
# This file holds cmake constants for the CPPCODEBASE

# Get definitions of test target appendices for in code macros (todo move this somewhere in the lower parts)
set( CCB_FIXTURE_TARGET_ENDING _fixtures)
set( CCB_TESTS_TARGET_ENDING _tests)


###### functions to define combined strings ######


# This function defines the nameing convention of the <developer>-int-<mainbranch>
# and <developer>-tmp-<mainbranch> branches.
function( ccbGetIntegrationBrancheNames devBranchOut tmpBranchOut developer mainbranch )
	set( ${devBranchOut} ${developer}-int-${mainbranch} PARENT_SCOPE)
	set( ${tmpBranchOut} ${developer}-tmp-${mainbranch} PARENT_SCOPE)
endfunction()

