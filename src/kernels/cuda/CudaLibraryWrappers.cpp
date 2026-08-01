/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 **/

#include <kernels/cuda/CudaLibraryWrappers.hpp>

#ifdef USE_CUDA

#include <cublas_v2.h>
#include <cusolverDn.h>
#include <cuda_runtime.h>
#include <stdexcept>
#include <string>

#define RCOMPSs_GPU_BLAS_CHECK(call) \
  do { \
    cublasStatus_t _st = (call); \
    if (_st != CUBLAS_STATUS_SUCCESS) { \
      throw std::runtime_error("cuBLAS error: " + std::string(#call)); \
    } \
  } while (0)

#define RCOMPSs_GPU_SOLVER_CHECK(call) \
  do { \
    cusolverStatus_t _st = (call); \
    if (_st != CUSOLVER_STATUS_SUCCESS) { \
      throw std::runtime_error("cuSOLVER error: " + std::string(#call)); \
    } \
  } while (0)

#define RCOMPSs_CUDA_CHECK(call) \
  do { \
    cudaError_t _e = (call); \
    if (_e != cudaSuccess) { \
      throw std::runtime_error(std::string("CUDA error: ") + cudaGetErrorString(_e)); \
    } \
  } while (0)

namespace rcompss {
namespace kernels {

void
GpuBlasDgemm(RunContext *ctx,
             bool transA,
             bool transB,
             int m,
             int n,
             int k,
             double alpha,
             double beta,
             const double *dA,
             int lda,
             const double *dB,
             int ldb,
             double *dC,
             int ldc) {
  cublasOperation_t ta = transA ? CUBLAS_OP_T : CUBLAS_OP_N;
  cublasOperation_t tb = transB ? CUBLAS_OP_T : CUBLAS_OP_N;
  cublasHandle_t h = ctx->GetCuBlasDnHandle();
  RCOMPSs_GPU_BLAS_CHECK(cublasDgemm(h, ta, tb, m, n, k, &alpha, dA, lda, dB, ldb, &beta, dC, ldc));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDaxpy(RunContext *ctx, int n, double alpha, const double *d_x, double *d_y) {
  RCOMPSs_GPU_BLAS_CHECK(cublasDaxpy(ctx->GetCuBlasDnHandle(), n, &alpha, d_x, 1, d_y, 1));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDgemv(RunContext *ctx,
             bool trans,
             int m,
             int n,
             double alpha,
             double beta,
             const double *dA,
             int lda,
             const double *d_x,
             double *d_y) {
  cublasOperation_t op = trans ? CUBLAS_OP_T : CUBLAS_OP_N;
  RCOMPSs_GPU_BLAS_CHECK(cublasDgemv(ctx->GetCuBlasDnHandle(), op, m, n, &alpha, dA, lda, d_x, 1, &beta,
                                     d_y, 1));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDdot(RunContext *ctx, int n, const double *d_x, const double *d_y, double *h_result) {
  RCOMPSs_GPU_BLAS_CHECK(cublasDdot(ctx->GetCuBlasDnHandle(), n, d_x, 1, d_y, 1, h_result));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDnrm2(RunContext *ctx, int n, const double *d_x, double *h_result) {
  RCOMPSs_GPU_BLAS_CHECK(cublasDnrm2(ctx->GetCuBlasDnHandle(), n, d_x, 1, h_result));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDscal(RunContext *ctx, int n, double alpha, double *d_x) {
  RCOMPSs_GPU_BLAS_CHECK(cublasDscal(ctx->GetCuBlasDnHandle(), n, &alpha, d_x, 1));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDtrmm(RunContext *ctx,
             bool sideLeft,
             bool upper,
             bool trans,
             bool unitDiag,
             int m,
             int n,
             double alpha,
             const double *dA,
             int lda,
             const double *dB,
             int ldb,
             double *dC,
             int ldc) {
  cublasSideMode_t side = sideLeft ? CUBLAS_SIDE_LEFT : CUBLAS_SIDE_RIGHT;
  cublasFillMode_t uplo = upper ? CUBLAS_FILL_MODE_UPPER : CUBLAS_FILL_MODE_LOWER;
  cublasOperation_t op = trans ? CUBLAS_OP_T : CUBLAS_OP_N;
  cublasDiagType_t diag = unitDiag ? CUBLAS_DIAG_UNIT : CUBLAS_DIAG_NON_UNIT;
  cublasHandle_t h = ctx->GetCuBlasDnHandle();
  RCOMPSs_GPU_BLAS_CHECK(cublasDtrmm(h, side, uplo, op, diag, m, n, &alpha, dA, lda, dB, ldb, dC, ldc));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDtrsm(RunContext *ctx,
             bool sideLeft,
             bool upper,
             bool trans,
             bool unitDiag,
             int m,
             int n,
             double alpha,
             const double *dA,
             int lda,
             double *dB,
             int ldb) {
  cublasSideMode_t side = sideLeft ? CUBLAS_SIDE_LEFT : CUBLAS_SIDE_RIGHT;
  cublasFillMode_t uplo = upper ? CUBLAS_FILL_MODE_UPPER : CUBLAS_FILL_MODE_LOWER;
  cublasOperation_t op = trans ? CUBLAS_OP_T : CUBLAS_OP_N;
  cublasDiagType_t diag = unitDiag ? CUBLAS_DIAG_UNIT : CUBLAS_DIAG_NON_UNIT;
  cublasHandle_t h = ctx->GetCuBlasDnHandle();
  RCOMPSs_GPU_BLAS_CHECK(cublasDtrsm(h, side, uplo, op, diag, m, n, &alpha, dA, lda, dB, ldb));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

void
GpuBlasDsyrk(RunContext *ctx,
             bool upper,
             bool trans,
             int n,
             int k,
             double alpha,
             const double *dA,
             int lda,
             double beta,
             double *dC,
             int ldc) {
  cublasFillMode_t uplo = upper ? CUBLAS_FILL_MODE_UPPER : CUBLAS_FILL_MODE_LOWER;
  cublasOperation_t op = trans ? CUBLAS_OP_T : CUBLAS_OP_N;
  cublasHandle_t h = ctx->GetCuBlasDnHandle();
  RCOMPSs_GPU_BLAS_CHECK(cublasDsyrk(h, uplo, op, n, k, &alpha, dA, lda, &beta, dC, ldc));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
}

int
GpuSolverDpotrf(RunContext *ctx, bool upper, int n, double *dA, int lda) {
  cublasFillMode_t uplo = upper ? CUBLAS_FILL_MODE_UPPER : CUBLAS_FILL_MODE_LOWER;
  cusolverDnHandle_t sh = ctx->GetCusolverDnHandle();
  int lwork = 0;
  RCOMPSs_GPU_SOLVER_CHECK(
      cusolverDnDpotrf_bufferSize(sh, uplo, n, dA, lda, &lwork));
  double *d_work = nullptr;
  if (lwork > 0) {
    RCOMPSs_CUDA_CHECK(cudaMalloc(reinterpret_cast<void **>(&d_work), sizeof(double) * lwork));
  }
  int *d_info = ctx->GetInfoPointer();
  RCOMPSs_GPU_SOLVER_CHECK(cusolverDnDpotrf(sh, uplo, n, dA, lda, d_work, lwork, d_info));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
  if (d_work) {
    RCOMPSs_CUDA_CHECK(cudaFree(d_work));
  }
  int h_info = 0;
  RCOMPSs_CUDA_CHECK(cudaMemcpy(&h_info, d_info, sizeof(int), cudaMemcpyDeviceToHost));
  return h_info;
}

int
GpuSolverDgetrf(RunContext *ctx, int m, int n, double *dA, int lda, int *dIpiv) {
  cusolverDnHandle_t sh = ctx->GetCusolverDnHandle();
  int lwork = 0;
  RCOMPSs_GPU_SOLVER_CHECK(cusolverDnDgetrf_bufferSize(sh, m, n, dA, lda, &lwork));
  double *d_work = nullptr;
  if (lwork > 0) {
    RCOMPSs_CUDA_CHECK(cudaMalloc(reinterpret_cast<void **>(&d_work), sizeof(double) * static_cast<size_t>(lwork)));
  }
  int *d_info = ctx->GetInfoPointer();
  RCOMPSs_GPU_SOLVER_CHECK(cusolverDnDgetrf(sh, m, n, dA, lda, d_work, dIpiv, d_info));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
  if (d_work) {
    RCOMPSs_CUDA_CHECK(cudaFree(d_work));
  }
  int h_info = 0;
  RCOMPSs_CUDA_CHECK(cudaMemcpy(&h_info, d_info, sizeof(int), cudaMemcpyDeviceToHost));
  return h_info;
}

int
GpuSolverDgetrs(RunContext *ctx, bool trans, int n, int nrhs, const double *dA, int lda, const int *dIpiv,
                double *dB, int ldb) {
  cublasOperation_t op = trans ? CUBLAS_OP_T : CUBLAS_OP_N;
  cusolverDnHandle_t sh = ctx->GetCusolverDnHandle();
  int *d_info = ctx->GetInfoPointer();
  RCOMPSs_GPU_SOLVER_CHECK(cusolverDnDgetrs(sh, op, n, nrhs, dA, lda, dIpiv, dB, ldb, d_info));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
  int h_info = 0;
  RCOMPSs_CUDA_CHECK(cudaMemcpy(&h_info, d_info, sizeof(int), cudaMemcpyDeviceToHost));
  return h_info;
}

int
GpuSolverDpotrs(RunContext *ctx, bool upper, int n, int nrhs, const double *dA, int lda, double *dB, int ldb) {
  cublasFillMode_t uplo = upper ? CUBLAS_FILL_MODE_UPPER : CUBLAS_FILL_MODE_LOWER;
  cusolverDnHandle_t sh = ctx->GetCusolverDnHandle();
  int *d_info = ctx->GetInfoPointer();
  RCOMPSs_GPU_SOLVER_CHECK(cusolverDnDpotrs(sh, uplo, n, nrhs, dA, lda, dB, ldb, d_info));
  if (ctx->GetRunMode() == rcompss::gpu::RunMode::SYNC) {
    RCOMPSs_CUDA_CHECK(cudaStreamSynchronize(ctx->GetStream()));
  }
  int h_info = 0;
  RCOMPSs_CUDA_CHECK(cudaMemcpy(&h_info, d_info, sizeof(int), cudaMemcpyDeviceToHost));
  return h_info;
}

} // namespace kernels
} // namespace rcompss

#endif // USE_CUDA
