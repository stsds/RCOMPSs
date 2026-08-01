/**
 * R-facing cuBLAS / cuSOLVER wrappers. GPU operation context must be set in R
 * before calling these; this file does not create contexts or change run mode.
 */

#include <Rcpp.h>
#include <algorithm>
#include <cctype>
#include <cstring>
#include <string>
#include <vector>
#include <kernels/ContextManager.hpp>
#include <kernels/MemoryHandler.hpp>
#ifdef USE_CUDA
#include <cuda_runtime.h>
#include <kernels/cuda/CudaLibraryWrappers.hpp>
#endif

namespace {

#ifdef USE_CUDA

class ScopedGpuArray {
 public:
  ScopedGpuArray() = default;
  ScopedGpuArray(size_t nbytes, rcompss::kernels::RunContext *ctx) : ctx_(ctx), nbytes_(nbytes) {
    if (nbytes > 0) {
      ptr_ = reinterpret_cast<char *>(
          rcompss::memory::AllocateArray(nbytes, rcompss::gpu::GPU, ctx_));
    }
  }
  ~ScopedGpuArray() { reset(); }
  ScopedGpuArray(const ScopedGpuArray &) = delete;
  ScopedGpuArray &operator=(const ScopedGpuArray &) = delete;
  ScopedGpuArray(ScopedGpuArray &&o) noexcept : ptr_(o.ptr_), ctx_(o.ctx_), nbytes_(o.nbytes_) {
    o.ptr_ = nullptr;
    o.ctx_ = nullptr;
    o.nbytes_ = 0;
  }
  ScopedGpuArray &operator=(ScopedGpuArray &&o) noexcept {
    if (this != &o) {
      reset();
      ptr_ = o.ptr_;
      ctx_ = o.ctx_;
      nbytes_ = o.nbytes_;
      o.ptr_ = nullptr;
      o.ctx_ = nullptr;
      o.nbytes_ = 0;
    }
    return *this;
  }
  void reset() {
    if (ptr_ && ctx_) {
      rcompss::memory::DestroyArray(ptr_, rcompss::gpu::GPU, ctx_);
      ptr_ = nullptr;
    }
  }
  char *ptr() const { return ptr_; }
  double *as_double() const { return reinterpret_cast<double *>(ptr_); }
  bool ok() const { return nbytes_ == 0 || ptr_ != nullptr; }

 private:
  char *ptr_ = nullptr;
  rcompss::kernels::RunContext *ctx_ = nullptr;
  size_t nbytes_ = 0;
};

rcompss::kernels::RunContext *rcompss_gpu_linalg_require_context() {
  auto *ctx = rcompss::kernels::ContextManager::GetOperationContext();
  if (ctx == nullptr) {
    Rcpp::stop(
        "No active operation context. Create a GPU run context and call "
        "rcompss_set_operation_context() (or your R wrapper) first.");
  }
  if (ctx->GetOperationPlacement() == rcompss::gpu::CPU) {
    Rcpp::stop(
        "Active operation context is CPU. Set placement to GPU before calling GPU linear algebra "
        "routines.");
  }
  return ctx;
}

bool rcompss_gpu_linalg_parse_side_left(const std::string &side) {
  if (side.empty()) {
    Rcpp::stop("side must be 'L' or 'R'.");
  }
  char c = static_cast<char>(std::toupper(static_cast<unsigned char>(side[0])));
  if (c == 'L') {
    return true;
  }
  if (c == 'R') {
    return false;
  }
  Rcpp::stop("side must be 'L' or 'R'.");
  return true;
}

bool rcompss_gpu_linalg_parse_upper(const std::string &uplo) {
  if (uplo.empty()) {
    Rcpp::stop("uplo must be 'U' or 'L'.");
  }
  char c = static_cast<char>(std::toupper(static_cast<unsigned char>(uplo[0])));
  if (c == 'U') {
    return true;
  }
  if (c == 'L') {
    return false;
  }
  Rcpp::stop("uplo must be 'U' or 'L'.");
  return true;
}

bool rcompss_gpu_linalg_parse_trans(const std::string &trans) {
  if (trans.empty()) {
    Rcpp::stop("trans must be 'N' or 'T'.");
  }
  char c = static_cast<char>(std::toupper(static_cast<unsigned char>(trans[0])));
  if (c == 'N') {
    return false;
  }
  if (c == 'T' || c == 'C') {
    return true;
  }
  Rcpp::stop("trans must be 'N' or 'T'.");
  return false;
}

bool rcompss_gpu_linalg_parse_unit_diag(const std::string &diag) {
  if (diag.empty()) {
    Rcpp::stop("diag must be 'N' (non-unit) or 'U' (unit).");
  }
  char c = static_cast<char>(std::toupper(static_cast<unsigned char>(diag[0])));
  if (c == 'U') {
    return true;
  }
  if (c == 'N') {
    return false;
  }
  Rcpp::stop("diag must be 'N' (non-unit) or 'U' (unit).");
  return false;
}

#endif  // USE_CUDA

}  // namespace

