    
require 'rexml/document'
require 'rexml/xpath'

require "#{File.dirname(__FILE__)}/geometry"
    
def build_measure_args_from_hpxml(hpxml_file_path, weather_file_path)

  doc = REXML::Document.new(File.read(hpxml_file_path))

  event_types = []
  doc.elements.each("*/*/ProjectStatus/EventType") do |el|
    next unless el.text == "audit" # TODO: consider all event types?
    event_types << el.text
  end
  
  errors = []
  measures = {}
  
  get_facility_type(doc, event_types, errors)
  get_location(doc, event_types, measures, weather_file_path)
  get_beds_and_baths(doc, event_types, measures, errors)
  get_num_occupants(doc, event_types, measures, errors)
  get_door_area(doc, event_types, measures, errors)
  get_ceiling_constructions(doc, event_types, measures, errors)
  get_floor_constructions(doc, event_types, measures, errors)
  get_wall_constructions(doc, event_types, measures, errors)
  get_other_constructions(doc, event_types, measures, errors)
  get_window_constructions(doc, event_types, measures, errors)
  get_door_constructions(doc, event_types, measures, errors)
  get_water_heating(doc, event_types, measures, errors)
  get_heating_system(doc, event_types, measures, errors)
  get_cooling_system(doc, event_types, measures, errors)
  get_heat_pump(doc, event_types, measures, errors)
  get_heating_setpoint(doc, event_types, measures, errors)
  get_cooling_setpoint(doc, event_types, measures, errors)
  get_ceiling_fan(doc, event_types, measures, errors)
  get_refrigerator(doc, event_types, measures, errors)
  get_clothes_washer(doc, event_types, measures, errors)
  get_clothes_dryer(doc, event_types, measures, errors)
  get_dishwasher(doc, event_types, measures, errors)
  get_cooking_range(doc, event_types, measures, errors)
  get_lighting(doc, event_types, measures, errors)
  get_airflow(doc, event_types, measures, errors)
  get_hvac_sizing(doc, event_types, measures, errors)
  get_photovoltaics(doc, event_types, measures, errors)

  return errors, measures, doc, event_types

end
    
def average_across_elements(doc, parent_path, child_path, value_path, weight_path=nil, criteria=nil)

  numerator = 0
  denominator = 0
  doc.elements.each(parent_path) do |parent|
    criteria_fulfilled = true
    if not criteria.nil?
      criteria.each do |element, enumerations|
        if not enumerations.is_a? String
          if not parent.elements[element].nil?
            if not enumerations.include? parent.elements[element].text
              criteria_fulfilled = false
            end
          else
            criteria_fulfilled = false
          end
        else
          if not element_exists(parent.elements["#{element}/#{enumerations}"])
            criteria_fulfilled = false
          end
        end
      end
    end
    if criteria_fulfilled
      parent.elements.each(child_path) do |child|
        if not weight_path.nil?
          if not child.elements[value_path].nil? and not parent.elements[weight_path].nil?
            numerator += child.elements[value_path].text.to_f * parent.elements[weight_path].text.to_f
            denominator += parent.elements[weight_path].text.to_f
          end
        else
          if not child.elements[value_path].nil?
            numerator += child.elements[value_path].text.to_f
            denominator += 1.0
          end
        end
      end
    end
  end

  if denominator == 0
    return nil
  end
  return (numerator / denominator).to_s
  
end
    
def element_exists(element)
  if element.nil?
    return false
  else
    if element.text
      return true
    end
  end
  return false
end
    
def get_facility_type(doc, event_types, errors)

  facility_types_handled = ["single-family detached"]
  if doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].nil?
    errors << "Residential facility type not specified."
  elsif not facility_types_handled.include? doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].text
    errors << "Residential facility type not #{facility_types_handled.join(", ")}."
  end

end
    
def get_location(doc, event_types, measures, weather_file_path)

  measure_subdir = "ResidentialLocation"
  if not weather_file_path.nil?
    args = {
            "weather_directory"=>File.dirname(weather_file_path),
            "weather_file_name"=>File.basename(weather_file_path),
            "dst_start_date"=>"April 7",
            "dst_end_date"=>"October 26"
           }
    measures[measure_subdir] = args
  else
    errors << "Weather file path not specified."
  end

end
    
def get_beds_and_baths(doc, event_types, measures, errors)

  measure_subdir = "ResidentialGeometryNumBedsAndBaths"  
  num_bedrooms = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"]
  if num_bedrooms.nil?
    errors << "Number of bedrooms not found."
  end
  num_bathrooms = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms"]
  if num_bathrooms.nil?
    errors << "Number of bathrooms not found."
  end  
  if not num_bedrooms.nil? and not num_bathrooms.nil?
    args = {
            "num_bedrooms"=>num_bedrooms.text,
            "num_bathrooms"=>num_bathrooms.text
           }  
    measures[measure_subdir] = args
  end
  
end
    
def get_num_occupants(doc, event_types, measures, errors)

  measure_subdir = "ResidentialGeometryNumOccupants"  
  num_occupants = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents"]
  if not num_occupants.nil?
    args = {
            "num_occ"=>num_occupants.text,
            "weekday_sch"=>"1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000",
            "weekend_sch"=>"1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000",
            "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
           }
    measures[measure_subdir] = args
  else
    errors << "Number of residents not found."
  end
  
