Getting Started
===============

Here is a brief overview on getting setup, running an ERI calculation, and obtaining outputs.

Setup
-----

To get started:

#. Either download `OpenStudio 3.2.1 <https://github.com/NREL/OpenStudio/releases/tag/v3.2.1>`_ and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the `latest release <https://github.com/NREL/OpenStudio-ERI/releases>`_ release.
#. To obtain all available weather files, run: ``openstudio workflow/energy_rating_index.rb --download-weather``

.. note:: 

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

.. _running:

Running ERI
-----------

Run the ERI calculation on a provided sample HPXML file as follows:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml``

Note that all simulations will be executed in parallel if there are sufficient cpus/cores available.

This will generate output as shown below:

.. image:: https://user-images.githubusercontent.com/5861765/82058115-8be1cc80-9681-11ea-9288-8b1eca5ec422.png

You can also request generation of timeseries output CSV files as part of the calculation by providing one or more timeseries flags (``--hourly``, ``--daily``, or ``--monthly``).

For example, to request all possible hourly outputs:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --hourly ALL``

Or for example, one or more specific monthly output types can be requested, e.g.:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --monthly fuels --monthly temperatures``

Run ``openstudio workflow/energy_rating_index.rb -h`` to see all available commands/arguments.

Running ENERGY STAR
-------------------

Run the ENERGY STAR calculation on a provided sample HPXML file as follows:
``openstudio workflow/energy_star.rb -x workflow/sample_files/base.xml``

Note that all simulations will be executed in parallel if there are sufficient cpus/cores available.

Output
------

Upon completion, results are provided in the console (stdout) as well as available in summary output files.
See the :ref:`outputs` section for a description of all available outputs.