//' Matrix multiply on GPU (cuBLAS DGEMM). Column-major layout matches R matrices.
//' C = alpha * op(A) %*% op(B) + beta * C0. With default trans flags, op is identity:
//' A must be m×k, B must be k×n; result is m×n. C0 is ignored when beta is 0 (default).
//' Requires an active GPU operation context (set from R before calling).
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dgemm(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B, bool transA = false,
                                      bool transB = false, double alpha = 1.0, double beta = 0.0) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int m = 0, n = 0, k = 0;
    int lda = 0, ldb = 0;
    if (!transA && !transB) {
      m = A.nrow();
      k = A.ncol();
      if (B.nrow() != k) {
        Rcpp::stop("Incompatible dimensions: A is %d×%d but B is %d×%d (need B nrow = %d).", m, k,
                   B.nrow(), B.ncol(), k);
      }
      n = B.ncol();
      lda = m;
      ldb = k;
    } else if (transA && !transB) {
      k = A.nrow();
      m = A.ncol();
      if (B.nrow() != k) {
        Rcpp::stop("Incompatible dimensions for A' %%*%% B.");
      }
      n = B.ncol();
      lda = k;
      ldb = k;
    } else if (!transA && transB) {
      m = A.nrow();
      k = A.ncol();
      n = B.nrow();
      if (B.ncol() != k) {
        Rcpp::stop("Incompatible dimensions for A %%*%% B'.");
      }
      lda = m;
      ldb = n;
    } else {
      k = A.nrow();
      m = A.ncol();
      n = B.nrow();
      if (B.ncol() != k) {
        Rcpp::stop("Incompatible dimensions for A' %%*%% B'.");
      }
      lda = k;
      ldb = n;
    }

    const size_t bytesA = static_cast<size_t>(A.nrow()) * static_cast<size_t>(A.ncol()) * sizeof(double);
    const size_t bytesB = static_cast<size_t>(B.nrow()) * static_cast<size_t>(B.ncol()) * sizeof(double);
    const size_t bytesC = static_cast<size_t>(m) * static_cast<size_t>(n) * sizeof(double);

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray dB(bytesB, ctx);
    ScopedGpuArray dC(bytesC, ctx);
    if (!dA.ok() || !dB.ok() || !dC.ok()) {
      Rcpp::stop("GPU allocation failed for dgemm.");
    }

    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(dB.ptr(), reinterpret_cast<const char *>(REAL(B)), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    if (beta != 0.0) {
      Rcpp::stop("Non-zero beta for dgemm is not supported in this binding (pass beta=0).");
    }
    rcompss::kernels::GpuBlasDgemm(ctx, transA, transB, m, n, k, alpha, beta, dA.as_double(), lda,
                                   dB.as_double(), ldb, dC.as_double(), m);

    Rcpp::NumericMatrix C(m, n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(C)), dC.ptr(), bytesC, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return C;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dgemm failed: %s", e.what());
  }
