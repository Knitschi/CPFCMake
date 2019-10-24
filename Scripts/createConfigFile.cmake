
# This script is used to generated ${CPF_CONFIG}.config.cmake files in the Configuration sub directory.
# ARGUMENTS
# DERIVED_CONFIG			- The base name of the generated file.
# PARENT_CONFIG				- The base name of an inherited config file.
# LIST_CONFIGURATIONS		- Set to true to only print the already existing configurations.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)

include(cpfConstants)
include(cpfMiscUtilities)
include(cpfProjectUtilities)
include(cpfLocations)
include(cpfPathUtilities)
include(cpfAssertions)
include(cpfConfigUtilities)

cpfNormalizeAbsPath( CPF_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../../..")

if(LIST_CONFIGURATIONS)

	# Developer configs
	cpfGetConfigurationsInDirectory( devConfigs "${CPF_ROOT_DIR}/${CPF_CONFIG_DIR}"	)
	if(devConfigs)
		message(STATUS "Developer configurations:")
		foreach(config ${devConfigs})
			message("${config}")
		endforeach()
		message("")
	endif()

	# Project configs
	cpfGetConfigurationsInDirectory( projectConfigs "${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/${CPF_PROJECT_CONFIGURATIONS_DIR}"	)
	if(projectConfigs)
		message(STATUS "Project configurations:")
		foreach(config ${projectConfigs})
			message("${config}")
		endforeach()
		message("")
	endif()

	# CPF configs
	cpfGetConfigurationsInDirectory( cpfConfigs "${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/CPFCMake/${CPF_DEFAULT_CONFIGS_DIR}"	)
	if(cpfConfigs)
		message(STATUS "CPF base configurations:")
		foreach(config ${cpfConfigs})
			message("${config}")
		endforeach()
		message("")
	endif()

else() # Do the file generation

	cpfAssertScriptArgumentDefined(DERIVED_CONFIG)
	cpfAssertScriptArgumentDefined(PARENT_CONFIG)

	# Find the location of the inherited configuration
	cpfFindConfigFile( fullInheritedConfigFile "${PARENT_CONFIG}" FALSE)

	# CREATE CONFIG-FILE CONTENT 
	cpfNormalizeAbsPath( pathToVariables "${CMAKE_CURRENT_LIST_DIR}/../Modules")

	# Add standard lines.
	set(fileContent)
	cpfListAppend( fileContent "# This file contains cmake project configuration parameters." )
	cpfListAppend( fileContent "" )
	cpfListAppend( fileContent "# Inherit configuration parameters." )
	cpfListAppend( fileContent "include( \"${fullInheritedConfigFile}\" )" )
	cpfListAppend( fileContent "set( CPF_PARENT_CONFIG \"${PARENT_CONFIG}\" CACHE STRING \"The CI-configuration from which this config derives.\" FORCE)" )
	cpfListAppend( fileContent "" )
	cpfListAppend( fileContent "# internal variables" )
	cpfListAppend( fileContent "set( CPF_CONFIG \"${DERIVED_CONFIG}\" CACHE STRING \"The name of the cmake configuration that is defined by this file.\" FORCE)" )
	cpfListAppend( fileContent "" )


	# Add definitions for the variables that were set by using the "-D"-options.
	cpfListAppend( fileContent "# Overridden or new cache variables." )
	cpfGetScriptDOptionVariableNames( dVariables )
	list(REMOVE_ITEM dVariables DERIVED_CONFIG PARENT_CONFIG )
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
	cpfGetFullConfigFilePath(configFilename ${DERIVED_CONFIG})
	file(REMOVE "${configFilename}")

	set(commandList)
	foreach( line IN LISTS fileContent)
		file( APPEND "${configFilename}" "${line}\n")
	endforeach()

endif()

