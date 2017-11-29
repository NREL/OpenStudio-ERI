require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/xmlhelper"
require "#{File.dirname(__FILE__)}/waterheater"
require "#{File.dirname(__FILE__)}/airflow"

class EnergyRatingIndex301Ruleset

  def self.apply_ruleset(hpxml_doc, calc_type, weather)
  
    building = hpxml_doc.elements["/HPXML/Building"]
    
    # Update XML type
    header = hpxml_doc.elements["//XMLTransactionHeaderInformation"]
    if header.elements["XMLType"].nil?
      header.elements["XMLType"].text = calc_type
    else
      header.elements["XMLType"].text += ", #{calc_type}"
    end
    
    # Set class variables
    @weather = weather
    @cfa = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    @nbeds = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    @nbaths = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms"))
    @ncfl = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors"))
    @ncfl_ag = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))
    @cvolume = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume"))
    @climate_zone = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2006']/ClimateZone")
        
    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
        apply_reference_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIRatedHome
        apply_rated_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIndexAdjustmentDesign
        apply_index_adjustment_design_ruleset(building)
    end
    
  end

  def self.apply_reference_home_ruleset(building)
  
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")
    
    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_reference(new_summary, orig_details)
    
    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")
    
    # Zones
    XMLHelper.copy_element(new_details, orig_details, "Zones")
    
    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    set_enclosure_attics_roofs_reference(new_enclosure, orig_details)
    set_enclosure_foundations_reference(new_enclosure, orig_details)
    set_enclosure_rim_joists_reference(new_enclosure)
    set_enclosure_walls_reference(new_enclosure, orig_details)
    set_enclosure_windows_reference(new_enclosure, orig_details)
    set_enclosure_skylights_reference(new_enclosure)
    set_enclosure_doors_reference(new_enclosure, orig_details)
    
    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_reference(new_systems, orig_details)
    set_systems_mechanical_ventilation_reference(new_systems, orig_details)
    set_systems_water_heating_reference(new_systems, orig_details)
    
    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_reference(new_appliances)
    set_appliances_clothes_dryer_reference(new_appliances, orig_details)
    set_appliances_dishwasher_reference(new_appliances)
    set_appliances_refrigerator_reference(new_appliances)
    set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
    
    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_reference(new_lighting, orig_details)
    set_lighting_ceiling_fans_reference(new_lighting)
    
    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_reference(new_misc_loads)
    
  end
  
  def self.apply_rated_home_ruleset(building)
  
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")
    
    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_rated(new_summary, orig_details)
    
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
    set_systems_water_heating_rated(new_systems, orig_details)
    
    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_rated(new_appliances, orig_details)
    set_appliances_clothes_dryer_rated(new_appliances, orig_details)
    set_appliances_dishwasher_rated(new_appliances, orig_details)
    set_appliances_refrigerator_rated(new_appliances, orig_details)
    set_appliances_cooking_range_oven_rated(new_appliances, orig_details)
    
    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_rated(new_lighting, orig_details)
    set_lighting_ceiling_fans_rated(new_lighting)
    
    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_rated(new_misc_loads)
    
  end
  
  def self.apply_index_adjustment_design_ruleset(building)
  
  end
  
  def self.set_summary_reference(new_summary, orig_details)
  
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.add_element(new_site, "AzimuthOfFrontOfHome", 0)
    XMLHelper.copy_element(new_site, orig_site, "FuelTypesAvailable")
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", get_shelter_coefficient())
    
    num_occ, heat_gain, sens, lat, hrs_per_day = get_occupants_heat_gain_sens_lat()
    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", num_occ)
    extension = XMLHelper.add_element(new_occupancy, "extension")
    XMLHelper.add_element(extension, "HeatGainBtuPerPersonPerHr", heat_gain)
    XMLHelper.add_element(extension, "PersonHrsPerDay", hrs_per_day)
    XMLHelper.add_element(extension, "FracSensible", sens)
    XMLHelper.add_element(extension, "FracLatent", lat)
    
    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBathrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
  end
  
  def self.set_summary_rated(new_summary, orig_details)
  
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
    XMLHelper.copy_element(new_site, orig_site, "AzimuthOfFrontOfHome")
    XMLHelper.copy_element(new_site, orig_site, "FuelTypesAvailable")
    extension = XMLHelper.add_element(new_site, "extension")
    XMLHelper.add_element(extension, "ShelterCoefficient", get_shelter_coefficient())
    
    num_occ, heat_gain, sens, lat, hrs_per_day = get_occupants_heat_gain_sens_lat()
    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.add_element(new_occupancy, "NumberofResidents", num_occ)
    extension = XMLHelper.add_element(new_occupancy, "extension")
    XMLHelper.add_element(extension, "HeatGainBtuPerPersonPerHr", heat_gain)
    XMLHelper.add_element(extension, "PersonHrsPerDay", hrs_per_day)
    XMLHelper.add_element(extension, "FracSensible", sens)
    XMLHelper.add_element(extension, "FracLatent", lat)
    
    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBathrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
  end
  
  def self.set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    
    '''
    Table 4.2.2(1) - Air exchange rate
    Specific Leakage Area (SLA) = 0.00036 assuming no energy recovery and with energy loads calculated in 
    quadrature
    '''
    
    sla = 0.00036
    
    # Convert to other forms
    nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)
    
    # nACH
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACHnatural")
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACHnatural")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", nach)
    
    # ACH50
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACH50")
    XMLHelper.add_element(new_infil_meas, "HousePressure", 50)
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACH")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", ach50)
    
    # ELA/SLA
    ela = sla * @cfa
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ELA_SLA")
    XMLHelper.add_element(new_infil_meas, "EffectiveLeakageArea", ela)
    extension = XMLHelper.add_element(new_infil, "extension")
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", sla)
    
    
    '''
    Table 4.2.2(1) - Attics
    Type: vented with aperture = 1ft2 per 300 ft2 ceiling area

    Table 4.2.2(1) - Crawlspaces
    Type: vented with net free vent aperture = 1ft2 per 150 ft2 of crawlspace floor area.
    U-factor: from Table 4.2.2(2) for floors over unconditioned spaces or outdoor environment.
    '''
    
    if orig_details.elements["Enclosure/AtticAndRoof/Attics/Attic[AtticType='unvented attic' or AtticType='vented attic']"]
      orig_details.elements["Enclosure/AtticAndRoof/Attics/Attic/AtticType"].text = "vented attic"
      XMLHelper.add_element(extension, "AtticSpecificLeakageArea", 1.0/300.0)
    end
    if orig_details.elements["Enclosure/Foundations/Foundation/FoundationType/Crawlspace"]
      orig_details.elements["Enclosure/Foundations/Foundation/FoundationType/Crawlspace/Vented"].text = true
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
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    orig_infil = orig_details.elements["Enclosure/AirInfiltration"]
    orig_mv = orig_details.elements["Systems/MechanicalVentilation"]
    
    whole_house_fan = nil
    if not orig_mv.nil?
      whole_house_fan = orig_mv.elements["VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    end
    nach = Float(XMLHelper.get_value(orig_infil, "AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
    if whole_house_fan.nil? and nach < 0.30
      nach = 0.30
    end
    
    # Convert to other forms
    sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
    ela = sla * @cfa
    ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)
    
    # nACH
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACHnatural")
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACHnatural")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", nach)
    
    # ACH50
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ACH50")
    XMLHelper.add_element(new_infil_meas, "HousePressure", 50)
    new_bldg_air_lkg = XMLHelper.add_element(new_infil_meas, "BuildingAirLeakage")
    XMLHelper.add_element(new_bldg_air_lkg, "UnitofMeasure", "ACH")
    XMLHelper.add_element(new_bldg_air_lkg, "AirLeakage", ach50)
    
    # ELA/SLA
    new_infil_meas = XMLHelper.add_element(new_infil, "AirInfiltrationMeasurement")
    sys_id = XMLHelper.add_element(new_infil_meas, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Infiltration_ELA_SLA")
    XMLHelper.add_element(new_infil_meas, "EffectiveLeakageArea", ela)
    extension = XMLHelper.add_element(new_infil, "extension")
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", sla)
    
    '''
    Table 4.2.2(1) - Attics
    Same as Rated Home

    Table 4.2.2(1) - Crawlspaces
    Same as the Rated Home, but not less net free ventilation area than the Reference Home unless an approved 
    ground cover in accordance with 2012 IRC 408.3.1 is used, in which case, the same net free ventilation area 
    as the Rated Home down to a minimum net free vent area of 1ft2 per 1,500 ft2 of crawlspace floor area.
    '''
    
    if orig_details.elements["Enclosure/AtticAndRoof/Attics/Attic[AtticType='vented attic']"]
      XMLHelper.copy_element(extension, orig_infil, "extension/AtticSpecificLeakageArea")
    end
    if orig_details.elements["Enclosure/Foundations/Foundation/FoundationType/Crawlspace[Vented='true']"]
      XMLHelper.copy_element(extension, orig_infil, "extension/CrawlspaceSpecificLeakageArea")
    end
    
  end
  
  def self.set_enclosure_attics_roofs_reference(new_enclosure, orig_details)
  
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")
    
    '''
    Table 4.2.2(1) - Ceilings
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    
    Table 4.2.2(1) - Roofs
    Type: composition shingle on wood sheathing
    Gross area: same as Rated Home
    Solar absorptance = 0.75
    Emittance = 0.90
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    ceiling_ufactor = get_reference_component_characteristics("ceiling")
    wall_ufactor = get_reference_component_characteristics("frame_wall")
    
    new_attic_roof.elements.each("Attics/Attic") do |new_attic|
      attic_type = XMLHelper.get_value(new_attic, "AtticType")
      interior_adjacent_to = attic_type
      
      # Roofs
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        new_roof.elements["RadiantBarrier"].text = false
        new_roof.elements["SolarAbsorptance"].text = 0.75
        new_roof.elements["Emittance"].text = 0.90
        exterior_adjacent_to = "ambient"
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_roof_ins = new_roof.elements["Insulation"]
          new_roof_ins.elements["InsulationGrade"].text = 1
          XMLHelper.delete_element(new_roof_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_roof_ins, "Layer")
          XMLHelper.add_element(new_roof_ins, "AssemblyEffectiveRValue", 1.0/ceiling_ufactor)
        end
      end
      
      # Floors
      new_attic.elements.each("Floors/Floor") do |new_floor|
        exterior_adjacent_to = XMLHelper.get_value(new_floor, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_floor_ins = new_floor.elements["Insulation"]
          new_floor_ins.elements["InsulationGrade"].text = 1
          XMLHelper.delete_element(new_floor_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_floor_ins, "Layer")
          XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0/ceiling_ufactor)
        end
      end
      
      # Walls
      new_attic.elements.each("Walls/Wall") do |new_wall|
        exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_wall_ins = new_wall.elements["Insulation"]
          new_wall_ins.elements["InsulationGrade"].text = 1
          XMLHelper.delete_element(new_wall_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_wall_ins, "Layer")
          XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0/wall_ufactor)
        end
      end
      
    end
    
  end
  
  def self.set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")
    
    '''
    Table 4.2.2(1) - Ceilings
    Type: Same as Rated Home
    Gross area: Same as Rated Home
    U-Factor: Same as Rated Home
    
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
    
    # nop
    
  end
  
  def self.set_enclosure_foundations_reference(new_enclosure, orig_details)
    
    new_foundations = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Foundations")
    
    floor_ufactor = get_reference_component_characteristics("floor")
    wall_ufactor = get_reference_component_characteristics("basement_wall")
    slab_rvalue, slab_depth = get_reference_component_characteristics("slab_on_grade")
          
    new_foundations.elements.each("Foundation") do |new_foundation|
      fnd_type = new_foundation.elements["FoundationType"]
      if fnd_type.elements["Basement[Conditioned='true']"]
        interior_adjacent_to = "conditioned basement"
      elsif fnd_type.elements["Basement[Conditioned='false']"]
        interior_adjacent_to = "unconditioned basement"
      elsif fnd_type.elements["Crawlspace"]
        interior_adjacent_to = "crawlspace"
      elsif fnd_type.elements["SlabOnGrade"]
        interior_adjacent_to = "living space"
      elsif fnd_type.elements["Ambient"]  
        interior_adjacent_to = "ambient"
      end
        
      '''
      Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      Type: wood frame
      Gross area: same as Rated Home
      U-Factor: from Table 4.2.2(2)
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      
      new_foundation.elements.each("FrameFloor") do |new_floor|
        exterior_adjacent_to = XMLHelper.get_value(new_floor, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_floor_ins = new_floor.elements["Insulation"]
          new_floor_ins.elements["InsulationGrade"].text = 1
          XMLHelper.delete_element(new_floor_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_floor_ins, "Layer")
          XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0/floor_ufactor)
        end
      end
  
      '''
      Table 4.2.2(1) - Conditioned basement walls
      Type: same as Rated Home
      Gross area: same as Rated Home
      U-Factor: from Table 4.2.2(2) with the insulation layer on the interior side of walls
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      
      new_foundation.elements.each("FoundationWall") do |new_wall|
        exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
        if fnd_type.elements["Basement[Conditioned='true']"] and is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_wall_ins = new_wall.elements["Insulation"]
          new_wall_ins.elements["InsulationGrade"].text = 1
          XMLHelper.delete_element(new_wall_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_wall_ins, "Layer")
          XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0/wall_ufactor)
        end
      end
  
      '''
      Table 4.2.2(1) - Foundations
      Type: same as Rated Home
      Gross Area: same as Rated Home
      U-Factor / R-value: from Table 4.2.2(2)
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      new_foundation.elements.each("Slab") do |new_slab|
        if fnd_type.elements["SlabOnGrade"] and is_external_thermal_boundary(interior_adjacent_to, "ground")
          new_slab.elements["PerimeterInsulationDepth"].text = slab_depth
          new_slab.elements["UnderSlabInsulationWidth"].text = 0
          perim_ins = new_slab.elements["PerimeterInsulation"]
          XMLHelper.delete_element(perim_ins, "Layer")
          perim_layer = XMLHelper.add_element(perim_ins, "Layer")
          XMLHelper.add_element(perim_layer, "InstallationType", "continuous")
          XMLHelper.add_element(perim_layer, "NominalRValue", slab_rvalue)
          XMLHelper.add_element(perim_layer, "Thickness", slab_rvalue/5.0)
          under_ins = new_slab.elements["UnderSlabInsulation"]
          XMLHelper.delete_element(under_ins, "Layer")
          under_layer = XMLHelper.add_element(under_ins, "Layer")
          XMLHelper.add_element(under_layer, "InstallationType", "continuous")
          XMLHelper.add_element(under_layer, "NominalRValue", 0)
          XMLHelper.add_element(under_layer, "Thickness", 0)
        end
        new_slab.elements["extension/CarpetFraction"].text = 0.8
        new_slab.elements["extension/CarpetRValue"].text = 2.0
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
  
  def self.get_wall_subsurface_area(wall, details)
    wall_id = wall.elements["SystemIdentifier"].attributes["id"]
    subsurface_area = 0.0
    details.elements.each("Enclosure/Windows/Window") do |window|
      next if window.elements["AttachedToWall"].attributes["idref"] != wall_id
      subsurface_area += Float(XMLHelper.get_value(window, "Area"))
    end
    details.elements.each("Enclosure/Doors/Door") do |door|
      next if door.elements["AttachedToWall"].attributes["idref"] != wall_id
      subsurface_area += Float(XMLHelper.get_value(door, "Area"))
    end
    return subsurface_area
  end

  def self.set_enclosure_walls_reference(new_enclosure, orig_details)
  
    new_walls = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Walls")
  
    '''
    Table 4.2.2(1) - Above-grade walls
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    Solar absorptance = 0.75
    Emittance = 0.90
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    ufactor = get_reference_component_characteristics("frame_wall")
    
    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        new_wall.elements["Siding"].text = "vinyl siding"
        new_wall.elements["SolarAbsorptance"].text = 0.75
        new_wall.elements["Emittance"].text = 0.90
        insulation = new_wall.elements["Insulation"]
        XMLHelper.delete_element(insulation, "AssemblyEffectiveRValue")
        XMLHelper.delete_element(insulation, "Layer")
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      end
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

  def self.set_enclosure_windows_reference(new_enclosure, orig_details)
    
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

    ufactor, shgc = get_reference_component_characteristics("window")
    
    ag_wall_area = 0.0
    bg_wall_area = 0.0
    
    orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
      int_adj_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
      ext_adj_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
      next if not ((int_adj_to == "living space" or ext_adj_to == "living space") and int_adj_to != ext_adj_to)
      area = Float(XMLHelper.get_value(wall, "Area"))
      ag_wall_area += area
    end
    
    orig_details.elements.each("Enclosure/Foundations/Foundation[FoundationType/Basement/Conditioned='true']/FoundationWall") do |fwall|
      adj_to = XMLHelper.get_value(fwall, "extension/ExteriorAdjacentTo")
      next if adj_to == "living space"
      height = Float(XMLHelper.get_value(fwall, "Height"))
      bg_depth = Float(XMLHelper.get_value(fwall, "BelowGradeDepth"))
      area = Float(XMLHelper.get_value(fwall, "Area"))
      ag_wall_area += (height - bg_depth) / height * area
      bg_wall_area += bg_depth / height * area
    end
    
    fa = ag_wall_area / (ag_wall_area + 0.5 * bg_wall_area)
    f = 1.0 # TODO
    
    total_window_area = 0.18 * @cfa * fa * f
    
    wall = orig_details.elements["Enclosure/Walls/Wall"] # Arbitrary wall
    
    # Create new windows
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")
    for orientation, azimuth in {"north"=>0,"south"=>180,"east"=>90,"west"=>270}
      new_window = XMLHelper.add_element(new_windows, "Window")
      sys_id = XMLHelper.add_element(new_window, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Window_#{orientation}")
      XMLHelper.add_element(new_window, "Area", 0.25 * total_window_area)
      XMLHelper.add_element(new_window, "Azimuth", azimuth)
      XMLHelper.add_element(new_window, "UFactor", ufactor)
      XMLHelper.add_element(new_window, "SHGC", shgc)
      XMLHelper.add_element(new_window, "ExteriorShading", "none")
      attwall = XMLHelper.add_element(new_window, "AttachedToWall")
      attwall.attributes["idref"] = wall.elements["SystemIdentifier"].attributes["id"]
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
  
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")
  
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
    
    orig_details.elements.each("Enclosure/Windows/Window") do |orig_window|
      new_window = XMLHelper.add_element(new_windows, "Window")
      XMLHelper.copy_element(new_window, orig_window, "SystemIdentifier")
      XMLHelper.copy_element(new_window, orig_window, "Area")
      XMLHelper.copy_element(new_window, orig_window, "Azimuth")
      XMLHelper.copy_element(new_window, orig_window, "UFactor")
      XMLHelper.copy_element(new_window, orig_window, "SHGC")
      XMLHelper.copy_element(new_window, orig_window, "ExteriorShading")
      XMLHelper.copy_element(new_window, orig_window, "AttachedToWall")
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

  def self.set_enclosure_doors_reference(new_enclosure, orig_details)

    '''
    Table 4.2.2(1) - Doors
    Area: 40 ft2
    U-factor: same as fenestration from Table 4.2.2(2)
    Orientation: North
    '''
    
    ufactor, shgc = get_reference_component_characteristics("door")
    door_area = 40.0
    
    wall = orig_details.elements["Enclosure/Walls/Wall"] # Arbitrary wall
    
    # Create new door
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
    new_door = XMLHelper.add_element(new_doors, "Door")
    sys_id = XMLHelper.add_element(new_door, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Door")
    attwall = XMLHelper.add_element(new_door, "AttachedToWall")
    attwall.attributes["idref"] = wall.elements["SystemIdentifier"].attributes["id"]
    XMLHelper.add_element(new_door, "Area", door_area)
    XMLHelper.add_element(new_door, "Azimuth", 0)
    XMLHelper.add_element(new_door, "RValue", 1.0/ufactor)
    
  end
  
  def self.set_enclosure_doors_rated(new_enclosure, orig_details)
  
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
  
    '''
    Table 4.2.2(1) - Doors
    Area: Same as Rated Home
    U-factor: Same as Rated Home
    Orientation: Same as Rated Home
    '''

    orig_details.elements.each("Enclosure/Doors/Door") do |orig_door|
      new_door = XMLHelper.add_element(new_doors, "Door")
      XMLHelper.copy_element(new_door, orig_door, "SystemIdentifier")
      XMLHelper.copy_element(new_door, orig_door, "AttachedToWall")
      XMLHelper.copy_element(new_door, orig_door, "Area")
      XMLHelper.copy_element(new_door, orig_door, "Azimuth")
      XMLHelper.copy_element(new_door, orig_door, "RValue")
    end
    
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
    
    prevent_hp_and_ac = true # TODO: Eventually allow this...
    
    has_boiler = false
    fuel_type = nil
    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    if not heating_system.nil?
      has_boiler = XMLHelper.has_element(heating_system, "HeatingSystemType/Boiler")
      fuel_type = XMLHelper.get_value(heating_system, "HeatingSystemFuel")
    elsif not heat_pump_system.nil?
      fuel_type = 'electricity'
    end
    
    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")
    
    # Heating
    heat_type = nil
    if heating_system.nil? and heat_pump_system.nil?
      if has_fuel_access(orig_details)
        heat_type = "GasFurnace"
      else
        heat_type = "HeatPump"
      end
    elsif fuel_type == 'electricity'
      heat_type = "HeatPump"
    elsif has_boiler
      heat_type = "GasBoiler"
    else
      heat_type = "GasFurnace"
    end
    
    # Cooling
    cool_type = "AirConditioner"
    if prevent_hp_and_ac and heat_type == "HeatPump"
      cool_type = "HeatPump"
    end
    
    # HeatingSystems
    if heat_type == "GasFurnace"
    
      # 78% AFUE gas furnace
      afue = 0.78
      heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
      dist = XMLHelper.add_element(heat_sys, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
      furnace = XMLHelper.add_element(sys_type, "Furnace")
      XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
      heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "AFUE")
      XMLHelper.add_element(heat_eff, "Value", afue)
      XMLHelper.add_element(heat_sys, "FractionHeatLoadServed", 1.0)
      
    elsif heat_type == "GasBoiler"
    
      # 80% AFUE gas boiler
      afue = 0.80
      heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
      dist = XMLHelper.add_element(heat_sys, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
      boiler = XMLHelper.add_element(sys_type, "Boiler")
      XMLHelper.add_element(boiler, "BoilerType", "hot water")
      XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "natural gas")
      heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "AFUE")
      XMLHelper.add_element(heat_eff, "Value", afue)
      XMLHelper.add_element(heat_sys, "FractionHeatLoadServed", 1.0)
      
    end
    
    # CoolingSystems
    if cool_type == "AirConditioner"
    
      # 13 SEER electric air conditioner
      seer = 13.0
      cool_sys = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cool_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      dist = XMLHelper.add_element(cool_sys, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      XMLHelper.add_element(cool_sys, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cool_sys, "CoolingSystemFuel", "electricity")
      XMLHelper.add_element(cool_sys, "FractionCoolLoadServed", 1.0)
      cool_eff = XMLHelper.add_element(cool_sys, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", seer)
      extension = XMLHelper.add_element(cool_sys, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941) # TODO: Do we really want to apply this?
      XMLHelper.add_element(extension, "NumberSpeeds", "1-Speed")
      
    end
    
    # HeatPump
    if heat_type == "HeatPump"
      
      # 7.7 HSPF air source heat pump
      hspf = 7.7
      heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      dist = XMLHelper.add_element(heat_pump, "DistributionSystem")
      XMLHelper.add_attribute(dist, "idref", "HVACDistribution")
      XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
      XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", 1.0)
      if prevent_hp_and_ac
        XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", 1.0)
        seer = 13.0
        cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolEfficiency")
        XMLHelper.add_element(cool_eff, "Units", "SEER")
        XMLHelper.add_element(cool_eff, "Value", seer)
      end
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", hspf)
      extension = XMLHelper.add_element(heat_pump, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582) # TODO: Do we really want to apply this?
      if prevent_hp_and_ac
        XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941) # TODO: Do we really want to apply this?
      end
      XMLHelper.add_element(extension, "NumberSpeeds", "1-Speed")
      
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
    
    heating_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatingSystem"]
    heat_pump_system = orig_details.elements["Systems/HVAC/HVACPlant/HeatPump"]
    cooling_system = orig_details.elements["Systems/HVAC/HVACPlant/CoolingSystem"]
    
    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")
    
    dist_id = nil
    if orig_details.elements["Systems/HVAC/HVACDistribution"]
      dist_id = orig_details.elements["Systems/HVAC/HVACDistribution/SystemIdentifier"].attributes["id"]
    end
    
    # Heating
    heat_type = nil
    if heating_system.nil? and heat_pump_system.nil?
      if has_fuel_access(orig_details)
        heat_type = "GasFurnace" # override
      else
        heat_type = "HeatPump" # override
      end
    end
    
    # Cooling
    cool_type = nil
    if cooling_system.nil? and heat_pump_system.nil?
      cool_type = "AirConditioner" # override
    end
    
    # HeatingSystems
    if not heating_system.nil?
      
      # Retain heating system
      heating_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HeatingSystem")
      
    elsif heat_type == "GasFurnace"
    
      # 78% AFUE gas furnace
      afue = 0.78
      heating_system = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
      sys_id = XMLHelper.add_element(heating_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
      if not dist_id.nil?
        dist = XMLHelper.add_element(heating_system, "DistributionSystem")
        XMLHelper.add_attribute(dist, "idref", dist_id)
      end
      sys_type = XMLHelper.add_element(heating_system, "HeatingSystemType")
      furnace = XMLHelper.add_element(sys_type, "Furnace")
      XMLHelper.add_element(heating_system, "HeatingSystemFuel", "natural gas")
      heat_eff = XMLHelper.add_element(heating_system, "AnnualHeatingEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "AFUE")
      XMLHelper.add_element(heat_eff, "Value", afue)
      XMLHelper.add_element(heating_system, "FractionHeatLoadServed", 1.0)
        
    end
    
    # CoolingSystems
    if not cooling_system.nil?
      
      # Retain cooling system
      cooling_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/CoolingSystem")
      extension = cooling_system.elements["extension"]
      if extension.nil?
        extension = XMLHelper.add_element(cooling_system, "extension")
      end
      XMLHelper.delete_element(extension, "PerformanceAdjustmentSEER")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941) # TODO: Do we really want to apply this?
      
    elsif cool_type == "AirConditioner"
      
      # 13 SEER electric air conditioner
      seer = 13.0
      cooling_system = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cooling_system, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      if not dist_id.nil?
        dist = XMLHelper.add_element(cooling_system, "DistributionSystem")
        XMLHelper.add_attribute(dist, "idref", dist_id)
      end
      XMLHelper.add_element(cooling_system, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cooling_system, "CoolingSystemFuel", "electricity")
      XMLHelper.add_element(cooling_system, "FractionCoolLoadServed", 1.0)
      cool_eff = XMLHelper.add_element(cooling_system, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", seer)
      extension = XMLHelper.add_element(cooling_system, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941) # TODO: Do we really want to apply this?
      XMLHelper.add_element(extension, "NumberSpeeds", "1-Speed")
      
    end
    
    # HeatPump
    if not heat_pump_system.nil?
    
      # Retain heating system
      heat_pump_system = XMLHelper.copy_element(new_hvac_plant, orig_details, "Systems/HVAC/HVACPlant/HeatPump")
      extension = heat_pump_system.elements["extension"]
      if extension.nil?
        extension = XMLHelper.add_element(heat_pump_system, "extension")
      end
      if not heat_pump_system.elements["AnnualCoolEfficiency"].nil?
        XMLHelper.delete_element(extension, "PerformanceAdjustmentSEER")
        XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941) # TODO: Do we really want to apply this?
      end
      XMLHelper.delete_element(extension, "PerformanceAdjustmentHSPF")
      XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582) # TODO: Do we really want to apply this?
      
    elsif heat_type == "HeatPump"
    
      # 7.7 HSPF air source heat pump
      hspf = 7.7
      heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      if not dist_id.nil?
        dist = XMLHelper.add_element(heat_pump, "DistributionSystem")
        XMLHelper.add_attribute(dist, "idref", dist_id)
      end
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
      XMLHelper.add_element(heat_pump, "FractionHeatLoadServed", 1.0)
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", hspf)
      extension = XMLHelper.add_element(heat_pump, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582) # TODO: Do we really want to apply this?
      XMLHelper.add_element(extension, "NumberSpeeds", "1-Speed")
      
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
    control_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACControl/ControlType")
    if control_type == "programmable thermostat"
      has_programmable_tstat = true
    end
    
    programmable_offset = 2 # F
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.copy_element(new_hvac_control, orig_details, "Systems/HVAC/HVACControl/ControlType")
    XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
    if has_programmable_tstat
      XMLHelper.add_element(new_hvac_control, "SetbackTempHeatingSeason", 68-programmable_offset)
      XMLHelper.add_element(new_hvac_control, "TotalSetbackHoursperWeekHeating", 7*7) # 11 p.m. to 5:59 a.m., 7 days a week
      XMLHelper.add_element(new_hvac_control, "SetupTempCoolingSeason", 78+programmable_offset)
    end
    XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
    if has_programmable_tstat
      XMLHelper.add_element(new_hvac_control, "TotalSetupHoursperWeekCooling", 6*7) # 9 a.m. to 2:59 p.m., 7 days a week
      extension = XMLHelper.add_element(new_hvac_control, "extension")
      XMLHelper.add_element(extension, "SetbackStartHour", 23) # 11 p.m.
      XMLHelper.add_element(extension, "SetupStartHour", 9) # 9 a.m.
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
    # FIXME: There can be no distribution system when HVAC prescribed via above
    #        e.g., no cooling system => AC w/o ducts
    XMLHelper.copy_element(new_hvac, orig_details, "Systems/HVAC/HVACDistribution")

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
    
    orig_whole_house_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    
    if not orig_whole_house_fan.nil?
      
      fan_type = XMLHelper.get_value(orig_whole_house_fan, "FanType")
      
      q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')
      
      # Calculate fan cfm for airflow rate using Reference Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
      sla = 0.00036
      # TODO: Merge with Airflow measure and move this code to airflow.rb
      nl = 1000.0 * sla * @ncfl_ag ** 0.4 # Normalized leakage, eq. 4.4
      q_inf = nl * @weather.data.WSF * @cfa / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
      if q_inf > 2.0/3.0 * q_tot
        q_fan_airflow = q_tot - 2.0/3.0 * q_tot
      else
        q_fan_airflow = q_tot - q_inf
      end
      
      # Calculate fan cfm for fan power using Rated Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
      nach = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
      sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
      # TODO: Merge with Airflow measure and move this code to airflow.rb
      nl = 1000.0 * sla * @ncfl_ag ** 0.4 # Normalized leakage, eq. 4.4
      q_inf = nl * @weather.data.WSF * @cfa / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
      if q_inf > 2.0/3.0 * q_tot
        q_fan_power = q_tot - 2.0/3.0 * q_tot
      else
        q_fan_power = q_tot - q_inf
      end
      
      fan_power_w = nil
      if fan_type == 'supply only' or fan_type == 'exhaust only' or fan_type == 'central fan integrated supply'
        w_cfm = 0.35
        fan_power_w = w_cfm * q_fan_power
      elsif fan_type == 'balanced'
        w_cfm = 0.70
        fan_power_w = w_cfm * q_fan_power
      elsif fan_type == 'energy recovery ventilator' or fan_type == 'heat recovery ventilator'
        w_cfm = 1.00
        fan_power_w = w_cfm * q_fan_power
        fan_type = 'balanced'
      end
      
      new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
      new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
      new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
      sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
      XMLHelper.add_element(new_vent_fan, "FanType", fan_type)
      XMLHelper.add_element(new_vent_fan, "RatedFlowRate", q_fan_airflow)
      XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24) # TODO: CFIS
      XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
      XMLHelper.add_element(new_vent_fan, "FanPower", fan_power_w)
      
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
    
    orig_vent_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]

    if not orig_vent_fan.nil?
      
      new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
      new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
      new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
      sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "FanType")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "RatedFlowRate") # FIXME
      XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24)
      XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "TotalRecoveryEfficiency")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "SensibleRecoveryEfficiency")
      XMLHelper.copy_element(new_vent_fan, orig_vent_fan, "FanPower")

    end
    
  end
  
  def self.set_systems_water_heating_reference(new_systems, orig_details)
  
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
      wh_tank_vol = Float(XMLHelper.get_value(orig_wh_sys, "TankVolume"))
      wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
    end

    if orig_wh_sys.nil?
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      if wh_fuel_type.nil?
        # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
    elsif wh_type == 'instantaneous water heater'
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
    end
    
    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_capacity(Constants.Auto, to_beopt_fuel(wh_fuel_type), @nbeds, @nbaths) * 1000.0 # Btuh
    
    # New water heater
    new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
    XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
    XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
    XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
    XMLHelper.add_element(new_wh_sys, "FractionDHWLoadServed", 1.0)
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
    
    ref_w_gpd = get_waste_gpd_reference()
    bsmnt = get_conditioned_basement_integer(orig_details)
    ref_pipe_l = get_pipe_length_reference(bsmnt)
    ref_loop_l = get_loop_length_reference(ref_pipe_l)
    
    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    sys_type = XMLHelper.add_element(new_hw_dist, "SystemType")
    standard = XMLHelper.add_element(sys_type, "Standard")
    XMLHelper.add_element(standard, "PipingLength", ref_pipe_l)
    pipe_ins = XMLHelper.add_element(new_hw_dist, "PipeInsulation")
    XMLHelper.add_element(pipe_ins, "PipeRValue", 0)
    extension = XMLHelper.add_element(new_hw_dist, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", ref_w_gpd)
    XMLHelper.add_element(extension, "RefLoopL", ref_loop_l)
    
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.1.4 refFgpd = 14.6 + 10.0*Nbr
                        = reference climate-normalized daily fixture water use in Reference Home (in 
                          gallons per day)
    '''
    
    ref_f_gpd = get_fixtures_gpd_reference()
    sens_gain, lat_gain = get_general_water_use_gains_sens_lat()
    
    # New water fixture
    new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
    sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
    XMLHelper.add_element(new_fixture, "WaterFixtureType", "shower head")
    extension = XMLHelper.add_element(new_fixture, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", ref_f_gpd)
    XMLHelper.add_element(extension, "SensibleGainsBtu", sens_gain)
    XMLHelper.add_element(extension, "LatentGainsBtu", lat_gain)
    
  end
  
  def self.set_systems_water_heating_rated(new_systems, orig_details)
  
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
      
      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "SystemIdentifier")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FuelType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "WaterHeaterType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "TankVolume")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FractionDHWLoadServed")
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
      if wh_fuel_type.nil?
        # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
      wh_cap = Waterheater.calc_capacity(Constants.Auto, to_beopt_fuel(wh_fuel_type), @nbeds, @nbaths) * 1000.0 # Btuh
    
      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
      XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
      XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
      XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
      XMLHelper.add_element(new_wh_sys, "FractionDHWLoadServed", 1.0)
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
    
    orig_hw_dist = orig_details.elements["Systems/WaterHeating/HotWaterDistribution"]
    
    low_flow_fixtures = false
    orig_details.elements.each("Systems/WaterHeating/WaterFixture[WaterFixtureType!='other']") do |wf|
      if wf.elements["FlowRate"] and Float(XMLHelper.get_value(wf, "FlowRate")) <= 2.0
        low_flow_fixtures = true
      end
    end
    
    bsmnt = get_conditioned_basement_integer(orig_details)
    
    is_recirc = false
    recirc_control_type = nil
    recirc_pump_power = nil
    if orig_hw_dist.nil?
      pipe_l = get_pipe_length_reference(bsmnt)
      pipe_rvalue = 0
    else
      if not orig_hw_dist.elements["SystemType/Recirculation"].nil?
        is_recirc = true
        recirc_branch_l = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/BranchPipingLoopLength"))
        recirc_loop_l = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/RecirculationPipingLoopLength"))
        recirc_control_type = XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/ControlType")
        recirc_pump_power = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/PumpPower"))
      else
        pipe_l = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Standard/PipingLength"))
      end
      pipe_rvalue = Float(XMLHelper.get_value(orig_hw_dist, "PipeInsulation/PipeRValue"))
    end
    
    # Waste gpd
    rated_w_gpd = get_waste_gpd_rated(is_recirc, pipe_rvalue, pipe_l, recirc_branch_l, bsmnt, low_flow_fixtures)
    
    # Recirc pump annual electricity consumption
    recirc_pump_annual_kwh = get_hwdist_recirc_pump_energy(is_recirc, recirc_control_type, recirc_pump_power)
    
    # Calculate energy delivery effectiveness adjustment for energy consumption
    ec_adj = get_hwdist_energy_consumption_adjustment(is_recirc, recirc_control_type, pipe_rvalue, pipe_l, recirc_loop_l, bsmnt)

    has_dwhr = false
    if not orig_hw_dist.nil? and not orig_hw_dist.elements["DrainWaterHeatRecovery"].nil?
      has_dwhr = true
      eff = Float(XMLHelper.get_value(orig_hw_dist, "DrainWaterHeatRecovery/Efficiency"))
      equal_flow = Boolean(XMLHelper.get_value(orig_hw_dist, "DrainWaterHeatRecovery/EqualFlow"))
      if XMLHelper.get_value(orig_hw_dist, "DrainWaterHeatRecovery/FacilitiesConnected") == "all"
        all_showers = true
      elsif XMLHelper.get_value(orig_hw_dist, "DrainWaterHeatRecovery/FacilitiesConnected") == "one"
        all_showers = false
      end
      dwhr_eff_adj, dwhr_iFrac, dwhr_plc, dwhr_locF, dwhr_fixF = get_dwhr_factors(bsmnt, pipe_l, is_recirc, recirc_branch_l, eff, equal_flow, all_showers, low_flow_fixtures)
    end
    
    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    systype = XMLHelper.add_element(new_hw_dist, "SystemType")
    if is_recirc
      recirc = XMLHelper.add_element(systype, "Recirculation")
      XMLHelper.add_element(recirc, "ControlType", recirc_control_type)
      XMLHelper.add_element(recirc, "RecirculationPipingLoopLength", recirc_loop_l)
      XMLHelper.add_element(recirc, "BranchPipingLoopLength", recirc_branch_l)
      XMLHelper.add_element(recirc, "PumpPower", recirc_pump_power)
    else
      standard = XMLHelper.add_element(systype, "Standard")
      XMLHelper.add_element(standard, "PipingLength", pipe_l)
    end
    insulation = XMLHelper.add_element(new_hw_dist, "PipeInsulation")
    XMLHelper.add_element(insulation, "PipeRValue", pipe_rvalue)
    if has_dwhr
      new_dwhr = XMLHelper.copy_element(new_hw_dist, orig_hw_dist, "DrainWaterHeatRecovery")
      extension = XMLHelper.add_element(new_dwhr, "extension")
      XMLHelper.add_element(extension, "EfficiencyAdjustment", dwhr_eff_adj)
      XMLHelper.add_element(extension, "FracImpactedHotWater", dwhr_iFrac)
      XMLHelper.add_element(extension, "PipingLossCoefficient", dwhr_plc)
      XMLHelper.add_element(extension, "LocationFactor", dwhr_locF)
      XMLHelper.add_element(extension, "FixtureFactor", dwhr_fixF)
    end
    extension = XMLHelper.add_element(new_hw_dist, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", rated_w_gpd)
    XMLHelper.add_element(extension, "EnergyConsumptionAdjustmentFactor", ec_adj) # used by energy_rating_index.rb
    if is_recirc
      XMLHelper.add_element(extension, "RecircPumpAnnualkWh", recirc_pump_annual_kwh)
    end

    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    4.2.2.5.2.11 Service Hot Water Use.
    refFgpd = reference climate-normalized daily fixture water use calculated in accordance with Section 4.2.2.5.1.4
    '''
    
    rated_f_gpd = get_fixtures_gpd_rated(low_flow_fixtures)
    sens_gain, lat_gain = get_general_water_use_gains_sens_lat()
    
    # New water fixture
    new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
    sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
    XMLHelper.add_element(new_fixture, "WaterFixtureType", "shower head")
    extension = XMLHelper.add_element(new_fixture, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", rated_f_gpd)
    XMLHelper.add_element(extension, "SensibleGainsBtu", sens_gain)
    XMLHelper.add_element(extension, "LatentGainsBtu", lat_gain)

  end
  
  def self.set_appliances_clothes_washer_reference(new_appliances)
  
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refCWgpd = reference clothes washer gallons per day
                         = (4.52*(164+46.5*Nbr))*((3*2.08+1.59)/(2.874*2.08+1.59))/365
    '''
  
    clothes_washer_kwh = 38.0 + 0.0 * @cfa + 10.0 * @nbeds
    clothes_washer_sens, clothes_washer_lat = get_clothes_washer_sens_lat(clothes_washer_kwh)
    clothes_washer_gpd = (4.52 * (164.0 + 46.5 * @nbeds)) * ((3.0 * 2.08 + 1.59)/(2.874 * 2.08 + 1.59)) / 365.0
    
    new_clothes_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    sys_id = XMLHelper.add_element(new_clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesWasher")
    extension = XMLHelper.add_element(new_clothes_washer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_washer_kwh)
    XMLHelper.add_element(extension, "FracSensible", clothes_washer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_washer_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", clothes_washer_gpd)
    
  end
  
  def self.set_appliances_clothes_washer_rated(new_appliances, orig_details)
  
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
    
    if orig_details.elements["Appliances/ClothesWasher/ModifiedEnergyFactor"]
      # Detailed
      ler = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/RatedAnnualkWh"))
      elec_rate = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/LabelElectricRate"))
      gas_rate = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/LabelGasRate"))
      agc = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/LabelAnnualGasCost"))
      cap = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/Capacity"))
      
      ncy = (3.0 / 2.847) * (164 + @nbeds * 46.5)
      acy = ncy * ((3.0 * 2.08 + 1.59) / (cap * 2.08 + 1.59)) #Adjusted Cycles per Year
      clothes_washer_kwh = ((ler / 392.0) - ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392.0) * 21.9825) * acy
      clothes_washer_sens, clothes_washer_lat = get_clothes_washer_sens_lat(clothes_washer_kwh)
      clothes_washer_gpd = 60.0 * ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392.0) * acy / 365.0
    else
      # Simplified
      clothes_washer_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/AnnualkWh"))
      clothes_washer_sens = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/FracSensible"))
      clothes_washer_lat = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/FracLatent"))
      clothes_washer_gpd = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/HotWaterGPD"))
    end
    
    new_clothes_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    sys_id = XMLHelper.add_element(new_clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesWasher")
    extension = XMLHelper.add_element(new_clothes_washer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_washer_kwh)
    XMLHelper.add_element(extension, "FracSensible", clothes_washer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_washer_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", clothes_washer_gpd)

  end

  def self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
  
    dryer_fuel = XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/FuelType")
    clothes_dryer_kwh = 524.0 + 0.0 * @cfa + 149.0 * @nbeds
    clothes_dryer_therm = 0.0
    if dryer_fuel != 'electricity'
      clothes_dryer_kwh = 41.0 + 0.0 * @cfa + 11.7 * @nbeds
      clothes_dryer_therm = 18.8 + 0.0 * @cfa + 5.3 * @nbeds
    end
    clothes_dryer_sens, clothes_dryer_lat = get_clothes_dryer_sens_lat(dryer_fuel, clothes_dryer_kwh, clothes_dryer_therm)
    
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
  
  def self.set_appliances_clothes_dryer_rated(new_appliances, orig_details)
  
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
    if orig_details.elements["Appliances/ClothesDryer/EfficiencyFactor"]
      # Detailed
      ef_dry = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/EfficiencyFactor"))
      has_timer_control = Boolean(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer[ControlType='timer']"))
      
      ler = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/RatedAnnualkWh"))
      cap = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/Capacity"))
      mef = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/ModifiedEnergyFactor"))
      
      field_util_factor = nil
      if has_timer_control
        field_util_factor = 1.18
      else
        field_util_factor = 1.04
      end
      clothes_dryer_kwh = 12.5 * (164.0 + 46.5 * @nbeds) * (field_util_factor / ef_dry) * ((cap / mef) - ler / 392.0) / (0.2184 * (cap * 4.08 + 0.24))
      clothes_dryer_therm = 0.0
      if dryer_fuel != 'electricity'
        clothes_dryer_therm = clothes_dryer_kwh * (3412.0/100000) * 0.93 * (3.01/ef_dry)
        clothes_dryer_kwh = clothes_dryer_kwh * 0.07 * (3.01/ef_dry)
      end
      clothes_dryer_sens, clothes_dryer_lat = get_clothes_dryer_sens_lat(dryer_fuel, clothes_dryer_kwh, clothes_dryer_therm)
    else
      # Simplified
      clothes_dryer_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/AnnualkWh"))
      clothes_dryer_therm = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/AnnualTherm"))
      clothes_dryer_sens = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/FracSensible"))
      clothes_dryer_lat = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/FracLatent"))
    end
    
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

  def self.set_appliances_dishwasher_reference(new_appliances)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes

    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refDWgpd = reference dishwasher gallons per day
                         = ((88.4+34.9*Nbr)*8.16)/365
    '''
  
    dishwasher_kwh = 78.0 + 0.0 * @cfa + 31.0 * @nbeds
    dishwasher_sens, dishwasher_lat = get_dishwasher_sens_lat(dishwasher_kwh)
    dishwasher_gpd = ((88.4 + 34.9 * @nbeds) * 8.16) / 365.0
    
    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    sys_id = XMLHelper.add_element(new_dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Dishwasher")
    extension = XMLHelper.add_element(new_dishwasher, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", dishwasher_kwh)
    XMLHelper.add_element(extension, "FracSensible", dishwasher_sens)
    XMLHelper.add_element(extension, "FracLatent", dishwasher_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", dishwasher_gpd)
    
  end
  
  def self.set_appliances_dishwasher_rated(new_appliances, orig_details)
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
    
    if orig_details.elements["Appliances/Dishwasher/EnergyFactor"] or orig_details.elements["Appliances/Dishwasher/RatedAnnualkWh"]
      # Detailed
      cap = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/PlaceSettingCapacity"))
      ef = XMLHelper.get_value(orig_details, "Appliances/Dishwasher/EnergyFactor")
      if ef.nil?
        rated_annual_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/RatedAnnualkWh"))
        ef = 215.0 / rated_annual_kwh
      else
        ef = ef.to_f
      end
      dwcpy = (88.4 + 34.9 * @nbeds) * (12.0 / cap)
      dishwasher_kwh = ((86.3 + 47.73 / ef) / 215) * dwcpy
      dishwasher_sens, dishwasher_lat = get_dishwasher_sens_lat(dishwasher_kwh)
      dishwasher_gpd = dwcpy * (4.6415 * (1.0 / ef) - 1.9295) / 365.0
    else
      # Simplified
      dishwasher_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/AnnualkWh"))
      dishwasher_sens = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/FracSensible"))
      dishwasher_lat = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/FracLatent"))
      dishwasher_gpd = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/HotWaterGPD"))
    end
  
    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    sys_id = XMLHelper.add_element(new_dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Dishwasher")
    extension = XMLHelper.add_element(new_dishwasher, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", dishwasher_kwh)
    XMLHelper.add_element(extension, "FracSensible", dishwasher_sens)
    XMLHelper.add_element(extension, "FracLatent", dishwasher_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", dishwasher_gpd)
    
  end

  def self.set_appliances_refrigerator_reference(new_appliances)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
  
    refrigerator_kwh = 637.0 + 0.0 * @cfa + 18.0 * @nbeds

    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
    extension = XMLHelper.add_element(new_fridge, "extension")
    XMLHelper.add_element(extension, "FracSensible", 1.0)
    XMLHelper.add_element(extension, "FracLatent", 0.0)
    
  end
  
  def self.set_appliances_refrigerator_rated(new_appliances, orig_details)
    '''
    4.2.2.5.2.5. Refrigerators. Refrigerator annual energy use for the Rated Home shall be determined from 
    either refrigerator Energy Guide labels or from age-based defaults in accordance with Table 
    4.2.2.5.2.5(1).
    '''
    
    refrigerator_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/Refrigerator/RatedAnnualkWh"))
    
    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
    extension = XMLHelper.add_element(new_fridge, "extension")
    XMLHelper.add_element(extension, "FracSensible", 1.0)
    XMLHelper.add_element(extension, "FracLatent", 0.0)
    
  end

  def self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
    
    # TODO: How to handle different fuel types for CookingRange vs Oven?
    range_fuel = XMLHelper.get_value(orig_details, "Appliances/CookingRange/FuelType")
    oven_fuel = XMLHelper.get_value(orig_details, "Appliances/Oven/FuelType")
    
    cooking_range_kwh = 331.0 + 0.0 * @cfa + 39.0 * @nbeds
    cooking_range_therm = 0.0
    if range_fuel != 'electricity' or oven_fuel != 'electricity'
      cooking_range_kwh = 22.6 + 0.0 * @cfa + 2.7 * @nbeds
      cooking_range_therm = 22.6 + 0.0 * @cfa + 2.7 * @nbeds
    end
    cooking_range_sens, cooking_range_lat = get_cooking_range_sens_lat(range_fuel, oven_fuel, cooking_range_kwh, cooking_range_therm)
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "CookingRange")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CookingRange")
    XMLHelper.add_element(new_cooking_range, "FuelType", range_fuel)
    extension = XMLHelper.add_element(new_cooking_range, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", cooking_range_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", cooking_range_therm)
    XMLHelper.add_element(extension, "FracSensible", cooking_range_sens)
    XMLHelper.add_element(extension, "FracLatent", cooking_range_lat)
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "Oven")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Oven")
    XMLHelper.add_element(new_cooking_range, "FuelType", oven_fuel)
    
  end
  
  def self.set_appliances_cooking_range_oven_rated(new_appliances, orig_details)
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
    
    range_fuel = XMLHelper.get_value(orig_details, "Appliances/CookingRange/FuelType")
    oven_fuel = XMLHelper.get_value(orig_details, "Appliances/Oven/FuelType")
    if orig_details.elements["Appliances/CookingRange/IsInduction"]
      # Detailed
      range_is_induction = Boolean(XMLHelper.get_value(orig_details, "Appliances/CookingRange/IsInduction"))
      oven_is_convection = Boolean(XMLHelper.get_value(orig_details, "Appliances/Oven/IsConvection"))
      
      burner_ef = 1.0
      if range_is_induction
        burner_ef = 0.91
      end
      
      oven_ef = 1.0
      if oven_is_convection
        oven_ef = 0.95
      end
      
      cooking_range_kwh = burner_ef * oven_ef * (331 + 39.0 * @nbeds)
      cooking_range_therm = 0.0
      if range_fuel != 'electricity' or oven_fuel != 'electricity'
        cooking_range_kwh = 22.6 + 2.7 * @nbeds
        cooking_range_therm = oven_ef * (22.6 + 2.7 * @nbeds)
      end
      cooking_range_sens, cooking_range_lat = get_cooking_range_sens_lat(range_fuel, oven_fuel, cooking_range_kwh, cooking_range_therm)
    else
      # Simplified
      cooking_range_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/AnnualkWh"))
      cooking_range_therm = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/AnnualTherm"))
      cooking_range_sens = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/FracSensible"))
      cooking_range_lat = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/FracLatent"))
    end
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "CookingRange")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CookingRange")
    XMLHelper.add_element(new_cooking_range, "FuelType", range_fuel)
    extension = XMLHelper.add_element(new_cooking_range, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", cooking_range_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", cooking_range_therm)
    XMLHelper.add_element(extension, "FracSensible", cooking_range_sens)
    XMLHelper.add_element(extension, "FracLatent", cooking_range_lat)
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "Oven")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Oven")
    XMLHelper.add_element(new_cooking_range, "FuelType", oven_fuel)

  end

  def self.set_lighting_reference(new_lighting, orig_details)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    4.2.2.5.1.3. Garage Lighting. Where the Rated Home includes an enclosed garage, 100 kWh/y shall be added
    to the energy use of the Reference Home to account for garage lighting.
    '''
    
    extension = XMLHelper.add_element(new_lighting, "extension")
    
    # Interior lighting
    interior_lighting_kwh = 455.0 + 0.80 * @cfa + 0.0 * @nbeds
    XMLHelper.add_element(extension, "AnnualInteriorkWh", interior_lighting_kwh)
    
    # Exterior lighting
    exterior_lighting_kwh = 100.0 + 0.05 * @cfa + 0.0 * @nbeds
    XMLHelper.add_element(extension, "AnnualExteriorkWh", exterior_lighting_kwh)
    
    # Garage lighting
    garage_lighting_kwh = 0.0
    if Boolean(XMLHelper.get_value(orig_details, "BuildingSummary/BuildingConstruction/GaragePresent"))
      garage_lighting_kwh = 100.0
    end
    XMLHelper.add_element(extension, "AnnualGaragekWh", garage_lighting_kwh)
    
  end
  
  def self.set_lighting_rated(new_lighting, orig_details)

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
    if orig_details.elements["Lighting/LightingFractions"]
      # Detailed
      qFF_int = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/QualifyingLightFixturesInterior"))
      interior_lighting_kwh = 0.8 * ((4.0 - 3.0 * qFF_int) / 3.7) * (455.0 + 0.8 * @cfa) + 0.2 * (455.0 + 0.8 * @cfa)
    else
      # Simplified
      interior_lighting_kwh = Float(XMLHelper.get_value(orig_details, "Lighting/extension/AnnualInteriorkWh"))
    end
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
    if orig_details.elements["Lighting/LightingFractions"]
      # Detailed
      qFF_ext = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/QualifyingLightFixturesExterior"))
      exterior_lighting_kwh = (100.0 + 0.05 * @cfa) * (1.0 - qFF_ext) + 0.25 * (100.0 + 0.05 * @cfa) * qFF_ext
    else
      # Simplified
      exterior_lighting_kwh = Float(XMLHelper.get_value(orig_details, "Lighting/extension/AnnualExteriorkWh"))
    end
    XMLHelper.add_element(extension, "AnnualExteriorkWh", exterior_lighting_kwh)
    
    '''
    4.2.2.5.2.4. Garage Lighting. For Rated homes with garages, garage annual lighting energy use in the Rated 
    home shall be determined in accordance with Equation 4.2-4:
    kWh = 100*(1-FFGL) + 25*FFGL (Eq 4.2-4)
    where:
    FFGL = Fraction of garage fixtures that are Qualifying Light Fixtures
    '''
    # Garage Lighting
    if orig_details.elements["Lighting/LightingFractions"]
      # Detailed
      garage_lighting_kwh = 0.0
      if Boolean(XMLHelper.get_value(orig_details, "BuildingSummary/BuildingConstruction/GaragePresent"))
        qFF_grg = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/QualifyingLightFixturesGarage"))
        garage_lighting_kwh = 100.0 * (1.0 - qFF_grg) + 25.0 * qFF_grg
      end
    else
      # Simplified
      garage_lighting_kwh = Float(XMLHelper.get_value(orig_details, "Lighting/extension/AnnualGaragekWh"))
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

  def self.set_misc_loads_reference(new_misc_loads)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
    
    # Residual MELs
    residual_mels_kwh = get_residual_mels_kwh()
    residual_mels_sens, residual_mels_lat = get_residual_mels_sens_lat(residual_mels_kwh)
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
    televisions_kwh = get_televisions_kwh()
    televisions_sens, televisions_lat = get_televisions_sens_lat(televisions_kwh)
    television = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(television, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Television")
    XMLHelper.add_element(television, "PlugLoadType", "TV other")
    television_load = XMLHelper.add_element(television, "Load")
    XMLHelper.add_element(television_load, "Units", "kWh/year")
    XMLHelper.add_element(television_load, "Value", televisions_kwh)
    extension = XMLHelper.add_element(television, "extension")
    XMLHelper.add_element(extension, "FracSensible", televisions_sens)
    XMLHelper.add_element(extension, "FracLatent", televisions_lat)
    
  end
  
  def self.set_misc_loads_rated(new_misc_loads)
    '''
    4.2.2.5.2.1. Residual MELs. Residual miscellaneous annual electric energy use in the Rated Home shall 
    be the same as in the HERS Reference Home and shall be calculated as 0.91*CFA.
    
    4.2.2.5.2.6. Televisions. Television annual energy use in the Rated Home shall be the same as television 
    energy use in the HERS Reference Home and shall be calculated as TVkWh/y = 413 + 69*Nbr, where Nbr is 
    the number of Bedrooms in the Rated Home.
    '''
    
    # Residual MELs
    residual_mels_kwh = get_residual_mels_kwh()
    residual_mels_sens, residual_mels_lat = get_residual_mels_sens_lat(residual_mels_kwh)
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
    televisions_kwh = get_televisions_kwh()
    televisions_sens, televisions_lat = get_televisions_sens_lat(televisions_kwh)
    television = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(television, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Television")
    XMLHelper.add_element(television, "PlugLoadType", "TV other")
    television_load = XMLHelper.add_element(television, "Load")
    XMLHelper.add_element(television_load, "Units", "kWh/year")
    XMLHelper.add_element(television_load, "Value", televisions_kwh)
    extension = XMLHelper.add_element(television, "extension")
    XMLHelper.add_element(extension, "FracSensible", televisions_sens)
    XMLHelper.add_element(extension, "FracLatent", televisions_lat)
    
  end

  def self.get_reference_component_characteristics(component_type)
    '''
    Table 4.2.2(2) - Component Heat Transfer Characteristics for HERS Reference Home
    '''
    if component_type == "window" or component_type == "door"
      # Fenestration and Opaque Door U-Factor
      # Glazed Fene-stration Assembly SHGC
      if ["1A", "1B", "1C"].include? @climate_zone
        return 1.2, 0.40
      elsif ["2A", "2B", "2C"].include? @climate_zone
        return 0.75, 0.40
      elsif ["3A", "3B", "3C"].include? @climate_zone
        return 0.65, 0.40
      elsif ["4A", "4B"].include? @climate_zone
        return 0.40, 0.40
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @climate_zone
        return 0.35, 0.40
      else
        return nil
      end
    elsif component_type == "frame_wall"
      # Frame Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B"].include? @climate_zone
        return 0.082
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C"].include? @climate_zone
        return 0.060
      elsif ["7", "8"].include? @climate_zone
        return 0.057
      else
        return nil
      end
    elsif component_type == "basement_wall"
      # Basement Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? @climate_zone
        return 0.360
      elsif ["4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @climate_zone
        return 0.059
      else
        return nil
      end
    elsif component_type == "floor"
      # Floor Over Uncond-itioned Space U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C"].include? @climate_zone
        return 0.064
      elsif ["3A", "3B", "3C", "4A", "4B"].include? @climate_zone
        return 0.047
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @climate_zone
        return 0.033
      else
        return nil
      end
    elsif component_type == "ceiling"
      # Ceiling U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? @climate_zone
        return 0.035
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? @climate_zone
        return 0.030
      elsif ["6A", "6B", "6C", "7", "8"].include? @climate_zone
        return 0.026
      else
        return nil
      end
    elsif component_type == "slab_on_grade"
      # Slab-on-Grade R-Value & Depth (ft)
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? @climate_zone
        return 0.0, 0.0
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? @climate_zone
        return 10.0, 2.0
      elsif ["6A", "6B", "6C", "7", "8"].include? @climate_zone
        return 10.0, 4.0
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def self.get_pipe_length_reference(bsmnt)
    return 2.0 * (@cfa / @ncfl)**0.5 + 10.0 * @ncfl + 5.0 * bsmnt
  end
  
  def self.get_loop_length_reference(ref_pipe_l)
    return 2.0 * ref_pipe_l - 20.0
  end
  
  def self.get_fixture_effectiveness_rated(low_flow_fixtures)
    f_eff = 1.0
    if low_flow_fixtures
      f_eff = 0.95
    end
    return f_eff
  end
  
  def self.get_fixtures_gpd_reference()
    return 14.6 + 10.0 * @nbeds
  end
  
  def self.get_fixtures_gpd_rated(low_flow_fixtures)
    ref_f_gpd = get_fixtures_gpd_reference()
    f_eff = get_fixture_effectiveness_rated(low_flow_fixtures)
    return f_eff * ref_f_gpd
  end
  
  def self.get_waste_gpd_reference()
    return 9.8 * (@nbeds**0.43)
  end
  
  def self.get_waste_gpd_rated(is_recirc, pipe_rvalue, pipe_l, recirc_branch_l, bsmnt, low_flow_fixtures)
    sys_factor = 1.0
    if is_recirc and pipe_rvalue < 3.0
      sys_factor = 1.11
    elsif not is_recirc and pipe_rvalue >= 3.0
      sys_factor = 0.90
    end
    
    ref_w_gpd = get_waste_gpd_reference()
    o_frac = 0.25
    o_cd_eff = 0.0
    
    if is_recirc
      p_ratio = recirc_branch_l / 10.0
    else
      ref_pipe_l = get_pipe_length_reference(bsmnt)
      p_ratio = pipe_l / ref_pipe_l
    end
    
    o_w_gpd = ref_w_gpd * o_frac * (1.0 - o_cd_eff)
    s_w_gpd = (ref_w_gpd - ref_w_gpd * o_frac) * p_ratio * sys_factor
    
    wd_eff = 1.0
    if is_recirc
      wd_eff = 0.10
    end
    
    f_eff = get_fixture_effectiveness_rated(low_flow_fixtures)
    
    return f_eff * (o_w_gpd + s_w_gpd * wd_eff)
  end
  
  def self.get_clothes_washer_sens_lat(clothes_washer_kwh)
    load_sens = 95.0 + 26.0 * @nbeds # Btu/day
    load_lat = 11.0 + 3.0 * @nbeds # Btu/day
    total = OpenStudio::convert(clothes_washer_kwh, "kWh", "Btu").get/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_clothes_dryer_sens_lat(dryer_fuel, clothes_dryer_kwh, clothes_dryer_therm)
    if dryer_fuel != 'electricity'
      load_sens = 738.0 + 209.0 * @nbeds # Btu/day
      load_lat = 91.0 + 26.0 * @nbeds # Btu/day
    else
      load_sens = 661.0 + 188.0 * @nbeds # Btu/day
      load_lat = 73.0 + 21.0 * @nbeds # Btu/day
    end
    total = OpenStudio::convert(clothes_dryer_kwh, "kWh", "Btu").get/365.0  # Btu/day
    total += OpenStudio::convert(clothes_dryer_therm, "therm", "Btu").get/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_dishwasher_sens_lat(dishwasher_kwh)
    load_sens = 219.0 + 87.0 * @nbeds # Btu/day
    load_lat = 219.0 + 87.0 * @nbeds # Btu/day
    total = OpenStudio::convert(dishwasher_kwh, "kWh", "Btu").get/365.0
    return load_sens/total, load_lat/total
  end
  
  def self.get_cooking_range_sens_lat(range_fuel, oven_fuel, cooking_range_kwh, cooking_range_therm)
    if range_fuel != 'electricity' or oven_fuel != 'electricity'
      load_sens = 4086.0 + 488.0 * @nbeds # Btu/day
      load_lat = 1037.0 + 124.0 * @nbeds # Btu/day
    else
      load_sens = 2228.0 + 262.0 * @nbeds # Btu/day
      load_lat = 248.0 + 29.0 * @nbeds # Btu/day
    end
    total = OpenStudio::convert(cooking_range_kwh, "kWh", "Btu").get/365.0 # Btu/day
    total += OpenStudio::convert(cooking_range_therm, "therm", "Btu").get/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_residual_mels_kwh()
    return 0.91 * @cfa
  end
  
  def self.get_residual_mels_sens_lat(residual_mels_kwh)
    load_sens = 7.27 * @cfa # Btu/day
    load_lat = 0.38 * @cfa # Btu/day
    total = OpenStudio::convert(residual_mels_kwh, "kWh", "Btu").get/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_televisions_kwh()
    return 413.0 + 0.0 * @cfa + 69.0 * @nbeds
  end
  
  def self.get_televisions_sens_lat(televisions_kwh)
    load_sens = 3861.0 + 645.0 * @nbeds # Btu/day
    load_lat = 0.0 # Btu/day
    total = OpenStudio::convert(televisions_kwh, "kWh", "Btu").get/365.0 # Btu/day
    return load_sens/total, load_lat/total
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
  
  def self.get_hwdist_energy_waste_factor(is_recirc, recirc_control_type, pipe_rvalue)
    '''
    Table 4.2.2.5.2.11(6) Hot water distribution system relative annual energy waste factors
                                                                             EWfact
    Distribution System Description                         ------------------------------------------
                                                            No pipe insulation    ≥R-3 pipe insulation
    -------------------------------                         ------------------    --------------------
    Standard systems                                        32.0                  28.8
    Recirculation without control or with timer control     500                   250
    Recirculation with temperature control                  375                   187.5
    Recirculation with demand control (presence sensor)     64.8                  43.2
    Recirculation with demand control (manual)              43.2                  28.8
    '''
    
    if is_recirc
      if recirc_control_type == "no control" or recirc_control_type == "timer"
        if pipe_rvalue < 3.0
          return 500.0
        else
          return 250.0
        end
      elsif recirc_control_type == "temperature"
        if pipe_rvalue < 3.0
          return 375.0
        else
          return 187.5
        end
      elsif recirc_control_type == "presence sensor demand control"
        if pipe_rvalue < 3.0
          return 64.8
        else
          return 43.2
        end
      elsif recirc_control_type == "manual demand control"
        if pipe_rvalue < 3.0
          return 43.2
        else
          return 28.8
        end
      end
    else # standard distribution
      if pipe_rvalue < 3.0
        return 32.0
      else
        return 28.8
      end
    end
    return nil
  end
  
  def self.get_hwdist_recirc_pump_energy(is_recirc, recirc_control_type, recirc_pump_power)
    '''
    4.2.2.5.2.11.2 Hot Water System Annual Energy Consumption
    
    If the Rated Home includes a hot water recirculation system, the annual electric consumption of the recirculation pump shall be added to the total hot water energy consumption. The recirculation pump kWh/y shall be calculated using Equation 4.2-15
      pumpkWh/y = pumpW * Efact Eq. 4.2-15
      where:
        pumpW = pump power in watts (default pumpW = 50 watts)
        Efact = factor selected from Table 4.2.2.5.2.11(5)
      
    Table 4.2.2.5.2.11(5) Annual electricity consumption factor for hot water recirculation system pumps
    Recirculation System Description                        Efact
    --------------------------------                        -----
    Recirculation without control or with timer control     8.76
    Recirculation with temperature control                  1.46
    Recirculation with demand control (presence sensor)     0.15
    Recirculation with demand control (manual)              0.10
    '''
    if is_recirc
      if recirc_control_type == "no control" or recirc_control_type == "timer"
        return 8.76 * recirc_pump_power
      elsif recirc_control_type == "temperature"
        return 1.46 * recirc_pump_power
      elsif recirc_control_type == "presence sensor demand control"
        return 0.15 * recirc_pump_power
      elsif recirc_control_type == "manual demand control"
        return 0.10 * recirc_pump_power
      end
    end
    return nil
  end
  
  def self.get_hwdist_energy_consumption_adjustment(is_recirc, recirc_control_type, pipe_rvalue, pipe_l, loop_l, bsmnt)
    '''
    Results from standard hot water energy consumption calculations considering only tested Energy Factor data (stdECHW) shall be adjusted to account for the energy delivery effectiveness of the hot water distribution system in accordance with equation 4.2-16.
      ECHW = stdECHW * (Ewaste + 128) / 160 Eq. 4.2-16
      where Ewaste is calculated in accordance with equation 4.2-17.
        Ewaste = oEWfact * (1-oCDeff) + sEWfact * pEratio Eq. 4.2-17
        where
          oEWfact = EWfact * oFrac = standard operating condition portion of hot water energy waste
          where
            EWfact = energy waste factor in accordance with Table 4.2.2.5.2.11(6)
          oCDeff is in accordance with Section 4.2.2.5.2.11.1
          sEWfact = EWfact – oEWfact = structural portion of hot water energy waste
          pEratio = piping length energy ratio
          where
            for standard system: pEratio = PipeL / refpipeL
            for recirculation systems: pEratio = LoopL / refLoopL
            and where
              LoopL = hot water recirculation loop piping length including both supply and return sides of the loop, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements.
              refLoopL = 2.0*refPipeL - 20
    '''
    ew_fact = get_hwdist_energy_waste_factor(is_recirc, recirc_control_type, pipe_rvalue)
    o_frac = 0.25 # fraction of hot water waste from standard operating conditions
    oew_fact = ew_fact * o_frac # standard operating condition portion of hot water energy waste
    ocd_eff = 0.0 # TODO: Need an HPXML input for this?
    sew_fact = ew_fact - oew_fact
    ref_pipe_l = get_pipe_length_reference(bsmnt)
    if not is_recirc
      pe_ratio = pipe_l / ref_pipe_l
    else
      ref_loop_l = get_loop_length_reference(ref_pipe_l)
      pe_ratio = loop_l / ref_loop_l
    end
    e_waste = oew_fact * (1.0 - ocd_eff) + sew_fact * pe_ratio
    return (e_waste + 128.0) / 160.0
  end
  
  def self.get_dwhr_factors(bsmnt, pipe_l, is_recirc, recirc_branch_l, eff, equal_flow, all_showers, low_flow_fixtures)
    '''
    4.2.2.5.2.11.1 Drain Water Heat Recovery (DWHR) Units
    
    If DWHR unit(s) is (are) installed in the Rated Home, the water heater potable water supply temperature adjustment (WHinTadj) shall be calculated in accordance with Equation 4.2-14.
    
      WHinTadj =Ifrac*(DWHRinT-Tmains)*DWHReff*PLC*LocF*FixF Eq. 4.2-14
      where
        WHinTadj = adjustment to water heater potable supply inlet temperature (oF)
        Ifrac = 0.56 + 0.015*Nbr – 0.0004*Nbr2 = fraction of hot water use impacted by DWHR
        DWHRinT = 97 oF
        Tmains = calculated in accordance with Section 4.2.2.5.1.4
        DWHReff = Drain Water Heat Recovery Unit efficiency as rated and labeled in accordance with CSA 55.1
        where
          DWHReff = DWHReff *1.082 if low-flow fixtures are installed in accordance with Table 4.2.2.5.2.11(1)
        PLC = 1 - 0.0002*pLength = piping loss coefficient
        where
          for standard systems: 
            pLength = pipeL as measured accordance with Section 4.1.1.5.2.11
          for recirculation systems: 
            pLength = branchL as measured in accordance with Section 4.2.2.5.2.11
        LocF = a performance factor based on the installation location of the DWHR determined from Table 4.2.2.5.2.11(4)
        
        Table 4.2.2.5.2.11(4) Location factors for DWHR placement
        DRHR Placement                                                                                                      LocF
        --------------                                                                                                      ----
        Supplies pre-heated water to both the fixture cold water piping and the hot water heater potable supply piping      1.000
        Supplies pre-heated water to only the hot water heater potable supply piping                                        0.777
        Supplies pre-heated water to only the fixture cold water piping                                                     0.777
    
        FixF = Fixture Factor
        where
          FixF = 1.0 if all of the showers in the home are connected to DWHR units
          FixF = 0.5 if there are 2 or more showers in the home and only 1 shower is connected to a DWHR unit.
    '''
    
    eff_adj = 1.0
    if low_flow_fixtures
      eff_adj = 1.082
    end
    
    iFrac = 0.56 + 0.015 * @nbeds - 0.0004 * @nbeds**2 # fraction of hot water use impacted by DWHR
    
    if is_recirc
      pLength = recirc_branch_l
    else
      pLength = pipe_l
    end
    plc = 1 - 0.0002 * pLength # piping loss coefficient
    
    # Location factors for DWHR placement
    if equal_flow
      locF = 1.000
    else
      locF = 0.777
    end
    
    # Fixture Factor
    if all_showers
      fixF = 1.0
    else
      fixF = 0.5
    end
    
    return eff_adj, iFrac, plc, locF, fixF
  end

  def self.get_occupants_heat_gain_sens_lat()
    '''
    Table 4.2.2(3). Internal Gains for HERS Reference Homes
    Occupants
    Sensible Gains (Btu/day) - 3716*Nbr
    Latent Gains (Btu/day) - 2884*Nbr
    
    Software tools shall use either the occupant gains provided above or similar temperature dependent values 
    generated by the software where the number of occupants equals the number of Bedrooms and occupants are 
    present in the home 16.5 hours per day.
    '''
    
    hrs_per_day = 16.5
    sens_gains = 3716.0 # Btu/person/day
    lat_gains = 2884.0 # Btu/person/day
    tot_gains = sens_gains + lat_gains
    
    num_occ = @nbeds
    heat_gain = tot_gains/hrs_per_day # Btu/person/hr
    sens = sens_gains/tot_gains
    lat = lat_gains/tot_gains
    return num_occ, heat_gain, sens, lat, hrs_per_day
  end
  
  def self.get_general_water_use_gains_sens_lat()
    '''
    Table 4.2.2(3). Internal Gains for HERS Reference Homes
    Occupants
    Sensible Gains (Btu/day) - -1227-409*Nbr
    Latent Gains (Btu/day) - 1245+415*Nbr
    '''
    
    sens_gains = -1227.0 - 409.0*@nbeds # Btu/day
    lat_gains = 1245.0 + 415.0*@nbeds # Btu/day
    return sens_gains*365.0, lat_gains*365.0
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
  
  def self.has_fuel_access(orig_details)
    orig_details.elements.each("BuildingSummary/Site/FuelTypesAvailable/Fuel") do |fuel|
      fuels = ["natural gas", "fuel oil", "fuel oil 1", 
               "fuel oil 2", "fuel oil 4", "fuel oil 5/6",
               "propane", "kerosene", "diesel",
               "anthracite coal", "bituminous coal", "coke",
               "wood", "wood pellets"]
      if fuels.include?(fuel.text)
        return true
      end
    end
    return false
  end
  
  def self.get_conditioned_basement_integer(orig_details)
    bsmnt = 0.0
    if not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?
      bsmnt = 1.0
    end
    return bsmnt
  end
  
  def self.is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
    interior_conditioned = is_adjacent_to_conditioned(interior_adjacent_to)
    exterior_conditioned = is_adjacent_to_conditioned(exterior_adjacent_to)
    return (interior_conditioned != exterior_conditioned)
  end
  
  def self.is_adjacent_to_conditioned(adjacent_to)
    if adjacent_to == "living space"
      return true
    elsif adjacent_to == "garage"
      return false
    elsif adjacent_to == "vented attic"
      return false
    elsif adjacent_to == "unvented attic"
      return false
    elsif adjacent_to == "cape cod"
      return true
    elsif adjacent_to == "cathedral ceiling"
      return true
    elsif adjacent_to == "unconditioned basement"
      return false
    elsif adjacent_to == "conditioned basement"
      return true
    elsif adjacent_to == "crawlspace"
      return false
    elsif adjacent_to == "ambient"
      return false
    elsif adjacent_to == "ground"
      return false
    end
    fail "Unexpected adjacent_to (#{adjacent_to})."
  end
  
end
  