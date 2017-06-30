#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessConstructionsWindows < OpenStudio::Measure::ModelMeasure

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
    args = OpenStudio::Measure::OSArgumentVector.new

    # #make a choice argument for window sub surfaces
    # sub_surfaces_args = Geometry.get_sub_surfaces(model.getSubSurfaces, "window")
    # sub_surfaces_args << Constants.Auto
    # sub_surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("sub_surface", sub_surfaces_args, false)
    # sub_surface.setDisplayName("Subsurface(s)")
    # sub_surface.setDescription("Select the sub surface(s) to assign constructions.")
    # sub_surface.setDefaultValue(Constants.Auto)
    # args << sub_surface    
    
    #make an argument for entering front window u-factor
    ufactor_front = OpenStudio::Measure::OSArgument::makeDoubleArgument("ufactor_front",true)
    ufactor_front.setDisplayName("Front U-Factor")
    ufactor_front.setUnits("Btu/hr-ft^2-R")
    ufactor_front.setDescription("The heat transfer coefficient of the windows on the front facade.")
    ufactor_front.setDefaultValue(0.37)
    args << ufactor_front

    #make an argument for entering back window u-factor
    ufactor_back = OpenStudio::Measure::OSArgument::makeDoubleArgument("ufactor_back",true)
    ufactor_back.setDisplayName("Back U-Factor")
    ufactor_back.setUnits("Btu/hr-ft^2-R")
    ufactor_back.setDescription("The heat transfer coefficient of the windows on the back facade.")
    ufactor_back.setDefaultValue(0.37)
    args << ufactor_back

    #make an argument for entering left window u-factor
    ufactor_left = OpenStudio::Measure::OSArgument::makeDoubleArgument("ufactor_left",true)
    ufactor_left.setDisplayName("Left U-Factor")
    ufactor_left.setUnits("Btu/hr-ft^2-R")
    ufactor_left.setDescription("The heat transfer coefficient of the windows on the left facade.")
    ufactor_left.setDefaultValue(0.37)
    args << ufactor_left

    #make an argument for entering right window u-factor
    ufactor_right = OpenStudio::Measure::OSArgument::makeDoubleArgument("ufactor_right",true)
    ufactor_right.setDisplayName("Right U-Factor")
    ufactor_right.setUnits("Btu/hr-ft^2-R")
    ufactor_right.setDescription("The heat transfer coefficient of the windows on the right facade.")
    ufactor_right.setDefaultValue(0.37)
    args << ufactor_right

    #make an argument for entering front window shgc
    shgc_front = OpenStudio::Measure::OSArgument::makeDoubleArgument("shgc_front",true)
    shgc_front.setDisplayName("Front SHGC")
    shgc_front.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows on the front facade.")
    shgc_front.setDefaultValue(0.3)
    args << shgc_front

    #make an argument for entering back window shgc
    shgc_back = OpenStudio::Measure::OSArgument::makeDoubleArgument("shgc_back",true)
    shgc_back.setDisplayName("Back SHGC")
    shgc_back.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows on the back facade.")
    shgc_back.setDefaultValue(0.3)
    args << shgc_back

    #make an argument for entering left window shgc
    shgc_left = OpenStudio::Measure::OSArgument::makeDoubleArgument("shgc_left",true)
    shgc_left.setDisplayName("Left SHGC")
    shgc_left.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows on the left facade.")
    shgc_left.setDefaultValue(0.3)
    args << shgc_left

    #make an argument for entering right window shgc
    shgc_right = OpenStudio::Measure::OSArgument::makeDoubleArgument("shgc_right",true)
    shgc_right.setDisplayName("Right SHGC")
    shgc_right.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows on the right facade.")
    shgc_right.setDefaultValue(0.3)
    args << shgc_right

    #make an argument for entering heating shade multiplier
    heating_shade_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_shade_mult",true)
    heating_shade_mult.setDisplayName("Heating Shade Multiplier")
    heating_shade_mult.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    heating_shade_mult.setDefaultValue(0.7)
    args << heating_shade_mult

    #make an argument for entering cooling shade multiplier
    cooling_shade_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_shade_mult",true)
    cooling_shade_mult.setDisplayName("Cooling Shade Multiplier")
    cooling_shade_mult.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    cooling_shade_mult.setDefaultValue(0.7)
    args << cooling_shade_mult

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # sub_surface_s = runner.getOptionalStringArgumentValue("sub_surface",user_arguments)
    # if not sub_surface_s.is_initialized
      # sub_surface_s = Constants.Auto
    # else
      # sub_surface_s = sub_surface_s.get
    # end
    
    facades = [Constants.FacadeFront, Constants.FacadeBack, Constants.FacadeLeft, Constants.FacadeRight]
    
    # loop thru all the spaces
    sub_surfaces = {Constants.FacadeFront=>[], Constants.FacadeBack=>[],
                    Constants.FacadeLeft=>[], Constants.FacadeRight=>[]}
                    
    # if sub_surface_s == Constants.Auto
      model.getSpaces.each do |space|
          space.surfaces.each do |surface|
              surface.subSurfaces.each do |subSurface|
                  next unless subSurface.subSurfaceType.downcase.include? "window"
                  facade = Geometry.get_facade_for_surface(surface)
                  sub_surfaces[facade] << subSurface
              end
          end
      end
    # else
      # model.getSubSurfaces.each do |sub_surface|
          # next unless sub_surface.name.to_s == sub_surface_s
          # facade = Geometry.get_facade_for_surface(sub_surface.surface.get)
          # sub_surfaces[facade] << sub_surface
      # end
    # end
    
    # Continue if no applicable sub surfaces
    if sub_surfaces[Constants.FacadeFront].empty? and sub_surfaces[Constants.FacadeBack].empty? and sub_surfaces[Constants.FacadeLeft].empty? and sub_surfaces[Constants.FacadeRight].empty?
      runner.registerAsNotApplicable("Measure not applied because no windows were found.")
      return true
    end
    
    ufactors = {}
    ufactors[Constants.FacadeFront] = OpenStudio::convert(runner.getDoubleArgumentValue("ufactor_front",user_arguments),"Btu/hr*ft^2*R","W/m^2*K").get
    ufactors[Constants.FacadeBack] = OpenStudio::convert(runner.getDoubleArgumentValue("ufactor_back",user_arguments),"Btu/hr*ft^2*R","W/m^2*K").get
    ufactors[Constants.FacadeLeft] = OpenStudio::convert(runner.getDoubleArgumentValue("ufactor_left",user_arguments),"Btu/hr*ft^2*R","W/m^2*K").get
    ufactors[Constants.FacadeRight] = OpenStudio::convert(runner.getDoubleArgumentValue("ufactor_right",user_arguments),"Btu/hr*ft^2*R","W/m^2*K").get
    shgcs = {}
    shgcs[Constants.FacadeFront] = runner.getDoubleArgumentValue("shgc_front",user_arguments)
    shgcs[Constants.FacadeBack] = runner.getDoubleArgumentValue("shgc_back",user_arguments)
    shgcs[Constants.FacadeLeft] = runner.getDoubleArgumentValue("shgc_left",user_arguments)
    shgcs[Constants.FacadeRight] = runner.getDoubleArgumentValue("shgc_right",user_arguments)
    
    #error checking
    facades.each do |facade|
      if ufactors[facade] <= 0
        runner.registerError("Invalid #{facade} window U-factor.")
        return false
      end
      if shgcs[facade] <= 0
        runner.registerError("Invalid #{facade} window SHGC.")
        return false
      end
    end

    intShadeHeatingMultiplier = runner.getDoubleArgumentValue("heating_shade_mult",user_arguments)
    intShadeCoolingMultiplier = runner.getDoubleArgumentValue("cooling_shade_mult",user_arguments)

    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
        return false
    end
    
    heating_season, cooling_season = HVAC.calc_heating_and_cooling_seasons(model, weather, runner)
    if heating_season.nil? or cooling_season.nil?
        return false
    end
    
    sc = nil
    if intShadeCoolingMultiplier < 1 or intShadeHeatingMultiplier < 1
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

        day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
        day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]    

        # WindowShadingSchedule
        sched_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
        sched_type.setName("FRACTION")
        sched_type.setLowerLimitValue(0)
        sched_type.setUpperLimitValue(1)
        sched_type.setNumericType("Continuous")
        
        # Interior Shading Schedule
        sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameWindowShading + " schedule", Array.new(24, 1), Array.new(24, 1), cooling_season)
        if not sch.validated?
            return false
        end

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
        sm.setConductivity(10000)
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
        sc.setSchedule(sch.schedule)
        
    end
    
    msgs = []
    facades.each do |facade|
    
        # Define materials
        glaz_mat = GlazingMaterial.new(name="GlazingMaterial#{facade}", ufactor=ufactors[facade], shgc=shgcs[facade] * intShadeHeatingMultiplier)
        
        # Set paths
        path_fracs = [1]
        
        # Define construction
        window = Construction.new(path_fracs)
        window.add_layer(glaz_mat, true)
        
        # Create and assign construction to surfaces
        if not window.create_and_assign_constructions(sub_surfaces[facade], runner, model, name="WindowConstruction#{facade}")
            return false
        end
        
        sc_msg = ""
        if sc.nil?
            # Remove any existing shading controls
            objects_to_remove = []
            sub_surfaces[facade].each do |sub_surface|
                next if not sub_surface.shadingControl.is_initialized
                shade_control = sub_surface.shadingControl.get
                if shade_control.shadingMaterial.is_initialized
                    objects_to_remove << shade_control.shadingMaterial.get
                end
                if shade_control.schedule.is_initialized
                    objects_to_remove << shade_control.schedule.get
                end
                objects_to_remove << shade_control
                sub_surface.resetShadingControl
            end
            objects_to_remove.uniq.each do |object|
                begin
                    object.remove
                rescue
                    # no op
                end
            end
        else
            # Add shading controls
            sc_msg = " and interior shades"
            sub_surfaces[facade].each do |sub_surface|
                sub_surface.setShadingControl(sc)
            end
        end
        
        msgs << "Construction#{sc_msg} added to #{sub_surfaces[facade].size.to_s} window(s)."
        
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    # Reporting
    msgs.each do |msg|
        runner.registerInfo(msg)
    end
    runner.registerFinalCondition("All windows have been assigned constructions.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWindows.new.registerWithApplication