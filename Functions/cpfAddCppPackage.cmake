# This file contains the functionality for adding a cpf package to a project.

include(GenerateExportHeader) # this must be put before the include_guard() or it wont work

include_guard(GLOBAL)

include(cpfInitPackageProject)
include(cpfLocations)
include(cpfConstants)
include(cpfProjectUtilities)
include(cpfGitUtilities)
include(cpfPathUtilities)
include(cpfTargetUtilities)

include(cpfAddClangTidyTarget)
include(cpfAddRunTestsTarget)
include(cpfAddDeploySharedLibrariesTarget)
include(cpfAddInstallRules)
include(cpfAddDistributionPackageTarget)
include(cpfAddCompatibilityCheckTarget)
include(cpfAddDoxygenPackage)


#[[-----------------------------------------------------------
# Documentation in APIDocs.dox
]]
function( cpfAddCppPackage )

	set( optionKeywords
		GENERATE_PACKAGE_DOX_FILES
	) 
	
	set( singleValueKeywords 
		PACKAGE_NAMESPACE
		TYPE
		BRIEF_DESCRIPTION
		LONG_DESCRIPTION
		HOMEPAGE
		MAINTAINER_EMAIL
		VERSION_COMPATIBILITY_SCHEME
		ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS
	)

	set( multiValueKeywords 
		PUBLIC_HEADER
		PRODUCTION_FILES
		PUBLIC_FIXTURE_HEADER
		FIXTURE_FILES
		TEST_FILES
		LINKED_LIBRARIES
		LINKED_TEST_LIBRARIES
		PLUGIN_DEPENDENCIES
		DISTRIBUTION_PACKAGES
	)

	# parse level 0 keywords
	cmake_parse_arguments(
		ARG 
		"${optionKeywords}" 
		"${singleValueKeywords}"
		"${multiValueKeywords}"
		${ARGN} 
	)

	# parse argument sublists
	set( allKeywords ${singleValueKeywords} ${multiValueKeywords})
	cpfGetKeywordValueLists( pluginOptionLists PLUGIN_DEPENDENCIES "${allKeywords}" "${ARGN}" pluginOptions)
	cpfGetKeywordValueLists( distributionPackageOptionLists DISTRIBUTION_PACKAGES "${allKeywords}" "${ARGN}" packagOptions)
	
	cpfDebugMessage("Add Package ${ARG_PACKAGE_NAME}")
	
	# By default build test targets.
	# Hunter sets this to off in order to skip test building.
	if( NOT "${${ARG_PACKAGE_NAME}_BUILD_TESTS}" STREQUAL OFF )
		set( ${ARG_PACKAGE_NAME}_BUILD_TESTS ON)
	endif()

	# ASERT ARGUMENTS

	# Make sure that linked targets have already been created.
	cpfDebugAssertLinkedLibrariesExists( linkedLibraries ${ARG_PACKAGE_NAME} "${ARG_LINKED_LIBRARIES}")
	cpfDebugAssertLinkedLibrariesExists( linkedTestLibraries ${ARG_PACKAGE_NAME} "${ARG_LINKED_TEST_LIBRARIES}")
	# If a library does not have a public header, it must be a user mistake
	if( (${ARG_TYPE} STREQUAL LIB) AND (NOT ARG_PUBLIC_HEADER) )
		message(FATAL_ERROR "Library package ${ARG_PACKAGE_NAME} has no public headers. The library can not be used without public headers, so please add the PUBLIC_HEADER argument to the cpfAddCppPackage() call.")
	endif()

	if(NOT ARG_VERSION_COMPATIBILITY_SCHEME)
		set(ARG_VERSION_COMPATIBILITY_SCHEME ExactVersion)
	endif()
	cpfAssertCompatibilitySchemeOption(${ARG_VERSION_COMPATIBILITY_SCHEME})

	# make sure that the properties of the imported targets follow our assumptions
	cpfNormalizeImportedTargetProperties( "${linkedLibraries};${linkedTestLibraries}" )

	# Add the binary targets
	cpfAddPackageBinaryTargets( 
		productionLibrary 
		${ARG_PACKAGE_NAME} 
		${ARG_PACKAGE_NAMESPACE} 
		${ARG_TYPE} 
		"${ARG_PUBLIC_HEADER}" 
		"${ARG_PRODUCTION_FILES}" 
		"${ARG_PUBLIC_FIXTURE_HEADER}" 
		"${ARG_FIXTURE_FILES}" 
		"${ARG_TEST_FILES}" 
		"${ARG_LINKED_LIBRARIES}" 
		"${ARG_LINKED_TEST_LIBRARIES}"
		${ARG_VERSION_COMPATIBILITY_SCHEME}
	)

	#set some properties
	set_property(TARGET ${ARG_PACKAGE_NAME} PROPERTY CPF_BRIEF_PACKAGE_DESCRIPTION ${ARG_BRIEF_DESCRIPTION} )
	set_property(TARGET ${ARG_PACKAGE_NAME} PROPERTY CPF_PACKAGE_HOMEPAGE ${ARG_HOMEPAGE} )
	set_property(TARGET ${ARG_PACKAGE_NAME} PROPERTY CPF_PACKAGE_MAINTAINER_EMAIL ${ARG_MAINTAINER_EMAIL} )
	
	
	# add other custom targets

	# add a target the will be build before the binary target and that will copy all 
	# depended on shared libraries to the targets output directory.
	cpfAddDeploySharedLibrariesTarget(${ARG_PACKAGE_NAME})

	# Adds target that runs clang-tidy on the given files.
    # Currently this is only added for the production target because clang-tidy does not filter out warnings that come over the GTest macros from external code.
    # When clang-tidy resolves the problem, static analysis should be executed for all binary targets.
    cpfAddClangTidyTarget(${productionLibrary})
    cpfAddRunCppTestsTargets(${ARG_PACKAGE_NAME})
	cpfAddValgrindTarget(${ARG_PACKAGE_NAME})
	cpfAddOpenCppCoverageTarget(${ARG_PACKAGE_NAME})

	# Plugins must be added before the install targets
	cpfAddPlugins( ${ARG_PACKAGE_NAME} "${pluginOptionLists}" )
	 
	# Adds a target the creates abi-dumps when using clang or gcc with debug options.
	cpfAddAbiCheckerTargets( ${ARG_PACKAGE_NAME} "${distributionPackageOptionLists}" "${ARG_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS}" )
	
	# A target to generate a .dox file that is used to add links to the packages build results to the package documentation.
	if(${GENERATE_PACKAGE_DOX_FILES})
		cpfAddPackageDocsTarget( packageLinkFile ${ARG_PACKAGE_NAME} ${ARG_PACKAGE_NAMESPACE} "${ARG_BRIEF_DESCRIPTION}" "${ARG_LONG_DESCRIPTION}")
		list(APPEND ARG_PRODUCTION_FILES ${packageLinkFile} )
	endif()

	# Adds the install rules and the per package install targets.
	cpfAddInstallRules( ${ARG_PACKAGE_NAME} ${ARG_PACKAGE_NAMESPACE} "${pluginOptionLists}" "${distributionPackageOptionLists}" ${ARG_VERSION_COMPATIBILITY_SCHEME} )

	# Adds the targets that create the distribution packages.
	cpfAddDistributionPackageTargets( ${ARG_PACKAGE_NAME} "${distributionPackageOptionLists}" )

