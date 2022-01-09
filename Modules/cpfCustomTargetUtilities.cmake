include_guard(GLOBAL)

include(cpfTestUtilities)


#----------------------------------------------------------------------------------------
# This function binds some commonly used arguments for the add_custom_command function
# to reduce code repetition.
# It only takes the DEPENDS OUTPUT and COMMANDS and COMMAND options.
# The COMMANDS option contains full commands as strings.
# [DEPENDS]				Note that for correct dependency propagation you need to depend on a target, and the files that it is producing.
# COMMAND				This can be used when the command is available as a list rather then a single string. This can be
#						be used multiple times to add multiple commands.
# [WORKING_DIRECTORY]	The current directory that is used when running the command. If defaults to CPF_ROOT_DIR
#
function( cpfAddStandardCustomCommand )

	set(singleValueKeywords WORKING_DIRECTORY )
	set(multiValueKeywords COMMANDS COMMAND DEPENDS OUTPUT)

	cmake_parse_arguments(ARG "" "${singleValueKeywords}" "${multiValueKeywords}" ${ARGN} )

	set(allKeywords ${singleValueKeywords} ${multiValueKeywords})
	cpfGetKeywordValueLists( commandOptionLists COMMAND "${allKeywords}" "${ARGN}" commandOptions)

	if(NOT ARG_WORKING_DIRECTORY)
		set(ARG_WORKING_DIRECTORY ${CPF_ROOT_DIR})
	endif()

	# Handle the one string commands
	set(commandArguments)
	set(comment)
	foreach(command ${ARG_COMMANDS})
		separate_arguments(argumentList NATIVE_COMMAND ${command})
		cpfListAppend( commandArguments COMMAND ${argumentList} )
		string(APPEND comment "${command} & ")
	endforeach()

	# Handle the string list commands
	foreach(listVariable ${commandOptionLists})
		cpfListAppend( commandArguments COMMAND ${${listVariable}} )
		cpfJoinString( commandString "${${listVariable}}" " ")
		string(APPEND comment "${commandString} & ")
	endforeach()
	
	add_custom_command(
		OUTPUT ${ARG_OUTPUT}
		DEPENDS ${ARG_DEPENDS}
		${commandArguments}
		WORKING_DIRECTORY ${ARG_WORKING_DIRECTORY}
		COMMENT ${comment}
		VERBATIM
	)
	
	set_source_files_properties(${ARG_OUTPUT} PROPERTIES GENERATED TRUE)

endfunction()

#-----------------------------------------------------------
# Creates a custom target with the common cpf properties.
#
function( cpfAddStandardCustomTarget )

	set( requiredSingleValueKeywords
		PACKAGE
		PACKAGE_COMPONENT
		TARGET
	)

	set( optionalSingleValueKeywords
		VS_SUBDIR
	)

	set( optionalMultiValueKeywords
		SOURCES
		TARGET_DEPENDENCIES
		PRODUCED_FILES
		INSTALL_COMPONENTS
	)

	cmake_parse_arguments(
		ARG 
		""
		"${requiredSingleValueKeywords};${optionalSingleValueKeywords}"
		"${optionalMultiValueKeywords}"
		${ARGN} 
	)

	cpfAssertKeywordArgumentsHaveValue( "${requiredSingleValueKeywords}" ARG "cpfAddStandardCustomTarget()")

    add_custom_target( 
        ${ARG_TARGET}
        SOURCES ${ARG_SOURCES}
        DEPENDS ${ARG_PRODUCED_FILES} ${ARG_TARGET_DEPENDENCIES}
	)
	
	# Set properties
	cpfGetComponentVSFolder(solutionFolder ${ARG_PACKAGE} ${ARG_PACKAGE_COMPONENT})
	if(ARG_VS_SUBDIR)
		string(APPEND solutionFolder /${ARG_VS_SUBDIR})
	endif()

	set_property( TARGET ${ARG_TARGET} PROPERTY FOLDER ${solutionFolder} )

	set_property( TARGET ${ARG_TARGET} PROPERTY CPF_OUTPUT_FILES ${ARG_PRODUCED_FILES} )
	set_property( TARGET ${ARG_TARGET} PROPERTY PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS ${ARG_INSTALL_COMPONENTS})
	cpfSetIDEDirectoriesForTargetSources(${ARG_TARGET})

	set_property( TARGET ${ARG_PACKAGE_COMPONENT} APPEND PROPERTY INTERFACE_CPF_PACKAGE_COMPONENT_SUBTARGETS ${ARG_TARGET})

endfunction()

