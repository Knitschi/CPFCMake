include_guard(GLOBAL)



#----------------------------------------------------------------------------------------
# See api docs for documentation
#         
function( cpfAddSphinxPackage )

    set( requiredSingleValueKeywords
    )

    set(optionalSingleValueKeywords
		CONFIG_FILE_DIR
		OUTPUT_SUBDIR
	)

    set( requiredMultiValueKeywords
    )

    set(optionalMultiValueKeywords
        OTHER_FILES
        ADDITIONAL_SPHINX_ARGUMENTS
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

	set(outputDir ${CMAKE_CURRENT_BINARY_DIR})
	if(ARG_OUTPUT_SUBDIR)
		set(outputDir ${outputDir}/${ARG_OUTPUT_SUBDIR})
	endif()

    # Assert that the index.rst file exists
    set(sphinxSourceDir ${CMAKE_SOURCE_DIR})
	if(NOT EXISTS ${sphinxSourceDir}/index.rst )
		message(FATAL_ERROR "Error! The Sphinx package requires an index.rst file to be present in the build projects source directory.")
	endif()

    # locations
    set(configFile ${absConfigDir}/conf.py)
    cpfToAbsSourcePaths(sourceFiles "${ARG_OTHER_FILES}" ${CMAKE_CURRENT_SOURCE_DIR})
    set(stampFile ${CMAKE_CURRENT_BINARY_DIR}/sphinx.stamp)

    set(sphinxCommand "\"${TOOL_SPHINX-BUILD}\" -c \"${absConfigDir}\" \"${sphinxSourceDir}\" \"${outputDir}\" -j auto ${ARG_ADDITIONAL_SPHINX_ARGUMENTS}")
    # We create a stampfile here for outdating the target because we do not know what the users shpinx configuration will produce.
    set(stampCommand "\"${CMAKE_COMMAND}\" -E touch \"${stampFile}\"")

    cpfAddStandardCustomCommand(
        DEPENDS ${configFile} ${sourceFiles}
		#WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMANDS ${sphinxCommand} ${stampCommand}
        OUTPUT ${stampFile}
    )

    cpfGetPackageName(package)
    cpfAddStandardCustomTarget(${package} ${package} "${configFile};${sourceFiles}" "${stampFile}")

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