#else
  (void)A;
  (void)B;
  (void)transA;
  (void)transB;
  (void)alpha;
  (void)beta;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}

//' y <- alpha*x + y on GPU (cuBLAS DAXPY). Returns a new numeric vector (does not modify x).
//' Requires an active GPU operation context (set from R before calling).
// [[Rcpp::export]]
Rcpp::NumericVector rcompss_gpu_daxpy(Rcpp::NumericVector x, Rcpp::NumericVector y, double alpha = 1.0) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = static_cast<int>(x.size());
    if (static_cast<int>(y.size()) != n) {
      Rcpp::stop("x and y must have the same length.");
    }
    const size_t bytes = static_cast<size_t>(n) * sizeof(double);
    ScopedGpuArray d_x(bytes, ctx);
    ScopedGpuArray d_y(bytes, ctx);
    if (!d_x.ok() || !d_y.ok()) {
      Rcpp::stop("GPU allocation failed for daxpy.");
    }
    rcompss::memory::MemCpy(d_x.ptr(), reinterpret_cast<const char *>(REAL(x)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(d_y.ptr(), reinterpret_cast<const char *>(REAL(y)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::kernels::GpuBlasDaxpy(ctx, n, alpha, d_x.as_double(), d_y.as_double());
    Rcpp::NumericVector out(n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(out)), d_y.ptr(), bytes, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return out;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_daxpy failed: %s", e.what());
  }
#else
  (void)x;
  (void)y;
  (void)alpha;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericVector();
#endif
}

//' Cholesky factorization on GPU (cuSOLVER DPOTRF). A must be square symmetric positive definite.
//' If upper=TRUE (default), returns upper-triangular R with A = R'R in the R sense (stored upper).
//' Requires an active GPU operation context (set from R before calling).
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dpotrf(Rcpp::NumericMatrix A, bool upper = true) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = A.nrow();
    if (A.ncol() != n) {
      Rcpp::stop("A must be square for Cholesky (got %d×%d).", A.nrow(), A.ncol());
    }
    const size_t bytes = static_cast<size_t>(n) * static_cast<size_t>(n) * sizeof(double);
    ScopedGpuArray dA(bytes, ctx);
    if (!dA.ok()) {
      Rcpp::stop("GPU allocation failed for dpotrf.");
    }
    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    int info = rcompss::kernels::GpuSolverDpotrf(ctx, upper, n, dA.as_double(), n);
    if (info != 0) {
      Rcpp::stop("DPOTRF failed: matrix is not positive definite (info=%d).", info);
    }
    Rcpp::NumericMatrix L(n, n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(L)), dA.ptr(), bytes, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return L;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dpotrf failed: %s", e.what());
  }
#else
  (void)A;
  (void)upper;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}