end
    
def get_door_area(doc, event_types, measures, errors)

  measure_subdir = "ResidentialGeometryDoorArea"  
  door_area = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Doors/Door/Area"]
  if not door_area.nil?
    args = {
            "door_area"=>door_area.text
           }  
    measures[measure_subdir] = args
  else
    errors << "Door area not found."
  end
  
end

def get_ceiling_constructions(doc, event_types, measures, errors)

  ceil_r = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic", "AtticFloorInsulation/Layer", "NominalRValue", "Area", {"AtticType"=>["vented attic", "venting unknown attic"]})
  if ceil_r.nil?
    ceil_r = "30"
  end  

  measure_subdir = "ResidentialConstructionsCeilingsRoofsUnfinishedAttic"
  args = {
          "ceil_r"=>ceil_r,
          "ceil_grade"=>"I",
          "ceil_ins_thick_in"=>"8.55",
          "ceil_ff"=>"0.07",
          "ceil_joist_height"=>"3.5",
          "roof_cavity_r"=>"0",
          "roof_cavity_grade"=>"I",
          "roof_cavity_ins_thick_in"=>"0",
          "roof_ff"=>"0.07",
          "roof_fram_thick_in"=>"7.25"
         }
  measures[measure_subdir] = args

  measure_subdir = "ResidentialConstructionsCeilingsRoofsFinishedRoof"
  args = {
          "cavity_r"=>"30",
          "install_grade"=>"I",
          "cavity_depth"=>"9.25",
          "ins_fills_cavity"=>"false",
          "framing_factor"=>"0.07"
         }  
  measures[measure_subdir] = args
  
  measure_subdir = "ResidentialConstructionsCeilingsRoofsRoofingMaterial"
  args = {
          "solar_abs"=>"0.85",
          "emissivity"=>"0.91",
          "material"=>"asphalt shingles",
          "color"=>"medium"
         }  
  measures[measure_subdir] = args

end

def get_floor_constructions(doc, event_types, measures, errors)

  exposed_perim = 0
  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    foundation.elements.each("Slab") do |slab|        
      unless slab.elements["ExposedPerimeter"].nil?
        exposed_perim += slab.elements["ExposedPerimeter"].text.to_f
      end
    end
  end

  measure_subdir = "ResidentialConstructionsFoundationsFloorsSlab"
  args = {
          "perim_r"=>"0",
          "perim_width"=>"0",
          "whole_r"=>"0",
          "gap_r"=>"0",
          "ext_r"=>"0",
          "ext_depth"=>"0",
          "mass_thick_in"=>"4",
          "mass_conductivity"=>"9.1",
          "mass_density"=>"140",
          "mass_specific_heat"=>"0.2",
          "exposed_perim"=>exposed_perim.to_s
         }  
  measures[measure_subdir] = args

  measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementFinished"
  args = {
          "wall_ins_height"=>"8",
          "wall_cavity_r"=>"0",
          "wall_cavity_grade"=>"I",
          "wall_cavity_depth"=>"0",
          "wall_cavity_insfills"=>"false",
          "wall_ff"=>"0",
          "wall_rigid_r"=>"10",
          "wall_rigid_thick_in"=>"2",
          "ceil_ff"=>"0.13",
          "ceil_joist_height"=>"9.25",
          "exposed_perim"=>exposed_perim.to_s
         }  
  measures[measure_subdir] = args
  
  measure_subdir = "ResidentialConstructionsFoundationsFloorsCrawlspace"
  args = {
          "wall_rigid_r"=>"10",
          "wall_rigid_thick_in"=>"2",
          "ceil_cavity_r"=>"0",
          "ceil_cavity_grade"=>"I",
          "ceil_ff"=>"0.13",
          "ceil_joist_height"=>"9.25",
          "exposed_perim"=>exposed_perim.to_s
         }  
  measures[measure_subdir] = args

end

def get_wall_constructions(doc, event_types, measures, errors)

  measure_subdir = "ResidentialConstructionsWallsExteriorWoodStud"
  cavity_r = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Walls/Wall", "Insulation/Layer", "NominalRValue", "Area", {"WallType"=>"WoodStud", "ExteriorAdjacentTo"=>["ambient"], "InteriorAdjacentTo"=>["living space"]})
  if cavity_r.nil?
    cavity_r = "13"
  end
  cavity_depth = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Walls/Wall", "Insulation/Layer", "Thickness", "Area", {"WallType"=>"WoodStud", "ExteriorAdjacentTo"=>["ambient"], "InteriorAdjacentTo"=>["living space"]})
  if cavity_depth.nil?
    cavity_depth = "3.5"
  end
  framing_factor = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Walls/Wall", "Studs", "FramingFactor", "Area", {"WallType"=>"WoodStud", "ExteriorAdjacentTo"=>["ambient"], "InteriorAdjacentTo"=>["living space"]})
  if framing_factor.nil?
    framing_factor = "0.13"
  end
  args = {
          "cavity_r"=>cavity_r,
          "install_grade"=>"I",
          "cavity_depth"=>cavity_depth,
          "ins_fills_cavity"=>"true",
          "framing_factor"=>framing_factor
         }
  measures[measure_subdir] = args

  measure_subdir = "ResidentialConstructionsWallsInterzonal"
  args = {
          "cavity_r"=>"10",
          "install_grade"=>"I",
          "cavity_depth"=>"3.5",
          "ins_fills_cavity"=>"true",
          "framing_factor"=>"0.25"
         }  
  measures[measure_subdir] = args

