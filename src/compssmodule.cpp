/**
 * Copyright (c) 2025- King Abdullah University of Science and Technology,
 * All rights reserved.
 * RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.
**/

/**
 * @file linear_regression.R
 * @brief This file contains the main file of the linear regression with predictions application
 * @version 1.0
 * @author Xiran Zhang; Javier Conejero
 * @date 2025-04-28
**/

#include <Rcpp.h>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <fstream>
#include <iostream>
#include <unistd.h>
#include <GS_compss.h>
#include <extrae.h>
#include <chrono>
#include <random>
#include <sstream>
#include <iomanip>
#include <ctime>
#include <adapters/RContextManager.hpp>
#include <kernels/MemoryHandler.hpp>
#ifdef USE_CUDA
#include <kernels/cuda/CudaVectorKernels.hpp>
#endif
using namespace Rcpp;

#define DEBUG_MODE 0  // Enable debug output to verify constraints are sent

// Printout for debugging
// @param str_to_print String to print if DEBUG_MODE is 1
void log_debug(std::string str_to_print)
{
  if (DEBUG_MODE)
  {
    Rcerr << str_to_print << std::endl;
  }
}

// Bool to String converter
// @param value Bool to convert to String
std::string boolToString(bool value) {
  return value ? "true" : "false";
}

//' Start a COMPSs-Runtime instance within interactive session
//' 
//' Note: Many parameters are currently commented out but may be added in the future:
//' monitor, project_xml, resources_xml, summary, task_execution, storage_conf, etc.
// [[Rcpp::export]]
void start_runtime_interactive(
  bool debug = false,
  bool graph = false,
  bool trace = false
)
{
  log_debug("Generate configuration file");

  char cwd[PATH_MAX];
  if (getcwd(cwd, sizeof(cwd)) == nullptr) {
      perror("Failed to get the current directory");
      return;
  }
  std::string fileName = "compss_jvm.cfg";
  std::string separator = "/";
  std::string fullPath = cwd + separator + fileName;

  std::string COMPSS_HOME = std::getenv("COMPSS_HOME");
  if (COMPSS_HOME.empty()) {
    perror("ERROR: 'COMPSS_HOME' environment variable is not defined.");
  }
  std::string JAVA_HOME = std::getenv("JAVA_HOME");
  if (JAVA_HOME.empty()) {
    perror("ERROR: 'JAVA_HOME' environment variable is not defined.");
  }
  std::string uuid = "123456-" + to_string(rand());

  std::string masterWorkingDir;
  const char* envMasterWd = std::getenv("COMPSS_MASTER_WORKING_DIR");
  if (envMasterWd != nullptr && envMasterWd[0] != '\0') {
    masterWorkingDir = envMasterWd;
  } else {
    const char* homeDir = std::getenv("HOME");
    if (homeDir != nullptr && homeDir[0] != '\0') {
      masterWorkingDir = std::string(homeDir) + "/.COMPSs/Interactive_01/tmpFiles";
    } else {
      masterWorkingDir = std::string(cwd) + "/.COMPSs_tmp";
    }
  }
  std::string logDirStr;
  const char* envLogDir = std::getenv("COMPSS_LOG_DIR");
  if (envLogDir != nullptr && envLogDir[0] != '\0') {
    logDirStr = envLogDir;
  } else {
    logDirStr = masterWorkingDir;
  }

  std::ofstream configFile(fileName);
  configFile << "-XX:+PerfDisableSharedMem\n";
  configFile << "-XX:-UsePerfData\n";
  configFile << "-XX:+UseG1GC\n";
  configFile << "-XX:+UseThreadPriorities\n";
  configFile << "-XX:ThreadPriorityPolicy=0\n";
  configFile << "-javaagent:" << COMPSS_HOME << "/Runtime/compss-engine.jar\n";
  configFile << "-Dcompss.to.file=false\n";
  configFile << "-Dcompss.appName=Interactive\n";  // << app_name << "\n";
  configFile << "-Dcompss.data_provenance=false\n";  // << boolToString(data_provenance) << "\n";
  configFile << "-Dcompss.uuid=" << uuid << "\n";
  configFile << "-Dcompss.shutdown_in_node_failure=false\n";  // << boolToString(shutdown_in_node_failure) << "\n";
  configFile << "-Dcompss.master.workingDir=" << masterWorkingDir << "\n";
  configFile << "-Dcompss.log.dir=" << logDirStr << "\n";
  configFile << "-Dlog4j.configurationFile=" << COMPSS_HOME << "/Runtime/configuration/log/COMPSsMaster-log4j.info\n";
  configFile << "-Dcompss.graph=" << boolToString(graph) << "\n";
  configFile << "-Dcompss.monitor=0\n";  // << monitor << "\n";
  configFile << "-Dcompss.summary=false\n";  // << boolToString(summary) << "\n";
  configFile << "-Dcompss.worker.cp=" << cwd << ":" << COMPSS_HOME << "/Runtime/compss-engine.jar\n";
  configFile << "-Dcompss.worker.appdir=" << cwd << "\n";
  configFile << "-Dcompss.worker.jvm_opts=-Xms1024m,-Xmx1024m,-Xmn400m\n"; // << jvm_workers << "\n";
  configFile << "-Dcompss.worker.cpu_affinity=automatic\n";  // << cpu_affinity << "\n";
  configFile << "-Dcompss.worker.gpu_affinity=automatic\n";  // << gpu_affinity << "\n";
  configFile << "-Dcompss.worker.fpga_affinity=automatic\n";  // << fpga_affinity << "\n";
  configFile << "-Dcompss.worker.fpga_reprogram=\n";  // << fpga_reprogram << "\n";
  configFile << "-Dcompss.worker.io_executors=0\n";  // << io_executors << "\n";
  configFile << "-Dcompss.worker.env_script=\n";  // << env_script << "\n";
  configFile << "-Dcompss.comm=es.bsc.compss.nio.master.NIOAdaptor\n";  // << comm << "\n";
  configFile << "-Dcompss.masterName=\n";  // << master_name << "\n";
  configFile << "-Dcompss.masterPort=\n";  // << master_port << "\n";
  configFile << "-Dgat.adaptor.path=" << COMPSS_HOME << "/Dependencies/JAVA_GAT/lib/adaptors\n";
  configFile << "-Dgat.debug=" << boolToString(debug) << "\n";
  configFile << "-Dgat.broker.adaptor=sshtrilead\n";
  configFile << "-Dgat.file.adaptor=sshtrilead\n";
  configFile << "-Dcompss.execution.reuseOnBlock=true\n";  // << boolToString(reuse_on_block) << "\n";
  configFile << "-Dcompss.execution.nested.enabled=false\n";  // << boolToString(nested_enabled) << "\n";
  configFile << "-Dcompss.scheduler=es.bsc.compss.scheduler.lookahead.locality.LocalityTS\n";  // << scheduler << "\n";
  configFile << "-Dcompss.scheduler.config=\n";  // << scheduler_config << "\n";
  configFile << "-Dcompss.profile.input=\n";  // << profile_input << "\n";
  configFile << "-Dcompss.profile.output=\n";  // << profile_output << "\n";
  configFile << "-Dcompss.project.file=" << COMPSS_HOME << "/Runtime/configuration/xml/projects/default_project.xml\n";  // << project_xml << "\n";
  configFile << "-Dcompss.resources.file=" << COMPSS_HOME << "/Runtime/configuration/xml/resources/default_resources.xml\n";  // << resources_xml << "\n";
  configFile << "-Dcompss.project.schema=" << COMPSS_HOME << "/Runtime/configuration/xml/projects/project_schema.xsd\n";
  configFile << "-Dcompss.resources.schema=" << COMPSS_HOME << "/Runtime/configuration/xml/resources/resources_schema.xsd\n";
  configFile << "-Dcompss.conn=es.bsc.compss.connectors.DefaultSSHConnector\n";  // << conn << "\n";
  configFile << "-Dcompss.external.adaptation=false\n";  // << boolToString(external_adaptation) << "\n";
  configFile << "-Dcompss.checkpoint.policy=es.bsc.compss.checkpoint.policies.NoCheckpoint\n";  // << checkpoint_policy << "\n";
  configFile << "-Dcompss.checkpoint.params=\n";  // << checkpoint_params << "\n";
  configFile << "-Dcompss.checkpoint.folder=\n";  // << checkpoint_folder << "\n";
  configFile << "-Dcompss.lang=R\n";
  configFile << "-Dcompss.core.count=50\n";  // << task_count << "\n";
  configFile << "-Djava.class.path=" << COMPSS_HOME << "/Runtime/compss-engine.jar\n";
  configFile << "-Djava.library.path=" << COMPSS_HOME << "/Bindings/bindings-common/lib/:" << JAVA_HOME << "/lib/server";
  const char* extraJavaLibPath = std::getenv("RCOMPSs_JAVA_LIBRARY_PATH_EXTRA");
  if (extraJavaLibPath != nullptr && extraJavaLibPath[0] != '\0') {
    configFile << ":" << extraJavaLibPath;
  }
  configFile << "\n";
  configFile << "-Dcompss.worker.pythonpath=\n";
  configFile << "-Dcompss.python.interpreter=R\n";
  configFile << "-Dcompss.python.version=3\n";
  configFile << "-Dcompss.python.virtualenvironment=null\n";
  configFile << "-Dcompss.python.propagate_virtualenvironment=true\n";
  configFile << "-Dcompss.python.mpi_worker=false\n";
  configFile << "-Dcompss.python.worker_cache=false\n";
  configFile << "-Dcompss.python.cache_profiler=false\n";
  configFile << "-Dcompss.streaming=NONE\n";  // << streaming_backend << "\n";
  configFile << "-Dcompss.streaming.masterName=null\n";  // << streaming_master_name << "\n";
  configFile << "-Dcompss.streaming.masterPort=null\n";  // << streaming_master_port << "\n";
  configFile << "-Dcompss.task.execution=compss\n";  // << task_execution << "\n";
  configFile << "-Dcompss.storage.conf=null\n";  // << storage_conf << "\n";
  configFile << "-Dcompss.tracing=" << boolToString(trace) << "\n";
  configFile << "-Dcompss.tracing.task.dependencies=false\n";  // << boolToString(tracing_task_dependencies) << "\n";
  configFile << "-Dcompss.extrae.working_dir=null\n";  // << extrae_final_directory << "\n";
  configFile << "-Dcompss.extrae.file=null\n";  // << extrae_cfg << "\n";
  configFile << "-Dcompss.extrae.file.python=null\n";
  configFile << "-Dcompss.trace.label=None\n";  // << trace_label << "\n";
  configFile << "-Dcompss.wcl=0\n";  // << wcl << "\n";
  configFile << "-Dcompss.ear=false\n";  // << boolToString(ear) << "\n";
  configFile.close();

  log_debug("Export configuration file");
  if (setenv("JVM_OPTIONS_FILE", fileName.c_str(), 1) != 0) {
    perror("Error exporting JVM_OPTIONS_FILE");
  } else {
    std::cout << " - Successfully exported JVM_OPTIONS_FILE: " << fileName << std::endl;
  }

  log_debug("Start interactive runtime");
  GS_On();
}

//' Start a COMPSs-Runtime instance
// [[Rcpp::export]]
void start_runtime()
{
  log_debug("Start runtime");
  GS_On();
}

//' stop_runtime
//'
//' Stop a COMPSs-Runtime instance
//'
//' @param code The code to exit
// [[Rcpp::export]]
void stop_runtime(int code)
{
  log_debug("Stop runtime with code: " + std::to_string(code));
  GS_Off(code);
  log_debug("RCOMPSs stopped");
}

