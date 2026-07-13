#include "executor/ExecutorCore.hpp"

#ifndef R_NO_REMAP
#define R_NO_REMAP
#endif
#include <Rembedded.h>
#include <Rinternals.h>
#ifdef length
#undef length
#endif

#include <Rcpp.h>
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cerrno>
#include <fstream>
#include <iostream>
#include <sstream>
#include <unistd.h>
#include <vector>
#include <sched.h>

#include "extrae.h"
#include <kernels/ContextManager.hpp>
#ifdef USE_CUDA
#include <cuda_runtime.h>
#endif

namespace rcompss {
namespace executor {

namespace {

std::vector<std::string> splitWhitespace(const std::string& input) {
  std::istringstream iss(input);
  std::vector<std::string> tokens;
  std::string token;
  while (iss >> token) {
    tokens.push_back(token);
  }
  return tokens;
}

int parseBool(const std::string& value) {
  if (value == "TRUE" || value == "T" || value == "1") {
    return 1;
  }
  return 0;
}

}  // namespace

ExecutorCore::ExecutorCore(const std::string& input_fifo_path,
                           const std::string& output_fifo_path,
                           int executor_id)
    : input_fifo_path_(input_fifo_path),
      output_fifo_path_(output_fifo_path),
      executor_id_(executor_id),
      r_initialized_(false),
      rcompss_ns_(nullptr),
      global_env_(nullptr),
      source_func_(nullptr),
      do_call_func_(nullptr),
      compss_unserialize_(nullptr),
      compss_serialize_(nullptr) {}

ExecutorCore::~ExecutorCore() { shutdownR(); }

void ExecutorCore::initR() {
  if (r_initialized_) {
    return;
  }

  // Disable JIT/bytecode to avoid embedded R startup failures.
  setenv("R_ENABLE_JIT", "0", 0);
  setenv("R_DISABLE_BYTECODE", "1", 0);
  setenv("R_COMPILE_PKGS", "0", 0);

  int r_argc = 3;
  std::vector<const char*> r_argv = {"RCOMPSsExecutor", "--no-save", "--silent"};
  std::vector<char*> r_argv_mut;
  r_argv_mut.reserve(r_argv.size());
  for (const auto* arg : r_argv) {
    r_argv_mut.push_back(const_cast<char*>(arg));
  }
  Rf_initEmbeddedR(r_argc, r_argv_mut.data());
  r_initialized_ = true;

  int error = 0;
  SEXP options_call = Rf_protect(Rf_lang2(Rf_install("options"), Rf_lang2(Rf_install("jit"), Rf_ScalarInteger(0))));
  R_tryEval(options_call, R_GlobalEnv, &error);
  Rf_unprotect(1);
  if (error) {
    std::cerr << "[C++ EXECUTOR] Failed to set options(jit=0)\n";
  }

  // Load Rcpp with the C API before touching Rcpp objects.
  error = 0;
  SEXP rcpp_call = Rf_protect(Rf_lang2(Rf_install("library"), Rf_mkString("Rcpp")));
  R_tryEval(rcpp_call, R_GlobalEnv, &error);
  Rf_unprotect(1);
  if (error) {
    std::cerr << "[C++ EXECUTOR] Failed to load Rcpp. R_LIBS_USER="
              << (std::getenv("R_LIBS_USER") ? std::getenv("R_LIBS_USER") : "<unset>")
              << "\n";
    throw std::runtime_error("Failed to load Rcpp");
  }

  Rcpp::Function library_func("library");
  try {
    library_func("RCOMPSs");
  } catch (const std::exception& ex) {
    std::cerr << "[C++ EXECUTOR] Failed to load RCOMPSs: " << ex.what() << "\n";
    throw;
  }

  Rcpp::Function requireNamespace_func("requireNamespace");
  try {
    bool qs_loaded = Rcpp::as<bool>(requireNamespace_func("qs", Rcpp::_["quietly"] = true));
    if (!qs_loaded) {
      std::cerr << "[C++ EXECUTOR] WARNING: Failed to load qs namespace\n";
    }
  } catch (...) {
    std::cerr << "[C++ EXECUTOR] WARNING: Exception loading qs namespace\n";
  }
  try {
    bool rmvl_loaded = Rcpp::as<bool>(requireNamespace_func("RMVL", Rcpp::_["quietly"] = true));
    if (!rmvl_loaded) {
      std::cerr << "[C++ EXECUTOR] WARNING: Failed to load RMVL namespace\n";
    }
  } catch (...) {
    std::cerr << "[C++ EXECUTOR] WARNING: Exception loading RMVL namespace\n";
  }

  rcompss_ns_ = std::make_unique<Rcpp::Environment>(
      Rcpp::Environment::namespace_env("RCOMPSs"));
  global_env_ = std::make_unique<Rcpp::Environment>(
      Rcpp::Environment::global_env());
  source_func_ = std::make_unique<Rcpp::Function>(
      Rcpp::Function("source"));
  do_call_func_ = std::make_unique<Rcpp::Function>(
      Rcpp::Function("do.call"));
  compss_unserialize_ = std::make_unique<Rcpp::Function>(
      (*rcompss_ns_)["rcompss_unserialize"]);
  compss_serialize_ = std::make_unique<Rcpp::Function>(
      (*rcompss_ns_)["rcompss_serialize"]);
}

void ExecutorCore::shutdownR() {
  if (!r_initialized_) {
    return;
  }
  Rf_endEmbeddedR(0);
  r_initialized_ = false;
}

bool ExecutorCore::parseTaskMessage(const std::string& line,
                                    TaskMessage& message) const {
  auto tokens = splitWhitespace(line);
  if (tokens.empty()) {
    return false;
  }
  if (tokens[0] != "EXECUTE_TASK") {
    return false;
  }
  if (tokens.size() < 14) {
    return false;
  }

  if (tokens.size() >= 3) {
    message.gpus = tokens[tokens.size() - 2];  // 2nd from last
    message.cpus = tokens[tokens.size() - 3];  // 3rd from last
  } else {
    message.cpus = "-";
    message.gpus = "-";
  }

  message.task_id = tokens[1];
  message.sandbox = tokens[2];
  message.job_out = tokens[3];
  message.job_err = tokens[4];
  message.tracing = tokens[5];
  message.debug = tokens[7];
  message.module = tokens[10];
  message.func = tokens[11];

  size_t params_end = tokens.size() - 3;
  if (params_end > 13) {
    message.params.assign(tokens.begin() + 13, tokens.begin() + params_end);
  } else {
    message.params.assign(tokens.begin() + 13, tokens.end());
  }
  return true;
}

std::string ExecutorCore::stripValueSuffix(const std::string& raw_value) const {
  auto pos = raw_value.find_last_of(':');
  if (pos == std::string::npos) {
    return raw_value;
  }
  return raw_value.substr(pos + 1);
}

namespace {
bool rcompssIsReturnValuePlaceholderArgName(const std::string& name) {
  static constexpr char kSuffix[] = "-RETURN_VALUE";
  constexpr size_t kLen = sizeof(kSuffix) - 1U;
  return name.size() >= kLen && name.compare(name.size() - kLen, kLen, kSuffix) == 0;
}
}  // namespace

Rcpp::List ExecutorCore::buildFunctionArgs(const std::vector<std::string>& params,
                                           int& return_index,
                                           int& num_returns) const {
  auto get_param = [&](int index_one_based) -> const std::string& {
    return params.at(static_cast<size_t>(index_one_based - 1));
  };

  int num_of_nodes = std::stoi(get_param(1));
  int has_target = parseBool(get_param(1 + num_of_nodes + 3));
  num_returns = std::stoi(get_param(1 + num_of_nodes + 5));
  int num_of_args = std::stoi(get_param(1 + num_of_nodes + 6));
  int first_arg_ind = num_of_nodes + 8;
  int leng_params_func = num_of_args - num_returns - has_target;

  Rcpp::List args(leng_params_func);
  Rcpp::CharacterVector names(leng_params_func);

  for (int i = 0; i < leng_params_func; ++i) {
    const std::string& type_code = get_param(first_arg_ind);
    const std::string& arg_name = get_param(first_arg_ind + 3);

    if (type_code == "0") {
      args[i] = Rcpp::LogicalVector::create(parseBool(get_param(first_arg_ind + 5)));
      names[i] = arg_name;
      first_arg_ind += 6;
    } else if (type_code == "4") {
      args[i] = std::stoi(get_param(first_arg_ind + 5));
      names[i] = arg_name;
      first_arg_ind += 6;
    } else if (type_code == "7") {
      args[i] = std::stod(get_param(first_arg_ind + 5));
      names[i] = arg_name;
      first_arg_ind += 6;
    } else if (type_code == "8") {
      int num_words = std::stoi(get_param(first_arg_ind + 5));
      std::ostringstream oss;
      for (int j = 1; j <= num_words; ++j) {
        if (j > 1) {
          oss << " ";
        }
        oss << get_param(first_arg_ind + 5 + j);
      }
      args[i] = oss.str();
      names[i] = arg_name;
      first_arg_ind += 6 + num_words;
    } else if (type_code == "10") {
      const std::string& content_type = get_param(first_arg_ind + 4);
      std::string path_value = stripValueSuffix(get_param(first_arg_ind + 5));
      if (content_type != "null") {
        // Write debug to file
        std::string log_file = "/tmp/rcompss_executor_debug_" + std::to_string(getpid()) + ".log";
        std::ofstream log(log_file, std::ios::app);
        log << "[DEBUG EXECUTOR] About to unserialize file: " << path_value << std::endl;
        log.flush();
        log.close();
        
        std::cerr << "[DEBUG EXECUTOR] About to unserialize file: " << path_value << "\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] About to unserialize file: " << path_value << "\n";
        Rcpp::Rcerr.flush();
        try {
          log.open(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] Step 1: Calling compss_unserialize function" << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] Step 1: Calling compss_unserialize function\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[DEBUG EXECUTOR] Step 1: Calling compss_unserialize function\n";
          Rcpp::Rcerr.flush();
          std::cerr << "[C++ EXECUTOR] Attempting to unserialize file: " << path_value << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[C++ EXECUTOR] Attempting to unserialize file: " << path_value << "\n";
          Rcpp::Rcerr.flush();
          
          log.open(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] Step 2: About to call (*compss_unserialize_)(path_value, 1)" << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] Step 2: About to call (*compss_unserialize_)(path_value, 1)\n";
          std::cerr.flush();
          Rcpp::RObject result = (*compss_unserialize_)(path_value, 1);
          
          log.open(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] Step 3: compss_unserialize returned, assigning to args[i]" << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] Step 3: compss_unserialize returned, assigning to args[i]\n";
          std::cerr.flush();
          args[i] = result;
          
          log.open(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] Step 4: Successfully assigned result to args[i]" << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] Step 4: Successfully assigned result to args[i]\n";
          std::cerr.flush();
          std::cerr << "[C++ EXECUTOR] Successfully unserialized file: " << path_value << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[C++ EXECUTOR] Successfully unserialized file: " << path_value << "\n";
          Rcpp::Rcerr.flush();
        } catch (const Rcpp::exception& e) {
          std::string error_msg = std::string("Rcpp exception unserializing file '") + path_value + "': " + e.what();
          std::string log_file = "/tmp/rcompss_executor_debug_" + std::to_string(getpid()) + ".log";
          std::ofstream log(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] CAUGHT Rcpp exception: " << e.what() << std::endl;
          log << "[C++ EXECUTOR] ERROR: " << error_msg << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] CAUGHT Rcpp exception: " << e.what() << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[DEBUG EXECUTOR] CAUGHT Rcpp exception: " << e.what() << "\n";
          Rcpp::Rcerr.flush();
          std::cerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
          Rcpp::Rcerr.flush();
          throw std::runtime_error(error_msg);
        } catch (const std::exception& e) {
          std::string error_msg = std::string("Exception unserializing file '") + path_value + "': " + e.what();
          std::string log_file = "/tmp/rcompss_executor_debug_" + std::to_string(getpid()) + ".log";
          std::ofstream log(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] CAUGHT std exception: " << e.what() << std::endl;
          log << "[C++ EXECUTOR] ERROR: " << error_msg << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] CAUGHT std exception: " << e.what() << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[DEBUG EXECUTOR] CAUGHT std exception: " << e.what() << "\n";
          Rcpp::Rcerr.flush();
          std::cerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
          Rcpp::Rcerr.flush();
          throw std::runtime_error(error_msg);
        } catch (...) {
          std::string error_msg = std::string("Unknown error unserializing file '") + path_value + "'";
          std::string log_file = "/tmp/rcompss_executor_debug_" + std::to_string(getpid()) + ".log";
          std::ofstream log(log_file, std::ios::app);
          log << "[DEBUG EXECUTOR] CAUGHT unknown exception" << std::endl;
          log << "[C++ EXECUTOR] ERROR: " << error_msg << std::endl;
          log.flush();
          log.close();
          
          std::cerr << "[DEBUG EXECUTOR] CAUGHT unknown exception\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[DEBUG EXECUTOR] CAUGHT unknown exception\n";
          Rcpp::Rcerr.flush();
          std::cerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
          std::cerr.flush();
          Rcpp::Rcerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
          Rcpp::Rcerr.flush();
          throw std::runtime_error(error_msg);
        }
      } else {
        args[i] = path_value;
      }
      names[i] = arg_name;
      first_arg_ind += 6;
    } else {
      args[i] = R_NilValue;
      names[i] = arg_name;
      first_arg_ind += 6;
    }
  }

