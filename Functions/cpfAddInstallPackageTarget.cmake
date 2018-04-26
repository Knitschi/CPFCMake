include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfProjectUtilities)



#----------------------------------------------------------------------------------------
# This function adds per package install targets and packaging targets.
# Currently packaging is fixed to creating a variety of compressed archives.
#
# Note that this must be done after adding plugins, because the information about
# plugin libraries must be known at this point.
function( cpfAddInstallRulesAndTargets package packageNamespace )

	cpfAddInstallRules( ${package} ${packageNamespace}) # creates the CMake INSTALL target
	cpfAddInstallPackageTarget( ${package} )			   # creates a per package install target

endfunction()


#----------------------------------------------------------------------------------------
# Adds a target that installs only the files that belong to the given package to the local
# InstallStage directory.
function( cpfAddInstallPackageTarget package )

	set( targetName install_${package} )

	# locations / files
	set( cmakeInstallScript "${CMAKE_CURRENT_BINARY_DIR}/cmake_install.cmake" )
	
	# again we need the hack with the cpfAddConfigurationDependendCommand() to allow config information in the output of our custom commands
	set(stampFiles)
	cpfGetConfigurations(configs)
	foreach(config ${configs}) #once more we have to add a target for each configuration because OUTPUT of add_custom_command does not support generator expressions.
        
        cpfToConfigSuffix(configSuffix ${config})
        get_property(installedFiles TARGET ${package} PROPERTY CPF_INSTALLED_FILES${configSuffix})
		cpfPrependMulti( outputFiles${configSuffix} "${CMAKE_INSTALL_PREFIX}/" "${installedFiles}" )

        # Setup the command that is does the actual installation (file copying)
        # We use the cmake generated script here to only install the files for the package.
        set( installCommand "cmake -DCMAKE_INSTALL_CONFIG_NAME=${config} -DCMAKE_INSTALL_PREFIX=\"${CMAKE_INSTALL_PREFIX}\" -P \"${cmakeInstallScript}\"")

        # We use a stampfile here instead of the real output files, because we do not have config specific output filenames
        # but config specific input files.
        set(stampfile "${CMAKE_CURRENT_BINARY_DIR}/${CPF_PRIVATE_DIR}/installFiles${package}${config}.stamp")
        set(stampFileCommand "cmake -E touch \"${stampfile}\"")
        cpfGetTouchFileCommands( touchCommmand "${stampfile}")

        get_property(binarySubTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS)
        cpfGetTargetLocations( targetFiles "${binarySubTargets}" ${config})

        cpfAddConfigurationDependendCommand(
			TARGET ${targetName}
            OUTPUT ${stampfile}
            DEPENDS ${cmakeInstallScript} ${targetFiles} ${binarySubTargets}
            COMMENT "Install files for package ${package} ${config}"
            CONFIG ${config}
            COMMANDS_CONFIG ${installCommand} ${touchCommmand}
            # The touched files pollute the install stage, but they are not created on Linux where we might use the content of the  InstallStage directly.
			COMMANDS_NOT_CONFIG ${touchCommmand}
        )
        list(APPEND allOutputFiles ${stampfile})

	endforeach()

	add_custom_target(
        ${targetName}
        DEPENDS ${binarySubTargets} ${allOutputFiles}
    )

	# set some properties
	set_property( TARGET ${package} PROPERTY CPF_INSTALL_PACKAGE_SUBTARGET ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")
	foreach(config ${configs})
		cpfToConfigSuffix(configSuffix ${config})
		set_property( TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES${configSuffix} ${outputFiles${configSuffix}})
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRules package namespace)

	cpfInstallPackageBinaries( ${package} )
    cpfInstallDebugFiles( ${package} )
	cpfInstallHeaders( ${package} )
	cpfGenerateAndInstallCmakeConfigFiles( ${package} ${namespace} )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallPackageBinaries )
	
	get_property(binaryTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS)
	cpfInstallTargetsForPackage( ${package} "${binaryTargets}")
    
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallTargetsForPackage package targets )

	# Do not install the targets that have been removed from the ALL_BUILD target
	cpfFilterOutTargetsWithProperty( targets "${targets}" EXCLUDE_FROM_ALL TRUE )

	cpfGetRelativeOutputDir( relRuntimeDir ${package} RUNTIME )
	cpfGetRelativeOutputDir( relLibDir ${package} LIBRARY)
	cpfGetRelativeOutputDir( relArchiveDir ${package} ARCHIVE)
	cpfGetRelativeOutputDir( relIncludeDir ${package} INCLUDE)
	cpfGetTargetsExportsName( targetsExportName ${package})
		
	file(RELATIVE_PATH rpath "${CMAKE_INSTALL_PREFIX}/${relRuntimeDir}" "${CMAKE_INSTALL_PREFIX}/${relLibDir}")
	cpfAppendPackageExeRPaths( ${package} "\$ORIGIN/${rpath}")

	install( 
		TARGETS ${targets}
		COMPONENT ${package}
		EXPORT ${targetsExportName}
		RUNTIME DESTINATION "${relRuntimeDir}"
		LIBRARY DESTINATION "${relLibDir}"
		ARCHIVE DESTINATION "${relArchiveDir}"
		INCLUDES DESTINATION "${relIncludeDir}"
	)

	# Add the installed files to the target property
	cpfGetConfigurations(configs)
	foreach( config ${configs})
		cpfSetInstalledTargetFilesPackageProperty( ${package} ${config} "${targets}" "" )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# relDir is set for special install directories of plugins
