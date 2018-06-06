include_guard(GLOBAL)

include(cpfCustomTargetUtilities)

#---------------------------------------------------------------------
#
# Adds a target that will build the complete pipeline, meaning all targets.
# 
# Arguments
# Takes a list of all the packages that belong to the project
function( cpfAddPipelineTarget packages)

	set( targetName pipeline)

	# A collection of the targets that should be contained in the pipeline.
	set( targets
		doxygen
		distributionPackages 	# Because of the global nature of the clearLastBuild command that is included in this target, we can not depend on the package targets directly.
		staticAnalysis			# Because of the global check for an acyclic dependency graph, we can not depend on the package targets directly
		opencppcoverage			# Because the global target assembles the OpenCppCoverage report from the individual reports, we can not use properties for this.
	)
	
	# A set package properties that contain custom targets that should be
	# included in the pipeline.
	set( pipelineSubTargetProperties
		CPF_BINARY_SUBTARGETS
		CPF_RUN_CPP_TESTS_SUBTARGET
		CPF_RUN_TESTS_SUBTARGET
		CPF_ABI_CHECK_SUBTARGETS
		CPF_VALGRIND_SUBTARGET
	)

	# When we know that the dynamic analysis target exists,
	# we can ommit the extra test run. Note that with multi-config-generators we can only tell
	# at compile time if the dynamic analysis is run, so for simplicity we
	# add the runTest targets always.
	cpfIsGccClangDebug(gccClangDebug)
	if(gccClangDebug)
		list(REMOVE_ITEM pipelineSubTargetProperties CPF_RUN_CPP_TESTS_SUBTARGET)
	endif()
	
	cpfGetTargetsFromProperties( targetsFromProperties "${packages}" "${pipelineSubTargetProperties}" )

    # only use the custom targets that the user has enabled
    set(existingTargets)
    foreach(target ${targetsFromProperties} ${targets})
        if(TARGET ${target})
            cpfListAppend( existingTargets ${target})
        endif()
    endforeach()
       
	cpfAddBundleTarget( ${targetName} "${existingTargets}")

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