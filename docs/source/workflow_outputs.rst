.. _outputs:

Workflow Outputs
================

Upon completing an ERI or ENERGY STAR calculation, a variety of summary output files and simulation files are available.

.. _eri_files:

ERI Files
---------

ERI output files described below are found in the ``results`` directory.
See the `sample_results_eri <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri>`_ directory for examples of these outputs.

CO2_Results.csv
~~~~~~~~~~~~~~~

A ``CO2_Results.csv`` file will be produced when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.
The file includes all of the outputs that are used in the CO2 Index calculation.

See the `example CO2_Results.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/results/CO2_Results.csv>`_.

ERI_Results.csv
~~~~~~~~~~~~~~~

The ``ERI_Results.csv`` file includes the ERI result as well as the high-level components (e.g., REUL, EC_r, EC_x, IAD_Save) that comprise the ERI calculation.
The file reflects the format of the Results tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

See the `example ERI_Results.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/results/ERI_Results.csv>`_.

ERI_Worksheet.csv
~~~~~~~~~~~~~~~~~

The ``ERI_Worksheet.csv`` file includes more detailed components that feed into the ERI_Results.csv values.
The file reflects the format of the Worksheet tab of the HERS Method Test spreadsheet.

Note that multiple comma-separated values will be reported for many of these outputs if there are multiple heating, cooling, or hot water systems.

See the `example ERI_Worksheet.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/results/ERI_Worksheet.csv>`_.

ERI______Home.csv
~~~~~~~~~~~~~~~~~

A CSV file is written for each of the homes simulated (e.g., ``ERIReferenceHome.csv`` for the Reference home).
The CSV file includes the following sections of output.

See the `example ERIRatedHome.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/results/ERIRatedHome.csv>`_.

A ``CO2ReferenceHome.csv`` will also be produced when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.

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
   ==========================  ===========================

Annual Energy Consumption By End Use
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

End uses are listed below.

Note that all end uses are mutually exclusive -- the "Electricity: Heating" end use, for example, excludes energy reported in the "Electricity: Heating Fans/Pumps" end use.
So the sum of all end uses for a given fuel (e.g., sum of all "End Use: Natural Gas: \*") equal the above reported fuel use (e.g., "Fuel Use: Natural Gas: Total").

   ==========================================================  ====================================================
   Type                                                        Notes
   ==========================================================  ====================================================
   Electricity: Heating (MBtu)                                 Excludes fans/pumps
   Electricity: Heating Fans/Pumps (MBtu)
   Electricity: Cooling (MBtu)                                 Excludes fans/pumps
   Electricity: Cooling Fans/Pumps (MBtu)
   Electricity: Hot Water (MBtu)                               Excludes recirc pump and solar thermal pump
   Electricity: Hot Water Recirc Pump (MBtu)
   Electricity: Hot Water Solar Thermal Pump (MBtu)            Non-zero only when using detailed (not simple) solar thermal inputs
   Electricity: Lighting Interior (MBtu)
   Electricity: Lighting Garage (MBtu)
   Electricity: Lighting Exterior (MBtu)
   Electricity: Mech Vent (MBtu)                               Excludes preheating/precooling
   Electricity: Mech Vent Preheating (MBtu)                    Shared ventilation preconditioning system
   Electricity: Mech Vent Precooling (MBtu)                    Shared ventilation preconditioning system
   Electricity: Whole House Fan (MBtu)
   Electricity: Refrigerator (MBtu)
   Electricity: Dehumidifier (MBtu)
   Electricity: Dishwasher (MBtu)
   Electricity: Clothes Washer (MBtu)
   Electricity: Clothes Dryer (MBtu)
   Electricity: Range/Oven (MBtu)
   Electricity: Ceiling Fan (MBtu)
   Electricity: Television (MBtu)
   Electricity: Plug Loads (MBtu)                              Excludes independently reported plug loads (e.g., well pump)
   Electricity: PV (MBtu)                                      Negative value for any power produced
   Electricity: Generator (MBtu)                               Negative value for any power produced
   Natural Gas: Heating (MBtu)
   Natural Gas: Hot Water (MBtu)
   Natural Gas: Clothes Dryer (MBtu)
   Natural Gas: Range/Oven (MBtu)
   Natural Gas: Mech Vent Preheating (MBtu)                    Shared ventilation preconditioning system
   Natural Gas: Generator (MBtu)                               Positive value for any fuel consumed
   Fuel Oil: Heating (MBtu)
   Fuel Oil: Hot Water (MBtu)
   Fuel Oil: Clothes Dryer (MBtu)
   Fuel Oil: Range/Oven (MBtu)
   Fuel Oil: Mech Vent Preheating (MBtu)                       Shared ventilation preconditioning system
   Propane: Heating (MBtu)
   Propane: Hot Water (MBtu)
   Propane: Clothes Dryer (MBtu)
   Propane: Range/Oven (MBtu)
   Propane: Mech Vent Preheating (MBtu)                        Shared ventilation preconditioning system
   Propane: Generator (MBtu)                                   Positive value for any fuel consumed
   Wood Cord: Heating (MBtu)
   Wood Cord: Hot Water (MBtu)
   Wood Cord: Clothes Dryer (MBtu)
   Wood Cord: Range/Oven (MBtu)
   Wood Cord: Mech Vent Preheating (MBtu)                      Shared ventilation preconditioning system
   Wood Pellets: Heating (MBtu)
   Wood Pellets: Hot Water (MBtu)
   Wood Pellets: Clothes Dryer (MBtu)
   Wood Pellets: Range/Oven (MBtu)
   Wood Pellets: Mech Vent Preheating (MBtu)                   Shared ventilation preconditioning system
   ==========================================================  ====================================================

