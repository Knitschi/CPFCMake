include_guard(GLOBAL)


#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function(cpfAddPythonPackageComponent)

    cmake_parse_arguments(
        ARG 
        "" 
        "TEST_SCRIPT"
        "SOURCES;TEST_SCRIPT_ARGUMENTS"
        ${ARGN} 
    )

    cpfPrintAddPackageComponentStatusMessage("Python")

    cpfAssertProjectVersionDefined()

    cpfGetLastNodeOfCurrentSourceDir(packageComponent)

    # Get values of cmake per-package global variables.
    cpfSetPerComponentGlobalCMakeVariables(${CPF_CURRENT_PACKAGE} ${packageComponent})

    cpfAddPackageSources(ARG_SOURCES ${CPF_CURRENT_PACKAGE})

    cpfGeneratePythonVersionFile(versionFile ${packageComponent} ${PROJECT_VERSION})
    cpfListAppend(ARG_SOURCES ${versionFile})

    cpfAddStandardCustomTarget(
        PACKAGE ${CPF_CURRENT_PACKAGE}
        PACKAGE_COMPONENT ${packageComponent}
        TARGET ${packageComponent}
        SOURCES ${ARG_SOURCES}
    )

    if(ARG_TEST_SCRIPT)
        cpfAddRunPython3TestTarget(${ARG_TEST_SCRIPT} "${ARG_TEST_SCRIPT_ARGUMENTS}" "${ARG_SOURCES}" "" "")
    endif()

endfunction()


#-----------------------------------------------------------
function(cpfGeneratePythonVersionFile versionFileOut packageComponent version)

    set( PACKAGE_COMPONENT_NAME ${packageComponent})
	set( CPF_PACKAGE_VERSION ${version} )

	cpfGetPackageComponentVersionPythonFileName(versionFile ${packageComponent})
    # This is created in the source directory because I was not sure how we can properly
    # add the build directory to the python path. Currently there is no way to generate
    # python projects which could be used to handle the paths from which scripts are read.
	set( absPathVersionFile "${CMAKE_CURRENT_SOURCE_DIR}/${versionFile}")

	cpfConfigureFileWithVariables( "${CPF_ABS_TEMPLATE_DIR}/packageVersion.py.in" "${absPathVersionFile}" PACKAGE_COMPONENT_NAME CPF_PACKAGE_VERSION)

    set(${versionFileOut} "${absPathVersionFile}" PARENT_SCOPE)

endfunction()

