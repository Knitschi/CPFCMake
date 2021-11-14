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
function( cpfAddRunCppTestsTargets package arguments)

	if(CPF_ENABLE_RUN_TESTS_TARGET)

		cpfAssertDefined(CPF_TEST_FILES_DIR)
		
		# add target that runs all tests
		cpfAddRunCppTestTarget( runTargetName ${package} ${CPF_RUN_ALL_TESTS_TARGET_PREFIX} "*" "${arguments}" )
        set_property( TARGET ${package} PROPERTY INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET ${runTargetName})

		# add target that runs only the fast tests
		cpfAddRunCppTestTarget( runTargetName ${package} runFastTests_ "*FastFixture*:*FastTests*" "${arguments}")
        set_property( TARGET ${package} PROPERTY INTERFACE_CPF_RUN_FAST_TESTS_SUBTARGET ${runTargetName})

	endif()

	cpfIsVisualStudioGenerator(isVS)
	if(isVS)
	    get_property(testTarget TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET)
		if(TARGET ${testTarget})
			cpfJoinArguments(argumentString "${arguments}")
			set_property(TARGET ${testTarget} PROPERTY VS_DEBUGGER_COMMAND_ARGUMENTS ${argumentString})
		endif()
	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddRunCppTestTarget runTargetNameArg package runTargetNamePrefix testFilter arguments )

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
			COMMAND $<TARGET_FILE:${testTarget}> ${arguments} --gtest_filter=${testFilter}
			COMMAND cmake -E touch "${stampFile}"
		)

		add_custom_target(
			${runTargetName}
			DEPENDS ${productionLib} ${testTarget} "${stampFile}"
		)

		set_property( TARGET ${runTargetName} PROPERTY FOLDER "${package}/test")

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
function( cpfAddRunPython3TestTarget testScript args sourceFiles dependedOnTargets dependedOnExternalFiles)
	if(TOOL_PYTHON3)

		# Since there is no generated file for the depended on cmake packages, we get there source files instead
		# to make the out-of-date mechanism work.
		cpfGetAllDependedOnSourceFiles(sourceFiles "${sourceFiles}" "${dependedOnTargets}")
		# Get the basic command for running a python script in module mode
		cpfGetRunPythonModuleCommand( runScriptCommand "${CMAKE_CURRENT_SOURCE_DIR}/${testScript}")
		set( runTestsCommand "${runScriptCommand} ${args}")
		cpfAddCustomTestTarget(${runTestsCommand} "${sourceFiles}" "${dependedOnExternalFiles}" )

	endif()
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetRunPythonModuleCommand commandOut fullScriptPath )

	# derive the python module path from the script path
	file( RELATIVE_PATH pathToTestScript ${CPF_ROOT_DIR} "${fullScriptPath}")
	string(REPLACE "/" "." pythonModulePath "${pathToTestScript}" )
	# remove the .py ending
	cpfStringRemoveRight( pythonModulePath ${pythonModulePath} 3)
	set(${commandOut} "\"${TOOL_PYTHON3}\" -u -m ${pythonModulePath}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddCustomTestTarget runTestsCommand sourceFiles dependedOnExternalFiles )

	cpfGetCurrentSourceDir(package)
	set(runTargetName ${CPF_RUN_ALL_TESTS_TARGET_PREFIX}${package})

	cpfAddCustomTestTargetWithName(${runTargetName} ${runTestsCommand} "${sourceFiles}" "${dependedOnExternalFiles}")

	set_property( TARGET ${runTargetName} PROPERTY FOLDER "${package}/pipeline")
	set_property( TARGET ${package} PROPERTY INTERFACE_CPF_RUN_TESTS_SUBTARGET ${runTargetName})

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddCustomTestTargetWithName targetName runTestsCommand sourceFiles dependedOnExternalFiles )

	getRunTestStampFile( stampFile ${targetName} ${CPF_RUN_ALL_TESTS_TARGET_PREFIX})
	set( touchCommand "cmake -E touch \"${stampFile}\"" )

	foreach(file ${sourceFiles} ${dependedOnExternalFiles})
		cpfIsAbsolutePath(isAbsPath ${file})
		if(NOT isAbsPath)
			message(FATAL_ERROR "DEPENDS requires absolute paths. The recived path was \"${file}\"")
		endif()
	endforeach()

	cpfAddStandardCustomCommand(
		DEPENDS ${sourceFiles} ${dependedOnExternalFiles}
		OUTPUT "${stampFile}"
		COMMANDS ${runTestsCommand} ${touchCommand}
	)

	add_custom_target(
		${targetName}
		DEPENDS "${stampFile}"
	)

endfunction()


#----------------------------------------------------------------------------------------
# Adds a run-tests target that runs a cmake script
function( cpfAddRunCMakeTestScriptTarget testScript sourceFiles)
	
	cpfToAbsSourcePaths( absSourceFiles "${sourceFiles}" ${CMAKE_CURRENT_SOURCE_DIR})
	
	set( runTestsCommand "cmake -P \"${CMAKE_CURRENT_SOURCE_DIR}/${testScript}\"")

	cpfAddCustomTestTarget(${runTestsCommand} "${absSourceFiles}" "")

endfunction()


#----------------------------------------------------------------------------------------
# This function adds a target for each of the given test modules so they can be run in parallel.
# It is the clients responsibility to ensure that there is no interaction between the test-cases of two
# different modules.
function( cpfAddRunPython3TestTargetForEachModule testScript modules args sourceFiles dependedOnTargets dependedOnExternalFiles)
	if(TOOL_PYTHON3)

		cpfGetCurrentSourceDir(package)
		set(runModuleTestsTargets)

		# Add one run target for each test module
		foreach(moduleFile ${modules})

			# remove the .py ending
			cpfStringRemoveRight( module ${moduleFile} 3)

			# Since there is no generated file for the depended on cmake packages, we get there source files instead
			# to make the out-of-date mechanism work.
			set(sourceFilesPlusModule)
			cpfGetAllDependedOnSourceFiles(sourceFilesPlusModule "${sourceFiles};${moduleFile}" "${dependedOnTargets}")
			# Get the basic command for running a python script in module mode
			cpfGetRunPythonModuleCommand( runScriptCommand "${CMAKE_CURRENT_SOURCE_DIR}/${testScript}")
			set( runTestsCommand "${runScriptCommand} ${args} module=${module}")

			set(runTargetName run_${module})
			cpfListAppend(runModuleTestsTargets ${runTargetName})
			cpfAddCustomTestTargetWithName( ${runTargetName} ${runTestsCommand} "${sourceFilesPlusModule}" "${dependedOnExternalFiles}")
			set_property( TARGET ${runTargetName} PROPERTY FOLDER "${package}/private")

		endforeach()

		# Add a bundle target to run all module test targets.
		set(bundleTestTarget ${CPF_RUN_ALL_TESTS_TARGET_PREFIX}${package})
		cpfAddBundleTarget(${bundleTestTarget} "${runModuleTestsTargets}")
		set_property( TARGET ${bundleTestTarget} PROPERTY FOLDER "${package}/pipeline")
		set_property( TARGET ${package} PROPERTY INTERFACE_CPF_RUN_TESTS_SUBTARGET ${bundleTestTarget})

	endif()
endfunction()


