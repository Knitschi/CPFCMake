# This file contains functions that contain project and target related helper functionality.

include_guard(GLOBAL)

include(cpfLocations)
include(cpfConstants)
include(cpfListUtilities)
include(cpfStringUtilities)
include(cpfPathUtilities)
include(cpfReadVariablesFromFile)

#---------------------------------------------------------------------------------------------
function( cpfGetHighWarningLevelFlags flagsOut )

	cpfGetCompiler(compiler)
    if(${compiler} STREQUAL Vc)
        set(${flagsOut} "/W4" PARENT_SCOPE)       
    elseif(${compiler} STREQUAL Gcc )
		set(${flagsOut} -Wpedantic -Wall -Wextra PARENT_SCOPE)   
    elseif(${compiler} STREQUAL Clang)
		set(${flagsOut} -Wpedantic -Wall -Wextra -Wthread-safety PARENT_SCOPE)   
    endif()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetWarningsAsErrorFlag flagOut )

	cpfGetCompiler(compiler)
    if(${compiler} STREQUAL Vc)
		set(${flagOut} "/WX" PARENT_SCOPE)
    elseif(${compiler} STREQUAL Gcc)
        set(${flagOut} "-Werror" PARENT_SCOPE)
    elseif(${compiler} STREQUAL Clang)
		set(${flagOut} "-Werror" PARENT_SCOPE)
    endif()

endfunction()

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
function( cpfCompilerProducesPdbFiles hasPdbOutput config )

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

	cpfCompilerProducesPdbFiles( hasPdbCompileOutput ${config})
	
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

