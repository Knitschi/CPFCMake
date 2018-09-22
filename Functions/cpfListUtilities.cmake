# This file contains functions that operate on lists
include_guard(GLOBAL)

include(cpfNumericUtilities)

#----------------------------------------------------------------------------------------
# Removes the last element from the list and sets it to VAR
function( cpfPopBack lastElementOut listOut list)
	list(GET list "-1" lastElement)
	set(${lastElementOut} ${lastElement} PARENT_SCOPE)
	list(REMOVE_AT list "-1")
	set(${listOut} "${list}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Does the same as cpfListAppend( ...) but fails if an empty value is added to an empty list.
# This is a problem because cmake currently can not have lists with one empty element.
# Argument list must be given by variable name (without dereference ${}).
function( cpfListAppend list_arg )

	# Handle add nothing case
	if( ${ARGC} EQUAL 1)
		return()
	endif()

	# Handle problematic case of adding an empty element to an empty list.
	# for some reason we have to dereference the arguments for the emptyness check in the conditional. Otherwise it does not work.
	set(list "${${list_arg}}")
	set(appendedElements "${ARGN}")
	if(NOT list AND ("${appendedElements}" STREQUAL ""))
		message(FATAL_ERROR "Failed to add an empty element to an empty list. CMake does not support lists with one empty element.")
	endif()
	
	# Do the normal append
	list(APPEND list "${appendedElements}")

	set(${list_arg} "${list}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Sets the element 
function( cpfListSet listOut list index value )
	list(INSERT list ${index} "${value}")
	cpfIncrement(index)
	list(REMOVE_AT list ${index})
	set(${listOut} "${list}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns the part left of the given index and the part right and including the given index
#
function( cpfSplitList outLeft outRight list splitIndex )
	
	set(index 0)
	foreach(element IN LISTS list)
		if(${index} LESS ${splitIndex})
			cpfListAppend( outLeftLocal "${element}")
		else()
			cpfListAppend( outRightLocal "${element}")
		endif()
		cpfIncrement(index)
	endforeach()

	set( ${outLeft} "${outLeftLocal}" PARENT_SCOPE)
	set( ${outRight} "${outRightLocal}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list of indexes in the list that contain the given value
#
function( cpfFindAllInList indexesOut list value)
	set(indexes)
	set(index 0)
	foreach(element IN LISTS list)
		if("${element}" STREQUAL "${value}" )
			cpfListAppend( indexes ${index})
		endif()
		cpfIncrement(index)
	endforeach()
	set(${indexesOut} "${indexes}" PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# In contrast to list(LENGTH ...) this function does not need any policies to be set and
# it does not ignore empty elements.
#
function( cpfListLength lengthOut list)
	set(counter 0)
	foreach( element IN LISTS list)
		cpfIncrement(counter)
	endforeach()
	set(${lengthOut} ${counter} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the given list cpfContains the given element
function( cpfContains ret list element)

	list(FIND list "${element}" index)
	if(${index} EQUAL -1)
		set(${ret} FALSE PARENT_SCOPE)
	else()
		set(${ret} TRUE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns true if listLoockedIn cpfContains one of the elements of listSearchStrings
function( cpfContainsOneOf ret listLookedIn listSearchStrings)
	
	foreach( searchString IN LISTS listSearchStrings )
		cpfContains( hasString "${listLookedIn}" "${searchString}")
		if(hasString)
			set(${ret} TRUE PARENT_SCOPE)
			return()
		endif()
	endforeach()
	set(${ret} FALSE PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the value of the first element in the list that matches the regular expression regex.
# If no element is matched it returns NOTFOUND
function( cpfGetFirstMatch matchedElementOut list regex)
	
	foreach( element IN LISTS list )
		if( "${element}" MATCHES "${regex}" )
			set(${matchedElementOut} "${element}" PARENT_SCOPE)
			return()
		endif()
	endforeach()
	set(${matchedElementOut} "NOTFOUND" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the elements in list1 that can not be found in list2
function( cpfGetList1WithoutList2 differenceOut list1 list2)
	set(difference)
	foreach( element IN LISTS list1)
		cpfContains( isInList2 "${list2}" "${element}")
		if(NOT isInList2)
			cpfListAppend( difference "${element}")
		endif()
	endforeach()
	set( ${differenceOut} "${difference}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetElementsMatching listOut list regexp )

	set(matchingElements)
	foreach(element ${list})
		if("${element}" MATCHES "${regexp}")
			cpfListAppend(matchingElements ${element})
		endif()
	endforeach()

	set(${listOut} "${matchingElements}" PARENT_SCOPE)

endfunction()