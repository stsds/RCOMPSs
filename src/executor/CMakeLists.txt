
add_executable(rcompss_executor
  ExecutorMain.cpp
  ExecutorCore.cpp
)

target_include_directories(rcompss_executor PRIVATE
  ${RCOMPSs_INCLUDE_DIRS}
  "${CMAKE_SOURCE_DIR}/include"
)
target_compile_options(rcompss_executor PRIVATE ${R_CPPFLAGS_LIST} ${RCPP_CPPFLAGS_LIST})
target_link_directories(rcompss_executor PRIVATE ${RCOMPSs_LIBRARY_DIRS})
target_link_options(rcompss_executor PRIVATE ${R_LDFLAGS_LIST} ${RCPP_LDFLAGS_LIST})
target_link_libraries(rcompss_executor PRIVATE ${RCOMPSs_LIBS} ${R_LDLIBS_LIST})

set_target_properties(rcompss_executor PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/aux"
)