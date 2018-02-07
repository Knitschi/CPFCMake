
# This script is supposed to be used by the build server to create a new branch <developer>-tmp-<mainbranch>
# by merging the <developer>-int-<mainbranch> and the <mainbranch>
#
# Arguments:
# DEVELOPER				The <developer> part of the developer integration branch with the naming convention <developer>-int-<mainbranch> 
#						to which individual developers push the changes they want to integrate in the <mainbranch>
# MAIN_BRANCH			A central branch that collects the changes made by multiple developers.
# ROOT_DIR		The directory in which the git commands are executed.

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfGitUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfProjectUtilities.cmake)

cpfAssertScriptArgumentDefined(DEVELOPER)
cpfAssertScriptArgumentDefined(MAIN_BRANCH)
cpfAssertScriptArgumentDefined(ROOT_DIR)

cpfGetIntegrationBrancheNames( devBranch tempBranch ${DEVELOPER} ${MAIN_BRANCH})

# Update the main branch
cpfExecuteProcess( dummy "git checkout ${MAIN_BRANCH}" "${ROOT_DIR}")
cpfExecuteProcess( dummy "git pull origin ${MAIN_BRANCH}" "${ROOT_DIR}")

# Create a clean tmp branch. 
# local cleanup
cpfHasLocalBranch( hasLocalTempBranch ${tempBranch} ${ROOT_DIR})
if(hasLocalTempBranch)
	message("-- Delete local branch ${tempBranch}.")
	cpfDeleteBranch( ${tempBranch} ${ROOT_DIR})
endif()
# remote cleanup
cpfRemoteHasBranch( hasTempBranch origin ${tempBranch} ${ROOT_DIR})
if(hasTempBranch)
	message("-- Delete remote branch ${tempBranch}.")
	cpfDeleteRemoteBranch( origin ${tempBranch} ${ROOT_DIR})
endif()
# create the branch from master
message("-- Create branch ${tempBranch} from branch ${MAIN_BRANCH}.")
cpfExecuteProcess( dummy "git checkout -b ${tempBranch}" "${ROOT_DIR}")

# merge in the changes from the developer branch
message("-- Merge branch ${devBranch} into branch ${tempBranch}.")
cpfExecuteProcess( dummy "git pull origin ${devBranch}" "${ROOT_DIR}")

# make the changes available on the central repository, so a developer can see what exactly was build
# for debugging purposes.
message("-- Push branch ${tempBranch} to the central repository.")
cpfExecuteProcess( dummy "git push --set-upstream origin ${tempBranch}" "${ROOT_DIR}")
