# This file contains the functionality for adding a cpf package to a project.

include(GenerateExportHeader) # this must be put before the include_guard() or it wont work

include_guard(GLOBAL)

include(cpfInitPackageProject)
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
include(cpfAddDistributionPackageTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDoxygenPackage)
include(cpfAddVersionRcPreBuildEvent)


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
function( cpfAddCppPackage )

	cpfPrintAddPackageStatusMessage("C++")

	set( optionKeywords
	) 
	
	set( requiredSingleValueKeywords
		PACKAGE_NAMESPACE
		TYPE
	)

	set( optionalSingleValueKeywords
		BRIEF_DESCRIPTION
		LONG_DESCRIPTION
		OWNER
		WEBPAGE_URL
		MAINTAINER_EMAIL
		VERSION_COMPATIBILITY_SCHEME
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
		DISTRIBUTION_PACKAGES
		COMPILE_OPTIONS
	)

	# parse level 0 keywords
	cmake_parse_arguments(
		ARG 
		"${optionKeywords}" 
		"${requiredSingleValueKeywords};${optionalSingleValueKeywords}"
		"${requiredMultiValueKeywords};${optionalMultiValueKeywords}"
		${ARGN} 
	)

	cpfAssertKeywordArgumentsHaveValue( "${requiredSingleValueKeywords};${requiredMultiValueKeywords}" ARG "cpfAddCppPackage()")
	
	cpfAssertProjectVersionDefined()

	# Use values of global variables for unset arguments.
	cpfSetIfNotSet( ARG_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS "${CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS}")
	cpfSetIfNotSet( ARG_ENABLE_ABI_API_STABILITY_CHECK_TARGETS "${CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS}")
	cpfSetIfNotSet( ARG_ENABLE_CLANG_FORMAT_TARGETS "${CPF_ENABLE_CLANG_FORMAT_TARGETS}")
	cpfSetIfNotSet( ARG_ENABLE_CLANG_TIDY_TARGET "${CPF_ENABLE_CLANG_TIDY_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_OPENCPPCOVERAGE_TARGET "${CPF_ENABLE_OPENCPPCOVERAGE_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_PACKAGE_DOX_FILE_GENERATION "${CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION}")
	cpfSetIfNotSet( ARG_ENABLE_PRECOMPILED_HEADER "${CPF_ENABLE_PRECOMPILED_HEADER}")
	cpfSetIfNotSet( ARG_ENABLE_RUN_TESTS_TARGET "${CPF_ENABLE_RUN_TESTS_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_VALGRIND_TARGET "${CPF_ENABLE_VALGRIND_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_VERSION_RC_FILE_GENERATION "${CPF_ENABLE_VERSION_RC_FILE_GENERATION}")
	cpfSetIfNotSet( ARG_COMPILE_OPTIONS "${CPF_COMPILE_OPTIONS}")

	# parse argument sublists
	set( allKeywords ${optionKeywords} ${requiredSingleValueKeywords} ${optionalSingleValueKeywords} ${requiredMultiValueKeywords} ${optionalMultiValueKeywords})
	cpfGetKeywordValueLists( pluginOptionLists PLUGIN_DEPENDENCIES "${allKeywords}" "${ARGN}" pluginOptions)
	cpfGetKeywordValueLists( distributionPackageOptionLists DISTRIBUTION_PACKAGES "${allKeywords}" "${ARGN}" packagOptions)

	# By default build test targets.
	# Hunter sets this to off in order to skip test building.
	cpfGetPackageName(package)
	if( NOT "${${package}_BUILD_TESTS}" STREQUAL OFF )
		set( ${package}_BUILD_TESTS ON)
	endif()

	# ASSERT ARGUMENTS

	# Print debug output if linked targets do not exist.
	cpfDebugAssertLinkedLibrariesExists( linkedLibraries ${package} "${ARG_LINKED_LIBRARIES}")
	cpfDebugAssertLinkedLibrariesExists( linkedTestLibraries ${package} "${ARG_LINKED_TEST_LIBRARIES}")

	# Replace alias targets with the original names, because they can cause trouble with custom targets.
	cpfStripTargetAliases(linkedLibraries "${linkedLibraries}")
	cpfStripTargetAliases(linkedTestLibraries "${linkedTestLibraries}")

	# If a library does not have a public header, it must be a user mistake
	if( (${ARG_TYPE} STREQUAL LIB) AND (NOT ARG_PUBLIC_HEADER) )
		message(FATAL_ERROR "Library package ${package} has no public headers. The library can not be used without public headers, so please add the PUBLIC_HEADER argument to the cpfAddCppPackage() call.")
	endif()

	if(NOT ARG_VERSION_COMPATIBILITY_SCHEME)
		set(ARG_VERSION_COMPATIBILITY_SCHEME ExactVersion)
	endif()
	cpfAssertCompatibilitySchemeOption(${ARG_VERSION_COMPATIBILITY_SCHEME})

	# make sure that the properties of the imported targets follow our assumptions
	cpfNormalizeImportedTargetProperties( "${linkedLibraries};${linkedTestLibraries}" )

	# Configure the c++ header file with the version.
	cpfConfigurePackageVersionHeader( ${package} ${PROJECT_VERSION} ${ARG_PACKAGE_NAMESPACE})

	# Add the binary targets
	cpfAddPackageBinaryTargets( 
		productionLibrary 
		${package} 
		"${ARG_BRIEF_DESCRIPTION}"
		"${ARG_OWNER}"
		${ARG_PACKAGE_NAMESPACE} 
		${ARG_TYPE} 
		"${ARG_PUBLIC_HEADER}" 
		"${ARG_PRODUCTION_FILES}"
		"${ARG_EXE_FILES}"
		"${ARG_PUBLIC_FIXTURE_HEADER}" 
		"${ARG_FIXTURE_FILES}" 
		"${ARG_TEST_FILES}" 
		"${linkedLibraries}" 
		"${linkedTestLibraries}"
		${ARG_VERSION_COMPATIBILITY_SCHEME}
		${ARG_ENABLE_CLANG_FORMAT_TARGETS}
		${ARG_ENABLE_PRECOMPILED_HEADER}
		${ARG_ENABLE_VERSION_RC_FILE_GENERATION}
		"${ARG_COMPILE_OPTIONS}"
	)

	#set some package properties
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_BRIEF_PACKAGE_DESCRIPTION ${ARG_BRIEF_DESCRIPTION} )
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_LONG_PACKAGE_DESCRIPTION ${ARG_LONG_DESCRIPTION} )
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_PACKAGE_WEBPAGE_URL ${ARG_WEBPAGE_URL} )
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_PACKAGE_MAINTAINER_EMAIL ${ARG_MAINTAINER_EMAIL} )
	
	
	# add other custom targets

	# add a target the will be build before the binary target and that will copy all 
	# depended on shared libraries to the targets output directory.
	cpfAddDeploySharedLibrariesTarget(${package})

	# Adds target that runs clang-tidy on the given files.
    # Currently this is only added for the production target because clang-tidy does not filter out warnings that come over the GTest macros from external code.
    # When clang-tidy resolves the problem, static analysis should be executed for all binary targets.
	if(${ARG_ENABLE_CLANG_TIDY_TARGET})
		cpfAddClangTidyTarget(${productionLibrary})
	endif()
	
	if(${ARG_ENABLE_RUN_TESTS_TARGET})
		cpfAddRunCppTestsTargets(${package})
	endif()

	if(${ARG_ENABLE_VALGRIND_TARGET})
		cpfAddValgrindTarget(${package})
	endif()

	if(${ARG_ENABLE_OPENCPPCOVERAGE_TARGET})
		cpfAddOpenCppCoverageTarget(${package})
	endif()

	# A target to generate a .dox file that is used to add links to the packages build results to the package documentation.
	if(${ARG_ENABLE_PACKAGE_DOX_FILE_GENERATION})
		cpfAddPackageDocsTarget( ${package} ${ARG_PACKAGE_NAMESPACE} )
	endif()

	# Plugins must be added before the install targets
	cpfAddPlugins( ${package} "${pluginOptionLists}" )
	 
	# Adds a target the creates abi-dumps when using clang or gcc with debug options.
	cpfAddAbiCheckerTargets( 
		${package}
		"${distributionPackageOptionLists}"
		${ARG_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS}
		${ARG_ENABLE_ABI_API_STABILITY_CHECK_TARGETS}
	)
	
	# Adds the install rules and the per package install targets.
	cpfAddInstallRulesForCppPackage( ${package} ${ARG_PACKAGE_NAMESPACE} "${pluginOptionLists}" "${distributionPackageOptionLists}" ${ARG_VERSION_COMPATIBILITY_SCHEME} )

	# Adds the targets that create the distribution packages.
	cpfAddDistributionPackageTargets( ${package} "${distributionPackageOptionLists}" )

	cpfAddPackageInstallTarget(${package})

