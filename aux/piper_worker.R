# Copyright (c) 2025- King Abdullah University of Science and Technology,
# All rights reserved.
# RCOMPSs is a software package, provided by King Abdullah University of Science and Technology (KAUST) - STSDS Group.

# @file piper_worker.R
# @brief This file contains the code to start a R worker main process that spawns a set of executors (normally one per core).
# @version 1.0
# @author Xiran Zhang
# @date 2025-04-28

# ##################################### #
# ########## RCOMPSs WORKER ########### #
# ##################################### #

# Foreach is used to start the executors.
library(foreach)
# Preloading RCOMPSs to boost the executors
library(RCOMPSs)

LIBPATHS <- .libPaths()

time_since_epoch <- function() {
  x1 <- as.POSIXct(Sys.time())
  x2 <- format(x1, tz = "GMT", usetz = F)
  x3 <- lubridate::ymd_hms(x2)
  epoch <- lubridate::ymd_hms("1970-01-01 00:00:00")
  time_since_epoch <- (x3 - epoch) / lubridate::dseconds()
  return(time_since_epoch)
}

###############################################################
####################### MAIN R SCRIPT #########################
###############################################################
print("Starting R Worker!")

RCOMPSs::extrae_ini()
RCOMPSs::extrae_emit_event(8000666, 1) # Sync event: for adjusting the timing

# Get command-line arguments
args <- commandArgs(TRUE)
print(paste("Parameters:", paste(args, collapse = " ")))

args_list <- as.list(args)
current_path <- args_list[1]
args_list <- args_list[-1] # Remove current dir
source(paste(current_path, "executor.R", sep = "/"))

# Even positions - CMDpipes
even_positions <- seq(2, length(args_list), by = 2)
even_args <- args_list[even_positions]

# Odd positions - RESULTpipes
odd_positions <- seq(1, length(args_list), by = 2)
odd_args <- args_list[odd_positions]

pipe_pairs <- Map(c, odd_args, even_args)

# num_cores <- parallel::detectCores() / 2  # Use one all total cores
RCOMPSs::extrae_emit_event(9090425, 1)
num_cores <- length(pipe_pairs)
cl <- parallel::makeCluster(num_cores, outfile = "")
doParallel::registerDoParallel(cl)
pipe_pids <- integer(length(pipe_pairs))
foreach(position = 1:length(pipe_pairs), .verbose = FALSE, .combine = "c") %dopar% {
  RCOMPSs::extrae_emit_event(9090425, 2)
  pipe_pids[position] <- Sys.getpid()
  executor(pipe_pairs[[position]][1], pipe_pairs[[position]][2], position - 1)
  RCOMPSs::extrae_emit_event(9090425, 0)
}

RCOMPSs::extrae_emit_event(9090425, 0)

RCOMPSs::extrae_emit_event(8000666, 0) # Sync event: for adjusting the timing
RCOMPSs::extrae_emit_event(8000666, time_since_epoch()) # Sync event: for adjusting the timing
RCOMPSs::extrae_emit_event(8000666, 0) # Sync event: for adjusting the timing
RCOMPSs::extrae_flu()
RCOMPSs::extrae_fin()

parallel::stopCluster(cl)

###############################################################
###############################################################
###############################################################
