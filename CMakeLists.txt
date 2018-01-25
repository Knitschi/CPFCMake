# This file bundles the cmake code file into a custom target to make them visible in the vs solution.

include(ccbLocations)
include(ccbAddPackage)

set( PACKAGE_NAMESPACE CcbBS )
ccbInitPackageProject(
	PACKAGE_NAME
	${PACKAGE_NAMESPACE}
)

# The files that contain functions that are called by the users of the CppCodeBase
set( PUBLIC_FILES 
    ccbAddPackage.cmake
    ccbInit.cmake
)

# Files that define variables.
set( VARIABLES_FILES
	Variables/ccbConstants.cmake
	Variables/ccbLocations.cmake
	Variables/ccbProperties.cmake
)

# Files that provide functionality.
set( FUNCTION_FILES 
	Functions/ccbAddCompatibilityCheckTarget.cmake
	Functions/ccbAddDeploySharedLibrariesTarget.cmake
	Functions/ccbAddDistributionPackageTarget.cmake
	Functions/ccbAddDocumentationTarget.cmake
	Functions/ccbAddDynamicAnalysisTarget.cmake
	Functions/ccbAddInstallPackageTarget.cmake
	Functions/ccbAddPipelineTarget.cmake
	Functions/ccbAddRunTestsTarget.cmake
	Functions/ccbAddRunUicTarget.cmake
	Functions/ccbAddStaticAnalysisTarget.cmake
	Functions/ccbBaseUtilities.cmake
	Functions/ccbCustomTargetUtilities.cmake
	Functions/ccbGitUtilities.cmake
	Functions/ccbProjectUtilities.cmake
)

# Files that provide default configurations of cmake variables.
set( CONFIGURATION_FILES 
	${CCB_DEFAULT_CONFIGS_DIR}/Clang.cmake
	${CCB_DEFAULT_CONFIGS_DIR}/Gcc.cmake
	${CCB_DEFAULT_CONFIGS_DIR}/MSVC2017.cmake
	${CCB_DEFAULT_CONFIGS_DIR}/PlatformIndependent.config.cmake
	${CCB_DEFAULT_CONFIGS_DIR}/Linux.config.cmake
	${CCB_DEFAULT_CONFIGS_DIR}/Windows.config.cmake
)

# Files that are supposed to be used with cmake script mode (-P).
set( SCRIPT_FILES 
	Scripts/clearDirExcept.cmake
	Scripts/createConfigFile.cmake
	Scripts/executeCommandForConfig.cmake
	Scripts/integrateTmpBranch.cmake
	Scripts/prepareTmpBranch.cmake
	Scripts/runAbiComplianceChecker.cmake
	Scripts/updateExistingWebPage.cmake
	Scripts/incrementVersionNumber.cmake
)

# Files that do not fit in any other category.
set( OTHER_FILES
	documentation/CppCodeBaseDocumentation.dox
)

# Template files that are used with the configure_file() command.
set( TEMPLATE_FILES
	${CCB_PACKAGE_CONFIG_TEMPLATE}
	Templates/packageVersion.h.in
	Templates/packageVersion.cmake.in
	Templates/.gitignore.in
	Templates/${CCB_GRAPHVIZ_OPTIONS_FILE}
	Templates/DoxygenConfig.txt.in
)

# Put the files in directories in visual studio.
source_group( Variables FILES ${VARIABLES_FILES} )
source_group( Functions FILES ${FUNCTION_FILES} )
source_group( DefaultConfigurations FILES ${CONFIGURATION_FILES} )
source_group( Scripts FILES ${SCRIPT_FILES} )
source_group( Other FILES ${OTHER_FILES} )
source_group( Templates FILES ${TEMPLATE_FILES} )

# Finally add the target.
set(allCMakeFiles ${PUBLIC_FILES} ${VARIABLES_FILES} ${FUNCTION_FILES} ${TEST_FILES} ${CONFIGURATION_FILES} ${SCRIPT_FILES} ${OTHER_FILES} ${TEMPLATE_FILES}  )

add_custom_target( ${PACKAGE_NAME} SOURCES ${allCMakeFiles} )
set_property( TARGET ${PACKAGE_NAME} PROPERTY FOLDER ${PACKAGE_NAME} )
