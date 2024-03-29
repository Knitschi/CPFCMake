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

	endif()

	if(CPF_ENABLE_CLANG_FORMAT_TARGETS)

		if(NOT CPF_CLANG_FORMAT_EXE)
			set(CPF_CLANG_FORMAT_EXE clang-format)
		endif()

		# Find clang-format
		cpfGetClangFormatSearchPaths(clangFormatPaths)
		cpfFindRequiredProgram( TOOL_CLANG_FORMAT ${CPF_CLANG_FORMAT_EXE} "A tool that formats .cpp and .c files." "${clangFormatPaths}")
	endif()

	if(Qt5Gui_FOUND )
		cpfFindRequiredProgram( 
			TOOL_UIC uic
			"A tool from the Qt framework that generates ui_*.h files from *.ui GUI defining xml files"
			"${Qt5_DIR}/../../../bin"
			)
	endif()

	# python is optional
	find_program(Python3_Interpreter NAMES python python3 HINTS ${Python3_DIR})
	if(Python3_Interpreter)
		cpfExecuteProcess(pythonVersion "\"${Python3_Interpreter}\" --version" "")
		# Get the pure version number from the returned string.
		cpfRightSideOfString( pythonVersion ${pythonVersion} 7)
		if(${pythonVersion} VERSION_GREATER_EQUAL 3.0.0)
			set(TOOL_PYTHON3 "${Python3_Interpreter}" CACHE PATH "The used python3 interpreter.")
		endif()
	endif()

endfunction()

#--------------------------------------------------------------------------------------
function( cpfGetClangFormatSearchPaths pathsOut )

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
		cpfNormalizeAbsPath( clangFormatPathVS2017 "${vsInstallPath}/Common7/IDE/VC/VCPackages")
		cpfNormalizeAbsPath( clangFormatPathVS2019 "${vsInstallPath}/VC/Tools/Llvm/bin")

		set(clangFormatPaths ${clangFormatPathVS2017} ${clangFormatPathVS2019})

    endif()

    set(${pathsOut} "${clangFormatPaths}" PARENT_SCOPE)

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

	# Get the tools version.
	if(CPF_VERBOSE)
		cpfExecuteProcess(
			stdOut "${${VAR}} --version" "" 
			IGNORE_ERROR
		)
		cpfDebugMessage("Found ${name} with version: ${stdOut}")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# The given var is only printed when the global CPF_VERBOSE option is set to ON.
# The function will prepend "-- [CPF] " to the given text so it can be identified
# as output from the CPFCMake code.
#
function( cpfDebugMessage var)
	if(CPF_VERBOSE)
		message("-- [CPF-DEBUG] ${var}")
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
# Helps to check whether a target exists during debugging.
function(devIsTarget target)
	if(NOT TARGET ${target})
		devMessage("${target} is missing.")
	else()
		devMessage("${target} exists.")
	endif()
endfunction()


#----------------------------------------------------------------------------------------
# This function can be used to get the values of options that can be defined with different
# global variables or with a key-word argument.
#
function(cpfGetRequiredPackageComponentOption optionOut package packageComponent optionKeyword)
	
	cpfGetOptionalPackageComponentOption(option ${package} ${packageComponent} ${optionKeyword} "")
	if("${option}" STREQUAL "")
		message(FATAL_ERROR "Error! Missing variable option. You need to set one of the following variables CPF_${optionKeyword}, ${package}_${optionKeyword}, ${package}_${packageComponent}_${optionKeyword} or the function key-word-argument.")
	endif()
	set(${optionOut} "${option}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Similar to cpfGetRequiredPackageComponentOption() but does not fail if neither of the variables
# is set. In this case it will return the provided default argument.
function(cpfGetOptionalPackageComponentOption optionOut package packageComponent optionKeyword defaultValue)
	
	if(NOT ("${ARG_${optionKeyword}}" STREQUAL ""))
		set(${optionOut} "${ARG_${optionKeyword}}" PARENT_SCOPE)
	elseif(NOT ("${${package}_${packageComponent}_${optionKeyword}}" STREQUAL ""))
		set(${optionOut} "${${package}_${packageComponent}_${optionKeyword}}" PARENT_SCOPE)
	elseif(NOT ("${${package}_${optionKeyword}}" STREQUAL ""))
		set(${optionOut} "${${package}_${optionKeyword}}" PARENT_SCOPE)
	elseif(NOT ("${CPF_${optionKeyword}}" STREQUAL ""))
		set(${optionOut} "${CPF_${optionKeyword}}" PARENT_SCOPE)
	else()
		set(${optionOut} "${defaultValue}" PARENT_SCOPE)
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Implements the mechanism that allows setting package and package-component specific values
# for certain CMake variables.
#
function( cpfSetPerPackageGlobalCMakeVariables package )

	cpfGetPerPackageCMakeVariables(cmakeVariables)

	foreach(variable ${cmakeVariables})
		if(NOT ("${${package}_${variable}}" STREQUAL ""))
			set(${variable} "${${package}_${variable}}" PARENT_SCOPE)
		endif()
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# Implements the mechanism that allows setting package and package-component specific values
# for certain CMake variables.
#
function( cpfSetPerComponentGlobalCMakeVariables package packageComponent )

	cpfGetPerPackageCMakeVariables(cmakeVariables)

	foreach(variable ${cmakeVariables})
		if(NOT ("${${package}_${packageComponent}_${variable}}" STREQUAL ""))
			set(${variable} "${${package}_${packageComponent}_${variable}}" PARENT_SCOPE)
		endif()
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# Defines all CMake variables that can be set per package or package-component.
function( cpfGetPerPackageCMakeVariables variablesOut )

	set(cmakeVariables 
		BUILD_SHARED_LIBS
		CMAKE_ARCHIVE_OUTPUT_DIRECTORY
		CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY
		CMAKE_LIBRARY_OUTPUT_DIRECTORY
		CMAKE_PDB_OUTPUT_DIRECTORY
		CMAKE_RUNTIME_OUTPUT_DIRECTORY
	)

	set(cmakeVariablesConfig
		CMAKE_ARCHIVE_OUTPUT_DIRECTORY_config
		CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY_config
		CMAKE_config_POSTFIX
		CMAKE_LIBRARY_OUTPUT_DIRECTORY_config
		CMAKE_PDB_OUTPUT_DIRECTORY_config
		CMAKE_RUNTIME_OUTPUT_DIRECTORY_config
	)

	cpfGetConfigVariableSuffixes(suffixes)
	foreach(configVariable ${cmakeVariablesConfig})
		foreach(suffix ${suffixes})
			string(REPLACE config ${suffix} ${configVariable} variable ${configVariable})
			cpfListAppend(cmakeVariables ${variable})
		endforeach()
	endforeach()

	set(${variablesOut} ${cmakeVariables} PARENT_SCOPE)

endfunction()


#----------------------------------------------------------------------------------------
# A common variant of executing a process that will cause an cmake error when the command fails.
# You can add an optional argument PRINT to display the output of the command.
# Note that the function strips trailing whitespaces (line-endings) from the output.
# Arguments:
# PRINT			The output of the command will be printed.
# IGNORE_ERROR  Set this to not cause cmake to fail when the command fails.
#
function( cpfExecuteProcess stdOut commandString workingDir)

	cmake_parse_arguments(ARG "PRINT;DONT_INTERCEPT_OUTPUT;IGNORE_ERROR" "" "" ${ARGN})

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

	if((NOT ${resultValue} STREQUAL 0) AND (NOT ARG_IGNORE_ERROR))
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



