#include <Rcpp.h>
#include <iostream>
#include <GS_compss.h>
using namespace Rcpp;

#define DEBUG_MODE 1

//' Printout for debugging
//' @param str_to_print String to print if DEBUG_MODE is 1
void debug(std::string str_to_print) {
    if(DEBUG_MODE){
      Rcerr << str_to_print << std::endl;
    }
}

//' Start a COMPSs-Runtime instance
//' @export
// [[Rcpp::export]]
void start_runtime(){
  debug("Start runtime");
  GS_On();
}

//' stop_runtime
//' 
//' Stop a COMPSs-Runtime instance
//' 
//' @param code The code to exit
//' @export
// [[Rcpp::export]]
void stop_runtime(int code){
  debug("Stop runtime with code: " + std::to_string(code));
  GS_Off(code);
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
//' @export
// [[Rcpp::export]]
void register_core_element(std::string CESignature, std::string ImplSignature, 
                           std::string ImplConstraints, std::string ImplType,
                           std::string ImplLocal, std::string ImplIO, 
                           CharacterVector prolog, CharacterVector epilog,
                           CharacterVector container, CharacterVector typeArgs) {
  debug("Register core element");
  
  char* CESignatureCStr = &CESignature[0];
  char* ImplSignatureCStr = &ImplSignature[0];
  char* ImplConstraintsCStr = &ImplConstraints[0];
  char* ImplTypeCStr = &ImplType[0];
  char* ImplLocalCStr = &ImplLocal[0];
  char* ImplIOCStr = &ImplIO[0];
  
  debug("- Core Element Signature: " + CESignature);
  debug("- Implementation Signature: " + ImplSignature);
  debug("- Implementation Constraints: " + ImplConstraints);
  debug("- Implementation Type: " + ImplType);
  debug("- Implementation Local: " + ImplLocal);
  debug("- Implementation IO: " + ImplIO);
  
  char** pro;
  char** epi;
  char** cont;
  char** ImplTypeArgs;
  
  int num_params = typeArgs.size();
  debug("- Implementation Type num args: " + std::to_string(num_params));
  
  pro = new char*[3];
  epi = new char*[3];
  cont = new char*[3];
  if(num_params > 0)
    ImplTypeArgs = new char*[num_params];
  
  std::string prolog0 = Rcpp::as<std::string>(prolog[0]);
  std::string prolog1 = Rcpp::as<std::string>(prolog[1]);
  std::string prolog2 = Rcpp::as<std::string>(prolog[2]);
  pro[0] = &prolog0[0];
  pro[1] = &prolog1[0];
  pro[2] = &prolog2[0];
  
  debug("- Prolog: " + prolog0 + "; " + prolog1 + "; " + prolog2);
  
  std::string epilog0 = Rcpp::as<std::string>(epilog[0]);
  std::string epilog1 = Rcpp::as<std::string>(epilog[1]);
  std::string epilog2 = Rcpp::as<std::string>(epilog[2]);
  epi[0] = &epilog0[0];
  epi[1] = &epilog1[0];
  epi[2] = &epilog2[0];
  
  debug("- Epilog: " + epilog0 + "; " + epilog1 + "; " + epilog2);
  
  std::string container0 = Rcpp::as<std::string>(container[0]);
  std::string container1 = Rcpp::as<std::string>(container[1]);
  std::string container2 = Rcpp::as<std::string>(container[2]);
  cont[0] = &container0[0];
  cont[1] = &container1[0];
  cont[2] = &container2[0];
  
  debug("- Container: " + container0 + "; " + container1 + "; " + container2);
  
  std::vector<std::string> stypeArgStorage; // Store the type arguments to ensure their lifetime
  stypeArgStorage.reserve(num_params);
  std::string typeArg;
  for (int i = 0; i < num_params; ++i) {
    typeArg = Rcpp::as<std::string>(typeArgs[i]);
    stypeArgStorage.push_back(typeArg);
    ImplTypeArgs[i] = &(stypeArgStorage[i][0]);
    debug("- Implementation Type Args: " + typeArg);
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
  
  debug("Core element registered");
}

int _get_type_size(int type){
  switch(type){
  case 0:
    debug("- Type: logical");
    return sizeof(int);
  case 4:
    debug("- Type: integer");
    return sizeof(int);
  case 7:
    debug("- Type: double");
    return sizeof(double);
  case 8:
    debug("- Type: string");
    return sizeof(char*);
  }
  debug("Type not implemented yet");
  exit(3);
  return -1;
}

//' process_task
//' 
//' Define the Rcpp function
//' 
//' @export
// [[Rcpp::export]]
void process_task(long int app_id, std::string signature, std::string on_failure,
                  int time_out, int priority, int num_nodes,
                  int reduce, int chunk_size, int replicated,
                  int distributed, int has_target, int num_returns,
                  List values, CharacterVector names, IntegerVector compss_types,
                  IntegerVector compss_directions, IntegerVector compss_streams,
                  CharacterVector compss_prefixes, CharacterVector content_types,
                  CharacterVector weights, IntegerVector keep_renames) {
  
  debug("Process task:");
  debug("- App id: " + std::to_string(app_id));
  debug("- Signature: " + signature);
  debug("- On Failure: " + on_failure);
  debug("- Time Out: " + std::to_string(time_out));
  debug("- Priority: " + std::to_string(priority));
  debug("- Reduce: " + std::to_string(reduce));
  debug("- Chunk size: " + std::to_string(chunk_size));
  debug("- MPI Num nodes: " + std::to_string(num_nodes));
  debug("- Replicated: " + std::to_string(replicated));
  debug("- Distributed: " + std::to_string(distributed));
  debug("- Has target: " + std::to_string(has_target));
  
  int num_pars = values.size();
  debug("+ Number of parameters: " + std::to_string(num_pars));
  int num_fields = 9;
  std::vector<void*> unrolled_parameters(num_fields * num_pars, NULL);
  std::vector<void*> p_value(num_pars, NULL);
  
  // For characters
  // prefix
  std::vector<std::string> prefix_str_vec; // Store the type arguments to ensure their lifetime
  prefix_str_vec.reserve(num_pars);
  std::vector<char*> prefix_charp(num_pars); // Conversion to C-friendly formats
  // name
  std::vector<std::string> name_str_vec; // Store the type arguments to ensure their lifetime
  name_str_vec.reserve(num_pars);
  std::vector<char*> name_charp(num_pars); // Conversion to C-friendly formats
  // content
  std::vector<std::string> content_str_vec; // Store the type arguments to ensure their lifetime
  content_str_vec.reserve(num_pars);
  std::vector<char*> content_charp(num_pars); // Conversion to C-friendly formats
  // weight
  std::vector<std::string> weight_str_vec; // Store the type arguments to ensure their lifetime
  weight_str_vec.reserve(num_pars);
  std::vector<char*> weight_charp(num_pars); // Conversion to C-friendly formats
  
  std::string temp_string; // temporary storage
  for(int i = 0; i < num_pars; i++){
    debug("Processing parameter " + std::to_string(i));
    int size_i = _get_type_size(compss_types[i]);
    
    p_value[i] = new std::uint8_t[size_i];
    switch(compss_types[i]){
    case 0:
      *(int*)(p_value[i]) = int(values[i]);
      break;
    case 4:
      *(int*)(p_value[i]) = int(values[i]);
      break;
    case 7:
      *(double*)(p_value[i]) = double(values[i]);
      break;
    // case 8:
    //   *(char**)(p_value[i]) = (char*) (values[i]);
    }
    
    // Format the values in unrolled_parameters
    // value
    unrolled_parameters[num_fields * i + 0] = (void*) p_value[i];
    // type: int
    unrolled_parameters[num_fields * i + 1] = (void*) &compss_types[i];
    // direction: int
    unrolled_parameters[num_fields * i + 2] = (void*) &compss_directions[i];
    // stream: int
    unrolled_parameters[num_fields * i + 3] = (void*) &compss_streams[i];
    // prefix: string
    temp_string = Rcpp::as<std::string>(compss_prefixes[i]);
    prefix_str_vec.push_back( temp_string );
    prefix_charp[i] = (char*) prefix_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 4] = (void*) &prefix_charp[i];
    // name: string
    temp_string = Rcpp::as<std::string>(names[i]);
    name_str_vec.push_back( temp_string );
    name_charp[i] = (char*) name_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 5] = (void*) &name_charp[i];
    // content: string
    temp_string = Rcpp::as<std::string>(content_types[i]);
    content_str_vec.push_back( temp_string );
    content_charp[i] = (char*) content_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 6] = (void*) &content_charp[i];
    // weight: string
    temp_string = Rcpp::as<std::string>(weights[i]);
    weight_str_vec.push_back( temp_string );
    weight_charp[i] = (char*) weight_str_vec[i].c_str();
    unrolled_parameters[num_fields * i + 7] = (void*) &weight_charp[i];
    // rename: int    
    unrolled_parameters[num_fields * i + 8] = (void*) &keep_renames[i];
    
#if DEBUG_MODE
    fprintf(stderr, "----> Value is at %p\n", (void*) p_value[i]);
    fprintf(stderr, "----> Type: %d\n", compss_types[i]);
    fprintf(stderr, "----> Direction: %d\n", compss_directions[i]);
    fprintf(stderr, "----> Stream: %d\n", compss_streams[i]);
    fprintf(stderr, "----> Prefix: %s\n", prefix_charp[i]);
    fprintf(stderr, "----> Size: %d\n", size_i);
    fprintf(stderr, "----> Name: %s\n", name_charp[i]);
    fprintf(stderr, "----> Content: %s\n", content_charp[i]);
    fprintf(stderr, "----> Weight: %s\n", weight_charp[i]);
    fprintf(stderr, "----> Keep rename: %d\n", keep_renames[i]);
#endif
  }
  
  char* signature_char = &signature[0];
  char* on_failure_char = &on_failure[0];
  
  debug("Calling GS_ExecuteTaskNew...");
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
  
  debug("Returning from process_task...");
}


//' barrier
//' 
//' Halt all the tasks: Notify the runtime that our current application wants to "execute" a barrier. Program will be blocked in GS_BarrierNew until all running tasks have ended. Notifies the 'no more tasks' boolean value.
//' 
//' @export
// [[Rcpp::export]]
void barrier(long int app_id, bool no_more_tasks){
  debug("Barrier\n");
  debug("- App id: " + std::to_string(app_id));
  if(no_more_tasks){
    debug("- No more tasks?: TRUE");
  }else{
    debug("- No more tasks?: FALSE");
  }
  GS_BarrierNew(app_id, no_more_tasks);
  debug("Barrier end\n");
}