#
function( cpfSetInstalledTargetFilesPackageProperty package config targets relDirArg )

	cpfToConfigSuffix(configSuffix ${config})
	foreach( target ${targets})

		cpfGetTargetOutputType( outputType ${target})
		if("${relDirArg}" STREQUAL "")
			cpfGetRelativeOutputDir( relDir ${package} ${outputType} )
		else()
			set(relDir "${relDirArg}")
		endif()

		set(additionalLibFiles)
		get_property( isImported TARGET ${target} PROPERTY IMPORTED)
		if(isImported)
			get_property(location TARGET ${target} PROPERTY LOCATION${configSuffix} )
			get_filename_component( targetFile "${location}" NAME )
		else()
			cpfGetTargetOutputFileName( targetFile ${target} ${config})

			# add some other files that are installed
			get_property( targetType TARGET ${target} PROPERTY TYPE)
			if( "${CMAKE_SYSTEM_NAME}" STREQUAL Windows AND "${targetType}" STREQUAL SHARED_LIBRARY )
				# on windows platforms there are also .lib files created when the target is a shared library
			
				cpfGetRelativeOutputDir( relDirLibFile ${package} ARCHIVE )
				cpfGetTargetOutputFileNameForTargetType( libFilename ${target} ${config} STATIC_LIBRARY ARCHIVE)
				list(APPEND additionalLibFiles "${relDirLibFile}/${libFilename}")
				
			elseif( "${CMAKE_SYSTEM_NAME}" STREQUAL Linux )
				# on linux, there are also soname links and name links generated for shared libraries and executables
				
				get_property( soVersion TARGET ${target} PROPERTY SOVERSION )
				get_property( version TARGET ${target} PROPERTY VERSION )
				
				# the solink with the shorter version
				if("${targetType}" STREQUAL SHARED_LIBRARY)
					string(REPLACE ${version} ${soVersion} soName "${targetFile}")
					list(APPEND additionalLibFiles "${relDir}/${soName}")
					
					# the namelink without the version
					string(REPLACE .${version} "" nameLink "${targetFile}")
					list(APPEND additionalLibFiles "${relDir}/${nameLink}")
					
				elseif("${targetType}" STREQUAL EXECUTABLE)
					
					# the namelink without the version
					# note that the version is appended with a - instead of a .
					string(REPLACE -${version} "" nameLink "${targetFile}")
					list(APPEND additionalLibFiles "${relDir}/${nameLink}")
					
				endif()
				
			endif()
		endif()

		# add the target files once only
		get_property( installedFiles TARGET ${package} PROPERTY CPF_INSTALLED_FILES${configSuffix} )
		list(APPEND installedFiles "${relDir}/${targetFile}")
		list(APPEND installedFiles ${additionalLibFiles})
		list(REMOVE_DUPLICATES installedFiles)
		set_property(TARGET ${package} PROPERTY CPF_INSTALLED_FILES${configSuffix} ${installedFiles} )

	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAppendPackageExeRPaths package rpath )

	get_property(targets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS )
	cpfFilterInTargetsWithProperty(exeTargets "${targets}" TYPE EXECUTABLE)
	foreach(target ${exeTargets})
		set_property(TARGET ${target} APPEND PROPERTY INSTALL_RPATH "${rpath}")
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetsExportsName output package)
	set(${output} ${package}Targets PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetLinkedSharedLibsForPackageExecutables output package )

	get_property(targetType TARGET ${package} PROPERTY TYPE)
	get_property(testTarget TARGET ${package} PROPERTY CPF_TESTS_SUBTARGET)

	# get the shared external libraries
	if(${targetType} STREQUAL EXECUTABLE)
		cpfGetRecursiveLinkedLibraries( packageExeLibs ${package})
	endif()

	if(testTarget AND ${package}_BUILD_TESTS)
		cpfGetRecursiveLinkedLibraries( testTargetLibs ${testTarget})
	endif()

	set(allLibs ${packageExeLibs} ${testTargetLibs})
	if(allLibs)
		list(REMOVE_DUPLICATES allLibs)
	endif()
	cpfFilterInTargetsWithProperty(sharedLibraries "${allLibs}" TYPE SHARED_LIBRARY )

	set(${output} ${sharedLibraries} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallDebugFiles package )

	get_property(targets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS)

	foreach(target ${targets})
        cpfGetConfigurations( configs )
        foreach( config ${configs})
            cpfToConfigSuffix( suffix ${config})
    
            # Install compiler generated pdb files
            get_property( compilePdbName TARGET ${target} PROPERTY COMPILE_PDB_NAME${suffix} )
            get_property( compilePdbDir TARGET ${target} PROPERTY COMPILE_PDB_OUTPUT_DIRECTORY${suffix} )
            cpfGetRelativeOutputDir( relPdbCompilerDir ${package} COMPILE_PDB )
            if(compilePdbName)
                install(
                    FILES ${compilePdbDir}/${compilePdbName}.pdb
                    COMPONENT ${package}
                    DESTINATION "${relPdbCompilerDir}"
                    CONFIGURATIONS ${config}
                )
                # Add the installed files to the target property
                set_property(TARGET ${package} APPEND PROPERTY CPF_INSTALLED_FILES${suffix} "${relPdbCompilerDir}/${compilePdbName}.pdb" )
            endif()

            # Install linker generated pdb files
            get_property( linkerPdbName TARGET ${target} PROPERTY PDB_NAME${suffix} )
            get_property( linkerPdbDir TARGET ${target} PROPERTY PDB_OUTPUT_DIRECTORY${suffix} )
            cpfGetRelativeOutputDir( relPdbLinkerDir ${package} PDB)
            if(linkerPdbName)
                install(
                    FILES ${linkerPdbDir}/${linkerPdbName}.pdb
                    COMPONENT ${package}
                    DESTINATION "${relPdbLinkerDir}"
                    CONFIGURATIONS ${config}
                )
                # Add the installed files to the target property
                set_property(TARGET ${package} APPEND PROPERTY CPF_INSTALLED_FILES${suffix} "${relPdbLinkerDir}/${linkerPdbName}.pdb" )
            endif()
            
        endforeach()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallHeaders package)

	# Install rules for production headers
	cpfInstallPublicHeaders( basicHeader ${package} ${package})
	
	# Install rules for test fixture library headers
	get_property( fixtureTarget TARGET ${package} PROPERTY CPF_TEST_FIXTURE_SUBTARGET)
	if(TARGET ${fixtureTarget})
		cpfInstallPublicHeaders( fixtureHeader ${package} ${fixtureTarget})
	endif()

    # Add the installed files to the target property
    cpfGetConfigurations(configs)
    foreach( config ${configs} )
		cpfToConfigSuffix(configSuffix ${config})
		foreach(header ${basicHeader} ${fixtureHeader} )
			set_property(TARGET ${package} APPEND PROPERTY CPF_INSTALLED_FILES${configSuffix} "${header}" )
		endforeach()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallPublicHeaders installedFilesOut package target )

    # Create header pathes relative to the install include directory.
    set( sourceDir ${${package}_SOURCE_DIR})
	set( binaryDir ${${package}_BINARY_DIR})
	cpfGetRelativeOutputDir( relIncludeDir ${package} INCLUDE)

	get_property( fixtureHeaderShort TARGET ${target} PROPERTY CPF_PUBLIC_HEADER)
	set(installedFiles)
	foreach( header ${fixtureHeaderShort})
		
		cpfIsAbsolutePath( cpfIsAbsolutePath ${header})

		if(NOT cpfIsAbsolutePath)	# The file is located in the source directory
			set(absHeader "${${package}_SOURCE_DIR}/${header}" )
		else()
			set(absHeader ${header})
		endif()

		# When building, the include directories are the packages binary and source directory.
		# This means we need the path of the header relative to one of the two in order to get the
		# relative path to the distribution packages install directory right.
		file(RELATIVE_PATH relPathSource ${${package}_SOURCE_DIR} ${absHeader} )
		file(RELATIVE_PATH relPathBinary ${${package}_BINARY_DIR} ${absHeader} )
		cpfGetShorterString( relFilePath ${relPathSource} ${relPathBinary}) # assume the shorter path is the correct one

		# prepend the includ/<package> directory
		get_filename_component( relDestDir ${relFilePath} DIRECTORY)
		if(relDestDir)
			set(relDestDir ${relIncludeDir}/${relDestDir} )
		else()
			set(relDestDir ${relIncludeDir} )
		endif()
		
		install(
			FILES ${absHeader}
			COMPONENT ${package}
			DESTINATION "${relDestDir}"
		)

		# add the relative install path to the returned paths
		get_filename_component( header ${absHeader} NAME)
		list( APPEND installedFiles ${relDestDir}/${header})
	endforeach()

	set( ${installedFilesOut} ${installedFiles} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGenerateAndInstallCmakeConfigFiles package namespace)

	# Generate the cmake config files
	set(packageConfigFile ${package}Config.cmake)
	set(versionConfigFile ${package}ConfigVersion.cmake )
	set(packageConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${packageConfigFile}")	# The config file is used by find package 
	set(versionConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${versionConfigFile}")
	cpfGetRelativeOutputDir( relConfigDir ${package} CMAKE_CONFIG)
	cpfGetTargetsExportsName( targetsExportName ${package})

	configure_package_config_file(
		${CPF_PACKAGE_CONFIG_TEMPLATE}
		"${packageConfigFileFull}"
		INSTALL_DESTINATION ${relConfigDir}
	)
		
	write_basic_package_version_file( 
		"${versionConfigFileFull}" 
		COMPATIBILITY SameMajorVersion # currently we assume globally that this compatibility scheme applies
	) 

	# Install cmake exported targets config file
	# This can not be done in the configs loop, so we need a generator expression for the output directory
	install(
		EXPORT "${targetsExportName}"
		COMPONENT ${package}
		NAMESPACE "${namespace}::"
		DESTINATION "${relConfigDir}"
	)

	# Install cmake config files
	install(
		FILES "${packageConfigFileFull}" "${versionConfigFileFull}"
		COMPONENT ${package}
		DESTINATION "${relConfigDir}"
	)

	# Add the installed files to the target property
	cpfGetConfigurations(configs)
	foreach( config ${configs} )
		cpfToConfigSuffix(configSuffix ${config})
		string( TOLOWER ${config} lowerConfig)
		set_property(TARGET ${package} APPEND PROPERTY CPF_INSTALLED_FILES${configSuffix} "${relConfigDir}/${packageConfigFile}" "${relConfigDir}/${versionConfigFile}" "${relConfigDir}/${targetsExportName}.cmake" "${relConfigDir}/${targetsExportName}-${lowerConfig}.cmake")
	endforeach()

endfunction()
