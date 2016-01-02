#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsInsulatedRoof < OpenStudio::Ruleset::ModelUserScript

  class FinishedRoof
    def initialize(frRoofContInsThickness, frRoofContInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor)
      @frRoofContInsThickness = frRoofContInsThickness
      @frRoofContInsRvalue = frRoofContInsRvalue
      @frRoofCavityInsFillsCavity = frRoofCavityInsFillsCavity
      @frRoofCavityInsRvalueInstalled = frRoofCavityInsRvalueInstalled
      @frRoofCavityDepth = frRoofCavityDepth
      @frRoofFramingFactor = frRoofFramingFactor
    end

    # attr_accessor(:)

    def FRRoofContInsThickness
      return @frRoofContInsThickness
    end

    def FRRoofContInsRvalue
      return @frRoofContInsRvalue
    end

    def FRRoofCavityInsFillsCavity
      return @frRoofCavityInsFillsCavity
    end

    def FRRoofCavityInsRvalueInstalled
      return @frRoofCavityInsRvalueInstalled
    end

    def FRRoofCavityDepth
      return @frRoofCavityDepth
    end

    def FRRoofFramingFactor
      return @frRoofFramingFactor
    end
  end

  class CeilingMass
    def initialize(ceilingMassGypsumThickness, ceilingMassGypsumNumLayers, rvalue, ceilingMassPCMType)
      @ceilingMassGypsumThickness = ceilingMassGypsumThickness
      @ceilingMassGypsumNumLayers = ceilingMassGypsumNumLayers
      @rvalue = rvalue
      @ceilingMassPCMType = ceilingMassPCMType
    end

    def CeilingMassGypsumThickness
      return @ceilingMassGypsumThickness
    end

    def CeilingMassGypsumNumLayers
      return @ceilingMassGypsumNumLayers
    end

    def Rvalue
      return @rvalue
    end

    def CeilingMassPCMType
      return @ceilingMassPCMType
    end
  end

  class RoofIns
    def initialize
    end
    attr_accessor(:fr_roof_ins_thickness, :fr_roof_ins_conductivity, :fr_roof_ins_density, :fr_roof_ins_spec_heat)
  end

  class RigidRoofIns
    def initialize
    end
    attr_accessor(:fr_roof_rigid_foam_ins_thickness, :fr_roof_rigid_foam_ins_conductivity, :fr_roof_rigid_foam_ins_density, :fr_roof_rigid_foam_ins_spec_heat)
  end

  class RoofingMaterial
    def initialize(roofMatEmissivity, roofMatAbsorptivity)
      @roofMatEmissivity = roofMatEmissivity
      @roofMatAbsorptivity = roofMatAbsorptivity
    end

    def RoofMatEmissivity
      return @roofMatEmissivity
    end

    def RoofMatAbsorptivity
      return @roofMatAbsorptivity
    end
  end
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Assign Residential Finished Roof Construction"
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

    #make a choice argument for unfinished attic ceiling framing factor
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

    #make a double argument for roofing material thermal absorptance of unfinished attic
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roof Material: Emissivity.")
	userdefined_roofmatthermalabs.setDescription("Infrared emissivity of the outside surface of the roof.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of unfinished attic
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

    ceilingMassPCMType = nil
    frRoofCavityInsRvalueInstalled = 0
    rigidInsThickness = 0
    rigidInsRvalue = 0

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end

    # Roof Insulation
    selected_frroof = runner.getOptionalWorkspaceObjectChoiceValue("selectedfrroof",user_arguments,model)
    if selected_frroof.empty?
      userdefined_frroofr = runner.getDoubleArgumentValue("userdefinedfrroofr",user_arguments)
    end

    # Cavity
    selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
    selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)

    # Ceiling Framing Factor
    userdefined_frroofff = runner.getDoubleArgumentValue("userdefinedfrroofff",user_arguments)
    if not ( userdefined_frroofff > 0.0 and userdefined_frroofff < 1.0 )
      runner.registerError("Invalid finished roof framing factor")
      return false
    end

    # Rigid
    userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
    userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)

    # Gypsum
    userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
    userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)

    # Exterior Finish
    userdefined_roofmatthermalabs = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
    userdefined_roofmatabs = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)

    # Constants
    mat_gyp = get_mat_gypsum
    mat_rigid = get_mat_rigid_ins

    # Insulation
    frRoofCavityInsRvalueInstalled = userdefined_frroofr

    # Cavity
    frRoofCavityDepth_dict = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}
    frRoofCavityDepth = frRoofCavityDepth_dict[selected_studsize]
    frRoofCavityInsFillsCavity = selected_insfills

    # Ceiling Framing Factor
    frRoofFramingFactor = userdefined_frroofff

    # Rigid
    rigidInsRvalue = userdefined_rigidinsr
    rigidInsThickness = userdefined_rigidinsthickness
    rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
    rigidInsDensity = mat_rigid.rho
    rigidInsSpecificHeat = mat_rigid.Cp

    # Gypsum
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    gypsumConductivity = mat_gyp.k
    gypsumDensity = mat_gyp.rho
    gypsumSpecificHeat = mat_gyp.Cp
    gypsumThermalAbs = get_mat_gypsum_ceiling(mat_gyp).TAbs
    gypsumSolarAbs = get_mat_gypsum_ceiling(mat_gyp).SAbs
    gypsumVisibleAbs = get_mat_gypsum_ceiling(mat_gyp).VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * userdefined_gyplayers / mat_gyp.k)

    # Roofing Material
    roofMatEmissivity = userdefined_roofmatthermalabs
    roofMatAbsorptivity = userdefined_roofmatabs

    # Create the material class instances
    fr = FinishedRoof.new(rigidInsThickness, rigidInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor)
    ceiling_mass = CeilingMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue, ceilingMassPCMType)
    ri = RoofIns.new
    rri = RigidRoofIns.new
    roofing_material = RoofingMaterial.new(roofMatEmissivity, roofMatAbsorptivity)

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the unfinished attic ceiling
    ri, rri = sim._processConstructionsInsulatedRoof(fr, ceiling_mass, ri, rri)

    # RoofingMaterial
    mat_roof_mat = get_mat_roofing_mat(roofing_material)
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
    ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(get_mat_wood).thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(get_mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(get_mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(get_mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # RigidRoofIns
    if fr.FRRoofContInsThickness > 0
      rriThickness = rri.fr_roof_rigid_foam_ins_thickness
      rriConductivity = rri.fr_roof_rigid_foam_ins_conductivity
      rriDensity = rri.fr_roof_rigid_foam_ins_density
      rriSpecificHeat = rri.fr_roof_rigid_foam_ins_spec_heat
      rri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      rri.setName("RigidRoofIns")
      rri.setRoughness("Rough")
      rri.setThickness(OpenStudio::convert(rriThickness,"ft","m").get)
      rri.setConductivity(OpenStudio::convert(rriConductivity,"Btu/hr*ft*R","W/m*K").get)
      rri.setDensity(OpenStudio::convert(rriDensity,"lb/ft^3","kg/m^3").get)
      rri.setSpecificHeat(OpenStudio::convert(rriSpecificHeat,"Btu/lb*R","J/kg*K").get)
    end

    # RoofIns
    riThickness = ri.fr_roof_ins_thickness
    riConductivity = ri.fr_roof_ins_conductivity
    riDensity = ri.fr_roof_ins_density
    riSpecificHeat = ri.fr_roof_ins_spec_heat
    ri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ri.setName("RoofIns")
    ri.setRoughness("Rough")
    ri.setThickness(OpenStudio::convert(riThickness,"ft","m").get)
    ri.setConductivity(OpenStudio::convert(riConductivity,"Btu/hr*ft*R","W/m*K").get)
    ri.setDensity(OpenStudio::convert(riDensity,"lb/ft^3","kg/m^3").get)
    ri.setSpecificHeat(OpenStudio::convert(riSpecificHeat,"Btu/lb*R","J/kg*K").get)

    # ConcPCMCeilWall
    if ceiling_mass.CeilingMassPCMType == Constants.PCMtypeConcentrated
      ceil_pcm_mat_base = get_mat_ceil_pcm(ceiling_mass)
      pcm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      pcm.setName("ConcPCMCeilWall")
      pcm.setRoughness("Rough")
      pcm.setThickness(OpenStudio::convert(get_mat_ceil_pcm_conc(get_mat_ceil_pcm, ceiling_mass).thick,"ft","m").get)
      pcm.setConductivity()
      pcm.setDensity()
      pcm.setSpecificHeat()
    end

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
    layercount = 0
    fininsextroof = OpenStudio::Model::Construction.new(model)
    fininsextroof.setName("FinInsExtRoof")
    fininsextroof.insertLayer(layercount,roofmat)
    layercount += 1
    fininsextroof.insertLayer(layercount,ply3_4)
    layercount += 1
    if fr.FRRoofContInsThickness > 0
      fininsextroof.insertLayer(layercount,rri)
      layercount += 1
      fininsextroof.insertLayer(layercount,ply3_4)
      layercount += 1
    end
    fininsextroof.insertLayer(layercount,ri)
    layercount += 1
    if ceiling_mass.CeilingMassPCMType == Constants.PCMtypeConcentrated
      fininsunfinuafloor.insertLayer(layercount,pcm)
      layercount += 1
    end
    (0...gypsumNumLayers).to_a.each do |i|
      fininsextroof.insertLayer(layercount,gypsum)
      layercount += 1
    end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if living_space_type.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(fininsextroof)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"FinInsExtRoof"]
          end
        end
      end
      constructions_hash.map do |key,value|
        runner.registerInfo("Surface '#{key}', attached to Space '#{space.name.to_s}' of Space Type '#{space.spaceType.get.name.to_s}' and with Surface Type '#{value[0]}' and Outside Boundary Condition '#{value[1]}', was assigned Construction '#{value[2]}'")
      end
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInsulatedRoof.new.registerWithApplication