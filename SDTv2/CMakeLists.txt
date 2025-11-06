cmake_minimum_required(VERSION 3.18)
project(SDTv2 LANGUAGES C)

set(SDTV2_SOURCES
    src/sdt_ipt.c
    src/sdt_mvb.c
    src/sdt_mutex.c
    src/sdt_uic.c
    src/sdt_validator.c
    src/sdt_wtb.c
)

set(SDTV2_VERSION_MAJOR 2)
set(SDTV2_VERSION_MINOR 4)
set(SDTV2_VERSION_PATCH 0)
set(SDTV2_DLU_SEQUENCE 1)
set(SDTV2_VERSION "${SDTV2_VERSION_MAJOR}.${SDTV2_VERSION_MINOR}.${SDTV2_VERSION_PATCH}")
set(SDTV2_DLU_VERSION "${SDTV2_VERSION}.${SDTV2_DLU_SEQUENCE}")

set(SDTV2_TARGET_OS "LINUX" CACHE STRING "Target operating system for SDTv2 artifacts")
set_property(CACHE SDTV2_TARGET_OS PROPERTY STRINGS LINUX ARM_TI VXWORKS INTEGRITY CSS)

set(SDTV2_OUTPUT_ROOT "${CMAKE_CURRENT_BINARY_DIR}/artifacts/${SDTV2_TARGET_OS}")

option(SDTV2_BUILD_LINUX_TESTS "Build the Linux unit test executables" OFF)
option(SDTV2_BUILD_CCUS_TESTS "Build the Integrity CCUS unit test executables" OFF)

set(SDTV2_LINUX_TEST_MULTILIB_FLAGS "-m32" CACHE STRING "Multilib flags used when building the Linux test executables")
set(SDTV2_LINUX_TEST_LIBRARY_VARIANT "static" CACHE STRING "SDTv2 library variant linked by the Linux test executables")
set_property(CACHE SDTV2_LINUX_TEST_LIBRARY_VARIANT PROPERTY STRINGS static shared)

option(SDTV2_ENABLE_IPT "Enable IPT protocol support" ON)
option(SDTV2_ENABLE_MVB "Enable MVB protocol support" ON)
option(SDTV2_ENABLE_WTB "Enable WTB protocol support" ON)
option(SDTV2_ENABLE_SECURE "Enable secure communication features" ON)
option(SDTV2_ENABLE_UNITTEST_LOGS "Enable unit test instrumentation and logging" OFF)

set(SDTV2_FEATURE_DEFINES)
if(SDTV2_ENABLE_IPT)
    list(APPEND SDTV2_FEATURE_DEFINES SDT_ENABLE_IPT)
endif()

if(SDTV2_ENABLE_MVB)
    list(APPEND SDTV2_FEATURE_DEFINES SDT_ENABLE_MVB)
endif()
if(SDTV2_ENABLE_WTB)
    list(APPEND SDTV2_FEATURE_DEFINES SDT_ENABLE_WTB)
endif()
if(SDTV2_ENABLE_SECURE)
    list(APPEND SDTV2_FEATURE_DEFINES SDT_SECURE)
endif()
if(SDTV2_ENABLE_UNITTEST_LOGS)
    list(APPEND SDTV2_FEATURE_DEFINES UNITTEST)
endif()

set(SDTV2_OS_DEFINES
    $<$<STREQUAL:${SDTV2_TARGET_OS},LINUX>:LINUX>
    $<$<STREQUAL:${SDTV2_TARGET_OS},ARM_TI>:ARM_TI>
    $<$<STREQUAL:${SDTV2_TARGET_OS},VXWORKS>:VXWORKS>
    $<$<STREQUAL:${SDTV2_TARGET_OS},INTEGRITY>:OS_INTEGRITY>
    $<$<STREQUAL:${SDTV2_TARGET_OS},CSS>:CSS>
)

add_library(sdtv2_static STATIC ${SDTV2_SOURCES})
add_library(tcnopen::sdtv2 ALIAS sdtv2_static)
add_library(tcnopen::sdtv2_static ALIAS sdtv2_static)

add_library(sdtv2_shared SHARED ${SDTV2_SOURCES})
add_library(tcnopen::sdtv2_shared ALIAS sdtv2_shared)

set(SDTV2_COMMON_INCLUDE_DIRS
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/api>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include/SDTv2>
)

