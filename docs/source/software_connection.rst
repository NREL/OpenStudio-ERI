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

HPXML for ERI
-------------

PXML is an flexible and extensible format, where nearly all fields in the schema are optional and custom fields can be included.
Because of this, an ERI Use Case for HPXML has been developed that specifies the HPXML fields or enumeration choices required to run the workflow.

The `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb>`_ is defined as a set of conditional XPath expressions.

It operates on top of **HPXML v3 (proposed)** files.

ERI Version
~~~~~~~~~~~

The version of the ERI calculation to be run is specified inside the HPXML file itself at ``/HPXML/SoftwareInfo/extension/ERICalculation/Version``. 
For example, a value of "2014AE" tells the workflow to use ANSI/RESNET/ICC© 301-2014 with both Addendum A (Amendment on Domestic Hot Water Systems) and Addendum E (House Size Index Adjustment Factors) included.

.. note:: 

  Valid choices for ERI version can be looked up in the `ERI Use Case <https://github.com/NREL/OpenStudio-ERI/blob/master/measures/301EnergyRatingIndexRuleset/resources/301validator.rb>`_.

Building Summary
~~~~~~~~~~~~~~~~

This section describes fields specified in HPXML's ``/HPXML/Building/BuildingDetails/BuildingSummary``. It is used for high-level building information needed for an ERI calculation including conditioned floor area, number of bedrooms, number of conditioned floors, etc.

The ``BuildingSummary/Site/FuelTypesAvailable`` field is used to determine whether the home has access to natural gas or fossil fuel delivery (specified by any value other than "electricity").
This information may be used for determining the heating system, as specified by the ERI 301 Standard.

Climate and Weather
~~~~~~~~~~~~~~~~~~~

This section describes fields specified in HPXML's ``/HPXML/Building/BuildingDetails/ClimateandRiskZones``.

``ClimateandRiskZones/ClimateZoneIECC`` specifies the IECC climate zone(s) for years required by the ERI 301 Standard.

``ClimateandRiskZones/WeatherStation`` specifies the EnergyPlus weather file (EPW) to be used in the simulation. 
The ``WeatherStation/WMO`` must be one of the acceptable WMO station numbers found in the `weather/data.csv <https://github.com/NREL/OpenStudio-ERI/blob/master/weather/data.csv>`_ file.

.. note:: 

  In the future, we hope to provide an automated lookup capability based on a building's address/zipcode or similar information. But for now, each software tool is responsible for providing this information.

Enclosure
~~~~~~~~~

This section describes fields specified in HPXML's ``/HPXML/Building/BuildingDetails/Enclosure``.

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

Air Leakage
***********

Building air leakage characterized by air changes per hour at 50 pascals pressure difference (ACH50) is entered at ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage/AirLeakage``. 
A value of "50" must be specified for ``AirInfiltrationMeasurement/HousePressure`` and a value of "ACH" must be specified for ``BuildingAirLeakage/UnitofMeasure``.

In addition, the building's volume associated with the air leakage measurement is provided in HPXML's ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/InfiltrationVolume``.

Roofs
*****

TODO

Walls
*****

TODO

Rim Joists
**********

TODO

Foundation Walls
****************

Any wall that is in contact with the ground should be specified as a ``FoundationWall``. Other walls (e.g., wood framed walls) that are connected to a below-grade space but have no contact with the ground should be specified as ``Walls`` and not ``FoundationWalls``.

*Exterior* foundation walls (i.e., those that fall along the perimeter of the building's footprint) should use "ground" for ``ExteriorAdjacentTo`` and the appropriate space type (e.g., "basement - unconditioned") for ``InteriorAdjacentTo``.

*Interior* foundation walls should be specified with two appropriate space types (e.g., "crawlspace - unvented" and "garage", or "basement - unconditioned" and "crawlspace - unvented") for ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo``.
Interior foundation walls should never use "ground" for ``ExteriorAdjacentTo`` even if the foundation wall has some contact with the ground due to the difference in below-grade depths of the two space types.
The choice of space type assignment for interior vs exterior is arbitrary.

Foundations must include a ``Height`` as well as a ``DepthBelowGrade``. 
For exterior foundation walls, the depth below grade is relative to the ground plane.
For interior foundation walls, the depth below grade **should not** be thought of as relative to the ground plane, but rather as the depth of foundation wall in contact with the ground.
For example, an interior foundation wall between an 8 ft conditioned basement and a 3 ft crawlspace has a height of 8 ft and a depth below grade of 5 ft.
Alternatively, an interior foundation wall between an 8 ft conditioned basement and an 8 ft unconditioned basement has a height of 8 ft and a depth below grade of 0 ft.

Foundation wall insulation can be described in two ways: 

Option 1. A continuous insulation layer with ``NominalRValue`` and ``InsulationHeight``. 
An insulation layer is useful for describing foundation wall insulation that doesn't span the entire height (e.g., 4 ft of insulation for an 8 ft conditioned basement). 
When an insulation layer R-value is specified, it is modeled with a concrete wall (whose ``Thickness`` is provided) as well as air film resistances as appropriate.

Option 2. An ``AssemblyEffectiveRValue``. 
When instead providing an assembly effective R-value, the R-value should include the concrete wall and an interior air film resistance. 
The exterior air film resistance (for any above-grade exposure) or any soil thermal resistance should not be included.

Floors
******

TODO

Slabs
*****

TODO

Windows/Skylights
*****************

TODO

Doors
*****

TODO

Systems
~~~~~~~

TODO

HVAC
****

TODO

Mechanical Ventilation
**********************

TODO

Water Heating
*************

TODO

Photovoltaics
*************

TODO

Appliances
~~~~~~~~~~

TODO

Clothes Washer
**************

TODO

Clothes Dryer
*************

TODO

Dishwasher
**********

TODO

Refrigerator
************

TODO

Cooking Range
*************

TODO

Lighting
~~~~~~~~

TODO

Ceiling Fans
~~~~~~~~~~~~

TODO

Validating & Debugging Errors
-----------------------------

TODO

Example Files
-------------

TODO
