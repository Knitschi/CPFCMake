

include(ccbCustomTargetUtilities)

#---------------------------------------------------------------------
#
# Adds a target that will build the complete pipeline, meaning all targets.
# 
# Arguments
# Takes a list of all the packages that belong to the project
function( ccbAddPipelineTarget packages)

	set( targetName pipeline)

	# A collection of the targets that should be contained in the pipeline.
	set( targets
		documentation
		distributionPackages 	# Because of the global nature of the clearLastBuild command that is included in this target, we can not depend on the package targets directly.
		staticAnalysis			# Because of the global check for an acyclic dependency graph, we can not depend on the package targets directly
		dynamicAnalysis			# Because the global target assembles the OpenCppCoverage report from the individual reports, we can not use properties for this.
	)
	
	# A set package properties that contain custom targets that should be
	# included in the pipeline.
	set( pipelineSubTargetProperties
		CCB_ABI_CHECK_SUBTARGETS
		CCB_RUN_TESTS_SUBTARGET
	)

	# When we know that the dynamic analysis target exists,
	# we can omit the extra test run. Note that with multi-config-generators we can only tell
	# at compile time if the dynamic analysis is run, so for simplicity we
	# add the runTest targets always.
	ccbIsGccClangDebug(gccClangDebug)
	if(gccClangDebug)
		list(REMOVE_ITEM targets runAllTests)
	endif()
	
	ccbGetTargetsFromProperties( targetsFromProperties "${packages}" "${pipelineSubTargetProperties}" )

    # only use the custom targets that the user has enabled
    set(existingTargets)
    foreach(target ${targetsFromProperties} ${targets})
        if(TARGET ${target})
            list(APPEND existingTargets ${target})
        endif()
    endforeach()
       
	ccbAddBundleTarget( ${targetName} "${existingTargets}")

endfunction()

#---------------------------------------------------------------------
# Retrieves all sub-targets that are stored in the given subTargetProperties, which must be set
# on the packages main target.
function( ccbGetTargetsFromProperties targetsOut packages subTargetProperties )
set(subTargets)
foreach( property ${subTargetProperties})
	ccbGetSubtargets(targets "${packages}" ${property})
	list(APPEND subTargets ${targets})
endforeach()
set(${targetsOut} ${subTargets} PARENT_SCOPE)
endfunction()