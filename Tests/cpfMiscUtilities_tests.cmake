# This file contains tests for the cpfMiscUtilities module

include(cpfMiscUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunMiscUtilitiesTests )

    test_cpfAssertDefined()
    test_cpfAssertDefinedMessage()
    test_cpfGetConfigVariableSuffixes1()
    test_cpfGetConfigVariableSuffixes2()
    test_cpfSplitVersion()
    test_cpfIsReleaseVersion()
    test_cpfGetKeywordValueLists()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfAssertDefined )

    set(bliblibblibbliblbibli bla)
    cpfAssertDefined( bliblibblibbliblbibli)

    # how can we test the negative case?

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfAssertDefinedMessage )

    set(bliblibblibbliblbibli bla)
    cpfAssertDefinedMessage( bliblibblibbliblbibli "Variable bliblibblibbliblbibli must be defined because of bla bla bla.")

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetConfigVariableSuffixes1 )

    # Test for single config build-tools where CMAKE_BUILD_TYPE
    # is defined in the CPF.
    set(CMAKE_CONFIGURATION_TYPES Debug Release)
    cpfGetConfigVariableSuffixes(suffixes)
    cpfAssertListsEqual( "${suffixes}" "_DEBUG;_RELEASE" )

endfunction()

function( test_cpfGetConfigVariableSuffixes2 )

    # Test for multi config build-tools where CMAKE_CONFIGURATION_TYPES
    # is defined.
    set(CMAKE_BUILD_TYPE Debug)
    cpfGetConfigVariableSuffixes(suffixes)
    cpfAssertListsEqual( "${suffixes}" "_DEBUG" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfSplitVersion )

    # Test with internal version
    set(version 1.02.33.999-ab0cdf)
    cpfSplitVersion( majorOut minorOut patchOut commitIdOut ${version})
    cpfAssertStrEQ(${majorOut} 1)
    cpfAssertStrEQ(${minorOut} 02)
    cpfAssertStrEQ(${patchOut} 33)
    cpfAssertStrEQ(${commitIdOut} 999-ab0cdf)

    # Test with release version
    set(version 1.02.33)
    cpfSplitVersion( majorOut minorOut patchOut commitIdOut ${version})
    cpfAssertStrEQ(${majorOut} 1)
    cpfAssertStrEQ(${minorOut} 02)
    cpfAssertStrEQ(${patchOut} 33)
    cpfAssertStrEQ(${commitIdOut} "")

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfIsReleaseVersion )

    # Test with internal version
    set(version 1.02.33.999-ab0cdf)
    cpfIsReleaseVersion( isRelease ${version})
    cpfAssertFalse(isRelease)

    # Test with release version
    set(version 1.02.33)
    cpfIsReleaseVersion( isRelease ${version})
    cpfAssertTrue(isRelease)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetKeywordValueLists )

    set(arguments BLUB blib MULTIKEY bli bla blab BLEB "" foo MULTIKEY bar "" booze )
    set(valueListsKeyword MULTIKEY )
    set(otherKeywords BLUB BLEB )
    cpfGetKeywordValueLists( valueListsOut "${valueListsKeyword}" "${otherKeywords}" "${arguments}" "multikeyArgs")
    
    list(GET ${valueListsOut} 0 listName0 )
    cpfAssertStrEQ(${listName0} "multikeyArgs_0")
    cpfAssertListsEqual( "${${listName0}}" "bli;bla;blab" )


    list(GET ${valueListsOut} 1 listName1 )
    cpfAssertStrEQ(${listName1} "multikeyArgs_1")
    cpfAssertListsEqual( "${${listName1}}" "bar;;booze" )

endfunction()