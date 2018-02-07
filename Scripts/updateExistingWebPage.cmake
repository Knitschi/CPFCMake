
# This script can be used by the build-server to copy the recently generated content of the html directory 
# to an existing html-directory on a web-server. The script replaces obsolete files with the new versions
# while leaving content in the target directory that should not be deleted like previously released packages.
#
# Arguments:
# TARGET_DIR		- The html directory with the existing page on the web-server.
# SOURCE_DIR		- The html directory that was created by the last build.
# ROOT_DIR: 		- The root directory of a CPF project.

include(${CMAKE_CURRENT_LIST_DIR}/../Variables/cpfLocations.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfBaseUtilities.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../Functions/cpfProjectUtilities.cmake)

cpfAssertScriptArgumentDefined(TARGET_DIR)
cpfAssertScriptArgumentDefined(SOURCE_DIR)
cpfAssertScriptArgumentDefined(ROOT_DIR)

# Delete directories that are obsolete in the target directory.
file(REMOVE_RECURSE "${TARGET_DIR}/${CPF_DOXYGEN_DIR}")
file(REMOVE_RECURSE "${TARGET_DIR}/${CPF_CGI_BIN_DIR}/doxysearch.db")
file(REMOVE_RECURSE "${TARGET_DIR}/${CPF_OPENCPPCOVERAGE_DIR}")

cpfGetSourcesSubdirectories( packages "${ROOT_DIR}" )
foreach( package ${packages})
	
	# distribution packages
	cpfGetRelLastBuildPackagesDir( dir ${package})
	file(REMOVE_RECURSE "${TARGET_DIR}/${dir}")

	# abi/api reports
	cpfGetRelCurrentToLastBuildReportDir( dir ${package} )
	file(REMOVE_RECURSE "${TARGET_DIR}/${dir}")
	cpfGetRelCurrentToLastReleaseReportDir( dir ${package})
	file(REMOVE_RECURSE "${TARGET_DIR}/${dir}")

endforeach()

# Copy the content of the html directory to target html directory
file(COPY "${SOURCE_DIR}/" DESTINATION "${TARGET_DIR}" FILES_MATCHING PATTERN "*" )
