include_guard(GLOBAL)


#----------------------------------------------------------------------------------------
# Creates a target that runs Qt's uic on all .ui files of the given binaryTargetName
#
# This is a helper target that needs to be hit before the runStaticAnalysis target can be run.
#
# BINARY_TARGET: The name of the binary target to which the ui_files belong
#		 
function( cpfAddRunUicTarget)

	cmake_parse_arguments(ARG "" "BINARY_TARGET" "" ${ARGN} )

	set(targetName ${ARG_BINARY_TARGET}_runUic)

    # Create the commands for the uic calls
	cpfGetTargetSourceFiles(files ${ARG_BINARY_TARGET})
    foreach( file ${files} )

        get_filename_Component( extension ${file} EXT)
        if( ${extension} STREQUAL .ui )
    
            get_filename_component( baseName ${file} NAME_WE)
            set(generatedFile "${CMAKE_CURRENT_BINARY_DIR}/ui_${baseName}.h")
            
            set(command "${TOOL_UIC} -o \"${generatedFile}\" \"${CMAKE_CURRENT_SOURCE_DIR}/${file}\"")
			cpfAddStandardCustomCommand(
				OUTPUT ${generatedFile}
				DEPENDS ${file}
				COMMANDS ${command}
			)
            list( APPEND generatedFiles ${generatedFile})
            
        endif()

    endforeach()

	if(generatedFiles)
		add_custom_target( 
			${targetName}
			DEPENDS ${generatedFiles}
		)

		get_property(baseFolder TARGET ${ARG_BINARY_TARGET} PROPERTY FOLDER )
		set_property(TARGET ${targetName} PROPERTY FOLDER ${baseFolder}/private)
		set_property(TARGET ${ARG_BINARY_TARGET} PROPERTY INTERFACE_CPF_UIC_SUBTARGET ${targetName})

	endif()

endfunction()
