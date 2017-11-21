# This script can be used to set release version tags on a CppCodeBase git repository.
# It will take the latest version tag and ccbIncrement one of its version numbers.
# The lower "digits" of the version number are reset to zero.

include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbGitUtilities.cmake)

ccbAssertScriptArgumentDefined(ROOT_DIR)
ccbAssertScriptArgumentDefined(BRANCH)
ccbAssertScriptArgumentDefined(DIGIT_OPTION)

# Check if last version tag is on HEAD. If so, delete it to prevent confusion.
ccbGetTagsOfHEAD( tagsAtHead ${ROOT_DIR})
ccbGetLastVersionTagOfBranch( lastVersionTag ${BRANCH} ${ROOT_DIR} TRUE)
ccbContains(headIsCurrentVersion "${tagsAtHead}" ${lastVersionTag})
if(headIsCurrentVersion)
	ccbIsReleaseVersion( isRelease ${lastVersionTag})
	if(isRelease)
		message(FATAL_ERROR "Error! The current commit is already at release version ${lastVersionTag}. Incrementing it would leave gaps in the version numbers.")
	endif()

	ccbExecuteProcess( d "git tag -d ${lastVersionTag}" ${ROOT_DIR})
	ccbExecuteProcess( d "git push origin :refs/tags/${lastVersionTag}" ${ROOT_DIR})
endif()

# Increment the version.
ccbSplitVersion( major minor patch commitId ${lastVersionTag})
if( "${DIGIT_OPTION}" STREQUAL incrementMajor )
	ccbIncrement(major)
	set(minor 0)
	set(patch 0)
elseif("${DIGIT_OPTION}" STREQUAL incrementMinor)
	ccbIncrement(minor)
	set(patch 0)
elseif("${DIGIT_OPTION}" STREQUAL incrementPatch)
	ccbIncrement(patch)
else()
	message( FATAL_ERROR "Error! Unrecognized value \"${DIGIT_OPTION}\" for parameter \"DIGIT_OPTION\"")
endif()
set( newVersion ${major}.${minor}.${patch} )

# Add new tag
ccbExecuteProcess( d "git tag ${newVersion}" ${ROOT_DIR})
ccbExecuteProcess( d "git push --tags" ${ROOT_DIR}")

