
include(ccbCustomTargetUtilities)
include(ccbLocations)
include(ccbBaseUtilities)

#----------------------------------------------------------------------------------------
# Creates a custom target that executes all unit and expensive tests of the given packages
#
function( ccbAddGlobalRunAllTestsTarget packages)

	if(CCB_ENABLE_RUN_TESTS_TARGET)
		
		set(targetName runAllTests)

		ccbGetSubtargets(runSlowTestsTargets "${packages}" CCB_RUN_TESTS_SUBTARGET)

		# We also need to run the unit tests for the python code.
		# Maybe the python files should be added to target which has a runAllTests_<package> subtarget.
		if(TOOL_PYTHON3)
			
			set( pythonDir "${CCB_ROOT_DIR}/${CCB_SOURCE_DIR}/CppCodeBaseBuildscripts" )
			set(pythonFiles
				${pythonDir}/cppcodebasebuildscripts/buildautomat.py
			)

			set(stampFile "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/runPythonTests.stamp")
			set(runTestsCommand "\"${TOOL_PYTHON3}\" \"${pythonDir}/run_tests.py\"")
			set( touchCommand "cmake -E touch \"${stampFile}\"" )

			ccbAddStandardCustomCommand(
				TARGET ${targetName}
				OUTPUT ${stampFile}
				DEPENDS ${pythonFiles}
				COMMANDS ${runTestsCommand} ${touchCommand}
			)
		endif()

		add_custom_target(
			${targetName}
			DEPENDS ${runSlowTestsTargets} ${stampFile}
		)

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
function( ccbAddRunTestsTargets package)

	if(CCB_ENABLE_RUN_TESTS_TARGET)

		ccbAssertDefined(CCB_TEST_FILES_DIR)
		
		# add target that runs all tests
		ccbAddRunTestTarget( runTargetName ${package} runAllTests_ "*" )
        set_property( TARGET ${package} PROPERTY CCB_RUN_TESTS_SUBTARGET ${runTargetName})

		# add target that runs only the fast tests
		ccbAddRunTestTarget( runTargetName ${package} runFastTests_ "*FastFixture*:*FastTests*" )
        set_property( TARGET ${package} PROPERTY CCB_RUN_FAST_TESTS_SUBTARGET ${runTargetName})

	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddRunTestTarget runTargetNameArg package runTargetNamePrefix testFilter )

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY CCB_PRODUCTION_LIB_SUBTARGET)
    get_property(testTarget TARGET ${package} PROPERTY CCB_TESTS_SUBTARGET)

	set(runTargetName ${runTargetNamePrefix}${package})
	set(targetBinaryDir "${CMAKE_BINARY_DIR}/${runTargetNamePrefix}tests_stamps")
	file(MAKE_DIRECTORY "${targetBinaryDir}")
    set(stampFile "${targetBinaryDir}/${runTargetName}.stamp")

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

endfunction()