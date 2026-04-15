/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs R Adapters for GPU Context Management Implementation
 *
 **/

#include <adapters/RContextManager.hpp>
#include <core/GPUDefinitions.hpp>
#include <algorithm>

using namespace rcompss::gpu;

void
rcompss::adapters::SetOperationPlacement(std::string &aRunContextName, const std::string &aOperationPlacement) {
    auto operation_placement = GetInputOperationPlacement(aOperationPlacement);
    auto &ContextManager = kernels::ContextManager::GetInstance();
    ContextManager.GetContext(aRunContextName)->SetOperationPlacement(operation_placement);
}

std::string
rcompss::adapters::GetOperationPlacement(std::string &aRunContextName) {
    auto &ContextManager = kernels::ContextManager::GetInstance();
    auto operation_placement = ContextManager.GetContext(aRunContextName)->GetOperationPlacement();
    return operation_placement == gpu::CPU ? "CPU" : "GPU";
}

void
rcompss::adapters::SetRunMode(std::string &aRunContextName, std::string &aRunMode) {
    auto &ContextManager = kernels::ContextManager::GetInstance();
    std::transform(aRunMode.begin(), aRunMode.end(),
                   aRunMode.begin(), ::tolower);
    auto run_mode = GetInputRunMode(aRunMode);
    ContextManager.GetContext(aRunContextName)->SetRunMode(run_mode);
}

std::string
rcompss::adapters::GetRunMode(std::string &aRunContextName) {
    auto &ContextManager = kernels::ContextManager::GetInstance();
    auto run_mode = ContextManager.GetContext(aRunContextName)->GetRunMode();
    return run_mode == RunMode::SYNC ? "SYNC" : "ASYNC";
}

void
rcompss::adapters::FinalizeRunContext(std::string &aRunContextName){
    auto &ContextManager = kernels::ContextManager::GetInstance();
    SyncContext(aRunContextName);
#ifdef USE_CUDA
    ContextManager.GetContext(aRunContextName)->FreeWorkBufferHost();
#endif
}

void
rcompss::adapters::CreateRunContext(std::string &aRunContextName){
    kernels::ContextManager::CreateRunContext(aRunContextName);
}

void
rcompss::adapters::SyncContext(const std::string &aRunContextName) {
    auto &ContextManager = kernels::ContextManager::GetInstance();
    ContextManager.SyncContext(aRunContextName);
}

void
rcompss::adapters::SyncAll(){
    auto &ContextManager = kernels::ContextManager::GetInstance();
    ContextManager.SyncAll();
}

size_t
rcompss::adapters::GetNumOfContexts(){
    auto &ContextManager = kernels::ContextManager::GetInstance();
    return ContextManager.GetNumOfContexts();
}

void
rcompss::adapters::SetOperationContext(std::string &aRunContextName){
    auto &ContextManager = kernels::ContextManager::GetInstance();
    auto runContext = ContextManager.GetContext(aRunContextName);
    ContextManager.SetOperationContext(runContext);
}

void
rcompss::adapters::DeleteRunContext(const std::string &aRunContextName){
    auto &ContextManager = kernels::ContextManager::GetInstance();
    ContextManager.DeleteRunContext(aRunContextName);
}

std::vector<std::string>
rcompss::adapters::GetAllContextNames(){
    auto &ContextManager = kernels::ContextManager::GetInstance();
    return ContextManager.GetAllContextNames();
}

