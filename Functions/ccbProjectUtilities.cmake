
include("${CMAKE_CURRENT_LIST_DIR}/../Variables/ccbLocations.cmake")

set(DIR_OF_PROJECT_UTILITIES ${CMAKE_CURRENT_LIST_DIR})


#---------------------------------------------------------------------------------------------
# Sets the warning level to high and forces the global include of the SwitchOffWarningsMacro file.
#
# Make sure to only set compiler options here that do not need to be passed to the static
# library dependencies upstream. Those must be specified in the cmake toolchain files.
macro( ccbSetDynamicAndCosmeticCompilerOptions )
    
	ccbGetCompiler(compiler)
    if( ${compiler} STREQUAL Vc) # VC flags

        # Include the warnings switch off macro in all source files
        # Note that we have to set this for the target to make sure it is included in the generated moc-files.
        ccbGetCompileOptionForIncludingTheSwitchOffWarningsMacroFile(includeWarningMacrosFlag)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${includeWarningMacrosFlag} /MP") # the /MP flag saved on my 4 core machine 25 % compile time
        
    endif()
    
	ccbSetHighWarningLevel()

    if( CCB_WARNINGS_AS_ERRORS )
		ccbSetWarningsAsErrors()
	endif()

endmacro()

#---------------------------------------------------------------------------------------------
# 
function(ccbGetCompileOptionForIncludingTheSwitchOffWarningsMacroFile flag)

	ccbGetCompiler(compiler)
    if( ${compiler} STREQUAL Gcc)
        set( incFlag "-include${CMAKE_SOURCE_DIR}/${CCB_SWITCH_WARNINGS_OFF_MACRO_FILE}")
    elseif( ${compiler} STREQUAL Clang)
        set( incFlag "-include${CMAKE_SOURCE_DIR}/${CCB_SWITCH_WARNINGS_OFF_MACRO_FILE}")
    elseif( ${compiler} STREQUAL Vc)
        set( incFlag "/FI\"${CMAKE_SOURCE_DIR}/${CCB_SWITCH_WARNINGS_OFF_MACRO_FILE}\"")
    endif()

    set(${flag} "${incFlag}" PARENT_SCOPE)
    
endfunction()

