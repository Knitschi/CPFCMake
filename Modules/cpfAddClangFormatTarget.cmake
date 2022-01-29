include_guard(GLOBAL)

#--------------------------------------------------------------------------------------
# See api docs for ducumentation.
function( cpfAddGlobalClangFormatTarget packages)

    if(NOT CPF_ENABLE_CLANG_FORMAT_TARGETS)
        return()
    endif()

    set(targetName clang-format)

    # add bundle target
    cpfAddSubTargetBundleTarget( ${targetName} "${packages}" INTERFACE_CPF_CLANG_FORMAT_SUBTARGET "")

endfunction()

#--------------------------------------------------------------------------------------
function( cpfAddPackageClangFormatTarget package)

    if(NOT CPF_ENABLE_CLANG_FORMAT_TARGETS)
        return()
    endif()

    set(targetName clang-format_${package})

    # add bundle target
    cpfAddSubTargetBundleTarget(${targetName} "${package}" INTERFACE_CPF_CLANG_FORMAT_SUBTARGET "")
    if(TARGET  ${targetName})
        set_property(TARGET ${targetName} PROPERTY FOLDER  ${package}/package)
        add_dependencies(pipeline_${package} ${targetName})
    endif()

endfunction()

#--------------------------------------------------------------------------------------
function( cpfAddClangFormatTarget packageComponent target )

	cpfAssertDefined(TOOL_CLANG_FORMAT)

    set(targetName clang-format_${target} )

    # Locations
    set( stampFileDir "${CMAKE_CURRENT_BINARY_DIR}/${targetName}")
    set( stampFile "${stampFileDir}/${targetName}.stamp")

    getAbsPathsOfTargetSources(sources ${target})
    # Only apply to files clang-format can handle.
    set(clangFormatExtensions cpp c h hpp js java proto)
    cpfGetFilepathsWithExtensions( sources "${sources}" "${clangFormatExtensions}")

    cpfJoinString(sourceString "${sources}" "\" \"")
    set(clangFormatCommand "\"${TOOL_CLANG_FORMAT}\" -i -style=file \"${sourceString}\"")
    separate_arguments(clangFormatCommandList NATIVE_COMMAND ${clangFormatCommand})

    set(CPF_CLANG_FORMAT_STYLE_FILE "${CMAKE_SOURCE_DIR}/.clang-format")
    if(NOT EXISTS ${CPF_CLANG_FORMAT_STYLE_FILE})
        message(FATAL_ERROR "You need to add a <root>/Sources/.clang-format file to your project when setting the CPF_ENABLE_CLANG_FORMAT_TARGETS option to ON.")
    endif()

    add_custom_command(
        DEPENDS ${sources} ${CPF_CLANG_FORMAT_STYLE_FILE}
        COMMAND ${clangFormatCommandList}
        COMMAND "${CMAKE_COMMAND}" -E make_directory ${stampFileDir}
        COMMAND "${CMAKE_COMMAND}" -E touch ${stampFile}
        OUTPUT ${stampFile}
        COMMENT "${clangFormatCommand}"
        WORKING_DIRECTORY ${CPF_ROOT_DIR}
        VERBATIM
        )

    add_custom_target( ${targetName} DEPENDS ${stampFile} )
    cpfGetComponentVSFolder(packageFolder ${CPF_CURRENT_PACKAGE} ${packageComponent})
    set_property(TARGET ${targetName} PROPERTY FOLDER ${packageFolder}/pipeline )
    set_property(TARGET ${target} PROPERTY INTERFACE_CPF_CLANG_FORMAT_SUBTARGET ${targetName} )

endfunction()

