
.. _ApiDocModules:

API Functions
=============

This page holds the documentation of the *CMake* functions that are provided to the
users of the *CPFCMake* package.


Argument Notation
-----------------

Here are some examples to explain how the function argument notation must be interpreted.

- <code>PACKAGE_NAMESPACE string</code>: The function expects the required key-word \c PACKAGE_NAMESPACE to be followed by a single string.
- <code>[PUBLIC_HEADER file1 [file2 ...]]</code>: The function expects the optional key-word \c PUBLIC_HEADER followed by one
  or more paths to source files. If not otherwise specified, paths must be absolute or relative to \c CMAKE_CURRENT_SOURCE_DIR.
- <code>[ENABLE_CLANG_TIDY_TARGET bool]</code>: The function expects the optional key-word \c ENABLE_CLANG_TIDY_TARGET followed by
  either \c TRUE or \c FALSE.
- <code>DISTRIBUTION_PACKAGE_FORMATS <7Z|TBZ2|TGZ ...></code>: The function expects the required key-word \c DISTRIBUTION_PACKAGE_FORMATS to be followed by
  one or multiple values of the listed enum \c 7Z, \c TBZ2 and \c TGZ.

Argument Sub-Lists
^^^^^^^^^^^^^^^^^^

Example:

.. code-block:: cmake

  [PLUGIN_DEPENDENCIES 
      PLUGIN_DIRECTORY dir
      PLUGIN_TARGETS target1 [target2 ...]
  [list2 ....]]


Some options are complex enough to require sub-lists of key-word value pairs.
In this example \c PLUGIN_DEPENDENCIES separates multiple sub-lists for plugin definitions.
In a function call this could look like this:

.. code-block:: cmake

  cpfAddCppPackage(
      ...
      PLUGIN_DEPENDENCIES  
          PLUGIN_DIRECTORY plugin
          PLUGIN_TARGETS MyPlugin1 MyPlugin2 
      PLUGIN_DEPENDENCIES  
          PLUGIN_DIRECTORY platforms
          PLUGIN_TARGETS Qt5::QWindowsIntegrationPlugin
      ...
  )


.. _cpfInitModule:

Module cpfInit.cmake
--------------------

This must be included at the top of your root CMakeLists.txt file. 

- It adds all CPF modules to the <code>CMAKE_MODULE_PATH</code> allows including them with their short filenames only.
- It sets the global variable <code>CPF_MINIMUM_CMAKE_VERSION</code> and checks that the currently run CMake version meets the requirement.
- Sets the CMake policies that are required for CPF projects.
- It includes further CPF modules that are needed in the root CMakeLists.txt file.


Module cpfAddPackages.cmake
---------------------------

This module provides the following function.

-  cpfAddPackages()


.. _cpfAddPackages:

cpfAddPackages()
^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfAddPackages(
      [GLOBAL_FILES file1 [file2 ...]] 
  )


The function is called in all CPF CI-projects.

- This calls <code>add_subdirectory()</code> for all the packages that are defined in the <code>package.cmake</code>
  file. 
- This adds the global custom targets. \see GlobalTargets
- Initiates some global variables.

