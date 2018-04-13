# This file contains small helper functions that do not fit in any other category

#----------------------------------------------------------------------------------------
# call the correct version of separate_arguments depending on the current platform.
macro ( cpfSeparateArgumentsForPlatform listArg command)
	if(CMAKE_HOST_UNIX)
		separate_arguments(list UNIX_COMMAND "${command}")
	elseif(CMAKE_HOST_WIN32)
		separate_arguments(list WINDOWS_COMMAND "${command}")
	else()
		message(FATAL_ERROR "Function cpfSeparateArgumentsForPlatform() needs to be extended for the current host platform.")
	endif()
	set(${listArg} ${list})
endmacro()

#----------------------------------------------------------------------------------------
# calls find_programm and triggers an fatal assertion if the program is not found
function( cpfFindRequiredProgram VAR name comment)

    find_program(${VAR} ${name} DOC ${comment})
    if( ${${VAR}} STREQUAL ${VAR}-NOTFOUND )
        message( FATAL_ERROR "The required program \"${name}\" could not be found." )
    endif()

endfunction()

#----------------------------------------------------------------------------------------
# The given var is only printed when the global CPF_VERBOSE option is set to ON.
# The function will prepend "-- [CPF] " to the given text so it can be identified
# as output from the CPFCMake code.
#
function( cpfDebugMessage var)
	if(CPF_VERBOSE)
		message("-- [CPF] ${var}")
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# This print function prepends "------------------" to the printed variable and is
# supposed to be used for temporary debug output while developing the CPFCMake code.
function( devMessage var)
	message("------------------ ${var}")
endfunction()

#----------------------------------------------------------------------------------------
function( devMessageList list)
    foreach( element IN LISTS list)
        devMessage("${element}")
    endforeach()
endfunction()