end

def get_other_constructions(doc, event_types, measures, errors)

  measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
  args = {}
  measures[measure_subdir] = args

end

def get_window_constructions(doc, event_types, measures, errors)

  measure_subdir = "ResidentialConstructionsWindows"
  ufactor = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Windows/Window", "", "UFactor", "Area")
  if ufactor.nil?
    ufactor = "0.37"
  end
  shgc = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Windows/Window", "", "SHGC", "Area")
  if shgc.nil?
    shgc = "0.3"
  end  
  args = {
          "ufactor"=>ufactor,
          "shgc"=>shgc,
          "heating_shade_mult"=>"0.7",
          "cooling_shade_mult"=>"0.7"
         }  
  measures[measure_subdir] = args

end

def get_door_constructions(doc, event_types, measures, errors)

  measure_subdir = "ResidentialConstructionsDoors"
  door_rvalue = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Enclosure/Doors/Door", "", "RValue", "Area")
  if door_rvalue.nil?
    door_rvalue = (1.0 / 0.2).to_s
  end
  args = {
          "door_uvalue"=>(1.0 / door_rvalue.to_f).to_s
         }  
  measures[measure_subdir] = args

end

def get_water_heating(doc, event_types, measures, errors)

  measure_subdir = nil
  args = {}

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem") do |dhw|
  
    errors << "Water heater type not specified." if dhw.elements["WaterHeaterType"].nil?
    
    if dhw.elements["WaterHeaterType"].text == "storage water heater"
      if dhw.elements["FuelType"].text == "electricity"
        measure_subdir = "ResidentialHotWaterHeaterTankElectric"
        args = {
                "tank_volume"=>"auto",
                "setpoint_temp"=>"125",
                "location"=>"auto",
                "capacity"=>"4.5",
                "energy_factor"=>dhw.elements["EnergyFactor"].text
               }
      elsif ["natural gas", "fuel oil", "propane"].include? dhw.elements["FuelType"].text
        measure_subdir = "ResidentialHotWaterHeaterTankFuel"
        args = {
                "fuel_type"=>{"natural gas"=>Constants.FuelTypeGas, "fuel oil"=>Constants.FuelTypeOil, "propane"=>Constants.FuelTypePropane}[dhw.elements["FuelType"].text],
                "tank_volume"=>"auto",
                "setpoint_temp"=>"125",
                "location"=>"auto",
                "capacity"=>"4.5",
                "energy_factor"=>dhw.elements["EnergyFactor"].text,
                "recovery_efficiency"=>"0.76",
                "offcyc_power"=>"0",
                "oncyc_power"=>"0"
               }
      end      
    elsif dhw.elements["WaterHeaterType"].text == "instantaneous water heater"
      if dhw.elements["FuelType"].text == "electricity"
        measure_subdir = "ResidentialHotWaterHeaterTanklessElectric"
        args = {
                "tank_volume"=>"auto",
                "setpoint_temp"=>"125",
                "location"=>"auto",
                "capacity"=>"100000000.0",
                "energy_factor"=>dhw.elements["EnergyFactor"].text
               }
      elsif ["natural gas", "fuel oil", "propane"].include? dhw.elements["FuelType"].text
        measure_subdir = "ResidentialHotWaterHeaterTanklessFuel"
        args = {
                "fuel_type"=>{"natural gas"=>Constants.FuelTypeGas, "fuel oil"=>Constants.FuelTypeOil, "propane"=>Constants.FuelTypePropane}[dhw.elements["FuelType"].text],
                "tank_volume"=>"auto",
                "setpoint_temp"=>"125",
                "location"=>"auto",
                "capacity"=>"100000000.0",
                "energy_factor"=>dhw.elements["EnergyFactor"].text,
                "recovery_efficiency"=>"0.76",
                "offcyc_power"=>"5",
                "oncyc_power"=>"65"
               }
      end       
    elsif dhw.elements["WaterHeaterType"].text == "heat pump water heater"
      measure_subdir = "ResidentialHotWaterHeaterHeatPump"
      args = {
              "storage_tank_volume"=>"50",
              "dhw_setpoint_temperature"=>"125",
              "space"=>"auto",
              "element_capacity"=>"4.5",
              "min_temp"=>"45",
              "max_temp"=>"120",
              "cap"=>"0.5",
              "cop"=>"2.8",
              "shr"=>"0.88",
              "airflow_rate"=>"181",
              "fan_power"=>"0.0462",
              "parasitics"=>"3",
              "tank_ua"=>"3.9",
              "int_factor"=>"1.0"
             }
    else
      errors << "#{dhw.elements["WaterHeaterType"].text} water heating system type not supported."
    end
  
  end
  
  unless measure_subdir.nil?
    measures[measure_subdir] = args
  end

end

