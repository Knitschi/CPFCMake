
# This file holds cmake constants for the CPPCODEBASE

set( CCB_MINIMUM_CMAKE_VERSION 3.10.0)

# Get definitions of test target appendices for in code macros (todo move this somewhere in the lower parts)
set( CCB_FIXTURE_TARGET_ENDING _fixtures)
set( CCB_TESTS_TARGET_ENDING _tests)

#### target names ####

set( CCB_RUN_ALL_TESTS_TARGET_PREFIX runAllTests_)


###### functions to define combined strings ######

# This function defines the nameing convention of the <developer>-int-<mainbranch>
# and <developer>-tmp-<mainbranch> branches.
function( ccbGetIntegrationBrancheNames devBranchOut tmpBranchOut developer mainbranch )
	set( ${devBranchOut} ${developer}-int-${mainbranch} PARENT_SCOPE)
	set( ${tmpBranchOut} ${developer}-tmp-${mainbranch} PARENT_SCOPE)
endfunction()

