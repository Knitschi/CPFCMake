
# This file defines some globally available directories and file pathes.

include_guard(GLOBAL)

###### 
# DIRECTORIES
set(CPF_GENERATED_DIR Generated)				# The directory that holds all files that are generated.
set(CPF_SOURCE_DIR Sources)						# The directory that should hold all non generated files that are checked into the repository.
set(CPF_CONFIG_DIR Configuration)				# The directory that holds files that define cmake variables that are specific to the local project instance, like local paths to dependencies etc.
set(CPF_PACKAGES_ASSEMBLE_DIR _pckg)			# Utility directory which is used to copy the content of the packages together.
set(CPF_PRIVATE_DIR _CPF)						# A directory for storing generated helper files of the CMakeProjectFramework project.
set(CPF_INSTALL_STAGE InstallStage)             # The trailing directory in the default install prefix
set(CPF_CMAKE_DIR CPFCMake )					# The directory of the CPFCMake package
set(CPF_BUILDSCRIPTS_DIR CPFBuildscripts )			# The directory of the CPFBuildscripts package
set(CPF_JENKINSFILE_DIR CPFJenkinsfile )			# The directory of the CPFJenkinsfile package
set(CPF_MACHINES_DIR CPFMachines )					# The directory of the CPFMachines package
set(CPF_PROJECT_CONFIGURATIONS_DIR CIBuildConfigurations )	# The directory that contains project specific cmake configuration files.

# SPECIAL FILES
# The name of the target dependency graph file that is generated by cmake. 
# This must be the same value as given with the --graphviz option when running the configure step.
set(CPF_TARGET_DEPENDENCY_GRAPH_FILE "${CMAKE_BINARY_DIR}/CPFDependencies.dot")	
set(CPF_GRAPHVIZ_OPTIONS_FILE "CMakeGraphVizOptions.cmake" )

# Developer Config file related
set( CPF_PACKAGE_CONFIG_TEMPLATE ${CMAKE_SOURCE_DIR}/${CPF_CMAKE_DIR}/Templates/Config.cmake.in )
set( CPF_DEFAULT_CONFIGS_DIR DefaultConfigurations)
set( CPF_CONFIG_FILE_ENDING ".config.cmake")

# other ci-project files
set( CPF_CIBUILDCONFIGS_FILE "${CMAKE_SOURCE_DIR}/${CPF_PROJECT_CONFIGURATIONS_DIR}/cpfCIBuildConfigurations.json")
set( CPF_OWNED_PACKAGES_FILE "cpfOwnedPackages.cmake")

###### Parameterized locations ######

# returns the root directory of a package in a CPF project
function( cpfGetAbsPackageDirectory packageDirOut package cpfRootDir )
	set( ${packageDirOut} "${cpfRootDir}/${CPF_SOURCE_DIR}/${package}" PARENT_SCOPE)
endfunction()

# This function defines the name of a packages version file. 
# currently this is: cpfPackageVersion_<package>.cmake 
function( cpfGetPackageVersionFileName filenameOut package )
	set( ${filenameOut} cpfPackageVersion_${package}.cmake PARENT_SCOPE)
endfunction()

# Returns the absolute path to a packages version file
function( cpfGetAbsPathOfPackageVersionFile fullFilenameOut package cpfRootDir )
	cpfGetPackageVersionFileName( shortName ${package})
	cpfGetAbsPackageDirectory( packageDir ${package} ${cpfRootDir})
	set( ${fullFilenameOut} "${packageDir}/${shortName}" PARENT_SCOPE)
endfunction()

# This function defines the name of a packages c++ header version file. 
function( cpfGetPackageVersionCppHeaderFileName filenameOut package )
	set( ${filenameOut} cpfPackageVersion_${package}.h PARENT_SCOPE)
endfunction()

# This function defines the full path to the currently used config file.
function( cpfGetFullConfigFilePath filenameOut )
	set( ${filenameOut} "${CPF_ROOT_DIR}/${CPF_CONFIG_DIR}/${CPF_CONFIG}${CPF_CONFIG_FILE_ENDING}" PARENT_SCOPE)
