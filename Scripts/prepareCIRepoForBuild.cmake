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
# CONFIG:           The configuration that is used to build the clang-format target.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)

include(cpfMiscUtilities)
include(cpfGitUtilities)
include(cpfProjectUtilities)
include(cpfPackageUtilities)

cpfAssertScriptArgumentDefined(ROOT_DIR)
cpfAssertScriptArgumentDefined(GIT_REF)
cpfAssertScriptArgumentDefined(TAGGING_OPTION)
cpfAssertScriptArgumentDefined(RELEASED_PACKAGE)
cpfAssertScriptArgumentDefined(CONFIG)

# Checkout the requested reference of the CI-repository
# This is necessary because the GitSCM step always
cpfExecuteProcess( unused "git checkout ${GIT_REF}" "${ROOT_DIR}")

# check if the call is is used to tag a release version
set( releaseTagOptions incrementMajor incrementMinor incrementPatch)
cpfContains( doReleaseTag "${releaseTagOptions}" ${TAGGING_OPTION} )

if(doReleaseTag)

    # Make sure only commits are upgraded to release that have already been successfully build.
    cpfHeadHasVersionTag( rootHasVersionTag "${ROOT_DIR}")
    if( NOT rootHasVersionTag)
        message( FATAL_ERROR "Error! Release tag builds can only be run on commits that have already been tagged with an internal version." )
    endif()

    # Get the directory of the repository that shall be release tagged.
    if(NOT RELEASED_PACKAGE)
        set(packageRepoDir ${ROOT_DIR})
    else()
        # Check the package directory exists
        cpfGetAbsPackageDirectory( packageDir ${RELEASED_PACKAGE} "${ROOT_DIR}")
        if(NOT EXISTS ${packageDir})
            message( FATAL_ERROR "Error! The CI-project does not contain a directory for the given package \"${RELEASED_PACKAGE}\".")
        endif()
        # Check the package is owned by this CI-project.
        cpfGetOwnedPackages( ownedPackages "${ROOT_DIR}")
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
        cpfExecuteProcess( unused "git pull --all" ${ROOT_DIR})

        # Update the owned packages
        set(updatedPackages)
        cpfGetOwnedLoosePackages( ownedLoosePackages ${ROOT_DIR})
        foreach( package ${ownedLoosePackages} )
            message( STATUS "Check package ${package}")

            cpfGetAbsPackageDirectory( packageDir ${package} ${ROOT_DIR})

            # Checkout the tracked branch
            cpfGetPackagesTrackedBranch( packageBranch ${package} ${ROOT_DIR})
            cpfExecuteProcess( b "git checkout ${packageBranch}" ${packageDir})
            message( STATUS "Package tracks branch ${packageBranch}")

            # Pull changes if available
            cpfCurrentBranchIsBehindOrigin( updatesAvailable ${packageDir})
            if(updatesAvailable)
                cpfExecuteProcess( unused "git pull" ${packageDir})
                cpfListAppend( updatedPackages ${package})
            endif()
        endforeach()

        # Format the owned packags if the project has a .clang-tidy file.
        if(EXISTS "${ROOT_DIR}/Sources/.clang-format")
            # Currently the build-job from CPFMachines will pass in an empty config if the project
            # has no configuration that builds on the debian node. The problem is that we need to set
            # know the node-label for the prepare step before we can read the configurations.
            # A possible solution would be to add another option to the buildjob to set a label for the
            # prepare stage. See Knitschi/CPFMachines#10
            if(NOT CONFIG)
                message(WARNING "Running clang-format is not possible since the CIBuildConfigurations.json file does not contain any configuration for the Debian build-slave.")
            else()
                # Execute clang-tidy by building the clang-format target.
                # As long as we only do this on Linux we can use the python3 command directly.
                # I failed to do this using the FindPython3 module, because it does not work in script mode.
                message(STATUS "Run clang-format")
                cpfExecuteProcess( unused "python3 Sources/CPFBuildscripts/0_CopyScripts.py" ${ROOT_DIR})
                cpfExecuteProcess( unused "conan install -pr \"${ROOT_DIR}/Sources/CIBuildConfigurations/ConanProfile-${CONFIG}\" -if \"${ROOT_DIR}/Configuration/${CONFIG}\" Sources --build=missing" ${ROOT_DIR})
                cpfExecuteProcess( unused "python3 4_Make.py ${CONFIG} --target clang-format" ${ROOT_DIR})

                # Commit the changes made to the packges.
                foreach(package ${ownedLoosePackages})
                    cpfGetAbsPackageDirectory( packageDir ${package} "${ROOT_DIR}")
                    cpfGitStatus("${packageDir}") # This call fixed some strange problems where cpfWorkingDirectoryIsDirty() returned incorrect values.
                    cpfWorkingDirectoryIsDirty(isDirty "${packageDir}")
                    if(isDirty)
                        cpfExecuteProcess( unused "git commit . -m\"clang-format\"" "${packageDir}")
                        cpfTryPushCommitsAndNotes( unused origin "${packageDir}")
                        cpfListAppend( updatedPackages ${package})
                    endif()
                endforeach()

            endif()
        endif()

        if(updatedPackages)
            list(REMOVE_DUPLICATES updatedPackages)
        endif()

        # Commit the update
        # We need to explicitly check if we need to make commmits because it is possible that we
        # update the packages to the revision that is stored in the host repo.
        cpfGitStatus("${ROOT_DIR}")  # This call fixed some strange problems where cpfWorkingDirectoryIsDirty() returned incorrect values.
        cpfWorkingDirectoryIsDirty(isDirty "${ROOT_DIR}") 
        if(isDirty) # we actually updated a package
            # Explicitly fetch the notes. Normal pull does not do it.
            cpfExecuteProcess( unused "git fetch origin refs/notes/*:refs/notes/*" "${ROOT_DIR}")
            cpfExecuteProcess( unused "git commit . -m\"clang-format and updates package(s): ${updatedPackages}\"" "${ROOT_DIR}")
            cpfExecuteProcess( unused "git notes append -m\"${CPF_DONT_TRIGGER_NOTE}\" HEAD" "${ROOT_DIR}")
        else() 
            # no package updates were done. We do not need to wait for a successful push
            message( STATUS "No package needed an update.")
            return()
        endif()

        cpfTryPushCommitsAndNotes( pushedChanges origin "${ROOT_DIR}")
        if(pushedChanges)
            message( STATUS "Updated package(s): ${updatedPackages}.")
        endif()

        # Repeat the update procedure in case somebody pushed changes to the remote in the meantime.

    endwhile()

endif()
