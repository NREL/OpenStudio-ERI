Usage Instructions
==================

Setup
-----

To get started:

#. Either download `OpenStudio 3.4.0 <https://github.com/NREL/OpenStudio/releases/tag/v3.4.0>`_ and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the `latest release <https://github.com/NREL/OpenStudio-ERI/releases>`_ release.
#. To obtain all available weather files, run: ``openstudio workflow/energy_rating_index.rb --download-weather``

.. note:: 

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

.. _running:

Running Calculations
--------------------

Run all calculations (e.g., ERI, ENERGY STAR, etc.) on a provided sample HPXML file as follows:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml``

Note that all simulations will be executed in parallel if there are sufficient cpus/cores available.

This will generate output as shown below:

.. image:: https://user-images.githubusercontent.com/5861765/177409096-102d0a15-c89c-400a-a81c-df9f402810a9.png

You can also request generation of timeseries output CSV files as part of the calculation by providing one or more timeseries flags (``--hourly``, ``--daily``, or ``--monthly``).

For example, to request all possible hourly outputs:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --hourly ALL``

Or for example, one or more specific monthly output types can be requested, e.g.:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --monthly fuels --monthly temperatures``

You can also skip simulations (i.e., just generate the ERI Reference/Rated Home HPXMLs) by using, e.g.:
``openstudio workflow/energy_rating_index.rb -x workflow/sample_files/base.xml --skip-simulation``

Run ``openstudio workflow/energy_rating_index.rb -h`` to see all available commands/arguments.

Output
------

Upon completion, results are provided in the console (stdout) as well as available in summary output files.
See the :ref:`outputs` section for a description of all available outputs.
