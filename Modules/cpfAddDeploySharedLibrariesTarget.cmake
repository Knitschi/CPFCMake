include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfProjectUtilities)
include(cpfLinkTreeUtilities)
include(cpfOutputPathUtilities)

#----------------------------------------------------------------------------------------
# Adds a target that copies depended on shared libraries to the binaryTargets output directory.
# linkedLibrarie can contain all linked libraries of the target. The function will pick
# the shared libraries by itself. 
#
function( cpfAddDeploySharedLibrariesTarget package )

	# Only deploy shared libraries on windows. On Linux CMake uses the RPATH to make it work.
	if(NOT ${CMAKE_SYSTEM_NAME} STREQUAL Windows)
		return()
	endif()

	cpfAddDeploySharedLibsToBuildStageTarget( ${package} "" "" ) 

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeploySharedLibsToBuildStageTarget package libs subdirectory)

	# Add one custom target to copy all external libs.
	cpfGetIndexedTargetName(targetName deployExternal_${package})

	set(outputs)

	# Add a copy command for the current version.
	cpfGetConfigurations(configs)
	foreach(config ${configs})

		if(NOT libs)
			cpfGetSharedLibrariesRequiredByPackageExecutables( libs ${package} ${config} )
		endif()

		foreach(lib ${libs})

			# Deploy the dll files
			cpfGetLibFilePath( libFile ${lib} ${config})
			cpfAddDeployCommand( outputs ${targetName} ${package} ${config} "${subdirectory}" ${lib} ${libFile} "${outputs}")

			# Deploy the liner pdb files if they are available.
			cpfGetImportedLibPdbFilePath( libPdbFile ${lib} ${config})
			if(libPdbFile)
				cpfAddDeployCommand( outputs ${targetName} ${package} ${config} "${subdirectory}" ${lib} ${libPdbFile} "${outputs}")
			endif()

		endforeach()

	endforeach()

	cpfAddDeployTarget( ${targetName} ${package} "${outputs}" "${libs}" )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetIndexedTargetName indexedName baseName )

	set(index 0)
	while(TARGET ${baseName}_${index})
		cpfIncrement(index)
	endwhile()

	set(${indexedName} ${baseName}_${index} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeployCommand outputsOut targetName package config outputSubDir lib libFile existingOutputs )

	cpfGetSharedLibraryOutputDir( targetDir ${package} ${config} )

	get_filename_component( shortName ${libFile} NAME)

	if(outputSubDir)
		set(output "${targetDir}/${outputSubDir}/${shortName}")
	else()
		set(output "${targetDir}/${shortName}")
	endif()

	set(outputs)
	cpfContains( alreadyCopied existingOutputs ${output})

	if(NOT ("${libFile}" STREQUAL "${output}") AND NOT alreadyCopied )  # Do not deploy the library that belongs to the same package or one that has already been copied.

		get_property( isImported TARGET ${lib} PROPERTY IMPORTED)
		if(isImported)

			# For external libraries we can not use a config dependent
			# deployment, because touched files are never overwritten by
			# the real files. So we deploy all libraries for all configurations.
			cpfAddCustomCommandCopyFile( ${libFile} ${output} )

		else()

			# Internal libraries are updated when the current compiler configuration changes, 
			# so we can add a configuration only deploy command.

			set(copyCommand "cmake -E copy \"${libFile}\" \"${output}\"")
			set(touchCommand "cmake -E touch \"${output}\"")

			cpfAddConfigurationDependendCommand(
				CONFIGS ${config}
				DEPENDS ${lib} ${libFile}
				COMMANDS ${copyCommand}
				OUTPUT ${output}
				COMMENT "Copy \"${libFile}\" to \"${output}\""
			)

		endif()

		cpfListAppend(outputs ${output})

	endif()

	cpfListAppend(existingOutputs ${outputs})
	set(${outputsOut} "${existingOutputs}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddDeployTarget targetName package outputs libs ) 

	if(outputs)

		add_custom_target(
			${targetName}
			DEPENDS ${outputs} ${libs}
		)
		set_property(TARGET ${targetName} PROPERTY FOLDER ${package}/private)

		# make sure the copying is done before the target is build
		cpfGetExecutableTargets(exeTargets ${package})
		foreach(exeTarget ${exeTargets})
			add_dependencies( ${exeTarget} ${targetName} )
		endforeach()

	endif()

endfunction()