def get_heating_system(doc, event_types, measures, errors)

  measure_subdir = nil
  args = {}

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |htgsys|
  
    next if htgsys.elements["FractionHeatLoadServed"].nil?
    next unless htgsys.elements["FractionHeatLoadServed"].text == "1"
    next if htgsys.elements["HeatingSystemType"].nil?
  
    if element_exists(htgsys.elements["HeatingSystemType/Furnace"])
      if htgsys.elements["HeatingSystemFuel"].text == "electricity"
        measure_subdir = "ResidentialHVACFurnaceElectric"
        args = {
                "afue"=>"1",
                "fan_power_installed"=>"0.5",
                "capacity"=>"autosize"
               }
      elsif ["natural gas", "fuel oil", "propane"].include? htgsys.elements["HeatingSystemFuel"].text
        measure_subdir = "ResidentialHVACFurnaceFuel"
        args = {
                "fuel_type"=>{"natural gas"=>Constants.FuelTypeGas, "fuel oil"=>Constants.FuelTypeOil, "propane"=>Constants.FuelTypePropane}[htgsys.elements["HeatingSystemFuel"].text],
                "afue"=>"1",
                "fan_power_installed"=>"0.5",
                "capacity"=>"autosize"
               }
      end
    elsif element_exists(htgsys.elements["HeatingSystemType/WallFurnace"])
      errors << "Wall furnace heating system type not supported."
    elsif element_exists(htgsys.elements["HeatingSystemType/Boiler"])
      if htgsys.elements["HeatingSystemFuel"].text == "electricity"
        measure_subdir = "ResidentialHVACBoilerElectric"
        args = {
                "system_type"=>"hot water, forced draft",
                "afue"=>"1",
                "oat_reset_enabled"=>"false",
                "capacity"=>"autosize"
               }
      elsif ["natural gas", "fuel oil", "propane"].include? htgsys.elements["HeatingSystemFuel"].text
        measure_subdir = "ResidentialHVACBoilerFuel"
        args = {
                "fuel_type"=>{"natural gas"=>Constants.FuelTypeGas, "fuel oil"=>Constants.FuelTypeOil, "propane"=>Constants.FuelTypePropane}[htgsys.elements["HeatingSystemFuel"].text],
                "system_type"=>"hot water, forced draft",
                "afue"=>"1",
                "oat_reset_enabled"=>"false",
                "modulation"=>"false",
                "capacity"=>"autosize"
               }
      end
    elsif element_exists(htgsys.elements["HeatingSystemType/ElectricResistance"])
      measure_subdir = "ResidentialHVACElectricBaseboard"
      args = {
              "efficiency"=>"1",
              "capacity"=>"autosize"
             }
    elsif element_exists(htgsys.elements["HeatingSystemType/Fireplace"])
      errors << "Fireplace heating system type not supported."
    elsif element_exists(htgsys.elements["HeatingSystemType/Stove"])
      errors << "Stove heating system type not supported."
    elsif element_exists(htgsys.elements["HeatingSystemType/PortableHeater"])
      errors << "Portable heater heating system type not supported."
    elsif element_exists(htgsys.elements["HeatingSystemType/SolarThermal"])
      errors << "Solar thermal heating system type not supported."
    elsif element_exists(htgsys.elements["HeatingSystemType/DistrictSteam"])
      errors << "District steam heating system type not supported."
    elsif element_exists(htgsys.elements["HeatingSystemType/Other"])
      errors << "Other heating system type not supported."
    end
  
  end
  
  unless measure_subdir.nil?
    measures[measure_subdir] = args
  end

end

