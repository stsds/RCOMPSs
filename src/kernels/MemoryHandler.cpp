/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs GPU Memory Handler Implementation
 *
 **/

#include <kernels/MemoryHandler.hpp>
#include <algorithm>
#include <stdexcept>
#include <iostream>

#ifdef USE_CUDA
#include <kernels/cuda/CudaMemoryKernels.hpp>
#include <cuda_runtime.h>

#define GPU_ERROR_CHECK(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "[RCOMPSs GPU] CUDA error at " << __FILE__ << ":" << __LINE__ \
                      << " - " << cudaGetErrorString(error) << std::endl; \
            throw std::runtime_error("CUDA error: " + std::string(cudaGetErrorString(error))); \
        } \
    } while(0)
#endif

using namespace rcompss;
using namespace rcompss::memory;
using namespace rcompss::gpu;

char *
memory::AllocateArray(const size_t &aSizeInBytes,
                      const gpu::OperationPlacement &aPlacement,
                      const kernels::RunContext *aContext) {

    char *pdata = nullptr;

    if (aSizeInBytes == 0) {
        return pdata;
    }

#ifdef USE_CUDA
    if (aPlacement == gpu::GPU) {
        GPU_ERROR_CHECK(cudaMalloc((void **) &pdata, aSizeInBytes));
    }
#endif
    if (aPlacement == gpu::CPU) {
        pdata = new char[aSizeInBytes];
    }

    return pdata;
}

void
memory::DestroyArray(char *&apArray, const gpu::OperationPlacement &aPlacement,
                     const kernels::RunContext *aContext) {

    if (apArray != nullptr) {
#ifdef USE_CUDA
        if (aPlacement == gpu::GPU) {
            GPU_ERROR_CHECK(cudaFree(apArray));
        }
#endif
        if (aPlacement == gpu::CPU) {
            delete[] apArray;
        }
    }
    apArray = nullptr;
}

void
memory::MemCpy(char *apDestination, const char *apSrcDataArray,
               const size_t &aSizeInBytes, const kernels::RunContext *aContext,
               MemoryTransfer aTransferType) {
    if (aSizeInBytes == 0) {
        return;
    }
#ifdef USE_CUDA
    if (aTransferType != MemoryTransfer::HOST_TO_HOST) {
        if (aContext == nullptr ||
            aContext->GetOperationPlacement() == gpu::CPU) {
            throw std::runtime_error("CUDA Memcpy cannot be performed with CPU context");
        }
        GPU_ERROR_CHECK(
            cudaMemcpyAsync(apDestination, apSrcDataArray,
                            aSizeInBytes,
                            MemoryDirectionConverter::ToCudaMemoryTransferType(
                                aTransferType),
                            aContext->GetStream()));
        if (aContext->GetRunMode() == gpu::RunMode::SYNC) {
            GPU_ERROR_CHECK(cudaStreamSynchronize(aContext->GetStream()));
        }
    }
#endif

    if (aTransferType == MemoryTransfer::HOST_TO_HOST) {
        std::memcpy(apDestination, apSrcDataArray, aSizeInBytes);
    }
}

void
memory::Memset(char *apDestination, char aValue, const size_t &aSizeInBytes,
               const gpu::OperationPlacement &aPlacement,
               const kernels::RunContext *aContext) {
#ifdef USE_CUDA
    if (aPlacement == gpu::GPU) {
        if (aContext == nullptr ||
            aContext->GetOperationPlacement() == gpu::CPU) {
            throw std::runtime_error("CUDA Memset cannot be performed with CPU context");
        }
        GPU_ERROR_CHECK(cudaMemsetAsync(apDestination, aValue, aSizeInBytes,
                                        aContext->GetStream()));
        if (aContext->GetRunMode() == gpu::RunMode::SYNC) {
            GPU_ERROR_CHECK(cudaStreamSynchronize(aContext->GetStream()));
        }
    }
#endif

    if (aPlacement == gpu::CPU) {
        std::memset(apDestination, aValue, aSizeInBytes);
    }
}

template <typename T, typename X>
void
memory::Copy(const char *apSource, char *apDestination,
             const size_t &aNumElements,
             const gpu::OperationPlacement &aOperationPlacement) {

    if (aOperationPlacement == gpu::CPU) {
        std::copy((T *) apSource, ((T *) apSource) + aNumElements,
                  (X *) apDestination);
    } else {
#ifdef USE_CUDA
        memory::CopyDevice<T, X>(apSource, apDestination, aNumElements);
#else
        throw std::runtime_error("CUDA Copy cannot be performed with CPU Compiled code");
#endif
    }
}

#ifdef USE_CUDA

template <typename T, typename X>
void
memory::CopyDevice(const char *apSource, char *apDestination,
               const size_t &aNumElements) {

    auto pData_src = (T *) apSource;
    auto pData_des = (X *) apDestination;
    auto context = kernels::ContextManager::GetOperationContext();
    if (context->GetOperationPlacement() == gpu::CPU) {
        context = kernels::ContextManager::GetGPUContext();
    }
    kernels::CudaMemoryKernels::Copy<T, X>(pData_src, pData_des, aNumElements,
                                            context);
}

// Explicit template instantiations for common types
template void memory::Copy<float, float>(const char *, char *, const size_t &, const gpu::OperationPlacement &);
template void memory::Copy<double, double>(const char *, char *, const size_t &, const gpu::OperationPlacement &);
template void memory::Copy<float, double>(const char *, char *, const size_t &, const gpu::OperationPlacement &);
template void memory::Copy<double, float>(const char *, char *, const size_t &, const gpu::OperationPlacement &);

template void memory::CopyDevice<float, float>(const char *, char *, const size_t &);
template void memory::CopyDevice<double, double>(const char *, char *, const size_t &);
template void memory::CopyDevice<float, double>(const char *, char *, const size_t &);
template void memory::CopyDevice<double, float>(const char *, char *, const size_t &);

#endif

