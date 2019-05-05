
.. _customtargets:

Custom targets
==============

The custom targets in a CPF project
-----------------------------------

The build pipeline of a CPF project is implemented with CMake *custom-targets*. In order to execute
one of those tasks separately from the whole pipeline, one has to build that *target* with the
\ref BuildStep "3_Make.py" script. The advantage of the custom-target mechanism is, that the used build-system
handles dependency issues, rebuilding outdated targets and parallelizing task execution.

The availability of custom-targets in a CPF project depends on the projects configuration and its source files.
Most custom targets can be disabled via the configuration file. This may be helpful if a custom implementation of the
task is preferred. Some tasks require a test executable which is only created if the package has
a source file that defines the main function of a test-executable.

In some IDEs like Visual Studio or KDevelop, targets are visualized and can be directly *build*
from within the IDE. This may sometimes be preferred to building the targets from the command line.

The following sections contain lists with the names of available custom targets. 
The lists do not contain some private targets of the CPF that are only created as sub-steps of the
targets that are of interest to the user.

Global targets
^^^^^^^^^^^^^^

A CPF project contains some targets that operate on the global level.
They either execute operations that can not be done for each package
in separation or *bundle* up a certain kind of per-package targets.
In this case building the bundle target will simply build all
per-package targets of that kind.

Here is a list of targets that can exist once per CPF project.

- `abi-compliance-checker`_
- `acyclic`_
- `ALL_BUILD (Visual Studio) / all (Makefiles)`_
- `clang-format`_
- `clang-tidy`_
- `distributionPackages`_
- `globalFiles`_
- `install`_
- `opencppcoverage`_
- `pipeline`_
- `runAllTests`_
- `runFastTests`_
- `valgrind`_
- `ZERO_CHECK (Visual Studio)`_


Package targets
^^^^^^^^^^^^^^^

Here is a list of targets that can exist once per CPF package.

- :ref:`abicompliancechecker_package`
- :ref:`clang-format_package`
- :ref:`clang-tidy_package`
- :ref:`distributionPackages_package`
- :ref:`opencppcoverage_package`
- :ref:`package`
- :ref:`package_fixtures`
- :ref:`package_tests`
- :ref:`runAllTests_package`
- :ref:`runFastTests_package`
- :ref:`valgrind_package`


Private targets
^^^^^^^^^^^^^^^

Here is a list of targets that are used as implementation details for other targets.
If everything works, they should be of no further interest, but more information
about them may be of interest if you need to debug problems with the CPF.


Target annotations
^^^^^^^^^^^^^^^^^^


abi-compliance-checker
""""""""""""""""""""""

This target bundles the \ref abicompliancechecker_package targets.


acyclic
"""""""

The target checks that the projects target dependency graph is acyclic.
This target can be disabled with the \c CPF_ENABLE_ACYCLIC_TARGET variable.

.. _ALL_BUILD:

ALL_BUILD (Visual Studio) / all (Makefiles)
"""""""""""""""""""""""""""""""""""""""""""

This target builds all binary targets. Note that the name depends on the
CMake generator in use.


clang-format
""""""""""""

This target bundles the \ref clang-format_package targets.
Note that this target is not included in the pipeline target.


clang-tidy
""""""""""

This target bundles the \ref clang-tidy_package targets.

distributionPackages
""""""""""""""""""""

This target bundles the \ref distributionPackages_package targets.

globalFiles
"""""""""""

This is only a file container target that does not execute any commands.
It holds all source files that are of global scope like tool configuration
files, global documentation, etc..

install
"""""""

This CMake standard target copies all installed files to the directory specified
with CMAKE_INSTALL_PREFIX. Not that this includes runtime files, developer files,
external shared library dependencies and source files.

opencppcoverage
"""""""""""""""

This target bundles the \ref opencppcoverage_package targets. It also
combines the temporary output of the \ref opencppcoverage_package targets
into the final html report that can be found in the html output directory.

pipeline
""""""""

The top-level bundle target that will make sure that all other targets are built.

runAllTests
"""""""""""

This target bundles the \ref runAllTests_package targets.

runFastTests
""""""""""""

This target bundles the \ref runFastTests_package targets. This target is not
contained in the \ref pipeline target which always builds the \ref runAllTests target.

valgrind
""""""""

This target bundles the \ref valgrind_package targets.

ZERO_CHECK (Visual Studio)
""""""""""""""""""""""""""

A CMake default target that runs the CMake generate step. This is only available for
when using Visual Studio.

.. _abicompliancechecker_package:

abi-compliance-checker_\&lt;package\&gt;
""""""""""""""""""""""""""""""""""""""""

