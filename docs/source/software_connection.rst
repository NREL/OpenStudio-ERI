Software Connection
===================

Introduction
------------

OpenStudio-ERI requires a building description in an `HPXML file <https://hpxml.nrel.gov/>`_ format.
HPXML is an open data standard for collecting and transferring home energy data.
Using HPXML files reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.

HPXML Inputs
------------

HPXML is an flexible and extensible format, where nearly all elements in the schema are optional and custom elements can be included.
Because of this, a stricter set of requirements for the HPXML file have been developed for purposes of running an Energy Rating Index calculation.

HPXML files submitted to OpenStudio-ERI should undergo a two step validation process:

1. Validation against the HPXML Schema

  The HPXML XSD Schema can be found at ``hpxml-measures/HPXMLtoOpenStudio/resources/HPXML.xsd``.
  It should be used by the software developer to validate their HPXML file prior to running the workflow.
  XSD Schemas are used to validate what elements/attributes/enumerations are available, data types for elements/attributes, the number/order of children elements, etc.
  
  OpenStudio-ERI **does not** validate the HPXML file against the XSD Schema and assumes the file submitted is valid.

2. Validation using `Schematron <http://schematron.com/>`_

  The Schematron document for the ERI use case can be found at ``rulesets/301EnergyRatingIndexRuleset/resources/301validator.xml``.
  Schematron is a rule-based validation language, expressed in XML using XPath expressions, for validating the presence or absence of inputs in XML files. 
  As opposed to an XSD Schema, a Schematron document validates constraints and requirements based on conditionals and other logical statements.
  For example, if an element is specified with a particular value, the applicable enumerations of another element may change.
  
  OpenStudio-ERI **automatically validates** the HPXML file against the Schematron document and reports any validation errors, but software developers may find it beneficial to also integrate Schematron validation into their software.
 
.. important::

  Usage of both validation approaches (XSD and Schematron) is recommended for developers actively working on creating HPXML files for Energy Rating Index calculations:
  
  - Validation against XSD for general correctness and usage of HPXML
  - Validation against Schematron for understanding XML document requirements specific to running ERI calculations

HPXML Software Info
-------------------

The version of the ERI calculation to be run is specified inside the HPXML file itself at ``/HPXML/SoftwareInfo/extension/ERICalculation/Version``. 
For example, a value of "2014AE" tells the workflow to use ANSI/RESNET/ICC© 301-2014 with both Addendum A (Amendment on Domestic Hot Water Systems) and Addendum E (House Size Index Adjustment Factors) included.
A value of "latest" can be used to always point to the latest version available.

.. note:: 

  Valid choices for ERI version can be looked up in the `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/rulesets/301EnergyRatingIndexRuleset/resources/301validator.rb>`_.

HPXML Building Details
----------------------

The building description is entered in HPXML's ``/HPXML/Building/BuildingDetails``.

HPXML Building Summary
----------------------

This section describes elements specified in HPXML's ``BuildingSummary``. 
It is used for high-level building information needed for an ERI calculation including conditioned floor area, number of bedrooms, number of conditioned floors, residential facility type, etc.
Note that a walkout basement should be included in ``NumberofConditionedFloorsAboveGrade``.

The ``BuildingSummary/Site/FuelTypesAvailable`` element is used to determine whether the home has access to natural gas or fossil fuel delivery (specified by any value other than "electricity").
This information may be used for determining the heating system, as specified by the ERI 301 Standard.

HPXML Weather Station
---------------------

This section describes elements specified in HPXML's ``ClimateandRiskZones``.

The ``ClimateandRiskZones/ClimateZoneIECC`` element specifies the IECC climate zone(s) for years required by the ERI 301 Standard.

The ``ClimateandRiskZones/WeatherStation`` element specifies the EnergyPlus weather file (EPW) to be used in the simulation. 
The weather file can be entered in one of two ways:

#. Using ``WeatherStation/WMO``, which must be one of the acceptable TMY3 WMO station numbers found in the ``weather/data.csv`` file.
   The full set of U.S. TMY3 weather files can be `downloaded here <https://data.nrel.gov/system/files/128/tmy3s-cache-csv.zip>`_.
#. Using ``WeatherStation/extension/EPWFilePath``.