foreach(sdtv2_target IN ITEMS sdtv2_static sdtv2_shared)
    target_include_directories(${sdtv2_target}
        PUBLIC
            ${SDTV2_COMMON_INCLUDE_DIRS}
    )
    target_compile_features(${sdtv2_target} PUBLIC c_std_99)
    target_compile_definitions(${sdtv2_target}
        PUBLIC
            ${SDTV2_FEATURE_DEFINES}
            ${SDTV2_OS_DEFINES}
    )
    set_target_properties(${sdtv2_target}
        PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}"
            LIBRARY_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}"
            RUNTIME_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}"
    )
endforeach()

set_target_properties(sdtv2_shared
    PROPERTIES
        OUTPUT_NAME libsdt
        VERSION "${SDTV2_VERSION}"
        SOVERSION "${SDTV2_VERSION_MAJOR}"
        POSITION_INDEPENDENT_CODE ON
)
set_target_properties(sdtv2_static
    PROPERTIES
        OUTPUT_NAME libsdt
)

if(NOT SDTV2_TARGET_OS STREQUAL "LINUX")
    set_target_properties(sdtv2_shared PROPERTIES EXCLUDE_FROM_ALL TRUE)
endif()

set(SDTV2_STATIC_ACTIVE_OS LINUX ARM_TI VXWORKS CSS)
if(NOT SDTV2_TARGET_OS IN_LIST SDTV2_STATIC_ACTIVE_OS)
    set_target_properties(sdtv2_static PROPERTIES EXCLUDE_FROM_ALL TRUE)
endif()

