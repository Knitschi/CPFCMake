
include(ccbBaseUtilities)
include(ccbConstants)

#----------------------------------------------------------------------------------------
# 
# This function defines all properties that are added and used by the CppCodeBase cmake code.
# The properties are mainly used to get the names of generated files and subtargets.
# 
function( ccbDefineProperties )

	# A property that is set on all targets in the CppCodeBase.
    define_property( 
        TARGET 
        PROPERTY PACKAGE
        BRIEF_DOCS "The name of the package to which the target belongs"
        FULL_DOCS " "
	)

	# A property that is set on all package main targets.
    define_property(
        TARGET
        PROPERTY CCB_BRIEF_PACKAGE_DESCRIPTION
        BRIEF_DOCS "Contains a short description about what the package is good for."
        FULL_DOCS " "
    )
    
	# A property that is set on all package main targets.
    define_property(
        TARGET
        PROPERTY CCB_PACKAGE_HOMEPAGE
        BRIEF_DOCS "A web address from where the source-code and/or the documentation of the package can be obtained."
        FULL_DOCS " "
    )
    
	# A property that is set on all package main targets.
    define_property(
        TARGET
        PROPERTY CCB_PACKAGE_MAINTAINER_EMAIL
        BRIEF_DOCS "An email address under which the maintainers of the package can be reached."
        FULL_DOCS " "
    )

    # A property that is set on all main targets that have the same name as their package.
    define_property(
        TARGET
        PROPERTY CCB_BINARY_SUBTARGETS
        BRIEF_DOCS "A list of all binary targets that are associated with the package including the main target."
        FULL_DOCS " "
    )

	# A property that is set on all main targets.
	define_property(
        TARGET
        PROPERTY CCB_PRODUCTION_LIB_SUBTARGET
        BRIEF_DOCS "For executables this ccbContains the name of the helper implementation library target. For library targets this ccbContains the name of the main target."
        FULL_DOCS " "
    )

    # A property that is set on all main targets.
    define_property(
        TARGET
        PROPERTY CCB_TEST_FIXTURE_SUBTARGET
        BRIEF_DOCS "The library the ccbContains test utilities."
        FULL_DOCS " "
    )

    # A property that is set on all main targets.
    define_property(
        TARGET
        PROPERTY CCB_TESTS_SUBTARGET
        BRIEF_DOCS "The test target that ccbContains the quick tests."
        FULL_DOCS " "
    )

	# A property that is set on all binary targets.
	define_property(
        TARGET
        PROPERTY CCB_PUBLIC_HEADER
        BRIEF_DOCS "The header files that need to be accessed by consumers that link to the target."
        FULL_DOCS " "
    )

    # A property that is set on binary targets that have .ui fiels.
    define_property( 
        TARGET 
        PROPERTY CCB_UIC_SUBTARGET 
        BRIEF_DOCS "A target that runs Qt's uic on all .ui files of the main-target in order to generate the ui_*.h files"
        FULL_DOCS " "
        )
       
    # A property that is set on all binary targets when using the clang toolchain.
    define_property(
        TARGET
        PROPERTY CCB_STATIC_ANALYSIS_SUBTARGET
        BRIEF_DOCS "A target that runs clang-tidy on all .cpp files of the binary target."
        FULL_DOCS " "
    )
    
	# A property that is set on all package main targets.
    define_property(
        TARGET
        PROPERTY CCB_DYNAMIC_ANALYSIS_SUBTARGET
        BRIEF_DOCS "Contains the name of a sub-target that runs Valgrind or OpenCppCoverage."
        FULL_DOCS " "
    )

	# A property that is set on the dynamic analysis targets.
    define_property(
        TARGET
        PROPERTY CCB_CPPCOVERAGE_OUTPUT
        BRIEF_DOCS "Contains a list of .cov files that are generated by running OpenCppCoverage."
        FULL_DOCS " "
    )

    # A property that is set on all package main targets
    define_property(
        TARGET
        PROPERTY CCB_RUN_TESTS_SUBTARGET
        BRIEF_DOCS "The name of the sub-target that runs all automated tests."
        FULL_DOCS " "
    )

	# A property that is set on all package main targets
    define_property(
        TARGET
        PROPERTY CCB_RUN_FAST_TESTS_SUBTARGET
        BRIEF_DOCS "The name of the sub-target that runs only the fast tests."
        FULL_DOCS " "
    )

	# A property that is set on the modules main binary target.
	define_property(
        TARGET
        PROPERTY CCB_DOXYGEN_SUBTARGET
        BRIEF_DOCS "The name of a custom sub-target that runs doxygen in order to generate an xml tags file that ccbContains documentation information of the modules source files."
        FULL_DOCS " "
    )

	# A property that is set on the CCB_DOXYGEN_SUBTARGET targets.
	define_property(
        TARGET
        PROPERTY CCB_DOXYGEN_TAGSFILE
        BRIEF_DOCS "The full path to the file xml tags file that is generated by the CCB_DOXYGEN_SUBTARGET target."
        FULL_DOCS " "
    )
	
	# A property that is set on the modules main binary target.
	define_property(
        TARGET
        PROPERTY CCB_DOXYGEN_CONFIG_SUBTARGET
        BRIEF_DOCS "The name of a custom sub-target that generates the per target doxygen config file by copying the global file and overwriting some options."
        FULL_DOCS " "
    )

	# A property that is set on the CCB_DOXYGEN_CONFIG_SUBTARGET targets.
	define_property(
        TARGET
        PROPERTY CCB_DOXYGEN_CONFIG_FILE
        BRIEF_DOCS "The full path to the file config file that is generated by the CCB_DOXYGEN_CONFIG_SUBTARGET target."
        FULL_DOCS " "
    )

	# A property that is set on all package main targets
	define_property(
        TARGET
        PROPERTY CCB_INSTALL_PACKAGE_SUBTARGET
        BRIEF_DOCS "The name of a custom sub-target that installs the packages files to the local InstallStage directory."
        FULL_DOCS " "
    )

	# A property that is set on all package main targets
	define_property(
        TARGET
        PROPERTY CCB_CREATE_DISTRIBUTION_PACKAGE_SUBTARGETS
        BRIEF_DOCS "The names of the custom sub-target that create distribution-packages for the package."
        FULL_DOCS " "
    )
    
	# A property that is set on all package main targets
	define_property(
        TARGET
        PROPERTY CCB_ABI_DUMP_SUBTARGETS
        BRIEF_DOCS "The names of the custom sub-target that create the abi dumps."
        FULL_DOCS " "
    )
    
    # A property that is set on all package main targets
    define_property(
		TARGET
		PROPERTY CCB_ABI_CHECK_SUBTARGETS
		BRIEF_DOCS "The names of all custom sub-target that call the abi-compliance-checker tool."
		FULL_DOCS " "
    )

	# A property that is set on some targets
	define_property(
		TARGET
		PROPERTY CCB_OUTPUT_FILES
		BRIEF_DOCS "A list of files that are created when the target is build."
		FULL_DOCS " "
	)

	# Configuration dependent properties	
	ccbGetConfigurations(configs)
	foreach(config ${configs})

		# A configuration dependent property that is set on all package main targets 
		define_property(
			TARGET
			PROPERTY CCB_INSTALLED_FILES${configSuffix}
			BRIEF_DOCS "A list of files that belong to the installed package. Paths are relative to the install prefix."
			FULL_DOCS " "
		)

		# A configuration dependent property that is set on some targets (optimally it should be set on all to get a completely clean dependency chain)
		define_property(
			TARGET
			PROPERTY CCB_OUTPUT_FILES${configSuffix}
			BRIEF_DOCS "A list of files that are created when the target is build in the given configuration."
			FULL_DOCS " "
		)

	endforeach()
	
	

       
endfunction()