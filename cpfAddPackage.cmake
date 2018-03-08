
include(cpfLocations)
include(cpfConstants)
include(GenerateExportHeader)
include(CMakePackageConfigHelpers)
include(cpfProjectUtilities)
include(cpfGitUtilities)

include(cpfAddStaticAnalysisTarget)
include(cpfAddDynamicAnalysisTarget)
include(cpfAddRunTestsTarget)
include(cpfAddDeploySharedLibrariesTarget)
include(cpfAddInstallPackageTarget)
include(cpfAddDistributionPackageTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDocumentationTarget)

set(DIR_OF_ADD_PACKAGE_FILE ${CMAKE_CURRENT_LIST_DIR})


#-------------------------------------------------------------------------
macro( cpfInitPackageProject packageNameOut packageNameSpace )

	# The package name is defined by the sub-directory name
	cpfGetParentFolder( packageName ${CMAKE_CURRENT_LIST_FILE})

	cpfConfigurePackageVersionFile( ${packageName} )

	# get the version number of the packages version file
	cpfGetPackageVersionFromFile( packageVersion ${packageName} ${CMAKE_CURRENT_LIST_DIR})
	message(STATUS "Package ${packageName} is now at version ${packageVersion}")
	# Configure the c++ header file with the version.
	cpfConfigurePackageVersionHeader( ${packageName} ${packageVersion} ${packageNameSpace})

	cpfSplitVersion( major minor patch commitId ${packageVersion})

	# create a sub-project for the package
	project( 
		${packageName} 
		VERSION ${major}.${minor}.${patch}
		LANGUAGES CXX C
	)
	set(PROJECT_VERSION ${packageVersion})
	set(PROJECT_VERSION_MAJOR ${major})
	set(PROJECT_VERSION_MINOR ${minor})
	set(PROJECT_VERSION_PATCH ${patch})
	set(PROJECT_VERSION_TWEAK ${commitId})

	set(${packageNameOut} ${packageName}) # this is a macro, so no PARENT_SCOPE

endmacro()

#-----------------------------------------------------------
# Creates the cpfPackageVersion_<package>.cmake file in the Sources directory, by reading the version from git.
# The file is required to provide a version if the build is done with sources that are not checked out from git.
#
function( cpfConfigurePackageVersionFile package )

	# Get the paths of the created files.
	cpfGetPackageVersionFileName( cmakeVersionFile ${package})
	set( absPathCmakeVersionFile "${CMAKE_CURRENT_SOURCE_DIR}/${cmakeVersionFile}")
	
	# Check if we work with a git repository.
	# If so, we retrieve the version from the repository.
	# If not, this must be an installed archive and the .cmake version file must already exist.
	cpfIsGitRepositoryDir( isRepoDirOut "${CMAKE_CURRENT_SOURCE_DIR}")
	if(isRepoDirOut)
	
		set(PACKAGE_NAME ${package})
		cpfGetCurrentVersionFromGitRepository( CPF_PACKAGE_VERSION "${CMAKE_CURRENT_SOURCE_DIR}")
		cpfConfigureFileWithVariables( "${DIR_OF_ADD_PACKAGE_FILE}/Templates/packageVersion.cmake.in" "${absPathCmakeVersionFile}" PACKAGE_NAME CPF_PACKAGE_VERSION )
	
	else()
		if(NOT EXISTS "${absPathCmakeVersionFile}" )
			message(FATAL_ERROR "The package source directory \"${CMAKE_CURRENT_SOURCE_DIR}\" neither belongs to a git repository nor cpfContains a .cmake version file.")
		endif()
	endif()

endfunction()

#-----------------------------------------------------------
function( cpfConfigurePackageVersionHeader package version packageNamespace)

	set( PACKAGE_NAME ${package})
	set( PACKAGE_NAMESPACE ${packageNamespace})
	set( CPF_PACKAGE_VERSION ${version} )

	cpfGetPackageVersionCppHeaderFileName( versionHeaderFile ${package})
	set( absPathVersionHeader "${CMAKE_CURRENT_BINARY_DIR}/${versionHeaderFile}")

	cpfConfigureFileWithVariables( "${DIR_OF_ADD_PACKAGE_FILE}/Templates/packageVersion.h.in" "${absPathVersionHeader}" PACKAGE_NAME CPF_PACKAGE_VERSION PACKAGE_NAMESPACE ) 

endfunction()

