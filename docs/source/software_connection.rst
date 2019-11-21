Software Connection
===================

In order to connect a software tool to the OpenStudio-ERI workflow, the software tool must be able to export its building description in `HPXML file <https://hpxml.nrel.gov/>`_ format.

HPXML Overview
--------------

HPXML is an open data standard for collecting and transferring home energy data. 
Requiring HPXML files as the input to the ERI workflow significantly reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.
It also simplifies the process of applying the ERI 301 ruleset.

The `HPXML Toolbox website <https://hpxml.nrel.gov/>`_ provides several resources for software developers, including:

#. An interactive schema validator
#. A data dictionary
#. An implementation guide

ERI Use Case for HPXML
----------------------

HPXML is an flexible and extensible format, where nearly all fields in the schema are optional and custom fields can be included.
Because of this, an ERI Use Case for HPXML has been developed that specifies the HPXML fields or enumeration choices required to run the workflow.

Software developers should use the `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb>`_ (defined as a set of conditional XPath expressions) as well as the `HPXML schema <https://github.com/NREL/OpenStudio-ERI/tree/master/measures/HPXMLtoOpenStudio/hpxml_schemas>`_ to construct valid HPXML files for ERI calculations.

ERI Version
~~~~~~~~~~~

The version of the ERI calculation to be run is specified inside the HPXML file itself at ``/HPXML/SoftwareInfo/extension/ERICalculation/Version``. 
For example, a value of "2014AE" tells the workflow to use ANSI/RESNET/ICC© 301-2014 with both Addendum A (Amendment on Domestic Hot Water Systems) and Addendum E (House Size Index Adjustment Factors) included.

.. note:: 

  Valid choices for ERI version can be looked up in the `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb>`_.

Building Details
~~~~~~~~~~~~~~~~

The building description is entered in HPXML's ``/HPXML/Building/BuildingDetails``.

Building Summary
~~~~~~~~~~~~~~~~

This section describes fields specified in HPXML's ``BuildingSummary``. It is used for high-level building information needed for an ERI calculation including conditioned floor area, number of bedrooms, number of conditioned floors, etc.

The ``BuildingSummary/Site/FuelTypesAvailable`` field is used to determine whether the home has access to natural gas or fossil fuel delivery (specified by any value other than "electricity").
This information may be used for determining the heating system, as specified by the ERI 301 Standard.

Climate and Weather
~~~~~~~~~~~~~~~~~~~

This section describes fields specified in HPXML's ``ClimateandRiskZones``.

The ``ClimateandRiskZones/ClimateZoneIECC`` element specifies the IECC climate zone(s) for years required by the ERI 301 Standard.

The ``ClimateandRiskZones/WeatherStation`` element specifies the EnergyPlus weather file (EPW) to be used in the simulation. 
The ``WeatherStation/WMO`` must be one of the acceptable TMY3 WMO station numbers found in the `weather/data.csv <https://github.com/NREL/OpenStudio-ERI/blob/master/weather/data.csv>`_ file.

In addition to using the TMY3 weather files that are provided, custom weather files can be used if they are in EPW file format.
To use custom weather files, first ensure that all weather files have a unique WMO station number (as provided in the first header line of the EPW file).
Then place them in the ``weather`` directory and call ``openstudio energy_rating_index.rb --cache-weather``.
After processing is complete, each EPW file will have a corresponding \*.cache file and the WMO station numbers of these weather files will be available in the `weather/data.csv <https://github.com/NREL/OpenStudio-ERI/blob/master/weather/data.csv>`_ file.

.. note:: 

  In the future, we hope to provide an automated weather file selector based on a building's address/zipcode or similar information. But for now, each software tool is responsible for providing this information.

Enclosure
~~~~~~~~~

This section describes fields specified in HPXML's ``Enclosure``.

