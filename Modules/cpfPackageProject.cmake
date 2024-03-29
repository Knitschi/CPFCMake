

include_guard(GLOBAL)

include(cpfPathUtilities)
include(cpfMiscUtilities)
include(cpfAddClangTidyTarget)
include(cpfAddClangFormatTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddOpenCppCoverageTarget)
include(cpfAddRunTestsTarget)
include(cpfAddValgrindTarget)

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
    cpfGetLastNodeOfCurrentSourceDir(package)

	# Read the per package global cmake variables.
	cpfSetPerPackageGlobalCMakeVariables(${package})

	# Find dependet on packages
	set(${package}_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
	cpfFindPackageDependencies(${package})

	cpfConfigurePackageVersionFile(${package})

	# get the version number of the packages version file
	cpfGetPackageVersionFromFileInSourcOrBuildTree( packageVersion ${package} ${CMAKE_CURRENT_LIST_DIR})

	cpfSplitVersion( major minor patch commitId ${packageVersion})

	cpfPrintAddPackageStatusMessage(${package} ${packageVersion})

	# create a sub-project for the package
	project( 
		${package} 
		VERSION ${major}.${minor}.${patch}
		${languageOption}
    )

	set(CPF_CURRENT_PACKAGE ${package})
	set(${package}_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})
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

	getExistingPackageVersionFile(absVersionFile ${package})
	cpfGetFullPackageDependenciesFilePathIfItExists(dependenciesFile ${package})
	set(packageSources
		${ARG_PACKAGE_FILES}
		CMakeLists.txt
		${absVersionFile}
		${dependenciesFile}
	)

	set_property(DIRECTORY ${CMAKE_CURRENT_LIST_DIR} PROPERTY CPF_PACKAGE_COMPONENTS ${ARG_COMPONENTS})
	set_property(DIRECTORY ${CMAKE_CURRENT_LIST_DIR} PROPERTY CPF_PACKAGE_SOURCES ${packageSources})

	if(NOT ("${ARG_COMPONENTS}" STREQUAL "SINGLE_COMPONENT"))


		# For multi component packages we add an extra target that holds the package level files.
		set(targetName ${package})
		# Check if there is a package component with the same name.
		cpfContains(hasComponentWithPackageName "${ARG_COMPONENTS}" ${package})
		if(hasComponentWithPackageName)
			set(targetName ${package}Package)
		endif()

		add_custom_target(
			${targetName}
			SOURCES ${packageSources}
		)

		set_property(TARGET ${targetName} PROPERTY FOLDER ${package}/package)
		set_property(TARGET ${targetName} APPEND PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS sources )

		cpfAddInstallRulesForPackageFiles(${package} ${targetName} "${packageSources}")

		foreach(component ${ARG_COMPONENTS})
			add_subdirectory(${component})
		endforeach()

		cpfFinalizePackageProject()

	endif()
	
endmacro()

#-----------------------------------------------------------
function( cpfFinalizePackageProject )

	set(package ${CPF_CURRENT_PACKAGE})

	# Set package properties for values that are needed outside the package directory.
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_PACKAGE_VERSION_COMPATIBILITY_SCHEME ${${package}_VERSION_COMPATIBILITY_SCHEME})
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_VERSION ${PROJECT_VERSION})

	cpfHasAtLeastOneBinaryComponent(hasBinaryComponent ${package})
	if(hasBinaryComponent) # Currently we can only export the binary targets. Do we need more?
		cpfGenerateAndInstallCMakeConfigFiles(${package} ${${package}_TARGET_NAMESPACE} ${${package}_VERSION_COMPATIBILITY_SCHEME})
	endif()

	# Adds the targets that create the package archives.
	set(distributionPackageOptionLists ${${package}_DISTRIBUTION_PACKAGE_OPTION_LISTS})
	if(distributionPackageOptionLists)
		cpfAddPackageArchiveTargets(${package} "${distributionPackageOptionLists}")
	endif()

	cpfAddPackageBundleTargets(${package})

endfunction()

#-----------------------------------------------------------
function( cpfAddInstallRulesForPackageFiles package packageTarget packageFiles )

	# Assume that package files are only relevenat for building the project.
	cpfInstallSourceFiles( relFiles ${package} "${packageFiles}" SOURCE sources "" )

endfunction( )

