  
require "#{File.dirname(__FILE__)}/geometry"

class OSMeasures    

  def self.build_measure_args_from_hpxml(building, weather_file_path)

    errors = []
    measures = {}
    
    get_facility_type(building, errors)
    get_location(building, measures, weather_file_path)
    get_beds_and_baths(building, measures, errors)
    get_num_occupants(building, measures, errors)
    get_door_area(building, measures, errors)
    get_ceiling_constructions(building, measures, errors)
    get_floor_constructions(building, measures, errors)
    get_wall_constructions(building, measures, errors)
    get_other_constructions(building, measures, errors)
    get_window_constructions(building, measures, errors)
    get_door_constructions(building, measures, errors)
    get_water_heating(building, measures, errors)
    get_heating_system(building, measures, errors)
    get_cooling_system(building, measures, errors)
    get_heat_pump(building, measures, errors)
    get_heating_setpoint(building, measures, errors)
    get_cooling_setpoint(building, measures, errors)
    get_ceiling_fan(building, measures, errors)
    get_refrigerator(building, measures, errors)
    get_clothes_washer(building, measures, errors)
    get_clothes_dryer(building, measures, errors)
    get_dishwasher(building, measures, errors)
    get_cooking_range(building, measures, errors)
    get_lighting(building, measures, errors)
    get_airflow(building, measures, errors)
    get_hvac_sizing(building, measures, errors)
    get_photovoltaics(building, measures, errors)

    return errors, measures, building

  end
      
  def self.element_exists(element)
    if element.nil?
      return false
    else
      if element.text
        return true
      end
    end
    return false
  end
      
  def self.get_facility_type(building, errors)

    facility_types_handled = ["single-family detached"]
    if building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].nil?
      errors << "Residential facility type not specified."
    elsif not facility_types_handled.include? building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].text
      errors << "Residential facility type not #{facility_types_handled.join(", ")}."
    end

  end
      
  def self.get_location(building, measures, weather_file_path)

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
      
  def self.get_beds_and_baths(building, measures, errors)

    measure_subdir = "ResidentialGeometryNumBedsAndBaths"  
    num_bedrooms = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"]
    if num_bedrooms.nil?
      errors << "Number of bedrooms not found."
    end
    num_bathrooms = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms"]
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
      
  def self.get_num_occupants(building, measures, errors)

    measure_subdir = "ResidentialGeometryNumOccupants"  
    num_occupants = building.elements["BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents"]
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
      
  def self.get_door_area(building, measures, errors)

    measure_subdir = "ResidentialGeometryDoorArea"  
    door_area = building.elements["BuildingDetails/Enclosure/Doors/Door/Area"]
    if not door_area.nil?
      args = {
              "door_area"=>door_area.text
             }  
      measures[measure_subdir] = args
    else
      errors << "Door area not found."
    end
    
  end

  def self.get_ceiling_constructions(building, measures, errors)

    measure_subdir = "ResidentialConstructionsCeilingsRoofsUnfinishedAttic"
    args = {
            "ceil_r"=>"30",
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

  def self.get_floor_constructions(building, measures, errors)

    exposed_perim = 0
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
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

  def self.get_wall_constructions(building, measures, errors)

    measure_subdir = "ResidentialConstructionsWallsExteriorWoodStud"
    args = {
            "cavity_r"=>"13",
            "install_grade"=>"I",
            "cavity_depth"=>"3.5",
            "ins_fills_cavity"=>"true",
            "framing_factor"=>"0.13"
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

  def self.get_other_constructions(building, measures, errors)

    measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
    args = {}
    measures[measure_subdir] = args

  end

  def self.get_window_constructions(building, measures, errors)

    measure_subdir = "ResidentialConstructionsWindows"
    args = {
            "ufactor"=>"0.37",
            "shgc"=>"0.3",
            "heating_shade_mult"=>"0.7",
            "cooling_shade_mult"=>"0.7"
           }  
    measures[measure_subdir] = args

  end

  def self.get_door_constructions(building, measures, errors)

    measure_subdir = "ResidentialConstructionsDoors"
    args = {
            "door_uvalue"=>"0.2"
           }  
    measures[measure_subdir] = args

  end

  def self.get_water_heating(building, measures, errors)

    measure_subdir = nil
    args = {}

    building.elements.each("BuildingDetails/Systems/WaterHeating/WaterHeatingSystem") do |dhw|
    
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

  def self.get_heating_system(building, measures, errors)

    measure_subdir = nil
    args = {}

    building.elements.each("BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem") do |htgsys|
    
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

  def self.get_cooling_system(building, measures, errors)

    measure_subdir = nil
    args = {}

    building.elements.each("BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem") do |clgsys|
    
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

  def self.get_heat_pump(building, measures, errors)

    measure_subdir = nil
    args = {}

    building.elements.each("BuildingDetails/Systems/HVAC/HVACPlant/HeatPump") do |hp|
    
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

  def self.get_heating_setpoint(building, measures, errors) 

    building.elements.each("BuildingDetails/Systems/HVAC/HVACControl") do |cont|
      measure_subdir = "ResidentialHVACHeatingSetpoints"
      htg_wkdy = cont.elements["SetpointTempHeatingSeason"]
      htg_wked = cont.elements["SetpointTempHeatingSeason"]
      if not htg_wkdy.nil? and not htg_wked.nil?
        args = {
                "htg_wkdy"=>htg_wkdy.text,
                "htg_wked"=>htg_wked.text
               }  
        measures[measure_subdir] = args
      end
      break
    end
    
  end

  def self.get_cooling_setpoint(building, measures, errors)

    building.elements.each("BuildingDetails/Systems/HVAC/HVACControl") do |cont|
      measure_subdir = "ResidentialHVACCoolingSetpoints"
      clg_wkdy = cont.elements["SetupTempCoolingSeason"]
      clg_wked = cont.elements["SetupTempCoolingSeason"]
      if not clg_wkdy.nil? and not clg_wked.nil?
        args = {
                "clg_wkdy"=>clg_wkdy.text,
                "clg_wked"=>clg_wked.text
               }  
        measures[measure_subdir] = args
      end
      break
    end

  end

  def self.get_ceiling_fan(building, measures, errors)

    building.elements.each("BuildingDetails/Lighting/CeilingFan") do |cf|
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

  def self.get_refrigerator(building, measures, errors)

    building.elements.each("BuildingDetails/Appliances/Refrigerator") do |ref|
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

  def self.get_clothes_washer(building, measures, errors)

    building.elements.each("BuildingDetails/Appliances/ClothesWasher") do |cw|
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

  def self.get_clothes_dryer(building, measures, errors)
    
    measure_subdir = nil
    args = {}
    
    building.elements.each("BuildingDetails/Appliances/ClothesDryer") do |cd|
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

  def self.get_dishwasher(building, measures, errors)

    building.elements.each("BuildingDetails/Appliances/Dishwasher") do |dw|  
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

  def self.get_cooking_range(building, measures, errors)
    
    measure_subdir = nil
    args = {}  
    
    building.elements.each("BuildingDetails/Appliances/Oven") do |ov|
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

  def self.get_lighting(building, measures, errors)

    measure_subdir = "ResidentialLighting"
    cfl = building.elements["BuildingDetails/Lighting/LightingFractions/FractionCFL"]
    led = building.elements["BuildingDetails/Lighting/LightingFractions/FractionLED"]
    lfl = building.elements["BuildingDetails/Lighting/LightingFractions/FractionLFL"]
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

  def self.get_airflow(building, measures, errors)

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

  def self.get_hvac_sizing(building, measures, errors)
    
    measure_subdir = "ResidentialHVACSizing"
    args = {
            "show_debug_info"=>"false"
           }  
    measures[measure_subdir] = args

  end

  def self.get_photovoltaics(building, measures, errors)

    building.elements.each("BuildingDetails/Systems/Photovoltaics") do |pv|
      measure_subdir = "ResidentialPhotovoltaics"
      args = {
              "size"=>"2.5",
              "module_type"=>"standard",
              "system_losses"=>"0.14",
              "inverter_efficiency"=>"0.96",
              "azimuth_type"=>"relative",
              "azimuth"=>"180",
              "tile_type"=>"pitch",
              "tilt"=>"0"
             }  
      measures[measure_subdir] = args
      break
    end  

  end
  
end

class OSModel

  def self.create_geometry(building, runner, model)

    geometry_errors = []
  
    # Geometry
    avg_ceil_hgt = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/AverageCeilingHeight"]
    if avg_ceil_hgt.nil?
      avg_ceil_hgt = 8.0
    else
      avg_ceil_hgt = avg_ceil_hgt.text.to_f
    end

    foundation_space, foundation_zone = build_foundation_space(model, building)
    living_space = build_living_space(model, building)
    attic_space, attic_zone = build_attic_space(model, building)
    foundation_finished_floor_area = add_foundation_floors(model, building, living_space, foundation_space)
    add_foundation_walls(model, building, living_space, foundation_space)
    foundation_finished_floor_area = add_foundation_ceilings(model, building, foundation_space, living_space, foundation_finished_floor_area)
    add_living_floors(model, building, geometry_errors, foundation_space, living_space, foundation_finished_floor_area) # TODO: need these assumptions for airflow measure
    wall_fractions, window_areas = get_wall_orientation_fractions(building)
    surface_window_area = add_living_walls(model, building, geometry_errors, avg_ceil_hgt, living_space, attic_space, wall_fractions, window_areas)
    add_attic_floors(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    add_attic_walls(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    add_attic_ceilings(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    add_windows(model, building, runner, surface_window_area)
    
    geometry_errors.each do |error|
      runner.registerError(error)
    end

    unless geometry_errors.empty?
      return false
    end    
    
    # Set the zone volumes based on the sum of space volumes
    model.getThermalZones.each do |thermal_zone|
      zone_volume = 0
      if not Geometry.get_volume_from_spaces(thermal_zone.spaces) > 0 # space doesn't have a floor
        if thermal_zone.name.to_s == Constants.CrawlZone
          floor_area = nil
          thermal_zone.spaces.each do |space|
            space.surfaces.each do |surface|
              next unless surface.surfaceType.downcase == "roofceiling"
              floor_area = surface.grossArea
            end
          end
          zone_volume = OpenStudio.convert(floor_area,"m^2","ft^2").get * Geometry.get_height_of_spaces(thermal_zone.spaces)
        end
      else # space has a floor
        zone_volume = Geometry.get_volume_from_spaces(thermal_zone.spaces)
      end
      thermal_zone.setVolume(OpenStudio.convert(zone_volume,"ft^3","m^3").get)
    end
   
    # Explode wall surfaces out from origin, from top down
    [Constants.FacadeFront, Constants.FacadeBack, Constants.FacadeLeft, Constants.FacadeRight].each do |facade|
    
      wall_surfaces = {}
      model.getSurfaces.each do |surface|
        next unless Geometry.get_facade_for_surface(surface) == facade
        next unless surface.surfaceType.downcase == "wall"
        if surface.adjacentSurface.is_initialized
          next if wall_surfaces.keys.include? surface or wall_surfaces.keys.include? surface.adjacentSurface.get
        end
        z_val = -10000
        surface.vertices.each do |vertex|
          if vertex.z > z_val
            wall_surfaces[surface] = vertex.z.to_f
            z_val = vertex.z
          end
        end
      end
          
      offset = 30.0 # m
      wall_surfaces.sort_by{|k, v| v}.reverse.to_h.keys.each do |surface|

        m = OpenStudio::Matrix.new(4, 4, 0)
        m[0,0] = 1
        m[1,1] = 1
        m[2,2] = 1
        m[3,3] = 1
        if Geometry.get_facade_for_surface(surface) == Constants.FacadeFront
          m[1,3] = -offset
        elsif Geometry.get_facade_for_surface(surface) == Constants.FacadeBack
          m[1,3] = offset
        elsif Geometry.get_facade_for_surface(surface) == Constants.FacadeLeft
          m[0,3] = -offset
        elsif Geometry.get_facade_for_surface(surface) == Constants.FacadeRight
          m[0,3] = offset
        end
     
        transformation = OpenStudio::Transformation.new(m)      
        
        surface.subSurfaces.each do |subsurface|
          next unless subsurface.subSurfaceType.downcase == "fixedwindow"
          subsurface.setVertices(transformation * subsurface.vertices)
        end
        if surface.adjacentSurface.is_initialized
          surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
        end
        surface.setVertices(transformation * surface.vertices)
        
        offset += 5.0 # m
          
      end
    
    end
    
    # Store building name
    model.getBuilding.setName(File.basename(hpxml_file_path))
        
    # Store building unit information
    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
    unit.setName(Constants.ObjectNameBuildingUnit)
    model.getSpaces.each do |space|
      space.setBuildingUnit(unit)
    end
    
    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(1)    
    
    # Store number of stories
    num_floors = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/NumberofStoriesAboveGrade"]
    if num_floors.nil?
      num_floors = 1
    else
      num_floors = num_floors.text.to_i
    end    
    
    if (REXML::XPath.first(building, "count(BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(building, "count(BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cape cod'])")) > 0
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(num_floors)
    model.getSpaces.each do |space|
      if space.name.to_s == Constants.FinishedBasementSpace
        num_floors += 1  
        break
      end
    end
    model.getBuilding.setStandardsNumberOfStories(num_floors)
    
    # Store the building type
    facility_types_map = {"single-family detached"=>Constants.BuildingTypeSingleFamilyDetached}
    model.getBuilding.setStandardsBuildingType(facility_types_map[building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].text])

    return true
    
  end

  def self.add_floor_polygon(x, y, z)
      
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0, 0, z)
    vertices << OpenStudio::Point3d.new(0, y, z)
    vertices << OpenStudio::Point3d.new(x, y, z)
    vertices << OpenStudio::Point3d.new(x, 0, z)
      
    return vertices
      
  end

  def self.add_wall_polygon(x, y, z, orientation="south")

    vertices = OpenStudio::Point3dVector.new
    if orientation == "north"      
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z)
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z)
    elsif orientation == "south"
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z)
      vertices << OpenStudio::Point3d.new(x-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z + y)
      vertices << OpenStudio::Point3d.new(0-(x/2), 0, z)
    elsif orientation == "east"
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z)
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z)
    elsif orientation == "west"
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z)
      vertices << OpenStudio::Point3d.new(0, 0-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z + y)
      vertices << OpenStudio::Point3d.new(0, x-(x/2), z)
    end
    return vertices
      
  end

  def self.add_ceiling_polygon(x, y, z)
      
    return OpenStudio::reverse(add_floor_polygon(x, y, z))
      
  end

  def self.build_living_space(model, building)
      
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)
    living_space = OpenStudio::Model::Space.new(model)
    living_space.setName(Constants.LivingSpace)
    living_space.setThermalZone(living_zone)   
    
    return living_space
      
  end

  def self.get_wall_orientation_fractions(building)

    wall_fractions = {}
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
      orientation = window.elements["Orientation"].text
      if orientation == "southwest"
        orientation = "south"
      elsif orientation == "northwest"
        orientation = "west"
      elsif orientation == "southeast"
        orientation = "east"
      elsif orientation == "northeast"
        orientation = "north"
      end
      if wall_fractions.keys.include? window.elements["AttachedToWall"].attributes["idref"]      
        if wall_fractions[window.elements["AttachedToWall"].attributes["idref"]].keys.include? orientation
          wall_fractions[window.elements["AttachedToWall"].attributes["idref"]][orientation] += window.elements["Area"].text.to_f
        else
          wall_fractions[window.elements["AttachedToWall"].attributes["idref"]][orientation] = window.elements["Area"].text.to_f
        end
      else      
        wall_fractions[window.elements["AttachedToWall"].attributes["idref"]] = {}
        wall_fractions[window.elements["AttachedToWall"].attributes["idref"]][orientation] = window.elements["Area"].text.to_f        
      end
    end

    window_areas = {}
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
      if window_areas.keys.include? window.elements["AttachedToWall"].attributes["idref"]
        window_areas[window.elements["AttachedToWall"].attributes["idref"]] += window.elements["Area"].text.to_f        
      else
        window_areas[window.elements["AttachedToWall"].attributes["idref"]] = {}
        window_areas[window.elements["AttachedToWall"].attributes["idref"]] = window.elements["Area"].text.to_f        
      end
    end

    wall_fractions.each do |wall_id, orientations|    
      orientations.each do |orientation, area|
        wall_fractions[wall_id][orientation] /= window_areas[wall_id]
      end    
    end
    
    return wall_fractions, window_areas

  end  

  def self.add_living_walls(model, building, errors, avg_ceil_hgt, living_space, attic_space, wall_fractions, window_areas)

    rotate = {"north"=>0, "south"=>180, "west"=>90, "east"=>270}

    surface_window_area = {}
    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "living space"
      next if wall.elements["Area"].nil?
      
      z_origin = 0
      unless wall.elements["ExteriorAdjacentTo"].nil?
        if wall.elements["ExteriorAdjacentTo"].text == "attic"
          z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
        end
      end
    
      if not wall_fractions.keys.include? wall.elements["SystemIdentifier"].attributes["id"]
      
        wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
        wall_length = OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_height

        surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin), model)
        surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Wall") 
        surface.setSpace(living_space)
        if wall.elements["ExteriorAdjacentTo"].text == "attic"
          surface.createAdjacentSurface(attic_space)
        elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
          surface.setOutsideBoundaryCondition("Outdoors")
        else
          errors << "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
        end      
      
      else
      
        wall_fractions[wall.elements["SystemIdentifier"].attributes["id"]].each do |orientation, frac|
        
          wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
          wall_length = frac * OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_height

          surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin, orientation), model)
          surface.setName("#{wall.elements["SystemIdentifier"].attributes["id"]} #{orientation}")
          surface.setSurfaceType("Wall") 
          surface.setSpace(living_space)
          if wall.elements["ExteriorAdjacentTo"].text == "attic"
            surface.createAdjacentSurface(attic_space)
          elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
            surface.setOutsideBoundaryCondition("Outdoors")
          else
            errors << "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
          end
          
          surface_window_area["#{wall.elements["SystemIdentifier"].attributes["id"]} #{orientation}"] = frac * window_areas[wall.elements["SystemIdentifier"].attributes["id"]]      
        
        end
        
      end
      
    end
    
    return surface_window_area

  end

  def self.build_foundation_space(model, building)

    foundation_type = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/FoundationType"]
    unless foundation_type.nil?
      foundation_space_name = nil
      foundation_zone_name = nil
      if foundation_type.elements["Basement/Conditioned/text()='true'"] or foundation_type.elements["Basement/Finished/text()='true'"]
        foundation_zone_name = Constants.FinishedBasementZone
        foundation_space_name = Constants.FinishedBasementSpace
      elsif foundation_type.elements["Basement/Conditioned/text()='false'"] or foundation_type.elements["Basement/Finished/text()='false'"]
        foundation_zone_name = Constants.UnfinishedBasementZone
        foundation_space_name = Constants.UnfinishedBasementSpace
      elsif foundation_type.elements["Crawlspace/Vented/text()='true'"] or foundation_type.elements["Crawlspace/Vented/text()='false'"] or foundation_type.elements["Crawlspace/Conditioned/text()='true'"] or foundation_type.elements["Crawlspace/Conditioned/text()='false'"]
        foundation_zone_name = Constants.CrawlZone
        foundation_space_name = Constants.CrawlSpace
      elsif foundation_type.elements["Garage/Conditioned/text()='true'"] or foundation_type.elements["Garage/Conditioned/text()='false'"]
        foundation_zone_name = Constants.GarageZone
        foundation_space_name = Constants.GarageSpace
      elsif foundation_type.elements["SlabOnGrade"]     
      end
      if not foundation_space_name.nil? and not foundation_zone_name.nil?
        foundation_zone = OpenStudio::Model::ThermalZone.new(model)
        foundation_zone.setName(foundation_zone_name)
        foundation_space = OpenStudio::Model::Space.new(model)
        foundation_space.setName(foundation_space_name)
        foundation_space.setThermalZone(foundation_zone)
      end
    end
    
    return foundation_space, foundation_zone
      
  end

  def self.add_foundation_floors(model, building, living_space, foundation_space)
      
    foundation_finished_floor_area = 0
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      foundation.elements.each("Slab") do |slab|
      
        next if slab.elements["Area"].nil?
        
        slab_width = OpenStudio.convert(Math::sqrt(slab.elements["Area"].text.to_f),"ft","m").get
        slab_length = OpenStudio.convert(slab.elements["Area"].text.to_f,"ft^2","m^2").get / slab_width
        
        z_origin = 0
        unless slab.elements["DepthBelowGrade"].nil?
          z_origin = -OpenStudio.convert(slab.elements["DepthBelowGrade"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(slab_length, slab_width, z_origin), model)
        surface.setName(slab.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Floor") 
        surface.setOutsideBoundaryCondition("Ground")
        if z_origin < 0
          surface.setSpace(foundation_space)
        else
          surface.setSpace(living_space)
        end
        if foundation_space.nil?
          foundation_finished_floor_area += slab.elements["Area"].text.to_f # is a slab foundation
        elsif foundation_space.name.to_s == Constants.FinishedBasementSpace
          foundation_finished_floor_area += slab.elements["Area"].text.to_f # is a finished basement foundation
        end
        
      end
      
    end
    
    return foundation_finished_floor_area
        
  end

  def self.add_foundation_walls(model, building, living_space, foundation_space)

    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation.elements.each("FoundationWall") do |wall|
        
        if not wall.elements["Length"].nil? and not wall.elements["Height"].nil?
        
          wall_length = OpenStudio.convert(wall.elements["Length"].text.to_f,"ft","m").get
          wall_height = OpenStudio.convert(wall.elements["Height"].text.to_f,"ft","m").get
        
        elsif not wall.elements["Area"].nil?
        
          wall_length = OpenStudio.convert(Math::sqrt(wall.elements["Area"].text.to_f),"ft","m").get
          wall_height = OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_length
        
        else
        
          next
        
        end
        
        z_origin = 0
        unless wall.elements["BelowGradeDepth"].nil?
          z_origin = -OpenStudio.convert(wall.elements["BelowGradeDepth"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin), model)
        surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Wall") 
        surface.setOutsideBoundaryCondition("Ground")
        surface.setSpace(foundation_space)
        
      end
    
    end

  end

  def self.add_foundation_ceilings(model, building, foundation_space, living_space, foundation_finished_floor_area)
       
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
     
      foundation.elements.each("FrameFloor") do |framefloor|
      
        next if framefloor.elements["Area"].nil?

        framefloor_width = OpenStudio.convert(Math::sqrt(framefloor.elements["Area"].text.to_f),"ft","m").get
        framefloor_length = OpenStudio.convert(framefloor.elements["Area"].text.to_f,"ft^2","m^2").get / framefloor_width
        
        z_origin = 0
        
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(framefloor_length, framefloor_width, z_origin), model)
        surface.setName(framefloor.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("RoofCeiling")
        surface.setSpace(foundation_space)
        surface.createAdjacentSurface(living_space)
        
        foundation_finished_floor_area += framefloor.elements["Area"].text.to_f
      
      end
    
    end
    
    return foundation_finished_floor_area
      
  end

  def self.add_living_floors(model, building, errors, foundation_space, living_space, foundation_finished_floor_area)

    finished_floor_area = nil
    if not building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/FinishedFloorArea"].nil?
      finished_floor_area = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/FinishedFloorArea"].text.to_f
      if finished_floor_area == 0 and not building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].nil?
        finished_floor_area = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].text.to_f
      end
    elsif not building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].nil?
      finished_floor_area = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].text.to_f
    end
    if finished_floor_area.nil?
      errors << "Could not find finished floor area."
    end
    above_grade_finished_floor_area = finished_floor_area - foundation_finished_floor_area
    return unless above_grade_finished_floor_area > 0
    
    finishedfloor_width = OpenStudio.convert(Math::sqrt(above_grade_finished_floor_area),"ft","m").get
    finishedfloor_length = OpenStudio.convert(above_grade_finished_floor_area,"ft^2","m^2").get / finishedfloor_width
    
    surface = OpenStudio::Model::Surface.new(add_floor_polygon(-finishedfloor_width, -finishedfloor_length, 0), model) # don't put it right on top of existing finished floor
    surface.setName("inferred above grade finished floor")
    surface.setSurfaceType("Floor")
    surface.setSpace(living_space)
    if foundation_space.nil?
      surface.createAdjacentSurface(living_space)
    else
      surface.createAdjacentSurface(foundation_space)
    end

  end

  def self.build_attic_space(model, building)

    attic_space = nil
    attic_zone = nil
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if attic.elements["Area"].nil?
    
      if ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
        if attic_space.nil?
          attic_zone = OpenStudio::Model::ThermalZone.new(model)
          attic_zone.setName(Constants.UnfinishedAtticZone)
          attic_space = OpenStudio::Model::Space.new(model)
          attic_space.setName(Constants.UnfinishedAtticSpace)
          attic_space.setThermalZone(attic_zone)
        end
      end
      
    end
    
    return attic_space, attic_zone
      
  end

  def self.add_attic_floors(model, building, errors, avg_ceil_hgt, attic_space, living_space)

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
      next if attic.elements["Area"].nil?
    
      attic_width = OpenStudio.convert(Math::sqrt(attic.elements["Area"].text.to_f),"ft","m").get
      attic_length = OpenStudio.convert(attic.elements["Area"].text.to_f,"ft^2","m^2").get / attic_width
    
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
     
      if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
      elsif ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(attic_length, attic_width, z_origin), model)
        surface.setName(attic.elements["SystemIdentifier"].attributes["id"])        
        surface.setSpace(attic_space)
        surface.setSurfaceType("Floor")
        surface.createAdjacentSurface(living_space)
      else
        errors << "#{attic.elements["AtticType"].text} not handled yet."
      end
      
    end
      
  end

  def self.add_attic_walls(model, building, errors, avg_ceil_hgt, attic_space, living_space)

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "attic"
      next if wall.elements["Area"].nil?
      
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
      
      wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
      wall_length = OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get / wall_height

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_height, wall_length, z_origin), model)
      surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
      surface.setSurfaceType("Wall")
      surface.setSpace(living_space)
      if wall.elements["ExteriorAdjacentTo"].text == "living space"
        surface.createAdjacentSurface(living_space)
      elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
        surface.setOutsideBoundaryCondition("Outdoors")
      else
        errors << "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
      end
      
    end
      
  end

  def self.add_attic_ceilings(model, building, errors, avg_ceil_hgt, attic_space, living_space)

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
      next if attic.elements["Area"].nil?
    
      attic_width = OpenStudio.convert(Math::sqrt(attic.elements["Area"].text.to_f),"ft","m").get
      attic_length = OpenStudio.convert(attic.elements["Area"].text.to_f,"ft^2","m^2").get / attic_width
    
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
     
      if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(attic_length, attic_width, z_origin), model)
        surface.setName(attic.elements["SystemIdentifier"].attributes["id"])
        surface.setSpace(living_space)
        surface.setSurfaceType("RoofCeiling")
        surface.setOutsideBoundaryCondition("Outdoors")
      elsif ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text     
      else
        errors << "#{attic.elements["AtticType"].text} not handled yet."
      end
      
    end  

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Roofs/Roof") do |roof|
    
      next if roof.elements["RoofArea"].nil?
    
      roof_width = OpenStudio.convert(Math::sqrt(roof.elements["RoofArea"].text.to_f),"ft","m").get
      roof_length = OpenStudio.convert(roof.elements["RoofArea"].text.to_f,"ft^2","m^2").get / roof_width
    
      z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 2 # TODO: is this a bad assumption?

      surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(roof_length, roof_width, z_origin), model)
      surface.setName("#{roof.elements["SystemIdentifier"].attributes["id"]}")
      surface.setSurfaceType("RoofCeiling")
      surface.setOutsideBoundaryCondition("Outdoors")
      surface.setSpace(attic_space)

    end
        
  end

  def self.add_windows(model, building, runner, surface_window_area)
      
    max_single_window_area = 12.0 # sqft
    window_gap_y = 1.0 # ft; distance from top of wall
    window_gap_x = 0.2 # ft; distance between windows in a two-window group
    aspect_ratio = 1.333
    facades = {"south"=>Constants.FacadeFront, "north"=>Constants.FacadeBack, "west"=>Constants.FacadeLeft, "east"=>Constants.FacadeRight}
    model.getSurfaces.each do |surface|
      next unless surface_window_area.keys.include? surface.name.to_s
      next if surface.outsideBoundaryCondition.downcase == "ground" # TODO: can't have windows on surfaces adjacent to ground in energyplus
      add_windows_to_wall(surface, surface_window_area[surface.name.to_s], window_gap_y, window_gap_x, aspect_ratio, max_single_window_area, facades[surface.name.to_s.split(' ')[1]], model, runner)      
    end
      
  end

  def self.add_windows_to_wall(surface, window_area, window_gap_y, window_gap_x, aspect_ratio, max_single_window_area, facade, model, runner)

    wall_width = Geometry.get_surface_length(surface)
    wall_height = Geometry.get_surface_height(surface)
    
    # Calculate number of windows needed
    num_windows = (window_area / max_single_window_area).ceil
    num_window_groups = (num_windows / 2.0).ceil
    num_window_gaps = num_window_groups
    if num_windows % 2 == 1
        num_window_gaps -= 1
    end
    window_width = Math.sqrt((window_area / num_windows.to_f) / aspect_ratio)
    window_height = (window_area / num_windows.to_f) / window_width
    width_for_windows = window_width * num_windows.to_f + window_gap_x * num_window_gaps.to_f
    if width_for_windows > wall_width
        runner.registerError("Could not fit windows on #{surface.name.to_s}.")
        return false
    end
    
    # Position window from top of surface
    win_top = wall_height - window_gap_y
    if Geometry.is_gable_wall(surface)
        # For gable surfaces, position windows from bottom of surface so they fit
        win_top = window_height + window_gap_y
    end
    
    # Groups of two windows
    win_num = 0
    for i in (1..num_window_groups)
        
        # Center vertex for group
        group_cx = wall_width * i / (num_window_groups+1).to_f
        group_cy = win_top - window_height / 2.0
        
        if not (i == num_window_groups and num_windows % 2 == 1)
            # Two windows in group
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx - window_width/2.0 - window_gap_x/2.0, group_cy, win_num, facade, model, runner)
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx + window_width/2.0 + window_gap_x/2.0, group_cy, win_num, facade, model, runner)
        else
            # One window in group
            win_num += 1
            add_window_to_wall(surface, window_width, window_height, group_cx, group_cy, win_num, facade, model, runner)
        end
    end
    runner.registerInfo("Added #{num_windows.to_s} window(s), totaling #{window_area.round(1).to_s} ft^2, to #{surface.name}.")
    return true
    
  end

  def self.add_window_to_wall(surface, win_width, win_height, win_center_x, win_center_y, win_num, facade, model, runner)
      
    # Create window vertices in relative coordinates, ft
    upperleft = [win_center_x - win_width/2.0, win_center_y + win_height/2.0]
    upperright = [win_center_x + win_width/2.0, win_center_y + win_height/2.0]
    lowerright = [win_center_x + win_width/2.0, win_center_y - win_height/2.0]
    lowerleft = [win_center_x - win_width/2.0, win_center_y - win_height/2.0]
    
    # Convert to 3D geometry; assign to surface
    window_polygon = OpenStudio::Point3dVector.new
    if facade == Constants.FacadeFront
        multx = 1
        multy = 0
    elsif facade == Constants.FacadeBack
        multx = -1
        multy = 0
    elsif facade == Constants.FacadeLeft
        multx = 0
        multy = -1
    elsif facade == Constants.FacadeRight
        multx = 0
        multy = 1
    end
    if facade == Constants.FacadeBack or facade == Constants.FacadeLeft
        leftx = Geometry.getSurfaceXValues([surface]).max
        lefty = Geometry.getSurfaceYValues([surface]).max
    else
        leftx = Geometry.getSurfaceXValues([surface]).min
        lefty = Geometry.getSurfaceYValues([surface]).min
    end
    bottomz = Geometry.getSurfaceZValues([surface]).min
    [upperleft, lowerleft, lowerright, upperright ].each do |coord|
        newx = OpenStudio.convert(leftx + multx * coord[0], "ft", "m").get
        newy = OpenStudio.convert(lefty + multy * coord[0], "ft", "m").get
        newz = OpenStudio.convert(bottomz + coord[1], "ft", "m").get
        window_vertex = OpenStudio::Point3d.new(newx, newy, newz)
        window_polygon << window_vertex
    end
    sub_surface = OpenStudio::Model::SubSurface.new(window_polygon, model)
    sub_surface.setName("#{surface.name} - Window #{win_num.to_s}")
    sub_surface.setSurface(surface)
    sub_surface.setSubSurfaceType("FixedWindow")
      
  end
  
  def self.apply_measures(measure_subdir, measures, runner, model)
  
    # Get workflow order of measures
    workflow_order = []
    workflow_json = JSON.parse(File.read(File.join(File.dirname(__FILE__), "resources", "measure-info.json")), :symbolize_names=>true)
    
    workflow_json.each do |group|
      group[:group_steps].each do |step|
        step[:measures].each do |measure|
          workflow_order << measure
        end
      end
    end
    
    # Call each measure for sample to build up model
    workflow_order.each do |measure_subdir|
      next unless measures.keys.include? measure_subdir

      # Gather measure arguments and call measure
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
      measure_instance = get_measure_instance(full_measure_path)
      argument_map = get_argument_map(model, measure_instance, measures[measure_subdir], measure_subdir, runner)
      print_measure_call(measures[measure_subdir], measure_subdir, runner)

      if not run_measure(model, measure_instance, argument_map, runner)
        return false
      end

    end
    
    return true

  end
  
end