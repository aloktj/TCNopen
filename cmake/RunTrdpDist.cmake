cmake_minimum_required(VERSION 3.16)

foreach(var IN ITEMS SOURCE_DIR TOP_SOURCE_DIR OUTPUT_DIR DIST_DEBIAN DIST_ORIG SRC_VERSION)
    if(NOT DEFINED ${var})
        message(FATAL_ERROR "${var} is not defined for RunTrdpDist.cmake")
    endif()
endforeach()

if(NOT TAR_CMD OR TAR_CMD STREQUAL "")
    message(STATUS "tar command not found; skipping TRDP distribution archives.")
    return()
endif()

file(MAKE_DIRECTORY "${OUTPUT_DIR}")

set(_debian_args
    --exclude-ignore-recursive=../.gitignore
    -c
    -J
    -f
    "${DIST_DEBIAN}"
    debian
)
execute_process(
    COMMAND ${TAR_CMD} ${_debian_args}
    WORKING_DIRECTORY "${SOURCE_DIR}"
    RESULT_VARIABLE _debian_result
)
if(_debian_result AND NOT _debian_result EQUAL 0)
    message(FATAL_ERROR "tar failed while creating '${DIST_DEBIAN}' with exit code ${_debian_result}")
endif()

set(_orig_args
    --exclude=debian
    --exclude=bld
    --exclude=VSExpress2015
    --exclude=Xcode
    --exclude=test
    --exclude=resources
    --exclude-ignore-recursive=.gitignore
    -c
    -J
    -f
    "${DIST_ORIG}"
    trdp
)
execute_process(
    COMMAND ${TAR_CMD} ${_orig_args}
    WORKING_DIRECTORY "${TOP_SOURCE_DIR}"
    RESULT_VARIABLE _orig_result
)
if(_orig_result AND NOT _orig_result EQUAL 0)
    message(FATAL_ERROR "tar failed while creating '${DIST_ORIG}' with exit code ${_orig_result}")
endif()

message(STATUS "Created TRDP distribution archives for version ${SRC_VERSION}.")
