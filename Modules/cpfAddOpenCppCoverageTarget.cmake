include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)


#----------------------------------------------------------------------------------------
# The global opencppcoverage target runns a OpenCppCoverage command that combines all intermediate outputs of the packages.
#
function( cpfAddGlobalOpenCppCoverageTarget packages)

    if(NOT CPF_ENABLE_OPENCPPCOVERAGE_TARGET)
        return()
    endif()

    if(MSVC)
        set(targetName opencppcoverage)

        #Locations
        set(htmlReportDir ${CMAKE_BINARY_DIR}/${targetName}/${html}/${CPF_OPENCPPCOVERAGE_DIR})

        cpfGetSubtargets(opencppcoverageTargets "${packages}" INTERFACE_CPF_OPENCPPCOVERAGE_SUBTARGET)
        if(opencppcoverageTargets)

            foreach( target ${opencppcoverageTargets})
                get_property( files TARGET ${target} PROPERTY CPF_CPPCOVERAGE_OUTPUT)
                cpfListAppend( covFiles "${files}")
            endforeach()

            # delete output command
            # OpenCppCoverage will issue an error if the output directory already exists.
            set( cleanDirCommand "cmake -E remove_directory \"${htmlReportDir}\"")

            # assemble OpenCppCoverage command
            set( runOpenCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" ")
            foreach( file ${covFiles} )
                string(APPEND runOpenCppCoverageCommand "--input_coverage=\"${file}\" ")
            endforeach()
            string(APPEND runOpenCppCoverageCommand "--export_type=html:\"${htmlReportDir}\" ")
            string(APPEND runOpenCppCoverageCommand "--quiet")

            # stampfile command
            set( stampFile ${CMAKE_CURRENT_BINARY_DIR}/${targetName}/${targetName}.stamp )
            set( stampFileCommand "cmake -E touch \"${stampFile}\"")

			cpfGetFirstMSVCDebugConfig( msvcDebugConfig )
			cpfWrapInConfigGeneratorExpressions(wrappedCovFiles "${covFiles}" ${msvcDebugConfig})
			cpfWrapInConfigGeneratorExpressions(wrappedTargets "${opencppcoverageTargets}" ${msvcDebugConfig})
			
            cpfAddConfigurationDependendCommand(
                TARGET ${targetName}
                OUTPUT "${stampFile}"
                DEPENDS ${wrappedCovFiles} ${wrappedTargets}
                COMMENT ${command}
                CONFIG ${msvcDebugConfig}
                COMMANDS_CONFIG ${cleanDirCommand} ${runOpenCppCoverageCommand} ${stampFileCommand}
                COMMANDS_NOT_CONFIG ${stampFileCommand}
            )

            add_custom_target(
                ${targetName}
                DEPENDS ${opencppcoverageTargets} ${stampFile}
            )

		endif()

    endif()

endfunction()


#----------------------------------------------------------------------------------------
# Creates the custom target that runs the test executable with OpenCppCoverage.
# The configuration must use MSVC enable this. OpenCppCoverage will only be run
# when compiling with debug flags.
# 
function( cpfAddOpenCppCoverageTarget package)

	if(NOT CPF_ENABLE_OPENCPPCOVERAGE_TARGET)
		return()
	endif()
	# check preconditions
	cpfAssertDefined(CPF_TEST_FILES_DIR)

	set(targetName opencppcoverage_${package})
	set(binaryDir ${CMAKE_CURRENT_BINARY_DIR}/${targetName})
	file(MAKE_DIRECTORY ${binaryDir})

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
	get_property(testTarget TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET)
	if(TARGET ${testTarget})

		# add OpenCppCoverage commands if possible
		cpfGetFirstMSVCDebugConfig( msvcDebugConfig )
		if(msvcDebugConfig) 
				
			cpfFindRequiredProgram( TOOL_OPENCPPCOVERAGE OpenCppCoverage "A tool that creates coverage reports for C++ binaries." "")

			# add OpenCppCoverage commands
			set(coverageOutputTemp "${binaryDir}/${testTarget}_temp.cov")
			set(coverageOutput "${binaryDir}/${testTarget}.cov")
			cpfListAppend( coverageOutputFiles ${coverageOutput})

			set(removeTempCovFileComand "cmake -E remove -f \"${coverageOutputTemp}\"") # we need to try to remove this to cover cases where the OpenCppCoverage command fails and the temp file does not get renamed.
			set(runOpenCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" --export_type=binary:\"${coverageOutputTemp}\" --sources=\"**\\${CPF_SOURCE_DIR}\\${package}\" --quiet -- \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CPF_TEST_FILES_DIR}/${CPF_CONFIG}/dynmicAnalysis_${testTarget}\"")
			set(cmakeRenameCommand "cmake -E rename \"${coverageOutputTemp}\" \"${coverageOutput}\"")
			# we use an extra stampfile to make sure that marking the target done works even if the commands are only the echos for non debug configs.
			set(stampFile ${binaryDir}/OpenCppCoverage_${testTarget}.stamp )
			set(stampFileCommand "cmake -E touch \"${stampFile}\"")

			cpfGetTargetFileGeneratorExpression(prodLibFile ${productionLib})

			cpfAddConfigurationDependendCommand(
				TARGET ${targetName}
				OUTPUT ${stampFile} # ${coverageOutput} The cov files are only created for debug configs so this causes warnings with visual studio when building configs that do not create the files.
				DEPENDS "$<TARGET_FILE:${testTarget}>" "${prodLibFile}"
				COMMENT "Run OpenCppCoverage for ${testTarget}."
				CONFIG ${msvcDebugConfig}
				COMMANDS_CONFIG ${removeTempCovFileComand} ${runOpenCppCoverageCommand} ${cmakeRenameCommand} ${stampFileCommand}
				COMMANDS_NOT_CONFIG ${stampFileCommand}
			)

			add_custom_target(
				${targetName}
				DEPENDS ${productionLib} ${testTarget} ${stampFile}
			)

			# set properties related to the static analysis target
			set_property( TARGET ${package} PROPERTY INTERFACE_CPF_OPENCPPCOVERAGE_SUBTARGET ${targetName})
			set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")
			set_property( TARGET ${targetName} PROPERTY CPF_CPPCOVERAGE_OUTPUT ${coverageOutputFiles} )
		endif()

	endif()

endfunction()