#----------------------------------------------------------------------------------------
# Takes a variable by name and asserts that it is defined.
#
function( cpfAssertDefined variableName )
	if(NOT DEFINED ${variableName})
		message(FATAL_ERROR "Assertion failed! Variable ${variableName} was not defined.}")
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Takes a variable by name and asserts that it is defined and prints the given message if not.
#
function( cpfAssertDefinedMessage variableName message )
	if(NOT DEFINED ${variableName})
		message(FATAL_ERROR "${message}")
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# This function can be used at the beginning of a script to check whether a variable
# was set as a script argument.
function( cpfAssertScriptArgumentDefined variableName )
	
	if(NOT DEFINED CMAKE_SCRIPT_MODE_FILE)
		message(FATAL_ERROR "Function cpfAssertScriptArgumentDefined() is supposed to used in .cmake files that are run in script mode \"cmake -P file\".")
	endif()
	
	if(NOT DEFINED ${variableName})
		get_filename_component(shortName "${CMAKE_SCRIPT_MODE_FILE}" NAME)
		message(FATAL_ERROR "Script \"${shortName}\" requires the -D${variableName}=<value> option.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# A version of the configure_file() function that asserts if the given variables
# contain no values when the function is called.
#
function( cpfConfigureFileWithVariables input output variables )
	foreach( variable ${variables})
		cpfAssertDefined(${variable})
	endforeach()
	configure_file( "${input}" "${output}" )
endfunction()

#----------------------------------------------------------------------------------------
function( cpfIsSingleConfigGenerator var )

	if(CMAKE_CONFIGURATION_TYPES)
		set( ${var} FALSE PARENT_SCOPE)
	else()
		set( ${var} TRUE PARENT_SCOPE)
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# Takes a list of targets and returns only the targets that have a given property set to a given value.
# An empty string "" for value means, that the property should not be set.
function( cpfFilterInTargetsWithProperty output targets property value )

	set(filteredTargets)

	foreach( target ${targets})
		get_property(isValue TARGET ${target} PROPERTY ${property})
		if( NOT isValue ) # handle special case "property not set"
			if( NOT value)
				list(APPEND filteredTargets ${target})
			endif()
		elseif( "${isValue}" STREQUAL "${value}")
			list(APPEND filteredTargets ${target})
		endif()
	endforeach()

	set(${output} "${filteredTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# The inverse of cpfFilterInTargetsWithProperty()
function( cpfFilterOutTargetsWithProperty output targets property value )

	set(filteredTargets)

	foreach( target ${targets})
		cpfFilterInTargetsWithProperty( hasProperty "${target}" ${property} ${value})
		if(NOT hasProperty)
			list(APPEND filteredTargets ${target})
		endif()
	endforeach()

	set(${output} "${filteredTargets}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list of _DEBUG;_RELEASE;etc when using multi-config generators or an empty value otherwise
#
function( cpfGetConfigVariableSuffixes suffixes)
	
	if(CMAKE_CONFIGURATION_TYPES)
		foreach(config ${CMAKE_CONFIGURATION_TYPES})
			cpfToConfigSuffix( suffix ${config})
			list(APPEND endings ${suffix})
		endforeach()
	else()
		if(CMAKE_BUILD_TYPE)
			cpfToConfigSuffix( suffix ${CMAKE_BUILD_TYPE})
			list(APPEND endings ${suffix})
		else()
			list(APPEND endings " ")
		endif()
	endif()
	set(${suffixes} "${endings}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfToConfigSuffix suffix config)

	string(TOUPPER ${config} upperConfig)
	set(${suffix} _${upperConfig} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the possible configurations in which the project can be build
function( cpfGetConfigurations configs )

	if(CMAKE_CONFIGURATION_TYPES)
		set( ${configs} ${CMAKE_CONFIGURATION_TYPES} PARENT_SCOPE)
	elseif(CMAKE_BUILD_TYPE)
		set( ${configs} ${CMAKE_BUILD_TYPE} PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Either CMAKE_CONFIGURATION_TYPES or CMAKE_BUILD_TYPE should be set.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# A common variant of executing a process that will cause an cmake error when the command fails.
# You can add an optional argument PRINT to display the output of the command.
# Note that the function strips trailing whitespaces (line-endings) from the output.
#
function( cpfExecuteProcess stdOut commandString workingDir)

	cmake_parse_arguments(ARG "PRINT;DONT_INTERCEPT_OUTPUT" "" "" ${ARGN})

	if(NOT ARG_DONT_INTERCEPT_OUTPUT)
		set( ouputInterceptArguments 
			OUTPUT_VARIABLE textOutput
			ERROR_VARIABLE errorOutput
		) 
	endif()

	cpfSeparateArgumentsForPlatform( commandList ${commandString})
	execute_process(
		COMMAND ${commandList}
		WORKING_DIRECTORY "${workingDir}"
		RESULT_VARIABLE resultValue
		${ouputInterceptArguments}
	)

	if(ARG_PRINT)
		message("${textOutput}")
	endif()

	if(NOT ${resultValue} STREQUAL 0)
		# print all the output if something went wrong.
		if(NOT ARG_PRINT)
			message("${textOutput}")
		endif()
		message("${errorOutput}")
		message("Working directory: \"${workingDir}\"")
		message(FATAL_ERROR "Command failed: \"${commandString}\"")
	endif()

	string(STRIP "${textOutput}" textOutput)
	set( ${stdOut} ${textOutput} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# assumes that version and has the form 123.12.123 and returns the first number as major version,
# the second number as minor version and the last number as numberOfCommits
# 
function( cpfSplitVersion majorOut minorOut patchOut commitIdOut versionString)
	
	cpfSplitString( versionList ${versionString} ".")
	list(GET versionList 0 majorVersion)
	list(GET versionList 1 minorVersion)
	list(GET versionList 2 patchNr)

	set(${majorOut} ${majorVersion} PARENT_SCOPE)
	set(${minorOut} ${minorVersion} PARENT_SCOPE)
	set(${patchOut} ${patchNr} PARENT_SCOPE)

	cpfListLength(length "${versionList}" )
	if( ${length} GREATER 3 )
		list(GET versionList 3 commitsNr)
		set( ${commitIdOut} ${commitsNr} PARENT_SCOPE)
	else()
		set( ${commitIdOut} "" PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the version number misses the 4th commits number.
# 
function( cpfIsReleaseVersion isReleaseOut version)
	cpfSplitVersion( d d d commits ${version})
	if("${commits}" STREQUAL "")
		set( ${isReleaseOut} TRUE PARENT_SCOPE)
	else()
		set( ${isReleaseOut} FALSE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# This function prints all currently set variables.
#
function( cpfPrintVariables )
	get_cmake_property(_variableNames VARIABLES)
	foreach (_variableName ${_variableNames})
		message(STATUS "${_variableName}=${${_variableName}}")
	endforeach()
endfunction()

#----------------------------------------------------------------------------------------
# This function can be called at the beginning of a .cmake file that is executed in script mode.
# It will then return the names of the variables that where given to the script with the -D option
function( cpfGetScriptDOptionVariableNames variablesOut )

	set(argIndex 0)
	set(variableNames)
	while( DEFINED CMAKE_ARGV${argIndex})
		set(argument "${CMAKE_ARGV${argIndex}}")

		string(SUBSTRING ${argument} 0 2 argStart)
		if( "${argStart}" STREQUAL "-D" )

			string(FIND "${argument}" "=" separatorIndex)
			math(EXPR variableNameLength "${separatorIndex} - 2")
			string(SUBSTRING "${argument}" 2 ${variableNameLength} variableName)
			list(APPEND variableNames ${variableName})
		endif()

		cpfIncrement(argIndex)
	endwhile()

	set( ${variablesOut} "${variableNames}" PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
# returns true if the given variable name belongs to a chache variable
function( cpfIsCacheVariable isCacheVarOut variableName )
	get_property( type CACHE ${variableName} PROPERTY TYPE )
	if( ${type} STREQUAL UNINITIALIZED)
		set( ${isCacheVarOut} FALSE PARENT_SCOPE)
	else()
		set( ${isCacheVarOut} TRUE PARENT_SCOPE)
	endif()
endfunction()


#----------------------------------------------------------------------------------------
# This function extracts value lists from keyword based argument lists where one keyword can occur
# multiple times. 
# The returned valueListsOut cpfContains a list of listnames that contain the values that where preceeded
# by the valueListsKeyword.
# valueListsOut:		Elements of this list must be dereferenced twice to get the actual list.
# valueListsKeyword: 	The keyword that can be used multiple times.
# otherKeywords: 		The other keywords in the function signature.
# argumentList:			The complete list of arguments given to the function.
# outputListBaseName:	The base name for the lists in valueListsOut. This should be some name that is not used by any other variable in the calling scope.
#
function( cpfGetKeywordValueLists valueListsOut valueListsKeyword otherKeywords argumentList outputListBaseName )

	list(REMOVE_ITEM otherKeywords ${valueListsKeyword})

	set(currentBelongsToSublist FALSE)
	set(listNameIndex 0)
	foreach( arg ${argumentList} )

		if( "${arg}" STREQUAL ${valueListsKeyword} )
			set( currentBelongsToSublist TRUE)
			set( currentList ${outputListBaseName}${listNameIndex} ) 
			list( APPEND subLists ${currentList} )
			cpfIncrement(listNameIndex)
		else()
			cpfContains( isOtherKeyword "${otherKeywords}" "${arg}" )
			if(isOtherKeyword)
				set( currentBelongsToSublist FALSE)
			else() # it is an argument value
				if( currentBelongsToSublist )
					list( APPEND ${currentList} "${arg}" )
				endif()
			endif()
		endif()
		
	endforeach()
	
	set( ${valueListsOut} "${subLists}" PARENT_SCOPE)
	foreach( subList ${subLists})
		set( ${subList} "${${subList}}" PARENT_SCOPE )
	endforeach()

endfunction()
