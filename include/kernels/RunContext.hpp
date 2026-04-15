/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs GPU RunContext - Manages CUDA streams and handles
 *
 **/

#ifndef RCOMPSs_RUNCONTEXT_HPP
#define RCOMPSs_RUNCONTEXT_HPP

#include <core/GPUDefinitions.hpp>
#include <cstddef>
#include <string>

#ifdef USE_CUDA
#include <cuda_runtime.h>
#include <cusolverDn.h>
#include <cublas_v2.h>
#endif

namespace rcompss {
namespace kernels {

    class RunContext {
    public:
        /**
         * @brief
         * Run Context constructor
         *
         * @param[in] aOperationPlacement
         * Enum indicating whether the stream is CPU or GPU.
         * @param[in] aRunMode
         * Run mode indicating whether the stream is sync or async.
         *
         */
        explicit
        RunContext(
            const gpu::OperationPlacement &aOperationPlacement = gpu::CPU,
            const gpu::RunMode &aRunMode = gpu::RunMode::SYNC);

        /**
         * @brief
         * Run Context destructor.
         */
        ~RunContext();

        /**
         * @brief
         * Get the Operation placement, indicating whether the context is
         * for GPU or CPU.
         *
         * @returns
         * Operation placement.
         */
        gpu::OperationPlacement
        GetOperationPlacement() const;

        /**
         * @brief
         * Set the Operation placement, to indicate whether the context is
         * for GPU or CPU.
         *
         * @param[in] aOperationPlacement
         * Operation placement enum CPU,GPU.
         *
         */
        void
        SetOperationPlacement(
            const gpu::OperationPlacement &aOperationPlacement);

        /**
         * @brief
         * Get the RunMode for the context, indicating whether the context is
         * SYNC or ASYNC, useful only in the case of GPU
         *
         * @returns
         * Run Mode
         */
        gpu::RunMode
        GetRunMode() const;

        /**
         * @brief
         * Set the RunMode for the context, to indicate whether the context is
         * SYNC or ASYNC, useful only in the case of GPU
         *
         * @param[in] aRunMode
         * Run Mode enum indicating whether the context is SYNC or ASYNC
         */
        void
        SetRunMode(const gpu::RunMode &aRunMode);

        /**
         * @brief
         * sync the context CUDA stream.
         *
         */
        void
        Sync() const;

#ifdef USE_CUDA

        /**
         * @brief
         * Get context CUDA stream to be used for any operation.
         *
         * @returns
         * CUDA stream.
         *
         */
        cudaStream_t
        GetStream() const;

        /**
         * @brief
         * Get context CuSolver handle.
         *
         * @returns
         * CuSolver handle.
         *
         */
        cusolverDnHandle_t
        GetCusolverDnHandle() const;

        /**
         * @brief
         * Get context CuBlas handle.
         *
         * @returns
         * Cublas handle.
         *
         */
        cublasHandle_t
        GetCuBlasDnHandle() const;

        /**
         * @brief
         * Get Information pointer used as output for any CuSolver call.
         *
         * @returns
         * info pointer on GPU
         *
         */
        int *
        GetInfoPointer() const;

        /**
         * @brief
         * Request a GPU work buffer for CuSolver/CuBlas operations.
         * The function will allocate a buffer in case the buffer size requested
         * is larger than the one already allocated, if not, it will return
         * the allocated work buffer.
         *
         * @returns
         * void pointer to the allocated work buffer.
         *
         */
        void *
        RequestWorkBufferDevice(const size_t &aBufferSize) const;

        /**
         * @brief
         * Request a CPU work buffer for CuSolver/CuBlas operations.
         * The function will allocate a buffer in case the buffer size requested
         * is larger than the one already allocated, if not, it will return
         * the allocated work buffer.
         *
         * @returns
         * void pointer to the allocated work buffer.
         *
         */
        void *
        RequestWorkBufferHost(const size_t &aBufferSize) const;

        /**
         * @brief
         * Sync the stream and then free the allocated work buffer.
         *
         */
        void
        FreeWorkBufferDevice() const;

        /**
         * @brief
         * Sync the stream and then free the allocated work buffer.
         *
         */
        void
        FreeWorkBufferHost() const;

#endif

    private:

#ifdef USE_CUDA
        /**
         * @brief
         * Clear up all the allocated memory and destroys all the handles.
         * This function doesn't change the state of context, so the RunContext
         * and the Operation placement will not be changed.
         *
         */
        void
        ClearUp();

        /** Integer pointer on device containing the rc values of cublas/cusolver **/
        int *mpInfo;
        /** GPU Work buffer needed for cublas/cusolver operations **/
        mutable void *mpWorkBufferDevice;
        /** Work buffer size **/
        mutable size_t mWorkBufferSizeDevice;
        /** CPU Work buffer needed for cublas/cusolver operations **/
        mutable void *mpWorkBufferHost;
        /** Work buffer size **/
        mutable size_t mWorkBufferSizeHost;
        /** cusolver handle **/
        cusolverDnHandle_t mCuSolverHandle;
        /** cublas handle **/
        cublasHandle_t  mCuBlasHandle;
        /** Cuda stream **/
        cudaStream_t mCudaStream;
#endif
        /** Enum indicating whether the operation is sync or async **/
        gpu::RunMode mRunMode;
        /** Enum indicating whether the operation is done on GPU or CPU **/
        gpu::OperationPlacement mOperationPlacement;
    };

} // namespace kernels
} // namespace rcompss

#endif // RCOMPSs_RUNCONTEXT_HPP

