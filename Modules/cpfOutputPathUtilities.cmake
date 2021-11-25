include_guard(GLOBAL)

#---------------------------------------------------------------------------------------------
function( cpfGetLibLocation location lib configSuffix )

	get_property( libFile TARGET ${lib} PROPERTY LOCATION_${suffix})

	if(NOT libFile) # if the given config is not available for the imported library, we use the RELEASE config instead.
		get_property( libFile TARGET ${lib} PROPERTY LOCATION_RELEASE)
		cpfAssertDefinedMessage( libFile "Could not get the location of the .dll/.so file of library ${lib}.")
		cpfDebugMessage("Library ${lib} has no property LOCATION_${suffix} configuration. Defaulting to the LOCATION_RELEASE version.")
	endif()

	set(${location} ${libFile} PARENT_SCOPE)

endfunction()

#--------------------------------------------------------------------------
function( cpfGetImportedLibPdbFilePath pathOut libraryTarget config)

	# We only need the file if we compile with debug options ourselves.
	cpfIsMSVCDebugConfig( isDebugConfig ${config})

	# We only need to deploy pdb files of imported targets.
	# The locally created ones are found automatically by msvc.
	get_property( libIsImported TARGET ${libraryTarget} PROPERTY IMPORTED)
	if(isDebugConfig AND libIsImported)

		# Import targets have no porperty that holds the location of the pdb file.
		# Therefore we guess that it is at the same location as the dll and has
		# the same name.
		cpfGetLibFilePath( dllPath ${libraryTarget} ${config})
		get_filename_component( dllDir ${dllPath} DIRECTORY )
		get_filename_component( dllShortNameWE ${dllPath} NAME_WE)

		set(pdbPath ${dllDir}/${dllShortNameWE}.pdb )
		
		# As we only guessed the path we have to check if it is there.
		if(NOT EXISTS ${pdbPath})
			#message(FATAL_ERROR "Could not find .pdb file of library ${libraryTarget} at guessed location \"${pdbPath}\"." )
			cpfDebugMessage("Could not find .pdb file of library ${libraryTarget} at guessed location \"${pdbPath}\".")
		else()
			set(${pathOut} "${pdbPath}" PARENT_SCOPE)
			return()
		endif()

	endif()

	set(${pathOut} "" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the short output name of the internal target
#
function( cpfGetTargetOutputFileName output target config )

	cpfGetTargetOutputType( outputType ${target})
	cpfGetTargetOutputFileNameForTargetType( shortFilename ${target} ${config} ${outputType})
	set( ${output} ${shortFilename} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetOutputFileNameForTargetType output target config outputType)

	cpfToConfigSuffix(configSuffix ${config})
	get_property( outputBaseName TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} )
	get_property( targetType TARGET ${target} PROPERTY TYPE)
	get_property( version TARGET ${target} PROPERTY VERSION)
	
	cpfGetTargetTypeFileExtension( extension ${targetType})
	cpfIsDynamicLibrary( isDynamicLib ${target})
	cpfIsExecutable( isExe ${target})

	if(${CMAKE_SYSTEM_NAME} STREQUAL Linux AND isDynamicLib )
		set( shortFilename "${outputBaseName}${extension}.${version}")
	elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux AND isExe)
		set( shortFilename "${outputBaseName}-${version}${extension}")
	else()
		set( shortFilename "${outputBaseName}${extension}")
	endif()

	set( ${output} ${shortFilename} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetOutputBaseName nameOut target config)
	cpfToConfigSuffix( configSuffix ${config})
	cpfGetTargetOutputType( outputType ${target})
	get_property( baseName TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} )
	set( ${nameOut} ${baseName} PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetAbsOutputDir absDirOut packageComponent outputType config )
	cpfGetRelativeOutputDir(relativeDir ${packageComponent} ${outputType})
	set(${absDirOut} "${CMAKE_BINARY_DIR}/BuildStage/${config}/${relativeDir}" PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# Note that this function defines a part of the directory structure of the deployed files
#
function( cpfGetRelativeOutputDir relativeDirOut packageComponent outputType )

	cpfGetTypePartOfOutputDir(typeDir ${packageComponent} ${outputType})
	set(${relativeDirOut} ${typeDir} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# returns the output directory of the target
function( cpfGetTargetOutputDirectory output target config )

	cpfToConfigSuffix(configSuffix ${config})
	cpfGetTargetOutputType( outputType ${target})
	get_property( outputDir TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY_${configSuffix} )
	set( ${output} "${outputDir}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# This function defines the part of the output directory that comes after the config/package add_subdirectory
#
function( cpfGetTypePartOfOutputDir typeDir packageComponent outputType )

	# handle relative dirs that are the same on all platforms
	if(${outputType} STREQUAL ARCHIVE)
		set(typeDirLocal lib)
	elseif(${outputType} STREQUAL COMPILE_PDB )	
		# We put the compiler pdb files parallel to the lib, because msvc looks for them there.
		set(typeDirLocal lib )
	elseif(${outputType} STREQUAL PDB)
		# We put the linker pdb files parallel to the dll, because msvc looks for them there.
		set(typeDirLocal . )
	elseif(${outputType} STREQUAL INCLUDE)
		set(typeDirLocal include/${packageComponent})
	elseif(${outputType} STREQUAL CMAKE_PACKAGE_FILES)
		set(typeDirLocal lib/cmake/${packageComponent}) 
	elseif(${outputType} STREQUAL SOURCE )
		set(typeDirLocal src/${packageComponent}) 
	elseif(${outputType} STREQUAL DISTRIBUTION_PACKAGE_FILES)
		set(typeDirLocal DistributionPackages)
	elseif(${outputType} STREQUAL OTHER )
		set(typeDirLocal other ) 
	endif()

	# handle platform specific relative dirs
	if( ${CMAKE_SYSTEM_NAME} STREQUAL Windows  )
		# on windows we put executables and dlls directly in the package-component directory.
		if(${outputType} STREQUAL RUNTIME)
			set(typeDirLocal . )
		elseif(${outputType} STREQUAL LIBRARY)
			set(typeDirLocal . )
		endif()

	elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
		# On Linux we follow the GNU coding standards that propose a directory structure
		# https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
		if(${outputType} STREQUAL RUNTIME)
			set(typeDirLocal bin)
		elseif(${outputType} STREQUAL LIBRARY)
			set(typeDirLocal lib)
		endif()

	else()
		message(FATAL_ERROR "Function cpfSetAllOutputDirectoriesAndNames() must be extended for system ${CMAKE_SYSTEM_NAME}")
	endif()
	
	set( ${typeDir} ${typeDirLocal} PARENT_SCOPE ) 

endfunction()

#---------------------------------------------------------------------------------------------
# Sets the <binary-type>_OUTOUT_DIRECTORY_<config> properties of the given target.
#
function( cpfSetTargetOutputDirectoriesAndNames packageComponent target )

	cpfGetConfigurations( configs)
	foreach(config ${configs})
		cpfSetAllOutputDirectoriesAndNames(${target} ${packageComponent} ${config} )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfSetAllOutputDirectoriesAndNames target packageComponent config )

	# The output directory properties can not be set on interface libraries.
	cpfIsInterfaceLibrary(isIntLib ${target})
	if(isIntLib)
		return()
	endif()

	cpfToConfigSuffix( configSuffix ${config})

	# Delete the <config>_postfix property and handle things manually in cpfSetOutputDirAndName()
	string(TOUPPER ${config} uConfig)
	set_property( TARGET ${target} PROPERTY ${uConfig}_POSTFIX "" )

	cpfSetOutputDirAndName( ${target} ${packageComponent} ${config} RUNTIME)
	cpfSetOutputDirAndName( ${target} ${packageComponent} ${config} LIBRARY)
	cpfSetOutputDirAndName( ${target} ${packageComponent} ${config} ARCHIVE)

	cpfCompilerProducesPdbFiles(hasOutput ${config})
	if(hasOutput)
		cpfSetOutputDirAndName( ${target} ${packageComponent} ${config} COMPILE_PDB)
		set_property(TARGET ${target} PROPERTY COMPILE_PDB_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX}-compiler) # we overwrite the filename to make it more meaningful
	endif()

	cpfTargetHasPdbLinkerOutput(hasOutput ${target} ${configSuffix})
	if(hasOutput)
		# Note that we use the same name and path for linker as are used for the dlls files.
		# When consuming imported targets we guess that the pdb files have these locations. 
		cpfSetOutputDirAndName( ${target} ${packageComponent} ${config} PDB)
		set_property(TARGET ${target} PROPERTY PDB_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX})
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# This function sets the output name property to make sure that the same target file names are
# achieved across all platforms.
function( cpfSetOutputDirAndName target packageComponent config outputType )

	cpfGetAbsOutputDir(outputDir ${packageComponent} ${outputType} ${config})
	cpfToConfigSuffix(configSuffix ${config})
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY_${configSuffix} ${outputDir})
	# use the config postfix for all target types
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX} )

