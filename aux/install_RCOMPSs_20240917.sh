#!/bin/bash
set -e  # Exit on error
set -u  # Treat unset variables as an error

###############################################
# Define colors
###############################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'  # Reset color

###############################################
# Function to prompt for yes or no
###############################################
ask_yes_no() {
  while true; do
    read -p "$1 (y/n): " choice
    case "$choice" in
      y|Y ) return 0;;  # Return true for yes
      n|N ) return 1;;  # Return false for no
      * ) echo "Please answer y or n.";;  # Handle invalid input
    esac
  done
}


echo -e "${YELLOW}==============================================${RESET}"
echo -e "${YELLOW}[0] Set passwordless connection to localhost  ${RESET}"
echo -e "${YELLOW}==============================================${RESET}"
if ssh -o BatchMode=yes localhost true; then
  echo -e "${BLUE}[0:1] SSH connection successful without password.${RESET}\n\n"
else
  echo -e "${RED}[0:2] SSH connection requires a password! Please make sure that you can passwordless connection to localhost!${RESET}"
  exit 3
fi


###############################################
# Get the flags
###############################################
echo -e "${YELLOW}***********************************************${RESET}"
echo -e "${YELLOW}***********************************************${RESET}"
echo -e "${YELLOW}*************START TO INSTALL RCOMPSs**********${RESET}"
echo -e "${YELLOW}***********************************************${RESET}"
echo -e "${YELLOW}***********************************************${RESET}"
if [ -d "RCOMPSs" ]; then
  if ask_yes_no "[0:3] Do you want to reinstall RCOMPSs from scratch?"; then
    rm -rf RCOMPSs
    mkdir RCOMPSs
  fi
else
  mkdir RCOMPSs
fi
cd RCOMPSs
echo -e "${YELLOW}PATH: $PWD${RESET}"

cat <<EOT
* Options:
  --help, -h                 Print this help message
  --Shaheen3                 Install on Shaheen-III
  --ECRC                     Install on ECRC servers
EOT
echo -e "\n\n"


echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}             [1] Set the base PATH           ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
if [ -e "config.sh" ]; then
  echo -e "${BLUE}[1:1] config.sh already exists and the content is:${RESET}\n"
  cat config.sh
  echo -e "\n${BLUE}[1:2] End of config.sh${RESET}"
fi
# source /home/zhanx0q/RCOMPSs/COMPSs_installation/compssenv
source /etc/profile.d/modules.sh
source /etc/profile.d/modules-ecrc.sh
export JAVA_TOOL_OPTIONS=-Xss4m
cat <<EOT > config.sh
source /etc/profile.d/modules.sh
source /etc/profile.d/modules-ecrc.sh
export JAVA_TOOL_OPTIONS=-Xss4m
EOT
export SETUP_DIR=$PWD
echo "export SETUP_DIR=$PWD" >> $SETUP_DIR/config.sh
if [ ! -d "dependencies" ]; then
  mkdir "dependencies"
  echo -e "${BLUE}[1:3] Directory 'dependencies' created.${RESET}"
else
  echo -e "${BLUE}[1:4] Directory 'dependencies' already exists.${RESET}"
fi
export DEPEN_DIR=$PWD/dependencies
echo "export DEPEN_DIR=$DEPEN_DIR" >> $SETUP_DIR/config.sh
echo -e "${BLUE}[1:5] DEPEN_DIR=$DEPEN_DIR${RESET}"
echo -e "${BLUE}[1:END] Finished Setting the base PATH${RESET}\n\n"


echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}           [2] Check R and R libs            ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
AVAIL_R_PATH=false
if command -v Rscript > /dev/null 2>&1; then
  R_LIBS_USER=$(Rscript -e "cat(.libPaths(), sep = ':')")
  echo -e "${BLUE}[2:1] R library paths: ${GREEN}$R_LIBS_USER${RESET}"

  IFS=':' read -r -a paths <<< "$R_LIBS_USER"
  for path in "${paths[@]}"; do
    if [ -w "$path" ]; then
      echo -e "${BLUE}[2:2] ${GREEN}$path${BLUE} is writable${RESET}"
      LOCAL_R_PATH=$path
      AVAIL_R_PATH=true
      break
    else
      echo -e "${BLUE}[2:3] ${GREEN}$path${BLUE} is not writable${RESET}"
    fi
  done
