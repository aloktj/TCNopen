cmake_minimum_required(VERSION 3.16)

foreach(var IN ITEMS SOURCE_DIR OUTPUT_DIR DEBUILD_CMD SRC_VERSION)
    if(NOT DEFINED ${var})
        message(FATAL_ERROR "${var} is not defined for RunBindebPkg.cmake")
    endif()
endforeach()

if(NOT DEBUILD_CMD OR DEBUILD_CMD STREQUAL "")
    message(STATUS "debuild command not found; skipping Debian package build.")
    return()
endif()

execute_process(
    COMMAND ${DEBUILD_CMD} -us -uc -i -I -b
    WORKING_DIRECTORY "${SOURCE_DIR}"
    RESULT_VARIABLE _debuild_result
)
if(_debuild_result AND NOT _debuild_result EQUAL 0)
    message(FATAL_ERROR "debuild failed with exit code ${_debuild_result}")
endif()

file(MAKE_DIRECTORY "${OUTPUT_DIR}")
file(GLOB _packages "${SOURCE_DIR}/../libtrdp*")
if(NOT _packages)
    message(WARNING "No files matching 'libtrdp*' were produced by debuild.")
    return()
endif()

foreach(pkg IN LISTS _packages)
    get_filename_component(_pkg_name "${pkg}" NAME)
    set(_target "${OUTPUT_DIR}/${_pkg_name}")
    if(EXISTS "${_target}")
        file(REMOVE "${_target}")
    endif()
    file(RENAME "${pkg}" "${_target}")
endforeach()

message(STATUS "Debian packages for TRDP ${SRC_VERSION} stored in '${OUTPUT_DIR}'.")
