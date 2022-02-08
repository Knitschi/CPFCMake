# This script is supposed to be run by the build server after a succsefull build.
# It adds a leightweight internal-version tag to mark a commit as a succesfull build,
# if the commit has no version tag yet.
#
# Arguments:
# ROOT_DIR						: The CPF root directory.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
include(cpfConstants)
include(cpfMiscUtilities)
include(cpfLocations)
include(cpfProjectUtilities)
include(cpfGitUtilities)


# check arguments
cpfAssertScriptArgumentDefined(ROOT_DIR)


################### SCRIPT ######################

# Get the directories of the individual owned repositories
cpfGetOwnedRepositoryDirectories( ownedRepoDirs "${ROOT_DIR}" )
foreach( repoDir ${ownedRepoDirs} )
	
	# Make sure our version tags are up to date
	cpfExecuteProcess( d "git fetch --tags" "${repoDir}")
	
	# Make sure we do not tag a repository with local changes
	cpfWorkingDirectoryIsDirty( isDirty "${repoDir}")
	if(isDirty)
		message(FATAL_ERROR "Error! Tagging failed. The repository \"${repoDir}\" is dirty.")
	endif()
	
	cpfHeadHasVersionTag( packageIsTagged ${repoDir})
	if(packageIsTagged) 
		message("-- The repository \"${repoDir}\" is already tagged. Skip tagging.")
		continue()
	else()
		cpfGetCurrentVersionFromGitRepository(newVersion ${repoDir})
		# Add the new Tag
		message("-- Set new internal version tag ${newVersion} for repository \"${repoDir}\".")
		cpfExecuteProcess( d "git tag ${newVersion}" "${repoDir}")
		# Push the tag
		cpfExecuteProcess( d "git push --tags origin" "${repoDir}")
	endif()

endforeach()