All surfaces that bound different space types in the building (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.
For software tools that do not collect sufficient inputs for every required surface, the software developers will need to make assumptions about these surfaces or collect additional input.

The space types used in the HPXML building description are:

============================  ===================================
Space Type                    Notes
============================  ===================================
living space                  Above-grade conditioned floor area.
attic - vented            
attic - unvented          
basement - conditioned        Below-grade conditioned floor area.
basement - unconditioned  
crawlspace - vented       
crawlspace - unvented     
garage                    
other housing unit            Used to specify adiabatic surfaces.
============================  ===================================

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth to be specified. 
Rather, only the windows/skylights themselves require an azimuth. 
Thus, software tools can use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

Air Leakage
***********

Building air leakage characterized by air changes per hour or cfm at 50 pascals pressure difference (ACH50) is entered at ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage/AirLeakage``. 
The ``Enclosure/AirInfiltration/AirInfiltrationMeasurement`` should be specified with ``HousePressure='50'`` and ``BuildingAirLeakage/UnitofMeasure='ACH'`` or ``BuildingAirLeakage/UnitofMeasure='CFM'``.

In addition, the building's volume associated with the air leakage measurement is provided in HPXML's ``AirInfiltrationMeasurement/InfiltrationVolume``.

Vented Attics/Crawlspaces
*************************

The ventilation rate for vented attics (or crawlspaces) can be specified using an ``Attic`` (or ``Foundation``) element.
First, define the ``AtticType`` as ``Attic[Vented='true']`` (or ``FoundationType`` as ``Crawlspace[Vented='true']``).
Then use the ``VentilationRate[UnitofMeasure='SLA']/Value`` element to specify a specific leakage area (SLA).
If these elements are not provided, the ERI 301 Standard Reference Home defaults will be used.

Roofs
*****

Pitched or flat roof surfaces that are exposed to ambient conditions should be specified as an ``Enclosure/Roofs/Roof``. 
For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``Floor`` and not a ``Roof``.

Beyond the specification of typical heat transfer properties (insulation R-value, solar absorptance, emittance, etc.), note that roofs can be defined as having a radiant barrier.

Walls
*****

Any wall that has no contact with the ground and bounds a space type should be specified as an ``Enclosure/Walls/Wall``. Interior walls (for example, walls solely within the conditioned space of the building) are not required.

Walls are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.
The choice of ``WallType`` has a secondary effect on heat transfer in that it informs the assumption of wall thermal mass.

Rim Joists
**********

Rim joists, the perimeter of floor joists typically found between stories of a building or on top of a foundation wall, are specified as an ``Enclosure//RimJoists/RimJoist``.

The ``InteriorAdjacentTo`` element should typically be "living space" for rim joists between stories of a building and "basement - conditioned", "basement - unconditioned", "crawlspace - vented", or "crawlspace - unvented" for rim joists on top of a foundation wall.

Foundation Walls
****************

Any wall that is in contact with the ground should be specified as an ``Enclosure/FoundationWalls/FoundationWall``.
Other walls (e.g., wood framed walls) that are connected to a below-grade space but have no contact with the ground should be specified as ``Walls`` and not ``FoundationWalls``.

*Exterior* foundation walls (i.e., those that fall along the perimeter of the building's footprint) should use "ground" for ``ExteriorAdjacentTo`` and the appropriate space type (e.g., "basement - unconditioned") for ``InteriorAdjacentTo``.

*Interior* foundation walls should be specified with two appropriate space types (e.g., "crawlspace - vented" and "garage", or "basement - unconditioned" and "crawlspace - unvented") for ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo``.
Interior foundation walls should never use "ground" for ``ExteriorAdjacentTo`` even if the foundation wall has some contact with the ground due to the difference in below-grade depths of the two adjacent space types.

Foundations must include a ``Height`` as well as a ``DepthBelowGrade``. 
For exterior foundation walls, the depth below grade is relative to the ground plane.
For interior foundation walls, the depth below grade **should not** be thought of as relative to the ground plane, but rather as the depth of foundation wall in contact with the ground.
For example, an interior foundation wall between an 8 ft conditioned basement and a 3 ft crawlspace has a height of 8 ft and a depth below grade of 5 ft.
Alternatively, an interior foundation wall between an 8 ft conditioned basement and an 8 ft unconditioned basement has a height of 8 ft and a depth below grade of 0 ft.

Foundation wall insulation can be described in two ways: 

Option 1. A continuous insulation layer with ``NominalRValue`` and ``DistanceToBottomOfInsulation``. 
An insulation layer is useful for describing foundation wall insulation that doesn't span the entire height (e.g., 4 ft of insulation for an 8 ft conditioned basement). 
When an insulation layer R-value is specified, it is modeled with a concrete wall (whose ``Thickness`` is provided) as well as air film resistances as appropriate.

Option 2. An ``AssemblyEffectiveRValue``. 
When instead providing an assembly effective R-value, the R-value should include the concrete wall and an interior air film resistance. 
The exterior air film resistance (for any above-grade exposure) or any soil thermal resistance should **not** be included.

Frame Floors
************

Any horizontal floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) should be specified as an ``Enclosure/FrameFloors/FrameFloor``.

Frame floors are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.

Slabs
*****

Any space type that borders the ground should include an ``Enclosure/Slabs/Slab`` surface with the appropriate ``InteriorAdjacentTo``. 
This includes basements, crawlspaces (even when there are dirt floors -- use zero for the ``Thickness``), garages, and slab-on-grade foundations.

A primary input for a slab is its ``ExposedPerimeter``. 
The exposed perimeter should include any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
So, a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.

Vertical insulation adjacent to the slab can be described by a ``PerimeterInsulation/Layer/NominalRValue`` and a ``PerimeterInsulationDepth``.

Horizontal insulation under the slab can be described by a ``UnderSlabInsulation/Layer/NominalRValue``. 
The insulation can either have a depth (``UnderSlabInsulationWidth``) or can span the entire slab (``UnderSlabInsulationSpansEntireSlab``).

For foundation types without walls, the ``DepthBelowGrade`` field must be provided.
For foundation types with walls, the slab's position relative to grade is determined by the ``FoundationWall/DepthBelowGrade`` values.

Windows
*******

Any window or glass door area should be specified as an ``Enclosure/Windows/Window``.

Windows are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Windows must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Windows must also have an ``Azimuth`` specified, even if the attached wall does not.

Overhangs can optionally be defined for a window by specifying a ``Window/Overhangs`` element.
Overhangs are defined by the vertical distance between the overhang and the top of the window (``DistanceToTopOfWindow``), and the vertical distance between the overhang and the bottom of the window (``DistanceToBottomOfWindow``).
The difference between these two values equals the height of the window.

Skylights
*********

Any skylight should be specified as an ``Enclosure/Skylights/Skylight``.

Skylights are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Skylights must reference a HPXML ``Enclosures/Roofs/Roof`` element via the ``AttachedToRoof``.
Skylights must also have an ``Azimuth`` specified, even if the attached roof does not.

Doors
*****

Any opaque doors should be specified as an ``Enclosure/Doors/Door``.

Doors are defined by ``RValue`` and ``Area``.
Doors must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Doors must also have an ``Azimuth`` specified, even if the attached wall does not.

Systems
~~~~~~~

This section describes fields specified in HPXML's ``Systems``.

If any HVAC systems are entered that provide heating, the sum of all their ``FractionHeatLoadServed`` values must equal 1.
The same holds true for ``FractionCoolLoadServeds`` for HVAC systems that provide cooling and ``FractionDHWLoadServed`` for water heating systems.

Heating Systems
***************

Each heating system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/HeatingSystem``.
Inputs including ``HeatingSystemType``, ``HeatingCapacity``, and ``FractionHeatLoadServed`` must be provided.

Depending on the type of heating system specified, additional elements are required:

==================  ===========================  =================  =======================
HeatingSystemType   DistributionSystem           HeatingSystemFuel  AnnualHeatingEfficiency
==================  ===========================  =================  =======================
ElectricResistance                               electricity        Percent
Furnace             AirDistribution or DSE       <any>              AFUE
WallFurnace                                      <any>              AFUE
Boiler              HydronicDistribution or DSE  <any>              AFUE
Stove                                            <any>              Percent
==================  ===========================  =================  =======================

If a non-electric heating system is specified, the ``ElectricAuxiliaryEnergy`` element may be provided if available. 

Cooling Systems
***************

Each cooling system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/CoolingSystem``.
Inputs including ``CoolingSystemType`` and ``FractionCoolLoadServed`` must be provided.
``CoolingCapacity`` must also be provided for all systems other than evaporative coolers.

Depending on the type of cooling system specified, additional elements are required/available:

=======================  =================================  =================  =======================  ====================
CoolingSystemType        DistributionSystem                 CoolingSystemFuel  AnnualCoolingEfficiency  SensibleHeatFraction
=======================  =================================  =================  =======================  ====================
central air conditioner  AirDistribution or DSE             electricity        SEER                     (optional)
room air conditioner                                        electricity        EER                      (optional)
evaporative cooler       AirDistribution or DSE (optional)  electricity
=======================  =================================  =================  =======================  ====================

Heat Pumps
**********

Each heat pump should be entered as a ``Systems/HVAC/HVACPlant/HeatPump``.
Inputs including ``HeatPumpType``, ``CoolingCapacity``, ``HeatingCapacity``, ``FractionHeatLoadServed``, and ``FractionCoolLoadServed`` must be provided.
Note that heat pumps are allowed to provide only heating (``FractionCoolLoadServed`` = 0) or cooling (``FractionHeatLoadServed`` = 0) if appropriate.

Depending on the type of heat pump specified, additional elements are required/available:

=============  =================================  ============  =======================  =======================  ===========================  ==================
HeatPumpType   DistributionSystem                 HeatPumpFuel  AnnualCoolingEfficiency  AnnualHeatingEfficiency  CoolingSensibleHeatFraction  HeatingCapacity17F
=============  =================================  ============  =======================  =======================  ===========================  ==================
air-to-air     AirDistribution or DSE             electricity   SEER                     HSPF                     (optional)                   (optional)
mini-split     AirDistribution or DSE (optional)  electricity   SEER                     HSPF                     (optional)                   (optional)
ground-to-air  AirDistribution or DSE             electricity   EER                      COP                      (optional)
=============  =================================  ============  =======================  =======================  ===========================  ==================

If the heat pump has integrated backup heating, it can be specified with ``BackupSystemFuel`` (currently only "electricity" is allowed), ``BackupAnnualHeatingEfficiency`` (percent), and ``BackupHeatingCapacity``.

Thermostat
**********

A ``Systems/HVAC/HVACControl`` must be provided if any HVAC systems are specified.
Its ``ControlType`` specifies whether there is a manual or programmable thermostat.

HVAC Distribution
*****************

Each separate HVAC distribution system should be specified as a ``Systems/HVAC/HVACDistribution``.
There should be at most one heating system and one cooling system attached to a distribution system.
See the sections on Heating Systems, Cooling Systems, and Heat Pumps for information on which ``DistributionSystemType`` is allowed for which HVAC system.
Also, note that some HVAC systems (e.g., room air conditioners) are not allowed to be attached to a distribution system.

``AirDistribution`` systems are defined by:

- Supply leakage in CFM25 to the outside (``DuctLeakageMeasurement[DuctType='supply']/DuctLeakage/Value``)
- Optional return leakage in CFM25 to the outside (``DuctLeakageMeasurement[DuctType='return']/DuctLeakage/Value``)
- Optional supply ducts (``Ducts[DuctType='supply']``)
- Optional return ducts (``Ducts[DuctType='return']``)

For each duct, ``DuctInsulationRValue``, ``DuctLocation``, and ``DuctSurfaceArea`` must be provided.

``HydronicDistribution`` systems do not require any additional inputs.

``DSE`` systems are defined by a ``AnnualHeatingDistributionSystemEfficiency`` and ``AnnualCoolingDistributionSystemEfficiency`` elements.

Mechanical Ventilation
**********************

A single whole-house mechanical ventilation system may be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForWholeBuildingVentilation='true'``.
Inputs including ``FanType``, ``TestedFlowRate``, ``HoursInOperation``, and ``FanPower`` must be provided.

Depending on the type of mechanical ventilation specified, additional elements are required:

====================================  ==========================  =======================  ================================
FanType                               SensibleRecoveryEfficiency  TotalRecoveryEfficiency  AttachedToHVACDistributionSystem
====================================  ==========================  =======================  ================================
energy recovery ventilator            required                    required
heat recovery ventilator              required
exhaust only
supply only
balanced
central fan integrated supply (CFIS)                                                       required
====================================  ==========================  =======================  ================================

Note that AdjustedSensibleRecoveryEfficiency and AdjustedTotalRecoveryEfficiency can be provided instead.

In many situations, the rated flow rate should be the value derived from actual testing of the system.
For a CFIS system, the rated flow rate should equal the amount of outdoor air provided to the distribution system.

Water Heaters
*************

Each water heater should be entered as a ``Systems/WaterHeating/WaterHeatingSystem``.
Inputs including ``WaterHeaterType``, ``Location``, and ``FractionDHWLoadServed`` must be provided.

Depending on the type of water heater specified, additional elements are required/available:

========================================  ===================================  ===========  ==========  ===============  ========================  =====================    =========================================
WaterHeaterType                           UniformEnergyFactor or EnergyFactor  FuelType     TankVolume  HeatingCapacity  RecoveryEfficiency        RelatedHVACSystem        WaterHeaterInsulation/Jacket/JacketRValue
========================================  ===================================  ===========  ==========  ===============  ========================  =====================    =========================================
storage water heater                      required                             <any>        required    <optional>       required if non-electric                           <optional>
instantaneous water heater                required                             <any>
heat pump water heater                    required                             electricity  required                                                                        <optional>
space-heating boiler with storage tank                                                      required                                               required                 <optional>
space-heating boiler with tankless coil                                                                                                            required                 
========================================  ===================================  ===========  ==========  ===============  ========================  =====================    =========================================

For combi boiler systems, the ``RelatedHVACSystem`` must point to a ``HeatingSystem`` of type "Boiler".

For water heaters that are connected to a desuperheater, ``UsesDesuperheater`` must be set and the ``RelatedHVACSystem`` must either point to a ``HeatPump`` or a ``CoolingSystem``.

Hot Water Distribution
**********************

A ``Systems/WaterHeating/HotWaterDistribution`` must be provided if any water heating systems are specified.
Inputs including ``SystemType`` and ``PipeInsulation/PipeRValue`` must be provided.

For a ``SystemType/Standard`` (non-recirculating) system, the following field is required:

- ``PipingLength``: Measured length of hot water piping from the hot water heater to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any)

