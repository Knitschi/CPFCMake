include_guard(GLOBAL)

include(cpfLocations)
include(cpfProjectUtilities)
include(cpfGitUtilities)
include(cpfCustomTargetUtilities)
include(cpfAddCompatibilityCheckTarget)
include(cpfInitPackageProject)
include(cpfAddCppPackage)


#-----------------------------------------------------------
# Documentation in APIDocs.dox
#
function( cpfAddDoxygenPackage )

	set( optionalBoolKeywords
		RUN_DOXYINDEXER
	) 

	set( requiredSingleValueKeywords
		DOXYGEN_CONFIG_FILE
		DOXYGEN_LAYOUT_FILE
		DOXYGEN_STYLESHEET_FILE
	)

	set( optionalSingleValueKeywords
		PROJECT_NAME
		HTML_HEADER
		HTML_FOOTER
		PROJECT_LOGO
		PLANTUML_JAR_PATH
	)

	set( requiredMultiValueKeywords 
	)

	set( optionalMultiValueKeywords 
		SOURCES
		ADDITIONAL_PACKAGES
	)

	cmake_parse_arguments(
		ARG 
		"${optionalBoolKeywords}" 
		"${requiredSingleValueKeywords};${optionalSingleValueKeywords}"
		"${requiredMultiValueKeywords};${optionalMultiValueKeywords}"
		${ARGN}
	)

	cpfAssertKeywordArgumentsHaveValue( "${singleValueKeywords};${requiredMultiValueKeywords}" ARG "cpfAddDoxygenPackage()")
	cpfAssertProjectVersionDefined()

	cpfFindRequiredProgram( TOOL_DOXYGEN doxygen "A tool that generates documentation files by reading in-code comments")
	cpfFindRequiredProgram( TOOL_DOXYINDEXER doxyindexer "A tool that generates search indexes for doxygen generated html files")
	cpfFindRequiredProgram( TOOL_TRED tred "A tool from the graphviz library that creates a transitive reduced version of a graphviz graph")

	if(NOT ARG_PROJECT_NAME)
		set(ARG_PROJECT_NAME ${CPF_CI_PROJECT})
	endif()

	cpfGetPackageName( package )
	message(STATUS "Add Doxygen package ${package} at version ${PROJECT_VERSION}")

	# Locations
	set(targetBinaryDir "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/${package}" )
	set(tempDoxygenConfigFile "${targetBinaryDir}/tempDoxygenConfig.txt" )
	set(reducedGraphFile "${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}/CPFDependenciesTransitiveReduced.dot")
	set(htmlCgiBinDir "${CPF_PROJECT_HTML_ABS_DIR}/${CPF_CGI_BIN_DIR}" )
	set(doxygenHtmlSubdir html)

	# Get dependencies
	cpfGetOwnedPackages( documentedPackages ${CPF_ROOT_DIR})
	cpfListAppend(documentedPackages "${ARG_ADDITIONAL_PACKAGES}")
	set(fileDependencies)
	set(targetDependencies)
	set(hasGeneratedDocumentation FALSE)
	foreach( package ${documentedPackages})
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
	list(APPEND appendedLines "PROJECT_NAME  = ${ARG_PROJECT_NAME}")
	list(APPEND appendedLines "OUTPUT_DIRECTORY = \"${CPF_DOXYGEN_OUTPUT_ABS_DIR}\"")
	list(APPEND appendedLines "GENERATE_HTML = YES")
	list(APPEND appendedLines "HTML_OUTPUT = ${doxygenHtmlSubdir}")	# We set a fixed location, so we can be sure were files are when copying the documentation on the build-server.	
	list(APPEND appendedLines "DOTFILE_DIRS = \"${CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR}\"")
	list(APPEND appendedLines "LAYOUT_FILE = \"${ARG_DOXYGEN_LAYOUT_FILE}\"")
	list(APPEND appendedLines "HTML_EXTRA_STYLESHEET = \"${ARG_DOXYGEN_STYLESHEET_FILE}\"")
	if(ARG_HTML_HEADER)
		list(APPEND appendedLines "HTML_HEADER = \"${ARG_HTML_HEADER}\"")
	endif()
	if(ARG_HTML_FOOTER)
		list(APPEND appendedLines "HTML_FOOTER = \"${ARG_HTML_FOOTER}\"")
	endif()
	if(ARG_PROJECT_LOGO)
		list(APPEND appendedLines "PROJECT_LOGO = \"${ARG_PROJECT_LOGO}\"")
	endif()

	# Make sure the name of the searchdate.xml file is the one that we use here.
	set(searchDataXmlShortName searchdata.xml)
	list(APPEND appendedLines "SEARCHDATA_FILE = ${searchDataXmlShortName}")

	# input files
	list(APPEND appendedLines "INPUT = \"${CMAKE_SOURCE_DIR}\"")
	if(hasGeneratedDocumentation)
		cpfGetGeneratedDoxygenDirectory(docsDir)
		list(APPEND appendedLines "INPUT += \"${docsDir}\"")
	endif()

	# Exclude non-owned packages from the documentation unless they were not explicitly added to the documentation.
	cpfGetAllPackages( allPackages )
	foreach( package ${allPackages})
		cpfContains( isDocumented "${documentedPackages}" ${package} )
		if(NOT isDocumented)
			list(APPEND appendedLines "EXCLUDE += \"${CMAKE_SOURCE_DIR}/${package}\"")
		endif()
	endforeach()

	# Forward the path to the plantuml.jar
	if(ARG_PLANTUML_JAR_PATH)
		message( STATUS "Enable UML diagrams in doxygen comments.")
		list(APPEND appendedLines "PLANTUML_JAR_PATH = \"${ARG_PLANTUML_JAR_PATH}\"")
	endif()

	cpfAddAppendLinesToFileCommands( 
		INPUT ${ARG_DOXYGEN_CONFIG_FILE}
		OUTPUT ${tempDoxygenConfigFile}
		ADDED_LINES ${appendedLines} 
	)

	# Add the command for running doxygen
	set( doxygenCommand "\"${TOOL_DOXYGEN}\" \"${tempDoxygenConfigFile}\"")
	set( searchDataXmlFile ${CPF_DOXYGEN_OUTPUT_ABS_DIR}/${searchDataXmlShortName})
	cpfGetAllNonGeneratedPackageSources(packagSourceFiles "${documentedPackages}")
	set( allDependedOnFiles 
		${tempDoxygenConfigFile}
		${ARG_DOXYGEN_LAYOUT_FILE}
		${ARG_DOXYGEN_STYLESHEET_FILE}
		${ARG_SOURCES}
		${copiedDependencyGraphFile}
		${reducedGraphFile}
		${fileDependencies}
		${packagSourceFiles}
		)
	
	cpfAddStandardCustomCommand(
		DEPENDS ${allDependedOnFiles}
		COMMANDS ${doxygenCommand}
		OUTPUT ${searchDataXmlFile}
	)

	# Create the command for running the doxyindexer.
	# The doxyindexer creates the content of the doxysearch.dp directory which is used by the doxysearch.cgi script 
	# when using the search function of the documentation
	set(doxyIndexerStampFile)
	if(ARG_RUN_DOXYINDEXER)
		set(doxyIndexerCommand "\"${TOOL_DOXYINDEXER}\" -o \"${htmlCgiBinDir}\" \"${searchDataXmlFile}\"" )
		set(doxyIndexerStampFile ${targetBinaryDir}/doxyindexer.stamp)
		cpfAddStandardCustomCommand(
			OUTPUT ${doxyIndexerStampFile}
			DEPENDS ${searchDataXmlFile}
			COMMANDS "cmake -E make_directory \"${htmlCgiBinDir}\"" ${doxyIndexerCommand} "cmake -E touch \"${doxyIndexerStampFile}\""
		)
	endif()

	# Now add the target
	add_custom_target(
		${package}
		DEPENDS 
			${targetDependencies}
			${searchDataXmlFile}
			${doxyIndexerStampFile}
		SOURCES 
			${ARG_SOURCES}
			${ARG_DOXYGEN_CONFIG_FILE}
			${ARG_DOXYGEN_LAYOUT_FILE}
			${ARG_DOXYGEN_STYLESHEET_FILE}
			${ARG_HTML_HEADER}
			${ARG_HTML_FOOTER}
			${ARG_PROJECT_LOGO}
	)
	set_property( TARGET ${package} PROPERTY FOLDER ${package} )
	cpfSetIDEDirectoriesForTargetSources(${package})

	add_dependencies(pipeline ${package})

