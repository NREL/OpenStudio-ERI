#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialMiscellaneousElectricLoads < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialMiscellaneousElectricLoads"
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for mels (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Simple"
	
	selected_mel = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_mel", chs, true)
	selected_mel.setDisplayName("MEL Energy Consumption Option")
	args << selected_mel
	
	#make a double argument for user defined mel options
	mel_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mel_E",true)
	mel_E.setDisplayName("Simple MEL Annual Energy Consumption (kWh/yr)")
	mel_E.setDefaultValue(0)
	args << mel_E
	
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
    selected_mel = runner.getStringArgumentValue("selected_mel",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
    mel_E = runner.getDoubleArgumentValue("mel_E",user_arguments)
	cfa = runner.getDoubleArgumentValue("CondFA",user_arguments)
	bab_mult = runner.getDoubleArgumentValue("BAB_mult",user_arguments)
	num_br = runner.getIntegerArgumentValue("Num_Br", user_arguments)
	
	#warning if things are specified that will not be used (ie. BAB mult when detailed mel is modeled)
	#Benchmark and other values specified
	if selected_mel == "Benchmark" and mel_E != 0
		runner.registerWarning("Benchmark is specified with a non-zero MEL energy. This value will not be used")
	end
	
	#Simple but BAB mult or detailed options specified
	
	if selected_mel == "Simple" and bab_mult != 1
		runner.registerWarning("Simple is specified with a user specified benchmark multiplier. This value will not be used")
	elsif selected_mel == "Simple" and num_br != 1
		runner.registerWarning("Simple is specified with a user specified number of bedrooms. This value will not be used")
	elsif selected_mel == "Simple" and cfa != 1800
		runner.registerWarning("Simple is specified with a user specified floor area. This value will not be used") 
	end
	
	#if mel energy consumption is defined, check for reasonable energy consumption
	if selected_mel == "Simple" 
		if mel_E < 0
			runner.registerError("Electric MEL energy consumption must be greater than 0")
		elsif mel_E > 3000
			runner.registerError("Electric MEL energy consumption seems high, double check inputs") 
		end
	end
	
	#if BAB multiplier is defined, make sure it is positive and nonzero
	if selected_mel == "Benchmark" and bab_mult <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	end
	
	#if num bedrooms is defined, must be between 1-5
	if selected_mel == "Benchmark" or selected_mel == "Detailed"
		if num_br < 1 or num_br > 5
			runner.registerError("Number of bedrooms must be between 1 and 5 (inclusive)")
		end
	end
	
	#if floor area is entered, must be > 0
	if selected_mel == "Benchmark" and cfa <= 0
		runner.registerError("Conditioned floor area must be positive and greater than zero, double check inputs")
	end
	
	#Get space floor area for MEL calculation
	
	#Calculate electric mel daily energy use
	
	if selected_mel == "Simple"
		mel_ann = mel_E
	elsif selected_mel == "Benchmark"
		mel_ann = (1108.1 +180.2 * num_br + 0.278 * cfa) * bab_mult
	end

	mel_daily = mel_ann / 365.0
	
	melval = Process_mels.new
	
	#pull schedule values and gain fractions from sim
	mel_lat = melval.Mel_lat
	mel_conv = melval.Mel_conv
	mel_lost = melval.Mel_lost
	mel_rad = melval.Mel_rad

	monthly_mult = melval.Monthly_mult_mel
	weekday_hourly = melval.Weekday_hourly_mel
	weekend_hourly = melval.Weekend_hourly_mel
	maxval = melval.Maxval_mel
	sum_max = melval.Sum_mel_max
	sch_adjust = 1/sum_max
	
	#get mel max power
	mel_max = mel_daily * maxval * 1000 * sch_adjust
	
	#add mel to the selected space
	has_elec_mel = 0
	replace_mel = 0
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add mel
			space_equipments = spaceType.electricEquipment
			space_equipments.each do |space_equipment|
				if space_equipment.electricEquipmentDefinition.name.get.to_s == "residential_electric_mel"
					has_elec_mel = 1
					replace_mel = 1
					runner.registerWarning("This space already has an electric MELs, the existing MELs will be replaced with the the currently selected option")
					space_equipment.electricEquipmentDefinition.setDesignLevel(mel_max)
				end
			end
			if has_elec_mel == 0 

				#add mel schedule
				has_elec_mel = 1
				mel_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				mel_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				mel_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_mel_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_mel_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				mel_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				mel_ruleset.setName("Elcetric_mel_annual_schedule")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_mel_rule[m] = OpenStudio::Model::ScheduleRule.new(mel_ruleset)
							wkdy_mel_rule[m].setName("elec_mel_weekday_ruleset#{m}")
							wkdy_mel_rule
							mel_wkdy[m] = wkdy_mel_rule[m].daySchedule
							mel_wkdy[m].setName("ElectricmelWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekday_hourly[h-1].to_f)/maxval
								mel_wkdy[m].addValue(time[h],val)
							end
							wkdy_mel_rule[m].setApplySunday(false)
							wkdy_mel_rule[m].setApplyMonday(true)
							wkdy_mel_rule[m].setApplyTuesday(true)
							wkdy_mel_rule[m].setApplyWednesday(true)
							wkdy_mel_rule[m].setApplyThursday(true)
							wkdy_mel_rule[m].setApplyFriday(true)
							wkdy_mel_rule[m].setApplySaturday(false)
							wkdy_mel_rule[m].setStartDate(date_s)
							wkdy_mel_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_mel_rule[m] = OpenStudio::Model::ScheduleRule.new(mel_ruleset)
							wknd_mel_rule[m].setName("elc_mel_weekend_ruleset#{m}")
							mel_wknd[m] = wknd_mel_rule[m].daySchedule
							mel_wknd[m].setName("ElectricmelWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekend_hourly[h-1].to_f)/maxval
								mel_wknd[m].addValue(time[h],val)
							end
							wknd_mel_rule[m].setApplySunday(true)
							wknd_mel_rule[m].setApplyMonday(false)
							wknd_mel_rule[m].setApplyTuesday(false)
							wknd_mel_rule[m].setApplyWednesday(false)
							wknd_mel_rule[m].setApplyThursday(false)
							wknd_mel_rule[m].setApplyFriday(false)
							wknd_mel_rule[m].setApplySaturday(true)
							wknd_mel_rule[m].setStartDate(date_s)
							wknd_mel_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = mel_wkdy[6]
				sumDesSch.setName("ElectricmelSummer")
				winDesSch = mel_wkdy[1]
				winDesSch.setName("ElectricmelWinter")
				mel_ruleset.setSummerDesignDaySchedule(sumDesSch)
				mel_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add electric equipment for the mel
				rng_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
				rng = OpenStudio::Model::ElectricEquipment.new(rng_def)
				rng.setName("residential_electric_mel")
				rng.setSpaceType(spaceType)
				rng_def.setName("residential_electric_mel")
				rng_def.setDesignLevel(mel_max)
				rng_def.setFractionRadiant(mel_rad)
				rng_def.setFractionLatent(mel_lat)
				rng_def.setFractionLost(mel_lost)
				
				rng.setSchedule(mel_ruleset)
				
			end
		end
	end

    #reporting final condition of model
	if has_elec_mel == 1
		if replace_mel == 1
			runner.registerFinalCondition("The existing electric MELS has been replaced by one with #{mel_ann} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("An electric mel has been added with #{mel_ann} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Electric mel was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialMiscellaneousElectricLoads.new.registerWithApplication