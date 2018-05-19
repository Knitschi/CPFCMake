
# This script wraps the execution of the abi-compliance-checker tool in order to intercept its return code. 
# This is necessary because we have to distinguish between non-zero return codes that are caused by broken compliance
# and those that are caused because the the tool failed to run correctly.add_custom_command(
#
# ARGUMENTS:
# TOOL_PATH					The path to the abi-compliance-checker tool.
# BINARY_NAME				The name of the binary for which the report is created. 
# OLD_DUMP_FILE				The dump file for the old version of the library.
# NEW_DUMP_FILE	 			The dump file for the new version of the library.
# REPORT_PATH				The full path to the file which shall hold the report.
# c		Set to NONE, API, ABI. If set, the script will fail if the compatibility is broken.

list(APPEND CMAKE_MODULE_PATH
	${CMAKE_CURRENT_LIST_DIR}/../Functions
)

include(cpfMiscUtilities)

cpfAssertScriptArgumentDefined(TOOL_PATH)
cpfAssertScriptArgumentDefined(BINARY_NAME)
cpfAssertScriptArgumentDefined(OLD_DUMP_FILE)
cpfAssertScriptArgumentDefined(NEW_DUMP_FILE)
cpfAssertScriptArgumentDefined(REPORT_PATH)
cpfAssertScriptArgumentDefined(ENFORCE_COMPATIBILITY)

if( "${ENFORCE_COMPATIBILITY}" STREQUAL NONE )
	set( additionalOptions )
	set( ignoreIncompatibility TRUE)
elseif("${ENFORCE_COMPATIBILITY}" STREQUAL API)
	set( additionalOptions "-api -strict")
	set( ignoreIncompatibility FALSE)
elseif("${ENFORCE_COMPATIBILITY}" STREQUAL ABI)
	set( additionalOptions "-abi -strict" )
	set( ignoreIncompatibility FALSE)
else()
	message( FATAL_ERROR "Invalid ENFORCE_COMPATIBILITY option \"${ENFORCE_COMPATIBILITY}\" in script runAbiComplianceChecker.cmake")
endif()


# make report directory if it does not exist.
#get_filename_component( reportDir "${REPORT_PATH}" DIRECTORY )
#file(MAKE_DIRECTORY ${reportDir} )
separate_arguments(commandList NATIVE_COMMAND "\"${TOOL_PATH}\" -l ${BINARY_NAME} -old \"${OLD_DUMP_FILE}\" -new \"${NEW_DUMP_FILE}\" -report-path \"${REPORT_PATH}\" ${additionalOptions}")

execute_process(
	COMMAND ${commandList}
	RESULT_VARIABLE resultValue
)

# always fail if the abi-compliance-checker did not run properly
if( ${resultValue} GREATER 1 )
	message( FATAL_ERROR "The abi-compliance-checker caused an error.")
endif()

# fail when the two dump files are incompatible and the ignore option is not set
if( NOT ignoreIncompatibility AND ${resultValue} GREATER 0 )
	message( FATAL_ERROR "Error! The ${ENFORCE_COMPATIBILITY} compatibility is broken. See the report \"${REPORT_PATH}\" for more information." )
endif()

