cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED INPUT)
    message(FATAL_ERROR "INPUT is not defined for WriteMD5.cmake")
endif()
if(NOT DEFINED OUTPUT)
    message(FATAL_ERROR "OUTPUT is not defined for WriteMD5.cmake")
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND} -E md5sum "${INPUT}"
    OUTPUT_VARIABLE _md5_output
    RESULT_VARIABLE _md5_result
    ERROR_VARIABLE _md5_error
)

if(_md5_result)
    message(FATAL_ERROR "Failed to compute md5sum for '${INPUT}': ${_md5_error}")
endif()

file(WRITE "${OUTPUT}" "${_md5_output}")