def get_cooling_system(doc, event_types, measures, errors)

  measure_subdir = nil
  args = {}

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |clgsys|
  
    next if clgsys.elements["FractionCoolLoadServed"].nil?
    next unless clgsys.elements["FractionCoolLoadServed"].text == "1"      
    next if clgsys.elements["CoolingSystemType"].nil?
  
    if clgsys.elements["CoolingSystemType"].text == "central air conditioning"
      clgsys.elements.each("AnnualCoolingEfficiency") do |eff|
        if eff.elements["Value"].text.to_f < 16
          measure_subdir = "ResidentialHVACCentralAirConditionerSingleSpeed"
          args = {
                  "seer"=>"13",
                  "eer"=>"11.1",
                  "shr"=>"0.73",
                  "fan_power_rated"=>"0.365",
                  "fan_power_installed"=>"0.5",
                  "crankcase_capacity"=>"0",
                  "crankcase_max_temp"=>"55",
                  "eer_capacity_derate_1ton"=>"1",
                  "eer_capacity_derate_2ton"=>"1",
                  "eer_capacity_derate_3ton"=>"1",
                  "eer_capacity_derate_4ton"=>"1",
                  "eer_capacity_derate_5ton"=>"1",
                  "capacity"=>"autosize"
                 }
        elsif eff.elements["Value"].text.to_f >= 16 and eff.elements["Value"].text.to_f <= 21
          measure_subdir = "ResidentialHVACCentralAirConditionerTwoSpeed"
          args = {
                  "seer"=>"16",
                  "eer"=>"13.5",
                  "eer2"=>"12.4",
                  "shr"=>"0.71",
                  "shr2"=>"0.73",
                  "capacity_ratio"=>"0.72",
                  "capacity_ratio2"=>"1",
                  "fan_speed_ratio"=>"0.86",
                  "fan_speed_ratio2"=>"1",                  
                  "fan_power_rated"=>"0.14",
                  "fan_power_installed"=>"0.3",
                  "crankcase_capacity"=>"0",
                  "crankcase_max_temp"=>"55",
                  "eer_capacity_derate_1ton"=>"1",
                  "eer_capacity_derate_2ton"=>"1",
                  "eer_capacity_derate_3ton"=>"1",
                  "eer_capacity_derate_4ton"=>"1",
                  "eer_capacity_derate_5ton"=>"1",
                  "capacity"=>"autosize"
                 }
        else
          measure_subdir = "ResidentialHVACCentralAirConditionerVariableSpeed"
          args = {
                  "seer"=>"24.5",
                  "eer"=>"19.2",
                  "eer2"=>"18.3",
                  "eer3"=>"16.5",
                  "eer4"=>"14.6",                  
                  "shr"=>"0.98",
                  "shr2"=>"0.82",
                  "shr3"=>"0.745",
                  "shr4"=>"0.77",                  
                  "capacity_ratio"=>"0.36",
                  "capacity_ratio2"=>"0.64",
                  "capacity_ratio3"=>"1",
                  "capacity_ratio4"=>"1.16",                  
                  "fan_speed_ratio"=>"0.51",
                  "fan_speed_ratio2"=>"84",
                  "fan_speed_ratio3"=>"1",
                  "fan_speed_ratio4"=>"1.19",                  
                  "fan_power_rated"=>"0.14",
                  "fan_power_installed"=>"0.3",
                  "crankcase_capacity"=>"0",
                  "crankcase_max_temp"=>"55",
                  "eer_capacity_derate_1ton"=>"1",
                  "eer_capacity_derate_2ton"=>"1",
                  "eer_capacity_derate_3ton"=>"0.89",
                  "eer_capacity_derate_4ton"=>"0.89",
                  "eer_capacity_derate_5ton"=>"0.89",
                  "capacity"=>"autosize"
                 }
        end
      end
    elsif clgsys.elements["CoolingSystemType"].text == "mini-split"
      measure_subdir = "ResidentialHVACMiniSplitHeatPump"
      args = {
              "seer"=>"14.5",
              "min_cooling_capacity"=>"0.4",
              "max_cooling_capacity"=>"1.2",
              "shr"=>"0.73",
              "min_cooling_airflow_rate"=>"200",
              "max_cooling_airflow_rate"=>"425",
              "hspf"=>"8.2",
              "heating_capacity_offset"=>"2300",
              "min_heating_capacity"=>"0.3",
              "max_heating_capacity"=>"1.2",
              "min_heating_airflow_rate"=>"200",
              "max_heating_airflow_rate"=>"400",
              "cap_retention_frac"=>"0.25",
              "cap_retention_temp"=>"-5",
              "pan_heater_power"=>"0",
              "fan_power"=>"0.07",
              "heat_pump_capacity"=>"autosize",
              "supplemental_efficiency"=>"1",
              "supplemental_capacity"=>"autosize"
             }
    elsif clgsys.elements["CoolingSystemType"].text == "room air conditioner"
      measure_subdir = "ResidentialHVACRoomAirConditioner"
      args = {
              "eer"=>"8.5",
              "shr"=>"0.65",
              "airflow_rate"=>"350",
              "capacity"=>"autosize"
             }
    else
      errors << "#{clgsys.elements["CoolingSystemType"].text} cooling system type not supported."
    end  
  
  end
  
  unless measure_subdir.nil?
    measures[measure_subdir] = args
  end

end

