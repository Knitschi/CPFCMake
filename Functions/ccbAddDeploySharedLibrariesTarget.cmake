

include(ccbCustomTargetUtilities)
include(ccbBaseUtilities)


#----------------------------------------------------------------------------------------
# Adds a target that copies depended on shared libraries to the binaryTargets output directory.
# linkedLibrarie can contain all linked libraries of the target. The function will pick
# the shared libraries by itself. 
#
function( ccbAddDeploySharedLibrariesTarget target package )

	# only deploy shared libraries for executables on windows
	get_property( type TARGET ${target} PROPERTY TYPE )
	if(NOT ${type} STREQUAL EXECUTABLE )
		return()
	endif()

	ccbGetRecursiveLinkedLibraries( allLinkedLibraries ${target})
	ccbFilterInTargetsWithProperty( sharedLibraries "${allLinkedLibraries}" TYPE SHARED_LIBRARY )
	ccbFilterInTargetsWithProperty( externalSharedLibs "${sharedLibraries}" IMPORTED TRUE )
	ccbFilterInTargetsWithProperty( internalSharedLibs "${sharedLibraries}" IMPORTED "" )

	ccbAddDeployInternalSharedLibsToBuildStageTargets( ${target} ${package} "${internalSharedLibs}" "" ) 
	ccbAddDeployExternalSharedLibsToBuildStageTarget( ${target} ${package} "${externalSharedLibs}" "" ) 

endfunction()

