
include(ccbCustomTargetUtilities)
include(ccbLocations)
include(ccbAddCompatibilityCheckTarget)
#include(CPack) # adding this creates the global package target

set(DIR_OF_THIS_FILE ${CMAKE_CURRENT_LIST_DIR})

#----------------------------------------------------------------------------------------
# Adds a global target that makes sure that all the per package createArchivePackage targets are build.
#
function( ccbAddGlobalCreatePackagesTarget packages)

    set(targetName distributionPackages)
	
	set(packageTargets)
	foreach(package ${packages})
		ccbGetDistributionPackagesTargetName( packageTarget ${package})
		if(TARGET ${packageTarget}) # not all packages may create distribution packages
			list(APPEND packageTargets ${packageTarget})
		endif()
	endforeach()
	
	ccbAddBundleTarget( ${targetName} "${packageTargets}" )

endfunction()

#----------------------------------------------------------------------------------------
#
# For argument documentation see the ccbAddPackage() function.
function( ccbAddDistributionPackageTargets package packageOptionLists pluginOptionLists )

	# todo create pair list for plugin options
	ccbGetPluginTargetDirectoryPairLists( pluginTargets pluginDirectories "${pluginOptionLists}" )
	
	foreach( list ${packageOptionLists})

		ccbParseDistributionPackageOptions( contentType packageFormats distributionPackageFormatOptions excludedTargets "${${list}}")

		# First we create targets that assemble the content of the desired contentType
		ccbGetCollectPackageContentTargetNameAnId( packageContentTarget contentId ${package} ${contentType} "${excludedTargets}")
		if(NOT TARGET ${packageContentTarget})
			ccbAddPackageContentTarget( packageAssembleOutputFiles ${packageContentTarget} ${package} ${contentId} ${contentType} "${excludedTargets}" "${pluginTargets}" "${pluginDirectories}")
		endif()

		foreach(packageFormat ${packageFormats})
			ccbAddDistributionPackageTarget( ${package} ${packageContentTarget} ${contentId} ${contentType} ${packageFormat} "${distributionPackageFormatOptions}")
		endforeach()
	endforeach()

	# Create one target to knot up all distribution package targets for the package.
	ccbAddDistributionPackagesTarget( ${package} )

endfunction()