//' Matrix–vector multiply on GPU (cuBLAS DGEMV). Column-major \code{A} (m×n).
//' If \code{trans=FALSE}: y = alpha*A*x + beta*y0 (x length n, result length m).
//' If \code{trans=TRUE}: y = alpha*t(A)*x + beta*y0 (x length m, result length n).
//' If \code{beta != 0}, pass \code{y0} with the same length as the result.
// [[Rcpp::export]]
Rcpp::NumericVector rcompss_gpu_dgemv(Rcpp::NumericMatrix A, Rcpp::NumericVector x, bool trans = false,
                                        double alpha = 1.0, double beta = 0.0,
                                        Rcpp::Nullable<Rcpp::NumericVector> y0 = R_NilValue) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    const int m = A.nrow();
    const int n = A.ncol();
    const int out_len = trans ? n : m;
    const int x_expect = trans ? m : n;
    if (static_cast<int>(x.size()) != x_expect) {
      Rcpp::stop("DGEMV: x has wrong length (expected %d, got %d).", x_expect, static_cast<int>(x.size()));
    }
    const size_t bytesA = static_cast<size_t>(m) * static_cast<size_t>(n) * sizeof(double);
    const size_t bytes_x = static_cast<size_t>(x_expect) * sizeof(double);
    const size_t bytes_y = static_cast<size_t>(out_len) * sizeof(double);

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray d_x(bytes_x, ctx);
    ScopedGpuArray d_y(bytes_y, ctx);
    if (!dA.ok() || !d_x.ok() || !d_y.ok()) {
      Rcpp::stop("GPU allocation failed for dgemv.");
    }
    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(d_x.ptr(), reinterpret_cast<const char *>(REAL(x)), bytes_x, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    if (beta != 0.0) {
      if (!y0.isNotNull()) {
        Rcpp::stop("DGEMV: beta is non-zero; provide y0 with length %d.", out_len);
      }
      Rcpp::NumericVector y0v(y0);
      if (static_cast<int>(y0v.size()) != out_len) {
        Rcpp::stop("DGEMV: y0 must have length %d (got %d).", out_len, static_cast<int>(y0v.size()));
      }
      rcompss::memory::MemCpy(d_y.ptr(), reinterpret_cast<const char *>(REAL(y0v)), bytes_y, ctx,
                              rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    } else {
      cudaError_t memset_st = cudaMemset(d_y.ptr(), 0, bytes_y);
      if (memset_st != cudaSuccess) {
        Rcpp::stop("cudaMemset failed: %s", cudaGetErrorString(memset_st));
      }
    }
    rcompss::kernels::GpuBlasDgemv(ctx, trans, m, n, alpha, beta, dA.as_double(), m, d_x.as_double(),
                                   d_y.as_double());
    Rcpp::NumericVector out(out_len);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(out)), d_y.ptr(), bytes_y, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return out;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dgemv failed: %s", e.what());
  }
#else
  (void)A;
  (void)x;
  (void)trans;
  (void)alpha;
  (void)beta;
  (void)y0;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericVector();
#endif
}