Annual Projected Emissions
^^^^^^^^^^^^^^^^^^^^^^^^^^

Annual projected emissions are listed below.

Project emissions (CO2, NOx, and SO2) are provided for the Rated Home, ERI Reference Home, and CO2 Reference Home.
These values are calculated according to ANSI/RESNET/ICC 301-2019 Section 5.

   ============================================  ========
   Type                                          Notes
   ============================================  ========
   Emissions: CO2: Projected: Total (lb)         Sum of the diseggregated fuel values
   Emissions: CO2: Projected: Electricity (lb)
   Emissions: CO2: Projected: Natural Gas (lb)
   Emissions: CO2: Projected: Fuel Oil (lb)
   Emissions: CO2: Projected: Propane (lb)
   Emissions: CO2: Projected: Wood Cord (lb)
   Emissions: CO2: Projected: Wood Pellets (lb)
   Emissions: NOx: Projected: Total (lb)         Sum of the diseggregated fuel values
   Emissions: NOx: Projected: Electricity (lb)
   Emissions: NOx: Projected: Natural Gas (lb)
   Emissions: NOx: Projected: Fuel Oil (lb)
   Emissions: NOx: Projected: Propane (lb)
   Emissions: NOx: Projected: Wood Cord (lb)
   Emissions: NOx: Projected: Wood Pellets (lb)
   Emissions: SO2: Projected: Total (lb)         Sum of the diseggregated fuel values
   Emissions: SO2: Projected: Electricity (lb)
   Emissions: SO2: Projected: Natural Gas (lb)
   Emissions: SO2: Projected: Fuel Oil (lb)
   Emissions: SO2: Projected: Propane (lb)
   Emissions: SO2: Projected: Wood Cord (lb)
   Emissions: SO2: Projected: Wood Pellets (lb)
   ============================================  ========

Annual CO2 Index Emissions
^^^^^^^^^^^^^^^^^^^^^^^^^^

Annual CO2 Index Emissions are listed below.

Annual CO2 Index Emissions used for calculating the CO2 Index are provided for the Rated Home and CO2 Reference Home.
These values are calculated according to ANSI/RESNET/ICC 301-2019 Section 6.
These outputs are only available when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.

   ============================================  ========
   Type                                          Notes
   ============================================  ========
   Emissions: CO2: CO2 Index: Total (lb)         Sum of the diseggregated fuel values
   Emissions: CO2: CO2 Index: Electricity (lb)
   Emissions: CO2: CO2 Index: Natural Gas (lb)
   Emissions: CO2: CO2 Index: Fuel Oil (lb)
   Emissions: CO2: CO2 Index: Propane (lb)
   Emissions: CO2: CO2 Index: Wood Cord (lb)
   Emissions: CO2: CO2 Index: Wood Pellets (lb)
   ============================================  ========

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

