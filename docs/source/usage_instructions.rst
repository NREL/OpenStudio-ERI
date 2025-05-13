Usage Instructions
==================

Setup
-----

To get started:

#. Either download `OpenStudio 3.10.0 <https://github.com/NREL/OpenStudio/releases/tag/v3.10.0>`_ and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the `latest release <https://github.com/NREL/OpenStudio-ERI/releases>`_ release.

.. note::

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

.. _running:

Running Calculations
--------------------

| Run all calculations (e.g., ERI, ENERGY STAR, etc.) on a provided sample HPXML file as follows:
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml``

Note that all simulations will be executed in parallel if there are sufficient cpus/cores available.

This will generate output as shown below:

.. image:: https://user-images.githubusercontent.com/5861765/178850875-12c90097-e1fd-48c5-888b-db4355d923e8.png

| You can also request generation of timeseries output CSV files by providing one or more timeseries flags. Some examples:
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --hourly ALL``
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --monthly fuels --monthly temperatures``

| You can also skip simulations (i.e., just generate the ERI Reference/Rated Home HPXMLs) by using, e.g.:
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --skip-simulation``

| Or you can request all output files in JSON (instead of CSV) format:
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --output-format json``

| Or you can generate a HERS diagnostic output file using, e.g.:
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --diagnostic-output``

| You can also specify the number of parallel processors to use when running simulations, e.g.:
| ``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --num-proc 2``

Run ``openstudio workflow/energy_rating_index.rb -h`` to see all available commands/arguments.

Output
------

Upon completion, results are provided in the console (stdout) as well as available in summary output files.
See the :ref:`outputs` section for a description of all available outputs.
