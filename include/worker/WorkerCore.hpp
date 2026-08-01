#ifndef RCOMPSs_WORKER_CORE_HPP
#define RCOMPSs_WORKER_CORE_HPP

#include <string>
#include <utility>
#include <vector>

namespace rcompss {
namespace worker {

class WorkerCore {
public:
  WorkerCore(const std::string& script_dir,
             const std::vector<std::pair<std::string, std::string>>& pipe_pairs);

  int run();

private:
  void spawnExecutors();
  int waitExecutors();

  std::string script_dir_;
  std::vector<std::pair<std::string, std::string>> pipe_pairs_;
  std::vector<int> executor_pids_;
};

}  // namespace worker
}  // namespace rcompss

#endif  // RCOMPSs_WORKER_CORE_HPP


