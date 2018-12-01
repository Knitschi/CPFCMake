
# This script is used to generated ${CPF_CONFIG}.config.cmake files in the Configuration sub directory.
# ARGUMENTS
# CPF_CONFIG			- The base name of the generated file.
# PARENT_CONFIG			- The base name of an inherited config file.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)

include(cpfConstants)
include(cpfMiscUtilities)
include(cpfProjectUtilities)
include(cpfLocations)
include(cpfPathUtilities)

cpfAssertScriptArgumentDefined(CPF_CONFIG)
cpfAssertScriptArgumentDefined(PARENT_CONFIG)

# Find the location of the inherited configuration
cpfNormalizeAbsPath( CPF_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../../..")
cpfFindConfigFile( fullInheritedConfigFile "${PARENT_CONFIG}")

# CREATE CONFIG-FILE CONTENT 
cpfNormalizeAbsPath( pathToVariables "${CMAKE_CURRENT_LIST_DIR}/../Variables")

# Add standard lines.
set(fileContent)
cpfListAppend( fileContent "# This file contains cmake project configuration parameters." )
cpfListAppend( fileContent "" )
cpfListAppend( fileContent "list( APPEND CMAKE_MODULE_PATH \"${pathToVariables}\")" )
cpfListAppend( fileContent "include(cpfLocations)")
cpfListAppend( fileContent "" )
cpfListAppend( fileContent "# Inherit configuration parameters." )
cpfListAppend( fileContent "include( \"${fullInheritedConfigFile}\" )" )
cpfListAppend( fileContent "set( CPF_PARENT_CONFIG \"${PARENT_CONFIG}\" CACHE STRING \"The CI-configuration from which this config derives.\" FORCE)" )
cpfListAppend( fileContent "" )
cpfListAppend( fileContent "# internal variables" )
cpfListAppend( fileContent "set( CPF_ROOT_DIR \"${CPF_ROOT_DIR}\" CACHE FILEPATH \"The path to the root directory of this CPF CI-project.\" FORCE)" )
cpfListAppend( fileContent "set( CPF_CONFIG \"${CPF_CONFIG}\" CACHE STRING \"The name of the cmake configuration that is defined by this file.\" FORCE)" )
cpfListAppend( fileContent "" )


# Add definitions for the variables that were set by using the "-D"-options.
cpfListAppend( fileContent "# Overridden or new cache variables." )
cpfGetScriptDOptionVariableNames( dVariables )
list(REMOVE_ITEM dVariables CPF_CONFIG PARENT_CONFIG )
foreach( variable ${dVariables})
	cpfIsCacheVariable( isCacheVar ${variable})
	if(isCacheVar) 
		# use existing information for overridden variables
		get_property( type CACHE ${variable} PROPERTY TYPE)
		get_property( helpString CACHE ${variable} PROPERTY HELPSTRING )
		cpfListAppend( fileContent "set( ${variable} \"${${variable}}\" CACHE ${type} \"${helpString}\" FORCE )" )
	else()
		cpfListAppend( fileContent "set( ${variable} \"${${variable}}\" CACHE STRING \"\" FORCE )" )
	endif()
endforeach()
cpfListAppend( fileContent "" )

# Add lines with commented inherited definitions.
cpfGetCacheVariablesDefinedInFile( inheritedCacheVariables inheritedCacheValues inheritedCacheTypes inheritedCacheDescriptions "${fullInheritedConfigFile}")
cpfListAppend( fileContent "# Inherited cache variables." )
set(index 0)
foreach( variable ${inheritedCacheVariables} )
	list(GET inheritedCacheValues ${index} value )
	list(GET inheritedCacheTypes ${index} type )
	list(GET inheritedCacheDescriptions ${index} description )

	cpfListAppend( fileContent "# set( ${variable} \"${value}\" CACHE ${type} \"${description}\" FORCE )" )
	cpfIncrement(index)
endforeach()
cpfListAppend( fileContent "" )


# Write the lines in fileContent to the config file.
cpfGetFullConfigFilePath(configFilename)
file(REMOVE "${configFilename}")

set(commandList)
foreach( line IN LISTS fileContent)
	file( APPEND "${configFilename}" "${line}\n")
endforeach()

