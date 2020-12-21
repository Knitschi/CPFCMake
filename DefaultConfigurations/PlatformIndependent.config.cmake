
# This file contains basic CMakeProjectFramework default configuration settings that are common for all platforms. 

# LOCATIONS
set( CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../../install" CACHE STRING "The path to which to build results are copied by the install targets.")
set( CPF_WEBSERVER_BASE_DIR "" CACHE STRING "The url of the html base directory of the web-server to which the updateExistingWebPage.cmake script copies the html build-output." )

# OUTPUT NAMES
set( CMAKE_DEBUG_POSTFIX "-debug" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_MINSIZEREL_POSTFIX "-minsizerel" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)
set( CMAKE_RELWITHDEBINFO_POSTFIX "-relwithdebinfo" CACHE STRING "Postfix for libraries build with Debug configuration." FORCE)

# PROJECT SETUP
set( BUILD_SHARED_LIBS OFF CACHE BOOL "Set this to ON to create all production target libraries as shared libries. The fixture libraries and libraries created for executables are always static libraries.")

# PIPELINE TARGETS AND FEATURES
set( CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS OFF CACHE BOOL "Enables targets that create ABI/API compatibility reports and checking." FORCE)
set( CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS OFF CACHE BOOL "If this is set to ON, the pipeline will fail if the current build results contain changes that hurt API compatibility." FORCE)
set( CPF_ENABLE_ACYCLIC_TARGET ON CACHE BOOL "Activates a custom target that checks that the projects target dependency graph is acyclic." FORCE)
set( CPF_ENABLE_CLANG_FORMAT_TARGETS OFF CACHE BOOL "Activates custom targets that run clang-format." FORCE)
set( CPF_ENABLE_CLANG_TIDY_TARGET ON CACHE BOOL "Activates custom targets that run clang-tidy." FORCE)
set( CPF_ENABLE_OPENCPPCOVERAGE_TARGET ON CACHE BOOL "Activates custom targets that run OpenCppCoverage. The targets are only available when compiling with msvc in debug configuration." FORCE)
set( CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION OFF CACHE BOOL "If this is set to ON, the CPF will generate a file that contains a basic documentation page for C++ packages in the doxygen format." FORCE )
set( CPF_ENABLE_PRECOMPILED_HEADER OFF CACHE BOOL "Switch the use of precompiled headers on and off." FORCE)
set( CPF_ENABLE_RUN_TESTS_TARGET ON CACHE BOOL "Activates custom targets that run the test executables." FORCE)
set( CPF_ENABLE_VALGRIND_TARGET ON CACHE BOOL "Activates custom targets that run Valgrind. The targets are only available when compiling with clang or gcc with debug info." FORCE)
set( CPF_ENABLE_VERSION_RC_FILE_GENERATION ON CACHE BOOL "If this is set to ON and the configuration uses the MSVC compiler, the CPF will generate a version.rc file to compile version information into C++ binary targets." FORCE )
set( CPF_HAS_GOOGLE_TEST_EXE FALSE CACHE BOOL "This option is currently only relevant when using Visual Studio with the GoogleTestAdaper. It will cause the CPF to create an empty file <test-exe>.is_google_test which helps the GoogleTestAdaper to discover the tests." FORCE )
set( CPF_ENABLE_DEPENDENCY_NAMES_HEADER_GENERATION OFF CACHE BOOL "Switch for the generation of the .../Sources/<package>/<package>DependencyNames.h files that can be used for versioned namespaces and includes." FORCE)

# OUTPUT VERBOSITY
set( CPF_VERBOSE OFF CACHE BOOL "Increases the output verbosity of the CMakeProjectFramework cmake modules." FORCE)
set( CMAKE_VERBOSE_MAKEFILE OFF CACHE BOOL "Increases the output verbosity of cmake itself." FORCE)
set( HUNTER_STATUS_DEBUG OFF CACHE BOOL "Increases the output verbosity of the hunter package manager cmake module." FORCE)
set( COTIRE_VERBOSE OFF CACHE BOOL "Increases the output verbosity of the cotire cmake module which handles the creation of pre-compiled headers." FORCE)
