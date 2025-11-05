## OpenStudio-ERI v1.11.0

__New Features__
- Updates to HPXML v4.2.
- Updates shared pump power for ground-source heat pumps on a shared recirculation loop to cycle with heating/cooling load rather than operate continuously per RESNET HERS Addendum 94.
- Improves electric water heater tank losses when using `EnergyFactor` as the metric; now consistent with how `UniformEnergyFactor` is handled.
- Allows multiple PV inverters with different efficiencies and uses a weighted-average efficiency in the model (previously threw an error).
- Updated DX heat pump and air conditioner models per latest draft of RESNET HERS Addendum 82.
- **Breaking change**: Adds RESNET HERS Addendum 77 to adjust HPWH performance when installed in confined space, used when ERI version is "latest".
  - A new `extension/HPWHInConfinedSpaceWithoutMitigation` input is now required for HPWHs; when true, `extension/HPWHContainmentVolume` is also required.
- Updates to DOE Efficient New Homes program
  - Updates Single Family Version 2 to Rev 3 and Multifamily Version 2 to Rev 2.
  - **Breaking change**: Replaces all references to "ZERH" with "DENH" (e.g., renames `ZERHCalculation` to `DENHCalculation` and renames various output products).

__Bugfixes__
- Fixes an EMS bug in heat pump defrost models that over-estimates defrost fractions.
- Fixes possibility of "Sum of energy consumptions ... do not match total" error when there are multiple HVAC/DHW systems whose load fractions don't sum to 1.

## OpenStudio-ERI v1.10.0

__New Features__
- Updates to OpenStudio 3.10/EnergyPlus 25.1/HPXML v4.2-rc2.
- **Breaking change**: ERI version of "latest" now includes RESNET HERS addenda not yet incorporated in ANSI 301.
  - Adds RESNET HERS Addenda 81 and 90f for "latest" (updates calculations for dishwashers, clothes washers, fixtures, and hot water waste).
- Updated DX heat pump and air conditioner models per RESNET HERS Addendum 82.
  - **Breaking change**: `CompressorType` required for central and mini-split air conditioners and heat pumps.
  - **Breaking change**: `HeatingCapacity17F` required for central and mini-split heat pumps; deprecates `HeatingCapacityRetention`.
  - **Breaking change**: EER2 or EER inputs (`AnnualCoolingEfficiency[Units="EER2" or Units="EER"]/Value`) required for central and mini-split air conditioners and heat pumps.
  - **Breaking change**: `BackupHeatingLockoutTemperature` and `BackupHeatingSwitchoverTemperature` inputs are no longer allowed.
  - **Breaking change**: `CompressorLockoutTemperature` is no longer allowed for HPs w/ fossil fuel backup; it is only allowed for HPs with electric backup or no backup.
  - **Breaking change**: SHR inputs (e.g., `CoolingSensibleHeatFraction`) are no longer allowed.
  - Allows optional design airflow rate inputs (`extension/HeatingDesignAirflowCFM` and `extension/CoolingDesignAirflowCFM`) to be used when the blower fan airflow is measured.
  - Allows optional `extension/FanMotorType` input for central equipment.
  - Allows optional `extension/EquipmentType` inputs for central air conditioners and heat pumps; only used for SEER/SEER2, EER/EER2, and HSPF/HSPF2 conversions.
- Allows multiple versions of a given program (e.g., ENERGY STAR 3.2 and 3.3) to be calculated in a single call.
  - **Breaking change**: Output directories and files have been reorganized/renamed (output file contents are not changed in any way).
- Allows specifying the number of parallel processors to use for simulations with `-n <NUM>` or `--num-proc <NUM>`.
- Infiltration improvements:
  - Improves defaulting for `InfiltrationHeight`.
  - Allows optional `WithinInfiltrationVolume` input for conditioned basements; defaults to true.
  - `AverageCeilingHeight` is no longer used (for infiltration calculations, Hf = InfiltrationVolume/CFA).
- Output updates:
  - Adds new outputs for *net* peak electricity (summer/winter/annual); same as *total* peak electricity outputs but subtracts power produced by PV.
  - Adds generator electricity produced to *total* fuel/energy use; previously it was only included in *net* values.

__Bugfixes__
- Fixes 301validator schematron file extension (.sch, not .xml).
- Fixes U-factor for floors over 'other multifamily buffer space' per ENERGY STAR MFNC Rev 05.
- Fixes modeling of 0.3 ACHnatural infiltration minimum for MF dwelling units where Aext < 0.5 and the mechanical ventilation system is solely exhaust-only.
- Fixes ZERH Target Home and ESRD so that dual-fuel heat pumps are preserved.
- Fixes battery charging/discharging not being included in peak electricity outputs.
- Fixes error if there's a vented attic with zero roof pitch.

## OpenStudio-ERI v1.9.4

__New Features__
- Adds ENERGY STAR ERI calculation for SFNH National v3.3 and MFNC National v1.3.
- Updates to ENERGY STAR SFNH Rev 14 and MFNC Rev 05.
  - **Breaking change**: Building types "single-family detached" and "single-family attached" may only be used for SFNC versions and "apartment unit" may only be used for MFNC versions.
  - ENERGY STAR MFNC National 1.2 now uses 100% LED lighting.
- `WeatherStation/extension/EPWFilePath` is now optional; if not provided, the closest TMY3 weather station will be automatically selected based on the zip code.
- Improves eGrid/Cambium region lookup by zipcode when an exact match is not found.

__Bugfixes__
- Fixes ZERH Target Home and ESRD so that operable window fraction (for natural ventilation) from the Rated Home is preserved.
- Fixes possible error if there's a surface w/ interior unconditioned space and exterior "other housing unit".

## OpenStudio-ERI v1.9.3

__Bugfixes__
- Fixes possibility of ERI Rated Home having extra balanced supplemental ventilation due to floating point comparison.

## OpenStudio-ERI v1.9.2

__New Features__
- Updates HERS test outputs to match the latest RESNET accreditation forms.

## OpenStudio-ERI v1.9.1

__Bugfixes__
- Fixes clothes washer configurations for ZERH v2 and ENERGY STAR SFNH 3.2/MFNC 1.2 programs when the rated home does not include a clothes washer.

## OpenStudio-ERI v1.9.0

__New Features__
- Updates to OpenStudio 3.9/EnergyPlus 24.2/HPXML v4.1-rc1.
- Adds 2024 IECC ERI pathway calculation.
- **Breaking change**: Renamed `Emissions: <EmissionsType>: RESNET: XXX` to `Emissions: <EmissionsType>: ANSI301: XXX` in Annual Home CSV output files.
- Implements ANSI/RESNET/ICC Standard 301-2022 Addendum E for CFIS systems.
  - `ERICalculation/Version` and `CO2IndexCalculation/Version` can now be "2022CE".
  - **Breaking change**: Removes `FanPower`/`FanPowerDefaulted` and `VentilationOnlyModeAirflowFraction` inputs for CFIS systems.
  - **Breaking change**: Adds `CFISControls/HasOutdoorAirControl` and `CFISControls/extension/ControlType` inputs for CFIS systems.
  - Adds choice of "none" for `CFISControls/AdditionalRuntimeOperatingMode` input for CFIS systems.
  - Adds optional `CFISControls/extension/SupplementalFanRunsWithAirHandlerFan` input for CFIS systems.
