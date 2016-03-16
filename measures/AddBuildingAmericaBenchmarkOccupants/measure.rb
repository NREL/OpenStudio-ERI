#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class AddBuildingAmericaBenchmarkOccupants < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Occupants"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
	
	#make an interger argument for number of bedrooms
	num_br = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("NumBr",true)
	num_br.setDisplayName("Number of Bedrooms")
	num_br.setDefaultValue(1)
	args << num_br
	
    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type
    
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
    num_br = runner.getIntegerArgumentValue("NumBr",user_arguments)
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)

    #Get space type
    living_space_type = Geometry.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end

	#number of bedrooms must be between 1-5
	if num_br < 1 or num_br > 5
		runner.registerError("Number of bedrooms must be between 1 and 5 (inclusive)")
	end
	
	#Calculate number of occupants & activity level
	num_occ = 0.87 + 0.59 * num_br
	activity_per_person = 112.5504
	occupant_activity = OpenStudio::Model::ScheduleRuleset.new(model)
	occupant_activity.setName("Occupant_Activity")
	occupant_activity.defaultDaySchedule().setName("DefaultDay")
	occupant_activity.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),activity_per_person)
	
	#get occupant gains fractions and schedule from sim
	occ_lat = 0.427
	occ_conv = 0.253
	occ_rad = 0.32
	occ_lost = 1 - occ_lat - occ_conv - occ_rad
	occ_sens = occ_rad + occ_conv
	
	#Right now hard coded simple schedules
	#TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
	monthly_mult = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	weekday_hourly = [1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000]
	weekend_hourly = weekday_hourly
	
	#add occupants to the selected space
	has_occ = 0
	replace_occ = 0
    space_occupants = living_space_type.people
    space_occupants.each do |occupant|
        if occupant.peopleDefinition.name.get.to_s == "residential_occupants"
            has_occ = 1
            runner.registerWarning("This space already has occupants, the existing occupants will be replaced with the specified occupants.")
            space_equipment.peopleDefinition.setDesignLevel(occ_max)
            replace_occ = 1
        end
    end
    if has_occ == 0 

        #add occupants schedule
        has_occ = 1
        occ_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
        occ_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
        occ_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
        time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
        wkdy_occ_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
        wknd_occ_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
        day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
        day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
        
        occ_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
        occ_ruleset.setName("occupants_ruleset")
        
        
        for m in 1..12
            date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
            date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
            for w in 1..2
                if w == 1
                    wkdy_occ_rule[m] = OpenStudio::Model::ScheduleRule.new(occ_ruleset)
                    wkdy_occ_rule[m].setName("occ_weekday_ruleset#{m}")
                    wkdy_occ_rule
                    occ_wkdy[m] = wkdy_occ_rule[m].daySchedule
                    occ_wkdy[m].setName("occupantsWeekday#{m}")
                    for h in 1..24
                        time[h] = OpenStudio::Time.new(0,h,0,0)
                        val = weekday_hourly[h-1]
                        occ_wkdy[m].addValue(time[h],val)
                    end
                    wkdy_occ_rule[m].setApplySunday(false)
                    wkdy_occ_rule[m].setApplyMonday(true)
                    wkdy_occ_rule[m].setApplyTuesday(true)
                    wkdy_occ_rule[m].setApplyWednesday(true)
                    wkdy_occ_rule[m].setApplyThursday(true)
                    wkdy_occ_rule[m].setApplyFriday(true)
                    wkdy_occ_rule[m].setApplySaturday(false)
                    wkdy_occ_rule[m].setStartDate(date_s)
                    wkdy_occ_rule[m].setEndDate(date_e)
                    
                elsif w == 2
                    wknd_occ_rule[m] = OpenStudio::Model::ScheduleRule.new(occ_ruleset)
                    wknd_occ_rule[m].setName("occ_weekday_ruleset#{m}")
                    occ_wknd[m] = wknd_occ_rule[m].daySchedule
                    occ_wknd[m].setName("occupantsWeekend#{m}")
                    for h in 1..24
                        time[h] = OpenStudio::Time.new(0,h,0,0)
                        val = weekend_hourly[h-1]
                        occ_wknd[m].addValue(time[h],val)
                    end
                    wknd_occ_rule[m].setApplySunday(true)
                    wknd_occ_rule[m].setApplyMonday(false)
                    wknd_occ_rule[m].setApplyTuesday(false)
                    wknd_occ_rule[m].setApplyWednesday(false)
                    wknd_occ_rule[m].setApplyThursday(false)
                    wknd_occ_rule[m].setApplyFriday(false)
                    wknd_occ_rule[m].setApplySaturday(true)
                    wknd_occ_rule[m].setStartDate(date_s)
                    wknd_occ_rule[m].setEndDate(date_e)
                end
            end
        end
        
        sumDesSch = occ_wkdy[6]
        sumDesSch.setName("OccupantsSummer")
        winDesSch = occ_wkdy[1]
        winDesSch.setName("OccupantsWinter")
        occ_ruleset.setSummerDesignDaySchedule(sumDesSch)
        occ_ruleset.setWinterDesignDaySchedule(winDesSch)
            
        #Add people definition for the occ
        occ_def = OpenStudio::Model::PeopleDefinition.new(model)
        occ = OpenStudio::Model::People.new(occ_def)
        occ.setName("residential_occupants")
        occ.setSpaceType(living_space_type)
        occ_def.setName("residential_occupants")
        occ_def.setNumberOfPeopleCalculationMethod("People",1)
        occ_def.setNumberofPeople(num_occ)
        occ_def.setFractionRadiant(occ_rad)
        occ_def.setSensibleHeatFraction(occ_sens)
        occ_def.setMeanRadiantTemperatureCalculationType("ZoneAveraged")
        occ_def.setCarbonDioxideGenerationRate(0)
        occ_def.setEnableASHRAE55ComfortWarnings(false)
        occ.setNumberofPeopleSchedule(occ_ruleset)
        occ.setActivityLevelSchedule(occupant_activity)
        
    end
	
    #reporting final condition of model
    if replace_occ == 1
        runner.registerFinalCondition("The existing occupants has been replaced, building now has #{num_occ} occupants.")
    else
        runner.registerFinalCondition("#{num_occ} occupants has been added to the space.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AddBuildingAmericaBenchmarkOccupants.new.registerWithApplication