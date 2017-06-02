require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/xmlhelper"
require "#{File.dirname(__FILE__)}/waterheater"

class EnergyRatingIndex301Ruleset

  def self.apply_ruleset(hpxml_doc, calc_type)
  
    errors = []
    building = nil
    
    # Check for required inputs, etc.
    run_validator(hpxml_doc, errors)
    if errors.size > 0
      return errors, building
    end
    
    # Update XML type
    header = hpxml_doc.elements["//XMLTransactionHeaderInformation"]
    if header.elements["XMLType"].nil?
      header.elements["XMLType"].text = calc_type
    else
      header.elements["XMLType"].text += calc_type
    end
    
    # Get the building element
    building = hpxml_doc.elements["//Building"]
    
    cfa, nbeds, nbaths, climate_zone = get_high_level_inputs(building)
        
    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
        apply_reference_home_ruleset(building, cfa, nbeds, nbaths, climate_zone)
    elsif calc_type == Constants.CalcTypeERIRatedHome
        apply_rated_home_ruleset(building, cfa, nbeds, nbaths)
    elsif calc_type == Constants.CalcTypeERIndexAdjustmentDesign
        apply_index_adjustment_design_ruleset(building)
    end
    
    return errors, building
    
  end

  def self.run_validator(hpxml_doc, errors)
  
    # Every file must have this number of elements
    unconditional_counts = {
            '//Building' => [1],
            '//Building/BuildingDetails/BuildingSummary/extension/HasNaturalGasAccessOrFuelDelivery' => [1],
            '//Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure="ACHnatural"]' => [1],
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant[HeatingSystem|CoolingSystem|HeatPump]' => [0,1],
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HVACControl/ControlType' => [0,1],
            '//Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation="true"]' => [0,1],
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => [0,1],
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => [1],
            '//Building/BuildingDetails/Appliances/ClothesWasher' => [1],
            '//Building/BuildingDetails/Appliances/ClothesDryer' => [1],
            '//Building/BuildingDetails/Appliances/Dishwasher' => [1],
            '//Building/BuildingDetails/Appliances/Refrigerator' => [1],
            '//Building/BuildingDetails/Appliances/CookingRange' => [1],
            '//Building/BuildingDetails/Appliances/Oven' => [1],
            '//Building/BuildingDetails/Lighting/LightingFractions' => [1],
    }
    
    # Every file must have 1 (or more) of these elements
    unconditional_has = [
            '//Building/BuildingDetails/BuildingSummary/Site/AzimuthOfFrontOfHome',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms',
            '//Building/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType',
            '//Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC/ClimateZone',
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
            ],
            # Attics
            '//Building/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic' => [
                #'AtticFloorInsulation[AssemblyEffectiveRValue and InsulationGrade]',
                #'AtticRoofInsulation[AssemblyEffectiveRValue and InsulationGrade]',
                'Area',
            ],
            # Basement
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationType/Basement' => [
                'Conditioned',
            ],
            # FrameFloor
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FrameFloor' => [
                'Area',
                #'Insulation[AssemblyEffectiveRValue and InsulationGrade]',
            ],
            # FoundationWall
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationWall' => [
                'Area',
                'Height',
                'BelowGradeDepth',
                'AdjacentTo',
                #'Insulation[AssemblyEffectiveRValue and InsulationGrade]',
            ],
            # Wall
            '//Building/BuildingDetails/Enclosure/Walls/Wall' => [
                'Area',
                'InteriorAdjacentTo',
                'ExteriorAdjacentTo',
                #'Insulation[AssemblyEffectiveRValue and InsulationGrade]',
                
            ],
            # Window
            '//Building/BuildingDetails/Enclosure/Windows/Window' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'Operable',
            ],
            # Skylight
            '//Building/BuildingDetails/Enclosure/Skylights/Skylight' => [
                'Area',
                'Azimuth',
                'UFactor',
                'SHGC',
                'Operable',
                'Pitch',
            ],
            # Slab
            '//Building/BuildingDetails/Enclosure/Foundations/Foundation/Slab' => [
                'Area',
                #'[[PerimeterInsulationDepth and PerimeterInsulation[AssemblyEffectiveRValue and InsulationGrade]]|[not(PerimeterInsulationDepth) and not(PerimeterInsulation)]]',
                #'[[UnderSlabInsulationWidth and UnderSlabInsulation[AssemblyEffectiveRValue and InsulationGrade]]|[not(UnderSlabInsulationWidth) and not(UnderSlabInsulation)]]',
            ],
            # HeatingSystem
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem' => [
                'HeatingSystemType[Furnace|Boiler|ElectricResistance]',
                '[HeatingSystemFuel="natural gas" or HeatingSystemFuel="fuel oil" or HeatingSystemFuel="propane" or HeatingSystemFuel="electricity"]',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempHeatingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
            ],
            # HeatingSystem (Furnace/Boiler)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/Furnace or HeatingSystemType/Boiler]' => [
                'AnnualHeatingEfficiency[Units="AFUE"]/Value',
            ],
            # HeatingSystem (ElectricResistance)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem[HeatingSystemType/ElectricResistance]' => [
                'AnnualHeatingEfficiency[Units="Percent"]/Value',
            ],
            # CoolingSystem
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem' => [
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempCoolingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
                '[CoolingSystemType="central air conditioning" or CoolingSystemType="room air conditioner"]',
            ],
            # CoolingSystem (CentralAC)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="central air conditioning"]' => [
                'AnnualCoolingEfficiency[Units="SEER"]/Value',
            ],
            # CoolingSystem (RoomAC)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem[CoolingSystemType="room air conditioner"]' => [
                'AnnualCoolingEfficiency[Units="EER"]/Value',
            ],
            # HeatPump
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump' => [
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempHeatingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/SetpointTempCoolingSeason',
                '//Building/BuildingDetails/Systems/HVAC/HVACControl/ControlType',
                '[HeatPumpType="air-to-air" or HeatPumpType="mini-split" or HeatPumpType="ground-to-air"]',
            ],
            # HeatPump (AirSource/MiniSplit)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="air-to-air" or HeatPumpType="mini-split"]' => [
                'AnnualCoolingEfficiency[Units="SEER"]/Value',
                'AnnualCoolingEfficiency[Units="HSPF"]/Value',
            ],
            # HeatPump (GroundSource)
            '//Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump[HeatPumpType="ground-to-air"]' => [
                'AnnualCoolingEfficiency[Units="EER"]/Value',
                'AnnualCoolingEfficiency[Units="COP"]/Value',
            ],
            # WaterHeatingSystem
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem' => [
                '[WaterHeaterType="storage water heater" or WaterHeaterType="instantaneous water heater" or WaterHeaterType="heat pump water heater"]',
                'TankVolume',
                'HeatingCapacity',
                '[FuelType="natural gas" or FuelType="fuel oil" or FuelType="propane" or FuelType="electricity"]',
            ],
            # WaterHeatingSystem (FuelStorage)
            '//Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem[WaterHeaterType="storage water heater" and FuelType!="electricity"]' => [
                'RecoveryEfficiency',
            ],
            # HotWaterDistribution
            '//Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution' => [
                'SystemType',
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
                'RatedFlowRate',
                'HoursInOperation',
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
  
  def self.get_high_level_inputs(building)
  
    cfa = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea").to_f
    nbeds = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms").to_i
    nbaths = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms").to_i
    climate_zone = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC/ClimateZone")
    
    return cfa, nbeds, nbaths, climate_zone
  end

  def self.apply_reference_home_ruleset(building, cfa, nbeds, nbaths, climate_zone)
  
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")
    
    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_reference(new_summary, orig_details, nbeds)
    
    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")
    
    # Zones
    XMLHelper.copy_element(new_details, orig_details, "Zones")
    
    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    set_enclosure_attics_roofs_reference(new_enclosure, orig_details, climate_zone)
    set_enclosure_foundations_reference(new_enclosure, orig_details, climate_zone)
    set_enclosure_rim_joists_reference(new_enclosure)
    set_enclosure_walls_reference(new_enclosure, orig_details, climate_zone)
    set_enclosure_windows_reference(new_enclosure, orig_details, cfa, climate_zone)
    set_enclosure_skylights_reference(new_enclosure)
    set_enclosure_doors_reference(new_enclosure, climate_zone)
    
    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_reference(new_systems, orig_details)
    set_systems_mechanical_ventilation_reference(new_systems, orig_details)
    set_systems_water_heating_reference(new_systems, orig_details, nbeds, nbaths)
    
    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_reference(new_appliances, cfa, nbeds)
    set_appliances_clothes_dryer_reference(new_appliances, orig_details, cfa, nbeds)
    set_appliances_dishwasher_reference(new_appliances, cfa, nbeds)
    set_appliances_refrigerator_reference(new_appliances, cfa, nbeds)
    set_appliances_cooking_range_oven_reference(new_appliances, orig_details, cfa, nbeds)
    
    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_reference(new_lighting, orig_details, cfa, nbeds)
    set_lighting_ceiling_fans_reference(new_lighting)
    
    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_reference(new_misc_loads, cfa, nbeds)
    
  end
  
  def self.apply_rated_home_ruleset(building, cfa, nbeds, nbaths)
  
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")
    
    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_rated(new_summary, orig_details, nbeds)
    
    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")
    
    # Zones
    XMLHelper.copy_element(new_details, orig_details, "Zones")
    
    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_rated(new_enclosure, orig_details)
    set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    set_enclosure_foundations_rated(new_enclosure, orig_details)
    set_enclosure_rim_joists_rated(new_enclosure)
    set_enclosure_walls_rated(new_enclosure, orig_details)
    set_enclosure_windows_rated(new_enclosure, orig_details)
    set_enclosure_skylights_rated(new_enclosure, orig_details)
    set_enclosure_doors_rated(new_enclosure, orig_details)
    
    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_rated(new_systems, orig_details)
    set_systems_mechanical_ventilation_rated(new_systems, orig_details)
    set_systems_water_heating_rated(new_systems, orig_details, cfa, nbeds, nbaths)
    
    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_rated(new_appliances, orig_details, nbeds)
    set_appliances_clothes_dryer_rated(new_appliances, orig_details, nbeds)
    set_appliances_dishwasher_rated(new_appliances, orig_details, nbeds)
    set_appliances_refrigerator_rated(new_appliances, orig_details)
    set_appliances_cooking_range_oven_rated(new_appliances, orig_details, nbeds)
    
    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_rated(new_lighting, orig_details, cfa)
    set_lighting_ceiling_fans_rated(new_lighting)
    
    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_rated(new_misc_loads, cfa, nbeds)
    
  end
  
  def self.apply_index_adjustment_design_ruleset(building)
  
  end
  
  def self.set_summary_reference(new_summary, orig_details, nbeds)
  
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.add_element(new_site, "AzimuthOfFrontOfHome", 0)
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", get_shelter_coefficient())
    
    num_occ, heat_gain, sens, lat = get_occupants_heat_gain_sens_lat(nbeds)
    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", num_occ)
    extension = XMLHelper.add_element(new_occupancy, "extension")
    XMLHelper.add_element(extension, "HeatGainPerPerson", heat_gain)
    XMLHelper.add_element(extension, "FracSensible", sens)
    XMLHelper.add_element(extension, "FracLatent", lat)
    
    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "ResidentialFacilityType")
    XMLHelper.copy_element(new_construction, orig_construction, "BuildingHeight")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "AverageCeilingHeight")
    XMLHelper.copy_element(new_construction, orig_construction, "FloorToFloorHeight ")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBathrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "FinishedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofStoriesAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "BuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "FoundationType")
    XMLHelper.copy_element(new_construction, orig_construction, "AtticType")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
    XMLHelper.copy_element(new_construction, orig_construction, "GarageLocation")
    XMLHelper.copy_element(new_construction, orig_construction, "SpaceAboveGarage")
  end
  
  def self.set_summary_rated(new_summary, orig_details, nbeds)
  
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.copy_element(new_site, orig_site, "AzimuthOfFrontOfHome")
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", get_shelter_coefficient())
    
    num_occ, heat_gain, sens, lat = get_occupants_heat_gain_sens_lat(nbeds)
    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", num_occ)
    extension = XMLHelper.add_element(new_occupancy, "extension")
    XMLHelper.add_element(extension, "HeatGainPerPerson", heat_gain)
    XMLHelper.add_element(extension, "FracSensible", sens)
    XMLHelper.add_element(extension, "FracLatent", lat)
    
    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "ResidentialFacilityType")
    XMLHelper.copy_element(new_construction, orig_construction, "BuildingHeight")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "AverageCeilingHeight")
    XMLHelper.copy_element(new_construction, orig_construction, "FloorToFloorHeight ")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBathrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "FinishedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofStoriesAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "BuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "FoundationType")
    XMLHelper.copy_element(new_construction, orig_construction, "AtticType")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
    XMLHelper.copy_element(new_construction, orig_construction, "GarageLocation")
    XMLHelper.copy_element(new_construction, orig_construction, "SpaceAboveGarage")
  end
  
  def self.set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    extension = XMLHelper.add_element(new_infil, "extension")
    
    '''
    Table 4.2.2(1) - Air exchange rate
    Specific Leakage Area (SLA) = 0.00036 assuming no energy recovery and with energy loads calculated in 
    quadrature
    '''
    
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", 0.00036)
    
    '''
    Table 4.2.2(1) - Attics
    Type: vented with aperture = 1ft2 per 300 ft2 ceiling area

    Table 4.2.2(1) - Crawlspaces
    Type: vented with net free vent aperture = 1ft2 per 150 ft2 of crawlspace floor area.
    U-factor: from Table 4.2.2(2) for floors over unconditioned spaces or outdoor environment.
    '''
    
    # TODO: Use Attic/Foundation extensions instead?
    if not orig_details.elements['Enclosure/AtticAndRoof/Attics'].nil?
      XMLHelper.add_element(extension, "AtticSpecificLeakageArea", 1.0/300.0)
    end
    if not orig_details.elements['Enclosure/Foundations/FoundationType/Crawlspace'].nil?
      XMLHelper.add_element(extension, "CrawlspaceSpecificLeakageArea", 1.0/150.0)
    end

  end
  
  def self.set_enclosure_air_infiltration_rated(new_enclosure, orig_details)
    '''
    Table 4.2.2(1) - Air exchange rate
    For residences , without Whole-House Mechanical Ventilation Systems, the measured infiltration rate but 
    not less than 0.30 ach
    For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate combined 
    with the time-averaged Whole-House Mechanical Ventilation System rate,(f) which shall not be less than 
    0.03 x CFA + 7.5 x (Nbr+1) cfm and with energy loads calculated in quadrature
    '''
    
    new_infil = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AirInfiltration")
    
    whole_house_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    if whole_house_fan.nil?
      building_air_leakage = new_infil.elements["AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']"]
      nach = XMLHelper.get_value(building_air_leakage, "AirLeakage").to_f
      if nach < 0.30
        building_air_leakage.elements["AirLeakage"].text = 0.30
      end
    end
    
    '''
    Table 4.2.2(1) - Attics
    Same as Rated Home

    Table 4.2.2(1) - Crawlspaces
    Same as the Rated Home, but not less net free ventilation area than the Reference Home unless an approved 
    ground cover in accordance with 2012 IRC 408.3.1 is used, in which case, the same net free ventilation area 
    as the Rated Home down to a minimum net free vent area of 1ft2 per 1,500 ft2 of crawlspace floor area.
    '''
    # TODO
    
  end
  
  def self.set_enclosure_attics_roofs_reference(new_enclosure, orig_details, climate_zone)
  
    attic_roof = XMLHelper.add_element(new_enclosure, "AtticAndRoof")
    
    '''
    Table 4.2.2(1) - Roofs
    Type: composition shingle on wood sheathing
    Gross area: same as Rated Home
    Solar absorptance = 0.75
    Emittance = 0.90
    '''
    
    new_roofs = XMLHelper.add_element(attic_roof, "Roofs")
    orig_details.elements.each("Enclosure/AtticAndRoof/Roofs/Roof") do |orig_roof|
      # Create new roof
      new_roof = XMLHelper.add_element(new_roofs, "Roof")
      XMLHelper.copy_element(new_roof, orig_roof, "SystemIdentifier")
      XMLHelper.copy_element(new_roof, orig_roof, "AttachedToSpace")
      XMLHelper.add_element(new_roof, "RoofType", "shingles")
      XMLHelper.add_element(new_roof, "DeckType", "wood")
      XMLHelper.copy_element(new_roof, orig_roof, "Pitch")
      XMLHelper.copy_element(new_roof, orig_roof, "RoofArea")
      XMLHelper.add_element(new_roof, "RadiantBarrier", false)
      extension = XMLHelper.add_element(new_roof, "extension")
      XMLHelper.add_element(extension, "SolarAbsorptance", 0.75)
      XMLHelper.add_element(extension, "Emittance", 0.90)
    end
    
    '''
    Table 4.2.2(1) - Ceilings
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    # FIXME: Need to look out for conditioned attics, etc.?
    
    ufactor = get_reference_component_characteristics(climate_zone, "ceiling")
    
    new_attics = XMLHelper.add_element(attic_roof, "Attics")
    orig_details.elements.each("Enclosure/AtticAndRoof/Attics/Attic") do |orig_attic|
      # Create new attic
      new_attic = XMLHelper.add_element(new_attics, "Attic")
      XMLHelper.copy_element(new_attic, orig_attic, "SystemIdentifier")
      XMLHelper.copy_element(new_attic, orig_attic, "AttachedToSpace")
      XMLHelper.copy_element(new_attic, orig_attic, "AttachedToRoof")
      XMLHelper.copy_element(new_attic, orig_attic, "ExteriorAdjacentTo")
      XMLHelper.copy_element(new_attic, orig_attic, "InteriorAdjacentTo")
      XMLHelper.copy_element(new_attic, orig_attic, "AtticKneeWall")
      XMLHelper.add_element(new_attic, "AtticType", "vented attic")
      insulation = XMLHelper.add_element(new_attic, "AtticFloorInsulation")
      XMLHelper.copy_element(insulation, orig_attic, "AtticFloorInsulation/SystemIdentifier")
      XMLHelper.add_element(insulation, "InsulationGrade", 1)
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      XMLHelper.copy_element(new_attic, orig_attic, "Area")
    end
    
  end
  
  def self.set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")
    
    '''
    Table 4.2.2(1) - Roofs
    Type: Same as Rated Home
    Gross area: Same as Rated Home
    Solar absorptance = Values from Table 4.2.2(4) shall be used to determine solar absorptance except 
    where test data are provided for roof surface in accordance with ASTM Standards C-1549, E-1918, or 
    CRRC Method # 1.
    Emittance = Emittance values provided by the roofing manufacturer in accordance with ASTM Standard 
    C-1371 shall be used when available. In cases where the appropriate data are not known, same as the 
    Reference Home.
    '''
    
    new_attic_roof.elements.each("Roofs/Roof") do |new_roof|
      
      roof_color = XMLHelper.get_value(new_roof, "RoofColor")
      
      extension = new_roof.elements["extension"]
      if extension.nil?
        extension = XMLHelper.add_element(new_roof, "extension")
      end
      
      XMLHelper.delete_element(extension, "SolarAbsorptance")
      if roof_color == "reflective"
        XMLHelper.add_element(extension, "SolarAbsorptance", 0.20)
      elsif roof_color == "dark"
        XMLHelper.add_element(extension, "SolarAbsorptance", 0.92)
      elsif roof_color == "medium"
        XMLHelper.add_element(extension, "SolarAbsorptance", 0.75)
      elsif roof_color == "light"
        XMLHelper.add_element(extension, "SolarAbsorptance", 0.60)
      end
      XMLHelper.delete_element(extension, "Emittance")
      XMLHelper.add_element(extension, "Emittance", 0.90)
      
    end
    
    '''
    Table 4.2.2(1) - Ceilings
    Type: Same as Rated Home
    Gross area: Same as Rated Home
    U-Factor: Same as Rated Home
    '''
    # nop

  end
  
  def self.set_enclosure_foundations_reference(new_enclosure, orig_details, climate_zone)
    
    new_foundations = XMLHelper.add_element(new_enclosure, "Foundations")
    
    floor_ufactor = get_reference_component_characteristics(climate_zone, "floor")
    wall_ufactor = get_reference_component_characteristics(climate_zone, "basement_wall")
    slab_rvalue, slab_depth = get_reference_component_characteristics(climate_zone, "foundation")
          
    orig_details.elements.each("Enclosure/Foundations/Foundation") do |orig_foundation|
    
      new_foundation = XMLHelper.add_element(new_foundations, "Foundation")
      XMLHelper.copy_element(new_foundation, orig_foundation, "SystemIdentifier")
      XMLHelper.copy_element(new_foundation, orig_foundation, "AttachedToSpace")
      XMLHelper.copy_element(new_foundation, orig_foundation, "FoundationType")
      XMLHelper.copy_element(new_foundation, orig_foundation, "ThermalBoundary")
        
      '''
      Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      Type: wood frame
      Gross area: same as Rated Home
      U-Factor: from Table 4.2.2(2)
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      
      # FIXME: Need to check the floor is over unconditioned space or outdoors?
      
      orig_foundation.elements.each("FrameFloor") do |orig_floor|
        # Create new floor
        new_floor = XMLHelper.add_element(new_foundation, "FrameFloor")
        XMLHelper.copy_element(new_floor, orig_floor, "SystemIdentifier")
        XMLHelper.copy_element(new_floor, orig_floor, "Area")
        insulation = XMLHelper.add_element(new_floor, "Insulation")
        XMLHelper.copy_element(insulation, orig_floor, "Insulation/SystemIdentifier")
        XMLHelper.add_element(insulation, "InsulationGrade", 1)
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/floor_ufactor)
      end
  
      '''
      Table 4.2.2(1) - Conditioned basement walls
      Type: same as Rated Home
      Gross area: same as Rated Home
      U-Factor: from Table 4.2.2(2) with the insulation layer on the interior side of walls
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      
      # FIXME: Need to check if the foundation wall is adjacent to living space?
    
      orig_foundation.elements.each("FoundationWall") do |orig_wall|
        # Create new wall
        new_wall = XMLHelper.add_element(new_foundation, "FoundationWall")
        XMLHelper.copy_element(new_wall, orig_wall, "SystemIdentifier")
        XMLHelper.copy_element(new_wall, orig_wall, "Type")
        XMLHelper.copy_element(new_wall, orig_wall, "Length")
        XMLHelper.copy_element(new_wall, orig_wall, "Height")
        XMLHelper.copy_element(new_wall, orig_wall, "Area")
        XMLHelper.copy_element(new_wall, orig_wall, "BelowGradeDepth")
        XMLHelper.copy_element(new_wall, orig_wall, "AdjacentToFoundation")
        XMLHelper.copy_element(new_wall, orig_wall, "AdjacentTo")
        insulation = XMLHelper.add_element(new_wall, "Insulation")
        XMLHelper.copy_element(insulation, orig_wall, "Insulation/SystemIdentifier")
        XMLHelper.add_element(insulation, "InsulationGrade", 1)
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/wall_ufactor)
      end
  
      '''
      Table 4.2.2(1) - Foundations
      Type: same as Rated Home
      Gross Area: same as Rated Home
      U-Factor / R-value: from Table 4.2.2(2)
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      # FIXME: Need to check for SlabOnGrade foundation type?
    
      orig_foundation.elements.each("Slab") do |orig_slab|
        # Create new slab
        new_slab = XMLHelper.add_element(new_foundation, "Slab")
        XMLHelper.copy_element(new_slab, orig_slab, "SystemIdentifier")
        XMLHelper.copy_element(new_slab, orig_slab, "Area")
        XMLHelper.copy_element(new_slab, orig_slab, "Perimeter")
        XMLHelper.copy_element(new_slab, orig_slab, "ExposedPerimeter")
        XMLHelper.add_element(new_slab, "PerimeterInsulationDepth", slab_depth)
        XMLHelper.copy_element(new_slab, orig_slab, "OnGradeExposedPerimeter")
        XMLHelper.copy_element(new_slab, orig_slab, "DepthBelowGrade")
        XMLHelper.add_element(new_slab, "FloorCovering", "carpet")
        insulation = XMLHelper.add_element(new_slab, "PerimeterInsulation")
        XMLHelper.copy_element(insulation, orig_slab, "PerimeterInsulation/SystemIdentifier")
        XMLHelper.add_element(insulation, "InsulationGrade", 1)
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", slab_rvalue)
        extension = XMLHelper.add_element(new_slab, "extension")
        XMLHelper.add_element(extension, "FloorCoveringFraction", 0.8)
        XMLHelper.add_element(extension, "FloorCoveringRValue", 2.0)
      end
      
    end
    
  end
  
  def self.set_enclosure_foundations_rated(new_enclosure, orig_details)
    
    new_foundations = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Foundations")
    
    '''
    Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
    Type: Same as Rated Home
    Gross area: Same as Rated Home
    U-Factor: Same as Rated Home
    '''
    # nop

    '''
    Table 4.2.2(1) - Conditioned basement walls
    Type: Same as Rated Home
    Gross area: Same as Rated Home
    U-Factor: Same as Rated Home
    '''
    # nop
    
    '''
    Table 4.2.2(1) - Foundations
    Type: Same as Rated Home
    Gross Area: Same as Rated Home
    U-Factor / R-value: Same as Rated Home
    '''
    # nop

  end
  
  def self.set_enclosure_rim_joists_reference(new_enclosure)
    # FIXME
  end
  
  def self.set_enclosure_rim_joists_rated(new_enclosure)
    # FIXME
  end

  def self.set_enclosure_walls_reference(new_enclosure, orig_details, climate_zone)
  
    '''
    Table 4.2.2(1) - Above-grade walls
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    Solar absorptance = 0.75
    Emittance = 0.90
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    # FIXME: Need to check wall is between living space and outside/unconditioned space?
    
    ufactor = get_reference_component_characteristics(climate_zone, "frame_wall")
    
    new_walls = XMLHelper.add_element(new_enclosure, "Walls")
    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      # Create new wall
      new_wall = XMLHelper.add_element(new_walls, "Wall")
      XMLHelper.copy_element(new_wall, orig_wall, "SystemIdentifier")
      XMLHelper.copy_element(new_wall, orig_wall, "AttachedToSpace")
      XMLHelper.copy_element(new_wall, orig_wall, "ExteriorAdjacentTo")
      XMLHelper.copy_element(new_wall, orig_wall, "InteriorAdjacentTo")
      XMLHelper.add_element(new_wall, "WallType/WoodStud")
      XMLHelper.copy_element(new_wall, orig_wall, "Area")
      insulation = XMLHelper.add_element(new_wall, "Insulation")
      XMLHelper.copy_element(insulation, orig_wall, "Insulation/SystemIdentifier")
      XMLHelper.add_element(insulation, "InsulationGrade", 1)
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      extension = XMLHelper.add_element(new_wall, "extension")
      XMLHelper.add_element(extension, "SolarAbsorptance", 0.75)
      XMLHelper.add_element(extension, "Emittance", 0.90)
    end
    
  end
  
  def self.set_enclosure_walls_rated(new_enclosure, orig_details)
  
    new_walls = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Walls")
  
    '''
    Table 4.2.2(1) - Above-grade walls
    Type: Same as Rated Home
    Gross area: Same as Rated Home
    U-Factor: Same as Rated Home
    Solar absorptance = Same as Rated Home
    Emittance = Same as Rated Home
    '''
    # nop
    
  end

  def self.set_enclosure_windows_reference(new_enclosure, orig_details, cfa, climate_zone)
    
    '''
    Table 4.2.2(1) - Glazing
    Total area = 18% of CFA
    Orientation: equally distributed to four (4) cardinal compass orientations (N,E,S,&W)
    U-factor: from Table 4.2.2(2)
    SHGC: from Table 4.2.2(2)    
    External shading: none
    
    (b) For one- and two-family dwellings with conditioned basements and dwelling units in residential 
    buildings not over three stories in height above grade containing multiple dwelling units the following 
    formula shall be used to determine total window area:
      AG = 0.18 x CFA x FA x F
      where:
        AG = Total glazing area
        CFA = Total Conditioned Floor Area
        FA = (gross above-grade thermal boundary wall area) / (gross above-grade thermal boundary wall area + 
             0.5*gross below-grade thermal boundary wall area)
        F = 1- 0.44* (gross common wall Area) / (gross above-grade thermal boundary wall area + gross common 
            wall area)
      and where:
        Thermal boundary wall is any wall that separates Conditioned Space from Unconditioned Space, outdoor 
        environment or the surrounding soil.
        Above-grade thermal boundary wall is any portion of a thermal boundary wall not in contact with soil.
        Below-grade thermal boundary wall is any portion of a thermal boundary wall in soil contact
        Common wall is the total wall area of walls adjacent to another conditioned living unit, not including 
        foundation walls.
    
    4.3.7. Natural Ventilation. Natural ventilation shall be assumed in both the Reference and Rated Homes 
    during hours when natural ventilation will reduce annual cooling energy use.
    '''

    ufactor, shgc = get_reference_component_characteristics(climate_zone, "window")
    
    ag_wall_area = 0.0
    bg_wall_area = 0.0
    
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      int_adj_to = XMLHelper.get_value(wall, "InteriorAdjacentTo")
      ext_adj_to = XMLHelper.get_value(wall, "ExteriorAdjacentTo")
      next if not ((int_adj_to == "living space" or ext_adj_to == "living space") and int_adj_to != ext_adj_to)
      area = XMLHelper.get_value(wall, "Area").to_f
      ag_wall_area += area
    end
    
    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement/Conditioned='true']/FoundationWall") do |fwall|
      adj_to = XMLHelper.get_value(fwall, "AdjacentTo")
      next if adj_to == "living space"
      height = XMLHelper.get_value(fwall, "Height").to_f
      bg_depth = XMLHelper.get_value(fwall, "BelowGradeDepth").to_f
      area = XMLHelper.get_value(fwall, "Area").to_f
      ag_wall_area += (height - bg_depth) / height * area
      bg_wall_area += bg_depth / height * area
    end
    
    fa = ag_wall_area / (ag_wall_area + 0.5 * bg_wall_area)
    f = 1.0 # TODO
    
    # Remove all windows
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")
    for orientation, azimuth in {"north"=>0,"south"=>180,"east"=>90,"west"=>270}
      # Create new window
      new_window = XMLHelper.add_element(new_windows, "Window")
      sys_id = XMLHelper.add_element(new_window, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Window_#{orientation}")
      XMLHelper.add_element(new_window, "Area", 0.18 * 0.25 * cfa * fa * f)
      XMLHelper.add_element(new_window, "Azimuth", azimuth)
      XMLHelper.add_element(new_window, "UFactor", ufactor)
      XMLHelper.add_element(new_window, "SHGC", shgc)
      XMLHelper.add_element(new_window, "NFRCCertified", true)
      XMLHelper.add_element(new_window, "ExteriorShading", "none")
      XMLHelper.add_element(new_window, "Operable", true)
      set_window_interior_shading_reference(new_window)
    end

  end
  
  def self.set_window_interior_shading_reference(window)
    '''
    Table 4.2.2(1) - Glazing
    Interior shade coefficient: Summer = 0.70; Winter = 0.85
    '''
    
    extension = window.elements["extension"]
    if extension.nil?
      extension = XMLHelper.add_element(window, "extension")
    end
    XMLHelper.delete_element(extension, "InteriorShadingFactorSummer")
    XMLHelper.add_element(extension, "InteriorShadingFactorSummer", 0.70)
    XMLHelper.delete_element(extension, "InteriorShadingFactorWinter")
    XMLHelper.add_element(extension, "InteriorShadingFactorWinter", 0.85)
    
  end
  
  def self.set_enclosure_windows_rated(new_enclosure, orig_details)
  
    new_windows = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Windows")
  
    '''
    Table 4.2.2(1) - Glazing
    Total area = Same as Rated Home
    Orientation: Same as Rated Home
    U-factor: Same as Rated Home
    SHGC: Same as Rated Home
    Interior shade coefficient: Same as HERS Reference Home
    External shading: Same as Rated Home
    
    4.3.7. Natural Ventilation. Natural ventilation shall be assumed in both the Reference and Rated Homes 
    during hours when natural ventilation will reduce annual cooling energy use.
    '''
    
    new_windows.elements.each("Window") do |new_window|
      new_window.elements["Operable"].text = true
      set_window_interior_shading_reference(new_window)
    end
    
  end

  def self.set_enclosure_skylights_reference(enclosure)
  
    '''
    Table 4.2.2(1) - Skylights
    None
    '''
    # nop
    
  end
  
  def self.set_enclosure_skylights_rated(new_enclosure, orig_details)
  
    new_skylights = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Skylights")

    '''
    Table 4.2.2(1) - Skylights
    Same as Rated Home
    '''
    # nop
    
  end

  def self.set_enclosure_doors_reference(new_enclosure, climate_zone)

    '''
    Table 4.2.2(1) - Doors
    Area: 40 ft2
    U-factor: same as fenestration from Table 4.2.2(2)
    Orientation: North
    '''
    
    ufactor, shgc = get_reference_component_characteristics(climate_zone, "door")
    
    # Create new door
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
    new_door = XMLHelper.add_element(new_doors, "Door")
    sys_id = XMLHelper.add_element(new_door, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Door")
    XMLHelper.add_element(new_door, "Area", 40)
    XMLHelper.add_element(new_door, "Azimuth", 0)
    XMLHelper.add_element(new_door, "DoorType", "exterior")
    XMLHelper.add_element(new_door, "RValue", 1.0/ufactor)
    
  end
  
  def self.set_enclosure_doors_rated(new_enclosure, orig_details)
  
    new_doors = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Doors")
  
    '''
    Table 4.2.2(1) - Doors
    Area: Same as Rated Home
    U-factor: Same as Rated Home
    Orientation: Same as Rated Home
    '''
    # nop
    
  end
  
  def self.set_systems_hvac_reference(new_systems, orig_details)
  
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")
  
    '''
    Table 4.2.2(1) - Heating systems
    Fuel type: same as Rated Home
    Efficiencies:
    - Electric: air source heat pump in accordance with Table 4.2.2(1a)
    - Non-electric furnaces: natural gas furnace in accordance with Table 4.2.2(1a)
    - Non-electric boilers: natural gas boiler in accordance with Table 4.2.2(1a)
    - Capacity: sized in accordance with Section 4.3.3.1.
    
    Table 4.2.2(1) - Cooling systems
    Fuel type: Electric
    Efficiency: in accordance with Table 4.2.2(1a)
    Capacity: sized in accordance with Section 4.3.3.1.
    
    (i) For a Rated Home with multiple heating, cooling, or water heating systems using different fuel types, 
    the applicable system capacities and fuel types shall be weighted in accordance with the loads 
    distribution (as calculated by accepted engineering practice for that equipment and fuel type) of the 
    subject multiple systems.
    
    (k) For a Rated Home without a heating system, a gas heating system with the efficiency provided in Table 
    4.2.2(1a) shall be assumed for both the HERS Reference Home and Rated Home. For a Rated home that has 
    no access to natural gas or fossil fuel delivery, an air-source heat pump with the efficiency provided 
    in Table 4.2.2(1a) shall be assumed for both the HERS Reference Home and Rated Home.
    
    (m) For a Rated Home without a cooling system, an electric air conditioner with the efficiency provided in 
    Table 4.2.2(1a) shall be assumed for both the HERS Reference Home and the Rated Home.
    
    4.3.4. Air Source Heat Pumps. For heat pumps and air conditioners where
    a detailed, hourly HVAC simulation is used to separately model the 
    compressor and evaporator energy (including part-load performance), the 
    back-up heating energy, the distribution fan or blower energy and crank 
    case heating energy, the Manufacturers Equipment Performance Rating 
    (HSPF and SEER) shall be modified as follows to represent the performance
    of the compressor and evaporator components alone: HSPF, corr = HSPF, mfg / 0.582
    and SEER, corr = SEER, mfg / 0.941. The energy uses of all components 
    (i.e. compressor and distribution fan/blower; and crank case heater) shall 
    then be added together to obtain the total energy uses for heating and cooling.
    '''
    
    # Init
    has_boiler = false
    fuel_type = nil
    has_fuel_access = (XMLHelper.get_value(orig_details, "BuildingSummary/extension/HasNaturalGasAccessOrFuelDelivery") == "true")
    
    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    if not heating_system.nil?
      has_boiler = XMLHelper.has_element(heating_system, "HeatingSystemType/Boiler")
      fuel_type = XMLHelper.get_value(heating_system, "HeatingSystemFuel")
    elsif not heat_pump_system.nil?
      fuel_type = 'electricity'
    end
    
    # FIXME: Add PrimarySystems
    
    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")
    if fuel_type == 'eletricity' or not has_fuel_access
    
      # 7.7 HSPF air source heat pump
      heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
      cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", 7.7)
      extension = XMLHelper.add_element(heat_pump, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941)
      XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582)
      
    else
    
      if has_boiler
      
        # 80% AFUE gas boiler
        heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
        boiler = XMLHelper.add_element(sys_type, "Boiler")
        XMLHelper.add_element(boiler, "BoilerType", "hot water")
        XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
        heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.add_element(heat_eff, "Units", "AFUE")
        XMLHelper.add_element(heat_eff, "Value", 0.80)
        
      else
      
        # 78% AFUE gas furnace
        heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
        furnace = XMLHelper.add_element(sys_type, "Furnace")
        XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
        heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.add_element(heat_eff, "Units", "AFUE")
        XMLHelper.add_element(heat_eff, "Value", 0.78)
        
      end
      
      # 13 SEER electric air conditioner
      cool_sys = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cool_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      XMLHelper.add_element(cool_sys, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cool_sys, "CoolingSystemFuel", "electricity")
      cool_eff = XMLHelper.add_element(cool_sys, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      extension = XMLHelper.add_element(cool_sys, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941)

    end
    
    '''
    Table 303.4.1(1) - Thermostat
    Type: manual
    Temperature setpoints: heating temperature set point = 68 F
    Temperature setpoints: cooling temperature set point = 78 F
    '''
    
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.add_element(new_hvac_control, "ControlType", "manual thermostat")
    XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
    XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
    
    '''
    Table 4.2.2(1) - Thermal distribution systems
    Thermal distribution system efficiency (DSE) of 0.80 shall be applied to both the heating and 
    cooling system efficiencies
    '''

    new_hvac_dist = XMLHelper.add_element(new_hvac, "HVACDistribution")
    sys_id = XMLHelper.add_element(new_hvac_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACDistribution")
    XMLHelper.add_element(new_hvac_dist, "AnnualHeatingDistributionSystemEfficiency", 0.8)
    XMLHelper.add_element(new_hvac_dist, "AnnualCoolingDistributionSystemEfficiency", 0.8)
    
  end
  
  def self.set_systems_hvac_rated(new_systems, orig_details)
  
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")
  
    '''
    Table 4.2.2(1) - Heating systems
    Fuel type: Same as Rated Home
    Efficiencies:
    - Electric: Same as Rated Home
    - Non-electric furnaces: Same as Rated Home
    - Non-electric boilers: Same as Rated Home
    - Capacity: Same as Rated Home
    
    Table 4.2.2(1) - Cooling systems
    Fuel type: Same as Rated Home
    Efficiency: Same as Rated Home
    Capacity: Same as Rated Home
    
    (i) For a Rated Home with multiple heating, cooling, or water heating systems using different fuel types, 
    the applicable system capacities and fuel types shall be weighted in accordance with the loads 
    distribution (as calculated by accepted engineering practice for that equipment and fuel type) of the 
    subject multiple systems.
    
    (k) For a Rated Home without a heating system, a gas heating system with the efficiency provided in Table 
    4.2.2(1a) shall be assumed for both the HERS Reference Home and Rated Home. For a Rated home that has 
    no access to natural gas or fossil fuel delivery, an air-source heat pump with the efficiency provided 
    in Table 4.2.2(1a) shall be assumed for both the HERS Reference Home and Rated Home.
    
    (m) For a Rated Home without a cooling system, an electric air conditioner with the efficiency provided in 
    Table 4.2.2(1a) shall be assumed for both the HERS Reference Home and the Rated Home.
    
    4.3.4. Air Source Heat Pumps. For heat pumps and air conditioners where
    a detailed, hourly HVAC simulation is used to separately model the 
    compressor and evaporator energy (including part-load performance), the 
    back-up heating energy, the distribution fan or blower energy and crank 
    case heating energy, the Manufacturers Equipment Performance Rating 
    (HSPF and SEER) shall be modified as follows to represent the performance
    of the compressor and evaporator components alone: HSPF, corr = HSPF, mfg / 0.582
    and SEER, corr = SEER, mfg / 0.941. The energy uses of all components 
    (i.e. compressor and distribution fan/blower; and crank case heater) shall 
    then be added together to obtain the total energy uses for heating and cooling.
    '''
    
    has_fuel_access = (XMLHelper.get_value(orig_details, "BuildingSummary/extension/HasNaturalGasAccessOrFuelDelivery") == "true")
    
    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    cooling_system = orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"]
    
    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")
    if heating_system.nil? and heat_pump_system.nil?
    
      if not has_fuel_access
      
        # 7.7 HSPF air source heat pump
        heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
        sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatPump")
        XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
        cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolEfficiency")
        XMLHelper.add_element(cool_eff, "Units", "SEER")
        XMLHelper.add_element(cool_eff, "Value", 13.0)
        heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatEfficiency")
        XMLHelper.add_element(heat_eff, "Units", "HSPF")
        XMLHelper.add_element(heat_eff, "Value", 7.7)
        extension = XMLHelper.add_element(heat_pump, "extension")
        XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941)
        XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582)
        cooling_system = heat_pump
        
      else
        
        # 78% AFUE gas furnace
        heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
        furnace = XMLHelper.add_element(sys_type, "Furnace")
        XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
        heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.add_element(heat_eff, "Units", "AFUE")
        XMLHelper.add_element(heat_eff, "Value", 0.78)
        
      end
      
    else
    
      # Retain heating system
      heating_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HeatingSystem")
      heat_pump_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HeatPump")
      if not heat_pump_system.nil?
        extension = heat_pump_system.elements["extension"]
        if extension.nil?
          extension = XMLHelper.add_element(heat_pump_system, "extension")
        end
        XMLHelper.delete_element(extension, "PerformanceAdjustmentSEER")
        XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941)
        XMLHelper.delete_element(extension, "PerformanceAdjustmentHSPF")
        XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582)
      end
      
    end
    
    if cooling_system.nil?
    
      # 13 SEER electric air conditioner
      cool_sys = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cool_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      XMLHelper.add_element(cool_sys, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cool_sys, "CoolingSystemFuel", "electricity")
      cool_eff = XMLHelper.add_element(cool_sys, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      extension = XMLHelper.add_element(cool_sys, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941)
    
    else
    
      # Retain cooling system
      cooling_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/CoolingSystem")
      extension = cooling_system.elements["extension"]
      if extension.nil?
        extension = XMLHelper.add_element(cooling_system, "extension")
      end
      XMLHelper.delete_element(extension, "PerformanceAdjustmentSEER")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941)
      XMLHelper.delete_element(extension, "PerformanceAdjustmentHSPF")
      XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582)
    
    end

    '''
    Table 303.4.1(1) - Thermostat
    Type: Same as Rated Home
    Temperature setpoints: same as the HERS Reference Home, except as required by Section 4.3.1
    
    4.3.1. Programmable Thermostats. Where programmable offsets are available in the Rated Home, 2F 
    temperature control point offsets with an 11 p.m. to 5:59 a.m. schedule for heating and a 9 a.m. 
    to 2:59 p.m. schedule for cooling, and with no offsets assumed for the Reference Home;
    '''
    
    has_programmable_tstat = false
    control_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HVACControl/ControlType")
    if control_type == "programmable thermostat"
      has_programmable_tstat = true
    end
    
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
    XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
    if has_programmable_tstat
      offset = 2 # F
      XMLHelper.add_element(new_hvac_control, "SetbackTempHeatingSeason", 68-offset)
      XMLHelper.add_element(new_hvac_control, "SetupTempCoolingSeason", 78+offset)
      XMLHelper.add_element(new_hvac_control, "TotalSetbackHoursperWeekHeating", 7*7) # 11 p.m. to 5:59 a.m., 7 days a week
      XMLHelper.add_element(new_hvac_control, "TotalSetupHoursperWeekCooling", 6*7) # 9 a.m. to 2:59 p.m., 7 days a week
      extension = XMLHelper.add_element(new_hvac_control, "extension")
      XMLHelper.add_element(extension, "SetbackStartHour", 23) # 11 p.m.
      XMLHelper.add_element(extension, "SetupCoolingStartHour", 9) # 9 a.m.
    end
    
    '''
    Table 4.2.2(1) - Thermal distribution systems
    For forced air distribution systems: Tested in accordance with Section 803 of the Mortgage Industry 
    National Home Energy Rating Systems Standards (o), and then either calculated through hourly simulation 
    or calculated in accordance with ASHRAE Standard 152-2004 with the ducts located and insulated as in 
    the Rated Home.
    For ductless distribution systems: DSE=1.00
    For hydronic distribution systems: DSE=1.00
    '''
    
    # Retain distribution system
    XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HVACDistribution")

  end
  
  def self.set_systems_mechanical_ventilation_reference(new_systems, orig_details)
    '''
    Table 4.2.2(1) - Whole-House Mechanical ventilation
    None, except where a mechanical ventilation system is specified by the Rated Home, in which case:
    Where Rated Home has supply-only or exhaust-only Whole-House Ventilation System:
    0.35*fanCFM*8.76 kWh/y
    Where Rated Home has balanced Whole-House Ventilation System without energy recovery:
    0.70* fanCFM*8.76 kWh/y
    Where Rated Home has balanced Whole-House Ventilation System with energy recovery:
    1.00*fanCFM*8.76 kWh/y
    And where fanCFM is calculated in accordance with Section 4.1.2 ASHRAE Standard 62.2-2013 for a 
    continuous Whole-House Ventilation System.
    '''
    
    # Init
    fan_type = nil
    fan_cfm = nil
    
    whole_house_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    
    if not whole_house_fan.nil?
      
      # FIXME: Review these interpretations:
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
      
      fan_type = XMLHelper.get_value(whole_house_fan, "FanType")
      fan_cfm = XMLHelper.get_value(whole_house_fan, "RatedFlowRate").to_f
      
      fan_power = nil
      if fan_type == 'supply only' or fan_type == 'exhaust only'
        fan_power = 0.35 * fan_cfm
      elsif fan_type == 'balanced' # FIXME: Not available in HPXML
        fan_power = 0.70 * fan_cfm
      elsif fan_type == 'energy recovery ventilator' or fan_type == 'heat recovery ventilator'
        fan_power = 1.00 * fan_cfm
        # FIXME: Uncomment below when HPXML allows balanced
        #fan_type = 'balanced' # Table 4.2.2(1) - Air exchange rate: "assuming no energy recovery"
      end
      
      new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
      new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
      new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
      sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
      XMLHelper.add_element(new_vent_fan, "FanType", fan_type)
      XMLHelper.add_element(new_vent_fan, "RatedFlowRate", fan_cfm)
      XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24)
      XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
      XMLHelper.add_element(new_vent_fan, "FanPower", fan_power)
      
    end
      
  end
  
  def self.set_systems_mechanical_ventilation_rated(new_systems, orig_details)
    '''
    Table 4.2.2(1) - Whole-House Mechanical ventilation
    Same as Rated Home
    
    Table 4.2.2(1) - Air exchange rate
    For residences with Whole-House Mechanical Ventilation Systems, the measured infiltration rate combined 
    with the time-averaged Whole-House Mechanical Ventilation System rate,(f) which shall not be less than 
    0.03 x CFA + 7.5 x (Nbr+1) cfm and with energy loads calculated in quadrature
    '''
    
    new_mech_vent = XMLHelper.copy_element(new_systems, orig_details, "Systems/MechanicalVentilation")

    if not new_mech_vent.elements["VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
      fan_cfm = XMLHelper.get_value(whole_house_fan, "RatedFlowRate").to_f
      new_mech_vent.elements["HoursInOperation"].text = 24
      # TODO
    end
    
  end
  
  def self.set_systems_water_heating_reference(new_systems, orig_details, nbeds, nbaths)
  
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")
  
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    Table 4.2.2(1) - Service water heating systems
    Fuel type: same as Rated Home
    Efficiency
    - Electric: EF = 0.97 - (0.00132 * store gal)
    - Fossil fuel: EF = 0.67 - (0.0019 * store gal)
    Tank temperature: 125 F
    
    (n) For a Rated Home with a non-storage type water heater, a 40-gallon storage-type water heater of the 
    same fuel as the proposed water heater shall be assumed for the HERS Reference Home. For a Rated 
    Home without a proposed water heater, a 40-gallon storage-type water heater of the same fuel as the 
    predominant fuel type used for the heating system(s) shall be assumed for both the Rated and HERS 
    Reference Homes. In both cases the Energy Factor of the water heater shall be as prescribed for water 
    heaters by CFR 430.32(d), published in the Federal Register/Volume 66, No. 11, Wednesday, January 17, 
    2001 for water heaters manufactured after January 20, 2004.
    '''
    
    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    wh_type = nil
    wh_tank_vol = nil
    wh_fuel_type = nil
    if not orig_wh_sys.nil?
      wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
      wh_tank_vol = XMLHelper.get_value(orig_wh_sys, "TankVolume").to_f
      wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
    end

    if orig_wh_sys.nil?
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
    elsif wh_type == 'instantaneous water heater'
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
    end
    
    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_capacity(Constants.Auto, to_beopt_fuel(wh_fuel_type), nbeds, nbaths) * 1000.0 # Btuh
    
    # New water heater
    new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
    XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
    XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
    XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
    XMLHelper.add_element(new_wh_sys, "HeatingCapacity", wh_cap)
    XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
    if not wh_re.nil?
      XMLHelper.add_element(new_wh_sys, "RecoveryEfficiency", wh_re)
    end
    XMLHelper.add_element(new_wh_sys, "HotWaterTemperature", 125)
    extension = XMLHelper.add_element(new_wh_sys, "extension")
    XMLHelper.add_element(extension, "PerformanceAdjustmentEnergyFactor", 1.0)
    
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.1.4 refWgpd = 9.8*Nbr^0.43 
                        = reference climate-normalized daily hot water waste due to distribution system 
                          losses in Reference Home (in gallons per day)
    '''
    
    ref_w_gpd = get_waste_gpd_reference(nbeds)
    
    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    extension = XMLHelper.add_element(new_hw_dist, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", ref_w_gpd)
    
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.1.4 refFgpd = 14.6 + 10.0*Nbr
                        = reference climate-normalized daily fixture water use in Reference Home (in 
                          gallons per day)
    '''
    
    ref_f_gpd = get_fixtures_gpd_reference(nbeds)
    
    # New water fixture
    new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
    sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
    XMLHelper.add_element(new_fixture, "WaterFixtureType", "other")
    extension = XMLHelper.add_element(new_fixture, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", ref_f_gpd)
    
  end
  
  def self.set_systems_water_heating_rated(new_systems, orig_details, cfa, nbeds, nbaths)
  
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")
  
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    Table 4.2.2(1) - Service water heating systems
    Fuel type: Same as Rated Home
    Efficiency: Same as Rated Home
    Tank temperature: Same as HERS Reference Home
    
    (n) For tankless water heaters, the Energy Factor (EF) shall be multiplied by 0.92 for Rated Home 
    calculations. For a Rated Home without a proposed water heater, a 40-gallon storage-type water heater 
    of the same fuel as the predominant fuel type used for the heating system(s) shall be assumed for both 
    the Rated and HERS Reference Homes. In both cases the Energy Factor of the water heater shall be as 
    prescribed for water heaters by CFR 430.32(d), published in the Federal Register/Volume 66, No. 11, 
    Wednesday, January 17, 2001 for water heaters manufactured after January 20, 2004.
    '''
    
    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]
    
    if not orig_wh_sys.nil?
      
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      wh_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/WaterHeaterType")
      wh_ef = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/EnergyFactor")
      
      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "SystemIdentifier")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FuelType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "WaterHeaterType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "TankVolume")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "HeatingCapacity")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "EnergyFactor")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "RecoveryEfficiency")
      XMLHelper.add_element(new_wh_sys, "HotWaterTemperature", 125)
      extension = XMLHelper.add_element(new_wh_sys, "extension")
      if XMLHelper.get_value(new_wh_sys, "WaterHeaterType") == 'instantaneous water heater'
        XMLHelper.add_element(extension, "PerformanceAdjustmentEnergyFactor", 0.92)
      else
        XMLHelper.add_element(extension, "PerformanceAdjustmentEnergyFactor", 1.0)
      end
      
    else
    
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
      wh_cap = Waterheater.calc_capacity(Constants.Auto, to_beopt_fuel(wh_fuel_type), nbeds, nbaths) * 1000.0 # Btuh
    
      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
      XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
      XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
      XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
      XMLHelper.add_element(new_wh_sys, "HeatingCapacity", wh_cap)
      XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
      if not wh_re.nil?
        XMLHelper.add_element(new_wh_sys, "RecoveryEfficiency", wh_re)
      end
      XMLHelper.add_element(new_wh_sys, "HotWaterTemperature", 125)
      extension = XMLHelper.add_element(new_wh_sys, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentEnergyFactor", 1.0)
      
    end
    
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.2.11 Service Hot Water Use.
    
    oWgpd = refWgpd * oFrac * (1-oCDeff) Eq. 4.2-12
    where
      oWgpd = daily standard operating condition waste hot water quantity
      oFrac = 0.25 = fraction of hot water waste from standard operating conditions
      oCDeff = Approved Hot Water Operating Condition Control Device effectiveness (default = 0.0)

    sWgpd = (refWgpd – refWgpd * oFrac) * pRatio * sysFactor Eq. 4.2-13
    where
      sWgpd = daily structural waste hot water quantity
      refWgpd = reference climate-normalized distribution system waste water use calculated in accordance with Section 4.2.2.5.1.4
      oFrac = 0.25 = fraction of hot water waste from standard operating conditions
      pRatio = hot water piping ratio
      where
        for Standard systems:
          pRatio = PipeL / refPipeL
          where
            PipeL = measured length of hot water piping from the hot water heater to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any)
            refPipeL = 2*(CFA/Nfl)0.5 + 10*Nfl + 5*Bsmt = hot water piping length for Reference Home
            where
              CFA = conditioned floor area
              Nfl = number of conditioned floor levels in the residence, including conditioned basements
              Bsmt = presence =1.0 or absence = 0.0 of an unconditioned basement in the residence
        for recirculation systems:
          pRatio = BranchL /10
          where
            BranchL = measured length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally
      sysFactor = hot water distribution system factor from Table 4.2.2.5.2.11(2)

    WDeff = distribution system water use effectiveness from Table 4.2.2.5.2.11(3)
    
    Feff = fixture effectiveness in accordance with Table 4.2.2.5.2.11(1)
    '''
    
    low_flow_fixtures = true
    orig_details.elements.each("Systems/WaterHeating/WaterFixture[WaterFixtureType!='other']") do |wf|
      if XMLHelper.get_value(wf, "FlowRate").to_f > 2.0
        low_flow_fixtures = false
      end
    end
    
    is_recirc = false
    if not orig_details.elements["Systems/WaterHeating/HotWaterDistribution/SystemType/Recirculation"].nil?
      is_recirc = true
    end
    
    bsmnt = 0.0
    if not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?
      bsmnt = 1.0
    end
    
    nfl = XMLHelper.get_value(orig_details, "BuildingSummary/BuildingConstruction/NumberofConditionedFloors").to_f
    
    pipe_ins_rvalue = XMLHelper.get_value(orig_details, "Systems/WaterHeating/HotWaterDistribution/PipeInsulation/PipeRValue")
    if pipe_ins_rvalue.nil?
      pipe_ins_rvalue = 0.0
    else
      pipe_ins_rvalue = pipe_ins_rvalue.to_f
    end
    
    sys_factor = 1.0
    if is_recirc and pipe_ins_rvalue == 0.0
      sys_factor = 1.11
    else
      sys_factor = 0.90
    end
    
    ref_w_gpd = get_waste_gpd_reference(nbeds)
    o_frac = 0.25
    o_cd_eff = 0.0
    
    pipe_l = XMLHelper.get_value(orig_details, "Systems/WaterHeating/HotWaterDistribution/extension/LongestPipeLength").to_f
    ref_pipe_l = 2.0 * (cfa / nfl)**0.5 + 10.0 * nfl + 5.0 * bsmnt
    p_ratio = pipe_l / ref_pipe_l
    
    o_w_gpd = ref_w_gpd * o_frac * (1.0 - o_cd_eff)
    s_w_gpd = (ref_w_gpd - ref_w_gpd * o_frac) * p_ratio * sys_factor
    
    wd_eff = 1.0
    if is_recirc
      wd_eff = 0.10
    end
    
    f_eff = 1.0
    if low_flow_fixtures
      f_eff = 0.95
    end
    
    rated_w_gpd = f_eff * (o_w_gpd + s_w_gpd * wd_eff)
    
    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    extension = XMLHelper.add_element(new_hw_dist, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", rated_w_gpd)

    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.2.11 Service Hot Water Use.
    refFgpd = reference climate-normalized daily fixture water use calculated in accordance with Section 4.2.2.5.1.4
    '''
    
    ref_f_gpd = get_fixtures_gpd_reference(nbeds)
    rated_f_gpd = f_eff * ref_f_gpd
    
    # New water fixture
    new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
    sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
    XMLHelper.add_element(new_fixture, "WaterFixtureType", "other")
    extension = XMLHelper.add_element(new_fixture, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", rated_f_gpd)

  end
  
  def self.set_appliances_clothes_washer_reference(new_appliances, cfa, nbeds)
  
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refCWgpd = reference clothes washer gallons per day
                         = (4.52*(164+46.5*Nbr))*((3*2.08+1.59)/(2.874*2.08+1.59))/365
    '''
  
    clothes_washer_kwh = 38.0 + 0.0 * cfa + 10.0 * nbeds
    clothes_washer_sens, clothes_washer_lat = get_clothes_washer_sens_lat()
    clothes_washer_gpd = (4.52 * (164.0 + 46.5 * nbeds)) * ((3.0 * 2.08 + 1.59)/(2.874 * 2.08 + 1.59)) / 365.0
    
    new_clothes_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    sys_id = XMLHelper.add_element(new_clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesWasher")
    extension = XMLHelper.add_element(new_clothes_washer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_washer_kwh)
    XMLHelper.add_element(extension, "FracSensible", clothes_washer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_washer_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", clothes_washer_gpd)
    
  end
  
  def self.set_appliances_clothes_washer_rated(new_appliances, orig_details, nbeds)
  
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.2.10 Clothes Washers. Clothes Washer annual energy use and daily hot water use for the Rated Home 
    shall be determined as follows.
    
    Annual energy use shall be calculated in accordance with Equation 4.2-9a.
    kWh/yr = ((LER/392)-((LER*($/kWh)-AGC)/(21.9825*($/kWh) - ($/therm))/392)*21.9825)*ACY (Eq. 4.2-9a)
    where:
      LER = Label Energy Rating (kWh/y) from the Energy Guide label
      $/kWh = Electric Rate from Energy Guide Label
      AGC = Annual Gas Cost from Energy Guide Label
      $/therm = Gas Rate from Energy Guide Label
      ACY = Adjusted Cycles per Year
    and where:
      ACY = NCY * ((3.0*2.08+1.59)/(CAPw*2.08+1.59))
      where:
        NCY = (3.0/2.847) * (164 + Nbr*46.5)
        CAPw = washer capacity in cubic feet from the manufacturer’s data or the CEC database1 or the EPA 
               Energy Star website 2 or the default value of 2.874 ft3
               
    Daily hot water use shall be calculated in accordance with Equation 4.2-9b.
    DHWgpd = 60 * therms/cyc * ACY / 365 (Eq 4.2-9b)
    where:
      therms/cyc = (LER * $/kWh - AGC) / (21.9825 * $/kWh - $/therm) / 392
    '''
    
    ler = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/EnergyRating").to_f
    elec_rate = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/ElectricRate").to_f
    gas_rate = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/GasRate").to_f
    agc = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/AnnualGasCost").to_f
    cap = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/Capacity").to_f
    
    ncy = (3.0 / 2.847) * (164 + nbeds * 46.5)
    acy = ncy * ((3.0 * 2.08 + 1.59) / (cap * 2.08 + 1.59)) #Adjusted Cycles per Year
    clothes_washer_kwh = ((ler / 392.0) - ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392.0) * 21.9825) * acy
    clothes_washer_sens, clothes_washer_lat = get_clothes_washer_sens_lat()
    clothes_washer_gpd = 60.0 * ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392.0) * acy / 365.0
    
    new_clothes_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    sys_id = XMLHelper.add_element(new_clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesWasher")
    extension = XMLHelper.add_element(new_clothes_washer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_washer_kwh)
    XMLHelper.add_element(extension, "FracSensible", clothes_washer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_washer_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", clothes_washer_gpd)

  end

  def self.set_appliances_clothes_dryer_reference(new_appliances, orig_details, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
  
    dryer_fuel = XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/FuelType")
    clothes_dryer_kwh = 524.0 + 0.0 * cfa + 149.0 * nbeds
    clothes_dryer_therm = 0.0
    if dryer_fuel != 'electricity'
      clothes_dryer_kwh = 41.0 + 0.0 * cfa + 11.7 * nbeds
      clothes_dryer_therm = 18.8 + 0.0 * cfa + 5.3 * nbeds
    end
    clothes_dryer_sens, clothes_dryer_lat = get_clothes_dryer_sens_lat()
    
    new_clothes_dryer = XMLHelper.add_element(new_appliances, "ClothesDryer")
    sys_id = XMLHelper.add_element(new_clothes_dryer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesDryer")
    XMLHelper.add_element(new_clothes_dryer, "FuelType", dryer_fuel)
    extension = XMLHelper.add_element(new_clothes_dryer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_dryer_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", clothes_dryer_therm)
    XMLHelper.add_element(extension, "FracSensible", clothes_dryer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_dryer_lat)
    
  end
  
  def self.set_appliances_clothes_dryer_rated(new_appliances, orig_details, nbeds)
  
    '''
    4.2.2.5.2.8. Clothes Dryers. Clothes Dryer annual energy use for the Rated Home shall be determined in 
    accordance with Equation 4.2-6.
    kWh/y = 12.5*(164+46.5*Nbr)*FU/EFdry*(CAPw/MEF- LER/392)/(0.2184*(CAPw*4.08+0.24)) (Eq 4.2-6)
    where:
      Nbr = Number of Bedrooms in home
      FU = Field Utilization factor =1.18 for timer controls or 1.04 for moisture sensing
      EFdry = Efficiency Factor of clothes dryer (lbs dry clothes/kWh) from the CEC database 8 or the 
              default value of 3.01.
      CAPw = Capacity of clothes washer (ft3) from the manufacturer’s data or the CEC database or the EPA 
             Energy Star website 9 or the default value of 2.874 ft3.
      MEF10 = Modified Energy Factor of clothes washer from the Energy Guide label or the default value of 
              0.817.
      LER = Labeled Energy Rating of clothes washer (kWh/y) from the Energy Guide label or the default 
            value of 704.
    
    For natural gas clothes dryers, annual energy use shall be determined in accordance with Equations 4.2-7a 
    and 4.2-7b.
    Therms/y = (result of Eq. 4.2-6)*3412*(1-0.07) *(3.01/EFdry-g)/100000 (Eq 4.2-7a)
    kWh/y = (result of Eq. 4.2-6)*0.07*(3.01/EFdry-g) (Eq 4.2-7b)
    where:
      EFdry-g = Efficiency Factor for gas clothes dryer from the CEC database1 or the default value of 2.67.
    '''
    
    dryer_fuel = XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/FuelType")
    ef_dry = XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/EfficiencyFactor").to_f
    has_timer_control = (XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/HasTimerControl") == "true")
    
    ler = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/EnergyRating").to_f
    cap = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/Capacity").to_f
    mef = XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/ModifiedEnergyFactor").to_f
    
    field_util_factor = nil
    if has_timer_control
      field_util_factor = 1.18
    else
      field_util_factor = 1.04
    end
    clothes_dryer_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / ef_dry) * ((cap / mef) - ler / 392.0) / (0.2184 * (cap * 4.08 + 0.24))
    clothes_dryer_therm = 0.0
    if dryer_fuel != 'electricity'
      clothes_dryer_therm = clothes_dryer_kwh * (3412.0/100000) * 0.93 * (3.01/ef_dry)
      clothes_dryer_kwh = clothes_dryer_kwh * 0.07 * (3.01/ef_dry)
    end
    clothes_dryer_sens, clothes_dryer_lat = get_clothes_dryer_sens_lat()
    
    new_clothes_dryer = XMLHelper.add_element(new_appliances, "ClothesDryer")
    sys_id = XMLHelper.add_element(new_clothes_dryer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesDryer")
    XMLHelper.add_element(new_clothes_dryer, "FuelType", dryer_fuel)
    extension = XMLHelper.add_element(new_clothes_dryer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_dryer_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", clothes_dryer_therm)
    XMLHelper.add_element(extension, "FracSensible", clothes_dryer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_dryer_lat)

  end

  def self.set_appliances_dishwasher_reference(new_appliances, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes

    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refDWgpd = reference dishwasher gallons per day
                         = ((88.4+34.9*Nbr)*8.16)/365
    '''
  
    dishwasher_kwh = 78.0 + 0.0 * cfa + 31.0 * nbeds
    dishwasher_sens, dishwasher_lat = get_dishwasher_sens_lat()
    dishwasher_gpd = ((88.4 + 34.9 * nbeds) * 8.16) / 365.0
    
    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    sys_id = XMLHelper.add_element(new_dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Dishwasher")
    extension = XMLHelper.add_element(new_dishwasher, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", dishwasher_kwh)
    XMLHelper.add_element(extension, "FracSensible", dishwasher_sens)
    XMLHelper.add_element(extension, "FracLatent", dishwasher_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", dishwasher_gpd)
    
  end
  
  def self.set_appliances_dishwasher_rated(new_appliances, orig_details, nbeds)
    '''
    4.2.2.5.2.9. Dishwashers. Dishwasher annual energy use for the Rated Home shall be determined in accordance with Equation 4.2-8a.
    kWh/y = [(86.3 + 47.73/EF)/215]*dWcpy (Eq 4.2-8a)
    where:
      EF = Labeled dishwasher energy factor
        or
      EF = 215/(labeled kWh/y)
      dWcpy = (88.4 + 34.9*Nbr)*12/dWcap
      where:
        dWcap = Dishwasher place setting capacity; Default = 12 settings for standard sized dishwashers and 8 place settings for compact dishwashers
      
      And the change (Δ) in daily hot water use (GPD – gallons per day) for dishwashers shall be calculated in accordance with Equation 4.2-8b.
      ΔGPDDW = [(88.4+34.9*Nbr)*8.16 - (88.4+34.9*Nbr)*12/dWcap*(4.6415*(1/EF) - 1.9295)]/365 (Eq 4.2-8b)
    '''
    
    cap = XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/Capacity").to_f
    ef = XMLHelper.get_value(orig_details, "Appliances/Dishwasher/EnergyFactor").to_f
    if ef.nil?
      rated_annual_kwh = XMLHelper.get_value(orig_details, "Appliances/Dishwasher/RatedAnnualkWh").to_f
      ef = 215.0 / rated_annual_kwh
    end
    dwcpy = (88.4 + 34.9 * nbeds) * (12.0 / cap)
    dishwasher_kwh = ((86.3 + 47.73 / ef) / 215) * dwcpy
    dishwasher_sens, dishwasher_lat = get_dishwasher_sens_lat()
    dishwasher_gpd = dwcpy * (4.6415 * (1.0 / ef) - 1.9295) / 365.0
  
    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    sys_id = XMLHelper.add_element(new_dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Dishwasher")
    extension = XMLHelper.add_element(new_dishwasher, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", dishwasher_kwh)
    XMLHelper.add_element(extension, "FracSensible", dishwasher_sens)
    XMLHelper.add_element(extension, "FracLatent", dishwasher_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", dishwasher_gpd)
    
  end

  def self.set_appliances_refrigerator_reference(new_appliances, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
  
    refrigerator_kwh = 637.0 + 0.0 * cfa + 18.0 * nbeds

    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
    
  end
  
  def self.set_appliances_refrigerator_rated(new_appliances, orig_details)
    '''
    4.2.2.5.2.5. Refrigerators. Refrigerator annual energy use for the Rated Home shall be determined from 
    either refrigerator Energy Guide labels or from age-based defaults in accordance with Table 
    4.2.2.5.2.5(1).
    '''
    
    refrigerator_kwh = XMLHelper.get_value(orig_details, "Appliances/Refrigerator/RatedAnnualkWh").to_f
    
    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
    
  end

  def self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
    
    # FIXME: How to handle different fuel types for CookingRange vs Oven?
    range_fuel = XMLHelper.get_value(orig_details, "Appliances/CookingRange/FuelType")
    oven_fuel = XMLHelper.get_value(orig_details, "Appliances/Oven/FuelType")
    
    cooking_range_kwh = 331.0 + 0.0 * cfa + 39.0 * nbeds
    cooking_range_therm = 0.0
    if range_fuel != 'electricity'
      cooking_range_kwh = 22.6 + 0.0 * cfa + 2.7 * nbeds
      cooking_range_therm = 22.6 + 0.0 * cfa + 2.7 * nbeds
    end
    cooking_range_sens, cooking_range_lat = get_cooking_range_sens_lat(range_fuel)
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "CookingRange")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CookingRange")
    XMLHelper.add_element(new_cooking_range, "FuelType", range_fuel)
    extension = XMLHelper.add_element(new_cooking_range, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", cooking_range_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", cooking_range_therm)
    XMLHelper.add_element(extension, "FracSensible", cooking_range_sens)
    XMLHelper.add_element(extension, "FracLatent", cooking_range_lat)
    
  end
  
  def self.set_appliances_cooking_range_oven_rated(new_appliances, orig_details, nbeds)
    '''
    4.2.2.5.2.7. Range/Oven. Range/Oven (cooking) annual energy use for the Rated Home shall be determined in accordance with Equations 4.2-5a through 4.2-5c, as appropriate.
    1) For electric cooking:
      kWh/y = BEF * OEF * (331 + 39*Nbr) (Eq 4.2-5a)
    2) For natural gas cooking:
      Therms/y = OEF*(22.6 + 2.7*Nbr) (Eq 4.2-5b)
     plus:
      kWh/y = 22.6 + 2.7*Nbr (Eq 4.2-5c)
    where:
      BEF= Burner Energy Factor = 0.91 for induction ranges and 1.0 otherwise.
      OEF = Oven Energy Factor = 0.95 for convection types and 1.0 otherwise
      Nbr = Number of Bedrooms
    '''
    
    # FIXME: How to handle different fuel types for CookingRange vs Oven?
    range_fuel = XMLHelper.get_value(orig_details, "Appliances/CookingRange/FuelType")
    oven_fuel = XMLHelper.get_value(orig_details, "Appliances/Oven/FuelType")
    range_is_induction = (XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/IsInduction") == "true")
    oven_is_convection = (XMLHelper.get_value(orig_details, "Appliances/Oven/extension/IsConvection") == "true")
    
    burner_ef = 1.0
    if range_is_induction
      burner_ef = 0.91
    end
    
    oven_ef = 1.0
    if oven_is_convection
      oven_ef = 0.95
    end
    
    cooking_range_kwh = burner_ef * oven_ef * (331 + 39.0 * nbeds)
    cooking_range_therm = 0.0
    if range_fuel != 'electricity'
      cooking_range_kwh = 22.6 + 2.7 * nbeds
      cooking_range_therm = oven_ef * (22.6 + 2.7 * nbeds)
    end
    cooking_range_sens, cooking_range_lat = get_cooking_range_sens_lat(range_fuel)
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "CookingRange")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CookingRange")
    XMLHelper.add_element(new_cooking_range, "FuelType", range_fuel)
    extension = XMLHelper.add_element(new_cooking_range, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", cooking_range_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", cooking_range_therm)
    XMLHelper.add_element(extension, "FracSensible", cooking_range_sens)
    XMLHelper.add_element(extension, "FracLatent", cooking_range_lat)
    
  end

  def self.set_lighting_reference(new_lighting, orig_details, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    4.2.2.5.1.3. Garage Lighting. Where the Rated Home includes an enclosed garage, 100 kWh/y shall be added
    to the energy use of the Reference Home to account for garage lighting.
    '''
    
    extension = XMLHelper.add_element(new_lighting, "extension")
    
    # Interior lighting
    interior_lighting_kwh = 455.0 + 0.80 * cfa + 0.0 * nbeds
    XMLHelper.add_element(extension, "AnnualInteriorkWh", interior_lighting_kwh)
    
    # Exterior lighting
    exterior_lighting_kwh = 100.0 + 0.05 * cfa + 0.0 * nbeds
    XMLHelper.add_element(extension, "AnnualExteriorkWh", exterior_lighting_kwh)
    
    # Garage lighting
    garage_lighting_kwh = 0.0
    if XMLHelper.get_value(orig_details, "BuildingSummary/BuildingConstruction/GaragePresent") == "true"
      garage_lighting_kwh = 100.0
    end
    XMLHelper.add_element(extension, "AnnualGaragekWh", garage_lighting_kwh)
    
  end
  
  def self.set_lighting_rated(new_lighting, orig_details, cfa)

    extension = XMLHelper.add_element(new_lighting, "extension")
    
    '''
    4.2.2.5.2.2. Interior Lighting. Interior lighting annual energy use in the Rated home shall be determined 
    in accordance with Equation 4.2-2:
    kWh/y = 0.8*[(4 - 3*qFFIL)/3.7]*(455 + 0.8*CFA) + 0.2*(455 + 0.8*CFA) (Eq 4.2-2)
    where:
    CFA = Conditioned Floor Area
    qFFIL = the ratio of the interior Qualifying Light Fixtures to all interior light fixtures in Qualifying
    Light Fixture Locations.
    For rating purposes, the Rated Home shall not have qFFIL less than 0.10 (10%).
    '''
    # Interior Lighting
    qFF_int = XMLHelper.get_value(orig_details, 'Lighting/LightingFractions/extension/QualifyingLightFixturesInterior').to_f
    interior_lighting_kwh = 0.8 * ((4.0 - 3.0 * qFF_int) / 3.7) * (455.0 + 0.8 * cfa) + 0.2 * (455.0 + 0.8 * cfa)
    XMLHelper.add_element(extension, "AnnualInteriorkWh", interior_lighting_kwh)
    
    '''
    4.2.2.5.2.3. Exterior Lighting. Exterior lighting annual energy use in the Rated home shall be determined 
    in accordance with Equation 4.2-3:
    kWh/y = (100 + 0.05*CFA)*(1-FFEL) + 0.25*(100 + 0 .05*CFA)*FFEL (Eq 4.2-3)
    where
    CFA = Conditioned Floor Area
    FFEL = Fraction of exterior fixtures that are Qualifying Light Fixtures
    '''
    # Exterior Lighting
    qFF_ext = XMLHelper.get_value(orig_details, 'Lighting/LightingFractions/extension/QualifyingLightFixturesExterior').to_f
    exterior_lighting_kwh = (100.0 + 0.05 * cfa) * (1.0 - qFF_ext) + 0.25 * (100.0 + 0.05 * cfa) * qFF_ext
    XMLHelper.add_element(extension, "AnnualExteriorkWh", exterior_lighting_kwh)
    
    '''
    4.2.2.5.2.4. Garage Lighting. For Rated homes with garages, garage annual lighting energy use in the Rated 
    home shall be determined in accordance with Equation 4.2-4:
    kWh = 100*(1-FFGL) + 25*FFGL (Eq 4.2-4)
    where:
    FFGL = Fraction of garage fixtures that are Qualifying Light Fixtures
    '''
    # Garage Lighting
    garage_lighting_kwh = 0.0
    if XMLHelper.get_value(orig_details, "BuildingSummary/BuildingConstruction/GaragePresent") == "true"
      qFF_grg = XMLHelper.get_value(orig_details, 'Lighting/LightingFractions/extension/QualifyingLightFixturesGarage').to_f
      garage_lighting_kwh = 100.0 * (1.0 - qFF_grg) + 25.0 * qFF_grg
    end
    XMLHelper.add_element(extension, "AnnualGaragekWh", garage_lighting_kwh)
    
  end

  def self.set_lighting_ceiling_fans_reference(new_lighting)
    '''
    4.2.2.5.1.4. Ceiling Fans. Where ceiling fans are included in the Rated Home they shall also be included
    in the Reference Home in accordance with the provisions of Section 4.2.2.5.2.11
    
    4.2.2.5.2.11. Ceiling Fans. If ceiling fans are included in the Rated home, they shall also be included 
    in the Reference home. The number of Bedrooms plus one (Nbr+1) ceiling fans shall be assumed in both the
    Reference Home and the Rated Home. A daily ceiling fan operating schedule equal to 10.5 full-load hours 
    shall be assumed in both the Reference Home and the Rated Home during months with an average outdoor 
    temperature greater than 63 oF. The cooling thermostat (but not the heating thermostat) shall be set up 
    by 0.5 oF in both the Reference and Rated Home during these months.
    
    The Reference Home shall use number of Bedrooms plus one (Nbr+1) Standard Ceiling Fans of 42.6 watts 
    each. The Rated Home shall use the Labeled Ceiling Fan Standardized Watts (LCFSW), also multiplied by 
    number of Bedrooms plus one (Nbr+1) fans to obtain total ceiling fan wattage for the Rated Home. The 
    Rated Home LCFSW shall be calculated in accordance with Equation 4.2-10.
    '''
    
    # FIXME
    
  end
  
  def self.set_lighting_ceiling_fans_rated(new_lighting)
    # FIXME
  end

  def self.set_misc_loads_reference(new_misc_loads, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
    
    # Residual MELs
    residual_mels_kwh = get_residual_mels_kwh(cfa, nbeds)
    residual_mels_sens, residual_mels_lat = get_residual_mels_sens_lat(cfa)
    residual_mels = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(residual_mels, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Residual_MELs")
    XMLHelper.add_element(residual_mels, "PlugLoadType", "other")
    residual_mels_load = XMLHelper.add_element(residual_mels, "Load")
    XMLHelper.add_element(residual_mels_load, "Units", "kWh/year")
    XMLHelper.add_element(residual_mels_load, "Value", residual_mels_kwh)
    extension = XMLHelper.add_element(residual_mels, "extension")
    XMLHelper.add_element(extension, "FracSensible", residual_mels_sens)
    XMLHelper.add_element(extension, "FracLatent", residual_mels_lat)
    
    # Televisions
    televisions_kwh = get_televisions_kwh(cfa, nbeds)
    television = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(television, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Television")
    XMLHelper.add_element(television, "PlugLoadType", "TV other")
    television_load = XMLHelper.add_element(television, "Load")
    XMLHelper.add_element(television_load, "Units", "kWh/year")
    XMLHelper.add_element(television_load, "Value", televisions_kwh)
    
  end
  
  def self.set_misc_loads_rated(new_misc_loads, cfa, nbeds)
    '''
    4.2.2.5.2.1. Residual MELs. Residual miscellaneous annual electric energy use in the Rated Home shall 
    be the same as in the HERS Reference Home and shall be calculated as 0.91*CFA.
    
    4.2.2.5.2.6. Televisions. Television annual energy use in the Rated Home shall be the same as television 
    energy use in the HERS Reference Home and shall be calculated as TVkWh/y = 413 + 69*Nbr, where Nbr is 
    the number of Bedrooms in the Rated Home.
    '''
    
    # Residual MELs
    residual_mels_kwh = get_residual_mels_kwh(cfa, nbeds)
    residual_mels_sens, residual_mels_lat = get_residual_mels_sens_lat(cfa)
    residual_mels = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(residual_mels, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Residual_MELs")
    XMLHelper.add_element(residual_mels, "PlugLoadType", "other")
    residual_mels_load = XMLHelper.add_element(residual_mels, "Load")
    XMLHelper.add_element(residual_mels_load, "Units", "kWh/year")
    XMLHelper.add_element(residual_mels_load, "Value", residual_mels_kwh)
    extension = XMLHelper.add_element(residual_mels, "extension")
    XMLHelper.add_element(extension, "FracSensible", residual_mels_sens)
    XMLHelper.add_element(extension, "FracLatent", residual_mels_lat)
    
    # Televisions
    televisions_kwh = get_televisions_kwh(cfa, nbeds)
    television = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(television, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Television")
    XMLHelper.add_element(television, "PlugLoadType", "TV other")
    television_load = XMLHelper.add_element(television, "Load")
    XMLHelper.add_element(television_load, "Units", "kWh/year")
    XMLHelper.add_element(television_load, "Value", televisions_kwh)
    
  end

  def self.get_reference_component_characteristics(climate_zone, component_type)
    '''
    Table 4.2.2(2) - Component Heat Transfer Characteristics for HERS Reference Home
    '''
    if component_type == "window" or component_type == "door"
      # Fenestration and Opaque Door U-Factor
      # Glazed Fene-stration Assembly SHGC
      if ["1A", "1B", "1C"].include? climate_zone
        return 1.2, 0.40
      elsif ["2A", "2B", "2C"].include? climate_zone
        return 0.75, 0.40
      elsif ["3A", "3B", "3C"].include? climate_zone
        return 0.65, 0.40
      elsif ["4A", "4B"].include? climate_zone
        return 0.40, 0.40
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"]
        return 0.35, 0.40
      else
        return nil
      end
    elsif component_type == "frame_wall"
      # Frame Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B"].include? climate_zone
        return 0.082
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C"].include? climate_zone
        return 0.060
      elsif ["7", "8"].include? climate_zone
        return 0.057
      else
        return nil
      end
    elsif component_type == "basement_wall"
      # Basement Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? climate_zone
        return 0.360
      elsif ["4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? climate_zone
        return 0.059
      else
        return nil
      end
    elsif component_type == "floor"
      # Floor Over Uncond-itioned Space U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C"].include? climate_zone
        return 0.064
      elsif ["3A", "3B", "3C", "4A", "4B"].include? climate_zone
        return 0.047
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? climate_zone
        return 0.033
      else
        return nil
      end
    elsif component_type == "ceiling"
      # Ceiling U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? climate_zone
        return 0.035
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? climate_zone
        return 0.030
      elsif ["6A", "6B", "6C", "7", "8"].include? climate_zone
        return 0.026
      else
        return nil
      end
    elsif component_type == "foundation"
      # Slab-on-Grade R-Value & Depth (ft)
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? climate_zone
        return 0.0, nil
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? climate_zone
        return 10.0, 2.0
      elsif ["6A", "6B", "6C", "7", "8"].include? climate_zone
        return 10.0, 4.0
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def self.get_fixtures_gpd_reference(nbeds)
    return 14.6 + 10.0 * nbeds
  end
  
  def self.get_waste_gpd_reference(nbeds)
    return 9.8 * (nbeds**0.43)
  end
  
  def self.get_clothes_washer_sens_lat()
    sens = 0.3 * 0.9
    lat = 0.3 * 0.1
    return sens, lat
  end
  
  def self.get_clothes_dryer_sens_lat()
    sens = 0.15 * 0.9
    lat = 0.15 * 0.1
    return sens, lat
  end
  
  def self.get_dishwasher_sens_lat()
    sens = 0.6 * 0.5
    lat = 0.6 * 0.5
    return sens, lat
  end
  
  def self.get_cooking_range_sens_lat(range_fuel)
    sens = 0.8 * 0.9
    lat = 0.8 * 0.1
    if range_fuel != 'electricity'
      sens = 0.8 * 0.8
      lat = 0.8 * 0.2
    end
    return sens, lat
  end
  
  def self.get_residual_mels_kwh(cfa, nbeds)
    return 0.0 + 0.91 * cfa + 0.0 * nbeds
  end
  
  def self.get_residual_mels_sens_lat(cfa)
    load_sens = 7.27 * cfa
    load_lat = 0.38 * cfa
    sens = load_sens/(load_sens + load_lat)
    lat = 1.0 - sens
    return sens, lat
  end
  
  def self.get_televisions_kwh(cfa, nbeds)
    return 413.0 + 0.0 * cfa + 69.0 * nbeds
  end
  
  def self.get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    ef = nil
    re = nil
    if wh_fuel_type == 'electricity'
      ef = 0.97 - (0.00132 * wh_tank_vol)
    else
      ef = 0.67 - (0.0019 * wh_tank_vol)
      if wh_fuel_type == 'natural gas' or wh_fuel_type == 'propane'
        re = 0.76
      elsif wh_fuel_type == 'fuel oil'
        re = 0.78
      end
    end
    return ef, re
  end
  
  def self.get_occupants_heat_gain_sens_lat(nbeds)
    '''
    Table 4.2.2(3). Internal Gains for HERS Reference Homes
    Occupants
    Sensible Gains (Btu/day) - 3716
    Latent Gains (Btu/day) - 2884
    
    Software tools shall use either the occupant gains provided above or similar temperature dependent values 
    generated by the software where the number of occupants equals the number of Bedrooms and occupants are 
    present in the home 16.5 hours per day.
    '''
    
    sens_gains = 3716
    lat_gains = 2884
    tot_gains = sens_gains + lat_gains
    
    num_occ = nbeds
    heat_gain = tot_gains/16.5 # Btu/person
    sens = sens_gains/tot_gains
    lat = lat_gains/tot_gains
    return num_occ, heat_gain, sens, lat
  end
  
  def self.get_shelter_coefficient()
    '''
    Either hourly calculations using the procedures given in the 2013 ASHRAE Handbook
    of Fundamentals (IP version), Chapter 16, page 16.25, Equation 51 using Shelter
    Class 4 or calculations yielding equivalent results shall be used to determine the
    energy loads resulting from infiltration in combination with Whole-House Mechanical
    Ventilation systems.
    '''
    return 0.5
  end
  
  def self.to_beopt_fuel(fuel)
    conv = {"natural gas"=>Constants.FuelTypeGas, 
            "fuel oil"=>Constants.FuelTypeOil, 
            "propane"=>Constants.FuelTypePropane, 
            "electricity"=>Constants.FuelTypeElectric}
    return conv[fuel]
  end
  
end
  