endfunction()

#----------------------------------------------------------------------------------------
# This function does a COPY_ONLY file configure if the target file does not exist yet.
# This function can be used when the created file should not be overwritten when
# the template file changes.
function( configureFileIfNotExists templateFile targetFile )
	if(NOT EXISTS ${targetFile} )
		# we use the manual existance check to prevent overwriting the file when the template changes.
		configure_file( ${templateFile} ${targetFile} COPYONLY )
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# read all sources from all binary targets of the given packages
function( cpfGetAllNonGeneratedPackageSources sourceFiles packages )

	foreach( package ${packages} globalFiles) # we also get the global files from the globalFiles target
		if(TARGET ${package}) # non-cpf packages may not have targets set to them
			get_property(binaryTargets TARGET ${package} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS )
			# explicitly include the package itself, because it may not be a binary target.
			set(targets ${binaryTargets} ${package})
			list(REMOVE_DUPLICATES targets)
			foreach( target ${targets} )
				get_property( sourceDir TARGET ${target} PROPERTY SOURCE_DIR)
				getAbsPathesForSourceFilesInDir( files ${target} ${sourceDir})
				list(APPEND allFiles ${files})
			endforeach()
		endif()
	endforeach()
	set(${sourceFiles} ${allFiles} PARENT_SCOPE)

