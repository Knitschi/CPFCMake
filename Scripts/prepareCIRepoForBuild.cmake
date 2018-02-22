# This script is supposed to be run by the build server before building a CI-project.
# The script updates all owned packages in the CI-project to their latest commits in the given branch.
# If the TAGGING_OPTION is set to create a release build, it will exchange the internal-version tag of the
# current commit with a release version tag.
# 
#
# Arguments:
# ROOT_DIR:         The CPF root directory.
# GIT_REF:          The branch, commit id or tag of the CI-repo that is build.
# TAGGING_OPTION:   This must be given if a commit should be tagges as a release. 
#                   It must be one of incrementMajor, incrementMinor, incrementPatch. Other values are ignored.
# RELEASED_PACKAGE: This option must hold the name of a package or be empty. It is only used when a release version
#                   tag is created for the specified package. If the value is empty, the CI-project repository is tagged.

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfGitUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfProjectUtilities.cmake)


cpfAssertScriptArgumentDefined(ROOT_DIR)
cpfAssertScriptArgumentDefined(GIT_REF)
cpfAssertScriptArgumentDefined(TAGGING_OPTION)
cpfAssertScriptArgumentDefined(RELEASED_PACKAGE)

# Checkout the requested reference of the CI-repository
# This is necessary because the GitSCM step always
cpfExecuteProcess( unused "git checkout ${GIT_REF}" ${ROOT_DIR})

# check if the call is is used to tag a release version
set( releaseTagOptions incrementMajor incrementMinor incrementPatch)
cpfContains( doReleaseTag "${releaseTagOptions}" ${TAGGING_OPTION} )

if(doReleaseTag)

    # Make sure only commits are upgraded to release that have already been successfully build.
    cpfHeadHasVersionTag( rootHasVersionTag ${ROOT_DIR})
    if( NOT rootHasVersionTag)
        message( FATAL_ERROR "Error! Release tag builds can only be run on commits that have already been tagged with an internal version." )
    endif()

    # Get the directory of the repository that shall be release tagged.
    if(NOT RELEASED_PACKAGE)
        set(packageRepoDir ${ROOT_DIR})
    else()
        # Check the package directory exists
        cpfGetAbsPackageDirectory( packageDir ${RELEASED_PACKAGE} ${ROOT_DIR})
        if(NOT EXISTS ${packageDir})
            message( FATAL_ERROR "Error! The CI-project does not contain a directory for the given package \"${RELEASED_PACKAGE}\".")
        endif()
        # Check the package is owned by this CI-project.
        cpfGetOwnedPackages( ownedPackages ${ROOT_DIR})
        cpfContains(isOwnedPackage "${ownedPackages}" ${RELEASED_PACKAGE})
        if(NOT isOwnedPackage)
            message( FATAL_ERROR "Error! The CI-project does not own the given package \"${RELEASED_PACKAGE}\". It can only set release tags for owned packages.")
        endif()

        set(packageRepoDir ${packageDir})
    endif()

    # Make sure no release version is overwritten.
    # Make sure that we do not overwrite a release tag.
    cpfGetCurrentVersionFromGitRepository( currentPackageVersion ${packageRepoDir})
    cpfIsReleaseVersion( isRelease ${currentPackageVersion})
    if(isRelease)
        message(FATAL_ERROR "Error! The current commit is already at release version ${lastVersionTag}. Overwriting existing releases is not allowed.")
    endif()

    # Proceed with the tagging.
    # Create the new release version number.
    cpfSplitVersion( major minor patch commitId ${currentPackageVersion})
    if( "${TAGGING_OPTION}" STREQUAL incrementMajor )
        cpfIncrement(major)
        set(minor 0)
        set(patch 0)
    elseif("${TAGGING_OPTION}" STREQUAL incrementMinor)
        cpfIncrement(minor)
        set(patch 0)
    elseif("${TAGGING_OPTION}" STREQUAL incrementPatch)
        cpfIncrement(patch)
    else()
        message( FATAL_ERROR "Error! Unrecognized value \"${DIGIT_OPTION}\" for parameter \"DIGIT_OPTION\"")
    endif()
    set( newVersion ${major}.${minor}.${patch} )

    # Make sure this version does not exist yet
    cpfGetReleaseVersionTags( releaseVersions ${packageRepoDir})
    cpfContains(alreadyExists "${releaseVersions}" ${newVersion})
    if(alreadyExists)
        message(FATAL_ERROR "Error! Incrementing the version number failed. A release with the new version ${newVersion} already exists.")
    endif()

    # Delete possibly existing internal version tags at this commit.
    cpfHeadHasVersionTag( packageHasTag ${packageRepoDir})
    if(packageHasTag)
        cpfExecuteProcess( d "git tag -d ${currentPackageVersion}" ${packageRepoDir})
        cpfExecuteProcess( d "git push origin :refs/tags/${currentPackageVersion}" ${packageRepoDir})
    endif()

    # Add the tag and push it
    message("-- Set new release version tag ${newVersion} for repository \"${packageRepoDir}\".")
    cpfExecuteProcess( d "git tag ${newVersion}" "${packageRepoDir}")
    cpfExecuteProcess( d "git push --tags origin" "${packageRepoDir}")

