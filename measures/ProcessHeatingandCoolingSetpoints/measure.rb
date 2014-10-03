#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
#require "#{File.dirname(__FILE__)}/resources/sim"
require "C:/OS-BEopt/OpenStudio-Beopt/resources/sim"

#start the measure
class ProcessHeatingandCoolingSetpoints < OpenStudio::Ruleset::ModelUserScript

  class HeatingSetpoint
    def initialize(heatingSetpointConstantSetpoint)
      @heatingSetpointConstantSetpoint = heatingSetpointConstantSetpoint
    end

    attr_accessor(:HeatingSetpointSchedule, :HeatingSetpointWeekday, :HeatingSetpointWeekend)

    def HeatingSetpointConstantSetpoint
      return @heatingSetpointConstantSetpoint
    end
  end

  class CoolingSetpoint
    def initialize(coolingSetpointConstantSetpoint)
      @coolingSetpointConstantSetpoint = coolingSetpointConstantSetpoint
    end

    attr_accessor(:CoolingSetpointSchedule, :CoolingSetpointWeekday, :CoolingSetpointWeekend)

    def CoolingSetpointConstantSetpoint
      return @coolingSetpointConstantSetpoint
    end
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessHeatingandCoolingSetpoints"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    thermalzone_handles = OpenStudio::StringVector.new
    thermalzone_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    thermalzone_args = model.getThermalZones
    thermalzone_args_hash = {}
    thermalzone_args.each do |thermalzone_arg|
      thermalzone_args_hash[thermalzone_arg.name.to_s] = thermalzone_arg
    end

    #looping through sorted hash of model objects
    thermalzone_args_hash.sort.map do |key,value|
      thermalzone_handles << value.handle.to_s
      thermalzone_display_names << key
    end

    #make a choice argument for living space
    selectedliving = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", thermalzone_handles, thermalzone_display_names, true)
    selectedliving.setDisplayName("Select the living zone.")
    args << selectedliving

    #make a double argument for constant heating setpoint
    userdefinedhsp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhsp", false)
    userdefinedhsp.setDisplayName("Enter the constant heating setpoint [F].")
    userdefinedhsp.setDefaultValue(71.0)
    args << userdefinedhsp

    #make a double argument for constant cooling setpoint
    userdefinedcsp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsp", false)
    userdefinedcsp.setDisplayName("Enter the constant cooling setpoint [F].")
    userdefinedcsp.setDefaultValue(76.0)
    args << userdefinedcsp

    #make a bool argument for whether the house has heating equipment
    selectedheating = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedheating", false)
    selectedheating.setDisplayName("The house has heating equipment.")
    selectedheating.setDefaultValue(true)
    args << selectedheating

    #make a bool argument for whether the house has cooling equipment
    selectedcooling = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedcooling", false)
    selectedcooling.setDisplayName("The house has cooling equipment.")
    selectedcooling.setDefaultValue(true)
    args << selectedcooling

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Thermal Zone
    selectedliving = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

    # Setpoints
    heatingSetpointConstantSetpoint = runner.getDoubleArgumentValue("userdefinedhsp",user_arguments)
    coolingSetpointConstantSetpoint = runner.getDoubleArgumentValue("userdefinedcsp",user_arguments)

    # Equipment
    selectedheating = runner.getBoolArgumentValue("selectedheating",user_arguments)
    selectedcooling = runner.getBoolArgumentValue("selectedcooling",user_arguments)

    if not selectedheating
      heatingSetpointConstantSetpoint = -1000
      runner.registerWarning("House has no heating equipment; heating setpoint set to -1000 so there's no heating")
    end
    if not selectedcooling
      coolingSetpointConstantSetpoint = 1000
      runner.registerWarning("House has no cooling equipment; cooling setpoint set to 1000 so there's no cooling")
    end

    # get the heating and cooling season schedules
    heating_season = {}
    cooling_season = {}
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "HeatingSeasonSchedule"
        scheduleRules = scheduleRuleset.scheduleRules
        scheduleRules.each do |scheduleRule|
          daySchedule = scheduleRule.daySchedule
          values = daySchedule.values
          heating_season[scheduleRule.name.to_s] = values[0]
        end
      elsif scheduleRuleset.name.to_s == "CoolingSeasonSchedule"
        scheduleRules = scheduleRuleset.scheduleRules
        scheduleRules.each do |scheduleRule|
          daySchedule = scheduleRule.daySchedule
          values = daySchedule.values
          cooling_season[scheduleRule.name.to_s] = values[0]
        end
      end
    end

    # Create the material class instances
    hsp = HeatingSetpoint.new(heatingSetpointConstantSetpoint)
    csp = CoolingSetpoint.new(coolingSetpointConstantSetpoint)

    # Create the sim object
    sim = Sim.new(model)

    # Process the heating and cooling setpoints
    hsp, csp, controlType = sim._processHeatingCoolingSetpoints(hsp, csp, selectedheating, selectedcooling)

    thermalzones = model.getThermalZones
    thermalzones.each do |thermalzone|
      if selectedliving.get.handle.to_s == thermalzone.handle.to_s
        thermostatsetpointdualsetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
        thermostatsetpointdualsetpoint.setName("Living Zone Temperature SP")

        day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
        day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

        heatingsetpoint = OpenStudio::Model::ScheduleRuleset.new(model)
        heatingsetpoint.setName("HeatingSetPoint")

        htgssn_rule_days = []
        for m in 1..12
          date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
          date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
          htgssn_rule = OpenStudio::Model::ScheduleRule.new(heatingsetpoint)
          htgssn_rule.setName("HeatingSetPointSchedule%02d" % m.to_s)
          htgssn_rule_day = htgssn_rule.daySchedule
          htgssn_rule_day.setName("HeatingSetPointSchedule%02dd" % m.to_s)
          for h in 1..24
            time = OpenStudio::Time.new(0,h,0,0)
            if heating_season["HeatingSeasonSchedule%02d" % m.to_s] == 1.0
              val = OpenStudio::convert(hsp.HeatingSetpointWeekday[h - 1],"F","C").get
            else
              val = -1000
            end
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
        heatingsetpoint.setSummerDesignDaySchedule(htgssn_sumDesSch)
        htgssn_summer = heatingsetpoint.summerDesignDaySchedule
        htgssn_summer.setName("HeatingSetPointScheduleSummer")
        htgssn_summer.clearValues
        for h in 1..24
          time = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(hsp.HeatingSetpointWeekday[h - 1],"F","C").get
          htgssn_summer.addValue(time,val)
        end
        heatingsetpoint.setWinterDesignDaySchedule(htgssn_winDesSch)
        htgssn_winter = heatingsetpoint.winterDesignDaySchedule
        htgssn_winter.setName("HeatingSetPointScheduleWinter")
        htgssn_winter.clearValues
        for h in 1..24
          time = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(hsp.HeatingSetpointWeekday[h - 1],"F","C").get
          htgssn_winter.addValue(time,val)
        end

        coolingsetpoint = OpenStudio::Model::ScheduleRuleset.new(model)
        coolingsetpoint.setName("CoolingSetPoint")

        clgssn_rule_days = []
        for m in 1..12
          date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
          date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
          clgssn_rule = OpenStudio::Model::ScheduleRule.new(coolingsetpoint)
          clgssn_rule.setName("CoolingSetPointSchedule%02d" % m.to_s)
          clgssn_rule_day = clgssn_rule.daySchedule
          clgssn_rule_day.setName("CoolingSetPointSchedule%02dd" % m.to_s)
          for h in 1..24
            time = OpenStudio::Time.new(0,h,0,0)
            if cooling_season["CoolingSeasonSchedule%02d" % m.to_s] == 1.0
              val = OpenStudio::convert(csp.CoolingSetpointWeekday[h - 1],"F","C").get
            else
              val = 1000
            end
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
        coolingsetpoint.setSummerDesignDaySchedule(clgssn_sumDesSch)
        clgssn_summer = coolingsetpoint.summerDesignDaySchedule
        clgssn_summer.setName("CoolingSetPointScheduleSummer")
        clgssn_summer.clearValues
        for h in 1..24
          time = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(csp.CoolingSetpointWeekday[h - 1],"F","C").get
          clgssn_summer.addValue(time,val)
        end
        coolingsetpoint.setWinterDesignDaySchedule(clgssn_winDesSch)
        clgssn_winter = coolingsetpoint.winterDesignDaySchedule
        clgssn_winter.setName("CoolingSetPointScheduleWinter")
        clgssn_winter.clearValues
        for h in 1..24
          time = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(csp.CoolingSetpointWeekday[h - 1],"F","C").get
          clgssn_winter.addValue(time,val)
        end

        if controlType == 4 or controlType == 2 or controlType == 1

          thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint)
          thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint)

        #   sched_type = heatingsetpoint.scheduleTypeLimits.get
        #   sched_type.setName("TEMPERATURE")
        #   sched_type.setLowerLimitValue(-60)
        #   sched_type.setUpperLimitValue(200)
        #   sched_type.setNumericType("Continuous")
        #   sched_type.resetUnitType
        #
        #   sched_type = coolingsetpoint.scheduleTypeLimits.get
        #   sched_type.setName("TEMPERATURE")
        #   sched_type.setLowerLimitValue(-60)
        #   sched_type.setUpperLimitValue(200)
        #   sched_type.setNumericType("Continuous")
        #   sched_type.resetUnitType
        #
        # elsif controlType == 2
        #
        #   thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint)
        #
        #   sched_type = coolingsetpoint.scheduleTypeLimits.get
        #   sched_type.setName("TEMPERATURE")
        #   sched_type.setLowerLimitValue(-60)
        #   sched_type.setUpperLimitValue(200)
        #   sched_type.setNumericType("Continuous")
        #   sched_type.resetUnitType
        #
        # elsif controlType == 1
        #
        #   thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint)
        #
        #   sched_type = heatingsetpoint.scheduleTypeLimits.get
        #   sched_type.setName("TEMPERATURE")
        #   sched_type.setLowerLimitValue(-60)
        #   sched_type.setUpperLimitValue(200)
        #   sched_type.setNumericType("Continuous")
        #   sched_type.resetUnitType

        end

        thermalzone.setThermostatSetpointDualSetpoint(thermostatsetpointdualsetpoint)

        if controlType == 4
          runner.registerInfo("Set the thermostat '#{thermalzone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{thermalzone.name}' with heating setpoint schedule '#{heatingsetpoint.name}' and cooling setpoint schedule '#{coolingsetpoint.name}'")
        elsif controlType == 2
          runner.registerInfo("Set the thermostat '#{thermalzone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{thermalzone.name}' with cooling setpoint schedule '#{coolingsetpoint.name}'")
        elsif controlType == 1
          runner.registerInfo("Set the thermostat '#{thermalzone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{thermalzone.name}' with heating setpoint schedule '#{heatingsetpoint.name}'")
        end

      end

    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessHeatingandCoolingSetpoints.new.registerWithApplication