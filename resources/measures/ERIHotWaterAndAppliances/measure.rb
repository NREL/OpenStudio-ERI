require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class ERIHotWaterAndAppliances < OpenStudio::Measure::ModelMeasure
            
    def name
        return "Set ERI Hot Water & Appliances"
    end

    def arguments(model)
        args = OpenStudio::Measure::OSArgumentVector.new
        
        # Clothes Washer kWh
        cw_annual_kwh = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_annual_kwh", true)
        cw_annual_kwh.setDisplayName("Clothes Washer: Annual kWh")
        args << cw_annual_kwh
        
        # Clothes Washer Frac Sensible
        cw_frac_sens = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_frac_sens", true)
        cw_frac_sens.setDisplayName("Clothes Washer: Fraction Sensible")
        args << cw_frac_sens
        
        # Clothes Washer Frac Latent
        cw_frac_lat = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_frac_lat", true)
        cw_frac_lat.setDisplayName("Clothes Washer: Fraction Latent")
        args << cw_frac_lat
        
        # Clothes Washer GPD
        cw_gpd = OpenStudio::Measure::OSArgument::makeDoubleArgument("cw_gpd", true)
        cw_gpd.setDisplayName("Clothes Washer: Hot Water Gallons Per Day")
        args << cw_gpd
        
        # Clothes Dryer kWh
        cd_annual_kwh = OpenStudio::Measure::OSArgument::makeDoubleArgument("cd_annual_kwh", true)
        cd_annual_kwh.setDisplayName("Clothes Dryer: Annual kWh")
        args << cd_annual_kwh
        
        # Clothes Dryer therm
        cd_annual_therm = OpenStudio::Measure::OSArgument::makeDoubleArgument("cd_annual_therm", true)
        cd_annual_therm.setDisplayName("Clothes Dryer: Annual therm")
        args << cd_annual_therm

        # Clothes Dryer Frac Sensible
        cd_frac_sens = OpenStudio::Measure::OSArgument::makeDoubleArgument("cd_frac_sens", true)
        cd_frac_sens.setDisplayName("Clothes Dryer: Fraction Sensible")
        args << cd_frac_sens

        # Clothes Dryer Frac Latent
        cd_frac_lat = OpenStudio::Measure::OSArgument::makeDoubleArgument("cd_frac_lat", true)
        cd_frac_lat.setDisplayName("Clothes Dryer: Fraction Latent")
        args << cd_frac_lat

        # Clothes Dryer Fuel Type
        choices = OpenStudio::StringVector.new
        choices << Constants.FuelTypeGas
        choices << Constants.FuelTypeOil
        choices << Constants.FuelTypePropane
        choices << Constants.FuelTypeElectric
        cd_fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("cd_fuel_type", choices, true)
        cd_fuel_type.setDisplayName("Clothes Dryer: Fuel Type")
        args << cd_fuel_type
        
        # Dishwasher kWh
        dw_annual_kwh = OpenStudio::Measure::OSArgument::makeDoubleArgument("dw_annual_kwh", true)
        dw_annual_kwh.setDisplayName("Dishwasher: Annual kWh")
        args << dw_annual_kwh
        
        # Dishwasher Frac Sensible
        dw_frac_sens = OpenStudio::Measure::OSArgument::makeDoubleArgument("dw_frac_sens", true)
        dw_frac_sens.setDisplayName("Dishwasher: Fraction Sensible")
        args << dw_frac_sens
        
        # Dishwasher Frac Latent
        dw_frac_lat = OpenStudio::Measure::OSArgument::makeDoubleArgument("dw_frac_lat", true)
        dw_frac_lat.setDisplayName("Dishwasher: Fraction Latent")
        args << dw_frac_lat
        
        # Dishwasher GPD
        dw_gpd = OpenStudio::Measure::OSArgument::makeDoubleArgument("dw_gpd", true)
        dw_gpd.setDisplayName("Dishwasher: Hot Water Gallons Per Day")
        args << dw_gpd
        
        # Refrigerator kWh
        fridge_annual_kwh = OpenStudio::Measure::OSArgument::makeDoubleArgument("fridge_annual_kwh", true)
        fridge_annual_kwh.setDisplayName("Refrigerator: Annual kWh")
        args << fridge_annual_kwh
        
        # Cooking Range kWh
        cook_annual_kwh = OpenStudio::Measure::OSArgument::makeDoubleArgument("cook_annual_kwh", true)
        cook_annual_kwh.setDisplayName("Cooking Range: Annual kWh")
        args << cook_annual_kwh
        
        # Cooking Range therm
        cook_annual_therm = OpenStudio::Measure::OSArgument::makeDoubleArgument("cook_annual_therm", true)
        cook_annual_therm.setDisplayName("Cooking Range: Annual therm")
        args << cook_annual_therm

        # Cooking Range Frac Sensible
        cook_frac_sens = OpenStudio::Measure::OSArgument::makeDoubleArgument("cook_frac_sens", true)
        cook_frac_sens.setDisplayName("Cooking Range: Fraction Sensible")
        args << cook_frac_sens

        # Cooking Range Frac Latent
        cook_frac_lat = OpenStudio::Measure::OSArgument::makeDoubleArgument("cook_frac_lat", true)
        cook_frac_lat.setDisplayName("Cooking Range: Fraction Latent")
        args << cook_frac_lat

        # Cooking Range Fuel Type
        choices = OpenStudio::StringVector.new
        choices << Constants.FuelTypeGas
        choices << Constants.FuelTypeOil
        choices << Constants.FuelTypePropane
        choices << Constants.FuelTypeElectric
        cook_fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("cook_fuel_type", choices, true)
        cook_fuel_type.setDisplayName("Cooking Range: Fuel Type")
        args << cook_fuel_type
        
        # Fixtures GPD
        fx_gpd = OpenStudio::Measure::OSArgument::makeDoubleArgument("fx_gpd", true)
        fx_gpd.setDisplayName("Fixtures: Mixed Water Gallons Per Day")
        args << fx_gpd
        
        # Distribution System Type
        choices = OpenStudio::StringVector.new
        choices << "standard"
        choices << "recirculation"
        dist_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("dist_type", choices, true)
        dist_type.setDisplayName("Distribution: System Type")
        dist_type.setDefaultValue("standard")
        args << dist_type
            
        # Distribution GPD
        dist_gpd = OpenStudio::Measure::OSArgument::makeDoubleArgument("dist_gpd", true)
        dist_gpd.setDisplayName("Distribution: Mixed Water Gallons Per Day")
        args << dist_gpd
        
        # Recirc Distribution: Pump kWh
        dist_pump_annual_kwh = OpenStudio::Measure::OSArgument::makeDoubleArgument("dist_pump_annual_kwh", false)
        dist_pump_annual_kwh.setDisplayName("Distribution: Recirc Pump Annual kWh")
        dist_pump_annual_kwh.setDescription("The annual electric consumption of the recirculation pump.")
        args << dist_pump_annual_kwh
        
        # Has DWHR
        dwhr_avail = OpenStudio::Measure::OSArgument::makeBoolArgument("dwhr_avail", true)
        dwhr_avail.setDisplayName("Drain Water Heat Recovery")
        args << dwhr_avail
        
        # DHWR: Efficiency
        dwhr_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_eff", true)
        dwhr_eff.setDisplayName("Drain Water Heat Recovery: Efficiency")
        dwhr_eff.setDescription("Rated according to CSA B55.1.")
        args << dwhr_eff
        
        # DHWR: Efficiency Adjustment
        dwhr_eff_adj = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_eff_adj", true)
        dwhr_eff_adj.setDisplayName("Drain Water Heat Recovery: Efficiency Adjustment")
        dwhr_eff_adj.setDescription("Adjustment factor for low flow fixtures.")
        args << dwhr_eff_adj
        
        # DHWR: Fraction Impacted Hot Water
        dwhr_iFrac = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_iFrac", true)
        dwhr_iFrac.setDisplayName("Drain Water Heat Recovery: Fraction Impacted Hot Water")
        dwhr_iFrac.setDescription("Fraction of hot water use impacted by DWHR.")
        args << dwhr_iFrac

        # DHWR: PLC
        dwhr_plc = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_plc", true)
        dwhr_plc.setDisplayName("Drain Water Heat Recovery: PLC")
        dwhr_plc.setDescription("Piping Loss Coefficient.")
        args << dwhr_plc

        # DHWR: Location Factor
        dwhr_locF = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_locF", true)
        dwhr_locF.setDisplayName("Drain Water Heat Recovery: Location Factor")
        dwhr_locF.setDescription("Location factor for DWHR placement.")
        args << dwhr_locF

        # DHWR: Fixture Factor
        dwhr_fixF = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_fixF", true)
        dwhr_fixF.setDisplayName("Drain Water Heat Recovery: Fixture Factor")
        dwhr_fixF.setDescription("Based on whether all showers in the home are connected to DWHR units.")
        args << dwhr_fixF
        
        return args
    end #end the arguments method

    #define what happens when the measure is run
    def run(model, runner, user_arguments)
        super(model, runner, user_arguments)

        #use the built-in error checking 
        if not runner.validateUserArguments(arguments(model), user_arguments)
            return false
        end

        #assign the user inputs to variables
        cw_annual_kwh = runner.getDoubleArgumentValue("cw_annual_kwh",user_arguments)
        cw_frac_sens = runner.getDoubleArgumentValue("cw_frac_sens",user_arguments)
        cw_frac_lat = runner.getDoubleArgumentValue("cw_frac_lat",user_arguments)
        cw_gpd = runner.getDoubleArgumentValue("cw_gpd",user_arguments)
        cd_annual_kwh = runner.getDoubleArgumentValue("cd_annual_kwh",user_arguments)
        cd_annual_therm = runner.getDoubleArgumentValue("cd_annual_therm",user_arguments)
        cd_frac_sens = runner.getDoubleArgumentValue("cd_frac_sens",user_arguments)
        cd_frac_lat = runner.getDoubleArgumentValue("cd_frac_lat",user_arguments)
        cd_fuel_type = runner.getStringArgumentValue("cd_fuel_type",user_arguments)
        dw_annual_kwh = runner.getDoubleArgumentValue("dw_annual_kwh",user_arguments)
        dw_frac_sens = runner.getDoubleArgumentValue("dw_frac_sens",user_arguments)
        dw_frac_lat = runner.getDoubleArgumentValue("dw_frac_lat",user_arguments)
        dw_gpd = runner.getDoubleArgumentValue("dw_gpd",user_arguments)
        fridge_annual_kwh = runner.getDoubleArgumentValue("fridge_annual_kwh",user_arguments)
        cook_annual_kwh = runner.getDoubleArgumentValue("cook_annual_kwh",user_arguments)
        cook_annual_therm = runner.getDoubleArgumentValue("cook_annual_therm",user_arguments)
        cook_frac_sens = runner.getDoubleArgumentValue("cook_frac_sens",user_arguments)
        cook_frac_lat = runner.getDoubleArgumentValue("cook_frac_lat",user_arguments)
        cook_fuel_type = runner.getStringArgumentValue("cook_fuel_type",user_arguments)
        fx_gpd = runner.getDoubleArgumentValue("fx_gpd",user_arguments)
        dist_type = runner.getStringArgumentValue("dist_type",user_arguments)
        dist_gpd = runner.getDoubleArgumentValue("dist_gpd",user_arguments)
        dist_pump_annual_kwh = runner.getDoubleArgumentValue("dist_pump_annual_kwh",user_arguments)
        dwhr_avail = runner.getBoolArgumentValue("dwhr_avail",user_arguments)
        dwhr_eff = runner.getDoubleArgumentValue("dwhr_eff",user_arguments)
        dwhr_eff_adj = runner.getDoubleArgumentValue("dwhr_eff_adj",user_arguments)
        dwhr_iFrac = runner.getDoubleArgumentValue("dwhr_iFrac",user_arguments)
        dwhr_plc = runner.getDoubleArgumentValue("dwhr_plc",user_arguments)
        dwhr_locF = runner.getDoubleArgumentValue("dwhr_locF",user_arguments)
        dwhr_fixF = runner.getDoubleArgumentValue("dwhr_fixF",user_arguments)
        
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
        interval = OpenStudio::Time.new(0, 0, timestep_minutes)
        temp_sch_limits = model.getScheduleTypeLimitsByName("Temperature").get
        
        # Get weather
        weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
        if weather.error?
          return false
        end
        tmains_daily = weather.data.MainsDailyTemps

        # Get building units
        units = Geometry.get_building_units(model, runner)
        if units.nil?
          return false
        end

        units.each do |unit|
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
          plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, Constants.Auto, unit.spaces, Constants.ObjectNameWaterHeater(unit.name.to_s.gsub("unit", "u")).gsub("|","_"), runner)
          if plant_loop.nil?
            return false
          end
          water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
          plant_loop.addDemandBranchForComponent(water_use_connection)
          
          tHot = 125.0 # F, Water heater set point temperature
          tMix = 105.0 # F, Temperature of mixed water at fixtures
          
          # Calculate adjFmix
          dwhr_inT = 97.0 # F
          adjFmix = [0.0] * 365
          if dwhr_avail
            for day in 0..364
              dwhr_WHinTadj = dwhr_iFrac * (dwhr_inT - tmains_daily[day]) * dwhr_eff * dwhr_eff_adj * dwhr_plc * dwhr_locF * dwhr_fixF
              dwhr_WHinT = tmains_daily[day] + dwhr_WHinTadj
              adjFmix[day] = 1.0 - ((tHot - tMix) / (tHot - dwhr_WHinT))
            end
          else
            for day in 0..364
              adjFmix[day] = 1.0 - ((tHot - tMix) / (tHot - tmains_daily[day]))
            end
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
          time_series_hw = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(fractions_hw), "")
          schedule_hw = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_hw, model).get
          schedule_hw.setName("Hot Water Draw Profile")
          
          # Create mixed water draw profile schedule
          fractions_mw = []
          for day in 0..364
            for hr in 0..23
              for timestep in 1..(60.0/timestep_minutes)
                fractions_mw << norm_daily_fraction[hr] * adjFmix[day]
              end
            end
          end
          time_series_mw = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(fractions_mw), "")
          schedule_mw = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_mw, model).get
          schedule_mw.setName("Mixed Water Draw Profile")
          
          # Hot water target temperature schedule
          hw_temp_schedule = OpenStudio::Model::ScheduleConstant.new(model)
          hw_temp_schedule.setName("Hot Water temperature schedule")
          hw_temp_schedule.setValue(OpenStudio::convert(tHot, "F", "C").get)
          hw_temp_schedule.setScheduleTypeLimits(temp_sch_limits)
          
          # Clothes washer
          cw_name = Constants.ObjectNameClothesWasher(unit.name.to_s)
          cw_space = Geometry.get_space_from_string(unit.spaces, Constants.Auto)
          cw_peak_flow_gpm = cw_gpd/sum_fractions_hw/timestep_minutes*365.0
          cw_design_level_w = OpenStudio::convert(cw_annual_kwh*60.0/(cw_gpd*365.0/cw_peak_flow_gpm), "kW", "W").get
          add_electric_equipment(model, cw_name, cw_space, cw_design_level_w, cw_frac_sens, cw_frac_lat, schedule_hw)
          add_water_use_equipment(model, cw_name, cw_peak_flow_gpm, schedule_hw, hw_temp_schedule, water_use_connection)
          
          # Clothes dryer
          cd_name_e = Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric, unit.name.to_s)
          cd_name_f = Constants.ObjectNameClothesDryer(Constants.FuelTypeGas, unit.name.to_s)
          cd_weekday_sch = "0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024"
          cd_monthly_sch = "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
          cd_space = Geometry.get_space_from_string(unit.spaces, Constants.Auto)
          cd_schedule = MonthWeekdayWeekendSchedule.new(model, runner, cd_name_e, cd_weekday_sch, cd_weekday_sch, cd_monthly_sch, 1.0, 1.0)
          cd_design_level_e = cd_schedule.calcDesignLevelFromDailykWh(cd_annual_kwh/365.0)
          cd_design_level_f = cd_schedule.calcDesignLevelFromDailyTherm(cd_annual_therm/365.0)
          add_electric_equipment(model, cd_name_e, cd_space, cd_design_level_e, cd_frac_sens, cd_frac_lat, cd_schedule.schedule)
          add_other_equipment(model, cd_name_f, cd_space, cd_design_level_f, cd_frac_sens, cd_frac_lat, cd_schedule.schedule, cd_fuel_type)
          
          # Dishwasher
          dw_name = Constants.ObjectNameDishwasher(unit.name.to_s)
          dw_space = Geometry.get_space_from_string(unit.spaces, Constants.Auto)
          dw_peak_flow_gpm = dw_gpd/sum_fractions_hw/timestep_minutes*365.0
          dw_design_level_w = OpenStudio::convert(dw_annual_kwh*60.0/(dw_gpd*365.0/dw_peak_flow_gpm), "kW", "W").get
          add_electric_equipment(model, dw_name, dw_space, dw_design_level_w, dw_frac_sens, dw_frac_lat, schedule_hw)
          add_water_use_equipment(model, dw_name, dw_peak_flow_gpm, schedule_hw, hw_temp_schedule, water_use_connection)
          
          # Refrigerator
          fridge_name = Constants.ObjectNameRefrigerator(unit.name.to_s)
          fridge_weekday_sch = "0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041"
          fridge_monthly_sch = "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837"
          fridge_space = Geometry.get_space_from_string(unit.spaces, Constants.Auto)
          fridge_schedule = MonthWeekdayWeekendSchedule.new(model, runner, fridge_name, fridge_weekday_sch, fridge_weekday_sch, fridge_monthly_sch, 1.0, 1.0)
          fridge_design_level = fridge_schedule.calcDesignLevelFromDailykWh(fridge_annual_kwh/365.0)
          add_electric_equipment(model, fridge_name, fridge_space, fridge_design_level, 1.0, 0.0, fridge_schedule.schedule)
          
          # Cooking Range
          cook_name_e = Constants.ObjectNameCookingRange(Constants.FuelTypeElectric, unit.name.to_s)
          cook_name_f = Constants.ObjectNameCookingRange(Constants.FuelTypeGas, unit.name.to_s)
          cook_weekday_sch = "0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011"
          cook_monthly_sch = "1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097"
          cook_space = Geometry.get_space_from_string(unit.spaces, Constants.Auto)
          cook_schedule = MonthWeekdayWeekendSchedule.new(model, runner, cook_name_e, cook_weekday_sch, cook_weekday_sch, cook_monthly_sch, 1.0, 1.0)
          cook_design_level_e = cook_schedule.calcDesignLevelFromDailykWh(cook_annual_kwh/365.0)
          cook_design_level_f = cook_schedule.calcDesignLevelFromDailyTherm(cook_annual_therm/365.0)
          add_electric_equipment(model, cook_name_e, cook_space, cook_design_level_e, cook_frac_sens, cook_frac_lat, cook_schedule.schedule)
          add_other_equipment(model, cook_name_f, cook_space, cook_design_level_f, cook_frac_sens, cook_frac_lat, cook_schedule.schedule, cook_fuel_type)
          
          # Fixtures (showers, sinks, baths)
          fx_obj_name = Constants.ObjectNameShower(unit.name.to_s)
          fx_peak_flow_gpm = fx_gpd/sum_fractions_hw/timestep_minutes*365.0
          add_water_use_equipment(model, fx_obj_name, fx_peak_flow_gpm, schedule_mw, hw_temp_schedule, water_use_connection)
          
          # Distribution losses
          dist_obj_name = Constants.ObjectNameHotWaterDistribution(unit.name.to_s)
          dist_peak_flow_gpm = dist_gpd/sum_fractions_hw/timestep_minutes*365.0
          add_water_use_equipment(model, dist_obj_name, dist_peak_flow_gpm, schedule_mw, hw_temp_schedule, water_use_connection)
          
          # Recirculation pump
          dist_pump_obj_name = Constants.ObjectNameHotWaterRecircPump(unit.name.to_s)
          dist_pump_space = Geometry.get_space_from_string(unit.spaces, Constants.Auto)
          dist_pump_schedule = cd_schedule
          dist_pump_design_level = dist_pump_schedule.calcDesignLevelFromDailykWh(dist_pump_annual_kwh/365.0)
          add_electric_equipment(model, dist_pump_obj_name, dist_pump_space, dist_pump_design_level, 0.0, 0.0, dist_pump_schedule.schedule)
          
        end
        
        return true
        
    end
    
    def add_electric_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule)
        return if design_level_w <= 0.0
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
    
    def add_other_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule, fuel_type)
        return if design_level_w <= 0.0
        oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        oe = OpenStudio::Model::OtherEquipment.new(oe_def)
        oe.setName(obj_name)
        oe.setEndUseSubcategory(obj_name)
        oe.setFuelType(fuel_type)
        oe.setSpace(space)
        oe_def.setName(obj_name)
        oe_def.setDesignLevel(design_level_w)
        oe_def.setFractionRadiant(0.6 * frac_sens)
        oe_def.setFractionLatent(frac_lat)
        oe_def.setFractionLost(1.0 - frac_sens - frac_lat)
        oe.setSchedule(schedule)
    end
    
    def add_water_use_equipment(model, obj_name, peak_flow_gpm, schedule, temp_schedule, water_use_connection)
        return if peak_flow_gpm <= 0.0
        wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        wu = OpenStudio::Model::WaterUseEquipment.new(wu_def)
        wu.setName(obj_name)
        wu_def.setName(obj_name)
        wu_def.setPeakFlowRate(OpenStudio::convert(peak_flow_gpm, "gal/min", "m^3/s").get)
        wu_def.setEndUseSubcategory(obj_name)
        wu.setFlowRateFractionSchedule(schedule)
        wu_def.setTargetTemperatureSchedule(temp_schedule)
        water_use_connection.addWaterUseEquipment(wu)
    end
    
end #end the measure

#this allows the measure to be use by the application
ERIHotWaterAndAppliances.new.registerWithApplication