set(SDTV2_MAKEDLU_COMMAND "makedlu" CACHE STRING "makedlu command used for SDTv2 packaging")
set(SDTV2_FLINT_COMMAND "flint" CACHE STRING "FLINT command used for SDTv2 linting")
set(SDTV2_FLINT_ARGS "" CACHE STRING "Additional arguments forwarded to the SDTv2 lint command")
set(SDTV2_PACKAGE_DLU_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PackageDLU.cmake")
set(SDTV2_WRITE_MD5_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/WriteMD5.cmake")
set(SDTV2_RUN_LINT_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/RunLint.cmake")

if(SDTV2_TARGET_OS STREQUAL "LINUX")
    set(SDTV2_DLU_DIR "${SDTV2_OUTPUT_ROOT}/dl2")
    set(SDTV2_DLU_LIB_DIR "${SDTV2_DLU_DIR}/lib")
    set(SDTV2_DLU_FILENAME "sdtv2_${SDTV2_DLU_VERSION}.dl2")
    set(SDTV2_DLU_PATH "${SDTV2_DLU_DIR}/${SDTV2_DLU_FILENAME}")
    set(SDTV2_TAR_PATH "${SDTV2_DLU_DIR}/sdtv2.tar")
    set(SDTV2_PACKAGE_STAMP "${SDTV2_OUTPUT_ROOT}/sdtv2_linux_package.stamp")

    add_custom_command(
        OUTPUT ${SDTV2_PACKAGE_STAMP}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${SDTV2_OUTPUT_ROOT}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${SDTV2_DLU_LIB_DIR}
        COMMAND ${CMAKE_COMMAND} -E remove -f ${SDTV2_TAR_PATH} ${SDTV2_DLU_PATH} ${SDTV2_DLU_PATH}.md5 ${SDTV2_OUTPUT_ROOT}/${SDTV2_DLU_FILENAME} ${SDTV2_OUTPUT_ROOT}/${SDTV2_DLU_FILENAME}.md5
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:sdtv2_shared> ${SDTV2_DLU_LIB_DIR}/$<TARGET_FILE_NAME:sdtv2_shared>
        COMMAND ${CMAKE_COMMAND} -E rm -f ${SDTV2_DLU_LIB_DIR}/libsdt.so ${SDTV2_DLU_LIB_DIR}/libsdt.so.${SDTV2_VERSION_MAJOR}
        COMMAND ${CMAKE_COMMAND} -E chdir ${SDTV2_DLU_LIB_DIR} ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE_NAME:sdtv2_shared> libsdt.so.${SDTV2_VERSION_MAJOR}
        COMMAND ${CMAKE_COMMAND} -E chdir ${SDTV2_DLU_LIB_DIR} ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE_NAME:sdtv2_shared> libsdt.so
        COMMAND ${CMAKE_COMMAND} -E chdir ${SDTV2_DLU_DIR} ${CMAKE_COMMAND} -E tar cf ${SDTV2_TAR_PATH} lib
        COMMAND ${CMAKE_COMMAND} -DDLU_COMMAND=${SDTV2_MAKEDLU_COMMAND} -DDLU_DIR=${SDTV2_DLU_DIR} -DDLU_VERSION=${SDTV2_DLU_VERSION} -DDLU_FILENAME=${SDTV2_DLU_FILENAME} -DTAR_PATH=${SDTV2_TAR_PATH} -P ${SDTV2_PACKAGE_DLU_SCRIPT}
        COMMAND ${CMAKE_COMMAND} -DINPUT=$<TARGET_FILE:sdtv2_shared> -DOUTPUT=$<TARGET_FILE:sdtv2_shared>.md5 -P ${SDTV2_WRITE_MD5_SCRIPT}
        COMMAND ${CMAKE_COMMAND} -DINPUT=${SDTV2_DLU_PATH} -DOUTPUT=${SDTV2_DLU_PATH}.md5 -P ${SDTV2_WRITE_MD5_SCRIPT}
        COMMAND ${CMAKE_COMMAND} -E copy ${SDTV2_DLU_PATH} ${SDTV2_OUTPUT_ROOT}/${SDTV2_DLU_FILENAME}
        COMMAND ${CMAKE_COMMAND} -E copy ${SDTV2_DLU_PATH}.md5 ${SDTV2_OUTPUT_ROOT}/${SDTV2_DLU_FILENAME}.md5
        COMMAND ${CMAKE_COMMAND} -E touch ${SDTV2_PACKAGE_STAMP}
        DEPENDS sdtv2_shared
        BYPRODUCTS ${SDTV2_TAR_PATH} ${SDTV2_DLU_PATH} ${SDTV2_DLU_PATH}.md5 ${SDTV2_OUTPUT_ROOT}/${SDTV2_DLU_FILENAME} ${SDTV2_OUTPUT_ROOT}/${SDTV2_DLU_FILENAME}.md5
        COMMAND_EXPAND_LISTS
        COMMENT "Packaging SDTv2 Linux artifacts"
    )

    add_custom_target(sdtv2_linux_package DEPENDS ${SDTV2_PACKAGE_STAMP})
endif()

set(SDTV2_LINT_DIR "${CMAKE_CURRENT_BINARY_DIR}/lint")
set(SDTV2_LINT_OUTPUT "${SDTV2_LINT_DIR}/final.lint")

set(SDTV2_ABSOLUTE_SOURCES)
foreach(src IN LISTS SDTV2_SOURCES)
    list(APPEND SDTV2_ABSOLUTE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
endforeach()
list(JOIN SDTV2_ABSOLUTE_SOURCES " " SDTV2_LINT_SOURCE_STRING)

add_custom_command(
    OUTPUT ${SDTV2_LINT_OUTPUT}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${SDTV2_LINT_DIR}
    COMMAND ${CMAKE_COMMAND}
        -DOUTPUT=${SDTV2_LINT_OUTPUT}
        -DFLINT_CMD=${SDTV2_FLINT_COMMAND}
        -DFLINT_ARGS=${SDTV2_FLINT_ARGS}
        -DSOURCES="${SDTV2_LINT_SOURCE_STRING}"
        -P ${SDTV2_RUN_LINT_SCRIPT}
    DEPENDS ${SDTV2_ABSOLUTE_SOURCES}
    COMMENT "Running SDTv2 lint"
)

add_custom_target(sdtv2_lint DEPENDS ${SDTV2_LINT_OUTPUT})

set(SDTV2_INTEGRITY_A_DEFINES
    sdt_get_sdsink_parameters=sdt_get_sdsink_parameters_A
    sdt_set_sdsink_parameters=sdt_set_sdsink_parameters_A
    sdt_set_uic_fillvalue=sdt_set_uic_fillvalue_A
    sdt_get_uic_fillvalue=sdt_get_uic_fillvalue_A
    sdt_get_counters=sdt_get_counters_A
    sdt_reset_counters=sdt_reset_counters_A
    sdt_get_errno=sdt_get_errno_A
    sdt_get_ssc=sdt_get_ssc_A
    sdt_get_sid=sdt_get_sid_A
    sdt_set_sid=sdt_set_sid_A
    sdt_get_validator=sdt_get_validator_A
    sdt_validate_pd=sdt_validate_pd_A
    sdt_mutex_lock=sdt_mutex_lock_A
    sdt_mutex_unlock=sdt_mutex_unlock_A
    sdt_mvb_secure_pd=sdt_mvb_secure_pd_A
    sdt_mvb_validate_pd=sdt_mvb_validate_pd_A
    sdt_ipt_secure_pd=sdt_ipt_secure_pd_A
    sdt_ipt_validate_pd=sdt_ipt_validate_pd_A
    sdt_wtb_validate_pd=sdt_wtb_validate_pd_A
    sdt_wtb_secure_pd=sdt_wtb_secure_pd_A
    sdt_uic_validate_pd=sdt_uic_validate_pd_A
    sdt_uic_secure_pd=sdt_uic_secure_pd_A
    sdt_uic_ed5_secure_pd=sdt_uic_ed5_secure_pd_A
    sdt_gen_sid=sdt_gen_sid_A
)

set(SDTV2_INTEGRITY_B_DEFINES
    sdt_get_sdsink_parameters=sdt_get_sdsink_parameters_B
    sdt_set_sdsink_parameters=sdt_set_sdsink_parameters_B
    sdt_set_uic_fillvalue=sdt_set_uic_fillvalue_B
    sdt_get_uic_fillvalue=sdt_get_uic_fillvalue_B
    sdt_get_counters=sdt_get_counters_B
    sdt_reset_counters=sdt_reset_counters_B
    sdt_get_errno=sdt_get_errno_B
    sdt_get_ssc=sdt_get_ssc_B
    sdt_get_sid=sdt_get_sid_B
    sdt_set_sid=sdt_set_sid_B
    sdt_get_validator=sdt_get_validator_B
    sdt_validate_pd=sdt_validate_pd_B
    sdt_mutex_lock=sdt_mutex_lock_B
    sdt_mutex_unlock=sdt_mutex_unlock_B
    sdt_mvb_secure_pd=sdt_mvb_secure_pd_B
    sdt_mvb_validate_pd=sdt_mvb_validate_pd_B
    sdt_ipt_secure_pd=sdt_ipt_secure_pd_B
    sdt_ipt_validate_pd=sdt_ipt_validate_pd_B
    sdt_wtb_validate_pd=sdt_wtb_validate_pd_B
    sdt_wtb_secure_pd=sdt_wtb_secure_pd_B
    sdt_uic_validate_pd=sdt_uic_validate_pd_B
    sdt_uic_secure_pd=sdt_uic_secure_pd_B
    sdt_uic_ed5_secure_pd=sdt_uic_ed5_secure_pd_B
    sdt_gen_sid=sdt_gen_sid_B
)

if(SDTV2_TARGET_OS STREQUAL "INTEGRITY")
    add_library(sdtv2_integrity_a STATIC ${SDTV2_SOURCES})
    add_library(sdtv2_integrity_b STATIC ${SDTV2_SOURCES})

    foreach(integrity_target IN ITEMS sdtv2_integrity_a sdtv2_integrity_b)
        target_include_directories(${integrity_target}
            PUBLIC
                ${SDTV2_COMMON_INCLUDE_DIRS}
        )
        target_compile_features(${integrity_target} PUBLIC c_std_99)
        target_compile_definitions(${integrity_target}
            PUBLIC
                ${SDTV2_FEATURE_DEFINES}
                OS_INTEGRITY
        )
    endforeach()

    set_target_properties(sdtv2_integrity_a
        PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}/lib_a"
            OUTPUT_NAME "libsdt_a"
    )
    set_target_properties(sdtv2_integrity_b
        PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}/lib_b"
            OUTPUT_NAME "libsdt_b"
    )

    target_compile_definitions(sdtv2_integrity_a PUBLIC ${SDTV2_INTEGRITY_A_DEFINES})
    target_compile_definitions(sdtv2_integrity_b PUBLIC ${SDTV2_INTEGRITY_B_DEFINES})

    add_library(tcnopen::sdtv2_integrity_a ALIAS sdtv2_integrity_a)
    add_library(tcnopen::sdtv2_integrity_b ALIAS sdtv2_integrity_b)
endif()

if(SDTV2_BUILD_LINUX_TESTS)
    if(NOT SDTV2_TARGET_OS STREQUAL "LINUX")
        message(FATAL_ERROR "Linux tests can only be built when SDTV2_TARGET_OS is set to LINUX")
    endif()

    if(SDTV2_LINUX_TEST_LIBRARY_VARIANT STREQUAL "static")
        set(_sdtv2_linux_test_library sdtv2_static)
    elseif(SDTV2_LINUX_TEST_LIBRARY_VARIANT STREQUAL "shared")
        set(_sdtv2_linux_test_library sdtv2_shared)
    else()
        message(FATAL_ERROR "Unknown SDTV2_LINUX_TEST_LIBRARY_VARIANT: ${SDTV2_LINUX_TEST_LIBRARY_VARIANT}")
    endif()

    set(SDTV2_LINUX_TEST_SOURCES
        test/etc_test_functions.c
        test/etc_test_scenarios.c
        test/ipt_test_functions.c
        test/ipt_test_scenarios.c
        test/mvb_test_functions.c
        test/mvb_test_scenarios.c
        test/test.c
        test/test_utils.c
        test/uic_test_functions.c
        test/uic_test_scenarios.c
        test/wtb_test_functions.c
        test/wtb_test_scenarios.c
    )

    set(_sdtv2_linux_test_compile_definitions
        ${SDTV2_FEATURE_DEFINES}
        ${SDTV2_OS_DEFINES}
        UNITTEST
    )

    separate_arguments(SDTV2_LINUX_TEST_MULTILIB_FLAGS_LIST NATIVE_COMMAND "${SDTV2_LINUX_TEST_MULTILIB_FLAGS}")

    function(sdtv2_add_linux_test target_name output_name)
        add_executable(${target_name} ${SDTV2_LINUX_TEST_SOURCES})
        target_compile_features(${target_name} PRIVATE c_std_99)
        target_include_directories(${target_name}
            PRIVATE
                ${CMAKE_CURRENT_SOURCE_DIR}/api
                ${CMAKE_CURRENT_SOURCE_DIR}/test
        )
        target_compile_definitions(${target_name} PRIVATE ${_sdtv2_linux_test_compile_definitions})
        target_compile_options(${target_name} PRIVATE -Wall)
        if(SDTV2_LINUX_TEST_MULTILIB_FLAGS_LIST)
            target_compile_options(${target_name} PRIVATE ${SDTV2_LINUX_TEST_MULTILIB_FLAGS_LIST})
            target_link_options(${target_name} PRIVATE ${SDTV2_LINUX_TEST_MULTILIB_FLAGS_LIST})
        endif()
        target_link_libraries(${target_name} PRIVATE ${_sdtv2_linux_test_library})
        set_target_properties(${target_name}
            PROPERTIES
                RUNTIME_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}/test"
                OUTPUT_NAME ${output_name}
        )
    endfunction()

    sdtv2_add_linux_test(sdtv2_linux_test_release test)
    set_target_properties(sdtv2_linux_test_release
        PROPERTIES
            EXCLUDE_FROM_DEFAULT_BUILD_DEBUG TRUE
            EXCLUDE_FROM_DEFAULT_BUILD_RELWITHDEBINFO TRUE
            EXCLUDE_FROM_DEFAULT_BUILD_MINSIZEREL TRUE
    )

    sdtv2_add_linux_test(sdtv2_linux_test_debug test_dbg)
    set_target_properties(sdtv2_linux_test_debug
        PROPERTIES
            EXCLUDE_FROM_DEFAULT_BUILD_RELEASE TRUE
            EXCLUDE_FROM_DEFAULT_BUILD_RELWITHDEBINFO TRUE
            EXCLUDE_FROM_DEFAULT_BUILD_MINSIZEREL TRUE
    )
endif()

if(SDTV2_BUILD_CCUS_TESTS)
    if(NOT SDTV2_TARGET_OS STREQUAL "INTEGRITY")
        message(FATAL_ERROR "CCUS tests can only be built when SDTV2_TARGET_OS is set to INTEGRITY")
    endif()

    get_filename_component(_sdtv2_ccus_compiler_name ${CMAKE_C_COMPILER} NAME)
    if(NOT _sdtv2_ccus_compiler_name MATCHES "^ccppc(\\.exe)?$")
        message(FATAL_ERROR "CCUS tests require the Integrity ccppc compiler provided by the active toolchain file")
    endif()

    if(NOT TARGET sdtv2_integrity_a OR NOT TARGET sdtv2_integrity_b)
        message(FATAL_ERROR "CCUS tests require the Integrity dual libraries to be available")
    endif()

    set(SDTV2_CCUS_TEST_SOURCE ccus_test/ccus.c)

    function(sdtv2_add_ccus_test target_name output_name extra_flags)
        add_executable(${target_name} ${SDTV2_CCUS_TEST_SOURCE})
        target_compile_features(${target_name} PRIVATE c_std_99)
        target_include_directories(${target_name}
            PRIVATE
                ${CMAKE_CURRENT_SOURCE_DIR}/api
                ${CMAKE_CURRENT_SOURCE_DIR}/ccus_test
        )
        target_compile_definitions(${target_name}
            PRIVATE
                ${SDTV2_FEATURE_DEFINES}
                ${SDTV2_OS_DEFINES}
        )
        if(extra_flags)
            separate_arguments(_sdtv2_ccus_flags_list NATIVE_COMMAND "${extra_flags}")
            if(_sdtv2_ccus_flags_list)
                target_compile_options(${target_name} PRIVATE ${_sdtv2_ccus_flags_list})
                target_link_options(${target_name} PRIVATE ${_sdtv2_ccus_flags_list})
            endif()
        endif()
        target_link_libraries(${target_name} PRIVATE sdtv2_integrity_a sdtv2_integrity_b)
        set_target_properties(${target_name}
            PROPERTIES
                OUTPUT_NAME ${output_name}
                RUNTIME_OUTPUT_DIRECTORY "${SDTV2_OUTPUT_ROOT}"
                SUFFIX ".bin"
        )
    endfunction()

    sdtv2_add_ccus_test(sdtv2_ccus_test_default ccus-test "")
    sdtv2_add_ccus_test(sdtv2_ccus_test_oi ccus-test-oi "-OI")
    sdtv2_add_ccus_test(sdtv2_ccus_test_oi_speed ccus-test-oi-speed "-Ospeed -OI")
endif()

add_custom_target(sdtv2_artifacts ALL
    DEPENDS
        $<$<OR:$<STREQUAL:${SDTV2_TARGET_OS},LINUX>,$<STREQUAL:${SDTV2_TARGET_OS},ARM_TI>,$<STREQUAL:${SDTV2_TARGET_OS},VXWORKS>,$<STREQUAL:${SDTV2_TARGET_OS},CSS>>:sdtv2_static>
        $<$<STREQUAL:${SDTV2_TARGET_OS},LINUX>:sdtv2_shared>
        $<$<STREQUAL:${SDTV2_TARGET_OS},LINUX>:sdtv2_linux_package>
        $<$<STREQUAL:${SDTV2_TARGET_OS},INTEGRITY>:sdtv2_integrity_a>
        $<$<STREQUAL:${SDTV2_TARGET_OS},INTEGRITY>:sdtv2_integrity_b>
        $<$<AND:$<BOOL:${SDTV2_BUILD_LINUX_TESTS}>,$<STREQUAL:${SDTV2_TARGET_OS},LINUX>>:sdtv2_linux_test_release>
        $<$<AND:$<BOOL:${SDTV2_BUILD_LINUX_TESTS}>,$<STREQUAL:${SDTV2_TARGET_OS},LINUX>>:sdtv2_linux_test_debug>
        $<$<AND:$<BOOL:${SDTV2_BUILD_CCUS_TESTS}>,$<STREQUAL:${SDTV2_TARGET_OS},INTEGRITY>>:sdtv2_ccus_test_default>
        $<$<AND:$<BOOL:${SDTV2_BUILD_CCUS_TESTS}>,$<STREQUAL:${SDTV2_TARGET_OS},INTEGRITY>>:sdtv2_ccus_test_oi>
        $<$<AND:$<BOOL:${SDTV2_BUILD_CCUS_TESTS}>,$<STREQUAL:${SDTV2_TARGET_OS},INTEGRITY>>:sdtv2_ccus_test_oi_speed>
)
