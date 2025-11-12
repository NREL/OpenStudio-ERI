.. |nbsp| unicode:: 0xA0
   :trim:

.. _outputs:

Workflow Outputs
================

Upon completing an OpenStudio-ERI run, a variety of summary output files and simulation files are available:

- :ref:`summary_outputs_csv`
- :ref:`home_annual_outputs_csv`
- :ref:`home_timeseries_outputs_csv`
- :ref:`home_configurations_hpxml`
- :ref:`home_energyplus_files`
- :ref:`hers_diagnostic_output`

Output directories will reflect the requested :ref:`hpxml_calculations`:

  ====================  ===============
  Calculation           Output dir name
  ====================  ===============
  CO2e Index            CO2e_<Version>
  ERI                   ERI_<Version>
  IECC ERI              IECC_<Version>
  ENERGY STAR           ES_<Version>
  DENH                  DENH_<Version>
  ====================  ===============

All CSV output files can be alternatively requested in JSON format; see :ref:`running`.

.. note::

  MBtu is defined as one million Btu.

.. _summary_outputs_csv:

Summary Outputs (CSV)
---------------------

Based on which :ref:`hpxml_calculations` were requested, summary output files will be found at ``results/results.csv`` directory.

  ================  =======================
  Calculation       File
  ================  =======================
  CO2e Index        :ref:`co2e_results_csv`
  ERI               :ref:`eri_results_csv`
  IECC ERI          :ref:`eri_results_csv`
  ENERGY STAR       :ref:`es_results_csv`
  DENH              :ref:`denh_results_csv`
  ================  =======================

.. _co2e_results_csv:

CO2e results.csv
~~~~~~~~~~~~~~~~

A ``CO2e_<Version>/results/results.csv`` file will be produced when requesting the CO2IndexCalculation; see :ref:`hpxml_calculations`.
Refer to the ANSI 301 Standard for details on how the CO2e Rating Index is calculated.

  =====================  ===============================================
  Output                 Notes
  =====================  ===============================================
  CO2e Rating Index      CO2e Rating Index
  ACO2 (lb CO2e)         Annual hourly CO2e emissions for Rated Home
  ARCO2 (lb CO2e)        Annual hourly CO2e emissions for Reference Home
  IAF RH                 Combined Index Adjustment Factor for Rated Home
  =====================  ===============================================

.. _eri_results_csv:

ERI results.csv
~~~~~~~~~~~~~~~

