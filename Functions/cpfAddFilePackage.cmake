# This module provides the cpfAddFilePackage function, that adds a custom target that only contains files
# without doing anything.

include_guard(GLOBAL)


#
# Keyword Arguments
# PACKAGE_NAME
# FILES

function( cpfAddFilePackage )

    cmake_parse_arguments(
        ARG 
        "" 
        "PACKAGE_NAME"
        "FILES"
        ${ARGN} 
    )

    add_custom_target( ${ARG_PACKAGE_NAME} SOURCES ${ARG_FILES} )
    set_property(TARGET ${ARG_PACKAGE_NAME} FOLDER ${ARG_PACKAGE_NAME} )    

endfunction()