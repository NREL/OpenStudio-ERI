class EnergyRatingIndex301Validator

  def self.run_validator(hpxml_doc)
  
    # A hash of hashes that defines the required XML elements.
    #
    # If a key is provided, the child elements are conditional based on
    # the existence of the key element. If a key is not provided (nil), the
    # elements are unconditional and always required.
    #
    # The child hash values define the number of required instances for
    # the element. Multiple values, e.g. [0,1,2], can be specified. If 
    # an empty list [] is specified, there must be 1 or more instances.
    #
    # Example:
    # use_case = {
    #     nil => {
    #         'cat' => [],        # 1 or more elements always required
    #         'dog' => [1],       # 1 element always required
    #         'bird' => [0,1],    # 0 or 1 elements always required
    #     },
    #     '/pets' => {
    #         'cat' => [],        # 1 or more elements required if /pets element exists
    #         'dog' => [1],       # 1 element required if /pets element exists
    #         'bird' => [0,1],    # 0 or 1 elements required if /pets element exists
    #     }
    # }
    #
    use_case = {
    
        nil => {
            '/HPXML/Building/BuildingDetails' => [1],
        },
        
        # Building
        '/HPXML/Building/BuildingDetails' => {
            'BuildingSummary/Site' => [1],
            'BuildingSummary/BuildingConstruction' => [1],
            'ClimateandRiskZones' => [1],
            'Enclosure/AtticAndRoof/Attics' => [],
            'Enclosure/Foundations' => [],
            'Enclosure/Walls' => [],
            'Enclosure/AirInfiltration/' => [1],
            'Systems/HVAC/HVACPlant/HeatingSystem | Systems/HVAC/HVACPlant/HeatPump' => [0,1],
            'Systems/HVAC/HVACPlant/CoolingSystem | Systems/HVAC/HVACPlant/HeatPump' => [0,1],
            'Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => [0,1],
            'Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution' => [0,1],
            'Systems/HVAC/HVACControl' => [0,1],
            'Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => [0,1],
            'Systems/WaterHeating/WaterHeatingSystem' => [0,1],
            'Systems/WaterHeating/HotWaterDistribution' => [0,1],
            'Systems/Photovoltaics/PVSystem' => [0,1,2,3,4,5],
            'Appliances/ClothesWasher' => [1],
            'Appliances/ClothesDryer' => [1],
            'Appliances/Dishwasher' => [1],
            'Appliances/Refrigerator' => [1],
            'Appliances/CookingRange' => [1],
            'Lighting' => [1],
        },
        
        ## Site
        '/HPXML/Building/BuildingDetails/BuildingSummary/Site' => {
            'FuelTypesAvailable' => [1],
        },
        
          # FuelTypesAvailable
          '/HPXML/Building/BuildingDetails/BuildingSummary/Site/FuelTypesAvailable' => {
            '[Fuel="electricity"]' => [0,1],
            '[Fuel="natural gas"]' => [0,1],
            '[Fuel="fuel oil"]' => [0,1],
            '[Fuel="propane"]' => [0,1],
            '[Fuel="kerosene"]' => [0,1],
            '[Fuel="diesel"]' => [0,1],
            '[Fuel="anthracite coal"]' => [0,1],
            '[Fuel="bituminous coal"]' => [0,1],
            '[Fuel="coke"]' => [0,1],
            '[Fuel="wood"]' => [0,1],
            '[Fuel="wood pellets"]' => [0,1],
        },
        
        ## BuildingConstruction
        '/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction' => {
            'NumberofConditionedFloors' => [1],
            'NumberofConditionedFloorsAboveGrade' => [1],
            'NumberofBedrooms' => [1],
            'NumberofBathrooms' => [1],
            'ConditionedFloorArea' => [1],
            'BuildingVolume' => [1],
            'ConditionedBuildingVolume' => [1],
            'GaragePresent' => [1],
        },
        
        ## Climate
        '/HPXML/Building/BuildingDetails/ClimateandRiskZones/' => {
            'ClimateZoneIECC[Year="2006"]' => [1],
            'WeatherStation/extension/EPWFileName' => [1],
        },

        ## AirInfiltration
        '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration' => {
            '[AirInfiltrationMeasurement[HousePressure="50"]/BuildingAirLeakage[UnitofMeasure="ACH"]/AirLeakage | AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure="ACHnatural"]/AirLeakage]' => [1],
        },
        
        ## Attic
        '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic' => {
            '[AtticType="unvented attic" or AtticType="vented attic" or AtticType="flat roof" or AtticType="cathedral ceiling" or AtticType="cape cod"]' => [1],
            'Roofs/Roof' => [],
        },
          
          # Attic (Vented)
          '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType="vented attic"]' => {
              '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/extension/AtticSpecificLeakageArea' => [1],
          },
        
        ## Foundation
        '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation' => {
            '[FoundationType/Basement | FoundationType/Crawlspace | FoundationType/SlabOnGrade | FoundationType/Ambient]' => [1],
        },
        
            # Foundation (Basement)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]' => {
                'FoundationType/Basement/Conditioned' => [1],
                'FrameFloor' => [1],
                'FoundationWall' => [1],
                'Slab' => [1],
            },
            
            # Foundation (Crawlspace)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace]' => {
                'FoundationType/Crawlspace/Vented' => [1],
                'FrameFloor' => [1],
                'FoundationWall' => [1],
                'Slab' => [1],
            },
            
            # Foundation (Vented Crawlspace)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationType/Crawlspace[Vented="true"]' => {
                '/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/extension/CrawlspaceSpecificLeakageArea' => [1],
            },
            
            # Foundation (SlabOnGrade)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/SlabOnGrade]' => {
                'Slab' => [1],
            },
            
            # Foundation (Ambient)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Ambient]' => {
                'FrameFloor' => [],
            },

        ## Roof
        '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Roofs/Roof' => {
            'Area' => [1],
            'Pitch' => [1],
            'RadiantBarrier' => [1],
            'SolarAbsorptance' => [1],
            'Emittance' => [1],
            '[Insulation/Layer | Insulation/AssemblyEffectiveRValue]' => [1],
        },
        
            # Roof (Detailed)
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Roofs/Roof[Insulation/Layer]' => {
                'Rafters[Material="wood"]/FramingFactor' => [1],
                'Insulation/InsulationGrade' => [1],
                'Insulation/Layer[InstallationType="cavity"]' => [1],
                'Insulation/Layer[InstallationType="continuous"]' => [1],
            },
        
        ## Wall
        '//Walls/Wall' => {
            'WallType/WoodStud' => [1],
            'Area' => [1],
            '[Siding="stucco" or Siding="brick veneer" or Siding="wood siding" or Siding="aluminum siding" or Siding="vinyl siding" or Siding="fiber cement siding"]' => [1],
            'SolarAbsorptance' => [1],
            'Emittance' => [1],
            'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="vented attic" or ExteriorAdjacentTo="unvented attic" or ExteriorAdjacentTo="cape cod" or ExteriorAdjacentTo="ambient"]' => [1],
        },
        
            # Wall (not Attic)
            '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => {
                'extension[InteriorAdjacentTo="living space" or InteriorAdjacentTo="garage" or InteriorAdjacentTo="vented attic" or InteriorAdjacentTo="unvented attic" or InteriorAdjacentTo="cape cod"]' => [1],
            },
        
            # Wall (WoodStud)
            '//Walls/Wall[WallType/WoodStud]' => {
                '[Insulation/Layer | Insulation/AssemblyEffectiveRValue]' => [1],
            },
            
            # Wall (WoodStud, Detailed)
            '//Walls/Wall[WallType/WoodStud][Insulation/Layer]' => {
                'Studs[Material="wood"]/FramingFactor' => [1],
                'Insulation/InsulationGrade' => [1],
                'Insulation/Layer[InstallationType="cavity"]' => [1],
                'Insulation/Layer[InstallationType="continuous"]' => [1],
            },
            
        ## FoundationWall
        '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationWall' => {
            'Height' => [1],
            'Area' => [1],
            'Thickness' => [1],
            'BelowGradeDepth' => [1],
            'extension[ExteriorAdjacentTo="ground" or ExteriorAdjacentTo="unconditioned basement" or ExteriorAdjacentTo="conditioned basement" or ExteriorAdjacentTo="crawlspace"]' => [1],
            '[Insulation/Layer | Insulation/AssemblyEffectiveRValue]' => [1],
        },
        
            # FoundationWall (Detailed)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationWall[Insulation/Layer]' => {
                'InteriorStuds[Material="wood"]/FramingFactor' => [1],
                'Insulation/InsulationGrade' => [1],
                'Insulation/Layer[InstallationType="cavity"]' => [1],
                'Insulation/Layer[InstallationType="continuous"]' => [1],
            },
        
        ## Floor
        '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Floors/Floor' => {
            'Area' => [1],
            'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="ambient"]' => [1],
            '[Insulation/Layer | Insulation/AssemblyEffectiveRValue]' => [1],
        },
        
            # Floor (Detailed)
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Floors/Floor[Insulation/Layer]' => {
                'FloorJoists[Material="wood"]/FramingFactor' => [1],
                'Insulation/InsulationGrade' => [1],
                'Insulation/Layer[InstallationType="cavity"]' => [1],
                'Insulation/Layer[InstallationType="continuous"]' => [1],
            },
        
        ## FoundationCeiling
        '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FrameFloor' => {
            'Area' => [1],
            'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage"]' => [1],
            '[Insulation/Layer | Insulation/AssemblyEffectiveRValue]' => [1],
        },
        
            # FoundationCeiling (Detailed)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FrameFloor[Insulation/Layer]' => {
                'FloorJoists[Material="wood"]/FramingFactor' => [1],
                'Insulation/InsulationGrade' => [1],
                'Insulation/Layer[InstallationType="cavity"]' => [1],
                'Insulation/Layer[InstallationType="continuous"]' => [1],
            },
        
        ## FoundationSlab
        '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab' => {
            'Area' => [1],
            'Thickness' => [1], # Use a value of zero for a dirt floor
            'ExposedPerimeter' => [1],
            'PerimeterInsulationDepth' => [1],
            'UnderSlabInsulationWidth' => [1],
            'DepthBelowGrade' => [1],
            'PerimeterInsulation/Layer[InstallationType="continuous"]' => [1],
            'UnderSlabInsulation/Layer[InstallationType="continuous"]' => [1],
            'extension/CarpetFraction' => [1],
            'extension/CarpetRValue' => [1],
        },
        
        ## Insulation Layer
        '//Layer' => {
            'InstallationType' => [1],
            'NominalRValue' => [1],
            'Thickness' => [1],
        },
        
            # InsulationLayer (Basement, Continuous)
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]/FoundationWall/Insulation/Layer[InstallationType="continuous"]' => {
                'extension/InsulationHeight' => [1], # FIXME?
            },
        
        ## Window
        '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window' => {
            'Area' => [1],
            'Azimuth' => [1],
            'UFactor' => [1],
            'SHGC' => [1],
            'AttachedToWall' => [1],
        },
        
        ## Skylight
        '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight' => {
            'Area' => [1],
            'Azimuth' => [1],
            'UFactor' => [1],
            'SHGC' => [1],
            'AttachedToRoof' => [1],
        },
        
        ## Door
        '/HPXML/Building/BuildingDetails/Enclosure/Doors/Door' => {
            'Area' => [1],
            'Azimuth' => [1],
            'RValue' => [1],
            'AttachedToWall' => [1],
        },
        
        ## HeatingSystem
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => {
            'HeatingSystemType[Furnace | Boiler | ElectricResistance]' => [1],
            '[FractionHeatLoadServed=1.0]' => [1],
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => [1],
        },
        
            # HeatingSystem (Furnace)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace]' => {
                'DistributionSystem' => [1],
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]' => [1],
                'AnnualHeatingEfficiency[Units="AFUE"]/Value' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency]' => [1],
            },
            
            # HeatingSystem (Boiler)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler]' => {
                'DistributionSystem' => [1],
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]' => [1],
                'AnnualHeatingEfficiency[Units="AFUE"]/Value' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency]' => [1],
            },
            
            # HeatingSystem (ElectricResistance)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => {
                '[HeatingSystemFuel="electricity"]' => [1],
                'AnnualHeatingEfficiency[Units="Percent"]/Value' => [1],
            },
        
        ## CoolingSystem
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => {
            '[CoolingSystemType="central air conditioning" or CoolingSystemType="room air conditioner"]' => [1],
            '[FractionCoolLoadServed=1.0]' => [1],
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => [1],
        },
        
            # CoolingSystem (CentralAC)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioning"]' => {
                'DistributionSystem' => [1],
                '[CoolingSystemFuel="electricity"]' => [1],
                'AnnualCoolingEfficiency[Units="SEER"]/Value' => [1],
                'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualCoolingDistributionSystemEfficiency]' => [1],
            },
            
            # CoolingSystem (RoomAC)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => {
                '[CoolingSystemFuel="electricity"]' => [1],
                'AnnualCoolingEfficiency[Units="EER"]/Value' => [1],
            },
        
        ## HeatPump
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => {
            '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]' => [1],
            '[FractionHeatLoadServed=1.0]' => [1],
            '[FractionCoolLoadServed=1.0]' => [1],
            'extension[NumberSpeeds="1-Speed" or NumberSpeeds="2-Speed" or NumberSpeeds="Variable-Speed"]' => [1],
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => [1],
        },
        
            # HeatPump (AirSource)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"]' => {
                'DistributionSystem' => [1],
                'AnnualCoolEfficiency[Units="SEER"]/Value' => [1],
                'AnnualHeatEfficiency[Units="HSPF"]/Value' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency]' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualCoolingDistributionSystemEfficiency]' => [1],
            },
            
            # HeatPump (MiniSplit)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="mini-split"]' => {
                'AnnualCoolEfficiency[Units="SEER"]/Value' => [1],
                'AnnualHeatEfficiency[Units="HSPF"]/Value' => [1],
            },
            
            # HeatPump (GroundSource)
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => {
                'DistributionSystem' => [1],
                'AnnualCoolEfficiency[Units="EER"]/Value' => [1],
                'AnnualHeatEfficiency[Units="COP"]/Value' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualHeatingDistributionSystemEfficiency]' => [1],
                '[/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution | /HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/AnnualCoolingDistributionSystemEfficiency]' => [1],
            },
            
        ## HVACControl
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => {
            'ControlType' => [1],
        },
        
        ## AirDistribution
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => {
            'DuctLeakageMeasurement[DuctType="supply"]' => [1],
            'DuctLeakageMeasurement[DuctType="return"]' => [1],
            'Ducts[DuctType="supply" and FractionDuctArea=1.0]' => [1],
            'Ducts[DuctType="return" and FractionDuctArea=1.0]' => [1],
        },
            
        ## Ducts
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/Ducts' => {
            'DuctInsulationRValue' => [1],
            'DuctLocation' => [1], # TODO: Restrict values
            'DuctSurfaceArea' => [1],
        },
        
        ## DuctLeakage
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution/DuctLeakageMeasurement' => {
            'DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value' => [1],
        },
        
        ## HydronicDistribution
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution' => {
            # TODO
        },
        
        ## WaterHeatingSystem
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => {
            '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => [1],
            '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater"]' => [1],
            # TODO: 'Location',
            '[FractionDHWLoadServed=1.0]' => [1],
            '[EnergyFactor | UniformEnergyFactor]' => [1],
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture[WaterFixtureType="shower head" or WaterFixtureType="faucet"]' => [],
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => [1],
        },
        
            # WaterHeatingSystem (Tank)
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" or WaterHeaterType="heat pump water heater"]' => {
                'TankVolume' => [1],
            },
            
            # WaterHeatingSystem (Fuel, Storage Tank)
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => {
                'RecoveryEfficiency' => [1],
            },
        
        ## HotWaterDistribution
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => {
            'SystemType' => [1],
            'PipeInsulation/PipeRValue' => [1],
        },
        
            # HotWaterDistribution (Standard)
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Standard' => {
                'PipingLength' => [0,1], # Uses Reference Home if not provided
            },
            
            # HotWaterDistribution (Recirculation)
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Recirculation' => {
                'ControlType' => [1],
                'RecirculationPipingLoopLength' => [0,1], # Uses Reference Home if not provided
                'BranchPipingLoopLength' => [1],
                'PumpPower' => [1],
            },
        
        ## DrainWaterHeatRecovery
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/DrainWaterHeatRecovery' => {
            'FacilitiesConnected' => [1],
            'EqualFlow' => [1],
            'Efficiency' => [1],
        },
        
        ## WaterFixture
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => {
            '[FlowRate | extension/MixedWaterGPD]' => [1],
        },
        
        ## WholeHouseVentilationFan
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => {
            'FanType' => [1],
            'RatedFlowRate' => [1],
            'HoursInOperation' => [1],
            'UsedForWholeBuildingVentilation' => [1],
            'FanPower' => [1],
        },
        
            # WholeHouseVentilationFan (ERV)
            '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="energy recovery ventilator"]' => {
                'TotalRecoveryEfficiency' => [1],
                'SensibleRecoveryEfficiency' => [1],
            },
            
            # WholeHouseVentilationFan (HRV)
            '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true" and FanType="heat recovery ventilator"]' => {
                'SensibleRecoveryEfficiency' => [1],
            },
        
        ## PV
        '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => {
            'ArrayAzimuth' => [1],
            'ArrayTilt' => [1],
            'InverterEfficiency' => [1],
            'MaxPowerOutput' => [1],
        },
        
        ## ClothesWasher
        '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => {
            '[ModifiedEnergyFactor | extension/AnnualkWh]' => [0,1], # Uses Reference Home if not provided
        },
        
            # ClothesWasher (Detailed)
            '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher[ModifiedEnergyFactor]' => {
                'RatedAnnualkWh' => [1],
                'LabelElectricRate' => [1],
                'LabelGasRate' => [1],
                'LabelAnnualGasCost' => [1],
                'Capacity' => [1],
            },
            
            # ClothesWasher (Simplified)
            '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher[extension/AnnualkWh]' => {
                'extension/HotWaterGPD' => [1],
                'extension/FracSensible' => [1],
                'extension/FracLatent' => [1],
            },
        
        ## ClothesDryer
        '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => {
            '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => [1],
            '[EfficiencyFactor | extension/AnnualkWh]' => [0,1], # Uses Reference Home if not provided
        },
        
            # ClothesDryer (Detailed)
            '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer[EfficiencyFactor]' => {
                'ControlType' => [1],
            },
            
            # ClothesDryer (Simplified)
            '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer[extension/AnnualkWh]' => {
                'extension/AnnualTherm' => [1],
                'extension/FracSensible' => [1],
                'extension/FracLatent' => [1],
            },
        
        ## Dishwasher
        '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => {
            '[EnergyFactor | RatedAnnualkWh | extension/AnnualkWh]' => [0,1], # Uses Reference Home if not provided
        },
        
            # Dishwasher (Detailed)
            '/HPXML/Building/BuildingDetails/Appliances/Dishwasher[EnergyFactor | RatedAnnualkWh]' => {
                'PlaceSettingCapacity' => [1],
            },
            
            # Dishwasher (Simplified)
            '/HPXML/Building/BuildingDetails/Appliances/Dishwasher[extension/AnnualkWh]' => {
                'extension/HotWaterGPD' => [1],
                'extension/FracSensible' => [1],
                'extension/FracLatent' => [1],
            },
        
        ## Refrigerator
        '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => {
            'RatedAnnualkWh' => [0,1],
        },
        
        ## CookingRange/Oven
        '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => {
            '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => [1],
            '[IsInduction | extension/AnnualkWh]' => [0,1], # Uses Reference Home if not provided
        },
        
            # CookingRange/Oven (Detailed)
            '/HPXML/Building/BuildingDetails/Appliances/CookingRange[IsInduction]' => {
                '//Oven/FuelType' => [1],
                '//Oven/IsConvection' => [1],
            },
            
            # CookingRange/Oven (Simplified)
            '/HPXML/Building/BuildingDetails/Appliances/CookingRange[extension/AnnualkWh]' => {
                'extension/AnnualTherm' => [1],
                'extension/FracSensible' => [1],
                'extension/FracLatent' => [1],
            },
        
        ## Lighting
        '/HPXML/Building/BuildingDetails/Lighting' => {
            '[LightingFractions | extension/AnnualInteriorkWh]' => [0,1], # Uses Reference Home if not provided
        },
        
            # Lighting (Detailed)
            '/HPXML/Building/BuildingDetails/Lighting/LightingFractions' => {
                'extension/QualifyingLightFixturesInterior' => [1],
                'extension/QualifyingLightFixturesExterior' => [1],
                'extension/QualifyingLightFixturesGarage' => [1],
            },
            
            # Lighting (Simplified)
            '/HPXML/Building/BuildingDetails/Lighting[extension/AnnualInteriorkWh]' => {
                'extension/AnnualExteriorkWh' => [1],
                'extension/AnnualGaragekWh' => [1],
            },
            
    }
    
    errors = []
    use_case.each do |parent, requirement|
      if parent.nil? # Unconditional
        requirement.each do |child, numbers|
          elements = hpxml_doc.elements.to_a(child)
          xpath = combine_into_xpath(parent, child)
          check_number_of_elements(elements, numbers, xpath, errors)
        end
      else # Conditional based on parent element existence
        next if hpxml_doc.elements[parent].nil? # Skip if parent element doesn't exist
        hpxml_doc.elements.each(parent) do |parent_element|
          requirement.each do |child, numbers|
            elements = parent_element.elements.to_a(child)
            xpath = combine_into_xpath(parent, child)
            check_number_of_elements(elements, numbers, xpath, errors)
          end
        end
      end
    end
    
    return errors
  end
  
  def self.check_number_of_elements(elements, numbers, xpath, errors)
    if numbers.size > 0 # Number of elements must be in the numbers list
      return if numbers.include?(elements.size)
      errors << "Expected #{numbers.to_s} element(s) but found #{elements.size.to_s} element(s) for xpath: #{xpath}"
    else # Must have 1 or more elements
      return if elements.size > 0
      errors << "Expected 1 or more element(s) but found 0 elements for xpath: #{xpath}"
    end
  end
  
  def self.combine_into_xpath(parent, child)
    if parent.nil? or child.start_with?("/")
      return child
    elsif child.start_with?("[")
      return [parent, child].join('')
    end
    return [parent, child].join('/')
  end
  
end
  