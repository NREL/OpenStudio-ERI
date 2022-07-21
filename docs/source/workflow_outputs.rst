.. _outputs:

Workflow Outputs
================

Upon completing an ERI or ENERGY STAR calculation, a variety of summary output files and simulation files are available.

.. _eri_files:

ERI Files
---------

ERI output files described below are found in the ``results`` directory.

CO2e_Results.csv
~~~~~~~~~~~~~~~~

A ``CO2e_Results.csv`` file will be produced when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.
The file includes all of the outputs that are used in the CO2e Index calculation.

ERI_Results.csv
~~~~~~~~~~~~~~~

The ``ERI_Results.csv`` file includes the ERI result as well as the high-level components (e.g., REUL, EC_r, EC_x, IAD_Save) that comprise the ERI calculation.
The file reflects the format of the Results tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

ERI_Worksheet.csv
~~~~~~~~~~~~~~~~~

The ``ERI_Worksheet.csv`` file includes more detailed components that feed into the ERI_Results.csv values.
The file reflects the format of the Worksheet tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

ERI______Home.csv
~~~~~~~~~~~~~~~~~

A CSV file is written for each of the homes simulated (e.g., ``ERIReferenceHome.csv`` for the Reference home).
The CSV file includes the following sections of output.

A ``CO2eReferenceHome.csv`` will also be produced when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.

Annual Energy Consumption
~~~~~~~~~~~~~~~~~~~~~~~~~

Annual energy consumption outputs are listed below.

  ====================================  ===========================
  Type                                  Notes
  ====================================  ===========================
  Energy Use: Total (MBtu)
  Energy Use: Net (MBtu)                Subtracts any power produced by PV (including any battery storage) or generators.
  ====================================  ===========================

Annual Energy Consumption by Fuel Type
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Fuel uses are listed below.

   ==========================  ===========================
   Type                        Notes
   ==========================  ===========================
   Electricity: Total (MBtu)
   Electricity: Net (MBtu)     Subtracts any power produced by PV or generators.
   Natural Gas: Total (MBtu)
   Fuel Oil: Total (MBtu)
   Propane: Total (MBtu)
   Wood Cord: Total (MBtu)         
   Wood Pellets: Total (MBtu)
   Coal: Total (MBtu)          Not used by OS-ERI
   ==========================  ===========================

Annual Energy Consumption By End Use
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

End uses are listed below.

