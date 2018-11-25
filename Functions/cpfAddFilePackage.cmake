# This module provides the cpfAddFilePackage function, that adds a custom target that only contains files
# without doing anything.

include_guard(GLOBAL)

include(cpfPathUtilities)
include(cpfAddCppPackage)
include(cpfInitPackageProject)

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

    
    cpfGetPackageName(package)

    add_custom_target( ${package} SOURCES ${ARG_SOURCES} )
    set_property( TARGET ${package} PROPERTY FOLDER ${package} )
	cpfSetIDEDirectoriesForTargetSources(${package})

endfunction()