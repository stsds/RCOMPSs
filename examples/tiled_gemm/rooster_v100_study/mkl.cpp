#include <mkl.h>
#include <vector>
#include <cstdint>
#include <cmath>
#include <chrono>
#include <cstdio>
#include <cstdlib>
static double entry(int n, int row, int col, int seed) {
  uint64_t z = static_cast<uint64_t>(row) + static_cast<uint64_t>(col)*n;
  z += static_cast<uint64_t>(seed)*0x9e3779b97f4a7c15ULL;
  z = (z^(z>>30))*0xbf58476d1ce4e5b9ULL;
  z = (z^(z>>27))*0x94d049bb133111ebULL;
  z ^= z>>31;
  return static_cast<double>(z>>11)*0x1.0p-53 - 0.5;
}


int main(int argc,char**argv){
 int n=atoi(argv[1]); size_t count=(size_t)n*n;
 mkl_set_dynamic(0);mkl_set_num_threads(40);
 std::vector<double>A(count),B(count),C(count);
 for(int j=0;j<n;++j)for(int i=0;i<n;++i){size_t q=i+(size_t)j*n;A[q]=entry(n,i,j,1);B[q]=entry(n,i,j,2);C[q]=entry(n,i,j,3);}
 auto begin=std::chrono::steady_clock::now();
 cblas_dgemm(CblasColMajor,CblasNoTrans,CblasNoTrans,n,n,n,.51,A.data(),n,B.data(),n,-.42,C.data(),n);
 double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-begin).count(),error=0;
 for(int s=0;s<8;++s){int i=((uint64_t)s*104729+17)%n,j=((uint64_t)s*130363+23)%n;long double dot=0;for(int k=0;k<n;++k)dot+=(long double)entry(n,i,k,1)*entry(n,k,j,2);long double expected=.51L*dot-.42L*entry(n,i,j,3);error=std::max(error,(double)(std::abs(C[i+(size_t)j*n]-expected)/(1+std::abs(expected))));}
 printf("n,operation_seconds,error,threads\n%d,%.9f,%.12g,40\n",n,seconds,error);
 return error<1e-10?0:2;
}
