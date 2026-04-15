/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs CUDA Memory Kernels Implementation
 *
 **/

#include <kernels/cuda/CudaMemoryKernels.hpp>
#include <cuda_runtime.h>

using namespace rcompss::kernels;

template <typename T, typename X>
__global__
void
PerformCopy(const T *apSource, X *apDestination, size_t aNumElements) {
    size_t tid = blockIdx.x * blockDim.x + threadIdx.x;

    if (tid < aNumElements) {
        apDestination[tid] = static_cast<X>(apSource[tid]);
    }
}

template <typename T, typename X>
void
CudaMemoryKernels::Copy(const T *apSource, X *apDestination,
                        const size_t &aNumElements,
                        const kernels::RunContext *aContext) {
    auto threadsPerBlock = 256;
    auto blocksPerGrid =
        (aNumElements + threadsPerBlock - 1) / threadsPerBlock;

    PerformCopy<T, X><<<blocksPerGrid,
                         threadsPerBlock, 0, aContext->GetStream()>>>
        (apSource, apDestination, aNumElements);

    aContext->Sync();
}

// Explicit template instantiations for common types
template void CudaMemoryKernels::Copy<float, float>(const float *, float *, const size_t &, const RunContext *);
template void CudaMemoryKernels::Copy<double, double>(const double *, double *, const size_t &, const RunContext *);
template void CudaMemoryKernels::Copy<float, double>(const float *, double *, const size_t &, const RunContext *);
template void CudaMemoryKernels::Copy<double, float>(const double *, float *, const size_t &, const RunContext *);