endfunction() 

#---------------------------------------------------------------------
#
function( cpfAddPackageBinaryTargets 
	outProductionLibrary 
	package
	shortDescription
	owner
	packageNamespace 
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
	getExistingPackageVersionFile( versionFile ${package} )
	list(APPEND productionFiles ${versionFile} )
	cpfGetPackageVersionCppHeaderFileName( versionHeader ${package} )
	list(APPEND publicHeaderFiles ${CMAKE_CURRENT_BINARY_DIR}/${versionHeader} )
	

	# Modify variables if the package creates an executable
	if("${type}" STREQUAL GUI_APP OR "${type}" STREQUAL CONSOLE_APP)

		set(isExe TRUE)
		set( productionTarget lib${package})
		#remove main.cpp from the files
		cpfAssertDefinedMessage(MAIN_CPP "A package of executable type must contain a main.cpp file.")
		list(REMOVE_ITEM productionFiles ${MAIN_CPP})
		foreach( iconFile ${iconFiles})
			list(REMOVE_ITEM productionFiles ${iconFile})
		endforeach()
		set(fileDescriptionExe ${shortDescription})
		set(fileDescriptionLib "Contains the functionality of the ${package} application.")

	else()

		set(isExe FALSE)
		set(productionTarget ${package})
		if(exeFiles)
			message(FATAL_ERROR "Error! The option EXE_FILES in cpfAddCppPackage() is only relevant for packages of type GUI_APP or CONSOLE_APP.")
		endif()
		set(fileDescriptionLib ${shortDescription})

	endif()
	

	###################### Create production library target ##############################
    if(productionFiles OR publicHeaderFiles)  

		set( libType ${type} )
		if(isExe)	# for executables the implementation lib is a normal lib.
			set(libType LIB)
		endif()

        cpfAddBinaryTarget(
			PACKAGE_NAME ${package}  
			PACKAGE_NAMESPACE ${packageNamespace}
			EXPORT_MACRO_PREFIX ${packageNamespace}
			TARGET_TYPE ${libType}
			NAME ${productionTarget}
			PUBLIC_HEADER ${publicHeaderFiles}
			FILES ${productionFiles}
			LINKED_LIBRARIES ${linkedLibraries}
			IDE_FOLDER ${package}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION ${fileDescriptionLib}
			OWNER ${owner}
			COMPILE_OPTIONS ${compileOptions}
	    )

    endif()

	###################### Create exe target ##############################
	if(isExe)
		
		set( exeTarget ${package})
		cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			PACKAGE_NAMESPACE ${packageNamespace}
			TARGET_TYPE ${type}
			NAME ${exeTarget}
			FILES ${MAIN_CPP} ${exeFiles}
			LINKED_LIBRARIES ${linkedLibraries} ${productionTarget}
			IDE_FOLDER ${package}/exe
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION ${fileDescriptionExe}
			OWNER ${owner}
			COMPILE_OPTIONS ${compileOptions}
	    )

	endif()
	
	########################## Test Targets ###############################
	set( VSTestFolder test)		# the name of the test targets folder in the visual studio solution

    ################### Create fixture library ##############################	
	if( fixtureFiles OR publicFixtureHeaderFiles )
        set( fixtureTarget ${productionTarget}${CPF_FIXTURE_TARGET_ENDING})
	    cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			PACKAGE_NAMESPACE ${packageNamespace}
			EXPORT_MACRO_PREFIX ${packageNamespace}_TESTS
			TARGET_TYPE LIB
			NAME ${fixtureTarget}
			PUBLIC_HEADER ${publicFixtureHeaderFiles}
			FILES ${fixtureFiles}
			LINKED_LIBRARIES ${productionTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION "A library that contains utilities for tests of the ${productionTarget} library."
			OWNER ${owner}
			COMPILE_OPTIONS ${compileOptions}
        )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF )
			set_property(TARGET ${fixtureTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()
		set_property(TARGET ${package} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET ${fixtureTarget} )
        
    endif()

    ################### Create unit test exe ##############################
	if( testFiles )
        set( unitTestsTarget ${productionTarget}${CPF_TESTS_TARGET_ENDING})
        cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			PACKAGE_NAMESPACE ${packageNamespace}
			TARGET_TYPE CONSOLE_APP
			NAME ${unitTestsTarget}
			FILES ${testFiles}
			LINKED_LIBRARIES ${productionTarget} ${fixtureTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_CLANG_FORMAT_TARGETS ${enableClangFormatTargets}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION "Runs tests of the ${productionTarget} library."
			OWNER ${owner}
			COMPILE_OPTIONS ${compileOptions}
        )
		set_property(TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET ${unitTestsTarget} )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF)
			set_property(TARGET ${unitTestsTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()

    endif()
    
	# Set some properties
	set(binaryTargets ${exeTarget} ${fixtureTarget} ${productionTarget} ${unitTestsTarget})
    set_property(TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS ${binaryTargets})
	set_property(TARGET ${package} APPEND PROPERTY INTERFACE_CPF_PACKAGE_SUBTARGETS ${binaryTargets})
    set_property(TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET ${productionTarget})
	set( ${outProductionLibrary} ${productionTarget} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
# Adds a binary target 
#
function( cpfAddBinaryTarget )

	cmake_parse_arguments(
		ARG 
		"" 
		"PACKAGE_NAME;PACKAGE_NAMESPACE;EXPORT_MACRO_PREFIX;TARGET_TYPE;NAME;IDE_FOLDER;VERSION_COMPATIBILITY_SCHEME;ENABLE_CLANG_FORMAT_TARGETS;ENABLE_PRECOMPILED_HEADER;ENABLE_VERSION_RC_FILE_GENERATION;BRIEF_DESCRIPTION;OWNER" 
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
			# Remove the lib prefix on Linux. We expect that to be part of the package name.
			set_property(TARGET ${ARG_NAME} PROPERTY PREFIX "")

		endif()

		# make sure that clients have the /D <target>_IMPORTS compile option set.
		if( ${BUILD_SHARED_LIBS} AND MSVC)
			target_compile_definitions(${ARG_NAME} INTERFACE /D ${ARG_NAME}_IMPORTS )
		endif()
		
    endif()

    # Link with other libraries
	# This must be done before setting up the precompiled headers.
	target_link_libraries(${ARG_NAME} PUBLIC ${ARG_LINKED_LIBRARIES})

    # Set target properties
	# Set include directories, that all header are included with #include <package/myheader.h>
	# We do not use special directories for private or public headers. So the include directory is public.
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
			$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
			$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
		)

	else()

		if(ARG_COMPILE_OPTIONS)
			target_compile_options(${ARG_NAME} ${ARG_COMPILE_OPTIONS})
		endif()

		# set include directories
		target_include_directories( ${ARG_NAME} PUBLIC 
			$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
			$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
		)

		# set the Visual Studio folder property
		set_property( TARGET ${ARG_NAME} PROPERTY FOLDER ${ARG_IDE_FOLDER})

		# Set the target version
		set_property( TARGET ${ARG_NAME} PROPERTY VERSION ${PROJECT_VERSION} )
		if("${ARG_VERSION_COMPATIBILITY_SCHEME}" STREQUAL ExactVersion)
			set_property( TARGET ${ARG_NAME} PROPERTY SOVERSION ${PROJECT_VERSION} )
		else()
			message(FATAL_ERROR "Unexpected compatibility scheme!")
		endif()

		# Generate the header file with the dll export and import macros
		cpfGenerateExportMacroHeader(${ARG_NAME} "${ARG_EXPORT_MACRO_PREFIX}")

		# set target to use pre-compiled header
		# compile flags can not be changed after this call
		if(${ARG_ENABLE_PRECOMPILED_HEADER})
			cpfAddPrecompiledHeader(${ARG_NAME})
		endif()

		# Setup automatic creation of a version.rc file on windows
		if(NOT ARG_DISABLE_VERSION_RC_GENERATION)
			cpfAddVersionRcPreBuildEvent(
				PACKAGE	${ARG_PACKAGE_NAME}
				BINARY_TARGET ${ARG_NAME}
				VERSION ${PROJECT_VERSION}
				BRIEF_DESCRIPTION ${ARG_BRIEF_DESCRIPTION}
				OWNER ${ARG_OWNER}
			)
		endif()

	endif()

	# public header
	set_property( TARGET ${ARG_NAME} APPEND PROPERTY INTERFACE_CPF_PUBLIC_HEADER ${ARG_PUBLIC_HEADER})

	# sets all the <bla>_OUTPUT_DIRECTORY_<config> options
	cpfSetTargetOutputDirectoriesAndNames(${ARG_PACKAGE_NAME} ${ARG_NAME})

	# sort files into folders in visual studio
	cpfSetIDEDirectoriesForTargetSources(${ARG_NAME})

	# Add an alias target to allow using namespaced names for inlined packages.
	cpfAddAliasTarget(${ARG_NAME} ${ARG_PACKAGE_NAMESPACE})

	# Adds a clang-format target
	if(ARG_ENABLE_CLANG_FORMAT_TARGETS)
		cpfAddClangFormatTarget(${ARG_PACKAGE_NAME} ${ARG_NAME})
	endif()

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
# Call this function to make sure explicitly loaded shared libraries are deployed besides the packages executables in the build and install stage.
# The package has no knowledge about plugins, so they must be explicitly deployed with this function.
#
# pluginDependencies A list where the first element is the relative path of the plugin and the folling elements are the plugin targets.
# 
function( cpfAddPlugins package pluginOptionLists )

	cpfGetExecutableTargets( exeTargets ${package})
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
			add_dependencies( ${package} ${plugin}) # adds the artifical dependency
			cpfAddDeploySharedLibsToBuildStageTarget( ${package} ${plugin} ${subdirectory} ) 
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
# Adds install rules for the various package components.
#
function( cpfAddInstallRulesForCppPackage package namespace pluginOptionLists distributionPackageOptionLists versionCompatibilityScheme )

	cpfAddInstallRulesForPackageBinaries( ${package} ${versionCompatibilityScheme} )
	cpfGenerateAndInstallCmakeConfigFiles( ${package} ${namespace} ${versionCompatibilityScheme} )
	cpfAddInstallRulesForPublicHeaders( ${package} )
	cpfAddInstallRulesForPDBFiles( ${package} )
	cpfAddInstallRulesForDependedOnSharedLibraries( ${package} "${pluginOptionLists}" "${distributionPackageOptionLists}" )
	cpfAddInstallRulesForSources( ${package} )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRulesForPackageBinaries package versionCompatibilityScheme )
	
	cpfGetProductionTargets( productionTargets ${package} )
	cpfAddInstallRulesForBinaryTargets( ${package} "${productionTargets}" "" ${versionCompatibilityScheme} )

	cpfGetTestTargets( testTargets ${package})
	if(testTargets)
		cpfAddInstallRulesForBinaryTargets( ${package} "${testTargets}" developer ${versionCompatibilityScheme} )
	endif()
    
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRulesForBinaryTargets package targets component versionCompatibilityScheme )

	# Do not install the targets that have been removed from the ALL_BUILD target
	cpfFilterInTargetsWithProperty( interfaceLibs "${targets}" TYPE INTERFACE_LIBRARY )
	cpfFilterOutTargetsWithProperty( noneInterfaceLibTargets "${targets}" TYPE INTERFACE_LIBRARY )
	cpfFilterOutTargetsWithProperty( noneInterfaceLibTargets "${noneInterfaceLibTargets}" EXCLUDE_FROM_ALL TRUE )
	set(targets ${interfaceLibs} ${noneInterfaceLibTargets})

	cpfGetRelativeOutputDir( relRuntimeDir ${package} RUNTIME )
	cpfGetRelativeOutputDir( relLibDir ${package} LIBRARY)
	cpfGetRelativeOutputDir( relArchiveDir ${package} ARCHIVE)
	cpfGetRelativeOutputDir( relIncludeDir ${package} INCLUDE)
	cpfGetTargetsExportsName( targetsExportName ${package})
		
	# Add an relative rpath to the executables that points to the lib directory.
	file(RELATIVE_PATH rpath "${CMAKE_CURRENT_BINARY_DIR}/${relRuntimeDir}" "${CMAKE_CURRENT_BINARY_DIR}/${relLibDir}")
	cpfAppendPackageExeRPaths( ${package} "\$ORIGIN/${rpath}")

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
			EXPORT ${targetsExportName}
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
			# This sets the import targets include directories to <package>/include, 
			# so clients can also include with <package/bla.h>
			INCLUDES
				DESTINATION "${relIncludeDir}/.."
		)

		set_property(TARGET ${target} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS ${component} ${additionalComponent} )

	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetsExportsName output package)
	set(${output} ${package}Targets PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# This function adds install rules for the files that are required for debugging.
# This is currently the pdb and source files for msvc configurations.
#
function( cpfAddInstallRulesForPDBFiles package )

	get_property(targets TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)

	cpfGetConfigurations( configs )
	foreach( config ${configs})

		cpfToConfigSuffix( suffix ${config})

		foreach(target ${targets})
	
			cpfIsInterfaceLibrary( isIntLib ${target})
			if(NOT isIntLib)

				# Install compiler generated pdb files
				get_property( compilePdbName TARGET ${target} PROPERTY COMPILE_PDB_NAME_${suffix} )
				get_property( compilePdbDir TARGET ${target} PROPERTY COMPILE_PDB_OUTPUT_DIRECTORY_${suffix} )
				cpfGetRelativeOutputDir( relPdbCompilerDir ${package} COMPILE_PDB )
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
				cpfGetRelativeOutputDir( relPdbLinkerDir ${package} PDB)
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
					cpfInstallSourceFiles( relFiles ${package} "${cppSources}" SOURCE developer ${config} )

					# Add the installed files to the target property
					cpfPrependMulti(relInstallPaths "${relSourceDir}/" "${shortSourceNames}" )

				endif()

			endif()

		endforeach()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRulesForPublicHeaders package)

	set(outputType INCLUDE)
	set(installComponent developer)

	# Install rules for production headers
	get_property( productionLib TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
	get_property( header TARGET ${productionLib} PROPERTY INTERFACE_CPF_PUBLIC_HEADER)
	cpfInstallSourceFiles( relBasicHeader ${package} "${header}" ${outputType} ${installComponent} "")
	
	# Install rules for test fixture library headers
	get_property( fixtureTarget TARGET ${package} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET)
	if(TARGET ${fixtureTarget})
		get_property( header TARGET ${fixtureTarget} PROPERTY INTERFACE_CPF_PUBLIC_HEADER)
		cpfInstallSourceFiles( relfixtureHeader ${package} "${header}" ${outputType} ${installComponent} "")
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallSourceFiles installedFilesOut package sources outputType installComponent config )

    # Create header pathes relative to the install include directory.
    set( sourceDir ${${package}_SOURCE_DIR})
	set( binaryDir ${${package}_BINARY_DIR})
	cpfGetRelativeOutputDir( relIncludeDir ${package} ${outputType})

	set(installedFiles)
	foreach( file ${sources})
		
		cpfToAbsSourcePath(absFile ${file} ${${package}_SOURCE_DIR})

		# When building, the include directories are the packages binary and source directory.
		# This means we need the path of the header relative to one of the two in order to get the
		# relative path to the distribution packages install directory right.
		file(RELATIVE_PATH relPathSource ${${package}_SOURCE_DIR} ${absFile} )
		file(RELATIVE_PATH relPathBinary ${${package}_BINARY_DIR} ${absFile} )
		cpfGetShorterString( relFilePath ${relPathSource} ${relPathBinary}) # assume the shorter path is the correct one

		# prepend the include/<package> directory
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
function( cpfGenerateAndInstallCmakeConfigFiles package namespace compatibilityScheme )

	# Generate the cmake config files
	set(packageConfigFile ${package}Config.cmake)
	set(versionConfigFile ${package}ConfigVersion.cmake )
	set(packageConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${packageConfigFile}")	# The config file is used by find package 
	set(versionConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${versionConfigFile}")
	cpfGetRelativeOutputDir( relCmakeFilesDir ${package} CMAKE_PACKAGE_FILES)
	cpfGetTargetsExportsName( targetsExportName ${package})

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
		EXPORT "${targetsExportName}"
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
# internal or external packages. We only add these rules for packages that actually
# create distribution packages that include depended on shared libraries.
#
function( cpfAddInstallRulesForDependedOnSharedLibraries package pluginOptions distributionPackageOptionLists )

	cpfGetDependedOnSharedLibrariesAndDirectories( libraries directories ${package} "${pluginOptions}" )

	# Add install rules for each distribution package that has a runtime-portable content.
	set(contentIds)
	foreach( list ${distributionPackageOptionLists})

		cpfParseDistributionPackageOptions( contentType packageFormats distributionPackageFormatOptions excludedTargets "${${list}}")
		if( "${contentType}" STREQUAL CT_RUNTIME_PORTABLE )
			cpfGetDistributionPackageContentId( contentId ${contentType} "${excludedTargets}" )
			cpfContains(contentTypeHandled "${contentIds}" ${contentId})
			if(NOT ${contentTypeHandled})
				
				cpfListAppend(contentIds ${contentId})
				removeExcludedTargets( libraries directories "${libraries}" "${directories}" "${excludedTargets}" )
				addSharedLibraryDependenciesInstallRules( ${package} ${contentId} "${libraries}" "${directories}" )
			
			endif()
		endif()
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with shared library targets and one with a relative directory for each
# target to which the shared library must be copied.
#
function( cpfGetDependedOnSharedLibrariesAndDirectories librariesOut directoriesOut package pluginOptionLists )

	cpfGetRelativeOutputDir( relRuntimeDir ${package} RUNTIME)
	cpfGetRelativeOutputDir( relLibraryDir ${package} LIBRARY)

	# Get plugin targets and relative directories
	cpfGetPluginTargetDirectoryPairLists( pluginTargets pluginDirectories "${pluginOptionLists}" )
	cpfPrependMulti( pluginDirectories "${relRuntimeDir}/" "${pluginDirectories}" )
	
	# Get library targets and add them to directories
	cpfGetSharedLibrariesRequiredByPackageProductionLib( libraries ${package} )
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
# This function was introduced to only have one definition of the distribution package option keywords
function( cpfParseDistributionPackageOptions contentTypeOut packageFormatsOut distributionPackageFormatOptionsOut excludedTargetsOut argumentList )

	cmake_parse_arguments(
		ARG 
		"" 
		"" 
		"DISTRIBUTION_PACKAGE_CONTENT_TYPE;DISTRIBUTION_PACKAGE_FORMATS;DISTRIBUTION_PACKAGE_FORMAT_OPTIONS"
		${argumentList}
	)

	set( contentTypeOptions 
		CT_DEVELOPER
		CT_RUNTIME
		CT_SOURCES
	)

	set(runtimePortableOption CT_RUNTIME_PORTABLE) 
	cmake_parse_arguments(
		ARG
		"${contentTypeOptions}"
		""
		"${runtimePortableOption}"
		"${ARG_DISTRIBUTION_PACKAGE_CONTENT_TYPE}"
	)
	
	# Check that only one content type was given.
	cpfContains(isRuntimeAndDependenciesType "${ARG_DISTRIBUTION_PACKAGE_CONTENT_TYPE}" ${runtimePortableOption})
	cpfPrependMulti( argOptions ARG_ "${contentTypeOptions}")
	set(nrOptions 0)
	foreach(option ${isRuntimeAndDependenciesType} ${argOptions})
		if(${option})
			cpfIncrement(nrOptions)
		endif()
	endforeach()
	
	if( NOT (${nrOptions} EQUAL 1) )
		message(FATAL_ERROR "Each DISTRIBUTION_PACKAGE_CONTENT_TYPE option in cpfAddCppPackage() must contain exactly one of these options: ${contentTypeOptions};${runtimePortableOption}. The given option was ${ARG_DISTRIBUTION_PACKAGE_CONTENT_TYPE}" )
	endif()
	
	if(ARG_CT_DEVELOPER)
		set(contentType CT_DEVELOPER)
	elseif(ARG_CT_RUNTIME)
		set(contentType CT_RUNTIME)
	elseif(isRuntimeAndDependenciesType)
		set(contentType CT_RUNTIME_PORTABLE)
	elseif(ARG_CT_SOURCES)
		set(contentType CT_SOURCES)
	else()
		message(FATAL_ERROR "Faulty DISTRIBUTION_PACKAGE_CONTENT_TYPE option in cpfAddCppPackage().")
	endif()
	
	set(${contentTypeOut} ${contentType} PARENT_SCOPE)
	set(${packageFormatsOut} ${ARG_DISTRIBUTION_PACKAGE_FORMATS} PARENT_SCOPE)
	set(${distributionPackageFormatOptionsOut} ${ARG_DISTRIBUTION_PACKAGE_FORMAT_OPTIONS} PARENT_SCOPE)
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
	else()
		message(FATAL_ERROR "Content type \"${contentType}\" is not supported by function contentTypeOutputNameIdentifier().")
	endif()
	
	set(${contentIdOut} ${contentIdLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function parses the distribution package options of the package and returns a list
# with the content-ids of all runtime-portable packages.
function( addSharedLibraryDependenciesInstallRules package contentId libraries directories )

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

	set_property(TARGET ${package} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS ${contentId} )

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddInstallRulesForSources package )

	set(outputType INCLUDE)
	set(installComponent developer)

	# Install rules for production headers
	set(packageSourceFiles)
	get_property( binaryTargets TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS )
	foreach(target ${binaryTargets})
		cpfGetTargetSourcesWithoutPrefixHeader( sources ${target})
		cpfListAppend(packageSourceFiles ${sources})
		set_property(TARGET ${target} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS sources )
	endforeach()
	cpfInstallSourceFiles( relFiles ${package} "${packageSourceFiles}" SOURCE sources "" )

endfunction()



