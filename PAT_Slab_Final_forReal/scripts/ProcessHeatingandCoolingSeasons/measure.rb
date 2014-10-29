#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessHeatingandCoolingSeasons < OpenStudio::Ruleset::ModelUserScript

  class Misc
    def initialize(simTestSuiteBuilding)
      @simTestSuiteBuilding = simTestSuiteBuilding
    end

    def SimTestSuiteBuilding
      return @simTestSuiteBuilding
    end
  end

  class Schedules
    def initialize
    end
    attr_accessor(:heating_season, :cooling_season)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessHeatingandCoolingSeasons"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    simTestSuiteBuilding = nil

    # Create the material class instances
    misc = Misc.new(simTestSuiteBuilding)
    schedules = Schedules.new

    # Create the sim object
    sim = Sim.new(model)

    # Process the heating and cooling seasons
    schedules = sim._processHeatingCoolingSeasons(misc, schedules)

    day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

    sched_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
    sched_type.setName("ON/OFF")
    sched_type.setLowerLimitValue(0)
    sched_type.setUpperLimitValue(1)
    sched_type.setNumericType("Discrete")

    # HeatingSeasonSchedule
    htgssn_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    htgssn_ruleset.setName("HeatingSeasonSchedule")

    htgssn_ruleset.setScheduleTypeLimits(sched_type)

    htgssn_rule_days = []
    for m in 1..12
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
      htgssn_rule = OpenStudio::Model::ScheduleRule.new(htgssn_ruleset)
      htgssn_rule.setName("HeatingSeasonSchedule%02d" % m.to_s)
      htgssn_rule_day = htgssn_rule.daySchedule
      htgssn_rule_day.setName("HeatingSeasonSchedule%02dd" % m.to_s)
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = schedules.heating_season[m - 1]
        htgssn_rule_day.addValue(time,val)
      end
      htgssn_rule_days << htgssn_rule_day
      htgssn_rule.setApplySunday(true)
      htgssn_rule.setApplyMonday(true)
      htgssn_rule.setApplyTuesday(true)
      htgssn_rule.setApplyWednesday(true)
      htgssn_rule.setApplyThursday(true)
      htgssn_rule.setApplyFriday(true)
      htgssn_rule.setApplySaturday(true)
      htgssn_rule.setStartDate(date_s)
      htgssn_rule.setEndDate(date_e)
    end

    htgssn_sumDesSch = htgssn_rule_days[6]
    htgssn_winDesSch = htgssn_rule_days[1]
    htgssn_ruleset.setSummerDesignDaySchedule(htgssn_sumDesSch)
    htgssn_summer = htgssn_ruleset.summerDesignDaySchedule
    htgssn_summer.setName("HeatingSeasonScheduleSummer")
    htgssn_ruleset.setWinterDesignDaySchedule(htgssn_winDesSch)
    htgssn_winter = htgssn_ruleset.winterDesignDaySchedule
    htgssn_winter.setName("HeatingSeasonScheduleWinter")

    # CoolingSeasonSchedule
    clgssn_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    clgssn_ruleset.setName("CoolingSeasonSchedule")

    clgssn_ruleset.setScheduleTypeLimits(sched_type)

    clgssn_rule_days = []
    for m in 1..12
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
      clgssn_rule = OpenStudio::Model::ScheduleRule.new(clgssn_ruleset)
      clgssn_rule.setName("CoolingSeasonSchedule%02d" % m.to_s)
      clgssn_rule_day = clgssn_rule.daySchedule
      clgssn_rule_day.setName("CoolingSeasonSchedule%02dd" % m.to_s)
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = schedules.cooling_season[m - 1]
        clgssn_rule_day.addValue(time,val)
      end
      clgssn_rule_days << clgssn_rule_day
      clgssn_rule.setApplySunday(true)
      clgssn_rule.setApplyMonday(true)
      clgssn_rule.setApplyTuesday(true)
      clgssn_rule.setApplyWednesday(true)
      clgssn_rule.setApplyThursday(true)
      clgssn_rule.setApplyFriday(true)
      clgssn_rule.setApplySaturday(true)
      clgssn_rule.setStartDate(date_s)
      clgssn_rule.setEndDate(date_e)
    end

    clgssn_sumDesSch = clgssn_rule_days[6]
    clgssn_winDesSch = clgssn_rule_days[1]
    clgssn_ruleset.setSummerDesignDaySchedule(clgssn_sumDesSch)
    clgssn_summer = clgssn_ruleset.summerDesignDaySchedule
    clgssn_summer.setName("CoolingSeasonScheduleSummer")
    clgssn_ruleset.setWinterDesignDaySchedule(clgssn_winDesSch)
    clgssn_winter = clgssn_ruleset.winterDesignDaySchedule
    clgssn_winter.setName("CoolingSeasonScheduleWinter")

    runner.registerInfo("Set the monthly HeatingSeasonSchedule as #{schedules.heating_season.join(", ")}")
    runner.registerInfo("Set the monthly CoolingSeasonSchedule as #{schedules.cooling_season.join(", ")}")

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessHeatingandCoolingSeasons.new.registerWithApplication