#----------------------------------------- set warning level to 4 and set warnings as errors --------------------------------
macro(ccbSetHighWarningLevel)
    
	ccbGetCompiler(compiler)
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
macro( ccbSetWarningsAsErrors )

	ccbGetCompiler(compiler)
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
function( ccbGetCompiler compiler)

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
function( ccbGetCxxFlags flagsOut config)
	ccbToConfigSuffix( configSuffix ${config})
	ccbSplitStringAtWhitespaces( flags "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS${configSuffix}}")
	set( ${flagsOut} ${flags} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
function( isMSVCDebugConfig bOut config )
	
	set(isMSVCDebug FALSE)

	if(MSVC)
		ccbGetCxxFlags( flags ${config})
		ccbContainsOneOf( isMSVCDebug "${flags}" "/Zi;/ZI;/Z7" )
	endif()

	set( ${bOut} ${isMSVCDebug} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( ccbIsGccClangDebug var )

	ccbGetCompiler(compiler)
	if(${compiler} STREQUAL Clang OR ${compiler} STREQUAL Gcc)

		ccbGetCxxFlags( flags ${CMAKE_BUILD_TYPE})
		ccbContains( hasDebugFlag "${flags}" -g )
		ccbContainsOneOf( hasLowOptimizationFlag "${flags}" "-O1;-O0" )
		
		if(hasDebugFlag AND hasLowOptimizationFlag )
			set(${var} TRUE PARENT_SCOPE)
			return()
		endif()
	endif()
	set(${var} FALSE PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# reduce the warning level for files that are added over cmakes interface sources mechanism
macro( ccbRemoveWarningFlagsForSomeExternalFiles targetName )

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
function( ccbPrintTargetProperties target )

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
		# CPPCODEBASE properties
		PACKAGE
		TARGET_STAMP_FILE
		CCB_UIC_SUBTARGET
		CCB_STATIC_ANALYSIS_SUBTARGET
		CCB_RUN_TESTS_SUBTARGET
		CCB_BINARY_SUBTARGETS
		CCB_DOXYGEN_SUBTARGET
		CCB_DOXYGEN_TAGSFILE
		CCB_DOXYGEN_CONFIG_SUBTARGET
		CCB_DOXYGEN_CONFIG_FILE
	)

	# get all conifg suffixes for the target
	ccbGetConfigVariableSuffixes(suffixes TRUE)
	if(NOT CMAKE_CONFIGURATION_TYPES AND CMAKE_BUILD_TYPE)
		list(APPEND suffixes " ") # also show the variables without the suffix
	endif()
	
	# also check imported configurations variables
	get_property( importedConfigurations TARGET ${target} PROPERTY IMPORTED_CONFIGURATIONS )
	foreach(importConfig ${importedConfigurations})
		string(TOUPPER ${importConfig} upperConfig)
		list(APPEND suffixes _${upperConfig})
	endforeach()
	list(REMOVE_DUPLICATES suffixes)
	
	
	# append all config variants of the properties to the list
	foreach( configProperty ${configDependentProperies})
		foreach( suffix ${suffixes})
			list(APPEND properties ${configProperty}${suffix} )
		endforeach()
	endforeach()
	
	# only append the import only properties if the target is imported
	get_property( isImported TARGET ${target} PROPERTY IMPORTED )
	if(isImported)
		foreach( configProperty ${onlyImportedTargetsConfigDependentProperties})
			foreach( suffix ${suffixes})
				list(APPEND properties ${configProperty}${suffix} )
			endforeach()
		endforeach()
	endif()
	
	
	# print the properties
	foreach( property ${properties})
		ccbPrintTargetPropertyIfSet( ${target} ${property})
	endforeach()

endfunction()


#----------------------------------------------------------------------------------------
# Prints the value of the given target property if it is set.
#
function( ccbPrintTargetPropertyIfSet target property )

	get_property( value TARGET ${target} PROPERTY ${property} )
	if(NOT "${value}" STREQUAL "")
		message("- ${property}: ${value} ")
	endif()

endfunction()


#----------------------------------------------------------------------------------------
# Prints all CMAKE variables that together define the toolchain
#
function( ccbPrintToolchainVariables )

	ccbDebugMessage("Used Buildtools:")
	ccbDebugMessage("CMAKE_GENERATOR: ${CMAKE_GENERATOR}")
	ccbDebugMessage("CMAKE_MAKE_PROGRAM: ${CMAKE_MAKE_PROGRAM}")
	ccbDebugMessage("CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
	ccbDebugMessage("CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
	ccbDebugMessage("CMAKE_LINKER: ${CMAKE_LINKER}")
	ccbDebugMessage("CMAKE_CXX_COMPILER_ID: ${CMAKE_CXX_COMPILER_ID}")
	ccbDebugMessage("CMAKE_CXX_COMPILER_VERSION: ${CMAKE_CXX_COMPILER_VERSION}")
	ccbDebugMessage("CMAKE_VS_PLATFORM_NAME: ${CMAKE_VS_PLATFORM_NAME}")

endfunction()


#---------------------------------------------------------------------------------------------
# This function will find all the tools that are required to build all the custom
# targets of a CppCodeBase package.
# The function will populate the TOOL_<exe> cache entries. Currently they are:
# TOOL_
#  
#
function( ccbFindRequiredTools )

	if(CCB_ENABLE_DOXYGEN_TARGET)
		ccbFindRequiredProgram( TOOL_DOXYGEN doxygen "A tool that generates documentation files by reading in-code comments")
		ccbFindRequiredProgram( TOOL_DOXYINDEXER doxyindexer "A tool that generates search indexes for doxygen generated html files")
		ccbFindRequiredProgram( TOOL_TRED tred "A tool from the graphviz library that creates a transitive reduced version of a graphviz graph")
	endif()
	
	if(CCB_ENABLE_STATIC_ANALYSIS_TARGET)
		ccbGetCompiler(compiler)
		if( ${compiler} STREQUAL Clang)
			set(CLANG_TIDY clang-tidy-3.9) # We should get this from hunter some day.
			ccbFindRequiredProgram(TOOL_CLANG_TIDY ${CLANG_TIDY} "A tool from the LLVM project that performs static analysis of cpp code")
		endif()
		ccbFindRequiredProgram( TOOL_ACYCLIC acyclic "A tool from the graphviz library that can check if a graphviz graph is acyclic")
	endif()

	if(Qt5Gui_FOUND )
		ccbFindRequiredProgram( TOOL_UIC uic "A tool from the Qt framework that generates ui_*.h files from *.ui GUI defining xml files")
	endif()

	# python is optional
	find_package(PythonInterp 3)
	if(PYTHONINTERP_FOUND AND PYTHON_VERSION_MAJOR STREQUAL 3)
		set(TOOL_PYTHON3 "${PYTHON_EXECUTABLE}" CACHE PATH "The used python3 interpreter.")
	endif()

endfunction()


#---------------------------------------------------------------------------------------------
function( ccbGetTargetProperties outputValues targets property )

	set(values)

	foreach(target ${targets})
		get_property(value TARGET ${target} PROPERTY ${property})
		list(APPEND values ${value})
	endforeach()

	set(${outputValues} ${values} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# This function can be used when there are possibly multiple target properties that may hold the
# required information. The function will try on property after the other and return the value
# for the first that holds a value.
function( ccbGetFirstDefinedTargetProperty valueOut target properties )
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
function( ccbGetTargetOutputFileName output target config )

	ccbGetTargetOutputType( outputType ${target})
	get_property( targetType TARGET ${target} PROPERTY TYPE)
	ccbGetTargetOutputFileNameForTargetType( shortFilename ${target} ${config} ${targetType} ${outputType})
	set( ${output} ${shortFilename} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbGetTargetOutputFileNameForTargetType output target config targetType outputType)

	ccbToConfigSuffix(configSuffix ${config})
	get_property( outputBaseName TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME${configSuffix} )
	
	ccbGetTargetTypeFileExtension( extension ${targetType})
	ccbTargetIsDynamicLibrary( isDynamicLib ${target})
	if(${CMAKE_SYSTEM_NAME} STREQUAL Linux AND isDynamicLib )
		get_property(version TARGET ${target} PROPERTY VERSION)
		set( shortFilename "${outputBaseName}${extension}.${version}")
	else()
		set( shortFilename "${outputBaseName}${extension}")
	endif()

	set( ${output} ${shortFilename} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( ccbGetTargetOutputBaseName nameOut target config)
	ccbToConfigSuffix( configSuffix ${config})
	ccbGetTargetOutputType( outputType ${target})
	get_property( baseName TARGET ${target} PROPERTY ${outputType}_OUTPUT_NAME${configSuffix} )
	set( ${nameOut} ${baseName} PARENT_SCOPE)
endfunction()

#---------------------------------------------------------------------------------------------
# Note that this function defines a part of the directory structure of the deployed files
#
function( ccbGetRelativeOutputDir relativeDir package outputType )

	ccbGetPackagePrefixOutputDir( packagePrefixDir ${package} )
	ccbGetTypePartOfOutputDir(typeDir ${package} ${outputType})
	set(${relativeDir} ${packagePrefixDir}/${typeDir} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# 
function( ccbGetPackagePrefixOutputDir outputDir package )
	set(${outputDir} ${package} PARENT_SCOPE )
endfunction()

#---------------------------------------------------------------------------------------------
# returns the output directory of the target
function( ccbGetTargetOutputDirectory output target config )

	ccbToConfigSuffix(configSuffix ${config})
	ccbGetTargetOutputType( outputType ${target})
	get_property( outputDir TARGET ${target} PROPERTY ${outputType}_OUTPUT_DIRECTORY${configSuffix} )
	set( ${output} "${outputDir}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# This function defines the part of the output directory that comes after the config/package add_subdirectory
#
function( ccbGetTypePartOfOutputDir typeDir package outputType )

	# handle relative dirs that are the same on all platforms
	if(${outputType} STREQUAL ARCHIVE)
		set(typeDirLocal lib)
	elseif(${outputType} STREQUAL COMPILE_PDB OR ${outputType} STREQUAL PDB )
		set(typeDirLocal debug )
	elseif(${outputType} STREQUAL INCLUDE)
		set(typeDirLocal include/${package})
	elseif(${outputType} STREQUAL CMAKE_CONFIG)
		set(typeDirLocal lib/cmake/${package}) 
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
		message(FATAL_ERROR "Function ccbSetAllOutputDirectoriesAndNames() must be extended for system ${CMAKE_SYSTEM_NAME}")
	endif()
	
	set( ${typeDir} ${typeDirLocal} PARENT_SCOPE ) 

endfunction()


#---------------------------------------------------------------------------------------------
function( ccbGetRelativeSharedLibraryOutputDir output package config)

	if(${CMAKE_SYSTEM_NAME} STREQUAL Windows)
		ccbGetRelativeOutputDir( relDir ${package} RUNTIME)
	elseif(${CMAKE_SYSTEM_NAME} STREQUAL Linux)
		ccbGetRelativeOutputDir( relDir ${package} LIBRARY)
	else()
		message(FATAL_ERROR "Function ccbGetRelativeSharedLibraryOutputDir() needs to be extended for system ${CMAKE_SYSTEM_NAME}")
	endif()
	
	set(${output} ${relDir} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the absolute path to the output directory and the short filename of the output file of an imported or internal target
#
function( ccbGetTargetLocation targetDirOut targetFilenameOut target config )

	get_property(isImported TARGET ${target} PROPERTY IMPORTED)
	if(isImported)
		ccbToConfigSuffix( configSuffix ${config})
		# for imported targets it is not clear which property holds the 
		set( possibleLocationProperties IMPORTED_LOCATION${configSuffix} LOCATION${configSuffix} IMPORTED_LOCATION LOCATION )
		ccbGetFirstDefinedTargetProperty( fullTargetFile ${target} "${possibleLocationProperties}")
  
        if("${fullTargetFile}" STREQUAL "") # give up
            ccbPrintTargetProperties(${target}) # print more debug information about which variable may hold the location
            message(FATAL_ERROR "Function ccbGetTargetLocation() could not determine the location of the binary file for target ${target} and configuration ${config}")
        endif()

	else()
		ccbGetFullTargetOutputFile( fullTargetFile ${target} ${config})
	endif()

	get_filename_component( shortName "${fullTargetFile}" NAME)
	get_filename_component( targetDir "${fullTargetFile}" DIRECTORY )

	set(${targetDirOut} ${targetDir} PARENT_SCOPE)
	set(${targetFilenameOut} ${shortName} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the absolute pathes of the output files of multiple targets.
#
function( ccbGetTargetLocations absolutePathes targets config )
	set(locations)
	foreach(target ${targets})
		ccbGetTargetLocation( dir shortName ${target} ${config} )
		list(APPEND locations "${dir}/${shortName}")
	endforeach()
	set(${absolutePathes} ${locations} PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the binary sub-targets that are of type SHARED_LIBRARY or MODULE_LIBRARY.
function( ccbGetSharedLibrarySubTargets librarySubTargetsOut package)

	set(libraryTargets)
	get_property( binaryTargets TARGET ${package} PROPERTY CCB_BINARY_SUBTARGETS)
	foreach( binaryTarget ${binaryTargets})
		ccbTargetIsDynamicLibrary( isDynamic ${binaryTarget})
		if(isDynamic)
			list(APPEND libraryTargets ${binaryTarget})
		endif()
	endforeach()
	
	set( ${librarySubTargetsOut} ${libraryTargets} PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Returns true if the target is a SHARED_LIBRARY or MODULE_LIBRARY
function( ccbTargetIsDynamicLibrary bOut target)
	get_property( type TARGET ${target} PROPERTY TYPE )
	if(${type} STREQUAL SHARED_LIBRARY OR ${type} STREQUAL MODULE_LIBRARY)
		set(${bOut} TRUE PARENT_SCOPE)
	else()
		set(${bOut} FALSE PARENT_SCOPE)
	endif()
endfunction()

#---------------------------------------------------------------------------------------------
# returns the full output filename of the given target
function( ccbGetFullTargetOutputFile output target config )

	ccbGetTargetOutputDirectory( directory ${target} ${config} )
	ccbGetTargetOutputFileName( name ${target} ${config})
	set( ${output} "${directory}/${name}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# translates the target type into the output type (ARCHIVE, RUNTIME etc.)
function( ccbGetTargetOutputType outputTypeOut target )

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
		message(FATAL_ERROR "Target type ${type} not supported by function ccbGetTargetOutputType()")
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# returns the file extension for the type of the given target
function( ccbGetTargetTypeFileExtension extension targetType)
	
	if( ${targetType} STREQUAL EXECUTABLE )
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL STATIC_LIBRARY)
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL MODULE_LIBRARY)
		set( ${extension} ${CMAKE_SHARED_MODULE_SUFFIX} PARENT_SCOPE)
	elseif(${targetType} STREQUAL SHARED_LIBRARY)
		set( ${extension} ${CMAKE_${targetType}_SUFFIX} PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Target type ${targetType} not supported by function ccbGetTargetTypeFileExtension()")
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
# This function returns all the subdirectories in the Sources directory of a CppCodeBase.
#
function( ccbGetSourcesSubdirectories subdirsOut cppCodeBaseRootDir )

	# get subdirectories in the Sources directory to find potential packages
	set( fullSourceDir "${cppCodeBaseRootDir}/${CCB_SOURCE_DIR}" )
	ccbGetSubdirectories( subDirs "${fullSourceDir}" )
	if(NOT subDirs)
		message(FATAL_ERROR "No possible package directories found in directory \"${fullSourceDir}\"")
	endif()

	set(${subdirsOut} ${subDirs} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# This function reads the package version from a packages version file.
function( ccbGetPackageVersionFromFile versionOut package absPackageSourceDir )

	ccbGetPackageVersionFileName( versionFile ${package})
	include("${absPackageSourceDir}/${versionFile}")
	if( "${CPPCODEBASE_${package}_VERSION}" STREQUAL "")
		message(FATAL_ERROR "Could not read value of variable CPPCODEBASE_${package}_VERSION from file \"${absPackageSourceDir}/${versionFile}\"." )
	endif()
	set( ${versionOut} ${CPPCODEBASE_${package}_VERSION} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# This function tries to find the location of a config file with the given configName
# configName can be an absolute file path to a .config.cmake file or the base-name of
# config file which is situated in one of the following directories:
#    <cppcodebase-root>/Configuration     
#    <cppcodebase-root>/Sources
#    <cppcodebase-root>/Sources/CppCodeBase/DefaultConfigurations
#
# If multiple files with the same base-name exist, the one in the directory that comes
# first in the above list is taken.
#
function( ccbFindConfigFile absFilePathOut configName )

	if(EXISTS "${configName}")
		set(absPath "${configName}")
	else()

		set( searchLocations
		"${DIR_OF_PROJECT_UTILITIES}/../../../${CCB_CONFIG_DIR}"
		"${DIR_OF_PROJECT_UTILITIES}/../../../${CCB_SOURCE_DIR}"
		"${DIR_OF_PROJECT_UTILITIES}/../${CCB_DEFAULT_CONFIGS_DIR}"
		)

		foreach( dir ${searchLocations})
			
			ccbNormalizeAbsPath( fullConfigFile "${dir}/${configName}${CCB_CONFIG_FILE_ENDING}" )
			if( EXISTS "${fullConfigFile}" )
				set( absPath "${fullConfigFile}" )
				continue()
			endif()
		endforeach()

		if( NOT absPath )
			message(FATAL_ERROR "Could not find any configuration file with base-name ${configName}.")
		endif()

	endif()
	
	set( ${absFilePathOut} ${absPath} PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the names of cache variables that are defined in a file.
# As a side effect the cache variables are defined after calling this function.
#
function( ccbGetCacheVariablesDefinedInFile variableNamesOut absFilePath )
	
	get_cmake_property( cacheVariablesBefore CACHE_VARIABLES)
	include("${absFilePath}")
	get_cmake_property( cacheVariablesAfter CACHE_VARIABLES)
	ccbGetList1WithoutList2( variableNames "${cacheVariablesAfter}" "${cacheVariablesBefore}" )
	set( ${variableNamesOut} ${variableNames} PARENT_SCOPE)

endfunction()







