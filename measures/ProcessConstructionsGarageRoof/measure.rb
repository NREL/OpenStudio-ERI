#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsGarageRoof < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Garage Roof Construction"
  end
  
  def description
    return "This measure assigns a construction to the garage roof."
  end
  
  def modeler_description
    return "Calculates material layer properties of uninsulated, unfinished, stud and air constructions for the garage roof. Finds surfaces adjacent to the garage and sets applicable constructions."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a bool argument for radiant barrier of roof cavity
    userdefined_hasradiantbarrier = OpenStudio::Ruleset::OSArgument::makeBoolArgument("userdefinedhasradiantbarrier", false)
    userdefined_hasradiantbarrier.setDisplayName("Has Radiant Barrier")
    userdefined_hasradiantbarrier.setDescription("Layers of reflective material used to reduce heat transfer between the attic roof and the ceiling insulation and ductwork (if present).")
    userdefined_hasradiantbarrier.setDefaultValue(false)
    args << userdefined_hasradiantbarrier

    #make a double argument for roofing material thermal absorptance of unfinished attic
    userdefined_roofmatthermalabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatthermalabs", false)
    userdefined_roofmatthermalabs.setDisplayName("Roof Material: Emissivity")
    userdefined_roofmatthermalabs.setDescription("Infrared emissivity of the outside surface of the roof.")
    userdefined_roofmatthermalabs.setDefaultValue(0.91)
    args << userdefined_roofmatthermalabs

    #make a double argument for roofing material solar/visible absorptance of unfinished attic
    userdefined_roofmatabs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedroofmatabs", false)
    userdefined_roofmatabs.setDisplayName("Roof Material: Absorptivity")
    userdefined_roofmatabs.setDescription("The solar radiation absorptance of the outside roof surface, specified as a value between 0 and 1.")
    userdefined_roofmatabs.setDefaultValue(0.85)
    args << userdefined_roofmatabs

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
    garage_space_type_r = runner.getStringArgumentValue("garage_space_type",user_arguments)
    garage_space_type = HelperMethods.get_space_type_from_string(model, garage_space_type_r, runner, false)
    if garage_space_type.nil?
        # If the building has no garage, no constructions are assigned and we continue by returning True
        return true
    end

    # Initialize hashes
    constructions_to_surfaces = {"UnfinUninsExtGrgRoof"=>[]}
    constructions_to_objects = Hash.new    
    
    # Roof of garage
    garage_space_type.spaces.each do |garage_space|
      garage_space.surfaces.each do |garage_surface|
        next unless garage_surface.surfaceType.downcase == "roofceiling" and garage_surface.outsideBoundaryCondition.downcase == "outdoors"
          constructions_to_surfaces["UnfinUninsExtGrgRoof"] << garage_surface
      end   
    end
    
    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end   
    
    # Radiant Barrier
    hasRadiantBarrier = runner.getBoolArgumentValue("userdefinedhasradiantbarrier",user_arguments)

    # Roofing Material
    roofMatEmissivity = runner.getDoubleArgumentValue("userdefinedroofmatthermalabs",user_arguments)
    roofMatAbsorptivity = runner.getDoubleArgumentValue("userdefinedroofmatabs",user_arguments)

    highest_roof_pitch = 26.565 # FIXME: Currently hardcoded
    film_roof_R = Material.AirFilmRoof(highest_roof_pitch).Rvalue

    # Process the roof
    sc_thick, sc_cond, sc_dens, sc_sh = _processConstructionsGarageRoof(film_roof_R)

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

    # RadiantBarrier
    radbar = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    radbar.setName("RadiantBarrier")
    radbar.setRoughness("Rough")
    radbar.setThickness(OpenStudio::convert(Material.RadiantBarrier.thick,"ft","m").get)
    radbar.setConductivity(OpenStudio::convert(Material.RadiantBarrier.k,"Btu/hr*ft*R","W/m*K").get)
    radbar.setDensity(OpenStudio::convert(Material.RadiantBarrier.rho,"lb/ft^3","kg/m^3").get)
    radbar.setSpecificHeat(OpenStudio::convert(Material.RadiantBarrier.Cp,"Btu/lb*R","J/kg*K").get)
    radbar.setThermalAbsorptance(Material.RadiantBarrier.TAbs)
    radbar.setSolarAbsorptance(Material.RadiantBarrier.SAbs)
    radbar.setVisibleAbsorptance(Material.RadiantBarrier.VAbs)

    # GrgRoofStudandAir
    gsa = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gsa.setName("GrgRoofStudandAir")
    gsa.setRoughness("Rough")
    gsa.setThickness(OpenStudio::convert(sc_thick,"ft","m").get)
    gsa.setConductivity(OpenStudio::convert(sc_cond,"Btu/hr*ft*R","W/m*K").get)
    gsa.setDensity(OpenStudio::convert(sc_dens,"lb/ft^3","kg/m^3").get)
    gsa.setSpecificHeat(OpenStudio::convert(sc_sh,"Btu/lb*R","J/kg*K").get)

    # UnfinUninsExtGrgRoof
    materials = []
    materials << roofmat
    materials << ply3_4
    materials << gsa
    if hasRadiantBarrier
      materials << radbar
    end
    unless constructions_to_surfaces["UnfinUninsExtGrgRoof"].empty?
        unfinuninsextgrgroof = OpenStudio::Model::Construction.new(materials)
        unfinuninsextgrgroof.setName("UnfinUninsExtGrgRoof")
        constructions_to_objects["UnfinUninsExtGrgRoof"] = unfinuninsextgrgroof
    end
    
    # Apply constructions to surfaces
    constructions_to_surfaces.each do |construction, surfaces|
        surfaces.each do |surface|
            surface.setConstruction(constructions_to_objects[construction])
            runner.registerInfo("Surface '#{surface.name}', of Space Type '#{HelperMethods.get_space_type_from_surface(model, surface.name.to_s, runner)}' and with Surface Type '#{surface.surfaceType}' and Outside Boundary Condition '#{surface.outsideBoundaryCondition}', was assigned Construction '#{construction}'")
        end
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials(model, runner)
    
    return true
 
  end #end the run method

  def _processConstructionsGarageRoof(film_roof_R)

    #generic method
    path_fracs = [Constants.DefaultFramingFactorCeiling, 1 - Constants.DefaultFramingFactorCeiling]
    roof_const = Construction.new(path_fracs)

    # Interior Film
    roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / film_roof_R])

    # Stud/cavity layer
    roof_const.addlayer(thickness=Material.Stud2x4.thick, conductivity_list=[BaseMaterial.Wood.k, 1000000000.0])

    # Sheathing
    roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)

    # Exterior Film
    roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / Material.AirFilmOutside.Rvalue])

    grgRoofStudandAir_Rvalue = roof_const.Rvalue_parallel - film_roof_R - Material.AirFilmOutside.Rvalue - Material.Plywood3_4in.Rvalue # hr*ft^2*F/Btu

    sc_thick = Material.Stud2x4.thick # ft
    sc_cond = sc_thick / grgRoofStudandAir_Rvalue # Btu/hr*ft*F
    sc_dens = Constants.DefaultFramingFactorCeiling * BaseMaterial.Wood.rho + (1 - Constants.DefaultFramingFactorCeiling) * Gas.Air.Cp # lbm/ft^3
    sc_sh = (Constants.DefaultFramingFactorCeiling * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - Constants.DefaultFramingFactorCeiling) * Gas.Air.Cp * Gas.Air.Cp) / sc_dens # Btu/lbm*F

    return sc_thick, sc_cond, sc_dens, sc_sh

  end  

  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsGarageRoof.new.registerWithApplication