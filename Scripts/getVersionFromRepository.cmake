# This script takes a directory that must belong to a cpf git repository and
# returns the current version number of the repository by exaniming the release
# tags and the nr of commits that were made since the last release.
#
# Arguments:
# REPO_DIR      A directory that is managed by the repository in question.


include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)

include(cpfGitUtilities)
include(cpfMiscUtilities)
include(cpfVersionUtilities)

cpfAssertScriptArgumentDefined(REPO_DIR)

cpfGetCurrentVersionFromGitRepository( version "${REPO_DIR}")
message("${version}")
