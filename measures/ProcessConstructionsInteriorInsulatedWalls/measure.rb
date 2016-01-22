#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class ProcessConstructionsInteriorInsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Interzonal Wall Construction"
  end
  
  def description
    return "This measure assigns a construction to the interzonal walls."
  end
  
  def modeler_description
    return "Calculates material layer properties of insulated constructions for the interzonal walls between the living space and the garage. Finds surfaces adjacent to the living space and garage and sets applicable constructions."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for partition wall mass thickness
    userdefined_partitionwallmassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassth", false)
    userdefined_partitionwallmassth.setDisplayName("Partition Wall Mass: Thickness")
    userdefined_partitionwallmassth.setUnits("in")
    userdefined_partitionwallmassth.setDescription("Thickness of the layer.")
    userdefined_partitionwallmassth.setDefaultValue(0.5)
    args << userdefined_partitionwallmassth

    #make a double argument for partition wall mass conductivity
    userdefined_partitionwallmasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasscond", false)
    userdefined_partitionwallmasscond.setDisplayName("Partition Wall Mass: Conductivity")
    userdefined_partitionwallmasscond.setUnits("Btu-in/h-ft^2-R")
    userdefined_partitionwallmasscond.setDescription("Conductivity of the layer.")
    userdefined_partitionwallmasscond.setDefaultValue(1.1112)
    args << userdefined_partitionwallmasscond

    #make a double argument for partition wall mass density
    userdefined_partitionwallmassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmassdens", false)
    userdefined_partitionwallmassdens.setDisplayName("Partition Wall Mass: Density")
    userdefined_partitionwallmassdens.setUnits("lb/ft^3")
    userdefined_partitionwallmassdens.setDescription("Density of the layer.")
    userdefined_partitionwallmassdens.setDefaultValue(50.0)
    args << userdefined_partitionwallmassdens

    #make a double argument for partition wall mass specific heat
    userdefined_partitionwallmasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedpartitionwallmasssh", false)
    userdefined_partitionwallmasssh.setDisplayName("Partition Wall Mass: Specific Heat")
    userdefined_partitionwallmasssh.setUnits("Btu/lb-R")
    userdefined_partitionwallmasssh.setDescription("Specific heat of the layer.")
    userdefined_partitionwallmasssh.setDefaultValue(0.2)
    args << userdefined_partitionwallmasssh

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "2x4"
    studsize_display_names << "2x6"
    studsize_display_names << "2x8"
    studsize_display_names << "2x10"
    studsize_display_names << "2x12"
    studsize_display_names << "2x14"

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, true)
    selected_studsize.setDisplayName("Interzonal Walls: Cavity Depth")
    selected_studsize.setUnits("in")
    selected_studsize.setDescription("Depth of the stud cavity.")
    selected_studsize.setDefaultValue("2x4")
    args << selected_studsize

    #make a choice argument for model objects
    spacing_display_names = OpenStudio::StringVector.new
    spacing_display_names << "16 in o.c."
    spacing_display_names << "24 in o.c."

    #make a choice argument for wood stud spacing
    selected_spacing = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedspacing", spacing_display_names, true)
    selected_spacing.setDisplayName("Interzonal Walls: Stud Spacing")
    selected_spacing.setUnits("in")
    selected_spacing.setDescription("The on-center spacing between studs in a wall assembly.")
    selected_spacing.setDefaultValue("16 in o.c.")
    args << selected_spacing

    #make a double argument for nominal R-value of installed cavity insulation
    userdefined_instcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinstcavr", true)
    userdefined_instcavr.setDisplayName("Interzonal Walls: Cavity Insulation Installed R-value")
    userdefined_instcavr.setUnits("hr-ft^2-R/Btu")
    userdefined_instcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_instcavr.setDefaultValue(13.0)
    args << userdefined_instcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
    selected_installgrade.setDisplayName("Interzonal Walls: Cavity Install Grade")
    selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade

    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
    selected_insfills.setDisplayName("Interzonal Walls: Insulation Fills Cavity")
    selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(true)
    args << selected_insfills

    #make a double argument for rigid insulation thickness of wall cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Interzonal Walls: Continuous Insulation Thickness")
    userdefined_rigidinsthickness.setUnits("in")
    userdefined_rigidinsthickness.setDescription("The thickness of the continuous insulation.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness
    
    #make a double argument for rigid insulation R-value of wall cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Interzonal Walls: Continuous Insulation Nominal R-value")
    userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
    userdefined_rigidinsr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_rigidinsr.setDefaultValue(0)
    args << userdefined_rigidinsr

    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type
    
    #make a choice argument for garage space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.GarageSpaceType)
        space_type_args << Constants.GarageSpaceType
    end
    garage_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_space_type", space_type_args, true)
    garage_space_type.setDisplayName("Garage space type")
    garage_space_type.setDescription("Select the garage space type")
    garage_space_type.setDefaultValue(Constants.GarageSpaceType)
    args << garage_space_type   
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Space Type
    living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
    garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    if garage_space_type.nil?
        # If the building has no garage, no constructions are assigned and we continue by returning True
        return true
    end 

    # Partition Wall Mass
    partitionWallMassThickness = runner.getDoubleArgumentValue("userdefinedpartitionwallmassth",user_arguments)
    partitionWallMassConductivity = runner.getDoubleArgumentValue("userdefinedpartitionwallmasscond",user_arguments)
    partitionWallMassDensity = runner.getDoubleArgumentValue("userdefinedpartitionwallmassdens",user_arguments)
    partitionWallMassSpecHeat = runner.getDoubleArgumentValue("userdefinedpartitionwallmasssh",user_arguments)
    
    # Cavity
    intWallCavityDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstudsize",user_arguments)]
    intWallFramingFactor = {"16 in o.c."=>0.25, "24 in o.c."=>0.22}[runner.getStringArgumentValue("selectedspacing",user_arguments)]
    intWallCavityInsRvalueInstalled = runner.getDoubleArgumentValue("userdefinedinstcavr",user_arguments)
    intWallInstallGrade = {"I"=>1, "II"=>2, "III"=>3}[runner.getStringArgumentValue("selectedinstallgrade",user_arguments)]
    intWallCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)
    
    # Rigid
    intWallContInsThickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
    intWallContInsRvalue = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
    rigidInsDensity = BaseMaterial.InsulationRigid.rho
    rigidInsSpecificHeat = BaseMaterial.InsulationRigid.Cp

    weather = WeatherProcess.new(model,runner,header_only=true)
    if weather.error?
        return false
    end

    # Process the wood stud walls
    mat_part_wall_mass = Material.MassPartitionWall(partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat)
    sc_thick, sc_cond, sc_dens, sc_sh = _processConstructionsInteriorInsulatedWalls(intWallCavityDepth, intWallCavityInsRvalueInstalled, intWallContInsThickness, intWallContInsRvalue, intWallCavityInsFillsCavity, intWallInstallGrade, intWallFramingFactor, partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat, mat_part_wall_mass.Rvalue, weather.header.LocalPressure)

    # Create the material layers

    # PartitionWallMass
    pwm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    pwm.setName("PartitionWallMass")
    pwm.setRoughness("Rough")
    pwm.setThickness(OpenStudio::convert(mat_part_wall_mass.thick,"ft","m").get)
    pwm.setConductivity(OpenStudio::convert(mat_part_wall_mass.k,"Btu/hr*ft*R","W/m*K").get)
    pwm.setDensity(OpenStudio::convert(mat_part_wall_mass.rho,"lb/ft^3","kg/m^3").get)
    pwm.setSpecificHeat(OpenStudio::convert(mat_part_wall_mass.Cp,"Btu/lb*R","J/kg*K").get)
    pwm.setThermalAbsorptance(mat_part_wall_mass.TAbs)
    pwm.setSolarAbsorptance(mat_part_wall_mass.SAbs)
    pwm.setVisibleAbsorptance(mat_part_wall_mass.VAbs)

    # IntWallIns
    iwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    iwi.setName("IntWallIns")
    iwi.setRoughness("Rough")
    iwi.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    iwi.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    iwi.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    iwi.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)

    if intWallContInsRvalue != 0

      # Set Rigid Insulation Layer Properties
      # IntWallRigidIns
      iwri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      iwri.setName("IntWallRigidIns")
      iwri.setThickness(OpenStudio::convert(intWallContInsThickness,"in","m").get)
      iwri.setConductivity(OpenStudio::convert(OpenStudio::convert(intWallContInsThickness,"in","ft").get / intWallContInsRvalue,"Btu/hr*ft*R","W/m*K").get)
      iwri.setDensity(OpenStudio::convert(BaseMaterial.InsulationRigid.rho,"lb/ft^3","kg/m^3").get) # lbm/ft^3
      iwri.setSpecificHeat(OpenStudio::convert(BaseMaterial.InsulationRigid.Cp,"Btu/lb*R","J/kg*K").get) # Btu/lbm*F

      # UnfinInsFinWall
      materials = []
      materials << iwri
      materials << iwi
      materials << pwm
      unfininsfinwall = OpenStudio::Model::Construction.new(materials)
      unfininsfinwall.setName("UnfinInsFinWall")
      
    else

      # UnfinInsFinWall
      materials = []
      materials << iwi
      materials << pwm
      unfininsfinwall = OpenStudio::Model::Construction.new(materials)
      unfininsfinwall.setName("UnfinInsFinWall")
      
    end

    # RevUnfinInsFinWall
    revunfininsfinwall = unfininsfinwall.reverseConstruction
    revunfininsfinwall.setName("RevUnfinInsFinWall")

    living_space_type.spaces.each do |living_space|
      living_space.surfaces.each do |living_surface|
        next unless ["wall"].include? living_surface.surfaceType.downcase
        adjacent_surface = living_surface.adjacentSurface
        next unless adjacent_surface.is_initialized
        adjacent_surface = adjacent_surface.get
        adjacent_surface_r = adjacent_surface.name.to_s
        adjacent_space_type_r = HelperMethods.get_space_type_from_surface(model, adjacent_surface_r)
        next unless [garage_space_type_r].include? adjacent_space_type_r
        living_surface.setConstruction(unfininsfinwall)
        runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{unfininsfinwall.name}'")
        adjacent_surface.setConstruction(revunfininsfinwall)        
        runner.registerInfo("Surface '#{adjacent_surface.name}', of Space Type '#{adjacent_space_type_r}' and with Surface Type '#{adjacent_surface.surfaceType}' and Outside Boundary Condition '#{adjacent_surface.outsideBoundaryCondition}', was assigned Construction '#{revunfininsfinwall.name}'")
      end   
    end

    return true
 
  end #end the run method

  def _processConstructionsInteriorInsulatedWalls(intWallCavityDepth, intWallCavityInsRvalueInstalled, intWallContInsThickness, intWallContInsRvalue, intWallCavityInsFillsCavity, intWallInstallGrade, intWallFramingFactor, partitionWallMassThickness, partitionWallMassConductivity, partitionWallMassDensity, partitionWallMassSpecHeat, partitionWallMassRvalue, localPressure)
    # Calculate R-value of Stud and Cavity Walls between two walls
    # where both interior and exterior spaces are not conditioned.

    # Set Furring insulation/air properties
    if intWallCavityInsRvalueInstalled == 0
      intWallCavityInsDens = Gas.AirInsideDensity(localPressure) # lbm/ft^3   Assumes that a cavity with an R-value of 0 is an air cavity
      intWallCavityInsSH = Gas.Air.Cp
    else
      intWallCavityInsDens = BaseMaterial.InsulationGenericDensepack.rho
      intWallCavityInsSH = BaseMaterial.InsulationGenericDensepack.Cp
    end

    overall_wall_Rvalue, gapFactor = get_interzonal_wall_r_assembly(intWallCavityDepth, intWallCavityInsRvalueInstalled, intWallContInsThickness, intWallContInsRvalue, intWallCavityInsFillsCavity, intWallInstallGrade, intWallFramingFactor, partitionWallMassThickness, OpenStudio::convert(partitionWallMassConductivity,"in","ft").get)

    bndry_wall_Rvalue = (overall_wall_Rvalue - (AirFilms.VerticalR * 2.0 + partitionWallMassRvalue + intWallContInsRvalue))

    sc_thick = OpenStudio::convert(intWallCavityDepth,"in","ft").get # ft
    sc_cond = sc_thick / bndry_wall_Rvalue # Btu/hr*ft*F
    sc_dens = intWallFramingFactor * BaseMaterial.Wood.rho + (1 - intWallFramingFactor - gapFactor) * intWallCavityInsDens + gapFactor * Gas.AirInsideDensity(localPressure) # lbm/ft^3
    sc_sh = (intWallFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - intWallFramingFactor - gapFactor) * intWallCavityInsSH * intWallCavityInsDens + gapFactor * Gas.Air.Cp * Gas.AirInsideDensity(localPressure)) / sc_dens # Btu/lbm*F

    return sc_thick, sc_cond, sc_dens, sc_sh

  end
  
  def get_interzonal_wall_r_assembly(intWallCavityDepth, intWallCavityInsRvalueInstalled, intWallContInsThickness, intWallContInsRvalue, intWallCavityInsFillsCavity, intWallInstallGrade, intWallFramingFactor, gypsumThickness, gypsumConductivity=nil)
      # Returns assemblu R-value for Other wall, including air films.

      intWallCavityInsRvalueInstalled = intWallCavityInsRvalueInstalled

      if gypsumConductivity.nil?
        gypsumConductivity = BaseMaterial.Gypsum.k
      end

      # Add air gap when insulation thickness < cavity depth
      if intWallCavityInsFillsCavity == false
        intWallCavityInsRvalueInstalled += Gas.AirGapRvalue
      end

      gapFactor = Construction.GetWallGapFactor(intWallInstallGrade, intWallFramingFactor)

      path_fracs = [intWallFramingFactor, 1 - intWallFramingFactor - gapFactor, gapFactor]

      interzonal_wall = Construction.new(path_fracs)

      # Interior Film
      interzonal_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.VerticalR])

      # Interior Finish (GWB)
      interzonal_wall.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get, conductivity_list=[gypsumConductivity])

      # Stud / Cavity Ins / Gap
      ins_k = OpenStudio::convert(intWallCavityDepth,"in","ft").get / intWallCavityInsRvalueInstalled
      gap_k = OpenStudio::convert(intWallCavityDepth,"in","ft").get / Gas.AirGapRvalue
      interzonal_wall.addlayer(thickness=OpenStudio::convert(intWallCavityDepth,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, ins_k, gap_k])

      # Rigid
      if intWallContInsRvalue > 0
        rigid_k = OpenStudio::convert(intWallContInsThickness,"in","ft").get / intWallContInsRvalue
        interzonal_wall.addlayer(thickness=OpenStudio::convert(intWallContInsThickness,"in","ft").get, conductivity_list=[rigid_k])
      end

      # Exterior Film
      interzonal_wall.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.VerticalR])

      return interzonal_wall.Rvalue_parallel, gapFactor

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInteriorInsulatedWalls.new.registerWithApplication