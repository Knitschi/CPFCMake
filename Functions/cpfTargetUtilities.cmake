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
function( cpfTargetIsDynamicLibrary bOut target)
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
	get_property( binaryTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS)
	foreach( binaryTarget ${binaryTargets})
		cpfTargetIsDynamicLibrary( isDynamic ${binaryTarget})
		if(isDynamic)
			cpfListAppend( libraryTargets ${binaryTarget})
		endif()
	endforeach()
	
	set( ${librarySubTargetsOut} "${libraryTargets}" PARENT_SCOPE)
	
endfunction()


