
# This file contains CMakeProjectFramework default configuration settings that are specific to the Linux platform.

include( "${CMAKE_CURRENT_LIST_DIR}/PlatformIndependent.config.cmake" )

# GENERATOR AND TOOLCHAIN
set( CMAKE_GENERATOR "Unix Makefiles" CACHE STRING "The CMake generator" FORCE)
# It seems that on Linux the CMAKE_MAKE_PROGRAM is set before reaching the project() command.
# This means that we can not leave it empty here like on windows where it is determined when
# calling project()
set( CMAKE_MAKE_PROGRAM "make" CACHE STRING "For some generators the make program must be set manually." FORCE)
set( CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/Gcc.cmake" CACHE PATH "The file that defines the compiler and compile options for all compile configurations." FORCE)
set( CMAKE_BUILD_TYPE "Debug" CACHE STRING "The compile configuration used by single configuration make tools." FORCE)

# LOCATIONS
set( HUNTER_ROOT "$ENV{HOME}/HunterPackages" CACHE PATH "The directory where the package manager will download and compile external packages." FORCE)
set( CPF_TEST_FILES_DIR "$ENV{HOME}/temp/CPF_tests/${CPF_CONFIG}" CACHE PATH "The directory under which the automated tests may create temporary files." FORCE) 