endfunction()

#-------------------------------------------------------------------------
# This targets generates .dox files that provide the doxygen documentation for the package.
# The documentation contains the given briefDescription, longDescription and links to the packages distribution
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
function( cpfAddPackageDocsTarget package packageNamespace )

	cpfGetGeneratedDoxygenDirectory(documentationDir)
	file(MAKE_DIRECTORY ${documentationDir} )

	cpfGetPackageDoxFilesTargetName( targetName ${package} )

	# Always create the basic package documentation page.	
	cpfAddPackageDocumentationDoxFileCommands( documentationFile ${package} ${packageNamespace})

	add_custom_target(
		${targetName}
		DEPENDS ${documentationFile}
		SOURCES ${documentationFile}
	)

	set_property(TARGET ${targetName} PROPERTY CPF_OUTPUT_FILES ${documentationFile}  )
	set_property(TARGET ${targetName} PROPERTY FOLDER "${package}/private" )

endfunction()

#-------------------------------------------------------------------------
function( cpfGetPackageDoxFilesTargetName targetNameOut package)
	set(${targetNameOut} packageDoxFiles_${package} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( cpfGetGeneratedDoxygenDirectory dirOut )
	set(${dirOut} "${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/doxygen" PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------
function( cpfAddPackageDocumentationDoxFileCommands fileOut package packageNamespace )

	get_property( briefDescription TARGET ${package} PROPERTY CPF_BRIEF_PACKAGE_DESCRIPTION )
	get_property( longDescription TARGET ${package} PROPERTY CPF_LONG_PACKAGE_DESCRIPTION )

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
- <a href=\"../${CPF_OPENCPPCOVERAGE_DIR}/index.html\">OpenCppCoverage Reports</a> (Will work if at least one test target and the CPF_ENABLE_OPENCPPCOVERAGE_TARGET option is enabled for a windows build)

"
)

	# executable packages do never have compatibility reports.
	cpfIsExecutable(isExe ${package})
	if(NOT isExe)
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

	source_group(Generated FILES ${fileName})

	set(${fileOut} ${fileName} PARENT_SCOPE)

endfunction()

#-------------------------------------------------------------------------
function( cpfGetPackageDocumentationFileName fileOut package )
	cpfGetGeneratedDoxygenDirectory(documentationDir)
	set( ${fileOut} "${documentationDir}/${package}Documentation.dox" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetCompatiblityReportLinks linksOut package )
		
	cpfGetGeneratedDoxygenDirectory(documentationDir)
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
