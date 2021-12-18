
API Global Variables
====================

This page holds the documentation of global CMake variables that can be set by the clients of
CPFCMake to influence its behavior.


Global variables and cache variables
------------------------------------

CPFCMake introduces some variables of global scope. Some of these variables are set by the CPFCMake and some are supposed to
be set by the user. The best place to set these variables is in your projects default configuration files in the :code:`CIBuildConfigurations` directory.


CPF Variables
^^^^^^^^^^^^^

- :ref:`CPF_CI_PROJECT` 
- :ref:`CPF_CLANG_FORMAT_EXE`
- :ref:`CPF_CLANG_TIDY_EXE`
- :ref:`CPF_WEBSERVER_BASE_DIR`
- :ref:`CPF_MINIMUM_CMAKE_VERSION`
- :ref:`CPF_VERBOSE`
- :ref:`CPF_ENABLE_ACYCLIC_TARGET`


.. _CPF_CI_PROJECT:

CPF_CI_PROJECT
""""""""""""""

It holds the name of the top-level CI-project that is created in the root :code:`CMakeLists.txt` file.
The variable is set in the :ref:`cpfAddPackages` function and can then be read from clients in
the packages :code:`CMakeLists.txt` files.


.. _CPF_CURRENT_PACKAGET:

CPF_CURRENT_PACKAGE
"""""""""""""""""""

It holds the name of the current package project. It is set in the :ref:`cpfPackageProject` function.


.. _CPF_CLANG_FORMAT_EXE:

CPF_CLANG_FORMAT_EXE
""""""""""""""""""""

Setting this may only be required when setting :ref:`cpfArgEnableClangFormatTargets` true.
The value is used when the CPF looks for the clang-format tool. For example you may set it to
:code:`clang-format-10` if the executable has that name on your system.


.. _CPF_CLANG_TIDY_EXE:

CPF_CLANG_TIDY_EXE
""""""""""""""""""

Setting this may only be required when setting :ref:`cpfArgEnableClangTidyTarget` true.
The value is used when the CPF looks for the clang-tidy tool. For example you can set it to
:code:`clang-tidy-10` if the executable has that name on your system.


.. _CPF_WEBSERVER_BASE_DIR:

CPF_WEBSERVER_BASE_DIR
""""""""""""""""""""""

Setting this variable is only required if the web-server functionality from
:ref:`CPFMachines` is used. It must then be set to the base url of the
web-server that hosts the CI-projects html pages.
For example :code:`http://buildmasterdebian9:8081` if the web-server container
is hosted on the buildmasterdebian9 machine and its port is mapped to the host-port
:code:`8081`. Setting this variable is required if the :ref:`abicompliancechecker_package` targets are
enabled, to allow downloading old binary files from the web-server.


.. _CPF_MINIMUM_CMAKE_VERSION:

CPF_MINIMUM_CMAKE_VERSION
"""""""""""""""""""""""""

The variable is set to the minimum CMake version that is required for the cmake code
in CPFCMake. This is not supposed to be set by clients. The variable is set by the line

.. code-block:: cmake

	include("${CMAKE_SOURCE_DIR}/CPFCMake/cpfInitCIProject.cmake")

which should be one of the first lines in your root :code:`CMakeLists.txt` file.
Your project can require a younger CMake version, but you can not use an older one when using CPFCMake.


.. _CPF_VERBOSE:

CPF_VERBOSE
"""""""""""

Set this variable to :code:`True` to print more output from the CPFCMake code that
may be helpful for trouble shooting problems.


.. _CPF_ENABLE_ACYCLIC_TARGET:

CPF_ENABLE_ACYCLIC_TARGET
"""""""""""""""""""""""""

This option can be used to disable the global :ref:`acyclic` target.


Per Package and per Package-Component Variables
-----------------------------------------------

CMake provides a set of variables that are used to initialize target properties.
CPFCMake hides the :code:`add_subdirectory()` calls in the :ref:`cpfAddPackages` and :ref:`cpfPackageProject` functions
which prevents users from setting these global variables differently for individual packages or package components.
To work around this, CPFCMake allows setting package and package-component specific versions of these variables.
Setting the :code:`BUILD_SHARED_LIBS` variable only for package :code:`MyPackage` can be done by calling

.. code-block:: cmake
	
	set(MyPackage_BUILD_SHARED_LIBS TRUE)

If :code:`BUILD_SHARED_LIBS` should only be set for :code:`MyComponent` in :code:`MyPackage`
it can be done by calling:

.. code-block:: cmake
	
	set(MyPackage_MyComponent_BUILD_SHARED_LIBS TRUE)

This mechanism is currently implemented for the following CMake variables:

- :code:`BUILD_SHARED_LIBS`
- :code:`CMAKE_ARCHIVE_OUTPUT_DIRECTORY`
- :code:`CMAKE_ARCHIVE_OUTPUT_DIRECTORY_CONFIG`
- :code:`CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY`
- :code:`CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY`
- :code:`CMAKE_LIBRARY_OUTPUT_DIRECTORY`
- :code:`CMAKE_LIBRARY_OUTPUT_DIRECTORY`
- :code:`CMAKE_PDB_OUTPUT_DIRECTORY`
- :code:`CMAKE_PDB_OUTPUT_DIRECTORY`
- :code:`CMAKE_RUNTIME_OUTPUT_DIRECTORY`
- :code:`CMAKE_RUNTIME_OUTPUT_DIRECTORY`
- :code:`CMAKE_config_POSTFIX`



Global Package Component Options
--------------------------------

