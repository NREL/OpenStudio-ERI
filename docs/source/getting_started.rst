Getting Started
===============

Here is a brief overview on getting setup, running an ERI calculation, and obtaining outputs.

Setup
-----

To get started:

#. Either download OpenStudio 2.8.1-rc2 (`Windows <https://openstudio-builds.s3.amazonaws.com/2.8.1/OpenStudio-2.8.1-rc2.6914d4f590-Windows.exe>`_ | `Linux <https://openstudio-builds.s3.amazonaws.com/2.8.1/OpenStudio-2.8.1-rc2.6914d4f590-Linux.deb>`_ | `Mac <https://openstudio-builds.s3.amazonaws.com/2.8.1/OpenStudio-2.8.1-rc2.6914d4f590-Darwin.dmg>`_) and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Clone or download the `OpenStudio-ERI GitHub repository <https://github.com/NREL/OpenStudio-ERI/>`_.
#. To obtain all available weather files, run: ``openstudio workflow/energy_rating_index.rb --download-weather``

.. note:: 

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

Running
-------

Run the ERI calculation on a provided sample HPXML file as follows:
``openstudio --no-ssl workflow/energy_rating_index.rb -x workflow/sample_files/valid.xml``

Note that the Reference Home, Rated Home and Index Adjustment Home (if applicable) simulations will be executed in parallel on the local machine.

This will generate output as shown below:

.. image:: https://user-images.githubusercontent.com/5861765/46991458-4e8f1480-d0c3-11e8-8234-22ed4bb4f383.png

Run ``openstudio workflow/energy_rating_index.rb -h`` to see all available commands/arguments.

Outputs
-------

Upon completion, multiple outputs are currently available:

* Summary ``ERI_Results.csv`` and ``ERI_Worksheet.csv`` files
* Summary annual energy consumption by fuel type and/or end use
* Reference/Rated/IndexAdjustment Home HPXML files (transformations of the input HPXML file as a result of applying the ERI 301 ruleset)
* EnergyPlus input/output files

See the `sample_results <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results>`_ directory for examples of these outputs.