//' Dot product on GPU (cuBLAS DDOT).
// [[Rcpp::export]]
double rcompss_gpu_ddot(Rcpp::NumericVector x, Rcpp::NumericVector y) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = static_cast<int>(x.size());
    if (static_cast<int>(y.size()) != n) {
      Rcpp::stop("x and y must have the same length.");
    }
    const size_t bytes = static_cast<size_t>(n) * sizeof(double);
    ScopedGpuArray d_x(bytes, ctx);
    ScopedGpuArray d_y(bytes, ctx);
    if (!d_x.ok() || !d_y.ok()) {
      Rcpp::stop("GPU allocation failed for ddot.");
    }
    rcompss::memory::MemCpy(d_x.ptr(), reinterpret_cast<const char *>(REAL(x)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(d_y.ptr(), reinterpret_cast<const char *>(REAL(y)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    double result = 0.0;
    rcompss::kernels::GpuBlasDdot(ctx, n, d_x.as_double(), d_y.as_double(), &result);
    return result;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_ddot failed: %s", e.what());
  }
#else
  (void)x;
  (void)y;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return 0.0;
#endif
}

//' Euclidean norm on GPU (cuBLAS DNRM2).
// [[Rcpp::export]]
double rcompss_gpu_dnrm2(Rcpp::NumericVector x) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = static_cast<int>(x.size());
    const size_t bytes = static_cast<size_t>(n) * sizeof(double);
    ScopedGpuArray d_x(bytes, ctx);
    if (!d_x.ok()) {
      Rcpp::stop("GPU allocation failed for dnrm2.");
    }
    rcompss::memory::MemCpy(d_x.ptr(), reinterpret_cast<const char *>(REAL(x)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    double result = 0.0;
    rcompss::kernels::GpuBlasDnrm2(ctx, n, d_x.as_double(), &result);
    return result;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dnrm2 failed: %s", e.what());
  }
#else
  (void)x;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return 0.0;
#endif
}

//' Scale a vector on GPU (cuBLAS DSCAL): returns alpha * x (new vector).
// [[Rcpp::export]]
Rcpp::NumericVector rcompss_gpu_dscal(Rcpp::NumericVector x, double alpha = 1.0) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = static_cast<int>(x.size());
    const size_t bytes = static_cast<size_t>(n) * sizeof(double);
    ScopedGpuArray d_x(bytes, ctx);
    if (!d_x.ok()) {
      Rcpp::stop("GPU allocation failed for dscal.");
    }
    rcompss::memory::MemCpy(d_x.ptr(), reinterpret_cast<const char *>(REAL(x)), bytes, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::kernels::GpuBlasDscal(ctx, n, alpha, d_x.as_double());
    Rcpp::NumericVector out(n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(out)), d_x.ptr(), bytes, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return out;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dscal failed: %s", e.what());
  }
#else
  (void)x;
  (void)alpha;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericVector();
#endif
}

//' Triangular matrix-matrix multiply on GPU (cuBLAS DTRMM).
//' C = alpha * op(A) %*% B (side="L") or C = alpha * B %*% op(A) (side="R").
//' A is triangular; \code{uplo} selects upper/lower, \code{diag} selects unit diagonal.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dtrmm(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B,
                                      std::string side = "L", std::string uplo = "U",
                                      std::string trans = "N", std::string diag = "N",
                                      double alpha = 1.0) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    const bool side_left = rcompss_gpu_linalg_parse_side_left(side);
    const bool upper = rcompss_gpu_linalg_parse_upper(uplo);
    const bool transA = rcompss_gpu_linalg_parse_trans(trans);
    const bool unit_diag = rcompss_gpu_linalg_parse_unit_diag(diag);

    const int m = B.nrow();
    const int n = B.ncol();
    const int a_size = side_left ? m : n;
    if (A.nrow() != a_size || A.ncol() != a_size) {
      Rcpp::stop("DTRMM: A must be %d×%d (got %d×%d).", a_size, a_size, A.nrow(), A.ncol());
    }

    const size_t bytesA = static_cast<size_t>(A.nrow()) * static_cast<size_t>(A.ncol()) * sizeof(double);
    const size_t bytesB = static_cast<size_t>(m) * static_cast<size_t>(n) * sizeof(double);
    const size_t bytesC = bytesB;

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray dB(bytesB, ctx);
    ScopedGpuArray dC(bytesC, ctx);
    if (!dA.ok() || !dB.ok() || !dC.ok()) {
      Rcpp::stop("GPU allocation failed for dtrmm.");
    }

    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(dB.ptr(), reinterpret_cast<const char *>(REAL(B)), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);

    rcompss::kernels::GpuBlasDtrmm(ctx, side_left, upper, transA, unit_diag, m, n, alpha,
                                   dA.as_double(), A.nrow(), dB.as_double(), m, dC.as_double(), m);

    Rcpp::NumericMatrix C(m, n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(C)), dC.ptr(), bytesC, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return C;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dtrmm failed: %s", e.what());
  }
#else
  (void)A;
  (void)B;
  (void)side;
  (void)uplo;
  (void)trans;
  (void)diag;
  (void)alpha;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}

//' Triangular solve on GPU (cuBLAS DTRSM).
//' Solves op(A) * X = alpha * B (side="L") or X * op(A) = alpha * B (side="R").
//' A is triangular; \code{uplo} selects upper/lower, \code{diag} selects unit diagonal.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dtrsm(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B,
                                      std::string side = "L", std::string uplo = "U",
                                      std::string trans = "N", std::string diag = "N",
                                      double alpha = 1.0) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    const bool side_left = rcompss_gpu_linalg_parse_side_left(side);
    const bool upper = rcompss_gpu_linalg_parse_upper(uplo);
    const bool transA = rcompss_gpu_linalg_parse_trans(trans);
    const bool unit_diag = rcompss_gpu_linalg_parse_unit_diag(diag);

    const int m = B.nrow();
    const int n = B.ncol();
    const int a_size = side_left ? m : n;
    if (A.nrow() != a_size || A.ncol() != a_size) {
      Rcpp::stop("DTRSM: A must be %d×%d (got %d×%d).", a_size, a_size, A.nrow(), A.ncol());
    }

    const size_t bytesA = static_cast<size_t>(A.nrow()) * static_cast<size_t>(A.ncol()) * sizeof(double);
    const size_t bytesB = static_cast<size_t>(m) * static_cast<size_t>(n) * sizeof(double);

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray dB(bytesB, ctx);
    if (!dA.ok() || !dB.ok()) {
      Rcpp::stop("GPU allocation failed for dtrsm.");
    }

    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(dB.ptr(), reinterpret_cast<const char *>(REAL(B)), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);

    rcompss::kernels::GpuBlasDtrsm(ctx, side_left, upper, transA, unit_diag, m, n, alpha,
                                   dA.as_double(), A.nrow(), dB.as_double(), m);

    Rcpp::NumericMatrix X(m, n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(X)), dB.ptr(), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return X;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dtrsm failed: %s", e.what());
  }
