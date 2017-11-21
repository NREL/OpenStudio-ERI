class EnergyRatingIndex301Validator

  # TODO: Combine has/counts into, e.g., {foo=>[], foo=>[0,1]};
  # TODO: Separate out OS/E+ limitations from ERI Use Case

  def self.run_validator(hpxml_doc)
  
    errors = []
  
    # Every file must have this number of elements
    unconditional_counts = {
            '//Building' => [1],
            '//BuildingSummary/Site' => [1],
            '//BuildingSummary/BuildingConstruction' => [1],
            '//ClimateandRiskZones' => [1],
            '//AirInfiltration/' => [1],
            '//HeatingSystem | //HeatPump' => [0,1],
            '//CoolingSystem | //HeatPump' => [0,1],
            '//AirDistribution' => [0,1],
            '//HydronicDistribution' => [0,1],
            '//HVACControl' => [0,1],
            '//VentilationFan[UsedForWholeBuildingVentilation="true"]' => [0,1],
            '//WaterHeatingSystem' => [1],
            '//HotWaterDistribution' => [1],
            '//PVSystem' => [0,1],
            '//ClothesWasher' => [1],
            '//ClothesDryer' => [1],
            '//Dishwasher' => [1],
            '//Refrigerator' => [1],
            '//CookingRange' => [1],
            '//Lighting' => [1],
    }
    
    # Every file must have 1 (or more) of these elements
    unconditional_has = [
            '//Enclosure/AtticAndRoof/Attics',
            '//Enclosure/Foundations',
            '//Enclosure/Walls',
            '//WaterFixture[WaterFixtureType="shower head" or WaterFixtureType="faucet"]',
    ]
    
    # If the key exists, the file must have 1 (or more) of these child elements
    conditional_has = {
    
            ## Site
            '//BuildingSummary/Site' => [
                'AzimuthOfFrontOfHome',
                'FuelTypesAvailable',
            ],
            
            ## BuildingConstruction
            '//BuildingSummary/BuildingConstruction' => [
                'ResidentialFacilityType',
                'NumberofConditionedFloors',
                'NumberofConditionedFloorsAboveGrade',
                'NumberofBedrooms',
                'NumberofBathrooms',
                'ConditionedFloorArea',
                'ConditionedBuildingVolume',
                'GaragePresent',
            ],
            
            ## Climate
            '//ClimateandRiskZones/' => [
                'ClimateZoneIECC[Year="2006"]',
                'WeatherStation/extension/EPWFileName',
            ],
    
            ## AirInfiltration
            '//AirInfiltration' => [
                'AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure="ACHnatural"]/AirLeakage', # TODO: Allow ACH50, ELA, and/or SLA?
            ],
            
            ## Attic
            '//Attic' => [
                '[AtticType="unvented attic" or AtticType="vented attic" or AtticType="flat roof" or AtticType="cathedral ceiling" or AtticType="cape cod"]',
                'Roofs/Roof',
            ],
              
              # Attic (Vented)
              '//Attic[AtticType="vented attic"]' => [
                  '//AirInfiltration/extension/AtticSpecificLeakageArea',
              ],
            
            ## Foundation
            '//Foundation' => [
                '[FoundationType/Basement | FoundationType/Crawlspace | FoundationType/SlabOnGrade | FoundationType/Ambient]',
            ],
            
                # Foundation (Basement)
                '//Foundation[FoundationType/Basement]' => [
                    'FoundationType/Basement/Conditioned',
                    'FrameFloor',
                    'FoundationWall',
                    'Slab',
                ],
                
                # Foundation (Crawlspace)
                '//Foundation[FoundationType/Crawlspace]' => [
                    'FoundationType/Crawlspace/Vented',
                    'FrameFloor',
                    'FoundationWall',
                ],
                
                # Foundation (Vented Crawlspace)
                '//Foundation/FoundationType/Crawlspace[Vented="true"]' => [
                    '//AirInfiltration/extension/CrawlspaceSpecificLeakageArea',
                ],
                
                # Foundation (SlabOnGrade)
                '//Foundation[FoundationType/SlabOnGrade]' => [
                    'Slab',
                ],
                
                # Foundation (Ambient)
                '//Foundation[FoundationType/Ambient]' => [
                    'FrameFloor',
                ],

            ## Roof
            '//Roof' => [
                'Area',
                'Rafters[Material="wood"]/FramingFactor',
                'Pitch',
                'RadiantBarrier',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'SolarAbsorptance',
                'Emittance',
            ],
            
            ## Wall
            '//Wall' => [
                'WallType/WoodStud',
                'Area',
                '[Siding="stucco" or Siding="brick veneer" or Siding="wood siding" or Siding="aluminum siding" or Siding="vinyl siding" or Siding="fiber cement siding"]',
                'SolarAbsorptance',
                'Emittance',                
                'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="vented attic" or ExteriorAdjacentTo="unvented attic" or ExteriorAdjacentTo="cape cod" or ExteriorAdjacentTo="ambient"]',
            ],
            
                # Wall (not Attic)
                '//Enclosure/Walls/Wall' => [
                    'extension[InteriorAdjacentTo="living space" or InteriorAdjacentTo="garage" or InteriorAdjacentTo="vented attic" or InteriorAdjacentTo="unvented attic" or InteriorAdjacentTo="cape cod"]',
                ],
            
                # Wall (WoodStud)
                '//Wall[WallType/WoodStud]' => [
                    'Studs[Material="wood"]/FramingFactor',
                    'Insulation/InsulationGrade',
                    'Insulation/Layer[InstallationType="cavity"]',
                    'Insulation/Layer[InstallationType="continuous"]',
                ],
                
            ## FoundationWall
            '//FoundationWall' => [
                'Height',
                'Area',
                'BelowGradeDepth',
                'InteriorStuds[Material="wood"]/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension[ExteriorAdjacentTo="ground" or ExteriorAdjacentTo="unconditioned basement" or ExteriorAdjacentTo="conditioned basement" or ExteriorAdjacentTo="crawlspace"]',
            ],
            
            ## Floor
            '//Floor' => [
                'Area',
                'FloorJoists[Material="wood"]/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="ambient"]',
            ],
            
            ## FoundationCeiling
            '//Foundation/FrameFloor' => [
                'Area',
                'FloorJoists[Material="wood"]/FramingFactor',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage"]',
            ],
            
            ## FoundationSlab
            '//Foundation/Slab' => [
                'Area',
                'PerimeterInsulationDepth',
                'UnderSlabInsulationWidth',
                'DepthBelowGrade',
                'PerimeterInsulation/Layer[InstallationType="continuous"]',
                'UnderSlabInsulation/Layer[InstallationType="continuous"]',
                'extension/CarpetFraction',
                'extension/CarpetRValue',
            ],
            
            ## Insulation Layer
            '//Layer' => [
                'InstallationType',
                'NominalRValue',
                'Thickness',
            ],
            
                # InsulationLayer (Basement, Continuous)
                '//Foundation[FoundationType/Basement]/FoundationWall/Insulation/Layer[InstallationType="continuous"]' => [
                    'extension/InsulationHeight',
                ],
            
            ## Window
            '//Enclosure/Windows/Window' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'AttachedToWall',
            ],
            
            ## Skylight
            '//Enclosure/Skylights/Skylight' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'Pitch',
                'AttachedToRoof',
            ],
            
            ## Door
            '//Enclosure/Doors/Door' => [
                'AttachedToWall',
                'Area',
                'Azimuth',
                'RValue',
            ],
            
            ## HeatingSystem
            '//HeatingSystem' => [
                'HeatingSystemType[Furnace | Boiler | ElectricResistance]',
                '[FractionHeatLoadServed=1.0]',
                '//HVACControl',
            ],
            
                # HeatingSystem (Furnace)
                '//HeatingSystem[HeatingSystemType/Furnace]' => [
                    'DistributionSystem',
                    '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]',
                    'AnnualHeatingEfficiency[Units="AFUE"]/Value',
                    '//AirDistribution',
                ],
                
                # HeatingSystem (Boiler)
                '//HeatingSystem[HeatingSystemType/Boiler]' => [
                    'DistributionSystem',
                    '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]',
                    'AnnualHeatingEfficiency[Units="AFUE"]/Value',
                    '//HydronicDistribution',
                ],
                
                # HeatingSystem (ElectricResistance)
                '//HeatingSystem[HeatingSystemType/ElectricResistance]' => [
                    '[HeatingSystemFuel="electricity"]',
                    'AnnualHeatingEfficiency[Units="Percent"]/Value',
                ],
            
            ## CoolingSystem
            '//CoolingSystem' => [
                '[CoolingSystemType="central air conditioning" or CoolingSystemType="room air conditioner"]',
                '[FractionCoolLoadServed=1.0]',
                '//HVACControl',
            ],
            
                # CoolingSystem (CentralAC)
                '//CoolingSystem[CoolingSystemType="central air conditioning"]' => [
                    'DistributionSystem',
                    '[CoolingSystemFuel="electricity"]',
                    'AnnualCoolingEfficiency[Units="SEER"]/Value',
                    'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]',
                    '//AirDistribution',
                ],
                
                # CoolingSystem (RoomAC)
                '//CoolingSystem[CoolingSystemType="room air conditioner"]' => [
                    '[CoolingSystemFuel="electricity"]',
                    'AnnualCoolingEfficiency[Units="EER"]/Value',
                ],
            
            ## HeatPump
            '//HeatPump' => [
                '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]',
                '[FractionHeatLoadServed=1.0]',
                '[FractionCoolLoadServed=1.0]',
                'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]',
                '//HVACControl',
            ],
            
                # HeatPump (AirSource)
                '//HeatPump[HeatPumpType="air-to-air"]' => [
                    'DistributionSystem',
                    'AnnualCoolEfficiency[Units="SEER"]/Value',
                    'AnnualHeatEfficiency[Units="HSPF"]/Value',
                    '//AirDistribution',
                ],
                
                # HeatPump (MiniSplit)
                '//HeatPump[HeatPumpType="mini-split"]' => [
                    'AnnualCoolEfficiency[Units="SEER"]/Value',
                    'AnnualHeatEfficiency[Units="HSPF"]/Value',
                ],
                
                # HeatPump (GroundSource)
                '//HeatPump[HeatPumpType="ground-to-air"]' => [
                    'DistributionSystem',
                    'AnnualCoolEfficiency[Units="EER"]/Value',
                    'AnnualHeatEfficiency[Units="COP"]/Value',
                    '//AirDistribution',
                ],
                
            ## HVACControl
            '//HVACControl' => [
                'ControlType',
            ],
            
            ## AirDistribution
            '//AirDistribution' => [
                'DuctLeakageMeasurement[DuctType="supply"]',
                'DuctLeakageMeasurement[DuctType="return"]',
                'Ducts[DuctType="supply" and FractionDuctArea=1.0]',
                'Ducts[DuctType="return" and FractionDuctArea=1.0]',
            ],
                
            ## Ducts
            '//Ducts' => [
                'DuctInsulationRValue',
                'DuctLocation', # TODO: Restrict values
                'DuctSurfaceArea',
            ],
            
            ## DuctLeakage
            '//DuctLeakageMeasurement' => [
                'DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value',
            ],
            
            ## HydronicDistribution
            '//HydronicDistribution' => [
                # TODO
            ],
            
            ## WaterHeatingSystem
            '//WaterHeatingSystem' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater"]',
                # TODO: 'Location',
                '[FractionDHWLoadServed=1.0]',
                'HeatingCapacity',
                'EnergyFactor',
            ],
            
                # WaterHeatingSystem (Tank)
                '//WaterHeatingSystem[WaterHeaterType="storage water heater" or WaterHeaterType="heat pump water heater"]' => [
                    'TankVolume',
                ],
                
                # WaterHeatingSystem (Fuel, Storage Tank)
                '//WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => [
                    'RecoveryEfficiency',
                ],
            
            ## HotWaterDistribution
            '//HotWaterDistribution' => [
                'SystemType',
                'PipeInsulation/PipeRValue',
            ],
            
                # HotWaterDistribution (Standard)
                '//HotWaterDistribution/SystemType/Standard' => [
                    'PipingLength',
                ],
                
                # HotWaterDistribution (Recirculation)
                '//HotWaterDistribution/SystemType/Recirculation' => [
                    'ControlType',
                    'RecirculationPipingLoopLength',
                    'BranchPipingLoopLength',
                    'PumpPower',
                ],
            
            ## DrainWaterHeatRecovery
            '//DrainWaterHeatRecovery' => [
                'FacilitiesConnected',
                'EqualFlow',
                'Efficiency',
            ],
            
            ## WaterFixture
            '//WaterFixture' => [
                '[FlowRate | extension/MixedWaterGPD]',
            ],
            
            ## WholeHouseVentilationFan
            '//VentilationFan[UsedForWholeBuildingVentilation="true"]' => [
                'FanType',
                'RatedFlowRate',
                'HoursInOperation',
                'UsedForWholeBuildingVentilation',
                'FanPower',
            ],
            
            # WholeHouseVentilationFan (ERV)
            '//VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="energy recovery ventilator"]' => [
                'TotalRecoveryEfficiency',
                'SensibleRecoveryEfficiency'
            ],
            
            # WholeHouseVentilationFan (HRV)
            '//VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="heat recovery ventilator"]' => [
                'SensibleRecoveryEfficiency',
            ],
            
            ## PV
            '//PVSystem' => [
                'ArrayAzimuth',
                'ArrayTilt',
                'InverterEfficiency',
                'MaxPowerOutput',
            ],
            
            ## ClothesWasher
            '//ClothesWasher' => [
                '[ModifiedEnergyFactor | extension/AnnualkWh]',
            ],
            
                # ClothesWasher (Detailed)
                '//ClothesWasher[ModifiedEnergyFactor]' => [
                    'RatedAnnualkWh',
                    'LabelElectricRate',
                    'LabelGasRate',
                    'LabelAnnualGasCost',
                    'Capacity',
                ],
                
                # ClothesWasher (Simplified)
                '//ClothesWasher[extension/AnnualkWh]' => [
                    'extension/HotWaterGPD',
                ],
            
            ## ClothesDryer
            '//ClothesDryer' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                '[EfficiencyFactor | extension/AnnualkWh]',
            ],
            
                # ClothesDryer (Detailed)
                '//ClothesDryer[EfficiencyFactor]' => [
                    'ControlType',
                ],
                
                # ClothesDryer (Simplified)
                '//ClothesDryer[extension/AnnualkWh]' => [
                    'extension/AnnualTherm',
                ],
            
            ## Dishwasher
            '//Dishwasher' => [
                '[EnergyFactor | RatedAnnualkWh | extension/AnnualkWh]',
            ],
            
                # Dishwasher (Detailed)
                '//Dishwasher[EnergyFactor | RatedAnnualkWh]' => [
                    'PlaceSettingCapacity',
                ],
                
                # Dishwasher (Simplified)
                '//Dishwasher[extension/AnnualkWh]' => [
                    'extension/HotWaterGPD',
                ],
            
            ## Refrigerator
            '//Refrigerator' => [
                'RatedAnnualkWh',
            ],
            
            ## CookingRange/Oven
            '//CookingRange' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                '[IsInduction | extension/AnnualkWh]',
            ],
            
                # CookingRange/Oven (Detailed)
                '//CookingRange[IsInduction]' => [
                    '//Oven/FuelType',
                    '//Oven/IsConvection',
                ],
                
                # CookingRange/Oven (Simplified)
                '//CookingRange[extension/AnnualkWh]' => [
                    'extension/AnnualTherm',
                ],
            
            ## Lighting
            '//Lighting' => [
                '[LightingFractions | extension/AnnualInteriorkWh]',
            ],
            
                # Lighting (Detailed)
                '//Lighting/LightingFractions' => [
                    'extension/QualifyingLightFixturesInterior',
                    'extension/QualifyingLightFixturesExterior',
                    'extension/QualifyingLightFixturesGarage',
                ],
                
                # Lighting (Simplified)
                '//Lighting[extension/AnnualInteriorkWh]' => [
                    'extension/AnnualExteriorkWh',
                    'extension/AnnualGaragekWh',
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
    
    return errors
    
  end
  
end
  