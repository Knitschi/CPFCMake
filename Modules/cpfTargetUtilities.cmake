include_guard(GLOBAL)


# This file contains functions that operate on targets


#----------------------------------------------------------------------------------------
# Returns true if the target is an executable.
function( cpfIsExecutable isExeOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL EXECUTABLE)
        set(${isExeOut} TRUE PARENT_SCOPE)
    else()
        set(${isExeOut} FALSE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the target is a SHARED_LIBRARY or MODULE_LIBRARY
function( cpfIsDynamicLibrary bOut target)
	get_property( type TARGET ${target} PROPERTY TYPE )
	if(${type} STREQUAL SHARED_LIBRARY OR ${type} STREQUAL MODULE_LIBRARY)
		set(${bOut} TRUE PARENT_SCOPE)
	else()
		set(${bOut} FALSE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the given target is an INTERFACE_LIBRARY
function( cpfIsStaticLibrary isStaticLibOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL STATIC_LIBRARY)
        set(${isStaticLibOut} TRUE PARENT_SCOPE)
    else()
        set(${isStaticLibOut} FALSE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the given target is an INTERFACE_LIBRARY
function( cpfIsInterfaceLibrary isIntLibOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL INTERFACE_LIBRARY)
        set(${isIntLibOut} TRUE PARENT_SCOPE)
    else()
        set(${isIntLibOut} FALSE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the given target is an INTERFACE_LIBRARY
function( cpfIsBinaryTarget isBinTargetOut target )
    get_property(type TARGET ${target} PROPERTY TYPE)
    if(${type} STREQUAL UTILITY)
        set(${isBinTargetOut} FALSE PARENT_SCOPE)
    else()
        set(${isBinTargetOut} TRUE PARENT_SCOPE)
    endif()
endfunction()

#----------------------------------------------------------------------------------------
# This function reads all properties from a target and prints the value if it is set.
#
function( cpfPrintTargetProperties target )

	if( NOT TARGET ${target})
		message("There is no target ${target}")
		return()
	endif()

	message("Properties on target ${target}:")
	
	set( configDependentProperies 
		ARCHIVE_OUTPUT_DIRECTORY
		ARCHIVE_OUTPUT_NAME
		COMPILE_DEFINITIONS
		COMPILE_PDB_NAME
		COMPILE_PDB_OUTPUT_DIRECTORY
		EXCLUDE_FROM_DEFAULT_BUILD
		IMPORTED_IMPLIB
		IMPORTED_LIBNAME
		IMPORTED_LINK_DEPENDENT_LIBRARIES
		IMPORTED_LINK_INTERFACE_LANGUAGES
		IMPORTED_LINK_INTERFACE_LIBRARIES
		IMPORTED_LINK_INTERFACE_MULTIPLICITY
		IMPORTED_LOCATION
		IMPORTED_NO_SONAME
		IMPORTED_OBJECTS
		IMPORTED_SONAME
		INTERPROCEDURAL_OPTIMIZATION
		LIBRARY_OUTPUT_DIRECTORY
		LIBRARY_OUTPUT_NAME
		LINK_FLAGS
		LINK_INTERFACE_LIBRARIES
		LINK_INTERFACE_MULTIPLICITY
		MAP_IMPORTED_CONFIG
		OSX_ARCHITECTURES
		OUTPUT_NAME
		PDB_NAME
		PDB_OUTPUT_DIRECTORY
		RUNTIME_OUTPUT_DIRECTORY
		RUNTIME_OUTPUT_NAME
		STATIC_LIBRARY_FLAGS
		# CPF properties
		CPF_OUTPUT_FILES
	)
	
	# cmake gives an error when reading the LOCATION property from internal targets
	set( onlyImportedTargetsConfigDependentProperties
		LOCATION
	)

	set(properties 
		ALIASED_TARGET
		ANDROID_ANT_ADDITIONAL_OPTIONS
		ANDROID_API
		ANDROID_API_MIN
		ANDROID_ARCH
		ANDROID_ASSETS_DIRECTORIES
		ANDROID_GUI
		ANDROID_JAR_DEPENDENCIES
		ANDROID_JAR_DIRECTORIES
		ANDROID_JAVA_SOURCE_DIR
		ANDROID_NATIVE_LIB_DEPENDENCIES
		ANDROID_NATIVE_LIB_DIRECTORIES
		ANDROID_PROCESS_MAX
		ANDROID_PROGUARD
		ANDROID_PROGUARD_CONFIG_PATH
		ANDROID_SECURE_PROPS_PATH
		ANDROID_SKIP_ANT_STEP
		ANDROID_STL_TYPE
		AUTOGEN_BUILD_DIR
		AUTOGEN_TARGET_DEPENDS
		AUTOMOC_DEPEND_FILTERS
		AUTOMOC_MOC_OPTIONS
		AUTOMOC
		AUTOUIC
		AUTOUIC_OPTIONS
		AUTOUIC_SEARCH_PATHS
		AUTORCC
		AUTORCC_OPTIONS
		BINARY_DIR
		BUILD_RPATH
		BUILD_WITH_INSTALL_NAME_DIR
		BUILD_WITH_INSTALL_RPATH
		BUNDLE_EXTENSION
		BUNDLE
		C_EXTENSIONS
		C_STANDARD
		C_STANDARD_REQUIRED
		COMPATIBLE_INTERFACE_BOOL
		COMPATIBLE_INTERFACE_NUMBER_MAX
		COMPATIBLE_INTERFACE_NUMBER_MIN
		COMPATIBLE_INTERFACE_STRING
		COMPILE_DEFINITIONS
		COMPILE_FEATURES
		COMPILE_FLAGS
		COMPILE_OPTIONS
		CROSSCOMPILING_EMULATOR
		CUDA_PTX_COMPILATION
		CUDA_SEPARABLE_COMPILATION
		CUDA_RESOLVE_DEVICE_SYMBOLS
		CUDA_EXTENSIONS
		CUDA_STANDARD
		CUDA_STANDARD_REQUIRED
		CXX_EXTENSIONS
		CXX_STANDARD
		CXX_STANDARD_REQUIRED
		DEBUG_OUTPUT_NAME
		DEBUG_POSTFIX
		DEFINE_SYMBOL
		EchoString
		ENABLE_EXPORTS
		EXCLUDE_FROM_ALL
		EXPORT_NAME
		FOLDER
		Fortran_FORMAT
		Fortran_MODULE_DIRECTORY
		FRAMEWORK
		FRAMEWORK_VERSION
		GENERATOR_FILE_NAME
		GNUtoMS
		HAS_CXX
		IMPLICIT_DEPENDS_INCLUDE_TRANSFORM
		IMPORTED_CONFIGURATIONS
		IMPORTED
		IMPORT_PREFIX
		IMPORT_SUFFIX
		INCLUDE_DIRECTORIES
		INSTALL_NAME_DIR
		INSTALL_RPATH
		INSTALL_RPATH_USE_LINK_PATH
		INTERFACE_AUTOUIC_OPTIONS
		INTERFACE_COMPILE_DEFINITIONS
		INTERFACE_COMPILE_OPTIONS
		INTERFACE_INCLUDE_DIRECTORIES
		INTERFACE_LINK_LIBRARIES
		INTERFACE_POSITION_INDEPENDENT_CODE
		INTERFACE_SOURCES
		INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
		IOS_INSTALL_COMBINED
		JOB_POOL_COMPILE
		JOB_POOL_LINK
		LABELS
		CXX_CLANG_TIDY
		CXX_COMPILER_LAUNCHER
		CXX_CPPLINT
		CXX_INCLUDE_WHAT_YOU_USE
		CXX_VISIBILITY_PRESET
		LINK_DEPENDS_NO_SHARED
		LINK_DEPENDS
		LINKER_LANGUAGE
		LINK_LIBRARIES
		LINK_SEARCH_END_STATIC
		LINK_SEARCH_START_STATIC
		LINK_WHAT_YOU_USE
		MACOSX_BUNDLE_INFO_PLIST
		MACOSX_BUNDLE
		MACOSX_FRAMEWORK_INFO_PLIST
		MACOSX_RPATH
		MANUALLY_ADDED_DEPENDENCIES
		NAME
		NO_SONAME
		NO_SYSTEM_FROM_IMPORTED
		POSITION_INDEPENDENT_CODE
		PREFIX
		PRIVATE_HEADER
		PROJECT_LABEL
		PUBLIC_HEADER
		RESOURCE
		RELEASE_OUTPUT_NAME
		RELEASE_POSTFIX
		RULE_LAUNCH_COMPILE
		RULE_LAUNCH_CUSTOM
		RULE_LAUNCH_LINK
		SKIP_BUILD_RPATH
		SOURCE_DIR
		SOURCES
		SOVERSION
		SUFFIX
		TYPE
		VERSION
		VISIBILITY_INLINES_HIDDEN
		VS_CONFIGURATION_TYPE
		VS_DEBUGGER_WORKING_DIRECTORY
		VS_DESKTOP_EXTENSIONS_VERSION
		VS_DOTNET_REFERENCES
		VS_DOTNET_REFERENCES_COPY_LOCAL
		VS_DOTNET_TARGET_FRAMEWORK_VERSION
		VS_GLOBAL_KEYWORD
		VS_GLOBAL_PROJECT_TYPES
		VS_GLOBAL_ROOTNAMESPACE
		VS_IOT_EXTENSIONS_VERSION
		VS_IOT_STARTUP_TASK
		VS_KEYWORD
		VS_MOBILE_EXTENSIONS_VERSION
		VS_SCC_AUXPATH
		VS_SCC_LOCALPATH
		VS_SCC_PROJECTNAME
		VS_SCC_PROVIDER
		VS_SDK_REFERENCES
		VS_USER_PROPS
		VS_WINDOWS_TARGET_PLATFORM_MIN_VERSION
		VS_WINRT_COMPONENT
		VS_WINRT_EXTENSIONS
		VS_WINRT_REFERENCES
		WIN32_EXECUTABLE
		WINDOWS_EXPORT_ALL_SYMBOLS
		XCODE_ATTRIBUTE_<an-attribute>
		XCODE_EXPLICIT_FILE_TYPE
		XCODE_PRODUCT_TYPE
		XCTEST
		# CPF properties
		INTERFACE_CPF_BRIEF_PACKAGE_DESCRIPTION
		INTERFACE_CPF_PACKAGE_WEBPAGE_URL
		INTERFACE_CPF_PACKAGE_MAINTAINER_EMAIL
		INTERFACE_CPF_BINARY_SUBTARGETS
		INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET
		INTERFACE_CPF_TEST_FIXTURE_SUBTARGET
		INTERFACE_CPF_TESTS_SUBTARGET
		INTERFACE_CPF_PUBLIC_HEADER
		INTERFACE_CPF_UIC_SUBTARGET
		INTERFACE_CPF_UIC_SUBTARGET
		INTERFACE_CPF_CLANG_TIDY_SUBTARGET
		INTERFACE_CPF_VALGRIND_SUBTARGET
		INTERFACE_CPF_OPENCPPCOVERAGE_SUBTARGET
		CPF_CPPCOVERAGE_OUTPUT
		INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET
		INTERFACE_CPF_RUN_TESTS_SUBTARGET
		INTERFACE_CPF_RUN_FAST_TESTS_SUBTARGET
		CPF_DOXYGEN_SUBTARGET
		CPF_DOXYGEN_TAGSFILE
		CPF_DOXYGEN_CONFIG_SUBTARGET
		CPF_DOXYGEN_CONFIG_FILE
		CPF_INSTALL_PACKAGE_SUBTARGET
		INTERFACE_CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS
		INTERFACE_CPF_ABI_DUMP_SUBTARGET
		INTERFACE_CPF_ABI_CHECK_SUBTARGETS
		CPF_OUTPUT_FILES
	)

	# For interface targets accessing non whitelisted properties causes errors.
	set( interfaceTargetPropertyWhitelist
		COMPATIBLE_INTERFACE_BOOL
		COMPATIBLE_INTERFACE_NUMBER_MAX
		COMPATIBLE_INTERFACE_NUMBER_MIN
		COMPATIBLE_INTERFACE_STRING
		EXPORT_NAME
		IMPORTED
		NAME
		INTERFACE_AUTOUIC_OPTIONS
		INTERFACE_COMPILE_DEFINITIONS
		INTERFACE_COMPILE_OPTIONS
		INTERFACE_INCLUDE_DIRECTORIES
		INTERFACE_LINK_LIBRARIES
		INTERFACE_POSITION_INDEPENDENT_CODE
		INTERFACE_SOURCES
		INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
	)

	set( configInterfaceTargetPropertyWhitelist
		IMPORTED_LIBNAME
		MAP_IMPORTED_CONFIG
	)

	# limit the propeties to the whitelist for interface libraries
	get_property( type TARGET ${target} PROPERTY TYPE )
	if(${type} STREQUAL INTERFACE_LIBRARY)
		set(properties ${interfaceTargetPropertyWhitelist})
		set(configDependentProperies ${configInterfaceTargetPropertyWhitelist})
	endif()


	# get all conifg suffixes for the target
	cpfGetConfigVariableSuffixes(suffixes TRUE)
	if(NOT CMAKE_CONFIGURATION_TYPES AND CMAKE_BUILD_TYPE)
		if(NOT ${type} STREQUAL INTERFACE_LIBRARY)
			cpfListAppend( suffixes " ") # also show the variables without the suffix
		endif()
	endif()
	
	# also check imported configurations variables
	get_property( importedConfigurations TARGET ${target} PROPERTY IMPORTED_CONFIGURATIONS )
	foreach(importConfig ${importedConfigurations})
		string(TOUPPER ${importConfig} upperConfig)
		cpfListAppend( suffixes ${upperConfig})
	endforeach()
	list(REMOVE_DUPLICATES suffixes)

	# append all config variants of the properties to the list
	foreach( configProperty ${configDependentProperies})
		foreach( suffix ${suffixes})
			cpfListAppend( properties ${configProperty}_${suffix} )
		endforeach()
	endforeach()
	
	# only append the import only properties if the target is imported
	get_property( isImported TARGET ${target} PROPERTY IMPORTED )
	if(isImported AND ( NOT ${type} STREQUAL INTERFACE_LIBRARY ))
		foreach( configProperty ${onlyImportedTargetsConfigDependentProperties})
			foreach( suffix ${suffixes})
				cpfListAppend( properties ${configProperty}_${suffix} )
			endforeach()
		endforeach()
	endif()
	
	
	# print the properties
	foreach( property ${properties})
		cpfPrintTargetPropertyIfSet( ${target} ${property})
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetProperties outputValues targets properties )

	set(values)

	foreach(target ${targets})
		foreach( property ${properties})
			get_property(value TARGET ${target} PROPERTY ${property})
			cpfListAppend( values ${value})
		endforeach()
	endforeach()

	set(${outputValues} "${values}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# This function can be used when there are possibly multiple target properties that may hold the
# required information. The function will try on property after the other and return the value
# for the first that holds a value.
function( cpfGetFirstDefinedTargetProperty valueOut target properties )
    foreach( property ${properties} )
        get_property( value TARGET ${target} PROPERTY ${property})
        if(value)
            set( ${valueOut} ${value} PARENT_SCOPE )
            return()
        endif()
    endforeach()
    set( ${valueOut} "" PARENT_SCOPE )
endfunction()

#---------------------------------------------------------------------------------------------
# Takes a list of targets and returns only the targets that have a given property set to a given value.
# An empty string "" for value means, that the property should not be set.
function( cpfFilterInTargetsWithProperty output targets property value )

	set(filteredTargets)

	foreach( target ${targets})
		get_property(isValue TARGET ${target} PROPERTY ${property})
		if( NOT isValue ) # handle special case "property not set"
			if( NOT value)
				cpfListAppend( filteredTargets ${target})
			endif()
		elseif( "${isValue}" STREQUAL "${value}")
			cpfListAppend( filteredTargets ${target})
		endif()
	endforeach()

	set(${output} "${filteredTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# The inverse of cpfFilterInTargetsWithProperty()
function( cpfFilterOutTargetsWithProperty output targets property value )

	set(filteredTargets)

	foreach( target ${targets})
		cpfFilterInTargetsWithProperty( hasProperty "${target}" ${property} ${value})
		if(NOT hasProperty)
			cpfListAppend( filteredTargets ${target})
		endif()
	endforeach()

	set(${output} "${filteredTargets}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Prints the value of the given target property if it is set.
#
function( cpfPrintTargetPropertyIfSet target property )

	get_property( value TARGET ${target} PROPERTY ${property} )
	if(NOT "${value}" STREQUAL "")
		message("- ${property}: ${value} ")
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
			
			set(interfacePrefix)
			cpfIsInterfaceLibrary( isIntLib ${target})
			if(isIntLib)
				set(interfacePrefix INTERFACE_)
			endif()

			get_property( location TARGET ${target} PROPERTY ${interfacePrefix}LOCATION_${configSuffix} )
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
					set_property( TARGET ${target} PROPERTY ${interfacePrefix}LOCATION_${configSuffix} ${linkTarget})
					set_property( TARGET ${target} PROPERTY ${interfacePrefix}IMPORTED_LOCATION_${configSuffix} ${linkTarget} )
					get_filename_component( locationShort ${location} NAME)
					set_property( TARGET ${target} PROPERTY ${interfacePrefix}IMPORTED_SONAME_${configSuffix} ${locationShort} )
				else()
					message( FATAL_ERROR "The soname symlink \"${location}\" of imported target ${target} points to the not existing file \"${linkTarget}\"." )
				endif()
				
			endif()
			
		endif()
	
	endforeach()
endfunction()

#----------------------------------------------------------------------------------------
# This reads the source files from the targets SOURCES property or in case of interface 
# library targets from the targets file container target.
#
function( cpfGetTargetSourceFiles filesOut target)
	cpfGetTargetSourceFilesAndSourceDir(files unused ${target})
	set(${filesOut} "${files}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTargetSourceFilesAndSourceDir filesOut dirOut target )

	cpfIsInterfaceLibrary( isIntLib ${target})
	if(isIntLib)
		# Use the file container target to get the files.
		get_property(target TARGET ${target} PROPERTY INTERFACE_CPF_FILE_CONTAINER_SUBTARGET )
	endif()
	get_property(sourceDir TARGET ${target} PROPERTY SOURCE_DIR )
	get_property(sources TARGET ${target} PROPERTY SOURCES )

	set(${dirOut} ${sourceDir} PARENT_SCOPE)
	set(${filesOut} ${sources} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Gets all files from the targets SOURCES property, turns them into abs pathes if needed
# and returns the list.
function( getAbsPathsOfTargetSources absPathsOut target)

	cpfGetTargetSourceFilesAndSourceDir(sources sourceDir ${target})

	# sources can have relative or absolute pathes
	set(absPaths)
	foreach( file ${sources})
		cpfToAbsSourcePath( absPath ${file} ${sourceDir})
		cpfListAppend( absPaths ${absPath})
	endforeach()

	set(${absPathsOut} "${absPaths}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with all files from target property SOURCES that are below the given
# directory, relative to the given directory.
function( getAbsPathesForSourceFilesInDir absfilePathsOut target dir)

	getAbsPathsOfTargetSources( absSources ${target})
	# get only files that are in the sources directory
	cpfGetSubPaths( subPaths ${dir} "${absSources}")
	set( ${absfilePathsOut} "${subPaths}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Assumes that the given path is either relative to CMAKE_CURRENT_SOURCE dir or an absolute
# path and prepends CMAKE_CURRENT_SCOURCE dir if it is relative.
function( cpfToAbsSourcePath absPathOut sourceFile sourceDir)
	cpfIsAbsolutePath( isAbsPath ${sourceFile})
	if(NOT isAbsPath )
		set(sourceFile ${sourceDir}/${sourceFile} )
	endif()
	set(${absPathOut} "${sourceFile}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Calls cpfToAbsSourcePath() for multiple files.
function( cpfToAbsSourcePaths absPathsOut sourceFiles sourceDir)
	set(absFiles)
	foreach(file ${sourceFiles})
		cpfToAbsSourcePath( absFile ${file} ${sourceDir})
		cpfListAppend(absFiles ${absFile})
	endforeach()
	set(${absPathsOut} "${absFiles}" PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# This function returns all the subdirectories in the Sources directory of a CMakeProjectFramework project.
#
function( cpfGetSourcesSubdirectories subdirsOut cpfRootDir )

	# get subdirectories in the Sources directory to find potential packages
	set( fullSourceDir "${cpfRootDir}/${CPF_SOURCE_DIR}" )
	cpfGetSubdirectories( subDirs "${fullSourceDir}" )
	if(NOT subDirs)
		message(FATAL_ERROR "No possible package directories found in directory \"${fullSourceDir}\"")
	endif()

	set(${subdirsOut} "${subDirs}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Similar to the cmake function source_group( TREE ), but also sorts .cpp and .h files # in directories.
# For some unkown reason the cmake function does not work for us, so we have to implement it manually.
# However, the cmake function worked in a minimalistic test project. wtf!?
function( cpfSourceGroupTree relfiles)

	foreach(file ${relfiles})
		get_filename_component(dir ${file} DIRECTORY)
		string(REPLACE "/" "\\" sourceGroup "${dir}")
		source_group("${sourceGroup}" FILES ${file})
	endforeach()

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetTargetSourcesWithoutPrefixHeader sourcesOut target )

	cpfGetTargetSourceFiles(sources ${target})

	cpfIsInterfaceLibrary( isIntLib ${target})
	if(NOT isIntLib)
		get_property(prefixHeader TARGET ${target} PROPERTY COTIRE_CXX_PREFIX_HEADER)
		if(sources AND prefixHeader)
			list(REMOVE_ITEM sources "${prefixHeader}")
		endif()
	endif()

	set(${sourcesOut} "${sources}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# Sorts the source files of the target into various folders for Visual Studio.
# 
# Remarks
# I failed to add the cotire prefix header to the generated files because
# it does not belong to the target.
# The ui_*.h files could also not be added to the generated files because they do not exist when the target is created.
function( cpfSetIDEDirectoriesForTargetSources targetName )

	cpfIsInterfaceLibrary(isInterfaceLib ${targetName})
	if(isInterfaceLib)
		return()
	endif()

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

#----------------------------------------------------------------------------------------
# Returns $<TARGET_FILE:<target>> if the target is not an interface library,
# othervise it returns an empty string.
function( cpfGetTargetFileGeneratorExpression expOut target)
	set(file)
	cpfIsInterfaceLibrary(isIntLib ${target})
	if(NOT isIntLib)
		set(file "$<TARGET_FILE:${target}>")
	endif()
	set(${expOut} "${file}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with all non-imported targets that are defined in a package directory
# with add_library(), add_executable() or add_custom_target().
#
function( cpfGetAllTargets allTargetsOut )
	
	set(allTargets)

	cpfGetAllPackages(packages)
	foreach(package ${packages})
		get_property(targets DIRECTORY ${CMAKE_SOURCE_DIR}/${package} PROPERTY BUILDSYSTEM_TARGETS )
		cpfListAppend(allTargets ${targets})
	endforeach()

	set(${allTargetsOut} "${allTargets}" PARENT_SCOPE)

endfunction()