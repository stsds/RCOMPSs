cmake_minimum_required(VERSION 3.16)
project(RCOMPSs LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# -----------------------------------------------------------------------------
# CUDA / GPU support configuration (mirrors TLAR pattern)
# -----------------------------------------------------------------------------

# Option to request GPU-enabled build. If ON but CUDA is missing, fail clearly.
option(RCOMPSs_GPU "Build RCOMPSs with CUDA GPU support" ON)

include(CheckLanguage)
check_language(CUDA)

if (CMAKE_CUDA_COMPILER AND RCOMPSs_GPU)
    set(USE_CUDA ON)
    message(STATUS "CUDA support enabled (CMAKE_CUDA_COMPILER=${CMAKE_CUDA_COMPILER})")
    enable_language(CUDA)
    add_definitions(-DUSE_CUDA)
elseif (RCOMPSs_GPU)
    message(FATAL_ERROR "RCOMPSs_GPU=ON but CUDA compiler was not found (CMAKE_CUDA_COMPILER is empty)")
else ()
    set(USE_CUDA OFF)
    message(STATUS "RCOMPSs_GPU=OFF or no CUDA compiler - building CPU-only version")
endif ()

find_program(R_EXECUTABLE R)
find_program(RSCRIPT_EXECUTABLE Rscript)
if (NOT R_EXECUTABLE OR NOT RSCRIPT_EXECUTABLE)
  message(FATAL_ERROR "R and Rscript are required to build the RCOMPSs shared library.")
endif()

execute_process(
  COMMAND ${R_EXECUTABLE} CMD config --cppflags
  OUTPUT_VARIABLE R_CPPFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND ${R_EXECUTABLE} CMD config --ldflags
  OUTPUT_VARIABLE R_LDFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND ${R_EXECUTABLE} CMD config --ldlibs
  OUTPUT_VARIABLE R_LDLIBS
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND ${R_EXECUTABLE} RHOME
  OUTPUT_VARIABLE R_HOME
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND ${RSCRIPT_EXECUTABLE} -e "cat(Rcpp:::CxxFlags())"
  OUTPUT_VARIABLE RCPP_CPPFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
  COMMAND ${RSCRIPT_EXECUTABLE} -e "cat(Rcpp:::LdFlags())"
  OUTPUT_VARIABLE RCPP_LDFLAGS
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

separate_arguments(R_CPPFLAGS_LIST UNIX_COMMAND "${R_CPPFLAGS}")
separate_arguments(RCPP_CPPFLAGS_LIST UNIX_COMMAND "${RCPP_CPPFLAGS}")
separate_arguments(R_LDFLAGS_LIST UNIX_COMMAND "${R_LDFLAGS}")
separate_arguments(RCPP_LDFLAGS_LIST UNIX_COMMAND "${RCPP_LDFLAGS}")
separate_arguments(R_LDLIBS_LIST UNIX_COMMAND "${R_LDLIBS}")

# Some R installations include a literal "--ldlibs" token in --ldflags output.
# Filter it out to avoid passing it to the linker.
list(FILTER R_LDFLAGS_LIST EXCLUDE REGEX "^--ldlibs$")
list(FILTER R_LDLIBS_LIST EXCLUDE REGEX "^--ldlibs$")

# Filter out non-flag tokens and stray error messages that can appear in R CMD config output.
list(FILTER R_LDFLAGS_LIST EXCLUDE REGEX "ERROR:|information|variable")
list(FILTER R_LDLIBS_LIST EXCLUDE REGEX "ERROR:|information|variable")
list(FILTER R_LDFLAGS_LIST EXCLUDE REGEX ":")
list(FILTER R_LDLIBS_LIST EXCLUDE REGEX ":")
list(FILTER R_LDLIBS_LIST EXCLUDE REGEX "^-l(no|for|information|variable)$")
list(FILTER R_LDFLAGS_LIST EXCLUDE REGEX "^-l(no|for|information|variable)$")
list(FILTER R_LDLIBS_LIST EXCLUDE REGEX "^(no|for)$")
list(FILTER R_LDFLAGS_LIST EXCLUDE REGEX "^(no|for)$")

# Drop -ltirpc from R cmd config output to avoid link failures when libtirpc isn't installed.
list(FILTER R_LDLIBS_LIST EXCLUDE REGEX "^-ltirpc$")
list(FILTER R_LDFLAGS_LIST EXCLUDE REGEX "^-ltirpc$")

# Ensure libR is discoverable for standalone executables (executor/worker).
if (R_HOME)
  find_library(R_LIBRARY NAMES R HINTS "${R_HOME}/lib" "${R_HOME}/lib64")
  if (R_LIBRARY)
    list(APPEND R_LDLIBS_LIST "${R_LIBRARY}")
  endif()
endif()

# Find COMPSs installation directory
# Try to find it relative to current source directory or use environment variable
if (DEFINED ENV{COMPSS_HOME})
  set(COMPSs_HOME "$ENV{COMPSS_HOME}")
else()
  # Try going up from source directory to find COMPSs root
  # CMAKE_SOURCE_DIR is typically .../Bindings/RCOMPSs
  # COMPSs root is typically .../ (2 levels up) or .../Bindings (1 level up)
  if (EXISTS "${CMAKE_SOURCE_DIR}/../../Bindings/bindings-common")
    get_filename_component(COMPSs_HOME "${CMAKE_SOURCE_DIR}/../.." ABSOLUTE)
  elseif (EXISTS "${CMAKE_SOURCE_DIR}/../Bindings/bindings-common")
    get_filename_component(COMPSs_HOME "${CMAKE_SOURCE_DIR}/.." ABSOLUTE)
  else()
    # Fallback: assume current directory structure
    get_filename_component(COMPSs_HOME "${CMAKE_SOURCE_DIR}/../.." ABSOLUTE)
  endif()
endif()

# Find Java installation
if (DEFINED ENV{JAVA_HOME})
  set(JAVA_HOME "$ENV{JAVA_HOME}")
else()
  # Try common Java installation paths
  find_path(JAVA_HOME_INCLUDE jni.h
    PATHS
      /usr/lib/jvm/java-*/include
      /usr/lib/jvm/*/include
      /usr/local/java/include
      /opt/java/include
    NO_DEFAULT_PATH
  )
  if (JAVA_HOME_INCLUDE)
    get_filename_component(JAVA_HOME "${JAVA_HOME_INCLUDE}/.." ABSOLUTE)
  else()
    # Fallback to common default
    set(JAVA_HOME "/usr/lib/jvm/java-17-openjdk-amd64")
  endif()
endif()

# Find dummy_extrae location (could be in source dir or installed location)
if (EXISTS "${CMAKE_SOURCE_DIR}/dummy_extrae")
  set(DUMMY_EXTRAE_DIR "${CMAKE_SOURCE_DIR}/dummy_extrae")
elseif (EXISTS "${COMPSs_HOME}/Bindings/RCOMPSs/dummy_extrae")
  set(DUMMY_EXTRAE_DIR "${COMPSs_HOME}/Bindings/RCOMPSs/dummy_extrae")
else()
  message(WARNING "dummy_extrae not found, trying ${CMAKE_SOURCE_DIR}/dummy_extrae")
  set(DUMMY_EXTRAE_DIR "${CMAKE_SOURCE_DIR}/dummy_extrae")
endif()

# Set include directories
set(RCOMPSs_INCLUDE_DIRS
  "${CMAKE_SOURCE_DIR}/include"
  "${CMAKE_SOURCE_DIR}/src"
  "${COMPSs_HOME}/Bindings/bindings-common/include"
  "${DUMMY_EXTRAE_DIR}"
  "${JAVA_HOME}/include"
  "${JAVA_HOME}/include/linux"
  "${JAVA_HOME}/jre/include"
  "${JAVA_HOME}/jre/include/linux"
)

# Set library directories
set(RCOMPSs_LIBRARY_DIRS
  "${COMPSs_HOME}/Bindings/bindings-common/lib"
  "${DUMMY_EXTRAE_DIR}"
)

set(RCOMPSs_LIBS
  bindings_common
  pttrace
)

# Add CUDA libraries if CUDA is enabled
if (USE_CUDA)
    find_package(CUDAToolkit REQUIRED)
    list(APPEND RCOMPSs_LIBS
      CUDA::cublas
      CUDA::cusolver
    )
    list(APPEND RCOMPSs_INCLUDE_DIRS
      ${CUDAToolkit_INCLUDE_DIRS}
    )
    list(APPEND RCOMPSs_LIBRARY_DIRS
      ${CUDAToolkit_LIBRARY_DIR}
    )
    message(STATUS "CUDA toolkit library dir: ${CUDAToolkit_LIBRARY_DIR}")
endif()

add_subdirectory(src)

target_include_directories(RCOMPSs PRIVATE ${RCOMPSs_INCLUDE_DIRS})
target_compile_options(RCOMPSs PRIVATE ${R_CPPFLAGS_LIST} ${RCPP_CPPFLAGS_LIST})
target_link_directories(RCOMPSs PRIVATE ${RCOMPSs_LIBRARY_DIRS})
target_link_options(RCOMPSs PRIVATE ${R_LDFLAGS_LIST} ${RCPP_LDFLAGS_LIST})
target_link_libraries(RCOMPSs PRIVATE ${RCOMPSs_LIBS} ${R_LDLIBS_LIST})

set_target_properties(RCOMPSs PROPERTIES
  PREFIX ""
  OUTPUT_NAME "RCOMPSs"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/src"
)