else()

    
    # Do nothing if the the current commit is in detached head state.
    # In this case we simply rebuild the repository "as is".
    cpfRepoIsOnDetachedHead( isDetached ${ROOT_DIR})
    if(isDetached)
        message( STATUS "The current commit of CI-Repository at \"${ROOT_DIR}\" is not the end of a branch. The repository will not be changed." )
        return()
    endif()


    # If we are at the tip of a branch we can now update all owned
    # packages to their latest version.
    message( STATUS "Update owned packages." )

    # try updateing the remote repo with changes
    # The loop is used to check wether somene else pushed to the remote while we were
    # changing the repository here.
    set(pushedChanges FALSE)
    while(NOT pushedChanges)

        # Make sure we are up to date. This is only needed after the first
        # iteration of the loop.
        cpfExecuteProcess( unused "git pull" ${ROOT_DIR})

        # Update the owned packages
        set(updatedPackages)
        cpfGetOwnedLoosePackages( ownedPackages ${ROOT_DIR})
        foreach( package ${ownedPackages} )

            cpfGetAbsPackageDirectory( packageDir ${package} ${ROOT_DIR})

            # Checkout the tracked branch
            cpfGetPackagesTrackedBranch( packageBranch ${package} ${ROOT_DIR})
            cpfExecuteProcess( b "git checkout ${packageBranch}" ${packageDir})
            # Pull changes if available
            cpfCurrentBranchIsBehindOrigin( updatesAvailable ${packageDir})
            if(updatesAvailable)
                cpfExecuteProcess( unused "git pull" ${packageDir})
                list(APPEND updatedPackages ${package})
            endif()
        endforeach()

        # At this point we could execute a formatting script on all owned packages.
        # After that we would have to commit and push all owned packages with the dontTrigger note.


        # Commit the update
        if(updatedPackages) # we actually updated a package
            cpfExecuteProcess( unused "git commit . -m\"Update packages ${updatedPackages}.\"" ${ROOT_DIR})
            cpfExecuteProcess( unused "git notes append -m\"${CPF_DONT_TRIGGER_NOTE}\" HEAD" ${ROOT_DIR})
            message( STATUS "Updated packages ${updatedPackages}.")
        else() 
            # no package updates were done. We do not need to wait for a successful push
            message( STATUS "No packages needed an update.")
            return()
        endif()

        cpfTryPushCommitsNotesAndTags( pushedChanges origin ${ROOT_DIR})

        # Repeat the update procedure if somebody pushed changes to the remote in the meantime.

    endwhile()

endif()