endfunction() 


#---------------------------------------------------------------------
# This function only returns the libraries from the input that actually exist.
# Lower level packages must be added first.
# For others a warning is issued when CPF_VERBOSE is ON.
# We allow adding dependencies to non existing targets so we can link to targets that may only be available
# on certain platforms.
#
function( cpfDebugAssertLinkedLibrariesExists linkedLibrariesOut package linkedLibrariesIn )

	foreach(lib ${linkedLibrariesIn})
		if(NOT TARGET ${lib} )
			cpfDebugMessage("${lib} is not a Target when creating package ${package}. If it should be available, make sure to have target ${lib} added before adding this package.")
		else()
			list(APPEND linkedLibraries ${lib})
		endif()
	endforeach()
	set(${linkedLibrariesOut} ${linkedLibraries} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
# Checks that the compatibility scheme option contains one of the allowed values.
function( cpfAssertCompatibilitySchemeOption scheme )
	if( NOT ( "${scheme}" STREQUAL ExactVersion ) )
		message(FATAL_ERROR "Invalid argument to cpfAddCppPackage()!. Value \"${scheme}\" for option VERSION_COMPATIBILITY_SCHEME is not allowed.")
	endif()
endfunction()

#---------------------------------------------------------------------
# This function is used to change properties of imported targets to make
# sure that property values are set after the same "scheme" on which the
# rest of the CPF cmake code can rely.
#
# E.g. On Linuy the LOCATION_<config> property should hold the location of the actual binary
# file and not the location of the symlink that points to the binary. The symlink
# location should be stored in the IMPORTED_SONAME_<config> property.
#
function( cpfNormalizeImportedTargetProperties targets )

	# also get indirectly linked targets
	cpfGetAllTargetsInLinkTree( allLinkedTargets "${targets}")
	
	cpfFilterInTargetsWithProperty( importedTargets "${allLinkedTargets}" IMPORTED TRUE)
	foreach(target ${importedTargets})
	
		# make sure the location property does not point to a symbolic link but to the real file on linux
		if( ${CMAKE_SYSTEM_NAME} STREQUAL Linux)
			cpfIsSingleConfigGenerator( isSingleConfig )
			if(NOT ${isSingleConfig})
				message(FATAL_ERROR "Function cpfNormalizeImportedTargetProperties() assumes that there are only single configuration generators on linux.")
			endif()
			cpfToConfigSuffix( configSuffix ${CMAKE_BUILD_TYPE} ) 
			
			get_property( location TARGET ${target} PROPERTY LOCATION_${configSuffix} )
			if( IS_SYMLINK ${location} )
			
				# get the file to which the symlink points
				execute_process(COMMAND readlink;${location} RESULT_VARIABLE result OUTPUT_VARIABLE linkTarget )
				if(NOT ${result} STREQUAL 0)
					message(FATAL_ERROR "Could not read symlink ${location}")
				endif()
				# refine the output result
				string(STRIP ${linkTarget} linkTarget)
				get_filename_component( dir ${location} DIRECTORY)
				set(linkTarget "${dir}/${linkTarget}")
				
				# change the target properties
				if( EXISTS ${linkTarget})
					set_property( TARGET ${target} PROPERTY LOCATION_${configSuffix} ${linkTarget})
					set_property( TARGET ${target} PROPERTY IMPORTED_LOCATION_${configSuffix} ${linkTarget} )
					get_filename_component( locationShort ${location} NAME)
					set_property( TARGET ${target} PROPERTY IMPORTED_SONAME_${configSuffix} ${locationShort} )
				else()
					message( FATAL_ERROR "The soname symlink \"${location}\" of imported target ${target} points to the not existing file \"${linkTarget}\"." )
				endif()
				
			endif()
			
		endif()
	
	endforeach()
endfunction()

#---------------------------------------------------------------------
#
function( 
	cpfAddPackageBinaryTargets 
	outProductionLibrary 
	package 
	packageNamespace 
	type 
	publicHeaderFiles 
	productionFiles 
	publicFixtureHeaderFiles 
	fixtureFiles 
	testFiles 
	linkedLibraries 
	linkedTestLibraries
	versionCompatibilityScheme
)

	# filter some files
	foreach( file ${productionFiles})
		
		# main.cpp
		if( "${file}" MATCHES "^main.cpp$" OR "${file}" MATCHES "(.*)/main.cpp$")
			set(MAIN_CPP ${file})
		endif()

		# icon files (they must be added to the executable)
		if( "${file}" MATCHES "(.*)${package}[.]ico$" OR "${file}" MATCHES "(.*)${package}[.]rc$")
			list(APPEND iconFiles ${file})
		endif()

	endforeach()

	# add version header and cmake files to the production files
	list(APPEND productionFiles ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt )
	getExistingPackageVersionFile( versionFile ${package} )
	list(APPEND productionFiles ${versionFile} )
	cpfGetPackageVersionCppHeaderFileName( versionHeader ${package} )
	list(APPEND publicHeaderFiles ${CMAKE_CURRENT_BINARY_DIR}/${versionHeader} )
	

	# Modify variables if the package creates an executable
	if("${type}" STREQUAL GUI_APP OR "${type}" STREQUAL CONSOLE_APP)
		set(isExe TRUE)
		set( productionTarget lib${package})
		#remove main.cpp from the files
		cpfAssertDefinedMessage(MAIN_CPP "A package of executable type must contain a main.cpp file.")
		list(REMOVE_ITEM productionFiles ${MAIN_CPP})
		foreach( iconFile ${iconFiles})
			list(REMOVE_ITEM productionFiles ${iconFile})
		endforeach()

	else()

		set(isExe FALSE)
		set(productionTarget ${package})

	endif()
	
	###################### Create production library target ##############################
    if(productionFiles OR publicHeaderFiles)  

        cpfAddBinaryTarget(
			PACKAGE_NAME ${package}  
			EXPORT_MACRO_PREFIX ${packageNamespace}
			TARGET_TYPE LIB
			NAME ${productionTarget}
			PUBLIC_HEADER ${publicHeaderFiles}
			FILES ${productionFiles}
			LINKED_LIBRARIES ${linkedLibraries}
			IDE_FOLDER ${package}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
	    )

    endif()

	###################### Create exe target ##############################
	if(isExe)
		
		set( exeTarget ${package})
		cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			TARGET_TYPE ${type}
			NAME ${exeTarget}
			FILES ${MAIN_CPP} ${iconFiles}
			LINKED_LIBRARIES ${linkedLibraries} ${productionTarget}
			IDE_FOLDER ${package}/exe
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
	    )

	endif()
	
	########################## Test Targets ###############################
	set( VSTestFolder test)		# the name of the test targets folder in the visual studio solution

    ################### Create fixture library ##############################	
	if( fixtureFiles OR publicFixtureHeaderFiles )
        set( fixtureTarget ${productionTarget}${CPF_FIXTURE_TARGET_ENDING})
	    cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			EXPORT_MACRO_PREFIX ${packageNamespace}_TESTS
			TARGET_TYPE LIB
			NAME ${fixtureTarget}
			PUBLIC_HEADER ${publicFixtureHeaderFiles}
			FILES ${fixtureFiles}
			LINKED_LIBRARIES ${productionTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
        )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF )
			set_property(TARGET ${fixtureTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()
		set_property(TARGET ${package} PROPERTY CPF_TEST_FIXTURE_SUBTARGET ${fixtureTarget} )
        
    endif()

    ################### Create unit test exe ##############################
	if( testFiles )
        set( unitTestsTarget ${productionTarget}${CPF_TESTS_TARGET_ENDING})
        cpfAddBinaryTarget(
			PACKAGE_NAME ${package}
			TARGET_TYPE CONSOLE_APP
			NAME ${unitTestsTarget}
			FILES ${testFiles}
			LINKED_LIBRARIES ${productionTarget} ${fixtureTarget} ${linkedTestLibraries}
			IDE_FOLDER ${package}/${VSTestFolder}
			VERSION_COMPATIBILITY_SCHEME ${versionCompatibilityScheme}
        )
		set_property(TARGET ${package} PROPERTY CPF_TESTS_SUBTARGET ${unitTestsTarget} )

		# respect an option that is used by hunter to not compile test targets
		if(${package}_BUILD_TESTS STREQUAL OFF)
			set_property(TARGET ${unitTestsTarget} PROPERTY EXCLUDE_FROM_ALL TRUE )
		endif()

    endif()
    
	# Set some properties
    set_property(TARGET ${package} PROPERTY CPF_BINARY_SUBTARGETS ${exeTarget} ${fixtureTarget} ${productionTarget} ${unitTestsTarget} )
    set_property(TARGET ${package} PROPERTY CPF_PRODUCTION_LIB_SUBTARGET ${productionTarget} )
	set( ${outProductionLibrary} ${productionTarget} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------
#
# Adds a binary target 
# 
# Arguments:
# PACKAGE_NAME				The name of the package to which the target belongs.
# PACKAGE_NAMESPACE			The namespace of the package
# TARGET_TYPE				GUI_APP = executable with switched of console (use for QApplications with ui); CONSOLE_APP = console application; LIB = library (use to create a static or shared libraries )
# NAME						The name of the added binary target.
# LINKAGE					Only relevant when adding a library. This takes STATIC or SHARED
# PUBLIC_HEADER				The header files that are required by clients that link to the target.
# FILES						All files that belong to the target.
# LINKED_LIBRARIES			Other targets on which this target depends.
# 
function( cpfAddBinaryTarget	)

	cmake_parse_arguments(
		ARG 
		"" 
		"PACKAGE_NAME;EXPORT_MACRO_PREFIX;TARGET_TYPE;NAME;IDE_FOLDER;VERSION_COMPATIBILITY_SCHEME" 
		"PUBLIC_HEADER;FILES;LINKED_LIBRARIES" 
		${ARGN} 
	)
	set( allSources ${ARG_PUBLIC_HEADER} ${ARG_FILES})

	cpfQt5AddUIAndQrcFiles( allSources )

    # Create Window application
    if( ${ARG_TARGET_TYPE} STREQUAL GUI_APP)
        add_executable(${ARG_NAME} WIN32 ${allSources} )
    endif()

    # Create console application
    if( ${ARG_TARGET_TYPE} MATCHES CONSOLE_APP)
        add_executable(${ARG_NAME} ${allSources} )
    endif()

    # library
    if( ${ARG_TARGET_TYPE} MATCHES LIB )
		
		add_library(${ARG_NAME} ${allSources} )
		
		# make sure that clients have the /D <target>_IMPORTS compile option set.
		if( ${BUILD_SHARED_LIBS} AND MSVC)
			target_compile_definitions(${ARG_NAME} INTERFACE /D ${ARG_NAME}_IMPORTS )
		endif()
		
		# Remove the lib prefix on Linux. We expect that to be part of the package name.
		set_property(TARGET ${ARG_NAME} PROPERTY PREFIX "")
		
    endif()

    # Set target properties
	# Set include directories, that all header are included with #include <package/myheader.h>
	# We do not use special directories for private or public headers. So the include directory is public.
	target_include_directories( ${ARG_NAME} PUBLIC 
		$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
		$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
	)
	
	# Hardcode c++ standard to 14 for now.
	# This should be set by the user in the addPackage() method.
	set_property(TARGET ${ARG_NAME} PROPERTY CXX_STANDARD 14)

	# set the Visual Studio folder property
	set_property( TARGET ${ARG_NAME} PROPERTY FOLDER ${ARG_IDE_FOLDER})
	# public header
	set_property( TARGET ${ARG_NAME} PROPERTY CPF_PUBLIC_HEADER ${ARG_PUBLIC_HEADER})
	# Enable qt auto moc
	# Note that we AUTOUIC and AUTORCC is not used because I was not able to get the names of
	# the generated files at cmake time which is required when setting source groups and 
	# adding the generated ui_*.h header to the targets interface include directories.
	set_property( TARGET ${ARG_NAME} PROPERTY AUTOMOC ON)
	# Set the target version
	set_property( TARGET ${ARG_NAME} PROPERTY VERSION ${PROJECT_VERSION} )
	if("${ARG_VERSION_COMPATIBILITY_SCHEME}" STREQUAL ExactVersion)
		set_property( TARGET ${ARG_NAME} PROPERTY SOVERSION ${PROJECT_VERSION} )
	else()
		message(FATAL_ERROR "Unexpected compatibility scheme!")
	endif()

	# sets all the <bla>_OUTPUT_DIRECTORY_<config> options
	cpfSetTargetOutputDirectoriesAndNames( ${ARG_PACKAGE_NAME} ${ARG_NAME})

    # link with other libraries
    target_link_libraries(${ARG_NAME} PUBLIC ${ARG_LINKED_LIBRARIES} )
    cpfRemoveWarningFlagsForSomeExternalFiles(${ARG_NAME})

	# Generate the header file with the dll export and import macros
	cpfGenerateExportMacroHeader(${ARG_NAME} "${ARG_EXPORT_MACRO_PREFIX}")

    # set target to use pre-compiled header
    # compile flags can not be changed after this call
    cpfAddPrecompiledHeader( ${ARG_NAME} )

	# sort files into folders in visual studio
    cpfSetIDEDirectoriesForTargetSources(${ARG_NAME})

endfunction()


#----------------------------------------- macro from Lars Christensen to use precompiled headers --------------------------------
# this was copied from https://gist.github.com/larsch/573926
# this might be an alternative if this does not work well enough: https://github.com/sakra/cotire
function(cpfAddPrecompiledHeader target )
    
    # add the precompiled header (targets and compile flags)
    set_target_properties(${target} PROPERTIES COTIRE_ADD_UNITY_BUILD FALSE)  # prevent the generation of unity build targets
	
	if(CPF_ENABLE_PRECOMPILED_HEADER AND CPF_USE_PRECOMPILED_HEADERS ) 
		cotire( ${target})
		cpfReAddInheritedCompileOptions( ${target})

		# Add the prefix header to the target files to make sure it appears in the visual studio solution.
		get_property(prefixHeader TARGET ${target} PROPERTY COTIRE_CXX_PREFIX_HEADER)
		set_property(TARGET ${target} APPEND PROPERTY SOURCES ${prefixHeader})

		# do not run moc for the generated prefix header, it will cause build errors.
		set_property(SOURCE ${prefixHeader} PROPERTY SKIP_AUTOMOC ON)
    endif()
endfunction()

#---------------------------------------------------------------------------------------------
# This function compensates a CMake bug (https://gitlab.kitware.com/cmake/cmake/issues/17488)
# Cotire sets the SOURCE propety COMPILE_FLAGS which removes inherited INTERFACE_COMPILE_OPTIONS due
# to the bug. We manually re-add the compile options here.
function( cpfReAddInheritedCompileOptions target )

	# The problem only occurs for the visual studio generator.
	cpfIsVisualStudioGenerator(isVS)
	if(NOT isVS)
		return()
	endif()

	# get all inherited compile options
	set(inheritedCompileOptions)
	cpfGetVisibleLinkedLibraries( linkedLibs ${target} )
	foreach( lib ${linkedLibs} )
		get_property( compileOptions TARGET ${lib} PROPERTY INTERFACE_COMPILE_OPTIONS )
		list(APPEND inheritedCompileOptions ${compileOptions})
	endforeach()

	if(inheritedCompileOptions)
		list(REMOVE_DUPLICATES inheritedCompileOptions )
		cpfJoinString( inheritedOptionsString "${inheritedCompileOptions}" " ")

		# add them to the SOURCE property COMPILE_FLAGS
		# adding them with target_compile_options will not work.
		get_property(sourceFiles TARGET ${target} PROPERTY SOURCES)
		foreach( file ${sourceFiles})
			get_filename_component( extension ${file} EXT)
			if( "${extension}" STREQUAL .cpp ) # we only handle the .cpp extension which is fragile, but hopes are that this code will be removed when the cmake bug is fixed.
				get_property( flags SOURCE ${file} PROPERTY COMPILE_FLAGS)
				set_property( SOURCE ${file} PROPERTY COMPILE_FLAGS "${inheritedOptionsString} ${flags}") # inherited options must come before the prefix header include option
			endif()
		endforeach()
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
# Calls the qt5_wrap_ui and qt5_add_resources and adds the generated files to the given file list
#
function( cpfQt5AddUIAndQrcFiles filesOut )

	set(files ${${filesOut}})

	# handle ui files manually
	# There were problems with the AUTOUIC option because
	# when using it, the names of the generated files are
	# not available here to add them to the include directories.
	foreach( file ${ARG_FILES})
		get_filename_component( extension ${file} EXT)
		if("${extension}" STREQUAL ".ui")
			list(APPEND uiFiles ${file})
		elseif("${extension}" STREQUAL ".qrc")
			list(APPEND rcFiles ${file})
		endif()
	endforeach() 

	if(uiFiles)
		qt5_wrap_ui(uiHeaders ${uiFiles})
		list(APPEND ARG_FILES ${uiHeaders})
	endif()

	if(rcFiles)
		qt5_add_resources(qrcFiles ${rcFiles})
	endif()

	set( ${filesOut} ${files} ${uiHeaders} ${qrcFiles} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Sorts the source files of the target into various folders for Visual Studio.
# 
# Remarks
# I failed to add the cotire prefix header to the generated files because
# it does not belong to the target.
# The ui_*.h files could also not be added to the generated files because they do not exist when the target is created.
function( cpfSetIDEDirectoriesForTargetSources targetName )

    # get the source files in the Sources directory
	get_target_property( sourceDir ${targetName} SOURCE_DIR)
	getAbsPathesForSourceFilesInDir( sourcesFiles ${targetName} ${sourceDir})
	# get the generated source files in the binary directory
	get_target_property( binaryDir ${targetName} BINARY_DIR)
	getAbsPathesForSourceFilesInDir( generatedFiles ${targetName} ${binaryDir})
	# manually add a file that is generated by automoc and not visible here
	list(APPEND generatedFiles ${CMAKE_CURRENT_BINARY_DIR}/${targetName}_autogen/moc_compilation.cpp) 
	
	# set source groups for generated files that do exist
	source_group(Generated FILES ${generatedFiles})
	
	# set the file groups of the files in the Source directory to follow the directory structure
	cpfGetRelativePaths( sourcesFiles "${sourceDir}" "${sourcesFiles}")
	cpfSourceGroupTree("${sourcesFiles}")

endfunction()

#---------------------------------------------------------------------------------------------
# Sets the <binary-type>_OUTOUT_DIRECTORY_<config> properties of the given target.
#
function( cpfSetTargetOutputDirectoriesAndNames package target )

	cpfGetConfigurations( configs)
	foreach(config ${configs})
		cpfSetAllOutputDirectoriesAndNames(${target} ${package} ${config} "${CMAKE_BINARY_DIR}/BuildStage/${config}" )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfSetAllOutputDirectoriesAndNames target package config outputPrefixDir  )

	cpfToConfigSuffix( configSuffix ${config})

	# Delete the <config>_postfix property and handle things manually in cpfSetOutputDirAndName()
	string(TOUPPER ${config} uConfig)
	set_property( TARGET ${target} PROPERTY ${uConfig}_POSTFIX "" )

	cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} RUNTIME)
	cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} LIBRARY)
	cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} ARCHIVE)

	cpfProjectProducesPdbFiles(hasOutput ${config})
	if(hasOutput)
		cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} COMPILE_PDB)
		set_property(TARGET ${target} PROPERTY COMPILE_PDB_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX}-compiler) # we overwrite the filename to make it more meaningful
	endif()

	cpfTargetHasPdbLinkerOutput(hasOutput ${target} ${configSuffix})
	if(hasOutput)
		# Note that we use the same name and path for linker as are used for the dlls files.
		# When consuming imported targets we guess that the pdb files have these locations. 
		cpfSetOutputDirAndName( ${target} ${package} ${config} ${outputPrefixDir} PDB)
		set_property(TARGET ${target} PROPERTY PDB_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX})
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
# This function sets the output name property to make sure that the same target file names are
# achieved across all platforms.
function( cpfSetOutputDirAndName target package config prefixDir outputType )

	cpfGetRelativeOutputDir( relativeDir ${package} ${outputType})
	cpfToConfigSuffix(configSuffix ${config})
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY_${configSuffix} ${prefixDir}/${relativeDir})
	# use the config postfix for all target types
	set_property(TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} ${target}${CMAKE_${configSuffix}_POSTFIX} )

