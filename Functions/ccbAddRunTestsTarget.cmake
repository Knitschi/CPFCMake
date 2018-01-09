
include(ccbCustomTargetUtilities)
include(ccbLocations)
include(ccbBaseUtilities)

#----------------------------------------------------------------------------------------
# Creates a custom target that executes all unit and expensive tests of the given packages
#
function( ccbAddGlobalRunAllTestsTarget packages)

	if(CCB_ENABLE_RUN_TESTS_TARGET)
		ccbAddSubTargetBundleTarget( runAllTests "${packages}" CCB_RUN_TESTS_SUBTARGET "")
	endif()
	
endfunction()



#----------------------------------------------------------------------------------------
# Creates a custom target that executes all unit tests of the given packages

function( ccbAddGlobalRunUnitTestsTarget packages)

	if(CCB_ENABLE_RUN_TESTS_TARGET)
		ccbAddSubTargetBundleTarget( runFastTests "${packages}" CCB_RUN_FAST_TESTS_SUBTARGET "")
	endif()
	
endfunction()


#----------------------------------------------------------------------------------------
# Creates a custom target that executes the given test executable when "build"
# Note that this function will add no target if the global CCB_ENABLE_RUN_TESTS_TARGET is set to FALSE
# 
# unitTestTarget : The name of t
function( ccbAddRunCppTestsTargets package)

	if(CCB_ENABLE_RUN_TESTS_TARGET)

		ccbAssertDefined(CCB_TEST_FILES_DIR)
		
		# add target that runs all tests
		ccbAddRunCppTestTarget( runTargetName ${package} ${CCB_RUN_ALL_TESTS_TARGET_PREFIX} "*" )
        set_property( TARGET ${package} PROPERTY CCB_RUN_TESTS_SUBTARGET ${runTargetName})

		# add target that runs only the fast tests
		ccbAddRunCppTestTarget( runTargetName ${package} runFastTests_ "*FastFixture*:*FastTests*" )
        set_property( TARGET ${package} PROPERTY CCB_RUN_FAST_TESTS_SUBTARGET ${runTargetName})

	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddRunCppTestTarget runTargetNameArg package runTargetNamePrefix testFilter )

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY CCB_PRODUCTION_LIB_SUBTARGET)
    get_property(testTarget TARGET ${package} PROPERTY CCB_TESTS_SUBTARGET)
	if(TARGET ${testTarget})

		set(runTargetName ${runTargetNamePrefix}${package})
		getRunTestStampFile( stampFile ${runTargetName} ${runTargetNamePrefix})

		# We need to add an explicit dependency to the production lib executable, because when using dynamic linkage,
		# the test executable is not rebuild when we only change the .cpp files of the production lib.
		ccbAddStandardCustomCommand(
			DEPENDS "$<TARGET_FILE:${testTarget}>" "$<TARGET_FILE:${productionLib}>" ${productionLib} ${testTarget}
			OUTPUT "${stampFile}" 
			COMMANDS "$<TARGET_FILE:${testTarget}> -TestFilesDir \"${CCB_TEST_FILES_DIR}/${runTargetName}\" --gtest_filter=${testFilter}" "cmake -E touch \"${stampFile}\""
		)

		add_custom_target(
			${runTargetName}
			DEPENDS ${productionLib} ${testTarget} "${stampFile}"
		)

		set_property( TARGET ${runTargetName} PROPERTY FOLDER "${package}/pipeline")

		set(${runTargetNameArg} ${runTargetName} PARENT_SCOPE)

	endif()
endfunction()


#----------------------------------------------------------------------------------------
function( getRunTestStampFile filenameOut runTargetName targetPrefix )
	
	set(targetBinaryDir "${CMAKE_BINARY_DIR}/${targetPrefix}tests_stamps")
	file(MAKE_DIRECTORY "${targetBinaryDir}")
	set(stampFile "${targetBinaryDir}/${runTargetName}.stamp")

	set(${filenameOut} ${stampFile} PARENT_SCOPE)

endfunction()


#----------------------------------------------------------------------------------------
function( ccbAddRunPython3TestTarget package testScript sourceFiles )

	if(TOOL_PYTHON3)

		set(runTargetName ${CCB_RUN_ALL_TESTS_TARGET_PREFIX}${PACKAGE_NAME})
		getRunTestStampFile( stampFile ${runTargetName} ${CCB_RUN_ALL_TESTS_TARGET_PREFIX})

		set( runTestsCommand "\"${TOOL_PYTHON3}\" \"${CMAKE_CURRENT_SOURCE_DIR}/${testScript}\"")
		set( touchCommand "cmake -E touch \"${stampFile}\"" )

		ccbAddStandardCustomCommand(
			DEPENDS "${sourceFiles}"
			OUTPUT "${stampFile}"
			COMMANDS ${runTestsCommand} ${touchCommand}
		)

		add_custom_target(
			${runTargetName}
			DEPENDS "${stampFile}"
		)

		set_property( TARGET ${runTargetName} PROPERTY FOLDER "${package}/pipeline")
		set_property( TARGET ${PACKAGE_NAME} PROPERTY CCB_RUN_TESTS_SUBTARGET ${runTargetName})

	endif()

endfunction()