#include <Rcpp.h>
#include <R_ext/BLAS.h>
#include <algorithm>
#include <cmath>
#include <kernels/ContextManager.hpp>
#ifdef USE_CUDA
#include <cuda_runtime.h>
#include <kernels/cuda/CudaLibraryWrappers.hpp>
#endif

namespace {
#ifdef USE_CUDA
void check_cuda(cudaError_t status) {
  if (status != cudaSuccess) Rcpp::stop("Tiled GEMM CUDA error: %s", cudaGetErrorString(status));
}
class DeviceBuffer {
 public:
  explicit DeviceBuffer(size_t bytes) { check_cuda(cudaMalloc(reinterpret_cast<void **>(&data), bytes)); }
  ~DeviceBuffer() { if (data) cudaFree(data); }
  DeviceBuffer(const DeviceBuffer &) = delete;
  DeviceBuffer &operator=(const DeviceBuffer &) = delete;
  double *data = nullptr;
};
#endif
}

//' Reduce pairs of matrix tiles into one output tile.
//' Keeps the output on the GPU across k updates and reuses input buffers.
//' CPU mode updates C directly with BLAS, without intermediate R products.
//' Inputs and C0 are not modified; partial and rectangular tiles are supported.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gemm_tile_reduce(Rcpp::List A, Rcpp::List B,
    Rcpp::NumericMatrix C0, double alpha = 1.0, double beta = 0.0, bool gpu = false) {
  if (A.size() == 0 || A.size() != B.size()) Rcpp::stop("A and B must contain the same positive number of tiles");
  if (!std::isfinite(alpha) || !std::isfinite(beta)) Rcpp::stop("alpha and beta must be finite");
  const int m = C0.nrow(), n = C0.ncol();
  if (m <= 0 || n <= 0) Rcpp::stop("C0 must be nonempty");
  size_t maxA = 0, maxB = 0;
  int block = 1;
  // Validate every pair before allocating buffers or launching work.
  for (R_xlen_t k = 0; k < A.size(); ++k) {
    SEXP a = A[k], b = B[k];
    if (TYPEOF(a) != REALSXP || !Rf_isMatrix(a) || TYPEOF(b) != REALSXP || !Rf_isMatrix(b))
      Rcpp::stop("Input tiles must be double matrices");
    Rcpp::NumericMatrix ak(a), bk(b);
    if (ak.nrow() != m || bk.ncol() != n || ak.ncol() <= 0 || ak.ncol() != bk.nrow())
      Rcpp::stop("Nonconformable tile pair at index %d", static_cast<int>(k + 1));
    block = std::max(block, ak.ncol());
    maxA = std::max(maxA, static_cast<size_t>(ak.size()));
    maxB = std::max(maxB, static_cast<size_t>(bk.size()));
  }
  Rcpp::NumericMatrix result = Rcpp::clone(C0);
  if (!gpu) {
    const char trans = 'N';
    for (R_xlen_t k = 0; k < A.size(); ++k) {
      Rcpp::NumericMatrix ak(static_cast<SEXP>(A[k])), bk(static_cast<SEXP>(B[k]));
      const int inner = ak.ncol();
      const double scale = k == 0 ? beta : 1.0;
      F77_CALL(dgemm)(&trans, &trans, &m, &n, &inner, &alpha,
          ak.begin(), &m, bk.begin(), &inner, &scale, result.begin(), &m FCONE FCONE);
    }
    return result;
  }
#ifdef USE_CUDA
  auto *ctx = rcompss::kernels::ContextManager::GetOperationContext();
  if (ctx->GetOperationPlacement() != rcompss::gpu::GPU)
    Rcpp::stop("Active operation context must be GPU");
  const size_t bytesC = static_cast<size_t>(m) * n * sizeof(double);
  DeviceBuffer da(maxA * sizeof(double)), db(maxB * sizeof(double)), dc(bytesC);
  const auto stream = ctx->GetStream();
  if (beta != 0.0)
    check_cuda(cudaMemcpyAsync(dc.data, C0.begin(), bytesC, cudaMemcpyHostToDevice, stream));
  for (R_xlen_t k = 0; k < A.size(); ++k) {
    Rcpp::NumericMatrix ak(static_cast<SEXP>(A[k])), bk(static_cast<SEXP>(B[k]));
    check_cuda(cudaMemcpyAsync(da.data, ak.begin(), static_cast<size_t>(ak.size()) * sizeof(double), cudaMemcpyHostToDevice, stream));
    check_cuda(cudaMemcpyAsync(db.data, bk.begin(), static_cast<size_t>(bk.size()) * sizeof(double), cudaMemcpyHostToDevice, stream));
    // Keep genuine output-tile kernels even when several tiles are batched
    // into a single runtime task. Panels and C remain resident for the batch.
    for (int j = 0; j < n; j += block) for (int i = 0; i < m; i += block) {
      rcompss::kernels::GpuBlasDgemm(ctx, false, false,
          std::min(block, m-i), std::min(block, n-j), ak.ncol(), alpha,
          k == 0 ? beta : 1.0, da.data+i, m,
          db.data+static_cast<size_t>(j)*ak.ncol(), ak.ncol(),
          dc.data+i+static_cast<size_t>(j)*m, m);
    }
  }
  check_cuda(cudaMemcpyAsync(result.begin(), dc.data, bytesC, cudaMemcpyDeviceToHost, stream));
  // Results and temporary device buffers must remain valid even in async mode.
  check_cuda(cudaStreamSynchronize(stream));
  return result;
#else
  Rcpp::stop("RCOMPSs was built without CUDA support");
  return result;
#endif
}