In addition to using the TMY3 weather files that are provided, custom weather files can be used if they are in EPW file format.
To use custom weather files, first ensure that all weather files have a unique WMO station number (as provided in the first header line of the EPW file).
Then place them in the ``weather`` directory and call ``openstudio energy_rating_index.rb --cache-weather``.
After processing is complete, each EPW file will have a corresponding \*.csv cache file and the WMO station numbers of these weather files will be available in the `weather/data.csv`` file.

.. note:: 

  In the future, we hope to provide an automated weather file selector based on a building's address/zipcode or similar information. But for now, each software tool is responsible for providing this information.

HPXML Enclosure
---------------

This section describes elements specified in HPXML's ``Enclosure``.

All surfaces that bound different space types in the building (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.
For software tools that do not collect sufficient inputs for every required surface, the software developers will need to make assumptions about these surfaces or collect additional input.

The space types used in the HPXML building description are:

==============================  ==================================  ========================================================  =========================
Space Type                      Description                         Temperature                                               Building Type
==============================  ==================================  ========================================================  =========================
living space                    Above-grade conditioned floor area  EnergyPlus calculation                                    Any
attic - vented                                                      EnergyPlus calculation                                    Any
attic - unvented                                                    EnergyPlus calculation                                    Any
basement - conditioned          Below-grade conditioned floor area  EnergyPlus calculation                                    Any
basement - unconditioned                                            EnergyPlus calculation                                    Any
crawlspace - vented                                                 EnergyPlus calculation                                    Any
crawlspace - unvented                                               EnergyPlus calculation                                    Any
garage                          Single-family (not shared parking)  EnergyPlus calculation                                    Any
other housing unit              Unrated Conditioned Space           Same as conditioned space                                 Attached/Multifamily only
other heated space              Unrated Heated Space                Average of conditioned space and outside; minimum of 68F  Attached/Multifamily only
other multifamily buffer space  Multifamily Buffer Boundary         Average of conditioned space and outside; minimum of 50F  Attached/Multifamily only
other non-freezing space        Non-Freezing Space                  Floats with outside; minimum of 40F                       Attached/Multifamily only
==============================  ==================================  ========================================================  =========================

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth to be specified. 
Rather, only the windows/skylights themselves require an azimuth. 
Thus, software tools can choose to use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

HPXML Air Infiltration
**********************

Building air leakage is entered using ``Enclosure/AirInfiltration/AirInfiltrationMeasurement``.
Air leakage can be provided in one of three ways:

#. nACH (natural air changes per hour): Use ``BuildingAirLeakage/UnitofMeasure='ACHnatural'``
#. ACH50 (air changes per hour at 50Pa): Use ``BuildingAirLeakage/UnitofMeasure='ACH'`` and ``HousePressure='50'``
#. CFM50 (cubic feet per minute at 50Pa): Use ``BuildingAirLeakage/UnitofMeasure='CFM'`` and ``HousePressure='50'``

In addition, the building's volume associated with the air leakage measurement is provided in HPXML's ``AirInfiltrationMeasurement/InfiltrationVolume``.

HPXML Attics
************

If the building has an unvented attic, an ``Enclosure/Attics/Attic/AtticType/Attic[Vented='false']`` element must be defined.
It must have the ``WithinInfiltrationVolume`` element specified in accordance with ANSI/RESNET/ICC Standard 380.

If the building has a vented attic, an ``Enclosure/Attics/Attic/AtticType/Attic[Vented='true']`` element may be defined in order to specify the ventilation rate.
The ventilation rate can be entered as a specific leakage area using ``VentilationRate[UnitofMeasure='SLA']/Value`` or as natural air changes per hour using ``VentilationRate[UnitofMeasure='ACHnatural']/Value``.
If the ventilation rate is not provided, the ERI 301 Standard Reference Home defaults will be used.

HPXML Foundations
*****************

If the building has an unconditioned basement, an ``Enclosure/Foundations/Foundation/FoundationType/Basement[Conditioned='false']`` element must be defined.
It must have the ``WithinInfiltrationVolume`` element specified in accordance with ANSI/RESNET/ICC Standard 380.
In addition, the ``ThermalBoundary`` element must be specified as either "foundation wall" or "frame floor".

If the building has an unvented crawlspace, an ``Enclosure/Foundations/Foundation/FoundationType/Crawlspace[Vented='false']`` element must be defined.
It must have the ``WithinInfiltrationVolume`` element specified in accordance with ANSI/RESNET/ICC Standard 380.

If the building has a vented crawlspace, an ``Enclosure/Foundations/Foundation/FoundationType/Crawlspace[Vented='true']`` element may be defined in order to specify the ventilation rate.
The ventilation rate can be entered as a specific leakage area using ``VentilationRate[UnitofMeasure='SLA']/Value``.
If the ventilation rate is not provided, the ERI 301 Standard Reference Home defaults will be used.

HPXML Roofs
***********

Pitched or flat roof surfaces that are exposed to ambient conditions should be specified as an ``Enclosure/Roofs/Roof``. 
For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``FrameFloor`` and not a ``Roof``.

Beyond the specification of typical heat transfer properties (insulation R-value, solar absorptance, emittance, etc.), note that roofs can be defined as having a radiant barrier.
If ``RadiantBarrier`` is provided, ``RadiantBarrierGrade`` must also be provided.

HPXML Rim Joists
****************

Rim joists, the perimeter of floor joists typically found between stories of a building or on top of a foundation wall, are specified as an ``Enclosure//RimJoists/RimJoist``.

The ``InteriorAdjacentTo`` element should typically be "living space" for rim joists between stories of a building and "basement - conditioned", "basement - unconditioned", "crawlspace - vented", or "crawlspace - unvented" for rim joists on top of a foundation wall.

HPXML Walls
***********

Any wall that has no contact with the ground and bounds a space type should be specified as an ``Enclosure/Walls/Wall``. 
Interior walls (for example, walls solely within the conditioned space of the building) are not required.

Walls are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.
The choice of ``WallType`` has a secondary effect on heat transfer in that it informs the assumption of wall thermal mass.

HPXML Foundation Walls
**********************

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

Option 1. Both interior and exterior continuous insulation layers with ``NominalRValue``, ``extension/DistanceToTopOfInsulation``, and ``extension/DistanceToBottomOfInsulation``. 
Insulation layers are particularly useful for describing foundation wall insulation that doesn't span the entire height (e.g., 4 ft of insulation for an 8 ft conditioned basement). 
If there is not insulation on the interior and/or exterior of the foundation wall, the continuous insulation layer must still be provided -- with the nominal R-value, etc., set to zero.
When insulation is specified with option 1, it is modeled with a concrete wall (whose ``Thickness`` is provided) as well as air film resistances as appropriate.

Option 2. An ``AssemblyEffectiveRValue``. 
The assembly effective R-value should include the concrete wall and an interior air film resistance. 
The exterior air film resistance (for any above-grade exposure) or any soil thermal resistance should **not** be included.

HPXML Frame Floors
******************

Any horizontal floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) should be specified as an ``Enclosure/FrameFloors/FrameFloor``.
Frame floors in an attached/multifamily building that are adjacent to "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space" must have the ``extension/OtherSpaceAboveOrBelow`` property set to signify whether the other space is "above" or "below".

Frame floors are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.

HPXML Slabs
***********

Any space type that borders the ground should include an ``Enclosure/Slabs/Slab`` surface with the appropriate ``InteriorAdjacentTo``. 
This includes basements, crawlspaces (even when there are dirt floors -- use zero for the ``Thickness``), garages, and slab-on-grade foundations.

A primary input for a slab is its ``ExposedPerimeter``. 
The exposed perimeter should include any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
So, a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.

Vertical insulation adjacent to the slab can be described by a ``PerimeterInsulation/Layer/NominalRValue`` and a ``PerimeterInsulationDepth``.

Horizontal insulation under the slab can be described by a ``UnderSlabInsulation/Layer/NominalRValue``. 
The insulation can either have a fixed width (``UnderSlabInsulationWidth``) or can span the entire slab (``UnderSlabInsulationSpansEntireSlab``).

For foundation types without walls, the ``DepthBelowGrade`` element must be provided.
For foundation types with walls, the ``DepthBelowGrade`` element is not used; instead the slab's position relative to grade is determined by the ``FoundationWall/DepthBelowGrade`` values.

HPXML Windows
*************

Any window or glass door area should be specified as an ``Enclosure/Windows/Window``.

Windows are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Windows must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Windows must also have an ``Azimuth`` specified, even if the attached wall does not.

Finally, windows must have the ``FractionOperable`` property specified for determining natural ventilation.
The input should solely reflect whether the windows are operable (can be opened), not how they are used by the occupants.
If a ``Window`` represents a single window, the value should be 0 or 1.
If a ``Window`` represents multiple windows (e.g., 4), the value should be between 0 and 1 (e.g., 0, 0.25, 0.5, 0.75, or 1).

Overhangs (e.g., a roof eave) can optionally be defined for a window by specifying a ``Window/Overhangs`` element.
Overhangs are defined by the vertical distance between the overhang and the top of the window (``DistanceToTopOfWindow``), and the vertical distance between the overhang and the bottom of the window (``DistanceToBottomOfWindow``).
The difference between these two values equals the height of the window.

HPXML Skylights
***************

Any skylight should be specified as an ``Enclosure/Skylights/Skylight``.

Skylights are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Skylights must reference a HPXML ``Enclosures/Roofs/Roof`` element via the ``AttachedToRoof``.
Skylights must also have an ``Azimuth`` specified, even if the attached roof does not.

HPXML Doors
***********

Any opaque doors should be specified as an ``Enclosure/Doors/Door``.

Doors are defined by ``RValue`` and ``Area``.
Doors must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Doors must also have an ``Azimuth`` specified, even if the attached wall does not.

HPXML Systems
-------------

This section describes elements specified in HPXML's ``Systems``.

If any HVAC systems are entered that provide heating (or cooling), the sum of all their ``FractionHeatLoadServed`` (or ``FractionCoolLoadServed``) values must be less than or equal to 1.

If any water heating systems are entered, the sum of all their ``FractionDHWLoadServed`` values must be equal to 1.

HPXML Heating Systems
*********************

Each heating system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/HeatingSystem``.
Inputs including ``HeatingSystemType``, and ``FractionHeatLoadServed`` must be provided.

Depending on the type of heating system specified, additional elements are used:

==================  ==============  ==================================================  =================  =======================  ===============
HeatingSystemType   IsSharedSystem  DistributionSystem                                  HeatingSystemFuel  AnnualHeatingEfficiency  HeatingCapacity
==================  ==============  ==================================================  =================  =======================  ===============
ElectricResistance                                                                      electricity        Percent                  (required)
Furnace                             AirDistribution or DSE                              <any>              AFUE                     (required)
WallFurnace                                                                             <any>              AFUE                     (required)
FloorFurnace                                                                            <any>              AFUE                     (required)
Boiler              false           HydronicDistribution or DSE                         <any>              AFUE                     (required)
Boiler              true            HydronicDistribution or HydronicAndAirDistribution  <any>              AFUE
Stove                                                                                   <any>              Percent                  (required)
PortableHeater                                                                          <any>              Percent                  (required)
Fireplace                                                                               <any>              Percent                  (required)
==================  ==============  ==================================================  =================  =======================  ===============

For all systems, the ``ElectricAuxiliaryEnergy`` element may be provided if available.
For shared boilers (i.e., serving multiple dwelling units), the electric auxiliary energy can alternatively be calculated using the following inputs:

- ``extension/SharedLoopWatts``: Shared pump power [W]
- ``NumberofUnitsServed``: Number of units served by the shared system
- ``extension/FanCoilWatts``: In-unit fan coil power [W]

If electric auxiliary energy is not provided (nor calculated for shared boilers), it is defaulted per `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

