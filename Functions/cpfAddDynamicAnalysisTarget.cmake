include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)


#----------------------------------------------------------------------------------------
# Creates the global dynamic analysis target that depends on the individual dynamic analysis targets
# and creates the html report using the .gov files of the individual targets.
#
function( cpfAddGlobalDynamicAnalysisTarget packages)
	
	if(NOT CPF_ENABLE_DYNAMIC_ANALYSIS_TARGET)
		return()
	endif()
		
	set(targetName dynamicAnalysis)

	cpfIsGccClangDebug(gccClangDebug)
	if(gccClangDebug)

		cpfAddSubTargetBundleTarget( ${targetName} "${packages}" CPF_VALGRIND_SUBTARGET "")
		
	elseif(MSVC)
		# add the OpenCppCoverage command that combines all intermediate outputs.
		
		#Locations
		set(htmlReportDir ${CPF_PROJECT_HTML_ABS_DIR}/${CPF_OPENCPPCOVERAGE_DIR})

		cpfGetSubtargets(dynamicAnalysisTargets "${packages}" CPF_OPENCPPCOVERAGE_SUBTARGET)
		if(dynamicAnalysisTargets)

			foreach( target ${dynamicAnalysisTargets})
				get_property( files TARGET ${target} PROPERTY CPF_CPPCOVERAGE_OUTPUT)
				list(APPEND covFiles ${files})
			endforeach()

			# delete output command
			# OpenCppCoverage will issue an error if the output directory already exists.
			set( cleanDirCommand "cmake -E remove_directory \"${htmlReportDir}\"")
        
			# assemble OpenCppCoverage command
			set( openCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" ")
			foreach( file ${covFiles} )
				string(APPEND openCppCoverageCommand "--input_coverage=\"${file}\" ")
			endforeach()
			string(APPEND openCppCoverageCommand "--export_type=html:\"${htmlReportDir}\" ")
			string(APPEND openCppCoverageCommand "--quiet")

			# stampfile command
			set( stampFile ${CMAKE_BINARY_DIR}/${targetName}/${targetName}.stamp )
			set( stampFileCommand "cmake -E touch \"${stampFile}\"")
        
			cpfAddConfigurationDependendCommand(
				TARGET ${targetName}
				OUTPUT "${stampFile}"
				DEPENDS ${covFiles} ${dynamicAnalysisTargets}
				COMMENT ${command}
				CONFIG Debug
				COMMANDS_CONFIG ${cleanDirCommand} ${openCppCoverageCommand} ${stampFileCommand}
				COMMANDS_NOT_CONFIG ${stampFileCommand}
			)

			add_custom_target(
				${targetName}
				DEPENDS ${dynamicAnalysisTargets} ${stampFile}
			)

		endif()
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Creates the custom target that runs the test executable with valgrind.
# 
# This will only be added when the configuration uses gcc and debug flags.
#
function( cpfAddValgrindTarget package)

	if(NOT CPF_ENABLE_DYNAMIC_ANALYSIS_TARGET)
		return()
	endif()

	set(targetName valgrind_${package})
	set(binaryDir ${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName})
	file(MAKE_DIRECTORY ${binaryDir})
		
	# check preconditions
	cpfAssertDefined(CPF_TEST_FILES_DIR)

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY CPF_PRODUCTION_LIB_SUBTARGET)
	get_property(testTarget TARGET ${package} PROPERTY CPF_TESTS_SUBTARGET)
	if(TARGET ${testTarget})
	
		# add Valgrind commands if possible
		cpfIsGccClangDebug(gccClangDebug)
		if(gccClangDebug) # muss auf gcc mit debug symbolen testen

			cpfFindRequiredProgram( TOOL_VALGRIND valgrind "A tool for dynamic analysis.")
			
			# add valgrind commands
			set(stampFile "${binaryDir}/Valgrind_${testTarget}.stamp")
			set(suppressionsFile "${CMAKE_CURRENT_SOURCE_DIR}/Other/${package}ValgrindSuppressions.supp")
			set(valgrindCommand "\"${TOOL_VALGRIND}\" --leak-check=full --track-origins=yes --smc-check=all --error-exitcode=1 --gen-suppressions=all --suppressions=\"${suppressionsFile}\" \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CPF_TEST_FILES_DIR}/${CPF_CONFIG}/dynmicAnalysis_${testTarget}\"")
				
			cpfAddStandardCustomCommand(
				OUTPUT ${stampFile}
				DEPENDS "$<TARGET_FILE:${testTarget}>" "$<TARGET_FILE:${productionLib}>"
				COMMANDS "${valgrindCommand}" "cmake -E touch \"${stampFile}\""
			)

			add_custom_target(
				${targetName}
				DEPENDS ${productionLib} ${testTarget} ${stampFile}
			)

			set_property( TARGET ${package} PROPERTY CPF_VALGRIND_SUBTARGET ${targetName})
			set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")

		endif()
	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
