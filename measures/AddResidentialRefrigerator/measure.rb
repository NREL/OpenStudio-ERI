#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ResidentialRefrigerator < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialRefrigerator"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for fridges (alternate schedules if automatic DR control is specified)
	
	#make a choice argument for whether Benchmark fraction or annual energy consumption is specified
	chs = OpenStudio::StringVector.new
	chs << "Benchmark" 
	chs << "Annual Energy Consumption"
	
	selected_fridge = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selected_fridge", chs, true)
	selected_fridge.setDisplayName("Refrigerator Energy Consumption Option")
	args << selected_fridge
	
	#make a double argument for user defined fridge options
	fridge_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fridge_E",true)
	fridge_E.setDisplayName("User Defined Refrigerator Annual Energy Consumption (kWh/yr)")
	fridge_E.setDefaultValue(0)
	args << fridge_E
	
	#make a double argument for BA Benchamrk multiplier
	bab_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("BAB_mult")
	bab_mult.setDisplayName("Building America Benchmark Multipler")
	bab_mult.setDefaultValue(1)
	args << bab_mult
	
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
    space_type.setDisplayName("Select the space where the refrigerator is located")
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
    selected_fridge = runner.getStringArgumentValue("selected_fridge",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
    fridge_E = runner.getDoubleArgumentValue("fridge_E",user_arguments)
	bab_mult = runner.getDoubleArgumentValue("BAB_mult",user_arguments)
	
	#warning if fridge E is selected and BAB multiplier is specified or vice versa
	if selected_fridge == "Annual Energy Consumption" and bab_mult != 1:
		runner.registerWarning("Annual energy consumption is selected with a user specified benchmark multiplier. The multiplier will not be used.")
	end
	
	if selected_fridge == "Benchmark" and fridge_E != 0:
		runner.registerWarning("Benchmark is selected with a user specified annual energy consumption. The annual energy consumption will not be used.")
	end
	
	#if fridge energy consumption is defined, check for reasonable energy consumption
	if selected_fridge == "Annual Energy Consumption" 
		if fridge_E < 0
			runner.registerError("Refrigerator energy consumption must be greater than 0")
		elsif fridge_E < 100
			runner.registerError("Refrigerator energy consumption seems low, double check inputs") 
		elsif fridge_E > 3000
			runner.registerError("Refrigerator energy consumption seems high, double check inputs") 
		end
	end
	
	#if BAB multiplier is defined, make sure it is positive and nonzero
	if selected_fridge == "Benchmark" and bab_mult <= 0
		runner.registerError("Benchmark multiplier must be positive and greater than zero, double check inputs")
	end
	
	#Calculate fridge daily energy use
	if selected_fridge == "Annual Energy Consumption"
		fridge_daily = fridge_E/365.0
		fridge_ann = fridge_E
	else
		fridge_daily = (434 * bab_mult)/365.0
		fridge_ann = 434 * bab_mult
	end

	#pull schedule values and gain fractions from sim
	fridge_lat = Process_refrigerator::Fridge_lat
	fridge_conv = Process_refrigerator::Fridge_conv
	fridge_rad = Process_refrigerator::Fridge_rad
	fridge_lost = Process_refrigerator::Fridge_lost
	
	monthly_mult = Process_refrigerator::Monthly_mult_fridge
	weekday_hourly = Process_refrigerator::Weekday_hourly_fridge
	weekend_hourly = Process_refrigerator::Weekend_hourly_fridge
	maxval = Process_refrigerator::Maxval_fridge
	sum_wkdy = Process_refrigerator::Sum_wkdy
	sch_adjust = 1/sum_wkdy
	
	#get fridge max power
	fridge_max = (fridge_daily * maxval * 1000 * sch_adjust)
	
	#add refrigerator to the selected space
	has_fridge = 0
	replace_fridge = 0
	num_equip = 1
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		#runner.registerWarning("#{spaceType}")
		if spacehandle == space_type_r #add refrigerator
			space_equipments = spaceType.electricEquipment
			space_equipments.each do |space_equipment|
				if space_equipment.electricEquipmentDefinition.name.get.to_s == "residential_refrigerator" #TODO: double check that this actually gets equipment name
					has_fridge = 1
					runner.registerWarning("This space already has a refrigerator, the existing refrigerator will be replaced with the the currently selected option")
					space_equipment.electricEquipmentDefinition.setDesignLevel(fridge_max)
					num_equip += 1
					replace_fridge = 1
				end
			end
			if has_fridge == 0 

				#add refrigerator schedule
				has_fridge = 1
				#refrig_sch = OpenStudio::Model::ScheduleRuleset.new(model)
				#refrig_sch.setName("refrig_schedule")
				refrig_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				refrig_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				refrig_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
				wkdy_refrig_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				wknd_refrig_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
				day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
				day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
				
				refrig_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
				refrig_ruleset.setName("refrigerator_ruleset")
				
				
				for m in 1..12
					date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
					date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
					for w in 1..2
						if w == 1
							wkdy_refrig_rule[m] = OpenStudio::Model::ScheduleRule.new(refrig_ruleset)
							wkdy_refrig_rule[m].setName("fridge_weekday_ruleset#{m}")
							wkdy_refrig_rule
							refrig_wkdy[m] = wkdy_refrig_rule[m].daySchedule
							refrig_wkdy[m].setName("RefrigeratorWeekday#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekday_hourly[h-1].to_f)/maxval
								#runner.registerWarning("#{monthly_mult[m-1]}")
								#runner.registerWarning("#{weekday_hourly[h]}")
								#runner.registerWarning("#{val}")
								refrig_wkdy[m].addValue(time[h],val)
							end
							wkdy_refrig_rule[m].setApplySunday(false)
							wkdy_refrig_rule[m].setApplyMonday(true)
							wkdy_refrig_rule[m].setApplyTuesday(true)
							wkdy_refrig_rule[m].setApplyWednesday(true)
							wkdy_refrig_rule[m].setApplyThursday(true)
							wkdy_refrig_rule[m].setApplyFriday(true)
							wkdy_refrig_rule[m].setApplySaturday(false)
							wkdy_refrig_rule[m].setStartDate(date_s)
							wkdy_refrig_rule[m].setEndDate(date_e)
							
						elsif w == 2
							wknd_refrig_rule[m] = OpenStudio::Model::ScheduleRule.new(refrig_ruleset)
							wknd_refrig_rule[m].setName("fridge_weekday_ruleset#{m}")
							refrig_wknd[m] = wknd_refrig_rule[m].daySchedule
							refrig_wknd[m].setName("RefrigeratorWeekend#{m}")
							for h in 1..24
								time[h] = OpenStudio::Time.new(0,h,0,0)
								val = (monthly_mult[m-1].to_f*weekend_hourly[h-1].to_f)/maxval
								refrig_wknd[m].addValue(time[h],val)
							end
							wknd_refrig_rule[m].setApplySunday(true)
							wknd_refrig_rule[m].setApplyMonday(false)
							wknd_refrig_rule[m].setApplyTuesday(false)
							wknd_refrig_rule[m].setApplyWednesday(false)
							wknd_refrig_rule[m].setApplyThursday(false)
							wknd_refrig_rule[m].setApplyFriday(false)
							wknd_refrig_rule[m].setApplySaturday(true)
							wknd_refrig_rule[m].setStartDate(date_s)
							wknd_refrig_rule[m].setEndDate(date_e)
						end
					end
				end
				
				sumDesSch = refrig_wkdy[6]
				sumDesSch.setName("RefrigeratorSummer")
				winDesSch = refrig_wkdy[1]
				winDesSch.setName("RefrigeratorWinter")
				refrig_ruleset.setSummerDesignDaySchedule(sumDesSch)
				refrig_ruleset.setWinterDesignDaySchedule(winDesSch)
					
				#Add electric equipment for the fridge
				frg_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
				frg = OpenStudio::Model::ElectricEquipment.new(frg_def)
				frg.setName("residential_refrigerator")
				frg.setSpaceType(spaceType)
				frg_def.setName("residential_refrigerator")
				frg_def.setDesignLevel(fridge_max)
				frg_def.setFractionRadiant(fridge_rad)
				frg_def.setFractionLatent(fridge_lat)
				frg_def.setFractionLost(fridge_lost)
				
				frg.setSchedule(refrig_ruleset)
				
			end
		end
	end
	
	
	
    #reporting final condition of model
	if has_fridge == 1
		if replace_fridge = 1
			runner.registerFinalCondition("The existing fridge has been replaced by one with #{fridge_ann} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("A fridge has been added with #{fridge_ann} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Refrigerator was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialRefrigerator.new.registerWithApplication