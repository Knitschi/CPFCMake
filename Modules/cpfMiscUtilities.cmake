# This file contains small helper functions that do not fit in any other category

include_guard(GLOBAL)

#---------------------------------------------------------------------------------------------
# This function will find all the tools that are required to build all the custom
# targets of a CMakeProjectFramework package.
# The function will populate the TOOL_<exe> cache entries.
#
function( cpfFindRequiredTools )

	if(CPF_ENABLE_CLANG_TIDY_TARGET)
		cpfGetCompiler(compiler)
		if( ${compiler} STREQUAL Clang)
			
			if(NOT CPF_CLANG_TIDY_EXE)
				set(CPF_CLANG_TIDY_EXE clang-tidy)
			endif()
			cpfFindRequiredProgram(TOOL_CLANG_TIDY ${CPF_CLANG_TIDY_EXE} "A tool from the LLVM project that performs static analysis of cpp code" "")
		
		endif()
		cpfFindRequiredProgram( TOOL_ACYCLIC acyclic "A tool from the graphviz library that can check if a graphviz graph is acyclic" "")
	endif()

	if(CPF_ENABLE_CLANG_FORMAT_TARGETS)

		if(NOT CPF_CLANG_FORMAT_EXE)
			set(CPF_CLANG_FORMAT_EXE clang-format)
		endif()

		# Find clang-format
		cpfGetClangFormatSearchPath(clangFormatPath)
		cpfFindRequiredProgram( TOOL_CLANG_FORMAT ${CPF_CLANG_FORMAT_EXE} "A tool that formats .cpp and .c files." "${clangFormatPath}")
	endif()

	if(Qt5Gui_FOUND )
		cpfFindRequiredProgram( 
			TOOL_UIC uic
			"A tool from the Qt framework that generates ui_*.h files from *.ui GUI defining xml files"
			"${Qt5_DIR}/../../../bin"
			)
	endif()

	# python is optional
	find_package(PythonInterp 3)
	if(PYTHONINTERP_FOUND AND PYTHON_VERSION_MAJOR STREQUAL 3)
		set(TOOL_PYTHON3 "${PYTHON_EXECUTABLE}" CACHE PATH "The used python3 interpreter.")
	endif()

endfunction()

#--------------------------------------------------------------------------------------
function( cpfGetClangFormatSearchPath pathOut )

    if(MSVC)
        cpfNormalizeAbsPath( vswherePath "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer")
        cpfFindRequiredProgram( TOOL_VSWHERE vswhere "A tool that finds visual studio installations." "${vswherePath}")
		execute_process( 
			COMMAND "${vswherePath}/vswhere.exe" -property installationPath 
			OUTPUT_VARIABLE vswhereOutput
			)
		string(STRIP "${vswhereOutput}" vswhereOutput)
		
		# Use the latest installation, which is the last element in the output.
		cpfSplitString( outputList "${vswhereOutput}" "\n")
		cpfPopBack(vsInstallPath dummy "${outputList}")
		cpfNormalizeAbsPath( clangTidyPath "${vsInstallPath}/Common7/IDE/VC/VCPackages")

    endif()

    set(${pathOut} "${clangTidyPath}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# calls find_programm and triggers an fatal assertion if the program is not found
function( cpfFindRequiredProgram VAR name comment hints)

	find_program(
		${VAR} ${name} 
		HINTS ${hints}
		DOC ${comment}
		)
	
    if( ${${VAR}} STREQUAL ${VAR}-NOTFOUND )
        message( FATAL_ERROR "The required program \"${name}\" could not be found.\nThe following search-paths were given: ${hints}" )
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
# This function will set the value of a variable if it is not already set.
#
function( cpfSetIfNotSet variable value )
	if("${${variable}}" STREQUAL "")
		set(${variable} "${value}" PARENT_SCOPE)
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

	separate_arguments(commandList NATIVE_COMMAND "${commandString}")
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
			cpfListAppend( variableNames ${variableName})
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
# The returned valueListsOut contains a list of listnames that contain the values that where preceeded
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
	foreach( arg IN LISTS argumentList )

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

#----------------------------------------------------------------------------------------
# This function does a COPY_ONLY file configure if the target file does not exist yet.
# This function can be used when the created file should not be overwritten when
# the template file changes.
function( configureFileIfNotExists templateFile targetFile )
	if(NOT EXISTS ${targetFile} )
		# we use the manual existance check to prevent overwriting the file when the template changes.
		configure_file( ${templateFile} ${targetFile} COPYONLY )
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# A version of the configure_file() function that asserts that all given variables have
# values when the function is called. This is supposed to prevent errors where configure_file()
# is broken because variables that are used in the configured file are renamed.
#
function( cpfConfigureFileWithVariables input output variables )
	foreach( variable ${variables})
		cpfAssertDefined(${variable})
	endforeach()
	configure_file( "${input}" "${output}" )
endfunction()