#---------------------------------------------------------------------------------------------
# Recursively get either imported or non-imported linked shared libraries of the target.
#
function( ccbGetRecursiveLinkedLibraries linkedLibsOut target )

	set(allLinkedLibraries)
    set(outputLocal)

	get_property(linkedLibraries TARGET ${target} PROPERTY INTERFACE_LINK_LIBRARIES)											# The linked libraries for non imported targets
	list(APPEND allLinkedLibraries ${linkedLibraries})

	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )		# The following properties can not be accessed for interface libraries.

		get_property(linkedLibraries TARGET ${target} PROPERTY LINK_LIBRARIES)		# The linked libraries for non imported targets
		list(APPEND allLinkedLibraries ${linkedLibraries})

		ccbGetConfigVariableSuffixes(configSuffixes)
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
			ccbGetRecursiveLinkedLibraries( subLibs ${lib})
			list( APPEND outputLocal ${subLibs} )

		else()
			# dependencies can be given as generator expressions
			# we can not follow these so we ignore them for now
			ccbContainsGeneratorExpressions( containsGenExp ${lib})
			if( containsGenExp )
				ccbDebugMessage("Ignored dependency ${lib} while setting up shared library deployment targets. The deployment mechanism can not handle generator expressions.")
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
function ( ccbGetVisibleLinkedLibraries linkedLibsOut target )
	
	set(allLibs)
	ccbGetLinkLibraries( linkedLibs ${target})
	
	list(APPEND allLibs ${linkedLibs})
	foreach( lib ${linkedLibs} )
		ccbGetRecursiveLinkedInterfaceLibraries( libs ${lib} )
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
function( ccbGetLinkLibraries linkedLibsOut target )
	set(libs)
	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )	# The following properties can not be accessed for interface libraries.
		ccbGetTargetProperties( libs ${target} "LINK_LIBRARIES;IMPORTED_LINK_DEPENDENT_LIBRARIES" )
	endif()
	if(libs)
		list(REMOVE_DUPLICATES libs)
	endif()
	set(${linkedLibsOut} ${libs} PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# Recursively gets all libraries from the INTERFACE_LINK_LIBRARIES and IMPORTED_LINK_INTERFACE_LIBRARIES
# properties
function( ccbGetRecursiveLinkedInterfaceLibraries interfaceLibsOut target )
	
	set(allLibs)
	ccbGetInterfaceLinkLibraries( libs ${target})
	list(APPEND allLibs ${libs})
	foreach(lib ${libs})
		ccbGetRecursiveLinkedInterfaceLibraries( libs ${lib})
		list(APPEND allLibs ${libs})
	endforeach()
	if(allLibs)
		list(REMOVE_DUPLICATES allLibs)
	endif()
	set(${interfaceLibsOut} ${allLibs} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Gets all linked libraries from the INTERFACE_LINK_LIBRARIES and IMPORTED_LINK_INTERFACE_LIBRARIES
function( ccbGetInterfaceLinkLibraries linkedLibsOut target )
	
	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )	# The following properties can not be accessed for interface libraries.
		ccbGetTargetProperties( libs1 ${target} "IMPORTED_LINK_INTERFACE_LIBRARIES" )
	endif()
	ccbGetTargetProperties( libs2 ${target} "INTERFACE_LINK_LIBRARIES" )
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
function( ccbGetAllTargetsInLinkTree targetsOut targetsIn )

	set(allLinkedTargets)
	foreach( target ${targetsIn})
		ccbGetRecursiveLinkedLibraries( indirectlyLinkedTargets ${target})
		list(APPEND allLinkedTargets ${target} ${indirectlyLinkedTargets} )
	endforeach()
	if(allLinkedTargets)
		list(REMOVE_DUPLICATES allLinkedTargets)
	endif()
	set(${targetsOut} ${allLinkedTargets} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbAddDeployExternalSharedLibsToBuildStageTarget binaryTarget baseFolder externalLibs outputSubDir)

	if(NOT externalLibs OR ${CMAKE_SYSTEM_NAME} STREQUAL Linux) # On linux cmake puts the directories of depended on libraries into the rpath
		return()
	endif()

	# Add one custom target to copy all external libs.
	ccbGetIndexedTargetName(targetName deployExternal_${binaryTarget})

	foreach( lib ${externalLibs})
		# sadly the add_custom_command() function does currently not take generator expressions for its output
		# https://cmake.org/pipermail/cmake-developers/2016-April/028195.html
		# This means we have to add custom command for each configuration library file
		ccbGetConfigVariableSuffixes(configSuffixes)
		foreach(suffix ${configSuffixes})

			ccbGetLibLocation( libFile ${lib} ${suffix})
			get_filename_component( shortName ${libFile} NAME)
			
			ccbGetSharedLibraryOutputDir( targetDir ${binaryTarget} ${suffix} )
			if(outputSubDir)
				set(output "${targetDir}/${outputSubDir}/${shortName}")
			else()
				set(output "${targetDir}/${shortName}")
			endif()

            add_custom_command(
                OUTPUT ${output}
                DEPENDS ${libFile} ${lib}
                COMMAND cmake;-E;copy;${libFile};${output}
                COMMENT "Deploy \"${output}\""
            )
            list(APPEND outputs ${output})

		endforeach()

	endforeach()

	add_custom_target(
		${targetName}
		DEPENDS ${outputs} ${externalLibs}
	)
	set_property(TARGET ${targetName} PROPERTY FOLDER ${baseFolder}/private)
	add_dependencies( ${binaryTarget} ${targetName} ) # make sure the copying is done before the target is build

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbGetSharedLibraryOutputDir outputDir target configSuffix )
    
    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows )
        get_property( sourceDir TARGET ${target} PROPERTY RUNTIME_OUTPUT_DIRECTORY${configSuffix})
    elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
        get_property( sourceDir TARGET ${target} PROPERTY LIBRARY_OUTPUT_DIRECTORY${configSuffix})
    else()
        message(FATAL_ERROR "Function ccbGetSharedLibraryOutputDir() must be extended for system ${CMAKE_SYSTEM_NAME}")
    endif()
    
    set(${outputDir} ${sourceDir} PARENT_SCOPE)
    
endfunction()


