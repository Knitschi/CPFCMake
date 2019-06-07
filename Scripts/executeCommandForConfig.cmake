
# This script requires the variables
# CMAKE_HOST_SYSTEM_NAME
# CURRENT_CONFIG								- should be set to $<CONFIG>
# STATIC_CONFIG									- A fixed set configuration
# ARGUMENT_FILE									- An absolute path to a .cmake file that contains the definitions for the following variables.
#	COMMANDS_CONFIG								- the commands that are executed when CURRENT_CONFIG is not STATIC_CONFIG
#	COMMANDS_NOT_CONFIG							- the commands that are executed when CURRENT_CONFIG is STATIC_CONFIG
# PRINT_SKIPPED_INSTEAD_OF_NON_CONFIG_OUTPUT	- If set to true the output of the non-config commands is suppressed and one "... skiped" message is printed instead.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
include(cpfMiscUtilities)

cpfAssertScriptArgumentDefined(CMAKE_HOST_SYSTEM_NAME)
cpfAssertScriptArgumentDefined(CURRENT_CONFIG)
cpfAssertScriptArgumentDefined(STATIC_CONFIG)
cpfAssertScriptArgumentDefined(ARGUMENT_FILE)
cpfAssertScriptArgumentDefined(PRINT_SKIPPED_INSTEAD_OF_NON_CONFIG_OUTPUT)

include("${CMAKE_CURRENT_LIST_DIR}/../../../${ARGUMENT_FILE}")	# get the commands from the argument file

function( executeCommands commands isConfig)

	foreach( command ${commands} )
		
        #devMessage("String from file: ${command}")
        
        # In order to get the special characters through to the final command
        # we need to re-escape them. The number of escapes was determined empirically.
        # It is not guaranteed that this will work in all cases.
        #string(REPLACE ";" "\\\\\\;" commandEscaped ${command})
		#string(REPLACE "\\" "\\\\" commandEscaped ${commandEscaped}) 
        #string(REPLACE "\"" "\\\"" commandEscaped ${commandEscaped})
        
        #devMessage("Escaped string FINAL: ${commandEscaped}")
		separate_arguments(commandList NATIVE_COMMAND ${command})
        #devMessage("Separated String: ${commandList}")

        # Print the command in a form that can be copied and executed.
        if(isConfig)
			message("${command}")
		endif()
        
		execute_process(
			COMMAND ${commandList} 
			RESULT_VARIABLE result
			OUTPUT_VARIABLE outputString
			ERROR_VARIABLE outputString
		)

        # Print the output of the command because it may be absorbed otherwise.
        if( NOT "${outputString}" STREQUAL "")
			if( isConfig OR NOT PRINT_SKIPPED_INSTEAD_OF_NON_CONFIG_OUTPUT )
				message("${outputString}")
			endif()
        endif()
        
        # make sure the script fails if the execution of a command fails
        if(NOT ${result} STREQUAL 0)
			if(	NOT isConfig) # print output for not config only if something goes wrong
				message("${command}")
				message("${outputString}")
			endif()
			message(FATAL_ERROR "Command failed! Static config: ${STATIC_CONFIG}, current config: ${CURRENT_CONFIG}")
        endif()

	endforeach()

	if(PRINT_SKIPPED_INSTEAD_OF_NON_CONFIG_OUTPUT AND NOT isConfig)
		message("... skipped")
	endif()

endfunction()


if( "${CURRENT_CONFIG}" STREQUAL "${STATIC_CONFIG}" )
	executeCommands( "${COMMANDS_CONFIG}" TRUE )
else()
	executeCommands( "${COMMANDS_NOT_CONFIG}" FALSE )
endif()






