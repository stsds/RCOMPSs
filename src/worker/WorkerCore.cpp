#include "worker/WorkerCore.hpp"

#include <chrono>
#include <iostream>
#include <sys/wait.h>
#include <unistd.h>

#include "extrae.h"

namespace rcompss {
namespace worker {

WorkerCore::WorkerCore(
    const std::string& script_dir,
    const std::vector<std::pair<std::string, std::string>>& pipe_pairs)
    : script_dir_(script_dir), pipe_pairs_(pipe_pairs) {}

void WorkerCore::spawnExecutors() {
  executor_pids_.clear();
  executor_pids_.resize(pipe_pairs_.size(), -1);

  std::string executor_path = script_dir_ + "/rcompss_executor";
  if (access(executor_path.c_str(), X_OK) != 0) {
    std::perror("[C++ WORKER] rcompss_executor not executable");
    return;
  }

  for (size_t i = 0; i < pipe_pairs_.size(); ++i) {
    pid_t pid = fork();
    if (pid == 0) {
      const auto& cmd_pipe = pipe_pairs_[i].first;
      const auto& result_pipe = pipe_pairs_[i].second;
      std::string executor_id = std::to_string(static_cast<int>(i));

      execl(executor_path.c_str(),
            executor_path.c_str(),
            cmd_pipe.c_str(),
            result_pipe.c_str(),
            executor_id.c_str(),
            static_cast<char*>(nullptr));
      std::perror("[C++ WORKER] exec rcompss_executor failed");
      _exit(1);
    }
    if (pid > 0) {
      executor_pids_[i] = static_cast<int>(pid);
    }
  }
}

int WorkerCore::waitExecutors() {
  int failures = 0;
  for (int pid : executor_pids_) {
    if (pid <= 0) {
      continue;
    }
    int status = 0;
    if (waitpid(pid, &status, 0) == -1) {
      failures++;
      continue;
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) != 0) {
      std::cerr << "[C++ WORKER] Executor " << pid
                << " exited with status " << WEXITSTATUS(status) << "\n";
      failures++;
    } else if (WIFSIGNALED(status)) {
      std::cerr << "[C++ WORKER] Executor " << pid
                << " killed by signal " << WTERMSIG(status) << "\n";
      failures++;
    }
  }
  return failures;
}

int WorkerCore::run() {
  std::cout << "[C++ WORKER] Starting R Worker!" << std::endl;

  Extrae_init();
  Extrae_eventandcounters(8000666, 1);

  Extrae_eventandcounters(9090425, 1);
  spawnExecutors();
  Extrae_eventandcounters(9090425, 0);

  Extrae_eventandcounters(8000666, 0);
  auto now = std::chrono::system_clock::now();
  auto epoch_seconds =
      std::chrono::duration_cast<std::chrono::seconds>(now.time_since_epoch())
          .count();
  Extrae_eventandcounters(8000666, static_cast<unsigned>(epoch_seconds));
  Extrae_eventandcounters(8000666, 0);
  Extrae_flush();
  Extrae_fini();

  int failures = waitExecutors();
  if (failures != 0) {
    std::cerr << "[C++ WORKER] " << failures << " executor(s) failed" << std::endl;
  }
  return failures == 0 ? 0 : 1;
}

}  // namespace worker
}  // namespace rcompss


