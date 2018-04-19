# This file bundles the cmake code file into a custom target to make them visible in the vs solution.

include(cpfLocations)
include(cpfAddPackage)

cpfInitPackageProject(
	PACKAGE_NAME
	CPFCM
)

# The files that contain functions that are called by the users of the CMakeProjectFramework
set( PUBLIC_FILES 
    cpfAddPackage.cmake
    cpfInit.cmake
)

# Files that define variables.
set( VARIABLES_FILES
	Variables/cpfConstants.cmake
	Variables/cpfLocations.cmake
	Variables/cpfProperties.cmake
)

# Files that provide functionality.
set( FUNCTION_FILES 
	Functions/cpfAddCompatibilityCheckTarget.cmake
	Functions/cpfAddDeploySharedLibrariesTarget.cmake
	Functions/cpfAddDistributionPackageTarget.cmake
	Functions/cpfAddDocumentationTarget.cmake
	Functions/cpfAddDynamicAnalysisTarget.cmake
	Functions/cpfAddInstallPackageTarget.cmake
	Functions/cpfAddPipelineTarget.cmake
	Functions/cpfAddRunTestsTarget.cmake
	Functions/cpfAddRunUicTarget.cmake
	Functions/cpfAddStaticAnalysisTarget.cmake
	Functions/cpfCustomTargetUtilities.cmake
	Functions/cpfGitUtilities.cmake
	Functions/cpfProjectUtilities.cmake
	Functions/cpfListUtilities.cmake
	Functions/cpfMiscUtilities.cmake
	Functions/cpfNumericUtilities.cmake
	Functions/cpfPathUtilities.cmake
	Functions/cpfStringUtilities.cmake
)

# Files that provide default configurations of cmake variables.
set( CONFIGURATION_FILES 
	${CPF_DEFAULT_CONFIGS_DIR}/Clang.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Gcc.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/MSVC2017.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/PlatformIndependent.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Linux.config.cmake
	${CPF_DEFAULT_CONFIGS_DIR}/Windows.config.cmake
)

# Files that are supposed to be used with cmake script mode (-P).
set( SCRIPT_FILES 
	Scripts/addVersionTag.cmake
	Scripts/clearDirExcept.cmake
	Scripts/createConfigFile.cmake
	Scripts/executeCommandForConfig.cmake
	Scripts/runAbiComplianceChecker.cmake
	Scripts/updateExistingWebPage.cmake
	Scripts/prepareCIRepoForBuild.cmake
)

# Files that do not fit in any other category.
set( OTHER_FILES
	documentation/CPFCMake.dox
)

# Template files that are used with the configure_file() command.
set( TEMPLATE_FILES
	${CPF_PACKAGE_CONFIG_TEMPLATE}
	Templates/packageVersion.h.in
	Templates/packageVersion.cmake.in
	Templates/.gitignore.in
	Templates/${CPF_GRAPHVIZ_OPTIONS_FILE}.in
	Templates/DoxygenConfig.txt.in
)

# File that contain tests
set( TEST_FILES
	Tests/cpfListUtilities_tests.cmake
	Tests/cpfMiscUtilities_tests.cmake
	Tests/cpfNumericUtilities_tests.cmake
	Tests/cpfPathUtilities_tests.cmake
	Tests/cpfStringUtilities_tests.cmake
	Tests/cpfTestUtilities.cmake
	Tests/run_tests.cmake
)

set( DOCUMENTATION_FILES 
	documentation/Configuration.dox
	documentation/CPFCMake.dox
	documentation/CustomTargets.dox
	documentation/DistributionPackages.dox
	documentation/DocumentationTargets.dox
	documentation/TestTargets.dox
	documentation/Versioning.dox
)

# Put the files in directories in visual studio.
source_group( Variables FILES ${VARIABLES_FILES} )
source_group( Functions FILES ${FUNCTION_FILES} )
source_group( DefaultConfigurations FILES ${CONFIGURATION_FILES} )
source_group( Scripts FILES ${SCRIPT_FILES} )
source_group( Other FILES ${OTHER_FILES} )
source_group( Templates FILES ${TEMPLATE_FILES} )
source_group( Tests FILES ${TEST_FILES} )
source_group( documentation FILES ${DOCUMENTATION_FILES} )

# Finally add the target.
set(allCMakeFiles ${PUBLIC_FILES} ${VARIABLES_FILES} ${FUNCTION_FILES} ${TEST_FILES} ${CONFIGURATION_FILES} ${SCRIPT_FILES} ${OTHER_FILES} ${TEMPLATE_FILES} ${TEST_FILES} ${DOCUMENTATION_FILES})

cpfAddFilePackage(${PACKAGE_NAME} "${allCMakeFiles}")

# Add a test target
cpfAddRunCMakeTestScriptTarget( ${PACKAGE_NAME} "Tests/run_tests.cmake" "${TEST_FILES}")
