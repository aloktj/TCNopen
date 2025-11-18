# SPDX-License-Identifier: MPL-2.0
# Expressif IDF component definition mirroring component.mk so that TRDP can be
# added to ESP-IDF projects without the legacy GNU Make integration.

idf_component_register(
    SRC_DIRS
        "../../common"
        "../../vos/common"
        "."
    INCLUDE_DIRS
        "../../api"
        "../../vos/api"
        "."
)

# Match the warning/endianness flags from component.mk
set(_esp_trdp_compile_options
    -Wall
    -DESP32
    -Wno-unknown-pragmas
    -Wno-char-subscripts
    -Wno-format
)

target_compile_options(${COMPONENT_LIB} PRIVATE ${_esp_trdp_compile_options})
target_compile_definitions(${COMPONENT_LIB} PUBLIC L_ENDIAN)
