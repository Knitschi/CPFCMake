# This script is the entry for running automated "unit" tests of the CPFCMake package.

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../Functions")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../Variables")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(cpfConstants)
cmake_minimum_required (VERSION ${CPF_MINIMUM_CMAKE_VERSION})

include(cpfListUtilities_tests)
include(cpfMiscUtilities_tests)
include(cpfNumericUtilities_tests)
include(cpfPathUtilities_tests)
include(cpfStringUtilities_tests)

# run tests
cpfRunListUtilitiesTests()
cpfRunMiscUtilitiesTests()
cpfRunNumericUtilitiesTests()
cpfRunPathUtilitiesTests()
cpfRunStringUtilitiesTests()