else
  echo -e "${RED}[2:4] No R module found!${RESET}"
  exit 1
fi
if [[ "$AVAIL_R_PATH" == false ]]; then
  LOCAL_R_PATH=$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))")
  if [ -d $R_LIBS_USER ]; then
    R_LIBS_USER=$R_LIBS_USER:$LOCAL_R_PATH
  else
    if ask_yes_no "[2:5] Do you want to create a local R library folder at $LOCAL_R_PATH?"; then
      R_LIBS_USER=$R_LIBS_USER:$LOCAL_R_PATH
      mkdir $LOCAL_R_PATH
    else
      echo -e "${RED}[2:6] No writable R paths!${RESET}"
      exit 2
    fi
  fi
fi
R_VERSION=$(Rscript -e 'cat(paste0(sessionInfo()$R.version$major, ".", sessionInfo()$R.version$minor))')
echo -e "${BLUE}[2:7] R version specified: $R_VERSION${RESET}"
export R_LIBS_USER=$R_LIBS_USER
echo "export R_LIBS_USER=$R_LIBS_USER" >> $SETUP_DIR/config.sh
echo -e "${BLUE}[2:8] R lib: $R_LIBS_USER${RESET}\n\n"
echo "\# Installing into R - $R_VERSION" >> $SETUP_DIR/config.sh
  module load gcc
module load mkl
echo -e "${GREEN}$(module list 2>&1)${RESET}"
echo "module load gcc" >> $SETUP_DIR/config.sh
echo "module load mkl" >> $SETUP_DIR/config.sh
echo -e "${BLUE}[2:9] Finished loading R${RESET}"
echo -e "${BLUE}[2:10] Installing R dependencies Rcpp, RMVL, pryr and proxy${RESET}"
Rscript -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); list.of.packages <- c('Rcpp', 'RMVL', 'pryr', 'proxy'); new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,'Package'])]; if(length(new.packages)) install.packages(new.packages, lib = '$LOCAL_R_PATH')"
echo -e "${BLUE}[2:END] R loaded with dependencies!${RESET}\n\n"


echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}                  [3] JAVA 8                 ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
cd $DEPEN_DIR
if [ ! -d "java" ] && [ ! -d "java/jdk1.8.0_201" ]; then
  echo -e "${BLUE}[3:1] There is no required java!${RESET}"
  rm -rf java
  mkdir java
  cd java
  echo -e "${BLUE}[3:2] Installing java 8${RESET}"
  wget https://compss.bsc.es/~fconejer/jdk-8u201-linux-x64.tar.gz
  tar -zxvf jdk-8u201-linux-x64.tar.gz
  rm jdk-8u201-linux-x64.tar.gz
else
  echo -e "${BLUE}[3:3] The required version of java already exists!${RESET}"
  cd java
fi
export JAVA_HOME=$PWD/jdk1.8.0_201
echo 'export JAVA_HOME='$PWD'/jdk1.8.0_201' >> $SETUP_DIR/config.sh
echo -e "${BLUE}[3:4] JAVA_HOME=$PWD/jdk1.8.0_201${RESET}"
export PATH=$PATH:$JAVA_HOME/bin
echo "export PATH=\$PATH:$JAVA_HOME/bin" >> $SETUP_DIR/config.sh
echo -e "${BLUE}[3:5] PATH=$PATH:$JAVA_HOME/bin${RESET}"
echo -e "${BLUE}[3:END] Finished installing JAVA\n\n${RESET}"


