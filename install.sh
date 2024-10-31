#!/usr/bin/env bash

#####################################################################
# Name:         install.sh
# Description:  COMPSs' R binding building script.
# Parameters:
#		target_dir  Target directory where to install the R binding
#   tracing     Boolean to compile with Extrae
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
    tracing                     If compile with Extrae (true|false)

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
  if [ $# -gt 1 ]; then
    target_dir=$1
    tracing=$2
  else
    display_error "${INCORRECT_TARGET_DIR}"
    exit 1
  fi
  shift 1
}

log_parameters() {
  echo "PARAMETERS:"
  echo "- Target directory = ${target_dir}"
  echo "- Tracing = ${tracing}"
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
  local tracing=$2
  local compss_home="$1/../../"

  echo "INFO: Installation parameters:"
  echo "      - Current script directory: ${SCRIPT_DIR}"
  echo "      - JAVA_HOME: ${JAVA_HOME}"
  echo "      - compss_home: ${compss_home}"
  echo "      - Target directory: ${target_directory}"
  echo "      - Tracing: ${tracing}"

  # Do the installation
  echo "INFO: Starting the installation... Please wait..."

  # Deploy dummy extrae
  mkdir -p ${compss_home}/Bindings/RCOMPSs
  cp -r ${SCRIPT_DIR}/aux/dummy_extrae/ ${compss_home}/Bindings/RCOMPSs/.
  # Compile dummy extrae
  ${compss_home}/Bindings/RCOMPSs/dummy_extrae/./compile.sh

  pkg_cppflags="-I${compss_home}/Bindings/bindings-common/include -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux -I${JAVA_HOME}/jre/include -I${JAVA_HOME}/jre/include/linux"
  pkg_libs="-L${compss_home}/Bindings/bindings-common/lib -lbindings_common"
  if [ "${tracing}" == "true" ]; then
    # Add extrae path
    echo "PKG_CPPFLAGS=${pkg_cppflags} -I${compss_home}/Dependencies/extrae/include -pthread" > ${SCRIPT_DIR}/src/Makevars
    echo "PKG_LIBS=${pkg_libs} -L${compss_home}/Dependencies/extrae/lib -lpttrace" >> ${SCRIPT_DIR}/src/Makevars
    export LD_LIBRARY_PATH=${compss_home}/Dependencies/extrae/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=${compss_home}/Dependencies/extrae/include:$LD_LIBRARY_PATH
  else
    # Add dummy extrae path
    echo "PKG_CPPFLAGS=${pkg_cppflags} -I${compss_home}/Bindings/RCOMPSs/dummy_extrae -pthread" > ${SCRIPT_DIR}/src/Makevars
    echo "PKG_LIBS=${pkg_libs} -L${compss_home}/Bindings/RCOMPSs/dummy_extrae -lpttrace" >> ${SCRIPT_DIR}/src/Makevars
    export LD_LIBRARY_PATH=${compss_home}/Bindings/RCOMPSs/dummy_extrae:$LD_LIBRARY_PATH
  fi

  export LD_LIBRARY_PATH=${compss_home}/Bindings/bindings-common/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=${compss_home}/Bindings/bindings-common/include:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${JAVA_HOME}/lib/amd64/server:${JAVA_HOME}/jre/lib/amd64/server
  # Update the paths on config_RCOMPSs.sh (for now we ignore path to libRblas.so  libRlapack.so
  current_dir=$(pwd)
  cd ..

  # Install Rcpp, RMVL, pryr, proxy packages on R if not installed
  target_r_directory="${target_directory}/user_libs"
  mkdir -p ${target_r_directory}
  Rscript -e "list.of.packages <- c(\"Rcpp\", \"RMVL\", \"pryr\", \"proxy\", \"lubridate\"); new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,\"Package\"])]; if(length(new.packages)) install.packages(new.packages, repos=\"http://cran.r-project.org\", lib=\"${target_r_directory}\")"

  # Build RCOMPSs
  R CMD build RCOMPSs

  # Install RCOMPSs
  R CMD INSTALL -l ${target_r_directory} --no-test-load RCOMPSs_1.0.tar.gz
  exitCode=$?
  if [ $exitCode -ne 0 ]; then
    echo "ERROR: Cannot install RCOMPSs"
    exit $exitCode
  fi

  cd ${current_dir}

  # Deploy the RCOMPSs executor
  cp ${SCRIPT_DIR}/aux/executor.R ${compss_home}/Runtime/scripts/system/adaptors/nio/pipers/


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
  install "${target_dir}" "${tracing}"

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
