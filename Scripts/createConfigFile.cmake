
# This script is used to generated ${CPF_CONFIG}.config.cmake files in the Configuration sub directory.
# ARGUMENTS
# CPF_CONFIG			- The base name of the generated file.
# PARENT_CONFIG			- The base name of an inherited config file.

list( APPEND CMAKE_MODULE_PATH
	${CMAKE_CURRENT_LIST_DIR}/../Functions
	${CMAKE_CURRENT_LIST_DIR}/../Variables
)

include(cpfMiscUtilities)
include(cpfProjectUtilities)
include(cpfLocations)
include(cpfConstants)
include(cpfPathUtilities)

cmake_minimum_required(VERSION ${CPF_MINIMUM_CMAKE_VERSION})

cpfAssertScriptArgumentDefined(CPF_CONFIG)
cpfAssertScriptArgumentDefined(PARENT_CONFIG)

# Find the location of the inherited configuration
cpfFindConfigFile( fullInheritedConfigFile "${PARENT_CONFIG}")

# CREATE CONFIG-FILE CONTENT 
cpfNormalizeAbsPath( configFilename "${CMAKE_CURRENT_LIST_DIR}/../../../Configuration/${CPF_CONFIG}${CPF_CONFIG_FILE_ENDING}")
cpfNormalizeAbsPath( pathToVariables "${CMAKE_CURRENT_LIST_DIR}/../Variables")

# Add standard lines.
set(fileContent)
list(APPEND fileContent "# This file cpfContains cmake project configuration parameters." )
list(APPEND fileContent "" )
list(APPEND fileContent "list( APPEND CMAKE_MODULE_PATH \"${pathToVariables}\")" )
list(APPEND fileContent "include(cpfLocations)")
list(APPEND fileContent "" )
list(APPEND fileContent "# Inherit configuration parameters." )
list(APPEND fileContent "include( \"${fullInheritedConfigFile}\" )" )
list(APPEND fileContent "set( CPF_PARENT_CONFIG \"${PARENT_CONFIG}\" CACHE STRING \"The CI-configuration from which this config derives.\" FORCE)" )
list(APPEND fileContent "" )
list(APPEND fileContent "# internal variables" )
list(APPEND fileContent "set( CPF_CONFIG_FILE \"${configFilename}\" CACHE FILEPATH \"The path to the used .config.cmake file.\" FORCE)" )
list(APPEND fileContent "set( CPF_CONFIG \"${CPF_CONFIG}\" CACHE STRING \"The name of the cmake configuration that is defined by this file.\" FORCE)" )
list(APPEND fileContent "set( CMAKE_INSTALL_PREFIX \"\${CPF_ROOT_DIR}/\${CPF_GENERATED_DIR}/\${CPF_CONFIG}/\${CPF_INSTALL_STAGE}\" CACHE STRING \"The name of the cmake configuration that is defined by this file.\" FORCE)" )
list(APPEND fileContent "" )

# Add lines with commented inherited definitions.
cpfGetCacheVariablesDefinedInFile( inheritedCacheVariables inheritedCacheValues inheritedCacheTypes inheritedCacheDescriptions "${fullInheritedConfigFile}")

list(APPEND fileContent "# Inherited cache variables." )
set(index 0)
foreach( variable ${inheritedCacheVariables} )

	list(GET inheritedCacheValues ${index} value )
	list(GET inheritedCacheTypes ${index} type )
	list(GET inheritedCacheDescriptions ${index} description )

	list(APPEND fileContent "# set( ${variable} \"${value}\" CACHE ${type} \"${description}\" FORCE )" )
	cpfIncrement(index)

endforeach()
list(APPEND fileContent "" )
list(APPEND fileContent "" )

# Add definitions for the variables that were set by using the "-D"-options.
list(APPEND fileContent "# Overridden or new cache variables." )
cpfGetScriptDOptionVariableNames( dVariables )
list(REMOVE_ITEM dVariables CPF_CONFIG PARENT_CONFIG )
foreach( variable ${dVariables})
	cpfIsCacheVariable( isCacheVar ${variable})
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
file(REMOVE "${configFilename}")

set(commandList)
foreach( line IN LISTS fileContent)
	file( APPEND "${configFilename}" "${line}\n")
endforeach()

