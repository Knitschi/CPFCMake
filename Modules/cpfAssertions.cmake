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
# Asserts the the variable PROJECT_VERSION is defined.
#
function( cpfAssertProjectVersionDefined )
	cpfAssertDefinedMessage(PROJECT_VERSION "The variable PROJECT_VERSION is not defined. Did you forget to call cpfInitPackageProject() before adding the package?")
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
function( cpfDebugAssertLinkedLibrariesExists linkedLibrariesOut package linkedLibrariesIn )

	foreach(lib ${linkedLibrariesIn})
		if(NOT TARGET ${lib} )
			cpfDebugMessage("${lib} is not a Target when creating package ${package}. If it should be available, make sure to have target ${lib} added before adding this package.")
		else()
			list(APPEND linkedLibraries ${lib})
		endif()
	endforeach()
	set(${linkedLibrariesOut} ${linkedLibraries} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
# Checks that the compatibility scheme option contains one of the allowed values.
function( cpfAssertCompatibilitySchemeOption scheme )
	if( NOT ( "${scheme}" STREQUAL ExactVersion ) )
		message(FATAL_ERROR "Invalid argument to cpfAddCppPackage()!. Value \"${scheme}\" for option VERSION_COMPATIBILITY_SCHEME is not allowed.")
	endif()
endfunction()