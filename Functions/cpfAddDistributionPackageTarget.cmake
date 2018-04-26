include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfAddCompatibilityCheckTarget)
#include(CPack) # adding this creates the global package target



#----------------------------------------------------------------------------------------
# Adds a global target that makes sure that all the per package createArchivePackage targets are build.
#
function( cpfAddGlobalCreatePackagesTarget packages)

    set(targetName distributionPackages)
	
	set(packageTargets)
	foreach(package ${packages})
		cpfGetDistributionPackagesTargetName( packageTarget ${package})
		if(TARGET ${packageTarget}) # not all packages may create distribution packages
			list(APPEND packageTargets ${packageTarget})
		endif()
	endforeach()
	
	cpfAddBundleTarget( ${targetName} "${packageTargets}" )

endfunction()

#----------------------------------------------------------------------------------------
#
# For argument documentation see the cpfAddPackage() function.
function( cpfAddDistributionPackageTargets package packageOptionLists pluginOptionLists )

	# todo create pair list for plugin options
	cpfGetPluginTargetDirectoryPairLists( pluginTargets pluginDirectories "${pluginOptionLists}" )
	
	foreach( list ${packageOptionLists})

		cpfParseDistributionPackageOptions( contentType packageFormats distributionPackageFormatOptions excludedTargets "${${list}}")

		# First we create targets that assemble the content of the desired contentType
		cpfGetCollectPackageContentTargetNameAnId( packageContentTarget contentId ${package} ${contentType} "${excludedTargets}")
		if(NOT TARGET ${packageContentTarget})
			cpfAddPackageContentTarget( packageAssembleOutputFiles ${packageContentTarget} ${package} ${contentId} ${contentType} "${excludedTargets}" "${pluginTargets}" "${pluginDirectories}")
		endif()

		foreach(packageFormat ${packageFormats})
			cpfAddDistributionPackageTarget( ${package} ${packageContentTarget} ${contentId} ${contentType} ${packageFormat} "${distributionPackageFormatOptions}")
		endforeach()
	endforeach()

	# Create one target to knot up all distribution package targets for the package.
	cpfAddDistributionPackagesTarget( ${package} )

endfunction()