def get_heat_pump(doc, event_types, measures, errors)

  measure_subdir = nil
  args = {}

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |hp|
  
    next if hp.elements["FractionHeatLoadServed"].nil?
    next unless hp.elements["FractionHeatLoadServed"].text == "1"      
    next if hp.elements["HeatPumpType"].nil?
  
    if hp.elements["HeatPumpType"].text == "air-to-air"        
      hp.elements.each("AnnualCoolingEfficiency") do |eff|
        if eff.elements["Value"].text.to_f < 16
          measure_subdir = "ResidentialHVACAirSourceHeatPumpSingleSpeed"
          args = {
                  "seer"=>"13",
                  "hspf"=>"7.7",
                  "eer"=>"11.4",
                  "cop"=>"3.05",
                  "shr"=>"0.73",
                  "fan_power_rated"=>"0.365",
                  "fan_power_installed"=>"0.5",
                  "min_temp"=>"0",
                  "crankcase_capacity"=>"0.02",
                  "crankcase_max_temp"=>"55",
                  "eer_capacity_derate_1ton"=>"1",
                  "eer_capacity_derate_2ton"=>"1",
                  "eer_capacity_derate_3ton"=>"1",
                  "eer_capacity_derate_4ton"=>"1",
                  "eer_capacity_derate_5ton"=>"1",
                  "cop_capacity_derate_1ton"=>"1",
                  "cop_capacity_derate_2ton"=>"1",
                  "cop_capacity_derate_3ton"=>"1",
                  "cop_capacity_derate_4ton"=>"1",
                  "cop_capacity_derate_5ton"=>"1",
                  "heat_pump_capacity"=>"autosize",
                  "supplemental_capacity"=>"autosize"
                 }
        elsif eff.elements["Value"].text.to_f >= 16 and eff.elements["Value"].text.to_f <= 21
          measure_subdir = "ResidentialHVACAirSourceHeatPumpTwoSpeed"
          args = {
                  "seer"=>"16",
                  "hspf"=>"8.6",
                  "eer"=>"13.1",
                  "eer2"=>"11.7",
                  "cop"=>"3.8",
                  "cop2"=>"3.3",
                  "shr"=>"0.71",
                  "shr2"=>"0.723",
                  "capacity_ratio"=>"0.72",
                  "capacity_ratio2"=>"1",
                  "fan_speed_ratio_cooling"=>"0.86",
                  "fan_speed_ratio_cooling2"=>"1",
                  "fan_speed_ratio_heating"=>"0.8",
                  "fan_speed_ratio_heating2"=>"1",
                  "fan_power_rated"=>"0.14",
                  "fan_power_installed"=>"0.3",
                  "min_temp"=>"0",
                  "crankcase_capacity"=>"0.02",
                  "crankcase_max_temp"=>"55",
                  "eer_capacity_derate_1ton"=>"1",
                  "eer_capacity_derate_2ton"=>"1",
                  "eer_capacity_derate_3ton"=>"1",
                  "eer_capacity_derate_4ton"=>"1",
                  "eer_capacity_derate_5ton"=>"1",
                  "cop_capacity_derate_1ton"=>"1",
                  "cop_capacity_derate_2ton"=>"1",
                  "cop_capacity_derate_3ton"=>"1",
                  "cop_capacity_derate_4ton"=>"1",
                  "cop_capacity_derate_5ton"=>"1",
                  "heat_pump_capacity"=>"autosize",
                  "supplemental_capacity"=>"autosize"
                 }
        else
          measure_subdir = "ResidentialHVACAirSourceHeatPumpVariableSpeed"
          args = {
                  "seer"=>"22",
                  "hspf"=>"10",
                  "eer"=>"17.4",
                  "eer2"=>"16.8",
                  "eer3"=>"14.3",
                  "eer4"=>"13",                  
                  "cop"=>"4.82",
                  "cop2"=>"4.56",
                  "cop3"=>"3.89",
                  "cop4"=>"3.92",                  
                  "shr"=>"0.84",
                  "shr2"=>"0.79",
                  "shr3"=>"0.76",
                  "shr4"=>"0.77",                  
                  "capacity_ratio"=>"0.49",
                  "capacity_ratio2"=>"0.67",
                  "capacity_ratio3"=>"0.1",
                  "capacity_ratio4"=>"1.2",                  
                  "fan_speed_ratio_cooling"=>"0.7",
                  "fan_speed_ratio_cooling2"=>"0.9",
                  "fan_speed_ratio_cooling3"=>"1",
                  "fan_speed_ratio_cooling4"=>"1.26",                  
                  "fan_speed_ratio_heating"=>"0.74",
                  "fan_speed_ratio_heating2"=>"0.92",
                  "fan_speed_ratio_heating3"=>"1",
                  "fan_speed_ratio_heating4"=>"1.22",                  
                  "fan_power_rated"=>"0.14",
                  "fan_power_installed"=>"0.3",
                  "min_temp"=>"0",
                  "crankcase_capacity"=>"0.02",
                  "crankcase_max_temp"=>"55",
                  "eer_capacity_derate_1ton"=>"1",
                  "eer_capacity_derate_2ton"=>"1",
                  "eer_capacity_derate_3ton"=>"0.95",
                  "eer_capacity_derate_4ton"=>"0.95",
                  "eer_capacity_derate_5ton"=>"0.95",
                  "cop_capacity_derate_1ton"=>"1",
                  "cop_capacity_derate_2ton"=>"1",
                  "cop_capacity_derate_3ton"=>"1",
                  "cop_capacity_derate_4ton"=>"1",
                  "cop_capacity_derate_5ton"=>"1",
                  "heat_pump_capacity"=>"autosize",
                  "supplemental_capacity"=>"autosize"
                 }
        end
      end
    elsif hp.elements["HeatPumpType"].text == "mini-split"
      measure_subdir = "ResidentialHVACMiniSplitHeatPump"
      args = {
              "seer"=>"14.5",
              "min_cooling_capacity"=>"0.4",
              "max_cooling_capacity"=>"1.2",
              "shr"=>"0.73",
              "min_cooling_airflow_rate"=>"200",
              "max_cooling_airflow_rate"=>"425",
              "hspf"=>"8.2",
              "heating_capacity_offset"=>"2300",
              "min_heating_capacity"=>"0.3",
              "max_heating_capacity"=>"1.2",
              "min_heating_airflow_rate"=>"200",
              "max_heating_airflow_rate"=>"400",
              "cap_retention_frac"=>"0.25",
              "cap_retention_temp"=>"-5",
              "pan_heater_power"=>"0",
              "fan_power"=>"0.07",
              "heat_pump_capacity"=>"autosize",
              "supplemental_efficiency"=>"1",
              "supplemental_capacity"=>"autosize"
             }
    elsif hp.elements["HeatPumpType"].text == "ground-to-air"
      errors << "Ground source heat pump not yet supported."
    else
      errors << "#{hp.elements["HeatPumpType"].text} heat pump type not supported."
    end
  
  end
  
  unless measure_subdir.nil?
    measures[measure_subdir] = args
  end  

end

