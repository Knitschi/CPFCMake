# This script returns a list of strings like
#
# myPacakge@2.4.1
# theOtherPackage@3.2.2.4-fdg33
# aThirdPackage@1.2.3
#
# that contains the OWNED packages and their version numbers.
#
# Arguments:
# CPF_ROOT_DIR
#
#
#

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
include(cpfPackageUtilities)
include(cpfGitUtilities)
include(cpfLocations)

cpfAssertScriptArgumentDefined(CPF_ROOT_DIR)

cpfGetPackageSubdirectories(ownedPackageSubdirs externalPackageSubdirs ${CPF_ROOT_DIR})
foreach(packageSubdir ${ownedPackageSubdirs})

    # Get package name
    cpfGetLastPathNode(package "${packageSubdir}")
    cpfGetCurrentVersionFromGitRepository(version "${CPF_ROOT_DIR}/${CPF_SOURCE_DIR}/${packageSubdir}")

    message("${package}@${version}")

endforeach()