# This script either reads the package version from a cpfPackageVersion_<package>.cmake file in the SOURCE tree or
# assumes that the package directory belongs to a git repository and tries to read the version from a tag of that
# repository. For simplicity we do not search for the build-tree version file here. If it exists we can
# also read the version from the repository and do not need to handle different cases depending on the existence
# of the build-tree.
#
# Arguments:
# PACKAGE_DIR      An absolute path to the packages root directory. This is the one that has the same name as the package.
#

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)

include(cpfGitUtilities)
include(cpfMiscUtilities)
include(cpfVersionUtilities)
include(cpfLocations)

cpfAssertScriptArgumentDefined(PACKAGE_DIR)

if(NOT EXISTS "${PACKAGE_DIR}")
	message(FATAL_ERROR "The given package directory \"${PACKAGE_DIR}\" does not exist.")
endif()

# Get package name
cpfGetLastPathNode(package "${PACKAGE_DIR}")

# Get the path to the version file.
# This will only exist in the source directory if the package was obtained from a package-archive.
cpfGetPackageVersionFileName(versionFile ${package})
set(absPathVersionFile "${PACKAGE_DIR}/${versionFile}")

if(EXISTS ${absPathVersionFile})
	cpfGetPackageVersionFromFile(version ${package} ${absPathVersionFile})
else()
	cpfGetCurrentVersionFromGitRepository(version "${PACKAGE_DIR}")
endif()

message("${version}")