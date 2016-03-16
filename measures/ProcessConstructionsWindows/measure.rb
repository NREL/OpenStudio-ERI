#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWindows < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Window Construction"
  end
  
  def description
    return "This measure assigns a construction to windows. This measure also creates the interior shading schedule, which is based on shade multipliers and the heating and cooling season logic defined in the Building America House Simulation Protocols."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for windows. Finds sub surfaces and sets applicable constructions. Using interior heating and cooling shading multipliers and the Building America heating and cooling season logic, creates schedule rulesets for window shade and shading control."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for entering optional window u-factor
    userdefined_ufactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ufactor",false)
    userdefined_ufactor.setDisplayName("U-Value")
	userdefined_ufactor.setUnits("Btu/hr-ft^2-R")
	userdefined_ufactor.setDescription("The heat transfer coefficient of the windows.")
    userdefined_ufactor.setDefaultValue(0.37)
    args << userdefined_ufactor

    #make an argument for entering optional window shgc
    userdefined_shgc = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shgc",false)
    userdefined_shgc.setDisplayName("SHGC")
	userdefined_shgc.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening.")
    userdefined_shgc.setDefaultValue(0.3)
    args << userdefined_shgc

    #make an argument for entering optional window u-factor
    userdefined_intshadeheatingmult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedintshadeheatingmult",false)
    userdefined_intshadeheatingmult.setDisplayName("Heating Shade Multiplier")
	userdefined_intshadeheatingmult.setDescription("Interior shading multiplier for heating season.")
    userdefined_intshadeheatingmult.setDefaultValue(0.7)
    args << userdefined_intshadeheatingmult

    #make an argument for entering optional window shgc
    userdefined_intshadecoolingmult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedintshadecoolingmult",false)
    userdefined_intshadecoolingmult.setDisplayName("Cooling Shade Multiplier")
	userdefined_intshadecoolingmult.setDescription("Interior shading multiplier for cooling season.")
    userdefined_intshadecoolingmult.setDefaultValue(0.7)
    args << userdefined_intshadecoolingmult

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # loop thru all the spaces
    sub_surfaces = []
    spaces = model.getSpaces
    spaces.each do |space|
        space.surfaces.each do |surface|
            surface.subSurfaces.each do |subSurface|
                next unless subSurface.subSurfaceType.downcase.include? "window"
                sub_surfaces << subSurface
            end
        end
    end
    
    # Continue if no applicable sub surfaces
    if sub_surfaces.empty?
      return true
    end    
    
    userdefined_ufactor = runner.getDoubleArgumentValue("ufactor",user_arguments)
    userdefined_shgc = runner.getDoubleArgumentValue("shgc",user_arguments)

    ufactor = OpenStudio::convert(userdefined_ufactor,"Btu/hr*ft^2*R","W/m^2*K").get
    shgc = userdefined_shgc

    intShadeCoolingMonths = nil
    intShadeHeatingMultiplier = runner.getDoubleArgumentValue("userdefinedintshadeheatingmult",user_arguments)
    intShadeCoolingMultiplier = runner.getDoubleArgumentValue("userdefinedintshadecoolingmult",user_arguments)

    weather = WeatherProcess.new(model,runner)
    if weather.error?
        return false
    end
    
    # Process the windows
    window_shade_cooling_season, window_shade_multiplier = _processInteriorShadingSchedule(weather, intShadeCoolingMonths, intShadeCoolingMultiplier, intShadeHeatingMultiplier)

    # Shades

    # EnergyPlus doesn't like shades that absorb no heat, transmit no heat or reflect no heat.
    if intShadeCoolingMultiplier == 1
        intShadeCoolingMultiplier = 0.999
    end

    if intShadeHeatingMultiplier == 1
        intShadeHeatingMultiplier = 0.999
    end

    total_shade_trans = intShadeCoolingMultiplier / intShadeHeatingMultiplier * 0.999
    total_shade_abs = 0.00001
    total_shade_ref = 1 - total_shade_trans - total_shade_abs

    day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

    # WindowShadingSchedule
    sched_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
    sched_type.setName("FRACTION")
    sched_type.setLowerLimitValue(0)
    sched_type.setUpperLimitValue(1)
    sched_type.setNumericType("Continuous")

    ish_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    ish_ruleset.setName("WindowShadingSchedule")

    ish_ruleset.setScheduleTypeLimits(sched_type)

    ish_rule_days = []
    for m in 1..12
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
        ish_rule = OpenStudio::Model::ScheduleRule.new(ish_ruleset)
        ish_rule.setName("WindowShadingSchedule%02d" % m.to_s)
        ish_rule_day = ish_rule.daySchedule
        ish_rule_day.setName("WindowShadingSchedule%02dd" % m.to_s)
        for h in 1..24
            time = OpenStudio::Time.new(0,h,0,0)
            val = window_shade_cooling_season[m - 1]
            ish_rule_day.addValue(time,val)
        end
        ish_rule_days << ish_rule_day
        ish_rule.setApplySunday(true)
        ish_rule.setApplyMonday(true)
        ish_rule.setApplyTuesday(true)
        ish_rule.setApplyWednesday(true)
        ish_rule.setApplyThursday(true)
        ish_rule.setApplyFriday(true)
        ish_rule.setApplySaturday(true)
        ish_rule.setStartDate(date_s)
        ish_rule.setEndDate(date_e)
    end

    sumDesSch = ish_rule_days[6]
    winDesSch = ish_rule_days[0]
    ish_ruleset.setSummerDesignDaySchedule(sumDesSch)
    ish_summer = ish_ruleset.summerDesignDaySchedule
    ish_summer.setName("WindowShadingScheduleSummer")
    ish_ruleset.setWinterDesignDaySchedule(winDesSch)
    ish_winter = ish_ruleset.winterDesignDaySchedule
    ish_winter.setName("WindowShadingScheduleWinter")

    # CoolingShade
    sm = OpenStudio::Model::Shade.new(model)
    sm.setName("CoolingShade")
    sm.setSolarTransmittance(total_shade_trans)
    sm.setSolarReflectance(total_shade_ref)
    sm.setVisibleTransmittance(total_shade_trans)
    sm.setVisibleReflectance(total_shade_ref)
    sm.setThermalHemisphericalEmissivity(total_shade_abs)
    sm.setThermalTransmittance(total_shade_trans)
    sm.setThickness(0.0001)
    sm.setConductivity(10000.0)
    sm.setShadetoGlassDistance(0.001)
    sm.setTopOpeningMultiplier(0)
    sm.setBottomOpeningMultiplier(0)
    sm.setLeftSideOpeningMultiplier(0)
    sm.setRightSideOpeningMultiplier(0)
    sm.setAirflowPermeability(0)

    # WindowShadingControl
    sc = OpenStudio::Model::ShadingControl.new(sm)
    sc.setName("WindowShadingControl")
    sc.setShadingType("InteriorShade")
    sc.setShadingControlType("OnIfScheduleAllows")
    sc.setSchedule(ish_ruleset)

    # WindowShades
    sched_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
    sched_type.setName("MULTIPLIER")
    #sched_type.setLowerLimitValue(0)
    #sched_type.setUpperLimitValue(1)
    sched_type.setNumericType("Continuous")

    ish_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    ish_ruleset.setName("WindowShades")

    ish_ruleset.setScheduleTypeLimits(sched_type)

    ish_rule_days = []
    for m in 1..12
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
        ish_rule = OpenStudio::Model::ScheduleRule.new(ish_ruleset)
        ish_rule.setName("WindowShades%02d" % m.to_s)
        ish_rule_day = ish_rule.daySchedule
        ish_rule_day.setName("WindowShades%02dd" % m.to_s)
        for h in 1..24
            time = OpenStudio::Time.new(0,h,0,0)
            val = window_shade_multiplier[m - 1]
            ish_rule_day.addValue(time,val)
        end
        ish_rule_days << ish_rule_day
        ish_rule.setApplySunday(true)
        ish_rule.setApplyMonday(true)
        ish_rule.setApplyTuesday(true)
        ish_rule.setApplyWednesday(true)
        ish_rule.setApplyThursday(true)
        ish_rule.setApplyFriday(true)
        ish_rule.setApplySaturday(true)
        ish_rule.setStartDate(date_s)
        ish_rule.setEndDate(date_e)
    end

    sumDesSch = ish_rule_days[6]
    winDesSch = ish_rule_days[0]
    ish_ruleset.setSummerDesignDaySchedule(sumDesSch)
    ish_summer = ish_ruleset.summerDesignDaySchedule
    ish_summer.setName("WindowShadesSummer")
    ish_ruleset.setWinterDesignDaySchedule(winDesSch)
    ish_winter = ish_ruleset.winterDesignDaySchedule
    ish_winter.setName("WindowShadesWinter")

    # Define materials
    glaz_mat = GlazingMaterial.new(name="GlazingMaterial", ufactor=ufactor, shgc=shgc * intShadeHeatingMultiplier)
    
    # Set paths
    path_fracs = [1]
    
    # Define construction
    window = Construction.new(path_fracs)
    window.addlayer(glaz_mat, true)
    
    # Create and apply construction to surfaces
    if not window.create_and_assign_constructions(sub_surfaces, runner, model, "WindowConstruction")
        return false
    end
    
    # Apply shading controls
    sub_surfaces.each do |sub_surface|
        sub_surface.setShadingControl(sc)
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)    
    
    return true
 
  end #end the run method

  def _processInteriorShadingSchedule(weather, intShadeCoolingMonths, intShadeCoolingMultiplier, intShadeHeatingMultiplier)
    # Assigns window shade multiplier and shading cooling season for each month.

    #if not intShadeCoolingMonths.nil?
    #  cooling_season = intShadeCoolingMonths.item # TODO: what is this?
    #else
    #  cooling_season = [0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0]
    #end

    monthly_temps = weather.data.MonthlyAvgDrybulbs
    heat_design_db = weather.design.HeatingDrybulb

    # create basis lists with zero for every month
    cooling_season_temp_basis = Array.new(monthly_temps.length, 0.0)
    heating_season_temp_basis = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      if temp < 66.0
        heating_season_temp_basis[i] = 1.0
      elsif temp >= 66.0
        cooling_season_temp_basis[i] = 1.0
      end

      if (i == 0 or i == 11) and heat_design_db < 59.0
        heating_season_temp_basis[i] = 1.0
      elsif i == 6 or i == 7
        cooling_season_temp_basis[i] = 1.0
      end
    end

    cooling_season = Array.new(monthly_temps.length, 0.0)
    heating_season = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      # Heating overlaps with cooling at beginning of summer
      if i == 0 # January
        prevmonth = 11 # December
      else
        prevmonth = i - 1
      end

      if (heating_season_temp_basis[i] == 1.0 or (cooling_season_temp_basis[prevmonth] == 0.0 and cooling_season_temp_basis[i] == 1.0))
        heating_season[i] = 1.0
      else
        heating_season[i] = 0.0
      end

      if (cooling_season_temp_basis[i] == 1.0 or (heating_season_temp_basis[prevmonth] == 0.0 and heating_season_temp_basis[i] == 1.0))
        cooling_season[i] = 1.0
      else
        cooling_season[i] = 0.0
      end
    end

    # Find the first month of cooling and add one month
    (1...12).to_a.each do |i|
      if cooling_season[i] == 1.0
        cooling_season[i - 1] = 1.0
        break
      end
    end

    
    window_shade_multiplier = []
    window_shade_cooling_season = cooling_season
    (0...Constants.MonthNames.length).to_a.each do |i|
      if cooling_season[i] == 1.0
        window_shade_multiplier << intShadeCoolingMultiplier
      else
        window_shade_multiplier << intShadeHeatingMultiplier
      end
    end

    # Interior Shading Schedule

    return window_shade_cooling_season, window_shade_multiplier

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWindows.new.registerWithApplication