# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class ResidentialCeilingFan < OpenStudio::Ruleset::ModelUserScript

  class Unit
    def initialize
    end    
    attr_accessor(:unit_num, :living_zone, :finished_basement_zone, :above_grade_finished_floor_area, :cooling_setpoint_min, :num_bedrooms, :num_bathrooms, :finished_floor_area)
  end
  
  class Schedules
    def initialize
    end
    attr_accessor(:CeilingFan, :CeilingFansMaster)
  end

  # human readable name
  def name
    return "Set Residential Ceiling Fan"
  end

  # human readable description
  def description
    return "This measure..."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Uses..."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a string argument for coverage
    coverage = OpenStudio::Ruleset::OSArgument::makeStringArgument("coverage", true)
    coverage.setDisplayName("Coverage")
    coverage.setUnits("frac")
    coverage.setDescription("Fraction of house conditioned by fans where # fans = (above-grade finished floor area)/(% coverage)/300.")
    coverage.setDefaultValue("NA")
    args << coverage

    #make a string argument for specified number
    specified_num = OpenStudio::Ruleset::OSArgument::makeStringArgument("specified_num", true)
    specified_num.setDisplayName("Specified Number")
    specified_num.setUnits("#/unit")
    specified_num.setDescription("Total number of fans.")
    specified_num.setDefaultValue("1")
    args << specified_num
    
    #make a double argument for power
    power = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("power", true)
    power.setDisplayName("Power")
    power.setUnits("W")
    power.setDescription("Power consumption per fan assuming it runs at medium speed.")
    power.setDefaultValue(45.0)
    args << power
    
    #make choice arguments for control
    control_names = OpenStudio::StringVector.new
    control_names << Constants.CeilingFanControlTypical
    control_names << Constants.CeilingFanControlSmart
    control = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("control", control_names, true)
    control.setDisplayName("Control")
    control.setDescription("'Typical' indicates half of the fans will be on whenever the interior temperature is above the cooling setpoint; 'Smart' indicates 50% of the energy consumption of 'Typical.'")
    control.setDefaultValue(Constants.CeilingFanControlTypical)
    args << control 
    
    #make a bool argument for using benchmark energy
    use_benchmark_energy = OpenStudio::Ruleset::OSArgument::makeBoolArgument("use_benchmark_energy", true)
    use_benchmark_energy.setDisplayName("Use Benchmark Energy")
    use_benchmark_energy.setDescription("Use the energy value specified in the BA Benchmark: 77.3 + 0.0403 x FFA kWh/yr, where FFA is Finished Floor Area.")
    use_benchmark_energy.setDefaultValue(true)
    args << use_benchmark_energy
    
    #make a double argument for cooling setpoint offset
    cooling_setpoint_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cooling_setpoint_offset", true)
    cooling_setpoint_offset.setDisplayName("Cooling Setpoint Offset")
    cooling_setpoint_offset.setUnits("degrees F")
    cooling_setpoint_offset.setDescription("Increase in cooling set point due to fan usage.")
    cooling_setpoint_offset.setDefaultValue(0)
    args << cooling_setpoint_offset    
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    coverage = runner.getStringArgumentValue("coverage",user_arguments)
    unless coverage == "NA"
      coverage = coverage.to_f
    else
      coverage = nil
    end
    specified_num = runner.getStringArgumentValue("specified_num",user_arguments)
    unless specified_num == "NA"
      specified_num = specified_num.to_f
    else
      specified_num = nil
    end    
    power = runner.getDoubleArgumentValue("power",user_arguments)
    control = runner.getStringArgumentValue("control",user_arguments)
    use_benchmark_energy = runner.getBoolArgumentValue("use_benchmark_energy",user_arguments)
    cooling_setpoint_offset = runner.getDoubleArgumentValue("cooling_setpoint_offset",user_arguments)
    
    if use_benchmark_energy
      coverage = nil
      specified_num = nil
      power = nil
      control = nil
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end    
    
    # Remove any existing airflow objects
    HelperMethods.remove_object_from_osm_based_on_name(model, "OutputVariable", ["Schedule Value", "Zone Mean Air Temperature"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemSensor", ["CeilingFan_sch_", "Tin_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemActuator", ["CeilingFanScheduleOverride_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemProgram", ["CeilingFanScheduleProgram_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemProgramCallingManager", ["CeilingFanProgramManager_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "ElectricEquipmentDefinition", ["CeilingFans_", "Misc Elec Load_", "FBsmt Misc Elec Load_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "ScheduleRuleset", ["CeilingFan_"])
    
    units.each do |building_unit|
    
      unit = Unit.new
      unit.num_bedrooms, unit.num_bathrooms = Geometry.get_unit_beds_baths(model, building_unit, runner)
      unit_spaces = building_unit.spaces
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit_spaces)
      unit.unit_num = Geometry.get_unit_number(model, building_unit, runner)
      unit.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(unit_spaces, false, runner)
      unit.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(unit_spaces, false, runner)
    
      schedules = Schedules.new
    
      # Determine geometry for spaces and zones that are unit specific
      thermal_zones.each do |thermal_zone|
        if thermal_zone.name.to_s.start_with? Constants.LivingZone
          unit.living_zone = thermal_zone
        elsif thermal_zone.name.to_s.start_with? Constants.FinishedBasementZone
          unit.finished_basement_zone = thermal_zone
        end
      end
          
      # Determine the number of ceiling fans
      ceiling_fan_num = 0
      if not coverage.nil?
        # User has chosen to specify the number of fans by indicating
        # % coverage, where it is assumed that 100% coverage requires 1 fan
        # per 300 square feet.
        ceiling_fan_num = get_ceiling_fan_number(unit.above_grade_finished_floor_area, coverage)
      elsif not specified_num.nil?
        ceiling_fan_num = specified_num
      else
        ceiling_fan_num = 0
      end
      
      # Adjust the power consumption based on the occupancy control.
      # The default assumption is that when the fans are "on" half of the
      # fans will be used. This is consistent with the results from an FSEC
      # survey (described in FSEC-PF-306-96) and approximates the reasonable
      # assumption that during the night the bedroom fans will be on and all
      # of the other fans will be off while during the day the reverse will
      # be true. "Smart" occupancy control indicates that fans are used more
      # sparingly; in other words, fans are frequently turned off when rooms
      # are vacant. To approximate this kind of control, the overall fan
      # power consumption is reduced by 50%.Note that although the idea here
      # is that in reality "smart" control means that fans will be run for
      # fewer hours, it is modeled as a reduction in power consumption.

      if control == Constants.CeilingFanControlSmart
        ceiling_fan_control_factor = 0.25
      else
        ceiling_fan_control_factor = 0.5
      end
        
      # Determine the power draw for the ceiling fans.
      # The power consumption depends on the number of fans, the "standard"
      # power consumption per fan, the fan efficiency, and the fan occupancy
      # control. Rather than specifying usage via a schedule, as for most
      # other electrical uses, the fans will be modeled as "on" with a
      # constant power consumption whenever the interior space temperature
      # exceeds the cooling setpoint and "off" at all other times (this
      # on/off behavior is accomplished in DOE2.bmi using EQUIP-PWR-FT - see
      # comments there). Note that there is also a fan schedule that accounts
      # for cooling setpoint setups (it is assumed that fans will always be
      # off during the setup period).
      
      if ceiling_fan_num > 0
        ceiling_fans_max_power = ceiling_fan_num * power * ceiling_fan_control_factor / OpenStudio::convert(1.0,"kW","W").get # kW
      else
        ceiling_fans_max_power = 0
      end
      
      # Determine ceiling fan schedule.
      # In addition to turning the fans off when the interior space
      # temperature falls below the cooling setpoint (handled in DOE2.bmi by
      # EQUIP-PWR-FT), the fans should be turned off during any setup of the
      # cooling setpoint (based on the assumption that the occupants leave
      # the house at those times). Therefore the fan schedule specifies zero
      # power during the setup period and full power outside of the setup
      # period. Determine the lowest value of all of the hourly cooling setpoints.
      
      # Get cooling setpoints
      thermostatsetpointdualsetpoint = unit.living_zone.thermostatSetpointDualSetpoint
      coolingSetpointWeekday = Array.new(24, 10000)
      coolingSetpointWeekend = Array.new(24, 10000)
      if thermostatsetpointdualsetpoint.is_initialized
        thermostatsetpointdualsetpoint.get.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
          if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value < coolingSetpointWeekday[hour]
                coolingSetpointWeekday[hour] = OpenStudio::convert(value,"C","F").get + cooling_setpoint_offset
              end
            end
            if rule.daySchedule.values.all? {|x| x == 10000}
              rule.daySchedule.clearValues
              coolingSetpointWeekday.each_with_index do |value, hour|
                rule.daySchedule.addValue(OpenStudio::Time.new(0,hour+1,0,0), OpenStudio::convert(value,"F","C").get)
              end
            end
          end
          if rule.applySaturday and rule.applySunday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value < coolingSetpointWeekend[hour]
                coolingSetpointWeekend[hour] = OpenStudio::convert(value,"C","F").get + cooling_setpoint_offset
              end
            end
            if rule.daySchedule.values.all? {|x| x == 10000}          
              rule.daySchedule.clearValues
              coolingSetpointWeekend.each_with_index do |value, hour|
                rule.daySchedule.addValue(OpenStudio::Time.new(0,hour+1,0,0), OpenStudio::convert(value,"F","C").get)
              end
            end
          end
        end
      end    
      
      default_clg_sp = 76.0
      if coolingSetpointWeekday.all? {|x| x == 10000}
        runner.registerWarning("No cooling equipment found. Assuming #{default_clg_sp} F for ceiling fan operation.")
        coolingSetpointWeekday = Array.new(24, default_clg_sp)
        coolingSetpointWeekend = Array.new(24, default_clg_sp)
      end
      
      unit.cooling_setpoint_min = (coolingSetpointWeekday + coolingSetpointWeekend).min
      
      ceiling_fans_hourly_weekday = []
      ceiling_fans_hourly_weekend = []
    
      (0..23).to_a.each do |hour|
        if coolingSetpointWeekday[hour] > unit.cooling_setpoint_min
          ceiling_fans_hourly_weekday << 0
        else
          ceiling_fans_hourly_weekday << 1
        end
        if coolingSetpointWeekend[hour] > unit.cooling_setpoint_min
          ceiling_fans_hourly_weekend << 0
        else
          ceiling_fans_hourly_weekend << 1
        end      
      end

      schedules.CeilingFan = MonthWeekdayWeekendSchedule.new(model, runner, "CeilingFan_#{unit.unit_num}", ceiling_fans_hourly_weekday, ceiling_fans_hourly_weekend, Array.new(12, 1), mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)      
      
      unless schedules.CeilingFan.validated?
        return false
      end
      
      schedules.CeilingFansMaster = OpenStudio::Model::ScheduleConstant.new(model)
      schedules.CeilingFansMaster.setName("CeilingFansMaster_#{unit.unit_num}")
      schedules.CeilingFansMaster.setValue(1)
      
      # Ceiling Fans
      # As described in more detail in the schedules section, ceiling fans are controlled by two schedules, CeilingFan and CeilingFansMaster.
      # The program CeilingFanScheduleProgram checks to see if a cooling setpoint setup is in effect (by checking the sensor CeilingFan_sch) and
      # it checks the indoor temperature to see if it is less than the normal cooling setpoint. In either case, it turns the fans off.
      # Otherwise it turns the fans on.
      
      sens = 0.93
      lat = 0.021      
      conv = sens / 2.5
      rad = conv * 1.5
      
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName("CeilingFans_#{unit.unit_num}")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName("CeilingFans_#{unit.unit_num}")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setDesignLevel(OpenStudio::convert(ceiling_fans_max_power,"kW","W").get)
      equip_def.setFractionLatent(0)
      equip_def.setFractionRadiant(rad)
      equip_def.setFractionLost(0)
      equip.setSchedule(schedules.CeilingFansMaster)
      equip.setEndUseSubcategory("Misc_#{unit.unit_num}")
      
      # Sensor that reports the value of the schedule CeilingFan (0 if cooling setpoint setup is in effect, 1 otherwise).
      schedule_value_output_var = OpenStudio::Model::OutputVariable.new("Schedule Value", model)
      schedule_value_output_var.setName("Schedule Value")
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("CeilingFan_sch_#{unit.unit_num}")
      sensor.setKeyName("CeilingFan_#{unit.unit_num}")
      
      zone_mean_air_temp_output_var = OpenStudio::Model::OutputVariable.new("Zone Mean Air Temperature", model)
      zone_mean_air_temp_output_var.setName("Zone Mean Air Temperature")
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_temp_output_var)
      sensor.setName("Tin_#{unit.unit_num}")
      sensor.setKeyName(unit.living_zone.name.to_s)
      
      # Actuator that overrides the master ceiling fan schedule.
      actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(schedules.CeilingFansMaster, "Schedule:Constant", "Schedule Value")
      actuator.setName("CeilingFanScheduleOverride_#{unit.unit_num}")
      
      # Program that turns the ceiling fans off in the situations described above.
      program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      program.setName("CeilingFanScheduleProgram_#{unit.unit_num}")
      program.addLine("If CeilingFan_sch_#{unit.unit_num} == 0")
      program.addLine("Set CeilingFanScheduleOverride_#{unit.unit_num} = 0")
      # Subtract 0.1 from cooling setpoint to avoid fans cycling on and off with minor temperature variations.
      program.addLine("ElseIf Tin_#{unit.unit_num}<#{OpenStudio::convert(unit.cooling_setpoint_min-0.1-32.0,"R","K").get}")
      program.addLine("Set CeilingFanScheduleOverride_#{unit.unit_num} = 0")
      program.addLine("Else")
      program.addLine("Set CeilingFanScheduleOverride_#{unit.unit_num} = 1")
      program.addLine("EndIf")
      
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName("CeilingFanProgramManager_#{unit.unit_num}")
      program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
      program_calling_manager.addProgram(program)

      mel_multiplier = 1 # TODO: is this assumption ok?
      other_mel = get_other_mels(unit.num_bedrooms, unit.finished_floor_area, mel_multiplier, use_benchmark_energy)
    
      # Calculate daily total energy
      daily_misc_elec_energy = other_mel / 365.0
      
      misc_plug_load_maxval = 0.089 # TODO: what should this be?
      max_misc_elec_power = misc_plug_load_maxval * daily_misc_elec_energy # kW 
    
      max_mels_elect_living = max_misc_elec_power * (unit.above_grade_finished_floor_area / unit.finished_floor_area)
      
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName("Misc Elec Load_#{unit.unit_num}")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName("Misc Elec Load_#{unit.unit_num}")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setDesignLevel(OpenStudio::convert(max_mels_elect_living,"kW","W").get)
      equip_def.setFractionLatent(lat)
      equip_def.setFractionRadiant(rad)
      equip_def.setFractionLost(1 - lat - sens)
      equip.setSchedule(model.alwaysOnDiscreteSchedule) # TODO: what schedule to set here?
      equip.setEndUseSubcategory("Misc_#{unit.unit_num}")
    
      unless unit.finished_basement_zone.nil?

        max_mels_elect_fbsmnt = max_misc_elec_power * (OpenStudio::convert(unit.finished_basement_zone.floorArea,"m^2","ft^2").get / unit.finished_floor_area)
      
        equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        equip_def.setName("FBsmt Misc Elec Load_#{unit.unit_num}")
        equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
        equip.setName("FBsmt Misc Elec Load_#{unit.unit_num}")
        equip.setSpace(unit.living_zone.spaces[0])
        equip_def.setDesignLevel(OpenStudio::convert(max_mels_elect_fbsmnt,"kW","W").get)
        equip_def.setFractionLatent(lat)
        equip_def.setFractionRadiant(rad)
        equip_def.setFractionLost(1 - lat - sens)
        equip.setSchedule(model.alwaysOnDiscreteSchedule) # TODO: what schedule to set here?
        equip.setEndUseSubcategory("Misc_#{unit.unit_num}")
        
      end
      
    end
    
    return true

  end
  
  def get_ceiling_fan_number(above_grade_finished_floor_area, coverage)
    return (above_grade_finished_floor_area * coverage / 300.0).round(1)
  end
  
  def get_other_mels(num_beds, ffa, multiplier, use_benchmark_energy=false)
    # Returns kWh/yr for misc electric loads, as per the 2010 BA Benchmark.
    if use_benchmark_energy #add ceiling fan if is benchmark
      total_mel=(1185.4 + 180.2 * num_beds + 0.3188 * ffa) * multiplier
    else
      total_mel=(1108.1 + 180.2 * num_beds + 0.2785 * ffa) * multiplier
    end        
    return total_mel
  end
  
end

# register the measure to be used by the application
ResidentialCeilingFan.new.registerWithApplication
