require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"

#start the measure
class ResidentialClothesWasher < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Clothes Washer"
  end

  def description
    return "Adds (or replaces) a residential clothes washer with the specified efficiency, operation, and schedule. For multifamily buildings, the clothes washer can be set for all units of the building."
  end
  
  def modeler_description
    return "Since there is no Clothes Washer object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential clothes washer. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #TODO: New argument for demand response for clothes washer (alternate schedules if automatic DR control is specified)

    #make a double argument for Integrated Modified Energy Factor
    imef = OpenStudio::Measure::OSArgument::makeDoubleArgument("imef",true)
    imef.setDisplayName("Integrated Modified Energy Factor")
    imef.setUnits("ft^3/kWh-cycle")
    imef.setDescription("The Integrated Modified Energy Factor (IMEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption. If only a Modified Energy Factor (MEF) is available, convert using the equation: IMEF = (MEF - 0.503) / 0.95.")
    imef.setDefaultValue(0.95)
    args << imef
    
    #make a double argument for Rated Annual Consumption
    rated_annual_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_annual_energy",true)
    rated_annual_energy.setDisplayName("Rated Annual Consumption")
    rated_annual_energy.setUnits("kWh")
    rated_annual_energy.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    rated_annual_energy.setDefaultValue(387.0)
    args << rated_annual_energy
    
    #make a double argument for Annual Cost With Gas DHW
    annual_cost = OpenStudio::Measure::OSArgument::makeDoubleArgument("annual_cost",true)
    annual_cost.setDisplayName("Annual Cost with Gas DHW")
    annual_cost.setUnits("$")
    annual_cost.setDescription("The annual cost of using the system under test conditions.  Input is obtained from the EnergyGuide label.")
    annual_cost.setDefaultValue(24.0)
    args << annual_cost
    
    #make an integer argument for Test Date
    test_date = OpenStudio::Measure::OSArgument::makeIntegerArgument("test_date",true)
    test_date.setDisplayName("Test Date")
    test_date.setDefaultValue(2007)
    test_date.setDescription("Input obtained from EnergyGuide labels.  The new E-guide labels state that the test was performed under the 2004 DOE procedure, otherwise use year < 2004.")
    args << test_date

    #make a double argument for Drum Volume
    drum_volume = OpenStudio::Measure::OSArgument::makeDoubleArgument("drum_volume",true)
    drum_volume.setDisplayName("Drum Volume")
    drum_volume.setUnits("ft^3")
    drum_volume.setDescription("Volume of the washer drum.  Obtained from the EnergyStar website or the manufacturer's literature.")
    drum_volume.setDefaultValue(3.5)
    args << drum_volume
    
    #make a boolean argument for Use Cold Cycle Only
    cold_cycle = OpenStudio::Measure::OSArgument::makeBoolArgument("cold_cycle",true)
    cold_cycle.setDisplayName("Use Cold Cycle Only")
    cold_cycle.setDescription("The washer is operated using only the cold cycle.")
    cold_cycle.setDefaultValue(false)
    args << cold_cycle

    #make a boolean argument for Thermostatic Control
    thermostatic_control = OpenStudio::Measure::OSArgument::makeBoolArgument("thermostatic_control",true)
    thermostatic_control.setDisplayName("Thermostatic Control")
    thermostatic_control.setDescription("The clothes washer uses hot and cold water inlet valves to control temperature (varies hot water volume to control wash temperature).  Use this option for machines that use hot and cold inlet valves to control wash water temperature or machines that use both inlet valves AND internal electric heaters to control temperature of the wash water.  Input obtained from the manufacturer's literature.")
    thermostatic_control.setDefaultValue(true)
    args << thermostatic_control

    #make a boolean argument for Has Internal Heater Adjustment
    internal_heater = OpenStudio::Measure::OSArgument::makeBoolArgument("internal_heater",true)
    internal_heater.setDisplayName("Has Internal Heater Adjustment")
    internal_heater.setDescription("The washer uses an internal electric heater to adjust the temperature of wash water.  Use this option for washers that have hot and cold water connections but use an internal electric heater to adjust the wash water temperature.  Obtain the input from the manufacturer's literature.")
    internal_heater.setDefaultValue(false)
    args << internal_heater

    #make a boolean argument for Has Water Level Fill Sensor
    fill_sensor = OpenStudio::Measure::OSArgument::makeBoolArgument("fill_sensor",true)
    fill_sensor.setDisplayName("Has Water Level Fill Sensor")
    fill_sensor.setDescription("The washer has a vertical axis and water level fill sensor.  Input obtained from the manufacturer's literature.")
    fill_sensor.setDefaultValue(false)
    args << fill_sensor

      #make a double argument for occupancy energy multiplier
    mult_e = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_e",true)
    mult_e.setDisplayName("Occupancy Energy Multiplier")
    mult_e.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    mult_e.setDefaultValue(1)
    args << mult_e

      #make a double argument for occupancy water multiplier
    mult_hw = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_hw",true)
    mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
    mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
    mult_hw.setDefaultValue(1)
    args << mult_hw

    #make a choice argument for space
    spaces = Geometry.get_all_unit_spaces(model)
    if spaces.nil?
        spaces = []
    end
    space_args = OpenStudio::StringVector.new
    space_args << Constants.Auto
    spaces.each do |space|
        space_args << space.name.to_s
    end
    space = OpenStudio::Measure::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the dishwasher is located. '#{Constants.Auto}' will choose the lowest above-grade finished space available (e.g., first story living space), or a below-grade finished space as last resort. For multifamily buildings, '#{Constants.Auto}' will choose a space for each unit of the building.")
    space.setDefaultValue(Constants.Auto)
    args << space
    
    #make a choice argument for plant loop
    plant_loops = model.getPlantLoops
    plant_loop_args = OpenStudio::StringVector.new
    plant_loop_args << Constants.Auto
    plant_loops.each do |plant_loop|
        plant_loop_args << plant_loop.name.to_s
    end
    plant_loop = OpenStudio::Measure::OSArgument::makeChoiceArgument("plant_loop", plant_loop_args, true)
    plant_loop.setDisplayName("Plant Loop")
    plant_loop.setDescription("Select the plant loop for the dishwasher. '#{Constants.Auto}' will try to choose the plant loop associated with the specified space. For multifamily buildings, '#{Constants.Auto}' will choose the plant loop for each unit of the building.")
    plant_loop.setDefaultValue(Constants.Auto)
    args << plant_loop
    
    #make a choice argument for calc type
    calc_types = []
    calc_types << Constants.CalcTypeStandard
    calc_types << Constants.CalcTypeERIReferenceHome
    calc_types << Constants.CalcTypeERIRatedHome
    #calc_types << Constants.CalcTypeERIIndexAdjustmentDesign
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("calc_type", calc_types, true)
    calc_type.setDisplayName("Calculation Type")
    calc_type.setDescription("'#{Constants.CalcTypeStandard}' will use the DOE Building America Simulation Protocols. HERS options will use the ANSI/RESNET 301-2014 Standard.")
    calc_type.setDefaultValue(Constants.CalcTypeStandard)
    args << calc_type
    
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
    imef = runner.getDoubleArgumentValue("imef",user_arguments)
    rated_annual_energy = runner.getDoubleArgumentValue("rated_annual_energy",user_arguments)
    annual_cost = runner.getDoubleArgumentValue("annual_cost",user_arguments)
    test_date = runner.getIntegerArgumentValue("test_date", user_arguments)
    drum_volume = runner.getDoubleArgumentValue("drum_volume",user_arguments)
    cold_cycle = runner.getBoolArgumentValue("cold_cycle",user_arguments)
    thermostatic_control = runner.getBoolArgumentValue("thermostatic_control",user_arguments)
    internal_heater = runner.getBoolArgumentValue("internal_heater",user_arguments)
    fill_sensor = runner.getBoolArgumentValue("fill_sensor",user_arguments)
    mult_e = runner.getDoubleArgumentValue("mult_e",user_arguments)
    mult_hw = runner.getDoubleArgumentValue("mult_hw",user_arguments)
    space_r = runner.getStringArgumentValue("space",user_arguments)
    plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)
    calc_type = runner.getStringArgumentValue("calc_type", user_arguments)

    #Check for valid inputs
    if imef <= 0
        runner.registerError("Integrated modified energy factor must be greater than 0.0.")
        return false
    end
    if rated_annual_energy <= 0
        runner.registerError("Rated annual consumption must be greater than 0.0.")
        return false
    end
    if annual_cost <= 0
        runner.registerError("Annual cost with gas DHW must be greater than 0.0.")
        return false
    end
    if test_date < 1900
        runner.registerError("Test date must be greater than or equal to 1900.")
        return false
    end
    if drum_volume <= 0
        runner.registerError("Drum volume must be greater than 0.0.")
        return false
    end
    if mult_e < 0
        runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.0.")
        return false
    end
    if mult_hw < 0
        runner.registerError("Occupancy hot water multiplier must be greater than or equal to 0.0.")
        return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end

    # Get mains monthly temperatures
    site = model.getSite
    if !site.siteWaterMainsTemperature.is_initialized
        runner.registerError("Mains water temperature has not been set.")
        return false
    end
    mains_monthly_temps = WeatherProcess.get_mains_temperature(site.siteWaterMainsTemperature.get, site.latitude)[1]
    
    tot_ann_e = 0
    
    msgs = []
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        sch_unit_index = Geometry.get_unit_dhw_sched_index(model, unit, runner)
        if sch_unit_index.nil?
            return false
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit.spaces, space_r)
        next if space.nil?
        
        #Get unit number
        unit_num = Geometry.get_unit_number(model, unit, runner)
        
        #Get plant loop
        plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, plant_loop_s, unit.spaces, unit_num, runner)
        if plant_loop.nil?
            return false
        end
    
        # Get water heater setpoint
        wh_setpoint = Waterheater.get_water_heater_setpoint(model, plant_loop, runner)
        if wh_setpoint.nil?
            return false
        end

        obj_name = Constants.ObjectNameClothesWasher(unit.name.to_s)

        # Remove any existing clothes washer
        objects_to_remove = []
        space.electricEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != obj_name
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.electricEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        space.waterUseEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != obj_name
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.waterUseEquipmentDefinition
            if space_equipment.flowRateFractionSchedule.is_initialized
                objects_to_remove << space_equipment.flowRateFractionSchedule.get
            end
            if space_equipment.waterUseEquipmentDefinition.targetTemperatureSchedule.is_initialized
                objects_to_remove << space_equipment.waterUseEquipmentDefinition.targetTemperatureSchedule.get
            end
        end
        if objects_to_remove.size > 0
            runner.registerInfo("Removed existing clothes washer from space #{space.name.to_s}.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end
        
        daily_energy, daily_water, water_temp, f_lat, f_rad, f_lost = nil, nil, nil, nil, nil, nil
        
        if calc_type == Constants.CalcTypeStandard
            daily_energy, daily_water, water_temp = calc_standard(nbeds, rated_annual_energy, annual_cost, 
                                                                  test_date, drum_volume, cold_cycle,
                                                                  thermostatic_control, internal_heater, 
                                                                  fill_sensor, mult_e, mult_hw, 
                                                                  mains_monthly_temps, wh_setpoint)
            f_lat = 0.0
            f_rad = 0.48
            f_lost = 0.2
        else
            if calc_type == Constants.CalcTypeERIReferenceHome
                daily_energy, daily_water = calc_eri_reference(nbeds)
            
            elsif calc_type == Constants.CalcTypeERIRatedHome
                daily_energy, daily_water = calc_eri_rated(nbeds, rated_annual_energy, test_date, 
                                                           annual_cost, drum_volume)
            end
            
            water_temp = wh_setpoint
        
            # 30% of electricity usage -> internal gains
            # Of this total amount, 90% shall be apportioned to sensible internal gains and 
            # 10% to latent internal gains. Internal gains shall not be modified for clothes 
            # washers located in Unconditioned Space or outdoor environment (e.g. an 
            # unconditioned garage)
            f_sens = 0.3 * 0.9
            f_lat = 0.3 * 0.1
            f_rad = f_sens * 0.6
            f_lost = f_sens * 0.4
        end
        
        if daily_energy > 0
            annual_energy = daily_energy * 365
        
            # Create schedule
            sch = HotWaterSchedule.new(model, runner, Constants.ObjectNameClothesWasher + " schedule", Constants.ObjectNameClothesWasher + " temperature schedule", nbeds, sch_unit_index, "ClothesWasher", water_temp, File.dirname(__FILE__))
            if not sch.validated?
                return false
            end
            
            #Reuse existing water use connection if possible
            water_use_connection = nil
            plant_loop.demandComponents.each do |component|
                next unless component.to_WaterUseConnections.is_initialized
                water_use_connection = component.to_WaterUseConnections.get
                break
            end
            if water_use_connection.nil?
                #Need new water heater connection
                water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
                plant_loop.addDemandBranchForComponent(water_use_connection)
            end

            design_level = sch.calcDesignLevelFromDailykWh(daily_energy)
            peak_flow = sch.calcPeakFlowFromDailygpm(daily_water)

            #Add equipment for the cw
            cwdef = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            cw = OpenStudio::Model::ElectricEquipment.new(cwdef)
            cw.setName(obj_name)
            cw.setEndUseSubcategory(obj_name)
            cw.setSpace(space)
            cwdef.setName(obj_name)
            cwdef.setDesignLevel(design_level)
            cwdef.setFractionRadiant(f_rad)
            cwdef.setFractionLatent(f_lat)
            cwdef.setFractionLost(f_lost)
            cw.setSchedule(sch.schedule)

            #Add water use equipment for the dw
            cwdef2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
            cw2 = OpenStudio::Model::WaterUseEquipment.new(cwdef2)
            cw2.setName(obj_name)
            cw2.setSpace(space)
            cwdef2.setName(obj_name)
            cwdef2.setPeakFlowRate(peak_flow)
            cwdef2.setEndUseSubcategory(obj_name)
            cw2.setFlowRateFractionSchedule(sch.schedule)
            cwdef2.setTargetTemperatureSchedule(sch.temperatureSchedule)
            water_use_connection.addWaterUseEquipment(cw2)
            
            msgs << "A clothes washer with #{annual_energy.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
            
            tot_ann_e += annual_energy
            
            # Store some info for Clothes Dryer measures
            unit.setFeature(Constants.ClothesWasherIMEF(cw), imef)
            unit.setFeature(Constants.ClothesWasherRatedAnnualEnergy(cw), rated_annual_energy)
            unit.setFeature(Constants.ClothesWasherDrumVolume(cw), drum_volume)
        end
        
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned clothes washers totaling #{tot_ann_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No clothes washer has been assigned.")
    end
    
    return true
    
  end
  
  def calc_standard(nbeds, rated_annual_energy, annual_cost, test_date, drum_volume, cold_cycle, thermostatic_control, internal_heater, fill_sensor, mult_e, mult_hw, mains_monthly_temps, wh_setpoint)
    # Use EnergyGuide Label test data to calculate per-cycle energy and water consumption.
    # Calculations are based on "Method for Evaluating Energy Use of Dishwashers, Clothes Washers, 
    # and Clothes Dryers" by Eastment and Hendron, Conference Paper NREL/CP-550-39769, August 2006.
    # Their paper is in part based on the energy use calculations  presented in the 10CFR Part 430,
    # Subpt. B, App. J1 (DOE 1999),
    # http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl

    # Determine the Gas use for domestic hot water per cycle for test conditions
    # FIXME: Switch to inputs and remove EnergyGuideLabel class
    gas_rate = EnergyGuideLabel.get_energy_guide_gas_cost(test_date)/100
    elec_rate = EnergyGuideLabel.get_energy_guide_elec_cost(test_date)/100
        
    # Set the number of cycles per year for test conditions
    cycles_per_year_test = 392 # (see Eastment and Hendron, NREL/CP-550-39769, 2006)

    # The water heater recovery efficiency - how efficiently the heat from natural gas is transferred 
    # to the water in the water heater. The DOE 10CFR Part 430 assumes a nominal gas water heater
    # recovery efficiency of 0.75.
    gas_dhw_heater_efficiency_test = 0.75

    # Calculate test load weight (correlation based on data in Table 5.1 of 10CFR Part 430,
    # Subpt. B, App. J1, DOE 1999)
    test_load = 4.103003337 * drum_volume + 0.198242492 # lb

    # Set the Hot Water Inlet Temperature for test conditions
    if test_date < 2004
        # (see 10CFR Part 430, Subpt. B, App. J, Section 2.3, DOE 1999)
        hot_water_inlet_temperature_test = 140 # degF
    elsif test_date >= 2004
        # (see 10CFR Part 430, Subpt. B, App. J1, Section 2.3, DOE 1999)
        hot_water_inlet_temperature_test = 135 # degF
    end

    # Set the cold water inlet temperature for test conditions (see 10CFR Part 430, Subpt. B, App. J, 
    # Section 2.3, DOE 1999)
    cold_water_inlet_temp_test = 60 #degF

    # Set/calculate the hot water fraction and mixed water temperature for test conditions.
    # Washer varies relative amounts of hot and cold water (by opening and closing valves) to achieve 
    # a specific wash temperature. This includes the option to simulate washers operating on cold
    # cycle only (cold_cycle = True). This is an operating choice for the occupant - the 
    # washer itself was tested under normal test conditions (not cold cycle).
    if thermostatic_control
        # (see p. 10 of Eastment and Hendron, NREL/CP-550-39769, 2006)
        mixed_cycle_temperature_test = 92.5 # degF
        # (eq. 17 Eastment and Hendron, NREL/CP-550-39769, 2006)
        hot_water_vol_frac_test = ((mixed_cycle_temperature_test - cold_water_inlet_temp_test) / 
                                  (hot_water_inlet_temperature_test - cold_water_inlet_temp_test))
    else
        # Note: if washer only has cold water supply then the following code will run and 
        # incorrectly set the hot water fraction to 0.5. However, the code below will correctly 
        # determine hot and cold water usage.
        hot_water_vol_frac_test = 0.5
        mixed_cycle_temperature_test = ((hot_water_inlet_temperature_test - cold_water_inlet_temp_test) * \
                                       hot_water_vol_frac_test + cold_water_inlet_temp_test) # degF
    end
                                           
    # Use the EnergyGuide Label information (eq. 4 Eastment and Hendron, NREL/CP-550-39769, 2006).
    gas_consumption_for_dhw_per_cycle_test = ((rated_annual_energy * elec_rate - 
                                                annual_cost) / 
                                                (OpenStudio.convert(gas_dhw_heater_efficiency_test, "therm", "kWh").get * 
                                                elec_rate - gas_rate) / 
                                                cycles_per_year_test) # therms/cycle

    # Use additional EnergyGuide Label information to determine how  much electricity was used in 
    # the test to power the clothes washer's internal machinery (eq. 5 Eastment and Hendron, 
    # NREL/CP-550-39769, 2006). Any energy required for internal water heating will be included
    # in this value.
    elec_use_per_cycle_test = (rated_annual_energy / cycles_per_year_test -
                                 gas_consumption_for_dhw_per_cycle_test * 
                                 OpenStudio.convert(gas_dhw_heater_efficiency_test, "therm", "kWh").get) # kWh/cycle 
    
    if test_date < 2004
        # (see 10CFR Part 430, Subpt. B, App. J, Section 4.1.2, DOE 1999)
        dhw_deltaT_test = 90
    else
        # (see 10CFR Part 430, Subpt. B, App. J1, Section 4.1.2, DOE 1999)
        dhw_deltaT_test = 75
    end

    # Determine how much hot water was used in the test based on the amount of gas used in the 
    # test to heat the water and the temperature rise in the water heater in the test (eq. 6 
    # Eastment and Hendron, NREL/CP-550-39769, 2006).
    water_dens = Liquid.H2O_l.rho # lbm/ft^3
    water_sh = Liquid.H2O_l.cp  # Btu/lbm-R
    dhw_use_per_cycle_test = ((OpenStudio.convert(gas_consumption_for_dhw_per_cycle_test, "therm", "kWh").get * 
                                gas_dhw_heater_efficiency_test) / (dhw_deltaT_test * 
                                water_dens * water_sh * OpenStudio.convert(1.0, "Btu", "kWh").get / UnitConversion.ft32gal(1.0)))
     
    if fill_sensor and test_date < 2004
        # For vertical axis washers that are sensor-filled, use a multiplying factor of 0.94 
        # (see 10CFR Part 430, Subpt. B, App. J, Section 4.1.2, DOE 1999)
        dhw_use_per_cycle_test = dhw_use_per_cycle_test / 0.94
    end

    # Calculate total per-cycle usage of water (combined from hot and cold supply).
    # Note that the actual total amount of water used per cycle is assumed to be the same as 
    # the total amount of water used per cycle in the test. Under actual conditions, however, 
    # the ratio of hot and cold water can vary with thermostatic control (see below).
    actual_total_per_cycle_water_use = dhw_use_per_cycle_test / hot_water_vol_frac_test # gal/cycle

    # Set actual clothes washer water temperature for calculations below.
    if cold_cycle
        # To model occupant behavior of using only a cold cycle.
        water_temp = mains_monthly_temps.inject(:+)/12 # degF
    elsif thermostatic_control
        # Washer is being operated "normally" - at the same temperature as in the test.
        water_temp = mixed_cycle_temperature_test # degF
    else
        water_temp = wh_setpoint # degF
    end

    # (eq. 14 Eastment and Hendron, NREL/CP-550-39769, 2006)
    actual_cycles_per_year = (cycles_per_year_test * (0.5 + nbeds / 6) * 
                                (12.5 / test_load)) # cycles/year

    total_daily_water_use = (actual_total_per_cycle_water_use * actual_cycles_per_year / 
                               365) # gal/day

    # Calculate actual DHW use and elecricity use.
    # First calculate per-cycle usages.
    #    If the clothes washer has thermostatic control, then the test per-cycle DHW usage 
    #    amounts will have to be adjusted (up or down) to account for differences between 
    #    actual water supply temperatures and test conditions. If the clothes washer has 
    #    an internal heater, then the test per-cycle electricity usage amounts will have to 
    #    be adjusted (up or down) to account for differences between actual water supply 
    #    temperatures and hot water amounts and test conditions.
    # The calculations are done on a monthly basis to reflect monthly variations in TMains 
    # temperatures. Per-cycle amounts are then used to calculate monthly amounts and finally 
    # daily amounts.

    monthly_clothes_washer_dhw = Array.new(12, 0)
    monthly_clothes_washer_energy = Array.new(12, 0)

    mains_monthly_temps.each_with_index do |monthly_main, i|

        # Adjust per-cycle DHW amount.
        if thermostatic_control
            # If the washer has thermostatic control then its use of DHW will vary as the 
            # cold and hot water supply temperatures vary.

            if cold_cycle and monthly_main >= water_temp
                # In this special case, the washer uses only a cold cycle and the TMains 
                # temperature exceeds the desired cold cycle temperature. In this case, no 
                # DHW will be used (the adjustment is -100%). A special calculation is 
                # needed here since the formula for the general case (below) would imply
                # that a negative volume of DHW is used.
                dhw_use_per_cycle_adjustment = -1 * dhw_use_per_cycle_test # gal/cycle

            else
                # With thermostatic control, the washer will adjust the amount of hot water 
                # when either the hot water or cold water supply temperatures vary (eq. 18 
                # Eastment and Hendron, NREL/CP-550-39769, 2006).
                dhw_use_per_cycle_adjustment = (dhw_use_per_cycle_test * 
                                                  ((1 / hot_water_vol_frac_test) * 
                                                  (water_temp - monthly_main) + 
                                                  monthly_main - wh_setpoint) / 
                                                  (wh_setpoint - monthly_main)) # gal/cycle
                         
            end

        else
            # Without thermostatic control, the washer will not adjust the amount of hot water.
            dhw_use_per_cycle_adjustment = 0 # gal/cycle
        end

        # Calculate actual water usage amounts for the current month in the loop.
        actual_dhw_use_per_cycle = (dhw_use_per_cycle_test + 
                                      dhw_use_per_cycle_adjustment) # gal/cycle

        # Adjust per-cycle electricity amount.
        if internal_heater
            # If the washer heats the water internally, then its use of electricity will vary 
            # as the cold and hot water supply temperatures vary.

            # Calculate cold water usage per cycle to facilitate calculation of electricity 
            # usage below.
            actual_cold_water_use_per_cycle = (actual_total_per_cycle_water_use - 
                                                 actual_dhw_use_per_cycle) # gal/cycle

            # With an internal heater, the washer will adjust its heating (up or down) when 
            # actual conditions differ from test conditions according to the following three 
            # equations. Compensation for changes in sensible heat due to:
            # 1) a difference in hot water supply temperatures and
            # 2) a difference in cold water supply temperatures
            # (modified version of eq. 20 Eastment and Hendron, NREL/CP-550-39769, 2006).
            elec_use_per_cycle_adjustment_supply_temps = ((actual_dhw_use_per_cycle * 
                                                            (hot_water_inlet_temperature_test - 
                                                            wh_setpoint) + 
                                                            actual_cold_water_use_per_cycle * 
                                                            (cold_water_inlet_temp_test - 
                                                            monthly_main)) * 
                                                            (water_dens * water_sh * 
                                                            OpenStudio.convert(1.0, "Btu", "kWh").get / 
                                                            UnitConversion.ft32gal(1.0))) # kWh/cycle

            # Compensation for the change in sensible heat due to a difference in hot water 
            # amounts due to thermostatic control.
            elec_use_per_cycle_adjustment_hot_water_amount = (dhw_use_per_cycle_adjustment * 
                                                                (cold_water_inlet_temp_test - 
                                                                hot_water_inlet_temperature_test) * 
                                                                (water_dens * water_sh * 
                                                                OpenStudio.convert(1.0, "Btu", "kWh").get /
                                                                UnitConversion.ft32gal(1.0))) # kWh/cycle

            # Compensation for the change in sensible heat due to a difference in operating 
            # temperature vs. test temperature (applies only to cold cycle only).
            # Note: This adjustment can result in the calculation of zero electricity use 
            # per cycle below. This would not be correct (the washer will always use some 
            # electricity to operate). However, if the washer has an internal heater, it is 
            # not possible to determine how much of the electricity was  used for internal 
            # heating of water and how much for other machine operations.
            elec_use_per_cycle_adjustment_operating_temp = (actual_total_per_cycle_water_use * 
                                                              (water_temp - mixed_cycle_temperature_test) * 
                                                              (water_dens * water_sh * 
                                                              OpenStudio.convert(1.0, "Btu", "kWh").get / 
                                                              UnitConversion.ft32gal(1.0))) # kWh/cycle

            # Sum the three adjustments above
            elec_use_per_cycle_adjustment = elec_use_per_cycle_adjustment_supply_temps + 
                                               elec_use_per_cycle_adjustment_hot_water_amount + 
                                               elec_use_per_cycle_adjustment_operating_temp

        else

            elec_use_per_cycle_adjustment = 0 # kWh/cycle
            
        end

        # Calculate actual electricity usage amount for the current month in the loop.
        actual_elec_use_per_cycle = (elec_use_per_cycle_test + 
                                       elec_use_per_cycle_adjustment) # kWh/cycle

        # Do not allow negative electricity use
        if actual_elec_use_per_cycle < 0
            actual_elec_use_per_cycle = 0
        end

        # Calculate monthly totals
        monthly_clothes_washer_dhw[i] = ((actual_dhw_use_per_cycle * 
                                        actual_cycles_per_year * 
                                        Constants.MonthNumDays[i] / 365)) # gal/month
        monthly_clothes_washer_energy[i] = ((actual_elec_use_per_cycle * 
                                           actual_cycles_per_year * 
                                           Constants.MonthNumDays[i] / 365)) # kWh/month
    end

    daily_energy = monthly_clothes_washer_energy.inject(:+) / 365
                
    daily_water = total_daily_water_use * mult_hw
    daily_energy = daily_energy * mult_e
    
    return daily_energy, daily_water, water_temp
  end
  
  def calc_eri_reference(nbeds)
    daily_energy = (38 + 10 * nbeds)/365.0
    daily_water = (4.52 * (164 + 46.5 * nbeds)) * ((3.0 * 2.08 + 1.59)/(2.874 * 2.08 + 1.59)) / 365
    
    return daily_energy, daily_water
  end
  
  def calc_eri_rated(nbeds, ler, test_date, agc, cap_w)
    # Determine the Gas use for domestic hot water per cycle for test conditions
    # FIXME: Switch to inputs and remove EnergyGuideLabel class
    gas_rate = EnergyGuideLabel.get_energy_guide_gas_cost(test_date)/100
    elec_rate = EnergyGuideLabel.get_energy_guide_elec_cost(test_date)/100
    
    ncy = (3.0 / 2.847) * (164 + nbeds * 46.5)
    acy = ncy * ((3.0 * 2.08 + 1.59) / (cap_w * 2.08 + 1.59)) #Adjusted Cycles per Year
    daily_energy = (((ler / 392.0) - ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392) * 21.9825) * acy)/365.0
    daily_water = 60 * ((ler * elec_rate - agc) / (21.9825 * elec_rate - gas_rate) / 392) * acy / 365
    
    return daily_energy, daily_water
  end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesWasher.new.registerWithApplication