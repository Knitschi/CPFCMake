# This file contains tests for the cpfStringUtilities module

include(cpfStringUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunStringUtilitiesTests )

    test_cpfSplitString()
    test_cpfSplitStringAtWhitespaces()
    test_cpfJoinString()
    test_cpfPrependMulti()
    test_cpfRightSideOfString()
    test_cpfStringRemoveRight()
    test_cpfGetShorterString()
    test_cpfContainsGeneratorExpressions()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfSplitString )

    set(string bli,blub,bleb)
    set(expectedList bli blub bleb)
    cpfSplitString( listFromSut ${string} ,)
    cpfAssertListsEqual( "${listFromSut}" "${expectedList}" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfSplitStringAtWhitespaces )

    set(string "bli blub   bleb")
    cpfSplitStringAtWhitespaces( stringList ${string})
    cpfAssertListsEqual( "${stringList}" "bli;blub;bleb" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfJoinString )

    set(list bli bla blub)
    cpfJoinString( string "${list}" aa)
    cpfAssertStrEQ(${string} bliaablaaablub)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfPrependMulti )

    set(list bli bla "" blub)
    cpfPrependMulti( prependedList aa "${list}")
    cpfAssertListsEqual( "${prependedList}" "aabli;aabla;aa;aablub" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfRightSideOfString )

    # test split in the middle
    set(string bliblub)
    cpfRightSideOfString( rightSide ${string} 3)
    cpfAssertStrEQ(${rightSide} blub)

    # test split at the left border
    set(string bliblub)
    cpfRightSideOfString( rightSide ${string} 0)
    cpfAssertStrEQ(${rightSide} bliblub)

    # test split at the right border
    set(string bliblub)
    cpfRightSideOfString( rightSide ${string} 7)
    cpfAssertStrEQ("${rightSide}" "")

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfStringRemoveRight )

    # test split in the middle
    set(string bliblub)
    cpfStringRemoveRight( remainingString ${string} 4)
    cpfAssertStrEQ(${remainingString} bli)

    # test split at the left border
    set(string bliblub)
    cpfStringRemoveRight( remainingString ${string} 7)
    cpfAssertStrEQ("${remainingString}" "")

    # test split at the right border
    set(string bliblub)
    cpfStringRemoveRight( remainingString ${string} 0)
    cpfAssertStrEQ(${remainingString} bliblub)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetShorterString )

    # left smaller than right
    set(left bla)
    set(right blub)
    cpfGetShorterString( shorter ${left} ${right})
    cpfAssertStrEQ(${shorter} bla)

    # left empty
    set(right blub)
    cpfGetShorterString( shorter "" ${right})
    cpfAssertStrEQ("${shorter}" "")

    # right smaller than left
    set(left bla)
    cpfGetShorterString( shorter ${left} "")
    cpfAssertStrEQ("${shorter}" "")

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfContainsGeneratorExpressions )

    # contains expression
    set(string blib$<bla>blub)
    cpfContainsGeneratorExpressions( containsExpression ${string})
    cpfAssertTrue(containsExpression)

    # does not contain expression
    cpfContainsGeneratorExpressions( containsExpression "")
    cpfAssertFalse(containsExpression)

endfunction()