# Creates the custom target that runs the test executable with OpenCppCoverage.
# The configuration must use MSVC enable this. OpenCppCoverage will only be run
# when compiling with debug flags.
# 
function( cpfAddOpenCppCoverageTarget package)

	if(NOT CPF_ENABLE_DYNAMIC_ANALYSIS_TARGET)
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
			list(APPEND coverageOutputFiles ${coverageOutput})

			set(removeTempCovFileComand "cmake -E remove -f \"${coverageOutputTemp}\"") # we need to try to remove this to cover cases where the OpenCppCoverage command fails and the temp file does not get renamed.
			set(openCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" --export_type=binary:\"${coverageOutputTemp}\" --sources=\"**\\${CPF_SOURCE_DIR}\\${package}\" --quiet -- \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CPF_TEST_FILES_DIR}/${CPF_CONFIG}/dynmicAnalysis_${testTarget}\"")
			set(cmakeRenameCommand "cmake -E rename \"${coverageOutputTemp}\" \"${coverageOutput}\"")
			# we use an extra stampfile to make sure that marking the target done works even if the commands are only the echos for non debug configs.
			set(stampFile ${binaryDir}/OpenCppCoverage_${testTarget}.stamp )
			set(stampFileCommand "cmake -E touch \"${stampFile}\"")

			cpfAddConfigurationDependendCommand(
				TARGET ${targetName}
				OUTPUT ${stampFile}
				DEPENDS "$<TARGET_FILE:${testTarget}>" "$<TARGET_FILE:${productionLib}>"
				COMMENT "Run OpenCppCoverage for ${testTarget}."
				CONFIG ${msvcDebugConfig}
				COMMANDS_CONFIG ${removeTempCovFileComand} ${openCppCoverageCommand} ${cmakeRenameCommand} ${stampFileCommand}
				COMMANDS_NOT_CONFIG ${stampFileCommand}
			)
			
			# debug: try if sporadic build errors stop if packaging does not happen at the same time.
			#set( debugDependency distributionPackages_${package} )

			add_custom_target(
				${targetName}
				DEPENDS ${productionLib} ${testTarget} ${stampFile}
			)

			# set properties related to the static analysis target
			set_property( TARGET ${package} PROPERTY CPF_OPENCPPCOVERAGE_SUBTARGET ${targetName})
			set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")
			set_property( TARGET ${targetName} PROPERTY CPF_CPPCOVERAGE_OUTPUT ${coverageOutputFiles} )
		endif()

	endif()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetFirstMSVCDebugConfig configOut )
	cpfGetConfigurations( configs )
	foreach(config ${configs})
		isMSVCDebugConfig(isDebugConfig ${config})
		if( isDebugConfig )
			set( ${configOut} ${config} PARENT_SCOPE)
			return()
		endif()		
	endforeach()
	set( ${configOut} "" PARENT_SCOPE)
endfunction()

