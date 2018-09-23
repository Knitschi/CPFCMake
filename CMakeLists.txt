# This file bundles the cmake code file into a custom target to make them visible in the vs solution.

include(cpfLocations)
include(cpfAddPackage)

cpfInitPackageProject(
	PACKAGE_NAME
	CPFCM
)

# Files that define variables.
set( files
	${CPF_DEFAULT_CONFIGS_DIR}/Clang.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Gcc.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Linux.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2017.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/PlatformIndependent.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Windows.config.cmake
	${CPF_PACKAGE_CONFIG_TEMPLATE}
	documentation/APIDoc.dox
	documentation/Configuration.dox
	documentation/CPFCMake.dox
	documentation/CPFCMake.dox
	documentation/CustomTargets.dox
	documentation/DistributionPackages.dox
	documentation/DocumentationTargets.dox
	documentation/TestTargets.dox
	documentation/Versioning.dox
	Functions/cpfAddAcyclicTarget.cmake
	Functions/cpfAddClangTidyTarget.cmake
	Functions/cpfAddCompatibilityCheckTarget.cmake
	Functions/cpfAddDeploySharedLibrariesTarget.cmake
	Functions/cpfAddDistributionPackageTarget.cmake
	Functions/cpfAddDocumentationTarget.cmake
	Functions/cpfAddInstallPackageTarget.cmake
	Functions/cpfAddOpenCppCoverageTarget.cmake
	Functions/cpfAddPackage.cmake
	Functions/cpfAddPipelineTarget.cmake
	Functions/cpfAddRunTestsTarget.cmake
	Functions/cpfAddRunUicTarget.cmake
	Functions/cpfAddValgrindTarget.cmake
	Functions/cpfCustomTargetUtilities.cmake
	Functions/cpfGitUtilities.cmake
	Functions/cpfInit.cmake
	Functions/cpfListUtilities.cmake
	Functions/cpfMiscUtilities.cmake
	Functions/cpfNumericUtilities.cmake
	Functions/cpfPathUtilities.cmake
	Functions/cpfProjectUtilities.cmake
	Functions/cpfStringUtilities.cmake
	Functions/cpfTestUtilities.cmake
	Scripts/addVersionTag.cmake
	Scripts/clearDirExcept.cmake
	Scripts/createConfigFile.cmake
	Scripts/executeCommandForConfig.cmake
	Scripts/prepareCIRepoForBuild.cmake
	Scripts/runAbiComplianceChecker.cmake
	Scripts/updateExistingWebPage.cmake
	Templates/.gitignore.in
	Templates/${CPF_GRAPHVIZ_OPTIONS_FILE}.in
	Templates/DoxygenConfig.txt.in
	Templates/packageVersion.cmake.in
	Templates/packageVersion.h.in
	Tests/cpfListUtilities_tests.cmake
	Tests/cpfMiscUtilities_tests.cmake
	Tests/cpfNumericUtilities_tests.cmake
	Tests/cpfPathUtilities_tests.cmake
	Tests/cpfStringUtilities_tests.cmake
	Tests/run_tests.cmake
	Variables/cpfConstants.cmake
	Variables/cpfLocations.cmake
	Variables/cpfProperties.cmake
)

cpfAddFilePackage(${PACKAGE_NAME} "${files}")

# Add a test target
cpfAddRunCMakeTestScriptTarget( ${PACKAGE_NAME} "Tests/run_tests.cmake" "${TEST_FILES}" )
