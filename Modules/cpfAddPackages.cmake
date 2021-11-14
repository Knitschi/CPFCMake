# This file contains the main functions of the CMakeProjectFramework cmake module.

include_guard(GLOBAL)

include(cpfLocations)
include(cpfProperties)
include(cpfProjectUtilities)
include(cpfAddDoxygenPackage)
include(cpfAddClangFormatTarget)
include(cpfAddClangTidyTarget)
include(cpfAddAcyclicTarget)
include(cpfAddPipelineTargetDependencies)
include(cpfAddRunTestsTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDistributionPackageTarget)
include(cpfAddValgrindTarget)
include(cpfAddOpenCppCoverageTarget)
include(cpfGTAUtilities)


#----------------------------------------------------------------------------------------
# Note that the package-components that are owned by the CPF CI-Project must be added via the
# packages.cmake file.
#
# Keyword Arguments:
# [GLOBAL_FILES]		A list of files that will be added to the globalFiles file package.
#
#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function( cpfAddPackages )

	cmake_parse_arguments( ARG "" "" "GLOBAL_FILES" ${ARGN})

	cpfInitGlobalState()

	# Add the pipeline target early so package-components can add them self as dependencies to it.
	add_custom_target(pipeline)

	# Add the package projects
	cpfAddPackageSubdirectories()

	# GlobalFiles
	# A target that holds some project wide files
	cpfGetFullConfigFilePath(configFile ${CPF_CONFIG})
	set( SOLUTION_FILES 
		${ARG_GLOBAL_FILES}
		CMakeLists.txt
		"${configFile}"
		#CMakePresets.json
		"${CMAKE_BINARY_DIR}/CMakeCache.txt"
		"${CPF_PACKAGES_FILE}"
	)

	if(CPF_ENABLE_CLANG_TIDY_TARGET)
		cpfListAppend( SOLUTION_FILES 
			"${CMAKE_BINARY_DIR}/${CPF_GRAPHVIZ_OPTIONS_FILE}"
		)
	endif()

	set_property(TARGET pipeline PROPERTY SOURCES ${SOLUTION_FILES})

	cpfGetAllPackages(packages)
	cpfGetOwnedPackages(ownedPackages "${CPF_ROOT_DIR}")

	# clang format
	cpfAddGlobalClangFormatTarget("${ownedPackages}" )
	# clang-tidy
	cpfAddGlobalClangTidyTarget("${packages}")
	# acyclic
	cpfAddAcyclicTarget()
	# runUnitTests
	cpfAddGlobalRunUnitTestsTarget("${packages}")
	# runAllTests
	cpfAddGlobalRunAllTestsTarget("${packages}")
	# valgrind
	cpfAddGlobalValgrindTarget("${packages}")
	# opencppcoverage
	cpfAddGlobalOpenCppCoverageTarget("${packages}")
	# distributionPackages
	cpfAddGlobalCreatePackagesTarget("${packages}")
	# abiComplianceCheck
	cpfAddGlobalAbiCheckerTarget("${packages}")
	# install_all target
	cpfAddGlobalInstallTarget("${packages}")
	# pipeline
	cpfAddPipelineTargetDependencies("${packages}")

	# Generate GoogleTestAdapter settings
	cpfGenerateGoogleTestAdapterSettingsFile("${packages}")


endfunction()


#----------------------------------------------------------------------------------------
function( cpfInitGlobalState )

	# Generate a .gitignore file that contains the generated files of a CPFCMake project.
	# We do not overwrite it if it already exists to make sure clients can change it.
	set(gitIgnoreFile "${CPF_ROOT_DIR}/.gitignore" )
	if(NOT EXISTS "${gitIgnoreFile}")
		configure_file( "${CPF_ABS_TEMPLATE_DIR}/.gitignore.in" "${gitIgnoreFile}" COPYONLY )
	endif()

	# generate the file with the graphviz options
	configure_file( "${CPF_ABS_TEMPLATE_DIR}/${CPF_GRAPHVIZ_OPTIONS_FILE}.in" "${CMAKE_BINARY_DIR}/${CPF_GRAPHVIZ_OPTIONS_FILE}" COPYONLY )

	cpfDebugMessage("Using toolchain file: \"${CMAKE_TOOLCHAIN_FILE}\"")
	cpfPrintToolchainVariables()

	# Define properties that are used within the CPFCMake code.
	cpfDefineProperties()

	# allow project folders
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)

	# Search for tool dependencies.
	cpfFindRequiredTools()

	# We expect the CMAKE_BUILD_TYPE to be set for single configuration generators.
	# This helps to make some config dependent code simpler.
	if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
		message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set when using a single-config generator.")
	endif()

	# We remember the name of the ci-project for cases where we need it
	# after creating the package projects.
	set(CPF_CI_PROJECT ${CMAKE_PROJECT_NAME} PARENT_SCOPE)

endfunction()






