include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddInstallRules)




#----------------------------------------------------------------------------------------
# Adds a global target that makes sure that all the per package createArchivePackage targets are build.
#
function( cpfAddGlobalCreatePackagesTarget packages)

    set(targetName distributionPackages)
	
	set(packageTargets)
	foreach(package ${packages})
		cpfGetDistributionPackagesTargetName( packageTarget ${package})
		if(TARGET ${packageTarget}) # not all packages may create distribution packages
			cpfListAppend( packageTargets ${packageTarget})
		endif()
	endforeach()
	
	cpfAddBundleTarget( ${targetName} "${packageTargets}" )

endfunction()

#----------------------------------------------------------------------------------------
#
# For argument documentation see the cpfAddCppPackage() function.
function( cpfAddDistributionPackageTargets package packageOptionLists )

	foreach( list ${packageOptionLists})

		cpfParseDistributionPackageOptions( contentType packageFormats distributionPackageFormatOptions excludedTargets "${${list}}")

		# First we create targets that assemble the content of the desired contentType.
		# We have extra targets for this so we can create multiple packages with the same content.
		cpfGetCollectPackageContentTargetNameAnId( packageContentTarget contentId ${package} ${contentType} "${excludedTargets}")
		if(NOT TARGET ${packageContentTarget})
			cpfAddPackageContentTarget( ${packageContentTarget} ${package} ${contentId} ${contentType} )
		endif()

		foreach(packageFormat ${packageFormats})
			cpfAddDistributionPackageTarget( ${package} ${packageContentTarget} ${contentId} ${contentType} ${packageFormat} "${distributionPackageFormatOptions}")
		endforeach()

	endforeach()

	# Create one target to knot up all distribution package targets for the package.
	cpfAddDistributionPackagesTarget( ${package} )

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
# Add a target that bundles all the individual distribution-package targets of the package together.
# The target also makes sure that old packages in LastBuild are deleted. 
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
			get_property(files TARGET ${target} PROPERTY CPF_OUTPUT_FILES_${configSuffix})
			foreach(file ${files})
				get_filename_component( shortName "${file}" NAME)
				cpfListAppend( packageFiles ${shortName})
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
function( cpfAddPackageContentTarget targetName package contentId contentType )

	get_property( installTarget TARGET ${package} PROPERTY CPF_INSTALL_PACKAGE_SUBTARGET )

	cpfGetPackageComponents( components ${contentType} ${contentId} )

    set(allStampFiles)
	set(configSuffixes)
	cpfGetConfigurations(configs)
    foreach( config ${configs})
		cpfToConfigSuffix( configSuffix ${config})
		cpfListAppend( configSuffixes ${configSuffix})

		# Get target and file dependencies
		cpfGetContentProducingTargetsAndOutputFiles( contentProducerTargets dependedOnFiles ${package} ${config} "${components}" )

		# get the files that are included in the package
		cpfGetPackageContentStagingDir( destDir ${package} ${config} ${contentId})
		cpfGetInstalledFiles( relativeDestinationFiles ${package} ${config} "${components}" )
		cpfPrependMulti( outputFiles${configSuffix} "${destDir}/" "${relativeDestinationFiles}")

		# commands for clearing the package stage
		cpfGetClearDirectoryCommands( clearContentStageCommands "${destDir}")

		# commands to run the packages install script
		cpfGetRunInstallScriptCommands( runInstallScriptCommands ${package} ${config} "${components}" "${destDir}" )

		# command to touch the target stamp
		set( stampFile${configSuffix} "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName}/${config}_copyFiles.stamp")
        cpfGetTouchFileCommands( touchCommmand "${stampFile${configSuffix}}")
		cpfAddConfigurationDependendCommand(
			TARGET ${targetName}
            OUTPUT ${stampFile${configSuffix}}
            DEPENDS ${sourceTargets${configSuffix}} ${dependedOnFiles}
			COMMENT "Collect ${package} ${contentType} package files for config ${config}"
            CONFIG ${config}
            COMMANDS_CONFIG ${clearContentStageCommands} ${runInstallScriptCommands} ${touchCommmand}
			COMMANDS_NOT_CONFIG ${touchCommmand}
		)
		
        cpfListAppend( allStampFiles ${stampFile${configSuffix}} )

	endforeach()

	# add a target
	add_custom_target(
		${targetName}
		DEPENDS ${contentProducerTargets} ${allStampFiles}
	)

	# set target properties
	set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	foreach( configSuffix ${configSuffixes})
		set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES_${configSuffix} ${outputFiles${configSuffix}})
		set_property(TARGET ${targetName} PROPERTY CPF_STAMP_FILE_${configSuffix} ${stampFile${configSuffix}})
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list of components that belong to a contentType.
#
function( cpfGetPackageComponents componentsOut contentType contentId )

	set(components)
	if( "${contentType}" STREQUAL CT_RUNTIME )
		set(components runtime)
	elseif( "${contentType}" STREQUAL CT_RUNTIME_PORTABLE )
		set(components runtime ${contentId} )
	elseif( "${contentType}" STREQUAL CT_DEVELOPER )
		set(components runtime developer )
	elseif( "${contentType}" STREQUAL CT_SOURCES )
		set(components sources )
	else()
		message(FATAL_ERROR "Function cpfAddPackageContentTarget() does not support contentType \"${contentType}\"")
	endif()

	set(${componentsOut} "${components}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetContentProducingTargetsAndOutputFiles contentProducerTargetsOut filesOut package config components )

	cpfToConfigSuffix(configSuffix ${config})

	# The content depends on the binary targets
	get_property(binaryTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS )

	# Get dumpfile target dependencies
	set(abiDumpTargets)
	set(files)
	foreach(binaryTarget ${binaryTargets})
		
		# Add target main output file.
		cpfListAppend(files $<TARGET_FILE:${binaryTarget}>)

		get_property( abiDumpTarget TARGET ${binaryTarget} PROPERTY CPF_ABI_DUMP_SUBTARGET )
		if(abiDumpTarget)
			# add target
			cpfListAppend(abiDumpTargets ${abiDumpTarget})
			# add dump file
			get_property( dumpFile TARGET ${abiDumpTarget} PROPERTY CPF_OUTPUT_FILES_${configSuffix} )
			cpfListAppend(files "${dumpFile}")

		endif()

	endforeach()

	set(contentTargets ${binaryTargets} ${abiDumpTargets})

	set(${contentProducerTargetsOut} "${contentTargets}" PARENT_SCOPE)
	set(${filesOut} "${files}" PARENT_SCOPE)

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
#
function( cpfGetInstalledFiles relativeDestinationFilesOut package config components )

	cpfToConfigSuffix(configSuffix ${config})

	set(files)
	foreach(component ${components})
		get_property(componentFiles TARGET ${package} PROPERTY CPF_INSTALLED_FILES_${component}_${configSuffix} )
		cpfListAppend(files ${componentFiles})
	endforeach()

	set(${relativeDestinationFilesOut} "${files}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetRunInstallScriptCommands runInstallScriptCommandsOut package config components destDir )

	set(scriptFile "${CMAKE_CURRENT_BINARY_DIR}/cmake_install.cmake")

	set(commands)
	foreach(component ${components})
		cpfListAppend( commands "${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=\"${destDir}\" -DCMAKE_INSTALL_COMPONENT=${component} -DCMAKE_INSTALL_CONFIG_NAME=${config} -P \"${scriptFile}\"" )
	endforeach()

	set( ${runInstallScriptCommandsOut} "${commands}" PARENT_SCOPE )

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
		cpfListAppend( configSuffixes ${configSuffix})

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

		get_property( contentStampFile TARGET ${contentTarget} PROPERTY CPF_STAMP_FILE_${configSuffix})
		cpfAddConfigurationDependendCommand(
            TARGET ${targetName}
			OUTPUT ${stampFile}			# we use a stamp-file here because we do not want to pollute the output directory with empty files. This should work because there are no consumers of the files.
            DEPENDS ${contentTarget} ${contentStampFile}
            COMMENT "Create distribution package ${packageFormat} for ${package}."
            CONFIG ${config}
            COMMANDS_CONFIG ${packagingCommand} ${copyToHtmlLastBuildCommand} ${copyToHtmlReleasesCommand} ${touchStampCommand}
			COMMANDS_NOT_CONFIG ${touchStampCommand}
        )

		cpfListAppend( allOutputFiles ${stampFile})

	endforeach()

	add_custom_target(
		${targetName}
		DEPENDS ${contentTarget} ${allOutputFiles}
	)

	set_property( TARGET ${package} APPEND PROPERTY CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	
	foreach( configSuffix ${configSuffixes})
		set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES_${configSuffix} ${destPackageFile${configSuffix}})
	endforeach()

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
	elseif( ${contentId} STREQUAL src )
		set( nameWE "${package}.${version}.${contentId}")
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
-D CPACK_PACKAGE_NAME=${package} \
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









