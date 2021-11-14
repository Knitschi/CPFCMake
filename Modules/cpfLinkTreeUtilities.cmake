include_guard(GLOBAL)


#---------------------------------------------------------------------------------------------
function( cpfGetSharedLibrariesRequiredByPackageExecutables librariesOut packageComponent config )

	cpfGetExecutableTargets( exeTargets ${packageComponent})
	set(allLinkedLibraries)
	foreach(exeTarget ${exeTargets})
		cpfGetRecursiveLinkedLibraries( targetLinkedLibraries ${exeTarget} ${config})
		list(APPEND allLinkedLibraries ${targetLinkedLibraries})
	endforeach()
	if(allLinkedLibraries)
		list(REMOVE_DUPLICATES allLinkedLibraries)
	endif()

	cpfFilterInTargetsWithProperty( sharedLibraries "${allLinkedLibraries}" TYPE SHARED_LIBRARY )

	set(${librariesOut} "${sharedLibraries}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetSharedLibrariesRequiredByPackageProductionLib librariesOut packageComponent )

	get_property( productionLib TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET )
	cpfGetRecursiveLinkedLibraries( linkedLibraries ${productionLib} all)
	if(linkedLibraries)
		list(REMOVE_DUPLICATES linkedLibraries)
	endif()

	cpfFilterInTargetsWithProperty( sharedLibraries "${linkedLibraries}" TYPE SHARED_LIBRARY )

	set(${librariesOut} "${sharedLibraries}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Recursively get either imported or non-imported linked shared libraries of the target.
# config:	Can be "all" or a specific configuration. This option is used when the libraries list contains
# targets that are only linked for a special configuration via generator expression $<$<CONFIG:Release>:lib1;lib2>
# interfaceOnly: Only get the publicly linked tree. This are the dependencies whichs headers are visible to target.
#
function( cpfGetRecursiveLinkedLibraries linkedLibsOut target config)

	cpfGetLinkedTargets(linkedTargets ${target} ${config} BOTH)

	set(outputLocal)
	foreach( lib ${linkedTargets})
		list( APPEND outputLocal ${lib} )
		cpfGetRecursiveLinkedLibraries( subLibs ${lib} ${config})
		list( APPEND outputLocal ${subLibs} )
	endforeach()

	if(outputLocal)
		list(REMOVE_DUPLICATES outputLocal)
	endif()

	set(${linkedLibsOut} ${outputLocal} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetLinkedTargets targetsOut target config linkVisibility)

	get_property(interfaceLibrariesTemp TARGET ${target} PROPERTY INTERFACE_LINK_LIBRARIES) # The linked libraries for non imported targets
	# Remove some of the possible generator expressions that can appear in the link tree.
	cpfRemoveConfigGeneratorExpressions(interfaceLibraries "${interfaceLibrariesTemp}" ${config})

	# The following property can not be accessed for interface libraries.
	set(allLinkedLibraries)
	get_property(type TARGET ${target} PROPERTY TYPE)	
	if(NOT ${type} STREQUAL INTERFACE_LIBRARY )	

		get_property(allLinkedLibraries TARGET ${target} PROPERTY LINK_LIBRARIES)		# The linked libraries for non imported targets

		cpfGetConfigVariableSuffixes(configSuffixes)
		foreach(configSuffix ${configSuffixes})
			
			# The libraries that are used in the header files of the target
			get_property(importedInterfaceLibraries TARGET ${target} PROPERTY IMPORTED_LINK_INTERFACE_LIBRARIES_${configSuffix})		
			list(APPEND interfaceLibraries ${importedInterfaceLibraries})

			get_property(importedPrivateLibraries TARGET ${target} PROPERTY IMPORTED_LINK_DEPENDENT_LIBRARIES_${configSuffix})
			list(APPEND allLinkedLibraries ${importedPrivateLibraries})

		endforeach()
	endif()

	list(APPEND allLinkedLibraries ${interfaceLibraries})
	if(${linkVisibility} STREQUAL INTERFACE)
		set(linkedLibraries ${interfaceLibraries})
	elseif(${linkVisibility} STREQUAL PRIVATE)
		cpfSetDifference(privateLibraries "${allLinkedLibraries}" "${interfaceLibraries}")
		set(linkedLibraries ${privateLibraries})
	elseif(${linkVisibility} STREQUAL BOTH)
		set(linkedLibraries ${allLinkedLibraries})
	else()
		message(FATAL_ERROR "Unexpected value for argument linkVisibility.")
	endif()

	if(linkedLibraries)
		list(REMOVE_DUPLICATES linkedLibraries)
	endif()

	# Ignore libaries that are linked via generator expression or library file name.
	set(linkedTargets)
	foreach(lib ${linkedLibraries})
		if(TARGET ${lib})
			list(APPEND linkedTargets ${lib})
		else()
			cpfDebugMessage("Ignored dependency ${lib} while accumulating the dependency tree because it is not a cmake target.")
		endif()
	endforeach()

	set(${targetsOut} "${linkedTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# The function removes libraries from the list that are wrapped in config generator expressions like
# $<$<CONFIG:Release>:CONAN_LIB::GTest_gmock_mainrelease;CONAN_LIB::GTest_gmockrelease;CONAN_LIB::GTest_gtestrelease>
#
function( cpfRemoveConfigGeneratorExpressions libsOut libs config)

	cpfGetConfigGenExpRegExp(configRegexp ${config})

	set(cleanLibs)
	if(${config} STREQUAL all)

		set(openRegexp FALSE)
		foreach(lib ${libs})

			if(${lib} MATCHES ${configRegexp}) # check for an opening config regexp
				string(REGEX REPLACE ${configRegexp} "" lib ${lib} )
				list(APPEND cleanLibs ${lib})
				set(openRegexp TRUE)
			elseif(${lib} STREQUAL ">")
				# ignore the closing braket
				set(openRegexp FALSE)
			else()
				# keep libraries without config generator expression.
				list(APPEND cleanLibs ${lib})
			endif()

		endforeach()

	else()

		cpfGetConfigGenExpRegExp(configRegexpAll all)
		set(openRegexp FALSE)
		set(openOtherConfigRegexp FALSE)
		foreach(lib ${libs})

			if(${lib} MATCHES ${configRegexp}) 

				# handle the opening generator expression for the given config.
				string(REGEX REPLACE ${configRegexp} "" lib ${lib} )
				list(APPEND cleanLibs ${lib})
				set(openRegexp TRUE)

			elseif(${lib} STREQUAL ">")
				# ignore the closing braket
				set(openRegexp FALSE)
				set(openOtherConfigRegexp FALSE)
			elseif(${lib} MATCHES ${configRegexpAll})
				# start ignoring libs that match other configs then the given one.
				set(openOtherConfigRegexp TRUE)
			elseif(openOtherConfigRegexp)
				# ignore libs that are only relevant for other configs
			else()
				# keep libraries without config generator expression.
				list(APPEND cleanLibs ${lib})
			endif()

		endforeach()

	endif()

	set(${libsOut} "${cleanLibs}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetConfigGenExpRegExp regexpOut config )

	if(${config} STREQUAL all)
		set(${regexpOut} "\\\$<\\\$<CONFIG:[a-zA-Z]*>:" PARENT_SCOPE)
	else()
		set(${regexpOut} "\\\$<\\\$<CONFIG:${config}>:" PARENT_SCOPE)
	endif()

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
		cpfGetRecursiveLinkedLibraries( indirectlyLinkedTargets ${target} all)
		list(APPEND allLinkedTargets ${target} ${indirectlyLinkedTargets} )
	endforeach()
	if(allLinkedTargets)
		list(REMOVE_DUPLICATES allLinkedTargets)
	endif()
	set(${targetsOut} ${allLinkedTargets} PARENT_SCOPE)

endfunction()