#-----------------------------------------------------------
# Adds a c++ package to the CMakeProjectFramework.
# A package consists of a main binary target that has the same name as the package and some helper binary targets for tests and test utilities.
# The test fixture library, the unit tests exe and the expensive tests exe will only be created if the file lists contain files.  
# If the target tye is an executable an extra library is created that should contain the code for the exe. The executable target will only contain the main.cpp file with the main function as small as possible. 
# This is needed so we can test the code in the test exes without needing to add the source files to the test targets.
#
# A package also has a number of custom targets that implement additional functionality like code analysis, packaging etc.
# TODO: list all targets and what they do.
# 
# Arguments:
# PACKAGE_NAME											The name of the module/target/project
# TYPE													GUI_APP = executable with switched of console (use for QApplications with ui); 
#														CONSOLE_APP = console application; 
#														LIB = library (use to create a static or shared libraries )
# PUBLIC_HEADER											All header files that are required by clients of the package in order to compile.
# PRODUCTION_FILES										All files that belong to the production target. If the target is an executable, there should be a main.cpp that is used for the executable.
# PUBLIC_FIXTURE_HEADER									All header files in the fixture library that are required by clients of the library.
# FIXTURE_FILES											All files that belong to the test fixtures target.
# TEST_FILES											All files that belong to the tests executable target.
# LINKED_LIBRARIES										The names of the libraries that are linked with this target.
# LINKED_TEST_LIBRARIES									The dependencies of the test target that are not needed in the production code.
# [PLUGIN_DEPENDENCIES]...								This keyword opens a sublist of arguments that are used to define plugin dependencies of the packgage. 
#														Multiple PLUGIN_DEPENDENCIES sub-lists can be given to allow having multiple plugin subdirectories.
#														The plugin targets are shared libraries that are explicitly loaded by the packages executables and on which the
#														package has no link dependency. If a target in the list does not exist when the function is called,
#														it will be silently ignored. If a given target is an internal target, an artificial dependency between
#														the plugin target and the packages executables is created to make sure the plugin is compilation is up-to-date before the
#														executable is build.
#
#														Sub-Options:
#	PLUGIN_DIRECTORY									A directory relative to the packages executables in which the plugin libraries must be deployed so they are found by the executable.
#	PLUGIN_TARGETS										The name of the targets that provide the plugin libraries. 
#
# [DISTRIBUTION_PACKAGES]...			            	This keyword opens a sub-list of arguments that are used to specify a list of packages that have the same content, but different formats.
#                                                       The argument can be given multiple times, in order to define a variety of package formats and content types.
#                                                       The argument takes two lists as sub-arguments. A distribution package is created for each combination of the
#                                                       elements in the sub-argument lists.
#                                                       For example: 
#                                                       argument   DISTRIBUTION_PACKAGES_0 DISTRIBUTION_PACKAGE_CONTENT_TYPES BINARIES_USER_PORTABLE DISTRIBUTION_PACKAGE_FORMATS ZIP;7Z
#                                                       will cause the creation of a zip and a 7z archive that both contain the packages executables and all depended on shared libraries.
#                                                       Adding another argument  DISTRIBUTION_PACKAGES_1 DISTRIBUTION_PACKAGE_CONTENT_TYPES BINARIES_USER_NOSYSTEMLIBS DISTRIBUTION_PACKAGE_FORMATS DEB
#                                                       will cause the additional creation of a debian package, that will not contain the dependencies marked as system libraries.
#
#														Sub-Options
#   DISTRIBUTION_PACKAGE_CONTENT_TYPE                  	possible values:
#														BINARIES_DEVELOPER              	- The package will include all package binaries, header files and cmake config files for importing the package in another project.
#                                                                                         	  This content type is supposed to be used for packages that distribute "closed source" libraries.
#                                                       BINARIES_USER [listExcludedTargets] - The package will include the packages executables and shared libraries and all depended on shared libraries. 
#																							  This is intended for packages that are delivered to the enduser who will not need header files etc.
#																							  The BINARIES_USER keyword can be followed by a list of depended on targets that shall not be included in the package.
#																							  This is usefull when the dependencies are provided by the systems package manager for example.
#
#   DISTRIBUTION_PACKAGE_FORMATS						7Z TBZ2 TGZ TXZ TZ ZIP			- Compressed archives. The distributed files are packed into one of the following archive formats: .7z, .tar.bz2, .tar.gz, .tar.xz, tar.Z, .zip
#														DEB								- A debian package .deb file. This will only be created when the dpkg tool is available.
#
#	DISTRIBUTION_PACKAGE_FORMAT_OPTIONS					A list of keyword arguments that contain further options for the creation of the distribution packages.
#
#		[SYSTEM_PACKAGES_DEB]							This is only relevant when using the DEB package format. The option must be a string that cpfContains the names and versions of the 
#														debian packages that provide the excluded shared libraries from the BINARIES_USER option. E.g.
#														"libc6 (>= 2.3.1-6), libc6 (< 2.4)"
#
# [BRIEF_DESCRIPTION]									A short description in one sentence about what the package does.
# [LONG_DESCRIPTION]									A longer description of the package.
# [HOMEPAGE]											A web address from where the source-code and/or the documentation of the package can be obtained.
# [MAINTAINER_EMAIL]									An email address under which the maintainers of the package can be reached.
#
function( cpfAddPackage )

	# parse level 0 keywords
	set( singleValueKeywords PACKAGE_NAME PACKAGE_NAMESPACE TYPE BRIEF_DESCRIPTION LONG_DESCRIPTION HOMEPAGE MAINTAINER_EMAIL)
	set( multiValueKeywords PUBLIC_HEADER PRODUCTION_FILES PUBLIC_FIXTURE_HEADER FIXTURE_FILES TEST_FILES LINKED_LIBRARIES LINKED_TEST_LIBRARIES PLUGIN_DEPENDENCIES DISTRIBUTION_PACKAGES )
	cmake_parse_arguments(
		ARG 
		"" 
		"${singleValueKeywords}"
		"${multiValueKeywords}"
		${ARGN} 
	)
	# parse argument sublists
	set( allKeywords ${singleValueKeywords} ${multiValueKeywords})
	cpfGetKeywordValueLists( pluginOptionLists PLUGIN_DEPENDENCIES "${allKeywords}" "${ARGN}" pluginOptions)
	cpfGetKeywordValueLists( distributionPackageOptionLists DISTRIBUTION_PACKAGES "${allKeywords}" "${ARGN}" packagOptions)
	
	cpfDebugMessage("Add Package ${ARG_PACKAGE_NAME}")
	
	# By default build test targets.
	# Hunter sets this to off in order to skip test building.
	if( NOT "${${ARG_PACKAGE_NAME}_BUILD_TESTS}" STREQUAL OFF )
		set( ${ARG_PACKAGE_NAME}_BUILD_TESTS ON)
	endif()

	cpfDebugAssertLinkedLibrariesExists( linkedLibraries ${ARG_PACKAGE_NAME} "${ARG_LINKED_LIBRARIES}")
	cpfDebugAssertLinkedLibrariesExists( linkedTestLibraries ${ARG_PACKAGE_NAME} "${ARG_LINKED_TEST_LIBRARIES}")

	# make sure that the properties of the imported targets follow our assumptions
	cpfNormalizeImportedTargetProperties( "${linkedLibraries};${linkedTestLibraries}" )

	# Add the binary targets
	cpfAddPackageBinaryTargets( productionLibrary ${ARG_PACKAGE_NAME} ${ARG_PACKAGE_NAMESPACE} ${ARG_TYPE} "${ARG_PUBLIC_HEADER}" "${ARG_PRODUCTION_FILES}" "${ARG_PUBLIC_FIXTURE_HEADER}" "${ARG_FIXTURE_FILES}" "${ARG_TEST_FILES}" "${ARG_LINKED_LIBRARIES}" "${ARG_LINKED_TEST_LIBRARIES}" )

	#set some properties
	set_property(TARGET ${ARG_PACKAGE_NAME} PROPERTY CPF_BRIEF_PACKAGE_DESCRIPTION ${ARG_BRIEF_DESCRIPTION} )
	set_property(TARGET ${ARG_PACKAGE_NAME} PROPERTY CPF_PACKAGE_HOMEPAGE ${ARG_HOMEPAGE} )
	set_property(TARGET ${ARG_PACKAGE_NAME} PROPERTY CPF_PACKAGE_MAINTAINER_EMAIL ${ARG_MAINTAINER_EMAIL} )
	
	
	# add other custom targets

	# add a target the will be build before the binary target and that will copy all 
	# depended on shared libraries to the targets output directory.
	cpfAddDeploySharedLibrariesTarget(${ARG_PACKAGE_NAME})

	# Adds target that runs clang-tidy on the given files.
    # Currently this is only added for the production target because clang-tidy does not filter out warnings that come over the GTest macros from external code.
    # When clang-tidy resolves the problem, static analysis should be executed for all binary targets.
    cpfAddStaticAnalysisTarget( BINARY_TARGET ${productionLibrary})
    cpfAddRunCppTestsTargets( ${ARG_PACKAGE_NAME})
	cpfAddDynamicAnalysisTarget(${ARG_PACKAGE_NAME})

	# Plugins must be added before the install targets
	cpfAddPlugins( ${ARG_PACKAGE_NAME} "${pluginOptionLists}" )
	 
	# Adds the install rules and the per package install targets.
	cpfAddInstallRulesAndTargets( ${ARG_PACKAGE_NAME} ${ARG_PACKAGE_NAMESPACE} )

	# Adds a target the creates abi-dumps when using clang or gcc with debug options.
	cpfAddAbiCheckerTargets( ${ARG_PACKAGE_NAME} "${distributionPackageOptionLists}" )
	
	# Adds the targets that create the distribution packages.
	cpfAddDistributionPackageTargets( ${ARG_PACKAGE_NAME} "${distributionPackageOptionLists}" "${pluginOptionLists}" )

	# A target to generate a .dox file that is used to add links to the packages build results to the package documentation.
	cpfAddPackageDocsTarget( packageLinkFile ${ARG_PACKAGE_NAME} ${ARG_PACKAGE_NAMESPACE} "${ARG_BRIEF_DESCRIPTION}" "${ARG_LONG_DESCRIPTION}")
	list(APPEND ARG_PRODUCTION_FILES ${packageLinkFile} )

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
			
			get_property( location TARGET ${target} PROPERTY LOCATION${configSuffix} )
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
					set_property( TARGET ${target} PROPERTY LOCATION${configSuffix} ${linkTarget})
					set_property( TARGET ${target} PROPERTY IMPORTED_LOCATION${configSuffix} ${linkTarget} )
					get_filename_component( locationShort ${location} NAME)
					set_property( TARGET ${target} PROPERTY IMPORTED_SONAME${configSuffix} ${locationShort} )
				else()
					message( FATAL_ERROR "The soname symlink \"${location}\" of imported target ${target} points to the not existing file \"${linkTarget}\"." )
				endif()
				
			endif()
			
		endif()
	
	endforeach()