Arguments
"""""""""

**GLOBAL_FILES**

This option can be used to add further files to the \ref globalFiles target.


Module cpfInitPackageModule.cmake
---------------------------------

This module provides the following function.

- cpfInitPackageProject()


.. _cpfInitPackageProject:

cpfInitPackageProject()
^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfInitPackageProject()


This macro is called at the beginning of a cpf-packages *CMakeLists.txt* file.
This function calls the \c project() function to create the package-level project.
It automatically reads the version number of the package from the packages
git repository or a provided version file and uses it to initiated the cmake
variables <code>PROJECT_VERSION</code> and <code>PROJECT_VERSION_<digit></code> variables.

.. seealso::

  CIProjectAndPackageProjects


Module cpfAddCppPackage.cmake
-----------------------------

This module provides the following functions.


- `cpfAddCppPackage()`_
- :ref:`cpfQt5AddUIAndQrcFiles`


.. _cpfAddCppPackage:

cpfAddCppPackage()
^^^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfAddCppPackage(
      PACKAGE_NAMESPACE string
      TYPE <GUI_APP|CONSOLE_APP|LIB|INTERFACE_LIB>
      [BRIEF_DESCRIPTION string]
      [LONG_DESCRIPTION string]
      [OWNER string]
      [WEBPAGE_URL string]
      [MAINTAINER_EMAIL string]
      [PUBLIC_HEADER file1 [file2 ...]]
      [PRODUCTION_FILES file1 [file2 ...]]
	  [EXE_FILES file1 [file2 ...]]
      [PUBLIC_FIXTURE_HEADER header1 [header2 ...]]
      [FIXTURE_FILES file1 [file2 ...]]
      [TEST_FILES file1 [file2 ...]]
      [LINKED_LIBRARIES <PRIVATE|PUBLIC|INTERFACE> target1 ... [ <PRIVATE|PUBLIC|INTERFACE> targetX ...]]
      [LINKED_TEST_LIBRARIES <PRIVATE|PUBLIC|INTERFACE> target1 ... [ <PRIVATE|PUBLIC|INTERFACE> targetX ...]]
	  [COMPILE_OPTIONS [BEFORE] <INTERFACE|PUBLIC|PRIVATE>]
      [PLUGIN_DEPENDENCIES 
          PLUGIN_DIRECTORY dir
          PLUGIN_TARGETS target1 [target2 ...]
      ...]
      [DISTRIBUTION_PACKAGES
          DISTRIBUTION_PACKAGE_CONTENT_TYPE <CT_RUNTIME|CT_RUNTIME_PORTABLE excludedTargets|CT_DEVELOPER|CT_SOURCES>
          DISTRIBUTION_PACKAGE_FORMATS <7Z|TBZ2|TGZ|TXZ|TZ|ZIP|DEB ...>
          [DISTRIBUTION_PACKAGE_FORMAT_OPTIONS 
              [SYSTEM_PACKAGES_DEB packageListString ]
          ]
          [DISTRIBUTION_PACKAGE_CONTENT_TYPE ...] 
      ...]
      [VERSION_COMPATIBILITY_SCHEME [ExactVersion] ]
      [ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS bool]
      [ENABLE_ABI_API_STABILITY_CHECK_TARGETS bool]
	  [ENABLE_CLANG_FORMAT_TARGETS bool]
      [ENABLE_CLANG_TIDY_TARGET bool]
      [ENABLE_OPENCPPCOVERAGE_TARGET bool]
      [ENABLE_PACKAGE_DOX_FILE_GENERATION bool]
      [ENABLE_PRECOMPILED_HEADER bool]
      [ENABLE_RUN_TESTS_TARGET bool]
      [ENABLE_VALGRIND_TARGET bool]
	  [ENABLE_VERSION_RC_FILE_GENERATION bool]
  )


Adds a C++ package to a CPF project. The name of the package is the same as the
name of the directory in which the packages CMakeLists.txt file is located.
The function provides a large list of options that allow defining the features that the package should provide.

A C++ package consists of a main binary target that has the same name as the package and some helper binary targets for tests and test utilities.
The names of the created targets are:

.. code-block:: cmake

  # Binary Targets of MyPackage
  MyPackage				      # The executable or library
  libMyPackage			    # The implementation library that is created for packages of TYPE GUI_APP or CONSOLE_APP.
  MyPackage_fixtures		# A library for test test utility code that is created when the FIXTURE_FILES option is given.
  MyPackage_tests			  # A text executable that is created when the TEST_FILES option is given.

  # Alias Targets of MyPackage with PACKAGE_NAMESPACE mypckg
  mypckg::MyPackage
  mypckg::libMyPackage
  mypckg::MyPackage_fixtures
  mypckg::MyPackage_tests


The function will create alias targets for all binary targets that have the package namespace prepended.
It is recommended to use the alias names in other packages, which enables to smoothly switch between inlined
and imported packages.

Providing the function with optional arguments will switch on more of CPF's functionality like test-targets, code-analysis, packaging or
documentation generation.

.. seealso::

  CPFCustomTargets

.. _cpfAddCppPackage_arguments:

Arguments
"""""""""