NEED_MAVEN=true
if [[ "$NEED_MAVEN" == true ]]; then
  MAVEN_VER="3.9.9"
  echo -e "${YELLOW}=============================================${RESET}"
  echo -e "${YELLOW}              [4-1] Maven-$MAVEN_VER         ${RESET}"
  echo -e "${YELLOW}=============================================${RESET}"
  cd $DEPEN_DIR
  if [ -d "maven" ] && [ -d "maven/apache-maven-$MAVEN_VER" ]; then
    echo -e "${BLUE}[4-1:1] Maven-$MAVEN_VER is already installed!${RESET}"
    cd maven
  else
    rm -rf maven
    mkdir maven
    cd maven
    echo -e "${BLUE}[4-1:2] Installing Maven-$MAVEN_VER at $PWD${RESET}"
    wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
    tar -xvzf apache-maven-3.9.9-bin.tar.gz
    rm -rf apache-maven-3.9.9-bin.tar.gz
  fi
  cd apache-maven-3.9.9/
  M2_HOME=$PWD
  echo "export M2_HOME=$PWD" >> $SETUP_DIR/config.sh
  echo -e "${BLUE}[4-1:3] M2_HOME=$PWD${RESET}"
  export PATH="$M2_HOME/bin:$PATH"
  echo "export PATH=\$PATH:$M2_HOME/bin" >> $SETUP_DIR/config.sh
  echo -e "${BLUE}[4-1:4] PATH=$PATH${RESET}"
  echo -e "${BLUE}[4-1:END] Finished installing Maven${RESET}\n\n"
fi


NEED_GRADLE=true
if [[ "$NEED_GRADLE" == true ]]; then
  GRADLE_VER="5.4.1"
  echo -e "${YELLOW}=============================================${RESET}"
  echo -e "${YELLOW}              [4-2] Gradle-$GRADLE_VER       ${RESET}"
  echo -e "${YELLOW}=============================================${RESET}"
  cd $DEPEN_DIR
  if [ -d "gradle" ] && [ -d "gradle/gradle-$GRADLE_VER" ]; then
    echo -e "${BLUE}[4-2:1] Gradle-$GRADLE_VER is already installed!${RESET}"
    cd gradle
  else
    rm -rf gradle
    mkdir gradle
    cd gradle
    echo -e "${BLUE}[4-2:2] Installing Gradle-$GRADLE_VER at $PWD${RESET}"
    wget 'https://services.gradle.org/distributions/gradle-'$GRADLE_VER'-bin.zip'
    unzip 'gradle-'$GRADLE_VER'-bin.zip'
    rm 'gradle-'$GRADLE_VER'-bin.zip'
  fi
  cd 'gradle-'$GRADLE_VER'/bin'
  export PATH=$PATH:$PWD
  echo "export PATH=\$PATH:$PWD" >> $SETUP_DIR/config.sh
  echo -e "${BLUE}[4-2:3] PATH=$PATH${RESET}"
  echo -e "${BLUE}[4-2:END] Finished installing Gradle${RESET}\n\n"
fi


BUILD_FROM_SOURCE=false
echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}                  [5] COMPSs                 ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
# Create the installation folder
cd $DEPEN_DIR
COMPSs_EXISTS=false
if [ -d "COMPSs_installation" ]; then
  echo -e "${BLUE}[5:1] The directory 'COMPSs_installation' already exists!${RESET}"
  if ask_yes_no "[5:2] Do you want to reinstall COMPSs?"; then
    rm -rf COMPSs_installation
    mkdir COMPSs_installation
  else
    COMPSs_EXISTS=true
  fi
else
  mkdir COMPSs_installation
  echo -e "${BLUE}[5:3] Created folder 'COMPSs_installation'${RESET}"
fi
cd COMPSs_installation
COMPSs_INSTALL_DIR=$PWD
echo -e "${BLUE}[5:4] COMPSs_INSTALL_DIR=$PWD${RESET}"

cd $DEPEN_DIR
if [[ "$COMPSs_EXISTS" == false ]]; then
  if ask_yes_no "[5:5] Do you want to build from binary?"; then
    if [ -d "compss" ]; then
      echo -e "${BLUE}[5:6] The directory 'compss' already exists!${RESET}"
    else
      echo -e "${BLUE}[5:7] Cloning 'compss'${RESET}"
      git clone git@github.com:bsc-wdc/compss.git
    fi
    cd compss
    git checkout r_binding
    echo -e "${BLUE}[5:8] Switched to branch 'r_binding'${RESET}"

    # Update the submodules
    ./submodules_get.sh
    echo -e "${BLUE}[5:9] Updated the submodules${RESET}"

    cd builders
    ./buildlocal --skip-tests --no-jacoco --no-cli --no-monitor --no-dlb --no-pycompss-compile --no-python-style --no-tracing --no-kafka ${COMPSs_INSTALL_DIR}
    # Obtain the tar.gz installation package for COMPSs
    # cd builders/specs/sc
    # ./buildsc R_version
    # cd ../../packages/sc
    # mv 
  elif [ -e COMPSs_R_version.tar.gz ]; then
    tar -xvzf COMPSs_R_version.tar.gz
    cd COMPSs
    ./install --no-python-binding --no-tracing ${COMPSs_INSTALL_DIR}
  fi
