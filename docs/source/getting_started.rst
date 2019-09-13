Getting Started
===============

Here is a brief overview on getting setup, running an ERI calculation, and obtaining outputs.

Setup
-----

To get started:

#. Either download `OpenStudio 2.8.1 <https://github.com/NREL/OpenStudio/releases/tag/v2.8.1>`_ and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the `OpenStudio-ERI v0.3.0 Beta <https://github.com/NREL/OpenStudio-ERI/releases/tag/v0.3.0-beta>`_ release.
#. To obtain all available weather files, run: ``openstudio workflow/energy_rating_index.rb --download-weather``

.. note:: 

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

Running
-------

Run the ERI calculation on a provided sample HPXML file as follows:
``openstudio --no-ssl workflow/energy_rating_index.rb -x workflow/sample_files/base.xml``

Note that the Reference Home, Rated Home and Index Adjustment Home (if applicable) simulations will be executed in parallel on the local machine.

This will generate output as shown below:

.. image:: https://user-images.githubusercontent.com/5861765/63288138-3e167000-c279-11e9-9a18-b0a2327ed89d.png

Run ``openstudio workflow/energy_rating_index.rb -h`` to see all available commands/arguments.

Output
------

Upon completion, ERI is provided in the console (stdout) as well as available in some of the summary output files.
See the :ref:`outputs` section for a description of all available outputs.