**PACKAGE_NAMESPACE**

The parameter is used in the following ways:

- CPFCMake assumes, this is the C++ namespace that you use in the package.
- The name is used as a namespace in the packages generated C++ version header file.
- As a namespace for the packages cmake target names.
- The value is used as a part of the packages generated export macro which must be 
  prepended to all exported classes and functions in a library.
- If you use the <code>ENABLE_PACKAGE_DOX_FILES_GENERATION</code> option, the default package documentation 
  page will generate a documentation of that namespace.


**TYPE**

The type of the main binary target of the package.

- \c GUI_APP = Executable with switched of console. Use this for Qt applications with GUI; 
- \c CONSOLE_APP = Console application; 
- \c LIB = Library
- \c INTERFACE_LIB = Header only library


**BRIEF_DESCRIPTION**

A short description in one sentence about what the package does. This is included
in the generated documentation page of the package and in some distribution package
types. It is also displayed on the "Details" tab of the file-properties window of 
the generated main binary file when compiling with MSVC.


**LONG_DESCRIPTION**

A longer description of the package. This is included
in the generated documentation page of the package and in some distribution package
types.


**OWNER**

The value is only used when compiling with MSVC. It is than used in the copyright notice 
that is displayed on the "Details" tab of the file-properties window of the generated binary
files. 

If you plan to allow using a package as \c EXTERNAL package in some other CI-project,
you have to hard-code this value in the packages CMakeLists file. Using a variable from the
CI-project in order to remove duplication between your packages will not work, because clients
will not have the value of that variable.


**WEBPAGE_URL**

A web address from where the source-code and/or the documentation of the package can be obtained.
This is required for Debian packages.

If you plan to allow using a package as \c EXTERNAL package in some other CI-project,
you have to hard-code this value in the packages CMakeLists file. Using a variable from the
CI-project in order to remove duplication between your packages will not work, because clients
will not have the value of that variable.


**MAINTAINER_EMAIL**

An email address under which the maintainers of the package can be reached.
This is required for Debian packages.
Setting this argument overrides the value of the global \c CPF_MAINTAINER_EMAIL variable for this package.

If you plan to allow using a package as \c EXTERNAL package in some other CI-project,
you have to hard-code this value in the packages CMakeLists file. Using a variable from the
CI-project in order to remove duplication between your packages will not work, because clients
will not have the value of that variable.


**PUBLIC_HEADER**

All header files that declare functions or classes that are supposed to be
used by consumers of a library package. The public headers will automatically
be put into binary distribution packages, while header files in the \c PRODUCTION_FILES
are not included.


**PRODUCTION_FILES**

All files that belong to the production target. If the target is an executable, 
there should be a main.cpp that is used for the executable.


**PRODUCTION_FILES**

For packages of type \c GUI_APP or \c CONSOLE_APP, this variable that must be
added to the executable itself. On windows this can be \c .rc files or the
icon for the executable.


**PUBLIC_FIXTURE_HEADER**

All header files in the fixture library that are required by external clients of the library.
If the fixture library is only used by this package, this can be empty.


**FIXTURE_FILES**

All files that belong to the test fixtures target.


**TEST_FILES**

All files that belong to the test executable target.


**COMPILE_OPTIONS**

The values of this argument are simply piped through to a call of the CMake function 
<a href="https://cmake.org/cmake/help/latest/command/target_compile_options.html">target_compile_options()</a> 
for each generated binary target. For further information about the possible values refer to the CMake documentation.


