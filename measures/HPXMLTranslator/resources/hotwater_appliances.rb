# This file, which has 301 calculations, will eventually replace appliances.rb,
# which has Building America calculations.

require "#{File.dirname(__FILE__)}/constants"

class HotWaterAndAppliances

  def self.apply(model, unit, runner, weather, 
                 cw_annual_kwh, cw_frac_sens, cw_frac_lat,
                 cw_gpd, cd_annual_kwh, cd_annual_therm,
                 cd_frac_sens, cd_frac_lat, cd_fuel_type,
                 dw_annual_kwh, dw_frac_sens, dw_frac_lat,
                 dw_gpd, fridge_annual_kwh, cook_fuel_type,
                 cook_is_induction, oven_is_convection,
                 fx_gpd, fx_sens_btu, fx_lat_btu, dist_type, 
                 dist_gpd, dist_pump_annual_kwh, 
                 daily_wh_inlet_temperatures, daily_mw_fractions)
  
    # Table 4.6.1.1(1): Hourly Hot Water Draw Fraction for Hot Water Tests
    daily_fraction = [0.0085, 0.0085, 0.0085, 0.0085, 0.0085, 0.0100, 0.0750, 0.0750, 
                      0.0650, 0.0650, 0.0650, 0.0460, 0.0460, 0.0370, 0.0370, 0.0370, 
                      0.0370, 0.0630, 0.0630, 0.0630, 0.0630, 0.0510, 0.0510, 0.0085]
    norm_daily_fraction = []
    daily_fraction.each do |frac|
      norm_daily_fraction << (frac / daily_fraction.max)
    end
    
    # Schedules init
    timestep_minutes = (60.0/model.getTimestep.numberOfTimestepsPerHour).to_i
    start_date = model.getYearDescription.makeDate(1,1)
    timestep_interval = OpenStudio::Time.new(0, 0, timestep_minutes)
    timestep_day = OpenStudio::Time.new(0, 0, 60*24)
    temp_sch_limits = model.getScheduleTypeLimitsByName("Temperature")
    
    # Get unit beds/baths
    nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
    if nbeds.nil? or nbaths.nil?
      return false
    end
      
    # Get FFA
    ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
    if ffa.nil?
      return false
    end
    
    # Get plant loop
    plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, Constants.Auto, unit, Constants.ObjectNameWaterHeater(unit.name.to_s.gsub("unit ", "")).gsub("|","_"), runner)
    if plant_loop.nil?
      return false
    end
    water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
    plant_loop.addDemandBranchForComponent(water_use_connection)
    
    # Get water heater setpoint schedule
    setpoint_sched = Waterheater.get_water_heater_setpoint_schedule(model, plant_loop, runner)
    if setpoint_sched.nil?
      return false
    end
    
    # Create hot water draw profile schedule
    fractions_hw = []
    for day in 0..364
      for hr in 0..23
        for timestep in 1..(60.0/timestep_minutes)
          fractions_hw << norm_daily_fraction[hr]
        end
      end
    end
    sum_fractions_hw = fractions_hw.reduce(:+).to_f
    time_series_hw = OpenStudio::TimeSeries.new(start_date, timestep_interval, OpenStudio::createVector(fractions_hw), "")
    schedule_hw = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_hw, model).get
    schedule_hw.setName("Hot Water Draw Profile")
    
    # Create mixed water draw profile schedule
    fractions_mw = []
    for day in 0..364
      for hr in 0..23
        for timestep in 1..(60.0/timestep_minutes)
          fractions_mw << norm_daily_fraction[hr] * daily_mw_fractions[day]
        end
      end
    end
    time_series_mw = OpenStudio::TimeSeries.new(start_date, timestep_interval, OpenStudio::createVector(fractions_mw), "")
    schedule_mw = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_mw, model).get
    schedule_mw.setName("Mixed Water Draw Profile")
    
    # Replace mains water temperature schedule with water heater inlet temperature schedule.
    # Unless there is a DWHR, these are identical.
    daily_wh_inlet_temperatures_c = daily_wh_inlet_temperatures.map {|t| UnitConversions.convert(t, "F", "C")}
    time_series_tmains = OpenStudio::TimeSeries.new(start_date, timestep_day, OpenStudio::createVector(daily_wh_inlet_temperatures_c), "")
    schedule_tmains = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_tmains, model).get
    model.getSiteWaterMainsTemperature.setTemperatureSchedule(schedule_tmains)
              
    location_hierarchy = [Constants.SpaceTypeLiving,
                          Constants.SpaceTypeFinishedBasement]

    # Clothes washer
    if cw_gpd > 0
      cw_name = Constants.ObjectNameClothesWasher(unit.name.to_s)
      cw_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
      cw_peak_flow_gpm = cw_gpd/sum_fractions_hw/timestep_minutes*365.0
      cw_design_level_w = UnitConversions.convert(cw_annual_kwh*60.0/(cw_gpd*365.0/cw_peak_flow_gpm), "kW", "W")
      add_electric_equipment(model, cw_name, cw_space, cw_design_level_w, cw_frac_sens, cw_frac_lat, schedule_hw)
      add_water_use_equipment(model, cw_name, cw_peak_flow_gpm, schedule_hw, setpoint_sched, water_use_connection)
    end
    
    # Clothes dryer
    cd_name_e = Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric, unit.name.to_s)
    cd_name_f = Constants.ObjectNameClothesDryer(Constants.FuelTypeGas, unit.name.to_s)
    cd_weekday_sch = "0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024"
    cd_monthly_sch = "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
    cd_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
    cd_schedule = MonthWeekdayWeekendSchedule.new(model, runner, cd_name_e, cd_weekday_sch, cd_weekday_sch, cd_monthly_sch, 1.0, 1.0)
    cd_design_level_e = cd_schedule.calcDesignLevelFromDailykWh(cd_annual_kwh/365.0)
    cd_design_level_f = cd_schedule.calcDesignLevelFromDailyTherm(cd_annual_therm/365.0)
    add_electric_equipment(model, cd_name_e, cd_space, cd_design_level_e, cd_frac_sens, cd_frac_lat, cd_schedule.schedule)
    add_other_equipment(model, cd_name_f, cd_space, cd_design_level_f, cd_frac_sens, cd_frac_lat, cd_schedule.schedule, cd_fuel_type)
    
    # Dishwasher
    if dw_gpd > 0
      dw_name = Constants.ObjectNameDishwasher(unit.name.to_s)
      dw_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
      dw_peak_flow_gpm = dw_gpd/sum_fractions_hw/timestep_minutes*365.0
      dw_design_level_w = UnitConversions.convert(dw_annual_kwh*60.0/(dw_gpd*365.0/dw_peak_flow_gpm), "kW", "W")
      add_electric_equipment(model, dw_name, dw_space, dw_design_level_w, dw_frac_sens, dw_frac_lat, schedule_hw)
      add_water_use_equipment(model, dw_name, dw_peak_flow_gpm, schedule_hw, setpoint_sched, water_use_connection)
    end
    
    # Refrigerator
    fridge_name = Constants.ObjectNameRefrigerator(unit.name.to_s)
    fridge_weekday_sch = "0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041"
    fridge_monthly_sch = "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837"
    fridge_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
    fridge_schedule = MonthWeekdayWeekendSchedule.new(model, runner, fridge_name, fridge_weekday_sch, fridge_weekday_sch, fridge_monthly_sch, 1.0, 1.0)
    fridge_design_level = fridge_schedule.calcDesignLevelFromDailykWh(fridge_annual_kwh/365.0)
    add_electric_equipment(model, fridge_name, fridge_space, fridge_design_level, 1.0, 0.0, fridge_schedule.schedule)
    
    # Cooking Range
    cook_annual_kwh, cook_annual_therm, cook_frac_sens, cook_frac_lat = self.calc_range_oven_energy(nbeds, cook_fuel_type, cook_is_induction, oven_is_convection)
    cook_name_e = Constants.ObjectNameCookingRange(Constants.FuelTypeElectric, unit.name.to_s)
    cook_name_f = Constants.ObjectNameCookingRange(Constants.FuelTypeGas, unit.name.to_s)
    cook_weekday_sch = "0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011"
    cook_monthly_sch = "1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097"
    cook_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
    cook_schedule = MonthWeekdayWeekendSchedule.new(model, runner, cook_name_e, cook_weekday_sch, cook_weekday_sch, cook_monthly_sch, 1.0, 1.0)
    cook_design_level_e = cook_schedule.calcDesignLevelFromDailykWh(cook_annual_kwh/365.0)
    cook_design_level_f = cook_schedule.calcDesignLevelFromDailyTherm(cook_annual_therm/365.0)
    add_electric_equipment(model, cook_name_e, cook_space, cook_design_level_e, cook_frac_sens, cook_frac_lat, cook_schedule.schedule)
    add_other_equipment(model, cook_name_f, cook_space, cook_design_level_f, cook_frac_sens, cook_frac_lat, cook_schedule.schedule, cook_fuel_type)
    
    # Fixtures (showers, sinks, baths)
    fx_obj_name = Constants.ObjectNameShower(unit.name.to_s)
    fx_obj_name_sens = "#{fx_obj_name} Sensible"
    fx_obj_name_lat = "#{fx_obj_name} Latent"
    fx_peak_flow_gpm = fx_gpd/sum_fractions_hw/timestep_minutes*365.0
    fx_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
    fx_schedule = cd_schedule
    fx_design_level_sens = fx_schedule.calcDesignLevelFromDailykWh(UnitConversions.convert(fx_sens_btu, "Btu", "kWh")/365.0)
    fx_design_level_lat = fx_schedule.calcDesignLevelFromDailykWh(UnitConversions.convert(fx_lat_btu, "Btu", "kWh")/365.0)
    add_water_use_equipment(model, fx_obj_name, fx_peak_flow_gpm, schedule_mw, setpoint_sched, water_use_connection)
    add_other_equipment(model, fx_obj_name_sens, fx_space, fx_design_level_sens, 1.0, 0.0, fx_schedule.schedule, nil)
    add_other_equipment(model, fx_obj_name_lat, fx_space, fx_design_level_lat, 0.0, 1.0, fx_schedule.schedule, nil)
    
    # Distribution losses
    dist_obj_name = Constants.ObjectNameHotWaterDistribution(unit.name.to_s)
    dist_peak_flow_gpm = dist_gpd/sum_fractions_hw/timestep_minutes*365.0
    add_water_use_equipment(model, dist_obj_name, dist_peak_flow_gpm, schedule_mw, setpoint_sched, water_use_connection)
    
    # Recirculation pump
    dist_pump_obj_name = Constants.ObjectNameHotWaterRecircPump(unit.name.to_s)
    dist_pump_space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
    dist_pump_schedule = cd_schedule
    dist_pump_design_level = dist_pump_schedule.calcDesignLevelFromDailykWh(dist_pump_annual_kwh/365.0)
    add_electric_equipment(model, dist_pump_obj_name, dist_pump_space, dist_pump_design_level, 0.0, 0.0, dist_pump_schedule.schedule)

    return true
  end
  
  def self.calc_range_oven_energy(nbeds, fuel_type, is_induction, is_convection)
    if is_induction
      burner_ef = 0.91
    else
      burner_ef = 1.0
    end
    if is_convection
      oven_ef = 0.95
    else
      oven_ef = 1.0
    end
    if fuel_type != Constants.FuelTypeElectric
      annual_kwh = 22.6 + 2.7*nbeds
      annual_therm = oven_ef*(22.6 + 2.7*nbeds)
      tot_btu = UnitConversions.convert(annual_kwh, "kWh", "Btu") + UnitConversions.convert(annual_therm, "therm", "Btu")
      gains_sens = (4086.0 + 488.0*nbeds)*365 # Btu
      gains_lat = (1037.0 + 124.0*nbeds)*365 # Btu
      frac_sens = gains_sens/tot_btu
      frac_lat = gains_lat/tot_btu
    else
      annual_kwh = burner_ef*oven_ef*(331 + 39.0*nbeds)
      annual_therm = 0.0
      tot_btu = UnitConversions.convert(annual_kwh, "kWh", "Btu") + UnitConversions.convert(annual_therm, "therm", "Btu")
      gains_sens = (2228.0 + 262.0*nbeds)*365 # Btu
      gains_lat = (248.0 + 29.0*nbeds)*365 # Btu
      frac_sens = gains_sens/tot_btu
      frac_lat = gains_lat/tot_btu
    end
    return annual_kwh, annual_therm, frac_sens, frac_lat
  end
  
  def self.calc_reference_fridge_energy(nbeds)
    return 637.0 + 18.0*nbeds
  end
      
  private
  
  def self.add_electric_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule)
    return if design_level_w == 0.0
    ee_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    ee = OpenStudio::Model::ElectricEquipment.new(ee_def)
    ee.setName(obj_name)
    ee.setEndUseSubcategory(obj_name)
    ee.setSpace(space)
    ee_def.setName(obj_name)
    ee_def.setDesignLevel(design_level_w)
    ee_def.setFractionRadiant(0.6 * frac_sens)
    ee_def.setFractionLatent(frac_lat)
    ee_def.setFractionLost(1.0 - frac_sens - frac_lat)
    ee.setSchedule(schedule)
  end
  
  def self.add_other_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule, fuel_type)
    return if design_level_w == 0.0
    oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    oe = OpenStudio::Model::OtherEquipment.new(oe_def)
    oe.setName(obj_name)
    oe.setEndUseSubcategory(obj_name)
    if fuel_type.nil?
      oe.setFuelType("None")
    else
      oe.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
    end
    oe.setSpace(space)
    oe_def.setName(obj_name)
    oe_def.setDesignLevel(design_level_w)
    oe_def.setFractionRadiant(0.6 * frac_sens)
    oe_def.setFractionLatent(frac_lat)
    oe_def.setFractionLost(1.0 - frac_sens - frac_lat)
    oe.setSchedule(schedule)
  end
  
  def self.add_water_use_equipment(model, obj_name, peak_flow_gpm, schedule, temp_schedule, water_use_connection)
    return if peak_flow_gpm == 0.0
    wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    wu = OpenStudio::Model::WaterUseEquipment.new(wu_def)
    wu.setName(obj_name)
    wu_def.setName(obj_name)
    wu_def.setPeakFlowRate(UnitConversions.convert(peak_flow_gpm, "gal/min", "m^3/s"))
    wu_def.setEndUseSubcategory(obj_name)
    wu.setFlowRateFractionSchedule(schedule)
    wu_def.setTargetTemperatureSchedule(temp_schedule)
    water_use_connection.addWaterUseEquipment(wu)
  end

end