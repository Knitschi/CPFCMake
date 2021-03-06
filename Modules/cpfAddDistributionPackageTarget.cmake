include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfLocations)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddInstallTarget)




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
		
		# Sanity check for the options
		cpfIsInterfaceLibrary(isIntLib ${package})
		if(isIntLib AND (${contentType} STREQUAL CT_RUNTIME OR ${contentType} STREQUAL CT_RUNTIME_PORTABLE))
			message(FATAL_ERROR 
"The interface library ${package} can not have a distribution package with DISTRIBUTION_PACKAGE_CONTENT_TYPE ${contentType} because it has no binary files. \
Remove that distribution package configuration from the cpfAddCppPackage() call to fix the problem."
			)
		endif()
		
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

	cpfGetSubtargets(createPackagesTargets "${package}" INTERFACE_CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS)
	if(createPackagesTargets)
		
		cpfGetDistributionPackagesTargetName( targetName ${package})

		add_custom_target(
			${targetName}
			DEPENDS ${createPackagesTargets}
		)

		set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/pipeline")

	endif()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetDistributionPackagesTargetName targetNameOut package)
	set( ${targetNameOut} distributionPackages_${package} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetLastBuildPackagesDir dirOut package)
	cpfGetRelLastBuildPackagesDir( relPackageDir ${package})
	set( ${dirOut} "${CPF_PROJECT_HTML_ABS_DIR}/${relPackageDir}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddPackageContentTarget targetName package contentId contentType )

	cpfGetPackageContentStagingDir( destDir ${package} ${contentId})
	cpfGetPackageComponents( components ${contentType} ${contentId} )
	cpfAddInstallTarget( ${package} ${targetName} "${components}" ${destDir} TRUE ${package}/private)

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
# returns the "private" _packaging directory which is used while creating the distribution packages. 
function( cpfGetPackagingDir dirOut )
	# Note that the temp dir needs the contentid level to make sure that instances of cpack do not access the same _CPack_Packages directories, which causes errors.
	set( ${dirOut} "${CMAKE_CURRENT_BINARY_DIR}/${CPF_PACKAGES_ASSEMBLE_DIR}" PARENT_SCOPE) 
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageContentStagingDir stagingDirOut package contentId )
	cpfGetPackagingDir( baseDir)
	set( ${stagingDirOut} "${baseDir}/${contentId}/${package}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function adds target that creates a distribution package. The command specifies how this is done.
#
# Note that packages are created in a temporary directory and later copied to the "Packages" directory.
# This is done because cmake creates a temporary "_CPACK_Packages" directory which we do not want in our final Packages directory.
# Another reason is that the temporary package directory needs an additional directory level with the package content type to prevent simultaneous
# accesses of cpack to the "_CPACK_Packages" directory. The copy operation allows us to get rid of that extra level in the "Packages" directory.
function( cpfAddDistributionPackageTarget package contentTarget contentId contentType packageFormat formatOptions )

	# Only create debian packages if the dpkg tool is available
	if("${packageFormat}" STREQUAL DEB )
		find_program(dpkgTool dpkg DOC "The tool that helps with creating debian packages.")
		if( ${dpkgTool} STREQUAL dpkgTool-NOTFOUND )
			cpfDebugMessage("Skip creation of target for package format ${packageFormat} because of missing dpkg tool.")
			return()
		endif()
	endif()
	

	cpfGetDistributionPackageTargetName( targetName ${package} ${contentId} ${contentType} ${packageFormat})
	
	cpfIsInterfaceLibrary( isIntLib ${package})
	if(isIntLib)
		get_property( version TARGET ${package} PROPERTY INTERFACE_CPF_VERSION )
	else()
		get_property( version TARGET ${package} PROPERTY VERSION )
	endif()

	# locations / files
	cpfGetBasePackageFilename( basePackageFileName ${package} ${version} ${contentId} ${packageFormat})
	cpfGetDistributionPackageExtension( extension ${packageFormat})
	set( shortPackageFilename ${basePackageFileName}.${extension} )
	cpfGetCPackWorkingDir( packagesOutputDirTemp ${package} ${contentId})
	set(absPathPackageFile ${packagesOutputDirTemp}/${shortPackageFilename})

	# Setup and add the commands
	# Get the cpack command that creates the package file
	cpfGetPackagingCommand( packagingCommand ${package} ${version} ${contentId} ${contentType} ${packageFormat} ${packagesOutputDirTemp} ${basePackageFileName} "${formatOptions}")
	# Use a stamp-file because the package file name is config dependent.
	cpfGetTouchTargetStampCommand( touchCommmand stampFile ${targetName})

	get_property( contentStampFile TARGET ${contentTarget} PROPERTY CPF_OUTPUT_FILES)
	cpfAddStandardCustomCommand(
		DEPENDS ${contentTarget} ${contentStampFile}
		COMMANDS ${packagingCommand} ${touchCommmand}
		OUTPUT ${stampFile}
	)

	# Add the target and set its properties
	add_custom_target(
		${targetName}
		DEPENDS ${contentTarget} ${stampFile}
	)

	set_property( TARGET ${package} APPEND PROPERTY INTERFACE_CPF_PACKAGE_SUBTARGETS ${targetName})
	set_property( TARGET ${package} APPEND PROPERTY INTERFACE_CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS ${targetName})
	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private")
	set_property( TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES ${stampFile})
	set_property( TARGET ${targetName} PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS distributionPackages)

	# Add an install rule for the created package file.
	cpfGetRelativeOutputDir( relDistPackageFilesDir ${package} DISTRIBUTION_PACKAGE_FILES)
	install(
		FILES ${absPathPackageFile}
		DESTINATION ${relDistPackageFilesDir}
		COMPONENT distributionPackages
		EXCLUDE_FROM_ALL	# This has a custom target dependency so we can not include it in the default install target.
	)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetCPackWorkingDir dirOut package contentId )
		
	cpfGetPackagingDir( baseDir )
	set( ${dirOut} "${baseDir}/$<CONFIG>/${contentId}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# nameWEOut short filename without the extension
function( cpfGetBasePackageFilename nameWEOut package version contentId packageFormat )
	
	if( ${packageFormat} STREQUAL DEB)
        
        cpfFindRequiredProgram( TOOL_DPKG dpkg "The debian package manager." "")

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
        set( nameWE "${package}.${version}.${CMAKE_SYSTEM_NAME}.${contentId}.$<CONFIG>")
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
-D CPACK_PACKAGE_DESCRIPTION=\"${CPF_PACKAGE_DESCRIPTION}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
${configOption} \
-P ${package} \
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

	get_property( description TARGET ${package} PROPERTY INTERFACE_CPF_BRIEF_PACKAGE_DESCRIPTION )
	get_property( homepage TARGET ${package} PROPERTY INTERFACE_CPF_PACKAGE_WEBPAGE_URL )
	get_property( maintainer TARGET ${package} PROPERTY INTERFACE_CPF_PACKAGE_MAINTAINER_EMAIL )
	
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
-D CPACK_PACKAGE_DESCRIPTION=\"${CPF_PACKAGE_DESCRIPTION}\" \
-D CPACK_PACKAGE_DIRECTORY=\"${packageOutputDir}\" \
-D CPACK_PACKAGE_CONTACT=\"${maintainer}\" \
-D CPACK_DEBIAN_FILE_NAME=DEB-DEFAULT \
-D CPACK_DEBIAN_PACKAGE_DEPENDS=\"${ARG_SYSTEM_PACKAGES_DEB}\" \
-D CPACK_DEBIAN_PACKAGE_DESCRIPTION=\"${description}\" \
-D CPACK_DEBIAN_PACKAGE_HOMEPAGE=\"${homepage}\" \
${configOption} \
-P ${package} \
")
	set( ${commandOut} ${command} PARENT_SCOPE)

endfunction()









