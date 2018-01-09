
include(ccbCustomTargetUtilities)
include(ccbLocations)
include(ccbBaseUtilities)

#----------------------------------------------------------------------------------------
# Creates the global dynamic analysis target that depends on the individual dynamic analysis targets
# and creates the html report using the .gov files of the individual targets.
#
function( ccbAddGlobalDynamicAnalysisTarget packages)
	
	if(NOT CCB_ENABLE_RUN_TESTS_TARGET)
		return()
	endif()
		
	set(targetName dynamicAnalysis)

	ccbIsGccClangDebug(gccClangDebug)
	if(gccClangDebug)

		ccbAddSubTargetBundleTarget( ${targetName} ${packages} CCB_DYNAMIC_ANALYSIS_SUBTARGET "")
		
	elseif(MSVC)
		# add the OpenCppCoverage command that combines all intermediate outputs.
		
		#Locations
		set(htmlReportDir ${CCB_PROJECT_HTML_ABS_DIR}/${CCB_OPENCPPCOVERAGE_DIR})

		ccbGetSubtargets(dynamicAnalysisTargets "${packages}" CCB_DYNAMIC_ANALYSIS_SUBTARGET)
		if(dynamicAnalysisTargets)

			foreach( target ${dynamicAnalysisTargets})
				get_property( files TARGET ${target} PROPERTY CCB_CPPCOVERAGE_OUTPUT)
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
        
			ccbAddConfigurationDependendCommand(
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
# Creates the custom target that does dynamic analysis of the test executables.
# 
# When compiling with gcc and debug information, this will run the tests with Valgrind.
# When compiling with mscv and debug information, this will run the tests with OpenCppCoverage
#
function( ccbAddDynamicAnalysisTarget package)

	if(NOT CCB_ENABLE_RUN_TESTS_TARGET)
		return()
	endif()

	set(targetName dynamicAnalysis_${package})
	set(analysisTargetBinaryDir ${CMAKE_CURRENT_BINARY_DIR}/${targetName})
	file(MAKE_DIRECTORY ${analysisTargetBinaryDir})
		
	# check preconditions
	ccbAssertDefined(CCB_TEST_FILES_DIR)

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY CCB_PRODUCTION_LIB_SUBTARGET)
	get_property(testTarget TARGET ${package} PROPERTY CCB_TESTS_SUBTARGET)
	if(TARGET ${testTarget})
	
		# add Valgrind commands if possible
		ccbIsGccClangDebug(gccClangDebug)
		if(gccClangDebug) # muss auf gcc mit debug symbolen testen

			ccbFindRequiredProgram( TOOL_VALGRIND valgrind "A tool for dynamic analysis.")
			
			# add valgrind commands
			set(stampFile "${analysisTargetBinaryDir}/Valgrind_${testTarget}.stamp")
			list(APPEND stampFiles ${stampFile})
				
			set(suppressionsFile "${CMAKE_CURRENT_SOURCE_DIR}/Other/${package}ValgrindSuppressions.supp")
				
			set(valgrindCommand "\"${TOOL_VALGRIND}\" --leak-check=full --track-origins=yes --smc-check=all --error-exitcode=1 --gen-suppressions=all --suppressions=\"${suppressionsFile}\" \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CCB_TEST_FILES_DIR}/dynmicAnalysis_${testTarget}\"")
				
			ccbAddStandardCustomCommand(
				OUTPUT ${stampFile}
				DEPENDS "$<TARGET_FILE:${testTarget}>" "$<TARGET_FILE:${productionLib}>" ${testTarget}
				COMMANDS "${valgrindCommand}" "cmake -E touch \"${stampFile}\""
			)

		endif()

		# add OpenCppCoverage commands if possible
		ccbGetFirstMSVCDebugConfig( msvcDebugConfig )
		if(msvcDebugConfig) 
				
			ccbFindRequiredProgram( TOOL_OPENCPPCOVERAGE OpenCppCoverage "A tool that creates coverage reports for C++ binaries.")

			# add OpenCppCoverage commands
			set(coverageOutputTemp "${analysisTargetBinaryDir}/${testTarget}_temp.cov")
			set(coverageOutput "${analysisTargetBinaryDir}/${testTarget}.cov")
			list(APPEND coverageOutputFiles ${coverageOutput})

			set(removeTempCovFileComand "cmake -E remove -f \"${coverageOutputTemp}\"") # we need to try to remove this to cover cases where the OpenCppCoverage command fails and the temp file does not get renamed.
			set(openCppCoverageCommand "\"${TOOL_OPENCPPCOVERAGE}\" --export_type=binary:\"${coverageOutputTemp}\" --sources=\"**\\${CCB_SOURCE_DIR}\\${package}\" --quiet -- \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CCB_TEST_FILES_DIR}/dynmicAnalysis_${testTarget}\"")
			set(cmakeRenameCommand "cmake -E rename \"${coverageOutputTemp}\" \"${coverageOutput}\"")
			# we use an extra stampfile to make sure that marking the target done works even if the commands are only the echos for non debug configs.
			set(stampFile ${analysisTargetBinaryDir}/OpenCppCoverage_${testTarget}.stamp )
			list(APPEND stampFiles ${stampFile})
			set( stampFileCommand "cmake -E touch \"${stampFile}\"")

			ccbAddConfigurationDependendCommand(
				TARGET ${targetName}
				OUTPUT ${stampFile}
				DEPENDS "$<TARGET_FILE:${testTarget}>" "$<TARGET_FILE:${productionLib}>" ${testTarget}
				COMMENT "Run OpenCppCoverage for ${testTarget}."
				CONFIG ${msvcDebugConfig}
				COMMANDS_CONFIG ${removeTempCovFileComand} ${openCppCoverageCommand} ${cmakeRenameCommand} ${stampFileCommand}
				COMMANDS_NOT_CONFIG ${stampFileCommand}
			)
			
			# debug: try if sporadic build errors stop if packaging does not happen at the same time.
			#set( debugDependency distributionPackages_${package} )

		endif()
			
		if(msvcDebugConfig OR gccClangDebug)
			add_custom_target(
				${targetName}
				DEPENDS ${productionLib} ${unitTestTarget} ${expensiveTestTarget} ${stampFiles} ${debugDependency}
			)

			# set properties related to the static analysis target
			set_property( TARGET ${package} PROPERTY CCB_DYNAMIC_ANALYSIS_SUBTARGET ${targetName})
			set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")
			set_property( TARGET ${targetName} PROPERTY CCB_CPPCOVERAGE_OUTPUT ${coverageOutputFiles} )
		endif()

	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetFirstMSVCDebugConfig configOut )
	ccbGetConfigurations( configs )
	foreach(config ${configs})
		isMSVCDebugConfig(isDebugConfig ${config})
		if( isDebugConfig )
			set( ${configOut} ${config} PARENT_SCOPE)
			return()
		endif()		
	endforeach()
	set( ${configOut} "" PARENT_SCOPE)
endfunction()

