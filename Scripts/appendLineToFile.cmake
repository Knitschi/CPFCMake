# This scirpt is used as an replacement for "cmake -E echo bla >> blub.txt" commands.
# Echo seems to be fragile in combination with single escaped quotes and >>.
#
# Arguments
# FILE      - The file to which a line shall be appended.
# LINE      - The content of the added line.

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
include(cpfMiscUtilities)

cpfAssertScriptArgumentDefined(FILE)
cpfAssertScriptArgumentDefined(LINE)

file( APPEND "${FILE}" "${LINE}\n")
