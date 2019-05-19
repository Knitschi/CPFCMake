
.. _cpfCMake:

CPFCMake 
========

The CPFCMake package implements a rich-featured and standardized C++ CMake project that offers
many tasks that are required for a continuous integration pipeline.
This package is the most basic component of the CMakeProjectFramework. 

The package tries to solve the following problems:

- Abstract common CMake code to a higher level. CMakeProjectFramework projects are set up by using only
  a handfull of CMake functions that take a lot of arguments but hide implementation details.
  This makes the code in the :code:`CMakeLists.txt` files shorter, cleaner and more descriptive.
- Providing a cannonical directory structure for a C++ project.
- Providing additional CI tasks like code-analysis or documentation-generation as custom targets.
- Package-versioning based on version tags provided by the Git repository.
- Modularisation of the code base into individual CMake packages.
- Use of cmake configuration files, which contain build configurations that outlive the deletion of the build directory and the :code:`CMakeCache.txt` file.


Index
-----

.. toctree::
  :maxdepth: 1

  ../README
  APIDocModules
  APIDocGlobalVariables
  ConfigurationManagement
  CustomTargets
  PackagesCMake
  TestTargets
  DistributionPackages
  DocumentationTargets
  Versioning
  UsageProblems
  ImplementationProblems

