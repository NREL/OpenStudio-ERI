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

        time = Array.new(24, 0)
        date_s = OpenStudio::Date::fromDayOfYear(1)
        date_e = OpenStudio::Date::fromDayOfYear(365)

        heatingsetpoint = OpenStudio::Model::ScheduleRuleset.new(model)
        heatingsetpoint.setName("HeatingSetPoint")

        for w in 1..2
          if w == 1
            htgsp_wkdy_rule = OpenStudio::Model::ScheduleRule.new(heatingsetpoint)
            htgsp_wkdy_rule.setName("HeatingSetPointWeekdayRule")
            htgsp_wkdy = htgsp_wkdy_rule.daySchedule
            htgsp_wkdy.setName("HeatingSetPointWeekday")
            for h in 1..24
              time[h] = OpenStudio::Time.new(0,h,0,0)
              val = OpenStudio::convert(hsp.HeatingSetpointWeekday[h - 1],"F","C").get
              htgsp_wkdy.addValue(time[h],val)
            end
            htgsp_wkdy_rule.setApplySunday(false)
            htgsp_wkdy_rule.setApplyMonday(true)
            htgsp_wkdy_rule.setApplyTuesday(true)
            htgsp_wkdy_rule.setApplyWednesday(true)
            htgsp_wkdy_rule.setApplyThursday(true)
            htgsp_wkdy_rule.setApplyFriday(true)
            htgsp_wkdy_rule.setApplySaturday(false)
            htgsp_wkdy_rule.setStartDate(date_s)
            htgsp_wkdy_rule.setEndDate(date_e)
          elsif w == 2
            htgsp_wknd_rule = OpenStudio::Model::ScheduleRule.new(heatingsetpoint)
            htgsp_wknd_rule.setName("HeatingSetPointWeekendRule")
            htgsp_wknd = htgsp_wknd_rule.daySchedule
            htgsp_wknd.setName("HeatingSetPointWeekend")
            for h in 1..24
              time[h] = OpenStudio::Time.new(0,h,0,0)
              val = OpenStudio::convert(hsp.HeatingSetpointWeekend[h - 1],"F","C").get
              htgsp_wknd.addValue(time[h],val)
            end
            htgsp_wknd_rule.setApplySunday(true)
            htgsp_wknd_rule.setApplyMonday(false)
            htgsp_wknd_rule.setApplyTuesday(false)
            htgsp_wknd_rule.setApplyWednesday(false)
            htgsp_wknd_rule.setApplyThursday(false)
            htgsp_wknd_rule.setApplyFriday(false)
            htgsp_wknd_rule.setApplySaturday(true)
            htgsp_wknd_rule.setStartDate(date_s)
            htgsp_wknd_rule.setEndDate(date_e)
          end
        end

        htgsp_DesSch = htgsp_wkdy
        heatingsetpoint.setSummerDesignDaySchedule(htgsp_DesSch)
        heatingsetpoint.setWinterDesignDaySchedule(htgsp_DesSch)
        htgsp_winter = heatingsetpoint.winterDesignDaySchedule
        htgsp_summer = heatingsetpoint.summerDesignDaySchedule
        htgsp_winter.setName("HeatingSetPointWinterDesignDay")
        htgsp_summer.setName("HeatingSetPointSummerDesignDay")
        htgsp_winter.clearValues
        htgsp_summer.clearValues
        for h in 1..24
          time[h] = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(70,"F","C").get
          htgsp_winter.addValue(time[h],val)
        end
        for h in 1..24
          time[h] = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(70,"F","C").get
          htgsp_summer.addValue(time[h],val)
        end

        coolingsetpoint = OpenStudio::Model::ScheduleRuleset.new(model)
        coolingsetpoint.setName("CoolingSetPoint")

        for w in 1..2
          if w == 1
            clgsp_wkdy_rule = OpenStudio::Model::ScheduleRule.new(coolingsetpoint)
            clgsp_wkdy_rule.setName("CoolingSetPointWeekdayRule")
            clgsp_wkdy = clgsp_wkdy_rule.daySchedule
            clgsp_wkdy.setName("CoolingSetPointWeekday")
            for h in 1..24
              time[h] = OpenStudio::Time.new(0,h,0,0)
              val = OpenStudio::convert(csp.CoolingSetpointWeekday[h - 1],"F","C").get
              clgsp_wkdy.addValue(time[h],val)
            end
            clgsp_wkdy_rule.setApplySunday(false)
            clgsp_wkdy_rule.setApplyMonday(true)
            clgsp_wkdy_rule.setApplyTuesday(true)
            clgsp_wkdy_rule.setApplyWednesday(true)
            clgsp_wkdy_rule.setApplyThursday(true)
            clgsp_wkdy_rule.setApplyFriday(true)
            clgsp_wkdy_rule.setApplySaturday(false)
            clgsp_wkdy_rule.setStartDate(date_s)
            clgsp_wkdy_rule.setEndDate(date_e)
          elsif w == 2
            clgsp_wknd_rule = OpenStudio::Model::ScheduleRule.new(coolingsetpoint)
            clgsp_wknd_rule.setName("CoolingSetPointWeekendRule")
            clgsp_wknd = clgsp_wknd_rule.daySchedule
            clgsp_wknd.setName("CoolingSetPointWeekend")
            for h in 1..24
              time[h] = OpenStudio::Time.new(0,h,0,0)
              val = OpenStudio::convert(csp.CoolingSetpointWeekend[h - 1],"F","C").get
              clgsp_wknd.addValue(time[h],val)
            end
            clgsp_wknd_rule.setApplySunday(true)
            clgsp_wknd_rule.setApplyMonday(false)
            clgsp_wknd_rule.setApplyTuesday(false)
            clgsp_wknd_rule.setApplyWednesday(false)
            clgsp_wknd_rule.setApplyThursday(false)
            clgsp_wknd_rule.setApplyFriday(false)
            clgsp_wknd_rule.setApplySaturday(true)
            clgsp_wknd_rule.setStartDate(date_s)
            clgsp_wknd_rule.setEndDate(date_e)
          end
        end

        clgsp_DesSch = clgsp_wkdy
        coolingsetpoint.setSummerDesignDaySchedule(clgsp_DesSch)
        coolingsetpoint.setWinterDesignDaySchedule(clgsp_DesSch)
        clgsp_summer = coolingsetpoint.summerDesignDaySchedule
        clgsp_winter = coolingsetpoint.winterDesignDaySchedule
        clgsp_summer.setName("CoolingSetPointSummerDesignDay")
        clgsp_winter.setName("CoolingSetPointWinterDesignDay")
        clgsp_summer.clearValues
        clgsp_winter.clearValues
        for h in 1..24
          time[h] = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(75,"F","C").get
          clgsp_summer.addValue(time[h],val)
        end
        for h in 1..24
          time[h] = OpenStudio::Time.new(0,h,0,0)
          val = OpenStudio::convert(75,"F","C").get
          clgsp_winter.addValue(time[h],val)
        end

        if controlType == 4

          thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint)
          thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint)

          # sched_type = heatingsetpoint.scheduleTypeLimits.get
          # sched_type.setName("TEMPERATURE")
          # sched_type.setLowerLimitValue(-60)
          # sched_type.setUpperLimitValue(200)
          # sched_type.setNumericType("Continuous")
          # sched_type.resetUnitType
          #
          # sched_type = coolingsetpoint.scheduleTypeLimits.get
          # sched_type.setName("TEMPERATURE")
          # sched_type.setLowerLimitValue(-60)
          # sched_type.setUpperLimitValue(200)
          # sched_type.setNumericType("Continuous")
          # sched_type.resetUnitType

        elsif controlType == 2

          thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint)

          # sched_type = coolingsetpoint.scheduleTypeLimits.get
          # sched_type.setName("TEMPERATURE")
          # sched_type.setLowerLimitValue(-60)
          # sched_type.setUpperLimitValue(200)
          # sched_type.setNumericType("Continuous")
          # sched_type.resetUnitType

        elsif controlType == 1

          thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint)

          # sched_type = heatingsetpoint.scheduleTypeLimits.get
          # sched_type.setName("TEMPERATURE")
          # sched_type.setLowerLimitValue(-60)
          # sched_type.setUpperLimitValue(200)
          # sched_type.setNumericType("Continuous")
          # sched_type.resetUnitType

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