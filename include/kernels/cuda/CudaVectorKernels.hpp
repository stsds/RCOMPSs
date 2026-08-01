/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs CUDA Vector Computation Kernels
 *
 **/

#ifndef RCOMPSs_CUDAVECTORKERNELS_HPP
#define RCOMPSs_CUDAVECTORKERNELS_HPP

#include <kernels/ContextManager.hpp>
#include <cstddef>

namespace rcompss {
namespace kernels {

    class CudaVectorKernels {
    public:
        /**
         * @brief
         * CUDA Vector Addition: result = a + b
         * Performs element-wise addition of two vectors on GPU.
         *
         * @param[in] a
         * First input vector (device memory).
         * @param[in] b
         * Second input vector (device memory).
         * @param[out] result
         * Output vector (device memory), must be pre-allocated.
         * @param[in] aNumElements
         * Number of elements in the vectors.
         * @param[in] aContext
         * Run context containing cuda stream to use for the function.
         *
         */
        template <typename T>
        static
        void
        VectorAdd(const T *a, const T *b, T *result, const size_t &aNumElements,
                  const kernels::RunContext *aContext);

        /**
         * @brief
         * CUDA Vector Multiply: result = a * b
         * Performs element-wise multiplication of two vectors on GPU.
         *
         * @param[in] a
         * First input vector (device memory).
         * @param[in] b
         * Second input vector (device memory).
         * @param[out] result
         * Output vector (device memory), must be pre-allocated.
         * @param[in] aNumElements
         * Number of elements in the vectors.
         * @param[in] aContext
         * Run context containing cuda stream to use for the function.
         *
         */
        template <typename T>
        static
        void
        VectorMultiply(const T *a, const T *b, T *result, const size_t &aNumElements,
                      const kernels::RunContext *aContext);

    };

} // namespace kernels
} // namespace rcompss

#endif // RCOMPSs_CUDAVECTORKERNELS_HPP