**LINKED_LIBRARIES**

The names of the library targets that are linked to the main binary target.
Just like in CMakes <a href="https://cmake.org/cmake/help/latest/command/target_link_libraries.html">target_link_libraries()</a> 
function you can use the PUBLIC, PRIVATE and INTERFACE keywords.


**LINKED_TEST_LIBRARIES**

The names of the library targets that are linked to the test fixture library
and the test executable. Use this to specify dependencies of the test targets
that are not needed in the production code, like fixture libraries from other
packages.


**PLUGIN_DEPENDENCIES**

This keyword opens a sub-list of arguments that are used to define plugin dependencies of the package. 
Multiple PLUGIN_DEPENDENCIES sub-lists can be given to allow having multiple plugin subdirectories.

The plugin targets are shared libraries that are explicitly loaded by the packages executables and on which the
package has no link dependency. If a target in the list does not exist when the function is called,
it will be silently ignored. If a given target is an internal target, an artificial dependency between
the plugin target and the packages executables is created to make sure the plugin is compilation is up-to-date before the
executable is build.

Adding this options makes sure that the plugin library is build before the executable and copied besides it
in the \c PLUGIN_DIRECTORY.

Sub-Options:

\c PLUGIN_DIRECTORY: A directory relative to the packages executables in which the plugin libraries must be deployed so they are found by the executable.
This if often a \c plugins directory.

\c PLUGIN_TARGETS: The name of the targets that provide the plugin libraries.


**DISTRIBUTION_PACKAGES**

This keyword opens a sub-list of arguments that are used to specify a list of packages that have the same content, but different formats.
The argument can be given multiple times, in order to define a variety of package formats and content types.
The argument takes two lists as sub-arguments. A distribution package is created for each combination of the
elements in the sub-argument lists.
For example: 
argument <code>DISTRIBUTION_PACKAGES DISTRIBUTION_PACKAGE_CONTENT_TYPE CT_RUNTIME_PORTABLE DISTRIBUTION_PACKAGE_FORMATS ZIP;7Z</code>
will cause the creation of a zip and a 7z archive that both contain the packages executables and all depended on shared libraries.
Adding another argument <code>DISTRIBUTION_PACKAGES DISTRIBUTION_PACKAGE_CONTENT_TYPE CT_RUNTIME DISTRIBUTION_PACKAGE_FORMATS DEB</code>
will cause the additional creation of a debian package that relies on external dependencies being provided by other packages.

Sub-Options:

DISTRIBUTION_PACKAGE_CONTENT_TYPE                

- :code:`CT_RUNTIME`: The distribution-package contains the executables and shared libraries that are produced by this package.
  This can be used for packages that either do not depend on any shared libraries or only on shared libraries that
  are provided externally by the system.

- :code:`CT_RUNTIME_PORTABLE listExcludedTargets`: The distribution-package will include the packages executables 
  and shared libraries and all depended on shared libraries. This is useful for creating "portable" packages
  that do not rely on any system provided shared libraries.
  The CT_RUNTIME_PORTABLE keyword can be followed by a list of depended on targets that belong
  to shared libraries that should not be included in the package, because they are provided by the system. 

- :code:`CT_DEVELOPER`: The distribution-package will include all package binaries, header files and cmake config files for 
  importing the package in another project. This content type is supposed to be used for binary library packages
  that are used in other projects. Note that for msvc debug configurations the package will also include source files
  to allow debugging into the package. The package does not include dependencies which are supposed to be imported
  separately by consuming projects.

- :code:`CT_SOURCES`: The distribution-package contains the files that are needed to compile the package.


DISTRIBUTION_PACKAGE_FORMATS

- :code:`7Z |TBZ2 | TGZ | TXZ | TZ | ZIP`: Packs the distributed files into one of the following archive formats: .7z, .tar.bz2, .tar.gz, .tar.xz, tar.Z, .zip
- :code:`DEB`: Creates a debian package .deb file. This will only be created when the dpkg tool is available.

