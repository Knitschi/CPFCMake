

# This script is supposed to be used by the build server to update the version<package>.cmake files
# of all packages in a CppCodeBase.
#
# The script will read the latest version tag from git and increase the version number
# depending on the number of commits that have been made since that version.
#
# Arguments
# ROOT_DIR		The absolute path to the root directory of the CppCodeBase. It is the one that contains the Sources directory.
# MAIN_BRANCH	The branch that contains the last version tag that is relevant for the next version.

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbGitUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbProjectUtilities.cmake)
set(DIR_OF_THIS_FILE ${CMAKE_CURRENT_LIST_DIR})

# check arguments where set
ccbAssertScriptArgumentDefined(ROOT_DIR)
ccbAssertScriptArgumentDefined(MAIN_BRANCH)

# for now assume this is executed on a Linux machine. Currently this also works on Windows.
set(CMAKE_HOST_SYSTEM_NAME Linux)

# Get the available packages
ccbGetCppCodeBasePackages( packages "${ROOT_DIR}" )
foreach( PACKAGE_NAME ${packages})

	# Get the version from the most recent version tag on the main branch.
	ccbGetLastVersionTagOfBranch( lastTagVersion ${MAIN_BRANCH} "${ROOT_DIR}" TRUE)

	# Create the new version.
	ccbGetNumberOfCommitsSinceTag( nrCommitsSinceTag ${lastTagVersion} "${repoDir}")
	ccbSplitVersion( majorVersion minorVersion patchVersion commitsNr ${lastTagVersion})
	# Why +1 ?
	# After the current commit we add one commit with the source changes to make the tmp branch available for debugging.
	# When the build passes, we make a merge commit into the master. This however will only be a fast-forward, because only
	# the build job is allowed to make pushes to the master, so master-HEAD will stay a direct ancestor of the tmpbranch-HEAD.
	# So the merge commit is the one that will be tagged and for which the version number must be correct.
	math(EXPR newCommitsNr "${nrCommitsSinceTag} + ${commitsNr} + 1")
	set(CCB_PACKAGE_VERSION ${majorVersion}.${minorVersion}.${patchVersion}.${newCommitsNr} )

	# Write the new version to the version file.
	message("Update version file for package ${PACKAGE_NAME} to version ${CPPCODEBASE_PACKAGE_VERSION}")
	ccbGetAbsPathOfPackageVersionFile( packageVersionFile ${PACKAGE_NAME} "${ROOT_DIR}")
	ccbConfigureFileWithVariables( "${CMAKE_CURRENT_LIST_DIR}/../Templates/packageVersion.cmake.in" "${packageVersionFile}" PACKAGE_NAME )

endforeach()