For shared boilers connected to a water loop heat pump, an additional element is required:

- ``extension/WaterLoopHeatPump/AnnualHeatingEfficiency[Units="COP"]/Value``: WLHP rated heating efficiency

HPXML Cooling Systems
*********************

Each cooling system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/CoolingSystem``.
Inputs including ``CoolingSystemType`` and ``FractionCoolLoadServed`` must be provided.

Depending on the type of cooling system specified, additional elements are used:

=======================  ==============  ==================================================  =================  =======================  ====================  ===============
CoolingSystemType        IsSharedSystem  DistributionSystem                                  CoolingSystemFuel  AnnualCoolingEfficiency  SensibleHeatFraction  CoolingCapacity
=======================  ==============  ==================================================  =================  =======================  ====================  ===============
central air conditioner                  AirDistribution or DSE                              electricity        SEER                     (optional)            (required)
room air conditioner                                                                         electricity        EER                      (optional)            (required)
evaporative cooler                       AirDistribution or DSE (optional)                   electricity
chiller                  true            HydronicDistribution or HydronicAndAirDistribution  electricity        kW/ton                                         (required)
cooling tower            true            HydronicAndAirDistribution                          electricity
=======================  ==============  ==================================================  =================  =======================  ====================  ===============

Central air conditioners can also have the ``CompressorType`` specified; if not provided, it is assumed as follows:

- "single stage": SEER <= 15
- "two stage": 15 < SEER <= 21
- "variable speed": SEER > 21

For shared chillers (i.e., serving multiple dwelling units), additional elements are required:

- ``NumberofUnitsServed``: Number of units served by the shared system
- ``AnnualCoolingEfficiency[Units="kW/ton"]/Value``: Chiller efficiency
- ``extension/SharedLoopWatts``: Total of the pumping and fan power serving the system [W]

For shared chillers connected to a fan coil, additional elements are required:

- ``extension/FanCoilWatts``: Total of the in-unit cooling equipment power serving the unit [W]

For shared chillers connected to a water loop heat pump, additional elements are required:

- ``extension/WaterLoopHeatPump/CoolingCapacity``: WLHP cooling capacity [Btu/hr]
- ``extension/WaterLoopHeatPump/AnnualCoolingEfficiency[Units="EER"]/Value``: WLHP rated cooling efficiency

For shared cooling towers (which must always be connected to a water loop heat pump), additional elements are required:

- ``NumberofUnitsServed``: Number of units served by the shared system
- ``extension/SharedLoopWatts``: Total of the pumping and fan power serving the system [W]
- ``extension/WaterLoopHeatPump/CoolingCapacity``: WLHP cooling capacity [Btu/hr]
- ``extension/WaterLoopHeatPump/AnnualCoolingEfficiency[Units="EER"]/Value``: WLHP rated cooling efficiency

HPXML Heat Pumps
****************

Each heat pump should be entered as a ``Systems/HVAC/HVACPlant/HeatPump``.
Inputs including ``HeatPumpType``, ``CoolingCapacity``, ``HeatingCapacity``, ``FractionHeatLoadServed``, and ``FractionCoolLoadServed`` must be provided.
Note that heat pumps are allowed to provide only heating (``FractionCoolLoadServed`` = 0) or cooling (``FractionHeatLoadServed`` = 0) if appropriate.

Depending on the type of heat pump specified, additional elements are used:

=============  ==============  =================================  ============  =======================  =======================  ===========================  ==================
HeatPumpType   IsSharedSystem  DistributionSystem                 HeatPumpFuel  AnnualCoolingEfficiency  AnnualHeatingEfficiency  CoolingSensibleHeatFraction  HeatingCapacity17F
=============  ==============  =================================  ============  =======================  =======================  ===========================  ==================
air-to-air                     AirDistribution or DSE             electricity   SEER                     HSPF                     (optional)                   (optional)
mini-split                     AirDistribution or DSE (optional)  electricity   SEER                     HSPF                     (optional)                   (optional)
ground-to-air  false           AirDistribution or DSE             electricity   EER                      COP                      (optional)
ground-to-air  true            AirDistribution or DSE             electricity   EER                      COP                      (optional)
=============  ==============  =================================  ============  =======================  =======================  ===========================  ==================

Ground-to-air heat pumps also have an additional input:

- ``extension/PumpPowerWattsPerTon``: Ground loop circulator pump power during operation of the heat pump in Watts/ton of cooling capacity.

Air-to-air heat pumps can also have the ``CompressorType`` specified; if not provided, it is assumed as follows:

- "single stage": SEER <= 15
- "two stage": 15 < SEER <= 21
- "variable speed": SEER > 21