endfunction()

#---------------------------------------------------------------------
#
function( cpfAddPackageBinaryTargets outProductionLibrary package packageNamespace type publicHeaderFiles productionFiles publicFixtureHeaderFiles fixtureFiles testFiles linkedLibraries linkedTestLibraries	)

	# filter some files
	foreach( file ${productionFiles})
		
		# main.cpp
		if( "${file}" MATCHES "^main.cpp$" OR "${file}" MATCHES "(.*)/main.cpp$")
			set(MAIN_CPP ${file})
		endif()

		# icon files (they must be added to the executable)
		if( "${file}" MATCHES "(.*)${package}[.]ico$" OR "${file}" MATCHES "(.*)${package}[.]rc$")
			list(APPEND iconFiles ${file})
		endif()

	endforeach()

	# add version header and cmake files to the production files
	cpfGetPackageVersionFileName( versionFile ${package} )
	list(APPEND productionFiles ${CMAKE_CURRENT_SOURCE_DIR}/${versionFile} )
	cpfGetPackageVersionCppHeaderFileName( versionHeader ${package} )
	list(APPEND productionFiles ${CMAKE_CURRENT_BINARY_DIR}/${versionHeader} )
	

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
		# use always static linkage for internal exe target libraries
		set(libLinkage STATIC)
	else()
		set(isExe FALSE)
		set(productionTarget ${package})

		# respect the clients BUILD_SHARED_LIBS setting when the main target is a library
		if(${BUILD_SHARED_LIBS})
			set(libLinkage SHARED)
		else()
			set(libLinkage STATIC)
		endif()

	endif()
	
	###################### Create production library target ##############################
    if(productionFiles OR publicHeaderFiles)  

        cpfAddBinaryTarget(
			PACKAGE_NAME ${package}  
			EXPORT_MACRO_PREFIX ${packageNamespace}
			TARGET_TYPE LIB
			LINKAGE ${libLinkage}
			NAME ${productionTarget}
			PUBLIC_HEADER ${publicHeaderFiles}
			FILES ${productionFiles}
			LINKED_LIBRARIES ${linkedLibraries}
			IDE_FOLDER ${package}
	    )

    endif()

	###################### Create exe target ##############################
	if(isExe)
		
		set( exeTarget ${package})
		cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			TARGET_TYPE ${type}
			NAME ${exeTarget}
			FILES ${MAIN_CPP} ${iconFiles}
			LINKED_LIBRARIES ${linkedLibraries} ${productionTarget}
			IDE_FOLDER ${package}/exe
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
			LINKAGE ${libLinkage}
			NAME ${fixtureTarget}
			PUBLIC_HEADER ${publicFixtureHeaderFiles}
			FILES ${fixtureFiles}
			LINKED_LIBRARIES ${productionTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
        )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF )
			set_property(TARGET ${fixtureTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()
		set_property(TARGET ${package} PROPERTY CPF_TEST_FIXTURE_SUBTARGET ${fixtureTarget} )
        
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
        )
		set_property(TARGET ${package} PROPERTY CPF_TESTS_SUBTARGET ${unitTestsTarget} )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF)
			set_property(TARGET ${unitTestsTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()

    endif()
    
	# Set some properties
    set_property(TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS ${exeTarget} ${fixtureTarget} ${productionTarget} ${unitTestsTarget} )
    set_property(TARGET ${package} PROPERTY CPF_PRODUCTION_LIB_SUBTARGET ${productionTarget} )
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
function( cpfAddBinaryTarget	)

	cmake_parse_arguments(
		ARG 
		"" 
		"PACKAGE_NAME;EXPORT_MACRO_PREFIX;TARGET_TYPE;NAME;LINKAGE;IDE_FOLDER" 
		"PUBLIC_HEADER;FILES;LINKED_LIBRARIES" 
		${ARGN} 
	)
	set( allSources ${ARG_PUBLIC_HEADER} ${ARG_FILES})

	cpfQt5AddUIAndQrcFiles( allSources )

    # Create Qt ui application
    if( ${ARG_TARGET_TYPE} STREQUAL GUI_APP)
        add_executable(${ARG_NAME} WIN32 ${allSources} )
    endif()

    # Create Qt console application
    if( ${ARG_TARGET_TYPE} MATCHES CONSOLE_APP)
        add_executable(${ARG_NAME} ${allSources} )
    endif()

    # library
    if( ${ARG_TARGET_TYPE} MATCHES LIB )
		
		add_library(${ARG_NAME} ${ARG_LINKAGE} ${allSources} )
		
		# make sure that clients have the /D <target>_IMPORTS compile option set.
		if( ${ARG_LINKAGE} STREQUAL SHARED AND MSVC)
			target_compile_definitions(${ARG_NAME} INTERFACE /D ${ARG_NAME}_IMPORTS )
		endif()
		
		# Remove the lib prefix on Linux. We expect that to be part of the package name.
		set_property(TARGET ${ARG_NAME} PROPERTY PREFIX "")

		# If a library does not have a public header, it must be a user mistake
		if(NOT ${ARG_PUBLIC_HEADER})
			message(FATAL_ERROR "Library package ${ARG_PACKAGE_NAME} has no public headers. The library can not be used without public headers, so please add the PUBLIC_HEADER argument to the cpfAddPackage() call.")
		endif()
    endif()

    # Set target properties
	# Set include directories, that all header are included with #include <package/myheader.h>
	# We do not use special directories for private or public headers. So the include directory is public.
	target_include_directories( ${ARG_NAME} PUBLIC 
		$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
		$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
		$<INSTALL_INTERFACE:..>
	)
	
	# Hardcode c++ standard to 14 for now.
	# This should be set by the user in the addPackage() method.
	set_property(TARGET ${ARG_NAME} PROPERTY CXX_STANDARD 14)

	# set the Visual Studio folder property
	set_property( TARGET ${ARG_NAME} PROPERTY FOLDER ${ARG_IDE_FOLDER})
	# public header
	set_property( TARGET ${ARG_NAME} PROPERTY CPF_PUBLIC_HEADER ${ARG_PUBLIC_HEADER})
	# Enable qt auto moc
	# Note that we AUTOUIC and AUTORCC is not used because I was not able to get the names of
	# the generated files at cmake time which is required when setting source groups and 
	# adding the generated ui_*.h header to the targets interface include directories.
	set_property( TARGET ${ARG_NAME} PROPERTY AUTOMOC ON)
	# Set the target version
	set_property( TARGET ${ARG_NAME} PROPERTY VERSION ${PROJECT_VERSION} )
	set_property( TARGET ${ARG_NAME} PROPERTY SOVERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR} )	# so version depends on the compatibility scheme, we currently have a hard-coded same-minor scheme.
	
	# sets all the <bla>_OUTPUT_DIRECTORY_<config> options
	cpfSetTargetOutputDirectoriesAndNames( ${ARG_PACKAGE_NAME} ${ARG_NAME})

    # link with other libraries
    target_link_libraries(${ARG_NAME} PUBLIC ${ARG_LINKED_LIBRARIES} )
    cpfRemoveWarningFlagsForSomeExternalFiles(${ARG_NAME})

	# Generate the header file with the dll export and import macros
	cpfGenerateExportMacroHeader(${ARG_NAME} "${ARG_EXPORT_MACRO_PREFIX}")

    # set target to use pre-compiled header
    # compile flags can not be changed after this call
    cpfAddPrecompiledHeader( ${ARG_NAME} )

	# sort files into folders in visual studio
    cpfSetIDEDirectoriesForTargetSources(${ARG_NAME})

endfunction()


#----------------------------------------- macro from Lars Christensen to use precompiled headers --------------------------------
# this was copied from https://gist.github.com/larsch/573926
# this might be an alternative if this does not work well enough: https://github.com/sakra/cotire
function(cpfAddPrecompiledHeader target )
    
    # add the precompiled header (targets and compile flags)
    set_target_properties(${target} PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)  # prevent the generation of unity build targets
    
	if(CPF_ENABLE_PRECOMPILED_HEADER) 
		cotire( ${target})
		cpfReAddInheritedCompileOptions( ${target})

		# add the prefix header to the target files
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
# Sorts the source files of the target into various folders for Visual Studio.
# 
# Remarks
# I failed to add the cotire prefix header to the generated files because
# it does not belong to the target.
# The ui_*.h files could also not be added to the generated files because they do not exist when the target is created.
function( cpfSetIDEDirectoriesForTargetSources targetName )

    # get source files
    get_target_property( allSourceFiles ${targetName} SOURCES)
	get_target_property( sourceDir ${targetName} SOURCE_DIR)
	get_target_property( binaryDir ${targetName} BINARY_DIR)

	# got through source files and sort them into various groups
	foreach( file ${allSourceFiles})
		
		
		get_source_file_property( fullName ${file} LOCATION )
		get_filename_component( dir ${fullName} DIRECTORY)

		cpfIsSubPath( isInSources "${dir}" "${sourceDir}") 
		if( isInSources )
			list(APPEND filesInSourceDir ${file})
		endif()

		cpfIsSubPath( isInBinary "${dir}" "${binaryDir}") 
		if( isInBinary )
			list(APPEND generatedFiles ${file})
		endif()

		if("${file}" MATCHES "^ui_(.*).h$")
			list(APPEND generatedFiles ${file} )
		elseif("${file}" MATCHES "^qrc_(.*).cpp$")
			list(APPEND generatedFiles ${file} )
		endif()

		get_filename_component( extension ${file} EXT)
		if( "${extension}" STREQUAL .cpp)
			list(APPEND codeFiles  ${file})
		elseif("${extension}" STREQUAL .h)
			list(APPEND codeFiles  ${file})
		endif()

	endforeach()

	list(APPEND generatedFiles ${CMAKE_CURRENT_BINARY_DIR}/${targetName}_autogen/moc_compilation.cpp) # this file is generated by automoc

	# set source groups for generated files that do exist
	source_group(Generated FILES ${generatedFiles})

	# set the file groups of the files in the Source directory to follow the directory structure
	source_group(TREE ${sourceDir} FILES ${filesInSourceDir})

	# add the source files without any folder
	source_group("" FILES ${codeFiles})

endfunction()

#---------------------------------------------------------------------------------------------
# Sets the <binary-type>_OUTOUT_DIRECTORY_<config> properties of the given target.
#
function( cpfSetTargetOutputDirectoriesAndNames package target )

	cpfGetConfigurations( configs)
	foreach(config ${configs})
		cpfSetAllOutputDirectoriesAndNames(${target} ${package} ${config} "${CMAKE_BINARY_DIR}/BuildStage/${config}" )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfSetAllOutputDirectoriesAndNames target package config outputPrefixDir  )

	cpfToConfigSuffix( configSuffix ${config})

	# Delete the <config>_postfix property and handle things manually in cpfSetOutputDirAndName()
	string(TOUPPER ${config} uConfig)
	set_property( TARGET ${target} PROPERTY ${uConfig}_POSTFIX "" )

	cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} RUNTIME)
	cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} LIBRARY)
	cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} ARCHIVE)

	cpfTargetHasPdbCompileOutput(hasOutput ${target} ${configSuffix})
	if(hasOutput)
		cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} COMPILE_PDB)
		set_property(TARGET ${target} PROPERTY COMPILE_PDB_NAME${configSuffix} ${target}${CMAKE${configSuffix}_POSTFIX}-compiler) # we overwrite the filename to make it more meaningful
	endif()

	cpfTargetHasPdbLinkerOutput(hasOutput ${target} ${configSuffix})
	if(hasOutput)
		cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} PDB)
		set_property(TARGET ${target} PROPERTY PDB_NAME${configSuffix} ${target}${CMAKE${configSuffix}_POSTFIX}-linker)  # we overwrite the filename to make it more meaningful
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
# This function sets the output name property to make sure that the same target file names are
# achieved across all platforms.
function( cpfSetOutputDirAndName target package config prefixDir outputType )

	cpfGetRelativeOutputDir( relativeDir ${package} ${outputType})
	cpfToConfigSuffix(configSuffix ${config})
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY${configSuffix} ${prefixDir}/${relativeDir})
	# use the config postfix for all target types
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME${configSuffix} ${target}${CMAKE_${uConfig}_POSTFIX} )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfTargetHasPdbCompileOutput hasPdbOutput target configSuffix )

	set( hasPdbFlag FALSE )
	if(MSVC)
		cpfSplitString( flagsList "${CMAKE_CXX_FLAGS${configSuffix}}" " ")
		cpfContainsOneOf( hasPdbFlag "${flagsList}" /Zi;/ZI )
	endif()
	set( ${hasPdbOutput} ${hasPdbFlag} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfTargetHasPdbLinkerOutput hasPdbOutput target configSuffix )

	cpfTargetHasPdbCompileOutput( hasPdbCompileOutput ${target} ${configSuffix})
	
	if( hasPdbCompileOutput )
		get_property( targetType TARGET ${target} PROPERTY TYPE)
		if(${targetType} STREQUAL SHARED_LIBRARY OR ${targetType} STREQUAL MODULE_LIBRARY OR ${targetType} STREQUAL EXECUTABLE)
			set(${hasPdbOutput} TRUE PARENT_SCOPE)
			return()
		endif()
	endif()

	set(${hasPdbOutput} FALSE PARENT_SCOPE)

