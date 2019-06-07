# This module provides the cpfAddFilePackage function, that adds a custom target that only contains files
# without doing anything.

include_guard(GLOBAL)

include(cpfPathUtilities)
include(cpfAddCppPackage)
include(cpfInitPackageProject)

#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function( cpfAddFilePackage )

    cmake_parse_arguments(
        ARG 
        "" 
        ""
        "SOURCES"
        ${ARGN} 
    )

    cpfPrintAddPackageStatusMessage("file")

    cpfAssertProjectVersionDefined()

    cpfGetPackageName(package)
    cpfAddStandardCustomTarget(${package} ${package} "${ARG_SOURCES}" "")

endfunction()

