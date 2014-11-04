#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsWindows < OpenStudio::Ruleset::ModelUserScript

  class InteriorShading
    def initialize(intShadeCoolingMonths, intShadeCoolingMultiplier, intShadeHeatingMultiplier)
      @intShadeCoolingMultiplier = intShadeCoolingMultiplier
      @intShadeHeatingMultiplier = intShadeHeatingMultiplier
      @intShadeCoolingMonths = intShadeCoolingMonths
    end

    def IntShadeCoolingMonths
      return @intShadeCoolingMonths
    end

    def IntShadeCoolingMultiplier
      return @intShadeCoolingMultiplier
    end

    def IntShadeHeatingMultiplier
      return @intShadeHeatingMultiplier
    end
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsWindows"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    material_handles = OpenStudio::StringVector.new
    material_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    material_args = model.getSimpleGlazings
    material_args_hash = {}
    material_args.each do |material_arg|
      material_args_hash[material_arg.name.to_s] = material_arg
    end

    #looping through sorted hash of model objects
    material_args_hash.sort.map do |key,value|
      material_handles << value.handle.to_s
      material_display_names << key
    end

    # #make a choice argument for window glazing
    # selected_windowglazing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedwindowglazing", material_handles, material_display_names, false)
    # selected_windowglazing.setDisplayName("Window simple glazing. For manually entering window simple glazing properties, leave blank.")
    # args << selected_windowglazing

    #make an argument for entering optional window u-factor
    userdefined_ufactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ufactor",false)
    userdefined_ufactor.setDisplayName("U-Value [Btu/hr-ft^2-R].")
    userdefined_ufactor.setDefaultValue(0.0)
    args << userdefined_ufactor

    #make an argument for entering optional window shgc
    userdefined_shgc = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("shgc",false)
    userdefined_shgc.setDisplayName("SHGC.")
    userdefined_shgc.setDefaultValue(0.0)
    args << userdefined_shgc

    #make an argument for entering optional window u-factor
    userdefined_intshadeheatingmult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedintshadeheatingmult",false)
    userdefined_intshadeheatingmult.setDisplayName("Heating shade multiplier.")
    userdefined_intshadeheatingmult.setDefaultValue(0.7)
    args << userdefined_intshadeheatingmult

    #make an argument for entering optional window shgc
    userdefined_intshadecoolingmult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedintshadecoolingmult",false)
    userdefined_intshadecoolingmult.setDisplayName("Cooling shade multiplier.")
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

    selected_windowglazing = runner.getOptionalWorkspaceObjectChoiceValue("selectedwindowglazing",user_arguments,model)
    if selected_windowglazing.empty?
      userdefined_ufactor = runner.getDoubleArgumentValue("ufactor",user_arguments)
      userdefined_shgc = runner.getDoubleArgumentValue("shgc",user_arguments)
    end

    if userdefined_ufactor.nil?
      ufactor = OpenStudio::convert(selected_ufactor.get.to_SimpleGlazing.get.getUFactor.value,"Btu/hr*ft*R","W/m*K").get
      shgc = selected_shgc.get.to_SimpleGlazing.get.getSolarHeatGainCoefficient.value
    else
      ufactor = OpenStudio::convert(userdefined_ufactor,"Btu/hr*ft^2*R","W/m^2*K").get
      shgc = userdefined_shgc
    end

    intShadeCoolingMonths = nil
    intshadeheatingmult = runner.getDoubleArgumentValue("userdefinedintshadeheatingmult",user_arguments)
    intshadecoolingmult = runner.getDoubleArgumentValue("userdefinedintshadecoolingmult",user_arguments)

    # Create the material class instances
    ish = InteriorShading.new(intShadeCoolingMonths, intshadecoolingmult, intshadeheatingmult)

    # Create the sim object
    sim = Sim.new(model)

    # Process the windows
    window_shade_cooling_season, window_shade_multiplier = sim._processInteriorShadingSchedule(ish)

    # Shades

    # EnergyPlus doesn't like shades that absorb no heat, transmit no heat or reflect no heat.
    if intshadecoolingmult == 1
      intshadecoolingmult = 0.999
    end

    if intshadeheatingmult == 1
      intshadeheatingmult = 0.999
    end

    total_shade_trans = intshadecoolingmult / intshadeheatingmult * 0.999
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

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      shadingcontrol_hash = {}
      surfaces = space.surfaces
      surfaces.each do |surface|
        subSurfaces = surface.subSurfaces
        subSurfaces.each do |subSurface|
          if subSurface.subSurfaceType.include? "Window"
            name = subSurface.name
            glazingName = "#{name}-Win"
            constName = "#{name}-Glass"
            sg = OpenStudio::Model::SimpleGlazing.new(model)
            sg.setName(glazingName)
            sg.setUFactor(ufactor)
            sg.setSolarHeatGainCoefficient(shgc * intshadeheatingmult)
            c = OpenStudio::Model::Construction.new(model)
            c.setName(constName)
            c.insertLayer(0,sg)
            subSurface.resetConstruction
            subSurface.setConstruction(c)
            subSurface.setShadingControl(sc)
            constructions_hash[name.to_s] = [subSurface.subSurfaceType,surface.name.to_s,constName]
            shadingcontrol_hash[name.to_s] = [subSurface.subSurfaceType,surface.name.to_s,sc.name]
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Sub Surface '#{key}' of Sub Surface Type '#{value[0]}', attached to Surface '#{value[1]}' which is attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}', was assigned Construction '#{value[2]}'")
      end
      shadingcontrol_hash.map do |key,value|
        runner.registerInfo("Sub Surface '#{key}' of Sub Surface Type '#{value[0]}', attached to Surface '#{value[1]}' which is attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}', was assigned Shading Control '#{value[2]}'")
      end
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWindows.new.registerWithApplication