If the heat pump has backup heating, it can be specified with ``BackupSystemFuel``, ``BackupAnnualHeatingEfficiency``, and ``BackupHeatingCapacity``.
If the heat pump has a switchover temperature (e.g., dual-fuel heat pump) where the heat pump stops operating and the backup heating system starts running, it can be specified with ``BackupHeatingSwitchoverTemperature``.
If the ``BackupHeatingSwitchoverTemperature`` is not provided, the backup heating system will operate as needed when the heat pump has insufficient capacity.

For multiple ground source heat pumps on a shared hydronic circulation loop (``IsSharedSystem="true"``), additional elements are required:

- ``NumberofUnitsServed``: Number of units served by the shared system
- ``extension/SharedLoopWatts``: Shared pump power [W]

HPXML HVAC Control
******************

A ``Systems/HVAC/HVACControl`` must be provided if any HVAC systems are specified.
Its ``ControlType`` specifies whether there is a manual or programmable thermostat.

HPXML HVAC Distribution
***********************

Each separate HVAC distribution system should be specified as a ``Systems/HVAC/HVACDistribution``.
The four types of HVAC distribution systems allowed are ``AirDistribution``, ``HydronicDistribution``, ``HydronicAndAirDistribution``, and ``DSE``.
There should be at most one heating system and one cooling system attached to a distribution system.
See the sections on Heating Systems, Cooling Systems, and Heat Pumps for information on which ``DistributionSystemType`` is allowed for which HVAC system.
Also note that some HVAC systems (e.g., room air conditioners) are not allowed to be attached to a distribution system.

Air Distribution
~~~~~~~~~~~~~~~~

``AirDistribution`` systems are defined by:
- ``ConditionedFloorAreaServed``
- Optional supply ducts (``Ducts[DuctType='supply']``)
- Optional return ducts (``Ducts[DuctType='return']``)

Each duct must have ``DuctInsulationRValue``, ``DuctLocation``, and ``DuctSurfaceArea`` provided.

``DuctLocation`` must be one of the following:

==============================  ==================================  ========================================================  =========================
Location                        Description                         Temperature                                               Building Type
==============================  ==================================  ========================================================  =========================
living space                    Above-grade conditioned floor area  EnergyPlus calculation                                    Any
basement - conditioned          Below-grade conditioned floor area  EnergyPlus calculation                                    Any
basement - unconditioned                                            EnergyPlus calculation                                    Any
crawlspace - unvented                                               EnergyPlus calculation                                    Any
crawlspace - vented                                                 EnergyPlus calculation                                    Any
attic - unvented                                                    EnergyPlus calculation                                    Any
attic - vented                                                      EnergyPlus calculation                                    Any
garage                          Single-family (not shared parking)  EnergyPlus calculation                                    Any
exterior wall                                                       Average of conditioned space and outside                  Any
under slab                                                          Ground                                                    Any
roof deck                                                           Outside                                                   Any
outside                                                             Outside                                                   Any
other housing unit              Unrated Conditioned Space           Same as conditioned space                                 Attached/Multifamily only
other heated space              Unrated Heated Space                Average of conditioned space and outside; minimum of 68F  Attached/Multifamily only
other multifamily buffer space  Multifamily Buffer Boundary         Average of conditioned space and outside; minimum of 50F  Attached/Multifamily only
other non-freezing space        Non-Freezing Space                  Floats with outside; minimum of 40F                       Attached/Multifamily only
==============================  ==================================  ========================================================  =========================

AirDistribution systems must also have duct leakage testing provided in one of three ways:

#. Optional supply/return leakage to the outside: ``DuctLeakageMeasurement[DuctType="supply" or DuctType="return"]/DuctLeakage[Units="CFM25"][TotalOrToOutside="to outside"]/Value``
#. Total leakage: ``DuctLeakageMeasurement/DuctLeakage[Units="CFM25"][TotalOrToOutside="total"]/Value`` (Version 2014AD or newer)
#. Leakage testing exemption: ``extension/DuctLeakageToOutsideTestingExemption="true"`` (Version 2014ADEGL or newer)

.. note::

  When the leakage to outside testing exemption is used with Addendum L or newer, it effectively overrides the Addendum D specification such that the leakage to outside testing exemption reflects solely the Addendum L specification.

.. warning::

  Total leakage and leakage to outside testing exemption should only be used if the conditions specified in ANSI/RESNET/ICC 301 have been appropriately met.

Hydronic Distribution
~~~~~~~~~~~~~~~~~~~~~

``HydronicDistribution`` systems are defined by:

- ``HydronicDistributionType``: "radiator" or "baseboard" or "radiant floor" or "radiant ceiling"

Hydronic And Air Distribution
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``HydronicAndAirDistribution`` systems are defined by:

- ``HydronicAndAirDistributionType``: "fan coil" or "water loop heat pump"

as well as all of the elements described above for an ``AirDistribution`` system.

Distribution System Efficiency
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``DSE`` systems are defined by ``AnnualHeatingDistributionSystemEfficiency`` and ``AnnualCoolingDistributionSystemEfficiency`` elements.

HPXML Mechanical Ventilation
****************************

