set(TRDP_COMMON_SOURCES
    src/common/tau_ctrl.c
    src/common/tau_cstinfo.c
    src/common/tau_dnr.c
    src/common/tau_marshall.c
    src/common/tau_so_if.c
    src/common/tau_tti.c
    src/common/tau_xml.c
    src/common/tau_xmarshall.c
    src/common/tau_xsession.c
    src/common/tlc_if.c
    src/common/tlm_if.c
    src/common/tlp_if.c
    src/common/trdp_dllmain.c
    src/common/trdp_mdcom.c
    src/common/trdp_pdcom.c
    src/common/trdp_pdindex.c
    src/common/trdp_stats.c
    src/common/trdp_utils.c
    src/common/trdp_xml.c
)

set(TRDP_VOS_COMMON_SOURCES
    src/vos/common/vos_mem.c
    src/vos/common/vos_utils.c
)

set(TRDP_VOS_POSIX_SOURCES
    src/vos/posix/vos_shared_mem.c
    src/vos/posix/vos_sock.c
    src/vos/posix/vos_thread.c
)

option(TRDP_ENABLE_TSN "Enable support for Time Sensitive Networking" OFF)
if(TRDP_ENABLE_TSN)
    list(APPEND TRDP_VOS_POSIX_SOURCES src/vos/posix/vos_sockTSN.c)
endif()

add_library(trdp STATIC
    ${TRDP_COMMON_SOURCES}
    ${TRDP_VOS_COMMON_SOURCES}
    ${TRDP_VOS_POSIX_SOURCES}
)
add_library(tcnopen::trdp ALIAS trdp)

find_package(Threads REQUIRED)

target_include_directories(trdp
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/api>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/common>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/vos/api>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/vos/common>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/vos/posix>
        $<INSTALL_INTERFACE:include/trdp>
)

target_compile_features(trdp PUBLIC c_std_99)

target_compile_definitions(trdp
    PUBLIC
        POSIX
        _GNU_SOURCE
)

if(TRDP_ENABLE_TSN)
    target_compile_definitions(trdp PUBLIC TSN_SUPPORT)
endif()

target_link_libraries(trdp PUBLIC Threads::Threads)

if(UNIX AND NOT APPLE)
    target_link_libraries(trdp PUBLIC rt)
endif()
