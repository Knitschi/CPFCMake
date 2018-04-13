# This file contains functions that work on pathes in the filesystem


#----------------------------------------------------------------------------------------
# Writes the name of the immediate parent directory to parantDirOut
function ( cpfGetParentDirectory parantDirOut absDirOrFilePath )
	
	get_filename_component( dir ${absDirOrFilePath} DIRECTORY)
	string(FIND ${dir} "/" index REVERSE)			# get the index of the last directory separator
	cpfIncrement(index)
	cpfRightSideOfString(dirName ${dir} ${index})
	set( ${parantDirOut} ${dirName}  PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the names of the subdirectories within a given directory
# 
function( cpfGetSubdirectories dirsOut absDir )

  file(GLOB children RELATIVE ${absDir} ${absDir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${absDir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()

  set(${dirsOut} ${dirlist} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Checks if subdir is a subdirectory of dir.
# e.g.: subPath = C:/bla/blub/blib, path = C:/bla  -> returns TRUE
#		subPath = C:/bla/blub/blib, path = C:/bleb -> returns FALSE
#
# Note that pathes must use / as a separator.
function( cpfIsSubPath VAR subPath path)
	
	set(${VAR} FALSE PARENT_SCOPE )
	string(FIND ${path} ${subPath} index)
	if(${index} EQUAL 0)
		set(${VAR} TRUE PARENT_SCOPE )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# Returns the drive name on windows and / on linux. If the given path is relative
# VAR is set to NOTFOUND.
#
function( cpfGetPathRoot VAR absPath)

	string(SUBSTRING ${absPath} 0 1 firstChar)

	if(CMAKE_HOST_UNIX)

		if(NOT ${firstChar} STREQUAL /)
			set(${VAR} NOTFOUND PARENT_SCOPE)
			return()
		endif()
		set(${VAR} / PARENT_SCOPE)

	elseif(CMAKE_HOST_WIN32)

		string(SUBSTRING ${absPath} 1 1 secondChar)
		if(NOT ${secondChar} STREQUAL :)
			set(${VAR} NOTFOUND PARENT_SCOPE)
			return()
		endif()
		set(${VAR} ${firstChar} PARENT_SCOPE)

	else()
		message(FATAL_ERROR "Function cpfGetPathRoot() needs to be extended to work on the current host platform.")
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# returns true if the given path is absolute 
function( cpfIsAbsolutePath boolOut path)
	cpfGetPathRoot( root ${path})
	if( ${root} STREQUAL NOTFOUND )
		set( ${boolOut} FALSE PARENT_SCOPE)
	else()
		set( ${boolOut} TRUE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# removes .. dirUp directories from absolute paths.
function( cpfNormalizeAbsPath normedPathOut absPath)
	cpfGetPathRoot( root "${absPath}")
	get_filename_component( normedPath "${absPath}" ABSOLUTE BASE_DIR ${root} )
	set( ${normedPathOut} "${normedPath}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# returns multiple relative paths from the fromPath to the toPaths
function( cpfGetRelativePaths relPathsOut fromPath toPaths )
	set(relPaths)
	foreach( toPath ${toPaths})
		file(RELATIVE_PATH relPath ${fromPath} ${toPath})
		list(APPEND relPaths ${relPath})
	endforeach()
	set(${relPathsOut} ${relPaths} PARENT_SCOPE)
endfunction()