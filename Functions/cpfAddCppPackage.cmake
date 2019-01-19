# This file contains the functionality for adding a cpf package to a project.

include(GenerateExportHeader) # this must be put before the include_guard() or it wont work

include_guard(GLOBAL)

include(cpfInitPackageProject)
include(cpfLocations)
include(cpfConstants)
include(cpfProjectUtilities)
include(cpfGitUtilities)
include(cpfPathUtilities)
include(cpfTargetUtilities)

include(cpfAddClangTidyTarget)
include(cpfAddRunTestsTarget)
include(cpfAddDeploySharedLibrariesTarget)
include(cpfAddInstallRules)
include(cpfAddDistributionPackageTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDoxygenPackage)
include(cpfAddVersionRcPreBuildEvent)

# cotire must be included on the global scope or we get errors that target xyz already has a custom rule
set(cotirePath "${CMAKE_CURRENT_LIST_DIR}/../../cotire/CMake/cotire.cmake")
if(CPF_ENABLE_PRECOMPILED_HEADER AND ${CMAKE_SOURCE_DIR}) # do not enter this when included from scripts or pchs are disabled.
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
		ENABLE_CLANG_TIDY_TARGET
		ENABLE_OPENCPPCOVERAGE_TARGET
		ENABLE_PACKAGE_DOX_FILES_GENERATION
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
	cpfSetIfNotSet( ARG_OWNER "${CPF_OWNER}")
	cpfSetIfNotSet( ARG_WEBPAGE_URL "${CPF_PROJECT_WEBPAGE_URL}")
	cpfSetIfNotSet( ARG_MAINTAINER_EMAIL "${CPF_MAINTAINER_EMAIL}")
	cpfSetIfNotSet( ARG_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS "${CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS}")
	cpfSetIfNotSet( ARG_ENABLE_ABI_API_STABILITY_CHECK_TARGETS "${CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS}")
	cpfSetIfNotSet( ARG_ENABLE_CLANG_TIDY_TARGET "${CPF_ENABLE_CLANG_TIDY_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_OPENCPPCOVERAGE_TARGET "${CPF_ENABLE_OPENCPPCOVERAGE_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_PACKAGE_DOX_FILES_GENERATION "${CPF_ENABLE_PACKAGE_DOX_FILES_GENERATION}")
	cpfSetIfNotSet( ARG_ENABLE_PRECOMPILED_HEADER "${CPF_ENABLE_PRECOMPILED_HEADER}")
	cpfSetIfNotSet( ARG_ENABLE_RUN_TESTS_TARGET "${CPF_ENABLE_RUN_TESTS_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_VALGRIND_TARGET "${CPF_ENABLE_VALGRIND_TARGET}")
	cpfSetIfNotSet( ARG_ENABLE_VERSION_RC_FILE_GENERATION "${CPF_ENABLE_VERSION_RC_FILE_GENERATION}")

	# parse argument sublists
	set( allKeywords ${optionKeywords} ${requiredSingleValueKeywords} ${optionalSingleValueKeywords} ${requiredMultiValueKeywords} ${optionalMultiValueKeywords})
	cpfGetKeywordValueLists( pluginOptionLists PLUGIN_DEPENDENCIES "${allKeywords}" "${ARGN}" pluginOptions)
	cpfGetKeywordValueLists( distributionPackageOptionLists DISTRIBUTION_PACKAGES "${allKeywords}" "${ARGN}" packagOptions)

	cpfGetPackageName(package)
	message(STATUS "Add C++ package ${package} at version ${PROJECT_VERSION}")
	
	# By default build test targets.
	# Hunter sets this to off in order to skip test building.
	if( NOT "${${package}_BUILD_TESTS}" STREQUAL OFF )
		set( ${package}_BUILD_TESTS ON)
	endif()

	# ASERT ARGUMENTS

	# Make sure that linked targets have already been created.
	cpfDebugAssertLinkedLibrariesExists( linkedLibraries ${package} "${ARG_LINKED_LIBRARIES}")
	cpfDebugAssertLinkedLibrariesExists( linkedTestLibraries ${package} "${ARG_LINKED_TEST_LIBRARIES}")
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
		"${ARG_LINKED_LIBRARIES}" 
		"${ARG_LINKED_TEST_LIBRARIES}"
		${ARG_VERSION_COMPATIBILITY_SCHEME}
		${ARG_ENABLE_PRECOMPILED_HEADER}
		${ARG_ENABLE_VERSION_RC_FILE_GENERATION}
	)

	#set some properties
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
	if(${ARG_ENABLE_PACKAGE_DOX_FILES_GENERATION})
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
	cpfAddInstallRules( ${package} ${ARG_PACKAGE_NAMESPACE} "${pluginOptionLists}" "${distributionPackageOptionLists}" ${ARG_VERSION_COMPATIBILITY_SCHEME} )

	# Adds the targets that create the distribution packages.
	cpfAddDistributionPackageTargets( ${package} "${distributionPackageOptionLists}" )

endfunction() 


#---------------------------------------------------------------------
# This function only returns the libraries from the input that actually exist.
# Lower level packages must be added first.
# For others a warning is issued when CPF_VERBOSE is ON.
# We allow adding dependencies to non existing targets so we can link to targets that may only be available
# on certain platforms.
#
function( cpfDebugAssertLinkedLibrariesExists linkedLibrariesOut package linkedLibrariesIn )

	foreach(lib ${linkedLibrariesIn})
		if(NOT TARGET ${lib} )
			cpfDebugMessage("${lib} is not a Target when creating package ${package}. If it should be available, make sure to have target ${lib} added before adding this package.")
		else()
			list(APPEND linkedLibraries ${lib})
		endif()
	endforeach()
	set(${linkedLibrariesOut} ${linkedLibraries} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
# Checks that the compatibility scheme option contains one of the allowed values.
function( cpfAssertCompatibilitySchemeOption scheme )
	if( NOT ( "${scheme}" STREQUAL ExactVersion ) )
		message(FATAL_ERROR "Invalid argument to cpfAddCppPackage()!. Value \"${scheme}\" for option VERSION_COMPATIBILITY_SCHEME is not allowed.")
	endif()
endfunction()

#---------------------------------------------------------------------
# This function is used to change properties of imported targets to make
# sure that property values are set after the same "scheme" on which the
# rest of the CPF cmake code can rely.
#
# E.g. On Linuy the LOCATION_<config> property should hold the location of the actual binary
# file and not the location of the symlink that points to the binary. The symlink
# location should be stored in the IMPORTED_SONAME_<config> property.
#
function( cpfNormalizeImportedTargetProperties targets )

	# also get indirectly linked targets
	cpfGetAllTargetsInLinkTree( allLinkedTargets "${targets}")
	
	cpfFilterInTargetsWithProperty( importedTargets "${allLinkedTargets}" IMPORTED TRUE)
	foreach(target ${importedTargets})
	
		# make sure the location property does not point to a symbolic link but to the real file on linux
		if( ${CMAKE_SYSTEM_NAME} STREQUAL Linux)
			cpfIsSingleConfigGenerator( isSingleConfig )
			if(NOT ${isSingleConfig})
				message(FATAL_ERROR "Function cpfNormalizeImportedTargetProperties() assumes that there are only single configuration generators on linux.")
			endif()
			cpfToConfigSuffix( configSuffix ${CMAKE_BUILD_TYPE} ) 
			
			get_property( location TARGET ${target} PROPERTY LOCATION_${configSuffix} )
			if( IS_SYMLINK ${location} )
			
				# get the file to which the symlink points
				execute_process(COMMAND readlink;${location} RESULT_VARIABLE result OUTPUT_VARIABLE linkTarget )
				if(NOT ${result} STREQUAL 0)
					message(FATAL_ERROR "Could not read symlink ${location}")
				endif()
				# refine the output result
				string(STRIP ${linkTarget} linkTarget)
				get_filename_component( dir ${location} DIRECTORY)
				set(linkTarget "${dir}/${linkTarget}")
				
				# change the target properties
				if( EXISTS ${linkTarget})
					set_property( TARGET ${target} PROPERTY LOCATION_${configSuffix} ${linkTarget})
					set_property( TARGET ${target} PROPERTY IMPORTED_LOCATION_${configSuffix} ${linkTarget} )
					get_filename_component( locationShort ${location} NAME)
					set_property( TARGET ${target} PROPERTY IMPORTED_SONAME_${configSuffix} ${locationShort} )
				else()
					message( FATAL_ERROR "The soname symlink \"${location}\" of imported target ${target} points to the not existing file \"${linkTarget}\"." )
				endif()
				
			endif()
			
		endif()
	
	endforeach()
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
	enablePrecompiledHeader
	enableVersionRcGeneration
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
			EXPORT_MACRO_PREFIX ${packageNamespace}
			TARGET_TYPE ${libType}
			NAME ${productionTarget}
			PUBLIC_HEADER ${publicHeaderFiles}
			FILES ${productionFiles}
			LINKED_LIBRARIES ${linkedLibraries}
			IDE_FOLDER ${package}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION ${fileDescriptionLib}
			OWNER ${owner}
	    )

    endif()

	###################### Create exe target ##############################
	if(isExe)
		
		set( exeTarget ${package})
		cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			TARGET_TYPE ${type}
			NAME ${exeTarget}
			FILES ${MAIN_CPP} ${exeFiles}
			LINKED_LIBRARIES ${linkedLibraries} ${productionTarget}
			IDE_FOLDER ${package}/exe
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION ${fileDescriptionExe}
			OWNER ${owner}
	    )

	endif()
	
	########################## Test Targets ###############################
	set( VSTestFolder test)		# the name of the test targets folder in the visual studio solution

    ################### Create fixture library ##############################	
	if( fixtureFiles OR publicFixtureHeaderFiles )
        set( fixtureTarget ${productionTarget}${CPF_FIXTURE_TARGET_ENDING})
	    cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			EXPORT_MACRO_PREFIX ${packageNamespace}_TESTS
			TARGET_TYPE LIB
			NAME ${fixtureTarget}
			PUBLIC_HEADER ${publicFixtureHeaderFiles}
			FILES ${fixtureFiles}
			LINKED_LIBRARIES ${productionTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION "A library that contains utilities for tests of the ${productionTarget} library."
			OWNER ${owner}
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
			TARGET_TYPE CONSOLE_APP
			NAME ${unitTestsTarget}
			FILES ${testFiles}
			LINKED_LIBRARIES ${productionTarget} ${fixtureTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
			ENABLE_PRECOMPILED_HEADER ${enablePrecompiledHeader}
			ENABLE_VERSION_RC_FILE_GENERATION ${enableVersionRcGeneration}
			BRIEF_DESCRIPTION "Runs tests of the ${productionTarget} library."
			OWNER ${owner}
        )
		set_property(TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET ${unitTestsTarget} )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF)
			set_property(TARGET ${unitTestsTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()

    endif()
    
	# Set some properties
    set_property(TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS ${exeTarget} ${fixtureTarget} ${productionTarget} ${unitTestsTarget} )
    set_property(TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET ${productionTarget} )
	set( ${outProductionLibrary} ${productionTarget} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
#
# Adds a binary target 
# 
# Arguments:
# PACKAGE_NAME				The name of the package to which the target belongs.
# PACKAGE_NAMESPACE			The namespace of the package
# TARGET_TYPE				GUI_APP = executable with switched of console (use for QApplications with ui); CONSOLE_APP = console application; LIB = library (use to create a static or shared libraries )
# NAME						The name of the added binary target.
# LINKAGE					Only relevant when adding a library. This takes STATIC or SHARED
# PUBLIC_HEADER				The header files that are required by clients that link to the target.
# FILES						All files that belong to the target.
# LINKED_LIBRARIES			Other targets on which this target depends.
# 
function( cpfAddBinaryTarget )

	cmake_parse_arguments(
		ARG 
		"" 
		"PACKAGE_NAME;EXPORT_MACRO_PREFIX;TARGET_TYPE;NAME;IDE_FOLDER;VERSION_COMPATIBILITY_SCHEME;ENABLE_PRECOMPILED_HEADER;ENABLE_VERSION_RC_FILE_GENERATION;BRIEF_DESCRIPTION;OWNER" 
		"PUBLIC_HEADER;FILES;LINKED_LIBRARIES" 
		${ARGN} 
	)
	set( allSources ${ARG_PUBLIC_HEADER} ${ARG_FILES})

	cpfQt5AddUIAndQrcFiles( allSources )

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

    # Set target properties
	# Set include directories, that all header are included with #include <package/myheader.h>
	# We do not use special directories for private or public headers. So the include directory is public.
	if(isInterfaceLib)

		set_property(TARGET ${ARG_NAME} PROPERTY INTERFACE_INCLUDE_DIRECTORIES  
			$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
			$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
		)

	else()

		target_include_directories( ${ARG_NAME} PUBLIC 
			$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
			$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
		)

		# set the Visual Studio folder property
		set_property( TARGET ${ARG_NAME} PROPERTY FOLDER ${ARG_IDE_FOLDER})

		# Enable qt auto moc
		# Note that we AUTOUIC and AUTORCC is not used because I was not able to get the names of
		# the generated files at cmake time which is required when setting source groups and 
		# adding the generated ui_*.h header to the targets interface include directories.
		set_property( TARGET ${ARG_NAME} PROPERTY AUTOMOC ON)

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
	cpfSetTargetOutputDirectoriesAndNames( ${ARG_PACKAGE_NAME} ${ARG_NAME})

    # link with other libraries
    target_link_libraries(${ARG_NAME} PUBLIC ${ARG_LINKED_LIBRARIES} )
	cpfRemoveWarningFlagsForSomeExternalFiles(${ARG_NAME})

	# sort files into folders in visual studio
	cpfSetIDEDirectoriesForTargetSources(${ARG_NAME})

endfunction()


#----------------------------------------- macro from Lars Christensen to use precompiled headers --------------------------------
# this was copied from https://gist.github.com/larsch/573926
# this might be an alternative if this does not work well enough: https://github.com/sakra/cotire
function(cpfAddPrecompiledHeader target )
	if(CPF_COTIRE_AVAILABLE) 
		
		# add the precompiled header (targets and compile flags)
		set_target_properties(${target} PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)  # prevent the generation of unity build targets
	
		cotire( ${target})
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
	foreach( file ${ARG_FILES})
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

#---------------------------------------------------------------------------------------------
# Sets the <binary-type>_OUTOUT_DIRECTORY_<config> properties of the given target.
#
function( cpfSetTargetOutputDirectoriesAndNames package target )

	cpfGetConfigurations( configs)
	foreach(config ${configs})
		cpfSetAllOutputDirectoriesAndNames(${target} ${package} ${config} )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfSetAllOutputDirectoriesAndNames target package config )

	# The output directory properties can not be set on interface libraries.
	cpfIsInterfaceLibrary(isIntLib ${target})
	if(isIntLib)
		return()
	endif()

	cpfToConfigSuffix( configSuffix ${config})

	# Delete the <config>_postfix property and handle things manually in cpfSetOutputDirAndName()
	string(TOUPPER ${config} uConfig)
	set_property( TARGET ${target} PROPERTY ${uConfig}_POSTFIX "" )

	cpfSetOutputDirAndName( ${target} ${package} ${config} RUNTIME)
	cpfSetOutputDirAndName( ${target} ${package} ${config} LIBRARY)
	cpfSetOutputDirAndName( ${target} ${package} ${config} ARCHIVE)

	cpfProjectProducesPdbFiles(hasOutput ${config})
	if(hasOutput)
		cpfSetOutputDirAndName( ${target} ${package} ${config} COMPILE_PDB)
		set_property(TARGET ${target} PROPERTY COMPILE_PDB_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX}-compiler) # we overwrite the filename to make it more meaningful
	endif()

	cpfTargetHasPdbLinkerOutput(hasOutput ${target} ${configSuffix})
	if(hasOutput)
		# Note that we use the same name and path for linker as are used for the dlls files.
		# When consuming imported targets we guess that the pdb files have these locations. 
		cpfSetOutputDirAndName( ${target} ${package} ${config} PDB)
		set_property(TARGET ${target} PROPERTY PDB_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX})
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
# This function sets the output name property to make sure that the same target file names are
# achieved across all platforms.
function( cpfSetOutputDirAndName target package config outputType )

	cpfGetAbsOutputDir(outputDir ${package} ${outputType} ${config})
	cpfToConfigSuffix(configSuffix ${config})
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY_${configSuffix} ${outputDir})
	# use the config postfix for all target types
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX} )

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