Note that all end uses are mutually exclusive -- the "Electricity: Heating" end use, for example, excludes energy reported in the "Electricity: Heating Fans/Pumps" end use.
So the sum of all end uses for a given fuel (e.g., sum of all "End Use: Natural Gas: \*") equal the above reported fuel use (e.g., "Fuel Use: Natural Gas: Total").

   ===================================================================  ====================================================
   Type                                                                 Notes
   ===================================================================  ====================================================
   End Use: Electricity: Heating (MBtu)                                 Excludes heat pump backup and fans/pumps
   End Use: Electricity: Heating Heat Pump Backup (MBtu)
   End Use: Electricity: Heating Fans/Pumps (MBtu)
   End Use: Electricity: Cooling (MBtu)                                 Excludes fans/pumps
   End Use: Electricity: Cooling Fans/Pumps (MBtu)
   End Use: Electricity: Hot Water (MBtu)                               Excludes recirc pump and solar thermal pump
   End Use: Electricity: Hot Water Recirc Pump (MBtu)
   End Use: Electricity: Hot Water Solar Thermal Pump (MBtu)            Non-zero only when using detailed (not simple) solar thermal inputs
   End Use: Electricity: Lighting Interior (MBtu)
   End Use: Electricity: Lighting Garage (MBtu)
   End Use: Electricity: Lighting Exterior (MBtu)
   End Use: Electricity: Mech Vent (MBtu)                               Excludes preheating/precooling
   End Use: Electricity: Mech Vent Preheating (MBtu)                    Shared ventilation preconditioning system
   End Use: Electricity: Mech Vent Precooling (MBtu)                    Shared ventilation preconditioning system
   End Use: Electricity: Whole House Fan (MBtu)
   End Use: Electricity: Refrigerator (MBtu)
   End Use: Electricity: Dehumidifier (MBtu)
   End Use: Electricity: Dishwasher (MBtu)
   End Use: Electricity: Clothes Washer (MBtu)
   End Use: Electricity: Clothes Dryer (MBtu)
   End Use: Electricity: Range/Oven (MBtu)
   End Use: Electricity: Ceiling Fan (MBtu)
   End Use: Electricity: Television (MBtu)
   End Use: Electricity: Plug Loads (MBtu)                              Excludes independently reported plug loads (e.g., well pump)
   End Use: Electricity: PV (MBtu)                                      Negative value for any power produced
   End Use: Electricity: Generator (MBtu)                               Negative value for any power produced
   End Use: Natural Gas: Heating (MBtu)                                 Excludes heat pump backup
   End Use: Natural Gas: Heating Heat Pump Backup (MBtu)
   End Use: Natural Gas: Hot Water (MBtu)
   End Use: Natural Gas: Clothes Dryer (MBtu)
   End Use: Natural Gas: Range/Oven (MBtu)
   End Use: Natural Gas: Mech Vent Preheating (MBtu)                    Shared ventilation preconditioning system
   End Use: Natural Gas: Generator (MBtu)                               Positive value for any fuel consumed
   End Use: Fuel Oil: Heating (MBtu)                                    Excludes heat pump backup
   End Use: Fuel Oil: Heating Heat Pump Backup (MBtu)
   End Use: Fuel Oil: Hot Water (MBtu)
   End Use: Fuel Oil: Clothes Dryer (MBtu)
   End Use: Fuel Oil: Range/Oven (MBtu)
   End Use: Fuel Oil: Mech Vent Preheating (MBtu)                       Shared ventilation preconditioning system
   End Use: Propane: Heating (MBtu)                                     Excludes heat pump backup
   End Use: Propane: Heating Heat Pump Backup (MBtu)
   End Use: Propane: Hot Water (MBtu)
   End Use: Propane: Clothes Dryer (MBtu)
   End Use: Propane: Range/Oven (MBtu)
   End Use: Propane: Mech Vent Preheating (MBtu)                        Shared ventilation preconditioning system
   End Use: Propane: Generator (MBtu)                                   Positive value for any fuel consumed
   End Use: Wood Cord: Heating (MBtu)                                   Excludes heat pump backup
   End Use: Wood Cord: Heating Heat Pump Backup (MBtu)
   End Use: Wood Cord: Hot Water (MBtu)
   End Use: Wood Cord: Clothes Dryer (MBtu)
   End Use: Wood Cord: Range/Oven (MBtu)
   End Use: Wood Cord: Mech Vent Preheating (MBtu)                      Shared ventilation preconditioning system
   End Use: Wood Pellets: Heating (MBtu)                                Excludes heat pump backup
   End Use: Wood Pellets: Heating Heat Pump Backup (MBtu)
   End Use: Wood Pellets: Hot Water (MBtu)
   End Use: Wood Pellets: Clothes Dryer (MBtu)
   End Use: Wood Pellets: Range/Oven (MBtu)
   End Use: Wood Pellets: Mech Vent Preheating (MBtu)                   Shared ventilation preconditioning system
   End Use: Coal: Heating (MBtu)                                        Excludes heat pump backup
   End Use: Coal: Heating Heat Pump Backup (MBtu)
   End Use: Coal: Hot Water (MBtu)                                      Not used by OS-ERI
   End Use: Coal: Clothes Dryer (MBtu)                                  Not used by OS-ERI
   End Use: Coal: Range/Oven (MBtu)                                     Not used by OS-ERI
   End Use: Coal: Mech Vent Preheating (MBtu)                           Not used by OS-ERI
   End Use: Coal: Generator (MBtu)                                      Not used by OS-ERI
   ===================================================================  ====================================================

Annual Emissions
^^^^^^^^^^^^^^^^

Annual emissions are listed below.

