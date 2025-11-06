cmake_minimum_required(VERSION 3.16)

project(trdp LANGUAGES C)

include(GNUInstallDirs)

set(TRDP_TARGET_ARCH "generic" CACHE STRING "Identifier for the target architecture used in output directory names.")
set(TRDP_TARGET_OS "LINUX" CACHE STRING "Name of the target operating system exposed as a preprocessor definition.")
set(TRDP_TARGET_VOS "posix" CACHE STRING "Name of the VOS backend directory under src/vos.")

set(TRDP_ADDITIONAL_INCLUDE_DIRS "" CACHE STRING "Extra include directories appended to the public include path.")
set(TRDP_ADDITIONAL_COMPILE_OPTIONS "" CACHE STRING "Extra compiler options applied to all TRDP targets.")
set(TRDP_ADDITIONAL_COMPILE_DEFINITIONS "" CACHE STRING "Extra preprocessor definitions applied to all TRDP targets.")
set(TRDP_ADDITIONAL_LINK_LIBRARIES "" CACHE STRING "Extra libraries linked to all TRDP targets.")

option(TRDP_MD_SUPPORT "Enable message data (MD) support" ON)
option(TRDP_SOA_SUPPORT "Enable service-oriented architecture (SOA) support" OFF)
option(TRDP_TSN_SUPPORT "Enable Time Sensitive Networking (TSN) support" OFF)
option(TRDP_HIGH_PERF_INDEXED "Build high performance (indexed) variants" OFF)
option(TRDP_HIGH_PERF_BASE2 "Use base-2 addressing for high performance builds" OFF)
option(TRDP_RT_THREADS "Enable realtime thread scheduling support" OFF)
option(TRDP_DEBUG "Enable debug definitions" OFF)

set(trdp_root ${CMAKE_CURRENT_SOURCE_DIR})

set(trdp_core_sources
    src/common/trdp_pdcom.c
    src/common/trdp_stats.c
    src/common/trdp_utils.c
    src/common/tlc_if.c
    src/common/tlp_if.c
    src/common/trdp_dllmain.c
    src/vos/common/vos_mem.c
    src/vos/common/vos_utils.c
)

if(TRDP_MD_SUPPORT)
    list(APPEND trdp_core_sources
        src/common/trdp_mdcom.c
        src/common/tlm_if.c
    )
endif()

set(trdp_optional_sources
    src/common/tau_ctrl.c
    src/common/tau_cstinfo.c
    src/common/tau_dnr.c
    src/common/tau_marshall.c
    src/common/tau_tti.c
    src/common/tau_xml.c
    src/common/tau_xmarshall.c
    src/common/tau_xsession.c
    src/common/trdp_xml.c
)

if(TRDP_MD_SUPPORT AND TRDP_SOA_SUPPORT)
    list(APPEND trdp_optional_sources src/common/tau_so_if.c)
endif()

set(trdp_vos_dir ${trdp_root}/src/vos/${TRDP_TARGET_VOS})
if(NOT IS_DIRECTORY "${trdp_vos_dir}")
    message(FATAL_ERROR "Unsupported TRDP_TARGET_VOS '${TRDP_TARGET_VOS}'. Expected directory '${trdp_vos_dir}'.")
endif()

file(GLOB trdp_vos_sources CONFIGURE_DEPENDS "${trdp_vos_dir}/*.c")

set(trdp_tsn_source "${trdp_root}/src/vos/${TRDP_TARGET_VOS}/vos_sockTSN.c")
if(TRDP_TSN_SUPPORT)
    if(EXISTS "${trdp_tsn_source}")
        list(APPEND trdp_vos_sources "${trdp_tsn_source}")
    else()
        message(WARNING "TSN support requested but '${trdp_tsn_source}' was not found.")
    endif()
else()
    list(REMOVE_ITEM trdp_vos_sources "${trdp_tsn_source}")
endif()

list(APPEND trdp_core_sources ${trdp_vos_sources})

set(trdp_high_perf_sources)
if(TRDP_HIGH_PERF_INDEXED)
    list(APPEND trdp_high_perf_sources src/common/trdp_pdindex.c)
endif()

set(trdp_public_includes
    ${trdp_root}/src/api
    ${trdp_root}/src/common
    ${trdp_root}/src/vos/api
    ${trdp_root}/src/vos/common
    ${trdp_root}/src/vos/${TRDP_TARGET_VOS}
)

if(TRDP_ADDITIONAL_INCLUDE_DIRS)
    separate_arguments(_extra_includes NATIVE_COMMAND "${TRDP_ADDITIONAL_INCLUDE_DIRS}")
    list(APPEND trdp_public_includes ${_extra_includes})
    unset(_extra_includes)
endif()

