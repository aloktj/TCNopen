# SPDX-License-Identifier: MPL-2.0
# Helper utilities for building the TRDP Wireshark plugin via pkg-config metadata.

include_guard(GLOBAL)

if(NOT TARGET PkgConfig::wireshark)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(wireshark REQUIRED IMPORTED_TARGET GLOBAL wireshark)
endif()

# Derive the default plugin directory from pkg-config if the user did not override it.
pkg_get_variable(TRDP_WIRESHARK_PKGCONFIG_PLUGINDIR wireshark plugindir)
if(TRDP_WIRESHARK_PKGCONFIG_PLUGINDIR)
    if(TRDP_WIRESHARK_PLUGIN_DIR STREQUAL "")
        set(TRDP_WIRESHARK_PLUGIN_DIR "${TRDP_WIRESHARK_PKGCONFIG_PLUGINDIR}" CACHE PATH
            "Base directory for Wireshark plugins (defaults to the pkg-config plugindir value)." FORCE)
    endif()
endif()

# Attempt to determine the Wireshark plugin API version from the directory layout when
# the caller did not specify one explicitly.
if(TRDP_WIRESHARK_PLUGIN_API_VERSION STREQUAL "" AND NOT TRDP_WIRESHARK_PLUGIN_DIR STREQUAL "")
    string(REGEX MATCH "/plugins/([^/]+)(/.*)?$" _wireshark_plugin_path "${TRDP_WIRESHARK_PLUGIN_DIR}")
    if(_wireshark_plugin_path)
        set(TRDP_WIRESHARK_PLUGIN_API_VERSION "${CMAKE_MATCH_1}" CACHE STRING
            "Wireshark plugin API version directory (leave empty to auto-detect)." FORCE)
    endif()
endif()

set(TRDP_WIRESHARK_PLUGIN_INSTALL_DIR "${TRDP_WIRESHARK_PLUGIN_DIR}")
if(TRDP_WIRESHARK_PLUGIN_INSTALL_DIR AND TRDP_WIRESHARK_PLUGIN_SUBDIR)
    string(REGEX REPLACE "/$" "" TRDP_WIRESHARK_PLUGIN_INSTALL_DIR "${TRDP_WIRESHARK_PLUGIN_INSTALL_DIR}")
    set(TRDP_WIRESHARK_PLUGIN_INSTALL_DIR
        "${TRDP_WIRESHARK_PLUGIN_INSTALL_DIR}/${TRDP_WIRESHARK_PLUGIN_SUBDIR}")
endif()

get_target_property(TRDP_WIRESHARK_INCLUDE_DIRS PkgConfig::wireshark INTERFACE_INCLUDE_DIRECTORIES)
if(NOT TRDP_WIRESHARK_INCLUDE_DIRS)
    set(TRDP_WIRESHARK_INCLUDE_DIRS "")
endif()