#-----------------------------------------------------------
function(cpfAddPackageBundleTargets package)

	# Add per package bundle targets.
	add_custom_target(pipeline_${package})
	set_property(TARGET pipeline_${package} PROPERTY FOLDER ${package}/package )
	add_dependencies(pipeline_${package} ${package})

	cpfGetPackageComponents(components ${package})
	cpfGetSubtargets(binaryTargets "${components}" INTERFACE_CPF_BINARY_SUBTARGETS)
	if(binaryTargets)
		add_dependencies(pipeline_${package} ${binaryTargets})
	endif()

	cpfGetPackageArchivesTargetName(archiveTarget ${package})
	if(TARGET ${archiveTarget})
		add_dependencies(pipeline_${package} ${archiveTarget})
	endif()

	cpfAddPackageInstallTarget(${package})
	cpfAddPackageClangFormatTarget(${package})
	cpfAddPackageClangTidyTarget(${package})
	cpfAddPackageRunAllTestsTarget(${package})
	cpfAddPackageValgrindTarget(${package})
	cpfAddPackageOpenCppCoverageTarget(${package})
	cpfAddPackageAbiCheckerTarget(${package})

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
function( cpfConfigurePackageComponentVersionHeader packageComponent version packageComponentNamespace)

	set( PACKAGE_NAME ${packageComponent})
	set( PACKAGE_NAMESPACE ${packageComponentNamespace})
	set( CPF_PACKAGE_VERSION ${version} )

	cpfGetPackageComponentVersionCppHeaderFileName( versionHeaderFile ${packageComponent})
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
	if(NOT ("${dependenciesFile}" STREQUAL ""))
		cpfReadVariablesFromFile(variables values ${dependenciesFile})
		
		cpfContains(hasRequirements "${variables}" "CPF_PACKAGE_DEPENDENCIES")
		if(NOT hasRequirements)
			message(FATAL_ERROR "File \"${dependenciesFile}\" does not contain the required definition of the CPF_PACKAGE_DEPENDENCIES variable.\nIf provided, the file should at least contain one definition for a dependency in the form of set(CPF_PACKAGE_DEPENDENCIES CPF_PACKAGE <depended-on-package> <version>)")
		endif()

		list(FIND variables CPF_PACKAGE_DEPENDENCIES index)
		list(GET values ${index} allDependencyRequirements)

		# Lists for collecting error information.
		set(failedRequiredPackages)
		set(failedRequiredVersions)
		set(failedAvailableVersions)
		set(failedCompatibilitySchemes)

		cpfGetKeywordValueLists(dependencyRequirementLists CPF_PACKAGE "" "${allDependencyRequirements}" findPackageArguments)
		foreach(requirementList ${dependencyRequirementLists})

			# Check that at least the package name and version exists in the list.
			cpfListLength(length "${${requirementList}}")
			if(${length} LESS 2)
				message(FATAL_ERROR "The package dependency definition in file \"${dependenciesFile}\" following the CPF_PACKAGE keyword must at least contain a package name and version number.")
			endif()

			list(GET ${requirementList} 0 requiredPackage)
			list(GET ${requirementList} 1 requiredVersion)

			# Check if we have a version range. This is currently not supported.
			if(TARGET ${requiredPackage})
				# Ignore the target if it was already imported 
				get_property(isImported TARGET ${requiredPackage} PROPERTY IMPORTED)
				if(NOT isImported)

					get_property(compatibilityScheme TARGET ${requiredPackage} PROPERTY INTERFACE_CPF_PACKAGE_VERSION_COMPATIBILITY_SCHEME)
					# We are dealing with an inlined package.
					# In this case we need to check the version requirements on our own.
					if(compatibilityScheme)
						get_property(availableVersion TARGET ${requiredPackage} PROPERTY INTERFACE_CPF_VERSION)
						cpfVersionIsCompatibleToRequirement(isCompatible ${availableVersion} ${requiredVersion} ${compatibilityScheme} TRUE)
						if(NOT isCompatible)
							cpfListAppend(failedRequiredPackages ${requiredPackage})
							cpfListAppend(failedRequiredVersions ${requiredVersion})
							cpfListAppend(failedAvailableVersions ${availableVersion})
							cpfListAppend(failedCompatibilitySchemes ${compatibilityScheme})
						endif()
					else()
						message(FATAL_ERROR "The required dependency ${requiredPackage} is an inlined package that was not created with the cpfPackageProject() function. This is not supported.")
					endif()

				else()
					# We are dealing with a package that has been imported by a different package in the project.
					message(FATAL_ERROR "Case not yet handled. TODO test if this can be triggered.")
				endif()

			else()
				# Try to import the required package if it is not availabe as inlined package.
				cpfDebugMessage("Call find_package() with arguments \"${${requirementList}}\"")
				find_package(${${requirementList}})
			endif()

		endforeach()

		# Print error message for all missing package requirements.
		if(failedRequiredPackages)

			set(errorMessage "\n\tPackage ${package} has unsatisfied dependency requirements of inlined packages!\n\n")

			list(PREPEND failedRequiredPackages "Required Package")
			list(PREPEND failedAvailableVersions "Available Version")
			list(PREPEND failedRequiredVersions "Required Version")
			list(PREPEND failedCompatibilitySchemes "Compatibility Scheme")

			cpfToTableString(requirementFailsTable COLUMN_VARIABLES failedRequiredPackages failedAvailableVersions failedRequiredVersions failedCompatibilitySchemes)
			string(APPEND errorMessage "${requirementFailsTable}")

			message(NOTICE "${errorMessage}")
			message(FATAL_ERROR "")

		endif()

	endif()

endfunction()

#-----------------------------------------------------------
