# This script can be used to set release version tags on a CMakeProjectFramework git repository.
# It will take the latest version tag and cpfIncrement one of its version numbers.
# The lower "digits" of the version number are reset to zero.

include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfGitUtilities.cmake)

cpfAssertScriptArgumentDefined(ROOT_DIR)
cpfAssertScriptArgumentDefined(BRANCH)
cpfAssertScriptArgumentDefined(DIGIT_OPTION)

# Check if last version tag is on HEAD. If so, delete it to prevent confusion.
cpfGetTagsOfHEAD( tagsAtHead ${ROOT_DIR})
cpfGetLastVersionTagOfBranch( lastVersionTag ${BRANCH} ${ROOT_DIR} TRUE)
cpfContains(headIsCurrentVersion "${tagsAtHead}" ${lastVersionTag})
if(headIsCurrentVersion)
	cpfIsReleaseVersion( isRelease ${lastVersionTag})
	if(isRelease)
		message(FATAL_ERROR "Error! The current commit is already at release version ${lastVersionTag}. Incrementing it would leave gaps in the version numbers.")
	endif()

	cpfExecuteProcess( d "git tag -d ${lastVersionTag}" ${ROOT_DIR})
	cpfExecuteProcess( d "git push origin :refs/tags/${lastVersionTag}" ${ROOT_DIR})
endif()

# Increment the version.
cpfSplitVersion( major minor patch commitId ${lastVersionTag})
if( "${DIGIT_OPTION}" STREQUAL incrementMajor )
	cpfIncrement(major)
	set(minor 0)
	set(patch 0)
elseif("${DIGIT_OPTION}" STREQUAL incrementMinor)
	cpfIncrement(minor)
	set(patch 0)
elseif("${DIGIT_OPTION}" STREQUAL incrementPatch)
	cpfIncrement(patch)
else()
	message( FATAL_ERROR "Error! Unrecognized value \"${DIGIT_OPTION}\" for parameter \"DIGIT_OPTION\"")
endif()
set( newVersion ${major}.${minor}.${patch} )

# Add new tag
cpfExecuteProcess( d "git tag ${newVersion}" ${ROOT_DIR})
cpfExecuteProcess( d "git push --tags" ${ROOT_DIR}")

