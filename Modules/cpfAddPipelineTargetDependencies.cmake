include_guard(GLOBAL)

include(cpfCustomTargetUtilities)

#---------------------------------------------------------------------
#
# Adds a target that will build the complete pipeline, meaning all targets.
# 
# Arguments
# Takes a list of all the packages that belong to the project
function( cpfAddPipelineTargetDependencies packages)

	set( targetName pipeline)

	# A collection of the targets that should be contained in the pipeline.
	set( targets
		acyclic
		distributionPackages 	# Because of the global nature of the clearLastBuild command that is included in this target, we can not depend on the package targets directly.
		opencppcoverage			# Because the global target assembles the OpenCppCoverage report from the individual reports, we can not use properties for this.
	)
	
	# A set package properties that contain custom targets that should be
	# included in the pipeline.
	set( pipelineSubTargetProperties
		INTERFACE_CPF_BINARY_SUBTARGETS
		INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET
		INTERFACE_CPF_RUN_TESTS_SUBTARGET
		INTERFACE_CPF_ABI_CHECK_SUBTARGETS
		INTERFACE_CPF_VALGRIND_SUBTARGET
		INTERFACE_CPF_CLANG_TIDY_SUBTARGET
	)

	# When we know that the dynamic analysis target exists,
	# we can ommit the extra test run. Note that with multi-config-generators we can only tell
	# at compile time if the dynamic analysis is run, so for simplicity we
	# add the runTest targets always.
	cpfIsGccClangDebug(gccClangDebug)
	if(gccClangDebug)
		list(REMOVE_ITEM pipelineSubTargetProperties INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET)
	endif()
	
	cpfGetTargetsFromProperties( targetsFromProperties "${packages}" "${pipelineSubTargetProperties}" )
	set(allTargets ${targetsFromProperties} ${targets} ${packages} )
	list(REMOVE_DUPLICATES allTargets)

    # only use the custom targets that the user has enabled
    set(existingTargets)
    foreach(target ${allTargets})
        if(TARGET ${target})
            cpfListAppend( existingTargets ${target})
        endif()
    endforeach()

	add_dependencies(pipeline ${existingTargets})

endfunction()

#---------------------------------------------------------------------
# Retrieves all sub-targets that are stored in the given subTargetProperties, which must be set
# on the packages main target.
function( cpfGetTargetsFromProperties targetsOut packages subTargetProperties )
	set(subTargets)
	foreach( property ${subTargetProperties})
		cpfGetSubtargets(targets "${packages}" ${property})
		cpfListAppend(subTargets ${targets})
	endforeach()
	set(${targetsOut} ${subTargets} PARENT_SCOPE)
endfunction()