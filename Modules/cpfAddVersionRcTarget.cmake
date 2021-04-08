include_guard(GLOBAL)

include(cpfCustomTargetUtilities)
include(cpfTargetUtilities)
include(cpfMiscUtilities)

#---------------------------------------------------------------------------------------------
# This function adds a custom target when compiling with MSVC that generates the version.rc
# resource file that provides the information that can be seen in the properties of the
# generated binary files.
#
# Arguments see API doc.
# 
function( cpfAddVersionRcTarget )

    set( requiredSingleValueKeywords
        PACKAGE
        BINARY_TARGET
        VERSION
    )

    set( optionalSingleValueKeywords 
        BRIEF_DESCRIPTION
        OWNER
    )

    cmake_parse_arguments( ARG "" "${requiredSingleValueKeywords};${optionalSingleValueKeywords}" "" ${ARGN} )
    cpfAssertKeywordArgumentsHaveValue( "${requiredSingleValueKeywords}" ARG "cpfAddVersionRcTarget()")

	# Interface libs have no binary file to which we could write version information.
	# Static libraries do not seem to have the version info attributes.
	cpfIsInterfaceLibrary(isIntLib ${ARG_BINARY_TARGET})
	cpfIsStaticLibrary(isStaticLib ${ARG_BINARY_TARGET})
	if(isIntLib OR isStaticLib)
		return()
	endif()

	# .rc files are only used by msvc
	if(NOT MSVC)
		return()
    endif()

    set(targetName ${ARG_BINARY_TARGET}_versionRc )

    # Locations
    set(configureScript "${CPF_ABS_SCRIPT_DIR}/configureFile.cmake")
    set(versionRcTemplate "${CPF_ABS_TEMPLATE_DIR}/version.rc.in")
    set(versionRcGenerated "${CMAKE_CURRENT_BINARY_DIR}/${ARG_BINARY_TARGET}_version.rc")
    
    # Gather the values for the configure variables
    cpfGetRCFileType( FILE_TYPE ${ARG_BINARY_TARGET} )
    cpfGetCopyRightNotice( COPY_RIGHT "${ARG_OWNER}" )
	cpfSplitVersion( major minor patch commitId ${ARG_VERSION} )
	cpfGetCommitsSinceLastRelease( commitNr ${ARG_VERSION} )
	set(fileflags)
	if(commitId)
		cpfListAppend(fileflags "VS_FF_PRERELEASE")
	endif()
	cpfIsDirtyVersion( isDirty ${ARG_VERSION})
	if(isDirty)
		cpfListAppend(fileflags "VS_FF_PRIVATEBUILD")
	endif() 
	cpfJoinString( fileFlagsString "${fileflags}" " | ")
	if(NOT fileFlagsString)
		set(fileFlagsString "0x0L")	# The build files if no flag is given. This is the null flag.
	endif()

    # We can not use the $<TARGET_FILE_NAME:${ARG_BINARY_TARGET}> generator expression here
	# to get the filename of the binary target because that would introduce a cyclic dependency.
	# In order to work around this we get the static output filenames here an wrap them in config generator expressions.
	set(targetFileName)
	cpfGetConfigurations(configs)
	foreach(config ${configs})
		cpfGetTargetOutputFileName(shortName ${ARG_BINARY_TARGET} ${config})
		string(APPEND targetFileName "$<$<CONFIG:${config}>:${shortName}>")
	endforeach()

    set( dOptions 
        "ABS_SOURCE_PATH=\"${versionRcTemplate}\""
		"ABS_DEST_PATH=\"${versionRcGenerated}\""
		"OWNER=\"${ARG_OWNER}\""
        "PACKAGE=${ARG_PACKAGE}"
        "PACKAGE_VERSION=${ARG_VERSION}"
		"PACKAGE_VERSION_SHORT=\"${major}, ${minor}, ${patch}, ${commitNr}\""
        "BRIEF_DESCRIPTION=\"${ARG_BRIEF_DESCRIPTION}\""
        "TARGET=${ARG_BINARY_TARGET}"
        "FILE_NAME=${targetFileName}"
		"FILE_TYPE=${FILE_TYPE}"
		"FILE_FLAGS=\"${fileFlagsString}\""
        "COPY_RIGHT=\"${COPY_RIGHT}\""
    )

	cpfGetRunCMakeScriptCommand( createRcFileCommand "${configureScript}" "${dOptions}")

	cpfAddStandardCustomCommand(
		COMMANDS ${createRcFileCommand}
		OUTPUT ${versionRcGenerated}
	)

	cpfAddStandardCustomTarget(
		PACKAGE ${ARG_PACKAGE}
		TARGET ${targetName}
		VS_SUBDIR private
		PRODUCED_FILES ${versionRcGenerated}
	)

	# Make sure the file is generated before the binary target is build.
	add_dependencies(${ARG_BINARY_TARGET} ${targetName})

    # Add the generated files to the binary targets sources to ensure the information is compiled into it.
	set_property(TARGET ${ARG_BINARY_TARGET} APPEND PROPERTY SOURCES ${versionRcGenerated} )

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetRCFileType typeOut target )

	cpfIsExecutable(isExe ${target})
	cpfIsDynamicLibrary(isDynamicLib ${target})

	if(isExe)
		set(${typeOut} VFT_APP PARENT_SCOPE)
	elseif(isDynamicLib)
		set(${typeOut} VFT_DLL PARENT_SCOPE)
	else()	# Must be a static library
		set(${typeOut} VFT_STATIC_LIB PARENT_SCOPE)
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetCopyRightNotice noticeOut owner )
    
    if(owner)
        string(TIMESTAMP year "%Y")
        set(${noticeOut} "Copyright ${year} ${owner}" PARENT_SCOPE)
    else()
        set(${noticeOut} "" PARENT_SCOPE)
    endif()

endfunction()