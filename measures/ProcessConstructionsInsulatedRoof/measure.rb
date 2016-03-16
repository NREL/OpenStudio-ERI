#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsInsulatedRoof < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Finished Roof Construction"
  end
  
  def description
    return "This measure assigns a construction to finished roofs."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of finished constructions for roofs above finished space."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for finished roof insulation R-value
    userdefined_frroofr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofr", false)
    userdefined_frroofr.setDisplayName("Cavity Insulation Installed R-value")
	userdefined_frroofr.setUnits("hr-ft^2-R/Btu")
	userdefined_frroofr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_frroofr.setDefaultValue(30.0)
    args << userdefined_frroofr

	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Insulation Fills Cavity")
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
    selected_studsize.setDisplayName("Cavity Depth")
	selected_studsize.setUnits("in")
	selected_studsize.setDescription("Thickness of roof framing.")
	selected_studsize.setDefaultValue("2x10")
    args << selected_studsize

    #make a choice argument for finished roof framing factor
    userdefined_frroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfrroofff", false)
    userdefined_frroofff.setDisplayName("Framing Factor")
	userdefined_frroofff.setUnits("frac")
	userdefined_frroofff.setDescription("The framing factor of the finished roof.")
    userdefined_frroofff.setDefaultValue(0.07)
    args << userdefined_frroofff

    #make a double argument for rigid insulation thickness of roof cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Continuous Insulation Thickness")
	userdefined_rigidinsthickness.setUnits("in")
	userdefined_rigidinsthickness.setDescription("Thickness of rigid insulation added to the roof.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness

    #make a double argument for rigid insulation R-value of roof cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Continuous Insulation Nominal R-value")
	userdefined_rigidinsr.setUnits("hr-ft^2-R/Btu")
	userdefined_rigidinsr.setDescription("The nominal R-value of the continuous insulation.")
    userdefined_rigidinsr.setDefaultValue(0)
    args << userdefined_rigidinsr

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
    living_space_type = Geometry.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end

    # Initialize hashes
    constructions_to_surfaces = {"FinInsExtRoof"=>[]}
    constructions_to_objects = Hash.new   

    # Roof above finished space
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            constructions_to_surfaces["FinInsExtRoof"] << surface
        end
    end
    
    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
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

    # Process the finished roof
    highest_roof_pitch = 26.565 # FIXME: Currently hardcoded
    
    unless constructions_to_surfaces["FinInsExtRoof"].empty?
        # Define materials
        if frRoofCavityInsRvalueInstalled > 0
            if frRoofCavityInsFillsCavity
                # Insulation
                mat_cavity = Material.new(name=nil, thick_in=frRoofCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(frRoofCavityDepth,"in","ft").get / frRoofCavityInsRvalueInstalled)
            else
                # Insulation plus air gap when insulation thickness < cavity depth
                mat_cavity = Material.new(name=nil, thick_in=frRoofCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, cond=OpenStudio::convert(frRoofCavityDepth,"in","ft").get / (frRoofCavityInsRvalueInstalled + Gas.AirGapRvalue))
            end
        else
            # Empty cavity
            mat_cavity = Material.AirCavity(frRoofCavityDepth)
        end
        mat_framing = Material.new(name=nil, thick_in=frRoofCavityDepth, mat_base=BaseMaterial.Wood)
        mat_rigid = nil
        if frRoofContInsThickness > 0
            mat_rigid = Material.new(name="RigidRoofIns", thick_in=frRoofContInsThickness, mat_base=BaseMaterial.InsulationRigid, cond=OpenStudio::convert(frRoofContInsThickness,"in","ft").get / frRoofContInsRvalue)
        end
        
        # Set paths
        path_fracs = [frRoofFramingFactor, 1 - frRoofFramingFactor]
        
        # Define construction
        roof = Construction.new(path_fracs)
        roof.addlayer(Material.AirFilmRoof(highest_roof_pitch), false)
        roof.addlayer(Material.DefaultWallMass, false) # thermal mass added in separate measure
        roof.addlayer([mat_framing, mat_cavity], true, "RoofIns")
        roof.addlayer(Material.Plywood3_4in, true)
        if not mat_rigid.nil?
            roof.addlayer(thickness=OpenStudio::convert(frRoofContInsThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(frRoofContInsThickness,"in","ft").get / frRoofContInsRvalue])
            roof.addlayer(Material.Plywood3_4in, true)
        end
        roof.addlayer(Material.AirFilmOutside, false)
            
        # Create construction
        constr = roof.create_construction(runner, model, "FinInsExtRoof")
        if constr.nil?
            return false
        end
        constructions_to_objects["FinInsExtRoof"] = constr
    end
    
    # Apply constructions to surfaces
    constructions_to_surfaces.each do |construction, surfaces|
        surfaces.each do |surface|
            surface.setConstruction(constructions_to_objects[construction])
            runner.registerInfo("Surface '#{surface.name}', of Space '#{Geometry.get_space_from_surface(model, surface.name.to_s, runner).name.to_s}' and with Surface Type '#{surface.surfaceType}' and Outside Boundary Condition '#{surface.outsideBoundaryCondition}', was assigned Construction '#{construction}'")
        end
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsInsulatedRoof.new.registerWithApplication