endfunction()

#---------------------------------------------------------------------
# generate a header file that contains the EXPORT macros
function( cpfGenerateExportMacroHeader target macroBaseName )

	cpfIsExecutable(isExe ${target})
	if(NOT isExe)
		string(TOLOWER ${macroBaseName} macroBaseNameLower ) # the generate_export_header() function will create a file with lower case name.
		generate_export_header( 
			${target}
			BASE_NAME ${macroBaseNameLower}
		)
		set(exportHeader "${CMAKE_CURRENT_BINARY_DIR}/${macroBaseNameLower}_export.h" )
		set_property(TARGET ${target} APPEND PROPERTY SOURCES ${exportHeader} )
		set_property(TARGET ${target} APPEND PROPERTY CPF_PUBLIC_HEADER ${exportHeader} )
		source_group(Generated FILES ${exportHeader})
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# Call this function to make sure explicitly loaded shared libraries are deployed besides the packages executables in the build and install stage.
# The package has no knowledge about plugins, so they must be explicitly deployed with this function.
#
# pluginDependencies A list where the first element is the relative path of the plugin and the folling elements are the plugin targets.
# 
function( cpfAddPlugins package pluginOptionLists )

	cpfGetExecutableTargets( exeTargets ${package})
	if(NOT exeTargets)
		return()
	endif()

	cpfGetPluginTargetDirectoryPairLists( pluginTargets pluginDirectories "${pluginOptionLists}" )

	# add deploy and install targets for the plugins
	set(index 0)
	foreach(plugin ${pluginTargets})
		list(GET pluginDirectories ${index} subdirectory)
		cpfIncrement(index)
		if(TARGET ${plugin})
			add_dependencies( ${package} ${plugin}) # adds the artifical dependency
			cpfAddDeploySharedLibsToBuildStageTarget( ${package} ${plugin} ${subdirectory} ) 
		endif()
	endforeach()

endfunction()

