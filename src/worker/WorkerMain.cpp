#include "worker/WorkerCore.hpp"

#include <iostream>
#include <string>
#include <utility>
#include <vector>

int main(int argc, char** argv) {
  if (argc < 3 || ((argc - 2) % 2 != 0)) {
    std::cerr << "Usage: rcompss_worker <script_dir> <cmd_pipe1> <result_pipe1> [<cmd_pipe2> <result_pipe2> ...]\n";
    return 1;
  }

  std::string script_dir = argv[1];
  std::vector<std::pair<std::string, std::string>> pipe_pairs;

  for (int i = 2; i + 1 < argc; i += 2) {
    pipe_pairs.emplace_back(argv[i], argv[i + 1]);
  }

  rcompss::worker::WorkerCore core(script_dir, pipe_pairs);
  return core.run();
}


