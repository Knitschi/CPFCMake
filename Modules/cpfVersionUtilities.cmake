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
		message(FATAL_ERROR "File \"${verisonFile}\" is missing! It should be in the source or binary directory of package ${package}." )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# The function assumes that version and has the form 123.12.123.12-acdf and returns the 
# first number as major version, the second number as minor version  and the last part
# as commitIdOut if it exists.
# 
function(cpfSplitVersion majorOut minorOut patchOut commitIdOut versionString)

	set(majorVersion "")
	set(minorVersion "")
	set(patchNr "")
	set(commitsNr "")

	cpfSplitString( versionList ${versionString} ".")
	cpfListLength(length "${versionList}")
	
	if(${length} GREATER 0)
		list(GET versionList 0 majorVersion)
	endif()

	if(${length} GREATER 1)
		list(GET versionList 1 minorVersion)
	endif()

	if(${length} GREATER 2)
		list(GET versionList 2 patchNr)
	endif()

	if( ${length} GREATER 3 )
		list(GET versionList 3 commitsNr)
	endif()

	set(${majorOut} ${majorVersion} PARENT_SCOPE)
	set(${minorOut} ${minorVersion} PARENT_SCOPE)
	set(${patchOut} ${patchNr} PARENT_SCOPE)
	set(${commitIdOut} ${commitsNr} PARENT_SCOPE)

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

#----------------------------------------------------------------------------------------
# Returns true if the availableVersion meats the version Requirement of the requiredVersion
# in combination with the provided combatibilityScheme. 
# 
# Arguments:
# compatibilityScheme: Can be one of <AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion>
#					   Note that these are the schemes that are defined in the CMakePackageConfigHelpers documentation
#					   https://cmake.org/cmake/help/latest/module/CMakePackageConfigHelpers.html#module:CMakePackageConfigHelpers
# 
function( cpfVersionIsCompatibleToRequirement isCompatibleOut availableVersion requiredVersion compatibilityScheme ignoreDirty)

	set(isCompatible FALSE)
	cpfSplitVersion( majorRequired minorRequired patchRequired commitIdRequired ${requiredVersion})
	cpfSplitVersion( majorAvailable minorAvailable patchAvailable commitIdAvailable ${availableVersion})

	if(ignoreDirty)
		cpfIsDirtyVersion(isDirty ${availableVersion})
		if(isDirty)
			cpfStringRemoveRight(availableVersion ${availableVersion} 6)
		endif()
	endif()

	if("${compatibilityScheme}" STREQUAL AnyNewerVersion)
		if(${requiredVersion} VERSION_LESS_EQUAL ${availableVersion})
			set(isCompatible TRUE)
		endif()
	elseif("${compatibilityScheme}" STREQUAL SameMajorVersion)
		if(${majorRequired} EQUAL ${majorAvailable})
			set(isCompatible TRUE)
		endif()
	elseif("${compatibilityScheme}" STREQUAL SameMinorVersion)
		if(${majorRequired} EQUAL ${majorAvailable})
			if(${minorRequired} EQUAL ${minorAvailable})
				set(isCompatible TRUE)
			endif()
		endif()
	elseif("${compatibilityScheme}" STREQUAL ExactVersion)
		if(${requiredVersion} STREQUAL ${availableVersion})
			set(isCompatible TRUE)
		endif()
	else()
		message(FATAL_ERROR "Argument compatibilityScheme in function ${CMAKE_CURRENT_FUNCTION}() was set to invalid value \"${compatibilityScheme}\". Alowed values are AnyNewerVersion|SameMajorVersion|SameMinorVersion|ExactVersion.")
	endif()

	set(${isCompatibleOut} ${isCompatible} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetReleaseVersionRegExp regexpOut )
	set( ${regexpOut} "^[0-9]+[.][0-9]+[.][0-9]+$" PARENT_SCOPE) 
endfunction()