//' register_core_element
//'
//' Register a core element
//'
//' @param CESignature String with the core element signature. Usually: module_file.module_name.task_name
//' @param ImplSignature String with the implementation signature. Usually: module_file.module_name.task_name
//' @param ImplConstraints String with the task constraints. Usually empty, but for example: computingUnits=1
//' @param ImplType String with the implementation type. Usually METHOD although there are others supported for binaries, etc.
//' @param ImplLocal String boolean indicating if the implementation has to be executed locally. Usually False.
//' @param ImplIO String boolean indicating if the implementation  has IO requirements. Usually False.
//' @param prolog String indicating any prolog action. Usually empty.
//' @param epilog String indicating any epilog action. Usually empty.
//' @param container String indicating if the task has to be executed within a container. Usually empty.
//' @param typeArgs String with all arguments (task parameters).
// [[Rcpp::export]]
void register_core_element(std::string CESignature, std::string ImplSignature,
                           std::string ImplConstraints, std::string ImplType,
                           std::string ImplLocal, std::string ImplIO,
                           CharacterVector prolog, CharacterVector epilog,
                           CharacterVector container, CharacterVector typeArgs)
{
  log_debug("Register core element");

  char *CESignatureCStr = &CESignature[0];
  char *ImplSignatureCStr = &ImplSignature[0];
  // Pass NULL for empty constraints to match behavior when constraints weren't supported
  char *ImplConstraintsCStr = ImplConstraints.empty() ? nullptr : &ImplConstraints[0];
  char *ImplTypeCStr = &ImplType[0];
  char *ImplLocalCStr = &ImplLocal[0];
  char *ImplIOCStr = &ImplIO[0];

  log_debug("- Core Element Signature: " + CESignature);
  log_debug("- Implementation Signature: " + ImplSignature);
  log_debug("- Implementation Constraints: " + ImplConstraints);
  log_debug("- Implementation Type: " + ImplType);
  log_debug("- Implementation Local: " + ImplLocal);
  log_debug("- Implementation IO: " + ImplIO);

  char **pro;
  char **epi;
  char **cont;
  char **ImplTypeArgs;

  int num_params = typeArgs.size();
  log_debug("- Implementation Type num args: " + std::to_string(num_params));

  pro = new char *[3];
  epi = new char *[3];
  cont = new char *[3];
  if (num_params > 0)
    ImplTypeArgs = new char *[num_params];

  std::string prolog0 = Rcpp::as<std::string>(prolog[0]);
  std::string prolog1 = Rcpp::as<std::string>(prolog[1]);
  std::string prolog2 = Rcpp::as<std::string>(prolog[2]);
  pro[0] = &prolog0[0];
  pro[1] = &prolog1[0];
  pro[2] = &prolog2[0];

  log_debug("- Prolog: " + prolog0 + "; " + prolog1 + "; " + prolog2);

  std::string epilog0 = Rcpp::as<std::string>(epilog[0]);
  std::string epilog1 = Rcpp::as<std::string>(epilog[1]);
  std::string epilog2 = Rcpp::as<std::string>(epilog[2]);
  epi[0] = &epilog0[0];
  epi[1] = &epilog1[0];
  epi[2] = &epilog2[0];

  log_debug("- Epilog: " + epilog0 + "; " + epilog1 + "; " + epilog2);

  std::string container0 = Rcpp::as<std::string>(container[0]);
  std::string container1 = Rcpp::as<std::string>(container[1]);
  std::string container2 = Rcpp::as<std::string>(container[2]);
  cont[0] = &container0[0];
  cont[1] = &container1[0];
  cont[2] = &container2[0];

  log_debug("- Container: " + container0 + "; " + container1 + "; " + container2);

  std::vector<std::string> stypeArgStorage; // Store the type arguments to ensure their lifetime
  stypeArgStorage.reserve(num_params);
  std::string typeArg;
  for (int i = 0; i < num_params; ++i)
  {
    typeArg = Rcpp::as<std::string>(typeArgs[i]);
    stypeArgStorage.push_back(typeArg);
    ImplTypeArgs[i] = &(stypeArgStorage[i][0]);
    log_debug("- Implementation Type Args: " + typeArg);
  }

  // Invoke the C library
  GS_RegisterCE(CESignatureCStr,
                ImplSignatureCStr,
                ImplConstraintsCStr,
                ImplTypeCStr,
                ImplLocalCStr,
                ImplIOCStr,
                pro,
                epi,
                cont,
                num_params,
                ImplTypeArgs);

  delete[] ImplTypeArgs;
  delete[] pro;
  delete[] epi;
  delete[] cont;

  log_debug("Core element registered");
}

int _get_type_size(int type)
{
  switch (type)
  {
  case 0:
    log_debug("- Type: logical");
    return sizeof(int);
  case 4:
    log_debug("- Type: integer");
    return sizeof(int);
  case 7:
    log_debug("- Type: double");
    return sizeof(double);
  }
  log_debug("Type not implemented yet");
  exit(3);
  return -1;
}

//' process_task
//'
//' Define the Rcpp function
//'
// [[Rcpp::export]]
void process_task(long int app_id, SEXP signatureSEXP, SEXP on_failureSEXP,
                  int time_out, int priority, int num_nodes,
                  int reduce, int chunk_size, int replicated,
                  int distributed, int has_target, int num_returns,
                  List values, CharacterVector names, IntegerVector compss_types,
                  IntegerVector compss_directions, IntegerVector compss_streams,
                  CharacterVector compss_prefixes, CharacterVector content_types,
                  CharacterVector weights, IntegerVector keep_renames)
{
  // CRITICAL: Handle symbols directly at C++ level to avoid Rcpp conversion issues
  // Check if signatureSEXP is a symbol and convert it manually
  std::string signature_str;
  if (TYPEOF(signatureSEXP) == SYMSXP) {
    // It's a symbol - convert to string manually
    signature_str = CHAR(PRINTNAME(signatureSEXP));
  } else {
    // It's already a character vector - extract normally
    CharacterVector signature(signatureSEXP);
    signature_str = (signature.size() > 0) ? Rcpp::as<std::string>(signature[0]) : "";
  }
  
  // Same for on_failure
  std::string on_failure_str;
  if (TYPEOF(on_failureSEXP) == SYMSXP) {
    on_failure_str = CHAR(PRINTNAME(on_failureSEXP));
  } else {
    CharacterVector on_failure(on_failureSEXP);
    on_failure_str = (on_failure.size() > 0) ? Rcpp::as<std::string>(on_failure[0]) : "";
  }

  log_debug("Process task:");
  log_debug("- App id: " + std::to_string(app_id));
  log_debug("- Signature: " + signature_str);
  log_debug("- On Failure: " + on_failure_str);
  log_debug("- Time Out: " + std::to_string(time_out));
  log_debug("- Priority: " + std::to_string(priority));
  log_debug("- Reduce: " + std::to_string(reduce));
  log_debug("- Chunk size: " + std::to_string(chunk_size));
  log_debug("- MPI Num nodes: " + std::to_string(num_nodes));
  log_debug("- Replicated: " + std::to_string(replicated));
  log_debug("- Distributed: " + std::to_string(distributed));
  log_debug("- Has target: " + std::to_string(has_target));

  int num_pars = values.size();
  log_debug("+ Number of parameters: " + std::to_string(num_pars));
  int num_fields = 9;
  std::vector<void *> unrolled_parameters(num_fields * num_pars, NULL);
  std::vector<void *> p_value(num_pars, NULL);

  // For characters
  // prefix
  std::vector<std::string> prefix_str_vec; // Store the type arguments to ensure their lifetime
  prefix_str_vec.reserve(num_pars);
  std::vector<char *> prefix_charp(num_pars); // Conversion to C-friendly formats
  // name
  std::vector<std::string> name_str_vec; // Store the type arguments to ensure their lifetime
  name_str_vec.reserve(num_pars);
  std::vector<char *> name_charp(num_pars); // Conversion to C-friendly formats
  // content
  std::vector<std::string> content_str_vec; // Store the type arguments to ensure their lifetime
  content_str_vec.reserve(num_pars);
  std::vector<char *> content_charp(num_pars); // Conversion to C-friendly formats
  // weight
  std::vector<std::string> weight_str_vec; // Store the type arguments to ensure their lifetime
  weight_str_vec.reserve(num_pars);
  std::vector<char *> weight_charp(num_pars); // Conversion to C-friendly formats
  // values
  std::vector<std::string> values_str_vec; // Store the type arguments to ensure their lifetime
  values_str_vec.reserve(num_pars);
  std::vector<char *> values_charp(num_pars); // Conversion to C-friendly formats

  std::string temp_string; // temporary storage
  int num_of_string_args = 0;
  for (int i = 0; i < num_pars; i++)
  {
    log_debug("Processing parameter " + std::to_string(i));
    int size_i;
    if (compss_types[i] == 0 || compss_types[i] == 4 || compss_types[i] == 7)
    {
      size_i = _get_type_size(compss_types[i]);
    }
    else if (compss_types[i] == 8 || compss_types[i] == 10)
    { // Strings
      size_i = (strlen(values[i]) + 1) * sizeof(char);
    }

    p_value[i] = new std::uint8_t[size_i];
    switch (compss_types[i])
    {
    case 0:
      *(int *)(p_value[i]) = int(values[i]);
      break;
    case 4:
      *(int *)(p_value[i]) = int(values[i]);
      break;
    case 7:
      *(double *)(p_value[i]) = double(values[i]);
      break;
    case 8:
      // strcpy((char*)p_value[i], values[i]);
      temp_string = Rcpp::as<std::string>(values[i]);
      values_str_vec.push_back(temp_string);
      values_charp[i] = (char *)values_str_vec[num_of_string_args].c_str();
      p_value[i] = &values_charp[i];
      num_of_string_args++;
      break;
    case 10:
      temp_string = Rcpp::as<std::string>(values[i]);
      values_str_vec.push_back(temp_string);
      values_charp[i] = (char *)values_str_vec[num_of_string_args].c_str();
      p_value[i] = &values_charp[i];
      num_of_string_args++;
      break;
    default:
      log_debug("Non-supported type!");
    }

    // Format the values in unrolled_parameters
    // value
    unrolled_parameters[num_fields * i + 0] = (void *)p_value[i];
    // type: int
    unrolled_parameters[num_fields * i + 1] = (void *)&compss_types[i];
    // direction: int
    unrolled_parameters[num_fields * i + 2] = (void *)&compss_directions[i];
    // stream: int
    unrolled_parameters[num_fields * i + 3] = (void *)&compss_streams[i];
    // prefix: string
    temp_string = Rcpp::as<std::string>(compss_prefixes[i]);
    prefix_str_vec.push_back(temp_string);
    prefix_charp[i] = (char *)prefix_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 4] = (void *)&prefix_charp[i];
    // name: string
    temp_string = Rcpp::as<std::string>(names[i]);
    name_str_vec.push_back(temp_string);
    name_charp[i] = (char *)name_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 5] = (void *)&name_charp[i];
    // content: string
    temp_string = Rcpp::as<std::string>(content_types[i]);
    content_str_vec.push_back(temp_string);
    content_charp[i] = (char *)content_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 6] = (void *)&content_charp[i];
    // weight: string
    temp_string = Rcpp::as<std::string>(weights[i]);
    weight_str_vec.push_back(temp_string);
    weight_charp[i] = (char *)weight_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 7] = (void *)&weight_charp[i];
    // rename: int
    unrolled_parameters[num_fields * i + 8] = (void *)&keep_renames[i];
  }

  for (int i = 0; i < num_pars; i++)
  {
#if DEBUG_MODE
    fprintf(stderr, "----> Value is at %p\n", (void *)p_value[i]);
    fprintf(stderr, "----> Type: %d\n", compss_types[i]);
    switch (compss_types[i])
    {
    case 0:
      fprintf(stderr, "----> The value is: %d\n", *(int *)(p_value[i]));
      break;
    case 4:
      fprintf(stderr, "----> The value is: %d\n", *(int *)(p_value[i]));
      break;
    case 7:
      fprintf(stderr, "----> The value is: %lf\n", *(double *)(p_value[i]));
      break;
    case 8:
      fprintf(stderr, "----> The value is: %s\n", *(char **)(p_value[i]));
      break;
    case 10:
      fprintf(stderr, "----> The value is: %s\n", *(char **)(p_value[i]));
      break;
    }
    fprintf(stderr, "----> Direction: %d\n", compss_directions[i]);
    fprintf(stderr, "----> Stream: %d\n", compss_streams[i]);
    fprintf(stderr, "----> Prefix: %s\n", prefix_charp[i]);
    // fprintf(stderr, "----> Size: %d\n", _get_type_size(compss_types[i]));
    fprintf(stderr, "----> Name: %s\n", name_charp[i]);
    fprintf(stderr, "----> Content: %s\n", content_charp[i]);
    fprintf(stderr, "----> Weight: %s\n", weight_charp[i]);
    fprintf(stderr, "----> Keep rename: %d\n\n", keep_renames[i]);
#endif
  }

  char *signature_char = const_cast<char*>(signature_str.c_str());
  char *on_failure_char = const_cast<char*>(on_failure_str.c_str());

  log_debug("Calling GS_ExecuteTaskNew...");
  log_debug("- Signature: " + signature_str);
  log_debug("- Num parameters: " + std::to_string(num_pars));
  log_debug("- Num returns: " + std::to_string(num_returns));
  
  // Call the C++ function with the parameters
  GS_ExecuteTaskNew(
      app_id,
      signature_char,
      on_failure_char,
      time_out,
      priority,
      num_nodes,
      reduce,
      chunk_size,
      replicated,
      distributed,
      has_target,
      num_returns,
      num_pars,
      &unrolled_parameters[0] // hide the fact that params is a std::vector
  );

  log_debug("GS_ExecuteTaskNew returned successfully");
  log_debug("Returning from process_task...");
}

