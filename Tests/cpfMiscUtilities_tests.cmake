# This file contains tests for the cpfMiscUtilities module

include(cpfMiscUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunMiscUtilitiesTests )

    test_cpfAssertDefined()
    test_cpfAssertDefinedMessage()

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
    cpfAssertDefinedMessage( bliblibblibbliblbibli "it must be difened because bla bla bla")

endfunction()

#----------------------------------------------------------------------------------------
function( test_ )



endfunction()