For a ``SystemType/Recirculation`` system, the following fields are required:

- ``ControlType``
- ``RecirculationPipingLoopLength``: Measured recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements
- ``BranchPipingLoopLength``: Measured length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally
- ``PumpPower``

In addition, a ``HotWaterDistribution/DrainWaterHeatRecovery`` (DWHR) may be specified.
The DWHR system is defined by:

- ``FacilitiesConnected``: 'one' if there are multiple showers and only one of them is connected to a DWHR; 'all' if there is one shower and it's connected to a DWHR or there are two or more showers connected to a DWHR
- ``EqualFlow``: 'true' if the DWHR supplies pre-heated water to both the fixture cold water piping and the hot water heater potable supply piping
- ``Efficiency``: As rated and labeled in accordance with CSA 55.1

Water Fixtures
**************

Water fixtures should be entered as ``Systems/WaterHeating/WaterFixture`` elements.
Each fixture must have ``WaterFixtureType`` and ``LowFlow`` elements provided.
Fixtures should be specified as low flow if they are <= 2.0 gpm.

Photovoltaics
*************

Each solar electric (photovoltaic) system should be entered as a ``Systems/Photovoltaics/PVSystem``.
The following fields, some adopted from the `PVWatts model <https://pvwatts.nrel.gov>`_, are required for each PV system:

