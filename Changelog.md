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
  - **[Breaking Change]** `IsSharedSystem` now required for boilers and ground-to-air heat pumps, water heating systems, ventilation systems, and PV systems
  - **[Breaking Change]** `IsSharedAppliance` now required for clothes washers, clothes dryers, and dishwashers
  - **[Breaking Change]** Appliances located in MF spaces (i.e., "other") must now be specified in more detail (i.e., "other heated space", "other non-freezing space", "other multifamily buffer space", or "other housing unit")
- Allows multiple mechanical ventilation systems (`VentilationFan`)
- **[Breaking Change]** For hydronic distributions, `HydronicDistributionType` is now required
- **[Breaking Change]** For DSE distributions, `AnnualHeatingDistributionSystemEfficiency` and `AnnualCoolingDistributionSystemEfficiency` are both always required
- **[Breaking Change]** Adds `RadiantBarrierGrade` as a required input if a roof has a radiant barrier
- **[Breaking Change]** Adds `extension/PumpPowerWattsPerTon` as a required input for ground-to-air heat pumps
- **[Breaking Change]** Renames `DuctLeakageTestingExemption` to `DuctLeakageToOutsideTestingExemption`, to clarify that it is different from the total duct leakage testing exemption in ANSI/RESNET/ACCA 310
- **[Breaking Change]** New `FanPowerDefaulted` and `FlowRateNotTested` elements must be provided when ventilation systems have defaulted fan power or unmeasured airflow
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
  - **[Breaking Change]** `Location` is now a required element for dishwashers and cooking ranges.
  - `Location` can be "other" for all appliances
  - **[Breaking change]** `Window/FractionOperable` is required
  - `VentilationFan/TestedFlowRate` is now optional and can be excluded for unmeasured mechanical ventilation flow rates
  - `VentilationFan/FanPower` is now optional and can be excluded for unknown mechanical ventilation fan power
  - **[Breaking change]** `LabelUsage` is required for clothes washers
  - **[Breaking change]** `LabelElectricRate`, `LabelGasRate`, `LabelAnnualGasCost`, and `LabelUsage` are required for dishwashers
  - **[Breaking Change]** `HVACDistribution/ConditionedFloorAreaServed` is now required for air distribution systems
  - **[Breaking Change]** For FrameFloors ExteriorAdjacentTo, "other housing unit above" and "other housing unit below" are replaced with "other housing unit"; floors adjacent to any "other ..." MF space type must have the `extension/OtherSpaceAboveOrBelow` element set to "above" or "below".
- **[Breaking Change]** Lighting inputs now use `LightingType[LightEmittingDiode | CompactFluorescent | FluorescentTube]` instead of `ThirdPartyCertification="ERI Tier I" or ThirdPartyCertification="ERI Tier II"`.
- Allows "exterior wall", "under slab", and "roof deck" for `DuctLocation`.
- Allows `PortableHeater`, `Fireplace`, and `FloorFurnace` for heating system types.
- Allows "wood" and "wood pellets" as fuel types for HVAC systems, water heaters, and appliances.
- Allows additional hourly outputs: airflows (e.g., infiltration, mechanical ventilation, natural ventilation, whole house fan) and weather (e.g., temperatures, wind speed, solar).
- Improved inferred infiltration height calculation for homes w/ conditioned basements.
- Reference Home mechanical ventilation that supplements infiltration is now always a balanced system.
- Additional runtime improvements.
- **[Breaking Change]** Many changes to HPXML test files to conform to latest RESNET Publication 002.
- ERI____Home.xml files:
  - **[Breaking Change]** `WaterHeatingSystem/PerformanceAdjustment` is now a multiplier (e.g., 0.92) instead of a derate (e.g., 0.08).
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
- **[Breaking Change]** Updates to OpenStudio v3.0.0 and EnergyPlus 9.3.
- **[Breaking Change]** Allows 301-2014 Addenda D & L to be used by providing inputs for A) duct leakage testing exemptions or B) total duct leakage in lieu of leakage to the outside. These inputs should only be used if the conditions specified in ANSI/RESNET/ICC© 301 have been appropriately met. Enumerations for `SoftwareInfo/extension/ERICalculation/Version` are now "latest", "2014ADEGL", "2014ADEG", "2014ADE", "2014AD", "2014A", "2014".
- **[Breaking Change]** `BuildingConstruction/ResidentialFacilityType` is now required. Valid choices are: "single-family detached", "single-family attached", "apartment unit", "manufactured home".
- Improves inferred infiltration height for conditioned basements (including walkout basements).
- A new HPXML input `WeatherStation/extension/EPWFilePath` can be used instead of `WeatherStation/WMO` to point directly to the EPW file of interest.
- Adds hot water outputs (gallons), disaggregated by end use, to annual output. Also available for timeseries outputs.
- Improved desuperheater model; can now be connected to heat pump water heaters.
- Solar thermal systems modeled with `SolarFraction` can now be connected to combi water heating systems.
- Small improvement to calculation of component loads.
- Allows buildings to have HVAC systems that do not condition 100% of the load (i.e., where sum of fraction heat/cool load served is greater than zero and less than one).
- Populates more information in the ERI___Home.xml files (e.g., plug load kWh/yr).
- **[Breaking Change]** The `--no-ssl` argument has been deprecated.
- **[Breaking Change]** Switches from `BuildingConstruction/extension/FractionofOperableWindowArea` to `Window/FractionOperable` in HPXML test files.

__Bugfixes__
- Fixes an unsuccessful simulation for buildings with multiple HVAC air distribution systems, each with multiple duct locations.
- Fixes an unsuccessful simulation for buildings where the sum of multiple HVAC systems' fraction load served was slightly above 1 due to rounding.
- Small fix for interior partition wall thermal mass model.

## OpenStudio-ERI v0.8.0 Beta

__Breaking Changes__
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

__Breaking Changes__
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

__Breaking Changes__
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

__Breaking Changes__
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

__Breaking Changes__
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

__Breaking Changes__
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

__Breaking Changes__
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
