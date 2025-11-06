cmake_minimum_required(VERSION 3.16)

project(trdp LANGUAGES C)

include(GNUInstallDirs)
include(CMakeParseArguments)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

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
option(TRDP_BUILD_WIRESHARK_PLUGIN "Build the TRDP Wireshark dissector plugin" OFF)

set(TRDP_WIRESHARK_PLUGIN_VERSION "2.2.4" CACHE STRING "Version string reported by the TRDP Wireshark plugin.")
set(TRDP_WIRESHARK_PLUGIN_SUBDIR "epan" CACHE STRING "Subdirectory appended to the Wireshark plugindir for dissectors.")
set(TRDP_WIRESHARK_PLUGIN_API_VERSION "" CACHE STRING "Wireshark plugin API version directory (leave empty to auto-detect).")
set(TRDP_WIRESHARK_PLUGIN_DIR "" CACHE PATH "Base directory for Wireshark plugins (defaults to the pkg-config plugindir value).")
set(TRDP_WIRESHARK_DOC_INSTALL_DIR "${CMAKE_INSTALL_DOCDIR}/trdp-spy" CACHE PATH "Install location for TRDP spy documentation.")
set(TRDP_WIRESHARK_CFILE_URL "https://raw.githubusercontent.com/wireshark/wireshark/master-2.6/cfile.h" CACHE STRING "URL used to fetch cfile.h when it is not provided by the installed Wireshark headers.")
set(TRDP_WIRESHARK_CFILE_PATH "" CACHE FILEPATH "Override path to a Wireshark cfile.h header when automatic detection fails.")
option(TRDP_WIRESHARK_DOWNLOAD_CFILE "Attempt to download cfile.h when missing from the system headers" ON)

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

option(TRDP_BUILD_EXAMPLES "Build TRDP example executables" OFF)
option(TRDP_BUILD_TSN_EXAMPLES "Build TRDP TSN example executables" OFF)
option(TRDP_BUILD_TESTS "Build TRDP test executables" OFF)
option(TRDP_BUILD_HIGH_PERF_TESTS "Build TRDP high-performance test executables" OFF)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(trdp_need_uuid FALSE)
set(TRDP_HAVE_UUID FALSE)
if(TRDP_BUILD_EXAMPLES OR TRDP_BUILD_TSN_EXAMPLES OR TRDP_BUILD_TESTS OR TRDP_BUILD_HIGH_PERF_TESTS)
    set(trdp_need_uuid TRUE)
endif()

if(trdp_need_uuid)
    find_library(TRDP_UUID_LIBRARY uuid)
    if(TRDP_UUID_LIBRARY)
        set(TRDP_HAVE_UUID TRUE)
    else()
        set(TRDP_HAVE_UUID FALSE)
    endif()
endif()

function(trdp_add_program target)
    cmake_parse_arguments(TRDP_PROG
        "REQUIRE_UUID;REQUIRE_MD;REQUIRE_TSN;REQUIRE_HIGH_PERF"
        "CATEGORY"
        "SOURCES;LINK_LIBS"
        ${ARGN}
    )

    if(TRDP_PROG_REQUIRE_MD AND NOT TRDP_MD_SUPPORT)
        message(STATUS "Skipping ${target}: requires TRDP_MD_SUPPORT")
        return()
    endif()

    if(TRDP_PROG_REQUIRE_TSN AND NOT TRDP_TSN_SUPPORT)
        message(STATUS "Skipping ${target}: requires TRDP_TSN_SUPPORT")
        return()
    endif()

    if(TRDP_PROG_REQUIRE_HIGH_PERF AND NOT TRDP_HIGH_PERF_INDEXED)
        message(STATUS "Skipping ${target}: requires TRDP_HIGH_PERF_INDEXED")
        return()
    endif()

    if(TRDP_PROG_REQUIRE_UUID)
        if(NOT TRDP_HAVE_UUID)
            message(STATUS "Skipping ${target}: libuuid not found")
            return()
        endif()
    endif()

    if(NOT TRDP_PROG_SOURCES)
        message(FATAL_ERROR "trdp_add_program called without SOURCES for ${target}")
    endif()

    add_executable(${target} ${TRDP_PROG_SOURCES})
    target_link_libraries(${target} PRIVATE tcnopen::trdpap_shared)
    target_include_directories(${target} PRIVATE ${trdp_public_includes})
    target_compile_features(${target} PRIVATE c_std_99)
    target_compile_definitions(${target} PRIVATE ${trdp_common_compile_defs})
    if(trdp_common_compile_opts)
        target_compile_options(${target} PRIVATE ${trdp_common_compile_opts})
    endif()
    if(TRDP_PROG_LINK_LIBS)
        target_link_libraries(${target} PRIVATE ${TRDP_PROG_LINK_LIBS})
    endif()
    if(TRDP_PROG_REQUIRE_UUID)
        target_link_libraries(${target} PRIVATE ${TRDP_UUID_LIBRARY})
    endif()
    if(TRDP_PROG_CATEGORY)
        set_target_properties(${target} PROPERTIES FOLDER "${TRDP_PROG_CATEGORY}")
    endif()