- ``Location``: 'ground' or 'roof' mounted
- ``ModuleType``: 'standard', 'premium', or 'thin film'
- ``Tracking``: 'fixed' or '1-axis' or '1-axis backtracked' or '2-axis'
- ``ArrayAzimuth``
- ``ArrayTilt``
- ``MaxPowerOutput``
- ``InverterEfficiency``: Default is 0.96.
- ``SystemLossesFraction``: Default is 0.14. System losses include soiling, shading, snow, mismatch, wiring, degradation, etc.

Appliances
~~~~~~~~~~

This section describes fields specified in HPXML's ``Appliances``.
Many of the appliances' inputs are derived from EnergyGuide labels.

The ``Location`` for clothes washers, clothes dryers, and refrigerators can be provided, while dishwashers and cooking ranges are assumed to be in the living space.

Clothes Washer
**************

An ``Appliances/ClothesWasher`` element must be specified.
The efficiency of the clothes washer can either be entered as a ``ModifiedEnergyFactor`` or an ``IntegratedModifiedEnergyFactor``.
Several other inputs from the EnergyGuide label must be provided as well.

Clothes Dryer
*************

An ``Appliances/ClothesDryer`` element must be specified.
The dryer's ``FuelType`` and ``ControlType`` ("timer" or "moisture") must be provided.
The efficiency of the clothes dryer can either be entered as an ``EnergyFactor`` or ``CombinedEnergyFactor``.


