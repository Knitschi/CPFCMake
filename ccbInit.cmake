# This file ccbContains the main functions of the CppCodeBase cmake module.

set(DIR_OF_INIT_FILE ${CMAKE_CURRENT_LIST_DIR})

list( APPEND 
	CMAKE_MODULE_PATH 
	"${DIR_OF_INIT_FILE}/Functions"
	"${DIR_OF_INIT_FILE}/Variables"
	"${DIR_OF_INIT_FILE}"
)

include(ccbLocations)
include(ccbProperties)
include(ccbProjectUtilities)
include(ccbBaseUtilities)
	
include(ccbAddDocumentationTarget)
include(ccbAddStaticAnalysisTarget)
include(ccbAddPipelineTarget)
include(ccbAddRunTestsTarget)
include(ccbAddInstallPackageTarget)
include(ccbAddCompatibilityCheckTarget)

# cotire must be included on the global scope or we get errors thta target xyz already has a custom rule
include("${CMAKE_SOURCE_DIR}/cotire/CMake/cotire.cmake")

cmake_minimum_required (VERSION ${CCB_MINIMUM_CMAKE_VERSION})


#----------------------------------------------------------------------------------------
function( ccbInit )

	# generate a .gitignore file that contains the generated files of the CppCodeBase
	configure_file( "${DIR_OF_INIT_FILE}/Templates/.gitignore.in" "${CCB_ROOT_DIR}/.gitignore" COPYONLY )

	# generate the file with the graphviz options
	configure_file( "${DIR_OF_INIT_FILE}/Templates/${CCB_GRAPHVIZ_OPTIONS_FILE}.in" "${CMAKE_BINARY_DIR}/${CCB_GRAPHVIZ_OPTIONS_FILE}" COPYONLY )
	
	ccbDebugMessage("Using toolchain file: \"${CMAKE_TOOLCHAIN_FILE}\"")
	ccbPrintToolchainVariables()

	####################################### OTHER GLOBAL SETTINGS #########################################    
	# Define properties that are used within the CppCodeBase cmake code.
	ccbDefineProperties()
	ccbSetPolicies()

    
	# allow project folders
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)
	set_property(GLOBAL PROPERTY AUTOGEN_TARGETS_FOLDER private)
	set_property(GLOBAL PROPERTY AUTOGEN_SOURCE_GROUP Generated)

	# The IDE folder for files generated by qt.
	set(AUTOGEN_TARGETS_FOLDER private PARENT_SCOPE)
	set(AUTOGEN_SOURCE_GROUP Generate PARENT_SCOPE)

	ccbFindRequiredTools()

	# assert variables
	
	# We expect the CMAKE_BUILD_TYPE to be set for single configuration generators.
	# This helps to make some config dependent code simpler.
	if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
		message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set when using a single-config generator.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Set policies to silence the warnings about changed cmake behavior.
function( ccbSetPolicies )
	cmake_policy(SET CMP0071 NEW)
	cmake_policy(SET CMP0007 NEW) # Do not ignore empty list elements
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddPackages packages globalFiles )

	# set various flags non binary relevant flats like warnings as errors and higher warning levels.
	ccbSetDynamicAndCosmeticCompilerOptions()

	# Add optional CppCodeBase packages.
	set( ccbPackageDirs
		${CCB_CPPCODEBASECMAKE_DIR}
		${CCB_PROJECT_CONFIGURATIONS_DIR}
		${CCB_BUILDSCRIPTS_DIR}
		${CCB_JENKINSFILE_DIR}
		${CCB_MACHINES_DIR}
	)
	foreach( dir ${ccbPackageDirs})
		if(EXISTS ${CMAKE_SOURCE_DIR}/${dir} )
			list(APPEND packages ${dir})
		endif()
	endforeach()

	foreach( package ${packages})
		add_subdirectory (${package})
	endforeach()

	# GlobalFiles
	# A target that holds some project wide files
	set( SOLUTION_FILES 
		${globalFiles}
		${CCB_SWITCH_WARNINGS_OFF_MACRO_FILE}
		CMakeLists.txt
		"${CCB_CONFIG_FILE}"
		"${CMAKE_BINARY_DIR}/CMakeCache.txt"
	)
	
	if(CCB_ENABLE_DOXYGEN_TARGET)
		list(APPEND SOLUTION_FILES 
			DoxygenConfig.txt 
			DoxygenLayout.xml
		)
	endif()

	if(CCB_ENABLE_STATIC_ANALYSIS_TARGET)
		list(APPEND SOLUTION_FILES 
			"${CMAKE_BINARY_DIR}/${CCB_GRAPHVIZ_OPTIONS_FILE}" # CMake looks for the file in the source directory, so it can not be put in the cmake directory.
		)
	endif()

	add_custom_target( globalFiles SOURCES ${SOLUTION_FILES})


	# documentation
	ccbAddGlobalMonolithicDocumentationTarget("${packages}")
	# staticAnalysis
	ccbAddGlobalStaticAnalysisTarget("${packages}")
	# runUnitTests
	ccbAddGlobalRunUnitTestsTarget("${packages}")
	# runAllTests
	ccbAddGlobalRunAllTestsTarget("${packages}")
	# dynamicAnalysis
	ccbAddGlobalDynamicAnalysisTarget("${packages}")
	# distributionPackages
	ccbAddGlobalCreatePackagesTarget("${packages}")
	# abiComplianceCheck
	ccbAddGlobalAbiCheckerTarget("${packages}")
	# pipeline
	ccbAddPipelineTarget("${packages}")


endfunction()



