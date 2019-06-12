Quick Start
===========

Here is a brief overview on getting setup, running an ERI calculation, and obtaining outputs.

Setup
-----

To get started:

#. Either download `OpenStudio 2.8.0 <https://github.com/NREL/OpenStudio/releases/tag/v2.8.0>`_ (at a minimum, install the Command Line Interface and EnergyPlus components) or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Clone or download the GitHub repository's source code.
#. To obtain all available weather files, run: ``openstudio workflow/energy_rating_index.rb --download-weather``

The OpenStudio-ERI workflow can be run on Linux, Mac, or Windows systems.

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
