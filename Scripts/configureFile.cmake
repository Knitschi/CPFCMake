# This script can be used to call cmakes configure_file() function at build time.
#
# The variables that are supposed to be replaced in the template must be given as
# additional script arguments.
# The template file must use the @@ syntax for replaced variables.

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../Functions)
include(cpfMiscUtilities)

cpfAssertScriptArgumentDefined(ABS_SOURCE_PATH) # The absolute path to the file template.
cpfAssertScriptArgumentDefined(ABS_DEST_PATH)   # The absolute path to the generated path.

configure_file("${ABS_SOURCE_PATH}" "${ABS_DEST_PATH}" @ONLY)
