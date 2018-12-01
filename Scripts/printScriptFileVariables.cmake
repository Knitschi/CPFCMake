# This script can be used to print all the variables that are defined in another script.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
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