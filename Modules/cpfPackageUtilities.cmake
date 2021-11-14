include_guard(GLOBAL)


#-----------------------------------------------------------
# Returns the name of the current source directory as packageNameOut.
#
function(cpfGetCurrentSourceDir dirOut)

    cpfGetParentDirectory( dir "${CMAKE_CURRENT_SOURCE_DIR}/blub")
    set(${dirOut} "${dir}" PARENT_SCOPE)

endfunction()

#-----------------------------------------------------------------------------------------
# Checks if the package name matches the pattern that has the version added in a postfix
# e.g. myPackage_6_344_65_232_asd5434f3
# If that is the case it splits the name into the unversioned part and the version postfix
# and returns it.
#
function( cpfGetUnversionedPackageComponentName isVersionedNameOut unversionedNameOut versionPostfixOut packageComponent)

	string(REGEX MATCH "^(.*)(_[0-9]*_[0-9]*_[0-9]*)(_[0-9]*_[a-z0-9]*)?$" dummy "${packageComponent}")

	if(CMAKE_MATCH_2)
		set(${isVersionedNameOut} FALSE PARENT_SCOPE)
		set(${unversionedNameOut} ${CMAKE_MATCH_1} PARENT_SCOPE)
		set(${versionPostfixOut} ${CMAKE_MATCH_2} PARENT_SCOPE)
	elseif()
		set(${isVersionedNameOut} FALSE PARENT_SCOPE)
		set(${unversionedNameOut} "${packageComponent}" PARENT_SCOPE)
		set(${versionPostfixOut} "" PARENT_SCOPE)
	endif()

endfunction()

#------------------------------------------------------------------------------------------
function( cpfIsMultiComponentPackage isMultiOut package )

	cpfGetAbsPackageDirectory(packageDir ${package} "${CPF_ROOT_DIR}")
	get_property(components DIRECTORY ${packageDir} PROPERTY CPF_PACKAGE_COMPONENTS)
	if("${components}" STREQUAL SINGLE_COMPONENT)
		set(${isMultiOut} FALSE PARENT_SCOPE)
	else()
		set(${isMultiOut} TRUE PARENT_SCOPE)
	endif()

endfunction()

#------------------------------------------------------------------------------------------
# Takes the variable name of the source file variable and appends the package level files
# to it if the package is a single component package.
#
function( cpfAddPackageSources sourcesVarName package )

	cpfIsMultiComponentPackage(isMulti ${package})
	if(NOT isMulti)
		cpfGetAbsPackageDirectory(packageDir ${package} "${CPF_ROOT_DIR}")
		get_property(packageSources DIRECTORY ${packageDir} PROPERTY CPF_PACKAGE_SOURCES)
		set(${sourcesVarName} "${${sourcesVarName}};${packageSources}" PARENT_SCOPE)
	endif()

endfunction()

