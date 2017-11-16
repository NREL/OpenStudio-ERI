class EnergyRatingIndex301Validator

  def self.run_validator(hpxml_doc, errors)
  
    # Every file must have this number of elements
    unconditional_counts = {
            '//Building' => [1],
            '//Building/BuildingDetails/BuildingSummary/Site/AzimuthOfFrontOfHome' => [1],
            '//Building/BuildingDetails/BuildingSummary/Site/FuelTypesAvailable' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume' => [1],
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent' => [1],
            '//Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year="2006"]' => [1],
            '//Building/BuildingDetails/ClimateandRiskZones/WeatherStation/extension/EPWFileName' => [1],
            '//Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure="ACHnatural"]/AirLeakage' => [1], # TODO: Allow ACH50, ELA, and/or SLA?
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem|//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [0,1],
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem|//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [0,1],
            '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => [0,1],
            '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution' => [0,1],
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => [0,1],
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => [0,1],
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => [1],
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="shower head"]' => [1],
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="faucet"]' => [1],
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
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics',
            '//Building/BuildingDetails/Enclosure/Foundations',
            '//Building/BuildingDetails/Enclosure/Walls',
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
                'Rafters/FramingFactor',
                'Rafters[Material="wood"]',
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
                'Joists/FramingFactor',
                'Joists[Material="wood"]',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
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
                'Studs/FramingFactor',
                'Studs[Material="wood"]',
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
                'FloorJoists/FramingFactor',
                'FloorJoists[Material="wood"]',
                'Area',
                'Insulation/InsulationGrade',
                'Insulation/Layer[InstallationType="cavity"]',
                'Insulation/Layer[InstallationType="continuous"]',
                'extension[AdjacentTo="living space"]',
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
                'Height',
                'Area',
                'BelowGradeDepth',
                'InteriorStuds/FramingFactor',
                'InteriorStuds[Material="wood"]',
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
                'UnderSlabInsulationWidth',
                'PerimeterInsulation/Layer[InstallationType="continuous"]',
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
                '[FractionHeatLoadServed=1.0]',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
            ],
            # HeatingSystem (Furnace)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace]' => [
                'DistributionSystem',
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]',
                'AnnualHeatingEfficiency[Units="AFUE"]/Value',
                '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution',
            ],
            # HeatingSystem (Boiler)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler]' => [
                'DistributionSystem',
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]',
                'AnnualHeatingEfficiency[Units="AFUE"]/Value',
                '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution',
            ],
            # HeatingSystem (ElectricResistance)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => [
                '[HeatingSystemFuel="electricity"]',
                'AnnualHeatingEfficiency[Units="Percent"]/Value',
            ],
            # CoolingSystem
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => [
                '[CoolingSystemType="central air conditioning" or CoolingSystemType="room air conditioner"]',
                '[FractionCoolLoadServed=1.0]',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
            ],
            # CoolingSystem (CentralAC)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioning"]' => [
                'DistributionSystem',
                '[CoolingSystemFuel="electricity"]',
                'AnnualCoolingEfficiency[Units="SEER"]/Value',
                'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]',
                '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution',
            ],
            # CoolingSystem (RoomAC)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => [
                '[CoolingSystemFuel="electricity"]',
                'AnnualCoolingEfficiency[Units="EER"]/Value',
            ],
            # HeatPump
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [
                '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]',
                '[FractionHeatLoadServed=1.0]',
                '[FractionCoolLoadServed=1.0]',
                'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
            ],
            # HeatPump (AirSource)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"]' => [
                'DistributionSystem',
                'AnnualCoolEfficiency[Units="SEER"]/Value',
                'AnnualHeatEfficiency[Units="HSPF"]/Value',
                '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution',
            ],
            # HeatPump (MiniSplit)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="mini-split"]' => [
                'AnnualCoolEfficiency[Units="SEER"]/Value',
                'AnnualHeatEfficiency[Units="HSPF"]/Value',
            ],
            # HeatPump (GroundSource)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => [
                'DistributionSystem',
                'AnnualCoolEfficiency[Units="EER"]/Value',
                'AnnualHeatEfficiency[Units="COP"]/Value',
                '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution',
            ],
            # AirDistribution
            '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => [
                'DuctLeakageMeasurement[DuctType="supply"]',
                'DuctLeakageMeasurement[DuctType="return"]',
                'Ducts[DuctType="supply" and FractionDuctArea=1.0]',
                'Ducts[DuctType="return" and FractionDuctArea=1.0]',
            ],
            # DuctLeakageMeasurement
            '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement' => [
                'DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value',
            ],
            # Ducts
            '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts' => [
                'DuctInsulationRValue',
                'DuctLocation', # TODO: Restrict values
                'DuctSurfaceArea',
            ],
            # HydronicDistribution
            '//Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution' => [
                # TODO
            ],
            # WaterHeatingSystem
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater"]',
                # TODO: 'Location',
                '[FractionDHWLoadServed=1.0]',
                'HeatingCapacity',
                'EnergyFactor',
                'RecoveryEfficiency',
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
            ],
            # HotWaterDistribution Standard
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Standard' => [
                'PipingLength',
            ],
            # HotWaterDistribution Recirculation
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Recirculation' => [
                'ControlType',
                'RecirculationPipingLoopLength',
                'BranchPipingLoopLength',
                'PumpPower',
            ],
            # DrainWaterHeatRecovery
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/DrainWaterHeatRecovery' => [
                'FacilitiesConnected',
                'EqualFlow',
                'Efficiency',
            ],
            # WaterFixture
            '//Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => [
                'FlowRate'
            ],
            # VentilationFan
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => [
                'FanType',
                'RatedFlowRate',
                'HoursInOperation',
                'UsedForWholeBuildingVentilation',
                'FanPower',
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
                'RatedAnnualkWh',
                'LabelElectricRate',
                'LabelGasRate',
                'LabelAnnualGasCost',
                'Capacity',
            ],
            # ClothesDryer
            '//Building/BuildingDetails/Appliances/ClothesDryer' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                'EfficiencyFactor',
                'ControlType',
            ],
            # Dishwasher
            '//Building/BuildingDetails/Appliances/Dishwasher' => [
                '[EnergyFactor|RatedAnnualkWh]',
                'PlaceSettingCapacity',
            ],
            # Refrigerator
            '//Building/BuildingDetails/Appliances/Refrigerator' => [
                'RatedAnnualkWh',
            ],
            # CookingRange
            '//Building/BuildingDetails/Appliances/CookingRange' => [
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
                'IsInduction',
            ],
            # Oven
            '//Building/BuildingDetails/Appliances/Oven' => [
                'FuelType',
                'IsConvection',
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
  