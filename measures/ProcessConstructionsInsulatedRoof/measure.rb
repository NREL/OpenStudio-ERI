#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsInsulatedRoof < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Finished Roof Construction"
  end
  
  def description
    return "This measure assigns a construction to the roof of the living space."
  end
  
  def modeler_description
    return "Calculates material layer properties of finished constructions for the roof of the living space. Finds surfaces adjacent to the living space and sets applicable constructions."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for finished roof insulation R-value
    userdefined_frroofr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofr", false)
    userdefined_frroofr.setDisplayName("Finished Roof: Cavity Insulation Installed R-value")
	userdefined_frroofr.setUnits("hr-ft^2-R/Btu")
	userdefined_frroofr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_frroofr.setDefaultValue(30.0)
    args << userdefined_frroofr

	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Finished Roof: Insulation Fills Cavity")
	selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(false)
	args << selected_insfills

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "2x4"
    studsize_display_names << "2x6"
    studsize_display_names << "2x8"
    studsize_display_names << "2x10"
    studsize_display_names << "2x12"
    studsize_display_names << "2x14"

    #make a string argument for thickness of roof framing
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, true)
    selected_studsize.setDisplayName("Finished Roof: Cavity Depth")
	selected_studsize.setUnits("in")
	selected_studsize.setDescription("Thickness of roof framing.")
	selected_studsize.setDefaultValue("2x10")
    args << selected_studsize

    #make a choice argument for finished roof framing factor
    userdefined_frroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofff", false)
    userdefined_frroofff.setDisplayName("Finished Roof: Framing Factor")
	userdefined_frroofff.setUnits("frac")
	userdefined_frroofff.setDescription("The framing factor of the finished roof.")
    userdefined_frroofff.setDefaultValue(0.07)
    args << userdefined_frroofff

    #make a double argument for rigid insulation thickness of roof cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Finished Roof: Continuous Insulation Thickness")
	userdefined_rigidinsthickness.setUnits("in")
	userdefined_rigidinsthickness.setDescription("Thickness of rigid insulation added to the roof.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness

    #make a double argument for rigid insulation R-value of roof cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Finished Roof: Continuous Insulation Nominal R-value")
	userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_rigidinsr.setDescription("The nominal R-value of the continuous insulation.")
    userdefined_rigidinsr.setDefaultValue(0)
    args << userdefined_rigidinsr

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Ceiling Mass: Thickness")
	userdefined_gypthickness.setUnits("in")
	userdefined_gypthickness.setDescription("Gypsum layer thickness.")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Ceiling Mass: Num Layers")
	userdefined_gyplayers.setUnits("#")
	userdefined_gyplayers.setDescription("Integer number of layers of gypsum.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

    #make a double argument for roofing material emmisitivity of finished roof
    userdefined_roofmatemm = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatemm", false)
    userdefined_roofmatemm.setDisplayName("Roof Material: Emissivity.")
	userdefined_roofmatemm.setDescription("Infrared emissivity of the outside surface of the roof.")
    userdefined_roofmatemm.setDefaultValue(0.91)
    args << userdefined_roofmatemm

    #make a double argument for roofing material solar/visible absorptance of finished roof
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roof Material: Absorptivity")
	userdefined_roofmatabs.setDescription("The solar radiation absorptance of the outside roof surface, specified as a value between 0 and 1.")
    userdefined_roofmatabs.setDefaultValue(0.85)
    args << userdefined_roofmatabs

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

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    frRoofCavityInsRvalueInstalled = 0
    rigidInsThickness = 0
    rigidInsRvalue = 0

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end

    has_applicable_surfaces = false
	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless living_surface.surfaceType.downcase == "roofceiling" and living_surface.outsideBoundaryCondition.downcase == "outdoors"
        has_applicable_surfaces = true
        break
	  end	
	end
    unless has_applicable_surfaces
        return true
    end    
    
    # Roof Insulation
    selected_frroof = runner.getOptionalWorkspaceObjectChoiceValue("selectedfrroof",user_arguments,model)
    if selected_frroof.empty?
      frRoofCavityInsRvalueInstalled = runner.getDoubleArgumentValue("userdefinedfrroofr",user_arguments)
    end

    # Cavity
    frRoofCavityDepth = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}[runner.getStringArgumentValue("selectedstudsize",user_arguments)]
    frRoofCavityInsFillsCavity = runner.getBoolArgumentValue("selectedinsfills",user_arguments)

    # Roof Framing Factor
    frRoofFramingFactor = runner.getDoubleArgumentValue("userdefinedfrroofff",user_arguments)
    if not ( frRoofFramingFactor > 0.0 and frRoofFramingFactor < 1.0 )
      runner.registerError("Invalid finished roof framing factor")
      return false
    end

    # Rigid
    frRoofContInsThickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
    frRoofContInsRvalue = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)

    # Gypsum
    gypsumThickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    gypsumNumLayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    gypsumConductivity = Material.GypsumCeiling.k
    gypsumDensity = Material.GypsumCeiling.rho
    gypsumSpecificHeat = Material.GypsumCeiling.Cp
    gypsumThermalAbs = Material.GypsumCeiling.TAbs
    gypsumSolarAbs = Material.GypsumCeiling.SAbs
    gypsumVisibleAbs = Material.GypsumCeiling.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / Material.GypsumCeiling.k)

    # Roofing Material
    roofMatEmissivity = runner.getDoubleArgumentValue("userdefinedroofmatemm",user_arguments)
    roofMatAbsorptivity = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)

    highest_roof_pitch = 26.565 # FIXME: Currently hardcoded
    film_roof_R = AirFilms.RoofR(highest_roof_pitch)

    # Process the finished roof
    sc_thick, sc_cond, sc_dens, sc_sh, rigid_thick, rigid_cond, rigid_dens, rigid_sh = _processConstructionsInsulatedRoof(frRoofContInsThickness, frRoofContInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor, gypsumThickness, gypsumNumLayers, gypsumRvalue, film_roof_R)

    # RoofingMaterial
    mat_roof_mat = Material.RoofMaterial(roofMatEmissivity, roofMatAbsorptivity)
    roofmat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    roofmat.setName("RoofingMaterial")
    roofmat.setRoughness("Rough")
    roofmat.setThickness(OpenStudio::convert(mat_roof_mat.thick,"ft","m").get)
    roofmat.setConductivity(OpenStudio::convert(mat_roof_mat.k,"Btu/hr*ft*R","W/m*K").get)
    roofmat.setDensity(OpenStudio::convert(mat_roof_mat.rho,"lb/ft^3","kg/m^3").get)
    roofmat.setSpecificHeat(OpenStudio::convert(mat_roof_mat.Cp,"Btu/lb*R","J/kg*K").get)
    roofmat.setThermalAbsorptance(mat_roof_mat.TAbs)
    roofmat.setSolarAbsorptance(mat_roof_mat.SAbs)
    roofmat.setVisibleAbsorptance(mat_roof_mat.VAbs)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(Material.Plywood3_4in.thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(Material.Plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(Material.Plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(Material.Plywood3_4in.Cp,"Btu/lb*R","J/kg*K").get)

    # RigidRoofIns
    if frRoofContInsThickness > 0
      rri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      rri.setName("RigidRoofIns")
      rri.setRoughness("Rough")
      rri.setThickness(OpenStudio::convert(rigid_thick,"ft","m").get)
      rri.setConductivity(OpenStudio::convert(rigid_cond,"Btu/hr*ft*R","W/m*K").get)
      rri.setDensity(OpenStudio::convert(rigid_dens,"lb/ft^3","kg/m^3").get)
      rri.setSpecificHeat(OpenStudio::convert(rigid_sh,"Btu/lb*R","J/kg*K").get)
    end

    # RoofIns
    ri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ri.setName("RoofIns")
    ri.setRoughness("Rough")
    ri.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    ri.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    ri.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    ri.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)

    # Gypsum
    gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gypsum.setName("GypsumBoard-Ceiling")
    gypsum.setRoughness("Rough")
    gypsum.setThickness(OpenStudio::convert(gypsumThickness,"in","m").get)
    gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
    gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
    gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
    gypsum.setThermalAbsorptance(gypsumThermalAbs)
    gypsum.setSolarAbsorptance(gypsumSolarAbs)
    gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

    # FinInsExtRoof
    materials = []
    materials << roofmat
    materials << ply3_4
    if frRoofContInsThickness > 0
      materials << rri
      materials << ply3_4
    end
    materials << ri
    (0...gypsumNumLayers).to_a.each do |i|
      materials << gypsum
    end
    fininsextroof = OpenStudio::Model::Construction.new(materials)
    fininsextroof.setName("FinInsExtRoof")	

	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless living_surface.surfaceType.downcase == "roofceiling" and living_surface.outsideBoundaryCondition.downcase == "outdoors"
	    living_surface.setConstruction(fininsextroof)
		runner.registerInfo("Surface '#{living_surface.name}', of Space Type '#{living_space_type_r}' and with Surface Type '#{living_surface.surfaceType}' and Outside Boundary Condition '#{living_surface.outsideBoundaryCondition}', was assigned Construction '#{fininsextroof.name}'")		
	  end	
	end

    return true
 
  end #end the run method

  def _processConstructionsInsulatedRoof(frRoofContInsThickness, frRoofContInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor, gypsumThickness, gypsumNumLayers, gypsumRvalue, film_roof_R)
    fr_roof_overall_ins_Rvalue = get_finished_roof_r_assembly(frRoofContInsThickness, frRoofContInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor, gypsumThickness, gypsumNumLayers, film_roof_R)

    if frRoofContInsThickness > 0
      fr_roof_stud_ins_Rvalue = fr_roof_overall_ins_Rvalue - frRoofContInsRvalue - 2.0 * Material.Plywood3_4in.Rvalue - gypsumRvalue - film_roof_R - AirFilms.OutsideR # hr*ft^2*F/Btu
    else
      fr_roof_stud_ins_Rvalue = fr_roof_overall_ins_Rvalue - Material.Plywood3_4in.Rvalue - gypsumRvalue - film_roof_R - AirFilms.OutsideR # hr*ft^2*F/Btu
    end

    # Set roof characteristics for finished roof
    sc_thick = OpenStudio::convert(frRoofCavityDepth,"in","ft").get # ft
    sc_cond = sc_thick / fr_roof_stud_ins_Rvalue # Btu/hr*ft*F
    sc_dens = frRoofFramingFactor * BaseMaterial.Wood.rho + (1 - frRoofFramingFactor) * BaseMaterial.InsulationGenericDensepack.rho # lbm/ft^3
    sc_sh = (frRoofFramingFactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - frRoofFramingFactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho) / sc_dens # Btu/lbm*F

    if frRoofContInsThickness > 0
      rigid_thick = OpenStudio::convert(frRoofContInsThickness,"in","ft").get # after() do
      rigid_cond = rigid_thick / frRoofContInsRvalue # Btu/hr*ft*F
      rigid_dens = BaseMaterial.InsulationRigid.rho # lbm/ft^3
      rigid_sh = BaseMaterial.InsulationRigid.Cp # Btu/lbm*F
    end

    return sc_thick, sc_cond, sc_dens, sc_sh, rigid_thick, rigid_cond, rigid_dens, rigid_sh

  end

  def get_finished_roof_r_assembly(frRoofContInsThickness, frRoofContInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor, gypsumThickness, gypsumNumLayers, film_roof)
      # Returns assembly R-value for finished roof, including air films.

      # Add air film coefficients when insulation thickness < cavity depth
      if not frRoofCavityInsFillsCavity
        frRoofCavityInsRvalueInstalled += Gas.AirGapRvalue
      end

      path_fracs = [frRoofFramingFactor, 1 - frRoofFramingFactor]

      roof_const = Construction.new(path_fracs)

      # Interior Film
      roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film_roof])

      # Interior Finish (GWB)
      (0...gypsumNumLayers).to_a.each do |i|
        roof_const.addlayer(thickness=OpenStudio::convert(gypsumThickness,"in","ft").get, conductivity_list=[BaseMaterial.Gypsum.k])
      end

      # Stud/cavity layer
      roof_const.addlayer(thickness=OpenStudio::convert(frRoofCavityDepth,"in","ft").get, conductivity_list=[BaseMaterial.Wood.k, OpenStudio::convert(frRoofCavityDepth,"in","ft").get / frRoofCavityInsRvalueInstalled])

      # Sheathing
      roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)

      # Rigid
      if frRoofContInsThickness > 0
        roof_const.addlayer(thickness=OpenStudio::convert(frRoofContInsThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(frRoofContInsThickness,"in","ft").get / frRoofContInsRvalue])
        # More sheathing
        roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)
      end

      # Exterior Film
      roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / AirFilms.OutsideR])

      return roof_const.Rvalue_parallel

  end

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInsulatedRoof.new.registerWithApplication