#---------------------------------------------------------------------------------------------
function( ccbAddDeployInternalSharedLibsToBuildStageTargets binaryTarget package libs outputSubDir )

	if(NOT libs OR ${CMAKE_SYSTEM_NAME} STREQUAL Linux)  # On linux cmake puts the directories of depended on libraries into the rpath
		return()
	endif()

	foreach( lib ${libs})
		
		# Add a custom target for each copied internal shared lib.
		ccbGetIndexedTargetName(targetName deployInternal_${binaryTarget}${suffix})

		# Always copy files for all configurations
		# This leads to unnecessary copying but we have less targets compared
		# to having one target for each copied file.
		# This is necessary because the OUTPUT argument of add_custom_command can not take
		# generator expressions.
		# We add custom command for each static configuration that will deploy the library
		# for that configuration if it is the currently build configuration. If not it will
		# only touch deployed library, to avoid copying files that are currently not needed.
		# When the current configuration is changed, the real file is deployed, because the
		# source file will be younger than the touched dummy file.
		ccbGetConfigurations(configs)
		foreach(config ${configs})

			ccbToConfigSuffix( configSuffix ${config})
			ccbGetSharedLibraryOutputDir( targetDir ${binaryTarget} ${configSuffix} )
			
			ccbGetTargetOutputFileName(libraryFileName ${lib} ${config} )
			if(outputSubDir)
				set(output "${targetDir}/${outputSubDir}/${libraryFileName}")
			else()
				set(output "${targetDir}/${libraryFileName}")
			endif()

            # if the output file already has the GENERATED property, it must have been created by another deploy target.
            get_property(alreadyDeployed SOURCE ${output} PROPERTY GENERATED)
            
            ccbGetTargetOutputDirectory( sourceDir ${lib} ${config} )
            set(libFile "${sourceDir}/${libraryFileName}")

            if(NOT "${libFile}" STREQUAL "${output}" )  # do not deploy the library that belongs to the same package, because it is already in the same directory
                if(NOT alreadyDeployed)                 # do not add a deploy rule twice. This can currently happen when deploying libraries for test targets and production targets to the same directory.
            
                    set(copyCommand "cmake -E copy \"${libFile}\" \"${output}\"")
                    set(touchCommand "cmake -E touch \"${output}\"")
                
                    #ccbDevMessage("deploy internal: ${output} ${binaryTarget}")
                
                    ccbAddConfigurationDependendCommand(
                        TARGET ${targetName}
                        OUTPUT ${output}
                        DEPENDS ${libFile} ${lib}
                        COMMENT "Deploy or touch \"${output}\""
                        CONFIG ${config}
                        COMMANDS_CONFIG ${copyCommand}
                        COMMANDS_NOT_CONFIG ${touchCommand}
                    )

                    #ccbDevMessage("deploy internal finished: ${output}")
                    
                    list(APPEND outputs ${output})
                    list(APPEND libs ${lib})
                
                endif()
            endif()
		endforeach()
	endforeach()

    if(outputs) # only add the target if commands have been added

		add_custom_target(
            ${targetName}
            DEPENDS ${outputs} ${libs}
        )
        set_property(TARGET ${targetName} PROPERTY FOLDER ${package}/private)
        add_dependencies( ${binaryTarget} ${targetName} ) # make sure the copying is done before the target is build
    endif()

endfunction()



#---------------------------------------------------------------------------------------------
function( ccbGetLibLocation location lib configSuffix )

	get_property( libFile TARGET ${lib} PROPERTY LOCATION${suffix})

	if(NOT libFile) # if the given config is not available for the imported library, we use the RELEASE config instead.
		get_property( libFile TARGET ${lib} PROPERTY LOCATION_RELEASE)
		ccbAssertDefinedMessage( libFile "Could not get the location of the .dll/.so file of library ${lib}.")
		ccbDebugMessage("Library ${lib} has no property LOCATION${suffix} configuration. Defaulting to the LOCATION_RELEASE version.")
	endif()

	set(${location} ${libFile} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbGetIndexedTargetName indexedName baseName )

	set(index 0)
	while(TARGET ${baseName}_${index})
		ccbIncrement(index)
	endwhile()

	set(${indexedName} ${baseName}_${index} PARENT_SCOPE)

endfunction()





