#!/usr/bin/env bash

#####################################################################
# Name:         install.sh
# Description:  COMPSs' R binding building script.
#               Used by COMPSs to install the R language support within
#               the COMPSs installation folder.
# Parameters:
#   --compss-home  COMPSs installation to use (optional)
#   target_dir     Target directory where to install the R binding
#   tracing        Boolean to compile with Extrae
######################################################################

#---------------------------------------------------
# SCRIPT CONSTANTS DECLARATION
#---------------------------------------------------

INCORRECT_TARGET_DIR="Error: No target directory"
INCORRECT_PARAMETER="Error: Invalid parameter"
INCORRECT_COMPSS_HOME="Error: Invalid COMPSs installation directory"
INCORRECT_COMPSS_SOURCE="Error: Invalid COMPSs source directory"
COMPSS_REPOSITORY="https://github.com/bsc-wdc/compss.git"

#---------------------------------------------------
# SET SCRIPT VARIABLES
#---------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDING_DIR="$(dirname "${SCRIPT_DIR}")"

#---------------------------------------------------
# FUNCTIONS DECLARATION
#---------------------------------------------------

show_opts() {
  cat <<EOT
* Options:
    --help, -h                  Print this help message
    --opts                      Show available options
    --compss-home <path>        COMPSs installation to use
    --compss-source <path>      Clone and build COMPSs from source at this path
    --compss-version <ref>      COMPSs branch or tag to clone
    --compss-repo <url>         COMPSs repository URL (default: ${COMPSS_REPOSITORY})

* Parameters:
    target_dir                  COMPSs' R Binding installation directory
    tracing                     If compile with Extrae (true|false)

EOT
}

