 
include(ccbCustomTargetUtilities)
include(ccbBaseUtilities)
include(ccbProjectUtilities)
include(ccbGitUtilities)
include(ccbLocations)


set(DIR_OF_ADD_COMPATIBILITY_FILE ${CMAKE_CURRENT_LIST_DIR})
 
 
# This file ccbContains functions that the targets that are used to implement the ABI and API compatibility checks.


#----------------------------------------------------------------------------------------
# Adds a bundle target, that can be used to run the abi-compliance-check targets for all packages. 
function( ccbAddGlobalAbiCheckerTarget packages )
	
	set(targets)
	foreach( package ${packages})
		ccbGetPackageVersionCompatibilityCheckTarget( target ${package})
		if(TARGET ${target})
			list(APPEND targets ${target})
		endif()
	endforeach()
	ccbAddBundleTarget( versionCompatibilityChecks "${targets}")
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetPackageVersionCompatibilityCheckTarget targetNameOut package )
	set( ${targetNameOut} versionCompatibilityCheck_${package} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function adds custom targets which call the abi-compliance-checker tool.
function( ccbAddAbiCheckerTargets package distributionPackageOptionLists )
	
	ccbAssertUserSettingsForCompatibilityChecksMakeSense( ${package} "${distributionPackageOptionLists}" )
	if( CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS )

		ccbGetLastBuildAndLastReleaseVersion( lastBuildVersion lastReleaseVersion)
		ccbHasDevBinDistributionPackage( unused packageFormat "${distributionPackageOptionLists}" )
		ccbDownloadOldAbiDumps( ${package} ${packageFormat} ${lastBuildVersion} ${lastReleaseVersion} )
		
		# Add The targets that create and use the abi-dumps.
		ccbGetSharedLibrarySubTargets( libraryTargets ${package})
		foreach( libraryTarget ${libraryTargets})
			
			ccbWritePublicHeaderListFile( headerListFile ${package} ${libraryTarget})

			ccbAddAbiDumpTarget( ${package} ${libraryTarget} ${headerListFile} )
			set( comparedToVersions ${lastBuildVersion} ${lastReleaseVersion} )
			list(REMOVE_DUPLICATES comparedToVersions) # this is required for the case when lastBuild == lastRelease
			ccbAddCompatibilityReportTargets( reportFiles ${package} ${libraryTarget} ${packageFormat} "${comparedToVersions}" )
			
			# Add the abi-compliance-checker targets that enforce the compatibility when the configuration options are set.
			ccbAddApiCompatibilityCheckTarget( reportFileApiCheck ${package} ${libraryTarget} ${packageFormat} ${lastReleaseVersion})
			ccbAddAbiCompatibilityCheckTarget( reportFileAbiCheck ${package} ${libraryTarget} ${packageFormat} ${lastReleaseVersion})

		endforeach()

		# Add a target to bundle all abi check targets of one package into one and to remove old reports.
		ccbGetPackageVersionCompatibilityCheckTarget( targetName ${package})
		ccbAddCleanOutputDirsCommands( cleanStamps ${targetName} "${reportFiles};${reportFileApiCheck};${reportFileAbiCheck}" )
		ccbAddSubTargetBundleTarget( ${targetName} ${package} CCB_ABI_CHECK_SUBTARGETS "${cleanStamps}")
	endif()
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAssertUserSettingsForCompatibilityChecksMakeSense package distributionPackageOptionLists )

	# If user requests compatibility checks, the compiler settings must support it. 
	if(CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS)
		ccbCompileSettingsSupportAbiDumper( abiDumperSupported )
		if(NOT abiDumperSupported )
			set(errorMessage "\
Error with project settings!\n\
Option CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS was set to ON while the compiler settings do not support the abi-dumper tool. \
This option can only be enabled when using \"g++ -g -Og\" or \"clang -g -O0\" compiler settings.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# check the tools are available
		ccbFindRequiredProgram( TOOL_ABI_DUMPER abi-dumper "A tool that creates abi dump files from shared libraries." )
		ccbFindRequiredProgram( TOOL_ABI_COMPLIANCE_CHECKER abi-compliance-checker "A tool that compares two abi dump files and checks whether the ABIs are compliant." )
		
		# check that previous builds have been made available through the webpage
		if( NOT CCB_WEBPAGE_URL )
			set(errorMessage "\
Error with project settings!\n\
Option CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS was set to ON but variable CCB_WEBPAGE_URL was not set. \
In order to check the compliance with previously released packages, the CppCodeBase must be able to download previous build results from the web-page.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# currently we the abi-compliance-checker tool needs shared libs
		if( NOT BUILD_SHARED_LIBS )
			set(errorMessage "\
Error with project settings!\n\
Option CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS was set to ON but variable BUILD_SHARED_LIBS was not set. \
The compatibility check targets currently only work for shared libraries.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# Currently we need the version information from the repository in order to download
		# the correct previous versions. 
		ccbIsGitRepositoryDir( isRepoDirOut "${CMAKE_CURRENT_SOURCE_DIR}")
		if(NOT isRepoDirOut)
			set(errorMessage "\
Error with project settings!\n\
Option CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS was set to ON but the sources were not retrieved by cloning the Git repository. \
The compatibility check targets require the version information from to repository in order to download previously build versions.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
		# Make sure that the package has a dev-bin distribution package which holds the dump file.
		ccbHasDevBinDistributionPackage( hasDevBinPackage unused "${distributionPackageOptionLists}")
		if(NOT hasDevBinPackage)
			set(errorMessage "\
Error with project settings!\n\
Option CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS was set to ON but package ${package} does not create a distribution package with content type BINARIES_DEVELOPER. \
The packages with content type BINARIES_DEVELOPER contain the abi dump files for previously build libraries which are needed to compare the abi-compliance. \
You need to add an DISTRIBUTION_PACKAGES to your call of ccbAddPackage() with the DISTRIBUTION_PACKAGE_CONTENT_TYPE BINARIES_DEVELOPER sub-option to remove this error.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
		
	endif()
	
	# CCB_CHECK_API_STABLE requires CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option.
	if( CCB_CHECK_API_STABLE )
		if( NOT CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS )
			set(errorMessage "\
Error with project settings!\n\
The activation of the CCB_CHECK_API_STABLE option requires the activation of the CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
	endif()

	# CCB_CHECK_ABI_STABLE requires CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option.
	if( CCB_CHECK_ABI_STABLE )
		if( NOT CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS )
			set(errorMessage "\
Error with project settings!\n\
The activation of the CCB_CHECK_API_STABLE option requires the activation of the CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option.\n\
			")
			message(FATAL_ERROR ${errorMessage} )
		endif()
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Note that the abi-dumper prefers the -Og flag over the -O0 flag, but it is only available
# for Gcc
function( ccbCompileSettingsSupportAbiDumper boolOut )

	set(isSupported FALSE)
	
	if(CMAKE_BUILD_TYPE) # we only support single configuration build tools for now
		ccbGetCompiler( compiler)
		ccbGetCxxFlags( compileFlags ${CMAKE_BUILD_TYPE})
		ccbContains( hasGFlag "${compileFlags}" "-g")
		ccbContains( hasO0Flag "${compileFlags}" "-O0")
		ccbContains( hasOgFlag "${compileFlags}" "-Og")
		if( ${compiler} STREQUAL Clang AND hasGFlag AND hasO0Flag )
			set(isSupported TRUE)
		elseif( ${compiler} STREQUAL Gcc AND hasGFlag AND hasOgFlag )
			set(isSupported TRUE)
		endif()
	else()
		message(FATAL_ERROR "Currently ccbAddAbiDumpTarget() is only supported for single configuration generators.")
	endif()

	set( ${boolOut} ${isSupported} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbHasDevBinDistributionPackage hasDevBinPackageOut packageFormatOut distributionPackageOptionLists )

	foreach( list ${distributionPackageOptionLists})
	
		ccbParseDistributionPackageOptions( contentType packageFormats unused unused "${${list}}")
		
		if( ${contentType} STREQUAL BINARIES_DEVELOPER )
			set( ${hasDevBinPackageOut} TRUE PARENT_SCOPE)
			
			foreach( format ${packageFormats})
				ccbIsArchiveFormat( isArchive ${format})
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
# This function was introduced to only have one definition of the distribution package option keywords
function( ccbParseDistributionPackageOptions contentTypeOut packageFormatsOut distributionPackageFormatOptionsOut excludedTargetsOut argumentList )

	cmake_parse_arguments(
		ARG 
		"" 
		"" 
		"DISTRIBUTION_PACKAGE_CONTENT_TYPE;DISTRIBUTION_PACKAGE_FORMATS;DISTRIBUTION_PACKAGE_FORMAT_OPTIONS"
		${argumentList}
	)

	cmake_parse_arguments(
		ARG
		"BINARIES_DEVELOPER"
		""
		"BINARIES_USER"
		"${ARG_DISTRIBUTION_PACKAGE_CONTENT_TYPE}"
	)
	
	ccbContains(isBinaryUserType "${ARG_DISTRIBUTION_PACKAGE_CONTENT_TYPE}" BINARIES_USER)
	if( ${ARG_BINARIES_DEVELOPER} AND ${isBinaryUserType} )
		message(FATAL_ERROR "The DISTRIBUTION_PACKAGE_CONTENT_TYPE option in ccbAddPackage() can not take both options BINARIES_DEVELOPER and BINARIES_USER" )
	endif()
	
	if(ARG_BINARIES_DEVELOPER)
		set(contentType BINARIES_DEVELOPER)
	elseif(isBinaryUserType)
		set(contentType BINARIES_USER)
	else()
		message(FATAL_ERROR "Faulty DISTRIBUTION_PACKAGE_CONTENT_TYPE option in ccbAddPackage().")
	endif()
	
	set(${contentTypeOut} ${contentType} PARENT_SCOPE)
	set(${packageFormatsOut} ${ARG_DISTRIBUTION_PACKAGE_FORMATS} PARENT_SCOPE)
	set(${distributionPackageFormatOptionsOut} ${ARG_DISTRIBUTION_PACKAGE_FORMAT_OPTIONS} PARENT_SCOPE)
	set(${excludedTargetsOut} ${ARG_BINARIES_USER} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbIsArchiveFormat isArchiveFormatOut packageFormat )
	ccbGetArchiveFormats(archiveGenerators)
	ccbContains( isArchiveGenerator "${archiveGenerators}" ${packageFormat})
	set( ${isArchiveFormatOut} ${isArchiveGenerator} PARENT_SCOPE )
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetArchiveFormats archiveFormatsOut )
	set( ${archiveFormatsOut} 7Z TBZ2 TGZ TXZ TZ ZIP PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetLastBuildAndLastReleaseVersion lastBuildVersionOut lastReleaseVersionOut )
	
	ccbGetCurrentBranch( branch "${CMAKE_CURRENT_SOURCE_DIR}")
	ccbGetLastVersionTagOfBranch( lastVersion ${branch} "${CMAKE_CURRENT_SOURCE_DIR}" FALSE)
	ccbGetLastReleaseVersionTagOfBranch( lastReleaseVersion ${branch} "${CMAKE_CURRENT_SOURCE_DIR}" FALSE)
	
	set(${lastBuildVersionOut} ${lastVersion} PARENT_SCOPE)
	set(${lastReleaseVersionOut} ${lastReleaseVersion} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbDownloadOldAbiDumps package packageFormat lastBuildVersion lastReleaseVersion )
	
	# get url of LastBuild package	
	ccbIsReleaseVersion( lastBuildIsRelease ${lastBuildVersion} )
	if(NOT lastBuildIsRelease)
		ccbGetShortDevBinPackageName( packageLastBuild ${package} ${CMAKE_BUILD_TYPE} ${lastBuildVersion} ${packageFormat} )
		ccbGetRelLastBuildPackagesDir( lastBuildPackageDir ${package})
		set( urlLastBuild "${CCB_WEBPAGE_URL}/${lastBuildPackageDir}/${packageLastBuild}")
		ccbDownloadAndExtractPackage( ${package} ${packageFormat} ${urlLastBuild})
	endif()

	# get url of last release package
	ccbGetShortDevBinPackageName( packageLastRelease ${package} ${CMAKE_BUILD_TYPE} ${lastReleaseVersion} ${packageFormat} )
	ccbGetRelReleasePackagesDir( releasePackageDir ${package} ${lastReleaseVersion})
	set( urlLastRelease "${CCB_WEBPAGE_URL}/${releasePackageDir}/${packageLastRelease}")
	ccbDownloadAndExtractPackage( ${package} ${packageFormat} ${urlLastRelease})

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetShortDevBinPackageName shortNameOut package config version packageFormat )

	ccbGetDistributionPackageContentId( contentId BINARIES_DEVELOPER "")
	ccbGetBasePackageFilename( basePackageFileName ${package} ${config} ${version} ${contentId} ${packageFormat})
	ccbGetDistributionPackageExtension( extension ${packageFormat})
	set( ${shortNameOut} ${basePackageFileName}.${extension} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetDistributionPackageContentId contentIdOut contentType excludedTargets )

	if( "${contentType}" STREQUAL BINARIES_DEVELOPER)
		set(contentIdLocal dev-bin)
	elseif( "${contentType}" STREQUAL BINARIES_USER )
		set(contentIdLocal usr-bin )
		if( NOT "${excludedTargets}" STREQUAL "")
			list(SORT excludedTargets)
			string(MD5 excludedTargetsHash "${excludedTargets}")
			# to keep things short we only use the first 8 characters and hope that collisions are
			# rare engough to never occur
			string(SUBSTRING ${excludedTargetsHash} 0 8 excludedTargetsHash)
			string(APPEND contentIdLocal -${excludedTargetsHash})
		else()
			string(APPEND contentIdLocal -portable)
		endif()
	else()
		message(FATAL_ERROR "Content type \"${contentType}\" is not supported by function contentTypeOutputNameIdentifier().")
	endif()
	
	set(${contentIdOut} ${contentIdLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetDistributionPackageExtension extensionOut packageFormat )

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
		message(FATAL_ERROR "Package format \"${packageFormat}\" is not supported by function ccbGetDistributionPackageExtension().")
	endif()

	set(${extensionOut} ${extensionLocal} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbDownloadAndExtractPackage package packageFormat packageUrl  )

	# downlaod the package
	get_filename_component( shortName "${packageUrl}" NAME )
	set( downloadDir "${CCB_PREVIOUS_PACKAGES_ABS_DIR}")
	set( downloadedPackage "${downloadDir}/${shortName}")
	ccbDebugMessage("Download package from \"${packageUrl}\"")
	file(DOWNLOAD "${packageUrl}" "${downloadedPackage}" INACTIVITY_TIMEOUT 1 STATUS resultValues )

	list(GET resultValues 0 returnCode )
	if( NOT ${returnCode} EQUAL 0)
		# We only issue a warning here to not break builds when the packages are not available.
		# This can happen when the variable CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS has been switched ON, or parts of the build have
		# been disabled during maintanance.
		message( "Warning: Could not download released distribution package from ${packageUrl}. Comparing the current ABI/API with that package will not be possible.")
 	else()
		# extract the package
		ccbExecuteProcess( unused "cmake -E tar x ${shortName}" "${downloadDir}" DONT_INTERCEPT_OUTPUT )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# 
function( ccbWritePublicHeaderListFile headerListFileOut package target )

	ccbGetAbiDumpTargetName( abiDumpTarget ${target})
	set(headerListFile "${CMAKE_BINARY_DIR}/${package}/${abiDumpTarget}/PublicHeaderList.txt")
	
	get_property( publicHeader TARGET ${target} PROPERTY CCB_PUBLIC_HEADER )
	set(fileContent)
	foreach( header ${publicHeader} )
		ccbIsAbsolutePath( isAbsPath ${header})
		if(NOT isAbsPath )
			set(header ${CMAKE_CURRENT_SOURCE_DIR}/${header} )
		endif()
		string(APPEND fileContent "${header}\n")
	endforeach()
	
	file(WRITE ${headerListFile} ${fileContent})
	
	set(${headerListFileOut} ${headerListFile} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Defines the name of the abi-dump target
function( ccbGetAbiDumpTargetName targetNameOut binaryTarget )
	set(${targetNameOut} abiDump_${binaryTarget} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# This function adds a target that creates an ABI dump file with the abi-dumper tool.
# The target will only be available when using "g++ -g -Og" or "clang -g -O0" because the
# tool requires DWARF debug information.
# 
function( ccbAddAbiDumpTarget package binaryTarget headerListFile )

	ccbGetAbiDumpTargetName( targetName ${binaryTarget})
	
	# Locations
	ccbGetFullTargetOutputFile( targetBinaryFile ${binaryTarget} ${CMAKE_BUILD_TYPE} )
	get_property( version TARGET ${binaryTarget} PROPERTY VERSION)
	ccbGetDumpFilePathRelativeToInstallPrefix( relDumpFilePath ${package} ${binaryTarget} ${version} )
	set( abiDumpFile "${CMAKE_INSTALL_PREFIX}/${relDumpFilePath}")
	
	# Setup the command
	get_property( version TARGET ${binaryTarget} PROPERTY VERSION)
	set( abiDumperCommand "\"${TOOL_ABI_DUMPER}\" \"${targetBinaryFile}\" -lver ${version} -o \"${abiDumpFile}\" -public-headers \"${headerListFile}\"" )
	ccbAddStandardCustomCommand(
		OUTPUT ${abiDumpFile}
		DEPENDS ${binaryTarget}
		COMMANDS ${abiDumperCommand}
	)

	# add target
	add_custom_target(
		${targetName}
		DEPENDS ${binaryTarget} ${abiDumpFile}
	)
	
	# set target properties
	ccbToConfigSuffix( configSuffix ${CMAKE_BUILD_TYPE} )
	set_property(TARGET ${targetName} PROPERTY CCB_OUTPUT_FILES${configSuffix} ${abiDumpFile} )
	set_property(TARGET ${package} APPEND PROPERTY CCB_ABI_DUMP_SUBTARGETS ${targetName} )

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetDumpFilePathRelativeToInstallPrefix pathOut package binaryTarget version )
	
	ccbGetAbiDumpFileName( abiDumpFileShort ${binaryTarget} ${version})
	ccbGetRelativeOutputDir( relDir ${package} PDB) # we put it in the debug directory
	set( ${pathOut} "${relDir}/${abiDumpFileShort}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetAbiDumpFileName shortNameOut binaryTarget version )
	ccbToConfigSuffix( configSuffix ${CMAKE_BUILD_TYPE} )
	set( ${shortNameOut} ABI_${binaryTarget}${CMAKE${configSuffix}_POSTFIX}.${version}.dump PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetDumpFilePathRelativeToPackageDir pathOut binaryTarget version)
	ccbGetAbiDumpFileName( dumpFile ${binaryTarget} ${version})
	ccbGetTypePartOfOutputDir( typeDir "" PDB )
	set( ${pathOut} ${typeDir}/${dumpFile} PARENT_SCOPE)
endfunction()


#----------------------------------------------------------------------------------------
# Adds targets that create api-compliance-checker compatibilty reports for the given binaryTarget
# comparing the current version to each version in comparedToVersion. 
function( ccbAddCompatibilityReportTargets reportFilesOut package binaryTarget packageFormat comparedToVersions )
	
	get_property( version TARGET ${binaryTarget} PROPERTY VERSION)
	ccbGetReportBaseNamesAndOutputDirs( reportOutputDirs reportBaseNames ${package} ${binaryTarget} ${version} "${comparedToVersions}")
	
	set(index 0)
	set(reportFiles)
	foreach( comparedToVersion ${comparedToVersions})
		list(GET reportOutputDirs ${index} reportOutputDir)
		list(GET reportBaseNames ${index} reportBaseName)
		ccbIncrement(index)
		ccbAddAbiComplianceCheckerTarget( reportFile ${package} ${binaryTarget} ${packageFormat} ${comparedToVersion} ${reportBaseName} "${CCB_PROJECT_HTML_ABS_DIR}/${reportOutputDir}" NONE)
		list(APPEND reportFiles ${reportFile})
	endforeach()
	
	set(${reportFilesOut} ${reportFiles} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetReportBaseNamesAndOutputDirs reportDirsOut reportBaseNamesOut package binaryTarget newVersion comparedToVersions )

	ccbIsReleaseVersion( newVersionIsRelease ${newVersion})
	
	set(reportOutputDirs)
	set(reportBaseNames)
	foreach( comparedToVersion ${comparedToVersions})
		
		# Get report directory depending on the compared versions
		ccbIsReleaseVersion( comparedToVersionIsRelease ${comparedToVersion})
		if(NOT newVersionIsRelease AND (NOT comparedToVersionIsRelease))
			ccbGetRelCurrentToLastBuildReportDir( reportOutputDir ${package})
		elseif(NOT newVersionIsRelease AND comparedToVersionIsRelease)
			ccbGetRelCurrentToLastReleaseReportDir( reportOutputDir ${package})
		else()	# both versions are release versions
			ccbGetRelVersionToVersionReportDir( reportOutputDir ${package} ${newVersion} ${comparedToVersion} )
		endif()
		list(APPEND reportOutputDirs ${reportOutputDir})
		
		# get the report base name
		ccbGetCompatibilityReportBaseNameForVersion( baseName ${binaryTarget} ${newVersion} ${comparedToVersion} )
		list(APPEND reportBaseNames ${baseName})
		
	endforeach()
	
	set( ${reportDirsOut} ${reportOutputDirs} PARENT_SCOPE )
	set( ${reportBaseNamesOut} ${reportBaseNames} PARENT_SCOPE )
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetCompatibilityReportBaseNameForVersion baseNameOut binaryTarget newVersion oldVersion )
	set( ${baseNameOut} compatibilityReport-${binaryTarget}-${oldVersion}-to-${newVersion} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# reportOutputDir is an absolute path to the directory that will contain the generated report.
# enforceOption must be one of NONE, API, ABI
function( ccbAddAbiComplianceCheckerTarget reportFileOut package binaryTarget packageFormat comparedToVersion reportBaseName reportOutputDir enforceOption )

	set(targetName ${reportBaseName})
	ccbGetAbiDumpTargetName( abiDumpTarget ${binaryTarget} )
	
	# Get locations of the compared dump files
	ccbGetLocationOfDownloadedDumpFile( oldVersionDumpFile ${package} ${binaryTarget} ${packageFormat} ${comparedToVersion} )
	if(NOT EXISTS "${oldVersionDumpFile}")
		if( ${enforceOption} STREQUAL "NONE" ) 
			# We have to allow missing previous old dumps, because that will happen if we switch the compatibility report target on.
			message( "Warning: The abi dump-file \"${oldVersionDumpFile}\" is missing. \
This means that either the old package could not be downloaded, or that the package did not contain an abi dump file. \
You can ignore this message if you just switched ON the CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option, and the old package does not yet contain an abi dump file. \
The abi/api compatibility report will not be created for this build." )
		return()
		else()
			# When stability shall be enforced, we have to insist on the old dump files.
			message( FATAL_ERROR "The abi dump-file \"${oldVersionDumpFile}\" is missing. \
This means that either the old package could not be downloaded, or that the package did not contain an abi dump file. \
This is the case when the old package was compiled with the CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option set to OFF. \
In this case you first have to build a release with the CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option set to ON, \
to ensure that abi dump files become available for following builds." )
		endif()
	endif()

	ccbGetCurrentDumpFile( abiDumpFile ${package} ${binaryTarget})
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
 -P \"${DIR_OF_ADD_COMPATIBILITY_FILE}/../Scripts/runAbiComplianceChecker.cmake\"")

	ccbAddStandardCustomCommand(
		DEPENDS ${abiDumpFile} ${oldVersionDumpFile}
		OUTPUT ${reportFile}
		COMMANDS ${complianceCheckerCommand}
	)

	# Add the target
	add_custom_target(
		${targetName}
		DEPENDS ${abiDumpTarget} ${reportFile} ${stampFile}
	)

	set_property(TARGET ${package} APPEND PROPERTY CCB_ABI_CHECK_SUBTARGETS ${targetName} )
	
	set(${reportFileOut} ${reportFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetLocationOfDownloadedDumpFile dumpFileOut package binaryTarget packageFormat version )
	
	# get the path to the dumpfile within the extracted package
	ccbGetDumpFilePathRelativeToPackageDir( relDumpFilePath ${binaryTarget} ${version})
	
	# get the name of the directory that is created when the package is extracted (the archive filename without the archive extensions)
	ccbGetShortDevBinPackageName( archiveFileName ${package} ${CMAKE_BUILD_TYPE} ${version} ${packageFormat} )
	ccbGetDistributionPackageExtension( archiveExtension ${packageFormat})
	# remove the extension
	string(LENGTH ${archiveExtension} length)
	ccbIncrement(length) # + 1 for the dot
	ccbStringRemoveRight( packageDir ${archiveFileName} ${length})

	set( ${dumpFileOut} "${CCB_PREVIOUS_PACKAGES_ABS_DIR}/${packageDir}/${relDumpFilePath}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetCurrentDumpFile dumpFileOut package binaryTarget )
	get_property( currentVersion TARGET ${package} PROPERTY VERSION )
	ccbGetDumpFilePathRelativeToInstallPrefix( relDumpFilePath ${package} ${binaryTarget} ${currentVersion} )
	set( ${dumpFileOut} "${CMAKE_INSTALL_PREFIX}/${relDumpFilePath}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddApiCompatibilityCheckTarget reportFileOut package binaryTarget packageFormat lastReleaseVersion )
	
	set(reportFile)
	if(CCB_CHECK_API_STABLE)
		set(targetName checkApiCompatibility_${binaryTarget} )
		ccbAddAbiComplianceCheckerTarget( reportFile ${package} ${binaryTarget} ${packageFormat} ${lastReleaseVersion} ${targetName} "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/${targetName}" API)
	endif()
	set(${reportFileOut} "${reportFile}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddAbiCompatibilityCheckTarget reportFileOut package binaryTarget packageFormat lastReleaseVersion )
	
	set(reportFile)
	if(CCB_CHECK_ABI_STABLE)
		set(targetName checkAbiCompatibility_${binaryTarget} )
		ccbAddAbiComplianceCheckerTarget( reportFile ${package} ${binaryTarget} ${packageFormat} ${lastReleaseVersion} ${targetName} "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/${targetName}" ABI)
	endif()
	set(${reportFileOut} "${reportFile}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddCleanOutputDirsCommands cleanStampsOut target reportFiles )
	
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
				ccbAddClearDirExceptCommand( stampFile ${currentDir} ${names} ${targetName} ${filesInDir})
				list(APPEND stampFiles ${stampFile})
			endif()
			
			set(currentDir ${dir})
			set(names ${name})
			set(filesInDir ${file})
		else()
			# accumulate the file for the same dir
			list(APPEND names ${name})
			list(APPEND filesInDir ${file})
		endif()

	endforeach()
	
	set(${cleanStampsOut} ${stampFiles} PARENT_SCOPE)
	
endfunction()
