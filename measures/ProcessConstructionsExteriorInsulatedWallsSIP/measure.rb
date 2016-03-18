# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsSIP < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Exterior SIP Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns a SIP construction to above-grade exterior walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of SIP constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of the sip insulation
    userdefined_sipinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsipinsr", true)
    userdefined_sipinsr.setDisplayName("Nominal Insulation R-value")
    userdefined_sipinsr.setUnits("hr-ft^2-R/Btu")
    userdefined_sipinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_sipinsr.setDefaultValue(17.5)
    args << userdefined_sipinsr

    #make a double argument for thickness of the sip insulation
    userdefined_sipinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsipinsthickness", true)
    userdefined_sipinsthickness.setDisplayName("Insulation Thickness")
    userdefined_sipinsthickness.setUnits("in")
    userdefined_sipinsthickness.setDescription("Thickness of the insulating core of the SIP.")
    userdefined_sipinsthickness.setDefaultValue(3.625)
    args << userdefined_sipinsthickness 

    #make a double argument for framing factor
    userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", true)
    userdefined_framingfrac.setDisplayName("Framing Factor")
    userdefined_framingfrac.setUnits("frac")
    userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.156)
    args << userdefined_framingfrac 
    
    #make a choice argument for model objects
    intsheathing_display_names = OpenStudio::StringVector.new
    intsheathing_display_names << Constants.MaterialOSB
    intsheathing_display_names << Constants.MaterialGypsum
    intsheathing_display_names << Constants.MaterialGypcrete
    
    #make a string argument for interior sheathing type
    selected_intsheathingtype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedintsheathingtype", intsheathing_display_names, true)
    selected_intsheathingtype.setDisplayName("Interior Sheathing Type")
    selected_intsheathingtype.setDescription("The interior sheathing type of the SIP wall.")
    selected_intsheathingtype.setDefaultValue(Constants.MaterialOSB)
    args << selected_intsheathingtype   
    
    #make a double argument for thickness of the interior sheathing
    userdefined_sipintsheathingthick = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsipintsheathingthick", true)
    userdefined_sipintsheathingthick.setDisplayName("Interior Sheathing Thickness")
    userdefined_sipintsheathingthick.setUnits("in")
    userdefined_sipintsheathingthick.setDescription("The thickness of the interior sheathing.")
    userdefined_sipintsheathingthick.setDefaultValue(0.44)
    args << userdefined_sipintsheathingthick

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Wall between finished space and outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end     
    
    # Get inputs
    sipInsRvalue = runner.getDoubleArgumentValue("userdefinedsipinsr",user_arguments)
    sipInsThickness = runner.getDoubleArgumentValue("userdefinedsipinsthickness",user_arguments)
    sipFramingFactor = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)
    sipIntSheathingType = runner.getStringArgumentValue("selectedintsheathingtype",user_arguments)
    sipIntSheathingThick = runner.getDoubleArgumentValue("userdefinedsipintsheathingthick",user_arguments)
    
    # Validate inputs
    if sipInsRvalue <= 0.0
        runner.registerError("Nominal Insulation R-value must be greater than 0.")
        return false
    end
    if sipInsThickness <= 0.0
        runner.registerError("Insulation Thickness must be greater than 0.")
        return false
    end
    if sipFramingFactor < 0.0 or sipFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if sipIntSheathingThick <= 0.0
        runner.registerError("Interior Sheathing Thickness must be greater than 0.")
        return false
    end
    
    # Process the SIP walls
    
    # Define materials
    spline_thick_in = 0.5
    ins_thick_in = sipInsThickness - (2.0 * spline_thick_in) # in
    if sipIntSheathingType == Constants.MaterialOSB
        mat_int_sheath = Material.new(name=nil, thick_in=sipIntSheathingThick, mat_base=BaseMaterial.Wood)
    elsif sipIntSheathingType == Constants.MaterialGypsum
        mat_int_sheath = Material.new(name=nil, thick_in=sipIntSheathingThick, mat_base=BaseMaterial.Gypsum)
    elsif sipIntSheathingType == Constants.MaterialGypcrete
        mat_int_sheath = Material.new(name=nil, thick_in=sipIntSheathingThick, mat_base=BaseMaterial.Gypcrete)
    end
    mat_framing_inner_outer = Material.new(name=nil, thick_in=spline_thick_in, mat_base=BaseMaterial.Wood)
    mat_framing_middle = Material.new(name=nil, thick_in=ins_thick_in, mat_base=BaseMaterial.Wood)
    mat_spline = Material.new(name=nil, thick_in=spline_thick_in, mat_base=BaseMaterial.Wood)
    mat_ins_inner_outer = Material.new(name=nil, thick_in=spline_thick_in, mat_base=BaseMaterial.InsulationRigid, cond=OpenStudio.convert(sipInsThickness,"in","ft").get / sipInsRvalue)
    mat_ins_middle = Material.new(name=nil, thick_in=ins_thick_in, mat_base=BaseMaterial.InsulationRigid, cond=OpenStudio.convert(sipInsThickness,"in","ft").get / sipInsRvalue)
    
    # Set paths
    spline_frac = 4.0 / 48.0 # One 4" spline for every 48" wide panel
    cavity_frac = 1.0 - (spline_frac + sipFramingFactor)
    path_fracs = [sipFramingFactor, spline_frac, cavity_frac]

    # Define construction
    sip_wall = Construction.new(path_fracs)
    sip_wall.addlayer(Material.AirFilmVertical, false)
    sip_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    sip_wall.addlayer(mat_int_sheath, true, "IntSheathing")
    sip_wall.addlayer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], true, "SplineLayerInner")
    sip_wall.addlayer([mat_framing_middle, mat_ins_middle, mat_ins_middle], true, "WallIns")
    sip_wall.addlayer([mat_framing_inner_outer, mat_spline, mat_ins_inner_outer], true, "SplineLayerOuter")
    sip_wall.addlayer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    sip_wall.addlayer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    sip_wall.addlayer(Material.AirFilmOutside, false)

    # Create and apply construction to surfaces
    if not sip_wall.create_and_assign_constructions(surfaces, runner, model, "ExtInsFinWall")
        return false
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner) 

    return true

  end

end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsSIP.new.registerWithApplication
