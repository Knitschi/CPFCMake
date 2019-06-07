# This file contains functions that execute numeric operations

include_guard(GLOBAL)

#----------------------------------------------------------------------------------------
# returns the maximum of both numbers
function( cpfMax VAR first second)
	if( ${first} LESS ${second})
		set(${VAR} ${second} PARENT_SCOPE)
	else()
		set(${VAR} ${first} PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# increments the given number by one
function(cpfIncrement VAR)
	set(varPrivate ${${VAR}})
	math( EXPR varPrivate "${varPrivate} + 1")
	set( ${VAR} ${varPrivate} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# decrements the given number by one
function(cpfDecrement VAR)
	set(varPrivate ${${VAR}})
	math( EXPR varPrivate "${varPrivate} - 1")
	set( ${VAR} ${varPrivate} PARENT_SCOPE)
endfunction()