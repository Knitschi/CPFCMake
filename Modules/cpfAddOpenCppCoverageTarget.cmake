include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)


#----------------------------------------------------------------------------------------
# The global opencppcoverage target runns a OpenCppCoverage command that combines all intermediate outputs of the packages.
#
function( cpfAddGlobalOpenCppCoverageTarget packages)

	cpfAddBundleOpenCppCoverageTarget(OpenCppCoverage ${packages})

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddPackageOpenCppCoverageTarget package)

	set(targetName OpenCppCoverage_${package})

	if(NOT (TARGET ${targetName}))
		cpfAddBundleOpenCppCoverageTarget(${targetName} ${package})
		if(TARGET ${targetName})
			set_property(TARGET ${targetName} PROPERTY FOLDER  ${package}/package)
			add_dependencies(pipeline_${package} ${targetName})
		endif()
	else()
		add_dependencies(pipeline_${package} ${targetName})
	endif()

endfunction()

#--------------------------------------------------------------------------------------
function( cpfAddBundleOpenCppCoverageTarget targetName packages)

    if(NOT CPF_ENABLE_OPENCPPCOVERAGE_TARGET)
        return()
    endif()

	cpfGetMSVCDebugConfigs( msvcDebugConfigs )

    if(msvcDebugConfigs)

        #Locations
        set(htmlReportDir ${CMAKE_BINARY_DIR}/${targetName}/$<CONFIG>/${html})

        cpfGetSubtargets(opencppcoverageTargets "${packages}" INTERFACE_CPF_OPENCPPCOVERAGE_SUBTARGET)
        if(opencppcoverageTargets)

            foreach( target ${opencppcoverageTargets})
                get_property( files TARGET ${target} PROPERTY CPF_CPPCOVERAGE_OUTPUT)
                cpfListAppend( covFiles "${files}")
            endforeach()

            # delete output command
            # OpenCppCoverage will issue an error if the output directory already exists.
            set( cleanDirCommand "\"${CMAKE_COMMAND}\" -E remove_directory \"${htmlReportDir}\"")

            # assemble OpenCppCoverage command
            set( runOpenCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" ")
            foreach( file ${covFiles} )
                string(APPEND runOpenCppCoverageCommand "--input_coverage=\"${file}\" ")
            endforeach()
            string(APPEND runOpenCppCoverageCommand "--export_type=html:\"${htmlReportDir}\" ")
            string(APPEND runOpenCppCoverageCommand "--quiet")

            set(mainOutputFile "${htmlReportDir}/index.html")

            cpfAddConfigurationDependendCommand(
                CONFIGS ${msvcDebugConfigs}
				DEPENDS ${covFiles} ${opencppcoverageTargets}
				COMMANDS ${cleanDirCommand} ${runOpenCppCoverageCommand}
				OUTPUT ${mainOutputFile}
            )

            add_custom_target(
                ${targetName}
                DEPENDS ${opencppcoverageTargets} ${mainOutputFile}
            )

		endif()

    endif()

endfunction()


#----------------------------------------------------------------------------------------
# Creates the custom target that runs the test executable with OpenCppCoverage.
# The configuration must use MSVC enable this. OpenCppCoverage will only be run
# when compiling with debug flags.
# 
function( cpfAddOpenCppCoverageTarget packageComponent)

	if(NOT CPF_ENABLE_OPENCPPCOVERAGE_TARGET)
		return()
	endif()
	# check preconditions
	cpfAssertDefined(CPF_TEST_FILES_DIR)

	set(targetName opencppcoverage_${packageComponent})
	set(binaryDir ${CMAKE_CURRENT_BINARY_DIR}/${targetName})
	file(MAKE_DIRECTORY ${binaryDir})

	# get related targets
	get_property(productionLib TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
	get_property(testTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET)
	if(TARGET ${testTarget})

		# add OpenCppCoverage commands if possible
		cpfGetMSVCDebugConfigs( msvcDebugConfigs )
		if(msvcDebugConfigs) 
				
			cpfFindRequiredProgram( TOOL_OPENCPPCOVERAGE OpenCppCoverage "A tool that creates coverage reports for C++ binaries." "")

			# add OpenCppCoverage commands
			set(coverageOutputTemp "${binaryDir}/${testTarget}_temp_$<CONFIG>.cov")
			set(coverageOutput "${binaryDir}/${testTarget}_$<CONFIG>.cov")
			cpfListAppend( coverageOutputFiles ${coverageOutput})

			set(removeTempCovFileComand "\"${CMAKE_COMMAND}\" -E remove -f \"${coverageOutputTemp}\"") # we need to try to remove this to cover cases where the OpenCppCoverage command fails and the temp file does not get renamed.
			set(runOpenCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" --export_type=binary:\"${coverageOutputTemp}\" --sources=\"**\\${CPF_SOURCE_DIR}\\${packageComponent}\" --quiet -- \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CPF_TEST_FILES_DIR}/${CPF_CONFIG}/dynmicAnalysis_${testTarget}\"")
			set(cmakeRenameCommand "\"${CMAKE_COMMAND}\" -E rename \"${coverageOutputTemp}\" \"${coverageOutput}\"")

			cpfGetTargetFileGeneratorExpression(prodLibFile ${productionLib})

			cpfAddConfigurationDependendCommand(
                CONFIGS ${msvcDebugConfigs}
				DEPENDS "$<TARGET_FILE:${testTarget}>" "${prodLibFile}"
				COMMANDS ${removeTempCovFileComand} ${runOpenCppCoverageCommand} ${cmakeRenameCommand}
				OUTPUT ${coverageOutput}
				COMMENT "Run OpenCppCoverage for ${testTarget}."
            )

			add_custom_target(
				${targetName}
				DEPENDS ${productionLib} ${testTarget} ${coverageOutput}
			)

			# set properties related to the static analysis target
			set_property( TARGET ${packageComponent} PROPERTY INTERFACE_CPF_OPENCPPCOVERAGE_SUBTARGET ${targetName})
			cpfGetComponentVSFolder(packageFolder ${CPF_CURRENT_PACKAGE} ${packageComponent})
			set_property( TARGET ${targetName} PROPERTY FOLDER "${packageFolder}/pipeline")
			set_property( TARGET ${targetName} PROPERTY CPF_CPPCOVERAGE_OUTPUT ${coverageOutputFiles} )
		endif()

	endif()

endfunction()
