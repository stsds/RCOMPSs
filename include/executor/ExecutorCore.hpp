#ifndef RCOMPSs_EXECUTOR_CORE_HPP
#define RCOMPSs_EXECUTOR_CORE_HPP

#ifndef R_NO_REMAP
#define R_NO_REMAP
#endif
#include <Rcpp.h>
#ifdef length
#undef length
#endif
#include <fstream>
#include <memory>
#include <string>
#include <vector>

namespace rcompss {
namespace executor {

struct TaskMessage {
  std::string task_id;
  std::string sandbox;
  std::string job_out;
  std::string job_err;
  std::string tracing;
  std::string debug;
  std::string module;
  std::string func;
  std::vector<std::string> params;
  std::string cpus;  // CPU affinity (3rd from last in task line)
  std::string gpus;  // GPU affinity (2nd from last in task line)
};

class ExecutorCore {
public:
  ExecutorCore(const std::string& input_fifo_path,
               const std::string& output_fifo_path,
               int executor_id);
  ~ExecutorCore();

  int run();

private:
  void initR();
  void shutdownR();
  bool parseTaskMessage(const std::string& line, TaskMessage& message) const;
  bool executeTask(const TaskMessage& message, std::ofstream& output_fifo);
  Rcpp::List buildFunctionArgs(const std::vector<std::string>& params,
                               int& return_index,
                               int& num_returns) const;
  std::string stripValueSuffix(const std::string& raw_value) const;
  bool bindCpus(const std::string& cpus, std::ofstream& job_out, std::ofstream& job_err) const;
  void bindGpus(const std::string& gpus, std::ofstream& job_out, std::ofstream& job_err) const;

  std::string input_fifo_path_;
  std::string output_fifo_path_;
  int executor_id_;
  bool r_initialized_;

  std::unique_ptr<Rcpp::Environment> rcompss_ns_;
  std::unique_ptr<Rcpp::Environment> global_env_;
  std::unique_ptr<Rcpp::Function> source_func_;
  std::unique_ptr<Rcpp::Function> do_call_func_;
  std::unique_ptr<Rcpp::Function> compss_unserialize_;
  std::unique_ptr<Rcpp::Function> compss_serialize_;
};

}  // namespace executor
}  // namespace rcompss

#endif  // RCOMPSs_EXECUTOR_CORE_HPP