Emissions for each emissions type (CO2e, NOx, and SO2) are provided for the Rated Home, ERI Reference Home, and CO2e Reference Home.
Note that rows below with values of zero will be excluded.

   ===============================================================  ===============================================================
   Type                                                             Notes
   ===============================================================  ===============================================================
   Emissions: <EmissionsType>: RESNET: Total (lb)                   Total emissions
   Emissions: <EmissionsType>: RESNET: Electricity: Total (lb)      Emissions for Electricity only
   Emissions: <EmissionsType>: RESNET: Electricity: <EndUse> (lb)   Emissions for this Electricity end use only (one row per end use)
   Emissions: <EmissionsType>: RESNET: Natural Gas: Total (lb)      Emissions for Natural Gas only
   Emissions: <EmissionsType>: RESNET: Natural Gas: <EndUse> (lb)   Emissions for this Natural Gas end use only (one row per end use)
   Emissions: <EmissionsType>: RESNET: Fuel Oil: Total (lb)         Emissions for Fuel Oil only
   Emissions: <EmissionsType>: RESNET: Fuel Oil: <EndUse> (lb)      Emissions for this Fuel Oil end use only (one row per end use)
   Emissions: <EmissionsType>: RESNET: Propane: Total (lb)          Emissions for Propane only
   Emissions: <EmissionsType>: RESNET: Propane: <EndUse> (lb)       Emissions for this Propane end use only (one row per end use)
   Emissions: <EmissionsType>: RESNET: Wood Cord: Total (lb)        Emissions for Wood Cord only
   Emissions: <EmissionsType>: RESNET: Wood Cord: <EndUse> (lb)     Emissions for this Wood Cord end use only (one row per end use)
   Emissions: <EmissionsType>: RESNET: Wood Pellets: Total (lb)     Emissions for Wood Pellets only
   Emissions: <EmissionsType>: RESNET: Wood Pellets: <EndUse> (lb)  Emissions for this Wood Pellets end use only (one row per end use)
   Emissions: <EmissionsType>: RESNET: Coal: Total (lb)             Not used by OS-ERI
   Emissions: <EmissionsType>: RESNET: Coal: <EndUse> (lb)          Not used by OS-ERI
   ===============================================================  ===============================================================

Annual Building Loads
^^^^^^^^^^^^^^^^^^^^^

Annual building loads are listed below.

   =====================================  ==================================================================
   Type                                   Notes
   =====================================  ==================================================================
   Load: Heating: Delivered (MBtu)        Includes HVAC distribution losses.
   Load: Cooling: Delivered (MBtu)        Includes HVAC distribution losses.
   Load: Hot Water: Delivered (MBtu)      Includes contributions by desuperheaters or solar thermal systems.
   Load: Hot Water: Tank Losses (MBtu)
   Load: Hot Water: Desuperheater (MBtu)  Load served by the desuperheater.
   Load: Hot Water: Solar Thermal (MBtu)  Load served by the solar thermal system.
   =====================================  ==================================================================

Note that the "Delivered" loads represent the energy delivered by the HVAC/DHW system; if a system is significantly undersized, there will be unmet load not reflected by these values.

Annual Unmet Hours
^^^^^^^^^^^^^^^^^^

Annual unmet hours are listed below.

   ==========================  =====
   Type                        Notes
   ==========================  =====
   Unmet Hours: Heating (hr)   Number of hours where the heating setpoint is not maintained.
   Unmet Hours: Cooling (hr)   Number of hours where the cooling setpoint is not maintained.
   ==========================  =====

These numbers reflect the number of hours during the year when the conditioned space temperature is more than 0.2 deg-C (0.36 deg-F) from the setpoint during heating/cooling.

Peak Building Electricity
^^^^^^^^^^^^^^^^^^^^^^^^^

Peak building electricity outputs are listed below.

   ==================================  =========================================================
   Type                                Notes
   ==================================  =========================================================
   Peak Electricity: Winter Total (W)  Winter season defined by operation of the heating system.
   Peak Electricity: Summer Total (W)  Summer season defined by operation of the cooling system.
   ==================================  =========================================================

Peak Building Loads
^^^^^^^^^^^^^^^^^^^

Peak building loads are listed below.

   =======================================  ==================================
   Type                                     Notes
   =======================================  ==================================
   Peak Load: Heating: Delivered (kBtu/hr)  Includes HVAC distribution losses.
   Peak Load: Cooling: Delivered (kBtu/hr)  Includes HVAC distribution losses.
   =======================================  ==================================

