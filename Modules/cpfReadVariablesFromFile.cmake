include_guard(GLOBAL)

include(cpfStringUtilities)

# This module contains functions that are used to retrieve cmake variables and cache-variables that
# are defined in .cmake files.



#---------------------------------------------------------------------------------------------
# Returns the names, types, values and descriptions of cache variables that are defined in a given file.
# 
#
function( cpfGetCacheVariablesDefinedInFile variableNamesOut variableValuesOut variableTypesOut variableDescriptionsOut absFilePath )
	
	# get and store original chache state
	cpfReadCurrentCacheVariables( cacheVariablesBefore cacheValuesBefore cacheTypesBefore cacheDescriptionsBefore)

	# clear the cache so we can read all variables from the file
	cpfClearAllCacheVariables()

	# load cache variables from file
	include("${absFilePath}")
	cpfReadCurrentCacheVariables( cacheVariablesFile cacheValuesFile cacheTypesFile cacheDescriptionsFile)

	# clear the cache changes from the include
	cpfClearAllCacheVariables()

	# restore the cache from before the include
	set(index 0)
	foreach(variable ${cacheVariablesBefore})
		list(GET cacheValuesBefore ${index} value )
		list(GET cacheTypesBefore ${index} type )
		list(GET cacheDescriptionsBefore ${index} description )	
		set( ${variable} "${value}" CACHE ${type} "${description}" FORCE )
		cpfIncrement(index)
	endforeach()

	set( ${variableNamesOut} "${cacheVariablesFile}" PARENT_SCOPE)
	set( ${variableValuesOut} "${cacheValuesFile}" PARENT_SCOPE)
	set( ${variableTypesOut} "${cacheTypesFile}" PARENT_SCOPE)
	set( ${variableDescriptionsOut} "${cacheDescriptionsFile}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the names, values, types and descriptions of the currently defined cache variabls.
# For variable values that are lists, the function escapes the separation ; with on \
function( cpfReadCurrentCacheVariables variableNamesOut variableValuesOut variableTypesOut variableDescriptionsOut )

	get_cmake_property( cacheVariables CACHE_VARIABLES)
	rotateCacheVariableWithAllValuesToTheFront(cacheVariables "${cacheVariables}") # We have to do this to make sure we later do net append empty elements to empty lists.
	set(cacheValues)
	set(cacheTypes)
	set(cacheDescriptions)

	foreach(variable ${cacheVariables})

		# values
		cpfGetCacheVariableValues( value type helpString ${variable})
		
		cpfListLength(valueLength "${value}") 
		if( ${valueLength} GREATER 1) 
			# for lists one escape level is needed to get a list of lists
			cpfJoinString( escapedList "${value}" "\\\\;")
			list(APPEND cacheValues "${escapedList}")
		else()
			list(APPEND cacheValues "${value}")
		endif()
		list(APPEND cacheTypes ${type})
		list(APPEND cacheDescriptions "${helpString}")

	endforeach()

	# assert that all lists are of the same length
	cpfListLength(namesLength "${cacheVariables}" )
	cpfListLength(valuesLength "${cacheValues}" )
	cpfListLength(typesLength "${cacheTypes}" )
	cpfListLength(descriptionsLength "${cacheDescriptions}" )
	if(NOT ( (${namesLength} EQUAL ${valuesLength}) AND (${namesLength} EQUAL ${typesLength}) AND(${namesLength} EQUAL ${descriptionsLength}) ))
		message("Length names: ${namesLength}")
		message("Length values: ${valuesLength}")
		message("Length types: ${typesLength}")
		message("Length descriptions: ${descriptionsLength}")
		message(FATAL_ERROR "Not all cache variables have all properties defined in function readCurrentCacheVariables().")
	endif()

	set( ${variableNamesOut} "${cacheVariables}" PARENT_SCOPE)
	set( ${variableValuesOut} "${cacheValues}" PARENT_SCOPE)
	set( ${variableTypesOut} "${cacheTypes}" PARENT_SCOPE)
	set( ${variableDescriptionsOut} "${cacheDescriptions}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# The function goes through the list of cache variables and finds the first that has a value,
# a type and a helpsting. It puts this variable at the top of the returned list.
function( rotateCacheVariableWithAllValuesToTheFront variablesOut variables)

	set(index 0)
	foreach(variable ${variables})
		cpfGetCacheVariableValues( value type helpstring ${variable})
		if(value AND type AND helpstring)
			# exchange variables
			list(REMOVE_AT variables ${index})
			list(INSERT variables 0 ${variable})
			set(${variablesOut} "${variables}" PARENT_SCOPE)
			return()
		endif()
		cpfIncrement(index)
	endforeach()
	message(FATAL_ERROR "There was no cache variable that has all values defined.")

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetCacheVariableValues valueOut typeOut helpstringOut variable)

	set(${valueOut} ${${variable}} PARENT_SCOPE)
	get_property( type CACHE ${variable} PROPERTY TYPE )
	set(${typeOut} ${type} PARENT_SCOPE)
	get_property( helpString CACHE ${variable} PROPERTY HELPSTRING )
	set(${helpstringOut} ${helpString} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Removes all variables from the cache
#
function( cpfClearAllCacheVariables )
	get_cmake_property( cacheVariables CACHE_VARIABLES)
	foreach(variable ${cacheVariables})
		unset(${variable} CACHE)
	endforeach()
endfunction()

#---------------------------------------------------------------------------------------------
# Gets the names and values of all normal variables that are defined in the given file
function( cpfReadVariablesFromFile variablesOut valuesOut absFilePath )

	# Unset all variables so we can identify the ones that came from the include.
	cpfClearAllVariablesExcept("variablesOut;valuesOut;absFilePath")

	# Read the variables from the file.
	include("${absFilePath}")
	cpfReadCurrentVariables( variables values )

	set(${variablesOut} "${variables}" PARENT_SCOPE)
	set(${valuesOut} "${values}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Unsets all variables in the current scope.
function( cpfClearAllVariablesExcept notClearedVariables )

	get_cmake_property(variableNames VARIABLES)
	foreach(variable ${variableNames})
		cpfContains(isException "${notClearedVariables}" "${variable}" )
		if(NOT isException)
			unset(${variable} PARENT_SCOPE)
		endif()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the names, values, types and descriptions of the currently defined cache variabls.
# For variable values that are lists, the function escapes the separation ; with on \
function( cpfReadCurrentVariables variableNamesOut variableValuesOut )

	set(values)

	get_cmake_property(variableNames VARIABLES)
	foreach(variable ${variableNames})

		set(value ${${variable}})
		cpfListLength(valueLength "${value}") 
		if( ${valueLength} GREATER 1) 
			# for lists one escape level is needed to get a list of lists
			cpfJoinString( escapedList "${value}" "\\\\;")
			list(APPEND values "${escapedList}")
		else()
			list(APPEND values "${value}")
		endif()

	endforeach()

	set(${variableNamesOut} "${variableNames}" PARENT_SCOPE)
	set(${variableValuesOut} "${values}" PARENT_SCOPE)

endfunction()