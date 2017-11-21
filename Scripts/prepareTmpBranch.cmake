
# This script is supposed to be used by the build server to create a new branch <developer>-tmp-<mainbranch>
# by merging the <developer>-int-<mainbranch> and the <mainbranch>
#
# Arguments:
# DEVELOPER				The <developer> part of the developer integration branch with the naming convention <developer>-int-<mainbranch> 
#						to which individual developers push the changes they want to integrate in the <mainbranch>
# MAIN_BRANCH			A central branch that collects the changes made by multiple developers.
# ROOT_DIR		The directory in which the git commands are executed.

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbGitUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbProjectUtilities.cmake)

ccbAssertScriptArgumentDefined(DEVELOPER)
ccbAssertScriptArgumentDefined(MAIN_BRANCH)
ccbAssertScriptArgumentDefined(ROOT_DIR)

ccbGetIntegrationBrancheNames( devBranch tempBranch ${DEVELOPER} ${MAIN_BRANCH})

# Update the main branch
ccbExecuteProcess( dummy "git checkout ${MAIN_BRANCH}" "${ROOT_DIR}")
ccbExecuteProcess( dummy "git pull origin ${MAIN_BRANCH}" "${ROOT_DIR}")

# Create a clean tmp branch. 
# local cleanup
ccbHasLocalBranch( hasLocalTempBranch ${tempBranch} ${ROOT_DIR})
if(hasLocalTempBranch)
	message("-- Delete local branch ${tempBranch}.")
	ccbDeleteBranch( ${tempBranch} ${ROOT_DIR})
endif()
# remote cleanup
ccbRemoteHasBranch( hasTempBranch origin ${tempBranch} ${ROOT_DIR})
if(hasTempBranch)
	message("-- Delete remote branch ${tempBranch}.")
	ccbDeleteRemoteBranch( origin ${tempBranch} ${ROOT_DIR})
endif()
# create the branch from master
message("-- Create branch ${tempBranch} from branch ${MAIN_BRANCH}.")
ccbExecuteProcess( dummy "git checkout -b ${tempBranch}" "${ROOT_DIR}")

# merge in the changes from the developer branch
message("-- Merge branch ${devBranch} into branch ${tempBranch}.")
ccbExecuteProcess( dummy "git pull origin ${devBranch}" "${ROOT_DIR}")

# make the changes available on the central repository, so a developer can see what exactly was build
# for debugging purposes.
message("-- Push branch ${tempBranch} to the central repository.")
ccbExecuteProcess( dummy "git push --set-upstream origin ${tempBranch}" "${ROOT_DIR}")