endfunction()

if(TRDP_BUILD_EXAMPLES)
    set(_trdp_examples_category "examples")
    trdp_add_program(trdp_example_echo_callback
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/echoCallback.c
    )
    trdp_add_program(trdp_example_echo_polling
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/echoPolling.c
    )
    trdp_add_program(trdp_example_echo_trackside
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/echoTrackside.c
    )
    trdp_add_program(trdp_example_send_data
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/sendData.c
    )
    trdp_add_program(trdp_example_receive_hello
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/receiveHello.c
    )
    trdp_add_program(trdp_example_send_hello
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/sendHello.c
    )
    trdp_add_program(trdp_example_source_filter
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/sourceFilter/sourceFiltering.c
    )
    trdp_add_program(trdp_example_service_registry
        CATEGORY "${_trdp_examples_category}"
        SOURCES ${trdp_root}/example/SRM/serviceRegistrySample.c
    )
    trdp_add_program(trdp_example_taul_pd
        CATEGORY "${_trdp_examples_category}"
        REQUIRE_UUID
        SOURCES ${trdp_root}/example/TAUL_PD/taulApp_PD_sample.c
    )
endif()

if(TRDP_BUILD_TSN_EXAMPLES)
    set(_trdp_tsn_category "examples/TSN")
    trdp_add_program(trdp_example_tsn_receive
        CATEGORY "${_trdp_tsn_category}"
        REQUIRE_TSN
        SOURCES ${trdp_root}/example/TSN/receiveTSN.c
    )
    trdp_add_program(trdp_example_tsn_send
        CATEGORY "${_trdp_tsn_category}"
        REQUIRE_TSN
        SOURCES ${trdp_root}/example/TSN/sendTSN.c
    )
endif()

