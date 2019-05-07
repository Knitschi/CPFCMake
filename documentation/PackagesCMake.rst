
.. _PackagesCMake:

The packages.cmake file
=======================

The \c packages.cmake file defines which sub-directories are added to CI-project. It is read when calling the
\ref cpfAddPackages function. The file must define the CMake variable \c CPF_PACKAGES.
The file must be located parallel to the root \c CMakeLists.txt file.

The content looks something like this.

.. code-block:: cmake

  # File packages.cmake

  set( CPF_PACKAGES 
	  EXTERNAL ExternalLib1
	  EXTERNAL ExternalLib2
      OWNED CPackage BUILD_SHARED_LIBS OFF ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS OFF
      OWNED EPackage BUILD_SHARED_LIBS ON
      OWNED APackage  
      OWNED documentation
  )


The list should contain some keywords and the package directories that belong to your CI-project.
The order of the packages is important. The lower-level packages must be listed first to make sure
they exist when they are linked to the higher-level packages that come later in the list.
The \c EXTERNAL and \c OWNED keywords determine if the package belongs to this CI-project or another one.
See \ref PackageOwnership. 

It is also possible to override some global variables per package. This can be used to force individual
packages to be build as static libraries or disable some of the custom targets in external packages.
Here is a list of the variables that can be overridden.

.. code-block:: cmake

  BUILD_SHARED_LIBS
  CPF_ENABLE_ABI_API_COMPATIBILITY_REPORT_TARGETS
  CPF_ENABLE_ABI_API_STABILITY_CHECK_TARGETS
  CPF_ENABLE_CLANG_TIDY_TARGET
  CPF_ENABLE_OPENCPPCOVERAGE_TARGET
  CPF_ENABLE_PACKAGE_DOX_FILE_GENERATION
  CPF_ENABLE_PRECOMPILED_HEADER
  CPF_ENABLE_RUN_TESTS_TARGET
  CPF_ENABLE_VALGRIND_TARGET
  CPF_ENABLE_VERSION_RC_FILE_GENERATION
  CPF_COMPILE_OPTIONS


