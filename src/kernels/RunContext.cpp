/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs GPU RunContext Implementation
 *
 **/

#include <kernels/RunContext.hpp>
#include <iostream>

#ifdef USE_CUDA
#define GPU_ERROR_CHECK(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "[RCOMPSs GPU] CUDA error at " << __FILE__ << ":" << __LINE__ \
                      << " - " << cudaGetErrorString(error) << std::endl; \
            throw std::runtime_error("CUDA error: " + std::string(cudaGetErrorString(error))); \
        } \
    } while(0)

// Destructor-safe CUDA check: log errors but never throw (destructors are noexcept by default).
#define GPU_ERROR_CHECK_NO_THROW(call) \
    do { \
        cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "[RCOMPSs GPU] CUDA error at " << __FILE__ << ":" << __LINE__ \
                      << " - " << cudaGetErrorString(error) << std::endl; \
        } \
    } while(0)
#endif

using namespace rcompss::kernels;
using namespace rcompss::gpu;

RunContext::RunContext(
    const gpu::OperationPlacement &aOperationPlacement,
    const gpu::RunMode &aRunMode) {

#ifdef USE_CUDA
    this->mpInfo = nullptr;
    if (aOperationPlacement == gpu::GPU) {
        GPU_ERROR_CHECK(cudaStreamCreate(&this->mCudaStream));
        cusolverDnCreate(&this->mCuSolverHandle);
        cusolverDnSetStream(this->mCuSolverHandle, this->mCudaStream);

        cublasCreate(&this->mCuBlasHandle);
        cublasSetStream(this->mCuBlasHandle, this->mCudaStream);

        GPU_ERROR_CHECK(cudaMalloc((void **) &this->mpInfo, sizeof(int)));
    }
    this->mWorkBufferSizeHost = 0;
    this->mpWorkBufferHost = nullptr;
    this->mWorkBufferSizeDevice = 0;
    this->mpWorkBufferDevice = nullptr;
    this->mOperationPlacement = aOperationPlacement;

#else
    std::cerr << "[RCOMPSs GPU] Context is running without GPU support" << std::endl;
    this->mOperationPlacement = gpu::CPU;
#endif

    this->mRunMode = aRunMode;
}

RunContext::~RunContext() {
#ifdef USE_CUDA
    int rc = 0;
    // Never throw from destructor; best-effort cleanup.
    try {
        this->Sync();
    } catch (...) {
        // ignore
    }
    if (this->mpWorkBufferDevice != nullptr) {
        GPU_ERROR_CHECK_NO_THROW(cudaFree(this->mpWorkBufferDevice));
    }
    if (this->mpWorkBufferHost != nullptr) {
        delete[] (char *) this->mpWorkBufferHost;
    }

    if (this->mOperationPlacement == gpu::GPU) {
        rc = cusolverDnDestroy(this->mCuSolverHandle);
        if (rc) {
            std::cerr << "[RCOMPSs GPU] Error While Destroying CuSolver Handle: " << rc << std::endl;
        }
        rc = cublasDestroy(this->mCuBlasHandle);
        if (rc) {
            std::cerr << "[RCOMPSs GPU] Error While Destroying CuBlas Handle: " << rc << std::endl;
        }
        rc = cudaStreamDestroy(this->mCudaStream);
        if (rc) {
            std::cerr << "[RCOMPSs GPU] Error While Destroying CUDA stream: " << rc << std::endl;
        }

        GPU_ERROR_CHECK_NO_THROW(cudaFree(this->mpInfo));
    }
#endif
}

rcompss::gpu::RunMode
RunContext::GetRunMode() const {
    return this->mRunMode;
}

rcompss::gpu::OperationPlacement
RunContext::GetOperationPlacement() const {
    return this->mOperationPlacement;
}

void
RunContext::SetOperationPlacement(
    const gpu::OperationPlacement &aOperationPlacement) {

#ifdef USE_CUDA
    if (this->mOperationPlacement == gpu::GPU &&
        aOperationPlacement == gpu::GPU) {
        this->FreeWorkBufferDevice();
        return;
    }
    this->ClearUp();
    this->mOperationPlacement = aOperationPlacement;
    if (this->mOperationPlacement == gpu::GPU) {
        GPU_ERROR_CHECK(cudaStreamCreate(&this->mCudaStream));
        cusolverDnCreate(&this->mCuSolverHandle);
        cusolverDnSetStream(this->mCuSolverHandle, this->mCudaStream);

        cublasCreate(&this->mCuBlasHandle);
        cublasSetStream(this->mCuBlasHandle, this->mCudaStream);

        GPU_ERROR_CHECK(cudaMalloc((void **) &this->mpInfo, sizeof(int)));
    }
#else
    std::cerr << "[RCOMPSs GPU] Context is running without GPU support, Mode of operation is set automatically to CPU" << std::endl;
    this->mOperationPlacement = gpu::CPU;
#endif
}