- Adds inputs for modeling skylight curbs and/or shafts.
- Relaxes IECC climate zone requirements.
  - IECC climate zone years other than 2006 are now always optional; for programs that use specific IECC climate zone years (e.g., 2021 for ZERH SF 2.0), that year is used if provided, otherwise the next earliest provided year will be used with the assumption that the climate zone has not changed across the years.
  - See [the documentation](https://openstudio-eri.readthedocs.io/en/latest/workflow_inputs.html#hpxml-climate-zones) for more information.
- Updates HERS Diagnostic Output to v0.3.0.

__Bugfixes__
- Adds error-checking for `NumberofConditionedFloorsAboveGrade`=0, which is not allowed per the documentation.
- Fixes error if a heating system and a heat pump (that only provides cooling) are attached to the same distribution system.
- Fixes double counting of battery storage losses in ERI calculation; CO2e Index is unaffected.
- Misc Manual J design load calculation improvements.
- Fixes GSHP rated fan/pump powers in net to gross calculations.

## OpenStudio-ERI v1.8.0

__New Features__
- Updates to OpenStudio 3.8, EnergyPlus 24.1, HPXML 4.0-rc4.
- Implements ANSI/RESNET/ICC Standard 301-2022 and Addendum C.
  - **Breaking change**: For shared water heaters, `NumberofUnitsServed` is replaced by `extension/NumberofBedroomsServed`.
  - **Breaking change**: For shared hot water recirculation systems, `NumberofUnitsServed` is replaced by `NumberofBedroomsServed`.
  - `ERICalculation/Version` and `CO2IndexCalculation/Version` can now be "2022C" or "2022".
  - Allows modeling electric battery storage, including shared batteries ("2022C" or newer).
  - The `ElectricAuxiliaryEnergy` input for boilers is no longer used.
- **Breaking change**: ERI_Results.csv and ERI_Worksheet.csv combined into a single ERI_Results.csv that better reflects the current ERI calculation components; additional fields (e.g., PEfrac) added and a few renamed/removed.
- **Breaking change**: Skylights attached to roofs of attics (e.g., with shafts or sun tunnels) must include the `Skylight/AttachedToFloor` element.
- **Breaking change**: Each `VentilationFan` must have one (and only one) `UsedFor...` element set to true.
- HERS software tests:
  - HERS Hot Water test HPXMLs have been updated to be direct EnergyPlus simulations (like the HERS HVAC & DSE tests already were); they are no longer run through ERI simulations.
  - HERS HVAC DSE tests now use duct effective R-values instead of nominal insulation R-values to demonstrate that they pass RESNET acceptance criteria.
- Adds `--diagnostic-output` commandline argument to produce a diagnostic output file per the [HERS Diagnostic Output Schema](https://github.com/resnet-us/hers-diagnostic-schema).
- Allows `AverageCeilingHeight` to be optionally provided for infiltration calculations.
- Allows `Roof/RadiantBarrier` to be omitted; defaults to false.
- Allows `FractionDuctArea` as alternative to `DuctSurfaceArea`
- Allows alternative `LabelEnergyUse` (W) input for ceiling fans.
- Allows `Slab/extension/GapInsulationRValue` input for cases where a slab has horizontal (under slab) insulation.
- Ground source heat pump model enhancements.
- Improves heating/cooling component loads.
- Now defaults to -20F for `CompressorLockoutTemperature` for variable-speed air-to-air heat pumps.
- Adds more error-checking for inappropriate inputs (e.g., HVAC SHR=0 or clothes washer IMEF=0).
- Clarifies that HVAC `Capacity=-1` can be used to autosize HVAC equipment for research purposes or to run tests. It should *not* be used for a real home, and a warning will be issued when it's used.

__Bugfixes__
- Fixes incorrect Reference Home mechanical ventilation flowrate for attached units (when Aext is not 1).
- Fixes possible 301ruleset.rb error due to floating point arithmetic.

## OpenStudio-ERI v1.7.1

__Bugfixes__
- Fixes emissions lookup when zip code starts with a zero.

## OpenStudio-ERI v1.7.0

__New Features__
- Updates to OpenStudio 3.7.0/EnergyPlus 23.2.
- **Breaking change**: Updates to HPXML v4.0-rc2:
  - HPXML namespace changed from http://hpxmlonline.com/2019/10 to http://hpxmlonline.com/2023/09.
  - Replaces "living space" with "conditioned space", which better represents what is modeled.
  - Replaces `PortableHeater` and `FixedHeater` with `SpaceHeater`.
- HVAC updates:
  - Updated assumptions for variable-speed air conditioners, heat pumps, and mini-splits based on NEEP data. Expect results to change, potentially significantly so depending on the scenario.
  - Updates deep ground temperatures (used for modeling ground-source heat pumps) using L. Xing's simplified design model (2014).
  - Replaces inverse calculations, used to calculate COPs from rated efficiencies, with regressions for single/two-speed central ACs and ASHPs.
- Output updates:
  - **Breaking change**: Disaggregates "EC_x Vent" and "EC_x Dehumid" from "EC_x L&A" in `ERI_Results.csv`.
  - Adds "Peak Electricity: Annual Total (W)" output.
- Relaxes requirements for some inputs:
  - `SolarAbsorptance` and `Emittance` now only required for *exterior* walls & rim joists (i.e., ExteriorAdjacentTo=outside).
  - `Window/PerformanceClass` no longer required (defaults to "residential").
  - Allows above-grade basements/crawlspaces defined solely with Wall (not FoundationWall) elements.
- Adds ZERH Multifamily v2.
- Updates to ZERH Single Family v2 windows SHGC in climate zone 4 through 8.
- Allow JSON output files instead of CSV via a new `--output-format JSON` commandline argument.

__Bugfixes__
- Fixes possible "Electricity category end uses do not sum to total" error for a heat pump w/o backup.
- Fixes error if conditioned basement has `InsulationSpansEntireSlab=true`.
- Fixes error if heat pump `CompressorLockoutTemperature` == `BackupHeatingLockoutTemperature`.
- Fixes ground source heat pump fan/pump adjustment to rated efficiency.
- Fixes missing radiation exchange between window and sky.
- Minor HVAC design load calculation bugfixes for foundation walls.
- Fixes `nEC_x` calculation for a fossil fuel water heater w/ UEF entered.
- Various HVAC sizing bugfixes and improvements.

## OpenStudio-ERI v1.6.3

__Bugfixes__
- Fixes possible "Sum of energy consumptions do not match total" error for shared water heater w/ FractionDHWLoadServed=0.

## OpenStudio-ERI v1.6.2

__Bugfixes__
- Fixes incorrect ESRD ceiling U-factor for SFA unit with adiabatic ceiling when using SFNH program.

## OpenStudio-ERI v1.6.1

__Bugfixes__
- Fixes ZERH Single Family v2 mechanical ventilation fan efficiency to use ASRE instead of SRE.
- Fixes error if describing a wall with `WallType/StructuralInsulatedPanel`.

## OpenStudio-ERI v1.6.0

__New Features__
- Updates to OpenStudio 3.6.1/EnergyPlus 23.1.
- **Breaking change**: CO2e Index results must now be requested through a new optional `SoftwareInfo/extension/CO2IndexCalculation/Version` input.
- **Breaking change**: Updates to newer proposed HPXML v4.0:
  - Replaces `CeilingFan/Quantity`, `ClothesWasher/NumberofUnits`, and `ClothesDryer/NumberofUnits` with `Count`.
  - Replaces `PVSystem/InverterEfficiency` with `PVSystem/AttachedToInverter` and `Inverter/InverterEfficiency`.
- Output updates:
  - **Breaking change**: Adds `End Use: Heating Heat Pump Backup Fans/Pumps` (disaggregated from `End Use: Heating Fans/Pumps`).
  - **Breaking change**: Replaces `Component Load: Windows` with `Component Load: Windows Conduction` and `Component Load: Windows Solar`.
  - **Breaking change**: Replaces `Component Load: Skylights` with `Component Load: Skylights Conduction` and `Component Load: Skylights Solar`.
  - **Breaking change**: Adds `Component Load: Lighting` (disaggregated from `Component Load: Internal Gains`).
  - **Breaking change**: Adds "net" values for emissions; "total" values now exclude generation (e.g., PV).
  - Adds `Load: Heating: Heat Pump Backup` (heating load delivered by heat pump backup systems).
  - Adds `System Use` outputs (end use outputs for each heating, cooling, and water heating system); allows requesting timeseries output.
  - All annual load outputs are now provided as timeseries outputs; previously only "Delivered" loads were available.
  - Peak summer/winter electricity outputs are now based on Jun/July/Aug and Dec/Jan/Feb months, not HVAC heating/cooling operation.
- Heat pump enhancements:
  - Allows `HeatingCapacityRetention[Fraction | Temperature]` optional inputs as a more flexible alternative to `HeatingCapacity17F`.
  - Allows `CompressorLockoutTemperature` and `BackupHeatingLockoutTemperature` as optional inputs; alternatives to `BackupHeatingSwitchoverTemperature`.
  - Defaults for `CompressorLockoutTemperature`: 25F for dual-fuel, -20F for mini-split, 0F for all other heat pumps.
  - Defaults for `BackupHeatingLockoutTemperature`: 50F for dual-fuel, 40F for all other heat pumps.
  - Increased consistency between variable-speed central HP and mini-split HP models for degradation coefficients, gross SHR calculations, etc.
- Duct enhancements:
  - Allows modeling ducts buried in attic loose-fill insulation using `Ducts/DuctBuriedInsulationLevel`.
  - The duct effective R-value can now be found in the ERI___Home.xml files; it accounts for exterior air film, duct shape, and buried insulation level.
- Allows additional building air leakage inputs (ACH or CFM at user-specified house pressure, Natural CFM, Effective Leakage Area).
- LightingGroup for garage is no longer required if the home doesn't have a garage.
- Weather cache files (\*foo-cache.csv) are no longer used/needed.

__Bugfixes__
- Adds error-checking to ensure that SFA/MF dwelling units have at least one attached wall/ceiling/floor surface.
- Various Manual J HVAC autosizing calculation bugfixes and improvements.
- Ensure that ductless HVAC systems do not have a non-zero airflow defect ratio specified.

## OpenStudio-ERI v1.5.2

__New Features__
- Adds support for ZERH Single Family v2.
- Updates to ENERGY STAR SFNH Rev 12 and MFNC Rev 03.
- `WaterHeatingSystem/RecoveryEfficiency` is now an optional input.
- Weather cache file (\*-cache.csv) is now optional; if not provided, it will be generated on the fly. Provide the cache file for fastest runtime.
- Provide two decimal places in ENERGY STARS/ZERH CSV output files to better prevent user confusion.
- Uses the same `Floor/FloorType` in the Reference Design as the Rated Home for ENERGY STAR MFNC, as per EPA's request.
- Changes the windows SHGC in CZ4-8 from 0.40 to 0.30 for ENERGY STAR SFNH National v3.2 and MFNC National v1.2 as per EPA's request.

__Bugfixes__
- Bugfixes for ENERGY STAR and ZERH programs.

## OpenStudio-ERI v1.5.1

__Bugfixes__
- Fixes incorrect warning about zip code not found in eGRID/Cambium lookup table.
- Fixes error when a non-electric water heater has jacket insulation and the UEF metric is used.

## OpenStudio-ERI v1.5.0

__New Features__
- Updates to OpenStudio 3.5.0/EnergyPlus 22.2.
- **Breaking change**: Updates to newer proposed HPXML v4.0:
  - Replaces `FrameFloors/FrameFloor` with `Floors/Floor`.
  - `Floor/FloorType` (WoodFrame, StructuralInsulatedPanel, SteelFrame, or SolidConcrete) is a required input.
  - All `Ducts` must now have a `SystemIdentifier`.
  - Replaces `WallType/StructurallyInsulatedPanel` with `WallType/StructuralInsulatedPanel`.
  - Replaces `StandbyLoss` with `StandbyLoss[Units="F/hr"]/Value` for an indirect water heater.
  - Replaces `BranchPipingLoopLength` with `BranchPipingLength` for a hot water recirculation system.
  - Replaces `Floor/extension/OtherSpaceAboveOrBelow` with `Floor/FloorOrCeiling`.
  - For PTAC with heating, replaces `HeatingSystem` of type PackagedTerminalAirConditionerHeating with `CoolingSystem/IntegratedHeating*` elements.
- **Breaking change**: Now performs full HPXML XSD schema validation (previously just limited checks); yields runtime speed improvements.
- Adds ENERGY STAR ERI calculation for SF National v3.2 and MF National v1.2.
- Adds IECC ERI pathway calculation (2015, 2018, 2021).
- Adds Zero Energy Ready Homes calculation for v1.
- Allows SEER2/HSPF2 efficiency types for central air conditioners and heat pumps.
- Allows calculating all programs (e.g., ERI, ENERGY STAR, IECC, etc.) simultaneously while avoiding duplicate EnergyPlus simulations.
  - **Breaking change**: Deprecates energy_star.rb script; energy_rating_index.rb will now run all programs specified in the HPXML.
  - **Breaking change**: The organization of ENERGY STAR output files have changed.
- Allows modeling CFIS ventilation systems with a supplemental fan.
  - **Breaking change**: New `CFISControls/AdditionalRuntimeOperatingMode` input required for CFIS ventilation systems.
- **Breaking change**: The `ClimateZoneIECC/Year` is now more strict:
  - All runs must include a 2006 IECC climate zone.
  - IECC ERI pathway runs must include an IECC climate zone of the same year.
  - ENERGY STAR ERI runs for SF National v3.2 and MF National v1.2 must include a 2021 IECC climate zone.
  - Zero Energy Ready Homes v1 runs must include a 2015 IECC climate zone.
- Allows modeling room air conditioners with heating or reverse cycle.
- Allows shared dishwasher/clothes washer to be attached to a hot water distribution system instead of a single water heater.
- Adds HVAC capacities, design loads, and design temperatures to csv output files.
- Annual/timeseries outputs:
  - Adds annual emission outputs disaggregated by end use; timeseries emission outputs disaggregated by end use can be requested.
  - Allows generating timeseries unmet hours for heating and cooling.
  - Adds heating/cooling setpoints to timeseries outputs when requesting zone temperatures.
- Improves Kiva foundation model heat transfer by providing better initial temperature assumptions based on foundation type and insulation levels.

__Bugfixes__
- Fixes units for Peak Loads (kBtu/hr, not kBtu) in ERI____Home.csv output files.
- Bugfix for increasing HVAC capacities due to installation grading.
- Fixes possible output error for ground source heat pumps with a shared hydronic circulation loop.
- Fixes zero energy use for a ventilation fan w/ non-zero fan power and zero airflow rate.

## OpenStudio-ERI v1.4.4

__Bugfixes__
- Fixes possible simulation error if a slab has an ExposedPerimeter near zero.

## OpenStudio-ERI v1.4.3

__Bugfixes__
- Fixes excessive heat transfer when foundation wall interior insulation does not start from the top of the wall.

## OpenStudio-ERI v1.4.2

__Bugfixes__
- Fixes incorrect ERI calculation when the Rated Home has multiple water heaters.

## OpenStudio-ERI v1.4.1

__Bugfixes__
- Fixes possible error when running HERS Auto-Generation tests.

## OpenStudio-ERI v1.4.0

__New Features__
- Updates to OpenStudio 3.4.0/EnergyPlus 22.1.
- Updates to OpenStudio-HPXML 1.4.0.
- Implements ANSI/RESNET/ICC Standard 301-2019 Addenda C & D. `ERICalculation/Version` can now be "2019ABC" or "2019ABCD" in the HPXML files.
  - Adds calculation of CO2e Rating Index and CO2e/NOx/SO2 emissions (annual and hourly).
  - Adds support for shared hot water recirculation systems controlled by temperature.
  - **Breaking change**: `/HPXML/Building/Site` is now required with `Address/StateCode` and `Address/ZipCode` child elements.
- Output changes:
  - Adds "Energy Use: Total" and "Energy Use: Net" columns to the ERI____Home.csv output files; allows hourly outputs.
  - **Breaking change**: New "End Use: \<Fuel\>: Heating Heat Pump Backup" output, disaggregated from "End Use: \<Fuel\>: Heating".
- **Breaking change**: Deprecates duct leakage to outside exemptions; software tools must provide duct leakage to outside or DSE. `SoftwareInfo/extension/ERICalculation/Version` enumerations "2014ADEGL", "2014ADEG", "2014ADE" are replaced by "2014AEG" and "2014AE".
- **Breaking change**: For CFIS systems, an `extension/VentilationOnlyModeAirflowFraction` input is now required to address duct losses during ventilation only mode.
- Allows `AirInfiltrationMeasurement/InfiltrationHeight` as an optional input; if not provided, it is inferred from other inputs as before.
- Allows duct leakage to be entered in units of CFM50 as an alternative to CFM25.
- Adds a `--skip-simulation` flag that can be used to just generate the ERI Rated/Reference Home HPXMLs and then stop.
- Adds a `--rated-home-only` flag to run only the ERI Rated Home simulation (ERI will not be calculated).
- Simplifies ERI Reference Home configuration with respect to HVAC types and number of DSE distribution systems.

__Bugfixes__
- Fixes opaque door R-value in the Reference Home in IECC climate zone 1.
- Fixes possible NaN result for ERI if, in a very cold climate, the Reference Home has no cooling load.

## OpenStudio-ERI v1.3.0

__New Features__
- Updates to OpenStudio 3.3.0/EnergyPlus 9.6.0.
- **Breaking change**: HVAC grading inputs `FanPowerNotTested`, `AirflowNotTested`, and `ChargeNotTested` are no longer accepted.
- **Breaking change**: Replaces "Unmet Load" outputs with "Unmet Hours".
- **Breaking change**: Renames "Load: Heating" and "Peak Load: Heating" (and Cooling) outputs to include "Delivered".
- **Breaking change**: Any heat pump backup heating requires `HeatPump/BackupType="integrated"` to be specified.
- **Breaking change**: HPXML schema version must now be '4.0' (proposed).
  - Moves `FoundationWall/Insulation/Layer/extension/DistanceToTopOfInsulation` to `FoundationWall/Insulation/Layer/DistanceToTopOfInsulation`.
  - Moves `FoundationWall/Insulation/Layer/extension/DistanceToBottomOfInsulation` to `FoundationWall/Insulation/Layer/DistanceToBottomOfInsulation`.
  - Moves `Slab/PerimeterInsulationDepth` to `Slab/PerimeterInsulation/Layer/InsulationDepth`.
  - Moves `Slab/UnderSlabInsulationWidth` to `Slab/UnderSlabInsulation/Layer/InsulationWidth`.
  - Moves `Slab/UnderSlabInsulationSpansEntireSlab` to `Slab/UnderSlabInsulation/Layer/InsulationSpansEntireSlab`.
- Allows modeling PTAC and PTHP HVAC systems.
- Allows additional fuel types for generators.
- Allows non-zero refrigerant charge defect ratios for ground source heat pumps.
- Allows CEER (Combined Energy Efficiency Ratio) efficiency unit for room AC.
- Allows specifying the foundation wall type (e.g., solid concrete, concrete block, wood, etc.).
- Removes error-check for number of bedrooms based on conditioned floor area, per RESNET guidance.
- Introduces a small amount of infiltration for unvented spaces.
- `ConditionedBuildingVolume` input is no longer needed.
- Improves consistency of installation quality calculations for two/variable-speed air source heat pumps and ground source heat pumps.

__Bugfixes__
- Improves ground reflectance for window interior shading.
- Improves HVAC fan power for central forced air systems.
- Fixes mechanical ventilation compartmentalization area calculation for SFA/MF homes with surfaces with InteriorAdjacentTo==ExteriorAdjacentTo.
- Negative `DistanceToTopOfInsulation` values are now disallowed.
- Fixes workflow errors if a `VentilationFan` has zero airflow rate or zero hours of operation.
- Fixes heating/cooling seasons (used for e.g. summer vs winter window shading) for the southern hemisphere.
- Relaxes `Overhangs` DistanceToBottomOfWindow vs DistanceToBottomOfWindow validation when Depth is zero.
- Fixes possibility of "Construction R-value ... does not match Assembly R-value" error.

## OpenStudio-ERI v1.2.1

__New Features__
- Revises shared mechanical ventilation preconditioning control logic to operate less often.

## OpenStudio-ERI v1.2.0

__New Features__
- Adds ENERGY STAR ERI Target workflow for new construction in accordance with [ENERGY STAR Certification System for Homes and Apartments Using an Energy Rating Index-Based Compliance Path](https://www.energystar.gov/sites/default/files/asset/document/ENERGY%20STAR%20Certification%20System.pdf).
  - Optional `SoftwareInfo/extension/EnergyStarCalculation/Version` (values like "SF_National_3.1"; required if running ENERGY STAR calculation).
  - **Breaking change**: `Building/Site/Address/StateCode` (values like "CO" or "FL") now required.
  - **Breaking change**: For windows, `Window/PerformanceClass` (values of "residential" or "architectural") now required.
  - **Breaking change**: For shared boilers, `HeatingSystem/HeatingCapacity`, `HeatingSystem/extension/SharedLoopWatts`, and `HeatingSystem/extension/FanCoilWatts` (fan coil only) now required.
  - **Breaking change**: For air distribution systems with ducts, `AirDistribution/NumberofReturnRegisters` now required.
  - **Breaking change**: For shared recirculation hot water systems, `HotWaterDistribution/extension/SharedRecirculation/PumpPower` now required.
  - Optional `extension/SharedLoopMotorEfficiency` for shared boilers, chillers, cooling towers, and GSHPs w/ shared loop and `extension/SharedRecirculation/MotorEfficiency` for shared recirculation hot water systems.
- **Breaking change**: Heating/cooling component loads no longer calculated by default for faster performance; use `--add-component-loads` argument if desired.
- Allows `DuctLeakageMeasurement` & `ConditionedFloorAreaServed` to not be specified for ductless fan coil systems; **Breaking change**: `AirDistributionType` is now required for all air distribution systems.
- Switches room air conditioner model to use Cutler performance curves.
- Shared systems now preserved in the Rated Home (as opposed to configuring, e.g., the equivalent central AC w/ SEEReq for a chiller).
- Removes limitation that a shared water heater serving a shared laundry room can't also serve dwelling unit fixtures (i.e., FractionDHWLoadServed is no longer required to be zero).
- When Reference/Rated water heater fuels are determined by predominant water/space heating fuels, fossil fuel is now selected in the case of a tie.
- Adds IDs to schematron validation errors/warnings when possible.

__Bugfixes__
- Prevents a solar hot water system w/ SolarFraction=1.
- Fixes room air conditioner performance curve.
- Fixes heating load fractions for boiler w/ WLHP.
- Water loop heat pumps no longer get added electric backup heating in the Rated Home.

## OpenStudio-ERI v1.1.2

__New Features__
- Revises shared mechanical ventilation preconditioning control logic to operate less often.

## OpenStudio-ERI v1.1.1

__New Features__
- Allow `Slab/ExposedPerimeter` to be zero.
- `ClothesDryer/ControlType` is no longer required if 301 version >= 2019A
- Moves additional error-checking from the ruby measure to the schematron validator.
- Adds more detail to error messages regarding the wrong data type in the HPXML file.
- Adds error-checking for negative SEEReq results for shared cooling systems.
- Relaxes tolerance for duct leakage to outside warning when ducts solely in conditioned space.

__Bugfixes__
- Fixes ruby error if elements (e.g., `SystemIdentifier`) exist without the proper 'id'/'idref' attribute.
- Fixes error if boiler/GSHP pump power is zero.
- Fixes possible "Electricity category end uses do not sum to total" error due to boiler pump energy.
- Fixes possible "Construction R-value ... does not match Assembly R-value" error for highly insulated enclosure elements.

## OpenStudio-ERI v1.1.0

__New Features__
- Implements ANSI/RESNET/ICC Standard 301-2019 Addendum B. `ERICalculation/Version` can now be "2019AB" in the HPXML files.
  - **Breaking change**: New HVAC installation quality inputs required for air conditioners, heat pumps, and furnaces.
  - Adds modeling of dehumidifiers.
- Adds modeling of generators (generic on-site power production).
- Adds modeling of mini-split air conditioners.
- Allows requesting hourly unmet heating/cooling loads.
- Includes hot water loads (in addition to heating/cooling loads) when hourly total loads are requested.
- **Breaking change**: Simplifies inputs for fan coils and water loop heat pumps by A) removing HydronicAndAirDistribution element and B) moving WLHP inputs from extension elements to HeatPump element.
- **Breaking change**: One of the three duct leakage input types is now required for AirDistribution systems.
- **Breaking change**: For ERI____Home.csv output files, the first two sections are now prefixed with "Fuel Use:" and "End Use:", respectively.
- Adds HPXML default values (e.g., Reference Home autosized HVAC capacities) to the four ERI____Home.xml files.
- Overhauls documentation to be more comprehensive and standardized.

__Bugfixes__
- Improved modeling of window/skylight interior shading -- better reflects shading coefficient inputs.
- Adds various error-checking to the schematron validator.
- Adds error-checking for empty IDs in the HPXML file.
- Fixes possible "Error: Electricity category end uses (X) do not sum to total (X)." for a heat pump water heater.
- Fixes possible OpenStudio ForwardTranslator "surface construction conflicts" errors.
- HVAC sizing improvements for floors above crawlspaces/basements and walls.
- Fixes schematron file not being valid per ISO Schematron standard.
- Fixes error when using energy_rating_index.rb --cache-weather.

## OpenStudio-ERI v1.0.0

__New Features__
- Updates to OpenStudio 3.1.0/EnergyPlus 9.4.0.
- **Breaking change**: Deprecates `WeatherStation/WMO` HPXML input, use `WeatherStation/extension/EPWFilePath` instead.
- Implements water heater Uniform Energy Factor (UEF) model; replaces RESNET UEF->EF regression. **Breaking change**: `FirstHourRating` is now a required input for storage water heaters when UEF is provided.
- Adds optional HPXML fan power inputs for most HVAC system types. **Breaking change**: Removes ElectricAuxiliaryEnergy input for non-boiler heating systems.
- Uses air-source heat pump cooling performance curves for central air conditioners.
- Accommodates common walls adjacent to unconditioned space by using HPXML surfaces where InteriorAdjacentTo == ExteriorAdjacentTo.
- Additional validation checks and error-checking.
- Various small updates to ASHRAE 140 test files.
- Release packages now include RESNET HERS test files/results; all tests pass RESNET's proposed stringent acceptance criteria.

__Bugfixes__
- EnergyPlus 9.4.0 fix for negative window solar absorptances at certain hours.
- Fixes ceiling fan configuration in Reference/Rated Homes for 301-2019.
- Fixes airflow timeseries outputs to be averaged instead of summed.

## OpenStudio-ERI v0.11.0 Beta

__New Features__
- New [Schematron](http://schematron.com) validation (301validator.xml) replaces custom ruby validation (301validator.rb)
- Ability to model shared systems for Attached/Multifamily dwelling units
  - Shared HVAC systems (cooling towers, chillers, central boilers, water loop heat pumps, fan coils, ground source heat pumps on shared hydronic circulation loops)
  - Shared water heaters serving either A) multiple dwelling units' service hot water or B) a shared laundry/equipment room, as well as shared hot water recirculation systems
  - Shared appliances (e.g., clothes dryer in a shared laundry room)
  - Shared ventilation systems (optionally with preconditioning equipment and recirculation)
  - Shared PV systems
  - **[Breaking change]** `IsSharedSystem` now required for boilers and ground-to-air heat pumps, water heating systems, ventilation systems, and PV systems
  - **[Breaking change]** `IsSharedAppliance` now required for clothes washers, clothes dryers, and dishwashers
  - **[Breaking change]** Appliances located in MF spaces (i.e., "other") must now be specified in more detail (i.e., "other heated space", "other non-freezing space", "other multifamily buffer space", or "other housing unit")
- Allows multiple mechanical ventilation systems (`VentilationFan`)
- **[Breaking change]** For hydronic distributions, `HydronicDistributionType` is now required
- **[Breaking change]** For DSE distributions, `AnnualHeatingDistributionSystemEfficiency` and `AnnualCoolingDistributionSystemEfficiency` are both always required
- **[Breaking change]** Adds `RadiantBarrierGrade` as a required input if a roof has a radiant barrier
- **[Breaking change]** Adds `extension/PumpPowerWattsPerTon` as a required input for ground-to-air heat pumps
- **[Breaking change]** Renames `DuctLeakageTestingExemption` to `DuctLeakageToOutsideTestingExemption`, to clarify that it is different from the total duct leakage testing exemption in ANSI/RESNET/ACCA 310
- **[Breaking change]** New `FanPowerDefaulted` and `FlowRateNotTested` elements must be provided when ventilation systems have defaulted fan power or unmeasured airflow
- Allows homes without a refrigerator, dishwasher, range/oven, clothes washer, and/or clothes dryer
- Rated Home equipment capacities now automatically increased if smaller than auto-calculated design loads
- Updates Reference Home to have a single water heater even when there are multiple water heaters
- Updates Reference Home unconditioned basement insulation to be the basement ceiling instead of basement walls
- Updates Reference Home conditioned basement insulation R-values per RESNET SCC clarifications
- Various updates to RESNET test files
- Updates ASHRAE 140 tests to use TMY3 instead of TMY weather
- Adds more reporting of warnings/errors to run.log

__Bugfixes__
- Fixes pump energy for boilers and ground source heat pumps
- Fixes incorrect gallons of hot water use reported when there are multiple water heaters
- No longer report unmet load for buildings where the HVAC system only meets part of the load (e.g., room AC serving 33% of the load)
- ASHRAE 140 test files now have only heating or cooling systems, not both

## OpenStudio-ERI v0.10.0 Beta

__New Features__
- Implements ANSI/RESNET/ICC Standard 301-2019 and Addendum A. Shared systems are not yet supported.
  - `ERICalculation/Version` can be "2019A" or "2019"
  - **[Breaking change]** `Attic/WithinInfiltrationVolume` is required for unvented attics
  - **[Breaking change]** `Foundation/WithinInfiltrationVolume` is required for unvented crawlspaces and unconditioned basements
  - `ExteriorAdjacentTo` can be "other heated space", "other multifamily buffer space", or "other non-freezing space" for `Wall`, `RimJoist`, `FoundationWall`, and `FrameFloor` elements
  - `DuctLocation` can be "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space"
  - `WaterHeater/Location` can be "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space"
  - **[Breaking change]** `Location` is now a required element for dishwashers and cooking ranges.
  - `Location` can be "other" for all appliances
  - **[Breaking change]** `Window/FractionOperable` is required
  - `VentilationFan/TestedFlowRate` is now optional and can be excluded for unmeasured mechanical ventilation flow rates
  - `VentilationFan/FanPower` is now optional and can be excluded for unknown mechanical ventilation fan power
  - **[Breaking change]** `LabelUsage` is required for clothes washers
  - **[Breaking change]** `LabelElectricRate`, `LabelGasRate`, `LabelAnnualGasCost`, and `LabelUsage` are required for dishwashers
  - **[Breaking change]** `HVACDistribution/ConditionedFloorAreaServed` is now required for air distribution systems
  - **[Breaking change]** For FrameFloors ExteriorAdjacentTo, "other housing unit above" and "other housing unit below" are replaced with "other housing unit"; floors adjacent to any "other ..." MF space type must have the `extension/OtherSpaceAboveOrBelow` element set to "above" or "below".
- **[Breaking change]** Lighting inputs now use `LightingType[LightEmittingDiode | CompactFluorescent | FluorescentTube]` instead of `ThirdPartyCertification="ERI Tier I" or ThirdPartyCertification="ERI Tier II"`.
- Allows "exterior wall", "under slab", and "roof deck" for `DuctLocation`.
- Allows `PortableHeater`, `Fireplace`, and `FloorFurnace` for heating system types.
- Allows "wood" and "wood pellets" as fuel types for HVAC systems, water heaters, and appliances.
- Allows additional hourly outputs: airflows (e.g., infiltration, mechanical ventilation, natural ventilation, whole house fan) and weather (e.g., temperatures, wind speed, solar).
- Improved inferred infiltration height calculation for homes w/ conditioned basements.
- Reference Home mechanical ventilation that supplements infiltration is now always a balanced system.
- Additional runtime improvements.
- **[Breaking change]** Many changes to HPXML test files to conform to latest RESNET Publication 002.
- ERI____Home.xml files:
  - **[Breaking change]** `WaterHeatingSystem/PerformanceAdjustment` is now a multiplier (e.g., 0.92) instead of a derate (e.g., 0.08).
   - Adds `AirInfiltrationMeasurement/extension/InfiltrationHeight` and `AirInfiltrationMeasurement/extension/Aext` as diagnostic outputs.
- Error-checking:
  - Adds more space type-specific error checking of adjacent surfaces.
  - Adds additional HPXML datatype checks.
  - Adds a warning if a `HVACDistribution` system has ducts entirely within conditioned space and non-zero leakage to the outside.
  - Adds warnings if appliance inputs may be inappropriate and result in negative energy or hot water use.

__Bugfixes__
- Reference Homes w/ ACs & furnaces now use the same W/cfm (derived from EAE) for both heating and cooling.
- Fixes error if a home has both a dual-fuel heat pump and an air-source heat pump.
- Fixes exterior air film and wind exposure of frame floors over ambient conditions.
- Fixes air films for ceiling surfaces.
- Preserve Rated Home appliance locations in the Reference Home.
- Fixes heat pump defrost control to be Timed instead of OnDemand.
- Fixes error if there's a `FoundationWall` whose height is less than 0.5 ft.
- Fixes vented attic ventilation rate.
- Reported unmet heating/cooling load now correctly excludes latent energy.
- Ground-source heat pump backup fuel is now correctly honored instead of always using electricity.

## OpenStudio-ERI v0.9.0 Beta

__New Features__
- **[Breaking change]** Updates to OpenStudio v3.0.0 and EnergyPlus 9.3.
- **[Breaking change]** Allows 301-2014 Addenda D & L to be used by providing inputs for A) duct leakage testing exemptions or B) total duct leakage in lieu of leakage to the outside. These inputs should only be used if the conditions specified in ANSI/RESNET/ICC© 301 have been appropriately met. Enumerations for `SoftwareInfo/extension/ERICalculation/Version` are now "latest", "2014ADEGL", "2014ADEG", "2014ADE", "2014AD", "2014A", "2014".
- **[Breaking change]** `BuildingConstruction/ResidentialFacilityType` is now required. Valid choices are: "single-family detached", "single-family attached", "apartment unit", "manufactured home".
- Improves inferred infiltration height for conditioned basements (including walkout basements).
- A new HPXML input `WeatherStation/extension/EPWFilePath` can be used instead of `WeatherStation/WMO` to point directly to the EPW file of interest.
- Adds hot water outputs (gallons), disaggregated by end use, to annual output. Also available for timeseries outputs.
- Improved desuperheater model; can now be connected to heat pump water heaters.
- Solar thermal systems modeled with `SolarFraction` can now be connected to combi water heating systems.
- Small improvement to calculation of component loads.
- Allows buildings to have HVAC systems that do not condition 100% of the load (i.e., where sum of fraction heat/cool load served is greater than zero and less than one).
- Populates more information in the ERI___Home.xml files (e.g., plug load kWh/yr).
- **[Breaking change]** The `--no-ssl` argument has been deprecated.
- **[Breaking change]** Switches from `BuildingConstruction/extension/FractionofOperableWindowArea` to `Window/FractionOperable` in HPXML test files.

