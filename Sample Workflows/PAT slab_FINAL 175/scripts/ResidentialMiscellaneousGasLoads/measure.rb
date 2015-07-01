#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialMiscellaneousGasLoads < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialMiscellaneousGasLoads"
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for mgls (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Simple"
	
	selected_mgl = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_mgl", chs, true)
	selected_mgl.setDisplayName("MGL Energy Consumption Option")
	args << selected_mgl
	
	#make a double argument for user defined mgl options
	mgl_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mgl_E",true)
	mgl_E.setDisplayName("Simple MGL Annual Energy Consumption (therm/yr)")
	mgl_E.setDefaultValue(0)
	args << mgl_E
	
	#make a double argument for the total conditioned floor area
	cfa = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("CondFA")
	cfa.setDisplayName("Living Space Floor Area (ft^2)")
	cfa.setDefaultValue(1800)
	args << cfa
	
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

	#TODO: Account for ceiling fan/thermostat setpoint interaction within this measure
	#make a bool argument for has ceiling fan
	#has_cf = OpenStudio::Ruleset::OSArgument::makeBoolArgument("Has_fan")
	#has_cf.setDisplayName("Has a ceiling fan")
	#has_cf.setDefaultValue(false)
	#args << has_cf
	
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
    space_type.setDisplayName("Select the space where the miscellaneous gas loads are located")
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
    selected_mgl = runner.getStringArgumentValue("selected_mgl",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
    mgl_E = runner.getDoubleArgumentValue("mgl_E",user_arguments)
	cfa = runner.getDoubleArgumentValue("CondFA",user_arguments)
	bab_mult = runner.getDoubleArgumentValue("BAB_mult",user_arguments)
	num_br = runner.getIntegerArgumentValue("Num_Br", user_arguments)
	
	#warning if things are specified that will not be used (ie. BAB mult when detailed mgl is modeled)
	#Benchmark and other values specified
	if selected_mgl == "Benchmark" and mgl_E != 0
		runner.registerWarning("Benchmark is specified with a non-zero mgl energy. This value will not be used")
	end
	
	#Simple but BAB mult or detailed options specified
	
	if selected_mgl == "Simple" and bab_mult != 1
		runner.registerWarning("Simple is specified with a user specified benchmark multiplier. This value will not be used")
	elsif selected_mgl == "Simple" and num_br != 1
		runner.registerWarning("Simple is specified with a user specified number of bedrooms. This value will not be used")
	elsif selected_mgl == "Simple" and cfa != 1800
		runner.registerWarning("Simple is specified with a user specified floor area. This value will not be used") 
	end
	
	#if mgl energy consumption is defined, check for reasonable energy consumption
	if selected_mgl == "Simple" 
		if mgl_E < 0
			runner.registerError("MGL energy consumption must be greater than 0")
		elsif mgl_E > 3000
			runner.registerError("MGL energy consumption seems high, double check inputs") 
		end
	end
	
	#if BAB multiplier is defined, make sure it is positive and nonzero
	if selected_mgl == "Benchmark" and bab_mult <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	end
	
	#if num bedrooms is defined, must be between 1-5
	if selected_mgl == "Benchmark" or selected_mgl == "Detailed"
		if num_br < 1 or num_br > 5
			runner.registerError("Number of bedrooms must be between 1 and 5 (inclusive)")
		end
	end
	
	#if floor area is entered, must be > 0
	if selected_mgl == "Benchmark" and cfa <= 0
		runner.registerError("Conditioned floor area must be positive and greater than zero, double check inputs")
	end
	
	#Get space floor area for mgl calculation
	
	#Calculate gas mgl daily energy use
	
	if selected_mgl == "Simple"
		mgl_ann = mgl_E
	elsif selected_mgl == "Benchmark"
		mgl_ann = (3.7 + 0.6 * num_br + 0.001 * cfa) * bab_mult
	end

	mgl_daily = mgl_ann / 365.0
	
	mglval = Process_mels.new
	
	#pull schedule values and gain fractions from sim
	mgl_lat = 0.021
	mgl_conv = 0.372
	mgl_lost = 0.049
	mgl_rad = 0.558

	monthly_mult = mglval.Monthly_mult_mel
	weekday_hourly = mglval.Weekday_hourly_mel
	weekend_hourly = mglval.Weekend_hourly_mel
	maxval = mglval.Maxval_mel
	sum_max = mglval.Sum_mel_max
	sch_adjust = 1/sum_max
	
	#get mgl max power
	mgl_max = mgl_daily * maxval * 1000 * sch_adjust * 29.30011
	
	#add mgl to the selected space
	has_mgl = 0
	replace_mgl = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add mgl
			space_equipments = spaceType.gasEquipment
			space_equipments.each do |space_equipment|
				if space_equipment.gasEquipmentDefinition.name.get.to_s == "residential_mgl"
					has_mgl = 1
					replace_mgl = 1
					runner.registerWarning("This space already has mgls, the existing mgls will be replaced with the the currently selected option")
					space_equipment.gasEquipmentDefinition.setDesignLevel(mgl_max)
				end
			end
			if has_mgl == 0 

				#add mgl schedule
				has_mgl = 1
				mgl_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				mgl_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				mgl_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_mgl_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_mgl_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				mgl_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				mgl_ruleset.setName("Elcetric_mgl_annual_schedule")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_mgl_rule[m] = OpenStudio::Model::ScheduleRule.new(mgl_ruleset)
							wkdy_mgl_rule[m].setName("mgl_weekday_ruleset#{m}")
							wkdy_mgl_rule
							mgl_wkdy[m] = wkdy_mgl_rule[m].daySchedule
							mgl_wkdy[m].setName("MGLWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekday_hourly[h-1].to_f)/maxval
								mgl_wkdy[m].addValue(time[h],val)
							end
							wkdy_mgl_rule[m].setApplySunday(false)
							wkdy_mgl_rule[m].setApplyMonday(true)
							wkdy_mgl_rule[m].setApplyTuesday(true)
							wkdy_mgl_rule[m].setApplyWednesday(true)
							wkdy_mgl_rule[m].setApplyThursday(true)
							wkdy_mgl_rule[m].setApplyFriday(true)
							wkdy_mgl_rule[m].setApplySaturday(false)
							wkdy_mgl_rule[m].setStartDate(date_s)
							wkdy_mgl_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_mgl_rule[m] = OpenStudio::Model::ScheduleRule.new(mgl_ruleset)
							wknd_mgl_rule[m].setName("mgl_weekend_ruleset#{m}")
							mgl_wknd[m] = wknd_mgl_rule[m].daySchedule
							mgl_wknd[m].setName("MGLWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekend_hourly[h-1].to_f)/maxval
								mgl_wknd[m].addValue(time[h],val)
							end
							wknd_mgl_rule[m].setApplySunday(true)
							wknd_mgl_rule[m].setApplyMonday(false)
							wknd_mgl_rule[m].setApplyTuesday(false)
							wknd_mgl_rule[m].setApplyWednesday(false)
							wknd_mgl_rule[m].setApplyThursday(false)
							wknd_mgl_rule[m].setApplyFriday(false)
							wknd_mgl_rule[m].setApplySaturday(true)
							wknd_mgl_rule[m].setStartDate(date_s)
							wknd_mgl_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = mgl_wkdy[6]
				sumDesSch.setName("MGLSummer")
				winDesSch = mgl_wkdy[1]
				winDesSch.setName("MGLWinter")
				mgl_ruleset.setSummerDesignDaySchedule(sumDesSch)
				mgl_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add gas equipment for the mgl
				mgl_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
				mgl = OpenStudio::Model::GasEquipment.new(mgl_def)
				mgl.setName("residential_mgl")
				mgl.setSpaceType(spaceType)
				mgl_def.setName("residential_mgl")
				mgl_def.setDesignLevel(mgl_max)
				mgl_def.setFractionRadiant(mgl_rad)
				mgl_def.setFractionLatent(mgl_lat)
				mgl_def.setFractionLost(mgl_lost)
				
				mgl.setSchedule(mgl_ruleset)
				
			end
		end
	end

    #reporting final condition of model
	if has_mgl == 1
		if replace_mgl == 1
			runner.registerFinalCondition("The existing MGLS has been replaced by one with #{mgl_ann} therm annual energy consumption.")
		else
			runner.registerFinalCondition("MGLs has been added with #{mgl_ann} therm annual energy consumption.")
		end
	else
		runner.registerFinalCondition("No MGL was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialMiscellaneousGasLoads.new.registerWithApplication