endfunction()


#---------------------------------------------------------------------
# generate a header file that cpfContains the EXPORT macros
function( cpfGenerateExportMacroHeader target macroBaseName )

	get_property( targetType TARGET ${target} PROPERTY TYPE)
	if(NOT ${targetType} STREQUAL EXECUTABLE)
		string(TOLOWER ${macroBaseName} macroBaseNameLower ) # the generate_export_header() function will create a file with lower case name.
		generate_export_header( 
			${target}
			BASE_NAME ${macroBaseNameLower}
		)
		set(exportHeader "${CMAKE_CURRENT_BINARY_DIR}/${macroBaseNameLower}_export.h" )
		set_property(TARGET ${target} APPEND PROPERTY SOURCES ${exportHeader} )
		set_property(TARGET ${target} APPEND PROPERTY CPF_PUBLIC_HEADER ${exportHeader} )
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
			get_property(isImported TARGET ${plugin} PROPERTY IMPORTED)
			if(isImported)
				cpfAddDeployExternalSharedLibsToBuildStageTarget( ${package} ${plugin} ${subdirectory} )
			else()
				add_dependencies( ${target} ${plugin}) # adds the artifical dependency
				cpfAddDeployInternalSharedLibsToBuildStageTargets( ${package} ${plugin} ${subdirectory} ) 
			endif()
		endif()
	endforeach()

endfunction()


#---------------------------------------------------------------------------------------------
# This function can be used to add a custom target that does nothing and is only good for
# holding files in a Visual Studio solution.
function( cpfAddFilePackage packageName files)

	add_custom_target( ${packageName} SOURCES ${files} )
	set_property( TARGET ${packageName} PROPERTY FOLDER ${packageName} )

endfunction()
