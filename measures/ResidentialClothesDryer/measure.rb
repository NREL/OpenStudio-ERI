require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class ResidentialClothesDryer < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Electric Clothes Dryer"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for cdss (alternate schedules if automatic DR control is specified)

	#make a double argument for Energy Factor
	cd_ef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cd_ef",true)
	cd_ef.setDisplayName("Energy Factor")
    cd_ef.setDescription("The Energy Factor, for electric or gas systems.")
	cd_ef.setDefaultValue(3.1)
    cd_ef.setUnits("lb/kWh")
	args << cd_ef
    
	#make a double argument for occupancy energy multiplier
	cd_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cd_mult",true)
	cd_mult.setDisplayName("Occupancy Energy Multiplier")
    cd_mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	cd_mult.setDefaultValue(1)
	args << cd_mult

   	#Make a string argument for 24 weekday schedule values
	cd_weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("cd_weekday_sch")
	cd_weekday_sch.setDisplayName("Weekday schedule")
	cd_weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	cd_weekday_sch.setDefaultValue("0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024")
	args << cd_weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	cd_weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("cd_weekend_sch")
	cd_weekend_sch.setDisplayName("Weekend schedule")
	cd_weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	cd_weekend_sch.setDefaultValue("0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024")
	args << cd_weekend_sch

  	#Make a string argument for 12 monthly schedule values
	cd_monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("cd_monthly_sch", true)
	cd_monthly_sch.setDisplayName("Month schedule")
	cd_monthly_sch.setDescription("Specify the 12-month schedule.")
	cd_monthly_sch.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
	args << cd_monthly_sch

	#make a double argument for Clothes Washer Modified Energy Factor
	cw_mef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_mef",true)
	cw_mef.setDisplayName("Clothes Washer Energy Factor")
    cw_mef.setUnits("ft^3/kWh-cycle")
    cw_mef.setDescription("The Modified Energy Factor (MEF) is the quotient of the capacity of the clothes container, C, divided by the total clothes washer energy consumption per cycle, with such energy consumption expressed as the sum of the machine electrical energy consumption, M, the hot water energy consumption, E, and the energy required for removal of the remaining moisture in the wash load, D. The higher the value, the more efficient the clothes washer is. Procedures to test MEF are defined by the Department of Energy (DOE) in 10 Code of Federal Regulations Part 430, Appendix J to Subpart B.")
	cw_mef.setDefaultValue(1.41)
	args << cw_mef
    
    #make a double argument for Clothes Washer Rated Annual Consumption
    cw_rated_annual_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_rated_annual_energy",true)
	cw_rated_annual_energy.setDisplayName("Clothes Washer Rated Annual Consumption")
    cw_rated_annual_energy.setUnits("kWh")
    cw_rated_annual_energy.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
	cw_rated_annual_energy.setDefaultValue(387.0)
	args << cw_rated_annual_energy
    
	#make a double argument for Clothes Washer Drum Volume
	cw_drum_volume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_drum_volume",true)
	cw_drum_volume.setDisplayName("Clothes Washer Drum Volume")
    cw_drum_volume.setUnits("ft^3")
    cw_drum_volume.setDescription("Volume of the washer drum.  Obtained from the EnergyStar website or the manufacturer's literature.")
	cw_drum_volume.setDefaultValue(3.5)
	args << cw_drum_volume
    
	#make a choice argument for which zone to put the space in
	#make a choice argument for model objects
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
    space_type.setDisplayName("Location")
    space_type.setDescription("Select the space type where the clothes washer and dryer are located")
    space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << space_type
    
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
	cd_ef = runner.getDoubleArgumentValue("cd_ef",user_arguments)
	cd_mult = runner.getDoubleArgumentValue("cd_mult",user_arguments)
	cd_weekday_sch = runner.getStringArgumentValue("cd_weekday_sch",user_arguments)
	cd_weekend_sch = runner.getStringArgumentValue("cd_weekend_sch",user_arguments)
    cd_monthly_sch = runner.getStringArgumentValue("cd_monthly_sch",user_arguments)
	cw_mef = runner.getDoubleArgumentValue("cw_mef",user_arguments)
    cw_rated_annual_energy = runner.getDoubleArgumentValue("cw_rated_annual_energy",user_arguments)
	cw_drum_volume = runner.getDoubleArgumentValue("cw_drum_volume",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)

    # Get number of bedrooms/bathrooms
    nbeds, nbaths = HelperMethods.get_bedrooms_bathrooms(model, space_type_r, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end

    #Check for valid inputs
	if cd_ef <= 0
		runner.registerError("Energy factor must be greater than 0.0.")
        return false
	end
	if cd_mult < 0
		runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.0.")
        return false
    end
    if cw_mef <= 0
        runner.registerError("Clothes washer modified energy factor must be greater than 0.0.")
        return false
    end
    if cw_rated_annual_energy <= 0
        runner.registerError("Clothes washer rated annual consumption must be greater than 0.0.")
        return false
    end
    if cw_drum_volume <= 0
        runner.registerError("Clothes washer drum volume must be greater than 0.0.")
        return false
    end

	
    #hard coded convective, radiative, latent, and lost fractions for clothes dryer
	cd_lat_e = 0.05
	cd_rad_e = 0.09
	cd_conv_e = 0.06
	cd_lost_e = 1 - cd_lat_e - cd_rad_e - cd_conv_e

    # Energy Use is based on "Method for Evaluating Energy Use of Dishwashers, Clothes 
    # Washers, and Clothes Dryers" by Eastment and Hendron, Conference Paper NREL/CP-550-39769, 
    # August 2006. Their paper is in part based on the energy use calculations presented in the 
    # 10CFR Part 430, Subpt. B, App. D (DOE 1999),
    # http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl
    # Eastment and Hendron present a method for estimating the energy consumption per cycle 
    # based on the dryer's energy factor.

    # Set some intermediate variables. An experimentally determined value for the percent 
    # reduction in the moisture content of the test load, expressed here as a fraction 
    # (DOE 10CFR Part 430, Subpt. B, App. D, Section 4.1)
    dryer_nominal_reduction_in_moisture_content = 0.66
    # The fraction of washer loads dried in a clothes dryer (DOE 10CFR Part 430, Subpt. B, 
    # App. J1, Section 4.3)
    dryer_usage_factor = 0.84
    load_adjustment_factor = 0.52

    # Set the number of cycles per year for test conditions
    cw_cycles_per_year_test = 392 # (see Eastment and Hendron, NREL/CP-550-39769, 2006)

    # Calculate test load weight (correlation based on data in Table 5.1 of 10CFR Part 430,
    # Subpt. B, App. J1, DOE 1999)
    cw_test_load = 4.103003337 * cw_drum_volume + 0.198242492 # lb

    # Eq. 10 of Eastment and Hendron, NREL/CP-550-39769, 2006.
    dryer_energy_factor_std = 0.5 # Nominal drying energy required, kWh/lb dry cloth
    dryer_elec_per_year = (cw_cycles_per_year_test * cw_drum_volume / cw_mef - 
                          cw_rated_annual_energy) # kWh
    dryer_elec_per_cycle = dryer_elec_per_year / cw_cycles_per_year_test # kWh
    remaining_moisture_after_spin = (dryer_elec_per_cycle / (load_adjustment_factor * 
                                    dryer_energy_factor_std * dryer_usage_factor * 
                                    cw_test_load) + 0.04) # lb water/lb dry cloth
    cw_remaining_water = cw_test_load * remaining_moisture_after_spin

    # Use the dryer energy factor and remaining water from the clothes washer to calculate 
    # total energy use per cycle (eq. 7 Eastment and Hendron, NREL/CP-550-39769, 2006).
    actual_cd_energy_use_per_cycle = (cw_remaining_water / (cd_ef *
                                     dryer_nominal_reduction_in_moisture_content)) # kWh/cycle
                                     
    # All energy use is electric.
    actual_cd_elec_use_per_cycle = actual_cd_energy_use_per_cycle # kWh/cycle

    # (eq. 14 Eastment and Hendron, NREL/CP-550-39769, 2006)
    actual_cw_cycles_per_year = (cw_cycles_per_year_test * (0.5 + nbeds / 6) * 
                                (12.5 / cw_test_load)) # cycles/year

    # eq. 15 of Eastment and Hendron, NREL/CP-550-39769, 2006
    actual_cd_cycles_per_year = dryer_usage_factor * actual_cw_cycles_per_year # cycles/year
    
    daily_energy_elec = actual_cd_cycles_per_year * actual_cd_elec_use_per_cycle / 365 # kWh/day
    
    daily_energy_elec = daily_energy_elec * cd_mult

    cd_ann_e = daily_energy_elec * 365.0 # kWh/yr

    mult_vacation = 0
    mult_non_vacation = 1.04
    mult_weekend = 1.15 * mult_non_vacation
    mult_weekday = 0.94 * mult_non_vacation

    obj_name = Constants.ObjectNameClothesDryer
    obj_name_e = Constants.ObjectNameClothesDryer + "_" + Constants.FuelTypeElectric
    obj_name_g = Constants.ObjectNameClothesDryer + "_" + Constants.FuelTypeGas
    obj_name_g_e = Constants.ObjectNameClothesDryer + "_" + Constants.FuelTypeGas + "_electricity"
	sch = MonthHourSchedule.new(cd_weekday_sch, cd_weekend_sch, cd_monthly_sch, model, obj_name, runner,
                                mult_weekday, mult_weekend)
	if not sch.validated?
		return false
	end
	design_level_e = sch.calcDesignLevelElec(daily_energy_elec)

	#add cd to the selected space
	has_elec_cd = 0
	replace_elec_cd = 0
	remove_g_cd = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add cd
			space_equipments_g = spaceType.gasEquipment
			space_equipments_g.each do |space_equipment_g| #check for an existing gas cd
				if space_equipment_g.gasEquipmentDefinition.name.get.to_s == cd_obj_name_g
                    runner.registerWarning("This space already has a gas dryer. The existing gas dryer will be removed and replaced with the specified electric dryer.")
                    space_equipment_g.remove
                    remove_g_cd = 1
				end
			end
			space_equipments_e = spaceType.electricEquipment
			space_equipments_e.each do |space_equipment_e|
				if space_equipment_e.electricEquipmentDefinition.name.get.to_s == obj_name_e
                    has_elec_cd = 1
                    runner.registerWarning("This space already has an electric dryer. The existing dryer will be replaced with the the currently selected option.")
                    space_equipment_e.electricEquipmentDefinition.setDesignLevel(design_level_e)
                    sch.setSchedule(space_equipment_e)
                    replace_elec_cd = 1
				elsif space_equipment_e.electricEquipmentDefinition.name.get.to_s == obj_name_g_e
                    space_equipment_e.remove
				end
			end
			
			if has_elec_cd == 0
				has_elec_cd = 1
					
                cd_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
                cd = OpenStudio::Model::ElectricEquipment.new(cd_def)
                cd.setName(obj_name_e)
                cd.setSpaceType(spaceType)
                cd_def.setName(obj_name_e)
                cd_def.setDesignLevel(design_level_e)
                cd_def.setFractionRadiant(cd_rad_e)
                cd_def.setFractionLatent(cd_lat_e)
                cd_def.setFractionLost(cd_lost_e)
                sch.setSchedule(cd)
			end
			
		end
	end
	
	#reporting final condition of model
	if has_elec_cd == 1
		if replace_elec_cd == 1
			runner.registerFinalCondition("The existing electric dryer has been replaced by one with #{cd_ann_e.round} kWhs annual energy consumption.")
		elsif remove_g_cd == 1
			runner.registerFinalCondition("The existing gas dryer has been replaced by an electric dryer with #{cd_ann_e.round} kWhs annual energy consumption.")
		else
			runner.registerFinalCondition("An electric dryer has been added with #{cd_ann_e.round} kWhs annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Dryer was not added to #{space_type_r}.")
    end
	
    return true
	
  end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesDryer.new.registerWithApplication