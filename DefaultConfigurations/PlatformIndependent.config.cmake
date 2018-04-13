
# This file contains basic CMakeProjectFramework default configuration settings that are common for all platforms. 

# LOCATIONS
set( CPF_WEBPAGE_URL "" CACHE STRING "The url to the webpage that is created with the updateExistingWebPage.cmake script." )
set( CPF_PLANT_UML_JAR "" CACHE FILEPATH "Setting a path to the plantuml.jar file enables defining UML diagrams in Doxygen comments.")

# OUTPUT NAMES
set( CMAKE_DEBUG_POSTFIX "-debug" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_MINSIZEREL_POSTFIX "-minsizerel" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_RELWITHDEBINFO_POSTFIX "-relwithdebinfo" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)

# PROJECT SETUP
set( CPF_WARNINGS_AS_ERRORS ON CACHE BOOL "Allow the developer to switch the \"warnings as errors\" option temporarily off." FORCE)
set( CPF_ENABLE_PRECOMPILED_HEADER ON CACHE BOOL "Switch the use of precompiled headers on and off." FORCE)
set( BUILD_SHARED_LIBS OFF CACHE BOOL "Set this to ON to create all production target libraries as shared libries. The fixture libraries and libraries created for executables are always static libraries.")

# PIPELINE TARGETS
set( CPF_ENABLE_RUN_TESTS_TARGET ON CACHE BOOL "Add targets that will run the test executables when build. The targets can be used to get a quick code, test, code, test cycle." FORCE)
set( CPF_ENABLE_DOXYGEN_TARGET ON CACHE BOOL "Adds a target that will run doxygen on the entire CPF project." FORCE)
set( CPF_ENABLE_STATIC_ANALYSIS_TARGET ON CACHE BOOL "Adds a target that mainly runs clang-tidy on the CPF project." FORCE)
set( CPF_ENABLE_DYNAMIC_ANALYSIS_TARGET ON CACHE BOOL "Adds a target that runs OpenCppCoverage on Windows and Valgrind on Linux." FORCE)
set( CPF_ENABLE_ABI_API_COMPATIBILITY_CHECK_TARGETS OFF CACHE BOOL "Enables targets that create ABI/API compatibility reports and checking." FORCE)
set( CPF_CHECK_API_STABLE OFF CACHE BOOL "If this is set to ON, the pipeline will fail if the current build results contain changes that hurt API compatibility." FORCE)
set( CPF_CHECK_ABI_STABLE OFF CACHE BOOL "If this is set to ON, the pipeline will fail if the current build results contain changes that hurt ABI compatibility." FORCE)

# OUTPUT VERBOSITY
set( CPF_VERBOSE OFF CACHE BOOL "Increases the output verbosity of the CMakeProjectFramework cmake modules." FORCE)
set( CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Increases the output verbosity of cmake itself." FORCE)
set( HUNTER_STATUS_DEBUG OFF CACHE BOOL "Increases the output verbosity of the hunter package manager cmake module." FORCE)
set( COTIRE_VERBOSE OFF CACHE BOOL "Increases the output verbosity of the cotire cmake module which handles the creation of pre-compiled headers." FORCE)

