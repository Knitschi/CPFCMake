include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfProjectUtilities)
include(cpfGitUtilities)
include(cpfLocations)
include(cpfAddInstallTarget)
include(cpfVersionUtilities)

 
# This file contains functions that the targets that are used to implement the ABI and API compatibility checks.


#----------------------------------------------------------------------------------------
# Adds a bundle target, that can be used to run the abi-compliance-check targets for all packages. 
function( cpfAddGlobalAbiCheckerTarget packages )
	
	set(targets)
	foreach(package ${packages})
		cpfGetPackageComponents(components ${package})
		foreach(component ${components})
			cpfGetPackageVersionCompatibilityCheckTarget(target ${component})
			if(TARGET ${target})
				cpfListAppend(targets ${target})
			endif()
		endforeach()
	endforeach()

	if(targets)

		cpfGetAbiComplianceCheckerBundleTargetBaseName(baseTargetName)
		set(targetName ${baseTargetNam}_${package})
		if(NOT (TARGET ${targetName}))
			cpfAddBundleTarget(${targetName} "${targets}")
			set_property(TARGET ${targetName} PROPERTY FOLDER  ${package}/package)
		endif()
		add_dependencies(pipeline_${package} ${targetName})

	endif()

endfunction()

#----------------------------------------------------------------------------------------
function(cpfAddPackageAbiCheckerTarget package )
	
	set(targets)

	cpfGetPackageVersionCompatibilityCheckTarget( target ${package})
	if(TARGET ${target})
		cpfListAppend( targets ${target})
	endif()

	cpfGetAbiComplianceCheckerBundleTargetBaseName(targetName)
	cpfAddBundleTarget( ${targetName} "${targets}")
	if(TARGET ${targetName})
	    set_property(TARGET ${targetName} PROPERTY FOLDER  ${package}/package)
        add_dependencies(pipeline_${package} ${targetName})
	endif()
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageVersionCompatibilityCheckTarget targetNameOut packageComponent )
	cpfGetAbiComplianceCheckerBundleTargetBaseName(targetName)
	set( ${targetNameOut} ${targetName}_${packageComponent} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetAbiComplianceCheckerBundleTargetBaseName baseNameOut )
	set(${baseNameOut} abi-compliance-checker PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function adds custom targets which call the abi-compliance-checker tool.
function( cpfAddAbiCheckerTargets packageComponent packageArchiveOptionLists enableCompatibilityReportTargets enableStabilityCheckTargets )
	
	cpfAssertUserSettingsForCompatibilityChecksMakeSense( 
		${packageComponent}
		"${packageArchiveOptionLists}"
		${enableCompatibilityReportTargets}
		${enableStabilityCheckTargets} 
	)
	
	if( enableCompatibilityReportTargets )

		cpfGetLastBuildAndLastReleaseVersion( lastBuildVersion lastReleaseVersion)
		cpfHasDevBinDistributionPackage( unused packageFormat "${packageArchiveOptionLists}" )
		cpfDownloadOldAbiDumps( ${packageComponent} ${packageFormat} ${lastBuildVersion} ${lastReleaseVersion} )
		
		# Add The targets that create and use the abi-dumps.
		cpfGetSharedLibrarySubTargets( libraryTargets ${packageComponent})
		foreach( libraryTarget ${libraryTargets})
			
			cpfWritePublicHeaderListFile( headerListFile ${packageComponent} ${libraryTarget})

			cpfAddAbiDumpTarget( ${packageComponent} ${libraryTarget} ${headerListFile} )
			set( comparedToVersions ${lastBuildVersion} ${lastReleaseVersion} )
			list(REMOVE_DUPLICATES comparedToVersions) # this is required for the case when lastBuild == lastRelease
			cpfAddCompatibilityReportTargets( reportFiles ${packageComponent} ${libraryTarget} ${packageFormat} "${comparedToVersions}" )
			
			# Add the abi-compliance-checker targets that enforce the compatibility when the configuration options are set.
			if(enableStabilityCheckTargets)
				cpfAddApiCompatibilityCheckTarget( reportFileApiCheck ${packageComponent} ${libraryTarget} ${packageFormat} ${lastReleaseVersion})
				cpfAddAbiCompatibilityCheckTarget( reportFileAbiCheck ${packageComponent} ${libraryTarget} ${packageFormat} ${lastReleaseVersion})
			endif()

		endforeach()

		# Add a target to bundle all abi check targets of one packageComponent into one and to remove old reports.
		cpfGetPackageVersionCompatibilityCheckTarget( targetName ${packageComponent})
		cpfAddCleanOutputDirsCommands( cleanStamps ${targetName} "${reportFiles};${reportFileApiCheck};${reportFileAbiCheck}" )
		cpfAddPackageComponentsSubTargetBundleTarget( ${targetName} ${packageComponent} INTERFACE_CPF_ABI_CHECK_SUBTARGETS "${cleanStamps}")

		# Add install rules
		cpfAddInstallRuleForAbiDumpFiles(${packageComponent})

	endif()
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAssertUserSettingsForCompatibilityChecksMakeSense packageComponent packageArchiveOptionLists enableCompatibilityReportTargets enableStabilityCheckTargets )

	# If user requests compatibility checks, the compiler settings must support it. 
	if(enableCompatibilityReportTargets)
		cpfCompileSettingsSupportAbiDumper( abiDumperSupported )
		if(NOT abiDumperSupported )
			set(errorMessage "\
Error with C++ package settings!\n\
Option [CPF_]ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS was set to ON while the compiler settings do not support the abi-dumper tool. \
This option can only be enabled when using \"g++ -g -Og\" or \"clang -g -O0\" compiler settings.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# check the tools are available
		cpfFindRequiredProgram( TOOL_ABI_DUMPER abi-dumper "A tool that creates abi dump files from shared libraries." "")
		cpfFindRequiredProgram( TOOL_ABI_COMPLIANCE_CHECKER abi-compliance-checker "A tool that compares two abi dump files and checks whether the ABIs are compliant." "")
		cpfFindRequiredProgram( TOOL_VTABLE_DUMPER vtable-dumper "A tool required by the abi-dumper tool" "")

		# check that previous builds have been made available through the webpage
		if( NOT CPF_WEBSERVER_BASE_DIR )
			set(errorMessage "\
Error with C++ package settings!\n\
Option [CPF_]ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS was set to ON but variable CPF_WEBSERVER_BASE_DIR was not set. \
In order to check the compliance with previously released packages, the script must be able to download previous build results from the web-page.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# currently we the abi-compliance-checker tool needs shared libs
		if( NOT BUILD_SHARED_LIBS )
			set(errorMessage "\
Error with C++ package settings!\n\
Option [CPF_]ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS was set to ON but variable BUILD_SHARED_LIBS was not set to TRUE. \
The compatibility check targets currently only work for shared libraries.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# Currently we need the version information from the repository in order to download
		# the correct previous versions. 
		cpfIsGitRepositoryDir( isRepoDirOut "${CMAKE_CURRENT_SOURCE_DIR}")
		if(NOT isRepoDirOut)
			set(errorMessage "\
Error with C++ package settings!\n\
Option [CPF_]ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS was set to ON but the sources were not retrieved by cloning the Git repository. \
The compatibility check targets require the version information from to repository in order to download previously build versions.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# Make sure that the package has a dev-bin package archive which holds the dump file.
		cpfHasDevBinDistributionPackage( hasDevBinPackage unused "${packageArchiveOptionLists}")
		if(NOT hasDevBinPackage)
			set(errorMessage "\
Error with project settings!\n\
Option [CPF_]ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS was set to ON but package ${packageComponent} does not create a package archive with content type CT_DEVELOPER. \
The packages with content type CT_DEVELOPER contain the abi dump files for previously build libraries which are needed to compare the abi-compliance. \
You need to add an PACKAGE_ARCHIVES to your call of cpfAddCppPackageComponent() with the PACKAGE_ARCHIVE_CONTENT_TYPE CT_DEVELOPER sub-option to remove this error.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
	endif()
	
	# enableStabilityCheckTargets requires enableCompatibilityReportTargets option.
	if( enableStabilityCheckTargets )
		if( NOT enableCompatibilityReportTargets )
			set(errorMessage "\
Error with project settings!\n\
The activation of the [CPF_]ENABLE_ABI_API_STABILITY_CHECK_TARGETS option requires the activation of the [CPF_]ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS option.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Note that the abi-dumper prefers the -Og flag over the -O0 flag, but it is only available
# for Gcc
function( cpfCompileSettingsSupportAbiDumper boolOut )

	set(isSupported FALSE)
	
	if(CMAKE_BUILD_TYPE) # we only support single configuration build tools for now
		cpfGetCompiler( compiler)
		cpfGetCxxFlags( compileFlags ${CMAKE_BUILD_TYPE})
		cpfContains( hasGFlag "${compileFlags}" "-g")
		cpfContains( hasO0Flag "${compileFlags}" "-O0")
		cpfContains( hasOgFlag "${compileFlags}" "-Og")
		if( ${compiler} STREQUAL Clang AND hasGFlag AND hasO0Flag )
			set(isSupported TRUE)
		elseif( ${compiler} STREQUAL Gcc AND hasGFlag AND hasOgFlag )
			set(isSupported TRUE)
		endif()
	else()
		message(FATAL_ERROR "Currently cpfAddAbiDumpTarget() is only supported for single configuration generators.")
	endif()

	set( ${boolOut} ${isSupported} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfHasDevBinDistributionPackage hasDevBinPackageOut packageFormatOut packageArchiveOptionLists )

	foreach( list ${packageArchiveOptionLists})
	
		cpfParseDistributionPackageOptions( contentType packageFormats unused unused "${${list}}")
		
		if( ${contentType} STREQUAL CT_DEVELOPER )
			set( ${hasDevBinPackageOut} TRUE PARENT_SCOPE)
			
			foreach( format ${packageFormats})
				cpfIsArchiveFormat( isArchive ${format})
				if(isArchive)
					set( ${packageFormatOut} ${format} PARENT_SCOPE )
					return()
				endif()
			endforeach()
		endif()
	endforeach()
	
	set( ${hasDevBinPackageOut} FALSE PARENT_SCOPE)
	set( ${packageFormatOut} PARENT_SCOPE )
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfIsArchiveFormat isArchiveFormatOut packageFormat )
	cpfGetArchiveFormats(archiveGenerators)
	cpfContains( isArchiveGenerator "${archiveGenerators}" ${packageFormat})
	set( ${isArchiveFormatOut} ${isArchiveGenerator} PARENT_SCOPE )
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetArchiveFormats archiveFormatsOut )
	set( ${archiveFormatsOut} 7Z TBZ2 TGZ TXZ TZ ZIP PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfDownloadOldAbiDumps packageComponent packageFormat lastBuildVersion lastReleaseVersion )
	
	# get url of LastBuild package	
	cpfIsReleaseVersion( lastBuildIsRelease ${lastBuildVersion} )
	if(NOT lastBuildIsRelease)
		cpfGetShortDevBinPackageName( packageLastBuild ${packageComponent} ${CMAKE_BUILD_TYPE} ${lastBuildVersion} ${packageFormat} )
		cpfGetRelLastBuildPackagesDir( lastBuildPackageDir ${packageComponent})
		set( urlLastBuild "${CPF_WEBSERVER_BASE_DIR}/${lastBuildPackageDir}/${packageLastBuild}")
		cpfDownloadAndExtractPackage( ${packageComponent} ${packageFormat} ${urlLastBuild})
	endif()

	# get url of last release package
	cpfGetShortDevBinPackageName( packageLastRelease ${packageComponent} ${CMAKE_BUILD_TYPE} ${lastReleaseVersion} ${packageFormat} )
	cpfGetRelReleasePackagesDir( releasePackageDir ${packageComponent} ${lastReleaseVersion})
	set( urlLastRelease "${CPF_WEBSERVER_BASE_DIR}/${releasePackageDir}/${packageLastRelease}")
	cpfDownloadAndExtractPackage( ${packageComponent} ${packageFormat} ${urlLastRelease})

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetShortDevBinPackageName shortNameOut packageComponent config version packageFormat )

	cpfGetDistributionPackageContentId( contentId CT_DEVELOPER "")
	cpfGetBasePackageFilename( basePackageFileName ${packageComponent} ${config} ${version} ${contentId} ${packageFormat})
	cpfGetPackageArchiveExtension( extension ${packageFormat})
	set( ${shortNameOut} ${basePackageFileName}.${extension} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetPackageArchiveExtension extensionOut packageFormat )

	if( "${packageFormat}" STREQUAL 7Z )
		set(extensionLocal 7z)
	elseif( "${packageFormat}" STREQUAL TBZ2  )
		set(extensionLocal tar.bz2)
	elseif( "${packageFormat}" STREQUAL TGZ )
		set(extensionLocal tar.gz)
	elseif( "${packageFormat}" STREQUAL TXZ )
		set(extensionLocal tar.xz)
	elseif( "${packageFormat}" STREQUAL TZ )
		set(extensionLocal tar.Z)
	elseif( "${packageFormat}" STREQUAL ZIP )
		set(extensionLocal zip)
	elseif( "${packageFormat}" STREQUAL DEB )
		set(extensionLocal deb)
	else()
		message(FATAL_ERROR "Package format \"${packageFormat}\" is not supported by function cpfGetPackageArchiveExtension().")
	endif()

	set(${extensionOut} ${extensionLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfDownloadAndExtractPackage packageComponent packageFormat packageUrl  )

	# downlaod the package
	get_filename_component( shortName "${packageUrl}" NAME )
	getPreviousPackageDownloadDirectory(downloadDir)
	set( downloadedPackage "${downloadDir}/${shortName}")
	cpfDebugMessage("Download package from \"${packageUrl}\"")
	file(DOWNLOAD "${packageUrl}" "${downloadedPackage}" INACTIVITY_TIMEOUT 1 STATUS resultValues )

	list(GET resultValues 0 returnCode )
	if( NOT ${returnCode} EQUAL 0)
		# We only issue a warning here to not break builds when the package-components are not available.
		# This can happen when the variable CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS has been switched ON, or parts of the build have
		# been disabled during maintanance.
		message( "Warning: Could not download released package archive from ${packageUrl}. Comparing the current ABI/API with that package will not be possible.")
 	else()
		# extract the package
		cpfExecuteProcess( unused "cmake -E tar x ${shortName}" "${downloadDir}" DONT_INTERCEPT_OUTPUT )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
function( getPreviousPackageDownloadDirectory dirOut )
	set(${dirOut} ${CMAKE_CURRENT_BINARY_DIR}/PreviousPackages PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# 
function( cpfWritePublicHeaderListFile headerListFileOut packageComponent target )

	cpfGetAbiDumpTargetName( abiDumpTarget ${target})
	set(headerListFile "${CMAKE_BINARY_DIR}/${packageComponent}/${abiDumpTarget}/PublicHeaderList.txt")
	
	get_property( publicHeader TARGET ${target} PROPERTY INTERFACE_CPF_PUBLIC_HEADER )
	set(fileContent)
	foreach( header ${publicHeader} )
		cpfToAbsSourcePath( header ${header} ${CMAKE_CURRENT_SOURCE_DIR})
		string(APPEND fileContent "${header}\n")
	endforeach()
	
	file(WRITE ${headerListFile} ${fileContent})
	
	set(${headerListFileOut} ${headerListFile} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Defines the name of the abi-dump target
function( cpfGetAbiDumpTargetName targetNameOut binaryTarget )
	set(${targetNameOut} abiDump_${binaryTarget} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function adds a target that creates an ABI dump file with the abi-dumper tool.
# The target will only be available when using "g++ -g -Og" or "clang -g -O0" because the
# tool requires DWARF debug information.
# 
function( cpfAddAbiDumpTarget packageComponent binaryTarget headerListFile )

	cpfGetAbiDumpTargetName( targetName ${binaryTarget})
	
	# Locations
	cpfGetAbsPathOfTargetOutputFile( targetBinaryFile ${binaryTarget} ${CMAKE_BUILD_TYPE} )
	cpfGetCurrentDumpFile( abiDumpFile ${packageComponent} ${binaryTarget})
	
	# Setup the command
	get_property( version TARGET ${binaryTarget} PROPERTY VERSION)
	set( abiDumperCommand "\"${TOOL_ABI_DUMPER}\" \"${targetBinaryFile}\" -lver ${version} -o \"${abiDumpFile}\" -public-headers \"${headerListFile}\"" )
	cpfAddStandardCustomCommand(
		OUTPUT ${abiDumpFile}
		DEPENDS ${binaryTarget}
		COMMANDS ${abiDumperCommand}
	)

	# add target
	add_custom_target(
		${targetName}
		ALL										# We have to add this to ALL to make sure it is build before the global install target.
		DEPENDS ${binaryTarget} ${abiDumpFile}
	)
	
	# Set target properties
	set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES ${abiDumpFile} )
	set_property(TARGET ${targetName} PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS developer )
	set_property(TARGET ${binaryTarget} PROPERTY INTERFACE_CPF_ABI_DUMP_SUBTARGET ${targetName} )
	set_property(TARGET ${packageComponent} APPEND PROPERTY INTERFACE_CPF_PACKAGE_COMPONENT_SUBTARGETS ${targetName} )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAddInstallRuleForAbiDumpFiles packageComponent )

	set(installedPackageFiles)

	# get files from abiDump targets
	get_property( binaryTargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS )
	foreach(binaryTarget ${binaryTargets})
		get_property( abiDumpTarget TARGET ${binaryTarget} PROPERTY INTERFACE_CPF_ABI_DUMP_SUBTARGET )
		if(abiDumpTarget)

			cpfGetCurrentDumpFile( dumpFile ${packageComponent} ${binaryTarget})
			get_filename_component( shortDumpFile "${dumpFile}" NAME )
			cpfGetRelativeOutputDir( relDumpFileDir ${packageComponent} OTHER)

			install(
				FILES ${dumpFile}
				DESTINATION "${relDumpFileDir}"
				COMPONENT developer
			)

			cpfListAppend( installedPackageFiles "${relDumpFileDir}/${shortDumpFile}" )

		endif()
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetCurrentDumpFile dumpFileOut packageComponent binaryTarget )
	get_property( currentVersion TARGET ${binaryTarget} PROPERTY VERSION )
	cpfGetAbiDumpTargetName( abiDumpTarget ${binaryTarget})
	cpfGetAbiDumpFileName( dumpFile ${binaryTarget} ${currentVersion})
	set( ${dumpFileOut} "${CMAKE_BINARY_DIR}/${packageComponent}/${abiDumpTarget}/${dumpFile}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetAbiDumpFileName shortNameOut binaryTarget version )
	cpfToConfigSuffix( configSuffix ${CMAKE_BUILD_TYPE} )
	set( ${shortNameOut} ABI_${binaryTarget}${CMAKE_${configSuffix}_POSTFIX}.${version}.dump PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetDumpFilePathRelativeToPackageDir pathOut packageComponent binaryTarget )
	get_property( version TARGET ${binaryTarget} PROPERTY VERSION )
	cpfGetAbiDumpFileName( dumpFile ${binaryTarget} ${version})
	cpfGetRelativeOutputDir( relativeDir ${packageComponent} OTHER )
	set( ${pathOut} ${relativeDir}/${dumpFile} PARENT_SCOPE)
endfunction()


#----------------------------------------------------------------------------------------
# Adds targets that create api-compliance-checker compatibilty reports for the given binaryTarget
# comparing the current version to each version in comparedToVersion. 
function( cpfAddCompatibilityReportTargets reportFilesOut packageComponent binaryTarget packageFormat comparedToVersions )
	
	get_property( version TARGET ${binaryTarget} PROPERTY VERSION)
	cpfGetReportBaseNamesAndOutputDirs( reportOutputDirs reportBaseNames ${packageComponent} ${binaryTarget} ${version} "${comparedToVersions}")
	
	set(index 0)
	set(reportFiles)
	foreach( comparedToVersion ${comparedToVersions})
		list(GET reportOutputDirs ${index} reportOutputDir)
		list(GET reportBaseNames ${index} reportBaseName)
		cpfIncrement(index)
		cpfAddAbiComplianceCheckerTarget( reportFile ${packageComponent} ${binaryTarget} ${packageFormat} ${comparedToVersion} ${reportBaseName} "${CPF_PROJECT_HTML_ABS_DIR}/${reportOutputDir}" NONE)
		cpfListAppend( reportFiles ${reportFile})
	endforeach()
	
	set(${reportFilesOut} ${reportFiles} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetReportBaseNamesAndOutputDirs reportDirsOut reportBaseNamesOut packageComponent binaryTarget newVersion comparedToVersions )

	cpfIsReleaseVersion( newVersionIsRelease ${newVersion})
	
	set(reportOutputDirs)
	set(reportBaseNames)
	foreach( comparedToVersion ${comparedToVersions})
		
		# Get report directory depending on the compared versions
		cpfIsReleaseVersion( comparedToVersionIsRelease ${comparedToVersion})
		if(NOT newVersionIsRelease AND (NOT comparedToVersionIsRelease))
			cpfGetRelCurrentToLastBuildReportDir( reportOutputDir ${packageComponent})
		elseif(NOT newVersionIsRelease AND comparedToVersionIsRelease)
			cpfGetRelCurrentToLastReleaseReportDir( reportOutputDir ${packageComponent})
		else()	# both versions are release versions
			cpfGetRelVersionToVersionReportDir( reportOutputDir ${packageComponent} ${newVersion} ${comparedToVersion} )
		endif()
		cpfListAppend( reportOutputDirs ${reportOutputDir})
		
		# get the report base name
		cpfGetCompatibilityReportBaseNameForVersion( baseName ${binaryTarget} ${newVersion} ${comparedToVersion} )
		cpfListAppend( reportBaseNames ${baseName})
		
	endforeach()
	
	set( ${reportDirsOut} ${reportOutputDirs} PARENT_SCOPE )
	set( ${reportBaseNamesOut} ${reportBaseNames} PARENT_SCOPE )
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetCompatibilityReportBaseNameForVersion baseNameOut binaryTarget newVersion oldVersion )
	set( ${baseNameOut} compatibilityReport-${binaryTarget}-${oldVersion}-to-${newVersion} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# reportOutputDir is an absolute path to the directory that will contain the generated report.
# enforceOption must be one of NONE, API, ABI
function( cpfAddAbiComplianceCheckerTarget reportFileOut packageComponent binaryTarget packageFormat comparedToVersion reportBaseName reportOutputDir enforceOption )

	set(targetName ${reportBaseName})
	cpfGetAbiDumpTargetName( abiDumpTarget ${binaryTarget} )
	
	# Get locations of the compared dump files
	cpfGetLocationOfDownloadedDumpFile( oldVersionDumpFile ${packageComponent} ${binaryTarget} ${packageFormat} ${comparedToVersion} )
	if(NOT EXISTS "${oldVersionDumpFile}")
		if( ${enforceOption} STREQUAL "NONE" ) 
			# We have to allow missing previous old dumps, because that will happen if we switch the compatibility report target on.
			message( "Warning: The abi dump-file \"${oldVersionDumpFile}\" is missing. \
This means that either the old package could not be downloaded, or that the package did not contain an abi dump file. \
You can ignore this message if you just switched ON the CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS option, and the old package does not yet contain an abi dump file. \
The abi/api compatibility report will not be created for this build." )
		return()
		else()
			# When stability shall be enforced, we have to insist on the old dump files.
			message( FATAL_ERROR "The abi dump-file \"${oldVersionDumpFile}\" is missing. \
This means that either the old package could not be downloaded, or that the package did not contain an abi dump file. \
This is the case when the old package was compiled with the CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS option set to OFF. \
In this case you first have to build a release with the CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS option set to ON, \
to ensure that abi dump files become available for following builds." )
		endif()
	endif()

	cpfGetCurrentDumpFile( abiDumpFile ${packageComponent} ${binaryTarget})
	set( shortReportFile ${reportBaseName}.html)
	set( reportFile "${reportOutputDir}/${shortReportFile}" )
	
	# Add a command for creating the report
	set( complianceCheckerCommand "cmake\
 -DTOOL_PATH=\"${TOOL_ABI_COMPLIANCE_CHECKER}\"\
 -DBINARY_NAME=\"${binaryTarget}\"\
 -DOLD_DUMP_FILE=\"${oldVersionDumpFile}\"\
 -DNEW_DUMP_FILE=\"${abiDumpFile}\"\
 -DREPORT_PATH=\"${reportFile}\"\
 -DENFORCE_COMPATIBILITY=${enforceOption}\
 -P \"${CPF_ABS_SCRIPT_DIR}/runAbiComplianceChecker.cmake\"")

	cpfAddStandardCustomCommand(
		DEPENDS ${abiDumpFile} ${oldVersionDumpFile}
		OUTPUT ${reportFile}
		COMMANDS ${complianceCheckerCommand}
	)

	# Add the target
	add_custom_target(
		${targetName}
		DEPENDS ${abiDumpTarget} ${reportFile} ${stampFile}
	)

	set_property(TARGET ${packageComponent} APPEND PROPERTY INTERFACE_CPF_ABI_CHECK_SUBTARGETS ${targetName} )
	
	set(${reportFileOut} ${reportFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetLocationOfDownloadedDumpFile dumpFileOut packageComponent binaryTarget packageFormat version )
	
	# get the path to the dumpfile within the extracted package
	cpfGetDumpFilePathRelativeToPackageDir( relDumpFilePath ${packageComponent} ${binaryTarget})
	
	# get the name of the directory that is created when the package-component is extracted (the archive filename without the archive extensions)
	cpfGetShortDevBinPackageName( archiveFileName ${packageComponent} ${CMAKE_BUILD_TYPE} ${version} ${packageFormat} )
	cpfGetPackageArchiveExtension( archiveExtension ${packageFormat})
	# remove the extension
	string(LENGTH ${archiveExtension} length)
	cpfIncrement(length) # + 1 for the dot
	cpfStringRemoveRight( packageDir ${archiveFileName} ${length})

	getPreviousPackageDownloadDirectory(downloadDir)
	set( ${dumpFileOut} "${downloadDir}/${packageDir}/${relDumpFilePath}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddApiCompatibilityCheckTarget reportFileOut packageComponent binaryTarget packageFormat lastReleaseVersion )
	
	set(reportFile)
	set(targetName checkApiCompatibility_${binaryTarget} )
	cpfAddAbiComplianceCheckerTarget( reportFile ${packageComponent} ${binaryTarget} ${packageFormat} ${lastReleaseVersion} ${targetName} "${CMAKE_CURRENT_BINARY_DIR}/${targetName}" API)
	set(${reportFileOut} "${reportFile}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddAbiCompatibilityCheckTarget reportFileOut packageComponent binaryTarget packageFormat lastReleaseVersion )
	
	set(reportFile)
	set(targetName checkAbiCompatibility_${binaryTarget} )
	cpfAddAbiComplianceCheckerTarget( reportFile ${packageComponent} ${binaryTarget} ${packageFormat} ${lastReleaseVersion} ${targetName} "${CMAKE_CURRENT_BINARY_DIR}/${targetName}" ABI)
	set(${reportFileOut} "${reportFile}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddCleanOutputDirsCommands cleanStampsOut target reportFiles )
	
	# get the directories of the files
	list(SORT reportFiles)

	set(currentDir)
	set(names)
	set(filesInDir)
	set(stampFiles)
	foreach(file ${reportFiles})
		
		get_filename_component( dir ${file} DIRECTORY)
		get_filename_component( name ${file} NAME)
		
		if( NOT ${dir} STREQUAL "${currentDir}")
			# add clear command for all files from the current dir
			if(currentDir)
				cpfAddClearDirExceptCommand( stampFile ${currentDir} "${names}" ${targetName} ${filesInDir})
				cpfListAppend( stampFiles ${stampFile})
			endif()
			
			set(currentDir ${dir})
			set(names ${name})
			set(filesInDir ${file})
		else()
			# accumulate the file for the same dir
			cpfListAppend( names ${name})
			cpfListAppend( filesInDir ${file})
		endif()

	endforeach()
	
	set(${cleanStampsOut} ${stampFiles} PARENT_SCOPE)
	
endfunction()
