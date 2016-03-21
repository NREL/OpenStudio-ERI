# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsExteriorInsulatedWallsSteelStud < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Exterior Steel Stud Wall Construction"
  end

  # human readable description
  def description
    return "This measure assigns a steel stud construction to above-grade exterior walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of steel stud constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of nominal cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcavr", true)
    userdefined_instcavr.setDisplayName("Cavity Insulation Nominal R-value")
    userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
    userdefined_instcavr.setDescription("Refers to the R-value of the cavity insulation and not the overall R-value of the assembly.")
    userdefined_instcavr.setDefaultValue(13.0)
    args << userdefined_instcavr
    
    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"
    
    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Cavity Install Grade")
    selected_installgrade.setDescription("Installation grade as defined by RESNET standard. 5% of the cavity is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade

    #make a double argument for wall cavity depth
    selected_cavdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("selectedcavitydepth", true)
    selected_cavdepth.setDisplayName("Cavity Depth")
    selected_cavdepth.setUnits("in")
    selected_cavdepth.setDescription("Depth of the stud cavity. 3.5\" for 2x4s, 5.5\" for 2x6s, etc.")
    selected_cavdepth.setDefaultValue("3.5")
    args << selected_cavdepth
    
    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
    selected_insfills.setDisplayName("Insulation Fills Cavity")
    selected_insfills.setDescription("When the insulation does not completely fill the depth of the cavity, air film resistances are added to the insulation R-value.")
    selected_insfills.setDefaultValue(true)
    args << selected_insfills
    
    #make a double argument for framing factor
    selected_ffactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("selectedffactor", true)
    selected_ffactor.setDisplayName("Framing Factor")
    selected_ffactor.setUnits("frac")
    selected_ffactor.setDescription("The fraction of a wall assembly that is comprised of structural framing.")
    selected_ffactor.setDefaultValue("0.25")
    args << selected_ffactor

    #make a double argument for correction factor
    userdefined_corrfact = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcorrfact", true)
    userdefined_corrfact.setDisplayName("Correction Factor")
    userdefined_corrfact.setDescription("The parallel path correction factor, as specified in Table C402.1.4.1 of the 2015 IECC as well as ASHRAE Standard 90.1, is used to determine the thermal resistance of wall assemblies containing metal framing.")
    userdefined_corrfact.setDefaultValue(0.46)
    args << userdefined_corrfact

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Above-grade wall between finished space and outdoors
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
    ssWallCavityInsRvalueNominal = runner.getDoubleArgumentValue("userdefinedcavr",user_arguments)
    ssWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    ssWallCavityDepth = runner.getDoubleArgumentValue("selectedcavitydepth",user_arguments)
    ssWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)  
    ssWallFramingFactor = runner.getDoubleArgumentValue("selectedffactor",user_arguments)
    ssWallCorrectionFactor = runner.getDoubleArgumentValue("userdefinedcorrfact",user_arguments)  
    
    # Validate inputs
    if ssWallCavityInsRvalueNominal < 0.0
        runner.registerError("Cavity Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if ssWallCavityDepth <= 0.0
        runner.registerError("Cavity Depth must be greater than 0.")
        return false
    end
    if ssWallFramingFactor < 0.0 or ssWallFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if ssWallCorrectionFactor < 0.0 or ssWallCorrectionFactor > 1.0
        runner.registerError("Correction Factor must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end

    # Process the steel stud walls
    
    # Define materials
    eR = ssWallCavityInsRvalueNominal * ssWallCorrectionFactor # The effective R-value of the cavity insulation with steel stud framing
    if eR > 0
        if ssWallCavityInsFillsCavity
            # Insulation
            mat_cavity = Material.new(name=nil, thick_in=ssWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(ssWallCavityDepth,"in","ft").get / eR)
        else
            # Insulation plus air gap when insulation thickness < cavity depth
            mat_cavity = Material.new(name=nil, thick_in=ssWallCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(ssWallCavityDepth,"in","ft").get / (eR + Gas.AirGapRvalue))
        end
    else
        # Empty cavity
        mat_cavity = Material.AirCavity(ssWallCavityDepth)
    end
    mat_gap = Material.AirCavity(ssWallCavityDepth)
    
    # Set paths
    gapFactor = Construction.GetWallGapFactor(ssWallInstallGrade, ssWallFramingFactor, ssWallCavityInsRvalueNominal)
    path_fracs = [1 - gapFactor, gapFactor]

    # Define constructions
    steel_stud_wall = Construction.new(path_fracs)
    steel_stud_wall.addlayer(Material.AirFilmVertical, false)
    steel_stud_wall.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    steel_stud_wall.addlayer([mat_cavity, mat_gap], true, "StudAndCavity")
    steel_stud_wall.addlayer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    steel_stud_wall.addlayer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    steel_stud_wall.addlayer(Material.AirFilmOutside, false)

    # Create and apply construction to surfaces
    if not steel_stud_wall.create_and_assign_constructions(surfaces, runner, model, "ExtInsFinWall")
        return false
    end

    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsExteriorInsulatedWallsSteelStud.new.registerWithApplication
