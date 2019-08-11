# This module provides the cpfAddFilePackage function, that adds a custom target that only contains files
# without doing anything.

include_guard(GLOBAL)

include(cpfPackageUtilities)
include(cpfAssertions)
include(cpfCustomTargetUtilities)


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
    cpfAddStandardCustomTarget(
        PACKAGE ${package}
        TARGET ${package}
        SOURCES ${ARG_SOURCES}
    )

endfunction()

