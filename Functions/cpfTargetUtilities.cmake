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

