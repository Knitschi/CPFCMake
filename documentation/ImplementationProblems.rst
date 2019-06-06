
############################################
Problems that are encountered in Development
############################################


**********************
CMake induced Problems
**********************


CMake's add_custom_command() does not support generator expressions in the OUTPUT argument
==========================================================================================

This limitation is the reason why we have the ugly workaround where we loop over
all configurations and use the :code:`cpfAddConfigurationDependendCommand()` function.

.. seealso::

    `CMake Issue 12877`_


.. _no_dependencies_for_install_target:

It is not possible to add dependencies to the CMake generated INSTALL target
============================================================================

This prevents us from using cmake's :code:`install()` command in combination
with custom targets because we can not ensure that the custom target is build
before the :code:`install` target. As a workaround we have to implement additional
custom-targets for the installation operations.

.. seealso::

    `CMake Issue 8438`_


CMake does not support lists that have only one empty element
=============================================================

Because lists are implemented as ; separated strings and the notation
does not have the list end with a ;, it is not possible to have a list
with one empty element. This especially is a problem in algorithms which handle
lists. Our function :code:`cpf_append_list()` is used to detect this problem,
but when it occurs, there is no general solution to it.

.. seealso::

    `CMake Issue 18009`_



.. Links

.. _CMake Issue 8438: https://gitlab.kitware.com/cmake/cmake/issues/8438
.. _CMake Issue 12877: https://gitlab.kitware.com/cmake/cmake/issues/12877
.. _CMake Issue 18009: https://gitlab.kitware.com/cmake/cmake/issues/18009


