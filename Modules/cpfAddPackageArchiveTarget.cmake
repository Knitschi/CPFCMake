include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddInstallTarget)




#----------------------------------------------------------------------------------------
# Adds a global target that makes sure that all the per package-component createArchivePackage targets are build.
#
function( cpfAddGlobalCreatePackagesTarget packageComponents)

    set(targetName packageArchives)
	
	set(packageTargets)
	foreach(packageComponent ${packageComponents})
		cpfGetPackageArchivesTargetName( packageTarget ${packageComponent})
		if(TARGET ${packageTarget}) # not all packages may create package archives
			cpfListAppend( packageTargets ${packageTarget})
		endif()
	endforeach()
	
	cpfAddBundleTarget( ${targetName} "${packageTargets}" )

endfunction()

#----------------------------------------------------------------------------------------
# For argument documentation see the cpfAddCppPackageComponent() function.
#
function( cpfAddPackageArchiveTargets package packageOptionLists )

	set(packageArchiveTargets)
	foreach( list ${packageOptionLists})

		cpfParseDistributionPackageOptions( contentType packageFormats distributionPackageFormatOptions excludedTargets "${${list}}")

		# First we create targets for each component that assemble the content of the desired contentType.
		# We have extra targets for this so we can create multiple packages with the same content.
		cpfGetDistributionPackageContentId(contentId ${contentType} "${excludedTargets}")

		set(copyComponentContentTargets)
		cpfGetPackageComponents(packageComponents ${package})
		foreach(packageComponent ${packageComponents})

			cpfGetCollectPackageContentTargetNameAnId(packageContentTarget ${packageComponent} ${contentType} ${contentId} "${excludedTargets}")
			if(NOT TARGET ${packageContentTarget})
				cpfAddCopyPackageContentTarget( ${packageContentTarget} ${packageComponent} ${contentId} ${contentType} )
				cpfListAppend(copyComponentContentTargets ${packageContentTarget})
			endif()

		endforeach()

		# Create the targets that create the archives.
		foreach(packageFormat ${packageFormats})
			cpfAddPackageArchiveTarget(distributionPackageTarget ${package} "${copyComponentContentTargets}" ${contentId} ${contentType} ${packageFormat} "${distributionPackageFormatOptions}")
			cpfListAppend(packageArchiveTargets ${distributionPackageTarget})
		endforeach()

	endforeach()

	# Create one target to knot up all package archive targets for the package.
	cpfAddPackageArchivesTarget(${package} "${packageArchiveTargets}")

endfunction()

