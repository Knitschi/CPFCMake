
# This file holds cmake constants of the package.

include_guard(GLOBAL)

set( CPF_MINIMUM_CMAKE_VERSION 3.10.0)

# Get definitions of test target appendices for in code macros (todo move this somewhere in the lower parts)
set( CPF_FIXTURE_TARGET_ENDING _fixtures)
set( CPF_TESTS_TARGET_ENDING _tests)

#### target names ####

set( CPF_RUN_ALL_TESTS_TARGET_PREFIX runAllTests_)

#### misc ####
set( CPF_DONT_TRIGGER_NOTE "dontTr1gger" ) # we use the 1 as i to minimize risc of clashing with a random use of the word in a commit message.

###### functions to define combined strings ######

