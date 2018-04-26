# This file contains tests for the cpfPathUtilities module

include(cpfPathUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunPathUtilitiesTests )

    test_cpfGetParentDirectory()
    test_cpfGetSubdirectories()
    test_cpfIsSubPath()
    test_cpfGetPathRoot()
    test_cpfIsAbsolutePath()
    test_cpfNormalizeAbsPath()
    test_cpfGetRelativePaths()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetParentDirectory )

    set(dirPath "/bli/Bla/blub" )
    cpfGetParentDirectory(parrentDir ${dirPath})
    cpfAssertStrEQ(${parrentDir} Bla)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetSubdirectories )
    # the function accesses the filesystem, so we leave it untested for now.
endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfIsSubPath )
    
    set(longPath C:/bli/bla/blub )
    set(shortPath C:/bli/bla )
    set(noSubPath D:/blob )

    # works for subpath
    cpfIsSubPath( isSubPath ${longPath} ${shortPath})
    cpfAssertTrue(isSubPath)

    # works if no subpath
    cpfIsSubPath( isSubPath ${noSubPath} ${shortPath})
    cpfAssertFalse(isSubPath)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetPathRoot )

    if(CMAKE_HOST_UNIX)

        # happy case
        set(absPath /bli/bla/blub)
        cpfGetPathRoot( pathRoot ${absPath})
        cpfAssertStrEQ(${pathRoot} /)

        # path has no root
        set(relPath bli/bla/blub)
        cpfGetPathRoot( pathRoot ${relPath})
        cpfAssertStrEQ(${pathRoot} NOTFOUND)

    elseif(CMAKE_HOST_WIN32)

        # happy case
        set(absPath C:/bli/bla/blub)
        cpfGetPathRoot( pathRoot ${absPath})
        cpfAssertStrEQ(${pathRoot} C)

        # path has no root
        set(relPath bli/bla/blub)
        cpfGetPathRoot( pathRoot ${relPath})
        cpfAssertStrEQ(${pathRoot} NOTFOUND)

    else()
        message(FATAL_ERROR "Test test_cpfGetPathRoot() needs to be extended to work on the current host platform.")
    endif()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfIsAbsolutePath )

    if(CMAKE_HOST_UNIX)

        # is absolute
        set(path /bli/bla/blub )
        cpfIsAbsolutePath( isAbsolute ${path})
        cpfAssertTrue(isAbsolute)

        # is not absolute
        set(path bli/bla/blub )
        cpfIsAbsolutePath( isAbsolute ${path})
        cpfAssertFalse(isAbsolute)

    elseif(CMAKE_HOST_WIN32)

        # is absolute
        set(path C:/bli/bla/blub )
        cpfIsAbsolutePath( isAbsolute ${path})
        cpfAssertTrue(isAbsolute)

        # is not absolute
        set(path bli/bla/blub )
        cpfIsAbsolutePath( isAbsolute ${path})
        cpfAssertFalse(isAbsolute)

    else()
        message(FATAL_ERROR "Test test_cpfIsAbsolutePath() needs to be extended to work on the current host platform.")
    endif()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfNormalizeAbsPath )

    set(notNormedPath ${CMAKE_CURRENT_LIST_DIR}/bla/../ )
    cpfNormalizeAbsPath( normedPath ${notNormedPath})
    cpfAssertStrEQ(${normedPath} ${CMAKE_CURRENT_LIST_DIR})

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetRelativePaths )

    set(relPath1 bli/bla )
    set(relPath2 blu/bleb )
    cpfGetRelativePaths( relPaths ${CMAKE_CURRENT_LIST_DIR} "${CMAKE_CURRENT_LIST_DIR}/${relPath1};${CMAKE_CURRENT_LIST_DIR}/${relPath2}")
    cpfAssertListsEqual( "${relPaths}" "${relPath1};${relPath2}" )

endfunction()