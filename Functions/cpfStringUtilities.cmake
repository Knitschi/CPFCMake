# This file contains functions that operate on strings

include_guard(GLOBAL)

include(cpfListUtilities)

#----------------------------------------------------------------------------------------
# Returns TRUE if the two strings are equal, otherwise FALSE
#
function( cpfStrequal equalOut string1 string2)
	set(equal FALSE)
	if(${string1} STREQUAL ${string2})
		set(equal TRUE)
	endif()
	set(${equalOut} ${equal} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Splits the given string into substrings at the location of the separator char
# The separator will not be contained in the returned substrings
# 
function( cpfSplitString VAR string separator)
	string(REPLACE "${separator}" ";" list ${string})
	set(${VAR} "${list}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Splits the given string into substrings at the location where white-spaces occur
# Multiple contiguous white-spaces do not lead to empty list elements.
# 
function( cpfSplitStringAtWhitespaces substringsOut string)
	string(STRIP ${string} string )
	string(REGEX REPLACE "[\\\n\\\t\\\r ]+" ";" list ${string})
	set(${substringsOut} ${list} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Joins the elements of the given list into one string were the elements are separated
# by separator
# 
function( cpfJoinString VAR list separator )
	string(REPLACE ";" "${separator}" joinedString "${list}")
	set(${VAR} ${joinedString} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Takes a list of strings and prepends the prefix to all elements.
#
function( cpfPrependMulti outputList prefix inputList )

	set(outLocal)
	foreach( string IN LISTS inputList )
		cpfListAppend( outLocal "${prefix}${string}")
	endforeach()
	set(${outputList} ${outLocal} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Returns the right side of the given string starting with the given index
#
function( cpfRightSideOfString ret string index)

	string(LENGTH ${string} length)
	math(EXPR lengthRighSide "${length} - ${index}")
	string(SUBSTRING ${string} ${index} ${lengthRighSide} rightSide)
	set(${ret} ${rightSide} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function removes removedLength characters from the end of the string
function( cpfStringRemoveRight stringOut string removedLength )
	string(LENGTH ${string} length)
	math(EXPR remainingLength "${length} - ${removedLength}")
	if( ${remainingLength} LESS 0 )
		message( FATAL_ERROR "Error in function cpfStringRemoveRight(). Tried to remove ${removeLength} characters form string \"${string}\" which only has ${length} characters")
	endif()
	string( SUBSTRING ${string} 0 ${remainingLength} leftString )
	set( ${stringOut} ${leftString} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function takes two strings and returns the one that has fewer characters
function( cpfGetShorterString stringOut string1 string2 )
	string(LENGTH "${string1}" length1)
	string(LENGTH "${string2}" length2)
	if( ${length2} LESS ${length1})
		set( ${stringOut} ${string2} PARENT_SCOPE)
	else()
		set( ${stringOut} ${string1} PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
function( cpfStringContains containsOut string )

	string(FIND "${string}" -dirty index)
	if(${index} EQUAL -1)
		set(${containsOut} FALSE PARENT_SCOPE)
	else()
		set(${containsOut} TRUE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# returns true if the given string contains a generator expression which is defined by the $<...> bracket.
#
function( cpfContainsGeneratorExpressions output string )

	string(FIND "${string}" "$<" index)
	if( ${index} GREATER -1 )
		set( ${output} TRUE PARENT_SCOPE)
	else()
		set( ${output} FALSE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Causes a fatal error if the string contains a generator expression
#
function( cpfAssertContainsNoGeneratorExpressions string message )

	cpfContainsGeneratorExpressions( contains ${string})
	if(contains)
		message(FATAL_ERROR "${massage}")
	endif()

endfunction()
