include_guard(GLOBAL)

include(CMakePackageConfigHelpers)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfProjectUtilities)



#---------------------------------------------------------------------------------------------
# Adds install rules for the various package components.
#
function( cpfAddInstallRules package namespace pluginOptionLists)

	cpfInstallPackageBinaries( ${package} )
	cpfGenerateAndInstallCmakeConfigFiles( ${package} ${namespace} )
	cpfInstallHeaders( ${package} )
	cpfInstallDebugFiles( ${package} )
	cpfInstallAbiDumpFiles( ${package} )

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
		EXPORT ${targetsExportName}
		RUNTIME DESTINATION "${relRuntimeDir}" COMPONENT runtime
		LIBRARY DESTINATION "${relLibDir}"     COMPONENT developer
		ARCHIVE DESTINATION "${relArchiveDir}" COMPONENT developer
		# This sets the import targets include directories to <package>/include, 
		# so clients can also include with <package/bla.h>
		INCLUDES DESTINATION "${relIncludeDir}/.."
		
	)

	# Add the installed files to the target property
	cpfGetConfigurations(configs)
	foreach( config ${configs})
		cpfAddBinaryFilesToInstalledFilesProperty( ${package} ${config} "${targets}" "" )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# relDir is set for special install directories of plugins
#
function( cpfAddBinaryFilesToInstalledFilesProperty package config targets relDirArg )

	cpfToConfigSuffix(configSuffix ${config})

	set(installedPackageFiles)
	foreach( target ${targets})

		cpfGetTargetOutputType( outputType ${target})
		if("${relDirArg}" STREQUAL "")
			cpfGetRelativeOutputDir( relDir ${package} ${outputType} )
		else()
			set(relDir "${relDirArg}")
		endif()

		set(additionalTargetFiles)
		get_property( isImported TARGET ${target} PROPERTY IMPORTED)
		if(isImported)
			get_property(location TARGET ${target} PROPERTY LOCATION_${configSuffix} )
			get_filename_component( targetFile "${location}" NAME )
		else()
			cpfGetTargetOutputFileName( targetFile ${target} ${config})

			# add some other files that are installed
			get_property( targetType TARGET ${target} PROPERTY TYPE)
			if( "${CMAKE_SYSTEM_NAME}" STREQUAL Windows AND "${targetType}" STREQUAL SHARED_LIBRARY )

				# on windows platforms there are also .lib files created when the target is a shared library
				cpfGetRelativeOutputDir( relDirLibFile ${package} ARCHIVE )
				cpfGetTargetOutputFileNameForTargetType( libFilename ${target} ${config} STATIC_LIBRARY ARCHIVE)
				cpfListAppend( additionalTargetFiles "${relDirLibFile}/${libFilename}")
				
			elseif( "${CMAKE_SYSTEM_NAME}" STREQUAL Linux )

				# on linux, there are also soname links and name links generated for shared libraries and executables
				get_property( soVersion TARGET ${target} PROPERTY SOVERSION )
				get_property( version TARGET ${target} PROPERTY VERSION )

				if("${targetType}" STREQUAL SHARED_LIBRARY)

					# the solink with the shorter version
					string(REPLACE ${version} ${soVersion} soName "${targetFile}")
					cpfListAppend( additionalTargetFiles "${relDir}/${soName}")
					
					# the namelink without the version
					string(REPLACE .${version} "" nameLink "${targetFile}")
					cpfListAppend( additionalTargetFiles "${relDir}/${nameLink}")
					
				elseif("${targetType}" STREQUAL EXECUTABLE)
					
					# the namelink without the version
					# note that the version is appended with a - instead of a .
					string(REPLACE -${version} "" nameLink "${targetFile}")
					cpfListAppend( additionalTargetFiles "${relDir}/${nameLink}")
					
				endif()
				
			endif()
		endif()

		# Add the main binary file itself.
		cpfListAppend( installedPackageFiles "${relDir}/${targetFile}")
		# Add the addtional files that belong to the main binary file.
		cpfListAppend( installedPackageFiles "${additionalTargetFiles}")

	endforeach()

	cpfAddInstalledFilesToProperty( ${package} ${config} "${installedPackageFiles}" )