#----------------------------------------------------------------------------------------
# Parses the pluginOptionLists and returns two lists of same size. One list cpfContains the
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
			list(APPEND pluginTargets ${pluginTarget})
			list(APPEND pluginDirectories ${ARG_PLUGIN_DIRECTORY})
		endforeach()
	endforeach()
	
	set(${targetsOut} ${pluginTargets} PARENT_SCOPE)
	set(${directoriesOut} ${pluginDirectories} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# This function defines the names of the package sub-targets that occur in a CMakeProjectFramework project.
# The contentIdOut is a shorter string that can be used in output names to identifiy the content type.
#
function( cpfGetCollectPackageContentTargetNameAnId targetNameOut contentIdOut package contentType excludedTargets )

	cpfGetDistributionPackageContentId( contentIdLocal ${contentType} "${excludedTargets}")
	set(${contentIdOut} ${contentIdLocal} PARENT_SCOPE)
	set(${targetNameOut} pkgContent_${contentIdLocal}_${package} PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetDistributionPackageTargetName targetNameOut package contentId contentType packageFormat )
	set( ${targetNameOut} distPckg_${contentId}_${packageFormat}_${package} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Add a target that bundles all the individual distribution-package targets of the package together
#
function( cpfAddDistributionPackagesTarget package )
	cpfGetSubtargets(createPackagesTargets "${package}" CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS)
	if(createPackagesTargets)
		
		cpfGetDistributionPackagesTargetName( targetName ${package})
		
		# Clear the directory from all files except the packages of this version.
		# This prevents the accumulation of old packages in the LastBuild dir.
		cpfAddClearLastBuildDirCommand( clearDirStamp ${package} ${targetName})

		add_custom_target(
			${targetName}
			DEPENDS ${createPackagesTargets} ${clearDirStamp}
		)

		set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")

	endif()
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetDistributionPackagesTargetName targetNameOut package)
	set( ${targetNameOut} distributionPackages_${package} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddClearLastBuildDirCommand stampFileOut package distPackagesTarget )

	cpfGetSubtargets(distPackageTargets "${package}" CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS)
	cpfGetConfigVariableSuffixes(configSuffixes)

	set(packageFiles)
	foreach( target ${distPackageTargets})
		foreach( configSuffix ${configSuffixes})
			get_property(files TARGET ${target} PROPERTY CPF_OUTPUT_FILES${configSuffix})
			foreach(file ${files})
				get_filename_component( shortName "${file}" NAME)
				list(APPEND packageFiles ${shortName})
			endforeach()
		endforeach()
	endforeach()

	cpfGetLastBuildPackagesDir( packagesDir ${package})
	cpfAddClearDirExceptCommand( stampFile "${packagesDir}" "${packageFiles}" ${distPackagesTarget} "${distPackageTargets}")

	set( ${stampFileOut} ${stampFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetLastBuildPackagesDir dirOut package)
	cpfGetRelLastBuildPackagesDir( relPackageDir ${package})
	set( ${dirOut} "${CPF_PROJECT_HTML_ABS_DIR}/${relPackageDir}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddPackageContentTarget packageAssembleOutputFiles targetName package contentId contentType excludedTargets pluginTargets pluginDirectories)

	get_property( installTarget TARGET ${package} PROPERTY CPF_INSTALL_PACKAGE_SUBTARGET )

	set(allSourceTargets)
	set(allOutputFiles)
    set(allStampFiles)
	set(configSuffixes)

	cpfGetConfigurations(configs)
    foreach( config ${configs})
		cpfToConfigSuffix( configSuffix ${config})
		list(APPEND configSuffixes ${configSuffix})

		set(sourceFiles)
		set(relativeDestinationFiles)

		# get the files that are included in the package
		if( "${contentType}" STREQUAL BINARIES_DEVELOPER )
			cpfGetDeveloperPackageFiles( sourceTargets${configSuffix} sourceDir sourceFiles relativeDestinationFiles ${package} ${config} )
		elseif( "${contentType}" STREQUAL BINARIES_USER )
			cpfGetUserPackageFiles( sourceTargets${configSuffix} sourceDir sourceFiles relativeDestinationFiles ${package} ${config} "${excludedTargets}" "${pluginTargets}" "${pluginDirectories}" )
		else()
			message(FATAL_ERROR "Function cpfAddPackageContentTarget() does not support contentType \"${contentType}\"")
		endif()

		# commands for clearing the package stage
		cpfGetPackageContentStagingDir( destDir ${package} ${config} ${contentId})
		cpfGetClearDirectoryCommands( clearContentStageCommands "${destDir}")

		# commands to copy the package files
		cpfPrependMulti( outputFiles${configSuffix} "${destDir}/" "${relativeDestinationFiles}")
		if( NOT "${sourceDir}" STREQUAL "")
			cpfPrependMulti( sourceFiles "${sourceDir}/" "${sourceFiles}")
		endif()
		
		cpfGetInstallFileCommands( copyFilesCommmands "${sourceFiles}" "${outputFiles${configSuffix}}")
		
		# command to touch the target stamp
		set( stampFile "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName}/${config}_copyFiles.stamp")
        cpfGetTouchFileCommands( touchCommmand "${stampFile}")

		cpfAddConfigurationDependendCommand(
			TARGET ${targetName}
            OUTPUT ${stampFile} 
            DEPENDS ${sourceTargets${configSuffix}} # ${sourceFiles} we can currently not depend on the real output files because they are only generated for the active configuration.
			COMMENT "Collect ${package} ${contentType} package files for config ${config}"
            CONFIG ${config}
            COMMANDS_CONFIG ${clearContentStageCommands} ${copyFilesCommmands} ${touchCommmand}
			COMMANDS_NOT_CONFIG ${touchCommmand}
        )
        list(APPEND allOutputFiles ${outputFiles${configSuffix}})
        list(APPEND allStampFiles ${stampFile} )
		list(APPEND allSourceTargets ${sourceTargets${configSuffix}})

	endforeach()

	# add a target
	add_custom_target(
		${targetName}
		DEPENDS ${allSourceTargets} ${allStampFiles}
	)

	# set target properties
	set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	foreach( configSuffix ${configSuffixes})
		set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES${configSuffix} ${outputFiles${configSuffix}})
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# returns the "private" _packaging directory which is used while creating the distribution packages. 
function( cpfGetPackagingDir dirOut )
	# Note that the temp dir needs the contentid level to make sure that instances of cpack do not access the same _CPack_Packages directories, which causes errors.
	set( ${dirOut} "${CMAKE_BINARY_DIR}/${CPF_PACKAGES_ASSEMBLE_DIR}" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageContentStagingDir stagingDirOut package config contentId )
	# we add another config level here, so we can touch files in the not-config case without polluting the collected files
	# cpfGetPackagePrefixOutputDir( packagePrefixDir ${package} )
	cpfGetPackagingDir( baseDir)
	set( ${stagingDirOut} "${baseDir}/${config}/${contentId}/${package}" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetCPackWorkingDir dirOut package config contentId )
		
	# We remove some directory levels and replace them with a hash
	# to shorten the long filenames, which has caused trouble in the past. 
	string(MD5 hash "${package}/${config}/${contentId}" )
	string(SUBSTRING ${hash} 0 8 shortCpackDir)

	cpfGetPackagingDir( baseDir )
	set( ${dirOut} "${baseDir}/${shortCpackDir}" PARENT_SCOPE) 
endfunction()


#----------------------------------------------------------------------------------------
# The BINARIES_DEVELOPER package cpfContains the same files as the install directory of the package
#
function( cpfGetDeveloperPackageFiles sourceTargetsOut sourceDirOut sourceFilesOut destFilesOut package config )
		
	cpfToConfigSuffix( configSuffix ${config})
	cpfGetPackagePrefixOutputDir( packageDir ${package} )
	set( sourceDir "${CMAKE_INSTALL_PREFIX}/${packageDir}")
			
	# get files from install targets
	get_property( installTarget TARGET ${package} PROPERTY CPF_INSTALL_PACKAGE_SUBTARGET )
	get_property( packageFiles TARGET ${installTarget} PROPERTY CPF_OUTPUT_FILES${configSuffix} )
	cpfGetRelativePaths( relPaths ${sourceDir} "${packageFiles}")
	list(APPEND sourceFiles "${relPaths}")

	# get files from abiDump targets
	get_property( abiDumpTargets TARGET ${package} PROPERTY CPF_ABI_DUMP_SUBTARGETS )
	if( abiDumpTargets )
		cpfGetTargetProperties( abiDumpFiles "${abiDumpTargets}" CPF_OUTPUT_FILES${configSuffix})
		cpfGetRelativePaths( relPaths ${sourceDir} "${abiDumpFiles}")
		list(APPEND sourceFiles "${relPaths}")
	endif()

	set(${sourceTargetsOut} ${installTarget} ${abiDumpTargets} PARENT_SCOPE)
	set(${sourceDirOut} ${sourceDir} PARENT_SCOPE)
	set(${sourceFilesOut} ${sourceFiles} PARENT_SCOPE)
	# The destination directory structure is already correct here
	set(${destFilesOut} ${sourceFiles} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# The BINARIES_USER_PORTABLE package cpfContains:
# The packages shared libraries and executables
# no header, cmake-files, debug files and static libraries
# All depended-on shared libraries and plugin libraries except the ones given in the excludedTargets option.
# 
function( cpfGetUserPackageFiles sourceTargetsOut sourceDirOut sourceFilesOut destFilesOut package config excludedTargets pluginTargets pluginDirectories )

    set(allRelevantTargets)
	set(usedTargets)

	# get package internal relevant targets
    get_property( packageTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS )
    foreach(subTarget ${packageTargets})
        get_property( type TARGET ${subTarget} PROPERTY TYPE )
        if( ${type} STREQUAL EXECUTABLE OR ${type} STREQUAL SHARED_LIBRARY )
            list(APPEND allRelevantTargets ${subTarget})
        endif()
    endforeach()
            
    # get depended on shared library targets
	cpfGetLinkedSharedLibsForPackageExecutables( sharedLibs ${package})
	list(APPEND allRelevantTargets ${sharedLibs})
	if(NOT "${excludedTargets}" STREQUAL "")
		list(REMOVE_ITEM allRelevantTargets ${excludedTargets} )
	endif()

	# now get all filenames we are interested in
	foreach(target ${allRelevantTargets})

		set(shortDestinationFiles)
		get_property(targetType TARGET ${target} PROPERTY TYPE)
		if(${targetType} STREQUAL EXECUTABLE OR ${targetType} STREQUAL SHARED_LIBRARY OR ${targetType} STREQUAL MODULE_LIBRARY )

			# the binary file of the target
			cpfGetTargetLocation( targetDir shortName ${target} ${config})
			
            list(APPEND sourceFiles "${targetDir}/${shortName}" )
			list(APPEND shortDestinationFiles ${shortName})

			# symlinks on Linux
			cpfGetTargetVersionSymlinks( symlinks ${target} ${config})

			cpfPrependMulti( symlinksFull "${targetDir}/" "${symlinks}" )
			list(APPEND sourceFiles ${symlinksFull} )
			list(APPEND shortDestinationFiles ${symlinks})
			
            cpfGetTargetOutputType( outputType ${target})
            cpfGetTypePartOfOutputDir( typeDir ${package} ${outputType})
            
            cpfPrependMulti( relativeTargetDestinationFiles "${typeDir}/" "${shortDestinationFiles}" )
            list(APPEND relativeDestinationFiles ${relativeTargetDestinationFiles})

            list(APPEND usedTargets ${target})
			
		endif()
		
	endforeach()
	
	# handle the plugins
	cpfFilterOutSystemPlugins(filteredPluginTargets filteredPluginDirectories "${pluginTargets}" "${pluginDirectories}" "${excludedTargets}")
	set(index 0)
	foreach( pluginTarget ${filteredPluginTargets})
		if(TARGET ${pluginTarget}) # plugins can not exist, so we do not need to specify the platform on which the plugin is needed in cpfAddPackage().

			# source path
			cpfGetTargetLocation( targetDir shortName ${pluginTarget} ${config})
			list(APPEND sourceFiles "${targetDir}/${shortName}" )
            
			# destination path
			cpfGetTypePartOfOutputDir( typeDir ${package} RUNTIME )
			list(GET filteredPluginDirectories ${index} pluginDir)
			list(APPEND relativeDestinationFiles "${typeDir}/${pluginDir}/${shortName}")

			list(APPEND usedTargets ${pluginTarget})

		endif()
		cpfIncrement(index)
	endforeach()

	set(${sourceTargetsOut} ${usedTargets} PARENT_SCOPE)
	set(${sourceDirOut} "" PARENT_SCOPE) # we use full names for simplicity here because of the imported targets there is no common base directory
	set(${sourceFilesOut} ${sourceFiles} PARENT_SCOPE)
	# The destination directory structure is already correct here
	set(${destFilesOut} ${relativeDestinationFiles} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTargetVersionSymlinks symlinksOut target config)

	if(${CMAKE_SYSTEM_NAME} STREQUAL Linux)

		cpfGetTargetLocation( targetDir shortName ${target} ${config})
		cpfToConfigSuffix( configSuffix ${config})
		set(symlinks)

		get_property(isImported TARGET ${target} PROPERTY IMPORTED)
		if(isImported)

			# On Linux we also have to get soname symlinks of the shared libraries
			# Note that there should not be any imported executables. 
			# Executable targets should only come from the package we are installing.
			get_property( soName TARGET ${target} PROPERTY IMPORTED_SONAME${configSuffix})
			if( soName AND NOT "${shortName}" STREQUAL "${soName}" ) 
				list(APPEND symlinks ${soName})
			endif()

		else() # internal targets

			# also add the soname symlinks for shared libraries and the non-versioned name links for executables
			get_property( targetType TARGET ${target} PROPERTY TYPE)
			if(${targetType} STREQUAL EXECUTABLE)

				get_property( outputName TARGET ${target} PROPERTY RUNTIME_OUTPUT_NAME${configSuffix})
				list(APPEND symlinks ${outputName})
								
			elseif(${targetType} STREQUAL SHARED_LIBRARY OR ${targetType} STREQUAL MODULE_LIBRARY)

				get_property( version TARGET ${target} PROPERTY VERSION)
				get_property( soVersion TARGET ${target} PROPERTY SOVERSION)
				string(REPLACE "${version}" "${soVersion}" soName "${shortName}" )
				list(APPEND symlinks ${soName})

			endif()
		endif()

	endif()

	set(${symlinksOut} ${symlinks} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfFilterOutSystemPlugins pluginTargetsOut pluginDirectoriesOut pluginTargetsIn pluginDirectoriesIn excludedTargets ) 

	set(pluginTargetsLocal)
	set(pluginDirectoriesLocal)

	set(index 0)
	foreach( plugin ${pluginTargetsIn})
		cpfContains( cpfContains "${excludedTargets}" ${plugin})
		if(NOT ${cpfContains})
			list(GET pluginDirectoriesIn ${index} directory )
			list(APPEND pluginTargetsLocal ${plugin} )
			list(APPEND pluginDirectoriesLocal ${directory})
		endif()
		cpfIncrement(index)
	endforeach()

	set(${pluginTargetsOut} ${pluginTargetsLocal} PARENT_SCOPE )
	set(${pluginDirectoriesOut} ${pluginDirectoriesLocal} PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
# This function adds target that creates a distribution package. The command specifies how this is done.
# 
function( cpfAddDistributionPackageTarget package contentTarget contentId contentType packageFormat formatOptions )

	if("${packageFormat}" STREQUAL DEB )
		# only create debian packages if the dpkg tool is available
		find_program(dpkgTool dpkg DOC "The tool that helps with creating debian packages.")
		if( ${dpkgTool} STREQUAL dpkgTool-NOTFOUND )
			cpfDebugMessage("Skip creation of target for package format ${packageFormat} because of missing dpkg tool.")
			return()
		endif()
	endif()
	
	cpfGetDistributionPackageTargetName( targetName ${package} ${contentId} ${contentType} ${packageFormat})

	get_property( version TARGET ${package} PROPERTY VERSION )

	set(configSuffixes)
	set(allOutputFiles)
	cpfGetConfigurations(configs)
	foreach(config ${configs}) #once more we have to add a target for each configuration because OUTPUT of add_custom_command does not support generator expressions.
		cpfToConfigSuffix( configSuffix ${config})
		list(APPEND configSuffixes ${configSuffix})

		# locations / files
		cpfGetBasePackageFilename( basePackageFileName ${package} ${config} ${version} ${contentId} ${packageFormat})
		cpfGetDistributionPackageExtension( extension ${packageFormat})
		set( shortPackageFilename ${basePackageFileName}.${extension} )
		cpfGetCPackWorkingDir( packagesOutputDirTemp ${package} ${config} ${contentId})

		# Get the cpack command that creates the package file
		# Note that the package is created in a temporary directory and later copied to the "Packages" directory.
		# This is done because cmake creates a temporary "_CPACK_Packages" directory which we do not want in our final Packages directory.
		# Another reason is that the temporary package directory needs an additional directory level with the package content type to prevent simultaneous
		# accesses of cpack to the "_CPACK_Packages" directory. The copy operation allows us to get rid of that extra level in the "Packages" directory.
		cpfGetPackagingCommand( packagingCommand ${package} ${config} ${version} ${contentId} ${contentType} ${packageFormat} ${packagesOutputDirTemp} ${basePackageFileName} "${formatOptions}")
		
		# Create a command to copy the package file to the html/Downloads directories
		cpfGetLastBuildPackagesDir( packagesDir ${package})
		set(destPackageFile${configSuffix} "${packagesDir}/${shortPackageFilename}")
		cpfGetInstallFileCommands( copyToHtmlLastBuildCommand "${packagesOutputDirTemp}/${shortPackageFilename}" "${destPackageFile${configSuffix}}")
		
		cpfIsReleaseVersion( isRelease ${version})
		set(copyToHtmlReleasesCommand)
		if(isRelease)
			cpfGetRelReleasePackagesDir( releasePackagesDir ${package} ${version} )
			cpfGetInstallFileCommands( copyToHtmlReleasesCommand "${packagesOutputDirTemp}/${shortPackageFilename}" "${CPF_PROJECT_HTML_ABS_DIR}/${releasePackagesDir}/${shortPackageFilename}")
		endif()


		# use a stamp file instead of real output files so we do not need to polute the LastBuild dir with empty package files
		set( stampFile "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName}/copyToHtml_${shortPackageFilename}.stamp")
		set( touchStampCommand "cmake -E touch \"${stampFile}\"")

		get_property( inputFiles TARGET ${contentTarget} PROPERTY CPF_OUTPUT_FILES${configSuffix})
		cpfAddConfigurationDependendCommand(
            TARGET ${targetName}
			OUTPUT ${stampFile}	# we use a stamp-file here because we do not want to pollute the output directory with empty files. This should work because there are no consumers of the files.
            DEPENDS ${contentTarget} #${inputFiles} we can ont use the input files because the content targets uses a stamp file
            COMMENT "Create distribution package ${packageFormat} for ${package}."
            CONFIG ${config}
            COMMANDS_CONFIG ${packagingCommand} ${copyToHtmlLastBuildCommand} ${copyToHtmlReleasesCommand} ${touchStampCommand}
			COMMANDS_NOT_CONFIG ${touchStampCommand}
        )

		list(APPEND allOutputFiles ${stampFile})

	endforeach()

	add_custom_target(
		${targetName}
		DEPENDS ${contentTarget} ${allOutputFiles}
	)

	set_property( TARGET ${package} APPEND PROPERTY CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	
	foreach( configSuffix ${configSuffixes})
		set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES${configSuffix} ${destPackageFile${configSuffix}})
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# nameWEOut short filename without the extension
function( cpfGetBasePackageFilename nameWEOut package config version contentId packageFormat )
	
	if( ${packageFormat} STREQUAL DEB)
        
        cpfFindRequiredProgram( TOOL_DPKG dpkg "The debian package manager.")

        # Debian packages need to follow a certain naming scheme.
        # Note that the filename of the created package is not influenced by what is returned here.
        # This mimic the filename of the package to get the dependencies of the custom commands right.
        string( TOLOWER ${package} lowerPackage )
        
        # We need the architecture name
        # Assume that the host and target system are the same
        if( NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "${CMAKE_HOST_SYSTEM_NAME}")
            message( FATAL_ERROR "Function cpfGetBasePackageFilename() was written with the assumption that CMAKE_SYSTEM_NAME and CMAKE_HOST_SYSTEM_NAME are the same.")
        endif()
        cpfExecuteProcess( architecture "\"${TOOL_DPKG}\" --print-architecture" "${CPF_ROOT_DIR}")
        
        set( nameWE "${lowerPackage}_${version}_${architecture}")
    else()
        set( nameWE "${package}.${version}.${CMAKE_SYSTEM_NAME}.${contentId}.${config}")
    endif()
    
    set(${nameWEOut} ${nameWE} PARENT_SCOPE)
    
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackagingCommand commandOut package config version contentId contentType packageFormat packageOutputDir baseFileName formatOptions )

	cpfIsArchiveFormat( isArchiveGenerator ${packageFormat} )
	if( isArchiveGenerator  )
		cpfGetArchivePackageCommand( command ${package} ${config} ${version} ${contentId} ${contentType} ${packageFormat} ${packageOutputDir} ${baseFileName} )
	elseif( "${packageFormat}" STREQUAL DEB )
		cpfGetDebianPackageCommand( command ${package} ${config} ${version} ${contentId} ${contentType} ${packageFormat} ${packageOutputDir} ${baseFileName} "${formatOptions}" )
	else()
		message(FATAL_ERROR "Package format \"${packageFormat}\" is not supported by function cpfGetPackagingCommand()")
	endif()

	set( ${commandOut} ${command} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# This function creates a cpack command that creates one of the compressed archive packages
# 
function( cpfGetArchivePackageCommand commandOut package config version contentId contentType packageFormat packageOutputDir baseFileName )

	cpfGetPackageContentStagingDir( packageContentDir ${package} ${config} ${contentId})

	# Setup the cpack command for creating the package
	set( command
"cpack -G \"${packageFormat}\" \
-D CPACK_PACKAGE_NAME=${${package}} \
-D CPACK_PACKAGE_VERSION=${version} \
-D CPACK_INSTALLED_DIRECTORIES=\"${packageContentDir}\"$<SEMICOLON>. \
-D CPACK_PACKAGE_FILE_NAME=\"${baseFileName}\" \
-D CPACK_PACKAGE_DESCRIPTION=\"${CPF_PACKAGE_DESCRIPTION}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
-C ${config} \
-P ${package} \
	")
	set( ${commandOut} ${command} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function creates a cpack command that creates debian package .dpkg 
# 
function( cpfGetDebianPackageCommand commandOut package config version contentId contentType packageFormat packageOutputDir baseFileName formatOptions )

	cmake_parse_arguments(
		ARG
		""
		""
		"SYSTEM_PACKAGES_DEB"
		"${formatOptions}"
	)

	cpfGetPackageContentStagingDir( packageContentDir ${package} ${config} ${contentId})
	
	# todo get string for package dependencies
	# example "libc6 (>= 2.3.1-6), libc6 (< 2.4)"
	# todo package description durchschl�usen

	get_property( description TARGET ${package} PROPERTY CPF_BRIEF_PACKAGE_DESCRIPTION )
	get_property( homepage TARGET ${package} PROPERTY CPF_PACKAGE_HOMEPAGE )
	get_property( maintainer TARGET ${package} PROPERTY CPF_PACKAGE_MAINTAINER_EMAIL )
	
	# Setup the cpack command for creating the package
	set( command
"cpack -G \"${packageFormat}\" \
-D CPACK_PACKAGE_NAME=${package} \
-D CPACK_PACKAGE_VERSION=${version} \
-D CPACK_INSTALLED_DIRECTORIES=\"${packageContentDir}\"$<SEMICOLON>. \
-D CPACK_PACKAGE_FILE_NAME=\"${baseFileName}\" \
-D CPACK_PACKAGE_DESCRIPTION=\"${CPF_PACKAGE_DESCRIPTION}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
-D CPACK_PACKAGE_CONTACT=\"${maintainer}\" \
-D CPACK_DEBIAN_FILE_NAME=DEB-DEFAULT \
-D CPACK_DEBIAN_PACKAGE_DEPENDS=\"${ARG_SYSTEM_PACKAGES_DEB}\" \
-D CPACK_DEBIAN_PACKAGE_DESCRIPTION=\"${description}\" \
-D CPACK_DEBIAN_PACKAGE_HOMEPAGE=\"${homepage}\" \
-C ${config} \
-P ${package} \
	")
	set( ${commandOut} ${command} PARENT_SCOPE)

endfunction()