__Bugfixes__
- Fixes an unsuccessful simulation for buildings with multiple HVAC air distribution systems, each with multiple duct locations.
- Fixes an unsuccessful simulation for buildings where the sum of multiple HVAC systems' fraction load served was slightly above 1 due to rounding.
- Small fix for interior partition wall thermal mass model.

## OpenStudio-ERI v0.8.0 Beta

__Breaking changes__
- The `--skip-validation` or `-s` argument has been removed, it's no longer needed now that the primary runtime bottleneck has been addressed.
- ERI____Home.csv output files:
  - Disaggregates "Electricity: Heating Fans/Pumps" from "Electricity: Heating", "Electricity: Cooling Fans/Pumps" from "Electricity: Cooling", and "Electricity: Television" from "Electricity: Plug Loads"
  - Renames "Annual Load" to "Load" and "Annual Unmet Load" to "Unmet Load"
- Requesting hourly output is now done via an `--hourly TYPE` (e.g., `--hourly fuels --hourly temperatures`) argument instead of `--hourly-output`. See documentation for more details.
- Weather cache files are now in .csv instead of .cache format. Re-run `--cache-weather` if using custom weather files.
- `extension/StandbyLoss` changed to `StandbyLoss` for indirect water heaters.
- `Site/extension/DisableNaturalVentilation` changed to `BuildingConstruction/extension/FractionofOperableWindowArea` for ASHRAE 140-based test files.

