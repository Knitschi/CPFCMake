include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)

#----------------------------------------------------------------------------------------
# Creates a custom target that executes all unit and expensive tests of the given packages
#
function( cpfAddGlobalRunAllTestsTarget packages)

	if(CPF_ENABLE_RUN_TESTS_TARGET)
		cpfAddSubTargetBundleTarget( runAllTests "${packages}" INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET "")
	endif()
	
endfunction()



#----------------------------------------------------------------------------------------
# Creates a custom target that executes all unit tests of the given packages

function( cpfAddGlobalRunUnitTestsTarget packages)

	if(CPF_ENABLE_RUN_TESTS_TARGET)
		cpfAddSubTargetBundleTarget( runFastTests "${packages}" INTERFACE_CPF_RUN_FAST_TESTS_SUBTARGET "")
	endif()
	
endfunction()


#----------------------------------------------------------------------------------------
# Creates a custom target that executes the given test executable when "build"
# Note that this function will add no target if the global CPF_ENABLE_RUN_TESTS_TARGET is set to FALSE
# 
# unitTestTarget : The name of t
function( cpfAddRunCppTestsTargets package)

	if(CPF_ENABLE_RUN_TESTS_TARGET)

		cpfAssertDefined(CPF_TEST_FILES_DIR)
		
		# add target that runs all tests
		cpfAddRunCppTestTarget( runTargetName ${package} ${CPF_RUN_ALL_TESTS_TARGET_PREFIX} "*" )
        set_property( TARGET ${package} PROPERTY INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET ${runTargetName})

		# add target that runs only the fast tests
		cpfAddRunCppTestTarget( runTargetName ${package} runFastTests_ "*FastFixture*:*FastTests*" )
        set_property( TARGET ${package} PROPERTY INTERFACE_CPF_RUN_FAST_TESTS_SUBTARGET ${runTargetName})

	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddRunCppTestTarget runTargetNameArg package runTargetNamePrefix testFilter )

	# get related targets
	get_property(productionLib TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
    get_property(testTarget TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET)
	if(TARGET ${testTarget})

		set(runTargetName ${runTargetNamePrefix}${package})
		getRunTestStampFile( stampFile ${runTargetName} ${runTargetNamePrefix})

		cpfGetTargetFileGeneratorExpression(prodLibFile ${productionLib})

		# We need to add an explicit dependency to the production lib executable, because when using dynamic linkage,
		# the test executable is not rebuild when we only change the .cpp files of the production lib.
		cpfAddStandardCustomCommand(
			DEPENDS "$<TARGET_FILE:${testTarget}>" ${prodLibFile} ${productionLib} ${testTarget}
			OUTPUT "${stampFile}" 
			COMMANDS "$<TARGET_FILE:${testTarget}> -TestFilesDir \"${CPF_TEST_FILES_DIR}/${CPF_CONFIG}/${runTargetName}\" --gtest_filter=${testFilter}" "cmake -E touch \"${stampFile}\""
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
# Adds a run-tests target that runs a pyhton script
# dependedOnPackages -> This argument is used to outdate the test target if the sources of some
# other package/target change. This is usefull if the tests internally use functionality from
# an external package.
function( cpfAddRunPython3TestTarget testScript args sourceFiles dependedOnPackages dependedOnExternalFiles)
	if(TOOL_PYTHON3)

		cpfPrependMulti( sourceFiles "${CMAKE_CURRENT_SOURCE_DIR}/" "${sourceFiles}")

		# Get the sources from the depended on packages.
		foreach( package ${dependedOnPackages})
			getAbsPathsOfTargetSources( absSources ${package})
			cpfListAppend( sourceFiles "${absSources}")
		endforeach()

		# derive the python module path from the script path
		file( RELATIVE_PATH pathToTestScript ${CPF_ROOT_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/${testScript}")
		string(REPLACE "/" "." pythonModulePath "${pathToTestScript}" )
		# remove the .py ending
		cpfStringRemoveRight( pythonModulePath ${pythonModulePath} 3)

		set( runTestsCommand "\"${TOOL_PYTHON3}\" -u -m ${pythonModulePath} ${args}")
		cpfAddCustomTestTarget(${runTestsCommand} "${sourceFiles}" "${dependedOnExternalFiles}" )

	endif()
endfunction()


#----------------------------------------------------------------------------------------
function( cpfAddCustomTestTarget runTestsCommand sourceFiles dependedOnExternalFiles )

	cpfGetPackageName(package)

	set(runTargetName ${CPF_RUN_ALL_TESTS_TARGET_PREFIX}${package})
	getRunTestStampFile( stampFile ${runTargetName} ${CPF_RUN_ALL_TESTS_TARGET_PREFIX})
	set( touchCommand "cmake -E touch \"${stampFile}\"" )

	cpfAddStandardCustomCommand(
		DEPENDS ${sourceFiles} ${dependedOnExternalFiles}
		OUTPUT "${stampFile}"
		COMMANDS ${runTestsCommand} ${touchCommand}
	)

	add_custom_target(
		${runTargetName}
		DEPENDS "${stampFile}"
	)

	set_property( TARGET ${runTargetName} PROPERTY FOLDER "${package}/pipeline")
	set_property( TARGET ${package} PROPERTY INTERFACE_RUN_TESTS_SUBTARGET ${runTargetName})

endfunction()


#----------------------------------------------------------------------------------------
# Adds a run-tests target that runs a cmake script
function( cpfAddRunCMakeTestScriptTarget testScript sourceFiles)
	set( runTestsCommand "cmake -P \"${CMAKE_CURRENT_SOURCE_DIR}/${testScript}\"")
	cpfAddCustomTestTarget(${runTestsCommand} "${sourceFiles}" "")
endfunction()


