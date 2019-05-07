
.. _Versioning:

Versioning
==========

This page contains information on how the versioning problem is handled in the CPF.

Version Tags
------------

The source of a version number is the Git repository that contains the package or CI-repository. During the *generate step*, The CPF
determines the current version number of each package by reading the release version tags of the repository.
This version number is then used by the *CPF* while creating distribution packages or in the production code. 
Because of the fully automated versioning-pipeline of a CPF project, developers can rely that builds of two different
commits will never have the same version number.

\note All repositories that are used for a CPF project should have the release version tag \c 0.0.0 at one
of their first commits. The CPF requires at least one release version tag for its versioning mechanism to
work.

\see \ref PackageOwnership


Release version format
----------------------

<b>Format:</b>    &lt;major&gt;.&lt;minor&gt;.&lt;patch&gt;
<b>Examples:</b>   \c 1.0.1, \c 0.0.99

The version tags must follow the given pattern in order to be recognized by the *CPF*. 
Tags of this form are called *release versions*. The *CPF* assumes that the commits with the release versions 
are the ones that are provided to clients. Release version tags must be manually added to the repository 
when the developer deems a commit worthy to be published. This can also be done via the build-job
that is provided by the CPFMachines package.


.. _internalVersion:

Internal version format
-----------------------

<b>Format:</b>     &lt;major&gt;.&lt;minor&gt;.&lt;patch&gt;.&lt;commit-nr.&gt;-&lt;hash&gt;
<b>Examples:</b>   \c 1.0.1.13-af4d, \c 0.0.99.1-3h9k0s

In order to have different version numbers for each build, the *CPF* will determine *internal version numbers*
for each package whenever the *generate step* is executed. The first three *digits* are derived from
the latest release version number that can be *seen* from the current commit in one of its preceding
commits. The \c <commit-nr.> is the number of commit that have been made since the commit that has
the release version. This allows to see if an internal version is older or younger than another
internal version. However the commit number alone does not make the version unique, as the development
could have branched since the last release version. This could lead to two commits with the same
version number. For this reason the version number also contains the first digits of the commit hash.
This part will be as long as is needed to make it unique.


Dirty versions
--------------

If the repository has local changes that have not yet been committed, the optional \c -dirty postfix
is added to the version number. Dirty versions can in general not be rebuild by other developers
and should therefore not be considered when trying to reproduce bugs.


Using the version number in the production code
-----------------------------------------------

For C++ packages, the *CPF* will automatically generate a header file that
contains the current version number. The version can be obtained in the C++
code by using:

.. code-block:: cpp

  #include <MyPackage/cpfPackageVersion_MyPackage.h>

  std::string version = mp::getPackageVersion();


assuming that you have a package \c MyPackage with namespace \c mp.

The package version can be accessed in the \c CMakeLists.txt file of
the package via the \c PROJECT_VERSION variable after the call of the
\c cpfInitPackageProject() function if you want to generate your own
version files.


Version tags as validation stamps
---------------------------------

In the CPF the version tags in the repository are also used to mark commits for
which the pipeline target was successfully build. This is only enforced in combination
with the build-job that is provided by the CPFMachines package. The build-job adds
version tags after successfully building a commit. When this policy is followed, developers
can quickly see which commits are worth checking out when they try to build older versions.


Incrementing versions
---------------------

Version numbers are incremented by adding new release version tags to the repository.
This can either be done manually or by setting certain parameters to the build-job
that is provided by the *CPFMachines* package. The CPF assumes that release version
tags are unique and *ordered*, where smaller versions can only be followed by larger
versions. Before you manually add a release version tag, you should also make sure
that the pipeline target of that commit builds for all your supported configurations.

The build-job of the *CPFMachines* package will make sure that all of these requirements
are met, when incrementing version numbers.

\see \ref CPFJobSubsection2
