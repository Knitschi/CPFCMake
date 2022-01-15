
# This file contains basic CMakeProjectFramework default configuration settings that are common for all platforms. 

# PIPELINE TARGETS AND FEATURES
set( CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS FALSE CACHE BOOL "Enables targets that create ABI/API compatibility reports and checking." FORCE)
set( CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS FALSE CACHE BOOL "If this is set to ON, the pipeline will fail if the current build results contain changes that hurt API compatibility." FORCE)
set( CPF_ENABLE_ACYCLIC_TARGET FALSE CACHE BOOL "Activates a custom target that checks that the projects target dependency graph is acyclic." FORCE)
set( CPF_ENABLE_CLANG_FORMAT_TARGETS FALSE CACHE BOOL "Activates custom targets that run clang-format." FORCE)
set( CPF_ENABLE_CLANG_TIDY_TARGET FALSE CACHE BOOL "Activates custom targets that run clang-tidy." FORCE)
set( CPF_ENABLE_OPENCPPCOVERAGE_TARGET FALSE CACHE BOOL "Activates custom targets that run OpenCppCoverage. The targets are only available when compiling with msvc in debug configuration." FORCE)
set( CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION FALSE CACHE BOOL "If this is set to ON, the CPF will generate a file that contains a basic documentation page for C++ package-components in the doxygen format." FORCE )
set( CPF_ENABLE_PRECOMPILED_HEADER FALSE CACHE BOOL "Switch the use of precompiled headers on and off." FORCE)
set( CPF_ENABLE_TEST_EXE_TARGETS TRUE CACHE BOOL "Switch to globally remove all test executables from the project. This can be used to speed up the build when there is no intrestest in the tests." FORCE)
set( CPF_ENABLE_RUN_TESTS_TARGET TRUE CACHE BOOL "Activates custom targets that run the test executables." FORCE)
set( CPF_ENABLE_VALGRIND_TARGET FALSE CACHE BOOL "Activates custom targets that run Valgrind. The targets are only available when compiling with clang or gcc with debug info." FORCE)

# LOCATIONS
set( CPF_WEBSERVER_BASE_DIR "" CACHE STRING "The url of the html base directory of the web-server to which the updateExistingWebPage.cmake script copies the html build-output." )
set( CPF_TEST_FILES_DIR "" CACHE PATH "The directory under which the automated tests may create temporary files." FORCE) 

# OUTPUT VERBOSITY
set( CPF_VERBOSE FALSE CACHE BOOL "Increases the output verbosity of the CMakeProjectFramework cmake modules." FORCE)

# Overridden CMake variables.
set( CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../../install" CACHE STRING "The path to which to build results are copied by the install targets.")
set( CMAKE_DEBUG_POSTFIX "-debug" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_MINSIZEREL_POSTFIX "-minsizerel" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_RELWITHDEBINFO_POSTFIX "-relwithdebinfo" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