function(trdp_add_wireshark_plugin)
    set(options)
    set(oneValueArgs TARGET OUTPUT_NAME)
    set(multiValueArgs SOURCES)
    cmake_parse_arguments(TRDP_PLUGIN "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT TRDP_PLUGIN_TARGET)
        message(FATAL_ERROR "trdp_add_wireshark_plugin: TARGET argument is required")
    endif()
    if(NOT TRDP_PLUGIN_SOURCES)
        message(FATAL_ERROR "trdp_add_wireshark_plugin: SOURCES argument is required")
    endif()

    set(_target "${TRDP_PLUGIN_TARGET}")
    set(_output_name "${TRDP_PLUGIN_OUTPUT_NAME}")
    if(_output_name STREQUAL "")
        set(_output_name "${_target}")
    endif()

    add_library(${_target} SHARED ${TRDP_PLUGIN_SOURCES})
    set_target_properties(${_target} PROPERTIES
        OUTPUT_NAME ${_output_name}
        POSITION_INDEPENDENT_CODE ON
    )

    set(_include_dirs ${CMAKE_CURRENT_SOURCE_DIR})
    if(TRDP_WIRESHARK_INCLUDE_DIRS)
        list(APPEND _include_dirs ${TRDP_WIRESHARK_INCLUDE_DIRS})
    endif()

    set(_resolved_cfile "")
    if(TRDP_WIRESHARK_CFILE_PATH)
        if(EXISTS "${TRDP_WIRESHARK_CFILE_PATH}")
            set(_resolved_cfile "${TRDP_WIRESHARK_CFILE_PATH}")
        else()
            message(FATAL_ERROR
                "TRDP_WIRESHARK_CFILE_PATH is set to '${TRDP_WIRESHARK_CFILE_PATH}' but the file does not exist.")
        endif()
    else()
        find_file(_detected_cfile NAMES cfile.h HINTS ${_include_dirs})
        if(_detected_cfile)
            set(_resolved_cfile "${_detected_cfile}")
        elseif(TRDP_WIRESHARK_DOWNLOAD_CFILE)
            set(_download_dir "${CMAKE_BINARY_DIR}/wireshark/include")
            file(MAKE_DIRECTORY "${_download_dir}")
            set(_download_path "${_download_dir}/cfile.h")
            if(NOT EXISTS "${_download_path}")
                message(STATUS "Downloading Wireshark cfile.h from ${TRDP_WIRESHARK_CFILE_URL}")
                file(DOWNLOAD "${TRDP_WIRESHARK_CFILE_URL}" "${_download_path}" STATUS _download_status)
                list(GET _download_status 0 _status_code)
                if(NOT _status_code EQUAL 0)
                    set(_status_message "")
                    if(_download_status)
                        list(LENGTH _download_status _status_length)
                        if(_status_length GREATER 1)
                            list(GET _download_status 1 _status_message)
                        endif()
                    endif()
                    if(_status_message)
                        message(WARNING "Failed to download cfile.h: ${_status_message}")
                    else()
                        message(WARNING "Failed to download cfile.h: unknown error")
                    endif()
                endif()
            endif()
            if(EXISTS "${_download_path}")
                set(_resolved_cfile "${_download_path}")
            endif()
        endif()
    endif()

    if(_resolved_cfile)
        get_filename_component(_cfile_dir "${_resolved_cfile}" DIRECTORY)
        list(APPEND _include_dirs "${_cfile_dir}")
    elseif(NOT TRDP_WIRESHARK_DOWNLOAD_CFILE)
        message(FATAL_ERROR
            "Wireshark header 'cfile.h' was not found. Enable TRDP_WIRESHARK_DOWNLOAD_CFILE or provide TRDP_WIRESHARK_CFILE_PATH.")
    else()
        message(WARNING
            "Wireshark header 'cfile.h' could not be located. The build may fail if the header is required.")
    endif()

    list(REMOVE_DUPLICATES _include_dirs)
    target_include_directories(${_target} PRIVATE ${_include_dirs})

    target_link_libraries(${_target} PRIVATE PkgConfig::wireshark)
    target_compile_features(${_target} PRIVATE c_std_99)
    target_compile_definitions(${_target} PRIVATE PLUGIN_VERSION="${TRDP_WIRESHARK_PLUGIN_VERSION}")

    set(_warning_flags
        -Wall
        -W
        -Wextra
        -Wendif-labels
        -Wpointer-arith
        -Warray-bounds
        -Wformat-security
        -fwrapv
        -fno-strict-overflow
        -fno-delete-null-pointer-checks
        -Wvla
        -Waddress
        -Wattributes
        -Wdiv-by-zero
        -Wignored-qualifiers
        -Wpragmas
        -Wno-overlength-strings
        -Wwrite-strings
        -Wno-long-long
        -fexcess-precision=fast
        -Wc++-compat
        -Wshadow
        -Wno-pointer-sign
        -Wold-style-definition
        -Wstrict-prototypes
        -Wlogical-op
        -Wjump-misses-init
        -fvisibility=hidden
    )
    target_compile_options(${_target} PRIVATE ${_warning_flags})
    set_target_properties(${_target} PROPERTIES
        C_VISIBILITY_PRESET hidden
        VISIBILITY_INLINES_HIDDEN YES
    )

    if(UNIX AND NOT APPLE)
        target_link_options(${_target} PRIVATE
            -Wl,--as-needed
            -pie
            -Wl,-soname,${_output_name}.so
        )
    endif()

    set(_binary_dir "${CMAKE_BINARY_DIR}/wireshark")
    if(TRDP_WIRESHARK_PLUGIN_API_VERSION)
        set(_binary_dir "${_binary_dir}/${TRDP_WIRESHARK_PLUGIN_API_VERSION}")
    endif()
    if(TRDP_WIRESHARK_PLUGIN_SUBDIR)
        set(_binary_dir "${_binary_dir}/${TRDP_WIRESHARK_PLUGIN_SUBDIR}")
    endif()
    set_target_properties(${_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${_binary_dir}")

    if(TRDP_WIRESHARK_PLUGIN_INSTALL_DIR)
        install(TARGETS ${_target}
            LIBRARY DESTINATION "${TRDP_WIRESHARK_PLUGIN_INSTALL_DIR}"
        )
    else()
        message(WARNING "TRDP_WIRESHARK_PLUGIN_INSTALL_DIR is empty; the plugin will not be installed.")
    endif()
endfunction()
