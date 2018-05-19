# This script takes a directory that must belong to a cpf git repository and
# returns the current version number of the repository by exaniming the release
# tags and the nr of commits that were made since the last release.
#
# Arguments:
# REPO_DIR      A directory that is managed by the repository in question.


list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../Functions)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../Variables)

include(cpfConstants)
cmake_minimum_required(VERSION ${CPF_MINIMUM_CMAKE_VERSION})

include(cpfGitUtilities)
include(cpfMiscUtilities)

cpfAssertScriptArgumentDefined(REPO_DIR)

cpfGetCurrentVersionFromGitRepository( version "${REPO_DIR}")
message("${version}")
