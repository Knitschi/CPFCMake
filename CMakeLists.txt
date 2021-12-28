# This file bundles the cmake code file into a custom target to make them visible in the vs solution.

include(cpfLocations)
include(cpfPackageProject)
include(cpfAddFilePackageComponent)
include(cpfAddRunTestsTarget)

cpfPackageProject(
	TARGET_NAMESPACE CIConfig
	COMPONENTS SINGLE_COMPONENT
	LANGUAGES NONE
)

# Files that define variables.
set( files
	${CPF_DEFAULT_CONFIGS_DIR}/Clang.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Gcc.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Linux.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2017.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2019.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/PlatformIndependent.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Windows.config.cmake
	${CPF_PACKAGE_CONFIG_TEMPLATE}
	cpfInit.cmake
	cpfInitCIProject.cmake
	documentation/APIDocGlobalVariables.rst
	documentation/APIDocModules.rst
	documentation/ConfigurationManagement.rst
	documentation/CPFCMake.rst
	documentation/CustomTargets.rst
	documentation/DocumentationTargets.rst
	documentation/ImplementationProblems.rst
	documentation/PackageArchives.rst
	documentation/PackagesCMake.rst
	documentation/TestTargets.rst
	documentation/UsageProblems.rst
	documentation/Versioning.rst
	LICENSE
	Modules/cpfAddAcyclicTarget.cmake
	Modules/cpfAddClangFormatTarget.cmake
	Modules/cpfAddClangTidyTarget.cmake
	Modules/cpfAddCompatibilityCheckTarget.cmake
	Modules/cpfAddCppPackageComponent.cmake
	Modules/cpfAddDeploySharedLibrariesTarget.cmake
	Modules/cpfAddDoxygenPackageComponent.cmake
	Modules/cpfAddFilePackageComponent.cmake
	Modules/cpfAddInstallTarget.cmake
	Modules/cpfAddOpenCppCoverageTarget.cmake
	Modules/cpfAddPackageArchiveTarget.cmake
	Modules/cpfAddPackages.cmake
	Modules/cpfAddPipelineTargetDependencies.cmake
	Modules/cpfAddPythonPackageComponent.cmake
	Modules/cpfAddRunTestsTarget.cmake
	Modules/cpfAddRunUicTarget.cmake
	Modules/cpfAddSphinxPackageComponent.cmake
	Modules/cpfAddValgrindTarget.cmake
	Modules/cpfAddVersionRcTarget.cmake
	Modules/cpfAssertions.cmake
	Modules/cpfConfigUtilities.cmake
	Modules/cpfConstants.cmake
	Modules/cpfCustomTargetUtilities.cmake
	Modules/cpfGitUtilities.cmake
	Modules/cpfGTAUtilities.cmake
	Modules/cpfLinkTreeUtilities.cmake
	Modules/cpfListUtilities.cmake
	Modules/cpfLocations.cmake
	Modules/cpfMiscUtilities.cmake
	Modules/cpfNumericUtilities.cmake
	Modules/cpfOutputPathUtilities.cmake
	Modules/cpfPackageProject.cmake
	Modules/cpfPackageUtilities.cmake
	Modules/cpfPathUtilities.cmake
	Modules/cpfProperties.cmake
	Modules/cpfReadVariablesFromFile.cmake
	Modules/cpfStringUtilities.cmake
	Modules/cpfTargetUtilities.cmake
	Modules/cpfTestUtilities.cmake
	Modules/cpfVersionUtilities.cmake
	README.md
	Scripts/addVersionTag.cmake
	Scripts/appendLineToFile.cmake
	Scripts/clearDirExcept.cmake
	Scripts/configureFile.cmake
	Scripts/createConfigFile.cmake
	Scripts/executeCommandForConfig.cmake
	Scripts/getPackageVersion.cmake
	Scripts/getVersionFromRepository.cmake
	Scripts/prepareCIRepoForBuild.cmake
	Scripts/printScriptFileVariables.cmake
	Scripts/runAbiComplianceChecker.cmake
	Scripts/updateBuildResultsRepository.cmake
	Templates/.gitignore.in
	Templates/${CPF_GRAPHVIZ_OPTIONS_FILE}.in
	Templates/cpfPackages.cmake.in
	Templates/packageVersion.cmake.in
	Templates/packageVersion.h.in
	Templates/packageVersion.py.in
	Templates/version.rc.in
	Tests/cpfListUtilities_tests.cmake
	Tests/cpfMiscUtilities_tests.cmake
	Tests/cpfNumericUtilities_tests.cmake
	Tests/cpfPathUtilities_tests.cmake
	Tests/cpfStringUtilities_tests.cmake
	Tests/run_tests.cmake
)

cpfAddFilePackageComponent(
    SOURCES ${files}
)

cpfFinalizePackageProject()

# Add a test target
cpfAddRunCMakeTestScriptTarget( "Tests/run_tests.cmake" "${files}" )