if(TRDP_BUILD_TESTS)
    set(_trdp_tests_category "tests")
    trdp_add_program(trdp_test_diverse_tau_tti
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/test_tau_tti.c
    )
    trdp_add_program(trdp_test_diverse_inaug
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/inaugTest.c
    )
    trdp_add_program(trdp_test_diverse_library
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/LibraryTests.c
    )
    trdp_add_program(trdp_test_diverse_md_length
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        SOURCES ${trdp_root}/test/diverse/mdDataLengthTest.c
    )
    trdp_add_program(trdp_test_diverse_get_stats
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/getStats.c
    )
    trdp_add_program(trdp_test_diverse_mc_receiver
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/MCreceiver.c
    )
    trdp_add_program(trdp_test_diverse_md_single
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        SOURCES ${trdp_root}/test/diverse/test_mdSingle.c
    )
    trdp_add_program(trdp_test_diverse_mem_sizes
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/test_memSizes.c
    )
    trdp_add_program(trdp_test_diverse_pd_responder
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/pd_responder.c
    )
    trdp_add_program(trdp_test_diverse_pd_mc_routing
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/pdMcRoutingTest.c
    )
    trdp_add_program(trdp_test_diverse_pd_pull
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/pdPull.c
    )
    trdp_add_program(trdp_test_diverse_sub
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/subTest.c
    )
    trdp_add_program(trdp_test_diverse_crc
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/crc-test.c
    )
    trdp_add_program(trdp_test_diverse_vos
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/vtest.c
    )
    trdp_add_program(trdp_test_diverse_traffic_shaping
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/test_trafficShaping.c
    )
    trdp_add_program(trdp_test_diverse_tau_dnr
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/diverse/test_tau_dnr.c
    )
    trdp_add_program(trdp_test_pd_patterns
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/pdpatterns/trdp-pd-test.c
    )
    trdp_add_program(trdp_test_marshalling
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/marshalling/test_marshalling.c
    )
    trdp_add_program(trdp_test_marshalling_2
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/marshalling/test_marshalling2.c
    )
    trdp_add_program(trdp_test_marshalling_stats
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/marshalling/getStatsMarshall.c
    )
    trdp_add_program(trdp_test_udp_md
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        REQUIRE_UUID
        SOURCES ${trdp_root}/test/udpmdcom/mdTest4.c
    )
    trdp_add_program(trdp_test_local_api
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/localtest/api_test.c
    )
    trdp_add_program(trdp_test_local_api2
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/localtest/api_test_2.c
    )
    trdp_add_program(trdp_test_local_api3
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/localtest/api_test_3.c
    )
    trdp_add_program(trdp_test_local_api4
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/localtest/api_test_4.c
    )
    trdp_add_program(trdp_test_ladder_md
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        REQUIRE_UUID
        SOURCES
            ${trdp_root}/test/laddermdtest/mdTestMain.c
            ${trdp_root}/test/laddermdtest/mdTestCaller.c
            ${trdp_root}/test/laddermdtest/mdTestReplier.c
            ${trdp_root}/test/laddermdtest/mdTestMdReceiveManager.c
            ${trdp_root}/test/laddermdtest/mdTestCommon.c
            ${trdp_root}/test/laddermdtest/mdTestLog.c
    )
    if(TARGET trdp_test_ladder_md)
        target_compile_definitions(trdp_test_ladder_md PRIVATE TRDP_OPTION_LADDER)
    endif()
    trdp_add_program(trdp_test_ladder_pd_subscriber
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/ladderpdtest/ladderApplication_subscriber.c
    )
    if(TARGET trdp_test_ladder_pd_subscriber)
        target_compile_definitions(trdp_test_ladder_pd_subscriber PRIVATE TRDP_OPTION_LADDER)
    endif()
    trdp_add_program(trdp_test_ladder_pd_publisher
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/ladderpdtest/ladderApplication_publisher.c
    )
    if(TARGET trdp_test_ladder_pd_publisher)
        target_compile_definitions(trdp_test_ladder_pd_publisher PRIVATE TRDP_OPTION_LADDER)
    endif()
    trdp_add_program(trdp_test_ladder_pd_multi
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/ladderpdtest/ladderApplication_multiPD.c
    )
    if(TARGET trdp_test_ladder_pd_multi)
        target_compile_definitions(trdp_test_ladder_pd_multi PRIVATE TRDP_OPTION_LADDER)
    endif()
    trdp_add_program(trdp_test_md_patterns
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        SOURCES ${trdp_root}/test/mdpatterns/trdp-md-test.c
    )
    trdp_add_program(trdp_test_md_pattern_replier
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        SOURCES ${trdp_root}/test/mdpatterns/rep-testreplier.c
    )
    trdp_add_program(trdp_test_md_pattern_caller
        CATEGORY "${_trdp_tests_category}"
        REQUIRE_MD
        SOURCES ${trdp_root}/test/mdpatterns/rep-testcaller.c
    )
    trdp_add_program(trdp_test_xml_pd
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/xml/trdp-xmlpd-test.c
    )
    trdp_add_program(trdp_test_xml_print
        CATEGORY "${_trdp_tests_category}"
        SOURCES ${trdp_root}/test/xml/trdp-xmlprint-test.c
    )
