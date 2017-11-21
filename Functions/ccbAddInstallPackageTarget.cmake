
include(ccbCustomTargetUtilities)
include(ccbLocations)
include(ccbBaseUtilities)
include(ccbProjectUtilities)

set(DIR_OF_THIS_FILE ${CMAKE_CURRENT_LIST_DIR})

#----------------------------------------------------------------------------------------
# This function adds per package install targets and packaging targets.
# Currently packaging is fixed to creating a variety of compressed archives.
#
# Note that this must be done after adding plugins, because the information about
# plugin libraries must be known at this point.
function( ccbAddInstallRulesAndTargets package packageNamespace )

	ccbAddInstallRules( ${package} ${packageNamespace}) # creates the CMake INSTALL target
	ccbAddInstallPackageTarget( ${package} )			   # creates a per package install target

endfunction()


#----------------------------------------------------------------------------------------
# Adds a target that installs only the files that belong to the given package to the local
# InstallStage directory.
function( ccbAddInstallPackageTarget package )

	set( targetName install_${package} )

	# locations / files
	set( cmakeInstallScript "${CMAKE_CURRENT_BINARY_DIR}/cmake_install.cmake" )
	
	# again we need the hack with the ccbAddConfigurationDependendCommand() to allow config information in the output of our custom commands
	set(stampFiles)
	ccbGetConfigurations(configs)
	foreach(config ${configs}) #once more we have to add a target for each configuration because OUTPUT of add_custom_command does not support generator expressions.
        
        ccbToConfigSuffix(configSuffix ${config})
        get_property(installedFiles TARGET ${package} PROPERTY CCB_INSTALLED_FILES${configSuffix})
		ccbPrependMulti( outputFiles${configSuffix} "${CMAKE_INSTALL_PREFIX}/" "${installedFiles}" )

        # Setup the command that is does the actual installation (file copying)
        # We use the cmake generated script here to only install the files for the package.
        set( installCommand "cmake -DCMAKE_INSTALL_CONFIG_NAME=${config} -DCMAKE_INSTALL_PREFIX=\"${CMAKE_INSTALL_PREFIX}\" -P \"${cmakeInstallScript}\"")

        # We use a stampfile here instead of the real output files, because we do not have config specific output filenames
        # but config specific input files.
        set(stampfile "${CMAKE_CURRENT_BINARY_DIR}/${CCB_PRIVATE_DIR}/installFiles${package}${config}.stamp")
        set(stampFileCommand "cmake -E touch \"${stampfile}\"")
        ccbGetTouchFileCommands( touchCommmand "${stampfile}")

        get_property(binarySubTargets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS)
        ccbGetTargetLocations( targetFiles "${binarySubTargets}" ${config})

        ccbAddConfigurationDependendCommand(
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
	set_property( TARGET ${package} PROPERTY CCB_INSTALL_PACKAGE_SUBTARGET ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")
	foreach(config ${configs})
		ccbToConfigSuffix(configSuffix ${config})
		set_property( TARGET ${targetName} PROPERTY CCB_OUTPUT_FILES${configSuffix} ${outputFiles${configSuffix}})
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbAddInstallRules package namespace)

	ccbInstallPackageBinaries( ${package} )
    ccbInstallDebugFiles( ${package} )
	ccbInstallHeaders( ${package} )
	ccbGenerateAndInstallCmakeConfigFiles( ${package} ${namespace} )

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbInstallPackageBinaries )
	
	get_property(binaryTargets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS)
	ccbInstallTargetsForPackage( ${package} "${binaryTargets}")
    
endfunction()

#---------------------------------------------------------------------------------------------
function( ccbInstallTargetsForPackage package targets )

	# Do not install the targets that have been removed from the ALL_BUILD target
	ccbFilterOutTargetsWithProperty( targets "${targets}" EXCLUDE_FROM_ALL TRUE )

	ccbGetRelativeOutputDir( relRuntimeDir ${package} RUNTIME )
	ccbGetRelativeOutputDir( relLibDir ${package} LIBRARY)
	ccbGetRelativeOutputDir( relArchiveDir ${package} ARCHIVE)
	ccbGetRelativeOutputDir( relIncludeDir ${package} INCLUDE)
	ccbGetTargetsExportsName( targetsExportName ${package})
		
	file(RELATIVE_PATH rpath "${CMAKE_INSTALL_PREFIX}/${relRuntimeDir}" "${CMAKE_INSTALL_PREFIX}/${relLibDir}")
	ccbAppendPackageExeRPaths( ${package} "\$ORIGIN/${rpath}")

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
	ccbGetConfigurations(configs)
	foreach( config ${configs})
		ccbSetInstalledTargetFilesPackageProperty( ${package} ${config} "${targets}" "" )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# relDir is set for special install directories of plugins