  {
    std::vector<Rcpp::RObject> kept_vals;
    std::vector<std::string> kept_names;
    kept_vals.reserve(static_cast<size_t>(leng_params_func));
    kept_names.reserve(static_cast<size_t>(leng_params_func));
    for (int i = 0; i < leng_params_func; ++i) {
      const std::string nm = Rcpp::as<std::string>(names[i]);
      if (rcompssIsReturnValuePlaceholderArgName(nm)) {
        continue;
      }
      kept_vals.push_back(args[i]);
      kept_names.push_back(nm);
    }
    const int n_kept = static_cast<int>(kept_vals.size());
    Rcpp::List filtered(n_kept);
    for (int j = 0; j < n_kept; ++j) {
      filtered[j] = kept_vals[static_cast<size_t>(j)];
    }
    if (n_kept > 0) {
      Rcpp::CharacterVector fnames(n_kept);
      for (int j = 0; j < n_kept; ++j) {
        fnames[j] = kept_names[static_cast<size_t>(j)];
      }
      filtered.attr("names") = fnames;
    }
    args = filtered;
  }

  return_index = first_arg_ind;
  return args;
}

bool ExecutorCore::bindCpus(const std::string& cpus, std::ofstream& job_out, std::ofstream& job_err) const {
  if (cpus == "-" || cpus.empty()) {
    return false;
  }

  // bind_cpus_event = 1, inside_tasks_type = 9000100
  Extrae_eventandcounters(9000100, 1);

  job_out << "[C++ EXECUTOR] Assigning CPU affinity: " << cpus << "\n";
  job_out.flush();

  // Parse CPU list (comma-separated)
  std::vector<int> cpu_list;
  std::istringstream cpu_stream(cpus);
  std::string cpu_token;
  while (std::getline(cpu_stream, cpu_token, ',')) {
    try {
      int cpu_id = std::stoi(cpu_token);
      cpu_list.push_back(cpu_id);
    } catch (const std::exception& e) {
      job_err << "[C++ EXECUTOR] WARNING: Invalid CPU ID in affinity string: " << cpu_token << "\n";
      job_err.flush();
      return false;
    }
  }

  if (cpu_list.empty()) {
    return false;
  }

  // Set CPU affinity using sched_setaffinity
  cpu_set_t cpu_set;
  CPU_ZERO(&cpu_set);
  for (int cpu_id : cpu_list) {
    CPU_SET(cpu_id, &cpu_set);
  }

  pid_t pid = getpid();
  if (sched_setaffinity(pid, sizeof(cpu_set_t), &cpu_set) < 0) {
    // End tracing event on error
    Extrae_eventandcounters(9000100, 0);
    job_err << "[C++ EXECUTOR] WARNING: Could not assign CPU affinity " << cpus
            << ": " << strerror(errno) << "\n";
    job_err.flush();
    return false;
  }

  // Export environment variables (similar to Python binding)
  // Only set on success (Python does this after try/except)
  setenv("COMPSS_BINDED_CPUS", cpus.c_str(), 1);
  setenv("COMPSS_NUM_CPUS", std::to_string(cpu_list.size()).c_str(), 1);

  // End tracing event (emit 0 when done, similar to EventInsideWorker __exit__)
  Extrae_eventandcounters(9000100, 0);

  job_out << "[C++ EXECUTOR] Successfully bound to CPUs: " << cpus << "\n";
  job_out.flush();
  return true;
}