def get_heating_setpoint(doc, event_types, measures, errors) 

  measure_subdir = "ResidentialHVACHeatingSetpoints"
  htg_wkdy = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACControl", "", "SetpointTempHeatingSeason")
  if htg_wkdy.nil?
    htg_wkdy = "71"
  end
  htg_wked = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACControl", "", "SetpointTempHeatingSeason")
  if htg_wked.nil?
    htg_wked = "71"
  end
  args = {
          "htg_wkdy"=>htg_wkdy,
          "htg_wked"=>htg_wked
         }  
  measures[measure_subdir] = args
  
end

def get_cooling_setpoint(doc, event_types, measures, errors)

  measure_subdir = "ResidentialHVACCoolingSetpoints"
  clg_wkdy = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACControl", "", "SetupTempCoolingSeason")
  if clg_wkdy.nil?
    clg_wkdy = "76"
  end
  clg_wked = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/HVAC/HVACControl", "", "SetupTempCoolingSeason")
  if clg_wked.nil?
    clg_wked = "76"
  end
  args = {
          "clg_wkdy"=>clg_wkdy,
          "clg_wked"=>clg_wked
         }  
  measures[measure_subdir] = args

end

def get_ceiling_fan(doc, event_types, measures, errors)

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Lighting/CeilingFan") do |cf|
    measure_subdir = "ResidentialHVACCeilingFan"
    args = {
            "coverage"=>"NA",
            "specified_num"=>"1",
            "power"=>"45",
            "control"=>"typical",
            "use_benchmark_energy"=>"true",
            "mult"=>"1",
            "cooling_setpoint_offset"=>"0",
            "weekday_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "weekend_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "monthly_sch"=>"1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248"
           }  
    measures[measure_subdir] = args
    break
  end  

end

def get_refrigerator(doc, event_types, measures, errors)

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Appliances/Refrigerator") do |ref|
    measure_subdir = "ResidentialApplianceRefrigerator"  
    fridge_E = ref.elements["RatedAnnualkWh"]
    if not fridge_E.nil?
      args = {
              "fridge_E"=>fridge_E.text,
              "mult"=>"1",
              "weekday_sch"=>"0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041",
              "weekend_sch"=>"0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041",
              "monthly_sch"=>"0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837",
              "space"=>"auto"
             }  
      measures[measure_subdir] = args
    else
      errors << "Refrigerator does not have rated annual kWh."
    end
    break
  end
  
end

def get_clothes_washer(doc, event_types, measures, errors)

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Appliances/ClothesWasher") do |cw|
    measure_subdir = "ResidentialApplianceClothesWasher"  
    cw_imef = cw.elements["ModifiedEnergyFactor"]
    if not cw_imef.nil?
      args = {
              "cw_imef"=>cw_imef.text,
              "cw_rated_annual_energy"=>"387",
              "cw_annual_cost"=>"24",
              "cw_test_date"=>"2007",
              "cw_drum_volume"=>"3.5",
              "cw_cold_cycle"=>"false",
              "cw_thermostatic_control"=>"true",
              "cw_internal_heater"=>"false",
              "cw_fill_sensor"=>"false",
              "cw_mult_e"=>"1",
              "cw_mult_hw"=>"1",
              "space"=>"auto",
              "plant_loop"=>"auto"
             }  
      measures[measure_subdir] = args
    else
      errors << "Clothes washer does not have modified energy factor."
    end
    break
  end
  
end

def get_clothes_dryer(doc, event_types, measures, errors)
  
  measure_subdir = nil
  args = {}
  
  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Appliances/ClothesDryer") do |cd|
    if cd.elements["FuelType"].text == "electricity"
      measure_subdir = "ResidentialApplianceClothesDryerElectric"
      args = {
              "cd_cef"=>"2.7",
              "cd_mult"=>"1",
              "cd_weekday_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "cd_weekend_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "cd_monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0",
              "space"=>"auto"
             }
      break
    elsif ["natural gas", "fuel oil", "propane"].include? cd.elements["FuelType"].text
      measure_subdir = "ResidentialApplianceClothesDryerFuel"
      args = {
              "cd_fuel_type"=>{"natural gas"=>Constants.FuelTypeGas, "fuel oil"=>Constants.FuelTypeOil, "propane"=>Constants.FuelTypePropane}[cd.elements["FuelType"].text],
              "cd_cef"=>"2.4",
              "cd_fuel_split"=>"0.07",
              "cd_mult"=>"1",
              "cd_weekday_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "cd_weekend_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "cd_monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0",
              "space"=>"auto"
             }
      break
    end
    break
  end
  
  unless measure_subdir.nil?
    measures[measure_subdir] = args
  end
  
end

def get_dishwasher(doc, event_types, measures, errors)

  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Appliances/Dishwasher") do |dw|  
    measure_subdir = "ResidentialApplianceDishwasher"
    args = {
            "num_settings"=>"12",
            "dw_E"=>"290",
            "int_htr"=>"true",
            "cold_inlet"=>"false",
            "cold_use"=>"0",
            "eg_date"=>"2007",
            "eg_gas_cost"=>"23",
            "mult_e"=>"1",
            "mult_hw"=>"1",
            "space"=>"auto",
            "plant_loop"=>"auto"
           }  
    measures[measure_subdir] = args
    break
  end

end

