cmake_minimum_required(VERSION 3.16)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(cmake/TRDPVersion.cmake)
trdp_parse_version("${CMAKE_CURRENT_SOURCE_DIR}/src/common/trdp_private.h")

project(TRDP VERSION "${TRDP_VERSION_VALUE}.${TRDP_RELEASE_VALUE}.${TRDP_UPDATE_VALUE}" LANGUAGES C)

include(GNUInstallDirs)
include(CMakeDependentOption)
include(CMakePackageConfigHelpers)

set(TRDP_TARGET_OS "LINUX" CACHE STRING "Value passed to -D<OS> for compatibility with the legacy Makefiles")
set(TRDP_TARGET_VOS "posix" CACHE STRING "Name of the VOS backend directory under src/vos")
set(TRDP_ARCH "linux-x86_64" CACHE STRING "Architecture suffix that becomes part of the output directory layout")
set(TRDP_ENDIANNESS "L_ENDIAN" CACHE STRING "Endian macro propagated to dependents")

option(TRDP_MD_SUPPORT "Enable Message Data (MD) support" ON)
cmake_dependent_option(TRDP_SOA_SUPPORT "Enable Service Oriented Architecture helpers" OFF "TRDP_MD_SUPPORT" OFF)
option(TRDP_TSN_SUPPORT "Build with Time Sensitive Networking helpers" OFF)
option(TRDP_RT_THREADS "Enable RT_THREADS scheduling flag" OFF)
option(TRDP_FULL_BUILD "Bundle optional TAU helpers directly into libtrdp" OFF)
option(TRDP_HIGH_PERF_INDEXED "Compile the default libraries with HIGH_PERF_INDEXED" OFF)
option(TRDP_HIGH_PERF_BASE2 "Use base-2 index table for HIGH_PERF_INDEXED" OFF)
option(TRDP_BUILD_HIGH_PERF_VARIANT "Emit separate high-performance libraries" OFF)
option(TRDP_BUILD_SHARED "Build shared libraries in addition to static archives" ON)
option(TRDP_BUILD_EXAMPLES "Build example applications" ON)
if(TRDP_TSN_SUPPORT)
    set(_trdp_default_tsn_examples ON)
else()
    set(_trdp_default_tsn_examples OFF)
endif()
option(TRDP_BUILD_TSN_EXAMPLES "Build the TSN demo applications" ${_trdp_default_tsn_examples})
option(TRDP_BUILD_TESTS "Build regression / lab test utilities" ON)
option(TRDP_BUILD_XML_TOOLS "Build XML helper applications" ON)
option(TRDP_BUILD_LOCAL_TESTS "Build the local API loopback tests" ON)
option(TRDP_BUILD_MARSHALLING_TOOLS "Build marshalling demonstration binaries" ON)
option(TRDP_USE_UUID "Link against libuuid and define HAS_UUID" ON)

if(TRDP_HIGH_PERF_BASE2 AND NOT (TRDP_HIGH_PERF_INDEXED OR TRDP_BUILD_HIGH_PERF_VARIANT))
    message(FATAL_ERROR "TRDP_HIGH_PERF_BASE2 requires either TRDP_HIGH_PERF_INDEXED or TRDP_BUILD_HIGH_PERF_VARIANT")
endif()

