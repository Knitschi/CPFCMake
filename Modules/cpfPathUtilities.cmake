# This file contains functions that work on pathes in the filesystem

include_guard(GLOBAL)

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
      cpfListAppend( dirlist ${child})
    endif()
  endforeach()

  set(${dirsOut} ${dirlist} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Checks if subdir is a subdirectory of dir.
# e.g.: longPath = C:/bla/blub/blib, shortPath = C:/bla  -> returns TRUE
#		longPath = C:/bla/blub/blib, shortPath = C:/bleb -> returns FALSE
#
# Note that pathes must use / as a separator.
function( cpfIsSubPath VAR longPath shortPath)
	
	set(${VAR} FALSE PARENT_SCOPE )
	string(FIND ${longPath} ${shortPath} index)
	if(${index} EQUAL 0)
		set(${VAR} TRUE PARENT_SCOPE )
	endif()

endfunction()

#----------------------------------------------------------------------------------------
# returns only the pathes in longPaths that are subpaths of the given shortPath
function( cpfGetSubPaths subPathsOut shortPath longPaths)
	set(subPaths)
	foreach( path ${longPaths})
		cpfIsSubPath( isSubPath ${path} ${shortPath})
		if(isSubPath)
			cpfListAppend( subPaths ${path})
		endif()
	endforeach()
	set(${subPathsOut} "${subPaths}" PARENT_SCOPE)
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
# Returns true if the given path is absolute.
function( cpfIsAbsolutePath boolOut path)
	cpfGetPathRoot( root ${path})
	if( ${root} STREQUAL NOTFOUND )
		set( ${boolOut} FALSE PARENT_SCOPE)
	else()
		set( ${boolOut} TRUE PARENT_SCOPE)
	endif()
endfunction()

#----------------------------------------------------------------------------------------
# Removes .. dirUp directories from absolute paths.
function( cpfNormalizeAbsPath normedPathOut absPath)
	cpfGetPathRoot( root "${absPath}")
	get_filename_component( normedPath "${absPath}" ABSOLUTE BASE_DIR ${root} )
	set( ${normedPathOut} "${normedPath}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns multiple relative paths from the fromPath to the toPaths
function( cpfGetRelativePaths relPathsOut fromPath toPaths )
	set(relPaths)
	foreach( toPath ${toPaths})
		file(RELATIVE_PATH relPath ${fromPath} ${toPath})
		cpfListAppend( relPaths ${relPath})
	endforeach()
	set(${relPathsOut} "${relPaths}" PARENT_SCOPE)
endfunction()

#----------------------------------------------------------------------------------------
# Returns the filenames in the given list that have one of the given extensions.
# The extensions must be given without the leading dot.
#
function( cpfGetFilepathsWithExtensions pathsOut filePaths extensions)

	# Prepare a regular expression that matches the extensions.
	cpfJoinString( oredExtensionMatcher "${extensions}" "|" )
	set(regExp ".*\\.(${oredExtensionMatcher})$")

	# Get the files and return them.
	cpfGetElementsMatching( list "${filePaths}" ${regExp} )
	set(${pathsOut} "${list}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns the short filenames of the given file-paths.
function( cpfGetShortFilenames namesOut filePaths )
	
	set(shortNames)
	foreach(path ${filePaths})
		get_filename_component(shortName ${path} NAME)
		cpfListAppend(shortNames ${shortName})
	endforeach()
	set(${namesOut} "${shortNames}" PARENT_SCOPE)

endfunction()