void ExecutorCore::bindGpus(const std::string& gpus, std::ofstream& job_out, std::ofstream& job_err) const {
  if (gpus == "-" || gpus.empty()) {
    return;
  }

  // Emit tracing event (similar to EventInsideWorker(TRACING_WORKER.bind_gpus_event) in Python)
  // bind_gpus_event = 2, inside_tasks_type = 9000100
  Extrae_eventandcounters(9000100, 2);

  std::vector<int> gpu_mask_list(4, 0);
  if (gpus.find(',') != std::string::npos) {
    std::istringstream gpu_stream(gpus);
    std::string gpu_token;
    int i = 0;
    while (std::getline(gpu_stream, gpu_token, ',')) {
      try {
        if (i < 4) {
          gpu_mask_list[i] = 1;
        }
        ++i;
      } catch (const std::exception&) {
      }
    }
  } else {
    // Single GPU assigned
    try {
      int gpu_id = std::stoi(gpus);
      if (gpu_id >= 0 && gpu_id < 4) {
        gpu_mask_list[gpu_id] = 1;
      }
    } catch (const std::exception&) {
    }
  }
  
  // Reverse the list (Python: gpu_mask_list.reverse())
  std::reverse(gpu_mask_list.begin(), gpu_mask_list.end());
  
  // Convert to binary string then to decimal (Python: int("".join(map(str, gpu_mask_list)), 2))
  std::string gpu_mask_str;
  for (int val : gpu_mask_list) {
    gpu_mask_str += std::to_string(val);
  }
  int assigned_gpus = std::stoi(gpu_mask_str, nullptr, 2);
  
  // Emit manual event with GPU affinity type (inside_tasks_gpu_affinity_type = 9000160)
  Extrae_eventandcounters(9000160, assigned_gpus);

  job_out << "[C++ EXECUTOR] Assigning GPU affinity: " << gpus << "\n";
  job_out.flush();

  // Set environment variables (similar to Python binding)
  setenv("COMPSS_BINDED_GPUS", gpus.c_str(), 1);
  setenv("CUDA_VISIBLE_DEVICES", gpus.c_str(), 1);
  setenv("GPU_DEVICE_ORDINAL", gpus.c_str(), 1);

  // End tracing event (emit 0 when done, similar to EventInsideWorker __exit__)
  Extrae_eventandcounters(9000100, 0);

  job_out << "[C++ EXECUTOR] Successfully bound to GPUs: " << gpus << "\n";
  job_out.flush();
}