#----------------------------------------------------------------------------------------
# Parses the pluginOptionLists and returns two lists of same size. One list ccbContains the
# plugin target while the element with the same index in the other list ccbContains the 
# directory of the plugin target.
function( ccbGetPluginTargetDirectoryPairLists targetsOut directoriesOut pluginOptionLists )
	# parse the plugin dependencies arguments
	# Creates two lists of the same length, where one list ccbContains the plugin targets
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
# This function defines the names of the package sub-targets that occur in the CppCodeBase.
# The contentIdOut is a shorter string that can be used in output names to identifiy the content type.
#
function( ccbGetCollectPackageContentTargetNameAnId targetNameOut contentIdOut package contentType excludedTargets )

	ccbGetDistributionPackageContentId( contentIdLocal ${contentType} "${excludedTargets}")
	set(${contentIdOut} ${contentIdLocal} PARENT_SCOPE)
	set(${targetNameOut} gatherPkgContent_${contentIdLocal}_${package} PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetDistributionPackageTargetName targetNameOut package contentId contentType packageFormat )
	set( ${targetNameOut} distPackage_${contentId}_${packageFormat}_${package} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Add a target that bundles all the individual distribution-package targets of the package together
#
function( ccbAddDistributionPackagesTarget package )
	ccbGetSubtargets(createPackagesTargets "${package}" CCB_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS)
	if(createPackagesTargets)
		
		ccbGetDistributionPackagesTargetName( targetName ${package})
		
		# Clear the directory from all files except the packages of this version.
		# This prevents the accumulation of old packages in the LastBuild dir.
		ccbAddClearLastBuildDirCommand( clearDirStamp ${package} ${targetName})

		add_custom_target(
			${targetName}
			DEPENDS ${createPackagesTargets} ${clearDirStamp}
		)

		set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")

	endif()
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetDistributionPackagesTargetName targetNameOut package)
	set( ${targetNameOut} distributionPackages_${package} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddClearLastBuildDirCommand stampFileOut package distPackagesTarget )

	ccbGetSubtargets(distPackageTargets "${package}" CCB_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS)
	ccbGetConfigVariableSuffixes(configSuffixes)

	set(packageFiles)
	foreach( target ${distPackageTargets})
		foreach( configSuffix ${configSuffixes})
			get_property(files TARGET ${target} PROPERTY CCB_OUTPUT_FILES${configSuffix})
			foreach(file ${files})
				get_filename_component( shortName "${file}" NAME)
				list(APPEND packageFiles ${shortName})
			endforeach()
		endforeach()
	endforeach()

	ccbGetLastBuildPackagesDir( packagesDir ${package})
	ccbAddClearDirExceptCommand( stampFile "${packagesDir}" "${packageFiles}" ${distPackagesTarget} "${distPackageTargets}")

	set( ${stampFileOut} ${stampFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetLastBuildPackagesDir dirOut package)
	ccbGetRelLastBuildPackagesDir( relPackageDir ${package})
	set( ${dirOut} "${CCB_PROJECT_HTML_ABS_DIR}/${relPackageDir}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddPackageContentTarget packageAssembleOutputFiles targetName package contentId contentType excludedTargets pluginTargets pluginDirectories)

	get_property( installTarget TARGET ${package} PROPERTY CCB_INSTALL_PACKAGE_SUBTARGET )

	set(allSourceTargets)
	set(allOutputFiles)
    set(allStampFiles)
	set(configSuffixes)

	ccbGetConfigurations(configs)
    foreach( config ${configs})
		ccbToConfigSuffix( configSuffix ${config})
		list(APPEND configSuffixes ${configSuffix})

		set(sourceFiles)
		set(relativeDestinationFiles)

		# get the files that are included in the package
		if( "${contentType}" STREQUAL BINARIES_DEVELOPER )
			ccbGetDeveloperPackageFiles( sourceTargets${configSuffix} sourceDir sourceFiles relativeDestinationFiles ${package} ${config} )
		elseif( "${contentType}" STREQUAL BINARIES_USER )
			ccbGetUserPackageFiles( sourceTargets${configSuffix} sourceDir sourceFiles relativeDestinationFiles ${package} ${config} "${excludedTargets}" "${pluginTargets}" "${pluginDirectories}" )
		else()
			message(FATAL_ERROR "Function ccbAddPackageContentTarget() does not support contentType \"${contentType}\"")
		endif()

		# commands for clearing the package stage
		ccbGetPackageContentStagingDir( destDir ${package} ${config} ${contentId})
		ccbGetClearDirectoryCommands( clearContentStageCommands "${destDir}")

		# commands to copy the package files
		ccbPrependMulti( outputFiles${configSuffix} "${destDir}/" "${relativeDestinationFiles}")
		if( NOT "${sourceDir}" STREQUAL "")
			ccbPrependMulti( sourceFiles "${sourceDir}/" "${sourceFiles}")
		endif()
		
		ccbGetInstallFileCommands( copyFilesCommmands "${sourceFiles}" "${outputFiles${configSuffix}}")
		
		# command to touch the target stamp
		set( stampFile "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/${targetName}/${config}_copyFiles.stamp")
        ccbGetTouchFileCommands( touchCommmand "${stampFile}")

		ccbAddConfigurationDependendCommand(
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
		set_property(TARGET ${targetName} PROPERTY CCB_OUTPUT_FILES${configSuffix} ${outputFiles${configSuffix}})
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# returns the "private" _packaging directory which is used while creating the distribution packages. 
function( ccbGetPackagingDir dirOut )
	# Note that the temp dir needs the contentid level to make sure that instances of cpack do not access the same _CPack_Packages directories, which causes errors.
	set( ${dirOut} "${CMAKE_BINARY_DIR}/${CCB_PACKAGES_ASSEMBLE_DIR}" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetPackageContentStagingDir stagingDirOut package config contentId )
	# we add another config level here, so we can touch files in the not-config case without polluting the collected files
	# ccbGetPackagePrefixOutputDir( packagePrefixDir ${package} )
	ccbGetPackagingDir( baseDir)
	set( ${stagingDirOut} "${baseDir}/${config}/${contentId}/${package}" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetCPackWorkingDir dirOut package config contentId )
		
	# We remove some directory levels and replace them with a hash
	# to shorten the long filenames, which has caused trouble in the past. 
	string(MD5 hash "${package}/${config}/${contentId}" )
	string(SUBSTRING ${hash} 0 8 shortCpackDir)

	ccbGetPackagingDir( baseDir )
	set( ${dirOut} "${baseDir}/${shortCpackDir}" PARENT_SCOPE) 
endfunction()


#----------------------------------------------------------------------------------------
# The BINARIES_DEVELOPER package ccbContains the same files as the install directory of the package
#
function( ccbGetDeveloperPackageFiles sourceTargetsOut sourceDirOut sourceFilesOut destFilesOut package config )
		
	ccbToConfigSuffix( configSuffix ${config})
	ccbGetPackagePrefixOutputDir( packageDir ${package} )
	set( sourceDir "${CMAKE_INSTALL_PREFIX}/${packageDir}")
			
	# get files from install targets
	get_property( installTarget TARGET ${package} PROPERTY CCB_INSTALL_PACKAGE_SUBTARGET )
	get_property( packageFiles TARGET ${installTarget} PROPERTY CCB_OUTPUT_FILES${configSuffix} )
	ccbGetRelativePaths( relPaths ${sourceDir} "${packageFiles}")
	list(APPEND sourceFiles "${relPaths}")

	# get files from abiDump targets
	get_property( abiDumpTargets TARGET ${package} PROPERTY CCB_ABI_DUMP_SUBTARGETS )
	if( abiDumpTargets )
		ccbGetTargetProperties( abiDumpFiles "${abiDumpTargets}" CCB_OUTPUT_FILES${configSuffix})
		ccbGetRelativePaths( relPaths ${sourceDir} "${abiDumpFiles}")
		list(APPEND sourceFiles "${relPaths}")
	endif()

	set(${sourceTargetsOut} ${installTarget} ${abiDumpTargets} PARENT_SCOPE)
	set(${sourceDirOut} ${sourceDir} PARENT_SCOPE)
	set(${sourceFilesOut} ${sourceFiles} PARENT_SCOPE)
	# The destination directory structure is already correct here
	set(${destFilesOut} ${sourceFiles} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# The BINARIES_USER_PORTABLE package ccbContains:
# The packages shared libraries and executables
# no header, cmake-files, debug files and static libraries
# All depended-on shared libraries and plugin libraries except the ones given in the excludedTargets option.
# 
function( ccbGetUserPackageFiles sourceTargetsOut sourceDirOut sourceFilesOut destFilesOut package config excludedTargets pluginTargets pluginDirectories )

    set(allRelevantTargets)
	set(usedTargets)

	# get package internal relevant targets
    get_property( packageTargets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS )
    foreach(subTarget ${packageTargets})
        get_property( type TARGET ${subTarget} PROPERTY TYPE )
        if( ${type} STREQUAL EXECUTABLE OR ${type} STREQUAL SHARED_LIBRARY )
            list(APPEND allRelevantTargets ${subTarget})
        endif()
    endforeach()
            
    # get depended on shared library targets
	ccbGetLinkedSharedLibsForPackageExecutables( sharedLibs ${package})
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
			ccbGetTargetLocation( targetDir shortName ${target} ${config})
			
            list(APPEND sourceFiles "${targetDir}/${shortName}" )
			list(APPEND shortDestinationFiles ${shortName})

			# symlinks on Linux
			ccbGetTargetVersionSymlinks( symlinks ${target} ${config})

			ccbPrependMulti( symlinksFull "${targetDir}/" "${symlinks}" )
			list(APPEND sourceFiles ${symlinksFull} )
			list(APPEND shortDestinationFiles ${symlinks})
			
            ccbGetTargetOutputType( outputType ${target})
            ccbGetTypePartOfOutputDir( typeDir ${package} ${outputType})
            
            ccbPrependMulti( relativeTargetDestinationFiles "${typeDir}/" "${shortDestinationFiles}" )
            list(APPEND relativeDestinationFiles ${relativeTargetDestinationFiles})

            list(APPEND usedTargets ${target})
			
		endif()
		
	endforeach()
	
	# handle the plugins
	ccbFilterOutSystemPlugins(filteredPluginTargets filteredPluginDirectories "${pluginTargets}" "${pluginDirectories}" "${excludedTargets}")
	set(index 0)
	foreach( pluginTarget ${filteredPluginTargets})
		if(TARGET ${pluginTarget}) # plugins can not exist, so we do not need to specify the platform on which the plugin is needed in ccbAddPackage().

			# source path
			ccbGetTargetLocation( targetDir shortName ${pluginTarget} ${config})
			list(APPEND sourceFiles "${targetDir}/${shortName}" )
            
			# destination path
			ccbGetTypePartOfOutputDir( typeDir ${package} RUNTIME )
			list(GET filteredPluginDirectories ${index} pluginDir)
			list(APPEND relativeDestinationFiles "${typeDir}/${pluginDir}/${shortName}")

			list(APPEND usedTargets ${pluginTarget})

		endif()
		ccbIncrement(index)
	endforeach()

	set(${sourceTargetsOut} ${usedTargets} PARENT_SCOPE)
	set(${sourceDirOut} "" PARENT_SCOPE) # we use full names for simplicity here because of the imported targets there is no common base directory
	set(${sourceFilesOut} ${sourceFiles} PARENT_SCOPE)
	# The destination directory structure is already correct here
	set(${destFilesOut} ${relativeDestinationFiles} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetTargetVersionSymlinks symlinksOut target config)

	if(${CMAKE_SYSTEM_NAME} STREQUAL Linux)

		ccbGetTargetLocation( targetDir shortName ${target} ${config})
		ccbToConfigSuffix( configSuffix ${config})
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
function( ccbFilterOutSystemPlugins pluginTargetsOut pluginDirectoriesOut pluginTargetsIn pluginDirectoriesIn excludedTargets ) 

	set(pluginTargetsLocal)
	set(pluginDirectoriesLocal)

	set(index 0)
	foreach( plugin ${pluginTargetsIn})
		ccbContains( ccbContains "${excludedTargets}" ${plugin})
		if(NOT ${ccbContains})
			list(GET pluginDirectoriesIn ${index} directory )
			list(APPEND pluginTargetsLocal ${plugin} )
			list(APPEND pluginDirectoriesLocal ${directory})
		endif()
		ccbIncrement(index)
	endforeach()

	set(${pluginTargetsOut} ${pluginTargetsLocal} PARENT_SCOPE )
	set(${pluginDirectoriesOut} ${pluginDirectoriesLocal} PARENT_SCOPE )

endfunction()

#----------------------------------------------------------------------------------------
# This function adds target that creates a distribution package. The command specifies how this is done.
# 
function( ccbAddDistributionPackageTarget package contentTarget contentId contentType packageFormat formatOptions )

	if("${packageFormat}" STREQUAL DEB )
		# only create debian packages if the dpkg tool is available
		find_program(dpkgTool dpkg DOC "The tool that helps with creating debian packages.")
		if( ${dpkgTool} STREQUAL dpkgTool-NOTFOUND )
			ccbDebugMessage("Skip creation of target for package format ${packageFormat} because of missing dpkg tool.")
			return()
		endif()
	endif()
	
	ccbGetDistributionPackageTargetName( targetName ${package} ${contentId} ${contentType} ${packageFormat})

	get_property( version TARGET ${package} PROPERTY VERSION )

	set(configSuffixes)
	set(allOutputFiles)
	ccbGetConfigurations(configs)
	foreach(config ${configs}) #once more we have to add a target for each configuration because OUTPUT of add_custom_command does not support generator expressions.
		ccbToConfigSuffix( configSuffix ${config})
		list(APPEND configSuffixes ${configSuffix})

		# locations / files
		ccbGetBasePackageFilename( basePackageFileName ${package} ${config} ${version} ${contentId} ${packageFormat})
		ccbGetDistributionPackageExtension( extension ${packageFormat})
		set( shortPackageFilename ${basePackageFileName}.${extension} )
		ccbGetCPackWorkingDir( packagesOutputDirTemp ${package} ${config} ${contentId})

		# Get the cpack command that creates the package file
		# Note that the package is created in a temporary directory and later copied to the "Packages" directory.
		# This is done because cmake creates a temporary "_CPACK_Packages" directory which we do not want in our final Packages directory.
		# Another reason is that the temporary package directory needs an additional directory level with the package content type to prevent simultaneous
		# accesses of cpack to the "_CPACK_Packages" directory. The copy operation allows us to get rid of that extra level in the "Packages" directory.
		ccbGetPackagingCommand( packagingCommand ${package} ${config} ${version} ${contentId} ${contentType} ${packageFormat} ${packagesOutputDirTemp} ${basePackageFileName} "${formatOptions}")
		
		# Create a command to copy the package file to the html/Downloads directories
		ccbGetLastBuildPackagesDir( packagesDir ${package})
		set(destPackageFile${configSuffix} "${packagesDir}/${shortPackageFilename}")
		ccbGetInstallFileCommands( copyToHtmlLastBuildCommand "${packagesOutputDirTemp}/${shortPackageFilename}" "${destPackageFile${configSuffix}}")
		
		ccbIsReleaseVersion( isRelease ${version})
		set(copyToHtmlReleasesCommand)
		if(isRelease)
			ccbGetRelReleasePackagesDir( releasePackagesDir ${package} ${version} )
			ccbGetInstallFileCommands( copyToHtmlReleasesCommand "${packagesOutputDirTemp}/${shortPackageFilename}" "${CCB_PROJECT_HTML_ABS_DIR}/${releasePackagesDir}/${shortPackageFilename}")
		endif()


		# use a stamp file instead of real output files so we do not need to polute the LastBuild dir with empty package files
		set( stampFile "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/${targetName}/copyToHtml_${shortPackageFilename}.stamp")
		set( touchStampCommand "cmake -E touch \"${stampFile}\"")

		get_property( inputFiles TARGET ${contentTarget} PROPERTY CCB_OUTPUT_FILES${configSuffix})
		ccbAddConfigurationDependendCommand(
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

	set_property( TARGET ${package} APPEND PROPERTY CCB_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	
	foreach( configSuffix ${configSuffixes})
		set_property(TARGET ${targetName} PROPERTY CCB_OUTPUT_FILES${configSuffix} ${destPackageFile${configSuffix}})
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# nameWEOut short filename without the extension
function( ccbGetBasePackageFilename nameWEOut package config version contentId packageFormat )
	
	if( ${packageFormat} STREQUAL DEB)
        
        ccbFindRequiredProgram( TOOL_DPKG dpkg "The debian package manager.")

        # Debian packages need to follow a certain naming scheme.
        # Note that the filename of the created package is not influenced by what is returned here.
        # This mimic the filename of the package to get the dependencies of the custom commands right.
        string( TOLOWER ${package} lowerPackage )
        
        # We need the architecture name
        # Assume that the host and target system are the same
        if( NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "${CMAKE_HOST_SYSTEM_NAME}")
            message( FATAL_ERROR "Function ccbGetBasePackageFilename() was written with the assumption that CMAKE_SYSTEM_NAME and CMAKE_HOST_SYSTEM_NAME are the same.")
        endif()
        ccbExecuteProcess( architecture "\"${TOOL_DPKG}\" --print-architecture" "${CCB_ROOT_DIR}")
        
        set( nameWE "${lowerPackage}_${version}_${architecture}")
    else()
        set( nameWE "${package}.${version}.${CMAKE_SYSTEM_NAME}.${contentId}.${config}")
    endif()
    
    set(${nameWEOut} ${nameWE} PARENT_SCOPE)
    
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetPackagingCommand commandOut package config version contentId contentType packageFormat packageOutputDir baseFileName formatOptions )

	ccbIsArchiveFormat( isArchiveGenerator ${packageFormat} )
	if( isArchiveGenerator  )
		ccbGetArchivePackageCommand( command ${package} ${config} ${version} ${contentId} ${contentType} ${packageFormat} ${packageOutputDir} ${baseFileName} )
	elseif( "${packageFormat}" STREQUAL DEB )
		ccbGetDebianPackageCommand( command ${package} ${config} ${version} ${contentId} ${contentType} ${packageFormat} ${packageOutputDir} ${baseFileName} "${formatOptions}" )
	else()
		message(FATAL_ERROR "Package format \"${packageFormat}\" is not supported by function ccbGetPackagingCommand()")
	endif()

	set( ${commandOut} ${command} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# This function creates a cpack command that creates one of the compressed archive packages
# 
function( ccbGetArchivePackageCommand commandOut package config version contentId contentType packageFormat packageOutputDir baseFileName )

	ccbGetPackageContentStagingDir( packageContentDir ${package} ${config} ${contentId})

	# Setup the cpack command for creating the package
	set( command
"cpack -G \"${packageFormat}\" \
-D CPACK_PACKAGE_NAME=${${package}} \
-D CPACK_PACKAGE_VERSION=${version} \
-D CPACK_INSTALLED_DIRECTORIES=\"${packageContentDir}\"$<SEMICOLON>. \
-D CPACK_PACKAGE_FILE_NAME=\"${baseFileName}\" \
-D CPACK_PACKAGE_DESCRIPTION=\"${CPPCODEBASE_PACKAGE_DESCRIPTION}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
-C ${config} \
-P ${package} \
	")
	set( ${commandOut} ${command} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function creates a cpack command that creates debian package .dpkg 
# 
function( ccbGetDebianPackageCommand commandOut package config version contentId contentType packageFormat packageOutputDir baseFileName formatOptions )

	cmake_parse_arguments(
		ARG
		""
		""
		"SYSTEM_PACKAGES_DEB"
		"${formatOptions}"
	)

	ccbGetPackageContentStagingDir( packageContentDir ${package} ${config} ${contentId})
	
	# todo get string for package dependencies
	# example "libc6 (>= 2.3.1-6), libc6 (< 2.4)"
	# todo package description durchschl�usen

	get_property( description TARGET ${package} PROPERTY CCB_BRIEF_PACKAGE_DESCRIPTION )
	get_property( homepage TARGET ${package} PROPERTY CCB_PACKAGE_HOMEPAGE )
	get_property( maintainer TARGET ${package} PROPERTY CCB_PACKAGE_MAINTAINER_EMAIL )
	
	# Setup the cpack command for creating the package
	set( command
"cpack -G \"${packageFormat}\" \
-D CPACK_PACKAGE_NAME=${package} \
-D CPACK_PACKAGE_VERSION=${version} \
-D CPACK_INSTALLED_DIRECTORIES=\"${packageContentDir}\"$<SEMICOLON>. \
-D CPACK_PACKAGE_FILE_NAME=\"${baseFileName}\" \
-D CPACK_PACKAGE_DESCRIPTION=\"${CPPCODEBASE_PACKAGE_DESCRIPTION}\" \
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









