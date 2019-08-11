
# This script can be used by the build-server to merge existing html content with the
# one that was generated by the last build. The Accumulated content will be in the
# EXISTING_HTML_DIR
#
# Arguments:
# CMAKE_INSTALL_PREFIX							- The absolute path to the directory that was used as the install prefix for the build.
# MASTER_BUILD_RESULTS_REPOSITORY_DIR			- The absolute path to the directory to which the master build result repository was cloned.
# WEB_SERVER_BUILD_RESULTS_REPOSITORY			- The address of the remote repository on the web-server.
# BUILD_RESULTS_REPOSITORY_PROJECT_SUBDIR		- The relative path to the subdirectory in the results repository that is used for the handled project.
# ROOT_DIR: 									- The root directory of a CPF project.


include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
include(cpfMiscUtilities)
include(cpfLocations)
include(cpfProjectUtilities)
include(cpfGitUtilities)

cpfAssertScriptArgumentDefined(CMAKE_INSTALL_PREFIX)
cpfAssertScriptArgumentDefined(MASTER_BUILD_RESULTS_REPOSITORY_DIR)
cpfAssertScriptArgumentDefined(WEB_SERVER_BUILD_RESULTS_REPOSITORY)
cpfAssertScriptArgumentDefined(BUILD_RESULTS_REPOSITORY_PROJECT_SUBDIR)
cpfAssertScriptArgumentDefined(ROOT_DIR)

# Locations
set(projectDir ${MASTER_BUILD_RESULTS_REPOSITORY_DIR}/${BUILD_RESULTS_REPOSITORY_PROJECT_SUBDIR})
file(TO_CMAKE_PATH ${projectDir} projectDir)
set(lastBuildDir ${projectDir}/LastBuild )

# Make sure the result repository is on the master branch.
# On the buildserver a checkout with the GitPlugin puts the repository into detached head state.
cpfGitCheckout(master ${projectDir})
cpfGitPullRebase(origin master ${projectDir})

# Remove the results from the last build.
if(EXISTS ${lastBuildDir})
	cpfGitRemove(LastBuild ${projectDir})
endif()

# Copy to the results to the LastBuild directory
file(MAKE_DIRECTORY ${lastBuildDir})
file(COPY ${CMAKE_INSTALL_PREFIX}/ DESTINATION ${lastBuildDir} PATTERN *)

# Also copy the results to a permanent version subdirectory if it is a release.
# The repo can be in detached-head state on the build-server.
# In this case we need to specify the commit hash when getting the version tags.
cpfGetCheckedOutCommit( commitId "${ROOT_DIR}")	
cpfGetLastVersionTagOfBranch( version ${commitId} "${ROOT_DIR}" True)
cpfIsReleaseVersion(isRelease ${version})
if(isRelease)
	# Copy to version subdirectory.
	set(versionDir ${projectDir}/${version})
	file(MAKE_DIRECTORY ${versionDir})
	file(COPY ${CMAKE_INSTALL_PREFIX}/ DESTINATION ${versionDir} PATTERN *)
endif()

# Add and commit the files.
cpfGitAddContent(${projectDir})
cpfGitCommit("Updates \"${BUILD_RESULTS_REPOSITORY_PROJECT_SUBDIR}\" with the build results of version ${version}" ${projectDir})

# Push to the master
cpfGitPullRebase(origin master ${projectDir})
cpfGitPush(origin master ${projectDir})

# Push to the alternative remote
if(DEFINED WEB_SERVER_BUILD_RESULTS_REPOSITORY AND WEB_SERVER_BUILD_RESULTS_REPOSITORY)

	cpfGitAddRemote(webserver ${WEB_SERVER_BUILD_RESULTS_REPOSITORY} ${projectDir})
	cpfGitPush(webserver master ${projectDir})

endif()
