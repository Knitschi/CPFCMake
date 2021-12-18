
.. _PackagesCMake:

The packages.cmake file
=======================

The :code:`packages.cmake` file defines which sub-directories are added to CI-project. It is read when calling the
:ref:`cpfAddPackages` function. The file must define the CMake variable :code:`CPF_PACKAGES`.
The file must be located parallel to the root :code:`CMakeLists.txt` file.

The content may look something like this.

.. code-block:: cmake

  # File packages.cmake

  set(CPF_PACKAGES 
	EXTERNAL ExternalLib1
	EXTERNAL bli/blub/ExternalLib2
	OWNED Cpp/MyPackageA
	OWNED Cpp/MyPackageB
	OWNED documentation
  )


The list should contain pairs in the shape of :code:`[EXTERNAL|OWNED] <package-dir>`.
Note that the name of the lowest directory must be the same as the package name.
The order of the packages is important. The lower-level packages must be listed first to make sure
they exist when they are linked to the higher-level packages that come later in the list.
The :code:`EXTERNAL` and :code:`OWNED` keywords determine if the package belongs to this CI-project or another one.
More about package ownership can be found in the :ref:`PackageOwnership` section. 

