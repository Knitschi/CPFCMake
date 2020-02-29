# This file bundles the cmake code file into a custom target to make them visible in the vs solution.

include(cpfLocations)
include(cpfInitPackageProject)
include(cpfAddFilePackage)
include(cpfAddRunTestsTarget)

cpfInitPackageProject(LANGUAGES NONE)

# Files that define variables.
set( files
	cpfInit.cmake
	cpfInitCIProject.cmake
	LICENSE
	README.md
	${CPF_DEFAULT_CONFIGS_DIR}/Clang.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Gcc.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Linux.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2017.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2019.cmake
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
	Modules/cpfAddAcyclicTarget.cmake
	Modules/cpfAddClangTidyTarget.cmake
	Modules/cpfAddClangFormatTarget.cmake
	Modules/cpfAddCompatibilityCheckTarget.cmake
	Modules/cpfAddDeploySharedLibrariesTarget.cmake
	Modules/cpfAddDistributionPackageTarget.cmake
	Modules/cpfAddDoxygenPackage.cmake
	Modules/cpfAddFilePackage.cmake
	Modules/cpfAddInstallTarget.cmake
	Modules/cpfAddOpenCppCoverageTarget.cmake
	Modules/cpfAddCppPackage.cmake
	Modules/cpfAddPipelineTargetDependencies.cmake
	Modules/cpfAddRunTestsTarget.cmake
	Modules/cpfAddRunUicTarget.cmake
	Modules/cpfAddSphinxPackage.cmake
	Modules/cpfAddValgrindTarget.cmake
	Modules/cpfAddVersionRcPreBuildEvent.cmake
	Modules/cpfCustomTargetUtilities.cmake
	Modules/cpfGitUtilities.cmake
	Modules/cpfAddPackages.cmake
	Modules/cpfInitPackageProject.cmake
	Modules/cpfListUtilities.cmake
	Modules/cpfMiscUtilities.cmake
	Modules/cpfNumericUtilities.cmake
	Modules/cpfPathUtilities.cmake
	Modules/cpfConfigUtilities.cmake
	Modules/cpfReadVariablesFromFile.cmake
	Modules/cpfStringUtilities.cmake
	Modules/cpfTestUtilities.cmake
	Modules/cpfTargetUtilities.cmake
	Modules/cpfPackageUtilities.cmake
	Modules/cpfVersionUtilities.cmake
	Modules/cpfOutputPathUtilities.cmake
	Modules/cpfAssertions.cmake
	Modules/cpfConstants.cmake
	Modules/cpfLocations.cmake
	Modules/cpfProperties.cmake
	Modules/cpfLinkTreeUtilities.cmake
	Modules/cpfGTAUtilities.cmake
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
)

cpfAddFilePackage(
    SOURCES ${files}
)

# Add a test target
cpfAddRunCMakeTestScriptTarget( "Tests/run_tests.cmake" "${files}" )
