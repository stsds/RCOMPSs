#include "executor/ExecutorCore.hpp"

#include <cstdlib>
#include <iostream>

int main(int argc, char** argv) {
  if (argc < 4) {
    std::cerr << "Usage: rcompss_executor <input_fifo> <output_fifo> <executor_id>\n";
    return 1;
  }

  std::string input_fifo = argv[1];
  std::string output_fifo = argv[2];
  int executor_id = std::atoi(argv[3]);

  rcompss::executor::ExecutorCore core(input_fifo, output_fifo, executor_id);
  return core.run();
}