//' barrier
//'
//' Halt all the tasks: Notify the runtime that our current application wants to "execute" a barrier. Program will be blocked in GS_BarrierNew until all running tasks have ended. Notifies the 'no more tasks' boolean value.
//'
// [[Rcpp::export]]
void barrier(long int app_id, bool no_more_tasks)
{
  log_debug("Barrier\n");
  log_debug("- App id: " + std::to_string(app_id));
  if (no_more_tasks)
  {
    log_debug("- No more tasks?: true");
  }
  else
  {
    log_debug("- No more tasks?: FALSE");
  }
  GS_BarrierNew(app_id, no_more_tasks);
  log_debug("Barrier end\n");
}

//' Get_File
//'
//' Serialization in R and synchronize the results with the master.
//'
// [[Rcpp::export]]
void Get_File(long int app_id, std::string outputfileName)
{
  log_debug("\nGet_File");
  log_debug("- App id: " + std::to_string(app_id));
  log_debug("- Output filename: " + outputfileName);
  char *outputfileName_char;
  outputfileName_char = &outputfileName[0];
  GS_Get_File(app_id, outputfileName_char);
  log_debug("Get_File end\n");
}

//' Get_MasterWorkingDir
//'
//' Obtain the master working direction
//'
// [[Rcpp::export]]
Rcpp::CharacterVector Get_MasterWorkingDir()
{
  log_debug("Get_MasterWorkingDir\n");
  char *master_working_path;
  GS_Get_MasterWorkingDir(&master_working_path);
  Rcpp::CharacterVector result = Rcpp::CharacterVector::create(master_working_path);
  log_debug("Get_MasterWorkingDir end\n");
  return result;
}

//' Extrae_event_and_counters
//'
//' Emit EXTRAE event.
//'
// [[Rcpp::export]]
void Extrae_event_and_counters(unsigned int group, unsigned int id)
{
  log_debug("\nExtrae_event_and_counters");
  log_debug("- Group: " + std::to_string(group));
  log_debug("- id: " + std::to_string(id));
  // Cast to extrae types for the actual function call
  extrae_type_t extrae_group = static_cast<extrae_type_t>(group);
  extrae_value_t extrae_id = static_cast<extrae_value_t>(id);
  Extrae_eventandcounters(extrae_group, extrae_id);
  log_debug("Extrae_event_and_counters end\n");
}

//' Extrae_ini
// [[Rcpp::export]]
void Extrae_ini()
{
  log_debug("\nExtrae_ini");
  Extrae_init();
  log_debug("Extrae_init end\n");
}

//' Extrae_flu
// [[Rcpp::export]]
void Extrae_flu()
{
  log_debug("\nExtrae_flu");
  Extrae_flush();
  log_debug("Extrae_flu end\n");
}

//' Extrae_fin
// [[Rcpp::export]]
void Extrae_fin()
{
  log_debug("\nExtrae_fin");
  Extrae_fini();
  log_debug("Extrae_fin end\n");
}

// ============================================================================
// STEP 1: UID() Function - C++ Implementation using UIDGenerator class
// ============================================================================
#include <core/UIDGenerator.hpp>

//' Generate a unique ID (C++ implementation)
//' 
//' This is a C++ implementation that exactly replicates the R UID() function logic.
//' Uses the UIDGenerator class which replicates:
//'   current_time <- Sys.time()
//'   time_string <- format(current_time, "%Y%m%d%H%M%S")
//'   random_string <- paste0(sample(c(letters, LETTERS, 0:9), 50, replace = TRUE), collapse = "")
//'   return(paste0(time_string, "-", random_string))
//' 
//' @return A unique string ID (format: YYYYMMDDHHMMSS-randomstring)
// [[Rcpp::export]]
std::string rcompss_generate_uid()
{
  std::string uid = RCOMPSs::core::UIDGenerator::generate();
  Rcpp::Rcerr << "[C++ UID Generator] Using C++ implementation. Generated UID: " << uid << "\n";
  return uid;
}

// ============================================================================
// STEP 2: parType_mapping() Function - C++ Implementation using TypeMapper class
// ============================================================================
#include <core/TypeMapper.hpp>

//' Map R type to COMPSs type number (C++ implementation)
//' 
//' This is a C++ implementation that exactly replicates the R parType_mapping() function logic.
//' Maps R types to COMPSs numbering system:
//'   "logical" = 0L
//'   "CHAR" = 1L
//'   "BYTE" = 2L
//'   "SHORT" = 3L
//'   "integer" = 4L
//'   "double" = 7L
//'   "character" = 8L
//'   default = 10L (FILE)
//' 
//' @param arg R object to get type from
//' @return COMPSs type number (integer)
// [[Rcpp::export]]
int rcompss_par_type_mapping(SEXP arg)
{
  // Get R type string using R's typeof() function via Rcpp
  Rcpp::Function typeof_func("typeof");
  std::string r_type = Rcpp::as<std::string>(typeof_func(arg));
  int compss_type = RCOMPSs::core::TypeMapper::mapType(r_type);
  Rcpp::Rcerr << "[C++ TypeMapper] Mapped R type '" << r_type << "' to COMPSs type " << compss_type << "\n";
  return compss_type;
}

// ============================================================================
// STEP 3: Path Utilities - C++ Implementation using PathUtils class
// ============================================================================
#include <core/PathUtils.hpp>

// ============================================================================
// STEP 4: Type Checking Utilities - C++ Implementation using TypeChecker class
// ============================================================================
#include <core/TypeChecker.hpp>

// ============================================================================
// STEP 5: String Utilities - C++ Implementation using StringUtils class
// ============================================================================
#include <core/StringUtils.hpp>

// ============================================================================
// STEP 6: Vector Utilities - C++ Implementation using VectorUtils class
// ============================================================================
#include <core/VectorUtils.hpp>

// ============================================================================
// STEP 7: Task Decorator - Complete task processing in one class
// ============================================================================
#include <core/TaskDecorator.hpp>

// Forward declarations for serialization functions (used by rcompss_execute_task)
void rcompss_serialize(SEXP object, const std::string& filepath, const std::string& ser_method, int mthreads);
SEXP rcompss_unserialize(const std::string& filepath, int mthreads);

// Helper function to get default serialization method from environment variable
std::string get_default_serialization_method() {
  const char* env_method = std::getenv("RCOMPSs_SERIALIZATION");
  if (env_method != nullptr && strlen(env_method) > 0) {
    std::string method(env_method);
    // Normalize to lowercase for comparison, but return original
    std::string method_lower = method;
    std::transform(method_lower.begin(), method_lower.end(), method_lower.begin(), ::tolower);
    if (method_lower == "cpp" || method_lower == "qs" || method_lower == "rmvl") {
      return method;
    } else {
      Rcpp::Rcerr << "[C++ SERIALIZE] WARNING: Invalid RCOMPSs_SERIALIZATION value '" << method
                  << "'. Valid values: cpp, qs, RMVL. Using default 'cpp'.\n";
      return "cpp";
    }
  }
  return "cpp";  // Default to cpp if not set
}

//' Create integer vector filled with value (C++ implementation)
//' 
//' This is a C++ implementation that replicates: rep(value, length = count)
//' 
//' @param value Integer value to repeat
//' @param count Length of vector
//' @return Integer vector filled with value
// [[Rcpp::export]]
Rcpp::IntegerVector rcompss_rep_integer(int value, int count)
{
  std::vector<int> vec = RCOMPSs::core::VectorUtils::repInteger(value, count);
  Rcpp::IntegerVector result = Rcpp::wrap(vec);
  Rcpp::Rcerr << "[C++ VectorUtils] Created integer vector of length " << count << " filled with " << value << "\n";
  return result;
}

//' Create string vector filled with value (C++ implementation)
//' 
//' This is a C++ implementation that replicates: rep(value, length = count)
//' 
//' @param value String value to repeat
//' @param count Length of vector
//' @return Character vector filled with value
// [[Rcpp::export]]
Rcpp::CharacterVector rcompss_rep_string(const std::string& value, int count)
{
  std::vector<std::string> vec = RCOMPSs::core::VectorUtils::repString(value, count);
  Rcpp::CharacterVector result = Rcpp::wrap(vec);
  Rcpp::Rcerr << "[C++ VectorUtils] Created string vector of length " << count << " filled with '" << value << "'\n";
  return result;
}

//' Concatenate integer vector with value (C++ implementation)
//' 
//' This is a C++ implementation that replicates: c(vector, value)
//' 
//' @param vec Input integer vector
//' @param value Value to append
//' @return New integer vector with value appended
// [[Rcpp::export]]
Rcpp::IntegerVector rcompss_concat_integer(Rcpp::IntegerVector vec, int value)
{
  std::vector<int> cpp_vec = Rcpp::as<std::vector<int>>(vec);
  std::vector<int> result = RCOMPSs::core::VectorUtils::concatInteger(cpp_vec, value);
  Rcpp::IntegerVector r_result = Rcpp::wrap(result);
  Rcpp::Rcerr << "[C++ VectorUtils] Concatenated integer vector with value " << value << "\n";
  return r_result;
}

//' Concatenate string vector with value (C++ implementation)
//' 
//' This is a C++ implementation that replicates: c(vector, value)
//' 
//' @param vec Input character vector
//' @param value Value to append
//' @return New character vector with value appended
// [[Rcpp::export]]
Rcpp::CharacterVector rcompss_concat_string(Rcpp::CharacterVector vec, const std::string& value)
{
  std::vector<std::string> cpp_vec = Rcpp::as<std::vector<std::string>>(vec);
  std::vector<std::string> result = RCOMPSs::core::VectorUtils::concatString(cpp_vec, value);
  Rcpp::CharacterVector r_result = Rcpp::wrap(result);
  Rcpp::Rcerr << "[C++ VectorUtils] Concatenated string vector with value '" << value << "'\n";
  return r_result;
}

//' Extract serialization method from filepath (C++ implementation)
//' 
//' This is a C++ implementation that replicates: strsplit(basename(filepath), "-")[[1]][1]
//' Extracts the method prefix from filenames like: /path/to/qs-filenamexxxx
//' 
//' @param filepath Full file path
//' @return Serialization method string (e.g., "qs", "RMVL")
// [[Rcpp::export]]
std::string rcompss_extract_serialization_method(const std::string& filepath)
{
  std::string method = RCOMPSs::core::PathUtils::extractSerializationMethod(filepath);
  Rcpp::Rcerr << "[C++ PathUtils] Extracted serialization method '" << method << "' from path: " << filepath << "\n";
  return method;
}

