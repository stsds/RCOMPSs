#!/usr/bin/env bash

###############################################################################
# install_rcompss.sh — Automated RCOMPSs installation for Ubuntu 22
#
# Usage:
#   ./install_rcompss.sh [OPTIONS] [INSTALL_DIR]
#
# Options:
#   --help, -h           Show this help message
#   --no-bashrc          Don't modify ~/.bashrc (print env block instead)
#   --source-dir DIR     Use an already-extracted COMPSs source directory
#                        instead of downloading the tarball
#   --r-libs DIR         Path to R user library directory
#                        (default: auto-detected from ~/R/)
#
# Arguments:
#   INSTALL_DIR   Where COMPSs will be installed
#                 (default: $HOME/COMPSs_installation)
#
# Prerequisites:
#   - A JDK must be available (JAVA_HOME set, or load a JDK module first)
#   - Gradle is recommended (load a gradle module or install it)
#
# Steps performed:
#   1. Verify JAVA_HOME and Gradle
#   2. Set Extrae MPI headers
#   3. Download & extract COMPSs (or use --source-dir)
#   4. Run COMPSs install with R binding enabled
#   5. Apply Ubuntu 22 JVM fix (processReaperUseDefaultStackSize)
#   6. Setup passwordless SSH to localhost
#   7. Disable .bashrc interactive guard (required for SSH workers)
#   8. Write RCOMPSs environment to .bashrc (unless --no-bashrc)
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $*"; }
step()  { echo -e "\n${CYAN}=== Step $1: $2 ===${NC}"; }