These numbers reflect the number of hours of the year when the conditioned space temperature is more than 0.2 deg-C (0.36 deg-F) from the setpoint during heating/cooling.

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

   ====================================  ==================================
   Type                                  Notes
   ====================================  ==================================
   Peak Load: Heating: Delivered (kBtu)  Includes HVAC distribution losses.
   Peak Load: Cooling: Delivered (kBtu)  Includes HVAC distribution losses.
   ====================================  ==================================

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
   Fuel Consumptions                    Energy use for each fuel type (in kBtu for fossil fuels and kWh for electricity).
   End Use Consumptions                 Energy use for each end use type (in kBtu for fossil fuels and kWh for electricity).
   Hot Water Uses                       Water use for each end use type (in gallons).
   Total Loads                          Heating, cooling, and hot water loads (in kBtu) for the building.
   Component Loads                      Heating and cooling loads (in kBtu) disaggregated by component (e.g., Walls, Windows, Infiltration, Ducts, etc.).
   Zone Temperatures                    Average temperatures (in deg-F) for each space modeled (e.g., living space, attic, garage, basement, crawlspace, etc.).
   Airflows                             Airflow rates (in cfm) for infiltration, mechanical ventilation, natural ventilation, and whole house fans.
   Weather                              Weather file data including outdoor temperatures, relative humidity, wind speed, and solar.
   ===================================  =====

Timeseries outputs can be one of the following frequencies: hourly, daily, or monthly.

Timestamps in the output use the end-of-hour (or end-of-day for daily frequency, etc.) convention.
Most outputs will be summed over the hour (e.g., energy) but some will be averaged over the hour (e.g., temperatures, airflows).

See the `example ERIRatedHome_Hourly.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/results/ERIRatedHome_Hourly.csv>`_.

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

See the `example ERIRatedHome.xml <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/results/ERIRatedHome.xml>`_.

A ``CO2ReferenceHome.xml`` will also be produced when using ANSI/RESNET/ICC 301-2019 Addendum D or newer.

.. _eri_simulation_files:

Simulation Files
~~~~~~~~~~~~~~~~

In addition, raw EnergyPlus simulation input/output files are available for each simulation (e.g., ``ERIRatedHome``, ``ERIReferenceHome``, etc. directories).

.. warning:: 

  It is highly discouraged for software tools to read the raw EnergyPlus output files. 
  The EnergyPlus input/output files are made available for inspection, but the outputs for certain situations can be misleading if one does not know how the model was created. 
  If there are additional outputs of interest that are not available in our summary output files, please send us a request.

See the `example ERIRatedHome directory <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_eri/ERIRatedHome>`_.

ENERGY STAR Files
-----------------

ENERGY STAR output files described below are found in the ``results`` directory.
See the `sample_results_energystar <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_energystar>`_ directory for examples of these outputs.

ES_Results.csv
~~~~~~~~~~~~~~

The ``ES_Results.csv`` file includes the following:

   ===================================  =====
   Output                               Notes
   ===================================  =====
   Reference Home ERI                   ERI of the ES Reference Home
   SAF (Size Adjustment Factor)         Can only be less than 1 for some ES programs/versions
   SAF Adjusted ERI Target              Reference Home ERI multiplied by SAF
   Rated Home ERI                       ERI of the Rated Home including OPP as allowed by the ES program/version
   Rated Home ERI w/o OPP               ERI of the Rated Home excluding any on-site power production (OPP)
   ENERGY STAR Certification            PASS or FAIL
   ===================================  =====

See the `example ES_Results.csv <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_energystar/results/ES_Results.csv>`_.

ES______.xml
~~~~~~~~~~~~

An HPXML file is written for the ENERGY STAR Reference Home (``ESReference.xml``) and the Rated Home (``ESRated.xml``).
The file reflects the configuration of the home after applying the ENERGY STAR ruleset.

See the `example ESReference.xml <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_energystar/results/ESReference.xml>`_.

ERI Directories
~~~~~~~~~~~~~~~

Two directories are created under ``results``, one called ``ESRerence`` and one called ``ESRated``.
Each directory has the full set of :ref:`eri_files` corresponding to the ERI calculation of the ES Reference Home and Rated Home.

See the `example ESReference directory <https://github.com/NREL/OpenStudio-ERI/tree/master/workflow/sample_results_energystar/ESReference/>`_.