fi
# source $COMPSs_INSTALL_DIR/compssenv
# echo "source $COMPSs_INSTALL_DIR/compssenv" >> $SETUP_DIR/config.sh
echo "export PATH=\$PATH:$COMPSs_INSTALL_DIR/Runtime/scripts/user:$COMPSs_INSTALL_DIR/Runtime/scripts/utils" >> $SETUP_DIR/config.sh
echo "export CLASSPATH=\$CLASSPATH:$COMPSs_INSTALL_DIR/Runtime/compss-engine.jar" >> $SETUP_DIR/config.sh
echo "export PATH=\$PATH:$COMPSs_INSTALL_DIR/Bindings/c/bin" >> $SETUP_DIR/config.sh
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$COMPSs_INSTALL_DIR/Bindings/bindings-common/lib:\$JAVA_HOME/lib/amd64/server:\$JAVA_HOME/jre/lib/amd64/server" >> $SETUP_DIR/config.sh
echo -e "${BLUE}[4:END] COMPSs is successfully installed!${RESET}\n\n"



echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}                  [6] RCOMPSs                ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
cd $SETUP_DIR
if [ -d "RCOMPSs" ]; then
  echo -e "${BLUE}[6:1] RCOMPSs already exists!${RESET}"
  cd RCOMPSs
  if ask_yes_no "[6:2] Do you want to update RCOMPSs?"; then
    git pull
    echo -e "${BLUE}[6:3] RCOMPSs updated${RESET}"
  fi
else
  git clone git@github.com:stsds/RCOMPSs.git
  echo -e "${BLUE}[6:4] RCOMPSs cloned${RESET}"
fi
cd $SETUP_DIR/RCOMPSs
export RCOMPSs_DIR=$PWD
echo "export RCOMPSs_DIR=$PWD" >> $SETUP_DIR/config.sh
echo -e "${BLUE}[6:5] RCOMPSs_DIR=$PWD${RESET}"
cd $RCOMPSs_DIR/src
echo 'PKG_CPPFLAGS=-I'$COMPSs_INSTALL_DIR'/Bindings/bindings-common/include -I'$JAVA_HOME'/include -I'$JAVA_HOME'/include/linux' > Makevars
echo 'PKG_LIBS=-L'$COMPSs_INSTALL_DIR'/Bindings/bindings-common/lib -lbindings_common' >> Makevars
echo -e "${BLUE}[6:6] Finished setting the \`Makevars\`${RESET}"

# Update paths
echo -e "${BLUE}[6:7] Updating paths${RESET}"
export LD_LIBRARY_PATH=$COMPSs_INSTALL_DIR/Bindings/bindings-common/lib:$LD_LIBRARY_PATH
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$COMPSs_INSTALL_DIR/Bindings/bindings-common/lib" >> $SETUP_DIR/config.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server" >> $SETUP_DIR/config.sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(R RHOME)
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$(R RHOME)" >> $SETUP_DIR/config.sh
cd $(R RHOME)
cd ../..
export R_BASE_ROOT=$PWD
echo "export R_BASE_ROOT=\$R_BASE_ROOT:$PWD" >> $SETUP_DIR/config.sh
export PATH=/opt/ecrc/r-base/4.3.1/ub18/bin:$PATH
echo "export PATH=\$PATH:$R_BASE_ROOT/bin"  >> $SETUP_DIR/config.sh

cd $SETUP_DIR
R CMD build RCOMPSs
echo -e "${BLUE}[6:8] RCOMPSs built!${RESET}"
R CMD INSTALL RCOMPSs_1.0.tar.gz
echo -e "${BLUE}[6:9] RCOMPSs installed!${RESET}"
rm RCOMPSs_1.0.tar.gz
echo -e "${BLUE}[6:END] Removed RCOMPSs_1.0.tar.gz!${RESET}\n\n"


echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}               [7] Update files              ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
cd $SETUP_DIR
if ask_yes_no "[7:1] Do you want to update executor.R using the one in RCOMPSs/aux/?"; then
  cp $RCOMPSs_DIR/aux/executor.R $COMPSs_INSTALL_DIR/Runtime/scripts/system/adaptors/nio/pipers/
  echo -e "${BLUE}[7:2] executor.R is updated!${RESET}"
fi

# default_project.xml
cd $RCOMPSs_DIR/aux
echo -e "${BLUE}[7:3] Updating default_project.xml${RESET}"
cat <<EOT > default_project.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Project>
  <MasterNode>
    <SharedDisks>
      <AttachedDisk Name="sharedDisk0">
        <MountPoint>/</MountPoint>
      </AttachedDisk>
    </SharedDisks>
  </MasterNode>
  <ComputeNode Name="localhost">
    <InstallDir>$COMPSs_INSTALL_DIR</InstallDir>
    <WorkingDir>/tmp/COMPSsWorker-$USER/</WorkingDir>
    <Application>
      <EnvironmentScript>$SETUP_DIR/config.sh</EnvironmentScript>
    </Application>
  </ComputeNode>
</Project>
EOT
echo -e "${BLUE}[7:END] All files updated${RESET}\n\n"


################FOR SHAHEEN

# cd /scratch/abdullsm/rcompss
# cp ./RCOMPSs/aux/install ./COMPSs
#Install COMPSs
# cd /scratch/abdullsm/rcompss/COMPSs
# ./install -T -C -P /scratch/abdullsm/rcompss/COMPSs_installation/
#prepare Shaheenconfiguration
# cd /scratch/abdullsm/rcompss/COMPSs_installation/Runtime/scripts/queues/supercomputers
# cp mn.cfg shaheen.cfg
# vim shaheen.cfg
# Change this to the number of CPUs on the system (DEFAULT_CPUS_PER_NODE=192) (DEFAULT_WORKER_IN_MASTER_CPUS=192) (DEFAULT_WORKER_WORKING_DIR=shared_disk) DEFAULT_NETWORK=ethernet  (DEFAULT_JVM_WORKER_IN_MASTER="-Xms1600m,-Xmx92000m,-Xmn1600m") (DEFAULT_JVM_WORKERS="-Xms1600m,-Xmx92000m,-Xmn1600m")
# DEFAULT_JVM_MASTER="-Xms1600m,-Xmx92000m,-Xmn1600m"  (LOCAL_DISK_PREFIX="/tmp")
# SHARED_DISK_PREFIX="/"
# SHARED_DISK_2_PREFIX="/"
# cp shaheen.cfg  default.cfg
#source you file
# source /scratch/abdullsm/rcompss/COMPSs_installation/compssenv
#Check if everything is okay (no need for it)
# enqueue_compss -h
# echo 'Finished installing COMPSs'


######## Run your example
echo -e "${YELLOW}=============================================${RESET}"
echo -e "${YELLOW}               [9] Test examples             ${RESET}"
echo -e "${YELLOW}=============================================${RESET}"
echo -e "${BLUE}[9:1] Sourcing the \`config.sh\`${RESET}"
cd $SETUP_DIR
source config.sh

cd $RCOMPSs_DIR/examples

echo -e "${BLUE}[9:2] Executing the K-means example${RESET}"
cd kmeans
EG_KMEANS_DIR=$PWD
compss_clean_procs
runcompss --lang=r -g -d --output_profile=$EG_KMEANS_DIR/output_profile --project=$RCOMPSs_DIR/aux/default_project.xml --resources=$RCOMPSs_DIR/aux/default_resources.xml kmeans.R --plot FALSE --RCOMPSs --fragments 2 --arity 2 --numpoints 9000 --iterations 2


echo -e "${YELLOW}*********************************************${RESET}"
echo -e "${YELLOW}*******RCOMPSs INSTALLED SUCCESSFULLY!*******${RESET}"
echo -e "${YELLOW}*********************************************${RESET}"
echo -e "${YELLOW}PATH: $SETUP_DIR${RESET}"
