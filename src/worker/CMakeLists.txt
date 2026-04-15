add_executable(rcompss_worker
  WorkerMain.cpp
  WorkerCore.cpp
)

target_include_directories(rcompss_worker PRIVATE
  ${RCOMPSs_INCLUDE_DIRS}
  "${CMAKE_SOURCE_DIR}/include"
)
target_link_directories(rcompss_worker PRIVATE ${RCOMPSs_LIBRARY_DIRS})
target_link_libraries(rcompss_worker PRIVATE ${RCOMPSs_LIBS})

set_target_properties(rcompss_worker PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/aux"
)


