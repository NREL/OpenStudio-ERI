class EnergyRatingIndex301Validator

  def self.run_validator(hpxml_doc, errors)
  
    # Every file must have this number of elements
    unconditional_counts = {
            '//Building' => [1],
            '//Building/BuildingDetails/BuildingSummary/extension/HasNaturalGasAccessOrFuelDelivery' => [1],
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
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Roofs',
            '//Building/BuildingDetails/Enclosure/Foundations',
            '//Building/BuildingDetails/Enclosure/Walls',
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="shower head"]',
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="faucet"]',
    ]
    
    # If the key exists, the file must have 1 (or more) of these child elements
    conditional_has = {
            # Roofs
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Roofs/Roof' => [
                'RoofArea',
                'RoofColor',
                'RadiantBarrier',
            ],
            # Attics
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic' => [
                #'AtticFloorInsulation[AssemblyEffectiveRValue and InsulationGrade]',
                #'AtticRoofInsulation[AssemblyEffectiveRValue and InsulationGrade]',
                'Area',
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
                'FloorJoists/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension/CarpetFraction',
                'extension/CarpetRValue',
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
                'AdjacentTo',
                'InteriorStuds/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
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
            # Wall
            '//Building/BuildingDetails/Enclosure/Walls/Wall' => [
                'Area',
                'InteriorAdjacentTo',
                'ExteriorAdjacentTo',
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
                'Studs/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
            ],
            # Window
            '//Building/BuildingDetails/Enclosure/Windows/Window' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'AttachedToWall',
                #Quantity, # FIXME: Should we require/use?
            ],
            # Skylight
            '//Building/BuildingDetails/Enclosure/Skylights/Skylight' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'Pitch',
                'AttachedToRoof',
                #Quantity, # FIXME: Should we require/use?
            ],
            # Door
            '//Building/BuildingDetails/Enclosure/Doors/Door' => [
                'AttachedToWall',
                'Area',
                'Azimuth',
                'RValue',
                #Quantity, # FIXME: Should we require/use?
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
  