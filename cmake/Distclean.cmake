cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED SOURCE_DIR)
    message(FATAL_ERROR "SOURCE_DIR is not defined for Distclean.cmake")
endif()
if(NOT DEFINED BINARY_DIR)
    message(FATAL_ERROR "BINARY_DIR is not defined for Distclean.cmake")
endif()

set(_dirs_to_remove
    "${SOURCE_DIR}/SDTv2/output"
    "${SOURCE_DIR}/trdp/bld"
    "${SOURCE_DIR}/trdp/doc/latex"
    "${SOURCE_DIR}/trdp/doc/html"
    "${SOURCE_DIR}/trdp/spy/src/trdp_spy/bld"
    "${BINARY_DIR}/dist"
    "${BINARY_DIR}/pkg"
    "${BINARY_DIR}/trdp/dist"
    "${BINARY_DIR}/trdp/pkg"
    "${BINARY_DIR}/trdp/lint"
    "${BINARY_DIR}/SDTv2/lint"
)

foreach(dir IN LISTS _dirs_to_remove)
    if(EXISTS "${dir}")
        file(REMOVE_RECURSE "${dir}")
        message(STATUS "Removed '${dir}'.")
    endif()
endforeach()

set(_files_to_remove
    "${SOURCE_DIR}/trdp/doc/TCN-TRDP2-D-BOM-033-xx - TRDP Reference Manual.pdf"
    "${SOURCE_DIR}/SDTv2/config/config.mk"
)
foreach(file_path IN LISTS _files_to_remove)
    if(EXISTS "${file_path}")
        file(REMOVE "${file_path}")
        message(STATUS "Removed '${file_path}'.")
    endif()
endforeach()

file(GLOB _debhelper_logs "${SOURCE_DIR}/trdp/debian/*.debhelper.log")
file(GLOB _debhelper_substvars "${SOURCE_DIR}/trdp/debian/*.substvars")
set(_debian_artifacts
    "${SOURCE_DIR}/trdp/debian/libtrdp2"
    "${SOURCE_DIR}/trdp/debian/tmp"
    "${SOURCE_DIR}/trdp/debian/libtrdp-dev"
    "${SOURCE_DIR}/trdp/debian/libtrdp-wireshark"
    "${SOURCE_DIR}/trdp/debian/files"
    "${SOURCE_DIR}/trdp/debian/debhelper-build-stamp"
    "${SOURCE_DIR}/trdp/debian/.debhelper"
)
foreach(dir IN LISTS _debian_artifacts)
    if(EXISTS "${dir}")
        file(REMOVE_RECURSE "${dir}")
        message(STATUS "Removed '${dir}'.")
    endif()
endforeach()

foreach(file_path IN LISTS _debhelper_logs _debhelper_substvars)
    if(EXISTS "${file_path}")
        file(REMOVE "${file_path}")
        message(STATUS "Removed '${file_path}'.")
    endif()
endforeach()

message(STATUS "Distclean completed. Run 'cmake --build . --target clean' beforehand to remove generator outputs.")
