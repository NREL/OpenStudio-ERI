require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/xmlhelper"
require "#{File.dirname(__FILE__)}/waterheater"
require "#{File.dirname(__FILE__)}/airflow"
require "#{File.dirname(__FILE__)}/unit_conversions"

class EnergyRatingIndex301Ruleset

  def self.apply_ruleset(hpxml_doc, calc_type, weather)
  
    building = hpxml_doc.elements["/HPXML/Building"]
    
    # Update XML type
    header = hpxml_doc.elements["/HPXML/XMLTransactionHeaderInformation"]
    if header.elements["XMLType"].nil?
      header.elements["XMLType"].text = calc_type
    else
      header.elements["XMLType"].text += ", #{calc_type}"
    end
    
    # Class variables
    @eri_version = XMLHelper.get_value(hpxml_doc, "/HPXML/SoftwareInfo/extension/ERICalculation/Version")
    @weather = weather
    @ndu = 1 # Dwelling units
    @cfa = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"))
    @nbeds = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    @ncfl = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloors"))
    @ncfl_ag = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofConditionedFloorsAboveGrade"))
    @cvolume = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedBuildingVolume"))
    @iecc_zone_2006 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2006']/ClimateZone")
    @iecc_zone_2012 = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year='2012']/ClimateZone")
        
    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
        apply_reference_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIRatedHome
        apply_rated_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIIndexAdjustmentDesign
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
    set_systems_mechanical_ventilation_reference(new_systems, orig_details, new_enclosure)
    set_systems_water_heater_reference(new_systems, orig_details)
    set_systems_water_heating_use_reference(new_systems, orig_details)
    set_systems_photovoltaics_reference(new_systems)
    
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
    set_systems_water_heater_rated(new_systems, orig_details)
    set_systems_water_heating_use_rated(new_systems, orig_details)
    set_systems_photovoltaics_rated(new_systems, orig_details)
    
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
  
    # Create new BuildingDetails element
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    XMLHelper.delete_element(building, "ModeledUsages")
    XMLHelper.delete_element(building, "extensions")
    new_details = XMLHelper.add_element(building, "BuildingDetails")
    
    # BuildingSummary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_iad(new_summary, orig_details)
    
    # ClimateAndRiskZones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")
    
    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_iad(new_enclosure, orig_details)
    set_enclosure_attics_roofs_iad(new_enclosure, orig_details)
    set_enclosure_foundations_iad(new_enclosure, orig_details)
    set_enclosure_rim_joists_iad(new_enclosure)
    set_enclosure_walls_iad(new_enclosure, orig_details)
    set_enclosure_windows_iad(new_enclosure, orig_details)
    set_enclosure_skylights_iad(new_enclosure, orig_details)
    set_enclosure_doors_iad(new_enclosure, orig_details)
    
    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_iad(new_systems, orig_details)
    set_systems_mechanical_ventilation_iad(new_systems, orig_details, new_enclosure)
    set_systems_water_heater_iad(new_systems, orig_details)
    set_systems_water_heating_use_iad(new_systems, orig_details)
    set_systems_photovoltaics_iad(new_systems)

    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_iad(new_appliances, orig_details)
    set_appliances_clothes_dryer_iad(new_appliances, orig_details)
    set_appliances_dishwasher_iad(new_appliances, orig_details)
    set_appliances_refrigerator_iad(new_appliances, orig_details)
    set_appliances_cooking_range_oven_iad(new_appliances, orig_details)
    
    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_iad(new_lighting, orig_details)
    set_lighting_ceiling_fans_iad(new_lighting)
    
    # MiscLoads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_iad(new_misc_loads)
  
  end
  
  def self.set_summary_reference(new_summary, orig_details)
  
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
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
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
    
  end
  
  def self.set_summary_rated(new_summary, orig_details)
  
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
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
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
    
  end
  
  def self.set_summary_iad(new_summary, orig_details)
  
    # Table 4.3.1(1) Configuration of Index Adjustment Design - General Characteristics
    @cfa = 2400
    @nbeds = 3
    @ncfl = 2
    @ncfl_ag = 2
    @cvolume = 20400
    @garage_present = false
    
    new_site = XMLHelper.add_element(new_summary, "Site")
    orig_site = orig_details.elements["BuildingSummary/Site"]
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
    XMLHelper.add_element(new_construction, "NumberofConditionedFloors", @ncfl)
    XMLHelper.add_element(new_construction, "NumberofConditionedFloorsAboveGrade", @ncfl_ag)
    XMLHelper.add_element(new_construction, "NumberofBedrooms", @nbeds)
    XMLHelper.add_element(new_construction, "ConditionedFloorArea", @cfa)
    XMLHelper.add_element(new_construction, "ConditionedBuildingVolume", @cvolume)
    XMLHelper.add_element(new_construction, "GaragePresent", @garage_present)
    
  end
  
  def self.set_enclosure_air_infiltration_reference(new_enclosure, orig_details)
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    
    # Table 4.2.2(1) - Air exchange rate
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
    
  end
  
  def self.set_enclosure_air_infiltration_rated(new_enclosure, orig_details)
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    orig_infil = orig_details.elements["Enclosure/AirInfiltration"]
    orig_mv = orig_details.elements["Systems/MechanicalVentilation"]
    
    # Table 4.2.2(1) - Air exchange rate
    
    whole_house_fan = nil
    if not orig_mv.nil?
      whole_house_fan = orig_mv.elements["VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    end
    
    if not orig_infil.elements["AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"].nil?
      nach = Float(XMLHelper.get_value(orig_infil, "AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
      if whole_house_fan.nil? and nach < 0.30
        nach = 0.30
      end
      # Convert to other forms
      sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
      ela = sla * @cfa
      ach50 = Airflow.get_infiltration_ACH50_from_SLA(sla, 0.67, @cfa, @cvolume)
    elsif not orig_infil.elements["AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].nil?
      ach50 = Float(XMLHelper.get_value(orig_infil, "AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
      # Convert to other forms
      sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
      ela = sla * @cfa
      nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    end
    
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
    
  end
  
  def self.set_enclosure_air_infiltration_iad(new_enclosure, orig_details)
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    orig_infil = orig_details.elements["Enclosure/AirInfiltration"]
    
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate
    if ["1A", "1B", "1C", "2A", "2B", "2C"].include? @iecc_zone_2012
      ach50 = 3.0
    elsif ["3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2012
      ach50 = 5.0
    else
      fail "Unhandled IECC 2012 climate zone #{@iecc_zone_2012}."
    end
    
    # Convert to other forms
    sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
    nach = Airflow.get_infiltration_ACH_from_SLA(sla, @ncfl_ag, @weather)
    
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
    
  end
  
  def self.set_enclosure_attics_roofs_reference(new_enclosure, orig_details)
  
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")
    
    ceiling_ufactor = get_reference_component_characteristics("ceiling")
    wall_ufactor = get_reference_component_characteristics("frame_wall")
    
    new_attic_roof.elements.each("Attics/Attic") do |new_attic|
      attic_type = XMLHelper.get_value(new_attic, "AtticType")
      if ['unvented attic','vented attic'].include? attic_type
        attic_type = 'vented attic'
        new_attic.elements["AtticType"].text = attic_type
      end
      interior_adjacent_to = attic_type
      
      # Table 4.2.2(1) - Roofs
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        new_roof.elements["RadiantBarrier"].text = false
        new_roof.elements["SolarAbsorptance"].text = 0.75
        new_roof.elements["Emittance"].text = 0.90
        if is_external_thermal_boundary(interior_adjacent_to, "ambient")
          new_roof_ins = new_roof.elements["Insulation"]
          XMLHelper.delete_element(new_roof_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_roof_ins, "Layer")
          XMLHelper.add_element(new_roof_ins, "AssemblyEffectiveRValue", 1.0/ceiling_ufactor)
        end
      end
      
      # Table 4.2.2(1) - Ceilings
      new_attic.elements.each("Floors/Floor") do |new_floor|
        exterior_adjacent_to = XMLHelper.get_value(new_floor, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_floor_ins = new_floor.elements["Insulation"]
          XMLHelper.delete_element(new_floor_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_floor_ins, "Layer")
          XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0/ceiling_ufactor)
        end
      end
      
      # Table 4.2.2(1) - Above-grade walls
      new_attic.elements.each("Walls/Wall") do |new_wall|
        exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_wall_ins = new_wall.elements["Insulation"]
          XMLHelper.delete_element(new_wall_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_wall_ins, "Layer")
          XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0/wall_ufactor)
        end
      end
      
      # Table 4.2.2(1) - Attics
      if attic_type == 'vented attic'
        extension = new_attic.elements["extension"]
        if extension.nil?
          extension = XMLHelper.add_element(new_attic, "extension")
        end
        XMLHelper.delete_element(extension, "AtticSpecificLeakageArea")
        XMLHelper.add_element(extension, "AtticSpecificLeakageArea", 1.0/300.0)
      end
      
    end
    
  end
  
  def self.set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    
    new_attic_roof = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/AtticAndRoof")
    
  end
  
  def self.set_enclosure_attics_roofs_iad(new_enclosure, orig_details)
    
    set_enclosure_attics_roofs_rated(new_enclosure, orig_details)
    
    new_attic_roof = new_enclosure.elements["AtticAndRoof"]
    
    new_attic_roof.elements.each("Attics/Attic") do |new_attic|
    
      # Table 4.3.1(1) Configuration of Index Adjustment Design - Roofs
      sum_roof_area = 0.0
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        sum_roof_area += Float(XMLHelper.get_value(new_roof, "Area"))
      end
      new_attic.elements.each("Roofs/Roof") do |new_roof|
        roof_area = Float(XMLHelper.get_value(new_roof, "Area"))
        new_roof.elements["Area"].text = 1300.0 * roof_area / sum_roof_area
      end
      
      # Table 4.3.1(1) Configuration of Index Adjustment Design - Ceilings
      sum_floor_area = 0.0
      new_attic.elements.each("Floors/Floor") do |new_floor|
        sum_floor_area += Float(XMLHelper.get_value(new_floor, "Area"))
      end
      new_attic.elements.each("Floors/Floor") do |new_floor|
        floor_area = Float(XMLHelper.get_value(new_floor, "Area"))
        new_floor.elements["Area"].text = 1200.0 * floor_area / sum_floor_area
      end
      
    end
    
  end
  
  def self.set_enclosure_foundations_reference(new_enclosure, orig_details)
    
    new_foundations = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Foundations")
    
    floor_ufactor = get_reference_component_characteristics("floor")
    wall_ufactor = get_reference_component_characteristics("basement_wall")
    slab_rvalue, slab_depth = get_reference_component_characteristics("slab_on_grade")
          
    new_foundations.elements.each("Foundation") do |new_foundation|
      
      if XMLHelper.has_element(new_foundation, "FoundationType/Crawlspace[Vented='false']")
        new_foundation.elements["FoundationType/Crawlspace/Vented"].text = true
      end
      
      fnd_type = new_foundation.elements["FoundationType"]
      interior_adjacent_to = get_foundation_interior_adjacent_to(fnd_type)
      
      # Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      new_foundation.elements.each("FrameFloor") do |new_floor|
        exterior_adjacent_to = XMLHelper.get_value(new_floor, "extension/ExteriorAdjacentTo")
        if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_floor_ins = new_floor.elements["Insulation"]
          XMLHelper.delete_element(new_floor_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_floor_ins, "Layer")
          XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0/floor_ufactor)
        end
      end
  
      # Table 4.2.2(1) - Conditioned basement walls
      new_foundation.elements.each("FoundationWall") do |new_wall|
        exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)?
        if interior_adjacent_to == "conditioned basement" and is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
          new_wall_ins = new_wall.elements["Insulation"]
          XMLHelper.delete_element(new_wall_ins, "AssemblyEffectiveRValue")
          XMLHelper.delete_element(new_wall_ins, "Layer")
          XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0/wall_ufactor)
        end
      end
  
      # Table 4.2.2(1) - Foundations
      new_foundation.elements.each("Slab") do |new_slab|
        # TODO: Can this just be is_external_thermal_boundary(interior_adjacent_to, "ground")?
        if interior_adjacent_to == "living space" and is_external_thermal_boundary(interior_adjacent_to, "ground")
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

      # Table 4.2.2(1) - Crawlspaces
      if XMLHelper.has_element(new_foundation, "FoundationType/Crawlspace[Vented='true']")
        extension = new_foundation.elements["extension"]
        if extension.nil?
          extension = XMLHelper.add_element(new_foundation, "extension")
        end
        XMLHelper.delete_element(extension, "CrawlspaceSpecificLeakageArea")
        XMLHelper.add_element(extension, "CrawlspaceSpecificLeakageArea", 1.0/150.0)
      end
      
    end
    
  end
  
  def self.set_enclosure_foundations_rated(new_enclosure, orig_details)
    
    new_foundations = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Foundations")
    
    min_crawl_vent = 1.0/150.0 # Reference Home vent
    
    new_foundations.elements.each("Foundation") do |new_foundation|
      
      # Table 4.2.2(1) - Crawlspaces
      if XMLHelper.has_element(new_foundation, "FoundationType/Crawlspace[Vented='true']")
        vent = Float(XMLHelper.get_value(new_foundation, "extension/CrawlspaceSpecificLeakageArea"))
        # TODO: Handle approved ground cover
        if vent < min_crawl_vent
          new_foundation.elements["extension/CrawlspaceSpecificLeakageArea"].text = min_crawl_vent
        end
      end

    end

  end
  
  def self.set_enclosure_foundations_iad(new_enclosure, orig_details)
  
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Foundation
    floor_ufactor = get_reference_component_characteristics("floor")
    
    new_foundation = XMLHelper.add_element(new_enclosure, "Foundations/Foundation")
    sys_id = XMLHelper.add_element(new_foundation, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Crawlspace")
    XMLHelper.add_element(new_foundation, "FoundationType/Crawlspace/Vented", true)
    
    # Ceiling
    new_floor = XMLHelper.add_element(new_foundation, "FrameFloor")
    sys_id = XMLHelper.add_element(new_floor, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Floor")
    XMLHelper.add_element(new_floor, "Area", 1200)
    new_floor_ins = XMLHelper.add_element(new_floor, "Insulation")
    sys_id = XMLHelper.add_element(new_floor_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Floor_Ins")
    XMLHelper.add_element(new_floor_ins, "AssemblyEffectiveRValue", 1.0/floor_ufactor)
    extension = XMLHelper.add_element(new_floor, "extension")
    XMLHelper.add_element(extension, "ExteriorAdjacentTo", "living space")
    
    # Wall
    new_wall = XMLHelper.add_element(new_foundation, "FoundationWall")
    sys_id = XMLHelper.add_element(new_wall, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Wall")
    XMLHelper.add_element(new_wall, "Height", 2)
    XMLHelper.add_element(new_wall, "Area", 2*34.64*4)
    XMLHelper.add_element(new_wall, "Thickness", 8)
    XMLHelper.add_element(new_wall, "BelowGradeDepth", 0)
    new_wall_ins = XMLHelper.add_element(new_wall, "Insulation")
    sys_id = XMLHelper.add_element(new_wall_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Wall_Ins")
    XMLHelper.add_element(new_wall_ins, "AssemblyEffectiveRValue", 1.0/floor_ufactor) # FIXME
    extension = XMLHelper.add_element(new_wall, "extension")
    XMLHelper.add_element(extension, "ExteriorAdjacentTo", "ground")
    
    # Floor
    new_slab = XMLHelper.add_element(new_foundation, "Slab")
    sys_id = XMLHelper.add_element(new_slab, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Slab")
    XMLHelper.add_element(new_slab, "Area", 1200)
    XMLHelper.add_element(new_slab, "Thickness", 0)
    XMLHelper.add_element(new_slab, "ExposedPerimeter", 4*34.64)
    XMLHelper.add_element(new_slab, "PerimeterInsulationDepth", 0)
    XMLHelper.add_element(new_slab, "UnderSlabInsulationWidth", 0)
    XMLHelper.add_element(new_slab, "DepthBelowGrade", 0)
    new_perim_ins = XMLHelper.add_element(new_slab, "PerimeterInsulation")
    sys_id = XMLHelper.add_element(new_perim_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Slab_Perim_Ins")
    new_perim_ins_layer = XMLHelper.add_element(new_perim_ins, "Layer")
    XMLHelper.add_element(new_perim_ins_layer, "InstallationType", "continuous")
    XMLHelper.add_element(new_perim_ins_layer, "NominalRValue", 0)
    XMLHelper.add_element(new_perim_ins_layer, "Thickness", 0)
    new_under_ins = XMLHelper.add_element(new_slab, "UnderSlabInsulation")
    sys_id = XMLHelper.add_element(new_under_ins, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Foundation_Slab_Under_Ins")
    new_under_ins_layer = XMLHelper.add_element(new_under_ins, "Layer")
    XMLHelper.add_element(new_under_ins_layer, "InstallationType", "continuous")
    XMLHelper.add_element(new_under_ins_layer, "NominalRValue", 0)
    XMLHelper.add_element(new_under_ins_layer, "Thickness", 0)
    extension = XMLHelper.add_element(new_slab, "extension")
    XMLHelper.add_element(extension, "CarpetFraction", 0)
    XMLHelper.add_element(extension, "CarpetRValue", 0)

    XMLHelper.add_element(new_foundation, "extension/CrawlspaceSpecificLeakageArea", 1.0/150.0)
    
  end
  
  def self.set_enclosure_rim_joists_reference(new_enclosure)
    # FIXME
  end
  
  def self.set_enclosure_rim_joists_rated(new_enclosure)
    # FIXME
  end
  
  def self.set_enclosure_rim_joists_iad(new_enclosure)
    # FIXME
  end
  
  def self.set_enclosure_walls_reference(new_enclosure, orig_details)
  
    new_walls = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Walls")
    
    # Table 4.2.2(1) - Above-grade walls
    ufactor = get_reference_component_characteristics("frame_wall")
    
    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
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
  
    # Table 4.2.2(1) - Above-grade walls
    # nop
    
  end
  
  def self.set_enclosure_walls_iad(new_enclosure, orig_details)
    
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Above-grade walls
    set_enclosure_walls_rated(new_enclosure, orig_details)
    
    new_walls = new_enclosure.elements["Walls"]
    
    sum_wall_area = 0.0
    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        sum_wall_area += Float(XMLHelper.get_value(new_wall, "Area"))
      end
    end
    
    new_walls.elements.each("Wall") do |new_wall|
      interior_adjacent_to = XMLHelper.get_value(new_wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(new_wall, "extension/ExteriorAdjacentTo")
      if is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
        wall_area = Float(XMLHelper.get_value(new_wall, "Area"))
        new_wall.elements["Area"].text = 2360.0 * wall_area / sum_wall_area
      end
    end
    
  end

  def self.set_enclosure_windows_reference(new_enclosure, orig_details)
    
    # Table 4.2.2(1) - Glazing
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
    
    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)
    
    # Create new windows
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")
    for orientation, azimuth in {"north"=>0,"south"=>180,"east"=>90,"west"=>270}
      window_area = 0.25 * total_window_area # Equal distribution to N/S/E/W
      # Distribute this orientation's window area proportionally across all exterior walls
      wall_area_fracs.each do |wall, wall_area_frac|
        wall_id = wall.elements["SystemIdentifier"].attributes["id"]
        new_window = XMLHelper.add_element(new_windows, "Window")
        sys_id = XMLHelper.add_element(new_window, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "Window_#{wall_id}_#{orientation}")
        XMLHelper.add_element(new_window, "Area", window_area * wall_area_frac)
        XMLHelper.add_element(new_window, "Azimuth", azimuth)
        XMLHelper.add_element(new_window, "UFactor", ufactor)
        XMLHelper.add_element(new_window, "SHGC", shgc)
        XMLHelper.add_element(new_window, "ExteriorShading", "none")
        attwall = XMLHelper.add_element(new_window, "AttachedToWall")
        attwall.attributes["idref"] = wall_id
        set_window_interior_shading_reference(new_window)
        extension = new_window.elements["extension"]
        XMLHelper.add_element(extension, "Height", 5.0)
      end
    end

  end
  
  def self.set_window_interior_shading_reference(window)

    # Table 4.2.2(1) - Glazing
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
  
    # Table 4.2.2(1) - Glazing
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
      extension = new_window.elements["extension"]
      XMLHelper.add_element(extension, "Height", 5.0)
    end
    
  end
  
  def self.set_enclosure_windows_iad(new_enclosure, orig_details)
    
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Glazing
    set_enclosure_windows_reference(new_enclosure, orig_details)
    
    new_windows = new_enclosure.elements["Windows"]
    
    sum_u_a = 0.0
    sum_shgc_a = 0.0
    sum_a = 0.0
    new_windows.elements.each("Window") do |new_window|
      window_area = Float(XMLHelper.get_value(new_window, "Area"))
      sum_a += window_area
      sum_u_a += (window_area * Float(XMLHelper.get_value(new_window, "UFactor")))
      sum_shgc_a += (window_area * Float(XMLHelper.get_value(new_window, "SHGC")))
    end
    avg_u = sum_u_a / sum_a
    avg_shgc = sum_shgc_a / sum_a
    
    new_windows.elements.each("Window") do |new_window|
      new_window.elements["UFactor"].text = avg_u
      new_window.elements["SHGC"].text = avg_shgc
    end
    
  end

  def self.set_enclosure_skylights_reference(enclosure)
  
    # Table 4.2.2(1) - Skylights
    # nop
    
  end
  
  def self.set_enclosure_skylights_rated(new_enclosure, orig_details)
  
    new_skylights = XMLHelper.copy_element(new_enclosure, orig_details, "Enclosure/Skylights")

    # Table 4.2.2(1) - Skylights
    # nop
    
  end
  
  def self.set_enclosure_skylights_iad(new_enclosure, orig_details)
  
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Skylights
    set_enclosure_skylights_rated(new_enclosure, orig_details)
    
  end

  def self.set_enclosure_doors_reference(new_enclosure, orig_details)

    # Table 4.2.2(1) - Doors
    ufactor, shgc = get_reference_component_characteristics("door")
    door_area = 40.0
    
    wall_area_fracs = get_exterior_wall_area_fracs(orig_details)
    
    # Create new doors
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
    # Distribute door area proportionally across all exterior walls
    wall_area_fracs.each do |wall, wall_area_frac|
      wall_id = wall.elements["SystemIdentifier"].attributes["id"]
      new_door = XMLHelper.add_element(new_doors, "Door")
      sys_id = XMLHelper.add_element(new_door, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Door_#{wall_id}")
      attwall = XMLHelper.add_element(new_door, "AttachedToWall")
      attwall.attributes["idref"] = wall_id
      XMLHelper.add_element(new_door, "Area", door_area * wall_area_frac)
      XMLHelper.add_element(new_door, "Azimuth", 0)
      XMLHelper.add_element(new_door, "RValue", 1.0/ufactor)
      extension = XMLHelper.add_element(new_door, "extension")
      XMLHelper.add_element(extension, "Height", 6.67)
    end
    
  end
  
  def self.set_enclosure_doors_rated(new_enclosure, orig_details)
  
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
  
    # Table 4.2.2(1) - Doors
    orig_details.elements.each("Enclosure/Doors/Door") do |orig_door|
      new_door = XMLHelper.add_element(new_doors, "Door")
      XMLHelper.copy_element(new_door, orig_door, "SystemIdentifier")
      XMLHelper.copy_element(new_door, orig_door, "AttachedToWall")
      XMLHelper.copy_element(new_door, orig_door, "Area")
      XMLHelper.copy_element(new_door, orig_door, "Azimuth")
      XMLHelper.copy_element(new_door, orig_door, "RValue")
      extension = XMLHelper.add_element(new_door, "extension")
      XMLHelper.add_element(extension, "Height", 6.67)
    end
    
  end
  
  def self.set_enclosure_doors_iad(new_enclosure, orig_details)
  
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Doors
    set_enclosure_doors_rated(new_enclosure, orig_details)
    
  end
  
  def self.set_systems_hvac_reference(new_systems, orig_details)
  
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")
  
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems
    
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
      
    end
    
    # Table 303.4.1(1) - Thermostat
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.add_element(new_hvac_control, "ControlType", "manual thermostat")
    XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
    XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
    
    # Table 4.2.2(1) - Thermal distribution systems
    new_hvac_dist = XMLHelper.add_element(new_hvac, "HVACDistribution")
    sys_id = XMLHelper.add_element(new_hvac_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACDistribution")
    XMLHelper.add_element(new_hvac_dist, "DistributionSystemType/Other", "DSE")
    XMLHelper.add_element(new_hvac_dist, "AnnualHeatingDistributionSystemEfficiency", 0.8)
    XMLHelper.add_element(new_hvac_dist, "AnnualCoolingDistributionSystemEfficiency", 0.8)
    
  end
  
  def self.set_systems_hvac_rated(new_systems, orig_details)
  
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")
  
    # Table 4.2.2(1) - Heating systems
    # Table 4.2.2(1) - Cooling systems
    
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
      XMLHelper.add_element(heat_pump, "FractionCoolLoadServed", 1.0)
      cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", hspf)
      extension = XMLHelper.add_element(heat_pump, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentSEER", 1.0/0.941) # TODO: Do we really want to apply this?
      XMLHelper.add_element(extension, "PerformanceAdjustmentHSPF", 1.0/0.582) # TODO: Do we really want to apply this?
      
    end
    
    # Table 303.4.1(1) - Thermostat
    has_programmable_tstat = false
    control_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACControl/ControlType")
    if control_type == "programmable thermostat"
      has_programmable_tstat = true
    end
    
    programmable_offset = 2 # F
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    if has_programmable_tstat
      XMLHelper.add_element(new_hvac_control, "ControlType", "programmable thermostat")
      XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
      XMLHelper.add_element(new_hvac_control, "SetbackTempHeatingSeason", 68-programmable_offset)
      XMLHelper.add_element(new_hvac_control, "TotalSetbackHoursperWeekHeating", 7*7) # 11 p.m. to 5:59 a.m., 7 days a week
      XMLHelper.add_element(new_hvac_control, "SetupTempCoolingSeason", 78+programmable_offset)
      XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
      XMLHelper.add_element(new_hvac_control, "TotalSetupHoursperWeekCooling", 6*7) # 9 a.m. to 2:59 p.m., 7 days a week
      extension = XMLHelper.add_element(new_hvac_control, "extension")
      XMLHelper.add_element(extension, "SetbackStartHour", 23) # 11 p.m.
      XMLHelper.add_element(extension, "SetupStartHour", 9) # 9 a.m.
    else
      XMLHelper.add_element(new_hvac_control, "ControlType", "manual thermostat")
      XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
      XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
    end
    
    # Table 4.2.2(1) - Thermal distribution systems
    # FIXME: There can be no distribution system when HVAC prescribed via above
    #        e.g., no cooling system => AC w/o ducts. Is this right?
    XMLHelper.copy_element(new_hvac, orig_details, "Systems/HVAC/HVACDistribution")

  end
  
  def self.set_systems_hvac_iad(new_systems, orig_details)
  
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Heating systems
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Cooling systems
    set_systems_hvac_reference(new_systems, orig_details)
  
  end
  
  def self.set_systems_mechanical_ventilation_reference(new_systems, orig_details, new_enclosure)
    
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
    
    # Init
    fan_type = nil
    
    orig_whole_house_fan = orig_details.elements["Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    
    if not orig_whole_house_fan.nil?
      
      fan_type = XMLHelper.get_value(orig_whole_house_fan, "FanType")
      
      q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')
      
      # Calculate fan cfm for airflow rate using Reference Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
      sla = Float(XMLHelper.get_value(new_enclosure, "AirInfiltration/extension/BuildingSpecificLeakageArea"))
      q_fan_airflow = calc_mech_vent_q_fan(q_tot, sla)
      
      # Calculate fan cfm for fan power using Rated Home infiltration
      # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
      if not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"].nil?
        nach = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
        sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
      elsif not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].nil?
        ach50 = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
        sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
      end
      q_fan_power = calc_mech_vent_q_fan(q_tot, sla)
      
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
    
    # Table 4.2.2(1) - Whole-House Mechanical ventilation
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
  
  def self.set_systems_mechanical_ventilation_iad(new_systems, orig_details, new_enclosure)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Whole-House Mechanical ventilation fan energy
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Air exchange rate
    
    q_tot = Airflow.get_mech_vent_whole_house_cfm(1.0, @nbeds, @cfa, '2013')
    
    # Calculate fan cfm for airflow rate using Reference Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_Air_Exchange_Rate_approved.pdf
    sla = Float(XMLHelper.get_value(new_enclosure, "AirInfiltration/extension/BuildingSpecificLeakageArea"))
    q_fan_airflow = calc_mech_vent_q_fan(q_tot, sla)
    
    # Calculate fan cfm for fan power using Rated Home infiltration
    # http://www.resnet.us/standards/Interpretation_on_Reference_Home_mechVent_fanCFM_approved.pdf
    if not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"].nil?
      nach = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACHnatural']/AirLeakage"))
      sla = Airflow.get_infiltration_SLA_from_ACH(nach, @ncfl_ag, @weather)
    elsif not orig_details.elements["Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"].nil?
      ach50 = Float(XMLHelper.get_value(orig_details, "Enclosure/AirInfiltration/AirInfiltrationMeasurement[HousePressure='50']/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
      sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.67, @cfa, @cvolume)
    end
    q_fan_power = calc_mech_vent_q_fan(q_tot, sla)
    
    w_cfm = 0.70
    fan_power_w = w_cfm * q_fan_power
    
    new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
    new_vent_fans = XMLHelper.add_element(new_mech_vent, "VentilationFans")
    new_vent_fan = XMLHelper.add_element(new_vent_fans, "VentilationFan")
    sys_id = XMLHelper.add_element(new_vent_fan, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "VentilationFan")
    XMLHelper.add_element(new_vent_fan, "FanType", 'balanced')
    XMLHelper.add_element(new_vent_fan, "RatedFlowRate", q_fan_airflow)
    XMLHelper.add_element(new_vent_fan, "HoursInOperation", 24)
    XMLHelper.add_element(new_vent_fan, "UsedForWholeBuildingVentilation", true)
    XMLHelper.add_element(new_vent_fan, "FanPower", fan_power_w)
    
  end
  
  def self.set_systems_water_heater_reference(new_systems, orig_details)
  
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")
  
    # Table 4.2.2(1) - Service water heating systems
    
    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]

    wh_type = nil
    wh_tank_vol = nil
    wh_fuel_type = nil
    if not orig_wh_sys.nil?
      wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
      if orig_wh_sys.elements["TankVolume"]
        wh_tank_vol = Float(XMLHelper.get_value(orig_wh_sys, "TankVolume"))
      end
      wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
      wh_location = XMLHelper.get_value(orig_wh_sys, "Location")
    end

    if orig_wh_sys.nil?
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
      if wh_fuel_type.nil? # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_location = 'conditioned space' # 301 Standard doesn't specify the location
    elsif wh_type == 'instantaneous water heater'
      wh_tank_vol = 40.0
    end
    wh_type = 'storage water heater'
    
    wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    wh_cap = Waterheater.calc_capacity(Constants.Auto, to_beopt_fuel(wh_fuel_type), @nbeds, 3.0) * 1000.0 # Btuh
    
    # New water heater
    new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
    XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
    XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
    XMLHelper.add_element(new_wh_sys, "Location", wh_location)
    XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
    XMLHelper.add_element(new_wh_sys, "FractionDHWLoadServed", 1.0)
    XMLHelper.add_element(new_wh_sys, "HeatingCapacity", wh_cap)
    XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
    if not wh_re.nil?
      XMLHelper.add_element(new_wh_sys, "RecoveryEfficiency", wh_re)
    end
    XMLHelper.add_element(new_wh_sys, "HotWaterTemperature", get_water_heater_tank_temperature())
    extension = XMLHelper.add_element(new_wh_sys, "extension")
    XMLHelper.add_element(extension, "PerformanceAdjustmentEnergyFactor", 1.0)
    
  end
    
  def self.set_systems_water_heater_rated(new_systems, orig_details)
  
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")
  
    # Table 4.2.2(1) - Service water heating systems
    
    orig_wh_sys = orig_details.elements["Systems/WaterHeating/WaterHeatingSystem"]
    
    if not orig_wh_sys.nil?
      
      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "SystemIdentifier")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FuelType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "WaterHeaterType")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "Location")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "TankVolume")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "FractionDHWLoadServed")
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "HeatingCapacity")
      if not orig_wh_sys.elements["EnergyFactor"].nil?
        XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "EnergyFactor")
      elsif not orig_wh_sys.elements["UniformEnergyFactor"].nil?
        wh_uef = Float(XMLHelper.get_value(orig_wh_sys, "UniformEnergyFactor"))
        wh_type = XMLHelper.get_value(orig_wh_sys, "WaterHeaterType")
        wh_fuel_type = XMLHelper.get_value(orig_wh_sys, "FuelType")
        wh_ef = get_water_heater_ef_from_uef(wh_uef, wh_type, wh_fuel_type)
        XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
      end
      XMLHelper.copy_element(new_wh_sys, orig_wh_sys, "RecoveryEfficiency")
      XMLHelper.add_element(new_wh_sys, "HotWaterTemperature", get_water_heater_tank_temperature())
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
      if wh_fuel_type.nil? # Electric heat pump or no heating system
        wh_fuel_type = 'electricity'
      end
      wh_ef, wh_re = get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
      wh_cap = Waterheater.calc_capacity(Constants.Auto, to_beopt_fuel(wh_fuel_type), @nbeds, 3.0) * 1000.0 # Btuh
      wh_location = 'conditioned space' # 301 Standard doesn't specify the location
    
      # New water heater
      new_wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
      sys_id = XMLHelper.add_element(new_wh_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
      XMLHelper.add_element(new_wh_sys, "FuelType", wh_fuel_type)
      XMLHelper.add_element(new_wh_sys, "WaterHeaterType", wh_type)
      XMLHelper.add_element(new_wh_sys, "Location", wh_location)
      XMLHelper.add_element(new_wh_sys, "TankVolume", wh_tank_vol)
      XMLHelper.add_element(new_wh_sys, "FractionDHWLoadServed", 1.0)
      XMLHelper.add_element(new_wh_sys, "HeatingCapacity", wh_cap)
      XMLHelper.add_element(new_wh_sys, "EnergyFactor", wh_ef)
      if not wh_re.nil?
        XMLHelper.add_element(new_wh_sys, "RecoveryEfficiency", wh_re)
      end
      XMLHelper.add_element(new_wh_sys, "HotWaterTemperature", get_water_heater_tank_temperature())
      extension = XMLHelper.add_element(new_wh_sys, "extension")
      XMLHelper.add_element(extension, "PerformanceAdjustmentEnergyFactor", 1.0)
      
    end
    
  end
  
  def self.set_systems_water_heater_iad(new_systems, orig_details)
    
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heater_reference(new_systems, orig_details)
    
  end
  
  def self.set_systems_water_heating_use_reference(new_systems, orig_details)
  
    new_water_heating = new_systems.elements["WaterHeating"]
  
    # Table 4.2.2(1) - Service water heating systems
    
    sens_gain, lat_gain = get_general_water_use_gains_sens_lat()
      
    if @eri_version.include? "A"
    
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
      
      ref_f_gpd = get_fixtures_gpd_reference()
      
      # New water fixture
      new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
      sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
      XMLHelper.add_element(new_fixture, "WaterFixtureType", "shower head")
      extension = XMLHelper.add_element(new_fixture, "extension")
      XMLHelper.add_element(extension, "MixedWaterGPD", ref_f_gpd)
      XMLHelper.add_element(extension, "SensibleGainsBtu", sens_gain)
      XMLHelper.add_element(extension, "LatentGainsBtu", lat_gain)
      
    else
    
      # Hot (not mixed) water GPD defined, so added to dishwasher instead.
      # Mixed water GPD here set to zero.
      ref_w_gpd = 0.0
    
      # New hot water distribution
      new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
      sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
      sys_type = XMLHelper.add_element(new_hw_dist, "SystemType")
      standard = XMLHelper.add_element(sys_type, "Standard")
      pipe_ins = XMLHelper.add_element(new_hw_dist, "PipeInsulation")
      XMLHelper.add_element(pipe_ins, "PipeRValue", 0)
      extension = XMLHelper.add_element(new_hw_dist, "extension")
      XMLHelper.add_element(extension, "MixedWaterGPD", ref_w_gpd)
      
      ref_f_gpd = 0.0
      
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
    
  end
  
  def self.set_systems_water_heating_use_rated(new_systems, orig_details)
  
    new_water_heating = new_systems.elements["WaterHeating"]
    
    # Table 4.2.2(1) - Service water heating systems
    
    if @eri_version.include? "A"
    
      orig_hw_dist = orig_details.elements["Systems/WaterHeating/HotWaterDistribution"]
      
      low_flow_fixtures = false
      orig_details.elements.each("Systems/WaterHeating/WaterFixture") do |wf|
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
          if not orig_hw_dist.elements["SystemType/Recirculation/RecirculationPipingLoopLength"].nil?
            recirc_loop_l = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/RecirculationPipingLoopLength"))
          else
            recirc_loop_l = get_loop_length_reference(get_pipe_length_reference(bsmnt))
          end
          recirc_control_type = XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/ControlType")
          recirc_pump_power = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Recirculation/PumpPower"))
        else
          if not orig_hw_dist.elements["SystemType/Standard/PipingLength"].nil?
            pipe_l = Float(XMLHelper.get_value(orig_hw_dist, "SystemType/Standard/PipingLength"))
          else
            pipe_l = get_pipe_length_reference(bsmnt)
          end
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
      XMLHelper.add_element(extension, "EnergyConsumptionAdjustmentFactor", ec_adj)
      if is_recirc
        XMLHelper.add_element(extension, "RecircPumpAnnualkWh", recirc_pump_annual_kwh)
      end

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
    
    else
      
      set_systems_water_heating_use_reference(new_systems, orig_details)
      
    end

  end
  
  def self.set_systems_water_heating_use_iad(new_systems, orig_details)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Service water heating systems
    set_systems_water_heating_use_reference(new_systems, orig_details)
    
    new_hw_dist = new_systems.elements["WaterHeating/HotWaterDistribution"]
    extension = new_hw_dist.elements["extension"]
    XMLHelper.add_element(extension, "EnergyConsumptionAdjustmentFactor", 1.0)
    
  end
  
  def self.set_systems_photovoltaics_reference(new_systems)
    # nop
  end
  
  def self.set_systems_photovoltaics_rated(new_systems, orig_details)
    new_pv = XMLHelper.copy_element(new_systems, orig_details, "Systems/Photovoltaics")
  end
  
  def self.set_systems_photovoltaics_iad(new_systems)
    
    # 4.3.1 Index Adjustment Design (IAD)
    # Renewable Energy Systems that offset the energy consumption requirements of the Rated Home shall not be included in the IAD.
    # nop
    
  end
  
  def self.set_appliances_clothes_washer_reference(new_appliances)
  
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    clothes_washer_kwh = 38.0 + 0.0*@cfa + 10.0*@nbeds
    clothes_washer_sens, clothes_washer_lat = get_clothes_washer_sens_lat(clothes_washer_kwh)
    if @eri_version.include? "A"
      clothes_washer_gpd = (4.52*(164.0 + 46.5*@nbeds))*((3.0*2.08 + 1.59)/(2.874*2.08 + 1.59))/365.0
    else
      clothes_washer_gpd = 0.0 # delta DHW change made to rated home
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
  
  def self.set_appliances_clothes_washer_rated(new_appliances, orig_details)
  
    # 4.2.2.5.2.10. Clothes Washers
    if orig_details.elements["Appliances/ClothesWasher/ModifiedEnergyFactor"]
      # Detailed
      ler = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/RatedAnnualkWh"))
      elec_rate = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/LabelElectricRate"))
      gas_rate = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/LabelGasRate"))
      agc = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/LabelAnnualGasCost"))
      cap = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/Capacity"))
      
      # Eq 4.2-9a
      ncy = (3.0/2.847)*(164 + @nbeds*45.6)
      if @eri_version.include? "A"
        ncy = (3.0/2.847)*(164 + @nbeds*46.5)
      end
      acy = ncy*((3.0*2.08 + 1.59)/(cap*2.08 + 1.59)) #Adjusted Cycles per Year
      clothes_washer_kwh = ((ler/392.0) - ((ler*elec_rate - agc)/(21.9825*elec_rate - gas_rate)/392.0)*21.9825)*acy
      clothes_washer_sens, clothes_washer_lat = get_clothes_washer_sens_lat(clothes_washer_kwh)
      clothes_washer_gpd = 60.0*((ler*elec_rate - agc)/(21.9825*elec_rate - gas_rate)/392.0)*acy/365.0
      if not @eri_version.include? "A"
        clothes_washer_gpd -= 3.97 # Section 4.2.2.5.2.10
      end
    elsif orig_details.elements["Appliances/ClothesWasher/extension/AnnualkWh"]
      # Simplified
      clothes_washer_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/AnnualkWh"))
      clothes_washer_sens = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/FracSensible"))
      clothes_washer_lat = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/FracLatent"))
      clothes_washer_gpd = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/extension/HotWaterGPD"))
    else
      # Reference
      set_appliances_clothes_washer_reference(new_appliances)
      return
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
  
  def self.set_appliances_clothes_washer_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_washer_reference(new_appliances)
  end

  def self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
    
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    # Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    dryer_fuel = XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/FuelType")
    clothes_dryer_kwh = 524.0 + 0.0*@cfa + 149.0*@nbeds
    clothes_dryer_therm = 0.0
    if dryer_fuel != 'electricity'
      clothes_dryer_kwh = 41.0 + 0.0*@cfa + 11.7*@nbeds
      clothes_dryer_therm = 18.8 + 0.0*@cfa + 5.3*@nbeds
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
  
    # 4.2.2.5.2.8. Clothes Dryers
    dryer_fuel = XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/FuelType")
    if orig_details.elements["Appliances/ClothesDryer/EfficiencyFactor"]
      # Detailed
      ef_dry = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/EfficiencyFactor"))
      has_timer_control = Boolean(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer[ControlType='timer']"))
      
      ler = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/RatedAnnualkWh"))
      cap = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/Capacity"))
      mef = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesWasher/ModifiedEnergyFactor"))
      
      # Eq 4.2-6 (FU)
      field_util_factor = nil
      if has_timer_control
        field_util_factor = 1.18
      else
        field_util_factor = 1.04
      end
      clothes_dryer_kwh = 12.5*(164.0 + 46.5*@nbeds)*(field_util_factor/ef_dry)*((cap/mef) - ler/392.0)/(0.2184*(cap*4.08 + 0.24)) # Eq 4.2-6
      clothes_dryer_therm = 0.0
      if dryer_fuel != 'electricity'
        clothes_dryer_therm = clothes_dryer_kwh*3412.0*(1.0-0.07)*(3.01/ef_dry)/100000 # Eq 4.2-7a
        clothes_dryer_kwh = clothes_dryer_kwh*0.07*(3.01/ef_dry)
      end
      clothes_dryer_sens, clothes_dryer_lat = get_clothes_dryer_sens_lat(dryer_fuel, clothes_dryer_kwh, clothes_dryer_therm)
    elsif orig_details.elements["Appliances/ClothesDryer/extension/AnnualkWh"]
      # Simplified
      clothes_dryer_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/AnnualkWh"))
      clothes_dryer_therm = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/AnnualTherm"))
      clothes_dryer_sens = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/FracSensible"))
      clothes_dryer_lat = Float(XMLHelper.get_value(orig_details, "Appliances/ClothesDryer/extension/FracLatent"))
    else
      # Reference
      set_appliances_clothes_dryer_reference(new_appliances, orig_details)
      return
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
  
  def self.set_appliances_clothes_dryer_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_clothes_dryer_reference(new_appliances, orig_details)
  end

  def self.set_appliances_dishwasher_reference(new_appliances)
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    dishwasher_kwh = 78.0 + 0.0*@cfa + 31.0*@nbeds
    dishwasher_sens, dishwasher_lat = get_dishwasher_sens_lat(dishwasher_kwh)
    if @eri_version.include? "A"
      dishwasher_gpd = ((88.4 + 34.9*@nbeds)*8.16)/365.0 # Eq. 4.2-2 (refDWgpd)
    else
      dishwasher_gpd = 0.0 # delta DHW change made to rated home
      # Add service water heating GPD here
      dishwasher_gpd += get_service_water_heating_use_gpd()
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
  
  def self.set_appliances_dishwasher_rated(new_appliances, orig_details)
  
    # 4.2.2.5.2.9. Dishwashers
    if orig_details.elements["Appliances/Dishwasher/EnergyFactor"] or orig_details.elements["Appliances/Dishwasher/RatedAnnualkWh"]
      # Detailed
      cap = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/PlaceSettingCapacity"))
      ef = XMLHelper.get_value(orig_details, "Appliances/Dishwasher/EnergyFactor")
      if ef.nil?
        rated_annual_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/RatedAnnualkWh"))
        ef = 215.0/rated_annual_kwh # Eq 4.2-8a (EF)
      else
        ef = ef.to_f
      end
      dwcpy = (88.4 + 34.9*@nbeds)*(12.0/cap) # Eq 4.2-8a (dWcpy)
      dishwasher_kwh = ((86.3 + 47.73/ef)/215.0)*dwcpy # Eq 4.2-8a
      dishwasher_sens, dishwasher_lat = get_dishwasher_sens_lat(dishwasher_kwh)
      if @eri_version.include? "A"
        dishwasher_gpd = dwcpy*(4.6415*(1.0/ef) - 1.9295)/365.0 # Eq. 4.2-11 (DWgpd)
      else
        dishwasher_gpd = ((88.4 + 34.9*@nbeds)*8.16 - (88.4 + 34.9*@nbeds)*12.0/cap*(4.6415*(1.0/ef) - 1.9295))/365.0 # Eq 4.2-8b
      end
    elsif orig_details.elements["Appliances/Dishwasher/extension/AnnualkWh"]
      # Simplified
      dishwasher_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/AnnualkWh"))
      dishwasher_sens = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/FracSensible"))
      dishwasher_lat = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/FracLatent"))
      dishwasher_gpd = Float(XMLHelper.get_value(orig_details, "Appliances/Dishwasher/extension/HotWaterGPD"))
    else
      # Reference
      set_appliances_dishwasher_reference(new_appliances)
      return
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
  
  def self.set_appliances_dishwasher_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_dishwasher_reference(new_appliances)
  end

  def self.set_appliances_refrigerator_reference(new_appliances)

    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    refrigerator_kwh = 637.0 + 0.0*@cfa + 18.0*@nbeds

    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
    extension = XMLHelper.add_element(new_fridge, "extension")
    XMLHelper.add_element(extension, "FracSensible", 1.0)
    XMLHelper.add_element(extension, "FracLatent", 0.0)
    
  end
  
  def self.set_appliances_refrigerator_rated(new_appliances, orig_details)

    # 4.2.2.5.2.5. Refrigerators
    if orig_details.elements["Appliances/Refrigerator/RatedAnnualkWh"]
      # Detailed
      refrigerator_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/Refrigerator/RatedAnnualkWh"))
    else
      # Reference
      set_appliances_refrigerator_reference(new_appliances)
      return
    end
    
    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    XMLHelper.add_element(new_fridge, "RatedAnnualkWh", refrigerator_kwh)
    
  end
  
  def self.set_appliances_refrigerator_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_refrigerator_reference(new_appliances)
  end

  def self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    # Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    
    # TODO: How to handle different fuel types for CookingRange vs Oven?
    range_fuel = XMLHelper.get_value(orig_details, "Appliances/CookingRange/FuelType")
    oven_fuel = XMLHelper.get_value(orig_details, "Appliances/Oven/FuelType")
    
    cooking_range_kwh = 331.0 + 0.0*@cfa + 39.0*@nbeds
    cooking_range_therm = 0.0
    if range_fuel != 'electricity' or oven_fuel != 'electricity'
      cooking_range_kwh = 22.6 + 0.0*@cfa + 2.7*@nbeds
      cooking_range_therm = 22.6 + 0.0*@cfa + 2.7*@nbeds
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

    # 4.2.2.5.2.7 Range/Oven
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
      
      cooking_range_kwh = burner_ef*oven_ef*(331 + 39.0*@nbeds)
      cooking_range_therm = 0.0
      if range_fuel != 'electricity' or oven_fuel != 'electricity'
        cooking_range_kwh = 22.6 + 2.7*@nbeds
        cooking_range_therm = oven_ef*(22.6 + 2.7*@nbeds)
      end
      cooking_range_sens, cooking_range_lat = get_cooking_range_sens_lat(range_fuel, oven_fuel, cooking_range_kwh, cooking_range_therm)
    elsif orig_details.elements["Appliances/CookingRange/extension/AnnualkWh"]
      # Simplified
      cooking_range_kwh = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/AnnualkWh"))
      cooking_range_therm = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/AnnualTherm"))
      cooking_range_sens = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/FracSensible"))
      cooking_range_lat = Float(XMLHelper.get_value(orig_details, "Appliances/CookingRange/extension/FracLatent"))
    else
      # Reference
      set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
      return
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
  
  def self.set_appliances_cooking_range_oven_iad(new_appliances, orig_details)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details)
  end

  def self.set_lighting_reference(new_lighting, orig_details)

    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    int_kwh = 455.0 + 0.80*@cfa + 0.0*@nbeds
    ext_kwh = 100.0 + 0.05*@cfa + 0.0*@nbeds
    grg_kwh = 0.0
    if @garage_present
      grg_kwh = 100.0
    end
    
    extension = XMLHelper.add_element(new_lighting, "extension")
    XMLHelper.add_element(extension, "AnnualInteriorkWh", int_kwh)
    XMLHelper.add_element(extension, "AnnualExteriorkWh", ext_kwh)
    XMLHelper.add_element(extension, "AnnualGaragekWh", grg_kwh)
    
  end
  
  def self.set_lighting_rated(new_lighting, orig_details)

    if orig_details.elements["Lighting/LightingFractions"]

      # Detailed
      if @eri_version.include? "G"
        fFI_int = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingTierIFixturesInterior"))
        fFI_ext = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingTierIFixturesExterior"))
        fFI_grg = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingTierIFixturesGarage"))
        fFII_int = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingTierIIFixturesInterior"))
        fFII_ext = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingTierIIFixturesExterior"))
        fFII_grg = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingTierIIFixturesGarage"))
        int_kwh, ext_kwh, grg_kwh = calc_lighting_addendum_g(fFI_int, fFII_int, fFI_ext, fFII_ext, fFI_grg, fFII_grg)
      else
        qFF_int = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingFixturesInterior"))
        qFF_ext = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingFixturesExterior"))
        qFF_grg = Float(XMLHelper.get_value(orig_details, "Lighting/LightingFractions/extension/FractionQualifyingFixturesGarage"))
        int_kwh, ext_kwh, grg_kwh = calc_lighting(qFF_int, qFF_ext, qFF_grg)
      end
      
    elsif orig_details.elements["Lighting/extension/AnnualInteriorkWh"]
      
      # Simplified
      int_kwh = Float(XMLHelper.get_value(orig_details, "Lighting/extension/AnnualInteriorkWh"))
      ext_kwh = Float(XMLHelper.get_value(orig_details, "Lighting/extension/AnnualExteriorkWh"))
      grg_kwh = 0
      if @garage_present
        grg_kwh = Float(XMLHelper.get_value(orig_details, "Lighting/extension/AnnualGaragekWh"))
      end
      
    else
      
      # Reference
      set_lighting_reference(new_lighting, orig_details)
      return
      
    end
    
    extension = XMLHelper.add_element(new_lighting, "extension")
    XMLHelper.add_element(extension, "AnnualInteriorkWh", int_kwh)
    XMLHelper.add_element(extension, "AnnualExteriorkWh", ext_kwh)
    XMLHelper.add_element(extension, "AnnualGaragekWh", grg_kwh)
    
  end
  
  def self.set_lighting_iad(new_lighting, orig_details)

    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    if @eri_version.include? "G"
      int_kwh, ext_kwh, grg_kwh = calc_lighting_addendum_g(0.75, 0.0, 0.75, 0.0, 0.75, 0.0)
    else
      int_kwh, ext_kwh, grg_kwh = calc_lighting(0.75, 0.75, 0.75)
    end
      
    extension = XMLHelper.add_element(new_lighting, "extension")
    XMLHelper.add_element(extension, "AnnualInteriorkWh", int_kwh)
    XMLHelper.add_element(extension, "AnnualExteriorkWh", ext_kwh)
    XMLHelper.add_element(extension, "AnnualGaragekWh", grg_kwh)
    
  end

  def self.set_lighting_ceiling_fans_reference(new_lighting)
    # FIXME
  end
  
  def self.set_lighting_ceiling_fans_rated(new_lighting)
    # FIXME
  end
  
  def self.set_lighting_ceiling_fans_iad(new_lighting)
    # FIXME
  end

  def self.set_misc_loads_reference(new_misc_loads)
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    
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
    # Table 4.2.2(1) - Internal gains

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
  
  def self.set_misc_loads_iad(new_misc_loads)
    # Table 4.3.1(1) Configuration of Index Adjustment Design - Lighting, Appliances and Miscellaneous Electric Loads (MELs)
    self.set_misc_loads_reference(new_misc_loads)
  end
  
  private

  def self.get_reference_component_characteristics(component_type)
    # Table 4.2.2(2) - Component Heat Transfer Characteristics for HERS Reference Home
    if component_type == "window" or component_type == "door"
      # Fenestration and Opaque Door U-Factor
      # Glazed Fenestration Assembly SHGC
      if ["1A", "1B", "1C"].include? @iecc_zone_2006
        return 1.2, 0.40
      elsif ["2A", "2B", "2C"].include? @iecc_zone_2006
        return 0.75, 0.40
      elsif ["3A", "3B", "3C"].include? @iecc_zone_2006
        return 0.65, 0.40
      elsif ["4A", "4B"].include? @iecc_zone_2006
        return 0.40, 0.40
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2006
        return 0.35, 0.40
      else
        return nil
      end
    elsif component_type == "frame_wall"
      # Frame Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B"].include? @iecc_zone_2006
        return 0.082
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C"].include? @iecc_zone_2006
        return 0.060
      elsif ["7", "8"].include? @iecc_zone_2006
        return 0.057
      else
        return nil
      end
    elsif component_type == "basement_wall"
      # Basement Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? @iecc_zone_2006
        return 0.360
      elsif ["4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2006
        return 0.059
      else
        return nil
      end
    elsif component_type == "floor"
      # Floor Over Unconditioned Space U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C"].include? @iecc_zone_2006
        return 0.064
      elsif ["3A", "3B", "3C", "4A", "4B"].include? @iecc_zone_2006
        return 0.047
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? @iecc_zone_2006
        return 0.033
      else
        return nil
      end
    elsif component_type == "ceiling"
      # Ceiling U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? @iecc_zone_2006
        return 0.035
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? @iecc_zone_2006
        return 0.030
      elsif ["6A", "6B", "6C", "7", "8"].include? @iecc_zone_2006
        return 0.026
      else
        return nil
      end
    elsif component_type == "slab_on_grade"
      # Slab-on-Grade R-Value & Depth (ft)
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? @iecc_zone_2006
        return 0.0, 0.0
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? @iecc_zone_2006
        return 10.0, 2.0
      elsif ["6A", "6B", "6C", "7", "8"].include? @iecc_zone_2006
        return 10.0, 4.0
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def self.get_pipe_length_reference(bsmnt)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    return 2.0*(@cfa/@ncfl)**0.5 + 10.0*@ncfl + 5.0*bsmnt # Eq. 4.2-13 (refPipeL)
  end
  
  def self.get_loop_length_reference(ref_pipe_l)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    return 2.0*ref_pipe_l - 20.0 # Eq. 4.2-17 (refLoopL)
  end
  
  def self.get_fixture_effectiveness_rated(low_flow_fixtures)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(1) Hot water fixture effectiveness
    f_eff = 1.0
    if low_flow_fixtures
      f_eff = 0.95
    end
    return f_eff
  end
  
  def self.get_fixtures_gpd_reference()
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    return 14.6 + 10.0*@nbeds # Eq. 4.2-2 (refFgpd)
  end
  
  def self.get_fixtures_gpd_rated(low_flow_fixtures)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    ref_f_gpd = get_fixtures_gpd_reference()
    f_eff = get_fixture_effectiveness_rated(low_flow_fixtures)
    return f_eff*ref_f_gpd
  end
  
  def self.get_waste_gpd_reference()
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    return 9.8*(@nbeds**0.43) # Eq. 4.2-2 (refWgpd)
  end
  
  def self.get_waste_gpd_rated(is_recirc, pipe_rvalue, pipe_l, recirc_branch_l, bsmnt, low_flow_fixtures)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    # 4.2.2.5.2.11 Service Hot Water Use
    
    # Table 4.2.2.5.2.11(2) Hot Water Distribution System Insulation Factors
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
      p_ratio = recirc_branch_l/10.0
    else
      ref_pipe_l = get_pipe_length_reference(bsmnt)
      p_ratio = pipe_l/ref_pipe_l
    end
    
    o_w_gpd = ref_w_gpd*o_frac*(1.0 - o_cd_eff) # Eq. 4.2-12
    s_w_gpd = (ref_w_gpd - ref_w_gpd*o_frac)*p_ratio*sys_factor # Eq. 4.2-13
    
    # Table 4.2.2.5.2.11(3) Distribution system water use effectiveness
    wd_eff = 1.0
    if is_recirc
      wd_eff = 0.10
    end
    
    f_eff = get_fixture_effectiveness_rated(low_flow_fixtures)
    
    hw_gpd = f_eff*(o_w_gpd + s_w_gpd*wd_eff) # Eq. 4.2-11
    
    return hw_gpd
  end
  
  def self.get_clothes_washer_sens_lat(clothes_washer_kwh)
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    load_sens = 95.0 + 26.0*@nbeds # Btu/day
    load_lat = 11.0 + 3.0*@nbeds # Btu/day
    total = UnitConversions.convert(clothes_washer_kwh, "kWh", "Btu")/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_clothes_dryer_sens_lat(dryer_fuel, clothes_dryer_kwh, clothes_dryer_therm)
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    if dryer_fuel != 'electricity'
      load_sens = 738.0 + 209.0*@nbeds # Btu/day
      load_lat = 91.0 + 26.0*@nbeds # Btu/day
    else
      load_sens = 661.0 + 188.0*@nbeds # Btu/day
      load_lat = 73.0 + 21.0*@nbeds # Btu/day
    end
    total = UnitConversions.convert(clothes_dryer_kwh, "kWh", "Btu")/365.0  # Btu/day
    total += UnitConversions.convert(clothes_dryer_therm, "therm", "Btu")/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_dishwasher_sens_lat(dishwasher_kwh)
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    load_sens = 219.0 + 87.0*@nbeds # Btu/day
    load_lat = 219.0 + 87.0*@nbeds # Btu/day
    total = UnitConversions.convert(dishwasher_kwh, "kWh", "Btu")/365.0
    return load_sens/total, load_lat/total
  end
  
  def self.get_cooking_range_sens_lat(range_fuel, oven_fuel, cooking_range_kwh, cooking_range_therm)
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    if range_fuel != 'electricity' or oven_fuel != 'electricity'
      load_sens = 4086.0 + 488.0*@nbeds # Btu/day
      load_lat = 1037.0 + 124.0*@nbeds # Btu/day
    else
      load_sens = 2228.0 + 262.0*@nbeds # Btu/day
      load_lat = 248.0 + 29.0*@nbeds # Btu/day
    end
    total = UnitConversions.convert(cooking_range_kwh, "kWh", "Btu")/365.0 # Btu/day
    total += UnitConversions.convert(cooking_range_therm, "therm", "Btu")/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_residual_mels_kwh()
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    return 0.91*@cfa
  end
  
  def self.get_residual_mels_sens_lat(residual_mels_kwh)
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    load_sens = 7.27*@cfa # Btu/day
    load_lat = 0.38*@cfa # Btu/day
    total = UnitConversions.convert(residual_mels_kwh, "kWh", "Btu")/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_televisions_kwh()
    # Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    return 413.0 + 0.0*@cfa + 69.0*@nbeds
  end
  
  def self.get_televisions_sens_lat(televisions_kwh)
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    load_sens = 3861.0 + 645.0*@nbeds # Btu/day
    load_lat = 0.0 # Btu/day
    total = UnitConversions.convert(televisions_kwh, "kWh", "Btu")/365.0 # Btu/day
    return load_sens/total, load_lat/total
  end
  
  def self.get_water_heater_ef_and_re(wh_fuel_type, wh_tank_vol)
    # # Table 4.2.2(1) - Service water heating systems
    ef = nil
    re = nil
    if wh_fuel_type == 'electricity'
      ef = 0.97 - (0.00132*wh_tank_vol)
    else
      ef = 0.67 - (0.0019*wh_tank_vol)
      if wh_fuel_type == 'natural gas' or wh_fuel_type == 'propane'
        re = 0.76
      elsif wh_fuel_type == 'fuel oil'
        re = 0.78
      end
    end
    return ef, re
  end
  
  def self.get_water_heater_ef_from_uef(wh_uef, wh_type, wh_fuel_type)
    # Interpretation on Water Heater UEF
    if wh_fuel_type == 'electricity'
      if wh_type == 'storage water heater'
        return [2.4029*wh_uef - 1.2844, 0.96].min
      elsif wh_type == 'instantaneous water heater'
        return wh_uef
      elsif wh_type == 'heat pump water heater'
        return 1.2101*wh_uef - 0.6052
      end
    else # Fuel
      if wh_type == 'storage water heater'
        return 0.9066*wh_uef + 0.0711
      elsif wh_type == 'instantaneous water heater'
        return wh_uef
      end
    end
    fail "Unable to calculated water heater EF from UEF."
  end
  
  def self.get_hwdist_energy_waste_factor(is_recirc, recirc_control_type, pipe_rvalue)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(6) Hot water distribution system relative annual energy waste factors
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
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(5) Annual electricity consumption factor for hot water recirculation system pumps
    if is_recirc
      if recirc_control_type == "no control" or recirc_control_type == "timer"
        return 8.76*recirc_pump_power
      elsif recirc_control_type == "temperature"
        return 1.46*recirc_pump_power
      elsif recirc_control_type == "presence sensor demand control"
        return 0.15*recirc_pump_power
      elsif recirc_control_type == "manual demand control"
        return 0.10*recirc_pump_power
      end
    end
    return nil
  end
  
  def self.get_hwdist_energy_consumption_adjustment(is_recirc, recirc_control_type, pipe_rvalue, pipe_l, loop_l, bsmnt)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-16
    ew_fact = get_hwdist_energy_waste_factor(is_recirc, recirc_control_type, pipe_rvalue)
    o_frac = 0.25 # fraction of hot water waste from standard operating conditions
    oew_fact = ew_fact*o_frac # standard operating condition portion of hot water energy waste
    ocd_eff = 0.0 # TODO: Need an HPXML input for this?
    sew_fact = ew_fact - oew_fact
    ref_pipe_l = get_pipe_length_reference(bsmnt)
    if not is_recirc
      pe_ratio = pipe_l/ref_pipe_l
    else
      ref_loop_l = get_loop_length_reference(ref_pipe_l)
      pe_ratio = loop_l/ref_loop_l
    end
    e_waste = oew_fact*(1.0 - ocd_eff) + sew_fact*pe_ratio
    return (e_waste + 128.0)/160.0
  end
  
  def self.get_dwhr_factors(bsmnt, pipe_l, is_recirc, recirc_branch_l, eff, equal_flow, all_showers, low_flow_fixtures)
    # ANSI/RESNET 301-2014 Addendum A-2015 
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-14
    
    eff_adj = 1.0
    if low_flow_fixtures
      eff_adj = 1.082
    end
    
    iFrac = 0.56 + 0.015*@nbeds - 0.0004*@nbeds**2 # fraction of hot water use impacted by DWHR
    
    if is_recirc
      pLength = recirc_branch_l
    else
      pLength = pipe_l
    end
    plc = 1 - 0.0002*pLength # piping loss coefficient
    
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
  
  def self.get_water_heater_tank_temperature()
    # Table 4.2.2(1) - Service water heating systems
    if @eri_version.include? "A"
      return 125.0
    end
    return 120.0
  end
  
  def self.get_service_water_heating_use_gpd()
    # Table 4.2.2(1) - Service water heating systems
    return 30.0*@ndu + 10.0*@nbeds
  end

  def self.get_occupants_heat_gain_sens_lat()
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
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
    # Table 4.2.2(3). Internal Gains for HERS Reference Homes
    sens_gains = -1227.0 - 409.0*@nbeds # Btu/day
    lat_gains = 1245.0 + 415.0*@nbeds # Btu/day
    return sens_gains*365.0, lat_gains*365.0
  end
  
  def self.get_shelter_coefficient()
    # Table 4.2.2(1)(g)
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
      fuels = ["natural gas", "fuel oil", "propane", "kerosene", "diesel",
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
    # FIXME: Looks wrong. Should be 'true'?
    if not orig_details.elements["Enclosure/Foundations/FoundationType/Basement[Conditioned='false']"].nil?
      bsmnt = 1.0
    end
    return bsmnt
  end
  
  def self.calc_mech_vent_q_fan(q_tot, sla)
    # TODO: Merge with Airflow measure and move this code to airflow.rb
    nl = 1000.0 * sla * @ncfl_ag ** 0.4 # Normalized leakage, eq. 4.4
    q_inf = nl * @weather.data.WSF * @cfa/7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
    if q_inf > 2.0/3.0 * q_tot
      return q_tot - 2.0/3.0 * q_tot
    end
    return q_tot - q_inf
  end

  def self.calc_lighting(qFF_int, qFF_ext, qFF_grg)
    if qFF_int < 0.1
      qFF_int = 0.1
    end
    int_kwh = 0.8*((4.0 - 3.0*qFF_int)/3.7)*(455.0 + 0.8*@cfa) + 0.2*(455.0 + 0.8*@cfa) # Eq 4.2-2
    ext_kwh = (100.0 + 0.05*@cfa)*(1.0 - qFF_ext) + 0.25*(100.0 + 0.05*@cfa)*qFF_ext # Eq 4.2-3
    grg_kwh = 0.0
    if @garage_present
      grg_kwh = 100.0*(1.0 - qFF_grg) + 25.0*qFF_grg # Eq 4.2-4
    end
    return int_kwh, ext_kwh, grg_kwh
  end
  
  def self.calc_lighting_addendum_g(fFI_int, fFII_int, fFI_ext, fFII_ext, fFI_grg, fFII_grg)
    # ANSI/RESNET/ICC 301-2014 Addendum G-2018, Solid State Lighting
    int_kwh = 0.9/0.925*(455.0 + 0.8*@cfa)*((1.0 - fFII_int - fFI_int) + fFI_int*15.0/60.0 + fFII_int*15.0/90.0) + 0.1*(455.0 + 0.8*@cfa) # Eq 4.2-2)
    ext_kwh = (100.0 + 0.05*@cfa)*(1.0 - fFI_ext - fFII_ext) + 15.0/60.0*(100.0 + 0.05*@cfa)*fFI_ext + 15.0/90.0*(100.0 + 0.05*@cfa)*fFII_ext # Eq 4.2-3
    grg_kwh = 0.0
    if @garage_present
      grg_kwh = 100.0*((1.0 - fFI_grg - fFII_grg) + 15.0/60.0*fFI_grg + 15.0/90.0*fFII_grg) # Eq 4.2-4
    end
    return int_kwh, ext_kwh, grg_kwh
  end

end
  
def is_external_thermal_boundary(interior_adjacent_to, exterior_adjacent_to)
  interior_conditioned = is_adjacent_to_conditioned(interior_adjacent_to)
  exterior_conditioned = is_adjacent_to_conditioned(exterior_adjacent_to)
  return (interior_conditioned != exterior_conditioned)
end

def is_adjacent_to_conditioned(adjacent_to)
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

def get_foundation_interior_adjacent_to(fnd_type)
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
  return interior_adjacent_to
end

def get_exterior_wall_area_fracs(orig_details)
  # Get individual exterior wall areas and sum
  wall_areas = {}
  wall_area_sum = 0.0
  orig_details.elements.each("Enclosure/Walls/Wall") do |wall|
    next if XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo") != "ambient"
    next if XMLHelper.get_value(wall, "extension/InteriorAdjacentTo") != "living space"
    wall_area = Float(XMLHelper.get_value(wall, "Area"))
    wall_areas[wall] = wall_area
    wall_area_sum += wall_area
  end
  
  # Convert to fractions
  wall_area_fracs = {}
  wall_areas.each do |wall, wall_area|
    wall_area_fracs[wall] = wall_areas[wall] / wall_area_sum
  end
  
  return wall_area_fracs
end