DISTRIBUTION_PACKAGE_FORMAT_OPTIONS

A list of keyword arguments that contain further options for the creation of the distribution packages.

- <code>[SYSTEM_PACKAGES_DEB]</code>: This is only relevant when using the DEB package format. 
  The option must be a string that contains the names and versions of the debian packages 
  that provide the excluded shared libraries from the CT_RUNTIME option. E.g. "libc6 (>= 2.3.1-6), libc6 (< 2.4)"
  on which the package depends.


**VERSION_COMPATIBILITY_SCHEME**

This option determines which versions of the package are can compatible to each other. This is only
of interest for shared library packages. For compatible versions it should be possible to replace
an older version with a newer one by simply replacing the library file or on linux by changing the symlink
that points to the used library. Not that it is still the developers responsibility to implement the
library in a compatible way. This option will only influence which symlinks are created, output file names
and the version.cmake files that are used to import the library.

:: note:: Currently only <code>ExactVersion</code> scheme is available, so you do not need to set this option.


Schemes

- <code>ExactVersion</code>: This option means, that different versions of the library are not compatible.
  This is the most simple scheme and relieves developers from the burdon of keeping things compatible.


**ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS**

This option can be used to enable/disable the \ref abicompliancechecker_package target.
This option is ignored on non-Linux platforms.
Setting this argument overrides the value of the global \c CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS variable for this package.


**ENABLE_ABI_API_STABILITY_CHECK_TARGETS**