endfunction()

#---------------------------------------------------------------------------------------------
# This function makes sure, that installed files are unique in the list.
#
function( cpfAddInstalledFilesToProperty package config files )

	cpfToConfigSuffix(configSuffix ${config})
	get_property( installedFilesFromProperty TARGET ${package} PROPERTY CPF_INSTALLED_FILES_${configSuffix} )
	set( allInstalledPackageFiles ${installedFilesFromProperty} ${files})
	list(REMOVE_DUPLICATES allInstalledPackageFiles)
	set_property(TARGET ${package} PROPERTY CPF_INSTALLED_FILES_${configSuffix} ${allInstalledPackageFiles} )

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
# This function adds install rules for the files that are required for debugging.
# This is currently the pdb and source files for msvc configurations.
#
function( cpfInstallDebugFiles package )

	get_property(targets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS)

	cpfGetConfigurations( configs )
	foreach( config ${configs})

		cpfToConfigSuffix( suffix ${config})

		set(installedPackageFiles)
		foreach(target ${targets})
    
            # Install compiler generated pdb files
            get_property( compilePdbName TARGET ${target} PROPERTY COMPILE_PDB_NAME_${suffix} )
            get_property( compilePdbDir TARGET ${target} PROPERTY COMPILE_PDB_OUTPUT_DIRECTORY_${suffix} )
            cpfGetRelativeOutputDir( relPdbCompilerDir ${package} COMPILE_PDB )
            if(compilePdbName)
                install(
                    FILES ${compilePdbDir}/${compilePdbName}.pdb
					DESTINATION "${relPdbCompilerDir}"
					COMPONENT developer
                    CONFIGURATIONS ${config}
                )
				cpfListAppend(installedPackageFiles "${relPdbCompilerDir}/${compilePdbName}.pdb")
            endif()

            # Install linker generated pdb files
            get_property( linkerPdbName TARGET ${target} PROPERTY PDB_NAME_${suffix} )
            get_property( linkerPdbDir TARGET ${target} PROPERTY PDB_OUTPUT_DIRECTORY_${suffix} )
            cpfGetRelativeOutputDir( relPdbLinkerDir ${package} PDB)
            if(linkerPdbName)
                install(
                    FILES ${linkerPdbDir}/${linkerPdbName}.pdb
					DESTINATION "${relPdbLinkerDir}"
					COMPONENT developer
                    CONFIGURATIONS ${config}
                )
				cpfListAppend(installedPackageFiles "${relPdbLinkerDir}/${linkerPdbName}.pdb")
			endif()
			
			# Install source files for configurations that require them for debugging.
			cpfProjectProducesPdbFiles( needsSourcesForDebugging ${config})
			if(needsSourcesForDebugging)

				getAbsPathsOfTargetSources( absSourcePaths ${target})
				cpfGetFilepathsWithExtensions( absSourcePaths "${absSourcePaths}" "${CPF_CXX_SOURCE_FILE_EXTENSIONS}" )
				cpfGetShortFilenames( shortSourceNames "${absSourcePaths}")
				get_property(sourceDir TARGET ${target} PROPERTY SOURCE_DIR )

				cpfGetRelativeOutputDir( relSourceDir ${package} SOURCE)
				install(
                    FILES ${absSourcePaths}
					DESTINATION "${relSourceDir}"
					COMPONENT developer
                    CONFIGURATIONS ${config}
                )

                # Add the installed files to the target property
				cpfPrependMulti(relInstallPaths "${relSourceDir}/" "${shortSourceNames}" )
				cpfListAppend(installedPackageFiles ${relInstallPaths})

			endif()

		endforeach()
		
		cpfAddInstalledFilesToProperty( ${package} ${config} "${installedPackageFiles}" )

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

		set(installedPackageFiles)
		foreach(header ${basicHeader} ${fixtureHeader} )
			cpfListAppend(installedPackageFiles "${header}")
		endforeach()

		cpfAddInstalledFilesToProperty( ${package} ${config} "${installedPackageFiles}" )

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

		# prepend the include/<package> directory
		get_filename_component( relDestDir ${relFilePath} DIRECTORY)
		if(relDestDir)
			set(relDestDir ${relIncludeDir}/${relDestDir} )
		else()
			set(relDestDir ${relIncludeDir} )
		endif()
		
		install(
			FILES ${absHeader}
			DESTINATION "${relDestDir}"
			COMPONENT developer
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
	cpfGetRelativeOutputDir( relCmakeFilesDir ${package} CMAKE_PACKAGE_FILES)
	cpfGetTargetsExportsName( targetsExportName ${package})

	configure_package_config_file(
		${CPF_PACKAGE_CONFIG_TEMPLATE}
		"${packageConfigFileFull}"
		INSTALL_DESTINATION ${relCmakeFilesDir}
	)
		
	write_basic_package_version_file( 
		"${versionConfigFileFull}" 
		COMPATIBILITY SameMajorVersion # currently we assume globally that this compatibility scheme applies
	) 

	# Install cmake exported targets config file
	# This can not be done in the configs loop, so we need a generator expression for the output directory
	install(
		EXPORT "${targetsExportName}"
		NAMESPACE "${namespace}::"
		DESTINATION "${relCmakeFilesDir}"
		COMPONENT developer
	)

	# Install cmake config files
	install(
		FILES "${packageConfigFileFull}" "${versionConfigFileFull}"
		DESTINATION "${relCmakeFilesDir}"
		COMPONENT developer
	)

	# Add the installed files to the target property
	cpfGetConfigurations(configs)
	foreach( config ${configs} )

		string( TOLOWER ${config} lowerConfig)
		set( installedPackageFiles 
			"${relCmakeFilesDir}/${packageConfigFile}"
			"${relCmakeFilesDir}/${versionConfigFile}"
			"${relCmakeFilesDir}/${targetsExportName}.cmake"
			"${relCmakeFilesDir}/${targetsExportName}-${lowerConfig}.cmake"
		)
		cpfAddInstalledFilesToProperty( ${package} ${config} "${installedPackageFiles}" )

	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfInstallAbiDumpFiles package )

	set(installedPackageFiles)

	# get files from abiDump targets
	get_property( binaryTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS )
	foreach(binaryTarget ${binaryTargets})
		get_property( abiDumpTarget TARGET ${binaryTarget} PROPERTY CPF_ABI_DUMP_SUBTARGET )
		if(abiDumpTarget)

			cpfGetCurrentDumpFile( dumpFile ${package} ${binaryTarget})
			get_filename_component( shortDumpFile "${dumpFile}" NAME )
			cpfGetRelativeOutputDir( relDumpFileDir ${package} OTHER)

			install(
				FILES ${dumpFile}
				DESTINATION "${relDumpFileDir}"
				COMPONENT developer
			)

			cpfListAppend( installedPackageFiles "${relDumpFileDir}/${shortDumpFile}" )

		endif()
	endforeach()

	cpfGetConfigurations(configs)
	foreach( config ${configs} )
		cpfAddInstalledFilesToProperty( ${package} ${config} "${installedPackageFiles}" )
	endforeach()

endfunction()


#----------------------------------------------------------------------------------------
# Parses the pluginOptionLists and returns two lists of same size. One list contains the
# plugin target while the element with the same index in the other list contains the 
# directory of the plugin target.
function( cpfGetPluginTargetDirectoryPairLists targetsOut directoriesOut pluginOptionLists )
	# parse the plugin dependencies arguments
	# Creates two lists of the same length, where one list contains the plugin targets
	# and the other the directory to which they are deployed.
	set(pluginTargets)
	set(pluginDirectories)
	foreach( list ${pluginOptionLists})
		cmake_parse_arguments(
			ARG 
			"" 
			"PLUGIN_DIRECTORY"
			"PLUGIN_TARGETS"
			${${list}}
		)
		foreach( pluginTarget ${ARG_PLUGIN_TARGETS})
			cpfListAppend( pluginTargets ${pluginTarget})
			cpfListAppend( pluginDirectories ${ARG_PLUGIN_DIRECTORY})
		endforeach()
	endforeach()
	
	set(${targetsOut} ${pluginTargets} PARENT_SCOPE)
	set(${directoriesOut} ${pluginDirectories} PARENT_SCOPE)
	
endfunction()
