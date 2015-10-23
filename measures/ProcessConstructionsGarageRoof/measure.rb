#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsGarageRoof < OpenStudio::Ruleset::ModelUserScript

  class GrgRoofStudandAir
    def initialize
    end
    attr_accessor(:grg_roof_thickness, :grg_roof_conductivity, :grg_roof_density, :grg_roof_spec_heat)
  end

  class RadiantBarrier
    def initialize(hasRadiantBarrier)
      @hasRadiantBarrier = hasRadiantBarrier
    end

    def HasRadiantBarrier
      return @hasRadiantBarrier
    end
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
    return "ProcessConstructionsGarageRoof"
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

    #make a choice argument for crawlspace
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", spacetype_handles, spacetype_display_names, true)
    selected_garage.setDisplayName("Of what space type is the garage?")
    args << selected_garage

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

    #make a bool argument for radiant barrier of roof cavity
    userdefined_hasradiantbarrier = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasradiantbarrier", true)
    userdefined_hasradiantbarrier.setDisplayName("Roof has radiant barrier?")
    args << userdefined_hasradiantbarrier

    # #make a choice argument for roofing material of unfinished attic
    # selected_roofmat = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedroofmat", material_handles, material_display_names, false)
    # selected_roofmat.setDisplayName("Roofing material for unfinished attic. For manually entering roofing material properties of unfinished attic, leave blank.")
    # args << selected_roofmat

    #make a double argument for roofing material thermal absorptance of unfinished attic
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roofing material emissivity of unfinished attic.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of unfinished attic
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roofing material absorptance of unfinished attic.")
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

    # Space Type
    selected_garage = runner.getOptionalWorkspaceObjectChoiceValue("selectedgarage",user_arguments,model)

    # Radiant Barrier
    userdefined_hasradiantbarrier = runner.getBoolArgumentValue("userdefinedhasradiantbarrier",user_arguments)

    # Exterior Finish
    selected_roofmat = runner.getOptionalWorkspaceObjectChoiceValue("selectedroofmat",user_arguments,model)
    if selected_roofmat.empty?
      userdefined_roofmatthermalabs = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
      userdefined_roofmatabs = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)
    end

    # Radiant Barrier
    hasRadiantBarrier = userdefined_hasradiantbarrier

    # Roofing Material
    if userdefined_roofmatthermalabs.nil?
      roofMatEmissivity = selected_roofmat.get.to_StandardOpaqueMaterial.get.getThermalAbsorptance.value
      roofMatAbsorptivity = selected_roofmat.get.to_StandardOpaqueMaterial.get.getSolarAbsorptance.value
    else
      roofMatEmissivity = userdefined_roofmatthermalabs
      roofMatAbsorptivity = userdefined_roofmatabs
    end

    # Create the material class instances
    gsa = GrgRoofStudandAir.new
    radiant_barrier = RadiantBarrier.new(hasRadiantBarrier)
    roofing_material = RoofingMaterial.new(roofMatEmissivity, roofMatAbsorptivity)

    # Create the sim object
    sim = Sim.new(model, runner)

    # Process the slab
    gsa = sim._processConstructionsGarageRoof(gsa)

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

    # RadiantBarrier
    mat_radiant_barrier = get_mat_radiant_barrier
    radbar = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    radbar.setName("RadiantBarrier")
    radbar.setRoughness("Rough")
    radbar.setThickness(OpenStudio::convert(mat_radiant_barrier.thick,"ft","m").get)
    radbar.setConductivity(OpenStudio::convert(mat_radiant_barrier.k,"Btu/hr*ft*R","W/m*K").get)
    radbar.setDensity(OpenStudio::convert(mat_radiant_barrier.rho,"lb/ft^3","kg/m^3").get)
    radbar.setSpecificHeat(OpenStudio::convert(mat_radiant_barrier.Cp,"Btu/lb*R","J/kg*K").get)
    radbar.setThermalAbsorptance(mat_radiant_barrier.TAbs)
    radbar.setSolarAbsorptance(mat_radiant_barrier.SAbs)
    radbar.setVisibleAbsorptance(mat_radiant_barrier.VAbs)

    # GrgRoofStudandAir
    gsaThickness = gsa.grg_roof_thickness
    gsaConductivity = gsa.grg_roof_conductivity
    gsaDensity = gsa.grg_roof_density
    gsaSpecificHeat = gsa.grg_roof_spec_heat
    gsa = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gsa.setName("GrgRoofStudandAir")
    gsa.setRoughness("Rough")
    gsa.setThickness(OpenStudio::convert(gsaThickness,"ft","m").get)
    gsa.setConductivity(OpenStudio::convert(gsaConductivity,"Btu/hr*ft*R","W/m*K").get)
    gsa.setDensity(OpenStudio::convert(gsaDensity,"lb/ft^3","kg/m^3").get)
    gsa.setSpecificHeat(OpenStudio::convert(gsaSpecificHeat,"Btu/lb*R","J/kg*K").get)

    # UnfinUninsExtGrgRoof
    layercount = 0
    unfinuninsextgrgroof = OpenStudio::Model::Construction.new(model)
    unfinuninsextgrgroof.setName("UnfinUninsExtGrgRoof")
    unfinuninsextgrgroof.insertLayer(layercount,roofmat)
    layercount += 1
    unfinuninsextgrgroof.insertLayer(layercount,ply3_4)
    layercount += 1
    unfinuninsextgrgroof.insertLayer(layercount,gsa)
    layercount += 1
    if radiant_barrier.HasRadiantBarrier
      unfinuninsextgrgroof.insertLayer(layercount,radbar)
    end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_garage.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(unfinuninsextgrgroof)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinUninsExtGrgRoof"]
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
ProcessConstructionsGarageRoof.new.registerWithApplication