include_guard(GLOBAL)

include(cpfAddRunUicTarget)
include(cpfLocations)

#----------------------------------------------------------------------------------------
# Creates a target that runs all the static analysis targets that are added by the given packages
# The target will also check that the target dependency graph is acyclic.
#
function( cpfAddGlobalClangTidyTarget packages)

    set(targetName clang-tidy)

	# Create the .json compile command file.
	# This is needed for the clang-tidy calls
	cpfGetCompiler(compiler)
	if( ${compiler} STREQUAL Clang)
		set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Create a .json file that contains all compiler calls. This is needed for clang-tidy." FORCE)
	endif()

    # add bundle target
    cpfAddSubTargetBundleTarget( ${targetName} "${packages}" INTERFACE_CPF_CLANG_TIDY_SUBTARGET "")

endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddPackageClangTidyTarget package)

    set(targetName clang-tidy_${package})

    if(NOT (TARGET ${targetName}))
        # add bundle target
        cpfAddSubTargetBundleTarget(${targetName} "${package}" INTERFACE_CPF_CLANG_TIDY_SUBTARGET "")
        if(TARGET  ${targetName})
            set_property(TARGET ${targetName} PROPERTY FOLDER  ${package}/package)
            add_dependencies(pipeline_${package} ${targetName})
        endif()
    else()
        add_dependencies(pipeline_${package} ${targetName})
    endif()

endfunction()

#----------------------------------------------------------------------------------------
# Adds a custom target that runs the clang-tidy on all .cpp files that belong to the given target.
#
# Arguments:
# BINARY_TARGET The name of the target that shall be analyzed
#
function( cpfAddClangTidyTarget binaryTarget )

	cpfGetCompiler(compiler)
    if( ${compiler} STREQUAL Clang)
    
        if(NOT CMAKE_EXPORT_COMPILE_COMMANDS)
            cpfGetFullConfigFilePath(configFile ${CPF_CONFIG} ${CPF_ROOT_DIR})
            message(FATAL_ERROR "You need to set the CMake -D option CMAKE_EXPORT_COMPILE_COMMANDS to TRUE when clang-tidy targets are enabled with option CPF_ENABLE_CLANG_TIDY_TARGET.")
        endif()

		# Add an extra target for running uic. 
		# Usually uic is automatically run before building, but we want to build
		# this target without building the binaries so we need an extra target
		# that runs uic for us.
		cpfAddRunUicTarget(BINARY_TARGET ${binaryTarget})

        set(targetName clang-tidy_${binaryTarget})


        # The checks we want to have
        set(includedChecks clang-analyzer-*,cppcoreguidelines-*,google-*,misc-*)
        
        # Checks we excluded because we do not like them
        set(deliberatelyExcludedChecks
            -clang-analyzer-alpha*                  # We dont want to be alpha tester
            -google-readability-namespace-comments  # Demands the name of the namespace in a comment at the closing brace
            -google-runtime-references              # This warns when using non const refs as function arguments
        )
        
        # Create a comma separated list for the argument
        foreach( check ${deliberatelyExcludedChecks})
                set(commaDeliberatelyExcludedChecks ${commaDeliberatelyExcludedChecks},${check})
        endforeach()
        
        set(command "\"${TOOL_CLANG_TIDY}\" -checks=${includedChecks}${commaDeliberatelyExcludedChecks} -warnings-as-errors=* -p \"${CMAKE_BINARY_DIR}\"")

        get_property( uicTarget TARGET ${binaryTarget} PROPERTY INTERFACE_CPF_UIC_SUBTARGET )
        if(uicTarget)
            get_property( uicStamp TARGET ${uicTarget} PROPERTY TARGET_STAMP_FILE )
        endif()
        
        set(prefixHeader)
        cpfIsInterfaceLibrary(isIntLib ${binaryTarget})
        if(NOT isIntLib)
            get_property( prefixHeader TARGET ${binaryTarget} PROPERTY COTIRE_CXX_PREFIX_HEADER)
        endif()

        cpfGetTargetSourceFiles(files ${binaryTarget})
        foreach( file ${files}  )

			get_filename_component( extension ${file} EXT)
			if(${extension} STREQUAL .cpp) 
			
				get_filename_component( baseName ${file} NAME_WE)
				set(stampFile ${CMAKE_CURRENT_BINARY_DIR}/clang-tidy_${baseName}.stamp )
				set(fullFile ${CMAKE_CURRENT_SOURCE_DIR}/${file})
				if(EXISTS ${fullFile}) # do not call clang-tidy for source files that are generated later in the make step
				
                    set(commandWithFile "${command} \"${fullFile}\"")
                    separate_arguments(commandList NATIVE_COMMAND ${commandWithFile})
                    add_custom_command(
                        OUTPUT ${stampFile}
                        DEPENDS "${fullFile}" "${uicStamp}" "${prefixHeader}" ${uicTarget}
                        IMPLICIT_DEPENDS CXX "${fullFile}"
                        COMMAND ${commandList}
                        COMMAND cmake -E touch "${stampFile}"   # without a file as a touch-stone the command will always be re-run.
                        WORKING_DIRECTORY ${CPF_ROOT_DIR}
                        COMMENT "${commandWithFile}"
                        VERBATIM
                        )
                    
                    cpfListAppend( stampFiles ${stampFile})

                endif()
			endif()
        endforeach()
        set_source_files_properties("${stampFiles}" PROPERTIES GENERATED TRUE)   # mark the output file as one that is not created on disc.
        add_custom_target( 
			${targetName}
			DEPENDS ${stampFiles} ${uicTarget}
		)
        set_property(TARGET ${binaryTarget} PROPERTY INTERFACE_CPF_CLANG_TIDY_SUBTARGET ${targetName})

    else()
        message( WARNING "clang-tidy targets can only be added when using the clang-compiler.")
    endif()
    
endfunction()
