# This file bundles the cmake code file into a custom target to make them visible in the vs solution.

include(cpfLocations)
include(cpfInitPackageProject)
include(cpfAddFilePackage)
include(cpfAddRunTestsTarget)

cpfInitPackageProject()

# Files that define variables.
set( files
	cpfInit.cmake
	LICENSE
	README.rst
	${CPF_DEFAULT_CONFIGS_DIR}/Clang.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Gcc.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Linux.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2017.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/PlatformIndependent.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Windows.config.cmake
	documentation/APIDocGlobalVariables.rst
	documentation/APIDocModules.rst
	documentation/ConfigurationManagement.rst
	documentation/CPFCMake.rst
	documentation/CustomTargets.rst
	documentation/DistributionPackages.rst
	documentation/DocumentationTargets.rst
	documentation/TestTargets.rst
	documentation/Versioning.rst
	documentation/PackagesCMake.rst
	documentation/UsageProblems.rst
	documentation/ImplementationProblems.rst
	Functions/cpfAddAcyclicTarget.cmake
	Functions/cpfAddClangTidyTarget.cmake
	Functions/cpfAddClangFormatTarget.cmake
	Functions/cpfAddCompatibilityCheckTarget.cmake
	Functions/cpfAddDeploySharedLibrariesTarget.cmake
	Functions/cpfAddDistributionPackageTarget.cmake
	Functions/cpfAddDoxygenPackage.cmake
	Functions/cpfAddFilePackage.cmake
	Functions/cpfAddInstallTarget.cmake
	Functions/cpfAddOpenCppCoverageTarget.cmake
	Functions/cpfAddCppPackage.cmake
	Functions/cpfAddPipelineTargetDependencies.cmake
	Functions/cpfAddRunTestsTarget.cmake
	Functions/cpfAddRunUicTarget.cmake
	Functions/cpfAddSphinxPackage.cmake
	Functions/cpfAddValgrindTarget.cmake
	Functions/cpfAddVersionRcPreBuildEvent.cmake
	Functions/cpfCustomTargetUtilities.cmake
	Functions/cpfGitUtilities.cmake
	Functions/cpfAddPackages.cmake
	Functions/cpfInitPackageProject.cmake
	Functions/cpfListUtilities.cmake
	Functions/cpfMiscUtilities.cmake
	Functions/cpfNumericUtilities.cmake
	Functions/cpfPathUtilities.cmake
	Functions/cpfConfigUtilities.cmake
	Functions/cpfReadVariablesFromFile.cmake
	Functions/cpfStringUtilities.cmake
	Functions/cpfTestUtilities.cmake
	Functions/cpfTargetUtilities.cmake
	Functions/cpfPackageUtilities.cmake
	Functions/cpfVersionUtilities.cmake
	Functions/cpfPropertyUtilities.cmake
	Functions/cpfAssertions.cmake
	Scripts/addVersionTag.cmake
	Scripts/appendLineToFile.cmake
	Scripts/clearDirExcept.cmake
	Scripts/configureFile.cmake
	Scripts/createConfigFile.cmake
	Scripts/executeCommandForConfig.cmake
	Scripts/getVersionFromRepository.cmake
	Scripts/prepareCIRepoForBuild.cmake
	Scripts/printScriptFileVariables.cmake
	Scripts/runAbiComplianceChecker.cmake
	Scripts/updateBuildResultsRepository.cmake
	Templates/.gitignore.in
	Templates/${CPF_GRAPHVIZ_OPTIONS_FILE}.in
	${CPF_PACKAGE_CONFIG_TEMPLATE}
	Templates/cpfPackages.cmake.in
	Templates/packageVersion.cmake.in
	Templates/packageVersion.h.in
	Templates/version.rc.in
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

cpfAddFilePackage(
    SOURCES ${files}
)

# Add a test target
cpfAddRunCMakeTestScriptTarget( "Tests/run_tests.cmake" "${files}" )
