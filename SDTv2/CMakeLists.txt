set(SDTV2_SOURCES
    src/sdt_ipt.c
    src/sdt_mvb.c
    src/sdt_mutex.c
    src/sdt_uic.c
    src/sdt_validator.c
    src/sdt_wtb.c
)

add_library(sdtv2 STATIC ${SDTV2_SOURCES})
add_library(tcnopen::sdtv2 ALIAS sdtv2)

target_include_directories(sdtv2
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/api>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<INSTALL_INTERFACE:include/SDTv2>
)

target_compile_features(sdtv2 PUBLIC c_std_99)
target_compile_definitions(sdtv2 PUBLIC LINUX)

option(SDTV2_ENABLE_IPT "Enable IPT protocol support" ON)
option(SDTV2_ENABLE_MVB "Enable MVB protocol support" ON)
option(SDTV2_ENABLE_WTB "Enable WTB protocol support" ON)
option(SDTV2_ENABLE_SECURE "Enable secure communication features" ON)
option(SDTV2_ENABLE_UNITTEST_LOGS "Enable unit test instrumentation and logging" OFF)

if(SDTV2_ENABLE_IPT)
    target_compile_definitions(sdtv2 PUBLIC SDT_ENABLE_IPT)
endif()
if(SDTV2_ENABLE_MVB)
    target_compile_definitions(sdtv2 PUBLIC SDT_ENABLE_MVB)
endif()
if(SDTV2_ENABLE_WTB)
    target_compile_definitions(sdtv2 PUBLIC SDT_ENABLE_WTB)
endif()
if(SDTV2_ENABLE_SECURE)
    target_compile_definitions(sdtv2 PUBLIC SDT_SECURE)
endif()
if(SDTV2_ENABLE_UNITTEST_LOGS)
    target_compile_definitions(sdtv2 PUBLIC UNITTEST)
endif()