Similar to the mechanisim that allows setting global CMake variables on a per packge
or packge-component basis, CPFCMake allows initializing some options of the :code:`cpfAddXXXPackageComponent()`
function family with global variables. If this mechanism is implemented for an keyword :code:`COMPILE_OPTIONS` argument of a function,
the argument can also be default initialized by setting the global variables:

.. code-block:: cmake

	# Global scope
	set(CPF_COMPILE_OPTIONS bli)
	set(MyPackage_COMPILE_OPTIONS bla)
	set(MyPackage_MyComponent_COMPILE_OPTIONS blub)

	...

	# Package-component scope
	cpfAddCppPackageComponent(
	...
	)


The variables with smaller scope take precedence over those with larger scope. So in this case all C++ components
that are not part of MyPackage would get the compile option :code:`bli`. All C++ components in MyPackage would get
the compile option :code:`bla` except for MyComponent which would get option :code:`blub`.
If an option is set directly in the :code:`cpfAddCppPackageComponent()` call, it can not be overridden from the outside.

This mechanism has the following benefits:

- It allows setting package-component options in one global place.
- It allows package clients to disable unwanted external helper targets like tests.
- It allows you to set package-component options that should not be overridden by clients.


Global defaults for the cpfAddCppPackageComponent() function
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Here is a list of the options of the :ref:`cpfAddCppPackageComponent` function that support
global initialization.

- :ref:`ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS`
- :ref:`ENABLE_ABI_API_STABILITY_CHECK_TARGETS`
- :ref:`ENABLE_CLANG_FORMAT_TARGETS`
- :ref:`ENABLE_CLANG_TIDY_TARGET`
- :ref:`ENABLE_OPENCPPCOVERAGE_TARGET`
- :ref:`ENABLE_PACKAGE_DOX_FILE_GENERATION`
- :ref:`ENABLE_RUN_TESTS_TARGET`
- :ref:`ENABLE_VALGRIND_TARGET`
- :ref:`COMPILE_OPTIONS`


Global defaults for the cpfAddDoxygenPackageComponent() function
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Here is a list of the options of the :ref:`cpfAddDoxygenPackageComponent` function that support
global initialization.

- :ref:`DOXYGEN_BIN_DIR`


Allowed CMake Variables
^^^^^^^^^^^^^^^^^^^^^^^

CMake introduces its own set of global variables. Many of them can still be used.
Others may be overridden by CPFCMake while implementing its functionality.
Here is a list of CMake variables that CPFCMake expects you to set.

- :code:`BUILD_SHARED_LIBS`: This can still be used as a global switch for creating
  shared or static libraries. If you provide library package-components for other developers, you should
  not set this variable on the package-component level. This allows clients to choose the library
  linkage they want to use.
- :code:`CMAKE_<config>_POSTFIX`: CPFCMake sets default values for this variable. You can
  change the values if you do not like them or have added your own compiler configurations.
- :code:`CMAKE_BUILD_TYPE`: While CMake does not require a value for this variable, CPFCMake does when a single
  configuration build-tool like *make* or *ninja* is used.
  The variable must be set to the name of the compiler configuration like :code:`Debug` or :code:`Release`.
- :code:`CMAKE_GENERATOR`: The :ref:`scriptGenerate` script does not use cmake's generator argument
  but instead relies on the value of this variable to get it. This is done to allow having the
  specification of the generator in the configuration file instead of re-typing it on every
  cmake call. The default configurations that are provided by CPFCMake already set a value
  for that variable.
- :code:`CMAKE_MAKE_PROGRAM`: This can be used to define the build-tool that is used.
  The default configurations that are provided by CPFCMake already set a value
  for that variable.
- :code:`CMAKE_TOOLCHAIN_FILE`: The value of that variable must be set to a :code:`.cmake` file
  that specifies the used compiler and the ABI relevant compiler flags.
  CPFCMake provides tool-chain-files for its default configurations which you can
  use as templates to create your own ones if needed. The CPF uses a toolchain file
  to foster the use of the package manager *hunter* which requires abi relevant compiler options
  to be bundled in one file to determine if dependencies need to be re-build.


Overridden CMake Variables
^^^^^^^^^^^^^^^^^^^^^^^^^^

Here is a list of the CMake variables for which CPFCMake assigns
fixed values. Setting these variables should in the best case 
have no effect but may cause faulty behavior of the CPFCMake functions.

- :code:`PROJECT_VERSION`: CPFCMake retrieves the version from the underlying
  git repository. There should be no need to set this manually.
- :code:`CMAKE_EXPORT_COMPILE_COMMANDS`: CPFCMake will set this to ON when
  using the clang compiler in order to allow clang-tidy to be run.


Overridden target properties
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

CPFCMake sets some target properties to its own values. Resetting those
properties to other values after calling :ref:`cpfAddCppPackageComponent` may cause
errors.

- :code:`CONFIG_OUTPUT_NAME`
- :code:`CONFIG_POSTFIX`
- :code:`COMPILE_PDB_OUTPUT_DIRECTORY_CONFIG`
- :code:`COMPILE_PDB_NAME_CONFIG`
- :code:`ARCHIVE_OUTPUT_NAME_CONFIG`
- :code:`ARCHIVE_OUTPUT_DIRECTORY_CONFIG`
- :code:`LIBRARY_OUTPUT_NAME_CONFIG`
- :code:`LIBRARY_OUTPUT_DIRECTORY_CONFIG`
- :code:`PDB_OUTPUT_DIRECTORY_CONFIG`
- :code:`PDB_NAME_CONFIG`
- :code:`RUNTIME_OUTPUT_NAME_CONFIG`
- :code:`RUNTIME_OUTPUT_DIRECTORY_CONFIG`

All the binary output locations are fixed by CPFCMake. This is because
some functionality relies on those locations.


