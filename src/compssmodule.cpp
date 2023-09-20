#include <Rcpp.h>
#include <iostream>
#include <GS_compss.h>
using namespace Rcpp;

//' @export
// [[Rcpp::export]]
List rcpp_hello_world() {

    CharacterVector x = CharacterVector::create( "foo", "bar" )  ;
    NumericVector y   = NumericVector::create( 0.0, 1.0 ) ;
    List z            = List::create( x, y ) ;

    return z ;
}

//' Start a COMPSs-Runtime instance
//' @export
// [[Rcpp::export]]
void start_runtime(){
  Rcout << "Start runtime\n";
  GS_On();
}


//' Start a COMPSs-Runtime instance
//' @export
// [[Rcpp::export]]
void stop_runtime(int code){
  Rcout << "Stop runtime with code: " << code << "\n";
  GS_Off(code);
}


//' Register a core element
//' @export
// [[Rcpp::export]]
void register_core_element(std::string CESignature, std::string ImplSignature, 
                           std::string ImplConstraints, std::string ImplType,
                           std::string ImplLocal, std::string ImplIO, 
                           CharacterVector prolog, CharacterVector epilog,
                           CharacterVector container, CharacterVector typeArgs) {
  Rcpp::Rcout << "Register core element" << std::endl;
  
  char* CESignatureCStr = &CESignature[0];
  char* ImplSignatureCStr = &ImplSignature[0];
  char* ImplConstraintsCStr = &ImplConstraints[0];
  char* ImplTypeCStr = &ImplType[0];
  char* ImplLocalCStr = &ImplLocal[0];
  char* ImplIOCStr = &ImplIO[0];
  
  Rcpp::Rcout << "- Core Element Signature: " << CESignature << std::endl;
  Rcpp::Rcout << "- Implementation Signature: " << ImplSignature << std::endl;
  Rcpp::Rcout << "- Implementation Constraints: " << ImplConstraints << std::endl;
  Rcpp::Rcout << "- Implementation Type: " << ImplType << std::endl;
  Rcpp::Rcout << "- Implementation Local: " << ImplLocal << std::endl;
  Rcpp::Rcout << "- Implementation IO: " << ImplIO << std::endl;
  
  char** pro;
  char** epi;
  char** cont;
  char** ImplTypeArgs;
  
  int num_params = typeArgs.size();
  Rcpp::Rcout << "- Implementation Type num args: " << num_params << std::endl;
  
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
  
  Rcpp::Rcout << "- Prolog: " << pro[0] << "; " << pro[1] << "; " << pro[2] << std::endl;
  
  std::string epilog0 = Rcpp::as<std::string>(epilog[0]);
  std::string epilog1 = Rcpp::as<std::string>(epilog[1]);
  std::string epilog2 = Rcpp::as<std::string>(epilog[2]);
  epi[0] = &epilog0[0];
  epi[1] = &epilog1[0];
  epi[2] = &epilog2[0];
  
  Rcpp::Rcout << "- Epilog: " << epi[0] << "; " << epi[1] << "; " << epi[2] << std::endl;
  
  std::string container0 = Rcpp::as<std::string>(container[0]);
  std::string container1 = Rcpp::as<std::string>(container[1]);
  std::string container2 = Rcpp::as<std::string>(container[2]);
  cont[0] = &container0[0];
  cont[1] = &container1[0];
  cont[2] = &container2[0];
  
  Rcpp::Rcout << "- Container: " << cont[0] << "; " << cont[1] << "; " << cont[2] << std::endl;
  
  std::vector<std::string> stypeArgStorage; // Store the type arguments to ensure their lifetime
  stypeArgStorage.reserve(num_params);
  std::string typeArg;
  for (int i = 0; i < num_params; ++i) {
    typeArg = Rcpp::as<std::string>(typeArgs[i]);
    stypeArgStorage.push_back(typeArg);
    ImplTypeArgs[i] = &(stypeArgStorage[i][0]);
    Rcpp::Rcout << "- Implementation Type Args: " << ImplTypeArgs[i] << std::endl;
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
  
  Rcpp::Rcout << "Core element registered" << std::endl;
}


