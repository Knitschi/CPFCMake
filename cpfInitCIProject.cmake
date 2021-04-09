
include("${CMAKE_CURRENT_LIST_DIR}/cpfInit.cmake" NO_POLICY_SCOPE)

cmake_minimum_required(VERSION ${CPF_MINIMUM_CMAKE_VERSION})

include(cpfConfigUtilities)
include(cpfMiscUtilities)
include(cpfAssertions)

# We include the config file here to retrigger the cmake generate step when the config changes.
cpfAssertDefined(CPF_CONFIG)    # CPF config must be either defined by the buildscripts or in the cache file.
cpfFindConfigFile(configFile "${CPF_CONFIG}" TRUE)
include("${configFile}")

cpfAssertDefined(CMAKE_TOOLCHAIN_FILE)  # The config file must define the CMAKE_TOOLCHAIN_FILE
include("${CMAKE_TOOLCHAIN_FILE}")      # Make sure the compiler is set before the project call.

# Include some commonly used modules.
include(cpfAddPackages)
include(cpfInitPackageProject)
include(cpfAddCppPackage)

