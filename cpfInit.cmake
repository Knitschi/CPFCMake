# This file cpfContains the main functions of the CMakeProjectFramework cmake module.

set(DIR_OF_INIT_FILE ${CMAKE_CURRENT_LIST_DIR})

list( APPEND 
	CMAKE_MODULE_PATH 
	"${DIR_OF_INIT_FILE}/Functions"
	"${DIR_OF_INIT_FILE}/Variables"
	"${DIR_OF_INIT_FILE}"
)

include(cpfLocations)
include(cpfProperties)
include(cpfProjectUtilities)
include(cpfBaseUtilities)
	
include(cpfAddDocumentationTarget)
include(cpfAddStaticAnalysisTarget)
include(cpfAddPipelineTarget)
include(cpfAddRunTestsTarget)
include(cpfAddInstallPackageTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDistributionPackageTarget)


# cotire must be included on the global scope or we get errors thta target xyz already has a custom rule
include("${CMAKE_SOURCE_DIR}/cotire/CMake/cotire.cmake")

cmake_minimum_required (VERSION ${CPF_MINIMUM_CMAKE_VERSION})


#----------------------------------------------------------------------------------------
function( cpfInit )

	# generate a .gitignore file that contains the generated files of a CPFCMake project
	configure_file( "${DIR_OF_INIT_FILE}/Templates/.gitignore.in" "${CPF_ROOT_DIR}/.gitignore" COPYONLY )

	# generate the file with the graphviz options
	configure_file( "${DIR_OF_INIT_FILE}/Templates/${CPF_GRAPHVIZ_OPTIONS_FILE}.in" "${CMAKE_BINARY_DIR}/${CPF_GRAPHVIZ_OPTIONS_FILE}" COPYONLY )
	
	cpfDebugMessage("Using toolchain file: \"${CMAKE_TOOLCHAIN_FILE}\"")
	cpfPrintToolchainVariables()

	####################################### OTHER GLOBAL SETTINGS #########################################    
	# Define properties that are used within the CPFCMake code.
	cpfDefineProperties()
	cpfSetPolicies()

    
	# allow project folders
	set_property(GLOBAL PROPERTY USE_FOLDERS ON)
	set_property(GLOBAL PROPERTY AUTOGEN_TARGETS_FOLDER private)
	set_property(GLOBAL PROPERTY AUTOGEN_SOURCE_GROUP Generated)

	# The IDE folder for files generated by qt.
	set(AUTOGEN_TARGETS_FOLDER private PARENT_SCOPE)
	set(AUTOGEN_SOURCE_GROUP Generate PARENT_SCOPE)

	cpfFindRequiredTools()

	# assert variables
	
	# We expect the CMAKE_BUILD_TYPE to be set for single configuration generators.
	# This helps to make some config dependent code simpler.
	if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
		message(FATAL_ERROR "CMAKE_BUILD_TYPE must be set when using a single-config generator.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Set policies to silence the warnings about changed cmake behavior.
function( cpfSetPolicies )
	cmake_policy(SET CMP0071 NEW)
	cmake_policy(SET CMP0007 NEW) # Do not ignore empty list elements
endfunction()

#----------------------------------------------------------------------------------------
# Note that the packages that are owned by the CPF CI-Project must be added via the
# cpfOwnedPackages.cmake file.
function( cpfAddPackages externalPackages globalFiles )

	# set various flags non binary relevant flats like warnings as errors and higher warning levels.
	cpfSetDynamicAndCosmeticCompilerOptions()

	# Read owned packages from the file
	cpfGetOwnedPackages( ownedPackages ${CPF_ROOT_DIR})
	set(packages ${ownedPackages})

	# Add optional CMakeProjectFramework packages.
	set( cpfPackageDirs
		${CPF_PROJECT_CONFIGURATIONS_DIR}
	)
	foreach( dir ${cpfPackageDirs})
		if(EXISTS ${CMAKE_SOURCE_DIR}/${dir} )
			list(APPEND packages ${dir})
		endif()
	endforeach()

	# We assume that the external packages are of lower level then the owned ones.
	# Is that always true? If not, we must provide a way to add them sorted by level.
	foreach( package ${externalPackages} ${packages} ) 
		add_subdirectory(${package})
	endforeach()

	# GlobalFiles
	# A target that holds some project wide files
	set( SOLUTION_FILES 
		${globalFiles}
		${CPF_SWITCH_WARNINGS_OFF_MACRO_FILE}
		CMakeLists.txt
		"${CPF_CONFIG_FILE}"
		"${CMAKE_BINARY_DIR}/CMakeCache.txt"
		"${CPF_OWNED_PACKAGES_FILE}"
	)
	
	if(CPF_ENABLE_DOXYGEN_TARGET)
		list(APPEND SOLUTION_FILES 
			DoxygenConfig.txt 
			DoxygenLayout.xml
		)
	endif()

	if(CPF_ENABLE_STATIC_ANALYSIS_TARGET)
		list(APPEND SOLUTION_FILES 
			"${CMAKE_BINARY_DIR}/${CPF_GRAPHVIZ_OPTIONS_FILE}" # CMake looks for the file in the source directory, so it can not be put in the cmake directory.
		)
	endif()

	add_custom_target( globalFiles SOURCES ${SOLUTION_FILES})


	# documentation
	cpfAddGlobalMonolithicDocumentationTarget( "${packages}" "${externalPackages}")
	# staticAnalysis
	cpfAddGlobalStaticAnalysisTarget("${packages}")
	# runUnitTests
	cpfAddGlobalRunUnitTestsTarget("${packages}")
	# runAllTests
	cpfAddGlobalRunAllTestsTarget("${packages}")
	# dynamicAnalysis
	cpfAddGlobalDynamicAnalysisTarget("${packages}")
	# distributionPackages
	cpfAddGlobalCreatePackagesTarget("${packages}")
	# abiComplianceCheck
	cpfAddGlobalAbiCheckerTarget("${packages}")
	# pipeline
	cpfAddPipelineTarget("${packages}")


endfunction()