//' Build serialization filename for arguments (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' paste0(MASTER_WORKING_DIR, "/", ser_method, "-", arg_name, "_arg[", index, "]_", uid)
//' 
//' @param master_working_dir Master working directory path
//' @param ser_method Serialization method (e.g., "qs", "RMVL")
//' @param arg_name Argument name
//' @param index Argument index (1-based, as R uses 1-based indexing)
//' @param uid Unique ID string
//' @return Full filepath for serialized argument
// [[Rcpp::export]]
std::string rcompss_build_argument_filename(const std::string& master_working_dir,
                                            const std::string& ser_method,
                                            const std::string& arg_name,
                                            int index,
                                            const std::string& uid)
{
  // R uses 1-based indexing, so index is already correct
  std::string filename = RCOMPSs::core::PathUtils::buildArgumentFilename(master_working_dir, ser_method, arg_name, index, uid);
  Rcpp::Rcerr << "[C++ PathUtils] Built argument filename: " << filename << "\n";
  return filename;
}

//' Build serialization filename for return values (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' paste0(MASTER_WORKING_DIR, "/", ser_method, "-", "ReturnValue_", uid)
//' 
//' @param master_working_dir Master working directory path
//' @param ser_method Serialization method (e.g., "qs", "RMVL")
//' @param uid Unique ID string
//' @return Full filepath for serialized return value
// [[Rcpp::export]]
std::string rcompss_build_return_value_filename(const std::string& master_working_dir,
                                                 const std::string& ser_method,
                                                 const std::string& uid)
{
  std::string filename = RCOMPSs::core::PathUtils::buildReturnValueFilename(master_working_dir, ser_method, uid);
  Rcpp::Rcerr << "[C++ PathUtils] Built return value filename: " << filename << "\n";
  return filename;
}

// ============================================================================
// STEP 4: Type Checking Utilities - C++ Implementation using TypeChecker class
// ============================================================================
#include <core/TypeChecker.hpp>

//' Check if R object is a basic type (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' length(class(arg)) == 1 && length(arg) == 1 && (class(arg) %in% c("integer", "numeric", "character"))
//' 
//' @param arg R object to check
//' @return true if object is a basic type, false otherwise
// [[Rcpp::export]]
bool rcompss_is_basic_type(SEXP arg)
{
  // Get class and type from R
  Rcpp::Function class_func("class");
  Rcpp::Function typeof_func("typeof");
  Rcpp::Function length_func("length");
  
  Rcpp::CharacterVector r_class_vec = class_func(arg);
  std::string r_class = (r_class_vec.length() == 1) ? Rcpp::as<std::string>(r_class_vec[0]) : "";
  std::string r_type = Rcpp::as<std::string>(typeof_func(arg));
  int length = Rcpp::as<int>(length_func(arg));
  
  bool result = RCOMPSs::core::TypeChecker::isBasicType(r_class, r_type, length);
  return result;
}

//' Check if R object is a future_object (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' length(class(obj)) == 1 && class(obj) == "future_object"
//' 
//' @param obj R object to check
//' @return true if object is a future_object, false otherwise
// [[Rcpp::export]]
bool rcompss_is_future_object(SEXP obj)
{
  Rcpp::Function class_func("class");
  Rcpp::CharacterVector r_class_vec = class_func(obj);
  std::string r_class = (r_class_vec.length() == 1) ? Rcpp::as<std::string>(r_class_vec[0]) : "";
  
  bool result = RCOMPSs::core::TypeChecker::isFutureObject(r_class);
  return result;
}

//' Check if R object is a future_object_path (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' length(class(obj)) == 1 && class(obj) == "future_object_path"
//' 
//' @param obj R object to check
//' @return true if object is a future_object_path, false otherwise
// [[Rcpp::export]]
bool rcompss_is_future_object_path(SEXP obj)
{
  Rcpp::Function class_func("class");
  Rcpp::CharacterVector r_class_vec = class_func(obj);
  std::string r_class = (r_class_vec.length() == 1) ? Rcpp::as<std::string>(r_class_vec[0]) : "";
  
  bool result = RCOMPSs::core::TypeChecker::isFutureObjectPath(r_class);
  return result;
}

//' Check if R object is a list (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' length(class(obj)) == 1 && class(obj) == "list"
//' 
//' @param obj R object to check
//' @return true if object is a list, false otherwise
// [[Rcpp::export]]
bool rcompss_is_list(SEXP obj)
{
  Rcpp::Function class_func("class");
  Rcpp::CharacterVector r_class_vec = class_func(obj);
  std::string r_class = (r_class_vec.length() == 1) ? Rcpp::as<std::string>(r_class_vec[0]) : "";
  
  bool result = RCOMPSs::core::TypeChecker::isList(r_class);
  return result;
}

//' Build variable argument names (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' paste0(paste0(f_name, "___"), 1:length(arguments))
//' Generates names like: "functionName___1", "functionName___2", etc.
//' 
//' @param function_name Function name
//' @param count Number of arguments
//' @return Character vector of argument names
// [[Rcpp::export]]
Rcpp::CharacterVector rcompss_build_variable_argument_names(const std::string& function_name, int count)
{
  std::vector<std::string> names = RCOMPSs::core::StringUtils::buildVariableArgumentNames(function_name, count);
  Rcpp::CharacterVector result = Rcpp::wrap(names);
  return result;
}

//' Build return value name (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' paste0(ser_method, "-RETURN_VALUE")
//' 
//' @param ser_method Serialization method (e.g., "qs", "RMVL")
//' @return Return value name string
// [[Rcpp::export]]
std::string rcompss_build_return_value_name(const std::string& ser_method)
{
  std::string result = RCOMPSs::core::StringUtils::buildReturnValueName(ser_method);
  return result;
}

//' Build register marker name (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' paste0("registered_", f_name)
//' 
//' @param function_name Function name
//' @return Register marker string
// [[Rcpp::export]]
std::string rcompss_build_register_marker(const std::string& function_name)
{
  std::string result = RCOMPSs::core::StringUtils::buildRegisterMarker(function_name);
  return result;
}

//' Build typeArgs path (C++ implementation)
//' 
//' This is a C++ implementation that replicates:
//' paste0(getwd(), "/", filename)
//' 
//' @param working_dir Current working directory
//' @param filename Filename
//' @return Full path string
// [[Rcpp::export]]
std::string rcompss_build_type_args_path(const std::string& working_dir, const std::string& filename)
{
  std::string result = RCOMPSs::core::PathUtils::buildTypeArgsPath(working_dir, filename);
  return result;
}

//' Build constraint string from named list (C++ implementation)
//' 
//' Builds constraint string in COMPSs format: key:value;key2:value2;
//' Examples:
//'   - computing_units:2;
//'   - processors:[{ProcessorType: CPU, ComputingUnits: 1}, {ProcessorType: GPU, ComputingUnits: 1}];
//' 
//' @param constraints Named list of constraints (key-value pairs)
//' @return Constraint string in COMPSs format
// [[Rcpp::export]]
std::string rcompss_build_constraint_string(Rcpp::List constraints)
{
  if (constraints.size() == 0) {
    return "";
  }
  
  std::vector<std::pair<std::string, std::string>> constraint_pairs;
  Rcpp::CharacterVector names = constraints.names();
  
  for (int i = 0; i < constraints.size(); ++i) {
    std::string key;
    if (i < names.size() && names[i] != R_NaString) {
      key = Rcpp::as<std::string>(names[i]);
    } else {
      continue;  // Skip unnamed constraints
    }
    
    // Convert value to string
    SEXP value = constraints[i];
    std::string value_str;
    
    if (TYPEOF(value) == INTSXP) {
      value_str = std::to_string(Rcpp::as<int>(value));
    } else if (TYPEOF(value) == REALSXP) {
      value_str = std::to_string(Rcpp::as<double>(value));
    } else if (TYPEOF(value) == STRSXP) {
      value_str = Rcpp::as<std::string>(value);
    } else if (TYPEOF(value) == VECSXP) {
      // For complex values like processors list, convert to string representation
      // Python format: processors=[{'processorType':'CPU', 'computingUnits':'1', ...}, ...]
      // COMPSs constraint string format: processors:[{processorType: CPU, computingUnits: 1}, ...]
      // Processor can have: processorType, computingUnits, name, speed, architecture,
      //                     propertyName, propertyValue, internalMemorySize
      // Note: COMPSs expects unquoted enum values (CPU, GPU) - quotes cause IllegalArgumentException
      Rcpp::List list_val = Rcpp::as<Rcpp::List>(value);
      value_str = "[{";
      for (int j = 0; j < list_val.size(); ++j) {
        if (j > 0) value_str += "}, {";
        // Format each processor entry
        if (TYPEOF(list_val[j]) == VECSXP) {
          Rcpp::List proc = Rcpp::as<Rcpp::List>(list_val[j]);
          Rcpp::CharacterVector proc_names = proc.names();
          bool first_field = true;
          for (int k = 0; k < proc.size(); ++k) {
            if (!first_field) value_str += ", ";
            first_field = false;
            
            std::string proc_key = (k < proc_names.size() && proc_names[k] != R_NaString) 
              ? Rcpp::as<std::string>(proc_names[k]) : "";
            std::string proc_val;
            
            if (TYPEOF(proc[k]) == STRSXP) {
              proc_val = Rcpp::as<std::string>(proc[k]);
              // COMPSs expects unquoted enum values (e.g., CPU, GPU, not "CPU", "GPU")
            } else if (TYPEOF(proc[k]) == INTSXP) {
              proc_val = std::to_string(Rcpp::as<int>(proc[k]));
            } else if (TYPEOF(proc[k]) == REALSXP) {
              proc_val = std::to_string(Rcpp::as<double>(proc[k]));
            } else if (TYPEOF(proc[k]) == LGLSXP) {
              proc_val = Rcpp::as<bool>(proc[k]) ? "true" : "false";
            } else {
              // Fallback: convert to string via R
              Rcpp::Function as_char("as.character");
              Rcpp::CharacterVector char_val = as_char(proc[k]);
              if (char_val.size() > 0) {
                proc_val = Rcpp::as<std::string>(char_val[0]);
              } else {
                proc_val = "";
              }
            }
            // COMPSs format: processorType: CPU (no quotes, space after colon)
            // COMPSs parses enum values directly, so "CPU" would fail with IllegalArgumentException
            value_str += proc_key + ": " + proc_val;
          }
        }
      }
      value_str += "}]";
    } else {
      // Fallback: convert to string via R
      Rcpp::Function as_char("as.character");
      Rcpp::CharacterVector char_val = as_char(value);
      if (char_val.size() > 0) {
        value_str = Rcpp::as<std::string>(char_val[0]);
      }
    }
    
    constraint_pairs.push_back(std::make_pair(key, value_str));
  }
  
  return RCOMPSs::core::StringUtils::buildConstraintString(constraint_pairs);
}

//' Process task metadata (C++ implementation)
//' 
//' This is a C++ implementation that processes task arguments and generates
//' all COMPSs metadata vectors (directions, streams, prefixes, etc.)
//' Note: arguments_type and content_types are NOT included as they get modified
//' during argument processing loop.
//' 
//' @param arguments_length Number of arguments
//' @param has_return_value Whether task has return value
//' @return List containing metadata vectors (directions, streams, prefixes, weights, keep_renames, num_returns)
// [[Rcpp::export]]
Rcpp::List rcompss_process_task_metadata(int arguments_length, bool has_return_value)
{
  RCOMPSs::core::TaskMetadata metadata = RCOMPSs::core::TaskDecorator::processTaskMetadata(arguments_length, has_return_value);
  
  Rcpp::List result;
  // Note: arguments_type and content_types are NOT included here because
  // they get modified during argument processing and should be handled separately
  result["compss_directions"] = Rcpp::wrap(metadata.compss_directions);
  result["compss_streams"] = Rcpp::wrap(metadata.compss_streams);
  result["compss_prefixes"] = Rcpp::wrap(metadata.compss_prefixes);
  result["weights"] = Rcpp::wrap(metadata.weights);
  result["keep_renames"] = Rcpp::wrap(metadata.keep_renames);
  result["num_returns"] = metadata.num_returns;
  
  return result;
}

