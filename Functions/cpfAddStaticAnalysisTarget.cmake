

include(cpfAddRunUicTarget)
include(cpfLocations)

#----------------------------------------------------------------------------------------
# Creates a target that runs all the static analysis targets that are added by the given packages
# The target will also check that the target dependency graph of all packages is acyclic.
#
function( cpfAddGlobalStaticAnalysisTarget packages)

	if(NOT CPF_ENABLE_STATIC_ANALYSIS_TARGET)
		return()
	endif()

    set(targetName staticAnalysis)

	# Create the .json compile command file.
	# This is needed for the clang-tidy calls
	cpfGetCompiler(compiler)
	if( ${compiler} STREQUAL Clang)
		set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Create a .json file that cpfContains all compiler calls. This is needed for clang-tidy." FORCE)
	endif()

	# get all static analysis targets from the packages
    foreach(package ${packages})

        if(TARGET ${package}) # not all packages may have a target
            get_property( binarySubTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS)
            foreach( binaryTarget ${binarySubTargets})
            
                get_property( staticAnalysisTarget TARGET ${binaryTarget} PROPERTY CPF_STATIC_ANALYSIS_SUBTARGET)

                if(staticAnalysisTarget)	# this is currently only available for the LinuxMakeClang toolchain.
                    list(APPEND staticAnalysisTargets ${staticAnalysisTarget})
                endif()
                
            endforeach()
        endif()
    
    endforeach()
    
    # Add the command for doing the acyclicity check
    set(command "\"${TOOL_ACYCLIC}\" -nv \"${CPF_TARGET_DEPENDENCY_GRAPH_FILE}\"")
    set(acyclicStampFile ${CMAKE_BINARY_DIR}/runAcyclic.stamp )

	cpfAddStandardCustomCommand(
		OUTPUT ${acyclicStampFile}
		DEPENDS ${CPF_TARGET_DEPENDENCY_GRAPH_FILE} ${staticAnalysisTargets}
		COMMANDS ${command} "cmake -E touch \"${acyclicStampFile}\""
	)
    
	add_custom_target(
		${targetName}
		DEPENDS ${acyclicStampFile} ${staticAnalysisTargets}
	)

endfunction()

#----------------------------------------------------------------------------------------
# Adds a custom target that runs the clang-tidy on all .cpp files that belong to the given target.
#
# Arguments:
# BINARY_TARGET The name of the target that shall be analyzed
#
function( cpfAddStaticAnalysisTarget )

	if(NOT CPF_ENABLE_STATIC_ANALYSIS_TARGET)
		return()
	endif()
	
	cpfGetCompiler(compiler)
    if( ${compiler} STREQUAL Clang)
    
		cmake_parse_arguments(ARG "" "BINARY_TARGET" "" ${ARGN} )

		# Add an extra target for running uic. 
		# Usually uic is automatically run before building, but we want to build
		# this target without building the binaries so we need an extra target
		# that runs uic for us.
		cpfAddRunUicTarget(BINARY_TARGET ${ARG_BINARY_TARGET})

        set(targetName ${ARG_BINARY_TARGET}_runStaticAnalysis)


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

        get_property( uicTarget TARGET ${ARG_BINARY_TARGET} PROPERTY CPF_UIC_SUBTARGET )
        if(uicTarget)
            get_property( uicStamp TARGET ${uicTarget} PROPERTY TARGET_STAMP_FILE )
        endif()
        
        get_property( prefixHeader TARGET ${ARG_BINARY_TARGET} PROPERTY COTIRE_CXX_PREFIX_HEADER)
        
		get_property(files TARGET ${ARG_BINARY_TARGET} PROPERTY SOURCES)
        foreach( file ${files}  )

			get_filename_component( extension ${file} EXT)
			if(${extension} STREQUAL .cpp) 
			
				get_filename_component( baseName ${file} NAME_WE)
				set(stampFile ${CMAKE_CURRENT_BINARY_DIR}/clang-tidy_${baseName}.stamp )
				set(fullFile ${CMAKE_CURRENT_SOURCE_DIR}/${file})
				if(EXISTS ${fullFile}) # do not call clang-tidy for source files that are generated later in the make step
				
                    set(commandWithFile "${command} \"${fullFile}\"")
                    cpfSeparateArgumentsForPlatform( commandList ${commandWithFile})
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
                    
                    list(APPEND stampFiles ${stampFile})

                endif()
			endif()
        endforeach()
        set_source_files_properties("${stampFiles}" PROPERTIES GENERATED TRUE)   # mark the output file as one that is not created on disc.
        add_custom_target( 
			${targetName}
			DEPENDS ${stampFiles} ${uicTarget}
		)
        set_property(TARGET ${ARG_BINARY_TARGET} PROPERTY CPF_STATIC_ANALYSIS_SUBTARGET ${targetName})

    endif()
    
endfunction()