This is a bundle target that runs the Abi-Compliance-Checker tool. The target only exists for
project configurations that use *Gcc* with debug flags and for shared library packages.

**Report compatibility**
The basic functionality is to create html reports that compare the abi/api-compatibility of
a previous libray package version with the current one. The reporst are added to the project
web-page. To enable this, the target must be able to download previously generated distribution 
packages of that package from the project web-page, which must contain generated abi-dump files. 
This complex requirement makes the target somewhat fragile. This functionality can be 
disabled with the \c CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS config variable.

**Enforce compatibility**
You can also enable targets that will fail to build if abi or api compatibility is hurt
by your current changes. This option can be switched on in stable branches. To do so
use the \c CPF_CHECK_ABI_STABLE and \c CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS config variables.

.. _clang-format_package:

clang-format_\&lt;binary-target\&gt;
""""""""""""""""""""""""""""""""""""
This target runs clang-format on the source files of a binary target.
The targets are only created for the binary targets of *owned* packages.
The target can be enabled with the CPF\_:ref:`cpfArgEnableClangFormatTargets` variable.

.. _clang-tidy_package:

clang-tidy_\&lt;package\&gt;
""""""""""""""""""""""""""""

This target only exists when compiling on Linux with the clang compiler.
It runs the \c clang-tidy tool on the source files of the packages production
library target.

The target can be disabled with the \c CPF_ENABLE_CLANG_TIDY_TARGET config variable.

.. _distributionPackages_package:

distributionPackages_\&lt;package\&gt;
""""""""""""""""""""""""""""""""""""""

Creates all *distribution packages* of the package. A *distribution package* is a file that is
distributed to users of the package. This can be a zip file that contains the binaries or sources or 
an installer. The target is only created if the \c addPackage() function has the \c DISTRIBUTION_PACKAGES
argument set.

.. _opencppcoverage_package:

opencppcoverage_\&lt;package\&gt;
"""""""""""""""""""""""""""""""""

This target runs the test executable with OpenCppCoverage tool in order to create
an html report that shows the code lines that are hit while running the tests.
This target will only exist for project configurations that use *MSVC* and will
only run the tool when compiling in *Debug* configuration.

The target can be disabled with the \c CPF_ENABLE_OPENCPPCOVERAGE_TARGET config variable.

.. _package:

\&lt;package\&gt;
"""""""""""""""""

The main binary target of the package.


.. _package_fixtures:

\&lt;package\&gt;_fixtures
""""""""""""""""""""""""""

An additional library that can be used to share test utility code between packages.
It is only created if the \c addPackage() function has the \c FIXTURE_FILES and \c PUBLIC_FIXTURE_HEADER arguments set.


.. _package_tests:

\&lt;package\&gt;_tests
"""""""""""""""""""""""

The test executable that belongs to the package. This target is only created
if the \c addPackage() function has the \c TEST_FILES argument set. The executable
should run automated tests when executed.


.. _runAllTests_package:


runAllTests_\&lt;package\&gt;
"""""""""""""""""""""""""""""

This target runs all the tests in the \ref package_tests executable.

The target can be disabled with the \c CPF_ENABLE_RUN_TESTS_TARGET config variable.

.. _runFastTests_package:

runFastTests_\&lt;package\&gt;
""""""""""""""""""""""""""""""

This target runs all the tests in the \ref package_tests executable that have either
the word *FastFixture* or *FastTests* included in their name. It is the the users
responsibility to make sure that the tests with those names are really fast tests.

The purpose of the target is to provide a way of executing only tests that are run quickly
an which are therefor useful when working in a tight test-driven development cycle.

The target can be disabled with the \c CPF_ENABLE_RUN_TESTS_TARGET config variable.


.. _valgrind_package:

valgrind_\&lt;package\&gt;
""""""""""""""""""""""""""

This target runs the test executable with the *Valgrind* tool, which
can help to detect memory leaks or undifined behavior. The target
only exists for project configurations that use *Gcc* or *Clang* with
debug flags. When this target is enabled you must also add the empty file 
\c Other/MyPackageValgrindSuppressions.supp file to all packages.
You can use this file to suppress false positives or unfixable
issues that are found by *Valgrind*.

The target can be disabled with the \c CPF_ENABLE_VALGRIND_TARGET config variable.