#else
  (void)A;
  (void)B;
  (void)side;
  (void)uplo;
  (void)trans;
  (void)diag;
  (void)alpha;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}

//' Symmetric rank-k update on GPU (cuBLAS DSRYK).
//' C = alpha * op(A) %*% t(op(A)) + beta * C, with C symmetric.
//' Only the triangle specified by \code{uplo} is referenced/updated.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dsyrk(Rcpp::NumericMatrix A,
                                      std::string uplo = "U",
                                      std::string trans = "N",
                                      double alpha = 1.0,
                                      double beta = 0.0,
                                      Rcpp::Nullable<Rcpp::NumericMatrix> C0 = R_NilValue) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    const bool upper = rcompss_gpu_linalg_parse_upper(uplo);
    const bool transA = rcompss_gpu_linalg_parse_trans(trans);

    const int n = transA ? A.ncol() : A.nrow();
    const int k = transA ? A.nrow() : A.ncol();
    if (A.nrow() == 0 || A.ncol() == 0) {
      Rcpp::stop("DSYRK: A must be non-empty.");
    }

    const size_t bytesA = static_cast<size_t>(A.nrow()) * static_cast<size_t>(A.ncol()) * sizeof(double);
    const size_t bytesC = static_cast<size_t>(n) * static_cast<size_t>(n) * sizeof(double);

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray dC(bytesC, ctx);
    if (!dA.ok() || !dC.ok()) {
      Rcpp::stop("GPU allocation failed for dsyrk.");
    }
    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);

    if (beta != 0.0) {
      if (!C0.isNotNull()) {
        Rcpp::stop("DSYRK: beta is non-zero; provide C0 (n×n).");
      }
      Rcpp::NumericMatrix C0m(C0);
      if (C0m.nrow() != n || C0m.ncol() != n) {
        Rcpp::stop("DSYRK: C0 must be %d×%d (got %d×%d).", n, n, C0m.nrow(), C0m.ncol());
      }
      rcompss::memory::MemCpy(dC.ptr(), reinterpret_cast<const char *>(REAL(C0m)), bytesC, ctx,
                              rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    } else {
      cudaError_t memset_st = cudaMemset(dC.ptr(), 0, bytesC);
      if (memset_st != cudaSuccess) {
        Rcpp::stop("cudaMemset failed: %s", cudaGetErrorString(memset_st));
      }
    }

    rcompss::kernels::GpuBlasDsyrk(ctx, upper, transA, n, k, alpha, dA.as_double(), A.nrow(),
                                   beta, dC.as_double(), n);

    Rcpp::NumericMatrix C(n, n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(C)), dC.ptr(), bytesC, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return C;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dsyrk failed: %s", e.what());
  }
#else
  (void)A;
  (void)uplo;
  (void)trans;
  (void)alpha;
  (void)beta;
  (void)C0;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}

