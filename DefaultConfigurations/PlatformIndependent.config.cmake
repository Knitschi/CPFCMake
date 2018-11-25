
# This file contains basic CMakeProjectFramework default configuration settings that are common for all platforms. 

# LOCATIONS
set( CPF_WEBPAGE_URL "" CACHE STRING "The url to the webpage that is created with the updateExistingWebPage.cmake script." )

# OUTPUT NAMES
set( CMAKE_DEBUG_POSTFIX "-debug" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_MINSIZEREL_POSTFIX "-minsizerel" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_RELWITHDEBINFO_POSTFIX "-relwithdebinfo" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)

# PROJECT SETUP
set( CPF_WARNINGS_AS_ERRORS ON CACHE BOOL "Allow the developer to switch the \"warnings as errors\" option temporarily off." FORCE)
set( CPF_ENABLE_PRECOMPILED_HEADER ON CACHE BOOL "Switch the use of precompiled headers on and off." FORCE)
set( BUILD_SHARED_LIBS OFF CACHE BOOL "Set this to ON to create all production target libraries as shared libries. The fixture libraries and libraries created for executables are always static libraries.")

# PIPELINE TARGETS
set( CPF_ENABLE_RUN_TESTS_TARGET ON CACHE BOOL "Activates custom targets that run the test executables." FORCE)
set( CPF_ENABLE_DOXYGEN_TARGET ON CACHE BOOL "Activates a custom target that runs doxygen on the entire CPF project." FORCE)
set( CPF_ENABLE_CLANG_TIDY_TARGET ON CACHE BOOL "Activates custom targets that run clang-tidy." FORCE)
set( CPF_ENABLE_ACYCLIC_TARGET ON CACHE BOOL "Activates a custom target that checks that the projects target dependency graph is acyclic." FORCE)
set( CPF_ENABLE_VALGRIND_TARGET ON CACHE BOOL "Activates custom targets that run Valgrind. The targets are only available when compiling with clang or gcc with debug info." FORCE)
set( CPF_ENABLE_OPENCPPCOVERAGE_TARGET ON CACHE BOOL "Activates custom targets that run OpenCppCoverage. The targets are only available when compiling with msvc in debug configuration." FORCE)
set( CPF_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS OFF CACHE BOOL "Enables targets that create ABI/API compatibility reports and checking." FORCE)
set( CPF_CHECK_API_STABLE OFF CACHE BOOL "If this is set to ON, the pipeline will fail if the current build results contain changes that hurt API compatibility." FORCE)
set( CPF_CHECK_ABI_STABLE OFF CACHE BOOL "If this is set to ON, the pipeline will fail if the current build results contain changes that hurt ABI compatibility." FORCE)

# OUTPUT VERBOSITY
set( CPF_VERBOSE OFF CACHE BOOL "Increases the output verbosity of the CMakeProjectFramework cmake modules." FORCE)
set( CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Increases the output verbosity of cmake itself." FORCE)
set( HUNTER_STATUS_DEBUG OFF CACHE BOOL "Increases the output verbosity of the hunter package manager cmake module." FORCE)
set( COTIRE_VERBOSE OFF CACHE BOOL "Increases the output verbosity of the cotire cmake module which handles the creation of pre-compiled headers." FORCE)