#----------------------------------------------------------------------------------------
# Adds a custom command for copying a file from source to destination.
# Both should be absolute paths. 
function( cpfAddCustomCommandCopyFile source destination )

	cpfAddStandardCustomCommand(
		OUTPUT ${destination}
		DEPENDS ${source}
		COMMANDS "cmake -E copy \"${source}\" \"${destination}\""
	)

endfunction()

#----------------------------------------------------------------------------------------
# This function can be used when a custom target needs to add multiple lines to a file.
# The function creates a custom command for each line that is added to the file.
# The inputFile will be left unchanged, while the output file contains the added lines
# Arguments:
# INPUT The full name of the input text file. This file will be left unchanged.
# OUTPUT The full name of the generated file that will contain the contents of the INPUT plus the strings given with ADDED_LINES
# ADDED_LINES A list of strings that will be added as new lines at the end of the given INPUT file. Currently no empty lines can be added.
# DEPENDS A list of additional files on which the added commands should depend.
function( cpfAddAppendLinesToFileCommands)

	cmake_parse_arguments(ARG "" "INPUT;OUTPUT" "ADDED_LINES;DEPENDS" ${ARGN} )

	# The first command must depend on the inputFile while the last command must generate the output file to make the "dependency chain" work.
	# Intermediate commands use extra stamp files because we can have only one custom_command for each generated file.

	get_filename_component( stampFileDir ${ARG_OUTPUT} DIRECTORY)
	get_filename_component( editedFileWE ${ARG_OUTPUT} NAME_WE)
	get_filename_component( editedFileShort ${ARG_OUTPUT} NAME)
	set(stampFile ${stampFileDir}/${editedFileWE}_copy_project_config_file.stamp)
	
	# first copy the input file
	cpfAddStandardCustomCommand(
		OUTPUT ${stampFile}
		DEPENDS ${ARG_INPUT} ${ARG_DEPENDS}
		COMMANDS "cmake -E remove \"${ARG_OUTPUT}\"" "cmake -E copy \"${ARG_INPUT}\" \"${ARG_OUTPUT}\"" "cmake -E touch \"${stampFile}\""
	)
	
	# now add one command for each appended line except the last one
	cpfPopBack(lastLine ARG_ADDED_LINES "${ARG_ADDED_LINES}")
	set(lineIndex 0)
	set(dependency ${stampFile})
	foreach( line ${ARG_ADDED_LINES})
		
		set(command cmake;-E;echo;${line};>>;${ARG_OUTPUT} ) # using cmake -E echo makes sure that the echo command behaves the same on all platforms
		
		set(stampFile ${stampFileDir}/${editedFileWE}_add_line_${lineIndex}.stamp)

		# Note that for the echo command adding the VERBATIM option leads to incorrect behavior.
		# That is why we can not use the cpfAddStandardCustomCommand() function here
		add_custom_command(
			OUTPUT ${stampFile}
			DEPENDS ${dependency}
			COMMAND ${command}
			COMMAND cmake;-E;touch;${stampFile}
			VERBATIM
		)
		
		set(dependency ${stampFile})
		cpfIncrement(lineIndex)
	
	endforeach()
	
	# add a final command for the last line
	set(command cmake;-E;echo;${lastLine};>>;${ARG_OUTPUT})
	add_custom_command(
		OUTPUT ${ARG_OUTPUT}
		DEPENDS ${dependency}
		COMMAND ${command}
		VERBATIM
	)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a command that will write the given content to the given file.
