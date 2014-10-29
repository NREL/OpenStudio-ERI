#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

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
    return "ProcessConstructionsInsulatedRoof"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Of what space type is the living space?")
    args << selected_living

    #make a choice argument for model objects
    material_handles = OpenStudio::StringVector.new
    material_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    material_args = model.getStandardOpaqueMaterials
    material_args_hash = {}
    material_args.each do |material_arg|
      material_args_hash[material_arg.name.to_s] = material_arg
    end

    #looping through sorted hash of model objects
    material_args_hash.sort.map do |key,value|
      material_handles << value.handle.to_s
      material_display_names << key
    end

    # #make a choice argument for roof insulation
    # selected_frroof = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfrroof", material_handles, material_display_names, false)
    # selected_frroof.setDisplayName("Finished roof insulation. For manually entering finished roof insulation properties, leave blank.")
    # args << selected_frroof

    #make a double argument for finished roof insulation R-value
    userdefined_frroofr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofr", false)
    userdefined_frroofr.setDisplayName("Installed finished roof cavity insulation R-value [hr-ft^2-R/Btu].")
    userdefined_frroofr.setDefaultValue(0)
    args << userdefined_frroofr

    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
    selected_insfills.setDisplayName("Cavity insulation fills the cavity?")
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
    selected_studsize.setDisplayName("Thickness of roof framing.")
    args << selected_studsize

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_frroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofff", false)
    userdefined_frroofff.setDisplayName("Finished roof framing factor [frac].")
    userdefined_frroofff.setDefaultValue(0.07)
    args << userdefined_frroofff

    # #make a choice argument for rigid insulation of roof cavity
    # selected_rigidins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedrigidins", material_handles, material_display_names, false)
    # selected_rigidins.setDisplayName("Rigid insulation of roof cavity. For manually entering rigid insulation properties of roof cavity, leave blank.")
    # args << selected_rigidins

    #make a double argument for rigid insulation thickness of roof cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Rigid insulation thickness of roof cavity [in].")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness

    #make a double argument for rigid insulation R-value of roof cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Rigid insulation R-value of roof cavity [hr-ft^2-R/Btu].")
    userdefined_rigidinsr.setDefaultValue(0)
    args << userdefined_rigidinsr

    # #make a choice argument for interior finish of cavity
    # selected_gypsum = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgypsum", material_handles, material_display_names, false)
    # selected_gypsum.setDisplayName("Interior finish (gypsum) of cavity. For manually entering interior finish properties of cavity, leave blank.")
    # args << selected_gypsum

    #make a double argument for thickness of gypsum
    userdefined_gypthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgypthickness", false)
    userdefined_gypthickness.setDisplayName("Thickness of drywall layers [in].")
    userdefined_gypthickness.setDefaultValue(0.5)
    args << userdefined_gypthickness

    #make a double argument for number of gypsum layers
    userdefined_gyplayers = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedgyplayers", false)
    userdefined_gyplayers.setDisplayName("Number of drywall layers.")
    userdefined_gyplayers.setDefaultValue(1)
    args << userdefined_gyplayers

    # #make a choice argument for roofing material of finished roof
    # selected_roofmat = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedroofmat", material_handles, material_display_names, false)
    # selected_roofmat.setDisplayName("Roofing material for finished roof. For manually entering roofing material properties of finished roof, leave blank.")
    # args << selected_roofmat

    #make a double argument for roofing material thermal absorptance of finished roof
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roofing material emissivity of finished roof.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of finished roof
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roofing material absorptance of finished roof.")
    userdefined_roofmatabs.setDefaultValue(0.85)
    args << userdefined_roofmatabs

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
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

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
    selected_rigidins = runner.getOptionalWorkspaceObjectChoiceValue("selectedrigidins",user_arguments,model)
    if selected_rigidins.empty?
      userdefined_rigidinsthickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
      userdefined_rigidinsr = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
    end

    # Gypsum
    selected_gypsum = runner.getOptionalWorkspaceObjectChoiceValue("selectedgypsum",user_arguments,model)
    if selected_gypsum.empty?
      userdefined_gypthickness = runner.getDoubleArgumentValue("userdefinedgypthickness",user_arguments)
      userdefined_gyplayers = runner.getDoubleArgumentValue("userdefinedgyplayers",user_arguments)
    end

    # Exterior Finish
    selected_roofmat = runner.getOptionalWorkspaceObjectChoiceValue("selectedroofmat",user_arguments,model)
    if selected_roofmat.empty?
      userdefined_roofmatthermalabs = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
      userdefined_roofmatabs = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)
    end

    # Constants
    mat_gyp = get_mat_gypsum
    mat_rigid = get_mat_rigid_ins

    # Insulation
    if userdefined_frroofr.nil?
      frRoofInsThickness = OpenStudio::convert(selected_frroof.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      frRoofConductivity = OpenStudio::convert(selected_frroof.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      frRoofCavityInsRvalueInstalled = OpenStudio::convert(frRoofInsThickness,"in","ft").get / frRoofConductivity
    else
      frRoofCavityInsRvalueInstalled = userdefined_frroofr
    end

    # Cavity
    frRoofCavityDepth_dict = {"2x4"=>3.5, "2x6"=>5.5, "2x8"=>7.25, "2x10"=>9.25, "2x12"=>11.25, "2x14"=>13.25, "2x16"=>15.25}
    frRoofCavityDepth = frRoofCavityDepth_dict[selected_studsize]
    frRoofCavityInsFillsCavity = selected_insfills

    # Ceiling Framing Factor
    frRoofFramingFactor = userdefined_frroofff

    # Rigid
    if userdefined_rigidinsthickness.nil?
      rigidInsRoughness = selected_rigidins.get.to_StandardOpaqueMaterial.get.roughness
      rigidInsThickness = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      rigidInsConductivity = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      rigidInsDensity = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      rigidInsSpecificHeat = OpenStudio::convert(selected_rigidins.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
      rigidInsRvalue = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsConductivity
    else
      rigidInsRvalue = userdefined_rigidinsr
      rigidInsRoughness = "Rough"
      rigidInsThickness = userdefined_rigidinsthickness
      rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
      rigidInsDensity = mat_rigid.rho
      rigidInsSpecificHeat = mat_rigid.Cp
    end

    # Gypsum
    if userdefined_gypthickness.nil?
      gypsumRoughness = selected_gypsum.get.to_StandardOpaqueMaterial.get.roughness
      gypsumThickness = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      gypsumNumLayers = 1.0
      gypsumConductivity = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      gypsumDensity = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      gypsumSpecificHeat = OpenStudio::convert(selected_gypsum.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
      gypsumThermalAbs = selected_gypsum.get.to_StandardOpaqueMaterial.get.getThermalAbsorptance.value
      gypsumSolarAbs = selected_gypsum.get.to_StandardOpaqueMaterial.get.getSolarAbsorptance.value
      gypsumVisibleAbs = selected_gypsum.get.to_StandardOpaqueMaterial.get.getVisibleAbsorptance.value
      gypsumRvalue = OpenStudio::convert(gypsumThickness,"in","ft").get / gypsumConductivity
    else
      gypsumRoughness = "Rough"
      gypsumThickness = userdefined_gypthickness
      gypsumNumLayers = userdefined_gyplayers
      gypsumConductivity = mat_gyp.k
      gypsumDensity = mat_gyp.rho
      gypsumSpecificHeat = mat_gyp.Cp
      gypsumThermalAbs = get_mat_gypsum_ceiling(mat_gyp).TAbs
      gypsumSolarAbs = get_mat_gypsum_ceiling(mat_gyp).SAbs
      gypsumVisibleAbs = get_mat_gypsum_ceiling(mat_gyp).VAbs
      gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * userdefined_gyplayers / mat_gyp.k)
    end

    # Roofing Material
    if userdefined_roofmatthermalabs.nil?
      roofMatEmissivity = selected_roofmat.get.to_StandardOpaqueMaterial.get.getThermalAbsorptance.value
      roofMatAbsorptivity = selected_roofmat.get.to_StandardOpaqueMaterial.get.getSolarAbsorptance.value
    else
      roofMatEmissivity = userdefined_roofmatthermalabs
      roofMatAbsorptivity = userdefined_roofmatabs
    end

    # Create the material class instances
    fr = FinishedRoof.new(rigidInsThickness, rigidInsRvalue, frRoofCavityInsFillsCavity, frRoofCavityInsRvalueInstalled, frRoofCavityDepth, frRoofFramingFactor)
    ceiling_mass = CeilingMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue, ceilingMassPCMType)
    ri = RoofIns.new
    rri = RigidRoofIns.new
    roofing_material = RoofingMaterial.new(roofMatEmissivity, roofMatAbsorptivity)

    # Create the sim object
    sim = Sim.new(model)

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
    if ceiling_mass.CeilingMassPCMType == Constants::PCMtypeConcentrated
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
    gypsum.setRoughness(gypsumRoughness)
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
    if ceiling_mass.CeilingMassPCMType == Constants::PCMtypeConcentrated
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
      if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
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