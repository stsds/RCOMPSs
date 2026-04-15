/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs CUDA Vector Computation Kernels Implementation
 *
 **/

#include <kernels/cuda/CudaVectorKernels.hpp>
#include <cuda_runtime.h>

using namespace rcompss::kernels;

// CUDA kernel for vector addition
template <typename T>
__global__
void
PerformVectorAdd(const T *a, const T *b, T *result, size_t aNumElements) {
    size_t tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < aNumElements) {
        result[tid] = a[tid] + b[tid];
    }
}

// CUDA kernel for vector multiplication
template <typename T>
__global__
void
PerformVectorMultiply(const T *a, const T *b, T *result, size_t aNumElements) {
    size_t tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < aNumElements) {
        result[tid] = a[tid] * b[tid];
    }
}

template <typename T>
void
CudaVectorKernels::VectorAdd(const T *a, const T *b, T *result,
                             const size_t &aNumElements,
                             const kernels::RunContext *aContext) {
    auto threadsPerBlock = 256;
    auto blocksPerGrid =
        (aNumElements + threadsPerBlock - 1) / threadsPerBlock;

    PerformVectorAdd<T><<<blocksPerGrid,
                          threadsPerBlock, 0, aContext->GetStream()>>>
        (a, b, result, aNumElements);

    aContext->Sync();
}

template <typename T>
void
CudaVectorKernels::VectorMultiply(const T *a, const T *b, T *result,
                                  const size_t &aNumElements,
                                  const kernels::RunContext *aContext) {
    auto threadsPerBlock = 256;
    auto blocksPerGrid =
        (aNumElements + threadsPerBlock - 1) / threadsPerBlock;

    PerformVectorMultiply<T><<<blocksPerGrid,
                               threadsPerBlock, 0, aContext->GetStream()>>>
        (a, b, result, aNumElements);

    aContext->Sync();
}

// Explicit template instantiations for common types
template void CudaVectorKernels::VectorAdd<double>(const double *, const double *, double *, const size_t &, const RunContext *);
template void CudaVectorKernels::VectorAdd<float>(const float *, const float *, float *, const size_t &, const RunContext *);

template void CudaVectorKernels::VectorMultiply<double>(const double *, const double *, double *, const size_t &, const RunContext *);
template void CudaVectorKernels::VectorMultiply<float>(const float *, const float *, float *, const size_t &, const RunContext *);