main() {

  local TARBALL_NAME="COMPSs_3.3.3_Trunk.tar.gz"
  local TARBALL_URL="https://compss.bsc.es/~fconejer/${TARBALL_NAME}"
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local INSTALL_DIR=""
  local MODIFY_BASHRC=true
  local SOURCE_DIR=""
  local R_LIBS_SYSTEM=""

  #############################################################################
  # Parse arguments
  #############################################################################
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        sed -n '4,/^###/{ /^###/d; s/^# \{0,1\}//; p }' "${BASH_SOURCE[0]}"
        return 0
        ;;
      --no-bashrc)    MODIFY_BASHRC=false; shift ;;
      --source-dir)   SOURCE_DIR="$2"; shift 2 ;;
      --source-dir=*) SOURCE_DIR="${1#*=}"; shift ;;
      --r-libs)       R_LIBS_SYSTEM="$2"; shift 2 ;;
      --r-libs=*)     R_LIBS_SYSTEM="${1#*=}"; shift ;;
      -*)             fail "Unknown option: $1. Use --help for usage."; return 1 ;;
      *)
        if [ -z "${INSTALL_DIR}" ]; then
          INSTALL_DIR="$1"
        else
          fail "Unexpected argument: $1. Use --help for usage."; return 1
        fi
        shift
        ;;
    esac
  done

  INSTALL_DIR="${INSTALL_DIR:-${HOME}/COMPSs_installation}"
  local BASHRC="${HOME}/.bashrc"
  local RCOMPSS_MARKER="# ── RCOMPSs environment"

  info "Installation target: ${INSTALL_DIR}"
  info "Modify .bashrc:      ${MODIFY_BASHRC}"
  [ -n "${SOURCE_DIR}" ] && info "Source directory:     ${SOURCE_DIR}"

  #############################################################################
  # Step 1: Verify JAVA_HOME and Gradle
  #############################################################################
  step 1 "Checking prerequisites"

  if [ -z "${JAVA_HOME:-}" ] || [ ! -x "${JAVA_HOME}/bin/java" ]; then
    fail "JAVA_HOME is not set or does not point to a valid JDK."
    fail "Please load a JDK module or export JAVA_HOME before running this script."
    fail "  Example:  module load openjdk/11   (check 'module avail' for your system)"
    fail "  Example:  export JAVA_HOME=/path/to/jdk"
    return 1
  fi
  info "JAVA_HOME=${JAVA_HOME}"
  export JAVA_HOME

  if command -v gradle &>/dev/null; then
    info "Gradle: $(gradle --version 2>/dev/null | grep '^Gradle ' | head -1)"
  else
    warn "Gradle not found."
    warn "  Example:  module load gradle   (check 'module avail' for your system)"
  fi

  #############################################################################
  # Step 2: Set MPI headers for Extrae
  #############################################################################
  step 2 "Setting Extrae MPI headers"

  export EXTRAE_MPI_HEADERS=/usr/include/x86_64-linux-gnu/mpi
  info "EXTRAE_MPI_HEADERS=${EXTRAE_MPI_HEADERS}"

  #############################################################################
  # Step 3: Obtain COMPSs source
  #############################################################################
  step 3 "Obtaining COMPSs source"

  if [ -n "${SOURCE_DIR}" ]; then
    if [ ! -d "${SOURCE_DIR}" ]; then
      fail "Source directory does not exist: ${SOURCE_DIR}"; return 1
    fi
    if [ ! -f "${SOURCE_DIR}/install" ]; then
      fail "No 'install' script found in ${SOURCE_DIR}. Is this a COMPSs source dir?"; return 1
    fi
    info "Using existing source directory: ${SOURCE_DIR}"
  else
    local TARBALL=""
    local loc
    for loc in "${SCRIPT_DIR}/${TARBALL_NAME}" "${HOME}/${TARBALL_NAME}"; do
      if [ -f "${loc}" ]; then
        TARBALL="${loc}"
        info "Tarball found at ${TARBALL}"
        break
      fi
    done

    if [ -z "${TARBALL}" ]; then
      TARBALL="${SCRIPT_DIR}/${TARBALL_NAME}"
      info "Downloading ${TARBALL_URL} ..."
      wget -q --show-progress "${TARBALL_URL}" -O "${TARBALL}"
    fi

    info "Extracting tarball into ${SCRIPT_DIR} ..."
    tar xzf "${TARBALL}" -C "${SCRIPT_DIR}"

    SOURCE_DIR="${SCRIPT_DIR}/COMPSs"
    if [ ! -d "${SOURCE_DIR}" ]; then
      fail "Could not find COMPSs directory in ${SCRIPT_DIR}"; return 1
    fi
    info "Source directory: ${SOURCE_DIR}"
  fi

  #############################################################################
  # Step 4: Install COMPSs (R binding only)
  #############################################################################
  step 4 "Installing COMPSs"

  cd "${SOURCE_DIR}"
  info "Running: ./install --no-c-binding --no-python-binding --r-binding ${INSTALL_DIR}"
  ./install --no-c-binding --no-python-binding --r-binding "${INSTALL_DIR}"
  info "COMPSs installed successfully."

  #############################################################################
  # Step 5: Apply Ubuntu 22 JVM fix
  #############################################################################
  step 5 "Applying Ubuntu 22 JVM fix"

  local SETUP_SH="${INSTALL_DIR}/Runtime/scripts/system/runtime/compss_setup.sh"
  local JVM_FIX='-Djdk.lang.processReaperUseDefaultStackSize=true'

  if [ ! -f "${SETUP_SH}" ]; then
    warn "compss_setup.sh not found at ${SETUP_SH}; skipping JVM fix."
  else
    if grep -q "processReaperUseDefaultStackSize" "${SETUP_SH}"; then
      info "JVM fix already present in compss_setup.sh, skipping."
    else
      info "Applying JVM fix to compss_setup.sh ..."
      sed -i "/-XX:ThreadPriorityPolicy=0/a\\${JVM_FIX}" "${SETUP_SH}"
      if grep -q "processReaperUseDefaultStackSize" "${SETUP_SH}"; then
        info "JVM fix applied successfully."
      else
        warn "Could not apply JVM fix automatically. Please add the following"
        warn "line to ${SETUP_SH} inside the JVM options block:"
        warn "  ${JVM_FIX}"
      fi
    fi
  fi

  #############################################################################
  # Step 6: Check passwordless SSH to localhost
  #############################################################################
  step 6 "Checking passwordless SSH to localhost"

  if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no localhost true 2>/dev/null; then
    info "Passwordless SSH to localhost works."
  else
    warn "Passwordless SSH to localhost is NOT working."
    warn "COMPSs requires passwordless SSH to start workers. To fix it:"
    echo ""
    info "  1. Create .ssh directory (if it doesn't exist):"
    info "     mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    echo ""
    info "  2. Generate a key (if you don't have one):"
    info "     ssh-keygen -t ed25519 -N ''"
    echo ""
    info "  3. Authorize it:"
    info "     cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys"
    echo ""
    info "  4. Fix permissions:"
    info "     chmod 600 ~/.ssh/authorized_keys"
    echo ""
    info "  5. Test:"
    info "     ssh localhost whoami"
  fi

  #############################################################################
  # Step 7: Disable .bashrc interactive guard
  #############################################################################
  step 7 "Checking .bashrc interactive guard"

  if [ -f "${BASHRC}" ]; then
    if grep -q '^[[:space:]]*case \$- in' "${BASHRC}"; then
      info "Commenting out the interactive-shell early-return block in .bashrc ..."
      info "(This is required so SSH worker sessions can source the environment)"
      sed -i '/^[[:space:]]*case \$- in/,/^[[:space:]]*esac/{s/^/#/}' "${BASHRC}"
      info ".bashrc interactive guard disabled."
    else
      info "Interactive guard already disabled or not present."
    fi
  fi

  #############################################################################
  # Step 8: Write environment to .bashrc
  #############################################################################
  step 8 "Setting up RCOMPSs environment"

  local COMPSS_HOME="${INSTALL_DIR%/}"

  if [ -z "${R_LIBS_SYSTEM}" ]; then
    R_LIBS_SYSTEM=$(ls -1d "${HOME}"/R/x86_64-pc-linux-gnu-library/*/ 2>/dev/null | head -1)
    R_LIBS_SYSTEM="${R_LIBS_SYSTEM%/}"
  fi

  if [ -z "${R_LIBS_SYSTEM}" ]; then
    fail "No R user library found. Use --r-libs to specify it."; return 1
  fi
  if [ ! -d "${R_LIBS_SYSTEM}" ]; then
    fail "R library directory does not exist: ${R_LIBS_SYSTEM}"; return 1
  fi
  info "R user library path: ${R_LIBS_SYSTEM}"

  local ENV_BLOCK="${RCOMPSS_MARKER} ──────────────────────────────────────────────
export JAVA_HOME=${JAVA_HOME}

export COMPSS_HOME=${COMPSS_HOME}
source \${COMPSS_HOME}/compssenv

export R_LIBS_USER=${R_LIBS_SYSTEM}
export R_LIBS_USER=\${COMPSS_HOME}/Bindings/RCOMPSs/user_libs:\${R_LIBS_USER}

export LD_LIBRARY_PATH=\${COMPSS_HOME}/Bindings/bindings-common/lib:\${LD_LIBRARY_PATH:-}
export LD_LIBRARY_PATH=\${JAVA_HOME}/lib/server:\${LD_LIBRARY_PATH}
# ─────────────────────────────────────────────────────────────────────"

  if [ "${MODIFY_BASHRC}" = true ]; then
    if [ -f "${BASHRC}" ] && grep -qF "${RCOMPSS_MARKER}" "${BASHRC}"; then
      info "RCOMPSs environment block already in .bashrc, skipping."
    else
      echo "" >> "${BASHRC}"
      echo "${ENV_BLOCK}" >> "${BASHRC}"
      info "RCOMPSs environment added to ${BASHRC}"
    fi
  else
    echo ""
    info "Add the following lines to your .bashrc (or run them in your terminal):"
    echo ""
    echo "${ENV_BLOCK}"
    echo ""
  fi

  #############################################################################
  # Step 9: Set environment for this session
  #############################################################################
  info "Loading environment for current session..."
  export COMPSS_HOME="${COMPSS_HOME}"
  source "${COMPSS_HOME}/compssenv"
  export R_LIBS_USER="${COMPSS_HOME}/Bindings/RCOMPSs/user_libs:${R_LIBS_SYSTEM}"
  export LD_LIBRARY_PATH="${COMPSS_HOME}/Bindings/bindings-common/lib:${LD_LIBRARY_PATH:-}"
  export LD_LIBRARY_PATH="${JAVA_HOME}/lib/server:${LD_LIBRARY_PATH}"

  #############################################################################
  # Done
  #############################################################################
  echo ""
  echo -e "${GREEN}============================================${NC}"
  echo -e "${GREEN}  RCOMPSs installation complete!${NC}"
  echo -e "${GREEN}  COMPSS_HOME = ${COMPSS_HOME}${NC}"
  echo -e "${GREEN}============================================${NC}"
  echo ""
  if [ "${MODIFY_BASHRC}" = true ]; then
    info "Open a new terminal (or run 'source ~/.bashrc') to activate the environment."
  fi
  info "To verify, run:  runcompss --version"
  info "To test, run:    cd ${SOURCE_DIR}/Bindings/RCOMPSs/examples/addition && runcompss --lang=r addition.R"
  echo ""
}

main "$@"
