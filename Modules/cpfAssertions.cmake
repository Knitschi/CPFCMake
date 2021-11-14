include_guard(GLOBAL)


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
# Triggers an error if the value is empty or FALSE of OFF.
#
function( cpfAssertTrue variableName )
	if(NOT ${${variableName}})
		message(FATAL_ERROR "Assertion failed! Variable ${variableName} had \"false\" value \"${${${variableName}}}\".")
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Asserts the the variable PROJECT_VERSION is defined.
#
function( cpfAssertProjectVersionDefined )
	cpfAssertDefinedMessage(PROJECT_VERSION "The variable PROJECT_VERSION is not defined. Did you forget to call cpfPackageProject() before adding the package?")
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
# This function can be used to assert that key-word arguments were set.
#
function( cpfAssertKeywordArgumentsHaveValue keywords keywordPrefix function )

	foreach(keyword ${keywords})
		if(NOT ${keywordPrefix}_${keyword})
			message(FATAL_ERROR "Function ${function} requires keyword argument ${keyword}")
		endif()
	endforeach()

endfunction()

#---------------------------------------------------------------------
# This function only returns the libraries from the input that actually exist.
# Lower level packages must be added first.
# For non existing target a warning is issued when CPF_VERBOSE is ON.
# We allow adding dependencies to non existing targets so we can link to targets that may only be available
# for some configurations.
#
function( cpfDebugAssertLinkedLibrariesExists linkedLibrariesOut packageComponent linkedLibrariesIn )

	set(linkedLibraries)
	foreach(lib ${linkedLibrariesIn})

		# Make sur no empty strings were given.
		if("${lib}" STREQUAL "")
			message(FATAL_ERROR "Values for argument keywords LINKED_LIBRARIES and LINKED_TEST_LIBRARIES can not be emtpy strings.")
		endif()

		# Ignore the visibility keywords
		cpfIsLinkVisibilityKeyword(isKeyword ${lib})
		if(isKeyword)
			# Pass the keyword on
			list(APPEND linkedLibraries ${lib})
			continue()
		endif()

		if(NOT TARGET ${lib})
			cpfDebugMessage("${lib} is not a Target when creating package ${packageComponent}. If it should be available, make sure to have target ${lib} added before adding this package.")
		else()
			list(APPEND linkedLibraries ${lib})
		endif()

	endforeach()

	set(${linkedLibrariesOut} ${linkedLibraries} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
function( cpfIsLinkVisibilityKeyword isKeywordOut linkedTarget )

	if((${linkedTarget} STREQUAL "PRIVATE") OR (${linkedTarget} STREQUAL "PUBLIC") OR (${linkedTarget} STREQUAL "INTERFACE"))
		set(${isKeywordOut} TRUE PARENT_SCOPE)
	else()
		set(${isKeywordOut} FALSE PARENT_SCOPE)
	endif()

endfunction()

#---------------------------------------------------------------------
# Checks that the compatibility scheme option contains one of the allowed values.
function( cpfAssertCompatibilitySchemeOption scheme )
	if( NOT ( "${scheme}" STREQUAL ExactVersion ) )
		message(FATAL_ERROR "Invalid argument to cpfAddCppPackageComponent()!. Value \"${scheme}\" for option VERSION_COMPATIBILITY_SCHEME is not allowed.")
	endif()
endfunction()