set(trdp_common_compile_defs
    ${TRDP_TARGET_OS}
    $<$<BOOL:${TRDP_MD_SUPPORT}>:MD_SUPPORT=1>
    $<$<NOT:$<BOOL:${TRDP_MD_SUPPORT}>>:MD_SUPPORT=0>
    $<$<BOOL:${TRDP_SOA_SUPPORT}>:SOA_SUPPORT>
    $<$<BOOL:${TRDP_TSN_SUPPORT}>:TSN_SUPPORT>
    $<$<BOOL:${TRDP_RT_THREADS}>:RT_THREADS>
)

if(TRDP_TARGET_VOS STREQUAL "posix")
    list(APPEND trdp_common_compile_defs POSIX)
endif()

if(TRDP_DEBUG)
    list(APPEND trdp_common_compile_defs DEBUG)
else()
    list(APPEND trdp_common_compile_defs NO_DEBUG)
endif()

if(TRDP_ADDITIONAL_COMPILE_DEFINITIONS)
    separate_arguments(_extra_defs NATIVE_COMMAND "${TRDP_ADDITIONAL_COMPILE_DEFINITIONS}")
    list(APPEND trdp_common_compile_defs ${_extra_defs})
    unset(_extra_defs)
endif()

set(trdp_common_compile_opts)
if(TRDP_ADDITIONAL_COMPILE_OPTIONS)
    separate_arguments(_extra_opts NATIVE_COMMAND "${TRDP_ADDITIONAL_COMPILE_OPTIONS}")
    list(APPEND trdp_common_compile_opts ${_extra_opts})
    unset(_extra_opts)
endif()

set(trdp_common_link_libs Threads::Threads)
if(UNIX AND NOT APPLE)
    list(APPEND trdp_common_link_libs rt)
endif()

if(TRDP_ADDITIONAL_LINK_LIBRARIES)
    separate_arguments(_extra_libs NATIVE_COMMAND "${TRDP_ADDITIONAL_LINK_LIBRARIES}")
    list(APPEND trdp_common_link_libs ${_extra_libs})
    unset(_extra_libs)
endif()

find_package(Threads REQUIRED)

set(trdp_library_pairs)

function(trdp_define_library_pair stem include_optional is_high_perf output_name)
    set(local_sources ${trdp_core_sources})
    if(include_optional)
        list(APPEND local_sources ${trdp_optional_sources})
    endif()

    set(local_compile_defs ${trdp_common_compile_defs})
    if(is_high_perf)
        if(NOT TRDP_HIGH_PERF_INDEXED)
            return()
        endif()
        list(APPEND local_sources ${trdp_high_perf_sources})
        list(APPEND local_compile_defs HIGH_PERF_INDEXED)
        if(TRDP_HIGH_PERF_BASE2)
            list(APPEND local_compile_defs HIGH_PERF_BASE2)
        endif()
    endif()

    set(static_target ${stem}_static)
    set(shared_target ${stem}_shared)

    add_library(${static_target} STATIC ${local_sources})
    add_library(${shared_target} SHARED ${local_sources})

    set(output_arch ${TRDP_TARGET_ARCH})
    if(is_high_perf)
        set(output_arch "${TRDP_TARGET_ARCH}-hp")
    endif()

    foreach(target IN ITEMS ${static_target} ${shared_target})
        target_include_directories(${target}
            PUBLIC
                ${trdp_public_includes}
        )
        target_compile_features(${target} PUBLIC c_std_99)
        target_compile_definitions(${target} PUBLIC ${local_compile_defs})
        if(trdp_common_compile_opts)
            target_compile_options(${target} PRIVATE ${trdp_common_compile_opts})
        endif()
        target_link_libraries(${target} PUBLIC ${trdp_common_link_libs})
        set(target_output_name ${output_name})
        if(is_high_perf)
            set(target_output_name "${output_name}-hp")
        endif()
        set_target_properties(${target} PROPERTIES
            OUTPUT_NAME ${target_output_name}
            ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${output_arch}/lib"
            LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${output_arch}/lib"
            RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${output_arch}/bin"
        )
    endforeach()

    list(APPEND trdp_library_pairs ${static_target} ${shared_target})
    set(trdp_library_pairs "${trdp_library_pairs}" PARENT_SCOPE)
endfunction()

trdp_define_library_pair(trdp FALSE FALSE trdp)
trdp_define_library_pair(trdpap TRUE FALSE trdpap)
if(TRDP_HIGH_PERF_INDEXED)
    trdp_define_library_pair(trdp_hp FALSE TRUE trdp)
    trdp_define_library_pair(trdpap_hp TRUE TRUE trdpap)
endif()

foreach(target IN LISTS trdp_library_pairs)
    add_library(tcnopen::${target} ALIAS ${target})
endforeach()

install(TARGETS ${trdp_library_pairs}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(DIRECTORY src/api/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp FILES_MATCHING PATTERN "*.h")
