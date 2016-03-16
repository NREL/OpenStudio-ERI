# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsCMU < OpenStudio::Ruleset::ModelUserScript
    
  # human readable name
  def name
    return "Set Residential Exterior CMU Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns a CMU construction to above-grade exterior walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of CMU constructions for above-grade walls between finished space and outside."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
        
    #make a double argument for thickness of the cmu block
    userdefined_cmuthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcmuthickness", true)
    userdefined_cmuthickness.setDisplayName("CMU Block Thickness")
    userdefined_cmuthickness.setUnits("in")
    userdefined_cmuthickness.setDescription("Thickness of the CMU portion of the wall.")
    userdefined_cmuthickness.setDefaultValue(6.0)
    args << userdefined_cmuthickness
    
    #make a double argument for conductivity of the cmu block
    userdefined_cmuconductivity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcmuconductivity", false)
    userdefined_cmuconductivity.setDisplayName("CMU Conductivity")
    userdefined_cmuconductivity.setUnits("Btu-in/hr-ft^2-R")
    userdefined_cmuconductivity.setDescription("Overall conductivity of the finished CMU block.")
    userdefined_cmuconductivity.setDefaultValue(5.33)
    args << userdefined_cmuconductivity 
    
    #make a double argument for density of the cmu block
    userdefined_cmudensity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcmudensity", false)
    userdefined_cmudensity.setDisplayName("CMU Density")
    userdefined_cmudensity.setUnits("lb/ft^3")
    userdefined_cmudensity.setDescription("The density of the finished CMU block.")
    userdefined_cmudensity.setDefaultValue(119.0)
    args << userdefined_cmudensity      
    
    #make a double argument for framing factor
    userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", false)
    userdefined_framingfrac.setDisplayName("Framing Factor")
    userdefined_framingfrac.setUnits("frac")
    userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.076)
    args << userdefined_framingfrac
    
    #make a double argument for furring insulation R-value
    userdefined_furringr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfurringr", false)
    userdefined_furringr.setDisplayName("Furring Insulation R-value")
    userdefined_furringr.setUnits("hr-ft^2-R/Btu")
    userdefined_furringr.setDescription("R-value of the insulation filling the furring cavity.")
    userdefined_furringr.setDefaultValue(0.0)
    args << userdefined_furringr
    
    #make a double argument for furring cavity depth
    userdefined_furringcavdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfurringcavdepth", false)
    userdefined_furringcavdepth.setDisplayName("Furring Cavity Depth")
    userdefined_furringcavdepth.setUnits("in")
    userdefined_furringcavdepth.setDescription("The depth of the interior furring cavity. User zero for no furring strips.")
    userdefined_furringcavdepth.setDefaultValue(1.0)
    args << userdefined_furringcavdepth 
    
    #make a double argument for furring stud spacing
    userdefined_furringstudspacing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfurringstudspacing", false)
    userdefined_furringstudspacing.setDisplayName("Furring Stud Spacing")
    userdefined_furringstudspacing.setUnits("in")
    userdefined_furringstudspacing.setDescription("Spacing of studs in the furring.")
    userdefined_furringstudspacing.setDefaultValue(24.0)
    args << userdefined_furringstudspacing  
        
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
      return true
    end     
        
    # CMU / Furring
    cmuThickness = runner.getDoubleArgumentValue("userdefinedcmuthickness",user_arguments)
    cmuConductivity = runner.getDoubleArgumentValue("userdefinedcmuconductivity",user_arguments)
    cmuDensity = runner.getDoubleArgumentValue("userdefinedcmudensity",user_arguments)
    cmuFramingFactor = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)
    cmuFurringInsRvalue = runner.getDoubleArgumentValue("userdefinedfurringr",user_arguments)
    cmuFurringCavityDepth = runner.getDoubleArgumentValue("userdefinedfurringcavdepth",user_arguments)
    cmuFurringStudSpacing = runner.getDoubleArgumentValue("userdefinedfurringstudspacing",user_arguments)

    # Process the CMU walls
    
    # Define materials
    mat_cmu = Material.new(name=nil, thick_in=cmuThickness, mat_base=BaseMaterial.Concrete, cond=OpenStudio.convert(cmuConductivity,"in","ft").get, dens=cmuDensity)
    mat_framing = Material.new(name=nil, thick_in=cmuThickness, mat_base=BaseMaterial.Wood)
    if cmuFurringCavityDepth != 0
        mat_furring = Material.new(name=nil, thick_in=cmuFurringCavityDepth, mat_base=BaseMaterial.Wood, cond=OpenStudio.convert(cmuFurringCavityDepth,"in","ft").get / cmuFurringInsRvalue)
        if cmuFurringInsRvalue.nil? or cmuFurringInsRvalue == 0
            mat_furring_cavity = Material.AirCavity(cmuFurringCavityDepth)
        else
            mat_furring_cavity = Material.new(name=nil, thick_in=cmuFurringCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio.convert(cmuFurringCavityDepth,"in","ft").get / cmuFurringInsRvalue)
        end
    end
    
    # Set paths
    if cmuFurringCavityDepth != 0
        stud_frac = 1.5 / cmuFurringStudSpacing
        cavity_frac = 1.0 - (stud_frac + cmuFramingFactor)
        path_fracs = [cmuFramingFactor, stud_frac, cavity_frac]
    else # No furring:
        path_fracs = [cmuFramingFactor, 1.0 - cmuFramingFactor]
    end
    
    # Define construction
    cmu_wall = Construction.new(path_fracs)
    cmu_wall.addlayer(Material.AirFilmVertical, false)
    cmu_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    if cmuFurringCavityDepth != 0
        cmu_wall.addlayer([mat_furring, mat_furring, mat_furring_cavity], true, "Furring")
        cmu_wall.addlayer([mat_framing, mat_cmu, mat_cmu], true, "CMU")
    else
        cmu_wall.addlayer([mat_framing, mat_cmu], true)
    end
    cmu_wall.addlayer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    cmu_wall.addlayer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    cmu_wall.addlayer(Material.AirFilmOutside, false)
        
    # Create and apply construction to surfaces
    if not cmu_wall.create_and_assign_constructions(surfaces, runner, model, "ExtInsFinWall")
        return false
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)        
        
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsCMU.new.registerWithApplication
