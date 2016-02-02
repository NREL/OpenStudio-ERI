#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsFinishedBasement < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Finished Basement Constructions"
  end

  def description
    return "This measure assigns constructions to the finished basement walls, floor, and rim joists."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for the finished basement walls, floor, and rim joists. Finds surfaces adjacent to the finished basement and sets applicable constructions."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    fbsmtins_display_names = OpenStudio::StringVector.new
    fbsmtins_display_names << "Uninsulated"
    fbsmtins_display_names << "Half Wall"
    fbsmtins_display_names << "Whole Wall"

    #make a choice argument for finished basement insulation type
    selected_fbsmtins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtins", fbsmtins_display_names, true)
    selected_fbsmtins.setDisplayName("Finished Basement: Insulation Type")
	selected_fbsmtins.setDescription("The type of insulation.")
	selected_fbsmtins.setDefaultValue("Whole Wall")
    args << selected_fbsmtins

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "None"
    studsize_display_names << "2x4, 16 in o.c."
    studsize_display_names << "2x6, 24 in o.c."

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, false)
    selected_studsize.setDisplayName("Finished Basement: Cavity Depth")
	selected_studsize.setUnits("in")
	selected_studsize.setDescription("Depth of the stud cavity.")
    selected_studsize.setDefaultValue("None")
    args << selected_studsize

    #make a double argument for unfinished basement whole wall cavity insulation R-value
    userdefined_fbsmtwallcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcavr", false)
    userdefined_fbsmtwallcavr.setDisplayName("Finished Basement: Cavity Insulation Installed R-value")
	userdefined_fbsmtwallcavr.setUnits("hr-ft^2-R/Btu")
	userdefined_fbsmtwallcavr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_fbsmtwallcavr.setDefaultValue(0)
    args << userdefined_fbsmtwallcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Finished Basement: Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade

	#make a bool argument for whether the cavity insulation fills the cavity
	selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", true)
	selected_insfills.setDisplayName("Finished Basement: Insulation Fills Cavity")
	selected_insfills.setDescription("Specifies whether the cavity insulation completely fills the depth of the wall cavity.")
    selected_insfills.setDefaultValue(false)
	args << selected_insfills

    #make a double argument for finished basement wall continuous R-value
    userdefined_fbsmtwallcontth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcontth", false)
    userdefined_fbsmtwallcontth.setDisplayName("Finished Basement: Continuous Insulation Thickness")
	userdefined_fbsmtwallcontth.setUnits("in")
	userdefined_fbsmtwallcontth.setDescription("The thickness of the continuous insulation.")
    userdefined_fbsmtwallcontth.setDefaultValue(2.0)
    args << userdefined_fbsmtwallcontth

    #make a double argument for finished basement wall continuous insulation R-value
    userdefined_fbsmtwallcontr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcontr", false)
    userdefined_fbsmtwallcontr.setDisplayName("Finished Basement: Continuous Insulation Nominal R-value")
	userdefined_fbsmtwallcontr.setUnits("hr-ft^2-R/Btu")
	userdefined_fbsmtwallcontr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_fbsmtwallcontr.setDefaultValue(10.0)
    args << userdefined_fbsmtwallcontr

    # Ceiling Joist Height
    #make a choice argument for model objects
    joistheight_display_names = OpenStudio::StringVector.new
    joistheight_display_names << "2x10"

	#make a choice argument for finished basement ceiling joist height
	selected_fbsmtceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtceiljoistheight", joistheight_display_names, true)
	selected_fbsmtceiljoistheight.setDisplayName("Finished Basement: Ceiling Joist Height")
	selected_fbsmtceiljoistheight.setUnits("in")
	selected_fbsmtceiljoistheight.setDescription("Height of the joist member.")
	selected_fbsmtceiljoistheight.setDefaultValue("2x10")
	args << selected_fbsmtceiljoistheight	

    # Ceiling Framing Factor
	#make a choice argument for finished basement ceiling framing factor
	userdefined_fbsmtceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtceilff", false)
    userdefined_fbsmtceilff.setDisplayName("Finished Basement: Ceiling Framing Factor")
	userdefined_fbsmtceilff.setUnits("frac")
	userdefined_fbsmtceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_fbsmtceilff.setDefaultValue(0.13)
	args << userdefined_fbsmtceilff

	#make a double argument for rim joist insulation R-value
	userdefined_fbsmtrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtrimjoistr", false)
	userdefined_fbsmtrimjoistr.setDisplayName("Finished Basement: Rim Joist Insulation R-value")
	userdefined_fbsmtrimjoistr.setUnits("hr-ft^2-R/Btu")
	userdefined_fbsmtrimjoistr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_fbsmtrimjoistr.setDefaultValue(10.0)
	args << userdefined_fbsmtrimjoistr

    #make a double argument for floor mass thickness
    userdefined_floormassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassth", false)
    userdefined_floormassth.setDisplayName("Floor Mass: Thickness")
	userdefined_floormassth.setUnits("in")
	userdefined_floormassth.setDescription("Thickness of the floor mass.")
    userdefined_floormassth.setDefaultValue(0.625)
    args << userdefined_floormassth

    #make a double argument for floor mass conductivity
    userdefined_floormasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasscond", false)
    userdefined_floormasscond.setDisplayName("Floor Mass: Conductivity")
	userdefined_floormasscond.setUnits("Btu-in/h-ft^2-R")
	userdefined_floormasscond.setDescription("Conductivity of the floor mass.")
    userdefined_floormasscond.setDefaultValue(0.8004)
    args << userdefined_floormasscond

    #make a double argument for floor mass density
    userdefined_floormassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassdens", false)
    userdefined_floormassdens.setDisplayName("Floor Mass: Density")
	userdefined_floormassdens.setUnits("lb/ft^3")
	userdefined_floormassdens.setDescription("Density of the floor mass.")
    userdefined_floormassdens.setDefaultValue(34.0)
    args << userdefined_floormassdens

    #make a double argument for floor mass specific heat
    userdefined_floormasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasssh", false)
    userdefined_floormasssh.setDisplayName("Floor Mass: Specific Heat")
	userdefined_floormasssh.setUnits("Btu/lb-R")
	userdefined_floormasssh.setDescription("Specific heat of the floor mass.")
    userdefined_floormasssh.setDefaultValue(0.29)
    args << userdefined_floormasssh

    #make a double argument for carpet pad R-value
    userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
    userdefined_carpetr.setDisplayName("Carpet: Carpet Pad R-value")
	userdefined_carpetr.setUnits("hr-ft^2-R/Btu")
	userdefined_carpetr.setDescription("The combined R-value of the carpet and the pad.")
    userdefined_carpetr.setDefaultValue(2.08)
    args << userdefined_carpetr

    #make a double argument for carpet floor fraction
    userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
    userdefined_carpetfrac.setDisplayName("Carpet: Floor Carpet Fraction")
	userdefined_carpetfrac.setUnits("frac")
	userdefined_carpetfrac.setDescription("Defines the fraction of a floor which is covered by carpet.")
    userdefined_carpetfrac.setDefaultValue(0.8)
    args << userdefined_carpetfrac

    #make a choice argument for finished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.FinishedBasementSpaceType)
        space_type_args << Constants.FinishedBasementSpaceType
    end
    fbasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_space_type", space_type_args, true)
    fbasement_space_type.setDisplayName("Finished basement space type")
    fbasement_space_type.setDescription("Select the finished basement space type")
    fbasement_space_type.setDefaultValue(Constants.FinishedBasementSpaceType)
    args << fbasement_space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    fbsmtWallContInsRvalue = 0
    fbsmtWallCavityInsRvalueInstalled = 0
    fbsmtWallInsHeight = 0
    fbsmtRimJoistInsRvalue = 0
    carpetPadRValue = 0

    # Space Type
	fbasement_space_type_r = runner.getStringArgumentValue("fbasement_space_type",user_arguments)
    fbasement_space_type = HelperMethods.get_space_type_from_string(model, fbasement_space_type_r, runner, false)
    if fbasement_space_type.nil?
        # If the building has no finished basement, no constructions are assigned and we continue by returning True
        return true
    end

    # Initialize hashes
    constructions_to_surfaces = {"GrndInsFinWall"=>[], "GrndUninsFinBFloor"=>[], "FBsmtRimJoist"=>[]}
    constructions_to_objects = Hash.new     
    
    # Finished basement walls, floor, rimjoists
	fbasement_space_type.spaces.each do |fbasement_space|
	  fbasement_space.surfaces.each do |fbasement_surface|
	    if fbasement_surface.surfaceType.downcase == "wall" and fbasement_surface.outsideBoundaryCondition.downcase == "ground"
          constructions_to_surfaces["GrndInsFinWall"] << fbasement_surface
		elsif fbasement_surface.surfaceType.downcase == "floor" and fbasement_surface.outsideBoundaryCondition.downcase == "ground"
          constructions_to_surfaces["GrndUninsFinBFloor"] << fbasement_surface
		elsif fbasement_surface.surfaceType.downcase == "wall" and fbasement_surface.outsideBoundaryCondition.downcase == "outdoors"
          constructions_to_surfaces["FBsmtRimJoist"] << fbasement_surface
		end
	  end	
	end
    
    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end           
    
    # Unfinished Basement Insulation
    selected_fbsmtins = runner.getStringArgumentValue("selectedfbsmtins",user_arguments)

    # Wall Cavity
    selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
    userdefined_fbsmtwallcavr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcavr",user_arguments)
    selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
    selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)

    # Whole Wall Cavity Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      userdefined_fbsmtwallcavr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcavr",user_arguments)
    end

    # Wall Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      userdefined_fbsmtwallcontth = runner.getDoubleArgumentValue("userdefinedfbsmtwallcontth",user_arguments)
      userdefined_fbsmtwallcontr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcontr",user_arguments)
      if selected_fbsmtins.to_s == "Half Wall"
        fbsmtWallInsHeight = 4
      elsif selected_fbsmtins.to_s == "Whole Wall"
        fbsmtWallInsHeight = 8
      end
    end

    # Ceiling Joist Height
    selected_fbsmtceiljoistheight = runner.getStringArgumentValue("selectedfbsmtceiljoistheight",user_arguments)

    # Ceiling Framing Factor
    userdefined_fbsmtceilff = runner.getDoubleArgumentValue("userdefinedfbsmtceilff",user_arguments)
    if not ( userdefined_fbsmtceilff > 0.0 and userdefined_fbsmtceilff < 1.0 )
      runner.registerError("Invalid finished basement ceiling framing factor")
      return false
    end

    # Rim Joist
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      userdefined_fbsmtrimjoistr = runner.getDoubleArgumentValue("userdefinedfbsmtrimjoistr",user_arguments)
    end

    # Gypsum
    gypsumThickness = 0
    gypsumNumLayers = 0
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        gypsumNumLayers = 0
        construction.layers.each do |layer|
          if layer.name.to_s == "GypsumBoard-ExtWall"
            gypsumThickness = OpenStudio::convert(layer.thickness,"m","in").get
            gypsumNumLayers += 1
          end
        end
      end
    end
    gypsumConductivity = Material.Gypsum1_2in.k
    gypsumDensity = Material.Gypsum1_2in.rho
    gypsumSpecificHeat = Material.Gypsum1_2in.Cp
    gypsumThermalAbs = Material.Gypsum1_2in.TAbs
    gypsumSolarAbs = Material.Gypsum1_2in.SAbs
    gypsumVisibleAbs = Material.Gypsum1_2in.VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / Material.Gypsum1_2in.k)

    # Floor Mass
    floorMassThickness = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
    floorMassConductivity = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
    floorMassDensity = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
	floorMassSpecificHeat = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)

    # Carpet
    carpetPadRValue = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    carpetFloorFraction = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    # Cavity Insulation
    if selected_fbsmtins.to_s == "Half Wall" or selected_fbsmtins.to_s == "Whole Wall"
      fbsmtWallCavityInsRvalueInstalled = userdefined_fbsmtwallcavr
    end

    # Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      fbsmtWallContInsThickness = userdefined_fbsmtwallcontth
      fbsmtWallContInsRvalue = userdefined_fbsmtwallcontr
    end

    # Wall Cavity
    fbsmtWallInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
    fbsmtWallInstallGrade = fbsmtWallInstallGrade_dict[selected_installgrade]
    fbsmtWallCavityDepth_dict = {"None"=>0, "2x4, 16 in o.c."=>3.5, "2x6, 24 in o.c."=>5.5}
    fbsmtWallCavityDepth = fbsmtWallCavityDepth_dict[selected_studsize]
    fbsmtWallFramingFactor_dict = {"None"=>0, "2x4, 16 in o.c."=>0.25, "2x6, 24 in o.c."=>0.22}
    fbsmtWallFramingFactor = fbsmtWallFramingFactor_dict[selected_studsize]
    fbsmtWallCavityInsFillsCavity = selected_insfills

    # Ceiling Joist Height
    fbsmtCeilingJoistHeight_dict = {"2x10"=>9.25}
    fbsmtCeilingJoistHeight = fbsmtCeilingJoistHeight_dict[selected_fbsmtceiljoistheight]

    # Ceiling Framing Factor
    fbsmtCeilingFramingFactor = userdefined_fbsmtceilff

    # Rim Joist
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      fbsmtRimJoistInsRvalue = userdefined_fbsmtrimjoistr
    end

    # Exterior Finish
    finishThickness = 0
    finishConductivity = 0
    extfin = nil
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        construction.layers.each do |layer|
          if layer.name.to_s == "ExteriorFinish"
            extfin = layer
            finishThickness = OpenStudio::convert(layer.thickness,"m","in").get
            finishConductivity = OpenStudio::convert(layer.to_StandardOpaqueMaterial.get.conductivity,"W/m*K","Btu*in/hr*ft^2*R").get
          end
        end
      end
    end

    # Rigid
    wallSheathingContInsThickness = 0
    wallSheathingContInsRvalue = 0
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        construction.layers.each do |layer|
          if layer.name.to_s == "WallRigidIns"
            wallSheathingContInsThickness = OpenStudio::convert(layer.thickness,"m","in").get
            wallSheathingContInsConductivity = OpenStudio::convert(layer.to_StandardOpaqueMaterial.get.conductivity,"W/m*K","Btu*in/hr*ft^2*R").get
            wallSheathingContInsRvalue = wallSheathingContInsThickness/wallSheathingContInsConductivity
          end
        end
      end
    end

    if fbsmtWallContInsRvalue == 0 and fbsmtWallCavityInsRvalueInstalled == 0
      fbsmtRimJoistInsRvalue = 0
    else
      fbsmtRimJoistInsRvalue = fbsmtRimJoistInsRvalue
    end

    # Process the slab
    wall_thick, wall_cond, wall_dens, wall_sh, fb_add_insul_layer, fb_fictitious_Rvalue, fb_floor_Rvalue, rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue = _processConstructionsFinishedBasement(fbsmtWallContInsRvalue, fbsmtWallContInsThickness, fbsmtWallCavityInsFillsCavity, fbsmtWallCavityInsRvalueInstalled, fbsmtWallInstallGrade, fbsmtWallCavityDepth, fbsmtWallFramingFactor, fbsmtWallInsHeight, fbsmtCeilingJoistHeight, fbsmtCeilingFramingFactor, fbsmtRimJoistInsRvalue, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, gypsumThickness, gypsumNumLayers, gypsumRvalue, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)

    # FBaseWall-FicR
    if fb_fictitious_Rvalue > 0
      fwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
      fwfr.setName("FBaseWall-FicR")
      fwfr.setRoughness("Rough")
      fwfr.setThermalResistance(OpenStudio::convert(fb_fictitious_Rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
    end

    # Soil-12in
    soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    soil.setName("Soil-12in")
    soil.setRoughness("Rough")
    soil.setThickness(OpenStudio::convert(Material.Soil12in.thick,"ft","m").get)
    soil.setConductivity(OpenStudio::convert(Material.Soil12in.k,"Btu/hr*ft*R","W/m*K").get)
    soil.setDensity(OpenStudio::convert(Material.Soil12in.rho,"lb/ft^3","kg/m^3").get)
    soil.setSpecificHeat(OpenStudio::convert(Material.Soil12in.Cp,"Btu/lb*R","J/kg*K").get)

    # Concrete-8in
    conc8 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    conc8.setName("Concrete-8in")
    conc8.setRoughness("Rough")
    conc8.setThickness(OpenStudio::convert(Material.Concrete8in.thick,"ft","m").get)
    conc8.setConductivity(OpenStudio::convert(Material.Concrete8in.k,"Btu/hr*ft*R","W/m*K").get)
    conc8.setDensity(OpenStudio::convert(Material.Concrete8in.rho,"lb/ft^3","kg/m^3").get)
    conc8.setSpecificHeat(OpenStudio::convert(Material.Concrete8in.Cp,"Btu/lb*R","J/kg*K").get)
    conc8.setThermalAbsorptance(Material.Concrete8in.TAbs)

    # FBaseWallIns
    if fb_add_insul_layer
      fwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      fwi.setName("FBaseWallIns")
      fwi.setRoughness("Rough")
      fwi.setThickness(OpenStudio::convert(wall_thick,"ft","m").get)
      fwi.setConductivity(OpenStudio::convert(wall_cond,"Btu/hr*ft*R","W/m*K").get)
      fwi.setDensity(OpenStudio::convert(wall_dens,"lb/ft^3","kg/m^3").get)
      fwi.setSpecificHeat(OpenStudio::convert(wall_sh,"Btu/lb*R","J/kg*K").get)
    end

    # Gypsum
    gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gypsum.setName("GypsumBoard-1_2in")
    gypsum.setRoughness("Rough")
    gypsum.setThickness(OpenStudio::convert(0.5,"in","m").get)
    gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
    gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
    gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
    gypsum.setThermalAbsorptance(gypsumThermalAbs)
    gypsum.setSolarAbsorptance(gypsumSolarAbs)
    gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

    # GrndInsFinWall
	materials = []
    if fb_fictitious_Rvalue > 0
      materials << fwfr
    end
    materials << soil
    materials << conc8
    if fb_add_insul_layer
      materials << fwi
    end
    materials << gypsum
    unless constructions_to_surfaces["GrndInsFinWall"].empty?
        grndinsfinwall = OpenStudio::Model::Construction.new(materials)
        grndinsfinwall.setName("GrndInsFinWall")
        constructions_to_objects["GrndInsFinWall"] = grndinsfinwall
    end
	
    # FBaseFloor-FicR
    fffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    fffr.setRoughness("Rough")
    fffr.setName("FBaseFloor-FicR")
    fffr.setThermalResistance(OpenStudio::convert(fb_floor_Rvalue,"hr*ft^2*R/Btu","m^2*K/W").get)

    # Concrete-4in
    conc4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    conc4.setName("Concrete-4in")
    conc4.setRoughness("Rough")
    conc4.setThickness(OpenStudio::convert(Material.Concrete4in.thick,"ft","m").get)
    conc4.setConductivity(OpenStudio::convert(Material.Concrete4in.k,"Btu/hr*ft*R","W/m*K").get)
    conc4.setDensity(OpenStudio::convert(Material.Concrete4in.rho,"lb/ft^3","kg/m^3").get)
    conc4.setSpecificHeat(OpenStudio::convert(Material.Concrete4in.Cp,"Btu/lb*R","J/kg*K").get)
    conc4.setThermalAbsorptance(Material.Concrete4in.TAbs)

    # GrndUninsFinBFloor
    materials = []
    materials << fffr
    materials << soil
    materials << conc4
    unless constructions_to_surfaces["GrndUninsFinBFloor"].empty?
        grnduninsfinbfloor = OpenStudio::Model::Construction.new(materials)
        grnduninsfinbfloor.setName("GrndUninsFinBFloor")
        constructions_to_objects["GrndUninsFinBFloor"] = grnduninsfinbfloor
    end
	
    # Rigid
    if wallSheathingContInsRvalue > 0
        rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
        rigid.setName("WallRigidIns")
        rigid.setRoughness("Rough")
		rigid.setThickness(OpenStudio::convert(wallSheathingContInsThickness,"in","m").get)
		rigid.setConductivity(OpenStudio::convert(wallSheathingContInsConductivity,"Btu/hr*ft*R","W/m*K").get)
		rigid.setDensity(OpenStudio::convert(BaseMaterial.RigidInsulation.rho,"lb/ft^3","kg/m^3").get)
		rigid.setSpecificHeat(OpenStudio::convert(BaseMaterial.RigidInsulation.Cp,"Btu/lb*R","J/kg*K").get)
    end

    # Plywood-3_2in
    ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_2.setName("Plywood-3_2in")
    ply3_2.setRoughness("Rough")
    ply3_2.setThickness(OpenStudio::convert(Material.Plywood3_2in.thick,"ft","m").get)
    ply3_2.setConductivity(OpenStudio::convert(Material.Plywood3_2in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_2.setDensity(OpenStudio::convert(Material.Plywood3_2in.rho,"lb/ft^3","kg/m^3").get)
    ply3_2.setSpecificHeat(OpenStudio::convert(Material.Plywood3_2in.Cp,"Btu/lb*R","J/kg*K").get)

    # FBsmtJoistandCavity
    if rj_Rvalue > 0
      fjc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      fjc.setName("FBsmtJoistandCavity")
      fjc.setRoughness("Rough")
      fjc.setThickness(OpenStudio::convert(rj_thick,"ft","m").get)
      fjc.setConductivity(OpenStudio::convert(rj_cond,"Btu/hr*ft*R","W/m*K").get)
      fjc.setDensity(OpenStudio::convert(rj_dens,"lb/ft^3","kg/m^3").get)
      fjc.setSpecificHeat(OpenStudio::convert(rj_sh,"Btu/lb*R","J/kg*K").get)
    end

    # FBsmtRimJoist
    materials = []
    materials << extfin.to_StandardOpaqueMaterial.get
    if wallSheathingContInsRvalue > 0
      materials << rigid
    end
    materials << ply3_2
    if rj_Rvalue > 0
      materials << fjc
    end
    if gypsumNumLayers > 1
      materials << gypsum
      materials << gypsum
    else
      materials << gypsum
    end
    unless constructions_to_surfaces["FBsmtRimJoist"].empty?
        fbsmtrimjoist = OpenStudio::Model::Construction.new(materials)
        fbsmtrimjoist.setName("FBsmtRimJoist")
        constructions_to_objects["FBsmtRimJoist"] = fbsmtrimjoist
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

  def _processConstructionsFinishedBasement(fbsmtWallContInsRvalue, fbsmtWallContInsThickness, fbsmtWallCavityInsFillsCavity, fbsmtWallCavityInsRvalueInstalled, fbsmtWallInstallGrade, fbsmtWallCavityDepth, fbsmtWallFramingFactor, fbsmtWallInsHeight, fbsmtCeilingJoistHeight, fbsmtCeilingFramingFactor, fbsmtRimJoistInsRvalue, carpetFloorFraction, carpetPadRValue, floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat, gypsumThickness, gypsumNumLayers, gypsumRvalue, wallSheathingContInsThickness, wallSheathingContInsRvalue, finishThickness, finishConductivity)
    # Calculate overall R value of the basement wall, including framed walls with cavity insulation
    overall_wall_Rvalue = Construction.GetWoodStudWallAssemblyR(fbsmtWallCavityInsFillsCavity, fbsmtWallCavityInsRvalueInstalled,
                                                                fbsmtWallInstallGrade, fbsmtWallCavityDepth, fbsmtWallFramingFactor,    
                                                                "FBsmt", gypsumThickness, gypsumNumLayers, 0, nil, 
                                                                fbsmtWallContInsThickness, fbsmtWallContInsRvalue, true)

    conduction_factor = Construction.GetBasementConductionFactor(fbsmtWallInsHeight, overall_wall_Rvalue)

    # FIXME: Currently hard-coded
    fbWallArea = 1376
    fbExtPerimeter = 172

    if fbExtPerimeter > 0
      fb_effective_Rvalue = fbWallArea / (conduction_factor * fbExtPerimeter) # hr*ft^2*F/Btu
    else
      fb_effective_Rvalue = 1000 # hr*ft^2*F/Btu
    end

    # Insulation of 4ft height inside a 8ft basement is modeled completely in the fictitious layer
    if fbsmtWallContInsRvalue > 0 and fbsmtWallInsHeight == 8
      fb_add_insul_layer = true
    else
      fb_add_insul_layer = false
    end

    if fb_add_insul_layer
      wall_Rvalue = fbsmtWallContInsRvalue # hr*ft^2*F/Btu
      wall_thick = wall_Rvalue * BaseMaterial.InsulationRigid.k # ft
      wall_cond = BaseMaterial.InsulationRigid.k # Btu/hr*ft*F
      wall_dens = BaseMaterial.InsulationRigid.rho # lbm/ft^3
      wall_sh = BaseMaterial.InsulationRigid.Cp # Btu/lbm*F
    else
      wall_Rvalue = 0 # hr*ft^2*F/Btu
    end

    fb_US_Rvalue = Material.Concrete8in.Rvalue + Material.AirFilmVertical.Rvalue + wall_Rvalue + Material.Gypsum1_2in.Rvalue

    fb_fictitious_Rvalue = fb_effective_Rvalue - Material.Soil12in.Rvalue - fb_US_Rvalue

    # Fictitious layer behind finished basement wall to achieve equivalent R-value. See Winkelmann article.

    fb_total_ua = fbWallArea / fb_effective_Rvalue # FBasementTotalUA

    if fb_fictitious_Rvalue < 0
      area = 1505 # FIXME: Currently hard-coded
      fb_floor_Rvalue = area / (fb_total_ua - fbWallArea / (fb_US_Rvalue + Material.Soil12in.Rvalue)) - Material.Soil12in.Rvalue - Material.Concrete4in.Rvalue # hr*ft^2*F/Btu
    else
      fb_floor_Rvalue = 1000 # hr*ft^2*F/Btu
    end

    rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue = _processConstructionsFinishedBasementRimJoist(fbsmtWallContInsRvalue, fbsmtCeilingJoistHeight, fbsmtCeilingFramingFactor, fbsmtRimJoistInsRvalue, wallSheathingContInsThickness, wallSheathingContInsRvalue, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity)

    return wall_thick, wall_cond, wall_dens, wall_sh, fb_add_insul_layer, fb_fictitious_Rvalue, fb_floor_Rvalue, rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue

  end

  def _processConstructionsFinishedBasementRimJoist(fbsmtWallContInsRvalue, fbsmtCeilingJoistHeight, fbsmtCeilingFramingFactor, fbsmtRimJoistInsRvalue, wallSheathingContInsThickness, wallSheathingContInsRvalue, gypsumThickness, gypsumNumLayers, gypsumRvalue, finishThickness, finishConductivity)

    rimjoist_framingfactor = 0.6 * fbsmtCeilingFramingFactor #0.6 Factor added for due joist orientation
    mat_2x = Material.Stud2x(fbsmtCeilingJoistHeight)

    rj_Rvalue = Construction.GetRimJoistAssmeblyR(fbsmtRimJoistInsRvalue, fbsmtCeilingJoistHeight, wallSheathingContInsThickness, wallSheathingContInsRvalue, gypsumThickness, gypsumNumLayers, rimjoist_framingfactor, finishThickness, finishConductivity)

    fb_rimjoist_studlayer_Rvalue = rj_Rvalue - Construction.GetRimJoistNonStudLayerR

    rj_thick = mat_2x.thick
    rj_cond = rj_thick / fb_rimjoist_studlayer_Rvalue

    if fbsmtWallContInsRvalue > 0 # insulated rim joist
      rj_dens = rimjoist_framingfactor * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * BaseMaterial.InsulationGenericDensepack.rho # lbm/ft^3
      rj_sh = (rimjoist_framingfactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * BaseMaterial.InsulationGenericDensepack.Cp * BaseMaterial.InsulationGenericDensepack.rho) / rj_dens # Btu/lbm*F
    else # no insulation
      rj_dens = rimjoist_framingfactor * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * Gas.Air.Cp # lbm/ft^3
      rj_sh = (rimjoist_framingfactor * BaseMaterial.Wood.Cp * BaseMaterial.Wood.rho + (1 - rimjoist_framingfactor) * Gas.Air.Cp * Gas.Air.Cp) / rj_dens # Btu/lbm*F
    end

    return rj_thick, rj_cond, rj_dens, rj_sh, rj_Rvalue

  end

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFinishedBasement.new.registerWithApplication