//' Execute complete task processing (C++ implementation)
//' 
//' This is a comprehensive C++ implementation that processes the entire task:
//' - Processes and matches arguments
//' - Determines types for each argument
//' - Handles serialization preparation for non-basic types
//' - Builds all COMPSs metadata vectors
//' - Prepares return value if needed
//' - Prepares registration info
//' 
//' This replaces the entire logic inside the task() decorator function.
//' All task-related processing is consolidated in the TaskDecorator class.
//' 
//' @param function_name Name of the function being decorated
//' @param arguments R list of arguments (from formals or ...)
//' @param arguments_length Number of arguments
//' @param master_working_dir Master working directory path
//' @param filename Filename where function is defined
//' @param ser_method Serialization method (vector of 2 strings: [input, output])
//' @param return_value Whether function has return value
//' @param return_type Return type ("list" or "element")
//' @return List with all processed data: processed_arguments, arguments_names, arguments_type,
//'         content_types, compss_directions, compss_streams, compss_prefixes, weights,
//'         keep_renames, num_returns, return_value_filename, return_value_name,
//'         register_marker, type_args_path, success, error_message
// [[Rcpp::export]]
Rcpp::List rcompss_execute_task(
    const std::string& function_name,
    Rcpp::List arguments,
    int arguments_length,
    const std::string& master_working_dir,
    const std::string& filename,
    Rcpp::CharacterVector ser_method,
    bool return_value,
    const std::string& return_type)
{
  
  // Convert ser_method to vector
  std::vector<std::string> ser_method_vec;
  for (int i = 0; i < ser_method.size() && i < 2; ++i) {
    std::string method = Rcpp::as<std::string>(ser_method[i]);
    // If method is empty, use environment variable or default
    if (method.empty()) {
      method = get_default_serialization_method();
  }
    ser_method_vec.push_back(method);
  }
  // Fill in missing elements with default from environment or first element
  if (ser_method_vec.size() < 2) {
    std::string default_method = ser_method_vec.empty() ? get_default_serialization_method() : ser_method_vec[0];
    ser_method_vec.push_back(default_method);
  }
  
  // Execute task processing using TaskDecorator
  RCOMPSs::core::TaskExecutionResult result = RCOMPSs::core::TaskDecorator::executeTask(
    function_name, arguments, arguments_length, master_working_dir, filename,
    ser_method_vec, return_value, return_type);
  
  Rcpp::Rcerr.flush();
  
  // IMPORTANT: Modify arguments in place (just like original R code) to preserve names
  // In original R code, arguments is modified in place: arguments[[i]] <- arg_ser_filename
  // This preserves the names from formals(f)
  // CRITICAL: R requires lists to have names. Ensure we always have names, even if empty strings
  // Get names from result.arguments_names which was extracted from arguments in executeTask
  Rcpp::CharacterVector names_vec = Rcpp::wrap(result.arguments_names);
  
  // Ensure names vector matches arguments_length - CRITICAL: R requires lists to have names
  // Initialize with empty strings to ensure all elements have names (even if empty)
  if (names_vec.size() != arguments_length) {
    // Create vector with proper empty string initialization
    std::vector<std::string> names_str_vec(arguments_length, "");
    for (int i = 0; i < arguments_length && i < result.arguments_names.size(); ++i) {
      if (!result.arguments_names[i].empty()) {
        names_str_vec[i] = result.arguments_names[i];
      }
    }
    names_vec = Rcpp::wrap(names_str_vec);
  }
  
  // Clone arguments and immediately set names - this ensures the list always has names
  Rcpp::List processed_args = Rcpp::clone(arguments);
  // CRITICAL: Set names attribute - R will throw "Object was created without names" if this is missing
  processed_args.attr("names") = names_vec;
  
  // Verify names are set correctly
  if (!processed_args.hasAttribute("names")) {
    Rcpp::stop("Failed to set names on processed_args");
  }
  Rcpp::CharacterVector verify_initial_names = processed_args.names();
  if (verify_initial_names.size() != processed_args.size()) {
    Rcpp::stop("Names size mismatch - processed_args size: %d, names size: %d", 
               processed_args.size(), verify_initial_names.size());
  }
  
  // Handle serialization for arguments that need it (calls R packages directly from C++)
  // EXACTLY replicate original R logic: modify arguments in place
  for (int i = 0; i < arguments_length; ++i) {
    if (result.arguments_type[i] == 10 && result.content_types[i] == "object") {
      // Need to serialize this argument - EXACTLY like original: arguments[[i]] <- arg_ser_filename
      SEXP obj = arguments[i];
      
      // Check if obj is a symbol (from formals with no default value)
      // Symbols cannot be serialized - they need to be evaluated first
      // Use TYPEOF() macro which doesn't evaluate the SEXP
      if (TYPEOF(obj) == SYMSXP) {
        // This is a symbol from formals with no default - skip serialization
        // Keep the symbol as-is (it will be handled when the function is actually called with values)
        // Don't modify processed_args[i] - keep the original symbol
        continue;
      }
      
      std::string uid_result = RCOMPSs::core::UIDGenerator::generate();
      std::string arg_ser_filename = RCOMPSs::core::PathUtils::buildArgumentFilename(
        master_working_dir, ser_method_vec[0], result.arguments_names[i], i + 1, uid_result);
      
      rcompss_serialize(obj, arg_ser_filename, ser_method_vec[0], 1);
      processed_args[i] = arg_ser_filename;  // Modify in place like original
    } else if (result.arguments_type[i] == 10 && result.content_types[i] == "future_object") {
      // Future object - extract outputfile - EXACTLY like original: arguments[[i]] <- arguments[[i]]$outputfile
      Rcpp::List fo = Rcpp::as<Rcpp::List>(arguments[i]);
      processed_args[i] = Rcpp::as<std::string>(fo["outputfile"]);
    }
  }
  
  // Handle return value if needed - EXACTLY like original: arguments[[length(arguments) + 1]] <- outputfile
  if (return_value && result.num_returns > 0) {
    processed_args.push_back(result.return_value_filename);
    result.arguments_names.push_back(result.return_value_name);
  }
  
  // ALWAYS update names after any modifications - ensure names match the current size
  // CRITICAL: Use proper string vector initialization to avoid R_NaString issues
  std::vector<std::string> final_names_str(processed_args.size(), "");
  for (int i = 0; i < processed_args.size() && i < result.arguments_names.size(); ++i) {
    if (!result.arguments_names[i].empty()) {
      final_names_str[i] = result.arguments_names[i];
    }
  }
  Rcpp::CharacterVector final_names = Rcpp::wrap(final_names_str);
  processed_args.attr("names") = final_names;
  
  // Verify names are still set after modifications
  if (!processed_args.hasAttribute("names")) {
    Rcpp::stop("Names lost after modifications - processed_args size: %d", processed_args.size());
  }
  Rcpp::CharacterVector verify_names = processed_args.names();
  if (verify_names.size() != processed_args.size()) {
    Rcpp::stop("Names size mismatch after modifications - processed_args size: %d, names size: %d", 
               processed_args.size(), verify_names.size());
  }
  
  // CRITICAL: Ensure processed_args has names before assigning to result
  // Double-check names are set
  if (!processed_args.hasAttribute("names")) {
    Rcpp::stop("processed_args missing names before assignment to result");
  }
  Rcpp::CharacterVector final_check_names = processed_args.names();
  if (final_check_names.size() != processed_args.size()) {
    Rcpp::stop("processed_args names size mismatch: list size %d, names size %d", 
               processed_args.size(), final_check_names.size());
  }
  
  result.processed_arguments = processed_args;
  
  // Convert to R list - ensure all elements are properly named
  // CRITICAL: Use Rcpp::List::create with Named() to ensure proper structure
  
  // Verify processed_arguments one more time before putting it in result
  Rcpp::List verify_processed = result.processed_arguments;
  if (!verify_processed.hasAttribute("names")) {
    Rcpp::stop("result.processed_arguments missing names in final check");
  }
  
  Rcpp::List r_result = Rcpp::List::create(
    Rcpp::Named("processed_arguments") = result.processed_arguments,
    Rcpp::Named("arguments_names") = Rcpp::wrap(result.arguments_names),
    Rcpp::Named("arguments_type") = Rcpp::wrap(result.arguments_type),
    Rcpp::Named("content_types") = Rcpp::wrap(result.content_types),
    Rcpp::Named("compss_directions") = Rcpp::wrap(result.compss_directions),
    Rcpp::Named("compss_streams") = Rcpp::wrap(result.compss_streams),
    Rcpp::Named("compss_prefixes") = Rcpp::wrap(result.compss_prefixes),
    Rcpp::Named("weights") = Rcpp::wrap(result.weights),
    Rcpp::Named("keep_renames") = Rcpp::wrap(result.keep_renames),
    Rcpp::Named("num_returns") = result.num_returns,
    Rcpp::Named("return_value_filename") = result.return_value_filename,
    Rcpp::Named("return_value_name") = result.return_value_name,
    Rcpp::Named("register_marker") = result.register_marker,
    Rcpp::Named("type_args_path") = result.type_args_path,
    Rcpp::Named("success") = result.success,
    Rcpp::Named("error_message") = result.error_message
  );

  return r_result;
}

// ============================================================================
// Task Decorator - Complete C++ Implementation (replaces task.R entirely)
// ============================================================================

//' task - Main task decorator function (C++ implementation)
//' 
//' This is the main entry point that creates the task decorator.
//' All logic is in C++ TaskDecorator class - this is just a thin Rcpp export wrapper.
//' 
//' @param f The function to be executed
//' @param filename Character. The file where the function is defined
//' @param return_value Boolean. Default value is FALSE. Whether there is a return value
//' @param return_type Character. Default value is "list". Return type ("list" or "element")
//' @param ser_method Character vector. Default value is c("qs", "qs"). Serialization method
//' @param info_only Boolean. Whether the run is to print the information only
//' @param DEBUG Boolean. Whether to print debug information
//' @param f_name Character. The name of the function (extracted from match.call() in R wrapper)
//' @return The decorated function (R function closure)
// [[Rcpp::export]]
Rcpp::Function task(
    SEXP f,
    const std::string& filename,
    bool return_value = false,
    const std::string& return_type = "list",
    Rcpp::CharacterVector ser_method = Rcpp::CharacterVector::create("cpp", "cpp"),
    bool info_only = false,
    bool DEBUG = false,
    const std::string& f_name = "")
{
  
  try {
    std::string extracted_f_name = f_name;
    
    // If f_name is empty, try to extract it from the calling context
    // Use match.call() in the parent frame to get the original call
    if (extracted_f_name.empty()) {
      
      try {
        // Get parent frame
        Rcpp::Function parent_frame("parent.frame");
        Rcpp::Environment parent_env = parent_frame();
        
        // Use match.call() in the parent frame to get the call with unevaluated arguments
        Rcpp::Function match_call("match.call");
        Rcpp::Function task_func("task");
        Rcpp::Function sys_call("sys.call");
        
        // Get the call from parent frame
        Rcpp::Language parent_call_expr = sys_call(Rcpp::_["which"] = 0);
        
        // Use match.call to get the formal argument matching
        Rcpp::Language matched = match_call(task_func, parent_call_expr);
        Rcpp::Function as_list("as.list");
        Rcpp::List matched_list = as_list(matched);
        
        // Get the 'f' argument
        if (matched_list.containsElementNamed("f")) {
          SEXP f_arg = matched_list["f"];
          // Deparse to get the name
          Rcpp::Function deparse_func("deparse");
          Rcpp::CharacterVector f_name_vec = deparse_func(f_arg);
          if (f_name_vec.size() > 0) {
            extracted_f_name = Rcpp::as<std::string>(f_name_vec[0]);
          }
        }
      } catch (const std::exception& e) {
      } catch (...) {
      }
    }
    
    
    // All logic is in TaskDecorator class - just call it
    Rcpp::Function result = RCOMPSs::core::TaskDecorator::createTaskDecorator(
      f, filename, return_value, return_type, ser_method, info_only, DEBUG, extracted_f_name);
    
    
    return result;
  } catch (const std::exception& e) {
    throw;
  } catch (...) {
    throw;
  }
}

