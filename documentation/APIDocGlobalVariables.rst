
API Global Variables
====================

This page holds the documentation of global CMake variables that can be set by the clients of
CPFCMake to influence its behavior.

Global variables and cache variables
------------------------------------

CPFCMake introduces some variables of global scope that provide CI-project wide defaults 
for recurring package settings. 
Most of them can be overridden with optional parameters when adding individual packages. 
This spares the user from repeatedly specifying the same values while at the same time allowing 
individual values for each package where necessary. The best place to set these variables is
in your projects default configuration files in the \c CIBuildConfigurations directory.

CPF Variables
^^^^^^^^^^^^^


- \ref CPF_CI_PROJECT
- \ref CPF_CLANG_FORMAT_EXE
- \ref CPF_CLANG_TIDY_EXE
- \ref CPF_WEBSERVER_BASE_DIR
- \ref CPF_MINIMUM_CMAKE_VERSION
- \ref CPF_VERBOSE
- \ref CPF_ENABLE_ACYCLIC_TARGET
- \ref CPF_TARGET_NAMESPACE


CPF_CI_PROJECT
""""""""""""""

It holds the name of the top-level CI-project that is created in the root \c CMakeLists.txt file.
The variable is set in the \ref cpfAddPackages function and can then be read from clients in
the packages \c CMakeLists.txt files.


CPF_CLANG_FORMAT_EXE
""""""""""""""""""""

Setting this may only be required when setting \ref cpfArgEnableClangFormatTargets true.
The value is used when the CPF looks for the clang-format tool. For example you may set it to
\c clang-format-10 if the executable has that name on your system.


CPF_CLANG_TIDY_EXE
""""""""""""""""""

Setting this may only be required when setting \ref cpfArgEnableClangTidyTarget true.
The value is used when the CPF looks for the clang-tidy tool. For example you can set it to
\c clang-tidy-10 if the executable has that name on your system.


CPF_WEBSERVER_BASE_DIR
""""""""""""""""""""""

Setting this variable is only required if the web-server functionality from
\ref CPFMachines is used. It must then be set to the base url of the
web-server that hosts the CI-projects html pages.
For example <code>%http://buildmasterdebian9:8081</code> if the web-server container
is hosted on the buildmasterdebian9 machine and its port is mapped to the host-port
\c 8081. Setting this variable is required if the \ref abicompliancechecker_package targets are
enabled, to allow downloading old binary files from the web-server.


CPF_MINIMUM_CMAKE_VERSION
"""""""""""""""""""""""""

The variable is set to the minimum CMake version that is required for the cmake code
in CPFCMake. This is not supposed to be set by clients. Your project can require a younger CMake version,
but you can not use an older one when using CPFCMake.


CPF_VERBOSE
"""""""""""

Set this variable to \c True to print more output from the CPFCMake code that
may be helpful for trouble shooting problems.


CPF_ENABLE_ACYCLIC_TARGET
"""""""""""""""""""""""""

This option can be used to disable the global \ref acyclic target.


Global defaults for the cpfAddCppPackageComponent() function
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The :ref:`cpfAddCppPackageComponent` function has a lot of parameters. Many of them
are likely to take the same value across most packages in your CI-project. The CPF provides
a list of global variables that you can set in your configuration file
in order to provide defaults for these arguments.
If one of your packages needs a different value then you can simply
override the the global value by giving a different value to the 
argument in the local function call. Each variable overrides the
respective argument without the :code:`CPF_` prefix.
Here is a list of the variables.

- CPF\_:ref:`cpfArgEnableAbiApiCompatibilityReportTargets`
- CPF\_:ref:`cpfArgEnableAbiApiStablilityCheckTargets`
- CPF\_:ref:`cpfArgEnableClangFormatTargets`
- CPF\_:ref:`cpfArgEnableClangTidyTarget`
- CPF\_:ref:`cpfArgEnableOpenCppCoverageTarget`
- CPF\_:ref:`cpfArgEnablePackageDoxFileGeneration`
- CPF\_:ref:`cpfArgEnablePrecompiledHeader`
- CPF\_:ref:`cpfArgEnableRunTestsTarget`
- CPF\_:ref:`cpfArgEnableValgrindTarget`
- CPF\_:ref:`cpfArgEnableVersionRCFileGeneration`
- CPF\_:ref:`cpfArgCompileOptions`
- CPF\_:ref:`cpfArgHasGoogleTestExe`


Allowed CMake Variables
^^^^^^^^^^^^^^^^^^^^^^^

CMake introduces its own set of global variables. Many of them can still be used.
Others may be overridden by CPFCMake while implementing its functionality.
Here is a list of CMake variables that CPFCMake expects you to set.

- <b>BUILD_SHARED_LIBS:</b> This can still be used as a global switch for creating
  shared or static libraries. If you provide library packages for other developers, you should
  not set this variable on the package level. This allows clients to choose the library
  linkage they want to use.
- <b>CMAKE_<config>_POSTFIX:</b> CPFCMake sets default values for this variable. You can
  change the values if you do not like them or have added your own compiler configurations.
- <b>CMAKE_BUILD_TYPE:</b> While CMake does not require a value for this variable, CPFCMake does when a single
  configuration build-tool like *make* or *ninja* is used.
  The variable must be set to the name of the compiler configuration like "Debug" or "Release".
- <b>CMAKE_GENERATOR:</b> The \ref scriptGenerate script does not use cmake's generator argument
  but instead relies on the value of this variable to get it. This is done to allow having the
  specification of the generator in the configuration file instead of re-typing it on every
  cmake call. The default configurations that are provided by CPFCMake already set a value
  for that variable.
- <b>CMAKE_MAKE_PROGRAM:</b> This can be used to define the build-tool that is used.
  The default configurations that are provided by CPFCMake already set a value
  for that variable.
- <b>CMAKE_TOOLCHAIN_FILE:</b> The value of that variable must be set to a \c .cmake file
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

- <b>PROJECT_VERSION:</b> CPFCMake retrieves the version from the underlying
  git repository. There should be no need to set this manually.
- <b>CMAKE_EXPORT_COMPILE_COMMANDS:</b> CPFCMake will set this to ON when
  using the clang compiler in order to allow clang-tidy to be run.


Overridden target properties
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

CPFCMake sets some target properties to its own values. Resetting those
properties to other values after calling \ref cpfAddCppPackageComponent may cause
errors.

- <b>CONFIG_OUTPUT_NAME</b>
- <b>CONFIG_POSTFIX</b>
- <b>COMPILE_PDB_OUTPUT_DIRECTORY_CONFIG</b>
- <b>COMPILE_PDB_NAME_CONFIG</b>
- <b>ARCHIVE_OUTPUT_NAME_CONFIG</b>
- <b>ARCHIVE_OUTPUT_DIRECTORY_CONFIG</b>
- <b>LIBRARY_OUTPUT_NAME_CONFIG</b>
- <b>LIBRARY_OUTPUT_DIRECTORY_CONFIG</b>
- <b>PDB_OUTPUT_DIRECTORY_CONFIG</b>
- <b>PDB_NAME_CONFIG</b>
- <b>RUNTIME_OUTPUT_NAME_CONFIG</b>
- <b>RUNTIME_OUTPUT_DIRECTORY_CONFIG</b>

All the binary output locations are fixed by CPFCMake. This is because
some functionality relies on those locations.


