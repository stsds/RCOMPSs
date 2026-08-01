/**
 * Copyright (c) 2025, King Abdullah University of Science and Technology
 * All rights reserved.
 *
 * RCOMPSs GPU ContextManager Implementation
 *
 **/

#include <kernels/ContextManager.hpp>
#include <iostream>
#include <stdexcept>

using namespace rcompss::kernels;
using namespace rcompss::gpu;

ContextManager *ContextManager::mpInstance = nullptr;

ContextManager &
ContextManager::GetInstance() {
    if (mpInstance == nullptr) {
        mpInstance = new ContextManager();
        mpInstance->mContexts["default"] = new RunContext();
        mpInstance->mpCurrentContext = mpInstance->mContexts["default"];
#ifdef USE_CUDA
        mpInstance->mpGPUContext = new RunContext(gpu::GPU, RunMode::SYNC);
#endif
    }
    return *mpInstance;
}

void
ContextManager::SyncContext(const std::string &aRunContextName) const {
    auto it = mContexts.find(aRunContextName);
    if (it == mContexts.end()) {
        throw std::runtime_error("No stream with that name: " + aRunContextName);
    }
    mContexts.at(aRunContextName)->Sync();
}

void
ContextManager::SyncMainContext() const {
    mContexts.at("default")->Sync();
}

void
ContextManager::SyncAll() const {
    for (auto it = mContexts.begin(); it != mContexts.end(); ++it) {
        auto context = it->second;
        if (context != nullptr) {
            context->Sync();
        }
    }
}

size_t
ContextManager::GetNumOfContexts() const {
    return mContexts.size();
}

void
ContextManager::DestroyInstance() {
    if (mpInstance) {
        mpInstance->SyncAll();

        for (auto it = mpInstance->mContexts.begin(); it != mpInstance->mContexts.end(); ++it) {
            delete it->second;
            it->second = nullptr;
        }
        mpInstance->mContexts.clear();

#ifdef USE_CUDA
        delete mpInstance->mpGPUContext;
        mpInstance->mpGPUContext = nullptr;
#endif

        delete mpInstance;
        mpInstance = nullptr;
    }
}

RunContext *
ContextManager::GetContext(const std::string &aRunContextName) {
    auto it = mContexts.find(aRunContextName);
    if (it == mContexts.end()) {
        throw std::runtime_error("No stream with that name: " + aRunContextName);
    }
    return mContexts[aRunContextName];
}

void
ContextManager::SetOperationContext(RunContext *&aRunContext) {
    this->mpCurrentContext = aRunContext;
}

RunContext *
ContextManager::GetOperationContext() {
    if (mpInstance == nullptr) {
        ContextManager::GetInstance();
    }
    if (mpInstance->mpCurrentContext == nullptr) {
        throw std::runtime_error("No current operation context available");
    }
    return mpInstance->mpCurrentContext;
}

RunContext *
ContextManager::CreateRunContext(const std::string &aRunContextName) {
    auto run_context = new RunContext();
    mpInstance->mContexts[aRunContextName] = run_context;
    return run_context;
}

void ContextManager::DeleteRunContext(const std::string &aRunContextName) {
    auto it = mContexts.find(aRunContextName);
    if (this->mpCurrentContext == this->GetContext(aRunContextName)) {
        if (aRunContextName == "default") {
            std::cerr << "[RCOMPSs GPU] WARNING: Cannot delete default RunContext" << std::endl;
            return;
        } else {
            auto default_context = this->GetContext("default");
            this->SetOperationContext(default_context);
        }
    }
    if (it == mContexts.end()) {
        throw std::runtime_error("No stream with that name: " + aRunContextName);
    }
    auto deleted_context = this->GetContext(aRunContextName);
    if (!deleted_context) {
        throw std::runtime_error("Failed to retrieve context: " + aRunContextName);
    }
    auto erase = mpInstance->mContexts.find(aRunContextName);
    if (erase != mpInstance->mContexts.end()) {
        mpInstance->mContexts.erase(erase);
    }
    delete deleted_context;
}

RunContext *
ContextManager::GetGPUContext() {
#ifdef USE_CUDA
    if (mpInstance == nullptr) {
        ContextManager::GetInstance();
    }
    if (mpInstance->mpGPUContext == nullptr) {
        throw std::runtime_error("No current GPU operation context available");
    }
    return mpInstance->mpGPUContext;
#else
    throw std::runtime_error("Code is compiled without CUDA support");
#endif
}

std::vector<std::string>
ContextManager::GetAllContextNames() const {
    std::vector<std::string> contextNames;
    for (auto it = mContexts.begin(); it != mContexts.end(); ++it) {
        contextNames.push_back(it->first);
    }
    return contextNames;
}

