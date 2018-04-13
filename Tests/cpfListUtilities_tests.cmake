# This file contains tests for cpfListUtilities.

include(cpfListUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunListUtilitiesTests )

    test_cpfPopBack()
    test_cpfSplitList()
    test_cpfFindAllInList()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfPopBack )

    # list with multiple elements
    set(mylist blub "" blab)
    cpfPopBack( lastElement mylist "${mylist}")
    cpfAssertStrEQ(${lastElement} blab)
    cpfAssertListLength("${mylist}" 2)

    # list with one element
    set(list blub)
    cpfPopBack( lastElement list "${list}")
    cpfAssertStrEQ(${lastElement} blub)
    cpfAssertListLength("${list}" 0)

    # list with no element
    # How can we test for script failure?
    set(list)
    #cpfPopBack( lastElement list "${list}")

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfSplitList )

    # splits list in the middle
    set(list bli bla "" blub)
    cpfSplitList( outLeft outRight "${list}" 1)
    cpfAssertListsEqual( "${outLeft}" "bli" )
    cpfAssertListsEqual( "${outRight}" "bla;;blub" )

    # splits list at left end
    set(list bli bla "" blub)
    cpfSplitList( outLeft outRight "${list}" 0)
    cpfAssertListsEqual( "${outLeft}" "" )
    cpfAssertListsEqual( "${outRight}" "bli;bla;;blub" )

    # splits list at right end
    set(list bli bla "" blub)
    cpfSplitList( outLeft outRight "${list}" 4)
    cpfAssertListsEqual( "${outLeft}" "bli;bla;;blub" )
    cpfAssertListsEqual( "${outRight}" "" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfFindAllInList )

    # finds elements
    set( list bli bla bla blub bla )
    cpfFindAllInList( foundIndexes "${list}" bla)
    cpfAssertListsEqual( "${foundIndexes}" "1;2;4" )

    # finds empty elements
    set( list bli bla "" bla blub "" bla )
    cpfFindAllInList( foundIndexes "${list}" "")
    cpfAssertListsEqual( "${foundIndexes}" "2;5" )

    # returns empty list if none found
    set( list bli bla "" bla blub "" bla )
    cpfFindAllInList( foundIndexes "${list}" "bleb")
    cpfAssertListsEqual( "${foundIndexes}" "" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_ )



endfunction()