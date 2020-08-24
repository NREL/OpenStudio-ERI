# frozen_string_literal: true

class EnergyRatingIndex301Validator
  def self.run_validator(hpxml_doc)
    # A hash of hashes that defines the XML elements used by the ERI HPXML Use Case.
    #
    # Example:
    #
    # use_case = {
    #     nil => {
    #         'floor_area' => one,            # 1 element required always
    #         'garage_area' => zero_or_one,   # 0 or 1 elements required always
    #         'walls' => one_or_more,         # 1 or more elements required always
    #     },
    #     '/walls' => {
    #         'rvalue' => one,                # 1 element required if /walls element exists (conditional)
    #         'windows' => zero_or_one,       # 0 or 1 elements required if /walls element exists (conditional)
    #         'layers' => one_or_more,        # 1 or more elements required if /walls element exists (conditional)
    #     }
    # }
    #

    zero = [0]
    zero_or_one = [0, 1]
    zero_or_more = nil
    one = [1]
    one_or_more = []

    requirements = {

      # Root
      nil => {
        '/HPXML/XMLTransactionHeaderInformation/XMLType' => one, # Required by HPXML schema
        '/HPXML/XMLTransactionHeaderInformation/XMLGeneratedBy' => one, # Required by HPXML schema
        '/HPXML/XMLTransactionHeaderInformation/CreatedDateAndTime' => one, # Required by HPXML schema
        '/HPXML/XMLTransactionHeaderInformation/Transaction' => one, # Required by HPXML schema
        '/HPXML/SoftwareInfo/extension/ERICalculation[Version="latest" or Version="2019A" or Version="2019" or Version="2014ADEGL" or Version="2014ADEG" or Version="2014ADE" or Version="2014AD" or Version="2014A" or Version="2014"]' => one, # Choose version of 301 standard and addenda (e.g., A, D, E, G)

        '/HPXML/Building' => one,
        '/HPXML/Building/BuildingID' => one, # Required by HPXML schema
        '/HPXML/Building/ProjectStatus/EventType' => one, # Required by HPXML schema

        '/HPXML/Building/BuildingDetails/BuildingSummary/Site/FuelTypesAvailable/Fuel' => one_or_more,
        '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => one, # See [BuildingConstruction]

        '/HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC' => one, # See [ClimateZone]
        '/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation' => one, # See [WeatherStation]

        '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/UnitofMeasure[text()="ACH" or text()="CFM" or text()="ACHnatural"]]' => one, # see [AirInfiltration]

        '/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic' => zero_or_more, # See [Attic]
        '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation' => zero_or_more, # See [Foundation]
        '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof' => zero_or_more, # See [Roof]
        '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => one_or_more, # See [Wall]
        '/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist' => zero_or_more, # See [RimJoist]
        '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall' => zero_or_more, # See [FoundationWall]
        '/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor' => zero_or_more, # See [FrameFloor]
        '/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab' => zero_or_more, # See [Slab]
        '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window' => zero_or_more, # See [Window]
        '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight' => zero_or_more, # See [Skylight]
        '/HPXML/Building/BuildingDetails/Enclosure/Doors/Door' => zero_or_more, # See [Door]

        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => zero_or_more, # See [HeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => zero_or_more, # See [CoolingSystem]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => zero_or_more, # See [HeatPump]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => zero_or_one, # See [HVACControl]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution' => zero_or_more, # See [HVACDistribution]

        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => zero_or_more, # See [MechanicalVentilation]
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction="true"]' => zero_or_more, # See [WholeHouseFan]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => zero_or_more, # See [WaterHeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => zero_or_one, # See [HotWaterDistribution]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => zero_or_more, # See [WaterFixture]
        '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem' => zero_or_one, # See [SolarThermalSystem]
        '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => zero_or_more, # See [PVSystem]

        '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => zero_or_one, # See [ClothesWasher]
        '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => zero_or_one, # See [ClothesDryer]
        '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => zero_or_one, # See [Dishwasher]
        '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => zero_or_one, # See [Refrigerator]
        '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => zero_or_one, # See [CookingRange]
        '/HPXML/Building/BuildingDetails/Appliances/Oven' => zero_or_one, # See [Oven]

        '/HPXML/Building/BuildingDetails/Lighting' => one, # See [Lighting]
        '/HPXML/Building/BuildingDetails/Lighting/CeilingFan' => zero_or_more, # See [CeilingFan]
      },

      # [BuildingConstruction]
      '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => {
        'ResidentialFacilityType[text()="single-family detached" or text()="single-family attached" or text()="apartment unit" or text()="manufactured home"]' => one,
        'NumberofConditionedFloors' => one,
        'NumberofConditionedFloorsAboveGrade' => one,
        'NumberofBedrooms' => one,
        'ConditionedFloorArea' => one,
        'ConditionedBuildingVolume' => one,
      },

      # [ClimateZone]
      '/HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC' => {
        'Year' => one,
        'ClimateZone[text()="1A" or text()="1B" or text()="1C" or text()="2A" or text()="2B" or text()="2C" or text()="3A" or text()="3B" or text()="3C" or text()="4A" or text()="4B" or text()="4C" or text()="5A" or text()="5B" or text()="5C" or text()="6A" or text()="6B" or text()="6C" or text()="7" or text()="8"]' => one,
      },

      # [WeatherStation]
      '/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Name' => one, # Required by HPXML schema
        'WMO | extension/EPWFilePath' => one, # Reference weather/data.csv for the list of acceptable WMO station numbers
      },

      # [AirInfiltration]
      '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement[BuildingAirLeakage/UnitofMeasure[text()="ACH" or text()="CFM" or text()="ACHnatural"]]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '[(number(HousePressure)=50 and BuildingAirLeakage/UnitofMeasure!="ACHnatural") or (not(HousePressure) and BuildingAirLeakage/UnitofMeasure="ACHnatural")]' => one,
        'BuildingAirLeakage/AirLeakage' => one,
        'InfiltrationVolume' => one,
      },

      # [Attic]
      '/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'AtticType' => one, # Required by HPXML schema
      },

      # [Foundation]
      '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'FoundationType' => one, # Required by HPXML schema
      },

      # [Roof]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'InteriorAdjacentTo[text()="attic - vented" or text()="attic - unvented" or text()="living space" or text()="garage"]' => one, # See [VentedAttic] or [UnventedAttic]
        'Area' => one,
        'Azimuth' => zero_or_one,
        'SolarAbsorptance' => one,
        'Emittance' => one,
        'Pitch' => one,
        'RadiantBarrier' => one, # See [RadiantBarrier]
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      ## [VentedAttic]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof[InteriorAdjacentTo="attic - vented"]' => {
        '../../Attics/Attic[AtticType/Attic[Vented="true"]]/VentilationRate[UnitofMeasure="SLA" or UnitofMeasure="ACHnatural"]/Value' => zero_or_one,
      },

      ## [UnventedAttic]
      "/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof[InteriorAdjacentTo='attic - unvented']" => {
        "../../Attics/Attic[AtticType/Attic[Vented='false']]/WithinInfiltrationVolume" => one,
      },

      ## [RadiantBarrier]
      '/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof[RadiantBarrier="true"]' => {
        'RadiantBarrierGrade' => one,
      },
      # [Wall]
      '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'InteriorAdjacentTo[text()="living space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'WallType[WoodStud | DoubleWoodStud | ConcreteMasonryUnit | StructurallyInsulatedPanel | InsulatedConcreteForms | SteelFrame | SolidConcrete | StructuralBrick | StrawBale | Stone | LogWall | Adobe]' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        'SolarAbsorptance' => one,
        'Emittance' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [RimJoist]
      '/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'InteriorAdjacentTo[text()="living space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        'SolarAbsorptance' => one,
        'Emittance' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      # [FoundationWall]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="ground" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'InteriorAdjacentTo[text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one, # See [VentedCrawlspace] or [UnventedCrawlspace] or [UnconditionedBasement]
        'Height' => one,
        'Area' => one,
        'Azimuth' => zero_or_one,
        'Thickness' => one,
        'DepthBelowGrade' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        # Insulation: either specify interior and exterior layers OR assembly R-value:
        'Insulation/Layer[InstallationType="continuous - interior"] | Insulation/AssemblyEffectiveRValue' => one, # See [FoundationWallInsLayer]
        'Insulation/Layer[InstallationType="continuous - exterior"] | Insulation/AssemblyEffectiveRValue' => one, # See [FoundationWallInsLayer]
      },

      ## [VentedCrawlspace]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall[InteriorAdjacentTo="crawlspace - vented"]' => {
        '../../Foundations/Foundation[FoundationType/Crawlspace[Vented="true"]]/VentilationRate[UnitofMeasure="SLA"]/Value' => zero_or_one,
      },

      ## [UnventedCrawlspace]
      "/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall[InteriorAdjacentTo='crawlspace - unvented']" => {
        "../../Foundations/Foundation[FoundationType/Crawlspace[Vented='false']]/WithinInfiltrationVolume" => one,
      },

      ## [UnconditionedBasement]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall[InteriorAdjacentTo="basement - unconditioned"]' => {
        '../../Foundations/Foundation[FoundationType/Basement[Conditioned="false"]]/ThermalBoundary' => one,
        '../../Foundations/Foundation[FoundationType/Basement[Conditioned="false"]]/WithinInfiltrationVolume' => one,
      },

      ## [FoundationWallInsLayer]
      '/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall/Insulation/Layer[InstallationType="continuous - exterior" or InstallationType="continuous - interior"]' => {
        'NominalRValue' => one,
        'extension/DistanceToTopOfInsulation' => one, # ft
        'extension/DistanceToBottomOfInsulation' => one, # ft
      },

      # [FrameFloor]
      '/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ExteriorAdjacentTo[text()="outside" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one, # See [FrameFloorAdjacentToOther]
        'InteriorAdjacentTo[text()="living space" or text()="attic - vented" or text()="attic - unvented" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'Area' => one,
        'Insulation/SystemIdentifier' => one, # Required by HPXML schema
        'Insulation/AssemblyEffectiveRValue' => one,
      },

      ## [FrameFloorAdjacentToOther]
      '/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor[ExteriorAdjacentTo[text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]]' => {
        'extension/OtherSpaceAboveOrBelow[text()="above" or text()="below"]' => one,
      },

      # [Slab]
      '/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'InteriorAdjacentTo[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="garage"]' => one,
        'Area' => one,
        'Thickness' => one, # Use zero for dirt floor
        'ExposedPerimeter' => one,
        'PerimeterInsulationDepth' => one,
        'UnderSlabInsulationWidth | UnderSlabInsulationSpansEntireSlab[text()="true"]' => one,
        'DepthBelowGrade | InteriorAdjacentTo[text()!="living space" and text()!="garage"]' => one_or_more, # DepthBelowGrade only required when InteriorAdjacentTo is 'living space' or 'garage'
        'PerimeterInsulation/SystemIdentifier' => one, # Required by HPXML schema
        'PerimeterInsulation/Layer[InstallationType="continuous"]/NominalRValue' => one,
        'UnderSlabInsulation/SystemIdentifier' => one, # Required by HPXML schema
        'UnderSlabInsulation/Layer[InstallationType="continuous"]/NominalRValue' => one,
        'extension/CarpetFraction' => one, # 0 - 1
        'extension/CarpetRValue' => one,
      },

      # [Window]
      '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Area' => one,
        'Azimuth' => one,
        'UFactor' => one,
        'SHGC' => one,
        'Overhangs' => zero_or_one, # See [WindowOverhang]
        'FractionOperable' => one,
        'AttachedToWall' => one,
      },

      ## [WindowOverhang]
      '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs' => {
        'Depth' => one,
        'DistanceToTopOfWindow' => one,
        'DistanceToBottomOfWindow' => one,
      },

      # [Skylight]
      '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Area' => one,
        'Azimuth' => one,
        'UFactor' => one,
        'SHGC' => one,
        'AttachedToRoof' => one,
      },

      # [Door]
      '/HPXML/Building/BuildingDetails/Enclosure/Doors/Door' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'AttachedToWall' => one,
        'Area' => one,
        'Azimuth' => one,
        'RValue' => one,
      },

      # [HeatingSystem]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        'HeatingSystemType[ElectricResistance | Furnace | WallFurnace | FloorFurnace | Boiler | Stove | PortableHeater | FixedHeater | Fireplace]' => one, # See [HeatingType=Resistance] or [HeatingType=Furnace] or [HeatingType=WallFurnace] or [HeatingType=FloorFurnace] or [HeatingType=Boiler] or [HeatingType=Stove] or [HeatingType=PortableHeater] or [HeatingType=FixedHeater] or [HeatingType=Fireplace]
        'FractionHeatLoadServed' => one, # Must sum to <= 1 across all HeatingSystems and HeatPumps
        'ElectricAuxiliaryEnergy' => zero_or_one, # If not provided, uses 301 defaults for fuel furnace/boiler and zero otherwise
      },

      ## [HeatingType=Resistance]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="electricity"]' => one,
        'HeatingCapacity' => one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=Furnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=WallFurnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/WallFurnace]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=FloorFurnace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/FloorFurnace]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [HeatingType=Boiler]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler]' => {
        'IsSharedSystem' => one, # See [BoilerType=InUnit] or [BoilerType=Shared]
        'DistributionSystem' => one,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
      },

      ## [BoilerType=InUnit]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler and IsSharedSystem="false"]' => {
        '../../HVACDistribution[DistributionSystemType/HydronicDistribution[HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]] | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'HeatingCapacity' => one,
      },

      ## [BoilerType=Shared]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler and IsSharedSystem="true"]' => {
        '../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]' => one,
        '../../HVACDistribution[DistributionSystemType/HydronicDistribution[HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]] | DistributionSystemType/HydronicAndAirDistribution[HydronicAndAirDistributionType[text()="fan coil" or text()="water loop heat pump"]]]' => one, # See [HVACDistribution]
        '../../HVACDistribution/extension/SharedLoopWatts' => one,
        'NumberofUnitsServed' => one,
      },

      ## [HeatingType=Stove]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Stove]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => zero_or_one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=PortableHeater]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/PortableHeater]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => zero_or_one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=FixedHeater]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/FixedHeater]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => zero_or_one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      ## [HeatingType=Fireplace]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Fireplace]' => {
        'DistributionSystem' => zero,
        'HeatingSystemFuel[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'HeatingCapacity' => zero_or_one,
        'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
      },

      # [CoolingSystem]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        'CoolingSystemType[text()="central air conditioner" or text()="room air conditioner" or text()="evaporative cooler" or text()="chiller" or text()="cooling tower"]' => one, # See [CoolingType=CentralAC] or [CoolingType=RoomAC] or [CoolingType=EvapCooler] or [CoolingType=SharedChiller] or [CoolingType=SharedCoolingTower]
        'CoolingSystemFuel[text()="electricity"]' => one,
        'FractionCoolLoadServed' => one,
      },

      ## [CoolingType=CentralAC]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioner"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'CoolingCapacity' => one,
        'CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"]' => zero_or_one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'SensibleHeatFraction' => zero_or_one,
      },

      ## [CoolingType=RoomAC]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => {
        'DistributionSystem' => zero,
        'CoolingCapacity' => one,
        'AnnualCoolingEfficiency[Units="EER"]/Value' => one,
        'SensibleHeatFraction' => zero_or_one,
      },

      ## [CoolingType=EvapCooler]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="evaporative cooler"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => zero_or_more, # See [HVACDistribution]
        'DistributionSystem' => zero_or_one,
        'CoolingCapacity' => zero,
      },

      ## [CoolingType=SharedChiller]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="chiller"]' => {
        '../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]' => one,
        '../../HVACDistribution[DistributionSystemType/HydronicDistribution[HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]] | DistributionSystemType/HydronicAndAirDistribution[HydronicAndAirDistributionType[text()="fan coil" or text()="water loop heat pump"]]]' => one, # See [HVACDistribution]
        '../../HVACDistribution/extension/SharedLoopWatts' => one,
        'DistributionSystem' => one,
        'IsSharedSystem[text()="true"]' => one,
        'NumberofUnitsServed' => one,
        'CoolingCapacity' => one,
        'AnnualCoolingEfficiency[Units="kW/ton"]/Value' => one,
      },

      ## [CoolingType=SharedCoolingTower]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="cooling tower"]' => {
        '../../../../BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]' => one,
        '../../HVACDistribution[DistributionSystemType/HydronicAndAirDistribution[HydronicAndAirDistributionType[text()="water loop heat pump"]]]' => one, # See [HVACDistribution]
        '../../HVACDistribution/extension/SharedLoopWatts' => one,
        'DistributionSystem' => one,
        'IsSharedSystem[text()="true"]' => one,
        'NumberofUnitsServed' => one,
      },

      # [HeatPump]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        '../../HVACControl' => one, # See [HVACControl]
        'HeatPumpType[text()="air-to-air" or text()="mini-split" or text()="ground-to-air" or text()="water-loop-to-air"]' => one, # See [HeatPumpType=ASHP] or [HeatPumpType=MSHP] or [HeatPumpType=GSHP] or [HeatPumpType=WLHP]
        'HeatPumpFuel[text()="electricity"]' => one,
        'CoolingSensibleHeatFraction' => zero_or_one,
        'BackupSystemFuel[text()="electricity" or text()="natural gas" or text()="fuel oil" or text()="propane" or text()="wood" or text()="wood pellets"]' => zero_or_one, # See [HeatPumpBackup]
      },

      ## [HeatPumpType=ASHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'HeatingCapacity' => one,
        'HeatingCapacity17F' => zero_or_one,
        'CoolingCapacity' => one,
        'CompressorType[text()="single stage" or text()="two stage" or text()="variable speed"]' => zero_or_one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="HSPF"]/Value' => one,
        'FractionHeatLoadServed' => one,
        'FractionCoolLoadServed' => one,
      },

      ## [HeatPumpType=MSHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="mini-split"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => zero_or_more, # See [HVACDistribution]
        'DistributionSystem' => zero_or_one,
        'HeatingCapacity' => one,
        'HeatingCapacity17F' => zero_or_one,
        'CoolingCapacity' => one,
        'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="HSPF"]/Value' => one,
        'FractionHeatLoadServed' => one,
        'FractionCoolLoadServed' => one,
      },

      ## [HeatPumpType=GSHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => {
        '../../HVACDistribution[DistributionSystemType/AirDistribution | DistributionSystemType[Other="DSE"]]' => one_or_more, # See [HVACDistribution]
        'DistributionSystem' => one,
        'HeatingCapacity' => one,
        'CoolingCapacity' => one,
        'BackupHeatingSwitchoverTemperature' => zero,
        'AnnualCoolingEfficiency[Units="EER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="COP"]/Value' => one,
        'FractionHeatLoadServed' => one,
        'FractionCoolLoadServed' => one,
      },

      ## [HeatPumpType=WLHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="water-loop-to-air"]' => {
        '../HeatingSystem[IsSharedSystem="true"] | ../CoolingSystem[IsSharedSystem="true"]' => one_or_more,
        '../../HVACDistribution[DistributionSystemType/HydronicAndAirDistribution[HydronicAndAirDistributionType[text()="water loop heat pump"]]]' => one, # See [HVACDistribution]
        'DistributionSystem' => one,
        'CoolingCapacity' => one,
        'AnnualCoolingEfficiency[Units="EER"]/Value' => one,
        'AnnualHeatingEfficiency[Units="COP"]/Value' => one,
        'FractionHeatLoadServed' => zero, # Specified by shared boiler
        'FractionCoolLoadServed' => zero, # Specified by shared chiller or cooling tower
      },

      ## [HeatPumpBackup]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[BackupSystemFuel]' => {
        'BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value' => one,
        'BackupHeatingCapacity' => one, # Use -1 for autosizing
        'BackupHeatingSwitchoverTemperature' => zero_or_one, # Use if dual-fuel heat pump
      },

      # [HVACControl]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'ControlType[text()="manual thermostat" or text()="programmable thermostat"]' => one,
      },

      # [HVACDistribution]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'DistributionSystemType[AirDistribution | HydronicDistribution | HydronicAndAirDistribution | Other[text()="DSE"]]' => one, # See [HVACDistType=Air] or [HVACDistType=Hydronic] or [HVACDistType=HydronicAndAir] or [HVACDistType=DSE]
      },

      ## [HVACDistType=Air]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => {
        '../../ConditionedFloorAreaServed' => one,
        'DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value | extension/DuctLeakageTestingExemption[text()="true"] | DuctLeakageMeasurement/DuctLeakage[Units="CFM25" and TotalOrToOutside="total"]/Value' => one,
        'DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value | extension/DuctLeakageTestingExemption[text()="true"] | DuctLeakageMeasurement/DuctLeakage[Units="CFM25" and TotalOrToOutside="total"]/Value' => zero_or_one,
        'Ducts[DuctType="supply"]' => zero_or_more, # See [AirDuct]
        'Ducts[DuctType="return"]' => zero_or_more, # See [AirDuct]
      },

      ## [AirDuct]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts[DuctType="supply" or DuctType="return"]' => {
        'DuctInsulationRValue' => one,
        'DuctLocation[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="crawlspace - vented" or text()="crawlspace - unvented" or text()="attic - vented" or text()="attic - unvented" or text()="garage" or text()="exterior wall" or text()="under slab" or text()="roof deck" or text()="outside" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'DuctSurfaceArea' => one,
      },

      ## [HVACDistType=Hydronic]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution' => {
        'HydronicDistributionType[text()="radiator" or text()="baseboard" or text()="radiant floor" or text()="radiant ceiling"]' => one,
      },

      ## [HVACDistType=HydronicAndAir]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicAndAirDistribution' => {
        'HydronicAndAirDistributionType[text()="fan coil" or text()="water loop heat pump"]' => one, # See [HydronicAndAirType=FanCoil] or [HydronicAndAirType=WLHP]
        '../../ConditionedFloorAreaServed' => one,
        'DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[(Units="CFM25" or Units="Percent") and TotalOrToOutside="to outside"]/Value' => zero_or_one,
        'DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[(Units="CFM25" or Units="Percent") and TotalOrToOutside="to outside"]/Value' => zero_or_one,
        'Ducts[DuctType="supply"]' => zero_or_more, # See [HydronicAndAirDuct]
        'Ducts[DuctType="return"]' => zero_or_more, # See [HydronicAndAirDuct]
        'NumberofReturnRegisters' => zero_or_one,
      },

      ## [HydronicAndAirType=FanCoil]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicAndAirDistribution[HydronicAndAirDistributionType[text()="fan coil"]]' => {
        'extension/FanCoilWatts' => one,
      },

      ## [HydronicAndAirType=WLHP]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicAndAirDistribution[HydronicAndAirDistributionType[text()="water loop heat pump"]]' => {
        '../../../HVACPlant/HeatPump[HeatPumpType[text()="water-loop-to-air"]]' => one,
      },

      ## [HydronicAndAirDuct]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicAndAirDistribution/Ducts[DuctType="supply" or DuctType="return"]' => {
        'DuctInsulationRValue' => one,
        'DuctSurfaceArea' => one,
      },

      ## [HVACDistType=DSE]
      '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other="DSE"]]' => {
        'AnnualHeatingDistributionSystemEfficiency | AnnualCoolingDistributionSystemEfficiency' => one_or_more,
      },

      # [MechanicalVentilation]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'FanType[text()="energy recovery ventilator" or text()="heat recovery ventilator" or text()="exhaust only" or text()="supply only" or text()="balanced" or text()="central fan integrated supply"]' => one, # See [MechVentType=HRV] or [MechVentType=ERV] or [MechVentType=CFIS]
        'TestedFlowRate' => zero_or_one,
        'HoursInOperation' => one,
        'FanPower' => zero_or_one,
      },

      ## [MechVentType=HRV]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="heat recovery ventilator"]' => {
        'SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency' => one,
      },

      ## [MechVentType=ERV]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="energy recovery ventilator"]' => {
        'TotalRecoveryEfficiency | AdjustedTotalRecoveryEfficiency' => one,
        'SensibleRecoveryEfficiency | AdjustedSensibleRecoveryEfficiency' => one,
      },

      ## [MechVentType=CFIS]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="central fan integrated supply"]' => {
        'AttachedToHVACDistributionSystem' => one,
      },

      # [WholeHouseFan]
      '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction="true"]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'RatedFlowRate' => one,
        'FanPower' => one,
      },

      # [WaterHeatingSystem]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => {
        '../HotWaterDistribution' => one, # See [HotWaterDistribution]
        '../WaterFixture' => one_or_more, # See [WaterFixture]
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsSharedSystem' => one, # See [WaterHeatingSystem=Shared]
        'WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater" or text()="space-heating boiler with storage tank" or text()="space-heating boiler with tankless coil"]' => one, # See [WHType=Tank] or [WHType=Tankless] or [WHType=HeatPump] or [WHType=Indirect] or [WHType=CombiTankless]
        'Location[text()="living space" or text()="basement - unconditioned" or text()="basement - conditioned" or text()="attic - unvented" or text()="attic - vented" or text()="garage" or text()="crawlspace - unvented" or text()="crawlspace - vented" or text()="other exterior" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'FractionDHWLoadServed' => one,
        'UsesDesuperheater' => zero_or_one, # See [Desuperheater]
      },

      ## [WaterHeatingSystem=Shared]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true"]' => {
        'NumberofUnitsServed' => one,
      },

      ## [WHType=Tank]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater"]' => {
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one, # If not electricity, see [WHType=FuelTank]
        'TankVolume' => one,
        'HeatingCapacity' => zero_or_one,
        'EnergyFactor | UniformEnergyFactor' => one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one,
      },

      ## [WHType=FuelTank]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => {
        'RecoveryEfficiency' => one,
      },

      ## [WHType=Tankless]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="instantaneous water heater"]' => {
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'EnergyFactor | UniformEnergyFactor' => one,
      },

      ## [WHType=HeatPump]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="heat pump water heater"]' => {
        'FuelType[text()="electricity"]' => one,
        'TankVolume' => one,
        'EnergyFactor | UniformEnergyFactor' => one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one,
      },

      ## [WHType=Indirect]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="space-heating boiler with storage tank"]' => {
        'RelatedHVACSystem' => one, # HeatingSystem (boiler)
        'TankVolume' => one,
        'WaterHeaterInsulation/Jacket/JacketRValue' => zero_or_one,
        'StandbyLoss' => zero_or_one, # deg-F/h, refer to https://www.ahridirectory.org/NewSearch?programId=28&searchTypeId=3
      },

      ## [WHType=CombiTankless]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="space-heating boiler with tankless coil"]' => {
        'RelatedHVACSystem' => one, # HeatingSystem (boiler)
      },

      ## [Desuperheater]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[UsesDesuperheater="true"]' => {
        'WaterHeaterType[text()="storage water heater" or text()="instantaneous water heater" or text()="heat pump water heater"]' => one, # Desuperheater is supported with storage water heater, tankless water heater and heat pump water heater
        'RelatedHVACSystem' => one, # HeatPump or CoolingSystem
      },

      # [HotWaterDistribution]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'SystemType/Standard | SystemType/Recirculation' => one, # See [HWDistType=Standard] or [HWDistType=Recirculation]
        'PipeInsulation/PipeRValue' => one,
        'DrainWaterHeatRecovery' => zero_or_one, # See [DrainWaterHeatRecovery]
        'extension/SharedRecirculation' => zero_or_one, # See [SharedRecirculation]
      },

      ## [HWDistType=Standard]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Standard' => {
        'PipingLength' => one,
      },

      ## [HWDistType=Recirculation]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Recirculation' => {
        'ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="temperature" or text()="timer" or text()="no control"]' => one,
        'RecirculationPipingLoopLength' => one,
        'BranchPipingLoopLength' => one,
        'PumpPower' => one,
      },

      ## [DrainWaterHeatRecovery]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/DrainWaterHeatRecovery' => {
        'FacilitiesConnected' => one,
        'EqualFlow' => one,
        'Efficiency' => one,
      },

      ## [SharedRecirculation]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution[extension/SharedRecirculation]' => {
        'extension/SharedRecirculation/NumberofUnitsServed' => one,
        'extension/SharedRecirculation/PumpPower' => zero_or_one,
        'extension/SharedRecirculation/ControlType[text()="manual demand control" or text()="presence sensor demand control" or text()="timer" or text()="no control"]' => one,
      },
      # [WaterFixture]
      '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => {
        '../HotWaterDistribution' => one, # See [HotWaterDistribution]
        'SystemIdentifier' => one, # Required by HPXML schema
        'WaterFixtureType[text()="shower head" or text()="faucet"]' => one, # Required by HPXML schema
        'LowFlow' => one,
      },

      # [SolarThermalSystem]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'SystemType[text()="hot water"]' => one,
        'CollectorArea | SolarFraction' => one, # See [SolarThermal=Detailed] or [SolarThermal=Simple]
      },

      ## [SolarThermal=Detailed]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem[CollectorArea]' => {
        'CollectorLoopType[text()="liquid indirect" or text()="liquid direct" or text()="passive thermosyphon"]' => one,
        'CollectorType[text()="single glazing black" or text()="double glazing black" or text()="evacuated tube" or text()="integrated collector storage"]' => one,
        'CollectorAzimuth' => one,
        'CollectorTilt' => one,
        'CollectorRatedOpticalEfficiency' => one,
        'CollectorRatedThermalLosses' => one,
        'StorageVolume' => one,
        'ConnectedTo' => one, # WaterHeatingSystem (any type but space-heating boiler)
      },

      ## [SolarThermal=Simple]
      '/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem[SolarFraction]' => {
        'ConnectedTo' => zero_or_one, # WaterHeatingSystem (any type)
      },

      # [PVSystem]
      '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsSharedSystem' => one, # See [PVSystem=Shared]
        'Location[text()="ground" or text()="roof"]' => one,
        'ModuleType[text()="standard" or text()="premium" or text()="thin film"]' => one,
        'Tracking[text()="fixed" or text()="1-axis" or text()="1-axis backtracked" or text()="2-axis"]' => one,
        'ArrayAzimuth' => one,
        'ArrayTilt' => one,
        'MaxPowerOutput' => one,
        'InverterEfficiency' => one, # PVWatts default is 0.96
        'SystemLossesFraction' => one, # PVWatts default is 0.14
      },

      ## [PVSystem=Shared]
      '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem[IsSharedSystem="true"]' => {
        'extension/NumberofBedroomsServed' => one,
      },

      # [ClothesWasher]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => {
        '../../Systems/WaterHeating/HotWaterDistribution' => one, # See [HotWaterDistribution]
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsSharedAppliance' => one, # See [ClothesWasher=Shared]
        'Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'ModifiedEnergyFactor | IntegratedModifiedEnergyFactor' => one,
        'RatedAnnualkWh' => one,
        'LabelElectricRate' => one,
        'LabelGasRate' => one,
        'LabelAnnualGasCost' => one,
        'LabelUsage' => one,
        'Capacity' => one,
      },

      ## [ClothesWasher=Shared]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher[IsSharedAppliance="true"]' => {
        '../../Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true" and number(FractionDHWLoadServed)=0]' => one_or_more,
        'AttachedToWaterHeatingSystem' => one,
        'NumberofUnits' => one,
        'NumberofUnitsServed' => one,
      },

      # [ClothesDryer]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsSharedAppliance' => one, # See [ClothesDryer=Shared]
        'Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'EnergyFactor | CombinedEnergyFactor' => one,
        'ControlType[text()="timer" or text()="moisture"]' => one,
      },

      ## [ClothesDryer=Shared]
      '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer[IsSharedAppliance="true"]' => {
        'NumberofUnits' => one,
        'NumberofUnitsServed' => one,
      },

      # [Dishwasher]
      '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => {
        '../../Systems/WaterHeating/HotWaterDistribution' => one, # See [HotWaterDistribution]
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsSharedAppliance' => one, # See [Dishwasher=Shared]
        'Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'RatedAnnualkWh | EnergyFactor' => one,
        'LabelElectricRate' => one,
        'LabelGasRate' => one,
        'LabelAnnualGasCost' => one,
        'LabelUsage' => one,
        'PlaceSettingCapacity' => one,
      },

      ## [Dishwasher=Shared]
      '/HPXML/Building/BuildingDetails/Appliances/Dishwasher[IsSharedAppliance="true"]' => {
        '../../Systems/WaterHeating/WaterHeatingSystem[IsSharedSystem="true" and number(FractionDHWLoadServed)=0]' => one_or_more,
        'AttachedToWaterHeatingSystem' => one,
      },

      # [Refrigerator]
      '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'RatedAnnualkWh' => one,
      },

      # [CookingRange]
      '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => {
        '../Oven' => one, # See [Oven]
        'SystemIdentifier' => one, # Required by HPXML schema
        'Location[text()="living space" or text()="basement - conditioned" or text()="basement - unconditioned" or text()="garage" or text()="other housing unit" or text()="other heated space" or text()="other multifamily buffer space" or text()="other non-freezing space"]' => one,
        'FuelType[text()="natural gas" or text()="fuel oil" or text()="propane" or text()="electricity" or text()="wood" or text()="wood pellets"]' => one,
        'IsInduction' => one,
      },

      # [Oven]
      '/HPXML/Building/BuildingDetails/Appliances/Oven' => {
        '../CookingRange' => one, # See [CookingRange]
        'SystemIdentifier' => one, # Required by HPXML schema
        'IsConvection' => one,
      },

      # [Lighting]
      '/HPXML/Building/BuildingDetails/Lighting' => {
        'LightingGroup[LightingType/CompactFluorescent and Location="interior"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/CompactFluorescent and Location="exterior"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/CompactFluorescent and Location="garage"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/FluorescentTube and Location="interior"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/FluorescentTube and Location="exterior"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/FluorescentTube and Location="garage"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/LightEmittingDiode and Location="interior"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/LightEmittingDiode and Location="exterior"]' => one, # See [LightingGroup]
        'LightingGroup[LightingType/LightEmittingDiode and Location="garage"]' => one, # See [LightingGroup]
      },

      ## [LightingGroup]
      '/HPXML/Building/BuildingDetails/Lighting/LightingGroup[LightingType[LightEmittingDiode | CompactFluorescent | FluorescentTube] and Location[text()="interior" or text()="exterior" or text()="garage"]]' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'FractionofUnitsInLocation' => one,
      },

      # [CeilingFan]
      '/HPXML/Building/BuildingDetails/Lighting/CeilingFan' => {
        'SystemIdentifier' => one, # Required by HPXML schema
        'Airflow[FanSpeed="medium"]/Efficiency' => one,
        'Quantity' => one,
      },

    }

    errors = []
    requirements.each do |parent, requirement|
      if parent.nil? # Unconditional
        requirement.each do |child, expected_sizes|
          next if expected_sizes.nil?

          xpath = combine_into_xpath(parent, child)
          begin
            actual_size = hpxml_doc.xpath(child).length
          rescue
            fail "Invalid xpath: #{child}"
          end
          check_number_of_elements(actual_size, expected_sizes, xpath, errors)
        end
      else # Conditional based on parent element existence
        begin
          next if hpxml_doc.xpath(parent).empty? # Skip if parent element doesn't exist
        rescue
          fail "Invalid xpath: #{parent}"
        end

        hpxml_doc.xpath(parent).each do |parent_element|
          requirement.each do |child, expected_sizes|
            next if expected_sizes.nil?

            xpath = combine_into_xpath(parent, child)
            begin
              actual_size = parent_element.xpath(update_leading_predicates(child)).length
            rescue
              fail "Invalid xpath: #{update_leading_predicates(child)}"
            end
            check_number_of_elements(actual_size, expected_sizes, xpath, errors)
          end
        end
      end
    end

    return errors
  end

  def self.check_number_of_elements(actual_size, expected_sizes, xpath, errors)
    if expected_sizes.size > 0
      return if expected_sizes.include?(actual_size)

      errors << "Expected #{expected_sizes} element(s) but found #{actual_size} element(s) for xpath: #{xpath}"
    else
      return if actual_size > 0

      errors << "Expected 1 or more element(s) but found 0 elements for xpath: #{xpath}"
    end
  end

  def self.combine_into_xpath(parent, child)
    if parent.nil?
      return child
    end

    return [parent, child].join(': ')
  end

  def self.update_leading_predicates(str)
    # Examples:
    #   "[foo='1' or foo='2']" => "(self::node()[foo='1' or foo='2'])"
    #   "[foo] | bar" => "(self::node()[foo]) | bar"

    add_str = '(self::node()'

    # First check beginning of str
    if str[0] == '['
      str = add_str + str
      # Find closing bracket match for ending parenthesis
      count = 0
      for i in add_str.size..str.size - 1
        if str[i] == '['
          count += 1
        elsif str[i] == ']'
          count -= 1
        end
        if count == 0
          str = str[0..i] + ')' + str[i + 1..str.size]
          break
        end
      end
    end

    return str
  end
end
