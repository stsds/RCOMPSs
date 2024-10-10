#!/usr/bin/env bash

#####################################################################
# Name:         install.sh
# Description:  COMPSs' R binding building script.
# Parameters:
#		target_dir  Target directory where to install the R binding
######################################################################



######################################################################

#---------------------------------------------------
# SCRIPT CONSTANTS DECLARATION
#---------------------------------------------------
INCORRECT_TARGET_DIR="Error: No target directory"


#---------------------------------------------------
# SET SCRIPT VARIABLES
#---------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINDING_DIR="$( dirname "${SCRIPT_DIR}")"


#---------------------------------------------------
# FUNCTIONS DECLARATION
#---------------------------------------------------
show_opts() {
  cat <<EOT
* Options:
    --help, -h                  Print this help message

    --opts                      Show available options

* Parameters:
    target_dir                  COMPSs' R Binding installation directory

EOT
}

usage() {
  exitValue=$1

  cat <<EOT
Usage: $0 target_dir
EOT
  show_opts
  exit "$exitValue"
}

# Displays arguments warnings
display_warning() {
  local warn_msg=$1
  echo "$warn_msg"
}

# Displays parsing arguments errors
display_error() {
  local error_msg=$1
  echo "$error_msg"

  echo " "
  usage 1
}

get_args() {
  # Parse COMPSs' Binding Options
  while getopts h-: flag; do
    # Treat the argument
    case "$flag" in
      h)
        # Display help
        usage 0
        ;;
      -)
        # Check more complex arguments
        case "$OPTARG" in
          help)
            # Display help
            usage 0
            ;;
          opts)
            # Display help
            show_opts
            exit 0
            ;;
          *)
            # Flag didn't match any pattern. End of COMPSs' R Binding flags
            display_error "${INCORRECT_PARAMETER}"
            break
            ;;
        esac
        ;;
      *)
        # Flag didn't match any pattern. End of COMPSs flags
        display_error "${INCORRECT_PARAMETER}"
        break
        ;;
    esac
  done
  # Shift option arguments
  shift $((OPTIND-1))

  # Parse target directory location
  if [ $# -gt 0 ]; then
    target_dir=$1
  else
    display_error "${INCORRECT_TARGET_DIR}"
    exit 1
  fi
  shift 1
}

log_parameters() {
  echo "PARAMETERS:"
  echo "- Target directory = ${target_dir}"
  sleep 5
}

#---------------------------------------------------
# HELPER FUNCTIONS
#---------------------------------------------------

command_exists () {
  type "$1" &> /dev/null ;
}

clean() {
  echo "Cleaning R-binding files"
}

install () {
  local target_directory=$1

  echo "INFO: Installation parameters:"
  echo "      - Current script directory: ${SCRIPT_DIR}"
  echo "      - JAVA_HOME: ${JAVA_HOME}"
  echo "      - COMPSS_HOME: ${COMPSS_HOME}"
  echo "      - Target directory: ${target_directory}"

  # Do the installation
  echo "INFO: Starting the installation... Please wait..."

  echo "PKG_CPPFLAGS=-I${COMPSS_HOME}/Bindings/bindings-common/include -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux -I${JAVA_HOME}/jre/include -I${JAVA_HOME}/jre/include/linux" > ${SCRIPT_DIR}/src/Makevars
  echo "PKG_LIBS=-L${COMPSS_HOME}/Bindings/bindings-common/lib -lbindings_common" >> ${SCRIPT_DIR}/src/Makevars

  export LD_LIBRARY_PATH=${COMPSS_HOME}/Bindings/bindings-common/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=${COMPSS_HOME}/Bindings/bindings-common/include:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${JAVA_HOME}/lib/amd64/server:${JAVA_HOME}/jre/lib/amd64/server
  # Update the paths on config_RCOMPSs.sh (for now we ignore path to libRblas.so  libRlapack.so
  current_dir=$(pwd)
  cd ..
  R CMD build RCOMPSs

  target_r_directory="${target_directory}/user_libs"
  mkdir -p ${target_r_directory}

  # Install Rcpp, RMVL, pryr, proxy packages on R if not installed
  Rscript -e "list.of.packages <- c(\"Rcpp\", \"RMVL\", \"pryr\", \"proxy\"); new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,\"Package\"])]; if(length(new.packages)) install.packages(new.packages, repos=\"http://cran.r-project.org\", lib=\"${target_r_directory}\")"

  # Install RCOMPSs
  R CMD INSTALL -l ${target_r_directory} RCOMPSs_1.0.tar.gz
  exitCode=$?
  if [ $exitCode -ne 0 ]; then
    echo "ERROR: Cannot install RCOMPSs"
    exit $exitCode
  fi

  cd ${current_dir}

  # Deploy the RCOMPSs executor
  cp ${SCRIPT_DIR}/aux/executor.R ${COMPSS_HOME}/Runtime/scripts/system/adaptors/nio/pipers/


  # Clean unnecessary files
  echo "INFO: Cleaning unnecessary files..."

}


#---------------------------------------------------
# MAIN INSTALLATION FUNCTION
#---------------------------------------------------

install_r_binding () {
  # Add trap for clean
  trap clean EXIT

  echo "INFO: Starting R binding installation"

  # Install
  install "${target_dir}"

  echo "INFO: Finished R binding installation"
}

#---------------------------------------------------
# MAIN EXECUTION
#---------------------------------------------------
get_args "$@"
log_parameters
install_r_binding

# END
echo "INFO: SUCCESS: R binding installed"
# Normal exit
exit 0