Note that the "Delivered" peak loads represent the energy delivered by the HVAC system; if a system is significantly undersized, there will be unmet peak load not reflected by these values.

Annual Component Building Loads
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Note**: This section is only available if the ``--add-component-loads`` argument is used.
The argument is not used by default for faster performance.

Component loads represent the estimated contribution of different building components to the annual heating/cooling building loads.
The sum of component loads for heating (or cooling) will roughly equal the annual heating (or cooling) building load reported above.

Component loads disaggregated by Heating/Cooling are listed below.
   
   =================================================  =========================================================================================================
   Type                                               Notes
   =================================================  =========================================================================================================
   Component Load: \*: Roofs (MBtu)                   Heat gain/loss through HPXML ``Roof`` elements adjacent to conditioned space
   Component Load: \*: Ceilings (MBtu)                Heat gain/loss through HPXML ``FrameFloor`` elements (inferred to be ceilings) adjacent to conditioned space
   Component Load: \*: Walls (MBtu)                   Heat gain/loss through HPXML ``Wall`` elements adjacent to conditioned space
   Component Load: \*: Rim Joists (MBtu)              Heat gain/loss through HPXML ``RimJoist`` elements adjacent to conditioned space
   Component Load: \*: Foundation Walls (MBtu)        Heat gain/loss through HPXML ``FoundationWall`` elements adjacent to conditioned space
   Component Load: \*: Doors (MBtu)                   Heat gain/loss through HPXML ``Door`` elements adjacent to conditioned space
   Component Load: \*: Windows (MBtu)                 Heat gain/loss through HPXML ``Window`` elements adjacent to conditioned space, including solar
   Component Load: \*: Skylights (MBtu)               Heat gain/loss through HPXML ``Skylight`` elements adjacent to conditioned space, including solar
   Component Load: \*: Floors (MBtu)                  Heat gain/loss through HPXML ``FrameFloor`` elements (inferred to be floors) adjacent to conditioned space
   Component Load: \*: Slabs (MBtu)                   Heat gain/loss through HPXML ``Slab`` elements adjacent to conditioned space
   Component Load: \*: Internal Mass (MBtu)           Heat gain/loss from internal mass (e.g., furniture, interior walls/floors) in conditioned space
   Component Load: \*: Infiltration (MBtu)            Heat gain/loss from airflow induced by stack and wind effects
   Component Load: \*: Natural Ventilation (MBtu)     Heat gain/loss from airflow through operable windows
   Component Load: \*: Mechanical Ventilation (MBtu)  Heat gain/loss from airflow/fan energy from a whole house mechanical ventilation system
   Component Load: \*: Whole House Fan (MBtu)         Heat gain/loss from airflow due to a whole house fan
   Component Load: \*: Ducts (MBtu)                   Heat gain/loss from conduction and leakage losses through supply/return ducts outside conditioned space
   Component Load: \*: Internal Gains (MBtu)          Heat gain/loss from appliances, lighting, plug loads, water heater tank losses, etc. in the conditioned space
   =================================================  =========================================================================================================

Annual Hot Water Uses
^^^^^^^^^^^^^^^^^^^^^

Annual hot water uses are listed below.

   ===================================  =====
   Type                                 Notes
   ===================================  =====
   Hot Water: Clothes Washer (gal)
   Hot Water: Dishwasher (gal)
   Hot Water: Fixtures (gal)            Showers and faucets.
   Hot Water: Distribution Waste (gal) 
   ===================================  =====

Timeseries Outputs
~~~~~~~~~~~~~~~~~~

See the :ref:`running` section for requesting timeseries outputs.
When requested, a CSV file of timeseries outputs is written for the Reference/Rated Homes (e.g., ``ERIReferenceHome_Hourly.csv``, ``ERIReferenceHome_Daily.csv``, or ``ERIReferenceHome_Monthly.csv`` for the Reference home).

