# This script returns a list of strings like
#
# myPacakge@2.4.1
# theOtherPackage@3.2.2.4-fdg33
# aThirdPackage@1.2.3
#
# that contains the owned packages and their version numbers.
#
# Arguments:
# CPF_ROOT_DIR
#
#
#

include(${CMAKE_CURRENT_LIST_DIR}/../cpfInit.cmake)
include(cpfPackageUtilities)

cpfAssertScriptArgumentDefined(CPF_ROOT_DIR)


cpfGetPackageVariableLists( listNames ${CPF_ROOT_DIR} packageVariables)
foreach(listName ${listNames})

    # The second element must be the package directory.
    list(GET ${listName} 1 packageDir )
    # Get package name
    cpfGetLastPathNode(package "${packageDir}")
    cpfGetCurrentVersionFromGitRepository(version "${packageDir}")

    message("${package}@${version}")

endforeach()