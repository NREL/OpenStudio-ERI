class EnergyRatingIndex301Validator

  def self.run_validator(hpxml_doc, errors)
  
    # Every file must have this number of elements
    unconditional_counts = {
            '//Building' => [1],
            '//Building/BuildingDetails/BuildingSummary/Site/FuelTypesAvailable' => [1],
            '//Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure="ACHnatural"]' => [1], # TODO: Allow ACH50, ELA, and/or SLA?
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem|//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [0,1],
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem|//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [0,1],
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HVACControl/ControlType' => [0,1],
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => [0,1],
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => [0,1],
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => [1],
            '//Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => [0,1],
            '//Building/BuildingDetails/Appliances/ClothesWasher' => [1],
            '//Building/BuildingDetails/Appliances/ClothesDryer' => [1],
            '//Building/BuildingDetails/Appliances/Dishwasher' => [1],
            '//Building/BuildingDetails/Appliances/Refrigerator' => [1],
            '//Building/BuildingDetails/Appliances/CookingRange' => [1],
            '//Building/BuildingDetails/Appliances/Oven' => [1],
            '//Building/BuildingDetails/Lighting/LightingFractions' => [1],
    }
    
    # Every file must have 1 or more of these elements
    unconditional_has = [
            '//Building/BuildingDetails/BuildingSummary/Site/AzimuthOfFrontOfHome',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType',
            '//Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year="2006"]',
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics',
            '//Building/BuildingDetails/Enclosure/Foundations',
            '//Building/BuildingDetails/Enclosure/Walls',
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="shower head"]',
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="faucet"]',
    ]
    
    # If the key exists, the file must have 1 (or more) of these child elements
    conditional_has = {
            # Attics
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic' => [
                '[AtticType="unvented attic" or AtticType="vented attic" or AtticType="flat roof" or AtticType="cathedral ceiling" or AtticType="cape cod"]'
            ],
            # Attic Roofs
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Roofs/Roof' => [
                'Area',
                'RoofColor',
                'Rafters[Material="wood"]',
                'Rafters/FramingFactor',
                'Pitch',
                'RadiantBarrier',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
            ],
            # Attic Roofs Insulation Layer
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Roofs/Roof/Insulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # Attic Floors (everything but cathedral ceiling and flat roof)
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType="vented attic" or AtticType="unvented attic" or AtticType="cape cod"]/Floors/Floor' => [
                'Area',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'Joists[Material="wood"]',
                'Joists/FramingFactor',
                'extension[AdjacentTo="living space" or AdjacentTo="garage"]',
            ],
            # Attic Floors Insulation Layer
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Floors/Floor/Insulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # Attic Walls
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Walls/Wall' => [
                'AtticWallType', # FIXME: Shouldn't be required in HPXML schema
                'Area',
                '[Siding="stucco" or Siding="brick veneer" or Siding="wood siding" or Siding="aluminum siding" or Siding="vinyl siding" or Siding="fiber cement siding"]',
                'Color',
                'extension/WallType/WoodStud',
                'extension[AdjacentTo="ambient" or AdjacentTo="garage" or AdjacentTo="living space" or AdjacentTo="unvented attic" or AdjacentTo="vented attic" or AdjacentTo="cape cod"]',
            ],
            # Attic Walls Insulation Layer
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Walls/Wall/Insulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # Attic Walls WoodStud
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Walls/Wall[extension/WallType/WoodStud]' => [
                'Studs[Material="wood"]',
                'Studs/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
            ],
            # Foundation
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation' => [
                '[FoundationType/Basement|FoundationType/Crawlspace|FoundationType/SlabOnGrade|FoundationType/Ambient]',
            ],
            # Basement Foundation
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]' => [
                'FoundationType/Basement/Conditioned',
                'FrameFloor',
                'FoundationWall',
                'Slab',
            ],
            # Crawlspace Foundation
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace]' => [
                'FoundationType/Crawlspace/Vented',
                'FrameFloor',
                'FoundationWall',
            ],
            # SlabOnGrade Foundation
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/SlabOnGrade]' => [
                'Slab',
            ],
            # Ambient Foundation
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Ambient]' => [
                'FrameFloor',
            ],
            # FrameFloor
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FrameFloor' => [
                'Area',
                'FloorJoists[Material="wood"]',
                'FloorJoists/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension/CarpetFraction',
                'extension/CarpetRValue',
                'extension[AdjacentTo="living space"]',
            ],
            # FrameFloor Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FrameFloor/Insulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # FoundationWall
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationWall' => [
                'Area',
                'Height',
                'BelowGradeDepth',
                'InteriorStuds[Material="wood"]',
                'InteriorStuds/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension[AdjacentTo="ground" or AdjacentTo="unconditioned basement" or AdjacentTo="conditioned basement" or AdjacentTo="crawlspace"]',
            ],
            # FoundationWall Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationWall/Insulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # Basement FoundationWall Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/FoundationWall/Insulation/Layer[InstallationType="continuous"]' => [
                'extension/InsulationHeight',
            ],
            # Slab
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab' => [
                'Area',
                'PerimeterInsulationDepth',
                'PerimeterInsulation/Layer[InstallationType="continuous"]',
                'UnderSlabInsulationWidth',
                'UnderSlabInsulation/Layer[InstallationType="continuous"]',
                'extension/CarpetFraction',
                'extension/CarpetRValue',
            ],
            # Basement Slab
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/Slab' => [
                'DepthBelowGrade',
            ],
            # Slab Perimeter Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab/PerimeterInsulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # Slab UnderSlab Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab/UnderSlabInsulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # Basement Slab Perimeter Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/Slab/PerimeterInsulation/Layer' => [
                '[NominalRValue=0]',
            ],
            # Basement Slab UnderSlab Insulation Layer
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/Slab/UnderSlabInsulation/Layer' => [
                '[NominalRValue=0]',
            ],
            # Wall
            '//Building/BuildingDetails/Enclosure/Walls/Wall' => [
                'Area',
                'extension[InteriorAdjacentTo="living space" or InteriorAdjacentTo="garage" or InteriorAdjacentTo="vented attic" or InteriorAdjacentTo="unvented attic" or InteriorAdjacentTo="cape cod"]',
                'extension[ExteriorAdjacentTo="ambient" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="unvented attic" or ExteriorAdjacentTo="vented attic" or ExteriorAdjacentTo="cape cod"]',
                'WallType/WoodStud',
                '[Siding="stucco" or Siding="brick veneer" or Siding="wood siding" or Siding="aluminum siding" or Siding="vinyl siding" or Siding="fiber cement siding"]',
                'Color',
            ],
            # Wall Insulation Layer
            '//Building/BuildingDetails/Enclosure/Walls/Wall/Insulation/Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            # WoodStud Wall
            '//Building/BuildingDetails/Enclosure/Walls/Wall[WallType/WoodStud]' => [
                'Studs[Material="wood"]',
                'Studs/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
            ],
            # Floors
            '//Building/BuildingDetails/Enclosure/extension/Floors/Floor' => [
                'Area',
                'FloorJoists[Material="wood"]',
                'FloorJoists/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'CarpetFraction',
                'CarpetRValue',
                '[InteriorAdjacentTo="living space"]',
                '[ExteriorAdjacentTo="garage"]',
            ],
            # Window
            '//Building/BuildingDetails/Enclosure/Windows/Window' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'AttachedToWall',
            ],
            # Skylight
            '//Building/BuildingDetails/Enclosure/Skylights/Skylight' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'Pitch',
                'AttachedToRoof',
            ],
            # Door
            '//Building/BuildingDetails/Enclosure/Doors/Door' => [
                'AttachedToWall',
                'Area',
                'Azimuth',
                'RValue',
            ],
            # HeatingSystem
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => [
                'HeatingSystemType[Furnace|Boiler|ElectricResistance]',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempHeatingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
                '[FractionHeatLoadServed=1.0]',
            ],
            # HeatingSystem (Furnace/Boiler)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace or HeatingSystemType/Boiler]' => [
                'AnnualHeatingEfficiency[Units="AFUE"]/Value',
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]',
            ],
            # HeatingSystem (ElectricResistance)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => [
                'AnnualHeatingEfficiency[Units="Percent"]/Value',
                '[HeatingSystemFuel="electricity"]',
            ],
            # CoolingSystem
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => [
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempCoolingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
                '[CoolingSystemType="central air conditioning" or CoolingSystemType="room air conditioner"]',
                '[FractionCoolLoadServed=1.0]',
            ],
            # CoolingSystem (CentralAC)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioning"]' => [
                'AnnualCoolingEfficiency[Units="SEER"]/Value',
                '[CoolingSystemFuel="electricity"]',
                'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]',
            ],
            # CoolingSystem (RoomAC)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => [
                'AnnualCoolingEfficiency[Units="EER"]/Value',
                '[CoolingSystemFuel="electricity"]',
            ],
            # HeatPump
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempHeatingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempCoolingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
                '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]',
                '[FractionHeatLoadServed=1.0]',
                '[FractionCoolLoadServed=1.0]',
                'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]',
            ],
            # HeatPump (AirSource/MiniSplit)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air" or HeatPumpType="mini-split"]' => [
                'AnnualCoolEfficiency[Units="SEER"]/Value',
                'AnnualHeatEfficiency[Units="HSPF"]/Value',
            ],
            # HeatPump (GroundSource)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => [
                'AnnualCoolEfficiency[Units="EER"]/Value',
                'AnnualHeatEfficiency[Units="COP"]/Value',
            ],
            # WaterHeatingSystem
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => [
                '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater"]',
                'HeatingCapacity',
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
            ],
            # Tank WaterHeatingSystem
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" or WaterHeaterType="heat pump water heater"]' => [
                'TankVolume',
            ],
            # WaterHeatingSystem (FuelStorage)
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => [
                'RecoveryEfficiency',
            ],
            # HotWaterDistribution
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => [
                'SystemType',
                'PipeInsulation/PipeRValue',
                'PipeInsulation/FractionPipeInsulation',
                'extension/LongestPipeLength',
            ],
            # WaterFixture
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => [
                'FlowRate'
            ],
            # VentilationFan
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan' => [
                'UsedForWholeBuildingVentilation',
                'FanType',
                'HoursInOperation',
                'FanPower',
                'RatedFlowRate',
            ],
            # ERV
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="energy recovery ventilator"]' => [
                'TotalRecoveryEfficiency',
                'SensibleRecoveryEfficiency'
            ],
            # HRV
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="heat recovery ventilator"]' => [
                'SensibleRecoveryEfficiency',
            ],
            # PV
            '//Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => [
                'ArrayAzimuth',
                'ArrayTilt',
                'InverterEfficiency',
                'MaxPowerOutput',
            ],
            # ClothesWasher
            '//Building/BuildingDetails/Appliances/ClothesWasher' => [
                'ModifiedEnergyFactor',
                'extension/EnergyRating',
                'extension/ElectricRate',
                'extension/GasRate',
                'extension/AnnualGasCost',
                'extension/Capacity',
            ],
            # ClothesDryer
            '//Building/BuildingDetails/Appliances/ClothesDryer' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                'extension/EfficiencyFactor',
                'extension/HasTimerControl',
            ],
            # Dishwasher
            '//Building/BuildingDetails/Appliances/Dishwasher' => [
                '[EnergyFactor|RatedAnnualkWh]',
                'extension/Capacity',
            ],
            # Refrigerator
            '//Building/BuildingDetails/Appliances/Refrigerator' => [
                'RatedAnnualkWh',
            ],
            # CookingRange
            '//Building/BuildingDetails/Appliances/CookingRange' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                'extension/IsInduction',
            ],
            # Oven
            '//Building/BuildingDetails/Appliances/Oven' => [
                'FuelType',
                'extension/IsConvection',
            ],
            # Lighting
            '//Building/BuildingDetails/Lighting/LightingFractions' => [
                'extension/QualifyingLightFixturesInterior',
                'extension/QualifyingLightFixturesExterior',
                'extension/QualifyingLightFixturesGarage',
            ],
    }
    
    # Check each unconditional "count"
    unconditional_counts.each do |p, n|
      elements = hpxml_doc.elements.to_a(p)
      next if n.include?(elements.size)
      errors << "Expected #{n.to_s} element(s) but found #{elements.size.to_s} element(s) for xpath: #{p}"
    end
    
    # Check each unconditional "has"
    unconditional_has.each do |e|
      next if not hpxml_doc.elements[e].nil?
      errors << "Cannot find xpath: #{e}"
    end
    
    # Check each conditional "has"
    conditional_has.keys.each do |p|
      next if hpxml_doc.elements[p].nil?
      # Check each child element
      hpxml_doc.elements.each(p) do |c_el|
        conditional_has[p].each do |c|
          next if not c_el.elements[c].nil?
          xpath = [p, c].join('/')
          if c.start_with?("[")
            xpath = [p, c].join('')
          elsif c.start_with?("//")
            xpath = c
          end
          errors << "Has #{p} but cannot find xpath: #{xpath}"
        end
      end
    end
    
  end
  
end
  