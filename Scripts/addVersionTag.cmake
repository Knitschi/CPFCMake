
# This script is supposed to be run by the build server after a succsefull build.
# It adds a leightweight tag with the current version to mark a commit as a succesfull build.
#
# Arguments:
# ROOT_DIR						: The CPF root directory.
# INCREMENT_VERSION_OPTION		: Can be internal, incrementPatch, incrementMinor, incrementMayor

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfProjectUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfGitUtilities.cmake)

cpfAssertScriptArgumentDefined(ROOT_DIR)
cpfAssertScriptArgumentDefined(INCREMENT_VERSION_OPTION)


################### SCRIPT ######################

# do it for owned packages and host repos
cpfGetOwnedPackages( ownedPackages ${ROOT_DIR} )
set( repositoryDirectories ${ROOT_DIR} )
foreach(package ${ownedPackages})
	cpfGetAbsPackageDirectory( packageDirOut ${package} ${ROOT_DIR})
endforeach()

foreach( repoDir ${repositoryDirectories} )
	# Add a new Tag
	cpfGetCurrentVersionFromGitRepository( version "${repoDir}")
	cpfGitRepoHasTag( alreadyHasBuildVersion ${version} "" "${repoDir}")
	if(alreadyHasBuildVersion)
		message("-- The version tag ${version} in branch ${tempBranch} already exists. Skip tagging.")
	else()
		message("-- Set new version tag ${version}.")
		cpfExecuteProcess( d "git tag ${version}" "${repoDir}")
	endif()

	# Push the commit and tag
	cpfExecuteProcess( d "git push origin" "${repoDir}")
	cpfExecuteProcess( d "git push --tags origin" "${repoDir}")

endforeach()