//' LU factorization on GPU (cuSOLVER DGETRF). \code{A} is m×n column-major.
//' Returns \code{list(LU, pivot, info)}; \code{pivot} has length min(m,n) (LAPACK-style indices).
// [[Rcpp::export]]
Rcpp::List rcompss_gpu_dgetrf(Rcpp::NumericMatrix A) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int m = A.nrow();
    int n = A.ncol();
    int min_mn = std::min(m, n);
    const size_t bytesA = static_cast<size_t>(m) * static_cast<size_t>(n) * sizeof(double);
    const size_t bytesPiv = static_cast<size_t>(min_mn) * sizeof(int);

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray dIpiv(bytesPiv, ctx);
    if (!dA.ok() || !dIpiv.ok()) {
      Rcpp::stop("GPU allocation failed for dgetrf.");
    }
    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(A)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    int info = rcompss::kernels::GpuSolverDgetrf(ctx, m, n, dA.as_double(), m,
                                                 reinterpret_cast<int *>(dIpiv.ptr()));
    Rcpp::NumericMatrix LU(m, n);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(LU)), dA.ptr(), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    std::vector<int> piv_host(static_cast<size_t>(min_mn));
    rcompss::memory::MemCpy(reinterpret_cast<char *>(piv_host.data()), dIpiv.ptr(), bytesPiv, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    Rcpp::IntegerVector pivot(min_mn);
    for (int i = 0; i < min_mn; ++i) {
      pivot[i] = piv_host[static_cast<size_t>(i)];
    }
    return Rcpp::List::create(Rcpp::Named("LU") = LU, Rcpp::Named("pivot") = pivot,
                              Rcpp::Named("info") = info);
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dgetrf failed: %s", e.what());
  }
#else
  (void)A;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::List();
#endif
}

//' Solve op(LU) * X = B after \code{rcompss_gpu_dgetrf} on a square n×n matrix.
//' \code{LU} and \code{pivot} are as returned there; \code{B} is n×nrhs (or length-n vector).
//' If \code{trans=TRUE}, solves t(A)*X = B.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dgetrs(Rcpp::NumericMatrix LU, Rcpp::IntegerVector pivot,
                                       Rcpp::RObject B, bool trans = false) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = LU.nrow();
    if (LU.ncol() != n) {
      Rcpp::stop("dgetrs requires square LU (got %d×%d).", LU.nrow(), LU.ncol());
    }
    if (static_cast<int>(pivot.size()) != n) {
      Rcpp::stop("dgetrs: pivot must have length n=%d (got %d).", n, static_cast<int>(pivot.size()));
    }
    Rcpp::NumericMatrix Bm;
    int nrhs = 0;
    if (Rf_isMatrix(B)) {
      Bm = Rcpp::as<Rcpp::NumericMatrix>(B);
      if (Bm.nrow() != n) {
        Rcpp::stop("dgetrs: B must have nrow = n (%d).", n);
      }
      nrhs = Bm.ncol();
    } else {
      Rcpp::NumericVector bv = Rcpp::as<Rcpp::NumericVector>(B);
      if (static_cast<int>(bv.size()) != n) {
        Rcpp::stop("dgetrs: B must have length n (%d).", n);
      }
      Bm = Rcpp::NumericMatrix(n, 1);
      std::memcpy(REAL(Bm), REAL(bv), static_cast<size_t>(n) * sizeof(double));
      nrhs = 1;
    }
    const size_t bytesLU = static_cast<size_t>(n) * static_cast<size_t>(n) * sizeof(double);
    const size_t bytesB = static_cast<size_t>(n) * static_cast<size_t>(nrhs) * sizeof(double);
    const size_t bytesPiv = static_cast<size_t>(n) * sizeof(int);

    ScopedGpuArray dLU(bytesLU, ctx);
    ScopedGpuArray dB(bytesB, ctx);
    ScopedGpuArray dIpiv(bytesPiv, ctx);
    if (!dLU.ok() || !dB.ok() || !dIpiv.ok()) {
      Rcpp::stop("GPU allocation failed for dgetrs.");
    }
    rcompss::memory::MemCpy(dLU.ptr(), reinterpret_cast<const char *>(REAL(LU)), bytesLU, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(dB.ptr(), reinterpret_cast<const char *>(REAL(Bm)), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    std::vector<int> piv_host(static_cast<size_t>(n));
    for (int i = 0; i < n; ++i) {
      piv_host[static_cast<size_t>(i)] = pivot[i];
    }
    rcompss::memory::MemCpy(dIpiv.ptr(), reinterpret_cast<const char *>(piv_host.data()), bytesPiv, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    int info = rcompss::kernels::GpuSolverDgetrs(ctx, trans, n, nrhs, dLU.as_double(), n,
                                                 reinterpret_cast<const int *>(dIpiv.ptr()),
                                                 dB.as_double(), n);
    if (info != 0) {
      Rcpp::stop("DGETRS failed (info=%d).", info);
    }
    Rcpp::NumericMatrix X(n, nrhs);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(X)), dB.ptr(), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return X;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dgetrs failed: %s", e.what());
  }
#else
  (void)LU;
  (void)pivot;
  (void)B;
  (void)trans;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}

