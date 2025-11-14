cmake_minimum_required(VERSION 3.16)
project(TCNopen LANGUAGES C)

set(_tcnopen_have_sdtv2 OFF)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/SDTv2/CMakeLists.txt")
    set(_tcnopen_have_sdtv2 ON)
endif()

option(TCNOPEN_BUILD_SDT "Build the SDTv2 safety data transmission library" ${_tcnopen_have_sdtv2})
option(TCNOPEN_BUILD_TRDP "Build the TRDP communication stack" ON)

if(TCNOPEN_BUILD_SDT)
    if(NOT _tcnopen_have_sdtv2)
        message(FATAL_ERROR
            "TCNOPEN_BUILD_SDT is enabled but the SDTv2 directory is missing. "
            "Either restore the folder or re-configure with -DTCNOPEN_BUILD_SDT=OFF.")
    endif()
    add_subdirectory(SDTv2)
endif()

if(TCNOPEN_BUILD_TRDP)
    add_subdirectory(trdp)
endif()

add_custom_target(distclean
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${CMAKE_SOURCE_DIR}
        -DBINARY_DIR=${CMAKE_BINARY_DIR}
        -P ${CMAKE_SOURCE_DIR}/cmake/Distclean.cmake
    COMMENT "Removing generated source tree artifacts"
)

add_custom_target(lint)
if(TARGET sdtv2_lint)
    add_dependencies(lint sdtv2_lint)
endif()
if(TARGET trdp_lint)
    add_dependencies(lint trdp_lint)
endif()
