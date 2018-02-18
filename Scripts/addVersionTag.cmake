# This script is supposed to be run by the build server after a succsefull build.
# It adds a leightweight tag with the current version to mark a commit as a succesfull build.
#
# Arguments:
# ROOT_DIR						: The CPF root directory.
# INCREMENT_VERSION_OPTION		: Can be internal, incrementPatch, incrementMinor, incrementMayor
# PACKAGE						: This option is used when setting a release version. It must be set to
#								  The name of a package or to an empty string when incrementing the host-project version. 

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfProjectUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfGitUtilities.cmake)


# check arguments
cpfAssertScriptArgumentDefined(ROOT_DIR)
cpfAssertScriptArgumentDefined(INCREMENT_VERSION_OPTION)
cpfAssertScriptArgumentDefined(PACKAGE)

cpfContains(isAllowedValue "internal;incrementPatch;incrementMinor;incrementMayor" ${INCREMENT_VERSION_OPTION})
if(NOT isAllowedValue)
	message("Invalid value \"${INCREMENT_VERSION_OPTION}\" for script argument INCREMENT_VERSION_OPTION.")
endif()


################### SCRIPT ######################

# Get the directories of the individual owned repositories
cpfGetOwnedRepositoryDirectories( ownedRepoDirs "${ROOT_DIR}" )
foreach( repoDir ${ownedRepoDirs} )
	
	cpfGetCurrentVersionFromGitRepository( versionHead "${repoDir}")
	cpfGetTagsOfHEAD( tagsAtHead "${repoDir}")
	cpfContains(headIsAlreadyTagged "${tagsAtHead}" ${versionHead})

	# Make sure we do not tag a repository with local changes
	cpfWorkingDirectoryIsDirty( isDirty "${repoDir}")
	if(isDirty)
		message(FATAL_ERROR "Error! Tagging failed. The repository \"${repoDir}\" is dirty.")
	endif()
	
	cpfRepoDirBelongsToPackage( isPackageRepoDir "${repoDir}" "${PACKAGE}" "${ROOT_DIR}")
	if(NOT (${INCREMENT_VERSION_OPTION} STREQUAL internal ) AND isPackageRepoDir ) # Handle tagging a release version for a selected package
		
		# Get the new release version.
		cpfSplitVersion( major minor patch commitId ${versionHead})
		if( "${INCREMENT_VERSION_OPTION}" STREQUAL incrementMajor )
			cpfIncrement(major)
			set(minor 0)
			set(patch 0)
		elseif("${INCREMENT_VERSION_OPTION}" STREQUAL incrementMinor)
			cpfIncrement(minor)
			set(patch 0)
		elseif("${INCREMENT_VERSION_OPTION}" STREQUAL incrementPatch)
			cpfIncrement(patch)
		else()
			message( FATAL_ERROR "Error! Unrecognized value \"${DIGIT_OPTION}\" for parameter \"DIGIT_OPTION\"")
		endif()
		set( newVersion ${major}.${minor}.${patch} )

		# Make sure this version does not yet exist
		cpfGetReleaseVersionTags( releaseVersions "${repoDir}")
		cpfContains(alreadyExists "${releaseVersions}" ${newVersion})
		if(alreadyExists)
			message(FATAL_ERROR "Error! Incrementing the version number failed. A release with version ${newVersion} already exists.")
		endif()

		# Make sure that we do not overwrite a release tag.
		cpfIsReleaseVersion( isRelease ${versionHead})
		if(isRelease)
			message(FATAL_ERROR "Error! The current commit is already at release version ${lastVersionTag}. Overwriting existing releases is not allowed.")
		endif()

		# Delete possibly existing internal version tags at this commit.
		if(headIsAlreadyTagged)
			cpfExecuteProcess( d "git tag -d ${versionHead}" "${repoDir}")
			cpfExecuteProcess( d "git push origin :refs/tags/${versionHead}" "${repoDir}")
		endif()

	else() # Set an internal version
		
		if(headIsAlreadyTagged)
			message("-- The repository \"${repoDir}\" is already tagged. Skip tagging.")
			continue()
		endif()
		set(newVersion ${versionHead})

	endif()

	# Add the new Tag
	message("-- Set new version tag ${newVersion} for repository \"${repoDir}\".")
	cpfExecuteProcess( d "git tag ${newVersion}" "${repoDir}")

	# Push the tag
	cpfExecuteProcess( d "git push --tags origin" "${repoDir}")

endforeach()

