
# This file holds cmake constants of the package.

include_guard(GLOBAL)

# Get definitions of test target appendices for in code macros (todo move this somewhere in the lower parts)
set( CPF_FIXTURE_TARGET_ENDING _fixtures)
set( CPF_TESTS_TARGET_ENDING _tests)

#### target names ####

set( CPF_RUN_ALL_TESTS_TARGET_PREFIX runAllTests_)

#### misc ####
set( CPF_DONT_TRIGGER_NOTE "dontTr1gger" )                  # We use the 1 as i to minimize risc of clashing with a random use of the word in a commit message.
set( CPF_CXX_SOURCE_FILE_EXTENSIONS ".c;.cpp;.h;.hpp" )     # These are used by the cpf to identify files that contain source code.

###### functions to define combined strings ######

