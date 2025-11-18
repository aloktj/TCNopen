# SPDX-License-Identifier: MPL-2.0
# Helper toolchain description for Green Hills INTEGRITY builds.  The legacy
# Makefiles only switched the compiler to "cc", so we mirror that here by
# letting the caller point at the vendor-provided binaries.

set(CMAKE_SYSTEM_NAME Integrity)
set(CMAKE_SYSTEM_PROCESSOR generic)

set(TRDP_INTEGRITY_COMPILER "" CACHE FILEPATH
    "Absolute path to the Green Hills cc compiler for your target")
if(NOT TRDP_INTEGRITY_COMPILER)
    message(FATAL_ERROR "Set TRDP_INTEGRITY_COMPILER to the cc executable from your Green Hills installation")
endif()
set(CMAKE_C_COMPILER "${TRDP_INTEGRITY_COMPILER}")

set(TRDP_INTEGRITY_ARCHIVER "" CACHE FILEPATH
    "Optional path to the archiver (e.g., cx) to override the default")
if(TRDP_INTEGRITY_ARCHIVER)
    set(CMAKE_AR "${TRDP_INTEGRITY_ARCHIVER}")
endif()

set(TRDP_INTEGRITY_RANLIB "" CACHE FILEPATH
    "Optional path to the ranlib-compatible tool (e.g., cxranlib)")
if(TRDP_INTEGRITY_RANLIB)
    set(CMAKE_RANLIB "${TRDP_INTEGRITY_RANLIB}")
endif()

set(TRDP_INTEGRITY_STRIP "" CACHE FILEPATH "Optional stripper for firmware images")
if(TRDP_INTEGRITY_STRIP)
    set(CMAKE_STRIP "${TRDP_INTEGRITY_STRIP}")
endif()

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