bool ExecutorCore::executeTask(const TaskMessage& message,
                               std::ofstream& output_fifo) {
  std::ofstream job_out(message.job_out, std::ios::app);
  std::ofstream job_err(message.job_err, std::ios::app);

  job_out << "[C++ EXECUTOR] Received task execution with id: " << message.task_id
          << ", module: " << message.module << ", function: " << message.func
          << "\n";
  job_out.flush();

  // CPU binding (similar to Python binding)
  bool binded_cpus = false;
  if (message.cpus != "-" && !message.cpus.empty()) {
    binded_cpus = bindCpus(message.cpus, job_out, job_err);
  }

  // GPU binding (similar to Python binding)
  bool binded_gpus = false;
  if (message.gpus != "-" && !message.gpus.empty()) {
    bindGpus(message.gpus, job_out, job_err);
    binded_gpus = true;
  }

  try {
    job_out << "[C++ EXECUTOR] About to source module: " << message.module << "\n";
    job_out.flush();
    std::cerr << "[C++ EXECUTOR] About to source module: " << message.module << "\n";
    std::cerr.flush();
    Rcpp::Rcerr << "[C++ EXECUTOR] About to source module: " << message.module << "\n";
    Rcpp::Rcerr.flush();
    
    // Check if file exists
    std::ifstream file_check(message.module);
    if (!file_check.good()) {
      std::string error_msg = "Module file does not exist or is not readable: " + message.module;
      job_err << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
      job_err.flush();
      std::cerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
      std::cerr.flush();
      output_fifo << "END_TASK " << message.task_id << " 1\n";
      output_fifo.flush();
      return false;
    }
    file_check.close();
    
    Extrae_eventandcounters(9000100, 5);
    try {
    (*source_func_)(message.module);
    } catch (const Rcpp::exception& e) {
      std::string error_msg = std::string("R error during source(): ") + e.what();
      job_err << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
      job_err.flush();
      std::cerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
      std::cerr.flush();
      Rcpp::Rcerr << "[C++ EXECUTOR] ERROR: " << error_msg << "\n";
      Rcpp::Rcerr.flush();
      throw;
    }
    Extrae_eventandcounters(9000100, 0);
    job_out << "Finished source(module)\n";
    job_out.flush();
    std::cerr << "[C++ EXECUTOR] Finished source(module)\n";
    std::cerr.flush();
    Rcpp::Rcerr << "[C++ EXECUTOR] Finished source(module)\n";
    Rcpp::Rcerr.flush();

    if (!global_env_->exists(message.func)) {
      job_err << "Function " << message.func << " does not exist\n";
      Extrae_eventandcounters(9000100, 13);
      output_fifo << "END_TASK " << message.task_id << " 1\n";
      output_fifo.flush();
      Extrae_eventandcounters(9000100, 0);
      return false;
    }

    int return_index = 0;
    int num_returns = 0;
    Rcpp::List args;
    try {
      args = buildFunctionArgs(message.params, return_index, num_returns);
    } catch (const Rcpp::exception& ex) {
      job_err << "[C++ EXECUTOR] R Error building function arguments: " << ex.what() << "\n";
      job_err.flush();
      std::cerr << "[C++ EXECUTOR] R Error building function arguments: " << ex.what() << "\n";
      std::cerr.flush();
      throw;
    } catch (const std::exception& ex) {
      job_err << "[C++ EXECUTOR] Error building function arguments: " << ex.what() << "\n";
      job_err.flush();
      std::cerr << "[C++ EXECUTOR] Error building function arguments: " << ex.what() << "\n";
      std::cerr.flush();
      throw;
    } catch (...) {
      job_err << "[C++ EXECUTOR] Unknown error building function arguments\n";
      job_err.flush();
      std::cerr << "[C++ EXECUTOR] Unknown error building function arguments\n";
      std::cerr.flush();
      throw;
    }

    Extrae_eventandcounters(9000100, 6);
    Rcpp::RObject result;
    try {
      job_out << "[C++ EXECUTOR] About to call function: " << message.func << "\n";
      job_out.flush();
      job_err << "[C++ EXECUTOR] About to call function: " << message.func << "\n";
      job_err.flush();
      std::cerr << "[C++ EXECUTOR] About to call function: " << message.func << "\n";
      std::cerr.flush();

      // Embedded R: do.call(what, list(), envir) can fail for zero-argument tasks; invoke
      // the closure directly (same as f() from the sourced module's global env).
      if (args.length() == 0) {
        job_out << "[C++ EXECUTOR] Zero-arg task: calling " << message.func << "() directly\n";
        job_out.flush();
        Rcpp::Function f = (*global_env_)[message.func];
        result = f();
      } else {
        result = (*do_call_func_)(Rcpp::_["what"] = message.func,
                                 Rcpp::_["args"] = args,
                                 Rcpp::_["envir"] = *global_env_);
      }

      job_out << "[C++ EXECUTOR] Function call completed successfully\n";
      job_out.flush();
    } catch (const Rcpp::exception& e) {
      std::string error_msg = std::string("[C++ EXECUTOR] Rcpp exception calling function '") + message.func + "': " + e.what();
      job_err << error_msg << "\n";
      job_err.flush();
      std::cerr << error_msg << "\n";
      std::cerr.flush();
      Rcpp::Rcerr << error_msg << "\n";
      Rcpp::Rcerr.flush();
      throw;
    } catch (const std::exception& e) {
      std::string error_msg = std::string("[C++ EXECUTOR] std exception calling function '") + message.func + "': " + e.what();
      job_err << error_msg << "\n";
      job_err.flush();
      std::cerr << error_msg << "\n";
      std::cerr.flush();
      Rcpp::Rcerr << error_msg << "\n";
      Rcpp::Rcerr.flush();
      throw;
    } catch (...) {
      std::string error_msg = std::string("[C++ EXECUTOR] Unknown exception calling function '") + message.func + "'";
      job_err << error_msg << "\n";
      job_err.flush();
      std::cerr << error_msg << "\n";
      std::cerr.flush();
      Rcpp::Rcerr << error_msg << "\n";
      Rcpp::Rcerr.flush();
      throw;
    }
    Extrae_eventandcounters(9000100, 0);

    if (num_returns > 0) {
      auto get_param = [&](int index_one_based) -> const std::string& {
        return message.params.at(static_cast<size_t>(index_one_based - 1));
      };

      std::string rv_ser_method = get_param(return_index + 3);
      rv_ser_method = rv_ser_method.substr(0, rv_ser_method.find('-'));
      std::string path_return_value = stripValueSuffix(get_param(return_index + 5));

      // Write debug to file (executor runs in separate process)
      std::string executor_log_file = "/tmp/rcompss_executor_debug_" + std::to_string(getpid()) + ".log";
      
      std::cerr << "[DEBUG EXECUTOR] About to serialize return value to: " << path_return_value << "\n";
      std::cerr << "[DEBUG EXECUTOR] Serialization method: " << rv_ser_method << "\n";
      std::cerr.flush();
      Rcpp::Rcerr << "[DEBUG EXECUTOR] About to serialize return value to: " << path_return_value << "\n";
      Rcpp::Rcerr << "[DEBUG EXECUTOR] Serialization method: " << rv_ser_method << "\n";
      Rcpp::Rcerr.flush();
      
      {
        std::ofstream executor_log(executor_log_file, std::ios::app);
        if (executor_log.is_open()) {
          executor_log.flush();
        }
      }

      Extrae_eventandcounters(9000100, 9);
      try {
      (*compss_serialize_)(result, path_return_value, rv_ser_method, 1);
        
        // Write debug to file
        {
          std::ofstream executor_log(executor_log_file, std::ios::app);
          if (executor_log.is_open()) {
            executor_log << "[DEBUG EXECUTOR] Serialization call completed successfully" << std::endl;
            executor_log.flush();
          }
        }
        
        std::cerr << "[DEBUG EXECUTOR] Serialization call completed successfully\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] Serialization call completed successfully\n";
        Rcpp::Rcerr.flush();
      } catch (const Rcpp::exception& e) {
        std::cerr << "[DEBUG EXECUTOR] ERROR in serialization: Rcpp exception: " << e.what() << "\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] ERROR in serialization: Rcpp exception: " << e.what() << "\n";
        Rcpp::Rcerr.flush();
        throw;
      } catch (const std::exception& e) {
        std::cerr << "[DEBUG EXECUTOR] ERROR in serialization: std exception: " << e.what() << "\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] ERROR in serialization: std exception: " << e.what() << "\n";
        Rcpp::Rcerr.flush();
        throw;
      } catch (...) {
        std::cerr << "[DEBUG EXECUTOR] ERROR in serialization: unknown exception\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] ERROR in serialization: unknown exception\n";
        Rcpp::Rcerr.flush();
        throw;
      }
      Extrae_eventandcounters(9000100, 0);
      
      // Verify file was created
      std::ifstream verify(path_return_value);
      if (!verify.good()) {
        std::cerr << "[DEBUG EXECUTOR] ERROR: Return value file was not created: " << path_return_value << "\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] ERROR: Return value file was not created: " << path_return_value << "\n";
        Rcpp::Rcerr.flush();
      } else {
        verify.close();
        std::cerr << "[DEBUG EXECUTOR] Return value file created successfully: " << path_return_value << "\n";
        std::cerr.flush();
        Rcpp::Rcerr << "[DEBUG EXECUTOR] Return value file created successfully: " << path_return_value << "\n";
        Rcpp::Rcerr.flush();
      }
      
      job_out << "Return value serialized to " << path_return_value << "\n";
    }

    Extrae_eventandcounters(9000100, 11);
    output_fifo << "END_TASK " << message.task_id << " 0\n";
    output_fifo.flush();
    Extrae_eventandcounters(9000100, 0);
    return true;
  } catch (const Rcpp::exception& ex) {
    job_err << "R Error: " << ex.what() << "\n";
    std::cerr << "[C++ EXECUTOR] R Error in task execution: " << ex.what() << "\n";
  } catch (const std::exception& ex) {
    job_err << "Error: " << ex.what() << "\n";
    std::cerr << "[C++ EXECUTOR] Error in task execution: " << ex.what() << "\n";
  } catch (...) {
    job_err << "Error: unknown exception\n";
    std::cerr << "[C++ EXECUTOR] Unknown exception in task execution\n";
  }

  Extrae_eventandcounters(9000100, 13);
  output_fifo << "END_TASK " << message.task_id << " 1\n";
  output_fifo.flush();
  Extrae_eventandcounters(9000100, 0);
  return false;
}

