# SPDX-License-Identifier: MPL-2.0
# Helper toolchain description for cross-compiling TRDP to VxWorks/PowerPC.
# The file mirrors the assumptions in trdp/rules.mk where the WindRiver
# toolchain is selected through TCPATH/TCPREFIX/TCPOSTFIX. Provide the full
# prefix (path + triplet + trailing hyphen) via TRDP_VXWORKS_TOOLCHAIN_PREFIX.

set(CMAKE_SYSTEM_NAME VxWorks)
set(CMAKE_SYSTEM_VERSION 6)
set(CMAKE_SYSTEM_PROCESSOR powerpc)

set(TRDP_VXWORKS_TOOLCHAIN_PREFIX "" CACHE STRING
    "Prefix (path + triplet + trailing hyphen) for the Wind River cross tools, e.g. /opt/WindRiver/gnu/4.8.1/vxworks-6.9/x86-linux2/bin/powerpc-wrs-vxworks-")
if(NOT TRDP_VXWORKS_TOOLCHAIN_PREFIX)
    message(FATAL_ERROR "Set TRDP_VXWORKS_TOOLCHAIN_PREFIX to the prefix of your VxWorks cross toolchain")
endif()

set(_vx_prefix "${TRDP_VXWORKS_TOOLCHAIN_PREFIX}")
set(CMAKE_C_COMPILER "${_vx_prefix}gcc")
set(CMAKE_AR "${_vx_prefix}ar")
set(CMAKE_RANLIB "${_vx_prefix}ranlib")
set(CMAKE_OBJCOPY "${_vx_prefix}objcopy")
set(CMAKE_OBJDUMP "${_vx_prefix}objdump")
set(CMAKE_STRIP "${_vx_prefix}strip")

# Try-compile targets should not attempt to execute generated binaries on the
# build host.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
