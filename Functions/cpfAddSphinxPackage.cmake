include_guard(GLOBAL)

include(cpfMiscUtilities)

include(GNUInstallDirs)

#----------------------------------------------------------------------------------------
# See api docs for documentation
#         
function( cpfAddSphinxPackage )

    set( requiredSingleValueKeywords
    )

    set(optionalSingleValueKeywords
		CONFIG_FILE_DIR
	)

    set( requiredMultiValueKeywords
    )

    set(optionalMultiValueKeywords
        OTHER_FILES
        ADDITIONAL_SPHINX_ARGUMENTS
		SOURCE_SUFFIXES
    )

	cmake_parse_arguments(
		ARG 
		"" 
		"${requiredSingleValueKeywords};${optionalSingleValueKeywords}"
		"${requiredMultiValueKeywords};${optionalMultiValueKeywords}"
		${ARGN} 
	)

    cpfPrintAddPackageStatusMessage("Sphinx")

	cpfAssertKeywordArgumentsHaveValue( "${requiredSingleValueKeywords};${requiredMultiValueKeywords}" ARG "cpfAddSphinxPackage()")
    cpfAssertProjectVersionDefined()
    cpfFindSphinxBuild()

	if(NOT ARG_CONFIG_FILE_DIR)
		set(absConfigDir ${CMAKE_CURRENT_SOURCE_DIR})
	else()
		cpfToAbsSourcePath(absConfigDir)
	endif()

	set(outputDir ${CMAKE_CURRENT_BINARY_DIR}/html)

	if(NOT ARG_SOURCE_SUFFIXES)
		set(ARG_SOURCE_SUFFIXES rst)
	endif()

    # Assert that the index.rst file exists
    set(sphinxSourceDir ${CMAKE_SOURCE_DIR})
	if(NOT EXISTS ${sphinxSourceDir}/index.rst )
		message(FATAL_ERROR "Error! The Sphinx package requires an index.rst file to be present in the build projects source directory.")
	endif()

    # locations
    set(configFile ${absConfigDir}/conf.py)
	set(keyOutputFile ${outputDir}/index.html)

	# File dependencies
	# Explicitly set files from this package
	cpfToAbsSourcePaths(sourceFiles "${ARG_OTHER_FILES}" ${CMAKE_CURRENT_SOURCE_DIR})
	# All relevant depended on source files from other packages in the project.
	cpfGetSphinxSourceFilesFromAllPackages(otherPackageFiles "${ARG_SOURCE_SUFFIXES}")

    set(sphinxCommand "\"${TOOL_SPHINX-BUILD}\" -c \"${absConfigDir}\" \"${sphinxSourceDir}\" \"${outputDir}\" -j auto ${ARG_ADDITIONAL_SPHINX_ARGUMENTS}")
    # We create a stampfile here for outdating the target because we do not know what the users shpinx configuration will produce.
    set(stampCommand "\"${CMAKE_COMMAND}\" -E touch \"${keyOutputFile}\"")

    cpfAddStandardCustomCommand(
        DEPENDS ${configFile} ${sourceFiles} ${otherPackageFiles}
        COMMANDS ${sphinxCommand} ${stampCommand}
        OUTPUT ${keyOutputFile}
    )

    cpfGetPackageName(package)
	cpfAddStandardCustomTarget(${package} ${package} "${configFile};${sourceFiles}" "${keyOutputFile}")
	
	# Add install rules to create the cmake_install.cmake script.
	install(
		DIRECTORY ${outputDir}
		DESTINATION doc/sphinx
		COMPONENT documentation
		OPTIONAL
	)

	# Add a custom install target.
	cpfGetRunInstallScriptCommands( runInstallScriptCommands ${package} "" "documentation" "${CMAKE_INSTALL_PREFIX}" )
	set(installedIndexHtmlFile ${CMAKE_INSTALL_PREFIX}/doc/sphinx/html/index.html)
	cpfAddStandardCustomCommand(
        DEPENDS ${keyOutputFile}
        COMMANDS ${runInstallScriptCommands}
        OUTPUT ${installedIndexHtmlFile}
	)
	set(installTarget install_${package})
	cpfAddStandardCustomTarget(${package} ${installTarget} "" "${installedIndexHtmlFile};${package}")

	# Set target properties
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_INSTALL_PACKAGE_SUBTARGETS ${installTarget})

endfunction()

#----------------------------------------------------------------------------------------
function( cpfFindSphinxBuild )

    # We require python to look for sphinx-build
    if(NOT TOOL_PYTHON3)
        messge(FATAL_ERROR "Error! Python 3 is required when using cpfAddSphinxPackage().")
    endif()

    # I expect the user site to be something like
    # C:\\Users\\knits\\AppData\\Roaming\\Python\\Python36\\site-packages
	set(userSiteCommand "\"${TOOL_PYTHON3}\" -m site --user-site")
    #set(userSiteCommand "cmake --version")
    separate_arguments(commandList NATIVE_COMMAND "${userSiteCommand}")
    execute_process(
		COMMAND ${commandList}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        OUTPUT_VARIABLE userSitePath
		ERROR_VARIABLE error
		RESULT_VARIABLE result
		OUTPUT_STRIP_TRAILING_WHITESPACE
		ERROR_STRIP_TRAILING_WHITESPACE
    )

	if(NOT (${result} EQUAL 0))
		message(FATAL_ERROR "Error! Could not retrieve the python user site with command\n\"${userSiteCommand}\"\nThe error output was:\n${ERROR_VARIABLE}")
	endif()

    file(TO_CMAKE_PATH ${userSitePath} userSitePath)

    cpfFindRequiredProgram( 
        TOOL_SPHINX-BUILD sphinx-build
        "A tool that generates html documentation from .rst files."
        "${userSitePath}/../Scripts"
    )

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetSphinxSourceFilesFromAllPackages filesOut parsedFilesExtensions )

	cpfGetAllTargets(allTargets)

	set(allUsedSources)
	foreach(target ${allTargets})
		getAbsPathsOfTargetSources(targetSources ${target})
		cpfGetFilepathsWithExtensions(usedTargetSources "${targetSources}" "${parsedFilesExtensions}")
		cpfListAppend(allUsedSources ${usedTargetSources})
	endforeach()

	set(${filesOut} "${allUsedSources}" PARENT_SCOPE)

endfunction()