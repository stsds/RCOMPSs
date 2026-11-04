#include <Rcpp.h>
#include <cuda_runtime.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <sstream>
#include <thread>
#include <vector>
#include <sched.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>
#include <string>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerVector campaign_affinity() {
  cpu_set_t mask;CPU_ZERO(&mask);
  if(sched_getaffinity(0,sizeof(mask),&mask)!=0)stop("Cannot read CPU affinity");
  std::vector<int> ids;
  for(int i=0;i<CPU_SETSIZE;++i)if(CPU_ISSET(i,&mask))ids.push_back(i);
  return wrap(ids);
}

// Stateless input generation: a matrix entry is identical in every task.
static double entry(int n, int row, int col, int seed) {
  uint64_t z = static_cast<uint64_t>(row) + static_cast<uint64_t>(col)*n;
  z += static_cast<uint64_t>(seed)*0x9e3779b97f4a7c15ULL;
  z = (z^(z>>30))*0xbf58476d1ce4e5b9ULL;
  z = (z^(z>>27))*0x94d049bb133111ebULL;
  z ^= z>>31;
  return static_cast<double>(z>>11)*0x1.0p-53 - 0.5;
}

// Prepare three complete host matrices before the operation timer.
// [[Rcpp::export]]
void campaign_prepare(int n, std::string path) {
  size_t bytes=static_cast<size_t>(n)*n*sizeof(double);
  for(int seed=1;seed<=3;++seed) {
    std::string file=path+"/input-"+std::to_string(seed)+".bin";
    int fd=open(file.c_str(),O_CREAT|O_TRUNC|O_RDWR,0600);
    if(fd<0 || ftruncate(fd,bytes)!=0) stop("Cannot prepare host input");
    double* data=(double*)mmap(nullptr,bytes,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    if(data==MAP_FAILED)stop("Cannot map host input");
    for(int j=0;j<n;++j)for(int i=0;i<n;++i)data[i+static_cast<size_t>(j)*n]=entry(n,i,j,seed);
    munmap(data,bytes);close(fd);
  }
}
static const double* prepared_input(int n,int seed,const char* path) {
  static std::string previous;static const double* data[3]={nullptr,nullptr,nullptr};
  static size_t bytes=0;
  if(previous!=path) {
    for(auto &x:data){if(x)munmap((void*)x,bytes);x=nullptr;}
    previous=path;bytes=static_cast<size_t>(n)*n*sizeof(double);
  }
  if(!data[seed-1]) {
    std::string file=previous+"/input-"+std::to_string(seed)+".bin";
    int fd=open(file.c_str(),O_RDONLY);struct stat info;
    if(fd<0 || fstat(fd,&info)!=0 || static_cast<size_t>(info.st_size)!=bytes)stop("Missing prepared host input");
    void* mapped=mmap(nullptr,bytes,PROT_READ,MAP_SHARED,fd,0);close(fd);
    if(mapped==MAP_FAILED)stop("Cannot map prepared host input");
    data[seed-1]=(const double*)mapped;
  }
  return data[seed-1];
}

// [[Rcpp::export]]
NumericMatrix campaign_input(int n, int row, int rows, int col, int cols, int seed) {
  if(n<=0 || row<0 || col<0 || rows<=0 || cols<=0 || row+rows>n || col+cols>n)
    stop("Invalid input block");
  NumericMatrix result(rows,cols);
  const char* path=std::getenv("CAMPAIGN_PREPARED");
  if(path && *path) {
    if(seed<1 || seed>3)stop("Invalid prepared seed");
    const double* data=prepared_input(n,seed,path);
    for(int j=0;j<cols;++j)std::memcpy(result.begin()+static_cast<size_t>(j)*rows,data+row+static_cast<size_t>(col+j)*n,rows*sizeof(double));
  } else for(int j=0;j<cols;++j) for(int i=0;i<rows;++i)
    result(i,j)=entry(n,row+i,col+j,seed);
  return result;
}

// Independent sampled dot products, accumulated in long double.
// [[Rcpp::export]]
double campaign_check(NumericMatrix result, int n, int row, int col, int samples=8) {
  double error=0;
  for(int s=0;s<samples;++s) {
    int i=(static_cast<uint64_t>(s)*104729+17)%result.nrow();
    int j=(static_cast<uint64_t>(s)*130363+23)%result.ncol();
    long double dot=0;
    for(int k=0;k<n;++k)
      dot+=static_cast<long double>(entry(n,row+i,k,1))*entry(n,k,col+j,2);
    long double expected=.51L*dot-.42L*entry(n,row+i,col+j,3);
    error=std::max(error,static_cast<double>(std::abs(result(i,j)-expected)/(1+std::abs(expected))));
  }
  return error;
}

static void check(cudaError_t status) {
  if(status!=cudaSuccess) stop("CUDA: %s",cudaGetErrorString(status));
}

// Benchmark-local binding adapter: restore the allocation mask BEFORE the first
// CUDA call, then explicitly select the ordinal assigned by COMPSs. Changing
// CUDA_VISIBLE_DEVICES alone cannot rebind an initialized persistent process.
// [[Rcpp::export]]
List campaign_device(int assigned, std::string mask) {
  setenv("CUDA_VISIBLE_DEVICES",mask.c_str(),1);
  int count=0;check(cudaGetDeviceCount(&count));
  if(assigned<0 || assigned>=count) stop("Assigned GPU is outside allocation");
  check(cudaSetDevice(assigned));
  cudaDeviceProp prop;check(cudaGetDeviceProperties(&prop,assigned));
  char bus[32];check(cudaDeviceGetPCIBusId(bus,sizeof(bus),assigned));
  size_t free=0,total=0;check(cudaMemGetInfo(&free,&total));
  return List::create(_["ordinal"]=assigned,_["bus"]=bus,_["name"]=prop.name,
                      _["free_bytes"]=static_cast<double>(free),_["total_bytes"]=static_cast<double>(total));
}

// Tests actual cudaMalloc feasibility, not GEMM correctness. Caller reserves
// additional headroom for numerical-library handles and workspace.
// [[Rcpp::export]]
List campaign_allocate(double nvalue, int tile, bool resident) {
  size_t n=static_cast<size_t>(nvalue),free=0,total=0;
  check(cudaMemGetInfo(&free,&total));
  std::vector<size_t> sizes=resident?std::vector<size_t>{8*n*n,8*n*n,8*n*n}:
    std::vector<size_t>{8*n*n,8*n*tile,8*n*tile};
  std::vector<void*> buffers; bool success=true;
  for(auto bytes:sizes) {
    void* p=nullptr;
    if(cudaMalloc(&p,bytes)!=cudaSuccess) {cudaGetLastError();success=false;break;}
    buffers.push_back(p);
  }
  size_t after=0;check(cudaMemGetInfo(&after,&total));
  std::this_thread::sleep_for(std::chrono::milliseconds(300));
  for(void* p:buffers) check(cudaFree(p));
  return List::create(_["success"]=success,_["allocated_bytes"]=static_cast<double>(free-after));
}