Dishwasher
**********

An ``Appliances/Dishwasher`` element must be specified.
The dishwasher's ``PlaceSettingCapacity`` must be provided.
The efficiency of the dishwasher can either be entered as an ``EnergyFactor`` or ``RatedAnnualkWh``.

Refrigerator
************

An ``Appliances/Refrigerator`` element must be specified.
The efficiency of the refrigerator must be entered as ``RatedAnnualkWh``.

Cooking Range/Oven
******************

``Appliances/CookingRange`` and ``Appliances/Oven`` elements must be specified.
The ``FuelType`` of the range and whether it ``IsInduction``, as well as whether the oven ``IsConvection``, must be provided.

Lighting
~~~~~~~~

The building's lighting is described by six ``Lighting/LightingGroup`` elements, each of which is the combination of:

- ``LightingGroup/ThirdPartyCertification``: 'ERI Tier I' (fluorescent) and 'ERI Tier II' (LEDs, outdoor lamps controlled by photocells, or indoor lamps controlled by motion sensor)
- ``LightingGroup/Location``: 'interior', 'garage', and 'exterior'

The fraction of lamps of the given type in the given location are provided as the ``LightingGroup/FractionofUnitsInLocation``.
The fractions for a given location cannot sum to greater than 1.
Garage lighting values are ignored if the building has no garage.

