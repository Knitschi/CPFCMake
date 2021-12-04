include_guard(GLOBAL)

include(CMakePackageConfigHelpers)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfProjectUtilities)
include(cpfAddDeploySharedLibrariesTarget)

#---------------------------------------------------------------------------------------------
# Adds a bundle target for all install_<package> targets
function( cpfAddGlobalInstallTarget )
	cpfAddSubTargetBundleTarget( install_all "${packages}" INTERFACE_CPF_INSTALL_PACKAGE_SUBTARGET "")
endfunction()

#---------------------------------------------------------------------------------------------
# Adds an install_<package> target that installs all components of the package.
# 
function( cpfAddPackageInstallTarget package )
	
	cpfAssertDefined(CMAKE_INSTALL_PREFIX)	# The install targets require the definition of the CMAKE_INSTALL_PREFIX path.
	
	# Add the install_<package> target that installs all install-components of the package-component to the install prefix.
	cpfGetPossibleInstallComponents(components)
	set(installTargetName install_${package})
	cpfAddInstallTarget( ${package} ${installTargetName} "${components}" ${CMAKE_INSTALL_PREFIX}/${package} FALSE ${package}/pipeline)
	# Add the target to the packaget property.
	set_property(TARGET ${package} PROPERTY INTERFACE_CPF_INSTALL_PACKAGE_SUBTARGET ${installTargetName} )

endfunction()

#---------------------------------------------------------------------------------------------
function(cpfGetPossibleInstallComponents componentsOut)

	set(${componentsOut}
		runtime
		developer
		sources
		documentation
		packageArchives
		PARENT_SCOPE
	)

endfunction()

#---------------------------------------------------------------------------------------------
function(cpfAddInstallTarget package installTargetName components destDir clearDestDir vsTargetFolder )

	cpfGetPackageComponents(packageComponents ${package})

	set(fileDependencies)
	set(targetDependencies)
	foreach(packageComponent ${packageComponents} ${package}) # The package dummy target may hold the package archive targets as subtargets.
		cpfGetInstallTargetDependencies( fileDependenciesComponent targetDependenciesComponent ${packageComponent} "${components}")
		cpfListAppend(fileDependencies ${fileDependenciesComponent})
		cpfListAppend(targetDependencies ${targetDependenciesComponent})
	endforeach()

	# Get the commands
	set(clearDestDirCommands)
	if(clearDestDir)
		cpfGetClearDirectoryCommands(clearDestDirCommands ${destDir})
	endif()
	cpfGetRunInstallScriptCommands(installCommands $<CONFIG> "${components}" ${destDir})
	cpfGetTouchTargetStampCommand(touchCommand stampFile ${installTargetName})

	cpfAddStandardCustomCommand(
		DEPENDS ${fileDependencies}
		COMMANDS ${clearDestDirCommands} ${installCommands} ${touchCommand}
		OUTPUT ${stampFile}
		WORKING_DIRECTORY ${CPF_ROOT_DIR}
	)

	# Add install target
	add_custom_target(
		${installTargetName}
		DEPENDS ${stampFile} ${targetDependencies}
	)

	# Set target properties
	set_property(TARGET ${installTargetName} PROPERTY CPF_OUTPUT_FILES ${stampFile} )
	set_property(TARGET ${installTargetName} PROPERTY FOLDER ${vsTargetFolder} )
	set_property(TARGET ${package} APPEND PROPERTY INTERFACE_CPF_PACKAGE_SUBTARGETS ${installTargetName} )

endfunction()


#---------------------------------------------------------------------------------------------
function( cpfGetInstallTargetDependencies fileDependenciesOut targetDependenciesOut packageComponent components )

	set(fileDependencies)
	set(targetDependencies)

	get_property(subtargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PACKAGE_SUBTARGETS)

	foreach(target ${subtargets})

		# Only add the target if it installs to the 
		get_property(targetInstallComponents TARGET ${target} PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS)

		foreach(component ${components})

			# Only add the target to the dependencies if it contributes files to the
			# current component.
			cpfContains(hasComponent "${targetInstallComponents}" ${component})
			if(hasComponent)

				cpfIsBinaryTarget( isBinaryTarget ${target})
				if(isBinaryTarget)

					cpfIsInterfaceLibrary( isIntLib ${target})
					if(NOT isIntLib)
						cpfListAppend(fileDependencies $<TARGET_FILE:${target}>)
					endif()

				else()

					get_property(outputFiles TARGET ${target} PROPERTY CPF_OUTPUT_FILES)
					cpfListAppend(fileDependencies ${outputFiles})

				endif()

				cpfListAppend(targetDependencies ${target})

			endif()

		endforeach()
	endforeach()

	if(fileDependencies)
		list(REMOVE_DUPLICATES fileDependencies)
	endif()

	if(targetDependencies)
		list(REMOVE_DUPLICATES targetDependencies)
	endif()

	set(${fileDependenciesOut} "${fileDependencies}" PARENT_SCOPE)
	set(${targetDependenciesOut} "${targetDependencies}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetRunInstallScriptCommand runInstallScriptCommandOut config component destDir )

	set(scriptFile "${CMAKE_CURRENT_BINARY_DIR}/cmake_install.cmake")

	if(config)
		set(configOption "-DCMAKE_INSTALL_CONFIG_NAME=${config}")
	endif()

	set( ${runInstallScriptCommandOut} "\"${CMAKE_COMMAND}\" -DCMAKE_INSTALL_PREFIX=\"${destDir}\" -DCMAKE_INSTALL_COMPONENT=${component} ${configOption} -P \"${scriptFile}\"" PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetRunInstallScriptCommands runInstallScriptCommandsOut config components destDir )

	set(commands)
	foreach(component ${components})
		cpfGetRunInstallScriptCommand( command "${config}" ${component} ${destDir})
		cpfListAppend( commands ${command} )
	endforeach()

	set( ${runInstallScriptCommandsOut} "${commands}" PARENT_SCOPE )

endfunction()

