
include(cpfLocations)
include(cpfBaseUtilities)
include(cpfProjectUtilities)
include(cpfGitUtilities)
include(cpfCustomTargetUtilities)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDynamicAnalysisTarget)

set(DIR_OF_DOCUMENTATION_TARGET_FILE ${CMAKE_CURRENT_LIST_DIR})

#----------------------------------------------------------------------------------------
# Adds a target that runs doxygen on the whole Source directory of the CPF project.
#
# This function should be removed when the problems with the cpfAddGlobalDocumentationTarget() generation get fixed.
function( cpfAddGlobalMonolithicDocumentationTarget packages externalPackages)

	if(NOT CPF_ENABLE_DOXYGEN_TARGET)
		return()
	endif()

	set(targetName documentation)

	# Locations
	set(targetBinaryDir "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${targetName}" )
	set(tempDoxygenConfigFile "${targetBinaryDir}/tempDoxygenConfig.txt" )
	set(reducedGraphFile "${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/CPFDependenciesTransitiveReduced.dot")
	set(doxygenConfigFile "${CMAKE_SOURCE_DIR}/DoxygenConfig.txt")
	set(doxygenLayoutFile "${CMAKE_SOURCE_DIR}/DoxygenLayout.xml")
	set(htmlCgiBinDir "${CPF_PROJECT_HTML_ABS_DIR}/${CPF_CGI_BIN_DIR}" )

	# Generate the DoxygenConfig.txt file if it does not exist.
	if(NOT EXISTS ${doxygenConfigFile} )
		# we use the manual check and copy instead of configure_file() to prevent overwriting the file when the template changes.
		file( COPY "${DIR_OF_DOCUMENTATION_TARGET_FILE}/../Templates/DoxygenConfig.txt.in" DESTINATION ${doxygenConfigFile} )
	endif()

	# Generate the DoxygenLayout.xml file if it does not exist.
	if(NOT EXISTS ${doxygenLayoutFile} )
		# we use the manual check and copy instead of configure_file() to prevent overwriting the file when the template changes.
		file( COPY "${DIR_OF_DOCUMENTATION_TARGET_FILE}/../Templates/DoxygenLayout.xml.in" DESTINATION ${doxygenLayoutFile} )
	endif()

	# Get dependencies
	set(fileDependencies)
	set(targetDependencies)
	set(hasGeneratedDocumentation FALSE)
	foreach( package ${packages})
		cpfGetPackageDoxFilesTargetName( doxFilesTarget ${package} )
		if( TARGET ${doxFilesTarget}) # not all packages may have the doxFilesTarget
			list(APPEND targetDependencies ${doxFilesTarget})
			get_property( generatedDoxFiles TARGET ${doxFilesTarget} PROPERTY CPF_OUTPUT_FILES )
			list(APPEND fileDependencies ${generatedDoxFiles})
			set(hasGeneratedDocumentation TRUE)
		endif()
	endforeach()

	# Add a command to generate the the transitive reduced dependency graph of all targets.
    # The tred tool is from the graphviz suite and does the transitive reduction.
	# The generated file is used as input of the documentation.
	get_filename_component(reducedDepGraphDir ${reducedGraphFile} DIRECTORY)
	set(tredCommand "\"${TOOL_TRED}\" \"${CPF_TARGET_DEPENDENCY_GRAPH_FILE}\" > \"${reducedGraphFile}\"")
	cpfAddStandardCustomCommand(
		OUTPUT ${reducedGraphFile}
		DEPENDS ${CPF_TARGET_DEPENDENCY_GRAPH_FILE}
		COMMANDS "cmake -E make_directory \"${reducedDepGraphDir}\"" ${tredCommand}
	)

	# add a command to copy the full dependency graph to the doxygen output dir
	get_filename_component(destShort ${CPF_TARGET_DEPENDENCY_GRAPH_FILE} NAME )
	set(copiedDependencyGraphFile ${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/${destShort})
	cpfAddCustomCommandCopyFile(${CPF_TARGET_DEPENDENCY_GRAPH_FILE} ${copiedDependencyGraphFile} )

	# The config file must contain the names of the depended on xml tag files of other doxygen sub-targets.
	list(APPEND appendedLines "PROJECT_NAME  = ${PROJECT_NAME}")
	list(APPEND appendedLines "DOTFILE_DIRS = \"${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}\"")
	list(APPEND appendedLines "OUTPUT_DIRECTORY = \"${CPF_DOXYGEN_OUTPUT_ABS_DIR}\"")
	list(APPEND appendedLines "INPUT = \"${CMAKE_SOURCE_DIR}\"")
	if(hasGeneratedDocumentation)
		list(APPEND appendedLines "INPUT += \"${CMAKE_BINARY_DIR}/${CPF_GENERATED_DOCS_DIR}\"")
	endif()
	foreach( externalPackage ${externalPackages})
		list(APPEND appendedLines "EXCLUDE += \"${CMAKE_SOURCE_DIR}/${externalPackage}\"")
	endforeach()

	# TODO get plantuml.jar with hunter
	if(CPF_PLANT_UML_JAR)
		message( STATUS "Enable UML diagrams in doxygen comments.")
		list(APPEND appendedLines "PLANTUML_JAR_PATH = \"${CPF_PLANT_UML_JAR}\"")
	endif()

	# Test custom stylesheet
	#list(APPEND appendedLines "HTML_EXTRA_STYLESHEET = \"${CMAKE_SOURCE_DIR}/${CPF_CMAKE_DIR}/Templates/customdoxygen.css\"")

	cpfAddAppendLinesToFileCommands( 
		INPUT ${doxygenConfigFile}
		OUTPUT ${tempDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)

	# Add the command for running doxygen
	set( doxygenCommand "\"${TOOL_DOXYGEN}\" \"${tempDoxygenConfigFile}\"")
	set( searchDataXmlFile ${CPF_DOXYGEN_OUTPUT_ABS_DIR}/searchdata.xml)
	cpfGetAllNonGeneratedPackageSources(sourceFiles "${packages}")
	cpfAddStandardCustomCommand(
		OUTPUT ${searchDataXmlFile}
		DEPENDS ${tempDoxygenConfigFile} ${copiedDependencyGraphFile} ${reducedGraphFile} ${sourceFiles} ${linkFiles} ${fileDependencies}
		COMMANDS ${doxygenCommand}
	)

	# Create the command for running the doxyindexer.
	# The doxyindexer creates the content of the doxysearch.dp directory which is used by the doxysearch.cgi script 
	# when using the search function of the documentation
	set(doxyIndexerCommand "\"${TOOL_DOXYINDEXER}\" -o \"${htmlCgiBinDir}\" \"${searchDataXmlFile}\"" )
	set(doxyIndexerStampFile ${targetBinaryDir}/doxyindexer.stamp)
	cpfAddStandardCustomCommand(
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
function( cpfGetAllNonGeneratedPackageSources sourceFiles packages )

	foreach( package ${packages})
		if(TARGET ${package}) # non-cpf packages may not have targets set to them
			get_property(binaryTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS )
			foreach( target ${binaryTargets} globalFiles)
				get_property(files TARGET ${target} PROPERTY SOURCES)
				get_property(dir TARGET ${target} PROPERTY SOURCE_DIR)
				foreach(file ${files})
					cpfGetPathRoot(root ${file})
					# Some source files have absolute paths and most not.
					# We ignore files that have absolute pathes for which we assume that they are the ones in the Generated directory.
					# Only the files in the Sources directory are used by doxygen.
					if(${root} STREQUAL NOTFOUND) 
						list(APPEND allFiles "${dir}/${file}")
					endif()
				endforeach()
			endforeach()
		endif()
	endforeach()
	
	set(${sourceFiles} ${allFiles} PARENT_SCOPE)

endfunction()


#----------------------------------------------------------------------------------------
# A custom target that generates the doxygen documentation for the whole project.
# In contrast to the target that is added with the cpfAddGlobalMonolithicDocumentationTarget() function
# This target uses the doxygen subtargets to run doxygen separately for all packages.
#
# Warning: The documentation generated with this target does include all classes in its
# class index due to this bug: https://bugzilla.gnome.org/show_bug.cgi?id=597928
#
# Arguments:
# PACKAGES A list of packages that contribute tag files as input for the documentation.
function( cpfAddGlobalDocumentationTarget )

	message(FATAL_ERROR "TODO: add doxyindexer command here and make sure the search works.")

	cmake_parse_arguments(ARG "" "" "PACKAGES" ${ARGN} )

	set(targetName generateDocumentation)
	
	# Locations
	set(tempDoxygenConfigFile ${CPF_GLOBAL_DOXYGEN_BIN_DIR}/tempDoxygenConfig.txt )
	set(globalHtmlOutputDir ${CPF_DOXYGEN_HTML_OUTPUT}/All)

    # Add a command to generate the the transitive reduced dependency graph of all targets.
    # The tred tool is from the graphviz suite and does the transitive reduction.
	# The generated file is used as input of the documentation.
	set(tredCommand "\"${TOOL_TRED}\" ${CPF_TARGET_DEPENDENCY_GRAPH_FILE} > ${reducedGraphFile}")
	cpfAddStandardCustomCommand(
		OUTPUT ${reducedGraphFile}
		DEPENDS ${CPF_TARGET_DEPENDENCY_GRAPH_FILE}
		COMMANDS ${tredCommand}
	)

	# Add a command to add the package tag files to the global doxygen configuration file.
	cpfGetDoxygenDependencies( doxygenSubTargets tagFiles PACKAGES ${ARG_PACKAGES})
	
	# The config file must contain the names of the depended on xml tag files of other doxygen sub-targets.
	list(APPEND appendedLines "DOTFILE_DIRS=\"${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}\"")
	list(APPEND appendedLines "OUTPUT_DIRECTORY=\"${globalHtmlOutputDir}\"")
	list(APPEND appendedLines "INPUT+=${CPF_SOURCE_DIR}")

	foreach( tagFile ${tagFiles})
		get_filename_component(extTagFileDir ${tagFile} DIRECTORY)
		file(RELATIVE_PATH relPath ${globalHtmlOutputDir} ${extTagFileDir})
		list(APPEND appendedLines "TAGFILES+=${tagFile}=${relPath}")
	endforeach()
	
	cpfAddAppendLinesToFileCommands( 
		INPUT ${doxygenConfigFile}
		OUTPUT ${tempDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)
	
	# add a command to copy the full dependency graph to the doxygen output dir
	get_filename_component(destShort ${CPF_TARGET_DEPENDENCY_GRAPH_FILE} NAME )
	set(copiedDependencyGraphFile ${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/${destShort})
	cpfAddCustomCommandCopyFile(${CPF_TARGET_DEPENDENCY_GRAPH_FILE} ${copiedDependencyGraphFile} )
	
	# Create the command for running doxygen
	set(doxygenCommand "\"${TOOL_DOXYGEN}\" ${tempDoxygenConfigFile}")
	set( targetStampFile ${CPF_GLOBAL_DOXYGEN_BIN_DIR}/globalDoxygenTarget.stamp)
	cpfAddStandardCustomCommand(
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
function( cpfGetDoxygenDependencies subtargetsArg tagFilesArg )

	cmake_parse_arguments(ARG "" "" "PACKAGES" ${ARGN} )

	foreach( library ${ARG_PACKAGES})
		get_property( subTarget TARGET ${library} PROPERTY CPF_DOXYGEN_SUBTARGET)
		if(subTarget)
			list(APPEND subTargets ${subTarget})
			get_property( tagFile TARGET ${subTarget} PROPERTY CPF_DOXYGEN_TAGSFILE)
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
function( cpfAddDoxygenSubTarget )

	cmake_parse_arguments(ARG "" PACKAGE "LINKED_LIBRARIES;DOCUMENTED_SOURCE_FILES" ${ARGN} )
	
	# Target name
	set( targetName ${ARG_PACKAGE}_runDoxygen)
	
	# Locations
	set( outputDir ${CPF_DOXYGEN_HTML_OUTPUT}/${ARG_PACKAGE})
	set(generatedDoxygenTagsfile ${outputDir}/${ARG_PACKAGE}Doxygen.tag )
	
	# Get tag files and doxygen targets of the dependencies.
	# The tag files are needed as an input for this doxygen run.
	cpfGetDoxygenDependencies( dependedOnDoxygenSubTargets dependedOnTagsFiles PACKAGES ${ARG_LINKED_LIBRARIES})
	
	# Add the target that generates the per target doxygen config file
	cpfAddDoxygenConfigurationTarget(
		OUTPUT_DIR ${outputDir}
		PACKAGE ${ARG_PACKAGE}
		GENERATED_TAG_FILE ${generatedDoxygenTagsfile}
		DOXYGEN_TAG_FILE_DEPENDENCIES ${dependedOnTagsFiles}
	)
	
	# Get the path to the doxygen config file
	get_property( configSubTarget TARGET ${ARG_PACKAGE} PROPERTY CPF_DOXYGEN_CONFIG_SUBTARGET )
	get_property( packageDoxygenConfigFile TARGET ${configSubTarget} PROPERTY CPF_DOXYGEN_CONFIG_FILE )
	
	# Transform source file names to full filenames
	foreach(file ${ARG_DOCUMENTED_SOURCE_FILES} )
		list(APPEND fullSourceFiles ${CMAKE_CURRENT_SOURCE_DIR}/${file} )
	endforeach()
	
	# Add the command for running doxygen
	set(doxygenCommand "\"${TOOL_DOXYGEN}\" \"${packageDoxygenConfigFile}\"")
	cpfAddStandardCustomCommand(
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
	set_property(TARGET ${targetName} PROPERTY CPF_DOXYGEN_TAGSFILE ${generatedDoxygenTagsfile})
	set_property(TARGET ${ARG_PACKAGE} PROPERTY CPF_DOXYGEN_SUBTARGET ${targetName})

endfunction()

#----------------------------------------------------------------------------------------
# This target generates the per target doxygen configuration file by copying the global
# doxygen configuration file and overwriting some options.
#
# Arguments: 
# PACKAGE: The package name
# DOXYGEN_TAG_FILE_DEPENDENCIES: Doxygen .xml tag files that deliver input for this targets tag file.
function( cpfAddDoxygenConfigurationTarget)

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
		file(RELATIVE_PATH tagFileRelPath ${CPF_ROOT_DIR} ${tagFile})
		list(APPEND appendedLines "TAGFILES+=${tagFileRelPath}=${relPath}")
	endforeach()

	cpfAddAppendLinesToFileCommands( 
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
	set_property(TARGET ${targetName} PROPERTY CPF_DOXYGEN_CONFIG_FILE ${packageDoxygenConfigFile})
	set_property(TARGET ${ARG_PACKAGE} PROPERTY CPF_DOXYGEN_CONFIG_SUBTARGET ${targetName})

endfunction()

#-------------------------------------------------------------------------
# This targets generates .dox files that provide the doxygen documentation for the package.
# The documentation cpfContains the given briefDescription, longDescription and links to the packages distribution
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
function( cpfAddPackageDocsTarget fileOut package packageNamespace briefDescription longDescription)

	if(NOT CPF_ENABLE_DOXYGEN_TARGET)
		return()
	endif()

	cpfGetGeneratedDocumentationDirectory(documentationDir)
	file(MAKE_DIRECTORY ${documentationDir} )

	cpfGetPackageDoxFilesTargetName( targetName ${package} )

	# Generate the OpenCppCoverageReport output only when compiling the configuration that generates it.
	cpfAddOpenCppCoverageLinksPageCommands( stampFile openCppCoverageLinksDoxFile openCppCoverageLinksHtmlFile ${targetName} ${package} )

	# Optionally add commands for creating the page with the links to the abi compatibility reports.
	cpfAddCompatiblityReportsLinksPageCommands( compatibilityReportLinksDoxFile compatibilityReportsLinkHtmlFile ${package} )

	# Always create the basic package documentation page.	
	cpfAddPackageDocumentationDoxFileCommands( documentationFile ${package} ${openCppCoverageLinksHtmlFile} ${compatibilityReportsLinkHtmlFile} )

	add_custom_target(
		${targetName}
		DEPENDS ${documentationFile} ${compatibilityReportLinksDoxFile} ${openCppCoverageLinksDoxFile} # ${stampFile}
	)
	set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES ${documentationFile} ${compatibilityReportLinksDoxFile} ${openCppCoverageLinksDoxFile} )

	set_property( TARGET ${targetName} PROPERTY FOLDER "${package}/private" )

endfunction()

#-------------------------------------------------------------------------
function( cpfGetPackageDoxFilesTargetName targetNameOut package)
	set(${targetNameOut} packageDoxFiles_${package} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( cpfGetGeneratedDocumentationDirectory dirOut )
	set(${dirOut} "${CMAKE_BINARY_DIR}/${CPF_GENERATED_DOCS_DIR}" PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( cpfAddPackageDocumentationDoxFileCommands fileOut package openCppCoverageLinksPage compatibilityReportsLinkPage )

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
	
	cpfGetPackageDocumentationFileName( fileName ${package} )
	cpfGetWriteFileCommands( commands ${fileName} ${fileContent} )
	add_custom_command(
		OUTPUT "${fileName}"
		${commands}
		VERBATIM
	)

	set(${fileOut} ${fileName} PARENT_SCOPE)

endfunction()

#-------------------------------------------------------------------------
function( cpfGetPackageDocumentationFileName fileOut package )
	cpfGetGeneratedDocumentationDirectory(documentationDir)
	set( ${fileOut} "${documentationDir}/${package}Documentation.dox" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# stamp file is only set when the config is not the config that generates the coverage report
# doxFileOut is only set when the config is the config that generates the coverage report
function( cpfAddOpenCppCoverageLinksPageCommands stampFileOut doxFileOut htmlFileOut target package )

	string(TOLOWER ${package} lowerPackage) # doxygen html pages only use lower case with spaces.
	set(htmlFileBaseName open_cpp_coverage_reports_${lowerPackage})

	# Add links to OpenCppCoverage reports
	cpfGetFirstMSVCDebugConfig( msvcDebugConfig )
	if( msvcDebugConfig AND CPF_ENABLE_DYNAMIC_ANALYSIS_TARGET )
		
		cpfGetGeneratedDocumentationDirectory(documentationDir)
		set(doxFile "${documentationDir}/${package}OpenCppCoverageReportLinks.dox" )

		# Assemble file content.
		set(fileContent)
		list(APPEND fileContent "/**")
		list(APPEND fileContent "\\page ${htmlFileBaseName} ${package} OpenCppCoverage Reports")
		set(index 0)
		cpfGetOpenCppCoverageReportFiles( reports titles ${package} )
		foreach( report ${reports} )
			list(GET titles ${index} title )
			list(APPEND fileContent "- <a href=\"../${report}\">${title}</a>")
			cpfIncrement(index)
		endforeach()
		list(APPEND fileContent "*/")

		# Add custom command that generates the file for the fitting configuration.
		set( stampFile "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${target}/generateOpenCppCoverageLinkFile.stamp")
		
		set(deleteFileCommand "cmake -E remove -f \"${doxFile}\"")

		set( writeFileCommands )
		foreach( line IN LISTS fileContent )
			list(APPEND writeFileCommands "cmake -DFILE=\"${doxFile}\" -DLINE=\"${line}\" -P \"${DIR_OF_DOCUMENTATION_TARGET_FILE}/../Scripts/appendLineToFile.cmake\"" )
		endforeach()

		#set(touchCommand "cmake -E touch \"${stampFile}\"")
		set(touchCommand "cmake -E touch \"${doxFile}\"")

		cpfAddConfigurationDependendCommand(
			TARGET ${target}
			COMMENT "Generate \"${doxFile}\""
			CONFIG ${msvcDebugConfig}
			OUTPUT ${doxFile} #${stampFile}
			COMMANDS_CONFIG ${deleteFileCommand} ${writeFileCommands} #${touchCommand}
			COMMANDS_NOT_CONFIG	${touchCommand}
		)

	endif()

	set(${htmlFileOut} ${htmlFileBaseName}.html PARENT_SCOPE)
	set(${doxFileOut} ${doxFile} PARENT_SCOPE)
	set(${stampFileOut} ${stampFile} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetOpenCppCoverageReportFiles relReportPathsOut titlesOut package )
	
	set(reports)
	set(titles)

	cpfGetFirstMSVCDebugConfig( msvcDebugConfig )
	
	get_property( prodLib TARGET ${package} PROPERTY CPF_PRODUCTION_LIB_SUBTARGET )
	get_property( fixtureLib TARGET ${package} PROPERTY CPF_TEST_FIXTURE_SUBTARGET)
	get_property( testExe TARGET ${package} PROPERTY CPF_TESTS_SUBTARGET)
	set(targets ${prodLib} ${fixtureLib} ${testExe})
	
	foreach( target ${targets})
		cpfToConfigSuffix( configSuffix ${msvcDebugConfig} )
		get_property( pdbOutput TARGET ${target} PROPERTY PDB_NAME${configSuffix}) # reports are generated for all targets that have linker generated .pdb files.
		if(pdbOutput)
			cpfGetTargetOutputBaseName( baseName ${target} ${msvcDebugConfig})
			list( APPEND reports "${CPF_OPENCPPCOVERAGE_DIR}/Modules/${baseName}.html" )
			list( APPEND titles "${baseName}" )
		endif()
	endforeach()

	set(${relReportPathsOut} ${reports} PARENT_SCOPE)
	set(${titlesOut} ${titles} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
function( cpfAddCompatiblityReportsLinksPageCommands doxFileOut htmlFileOut package )
	
	string(TOLOWER ${package} lowerPackage) # doxygen html pages only use lower case with spaces.
	set(htmlFileBaseName compatibilitiy_reports_${lowerPackage})
	set(doxFile)

	# Add links to available abi reports
	if(CPF_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS)
		
		cpfGetGeneratedDocumentationDirectory(documentationDir)
		set(doxFile "${documentationDir}/${package}CompatibilityReportLinks.dox" )

		set(fileContent)
		string(APPEND fileContent "/**")
		string(APPEND fileContent "\n")
		string(APPEND fileContent "\\page ${htmlFileBaseName} ${package} ABI/API Compatibility Reports\n")
	
		cpfGetSharedLibrarySubTargets( libraryTargets ${package})
		if(libraryTargets)
			list(REVERSE libraryTargets) # put main-lib first
		endif()
		foreach( libraryTarget ${libraryTargets})
		
			string(APPEND fileContent "\n")
			string(APPEND fileContent "### ${libraryTarget} ###\n")

			cpfGetAvailableCompatibilityReports( reports titles ${package} ${libraryTarget} )

			set(index 0)
			foreach(report ${reports})
				list(GET titles ${index} title )
				string(APPEND fileContent "- <a href=\"../${report}\">${title}</a>\n")
				cpfIncrement(index)
			endforeach()
		
		endforeach()

		string(APPEND fileContent "*/\n")

		cpfGetWriteFileCommands( commands ${doxFile} ${fileContent} )
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
function( cpfGetAvailableCompatibilityReports reportsOut titlesOut package binaryTarget)

	set(reports)
	set(titles)
		
	# first we create a list of reports that could possibly exist
		
	# Handle the two reports that compare the current version to the last build and last release.
	# We always add links for those because they will be created with this build.
	get_property( currentVersion TARGET ${binaryTarget} PROPERTY VERSION )
	cpfGetLastBuildAndLastReleaseVersion( lastBuildVersion lastReleaseVersion)
	cpfGetReportBaseNamesAndOutputDirs( reportDirs reportBaseNames ${package} ${binaryTarget} ${currentVersion} "${lastBuildVersion};${lastReleaseVersion}")
	set( thisBuildReportsTitles "Last build to current build" "Last release to current build" )
		
	set(index 0)
	foreach( reportDir ${reportDirs} )
		list(GET reportBaseNames ${index} baseName)
		list(GET thisBuildReportsTitles ${index} title)
			
		list(APPEND reports "${reportDir}/${baseName}.html")
		list(APPEND titles ${title} )
			
		cpfIncrement(index)
	endforeach()
		
	# Now handle the reports for between old releases.
	# They may not exist anymore, so we check on the web-page which are
	# still available.
	cpfGetReleaseVersionTags( releaseVersions ${CMAKE_CURRENT_SOURCE_DIR})
	set(youngerVersion)
	foreach( version ${releaseVersions})
		if(youngerVersion)

			cpfGetReportBaseNamesAndOutputDirs( reportDir reportBaseName ${package} ${binaryTarget} ${youngerVersion} ${version} )
			set( relReportPath "${reportDir}/${reportBaseName}.html" )
			set( reportWebUrl "${CPF_WEBPAGE_URL}/${relReportPath}")
			
			cpfUrlExists( reportExists ${reportWebUrl} )
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
function( cpfUrlExists boolOut url )
	
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
		set( downloadedFile "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/downloadTest.html")
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