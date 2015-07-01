#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialCookingRange < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialCookingRange"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for rangess (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Detailed"
	chs << "Simple"
	
	selected_range = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_range", chs, true)
	selected_range.setDisplayName("Cooking Range Energy Consumption Option")
	args << selected_range
	
	#make a choice argument for whether gas or electricity is the fuel used by the range
	chs2 = OpenStudio::StringVector.new
	chs2 << "Gas" 
	chs2 << "Electricity"
	
	range_fuel = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("range_fuel", chs2, true)
	range_fuel.setDisplayName("Cooking Range Fuel")
	range_fuel.setDefaultValue(false)
	args << range_fuel
	
	#make a double argument for user defined range options
	range_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("range_E",true)
	range_E.setDisplayName("Simple Range Annual Energy Consumption (kWh/yr or therms/yr)")
	range_E.setDefaultValue(0)
	args << range_E
	
	#make a double argument for BA Benchamrk multiplier
	bab_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("BAB_mult")
	bab_mult.setDisplayName("Building America Benchmark Multipler")
	bab_mult.setDefaultValue(1)
	args << bab_mult
	
	#make an integer argument for number of bedrooms
	num_br = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("Num_Br")
	num_br.setDisplayName("Number of Bedrooms")
	num_br.setDefaultValue(1)
	args << num_br
	
	#make a double argument for oven EF
	o_ef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("O_ef")
	o_ef.setDisplayName("Oven Energy Factor")
	o_ef.setDefaultValue(0)
	args << o_ef
	
	#make a double argument for cooktop EF
	c_ef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("C_ef")
	c_ef.setDisplayName("Cooktop Energy Factor")
	c_ef.setDefaultValue(0)
	args << c_ef
	
	#make a boolean argument for has glo bar
	glo_bar = OpenStudio::Ruleset::OSArgument::makeBoolArgument("Glo_Bar")
	glo_bar.setDisplayName("Has glo bar ignition")
	glo_bar.setDefaultValue(0)
	args << glo_bar
	
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
    space_type.setDisplayName("Select the space where the cooking range is located")
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
    selected_range = runner.getStringArgumentValue("selected_range",user_arguments)
	range_fuel = runner.getStringArgumentValue("range_fuel",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
    range_E = runner.getDoubleArgumentValue("range_E",user_arguments)
	bab_mult = runner.getDoubleArgumentValue("BAB_mult",user_arguments)
	num_br = runner.getIntegerArgumentValue("Num_Br", user_arguments)
	glo_bar = runner.getBoolArgumentValue("Glo_Bar",user_arguments)
	o_ef = runner.getDoubleArgumentValue("O_ef",user_arguments)
	c_ef = runner.getDoubleArgumentValue("C_ef",user_arguments)
	
	#warning if things are specified that will not be used (ie. BAB mult when detailed range is modeled)
	#Benchmark and other values specified
	if selected_range == "Benchmark" and range_E != 0
		runner.registerWarning("Benchmark is specified with a non-zero range energy. This value will not be used")
	elsif selected_range == "Benchmark" and num_br != 1
		runner.registerWarning("Benchmark is specified with a user specified number of bedrooms. This value will not be used")
	elsif selected_range == "Benchmark" and o_ef != 0
		runner.registerWarning("Benchmark is specified with a user specified oven energy factor. This value will not be used")
	elsif selected_range == "Benchmark" and o_ef != 0
		runner.registerWarning("Benchmark is specified with a user specified cooktop energy factor. This value will not be used")
	end
	
	#Simple but BAB mult or detailed options specified
	
	if selected_range == "Simple" and bab_mult != 1
		runner.registerWarning("Simple is specified with a user specified benchmark multiplier. This value will not be used")
	elsif selected_range == "Simple" and o_ef != 0
		runner.registerWarning("Simple is specified with a user specified oven energy factor. This value will not be used")
	elsif selected_range == "Simple" and c_ef != 0
		runner.registerWarning("Simple is specified with a user specified cooktop energy factor. This value will not be used")
	end
	
	#Detailed but BAB mult or simple
	
	if selected_range == "Detailed" and bab_mult != 1
		runner.registerWarning("Detailed is specified with a user specified benchmark multiplier. This value will not be used")
	elsif selected_range == "Detailed" and range_E != 0
		runner.registerWarning("Simple is specified with a user specified number of bedrooms. This value will not be used")
	elsif selected_range == "Simple" and o_ef != 0
		runner.registerWarning("Simple is specified with a user specified oven energy factor. This value will not be used")
	elsif selected_range == "Simple" and c_ef != 0
		runner.registerWarning("Simple is specified with a user specified cooktop energy factor. This value will not be used")
	end
	
	#BAB and gas
	if selected_range == "Benchmark" and range_fuel == "Gas"
		runner.registerWarning("The benchmark range always uses electricity as the fuel. An electric range will be added to the building instead of a gas range.")
		range_fuel = "Electricity"
	end
	
	#Glo bar and elec
	if range_fuel == "Electricity" and glo_bar == true
		runner.registerWarning("Glo bars are only used in gas ovens, the glo bar energy use will not be simulated")
	end
	
	#if range energy consumption is defined, check for reasonable energy consumption
	if selected_range == "Simple" 
		if range_E < 0
			runner.registerError("Electric range energy consumption must be greater than 0")
		elsif range_E < 100 and range_fuel == "Electricity"
			runner.registerError("Electric range energy consumption seems low, double check inputs") 
		elsif range_E > 3000 and range_fuel == "Electricity"
			runner.registerError("Electric range energy consumption seems high, double check inputs") 
		elsif range_E > 200 and range_fuel == "Gas"
			runner.registerError("Gas range energy consumption seems high, double check inputs")
		end
	end
	
	#if BAB multiplier is defined, make sure it is positive and nonzero
	if selected_range == "Benchmark" and bab_mult <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	end
	
	#if num bedrooms is defined, must be between 1-5
	if selected_range == "Benchmark" or selected_range == "Detailed"
		if num_br < 1 or num_br > 5
			runner.registerError("Number of bedrooms must be between 1 and 5 (inclusive)")
		end
	end
	
	#if oef or cef is defined, must be > 0 and < 1
	#TODO: is 1 the upper limit?
	if selected_range == "Detailed"
		if o_ef < 0 or o_ef > 1
			runner.registerError("Oven energy factor must be greater than zero and less than one")
		elsif c_ef < 0 or c_ef > 1
			runner.registerError("Cooktop energy factor must be greater than zero and less than one")
		end
	end
	
	#Calculate electric range daily energy use
	
	if range_fuel == "Electricity"
		if selected_range == "Simple"
			range_ann_e = range_E
		elsif selected_range == "Benchmark"
			range_ann_e = ((250 + 83 * num_br) * bab_mult)
		elsif selected_range == "Detailed"
			range_ann_e = ((86.5 + 28.9 * num_br) / c_ef + (14.6 + 4.9 * num_br) / o_ef)
		end
		
		range_daily_e = range_ann_e / 365.0
		
	else
		if selected_range == "Simple"
			range_ann_g = range_E
		elsif selected_range == "Detailed"
			range_ann_g = ((2.64 + 0.88 * num_br) / c_ef + (0.44 + 0.15 * num_br) / o_ef) # therm/yr
		end
		
		range_daily_g = range_ann_g / 365.0
		
		if glo_bar == true
			range_ann_globar = 40 +13.3 * num_br #kWh/yr
			range_daily_globar = range_ann_globar / 365.0
		end
	end
	
	rangeval = Process_range.new
	#pull schedule values and gain fractions from sim
	range_lat_e = rangeval.Range_lat_elec
	range_conv_e = rangeval.Range_conv_elec
	range_lost_e = rangeval.Range_lost_elec
	range_rad_e = rangeval.Range_rad_elec

	range_lat_g = rangeval.Range_lat_gas
	range_conv_g = rangeval.Range_conv_gas
	range_lost_g = rangeval.Range_lost_gas
	range_rad_g = rangeval.Range_rad_gas

	monthly_mult = rangeval.Monthly_mult_range
	weekday_hourly = rangeval.Weekday_hourly_range
	weekend_hourly = rangeval.Weekend_hourly_range
	maxval = rangeval.Maxval_range
	sum_max = rangeval.Sum_range_max
	sch_adjust = 1/sum_max
	
	#get range max power
	if range_fuel == "Gas"
		range_max_g = range_daily_g * maxval * 1000 * sch_adjust * 29.30011
		if glo_bar == true
			range_max_globar = range_daily_globar * maxval * 1000 * sch_adjust
		end
	else
		range_max_e = range_daily_e * maxval * 1000 * sch_adjust
	end
	
	#add range to the selected space
	has_elec_range = 0
	has_gas_range = 0
	replace_gas_range = 0
	replace_elec_range = 0
	remove_g_range = 0
	remove_e_range = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add range
			space_equipments_g = spaceType.gasEquipment
			space_equipments_g.each do |space_equipment_g| #check for an existing gas range
				if space_equipment_g.gasEquipmentDefinition.name.get.to_s == "residential_gas_range" and range_fuel == "Electricity"
					if range_fuel == "Gas"
						has_gas_range = 1
						runner.registerWarning("This space already has a gas range, multiple ranges are not allowed. The existing gas range will be replaced with the specified gas range")
						space_equipment.gasEquipmentDefinition.setDesignLevel(range_max_g)
						replace_gas_range = 1
					else
						runner.registerWarning("This space already has a gas range, multiple ranges are not allowed. The existing gas range will be removed and replaced with the specified electric range")
						space_equipment_g.remove
						remove_g_range = 1
					end
				end
			end
			space_equipments_e = spaceType.electricEquipment
			space_equipments_e.each do |space_equipment_e|
				if space_equipment_e.electricEquipmentDefinition.name.get.to_s == "residential_electric_range"
					if range_fuel == "Gas"
						runner.registerWarning("This space already has an electric range, the existing range will be replaced with the the currently selected option")
						space_equipment_e.remove
						remove_e_range = 1
					else
						has_elec_range = 1
						runner.registerWarning("This space already has an electric range, the existing range will be replaced with the the currently selected option")
						space_equipment.electricEquipmentDefinition.setDesignLevel(range_max_e)
						replace_elec_range = 1
					end
				elsif space_equipment_e.electricEquipmentDefinition.name.get.to_s == "range_glo_bar"
					if range_fuel == "Electricity"
						space_equipment_e.remove
					elsif glo_bar == true and range_fuel == "Gas"
						space_equipment.electricEquipmentDefinition.setDesignLevel(range_max_globar)
					else
						space_equipment_e.remove
					end
				end
			end
			
			if (has_elec_range == 0 and range_fuel == "Electricity") or (has_gas_range == 0 and range_fuel == "Gas")
				#add range schedule
				if range_fuel == "Gas"
					has_gas_range = 1
				else
					has_elec_range = 1
				end
				range_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				range_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				range_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_range_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_range_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				range_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				range_ruleset.setName("Range_annual_schedule")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_range_rule[m] = OpenStudio::Model::ScheduleRule.new(range_ruleset)
							wkdy_range_rule[m].setName("range_weekday_ruleset#{m}")
							wkdy_range_rule
							range_wkdy[m] = wkdy_range_rule[m].daySchedule
							range_wkdy[m].setName("RangeWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekday_hourly[h-1].to_f)/maxval
								range_wkdy[m].addValue(time[h],val)
							end
							wkdy_range_rule[m].setApplySunday(false)
							wkdy_range_rule[m].setApplyMonday(true)
							wkdy_range_rule[m].setApplyTuesday(true)
							wkdy_range_rule[m].setApplyWednesday(true)
							wkdy_range_rule[m].setApplyThursday(true)
							wkdy_range_rule[m].setApplyFriday(true)
							wkdy_range_rule[m].setApplySaturday(false)
							wkdy_range_rule[m].setStartDate(date_s)
							wkdy_range_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_range_rule[m] = OpenStudio::Model::ScheduleRule.new(range_ruleset)
							wknd_range_rule[m].setName("range_weekend_ruleset#{m}")
							range_wknd[m] = wknd_range_rule[m].daySchedule
							range_wknd[m].setName("RangeWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekend_hourly[h-1].to_f)/maxval
								range_wknd[m].addValue(time[h],val)
							end
							wknd_range_rule[m].setApplySunday(true)
							wknd_range_rule[m].setApplyMonday(false)
							wknd_range_rule[m].setApplyTuesday(false)
							wknd_range_rule[m].setApplyWednesday(false)
							wknd_range_rule[m].setApplyThursday(false)
							wknd_range_rule[m].setApplyFriday(false)
							wknd_range_rule[m].setApplySaturday(true)
							wknd_range_rule[m].setStartDate(date_s)
							wknd_range_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = range_wkdy[6]
				sumDesSch.setName("RangeSummer")
				winDesSch = range_wkdy[1]
				winDesSch.setName("RangeWinter")
				range_ruleset.setSummerDesignDaySchedule(sumDesSch)
				range_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add equipment for the range
				if range_fuel == "Gas"
					rng_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
					rng = OpenStudio::Model::GasEquipment.new(rng_def)
					rng.setName("residential_gas_range")
					rng.setSpaceType(spaceType)
					rng_def.setName("residential_gas_range")
					rng_def.setDesignLevel(range_max_g)
					rng_def.setFractionRadiant(range_rad_g)
					rng_def.setFractionLatent(range_lat_g)
					rng_def.setFractionLost(range_lost_g)
					rng.setSchedule(range_ruleset)
					if glo_bar == true
						rng_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
						rng = OpenStudio::Model::ElectricEquipment.new(rng_def)
						rng.setName("range_glo_bar")
						rng.setSpaceType(spaceType)
						rng_def.setName("range_glo_bar")
						rng_def.setDesignLevel(range_max_globar)
						rng_def.setFractionRadiant(range_rad_e)
						rng_def.setFractionLatent(range_lat_e)
						rng_def.setFractionLost(range_lost_e)
						rng.setSchedule(range_ruleset)
					end

				else
					rng_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
					rng = OpenStudio::Model::ElectricEquipment.new(rng_def)
					rng.setName("residential_electric_range")
					rng.setSpaceType(spaceType)
					rng_def.setName("residential_electric_range")
					rng_def.setDesignLevel(range_max_e)
					rng_def.setFractionRadiant(range_rad_e)
					rng_def.setFractionLatent(range_lat_e)
					rng_def.setFractionLost(range_lost_e)
					rng.setSchedule(range_ruleset)
				end		
			end
		end
	end

    #reporting final condition of model
	if has_elec_range == 1
		if replace_elec_range == 1
			runner.registerFinalCondition("The existing electric range has been replaced by one with #{range_ann_e.round} kWh annual energy consumption.")
		elsif remove_g_range == 1
			runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_e.round} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("An electric range has been added with #{range_ann_e.round} kWh annual energy consumption.")
		end
	elsif has_gas_range == 1
		if replace_gas_range == 1
			if glo_bar == true
				runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_g.round} therm and #{range_ann_globar.round} kWh annual energy consumption.")
			else
				runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_g.round} therm annual energy consumption.")
			end
		elsif remove_g_range == 1
			if glo_bar == true
				runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_g.round} therm and #{range_ann_globar.round} kWh annual energy consumption.")
			else
				runner.registerFinalCondition("The existing gas range has been replaced by one with #{range_ann_g.round} therm annual energy consumption.")
			end
		else
			if glo_bar == true
				runner.registerFinalCondition("A gas range has been added with #{range_ann_g.round} therm and #{range_ann_globar.round} kWh annual energy consumption.")
			else
				runner.registerFinalCondition("A gas range has been added with #{range_ann_g.round} therm annual energy consumption.")
			end
		end
	else
		runner.registerFinalCondition("No range was not added.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialCookingRange.new.registerWithApplication