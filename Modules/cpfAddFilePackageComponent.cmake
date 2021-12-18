# This module provides the cpfAddFilePackageComponent function, that adds a custom target that only contains files
# without doing anything.

include_guard(GLOBAL)

include(cpfPackageUtilities)
include(cpfAssertions)
include(cpfCustomTargetUtilities)


#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function( cpfAddFilePackageComponent )

    cmake_parse_arguments(
        ARG 
        "" 
        ""
        "SOURCES"
        ${ARGN} 
    )

    cpfPrintAddPackageComponentStatusMessage("file")

    cpfAssertProjectVersionDefined()

    cpfGetLastNodeOfCurrentSourceDir(packageComponent)

    # Get values of cmake per-package global variables.
	cpfSetPerComponentGlobalCMakeVariables(${CPF_CURRENT_PACKAGE} ${packageComponent})

    cpfAddPackageSources(ARG_SOURCES ${CPF_CURRENT_PACKAGE})

    cpfAddStandardCustomTarget(
        PACKAGE ${CPF_CURRENT_PACKAGE}
        PACKAGE_COMPONENT ${packageComponent}
        TARGET ${packageComponent}
        SOURCES ${ARG_SOURCES}
    )

endfunction()