A ``ERI_<Version>/results/results.csv`` (and/or ``IECC_<Version>/results/results.csv``)  file will be produced when requesting the ERICalculation (and/or IECCERICalculation); see :ref:`hpxml_calculations`.
Refer to the ANSI 301 Standard for details on how the Energy Rating Index is calculated.

  =====================  ===============================================
  Output                 Notes
  =====================  ===============================================
  ERI                    Energy Rating Index
  Total Loads TRL        Total Reference Loads
  Total Loads TnML       Total normalized Modified Loads for Rated Home
  Total Loads TRL*IAF    Total Reference Loads x Index Adjustment Factor for Rated Home
  IAD_Save (%)           Index Adjustment Design savings
  IAF CFA                Conditioned Floor Area factor for Index Adjustment Factor
  IAF NBR                Number of Bedrooms factor for Index Adjustment Factor
  IAF NS                 Number of Stories factor for Index Adjustment Factor
  IAF RH                 Combined Index Adjustment Factor for Rated Home
  PEfrac                 Purchased Energy fraction for Rated Home
  TEU (MBtu)             Total Energy Use for Rated Home
  OPP (MBtu)             On-Site Power Production for Rated Home
  BSL (MBtu)             Battery Storage Losses for Rated Home
  |nbsp|
  REUL Heating (MBtu)    Reference Home End Use Load for Heating [#]_
  REUL Cooling (MBtu)    Reference Home End Use Load for Cooling
  REUL Hot Water (MBtu)  Reference Home End Use Load for Hot Water
  EC_r Heating (MBtu)    Reference Home estimated Energy Consumption for Heating
  EC_r Cooling (MBtu)    Reference Home estimated Energy Consumption for Cooling
  EC_r Hot Water (MBtu)  Reference Home estimated Energy Consumption for Hot Water
  EC_r L&A (MBtu)        Reference Home estimated Energy Consumption for Lights & Appliances
  EC_r Vent (MBtu)       Reference Home estimated Energy Consumption for Mechanical Ventilation
  EC_r Dehumid (MBtu)    Reference Home estimated Energy Consumption for Dehumidification
  DSE_r Heating          Reference Home Distribution System Efficiency for Heating
  DSE_r Cooling          Reference Home Distribution System Efficiency for Cooling
  DSE_r Hot Water        Reference Home Distribution System Efficiency for Hot Water
  EEC_r Heating          Reference Home Equipment Efficiency Coefficient for Heating
  EEC_r Cooling          Reference Home Equipment Efficiency Coefficient for Cooling
  EEC_r Hot Water        Reference Home Equipment Efficiency Coefficient for Hot Water
  |nbsp|
  nMEUL Heating          Rated Home normalized Modified End Use Load for Heating
  nMEUL Cooling          Rated Home normalized Modified End Use Load for Cooling
  nMEUL Hot Water        Rated Home normalized Modified End Use Load for Hot Water
  nMEUL Vent Preheat     Rated Home normalized Modified End Use Load for Mechanical Ventilation Preheating
  nMEUL Vent Precool     Rated Home normalized Modified End Use Load for Mechanical Ventilation Precooling
  nEC_x Heating          Rated Home normalized Energy Consumption for Heating
  nEC_x Cooling          Rated Home normalized Energy Consumption for Cooling
  nEC_x Hot Water        Rated Home normalized Energy Consumption for Hot Water
  EC_x Heating (MBtu)    Rated Home estimated Energy Consumption for Heating
  EC_x Cooling (MBtu)    Rated Home estimated Energy Consumption for Cooling
  EC_x Hot Water (MBtu)  Rated Home estimated Energy Consumption for Hot Water
  EC_x L&A (MBtu)        Rated Home estimated Energy Consumption for Lights & Appliances
  EC_x Vent (MBtu)       Rated Home estimated Energy Consumption for Mechanical Ventilation
  EC_x Dehumid (MBtu)    Rated Home estimated Energy Consumption for Dehumidification
  EEC_x Heating          Rated Home Equipment Efficiency Coefficient for Heating
  EEC_x Cooling          Rated Home Equipment Efficiency Coefficient for Cooling
  EEC_x Hot Water        Rated Home Equipment Efficiency Coefficient for Hot Water
  |nbsp|
  Coeff Heating a        Heating coefficient a for EEC_r
  Coeff Heating b        Heating coefficient b for EEC_r
  Coeff Cooling a        Cooling coefficient a for EEC_r
  Coeff Cooling b        Cooling coefficient b for EEC_r
  Coeff Hot Water a      Hot Water coefficient a for EEC_r
  Coeff Hot Water b      Hot Water coefficient a for EEC_r
  =====================  ===============================================

  .. [#] Multiple comma-separated values will be reported for some outputs if there are multiple heating, cooling, or hot water systems.

.. _es_results_csv:

ES results.csv
~~~~~~~~~~~~~~

A ``ES_<Version>/results/results.csv`` file will be produced when requesting an ENERGY STAR calculation (``EnergyStarCalculation``); see :ref:`hpxml_calculations`.

  ====================================  =====
  Output                                Notes
  ====================================  =====
  Reference Home ERI                    ERI of the ES Reference Home
  SAF (Size Adjustment Factor)          Can only be less than 1 for some programs/versions
  SAF Adjusted ERI Target               Reference Home ERI multiplied by SAF
  Rated Home ERI                        ERI of the Rated Home including OPP as allowed by the program/version
  Rated Home ERI w/o OPP                ERI of the Rated Home excluding any on-site power production (OPP)
  ENERGY STAR Certification             PASS or FAIL
  ====================================  =====

.. _denh_results_csv:

DENH results.csv
~~~~~~~~~~~~~~~~

A ``DENH_<Version>/results/results.csv`` file will be produced when requesting a DOE Efficient New Homes (formerly Zero Energy Ready Homes) calculation (``DENHCalculation``); see :ref:`hpxml_calculations`.

  =====================================  =====
  Output                                 Notes
  =====================================  =====
  Reference Home ERI                     ERI of the DENH Reference Home
  SAF (Size Adjustment Factor)           Can only be less than 1 for some programs/versions
  SAF Adjusted ERI Target                Reference Home ERI multiplied by SAF
  Rated Home ERI                         ERI of the Rated Home including OPP as allowed by the program/version
  Rated Home ERI w/o OPP                 ERI of the Rated Home excluding any on-site power production (OPP)
  DOE Efficient New Homes Certification  PASS or FAIL
  =====================================  =====

.. _home_annual_outputs_csv:

Home Annual Outputs (CSV)
-------------------------

Based on which calculations were requested in the HPXML file, CSV annual output files will be found in the ``results`` directory for each simulated home.

  ================  ===================================================  =========
  Calculation       File                                                 Notes
  ================  ===================================================  =========
  CO2e Index        RatedHome.csv                                        CO2e Rated Home. Only produced if 301-2019 Addendum D or newer.
  CO2e Index        ReferenceHome.csv                                    CO2e Reference Home. Only produced if 301-2019 Addendum D or newer.
  CO2e Index        IndexAdjustmentHome.csv                              CO2e Index Adjustment Design. Only produced if 301-2019 Addendum D or newer.
  CO2e Index        IndexAdjustmentReferenceHome.csv                     CO2e Index Adjustment Reference Home. Only produced if 301-2019 Addendum D or newer.
  ERI               RatedHome.csv                                        ERI Rated Home.
  ERI               ReferenceHome.csv                                    ERI Reference Home.
  ERI               IndexAdjustmentHome.csv                              ERI Index Adjustment Design. Only produced if 301-2014 Addendum E or newer.
  ERI               IndexAdjustmentReferenceHome.csv                     ERI Index Adjustment Reference Home. Only produced if 301-2014 Addendum E or newer.
  IECC ERI          RatedHome.csv                                        IECC ERI Rated Home.
  IECC ERI          ReferenceHome.csv                                    IECC ERI Reference Home.
  IECC ERI          IndexAdjustmentHome.csv                              IECC ERI Index Adjustment Design.
  IECC ERI          IndexAdjustmentReferenceHome.csv                     IECC ERI Index Adjustment Reference Home.
  ENERGY STAR       RatedHome/results/RatedHome.csv                      ERI Rated Home for the ENERGY STAR rated home.
  ENERGY STAR       RatedHome/results/ReferenceHome.csv                  ERI Reference Home for the ENERGY STAR rated home.
  ENERGY STAR       RatedHome/results/IndexAdjustmentHome.csv            ERI Index Adjustment Design for the ENERGY STAR rated home.
  ENERGY STAR       RatedHome/results/IndexAdjustmentReferenceHome.csv   ERI Index Adjustment Reference Home for the ENERGY STAR rated home.
  ENERGY STAR       TargetHome/results/RatedHome.csv                     ERI Rated Home for the ENERGY STAR Reference Design.
  ENERGY STAR       TargetHome/results/ReferenceHome.csv                 ERI Reference Home for the ENERGY STAR Reference Design.
  ENERGY STAR       TargetHome/results/IndexAdjustmentHome.csv           ERI Index Adjustment Design for the ENERGY STAR Reference Design.
  ENERGY STAR       TargetHome/results/IndexAdjustmentReferenceHome.csv  ERI Index Adjustment Reference Home for the ENERGY STAR Reference Design.
  DENH              RatedHome/results/RatedHome.csv                      ERI Rated Home for the DENH rated home.
  DENH              RatedHome/results/ReferenceHome.csv                  ERI Reference Home for the DENH rated home.
  DENH              RatedHome/results/IndexAdjustmentHome.csv            ERI Index Adjustment Design for the DENH rated home.
  DENH              RatedHome/results/IndexAdjustmentReferenceHome.csv   ERI Index Adjustment Reference Home for the DENH rated home.
  DENH              TargetHome/results/RatedHome.csv                     ERI Rated Home for the DENH Target Home.
  DENH              TargetHome/results/ReferenceHome.csv                 ERI Reference Home for the DENH Target Home.
  DENH              TargetHome/results/IndexAdjustmentHome.csv           ERI Index Adjustment Design for the DENH Target Home.
  DENH              TargetHome/results/IndexAdjustmentReferenceHome.csv  ERI Index Adjustment Reference Home for the DENH Target Home.
  ================  ===================================================  =========

Each CSV file includes the following sections of output.

Annual Energy
~~~~~~~~~~~~~

Annual energy outputs are listed below.

  ====================================  ===========================
  Type                                  Notes
  ====================================  ===========================
  Energy Use: Total (MBtu)              Total energy consumption
  Energy Use: Net (MBtu)                Total energy consumption minus power produced by PV
  ====================================  ===========================

Annual Energy by Fuel Type
~~~~~~~~~~~~~~~~~~~~~~~~~~

Fuel uses are listed below.

  ====================================  ===========================
  Type                                  Notes
  ====================================  ===========================
  Fuel Use: Electricity: Total (MBtu)   Total electricity consumption
  Fuel Use: Electricity: Net (MBtu)     Total energy consumption minus power produced by PV
  Fuel Use: Natural Gas: Total (MBtu)
  Fuel Use: Fuel Oil: Total (MBtu)
  Fuel Use: Propane: Total (MBtu)
  Fuel Use: Wood Cord: Total (MBtu)
  Fuel Use: Wood Pellets: Total (MBtu)
  Fuel Use: Coal: Total (MBtu)          Not used by OS-ERI
  ====================================  ===========================

.. _annualenduses:

Annual Energy By End Use
~~~~~~~~~~~~~~~~~~~~~~~~

End uses are listed below.

Note that all end uses are mutually exclusive -- the "Electricity: Heating" end use, for example, excludes energy reported in the "Electricity: Heating Fans/Pumps" end use.
So the sum of all end uses for a given fuel (e.g., sum of all "End Use: Natural Gas: \*") equal the above reported fuel use (e.g., "Fuel Use: Natural Gas: Total").

  ================================================================  ====================================================
  Type                                                                 Notes
  ================================================================  ====================================================
  End Use: Electricity: Heating (MBtu)                              Excludes heat pump backup and fans/pumps
  End Use: Electricity: Heating Fans/Pumps (MBtu)                   Includes supply fan (air distribution) or circulating pump (hydronic distribution or geothermal loop)
  End Use: Electricity: Heating Heat Pump Backup (MBtu)             Excludes heat pump backup fans/pumps
  End Use: Electricity: Heating Heat Pump Backup Fans/Pumps (MBtu)  Includes supply fan (air distribution) or circulating pump (hydronic distribution) during heat pump backup
  End Use: Electricity: Cooling (MBtu)                              Excludes fans/pumps
  End Use: Electricity: Cooling Fans/Pumps (MBtu)                   Includes supply fan (air distribution) and circulating pump (geothermal loop)
  End Use: Electricity: Hot Water (MBtu)                            Excludes recirc pump and solar thermal pump
  End Use: Electricity: Hot Water Recirc Pump (MBtu)
  End Use: Electricity: Hot Water Solar Thermal Pump (MBtu)         Non-zero only when using detailed (not simple) solar thermal inputs
  End Use: Electricity: Lighting Interior (MBtu)
  End Use: Electricity: Lighting Garage (MBtu)
  End Use: Electricity: Lighting Exterior (MBtu)
  End Use: Electricity: Mech Vent (MBtu)                            Excludes preheating/precooling
  End Use: Electricity: Mech Vent Preheating (MBtu)                 Shared ventilation preconditioning system
  End Use: Electricity: Mech Vent Precooling (MBtu)                 Shared ventilation preconditioning system
  End Use: Electricity: Whole House Fan (MBtu)
  End Use: Electricity: Refrigerator (MBtu)
  End Use: Electricity: Freezer (MBtu)                              Not used by OS-ERI
  End Use: Electricity: Dehumidifier (MBtu)
  End Use: Electricity: Dishwasher (MBtu)
  End Use: Electricity: Clothes Washer (MBtu)
  End Use: Electricity: Clothes Dryer (MBtu)
  End Use: Electricity: Range/Oven (MBtu)
  End Use: Electricity: Ceiling Fan (MBtu)
  End Use: Electricity: Television (MBtu)
  End Use: Electricity: Plug Loads (MBtu)                           Excludes independently reported plug loads (e.g., well pump)
  End Use: Electricity: Well Pump (MBtu)                            Not used by OS-ERI
  End Use: Electricity: Pool Heater (MBtu)                          Not used by OS-ERI
  End Use: Electricity: Pool Pump (MBtu)                            Not used by OS-ERI
  End Use: Electricity: Hot Tub Heater (MBtu)                       Not used by OS-ERI
  End Use: Electricity: Hot Tub Pump (MBtu)                         Not used by OS-ERI
  End Use: Electricity: PV (MBtu)                                   Negative value for any power produced
  End Use: Electricity: Generator (MBtu)                            Negative value for any power produced
  End Use: Electricity: Battery (MBtu)                              Not used by OS-ERI
  End Use: Electricity: Electric Vehicle Charging (MBtu)            Not used by OS-ERI
  End Use: Natural Gas: Heating (MBtu)                              Excludes heat pump backup
  End Use: Natural Gas: Heating Heat Pump Backup (MBtu)
  End Use: Natural Gas: Hot Water (MBtu)
  End Use: Natural Gas: Clothes Dryer (MBtu)
  End Use: Natural Gas: Range/Oven (MBtu)
  End Use: Natural Gas: Mech Vent Preheating (MBtu)                 Shared ventilation preconditioning system
  End Use: Natural Gas: Pool Heater (MBtu)                          Not used by OS-ERI
  End Use: Natural Gas: Hot Tub Heater (MBtu)                       Not used by OS-ERI
  End Use: Natural Gas: Grill (MBtu)                                Not used by OS-ERI
  End Use: Natural Gas: Lighting (MBtu)                             Not used by OS-ERI
  End Use: Natural Gas: Fireplace (MBtu)                            Not used by OS-ERI
  End Use: Natural Gas: Generator (MBtu)                            Positive value for any fuel consumed
  End Use: Fuel Oil: Heating (MBtu)                                 Excludes heat pump backup
  End Use: Fuel Oil: Heating Heat Pump Backup (MBtu)
  End Use: Fuel Oil: Hot Water (MBtu)
  End Use: Fuel Oil: Clothes Dryer (MBtu)
  End Use: Fuel Oil: Range/Oven (MBtu)
  End Use: Fuel Oil: Mech Vent Preheating (MBtu)                    Shared ventilation preconditioning system
  End Use: Fuel Oil: Grill (MBtu)                                   Not used by OS-ERI
  End Use: Fuel Oil: Lighting (MBtu)                                Not used by OS-ERI
  End Use: Fuel Oil: Fireplace (MBtu)                               Not used by OS-ERI
  End Use: Fuel Oil: Generator (MBtu)                               Positive value for any fuel consumed
  End Use: Propane: Heating (MBtu)                                  Excludes heat pump backup
  End Use: Propane: Heating Heat Pump Backup (MBtu)
  End Use: Propane: Hot Water (MBtu)
  End Use: Propane: Clothes Dryer (MBtu)
  End Use: Propane: Range/Oven (MBtu)
  End Use: Propane: Mech Vent Preheating (MBtu)                     Shared ventilation preconditioning system
  End Use: Propane: Grill (MBtu)                                    Not used by OS-ERI
  End Use: Propane: Lighting (MBtu)                                 Not used by OS-ERI
  End Use: Propane: Fireplace (MBtu)                                Not used by OS-ERI
  End Use: Propane: Generator (MBtu)                                Positive value for any fuel consumed
  End Use: Wood Cord: Heating (MBtu)                                Excludes heat pump backup
  End Use: Wood Cord: Heating Heat Pump Backup (MBtu)
  End Use: Wood Cord: Hot Water (MBtu)
  End Use: Wood Cord: Clothes Dryer (MBtu)
  End Use: Wood Cord: Range/Oven (MBtu)
  End Use: Wood Cord: Mech Vent Preheating (MBtu)                   Shared ventilation preconditioning system
  End Use: Wood Cord: Grill (MBtu)                                  Not used by OS-ERI
  End Use: Wood Cord: Lighting (MBtu)                               Not used by OS-ERI
  End Use: Wood Cord: Fireplace (MBtu)                              Not used by OS-ERI
  End Use: Wood Cord: Generator (MBtu)                              Positive value for any fuel consumed
  End Use: Wood Pellets: Heating (MBtu)                             Excludes heat pump backup
  End Use: Wood Pellets: Heating Heat Pump Backup (MBtu)
  End Use: Wood Pellets: Hot Water (MBtu)
  End Use: Wood Pellets: Clothes Dryer (MBtu)
  End Use: Wood Pellets: Range/Oven (MBtu)
  End Use: Wood Pellets: Mech Vent Preheating (MBtu)                Shared ventilation preconditioning system
  End Use: Wood Pellets: Grill (MBtu)                               Not used by OS-ERI
  End Use: Wood Pellets: Lighting (MBtu)                            Not used by OS-ERI
  End Use: Wood Pellets: Fireplace (MBtu)                           Not used by OS-ERI
  End Use: Wood Pellets: Generator (MBtu)                           Positive value for any fuel consumed
  End Use: Coal: Heating (MBtu)                                     Excludes heat pump backup
  End Use: Coal: Heating Heat Pump Backup (MBtu)
  End Use: Coal: Hot Water (MBtu)                                   Not used by OS-ERI
  End Use: Coal: Clothes Dryer (MBtu)                               Not used by OS-ERI
  End Use: Coal: Range/Oven (MBtu)                                  Not used by OS-ERI
  End Use: Coal: Mech Vent Preheating (MBtu)                        Not used by OS-ERI
  End Use: Coal: Grill (MBtu)                                       Not used by OS-ERI
  End Use: Coal: Lighting (MBtu)                                    Not used by OS-ERI
  End Use: Coal: Fireplace (MBtu)                                   Not used by OS-ERI
  End Use: Coal: Generator (MBtu)                                   Not used by OS-ERI
  ================================================================  ====================================================

Annual Energy By System Use
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Results for each end use of each heating, cooling, and water heating system defined in the HPXML file are listed as shown below.
Non-zero end uses from :ref:`annualenduses` will be included.

  ===============================================================  =============================================
  Type                                                             Notes
  ===============================================================  =============================================
  System Use: <HeatingSystemID>: <FuelType>: <EndUse> (MBtu)       End use energy for the heating system
  System Use: <CoolingSystemID>: <FuelType>: <EndUse> (MBtu)       End use energy for the cooling system
  System Use: <HeatPumpID>: <FuelType>: <EndUse> (MBtu)            End use energy for the heat pump system
  System Use: <WaterHeatingSystemID>: <FuelType>: <EndUse> (MBtu)  End use energy for the water heating system
  System Use: <VentilationFanID>: <FuelType>: <EndUse> (MBtu)      End use energy for the ventilation fan system (preheating/precooling only)
  ===============================================================  =============================================

Annual Emissions
~~~~~~~~~~~~~~~~

Annual emissions are listed below.

Emissions for each emissions type (CO2e, NOx, and SO2) are provided.

  ================================================================  ===============================================================
  Type                                                              Notes
  ================================================================  ===============================================================
  Emissions: <EmissionsType>: ANSI301: Total (lb)                   Total emissions
  Emissions: <EmissionsType>: ANSI301: Net (lb)                     Total emissions minus power produced by PV
  ================================================================  ===============================================================

Annual Emissions by Fuel Use
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Annual emissions by fuel use are listed below.

Emissions for each emissions type (CO2e, NOx, and SO2) are provided.

  ================================================================  ===============================================================
  Type                                                              Notes
  ================================================================  ===============================================================
  Emissions: <EmissionsType>: ANSI301: Electricity: Total (lb)      Emissions for Electricity only
  Emissions: <EmissionsType>: ANSI301: Electricity: Net (lb)        Emissions for Electricity only minus power produced by PV
  Emissions: <EmissionsType>: ANSI301: Natural Gas: Total (lb)      Emissions for Natural Gas only
  Emissions: <EmissionsType>: ANSI301: Fuel Oil: Total (lb)         Emissions for Fuel Oil only
  Emissions: <EmissionsType>: ANSI301: Propane: Total (lb)          Emissions for Propane only
  Emissions: <EmissionsType>: ANSI301: Wood Cord: Total (lb)        Emissions for Wood Cord only
  Emissions: <EmissionsType>: ANSI301: Wood Pellets: Total (lb)     Emissions for Wood Pellets only
  Emissions: <EmissionsType>: ANSI301: Coal: Total (lb)             Not used by OS-ERI
  ================================================================  ===============================================================

Annual Emissions by End Use
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Annual emissions by end use are listed below.

Emissions for each emissions type (CO2e, NOx, and SO2) are provided.
Every end use from :ref:`annualenduses` will be included.

  ================================================================  ===============================================================
  Type                                                              Notes
  ================================================================  ===============================================================
  Emissions: <EmissionsType>: ANSI301: Electricity: <EndUse> (lb)   Emissions for this Electricity end use only (one row per end use)
  Emissions: <EmissionsType>: ANSI301: Natural Gas: <EndUse> (lb)   Emissions for this Natural Gas end use only (one row per end use)
  Emissions: <EmissionsType>: ANSI301: Fuel Oil: <EndUse> (lb)      Emissions for this Fuel Oil end use only (one row per end use)
  Emissions: <EmissionsType>: ANSI301: Propane: <EndUse> (lb)       Emissions for this Propane end use only (one row per end use)
  Emissions: <EmissionsType>: ANSI301: Wood Cord: <EndUse> (lb)     Emissions for this Wood Cord end use only (one row per end use)
  Emissions: <EmissionsType>: ANSI301: Wood Pellets: <EndUse> (lb)  Emissions for this Wood Pellets end use only (one row per end use)
  Emissions: <EmissionsType>: ANSI301: Coal: <EndUse> (lb)          Not used by OS-ERI
  ================================================================  ===============================================================

Annual Building Loads
~~~~~~~~~~~~~~~~~~~~~

Annual building loads are listed below.

  ======================================  ==================================================================
  Type                                    Notes
  ======================================  ==================================================================
  Load: Heating: Delivered (MBtu)         Total heating load delivered, including distribution losses.
  Load: Heating: Heat Pump Backup (MBtu)  Heating load delivered by the heat pump backup only, including distribution losses.
  Load: Cooling: Delivered (MBtu)         Total cooling load delivered, including distribution losses.
  Load: Hot Water: Delivered (MBtu)       Total hot water load delivered, including contributions by desuperheaters or solar thermal systems.
  Load: Hot Water: Tank Losses (MBtu)
  Load: Hot Water: Desuperheater (MBtu)   Hot water load delivered by the desuperheater.
  Load: Hot Water: Solar Thermal (MBtu)   Hot water load delivered by the solar thermal system.
  ======================================  ==================================================================

Note that the "Delivered" loads represent the energy delivered by the HVAC/DHW system; if a system is significantly undersized, there will be unmet load not reflected by these values.

Annual Unmet Hours
~~~~~~~~~~~~~~~~~~

Annual unmet hours are listed below.

  ============================  =====
  Type                          Notes
  ============================  =====
  Unmet Hours: Heating (hr)     Number of hours where the heating setpoint is not maintained. [#]_
  Unmet Hours: Cooling (hr)     Number of hours where the cooling setpoint is not maintained.
  Unmet Hours: EV Driving (hr)  Not used by OS-ERI
  ============================  =====

  .. [#] The unmet heating and cooling numbers reflect the number of hours during the heating/cooling season when the conditioned space temperature deviates more than 0.2 deg-C (0.36 deg-F) from the heating/cooling setpoint.

Peak Building Electricity
~~~~~~~~~~~~~~~~~~~~~~~~~

Peak building electricity outputs are listed below.

  ==================================  =============================================================
  Type                                Notes
  ==================================  =============================================================
  Peak Electricity: Winter Total (W)  Winter maximum for total electricity consumption [#]_
  Peak Electricity: Summer Total (W)  Summer maximum for total electricity consumption [#]_
  Peak Electricity: Annual Total (W)  Annual maximum for total electricity consumption
  Peak Electricity: Winter Net (W)    Winter maximum for total electricity consumption minus power produced by PV
  Peak Electricity: Summer Net (W)    Summer maximum for total electricity consumption minus power produced by PV
  Peak Electricity: Annual Net (W)    Annual maximum for total electricity consumption minus power produced by PV
  ==================================  =============================================================

  .. [#] Winter is Dec/Jan/Feb (or Jun/Jul/Aug in the southern hemisphere).
  .. [#] Summer is Jun/Jul/Aug (or Dec/Jan/Feb in the southern hemisphere).

Peak Building Loads
~~~~~~~~~~~~~~~~~~~

Peak building loads are listed below.

  =======================================  ==================================
  Type                                     Notes
  =======================================  ==================================
  Peak Load: Heating: Delivered (kBtu/hr)  Includes HVAC distribution losses.
  Peak Load: Cooling: Delivered (kBtu/hr)  Includes HVAC distribution losses.
  =======================================  ==================================

Note that the "Delivered" peak loads represent the energy delivered by the HVAC system; if a system is significantly undersized, there will be unmet peak load not reflected by these values.

Annual Component Building Loads
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Note**: This section is only available if the ``--add-component-loads`` argument is used.
The argument is not used by default for faster performance.

Component loads represent the estimated contribution of different building components to the annual heating/cooling building loads.
The sum of component loads for heating (or cooling) will roughly equal the annual heating (or cooling) building load reported above.

Component loads disaggregated by Heating/Cooling are listed below.

  =================================================  =========================================================================================================
  Type                                               Notes
  =================================================  =========================================================================================================
  Component Load: \*: Roofs (MBtu)                   Heat gain/loss through HPXML ``Roof`` elements adjacent to conditioned space
  Component Load: \*: Ceilings (MBtu)                Heat gain/loss through HPXML ``Floor`` elements (inferred to be ceilings) adjacent to conditioned space
  Component Load: \*: Walls (MBtu)                   Heat gain/loss through HPXML ``Wall`` elements adjacent to conditioned space
  Component Load: \*: Rim Joists (MBtu)              Heat gain/loss through HPXML ``RimJoist`` elements adjacent to conditioned space
  Component Load: \*: Foundation Walls (MBtu)        Heat gain/loss through HPXML ``FoundationWall`` elements adjacent to conditioned space
  Component Load: \*: Doors (MBtu)                   Heat gain/loss through HPXML ``Door`` elements adjacent to conditioned space
  Component Load: \*: Windows Conduction (MBtu)      Heat gain/loss attributed to conduction through HPXML ``Window`` elements adjacent to conditioned space
  Component Load: \*: Windows Solar (MBtu)           Heat gain/loss attributed to solar gains through HPXML ``Window`` elements adjacent to conditioned space
  Component Load: \*: Skylights Conduction (MBtu)    Heat gain/loss attributed to conduction through HPXML ``Skylight`` elements adjacent to conditioned space
  Component Load: \*: Skylights Solar (MBtu)         Heat gain/loss attributed to solar gains through HPXML ``Skylight`` elements adjacent to conditioned space
  Component Load: \*: Floors (MBtu)                  Heat gain/loss through HPXML ``Floor`` elements (inferred to be floors) adjacent to conditioned space
  Component Load: \*: Slabs (MBtu)                   Heat gain/loss through HPXML ``Slab`` elements adjacent to conditioned space
  Component Load: \*: Internal Mass (MBtu)           Heat gain/loss from internal mass (e.g., furniture, interior walls/floors) in conditioned space
  Component Load: \*: Infiltration (MBtu)            Heat gain/loss from airflow induced by stack and wind effects
  Component Load: \*: Natural Ventilation (MBtu)     Heat gain/loss from airflow through operable windows
  Component Load: \*: Mechanical Ventilation (MBtu)  Heat gain/loss from airflow/fan energy from mechanical ventilation systems
  Component Load: \*: Whole House Fan (MBtu)         Heat gain/loss from airflow due to a whole house fan
  Component Load: \*: Ducts (MBtu)                   Heat gain/loss from conduction and leakage losses through supply/return ducts outside conditioned space
  Component Load: \*: Internal Gains (MBtu)          Heat gain/loss from appliances, plug loads, water heater tank losses, etc. in the conditioned space
  Component Load: \*: Lighting (MBtu)                Heat gain/loss from lighting in the conditioned space
  =================================================  =========================================================================================================

Annual Hot Water Uses
~~~~~~~~~~~~~~~~~~~~~

Annual hot water uses are listed below.

  ===================================  ====================
  Type                                 Notes
  ===================================  ====================
  Hot Water: Clothes Washer (gal)
  Hot Water: Dishwasher (gal)
  Hot Water: Fixtures (gal)            Showers and faucets.
  Hot Water: Distribution Waste (gal)
  ===================================  ====================

.. note::

  All values are gallons of *hot* water (e.g., at water heater setpoint), not *total* water (e.g., at the fixture temperature).

Resilience
~~~~~~~~~~

Resilience outputs are listed below.

  ===================================  ====================
  Type                                 Notes
  ===================================  ====================
  Resilience: Battery (hr)             Not used by OS-ERI
  ===================================  ====================

HVAC Capacities
~~~~~~~~~~~~~~~

System outputs are listed below.
Autosized HVAC systems are based on HVAC design temperatures/loads described below.
Capacities for individual HVAC systems can be found in the, e.g., ERIReferenceHome.xml file.

  ====================================================  ====================
  Type                                                  Notes
  ====================================================  ====================
  HVAC Capacity: Cooling (Btu/h)                        Total HVAC cooling capacity
  HVAC Capacity: Heating (Btu/h)                        Total HVAC heating capacity
  HVAC Capacity: Heat Pump Backup (Btu/h)               Total HVAC heat pump backup capacity
  ====================================================  ====================

HVAC Design Temperatures
~~~~~~~~~~~~~~~~~~~~~~~~

Design temperatures are used in the design load calculations for autosizing of HVAC equipment.
1%/99% design temperatures are obtained from the DESIGN CONDITIONS header section inside the EPW weather file.
If they are not available in the EPW header, the design temperatures are calculated from the 8760 hourly temperatures in the EPW.
Design temperatures can also be found in the, e.g., ERIReferenceHome.xml file.

  =====================================================================  ====================
  Type                                                                   Notes
  =====================================================================  ====================
  HVAC Design Temperature: Heating (F)                                   99% heating drybulb temperature
  HVAC Design Temperature: Cooling (F)                                   1% cooling drybulb temperature
  =====================================================================  ====================

HVAC Design Loads
~~~~~~~~~~~~~~~~~

Design load outputs, used for autosizing of HVAC equipment, are listed below.
Design loads are based on block load ACCA Manual J calculations using 1%/99% design temperatures.
Design loads can also be found in the, e.g., ERIReferenceHome.xml file.

  =====================================================================  ====================
  Type                                                                   Notes
  =====================================================================  ====================
  HVAC Design Load: Heating: Total (Btu/h)                               Total heating design load
  HVAC Design Load: Heating: Ducts (Btu/h)                               Heating design load for ducts
  HVAC Design Load: Heating: Windows (Btu/h)                             Heating design load for windows
  HVAC Design Load: Heating: Skylights (Btu/h)                           Heating design load for skylights
  HVAC Design Load: Heating: Doors (Btu/h)                               Heating design load for doors
  HVAC Design Load: Heating: Walls (Btu/h)                               Heating design load for walls
  HVAC Design Load: Heating: Roofs (Btu/h)                               Heating design load for roofs
  HVAC Design Load: Heating: Floors (Btu/h)                              Heating design load for floors
  HVAC Design Load: Heating: Slabs (Btu/h)                               Heating design load for slabs
  HVAC Design Load: Heating: Ceilings (Btu/h)                            Heating design load for ceilings
  HVAC Design Load: Heating: Infiltration (Btu/h)                        Heating design load for infiltration
  HVAC Design Load: Heating: Ventilation (Btu/h)                         Heating design load for ventilation
  HVAC Design Load: Heating: Piping (Btu/h)                              Heating design load for hydronic piping (not used by OS-ERI)
  HVAC Design Load: Cooling Sensible: Total (Btu/h)                      Total sensible cooling design load
  HVAC Design Load: Cooling Sensible: Ducts (Btu/h)                      Sensible cooling design load for ducts
  HVAC Design Load: Cooling Sensible: Windows (Btu/h)                    Sensible cooling design load for windows
  HVAC Design Load: Cooling Sensible: Skylights (Btu/h)                  Sensible cooling design load for skylights
  HVAC Design Load: Cooling Sensible: Doors (Btu/h)                      Sensible cooling design load for doors
  HVAC Design Load: Cooling Sensible: Walls (Btu/h)                      Sensible cooling design load for walls
  HVAC Design Load: Cooling Sensible: Roofs (Btu/h)                      Sensible cooling design load for roofs
  HVAC Design Load: Cooling Sensible: Floors (Btu/h)                     Sensible cooling design load for floors
  HVAC Design Load: Cooling Sensible: Slabs (Btu/h)                      Sensible cooling design load for slabs
  HVAC Design Load: Cooling Sensible: Ceilings (Btu/h)                   Sensible cooling design load for ceilings
  HVAC Design Load: Cooling Sensible: Infiltration (Btu/h)               Sensible cooling design load for infiltration
  HVAC Design Load: Cooling Sensible: Ventilation (Btu/h)                Sensible cooling design load for ventilation
  HVAC Design Load: Cooling Sensible: Internal Gains (Btu/h)             Sensible cooling design load for internal gains
  HVAC Design Load: Cooling Sensible: Blower Heat (Btu/h)                Sensible cooling design load for blower fan heat (not used by OS-ERI)
  HVAC Design Load: Cooling Sensible: AED Excursion (Btu/h)              Sensible cooling design load for Adequate Exposure Diversity (AED) excursion
  HVAC Design Load: Cooling Latent: Total (Btu/h)                        Total latent cooling design load
  HVAC Design Load: Cooling Latent: Ducts (Btu/h)                        Latent cooling design load for ducts
  HVAC Design Load: Cooling Latent: Infiltration (Btu/h)                 Latent cooling design load for infiltration
  HVAC Design Load: Cooling Latent: Ventilation (Btu/h)                  Latent cooling design load for ventilation
  HVAC Design Load: Cooling Latent: Internal Gains (Btu/h)               Latent cooling design load for internal gains
  =====================================================================  ====================

.. _home_timeseries_outputs_csv:

Home Timeseries Outputs (CSV)
-----------------------------

See the :ref:`running` section for requesting timeseries outputs.
When requested, a CSV file of timeseries outputs is written for the Reference/Rated Homes (e.g., ``ReferenceHome_Hourly.csv``, ``ReferenceHome_Daily.csv``, or ``ReferenceHome_Monthly.csv`` for the Reference home).

Depending on the outputs requested, CSV files may include:

  =======================  ===================  ================================================================================================================================================
  Type                     Argument [#]_        Notes
  =======================  ===================  ================================================================================================================================================
  Total Consumptions       ``total``            Energy use for building total and net (i.e., subtracts any power produced by PV).
  Fuel Consumptions        ``fuels``            Energy use for each fuel type (in kBtu for fossil fuels and kWh for electricity).
  End Use Consumptions     ``enduses``          Energy use for each end use type (in kBtu for fossil fuels and kWh for electricity).
  System Use Consumptions  ``systemuses``       Energy use for each HVAC and water heating system (in kBtu).
  Emissions                ``emissions``        Emissions (CO2e, NOx, SO2).
  Emission Fuels           ``emissionfuels``    Emissions (CO2e, NOx, SO2) disaggregated by fuel type.
  Emission End Uses        ``emissionenduses``  Emissions (CO2e, NOx, SO2) disaggregated by end use.
  Hot Water Uses           ``hotwater``         Water use for each end use type (in gallons).
  Total Loads              ``loads``            Heating, cooling, and hot water loads (in kBtu).
  Component Loads          ``componentloads``   Heating and cooling loads (in kBtu) disaggregated by component (e.g., Walls, Windows, Infiltration, Ducts, etc.).
  Unmet Hours              ``unmethours``       Heating and cooling unmet hours.
  Zone Temperatures        ``temperatures``     Zone temperatures (in deg-F) for each space (e.g., conditioned space, attic, garage, basement, crawlspace, etc.) plus heating/cooling setpoints.
  Zone Conditions          ``conditions``       Zone conditions (humidity ratio and relative humidity and dewpoint, radiant, and operative temperatures)
  Airflows                 ``airflows``         Airflow rates (in cfm) for infiltration, mechanical ventilation, natural ventilation, and whole house fans.
  Weather                  ``weather``          Weather file data including outdoor temperatures, relative humidity, wind speed, and solar.
  =======================  ===================  ================================================================================================================================================

  .. [#] This is the argument provided to ``energy_rating_index.rb`` as described in the :ref:`running` usage instructions.

Timeseries outputs can be one of the following frequencies: hourly, daily, or monthly.

Timestamps in the output use the start-of-period convention.
Most outputs will be summed over the hour (e.g., energy) but some will be averaged over the hour (e.g., temperatures, airflows).

.. _home_configurations_hpxml:

Home Configurations (HPXML)
---------------------------

Based on which calculations were requested in the HPXML file, home configuration details in HPXML format will be found in the ``results`` directory for each simulated home.
The HPXML files will have the same filename as the :ref:`home_annual_outputs_csv` output files, but with a .xml extension instead of .csv.
The files reflect the configuration of the home after applying, e.g., the ERI 301 ruleset.

The files will also show HPXML default values that are applied as part of modeling the home.
Defaults will be applied for a few different reasons:

#. Optional ERI inputs aren't provided (e.g., ventilation rate for a vented attic, SHR for an air conditioner, etc.)
#. Modeling assumptions (e.g., 1 hour timestep, Jan 1 - Dec 31 run period, appliance schedules, etc.)
#. HVAC sizing calculations (e.g., autosized HVAC capacities and airflow rates, heating/cooling design temperatures and loads)

Any defaulted values will include the ``dataSource='software'`` attribute in the HPXML file.

.. _home_energyplus_files:

Home EnergyPlus Files
---------------------

In addition, raw EnergyPlus simulation input/output files are available for each simulation (e.g., ``RatedHome``, ``ReferenceHome``, etc. directories).

.. warning::

  It is highly discouraged for software tools to read the raw EnergyPlus output files.
  The EnergyPlus input/output files are made available for inspection, but the outputs for certain situations can be misleading if one does not know how the model was created.
  If there are additional outputs of interest that are not available in the annual/timeseries output files, please send us a request.

.. _hers_diagnostic_output:

HERS Diagnostic Output
----------------------

A HERS diagnostic output file (``ERI_<Version>/results/HERS_Diagnostic.json``) can be produced if the ``--output-diagnostic`` commandline argument is used; see the :ref:`running` section.
The output file includes hourly data and is formatted per the `HERS Diagnostic Output Schema <https://github.com/resnet-us/hers-diagnostic-schema>`_.