int ExecutorCore::run() {
  std::cout << "[C++ EXECUTOR] RCOMPSs executor PID: " << getpid() << "\n";

  Extrae_init();
  Extrae_eventandcounters(9000200, 1);
  Extrae_eventandcounters(8001003, 8);
  Extrae_eventandcounters(8001112, static_cast<unsigned>(executor_id_));
  Extrae_eventandcounters(9000200, 3);

  initR();

  std::ifstream input_fifo(input_fifo_path_);
  std::ofstream output_fifo(output_fifo_path_, std::ios::out);
  output_fifo.flush();

  Extrae_eventandcounters(9000200, 0);
  std::string line;
  while (std::getline(input_fifo, line)) {
    if (line.empty()) {
      continue;
    }
    if (line == "QUIT") {
      break;
    }

    TaskMessage message;
    if (!parseTaskMessage(line, message)) {
      std::cout << "Received: " << line << "\n";
      continue;
    }

    Extrae_eventandcounters(9000200, 6);
    Extrae_eventandcounters(9000100, 4);
    executeTask(message, output_fifo);
    Extrae_eventandcounters(9000100, 0);
    Extrae_eventandcounters(9000200, 0);
  }

  rcompss::kernels::ContextManager::DestroyInstance();
#ifdef USE_CUDA
  cudaDeviceReset();
#endif

  Extrae_eventandcounters(9000200, 0);
  Extrae_flush();
  Extrae_fini();

  std::cout << "RCOMPSs executor finish PID: " << getpid() << "\n";
  return 0;
}

}  // namespace executor
}  // namespace rcompss

