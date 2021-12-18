# This file contains the functionality for adding a cpf package-component to a project.

include(GenerateExportHeader) # this must be put before the include_guard() or it wont work

include_guard(GLOBAL)

include(cpfPackageProject)
include(cpfLocations)
include(cpfConstants)
include(cpfConfigUtilities)
include(cpfTargetUtilities)
include(cpfPackageUtilities)
include(cpfGitUtilities)
include(cpfPathUtilities)
include(cpfAssertions)

include(cpfAddClangTidyTarget)
include(cpfAddRunTestsTarget)
include(cpfAddDeploySharedLibrariesTarget)
include(cpfAddInstallTarget)
include(cpfAddPackageArchiveTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDoxygenPackageComponent)
include(cpfAddVersionRcTarget)


# cotire must be included on the global scope or we get errors that target xyz already has a custom rule
set(cotirePath "${CMAKE_CURRENT_LIST_DIR}/../../cotire/CMake/cotire.cmake")
if(CPF_ENABLE_PRECOMPILED_HEADER AND NOT CMAKE_SCRIPT_MODE_FILE) # do not enter this when included from scripts or pchs are disabled.
	if(EXISTS ${cotirePath})
		include(${cotirePath})
		set( CPF_COTIRE_AVAILABLE TRUE )
	else()
		message(WARNING "Cotire not found! Add it as package to \"Sources/cotire\" to enable precompiled headers.")
		set( CPF_COTIRE_AVAILABLE FALSE )
	endif()
endif()


#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function( cpfAddCppPackageComponent )

	cpfPrintAddPackageComponentStatusMessage("C++")

	set( optionKeywords
	) 
	
	set( requiredSingleValueKeywords
		TYPE
	)

	set( optionalSingleValueKeywords
		ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS
		ENABLE_ABI_API_STABILITY_CHECK_TARGETS
		ENABLE_CLANG_FORMAT_TARGETS
		ENABLE_CLANG_TIDY_TARGET
		ENABLE_OPENCPPCOVERAGE_TARGET
		ENABLE_PACKAGE_DOX_FILE_GENERATION
		ENABLE_PRECOMPILED_HEADER
		ENABLE_RUN_TESTS_TARGET
		ENABLE_VALGRIND_TARGET
		ENABLE_VERSION_RC_FILE_GENERATION
		HAS_GOOGLE_TEST_EXE
		CPP_NAMESPACE
		BRIEF_DESCRIPTION
		LONG_DESCRIPTION
	)

	set( requiredMultiValueKeywords
	)

	set( optionalMultiValueKeywords
		PRODUCTION_FILES
		PUBLIC_HEADER
		EXE_FILES
		PUBLIC_FIXTURE_HEADER
		FIXTURE_FILES
		TEST_FILES
		LINKED_LIBRARIES
		LINKED_TEST_LIBRARIES
		PLUGIN_DEPENDENCIES
		COMPILE_OPTIONS
		TEST_EXE_ARGUMENTS
	)

	# parse level 0 keywords
	cmake_parse_arguments(
		ARG 
		"${optionKeywords}" 
		"${requiredSingleValueKeywords};${optionalSingleValueKeywords}"
		"${requiredMultiValueKeywords};${optionalMultiValueKeywords}"
		${ARGN} 
	)

	if(DEFINED ARG_PACKAGE_NAMESPACE)
		message(FATAL_ERROR "Error! ${CMAKE_CURRENT_FUNCTION}() no longer accepts the PACKAGE_NAMESPACE option. Use variable CPF_<package-component>_TARGET_NAMESPACE instead.")
	endif()

	cpfAssertKeywordArgumentsHaveValue( "${requiredSingleValueKeywords};${requiredMultiValueKeywords}" ARG "${CMAKE_CURRENT_FUNCTION}()")
	
	cpfAssertProjectVersionDefined()

	cpfGetLastNodeOfCurrentSourceDir(packageComponent)

	# Get values of cpf per-package global variables.
	# Extra targets
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_PACKAGE_DOX_FILE_GENERATION ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_PACKAGE_DOX_FILE_GENERATION False)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_RUN_TESTS_TARGET ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_RUN_TESTS_TARGET True)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS False)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_ABI_API_STABILITY_CHECK_TARGETS ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_ENABLE_ABI_API_STABILITY_CHECK_TARGETS False)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_CLANG_FORMAT_TARGETS ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_ENABLE_CLANG_FORMAT_TARGETS False)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_CLANG_TIDY_TARGET ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_ENABLE_CLANG_TIDY_TARGET False)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_OPENCPPCOVERAGE_TARGET ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_ENABLE_OPENCPPCOVERAGE_TARGET False)
	cpfGetOptionalPackageComponentOption( ARG_ENABLE_VALGRIND_TARGET ${CPF_CURRENT_PACKAGE} ${packageComponent} ENABLE_ENABLE_VALGRIND_TARGET False)
	cpfGetOptionalPackageComponentOption( ARG_COMPILE_OPTIONS ${CPF_CURRENT_PACKAGE} ${packageComponent} COMPILE_OPTIONS "")
	# Get values of cmake per-package global variables.
	cpfSetPerComponentGlobalCMakeVariables(${CPF_CURRENT_PACKAGE} ${packageComponent})


	# Get package options
	set(targetNamespace ${CPF_CURRENT_PACKAGE}_TARGET_NAMESPACE)

	# parse argument sublists
	set( allKeywords ${optionKeywords} ${requiredSingleValueKeywords} ${optionalSingleValueKeywords} ${requiredMultiValueKeywords} ${optionalMultiValueKeywords})
	cpfGetKeywordValueLists( pluginOptionLists PLUGIN_DEPENDENCIES "${allKeywords}" "${ARGN}" pluginOptions)
	set(distributionPackageOptionLists ${${package}_DISTRIBUTION_PACKAGE_OPTION_LISTS})

	# By default build test targets.
	# Hunter sets this to off in order to skip test building.
	if( NOT "${${packageComponent}_BUILD_TESTS}" STREQUAL OFF )
		set( ${packageComponent}_BUILD_TESTS ON)
	endif()

	# ASSERT ARGUMENTS

	# Print debug output if linked targets do not exist.
	cpfDebugAssertLinkedLibrariesExists( linkedLibraries ${packageComponent} "${ARG_LINKED_LIBRARIES}")
	cpfDebugAssertLinkedLibrariesExists( linkedTestLibraries ${packageComponent} "${ARG_LINKED_TEST_LIBRARIES}")

	# Replace alias targets with the original names, because they can cause trouble with custom targets.
	cpfStripTargetAliases(linkedLibraries "${linkedLibraries}")
	cpfStripTargetAliases(linkedTestLibraries "${linkedTestLibraries}")

	# If a library does not have a public header, it must be a user mistake
	if( (${ARG_TYPE} STREQUAL LIB) AND (NOT ARG_PUBLIC_HEADER) )
		message(FATAL_ERROR "Library component ${packageComponent} has no public headers. The library can not be used without public headers, so please add the PUBLIC_HEADER argument to the cpfAddCppPackageComponent() call.")
	endif()

	if("${ARG_CPP_NAMESPACE}" STREQUAL "")
		set(ARG_CPP_NAMESPACE ${${package}_TARGET_NAMESPACE})
	endif()

	# make sure that the properties of the imported targets follow our assumptions
	cpfNormalizeImportedTargetProperties( "${linkedLibraries};${linkedTestLibraries}" )

	# Configure the c++ header file with the version.
	cpfConfigurePackageVersionHeader(${packageComponent} ${PROJECT_VERSION} ${ARG_CPP_NAMESPACE})

	cpfAddPackageSources(ARG_PRODUCTION_FILES ${CPF_CURRENT_PACKAGE})

	# Add the binary targets
	cpfAddPackageBinaryTargets( 
		productionLibrary
		${packageComponent} 
		"${ARG_BRIEF_DESCRIPTION}"
		"${ARG_OWNER}"
		${targetNamespace} 
		${ARG_TYPE} 
		"${ARG_PUBLIC_HEADER}" 
		"${ARG_PRODUCTION_FILES}"
		"${ARG_EXE_FILES}"
		"${ARG_PUBLIC_FIXTURE_HEADER}" 
		"${ARG_FIXTURE_FILES}" 
		"${ARG_TEST_FILES}" 
		"${linkedLibraries}" 
		"${linkedTestLibraries}"
		${${package}_VERSION_COMPATIBILITY_SCHEME}
		${ARG_ENABLE_CLANG_FORMAT_TARGETS}
		${ARG_ENABLE_PRECOMPILED_HEADER}
		${ARG_ENABLE_VERSION_RC_FILE_GENERATION}
		"${ARG_COMPILE_OPTIONS}"
		"${ARG_HAS_GOOGLE_TEST_EXE}"
	)

	# set some package-component properties
	set_property(TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BRIEF_PACKAGE_COMPONENT_DESCRIPTION ${ARG_BRIEF_DESCRIPTION} )
	set_property(TARGET ${packageComponent} PROPERTY INTERFACE_CPF_LONG_PACKAGE_COMPONENT_DESCRIPTION ${ARG_LONG_DESCRIPTION} )
	
	# Generate the "<package-component>DependencyNames.h" header file.
	if(CPF_ENABLE_DEPENDENCY_NAMES_HEADER_GENERATION)
		cpfGenerateDependencyNamesHeader(${packageComponent})
	endif()
	
	# add other custom targets

	# add a target the will be build before the binary target and that will copy all 
	# depended on shared libraries to the targets output directory.
	cpfAddDeploySharedLibrariesTarget(${packageComponent})

	# Adds target that runs clang-tidy on the given files.
    # Currently this is only added for the production target because clang-tidy does not filter out warnings that come over the GTest macros from external code.
    # When clang-tidy resolves the problem, static analysis should be executed for all binary targets.
	if(${ARG_ENABLE_CLANG_TIDY_TARGET})
		cpfAddClangTidyTarget(${productionLibrary})
	endif()
	
	if(${ARG_ENABLE_RUN_TESTS_TARGET})
		cpfAddRunCppTestsTargets(${packageComponent} "${ARG_TEST_EXE_ARGUMENTS}")
	endif()

	if(${ARG_ENABLE_VALGRIND_TARGET})
		cpfAddValgrindTarget(${packageComponent})
	endif()

	if(${ARG_ENABLE_OPENCPPCOVERAGE_TARGET})
		cpfAddOpenCppCoverageTarget(${packageComponent})
	endif()

	# A target to generate a .dox file that is used to add links to the package-components build results to the package-component documentation.
	if(${ARG_ENABLE_PACKAGE_DOX_FILE_GENERATION})
		cpfAddPackageDocsTarget( ${packageComponent} ${ARG_CPP_NAMESPACE} )
	endif()

	# Plugins must be added before the install targets
	cpfAddPlugins( ${packageComponent} "${pluginOptionLists}" )
	 
	# Adds a target the creates abi-dumps when using clang or gcc with debug options.
	cpfAddAbiCheckerTargets( 
		${packageComponent}
		"${distributionPackageOptionLists}"
		${ARG_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS}
		${ARG_ENABLE_ABI_API_STABILITY_CHECK_TARGETS}
	)
	
	# Adds the install rules and the per package-component install targets.
	cpfAddInstallRulesForCppPackageComponent(${CPF_CURRENT_PACKAGE} ${packageComponent} "${pluginOptionLists}" "${distributionPackageOptionLists}" ${${CPF_CURRENT_PACKAGE}_VERSION_COMPATIBILITY_SCHEME} )

