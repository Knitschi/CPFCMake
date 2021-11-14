# This file contains tests for the cpfMiscUtilities module

include(cpfMiscUtilities)
include(cpfTestUtilities)
include(cpfConfigUtilities)
include(cpfVersionUtilities)

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
    test_cpfGetCommitsSinceLastRelease()
    test_cpfGetRequiredPackageOption()

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
    cpfAssertListsEqual( "${suffixes}" "DEBUG;RELEASE" )

endfunction()

function( test_cpfGetConfigVariableSuffixes2 )

    # Test for multi config build-tools where CMAKE_CONFIGURATION_TYPES
    # is defined.
    set(CMAKE_BUILD_TYPE Debug)
    cpfGetConfigVariableSuffixes(suffixes)
    cpfAssertListsEqual( "${suffixes}" "DEBUG" )

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
    cpfAssertStrEQ("${commitIdOut}" "")

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
    
    list(GET valueListsOut 0 listName0 )
    cpfAssertStrEQ(${listName0} "multikeyArgs0")
    cpfAssertListsEqual( "${${listName0}}" "bli;bla;blab" )

    list(GET valueListsOut 1 listName1 )
    cpfAssertStrEQ(${listName1} "multikeyArgs1")
    cpfAssertListsEqual( "${${listName1}}" "bar;;booze" )

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetCommitsSinceLastRelease )

	set( version 1.2.3.123-ab325-dirty )
	cpfGetCommitsSinceLastRelease( commitNr ${version} )
	cpfAssertStrEQ(${commitNr} "123")

	set( version 1.2.3.4874-43325 )
	cpfGetCommitsSinceLastRelease( commitNr ${version} )
	cpfAssertStrEQ(${commitNr} "4874")

	set( version 1.0.0 )
	cpfGetCommitsSinceLastRelease( commitNr ${version} )
	cpfAssertStrEQ(${commitNr} "0")

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfGetRequiredPackageOption )

    # Setup
    set(package MyPackage)
    set(component MyComponent)
    
    # Execute
    
    # Check that global CPF option is picked up.
    set(CPF_MY_OPTION bla)
    cpfGetRequiredPackageComponentOption(var ${package} ${component} MY_OPTION)
    cpfAssertStrEQ(${var} bla)

    # Check that package wide variable takes precedence
    # over the global one.
    set(MyPackage_MY_OPTION blub)
    cpfGetRequiredPackageComponentOption(var ${package} ${component} MY_OPTION)
    cpfAssertStrEQ(${var} blub)

    # Check that the package-component wide variable takes
    # precedence over the global and the package wide ones.
    set(MyPackage_MyComponent_MY_OPTION foo)
    cpfGetRequiredPackageComponentOption(var ${package} ${component} MY_OPTION)
    cpfAssertStrEQ(${var} foo)
    
    # Check that the function argument takes
    # precedence over all the variables.
    set(ARG_MY_OPTION bar)
    cpfGetRequiredPackageComponentOption(var ${package} ${component} MY_OPTION)
    cpfAssertStrEQ(${var} bar)

endfunction()
