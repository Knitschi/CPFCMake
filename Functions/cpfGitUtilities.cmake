# This file contains functions that can be used to interact with a git repository

include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)


#----------------------------------------------------------------------------------------
# Returns true if the tag exists somewhere in the repository
# If branch is "", the function will look in the whole repository, otherwise only in the
# commits that precede the HEAD of the given branch.
function( cpfGitRepoHasTag hasTagOut tag branch repositoryDir )
	# get a list of tags from git
	cpfGetTags( tags "${branch}" "${repositoryDir}" )
	# check if there is a tag with our version
	cpfContains( hasVersionTag "${tags}" ${tag})
	set( ${hasTagOut} ${hasVersionTag} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# A list of tags in a branch or the whole repository
# Tags of younger releases come first in the returned list.
function( cpfGetTags tagsOut branch repositoryDir)

	if( "${branch}" STREQUAL "")
		cpfExecuteProcess( textOutput "git tag -l --sort=-committerdate" "${repositoryDir}")
	else()
		cpfExecuteProcess( textOutput "git tag -l --sort=-committerdate --merged ${branch}" "${repositoryDir}")
	endif()

	set(tags)
	if(textOutput)
		cpfSplitStringAtWhitespaces( tags "${textOutput}")
	endif()

	set( ${tagsOut} ${tags} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTagsOfHEAD tagsOut repositoryDir )
	cpfGetTagsAtCommit( tags HEAD ${repositoryDir})
	set( ${tagsOut} ${tags} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTagsAtCommit tagsOut commitRef repositoryDir )

	cpfExecuteProcess( textOutput "git tag -l --points-at ${commitRef}" ${repositoryDir})
	set(tags)
	if(textOutput)
		cpfSplitStringAtWhitespaces( tags "${textOutput}")
	endif()
	set( ${tagsOut} ${tags} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Returns a list of release version tags with the latest tags appearing first in the list.
function( cpfGetReleaseVersionTags tagsOut repositoryDir )
	cpfGetTags( tags "" ${repositoryDir})
	cpfGetReleaseVersionRegExp(versionRegExp)
	list(FILTER tags INCLUDE REGEX ${versionRegExp})
	
	set(${tagsOut} ${tags} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Get the previous version tag of the checked out branch.
# Argument branch can either be set a branch name or to HEAD if the repository is in detached mode.
# 
function( cpfGetLastVersionTagOfBranch lastVersionTagOut branch repositoryDir allowTagsAtHEAD )

	cpfGetPrecedingTagsLatestFirst( tags ${branch} ${repositoryDir} ${allowTagsAtHEAD} )

	# The regex should match the following strings
	# "1.2.3"							release version
	# "1.3.4.34-udfs"					internal-version
	# "1.2.898.342-uda83-rc_foo-Bar6"	internal-version with added "comment"
	# "3.24.5324.u8ewa"					version without commit number since last release.
	#
	# The regex should not match
	# "83.54.32-rc"						release-version with comment. The version of a release must be "clean" so it can be directly used in binary names.
	# "abc12.43.5"						Should not match unclean release version

	cpfGetFirstMatch( latestVersionTag "${tags}" "^[0-9]+[.][0-9]+[.][0-9]+([.]([0-9]+[\\-])?[0-9a-z]+([\\-][0-9a-zA-Z\\-\\_]*)?)?$")
	# make sure we do not have a release tag at the same version
	cpfGetTagsAtCommit( siblingTags ${latestVersionTag} ${repositoryDir})
	cpfGetReleaseVersionRegExp( regexp)
	cpfGetFirstMatch( releaseVersionTag "${siblingTags}" ${regexp})
	if(releaseVersionTag)
		set(${lastVersionTagOut} ${releaseVersionTag} PARENT_SCOPE)
	else()
		set(${lastVersionTagOut} ${latestVersionTag} PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetReleaseVersionRegExp regexpOut )
	set( ${regexpOut} "^[0-9]+[.][0-9]+[.][0-9]+$" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPrecedingTagsLatestFirst tagsOut branch repositoryDir allowTagsAtHEAD )

	cpfGetTags( tags ${branch} "${repositoryDir}")
	if(NOT allowTagsAtHEAD)
		cpfGetTagsOfHEAD( headTags ${repositoryDir} )
		if(headTags)
			list(REMOVE_ITEM tags ${headTags}) # make sure we do not get a tag at HEAD
		endif()
	endif()
	
	set( ${tagsOut} ${tags} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Returns the last version tag that is a release version.
# This will not return a tag of HEAD, but only older tags.
function( cpfGetLastReleaseVersionTagOfBranch lastVersionTagOut branch repositoryDir allowTagsAtHEAD )

	cpfGetPrecedingTagsLatestFirst( tags "${branch}" ${repositoryDir} ${allowTagsAtHEAD} )

	# The regex should only match release versions that only contain three numbers with single dots in between them like 1.23.45
	cpfGetReleaseVersionRegExp(regexp)
	cpfGetFirstMatch( latestVersionTag "${tags}" ${regexp} )
	set(${lastVersionTagOut} ${latestVersionTag} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# get the number of commits since the last tag
function( cpfGetNumberOfCommitsSinceTag nrCommitsOut tag repositoryDir )

	cpfExecuteProcess( nrCommitsSinceTag "git rev-list ${tag}..HEAD --count" "${repositoryDir}")

	set(${nrCommitsOut} ${nrCommitsSinceTag} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the name of the currently checked out branch.
# The function returns HEAD if the repository is in detached HEAD mode.
function( cpfGetCurrentBranch currentBranchOut repositoryDir)
	cpfExecuteProcess( branch "git rev-parse --abbrev-ref HEAD" "${repositoryDir}")
	set(${currentBranchOut} ${branch} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfHasLocalBranch hasBranchOut branch repositoryDir )

	cpfExecuteProcess( textOutput "git branch" "${repositoryDir}")
	cpfSplitStringAtWhitespaces( branches "${textOutput}")
	cpfContains( hasBranch "${branches}" ${branch})
	set(${hasBranchOut} ${hasBranch} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfDeleteBranch branch repositoryDir )
	cpfExecuteProcess( dummyOut "git branch -D ${branch}" "${repositoryDir}")
endfunction()

#----------------------------------------------------------------------------------------
# checks if a certain branch exists on a remote repository
function( cpfRemoteHasBranch hasBranchOut remote branch repositoryDir )

	cpfExecuteProcess( dummyOut "git fetch -p ${remote}" "${repositoryDir}") # update the local "cache" of remote branches first
	cpfExecuteProcess( textOutput "git branch -r" "${repositoryDir}")
	cpfSplitStringAtWhitespaces( branches "${textOutput}")
	cpfContains( hasBranch "${branches}" ${remote}/${branch})
	set(${hasBranchOut} ${hasBranch} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# deletes a remote branch
function( cpfDeleteRemoteBranch remote branch repositoryDir )
	cpfExecuteProcess( dummyOut "git fetch -p ${remote}" "${repositoryDir}") # update the local "cache" of remote branches first
	cpfExecuteProcess( textOutput "git push ${remote} -d ${branch}" "${repositoryDir}")
endfunction()

#----------------------------------------------------------------------------------------
# returns the url of the origin remote
function( cpfGetUrlOfOrigin urlOut repositoryDir )
	cpfExecuteProcess( url "git config --get remote.origin.url" "${repositoryDir}")
	set( ${urlOut} "${url}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# The function returns true if one of the heads of the branches 1 and 2 is an ancestor
# to the other. If this is true, merging the branches will be a fast-forward merge without
# the creation of a new commit.
function( cpfMergeWillBeFastForward isFastForwardOut branch1 branch2 repoDir )

	set(isFastForward FALSE)

	execute_process(
		COMMAND git;merge-base;--is-ancestor;refs/heads/${branch1};refs/heads/${branch2}
		WORKING_DIRECTORY "${repoDir}"
		RESULT_VARIABLE result1
	)

	execute_process(
		COMMAND git;merge-base;--is-ancestor;refs/heads/${branch2};refs/heads/${branch1}
		WORKING_DIRECTORY "${repoDir}"
		RESULT_VARIABLE result2
	)

	if( result1 OR result2 )
		set(isFastForward TRUE)
	endif()
	set(${isFastForwardOut} ${isFastForward} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# returns True if the given directory is within a git repository.
function( cpfIsGitRepositoryDir isRepoDirOut absDirPath )

	execute_process(
		COMMAND git;rev-parse;HEAD
		WORKING_DIRECTORY "${absDirPath}"
		RESULT_VARIABLE result
		OUTPUT_VARIABLE unused	# suppress the output of the command
		ERROR_VARIABLE unused
	)

	if( ${result} EQUAL 0 )
		set(${isRepoDirOut} TRUE PARENT_SCOPE)
	else()
		set(${isRepoDirOut} FALSE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns the 4th part of a version number that can only be found in internal versions.
# It consists of a number that indicates the number of commits since the last release
# version and the first digits of the commit hash that are needed to uniquely identify 
# the commit.
# The commit number is included to provide information that allows to quickly compare
# the "age" of versions, but same commit numbers can be counted on different branches
# so the commit id is also needed to make sure the version is unique.
#
# If the function is run, while the working directory has changes, it will also
# append "-dirty" to the version number. However, it is not guaranteed that build-results
# that have no -dirty version were build from a clean working directory. 
#
function( cpfGetCommitIdOfHead commitIdOut lastVersionTag repositoryDir )
	
	# get the number of commits since the last release version
	cpfSplitVersion( major minor patch unused ${lastVersionTag})
	set( lastReleaseTag ${major}.${minor}.${patch})
	cpfGetNumberOfCommitsSinceTag( nrCommitsOut ${lastReleaseTag} "${repositoryDir}")
	set(commitId ${nrCommitsOut} )

	# get the commit has
	cpfExecuteProcess( hash "git rev-parse --short=4 HEAD" "${repositoryDir}")
	string(APPEND commitId -${hash})
	
	set( ${commitIdOut} ${commitId} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns FALSE if there are no changes in the current working directory
function( cpfWorkingDirectoryIsDirty isDirtyOut repositoryDir)
	execute_process(
		COMMAND git;diff-index;--quiet;HEAD
		WORKING_DIRECTORY "${repositoryDir}"
		RESULT_VARIABLE result
	)

	if( ${result} EQUAL 0 )
		set(${isDirtyOut} FALSE PARENT_SCOPE)
	else()
		set(${isDirtyOut} TRUE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Reads the version of the currently checked out commit from the git repository
function( cpfGetCurrentVersionFromGitRepository versionOut repoDir  )

	cpfGetCurrentBranch( currentBranch "${repoDir}")
	cpfGetLastReleaseVersionTagOfBranch( lastReleaseTagVersion ${currentBranch} "${repoDir}" TRUE)
	if(NOT lastReleaseTagVersion)
		message( FATAL_ERROR "Branch ${currentBranch} of the repository at ${repoDir} has no release version tag. Make sure to tag the first commit of the repository with \"0.0.0\"" )
	endif()
	cpfSplitVersion( major minor patch unused ${lastReleaseTagVersion} )
	
	# check if the last tag is the currently checked out version.
	# If so we return the tag. This will make sure that the function
	# will return release version tags that do not have the commit id.
	cpfGetHashOfTag( hashLastTag ${lastReleaseTagVersion} "${repoDir}")
	cpfGetHashOfTag( hashHEAD HEAD "${repoDir}")
	cpfWorkingDirectoryIsDirty(isDirty "${repoDir}")
	if( ${hashLastTag} STREQUAL ${hashHEAD} ) 
		# HEAD already has a version tag. We use this one.
		set( versionLocal ${lastReleaseTagVersion})
		if(isDirty)
			set( versionLocal ${versionLocal}.0-dirty )
		endif()
	else()	
		# HEAD does not have a version tag. We create a new one.
		cpfGetCommitIdOfHead( currentCommitId ${lastReleaseTagVersion} "${repoDir}")
		set( versionLocal ${major}.${minor}.${patch}.${currentCommitId})
		if(isDirty)
			set( versionLocal ${versionLocal}-dirty )
		endif()
	endif()

	# Leave the major minor and patch as they are. They must be incremented manually for released versions.
	# We only update the commitId to the hash of the current commit.
	set( ${versionOut} ${versionLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the commitId hash of a tag or the head.
function( cpfGetHashOfTag hashOut tag repositoryDir )
	cpfExecuteProcess( hash "git rev-list -1 ${tag}" "${repositoryDir}")
	set(${hashOut} ${hash} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the current branch of the given repository was pushed to a remote.
# The function will fail if the repository is in detached HEAD state.
function( cpfTryPushCommitsNotesAndTags pushConfirmedOut remote repoDir )
	
	cpfGetCurrentBranch( branch ${repoDir})
	if(${branch} STREQUAL HEAD)
		message(FATAL_ERROR "Function cpfTryPushCommitsNotesAndTags() requires the repository not to be in detached HEAD mode.")
	endif()
	# try push commits
	execute_process(
		COMMAND git;push;${remote};refs/notes/*;refs/heads/${branch};refs/tags/*
		WORKING_DIRECTORY "${repoDir}"
		RESULT_VARIABLE result
	)
	if(${result} EQUAL 0)
		devMessage("push returned 0")
		set(${pushConfirmedOut} TRUE PARENT_SCOPE)
	else()
		set(${pushConfirmedOut} FALSE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the repository is checked out to a specific commit that is not the end
# of a branch.
function( cpfRepoIsOnDetachedHead isDetached repoDir)
	# the command fails if the HEAD is detached, otherwise returns the branch name
	cpfGetCurrentBranch( branch ${repoDir})
	if("${branch}" STREQUAL HEAD)
		set(${isDetached} TRUE PARENT_SCOPE)
	else()
		set(${isDetached} FALSE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# The function returns true if the currently checkout out commit already has a version tag.
function( cpfHeadHasVersionTag hasTagOut repoDir)

	cpfGetCurrentVersionFromGitRepository( versionHead ${repoDir})
	cpfGetTagsOfHEAD( tagsAtHead ${repoDir})
	cpfContains(headHasVersionTag "${tagsAtHead}" ${versionHead})
	set(${hasTagOut} ${headHasVersionTag} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# The function returns TRUE if a git pull command would actually pull new commits from
# remote origin on the current branch.
function( cpfCurrentBranchIsBehindOrigin isBehindOut repoDir )

	cpfGetCurrentBranch( branch ${repoDir})
	if(${branch} STREQUAL HEAD)
		message(FATAL_ERROR "Calling function cpfCurrentBranchIsBehindOrigin() does not make sense when the repository is in detached HEAD mode.")
	endif()
	cpfExecuteProcess( d "git remote update" ${repoDir})
	cpfExecuteProcess( nrCommitsBehindOrigin "git rev-list HEAD...origin/${branch} --count" ${repoDir})
	devMessage("${nrCommitsBehindOrigin}")
	if( ${nrCommitsBehindOrigin} EQUAL 0)
		set(${isBehindOut} FALSE PARENT_SCOPE)
	else()
		set(${isBehindOut} TRUE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackagesTrackedBranch packageBranchOut package rootDir)
	cpfExecuteProcess( branch "git config --file .gitmodules --get submodule.Sources/${package}.branch" ${rootDir})
	if(NOT branch)
		message(FATAL_ERROR "Error! Function cpfGetPackagesTrackedBranch() expects the package ${package} to be a git-submodule with a tracked branch in the .gitmodules file.")
	endif()
	set(${packageBranchOut} ${branch} PARENT_SCOPE)
endfunction()

