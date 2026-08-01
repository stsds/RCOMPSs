/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * cuBLAS / cuSOLVER helpers for R-facing GPU linear algebra.
 **/

#ifndef RCOMPSs_CUDALIBRARYWRAPPERS_HPP
#define RCOMPSs_CUDALIBRARYWRAPPERS_HPP

#include <kernels/RunContext.hpp>

#ifdef USE_CUDA

namespace rcompss {
namespace kernels {

/**
 * C = alpha * op(A) * op(B) + beta * C (column-major, same layout as R matrices).
 * transA/transB: false = no transpose, true = transpose.
 * A is m×k (or k×m if transA), B is k×n (or n×k if transB), C is m×n.
 */
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
             int ldc);

/**
 * y <- alpha * x + y (length n).
 */
void
GpuBlasDaxpy(RunContext *ctx, int n, double alpha, const double *d_x, double *d_y);

/**
 * y <- alpha * op(A) * x + beta * y (column-major A, m×n). trans=false => op(A)=A (x length n, y length m).
 * trans=true => op(A)=A' (x length m, y length n).
 */
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
             double *d_y);

/**
 * Host scalar result: *h_result = x' y.
 */
void
GpuBlasDdot(RunContext *ctx, int n, const double *d_x, const double *d_y, double *h_result);

/**
 * Host scalar result: *h_result = ||x||_2.
 */
void
GpuBlasDnrm2(RunContext *ctx, int n, const double *d_x, double *h_result);

/**
 * x <- alpha * x (length n).
 */
void
GpuBlasDscal(RunContext *ctx, int n, double alpha, double *d_x);

/**
 * C = alpha * op(A) * B (side=left) or C = alpha * B * op(A) (side=right).
 * A is triangular: upper/lower, unit/non-unit diagonal. A is square (m×m or n×n).
 */
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
             int ldc);

/**
 * Solve op(A) * X = alpha * B (side=left) or X * op(A) = alpha * B (side=right).
 * B is overwritten with X. A is triangular: upper/lower, unit/non-unit diagonal.
 */
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
             int ldb);

/**
 * Symmetric rank-k update: C = alpha * op(A) * op(A)' + beta * C.
 * C is symmetric (upper or lower stored). A is n×k (or k×n if trans).
 */
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
             int ldc);

/**
 * Cholesky factorization of SPD matrix A (n×n, column-major, lda >= n).
 * Overwrites upper or lower triangle of d_A; other triangle is not referenced for result.
 * Uses ctx stream and ctx cuSOLVER handle; writes info to ctx device info pointer.
 * Returns host info: 0 = success, i > 0 means leading minor i is not positive definite.
 */
int
GpuSolverDpotrf(RunContext *ctx, bool upper, int n, double *dA, int lda);

/**
 * Solve op(A) * X = B after DGETRF (LU in dA, pivot dIpiv). B is n×nrhs, column-major, ldb >= n.
 * trans: false => op(A)=A, true => op(A)=A^T. Returns host info (0 = success).
 */
int
GpuSolverDgetrs(RunContext *ctx, bool trans, int n, int nrhs, const double *dA, int lda, const int *dIpiv,
                double *dB, int ldb);

/**
 * Solve A * X = B after DPOTRF (Cholesky factor in dA). B overwritten with X. Returns host info.
 */
int
GpuSolverDpotrs(RunContext *ctx, bool upper, int n, int nrhs, const double *dA, int lda, double *dB, int ldb);

/**
 * LU factorization P*A = L*U (column-major m×n). dIpiv length min(m,n). Returns host info (0 = success).
 */
int
GpuSolverDgetrf(RunContext *ctx, int m, int n, double *dA, int lda, int *dIpiv);

} // namespace kernels
} // namespace rcompss

#endif // USE_CUDA

#endif // RCOMPSs_CUDALIBRARYWRAPPERS_HPP
