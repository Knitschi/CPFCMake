

#----------------------------------------------------------------------------------------
# call the correct version of separate_arguments depending on the current platform
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

#----------------------------------------------------------------------------------------
# Removes the last element from the list and sets it to VAR
function( cpfPopBack VAR list)
	list(GET ${list} "-1" blib)
	set(${VAR} ${blib} PARENT_SCOPE)
	list(REMOVE_AT ${list} "-1")
	set(${list} ${${list}} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns the part left of the given index and the part right and including the given index
#
function( cpfSplitList outLeft outRight list splitIndex )
	
	set(index 0)
	foreach(element ${list})
		if(${index} LESS ${splitIndex})
			list(APPEND outLeftLocal ${element})
		else()
			list(APPEND outRightLocal ${element})
		endif()
		cpfIncrement(index)
	endforeach()

	set( ${outLeft} ${outLeftLocal} PARENT_SCOPE)
	set( ${outRight} ${outRightLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list of indexes in the list that contain the given value
#
function( cpfFindAllInList indexesOut list value)
	set(indexes)
	set(index 0)
	foreach(element ${list})
		if("${element}" STREQUAL "${value}" )
			list(APPEND indexes ${index})
		endif()
		cpfIncrement(index)
	endforeach()
	set(${indexesOut} "${indexes}" PARENT_SCOPE)
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
# Writes the name of the immediate parent folder to VAR
function ( cpfGetParentFolder output fileName )
	
	get_source_file_property( fullFilename ${fileName} LOCATION)
	get_filename_component( dir ${fullFilename} DIRECTORY)
	string(FIND ${dir} "/" dirSeparatorIndex REVERSE)	# get the index of the last directory separator
	# compute the length of the last directory name
	string(LENGTH ${dir} fullDirLength)
	math(EXPR folderNameStartIndex "${dirSeparatorIndex} + 1")
	math(EXPR lastNameLength "${fullDirLength} - ${folderNameStartIndex}")
	# get the substring of the last folder
	string(SUBSTRING ${dir} ${folderNameStartIndex} ${lastNameLength} folderName)
	# set the output variable
	set( ${output} ${folderName}  PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the names of the subdirectories within a given directory
# 
function( cpfGetSubdirectories dirsOut absDir )

  file(GLOB children RELATIVE ${absDir} ${absDir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${absDir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()

  set(${dirsOut} ${dirlist} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Checks if subdir is a subdirectory of dir.
# e.g.: subPath = C:/bla/blub/blib path = C:/bla  -> returns TRUE
#		subPath = C:/bla/blub/blib path = C:/bleb -> returns FALSE
#
# Note that pathes must use / as a separator.
function( cpfIsSubPath VAR subPath path)
	
	set(${VAR} FALSE PARENT_SCOPE )
	if("${subPath}" MATCHES "^${path}(.*)")
		set(${VAR} TRUE PARENT_SCOPE )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns the drive name on windows and / on linux. If the given path is relative
# VAR is set to NOTFOUND.
#
function( cpfGetPathRoot VAR absPath)

	string(SUBSTRING ${absPath} 0 1 firstChar)

	if(CMAKE_HOST_UNIX)

		if(NOT ${firstChar} STREQUAL /)
			set(${VAR} NOTFOUND PARENT_SCOPE)
			return()
		endif()
		set(${VAR} / PARENT_SCOPE)

	elseif(CMAKE_HOST_WIN32)

		string(SUBSTRING ${absPath} 1 1 secondChar)
		if(NOT ${secondChar} STREQUAL :)
			set(${VAR} NOTFOUND PARENT_SCOPE)
			return()
		endif()
		set(${VAR} ${firstChar} PARENT_SCOPE)

	else()
		message(FATAL_ERROR "Function cpfGetPathRoot() needs to be extended to work on the current host platform.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# returns true if the given path is absolute 
function( cpfIsAbsolutePath boolOut path)
	cpfGetPathRoot( root ${path})
	if( ${root} STREQUAL NOTFOUND )
		set( ${boolOut} FALSE PARENT_SCOPE)
	else()
		set( ${boolOut} TRUE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# removes .. dirUp directories from absolute paths.
function( cpfNormalizeAbsPath normedPathOut absPath)
	cpfGetPathRoot( root "${absPath}")
	get_filename_component( normedPath "${absPath}" ABSOLUTE BASE_DIR ${root} )
	set( ${normedPathOut} "${normedPath}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# returns multiple relative paths from the fromPath to the toPaths
function( cpfGetRelativePaths relPathsOut fromPath toPaths )
	set(relPaths)
	foreach( toPath ${toPaths})
		file(RELATIVE_PATH relPath ${fromPath} ${toPath})
		list(APPEND relPaths ${relPath})
	endforeach()
	set(${relPathsOut} ${relPaths} PARENT_SCOPE)
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
	foreach( string ${inputList} )
		list(APPEND outLocal "${prefix}${string}")
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
	string(LENGTH ${string1} length1)
	string(LENGTH ${string2} length2)
	if( ${length2} LESS ${length1})
		set( ${stringOut} ${string2} PARENT_SCOPE)
	else()
		set( ${stringOut} ${string1} PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Uses the baseString to create a list with N elements where the baseString has an appended
# index in each element like baseString_0;baseString_1;...;baseString_(length-1)
function( cpfCreateIndexdStringList list baseString length )

	set(index 0)
	set(localList)
	while( ${index} LESS ${length} )
		list(APPEND localList ${baseString}_${index})
		cpfIncrement(index)
	endwhile()
	set(${list} ${localList} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# returns true if the given string contains a generator expression
#
function( cpfContainsGeneratorExpressions output string )

	string(FIND ${string} "$<" index)
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

	cpfContainsGeneratorExpressions( cpfContains ${string})
	if(cpfContains)
		message(FATAL_ERROR "${massage}")
	endif()

endfunction()


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
# Takes a variable by name and asserts that it is defined.
#
function( cpfAssertDefined variableName )
	if(NOT DEFINED ${variableName})
		message(FATAL_ERROR "Assertion failed! Variable ${variableName} was not defined.}")
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
# Takes a variable by name and asserts that it is defined and prints the given message if not.
#
function( cpfAssertDefinedMessage variableName message )
	if(NOT DEFINED ${variableName})
		message(FATAL_ERROR "${message}")
	endif()
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
	if("${index}" STREQUAL -1)
		set(${ret} FALSE PARENT_SCOPE)
	else()
		set(${ret} TRUE PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns true if listLoockedIn cpfContains one of the elements of listSearchStrings
function( cpfContainsOneOf ret listLookedIn listSearchStrings)
	
	foreach( searchString ${listSearchStrings} )
		cpfContains( hasString "${listLookedIn}" ${searchString})
		if(hasString)
			set(${ret} TRUE PARENT_SCOPE)
			return()
		endif()
	endforeach()
	set(${ret} FALSE PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the first element in the list that matches the regular expression regex
function( cpfGetFirstMatch matchedElementOut list regex)
	
	foreach( element ${list} )
		if( "${element}" MATCHES "${regex}" )
			set(${matchedElementOut} "${element}" PARENT_SCOPE)
			return()
		endif()
	endforeach()
	set(${matchedElementOut} "" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the elements in list1 that can not be found in list2
function( cpfGetList1WithoutList2 differenceOut list1 list2)
	set(difference)
	foreach( element ${list1})
		cpfContains( isInList2 "${list2}" ${element})
		if(NOT isInList2)
			list(APPEND difference ${element})
		endif()
	endforeach()
	set( ${differenceOut} ${difference} PARENT_SCOPE)
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