// ============================================================================
// Serialization Functions - C++ Implementation (custom binary serializer)
// ============================================================================

#include <core/Serialization.hpp>

//' Serialize R object to file (C++ implementation)
//' 
//' This C++ function supports three serialization methods:
//' - "cpp": Native C++ serializer (default)
//' - "qs": Uses qs package
//' - "RMVL": Uses RMVL package
//' 
//' The default method can be set via RCOMPSs_SERIALIZATION environment variable.
//' 
//' @param object R object to serialize
//' @param filepath File path to save serialized object
//' @param ser_method Serialization method ("cpp", "qs", or "RMVL"). If empty, uses RCOMPSs_SERIALIZATION env var or "cpp"
//' @param mthreads Number of threads for serialization

// Forward declaration of helper function
void write_debug_log(const std::string& msg);

// [[Rcpp::export]]
void rcompss_serialize(SEXP object, const std::string& filepath, const std::string& ser_method, int mthreads = 1)
{
  try {
    // Determine which method to use
    std::string method = ser_method;
    if (method.empty()) {
      method = get_default_serialization_method();
      Rcpp::Rcerr << "[C++ SERIALIZE] ser_method not specified, using default: " << method << "\n";
    }
    
    // Normalize method name for comparison (case-insensitive)
    std::string method_lower = method;
    std::transform(method_lower.begin(), method_lower.end(), method_lower.begin(), ::tolower);
    
    if (method_lower == "cpp") {
      // Use native C++ serializer
    Rcpp::Rcerr << "[C++ SERIALIZE] Using native C++ serializer -> " << filepath << "\n";
    std::cerr << "[C++ SERIALIZE] Using native C++ serializer -> " << filepath << "\n";
    std::cerr.flush();
    RCOMPSs::core::Serialization::serializeSEXP(object, filepath);
    // Verify file was created with correct magic header
    std::ifstream verify(filepath, std::ios::binary);
    if (verify.good()) {
      std::uint32_t magic = 0;
      verify.read(reinterpret_cast<char*>(&magic), sizeof(magic));
      constexpr std::uint32_t kCppMagic = 0x52535343;  // "RCSS"
      if (magic == kCppMagic) {
        Rcpp::Rcerr << "[C++ SERIALIZE] ✓ Verified: File has C++ magic header (0x52535343)\n";
        std::cerr << "[C++ SERIALIZE] ✓ Verified: File has C++ magic header (0x52535343)\n";
        std::cerr.flush();
      }
      }
    } else if (method_lower == "qs") {
      // Replicate old R code: qs::qsave(object, file = filepath, preset = "uncompressed", nthreads = mthreads)
      write_debug_log("[DEBUG] rcompss_serialize: Using qs serializer -> " + filepath);
      Rcpp::Rcerr << "[C++ SERIALIZE] Using qs serializer -> " << filepath << "\n";
      std::cerr << "[C++ SERIALIZE] Using qs serializer -> " << filepath << "\n";
      std::cerr.flush();
      
      // First ensure namespace is loaded
      Rcpp::Function requireNamespace_func("requireNamespace");
      write_debug_log("[DEBUG] rcompss_serialize: Step 1: Calling requireNamespace('qs')");
      bool ns_loaded = Rcpp::as<bool>(requireNamespace_func("qs", Rcpp::_["quietly"] = true));
      if (!ns_loaded) {
        write_debug_log("[DEBUG] rcompss_serialize: ERROR: Failed to load qs package namespace");
        Rcpp::stop("Failed to load qs package namespace. Is qs installed?");
      }
      write_debug_log("[DEBUG] rcompss_serialize: Step 1a: requireNamespace('qs') returned: TRUE");
      
      // Get namespace and function - exactly like old R code
      Rcpp::Function getNamespace_func("getNamespace");
      write_debug_log("[DEBUG] rcompss_serialize: Step 2: Calling getNamespace('qs')");
      Rcpp::Environment qs_env = Rcpp::as<Rcpp::Environment>(getNamespace_func("qs"));
      write_debug_log("[DEBUG] rcompss_serialize: Step 2a: Successfully got qs namespace");
      Rcpp::Function qs_qsave = qs_env["qsave"];
      write_debug_log("[DEBUG] rcompss_serialize: Step 3: Successfully got qsave function");
      
      // Call qs::qsave directly - exactly like old R code: qs::qsave(object, file = filepath, preset = "uncompressed", nthreads = mthreads)
      write_debug_log("[DEBUG] rcompss_serialize: Step 4: About to call qs::qsave with file=" + filepath + ", nthreads=" + std::to_string(mthreads));
      
      try {
        // Call qs::qsave with object as first positional argument, then named arguments
        // qs::qsave signature: qsave(x, file, preset = "high", algorithm = "zstd", compress_level = 4L, nthreads = 1L, ...)
        qs_qsave(object, 
                 Rcpp::_["file"] = filepath, 
                 Rcpp::_["preset"] = "uncompressed", 
                 Rcpp::_["nthreads"] = mthreads);
        write_debug_log("[DEBUG] rcompss_serialize: Step 5: qs::qsave call completed");
        
        // Verify file was created and is valid QS format
        std::ifstream verify(filepath, std::ios::binary);
        if (!verify.good()) {
          write_debug_log("[DEBUG] rcompss_serialize: ERROR: File was not created: " + filepath);
          Rcpp::stop("qs::qsave did not create file: %s", filepath);
        }
        verify.close();
        write_debug_log("[DEBUG] rcompss_serialize: Step 6: File created successfully");
      } catch (const Rcpp::exception& e) {
        write_debug_log("[DEBUG] rcompss_serialize: ERROR in qs_qsave call: Rcpp exception: " + std::string(e.what()));
        throw;
      } catch (const std::exception& e) {
        write_debug_log("[DEBUG] rcompss_serialize: ERROR in qs_qsave call: std exception: " + std::string(e.what()));
        throw;
      } catch (...) {
        write_debug_log("[DEBUG] rcompss_serialize: ERROR in qs_qsave call: unknown exception");
        // Try to get the last R error
        try {
          Rcpp::Function geterrmessage_func("geterrmessage");
          std::string r_error = Rcpp::as<std::string>(geterrmessage_func());
          write_debug_log("[DEBUG] rcompss_serialize: Last R error message: " + r_error);
          Rcpp::stop("R error in qs::qsave: %s", r_error);
        } catch (...) {
          write_debug_log("[DEBUG] rcompss_serialize: Could not get R error message");
          Rcpp::stop("Unknown error calling qs::qsave");
        }
      }
    } else if (method_lower == "rmvl") {
      // Replicate old R code: RMVL::mvl_open(filepath, append = TRUE, create = TRUE); RMVL::mvl_write_object(con, object, name = "obj"); RMVL::mvl_close(con)
      Rcpp::Rcerr << "[C++ SERIALIZE] Using RMVL serializer -> " << filepath << "\n";
      std::cerr << "[C++ SERIALIZE] Using RMVL serializer -> " << filepath << "\n";
      std::cerr.flush();
      // Replicate old R code: RMVL::mvl_open(filepath, append = TRUE, create = TRUE); RMVL::mvl_write_object(con, object, name = "obj"); RMVL::mvl_close(con)
      // Use getNamespace() to get RMVL namespace, then call functions
      // This replicates R's :: operator behavior
      try {
        Rcpp::Function getNamespace_func("getNamespace");
        Rcpp::Environment rmvl_env = Rcpp::as<Rcpp::Environment>(getNamespace_func("RMVL"));
        Rcpp::Function mvl_open = rmvl_env["mvl_open"];
        Rcpp::Function mvl_write_object = rmvl_env["mvl_write_object"];
        Rcpp::Function mvl_close = rmvl_env["mvl_close"];
        // mvl_open expects filename as first positional argument
        SEXP con = mvl_open(filepath, Rcpp::_["append"] = true, Rcpp::_["create"] = true);
        mvl_write_object(con, object, Rcpp::_["name"] = "obj");
        mvl_close(con);
      } catch (const Rcpp::exception& e) {
        // Try using requireNamespace to ensure package is available
        Rcpp::Function requireNamespace_func("requireNamespace");
        bool ns_loaded = Rcpp::as<bool>(requireNamespace_func("RMVL", Rcpp::_["quietly"] = false));
        if (!ns_loaded) {
          Rcpp::stop("Failed to load RMVL package namespace");
        }
        // Retry after loading
        Rcpp::Function getNamespace_func("getNamespace");
        Rcpp::Environment rmvl_env = Rcpp::as<Rcpp::Environment>(getNamespace_func("RMVL"));
        Rcpp::Function mvl_open = rmvl_env["mvl_open"];
        Rcpp::Function mvl_write_object = rmvl_env["mvl_write_object"];
        Rcpp::Function mvl_close = rmvl_env["mvl_close"];
        // mvl_open expects filename as first positional argument
        SEXP con = mvl_open(filepath, Rcpp::_["append"] = true, Rcpp::_["create"] = true);
        mvl_write_object(con, object, Rcpp::_["name"] = "obj");
        mvl_close(con);
      }
    } else {
      Rcpp::stop("Unknown serialization method: '%s'. Valid methods: cpp, qs, RMVL", method);
    }
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to serialize object: %s", e.what());
  }
}

//' Unserialize R object from file (C++ implementation)
//' 
//' This C++ function uses the C++ serializer for cpp-prefixed files and
//' falls back to legacy qs/RMVL readers for older files.
//' Only uses C++ unserialization if the file was actually created with C++ serialization.
//' 
//' @param filepath File path to read serialized object from
//' @param mthreads Number of threads for unserialization
//' @return Unserialized R object
// Helper function to write debug message to file
void write_debug_log(const std::string& msg) {
  // Write to a debug log file in /tmp
  std::string log_file = "/tmp/rcompss_debug_" + std::to_string(getpid()) + ".log";
  std::ofstream log(log_file, std::ios::app);
  if (log.is_open()) {
    log << msg << std::endl;
    log.flush();
    log.close();
  }
  // Also write to stderr
  std::cerr << msg << std::endl;
  std::cerr.flush();
  Rcpp::Rcerr << msg << std::endl;
  Rcpp::Rcerr.flush();
}

