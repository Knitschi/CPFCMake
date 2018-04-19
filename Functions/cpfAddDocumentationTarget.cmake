
include(cpfLocations)
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
function( cpfAddGlobalMonolithicDocumentationTarget packages externalPackages )

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
	if(NOT (EXISTS ${doxygenConfigFile}) )
		# we use the manual existance check to prevent overwriting the file when the template changes.
		configure_file( "${DIR_OF_DOCUMENTATION_TARGET_FILE}/../Templates/DoxygenConfig.txt.in" ${doxygenConfigFile} COPYONLY )
	endif()

	# Generate the DoxygenLayout.xml file if it does not exist.
	if(NOT EXISTS ${doxygenLayoutFile} )
		# we use the manual existance check to prevent overwriting the file when the template changes.
		configure_file( "${DIR_OF_DOCUMENTATION_TARGET_FILE}/../Templates/DoxygenLayout.xml.in" ${doxygenLayoutFile} COPYONLY )
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
		cpfGetGeneratedDocumentationDirectory(docsDir)
		list(APPEND appendedLines "INPUT += \"${docsDir}\"")
	endif()
	# Exclude external packges
	foreach( externalPackage ${externalPackages})
		list(APPEND appendedLines "EXCLUDE += \"${CMAKE_SOURCE_DIR}/${externalPackage}\"")
	endforeach()

	# TODO get plantuml.jar with hunter
	if(CPF_PLANT_UML_JAR)
		message( STATUS "Enable UML diagrams in doxygen comments.")
		list(APPEND appendedLines "PLANTUML_JAR_PATH = \"${CPF_PLANT_UML_JAR}\"")
	endif()

	cpfAddAppendLinesToFileCommands( 
		INPUT ${doxygenConfigFile}
		OUTPUT ${tempDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)

	# Add the command for running doxygen
	set( doxygenCommand "\"${TOOL_DOXYGEN}\" \"${tempDoxygenConfigFile}\"")
	set( searchDataXmlFile ${CPF_DOXYGEN_OUTPUT_ABS_DIR}/searchdata.xml)
	cpfGetAllNonGeneratedPackageSources(sourceFiles "${packages}")
	set( allDependedOnFiles ${tempDoxygenConfigFile} ${copiedDependencyGraphFile} ${reducedGraphFile} ${sourceFiles} ${fileDependencies} ${globalFiles} )
	cpfAddStandardCustomCommand(
		OUTPUT ${searchDataXmlFile}
		DEPENDS ${allDependedOnFiles}
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

	foreach( package ${packages} globalFiles) # we also get the global files from the globalFiles target
		if(TARGET ${package}) # non-cpf packages may not have targets set to them
			get_property(binaryTargets TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS )
			# explicitly include the package itself, because it may not be a binary target.
			set(targets ${binaryTargets} ${package})
			list(REMOVE_DUPLICATES targets)
			foreach( target ${targets} )
				getRelativeSourceFilesPaths( files ${target})
				list(APPEND allFiles ${files})
			endforeach()
		endif()
	endforeach()
	set(${sourceFiles} ${allFiles} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with all files from target property SOURCES that do not have an absolute
# path.
function( getRelativeSourceFilesPaths filePathsOut target)

	set(allFiles)
	get_property(files TARGET ${target} PROPERTY SOURCES)
	get_property(dir TARGET ${target} PROPERTY SOURCE_DIR)
	foreach(file ${files})
		# Some source files have absolute paths and most not.
		# We ignore files that have absolute pathes for which we assume that they are the ones in the Generated directory.
		# Only the files in the Sources directory are used by doxygen.
		cpfIsAbsolutePath( isAbsolute ${file})
		if(NOT isAbsolute) 
			list(APPEND relFiles "${dir}/${file}")
		endif()
	endforeach()
	set( ${filePathsOut} ${relFiles} PARENT_SCOPE)

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

	# Always create the basic package documentation page.	
	cpfAddPackageDocumentationDoxFileCommands( documentationFile ${package})

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
	set(${dirOut} "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${CPF_GENERATED_DOCS_DIR}" PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( cpfAddPackageDocumentationDoxFileCommands fileOut package )

	set( fileContent "
/// The namespace of the ${package} package.
namespace ${packageNamespace} {

/**

\\defgroup ${package}Group ${package}
\\brief ${briefDescription}

${longDescription}

### Links ###

\\note The links can be broken if no project configuration creates the linked pages.

- <a href=\"../${CPF_DOWNLOADS_DIR}/${package}\">Downloads</a> (Will work if distribution packages are created.)
- <a href=\"../${CPF_OPENCPPCOVERAGE_DIR}/index.html\">OpenCppCoverage Reports</a> (Will work if at least one test target and the CPF_ENABLE_DYNAMIC_ANALYSIS_TARGET option is enabled for a windows build)

"
)

	# executable packages do never have compatibility reports.
	get_property( type TARGET ${package} PROPERTY TYPE)
	if(NOT ${type} STREQUAL EXECUTABLE)
		cpfGetCompatiblityReportLinks(linksOut ${package})
		string(APPEND fileContent ${linksOut})
	endif()

	string(APPEND fileContent "\n*/}\n") # close the doxygen comment and the namespace
	
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
function( cpfGetCompatiblityReportLinks linksOut package )
		
	cpfGetGeneratedDocumentationDirectory(documentationDir)
	set(doxFile "${documentationDir}/${package}CompatibilityReportLinks.dox" )

	set(linkLines)

	cpfGetPossiblySharedLibrarySubTargets( libraryTargets ${package})
	foreach( libraryTarget ${libraryTargets})
	
		string(APPEND linkLines "\n")
		string(APPEND linkLines "#### ABI/API Compatibility Reports ${libraryTarget} ####\n")
		string(APPEND linkLines "The links will work if the package has a test target and the CPF_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS option is set for a Linux debug configuration.\n")
		string(APPEND linkLines "\n")

		cpfGetPossiblyAvailableCompatibilityReports( reports titles ${package} ${libraryTarget} )

		set(index 0)
		foreach(report ${reports})
			list(GET titles ${index} title )
			string(APPEND linkLines "- <a href=\"../${report}\">${title}</a>\n")
			cpfIncrement(index)
		endforeach()
	
	endforeach()

	set(${linksOut} ${linkLines} PARENT_SCOPE)

endfunction()

#-------------------------------------------------------------------------
function( cpfGetPossiblyAvailableCompatibilityReports reportsOut titlesOut package binaryTarget)

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
				
		endif()
		set(youngerVersion ${version})
	endforeach()

	set( ${reportsOut} ${reports} PARENT_SCOPE )
	set( ${titlesOut} ${titles} PARENT_SCOPE)

endfunction()
