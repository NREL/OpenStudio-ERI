#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
#require "#{File.dirname(__FILE__)}/resources/sim"
require "C:/OS-BEopt/OpenStudio-Beopt/resources/sim"

#start the measure
class ProcessConstructionsFinishedBasement < OpenStudio::Ruleset::ModelUserScript

  class FinishedBasement
    def initialize(fbsmtWallContInsRvalue, fbsmtWallContInsThickness, fbsmtWallCavityInsFillsCavity, fbsmtWallCavityInsRvalueInstalled, fbsmtWallInstallGrade, fbsmtWallCavityDepth, fbsmtWallFramingFactor, fbsmtWallInsHeight, fbsmtCeilingJoistHeight, fbsmtCeilingFramingFactor)
      @fbsmtWallContInsRvalue = fbsmtWallContInsRvalue
      @fbsmtWallContInsThickness = fbsmtWallContInsThickness
      @fbsmtWallCavityInsFillsCavity = fbsmtWallCavityInsFillsCavity
      @fbsmtWallCavityInsRvalueInstalled = fbsmtWallCavityInsRvalueInstalled
      @fbsmtWallInstallGrade = fbsmtWallInstallGrade
      @fbsmtWallCavityDepth = fbsmtWallCavityDepth
      @fbsmtWallFramingFactor = fbsmtWallFramingFactor
      @fbsmtWallInsHeight = fbsmtWallInsHeight
      @fbsmtCeilingJoistHeight = fbsmtCeilingJoistHeight
      @fbsmtCeilingFramingFactor = fbsmtCeilingFramingFactor
    end

    attr_accessor(:conduction_factor, :FBsmtRimJoistInsRvalue, :wall_area, :ext_perimeter)

    def FBsmtWallContInsRvalue
      return @fbsmtWallContInsRvalue
    end

    def FBsmtWallContInsThickness
      return @fbsmtWallContInsThickness
    end

    def FBsmtWallCavityInsFillsCavity
      return @fbsmtWallCavityInsFillsCavity
    end

    def FBsmtWallCavityInsRvalueInstalled
      return @fbsmtWallCavityInsRvalueInstalled
    end

    def FBsmtWallInstallGrade
      return @fbsmtWallInstallGrade
    end

    def FBsmtWallCavityDepth
      return @fbsmtWallCavityDepth
    end

    def FBsmtWallFramingFactor
      return @fbsmtWallFramingFactor
    end

    def FBsmtWallInsHeight
      return @fbsmtWallInsHeight
    end

    def FBsmtCeilingJoistHeight
      return @fbsmtCeilingJoistHeight
    end

    def FBsmtCeilingFramingFactor
      return @fbsmtCeilingFramingFactor
    end
  end

  class Carpet
    def initialize(carpetFloorFraction, carpetPadRValue)
      @carpetFloorFraction = carpetFloorFraction
      @carpetPadRValue = carpetPadRValue
    end

    attr_accessor(:floor_bare_fraction)

    def CarpetFloorFraction
      return @carpetFloorFraction
    end

    def CarpetPadRValue
      return @carpetPadRValue
    end
  end

  class FloorMass
    def initialize(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
      @floorMassThickness = floorMassThickness
      @floorMassConductivity = floorMassConductivity
      @floorMassDensity = floorMassDensity
      @floorMassSpecificHeat = floorMassSpecificHeat
    end

    def FloorMassThickness
      return @floorMassThickness
    end

    def FloorMassConductivity
      return @floorMassConductivity
    end

    def FloorMassDensity
      return @floorMassDensity
    end

    def FloorMassSpecificHeat
      return @floorMassSpecificHeat
    end
  end

  class ExtWallMass
    def initialize(gypsumThickness, gypsumNumLayers, gypsumRvalue)
      @gypsumThickness = gypsumThickness
      @gypsumNumLayers = gypsumNumLayers
      @gypsumRvalue = gypsumRvalue
    end

    def ExtWallMassGypsumThickness
      return @gypsumThickness
    end

    def ExtWallMassGypsumNumLayers
      return @gypsumNumLayers
    end

    def ExtWallMassGypsumRvalue
      return @gypsumRvalue
    end
  end

  class WallSheathing
    def initialize(wallSheathingContInsThickness, wallSheathingContInsRvalue)
      @wallSheathingContInsThickness = wallSheathingContInsThickness
      @wallSheathingContInsRvalue = wallSheathingContInsRvalue
    end

    attr_accessor(:rigid_ins_layer_thickness, :rigid_ins_layer_conductivity, :rigid_ins_layer_density, :rigid_ins_layer_spec_heat)

    def WallSheathingContInsThickness
      return @wallSheathingContInsThickness
    end

    def WallSheathingContInsRvalue
      return @wallSheathingContInsRvalue
    end
  end

  class ExteriorFinish
    def initialize(finishThickness, finishConductivity)
      @finishThickness = finishThickness
      @finishConductivity = finishConductivity
    end

    def FinishThickness
      return @finishThickness
    end

    def FinishConductivity
      return @finishConductivity
    end
  end

  class FBaseWallIns
    def initialize
    end
    attr_accessor(:fb_wall_Rvalue, :fb_wall_thickness, :fb_wall_conductivity, :fb_wall_density, :fb_wall_specheat, :fb_add_insul_layer)
  end

  class FBaseWallFicR
    def initialize
    end
    attr_accessor(:fb_fictitious_Rvalue)
  end

  class FBaseFloorFicR
    def initialize
    end
    attr_accessor(:fb_floor_Rvalue)
  end

  class FBsmtJoistandCavity
    def initialize
    end
    attr_accessor(:fb_rimjoist_thickness, :fb_rimjoist_conductivity, :fb_rimjoist_density, :fb_rimjoist_spec_heat, :fb_rimjoist_Rvalue)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsUnfinishedBasement"
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

    #make a choice argument for finished basement
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", spacetype_handles, spacetype_display_names, true)
    selected_fbsmt.setDisplayName("Of what space type is the finished basement?")
    args << selected_fbsmt

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

    #make a choice argument for model objects
    fbsmtins_display_names = OpenStudio::StringVector.new
    fbsmtins_display_names << "Uninsulated"
    fbsmtins_display_names << "Half Wall"
    fbsmtins_display_names << "Whole Wall"

    #make a choice argument for finished basement insulation type
    selected_fbsmtins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtins", fbsmtins_display_names, true)
    selected_fbsmtins.setDisplayName("Finished basement insulation type.")
    args << selected_fbsmtins

    #make a choice argument for model objects
    studsize_display_names = OpenStudio::StringVector.new
    studsize_display_names << "None"
    studsize_display_names << "2x4, 16 in o.c."
    studsize_display_names << "2x6, 24 in o.c."

    #make a string argument for wood stud size of wall cavity
    selected_studsize = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedstudsize", studsize_display_names, false)
    selected_studsize.setDisplayName("Wood stud size of wall cavity.")
    selected_studsize.setDefaultValue("None")
    args << selected_studsize

    # Whole Wall Cavity Insulation
    # #make a choice argument for wall / ceiling cavity insulation
    # selected_fbsmtwallcav = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtwallcav", material_handles, material_display_names, false)
    # selected_fbsmtwallcav.setDisplayName("Finished basement whole wall cavity insulation. For manually entering finished basement whole wall cavity insulation properties, leave blank.")
    # args << selected_fbsmtwallcav

    #make a double argument for unfinished basement whole wall cavity insulation R-value
    userdefined_fbsmtwallcavr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcavr", false)
    userdefined_fbsmtwallcavr.setDisplayName("Finished basement whole wall cavity insulation R-value [hr-ft^2-R/Btu].")
    userdefined_fbsmtwallcavr.setDefaultValue(0)
    args << userdefined_fbsmtwallcavr

    #make a choice argument for model objects
    installgrade_display_names = OpenStudio::StringVector.new
    installgrade_display_names << "I"
    installgrade_display_names << "II"
    installgrade_display_names << "III"

    #make a choice argument for wall cavity insulation installation grade
    selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, false)
    selected_installgrade.setDisplayName("Insulation installation grade of wood stud wall cavity.")
    selected_installgrade.setDefaultValue("I")
    args << selected_installgrade

    #make a bool argument for whether the cavity insulation fills the cavity
    selected_insfills = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinsfills", false)
    selected_insfills.setDisplayName("Cavity insulation fills the cavity?")
    selected_insfills.setDefaultValue(true)
    args << selected_insfills

    # Wall Continuous Insulation
    # #make a choice argument for wall continuous insulation
    # selected_fbsmtwallcont = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtwallcont", material_handles, material_display_names, false)
    # selected_fbsmtwallcont.setDisplayName("Finished basement wall continuous insulation. For manually entering finished basement wall continuous insulation properties, leave blank.")
    # args << selected_fbsmtwallcont

    #make a double argument for finished basement wall continuous R-value
    userdefined_fbsmtwallcontth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcontth", false)
    userdefined_fbsmtwallcontth.setDisplayName("Finished basement wall continuous insulation thickness [in].")
    userdefined_fbsmtwallcontth.setDefaultValue(0)
    args << userdefined_fbsmtwallcontth

    #make a double argument for finished basement wall continuous insulation R-value
    userdefined_fbsmtwallcontr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtwallcontr", false)
    userdefined_fbsmtwallcontr.setDisplayName("Finished basement wall continuous insulation R-value [hr-ft^2-R/Btu].")
    userdefined_fbsmtwallcontr.setDefaultValue(0)
    args << userdefined_fbsmtwallcontr

    # Ceiling Joist Height
    #make a choice argument for model objects
    joistheight_display_names = OpenStudio::StringVector.new
    joistheight_display_names << "9.25"

    #make a choice argument for crawlspace ceiling joist height
    selected_fbsmtceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtceiljoistheight", joistheight_display_names, true)
    selected_fbsmtceiljoistheight.setDisplayName("Finished basement ceiling joist height [in].")
    args << selected_fbsmtceiljoistheight

    # Ceiling Framing Factor
    #make a choice argument for crawlspace ceiling framing factor
    userdefined_fbsmtceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtceilff", false)
    userdefined_fbsmtceilff.setDisplayName("Finished basement ceiling framing factor [frac].")
    userdefined_fbsmtceilff.setDefaultValue(0.13)
    args << userdefined_fbsmtceilff

    # Rim Joist
    # #make a choice argument for rim joist insulation
    # selected_fbsmtrimjoist = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmtrimjoist", material_handles, material_display_names, false)
    # selected_fbsmtrimjoist.setDisplayName("Finished basement rim joist insulation. For manually entering finished basement rim joist insulation properties, leave blank.")
    # args << selected_fbsmtrimjoist

    #make a double argument for rim joist insulation R-value
    userdefined_fbsmtrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfbsmtrimjoistr", false)
    userdefined_fbsmtrimjoistr.setDisplayName("Finished basement rim joist insulation R-value [hr-ft^2-R/Btu].")
    userdefined_fbsmtrimjoistr.setDefaultValue(0)
    args << userdefined_fbsmtrimjoistr

    # Floor Mass
    # #make a choice argument for floor mass
    # selected_floormass = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfloormass", material_handles, material_display_names, false)
    # selected_floormass.setDisplayName("Floor mass. For manually entering floor mass properties, leave blank.")
    # args << selected_floormass

    #make a double argument for floor mass thickness
    userdefined_floormassth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassth", false)
    userdefined_floormassth.setDisplayName("Floor mass thickness [in].")
    userdefined_floormassth.setDefaultValue(0.625)
    args << userdefined_floormassth

    #make a double argument for floor mass conductivity
    userdefined_floormasscond = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasscond", false)
    userdefined_floormasscond.setDisplayName("Floor mass conductivity [Btu-in/h-ft^2-R].")
    userdefined_floormasscond.setDefaultValue(0.8004)
    args << userdefined_floormasscond

    #make a double argument for floor mass density
    userdefined_floormassdens = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormassdens", false)
    userdefined_floormassdens.setDisplayName("Floor mass density [lb/ft^3].")
    userdefined_floormassdens.setDefaultValue(34.0)
    args << userdefined_floormassdens

    #make a double argument for floor mass specific heat
    userdefined_floormasssh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfloormasssh", false)
    userdefined_floormasssh.setDisplayName("Floor mass specific heat [Btu/lb-R].")
    userdefined_floormasssh.setDefaultValue(0.29)
    args << userdefined_floormasssh

    # Carpet
    # #make a choice argument for carpet pad R-value
    # selected_carpet = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcarpet", material_handles, material_display_names, false)
    # selected_carpet.setDisplayName("Carpet. For manually entering carpet properties, leave blank.")
    # args << selected_carpet

    #make a double argument for carpet pad R-value
    userdefined_carpetr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetr", false)
    userdefined_carpetr.setDisplayName("Carpet pad R-value [hr-ft^2-R/Btu].")
    userdefined_carpetr.setDefaultValue(2.08)
    args << userdefined_carpetr

    #make a double argument for carpet floor fraction
    userdefined_carpetfrac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcarpetfrac", false)
    userdefined_carpetfrac.setDisplayName("Carpet floor fraction [frac].")
    userdefined_carpetfrac.setDefaultValue(0.8)
    args << userdefined_carpetfrac

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
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)

    # Unfinished Basement Insulation
    selected_fbsmtins = runner.getStringArgumentValue("selectedfbsmtins",user_arguments)

    # Wall Cavity
    selected_studsize = runner.getStringArgumentValue("selectedstudsize",user_arguments)
    userdefined_fbsmtwallcavr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcavr",user_arguments)
    selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
    selected_insfills = runner.getBoolArgumentValue("selectedinsfills",user_arguments)

    # Whole Wall Cavity Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      selected_fbsmtwallcav = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmtwallcav",user_arguments,model)
      if selected_fbsmtwallcav.empty?
        userdefined_fbsmtwallcavr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcavr",user_arguments)
      end
    end

    # Wall Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      selected_fbsmtwallcont = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmtwallcont",user_arguments,model)
      if selected_fbsmtwallcont.empty?
        userdefined_fbsmtwallcontth = runner.getDoubleArgumentValue("userdefinedfbsmtwallcontth",user_arguments)
        userdefined_fbsmtwallcontr = runner.getDoubleArgumentValue("userdefinedfbsmtwallcontr",user_arguments)
      end
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
      selected_fbsmtrimjoist = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmtrimjoist",user_arguments,model)
      if selected_fbsmtrimjoist.empty?
        userdefined_fbsmtrimjoistr = runner.getDoubleArgumentValue("userdefinedfbsmtrimjoistr",user_arguments)
      end
    end

    # Gypsum
    userdefined_gypthickness = 0
    userdefined_gyplayers = 0
    constructions = model.getConstructions
    constructions.each do |construction|
      if construction.name.to_s == "ExtInsFinWall"
        userdefined_gyplayers = 0
        construction.layers.each do |layer|
          if layer.name.to_s == "GypsumBoard-ExtWall"
            userdefined_gypthickness = OpenStudio::convert(layer.thickness,"m","in").get
            userdefined_gyplayers += 1
          end
        end
      end
    end

    # Floor Mass
    selected_slabfloormass = runner.getOptionalWorkspaceObjectChoiceValue("selectedfloormass",user_arguments,model)
    if selected_slabfloormass.empty?
      userdefined_floormassth = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
      userdefined_floormasscond = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
      userdefined_floormassdens = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
      userdefined_floormasssh = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)
    end

    # Carpet
    selected_carpet = runner.getOptionalWorkspaceObjectChoiceValue("selectedcarpet",user_arguments,model)
    if selected_carpet.empty?
      userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
    end
    userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

    # Constants
    mat_gyp = get_mat_gypsum
    mat_wood = get_mat_wood
    mat_soil = get_mat_soil
    mat_concrete = get_mat_concrete

    # Cavity Insulation
    if selected_fbsmtins.to_s == "Half Wall" or selected_fbsmtins.to_s == "Whole Wall"
      if userdefined_fbsmtwallcavr.nil?
        fbWallThickness = OpenStudio::convert(selected_fbsmtwallcav.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
        fbWallConductivity = OpenStudio::convert(selected_fbsmtwallcav.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
        fbsmtWallCavityInsRvalueInstalled = OpenStudio::convert(fbWallThickness,"in","ft").get / fbWallConductivity
      else
        fbsmtWallCavityInsRvalueInstalled = userdefined_fbsmtwallcavr
      end
    end

    # Continuous Insulation
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      if userdefined_fbsmtwallcontr.nil?
        fbWallThickness = OpenStudio::convert(selected_fbsmtwallcont.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
        fbWallConductivity = OpenStudio::convert(selected_fbsmtwallcont.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
        fbsmtWallContInsThickness = fbWallThickness
        fbsmtWallContInsRvalue = OpenStudio::convert(fbWallThickness,"in","ft").get / fbWallConductivity
      else
        fbsmtWallContInsThickness = userdefined_fbsmtwallcontth
        fbsmtWallContInsRvalue = userdefined_fbsmtwallcontr
      end
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
    fbsmtCeilingJoistHeight_dict = {"9.25"=>9.25}
    fbsmtCeilingJoistHeight = fbsmtCeilingJoistHeight_dict[selected_fbsmtceiljoistheight]

    # Ceiling Framing Factor
    fbsmtCeilingFramingFactor = userdefined_fbsmtceilff

    # Rim Joist
    if ["Half Wall", "Whole Wall"].include? selected_fbsmtins.to_s
      if userdefined_fbsmtrimjoistr.nil?
        fbRimJoistThickness = OpenStudio::convert(selected_fbsmtrimjoist.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
        fbRimJoistConductivity = OpenStudio::convert(selected_fbsmtrimjoist.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
        fbsmtRimJoistInsRvalue = OpenStudio::convert(fbRimJoistThickness,"in","ft").get / fbRimJoistConductivity
      else
        fbsmtRimJoistInsRvalue = userdefined_fbsmtrimjoistr
      end
    end

    # Gypsum
    gypsumRoughness = "Rough"
    gypsumThickness = userdefined_gypthickness
    gypsumNumLayers = userdefined_gyplayers
    gypsumConductivity = mat_gyp.k
    gypsumDensity = mat_gyp.rho
    gypsumSpecificHeat = mat_gyp.Cp
    gypsumThermalAbs = get_mat_gypsum1_2in(mat_gyp).TAbs
    gypsumSolarAbs = get_mat_gypsum1_2in(mat_gyp).SAbs
    gypsumVisibleAbs = get_mat_gypsum1_2in(mat_gyp).VAbs
    gypsumRvalue = (OpenStudio::convert(gypsumThickness,"in","ft").get * gypsumNumLayers / mat_gyp.k)

    # Floor Mass
    if userdefined_floormassth.nil?
      floorMassThickness = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      floorMassConductivity = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      floorMassDensity = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getDensity.value,"kg/m^3","lb/ft^3").get
      floorMassSpecificHeat = OpenStudio::convert(selected_floormass.get.to_StandardOpaqueMaterial.get.getSpecificHeat.value,"J/kg*K","Btu/lb*R").get
    else
      floorMassThickness = userdefined_floormassth
      floorMassConductivity = userdefined_floormasscond
      floorMassDensity = userdefined_floormassdens
      floorMassSpecificHeat = userdefined_floormasssh
    end

    # Carpet
    if userdefined_carpetr.nil?
      carpetPadThickness = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
      carpetPadConductivity = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
      carpetPadRValue = OpenStudio::convert(carpetPadThickness,"in","ft").get / carpetPadConductivity
    else
      carpetPadRValue = userdefined_carpetr
    end
    carpetFloorFraction = userdefined_carpetfrac

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
            wallSheathingContInsThickness = OpenStudio::convert(layer.to_StandardOpaqueMaterial.get.conductivity,"W/m*K","Btu*in/hr*ft^2*R").get
          end
        end
      end
    end

    # Create the material class instances
    fb = FinishedBasement.new(fbsmtWallContInsRvalue, fbsmtWallContInsThickness, fbsmtWallCavityInsFillsCavity, fbsmtWallCavityInsRvalueInstalled, fbsmtWallInstallGrade, fbsmtWallCavityDepth, fbsmtWallFramingFactor, fbsmtWallInsHeight, fbsmtCeilingJoistHeight, fbsmtCeilingFramingFactor)
    carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
    floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
    extwallmass = ExtWallMass.new(gypsumThickness, gypsumNumLayers, gypsumRvalue)
    fwi = FBaseWallIns.new
    fwfr = FBaseWallFicR.new
    fffr = FBaseFloorFicR.new
    fjc = FBsmtJoistandCavity.new
    wallsh = WallSheathing.new(wallSheathingContInsThickness, wallSheathingContInsRvalue)
    exterior_finish = ExteriorFinish.new(finishThickness, finishConductivity)

    if fbsmtWallContInsRvalue == 0 and fbsmtWallCavityInsRvalueInstalled == 0
      fb.FBsmtRimJoistInsRvalue = 0
    else
      fb.FBsmtRimJoistInsRvalue = fbsmtRimJoistInsRvalue
    end

    # Create the sim object
    sim = Sim.new(model)

    # Process the slab
    fwi, fwfr, fffr, fjc, wallsh = sim._processConstructionsFinishedBasement(fb, carpet, floor_mass, extwallmass, wallsh, exterior_finish, fwi, fwfr, fffr, fjc)

    # FBaseWall-FicR
    fwfrRvalue = fwfr.fb_fictitious_Rvalue
    if fwfrRvalue > 0
      fwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
      fwfr.setName("FBaseWall-FicR")
      fwfr.setRoughness("Rough")
      fwfr.setThermalResistance(OpenStudio::convert(fwfrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
    end

    # Soil-12in
    soil = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    soil.setName("Soil-12in")
    soil.setRoughness("Rough")
    soil.setThickness(OpenStudio::convert(get_mat_soil12in(mat_soil).thick,"ft","m").get)
    soil.setConductivity(OpenStudio::convert(mat_soil.k,"Btu/hr*ft*R","W/m*K").get)
    soil.setDensity(OpenStudio::convert(mat_soil.rho,"lb/ft^3","kg/m^3").get)
    soil.setSpecificHeat(OpenStudio::convert(mat_soil.Cp,"Btu/lb*R","J/kg*K").get)

    # Concrete-8in
    conc8 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    conc8.setName("Concrete-8in")
    conc8.setRoughness("Rough")
    conc8.setThickness(OpenStudio::convert(get_mat_concrete8in(mat_concrete).thick,"ft","m").get)
    conc8.setConductivity(OpenStudio::convert(mat_concrete.k,"Btu/hr*ft*R","W/m*K").get)
    conc8.setDensity(OpenStudio::convert(mat_concrete.rho,"lb/ft^3","kg/m^3").get)
    conc8.setSpecificHeat(OpenStudio::convert(mat_concrete.Cp,"Btu/lb*R","J/kg*K").get)
    conc8.setThermalAbsorptance(get_mat_concrete8in(mat_concrete).TAbs)

    # FBaseWallIns
    fwiThickness = fwi.fb_wall_thickness
    fwiConductivity = fwi.fb_wall_conductivity
    fwiDensity = fwi.fb_wall_density
    fwiSpecificHeat = fwi.fb_wall_specheat
    fwiaddinsullayer = fwi.fb_add_insul_layer
    if fwiaddinsullayer
      fwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      fwi.setName("FBaseWallIns")
      fwi.setRoughness("Rough")
      fwi.setThickness(OpenStudio::convert(fwiThickness,"ft","m").get)
      fwi.setConductivity(OpenStudio::convert(fwiConductivity,"Btu/hr*ft*R","W/m*K").get)
      fwi.setDensity(OpenStudio::convert(fwiDensity,"lb/ft^3","kg/m^3").get)
      fwi.setSpecificHeat(OpenStudio::convert(fwiSpecificHeat,"Btu/lb*R","J/kg*K").get)
    end

    # Gypsum
    gypsum = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    gypsum.setName("GypsumBoard-1_2in")
    gypsum.setRoughness(gypsumRoughness)
    gypsum.setThickness(OpenStudio::convert(0.5,"in","m").get)
    gypsum.setConductivity(OpenStudio::convert(gypsumConductivity,"Btu/hr*ft*R","W/m*K").get)
    gypsum.setDensity(OpenStudio::convert(gypsumDensity,"lb/ft^3","kg/m^3").get)
    gypsum.setSpecificHeat(OpenStudio::convert(gypsumSpecificHeat,"Btu/lb*R","J/kg*K").get)
    gypsum.setThermalAbsorptance(gypsumThermalAbs)
    gypsum.setSolarAbsorptance(gypsumSolarAbs)
    gypsum.setVisibleAbsorptance(gypsumVisibleAbs)

    # GrndInsFinWall
    layercount = 0
    grndinsfinwall = OpenStudio::Model::Construction.new(model)
    grndinsfinwall.setName("GrndInsFinWall")
    if fwfrRvalue > 0
      grndinsfinwall.insertLayer(layercount,fwfr)
      layercount += 1
    end
    grndinsfinwall.insertLayer(layercount,soil)
    layercount += 1
    grndinsfinwall.insertLayer(layercount,conc8)
    layercount += 1
    if fwiaddinsullayer
      grndinsfinwall.insertLayer(layercount,fwi)
      layercount += 1
    end
    grndinsfinwall.insertLayer(layercount,gypsum)

    # FBaseFloor-FicR
    fffrRvalue = fffr.fb_floor_Rvalue
    fffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    fffr.setRoughness("Rough")
    fffr.setName("FBaseFloor-FicR")
    fffr.setThermalResistance(OpenStudio::convert(fffrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)

    # Concrete-4in
    conc4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    conc4.setName("Concrete-4in")
    conc4.setRoughness("Rough")
    conc4.setThickness(OpenStudio::convert(get_mat_concrete4in(mat_concrete).thick,"ft","m").get)
    conc4.setConductivity(OpenStudio::convert(mat_concrete.k,"Btu/hr*ft*R","W/m*K").get)
    conc4.setDensity(OpenStudio::convert(mat_concrete.rho,"lb/ft^3","kg/m^3").get)
    conc4.setSpecificHeat(OpenStudio::convert(mat_concrete.Cp,"Btu/lb*R","J/kg*K").get)
    conc4.setThermalAbsorptance(get_mat_concrete4in(mat_concrete).TAbs)

    # GrndUninsFinBFloor
    layercount = 0
    grnduninsfinbfloor = OpenStudio::Model::Construction.new(model)
    grnduninsfinbfloor.setName("GrndUninsFinBFloor")
    grnduninsfinbfloor.insertLayer(layercount,fffr)
    layercount += 1
    grnduninsfinbfloor.insertLayer(layercount,soil)
    layercount += 1
    grnduninsfinbfloor.insertLayer(layercount,conc4)

    # Rigid
    if wallSheathingContInsRvalue > 0
      rigid = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      rigid.setName("WallRigidIns")
      rigid.setRoughness("Rough")
      rigid.setThickness(OpenStudio::convert(wallsh.rigid_ins_layer_thickness,"ft","m").get)
      rigid.setConductivity(OpenStudio::convert(wallsh.rigid_ins_layer_conductivity,"Btu/hr*ft*R","W/m*K").get)
      rigid.setDensity(OpenStudio::convert(wallsh.rigid_ins_layer_density,"lb/ft^3","kg/m^3").get)
      rigid.setSpecificHeat(OpenStudio::convert(wallsh.rigid_ins_layer_spec_heat,"Btu/lb*R","J/kg*K").get)
    end

    # Plywood-3_2in
    ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_2.setName("Plywood-3_2in")
    ply3_2.setRoughness("Rough")
    ply3_2.setThickness(OpenStudio::convert(get_mat_plywood3_2in(mat_wood).thick,"ft","m").get)
    ply3_2.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_2.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
    ply3_2.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)

    # FBsmtJoistandCavity
    fjcThickness = fjc.fb_rimjoist_thickness
    fjcConductivity = fjc.fb_rimjoist_conductivity
    fjcDensity = fjc.fb_rimjoist_density
    fjcSpecificHeat = fjc.fb_rimjoist_spec_heat
    fjcrimjoistrvalue = fjc.fb_rimjoist_Rvalue
    if fjcrimjoistrvalue > 0
      fjc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      fjc.setName("FBsmtJoistandCavity")
      fjc.setRoughness("Rough")
      fjc.setThickness(OpenStudio::convert(fjcThickness,"ft","m").get)
      fjc.setConductivity(OpenStudio::convert(fjcConductivity,"Btu/hr*ft*R","W/m*K").get)
      fjc.setDensity(OpenStudio::convert(fjcDensity,"lb/ft^3","kg/m^3").get)
      fjc.setSpecificHeat(OpenStudio::convert(fjcSpecificHeat,"Btu/lb*R","J/kg*K").get)
    end

    # FBsmtRimJoist
    layercount = 0
    fbsmtrimjoist = OpenStudio::Model::Construction.new(model)
    fbsmtrimjoist.setName("FBsmtRimJoist")
    fbsmtrimjoist.insertLayer(layercount,extfin)
    layercount += 1
    if wallsh.WallSheathingContInsRvalue > 0
      fbsmtrimjoist.insertLayer(layercount,rigid)
      layercount += 1
    end
    fbsmtrimjoist.insertLayer(layercount,ply3_2)
    layercount += 1
    if fjcrimjoistrvalue > 0
      fbsmtrimjoist.insertLayer(layercount,fjc)
      layercount += 1
    end
    if gypsumNumLayers > 1
      fbsmtrimjoist.insertLayer(layercount,gypsum)
      layercount += 1
      fbsmtrimjoist.insertLayer(layercount,gypsum)
      layercount += 1
    else
      fbsmtrimjoist.insertLayer(layercount,gypsum)
    end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_fbsmt.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grndinsfinwall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndInsFinWall"]
          elsif surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grnduninsfinbfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndUninsFinBFloor"]
          elsif surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(fbsmtrimjoist)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"FBsmtRimJoist"]
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
ProcessConstructionsFinishedBasement.new.registerWithApplication