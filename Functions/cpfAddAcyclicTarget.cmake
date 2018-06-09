include_guard(GLOBAL)

include(cpfLocations)

#----------------------------------------------------------------------------------------
# Creates a global custom target that runs the graphviz tool "acyclic" on the target
# dependency tree of the cpf-project. The target will fail to build if cyclic dependencies
# are detected.
#
function( cpfAddAcyclicTarget )

    if(NOT CPF_ENABLE_ACYCLIC_TARGET)
        return()
    endif()

    set(targetName acyclic)

    # Add the command for doing the acyclicity check
    set(command "\"${TOOL_ACYCLIC}\" -nv \"${CPF_TARGET_DEPENDENCY_GRAPH_FILE}\"")
    set(acyclicStampFile ${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName}/runAcyclic.stamp )

    cpfAddStandardCustomCommand(
        OUTPUT ${acyclicStampFile}
        DEPENDS ${CPF_TARGET_DEPENDENCY_GRAPH_FILE}
        COMMANDS ${command} "cmake -E touch \"${acyclicStampFile}\""
    )
    
    add_custom_target(
        ${targetName}
        DEPENDS ${acyclicStampFile}
    )

endfunction()