#
function( ccbSetInstalledTargetFilesPackageProperty package config targets relDirArg )

	ccbToConfigSuffix(configSuffix ${config})
	foreach( target ${targets})

		ccbGetTargetOutputType( outputType ${target})
		if("${relDirArg}" STREQUAL "")
			ccbGetRelativeOutputDir( relDir ${package} ${outputType} )
		else()
			set(relDir "${relDirArg}")
		endif()

		set(additionalLibFiles)
		get_property( isImported TARGET ${target} PROPERTY IMPORTED)
		if(isImported)
			get_property(location TARGET ${target} PROPERTY LOCATION${configSuffix} )
			get_filename_component( targetFile "${location}" NAME )
		else()
			ccbGetTargetOutputFileName( targetFile ${target} ${config})

			# add some other files that are installed
			get_property( targetType TARGET ${target} PROPERTY TYPE)
			if( "${CMAKE_SYSTEM_NAME}" STREQUAL Windows AND "${targetType}" STREQUAL SHARED_LIBRARY )
				# on windows platforms there are also .lib files created when the target is a shared library
			
				ccbGetRelativeOutputDir( relDirLibFile ${package} ARCHIVE )
				ccbGetTargetOutputFileNameForTargetType( libFilename ${target} ${config} STATIC_LIBRARY ARCHIVE)
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
		get_property( installedFiles TARGET ${package} PROPERTY CCB_INSTALLED_FILES${configSuffix} )
		list(APPEND installedFiles "${relDir}/${targetFile}")
		list(APPEND installedFiles ${additionalLibFiles})
		list(REMOVE_DUPLICATES installedFiles)
		set_property(TARGET ${package} PROPERTY CCB_INSTALLED_FILES${configSuffix} ${installedFiles} )

	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbAppendPackageExeRPaths package rpath )

	get_property(targets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS )
	ccbFilterInTargetsWithProperty(exeTargets "${targets}" TYPE EXECUTABLE)
	foreach(target ${exeTargets})
		set_property(TARGET ${target} APPEND PROPERTY INSTALL_RPATH "${rpath}")
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbGetTargetsExportsName output package)
	set(${output} ${package}Targets PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
function( ccbGetLinkedSharedLibsForPackageExecutables output package )

	get_property(targetType TARGET ${package} PROPERTY TYPE)
	get_property(testTarget TARGET ${package} PROPERTY CCB_TESTS_SUBTARGET)

	# get the shared external libraries
	if(${targetType} STREQUAL EXECUTABLE)
		ccbGetRecursiveLinkedLibraries( packageExeLibs ${package})
	endif()

	if(testTarget AND ${package}_BUILD_TESTS)
		ccbGetRecursiveLinkedLibraries( testTargetLibs ${testTarget})
	endif()

	set(allLibs ${packageExeLibs} ${testTargetLibs})
	if(allLibs)
		list(REMOVE_DUPLICATES allLibs)
	endif()
	ccbFilterInTargetsWithProperty(sharedLibraries "${allLibs}" TYPE SHARED_LIBRARY )

	set(${output} ${sharedLibraries} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbInstallDebugFiles package )

	get_property(targets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS)

	foreach(target ${targets})
        ccbGetConfigurations( configs )
        foreach( config ${configs})
            ccbToConfigSuffix( suffix ${config})
    
            # Install compiler generated pdb files
            get_property( compilePdbName TARGET ${target} PROPERTY COMPILE_PDB_NAME${suffix} )
            get_property( compilePdbDir TARGET ${target} PROPERTY COMPILE_PDB_OUTPUT_DIRECTORY${suffix} )
            ccbGetRelativeOutputDir( relPdbCompilerDir ${package} COMPILE_PDB )
            if(compilePdbName)
                install(
                    FILES ${compilePdbDir}/${compilePdbName}.pdb
                    COMPONENT ${package}
                    DESTINATION "${relPdbCompilerDir}"
                    CONFIGURATIONS ${config}
                )
                # Add the installed files to the target property
                set_property(TARGET ${package} APPEND PROPERTY CCB_INSTALLED_FILES${suffix} "${relPdbCompilerDir}/${compilePdbName}.pdb" )
            endif()

            # Install linker generated pdb files
            get_property( linkerPdbName TARGET ${target} PROPERTY PDB_NAME${suffix} )
            get_property( linkerPdbDir TARGET ${target} PROPERTY PDB_OUTPUT_DIRECTORY${suffix} )
            ccbGetRelativeOutputDir( relPdbLinkerDir ${package} PDB)
            if(linkerPdbName)
                install(
                    FILES ${linkerPdbDir}/${linkerPdbName}.pdb
                    COMPONENT ${package}
                    DESTINATION "${relPdbLinkerDir}"
                    CONFIGURATIONS ${config}
                )
                # Add the installed files to the target property
                set_property(TARGET ${package} APPEND PROPERTY CCB_INSTALLED_FILES${suffix} "${relPdbLinkerDir}/${linkerPdbName}.pdb" )
            endif()
            
        endforeach()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbInstallHeaders package)

	# Install rules for production headers
	ccbInstallPublicHeaders( basicHeader ${package} ${package})
	
	# Install rules for test fixture library headers
	get_property( fixtureTarget TARGET ${package} PROPERTY CCB_TEST_FIXTURE_SUBTARGET)
	if(TARGET ${fixtureTarget})
		ccbInstallPublicHeaders( fixtureHeader ${package} ${fixtureTarget})
	endif()

    # Add the installed files to the target property
    ccbGetConfigurations(configs)
    foreach( config ${configs} )
		ccbToConfigSuffix(configSuffix ${config})
		foreach(header ${basicHeader} ${fixtureHeader} )
			set_property(TARGET ${package} APPEND PROPERTY CCB_INSTALLED_FILES${configSuffix} "${header}" )
		endforeach()
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbInstallPublicHeaders installedFilesOut package target )

    # Create header pathes relative to the install include directory.
    set( sourceDir ${${package}_SOURCE_DIR})
	set( binaryDir ${${package}_BINARY_DIR})
	ccbGetRelativeOutputDir( relIncludeDir ${package} INCLUDE)

	get_property( fixtureHeaderShort TARGET ${target} PROPERTY CCB_PUBLIC_HEADER)
	set(installedFiles)
	foreach( header ${fixtureHeaderShort})
		
		ccbIsAbsolutePath( ccbIsAbsolutePath ${header})

		if(NOT ccbIsAbsolutePath)	# The file is located in the source directory
			set(absHeader "${${package}_SOURCE_DIR}/${header}" )
		else()
			set(absHeader ${header})
		endif()

		# When building, the include directories are the packages binary and source directory.
		# This means we need the path of the header relative to one of the two in order to get the
		# relative path to the distribution packages install directory right.
		file(RELATIVE_PATH relPathSource ${${package}_SOURCE_DIR} ${absHeader} )
		file(RELATIVE_PATH relPathBinary ${${package}_BINARY_DIR} ${absHeader} )
		ccbGetShorterString( relFilePath ${relPathSource} ${relPathBinary}) # assume the shorter path is the correct one

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
function( ccbGenerateAndInstallCmakeConfigFiles package namespace)

	# Generate the cmake config files
	set(packageConfigFile ${package}Config.cmake)
	set(versionConfigFile ${package}ConfigVersion.cmake )
	set(packageConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${packageConfigFile}")	# The config file is used by find package 
	set(versionConfigFileFull "${CMAKE_CURRENT_BINARY_DIR}/${versionConfigFile}")
	ccbGetRelativeOutputDir( relConfigDir ${package} CMAKE_CONFIG)
	ccbGetTargetsExportsName( targetsExportName ${package})

	configure_package_config_file(
		${CCB_PACKAGE_CONFIG_TEMPLATE}
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
	ccbGetConfigurations(configs)
	foreach( config ${configs} )
		ccbToConfigSuffix(configSuffix ${config})
		string( TOLOWER ${config} lowerConfig)
		set_property(TARGET ${package} APPEND PROPERTY CCB_INSTALLED_FILES${configSuffix} "${relConfigDir}/${packageConfigFile}" "${relConfigDir}/${versionConfigFile}" "${relConfigDir}/${targetsExportName}.cmake" "${relConfigDir}/${targetsExportName}-${lowerConfig}.cmake")
	endforeach()

endfunction()