Ceiling Fans
~~~~~~~~~~~~

Each ceiling fan (or set of identical ceiling fans) should be entered as a ``Lighting/CeilingFan``.
The ``Airflow/Efficiency`` (at medium speed) and ``Quantity`` must be provided.

Validating & Debugging Errors
-----------------------------

When running HPXML files, errors may occur because:

#. An HPXML file provided is invalid (either relative to the HPXML schema or the ERI Use Case).
#. An unexpected error occurred in the workflow (e.g., applying the ERI 301 ruleset).
#. An unexpected EnergyPlus simulation error occurred.

If, for example, the Rated Home is unsuccessful, first look in the ERIRatedHome/run.log for details.
If there are no errors in that log file, then the error may be in the EnergyPlus simulation -- see ERIRatedHome/eplusout.err.

Contact us if you can't figure out the cause of an error.

Sample Files
------------

Dozens of sample HPXML files are included in the workflow/sample_files directory.
The sample files help to illustrate how different building components are described in HPXML.

Each sample file generally makes one isolated change relative to the base HPXML (base.xml) building.
For example, the base-dhw-dwhr.xml file adds a ``DrainWaterHeatRecovery`` element to the building.

You may find it useful to search through the files for certain HPXML elements or compare (diff) a sample file to the base.xml file.
