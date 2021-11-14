include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)

#----------------------------------------------------------------------------------------
#
function( cpfAddGlobalValgrindTarget packages)

    if(NOT CPF_ENABLE_VALGRIND_TARGET)
        return()
    endif()

    cpfIsGccClangDebug(gccClangDebug)
    if(gccClangDebug)
        cpfAddSubTargetBundleTarget( valgrind "${packages}" INTERFACE_CPF_VALGRIND_SUBTARGET "")
    endif()

endfunction()

#----------------------------------------------------------------------------------------
# Creates the custom target that runs the test executable with valgrind.
# 
# This will only be added when the configuration uses gcc and debug flags.
#
function( cpfAddValgrindTarget package)

	if(NOT CPF_ENABLE_VALGRIND_TARGET)
		return()
	endif()

	set(targetName valgrind_${packageComponent})
	set(binaryDir ${CMAKE_CURRENT_BINARY_DIR}/${targetName})
	file(MAKE_DIRECTORY ${binaryDir})
		
	# check preconditions
	cpfAssertDefined(CPF_TEST_FILES_DIR)

	# get related targets
	get_property(productionLib TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
	get_property(testTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET)
	if(TARGET ${testTarget})
	
		# add Valgrind commands if possible
		cpfIsGccClangDebug(gccClangDebug)
		if(gccClangDebug) # muss auf gcc mit debug symbolen testen

			cpfFindRequiredProgram( TOOL_VALGRIND valgrind "A tool for dynamic analysis." "")

			# add valgrind commands
			set(stampFile "${binaryDir}/Valgrind_${testTarget}.stamp")
			set(suppressionsFile "${CMAKE_CURRENT_SOURCE_DIR}/Other/${packageComponent}ValgrindSuppressions.supp")
			set(valgrindCommand "\"${TOOL_VALGRIND}\" --show-reachable=yes --error-limit=no --leak-check=full --track-origins=yes --smc-check=all --error-exitcode=1 --gen-suppressions=all --suppressions=\"${suppressionsFile}\" \"$<TARGET_FILE:${testTarget}>\" -TestFilesDir \"${CPF_TEST_FILES_DIR}/${CPF_CONFIG}/dynmicAnalysis_${testTarget}\"")
				
			cpfIsInterfaceLibrary(isInterfaceLib ${productionLib})
			set(productionLibFile)
			if(NOT isInterfaceLib)
				set(productionLibFile "$<TARGET_FILE:${productionLib}>")
			endif()

			cpfAddStandardCustomCommand(
				OUTPUT ${stampFile}
				DEPENDS "$<TARGET_FILE:${testTarget}>" ${productionLibFile}
				COMMANDS "${valgrindCommand}" "cmake -E touch \"${stampFile}\""
			)

			add_custom_target(
				${targetName}
				DEPENDS ${productionLib} ${testTarget} ${stampFile}
			)

			set_property( TARGET ${packageComponent} PROPERTY INTERFACE_CPF_VALGRIND_SUBTARGET ${targetName})
			set_property( TARGET ${targetName} PROPERTY FOLDER "${packageComponent}/pipeline")

		endif()
	endif()
	
endfunction()
