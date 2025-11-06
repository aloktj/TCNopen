cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED OUTPUT)
    message(FATAL_ERROR "OUTPUT is not defined for RunLint.cmake")
endif()
if(NOT DEFINED SOURCES)
    message(FATAL_ERROR "SOURCES is not defined for RunLint.cmake")
endif()

set(_header " ### Lint Final\n### Final Lint Stage - Verifying inter module / system wide stuff\n")
file(WRITE "${OUTPUT}" "${_header}")

if(NOT FLINT_CMD OR FLINT_CMD STREQUAL "")
    file(APPEND "${OUTPUT}" "FLINT command not configured, skipping analysis\n")
    return()
endif()

separate_arguments(_flint_args UNIX_COMMAND "${FLINT_ARGS}")
separate_arguments(_source_list UNIX_COMMAND "${SOURCES}")

execute_process(
    COMMAND ${FLINT_CMD} ${_flint_args} ${_source_list}
    RESULT_VARIABLE _lint_result
    OUTPUT_VARIABLE _lint_stdout
    ERROR_VARIABLE _lint_stderr
)

if(_lint_stdout)
    file(APPEND "${OUTPUT}" "${_lint_stdout}")
endif()

if(_lint_stderr)
    file(APPEND "${OUTPUT}" "${_lint_stderr}")
endif()

if(_lint_result AND NOT _lint_result EQUAL 0)
    string(STRIP "${_lint_result}" _lint_result_stripped)
    if("${_lint_result_stripped}" STREQUAL "No such file or directory")
        file(APPEND "${OUTPUT}" "FLINT command '${FLINT_CMD}' not found, skipping analysis\n")
    else()
        file(APPEND "${OUTPUT}" "FLINT command returned ${_lint_result_stripped}\n")
    endif()
endif()
