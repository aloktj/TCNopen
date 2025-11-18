# SPDX-License-Identifier: MPL-2.0
# Helper that extracts the version triplet from src/common/trdp_private.h so that
# both the legacy Makefile and the CMake build derive the same SONAME.

function(trdp_parse_version header)
    if(NOT EXISTS "${header}")
        message(FATAL_ERROR "Unable to read TRDP version header: ${header}")
    endif()

    file(READ "${header}" _trdp_header)
    foreach(part VERSION RELEASE UPDATE EVOLUTION)
        string(REGEX MATCH "#define[ \t]+TRDP_${part}[ \t]+([0-9]+)" _match "${_trdp_header}")
        if(CMAKE_MATCH_COUNT EQUAL 0)
            message(FATAL_ERROR "Could not find TRDP_${part} in ${header}")
        endif()
        set(TRDP_${part}_VALUE "${CMAKE_MATCH_1}" PARENT_SCOPE)
    endforeach()

    set(TRDP_VERSION_STRING
        "${TRDP_VERSION_VALUE}.${TRDP_RELEASE_VALUE}.${TRDP_UPDATE_VALUE}.${TRDP_EVOLUTION_VALUE}"
        PARENT_SCOPE)
endfunction()