// [[Rcpp::export]]
SEXP rcompss_unserialize(const std::string& filepath, int mthreads = 1)
{
  try {
    std::string method = RCOMPSs::core::PathUtils::extractSerializationMethod(filepath);
    // For cpp-prefixed files, verify it's actually C++ format before using C++ unserializer
    if (method == "cpp") {
      Rcpp::Rcerr.flush();
      // Check magic header to ensure file was created with C++ serializer
      std::ifstream verify(filepath, std::ios::binary);
      if (verify.good()) {
        std::uint32_t magic = 0;
        verify.read(reinterpret_cast<char*>(&magic), sizeof(magic));
        constexpr std::uint32_t kCppMagic = 0x52535343;  // "RCSS"
        if (magic == kCppMagic) {
          // File has C++ magic header - safe to use C++ unserializer
          Rcpp::Rcerr.flush();
          return RCOMPSs::core::Serialization::unserializeSEXP(filepath);
        } else {
          // File has cpp prefix but wrong magic header - this shouldn't happen
          Rcpp::Rcerr << "[C++ SERIALIZE] WARNING: File has 'cpp' prefix but wrong magic header (0x"
                      << std::hex << magic << std::dec << "). Attempting C++ unserialization anyway.\n";
          Rcpp::Rcerr.flush();
          // Still try C++ unserializer - it will throw if format is wrong
          return RCOMPSs::core::Serialization::unserializeSEXP(filepath);
        }
      } else {
        Rcpp::Rcerr << "[DEBUG] ERROR: Failed to open file for verification: " << filepath << "\n";
        Rcpp::Rcerr.flush();
        Rcpp::stop("Failed to open file for verification: %s", filepath);
      }
    }
    
    // Legacy formats - use their respective unserializers
    // Replicate old R code: qs::qread(filepath, nthreads = mthreads)
    if (method == "qs") {
      write_debug_log("[DEBUG] Method is 'qs', starting qs unserialization");
      write_debug_log("[C++ SERIALIZE] Using legacy qs reader <- " + filepath);
      
      // First ensure namespace is loaded
      write_debug_log("[DEBUG] Step 1: Calling requireNamespace('qs')");
      Rcpp::Function requireNamespace_func("requireNamespace");
      bool ns_loaded = false;
      try {
        write_debug_log("[DEBUG] Step 1a: About to call requireNamespace");
        ns_loaded = Rcpp::as<bool>(requireNamespace_func("qs", Rcpp::_["quietly"] = true));
        write_debug_log("[DEBUG] Step 1b: requireNamespace('qs') returned: " + std::string(ns_loaded ? "TRUE" : "FALSE"));
      } catch (const Rcpp::exception& e) {
        write_debug_log("[DEBUG] ERROR in requireNamespace: Rcpp exception: " + std::string(e.what()));
        throw;
      } catch (const std::exception& e) {
        write_debug_log("[DEBUG] ERROR in requireNamespace: std exception: " + std::string(e.what()));
        throw;
      } catch (...) {
        write_debug_log("[DEBUG] ERROR in requireNamespace: unknown exception");
        throw;
      }
      
      if (!ns_loaded) {
        write_debug_log("[DEBUG] ERROR: qs namespace not loaded");
        Rcpp::stop("Failed to load qs package namespace. Is qs installed?");
      }
      
      // Now get the namespace and call qread
      write_debug_log("[DEBUG] Step 2: Calling getNamespace('qs')");
      Rcpp::Function getNamespace_func("getNamespace");
      Rcpp::Environment qs_env;
      try {
        write_debug_log("[DEBUG] Step 2a: About to call getNamespace");
        qs_env = Rcpp::as<Rcpp::Environment>(getNamespace_func("qs"));
        write_debug_log("[DEBUG] Step 2b: Successfully got qs namespace");
      } catch (const Rcpp::exception& e) {
        write_debug_log("[DEBUG] ERROR in getNamespace: Rcpp exception: " + std::string(e.what()));
        throw;
      } catch (const std::exception& e) {
        write_debug_log("[DEBUG] ERROR in getNamespace: std exception: " + std::string(e.what()));
        throw;
      } catch (...) {
        write_debug_log("[DEBUG] ERROR in getNamespace: unknown exception");
        throw;
      }
      
      write_debug_log("[DEBUG] Step 3: Getting qread function from namespace");
      Rcpp::Function qs_qread = qs_env["qread"];
      write_debug_log("[DEBUG] Step 3a: Successfully got qread function");
      
      write_debug_log("[DEBUG] Step 4: Calling qs::qread with file=" + filepath + ", nthreads=" + std::to_string(mthreads));
      
      // Check if file exists first
      std::ifstream file_check(filepath);
      if (!file_check.good()) {
        write_debug_log("[DEBUG] ERROR: File does not exist or cannot be opened: " + filepath);
        Rcpp::stop("File does not exist or cannot be opened: %s", filepath);
      }
      file_check.close();
      write_debug_log("[DEBUG] Step 4a: File exists, about to call qs::qread");
      
      // Call qs::qread directly - exactly like old R code: qs::qread(filepath, nthreads = mthreads)
      // qs::qread signature: qread(file, use_alt_rep = FALSE, strict = FALSE, nthreads = 1L)
      try {
        SEXP result = qs_qread(Rcpp::_["file"] = filepath, Rcpp::_["nthreads"] = mthreads);
        write_debug_log("[DEBUG] Step 4b: qs::qread succeeded, returning result");
        return result;
      } catch (const Rcpp::exception& e) {
        write_debug_log("[DEBUG] ERROR in qs_qread call: Rcpp exception: " + std::string(e.what()));
        throw;
      } catch (const std::exception& e) {
        write_debug_log("[DEBUG] ERROR in qs_qread call: std exception: " + std::string(e.what()));
        throw;
      } catch (...) {
        write_debug_log("[DEBUG] ERROR in qs_qread call: unknown exception");
        // Try to get the last R error
        try {
          Rcpp::Function geterrmessage_func("geterrmessage");
          std::string r_error = Rcpp::as<std::string>(geterrmessage_func());
          write_debug_log("[DEBUG] Last R error message: " + r_error);
          Rcpp::stop("R error in qs::qread: %s", r_error);
        } catch (...) {
          write_debug_log("[DEBUG] Could not get R error message");
          Rcpp::stop("Unknown error calling qs::qread");
        }
      }
    }
    // Replicate old R code: RMVL::mvl_open(filepath); RMVL::mvl2R(con$obj); RMVL::mvl_close(con)
    if (method == "RMVL") {
      Rcpp::Rcerr << "[C++ SERIALIZE] Using legacy RMVL reader <- " << filepath << "\n";
      std::cerr << "[C++ SERIALIZE] Using legacy RMVL reader <- " << filepath << "\n";
      std::cerr.flush();
      // First ensure namespace is loaded
      Rcpp::Function requireNamespace_func("requireNamespace");
      bool ns_loaded = Rcpp::as<bool>(requireNamespace_func("RMVL", Rcpp::_["quietly"] = true));
      if (!ns_loaded) {
        Rcpp::stop("Failed to load RMVL package namespace. Is RMVL installed?");
      }
      // Now get the namespace and call functions
      Rcpp::Function getNamespace_func("getNamespace");
      Rcpp::Environment rmvl_env = Rcpp::as<Rcpp::Environment>(getNamespace_func("RMVL"));
      Rcpp::Function mvl_open = rmvl_env["mvl_open"];
      Rcpp::Function mvl2R = rmvl_env["mvl2R"];
      Rcpp::Function mvl_close = rmvl_env["mvl_close"];
      
      // con <- RMVL::mvl_open(filepath)
      // mvl_open expects filename as first positional argument
      SEXP con = mvl_open(filepath);
      
      // object <- RMVL::mvl2R(con$obj)
      // Use R's $ operator to access con$obj, then pass to mvl2R
      // In R: con$obj, which we can do via Rcpp::Language
      Rcpp::Function dollar_func("$");
      SEXP obj_sexp = dollar_func(con, "obj");
      SEXP result = mvl2R(obj_sexp);
      
      // RMVL::mvl_close(con)
      mvl_close(con);
      
      return result;
    }

    // Unknown format - try C++ unserializer as fallback (will fail if wrong format)
    write_debug_log("[DEBUG] Unknown format prefix '" + method + "', attempting C++ unserializer");
    write_debug_log("[C++ SERIALIZE] Unknown format prefix '" + method + "', attempting C++ unserializer <- " + filepath);
    return RCOMPSs::core::Serialization::unserializeSEXP(filepath);
  } catch (const Rcpp::exception& e) {
    write_debug_log("[DEBUG] Rcpp exception in rcompss_unserialize: " + std::string(e.what()));
    Rcpp::stop("Failed to unserialize object: %s", e.what());
  } catch (const std::exception& e) {
    write_debug_log("[DEBUG] std exception in rcompss_unserialize: " + std::string(e.what()));
    Rcpp::stop("Failed to unserialize object: %s", e.what());
  } catch (...) {
    write_debug_log("[DEBUG] Unknown exception in rcompss_unserialize");
    Rcpp::stop("Failed to unserialize object: unknown error");
  }
}

// ============================================================================
// Wait On Functions - C++ Implementation
// ============================================================================

//' Wait on future object (C++ implementation)
//' 
//' This C++ function handles waiting on future objects, lists, and future_object_path.
//' 
//' @param future_obj Future object to wait on
//' @param mthreads Number of threads for serialization
//' @param nthreads Number of threads for parallel processing
//' @return Deserialized result
// [[Rcpp::export]]
SEXP rcompss_wait_on(SEXP future_obj, int mthreads = 1, int nthreads = 1)
{
  try {
    // Check if it's a future_object
    if (rcompss_is_future_object(future_obj)) {
      Rcpp::List fo = Rcpp::as<Rcpp::List>(future_obj);
      std::string outputfile = Rcpp::as<std::string>(fo["outputfile"]);
      
      Get_File(0L, outputfile);
      return rcompss_unserialize(outputfile, mthreads);
    }
    
    // Check if it's a list
    if (rcompss_is_list(future_obj)) {
      Rcpp::List obj_list = Rcpp::as<Rcpp::List>(future_obj);
      Rcpp::List return_list(obj_list.size());
      
      for (int i = 0; i < obj_list.size(); ++i) {
        SEXP obj = obj_list[i];
        if (rcompss_is_future_object(obj)) {
          Rcpp::List fo = Rcpp::as<Rcpp::List>(obj);
          std::string outputfile = Rcpp::as<std::string>(fo["outputfile"]);
          Get_File(0L, outputfile);
          return_list[i] = rcompss_unserialize(outputfile, mthreads);
        } else {
          return_list[i] = obj;
        }
      }
      return return_list;
    }
    
    // Check if it's a future_object_path
    if (rcompss_is_future_object_path(future_obj)) {
      Rcpp::CharacterVector paths = Rcpp::as<Rcpp::CharacterVector>(future_obj);
      Rcpp::List return_list(paths.size());
      
      for (int i = 0; i < paths.size(); ++i) {
        std::string file = Rcpp::as<std::string>(paths[i]);
        try {
          Get_File(0L, file);
          return_list[i] = rcompss_unserialize(file, mthreads);
        } catch (...) {
          Rcpp::warning("File %s does not exist. Returning the original character.", file);
          return_list[i] = file;
        }
      }
      return return_list;
    }
    
    // Unknown type - return as is
    Rcpp::warning("Unknown future object type. Returning as is.");
    return future_obj;
    
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to wait on future object: %s", e.what());
  }
}

// ============================================================================
// GPU Context Management Functions
// ============================================================================

// ============================================================================
// GPU Memory smoke-test (ContextManager + MemoryHandler)
// ============================================================================

// [[Rcpp::export]]
Rcpp::NumericVector rcompss_gpu_memory_roundtrip_double(Rcpp::NumericVector x) {
#ifdef USE_CUDA
  try {
    auto ctx = rcompss::kernels::ContextManager::GetOperationContext();
    if (ctx == nullptr) {
      Rcpp::stop("No active operation context. Call rcompss_set_operation_context() first.");
    }
    if (ctx->GetOperationPlacement() == rcompss::gpu::CPU) {
      Rcpp::stop("Active operation context is CPU. Set placement to GPU and set a GPU operation context.");
    }

    // Force sync mode for deterministic behavior in tests
    ctx->SetRunMode(rcompss::gpu::RunMode::SYNC);

    const size_t n = static_cast<size_t>(x.size());
    const size_t bytes = n * sizeof(double);

    char *d_buf = rcompss::memory::AllocateArray(bytes, rcompss::gpu::GPU, ctx);
    char *h_out = rcompss::memory::AllocateArray(bytes, rcompss::gpu::CPU, ctx);
    if (bytes > 0 && (d_buf == nullptr || h_out == nullptr)) {
      Rcpp::stop("Memory allocation failed (device or host buffer).");
    }

    rcompss::memory::MemCpy(
        d_buf,
        reinterpret_cast<const char *>(REAL(x)),
        bytes,
        ctx,
        rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);

    rcompss::memory::MemCpy(
        h_out,
        d_buf,
        bytes,
        ctx,
        rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);

    Rcpp::NumericVector y(x.size());
    if (bytes > 0) {
      std::memcpy(reinterpret_cast<void *>(REAL(y)), h_out, bytes);
    }

    rcompss::memory::DestroyArray(d_buf, rcompss::gpu::GPU, ctx);
    rcompss::memory::DestroyArray(h_out, rcompss::gpu::CPU, ctx);
    return y;
  } catch (const std::exception &e) {
    Rcpp::stop("GPU memory roundtrip failed: %s", e.what());
  }
#else
  Rcpp::stop("RCOMPSs was built without CUDA support (USE_CUDA is not defined).");
#endif
}

