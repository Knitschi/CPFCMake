# This file contains tests for the cpfNumericUtilities module

include(cpfNumericUtilities)
include(cpfTestUtilities)

#----------------------------------------------------------------------------------------
# Runs all tests from this file
function( cpfRunNumericUtilitiesTests )

    test_cpfMax()
    test_cpfIncrement()
    test_cpfDecrement()

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfMax )

    # left > right
    cpfMax( max 2 -1)
    cpfAssertStrEQ(${max} 2)

    # left < right
    cpfMax( max -2 -1)
    cpfAssertStrEQ(${max} -1)

    # left == right
    cpfMax( max 0 0)
    cpfAssertStrEQ(${max} 0)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfIncrement )

    set(incrementedValue 0)
    cpfIncrement(incrementedValue)
    cpfAssertStrEQ(${incrementedValue} 1)

endfunction()

#----------------------------------------------------------------------------------------
function( test_cpfDecrement )

    set(incrementedValue 0)
    cpfDecrement(incrementedValue)
    cpfAssertStrEQ(${incrementedValue} -1)

endfunction()
