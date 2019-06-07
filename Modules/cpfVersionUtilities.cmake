include_guard(GLOBAL)

#---------------------------------------------------------------------------------------------
# This function reads the package version from a packages version file.
function( cpfGetPackageVersionFromFile versionOut package absPackageSourceDir )

	getExistingPackageVersionFile( versionFile ${package} )

	include("${versionFile}")
	if( "${CPF_${package}_VERSION}" STREQUAL "")
		message(FATAL_ERROR "Could not read value of variable CPF_${package}_VERSION from file \"${absPackageSourceDir}/${versionFile}\"." )
	endif()
	set( ${versionOut} ${CPF_${package}_VERSION} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the path to the version.cmake file in the source tree or in the binary tree depending on which exists.
function( getExistingPackageVersionFile absPathOut package )

	cpfGetPackageVersionFileName( versionFile ${package})
	set(sourceTreePath "${CMAKE_CURRENT_SOURCE_DIR}/${versionFile}")
	set(binaryTreePath "${CMAKE_CURRENT_BINARY_DIR}/${versionFile}")

	if(EXISTS "${sourceTreePath}")
		set(${absPathOut} "${sourceTreePath}" PARENT_SCOPE)
	elseif(EXISTS "${binaryTreePath}")
		set(${absPathOut} "${binaryTreePath}" PARENT_SCOPE)
	else()
		message(FATAL_ERROR "File ${verisonFile} is missing! It should be in the source or binary directory of package ${package}." )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# The function assumes that version and has the form 123.12.123.12-acdf and returns the 
# first number as major version, the second number as minor version  and the last part
# as commitIdOut if it exists.
# 
function( cpfSplitVersion majorOut minorOut patchOut commitIdOut versionString)
	
	cpfSplitString( versionList ${versionString} ".")
	list(GET versionList 0 majorVersion)
	list(GET versionList 1 minorVersion)
	list(GET versionList 2 patchNr)

	set(${majorOut} ${majorVersion} PARENT_SCOPE)
	set(${minorOut} ${minorVersion} PARENT_SCOPE)
	set(${patchOut} ${patchNr} PARENT_SCOPE)

	cpfListLength(length "${versionList}" )
	if( ${length} GREATER 3 )
		list(GET versionList 3 commitsNr)
		set( ${commitIdOut} ${commitsNr} PARENT_SCOPE)
	else()
		set( ${commitIdOut} "" PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the version number misses the 4th commits number.
# 
function( cpfIsReleaseVersion isReleaseOut version )
	cpfSplitVersion( d d d commits ${version})
	if("${commits}" STREQUAL "")
		set( ${isReleaseOut} TRUE PARENT_SCOPE)
	else()
		set( ${isReleaseOut} FALSE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the version is marked as dirty, which means there are local uncommitted changes.
#
function( cpfIsDirtyVersion isDirtyOut version )
	cpfStringContains( isDirty "${version}" -dirty)
	set(${isDirtyOut} ${isDirty} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns the part of the version number that contains the nummber of commits since the
# last release version.
#
function( cpfGetCommitsSinceLastRelease commitNrOut version )
	
	cpfIsReleaseVersion(isRelease ${version})
	if(isRelease)
		set(${commitNrOut} 0 PARENT_SCOPE)
		return()
	endif()

	string(REGEX MATCH ".[0-9]*-" commitNr "${version}")
	cpfStringRemoveRight( commitNr ${commitNr} 1)
	cpfRightSideOfString( commitNr ${commitNr} 1)
	set(${commitNrOut} ${commitNr} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetLastBuildAndLastReleaseVersion lastBuildVersionOut lastReleaseVersionOut )
	
	cpfGetCurrentBranch( branch "${CMAKE_CURRENT_SOURCE_DIR}")
	cpfGetLastVersionTagOfBranch( lastVersion ${branch} "${CMAKE_CURRENT_SOURCE_DIR}" FALSE)
	cpfGetLastReleaseVersionTagOfBranch( lastReleaseVersion ${branch} "${CMAKE_CURRENT_SOURCE_DIR}" FALSE)
	
	set(${lastBuildVersionOut} "${lastVersion}" PARENT_SCOPE)
	set(${lastReleaseVersionOut} "${lastReleaseVersion}" PARENT_SCOPE)
	
endfunction()
