# This file contains functions that contain project and target related helper functionality.

include_guard(GLOBAL)

include(cpfLocations)
include(cpfConstants)
include(cpfListUtilities)
include(cpfStringUtilities)
include(cpfPathUtilities)
include(cpfReadVariablesFromFile)

#---------------------------------------------------------------------------------------------
# Sets the warning level to high and forces the global include of the SwitchOffWarningsMacro file.
#
# Make sure to only set compiler options here that do not need to be passed to the static
# library dependencies upstream. Those must be specified in the cmake toolchain files.
macro( cpfSetDynamicAndCosmeticCompilerOptions )
    
	cpfGetCompiler(compiler)
    if( ${compiler} STREQUAL Vc) # VC flags
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP") # the /MP flag saved on my 4 core machine 25 % compile time
    endif()
    
	cpfSetHighWarningLevel()

    if( CPF_WARNINGS_AS_ERRORS )
		cpfSetWarningsAsErrors()
	endif()

endmacro()

#----------------------------------------- set warning level to 4 and set warnings as errors --------------------------------
macro(cpfSetHighWarningLevel)
    
	cpfGetCompiler(compiler)
    if(${compiler} STREQUAL Vc)
        # Use the highest warning level for visual studio.
        set(CMAKE_CXX_WARNING_LEVEL 4)
        if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
            string(REGEX REPLACE "/W[0-4]" "/W4"
                CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        else(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
        endif(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
       
    elseif(${compiler} STREQUAL Gcc )
    
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wpedantic -Wall -Wextra" )
        
    elseif(${compiler} STREQUAL Clang)
    
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wpedantic -Wall -Wextra -Wthread-safety" )
       
    endif()

endmacro()

#----------------------------------------------------------------------------------------
macro( cpfSetWarningsAsErrors )

	cpfGetCompiler(compiler)
    if(${compiler} STREQUAL Vc)
        # Treat warnings as errors
        # TODO only do this optionally when user sets a variable
        if(CMAKE_CXX_FLAGS MATCHES "/WX-" )
            string(REGEX REPLACE "/WX-" "/WX"
                CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        else(CMAKE_CXX_FLAGS MATCHES "/WX-")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /WX")                
        endif(CMAKE_CXX_FLAGS MATCHES "/WX-")
    
    elseif(${compiler} STREQUAL Gcc)
        
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")  
        
    elseif(${compiler} STREQUAL Clang)
    
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")  
        
    endif()

endmacro()

#----------------------------------------------------------------------------------------
# Returns Vc, Clang, Gcc, or UNKNOWN
#
function( cpfGetCompiler compiler)

	if(MSVC)
		set(comp Vc)
	elseif(CMAKE_COMPILER_IS_GNUCXX)
		set(comp Gcc)
	elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
		set(comp Clang)
	else()
		set(comp UNKNOWN)
	endif()

	set( ${compiler} ${comp} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# returns a list of all currently used CXX_FLAGS
function( cpfGetCxxFlags flagsOut config)
	cpfToConfigSuffix( configSuffix ${config})
	cpfSplitStringAtWhitespaces( flags "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${configSuffix}}")
	set( ${flagsOut} "${flags}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( cpfIsMSVCDebugConfig bOut config )
	
	set(isMSVCDebug FALSE)

	if(MSVC)
		cpfGetCxxFlags( flags ${config})
		cpfContainsOneOf( isMSVCDebug "${flags}" "/Zi;/ZI;/Z7" )
	endif()

	set( ${bOut} ${isMSVCDebug} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfProjectProducesPdbFiles hasPdbOutput config )

	set( hasPdbFlag FALSE )
	if(MSVC)
		cpfToConfigSuffix(configSuffix ${config})
		cpfSplitString( flagsList "${CMAKE_CXX_FLAGS_${configSuffix}}" " ")
		cpfContainsOneOf( hasPdbFlag "${flagsList}" /Zi;/ZI )
	endif()
	set( ${hasPdbOutput} ${hasPdbFlag} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfTargetHasPdbLinkerOutput hasPdbOutput target configSuffix )

	cpfProjectProducesPdbFiles( hasPdbCompileOutput ${config})
	
	if( hasPdbCompileOutput )
		get_property( targetType TARGET ${target} PROPERTY TYPE)
		if(${targetType} STREQUAL SHARED_LIBRARY OR ${targetType} STREQUAL MODULE_LIBRARY OR ${targetType} STREQUAL EXECUTABLE)
			set(${hasPdbOutput} TRUE PARENT_SCOPE)
			return()
		endif()
	endif()

	set(${hasPdbOutput} FALSE PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfIsGccClangDebug var )

	cpfGetCompiler(compiler)
	if(${compiler} STREQUAL Clang OR ${compiler} STREQUAL Gcc)

		cpfGetCxxFlags( flags ${CMAKE_BUILD_TYPE})
		cpfContains( hasDebugFlag "${flags}" -g )
		# When compiling for debugging we usually have low optimization level flags set.
		cpfContainsOneOf( hasLowOptimizationFlag "${flags}" "-O1;-O0;-Og" )

		if(hasDebugFlag AND hasLowOptimizationFlag )
			set(${var} TRUE PARENT_SCOPE)
			return()
		endif()
	endif()
	set(${var} FALSE PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the current generator is one of the Visual Studio generators.
function( cpfIsVisualStudioGenerator isVSOut )
	set(isVS FALSE)
	if( ${CMAKE_GENERATOR} MATCHES "Visual Studio.*")
		set(isVS TRUE)
	endif()
	set(${isVSOut} ${isVS} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# reduce the warning level for files that are added over cmakes interface sources mechanism
macro( cpfRemoveWarningFlagsForSomeExternalFiles targetName )

	cpfIsInterfaceLibrary( isIntLib ${targetName})
	if(isIntLib)
		return()
	endif()

    set( externalFiles 
        static_qt_plugins.cpp   # added when using staticly linked hunter-qt
    )
    
    get_target_property( linkedLibraries ${targetName} LINK_LIBRARIES )
    
    foreach(library ${linkedLibraries})
        
        if( TARGET ${library}) # prevent errors with get_property call on our own targets.
        
            get_target_property( isImported ${library} IMPORTED)
            if( ${isImported})      # prevent errors with get_property call on our own targets.
            
                get_property( sources TARGET ${library} PROPERTY INTERFACE_SOURCES )
                
                foreach(source ${sources})
                
                    get_filename_component(shortName ${source} NAME)
                    
                    if( ${shortName} IN_LIST externalFiles)
                        
                        get_source_file_property( flags ${shortName} COMPILE_FLAGS)
                        if( ${flags} STREQUAL NOTFOUND)
                            set(flags "")
                        endif()

                        set_source_files_properties(${source} PROPERTIES COMPILE_FLAGS "-w ${flags}")
                        
                    endif()
                    
                endforeach()
            
            endif()
        endif()
    endforeach()
endmacro()

#----------------------------------------------------------------------------------------
# This function reads some properties from a target and prints the value if it is set.
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
		INTERFACE_RUN_TESTS_SUBTARGET
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


#----------------------------------------------------------------------------------------
# Prints the value of the given target property if it is set.
#
function( cpfPrintTargetPropertyIfSet target property )

	get_property( value TARGET ${target} PROPERTY ${property} )
	if(NOT "${value}" STREQUAL "")
		message("- ${property}: ${value} ")
	endif()

endfunction()


#----------------------------------------------------------------------------------------
# Prints all CMAKE variables that together define the toolchain
#
function( cpfPrintToolchainVariables )

	cpfDebugMessage("Used Buildtools:")
	cpfDebugMessage("CMAKE_GENERATOR: ${CMAKE_GENERATOR}")
	cpfDebugMessage("CMAKE_MAKE_PROGRAM: ${CMAKE_MAKE_PROGRAM}")
	cpfDebugMessage("CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
	cpfDebugMessage("CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
	cpfDebugMessage("CMAKE_LINKER: ${CMAKE_LINKER}")
	cpfDebugMessage("CMAKE_CXX_COMPILER_ID: ${CMAKE_CXX_COMPILER_ID}")
	cpfDebugMessage("CMAKE_CXX_COMPILER_VERSION: ${CMAKE_CXX_COMPILER_VERSION}")
	cpfDebugMessage("CMAKE_VS_PLATFORM_NAME: ${CMAKE_VS_PLATFORM_NAME}")

endfunction()


#---------------------------------------------------------------------------------------------
# This function will find all the tools that are required to build all the custom
# targets of a CMakeProjectFramework package.
# The function will populate the TOOL_<exe> cache entries. Currently they are:
# TOOL_
#  
#
function( cpfFindRequiredTools )

	if(CPF_ENABLE_CLANG_TIDY_TARGET)
		cpfGetCompiler(compiler)
		if( ${compiler} STREQUAL Clang)
			set(CLANG_TIDY clang-tidy-3.9) # We should get this from hunter some day.
			cpfFindRequiredProgram(TOOL_CLANG_TIDY ${CLANG_TIDY} "A tool from the LLVM project that performs static analysis of cpp code" "")
		endif()
		cpfFindRequiredProgram( TOOL_ACYCLIC acyclic "A tool from the graphviz library that can check if a graphviz graph is acyclic" "")
	endif()

	if(Qt5Gui_FOUND )
		cpfFindRequiredProgram( 
			TOOL_UIC uic
			"A tool from the Qt framework that generates ui_*.h files from *.ui GUI defining xml files"
			"${Qt5_DIR}/../../../bin"
			)
	endif()

	# python is optional
	find_package(PythonInterp 3)
	if(PYTHONINTERP_FOUND AND PYTHON_VERSION_MAJOR STREQUAL 3)
		set(TOOL_PYTHON3 "${PYTHON_EXECUTABLE}" CACHE PATH "The used python3 interpreter.")
	endif()

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
# Returns the short output name of the internal target
#
function( cpfGetTargetOutputFileName output target config )

	cpfGetTargetOutputType( outputType ${target})
	cpfGetTargetOutputFileNameForTargetType( shortFilename ${target} ${config} ${outputType})
	set( ${output} ${shortFilename} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetOutputFileNameForTargetType output target config outputType)

	cpfToConfigSuffix(configSuffix ${config})
	get_property( outputBaseName TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} )
	get_property( targetType TARGET ${target} PROPERTY TYPE)
	get_property( version TARGET ${target} PROPERTY VERSION)
	
	cpfGetTargetTypeFileExtension( extension ${targetType})
	cpfIsDynamicLibrary( isDynamicLib ${target})
	cpfIsExecutable( isExe ${target})

	if(${CMAKE_SYSTEM_NAME} STREQUAL Linux AND isDynamicLib )
		set( shortFilename "${outputBaseName}${extension}.${version}")
	elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux AND isExe)
		set( shortFilename "${outputBaseName}-${version}${extension}")
	else()
		set( shortFilename "${outputBaseName}${extension}")
	endif()

	set( ${output} ${shortFilename} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTargetOutputBaseName nameOut target config)
	cpfToConfigSuffix( configSuffix ${config})
	cpfGetTargetOutputType( outputType ${target})
	get_property( baseName TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME_${configSuffix} )
	set( ${nameOut} ${baseName} PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetAbsOutputDir absDirOut package outputType config )
	cpfGetRelativeOutputDir(relativeDir ${package} ${outputType})
	set(${absDirOut} "${CMAKE_BINARY_DIR}/BuildStage/${config}/${relativeDir}" PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# Note that this function defines a part of the directory structure of the deployed files
#
function( cpfGetRelativeOutputDir relativeDirOut package outputType )

	cpfGetPackagePrefixOutputDir( packagePrefixDir ${package} )
	cpfGetTypePartOfOutputDir(typeDir ${package} ${outputType})
	set(${relativeDirOut} ${packagePrefixDir}/${typeDir} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# 
function( cpfGetPackagePrefixOutputDir outputDir package )
	set(${outputDir} ${package} PARENT_SCOPE )
endfunction()

#---------------------------------------------------------------------------------------------
# returns the output directory of the target
function( cpfGetTargetOutputDirectory output target config )

	cpfToConfigSuffix(configSuffix ${config})
	cpfGetTargetOutputType( outputType ${target})
	get_property( outputDir TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY_${configSuffix} )
	set( ${output} "${outputDir}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# This function defines the part of the output directory that comes after the config/package add_subdirectory
#
function( cpfGetTypePartOfOutputDir typeDir package outputType )

	# handle relative dirs that are the same on all platforms
	if(${outputType} STREQUAL ARCHIVE)
		set(typeDirLocal lib)
	elseif(${outputType} STREQUAL COMPILE_PDB )	
		# We put the compiler pdb files parallel to the lib, because msvc looks for them there.
		set(typeDirLocal lib )
	elseif(${outputType} STREQUAL PDB)
		# We put the linker pdb files parallel to the dll, because msvc looks for them there.
		set(typeDirLocal . )
	elseif(${outputType} STREQUAL INCLUDE)
		set(typeDirLocal include/${package})
	elseif(${outputType} STREQUAL CMAKE_PACKAGE_FILES)
		set(typeDirLocal lib/cmake/${package}) 
	elseif(${outputType} STREQUAL SOURCE )
		set(typeDirLocal src/${package}) 
	elseif(${outputType} STREQUAL OTHER )
		set(typeDirLocal other ) 
	endif()

	# handle platform specific relative dirs
	if( ${CMAKE_SYSTEM_NAME} STREQUAL Windows  )
		# on windows we put executables and dlls directly in the package directory.
		if(${outputType} STREQUAL RUNTIME)
			set(typeDirLocal . )
		elseif(${outputType} STREQUAL LIBRARY)
			set(typeDirLocal . )
		endif()

	elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
		# On Linux we follow the GNU coding standards that propose a directory structure
		# https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
		if(${outputType} STREQUAL RUNTIME)
			set(typeDirLocal bin)
		elseif(${outputType} STREQUAL LIBRARY)
			set(typeDirLocal lib)
		endif()

	else()
		message(FATAL_ERROR "Function cpfSetAllOutputDirectoriesAndNames() must be extended for system ${CMAKE_SYSTEM_NAME}")
	endif()
	
	set( ${typeDir} ${typeDirLocal} PARENT_SCOPE ) 

endfunction()

#----------------------------------------------------------------------------------------
# Returns the absolute path to the output directory and the short filename of the output file of an imported or internal target
#
function( cpfGetTargetLocation targetDirOut targetFilenameOut target config )

	get_property(isImported TARGET ${target} PROPERTY IMPORTED)
	if(isImported)
		cpfToConfigSuffix( configSuffix ${config})
		# for imported targets it is not clear which property holds the 
		set( possibleLocationProperties IMPORTED_LOCATION_${configSuffix} LOCATION_${configSuffix} IMPORTED_LOCATION LOCATION )
		cpfGetFirstDefinedTargetProperty( fullTargetFile ${target} "${possibleLocationProperties}")
  
        if("${fullTargetFile}" STREQUAL "") # give up
            cpfPrintTargetProperties(${target}) # print more debug information about which variable may hold the location
            message(FATAL_ERROR "Function cpfGetTargetLocation() could not determine the location of the binary file for target ${target} and configuration ${config}")
        endif()

	else()
		cpfGetFullTargetOutputFile( fullTargetFile ${target} ${config})
	endif()

	get_filename_component( shortName "${fullTargetFile}" NAME)
	get_filename_component( targetDir "${fullTargetFile}" DIRECTORY )

	set(${targetDirOut} ${targetDir} PARENT_SCOPE)
	set(${targetFilenameOut} ${shortName} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the absolute pathes of the output files of multiple targets.
#
function( cpfGetTargetLocations absolutePathes targets config )
	set(locations)
	foreach(target ${targets})
		cpfGetTargetLocation( dir shortName ${target} ${config} )
		cpfListAppend( locations "${dir}/${shortName}")
	endforeach()
	set(${absolutePathes} "${locations}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the binary sub-targets that will be shared libraries if
# the BUILD_SHARED_LIBS option is set to ON.
function( cpfGetPossiblySharedLibrarySubTargets librarySubTargetsOut package)

	set(libraryTargets)

	cpfIsExecutable(isExe ${package})
	if(NOT isExe)
		cpfListAppend( libraryTargets ${package})
	endif()

	get_property( fixtureTarget TARGET ${package} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET)
	if(TARGET ${fixtureTarget})
		cpfListAppend( libraryTargets ${fixtureTarget})
	endif()

	set( ${librarySubTargetsOut} "${libraryTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# returns the full output filename of the given target
function( cpfGetFullTargetOutputFile output target config )

	cpfGetTargetOutputDirectory( directory ${target} ${config} )
	cpfGetTargetOutputFileName( name ${target} ${config})
	set( ${output} "${directory}/${name}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# translates the target type into the output type (ARCHIVE, RUNTIME etc.)
function( cpfGetTargetOutputType outputTypeOut target )

	get_property( type TARGET ${target} PROPERTY TYPE)
	if( ${type} STREQUAL EXECUTABLE )
		set( ${outputTypeOut} RUNTIME PARENT_SCOPE)
	elseif(${type} STREQUAL STATIC_LIBRARY)
		set( ${outputTypeOut} ARCHIVE PARENT_SCOPE)
	elseif(${type} STREQUAL MODULE_LIBRARY)
		set( ${outputTypeOut} LIBRARY PARENT_SCOPE)
	elseif(${type} STREQUAL SHARED_LIBRARY)
		if(${CMAKE_SYSTEM_NAME} STREQUAL Windows ) # this should also be set when using cygwin or maybe clang-cl, but we ignore that for now
			set( ${outputTypeOut} RUNTIME PARENT_SCOPE)
		else()
			set( ${outputTypeOut} LIBRARY PARENT_SCOPE)
		endif()
	elseif(${type} STREQUAL INTERFACE_LIBRARY)
		set( ${outputTypeOut} ARCHIVE PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Target type ${type} not supported by function cpfGetTargetOutputType()")
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# returns the file extension for the type of the given target
function( cpfGetTargetTypeFileExtension extension targetType)
	
	if( ${targetType} STREQUAL EXECUTABLE )
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL STATIC_LIBRARY)
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL MODULE_LIBRARY)
		set( ${extension} ${CMAKE_SHARED_MODULE_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL SHARED_LIBRARY)
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Target type ${targetType} not supported by function cpfGetTargetTypeFileExtension()")
	endif()

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
# This function reads the package version from a packages version file.
function( cpfGetPackageVersionFromFile versionOut package absPackageSourceDir )

	getExistingPackageVersionFile( versionFile ${package} )

	include("${versionFile}")
	if( "${CPF_${package}_VERSION}" STREQUAL "")
		message(FATAL_ERROR "Could not read value of variable CPF_${package}_VERSION from file \"${absPackageSourceDir}/${versionFile}\"." )
	endif()
	set( ${versionOut} ${CPF_${package}_VERSION} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the path to the version.cmake file in the source tree or in the binary tree depending on which exists.
function( getExistingPackageVersionFile absPathOut package )

	cpfGetPackageVersionFileName( versionFile ${package})
	set(sourceTreePath "${CMAKE_CURRENT_SOURCE_DIR}/${versionFile}")
	set(binaryTreePath "${CMAKE_CURRENT_BINARY_DIR}/${versionFile}")

	if(EXISTS "${sourceTreePath}")
		set(${absPathOut} "${sourceTreePath}" PARENT_SCOPE)
	elseif(EXISTS "${binaryTreePath}")
		set(${absPathOut} "${binaryTreePath}" PARENT_SCOPE)
	else()
		message(FATAL_ERROR "File ${verisonFile} is missing! It should be in the source or binary directory of package ${package}." )
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# This function tries to find the location of a config file with the given configName
# configName can be an absolute file path to a .config.cmake file or the base-name of
# config file which is situated in one of the following directories:
#    <cpf-root>/Configuration     
#    <cpf-root>/Sources/BuildConfigurations
#    <cpf-root>/Sources/CPFCMake/DefaultConfigurations
#
# If multiple files with the same base-name exist, the one in the directory that comes
# first in the above list is taken.
#
function( cpfFindConfigFile absFilePathOut configName )

	if(EXISTS "${configName}")
		set( ${absFilePathOut} "${configName}" PARENT_SCOPE )
	else()

		set( searchLocations
			"${CPF_ROOT_DIR}/${CPF_CONFIG_DIR}"											# developer specific configs
			"${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/${CPF_PROJECT_CONFIGURATIONS_DIR}"		# project default configs
			"${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/CPFCMake/${CPF_DEFAULT_CONFIGS_DIR}"		# CPF provided standard configs
		)

		foreach( dir ${searchLocations})
			cpfNormalizeAbsPath( fullConfigFile "${dir}/${configName}${CPF_CONFIG_FILE_ENDING}" )
			if( EXISTS "${fullConfigFile}" )
				set( ${absFilePathOut} "${fullConfigFile}" PARENT_SCOPE )
				return()
			endif()
		endforeach()

	endif()
	
	message(FATAL_ERROR "Could not find any configuration file with base-name ${configName}.")

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetExecutableTargets exeTargetsOut package )
	
	set(exeTargets)

	cpfIsExecutable(isExe ${package})
	if(isExe)
		cpfListAppend( exeTargets ${package})
	endif()

	get_property( testTarget TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET )
	if(testTarget)
		list(APPEND exeTargets ${testTarget})
	endif()

	set(${exeTargetsOut} "${exeTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetProductionTargets productionTargetsOut package)
	
	set(targets ${package})
	
	cpfIsExecutable(isExe ${package})
	if(isExe)
		get_property( prodLibTarget TARGET ${package} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET )
		cpfListAppend(targets ${prodLibTarget})
	endif()

	set(${productionTargetsOut} ${targets} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTestTargets testTargetsOut package )

	set(targets)

	get_property( fixtureTarget TARGET ${package} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET )
	if(fixtureTarget)
		cpfListAppend(targets ${fixtureTarget})
	endif()

	get_property( testExeTarget TARGET ${package} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET )
	if(testExeTarget)
		cpfListAppend(targets ${testExeTarget})
	endif()

	set(${testTargetsOut} ${targets} PARENT_SCOPE)

endfunction()


#---------------------------------------------------------------------------------------------
# Reads the value of the CPF_PACKAGES variable from the ci-projects owned packages file
# and returns the list of packages.
# 
function( cpfGetPackages allPackagesOut ownedPackagesOut externalPackagesOut rootDir )
	
	set(fullOwnedPackagesFile "${rootDir}/${CPF_SOURCE_DIR}/${CPF_PACKAGES_FILE}")
	# create an owned packages file if none exists
	if(NOT EXISTS ${fullOwnedPackagesFile} )
		# we use the manual existance check to prevent overwriting the file when the template changes.
		configure_file("${CPF_ABS_TEMPLATE_DIR}/${CPF_PACKAGES_FILE}.in" ${fullOwnedPackagesFile} COPYONLY )
	endif()

	cpfReadVariablesFromFile( variableNames variableValues ${fullOwnedPackagesFile})

	set(index 0)
	foreach( variable ${variableNames} )

		if( ${variable} STREQUAL CPF_PACKAGES)
			list(GET variableValues ${index} packageList )
			if("${packageList}" STREQUAL "")
				message(FATAL_ERROR "No packages defined in file \"${fullOwnedPackagesFile}\".")
			endif()
			continue()
		endif()
		cpfIncrement(index)

	endforeach()

	if(NOT packageList)
		message(WARNING "File \"${fullOwnedPackagesFile}\" is missing a definition for variable CPF_PACKAGES")
	endif()

	# parse the package list
	set(allPackages)
	set(ownedPackages)
	set(externalPackages)

	cpfListLength( length "${packageList}")
	set(index 0)
	while(${index} LESS ${length})

		list(GET packageList ${index} keyWord )

		cpfStrequal( isOwned ${keyWord} OWNED)
		cpfStrequal( isExternal ${keyWord} EXTERNAL)

		if( (NOT isOwned) AND (NOT isExternal) )
			message(FATAL_ERROR "The list defined by CPF_PACKAGES in file \"${fullOwnedPackagesFile}\" must be a sequence of [ OWNED|EXTERNAL <package> ] pairs.")
		endif()

		cpfIncrement(index)
		list(GET packageList ${index} package )

		cpfListAppend(allPackages ${package})
		if(isOwned)
			cpfListAppend(ownedPackages ${package})
		else()
			cpfListAppend(externalPackages ${package})
		endif()

		cpfIncrement(index)

	endwhile()

	set(${allPackagesOut} "${allPackages}" PARENT_SCOPE)
	set(${ownedPackagesOut} "${ownedPackages}" PARENT_SCOPE)
	set(${externalPackagesOut} "${externalPackages}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns all packages from the packages.cmake file
#
function( cpfGetAllPackages packagesOut )

	cpfGetPackages( allPackages ownedPackages externalPackages ${CPF_ROOT_DIR})
	set(${packagesOut} "${allPackages}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns a list with the owned packages from the packages.cmake file
#
function( cpfGetOwnedPackages packagesOut rootDir )

	cpfGetPackages( allPackages ownedPackages externalPackages ${rootDir})
	set(${packagesOut} "${ownedPackages}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the owned packages that are not in the same repository as the CI-project.
#  
function( cpfGetOwnedLoosePackages loosePackagesOut rootDir )

	set(loosePackages)
	cpfGetOwnedPackages( ownedPackages ${rootDir})
	foreach(package ${ownedPackages})
		cpfIsLoosePackage( isLoose ${package} ${rootDir})
		if(isLoose)
			list(APPEND loosePackages ${package})
		endif()
	endforeach()
	set(${loosePackagesOut} ${loosePackages} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns true if the package is not in the same repository as the ci-project.
function( cpfIsLoosePackage isLooseOut package rootDir)

	cpfGetAbsPackageDirectory( packageDir ${package} ${rootDir})
	cpfGetHashOfTag( packageHash HEAD "${packageDir}")
	cpfGetHashOfTag( rootHash HEAD "${rootDir}")
	if( ${packageHash} STREQUAL ${rootHash} )
		set(${isLooseOut} FALSE PARENT_SCOPE)
	else()
		set(${isLooseOut} TRUE PARENT_SCOPE)
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
# returns the absolute paths to the repository directories that are owned by the CPF project located at rootDir
#
function( cpfGetOwnedRepositoryDirectories dirsOut rootDir)

	# Get all directories that may belong to different owned repositories
	cpfGetOwnedPackages( ownedPackages ${rootDir})
	set( possibleRepoDirectories ${rootDir} )
	foreach(package ${ownedPackages})
		cpfGetAbsPackageDirectory( packageDirOut ${package} ${rootDir})
		list(APPEND possibleRepoDirectories ${packageDirOut})
	endforeach()

	# Check which of these repositories belong together (have the same hash of the HEAD).
	# Get list of all current hashes
	set(hashes)
	foreach(repoDir ${possibleRepoDirectories})
		cpfGetHashOfTag( hashHEAD HEAD "${repoDir}")
		list(APPEND hashes ${hashHEAD})
	endforeach()

	# Get indexes of duplicated elements in list
	set(duplicatedIndexes)
	foreach(hash ${hashes})
		cpfFindAllInList( indexes "${hashes}" ${hash})
		cpfSplitList( unused duplIndexes "${indexes}" 1)
		list(APPEND duplicatedIndexes ${duplIndexes})
	endforeach()

	# Get directories of non duplicated hashes
	set(uniqueRepoDirs)
	set(index 0)
	foreach(hash ${hashes})
		cpfContains(isDuplicated "${duplicatedIndexes}" ${index})
		if(NOT isDuplicated)
			list(GET possibleRepoDirectories ${index} repoDir)
			list(APPEND uniqueRepoDirs ${repoDir})
		endif()
		cpfIncrement(index)
	endforeach()

	set(${dirsOut} "${uniqueRepoDirs}" PARENT_SCOPE)

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