endfunction()

#----------------------------------------------------------------------------------------
# Returns the absolute path to the output directory and the short filename of the output file of an imported or internal target
#
function( cpfGetTargetLocation targetDirOut targetFilenameOut target config )

	get_property(isImported TARGET ${target} PROPERTY IMPORTED)
	if(isImported)
		cpfToConfigSuffix( configSuffix ${config})
		# for imported targets it is not clear which property holds the 
		set( possibleLocationProperties IMPORTED_LOCATION_${configSuffix} LOCATION_${configSuffix} IMPORTED_LOCATION LOCATION )
		cpfGetFirstDefinedTargetProperty( fullTargetFile ${target} "${possibleLocationProperties}")
  
        if("${fullTargetFile}" STREQUAL "") # give up
            cpfPrintTargetProperties(${target}) # print more debug information about which variable may hold the location
            message(FATAL_ERROR "Function cpfGetTargetLocation() could not determine the location of the binary file for target ${target} and configuration ${config}")
        endif()

	else()
		cpfGetAbsPathOfTargetOutputFile( fullTargetFile ${target} ${config})
	endif()

	get_filename_component( shortName "${fullTargetFile}" NAME)
	get_filename_component( targetDir "${fullTargetFile}" DIRECTORY )

	set(${targetDirOut} ${targetDir} PARENT_SCOPE)
	set(${targetFilenameOut} ${shortName} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the absolute pathes of the output files of multiple targets.
#
function( cpfGetTargetLocations absolutePathes targets config )
	set(locations)
	foreach(target ${targets})
		cpfGetTargetLocation( dir shortName ${target} ${config} )
		cpfListAppend( locations "${dir}/${shortName}")
	endforeach()
	set(${absolutePathes} "${locations}" PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# returns the absolute path to the created binary output file of the the given target
function( cpfGetAbsPathOfTargetOutputFile output target config )

	cpfGetTargetOutputDirectory( directory ${target} ${config} )
	cpfGetTargetOutputFileName( name ${target} ${config})
	set( ${output} "${directory}/${name}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetSharedLibraryOutputDir outputDir target config )

    if(${CMAKE_SYSTEM_NAME} STREQUAL Windows )
		cpfGetAbsOutputDir(sourceDir ${target} RUNTIME ${config})
    elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
		cpfGetAbsOutputDir(sourceDir ${target} LIBRARY ${config})
    else()
        message(FATAL_ERROR "Function cpfGetSharedLibraryOutputDir() must be extended for system ${CMAKE_SYSTEM_NAME}")
    endif()
    
    set(${outputDir} ${sourceDir} PARENT_SCOPE)
    
endfunction()

#--------------------------------------------------------------------------
function( cpfGetLibFilePath pathOut libraryTarget config)

	get_property(isImported TARGET ${libraryTarget} PROPERTY IMPORTED)
	if(isImported)

		cpfToConfigSuffix(suffix ${config} )
		cpfGetLibLocation(libPath ${libraryTarget} ${suffix})
		set(${pathOut} ${libPath} PARENT_SCOPE)

	else()

		cpfGetTargetOutputFileName(libraryFileName ${libraryTarget} ${config})
		cpfGetTargetOutputDirectory(sourceDir ${libraryTarget} ${config} )
		set(${pathOut} "${sourceDir}/${libraryFileName}" PARENT_SCOPE)

	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# translates the target type into the output type (ARCHIVE, RUNTIME etc.)
function( cpfGetTargetOutputType outputTypeOut target )

	get_property( type TARGET ${target} PROPERTY TYPE)
	if( ${type} STREQUAL EXECUTABLE )
		set( ${outputTypeOut} RUNTIME PARENT_SCOPE)
	elseif(${type} STREQUAL STATIC_LIBRARY)
		set( ${outputTypeOut} ARCHIVE PARENT_SCOPE)
	elseif(${type} STREQUAL MODULE_LIBRARY)
		set( ${outputTypeOut} LIBRARY PARENT_SCOPE)
	elseif(${type} STREQUAL SHARED_LIBRARY)
		if(${CMAKE_SYSTEM_NAME} STREQUAL Windows ) # this should also be set when using cygwin or maybe clang-cl, but we ignore that for now
			set( ${outputTypeOut} RUNTIME PARENT_SCOPE)
		else()
			set( ${outputTypeOut} LIBRARY PARENT_SCOPE)
		endif()
	elseif(${type} STREQUAL INTERFACE_LIBRARY)
		set( ${outputTypeOut} ARCHIVE PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Target type ${type} not supported by function cpfGetTargetOutputType()")
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# returns the file extension for the type of the given target
function( cpfGetTargetTypeFileExtension extension targetType)
	
	if( ${targetType} STREQUAL EXECUTABLE )
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL STATIC_LIBRARY)
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL MODULE_LIBRARY)
		set( ${extension} ${CMAKE_SHARED_MODULE_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL SHARED_LIBRARY)
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Target type ${targetType} not supported by function cpfGetTargetTypeFileExtension()")
	endif()

endfunction()



