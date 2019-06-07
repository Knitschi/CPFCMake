include_guard(GLOBAL)


#---------------------------------------------------------------------------------------------
function( cpfGetSharedLibrariesRequiredByPackageExecutables librariesOut package )

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

	set(${librariesOut} "${sharedLibraries}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetSharedLibrariesRequiredByPackageProductionLib librariesOut package )

	get_property( productionLib TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET )
	cpfGetRecursiveLinkedLibraries( linkedLibraries ${productionLib})
	if(linkedLibraries)
		list(REMOVE_DUPLICATES linkedLibraries)
	endif()

	cpfFilterInTargetsWithProperty( sharedLibraries "${linkedLibraries}" TYPE SHARED_LIBRARY )

	set(${librariesOut} "${sharedLibraries}" PARENT_SCOPE)

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
			get_property(importedInterfaceLibraries TARGET ${target} PROPERTY IMPORTED_LINK_INTERFACE_LIBRARIES_${configSuffix})		# the libraries that are used in the header files of the target
			list(APPEND allLinkedLibraries ${importedInterfaceLibraries})
			
			get_property(importedPrivateLibraries TARGET ${target} PROPERTY IMPORTED_LINK_DEPENDENT_LIBRARIES_${configSuffix})
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