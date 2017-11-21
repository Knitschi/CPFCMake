
include(ccbLocations)
include(ccbBaseUtilities)
include(ccbProjectUtilities)
include(ccbGitUtilities)
include(ccbCustomTargetUtilities)
include(ccbAddCompatibilityCheckTarget)
include(ccbAddDynamicAnalysisTarget)

set(DIR_OF_DOCUMENTATION_TARGET_FILE ${CMAKE_CURRENT_LIST_DIR})

#----------------------------------------------------------------------------------------
# Adds a target that runs doxygen on the whole Source directory of the CPPCODEBASE
#
# This function should be removed when the problems with the ccbAddGlobalDocumentationTarget() generation get fixed.
function( ccbAddGlobalMonolithicDocumentationTarget packages)

	if(NOT CCB_ENABLE_DOXYGEN_TARGET)
		return()
	endif()

	set(targetName documentation)

	# Locations
	set(targetBinaryDir "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/${targetName}" )
	set(tempDoxygenConfigFile "${targetBinaryDir}/tempDoxygenConfig.txt" )
	set(reducedGraphFile "${CCB_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/CppCodeBaseDependenciesTransitiveReduced.dot")
	set(doxygenConfigFile "${CMAKE_SOURCE_DIR}/DoxygenConfig.txt")
	set(htmlCgiBinDir "${CCB_PROJECT_HTML_ABS_DIR}/${CCB_CGI_BIN_DIR}" )

	# Get dependencies
	set(fileDependencies)
	set(targetDependencies)
	foreach( package ${packages})
		ccbGetPackageDoxFilesTargetName( doxFilesTarget ${package} )
		list(APPEND targetDependencies ${doxFilesTarget})
		get_property( generatedDoxFiles TARGET ${doxFilesTarget} PROPERTY CCB_OUTPUT_FILES )
		list(APPEND fileDependencies ${generatedDoxFiles})
	endforeach()

	# Add a command to generate the the transitive reduced dependency graph of all targets.
    # The tred tool is from the graphviz suite and does the transitive reduction.
	# The generated file is used as input of the documentation.
	get_filename_component(reducedDepGraphDir ${reducedGraphFile} DIRECTORY)
	set(tredCommand "\"${TOOL_TRED}\" \"${CCB_TARGET_DEPENDENCY_GRAPH_FILE}\" > \"${reducedGraphFile}\"")
	ccbAddStandardCustomCommand(
		OUTPUT ${reducedGraphFile}
		DEPENDS ${CCB_TARGET_DEPENDENCY_GRAPH_FILE}
		COMMANDS "cmake -E make_directory \"${reducedDepGraphDir}\"" ${tredCommand}
	)

	# add a command to copy the full dependency graph to the doxygen output dir
	get_filename_component(destShort ${CCB_TARGET_DEPENDENCY_GRAPH_FILE} NAME )
	set(copiedDependencyGraphFile ${CCB_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/${destShort})
	ccbAddCustomCommandCopyFile(${CCB_TARGET_DEPENDENCY_GRAPH_FILE} ${copiedDependencyGraphFile} )

	# The config file must contain the names of the depended on xml tag files of other doxygen sub-targets.
	list(APPEND appendedLines "DOTFILE_DIRS = \"${CCB_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}\"")
	list(APPEND appendedLines "OUTPUT_DIRECTORY = \"${CCB_DOXYGEN_OUTPUT_ABS_DIR}\"")
	list(APPEND appendedLines "INPUT = \"${CMAKE_SOURCE_DIR}\"")
	list(APPEND appendedLines "INPUT += \"${CMAKE_BINARY_DIR}/${CCB_GENERATED_DOCS_DIR}\"")
	
	ccbAddAppendLinesToFileCommands( 
		INPUT ${doxygenConfigFile}
		OUTPUT ${tempDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)

	# Add the command for running doxygen
	set( doxygenCommand "\"${TOOL_DOXYGEN}\" \"${tempDoxygenConfigFile}\"")
	set( searchDataXmlFile ${CCB_DOXYGEN_OUTPUT_ABS_DIR}/searchdata.xml)
	ccbGetAllNonGeneratedPackageSources(sourceFiles "${packages}")
	ccbAddStandardCustomCommand(
		OUTPUT ${searchDataXmlFile}
		DEPENDS ${tempDoxygenConfigFile} ${copiedDependencyGraphFile} ${reducedGraphFile} ${sourceFiles} ${linkFiles} ${fileDependencies}
		COMMANDS ${doxygenCommand}
	)

	# Create the command for running the doxyindexer.
	# The doxyindexer creates the content of the doxysearch.dp directory which is used by the doxysearch.cgi script 
	# when using the search function of the documentation
	set(doxyIndexerCommand "\"${TOOL_DOXYINDEXER}\" -o \"${htmlCgiBinDir}\" \"${searchDataXmlFile}\"" )
	set(doxyIndexerStampFile ${targetBinaryDir}/doxyindexer.stamp)
	ccbAddStandardCustomCommand(
		OUTPUT ${doxyIndexerStampFile}
		DEPENDS ${searchDataXmlFile}
		COMMANDS "cmake -E make_directory \"${htmlCgiBinDir}\"" ${doxyIndexerCommand} "cmake -E touch \"${doxyIndexerStampFile}\""
	)

	# Now add the target
	add_custom_target(
		${targetName}
		DEPENDS ${doxyIndexerStampFile} ${targetDependencies}
	)

endfunction()

#----------------------------------------------------------------------------------------
# read all sources from all binary targets of the given packages
function( ccbGetAllNonGeneratedPackageSources sourceFiles packages )

	foreach( package ${packages})
		get_property(binaryTargets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS )
		foreach( target ${binaryTargets} globalFiles)
			get_property(files TARGET ${target} PROPERTY SOURCES)
			get_property(dir TARGET ${target} PROPERTY SOURCE_DIR)
			foreach(file ${files})
                ccbGetPathRoot(root ${file})
                # Some source files have absolute paths and most not.
                # We ignore files that have absolute pathes for which we assume that they are the ones in the Generated directory.
                # Only the files in the Sources directory are used by doxygen.
                if(${root} STREQUAL NOTFOUND) 
                    list(APPEND allFiles "${dir}/${file}")
                endif()
			endforeach()
		endforeach()
	endforeach()
	
	set(${sourceFiles} ${allFiles} PARENT_SCOPE)

endfunction()


#----------------------------------------------------------------------------------------
# A custom target that generates the doxygen documentation for the whole project.
# In contrast to the target that is added with the ccbAddGlobalMonolithicDocumentationTarget() function
# This target uses the doxygen subtargets to run doxygen separately for all packages.
#
# Warning: The documentation generated with this target does include all classes in its
# class index due to this bug: https://bugzilla.gnome.org/show_bug.cgi?id=597928
#
# Arguments:
# PACKAGES A list of packages that contribute tag files as input for the documentation.
function( ccbAddGlobalDocumentationTarget )

	message(FATAL_ERROR "TODO: add doxyindexer command here and make sure the search works.")

	cmake_parse_arguments(ARG "" "" "PACKAGES" ${ARGN} )

	set(targetName generateDocumentation)
	
	# Locations
	set(tempDoxygenConfigFile ${CPPCODEBASE_GLOBAL_DOXYGEN_BIN_DIR}/tempDoxygenConfig.txt )
	set(globalHtmlOutputDir ${CPPCODEBASE_DOXYGEN_HTML_OUTPUT}/All)

    # Add a command to generate the the transitive reduced dependency graph of all targets.
    # The tred tool is from the graphviz suite and does the transitive reduction.
	# The generated file is used as input of the documentation.
	set(tredCommand "\"${TOOL_TRED}\" ${CCB_TARGET_DEPENDENCY_GRAPH_FILE} > ${reducedGraphFile}")
	ccbAddStandardCustomCommand(
		OUTPUT ${reducedGraphFile}
		DEPENDS ${CCB_TARGET_DEPENDENCY_GRAPH_FILE}
		COMMANDS ${tredCommand}
	)

	
	# Add a command to add the package tag files to the global doxygen configuration file.
	ccbGetDoxygenDependencies( doxygenSubTargets tagFiles PACKAGES ${ARG_PACKAGES})
	
	# The config file must contain the names of the depended on xml tag files of other doxygen sub-targets.
	list(APPEND appendedLines "DOTFILE_DIRS=\"${CCB_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}\"")
	list(APPEND appendedLines "OUTPUT_DIRECTORY=\"${globalHtmlOutputDir}\"")
	list(APPEND appendedLines "INPUT+=${CCB_SOURCE_DIR}/CppCodeBaseDocumentation.dox")
	list(APPEND appendedLines "INPUT+=${CCB_SOURCE_DIR}/CMakeGraphVizOptions.cmake")

	foreach( tagFile ${tagFiles})
		get_filename_component(extTagFileDir ${tagFile} DIRECTORY)
		file(RELATIVE_PATH relPath ${globalHtmlOutputDir} ${extTagFileDir})
		list(APPEND appendedLines "TAGFILES+=${tagFile}=${relPath}")
	endforeach()
	
	ccbAddAppendLinesToFileCommands( 
		INPUT ${doxygenConfigFile}
		OUTPUT ${tempDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)
	
	# add a command to copy the full dependency graph to the doxygen output dir
	get_filename_component(destShort ${CCB_TARGET_DEPENDENCY_GRAPH_FILE} NAME )
	set(copiedDependencyGraphFile ${CCB_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/${destShort})
	ccbAddCustomCommandCopyFile(${CCB_TARGET_DEPENDENCY_GRAPH_FILE} ${copiedDependencyGraphFile} )
	
	# Create the command for running doxygen
	set(doxygenCommand "\"${TOOL_DOXYGEN}\" ${tempDoxygenConfigFile}")
	set( targetStampFile ${CPPCODEBASE_GLOBAL_DOXYGEN_BIN_DIR}/globalDoxygenTarget.stamp)
	ccbAddStandardCustomCommand(
		OUTPUT ${targetStampFile}
		DEPENDS ${tempDoxygenConfigFile} ${tagFiles} ${copiedDependencyGraphFile} ${reducedGraphFile}
		COMMANDS ${doxygenCommand} "cmake -E touch ${targetStampFile}"
	)

	# Now add the target
	add_custom_target(
        ${targetName}
		DEPENDS ${targetStampFile} ${doxygenSubTargets}
    )

endfunction()


#----------------------------------------------------------------------------------------
# This function takes a list of package names and gets all the doxygen tag-file subtargets
# and tag-files.
# Arguments
# subtargets: Output variable that will contain all the doxygen tag subtargets.
# tagFiles: Output variable that will contain all the doxygen tag files.
# PACKAGES: A list of packages that may or may not have a generateDoxygenTags subtarget.
function( ccbGetDoxygenDependencies subtargetsArg tagFilesArg )

	cmake_parse_arguments(ARG "" "" "PACKAGES" ${ARGN} )

	foreach( library ${ARG_PACKAGES})
		get_property( subTarget TARGET ${library} PROPERTY CCB_DOXYGEN_SUBTARGET)
		if(subTarget)
			list(APPEND subTargets ${subTarget})
			get_property( tagFile TARGET ${subTarget} PROPERTY CCB_DOXYGEN_TAGSFILE)
			list(APPEND tagFiles ${tagFile})
		endif()
	endforeach()
	
	set(${subtargetsArg} ${subTargets} PARENT_SCOPE)
	set(${tagFilesArg} ${tagFiles} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Creates a target that runs Doxygen on the given files and only creates an intermediate xml tag file.
# Arguments: 
# PACKAGE: The package name
# LINKED_LIBRARIES: The dependencies of the package.
# DOCUMENTED_SOURCE_FILES: The source files that are parsed by doxygen. They are used as dependency for the doxygen command to trigger reruns of doxygen.
function( ccbAddDoxygenSubTarget )

	cmake_parse_arguments(ARG "" PACKAGE "LINKED_LIBRARIES;DOCUMENTED_SOURCE_FILES" ${ARGN} )
	
	# Target name
	set( targetName ${ARG_PACKAGE}_runDoxygen)
	
	# Locations
	set( outputDir ${CPPCODEBASE_DOXYGEN_HTML_OUTPUT}/${ARG_PACKAGE})
	set(generatedDoxygenTagsfile ${outputDir}/${ARG_PACKAGE}Doxygen.tag )
	
	# Get tag files and doxygen targets of the dependencies.
	# The tag files are needed as an input for this doxygen run.
	ccbGetDoxygenDependencies( dependedOnDoxygenSubTargets dependedOnTagsFiles PACKAGES ${ARG_LINKED_LIBRARIES})
	
	# Add the target that generates the per target doxygen config file
	ccbAddDoxygenConfigurationTarget(
		OUTPUT_DIR ${outputDir}
		PACKAGE ${ARG_PACKAGE}
		GENERATED_TAG_FILE ${generatedDoxygenTagsfile}
		DOXYGEN_TAG_FILE_DEPENDENCIES ${dependedOnTagsFiles}
	)
	
	# Get the path to the doxygen config file
	get_property( configSubTarget TARGET ${ARG_PACKAGE} PROPERTY CCB_DOXYGEN_CONFIG_SUBTARGET )
	get_property( packageDoxygenConfigFile TARGET ${configSubTarget} PROPERTY CCB_DOXYGEN_CONFIG_FILE )
	
	# Transform source file names to full filenames
	foreach(file ${ARG_DOCUMENTED_SOURCE_FILES} )
		list(APPEND fullSourceFiles ${CMAKE_CURRENT_SOURCE_DIR}/${file} )
	endforeach()
	
	# Add the command for running doxygen
	set(doxygenCommand "\"${TOOL_DOXYGEN}\" \"${packageDoxygenConfigFile}\"")
	ccbAddStandardCustomCommand(
		OUTPUT ${generatedDoxygenTagsfile}
		DEPENDS ${packageDoxygenConfigFile} ${fullSourceFiles}
		COMMANDS ${doxygenCommand}
	)

	# Now add the target
	add_custom_target(
        ${targetName}
		DEPENDS ${generatedDoxygenTagsfile} ${dependedOnDoxygenSubTargets}
    )
	
	set_property(TARGET ${targetName} PROPERTY FOLDER ${ARG_PACKAGE}/private)
	set_property(TARGET ${targetName} PROPERTY CCB_DOXYGEN_TAGSFILE ${generatedDoxygenTagsfile})
	set_property(TARGET ${ARG_PACKAGE} PROPERTY CCB_DOXYGEN_SUBTARGET ${targetName})

endfunction()

#----------------------------------------------------------------------------------------
# This target generates the per target doxygen configuration file by copying the global
# doxygen configuration file and overwriting some options.
#
# Arguments: 
# PACKAGE: The package name
# DOXYGEN_TAG_FILE_DEPENDENCIES: Doxygen .xml tag files that deliver input for this targets tag file.
function( ccbAddDoxygenConfigurationTarget)

	cmake_parse_arguments(ARG "" "OUTPUT_DIR;PACKAGE;GENERATED_TAG_FILE" "DOXYGEN_TAG_FILE_DEPENDENCIES" ${ARGN} )

	set( targetName ${ARG_PACKAGE}_generateDoxygenConfig)

	# Locations
	set(packageDoxygenConfigFile ${CMAKE_CURRENT_BINARY_DIR}/${targetName}/${ARG_PACKAGE}DoxygenConfig.txt)

	# add commands for adding lines to the config files that override some values from the global file
	set(appendedLines
		"OUTPUT_DIRECTORY=\"${ARG_OUTPUT_DIR}\""				# the location where the tag file is generated
		"INPUT=\"${CMAKE_CURRENT_SOURCE_DIR}\""					# only parse this packages source directory
		"GENERATE_TAGFILE=\"${ARG_GENERATED_TAG_FILE}\""		# activate tag file generation
		"DOTFILE_DIRS="											# this option is only used in the global target
	)
	# The config file must contain the names of the depended on xml tag files of other doxygen sub-targets.
	foreach( tagFile ${ARG_DOXYGEN_TAG_FILE_DEPENDENCIES})
		get_filename_component(extTagFileDir ${tagFile} DIRECTORY)
		file(RELATIVE_PATH relPath ${ARG_OUTPUT_DIR} ${extTagFileDir})
		file(RELATIVE_PATH tagFileRelPath ${CCB_ROOT_DIR} ${tagFile})
		list(APPEND appendedLines "TAGFILES+=${tagFileRelPath}=${relPath}")
	endforeach()

	ccbAddAppendLinesToFileCommands( 
		INPUT ${doxygenConfigFile}
		OUTPUT ${packageDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)

	# Now add the target
	add_custom_target(
        ${targetName}
		DEPENDS ${packageDoxygenConfigFile}
    )
	
	# Set properties
	set_property(TARGET ${targetName} PROPERTY FOLDER ${ARG_PACKAGE}/private)
	set_property(TARGET ${targetName} PROPERTY CCB_DOXYGEN_CONFIG_FILE ${packageDoxygenConfigFile})
	set_property(TARGET ${ARG_PACKAGE} PROPERTY CCB_DOXYGEN_CONFIG_SUBTARGET ${targetName})

endfunction()

#-------------------------------------------------------------------------
# This targets generates .dox files that provide the doxygen documentation for the package.
# The documentation ccbContains the given briefDescription, longDescription and links to the packages distribution
# packages, coverage reports and abi/api compatibility reports.
# The documentation can be extended by using \addtogroup <package>Group in another doxygen comment.
#
# Problem:
# We have the fundamental problem, that we want to link to pages, that may not be available for the
# current configuration, but which are generated by building another configuration. To solve this
# problem, groups of optional links where pulled out into separate pages that may or may not be generated 
# by the current configuration. Having the links in separate pages enables merging the html output of multiple
# configurations together, by simply copying the html directories of all configurations into each other. 
# However, as we have no knowledge here, which other build configurations may exist, we have to
# link to all possible generated pages, which leads to broken links if those pages are not generated
# by another configuration. Also the content of "Replated Pages" tab depends on which configuration
# was build last.
# 
# Despite all these problems, this solution seemed to be the most practical one.
# 
function( ccbAddPackageDocsTarget fileOut package packageNamespace briefDescription longDescription)

	if(NOT CCB_ENABLE_DOXYGEN_TARGET)
		return()
	endif()

	ccbGetGeneratedDocumentationDirectory(documentationDir)
	file(MAKE_DIRECTORY ${documentationDir} )

	ccbGetPackageDoxFilesTargetName( targetName ${package} )

	# Generate the OpenCppCoverageReport output only when compiling the configuration that generates it.
	ccbAddOpenCppCoverageLinksPageCommands( stampFile openCppCoverageLinksDoxFile openCppCoverageLinksHtmlFile ${targetName} ${package} )

	# Optionally add commands for creating the page with the links to the abi compatibility reports.
	ccbAddCompatiblityReportsLinksPageCommands( compatibilityReportLinksDoxFile compatibilityReportsLinkHtmlFile ${package} )

	# Always create the basic package documentation page.	
	ccbAddPackageDocumentationDoxFileCommands( documentationFile ${package} ${openCppCoverageLinksHtmlFile} ${compatibilityReportsLinkHtmlFile} )

	add_custom_target(
		${targetName}
		DEPENDS ${documentationFile} ${compatibilityReportLinksDoxFile} ${stampFile}
	)
	set_property(TARGET ${targetName} PROPERTY CCB_OUTPUT_FILES ${documentationFile} ${compatibilityReportLinksDoxFile} ${openCppCoverageLinksDoxFile} )

	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private" )

endfunction()

#-------------------------------------------------------------------------
function( ccbGetPackageDoxFilesTargetName targetNameOut package)
	set(${targetNameOut} packageDoxFiles_${package} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( ccbGetGeneratedDocumentationDirectory dirOut )
	set(${dirOut} "${CMAKE_BINARY_DIR}/${CCB_GENERATED_DOCS_DIR}" PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( ccbAddPackageDocumentationDoxFileCommands fileOut package openCppCoverageLinksPage compatibilityReportsLinkPage )

	set( fileContent "
/// The namespace of the ${package} package.
namespace ${packageNamespace} {

/**

\\defgroup ${package}Group ${package}
\\brief ${briefDescription}

${longDescription}

### Links ###

\\note The links can be broken if no project configuration generates the linked pages.

- <a href=\"../Downloads/${package}\">Downloads</a>
- <a href=\"${openCppCoverageLinksPage}\">OpenCppCoverage Reports</a>
"
)
	
	# executable packages do never have compatibility reports.
	get_property( type TARGET ${package} PROPERTY TYPE)
	if(NOT ${type} STREQUAL EXECUTABLE)
		string(APPEND fileContent "- <a href=\"${compatibilityReportsLinkPage}\">ABI/API Compatibility Reports</a>\n" )
	endif()

	string(APPEND fileContent "\n*/}\n")
	
	ccbGetPackageDocumentationFileName( fileName ${package} )
	ccbGetWriteFileCommands( commands ${fileName} ${fileContent} )
	add_custom_command(
		OUTPUT "${fileName}"
		${commands}
		VERBATIM
	)

	set(${fileOut} ${fileName} PARENT_SCOPE)

endfunction()

#-------------------------------------------------------------------------
function( ccbGetPackageDocumentationFileName fileOut package )
	ccbGetGeneratedDocumentationDirectory(documentationDir)
	set( ${fileOut} "${documentationDir}/${package}Documentation.dox" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# stamp file is only set when the config is not the config that generates the coverage report
# doxFileOut is only set when the config is the config that generates the coverage report
function( ccbAddOpenCppCoverageLinksPageCommands stampFileOut doxFileOut htmlFileOut target package )

	string(TOLOWER ${package} lowerPackage) # doxygen html pages only use lower case with spaces.
	set(htmlFileBaseName open_cpp_coverage_reports_${lowerPackage})

	# Add links to OpenCppCoverage reports
	ccbGetFirstMSVCDebugConfig( msvcDebugConfig )
	if( msvcDebugConfig AND CCB_ENABLE_DYNAMIC_ANALYSIS_TARGET )
		
		ccbGetGeneratedDocumentationDirectory(documentationDir)
		set(doxFile "${documentationDir}/${package}OpenCppCoverageReportLinks.dox" )

		# Assemble file content.
		set(fileContent)
		list(APPEND fileContent "/**")
		list(APPEND fileContent "\\page ${htmlFileBaseName} ${package} OpenCppCoverage Reports")
		set(index 0)
		ccbGetOpenCppCoverageReportFiles( reports titles ${package} )
		foreach( report ${reports} )
			list(GET titles ${index} title )
			list(APPEND fileContent "- <a href=\"../${report}\">${title}</a>")
			ccbIncrement(index)
		endforeach()
		list(APPEND fileContent "*/")

		# Add custom command that generates the file for the fitting configuration.
		set( stampFile "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/${target}/generateOpenCppCoverageLinkFile.stamp")
		
		set(deleteFileCommand "cmake -E remove -f \"${doxFile}\"")

		set( writeFileCommands )
		foreach( line IN LISTS fileContent )
			list(APPEND writeFileCommands "cmake -DFILE=\"${doxFile}\" -DLINE=\"${line}\" -P \"${DIR_OF_DOCUMENTATION_TARGET_FILE}/../Scripts/appendLineToFile.cmake\"" )
		endforeach()

		set(touchCommand "cmake -E touch \"${stampFile}\"")

		ccbAddConfigurationDependendCommand(
			TARGET ${target}
			COMMENT "Generate \"${doxFile}\""
			CONFIG ${msvcDebugConfig}
			OUTPUT ${stampFile}
			COMMANDS_CONFIG ${deleteFileCommand} ${writeFileCommands} ${touchCommand}
			COMMANDS_NOT_CONFIG	${touchCommand}
		)

	endif()

	set(${htmlFileOut} ${htmlFileBaseName}.html PARENT_SCOPE)
	set(${doxFileOut} ${doxFile} PARENT_SCOPE)
	set(${stampFileOut} ${stampFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbGetOpenCppCoverageReportFiles relReportPathsOut titlesOut package )
	
	set(reports)
	set(titles)

	ccbGetFirstMSVCDebugConfig( msvcDebugConfig )
	
	get_property( prodLib TARGET ${package} PROPERTY CCB_PRODUCTION_LIB_SUBTARGET )
	get_property( fixtureLib TARGET ${package} PROPERTY CCB_TEST_FIXTURE_SUBTARGET)
	get_property( testExe TARGET ${package} PROPERTY CCB_TESTS_SUBTARGET)
	set(targets ${prodLib} ${fixtureLib} ${testExe})
	
	foreach( target ${targets})
		ccbToConfigSuffix( configSuffix ${msvcDebugConfig} )
		get_property( pdbOutput TARGET ${target} PROPERTY PDB_NAME${configSuffix}) # reports are generated for all targets that have linker generated .pdb files.
		if(pdbOutput)
			ccbGetTargetOutputBaseName( baseName ${target} ${msvcDebugConfig})
			list( APPEND reports "${CCB_OPENCPPCOVERAGE_DIR}/Modules/${baseName}.html" )
			list( APPEND titles "${baseName}" )
		endif()
	endforeach()

	set(${relReportPathsOut} ${reports} PARENT_SCOPE)
	set(${titlesOut} ${titles} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( ccbAddCompatiblityReportsLinksPageCommands doxFileOut htmlFileOut package )
	
	string(TOLOWER ${package} lowerPackage) # doxygen html pages only use lower case with spaces.
	set(htmlFileBaseName compatibilitiy_reports_${lowerPackage})
	set(doxFile)

	# Add links to available abi reports
	if(CCB_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS)
		
		ccbGetGeneratedDocumentationDirectory(documentationDir)
		set(doxFile "${documentationDir}/${package}CompatibilityReportLinks.dox" )

		set(fileContent)
		string(APPEND fileContent "/**")
		string(APPEND fileContent "\n")
		string(APPEND fileContent "\\page ${htmlFileBaseName} ${package} ABI/API Compatibility Reports\n")
	
		ccbGetSharedLibrarySubTargets( libraryTargets ${package})
		if(libraryTargets)
			list(REVERSE libraryTargets) # put main-lib first
		endif()
		foreach( libraryTarget ${libraryTargets})
		
			string(APPEND fileContent "\n")
			string(APPEND fileContent "### ${libraryTarget} ###\n")

			ccbGetAvailableCompatibilityReports( reports titles ${package} ${libraryTarget} )

			set(index 0)
			foreach(report ${reports})
				list(GET titles ${index} title )
				string(APPEND fileContent "- <a href=\"../${report}\">${title}</a>\n")
				ccbIncrement(index)
			endforeach()
		
		endforeach()

		string(APPEND fileContent "*/\n")

		ccbGetWriteFileCommands( commands ${doxFile} ${fileContent} )
		add_custom_command(
			OUTPUT "${doxFile}"
			${commands}
			VERBATIM
		)

	endif()

	set(${htmlFileOut} ${htmlFileBaseName}.html PARENT_SCOPE)
	set(${doxFileOut} ${doxFile} PARENT_SCOPE)

endfunction()

#-------------------------------------------------------------------------
function( ccbGetAvailableCompatibilityReports reportsOut titlesOut package binaryTarget)

	set(reports)
	set(titles)
		
	# first we create a list of reports that could possibly exist
		
	# Handle the two reports that compare the current version to the last build and last release.
	# We always add links for those because they will be created with this build.
	get_property( currentVersion TARGET ${binaryTarget} PROPERTY VERSION )
	ccbGetLastBuildAndLastReleaseVersion( lastBuildVersion lastReleaseVersion)
	ccbGetReportBaseNamesAndOutputDirs( reportDirs reportBaseNames ${package} ${binaryTarget} ${currentVersion} "${lastBuildVersion};${lastReleaseVersion}")
	set( thisBuildReportsTitles "Last build to current build" "Last release to current build" )
		
	set(index 0)
	foreach( reportDir ${reportDirs} )
		list(GET reportBaseNames ${index} baseName)
		list(GET thisBuildReportsTitles ${index} title)
			
		list(APPEND reports "${reportDir}/${baseName}.html")
		list(APPEND titles ${title} )
			
		ccbIncrement(index)
	endforeach()
		
	# Now handle the reports for between old releases.
	# They may not exist anymore, so we check on the web-page which are
	# still available.
	ccbGetReleaseVersionTags( releaseVersions ${CMAKE_CURRENT_SOURCE_DIR})
	set(youngerVersion)
	foreach( version ${releaseVersions})
		if(youngerVersion)

			ccbGetReportBaseNamesAndOutputDirs( reportDir reportBaseName ${package} ${binaryTarget} ${youngerVersion} ${version} )
			set( relReportPath "${reportDir}/${reportBaseName}.html" )
			set( reportWebUrl "${CCB_WEBPAGE_URL}/${relReportPath}")
			
			ccbUrlExists( reportExists ${reportWebUrl} )
			if(reportExists)
				list(APPEND reports "${relReportPath}")
				list(APPEND titles "${version} to ${youngerVersion}" )
			endif()
				
		endif()
		set(youngerVersion ${version})
	endforeach()

	set( ${reportsOut} ${reports} PARENT_SCOPE )
	set( ${titlesOut} ${titles} PARENT_SCOPE)

endfunction()


#-------------------------------------------------------------------------
function( ccbUrlExists boolOut url )
	
	set( exists TRUE )

	if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL Linux )
		# With curl we do not have to download the file for checking if it exists.
		execute_process(
			COMMAND curl;--output;/dev/null;--silent;--head;--fail;--connect-timeout 0.1;${url}
			RESULT_VARIABLE result
		)
		if( NOT result EQUAL 0)
			set( exists FALSE )
		endif()

	else()
		# For windows we try to download the file.
		set( downloadedFile "${CMAKE_BINARY_DIR}/${CCB_PRIVATE_DIR}/downloadTest.html")
		file(DOWNLOAD ${url} ${downloadedFile} INACTIVITY_TIMEOUT 1 STATUS status)
		list(GET status 0 result)
		if( NOT result EQUAL 0)
			set( exists FALSE )
		else()
			# clean up the file
			file( REMOVE ${downloadedFile})
		endif()
	endif()

	set(${boolOut} ${exists} PARENT_SCOPE)
	
endfunction()