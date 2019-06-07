# This module contains functions that help with testing

include(cpfMiscUtilities)

#----------------------------------------------------------------------------------------
# Fails if var1 and var2 are not equal
# Set arguments by variable name, not by value.
function( cpfAssertStrEQ var1 var2 )
    if( NOT "${var1}" STREQUAL "${var2}")
        message( FATAL_ERROR "Test assertion failed! Values not equal. Left: ${var1}, Right: ${var2}" )
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Fails if the length of the given list has not the expectedLength
function(cpfAssertListLength list expectedLength)
    cpfListLength( length "${list}")
    if( NOT ${length} EQUAL ${expectedLength})
        message( FATAL_ERROR "Test assertion failed! List did not have the expected length ${expectedLength}. {${list}}" )
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Checks if all elements have string equality and the lists are of same length
function( cpfAssertListsEqual list1 list2)

    set(errorMessage "Test assertion failed! Lists are not equal. Left: {${list1}}, Right: {${list2}}")

    cpfListLength( length1 "${list1}")
    cpfListLength( length2 "${list2}")
    if(NOT length1 EQUAL length2)
        message( FATAL_ERROR "${errorMessage}")
    endif()

    set(index 0)
    while( ${index} LESS ${length1} )
        list(GET list1 ${index} element1)
        list(GET list2 ${index} element2)
        if(NOT "${element1}" STREQUAL "${element2}")
            message( FATAL_ERROR "${errorMessage}")
        endif()
        cpfIncrement(index)
    endwhile()

endfunction()

#----------------------------------------------------------------------------------------
#
function( cpfAssertListsHaveSameLength list1 list2 )
	
	cpfListLength(length1 "${list1}" )
	cpfListLength(length2 "${list2}" )
	if(NOT ${length1} EQUAL ${length2})
		message(FATAL_ERROR "Lists are not of same length as required.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Fails if the value of the variable is not TRUE.
# The argument must be given by variable name.
function( cpfAssertTrue var )
    if(NOT ${var})
        message(FATAL_ERROR "Test assertion failed! Variable value was not TRUE.")
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Fails if the value of the variable is not FALSE.
# The argument must be given by variable name.
function( cpfAssertFalse var )
    if(${var})
        message(FATAL_ERROR "Test assertion failed! Variable value was not FALSE.")
    endif()
endfunction()