# This script is supposed to be run by the build server before building a CI-project.
# The script updates all owned packages in the CI-project to their latest commits in the given branch.
# 
#
# Arguments:
# ROOT_DIR						: The CPF root directory.
# BRANCH                        : The branch of the package repositories from which updates are pulled.
# TEMP_BRANCH                   : A branch that is temporarily created on all owned repositories.


include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfConstants.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfGitUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfProjectUtilities.cmake)


cpfAssertScriptArgumentDefined(ROOT_DIR)
cpfAssertScriptArgumentDefined(BRANCH)

# Do nothing if the current commit already has a build tag.
cpfGetCurrentVersionFromGitRepository( versionHead "${ROOT_DIR}")
cpfGetTagsOfHEAD( tagsAtHead "${ROOT_DIR}")
cpfContains(headIsAlreadyTagged "${tagsAtHead}" ${versionHead})
if(headIsAlreadyTagged)
    message( STATUS "The current commit of CI-Repository at \"${ROOT_DIR}\" has already been tagged. Packages are not updated." )
    return()
endif()

# checkout the CI-repository
cpfExecuteProcess( unused "git checkout ${BRANCH}" ${ROOT_DIR})

# try updateing the remote repo with changes
# The loop is used to check wether somene else pushed to the remote while we were
# changing the repository here.
set(pushedChanges FALSE)
while(NOT pushedChanges)

    # Make sure we are up to date. This is only needed after the first
    # iteration of the loop.
    cpfExecuteProcess( unused "git pull ${BRANCH}" ${ROOT_DIR})

    # Update the owned packages
    cpfGetOwnedRepositoryDirectories( ownedRepoDirs "${ROOT_DIR}" )
    foreach( repoDir ${ownedRepoDirs} )
        if(NOT (${repoDir} STREQUAL "${ROOT_DIR}"))
            # checkout the branch
            cpfExecuteProcess( unused "git checkout ${BRANCH}" ${repoDir})
            # pull new commits
            cpfExecuteProcess( unused "git pull origin ${BRANCH}" ${repoDir})
        endif()
    endforeach()

    # At this point we could execute a formatting script on all owned packages.
    # After that we would have to commit and push all owned packages with the dontTrigger note.


    # Commit the update
    cpfWorkingDirectoryIsDirty( isDirty "${ROOT_DIR}")
    if(isDirty) 
        cpfExecuteProcess( unused "git commit . -m\"Update owned packages.\"" ${ROOT_DIR})
        cpfExecuteProcess( unused "git notes append -m\"${CPF_DONT_TRIGGER_NOTE}\" HEAD" ${ROOT_DIR})
    endif()

    cpfTryPushCommitsAndNotes( pushedChanges origin ${ROOT_DIR})
    # Repeat the update procedure if somebody pushed changes to the remote in the meantime.

endif()