This section describes elements specified in HPXML's ``Systems/MechanicalVentilation``.
``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` elements can be used to specify whole building ventilation systems and/or cooling load reduction.

Whole Building Ventilation
~~~~~~~~~~~~~~~~~~~~~~~~~~

Mechanical ventilation systems that provide whole building ventilation may each be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForWholeBuildingVentilation='true'``.
Inputs including ``FanType`` and ``HoursInOperation`` must be provided.

The measured airflow rate should be entered as ``TestedFlowRate``; if unmeasured, it should not be provided and the airflow rate will be defaulted.
For a CFIS system, the flow rate should equal the amount of outdoor air provided to the distribution system.

Likewise the fan power for the highest airflow setting should be entered as ``FanPower``; if unknown, it should not be provided and the fan power will be defaulted.

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

Note that ``AdjustedSensibleRecoveryEfficiency`` and ``AdjustedTotalRecoveryEfficiency`` can be provided instead of ``SensibleRecoveryEfficiency`` and ``TotalRecoveryEfficiency``.

Cooling Load Reduction
~~~~~~~~~~~~~~~~~~~~~~

Whole house fans that provide cooling load reduction may each be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForSeasonalCoolingLoadReduction='true'``.
Required elements include ``RatedFlowRate`` and ``FanPower``.

The whole house fan is assumed to operate during hours of favorable outdoor conditions and will take priority over operable windows (natural ventilation).

HPXML Water Heating Systems
***************************

Each water heater should be entered as a ``Systems/WaterHeating/WaterHeatingSystem``.
Inputs including ``WaterHeaterType``, ``IsSharedSystem``, ``Location``, and ``FractionDHWLoadServed`` must be provided.

.. warning::

  ``FractionDHWLoadServed`` represents only the fraction of the hot water load associated with the hot water **fixtures**. Additional hot water load from the clothes washer/dishwasher will be automatically assigned to the appropriate water heater(s).

The ``Location`` must be one of the following:

==============================  ==================================  ========================================================  =========================
Location                        Description                         Temperature                                               Building Type
==============================  ==================================  ========================================================  =========================
living space                    Above-grade conditioned floor area  EnergyPlus calculation                                    Any
basement - conditioned          Below-grade conditioned floor area  EnergyPlus calculation                                    Any
basement - unconditioned                                            EnergyPlus calculation                                    Any
attic - unvented                                                    EnergyPlus calculation                                    Any
attic - vented                                                      EnergyPlus calculation                                    Any
garage                          Single-family (not shared parking)  EnergyPlus calculation                                    Any
crawlspace - unvented                                               EnergyPlus calculation                                    Any
crawlspace - vented                                                 EnergyPlus calculation                                    Any
other exterior                  Outside                             Outside                                                   Any
other housing unit              Unrated Conditioned Space           Same as conditioned space                                 Attached/Multifamily only
other heated space              Unrated Heated Space                Average of conditioned space and outside; minimum of 68F  Attached/Multifamily only
other multifamily buffer space  Multifamily Buffer Boundary         Average of conditioned space and outside; minimum of 50F  Attached/Multifamily only
other non-freezing space        Non-Freezing Space                  Floats with outside; minimum of 40F                       Attached/Multifamily only
==============================  ==================================  ========================================================  =========================

Depending on the type of water heater specified, additional elements are required/available:

========================================  ===================================  ===========  ==========  ===============  ========================  =================  =========================================  ==============================
WaterHeaterType                           UniformEnergyFactor or EnergyFactor  FuelType     TankVolume  HeatingCapacity  RecoveryEfficiency        UsesDesuperheater  WaterHeaterInsulation/Jacket/JacketRValue  RelatedHVACSystem
========================================  ===================================  ===========  ==========  ===============  ========================  =================  =========================================  ==============================
storage water heater                      required                             <any>        required    (optional)       required if non-electric  (optional)         (optional)                                 required if uses desuperheater
instantaneous water heater                required                             <any>                                                               (optional)                                                    required if uses desuperheater
heat pump water heater                    required                             electricity  required                                               (optional)         (optional)                                 required if uses desuperheater
space-heating boiler with storage tank                                                      required                                                                  (optional)                                 required         
space-heating boiler with tankless coil                                                                                                                                                                          required
========================================  ===================================  ===========  ==========  ===============  ========================  =================  =========================================  ==============================

For combi boiler systems, the ``RelatedHVACSystem`` must point to a ``HeatingSystem`` of type "Boiler".
For combi boiler systems with a storage tank, the storage tank losses (deg-F/hr) can be entered as ``StandbyLoss``; if not provided, a default value based on the `AHRI Directory of Certified Product Performance <https://www.ahridirectory.org>`_ will be calculated.

For water heaters that are connected to a desuperheater, the ``RelatedHVACSystem`` must either point to a ``HeatPump`` or a ``CoolingSystem``.

If the water heater is a shared system (i.e., serving multiple dwelling units or a shared laundry room), it should be described using ``IsSharedSystem='true'``.
In addition, the ``NumberofUnitsServed`` must be specified, where the value is the number of dwelling units served either indirectly (e.g., via shared laundry room) or directly.

HPXML Hot Water Distribution
****************************

