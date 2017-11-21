# This script can be used to clear the content of a directory except for a list of entries.
# The entries can be files or subdirectories. Subdirectories are deleted recursively.
#
# Arguments
# ARGUMENT_FILE	- The absolute path to a file that ccbContains the arguments of the script.
#	DIRECTORY	- A cmake variable in the argument file that ccbContains the absolute path to the directory that shall be cleared.
#	ENTRIES		- A cmake variable in the argument file that ccbContains the entries that shall not be deleted from the directory.

include(${CMAKE_CURRENT_LIST_DIR}/../Functions/ccbBaseUtilities.cmake)

ccbAssertScriptArgumentDefined(ARGUMENT_FILE)

include("${ARGUMENT_FILE}")

ccbAssertDefined(DIRECTORY)
ccbAssertDefined(ENTRIES)

file(GLOB existingDirEntriesFull "${DIRECTORY}/*")
set(existingDirEntries)
foreach( fullEntry ${existingDirEntriesFull})
	file(RELATIVE_PATH shortEntry "${DIRECTORY}" "${fullEntry}" )
	list(APPEND existingDirEntries ${shortEntry})
endforeach()

set(deletedEntries)
foreach( entry ${existingDirEntries})
	ccbContains( isPersistentEntry "${ENTRIES}" ${entry})
	if(NOT isPersistentEntry)
		list(APPEND deletedEntries "${DIRECTORY}/${entry}")
	endif()
endforeach()

if(deletedEntries)
	file(REMOVE_RECURSE ${deletedEntries})
endif()
