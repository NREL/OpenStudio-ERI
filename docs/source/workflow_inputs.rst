.. _workflow_inputs:

Workflow Inputs
===============

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
  However, OpenStudio-ERI does automatically check for valid data types (e.g., integer vs string), enumeration choices, and numeric values within min/max.

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

High-level simulation inputs are entered in ``/HPXML/SoftwareInfo``.

HPXML ERI Calculation
*********************

The version of the ERI calculation is entered in ``/HPXML/SoftwareInfo/extension/ERICalculation``.

  ===========  ========  =======  ===========  ========  =======  ==================================
  Element      Type      Units    Constraints  Required  Default  Description
  ===========  ========  =======  ===========  ========  =======  ==================================
  ``Version``  string             See [#]_     Yes                Version of 301 Standard w/ addenda
  ===========  ========  =======  ===========  ========  =======  ==================================
  
  .. [#] Version choices are "latest", "2019AB", "2019A", "2019", "2014ADEGL", "2014ADEG", "2014ADE", "2014AD", "2014A", or "2014".
         For example, a value of "2019AB" tells the workflow to use ANSI/RESNET/ICC© 301-2019 with both Addendum A and Addendum B included.
         A value of "latest" can be used to always point to the latest version available.

HPXML Building Summary
----------------------

High-level building summary information is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary``. 

HPXML Site
**********

Each fuel type available to the building is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/Site/FuelTypesAvailable``.

  ========  ========  =======  ===========  ========  =======  ============================
  Element   Type      Units    Constraints  Required  Default  Description
  ========  ========  =======  ===========  ========  =======  ============================
  ``Fuel``  string             See [#]_     Yes                Fuel name
  ========  ========  =======  ===========  ========  =======  ============================
  
  .. [#] Fuel choices can be found at the `HPXML Toolbox website <https://hpxml.nrel.gov/datadictionary/3.0.0/Building/BuildingDetails/BuildingSummary/Site/FuelTypesAvailable/Fuel>`_.

.. note::

  The provided fuels are used to determine whether the home has access to natural gas or fossil fuel delivery (specified by any value other than "electricity").
  This information may be used for determining the heating system, as specified by the ERI 301 Standard.

HPXML Building Construction
***************************

Building construction is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction``.

  =======================================  ========  =========  ===========  ========  ========  =======================================================================
  Element                                  Type      Units      Constraints  Required  Default   Notes
  =======================================  ========  =========  ===========  ========  ========  =======================================================================
  ``ResidentialFacilityType``              string               See [#]_     Yes                 Type of dwelling unit
  ``NumberofConditionedFloors``            double               > 0          Yes                 Number of conditioned floors (including a basement)
  ``NumberofConditionedFloorsAboveGrade``  double               > 0          Yes                 Number of conditioned floors above grade (including a walkout basement)
  ``NumberofBedrooms``                     integer              > 0          Yes                 Number of bedrooms
  ``ConditionedFloorArea``                 double    ft2        > 0          Yes                 Floor area within conditioned space boundary
  ``ConditionedBuildingVolume``            double    ft3 or ft  > 0          Yes                 Volume within conditioned space boundary
  =======================================  ========  =========  ===========  ========  ========  =======================================================================

  .. [#] ResidentialFacilityType choices are "single-family detached", "single-family attached", "apartment unit", or "manufactured home".

HPXML Weather Station
---------------------

Weather information is entered in ``/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation``.

  =========================  ======  =======  ===========  ========  =======  ==============================================
  Element                    Type    Units    Constraints  Required  Default  Notes
  =========================  ======  =======  ===========  ========  =======  ==============================================
  ``SystemIdentifier``       id                            Yes                Unique identifier
  ``Name``                   string                        Yes                Name of weather station
  ``extension/EPWFilePath``  string                        Yes                Path to the EnergyPlus weather file (EPW) [#]_
  =========================  ======  =======  ===========  ========  =======  ==============================================

  .. [#] A full set of U.S. TMY3 weather files can be `downloaded here <https://data.nrel.gov/system/files/128/tmy3s-cache-csv.zip>`_.

HPXML Climate Zone
------------------

The IECC climate zone is entered in ``/HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC``.

  =========================  =======  =======  ===========  ========  =======  =========
  Element                    Type     Units    Constraints  Required  Default  Notes
  =========================  =======  =======  ===========  ========  =======  =========
  ``Year``                   integer           See [#]_     Yes                IECC year
  ``ClimateZone``            string            See [#]_     Yes                IECC zone
  =========================  =======  =======  ===========  ========  =======  =========

  .. [#] Year choices are 2003, 2006, 2009, or 2012.
  .. [#] ClimateZone choices are "1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", or "8".

HPXML Enclosure
---------------

The dwelling unit's enclosure is entered in ``/HPXML/Building/BuildingDetails/Enclosure``.

All surfaces that bound different space types of the dwelling unit (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.
For software tools that do not collect sufficient inputs for every required surface, the software developers will need to make assumptions about these surfaces or collect additional input.

Interior partition surfaces (e.g., walls between rooms inside conditioned space, or the floor between two conditioned stories) can be excluded.

For single-family attached (SFA) or multifamily (MF) buildings, surfaces between unconditioned space and the neighboring unit's same unconditioned space should set ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo`` to the same value.
For example, a foundation wall between the unit's vented crawlspace and the neighboring unit's vented crawlspace would use ``InteriorAdjacentTo="crawlspace - vented"`` and ``ExteriorAdjacentTo="crawlspace - vented"``.

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth to be specified. 
Rather, only the windows/skylights themselves require an azimuth. 
Thus, software tools can choose to use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

HPXML Air Infiltration
**********************

Building air leakage is entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement``.

  ====================================  ======  =====  ===========  =========  =======  ========================================================
  Element                               Type    Units  Constraints  Required   Default  Notes
  ====================================  ======  =====  ===========  =========  =======  ========================================================
  ``SystemIdentifier``                  id                          Yes                 Unique identifier
  ``BuildingAirLeakage/UnitofMeasure``  string         See [#]_     Yes                 Units for air leakage
  ``HousePressure``                     double  Pa     > 0          See [#]_            House pressure with respect to outside, typically ~50 Pa
  ``BuildingAirLeakage/AirLeakage``     double         > 0          Yes                 Value for air leakage
  ``InfiltrationVolume``                double  ft3    > 0          Yes                 Volume associated with the air leakage measurement
  ====================================  ======  =====  ===========  =========  =======  ========================================================

  .. [#] UnitofMeasure choices are "ACH" (air changes per hour at user-specified pressure), "CFM" (cubic feet per minute at user-specified pressure), or "ACHnatural" (natural air changes per hour).
  .. [#] HousePressure only required if BuildingAirLeakage/UnitofMeasure is not "ACHnatural".

HPXML Attics
************

If the dwelling unit has an unvented attic, whether it is within the infiltration volume is entered in ``/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic[AtticType/Attic[Vented="false"]]``.

  ============================  =======  =====  ===========  ========  =======  ===============================================
  Element                       Type     Units  Constraints  Required  Default  Notes
  ============================  =======  =====  ===========  ========  =======  ===============================================
  ``WithinInfiltrationVolume``  boolean                      Yes                In accordance with ANSI/RESNET/ICC Standard 380
  ============================  =======  =====  ===========  ========  =======  ===============================================

If the dwelling unit has a vented attic, attic ventilation information can be optionally entered in ``/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic[AtticType/Attic[Vented="true"]]/VentilationRate``.

  =================  ======  =====  ===========  ========  =======  ==========================
  Element            Type    Units  Constraints  Required  Default  Notes
  =================  ======  =====  ===========  ========  =======  ==========================
  ``UnitofMeasure``  string         See [#]_     No        SLA      Units for ventilation rate
  ``Value``          double         > 0          No        1/300    Value for ventilation rate
  =================  ======  =====  ===========  ========  =======  ==========================

  .. [#] UnitofMeasure choices are "SLA" (specific leakage area) or "ACHnatural" (natural air changes per hour).

HPXML Foundations
*****************

If the dwelling unit has an unconditioned basement, whether it is within the infiltration volume is entered in ``Enclosure/Foundations/Foundation/FoundationType/Basement[Conditioned='false']``.

  ============================  =======  =====  ===========  ========  =======  ===============================================
  Element                       Type     Units  Constraints  Required  Default  Notes
  ============================  =======  =====  ===========  ========  =======  ===============================================
  ``WithinInfiltrationVolume``  boolean                      Yes                In accordance with ANSI/RESNET/ICC Standard 380
  ============================  =======  =====  ===========  ========  =======  ===============================================

If the dwelling unit has an unvented crawlspace, whether it is within the infiltration volume is entered in ``Enclosure/Foundations/Foundation/FoundationType/Crawlspace[Vented='false']``.

  ============================  =======  =====  ===========  ========  =======  ===============================================
  Element                       Type     Units  Constraints  Required  Default  Notes
  ============================  =======  =====  ===========  ========  =======  ===============================================
  ``WithinInfiltrationVolume``  boolean                      Yes                In accordance with ANSI/RESNET/ICC Standard 380
  ============================  =======  =====  ===========  ========  =======  ===============================================

If the dwelling unit has a vented crawlspace, crawlspace ventilation information can be optionally entered in ``/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented="true"]]/VentilationRate``.

  =================  ======  =====  ===========  ========  =======  ==========================
  Element            Type    Units  Constraints  Required  Default  Notes
  =================  ======  =====  ===========  ========  =======  ==========================
  ``UnitofMeasure``  string         See [#]_     No        SLA      Units for ventilation rate
  ``Value``          double         > 0          No        1/150    Value for ventilation rate
  =================  ======  =====  ===========  ========  =======  ==========================

  .. [#] UnitofMeasure only choice is "SLA" (specific leakage area).

HPXML Roofs
***********

Each pitched or flat roof surface that is exposed to ambient conditions is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof``.

For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``FrameFloor`` and not a ``Roof``.

  ======================================  =========  ============  ===========  =========  ========  ==================================
  Element                                 Type       Units         Constraints  Required   Default   Notes
  ======================================  =========  ============  ===========  =========  ========  ==================================
  ``SystemIdentifier``                    id                                    Yes                  Unique identifier
  ``InteriorAdjacentTo``                  string                   See [#]_     Yes                  Interior adjacent space type
  ``Area``                                double     ft2           > 0          Yes                  Gross area (including skylights)
  ``Azimuth``                             integer    deg           0-359        No         See [#]_  Azimuth (clockwise from North)
  ``SolarAbsorptance``                    double                   0-1          Yes                  Solar absorptance
  ``Emittance``                           double                   0-1          Yes                  Emittance
  ``Pitch``                               integer    ?:12          >= 0         Yes                  Pitch
  ``RadiantBarrier``                      boolean                               Yes                  Presence of radiant barrier
  ``RadiantBarrier/RadiantBarrierGrade``  integer                  1-3          See [#]_             Radiant barrier installation grade
  ``Insulation/SystemIdentifier``         id                                    Yes                  Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double     F-ft2-hr/Btu  > 0          Yes                  Assembly R-value [#]_
  ======================================  =========  ============  ===========  =========  ========  ==================================

  .. [#] InteriorAdjacentTo choices are "attic - vented", "attic - unvented", "living space", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Azimuth not provided, modeled as four surfaces of equal area facing every direction.
  .. [#] RadiantBarrierGrade only required if RadiantBarrier is provided.
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Rim Joists
****************

Each rim joist surface (i.e., the perimeter of floor joists typically found between stories of a building or on top of a foundation wall) is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist``.

  ======================================  =======  ============  ===========  ========  ===========  ==============================
  Element                                 Type     Units         Constraints  Required  Default      Notes
  ======================================  =======  ============  ===========  ========  ===========  ==============================
  ``SystemIdentifier``                    id                                  Yes                    Unique identifier
  ``ExteriorAdjacentTo``                  string                 See [#]_     Yes                    Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                 See [#]_     Yes                    Interior adjacent space type
  ``Area``                                double   ft2           > 0          Yes                    Gross area
  ``Azimuth``                             integer  deg           0-359        No        See [#]_     Azimuth (clockwise from North)
  ``SolarAbsorptance``                    double                 0-1          Yes                    Solar absorptance
  ``Emittance``                           double                 0-1          Yes                    Emittance
  ``Insulation/SystemIdentifier``         id                                  Yes                    Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double   F-ft2-hr/Btu  > 0          Yes                    Assembly R-value [#]_
  ======================================  =======  ============  ===========  ========  ===========  ==============================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "living space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Azimuth not provided, modeled as four surfaces of equal area facing every direction.
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Walls
***********

Each wall that has no contact with the ground and bounds a space type is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall``.

  ======================================  =======  ============  ===========  ========  ===========  ====================================
  Element                                 Type     Units         Constraints  Required  Default      Notes
  ======================================  =======  ============  ===========  ========  ===========  ====================================
  ``SystemIdentifier``                    id                                  Yes                    Unique identifier
  ``ExteriorAdjacentTo``                  string                 See [#]_     Yes                    Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                 See [#]_     Yes                    Interior adjacent space type
  ``WallType``                            element                1 [#]_       Yes                    Wall type (for thermal mass)
  ``Area``                                double   ft2           > 0          Yes                    Gross area (including doors/windows)
  ``Azimuth``                             integer  deg           0-359        No        See [#]_     Azimuth (clockwise from North)
  ``SolarAbsorptance``                    double                 0-1          Yes                    Solar absorptance
  ``Emittance``                           double                 0-1          Yes                    Emittance
  ``Insulation/SystemIdentifier``         id                                  Yes                    Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double   F-ft2-hr/Btu  > 0          Yes                    Assembly R-value [#]_
  ======================================  =======  ============  ===========  ========  ===========  ====================================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "living space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] WallType child element choices are ``WoodStud``, ``DoubleWoodStud``, ``ConcreteMasonryUnit``, ``StructurallyInsulatedPanel``, ``InsulatedConcreteForms``, ``SteelFrame``, ``SolidConcrete``, ``StructuralBrick``, ``StrawBale``, ``Stone``, ``LogWall``, or ``Adobe``.
  .. [#] If Azimuth not provided, modeled as four surfaces of equal area facing every direction.
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Foundation Walls
**********************

Each wall that is in contact with the ground should be specified as an ``/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall``.

Other walls (e.g., wood framed walls) that are connected to a below-grade space but have no contact with the ground should be specified as a ``Wall`` and not a ``FoundationWall``.

  ==============================================================  ========  ============  ===========  =========  ========  ====================================
  Element                                                         Type      Units         Constraints  Required   Default   Notes
  ==============================================================  ========  ============  ===========  =========  ========  ====================================
  ``SystemIdentifier``                                            id                                   Yes                  Unique identifier
  ``ExteriorAdjacentTo``                                          string                  See [#]_     Yes                  Exterior adjacent space type [#]_
  ``InteriorAdjacentTo``                                          string                  See [#]_     Yes                  Interior adjacent space type
  ``Height``                                                      double    ft            > 0          Yes                  Total height
  ``Area``                                                        double    ft2           > 0          Yes                  Gross area (including doors/windows)
  ``Azimuth``                                                     integer   deg           0-359        No         See [#]_  Azimuth (clockwise from North)
  ``Thickness``                                                   double    inches        > 0          Yes                  Thickness excluding interior framing
  ``DepthBelowGrade``                                             double    ft            >= 0         Yes                  Depth below grade [#]_
  ``Insulation/SystemIdentifier``                                 id                                   Yes                  Unique identifier
  ``Insulation/Layer[InstallationType="continuous - interior"]``  element                 0-1          See [#]_             Interior insulation layer
  ``Insulation/Layer[InstallationType="continuous - exterior"]``  element                 0-1          See [#]_             Exterior insulation layer
  ``Insulation/AssemblyEffectiveRValue``                          double    F-ft2-hr/Btu  > 0          See [#]_             Assembly R-value [#]_
  ==============================================================  ========  ============  ===========  =========  ========  ====================================

  .. [#] ExteriorAdjacentTo choices are "ground", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] Interior foundation walls (e.g., between basement and crawlspace) should **not** use "ground" even if the foundation wall has some contact with the ground due to the difference in below-grade depths of the two adjacent spaces.
  .. [#] If Azimuth not provided, modeled as four surfaces of equal area facing every direction.
  .. [#] For exterior foundation walls, depth below grade is relative to the ground plane.
         For interior foundation walls, depth below grade is the vertical span of foundation wall in contact with the ground.
         For example, an interior foundation wall between an 8 ft conditioned basement and a 3 ft crawlspace has a height of 8 ft and a depth below grade of 5 ft.
         Alternatively, an interior foundation wall between an 8 ft conditioned basement and an 8 ft unconditioned basement has a height of 8 ft and a depth below grade of 0 ft.
  .. [#] Layer[InstallationType="continuous - interior"] only required if AssemblyEffectiveRValue is not provided.
  .. [#] Layer[InstallationType="continuous - exterior"] only required if AssemblyEffectiveRValue is not provided.
  .. [#] AssemblyEffectiveRValue only required if Layer elements are not provided.
  .. [#] AssemblyEffectiveRValue includes all material layers, interior air film, and insulation installation grade.
         R-value should **not** include exterior air film (for any above-grade exposure) or any soil thermal resistance.

If insulation layers are provided, additional information is entered in each ``FoundationWall/Insulation/Layer``.

  ==========================================  ========  ============  ===========  ========  =======  ======================================================================
  Element                                     Type      Units         Constraints  Required  Default  Notes
  ==========================================  ========  ============  ===========  ========  =======  ======================================================================
  ``NominalRValue``                           double    F-ft2-hr/Btu  >= 0         Yes                R-value of the foundation wall insulation; use zero if no insulation
  ``extension/DistanceToTopOfInsulation``     double    ft            >= 0         Yes                Vertical distance from top of foundation wall to top of insulation
  ``extension/DistanceToBottomOfInsulation``  double    ft            >= 0         Yes                Vertical distance from top of foundation wall to bottom of insulation
  ==========================================  ========  ============  ===========  ========  =======  ======================================================================

HPXML Frame Floors
******************

Each horizontal floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor``.

  ======================================  ========  ============  ===========  ========  =======  ============================
  Element                                 Type      Units         Constraints  Required  Default  Notes
  ======================================  ========  ============  ===========  ========  =======  ============================
  ``SystemIdentifier``                    id                                   Yes                Unique identifier
  ``ExteriorAdjacentTo``                  string                  See [#]_     Yes                Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                  See [#]_     Yes                Interior adjacent space type
  ``Area``                                double    ft2           > 0          Yes                Gross area
  ``Insulation/SystemIdentifier``         id                                   Yes                Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double    F-ft2-hr/Btu  > 0          Yes                Assembly R-value [#]_
  ======================================  ========  ============  ===========  ========  =======  ============================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "living space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

For frame floors adjacent to "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space", additional information is entered in ``FrameFloor``.

  ======================================  ========  =====  ==============  ========  =======  ==========================================
  Element                                 Type      Units  Constraints     Required  Default  Notes
  ======================================  ========  =====  ==============  ========  =======  ==========================================
  ``extension/OtherSpaceAboveOrBelow``    string           See [#]_        Yes                Specifies if above/below the MF space type
  ======================================  ========  =====  ==============  ========  =======  ==========================================

  .. [#] OtherSpaceAboveOrBelow choices are "above" or "below".

HPXML Slabs
***********

Each space type that borders the ground (i.e., basements, crawlspaces, garages, and slab-on-grade foundations) should have a slab entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab``.

  ===========================================  ========  ============  ===========  =========  ========  ====================================================
  Element                                      Type      Units         Constraints  Required   Default   Notes
  ===========================================  ========  ============  ===========  =========  ========  ====================================================
  ``SystemIdentifier``                         id                                   Yes                  Unique identifier
  ``InteriorAdjacentTo``                       string                  See [#]_     Yes                  Interior adjacent space type
  ``Area``                                     double    ft2           > 0          Yes                  Gross area
  ``Thickness``                                double    inches        >= 0         Yes                  Thickness [#]_
  ``ExposedPerimeter``                         double    ft            > 0          Yes                  Perimeter exposed to ambient conditions [#]_
  ``PerimeterInsulationDepth``                 double    ft            >= 0         Yes                  Depth from grade to bottom of vertical insulation
  ``UnderSlabInsulationWidth``                 double    ft            >= 0         See [#]_             Width from slab edge inward of horizontal insulation
  ``UnderSlabInsulationSpansEntireSlab``       boolean                              See [#]_             Whether horizontal insulation spans entire slab
  ``DepthBelowGrade``                          double    ft            >= 0         See [#]_             Depth from the top of the slab surface to grade
  ``PerimeterInsulation/SystemIdentifier``     id                                   Yes                  Unique identifier
  ``PerimeterInsulation/Layer/NominalRValue``  double    F-ft2-hr/Btu  >= 0         Yes                  R-value of vertical insulation
  ``UnderSlabInsulation/SystemIdentifier``     id                                   Yes                  Unique identifier
  ``UnderSlabInsulation/Layer/NominalRValue``  double    F-ft2-hr/Btu  >= 0         Yes                  R-value of horizontal insulation
  ``extension/CarpetFraction``                 double    frac          0-1          Yes                  Fraction of slab covered by carpet
  ``extension/CarpetRValue``                   double    F-ft2-hr/Btu  >= 0         Yes                  Carpet R-value
  ===========================================  ========  ============  ===========  =========  ========  ====================================================

  .. [#] InteriorAdjacentTo choices are "living space", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] For a crawlspace with a dirt floor, enter a thickness of zero.
  .. [#] ExposedPerimeter includes any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
         So a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.
  .. [#] UnderSlabInsulationWidth only required if UnderSlabInsulationSpansEntireSlab=true is not provided.
  .. [#] UnderSlabInsulationSpansEntireSlab=true only required if UnderSlabInsulationWidth is not provided.
  .. [#] DepthBelowGrade only required if the attached foundation has no ``FoundationWalls``.
         For foundation types with walls, the the slab's position relative to grade is determined by the ``FoundationWall/DepthBelowGrade`` value.

HPXML Windows
*************

Each window or glass door area is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Windows/Window``.

  ============================================  ========  ============  ===========  ========  =========  ==============================================
  Element                                       Type      Units         Constraints  Required  Default    Notes
  ============================================  ========  ============  ===========  ========  =========  ==============================================
  ``SystemIdentifier``                          id                                   Yes                  Unique identifier
  ``Area``                                      double    ft2           > 0          Yes                  Total area
  ``Azimuth``                                   integer   deg           0-359        Yes                  Azimuth (clockwise from North)
  ``UFactor``                                   double    Btu/F-ft2-hr  > 0          Yes                  Full-assembly NFRC U-factor
  ``SHGC``                                      double                  0-1          Yes                  Full-assembly NFRC solar heat gain coefficient
  ``Overhangs``                                 element                 0-1          No        <none>     Presence of overhangs (including roof eaves)
  ``FractionOperable``                          double    frac          0-1          Yes                  Operable fraction [#]_
  ``AttachedToWall``                            idref                   See [#]_     Yes                  ID of attached wall
  ============================================  ========  ============  ===========  ========  =========  ==============================================

  .. [#] FractionOperable reflects whether the windows are operable (can be opened), not how they are used by the occupants.
         If a ``Window`` represents a single window, the value should be 0 or 1.
         If a ``Window`` represents multiple windows (e.g., 4), the value should be between 0 and 1 (e.g., 0, 0.25, 0.5, 0.75, or 1).
  .. [#] AttachedToWall must reference a ``Wall`` or ``FoundationWall``.

If overhangs are specified, additional information is entered in ``Overhangs``.

  ============================  ========  ======  ===========  ========  =======  ========================================================
  Element                       Type      Units   Constraints  Required  Default  Notes
  ============================  ========  ======  ===========  ========  =======  ========================================================
  ``Depth``                     double    inches  > 0          Yes                Depth of overhang
  ``DistanceToTopOfWindow``     double    ft      >= 0         Yes                Vertical distance from overhang to top of window
  ``DistanceToBottomOfWindow``  double    ft      >= 0         Yes                Vertical distance from overhang to bottom of window [#]_
  ============================  ========  ======  ===========  ========  =======  ========================================================

  .. [#] The difference between DistanceToBottomOfWindow and DistanceToTopOfWindow defines the height of the window.

HPXML Skylights
***************

Each skylight is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight``.

  ============================================  ========  ============  ===========  ========  =========  ==============================================
  Element                                       Type      Units         Constraints  Required  Default    Notes
  ============================================  ========  ============  ===========  ========  =========  ==============================================
  ``SystemIdentifier``                          id                                   Yes                  Unique identifier
  ``Area``                                      double    ft2           > 0          Yes                  Total area
  ``Azimuth``                                   integer   deg           0-359        Yes                  Azimuth (clockwise from North)
  ``UFactor``                                   double    Btu/F-ft2-hr  > 0          Yes                  Full-assembly NFRC U-factor
  ``SHGC``                                      double                  0-1          Yes                  Full-assembly NFRC solar heat gain coefficient
  ``AttachedToRoof``                            idref                   See [#]_     Yes                  ID of attached roof
  ============================================  ========  ============  ===========  ========  =========  ==============================================

  .. [#] AttachedToRoof must reference a ``Roof``.

HPXML Doors
***********

Each opaque door is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Doors/Door``.

  ============================================  ========  ============  ===========  ========  =========  ==============================
  Element                                       Type      Units         Constraints  Required  Default    Notes
  ============================================  ========  ============  ===========  ========  =========  ==============================
  ``SystemIdentifier``                          id                                   Yes                  Unique identifier
  ``AttachedToWall``                            idref                   See [#]_     Yes                  ID of attached wall
  ``Area``                                      double    ft2           > 0          Yes                  Total area
  ``Azimuth``                                   integer   deg           0-359        Yes                  Azimuth (clockwise from North)
  ``RValue``                                    double    F-ft2-hr/Btu  > 0          Yes                  R-value
  ============================================  ========  ============  ===========  ========  =========  ==============================

  .. [#] AttachedToWall must reference a ``Wall`` or ``FoundationWall``.

HPXML Systems
-------------

The dwelling unit's systems are entered in ``/HPXML/Building/BuildingDetails/Systems``.

.. _hvac_heating:

HPXML Heating Systems
*********************

Each heating system (other than heat pumps) is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem``.

  =================================  ========  ======  ===========  ========  =========  ===============================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ===============================
  ``SystemIdentifier``               id                             Yes                  Unique identifier
  ``HeatingSystemType``              element           1 [#]_       Yes                  Type of heating system
  ``FractionHeatLoadServed``         double    frac    0-1 [#]_     Yes                  Fraction of heating load served
  ``HeatingSystemFuel``              string            See [#]_     Yes                  Fuel type
  ``HeatingCapacity``                double    Btu/hr  >= 0         See [#]_             Input heating capacity
  =================================  ========  ======  ===========  ========  =========  ===============================

  .. [#] HeatingSystemType child element choices are ``ElectricResistance``, ``Furnace``, ``WallFurnace``, ``FloorFurnace``, ``Boiler``, ``Stove``, ``PortableHeater``, ``FixedHeater``, or ``Fireplace``.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
         For example, the dwelling unit could have a boiler heating system and a heat pump with values of 0.4 (40%) and 0.6 (60%), respectively.
  .. [#] HeatingSystemFuel choices are  "natural gas", "fuel oil", "propane", "electricity", "wood", or "wood pellets".
         For ``ElectricResistance``, "electricity" is required.
  .. [#] HeatingCapacity required for all systems other than shared boilers.

Electric Resistance
~~~~~~~~~~~~~~~~~~~

If electric resistance heating is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =======  ==========
  Element                                             Type    Units  Constraints  Required  Default  Notes
  ==================================================  ======  =====  ===========  ========  =======  ==========
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0-1          Yes                Efficiency
  ==================================================  ======  =====  ===========  ========  =======  ==========

Furnace
~~~~~~~

If a furnace is specified, additional information is entered in ``HeatingSystem``.

  ===============================================  ======  =====  ===========  ========  =========  ==================================
  Element                                          Type    Units  Constraints  Required  Default    Notes
  ===============================================  ======  =====  ===========  ========  =========  ==================================
  ``DistributionSystem``                           idref          See [#]_     Yes                  ID of attached distribution system
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``  double  frac   0-1          Yes                  Rated efficiency
  ``extension/FanPowerWattsPerCFM``                double  W/cfm  >= 0         No        See [#]_   Installed fan efficiency
  ===============================================  ======  =====  ===========  ========  =========  ==================================

  .. [#] HVACDistribution type must be AirDistribution or DSE.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.5 W/cfm if AFUE <= 0.9, else 0.375 W/cfm.

Wall/Floor Furnace
~~~~~~~~~~~~~~~~~~

If a wall furnace or floor furnace is specified, additional information is entered in ``HeatingSystem``.

  ===============================================  ======  =====  ===========  ========  =======  ===================
  Element                                          Type    Units  Constraints  Required  Default  Notes
  ===============================================  ======  =====  ===========  ========  =======  ===================
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``  double  frac   0-1          Yes                Rated efficiency
  ``extension/FanPowerWatts``                      double  W      >= 0         No        0        Installed fan power
  ===============================================  ======  =====  ===========  ========  =======  ===================

Boiler
~~~~~~

If a boiler is specified, additional information is entered in ``HeatingSystem``.

  ==========================================================================  ========  ======  ===========  ========  ========  =========================================
  Element                                                                     Type      Units   Constraints  Required  Default   Notes
  ==========================================================================  ========  ======  ===========  ========  ========  =========================================
  ``IsSharedSystem``                                                          boolean                        Yes                 Whether it serves multiple dwelling units
  ``DistributionSystem``                                                      idref             See [#]_     Yes                 ID of attached distribution system
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``                             double    frac    0-1          Yes                 Rated efficiency
  ``ElectricAuxiliaryEnergy``                                                 double    kWh/yr  >= 0         No [#]_   See [#]_  Electric auxiliary energy
  ``extension/WaterLoopHeatPump/AnnualHeatingEfficiency[Units="COP"]/Value``  double    W/W     > 0          See [#]_            COP of the attached water loop heat pump
  ==========================================================================  ========  ======  ===========  ========  ========  =========================================

  .. [#] HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", or "radiant ceiling") or DSE for in-unit boilers, and HydronicDistribution (type: "radiator", "baseboard", "radiant floor", or "radiant ceiling") or HydronicAndAirDistribution (type: "fan coil" or "water loop heat pump") for shared boilers.
  .. [#] | For shared boilers, ElectricAuxiliaryEnergy can alternatively be calculated as:
         | EAE = (SP / N_dweq + aux_in) * HLH
         | where
         | SP = Shared pump power [W] provided as ``extension/SharedLoopWatts``,
         | N_dweq = Number of units served by the shared system provided as ``NumberofUnitsServed``,
         | aux_in = In-unit fan coil power [W] provided as ``extension/FanCoilWatts``,
         | HLH = Annual heating load hours.
  .. [#] If ElectricAuxiliaryEnergy not provided (nor calculated for shared boilers), defaults as follows:

         - **Oil boiler**: 330
         - **Gas boiler (in-unit)**: 170
         - **Gas boiler (shared, w/ baseboard)**: 220
         - **Gas boiler (shared, w/ water loop heat pump)**: 265
         - **Gas boiler (shared, w/ fan coil)**: 438

  .. [#] Water loop heat pump (WLHP) heating COP only required if a shared boiler connected to a water loop heat pump.

Stove
~~~~~

If a stove is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0-1          Yes                  Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        40         Installed fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

Portable/Fixed Heater
~~~~~~~~~~~~~~~~~~~~~

If a portable heater or fixed heater is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0-1          Yes                  Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        0          Installed fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

Fireplace
~~~~~~~~~

If a fireplace is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0-1          Yes                  Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        0          Installed fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

.. _hvac_cooling:

HPXML Cooling Systems
*********************

Each cooling system (other than heat pumps) is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem``.

  ==========================  ========  ======  ===========  ========  =======  ===============================
  Element                     Type      Units   Constraints  Required  Default  Notes
  ==========================  ========  ======  ===========  ========  =======  ===============================
  ``SystemIdentifier``        id                             Yes                Unique identifier
  ``CoolingSystemType``       string            See [#]_     Yes                Type of cooling system
  ``CoolingSystemFuel``       string            See [#]_     Yes                Fuel type
  ``FractionCoolLoadServed``  double    frac    0-1 [#]_     Yes                Fraction of cooling load served
  ==========================  ========  ======  ===========  ========  =======  ===============================

  .. [#] CoolingSystemType choices are "central air conditioner", "room air conditioner", "evaporative cooler", "chiller", or "cooling tower".
  .. [#] CoolingSystemFuel only choice is "electricity".
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.
         For example, the dwelling unit could have two room air conditioners with values of 0.1 (10%) and 0.2 (20%), respectively, with the rest of the home (70%) uncooled.

Central Air Conditioner
~~~~~~~~~~~~~~~~~~~~~~~

If a central air conditioner is specified, additional information is entered in ``CoolingSystem``.

  ===============================================  ========  ======  ===========  ========  =========  ==================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  ==================================
  ``DistributionSystem``                           idref             See [#]_     Yes                  ID of attached distribution system
  ``AnnualCoolingEfficiency[Units="SEER"]/Value``  double    Btu/Wh  > 0          Yes                  Rated efficiency
  ``CoolingCapacity``                              double    Btu/hr  >= 0         Yes                  Cooling capacity
  ``SensibleHeatFraction``                         double    frac    0-1          No                   Sensible heat fraction
  ``CompressorType``                               string            See [#]_     No        See [#]_   Type of compressor
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_   Installed fan efficiency
  ===============================================  ========  ======  ===========  ========  =========  ==================================

  .. [#] HVACDistribution type must be AirDistribution or DSE.
  .. [#] CompressorType choices are "single stage", "two stage", or "variable speed".
  .. [#] If CompressorType not provided, defaults to "single stage" if SEER <= 15, else "two stage" if SEER <= 21, else "variable speed".
  .. [#] If FanPowerWattsPerCFM not provided, defaults to using attached furnace W/cfm if available, else 0.5 W/cfm if SEER <= 13.5, else 0.375 W/cfm.

Room Air Conditioner
~~~~~~~~~~~~~~~~~~~~

If a room air conditioner is specified, additional information is entered in ``CoolingSystem``.

  ==============================================  ========  ======  ===========  ========  =========  ======================
  Element                                         Type      Units   Constraints  Required  Default    Notes
  ==============================================  ========  ======  ===========  ========  =========  ======================
  ``AnnualCoolingEfficiency[Units="EER"]/Value``  double    Btu/Wh  > 0          Yes                  Rated efficiency
  ``CoolingCapacity``                             double    Btu/hr  >= 0         Yes                  Cooling capacity
  ``SensibleHeatFraction``                        double    frac    0-1          No                   Sensible heat fraction
  ==============================================  ========  ======  ===========  ========  =========  ======================

Evaporative Cooler
~~~~~~~~~~~~~~~~~~

If an evaporative cooler is specified, additional information is entered in ``CoolingSystem``.

  =================================  ========  ======  ===========  ========  =========  ==================================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ==================================
  ``DistributionSystem``             idref             See [#]_     No                   ID of attached distribution system
  ``extension/FanPowerWattsPerCFM``  double    W/cfm   >= 0         No        See [#]_   Installed fan efficiency
  =================================  ========  ======  ===========  ========  =========  ==================================

  .. [#] HVACDistribution type must be AirDistribution or DSE.
  .. [#] If FanPowerWattsPerCFM not provided, defaults to MIN(2.79 * cfm^-0.29, 0.6) W/cfm.

Chiller
~~~~~~~

If a chiller is specified, additional information is entered in ``CoolingSystem``.

  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  Element                                                                     Type      Units   Constraints  Required  Default    Notes
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  ``IsSharedSystem``                                                          boolean           true         Yes                  Whether it serves multiple dwelling units
  ``DistributionSystem``                                                      idref             See [#]_     Yes                  ID of attached distribution system
  ``NumberofUnitsServed``                                                     integer           > 1          Yes                  Number of dwelling units served
  ``CoolingCapacity``                                                         double    Btu/hr  >= 0         Yes                  Total cooling capacity
  ``AnnualCoolingEfficiency[Units="kW/ton"]/Value``                           double    kW/ton  > 0          Yes                  Rated efficiency
  ``extension/SharedLoopWatts``                                               double    W       >= 0         Yes                  Pumping and fan power serving the system
  ``extension/FanCoilWatts``                                                  double    W       >= 0         See [#]_             Fan coil power
  ``extension/WaterLoopHeatPump/CoolingCapacity``                             double    Btu/hr  > 0          See [#]_             Water loop heat pump cooling capacity
  ``extension/WaterLoopHeatPump/AnnualCoolingEfficiency[Units="EER"]/Value``  double    Btu/Wh  > 0          See [#]_             Water loop heat pump efficiency
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================

  .. [#] HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", or "radiant ceiling") or HydronicAndAirDistribution (type: "fan coil" or "water loop heat pump").
  .. [#] FanCoilWatts only required if chiller connected to a fan coil.
  .. [#] WLHP CoolingCapacity only required if chiller connected to a water loop heat pump.
  .. [#] WLHP Cooling EER only required if chiller connected to a water loop heat pump.
  
Cooling Tower w/ WLHP
~~~~~~~~~~~~~~~~~~~~~

If a cooling tower w/ water loop heat pump (WLHP) is specified, additional information is entered in ``CoolingSystem``.

  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  Element                                                                     Type      Units   Constraints  Required  Default    Notes
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  ``IsSharedSystem``                                                          boolean           true         Yes                  Whether it serves multiple dwelling units
  ``DistributionSystem``                                                      idref             See [#]_     Yes                  ID of attached distribution system
  ``NumberofUnitsServed``                                                     integer           > 1          Yes                  Number of dwelling units served
  ``extension/SharedLoopWatts``                                               double    W       >= 0         Yes                  Pumping and fan power serving the system
  ``extension/WaterLoopHeatPump/CoolingCapacity``                             double    Btu/hr  > 0          Yes                  Water loop heat pump cooling capacity
  ``extension/WaterLoopHeatPump/AnnualCoolingEfficiency[Units="EER"]/Value``  double    Btu/Wh  > 0          Yes                  Water loop heat pump efficiency
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================

  .. [#] HVACDistribution type must be HydronicAndAirDistribution (type: "water loop heat pump").
  
.. _hvac_heatpump:

HPXML Heat Pumps
****************

Each heat pump is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump``.

  =================================  ========  ======  ===========  ========  =========  ===============================================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ===============================================
  ``SystemIdentifier``               id                             Yes                  Unique identifier
  ``HeatPumpType``                   string            See [#]_     Yes                  Type of heat pump
  ``HeatPumpFuel``                   string            See [#]_     Yes                  Fuel type
  ``HeatingCapacity``                double    Btu/hr  >= 0         Yes                  Heating capacity (excluding any backup heating)
  ``CoolingCapacity``                double    Btu/hr  >= 0         Yes                  Cooling capacity
  ``CoolingSensibleHeatFraction``    double    frac    0-1          No                   Sensible heat fraction
  ``BackupSystemFuel``               string            See [#]_     No                   Fuel type of backup heating, if present
  ``FractionHeatLoadServed``         double    frac    0-1 [#]_     Yes                  Fraction of heating load served
  ``FractionCoolLoadServed``         double    frac    0-1 [#]_     Yes                  Fraction of cooling load served
  =================================  ========  ======  ===========  ========  =========  ===============================================

  .. [#] HeatPumpType choices are "air-to-air", "mini-split", or "ground-to-air".
  .. [#] HeatPumpFuel only choice is "electricity".
  .. [#] BackupSystemFuel choices are "electricity", "natural gas", "fuel oil", "propane", "wood", or "wood pellets".
  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
         For example, the dwelling unit could have a heat pump and a boiler heating system with values of 0.4 (40%) and 0.6 (60%), respectively.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.
         For example, the dwelling unit could have two mini-split heat pumps with values of 0.1 (10%) and 0.2 (20%), respectively, with the rest of the home (70%) uncooled.

If a backup system fuel is provided, additional information is entered in ``HeatPump``.

  ========================================================================  ========  ======  ===========  ========  =========  ==========================================
  Element                                                                   Type      Units   Constraints  Required  Default    Notes
  ========================================================================  ========  ======  ===========  ========  =========  ==========================================
  ``BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value``  double    frac    0-1          Yes                  Backup heating efficiency
  ``BackupHeatingCapacity``                                                 double    Btu/hr  >= 0         Yes                  Backup heating capacity
  ``BackupHeatingSwitchoverTemperature``                                    double    F                    No        <none>     Backup heating switchover temperature [#]_
  ========================================================================  ========  ======  ===========  ========  =========  ==========================================

  .. [#] Provide BackupHeatingSwitchoverTemperature for, e.g., a dual-fuel heat pump, in which there is a discrete outdoor temperature when the heat pump stops operating and the backup heating system starts operating.
         If not provided, the backup heating system will operate as needed when the heat pump has insufficient capacity.

.. note::
  
  Water loop heat pumps in multifamily buildings should not be entered as a HeatPump.
  Rather, enter them as a :ref:`hvac_heating` (shared boiler) and/or :ref:`hvac_cooling` (shared chiller or cooling tower).

Air-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~

If an air-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  =========  =====================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  =====================================
  ``DistributionSystem``                           idref             See [#]_     Yes                  ID of attached distribution system
  ``CompressorType``                               string            See [#]_     No        See [#]_   Type of compressor
  ``AnnualCoolingEfficiency[Units="SEER"]/Value``  double    Btu/Wh  > 0          Yes                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="HSPF"]/Value``  double    Btu/Wh  > 0          Yes                  Rated heating efficiency
  ``HeatingCapacity17F``                           double    Btu/hr  >= 0         No                   Heating capacity at 17F, if available
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_   Installed fan efficiency
  ===============================================  ========  ======  ===========  ========  =========  =====================================

  .. [#] HVACDistribution type must be AirDistribution or DSE.
  .. [#] CompressorType choices are "single stage", "two stage", or "variable speed".
  .. [#] If CompressorType not provided, defaults to "single stage" if SEER <= 15, else "two stage" if SEER <= 21, else "variable speed".
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.5 W/cfm if HSPF <= 8.75, else 0.375 W/cfm.

Mini-Split Heat Pump
~~~~~~~~~~~~~~~~~~~~

If a mini-split heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  ``DistributionSystem``                           idref             See [#]_     No                   ID of attached distribution system, if present
  ``AnnualCoolingEfficiency[Units="SEER"]/Value``  double    Btu/Wh  > 0          Yes                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="HSPF"]/Value``  double    Btu/Wh  > 0          Yes                  Rated heating efficiency
  ``HeatingCapacity17F``                           double    Btu/hr  >= 0         No                   Heating capacity at 17F, if available
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_   Installed fan efficiency
  ===============================================  ========  ======  ===========  ========  =========  ==============================================

  .. [#] HVACDistribution type must be AirDistribution or DSE.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.07 W/cfm if ductless, else 0.18 W/cfm.

Ground-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~

If a ground-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  ``IsSharedSystem``                               boolean                        Yes                  Whether it serves multiple dwelling units [#]_
  ``DistributionSystem``                           idref             See [#]_     Yes                  ID of attached distribution system
  ``AnnualCoolingEfficiency[Units="EER"]/Value``   double    Btu/Wh  > 0          Yes                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``   double    W/W     > 0          Yes                  Rated heating efficiency
  ``extension/PumpPowerWattsPerTon``               double    W/ton   >= 0         Yes                  Installed pump efficiency
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_   Installed fan efficiency
  ``NumberofUnitsServed``                          integer           > 1          See [#]_             Number of dwelling units served
  ``extension/SharedLoopWatts``                    double    W       >= 0         See [#]_             Shared pump power [#]_
  ===============================================  ========  ======  ===========  ========  =========  ==============================================

  .. [#] IsSharedSystem should be true if the SFA/MF building has multiple ground source heat pumps connected to a shared hydronic circulation loop.
  .. [#] HVACDistribution type must be AirDistribution or DSE.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.5 W/cfm if COP <= 8.75/3.2, else 0.375 W/cfm.
  .. [#] NumberofUnitsServed only required if IsSharedSystem is true.
  .. [#] SharedLoopWatts only required if IsSharedSystem is true.
  .. [#] Shared loop pump power attributed to the dwelling unit is calculated as SharedLoopWatts / NumberofUnitsServed.

HPXML HVAC Control
******************

If any HVAC systems are specified, a single thermostat is entered as a ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl``.

  ====================  ========  =======  ===========  ========  =========  ========================================
  Element               Type      Units    Constraints  Required  Default    Notes
  ====================  ========  =======  ===========  ========  =========  ========================================
  ``SystemIdentifier``  id                              Yes                  Unique identifier
  ``ControlType``       string             See [#]_     Yes                  Type of thermostat
  ====================  ========  =======  ===========  ========  =========  ========================================

  .. [#] ControlType choices are "manual thermostat" or "programmable thermostat".

HPXML HVAC Distribution
***********************

Each separate HVAC distribution system is entered as a ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution``.

  ==============================  =======  =======  ===========  ========  =========  =============================
  Element                         Type     Units    Constraints  Required  Default    Notes
  ==============================  =======  =======  ===========  ========  =========  =============================
  ``SystemIdentifier``            id                             Yes                  Unique identifier
  ``DistributionSystemType``      element           1 [#]_       Yes                  Type of distribution system
  ``ConditionedFloorAreaServed``  double   ft2      > 0          See [#]_             Conditioned floor area served
  ==============================  =======  =======  ===========  ========  =========  =============================

  .. [#] DistributionSystemType child element choices are ``AirDistribution``, ``HydronicDistribution``, ``HydronicAndAirDistribution``, or ``Other=DSE``.
  .. [#] ConditionedFloorAreaServed is required for AirDistribution and HydronicAndAir types.

.. note::
  
  There should be at most one heating system and one cooling system attached to a distribution system.
  See :ref:`hvac_heating`, :ref:`hvac_cooling`, and :ref:`hvac_heatpump` for information on which DistributionSystemType is allowed for which HVAC system.
  Also note that some HVAC systems (e.g., room air conditioners) are not allowed to be attached to a distribution system.

.. _air_distribution:

Air Distribution
~~~~~~~~~~~~~~~~

To define an air distribution system, the presence of duct leakage can be entered in one of three ways:

1. **Leakage to the Outside**

  Supply and/or return leakage to the outside are entered as a ``HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement``:
  
  ================================  =======  =======  ===========  ========  =========  =========================================================
  Element                           Type     Units    Constraints  Required  Default    Notes
  ================================  =======  =======  ===========  ========  =========  =========================================================
  ``DuctType``                      string            See [#]_     Yes                  Supply or return ducts
  ``DuctLeakage/Units``             string            CFM25        Yes                  Duct leakage units
  ``DuctLeakage/Value``             double            >= 0         Yes                  Duct leakage value
  ``DuctLeakage/TotalOrToOutside``  string            to outside   Yes                  Type of duct leakage (outside conditioned space vs total)
  ================================  =======  =======  ===========  ========  =========  =========================================================
  
  .. [#] DuctType choices are "supply" or "return".

2. **Total leakage** (Version 2014ADEGL or newer)

  Total leakage is entered as a ``HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement``:

  ================================  =======  =======  ===========  ========  =========  =========================================================
  Element                           Type     Units    Constraints  Required  Default    Notes
  ================================  =======  =======  ===========  ========  =========  =========================================================
  ``DuctLeakage/Units``             string            CFM25        Yes                  Duct leakage units
  ``DuctLeakage/Value``             double            >= 0         Yes                  Duct leakage value
  ``DuctLeakage/TotalOrToOutside``  string            total        Yes                  Type of duct leakage (outside conditioned space vs total)
  ================================  =======  =======  ===========  ========  =========  =========================================================
  
  .. warning::
  
    Total leakage should only be used if the conditions specified in ANSI/RESNET/ICC 301 have been appropriately met.

3. **Leakage Testing Exemption** (Version 2014AD or newer)

   A duct leakage testing exemption is entered in ``HVACDistribution/DistributionSystemType/AirDistribution``:
   
  =======================================================  =======  =======  ===========  ========  =========  =============================
  Element                                                  Type     Units    Constraints  Required  Default    Notes
  =======================================================  =======  =======  ===========  ========  =========  =============================
  ``extension/DuctLeakageToOutsideTestingExemption=true``  boolean           true         Yes                  Leakage to outside exemption?
  =======================================================  =======  =======  ===========  ========  =========  =============================

  .. warning::

    Leakage testing exemption should only be used if the conditions specified in ANSI/RESNET/ICC 301 have been appropriately met.
    OpenStudio-ERI does not assess the validity of the duct test exemption claim.

Additionally, each supply/return duct present is entered in a ``HVACDistribution/DistributionSystemType/AirDistribution/Ducts``.

  ========================  =======  ============  ===========  ========  =========  ===============================
  Element                   Type     Units         Constraints  Required  Default    Notes
  ========================  =======  ============  ===========  ========  =========  ===============================
  ``DuctInsulationRValue``  double   F-ft2-hr/Btu  >= 0         Yes                  R-value of duct insulation [#]_
  ``DuctSurfaceArea``       double   ft2           >= 0         Yes                  Duct surface area
  ``DuctLocation``          string                 See [#]_     Yes                  Duct location
  ========================  =======  ============  ===========  ========  =========  ===============================

  .. [#] DuctInsulationRValue should not include air films (i.e., use 0 for an uninsulated duct).
  .. [#] DuctLocation choices are "living space", "basement - conditioned", "basement - unconditioned", "crawlspace - unvented", "crawlspace - vented", "attic - unvented", "attic - vented", "garage", "outside", "exterior wall", "under slab", "roof deck", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.

Hydronic Distribution
~~~~~~~~~~~~~~~~~~~~~

To define a hydronic distribution system, additional information is entered in ``HVACDistribution/DistributionSystemType/HydronicDistribution``.

  ============================  =======  =======  ===========  ========  =========  ====================================
  Element                       Type     Units    Constraints  Required  Default    Notes
  ============================  =======  =======  ===========  ========  =========  ====================================
  ``HydronicDistributionType``  string            See [#]_     Yes                  Type of hydronic distribution system
  ============================  =======  =======  ===========  ========  =========  ====================================

  .. [#] HydronicDistributionType choices are "radiator", "baseboard", "radiant floor", or "radiant ceiling".

Hydronic And Air Distribution
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To define an air and hydronic distribution system, additional information is entered in ``HVACDistribution/DistributionSystemType/HydronicAndAirDistribution``.

  ==================================  =======  =======  ===========  ========  =========  ============================================
  Element                             Type     Units    Constraints  Required  Default    Notes
  ==================================  =======  =======  ===========  ========  =========  ============================================
  ``HydronicAndAirDistributionType``  string            See [#]_     Yes                  Type of hydronic and air distribution system
  ==================================  =======  =======  ===========  ========  =========  ============================================

  .. [#] HydronicAndAirDistributionType choices are "fan coil" or "water loop heat pump".

In addition, if the system is ducted, all of the elements from the :ref:`air_distribution` Section can be entered in this ``HydronicAndAirDistribution`` element too (e.g., ``DuctLeakageMeasurement`` and ``Ducts``).

Distribution System Efficiency (DSE)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. warning::

  A simplified DSE model is provided for flexibility, but it is **strongly** recommended to use one of the other detailed distribution system types for better accuracy.

To define a DSE system, additional information is entered in ``HVACDistribution``.

  =============================================  =======  =======  ===========  ========  =========  ===================================================
  Element                                        Type     Units    Constraints  Required  Default    Notes
  =============================================  =======  =======  ===========  ========  =========  ===================================================
  ``AnnualHeatingDistributionSystemEfficiency``  double   frac     0-1          Yes                  Seasonal distribution system efficiency for heating
  ``AnnualCoolingDistributionSystemEfficiency``  double   frac     0-1          Yes                  Seasonal distribution system efficiency for cooling
  =============================================  =======  =======  ===========  ========  =========  ===================================================

  DSE values can be calculated from `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_.

HPXML Ventilation Fan
*********************

Each mechanical ventilation systems that provide ventilation to the whole dwelling unit is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan``.

  ====================================================  =================  =======  ============  ========  =========  =========================================
  Element                                               Type               Units    Constraints   Required  Default    Notes
  ====================================================  =================  =======  ============  ========  =========  =========================================
  ``SystemIdentifier``                                  id                                        Yes                  Unique identifier
  ``UsedForWholeBuildingVentilation``                   boolean                     true          Yes                  Must be set to true
  ``IsSharedSystem``                                    boolean                     See [#]_      Yes                  Whether it serves multiple dwelling units
  ``FanType``                                           string                      See [#]_      Yes                  Type of ventilation system
  ``TestedFlowRate`` or ``RatedFlowRate``               double             cfm      >= 0          Yes                  Flow rate [#]_
  ``HoursInOperation``                                  double             hrs/day  0-24          Yes                  Hours per day of operation
  ``FanPower`` or ``extension/FanPowerDefaulted=true``  double or boolean  W        >= 0 or true  See [#]_             Fan power or whether fan power is unknown
  ====================================================  =================  =======  ============  ========  =========  =========================================

  .. [#] For central fan integrated supply systems, IsSharedSystem must be false.
  .. [#] FanType choices are "energy recovery ventilator", "heat recovery ventilator", "exhaust only", "supply only", "balanced", or "central fan integrated supply".
  .. [#] For a central fan integrated supply system, the flow rate should equal the amount of outdoor air provided to the distribution system.
  .. [#] FanPower or FanPowerDefaulted=true required if IsSharedSystem is false.

Exhaust/Supply Only
~~~~~~~~~~~~~~~~~~~

If a supply only or exhaust only system is specified, no additional information is entered.

Balanced
~~~~~~~~

If a balanced system is specified, no additional information is entered.

Heat Recovery Ventilator
~~~~~~~~~~~~~~~~~~~~~~~~

If a heat recovery ventilator system is specified, additional information is entered in ``VentilationFan``.

  ========================================================================  ======  =====  ===========  ========  =======  ============================
  Element                                                                   Type    Units  Constraints  Required  Default  Notes
  ========================================================================  ======  =====  ===========  ========  =======  ============================
  ``SensibleRecoveryEfficiency`` or ``AdjustedSensibleRecoveryEfficiency``  double  frac   0-1          Yes                Sensible recovery efficiency
  ========================================================================  ======  =====  ===========  ========  =======  ============================

Energy Recovery Ventilator
~~~~~~~~~~~~~~~~~~~~~~~~~~

If an energy recovery ventilator system is specified, additional information is entered in ``VentilationFan``.

  ========================================================================  ======  =====  ===========  ========  =======  ============================
  Element                                                                   Type    Units  Constraints  Required  Default  Notes
  ========================================================================  ======  =====  ===========  ========  =======  ============================
  ``TotalRecoveryEfficiency`` or ``AdjustedTotalRecoveryEfficiency``        double  frac   0-1          Yes                Total recovery efficiency
  ``SensibleRecoveryEfficiency`` or ``AdjustedSensibleRecoveryEfficiency``  double  frac   0-1          Yes                Sensible recovery efficiency
  ========================================================================  ======  =====  ===========  ========  =======  ============================

Central Fan Integrated Supply
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a central fan integrated supply system is specified, additional information is entered in ``VentilationFan``.

  ====================================  ======  =====  ===========  ========  =======  ==================================
  Element                               Type    Units  Constraints  Required  Default  Notes
  ====================================  ======  =====  ===========  ========  =======  ==================================
  ``AttachedToHVACDistributionSystem``  idref          See [#]_     Yes                ID of attached distribution system
  ====================================  ======  =====  ===========  ========  =======  ==================================

  .. [#] HVACDistribution type cannot be HydronicDistribution.

Shared System
~~~~~~~~~~~~~

If the specified system is a shared system (i.e., serving multiple dwelling units), additional information is entered in ``VentilationFan``.

  ====================================================================  =================  =====  ============  ========  =======  ==========================================================================
  Element                                                               Type               Units  Constraints   Required  Default  Notes
  ====================================================================  =================  =====  ============  ========  =======  ==========================================================================
  ``RatedFlowRate``                                                     double             cfm    >= 0          Yes                Total flow rate of shared system
  ``FractionRecirculation``                                             double             frac   0-1           Yes                Fraction of supply air that is recirculated [#]_
  ``extension/InUnitFlowRate`` or ``extension/FlowRateNotTested=true``  double or boolean  cfm    >= 0 or true  Yes                Flow rate delivered to the dwelling unit or whether flow rate not measured
  ``extension/PreHeating``                                              element                   0-1           No        <none>   Supply air preconditioned by heating equipment? [#]_
  ``extension/PreCooling``                                              element                   0-1           No        <none>   Supply air preconditioned by cooling equipment? [#]_
  ====================================================================  =================  =====  ============  ========  =======  ==========================================================================

  .. [#] 1-FractionRecirculation is assumed to be the fraction of supply air that is provided from outside.
         The value must be 0 for exhaust only systems.
  .. [#] PreHeating not allowed for exhaust only systems.
  .. [#] PreCooling not allowed for exhaust only systems.

If pre-heating is specified, additional information is entered in ``extension/PreHeating``.

  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  Element                                         Type     Units  Constraints  Required  Default  Notes
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  ``Fuel``                                        string          See [#]_     Yes                Pre-heating equipment fuel type
  ``AnnualHeatingEfficiency[Units="COP"]/Value``  double   W/W    > 0          Yes                Pre-heating equipment annual COP
  ``FractionVentilationHeatLoadServed``           double   frac   0-1          Yes                Fraction of ventilation heating load served by pre-heating equipment
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================

  .. [#] Fuel choices are "natural gas", "fuel oil", "propane", "electricity", "wood", or "wood pellets".

If pre-cooling is specified, additional information is entered in ``extension/PreCooling``.

  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  Element                                         Type     Units  Constraints  Required  Default  Notes
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  ``Fuel``                                        string          See [#]_     Yes                Pre-cooling equipment fuel type
  ``AnnualCoolingEfficiency[Units="COP"]/Value``  double   W/W    > 0          Yes                Pre-cooling equipment annual COP
  ``FractionVentilationCoolLoadServed``           double   frac   0-1          Yes                Fraction of ventilation cooling load served by pre-cooling equipment
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================

  .. [#] Fuel only choice is "electricity".

HPXML Whole House Fan
*********************

Each whole house fans that provides cooling load reduction is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan``.

  =======================================  =======  =======  ===========  ========  ========  ==========================
  Element                                  Type     Units    Constraints  Required  Default   Notes
  =======================================  =======  =======  ===========  ========  ========  ==========================
  ``SystemIdentifier``                     id                             Yes                 Unique identifier
  ``UsedForSeasonalCoolingLoadReduction``  boolean           true         Yes                 Must be set to true
  ``RatedFlowRate``                        double   cfm      >= 0         Yes                 Flow rate
  ``FanPower``                             double   W        >= 0         Yes                 Fan power
  =======================================  =======  =======  ===========  ========  ========  ==========================

.. note::

  The whole house fan is assumed to operate during hours of favorable outdoor conditions and will take priority over operable windows (natural ventilation).

HPXML Water Heating Systems
***************************

Each water heater is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem``.

  =========================  =======  =======  ===========  ========  ========  ================================================================
  Element                    Type     Units    Constraints  Required  Default   Notes
  =========================  =======  =======  ===========  ========  ========  ================================================================
  ``SystemIdentifier``       id                             Yes                 Unique identifier
  ``IsSharedSystem``         boolean                        Yes                 Whether it serves multiple dwelling units or shared laundry room
  ``WaterHeaterType``        string            See [#]_     Yes                 Type of water heater
  ``Location``               string            See [#]_     Yes                 Water heater location
  ``FractionDHWLoadServed``  double   frac     0-1 [#]_     Yes                 Fraction of hot water load served [#]_
  ``UsesDesuperheater``      boolean                        No        false     Presence of desuperheater?
  ``NumberofUnitsServed``    integer           > 1          See [#]_            Number of dwelling units served directly or indirectly
  =========================  =======  =======  ===========  ========  ========  ================================================================

  .. [#] WaterHeaterType choices are "storage water heater", "instantaneous water heater", "heat pump water heater", "space-heating boiler with storage tank", or "space-heating boiler with tankless coil".
  .. [#] Location choices are "living space", "basement - unconditioned", "basement - conditioned", "attic - unvented", "attic - vented", "garage", "crawlspace - unvented", "crawlspace - vented", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] The sum of all ``FractionDHWLoadServed`` (across all WaterHeatingSystems) must equal to 1.
  .. [#] FractionDHWLoadServed represents only the fraction of the hot water load associated with the hot water **fixtures**.
         Additional hot water load from clothes washers/dishwashers will be automatically assigned to the appropriate water heater(s).
  .. [#] NumberofUnitsServed only required if IsSharedSystem is true.

Conventional Storage
~~~~~~~~~~~~~~~~~~~~

If a conventional storage water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  =============================================  =======  ============  ===========  ========  ========  ==========================================
  Element                                        Type     Units         Constraints  Required  Default   Notes
  =============================================  =======  ============  ===========  ========  ========  ==========================================
  ``FuelType``                                   string                 See [#]_     Yes                 Fuel type
  ``TankVolume``                                 double   gal           > 0          Yes                 Tank volume
  ``HeatingCapacity``                            double   Btuh          > 0          No        See [#]_  Heating capacity
  ``UniformEnergyFactor`` or ``EnergyFactor``    double   frac          0-1          Yes                 EnergyGuide label rated efficiency
  ``FirstHourRating``                            double   gal/hr        > 0          See [#]_            EnergyGuide label first hour rating
  ``RecoveryEfficiency``                         double   frac          0-1          See [#]_            Recovery efficiency
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double   F-ft2-hr/Btu  >= 0         No        0         R-value of additional tank insulation wrap
  =============================================  =======  ============  ===========  ========  ========  ==========================================
  
  .. [#] FuelType choices are "natural gas", "fuel oil", "propane", "electricity", "wood", or "wood pellets".
  .. [#] If HeatingCapacity not provided, defaults based on Table 8 in the `2014 BAHSP <https://www.energy.gov/sites/prod/files/2014/03/f13/house_simulation_protocols_2014.pdf>`_.
  .. [#] FirstHourRating only required if UniformEnergyFactor provided.
  .. [#] RecoveryEfficiency only required if FuelType is not electricity.

Tankless
~~~~~~~~

If an instantaneous tankless water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  ===========================================  =======  ============  ===========  ============  ========  ==========================================================
  Element                                      Type     Units         Constraints  Required      Default   Notes
  ===========================================  =======  ============  ===========  ============  ========  ==========================================================
  ``FuelType``                                 string                 See [#]_     Yes                     Fuel type
  ``UniformEnergyFactor`` or ``EnergyFactor``  double   frac          0-1          Yes                     EnergyGuide label rated efficiency
  ===========================================  =======  ============  ===========  ============  ========  ==========================================================
  
  .. [#] FuelType choices are "natural gas", "fuel oil", "propane", "electricity", "wood", or "wood pellets".

Heat Pump
~~~~~~~~~

If a heat pump water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  =============================================  =======  ============  ===========  ========  ========  ==========================================
  Element                                        Type     Units         Constraints  Required  Default   Notes
  =============================================  =======  ============  ===========  ========  ========  ==========================================
  ``FuelType``                                   string                 See [#]_     Yes                 Fuel type
  ``TankVolume``                                 double   gal           > 0          Yes                 Tank volume
  ``UniformEnergyFactor`` or ``EnergyFactor``    double   frac          0-1          Yes                 EnergyGuide label rated efficiency
  ``FirstHourRating``                            double   gal/hr        > 0          See [#]_            EnergyGuide label first hour rating
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double   F-ft2-hr/Btu  >= 0         No        0         R-value of additional tank insulation wrap
  =============================================  =======  ============  ===========  ========  ========  ==========================================

  .. [#] FuelType only choice is "electricity".
  .. [#] FirstHourRating only required if UniformEnergyFactor provided.

Combi Boiler w/ Storage
~~~~~~~~~~~~~~~~~~~~~~~

If a combination boiler w/ storage tank (sometimes referred to as an indirect water heater) is specified, additional information is entered in ``WaterHeatingSystem``.

  =============================================  =======  ============  ===========  ============  ========  ==================================================
  Element                                        Type     Units         Constraints  Required      Default   Notes
  =============================================  =======  ============  ===========  ============  ========  ==================================================
  ``RelatedHVACSystem``                          idref                  See [#]_     Yes                     ID of boiler
  ``TankVolume``                                 double   gal           > 0          Yes                     Volume of the storage tank
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double   F-ft2-hr/Btu  >= 0         No            0         R-value of additional storage tank insulation wrap
  ``StandbyLoss``                                double   F/hr          > 0          No            See [#]_  Storage tank standby losses
  =============================================  =======  ============  ===========  ============  ========  ==================================================

  .. [#] RelatedHVACSystem must reference a ``HeatingSystem`` of type Boiler.
  .. [#] If StandbyLoss not provided, defaults based on a regression analysis of `AHRI Directory of Certified Product Performance <https://www.ahridirectory.org>`_.

Combi Boiler w/ Tankless Coil
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a combination boiler w/ tankless coil is specified, additional information is entered in ``WaterHeatingSystem``.

  =====================  =======  ============  ===========  ============  ========  ==================================================
  Element                Type     Units         Constraints  Required      Default   Notes
  =====================  =======  ============  ===========  ============  ========  ==================================================
  ``RelatedHVACSystem``  idref                  See [#]_     Yes                     ID of boiler
  =====================  =======  ============  ===========  ============  ========  ==================================================

  .. [#] RelatedHVACSystem must reference a ``HeatingSystem`` (Boiler).

Desuperheater
~~~~~~~~~~~~~

If the water heater uses a desuperheater, additional information is entered in ``WaterHeatingSystem``.

  =====================  =======  ============  ===========  ============  ========  ==================================
  Element                Type     Units         Constraints  Required      Default   Notes
  =====================  =======  ============  ===========  ============  ========  ==================================
  ``RelatedHVACSystem``  idref                  See [#]_     Yes                     ID of heat pump or air conditioner
  =====================  =======  ============  ===========  ============  ========  ==================================

  .. [#] RelatedHVACSystem must reference a ``HeatPump`` (air-to-air, mini-split, or ground-to-air) or ``CoolingSystem`` (central air conditioner).

HPXML Hot Water Distribution
****************************

If any water heating systems are provided, a single hot water distribution system is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution``.

  =================================  =======  ============  ===========  ========  ========  =======================================================================
  Element                            Type     Units         Constraints  Required  Default   Notes
  =================================  =======  ============  ===========  ========  ========  =======================================================================
  ``SystemIdentifier``               id                                  Yes                 Unique identifier
  ``SystemType``                     element                1 [#]_       Yes                 Type of in-unit distribution system serving the dwelling unit
  ``PipeInsulation/PipeRValue``      double   F-ft2-hr/Btu  >= 0         Yes                 Pipe insulation R-value
  ``DrainWaterHeatRecovery``         element                0-1          No        <none>    Presence of drain water heat recovery device
  ``extension/SharedRecirculation``  element                0-1 [#]_     No        <none>    Presence of shared recirculation system serving multiple dwelling units
  =================================  =======  ============  ===========  ========  ========  =======================================================================

  .. [#] SystemType child element choices are ``Standard`` and ``Recirculation``.
  .. [#] If SharedRecirculation is provided, SystemType must be ``Standard``.
         This is because a stacked recirculation system (i.e., shared recirculation loop plus an additional in-unit recirculation system) is more likely to indicate input errors than reflect an actual real-world scenario.

.. note::

  In attached/multifamily buildings, only the hot water distribution system serving the dwelling unit should be defined.
  The hot water distribution associated with, e.g., a shared laundry room should not be defined.

Standard
~~~~~~~~

If the in-unit distribution system is specified as standard, additional information is entered in ``SystemType/Standard``.

  ================  =======  =====  ===========  ========  ========  =====================
  Element           Type     Units  Constraints  Required  Default   Notes
  ================  =======  =====  ===========  ========  ========  =====================
  ``PipingLength``  double   ft     > 0          Yes                 Length of piping [#]_
  ================  =======  =====  ===========  ========  ========  =====================

  .. [#] PipingLength is the length of hot water piping from the hot water heater (or from a shared recirculation loop serving multiple dwelling units) to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any).

Recirculation
~~~~~~~~~~~~~

If the in-unit distribution system is specified as recirculation, additional information is entered in ``SystemType/Recirculation``.

  =================================  =======  =====  ===========  ========  ========  =====================================
  Element                            Type     Units  Constraints  Required  Default   Notes
  =================================  =======  =====  ===========  ========  ========  =====================================
  ``ControlType``                    string          See [#]_     Yes                 Recirculation control type
  ``RecirculationPipingLoopLength``  double   ft     > 0          Yes                 Recirculation piping loop length [#]_
  ``BranchPipingLoopLength``         double   ft     > 0          Yes                 Branch piping loop length [#]_
  ``PumpPower``                      double   W      >= 0         Yes                 Recirculation pump power
  =================================  =======  =====  ===========  ========  ========  =====================================

  .. [#] ControlType choices are "manual demand control", "presence sensor demand control", "temperature", "timer", or "no control".
  .. [#] RecirculationPipingLoopLength is the recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements.
  .. [#] BranchPipingLoopLength is the length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally.

Shared Recirculation
~~~~~~~~~~~~~~~~~~~~

If a shared recirculation system is specified, additional information is entered in ``extension/SharedRecirculation``.

  =======================  =======  =====  ===========  ========  ========  =================================
  Element                  Type     Units  Constraints  Required  Default   Notes
  =======================  =======  =====  ===========  ========  ========  =================================
  ``NumberofUnitsServed``  integer         > 1          Yes                 Number of dwelling units served
  ``PumpPower``            double   W      >= 0         No        220       Shared recirculation pump power
  ``ControlType``          string          See [#]_     Yes                 Shared recirculation control type
  =======================  =======  =====  ===========  ========  ========  =================================

  .. [#] ControlType choices are "manual demand control", "presence sensor demand control", "timer", or "no control".

Drain Water Heat Recovery
~~~~~~~~~~~~~~~~~~~~~~~~~

If a drain water heat recovery (DWHR) device is specified, additional information is entered in ``DrainWaterHeatRecovery``.

  =======================  =======  =====  ===========  ========  ========  =========================================
  Element                  Type     Units  Constraints  Required  Default   Notes
  =======================  =======  =====  ===========  ========  ========  =========================================
  ``FacilitiesConnected``  string          See [#]_     Yes                 Specifies which facilities are connected
  ``EqualFlow``            boolean                      Yes                 Specifies how the DHWR is configured [#]_
  ``Efficiency``           double   frac   0-1          Yes                 Efficiency according to CSA 55.1
  =======================  =======  =====  ===========  ========  ========  =========================================

  .. [#] FacilitiesConnected choices are "one" or "all".
         Use "one" if there are multiple showers and only one of them is connected to the DWHR.
         Use "all" if there is one shower and it's connected to the DWHR or there are two or more showers connected to the DWHR.
  .. [#] EqualFlow should be true if the DWHR supplies pre-heated water to both the fixture cold water piping *and* the hot water heater potable supply piping.

HPXML Water Fixtures
********************

Each water fixture is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture``.

  ====================  =======  =====  ===========  ========  ========  ===============================================
  Element               Type     Units  Constraints  Required  Default   Notes
  ====================  =======  =====  ===========  ========  ========  ===============================================
  ``SystemIdentifier``  id                           Yes                 Unique identifier
  ``WaterFixtureType``  string          See [#]_     Yes                 Type of water fixture
  ``LowFlow``           boolean                      Yes                 Whether the fixture is considered low-flow [#]_
  ====================  =======  =====  ===========  ========  ========  ===============================================

  .. [#] WaterFixtureType choices are "shower head" or "faucet".
  .. [#] LowFlow should be true if the fixture's flow rate (gpm) is <= 2.0.

HPXML Solar Thermal
*******************

A single solar hot water system can be entered as a ``/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem``.

  ====================  =======  =====  ===========  ========  ========  ============================
  Element               Type     Units  Constraints  Required  Default   Notes
  ====================  =======  =====  ===========  ========  ========  ============================
  ``SystemIdentifier``  id                           Yes                 Unique identifier
  ``SystemType``        string          See [#]_     Yes                 Type of solar thermal system
  ====================  =======  =====  ===========  ========  ========  ============================

  .. [#] SystemType only choice is "hot water".

Solar hot water systems can be described with either simple or detailed inputs.

Simple Inputs
~~~~~~~~~~~~~

To define a simple solar hot water system, additional information is entered in ``SolarThermalSystem``.

  =================  =======  =====  ===========  ========  ========  ======================
  Element            Type     Units  Constraints  Required  Default   Notes
  =================  =======  =====  ===========  ========  ========  ======================
  ``SolarFraction``  double   frac   0-1          Yes                 Solar fraction [#]_
  ``ConnectedTo``    idref           See [#]_     No [#]_   <none>    Connected water heater
  =================  =======  =====  ===========  ========  ========  ======================
  
  .. [#] Portion of total conventional hot water heating load (delivered energy plus tank standby losses).
         Can be obtained from `Directory of SRCC OG-300 Solar Water Heating System Ratings <https://solar-rating.org/programs/og-300-program/>`_ or NREL's `System Advisor Model <https://sam.nrel.gov/>`_ or equivalent.
  .. [#] ConnectedTo must reference a ``WaterHeatingSystem``.
         The referenced water heater cannot be a space-heating boiler nor attached to a desuperheater.
  .. [#] If ConnectedTo not provided, solar fraction will apply to all water heaters in the building.

Detailed Inputs
~~~~~~~~~~~~~~~

To define a detailed solar hot water system, additional information is entered in ``SolarThermalSystem``.

  ===================================  =======  ============  ===========  ========  ========  ==============================
  Element                              Type     Units         Constraints  Required  Default   Notes
  ===================================  =======  ============  ===========  ========  ========  ==============================
  ``CollectorArea``                    double   ft2           > 0          Yes                 Area
  ``CollectorLoopType``                string                 See [#]_     Yes                 Loop type
  ``CollectorType``                    string                 See [#]_     Yes                 System type
  ``CollectorAzimuth``                 integer  deg           0-359        Yes                 Azimuth (clockwise from North)
  ``CollectorTilt``                    double   deg           0-90         Yes                 Tilt relative to horizontal
  ``CollectorRatedOpticalEfficiency``  double   frac          0-1          Yes                 Rated optical efficiency [#]_
  ``CollectorRatedThermalLosses``      double   Btu/hr-ft2-R  > 0          Yes                 Rated thermal losses [#]_
  ``StorageVolume``                    double   gal           > 0          Yes                 Hot water storage volume
  ``ConnectedTo``                      idref                  See [#]_     Yes                 Connected water heater
  ===================================  =======  ============  ===========  ========  ========  ==============================
  
  .. [#] CollectorLoopType choices are "liquid indirect", "liquid direct", or "passive thermosyphon".
  .. [#] CollectorType choices are "single glazing black", "double glazing black", "evacuated tube", or "integrated collector storage".
  .. [#] CollectorRatedOpticalEfficiency is FRTA (y-intercept) from the `Directory of SRCC OG-100 Certified Solar Collector Ratings <https://solar-rating.org/programs/og-100-program/>`_.
  .. [#] CollectorRatedThermalLosses is FRUL (slope) from the `Directory of SRCC OG-100 Certified Solar Collector Ratings <https://solar-rating.org/programs/og-100-program/>`_.
  .. [#] ConnectedTo must reference a ``WaterHeatingSystem`` that is not of type space-heating boiler nor connected to a desuperheater.

HPXML Photovoltaics
*******************

Each solar electric photovoltaic (PV) system is entered as a ``/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem``.

Many of the inputs are adopted from the `PVWatts model <https://pvwatts.nrel.gov>`_.

  ====================================  =======  =====  ===========  ========  ========  ============================================
  Element                               Type     Units  Constraints  Required  Default   Notes
  ====================================  =======  =====  ===========  ========  ========  ============================================
  ``SystemIdentifier``                  id                           Yes                 Unique identifier
  ``IsSharedSystem``                    boolean                      Yes                 Whether it serves multiple dwelling units
  ``Location``                          string          See [#]_     Yes                 Mounting location
  ``ModuleType``                        string          See [#]_     Yes                 Type of module
  ``Tracking``                          string          See [#]_     Yes                 Type of tracking
  ``ArrayAzimuth``                      integer  deg    0-359        Yes                 Direction panels face (clockwise from North)
  ``ArrayTilt``                         double   deg    0-90         Yes                 Tilt relative to horizontal
  ``MaxPowerOutput``                    double   W      >= 0         Yes                 Peak power
  ``InverterEfficiency``                double   frac   0-1          Yes                 Inverter efficiency [#]_
  ``SystemLossesFraction``              double   frac   0-1          Yes                 System losses [#]_
  ``extension/NumberofBedroomsServed``  integer         > 1          See [#]_            Number of bedrooms served
  ====================================  =======  =====  ===========  ========  ========  ============================================
  
  .. [#] Location choices are "ground" or "roof" mounted.
  .. [#] ModuleType choices are "standard", "premium", or "thin film".
  .. [#] Tracking choices are "fixed", "1-axis", "1-axis backtracked", or "2-axis".
  .. [#] Default from PVWatts is 0.96.
  .. [#] System losses due to soiling, shading, snow, mismatch, wiring, degradation, etc.
         Default from PVWatts is 0.14.
  .. [#] NumberofBedroomsServed only required if IsSharedSystem is true.
         PV generation will be apportioned to the dwelling unit using its number of bedrooms divided by the total number of bedrooms served by the PV system.

HPXML Generators
****************

Each generator that provides on-site power is entered as a ``/HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator``.

  ==========================  =======  =======  ===========  ========  =======  ============================================
  Element                     Type     Units    Constraints  Required  Default  Notes
  ==========================  =======  =======  ===========  ========  =======  ============================================
  ``SystemIdentifier``        id                             Yes                Unique identifier
  ``IsSharedSystem``          boolean                        Yes                Whether it serves multiple dwelling units
  ``FuelType``                string            See [#]_     Yes                Fuel type
  ``AnnualConsumptionkBtu``   double   kBtu/yr  > 0          Yes                Annual fuel consumed
  ``AnnualOutputkWh``         double   kWh/yr   > 0          Yes                Annual electricity produced
  ``NumberofBedroomsServed``  integer           > 1          See [#]_           Number of bedrooms served
  ==========================  =======  =======  ===========  ========  =======  ============================================

  .. [#] FuelType choices are "natural gas" or "propane".
  .. [#] NumberofBedroomsServed only required if IsSharedSystem is true.
         Annual consumption and annual production will be apportioned to the dwelling unit using its number of bedrooms divided by the total number of bedrooms served by the generator.

.. note::

  Generators will be modeled as operating continuously (24/7).

HPXML Appliances
----------------

Appliances entered in ``/HPXML/Building/BuildingDetails/Appliances``.

HPXML Clothes Washer
********************

A single clothes washer can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/ClothesWasher``.

  ==============================================================  =======  ===========  ===========  ========  =======  ==============================================
  Element                                                         Type     Units        Constraints  Required  Default  Notes
  ==============================================================  =======  ===========  ===========  ========  =======  ==============================================
  ``SystemIdentifier``                                            id                                 Yes                Unique identifier
  ``IsSharedAppliance``                                           boolean                            Yes                Whether it serves multiple dwelling units [#]_
  ``Location``                                                    string                See [#]_     Yes                Location
  ``IntegratedModifiedEnergyFactor`` or ``ModifiedEnergyFactor``  double   ft3/kWh/cyc  > 0          Yes                EnergyGuide label efficiency [#]_
  ``RatedAnnualkWh``                                              double   kWh/yr       > 0          Yes                EnergyGuide label annual consumption
  ``LabelElectricRate``                                           double   $/kWh        > 0          Yes                EnergyGuide label electricity rate
  ``LabelGasRate``                                                double   $/therm      > 0          Yes                EnergyGuide label natural gas rate
  ``LabelAnnualGasCost``                                          double   $            > 0          Yes                EnergyGuide label annual gas cost
  ``LabelUsage``                                                  double   cyc/wk       > 0          Yes                EnergyGuide label number of cycles
  ``Capacity``                                                    double   ft3          > 0          Yes                Clothes dryer volume
  ==============================================================  =======  ===========  ===========  ========  =======  ==============================================

  .. [#] For example, a clothes washer in a shared laundry room of a MF building.
  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If ModifiedEnergyFactor (MEF) provided instead of IntegratedModifiedEnergyFactor (IMEF), it will be converted using the `Interpretation on ANSI/RESNET 301-2014 Clothes Washer IMEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-08-sECTION-4.2.2.5.2.8-Clothes-Washers-Eq-4.2-6.pdf>`_:
         IMEF = (MEF - 0.503) / 0.95.

If the clothes washer is shared, additional information is entered in ``/HPXML/Building/BuildingDetails/Appliances/ClothesWasher``.

  ================================  =======  =====  ===========  ========  =======  ==========================================================
  Element                           Type     Units  Constraints  Required  Default  Notes
  ================================  =======  =====  ===========  ========  =======  ==========================================================
  ``AttachedToWaterHeatingSystem``  idref           See [#]_     Yes                ID of attached water heater
  ``NumberofUnits``                 integer                      Yes                Number of clothes washers in the shared laundry room
  ``NumberofUnitsServed``           integer                      Yes                Number of dwelling units served by the shared laundry room
  ================================  =======  =====  ===========  ========  =======  ==========================================================

  .. [#] AttachedToWaterHeatingSystem must reference a ``WaterHeatingSystem``.

.. note::

  If no clothes washer is located within the Rated Home, a clothes washer in the nearest shared laundry room on the project site shall be used if available for daily use by the occupants of the Rated Home.
  If there are multiple clothes washers, the clothes washer with the highest Label Energy Rating (kWh/yr) shall be used.

HPXML Clothes Dryer
*******************

A single clothes dryer can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/ClothesDryer``.

  ============================================  =======  ======  ===========  ========  ============  ==============================================
  Element                                       Type     Units   Constraints  Required  Default       Notes
  ============================================  =======  ======  ===========  ========  ============  ==============================================
  ``SystemIdentifier``                          id                            Yes                     Unique identifier
  ``IsSharedAppliance``                         boolean                       Yes                     Whether it serves multiple dwelling units [#]_
  ``Location``                                  string           See [#]_     Yes                     Location
  ``FuelType``                                  string           See [#]_     Yes                     Fuel type
  ``CombinedEnergyFactor`` or ``EnergyFactor``  double   lb/kWh  > 0          Yes                     EnergyGuide label efficiency [#]_
  ``ControlType``                               string           See [#]_     Yes                     Type of controls
  ============================================  =======  ======  ===========  ========  ============  ==============================================

  .. [#] For example, a clothes dryer in a shared laundry room of a MF building.
  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] FuelType choices are "natural gas", "fuel oil", "propane", "electricity", "wood", or "wood pellets".
  .. [#] If EnergyFactor (EF) provided instead of CombinedEnergyFactor (CEF), it will be converted using the following equation based on the `Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-10-Section-4.2.2.5.2.8-Clothes-Dryer-CEF-Rating.pdf>`_:
         CEF = EF / 1.15.
  .. [#] ControlType choices are "timer" or "moisture".

If the clothes dryer is shared, additional information is entered in ``/HPXML/Building/BuildingDetails/Appliances/ClothesDryer``.

  =======================  =======  =====  ===========  ========  =======  ==========================================================
  Element                  Type     Units  Constraints  Required  Default  Notes
  =======================  =======  =====  ===========  ========  =======  ==========================================================
  ``NumberofUnits``        integer                      Yes                Number of clothes dryers in the shared laundry room
  ``NumberofUnitsServed``  integer                      Yes                Number of dwelling units served by the shared laundry room
  ================================  =====  ===========  ========  =======  ==========================================================
  
.. note::

  If no clothes dryer is located within the Rated Home, a clothes dryer in the nearest shared laundry room on the project site shall be used if available for daily use by the occupants of the Rated Home.
  If there are multiple clothes dryers, the clothes dryer with the lowest Energy Factor or Combined Energy Factor shall be used.

HPXML Dishwasher
****************

A single dishwasher can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Dishwasher``.

  ======================================  =======  ===========  ===========  ========  =======  ==============================================
  Element                                 Type     Units        Constraints  Required  Default  Notes
  ======================================  =======  ===========  ===========  ========  =======  ==============================================
  ``SystemIdentifier``                    id                                 Yes                Unique identifier
  ``IsSharedAppliance``                   boolean                            Yes                Whether it serves multiple dwelling units [#]_
  ``Location``                            string                See [#]_     Yes                Location
  ``RatedAnnualkWh`` or ``EnergyFactor``  double   kWh/yr or #  > 0          Yes                EnergyGuide label consumption/efficiency [#]_
  ``LabelElectricRate``                   double   $/kWh        > 0          Yes                EnergyGuide label electricity rate
  ``LabelGasRate``                        double   $/therm      > 0          Yes                EnergyGuide label natural gas rate
  ``LabelAnnualGasCost``                  double   $            > 0          Yes                EnergyGuide label annual gas cost
  ``LabelUsage``                          double   cyc/wk       > 0          Yes                EnergyGuide label number of cycles
  ``PlaceSettingCapacity``                integer  #            > 0          Yes                Number of place settings
  ======================================  =======  ===========  ===========  ========  =======  ==============================================

  .. [#] For example, a dishwasher in a shared mechanical room of a MF building.
  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If EnergyFactor (EF) provided instead of RatedAnnualkWh, it will be converted using the following equation based on `ANSI/RESNET/ICC 301-2014 <https://codes.iccsafe.org/content/document/843>`_:
         RatedAnnualkWh = 215.0 / EF.

If the dishwasher is shared, additional information is entered in ``/HPXML/Building/BuildingDetails/Appliances/Dishwasher``.

  ================================  =======  =====  ===========  ========  =======  ===========================
  Element                           Type     Units  Constraints  Required  Default  Notes
  ================================  =======  =====  ===========  ========  =======  ===========================
  ``AttachedToWaterHeatingSystem``  idref           See [#]_     Yes                ID of attached water heater
  ================================  =======  =====  ===========  ========  =======  ===========================

  .. [#] AttachedToWaterHeatingSystem must reference a ``WaterHeatingSystem``.

.. note::
  
  If no dishwasher is located within the Rated Home, a dishwasher in the nearest shared kitchen in the building shall be used only if available for daily use by the occupants of the Rated Home.
  If there are multiple dishwashers, the dishwasher with the lowest Energy Factor (highest kWh/yr) shall be used.
  
HPXML Refrigerators
*******************

A single refrigerator can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Refrigerator``.

  ====================  =======  ======  ===========  ========  ========  ==================
  Element               Type     Units   Constraints  Required  Default   Notes
  ====================  =======  ======  ===========  ========  ========  ==================
  ``SystemIdentifier``  id                            Yes                 Unique identifier
  ``Location``          string           See [#]_     Yes                 Location
  ``RatedAnnualkWh``    double   kWh/yr  > 0          Yes                 Annual consumption
  ====================  =======  ======  ===========  ========  ========  ==================

  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.

.. note::
  
  If there are multiple refrigerators, the total energy consumption of all refrigerators/freezers shall be used along with the location that represents the majority of power consumption.

HPXML Dehumidifier
******************

A single dehumidifier can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Dehumidifier``.

  ==============================================  ==========  ==========  ===========  ========  =======  ========================================
  Element                                         Type        Units       Constraints  Required  Default  Notes
  ==============================================  ==========  ==========  ===========  ========  =======  ========================================
  ``SystemIdentifier``                            id                                   Yes                Unique identifier
  ``Type``                                        string                  See [#]_     Yes                Type of dehumidifier
  ``Capacity``                                    double      pints/day   > 0          Yes                Dehumidification capacity
  ``IntegratedEnergyFactor`` or ``EnergyFactor``  double      liters/kWh  > 0          Yes                Rated efficiency
  ``DehumidistatSetpoint``                        double      frac        0-1          Yes                Relative humidity setpoint
  ``FractionDehumidificationLoadServed``          double      frac        0-1          Yes                Fraction of dehumidification load served
  ==============================================  ==========  ==========  ===========  ========  =======  ========================================
  
  .. [#] Type choices are "portable" or "whole-home".

.. note::

  Dehumidifiers only affect ERI scores if Version 2019AB or newer is used, as dehumidifiers were incorporated into the ERI calculation as of 301-2019 Addendum B.

HPXML Cooking Range/Oven
************************

A single cooking range can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/CookingRange``.

  ====================  =======  ======  ===========  ========  =======  =================
  Element               Type     Units   Constraints  Required  Default  Notes
  ====================  =======  ======  ===========  ========  =======  =================
  ``SystemIdentifier``  id                            Yes                Unique identifier
  ``Location``          string           See [#]_     Yes                Location
  ``FuelType``          string           See [#]_     Yes                Fuel type
  ``IsInduction``       boolean                       Yes                Induction range?
  ====================  =======  ======  ===========  ========  =======  =================

  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] FuelType choices are "natural gas", "fuel oil", "propane", "electricity", "wood", or "wood pellets".

If a cooking range is specified, a single oven is also entered as a ``/HPXML/Building/BuildingDetails/Appliances/Oven``.

  ====================  =======  ======  ===========  ========  =======  ================
  Element               Type     Units   Constraints  Required  Default  Notes
  ====================  =======  ======  ===========  ========  =======  ================
  ``SystemIdentifier``  id                            Yes                Unique identifier
  ``IsConvection``      boolean                       Yes                Convection oven?
  ====================  =======  ======  ===========  ========  =======  ================

HPXML Lighting & Ceiling Fans
-----------------------------

Lighting and ceiling fans are entered in ``/HPXML/Building/BuildingDetails/Lighting``.

HPXML Lighting
**************

If the building has lighting, nine ``/HPXML/Building/BuildingDetails/Lighting/LightingGroup`` elements must be provided, each of which is the combination of:

- ``LightingType``: 'LightEmittingDiode', 'CompactFluorescent', and 'FluorescentTube'
- ``Location``: 'interior', 'garage', and 'exterior'

Use ``LightEmittingDiode`` for Tier II qualifying light fixtures; use ``CompactFluorescent`` and/or ``FluorescentTube`` for Tier I qualifying light fixtures.

Information is entered in each ``LightingGroup``.

  =============================  =======  ======  ===========  ========  =======  ===========================================================================
  Element                        Type     Units   Constraints  Required  Default  Notes
  =============================  =======  ======  ===========  ========  =======  ===========================================================================
  ``SystemIdentifier``           id                            Yes                Unique identifier
  ``LightingType``               element          1 [#]_       Yes                Lighting type
  ``Location``                   string           See [#]_     Yes                See [#]_
  ``FractionofUnitsInLocation``  double   frac    0-1 [#]_     Yes                Fraction of light fixtures in the location with the specified lighting type
  =============================  =======  ======  ===========  ========  =======  ===========================================================================

  .. [#] LightingType child element choices are ``LightEmittingDiode``, ``CompactFluorescent``, or ``FluorescentTube``.
  .. [#] Location choices are "interior", "garage", or "exterior".
  .. [#] Garage lighting is ignored if the building has no garage specified elsewhere.
  .. [#] The sum of FractionofUnitsInLocation for a given Location (e.g., interior) must be less than or equal to 1.
         If the fractions sum to less than 1, the remainder is assumed to be incandescent lighting.

HPXML Ceiling Fans
******************

Each ceiling fan is entered as a ``/HPXML/Building/BuildingDetails/Lighting/CeilingFan``.

  =========================================  =======  =======  ===========  ========  ========  ==============================
  Element                                    Type     Units    Constraints  Required  Default   Notes
  =========================================  =======  =======  ===========  ========  ========  ==============================
  ``SystemIdentifier``                       id                             Yes                 Unique identifier
  ``Airflow[FanSpeed="medium"]/Efficiency``  double   cfm/W    > 0          Yes                 Efficiency at medium speed
  ``Quantity``                               integer           > 0          Yes                 Number of similar ceiling fans
  =========================================  =======  =======  ===========  ========  ========  ==============================

.. _hpxmllocations:

HPXML Locations
---------------

The various locations used in an HPXML file are defined as follows:

  ==============================  ==================================  ============================================  =============
  Value                           Description                         Temperature                                   Building Type
  ==============================  ==================================  ============================================  =============
  outside                         Ambient environment                 Weather data                                  Any
  ground                                                              EnergyPlus calculation                        Any
  living space                    Above-grade conditioned floor area  EnergyPlus calculation                        Any
  attic - vented                                                      EnergyPlus calculation                        Any
  attic - unvented                                                    EnergyPlus calculation                        Any
  basement - conditioned          Below-grade conditioned floor area  EnergyPlus calculation                        Any
  basement - unconditioned                                            EnergyPlus calculation                        Any
  crawlspace - vented                                                 EnergyPlus calculation                        Any
  crawlspace - unvented                                               EnergyPlus calculation                        Any
  garage                          Single-family (not shared parking)  EnergyPlus calculation                        Any
  other housing unit              Unrated Conditioned Space           Same as conditioned space                     SFA/MF only
  other heated space              Unrated Heated Space                Avg of conditioned space/outside; min of 68F  SFA/MF only
  other multifamily buffer space  Multifamily Buffer Boundary         Avg of conditioned space/outside; min of 50F  SFA/MF only
  other non-freezing space        Non-Freezing Space                  Floats with outside; minimum of 40F           SFA/MF only
  other exterior                  Water heater outside                Weather data                                  Any
  exterior wall                   Ducts in exterior wall              Avg of living space/outside                   Any
  under slab                      Ducts under slab (ground)           EnergyPlus calculation                        Any
  roof deck                       Ducts on roof deck (outside)        Weather data                                  Any
  ==============================  ==================================  ============================================  =============

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
