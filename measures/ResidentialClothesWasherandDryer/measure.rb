#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialClothesWasherandDryer < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialClothesWasherandDryer"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for cdss (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Detailed"
	
	selected_cd = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_cd", chs, true)
	selected_cd.setDisplayName("Clothes Dryer Energy Consumption Option")
	args << selected_cd
	
	#make a choice argument for whether gas or electricity is the fuel used by the cd
	chs2 = OpenStudio::StringVector.new
	chs2 << "Gas" 
	chs2 << "Electricity"
	
	cd_fuel = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("cd_fuel", chs2, true)
	cd_fuel.setDisplayName("Clothes Dryer Fuel")
	cd_fuel.setDefaultValue("Electricity")
	args << cd_fuel
	
	#make a double argument for BA Benchamrk multiplier
	bab_mult_cd = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("BAB_mult_cd")
	bab_mult_cd.setDisplayName("Clothes Dryer Building America Benchmark Multipler")
	bab_mult_cd.setDefaultValue(1)
	args << bab_mult_cd
	
	#make an integer argument for number of bedrooms
	num_br = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("Num_Br")
	num_br.setDisplayName("Number of Bedrooms")
	num_br.setDefaultValue(1)
	args << num_br
	
	#make a double argument for Clothes Dryer Energy Factor
	ef_cd = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("EF_cd")
	ef_cd.setDisplayName("Clothes Dryer Energy Factor")
	ef_cd.setDefaultValue(3.1)
	args << ef_cd
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified for the clothes washer
	selected_cw = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_cw", chs, true)
	selected_cw.setDisplayName("Clothes Washer Energy Consumption Option")
	args << selected_cw
	
	#make a double argument for BA Benchamrk multiplier
	bab_mult_cw = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("BAB_mult_cw")
	bab_mult_cw.setDisplayName("Clothes Washer Building America Benchmark Multipler")
	bab_mult_cw.setDefaultValue(1)
	args << bab_mult_cw
	
	#make a double argument for Clothes Washer Energy Factor
	ef_cw = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("EF_cw")
	ef_cw.setDisplayName("Clothes Washer Energy Factor")
	ef_cw.setDefaultValue(1.41)
	args << ef_cw
	
	#make a double argument for Clothes Washer Drum Volume
	dv_cw = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("DV_cw")
	dv_cw.setDisplayName("Clothes Washer Drum Volume (ft^3)")
	dv_cw.setDefaultValue(3.5)
	args << dv_cw
	
	#make an integer argument for clothes washer test date
	cw_td = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("CW_testdate")
	cw_td.setDisplayName("Clothes Washer Test Date")
	cw_td.setDefaultValue(2007)
	args << cw_td
	
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
    space_type.setDisplayName("Select the space where the clothes washer and dryer are located")
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
    selected_cd = runner.getStringArgumentValue("selected_cd",user_arguments)
	cd_fuel = runner.getStringArgumentValue("cd_fuel",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
	bab_mult_cd = runner.getDoubleArgumentValue("BAB_mult_cd",user_arguments)
	num_br = runner.getIntegerArgumentValue("Num_Br", user_arguments)
	ef_cd = runner.getDoubleArgumentValue("EF_cd",user_arguments)
	selected_cw = runner.getStringArgumentValue("selected_cw",user_arguments)
	bab_mult_cw = runner.getDoubleArgumentValue("BAB_mult_cw",user_arguments)
	ef_cw = runner.getDoubleArgumentValue("EF_cw",user_arguments)
	dv_cw = runner.getDoubleArgumentValue("DV_cw",user_arguments)
	cw_td = runner.getIntegerArgumentValue("CW_testdate", user_arguments)
	
	
	#warning if things are specified that will not be used (ie. BAB mult when detailed cd is modeled)
	#Benchmark and other values specified
	if selected_cd == "Benchmark" and ef_cd != 3.1
		runner.registerWarning("Benchmark is specified with a user specified energy factor. This value will not be used")
	end
	
	if selected_cw == "Benchmark" and ef_cw != 1.41
		runner.registerWarning("Benchmark is specified with a user specified energy factor. This value will not be used")
	end
	
	#Detailed but BAB mult or detailed options specified
	
	if selected_cd == "Detailed" and bab_mult_cd != 1
		runner.registerWarning("Detailed is specified with a user specified clothes dryer benchmark multiplier. This value will not be used")
	end
	
	if selected_cw == "Detailed" and bab_mult_cw != 1
		runner.registerWarning("Detailed is specified with a user specified clothes washer benchmark multiplier. This value will not be used")
	end
	
	#BAB and gas
	if selected_cd == "Benchmark" and cd_fuel == "Gas"
		runner.registerWarning("The benchmark clothes dryer always uses electricity as the fuel. An electric clothes dryer will be added to the building instead of a gas dryer.")
		cd_fuel = "Electricity"
	end
	
	#if BAB multiplier is defined, make sure it is positive and nonzero
	if selected_cd == "Benchmark" and bab_mult_cd <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	elsif selected_cw == "Benchamrk" and bab_mult_cw <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	end
	
	#if Energy Factor is defined, make sure it is positive and nonzero
	if ef_cd <= 0 or ef_cw <= 0
		runner.registerError("Energy Factor must be greater than zero, double check inputs")
	end
	
	#if num bedrooms is defined, must be between 1-5
	if selected_cd == "Benchmark" or selected_cd == "Detailed"
		if num_br < 1 or num_br > 5
			runner.registerError("Number of bedrooms must be between 1 and 5 (inclusive)")
		end
	end
	
	if selected_cw == "Detailed" or selected_cd == "Detailed"
		runner.registerError("TODO: revisit after HW measures are written")
	end
		
	
	#Calculate clothes washer daily energy use
	
	if selected_cw == "Benchmark"
		cw_ann_e = bab_mult_cw * (38.8 + 12.9 * num_br)
	else
		cw_cycles_test = 392
		cw_gas_heater_eta = 0.75
		cw_test_load = 4.103003337 * dv_cw + 0.198242492
		if cw_td < 2004
			cw_inlet_t = 140.0
		else
			cw_inlet_t = 135.0
		end
		cw_cold_t = 60.0
		cw_mixed_t = 92.5
		hw_vol_frac = (cw_mixed_t-cw_cold_t)/(cw_inlet_t-cw_cold_t)
	end
	
	cw_daily_e = cw_ann_e/365.0
	
	#Calculate electric cd daily energy use
	
	if selected_cd == "Benchmark"
		cd_ann_e = bab_mult_cd * (538.2 + 179.4 * num_br)
		cd_ann_g = 0
	else
		dryer_red_mc = 0.66
		dryer_use_f = 0.84
		load_adj_f = 0.52
		#TODO: fill this out once the HW measures are in
	end	
	cd_daily_e = cd_ann_e / 365.0
	
	cdval = Process_clothes_dryer.new
	#pull schedule values and gain fractions from sim
	cd_lat_e = cdval.Clothes_d_lat_e
	cd_conv_e = cdval.Clothes_d_conv_e
	cd_lost_e = cdval.Clothes_d_lost_e
	cd_rad_e = cdval.Clothes_d_rad_e

	cd_lat_g = cdval.Clothes_d_lat_g
	cd_conv_g = cdval.Clothes_d_conv_g
	cd_lost_g = cdval.Clothes_d_lost_g
	cd_rad_g = cdval.Clothes_d_rad_g

	cd_lat_e_g = cdval.Clothes_d_lat_e_g
	cd_conv_e_g = cdval.Clothes_d_conv_e_g
	cd_lost_e_g = cdval.Clothes_d_lost_e_g
	cd_rad_e_g = cdval.Clothes_d_rad_e_g
	
	monthly_mult_cd = cdval.Monthly_mult_cd
	weekday_hourly_cd = cdval.Weekday_hourly_cd
	weekend_hourly_cd = cdval.Weekend_hourly_cd
	maxval_cd = cdval.Maxval_cd
	sum_max_cd = cdval.Sum_cd_max
	sch_adjust_cd = 1/sum_max_cd
	
	cwval = Process_clothes_washer.new
	cw_lat = cwval.Clothes_w_lat
	cw_conv = cwval.Clothes_w_conv
	cw_lost = cwval.Clothes_w_lost
	cw_rad = cwval.Clothes_w_rad
	
	monthly_mult_cw = cwval.Monthly_mult_cw
	weekday_hourly_cw = cwval.Weekday_hourly_cw
	weekend_hourly_cw = cwval.Weekend_hourly_cw
	maxval_cw = cwval.Maxval_cw
	sum_max_cw = cwval.Sum_cw_max
	sch_adjust_cw = 1/sum_max_cw
	
	#get cd max power
	if cd_fuel == "Gas"
		cd_max_g = cd_daily_g * maxval_cd * 1000 * sch_adjust_cd * 29.30011
	else
		cd_max_e = cd_daily_e * maxval_cd * 1000 * sch_adjust_cd
	end
	
	cw_max = cw_daily_e * maxval_cw * 1000 * sch_adjust_cw
	
	#add cd to the selected space
	has_elec_cd = 0
	has_gas_cd = 0
	has_cw = 0
	replace_gas_cd = 0
	replace_elec_cd = 0
	replace_cw = 0
	remove_g_cd = 0
	remove_e_cd = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add cd
			space_equipments_g = spaceType.gasEquipment
			space_equipments_g.each do |space_equipment_g| #check for an existing gas cd
				if space_equipment_g.gasEquipmentDefinition.name.get.to_s == "residential_gas_clothes_dryer" and cd_fuel == "Electricity"
					if cd_fuel == "Gas"
						has_gas_cd = 1
						runner.registerWarning("This space already has a gas dryer, multiple clothes dryers are not allowed. The existing gas dryer will be replaced with the specified gas dryer")
						space_equipment.gasEquipmentDefinition.setDesignLevel(cd_max_g)
						replace_gas_cd = 1
					else
						runner.registerWarning("This space already has a gas clothes dryer, multiple dryer are not allowed. The existing gas dryer will be removed and replaced with the specified electric dryer")
						space_equipment_g.remove
						remove_g_cd = 1
					end
				end
			end
			space_equipments_e = spaceType.electricEquipment
			space_equipments_e.each do |space_equipment_e|
				if space_equipment_e.electricEquipmentDefinition.name.get.to_s == "residential_electric_clothes_dryer"
					if cd_fuel == "Gas"
						runner.registerWarning("This space already has an electric clothes dryer, the existing dryer will be replaced with the the currently selected option")
						space_equipment_e.remove
						remove_e_cd = 1
					else
						has_elec_cd = 1
						runner.registerWarning("This space already has an electric clothes dryer, the existing dryer will be replaced with the the currently selected option")
						space_equipment_e.electricEquipmentDefinition.setDesignLevel(cd_max_e)
						replace_elec_cd = 1
					end
				elsif space_equipment_e.electricEquipmentDefinition.name.get.to_s == "gas_dryer_electricity"
					if cd_fuel == "Electricity"
						space_equipment_e.remove
					elsif cd_fuel == "Gas"
						space_equipment.electricEquipmentDefinition.setDesignLevel(cd_max_elec) #TODO: fix this once gas dryers are implemented
					else
						space_equipment_e.remove
					end
				elsif space_equipment_e.electricEquipmentDefinition.name.get.to_s == "residential_clothes_washer"
					has_cw = 1
					runner.registerWarning("This space already has a clothes washer, the existing washer will be replaced with the the currently selected option")
					space_equipment_e.electricEquipmentDefinition.setDesignLevel(cw_max)
					replace_cw = 1
				end
			end
			
			if (has_elec_cd == 0 and cd_fuel == "Electricity") or (has_gas_cd == 0 and cd_fuel == "Gas")
				#add cd schedule
				if cd_fuel == "Gas"
					has_gas_cd = 1
				else
					has_elec_cd = 1
				end
				cd_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				cd_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				cd_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_cd_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_cd_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				cd_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				cd_ruleset.setName("clothes_dryer_annual_schedule")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_cd_rule[m] = OpenStudio::Model::ScheduleRule.new(cd_ruleset)
							wkdy_cd_rule[m].setName("clothes_dryer_weekday_ruleset#{m}")
							wkdy_cd_rule
							cd_wkdy[m] = wkdy_cd_rule[m].daySchedule
							cd_wkdy[m].setName("ClothesDryerWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult_cd[m-1].to_f*weekday_hourly_cd[h-1].to_f)/maxval_cd
								cd_wkdy[m].addValue(time[h],val)
							end
							wkdy_cd_rule[m].setApplySunday(false)
							wkdy_cd_rule[m].setApplyMonday(true)
							wkdy_cd_rule[m].setApplyTuesday(true)
							wkdy_cd_rule[m].setApplyWednesday(true)
							wkdy_cd_rule[m].setApplyThursday(true)
							wkdy_cd_rule[m].setApplyFriday(true)
							wkdy_cd_rule[m].setApplySaturday(false)
							wkdy_cd_rule[m].setStartDate(date_s)
							wkdy_cd_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_cd_rule[m] = OpenStudio::Model::ScheduleRule.new(cd_ruleset)
							wknd_cd_rule[m].setName("cd_weekend_ruleset#{m}")
							cd_wknd[m] = wknd_cd_rule[m].daySchedule
							cd_wknd[m].setName("ClothesDryerWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult_cd[m-1].to_f*weekend_hourly_cd[h-1].to_f)/maxval_cd
								cd_wknd[m].addValue(time[h],val)
							end
							wknd_cd_rule[m].setApplySunday(true)
							wknd_cd_rule[m].setApplyMonday(false)
							wknd_cd_rule[m].setApplyTuesday(false)
							wknd_cd_rule[m].setApplyWednesday(false)
							wknd_cd_rule[m].setApplyThursday(false)
							wknd_cd_rule[m].setApplyFriday(false)
							wknd_cd_rule[m].setApplySaturday(true)
							wknd_cd_rule[m].setStartDate(date_s)
							wknd_cd_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = cd_wkdy[6]
				sumDesSch.setName("cdSummer")
				winDesSch = cd_wkdy[1]
				winDesSch.setName("cdWinter")
				cd_ruleset.setSummerDesignDaySchedule(sumDesSch)
				cd_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add equipment for the cd
				if cd_fuel == "Gas"
					cd_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
					cd = OpenStudio::Model::GasEquipment.new(cd_def)
					cd.setName("residential_gas_cd")
					cd.setSpaceType(spaceType)
					cd_def.setName("residential_gas_cd")
					cd_def.setDesignLevel(cd_max_g)
					cd_def.setFractionRadiant(cd_rad_g)
					cd_def.setFractionLatent(cd_lat_g)
					cd_def.setFractionLost(cd_lost_g)
					cd.setSchedule(cd_ruleset)
					
					cd_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
					cd = OpenStudio::Model::ElectricEquipment.new(cd_def)
					cd.setName("gas_dryer_electricity")
					cd.setSpaceType(spaceType)
					cd_def.setName("gas_dryer_electricity")
					cd_def.setDesignLevel(cd_max_e_g)
					cd_def.setFractionRadiant(cd_rad_e_g)
					cd_def.setFractionLatent(cd_lat_e_g)
					cd_def.setFractionLost(cd_lost_e_g)
					cd.setSchedule(cd_ruleset)

				else
					cd_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
					cd = OpenStudio::Model::ElectricEquipment.new(cd_def)
					cd.setName("residential_electric_clothes_dryer")
					cd.setSpaceType(spaceType)
					cd_def.setName("residential_electric_clothes_dryer")
					cd_def.setDesignLevel(cd_max_e)
					cd_def.setFractionRadiant(cd_rad_e)
					cd_def.setFractionLatent(cd_lat_e)
					cd_def.setFractionLost(cd_lost_e)
					cd.setSchedule(cd_ruleset)
				end		
			end
			
			if has_cw == 0 
				#add cw schedule
				has_cw = 1
				cw_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				cw_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				cw_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_cw_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_cw_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				cw_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				cw_ruleset.setName("clothes_washer_annual_schedule")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_cw_rule[m] = OpenStudio::Model::ScheduleRule.new(cw_ruleset)
							wkdy_cw_rule[m].setName("clothes_washer_weekday_ruleset#{m}")
							wkdy_cw_rule
							cw_wkdy[m] = wkdy_cw_rule[m].daySchedule
							cw_wkdy[m].setName("ClothesWasherWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult_cw[m-1].to_f*weekday_hourly_cw[h-1].to_f)/maxval_cw
								cw_wkdy[m].addValue(time[h],val)
							end
							wkdy_cw_rule[m].setApplySunday(false)
							wkdy_cw_rule[m].setApplyMonday(true)
							wkdy_cw_rule[m].setApplyTuesday(true)
							wkdy_cw_rule[m].setApplyWednesday(true)
							wkdy_cw_rule[m].setApplyThursday(true)
							wkdy_cw_rule[m].setApplyFriday(true)
							wkdy_cw_rule[m].setApplySaturday(false)
							wkdy_cw_rule[m].setStartDate(date_s)
							wkdy_cw_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_cw_rule[m] = OpenStudio::Model::ScheduleRule.new(cw_ruleset)
							wknd_cw_rule[m].setName("clothes_washer_weekend_ruleset#{m}")
							cw_wknd[m] = wknd_cw_rule[m].daySchedule
							cw_wknd[m].setName("ClothesWasherWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult_cw[m-1].to_f*weekend_hourly_cw[h-1].to_f)/maxval_cw
								cw_wknd[m].addValue(time[h],val)
							end
							wknd_cw_rule[m].setApplySunday(true)
							wknd_cw_rule[m].setApplyMonday(false)
							wknd_cw_rule[m].setApplyTuesday(false)
							wknd_cw_rule[m].setApplyWednesday(false)
							wknd_cw_rule[m].setApplyThursday(false)
							wknd_cw_rule[m].setApplyFriday(false)
							wknd_cw_rule[m].setApplySaturday(true)
							wknd_cw_rule[m].setStartDate(date_s)
							wknd_cw_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = cw_wkdy[6]
				sumDesSch.setName("cwSummer")
				winDesSch = cw_wkdy[1]
				winDesSch.setName("cwWinter")
				cw_ruleset.setSummerDesignDaySchedule(sumDesSch)
				cw_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add equipment for the cw
				cw_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
				cw = OpenStudio::Model::ElectricEquipment.new(cw_def)
				cw.setName("residential_clothes_washer")
				cw.setSpaceType(spaceType)
				cw_def.setName("residential_clothes_washer")
				cw_def.setDesignLevel(cw_max)
				cw_def.setFractionRadiant(cw_rad)
				cw_def.setFractionLatent(cw_lat)
				cw_def.setFractionLost(cw_lost)
				cw.setSchedule(cw_ruleset)	
			end
		end
	end
	
	if (has_elec_cd == 1 or has_gas_cd == 0) and has_cw == 0
		runner.registerError("Homes with a clothes dryer must have a clothes washer")
	end

	#reporting final condition of model
	if has_elec_cd == 1 and has_cw == 1
		if replace_elec_cd == 1 and replace_cw == 1
			runner.registerFinalCondition("The existing clothes washer and dryer has been replaced by ones with #{cd_ann_e.round} and #{cw_ann_e.round} kWh annual energy consumption respectively.")
		elsif remove_g_cd == 1 and replace_cw == 1
			runner.registerFinalCondition("The existing gas dryer and clothes washer have been replaced by ones with #{cd_ann_e.round} and #{cw_ann_e.round}kWh annual energy consumption respectively.")
		else
			runner.registerFinalCondition("A clothes dryer and washer have been added with #{cd_ann_e.round} and #{cw_ann_e.round} kWh annual energy consumption respectively.")
		end
	elsif has_gas_cd == 1 and has cw == 1
		if replace_gas_cd == 1 and replace_cw == 1
			runner.registerFinalCondition("The existing gas clothes dryer has been replaced by one with #{cd_ann_g.round} therm and #{cd_ann_e_g.round} kWh annual energy consumption. The washer was replaced by one with #{cw_ann_e.round} kWh annual energy consumption")
		elsif remove_g_cd == 1 and has_cw == 1
			runner.registerFinalCondition("The existing gas cd has been replaced by one with #{cd_ann_g.round} therm and #{cd_ann_e_g.round} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("A gas dryer has been added with #{cd_ann_g.round} therm and #{cd_ann_e_g.round} kWh annual energy consumption. A clothes washer has been added with #{cw_ann_e} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("No washer or dryer were not added.")
	end
	
    return true
	
	end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesWasherandDryer.new.registerWithApplication