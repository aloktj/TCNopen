cmake_minimum_required(VERSION 3.16)
project(TCNopen LANGUAGES C)

option(TCNOPEN_BUILD_SDT "Build the SDTv2 safety data transmission library" ON)
option(TCNOPEN_BUILD_TRDP "Build the TRDP communication stack" ON)

if(TCNOPEN_BUILD_SDT)
    add_subdirectory(SDTv2)
endif()

if(TCNOPEN_BUILD_TRDP)
    add_subdirectory(trdp)
endif()