This option can be used to enable/disable the enforcement of version compatibility between the current version
and the last release version. It requires option (CPF\_)ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS to be set.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS` variable for this package.


**ENABLE_CLANG_FORMAT_TARGETS**

This option can be used to enable/disable the \ref clang-format_package target.
Setting this argument overrides the value of the global \c CPF_ENABLE_CLANG_FORMAT_TARGETS variable for this package.
Enabling the clang-format target requires two dependencies.

1. Clang-format must be available in the PATH on Linux platforms.
   If you use Visual Studio 2017 or later you should choose to install clang-format in the
   Visual Studio installer.

2. You need to add the a <code>Sources/.clang-format</code> file to your project.
   This file defines the formatting rules.
   You can also add this file with the \ref cpfAddPackagesGlobalFilesArg
   argument to your project to make it visible in the Visual Studio solution. 
   Read the <a href="https://clang.llvm.org/docs/ClangFormatStyleOptions.html">clang-format documentation</a>
   to see what you have to put into that file.

**ENABLE_CLANG_TIDY_TARGET**

This option can be used to enable/disable the \ref clang-tidy_package target.
This option is ignored if the compiler is not clang.
Setting this argument overrides the value of the global \c CPF_ENABLE_CLANG_TIDY_TARGET variable for this package.


**ENABLE_OPENCPPCOVERAGE_TARGET**

This option can be used to enable/disable the \ref opencppcoverage_package target.
This option is ignored on non-Windows platforms.
Setting this argument overrides the value of the global \c CPF_ENABLE_OPENCPPCOVERAGE_TARGET variable for this package.


**ENABLE_PACKAGE_DOX_FILE_GENERATION**

If this option is given, the package will generate a standard package documentation .dox file.
The file contains the brief and long package description as well as some links to other generated
html content like test-coverage reports or abi-compatibility reports.
Setting this argument overrides the value of the global \c CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION variable for this package.


**ENABLE_PRECOMPILED_HEADER**
This option can be used to enable/disable the use of pre-compiled headers for the packages
binary targets. Using the this option requires the cotire dependency.
Setting this argument overrides the value of the global \c CPF_ENABLE_PRECOMPILED_HEADER variable for this package.


**ENABLE_RUN_TESTS_TARGET**

This option can be used to enable/disable the \ref runAllTests_package and \ref runFastTests_package
targets. The option is ignored if the package does not have a test executable.
Setting this argument overrides the value of the global \c CPF_ENABLE_RUN_TESTS_TARGET variable for this package.


**ENABLE_VALGRIND_TARGET**

This option can be used to enable/disable the \ref valgrind_package target.
The option is ignored when not compiling with gcc and debug information.
Setting this argument overrides the value of the global \c CPF_ENABLE_VALGRIND_TARGET variable for this package.


**ENABLE_VERSION_RC_FILE_GENERATION**

By default the CPF generates a version.rc file for MSVC that is used
to inject some version information into the binary files. If this
version.rc file does not fit your needs, you can disable it's generation
with this option and provide your custom made .rc file.
Setting this argument overrides the value of the global \c CPF_ENABLE_VERSION_RC_FILE_GENERATION variable for this package.


Example
"""""""

Here is an example of an \c CMakeLists.txt file for a library package.

.. code-block:: cmake

  # MyLib/CMakeLists.txt

  include(cpfAddCppPackage)
  include(cpfConstants)

  set( PACKAGE_NAMESPACE myl )

  set( briefDescription "My awsome library." )

  set( longDescription 
  "Here you can go on in length about how awsome your library is."
  )

  cpfInitPackageProject(
	  PACKAGE_NAME
	  ${PACKAGE_NAMESPACE}
  )

  ######################################### Define package files ######################################################
  set( PACKAGE_PUBLIC_HEADERS
	  MyFunction.h
  )

  set( PACKAGE_PRODUCTION_FILES
	  MyFunction.cpp
      MyPrivateFunction.h
      MyPrivateFunction.cpp
  )

  set( PACKAGE_FIXTURE_FILES
	  TestFixtures/MyFunction_fixtures.cpp
      TestFixtures/MyFunction_fixtures.h
  )

  set( PACKAGE_TEST_FILES
	  Tests/MyFunction_tests.cpp
  )

  set(PACKAGE_LINKED_LIBRARIES
      Qt5::Core
      Qt5::Gui
  )

  set(PACKAGE_LINKED_TEST_LIBRARIES
	  GMock::gmock
  )

  set( qtPlatformPlugins 
	  PLUGIN_DIRECTORY 	platforms
	  PLUGIN_TARGETS		Qt5::QWindowsIntegrationPlugin Qt5::QXcbIntegrationPlugin
  )

  set( myPlugin 
	  PLUGIN_DIRECTORY 	plugins
	  PLUGIN_TARGETS		MyPlugin
  )

  set( archiveDevPackageOptions
	  DISTRIBUTION_PACKAGE_CONTENT_TYPE 	CT_DEVELOPER
	  DISTRIBUTION_PACKAGE_FORMATS 		7Z
  )

  set( archiveUserPackageOptions
	  DISTRIBUTION_PACKAGE_CONTENT_TYPE 	CT_RUNTIME
	  DISTRIBUTION_PACKAGE_FORMATS 		ZIP
  )

  set( debianPackageOptions
	  DISTRIBUTION_PACKAGE_CONTENT_TYPE	CT_RUNTIME Qt5::Core Qt5::Test Qt5::Gui_GL Qt5::QXcbIntegrationPlugin
	  DISTRIBUTION_PACKAGE_FORMATS 		DEB
	  DISTRIBUTION_PACKAGE_FORMAT_OPTIONS SYSTEM_PACKAGES_DEB "libqt5core5a, libqt5gui5" 
  )

  ############################################## Add Package ###################################################
  cpfAddCppPackage( 
	  PACKAGE_NAME			${PACKAGE_NAME}
	  PACKAGE_NAMESPACE		${PACKAGE_NAMESPACE}
	  WEBPAGE_URL				"http://www.awsomelib.com/index.html"
	  MAINTAINER_EMAIL		"hans@awsomelib.com"
	  TYPE					LIB
	  BRIEF_DESCRIPTION		${briefDescription}
	  LONG_DESCRIPTION		${longDescription}
      PUBLIC_HEADER           ${PACKAGE_PUBLIC_HEADERS}
	  PRODUCTION_FILES		${PACKAGE_PRODUCTION_FILES}
	  FIXTURE_FILES			${PACKAGE_FIXTURE_FILES}
	  TEST_FILES				${PACKAGE_TEST_FILES}
	  LINKED_LIBRARIES		${PACKAGE_LINKED_LIBRARIES}
	  LINKED_TEST_LIBRARIES	${PACKAGE_LINKED_TEST_LIBRARIES}
	  PLUGIN_DEPENDENCIES		${qtPlatformPlugins}
      PLUGIN_DEPENDENCIES		${myPlugin}
	  DISTRIBUTION_PACKAGES 	${archiveDevPackageOptions}
	  DISTRIBUTION_PACKAGES 	${archiveUserPackageOptions}
	  DISTRIBUTION_PACKAGES 	${debianPackageOptions}
  )


.. _cpfQt5AddUIAndQrcFiles:

cpfQt5AddUIAndQrcFiles()
^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfQt5AddUIAndQrcFiles( sources )


Parameter \c sources must be passed by name. The function calls
the \c qt5_wrap_ui() and \c qt5_add_resources() for all files
in the given source files that have the \c .ui or \c .qrc file extension.
It adds the generated files to the list. It may be necessary to call this
function when Qt is used in combination with pre-compiled headers. See \ref CotireQtIncompatibility

The function can be used like this before calling \ref cpfAddCppPackage.

.. code-block:: cmake

  # CMakeLists.txt

  set(CMAKE_AUTOMOC ON)
  set(CMAKE_AUTOUIC OFF)
  set(CMAKE_AUTORCC OFF)

  set( sources
      ...
      myui.ui
      myresources.qrc
      ...
  )

  cpfQt5AddUIAndQrcFiles( sources )

  cpfAddCppPackage( 
      ...
      PRODUCTION_FILES ${sources}
      ...
  )


Module cpfAddFilePackage.cmake
------------------------------

This module provides the following function.

- cpfAddFilePackage()


cpfAddFilePackage()
^^^^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfAddFilePackage(
      SOURCES file1 ...    
  )


This function creates a target that does nothing, but is only used as a file container.
This makes sure that the files are included in a Visual Studio solution. 

Arguments
"""""""""

**SOURCES**

A list of files that are added to the package. The paths must be relative to the
current source directory or absolute.


Module cpfAddDoxygenPackage.cmake
---------------------------------

This module provides the following function.

- cpfAddDoxygenPackage()


cpfAddDoxygenPackage()
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfAddFilePackage(
      [PROJECT_NAME name]
      DOXYGEN_CONFIG_FILE absPath
      DOXYGEN_LAYOUT_FILE absPath
      DOXYGEN_STYLESHEET_FILE absPath
      [SOURCES relPath1 [relPath2 ... ]]
      [ADDITIONAL_PACKAGES externalPackage1 [externalPackage2 ...]]
      [HTML_HEADER absPath]
      [HTML_FOOTER absPath]
      [PROJECT_LOGO absPath]
      [PLANTUML_JAR_PATH absPath]
      [RUN_DOXYINDEXER]
  )


This function adds a package that runs the doxygen documentation generator on the owned packages of your CI-project.
The package can also contain extra files containing global documentation that does not belong to
any other package.

All files specified with the key-word arguments are added to the targets source files.

More information about the documentation generation can be found on the page \ref CPFDocumentationGeneration and in the 
\ref CPFAddDoxygenPackage "tutorial".

Arguments
"""""""""

**PROJECT_NAME**

The value of this argument is the name that appears in the header of the doxygen
documentation. This is set to the name of the CI-project if no value is specified.
Note that this overrides the value of the \c PROJECT_NAME variable in the 
\c DOXYGEN_CONFIG_FILE.

**DOXYGEN_CONFIG_FILE**

This must be set to the absolute path of the Doxygen configuration file. You should be aware that the file
is not directly passed to Doxygen. In order to inject the values of CMake variables into the Doxygen configuration,
the file is used as a template to generate the file <code>Generated/\<config\>/_CPF/documentation/tempDoxygenConfig.txt</code>.
This generated file is the one that is used as the input for the call of Doxygen. After building the new package for the first
time you can open the file and see that it overwrites some values of the configuration variables at the bottom of the file.

The following variables in the configuration file are overwritten.
Changing them in the given template will have no effect.

.. code-block:: cmake

  PROJECT_NAME                (set to the value of the PROJECT_NAME option)
  OUTPUT_DIRECTORY            (set to "Generated/<config>/html/doxygen")
  HTML_OUTPUT                 (set to "html")
  INPUT                       (set to Sources and the directories with the generated package documentation dox files)
  EXCLUDE                     (set to the external packages source directories that are not listed in ADDITIONAL_PACKAGES)
  DOTFILE_DIRS                (set to "Generated/<config>/html/doxygen/external")
  LAYOUT_FILE                 (set to the path of the DOXYGEN_LAYOUT_FILE option)
  GENERATE_HTML               (set to YES)
  HTML_EXTRA_STYLESHEET       (set to the path of the DOXYGEN_STYLESHEET_FILE option)
  HTML_HEADER                 (only if HTML_HEADER option is set)
  HTML_FOOTER                 (only if HTML_FOOTER option is set)
  PROJECT_LOGO                (only if PROJECT_LOGO option is set)
  PLANTUML_JAR_PATH           (only if PLANTUML_JAR_PATH option is set)
  SEARCHDATA_FILE             (set to "searchdata.xml")



**DOXYGEN_LAYOUT_FILE**

Absolute path to the used DoxygenLayout.xml file.

**DOXYGEN_STYLESHEET_FILE**

Absolute path to the used DoxygenStylesheet.css file.

**SOURCES**

Additional files that will be parsed by doxygen and that can contain global documentation.

**ADDITIONAL_PACKAGES**

Packages that are not owned by this ci-project, but should also be parsed by doxygen in order
to add them to the documentation.

**HTML_HEADER**

The header.html file used by doxygen.

**HTML_FOOTER**

The footer.html file used by doxygen.

**PROJECT_LOGO**

An .svg or .png file that is copied to the doxygen output directory and can then be used
in the documentation.

**PLANT_UML_JAR**

The absolute path to the plantuml.jar which doxygen uses to generate UML-diagramms from
<a href="http://plantuml.com/">PlantUML</a> code in doxygen comments. 
Setting this enables you to use Doxygen's <code>startuml</code> command.


**RUN_DOXYINDEXER**

This option can be added to also run the doxyindexer tool to generate the \c searchdata.db
directory that is required when using the server-side search feature of doxygen.
The directory will be created in the <code>Generated/\<config\>/html/cgi-bin</code> directory.


Module cpfAddSphinxPackage.cmake
--------------------------------

This module provides the following function.

- cpfAddSphinxPackage()

cpfAddSphinxPackage()
^^^^^^^^^^^^^^^^^^^^^

.. code-block:: cmake

  cpfAddSphinxPackage(
      [CONFIG_FILE_DIR]               dir
      [OTHER_FILES]                   file1 ...
      [ADDITIONAL_SPHINX_ARGUMENTS]   arg1 val1 arg2 val2 ...
  )


This function creates a target that runs the python based sphinx documentation generator
using a given configuration file.

Arguments
"""""""""

**CONFIG_FILE_DIR**

A relative path to the directory that holds the <code>conf.py</code> file that configures your
sphinx project. When not given, the source directory of the package is used.

**OTHER_FILES**

All other files that belong to the documentation package.

**ADDITIONAL_SPHINX_ARGUMENTS**

A list of command line arguments that are passed on to the sphinx tool.
