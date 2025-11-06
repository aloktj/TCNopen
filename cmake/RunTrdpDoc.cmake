cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED SOURCE_DIR)
    message(FATAL_ERROR "SOURCE_DIR is not defined for RunTrdpDoc.cmake")
endif()
if(NOT DEFINED DOXYGEN_CMD)
    message(FATAL_ERROR "DOXYGEN_CMD is not defined for RunTrdpDoc.cmake")
endif()
if(NOT DEFINED PDF_OUTPUT)
    message(FATAL_ERROR "PDF_OUTPUT is not defined for RunTrdpDoc.cmake")
endif()
if(NOT DEFINED PDF_DESTINATION)
    message(FATAL_ERROR "PDF_DESTINATION is not defined for RunTrdpDoc.cmake")
endif()

if(NOT DOXYGEN_CMD OR DOXYGEN_CMD STREQUAL "")
    message(STATUS "Doxygen not found; skipping TRDP documentation generation.")
    return()
endif()

execute_process(
    COMMAND ${DOXYGEN_CMD} Doxyfile
    WORKING_DIRECTORY "${SOURCE_DIR}"
    RESULT_VARIABLE _doxygen_result
)
if(_doxygen_result AND NOT _doxygen_result EQUAL 0)
    message(FATAL_ERROR "Doxygen command failed with exit code ${_doxygen_result}")
endif()

set(_pdf_generated FALSE)
if(DEFINED MAKE_CMD AND NOT MAKE_CMD STREQUAL "")
    execute_process(
        COMMAND ${MAKE_CMD}
        WORKING_DIRECTORY "${SOURCE_DIR}/doc/latex"
        RESULT_VARIABLE _latex_result
    )
    if(_latex_result AND NOT _latex_result EQUAL 0)
        message(WARNING "Latex build failed with exit code ${_latex_result}; the PDF may be outdated.")
    elseif(EXISTS "${PDF_OUTPUT}")
        set(_pdf_generated TRUE)
    endif()
else()
    message(STATUS "'make' not found; skipping PDF build step for TRDP documentation.")
    if(EXISTS "${PDF_OUTPUT}")
        set(_pdf_generated TRUE)
    endif()
endif()

if(_pdf_generated)
    get_filename_component(_dest_dir "${PDF_DESTINATION}" DIRECTORY)
    if(NOT _dest_dir)
        set(_dest_dir "${SOURCE_DIR}")
    endif()
    file(MAKE_DIRECTORY "${_dest_dir}")
    get_filename_component(_pdf_name "${PDF_OUTPUT}" NAME)
    set(_copied_pdf "${_dest_dir}/${_pdf_name}")
    if(EXISTS "${_copied_pdf}")
        file(REMOVE "${_copied_pdf}")
    endif()
    file(COPY "${PDF_OUTPUT}" DESTINATION "${_dest_dir}")
    if(EXISTS "${PDF_DESTINATION}")
        file(REMOVE "${PDF_DESTINATION}")
    endif()
    file(RENAME "${_copied_pdf}" "${PDF_DESTINATION}")
    message(STATUS "Reference manual copied to '${PDF_DESTINATION}'.")
else()
    message(WARNING "TRDP reference manual '${PDF_OUTPUT}' was not generated.")
endif()
