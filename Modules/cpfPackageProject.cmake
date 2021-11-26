

include_guard(GLOBAL)

include(cpfPathUtilities)
include(cpfMiscUtilities)



#-------------------------------------------------------------------------
# Documentation in APIDocs.dox
macro( cpfPackageProject )

	set(requiredSingleValueKeywords
		TARGET_NAMESPACE
	)

	set(optionalSingleValueKeywords
		BRIEF_DESCRIPTION
		LONG_DESCRIPTION
		WEBPAGE_URL
		OWNER
		MAINTAINER_EMAIL
		VERSION_COMPATIBILITY_SCHEME
	)

	set(requiredMultiValueKeywords
		COMPONENTS
	)

	set(optionalMultiValueKeywords
		LANGUAGES
		DISTRIBUTION_PACKAGES
		PACKAGE_FILES 
	)

	cmake_parse_arguments(ARG "" "${requiredSingleValueKeywords};${optionalSingleValueKeywords}" "${requiredMultiValueKeywords};${optionalMultiValueKeywords}" ${ARGN})

	cpfAssertKeywordArgumentsHaveValue("${requiredSingleValueKeywords};${requiredMultiValueKeywords}" ARG "cpfPackageProject()")
	if(NOT ARG_VERSION_COMPATIBILITY_SCHEME)
		set(ARG_VERSION_COMPATIBILITY_SCHEME ExactVersion)
	endif()
	cpfAssertCompatibilitySchemeOption(${ARG_VERSION_COMPATIBILITY_SCHEME})

	# Look for CXX and C by default.
	if(NOT ARG_LANGUAGES)
		set(languageOption LANGUAGES CXX C)
	else()
		set(languageOption LANGUAGES ${ARG_LANGUAGES})
	endif()

	# The package name is defined by the sub-directory name
    cpfGetCurrentSourceDir(package)

	cpfConfigurePackageVersionFile(${package})

	# get the version number of the packages version file
	cpfGetPackageVersionFromFile( packageVersion ${package} ${CMAKE_CURRENT_LIST_DIR})

	cpfSplitVersion( major minor patch commitId ${packageVersion})

	cpfPrintAddPackageStatusMessage(${package} ${packageVersion})

	# create a sub-project for the package
	project( 
		${package} 
		VERSION ${major}.${minor}.${patch}
		${languageOption}
    )
    
	set(CPF_CURRENT_PACKAGE ${package})
	set(${package}_TARGET_NAMESPACE ${ARG_TARGET_NAMESPACE})

	set(CPF_CURRENT_PACKAGE_VERSION_COMPATIBILITY_SCHEME ${ARG_VERSION_COMPATIBILITY_SCHEME})

	set(PROJECT_VERSION ${packageVersion})
	set(PROJECT_VERSION_MAJOR ${major})
	set(PROJECT_VERSION_MINOR ${minor})
	set(PROJECT_VERSION_PATCH ${patch})
	set(PROJECT_VERSION_TWEAK ${commitId})

	cpfGetPackageVersionFileName(versionFile ${package})

	set(packageSources
		${ARG_PACKAGE_FILES}
		CMakeLists.txt
		${versionFile}
	)

	set_property(DIRECTORY ${CMAKE_CURRENT_LIST_DIR} PROPERTY CPF_PACKAGE_COMPONENTS ${ARG_COMPONENTS})
	set_property(DIRECTORY ${CMAKE_CURRENT_LIST_DIR} PROPERTY CPF_PACKAGE_SOURCES ${packageSources})

	if(NOT ("${ARG_COMPONENTS}" STREQUAL "SINGLE_COMPONENT"))

		# For multi component packages we add an extra target that holds the package level files.
		add_custom_target(
			${package}
			SOURCES ${packageSources}
		)

		set_property(TARGET ${package} PROPERTY FOLDER ${package})

		foreach(component ${ARG_COMPONENTS})
			add_subdirectory(${component})
		endforeach()

		finalizePackageProject()

	endif()
	
endmacro()

#-----------------------------------------------------------
function( finalizePackageProject )

	set(package ${CPF_CURRENT_PACKAGE})

	cpfHasAtLeastOneBinaryComponent(hasBinaryComponent ${package})
	if(hasBinaryComponent) # Currently we can only export the binary targets. Do we need more?
		cpfGenerateAndInstallCMakeConfigFiles(${package} ${${package}_TARGET_NAMESPACE} ${CPF_CURRENT_PACKAGE_VERSION_COMPATIBILITY_SCHEME})
	endif()
	cpfAddPackageInstallTarget(${package})

endfunction()

#-----------------------------------------------------------
# Creates the cpfPackageVersion_<package>.cmake file in the Sources directory, by reading the version from git.
# The file is required to provide a version if the build is done with sources that are not checked out from git.
#
function( cpfConfigurePackageVersionFile package )

	# Get the paths of the created files.
	cpfGetPackageVersionFileName( cmakeVersionFile ${package})

	# Check if we work with a git repository.
	# If so, we retrieve the version from the repository.
	# If not, this must be an installed archive and the .cmake version file must already exist.
	cpfIsGitRepositoryDir( isRepoDirOut "${CMAKE_CURRENT_SOURCE_DIR}")
	if(isRepoDirOut)
	
		set(PACKAGE_NAME ${package})
		cpfGetCurrentVersionFromGitRepository( CPF_PACKAGE_VERSION "${CMAKE_CURRENT_SOURCE_DIR}")
		set( absPathCmakeVersionFile "${CMAKE_CURRENT_BINARY_DIR}/${cmakeVersionFile}")
		cpfConfigureFileWithVariables( "${CPF_ABS_TEMPLATE_DIR}/packageVersion.cmake.in" "${absPathCmakeVersionFile}" PACKAGE_NAME CPF_PACKAGE_VERSION )
	
	else()
		# Note that the version.cmake file is generated in the binary tree, but is moved
		# to the source tree when creating source packages.
		set( absPathCmakeVersionFile "${CMAKE_CURRENT_SOURCE_DIR}/${cmakeVersionFile}")
		if(NOT EXISTS "${absPathCmakeVersionFile}" )
			message(FATAL_ERROR "The package source directory \"${CMAKE_CURRENT_SOURCE_DIR}\" neither belongs to a git repository nor contains a .cmake version file.")
		endif()
	endif()

endfunction()

#-----------------------------------------------------------
function( cpfConfigurePackageVersionHeader package version packageNamespace)

	set( PACKAGE_NAME ${package})
	set( PACKAGE_NAMESPACE ${packageNamespace})
	set( CPF_PACKAGE_VERSION ${version} )

	cpfGetPackageComponentVersionCppHeaderFileName( versionHeaderFile ${package})
	set( absPathVersionHeader "${CMAKE_CURRENT_BINARY_DIR}/${versionHeaderFile}")

	cpfConfigureFileWithVariables( "${CPF_ABS_TEMPLATE_DIR}/packageVersion.h.in" "${absPathVersionHeader}" PACKAGE_NAME CPF_PACKAGE_VERSION PACKAGE_NAMESPACE ) 

endfunction()