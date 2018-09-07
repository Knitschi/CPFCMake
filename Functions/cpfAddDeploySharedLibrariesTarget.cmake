include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfProjectUtilities)


#----------------------------------------------------------------------------------------
# Adds a target that copies depended on shared libraries to the binaryTargets output directory.
# linkedLibrarie can contain all linked libraries of the target. The function will pick
# the shared libraries by itself. 
#
function( cpfAddDeploySharedLibrariesTarget package )

	# Only deploy shared libraries on windows. On Linux CMake uses the RPATH to make it work.
	if(NOT ${CMAKE_SYSTEM_NAME} STREQUAL Windows)
		return()
	endif()

	# Get all libraries that need to be copied.
	cpfGetExecutableTargets( exeTargets ${package})
	set(allLinkedLibraries)
	foreach(exeTarget ${exeTargets})
		cpfGetRecursiveLinkedLibraries( targetLinkedLibraries ${exeTarget})
		list(APPEND allLinkedLibraries ${targetLinkedLibraries})
	endforeach()
	if(allLinkedLibraries)
		list(REMOVE_DUPLICATES allLinkedLibraries)
	endif()

	cpfFilterInTargetsWithProperty( sharedLibraries "${allLinkedLibraries}" TYPE SHARED_LIBRARY )
	cpfFilterInTargetsWithProperty( externalSharedLibs "${sharedLibraries}" IMPORTED TRUE )
	cpfFilterInTargetsWithProperty( internalSharedLibs "${sharedLibraries}" IMPORTED "" )

	# Add the targets that copy the dlls
	cpfAddDeployInternalSharedLibsToBuildStageTarget( ${package} "${internalSharedLibs}" "" ) 
	cpfAddDeployExternalSharedLibsToBuildStageTarget( ${package} "${externalSharedLibs}" "" ) 

endfunction()

