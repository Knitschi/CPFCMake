# This script can be used to print all the variables that are defined in another script.


list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../Functions)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../Variables)

include(cpfConstants)
cmake_minimum_required(VERSION ${CPF_MINIMUM_CMAKE_VERSION})

include(cpfProjectUtilities)
include(cpfMiscUtilities)

# This script requires the absolute path to the examinded script file stored in SCRIPT_PATH
cpfAssertScriptArgumentDefined(SCRIPT_PATH)

cpfReadVariablesFromFile( variables values "${SCRIPT_PATH}")

set(index 0)
foreach( variable ${variables})
    list(GET values ${index} value)
    message("${variable}=${value}")
    cpfIncrement(index)
endforeach()