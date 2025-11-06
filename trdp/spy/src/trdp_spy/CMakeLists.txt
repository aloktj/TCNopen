cmake_minimum_required(VERSION 3.16)

set(TRDP_SPY_PLUGIN_TARGET trdp_spy_plugin)
set(TRDP_SPY_PLUGIN_OUTPUT_NAME trdp_spy)

set(TRDP_SPY_PLUGIN_SOURCES
    packet-trdp_spy.c
    trdp_env.c
    trdpDict.c
    plugin.c
)

set(TRDP_SPY_PLUGIN_HEADERS
    packet-trdp_spy.h
    trdp_env.h
    trdpDict.h
)

file(GLOB TRDP_SPY_DOC_CUSTOM_FILES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/doc/custom/*")

include(TrdpWiresharkPlugin)

trdp_add_wireshark_plugin(
    TARGET ${TRDP_SPY_PLUGIN_TARGET}
    OUTPUT_NAME ${TRDP_SPY_PLUGIN_OUTPUT_NAME}
    SOURCES ${TRDP_SPY_PLUGIN_SOURCES}
)

add_library(tcnopen::trdp_spy_plugin ALIAS ${TRDP_SPY_PLUGIN_TARGET})

set(TRDP_SPY_DOXYGEN_INPUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(TRDP_SPY_DOXYGEN_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/doc")
set(TRDP_SPY_DOXYGEN_IMAGE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/doc/custom")
set(TRDP_SPY_DOXYGEN_LATEX_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/doc/custom/docstart.tex")
set(TRDP_SPY_DOXYGEN_LATEX_FOOTER "${CMAKE_CURRENT_SOURCE_DIR}/doc/custom/docend.tex")
set(TRDP_SPY_DOXYGEN_CONFIG "${CMAKE_CURRENT_BINARY_DIR}/Doxyfile")

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile"
    "${TRDP_SPY_DOXYGEN_CONFIG}"
    @ONLY
)

set(TRDP_SPY_DOC_INPUTS
    ${TRDP_SPY_PLUGIN_SOURCES}
    ${TRDP_SPY_PLUGIN_HEADERS}
    ${TRDP_SPY_DOC_CUSTOM_FILES}
)

find_package(Doxygen QUIET)
set(TRDP_SPY_DOC_PDF "")

if(DOXYGEN_FOUND)
    set(TRDP_SPY_DOC_HTML_INDEX "${TRDP_SPY_DOXYGEN_OUTPUT_DIR}/html/index.html")
    set(TRDP_SPY_DOC_LATEX_MAKEFILE "${TRDP_SPY_DOXYGEN_OUTPUT_DIR}/latex/Makefile")

    add_custom_command(
        OUTPUT ${TRDP_SPY_DOC_HTML_INDEX} ${TRDP_SPY_DOC_LATEX_MAKEFILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${TRDP_SPY_DOXYGEN_OUTPUT_DIR}"
        COMMAND ${DOXYGEN_EXECUTABLE} "${TRDP_SPY_DOXYGEN_CONFIG}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS ${TRDP_SPY_DOXYGEN_CONFIG} ${TRDP_SPY_DOC_INPUTS}
        COMMENT "Generating TRDP spy plugin documentation (HTML and LaTeX)"
        VERBATIM
    )

    if(NOT TARGET doc-html)
        add_custom_target(doc-html DEPENDS ${TRDP_SPY_DOC_HTML_INDEX})
    else()
        add_custom_target(trdp_spy_doc_html DEPENDS ${TRDP_SPY_DOC_HTML_INDEX})
    endif()

    find_program(TRDP_SPY_LATEX_MAKE NAMES make gmake)
    if(TRDP_SPY_LATEX_MAKE)
        set(TRDP_SPY_DOC_PDF "${TRDP_SPY_DOXYGEN_OUTPUT_DIR}/latex/refman.pdf")
        add_custom_command(
            OUTPUT ${TRDP_SPY_DOC_PDF}
            COMMAND ${TRDP_SPY_LATEX_MAKE} -C "${TRDP_SPY_DOXYGEN_OUTPUT_DIR}/latex"
            DEPENDS ${TRDP_SPY_DOC_LATEX_MAKEFILE}
            COMMENT "Generating TRDP spy plugin documentation (PDF)"
            VERBATIM
        )
        if(NOT TARGET doc-pdf)
            add_custom_target(doc-pdf DEPENDS ${TRDP_SPY_DOC_PDF})
        else()
            add_custom_target(trdp_spy_doc_pdf DEPENDS ${TRDP_SPY_DOC_PDF})
        endif()
    else()
        if(NOT TARGET doc-pdf)
            add_custom_target(doc-pdf
                COMMAND ${CMAKE_COMMAND} -E echo "Skipping TRDP spy PDF documentation: no make tool found."
            )
        else()
            add_custom_target(trdp_spy_doc_pdf
                COMMAND ${CMAKE_COMMAND} -E echo "Skipping TRDP spy PDF documentation: no make tool found."
            )
        endif()
    endif()

    if(TRDP_WIRESHARK_DOC_INSTALL_DIR)
        install(DIRECTORY "${TRDP_SPY_DOXYGEN_OUTPUT_DIR}/html/"
            DESTINATION "${TRDP_WIRESHARK_DOC_INSTALL_DIR}/html"
            OPTIONAL
        )
        if(TRDP_SPY_DOC_PDF)
            install(FILES "${TRDP_SPY_DOC_PDF}"
                DESTINATION "${TRDP_WIRESHARK_DOC_INSTALL_DIR}"
                OPTIONAL
            )
        endif()
    endif()
else()
    if(NOT TARGET doc-html)
        add_custom_target(doc-html
            COMMAND ${CMAKE_COMMAND} -E echo "Skipping TRDP spy documentation: Doxygen not found."
        )
    else()
        add_custom_target(trdp_spy_doc_html
            COMMAND ${CMAKE_COMMAND} -E echo "Skipping TRDP spy documentation: Doxygen not found."
        )
    endif()
    if(NOT TARGET doc-pdf)
        add_custom_target(doc-pdf
            COMMAND ${CMAKE_COMMAND} -E echo "Skipping TRDP spy PDF documentation: Doxygen not found."
        )
    else()
        add_custom_target(trdp_spy_doc_pdf
            COMMAND ${CMAKE_COMMAND} -E echo "Skipping TRDP spy PDF documentation: Doxygen not found."
        )
    endif()
endif()
