#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialDishwasher < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialDishwasher"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for dws (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Simple"
	
	selected_dw = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_dw", chs, true)
	selected_dw.setDisplayName("Dishwasher Energy Consumption Option")
	args << selected_dw
	
	#make a double argument for user defined dw options
	dw_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("dw_E",true)
	dw_E.setDisplayName("Simple Dishwasher Annual Energy Consumption (kWh/yr)")
	dw_E.setDefaultValue(0)
	args << dw_E
	
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
    space_type.setDisplayName("Select the space where the miscellaneous electric loads are located")
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
    selected_dw = runner.getStringArgumentValue("selected_dw",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
    dw_E = runner.getDoubleArgumentValue("dw_E",user_arguments)
	bab_mult = runner.getDoubleArgumentValue("BAB_mult",user_arguments)
	num_br = runner.getIntegerArgumentValue("Num_Br", user_arguments)
	
	#warning if things are specified that will not be used (ie. BAB mult when detailed dw is modeled)
	#Benchmark and other values specified
	if selected_dw == "Benchmark" and dw_E != 0
		runner.registerWarning("Benchmark is specified with a non-zero dishwasher energy. This value will not be used")
	end
	
	#Simple but BAB mult or detailed options specified
	
	if selected_dw == "Simple" and bab_mult != 1
		runner.registerWarning("Simple is specified with a user specified benchmark multiplier. This value will not be used")
	elsif selected_dw == "Simple" and num_br != 1
		runner.registerWarning("Simple is specified with a user specified number of bedrooms. This value will not be used")
	end
	
	#if dw energy consumption is defined, check for reasonable energy consumption
	if selected_dw == "Simple" 
		if dw_E < 0
			runner.registerError("Electric dishwasher energy consumption must be greater than 0")
		elsif dw_E > 3000
			runner.registerError("Electric dishwasher energy consumption seems high, double check inputs") 
		end
	end
	
	#if BAB multiplier is defined, make sure it is positive and nonzero
	if selected_dw == "Benchmark" and bab_mult <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	end
	
	#if num bedrooms is defined, must be between 1-5
	if selected_dw == "Benchmark" or selected_dw == "Detailed"
		if num_br < 1 or num_br > 5
			runner.registerError("Number of bedrooms must be between 1 and 5 (inclusive)")
		end
	end
	
	#Calculate electric dw daily energy use
	
	if selected_dw == "Simple"
		dw_ann = dw_E
	elsif selected_dw == "Benchmark"
		dw_ann = (87.6 + 29.2 * num_br) * bab_mult
	end

	dw_daily = dw_ann / 365.0
	
	dwval = Process_dishwasher.new
	
	#pull schedule values and gain fractions from sim
	dw_lat = dwval.Dw_lat
	dw_conv = dwval.Dw_conv
	dw_lost = dwval.Dw_lost
	dw_rad = dwval.Dw_rad

	monthly_mult = dwval.Monthly_mult_dw
	weekday_hourly = dwval.Weekday_hourly_dw
	weekend_hourly = dwval.Weekend_hourly_dw
	maxval = dwval.Maxval_dw
	sum_max = dwval.Sum_dw_max
	sch_adjust = 1/sum_max
	
	#get dw max power
	dw_max = dw_daily * maxval * 1000 * sch_adjust
	
	#add dw to the selected space
	has_elec_dw = 0
	replace_dw = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add dw
			space_equipments = spaceType.electricEquipment
			space_equipments.each do |space_equipment|
				if space_equipment.electricEquipmentDefinition.name.get.to_s == "residential_electric_dw"
					has_elec_dw = 1
					replace_dw = 1
					runner.registerWarning("This space already has an dishwasher, the existing dishwasher will be replaced with the the currently selected option")
					space_equipment.electricEquipmentDefinition.setDesignLevel(dw_max)
				end
			end
			if has_elec_dw == 0 

				#add dw schedule
				has_elec_dw = 1
				dw_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				dw_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				dw_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_dw_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_dw_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				dw_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				dw_ruleset.setName("Elcetric_dw_annual_schedule")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_dw_rule[m] = OpenStudio::Model::ScheduleRule.new(dw_ruleset)
							wkdy_dw_rule[m].setName("elec_dw_weekday_ruleset#{m}")
							wkdy_dw_rule
							dw_wkdy[m] = wkdy_dw_rule[m].daySchedule
							dw_wkdy[m].setName("ElectricDwWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekday_hourly[h-1].to_f)/maxval
								dw_wkdy[m].addValue(time[h],val)
							end
							wkdy_dw_rule[m].setApplySunday(false)
							wkdy_dw_rule[m].setApplyMonday(true)
							wkdy_dw_rule[m].setApplyTuesday(true)
							wkdy_dw_rule[m].setApplyWednesday(true)
							wkdy_dw_rule[m].setApplyThursday(true)
							wkdy_dw_rule[m].setApplyFriday(true)
							wkdy_dw_rule[m].setApplySaturday(false)
							wkdy_dw_rule[m].setStartDate(date_s)
							wkdy_dw_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_dw_rule[m] = OpenStudio::Model::ScheduleRule.new(dw_ruleset)
							wknd_dw_rule[m].setName("elc_dw_weekend_ruleset#{m}")
							dw_wknd[m] = wknd_dw_rule[m].daySchedule
							dw_wknd[m].setName("ElectricDwWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekend_hourly[h-1].to_f)/maxval
								dw_wknd[m].addValue(time[h],val)
							end
							wknd_dw_rule[m].setApplySunday(true)
							wknd_dw_rule[m].setApplyMonday(false)
							wknd_dw_rule[m].setApplyTuesday(false)
							wknd_dw_rule[m].setApplyWednesday(false)
							wknd_dw_rule[m].setApplyThursday(false)
							wknd_dw_rule[m].setApplyFriday(false)
							wknd_dw_rule[m].setApplySaturday(true)
							wknd_dw_rule[m].setStartDate(date_s)
							wknd_dw_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = dw_wkdy[6]
				sumDesSch.setName("ElectricDwSummer")
				winDesSch = dw_wkdy[1]
				winDesSch.setName("ElectricDwWinter")
				dw_ruleset.setSummerDesignDaySchedule(sumDesSch)
				dw_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add electric equipment for the dw
				dw_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
				dw = OpenStudio::Model::ElectricEquipment.new(dw_def)
				dw.setName("residential_electric_dw")
				dw.setSpaceType(spaceType)
				dw_def.setName("residential_electric_dw")
				dw_def.setDesignLevel(dw_max)
				dw_def.setFractionRadiant(dw_rad)
				dw_def.setFractionLatent(dw_lat)
				dw_def.setFractionLost(dw_lost)
				
				dw.setSchedule(dw_ruleset)
				
			end
		end
	end

    #reporting final condition of model
	if has_elec_dw == 1
		if replace_dw == 1
			runner.registerFinalCondition("The existing dishwasher has been replaced by one with #{dw_ann} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("A dishwasher has been added with #{dw_ann} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Dishwasher was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialDishwasher.new.registerWithApplication