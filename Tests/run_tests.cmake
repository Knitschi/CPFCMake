# This script is the entry for running automated "unit" tests of the CPFCMake package.

include("${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake")
cmake_minimum_required(VERSION ${CPF_MINIMUM_CMAKE_VERSION})

list(APPEND CMAKE_MODULE_PATH 
    "${CMAKE_CURRENT_LIST_DIR}/../Tests"
)

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