def get_cooking_range(doc, event_types, measures, errors)
  
  measure_subdir = nil
  args = {}  
  
  doc.elements.each("//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Appliances/Oven") do |ov|
    if ov.elements["FuelType"].text == "electricity"
      measure_subdir = "ResidentialApplianceCookingRangeElectric"
      args = {
              "c_ef"=>"0.74",
              "o_ef"=>"0.11",
              "mult"=>"1",
              "weekday_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "weekend_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "monthly_sch"=>"1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097",
              "space"=>"auto"
             }
      break
    elsif ["natural gas", "fuel oil", "propane"].include? ov.elements["FuelType"].text    
      measure_subdir = "ResidentialApplianceCookingRangeFuel"
      args = {
              "fuel_type"=>{"natural gas"=>Constants.FuelTypeGas, "fuel oil"=>Constants.FuelTypeOil, "propane"=>Constants.FuelTypePropane}[ov.elements["FuelType"].text],
              "c_ef"=>"0.4",
              "o_ef"=>"0.058",
              "e_ignition"=>true,
              "mult"=>"1",
              "weekday_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "weekend_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "monthly_sch"=>"1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097",
              "space"=>"auto"
             }
      break
    end
  end
  
  unless measure_subdir.nil?
    measures[measure_subdir] = args
  end  

end

def get_lighting(doc, event_types, measures, errors)

  measure_subdir = "ResidentialLighting"
  cfl = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Lighting/LightingFractions/FractionCFL"]
  led = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Lighting/LightingFractions/FractionLED"]
  lfl = doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Lighting/LightingFractions/FractionLFL"]
  if not cfl.nil? and not led.nil? and not lfl.nil?
    args = {
            "hw_cfl"=>cfl.text,
            "hw_led"=>led.text,
            "hw_lfl"=>lfl.text,
            "pg_cfl"=>cfl.text,
            "pg_led"=>led.text,
            "pg_lfl"=>lfl.text,
            "in_eff"=>"15",
            "cfl_eff"=>"55",
            "led_eff"=>"80",
            "lfl_eff"=>"88"
           }  
    measures[measure_subdir] = args  
  end

end

def get_airflow(doc, event_types, measures, errors)

  measure_subdir = "ResidentialAirflow"
  args = {
          "living_ach50"=>"7",
          "garage_ach50"=>"7",
          "finished_basement_ach"=>"0",
          "unfinished_basement_ach"=>"0.1",
          "crawl_ach"=>"0",
          "pier_beam_ach"=>"100",
          "unfinished_attic_sla"=>"0.00333",
          "shelter_coef"=>"auto",
          "has_hvac_flue"=>"false",
          "has_water_heater_flue"=>"false",
          "has_fireplace_chimney"=>"false",
          "terrain"=>"suburban",
          "mech_vent_type"=>"exhaust",
          "mech_vent_total_efficiency"=>"0",
          "mech_vent_sensible_efficiency"=>"0",
          "mech_vent_fan_power"=>"0.3",
          "mech_vent_frac_62_2"=>"1.0",
          "mech_vent_ashrae_std"=>"2010",
          "mech_vent_infil_credit"=>"true",
          "is_existing_home"=>"false",
          "clothes_dryer_exhaust"=>"1",
          "nat_vent_htg_offset"=>"1",
          "nat_vent_clg_offset"=>"1",
          "nat_vent_ovlp_offset"=>"1",
          "nat_vent_htg_season"=>"true",
          "nat_vent_clg_season"=>"true",
          "nat_vent_ovlp_season"=>"true",
          "nat_vent_num_weekdays"=>"3",
          "nat_vent_num_weekends"=>"0",
          "nat_vent_frac_windows_open"=>"0.33",
          "nat_vent_frac_window_area_openable"=>"0.2",
          "nat_vent_max_oa_hr"=>"0.0115",
          "nat_vent_max_oa_rh"=>"0.7",
          "duct_location"=>"auto",
          "duct_total_leakage"=>"0.3",
          "duct_supply_frac"=>"0.6",
          "duct_return_frac"=>"0.067",
          "duct_ah_supply_frac"=>"0.067",
          "duct_ah_return_frac"=>"0.267",
          "duct_location_frac"=>"auto",
          "duct_num_returns"=>"auto",
          "duct_supply_area_mult"=>"1",
          "duct_return_area_mult"=>"1",
          "duct_unconditioned_r"=>"0"
         }  
  measures[measure_subdir] = args

end

def get_hvac_sizing(doc, event_types, measures, errors)
  
  measure_subdir = "ResidentialHVACSizing"
  args = {
          "show_debug_info"=>"false"
         }  
  measures[measure_subdir] = args

end

def get_photovoltaics(doc, event_types, measures, errors)

  inverter_efficiency = average_across_elements(doc, "//Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/Systems/Photovoltaics/PVSystem", "", "InverterEfficiency", "CollectorArea")
  if inverter_efficiency.nil?
    inverter_efficiency = "96"
  end
  measure_subdir = "ResidentialPhotovoltaics"
  args = {
          "size"=>"2.5",
          "module_type"=>"standard",
          "system_losses"=>"0.14",
          "inverter_efficiency"=>(inverter_efficiency.to_f * 0.01).to_s,
          "azimuth_type"=>"relative",
          "azimuth"=>"180",
          "tile_type"=>"pitch",
          "tilt"=>"0"
         }  
  measures[measure_subdir] = args

end
