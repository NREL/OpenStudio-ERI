.. _outputs:

Outputs
=======

Upon completion of the ERI calculation, multiple output files are available in the ``results`` directory.
See the `sample_results <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results>`_ directory for examples of these outputs.

ERI_Results.csv
---------------

The ``ERI_Results.csv`` file includes the ERI result as well as the high-level components (e.g., REUL, EC_r, EC_x, IAD_Save) that comprise the ERI calculation.
The file reflects the format of the Results tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

See the `example ERI_Results.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERI_Results.csv>`_.

ERI_Worksheet.csv
-----------------

The ``ERI_Worksheet.csv`` file includes more detailed components that feed into the ERI_Results.csv values.
The file reflects the formate of the Worksheet tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

See the `example ERI_Worksheet.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERI_Worksheet.csv>`_.

ERI______Home.csv
-----------------

A CSV file is written for each of the homes simulated (e.g., ``ERIRatedHome.csv`` for the Rated home, ``ERIReferenceHome.csv`` for the Reference home, etc.).

At the top of the file are total annual consumption values for each fuel type as well as an ``Electricity: Net`` field that incorporates any renewable generation.

The next section includes annual energy consumption values disaggregated by fuel type and end use.
Current fuel types are ``Electricity``, ``Natural Gas``, and ``Other Fuel`` (oil, propane, etc.).
Current end uses are ``Heating``, ``Cooling``, ``Hot Water``, ``Lighting``, ``Mech Vent``, ``Refrigerator``, ``Dishwasher``, ``Clothes Washer``, ``Clothes Dryer``, ``Range/Oven``, ``Ceiling Fan``, ``Plug Loads``, and ``PV`` (negative value for generation).

The third section in the CSV includes the heating, cooling, and hot water loads.
Heating and cooling loads include duct losses while hot water loads exclude tank losses.

The final section in the CSV includes `unmet` heating and cooling loads.
These numbers reflect the amount of heating/cooling load that is not met by the HVAC system, indicating that the HVAC system is undersized.
An HVAC system with sufficient capacity to perfectly maintain the thermostat setpoints will report an unmet load of zero.

See the `example ERIRatedHome.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERIRatedHome.csv>`_.

ERI______Home.xml
-----------------

A HPXML file is written for each of the homes simulated (e.g., ``ERIRatedHome.xml`` for the Rated home, ``ERIReferenceHome.xml`` for the Reference home, etc.).
The file reflects the configuration of the home after applying the ERI 301 ruleset.

See the `example ERIRatedHome.xml <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/results/ERIRatedHome.xml>`_.

Simulation Files
----------------

In addition, raw EnergyPlus simulation input/output files are available for each simulation (e.g., ``ERIRatedHome``, ``ERIReferenceHome``, etc. directories).

.. warning:: 

  It is highly discouraged for software tools to read the raw EnergyPlus output files. 
  The EnergyPlus input/output files are made available for inspection, but the outputs for certain situations can be misleading if one does not know how the model was created. 
  If there are additional outputs of interest that are not available in our summary output files, please send us a request.

See the `example ERIRatedHome directory <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results/ERIRatedHome>`_.
