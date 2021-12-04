

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
		PACKAGE_ARCHIVES
		PACKAGE_FILES
	)

	cmake_parse_arguments(ARG "" "${requiredSingleValueKeywords};${optionalSingleValueKeywords}" "${requiredMultiValueKeywords};${optionalMultiValueKeywords}" ${ARGN})

	cpfAssertKeywordArgumentsHaveValue("${requiredSingleValueKeywords};${requiredMultiValueKeywords}" ARG "cpfPackageProject()")
	if(NOT ("${ARG_VERSION_COMPATIBILITY_SCHEME}" STREQUAL ""))
		message(WARNING "Function ${CMAKE_CURRENT_FUNCTION}() currently ignores the VERSION_COMPATIBILITY_SCHEME argument and uses \"ExactVersion\" by default.")
	endif()
	set(ARG_VERSION_COMPATIBILITY_SCHEME ExactVersion)
	cpfAssertCompatibilitySchemeOption(${ARG_VERSION_COMPATIBILITY_SCHEME})

	# Look for CXX and C by default.
	if(NOT ARG_LANGUAGES)
		set(languageOption LANGUAGES CXX C)
	else()
		set(languageOption LANGUAGES ${ARG_LANGUAGES})
	endif()

	# parse argument sublists
	set(allKeywords ${requiredSingleValueKeywords} ${optionalSingleValueKeywords} ${requiredMultiValueKeywords} ${optionalMultiValueKeywords})
	cpfGetKeywordValueLists(distributionPackageOptionLists PACKAGE_ARCHIVES "${allKeywords}" "${ARGN}" packagOptions)

	# The package name is defined by the sub-directory name
    cpfGetCurrentSourceDir(package)

	# Find dependet on packages
	cpfFindPackageDependencies(${package})

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
	set(${package}_DISTRIBUTION_PACKAGE_OPTION_LISTS ${distributionPackageOptionLists})
	set(${package}_BRIEF_DESCRIPTION ${ARG_BRIEF_DESCRIPTION})
	set(${package}_LONG_DESCRIPTION ${ARG_LONG_DESCRIPTION})
	set(${package}_WEBPAGE_URL ${ARG_WEBPAGE_URL})
	set(${package}_OWNER ${ARG_OWNER})
	set(${package}_MAINTAINER_EMAIL ${ARG_MAINTAINER_EMAIL})
	set(${package}_VERSION_COMPATIBILITY_SCHEME ${ARG_VERSION_COMPATIBILITY_SCHEME})

	set(PROJECT_VERSION ${packageVersion})
	set(PROJECT_VERSION_MAJOR ${major})
	set(PROJECT_VERSION_MINOR ${minor})
	set(PROJECT_VERSION_PATCH ${patch})
	set(PROJECT_VERSION_TWEAK ${commitId})

	cpfGetPackageVersionFileName(versionFile ${package})
	cpfGetFullPackageDependenciesFilePathIfItExists(dependenciesFile ${package})
	set(packageSources
		${ARG_PACKAGE_FILES}
		CMakeLists.txt
		${versionFile}
		#${dependenciesFile}
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

		cpfFinalizePackageProject()

	endif()
	
endmacro()

#-----------------------------------------------------------
function( cpfFinalizePackageProject )

	set(package ${CPF_CURRENT_PACKAGE})

	cpfHasAtLeastOneBinaryComponent(hasBinaryComponent ${package})
	if(hasBinaryComponent) # Currently we can only export the binary targets. Do we need more?
		cpfGenerateAndInstallCMakeConfigFiles(${package} ${${package}_TARGET_NAMESPACE} ${${package}_VERSION_COMPATIBILITY_SCHEME})
	endif()

	# Adds the targets that create the package archives.
	set(distributionPackageOptionLists ${${package}_DISTRIBUTION_PACKAGE_OPTION_LISTS})
	if(distributionPackageOptionLists)
		cpfAddPackageArchiveTargets(${package} "${distributionPackageOptionLists}")
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

#-----------------------------------------------------------
function( cpfGetFullPackageDependenciesFilePathIfItExists pathOut package)
	
	cpfGetFullPackageDependenciesFilePath(dependenciesFile ${package})
	if(EXISTS ${dependenciesFile})
		set(${pathOut} "${dependenciesFile}" PARENT_SCOPE)
	else()
		set(${pathOut} "" PARENT_SCOPE)
	endif()

endfunction()

#-----------------------------------------------------------
function( cpfFindPackageDependencies package)

	cpfGetFullPackageDependenciesFilePathIfItExists(dependenciesFile ${package})
	if(${dependenciesFile})
		cpfReadVariablesFromFile(variables values ${dependenciesFile})

		cpfContains(hasRequirements "${variables}" "CPF_PACKAGE_DEPENDENCIES")
		if(NOT hasRequirements)
			message(FATAL_ERROR "File \"${dependenciesFile}\" does not contain the required definition of the CPF_PACKAGE_DEPENDENCIES variable.\nThe file should at least contain an empty definition in the form of\nset(CPF_PACKAGE_DEPENDENCIES)")
		endif()

		list(FIND variables CPF_PACKAGE_DEPENDENCIES index)
		list(GET values ${index} allDependencyRequirements)

		cpfGetKeywordValueLists(dependencyRequirementLists CPF_PACKAGE "" "${allDependencyRequirements}" findPackageArguments)
		foreach(requirementList ${dependencyRequirementLists})
			find_package(${${requirementList}})
		endforeach()
	endif()

endfunction()

#-----------------------------------------------------------
