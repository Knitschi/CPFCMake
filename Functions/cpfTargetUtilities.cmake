include_guard(GLOBAL)


# This file contains functions that operate on targets


#----------------------------------------------------------------------------------------
# Returns true if the target is an executable.
function( cpfIsExecutable isExeOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL EXECUTABLE)
        set(${isExeOut} TRUE PARENT_SCOPE)
    else()
        set(${isExeOut} FALSE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the target is a SHARED_LIBRARY or MODULE_LIBRARY
function( cpfIsDynamicLibrary bOut target)
	get_property( type TARGET ${target} PROPERTY TYPE )
	if(${type} STREQUAL SHARED_LIBRARY OR ${type} STREQUAL MODULE_LIBRARY)
		set(${bOut} TRUE PARENT_SCOPE)
	else()
		set(${bOut} FALSE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the given target is an INTERFACE_LIBRARY
function( cpfIsStaticLibrary isStaticLibOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL STATIC_LIBRARY)
        set(${isStaticLibOut} TRUE PARENT_SCOPE)
    else()
        set(${isStaticLibOut} FALSE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the given target is an INTERFACE_LIBRARY
function( cpfIsInterfaceLibrary isIntLibOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL INTERFACE_LIBRARY)
        set(${isIntLibOut} TRUE PARENT_SCOPE)
    else()
        set(${isIntLibOut} FALSE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the binary sub-targets that are of type SHARED_LIBRARY or MODULE_LIBRARY.
function( cpfGetSharedLibrarySubTargets librarySubTargetsOut package)

	set(libraryTargets)
	get_property( binaryTargets TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)
	foreach( binaryTarget ${binaryTargets})
		cpfIsDynamicLibrary( isDynamic ${binaryTarget})
		if(isDynamic)
			cpfListAppend( libraryTargets ${binaryTarget})
		endif()
	endforeach()
	
	set( ${librarySubTargetsOut} "${libraryTargets}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Returns $<TARGET_FILE:<target>> if the target is not an interface library,
# othervise it returns an empty string.
function( cpfGetTargetFileGeneratorExpression expOut target)
	set(file)
	cpfIsInterfaceLibrary(isIntLib ${productionLib})
	if(NOT isIntLib)
		set(file "$<TARGET_FILE:${productionLib}>")
	endif()
	set(${expOut} "${file}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This reads the source files from the targets SOURCES property or in case of interface 
# library targets from the targets file container target.
#
function( cpfGetTargetSourceFiles filesOut target)
	cpfIsInterfaceLibrary( isIntLib ${target})
	if(NOT isIntLib)
		get_property(sources TARGET ${target} PROPERTY SOURCES)
	else()
		# Interface libraries can only have public header files as sources.
		get_property(filesTarget TARGET ${target} PROPERTY INTERFACE_CPF_FILE_CONTAINER_SUBTARGET )
		get_property(sources TARGET ${filesTarget} PROPERTY SOURCES)
	endif()
	set(${filesOut} "${sources}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetSubtargets subTargetsOut packages subtargetProperty)

	set(targets)
	foreach(package ${packages})
		if(TARGET ${package}) # not all packages have targets
			
			# check for subtargets that belong to the package
			get_property(subTarget TARGET ${package} PROPERTY ${subtargetProperty})
			cpfListAppend( targets ${subTarget} )

			# check for subtargets that belong to the binary targets
			get_property(binaryTargets TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)
			foreach(binaryTarget ${binaryTargets})
				get_property(subTarget TARGET ${binaryTarget} PROPERTY ${subtargetProperty})
				cpfListAppend( targets ${subTarget} )
			endforeach()
			
		endif()
	endforeach()
	set(${subTargetsOut} "${targets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Sorts the source files of the target into various folders for Visual Studio.
# 
# Remarks
# I failed to add the cotire prefix header to the generated files because
# it does not belong to the target.
# The ui_*.h files could also not be added to the generated files because they do not exist when the target is created.
function( cpfSetIDEDirectoriesForTargetSources targetName )

	cpfIsInterfaceLibrary(isInterfaceLib ${targetName})
	if(isInterfaceLib)
		return()
	endif()

    # get the source files in the Sources directory
	get_target_property( sourceDir ${targetName} SOURCE_DIR)
	getAbsPathesForSourceFilesInDir( sourcesFiles ${targetName} ${sourceDir})
	# get the generated source files in the binary directory
	get_target_property( binaryDir ${targetName} BINARY_DIR)
	getAbsPathesForSourceFilesInDir( generatedFiles ${targetName} ${binaryDir})
	# manually add a file that is generated by automoc and not visible here
	list(APPEND generatedFiles ${CMAKE_CURRENT_BINARY_DIR}/${targetName}_autogen/moc_compilation.cpp) 
	
	# set source groups for generated files that do exist
	source_group(Generated FILES ${generatedFiles})
	
	# set the file groups of the files in the Source directory to follow the directory structure
	cpfGetRelativePaths( sourcesFiles "${sourceDir}" "${sourcesFiles}")
	cpfSourceGroupTree("${sourcesFiles}")

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddAliasTarget target packageNamespace )

	cpfIsExecutable(isExe ${target})
	if(isExe)
		add_executable(${packageNamespace}::${target} ALIAS ${target})
	else()
		add_library(${packageNamespace}::${target} ALIAS ${target})
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# Goes through the given targets and in case that a target is an alias target replaces them
# with the name of the original target.
function( cpfStripTargetAliases deAliasedTargetsOut targets)
	
	set(deAliasedTargets)
	foreach(target ${targets})
		get_property(aliasedTarget TARGET ${target} PROPERTY ALIASED_TARGET)
		if(aliasedTarget)
			cpfListAppend(deAliasedTargets ${aliasedTarget})
		else()
			cpfListAppend(deAliasedTargets ${target})
		endif()
	endforeach()
	set(${deAliasedTargetsOut} "${deAliasedTargets}" PARENT_SCOPE)

endfunction()