usage() {
  exitValue=$1

  cat <<EOT
Usage: $0 [options] target_dir tracing
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
  local positional_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
    -h|--help)
      usage 0
      ;;
    --opts)
      show_opts
      exit 0
      ;;
    --compss-home)
      if [ $# -lt 2 ]; then
        display_error "${INCORRECT_COMPSS_HOME}"
      fi
      compss_home=$2
      shift 2
      ;;
    --compss-source)
      if [ $# -lt 2 ]; then
        display_error "${INCORRECT_COMPSS_SOURCE}"
      fi
      compss_source=$2
      shift 2
      ;;
    --compss-version)
      if [ $# -lt 2 ]; then
        display_error "${INCORRECT_PARAMETER}: --compss-version requires a branch or tag"
      fi
      compss_version=$2
      shift 2
      ;;
    --compss-repo)
      if [ $# -lt 2 ]; then
        display_error "${INCORRECT_PARAMETER}: --compss-repo requires a URL"
      fi
      compss_repository=$2
      shift 2
      ;;
    --)
      shift
      positional_args+=("$@")
      break
      ;;
    -*)
      display_error "${INCORRECT_PARAMETER}: $1"
      ;;
    *)
      positional_args+=("$1")
      shift
      ;;
    esac
  done

  if [ ${#positional_args[@]} -ne 2 ]; then
    display_error "${INCORRECT_TARGET_DIR}"
  fi

  target_dir=${positional_args[0]}
  tracing=${positional_args[1]}

  if [ -z "${compss_home}" ]; then
    compss_home="${target_dir}/../../"
  fi
  compss_home=${compss_home%/}

  if [ -n "${compss_source}" ] && [ -z "${compss_version}" ]; then
    display_error "${INCORRECT_PARAMETER}: --compss-source requires --compss-version"
  fi
  if [ -z "${compss_source}" ] && [ -n "${compss_version}" ]; then
    display_error "${INCORRECT_PARAMETER}: --compss-version requires --compss-source"
  fi
  if [ -z "${compss_source}" ] && [ -n "${compss_repository}" ]; then
    display_error "${INCORRECT_PARAMETER}: --compss-repo requires --compss-source"
  fi
}

validate_compss_home() {
  if [ ! -d "${compss_home}/Bindings/bindings-common/include" ] || \
    [ ! -d "${compss_home}/Bindings/bindings-common/lib" ] || \
    [ ! -d "${compss_home}/Runtime/scripts/system/adaptors/nio/pipers" ]; then
    display_error "${INCORRECT_COMPSS_HOME}: ${compss_home}"
  fi
}

clone_and_build_compss() {
  precheck_compss_build_dependencies

  if [ -e "${compss_source}" ]; then
    display_error "${INCORRECT_COMPSS_SOURCE}: ${compss_source} already exists"
  fi
  if [ -e "${compss_home}" ]; then
    display_error "${INCORRECT_COMPSS_HOME}: ${compss_home} already exists"
  fi
  if ! command_exists git; then
    display_error "Error: git is required to clone COMPSs"
  fi

  local repository=${compss_repository:-${COMPSS_REPOSITORY}}
  echo "INFO: Cloning COMPSs ${compss_version} from ${repository}"
  git clone --branch "${compss_version}" --depth 1 --recurse-submodules "${repository}" "${compss_source}" || exit $?
  (
    cd "${compss_source}" || exit 1
    ./submodules_get.sh && cd builders && ./buildlocal "${compss_home}"
  ) || exit $?
}

precheck_compss_build_dependencies() {
  local missing_dependencies=()
  local required_command

  for required_command in R Rscript git wget mvn java javac make gcc g++ autoreconf libtoolize python3; do
    if ! command_exists "${required_command}"; then
      missing_dependencies+=("${required_command}")
    fi
  done

  if [ -z "${JAVA_HOME}" ]; then
    missing_dependencies+=("JAVA_HOME (must point to a JDK)")
  elif [ ! -x "${JAVA_HOME}/bin/java" ] || [ ! -x "${JAVA_HOME}/bin/javac" ]; then
    missing_dependencies+=("JAVA_HOME/bin/java and JAVA_HOME/bin/javac")
  fi

  if [ ${#missing_dependencies[@]} -ne 0 ]; then
    echo "ERROR: Cannot build COMPSs; install or configure these dependencies first:" >&2
    printf '  - %s\n' "${missing_dependencies[@]}" >&2
    show_dependency_guidance >&2
    exit 1
  fi
}

precheck_rcompss_dependencies() {
  local missing_dependencies=()
  local required_command

  for required_command in R Rscript make gcc g++ java javac; do
    if ! command_exists "${required_command}"; then
      missing_dependencies+=("${required_command}")
    fi
  done

  if [ -z "${JAVA_HOME}" ]; then
    missing_dependencies+=("JAVA_HOME (must point to a JDK)")
  elif [ ! -x "${JAVA_HOME}/bin/java" ] || [ ! -x "${JAVA_HOME}/bin/javac" ]; then
    missing_dependencies+=("JAVA_HOME/bin/java and JAVA_HOME/bin/javac")
  fi

  if [ ${#missing_dependencies[@]} -ne 0 ]; then
    echo "ERROR: Cannot install RCOMPSs; install or configure these dependencies first:" >&2
    printf '  - %s\n' "${missing_dependencies[@]}" >&2
    show_dependency_guidance >&2
    exit 1
  fi
}

show_dependency_guidance() {
  cat <<'EOT'
Install the missing capabilities with your system's package manager. Package names vary by distribution; look for the R development package, a JDK, a C/C++ build toolchain, Maven, Autotools, Libtool, and the listed command-line tools. This script does not install system packages automatically.
EOT
}

log_parameters() {
  echo "PARAMETERS:"
  echo "- COMPSs home = ${compss_home}"
  if [ -n "${compss_source}" ]; then
    echo "- COMPSs source = ${compss_source}"
    echo "- COMPSs version = ${compss_version}"
  fi
  echo "- Target directory = ${target_dir}"
  echo "- Tracing = ${tracing}"
  sleep 5
}

#---------------------------------------------------
# HELPER FUNCTIONS
#---------------------------------------------------

command_exists() {
  type "$1" &>/dev/null
}

clean() {
  echo "Cleaning R-binding files"
}

install() {
  local target_directory=$1
  local tracing=$2
  local compss_home=$3

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
    echo "PKG_CPPFLAGS=${pkg_cppflags} -I${compss_home}/Dependencies/extrae/include -pthread" >${SCRIPT_DIR}/src/Makevars
    echo "PKG_LIBS=${pkg_libs} -L${compss_home}/Dependencies/extrae/lib -lpttrace" >>${SCRIPT_DIR}/src/Makevars
    export LD_LIBRARY_PATH=${compss_home}/Dependencies/extrae/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=${compss_home}/Dependencies/extrae/include:$LD_LIBRARY_PATH
  else
    # Add dummy extrae path
    echo "PKG_CPPFLAGS=${pkg_cppflags} -I${compss_home}/Bindings/RCOMPSs/dummy_extrae -pthread" >${SCRIPT_DIR}/src/Makevars
    echo "PKG_LIBS=${pkg_libs} -L${compss_home}/Bindings/RCOMPSs/dummy_extrae -lpttrace" >>${SCRIPT_DIR}/src/Makevars
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
  Rscript -e "install.packages(\"https://cran.r-project.org/src/contrib/Archive/lobstr/lobstr_1.1.3.tar.gz\", repos = NULL, type = \"source\", lib=\"${target_r_directory}\")"
  Rscript -e "install.packages(\"https://cran.r-project.org/src/contrib/Archive/pryr/pryr_0.1.6.tar.gz\", repos = NULL, type = \"source\", lib=\"${target_r_directory}\")"
  Rscript -e "list.of.packages <- c(\"Rcpp\", \"RMVL\", \"proxy\", \"lubridate\", \"doParallel\", \"foreach\", \"fields\"); new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,\"Package\"])]; if(length(new.packages)) install.packages(new.packages, repos=\"http://cran.r-project.org\", lib=\"${target_r_directory}\")"

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
  cp ${SCRIPT_DIR}/aux/piper_worker.R ${compss_home}/Runtime/scripts/system/adaptors/nio/pipers/
  cp ${SCRIPT_DIR}/aux/r_piper.sh ${compss_home}/Runtime/scripts/system/adaptors/nio/pipers/

  # Clean unnecessary files
  echo "INFO: Cleaning unnecessary files..."
}

#---------------------------------------------------
# MAIN INSTALLATION FUNCTION
#---------------------------------------------------

install_r_binding() {
  # Add trap for clean
  trap clean EXIT

  echo "INFO: Starting R binding installation"

  # Install
  install "${target_dir}" "${tracing}" "${compss_home}"

  echo "INFO: Finished R binding installation"
}

#---------------------------------------------------
# MAIN EXECUTION
#---------------------------------------------------

get_args "$@"
if [ -n "${compss_source}" ]; then
  clone_and_build_compss
else
  precheck_rcompss_dependencies
fi
validate_compss_home
log_parameters
install_r_binding

# END
echo "INFO: SUCCESS: R binding installed"
# Normal exit
exit 0