#---------------------------------------------------------------------------------------------
# Recursively get either imported or non-imported linked shared libraries of the target.
#
function( cpfGetRecursiveLinkedLibraries linkedLibsOut target )

	set(allLinkedLibraries)
    set(outputLocal)

	get_property(linkedLibraries TARGET ${target} PROPERTY INTERFACE_LINK_LIBRARIES)											# The linked libraries for non imported targets
	list(APPEND allLinkedLibraries ${linkedLibraries})

	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )		# The following properties can not be accessed for interface libraries.

		get_property(linkedLibraries TARGET ${target} PROPERTY LINK_LIBRARIES)		# The linked libraries for non imported targets
		list(APPEND allLinkedLibraries ${linkedLibraries})

		cpfGetConfigVariableSuffixes(configSuffixes)
		foreach(configSuffix ${configSuffixes})
			get_property(importedInterfaceLibraries TARGET ${target} PROPERTY IMPORTED_LINK_INTERFACE_LIBRARIES${configSuffix})		# the libraries that are used in the header files of the target
			list(APPEND allLinkedLibraries ${importedInterfaceLibraries})
			
			get_property(importedPrivateLibraries TARGET ${target} PROPERTY IMPORTED_LINK_DEPENDENT_LIBRARIES${configSuffix})
			list(APPEND allLinkedLibraries ${importedPrivateLibraries})
		endforeach()

	endif()

	if(allLinkedLibraries)
		list(REMOVE_DUPLICATES allLinkedLibraries)
	endif()

	set(outputLocal)
	foreach( lib ${allLinkedLibraries})

		if(TARGET ${lib})
			
			list( APPEND outputLocal ${lib} )
			cpfGetRecursiveLinkedLibraries( subLibs ${lib})
			list( APPEND outputLocal ${subLibs} )

		else()
			# dependencies can be given as generator expressions
			# we can not follow these so we ignore them for now
			cpfContainsGeneratorExpressions( containsGenExp ${lib})
			if( containsGenExp )
				cpfDebugMessage("Ignored dependency ${lib} while setting up shared library deployment targets. The deployment mechanism can not handle generator expressions.")
			elseif( ${lib} MATCHES "[-].+" ) # ignore libraries that are linked via linker options for now.
			else()
				# The dependency does not seem to be a generator expression, so it should be available here.
				message(FATAL_ERROR "Linked library ${lib} is not an existing target. Maybe you need to add another find_package() call.")
			endif()
		endif()

	endforeach()

	if(outputLocal)
		list(REMOVE_DUPLICATES outputLocal)
	endif()

	set(${linkedLibsOut} ${outputLocal} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Get all linked libraries from which the given target may inherit compile flags.
# This is all directly linked non interface libraries and below that the tree of linked
# interface libraries.
# This function currently ignores the IMPORTED_LINK_DEPENDENT_LIBRARIES_<CONFIG> and
# IMPORTED_LINK_INTERFACE_LIBRARIES_<CONFIG> properties.
#
function ( cpfGetVisibleLinkedLibraries linkedLibsOut target )
	
	set(allLibs)
	cpfGetLinkLibraries( linkedLibs ${target})
	
	list(APPEND allLibs ${linkedLibs})
	foreach( lib ${linkedLibs} )
		cpfGetRecursiveLinkedInterfaceLibraries( libs ${lib} )
		list(APPEND allLibs ${libs})
	endforeach()
	if(allLibs)
		list(REMOVE_DUPLICATES allLibs)
	endif()
	set(${linkedLibsOut} ${allLibs} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Gets all linked librares from the LINK_LIBRARIES and IMPORTED_LINK_DEPENDENT_LIBRARIES properties.
#
function( cpfGetLinkLibraries linkedLibsOut target )
	set(libs)
	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )	# The following properties can not be accessed for interface libraries.
		cpfGetTargetProperties( libs ${target} "LINK_LIBRARIES;IMPORTED_LINK_DEPENDENT_LIBRARIES" )
	endif()
	if(libs)
		list(REMOVE_DUPLICATES libs)
	endif()
	set(${linkedLibsOut} ${libs} PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# Recursively gets all libraries from the INTERFACE_LINK_LIBRARIES and IMPORTED_LINK_INTERFACE_LIBRARIES
# properties
function( cpfGetRecursiveLinkedInterfaceLibraries interfaceLibsOut target )
	
	set(allLibs)
	cpfGetInterfaceLinkLibraries( libs ${target})
	list(APPEND allLibs ${libs})
	foreach(lib ${libs})
		cpfGetRecursiveLinkedInterfaceLibraries( libs ${lib})
		list(APPEND allLibs ${libs})
	endforeach()
	if(allLibs)
		list(REMOVE_DUPLICATES allLibs)
	endif()
	set(${interfaceLibsOut} ${allLibs} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Gets all linked libraries from the INTERFACE_LINK_LIBRARIES and IMPORTED_LINK_INTERFACE_LIBRARIES
function( cpfGetInterfaceLinkLibraries linkedLibsOut target )
	
	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )	# The following properties can not be accessed for interface libraries.
		cpfGetTargetProperties( libs1 ${target} "IMPORTED_LINK_INTERFACE_LIBRARIES" )
	endif()
	cpfGetTargetProperties( libs2 ${target} "INTERFACE_LINK_LIBRARIES" )
	if(libs)
		list(REMOVE_DUPLICATES libs)
	endif()

	# remove generator expression targets, because they cause trouble
	set(libs)
	foreach(lib ${libs1} ${libs2})
		if(TARGET ${lib})
			list(APPEND libs ${lib})
		endif()
	endforeach()

	set(${linkedLibsOut} ${libs} PARENT_SCOPE)
endfunction()


#---------------------------------------------------------------------------------------------
# This function returns a list of the given targets plus all targets that are directly or indirectly 
# linked to the given targets.
function( cpfGetAllTargetsInLinkTree targetsOut targetsIn )

	set(allLinkedTargets)
	foreach( target ${targetsIn})
		cpfGetRecursiveLinkedLibraries( indirectlyLinkedTargets ${target})
		list(APPEND allLinkedTargets ${target} ${indirectlyLinkedTargets} )
	endforeach()
	if(allLinkedTargets)
		list(REMOVE_DUPLICATES allLinkedTargets)
	endif()
	set(${targetsOut} ${allLinkedTargets} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeployInternalSharedLibsToBuildStageTarget package libs outputSubDir )

	if(NOT libs)
		return()
	endif()

	# Add one custom target to copy all external libs.
	cpfGetIndexedTargetName(targetName deployExternal_${package})

	set(outputs)
	foreach( lib ${libs})
		
		# Add a copy command for the current version.
		cpfGetConfigurations(configs)
		foreach(config ${configs})

			cpfGetInternalLibFilePath( libFile ${lib} ${config})
			cpfAddDeployCommand( outputs ${targetName} ${package} ${config} "${outputSubDir}" ${lib} ${libFile} "${outputs}")

		endforeach()

	endforeach()

	cpfAddDeployTarget( ${targetName} ${package} "${outputs}" "${libs}" )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeployExternalSharedLibsToBuildStageTarget package libs outputSubDir )

	if(NOT libs)
		return()
	endif()

	# Add one custom target to copy all external libs.
	cpfGetIndexedTargetName(targetName deployExternal_${package})

	set(outputs)
	foreach( lib ${libs})
		
		# Add a copy command for the current version.
		cpfGetConfigurations(configs)
		foreach(config ${configs})

			cpfGetExternalLibFilePath( libFile ${lib} ${config})
			cpfAddDeployCommand( outputs ${targetName} ${package} ${config} "${outputSubDir}" ${lib} ${libFile} "${outputs}")

		endforeach()

	endforeach()

	cpfAddDeployTarget( ${targetName} ${package} "${outputs}" "${libs}" )

endfunction()

#--------------------------------------------------------------------------
function( cpfGetInternalLibFilePath pathOut libraryTarget config)

	cpfGetTargetOutputFileName(libraryFileName ${libraryTarget} ${config})
	cpfGetTargetOutputDirectory( sourceDir ${libraryTarget} ${config} )
	set(${pathOut} "${sourceDir}/${libraryFileName}" PARENT_SCOPE)

endfunction()

#--------------------------------------------------------------------------
function( cpfGetExternalLibFilePath pathOut libraryTarget config)

	cpfToConfigSuffix( suffix ${config} )
	cpfGetLibLocation( libPath ${libraryTarget} ${suffix})
	set(${pathOut} ${libPath} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeployCommand outputsOut targetName package config outputSubDir lib libFile existingOutputs )

	cpfToConfigSuffix( configSuffix ${config})
	cpfGetSharedLibraryOutputDir( targetDir ${package} ${configSuffix} )

	get_filename_component( shortName ${libFile} NAME)

	if(outputSubDir)
		set(output "${targetDir}/${outputSubDir}/${shortName}")
	else()
		set(output "${targetDir}/${shortName}")
	endif()

	set(outputs)
	cpfContains( alreadyCopied existingOutputs ${output})
	if(NOT ("${libFile}" STREQUAL "${output}") AND NOT alreadyCopied )  # Do not deploy the library that belongs to the same package or one that has already been copied.

		set(copyCommand "cmake -E copy \"${libFile}\" \"${output}\"")
		set(touchCommand "cmake -E touch \"${output}\"")

		cpfAddConfigurationDependendCommand(
			TARGET ${targetName}
			OUTPUT ${output}
			DEPENDS ${lib} ${libFile}
			COMMENT "Deploy or touch \"${output}\""
			CONFIG ${config}
			COMMANDS_CONFIG ${copyCommand}
			COMMANDS_NOT_CONFIG ${touchCommand}
		)

		cpfListAppend(outputs ${output})

	endif()

	set(${outputsOut} "${outputs}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeployTarget targetName package outputs libs ) 

	if(outputs)

	add_custom_target(
		${targetName}
		DEPENDS ${outputs} ${libs}
	)
	set_property(TARGET ${targetName} PROPERTY FOLDER ${package}/private)

	# make sure the copying is done before the target is build
	cpfGetExecutableTargets(exeTargets ${package})
	foreach(exeTarget ${exeTargets})
		add_dependencies( ${exeTarget} ${targetName} )
	endforeach()

	endif()

endfunction()


#---------------------------------------------------------------------------------------------
function( cpfGetSharedLibraryOutputDir outputDir target configSuffix )
    
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows )
        get_property( sourceDir TARGET ${target} PROPERTY RUNTIME_OUTPUT_DIRECTORY${configSuffix})
    elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
        get_property( sourceDir TARGET ${target} PROPERTY LIBRARY_OUTPUT_DIRECTORY${configSuffix})
    else()
        message(FATAL_ERROR "Function cpfGetSharedLibraryOutputDir() must be extended for system ${CMAKE_SYSTEM_NAME}")
    endif()
    
    set(${outputDir} ${sourceDir} PARENT_SCOPE)
    
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetLibLocation location lib configSuffix )

	get_property( libFile TARGET ${lib} PROPERTY LOCATION${suffix})

	if(NOT libFile) # if the given config is not available for the imported library, we use the RELEASE config instead.
		get_property( libFile TARGET ${lib} PROPERTY LOCATION_RELEASE)
		cpfAssertDefinedMessage( libFile "Could not get the location of the .dll/.so file of library ${lib}.")
		cpfDebugMessage("Library ${lib} has no property LOCATION${suffix} configuration. Defaulting to the LOCATION_RELEASE version.")
	endif()

	set(${location} ${libFile} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetIndexedTargetName indexedName baseName )

	set(index 0)
	while(TARGET ${baseName}_${index})
		cpfIncrement(index)
	endwhile()

	set(${indexedName} ${baseName}_${index} PARENT_SCOPE)

endfunction()





