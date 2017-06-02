require 'rexml/document'
require 'rexml/xpath'
require "#{File.dirname(__FILE__)}/geometry"
require "#{File.dirname(__FILE__)}/util"
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/xmlhelper"

class OSMeasures    

  def self.build_measures_from_hpxml(building, weather_file_path)

    measures = {}
    
    # TODO
    # ResidentialGeometryOrientation
    # ResidentialGeometryEaves
    # ResidentialGeometryOverhangs
    # ResidentialGeometryNeighbors
    # ResidentialHVACDehumidifier
    
    get_location(building, measures, weather_file_path)
    get_beds_and_baths(building, measures)
    get_num_occupants(building, measures)
    get_window_area(building, measures)
    get_door_area(building, measures)
    get_ceiling_roof_constructions(building, measures)
    get_floor_constructions(building, measures)
    get_wall_constructions(building, measures)
    get_other_constructions(building, measures)
    get_window_constructions(building, measures)
    get_door_constructions(building, measures)
    get_water_heating(building, measures)
    get_heating_system(building, measures)
    get_cooling_system(building, measures)
    get_heat_pump(building, measures)
    get_heating_setpoint(building, measures)
    get_cooling_setpoint(building, measures)
    get_ceiling_fan(building, measures)
    get_refrigerator(building, measures)
    get_clothes_washer(building, measures)
    get_clothes_dryer(building, measures)
    get_dishwasher(building, measures)
    get_cooking_range(building, measures)
    get_lighting(building, measures)
    get_mels(building, measures)
    get_airflow(building, measures)
    get_hvac_sizing(building, measures)
    get_photovoltaics(building, measures)

    return measures

  end
  
  def self.to_beopt_fuel(fuel)
    conv = {"natural gas"=>Constants.FuelTypeGas, 
            "fuel oil"=>Constants.FuelTypeOil, 
            "propane"=>Constants.FuelTypePropane, 
            "electricity"=>Constants.FuelTypeElectric}
    return conv[fuel]
  end
      
  def self.get_location(building, measures, weather_file_path)

    measure_subdir = "ResidentialLocation"
    args = {
            "weather_directory"=>File.dirname(weather_file_path),
            "weather_file_name"=>File.basename(weather_file_path),
            "dst_start_date"=>"NA",
            "dst_end_date"=>"NA"
           }
    measures[measure_subdir] = args

  end
      
  def self.get_beds_and_baths(building, measures)

    measure_subdir = "ResidentialGeometryNumBedsAndBaths"  
    num_bedrooms = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms")
    num_bathrooms = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms")
    args = {
            "num_bedrooms"=>num_bedrooms,
            "num_bathrooms"=>num_bathrooms
           }  
    measures[measure_subdir] = args
    
  end
      
  def self.get_num_occupants(building, measures)

    num_occ = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents")
    occ_gain = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/HeatGainPerPerson")
    sens_frac = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/FracSensible")
    lat_frac = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/FracLatent")
    
    measure_subdir = "ResidentialGeometryNumOccupants"  
    args = {
            "num_occ"=>num_occ,
            "occ_gain"=>occ_gain,
            "sens_frac"=>sens_frac,
            "lat_frac"=>lat_frac,
            "weekday_sch"=>"1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000",
            "weekend_sch"=>"1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000",
            "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
           }
    measures[measure_subdir] = args
    
  end
      
  def self.get_window_area(building, measures)
  
    facades = [Constants.FacadeFront, Constants.FacadeBack, Constants.FacadeLeft, Constants.FacadeRight]
    
    azimuths = {}
    azimuths[Constants.FacadeFront] = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/Site/AzimuthOfFrontOfHome").to_f
    azimuths[Constants.FacadeBack] = normalize_azimuth(azimuths[Constants.FacadeFront] + 180)
    azimuths[Constants.FacadeLeft] = normalize_azimuth(azimuths[Constants.FacadeFront] + 90)
    azimuths[Constants.FacadeRight] = normalize_azimuth(azimuths[Constants.FacadeFront] + 270)
    
    window_areas = {Constants.FacadeFront=>0.0,
                    Constants.FacadeBack=>0.0,
                    Constants.FacadeLeft=>0.0,
                    Constants.FacadeRight=>0.0
                   }
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
      window_az = XMLHelper.get_value(window, "Azimuth").to_f
      window_area = XMLHelper.get_value(window, "Area").to_f
      
      # Find closest facade
      best_min_delta = 99999
      best_facade = nil
      facades.each do |facade|
        min_delta = [(window_az - azimuths[facade]).abs, 
                     ((window_az+360) - azimuths[facade]).abs,
                     ((window_az-360) - azimuths[facade]).abs].min
        next if min_delta > best_min_delta
        best_min_delta = (window_az - azimuths[facade]).abs
        best_facade = facade
      end
      
      window_areas[best_facade] += window_area
      
    end
    
    measure_subdir = "ResidentialGeometryWindowArea"  
    args = {
            "front_wwr"=>"0",
            "back_wwr"=>"0",
            "left_wwr"=>"0",
            "right_wwr"=>"0",
            "front_area"=>window_areas[Constants.FacadeFront].to_s,
            "back_area"=>window_areas[Constants.FacadeBack].to_s,
            "left_area"=>window_areas[Constants.FacadeLeft].to_s,
            "right_area"=>window_areas[Constants.FacadeRight].to_s,
            "aspect_ratio"=>"1.333"
           }  
    measures[measure_subdir] = args
    
  end
  
  def self.normalize_azimuth(az)
    while az < 0.0
      az += 360.0
    end
    while az >= 360.0
      az -= 360.0
    end
    return az
  end
      
  def self.get_door_area(building, measures)

    measure_subdir = "ResidentialGeometryDoorArea"  
    door_area = 0.0
    building.elements.each("BuildingDetails/Enclosure/Doors/Door/Area") do |area|
      door_area += area.text.to_f
    end
    if door_area > 0
      args = {
              "door_area"=>door_area.to_s
             }  
      measures[measure_subdir] = args
    end
    
  end

  def self.get_ceiling_roof_constructions(building, measures)

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
            "material"=>Constants.RoofMaterialAsphaltShingles,
            "color"=>Constants.ColorMedium
           }  
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsCeilingsRoofsRadiantBarrier"
    args = {
            "has_rb"=>"false"
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsCeilingsRoofsSheathing"
    args = {
            "osb_thick_in"=>"0.75",
            "rigid_r"=>"0.0",
            "rigid_thick_in"=>"0.0",
           }
    measures[measure_subdir] = args
           
    measure_subdir = "ResidentialConstructionsCeilingsRoofsThermalMass"
    args = {
            "thick_in1"=>"0.5",
            "thick_in2"=>nil,
            "cond1"=>"1.1112",
            "cond2"=>nil,
            "dens1"=>"50.0",
            "dens2"=>nil,
            "specheat1"=>"0.2",
            "specheat2"=>nil
           }
    measures[measure_subdir] = args

  end

  def self.get_floor_constructions(building, measures)

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
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementUnfinished"
    args = {
            "wall_ins_height"=>"8",
            "wall_cavity_r"=>"0",
            "wall_cavity_grade"=>"I",
            "wall_cavity_depth"=>"0",
            "wall_cavity_insfills"=>"false",
            "wall_ff"=>"0",
            "wall_rigid_r"=>"10.0",
            "wall_rigid_thick_in"=>"2.0",
            "ceil_cavity_r"=>"0",
            "ceil_cavity_grade"=>"I",
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
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsPierBeam"
    args = {
            "cavity_r"=>"19",
            "install_grade"=>"I",
            "framing_factor"=>"0.13"
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsCovering"
    args = {
            "covering_frac"=>"0.8",
            "covering_r"=>"2.08"
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsInterzonalFloors"
    args = {
            "cavity_r"=>"19",
            "install_grade"=>"I",
            "framing_factor"=>"0.13"
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
    args = {
            "osb_thick_in"=>"0.75",
            "rigid_r"=>"0.0",
            "rigid_thick_in"=>"0.0"
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsThermalMass"
    args = {
            "thick_in"=>"0.625",
            "cond"=>"0.8004",
            "dens"=>"34.0",
            "specheat"=>"0.29"
           }
    measures[measure_subdir] = args
    
  end

  def self.get_wall_constructions(building, measures)

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
    
    measure_subdir = "ResidentialConstructionsWallsExteriorFinish"
    args = {
            "solar_abs"=>"0.3",
            "conductivity"=>"0.62",
            "density"=>"11.1",
            "specific_heat"=>"0.25",
            "thick_in"=>"0.375",
            "emissivity"=>"0.9"
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsWallsExteriorThermalMass"
    args = {
            "thick_in1"=>"0.5",
            "thick_in2"=>nil,
            "cond1"=>"1.1112",
            "cond2"=>nil,
            "dens1"=>"50.0",
            "dens2"=>nil,
            "specheat1"=>"0.2",
            "specheat2"=>nil
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsWallsPartitionThermalMass"
    args = {
            "frac"=>"1.0",
            "thick_in1"=>"0.5",
            "thick_in2"=>nil,
            "cond1"=>"1.1112",
            "cond2"=>nil,
            "dens1"=>"50.0",
            "dens2"=>nil,
            "specheat1"=>"0.2",
            "specheat2"=>nil
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsWallsSheathing"
    args = {
            "osb_thick_in"=>"0.5",
            "rigid_r"=>"0.0",
            "rigid_thick_in"=>"0.0"
           }
    measures[measure_subdir] = args

  end

  def self.get_other_constructions(building, measures)

    measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
    args = {}
    measures[measure_subdir] = args

    measure_subdir = "ResidentialConstructionsFurnitureThermalMass"
    args = {
            "area_fraction"=>"0.4",
            "mass"=>"8.0",
            "solar_abs"=>"0.6",
            "conductivity"=>BaseMaterial.Wood.k_in.to_s,
            "density"=>"40.0",
            "specific_heat"=>BaseMaterial.Wood.cp.to_s,
           }
    measures[measure_subdir] = args
    
  end

  def self.get_window_constructions(building, measures)

    measure_subdir = "ResidentialConstructionsWindows"
    args = {
            "ufactor"=>"0.37",
            "shgc"=>"0.3",
            "heating_shade_mult"=>"0.7",
            "cooling_shade_mult"=>"0.7"
           }  
    measures[measure_subdir] = args
    
  end

  def self.get_door_constructions(building, measures)

    measure_subdir = "ResidentialConstructionsDoors"
    args = {
            "door_uvalue"=>"0.2"
           }  
    measures[measure_subdir] = args

  end

  def self.get_water_heating(building, measures)

    dhw = building.elements["BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
    
    return if dhw.nil?
    
    setpoint_temp = XMLHelper.get_value(dhw, "HotWaterTemperature")
    tank_vol = XMLHelper.get_value(dhw, "TankVolume")
    wh_type = XMLHelper.get_value(dhw, "WaterHeaterType")
    fuel = XMLHelper.get_value(dhw, "FuelType")
    
    if wh_type == "storage water heater"
    
      ef = XMLHelper.get_value(dhw, "EnergyFactor")
      cap_btuh = XMLHelper.get_value(dhw, "HeatingCapacity")
      
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHotWaterHeaterTankElectric"
        args = {
                "tank_volume"=>tank_vol,
                "setpoint_temp"=>setpoint_temp,
                "location"=>Constants.Auto,
                "capacity"=>OpenStudio::convert(cap_btuh.to_f,"Btu/h","kW").get.to_s,
                "energy_factor"=>ef
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        re = XMLHelper.get_value(dhw, "RecoveryEfficiency")
        
        measure_subdir = "ResidentialHotWaterHeaterTankFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "tank_volume"=>tank_vol,
                "setpoint_temp"=>setpoint_temp,
                "location"=>Constants.Auto,
                "capacity"=>(cap_btuh.to_f/1000.0).to_s,
                "energy_factor"=>ef,
                "recovery_efficiency"=>re,
                "offcyc_power"=>"0",
                "oncyc_power"=>"0"
               }
        measures[measure_subdir] = args
        
      end      
      
    elsif wh_type == "instantaneous water heater"
    
      ef = XMLHelper.get_value(dhw, "EnergyFactor")
      ef_adj = XMLHelper.get_value(dhw, "extension/PerformanceAdjustmentEnergyFactor")
      
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHotWaterHeaterTanklessElectric"
        args = {
                "setpoint_temp"=>setpoint_temp,
                "location"=>Constants.Auto,
                "capacity"=>"100000000.0",
                "energy_factor"=>ef,
                "cycling_derate"=>ef_adj
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
        
        measure_subdir = "ResidentialHotWaterHeaterTanklessFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "location"=>Constants.Auto,
                "capacity"=>"100000000.0",
                "energy_factor"=>ef,
                "cycling_derate"=>ef_adj,
                "offcyc_power"=>"0",
                "oncyc_power"=>"0",
               }
        measures[measure_subdir] = args
        
      end
      
    elsif wh_type == "heat pump water heater"
    
      measure_subdir = "ResidentialHotWaterHeaterHeatPump"
      # FIXME
      args = {
              "storage_tank_volume"=>tank_vol,
              "dhw_setpoint_temperature"=>setpoint_temp,
              "space"=>Constants.Auto,
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
      measures[measure_subdir] = args
      
    end
    
    # TODO: ResidentialHotWaterDistribution
    # TODO: ResidentialHotWaterFixtures
    # TODO: ResidentialHotWaterSolar

  end

  def self.get_heating_system(building, measures)

    htgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
    
    return if htgsys.nil?
    
    fuel = XMLHelper.get_value(htgsys, "HeatingSystemFuel")
    
    if XMLHelper.has_element(htgsys, "HeatingSystemType/Furnace")
    
      afue = XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value")
    
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHVACFurnaceElectric"
        args = {
                "afue"=>afue,
                "fan_power_installed"=>"0.5", # FIXME
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        measure_subdir = "ResidentialHVACFurnaceFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "afue"=>afue,
                "fan_power_installed"=>"0.5", # FIXME
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      end
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/Boiler")
    
      afue = XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value")
    
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHVACBoilerElectric"
        args = {
                "system_type"=>Constants.BoilerTypeForcedDraft,
                "afue"=>afue,
                "oat_reset_enabled"=>"false",
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        measure_subdir = "ResidentialHVACBoilerFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "system_type"=>Constants.BoilerTypeForcedDraft,
                "afue"=>afue,
                "oat_reset_enabled"=>"false", # FIXME?
                "oat_high"=>nil,
                "oat_low"=>nil,
                "oat_hwst_high"=>nil,
                "oat_hwst_low"=>nil,
                "design_temp"=>nil,
                "modulation"=>"false",
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      end
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/ElectricResistance")
    
      percent = XMLHelper.get_value(htgsys, "AnnualHeatingEfficiency[Units='Percent']/Value")
    
      measure_subdir = "ResidentialHVACElectricBaseboard"
      args = {
              "efficiency"=>percent,
              "capacity"=>Constants.SizingAuto
             }
      measures[measure_subdir] = args
             
    end

  end

  def self.get_cooling_system(building, measures)

    clgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
    
    return if clgsys.nil?
    
    clg_type = XMLHelper.get_value(clgsys, "CoolingSystemType")
    
    if clg_type == "central air conditioning"
    
      seer_nom = XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='SEER']/Value").to_f
      seer_adj = XMLHelper.get_value(clgsys, "extension/PerformanceAdjustmentSEER").to_f
      seer = (seer_nom * seer_adj).to_s
    
      if seer_nom < 16
      
        measure_subdir = "ResidentialHVACCentralAirConditionerSingleSpeed"
        args = {
                "seer"=>seer,
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
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      elsif seer_nom <= 21
      
        measure_subdir = "ResidentialHVACCentralAirConditionerTwoSpeed"
        args = {
                "seer"=>seer,
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
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      else
      
        measure_subdir = "ResidentialHVACCentralAirConditionerVariableSpeed"
        args = {
                "seer"=>seer,
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
                "capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      end
      
    elsif clg_type == "room air conditioner"
    
      eer = XMLHelper.get_value(htgsys, "AnnualCoolingEfficiency[Units='EER']/Value")

      measure_subdir = "ResidentialHVACRoomAirConditioner"
      args = {
              "eer"=>eer,
              "shr"=>"0.65",
              "airflow_rate"=>"350",
              "capacity"=>Constants.SizingAuto
             }
      measures[measure_subdir] = args
      
    end  

  end

  def self.get_heat_pump(building, measures)

    hp = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
    
    return if hp.nil?
    
    hp_type = XMLHelper.get_value(hp, "HeatPumpType")
    
    if hp_type == "air-to-air"        
    
      seer_nom = XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value").to_f
      seer_adj = XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER").to_f
      seer = (seer_nom * seer_adj).to_s
      hspf_nom = XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='HSPF']/Value").to_f
      hspf_adj = XMLHelper.get_value(hp, "extension/PerformanceAdjustmentHSPF").to_f
      hspf = (hspf_nom * hspf_adj).to_s
      
      if seer_nom < 16
      
        measure_subdir = "ResidentialHVACAirSourceHeatPumpSingleSpeed"
        args = {
                "seer"=>seer,
                "hspf"=>hspf,
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
                "heat_pump_capacity"=>Constants.SizingAuto,
                "supplemental_capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      elsif seer_nom <= 21
      
        measure_subdir = "ResidentialHVACAirSourceHeatPumpTwoSpeed"
        args = {
                "seer"=>seer,
                "hspf"=>hspf,
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
                "heat_pump_capacity"=>Constants.SizingAuto,
                "supplemental_capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      else
      
        measure_subdir = "ResidentialHVACAirSourceHeatPumpVariableSpeed"
        args = {
                "seer"=>seer,
                "hspf"=>hspf,
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
                "heat_pump_capacity"=>Constants.SizingAuto,
                "supplemental_capacity"=>Constants.SizingAuto
               }
        measures[measure_subdir] = args
        
      end
      
    elsif hp_type == "mini-split"
      
      seer_nom = XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='SEER']/Value").to_f
      seer_adj = XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER").to_f
      seer = (seer_nom * seer_adj).to_s
      hspf_nom = XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='HSPF']/Value").to_f
      hspf_adj = XMLHelper.get_value(hp, "extension/PerformanceAdjustmentHSPF").to_f
      hspf = (hspf_nom * hspf_adj).to_s
      
      measure_subdir = "ResidentialHVACMiniSplitHeatPump"
      args = {
              "seer"=>seer,
              "min_cooling_capacity"=>"0.4",
              "max_cooling_capacity"=>"1.2",
              "shr"=>"0.73",
              "min_cooling_airflow_rate"=>"200",
              "max_cooling_airflow_rate"=>"425",
              "hspf"=>hpsf,
              "heating_capacity_offset"=>"2300",
              "min_heating_capacity"=>"0.3",
              "max_heating_capacity"=>"1.2",
              "min_heating_airflow_rate"=>"200",
              "max_heating_airflow_rate"=>"400",
              "cap_retention_frac"=>"0.25",
              "cap_retention_temp"=>"-5",
              "pan_heater_power"=>"0",
              "fan_power"=>"0.07",
              "heat_pump_capacity"=>Constants.SizingAuto,
              "supplemental_efficiency"=>"1",
              "supplemental_capacity"=>Constants.SizingAuto
             }
      measures[measure_subdir] = args
             
    elsif hp_type == "ground-to-air"
    
      eer = XMLHelper.get_value(hp, "AnnualCoolingEfficiency[Units='EER']/Value")
      cop = XMLHelper.get_value(hp, "AnnualHeatingEfficiency[Units='COP']/Value")
    
      measure_subdir = "ResidentialHVACGroundSourceHeatPumpVerticalBore"
      args = {
              "cop"=>cop,
              "eer"=>eer,
              "ground_conductivity"=>"0.6",
              "grout_conductivity"=>"0.4",
              "bore_config"=>Constants.SizingAuto,
              "bore_holes"=>Constants.SizingAuto,
              "bore_depth"=>Constants.SizingAuto,
              "bore_spacing"=>"20.0",
              "bore_diameter"=>"5.0",
              "pipe_size"=>"0.75",
              "ground_diffusivity"=>"0.0208",
              "fluid_type"=>Constants.FluidPropyleneGlycol,
              "frac_glycol"=>"0.3",
              "design_delta_t"=>"10.0",
              "pump_head"=>"50.0",
              "u_tube_leg_spacing"=>"0.9661",
              "u_tube_spacing_type"=>"b",
              "rated_shr"=>"0.732",
              "fan_power"=>"0.5",
              "heat_pump_capacity"=>Constants.SizingAuto,
              "supplemental_capacity"=>Constants.SizingAuto
             }
      measures[measure_subdir] = args
             
    end

  end

  def self.get_heating_setpoint(building, measures) 

    htg_sp = building.elements["BuildingDetails/Systems/HVAC/HVACControl/SetpointTempHeatingSeason"]
    measure_subdir = "ResidentialHVACHeatingSetpoints"
    if not htg_sp.nil?
      args = {
              "htg_wkdy"=>htg_sp.text,
              "htg_wked"=>htg_sp.text
             }  
      measures[measure_subdir] = args
    end
    
  end

  def self.get_cooling_setpoint(building, measures)

    clg_sp = building.elements["BuildingDetails/Systems/HVAC/HVACControl/SetpointTempCoolingSeason"]
    measure_subdir = "ResidentialHVACCoolingSetpoints"
    if not clg_sp.nil?
      args = {
              "clg_wkdy"=>clg_sp.text,
              "clg_wked"=>clg_sp.text
             }  
      measures[measure_subdir] = args
    end

  end

  def self.get_ceiling_fan(building, measures)

    cf = building.elements["BuildingDetails/Lighting/CeilingFan"]
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

  end

  def self.get_refrigerator(building, measures)

    kWhs = XMLHelper.get_value(building, "BuildingDetails/Appliances/Refrigerator/RatedAnnualkWh")
    measure_subdir = "ResidentialApplianceRefrigerator"  
    args = {
            "fridge_E"=>kWhs,
            "mult"=>"1",
            "weekday_sch"=>"0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041",
            "weekend_sch"=>"0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041",
            "monthly_sch"=>"0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837",
            "space"=>Constants.Auto
           }  
    measures[measure_subdir] = args
    
  end

  def self.get_clothes_washer(building, measures)

    cw = building.elements["BuildingDetails/Appliances/ClothesWasher"]
    measure_subdir = "ResidentialApplianceClothesWasher"  
    args = {
            "imef"=>"0.95",
            "rated_annual_energy"=>"387",
            "annual_cost"=>"24",
            "test_date"=>"2007",
            "drum_volume"=>"3.5",
            "cold_cycle"=>"false",
            "thermostatic_control"=>"true",
            "internal_heater"=>"false",
            "fill_sensor"=>"false",
            "mult_e"=>"1",
            "mult_hw"=>"1",
            "space"=>Constants.Auto,
            "plant_loop"=>Constants.Auto
           }  
    measures[measure_subdir] = args
    
  end

  def self.get_clothes_dryer(building, measures)
    
    cd = building.elements["BuildingDetails/Appliances/ClothesDryer"]
    cd_fuel = XMLHelper.get_value(cd, "FuelType")
    
    if cd_fuel == "electricity"
      measure_subdir = "ResidentialApplianceClothesDryerElectric"
      args = {
              "cef"=>"2.7",
              "mult"=>"1",
              "weekday_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "weekend_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    else
      measure_subdir = "ResidentialApplianceClothesDryerFuel"
      args = {
              "fuel_type"=>to_beopt_fuel(cd_fuel),
              "cef"=>"2.4",
              "fuel_split"=>"0.07",
              "mult"=>"1",
              "weekday_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "weekend_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    end
    
  end

  def self.get_dishwasher(building, measures)

    dw = building.elements["BuildingDetails/Appliances/Dishwasher"]
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
            "space"=>Constants.Auto,
            "plant_loop"=>Constants.Auto
           }  
    measures[measure_subdir] = args

  end

  def self.get_cooking_range(building, measures)
    
    crange = building.elements["BuildingDetails/Appliances/CookingRange"]
    ov = building.elements["BuildingDetails/Appliances/Oven"] # TODO
    crange_fuel = XMLHelper.get_value(crange, "FuelType")
    
    if crange_fuel == "electricity"
      measure_subdir = "ResidentialApplianceCookingRangeElectric"
      args = {
              "c_ef"=>"0.74",
              "o_ef"=>"0.11",
              "mult"=>"1",
              "weekday_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "weekend_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "monthly_sch"=>"1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    else
      measure_subdir = "ResidentialApplianceCookingRangeFuel"
      args = {
              "fuel_type"=>to_beopt_fuel(crange_fuel),
              "c_ef"=>"0.4",
              "o_ef"=>"0.058",
              "e_ignition"=>"true",
              "mult"=>"1",
              "weekday_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "weekend_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "monthly_sch"=>"1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    end
    
  end

  def self.get_lighting(building, measures)
  
    annual_kwh_interior = XMLHelper.get_value(building, "BuildingDetails/Lighting/extension/AnnualInteriorkWh")
    annual_kwh_exterior = XMLHelper.get_value(building, "BuildingDetails/Lighting/extension/AnnualExteriorkWh")
    annual_kwh_garage = XMLHelper.get_value(building, "BuildingDetails/Lighting/extension/AnnualGaragekWh")

    measure_subdir = "ResidentialLighting"
    args = {
            "option_type"=>Constants.OptionTypeLightingEnergyUses,
            "hw_cfl"=>"0", # not used
            "hw_led"=>"0", # not used
            "hw_lfl"=>"0", # not used
            "pg_cfl"=>"0", # not used
            "pg_led"=>"0", # not used
            "pg_lfl"=>"0", # not used
            "in_eff"=>"15", # not used
            "cfl_eff"=>"55", # not used
            "led_eff"=>"80", # not used
            "lfl_eff"=>"88", # not used
            "energy_use_interior"=>annual_kwh_interior,
            "energy_use_exterior"=>annual_kwh_exterior,
            "energy_use_garage"=>annual_kwh_garage
           }  
    measures[measure_subdir] = args  

  end
  
  def self.get_mels(building, measures)
  
    # TODO: Split apart residual MELs and TVs for reporting
    
    sens_kWhs = 0
    lat_kWhs = 0
    building.elements.each("BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other' or PlugLoadType='TV other']") do |pl|
      kWhs = XMLHelper.get_value(pl, "Load[Units='kWh/year']/Value").to_f
      if XMLHelper.has_element(pl, "extension/FracSensible") and XMLHelper.has_element(pl, "extension/FracLatent")
        sens_kWhs += kWhs * XMLHelper.get_value(pl, "extension/FracSensible").to_f
        lat_kWhs += kWhs * XMLHelper.get_value(pl, "extension/FracLatent").to_f
      else # No fractions; all sensible
        sens_kWhs += kWhs
      end
    end
    tot_kWhs = sens_kWhs + lat_kWhs
    
    measure_subdir = "ResidentialMiscPlugLoads"
    args = {
            "option_type"=>Constants.OptionTypePlugLoadsEnergyUse,
            "mult"=>"0", # not used
            "energy_use"=>tot_kWhs.to_s,
            "sens_frac"=>(sens_kWhs/tot_kWhs).to_s,
            "lat_frac"=>(lat_kWhs/tot_kWhs).to_s,
            "weekday_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "weekend_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "monthly_sch"=>"1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248",
           }  
    measures[measure_subdir] = args  
  
  end

  def self.get_airflow(building, measures)

    measure_subdir = "ResidentialAirflow"
    args = {
            "living_ach50"=>"7",
            "garage_ach50"=>"7",
            "finished_basement_ach"=>"0",
            "unfinished_basement_ach"=>"0.1",
            "crawl_ach"=>"0",
            "pier_beam_ach"=>"100",
            "unfinished_attic_sla"=>"0.00333",
            "shelter_coef"=>Constants.Auto,
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
            "duct_location"=>Constants.Auto,
            "duct_total_leakage"=>"0.3",
            "duct_supply_frac"=>"0.6",
            "duct_return_frac"=>"0.067",
            "duct_ah_supply_frac"=>"0.067",
            "duct_ah_return_frac"=>"0.267",
            "duct_location_frac"=>Constants.Auto,
            "duct_num_returns"=>Constants.Auto,
            "duct_supply_area_mult"=>"1",
            "duct_return_area_mult"=>"1",
            "duct_unconditioned_r"=>"0"
           }  
    measures[measure_subdir] = args

  end

  def self.get_hvac_sizing(building, measures)
    
    measure_subdir = "ResidentialHVACSizing"
    args = {
            "show_debug_info"=>"false"
           }  
    measures[measure_subdir] = args

  end

  def self.get_photovoltaics(building, measures)

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
    add_foundation_floors(model, building, living_space, foundation_space)
    add_foundation_walls(model, building, living_space, foundation_space)
    foundation_ceiling_area = add_foundation_ceilings(model, building, foundation_space, living_space)
    add_living_floors(model, building, geometry_errors, living_space, foundation_ceiling_area)
    add_living_walls(model, building, geometry_errors, avg_ceil_hgt, living_space, attic_space)
    add_attic_floors(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    add_attic_walls(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    add_attic_ceilings(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    
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
    model.getBuilding.setName("FIXME")
        
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

  def self.add_living_walls(model, building, errors, avg_ceil_hgt, living_space, attic_space)

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "living space"
      next if wall.elements["Area"].nil?
      
      z_origin = 0
      unless wall.elements["ExteriorAdjacentTo"].nil?
        if wall.elements["ExteriorAdjacentTo"].text == "attic"
          z_origin = OpenStudio.convert(avg_ceil_hgt,"ft","m").get * 1 # TODO: is this a bad assumption?
        end
      end
    
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
      
    end
    
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
        
      end
      
    end

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

  def self.add_foundation_ceilings(model, building, foundation_space, living_space)
       
    foundation_ceiling_area = 0
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
        
        foundation_ceiling_area += framefloor.elements["Area"].text.to_f
      
      end
    
    end
    
    return foundation_ceiling_area
      
  end

  def self.add_living_floors(model, building, errors, living_space, foundation_ceiling_area)

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
    above_grade_finished_floor_area = finished_floor_area - foundation_ceiling_area
    return unless above_grade_finished_floor_area > 0
    
    finishedfloor_width = OpenStudio.convert(Math::sqrt(above_grade_finished_floor_area),"ft","m").get
    finishedfloor_length = OpenStudio.convert(above_grade_finished_floor_area,"ft^2","m^2").get / finishedfloor_width
    
    surface = OpenStudio::Model::Surface.new(add_floor_polygon(-finishedfloor_width, -finishedfloor_length, 0), model) # don't put it right on top of existing finished floor
    surface.setName("inferred above grade finished floor")
    surface.setSurfaceType("Floor")
    surface.setSpace(living_space)
    surface.setOutsideBoundaryCondition("Adiabatic")

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
    
end