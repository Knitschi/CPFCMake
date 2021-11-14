
include_guard(GLOBAL)

include(cpfMiscUtilities)
include(cpfConstants)

#----------------------------------------------------------------------------------------
# 
# This function defines all properties that are added and used by the CMakeProjectFramework cmake code.
# The properties are mainly used to get the names of generated files and subtargets.
# 
function( cpfDefineProperties )

	# A property that is set on all package-component targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_PACKAGE_NAME
        BRIEF_DOCS "Contains the package-component name including the version postfix."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_BRIEF_PACKAGE_DESCRIPTION
        BRIEF_DOCS "Contains a short description about what the package-component is good for."
        FULL_DOCS " "
    )
    
	# A property that is set on all package-component main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_LONG_PACKAGE_DESCRIPTION
        BRIEF_DOCS "Contains a long description about what the package-component is good for."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_PACKAGE_WEBPAGE_URL
        BRIEF_DOCS "A web address from where the source-code and/or the documentation of the package-component can be obtained."
        FULL_DOCS " "
    )
    
	# A property that is set on all package-component main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_PACKAGE_MAINTAINER_EMAIL
        BRIEF_DOCS "An email address under which the maintainers of the package-component can be reached."
        FULL_DOCS " "
    )

    # A property that is set on interface library targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_VERSION
        BRIEF_DOCS "Duplicates the VERSION property to allow passing on the version for interface libraries."
        FULL_DOCS " "
    )

	# A property that is set on all binary targets.
	define_property(
        TARGET
        PROPERTY INTERFACE_CPF_PUBLIC_HEADER
        BRIEF_DOCS "The header files that need to be accessed by consumers that link to the target."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets that have the same name as their package.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_PACKAGE_SUBTARGETS
        BRIEF_DOCS "A list of all targets that are associated with the package-component including the main target."
        FULL_DOCS " "
    )

    # A property that is set on all main targets that have the same name as their package.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_BINARY_SUBTARGETS
        BRIEF_DOCS "A list of all binary targets that are associated with the package-component including the main target."
        FULL_DOCS " "
    )

	# A property that is set on all main targets.
	define_property(
        TARGET
        PROPERTY INTERFACE_CPF_PRODUCTION_LIB_SUBTARGET
        BRIEF_DOCS "For executables this contains the name of the helper implementation library target. For library targets this contains the name of the main target."
        FULL_DOCS " "
    )

    # A property that is set on all main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_TEST_FIXTURE_SUBTARGET
        BRIEF_DOCS "The library the contains test utilities."
        FULL_DOCS " "
    )

    # A property that is set on all main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_TESTS_SUBTARGET
        BRIEF_DOCS "The test-executable binary target."
        FULL_DOCS " "
    )

    # A property that is set on interface library targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_FILE_CONTAINER_SUBTARGET
        BRIEF_DOCS "A custom target that is used to hold the files for interface library targets."
        FULL_DOCS " "
    )

	# A property that may be set on all targets that contribute to the install rules of a package.
	define_property(
        TARGET
        PROPERTY INTERFACE_CPF_INSTALL_COMPONENTS
        BRIEF_DOCS "A list with install-components that are provided by the target. If no components are given, it means that the target does not contribute any installable files to the package."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets
	define_property(
        TARGET
        PROPERTY INTERFACE_CPF_INSTALL_PACKAGE_SUBTARGET
        BRIEF_DOCS "The name of the target that installs all package-component components to the location defined by CMAKE_INSTALL_PREFIX."
        FULL_DOCS " "
    )

    # A property that is set on binary targets that have .ui fiels.
    define_property( 
        TARGET 
        PROPERTY INTERFACE_CPF_UIC_SUBTARGET 
        BRIEF_DOCS "A target that runs Qt's uic on all .ui files of the main-target in order to generate the ui_*.h files"
        FULL_DOCS " "
        )
       
    # A property that is set on all binary targets when using the clang toolchain.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_CLANG_TIDY_SUBTARGET
        BRIEF_DOCS "A target that runs clang-tidy on all .cpp files of the binary target."
        FULL_DOCS " "
    )

    # A property that is set on all binary targets when CPF_ENABLE_CLANG_FORMAT_TARGETS is set to on.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_CLANG_FORMAT_SUBTARGET
        BRIEF_DOCS "A target that runs clang-format on all C/C++ source files of the target."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_VALGRIND_SUBTARGET
        BRIEF_DOCS "Contains the name of a sub-target that runs Valgrind or OpenCppCoverage."
        FULL_DOCS " "
    )

    # A property that is set on all package-component main targets.
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_OPENCPPCOVERAGE_SUBTARGET
        BRIEF_DOCS "Contains the name of a sub-target that runs Valgrind or OpenCppCoverage."
        FULL_DOCS " "
    )

	# A property that is set on the dynamic analysis targets.
    define_property(
        TARGET
        PROPERTY CPF_CPPCOVERAGE_OUTPUT
        BRIEF_DOCS "Contains a list of .cov files that are generated by running OpenCppCoverage."
        FULL_DOCS " "
    )

    # A property that is set on some package-component main targets
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_RUN_CPP_TESTS_SUBTARGET
        BRIEF_DOCS "The name of the sub-target that runs a cpp executable with all automated tests."
        FULL_DOCS " "
    )

    # A property that is set on some package-component main targets
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_RUN_TESTS_SUBTARGET
        BRIEF_DOCS "The name of the sub-target that runs all automated tests."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets
    define_property(
        TARGET
        PROPERTY INTERFACE_CPF_RUN_FAST_TESTS_SUBTARGET
        BRIEF_DOCS "The name of the sub-target that runs only the fast tests."
        FULL_DOCS " "
    )

	# A property that is set on the modules main binary target.
	define_property(
        TARGET
        PROPERTY CPF_DOXYGEN_SUBTARGET
        BRIEF_DOCS "The name of a custom sub-target that runs doxygen in order to generate an xml tags file that contains documentation information of the modules source files."
        FULL_DOCS " "
    )

	# A property that is set on the CPF_DOXYGEN_SUBTARGET targets.
	define_property(
        TARGET
        PROPERTY CPF_DOXYGEN_TAGSFILE
        BRIEF_DOCS "The full path to the file xml tags file that is generated by the CPF_DOXYGEN_SUBTARGET target."
        FULL_DOCS " "
    )
	
	# A property that is set on the modules main binary target.
	define_property(
        TARGET
        PROPERTY CPF_DOXYGEN_CONFIG_SUBTARGET
        BRIEF_DOCS "The name of a custom sub-target that generates the per target doxygen config file by copying the global file and overwriting some options."
        FULL_DOCS " "
    )

	# A property that is set on the CPF_DOXYGEN_CONFIG_SUBTARGET targets.
	define_property(
        TARGET
        PROPERTY CPF_DOXYGEN_CONFIG_FILE
        BRIEF_DOCS "The full path to the file config file that is generated by the CPF_DOXYGEN_CONFIG_SUBTARGET target."
        FULL_DOCS " "
    )

	# A property that is set on all package-component main targets
	define_property(
        TARGET
        PROPERTY INTERFACE_CPF_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS
        BRIEF_DOCS "The names of the custom sub-target that create distribution-packages for the package."
        FULL_DOCS " "
    )

    # A property that is set on shared library targets
	define_property(
        TARGET
        PROPERTY INTERFACE_CPF_ABI_DUMP_SUBTARGET
        BRIEF_DOCS "The names of the custom sub-target that create the abi dumps."
        FULL_DOCS " "
    )
    
    # A property that is set on all package-component main targets
    define_property(
		TARGET
		PROPERTY INTERFACE_CPF_ABI_CHECK_SUBTARGETS
		BRIEF_DOCS "The names of all custom sub-target that call the abi-compliance-checker tool."
		FULL_DOCS " "
    )

	# A property that is set on some targets
	define_property(
		TARGET
		PROPERTY CPF_OUTPUT_FILES
		BRIEF_DOCS "A list of files that are created when the target is build."
		FULL_DOCS " "
	)

	# Configuration dependent properties	
	cpfGetConfigurations(configs)
	foreach(config ${configs})

		# A configuration dependent property that is set on some targets (optimally it should be set on all to get a completely clean dependency chain)
		define_property(
			TARGET
			PROPERTY CPF_OUTPUT_FILES_${configSuffix}
			BRIEF_DOCS "A list of files that are created when the target is build in the given configuration."
			FULL_DOCS " "
        )

    endforeach()

endfunction()
