# This file contains tests for cpfListUtilities.

include(cpfListUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunListUtilitiesTests )

    test_cpfPopBack()
    test_cpfSplitList()
    test_cpfFindAllInList()
    test_cpfListLength()
    test_appendEmptytoEmpty()
    test_cpfContains()
    test_cpfContainsOneOf()
    test_cpfGetFirstMatch()
    test_cpfGetList1WithoutList2()

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
function( test_cpfListLength )

    set( list bli "" bla blub)
    cpfListLength(length "${list}")
    cpfAssertStrEQ(${length} 4)

endfunction()

#----------------------------------------------------------------------------------------
function( test_appendEmptytoEmpty )

    set(list)
    list(APPEND list "")
    cpfListLength(length "${list}")
    cpfAssertStrEQ(${length} 1)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfContains )

    # contains element
    set(list bli bla "" blub)
    cpfContains( contains "${list}" "")
    cpfAssertTrue(contains)

    # does not contain element
    set(list bli bla blub)
    cpfContains( contains "${list}" bleb)
    cpfAssertFalse(contains)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfContainsOneOf )

    # contains element
    set(listSearchedIn bli "" bla blub)
    set(listSearchedFor bleb blob "")
    cpfContainsOneOf( contains "${listSearchedIn}" "${listSearchedFor}")
    cpfAssertTrue(contains)

    # does not contain element
    set(listSearchedIn bli bla blub)
    set(listSearchedFor bleb blob blab)
    cpfContainsOneOf( contains "${listSearchedIn}" "${listSearchedFor}")
    cpfAssertFalse(contains)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetFirstMatch )

    # element is matched
    set(list bli bla "" blub )
    set(regex "^bla$")   # matches bla
    cpfGetFirstMatch( matchedElement "${list}" ${regex})
    cpfAssertStrEQ(${matchedElement} "bla")

    # empty element is matched
    set(list bli bla "" blub )
    set(regex "^$")   # matches only empty string
    cpfGetFirstMatch( matchedElement "${list}" ${regex})
    cpfAssertStrEQ("${matchedElement}" "")

    # no element is matched
    set(list bli bla blub )
    set(regex "^$")   # matches only empty string
    cpfGetFirstMatch( matchedElement "${list}" ${regex})
    cpfAssertStrEQ("${matchedElement}" NOTFOUND)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetList1WithoutList2 )

    set(list1 bli bla "" blub)
    set(list2 blub bli)
    cpfGetList1WithoutList2( difference "${list1}" "${list2}")
    cpfAssertListsEqual( "${difference}" "bla;" )

endfunction()