__New Features__
- Allows modeling of whole-house fans.
- Adds optional `CompressorType` input for ACs/ASHPs.
- Improved natural ventilation algorithm that reduces the potential for incurring additional heating energy.
- Improved calculation of component heating/cooling loads.
- Hot water temperatures are now included in the ERI____Home.xml files.
- Runtime performance improvements, particularly for Windows.
- Additional hourly outputs can be requested: energy by end use, total heating/cooling loads, and component heating/cooling loads.
- ERI version in the HPXML file can now be entered as "latest".
- Additional HPXML error-checking.

__Bugfixes__
- Fix for central fan integrated supply (CFIS) fan energy.
- Fix simulation error when `FractionHeatLoadServed` (or `FractionCoolLoadServed`) sums to slightly greater than 1.
- Fix for running simulations on a different drive (either local or remote network).
- Fix for HVAC sizing error when latitude is exactly 64 (Big Delta, Alaska).
- Fix for DSE not being incorporated in the heating/cooling in ERI____Home_Hourly.csv output files.
- Fix potential simulation error for buildings with foundation walls.
- Fix radiation heat transfer when conditioned basement walls have a window/door.
- Fixes weather download location.
- Fixes Rated Home infiltration rate for homes with below-grade stories and using natural ACH.

## OpenStudio-ERI v0.7.0 Beta