set(TRDP_VOS_RELATIVE_PATH "src/vos/${TRDP_TARGET_VOS}")
set(TRDP_VOS_ABSOLUTE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${TRDP_VOS_RELATIVE_PATH}")
if(NOT IS_DIRECTORY "${TRDP_VOS_ABSOLUTE_PATH}")
    message(FATAL_ERROR "Unknown VOS backend '${TRDP_TARGET_VOS}'. Directory ${TRDP_VOS_ABSOLUTE_PATH} is missing.")
endif()

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(TRDP_BUILD_ROOT "${CMAKE_BINARY_DIR}/bld/output")
set(TRDP_BASE_DIR "$<IF:$<CONFIG:Debug>,${TRDP_ARCH}-dbg,${TRDP_ARCH}-rel>")
foreach(type ARCHIVE LIBRARY RUNTIME)
    set(CMAKE_${type}_OUTPUT_DIRECTORY "${TRDP_BUILD_ROOT}/${TRDP_BASE_DIR}")
endforeach()
set(TRDP_HP_DIR "$<IF:$<CONFIG:Debug>,${TRDP_ARCH}-hp-dbg,${TRDP_ARCH}-hp-rel>")
set(TRDP_HP_OUTPUT_DIRECTORY "${TRDP_BUILD_ROOT}/${TRDP_HP_DIR}")

find_package(Threads REQUIRED)
set(TRDP_PLATFORM_LIBS Threads::Threads m)
if(UNIX AND NOT APPLE)
    list(APPEND TRDP_PLATFORM_LIBS rt)
endif()
set(TRDP_HAS_UUID FALSE)
set(TRDP_UUID_INCLUDE_DIR "")
if(TRDP_USE_UUID)
    find_library(TRDP_UUID_LIBRARY uuid)
    find_path(TRDP_UUID_INCLUDE_DIR uuid.h PATH_SUFFIXES uuid)
    if(TRDP_UUID_LIBRARY AND TRDP_UUID_INCLUDE_DIR)
        set(TRDP_HAS_UUID TRUE)
        list(APPEND TRDP_PLATFORM_LIBS "${TRDP_UUID_LIBRARY}")
    else()
        message(WARNING "libuuid requested but not found. Continuing without HAS_UUID.")
    endif()
endif()

if(TRDP_MD_SUPPORT)
    set(TRDP_MD_SUPPORT_INT 1)
else()
    set(TRDP_MD_SUPPORT_INT 0)
endif()

set(TRDP_PUBLIC_INCLUDE_DIRS
    ${CMAKE_CURRENT_SOURCE_DIR}/src/api
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common
    ${CMAKE_CURRENT_SOURCE_DIR}/src/vos/api
    ${CMAKE_CURRENT_SOURCE_DIR}/src/vos/common
    ${TRDP_VOS_ABSOLUTE_PATH}
)
if(TRDP_HAS_UUID)
    list(APPEND TRDP_PUBLIC_INCLUDE_DIRS ${TRDP_UUID_INCLUDE_DIR})
endif()

set(TRDP_BUILD_INTERFACE_INCLUDES)
foreach(dir IN LISTS TRDP_PUBLIC_INCLUDE_DIRS)
    list(APPEND TRDP_BUILD_INTERFACE_INCLUDES $<BUILD_INTERFACE:${dir}>)
endforeach()

set(TRDP_INSTALL_INCLUDE_DIRS
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/trdp/api>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/trdp/common>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/trdp/vos/api>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/trdp/vos/common>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/trdp/vos/${TRDP_TARGET_VOS}>
)

set(TRDP_INTERFACE_DEFINES
    ${TRDP_TARGET_OS}
    ${TRDP_ENDIANNESS}
    MD_SUPPORT=${TRDP_MD_SUPPORT_INT}
)
if(TRDP_HAS_UUID)
    list(APPEND TRDP_INTERFACE_DEFINES HAS_UUID)
endif()
if(TRDP_TSN_SUPPORT)
    list(APPEND TRDP_INTERFACE_DEFINES TSN_SUPPORT)
endif()
if(TRDP_RT_THREADS)
    list(APPEND TRDP_INTERFACE_DEFINES RT_THREADS)
endif()
if(TRDP_SOA_SUPPORT)
    list(APPEND TRDP_INTERFACE_DEFINES SOA_SUPPORT)
endif()
if(TRDP_HIGH_PERF_INDEXED)
    list(APPEND TRDP_INTERFACE_DEFINES HIGH_PERF_INDEXED)
    if(TRDP_HIGH_PERF_BASE2)
        list(APPEND TRDP_INTERFACE_DEFINES HIGH_PERF_BASE2)
    endif()
endif()
list(APPEND TRDP_INTERFACE_DEFINES POSIX _GNU_SOURCE)

set(TRDP_WARNING_FLAGS
    -Wall -Wextra -Wno-unknown-pragmas -Wno-unused-label
    -Wno-unused-function -Wno-address-of-packed-member
)

set(TRDP_CORE_SOURCES
    src/common/trdp_pdcom.c
    src/common/trdp_utils.c
    src/common/tlp_if.c
    src/common/tlc_if.c
    src/common/trdp_stats.c
    src/vos/common/vos_mem.c
    src/vos/common/vos_utils.c
    ${TRDP_VOS_RELATIVE_PATH}/vos_sock.c
    ${TRDP_VOS_RELATIVE_PATH}/vos_thread.c
)
if(EXISTS "${TRDP_VOS_ABSOLUTE_PATH}/vos_shared_mem.c")
    list(APPEND TRDP_CORE_SOURCES ${TRDP_VOS_RELATIVE_PATH}/vos_shared_mem.c)
endif()
if(TRDP_MD_SUPPORT)
    list(APPEND TRDP_CORE_SOURCES
        src/common/trdp_mdcom.c
        src/common/tlm_if.c
    )
endif()
if(TRDP_TSN_SUPPORT)
    if(EXISTS "${TRDP_VOS_ABSOLUTE_PATH}/vos_sockTSN.c")
        list(APPEND TRDP_CORE_SOURCES ${TRDP_VOS_RELATIVE_PATH}/vos_sockTSN.c)
    else()
        message(FATAL_ERROR "TSN support requested but ${TRDP_VOS_RELATIVE_PATH}/vos_sockTSN.c is missing")
    endif()
endif()
if(TRDP_HIGH_PERF_INDEXED)
    list(APPEND TRDP_CORE_SOURCES src/common/trdp_pdindex.c)
endif()

set(TRDP_OPTIONAL_SOURCES
    src/common/trdp_xml.c
    src/common/tau_xml.c
    src/common/tau_marshall.c
    src/common/tau_dnr.c
    src/common/tau_tti.c
    src/common/tau_cstinfo.c
    src/common/tau_ctrl.c
    src/common/tau_xsession.c
    src/common/tau_xmarshall.c
)
if(TRDP_MD_SUPPORT AND TRDP_SOA_SUPPORT)
    list(APPEND TRDP_OPTIONAL_SOURCES src/common/tau_so_if.c)
endif()

add_library(trdp_core_objects OBJECT ${TRDP_CORE_SOURCES})
target_compile_features(trdp_core_objects PRIVATE c_std_99)
target_include_directories(trdp_core_objects PRIVATE ${TRDP_PUBLIC_INCLUDE_DIRS})
target_compile_definitions(trdp_core_objects PRIVATE ${TRDP_INTERFACE_DEFINES})
target_compile_options(trdp_core_objects PRIVATE ${TRDP_WARNING_FLAGS})
target_link_libraries(trdp_core_objects PRIVATE Threads::Threads)

add_library(trdp_optional_objects OBJECT ${TRDP_OPTIONAL_SOURCES})
target_compile_features(trdp_optional_objects PRIVATE c_std_99)
target_include_directories(trdp_optional_objects PRIVATE ${TRDP_PUBLIC_INCLUDE_DIRS})
target_compile_definitions(trdp_optional_objects PRIVATE ${TRDP_INTERFACE_DEFINES})
target_compile_options(trdp_optional_objects PRIVATE ${TRDP_WARNING_FLAGS})
target_link_libraries(trdp_optional_objects PRIVATE Threads::Threads)

add_library(trdp STATIC $<TARGET_OBJECTS:trdp_core_objects>)
if(TRDP_FULL_BUILD)
    target_sources(trdp PRIVATE $<TARGET_OBJECTS:trdp_optional_objects>)
endif()
set_target_properties(trdp PROPERTIES OUTPUT_NAME trdp)
target_include_directories(trdp
    PUBLIC
        ${TRDP_BUILD_INTERFACE_INCLUDES}
        ${TRDP_INSTALL_INCLUDE_DIRS}
)
target_compile_definitions(trdp PUBLIC ${TRDP_INTERFACE_DEFINES})
target_link_libraries(trdp PUBLIC ${TRDP_PLATFORM_LIBS})
add_library(TRDP::trdp ALIAS trdp)

set(TRDP_TRDPAP_OBJECTS $<TARGET_OBJECTS:trdp_core_objects> $<TARGET_OBJECTS:trdp_optional_objects>)
add_library(trdpap STATIC ${TRDP_TRDPAP_OBJECTS})
set_target_properties(trdpap PROPERTIES OUTPUT_NAME trdpap)
target_include_directories(trdpap
    PUBLIC
        ${TRDP_BUILD_INTERFACE_INCLUDES}
        ${TRDP_INSTALL_INCLUDE_DIRS}
)
target_compile_definitions(trdpap PUBLIC ${TRDP_INTERFACE_DEFINES})
target_link_libraries(trdpap PUBLIC ${TRDP_PLATFORM_LIBS})
add_library(TRDP::trdpap ALIAS trdpap)

set(TRDP_SO_VERSION "${TRDP_VERSION_VALUE}.${TRDP_RELEASE_VALUE}")
if(TRDP_BUILD_SHARED)
    add_library(trdp_shared SHARED $<TARGET_OBJECTS:trdp_core_objects>)
    if(TRDP_FULL_BUILD)
        target_sources(trdp_shared PRIVATE $<TARGET_OBJECTS:trdp_optional_objects>)
    endif()
    set_target_properties(trdp_shared PROPERTIES
        OUTPUT_NAME trdp
        VERSION ${TRDP_SO_VERSION}
        SOVERSION ${TRDP_VERSION_VALUE}
    )
    target_include_directories(trdp_shared
        PUBLIC
            ${TRDP_BUILD_INTERFACE_INCLUDES}
            ${TRDP_INSTALL_INCLUDE_DIRS}
    )
    target_compile_definitions(trdp_shared PUBLIC ${TRDP_INTERFACE_DEFINES})
    target_link_libraries(trdp_shared PUBLIC ${TRDP_PLATFORM_LIBS})
    add_library(TRDP::trdp_shared ALIAS trdp_shared)

    add_library(tau_shared SHARED $<TARGET_OBJECTS:trdp_optional_objects>)
    set_target_properties(tau_shared PROPERTIES
        OUTPUT_NAME tau
        VERSION ${TRDP_SO_VERSION}
        SOVERSION ${TRDP_VERSION_VALUE}
    )
    target_include_directories(tau_shared
        PUBLIC
            ${TRDP_BUILD_INTERFACE_INCLUDES}
            ${TRDP_INSTALL_INCLUDE_DIRS}
    )
    target_compile_definitions(tau_shared PUBLIC ${TRDP_INTERFACE_DEFINES})
    target_link_libraries(tau_shared PUBLIC trdp_shared)
    add_library(TRDP::tau_shared ALIAS tau_shared)
endif()

if(TRDP_BUILD_HIGH_PERF_VARIANT)
    set(TRDP_HP_SOURCES ${TRDP_CORE_SOURCES})
    list(FIND TRDP_HP_SOURCES "src/common/trdp_pdindex.c" _hp_index_pos)
    if(_hp_index_pos EQUAL -1)
        list(APPEND TRDP_HP_SOURCES src/common/trdp_pdindex.c)
    endif()
    add_library(trdp_hp_objects OBJECT ${TRDP_HP_SOURCES})
    target_compile_features(trdp_hp_objects PRIVATE c_std_99)
    target_include_directories(trdp_hp_objects PRIVATE ${TRDP_PUBLIC_INCLUDE_DIRS})
    target_compile_definitions(trdp_hp_objects PRIVATE ${TRDP_INTERFACE_DEFINES} HIGH_PERF_INDEXED)
    if(TRDP_HIGH_PERF_BASE2)
        target_compile_definitions(trdp_hp_objects PRIVATE HIGH_PERF_BASE2)
    endif()
    target_compile_options(trdp_hp_objects PRIVATE ${TRDP_WARNING_FLAGS})
    target_link_libraries(trdp_hp_objects PRIVATE Threads::Threads)

    add_library(trdp_hp STATIC $<TARGET_OBJECTS:trdp_hp_objects>)
    set_target_properties(trdp_hp PROPERTIES OUTPUT_NAME trdp-hp)
    target_include_directories(trdp_hp
        PUBLIC
            ${TRDP_BUILD_INTERFACE_INCLUDES}
            ${TRDP_INSTALL_INCLUDE_DIRS}
    )
    target_compile_definitions(trdp_hp PUBLIC ${TRDP_INTERFACE_DEFINES} HIGH_PERF_INDEXED)
    if(TRDP_HIGH_PERF_BASE2)
        target_compile_definitions(trdp_hp PUBLIC HIGH_PERF_BASE2)
    endif()
    target_link_libraries(trdp_hp PUBLIC ${TRDP_PLATFORM_LIBS})
    set_target_properties(trdp_hp PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
        LIBRARY_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
        RUNTIME_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
    )

    if(TRDP_BUILD_SHARED)
        add_library(trdp_hp_shared SHARED $<TARGET_OBJECTS:trdp_hp_objects>)
        set_target_properties(trdp_hp_shared PROPERTIES
            OUTPUT_NAME trdp-hp
            VERSION ${TRDP_SO_VERSION}
            SOVERSION ${TRDP_VERSION_VALUE}
            ARCHIVE_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
            LIBRARY_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
            RUNTIME_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
        )
        target_include_directories(trdp_hp_shared
            PUBLIC
                ${TRDP_BUILD_INTERFACE_INCLUDES}
                ${TRDP_INSTALL_INCLUDE_DIRS}
        )
        target_compile_definitions(trdp_hp_shared PUBLIC ${TRDP_INTERFACE_DEFINES} HIGH_PERF_INDEXED)
        if(TRDP_HIGH_PERF_BASE2)
            target_compile_definitions(trdp_hp_shared PUBLIC HIGH_PERF_BASE2)
        endif()
        target_link_libraries(trdp_hp_shared PUBLIC ${TRDP_PLATFORM_LIBS})

        add_library(tau_hp_shared SHARED $<TARGET_OBJECTS:trdp_optional_objects>)
        set_target_properties(tau_hp_shared PROPERTIES
            OUTPUT_NAME tau-hp
            VERSION ${TRDP_SO_VERSION}
            SOVERSION ${TRDP_VERSION_VALUE}
            ARCHIVE_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
            LIBRARY_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
            RUNTIME_OUTPUT_DIRECTORY "${TRDP_HP_OUTPUT_DIRECTORY}"
        )
        target_include_directories(tau_hp_shared
            PUBLIC
                ${TRDP_BUILD_INTERFACE_INCLUDES}
                ${TRDP_INSTALL_INCLUDE_DIRS}
        )
        target_compile_definitions(tau_hp_shared PUBLIC ${TRDP_INTERFACE_DEFINES} HIGH_PERF_INDEXED)
        if(TRDP_HIGH_PERF_BASE2)
            target_compile_definitions(tau_hp_shared PUBLIC HIGH_PERF_BASE2)
        endif()
        target_link_libraries(tau_hp_shared PUBLIC trdp_hp_shared)
    endif()
endif()

function(trdp_add_app target)
    set(options NEEDS_UUID)
    set(oneValueArgs LIBRARY OUTPUT_NAME)
    set(multiValueArgs SOURCES OPTIONS)
    cmake_parse_arguments(APP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    if(APP_NEEDS_UUID AND NOT TRDP_HAS_UUID)
        message(STATUS "Skipping ${target}: libuuid not available")
        return()
    endif()
    if(NOT APP_SOURCES)
        message(FATAL_ERROR "trdp_add_app(${target}) requires SOURCES")
    endif()
    set(link_lib TRDP::trdp)
    if(APP_LIBRARY)
        set(link_lib ${APP_LIBRARY})
    endif()
    add_executable(${target} ${APP_SOURCES})
    if(APP_OUTPUT_NAME)
        set_target_properties(${target} PROPERTIES OUTPUT_NAME ${APP_OUTPUT_NAME})
    endif()
    target_include_directories(${target} PRIVATE ${TRDP_PUBLIC_INCLUDE_DIRS})
    target_compile_definitions(${target} PRIVATE ${TRDP_INTERFACE_DEFINES})
    target_compile_options(${target} PRIVATE ${TRDP_WARNING_FLAGS})
    if(APP_OPTIONS)
        target_compile_options(${target} PRIVATE ${APP_OPTIONS})
    endif()
    target_link_libraries(${target} PRIVATE ${link_lib} ${TRDP_PLATFORM_LIBS})
endfunction()

if(TRDP_BUILD_EXAMPLES)
    trdp_add_app(echoCallback SOURCES example/echoCallback.c)
    trdp_add_app(echoTrackside SOURCES example/echoTrackside.c)
    trdp_add_app(sourceFiltering SOURCES example/sourceFilter/sourceFiltering.c)
    trdp_add_app(receivePolling SOURCES example/echoPolling.c)
    trdp_add_app(receiveHello SOURCES example/receiveHello.c)
    trdp_add_app(sendHello SOURCES example/sendHello.c)
    trdp_add_app(sendData SOURCES example/sendData.c)
    if(TRDP_MD_SUPPORT)
        set(_trdp_md_manager "${CMAKE_CURRENT_SOURCE_DIR}/example/mdManager.c")
        if(EXISTS "${_trdp_md_manager}")
            trdp_add_app(mdManager SOURCES example/mdManager.c NEEDS_UUID)
        else()
            message(STATUS "Skipping mdManager example: ${_trdp_md_manager} not available")
        endif()
    endif()
endif()

if(TRDP_TSN_SUPPORT AND TRDP_BUILD_TSN_EXAMPLES)
    trdp_add_app(sendTSN SOURCES example/TSN/sendTSN.c)
    trdp_add_app(receiveTSN SOURCES example/TSN/receiveTSN.c)
endif()

if(TRDP_BUILD_TESTS)
    trdp_add_app(getStats SOURCES test/diverse/getStats.c)
    trdp_add_app(vostest SOURCES test/diverse/LibraryTests.c)
    trdp_add_app(MCreceiver SOURCES test/diverse/MCreceiver.c)
    trdp_add_app(inaugTest SOURCES test/diverse/inaugTest.c)
    trdp_add_app(pd_responder SOURCES test/diverse/pd_responder.c)
    trdp_add_app(testSub SOURCES test/diverse/subTest.c)
    trdp_add_app(pdPull SOURCES test/diverse/pdPull.c)
    trdp_add_app(pdMcRouting SOURCES test/diverse/pdMcRoutingTest.c)
    trdp_add_app(trdp_pd_test SOURCES test/pdpatterns/trdp-pd-test.c OUTPUT_NAME trdp-pd-test)
    if(TRDP_HIGH_PERF_INDEXED)
        trdp_add_app(trdp_pd_test_fast SOURCES test/pdpatterns/trdp-pd-test-fast.c OUTPUT_NAME trdp-pd-test-fast)
    endif()
    if(TRDP_MD_SUPPORT)
        trdp_add_app(test_mdSingle SOURCES test/diverse/test_mdSingle.c)
        trdp_add_app(mdDataLength SOURCES test/diverse/mdDataLengthTest.c)
        trdp_add_app(trdp_md_test SOURCES test/mdpatterns/trdp-md-test.c OUTPUT_NAME trdp-md-test)
        trdp_add_app(trdp_md_test_fast SOURCES test/mdpatterns/trdp-md-test-fast.c OUTPUT_NAME trdp-md-test-fast)
        trdp_add_app(trdp_md_reptestcaller SOURCES test/mdpatterns/rep-testcaller.c OUTPUT_NAME trdp-md-reptestcaller)
        trdp_add_app(trdp_md_reptestreplier SOURCES test/mdpatterns/rep-testreplier.c OUTPUT_NAME trdp-md-reptestreplier)
        trdp_add_app(mdTest4 SOURCES test/udpmdcom/mdTest4.c)
    endif()
endif()

if(TRDP_BUILD_TESTS AND TRDP_BUILD_LOCAL_TESTS)
    trdp_add_app(localtest SOURCES test/localtest/api_test.c LIBRARY TRDP::trdpap OPTIONS -Wno-unused-variable)
    trdp_add_app(localtest2 SOURCES test/localtest/api_test_2.c LIBRARY TRDP::trdpap OPTIONS -Wno-unused-variable)
    trdp_add_app(localtest3 SOURCES test/localtest/api_test_3.c LIBRARY TRDP::trdpap OPTIONS -Wno-unused-variable)
    trdp_add_app(localtest4 SOURCES test/localtest/api_test_4.c LIBRARY TRDP::trdpap OPTIONS -Wno-unused-variable)
endif()

if(TRDP_BUILD_XML_TOOLS)
    trdp_add_app(trdp_xmlprint_test SOURCES test/xml/trdp-xmlprint-test.c LIBRARY TRDP::trdpap OUTPUT_NAME trdp-xmlprint-test)
    trdp_add_app(trdp_xmlpd_test SOURCES test/xml/trdp-xmlpd-test.c LIBRARY TRDP::trdpap OUTPUT_NAME trdp-xmlpd-test)
    if(TRDP_HIGH_PERF_INDEXED)
        trdp_add_app(trdp_xmlpd_test_fast SOURCES test/xml/trdp-xmlpd-test-fast.c LIBRARY TRDP::trdpap OUTPUT_NAME trdp-xmlpd-test-fast)
    endif()
endif()

if(TRDP_BUILD_MARSHALLING_TOOLS)
    trdp_add_app(test_marshalling SOURCES test/marshalling/test_marshalling.c LIBRARY TRDP::trdpap OPTIONS -Wno-unused-variable)
endif()

install(TARGETS
    trdp trdpap
    EXPORT TRDPTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
if(TRDP_BUILD_SHARED)
    install(TARGETS trdp_shared tau_shared
        EXPORT TRDPTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
endif()
if(TRDP_BUILD_HIGH_PERF_VARIANT)
    install(TARGETS trdp_hp
        EXPORT TRDPTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    if(TRDP_BUILD_SHARED)
        install(TARGETS trdp_hp_shared tau_hp_shared
            EXPORT TRDPTargets
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        )
    endif()
endif()

install(DIRECTORY src/api/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp/api FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
install(DIRECTORY src/common/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp/common FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
install(DIRECTORY src/vos/api/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp/vos/api FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
install(DIRECTORY src/vos/common/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp/vos/common FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
install(DIRECTORY ${TRDP_VOS_RELATIVE_PATH}/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/trdp/vos/${TRDP_TARGET_VOS} FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")

install(EXPORT TRDPTargets
    NAMESPACE TRDP::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/TRDP
)

configure_package_config_file(
    cmake/trdpConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/trdpConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/TRDP
)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/trdpConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/trdpConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/trdpConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/TRDP
)

export(EXPORT TRDPTargets NAMESPACE TRDP:: FILE ${CMAKE_CURRENT_BINARY_DIR}/TRDPTargets.cmake)