void
RunContext::Sync() const {
#ifdef USE_CUDA
    if (this->mOperationPlacement == gpu::GPU) {
        GPU_ERROR_CHECK(cudaStreamSynchronize(this->mCudaStream));
    }
#endif
}

void
RunContext::SetRunMode(const gpu::RunMode &aRunMode) {
    if (this->mRunMode == RunMode::ASYNC && aRunMode == RunMode::SYNC) {
        this->Sync();
    }
    this->mRunMode = aRunMode;
}

#ifdef USE_CUDA

cudaStream_t
RunContext::GetStream() const {
    if (this->mOperationPlacement == gpu::CPU) {
        throw std::runtime_error("Cannot get context metadata while running CPU context");
    }
    return this->mCudaStream;
}

cusolverDnHandle_t
RunContext::GetCusolverDnHandle() const {
    if (this->mOperationPlacement == gpu::CPU) {
        throw std::runtime_error("Cannot get context metadata while running CPU context");
    }
    return this->mCuSolverHandle;
}

int *
RunContext::GetInfoPointer() const {
    if (this->mOperationPlacement == gpu::CPU) {
        throw std::runtime_error("Cannot get context metadata while running CPU context");
    }
    return this->mpInfo;
}

void *
RunContext::RequestWorkBufferDevice(const size_t &aBufferSize) const {
    if (aBufferSize == 0) {
        return this->mpWorkBufferDevice;
    }

    if (this->mOperationPlacement == gpu::CPU) {
        throw std::runtime_error("Cannot get context metadata while running CPU context");
    }

    if (aBufferSize > this->mWorkBufferSizeDevice) {
        if (this->mpWorkBufferDevice != nullptr) {
            GPU_ERROR_CHECK(cudaFree(this->mpWorkBufferDevice));
        }
        this->mWorkBufferSizeDevice = aBufferSize;
        GPU_ERROR_CHECK(cudaMalloc(&this->mpWorkBufferDevice, aBufferSize));
    }
    return this->mpWorkBufferDevice;
}

void *
RunContext::RequestWorkBufferHost(const size_t &aBufferSize) const {
    if (aBufferSize == 0) {
        return this->mpWorkBufferHost;
    }

    if (this->mOperationPlacement == gpu::CPU) {
        throw std::runtime_error("Cannot get context metadata while running CPU context");
    }

    if (aBufferSize > this->mWorkBufferSizeHost) {
        if (this->mpWorkBufferHost != nullptr) {
            delete[] (char *) this->mpWorkBufferHost;
        }
        this->mWorkBufferSizeHost = aBufferSize;
        this->mpWorkBufferHost = new char[aBufferSize];
    }
    return this->mpWorkBufferHost;
}

void RunContext::ClearUp() {
    if (this->mOperationPlacement == gpu::GPU) {
        int rc = 0;
        this->Sync();
        if (this->mpWorkBufferDevice != nullptr) {
            GPU_ERROR_CHECK(cudaFree(this->mpWorkBufferDevice));
        }
        if (this->mpWorkBufferHost != nullptr) {
            delete[] (char *) this->mpWorkBufferHost;
        }
        rc = cusolverDnDestroy(this->mCuSolverHandle);
        if (rc) {
            std::cerr << "[RCOMPSs GPU] Error While Destroying CuSolver Handle: " << rc << std::endl;
        }
        rc = cublasDestroy(this->mCuBlasHandle);
        if (rc) {
            std::cerr << "[RCOMPSs GPU] Error While Destroying CuBlas Handle: " << rc << std::endl;
        }
        rc = cudaStreamDestroy(this->mCudaStream);
        if (rc) {
            std::cerr << "[RCOMPSs GPU] Error While Destroying CUDA stream: " << rc << std::endl;
        }
        GPU_ERROR_CHECK(cudaFree(this->mpInfo));
    }

    this->mpInfo = nullptr;
    this->mWorkBufferSizeDevice = 0;
    this->mpWorkBufferDevice = nullptr;
    this->mWorkBufferSizeHost = 0;
    this->mpWorkBufferHost = nullptr;
}

void
RunContext::FreeWorkBufferDevice() const {
    if (this->mOperationPlacement == gpu::GPU) {
        this->Sync();
        if (this->mpWorkBufferDevice != nullptr) {
            GPU_ERROR_CHECK(cudaFree(this->mpWorkBufferDevice));
        }
    }
    // Note: We can't modify mutable members here, so we just free the buffer
    // The size tracking would need to be reset elsewhere if needed
}

void
RunContext::FreeWorkBufferHost() const {
    if (this->mOperationPlacement == gpu::GPU) {
        this->Sync();
        if (this->mpWorkBufferHost != nullptr) {
            delete[] (char *) this->mpWorkBufferHost;
        }
    }
    // Note: We can't modify mutable members here, so we just free the buffer
}

cublasHandle_t
RunContext::GetCuBlasDnHandle() const {
    if (this->mOperationPlacement == gpu::CPU) {
        throw std::runtime_error("Cannot get context metadata while running CPU context");
    }
    return mCuBlasHandle;
}

#endif