endif()

if(TRDP_BUILD_HIGH_PERF_TESTS)
    set(_trdp_hp_category "tests/high-performance")
    trdp_add_program(trdp_test_pd_patterns_fast
        CATEGORY "${_trdp_hp_category}"
        REQUIRE_HIGH_PERF
        SOURCES ${trdp_root}/test/pdpatterns/trdp-pd-test-fast.c
    )
    trdp_add_program(trdp_test_md_patterns_fast
        CATEGORY "${_trdp_hp_category}"
        REQUIRE_HIGH_PERF
        REQUIRE_MD
        SOURCES ${trdp_root}/test/mdpatterns/trdp-md-test-fast.c
    )
    trdp_add_program(trdp_test_xml_pd_fast
        CATEGORY "${_trdp_hp_category}"
        REQUIRE_HIGH_PERF
        SOURCES ${trdp_root}/test/xml/trdp-xmlpd-test-fast.c
    )
endif()

install(TARGETS ${trdp_library_pairs}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(DIRECTORY src/api/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp FILES_MATCHING PATTERN "*.h")

file(READ "${trdp_root}/src/common/trdp_private.h" _trdp_private_header)
string(REGEX MATCH "#define[ \t]+TRDP_VERSION[ \t]+([0-9]+)" _trdp_version_match "${_trdp_private_header}")
set(TRDP_VERSION_MAJOR "${CMAKE_MATCH_1}")
string(REGEX MATCH "#define[ \t]+TRDP_RELEASE[ \t]+([0-9]+)" _trdp_release_match "${_trdp_private_header}")
set(TRDP_VERSION_RELEASE "${CMAKE_MATCH_1}")
if(TRDP_VERSION_MAJOR AND TRDP_VERSION_RELEASE)
    set(TRDP_SOURCE_VERSION "${TRDP_VERSION_MAJOR}.${TRDP_VERSION_RELEASE}")
else()
    set(TRDP_SOURCE_VERSION "unknown")
endif()
unset(_trdp_private_header)
unset(_trdp_version_match)
unset(_trdp_release_match)

set(_trdp_default_flint "flint")
if(DEFINED ENV{FLINT} AND NOT "$ENV{FLINT}" STREQUAL "")
    set(_trdp_default_flint "$ENV{FLINT}")
endif()
set(TRDP_FLINT_COMMAND "${_trdp_default_flint}" CACHE STRING "FLINT command used for TRDP linting")
unset(_trdp_default_flint)

set(_trdp_default_rule_dir "")
if(DEFINED ENV{LINT_RULE_DIR} AND NOT "$ENV{LINT_RULE_DIR}" STREQUAL "")
    file(TO_CMAKE_PATH "$ENV{LINT_RULE_DIR}" _trdp_default_rule_dir)
    string(REGEX REPLACE "/$" "" _trdp_default_rule_dir "${_trdp_default_rule_dir}")
endif()
set(TRDP_LINT_RULE_DIR "${_trdp_default_rule_dir}" CACHE PATH "Directory containing TRDP lint rule files")
unset(_trdp_default_rule_dir)
set(TRDP_LINT_EXTRA_ARGS "" CACHE STRING "Additional arguments forwarded to the TRDP lint command")

set(TRDP_RUN_LINT_SCRIPT "${CMAKE_SOURCE_DIR}/cmake/RunLint.cmake")
set(TRDP_LINT_DIR "${CMAKE_CURRENT_BINARY_DIR}/lint")
set(TRDP_LINT_OUTPUT "${TRDP_LINT_DIR}/final.lint")

set(trdp_lint_args +v)
if(TRDP_LINT_RULE_DIR)
    list(APPEND trdp_lint_args "-i${TRDP_LINT_RULE_DIR}")
    list(APPEND trdp_lint_args "${TRDP_LINT_RULE_DIR}/co-gcc.lnt")
endif()

set(trdp_lint_include_dirs ${trdp_public_includes})
list(REMOVE_DUPLICATES trdp_lint_include_dirs)
foreach(include_dir IN LISTS trdp_lint_include_dirs)
    if(IS_ABSOLUTE "${include_dir}")
        set(_lint_dir "${include_dir}")
    else()
        set(_lint_dir "${trdp_root}/${include_dir}")
    endif()
    list(APPEND trdp_lint_args "-i${_lint_dir}")
endforeach()
unset(_lint_dir)

list(APPEND trdp_lint_args "-D${TRDP_TARGET_OS}")
if(TRDP_TARGET_VOS STREQUAL "posix")
    list(APPEND trdp_lint_args "-DPOSIX")
endif()
if(TRDP_MD_SUPPORT)
    list(APPEND trdp_lint_args "-DMD_SUPPORT=1")
else()
    list(APPEND trdp_lint_args "-DMD_SUPPORT=0")
endif()
if(TRDP_SOA_SUPPORT)
    list(APPEND trdp_lint_args "-DSOA_SUPPORT")
endif()
if(TRDP_TSN_SUPPORT)
    list(APPEND trdp_lint_args "-DTSN_SUPPORT")
endif()
if(TRDP_RT_THREADS)
    list(APPEND trdp_lint_args "-DRT_THREADS")
endif()
if(TRDP_DEBUG)
    list(APPEND trdp_lint_args "-DDEBUG")
else()
    list(APPEND trdp_lint_args "-DNO_DEBUG")
endif()
list(APPEND trdp_lint_args "-w3" "-e655" "-summary" "-u")

if(TRDP_LINT_EXTRA_ARGS)
    separate_arguments(_trdp_extra_lint_args NATIVE_COMMAND "${TRDP_LINT_EXTRA_ARGS}")
    list(APPEND trdp_lint_args ${_trdp_extra_lint_args})
    unset(_trdp_extra_lint_args)
endif()

set(trdp_lint_sources ${trdp_core_sources} ${trdp_optional_sources} ${trdp_high_perf_sources})
list(REMOVE_DUPLICATES trdp_lint_sources)
set(TRDP_LINT_ABSOLUTE_SOURCES)
foreach(src IN LISTS trdp_lint_sources)
    if(IS_ABSOLUTE "${src}")
        set(_abs_src "${src}")
    else()
        set(_abs_src "${trdp_root}/${src}")
    endif()
    if(EXISTS "${_abs_src}")
        list(APPEND TRDP_LINT_ABSOLUTE_SOURCES "${_abs_src}")
    endif()
endforeach()
unset(_abs_src)
list(SORT TRDP_LINT_ABSOLUTE_SOURCES)
list(JOIN trdp_lint_args " " TRDP_LINT_ARGS_STRING)
list(JOIN TRDP_LINT_ABSOLUTE_SOURCES " " TRDP_LINT_SOURCE_STRING)

add_custom_command(
    OUTPUT ${TRDP_LINT_OUTPUT}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${TRDP_LINT_DIR}
    COMMAND ${CMAKE_COMMAND}
        -DOUTPUT=${TRDP_LINT_OUTPUT}
        -DFLINT_CMD=${TRDP_FLINT_COMMAND}
        -DFLINT_ARGS=${TRDP_LINT_ARGS_STRING}
        -DSOURCES="${TRDP_LINT_SOURCE_STRING}"
        -P ${TRDP_RUN_LINT_SCRIPT}
    DEPENDS ${TRDP_LINT_ABSOLUTE_SOURCES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Running TRDP lint"
    VERBATIM
)

add_custom_target(trdp_lint DEPENDS ${TRDP_LINT_OUTPUT})

if(TRDP_BUILD_WIRESHARK_PLUGIN)
    add_subdirectory(spy/src/trdp_spy)
endif()

find_program(TRDP_DOXYGEN_COMMAND doxygen)
if(TRDP_DOXYGEN_COMMAND STREQUAL "TRDP_DOXYGEN_COMMAND-NOTFOUND")
    set(TRDP_DOXYGEN_COMMAND "")
endif()
find_program(TRDP_MAKE_COMMAND NAMES make gmake)
if(TRDP_MAKE_COMMAND STREQUAL "TRDP_MAKE_COMMAND-NOTFOUND")
    set(TRDP_MAKE_COMMAND "")
endif()

set(TRDP_REFERENCE_PDF "${trdp_root}/doc/latex/refman.pdf")
set(TRDP_REFERENCE_MANUAL "${trdp_root}/doc/TCN-TRDP2-D-BOM-033-xx - TRDP Reference Manual.pdf")

add_custom_target(doc
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${trdp_root}
        -DDOXYGEN_CMD=${TRDP_DOXYGEN_COMMAND}
        -DMAKE_CMD=${TRDP_MAKE_COMMAND}
        -DPDF_OUTPUT=${TRDP_REFERENCE_PDF}
        -DPDF_DESTINATION=${TRDP_REFERENCE_MANUAL}
        -P ${CMAKE_SOURCE_DIR}/cmake/RunTrdpDoc.cmake
    BYPRODUCTS ${TRDP_REFERENCE_PDF} ${TRDP_REFERENCE_MANUAL}
    COMMENT "Building TRDP documentation"
    USES_TERMINAL
)

find_program(TRDP_TAR_COMMAND tar)
if(TRDP_TAR_COMMAND STREQUAL "TRDP_TAR_COMMAND-NOTFOUND")
    set(TRDP_TAR_COMMAND "")
endif()

set(TRDP_DIST_DIR "${CMAKE_CURRENT_BINARY_DIR}/dist")
set(TRDP_DIST_DEBIAN "${TRDP_DIST_DIR}/libtrdp_${TRDP_SOURCE_VERSION}.debian.tar.xz")
set(TRDP_DIST_ORIG "${TRDP_DIST_DIR}/libtrdp_${TRDP_SOURCE_VERSION}.orig.tar.xz")

add_custom_target(dist
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${trdp_root}
        -DTOP_SOURCE_DIR=${CMAKE_SOURCE_DIR}
        -DOUTPUT_DIR=${TRDP_DIST_DIR}
        -DDIST_DEBIAN=${TRDP_DIST_DEBIAN}
        -DDIST_ORIG=${TRDP_DIST_ORIG}
        -DSRC_VERSION=${TRDP_SOURCE_VERSION}
        -DTAR_CMD=${TRDP_TAR_COMMAND}
        -P ${CMAKE_SOURCE_DIR}/cmake/RunTrdpDist.cmake
    BYPRODUCTS ${TRDP_DIST_DEBIAN} ${TRDP_DIST_ORIG}
    COMMENT "Creating TRDP distribution archives"
    USES_TERMINAL
)

find_program(TRDP_DEBUILD_COMMAND debuild)
if(TRDP_DEBUILD_COMMAND STREQUAL "TRDP_DEBUILD_COMMAND-NOTFOUND")
    set(TRDP_DEBUILD_COMMAND "")
endif()

set(TRDP_DEB_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/pkg")

add_custom_target(bindeb-pkg
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${trdp_root}
        -DOUTPUT_DIR=${TRDP_DEB_OUTPUT_DIR}
        -DDEBUILD_CMD=${TRDP_DEBUILD_COMMAND}
        -DSRC_VERSION=${TRDP_SOURCE_VERSION}
        -P ${CMAKE_SOURCE_DIR}/cmake/RunBindebPkg.cmake
    COMMENT "Building TRDP Debian binary packages"
    USES_TERMINAL
)

add_custom_target(deb-pkg
    COMMAND ${CMAKE_COMMAND} -E echo "Building the source pkg is not yet available."
    COMMENT "Reporting TRDP source package status"
)
add_dependencies(deb-pkg bindeb-pkg)