A single ``Systems/WaterHeating/HotWaterDistribution`` must be provided if any water heating systems are specified.
Inputs including ``SystemType`` and ``PipeInsulation/PipeRValue`` must be provided.
Note: Any hot water distribution associated with a shared laundry room in attached/multifamily buildings should not be defined.

Standard
~~~~~~~~

For a ``SystemType/Standard`` (non-recirculating) system within the dwelling unit, the following element is required:

- ``PipingLength``: Measured length of hot water piping from the hot water heater (or from a shared recirculation loop serving multiple dwelling units) to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any)

Recirculation
~~~~~~~~~~~~~

For a ``SystemType/Recirculation`` system within the dwelling unit, the following elements are required:

- ``ControlType``: One of "manual demand control", "presence sensor demand control", "temperature", "timer", or "no control".
- ``RecirculationPipingLoopLength``: Measured recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements
- ``BranchPipingLoopLength``: Measured length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally
- ``PumpPower``: Pump power in Watts.

Shared Recirculation
~~~~~~~~~~~~~~~~~~~~

In addition to the hot water distribution systems within the dwelling unit, the pump energy use of a shared recirculation system can also be described using the following elements:

- ``extension/SharedRecirculation/NumberofUnitsServed``: Number of dwelling units served by the shared pump.
- ``extension/SharedRecirculation/PumpPower``: Shared pump power in Watts.
- ``extension/SharedRecirculation/ControlType``: One of "manual demand control", "presence sensor demand control", "timer", or "no control".

Drain Water Heat Recovery
~~~~~~~~~~~~~~~~~~~~~~~~~

In addition, a ``HotWaterDistribution/DrainWaterHeatRecovery`` (DWHR) may be specified.
The DWHR system is defined by:

- ``FacilitiesConnected``: 'one' if there are multiple showers and only one of them is connected to a DWHR; 'all' if there is one shower and it's connected to a DWHR or there are two or more showers connected to a DWHR
- ``EqualFlow``: 'true' if the DWHR supplies pre-heated water to both the fixture cold water piping and the hot water heater potable supply piping
- ``Efficiency``: As rated and labeled in accordance with CSA 55.1

HPXML Water Fixtures
********************

Water fixtures should be entered as ``Systems/WaterHeating/WaterFixture`` elements.
Each fixture must have ``WaterFixtureType`` and ``LowFlow`` elements provided.
Fixtures should be specified as low flow if they are <= 2.0 gpm.

HPXML Solar Thermal
*******************

A solar hot water system can be entered as a ``Systems/SolarThermal/SolarThermalSystem``.
The ``SystemType`` element must be 'hot water'.

Solar hot water systems can be described with either simple or detailed inputs.

Simple Model
~~~~~~~~~~~~

If using simple inputs, the following elements are used:

- ``SolarFraction``: Portion of total conventional hot water heating load (delivered energy and tank standby losses). Can be obtained from Directory of SRCC OG-300 Solar Water Heating System Ratings or NREL's `System Advisor Model <https://sam.nrel.gov/>`_ or equivalent.
- ``ConnectedTo``: Optional. If not specified, applies to all water heaters in the building. If specified, must point to a ``WaterHeatingSystem``.

Detailed Model
~~~~~~~~~~~~~~

If using detailed inputs, the following elements are used:

- ``CollectorArea``
- ``CollectorLoopType``: 'liquid indirect' or 'liquid direct' or 'passive thermosyphon'
- ``CollectorType``: 'single glazing black' or 'double glazing black' or 'evacuated tube' or 'integrated collector storage'
- ``CollectorAzimuth``
- ``CollectorTilt``
- ``CollectorRatedOpticalEfficiency``: FRTA (y-intercept); see Directory of SRCC OG-100 Certified Solar Collector Ratings
- ``CollectorRatedThermalLosses``: FRUL (slope, in units of Btu/hr-ft^2-R); see Directory of SRCC OG-100 Certified Solar Collector Ratings
- ``StorageVolume``
- ``ConnectedTo``: Must point to a ``WaterHeatingSystem``. The connected water heater cannot be of type space-heating boiler or attached to a desuperheater.

HPXML Photovoltaics
*******************

Each solar electric (photovoltaic) system should be entered as a ``Systems/Photovoltaics/PVSystem``.
The following elements, some adopted from the `PVWatts model <https://pvwatts.nrel.gov>`_, are required for each PV system:

- ``IsSharedSystem``: true or false
- ``Location``: 'ground' or 'roof' mounted
- ``ModuleType``: 'standard', 'premium', or 'thin film'
- ``Tracking``: 'fixed' or '1-axis' or '1-axis backtracked' or '2-axis'
- ``ArrayAzimuth``
- ``ArrayTilt``
- ``MaxPowerOutput``
- ``InverterEfficiency``: Default is 0.96.
- ``SystemLossesFraction``: Default is 0.14. System losses include soiling, shading, snow, mismatch, wiring, degradation, etc.

If the PV system is a shared system (i.e., serving multiple dwelling units), it should be described using ``IsSharedSystem='true'``.
In addition, the total number of bedrooms across all dwelling units served by the system must be entered as ``extension/NumberofBedroomsServed``.
PV generation will be apportioned to the dwelling unit using its number of bedrooms divided by the total number of bedrooms in the building.

HPXML Appliances
----------------

