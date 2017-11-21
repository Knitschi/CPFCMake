
# This script is supposed to be run by the build server after a <developer>-tmp-<mainbranch> branch was successfully built.
# It merges the temp-branch into the main branch and tags the main-branch with the version from the package version file.
#
# Arguments:
# DEVELOPER		: The <developer> part in the developer branch name <developer>-int-<mainbranch> which is currently integrated in the main branch.
# MAIN_BRANCH	: The <mainbranch> part in the developer branch name <developer>-int-<mainbranch> which is currently integrated in the main branch.
# ROOT_DIR		: The root directory of the CppCodeBase

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbProjectUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbGitUtilities.cmake)

ccbAssertScriptArgumentDefined(DEVELOPER)
ccbAssertScriptArgumentDefined(MAIN_BRANCH)
ccbAssertScriptArgumentDefined(ROOT_DIR)

################### Functions ######################
function( assertThatAllPackagesBelongToTheSameRepository packages rootDir )

	set(originUrls)
	set(packageVersions)
	foreach( package ${packages})
	
		ccbGetAbsPackageDirectory( packageDir ${package} "${rootDir}")

		ccbGetUrlOfOrigin( packageOriginUrl "${packageDir}")
		list(APPEND originUrls "${packageOriginUrl}" )
		list(REMOVE_DUPLICATES originUrls)
		list(LENGTH originUrls length)
		if( NOT ${length} EQUAL 1)
			message(FATAL_ERROR "Script mergeTempBranchToMainBranchAndTag.cmake currently only handles the case that all packages come from one repository. Abort merge to main-branch." )
		endif()

	endforeach()

endfunction()

function( assertMergeWillBeFastForward tmpBranch mainBranch repoDir)
	# Check that the master can still be fast forwarded to the temp branches head.
	# This may not be the case if somehow a commit was added to the master while the build-job was running.
	# This should normally not be the case because the build-job should be the only one pushing to master.
	ccbMergeWillBeFastForward( isFastForward ${tmpBranch} ${mainBranch} "${repoDir}")
	if( NOT isFastForward)
		message(FATAL_ERROR "It seems there was an external commit to branch ${mainBranch} while the integration process for branch ${tmpBranch} was running. This corrupts the version number, so the integration was aborted.")
	endif()
endfunction()



################### SCRIPT ######################

ccbGetIntegrationBrancheNames( devBranch tempBranch ${DEVELOPER} ${MAIN_BRANCH})

# checkout developer branch to make sure we have it here
ccbExecuteProcess( d "git checkout ${devBranch}" "${ROOT_DIR}")

# update the main-branch so we can find out if somebody messed around with it while the build ran.
message("-- Update ${MAIN_BRANCH}")
ccbExecuteProcess( d "git checkout ${MAIN_BRANCH}" "${ROOT_DIR}")
ccbExecuteProcess( d "git pull origin ${MAIN_BRANCH}" "${ROOT_DIR}")

# Move to the branch that contains the changes and do some checks on the new version number
message("-- Sanity checks for the new version number.")
ccbExecuteProcess( d "git checkout ${tempBranch}" "${ROOT_DIR}")
ccbExecuteProcess( d "git pull origin ${tempBranch}" "${ROOT_DIR}")

# VERSION NUMBER SANITY CHECKS
ccbGetSourcesSubdirectories( packages "${ROOT_DIR}" )

# For now the merge commands in this script assume that we only deal with one
# repository. This assertion makes sure that this is still the case.
assertThatAllPackagesBelongToTheSameRepository( "${packages}" "${ROOT_DIR}")
set(repoDir "${ROOT_DIR}")

# Make sure the temp-branch is still up-to-date
# Usually the build job will serialize the commits to the main-branch.
# If somebody does an direct commit to the main branch while the build-job is running,
# the version that was just build is out-dated and the later push will fail.
# We abort here before adding a tag in this case.
assertMergeWillBeFastForward( ${tempBranch} ${MAIN_BRANCH} "${repoDir}")

# DO THE MERGING
message("-- Merge branch ${tempBranch} into ${MAIN_BRANCH}.")
# Merge the branches, set a new version tag and update origin
ccbExecuteProcess( d "git checkout ${MAIN_BRANCH}" "${repoDir}")
ccbExecuteProcess( d "git merge ${tempBranch}" "${repoDir}")

# Add a new Tag
ccbGetCurrentVersionFromGitRepository( version "${repoDir}")
ccbGitRepoHasTag( alreadyHasBuildVersion ${version} "" "${repoDir}")
if(alreadyHasBuildVersion)
	message("-- The version tag ${version} in branch ${tempBranch} already exists. Skip tagging.")
else()
	message("-- Set new version tag ${version}.")
	ccbExecuteProcess( d "git tag ${version}" "${repoDir}")
endif()

# Push the commit and tag
ccbExecuteProcess( d "git push origin ${MAIN_BRANCH}" "${repoDir}")
ccbExecuteProcess( d "git push --tags origin ${MAIN_BRANCH}" "${repoDir}")