# There will be one command for each line in fileContent.
function( cpfGetWriteFileCommands commandsOut absFilePath fileContent )
	
	set(commands)

	# delete file first, because we later append lines.
	list( APPEND commands COMMAND cmake -E remove -f "${absFilePath}")
	
	# Append lines one by one. I was not able to write the whole content in one go.
	cpfSplitString( lines ${fileContent} "\n" )
	foreach( line IN LISTS lines )
		list( APPEND commands COMMAND cmake -E echo "${line}" >> "${absFilePath}" )
	endforeach()

	set( ${commandsOut} ${commands} PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
# Adds a custom command that is only run when the given CONFIGS are build.
# The function wraps all elements in the arguments DEPENDS, COMMANDS and OUTPUT in 
# generator expressions of the form $<$<CONFIG:${configs}>:${element}>
#
# CONFIGS			A subset of the configurations that are defined with the CMAKE_CONFIGURATION_TYPES variable.
#					The custom command will only be run when the built configuration is one of the given configurations.
# DEPENDS			Equivalent to the add_custum_command(DEPENDS) argument.
# COMMANDS			A list of commands in string form. This is internally then separated into command lists.
# OUTPUT			Equivalent to the add_custum_command(DEPENDS) argument.
# [COMMENT]			If this is given, the given string is printed when the command is run. Otherwise a default
#					string is printed that contains the given commands.
#
function( cpfAddConfigurationDependendCommand )

	cmake_parse_arguments(
		ARG 
		"" 
		"COMMENT"
		"CONFIGS;DEPENDS;COMMANDS;OUTPUT"
		${ARGN} 
	)

	# Wrap the dependencies.
	cpfWrapInConfigGeneratorExpressions(dependsWrapped "${ARG_DEPENDS}" "${ARG_CONFIGS}")

	# Wrap the command lists in generator expressions.
	set(allCommandLists)
	foreach(command ${ARG_COMMANDS})
		separate_arguments(commandList NATIVE_COMMAND ${command})
		cpfWrapInConfigGeneratorExpressions(commandListWrapped "${commandList}" "${ARG_CONFIGS}")
		cpfListAppend(allCommandLists "COMMAND;${commandListWrapped}")
	endforeach()

	# Wrap the output.
	cpfWrapInConfigGeneratorExpressions(outputWrapped "${ARG_OUTPUT}" "${ARG_CONFIGS}")

	cpfAddStandardCustomCommand(
		DEPENDS ${dependsWrapped}
		${allCommandLists}
		OUTPUT ${outputWrapped}
		COMMENT ${ARG_COMMENT}
	)

endfunction()

#----------------------------------------------------------------------------------------
# This function creates a file that contains definitions for all the given variables with the given values.
# This is intended to be used to pass arguments to cmake scripts. This is a workaround for the problem
# that there is a limitation to the length of the argument string that can be passed to a script.
# In these cases we can pass the location of the argument file instead.
# Argument variableDefinitions		A list of variable definitions that are separated by the keyword  DEFINITION
#									All list elements must have the structure: DEFINITION VARIABLE <variable-name> VALUES <values> DEFINITION VARIABLE <variable-name> VALUES <values>
function( cpfSetupArgumentFile filenameOut target depends variableDefinitions )

	# create a unique argument file
	set( dir "${CMAKE_CURRENT_BINARY_DIR}/${target}")
    file( MAKE_DIRECTORY "${dir}")
	string(MD5 hash "${variableDefinitions}")
	set( filename "${dir}/argumentFile_${hash}.cmake" ) 

	set(commands)
	# make sure the previous argument file is removed because the later commands append lines to it
    list( APPEND commands COMMAND cmake -E remove -f "${filename}")

	set(definition)
	foreach(element ${variableDefinitions})
		if( "${element}" STREQUAL DEFINITION)
			if(definition) # do nothing when hitting the first keyword
				cpfAppendCommandsForVariableDefinition( commands "${definition}" "${filename}" )
			endif()
			# reset for next definition
			set(definition)
		else()
			cpfListAppend( definition ${element})
		endif()
	endforeach()

	# add the last definition
	if(definition)
		cpfAppendCommandsForVariableDefinition( commands "${definition}" "${filename}" )
	endif()

    add_custom_command(
		OUTPUT "${filename}"
		DEPENDS ${depends}
		${commands}
		VERBATIM
	)
    
    set(${filenameOut} "${filename}" PARENT_SCOPE)	

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAppendCommandsForVariableDefinition commandList definition filename )
	set( commandListLocal ${${commandList}})

	cmake_parse_arguments( "KEY" "" "VARIABLE" "VALUES" ${definition} )

	cpfAddAppendLineCommand( commandListLocal "set( ${KEY_VARIABLE}" ${filename} FALSE)
	foreach( value ${KEY_VALUES})
		cpfAddAppendLineCommand( commandListLocal "${value}" ${filename} TRUE)
	endforeach()
	cpfAddAppendLineCommand( commandListLocal ")" ${filename} FALSE)
	cpfAddAppendLineCommand( commandListLocal "" ${filename} FALSE)

	set(${commandList} ${commandListLocal} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddAppendLineCommand commandList line file isValue)
	set( commandListLocal ${${commandList}})
	
	# Add some empirically determined escape levels to get the special
    # characters into the created file.
    string(REPLACE "\\" "\\\\" line "${line}")
	string(REPLACE "\"" "\\\"" line "${line}")
	string(REPLACE "$<SEMICOLON>" "\\\\\\\\\\\\$<SEMICOLON>" line "${line}")

    if(isValue)
		set( line "    \"${line}\"")
    endif()
    
	set( command COMMAND ${CMAKE_COMMAND} -E echo "${line}" >> "${file}" )
	list( APPEND commandListLocal ${command})

	set(${commandList} ${commandListLocal} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTouchFileCommands commandsOut absFilePaths )

	set(commands)
	# get a list of directories that must be created.
	set(outputDirs)
	foreach( file ${absFilePaths} )
		get_filename_component(dir "${file}" DIRECTORY)		
		cpfListAppend( outputDirs ${dir})
	endforeach()
	list(REMOVE_DUPLICATES outputDirs)

	# add commands for creating these directories
	foreach( dir ${outputDirs} )
		cpfListAppend( commands "\"${CMAKE_COMMAND}\" -E make_directory \"${dir}\"")
	endforeach()

	# add commands for touching the files
	foreach( file ${absFilePaths})
		cpfListAppend( commands "\"${CMAKE_COMMAND}\" -E touch \"${file}\" ")
	endforeach()

	set( ${commandsOut} ${commands} PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTouchTargetStampCommand commandOut stampFileOut targetName)

	set(stampFile "${CMAKE_CURRENT_BINARY_DIR}/${targetName}.stamp")
	set(${commandOut} "\"${CMAKE_COMMAND}\" -E touch \"${stampFile}\"" PARENT_SCOPE)
	set(${stampFileOut} ${stampFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetClearDirectoryCommands commandsOut absDirPath )
	set( ${commandsOut} "\"${CMAKE_COMMAND}\" -E remove_directory \"${absDirPath}\"" "\"${CMAKE_COMMAND}\" -E make_directory \"${absDirPath}\"" PARENT_SCOPE )
endfunction()

#----------------------------------------------------------------------------------------
# Adds a custom command that will clear the content of the given directory except for the
# entries given in the notDeletedEntries variable.
function( cpfAddClearDirExceptCommand stampFileOut directory notDeletedEntries target dependedOnTargets)

	# we use the argument file mechanism to pass the file list to the script, because it can be a long list.
	set(variableDefinitions)
	cpfListAppend( variableDefinitions DEFINITION VARIABLE DIRECTORY VALUES ${directory} )
	cpfListAppend( variableDefinitions DEFINITION VARIABLE ENTRIES VALUES ${notDeletedEntries} )
	
	cpfPrependMulti(notDeletedEntriesFull "${directory}/" "${notDeletedEntries}")
    cpfSetupArgumentFile( argumentFile ${target} "${dependedOnTargets}" "${variableDefinitions}")

	set(stampFile "${CMAKE_CURRENT_BINARY_DIR}/${target}/clearLastBuild.stamp")
	
	cpfAddStandardCustomCommand(
		OUTPUT ${stampFile}
		DEPENDS ${argumentFile} # ${notDeletedEntriesFull}
		COMMENT "Clear directory \"${directory}\""
		COMMANDS "\"${CMAKE_COMMAND}\" -DARGUMENT_FILE=\"${argumentFile}\" -P \"${CPF_ABS_SCRIPT_DIR}/clearDirExcept.cmake\"" "\"${CMAKE_COMMAND}\" -E touch \"${stampFile}\""
	)

	set(${stampFileOut} ${stampFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Adds a custom command that executes cmake in script mode handing it the given D-options
# 
# dOptions must be a list in the form "ARG1=blub;OTHER_ARG=blab;THIRD_ARG=bleb".
#
function( cpfGetRunCMakeScriptCommand commandOut script dOptions )

	set(runScriptCommand "\"${CMAKE_COMMAND}\"")
	foreach(option ${dOptions})
		string(APPEND runScriptCommand " -D ${option}")
	endforeach()
	string(APPEND runScriptCommand " -P \"${script}\"")

	set(${commandOut} ${runScriptCommand} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Adds a bundle-target that bundles all the subtargets from the package-component property
function( cpfAddPackageComponentsSubTargetBundleTarget targetName packageComponents subtargetProperty additionalDependencies )
	
	cpfGetSubtargets( dependedOnTargets "${packageComponents}" ${subtargetProperty})
	if(dependedOnTargets)
		cpfAddBundleTarget( ${targetName} "${dependedOnTargets};${additionalDependencies}" )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Adds a bundle-target that bundles all the subtargets from the package-component property 
function( cpfAddSubTargetBundleTarget targetName packages subtargetProperty additionalDependencies )

	set(packageComponents)
	foreach(package ${packages})
		cpfGetPackageComponents(components ${package})
		if(components)
			cpfListAppend(packageComponents "${components}")
		endif()
	endforeach()

	cpfAddPackageComponentsSubTargetBundleTarget(${targetName} "${packageComponents}" ${subtargetProperty} "${additionalDependencies}")

endfunction()

#----------------------------------------------------------------------------------------
# This function adds a target that does nothing for it self, but only makes sure that
# the depended on targets are build. If the list of dependedOnTargets is empty, no
# bundle target is added.
function( cpfAddBundleTarget targetName dependedOnTargets )
	if(dependedOnTargets)
		add_custom_target(
			${targetName}
			DEPENDS ${dependedOnTargets}
		)
	endif()
endfunction()