// [[Rcpp::export]]
void rcompss_create_gpu_context(std::string context_name) {
  try {
    rcompss::adapters::CreateRunContext(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to create GPU context: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_set_operation_placement(std::string context_name, std::string placement) {
  try {
    rcompss::adapters::SetOperationPlacement(context_name, placement);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to set operation placement: %s", e.what());
  }
}

// [[Rcpp::export]]
std::string rcompss_get_operation_placement(std::string context_name) {
  try {
    return rcompss::adapters::GetOperationPlacement(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to get operation placement: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_set_run_mode(std::string context_name, std::string run_mode) {
  try {
    rcompss::adapters::SetRunMode(context_name, run_mode);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to set run mode: %s", e.what());
  }
}

// [[Rcpp::export]]
std::string rcompss_get_run_mode(std::string context_name) {
  try {
    return rcompss::adapters::GetRunMode(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to get run mode: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_sync_context(std::string context_name) {
  try {
    rcompss::adapters::SyncContext(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to sync context: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_sync_all_contexts() {
  try {
    rcompss::adapters::SyncAll();
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to sync all contexts: %s", e.what());
  }
}

// [[Rcpp::export]]
int rcompss_get_num_contexts() {
  try {
    return static_cast<int>(rcompss::adapters::GetNumOfContexts());
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to get number of contexts: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_set_operation_context(std::string context_name) {
  try {
    rcompss::adapters::SetOperationContext(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to set operation context: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_delete_context(std::string context_name) {
  try {
    rcompss::adapters::DeleteRunContext(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to delete context: %s", e.what());
  }
}

// [[Rcpp::export]]
std::vector<std::string> rcompss_get_all_context_names() {
  try {
    return rcompss::adapters::GetAllContextNames();
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to get context names: %s", e.what());
  }
}

// [[Rcpp::export]]
void rcompss_finalize_context(std::string context_name) {
  try {
    rcompss::adapters::FinalizeRunContext(context_name);
  } catch (const std::exception& e) {
    Rcpp::stop("Failed to finalize context: %s", e.what());
  }
}

// ============================================================================
// GPU Vector Computation Functions
// ============================================================================

#ifdef USE_CUDA
// Opaque handle for R-allocated GPU buffer (ptr + size in bytes)
struct GpuBufferHandle {
  char* ptr;
  size_t size_bytes;
};

static void gpu_buffer_finalizer(SEXP sexp) {
  GpuBufferHandle* buf = (GpuBufferHandle*) R_ExternalPtrAddr(sexp);
  if (buf && buf->ptr) {
    rcompss::memory::DestroyArray(buf->ptr, rcompss::gpu::GPU, nullptr);
    buf->ptr = nullptr;
  }
  delete buf;
  R_ClearExternalPtr(sexp);
}

static GpuBufferHandle* check_gpu_handle(SEXP handle) {
  if (handle == R_NilValue || TYPEOF(handle) != EXTPTRSXP)
    Rcpp::stop("Invalid GPU buffer handle (expected external pointer from rcompss_gpu_alloc).");
  GpuBufferHandle* buf = (GpuBufferHandle*) R_ExternalPtrAddr(handle);
  if (!buf || !buf->ptr)
    Rcpp::stop("GPU buffer handle is null or already freed.");
  return buf;
}
#endif

//' Allocate GPU memory from R (number of double elements).
//' Returns an external pointer handle; free with rcompss_gpu_free or by GC.
// [[Rcpp::export]]
SEXP rcompss_gpu_alloc(int n) {
#ifdef USE_CUDA
  if (n <= 0) Rcpp::stop("rcompss_gpu_alloc: n must be positive.");
  auto ctx = rcompss::kernels::ContextManager::GetOperationContext();
  if (!ctx || ctx->GetOperationPlacement() != rcompss::gpu::GPU)
    Rcpp::stop("Active context must be GPU. Set placement and operation context first.");
  size_t bytes = static_cast<size_t>(n) * sizeof(double);
  char* ptr = rcompss::memory::AllocateArray(bytes, rcompss::gpu::GPU, ctx);
  if (!ptr) Rcpp::stop("GPU allocation failed.");
  GpuBufferHandle* buf = new GpuBufferHandle{ptr, bytes};
  SEXP result = R_MakeExternalPtr(buf, R_NilValue, R_NilValue);
  R_RegisterCFinalizer(result, gpu_buffer_finalizer);
  return result;
#else
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return R_NilValue;
#endif
}

//' Copy R numeric vector to GPU buffer (host to device).
// [[Rcpp::export]]
void rcompss_copy_to_gpu(Rcpp::NumericVector r_vec, SEXP gpu_handle) {
#ifdef USE_CUDA
  GpuBufferHandle* buf = check_gpu_handle(gpu_handle);
  size_t bytes = static_cast<size_t>(r_vec.size()) * sizeof(double);
  if (bytes > buf->size_bytes)
    Rcpp::stop("Vector length exceeds GPU buffer size.");
  auto ctx = rcompss::kernels::ContextManager::GetOperationContext();
  rcompss::memory::MemCpy(buf->ptr, reinterpret_cast<const char*>(REAL(r_vec)), bytes, ctx,
                          rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
#else
  (void)r_vec; (void)gpu_handle;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
#endif
}

//' Copy GPU buffer to R (device to host). Returns a new numeric vector.
// [[Rcpp::export]]
Rcpp::NumericVector rcompss_copy_from_gpu(SEXP gpu_handle) {
#ifdef USE_CUDA
  GpuBufferHandle* buf = check_gpu_handle(gpu_handle);
  size_t n = buf->size_bytes / sizeof(double);
  Rcpp::NumericVector result(n);
  if (n > 0) {
    auto ctx = rcompss::kernels::ContextManager::GetOperationContext();
    rcompss::memory::MemCpy(reinterpret_cast<char*>(REAL(result)), buf->ptr, buf->size_bytes, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
  }
  return result;
#else
  (void)gpu_handle;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericVector();
#endif
}

//' Free GPU buffer. Safe to call multiple times; handle is invalidated.
// [[Rcpp::export]]
void rcompss_gpu_free(SEXP gpu_handle) {
#ifdef USE_CUDA
  if (gpu_handle == R_NilValue || TYPEOF(gpu_handle) != EXTPTRSXP) return;
  GpuBufferHandle* buf = (GpuBufferHandle*) R_ExternalPtrAddr(gpu_handle);
  if (buf && buf->ptr) {
    rcompss::memory::DestroyArray(buf->ptr, rcompss::gpu::GPU, nullptr);
    buf->ptr = nullptr;
  }
  delete buf;
  R_ClearExternalPtr(gpu_handle);
#else
  (void)gpu_handle;
#endif
}

//' Run vector addition kernel only (inputs and output are GPU buffers allocated from R).
// [[Rcpp::export]]
void rcompss_gpu_vector_add_kernel(SEXP d_a_handle, SEXP d_b_handle, SEXP d_result_handle) {
#ifdef USE_CUDA
  GpuBufferHandle* a = check_gpu_handle(d_a_handle);
  GpuBufferHandle* b = check_gpu_handle(d_b_handle);
  GpuBufferHandle* r = check_gpu_handle(d_result_handle);
  size_t n = r->size_bytes / sizeof(double);
  if (a->size_bytes < n * sizeof(double) || b->size_bytes < n * sizeof(double))
    Rcpp::stop("Input buffers too small for result length.");
  auto ctx = rcompss::kernels::ContextManager::GetOperationContext();
  double* d_a = reinterpret_cast<double*>(a->ptr);
  double* d_b = reinterpret_cast<double*>(b->ptr);
  double* d_result = reinterpret_cast<double*>(r->ptr);
  rcompss::kernels::CudaVectorKernels::VectorAdd(d_a, d_b, d_result, n, ctx);
#else
  (void)d_a_handle; (void)d_b_handle; (void)d_result_handle;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
#endif
}

// [[Rcpp::export]]
Rcpp::NumericVector rcompss_gpu_vector_add(Rcpp::NumericVector a, Rcpp::NumericVector b) {
#ifdef USE_CUDA
  try {
    auto ctx = rcompss::kernels::ContextManager::GetOperationContext();
    if (ctx == nullptr) {
      Rcpp::stop("No active operation context. Call rcompss_set_operation_context() first.");
    }
    if (ctx->GetOperationPlacement() == rcompss::gpu::CPU) {
      Rcpp::stop("Active operation context is CPU. Set placement to GPU and set a GPU operation context.");
    }

    // Force sync mode for deterministic behavior
    ctx->SetRunMode(rcompss::gpu::RunMode::SYNC);

    if (a.size() != b.size()) {
      Rcpp::stop("Vectors must have the same size. a.size()=%d, b.size()=%d", a.size(), b.size());
    }

    const size_t n = static_cast<size_t>(a.size());
    const size_t bytes = n * sizeof(double);

    // Allocate device memory
    double *d_a = reinterpret_cast<double*>(rcompss::memory::AllocateArray(bytes, rcompss::gpu::GPU, ctx));
    double *d_b = reinterpret_cast<double*>(rcompss::memory::AllocateArray(bytes, rcompss::gpu::GPU, ctx));
    double *d_result = reinterpret_cast<double*>(rcompss::memory::AllocateArray(bytes, rcompss::gpu::GPU, ctx));
    
    if (bytes > 0 && (d_a == nullptr || d_b == nullptr || d_result == nullptr)) {
      Rcpp::stop("GPU memory allocation failed.");
    }

    // Copy input vectors to device
    rcompss::memory::MemCpy(
        reinterpret_cast<char*>(d_a),
        reinterpret_cast<const char*>(REAL(a)),
        bytes,
        ctx,
        rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);

    rcompss::memory::MemCpy(
        reinterpret_cast<char*>(d_b),
        reinterpret_cast<const char*>(REAL(b)),
        bytes,
        ctx,
        rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);

    // Perform vector addition on GPU
    rcompss::kernels::CudaVectorKernels::VectorAdd(d_a, d_b, d_result, n, ctx);

    // Allocate host memory for result
    char *h_result = rcompss::memory::AllocateArray(bytes, rcompss::gpu::CPU, ctx);
    if (h_result == nullptr) {
      Rcpp::stop("Host memory allocation failed.");
    }

    // Copy result back to host
    rcompss::memory::MemCpy(
        h_result,
        reinterpret_cast<char*>(d_result),
        bytes,
        ctx,
        rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);

    // Create R vector with result
    Rcpp::NumericVector result(n);
    if (bytes > 0) {
      std::memcpy(reinterpret_cast<void*>(REAL(result)), h_result, bytes);
    }

    // Cleanup - need to use char* variables since DestroyArray takes non-const reference
    char *d_a_char = reinterpret_cast<char*>(d_a);
    char *d_b_char = reinterpret_cast<char*>(d_b);
    char *d_result_char = reinterpret_cast<char*>(d_result);
    
    rcompss::memory::DestroyArray(d_a_char, rcompss::gpu::GPU, ctx);
    rcompss::memory::DestroyArray(d_b_char, rcompss::gpu::GPU, ctx);
    rcompss::memory::DestroyArray(d_result_char, rcompss::gpu::GPU, ctx);
    rcompss::memory::DestroyArray(h_result, rcompss::gpu::CPU, ctx);

    return result;
  } catch (const std::exception &e) {
    Rcpp::stop("GPU vector addition failed: %s", e.what());
  }
#else
  Rcpp::stop("RCOMPSs was built without CUDA support (USE_CUDA is not defined).");
#endif
}