This section describes elements specified in HPXML's ``Appliances``.
Many of the appliances' inputs are derived from EnergyGuide labels.

The ``Location`` for each appliance must be provided as one of the following:

==============================  ==================================  =========================
Location                        Description                         Building Type
==============================  ==================================  =========================
living space                    Above-grade conditioned floor area  Any
basement - conditioned          Below-grade conditioned floor area  Any
basement - unconditioned                                            Any
garage                          Single-family (not shared parking)  Any
other housing unit              Unrated Conditioned Space           Attached/Multifamily only
other heated space              Unrated Heated Space                Attached/Multifamily only
other multifamily buffer space  Multifamily Buffer Boundary         Attached/Multifamily only
other non-freezing space        Non-Freezing Space                  Attached/Multifamily only
==============================  ==================================  =========================

HPXML Clothes Washer
********************

A single ``Appliances/ClothesWasher`` element may be specified.
The ``IsSharedAppliance`` element must be provided.

If no clothes washer is located within the Rated Home, a clothes washer in the nearest shared laundry room on the project site shall be used if available for daily use by the occupants of the Rated Home.
If there are multiple clothes washers, the clothes washer with the highest Label Energy Rating (kWh/yr) shall be used.

The efficiency of the clothes washer can either be entered as an ``IntegratedModifiedEnergyFactor`` or a ``ModifiedEnergyFactor``.
Several other inputs from the EnergyGuide label must be provided as well.

If the clothes washer is a shared appliance (i.e., in a shared laundry room), it should be described using ``IsSharedAppliance='true'``.
In addition, the following elements must be provided:

- ``AttachedToWaterHeatingSystem``: Reference a shared water heater.
- ``NumberofUnitsServed``: The number of dwelling units served by the shared laundry room.
- ``NumberofUnits``: The number of clothes washers in the shared laundry room.

HPXML Clothes Dryer
*******************

A single ``Appliances/ClothesDryer`` element may be specified.
The ``IsSharedAppliance`` element must be provided.

If no clothes dryer is located within the Rated Home, a clothes dryer in the nearest shared laundry room on the project site shall be used if available for daily use by the occupants of the Rated Home.
If there are multiple clothes dryers, the clothes dryer with the lowest Energy Factor or Combined Energy Factor shall be used.

The dryer's ``FuelType`` and ``ControlType`` ("timer" or "moisture") must be provided.
The efficiency of the clothes dryer can either be entered as a ``CombinedEnergyFactor`` or an ``EnergyFactor``.

If the clothes dryer is a shared appliance (i.e., in a shared laundry room), it should be described using ``IsSharedAppliance='true'``.
In addition, the following elements must be provided:

- ``NumberofUnitsServed``: The number of dwelling units served by the shared laundry room.
- ``NumberofUnits``: The number of clothes dryers in the shared laundry room.

HPXML Dishwasher
****************

A single ``Appliances/Dishwasher`` element may be specified.
The ``IsSharedAppliance`` element must be provided.

If no dishwasher is located within the Rated Home, a dishwasher in the nearest shared kitchen in the building shall be used only if available for daily use by the occupants of the Rated Home.
If there are multiple dishwashers, the dishwasher with the lowest Energy Factor (highest kWh/yr) shall be used.

The efficiency of the dishwasher can either be entered as a ``RatedAnnualkWh`` or an ``EnergyFactor``.
The dishwasher's ``PlaceSettingCapacity`` also must be provided as well as other inputs from the EnergyGuide label.

If the dishwasher is a shared appliance (i.e., in a shared laundry room), it should be described using ``IsSharedAppliance='true'``.
In addition, the following elements must be provided:

- ``AttachedToWaterHeatingSystem``: Reference a shared water heater.

HPXML Refrigerator
******************

A single ``Appliances/Refrigerator`` element may be specified.

If there are multiple refrigerators, the total energy consumption of all refrigerators/freezers shall be used along with the location that represents the majority of power consumption.

The efficiency of the refrigerator must be entered as ``RatedAnnualkWh``.

HPXML Cooking Range/Oven
************************

A single pair of ``Appliances/CookingRange`` and ``Appliances/Oven`` elements may be specified.

The ``FuelType`` of the range and whether it ``IsInduction``, as well as whether the oven ``IsConvection``, must be provided.

HPXML Lighting
--------------

This section describes elements specified in HPXML's ``Lighting``.

HPXML Lighting Groups
*********************

The building's lighting is described by nine ``LightingGroup`` elements, each of which is the combination of:

- ``LightingType``: ``LightEmittingDiode``, ``CompactFluorescent``, and ``FluorescentTube``
- ``LightingGroup/Location``: 'interior', 'garage', and 'exterior'

Use ``LightEmittingDiode`` for Tier II qualifying light fixtures; use ``CompactFluorescent`` and/or ``FluorescentTube`` for Tier I qualifying light fixtures.

The fraction of lamps of the given type in the given location are provided as the ``LightingGroup/FractionofUnitsInLocation``.
The fractions for a given location cannot sum to greater than 1.
If the fractions sum to less than 1, the remainder is assumed to be incandescent lighting.
Garage lighting values are ignored if the building has no garage.

HPXML Ceiling Fans
******************

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
