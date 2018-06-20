class EnergyRatingIndex301Validator

  def self.run_validator(hpxml_doc)
  
    one = [1]
    zero_or_one = [0,1]
    one_or_more = []
  
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
    
    eri_requirements = {
    
        # Root
        nil => {
            '/HPXML/SoftwareInfo' => one, # See [SoftwareInfo]
            '/HPXML/Building/BuildingDetails' => one, # See [BuildingDetails]
        },
        
        # [SoftwareInfo]
        '/HPXML/SoftwareInfo' => {
            'extension/ERICalculation[Version="2014"]' => one, # Only 2014 currently
            'extension/ERICalculation[Addenda="IncludeAll" or Addenda="Exclude2014G" or Addenda="Exclude2014GE" or Addenda="Exclude2014GEA"]' => one, # Only ERI version 2014 addenda A, E, and G affect the calculation
        },
        
        # [BuildingDetails]
        '/HPXML/Building/BuildingDetails' => {
            'BuildingSummary/Site/FuelTypesAvailable[Fuel="electricity" or Fuel="natural gas" or Fuel="fuel oil" or Fuel="propane" or Fuel="kerosene" or Fuel="diesel" or Fuel="anthracite coal" or Fuel="bituminous coal" or Fuel="coke" or Fuel="wood" or Fuel="wood pellets"]' => one_or_more,
            'BuildingSummary/BuildingConstruction/NumberofConditionedFloors' => one,
            'BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade' => one,
            'BuildingSummary/BuildingConstruction/NumberofBedrooms' => one,
            'BuildingSummary/BuildingConstruction/ConditionedFloorArea' => one,
            'BuildingSummary/BuildingConstruction/ConditionedBuildingVolume' => one,
            'BuildingSummary/BuildingConstruction/GaragePresent' => one,
            
            'ClimateandRiskZones/ClimateZoneIECC[Year="2006"]' => one, # Used by ANSI/RESNET/ICC 301-2014
            'ClimateandRiskZones/ClimateZoneIECC[Year="2012"]' => one, # Used by ANSI/RESNET/ICC 301-2014 Addendum E-2018 House Size Index Adjustment Factors (IAF)
            'ClimateandRiskZones/WeatherStation/WMO' => one, # Reference weather/data.csv for the list of acceptable WMO station numbers
            
            'Enclosure/AtticAndRoof/Attics' => one, # See [Attic]
            'Enclosure/Foundations' => one, # See [Foundation]
            'Enclosure/RimJoists' => zero_or_one, # See [RimJoist]
            'Enclosure/Walls' => one, # See [Wall]
            'Enclosure/Windows' => zero_or_one, # See [Window]
            'Enclosure/Skylights' => zero_or_one, # See [Skylight]
            'Enclosure/Doors' => zero_or_one, # See [Door]
            'Enclosure/AirInfiltration[AirInfiltrationMeasurement[HousePressure="50"]/BuildingAirLeakage[UnitofMeasure="ACH"]/AirLeakage | AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure="ACHnatural"]/AirLeakage]' => one, # ACH50 or constant ACH
            
            'Systems/HVAC/HVACPlant/HeatingSystem' => zero_or_one, # See [HeatingSystem]
            'Systems/HVAC/HVACPlant/CoolingSystem' => zero_or_one, # See [CoolingSystem]
            'Systems/HVAC/HVACPlant/HeatPump' => zero_or_one, # See [HeatPump]
            
            'Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => zero_or_one, # See [MechanicalVentilation]
            'Systems/WaterHeating' => zero_or_one, # See [WaterHeatingSystem]
            'Systems/Photovoltaics' => zero_or_one, # See [PVSystem]
            
            'Appliances/ClothesWasher' => one, # See [ClothesWasher]
            'Appliances/ClothesDryer' => one, # See [ClothesDryer]
            'Appliances/Dishwasher' => one, # See [Dishwasher]
            'Appliances/Refrigerator' => one, # See [Refrigerator]
            'Appliances/CookingRange' => one, # See [CookingRange]
            
            'Lighting' => one, # See [Lighting]
        },
        
        
        
        # [Attic]
        '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic' => {
            '[AtticType="unvented attic" or AtticType="vented attic" or AtticType="flat roof" or AtticType="cathedral ceiling" or AtticType="cape cod"]' => one, # See [AtticType=Unvented] or [AtticType=Vented] or [AtticType=Cape]
            'Roofs' => one, # See [AtticRoof]
            'Walls' => zero_or_one, # See [AtticWall]
        },
        
            ## [AtticType=Unvented]
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType="unvented attic"]' => {
                'Floors' => one, # See [AtticFloor]
            },
          
            ## [AtticType=Vented]
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType="vented attic"]' => {
                'Floors' => one, # See [AtticFloor]
                'extension/AtticSpecificLeakageArea' => one,
            },
          
            ## [AtticType=Cape]
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType="cape cod"]' => {
                'Floors' => one, # See [AtticFloor]
            },
            
            ## [AtticRoof]
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Roofs/Roof' => {
                'Area' => one,
                'SolarAbsorptance' => one,
                'Emittance' => one,
                'Pitch' => one,
                'RadiantBarrier' => one,
                'Insulation/AssemblyEffectiveRValue' => one,
            },
    
            ## [AtticFloor]
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Floors/Floor' => {
                'Area' => one,
                'Insulation/AssemblyEffectiveRValue' => one,
                'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="ambient"]' => one,
            },
            
            ## [AtticWall]
            '/HPXML/Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic/Walls/Wall' => {
                'WallType/WoodStud' => one,
                'Area' => one,
                '[Siding="stucco" or Siding="brick veneer" or Siding="wood siding" or Siding="aluminum siding" or Siding="vinyl siding" or Siding="fiber cement siding"]' => one,
                'SolarAbsorptance' => one,
                'Emittance' => one,
                'Insulation/AssemblyEffectiveRValue' => one,
                'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="vented attic" or ExteriorAdjacentTo="unvented attic" or ExteriorAdjacentTo="cape cod" or ExteriorAdjacentTo="ambient"]' => one,
            },

            
            
        # [Foundation]
        '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation' => {
            'FoundationType[Basement | Crawlspace | SlabOnGrade | Ambient]' => one, # See [FoundationType=Basement] or [FoundationType=Crawl] or [FoundationType=Slab] or [FoundationType=Ambient]
        },
            
            ## [FoundationType=Basement]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement]' => {
                'FoundationType/Basement/Conditioned' => one, # If not conditioned, see [FoundationType=UnconditionedBasement]
                'FoundationWall' => one_or_more, # See [FoundationWall]
                'Slab' => one_or_more, # See [FoundationSlab]
            },
            
            ## [FoundationType=UnconditionedBasement]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Basement[Conditioned="false"]]' => {
                'FrameFloor' => one_or_more, # See [FoundationFrameFloor]
            },
    
            ## [FoundationType=Crawl]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace]' => {
                'FoundationType/Crawlspace/Vented' => one, # If vented, see [FoundationType=VentedCrawl]
                'FrameFloor' => one_or_more, # See [FoundationFrameFloor]
                'FoundationWall' => one_or_more, # See [FoundationWall]
                'Slab' => one_or_more, # See [FoundationSlab]; use slab with zero thickness for dirt floor
            },
            
            ## [FoundationType=VentedCrawl]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented="true"]]' => {
                'extension/CrawlspaceSpecificLeakageArea' => one,
            },
            
            ## [FoundationType=Slab]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/SlabOnGrade]' => {
                'Slab' => one_or_more, # See [FoundationSlab]
            },
    
            ## [FoundationType=Ambient]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Ambient]' => {
                'FrameFloor' => one_or_more, # See [FoundationSlab]
            },
    
            ## [FoundationFrameFloor]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FrameFloor' => {
                'Area' => one,
                'Insulation/AssemblyEffectiveRValue' => one,
                'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage"]' => one,
            },

            ## [FoundationWall]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationWall' => {
                'Height' => one,
                'Area' => one,
                'Thickness' => one,
                'BelowGradeDepth' => one,
                'Insulation/AssemblyEffectiveRValue' => one,
                'extension[ExteriorAdjacentTo="ground" or ExteriorAdjacentTo="unconditioned basement" or ExteriorAdjacentTo="conditioned basement" or ExteriorAdjacentTo="crawlspace"]' => one,
            },

            ## [FoundationSlab]
            '/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab' => {
                'Area' => one,
                'Thickness' => one, # Use zero for dirt floor
                'ExposedPerimeter' => one,
                'PerimeterInsulationDepth' => one,
                'UnderSlabInsulationWidth' => one,
                'DepthBelowGrade' => one,
                'PerimeterInsulation/Layer[InstallationType="continuous"]/NominalRValue' => one,
                'PerimeterInsulation/Layer[InstallationType="continuous"]/Thickness' => one,
                'UnderSlabInsulation/Layer[InstallationType="continuous"]/NominalRValue' => one,
                'UnderSlabInsulation/Layer[InstallationType="continuous"]/Thickness' => one,
                'extension/CarpetFraction' => one,
                'extension/CarpetRValue' => one,
            },
            
            
            
        # [RimJoist]
        '/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist' => {
            '[ExteriorAdjacentTo="unconditioned basement" or ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="ground" or ExteriorAdjacentTo="crawlspace" or ExteriorAdjacentTo="attic" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="ambient"]' => one,
            '[InteriorAdjacentTo="unconditioned basement" or InteriorAdjacentTo="living space" or InteriorAdjacentTo="crawlspace" or InteriorAdjacentTo="attic" or InteriorAdjacentTo="garage"]' => one,
            'Area' => one,
            'Insulation/AssemblyEffectiveRValue' => one,
            'extension/SolarAbsorptance' => one,
            'extension/Emittance' => one,
        },
        
        
        
        # [Wall]
        '/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall' => {
            'WallType/WoodStud' => one,
            'Area' => one,
            '[Siding="stucco" or Siding="brick veneer" or Siding="wood siding" or Siding="aluminum siding" or Siding="vinyl siding" or Siding="fiber cement siding"]' => one,
            'SolarAbsorptance' => one,
            'Emittance' => one,
            'Insulation/AssemblyEffectiveRValue' => one,
            'extension[InteriorAdjacentTo="living space" or InteriorAdjacentTo="garage" or InteriorAdjacentTo="vented attic" or InteriorAdjacentTo="unvented attic" or InteriorAdjacentTo="cape cod"]' => one,
            'extension[ExteriorAdjacentTo="living space" or ExteriorAdjacentTo="garage" or ExteriorAdjacentTo="vented attic" or ExteriorAdjacentTo="unvented attic" or ExteriorAdjacentTo="cape cod" or ExteriorAdjacentTo="ambient"]' => one,
        },
    
    
    
        # [Window]
        '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window' => {
            'Area' => one,
            'Azimuth' => one,
            'UFactor' => one,
            'SHGC' => one,
            'Overhangs' => zero_or_one, # See [WindowOverhang]
            'AttachedToWall' => one,
        },
        
            ## [WindowOverhang]
            '/HPXML/Building/BuildingDetails/Enclosure/Windows/Window/Overhangs' => {
                'Depth' => one,
                'DistanceToTopOfWindow' => one,
            },
    
    
    
        # [Skylight]
        '/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight' => {
            'Area' => one,
            'Azimuth' => one,
            'UFactor' => one,
            'SHGC' => one,
            'AttachedToRoof' => one,
        },
    
    
    
        # [Door]
        '/HPXML/Building/BuildingDetails/Enclosure/Doors/Door' => {
            'Area' => one,
            'Azimuth' => one,
            'RValue' => one,
            'AttachedToWall' => one,
        },
        
        
        
        # [HeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => {
            '../../HVACControl' => one, # See [HVACControl]
            'DistributionSystem' => zero_or_one, # See [HVACDistribution]
            'HeatingSystemType[Furnace | Boiler | ElectricResistance]' => one, # See [HeatingType=Furnace] or [HeatingType=Boiler] or [HeatingType=Resistance]
            'FractionHeatLoadServed' => one,
        },
        
            ## [HeatingType=Furnace]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace]' => {
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]' => one,
                'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
            },
        
            ## [HeatingType=Boiler]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Boiler]' => {
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]' => one,
                'AnnualHeatingEfficiency[Units="AFUE"]/Value' => one,
            },
            
            ## [HeatingType=Resistance]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => {
                '[HeatingSystemFuel="electricity"]' => one,
                'AnnualHeatingEfficiency[Units="Percent"]/Value' => one,
            },
            
            
            
        ## [CoolingSystem]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => {
            'DistributionSystem' => zero_or_one, # See [HVACDistribution]
            '[CoolingSystemType="central air conditioning" or CoolingSystemType="room air conditioner"]' => one, # See [CoolingType=CentralAC] or [CoolingType=RoomAC]
            '[CoolingSystemFuel="electricity"]' => one,
            'FractionCoolLoadServed' => one,
        },
    
            ## [CoolingType=CentralAC]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioning"]' => {
                'AnnualCoolingEfficiency[Units="SEER"]/Value' => one,
            },
            
            ## [CoolingType=RoomAC]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioning"]' => {
                'AnnualCoolingEfficiency[Units="EER"]/Value' => one,
            },
            
            
            
        ## [HeatPump]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => {
            'DistributionSystem' => zero_or_one, # See [HVACDistribution]
            '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]' => one, # See [HeatPumpType=ASHP] or [HeatPumpType=MSHP] or [HeatPumpType=GSHP]
            'FractionHeatLoadServed' => one,
            'FractionCoolLoadServed' => one,
        },
            
            ## [HeatPumpType=ASHP]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air"]' => {
                'AnnualCoolEfficiency[Units="SEER"]/Value' => one,
                'AnnualHeatEfficiency[Units="HSPF"]/Value' => one,
            },

            ## [HeatPumpType=MSHP]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="mini-split"]' => {
                'AnnualCoolEfficiency[Units="SEER"]/Value' => one,
                'AnnualHeatEfficiency[Units="HSPF"]/Value' => one,
            },

            ## [HeatPumpType=GSHP]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => {
                'AnnualCoolEfficiency[Units="EER"]/Value' => one,
                'AnnualHeatEfficiency[Units="COP"]/Value' => one,
            },
            
        
        
        # [HVACControl]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl' => {
            'ControlType' => one,
        },

        
        
        # [HVACDistribution]
        '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution' => {
            '[DistributionSystemType/AirDistribution | DistributionSystemType/HydronicDistribution | DistributionSystemType[Other="DSE"]]' => one, # See [HVACDistType=Air] or [HVACDistType=Hydronic] or [HVACDistType=DSE]
        },
            
            ## [HVACDistType=Air]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution' => {
                'DuctLeakageMeasurement[DuctType="supply"]/DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value' => one,
                'DuctLeakageMeasurement[DuctType="return"]/DuctLeakage[Units="CFM25" and TotalOrToOutside="to outside"]/Value' => one,
                'Ducts[DuctType="supply" and FractionDuctArea=1.0]/DuctInsulationRValue' => one,
                'Ducts[DuctType="supply" and FractionDuctArea=1.0]/DuctLocation' => one, # TODO: Restrict values
                'Ducts[DuctType="supply" and FractionDuctArea=1.0]/DuctSurfaceArea' => one,
                'Ducts[DuctType="return" and FractionDuctArea=1.0]/DuctInsulationRValue' => one,
                'Ducts[DuctType="return" and FractionDuctArea=1.0]/DuctLocation' => one, # TODO: Restrict values
                'Ducts[DuctType="return" and FractionDuctArea=1.0]/DuctSurfaceArea' => one,
            },
        
            ## [HVACDistType=Hydronic]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/HydronicDistribution' => {
                # TODO
            },
            
            ## [HVACDistType=DSE]
            '/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution[DistributionSystemType[Other="DSE"]]' => {
                '[AnnualHeatingDistributionSystemEfficiency | AnnualCoolingDistributionSystemEfficiency]' => one_or_more,
            },
            
            
            
        # [MechanicalVentilation]
        '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => {
            '[FanType="energy recovery ventilator" or FanType="heat recovery ventilator" or FanType="exhaust only" or FanType="supply only" or FanType="balanced" or FanType="central fan integrated supply"]' => one, # See [MechVentType=HRV] or [MechVentType=ERV]
            'RatedFlowRate' => one,
            'HoursInOperation' => one,
            'UsedForWholeBuildingVentilation' => one,
            'FanPower' => one,
        },
        
            ## [MechVentType=HRV]
            '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"][FanType="heat recovery ventilator"]' => {
                'SensibleRecoveryEfficiency' => one,
            },
            
            ## [MechVentType=ERV]
            '/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"][FanType="energy recovery ventilator"]' => {
                'TotalRecoveryEfficiency' => one,
                'SensibleRecoveryEfficiency' => one,
            },

            
        
        # [WaterHeatingSystem]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => {
            '../HotWaterDistribution' => one, # See [HotWaterDistribution]
            '../WaterFixture' => one, # See [WaterFixture]
            '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater"]' => one, # See [WHType=Tank]
            '[Location="conditioned space" or Location="basement - unconditioned" or Location="attic - unconditioned" or Location="garage - unconditioned" or Location="crawlspace - unvented" or Location="crawlspace - vented"]' => one,
            'FractionDHWLoadServed' => one,
            '[EnergyFactor | UniformEnergyFactor]' => one,
        },
        
            ## [WHType=Tank]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater"]' => {
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => one, # If not electricity, see [WHType=FuelTank]
                'TankVolume' => one,
                'HeatingCapacity' => one,
            },
            
            ## [WHType=FuelTank]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => {
                'RecoveryEfficiency' => one,
            },
            
            ## [WHType=Tankless]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="instantaneous water heater"]' => {
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => one,
            },
            
            ## [WHType=HeatPump]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="heat pump water heater"]' => {
                '[FuelType="electricity"]' => one,
                'TankVolume' => one,
            },
        
        
        
        # [HotWaterDistribution]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => {
            '[SystemType/Standard | SystemType/Recirculation]' => one, # See [HWDistType=Standard] or [HWDistType=Recirculation]
            'PipeInsulation/PipeRValue' => one,
            'DrainWaterHeatRecovery' => zero_or_one # See [HotWaterDistribution DrainWaterHeatRecovery]
        },
        
            ## [HWDistType=Standard]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Standard' => {
                'PipingLength' => zero_or_one, # Uses Reference Home if not provided
            },
            
            ## [HWDistType=Recirculation]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/SystemType/Recirculation' => {
                'ControlType' => one,
                'RecirculationPipingLoopLength' => zero_or_one, # Uses Reference Home if not provided
                'BranchPipingLoopLength' => one,
                'PumpPower' => one,
            },
        
            ## [HotWaterDistribution DrainWaterHeatRecovery]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution/DrainWaterHeatRecovery' => {
                'FacilitiesConnected' => one,
                'EqualFlow' => one,
                'Efficiency' => one,
            },
        
        
        
        # [WaterFixture]
        '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture' => {
            '[FlowRate | extension/MixedWaterGPD]' => one, # If extension/MixedWaterGPD provided, see [FixtureType=Simplified]
        },
        
            # [FixtureType=Simplified]
            '/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture[extension/MixedWaterGPD]' => {
                'extension/SensibleGainsBtu' => [1],
                'extension/LatentGainsBtu' => [1],
            },

        
        
        # [PVSystem]
        '/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem' => {
            'ArrayAzimuth' => one,
            'ArrayTilt' => one,
            'InverterEfficiency' => one,
            'MaxPowerOutput' => one,
        },
        
        
        
        # [ClothesWasher]
        '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher' => {
            '[ModifiedEnergyFactor | extension/AnnualkWh]' => zero_or_one, # Uses Reference Home if neither provided; otherwise see [CWType=Detailed] or [CWType=Simplified]
        },
        
            ## [CWType=Detailed]
            '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher[ModifiedEnergyFactor]' => {
                'RatedAnnualkWh' => one,
                'LabelElectricRate' => one,
                'LabelGasRate' => one,
                'LabelAnnualGasCost' => one,
                'Capacity' => one,
            },
            
            ## [CWType=Simplified]
            '/HPXML/Building/BuildingDetails/Appliances/ClothesWasher[extension/AnnualkWh]' => {
                'extension/HotWaterGPD' => one,
                'extension/FracSensible' => one,
                'extension/FracLatent' => one,
            },
        
        
        
        # [ClothesDryer]
        '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer' => {
            '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => one,
            '[EfficiencyFactor | extension/AnnualkWh]' => zero_or_one, # Uses Reference Home if neither provided; otherwise see [CDType=Detailed] or [CDType=Simplified]
        },
        
            ## [CDType=Detailed]
            '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer[EfficiencyFactor]' => {
                'ControlType' => one,
            },
            
            ## [CDType=Simplified]
            '/HPXML/Building/BuildingDetails/Appliances/ClothesDryer[extension/AnnualkWh]' => {
                'extension/AnnualTherm' => one,
                'extension/FracSensible' => one,
                'extension/FracLatent' => one,
            },
        
        
        
        # [Dishwasher]
        '/HPXML/Building/BuildingDetails/Appliances/Dishwasher' => {
            '[EnergyFactor | RatedAnnualkWh | extension/AnnualkWh]' => zero_or_one, # Uses Reference Home if none provided; otherwise see [DWType=Detailed] or [DWType=Simplified]
        },
        
            ## [DWType=Detailed]
            '/HPXML/Building/BuildingDetails/Appliances/Dishwasher[EnergyFactor | RatedAnnualkWh]' => {
                'PlaceSettingCapacity' => one,
            },
            
            ## [DWType=Simplified]
            '/HPXML/Building/BuildingDetails/Appliances/Dishwasher[extension/AnnualkWh]' => {
                'extension/HotWaterGPD' => one,
                'extension/FracSensible' => one,
                'extension/FracLatent' => one,
            },
        
        
        
        # [Refrigerator]
        '/HPXML/Building/BuildingDetails/Appliances/Refrigerator' => {
            'RatedAnnualkWh' => zero_or_one,
        },
        
        
        
        # [CookingRange]
        '/HPXML/Building/BuildingDetails/Appliances/CookingRange' => {
            '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]' => one,
            '[IsInduction | extension/AnnualkWh]' => zero_or_one, # Uses Reference Home if neither provided; otherwise see [CRType=Detailed] or [CRType=Simplified]
        },
        
            ## [CRType=Detailed]
            '/HPXML/Building/BuildingDetails/Appliances/CookingRange[IsInduction]' => {
                '../Oven/FuelType' => one,
                '../Oven/IsConvection' => one,
            },
            
            ## [CRType=Simplified]
            '/HPXML/Building/BuildingDetails/Appliances/CookingRange[extension/AnnualkWh]' => {
                'extension/AnnualTherm' => one,
                'extension/FracSensible' => one,
                'extension/FracLatent' => one,
            },
        
        
        
        # [Lighting]
        '/HPXML/Building/BuildingDetails/Lighting' => {
            '[LightingFractions | extension/AnnualInteriorkWh]' => zero_or_one, # Uses Reference Home if neither provided; otherwise see [LtgType=Detailed] or [LtgType=Simplified]
        },
        
            ## [LtgType=Detailed]
            '/HPXML/Building/BuildingDetails/Lighting/LightingFractions[/HPXML/SoftwareInfo/extension/ERICalculation[Addenda="Exclude2014G" or Addenda="Exclude2014GE" or Addenda="Exclude2014GEA"]]' => {
                'extension/FractionQualifyingFixturesInterior' => one,
                'extension/FractionQualifyingFixturesExterior' => one,
                'extension/FractionQualifyingFixturesGarage' => one,
            },
            
            ## [LtgType=DetailedAppendixG]
            '/HPXML/Building/BuildingDetails/Lighting/LightingFractions[/HPXML/SoftwareInfo/extension/ERICalculation[Addenda="IncludeAll"]]' => {
                'extension/FractionQualifyingTierIFixturesInterior' => one,
                'extension/FractionQualifyingTierIFixturesExterior' => one,
                'extension/FractionQualifyingTierIFixturesGarage' => one,
                'extension/FractionQualifyingTierIIFixturesInterior' => one,
                'extension/FractionQualifyingTierIIFixturesExterior' => one,
                'extension/FractionQualifyingTierIIFixturesGarage' => one,
            },
            
            ## [LtgType=Simplified]
            '/HPXML/Building/BuildingDetails/Lighting[extension/AnnualInteriorkWh]' => {
                'extension/AnnualExteriorkWh' => one,
                'extension/AnnualGaragekWh' => one,
            },
            
    }
    
    errors = []
    eri_requirements.each do |parent, requirement|
      if parent.nil? # Unconditional
        requirement.each do |child, expected_sizes|
          xpath = combine_into_xpath(parent, child)
          actual_size = REXML::XPath.first(hpxml_doc, "count(#{xpath})")
          check_number_of_elements(actual_size, expected_sizes, xpath, errors)
        end
      else # Conditional based on parent element existence
        next if hpxml_doc.elements[parent].nil? # Skip if parent element doesn't exist
        hpxml_doc.elements.each(parent) do |parent_element|
          requirement.each do |child, expected_sizes|
            xpath = combine_into_xpath(parent, child)
            actual_size = REXML::XPath.first(parent_element, "count(#{child})")
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
      errors << "Expected #{expected_sizes.to_s} element(s) but found #{actual_size.to_s} element(s) for xpath: #{xpath}"
    else
      return if actual_size > 0
      errors << "Expected 1 or more element(s) but found 0 elements for xpath: #{xpath}"
    end
  end
  
  def self.combine_into_xpath(parent, child)
    if parent.nil?
      return child
    elsif child.start_with?("[")
      return [parent, child].join('')
    end
    return [parent, child].join('/')
  end
  
end
  