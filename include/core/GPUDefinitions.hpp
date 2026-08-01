/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs GPU Support Definitions
 *
 **/

#ifndef RCOMPSs_GPU_DEFINITIONS_HPP
#define RCOMPSs_GPU_DEFINITIONS_HPP

#include <string>
#include <algorithm>
#include <stdexcept>

namespace rcompss {
namespace gpu {

    /** Enum to describe whether a RunContext is on GPU or CPU **/
    enum OperationPlacement : int {
        GPU = 0,
        CPU = 1
    };

    /** Enum describing the CUDA stream behavior (async, sync),
     * not used in the case of CPU Context.  **/
    enum class RunMode {
        SYNC,
        ASYNC
    };

    /**
     * @brief
     * Get Input operation placement from a string.
     * Transforms the string to lower case to ensure proper initialization
     *
     * @param[in] aPlacement
     * String describing required placement (CPU/GPU)
     *
     * @returns
     * OperationPlacement enum
     */
    inline
    OperationPlacement
    GetInputOperationPlacement(const std::string &aPlacement) {
        std::string placement = aPlacement;
        std::transform(placement.begin(), placement.end(),
                       placement.begin(), ::tolower);
        if (placement == "gpu") {
            return GPU;
        } else if (placement == "cpu") {
            return CPU;
        } else {
            throw std::runtime_error("Invalid operation placement: " + aPlacement);
        }
    }

    /**
     * @brief
     * Get Input run mode from a string.
     * Transforms the string to lower case to ensure proper initialization
     *
     * @param[in] aRunMode
     * String describing required run mode (SYNC/ASYNC)
     *
     * @returns
     * RunMode enum
     */
    inline
    RunMode
    GetInputRunMode(const std::string &aRunMode) {
        std::string run_mode = aRunMode;
        std::transform(run_mode.begin(), run_mode.end(),
                       run_mode.begin(), ::tolower);
        if (run_mode == "sync") {
            return RunMode::SYNC;
        } else if (run_mode == "async") {
            return RunMode::ASYNC;
        } else {
            throw std::runtime_error("Invalid run mode: " + aRunMode);
        }
    }

} // namespace gpu
} // namespace rcompss

#endif // RCOMPSs_GPU_DEFINITIONS_HPP

