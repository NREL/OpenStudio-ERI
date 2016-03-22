# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsICF < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Exterior ICF Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns an ICF construction to above-grade exterior walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of ICF constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of the icf insulation
    userdefined_icfinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfinsr", true)
    userdefined_icfinsr.setDisplayName("Nominal Insulation R-value")
    userdefined_icfinsr.setUnits("hr-ft^2-R/Btu")
    userdefined_icfinsr.setDescription("R-value of each insulating layer of the form.")
    userdefined_icfinsr.setDefaultValue(10.0)
    args << userdefined_icfinsr

    #make a double argument for thickness of the icf insulation
    userdefined_icfinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfinsthickness", true)
    userdefined_icfinsthickness.setDisplayName("Insulation Thickness")
    userdefined_icfinsthickness.setUnits("in")
    userdefined_icfinsthickness.setDescription("Thickness of each insulating layer of the form.")
    userdefined_icfinsthickness.setDefaultValue(2.0)
    args << userdefined_icfinsthickness 

    #make a double argument for thickness of the concrete
    userdefined_sipintsheathingthick = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedicfconcth", true)
    userdefined_sipintsheathingthick.setDisplayName("Concrete Thickness")
    userdefined_sipintsheathingthick.setUnits("in")
    userdefined_sipintsheathingthick.setDescription("The thickness of the concrete core of the ICF.")
    userdefined_sipintsheathingthick.setDefaultValue(4.0)
    args << userdefined_sipintsheathingthick

    #make a double argument for framing factor
    userdefined_framingfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedframingfrac", true)
    userdefined_framingfrac.setDisplayName("Framing Factor")
    userdefined_framingfrac.setUnits("frac")
    userdefined_framingfrac.setDescription("Total fraction of the wall that is framing for windows or doors.")
    userdefined_framingfrac.setDefaultValue(0.076)
    args << userdefined_framingfrac 
        
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
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end     
    
    # Get inputs
    icfInsRvalue = runner.getDoubleArgumentValue("userdefinedicfinsr",user_arguments)
    icfInsThickness = runner.getDoubleArgumentValue("userdefinedicfinsthickness",user_arguments)
    icfConcreteThickness = runner.getDoubleArgumentValue("userdefinedicfconcth",user_arguments)
    icfFramingFactor = runner.getDoubleArgumentValue("userdefinedframingfrac",user_arguments)

    # Validate inputs
    if icfInsRvalue <= 0.0
        runner.registerError("Nominal Insulation R-value must be greater than 0.")
        return false
    end
    if icfInsThickness <= 0.0
        runner.registerError("Insulation Thickness must be greater than 0.")
        return false
    end
    if icfConcreteThickness <= 0.0
        runner.registerError("Concrete Thickness must be greater than 0.")
        return false
    end
    if icfFramingFactor < 0.0 or icfFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end

    # Process the ICF walls
    
    # Define materials
    mat_ins = Material.new(name=nil, thick_in=icfInsThickness, mat_base=BaseMaterial.InsulationRigid, cond=OpenStudio.convert(icfInsThickness,"in","ft").get / icfInsRvalue)
    mat_conc = Material.new(name=nil, thick_in=icfConcreteThickness, mat_base=BaseMaterial.Concrete)
    mat_framing_inner_outer = Material.new(name=nil, thick_in=icfInsThickness, mat_base=BaseMaterial.Wood)
    mat_framing_middle = Material.new(name=nil, thick_in=icfConcreteThickness, mat_base=BaseMaterial.Wood)
    
    # Set paths
    path_fracs = [icfFramingFactor, 1.0 - icfFramingFactor]
    
    # Define construction
    icf_wall = Construction.new(path_fracs)
    icf_wall.addlayer(Material.AirFilmVertical, false)
    icf_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    icf_wall.addlayer([mat_framing_inner_outer, mat_ins], true, "ICFInsFormInner")
    icf_wall.addlayer([mat_framing_middle, mat_conc], true, "ICFConcrete")
    icf_wall.addlayer([mat_framing_inner_outer, mat_ins], true, "ICFInsFormOuter")
    icf_wall.addlayer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    icf_wall.addlayer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    icf_wall.addlayer(Material.AirFilmOutside, false)
    
    # Create and assign construction to surfaces
    if not icf_wall.create_and_assign_constructions(surfaces, runner, model, name="ExtInsFinWall")
        return false
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner) 

    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsICF.new.registerWithApplication
