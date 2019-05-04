
CPFCMake 
========

The CPFCMake package implements a standardized C++ CMake project with additional CI functionality.
This package is the most basic component of the CMakeProjectFramework. It helps with setting
up a CMake based C++ project with extended functionality. The package tries to solve the following problems:

- Abstraction of common CMake code to a higher level. CMakeProjectFramework projects are set up by using only
  a handfull of CMake functions. This removes implementation details from the `CMakeLists.txt` files.
- Providing a standardized directory structure for a C++ project.
- Providing additional CI tasks like code-analysis or documentation-generation as custom targets.
- Package-versioning based on version tags provided by the Git repository.
- Modularisation of the code base into individual CMake packages.
- Use of cmake configuration files, which contain build configurations that outlive the deletion of the build directory and the :code:`CMakeCache.txt` file.


Index
-----

.. toctree::
  :maxdepth: 1

  APIDocModules
  APIDocGlobalVariables
  Configuration
  CustomTargets
  PackagesCMake
  TestTargets
  DistributionPackages
  DocumentationTargets
  Versioning
  KnownProblems
