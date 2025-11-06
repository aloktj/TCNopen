cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED DLU_COMMAND)
    message(FATAL_ERROR "DLU_COMMAND is not defined for PackageDLU.cmake")
endif()
if(NOT DEFINED DLU_DIR)
    message(FATAL_ERROR "DLU_DIR is not defined for PackageDLU.cmake")
endif()
if(NOT DEFINED DLU_FILENAME)
    message(FATAL_ERROR "DLU_FILENAME is not defined for PackageDLU.cmake")
endif()
if(NOT DEFINED DLU_VERSION)
    message(FATAL_ERROR "DLU_VERSION is not defined for PackageDLU.cmake")
endif()
if(NOT DEFINED TAR_PATH)
    message(FATAL_ERROR "TAR_PATH is not defined for PackageDLU.cmake")
endif()

set(dlu_args
    sdtv2.tar
    sdtv2
    ${DLU_VERSION}
    DLU_TYPE_LINUX_TAR
    TPATH
    /usr/local/sdtv2.tar
    OUTFILE
    ${DLU_FILENAME}
)

execute_process(
    COMMAND ${DLU_COMMAND} ${dlu_args}
    WORKING_DIRECTORY "${DLU_DIR}"
    RESULT_VARIABLE _dlu_result
    OUTPUT_VARIABLE _dlu_stdout
    ERROR_VARIABLE _dlu_stderr
)

if(_dlu_result)
    message(STATUS "makedlu command '${DLU_COMMAND}' failed with status ${_dlu_result}; copying tar archive instead")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy "${TAR_PATH}" "${DLU_DIR}/${DLU_FILENAME}"
        RESULT_VARIABLE _copy_result
        ERROR_VARIABLE _copy_error
    )
    if(_copy_result)
        message(FATAL_ERROR "Failed to copy '${TAR_PATH}' to '${DLU_DIR}/${DLU_FILENAME}': ${_copy_error}")
    endif()
endif()