endfunction() 

#---------------------------------------------------------------------
#
function( cpfAddPackageBinaryTargets 
	outProductionLibrary
	packageComponent
	shortDescription
	owner
	targetNamespace 
	type 
	publicHeaderFiles 
	productionFiles 
	exeFiles
	publicFixtureHeaderFiles 
	fixtureFiles 
	testFiles 
	linkedLibraries 
	linkedTestLibraries
	versionCompatibilityScheme
	enableClangFormatTargets
	enablePrecompiledHeader
	enableVersionRcGeneration
	compileOptions
	isGoogleTestExe
)

	# filter some files
	foreach( file ${productionFiles})
		
		# main.cpp
		if( "${file}" MATCHES "^main.cpp$" OR "${file}" MATCHES "(.*)/main.cpp$")
			set(MAIN_CPP ${file})
		endif()

	endforeach()

	# add version header and cmake files to the production files
	list(APPEND productionFiles ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt )
	cpfGetPackageComponentVersionCppHeaderFileName( versionHeader ${packageComponent} )
	list(APPEND publicHeaderFiles ${CMAKE_CURRENT_BINARY_DIR}/${versionHeader} )
	cpfGetComponentVSFolder(packageFolder ${CPF_CURRENT_PACKAGE} ${packageComponent})

	# Modify variables if the package-component creates an executable
	if("${type}" STREQUAL GUI_APP OR "${type}" STREQUAL CONSOLE_APP)
		set(isExe TRUE)
		set(libraryTarget lib${packageComponent})
		set(exeTarget ${packageComponent})
	else()
		set(isExe FALSE)
		set(libraryTarget ${packageComponent})
	endif()

	if(isExe)

		#remove main.cpp from the files
		cpfAssertDefinedMessage(MAIN_CPP "A package-component of executable type must contain a main.cpp file.")
		list(REMOVE_ITEM productionFiles ${MAIN_CPP})

		###################### Create Exe as package-component main target ##############################
		# The main target must be created first because cpfAddBinaryTarget() needs to set the
		# main target properties when adding helper targets.
		cpfAddBinaryTarget(
			PACKAGE_COMPONENT ${packageComponent}
			TARGET_NAMESPACE ${targetNamespace}
			TARGET_TYPE ${type}
			NAME ${exeTarget}
			FILES ${MAIN_CPP} ${exeFiles}
			#LINKED_LIBRARIES ${linkedLibraries}
			IDE_FOLDER ${packageFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION ${shortDescription}
			OWNER ${${CPF_CURRENT_PACKAGE}_OWNER}
			COMPILE_OPTIONS ${compileOptions}
	    )

		###################### Create implementation library target ##############################
		# This is created to allow linking the implementation of the exe to a test executable.
		if(productionFiles OR publicHeaderFiles)  

			cpfAddBinaryTarget(
				PACKAGE_COMPONENT ${packageComponent}  
				TARGET_NAMESPACE ${targetNamespace}
				TARGET_TYPE LIB
				NAME ${libraryTarget}
				PUBLIC_HEADER ${publicHeaderFiles}
				FILES ${productionFiles}
				LINKED_LIBRARIES ${linkedLibraries}
				IDE_FOLDER ${packageFolder}
				VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
				ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
				ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
				ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
				BRIEF_DESCRIPTION "Contains the functionality of the ${packageComponent} application."
				OWNER ${${CPF_CURRENT_PACKAGE}_OWNER}
				COMPILE_OPTIONS ${compileOptions}
			)

			# todo link with prod lib
			target_link_libraries(${packageComponent} PRIVATE ${libraryTarget})

		endif()

	else()

		if(exeFiles)
			message(FATAL_ERROR "Error! The option EXE_FILES in cpfAddCppPackageComponent() is only relevant for package-components of type GUI_APP or CONSOLE_APP.")
		endif()

		###################### Create a library target as package-component main target ##############################
		# This is created to allow linking the implementation of the exe to a test executable.
		if(productionFiles OR publicHeaderFiles)  

			cpfAddBinaryTarget(
				PACKAGE_COMPONENT ${packageComponent}  
				TARGET_NAMESPACE ${targetNamespace}
				TARGET_TYPE ${type}
				NAME ${packageComponent} 
				PUBLIC_HEADER ${publicHeaderFiles}
				FILES ${productionFiles}
				LINKED_LIBRARIES ${linkedLibraries}
				IDE_FOLDER ${packageFolder}
				VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
				ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
				ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
				ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
				BRIEF_DESCRIPTION ${shortDescription}
				OWNER ${${CPF_CURRENT_PACKAGE}_OWNER}
				COMPILE_OPTIONS ${compileOptions}
			)

		endif()

	endif()
	
	########################## Test Targets ###############################
	set( VSTestFolder test)		# the name of the test targets folder in the visual studio solution

    ################### Create fixture library ##############################	
	if( fixtureFiles OR publicFixtureHeaderFiles )
        set( fixtureTarget ${libraryTarget}${CPF_FIXTURE_TARGET_ENDING})
	    cpfAddBinaryTarget(
			PACKAGE_COMPONENT ${packageComponent}
			TARGET_NAMESPACE ${targetNamespace}
			TARGET_TYPE LIB
			NAME ${fixtureTarget}
			PUBLIC_HEADER ${publicFixtureHeaderFiles}
			FILES ${fixtureFiles}
			LINKED_LIBRARIES PUBLIC ${libraryTarget} ${linkedTestLibraries}
			IDE_FOLDER ${packageFolder}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION "A library that contains utilities for tests of the ${libraryTarget} library."
			OWNER ${${CPF_CURRENT_PACKAGE}_OWNER}
			COMPILE_OPTIONS ${compileOptions}
        )

		# respect an option that is used by hunter to not compile test targets
		if(${packageComponent}_BUILD_TESTS STREQUAL OFF )
			set_property(TARGET ${fixtureTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()
		set_property(TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET ${fixtureTarget} )
        
    endif()

    ################### Create unit test exe ##############################
	if( testFiles )
        set( unitTestsTarget ${libraryTarget}${CPF_TESTS_TARGET_ENDING})
        cpfAddBinaryTarget(
			PACKAGE_COMPONENT ${packageComponent}
			TARGET_NAMESPACE ${targetNamespace}
			TARGET_TYPE CONSOLE_APP
			NAME ${unitTestsTarget}
			FILES ${testFiles}
			LINKED_LIBRARIES PRIVATE ${libraryTarget} ${fixtureTarget} ${linkedTestLibraries}
			IDE_FOLDER ${packageFolder}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION "Runs tests of the ${libraryTarget} library."
			OWNER ${${CPF_CURRENT_PACKAGE}_OWNER}
			COMPILE_OPTIONS ${compileOptions}
        )
		set_property(TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET ${unitTestsTarget} )

		# respect an option that is used by hunter to not compile test targets
		if(${packageComponent}_BUILD_TESTS STREQUAL OFF)
			set_property(TARGET ${unitTestsTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()

		if(isGoogleTestExe)
			cpfGenerateGoogleTestAdapterHelperFiles(${unitTestsTarget})
		endif()

    endif()
    
	# Set some properties
	set(binaryTargets ${libraryTarget} ${exeTarget} ${fixtureTarget} ${unitTestsTarget})
    set_property(TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS ${binaryTargets})
	set_property(TARGET ${packageComponent} APPEND PROPERTY INTERFACE_CPF_PACKAGE_COMPONENT_SUBTARGETS ${binaryTargets})
    set_property(TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET ${libraryTarget})
	set( ${outProductionLibrary} ${libraryTarget} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
function( cpfGenerateGoogleTestAdapterHelperFiles testExeTarget )
		# Generating a file .is_google_test makes sure the  GoogleTestAdapter can find the tests.
		cpfIsVisualStudioGenerator(useVS)
		if(useVS)
			cpfGetConfigurations(configs)
			foreach(config ${configs})
				cpfGetTargetOutputDirectory( exeDir ${testExeTarget} ${config} )
				file(MAKE_DIRECTORY ${exeDir})
				cpfGetAbsPathOfTargetOutputFile( exeFilename ${testExeTarget} ${config})
				file(TOUCH ${exeFilename}.is_google_test)
			endforeach()
		endif()
endfunction()

#---------------------------------------------------------------------
# Adds a binary target 
#
function( cpfAddBinaryTarget )

	cmake_parse_arguments(
		ARG 
		"" 
		"PACKAGE_COMPONENT;NAME;TARGET_NAMESPACE;TARGET_TYPE;IDE_FOLDER;VERSION_COMPATIBILITY_SCHEME;ENABLE_CLANG_FORMAT_TARGETS;ENABLE_PRECOMPILED_HEADER;ENABLE_VERSION_RC_FILE_GENERATION;BRIEF_DESCRIPTION;OWNER" 
		"PUBLIC_HEADER;FILES;LINKED_LIBRARIES;COMPILE_OPTIONS" 
		${ARGN} 
	)
	set( allSources ${ARG_PUBLIC_HEADER} ${ARG_FILES})


	set(isInterfaceLib FALSE)
	if(${ARG_TARGET_TYPE} MATCHES INTERFACE_LIB)
		set(isInterfaceLib TRUE)
	endif()

    # Create Window application
    if( ${ARG_TARGET_TYPE} STREQUAL GUI_APP)
        add_executable(${ARG_NAME} WIN32 ${allSources} )
    endif()

    # Create console application
    if( ${ARG_TARGET_TYPE} MATCHES CONSOLE_APP)
        add_executable(${ARG_NAME} ${allSources} )
    endif()

    # library
    if( ${ARG_TARGET_TYPE} MATCHES LIB OR isInterfaceLib )
		
		if(isInterfaceLib)

			add_library(${ARG_NAME} INTERFACE )

			# We also add a custom target to hold the files so we can see them in Visual Studio
			set(fileContainerTarget ${ARG_NAME}_files )
			add_custom_target(
				${fileContainerTarget}
				SOURCES ${allSources}
			)
			set_property( TARGET ${fileContainerTarget} PROPERTY FOLDER ${ARG_IDE_FOLDER})

			set_property(TARGET ${ARG_NAME} PROPERTY INTERFACE_CPF_FILE_CONTAINER_SUBTARGET ${fileContainerTarget})

			# Set the version to a special property
			set_property( TARGET ${ARG_NAME} PROPERTY INTERFACE_CPF_VERSION ${PROJECT_VERSION} )

		else()

			add_library(${ARG_NAME} ${allSources} )
			# Remove the lib prefix on Linux. We expect that to be part of the package-component name.
			set_property(TARGET ${ARG_NAME} PROPERTY PREFIX "")

		endif()

		# make sure that clients have the /D <target>_IMPORTS compile option set.
		if( ${BUILD_SHARED_LIBS} AND MSVC)
			target_compile_definitions(${ARG_NAME} INTERFACE ${ARG_NAME}_IMPORTS )
		endif()
		
    endif()

	# Set the package-component name to the target. With this we can check if an imported target is from a CPF package-component.
	set_property(TARGET ${ARG_NAME} PROPERTY INTERFACE_CPF_PACKAGE_COMPONENT_NAME ${ARG_PACKAGE_COMPONENT})

    # Link with other libraries
	# This must be done before setting up the precompiled headers.
	target_link_libraries(${ARG_NAME} PUBLIC ${ARG_LINKED_LIBRARIES})

    # Set target properties
	# Set include directories, that all header are included with #include <package-component/myheader.h>
	# We do not use special directories for private or public headers. So the include directory is public.
	file(RELATIVE_PATH relativeComponentDirectory ${CMAKE_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
	cpfGetParentDirectory(parentOfComponentDirectory ${relativeComponentDirectory})
	if(NOT ("${parentOfComponentDirectory}" STREQUAL ""))
		string(PREPEND parentOfComponentDirectory /)
	endif()
	if(isInterfaceLib)

		# only use the interface compile options for interface targets
		cmake_parse_arguments(
			ARG 
			"" 
			"" 
			"INTERFACE" 
			${ARG_COMPILE_OPTIONS} 
		)
		cpfContains(hasBefore "${ARG_COMPILE_OPTIONS}" BEFORE)
		set(beforeOption)
		if(hasBefore)
			set(beforeOption BEFORE)
		endif()
		if(ARG_INTERFACE)
			target_compile_options(${ARG_NAME} ${beforeOption} INTERFACE ${ARG_INTERFACE})
		endif()

		# set include directories
		set_property(TARGET ${ARG_NAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES  
			$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>${parentOfComponentDirectory}
			$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>${parentOfComponentDirectory}
		)

	else()

		if(ARG_COMPILE_OPTIONS)
			target_compile_options(${ARG_NAME} ${ARG_COMPILE_OPTIONS})
		endif()

		# set include directories
		target_include_directories( ${ARG_NAME} PUBLIC 
			$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>${parentOfComponentDirectory}
			$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>${parentOfComponentDirectory}
		)

		# set the Visual Studio folder property
		set_property( TARGET ${ARG_NAME} PROPERTY FOLDER ${ARG_IDE_FOLDER})

		# Set the target version
		set_property( TARGET ${ARG_NAME} PROPERTY VERSION ${PROJECT_VERSION} )
		if("${${CPF_CURRENT_PACKAGE}_VERSION_COMPATIBILITY_SCHEME}" STREQUAL ExactVersion)
			set_property( TARGET ${ARG_NAME} PROPERTY SOVERSION ${PROJECT_VERSION} )
		else()
			message(FATAL_ERROR "Unexpected compatibility scheme!")
		endif()

		# Generate the header file with the dll export and import macros
		cpfGenerateExportMacroHeader(${ARG_NAME} "${ARG_NAME}")

		# set target to use pre-compiled header
		# compile flags can not be changed after this call
		if(${ARG_ENABLE_PRECOMPILED_HEADER})
			cpfAddPrecompiledHeader(${ARG_NAME})
		endif()

	endif()

	# public header
	set_property( TARGET ${ARG_NAME} APPEND PROPERTY INTERFACE_CPF_PUBLIC_HEADER ${ARG_PUBLIC_HEADER})

	# sets all the <bla>_OUTPUT_DIRECTORY_<config> options
	cpfSetTargetOutputDirectoriesAndNames(${ARG_PACKAGE_COMPONENT} ${ARG_NAME})

	# Add an alias target to allow using namespaced names for inlined packages.
	cpfAddAliasTarget(${ARG_NAME} ${ARG_TARGET_NAMESPACE})

	# Adds a clang-format target
	if(ARG_ENABLE_CLANG_FORMAT_TARGETS)
		cpfAddClangFormatTarget(${ARG_PACKAGE_COMPONENT} ${ARG_NAME})
	endif()

	# Setup automatic creation of a version.rc file on windows
	if((NOT ARG_DISABLE_VERSION_RC_GENERATION) AND (NOT isInterfaceLib))
		cpfAddVersionRcTarget(
			PACKAGE_COMPONENT ${ARG_PACKAGE_COMPONENT}
			BINARY_TARGET ${ARG_NAME}
			VERSION ${PROJECT_VERSION}
			BRIEF_DESCRIPTION ${ARG_BRIEF_DESCRIPTION}
			OWNER ${ARG_OWNER}
		)
	endif()

	# sort files into folders in visual studio
	cpfSetIDEDirectoriesForTargetSources(${ARG_NAME})

endfunction()


#----------------------------------------- macro from Lars Christensen to use precompiled headers --------------------------------
#
function(cpfAddPrecompiledHeader target )
	if(${CPF_COTIRE_AVAILABLE}) 
		
		# add the precompiled header (targets and compile flags)
		set_target_properties(${target} PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)  # prevent the generation of unity build targets
	
		cotire(${target})
		cpfReAddInheritedCompileOptions( ${target})

		# Add the prefix header to the target files to make sure it appears in the visual studio solution.
		get_property(prefixHeader TARGET ${target} PROPERTY COTIRE_CXX_PREFIX_HEADER)
		set_property(TARGET ${target} APPEND PROPERTY SOURCES ${prefixHeader})

		# do not run moc for the generated prefix header, it will cause build errors.
		set_property(SOURCE ${prefixHeader} PROPERTY SKIP_AUTOMOC ON)

	endif()
endfunction()

#---------------------------------------------------------------------------------------------
# This function compensates a CMake bug (https://gitlab.kitware.com/cmake/cmake/issues/17488)
# Cotire sets the SOURCE propety COMPILE_FLAGS which removes inherited INTERFACE_COMPILE_OPTIONS due
# to the bug. We manually re-add the compile options here.
function( cpfReAddInheritedCompileOptions target )

	# The problem only occurs for the visual studio generator.
	cpfIsVisualStudioGenerator(isVS)
	if(NOT isVS)
		return()
	endif()

	# get all inherited compile options
	set(inheritedCompileOptions)
	cpfGetVisibleLinkedLibraries( linkedLibs ${target} )
	foreach( lib ${linkedLibs} )
		get_property( compileOptions TARGET ${lib} PROPERTY INTERFACE_COMPILE_OPTIONS )
		list(APPEND inheritedCompileOptions ${compileOptions})
	endforeach()

	if(inheritedCompileOptions)
		list(REMOVE_DUPLICATES inheritedCompileOptions )
		cpfJoinString( inheritedOptionsString "${inheritedCompileOptions}" " ")

		# add them to the SOURCE property COMPILE_FLAGS
		# adding them with target_compile_options will not work.
		get_property(sourceFiles TARGET ${target} PROPERTY SOURCES)
		foreach( file ${sourceFiles})
			get_filename_component( extension ${file} EXT)
			if( "${extension}" STREQUAL .cpp ) # we only handle the .cpp extension which is fragile, but hopes are that this code will be removed when the cmake bug is fixed.
				get_property( flags SOURCE ${file} PROPERTY COMPILE_FLAGS)
				set_property( SOURCE ${file} PROPERTY COMPILE_FLAGS "${inheritedOptionsString} ${flags}") # inherited options must come before the prefix header include option
			endif()
		endforeach()
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
# Calls the qt5_wrap_ui and qt5_add_resources and adds the generated files to the given file list
#
function( cpfQt5AddUIAndQrcFiles filesOut )

	set(files ${${filesOut}})

	# handle ui files manually
	# There were problems with the AUTOUIC option because
	# when using it, the names of the generated files are
	# not available here to add them to the include directories.
	foreach( file ${files})
		get_filename_component( extension ${file} EXT)
		if("${extension}" STREQUAL ".ui")
			list(APPEND uiFiles ${file})
		elseif("${extension}" STREQUAL ".qrc")
			list(APPEND rcFiles ${file})
		endif()
	endforeach() 

	if(uiFiles)
		qt5_wrap_ui(uiHeaders ${uiFiles})
		list(APPEND ARG_FILES ${uiHeaders})
	endif()

	if(rcFiles)
		qt5_add_resources(qrcFiles ${rcFiles})
	endif()

	set( ${filesOut} ${files} ${uiHeaders} ${qrcFiles} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
# generate a header file that contains the EXPORT macros
function( cpfGenerateExportMacroHeader target macroBaseName )

	cpfIsExecutable(isExe ${target})
	if(NOT isExe)

		string(TOLOWER ${macroBaseName} macroBaseNameLower ) # the generate_export_header() function will create a file with lower case name.
		generate_export_header( 
			${target}
			BASE_NAME ${macroBaseNameLower}
		)
		set(exportHeader "${CMAKE_CURRENT_BINARY_DIR}/${macroBaseNameLower}_export.h" )
		set_property(TARGET ${target} APPEND PROPERTY SOURCES ${exportHeader} )
		set_property(TARGET ${target} APPEND PROPERTY INTERFACE_CPF_PUBLIC_HEADER ${exportHeader} )

		source_group(Generated FILES ${exportHeader})

	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# Call this function to make sure explicitly loaded shared libraries are deployed besides the package-components executables in the build and install stage.
# The package-component has no knowledge about plugins, so they must be explicitly deployed with this function.
#
# pluginDependencies A list where the first element is the relative path of the plugin and the folling elements are the plugin targets.
# 
function( cpfAddPlugins packageComponent pluginOptionLists )

	cpfGetExecutableTargets( exeTargets ${packageComponent})
	if(NOT exeTargets)
		return()
	endif()

	cpfGetPluginTargetDirectoryPairLists( pluginTargets pluginDirectories "${pluginOptionLists}" )
	cpfStripTargetAliases(pluginTargets "${pluginTargets}")

	# add deploy and install targets for the plugins
	set(index 0)
	foreach(plugin ${pluginTargets})
		list(GET pluginDirectories ${index} subdirectory)
		cpfIncrement(index)
		if(TARGET ${plugin})
			add_dependencies( ${packageComponent} ${plugin}) # adds the artifical dependency
			cpfAddDeploySharedLibsToBuildStageTarget( ${packageComponent} ${plugin} ${subdirectory} ) 
		endif()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddAliasTarget target packageNamespace )

	cpfIsExecutable(isExe ${target})
	if(isExe)
		add_executable(${packageNamespace}::${target} ALIAS ${target})
	else()
		add_library(${packageNamespace}::${target} ALIAS ${target})
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# Goes through the given targets and in case that a target is an alias target replaces them
# with the name of the original target.
function( cpfStripTargetAliases deAliasedTargetsOut targets)
	
	set(deAliasedTargets)
	foreach(target ${targets})

		cpfIsLinkVisibilityKeyword(isKeyword ${target})
		if(isKeyword)
			cpfListAppend(deAliasedTargets ${target})
			continue()
		endif()

		get_property(aliasedTarget TARGET ${target} PROPERTY ALIASED_TARGET)
		if(aliasedTarget)
			cpfListAppend(deAliasedTargets ${aliasedTarget})
		else()
			cpfListAppend(deAliasedTargets ${target})
		endif()
	endforeach()
	set(${deAliasedTargetsOut} "${deAliasedTargets}" PARENT_SCOPE)

endfunction()


#---------------------------------------------------------------------------------------------
# Adds install rules for the various package-component components.
#
function( cpfAddInstallRulesForCppPackageComponent package packageComponent pluginOptionLists distributionPackageOptionLists versionCompatibilityScheme )

	cpfAddInstallRulesForPackageBinaries(${package} ${packageComponent} ${versionCompatibilityScheme} )
	cpfAddInstallRulesForPublicHeaders( ${packageComponent} )
	cpfAddInstallRulesForPDBFiles( ${packageComponent} )
	cpfAddInstallRulesForDependedOnSharedLibraries( ${packageComponent} "${pluginOptionLists}" "${distributionPackageOptionLists}" )
	cpfAddInstallRulesForSources( ${packageComponent} )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRulesForPackageBinaries package packageComponent versionCompatibilityScheme )
	
	cpfGetProductionTargets( productionTargets ${packageComponent} )
	cpfAddInstallRulesForBinaryTargets(${package} ${packageComponent} "${productionTargets}" "" ${versionCompatibilityScheme} )

	cpfGetTestTargets( testTargets ${packageComponent})
	if(testTargets)
		cpfAddInstallRulesForBinaryTargets(${package} ${packageComponent} "${testTargets}" developer ${versionCompatibilityScheme} )
	endif()
    
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRulesForBinaryTargets package packageComponent targets component versionCompatibilityScheme )

	# Do not install the targets that have been removed from the ALL_BUILD target
	cpfFilterInTargetsWithProperty( interfaceLibs "${targets}" TYPE INTERFACE_LIBRARY )
	cpfFilterOutTargetsWithProperty( noneInterfaceLibTargets "${targets}" TYPE INTERFACE_LIBRARY )
	cpfFilterOutTargetsWithProperty( noneInterfaceLibTargets "${noneInterfaceLibTargets}" EXCLUDE_FROM_ALL TRUE )
	set(targets ${interfaceLibs} ${noneInterfaceLibTargets})

	cpfGetRelativeOutputDir( relRuntimeDir ${packageComponent} RUNTIME )
	cpfGetRelativeOutputDir( relLibDir ${packageComponent} LIBRARY)
	cpfGetRelativeOutputDir( relArchiveDir ${packageComponent} ARCHIVE)
	cpfGetRelativeOutputDir( relIncludeDir ${packageComponent} INCLUDE)
		
	# Add an relative rpath to the executables that points to the lib directory.
	file(RELATIVE_PATH rpath "${CMAKE_CURRENT_BINARY_DIR}/${relRuntimeDir}" "${CMAKE_CURRENT_BINARY_DIR}/${relLibDir}")
	cpfAppendPackageExeRPaths( ${packageComponent} "\$ORIGIN/${rpath}")

	set(skipNameLinkOption)
	if( ${versionCompatibilityScheme} STREQUAL ExactVersion)
		set(skipNameLinkOption NAMELINK_SKIP)
	endif()

	foreach(target ${targets})

		set(additionalComponent)
		cpfIsDynamicLibrary(isDynLib ${target})
		if(NOT component)
			cpfIsExecutable(isExe ${target})
			if(isExe OR isDynLib)
				set(component runtime)
			else()
				set(component developer)
			endif()

			# MSVC will create additional static libs for dynamic libraries so we also have the developer
			# component in this case.
			if(MSVC AND isDynLib)
				set(additionalComponent developer)
			endif()

		endif()

		install( 
			TARGETS ${target}
			EXPORT ${package}
			RUNTIME 
				DESTINATION "${relRuntimeDir}"
				COMPONENT ${component}
			LIBRARY
				DESTINATION "${relLibDir}"
				COMPONENT ${component}
				${skipNameLinkOption}
			ARCHIVE
				DESTINATION "${relArchiveDir}"
				COMPONENT developer
			# This sets the import targets include directories to <package-component>/include, 
			# so clients can also include with <package-component/bla.h>
			INCLUDES
				DESTINATION "${relIncludeDir}/.."
		)

		set_property(TARGET ${target} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS ${component} ${additionalComponent} )

	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# This function adds install rules for the files that are required for debugging.
# This is currently the pdb and source files for msvc configurations.
#
function( cpfAddInstallRulesForPDBFiles packageComponent )

	get_property(targets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)

	cpfGetConfigurations( configs )
	foreach( config ${configs})

		cpfToConfigSuffix( suffix ${config})

		foreach(target ${targets})
	
			cpfIsInterfaceLibrary( isIntLib ${target})
			if(NOT isIntLib)

				# Install compiler generated pdb files
				get_property( compilePdbName TARGET ${target} PROPERTY COMPILE_PDB_NAME_${suffix} )
				get_property( compilePdbDir TARGET ${target} PROPERTY COMPILE_PDB_OUTPUT_DIRECTORY_${suffix} )
				cpfGetRelativeOutputDir( relPdbCompilerDir ${packageComponent} COMPILE_PDB )
				if(compilePdbName)
					install(
						FILES ${compilePdbDir}/${compilePdbName}.pdb
						DESTINATION "${relPdbCompilerDir}"
						COMPONENT developer
						CONFIGURATIONS ${config}
					)
				endif()

				# Install linker generated pdb files
				get_property( linkerPdbName TARGET ${target} PROPERTY PDB_NAME_${suffix} )
				get_property( linkerPdbDir TARGET ${target} PROPERTY PDB_OUTPUT_DIRECTORY_${suffix} )
				cpfGetRelativeOutputDir( relPdbLinkerDir ${packageComponent} PDB)
				if(linkerPdbName)
					install(
						FILES ${linkerPdbDir}/${linkerPdbName}.pdb
						DESTINATION "${relPdbLinkerDir}"
						COMPONENT developer
						CONFIGURATIONS ${config}
					)
				endif()
				
				# Install source files for configurations that require them for debugging.
				cpfCompilerProducesPdbFiles( needsSourcesForDebugging ${config})
				if(needsSourcesForDebugging)

					cpfGetTargetSourcesWithoutPrefixHeader( sources ${target} )
					cpfGetFilepathsWithExtensions( cppSources "${sources}" "${CPF_CXX_SOURCE_FILE_EXTENSIONS}" )
					cpfInstallSourceFiles( relFiles ${packageComponent} "${cppSources}" SOURCE developer ${config} )

					# Add the installed files to the target property
					cpfPrependMulti(relInstallPaths "${relSourceDir}/" "${shortSourceNames}" )

				endif()

			endif()

		endforeach()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRulesForPublicHeaders packageComponent)

	set(outputType INCLUDE)
	set(installComponent developer)

	# Install rules for production headers
	get_property( productionLib TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
	get_property( header TARGET ${productionLib} PROPERTY INTERFACE_CPF_PUBLIC_HEADER)
	cpfInstallSourceFiles( relBasicHeader ${packageComponent} "${header}" ${outputType} ${installComponent} "")
	
	# Install rules for test fixture library headers
	get_property( fixtureTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET)
	if(TARGET ${fixtureTarget})
		get_property( header TARGET ${fixtureTarget} PROPERTY INTERFACE_CPF_PUBLIC_HEADER)
		cpfInstallSourceFiles( relfixtureHeader ${packageComponent} "${header}" ${outputType} ${installComponent} "")
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallSourceFiles installedFilesOut packageComponent sources outputType installComponent config )

    # Create header pathes relative to the install include directory.
    set(sourceDir ${CMAKE_CURRENT_SOURCE_DIR})
	set( binaryDir ${CMAKE_CURRENT_BINARY_DIR})
	cpfGetRelativeOutputDir( relIncludeDir ${packageComponent} ${outputType})

	set(installedFiles)
	foreach( file ${sources})
		
		cpfToAbsSourcePath(absFile ${file} ${sourceDir})

		# When building, the include directories are the package-components binary and source directory.
		# This means we need the path of the header relative to one of the two in order to get the
		# relative path to the package archive-components install directory right.
		file(RELATIVE_PATH relPathSource ${sourceDir} ${absFile} )
		file(RELATIVE_PATH relPathBinary ${binaryDir} ${absFile} )
		cpfGetShorterString( relFilePath ${relPathSource} ${relPathBinary}) # assume the shorter path is the correct one

		# prepend the include/<package-component> directory
		get_filename_component( relDestDir ${relFilePath} DIRECTORY)
		if(relDestDir)
			set(relDestDir ${relIncludeDir}/${relDestDir} )
		else()
			set(relDestDir ${relIncludeDir} )
		endif()
		
		if(config)
			set(configOption CONFIGURATIONS ${config})
		endif()

		install(
			FILES ${absFile}
			DESTINATION "${relDestDir}"
			COMPONENT ${installComponent}
			${configOption}
		)

		# add the relative install path to the returned paths
		get_filename_component( header ${absFile} NAME)
		list( APPEND installedFiles ${relDestDir}/${header})
	endforeach()

	set( ${installedFilesOut} ${installedFiles} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGenerateAndInstallCMakeConfigFiles package namespace compatibilityScheme )

	# Generate the cmake config files
	set(packageConfigFile ${package}Config.cmake)
	set(versionConfigFile ${package}ConfigVersion.cmake )
	set(packageConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${packageConfigFile}")	# The config file is used by find package-component 
	set(versionConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${versionConfigFile}")
	cpfGetRelativeOutputDir( relCmakeFilesDir ${package} CMAKE_PACKAGE_FILES)

	configure_package_config_file(
		${CPF_PACKAGE_CONFIG_TEMPLATE}
		"${packageConfigFileFull}"
		INSTALL_DESTINATION ${relCmakeFilesDir}
	)
		
	write_basic_package_version_file( 
		"${versionConfigFileFull}" 
		COMPATIBILITY ${compatibilityScheme}
	) 

	# Install cmake exported targets config file
	# This can not be done in the configs loop, so we need a generator expression for the output directory
	install(
		EXPORT "${package}"
		NAMESPACE "${namespace}::"
		DESTINATION "${relCmakeFilesDir}"
		COMPONENT developer
	)

	# Install cmake config files
	install(
		FILES "${packageConfigFileFull}" "${versionConfigFileFull}"
		DESTINATION "${relCmakeFilesDir}"
		COMPONENT developer
	)

endfunction()

#----------------------------------------------------------------------------------------
# Parses the pluginOptionLists and returns two lists of same size. One list contains the
# plugin target while the element with the same index in the other list contains the 
# directory of the plugin target.
function( cpfGetPluginTargetDirectoryPairLists targetsOut directoriesOut pluginOptionLists )
	
	# parse the plugin dependencies arguments
	# Creates two lists of the same length, where one list contains the plugin targets
	# and the other the directory to which they are deployed.
	set(pluginTargets)
	set(pluginDirectories)
	foreach( list ${pluginOptionLists})
		cmake_parse_arguments(
			ARG 
			"" 
			"PLUGIN_DIRECTORY"
			"PLUGIN_TARGETS"
			${${list}}
		)

		# check for correct keywords
		if(NOT ARG_PLUGIN_TARGETS)
			message(FATAL_ERROR "Faulty plugin option \"${${list}}\"! The option is missing the PLUGIN_TARGETS key word or values for it.")
		endif()

		if(NOT ARG_PLUGIN_DIRECTORY)
			message(FATAL_ERROR "Faulty plugin option \"${${list}}\"! The option is missing the PLUGIN_DIRECTORY key word or a value for it.")
		endif()

		foreach( pluginTarget ${ARG_PLUGIN_TARGETS})
			if(TARGET ${pluginTarget})
				cpfListAppend( pluginTargets ${pluginTarget})
				cpfListAppend( pluginDirectories ${ARG_PLUGIN_DIRECTORY})
			else()
				cpfDebugMessage("Ignored missing plugin target ${pluginTarget}.")
			endif()
		endforeach()

	endforeach()

	set(${targetsOut} "${pluginTargets}" PARENT_SCOPE)
	set(${directoriesOut} "${pluginDirectories}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# This function adds install rules for the shared libraries that are provided by other
# internal or external packages. We only add these rules for package-components that actually
# create package archive-components that include depended on shared libraries.
#
function( cpfAddInstallRulesForDependedOnSharedLibraries packageComponent pluginOptions distributionPackageOptionLists )

	cpfGetDependedOnSharedLibrariesAndDirectories( libraries directories ${packageComponent} "${pluginOptions}" )

	# Add install rules for each package archive-component that has a runtime-portable content.
	set(contentIds)
	foreach( list ${distributionPackageOptionLists})

		cpfParseDistributionPackageOptions( contentType packageFormats distributionPackageFormatOptions excludedTargets "${${list}}")
		if( "${contentType}" STREQUAL CT_RUNTIME_PORTABLE )
			cpfGetDistributionPackageContentId( contentId ${contentType} "${excludedTargets}" )
			cpfContains(contentTypeHandled "${contentIds}" ${contentId})
			if(NOT ${contentTypeHandled})
				
				cpfListAppend(contentIds ${contentId})
				removeExcludedTargets( libraries directories "${libraries}" "${directories}" "${excludedTargets}" )
				addSharedLibraryDependenciesInstallRules( ${packageComponent} ${contentId} "${libraries}" "${directories}" )
			
			endif()
		endif()
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with shared library targets and one with a relative directory for each
# target to which the shared library must be copied.
#
function( cpfGetDependedOnSharedLibrariesAndDirectories librariesOut directoriesOut packageComponent pluginOptionLists )

	cpfGetRelativeOutputDir( relRuntimeDir ${packageComponent} RUNTIME)
	cpfGetRelativeOutputDir( relLibraryDir ${packageComponent} LIBRARY)

	# Get plugin targets and relative directories
	cpfGetPluginTargetDirectoryPairLists( pluginTargets pluginDirectories "${pluginOptionLists}" )
	cpfPrependMulti( pluginDirectories "${relRuntimeDir}/" "${pluginDirectories}" )
	
	# Get library targets and add them to directories
	cpfGetSharedLibrariesRequiredByPackageProductionLib( libraries ${packageComponent} )
	set( allLibraries ${pluginTargets} )
	set( allDirectories ${pluginDirectories} )
	foreach( library ${libraries} )
		cpfListAppend( allLibraries ${library} )
		cpfListAppend( allDirectories ${relLibraryDir} )
	endforeach()

	set(${librariesOut} "${allLibraries}" PARENT_SCOPE)
	set(${directoriesOut} "${allDirectories}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( removeExcludedTargets librariesOut directoriesOut libraries directories excludedTargets )

	set(index 0)
	set(filteredLibraries)
	set(filteredDirectories)
	foreach( library ${libraries} )
		cpfContains(isExcluded "${excludedTargets}" ${library})
		if(NOT isExcluded)
			cpfListAppend(filteredLibraries ${library})
			list(GET directories ${index} dir)
			cpfListAppend(filteredDirectories ${dir})
		endif()	
		cpfIncrement(index)
	endforeach()

	set(${librariesOut} ${filteredLibraries} PARENT_SCOPE)
	set(${directoriesOut} ${filteredDirectories} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function was introduced to only have one definition of the package archive option keywords
function( cpfParseDistributionPackageOptions contentTypeOut packageFormatsOut distributionPackageFormatOptionsOut excludedTargetsOut argumentList )

	cmake_parse_arguments(
		ARG 
		"" 
		"" 
		"PACKAGE_ARCHIVE_CONTENT_TYPE;PACKAGE_ARCHIVE_FORMATS;PACKAGE_ARCHIVE_FORMAT_OPTIONS"
		${argumentList}
	)

	set( contentTypeOptions 
		CT_DEVELOPER
		CT_RUNTIME
		CT_SOURCES
		CT_DOCUMENTATION
	)

	set(runtimePortableOption CT_RUNTIME_PORTABLE) 
	cmake_parse_arguments(
		ARG
		"${contentTypeOptions}"
		""
		"${runtimePortableOption}"
		"${ARG_PACKAGE_ARCHIVE_CONTENT_TYPE}"
	)
	
	# Check that only one content type was given.
	cpfContains(isRuntimeAndDependenciesType "${ARG_PACKAGE_ARCHIVE_CONTENT_TYPE}" ${runtimePortableOption})
	cpfPrependMulti( argOptions ARG_ "${contentTypeOptions}")
	set(nrOptions 0)
	foreach(option ${isRuntimeAndDependenciesType} ${argOptions})
		if(${option})
			cpfIncrement(nrOptions)
		endif()
	endforeach()
	
	if( NOT (${nrOptions} EQUAL 1) )
		message(FATAL_ERROR "Each PACKAGE_ARCHIVE_CONTENT_TYPE option in cpfAddCppPackageComponent() must contain exactly one of these options: ${contentTypeOptions};${runtimePortableOption}. The given option was ${ARG_PACKAGE_ARCHIVE_CONTENT_TYPE}" )
	endif()
	
	if(ARG_CT_DEVELOPER)
		set(contentType CT_DEVELOPER)
	elseif(ARG_CT_RUNTIME)
		set(contentType CT_RUNTIME)
	elseif(isRuntimeAndDependenciesType)
		set(contentType CT_RUNTIME_PORTABLE)
	elseif(ARG_CT_SOURCES)
		set(contentType CT_SOURCES)
	elseif(ARG_CT_DOCUMENTATION)
		set(contentType CT_DOCUMENTATION)
	else()
		message(FATAL_ERROR "Faulty PACKAGE_ARCHIVE_CONTENT_TYPE option in cpfAddCppPackageComponent().")
	endif()
	
	set(${contentTypeOut} ${contentType} PARENT_SCOPE)
	set(${packageFormatsOut} ${ARG_PACKAGE_ARCHIVE_FORMATS} PARENT_SCOPE)
	set(${distributionPackageFormatOptionsOut} ${ARG_PACKAGE_ARCHIVE_FORMAT_OPTIONS} PARENT_SCOPE)
	set(${excludedTargetsOut} ${ARG_CT_RUNTIME_PORTABLE} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetDistributionPackageContentId contentIdOut contentType excludedTargets )

	if( "${contentType}" STREQUAL CT_DEVELOPER)
		set(contentIdLocal dev)
	elseif( "${contentType}" STREQUAL CT_RUNTIME )
		set(contentIdLocal runtime )
	elseif( "${contentType}" STREQUAL CT_RUNTIME_PORTABLE )
		set(contentIdLocal runtime-port )
		if( NOT "${excludedTargets}" STREQUAL "")
			# When using excluded targets there are arbitrary numbers of possible
			# package contents. To distinguish between them and get a short content
			# id we calculate the MD5 checksum of the excluded targets list and add
			# it to the base runtime portable content id.
			list(SORT excludedTargets)
			string(MD5 excludedTargetsHash "${excludedTargets}")
			string(SUBSTRING ${excludedTargetsHash} 0 8 excludedTargetsHash) # Only use the first 8 characters to keep things short.
			string(APPEND contentIdLocal -${excludedTargetsHash})
		endif()
	elseif( "${contentType}" STREQUAL CT_SOURCES )
		set(contentIdLocal src )
	elseif( "${contentType}" STREQUAL CT_DOCUMENTATION )
		set(contentIdLocal doc )
	else()
		message(FATAL_ERROR "Content type \"${contentType}\" is not supported by function contentTypeOutputNameIdentifier().")
	endif()
	
	set(${contentIdOut} ${contentIdLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function parses the package archive options of the package and returns a list
# with the content-ids of all runtime-portable packages.
function( addSharedLibraryDependenciesInstallRules packageComponent contentId libraries directories )

	cpfGetConfigurations(configurations)
	foreach(config ${configurations})

		set(installedFiles)
		set(index 0)
		foreach(library ${libraries})

			cpfGetLibFilePath( libFile ${library} ${config})
			list(GET directories ${index} dir)

			install(
				FILES ${libFile}
				DESTINATION "${dir}"
				COMPONENT ${contentId}
				CONFIGURATIONS ${config}
			)

			cpfIncrement(index)

		endforeach()
	endforeach()

	set_property(TARGET ${packageComponent} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS ${contentId} )

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddInstallRulesForSources packageComponent )

	set(outputType INCLUDE)
	set(installComponent developer)

	# Install rules for production headers
	set(packageSourceFiles)
	get_property( binaryTargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS )
	foreach(target ${binaryTargets})
		cpfGetTargetSourcesWithoutPrefixHeader( sources ${target})
		cpfListAppend(packageSourceFiles ${sources})
		set_property(TARGET ${target} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS sources )
	endforeach()
	cpfInstallSourceFiles( relFiles ${packageComponent} "${packageSourceFiles}" SOURCE sources "" )

endfunction()



