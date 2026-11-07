#include <Rcpp.h>
#include <algorithm>
#include <cmath>
#include <memory>
#include <kernels/ContextManager.hpp>
#ifdef USE_CUDA
#include <cuda_runtime.h>
#include <kernels/cuda/CudaLibraryWrappers.hpp>

namespace {
void check_cuda(cudaError_t status) {
  if (status != cudaSuccess) Rcpp::stop("GPU matrix CUDA error: %s", cudaGetErrorString(status));
}
rcompss::kernels::RunContext *gpu_context() {
  auto *ctx = rcompss::kernels::ContextManager::GetOperationContext();
  if (ctx->GetOperationPlacement() != rcompss::gpu::GPU)
    Rcpp::stop("Active operation context must be GPU");
  return ctx;
}
SEXP matrix_tag() { return Rf_install("RCOMPSs_gpu_matrix"); }
struct DeviceMatrix {
  int rows, cols, device;
  double *data = nullptr;
  cudaEvent_t ready = nullptr;
  DeviceMatrix(int m, int n, int d) : rows(m), cols(n), device(d) {}
  ~DeviceMatrix() {
    int previous = -1;
    if (!data && !ready) return;
    if (cudaGetDevice(&previous) != cudaSuccess) return;
    if (previous != device && cudaSetDevice(device) != cudaSuccess) return;
    if (ready) cudaEventSynchronize(ready);
    if (data) cudaFree(data);
    if (ready) cudaEventDestroy(ready);
    if (previous != device) cudaSetDevice(previous);
  }
  size_t bytes() const { return static_cast<size_t>(rows)*cols*sizeof(double); }
};
DeviceMatrix &get_matrix(SEXP x) {
  if (TYPEOF(x) != EXTPTRSXP || R_ExternalPtrTag(x) != matrix_tag())
    Rcpp::stop("Expected an RCOMPSs GPU matrix handle");
  auto *p = static_cast<DeviceMatrix *>(R_ExternalPtrAddr(x));
  if (!p) Rcpp::stop("GPU matrix handle has been released or is invalid");
  return *p;
}
void check_device(const DeviceMatrix &x) {
  int device = -1; check_cuda(cudaGetDevice(&device));
  if (x.device != device) Rcpp::stop("GPU matrix belongs to a different CUDA device");
}
void wait_for(cudaStream_t stream, DeviceMatrix &x) {
  check_device(x);
  check_cuda(cudaStreamWaitEvent(stream,x.ready,0));
}
}
#endif

//' Upload an ordinary matrix and return a worker-local GPU matrix handle.
// [[Rcpp::export]]
SEXP rcompss_gpu_matrix_upload(Rcpp::NumericMatrix x) {
#ifdef USE_CUDA
  if (x.nrow() <= 0 || x.ncol() <= 0) Rcpp::stop("Matrix must be nonempty");
  auto *ctx = gpu_context(); int device = -1; check_cuda(cudaGetDevice(&device));
  std::unique_ptr<DeviceMatrix> p(new DeviceMatrix(x.nrow(),x.ncol(),device));
  check_cuda(cudaMalloc(reinterpret_cast<void **>(&p->data),p->bytes()));
  check_cuda(cudaEventCreateWithFlags(&p->ready,cudaEventDisableTiming));
  check_cuda(cudaMemcpyAsync(p->data,x.begin(),p->bytes(),cudaMemcpyHostToDevice,ctx->GetStream()));
  check_cuda(cudaEventRecord(p->ready,ctx->GetStream()));
  // R may release x after this call; complete its host-to-device transfer now.
  check_cuda(cudaStreamSynchronize(ctx->GetStream()));
  Rcpp::XPtr<DeviceMatrix> result(p.get(),true,matrix_tag());p.release();
  result.attr("class") = "rcompss_gpu_matrix";
  return result;
#else
  Rcpp::stop("RCOMPSs was built without CUDA support"); return R_NilValue;
#endif
}

//' Update resident C in place using tiled cuBLAS GEMM; no matrix data returns to R.
// [[Rcpp::export]]
SEXP rcompss_gpu_matrix_gemm(SEXP A, SEXP B, SEXP C, double alpha = 1.0,
                            double beta = 0.0, int tile = 512) {
#ifdef USE_CUDA
  if (tile <= 0 || !std::isfinite(alpha) || !std::isfinite(beta))
    Rcpp::stop("tile must be positive and alpha/beta must be finite");
  auto &a=get_matrix(A);auto &b=get_matrix(B);auto &c=get_matrix(C);
  if (&c==&a || &c==&b) Rcpp::stop("Output C must not alias A or B");
  if (a.cols != b.rows || c.rows != a.rows || c.cols != b.cols)
    Rcpp::stop("Nonconformable GPU matrix dimensions");
  auto *ctx=gpu_context();auto stream=ctx->GetStream();
  wait_for(stream,a);wait_for(stream,b);wait_for(stream,c);
  for(int k=0;k<a.cols;k+=std::min(tile,a.cols-k))
    for(int j=0;j<b.cols;j+=std::min(tile,b.cols-j))
      for(int i=0;i<a.rows;i+=std::min(tile,a.rows-i)) {
        rcompss::kernels::GpuBlasDgemm(ctx,false,false,
          std::min(tile,a.rows-i),std::min(tile,b.cols-j),std::min(tile,a.cols-k),
          alpha,k==0?beta:1.0,
          a.data+i+static_cast<size_t>(k)*a.rows,a.rows,
          b.data+k+static_cast<size_t>(j)*b.rows,b.rows,
          c.data+i+static_cast<size_t>(j)*c.rows,c.rows);
      }
  // Track reads as well as writes: another context or finalizer must wait.
  check_cuda(cudaEventRecord(a.ready,stream));
  check_cuda(cudaEventRecord(b.ready,stream));
  check_cuda(cudaEventRecord(c.ready,stream));
  return C;
#else
  Rcpp::stop("RCOMPSs was built without CUDA support"); return R_NilValue;
#endif
}

//' Download a GPU matrix; synchronize before exposing values to R.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_matrix_download(SEXP x) {
#ifdef USE_CUDA
  auto &p=get_matrix(x);auto *ctx=gpu_context();auto stream=ctx->GetStream();
  wait_for(stream,p);
  Rcpp::NumericMatrix result(p.rows,p.cols);
  check_cuda(cudaMemcpyAsync(result.begin(),p.data,p.bytes(),cudaMemcpyDeviceToHost,stream));
  check_cuda(cudaEventRecord(p.ready,stream));
  check_cuda(cudaStreamSynchronize(stream));
  return result;
#else
  Rcpp::stop("RCOMPSs was built without CUDA support"); return Rcpp::NumericMatrix();
#endif
}

//' Release a GPU matrix explicitly. Calling twice on the same handle is safe.
// [[Rcpp::export]]
void rcompss_gpu_matrix_release(SEXP x) {
  if (x==R_NilValue) return;
#ifdef USE_CUDA
  if (TYPEOF(x) != EXTPTRSXP || R_ExternalPtrTag(x) != matrix_tag())
    Rcpp::stop("Expected an RCOMPSs GPU matrix handle");
  delete static_cast<DeviceMatrix *>(R_ExternalPtrAddr(x));
  R_ClearExternalPtr(x);
#else
  Rcpp::stop("RCOMPSs was built without CUDA support");
#endif
}