#----------------------------------------------------------------------------------------
# This function defines the names of the package-component sub-targets that occur in a CMakeProjectFramework project.
# The contentIdOut is a shorter string that can be used in output names to identifiy the content type.
#
function( cpfGetCollectPackageContentTargetNameAnId targetNameOut packageComponent contentType contentId excludedTargets )
	set(${targetNameOut} pkgContent_${contentId}_${packageComponent} PARENT_SCOPE )
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageArchiveTargetName targetNameOut packageComponent contentId contentType packageFormat )
	set( ${targetNameOut} pckgArchive_${contentId}_${packageFormat}_${packageComponent} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Add a target that bundles all the individual package archive targets of the package together.
# The target also makes sure that old packages in LastBuild are deleted. 
#
function( cpfAddPackageArchivesTarget package packageArchiveTargets)

	if(packageArchiveTargets)
		
		cpfGetPackageArchivesTargetName( targetName ${package})

		add_custom_target(
			${targetName}
			DEPENDS ${packageArchiveTargets}
		)

		set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")

	endif()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageArchivesTargetName targetNameOut packageComponent)
	set( ${targetNameOut} packageArchives_${packageComponent} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetLastBuildPackagesDir dirOut packageComponent)
	cpfGetRelLastBuildPackagesDir( relPackageDir ${packageComponent})
	set( ${dirOut} "${CPF_PROJECT_HTML_ABS_DIR}/${relPackageDir}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddCopyPackageContentTarget targetName packageComponent contentId contentType )

	cpfGetPackageContentStagingDir( destDir ${packageComponent} ${contentId})
	cpfGetPackageInstallComponents( components ${contentType} ${contentId} )
	cpfGetComponentVSFolder(packageFolder ${CPF_CURRENT_PACKAGE} ${packageComponent})
	cpfAddInstallTarget( ${packageComponent} ${targetName} "${components}" ${destDir} TRUE ${packageFolder}/private)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list of components that belong to a contentType.
#
function( cpfGetPackageInstallComponents componentsOut contentType contentId )

	set(components)
	if( "${contentType}" STREQUAL CT_RUNTIME )
		set(components runtime)
	elseif( "${contentType}" STREQUAL CT_RUNTIME_PORTABLE )
		set(components runtime ${contentId} )
	elseif( "${contentType}" STREQUAL CT_DEVELOPER )
		set(components runtime developer )
	elseif( "${contentType}" STREQUAL CT_SOURCES )
		set(components sources)
	elseif( "${contentType}" STREQUAL CT_DOCUMENTATION )
		set(components documentation)
	else()
		message(FATAL_ERROR "Function cpfAddCopyPackageContentTarget() does not support contentType \"${contentType}\"")
	endif()

	set(${componentsOut} "${components}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# returns the "private" _packaging directory which is used while creating the package archives. 
function( cpfGetPackagingDir dirOut )
	# Note that the temp dir needs the contentid level to make sure that instances of cpack do not access the same _CPack_Packages directories, which causes errors.
	set( ${dirOut} "${CMAKE_CURRENT_BINARY_DIR}/${CPF_PACKAGES_ASSEMBLE_DIR}" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageContentStagingDir stagingDirOut packageComponent contentId )
	cpfGetPackagingDir( baseDir)
	set( ${stagingDirOut} "${baseDir}/${contentId}/${packageComponent}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function adds target that creates a package archive. The command specifies how this is done.
#
# Note that packages are created in a temporary directory and later copied to the "Packages" directory.
# This is done because cmake creates a temporary "_CPACK_Packages" directory which we do not want in our final Packages directory.
# Another reason is that the temporary package directory needs an additional directory level with the package content type to prevent simultaneous
# accesses of cpack to the "_CPACK_Packages" directory. The copy operation allows us to get rid of that extra level in the "Packages" directory.
function( cpfAddPackageArchiveTarget packageArchiveTargetNameOut package contentTargets contentId contentType packageFormat formatOptions )

	# Only create debian packages if the dpkg tool is available
	if("${packageFormat}" STREQUAL DEB )
		find_program(dpkgTool dpkg DOC "The tool that helps with creating debian packages.")
		if( ${dpkgTool} STREQUAL dpkgTool-NOTFOUND )
			cpfDebugMessage("Skip creation of target for package format ${packageFormat} because of missing dpkg tool.")
			return()
		endif()
	endif()

	cpfGetPackageArchiveTargetName( targetName ${package} ${contentId} ${contentType} ${packageFormat})
	set(version ${PROJECT_VERSION})


	# locations / files
	cpfGetBasePackageFilename( basePackageFileName ${package} ${version} ${contentId} ${packageFormat})
	cpfGetPackageArchiveExtension( extension ${packageFormat})
	set( shortPackageFilename ${basePackageFileName}.${extension} )
	cpfGetCPackWorkingDir( packagesOutputDirTemp ${package} ${contentId})
	set(absPathPackageFile ${packagesOutputDirTemp}/${shortPackageFilename})

	# Setup and add the commands
	# Get the cpack command that creates the package-component file
	cpfGetPackagingCommand( packagingCommand ${package} ${version} ${contentId} ${contentType} ${packageFormat} ${packagesOutputDirTemp} ${basePackageFileName} "${formatOptions}")
	# Use a stamp-file because the package file name is config dependent.
	cpfGetTouchTargetStampCommand( touchCommmand stampFile ${targetName})

	set(contentStampFiles)
	foreach(contentTarget ${contentTargets})
		get_property(contentStampFile TARGET ${contentTarget} PROPERTY CPF_OUTPUT_FILES)
		cpfListAppend(contentStampFiles ${contentStampFile})
	endforeach()
	
	cpfAddStandardCustomCommand(
		DEPENDS ${contentTargets} ${contentStampFiles}
		COMMANDS ${packagingCommand} ${touchCommmand}
		OUTPUT ${stampFile}
	)

	# Add the target and set its properties
	add_custom_target(
		${targetName}
		DEPENDS ${contentTargets} ${stampFile}
	)

	set_property( TARGET ${package} APPEND PROPERTY INTERFACE_CPF_PACKAGE_COMPONENT_SUBTARGETS ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	set_property( TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES ${stampFile})
	set_property( TARGET ${targetName} PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS packageArchives)

	# Add an install rule for the created package file.
	cpfGetRelativeOutputDir( relPackageArchiveFilesDir ${package} DISTRIBUTION_PACKAGE_FILES)
	install(
		FILES ${absPathPackageFile}
		DESTINATION ${relPackageArchiveFilesDir}
		COMPONENT packageArchives
		EXCLUDE_FROM_ALL	# This has a custom target dependency so we can not include it in the default install target.
	)

	set(${packageArchiveTargetNameOut} ${targetName} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetCPackWorkingDir dirOut packageComponent contentId )
		
	cpfGetPackagingDir( baseDir )
	set( ${dirOut} "${baseDir}/$<CONFIG>/${contentId}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# nameWEOut short filename without the extension
function( cpfGetBasePackageFilename nameWEOut packageComponent version contentId packageFormat )
	
	if( ${packageFormat} STREQUAL DEB)
        
        cpfFindRequiredProgram( TOOL_DPKG dpkg "The debian package manager." "")

        # Debian packages need to follow a certain naming scheme.
        # Note that the filename of the created package is not influenced by what is returned here.
        # This mimic the filename of the package to get the dependencies of the custom commands right.
        string( TOLOWER ${packageComponent} lowerPackage )
        
        # We need the architecture name
        # Assume that the host and target system are the same
        if( NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "${CMAKE_HOST_SYSTEM_NAME}")
            message( FATAL_ERROR "Function cpfGetBasePackageFilename() was written with the assumption that CMAKE_SYSTEM_NAME and CMAKE_HOST_SYSTEM_NAME are the same.")
        endif()
        cpfExecuteProcess( architecture "\"${TOOL_DPKG}\" --print-architecture" "${CPF_ROOT_DIR}")
        
        set( nameWE "${lowerPackage}_${version}_${architecture}")
	elseif( ${contentId} STREQUAL src )
		set( nameWE "${packageComponent}.${version}.${contentId}")
	else()
        set( nameWE "${packageComponent}.${version}.${CMAKE_SYSTEM_NAME}.${contentId}.$<CONFIG>")
    endif()
    
    set(${nameWEOut} ${nameWE} PARENT_SCOPE)
    
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackagingCommand commandOut package version contentId contentType packageFormat packageOutputDir baseFileName formatOptions )

	cpfIsArchiveFormat( isArchiveGenerator ${packageFormat} )
	if( isArchiveGenerator  )
		cpfGetArchivePackageCommand( command ${package} ${version} ${contentId} ${contentType} ${packageFormat} ${packageOutputDir} ${baseFileName} )
	elseif( "${packageFormat}" STREQUAL DEB )
		cpfGetDebianPackageCommand( command ${package} ${version} ${contentId} ${contentType} ${packageFormat} ${packageOutputDir} ${baseFileName} "${formatOptions}" )
	else()
		message(FATAL_ERROR "Package format \"${packageFormat}\" is not supported by function cpfGetPackagingCommand()")
	endif()

	set( ${commandOut} ${command} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# This function creates a cpack command that creates one of the compressed archive packages
# 
function( cpfGetArchivePackageCommand commandOut package version contentId contentType packageFormat packageOutputDir baseFileName )

	cpfGetPackageContentStagingDir( packageContentDir ${package} ${contentId})

	set(configOption)
	if(NOT (${contentId} STREQUAL src))
		set(configOption "-C $<CONFIG>")
	endif()

	# Setup the cpack command for creating the package
	set( command
"cpack -G \"${packageFormat}\" \
-D CPACK_PACKAGE_NAME=${package} \
-D CPACK_PACKAGE_VERSION=${version} \
-D CPACK_INSTALLED_DIRECTORIES=\"${packageContentDir}\"$<SEMICOLON>. \
-D CPACK_PACKAGE_FILE_NAME=\"${baseFileName}\" \
-D CPACK_PACKAGE_DESCRIPTION=\"${${package}_BRIEF_DESCRIPTION}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
${configOption} \
-P ${packaget} \
")
	set( ${commandOut} ${command} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# This function creates a cpack command that creates debian package .dpkg 
# 
function( cpfGetDebianPackageCommand commandOut package version contentId contentType packageFormat packageOutputDir baseFileName formatOptions )

	cmake_parse_arguments(
		ARG
		""
		""
		"SYSTEM_PACKAGES_DEB"
		"${formatOptions}"
	)

	cpfGetPackageContentStagingDir( packageContentDir ${package} ${contentId})
	
	# todo get string for package dependencies
	# example "libc6 (>= 2.3.1-6), libc6 (< 2.4)"
	# todo package description durchschl�usen

	set( briefDescription ${${package}_BRIEF_DESCRIPTION})
	set( longDescription ${${package}_LONG_DESCRIPTION})
	set( homepage ${${package}_WEBPAGE_URL})
	set( maintainerMail ${${package}_MAINTAINER_EMAIL})
	
	set(configOption)
	if(NOT (${contentId} STREQUAL src))
		set(configOption "-C $<CONFIG>")
	endif()


	# Setup the cpack command for creating the package
	set( command
"cpack -G \"${packageFormat}\" \
-D CPACK_PACKAGE_NAME=${package} \
-D CPACK_PACKAGE_VERSION=${version} \
-D CPACK_INSTALLED_DIRECTORIES=\"${packageContentDir}\"$<SEMICOLON>. \
-D CPACK_PACKAGE_FILE_NAME=\"${baseFileName}\" \
-D CPACK_PACKAGE_DESCRIPTION=\"${briefDescription}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
-D CPACK_PACKAGE_CONTACT=\"${maintainerMail}\" \
-D CPACK_DEBIAN_FILE_NAME=DEB-DEFAULT \
-D CPACK_DEBIAN_PACKAGE_DEPENDS=\"${ARG_SYSTEM_PACKAGES_DEB}\" \
-D CPACK_DEBIAN_PACKAGE_DESCRIPTION=\"${longDescription}\" \
-D CPACK_DEBIAN_PACKAGE_HOMEPAGE=\"${homepage}\" \
${configOption} \
-P ${package} \
")
	set( ${commandOut} ${command} PARENT_SCOPE)

endfunction()









