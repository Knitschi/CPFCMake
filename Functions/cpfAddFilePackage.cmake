# This module provides the cpfAddFilePackage function, that adds a custom target that only contains files
# without doing anything.

include_guard(GLOBAL)

include(cpfPathUtilities)

#
# Keyword Arguments:
#
# SOURCES         The files that belong to the package.
#
function( cpfAddFilePackage )

    cmake_parse_arguments(
        ARG 
        "" 
        ""
        "SOURCES"
        ${ARGN} 
    )

    cpfGetParentDirectory( packageName "${CMAKE_CURRENT_SOURCE_DIR}")

    add_custom_target( ${packageName} SOURCES ${ARG_SOURCES} )
    #set_property(TARGET ${packageName} FOLDER ${packageName} )    

endfunction()