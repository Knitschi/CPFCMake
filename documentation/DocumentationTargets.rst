
.. _DocumentationGeneration:

Documentation generation
========================

The Doxygen Package
-------------------

Currently the CPF provides the \ref cpfAddDoxygenPackage function to integrate <a href="http://www.stack.nl/~dimitri/doxygen/download.html">Doxygen</a>
based documentation generation into the CI-pipeline. Adding a doxygen package-component adds a custom
target that runs doxygen with all the owned packages as input.

Searching
---------

The search functionality is configured to use the server-side search approach as described <a href="http://www.stack.nl/~dimitri/doxygen/manual/extsearch.html">here</a>.
To make it work these points must be implemented.

- The \c DoxygenConfig.txt must contain the correct value for the \c SEARCHENGINE_URL key. This means that the url of the \c doxysearch.cgi file must be
  known and accessible <b>before</b> generating the documentation. When the url of the documentation web-server changes, this value must be changed too.
  One can test if the cgi script works by entering \c http://feldrechengeraet/cgi-bin/doxysearch.cgi?test. This should return <tt>test succesfull</tt>.
  The file \c search/search.js in the doxygen directory should also contain a correct linkt to the \c doxysearch.cgi file.
- The web-server needs access to the right \c doxysearch.cgi file which is provided by Doxygen. The \c doxysearch.cgi file must come
  from the same version of doxygen that is used to generate the html files and the \c doxysearch.db search database.
- The webserver must be configured to use cgi scripts, which is done by providing the serve-cgi-bin.conf file with the docker-image of the webserver.
  The Dockerfile makes sure the file is copied into the container.
- The help generation needs to execute the \c doxyindexer.exe to create the \c doxysearch.db serach-index for the \c doxysearch.cgi.
- The generated files must be copied to the documentation server container with the command

.. code-block:: bash

  docker cp /var/lib/jenkins/www/html docserver:/var/www



Adding a dependency graph
-------------------------

CMake allows to generate a dependency graph for the packages in a CI-project.
This dependency graph can be integrated into your doxygen documentation. The doxygen target
will also create a second *transitive reduced* version of the dependency graph.
The transitive reduced graph does not show direct dependencies when an indirect dependency exists. 
This resulst in a cleaner graph, which may sometimes be favoured to the complete graph.

These graphs can be added to the documentation by adding the lines

.. code-block:: rst

  .. graphviz:: CPFDependencies.dot The projects dependency graph
  .. graphviz:: CPFDependenciesTransitiveReduced.dot The projects transitive reduced target dependency graph


to one of your doxygen comments. 