#------------------------------------------------------------------------------------------
# Returns either ${package} for single component packages and  ${package}/${packageComponent} 
# for multi component packages
#
function( cpfGetComponentVSFolder folderOut package packageComponent )

	cpfIsMultiComponentPackage(isMulti ${package})
	if(isMulti)
		set(${folderOut} ${package}/${packageComponent} PARENT_SCOPE)
	else()
		set(${folderOut} ${package} PARENT_SCOPE)
	endif()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetExecutableTargets exeTargetsOut packageComponent )
	
	set(exeTargets)

	cpfIsExecutable(isExe ${packageComponent})
	if(isExe)
		cpfListAppend( exeTargets ${packageComponent})
	endif()

	get_property( testTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET )
	if(testTarget)
		list(APPEND exeTargets ${testTarget})
	endif()

	set(${exeTargetsOut} "${exeTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetProductionTargets productionTargetsOut packageComponent)
	
	set(targets ${packageComponent})
	
	cpfIsExecutable(isExe ${packageComponent})
	if(isExe)
		get_property( prodLibTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET )
		cpfListAppend(targets ${prodLibTarget})
	endif()

	set(${productionTargetsOut} ${targets} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the binary sub-targets that are of type SHARED_LIBRARY or MODULE_LIBRARY.
function( cpfGetSharedLibrarySubTargets librarySubTargetsOut packageComponent)

	set(libraryTargets)
	get_property( binaryTargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)
	foreach( binaryTarget ${binaryTargets})
		cpfIsDynamicLibrary( isDynamic ${binaryTarget})
		if(isDynamic)
			cpfListAppend( libraryTargets ${binaryTarget})
		endif()
	endforeach()
	
	set( ${librarySubTargetsOut} "${libraryTargets}" PARENT_SCOPE)
	
endfunction()

#----------------------------------------------------------------------------------------
# Returns a list with the binary sub-targets that will be shared libraries if
# the BUILD_SHARED_LIBS option is set to ON.
function( cpfGetPossiblySharedLibrarySubTargets librarySubTargetsOut packageComponent)

	set(libraryTargets)

	cpfIsExecutable(isExe ${packageComponent})
	if(NOT isExe)
		cpfListAppend( libraryTargets ${packageComponent})
	endif()

	get_property( fixtureTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET)
	if(TARGET ${fixtureTarget})
		cpfListAppend( libraryTargets ${fixtureTarget})
	endif()

	set( ${librarySubTargetsOut} "${libraryTargets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetTestTargets testTargetsOut packageComponent )

	set(targets)

	get_property( fixtureTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET )
	if(fixtureTarget)
		cpfListAppend(targets ${fixtureTarget})
	endif()

	get_property( testExeTarget TARGET ${packageComponent} PROPERTY INTERFACE_CPF_TESTS_SUBTARGET )
	if(testExeTarget)
		cpfListAppend(targets ${testExeTarget})
	endif()

	set(${testTargetsOut} ${targets} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetSubtargets subTargetsOut packageComponents subtargetProperty)

	set(targets)
	foreach(packageComponent ${packageComponents})
		if(TARGET ${packageComponent}) # not all package-components have targets
			
			# check for subtargets that belong to the main package-component target
			get_property(subTarget TARGET ${packageComponent} PROPERTY ${subtargetProperty})
			cpfListAppend( targets ${subTarget} )

			# check for subtargets that belong to the binary targets
			get_property(binaryTargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)
			foreach(binaryTarget ${binaryTargets})
				get_property(subTarget TARGET ${binaryTarget} PROPERTY ${subtargetProperty})
				cpfListAppend( targets ${subTarget} )
			endforeach()
			
		endif()
	endforeach()

	set(${subTargetsOut} "${targets}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns all packages from the packages.cmake file
#
function( cpfGetAllPackages packagesOut )

	set(packages)

	cpfGetPackageVariableLists( listNames ${CPF_ROOT_DIR} packageVariables)
	foreach(listName ${listNames})
		cmake_parse_arguments(ARG "" "OWNED" "" ${${listName}})
		cmake_parse_arguments(ARG "" "EXTERNAL" "" ${${listName}})

		if(ARG_OWNED)
			cpfListAppend(packages ${ARG_OWNED})
		elseif(ARG_EXTERNAL)
			cpfListAppend(packages ${ARG_EXTERNAL})
		else()
			message(FATAL_ERROR "Error! Unexpected case when parsing CPF_PACKAGES lists.")
		endif()

	endforeach()

	set(${packagesOut} "${packages}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetPackageVariableLists packageVariableListsOut rootDir outputListBaseName )

	cpfReadPackagesVariable(packages "${rootDir}")

	# Assert the list starts with the OWNED or EXTERNAL keyword.
	list(GET packages 0 firstElement)
	isOwnedOrExternal( isFittingKeyword ${firstElement} )
	if(NOT isFittingKeyword)
		message(FATAL_ERROR "Error! The first element in the CPF_PACKAGES variable in the packages.cmake file must be either OWNED or EXTERNAL.")
	endif()

	set(packageIndex -1)
	set(currentVariableList)
	foreach(element ${packages})
		
		isOwnedOrExternal( isNewPackageKeyword ${element} )
		if(isNewPackageKeyword)
			cpfIncrement(packageIndex)
			set(currentVariableList ${outputListBaseName}${packageIndex})
			cpfListAppend(packageVariableLists ${currentVariableList})
		endif()

		cpfListAppend(${currentVariableList} ${element})

	endforeach()

	set( ${packageVariableListsOut} "${packageVariableLists}" PARENT_SCOPE)
	foreach( subList ${packageVariableLists})
		set( ${subList} "${${subList}}" PARENT_SCOPE )
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# Reads the value of the CPF_PACKAGES variable from the ci-projects owned packages file
# and returns its value.
function( cpfReadPackagesVariable packagesOut rootDir )

	set(fullOwnedPackagesFile "${rootDir}/${CPF_SOURCE_DIR}/${CPF_PACKAGES_FILE}")
	# create an owned packages file if none exists
	if(NOT EXISTS ${fullOwnedPackagesFile} )
		# we use the manual existance check to prevent overwriting the file when the template changes.
		configure_file("${CPF_ABS_TEMPLATE_DIR}/${CPF_PACKAGES_FILE}.in" ${fullOwnedPackagesFile} COPYONLY )
	endif()

	cpfReadVariablesFromFile( variableNames variableValues ${fullOwnedPackagesFile})

	set(packageList)

	set(index 0)
	foreach( variable ${variableNames} )

		if( ${variable} STREQUAL CPF_PACKAGES)
			list(GET variableValues ${index} packageList )
			if("${packageList}" STREQUAL "")
				message(FATAL_ERROR "No packages defined in file \"${fullOwnedPackagesFile}\".")
			endif()
			continue()
		endif()
		cpfIncrement(index)

	endforeach()

	if(NOT packageList)
		message(WARNING "File \"${fullOwnedPackagesFile}\" is missing a definition for variable CPF_PACKAGES")
	endif()

	set(${packagesOut} "${packageList}" PARENT_SCOPE )

endfunction()

#---------------------------------------------------------------------------------------------
function( isOwnedOrExternal isOut var )
	if(("${var}" STREQUAL OWNED) OR ("${var}" STREQUAL EXTERNAL))
		set(${isOut} TRUE PARENT_SCOPE)
	else()
		set(${isOut} FALSE PARENT_SCOPE)
	endif()
endfunction()

#---------------------------------------------------------------------------------------------
# Returns a list with the owned packages from the packages.cmake file
#
function( cpfGetOwnedPackages packagesOut rootDir )

	set(packages)

	cpfGetPackageVariableLists( listNames ${rootDir} packageVariables)
	foreach(listName ${listNames})
		
		cmake_parse_arguments(ARG "" "OWNED" "" ${${listName}})
		if(ARG_OWNED)
			cpfListAppend(packages ${ARG_OWNED})
		endif()

	endforeach()

	set(${packagesOut} "${packages}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Reads the packages and overridden variables from the packages.cmake file and adds
# the packages as subdirectories.
#
function( cpfAddPackageSubdirectories )

	cpfGetPackageDefaultValueVariables(overridableVariables)

	cpfGetPackageVariableLists( listNames ${CPF_ROOT_DIR} packageVariables)
	foreach(listName ${listNames})
		
		# The second element must be the package name.
		list(GET ${listName} 1 package )
		cmake_parse_arguments(ARG "" "${overridableVariables}" "" ${${listName}})

		# Override the global variables with the values from the list.
		foreach(variable ${overridableVariables})
			if(NOT "${ARG_${variable}}" STREQUAL "")
				set(${variable} ${ARG_${variable}})
				cpfDebugMessage("Override ${variable} with \"${ARG_${variable}}\"")
			endif()
		endforeach()

		# Now add the subdirectory.
		add_subdirectory(${package})

	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the names of the variables that can be overridden in the packages.cmake file.
function( cpfGetPackageDefaultValueVariables variablesOut )

	set( variables 
		BUILD_SHARED_LIBS
		CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS
		CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS
		CPF_ENABLE_CLANG_TIDY_TARGET
		CPF_ENABLE_OPENCPPCOVERAGE_TARGET
		CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION
		CPF_ENABLE_PRECOMPILED_HEADER
		CPF_ENABLE_RUN_TESTS_TARGET
		CPF_ENABLE_VALGRIND_TARGET
		CPF_ENABLE_VERSION_RC_FILE_GENERATION
		CPF_COMPILE_OPTIONS
	)

	set(${variablesOut} "${variables}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns the owned packages that are not in the same repository as the CI-project.
#  
function( cpfGetOwnedLoosePackages loosePackagesOut rootDir )

	set(loosePackages)
	cpfGetOwnedPackages( ownedPackages ${rootDir})
	foreach(package ${ownedPackages})
		cpfIsLoosePackage( isLoose ${package} ${rootDir})
		if(isLoose)
			list(APPEND loosePackages ${package})
		endif()
	endforeach()
	set(${loosePackagesOut} ${loosePackages} PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
# Returns true if the package-component is not in the same repository as the ci-project.
function( cpfIsLoosePackage isLooseOut package rootDir)

	cpfGetAbsPackageDirectory( packageDir ${package} ${rootDir})
	cpfGetHashOfTag( packageHash HEAD "${packageDir}")
	cpfGetHashOfTag( rootHash HEAD "${rootDir}")
	if( ${packageHash} STREQUAL ${rootHash} )
		set(${isLooseOut} FALSE PARENT_SCOPE)
	else()
		set(${isLooseOut} TRUE PARENT_SCOPE)
	endif()

endfunction()

#--------------------------------------------------------------------------------------------
function( cpfPrintAddPackageComponentStatusMessage packageType )

	cpfGetCurrentSourceDir(packageComponent)
	cpfGetTagsOfHEAD( tags "${CMAKE_CURRENT_SOURCE_DIR}" )
	set(tagged)
	if(tags)
		set(tagged "tagged ")
	endif()

	message(STATUS "Add ${packageType} package-component ${packageComponent}")

endfunction()

#--------------------------------------------------------------------------------------------
function( cpfPrintAddPackageStatusMessage package version)

	cpfGetTagsOfHEAD( tags "${CMAKE_CURRENT_SOURCE_DIR}" )
	set(tagged)
	if(tags)
		set(tagged "tagged ")
	endif()

	message(STATUS "Add package ${package} at ${tagged}version ${version}")

endfunction()

#---------------------------------------------------------------------------------------------
# returns the absolute paths to the repository directories that are owned by the CPF project located at rootDir
#
function( cpfGetOwnedRepositoryDirectories dirsOut rootDir)

	# Get all directories that may belong to different owned repositories
	cpfGetOwnedPackages( ownedPackages ${rootDir})
	set( possibleRepoDirectories ${rootDir} )
	foreach(package ${ownedPackages})
		cpfGetAbsPackageDirectory( packageDirOut ${package} ${rootDir})
		list(APPEND possibleRepoDirectories ${packageDirOut})
	endforeach()

	# Check which of these repositories belong together (have the same hash of the HEAD).
	# Get list of all current hashes
	set(hashes)
	foreach(repoDir ${possibleRepoDirectories})
		cpfGetHashOfTag( hashHEAD HEAD "${repoDir}")
		list(APPEND hashes ${hashHEAD})
	endforeach()

	# Get indexes of duplicated elements in list
	set(duplicatedIndexes)
	foreach(hash ${hashes})
		cpfFindAllInList( indexes "${hashes}" ${hash})
		cpfSplitList( unused duplIndexes "${indexes}" 1)
		list(APPEND duplicatedIndexes ${duplIndexes})
	endforeach()

	# Get directories of non duplicated hashes
	set(uniqueRepoDirs)
	set(index 0)
	foreach(hash ${hashes})
		cpfContains(isDuplicated "${duplicatedIndexes}" ${index})
		if(NOT isDuplicated)
			list(GET possibleRepoDirectories ${index} repoDir)
			list(APPEND uniqueRepoDirs ${repoDir})
		endif()
		cpfIncrement(index)
	endforeach()

	set(${dirsOut} "${uniqueRepoDirs}" PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
# read all sources from all binary targets of the given packages
function( cpfGetAllNonGeneratedPackageSources sourceFiles packageComponents )

	foreach( packageComponent ${packageComponents} globalFiles) # we also get the global files from the globalFiles target
		if(TARGET ${packageComponent}) # non-cpf package-components may not have targets set to them
			get_property(binaryTargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS )
			# explicitly include the package-component itself, because it may not be a binary target.
			set(targets ${binaryTargets} ${packageComponent})
			list(REMOVE_DUPLICATES targets)
			foreach( target ${targets} )
				cpfIsInterfaceLibrary( isIntLib ${target})
				if(isIntLib)
					# Use the file container target to get the source dir.
					get_property(target TARGET ${target} PROPERTY INTERFACE_CPF_FILE_CONTAINER_SUBTARGET )
				endif()
				get_property( sourceDir TARGET ${target} PROPERTY SOURCE_DIR)
				getAbsPathesForSourceFilesInDir( files ${target} ${sourceDir})
				list(APPEND allFiles ${files})
			endforeach()
		endif()
	endforeach()
	set(${sourceFiles} ${allFiles} PARENT_SCOPE)

endfunction()

#----------------------------------------------------------------------------------------
function( cpfGetAllDependedOnSourceFiles filesOut sourceFiles dependedOnPackageComponents )

	cpfPrependMulti( absSourceFiles "${CMAKE_CURRENT_SOURCE_DIR}/" "${sourceFiles}")

	# Get the sources from the depended on packages.
	foreach( packageComponent ${dependedOnPackageComponents})
		getAbsPathsOfTargetSources( absSources ${packageComponent})
		cpfListAppend( absSourceFiles ${absSources})
	endforeach()

	set(${filesOut} "${absSourceFiles}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfAppendPackageExeRPaths packageComponent rpath )

	cpfGetExecutableTargets( exeTargets ${packageComponent})
	foreach(target ${exeTargets})
		set_property(TARGET ${target} APPEND PROPERTY INSTALL_RPATH "${rpath}")
	endforeach()

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGenerateDependencyNamesHeader packageComponent )

	set(fileContent "// This file is generated by the CMakeProjectFramework.\n// Manual changes will be overwritten.\n\n")

	# Add macro names and values for this package
	cpfGetUnversionedPackageComponentName(unused unversionedPackage unused ${packageComponent})
	set(packageComponents ${packageComponent})
	set(macroNames ${unversionedPackage})

	# Add macro names and values for linked packages
	cpfGetCPFPackagesInPubliclyLinkedTree(interfacePackageComponents interfaceMacroNames ${packageComponent} TRUE)
	list(APPEND packageComponents ${interfacePackageComponent})
	list(APPEND macroNames ${interfaceMacroNames})

	# Write the public names file
	cpfWriteDependencyNamesToFile("${CMAKE_CURRENT_SOURCE_DIR}/${unversionedPackage}DependencyNames.h" "${packages}" "${macroNames}")

	# The private names header can also contain the names of privatly linked dependencies. 
	# They can not appear in the public header because it will make the short macro names ambigious.
	cpfGetNamesAndMacrosOfDirectlyLinkedCPFPackages(privatePackageComponents privateMacroNames ${packageComponent} PRIVATE TRUE)
	list(APPEND packageComponents ${privatePackageComponents})
	list(APPEND macroNames ${privateMacroNames})

	# Write the private names file
	cpfWriteDependencyNamesToFile("${CMAKE_CURRENT_SOURCE_DIR}/${unversionedPackage}DependencyNamesPrivate.h" "${packageComponents}" "${macroNames}")

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfWriteDependencyNamesToFile absFilename packageComponents macroNames )

	foreach(macroName packageComponent IN ZIP_LISTS macroNames packageComponents)
		string(APPEND fileContent "#undef ${macroName}\n")
		string(APPEND fileContent "#define ${macroName} ${packageComponent}\n")
		string(APPEND fileContent "\n")
	endforeach()
	
	if(packageComponents)
		file(CONFIGURE OUTPUT ${absFilename} CONTENT ${fileContent} NEWLINE_STYLE LF)
	endif()

	get_property(productionLib TARGET ${packageComponent} PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET)
	set_property(TARGET ${productionLib} APPEND PROPERTY SOURCES ${absFilename} )
	set_property(TARGET ${productionLib} APPEND PROPERTY INTERFACE_CPF_PUBLIC_HEADER ${absFilename} )
	source_group("" FILES ${absFilename})

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetCPFPackagesInPubliclyLinkedTree packagesOut macroNamesOut packageComponent isRoot)

	# Get directly linked packages.
	cpfGetNamesAndMacrosOfDirectlyLinkedCPFPackages(linkedPackages macroNames ${packageComponent} INTERFACE ${isRoot})

	# Recurse through the linked packages.
	foreach(linkedPackage ${linkedPackages})
		cpfGetCPFPackagesInPubliclyLinkedTree(indirectlyLinkedPackages macroNamesOfIndirectPackages ${linkedPackage} FALSE)
		list(APPEND linkedPackages ${indirectlyLinkedPackages})
		list(APPEND macroNames ${macroNamesOfIndirectPackages})
	endforeach()
	
	set(${packagesOut} "${linkedPackages}" PARENT_SCOPE)
	set(${macroNamesOut} "${macroNames}" PARENT_SCOPE)

endfunction()

#---------------------------------------------------------------------------------------------
function( cpfGetNamesAndMacrosOfDirectlyLinkedCPFPackages packagesOut packageVersionMacroNamesOut packageComponent linkVisibility isRoot)

	# Get visible linked targets
	set(linkedTargets)
	get_property(binaryTargets TARGET ${packageComponent} PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS)
	foreach(target ${binaryTargets})
		cpfGetLinkedTargets(linkedTargets ${target} all ${linkVisibility})
	endforeach()
	list(REMOVE_DUPLICATES linkedTargets)

	# Get the package-components of the targets
	set(linkedCPFPackages)
	foreach(target ${linkedTargets})
		get_property(packageName TARGET ${target} PROPERTY INTERFACE_CPF_PACKAGE_COMPONENT_NAME)
		if(packageName AND (NOT (${packageName} STREQUAL ${packageComponent})))
			list(APPEND linkedCPFPackages ${packageName})
		endif()
	endforeach()

	# Get macro names for the linked packages
	set(packageMacroNames)
	cpfGetUnversionedPackageComponentName(unused unversionedNameThisPackage unused ${packageComponent})
	foreach(linkedPackage ${linkedCPFPackages})
		cpfGetUnversionedPackageComponentName(unused unversionedNameLinkedPackage unused ${linkedPackage})
		if(isRoot)
			# Use a shorter macro name for directly linked package-components to reduce clutter in the code.
			list(APPEND packageMacroNames "${unversionedNameLinkedPackage}")
		else()
			list(APPEND packageMacroNames "${unversionedNameLinkedPackage}_from_${unversionedNameThisPackage}")
		endif()
	endforeach()

	set(${packagesOut} "${linkedCPFPackages}" PARENT_SCOPE)
	set(${packageVersionMacroNamesOut} "${packageMacroNames}" PARENT_SCOPE)

endfunction()

