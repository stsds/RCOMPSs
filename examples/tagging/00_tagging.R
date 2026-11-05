library(data.table);library(R.utils);library(quanteda);library(toOrdinal);library(arrow);library(dplyr)

library(RCOMPSs)
compss_start()
source("tasks_00_tagging.R")

task.ftagging <- task(ftagging, "tasks_00_tagging.R", info_only=FALSE, return_value=FALSE, DEBUG=FALSE)

## edit for testing
base_dir <- "/gpfs/scratch/bsc19/bsc021292/project_SocialSciences/"
input_path <- file.path(base_dir, "/test_data/")
output_path <- file.path(base_dir, "/workflow/00_tagging/outputs/")
dict_path <- file.path(base_dir, "/test_data/dictionary_test.RDS")

dir.create(output_path, recursive = TRUE, showWarnings = FALSE)

allfiles <- list.files(input_path, pattern = "\\.parquet$")

for(year in 1960:2021){
  files <- grep(as.character(year), allfiles, value=T)
  file_paths <- file.path(input_path, files)
  
  for(file in file_paths) {
    task.ftagging(file, dict_path, output_path)
  }
  
  print(paste("Year:", year, "- Time: ", Sys.time()))
}

compss_stop()

outputs <- list.files(output_path, pattern = "\\.RDS$")
print(paste("Total files processed:", length(outputs)))