//' Solve A * X = B after \code{rcompss_gpu_dpotrf} (Cholesky factor in \code{chol}).
//' \code{B} is n×nrhs or a length-n vector; returns X with the same shape as \code{B}.
// [[Rcpp::export]]
Rcpp::NumericMatrix rcompss_gpu_dpotrs(Rcpp::NumericMatrix chol, Rcpp::RObject B, bool upper = true) {
#ifdef USE_CUDA
  try {
    auto *ctx = rcompss_gpu_linalg_require_context();
    int n = chol.nrow();
    if (chol.ncol() != n) {
      Rcpp::stop("dpotrs requires square Cholesky factor (got %d×%d).", chol.nrow(), chol.ncol());
    }
    Rcpp::NumericMatrix Bm;
    int nrhs = 0;
    if (Rf_isMatrix(B)) {
      Bm = Rcpp::as<Rcpp::NumericMatrix>(B);
      if (Bm.nrow() != n) {
        Rcpp::stop("dpotrs: B must have nrow = n (%d).", n);
      }
      nrhs = Bm.ncol();
    } else {
      Rcpp::NumericVector bv = Rcpp::as<Rcpp::NumericVector>(B);
      if (static_cast<int>(bv.size()) != n) {
        Rcpp::stop("dpotrs: B must have length n (%d).", n);
      }
      Bm = Rcpp::NumericMatrix(n, 1);
      std::memcpy(REAL(Bm), REAL(bv), static_cast<size_t>(n) * sizeof(double));
      nrhs = 1;
    }
    const size_t bytesA = static_cast<size_t>(n) * static_cast<size_t>(n) * sizeof(double);
    const size_t bytesB = static_cast<size_t>(n) * static_cast<size_t>(nrhs) * sizeof(double);

    ScopedGpuArray dA(bytesA, ctx);
    ScopedGpuArray dB(bytesB, ctx);
    if (!dA.ok() || !dB.ok()) {
      Rcpp::stop("GPU allocation failed for dpotrs.");
    }
    rcompss::memory::MemCpy(dA.ptr(), reinterpret_cast<const char *>(REAL(chol)), bytesA, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    rcompss::memory::MemCpy(dB.ptr(), reinterpret_cast<const char *>(REAL(Bm)), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::HOST_TO_DEVICE);
    int info = rcompss::kernels::GpuSolverDpotrs(ctx, upper, n, nrhs, dA.as_double(), n, dB.as_double(), n);
    if (info != 0) {
      Rcpp::stop("DPOTRS failed (info=%d).", info);
    }
    Rcpp::NumericMatrix X(n, nrhs);
    rcompss::memory::MemCpy(reinterpret_cast<char *>(REAL(X)), dB.ptr(), bytesB, ctx,
                            rcompss::memory::MemoryTransfer::DEVICE_TO_HOST);
    return X;
  } catch (const std::exception &e) {
    Rcpp::stop("rcompss_gpu_dpotrs failed: %s", e.what());
  }
#else
  (void)chol;
  (void)B;
  (void)upper;
  Rcpp::stop("RCOMPSs was built without CUDA support.");
  return Rcpp::NumericMatrix();
#endif
}
