require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class ResidentialDishwasher < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Dishwasher"
  end
 
  def description
    return "Adds (or replaces) a residential dishwasher with the specified efficiency, operation, and schedule."
  end
  
  def modeler_description
    return "Since there is no Dishwasher object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential dishwasher. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
 
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for dws (alternate schedules if automatic DR control is specified)
	
	#make an integer argument for number of place settings
	num_settings = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_settings",true)
	num_settings.setDisplayName("Number of Place Settings")
	num_settings.setUnits("#")
	num_settings.setDescription("The number of place settings for the unit. Data obtained from manufacturer's literature.")
	num_settings.setDefaultValue(12)
	args << num_settings
	
	#make a double argument for rated annual consumption
	dw_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("dw_E",true)
	dw_E.setDisplayName("Rated Annual Consumption")
	dw_E.setUnits("kWh")
	dw_E.setDescription("The annual energy consumed by the dishwasher, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
	dw_E.setDefaultValue(290)
	args << dw_E
	
	#make a bool argument for internal heater adjustment
	int_htr = OpenStudio::Ruleset::OSArgument::makeBoolArgument("int_htr",true)
	int_htr.setDisplayName("Internal Heater Adjustment")
	int_htr.setDescription("Does the system use an internal electric heater to adjust water temperature?   Input obtained from manufacturer's literature.")
	int_htr.setDefaultValue("true")
	args << int_htr

	#make a bool argument for cold water inlet only
	cold_inlet = OpenStudio::Ruleset::OSArgument::makeBoolArgument("cold_inlet",true)
	cold_inlet.setDisplayName("Cold Water Inlet Only")
	cold_inlet.setDescription("Does the dishwasher use a cold water connection only.   Input obtained from manufacturer's literature.")
	cold_inlet.setDefaultValue("false")
	args << cold_inlet
	
	#make a double argument for cold water connection use
	cold_use = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cold_use",true)
	cold_use.setDisplayName("Cold Water Conn Use Per Cycle")
	cold_use.setUnits("gal/cycle")
	cold_use.setDescription("Volume of water per cycle used if there is only a cold water inlet connection, for the dishwasher.   Input obtained from manufacturer's literature.")
	cold_use.setDefaultValue(0)
	args << cold_use

	#make an integer argument for energy guide date
	eg_date = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("eg_date",true)
	eg_date.setDisplayName("Energy Guide Date")
	eg_date.setDescription("Energy Guide test date.")
	eg_date.setDefaultValue(2007)
	args << eg_date
	
	#make a double argument for energy guide annual gas cost
	eg_gas_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eg_gas_cost",true)
	eg_gas_cost.setDisplayName("Energy Guide Annual Gas Cost")
	eg_gas_cost.setUnits("$/yr")
	eg_gas_cost.setDescription("Annual cost of gas, as rated.  Obtained from the EnergyGuide label.")
	eg_gas_cost.setDefaultValue(23)
	args << eg_gas_cost
	
	#make a double argument for occupancy energy multiplier
	mult_e = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult_e",true)
	mult_e.setDisplayName("Occupancy Energy Multiplier")
	mult_e.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	mult_e.setDefaultValue(1)
	args << mult_e

	#make a double argument for occupancy water multiplier
	mult_hw = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult_hw",true)
	mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
	mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
	mult_hw.setDefaultValue(1)
	args << mult_hw
	
	#make an integer argument for number of bedrooms
	chs = OpenStudio::StringVector.new
	chs << "1"
	chs << "2" 
	chs << "3"
	chs << "4"
	chs << "5+"
	num_br = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("Num_Br", chs, true)
	num_br.setDisplayName("Number of Bedrooms")
	num_br.setDefaultValue("3")
	args << num_br
	
	#make a choice argument for which zone to put the space in
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end
	
	#make a choice argument for space type
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_handles, space_type_display_names)
    space_type.setDisplayName("Select the space where the dishwasher is located")
    space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << space_type
    
    #make a double argument for water heater setpoint
    #FIXE: remove this some day and require water heater to be set first
	wh_setpoint = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("wh_setpoint",true)
	wh_setpoint.setDisplayName("Water Heater Setpoint")
	wh_setpoint.setDescription("Water heater setpoint temperature.")
	wh_setpoint.setDefaultValue(125.0)
    wh_setpoint.setUnits("degrees F")
	args << wh_setpoint

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
	dw_capacity = runner.getIntegerArgumentValue("num_settings",user_arguments).to_f
	dw_energy_guide_annual_energy = runner.getDoubleArgumentValue("dw_E", user_arguments)
	dw_is_cold_water_inlet_only = runner.getBoolArgumentValue("cold_inlet", user_arguments)
	dw_internal_heater_adjustment = runner.getBoolArgumentValue("int_htr", user_arguments)
	dw_cold_water_conn_use_per_cycle = runner.getDoubleArgumentValue("cold_use", user_arguments)
	dw_energy_guide_date = runner.getIntegerArgumentValue("eg_date", user_arguments)
	dw_energy_guide_annual_gas_cost = runner.getDoubleArgumentValue("eg_gas_cost", user_arguments)
	dw_energy_multiplier = runner.getDoubleArgumentValue("mult_e", user_arguments)
	dw_hot_water_multiplier = runner.getDoubleArgumentValue("mult_hw", user_arguments)
	num_br = runner.getStringArgumentValue("Num_Br", user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
    wh_setpoint = runner.getDoubleArgumentValue("wh_setpoint", user_arguments)
	
	#Convert num bedrooms to appropriate integer
	num_br = num_br.tr('+','').to_f
	
	#Check for valid inputs
	if dw_capacity < 1
		runner.registerError("Number of place settings must be greater than or equal to 1.")
		return false
	end
	if dw_energy_guide_annual_energy < 0
		runner.registerError("Rated annual energy consumption must be greater than or equal to 0.")
		return false
	end
	if dw_cold_water_conn_use_per_cycle < 0
		runner.registerError("Cold water connection use must be greater than or equal to 0.")
		return false
	end
	if dw_energy_guide_date < 1900
		runner.registerError("Energy Guide date must be greater than or equal to 1900.")
		return false
	end
	if dw_energy_guide_annual_gas_cost <= 0
		runner.registerError("Energy Guide annual gas cost must be greater than 0.")
		return false
	end
	if dw_energy_multiplier < 0
		runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.")
		return false
	end
	if dw_hot_water_multiplier < 0
		runner.registerError("Occupancy hot water multiplier must be greater than or equal to 0.")
		return false
	end

	properties = Properties.new

	#hard coded convective, radiative, latent, and lost fractions for dishwashers
    dw_lat = 0.15
    dw_rad = 0.36
    dw_conv = 0.24
    dw_lost = 1 - dw_lat - dw_rad - dw_conv
	
	# TODO: Existing OpenStudio unit conversion? If not, add to units.rb
	ft32gal = 7.4805195

	# The water used in dishwashers must be heated, either internally or
	# externally, to at least 140 degF for proper operation (dissolving of
	# detergent, cleaning of dishes).
	dw_operating_water_temp = 140 # degF
	
	water_dens = properties.H2O_l.rho # lbm/ft^3
	water_sh = properties.H2O_l.Cp  # Btu/lbm-R

	# Use EnergyGuide Label test data to calculate per-cycle energy and
	# water consumption. Calculations are based on "Method for
	# Evaluating Energy Use of Dishwashers, Clothes Washers, and
	# Clothes Dryers" by Eastment and Hendron, Conference Paper
	# NREL/CP-550-39769, August 2006. Their paper is in part based on
	# the energy use calculations presented in the 10CFR Part 430,
	# Subpt. B, App. C (DOE 1999),
	# http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl
	if dw_energy_guide_date <= 2002
		test_dw_cycles_per_year = 322
	elsif dw_energy_guide_date < 2004
		test_dw_cycles_per_year = 264
	else
		test_dw_cycles_per_year = 215
	end

	# The water heater recovery efficiency - how efficiently the heat
	# from natural gas is transferred to the water in the water heater.
	# The DOE 10CFR Part 430 assumes a nominal gas water heater
	# recovery efficiency of 0.75.
	test_dw_gas_dhw_heater_efficiency = 0.75

	# Cold water supply temperature during tests (see 10CFR Part 430,
	# Subpt. B, App. C, Section 1.19, DOE 1999).
	test_dw_mains_temp = 50 # degF
	# Hot water supply temperature during tests (see 10CFR Part 430,
	# Subpt. B, App. C, Section 1.19, DOE 1999).
	test_dw_dhw_temp = 120 # degF

	# Determine the Gas use for domestic hot water per cycle for test conditions
	if dw_is_cold_water_inlet_only
		test_dw_gas_use_per_cycle = 0 # therms/cycle
	else
		# Use the EnergyGuide Label information (eq. 1 Eastment and
		# Hendron, NREL/CP-550-39769, 2006).
		dw_energy_guide_gas_cost = EnergyGuideLabel.get_energy_guide_gas_cost(dw_energy_guide_date)/100
		dw_energy_guide_elec_cost = EnergyGuideLabel.get_energy_guide_elec_cost(dw_energy_guide_date)/100
		test_dw_gas_use_per_cycle = ((dw_energy_guide_annual_energy * 
									 dw_energy_guide_elec_cost - 
									 dw_energy_guide_annual_gas_cost) / 
									(OpenStudio.convert(test_dw_gas_dhw_heater_efficiency, "therm", "kWh").get * 
									 dw_energy_guide_elec_cost - 
									 dw_energy_guide_gas_cost) / 
									test_dw_cycles_per_year) # Therns/cycle
	end
    
	# Use additional EnergyGuide Label information to determine how much
	# electricity was used in the test to power the dishwasher's
	# internal machinery (eq. 2 Eastment and Hendron, NREL/CP-550-39769,
	# 2006). Any energy required for internal water heating will be
	# included in this value.
	test_dw_elec_use_per_cycle = dw_energy_guide_annual_energy / \
			test_dw_cycles_per_year - \
			OpenStudio.convert(test_dw_gas_dhw_heater_efficiency, "therm", "kWh").get * \
			test_dw_gas_use_per_cycle # kWh/cycle

	if dw_is_cold_water_inlet_only
		# for Type 3 Dishwashers - those with an electric element
		# internal to the machine to provide all of the water heating
		# (see Eastment and Hendron, NREL/CP-550-39769, 2006)
		test_dw_dhw_use_per_cycle = 0 # gal/cycle
	else
		if dw_internal_heater_adjustment
			# for Type 2 Dishwashers - those with an electric element
			# internal to the machine for providing auxiliary water
			# heating (see Eastment and Hendron, NREL/CP-550-39769,
			# 2006)
			test_dw_water_heater_temp_diff = test_dw_dhw_temp - \
					test_dw_mains_temp # degF water heater temperature rise in the test
		else
			test_dw_water_heater_temp_diff = dw_operating_water_temp - \
					test_dw_mains_temp # water heater temperature rise in the test
		end
		
		# Determine how much hot water was used in the test based on
		# the amount of gas used in the test to heat the water and the
		# temperature rise in the water heater in the test (eq. 3
		# Eastment and Hendron, NREL/CP-550-39769, 2006).
		test_dw_dhw_use_per_cycle = (OpenStudio.convert(test_dw_gas_use_per_cycle, "therm", "kWh").get * \
									 test_dw_gas_dhw_heater_efficiency) / \
									 (test_dw_water_heater_temp_diff * \
									  water_dens * water_sh * \
									  OpenStudio.convert(1, "Btu", "kWh").get / ft32gal) # gal/cycle (hot water)
	end
									  
	# (eq. 16 Eastment and Hendron, NREL/CP-550-39769, 2006)
	actual_dw_cycles_per_year = 215 * (0.5 + num_br / 6) * (8 / dw_capacity) # cycles/year

	daily_dishwasher_dhw = actual_dw_cycles_per_year * test_dw_dhw_use_per_cycle / 365 # gal/day (hot water)

	# Calculate total (hot or cold) daily water usage.
	if dw_is_cold_water_inlet_only
		# From the 2010 BA Benchmark for dishwasher hot water
		# consumption. Should be appropriate for cold-water-inlet-only
		# dishwashers also.
		daily_dishwasher_water = 2.5 + 0.833 * num_br # gal/day
	else
		# Dishwasher uses only hot water so total water usage = DHW usage.
		daily_dishwasher_water = daily_dishwasher_dhw # gal/day
	end
    
	# Calculate actual electricity use per cycle by adjusting test
	# electricity use per cycle (up or down) to account for differences
	# between actual water supply temperatures and test conditions.
	# Also convert from per-cycle to daily electricity usage amounts.
	if dw_is_cold_water_inlet_only

        epw_path = runner.lastEpwFilePath.get.to_s
        if File.exist?(epw_path)
            @weather = WeatherProcess.new(epw_path,runner)
        else
           runner.registerError("Cannot find weather file: #{epw_path}")
           return false
        end
        daily_mains, monthly_mains, annual_mains = WeatherProcess._calc_mains_temperature(@weather.data, @weather.header)

        monthly_dishwasher_energy = Array.new(12, 0)
		i = 0
		monthly_mains.each do |tmain|
			# Adjust for monthly variation in Tmains vs. test cold
			# water supply temperature.
			actual_dw_elec_use_per_cycle = test_dw_elec_use_per_cycle + \
                                           (test_dw_mains_temp - tmain) * \
                                           dw_cold_water_conn_use_per_cycle * \
                                           (water_dens * water_sh * OpenStudio.convert(1, "Btu", "kWh").get / ft32gal) # kWh/cycle
			monthly_dishwasher_energy[i] = (actual_dw_elec_use_per_cycle * \
										    Constants.MonthNumDays[i] * \
											actual_dw_cycles_per_year / \
											365) # kWh/month
			i = i + 1
		end

		daily_energy = monthly_dishwasher_energy.inject(:+) / 365 # kWh/day

	elsif dw_internal_heater_adjustment

		# Adjust for difference in water heater supply temperature vs.
		# test hot water supply temperature.
		actual_dw_elec_use_per_cycle = test_dw_elec_use_per_cycle + \
				(test_dw_dhw_temp - wh_setpoint) * \
				test_dw_dhw_use_per_cycle * \
				(water_dens * water_sh * \
				 OpenStudio.convert(1, "Btu", "kWh").get / ft32gal) # kWh/cycle
		daily_energy = actual_dw_elec_use_per_cycle * \
				actual_dw_cycles_per_year / 365 # kWh/day

	else

		# Dishwasher has no internal heater
		daily_energy = actual_dw_elec_use_per_cycle * \
				actual_dw_cycles_per_year / 365 # kWh/day
	
	end
	
	if daily_energy < 0
		runner.registerError("The inputs for the dishwasher resulted in a negative amount of energy consumption.")
		return false
	end
	
	obj_name = Constants.ObjectNameDishwasher
    sch = HotWaterSchedule.new(runner, model, num_br, 0, "DW", obj_name, wh_setpoint)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelElec(daily_energy)
    peak_flow = sch.calcPeakFlow(daily_energy)

	#add dw to the selected space
	has_elec_dw = 0
	replace_dw = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add dw
			space_equipments = spaceType.electricEquipment
			space_equipments.each do |space_equipment|
				if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
					has_elec_dw = 1
					runner.registerWarning("This space already has an dishwasher, the existing dishwasher will be replaced with the the currently selected option")
					space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
					sch.setSchedule(space_equipment)
					replace_dw = 1
				end
			end
            if replace_dw == 1
                # Also update water use equipment
                space_equipments = spaceType.waterUseEquipment
                space_equipments.each do |space_equipment|
                    if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
                        space_equipment.waterUseEquipmentDefinition.setPeakFlowRate(peak_flow)
                        sch.setWaterSchedule(space_equipment)
                    end
                end
            end
			if has_elec_dw == 0 
				has_elec_dw = 1

				#Add electric equipment for the dw
				dw_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
				dw = OpenStudio::Model::ElectricEquipment.new(dw_def)
				dw.setName(obj_name)
				dw.setSpaceType(spaceType)
				dw_def.setName(obj_name)
				dw_def.setDesignLevel(design_level)
				dw_def.setFractionRadiant(dw_rad)
				dw_def.setFractionLatent(dw_lat)
				dw_def.setFractionLost(dw_lost)
				sch.setSchedule(dw)
				
                #Add water use equipment for the dw
				dw_def2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
                dw2 = OpenStudio::Model::WaterUseEquipment.new(dw_def2)
                dw2.setName(obj_name)
                dw2.setSpaceType(spaceType)
                dw_def2.setName(obj_name)
                dw_def2.setPeakFlowRate(peak_flow)
                dw_def2.setEndUseSubcategory("Domestic Hot Water")
				sch.setWaterSchedule(dw2)
                
                #FIXME: Need to have water use connections, plant loop?
                #Code adapted from https://github.com/NREL/OpenStudio/issues/1635
                water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
                water_use_connection.addWaterUseEquipment(dw2)
                plant_loop = OpenStudio::Model::PlantLoop.new(model)
                plant_loop.addDemandBranchForComponent(water_use_connection)
			end
		end
	end

    #reporting final condition of model
	dw_ann = daily_energy * 365
	if has_elec_dw == 1
		if replace_dw == 1
			runner.registerFinalCondition("The existing dishwasher has been replaced by one with #{dw_ann.round} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("A dishwasher has been added with #{dw_ann.round} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Dishwasher was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialDishwasher.new.registerWithApplication