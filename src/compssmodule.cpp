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
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <unistd.h>
#include <GS_compss.h>
#include <extrae.h>
using namespace Rcpp;

#define DEBUG_MODE 0

//' Printout for debugging
//' @param str_to_print String to print if DEBUG_MODE is 1
void log_debug(std::string str_to_print)
{
  if (DEBUG_MODE)
  {
    Rcerr << str_to_print << std::endl;
  }
}

//' Bool to String converter
//' @param value Bool to convert to String
std::string boolToString(bool value) {
  return value ? "true" : "false";
}

//' Start a COMPSs-Runtime instance within interactive session
// [[Rcpp::export]]
void start_runtime_interactive(
  bool debug = false,
  bool graph = false,
  bool trace = false
  // int monitor = -1,
  // std::string project_xml = "",
  // std::string resources_xml = "",
  // bool summary = false,
  // std::string task_execution = "compss",
  // std::string storage_conf = "null",
  // std::string streaming_backend = "NONE",
  // std::string streaming_master_name = "null",
  // std::string streaming_master_port = "null",
  // int task_count = 50,
  // std::string app_name = "InteractiveMode",
  // std::string uuid = "",
  // std::string log_dir = "",
  // std::string master_working_dir = "/home/javier/.COMPSs/Interactive_01/tmpFiles",  // TODO: this should depend on the user home
  // std::string extrae_cfg = "null",
  // std::string extrae_final_directory = "null",
  // std::string comm = "NIO",
  // std::string conn = "es.bsc.compss.connectors.DefaultSSHConnector",
  // std::string master_name = "",
  // std::string master_port = "",
  // std::string scheduler = "es.bsc.compss.scheduler.lookahead.locality.LocalityTS",
  // std::string scheduler_config = "",
  // std::string jvm_workers = "-Xms1024m,-Xmx1024m,-Xmn400m",
  // std::string cpu_affinity = "automatic",
  // std::string gpu_affinity = "automatic",
  // std::string fpga_affinity = "automatic",
  // std::string fpga_reprogram = "",
  // std::string profile_input = "",
  // std::string profile_output = "",
  // bool external_adaptation = false,
  // bool shutdown_in_node_failure=false,
  // int io_executors = 0,
  // std::string env_script = "",
  // bool reuse_on_block = true,
  // bool nested_enabled = false,
  // bool tracing_task_dependencies = false,
  // std::string trace_label = "None",
  // int wcl = 0,
  // bool ear = false,
  // bool data_provenance = false,
  // std::string checkpoint_policy = "es.bsc.compss.checkpoint.policies.NoCheckpoint",
  // std::string checkpoint_params = "",
  // std::string checkpoint_folder = ""
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

  std::ofstream configFile(fileName);
  configFile << "-Djdk.lang.Process.launchMechanism=fork\n";
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
  configFile << "-Dcompss.master.workingDir=/home/javier/.COMPSs/Interactive_01/tmpFiles\n";  // << master_working_dir << "\n";
  configFile << "-Dcompss.log.dir=/home/javier/.COMPSs/Interactive_01/tmpFiles\n";  // << log_dir << "\n";
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
  configFile << "-Djava.library.path=" << COMPSS_HOME << "/Bindings/bindings-common/lib/:" <<  JAVA_HOME << "/lib/server/:/usr/lib64/mpi/gcc/openmpi/lib64/\n";
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
  char *ImplConstraintsCStr = &ImplConstraints[0];
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
void process_task(long int app_id, std::string signature, std::string on_failure,
                  int time_out, int priority, int num_nodes,
                  int reduce, int chunk_size, int replicated,
                  int distributed, int has_target, int num_returns,
                  List values, CharacterVector names, IntegerVector compss_types,
                  IntegerVector compss_directions, IntegerVector compss_streams,
                  CharacterVector compss_prefixes, CharacterVector content_types,
                  CharacterVector weights, IntegerVector keep_renames)
{

  log_debug("Process task:");
  log_debug("- App id: " + std::to_string(app_id));
  log_debug("- Signature: " + signature);
  log_debug("- On Failure: " + on_failure);
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
  char *temp_cptr = NULL;
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

  char *signature_char = &signature[0];
  char *on_failure_char = &on_failure[0];

  log_debug("Calling GS_ExecuteTaskNew...");
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
void Extrae_event_and_counters(extrae_type_t group, extrae_value_t id)
{
  log_debug("\nExtrae_event_and_counters");
  log_debug("- Group: " + std::to_string(group));
  log_debug("- id: " + std::to_string(id));
  Extrae_eventandcounters(group, id);
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
