
# This file contains CMakeProjectFramework default configuration settings that are specific to the Windows platform. 
include( "${CMAKE_CURRENT_LIST_DIR}/PlatformIndependent.config.cmake" )

# GENERATOR AND TOOLCHAIN
set( CMAKE_GENERATOR "Visual Studio 16 2019" CACHE STRING "The CMake generator" FORCE) # When using the "Visual Studio" generators, this must be compatible to the compiler that is defined in the CMAKE_TOOLCHAIN_FILE
set( CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/MSVC2017.cmake" CACHE PATH "The file that defines the compiler and compile options for all compile configurations." FORCE)

# LOCATIONS
file( TO_CMAKE_PATH "$ENV{TEMP}\\CPF_tests\\${CPF_CONFIG}" testDir)
set( CPF_TEST_FILES_DIR "${testDir}" CACHE PATH "The directory under which the automated tests may create temporary files." FORCE) 
