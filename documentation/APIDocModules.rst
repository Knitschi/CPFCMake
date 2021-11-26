
.. _ApiDocModules:

###########
API Modules
###########

This page holds the documentation of the *CMake* functions that are provided to the
users of the *CPFCMake* package.


*****************
Argument Notation
*****************

Here are some examples to explain how the function argument notation must be interpreted.

- :code:`PACKAGE_NAMESPACE string`: The function expects the required key-word :code:`PACKAGE_NAMESPACE` to be followed by a single string.
- :code:`[PUBLIC_HEADER file1 [file2 ...]]`: The function expects the optional key-word :code:`PUBLIC_HEADER` followed by one
  or more paths to source files. If not otherwise specified, paths must be absolute or relative to :code:`CMAKE_CURRENT_SOURCE_DIR`.
- :code:`[ENABLE_CLANG_TIDY_TARGET bool]`: The function expects the optional key-word :code:`ENABLE_CLANG_TIDY_TARGET` followed by
  either :code:`TRUE` or :code:`FALSE`.
- :code:`DISTRIBUTION_PACKAGE_FORMATS <7Z|TBZ2|TGZ ...>`: The function expects the required key-word :code:`DISTRIBUTION_PACKAGE_FORMATS` to be followed by
  one or multiple values of the listed enum :code:`7Z`, :code:`TBZ2` and :code:`TGZ`.


Argument Sub-Lists
==================

Example:

.. code-block:: cmake

  [PLUGIN_DEPENDENCIES 
      PLUGIN_DIRECTORY dir
      PLUGIN_TARGETS target1 [target2 ...]
  [list2 ...]]


Some options are complex enough to require sub-lists of key-word value pairs.
In this example :code:`PLUGIN_DEPENDENCIES` separates multiple sub-lists for plugin definitions.
In a function call this could look like this:

.. code-block:: cmake

  cpfAddCppPackageComponent(
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


********************
Module cpfInit.cmake
********************

This must be included at the top of your root CMakeLists.txt file. 

- It adds all CPF modules to the :code:`CMAKE_MODULE_PATH` allows including them with their short filenames only.
- It sets the global variable :code:`CPF_MINIMUM_CMAKE_VERSION` and checks that the currently run CMake version meets the requirement.
- Sets the CMake policies that are required for CPF projects.
- It includes further CPF modules that are needed in the root CMakeLists.txt file.


***************************
Module cpfAddPackages.cmake
***************************

This module provides the following function.

-  cpfAddPackages()


.. _cpfAddPackages:

cpfAddPackages()
================

.. code-block:: cmake

  cpfAddPackages(
      [GLOBAL_FILES file1 [file2 ...]] 
  )


The function is called in all CPF CI-projects.

- This calls :code:`add_subdirectory()` for all the packages that are defined in the :code:`package.cmake`
  file. 
- This adds the global custom targets. \see GlobalTargets
- Initiates some global variables.

Arguments
---------

.. _GLOBAL_FILES:

GLOBAL_FILES
^^^^^^^^^^^^

This option can be used to add further files to the :ref:`pipeline` target.
This can be useful to make global files like a :code:`README.md`  or :code:`LICENSE.txt` visible
in a Visual Studio solution.



*********************************
Module cpfPackageProject.cmake
*********************************

This module provides the following function.

- cpfPackageProject()
- cpfFinalizePackageProject()


.. _cpfPackageProject:

cpfPackageProject()
===================

.. code-block:: cmake

  cpfPackageProject(
      COMPONENTS component_subdir1 component_subdir2 ...
      TARGET_NAMESPACE string
      [BRIEF_DESCRIPTION string]
      [LONG_DESCRIPTION string]
      [OWNER string]
      [WEBPAGE_URL string]
      [MAINTAINER_EMAIL string]
      [LANGUAGES language1 language2 ...]
      [DISTRIBUTION_PACKAGES
          DISTRIBUTION_PACKAGE_CONTENT_TYPE <CT_RUNTIME|CT_RUNTIME_PORTABLE excludedTargets|CT_DEVELOPER|CT_SOURCES|CT_DOCUMENTATION>
          DISTRIBUTION_PACKAGE_FORMATS <7Z|TBZ2|TGZ|TXZ|TZ|ZIP|DEB ...>
          [DISTRIBUTION_PACKAGE_FORMAT_OPTIONS 
              [SYSTEM_PACKAGES_DEB packageListString ]
          ]
          [DISTRIBUTION_PACKAGE_CONTENT_TYPE ...] 
      ...]
      [VERSION_COMPATIBILITY_SCHEME [ExactVersion] ]
  )


This macro is called at the beginning of a cpf-packages *CMakeLists.txt* file.
This function calls the :code:`project()` function to create the package-level project.
It automatically reads the version number of the package from the packages
git repository or a provided version file and uses it to initiated the cmake
variables :code:`PROJECT_VERSION` and :code:`PROJECT_VERSION_<digit>` variables.


.. _cpfPackageProject_arguments:

Arguments
---------

LANGUAGES
^^^^^^^^^

The value of this argument is passed on to the underlying :code:`project()` call.
It determines for which compilers cmake will look. When the argument is not given,
the default value :code:`CXX C` is used.

.. seealso::

  :ref:`CIProjectAndPackageProjects`


TARGET_NAMESPACE
^^^^^^^^^^^^^^^^^

As a namespace for the packages cmake target names.
When clients of your package import your targets they will have to use that namespace like this:

.. code-block:: cmake

    find_package(YourPackage COMPONENTS YourLib)

    add_executable(TheirExe)
    target_link_libraries(TheirExe yourTargetNamespace::YourLib)

It is also reccomended that you use this internally as well because it makes your
cmake code ignorant to the fact if a target is imported or *inlined*.



OWNER
^^^^^

The value is only used when compiling with MSVC. It is than used in the copyright notice 
that is displayed on the *Details* tab of the file-properties window of the generated binary
files. 

If you plan to allow using a package as :code:`EXTERNAL` package in some other CI-project,
you have to hard-code this value in the packages CMakeLists file. Using a variable from the
CI-project in order to remove duplication between your packages will not work, because clients
will not have the value of that variable.


WEBPAGE_URL
^^^^^^^^^^^

A web address from where the source-code and/or the documentation of the package can be obtained.
This is required for Debian packages.

If you plan to allow using a package as :code:`EXTERNAL` package in some other CI-project,
you have to hard-code this value in the packages CMakeLists file. Using a variable from the
CI-project in order to remove duplication between your packages will not work, because clients
will not have the value of that variable.


MAINTAINER_EMAIL
^^^^^^^^^^^^^^^^

An email address under which the maintainers of the package can be reached.
This is required for Debian packages.
Setting this argument overrides the value of the global :code:`CPF_MAINTAINER_EMAIL` variable for this package.

If you plan to allow using a package as :code:`EXTERNAL` package in some other CI-project,
you have to hard-code this value in the packages CMakeLists file. Using a variable from the
CI-project in order to remove duplication between your packages will not work, because clients
will not have the value of that variable.


DISTRIBUTION_PACKAGES
^^^^^^^^^^^^^^^^^^^^^

This keyword opens a sub-list of arguments that are used to specify a list of packages that have the same content, but different formats.
The argument can be given multiple times, in order to define a variety of package formats and content types.
The argument takes two lists as sub-arguments. A distribution package is created for each combination of the
elements in the sub-argument lists.
For example: 
argument :code:`DISTRIBUTION_PACKAGES DISTRIBUTION_PACKAGE_CONTENT_TYPE CT_RUNTIME_PORTABLE DISTRIBUTION_PACKAGE_FORMATS ZIP;7Z`
will cause the creation of a zip and a 7z archive that both contain the packages executables and all depended on shared libraries.
Adding another argument :code:`DISTRIBUTION_PACKAGES DISTRIBUTION_PACKAGE_CONTENT_TYPE CT_RUNTIME DISTRIBUTION_PACKAGE_FORMATS DEB`
will cause the additional creation of a debian package that relies on external dependencies being provided by other packages.

**Sub-Options:**

DISTRIBUTION_PACKAGE_CONTENT_TYPE 
"""""""""""""""""""""""""""""""""               

- :code:`CT_RUNTIME`: The distribution-package contains the executables and shared libraries that are produced by this package.
  This can be used for packages that either do not depend on any shared libraries or only on shared libraries that
  are provided externally by the system.

- :code:`CT_RUNTIME_PORTABLE listExcludedTargets`: The distribution-package will include the packages executables 
  and shared libraries and all depended on shared libraries. This is useful for creating *portable* packages
  that do not rely on any system provided shared libraries.
  The :code:`CT_RUNTIME_PORTABLE` keyword can be followed by a list of depended on targets that belong
  to shared libraries that should not be included in the package, because they are provided by the system. 

- :code:`CT_DEVELOPER`: The distribution-package will include all package binaries, header files and cmake config files for 
  importing the package in another project. This content type is supposed to be used for binary library packages
  that are used in other projects. Note that for msvc debug configurations the package will also include source files
  to allow debugging into the package. The package does not include dependencies which are supposed to be imported
  separately by consuming projects.

- :code:`CT_SOURCES`: The distribution-package contains the files that are needed to compile the package.


DISTRIBUTION_PACKAGE_FORMATS
""""""""""""""""""""""""""""

- :code:`7Z |TBZ2 | TGZ | TXZ | TZ | ZIP`: Packs the distributed files into one of the following archive formats: .7z, .tar.bz2, .tar.gz, .tar.xz, tar.Z, .zip
- :code:`DEB`: Creates a debian package .deb file. This will only be created when the dpkg tool is available.

DISTRIBUTION_PACKAGE_FORMAT_OPTIONS
"""""""""""""""""""""""""""""""""""

A list of keyword arguments that contain further options for the creation of the distribution packages.

- :code:`[SYSTEM_PACKAGES_DEB]`: This is only relevant when using the DEB package format. 
  The option must be a string that contains the names and versions of the debian packages 
  that provide the excluded shared libraries from the :code:`CT_RUNTIME` option. E.g. :code:`libc6 (>= 2.3.1-6), libc6 (< 2.4)`
  on which the package depends.


VERSION_COMPATIBILITY_SCHEME
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This option determines which versions of the package are can compatible to each other. This is only
of interest for shared library packages. For compatible versions it should be possible to replace
an older version with a newer one by simply replacing the library file or on linux by changing the symlink
that points to the used library. Not that it is still the developers responsibility to implement the
library in a compatible way. This option will only influence which symlinks are created, output file names
and the version.cmake files that are used to import the library.

.. note:: 

  Currently only :code:`ExactVersion` scheme is available, so you do not need to set this option.


**Schemes:**

- :code:`ExactVersion`: This option means, that different versions of the library are not compatible.
  This is the most simple scheme and relieves developers from the burdon of keeping things compatible.


.. _cpfFinalizePackageProject:

cpfFinalizePackageProject()
===========================

In single component packages this must be called after adding the component.
It will create some custom targets that are required for installing and creating distribution packages.


**************************************
Module cpfAddCppPackageComponent.cmake
**************************************

This module provides the following functions.


- `cpfAddCppPackageComponent()`_
- :ref:`cpfQt5AddUIAndQrcFiles`


.. _cpfAddCppPackageComponent:

cpfAddCppPackageComponent()
===========================

.. code-block:: cmake

  cpfAddCppPackageComponent(
      TYPE <GUI_APP|CONSOLE_APP|LIB|INTERFACE_LIB>
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
      [TEST_EXE_ARGUMENTS arg1 [arg2 ...]]
      [HAS_GOOGLE_TEST_EXE bool]
  )


Adds a C++ package-component to a CPF project. The name of the package-component is the same as the
name of the directory in which the package-components CMakeLists.txt file is located.
The function provides a large list of options that allow defining the features that the package-component should provide.

A C++ package-component consists of a main binary target that has the same name as the package-component and some helper binary targets for tests and test utilities.
The names of the created targets are:

.. code-block:: none

  # Binary Targets of MyPackage
  MyComponent             # The executable or library
  libMyComponent          # The implementation library.
  MyComponent_fixtures    # A library for test test utility code.
  MyComponent_tests       # A text executabl.

  # Alias Targets of MyComponent with TARGET_NAMESPACE mypckg
  mypckg::MyComponent
  mypckg::libMyComponent
  mypckg::MyComponent_fixtures
  mypckg::MyComponent_tests


The function will create alias targets for all binary targets that have the package namespace prepended.
It is recommended to use the alias names in other packages, which enables to smoothly switch between inlined
and imported packages.

Providing the function with optional arguments will switch on more of CPF's functionality like test-targets, code-analysis, packaging or
documentation generation.

.. seealso::

  :ref:`customtargets`

Example
-------

Here is an example that uses :code:`cpfAddCppPackageComponent()` in a :code:`CMakeLists.txt` file to create C++ library package.

.. code-block:: cmake

  # MyLib/CMakeLists.txt

  include(cpfAddCppPackageComponent)
  include(cpfConstants)

  cpfPackageProject(
      TARGET_NAMESPACE                      myl
      BRIEF_DESCRIPTION                     "My awsome library."
      LONG_DESCRIPTION                      "Here you can go on in length about how awsome your library is."
      WEBPAGE_URL                           "http://www.awsomelib.com/index.html"
      MAINTAINER_EMAIL                      "hans@awsomelib.com"
      COMPONENTS                            SINGLE_COMPONENT
      DISTRIBUTION_PACKAGES
        DISTRIBUTION_PACKAGE_CONTENT_TYPE 	CT_DEVELOPER
        DISTRIBUTION_PACKAGE_FORMATS 		7Z
      DISTRIBUTION_PACKAGES
        DISTRIBUTION_PACKAGE_CONTENT_TYPE 	CT_RUNTIME
        DISTRIBUTION_PACKAGE_FORMATS 		ZIP
      DISTRIBUTION_PACKAGES
        DISTRIBUTION_PACKAGE_CONTENT_TYPE   CT_RUNTIME Qt5::Core Qt5::Test Qt5::Gui_GL Qt5::QXcbIntegrationPlugin
        DISTRIBUTION_PACKAGE_FORMATS DEB
        DISTRIBUTION_PACKAGE_FORMAT_OPTIONS SYSTEM_PACKAGES_DEB "libqt5core5a, libqt5gui5" 
  )

  ################# Define package-component files #################
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

  ################# Add Package #################
  cpfAddCppPackageComponent( 
      TYPE                    LIB
      PUBLIC_HEADER           ${PACKAGE_PUBLIC_HEADERS}
      PRODUCTION_FILES        ${PACKAGE_PRODUCTION_FILES}
      FIXTURE_FILES           ${PACKAGE_FIXTURE_FILES}
      TEST_FILES              ${PACKAGE_TEST_FILES}
      LINKED_LIBRARIES        ${PACKAGE_LINKED_LIBRARIES}
      LINKED_TEST_LIBRARIES   ${PACKAGE_LINKED_TEST_LIBRARIES}
      PLUGIN_DEPENDENCIES     ${qtPlatformPlugins}
      PLUGIN_DEPENDENCIES     ${myPlugin}
  )

  cpfFinalizePackageProject()


.. _cpfAddCppPackageComponent_arguments:

Arguments
---------

TYPE
^^^^

The type of the main binary target of the package.

- :code:`GUI_APP` = Executable with switched of console. Use this for Qt applications with GUI; 
- :code:`CONSOLE_APP` = Console application; 
- :code:`LIB` = Library
- :code:`INTERFACE_LIB` = Header only library


BRIEF_DESCRIPTION
^^^^^^^^^^^^^^^^^

A short description in one sentence about what the package-component does. This is included
in the generated documentation page of the package-component and in some distribution package
types. It is also displayed on the *Details* tab of the file-properties window of 
the generated main binary file when compiling with MSVC.


LONG_DESCRIPTION
^^^^^^^^^^^^^^^^

A longer description of the package. This is included
in the generated documentation page of the package-component and in some distribution package
types.


PUBLIC_HEADER
^^^^^^^^^^^^^

All header files that declare functions or classes that are supposed to be
used by consumers of a library package. The public headers will automatically
be put into binary distribution packages, while header files in the :code:`PRODUCTION_FILES`
are not included.


PRODUCTION_FILES
^^^^^^^^^^^^^^^^

All files that belong to the production target. If the target is an executable, 
there should be a :code:`main.cpp` that is used for the executable.


PRODUCTION_FILES
^^^^^^^^^^^^^^^^

For package-components of type :code:`GUI_APP` or :code:`CONSOLE_APP`, this variable that must be
added to the executable itself. On windows this can be :code:`.rc` files or the
icon for the executable.


PUBLIC_FIXTURE_HEADER
^^^^^^^^^^^^^^^^^^^^^

All header files in the fixture library that are required by external clients of the library.
If the fixture library is only used by this package, this can be empty.


FIXTURE_FILES
^^^^^^^^^^^^^

All files that belong to the test fixtures target.


TEST_FILES
^^^^^^^^^^

All files that belong to the test executable target.


COMPILE_OPTIONS
^^^^^^^^^^^^^^^

The values of this argument are simply piped through to a call of the CMake function 
`target_compile_options()`_ for each generated binary target. 
For further information about the possible values refer to the CMake documentation.


LINKED_LIBRARIES
^^^^^^^^^^^^^^^^

The names of the library targets that are linked to the main binary target.
Just like in CMakes `target_link_libraries()`_ function you can use the 
:code:`PUBLIC`, :code:`PRIVATE` and :code:`INTERFACE` keywords.


LINKED_TEST_LIBRARIES
^^^^^^^^^^^^^^^^^^^^^

The names of the library targets that are linked to the test fixture library
and the test executable. Use this to specify dependencies of the test targets
that are not needed in the production code, like fixture libraries from other
packages.


PLUGIN_DEPENDENCIES
^^^^^^^^^^^^^^^^^^^

This keyword opens a sub-list of arguments that are used to define plugin dependencies of the package. 
Multiple :code:`PLUGIN_DEPENDENCIES` sub-lists can be given to allow having multiple plugin subdirectories.

The plugin targets are shared libraries that are explicitly loaded by the package-components executables and on which the
package has no link dependency. If a target in the list does not exist when the function is called,
it will be silently ignored. If a given target is an internal target, an artificial dependency between
the plugin target and the package-components executables is created to make sure the plugin is compilation is up-to-date before the
executable is build.

Adding this options makes sure that the plugin library is build before the executable and copied besides it
in the :code:`PLUGIN_DIRECTORY`.

**Sub-Options:**

:code:`PLUGIN_DIRECTORY`: A directory relative to the package's executables in which the plugin libraries
must be deployed so they are found by the executable. This if often a :code:`plugins` directory.

:code:`PLUGIN_TARGETS`: The name of the targets that provide the plugin libraries.


ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the :ref:`abicompliancechecker_package` target.
This option is ignored on non-Linux platforms.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS` variable for this package.


ENABLE_ABI_API_STABILITY_CHECK_TARGETS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the enforcement of version compatibility between the current version
and the last release version. It requires option :code:`ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS` to be set.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS` variable for this package.


ENABLE_CLANG_FORMAT_TARGETS
^^^^^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the :ref:`clang-format_package` target.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_CLANG_FORMAT_TARGETS` variable for this package.
Enabling the clang-format target requires two dependencies.

1. Clang-format must be available in the :code:`PATH` on Linux platforms.
   If you use Visual Studio 2017 or later you should choose to install clang-format in the
   Visual Studio installer.

2. You need to add the a :code:`Sources/.clang-format` file to your project.
   This file defines the formatting rules.
   You can also add this file with the `GLOBAL_FILES`_
   argument to your project to make it visible in the Visual Studio solution. 
   Read the `clang-format`_ documentation to see what you have to put into that file.

ENABLE_CLANG_TIDY_TARGET
^^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the :ref:`clang-tidy_package` target.
This option is ignored if the compiler is not clang.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_CLANG_TIDY_TARGET` variable for this package.


ENABLE_OPENCPPCOVERAGE_TARGET
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the :ref:`opencppcoverage_package` target.
This option is ignored on non-Windows platforms.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_OPENCPPCOVERAGE_TARGET` variable for this package.


ENABLE_PACKAGE_DOX_FILE_GENERATION
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If this option is given, the package-component will generate a standard package-component documentation :code:`.dox` file.
The file contains the brief and long package-component description as well as some links to other generated
html content like test-coverage reports or abi-compatibility reports.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION` variable for this package.


ENABLE_PRECOMPILED_HEADER
^^^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the use of pre-compiled headers for the packages
binary targets. Using the this option requires the cotire dependency.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_PRECOMPILED_HEADER` variable for this package.


ENABLE_RUN_TESTS_TARGET
^^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the :ref:`runAllTests_package` and :ref:`runFastTests_package`
targets. The option is ignored if the package-component does not have a test executable.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_RUN_TESTS_TARGET` variable for this package.


ENABLE_VALGRIND_TARGET
^^^^^^^^^^^^^^^^^^^^^^

This option can be used to enable or disable the :ref:`valgrind_package` target.
The option is ignored when not compiling with gcc and debug information.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_VALGRIND_TARGET` variable for this package.


ENABLE_VERSION_RC_FILE_GENERATION
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

By default the CPF generates a version.rc file for MSVC that is used
to inject some version information into the binary files. If this
version.rc file does not fit your needs, you can disable its generation
with this option and provide your custom made :code:`.rc` file.
Setting this argument overrides the value of the global :code:`CPF_ENABLE_VERSION_RC_FILE_GENERATION` variable for this package.


TEST_EXE_ARGUMENTS
^^^^^^^^^^^^^^^^^^

This option can be used to pass a list of arguments to the test executable when building the :ref:`runAllTests_package` or :ref:`runFastTests_package` targets.
This can be usefull in cases where the test executable needs information from the build-system like a directory for test files etc.
When using the "Visual Studio" generator family, these arguments are also set to the "Debugging -> Command Arguments" option to make sure that the same arguments
are passed to the test executable during debugging.


Example
.. code-block:: none

  TEST_EXE_ARGUMENTS
    --TestWorkingDirectory "${CMAKE_BINARY_DIR}/TestFiles"
    --TestDataDirectory "${CMAKE_SOURCE_DIR}/TestData"


HAS_GOOGLE_TEST_EXE
^^^^^^^^^^^^^^^^^^^

This option only has an effect when using a Visual Studio Generator.
When this option is set to true, :code:`cpfAddCppPackageComponent()` will create an empty file :code:`<test-exe>.is_google_test` that lies beside the
create test executable. Set this option to true when you use the <a href="https://github.com/csoltenborn/GoogleTestAdapter">GoogleTestAdapter</a> 
and it fails to find your tests.



.. _cpfQt5AddUIAndQrcFiles:

cpfQt5AddUIAndQrcFiles()
========================

.. code-block:: cmake

  cpfQt5AddUIAndQrcFiles( sources )


Parameter :code:`sources` must be passed by name. The function calls
the :code:`qt5_wrap_ui()` and :code:`qt5_add_resources()` for all files
in the given source files that have the :code:`.ui` or :code:`.qrc` file extension.
It adds the generated files to the list. It may be necessary to call this
function when Qt is used in combination with pre-compiled headers. 

.. seealso::

  :ref:`CotireQtIncompatibility`

The function can be used like shown below before calling :ref:`cpfAddCppPackageComponent`.

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

  cpfAddCppPackageComponent( 
      ...
      PRODUCTION_FILES ${sources}
      ...
  )



***************************************
Module cpfAddFilePackageComponent.cmake
***************************************

This module provides the following function.

- cpfAddFilePackageComponent()


cpfAddFilePackageComponent()
============================

.. code-block:: cmake

  cpfAddFilePackageComponent(
      SOURCES file1 ...    
  )


This function creates a target that does nothing, but is only used as a file container.
This makes sure that the files are included in a Visual Studio solution. 

Arguments
---------

SOURCES
^^^^^^^

A list of files that are added to the package. The paths must be relative to the
current source directory or absolute.


******************************************
Module cpfAddDoxygenPackageComponent.cmake
******************************************

This module provides the following function.

- cpfAddDoxygenPackageComponent()


.. _cpfAddDoxygenPackageComponent:

cpfAddDoxygenPackageComponent()
===============================

.. code-block:: cmake

  cpfAddFilePackageComponent(
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


This function adds a package-component that runs the doxygen documentation generator on the owned packages of your CI-project.
The package-component can also contain extra files containing global documentation that does not belong to
any other package.

All files specified with the key-word arguments are added to the targets source files.

More information about the documentation generation can be found on the page :ref:`DocumentationGeneration` and in the 
:ref:`cpfAddDoxygenPackageComponent` tutorial.

Arguments
---------

PROJECT_NAME
^^^^^^^^^^^^

The value of this argument is the name that appears in the header of the doxygen
documentation. This is set to the name of the CI-project if no value is specified.
Note that this overrides the value of the :code:`PROJECT_NAME` variable in the 
:code:`DOXYGEN_CONFIG_FILE`.

DOXYGEN_CONFIG_FILE
^^^^^^^^^^^^^^^^^^^

This must be set to the absolute path of the Doxygen configuration file. You should be aware that the file
is not directly passed to Doxygen. In order to inject the values of CMake variables into the Doxygen configuration,
the file is used as a template to generate the file :code:`Generated/\<config\>/_CPF/documentation/tempDoxygenConfig.txt`.
This generated file is the one that is used as the input for the call of Doxygen. After building the new package-component for the first
time you can open the file and see that it overwrites some values of the configuration variables at the bottom of the file.

The following variables in the configuration file are overwritten.
Changing them in the given template will have no effect.

.. code-block:: cmake

  PROJECT_NAME                (set to the value of the PROJECT_NAME option)
  OUTPUT_DIRECTORY            (set to "Generated/<config>/html/doxygen")
  HTML_OUTPUT                 (set to "html")
  INPUT                       (set to Sources and the directories with the generated package-component documentation dox files)
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



DOXYGEN_LAYOUT_FILE
^^^^^^^^^^^^^^^^^^^

Absolute path to the used DoxygenLayout.xml file.

DOXYGEN_STYLESHEET_FILE
^^^^^^^^^^^^^^^^^^^^^^^

Absolute path to the used DoxygenStylesheet.css file.

SOURCES
^^^^^^^

Additional files that will be parsed by doxygen and that can contain global documentation.

ADDITIONAL_PACKAGES
^^^^^^^^^^^^^^^^^^^

Packages that are not owned by this ci-project, but should also be parsed by doxygen in order
to add them to the documentation.

HTML_HEADER
^^^^^^^^^^^

The header.html file used by doxygen.

HTML_FOOTER
^^^^^^^^^^^

The footer.html file used by doxygen.

PROJECT_LOGO
^^^^^^^^^^^^

An .svg or .png file that is copied to the doxygen output directory and can then be used
in the documentation.

PLANT_UML_JAR
^^^^^^^^^^^^^

The absolute path to the plantuml.jar which doxygen uses to generate UML-diagramms from
<a href="http://plantuml.com/">PlantUML</a> code in doxygen comments. 
Setting this enables you to use Doxygen's :code:`startuml` command.


RUN_DOXYINDEXER
^^^^^^^^^^^^^^^

This option can be added to also run the doxyindexer tool to generate the :code:`searchdata.db`
directory that is required when using the server-side search feature of doxygen.
The directory will be created in the :code:`Generated/\<config\>/html/cgi-bin` directory.


*****************************************
Module cpfAddSphinxPackageComponent.cmake
*****************************************

This module provides the following function.

- cpfAddSphinxPackageComponent()

cpfAddSphinxPackageComponent()
==============================

.. code-block:: cmake

  cpfAddSphinxPackageComponent(
      [SOURCE_DIR]                    absDir
      [CONFIG_FILE_DIR]               absDir
      [OTHER_FILES]                   file1 ...
      [OUTPUT_SUBDIR]                 relDir
      [ADDITIONAL_SPHINX_ARGUMENTS]   arg1 val1 arg2 val2 ...
      [SOURCE_SUFFIXES]               extension1 extension2 ...
  )


This function creates a target that runs the python based sphinx documentation generator
using a given configuration file. The source directory for sphinx is the :code:`<rootdir>/Sources`
directory.

Arguments
---------

SOURCE_DIR
^^^^^^^^^^

The base directory in which sphinx searches for files that contribute to the documentation.
When the argument is not given, :code:`CMAKE_SOURCE_DIR` is used in order to look for documentation
files in all package-components of the CI-project.

CONFIG_FILE_DIR
^^^^^^^^^^^^^^^

A relative path to the directory that holds the :code:`conf.py` file that configures your
sphinx project. When not given, the source directory of the package-component is used.

OTHER_FILES
^^^^^^^^^^^

All other files that belong to the documentation package.

OUTPUT_SUBDIR
^^^^^^^^^^^^^

This option can be used to add extra subdirectories to the o

ADDITIONAL_SPHINX_ARGUMENTS
^^^^^^^^^^^^^^^^^^^^^^^^^^^

A list of command line arguments that are passed on to the sphinx tool.

SOURCE_SUFFIX
^^^^^^^^^^^^^

This should be a list of file extensions without a leading dot. It must be set
when you use the :code:`source_suffix` variable in your sphinx config file
to enable the parsing of other file types. Getting this wrong will break the
out-of-date mechanism for the created target. This means that the build-system
may not always re-build the target after making changes to the source files.




.. External links
.. _target_compile_options(): https://cmake.org/cmake/help/latest/command/target_compile_options.html
.. _target_link_libraries(): https://cmake.org/cmake/help/latest/command/target_link_libraries.html
.. _clang-format: https://clang.llvm.org/docs/ClangFormatStyleOptions.html