endfunction()

# This function defines the relative dir from the html directory to the package release files of the last build
function( cpfGetRelLastBuildPackagesDir dirOut package)
	set( ${dirOut} ${CPF_DOWNLOADS_DIR}/${package}/${CPF_LAST_BUILD_DIR} PARENT_SCOPE)
endfunction()

# This function defines the relative dir from the html directory to the package release files of the release versions.
function( cpfGetRelReleasePackagesDir dirOut package version )
	set( ${dirOut} ${CPF_DOWNLOADS_DIR}/${package}/${version} PARENT_SCOPE)
endfunction()

# This function defines the relative path from the html directory to the directory that holds the abi compatibility report that compares the current build to the last build.
function( cpfGetRelCurrentToLastBuildReportDir dirOut package )
	set( ${dirOut} "${CPF_COMPATIBLITY_REPORTS_DIR}/${package}/${CPF_CURRENT_TO_LAST_BUILD_DIR}" PARENT_SCOPE )
endfunction()

# This function defines the relative path from the html directory to the directory that holds the abi compatibility report that compares the current build to the last release.
function( cpfGetRelCurrentToLastReleaseReportDir dirOut package )
	set( ${dirOut} "${CPF_COMPATIBLITY_REPORTS_DIR}/${package}/${CPF_CURRENT_TO_LAST_RELEASE_DIR}" PARENT_SCOPE )
endfunction()

# This function defines the relative path from the html directory to the directory that holds the abi compatibility report that compares two release versions.
function( cpfGetRelVersionToVersionReportDir dirOut package newVersion oldVersion )
	set( ${dirOut} "${CPF_COMPATIBLITY_REPORTS_DIR}/${package}/${oldVersion}-to-${newVersion}" PARENT_SCOPE)
endfunction()

###### Custom targets ######

# relative dirs
set( CPF_DOXYGEN_DIR doxygen )
set( CPF_DOXYGEN_EXTERNAL_DIR external)
set( CPF_GENERATED_DOCS_DIR documentation)						# A subdirectory in the CMAKE_BINARY_DIR that contains generated files that are used by doxygen.
set( CPF_DOCUMENTATION_DIR documentation)						# A subdirectroy in the sources tree that contains global documentation files.
set( CPF_DOWNLOADS_DIR Downloads )
set( CPF_LAST_BUILD_DIR LastBuild)
set( CPF_CGI_BIN_DIR cgi-bin )
set( CPF_OPENCPPCOVERAGE_DIR OpenCppCoverage )
set( CPF_COMPATIBLITY_REPORTS_DIR AbiCheckerReports )
set( CPF_CURRENT_TO_LAST_BUILD_DIR LastBuildToCurrent )
set( CPF_CURRENT_TO_LAST_RELEASE_DIR LastReleaseToCurrent )


# absolute dirs
set( CPF_ABS_TEMPLATE_DIR "${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/CPFCMake/Templates")							# The directory that holds the file templates of the CPFCMake package.
set( CPF_ABS_SCRIPT_DIR "${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/CPFCMake/Scripts")								# The directory that holds the scripts of the CPFCMake package.
set( CPF_PROJECT_HTML_ABS_DIR ${CMAKE_BINARY_DIR}/html)														# The directory that contains the html page of the project
set( CPF_DOXYGEN_OUTPUT_ABS_DIR ${CPF_PROJECT_HTML_ABS_DIR}/${CPF_DOXYGEN_DIR})								# The part of the project page that contains the doxygen output.
set( CPF_DOXYGEN_EXTERNAL_DOT_FILES_ABS_DIR  ${CPF_DOXYGEN_OUTPUT_ABS_DIR}/${CPF_DOXYGEN_EXTERNAL_DIR} )	# The directory within the doxygen documentation where the dependency graph files are put.
set( CPF_PREVIOUS_PACKAGES_ABS_DIR ${CMAKE_BINARY_DIR}/${CPF_PRIVATE_DIR}/PreviousPackages )				# The directory where the abi-compliance-checker targets download the previous packages to.
