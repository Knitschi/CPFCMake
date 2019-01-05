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
        set(htmlReportDir ${CPF_PROJECT_HTML_ABS_DIR}/${CPF_OPENCPPCOVERAGE_DIR})

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
            set( stampFile ${CMAKE_BINARY_DIR}/${targetName}/${targetName}.stamp )
            set( stampFileCommand "cmake -E touch \"${stampFile}\"")

            cpfAddConfigurationDependendCommand(
                TARGET ${targetName}
                OUTPUT "${stampFile}"
                DEPENDS ${covFiles} ${opencppcoverageTargets}
                COMMENT ${command}
                CONFIG Debug
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
	set(binaryDir ${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName})
	file(MAKE_DIRECTORY ${binaryDir})

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY CPF_PRODUCTION_LIB_SUBTARGET)
	get_property(testTarget TARGET ${package} PROPERTY CPF_TESTS_SUBTARGET)
	if(TARGET ${testTarget})

		# add OpenCppCoverage commands if possible
		cpfGetFirstMSVCDebugConfig( msvcDebugConfig )
		if(msvcDebugConfig) 
				
			cpfFindRequiredProgram( TOOL_OPENCPPCOVERAGE OpenCppCoverage "A tool that creates coverage reports for C++ binaries.")

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

			cpfAddConfigurationDependendCommand(
				TARGET ${targetName}
				OUTPUT ${stampFile} ${coverageOutput}
				DEPENDS "$<TARGET_FILE:${testTarget}>" "$<TARGET_FILE:${productionLib}>"
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

#----------------------------------------------------------------------------------------
function( cpfGetFirstMSVCDebugConfig configOut )
	cpfGetConfigurations( configs )
	foreach(config ${configs})
		cpfIsMSVCDebugConfig(isDebugConfig ${config})
		if( isDebugConfig )
			set( ${configOut} ${config} PARENT_SCOPE)
			return()
		endif()		
	endforeach()
	set( ${configOut} "" PARENT_SCOPE)
endfunction()