__Breaking changes__
- OpenStudio version 2.9.1 is now required.
- The `--hourly-output` argument now only generates hourly output for the Reference/Rated Homes, not the IAD Homes, for faster runtime.
- Foundation walls described with the `Insulation/Layer` approach now require two layers (i.e., interior and exterior). (Foundation walls described using the `Insulation/AssemblyEffectiveRValue` approach are unchanged.) See [here](https://github.com/NREL/OpenStudio-HPXML/pull/120) for more information.

__New Features__
- Runtime performance improvements for all buildings.
- Adds dual fuel heat pump model with a switchover temperature input.
- Adds solar hot water models. Inputs are either a system-level solar fraction or detailed collector inputs for flat-plate, evacuated tube, and ICS systems.
- Allows input for indirect water heater (combi boiler) standby losses.
- Allows separate interior vs exterior foundation wall insulation elements.
- Allows foundation wall insulation that doesn't start at the top of the wall.

__Bugfixes__
- Fixes Reference Home HVAC sizing when the house has a conditioned basement.
- Fixes basement slab insulation being ignored.
- Fixes possible issue with ground-source heat pump ground loop sizing.
- Fixes return duct losses and duct component load reporting.
- Fixes desuperheater model bugs.
- Fixes/updates to Proposed HERS Method Test HPXML files
- Errors are now generated for duplicate `SystemIdentifier` IDs, as they are supposed to be unique per the HPXML schema and can result in unpredictable behavior.

__Known Issues__
- None

## OpenStudio-ERI v0.6.0 Beta

__Breaking changes__
- A `Foundations/Foundation[FoundationType/Basement[Conditioned='false']]/ThermalBoundary` element is now required for all buildings with unconditioned basements.
- Several reporting changes for results/ERI____Home.csv output files:
  - "Other Fuel" is now disaggregated into "Fuel Oil" and "Propane"
  - Peak load units are changed from W to kBtu

__New Features__
- Adds ability to specify evaporative coolers
- Adds heating/cooling component loads reporting to results/ERI____Home.csv output files. See the Outputs documentation for more information.
- When an `AirDistribution` is specified, only supply duct leakage is now required. Return duct leakage, supply ducts, and return ducts are now optional.

__Bugfixes__
- Improves combi boiler model to achieve better control/accuracy.
- Changes the recovery efficiency (RE) of the Reference Home water heater for consistency with other software tools.
- Changes the thermal boundary location for unconditioned basements in the Reference Home configuration for consistency with other software tools.
- Fixes bug where presence of a radiant barrier was not being reflected in the model.
- Fixes Reference Home configuration for thermal boundary vs. exterior thermal boundary surfaces.
- Fixes bug where a couple FoundationWall elements were not being properly validated.
- Improves handling of uninsulated foundation walls defined by assembly R-value.

__Known Issues__
- Desuperheater savings is not correct. The issue is being investigated.
- Return duct losses may not be correct. Heating/cooling loads do not include return duct loads. These issues are being investigated.

## OpenStudio-ERI v0.5.0 Beta

__Breaking changes__
- None

__New Features__
- Adds thermostat information (setpoints, setbacks/setups, ceiling fan offset) to all the configured homes' HPXMLs.
- Runtime improvements for homes with heat pump water heaters.
- Runtime improvements for homes with slabs/crawlspaces/basements.
- Reduces number of simulations for Reference/IAD Auto-Generation tests.
- Simulations are now immediately aborted when an error occurs.

__Bugfixes__
- Fixes significant runtime regression for more complex homes.
- Fixes possibility of IAD Home skylight area exceeding roof area.
- Fixes Reference Home R-values for non-thermal boundary surfaces.
- Fixes entered setpoints being used in the Rated Home.
- Fixes infiltration credit erroneously being applied to SFA/MF mechanical ventilation rates.
- Fixes cooling system's Sensible Heat Ratio not being preserved in the Reference Home.
- Fixes attic/crawlspace ventilation rates appearing in the Reference Home HPXML even when there's no vented attic/crawlspace.
- Fixes zero mechanical ventilation energy when CFIS systems are set to run exactly 24 hrs/day.
- Fixes ceiling fans running year-round instead of only during certain months.
- Fixes Reference Home mechanical ventilation when infiltration is entered as CFM50.
- Increases precision of some outputs (that were previously rounded to 0.01 GJ).

__Known Issues__
- Energy results for combination boilers may be incorrect by a few percentage points. The issue is still being investigated.

## OpenStudio-ERI v0.4.0 Beta

__Breaking changes__
- Requires OpenStudio 2.9.0
- The root `HPXML` element needs to be changed from http://hpxmlonline.com/2014/6 to http://hpxmlonline.com/2019/10 per the latest HPXML v3 schema.
- `Slab/DepthBelowGrade` is now required when `Slab/InteriorAdjacentTo=’garage’`.
- `FrameFloor/ExteriorAdjacentTo` must now be either 'other housing unit above' or 'other housing unit below' instead of 'other housing unit'.
- `HeatPump/HeatingCapacity` is now a required element.
- Several reporting changes for results/ERI____Home.csv output files:
  - Hot water recirculation pump energy is now disaggregated.
  - Lighting energy is disaggregated into interior vs exterior vs garage.
  - Hot water load related to tank losses are now reported.
  - Summer/winter peak electricity consumption values are now reported.
  - Peak heating/cooling loads are now reported.
- A couple reporting changes for HERS test results:
  - Hot water tests: Hot water recirculation pump energy is now disaggregated.
  - ASHRAE 140 tests: Load results are separated into heating/cooling categories.

__New Features__
- Adds an optional `--hourly-output` argument to request an hourly output CSV file that includes zone temperatures and energy uses disaggregated by fuel.
- Adds ability to model a desuperheater attached to a ground source heat pump, air source heat pump, or air conditioner.
- Adds `SensibleHeatFraction` as a new optional input for air conditioners.
- Adds `CoolingSensibleHeatFraction` and `HeatingCapacity17F` as new optional inputs for heat pumps.
- Improves modeling of ERVs/HRVs (compared to mechanical ventilation systems without energy recovery).
- Improves modeling of conditioned basements (radiation heat exchange and solar distribution).
- Improves modeling of exterior incident solar for walls/roofs/etc. without an `Azimuth` provided.
- Allows tests to be run in parallel without clobbering each other on the filesystem.

__Bugfixes__
- Prevent E+ simulation error due to near zero autosized heating/cooling airflow rate.
- Fixes incorrect reference in EPvalidator.rb for `FoundationWall`.
- Fixes possible "Cannot create a surface with vertices" error.
- Fixes possible "Unable to calculate a construction for <surface> using the provided assembly R-value" errors.
- Fixes possible "Electric category end uses do not sum to total" error for heat pumps.
- Fixes possible "Sum of conditioned floor surface areas is greater than ConditionedFloorArea specified" error for buildings with adiabatic ceilings.
- Fixes possible "Two airloops found for CFIS" error.
- Fixes error when a `FoundationWall` is completely below-grade (i.e., `DepthBelowGrade` = `Height`).
- Fixes the infiltration rate in the conditioned basement ASHRAE 140 tests (L322XC and L324XC) and other HERS tests derived thereof.
- Fixes HERS hot water tests not passing when pasted into the RESNET spreadsheet.
- Fixes modeling of leakage to outside when all ducts are in conditioned space.
- Fixes modeling tankless water heaters when the home has >5 or <1 bedrooms.
- Fixes error for HVAC systems with zero heating/cooling capacity.
- Fixes error for duct locations that have only supply (or only return) ducts.
- Various minor fixes to HERS test files.
- Adds better error-checking if surfaces are missing -- for example, a garage ceiling/roof.
- Adds error-checking for stranded `HVACDistribution` elements (i.e., not referenced by an HVAC system).
- Adds error-checking for a negative water heater standby loss coefficient (UA).

__Known Issues__
- Energy results for combination boilers may be incorrect by a few percentage points. The issue is still being investigated.

## OpenStudio-ERI v0.3.0 Beta

__Breaking changes__
- `VentilationFan/RatedFlowRate` is now `TestedFlowRate`.
- Several reporting changes for results/ERI____Home.csv output files:
  - Disaggregated natural gas from other fuels.
  - Changed PV energy generation to a negative number.
  - Added heating, cooling, and hot water loads.
  - Added *unmet* heating and cooling loads.

__New Features__
- General runtime performance improvements.
- Combination boilers, which provide both space and water heating, can be specified. Use `WaterHeatingSystem/WaterHeaterType` and point `WaterHeatingSystem/RelatedHVACSystem` to a `HeatingSystem` of type boiler.
- Water heater tank wrap insulation can be optionally specified via `WaterHeatingSystem/WaterHeaterInsulation/Jacket/JacketRValue`.
- Improved foundation modeling for more complex configurations (e.g., walkout basements, multiple foundation walls/slabs with different insulation properties, etc.)
- `WaterHeatingSystem/HeatingCapacity` is now optional.
- `Slab/DepthBelowGrade` is now only required for slab foundation types.
- Custom weather files can now be used.

__Bugfixes__
- Improved approach for distribution system efficiency (DSE).
- Improved approach for calculation of Reference End Use Loads (REUL).
- Improved approach for calculation of water heater energy consumption adjustment due to delivery effectiveness.
- Fixed workflow errors if paths had spaces in them.
- Various fixes to test/sample HPXML files.
- Fixed fan power of (non-CFIS) mechanical ventilation systems when hours of operation is less than 24.
- Fixed possible error when trying to use custom weather files.

__Known Issues__
- Combination boiler results are currently incorrect; this will be resolved in a future release that uses EnergyPlus v9.2.
- Heating/cooling energy use for homes with conditioned basements will likely change a bit in a future version.
- Heating/cooling loads are incorrectly reported for Rated Homes that have ERVs or HRVs; the ERI calculation is not affected.

## OpenStudio-ERI v0.2.0 Beta

__Breaking changes__
- `CoolingSystemType="central air conditioning"` is now `"central air conditioner"` (consistent with `"room air conditioner"`)

__New Features__
- Now passes Reference Home Auto-Generation tests (specifically e-Ratio test)
- Allows HRVs/ERVs to be specified with `AdjustedSensibleRecoveryEfficiency` and `AdjustedTotalRecoveryEfficiency` (instead of `SensibleRecoveryEfficiency` and `TotalRecoveryEfficiency`)
- Allows ducts to be located outside (`DuctLocation="outside"`)
- Allows water heaters to be located outside (`Location="other exterior"`)
- All simulation/HPXML/etc. files generated from running tests are now saved to the `workflow/tests/test_files` directory

__Bugfixes__
- Fixes ERI Reference Home mechanical ventilation when Rated Home has no mechanical ventilation
- Fixes ERI Rated Home mechanical ventilation and infiltration when Rated Home has no mechanical ventilation
- Fixes missing heating system in HVAC2b.xml test file
- Fixes heat pump sizing when `FractionHeatLoadServed` and `FractionCoolLoadServed` are different (e.g., ERI Reference Homes when Rated Home heating system is electric)
- Heat pumps now sized based on the max of heating and cooling loads

## OpenStudio-ERI v0.1.0 Beta

- Initial beta release
