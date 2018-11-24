

include_guard(GLOBAL)

include(cpfPathUtilities)
include(cpfMiscUtilities)

#-------------------------------------------------------------------------
# Documentation in APIDocs.dox
macro( cpfInitPackageProject packageNameSpace )

	# The package name is defined by the sub-directory name
    cpfGetPackageName( packageName )

	cpfConfigurePackageVersionFile( ${packageName} )

	# get the version number of the packages version file
	cpfGetPackageVersionFromFile( packageVersion ${packageName} ${CMAKE_CURRENT_LIST_DIR})
	message(STATUS "Package ${packageName} is now at version ${packageVersion}")
	# Configure the c++ header file with the version.
	cpfConfigurePackageVersionHeader( ${packageName} ${packageVersion} ${packageNameSpace})

	cpfSplitVersion( major minor patch commitId ${packageVersion})

	# create a sub-project for the package
	project( 
		${packageName} 
		VERSION ${major}.${minor}.${patch}
		LANGUAGES CXX C
    )
    
	set(PROJECT_VERSION ${packageVersion})
	set(PROJECT_VERSION_MAJOR ${major})
	set(PROJECT_VERSION_MINOR ${minor})
	set(PROJECT_VERSION_PATCH ${patch})
	set(PROJECT_VERSION_TWEAK ${commitId})

endmacro()

#-----------------------------------------------------------
# Returns the name of the current source directory.
function( cpfGetPackageName packageNameOut )
    cpfGetParentDirectory( packageName "${CMAKE_CURRENT_SOURCE_DIR}/blub")
    set(${packageNameOut} "${packageName}" PARENT_SCOPE)
endfunction()

#-----------------------------------------------------------
# Creates the cpfPackageVersion_<package>.cmake file in the Sources directory, by reading the version from git.
# The file is required to provide a version if the build is done with sources that are not checked out from git.
#
function( cpfConfigurePackageVersionFile package )

	# Get the paths of the created files.
	cpfGetPackageVersionFileName( cmakeVersionFile ${package})

	# Check if we work with a git repository.
	# If so, we retrieve the version from the repository.
	# If not, this must be an installed archive and the .cmake version file must already exist.
	cpfIsGitRepositoryDir( isRepoDirOut "${CMAKE_CURRENT_SOURCE_DIR}")
	if(isRepoDirOut)
	
		set(PACKAGE_NAME ${package})
		cpfGetCurrentVersionFromGitRepository( CPF_PACKAGE_VERSION "${CMAKE_CURRENT_SOURCE_DIR}")
		set( absPathCmakeVersionFile "${CMAKE_CURRENT_BINARY_DIR}/${cmakeVersionFile}")
		cpfConfigureFileWithVariables( "${CPF_ABS_TEMPLATE_DIR}/packageVersion.cmake.in" "${absPathCmakeVersionFile}" PACKAGE_NAME CPF_PACKAGE_VERSION )
	
	else()
		# Note that the version.cmake file is generated in the binary tree, but is moved
		# to the source tree when creating source packages.
		set( absPathCmakeVersionFile "${CMAKE_CURRENT_SOURCE_DIR}/${cmakeVersionFile}")
		if(NOT EXISTS "${absPathCmakeVersionFile}" )
			message(FATAL_ERROR "The package source directory \"${CMAKE_CURRENT_SOURCE_DIR}\" neither belongs to a git repository nor contains a .cmake version file.")
		endif()
	endif()

endfunction()

#-----------------------------------------------------------
function( cpfConfigurePackageVersionHeader package version packageNamespace)

	set( PACKAGE_NAME ${package})
	set( PACKAGE_NAMESPACE ${packageNamespace})
	set( CPF_PACKAGE_VERSION ${version} )

	cpfGetPackageVersionCppHeaderFileName( versionHeaderFile ${package})
	set( absPathVersionHeader "${CMAKE_CURRENT_BINARY_DIR}/${versionHeaderFile}")

	cpfConfigureFileWithVariables( "${CPF_ABS_TEMPLATE_DIR}/packageVersion.h.in" "${absPathVersionHeader}" PACKAGE_NAME CPF_PACKAGE_VERSION PACKAGE_NAMESPACE ) 

endfunction()