Depending on the outputs requested, CSV files may include:

   ===================================  =====
   Type                                 Notes
   ===================================  =====
   Total Consumptions                   Energy use for building total.
   Fuel Consumptions                    Energy use for each fuel type (in kBtu for fossil fuels and kWh for electricity).
   End Use Consumptions                 Energy use for each end use type (in kBtu for fossil fuels and kWh for electricity).
   Emissions                            Emissions (CO2e, NOx, SO2).
   Emission Fuels                       Emissions (CO2e, NOx, SO2) disaggregated by fuel type.
   Emission End Uses                    Emissions (CO2e, NOx, SO2) disaggregated by end use.
   Hot Water Uses                       Water use for each end use type (in gallons).
   Total Loads                          Heating, cooling, and hot water loads (in kBtu) for the building.
   Component Loads                      Heating and cooling loads (in kBtu) disaggregated by component (e.g., Walls, Windows, Infiltration, Ducts, etc.).
   Zone Temperatures                    Zone temperatures (in deg-F) for each space (e.g., living space, attic, garage, basement, crawlspace, etc.) plus heating/cooling setpoints.
   Airflows                             Airflow rates (in cfm) for infiltration, mechanical ventilation, natural ventilation, and whole house fans.
   Weather                              Weather file data including outdoor temperatures, relative humidity, wind speed, and solar.
   ===================================  =====

Timeseries outputs can be one of the following frequencies: hourly, daily, or monthly.

Timestamps in the output use the end-of-hour (or end-of-day for daily frequency, etc.) convention.
Most outputs will be summed over the hour (e.g., energy) but some will be averaged over the hour (e.g., temperatures, airflows).

ERI______Home.xml
~~~~~~~~~~~~~~~~~

An HPXML file is written for each of the homes simulated (e.g., ``ERIReferenceHome.xml`` for the Reference home).
The file reflects the configuration of the home after applying the ERI 301 ruleset.

The file will also show HPXML default values that are applied as part of modeling this home.
Defaults will be applied for a few different reasons:

#. Optional ERI inputs aren't provided (e.g., ventilation rate for a vented attic, SHR for an air conditioner, etc.)
#. Modeling assumptions (e.g., 1 hour timestep, Jan 1 - Dec 31 run period, appliance schedules, etc.)
#. HVAC sizing calculations (e.g., autosized HVAC capacities and airflow rates, heating/cooling design loads)

Any HPXML-defaulted values will include the ``dataSource='software'`` attribute.

A ``CO22ReferenceHome.xml`` will also be produced when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.

.. _eri_simulation_files:

Simulation Files
~~~~~~~~~~~~~~~~

In addition, raw EnergyPlus simulation input/output files are available for each simulation (e.g., ``ERIRatedHome``, ``ERIReferenceHome``, etc. directories).

.. warning:: 

  It is highly discouraged for software tools to read the raw EnergyPlus output files. 
  The EnergyPlus input/output files are made available for inspection, but the outputs for certain situations can be misleading if one does not know how the model was created. 
  If there are additional outputs of interest that are not available in our summary output files, please send us a request.

ENERGY STAR Files
-----------------

ENERGY STAR output files described below are found in the ``results`` directory.

In addition, :ref:`eri_files` corresponding to the ERI calculation of the ENERGY STAR Reference Home and ENERGY STAR Rated Home will be generated.
For example, ESRated_ERIReferenceHome.xml is the ERI Reference Home HPXML file corresponding to the ENERGY STAR Rated Home.

ES_Results.csv
~~~~~~~~~~~~~~

The ``ES_Results.csv`` file includes the following:

   ====================================  =====
   Output                                Notes
   ====================================  =====
   Reference Home ERI                    ERI of the ES Reference Home
   SAF (Size Adjustment Factor)          Can only be less than 1 for some ES programs/versions
   SAF Adjusted ERI Target               Reference Home ERI multiplied by SAF
   Rated Home ERI                        ERI of the Rated Home including OPP as allowed by the ES program/version
   Rated Home ERI w/o OPP                ERI of the Rated Home excluding any on-site power production (OPP)
   ENERGY STAR Certification             PASS or FAIL
   Zero Energy Ready Home Certification  PASS or FAIL
   ====================================  =====

ES______.xml
~~~~~~~~~~~~

An HPXML file is written for the ENERGY STAR Reference Home (``ESReference.xml``) and the ENERGY STAR Rated Home (``ESRated.xml``).
The file reflects the configuration of the home after applying the ENERGY STAR ruleset.
