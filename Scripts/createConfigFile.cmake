
# This script is used to generated ${CPPCODEBASE_CONFIG}.config.cmake files in the Configuration sub directory.
# ARGUMENTS
# CPPCODEBASE_CONFIG			- The base name of the generated file.
# PARENT_CONFIG					- A two element list with one of (Local,Project,CppCodeBase)

#[[
get_cmake_property(_variableNames VARIABLES)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}=${${_variableName}}")
endforeach()
]]

include("${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbBaseUtilities.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbProjectUtilities.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbLocations.cmake")

ccbAssertScriptArgumentDefined(CPPCODEBASE_CONFIG)
ccbAssertScriptArgumentDefined(PARENT_CONFIG)

# Find the location of the inherited configuration
ccbFindConfigFile( fullInheritedConfigFile "${PARENT_CONFIG}")

# CREATE CONFIG-FILE CONTENT 
set(fileContent)

# Add standard lines.
list(APPEND fileContent "# This file ccbContains cmake project configuration parameters." )
list(APPEND fileContent "" )
ccbNormalizeAbsPath( fullProjectUtilities "${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbProjectUtilities.cmake" )
list(APPEND fileContent "include(\"${fullProjectUtilities}\")" )
list(APPEND fileContent "set( CPPCODEBASE_CONFIG \"${CPPCODEBASE_CONFIG}\" CACHE STRING \"The name of the cmake configuration that is defined by this file.\" FORCE )" )
list(APPEND fileContent "" )
list(APPEND fileContent "# Inherit configuration parameters." )
list(APPEND fileContent "include( \"${fullInheritedConfigFile}\" )" )
list(APPEND fileContent "" )

# Add lines with commented inherited definitions.
list(APPEND fileContent "# Inherited cache variables." )

ccbGetCacheVariablesDefinedInFile( inheritedCacheVariables "${fullInheritedConfigFile}")
foreach( variable ${inheritedCacheVariables} )
	get_property( type CACHE ${variable} PROPERTY TYPE )
	get_property( helpString CACHE ${variable} PROPERTY HELPSTRING )
	list(APPEND fileContent "# set( ${variable} \"${${variable}}\" CACHE ${type} \"${helpString}\" FORCE )" )
endforeach()
list(APPEND fileContent "" )
list(APPEND fileContent "" )

# Add definitions for the variables that were set by using the "-D"-options.
list(APPEND fileContent "# Overridden or new cache variables." )
ccbGetScriptDOptionVariableNames( dVariables )
list(REMOVE_ITEM dVariables CPPCODEBASE_CONFIG PARENT_CONFIG )
foreach( variable ${dVariables})
	ccbIsCacheVariable( isCacheVar ${variable})
	if(isCacheVar) 
		# use existing information for overridden variables
		get_property( type CACHE ${variable} PROPERTY TYPE)
		get_property( helpString CACHE ${variable} PROPERTY HELPSTRING )
		list(APPEND fileContent "set( ${variable} \"${${variable}}\" CACHE ${type} \"${helpString}\" FORCE )" )
	else()
		list(APPEND fileContent "set( ${variable} \"${${variable}}\" CACHE STRING \"\" FORCE )" )
	endif()
endforeach()


# Write the lines in fileContent to the config file.
set(configFilename "${CMAKE_CURRENT_LIST_DIR}/../../../Configuration/${CPPCODEBASE_CONFIG}${CCB_CONFIG_FILE_ENDING}")
file(REMOVE "${configFilename}")

set(commandList)
foreach( line IN LISTS fileContent)
	file( APPEND "${configFilename}" "${line}\n")
endforeach()

