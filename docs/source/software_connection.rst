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

With the exception of interior surfaces between conditioned spaces, *all* surfaces of a building, not just those that make up the thermal boundary of the building, must be specified in the HPXML file.
These surfaces are used by EnergyPlus to calculate the hourly air temperature in each unconditioned space.
For example, the garage's temperature is influenced by its connections to the ground, the conditioned space, and the ambient environment.
In turn, this temperature affects equipment (e.g., ducts, water heater, etc.) located in the garage as well as the heat transfer across any walls between the garage and conditioned space.

For software tools that do not collect inputs for every surface in the building, the software developers will need to make assumptions about these additional surfaces.

For interzonal surfaces (e.g., a wall between a conditioned basement and an unconditioned basement), the wall can be associated with either HPXML element. 
(It should not be specified in both.)

.. warning::

  It is the software tool's responsibility to provide all building surfaces. 
  While some error-checking is included in the workflow, it is not possible to know whether certain surfaces have been left out.

Air Leakage
***********

Building air leakage characterized by air changes per hour at 50 pascals pressure difference (ACH50) is entered at ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage/AirLeakage``. A value of "50" must be specified for ``AirInfiltrationMeasurement/HousePressure`` and a value of "ACH" must be specified for ``BuildingAirLeakage/UnitofMeasure``.

In addition, the building's volume associated with the air leakage measurement is provided in HPXML's ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/InfiltrationVolume``. The definition of infiltration volume can be found in the ERI 301 Standard.

Attics/Roofs
************

One or more attics/roofs must be specified in ``Enclosure/Attics/Attic``.

In the ``Attic/AtticType`` field, attics/roofs can be described as:

#. Unvented (unconditioned)
#. Vented (unconditioned)
#. Conditioned
#. Flat roof
#. Cathedral ceiling (vaulted)

See Surfaces............. FIXME

TODO

Foundations
***********

One or more foundations must be specified in ``Enclosure/Foundations/Foundation``.

See Surfaces............. FIXME

TODO

Surfaces
********

Surfaces described in HPXML include:

=============================  ====================================================================================
Surface Type                   Notes
=============================  ====================================================================================
``Attic/Roofs/Roof``           Required.
``Attic/Walls/Wall``           Optional. Provide if, e.g., gable walls or knee walls present.
``Attic/Floors/Floor``         Optional. Only required for unconditioned attics.
``Foundation/FrameFloor``      Optional. Only required for unconditioned basements, crawlspaces, or ambient foundations.
``Foundation/FoundationWall``  Optional. Only required for basements and crawlspaces.
``Foundation/Slab``            Required for all foundation types except ambient.
``RimJoists/RimJoist``         Optional. Provide if rim joists are present.
``Walls/Wall``                 Required. Attic/foundation walls should be specified elsewhere.
=============================  ====================================================================================

Surfaces are primarily described by their ``Area`` and ``Insulation/AssemblyEffectiveRValue``.
(The exception is ``Foundation/Slab``, where perimeter/under-slab insulation R-values and depths/widths are instead required.)

Many surfaces have ``AdjacentTo`` fields. 
For attics/foundations, the field specifies the boundary condition on the *other* side of the surface. 
For example, "outside" (not "attic") would be the value for attic gable walls while "ground" (not "basement") would be the value for foundation walls.
For other walls or rim joists, both ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo`` fields are specified.

A number of additional fields (e.g., ``SolarAbsorptance``, ``Emittance``, ``Pitch``, ``RadiantBarrier``, etc.) are required depending on the surface type.

Roofs, wall, and rim joists also have a field for ``Azimuth``. 
The azimuth is currently optional to accommodate software tools that, e.g., allow users to enter a single wall for the entire building.
However, providing the azimuth for these surfaces is strongly encouraged and may become required in the future.

TODO

Sub-Surfaces
************

Sub-surfaces described in HPXML include windows, doors, and skylights.

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
