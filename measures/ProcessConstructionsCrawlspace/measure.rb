#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsCrawlspace < OpenStudio::Ruleset::ModelUserScript
  
	class Crawlspace
		def initialize(crawlWallContInsRvalueNominal, crawlCeilingCavityInsRvalueNominal, crawlCeilingJoistHeight, crawlCeilingFramingFactor, crawlCeilingInstallGrade)
			@crawlWallContInsRvalueNominal = crawlWallContInsRvalueNominal
			@crawlCeilingCavityInsRvalueNominal = crawlCeilingCavityInsRvalueNominal
			@crawlCeilingJoistHeight = crawlCeilingJoistHeight
			@crawlCeilingFramingFactor = crawlCeilingFramingFactor
			@crawlCeilingInstallGrade = crawlCeilingInstallGrade
		end
		
		attr_accessor(:CrawlRimJoistInsRvalue, :ext_perimeter, :height, :crawlspace_area)
		
		def CrawlWallContInsRvalueNominal
			return @crawlWallContInsRvalueNominal
		end
		
		def CrawlCeilingCavityInsRvalueNominal
			return @crawlCeilingCavityInsRvalueNominal
		end
		
		def CrawlCeilingJoistHeight
			return @crawlCeilingJoistHeight
		end
		
		def CrawlCeilingFramingFactor
			return @crawlCeilingFramingFactor
		end
		
		def CrawlCeilingInstallGrade
			return @crawlCeilingInstallGrade
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
	
	class CrawlCeilingIns
		def initialize
		end
		attr_accessor(:crawl_ceiling_thickness, :crawl_ceiling_conductivity, :crawl_ceiling_density, :crawl_ceiling_spec_heat, :crawl_ceiling_Rvalue)
	end
	
	class CWallFicR
		def initialize
		end
		attr_accessor(:crawlspace_fictitious_Rvalue)
	end
	
	class CWallIns
		def initialize
		end
		attr_accessor(:crawlspace_wall_thickness, :crawlspace_wall_conductivity, :crawlspace_wall_density, :crawlspace_wall_spec_heat)
	end
	
	class CFloorFicR
		def initialize
		end
		attr_accessor(:crawlspace_floor_Rvalue)
	end
	
	class CSJoistandCavity
		def initialize
		end
		attr_accessor(:crawl_rimjoist_thickness, :crawl_rimjoist_conductivity, :crawl_rimjoist_density, :crawl_rimjoist_spec_heat)
	end
	  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add/Replace Residential Crawlspace Constructions"
  end
  
  def description
    return "This measure creates constructions for the crawlspace ceiling, walls, floor, and rim joists."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for the crawlspace ceiling, walls, floor, and rim joists. Finds surfaces adjacent to the crawlspace and sets applicable constructions."
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
    selected_living.setDisplayName("Living Space")
	selected_living.setDescription("The living space type.")
    args << selected_living

    #make a choice argument for crawlspace
    selected_crawlspace = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcrawlspace", spacetype_handles, spacetype_display_names, true)
    selected_crawlspace.setDisplayName("Crawlspace Space")
	selected_crawlspace.setDescription("The crawlspace space type.")
    args << selected_crawlspace

	#make a choice argument for model objects
	csins_display_names = OpenStudio::StringVector.new
	csins_display_names << "Uninsulated"
	csins_display_names << "Wall"
	csins_display_names << "Ceiling"
	
	#make a choice argument for cs insulation type
	selected_csins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsins", csins_display_names, true)
	selected_csins.setDisplayName("Crawlspace: Insulation Type")
	selected_csins.setDescription("The type of insulation.")
	selected_csins.setDefaultValue("Wall")
	args << selected_csins	

	#make a double argument for crawlspace ceiling / wall insulation R-value
	userdefined_cswallceilr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcswallceilr", false)
	userdefined_cswallceilr.setDisplayName("Crawlspace: Wall/Ceiling Continuous/Cavity Insulation Nominal R-value")
	userdefined_cswallceilr.setUnits("hr-ft^2-R/Btu")
	userdefined_cswallceilr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_cswallceilr.setDefaultValue(5.0)
	args << userdefined_cswallceilr
	
	# Ceiling Joist Height
	#make a choice argument for model objects
	joistheight_display_names = OpenStudio::StringVector.new
	joistheight_display_names << "2x10"	
	
	#make a choice argument for crawlspace ceiling joist height
	selected_csceiljoistheight = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcsceiljoistheight", joistheight_display_names, true)
	selected_csceiljoistheight.setDisplayName("Crawlspace: Ceiling Joist Height")
	selected_csceiljoistheight.setUnits("in")
	selected_csceiljoistheight.setDescription("Height of the joist member.")
	selected_csceiljoistheight.setDefaultValue("2x10")
	args << selected_csceiljoistheight	
	
	#make a choice argument for model objects
	installgrade_display_names = OpenStudio::StringVector.new
	installgrade_display_names << "I"
	installgrade_display_names << "II"
	installgrade_display_names << "III"
	
	#make a choice argument for wall cavity insulation installation grade
	selected_installgrade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedinstallgrade", installgrade_display_names, true)
	selected_installgrade.setDisplayName("Crawlspace: Ceiling Cavity Install Grade")
	selected_installgrade.setDescription("5% of the wall is considered missing insulation for Grade 3, 2% for Grade 2, and 0% for Grade 1.")
    selected_installgrade.setDefaultValue("I")
	args << selected_installgrade	
	
	# Ceiling Framing Factor
	#make a choice argument for crawlspace ceiling framing factor
	userdefined_csceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsceilff", false)
    userdefined_csceilff.setDisplayName("Crawlspace: Ceiling Framing Factor")
	userdefined_csceilff.setUnits("frac")
	userdefined_csceilff.setDescription("Fraction of ceiling that is framing.")
    userdefined_csceilff.setDefaultValue(0.13)
	args << userdefined_csceilff
	
	#make a double argument for rim joist insulation R-value
	userdefined_csrimjoistr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsrimjoistr", false)
	userdefined_csrimjoistr.setDisplayName("Crawlspace: Rim Joist Insulation R-value")
	userdefined_csrimjoistr.setUnits("hr-ft^2-R/Btu")
	userdefined_csrimjoistr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_csrimjoistr.setDefaultValue(5.0)
	args << userdefined_csrimjoistr
	
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

    # Geometry
    userdefinedcsarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsarea", false)
    userdefinedcsarea.setDisplayName("Crawlspace Area")
	userdefinedcsarea.setUnits("ft^2")
	userdefinedcsarea.setDescription("The area of the crawlspace.")
    userdefinedcsarea.setDefaultValue(1200.0)
    args << userdefinedcsarea	
	
    userdefinedcsheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsheight", false)
    userdefinedcsheight.setDisplayName("Crawlspace Height")
	userdefinedcsheight.setUnits("ft")
	userdefinedcsheight.setDescription("The height of the crawlspace.")
    userdefinedcsheight.setDefaultValue(4.0)
    args << userdefinedcsheight

    userdefinedcsextperim = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsextperim", false)
    userdefinedcsextperim.setDisplayName("Crawlspace Perimeter")
	userdefinedcsextperim.setUnits("ft")
	userdefinedcsextperim.setDescription("The perimeter of the crawlspace.")
    userdefinedcsextperim.setDefaultValue(140.0)
    args << userdefinedcsextperim
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	crawlWallContInsRvalueNominal = 0
	crawlCeilingCavityInsRvalueNominal = 0
	crawlRimJoistInsRvalue = 0
	carpetPadRValue = 0

    # Space Type
    selected_crawlspace = runner.getOptionalWorkspaceObjectChoiceValue("selectedcrawlspace",user_arguments,model)
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

	# Crawlspace Insulation
	selected_csins = runner.getStringArgumentValue("selectedcsins",user_arguments)
	selected_installgrade = runner.getStringArgumentValue("selectedinstallgrade",user_arguments)
	
	# Wall / Ceiling Insulation
	if ["Wall", "Ceiling"].include? selected_csins.to_s
		userdefined_cswallceilr = runner.getDoubleArgumentValue("userdefinedcswallceilr",user_arguments)
	end
	
	# Ceiling Joist Height
	selected_csceiljoistheight = runner.getStringArgumentValue("selectedcsceiljoistheight",user_arguments)
	
	# Ceiling Framing Factor
	userdefined_csceilff = runner.getDoubleArgumentValue("userdefinedcsceilff",user_arguments)
    if not ( userdefined_csceilff > 0.0 and userdefined_csceilff < 1.0 )
      runner.registerError("Invalid crawlspace ceiling framing factor")
      return false
    end

	# Rim Joist
	if ["Wall"].include? selected_csins.to_s
		selected_csrimjoist = runner.getOptionalWorkspaceObjectChoiceValue("selectedcsrimjoist",user_arguments,model)
		if selected_csrimjoist.empty?
			userdefined_csrimjoistr = runner.getDoubleArgumentValue("userdefinedcsrimjoistr",user_arguments)
		end
	end
	
	# Floor Mass
	userdefined_floormassth = runner.getDoubleArgumentValue("userdefinedfloormassth",user_arguments)
	userdefined_floormasscond = runner.getDoubleArgumentValue("userdefinedfloormasscond",user_arguments)
	userdefined_floormassdens = runner.getDoubleArgumentValue("userdefinedfloormassdens",user_arguments)
	userdefined_floormasssh = runner.getDoubleArgumentValue("userdefinedfloormasssh",user_arguments)
	
	# Carpet
	userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
	userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)
	
	# Constants
	mat_wood = get_mat_wood
	mat_soil = get_mat_soil
	mat_concrete = get_mat_concrete
	
	# Insulation
	if selected_csins.to_s == "Wall"
		crawlWallContInsRvalueNominal = userdefined_cswallceilr
	elsif selected_csins.to_s == "Ceiling"
		crawlCeilingCavityInsRvalueNominal = userdefined_cswallceilr
	end
	crawlCeilingInstallGrade_dict = {"I"=>1, "II"=>2, "III"=>3}
	crawlCeilingInstallGrade = crawlCeilingInstallGrade_dict[selected_installgrade]	
	
	# Ceiling Joist Height
	csCeilingJoistHeight_dict = {"2x10"=>9.25}
	crawlCeilingJoistHeight = csCeilingJoistHeight_dict[selected_csceiljoistheight]	
		
	# Ceiling Framing Factor
	crawlCeilingFramingFactor = userdefined_csceilff
	
	# Rim Joist
	if ["Wall"].include? selected_csins.to_s
		crawlRimJoistInsRvalue = userdefined_csrimjoistr
	end
	
	# Floor Mass
	floorMassThickness = userdefined_floormassth
	floorMassConductivity = userdefined_floormasscond
	floorMassDensity = userdefined_floormassdens
	floorMassSpecificHeat = userdefined_floormasssh
	
	# Carpet
	carpetPadRValue = userdefined_carpetr
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
	cs = Crawlspace.new(crawlWallContInsRvalueNominal, crawlCeilingCavityInsRvalueNominal, crawlCeilingJoistHeight, crawlCeilingFramingFactor, crawlCeilingInstallGrade)
	carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)
	floor_mass = FloorMass.new(floorMassThickness, floorMassConductivity, floorMassDensity, floorMassSpecificHeat)
	cci = CrawlCeilingIns.new
	cwfr = CWallFicR.new
	cwi = CWallIns.new
	cffr = CFloorFicR.new
	cjc = CSJoistandCavity.new
    wallsh = WallSheathing.new(wallSheathingContInsThickness, wallSheathingContInsRvalue)
    exterior_finish = ExteriorFinish.new(finishThickness, finishConductivity)

	if crawlWallContInsRvalueNominal > 0
		cs.CrawlRimJoistInsRvalue = crawlRimJoistInsRvalue
	end

	# Create the sim object
	sim = Sim.new(model, runner)

    cs.height = runner.getDoubleArgumentValue("userdefinedcsheight",user_arguments)
    cs.crawlspace_area = runner.getDoubleArgumentValue("userdefinedcsarea",user_arguments)
    cs.ext_perimeter = runner.getDoubleArgumentValue("userdefinedcsextperim",user_arguments)
	
	# Process the crawlspace
	cci, cwfr, cwi, cffr, cjc, wallsh = sim._processConstructionsCrawlspace(cs, carpet, floor_mass, wallsh, exterior_finish, cci, cwfr, cwi, cffr, cjc, selected_crawlspace)
	
	# CrawlCeilingIns
	cciThickness = cci.crawl_ceiling_thickness
	cciConductivity = cci.crawl_ceiling_conductivity
	cciDensity = cci.crawl_ceiling_density
	cciSpecificHeat = cci.crawl_ceiling_spec_heat
	cciRvalue = cci.crawl_ceiling_Rvalue
	if cciRvalue > 0
		cci = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		cci.setName("CrawlCeilingIns")
		cci.setRoughness("Rough")
		cci.setThickness(OpenStudio::convert(cciThickness,"ft","m").get)
		cci.setConductivity(OpenStudio::convert(cciConductivity,"Btu/hr*ft*R","W/m*K").get)
		cci.setDensity(OpenStudio::convert(cciDensity,"lb/ft^3","kg/m^3").get)
		cci.setSpecificHeat(OpenStudio::convert(cciSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
	# Plywood-3_4in
	ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_4.setName("Plywood-3_4in")
	ply3_4.setRoughness("Rough")
	ply3_4.setThickness(OpenStudio::convert(get_mat_plywood3_4in(mat_wood).thick,"in","m").get)
	ply3_4.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_4.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
	ply3_4.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)
	
	# Plywood-3_2in
	ply3_2 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ply3_2.setName("Plywood-3_2in")
	ply3_2.setRoughness("Rough")
	ply3_2.setThickness(OpenStudio::convert(get_mat_plywood3_2in(mat_wood).thick,"ft","m").get)
	ply3_2.setConductivity(OpenStudio::convert(mat_wood.k,"Btu/hr*ft*R","W/m*K").get)
	ply3_2.setDensity(OpenStudio::convert(mat_wood.rho,"lb/ft^3","kg/m^3").get)
	ply3_2.setSpecificHeat(OpenStudio::convert(mat_wood.Cp,"Btu/lb*R","J/kg*K").get)	
	
	# FloorMass
	fm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	fm.setName("FloorMass")
	fm.setRoughness("Rough")
	fm.setThickness(OpenStudio::convert(get_mat_floor_mass(floor_mass).thick,"ft","m").get)
	fm.setConductivity(OpenStudio::convert(get_mat_floor_mass(floor_mass).k,"Btu/hr*ft*R","W/m*K").get)
	fm.setDensity(OpenStudio::convert(get_mat_floor_mass(floor_mass).rho,"lb/ft^3","kg/m^3").get)
	fm.setSpecificHeat(OpenStudio::convert(get_mat_floor_mass(floor_mass).Cp,"Btu/lb*R","J/kg*K").get)
	fm.setThermalAbsorptance(get_mat_floor_mass(floor_mass).TAbs)
	fm.setSolarAbsorptance(get_mat_floor_mass(floor_mass).SAbs)
		
	# CWall-FicR
	cwfrRvalue = cwfr.crawlspace_fictitious_Rvalue
	if cwfrRvalue > 0
		cwfr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
		cwfr.setName("CWall-FicR")
		cwfr.setRoughness("Rough")
		cwfr.setThermalResistance(OpenStudio::convert(cwfrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
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
	
	# CWallIns
	cwiThickness = cwi.crawlspace_wall_thickness
	cwiConductivity = cwi.crawlspace_wall_conductivity
	cwiDensity = cwi.crawlspace_wall_density
	cwiSpecificHeat = cwi.crawlspace_wall_spec_heat
	if cs.CrawlWallContInsRvalueNominal > 0
		cwi = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		cwi.setName("CWallIns")
		cwi.setRoughness("Rough")
		cwi.setThickness(OpenStudio::convert(cwiThickness,"ft","m").get)
		cwi.setConductivity(OpenStudio::convert(cwiConductivity,"Btu/hr*ft*R","W/m*K").get)
		cwi.setDensity(OpenStudio::convert(cwiDensity,"lb/ft^3","kg/m^3").get)
		cwi.setSpecificHeat(OpenStudio::convert(cwiSpecificHeat,"Btu/lb*R","J/kg*K").get)
	end
	
	# CFloor-FicR
	cffrRvalue = cffr.crawlspace_floor_Rvalue
	cffr = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
	cffr.setName("CFloor-FicR")
	cffr.setRoughness("Rough")
	cffr.setThermalResistance(OpenStudio::convert(cffrRvalue,"hr*ft^2*R/Btu","m^2*K/W").get)
	
	# CSJoistandCavity
	cjcThickness = cjc.crawl_rimjoist_thickness
	cjcConductivity = cjc.crawl_rimjoist_conductivity
	cjcDensity = cjc.crawl_rimjoist_density
	cjcSpecificHeat = cjc.crawl_rimjoist_spec_heat
	cjc = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	cjc.setName("CSJoistandCavity")
	cjc.setRoughness("Rough")
	cjc.setThickness(OpenStudio::convert(cjcThickness,"ft","m").get)
	cjc.setConductivity(OpenStudio::convert(cjcConductivity,"Btu/hr*ft*R","W/m*K").get)
	cjc.setDensity(OpenStudio::convert(cjcDensity,"lb/ft^3","kg/m^3").get)
	cjc.setSpecificHeat(OpenStudio::convert(cjcSpecificHeat,"Btu/lb*R","J/kg*K").get)

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
	
	# CarpetBareLayer
	if carpet.CarpetFloorFraction > 0
		cbl = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		cbl.setName("CarpetBareLayer")
		cbl.setRoughness("Rough")
		cbl.setThickness(OpenStudio::convert(get_mat_carpet_bare(carpet).thick,"ft","m").get)
		cbl.setConductivity(OpenStudio::convert(get_mat_carpet_bare(carpet).k,"Btu/hr*ft*R","W/m*K").get)
		cbl.setDensity(OpenStudio::convert(get_mat_carpet_bare(carpet).rho,"lb/ft^3","kg/m^3").get)
		cbl.setSpecificHeat(OpenStudio::convert(get_mat_carpet_bare(carpet).Cp,"Btu/lb*R","J/kg*K").get)
		cbl.setThermalAbsorptance(get_mat_carpet_bare(carpet).TAbs)
		cbl.setSolarAbsorptance(get_mat_carpet_bare(carpet).SAbs)
	end
	
	# UnfinCSInsFinFloor
	layercount = 0
	unfincsinsfinfloor = OpenStudio::Model::Construction.new(model)
	unfincsinsfinfloor.setName("UnfinCSInsFinFloor")
    if cciRvalue > 0
		unfincsinsfinfloor.insertLayer(layercount,cci)
		layercount += 1
	end	
	unfincsinsfinfloor.insertLayer(layercount,ply3_4)
	layercount += 1	
	unfincsinsfinfloor.insertLayer(layercount,fm)
	layercount += 1
	if carpet.CarpetFloorFraction > 0
		unfincsinsfinfloor.insertLayer(layercount,cbl)
	end	

	# RevUnfinCSInsFinFloor
	layercount = 0
	revunfincsinsfinfloor = OpenStudio::Model::Construction.new(model)
	revunfincsinsfinfloor.setName("RevUnfinCSInsFinFloor")
  unfincsinsfinfloor.layers.reverse_each do |layer|
    revunfincsinsfinfloor.insertLayer(layercount,layer)
    layercount += 1
  end

	# GrndInsUnfinCSWall
	layercount = 0
	grndinsunfincswall = OpenStudio::Model::Construction.new(model)
	grndinsunfincswall.setName("GrndInsUnfinCSWall")
	if cwfrRvalue > 0
		grndinsunfincswall.insertLayer(layercount,cwfr)
		layercount += 1
	end
	grndinsunfincswall.insertLayer(layercount,soil)
	layercount += 1
	grndinsunfincswall.insertLayer(layercount,conc8)
	layercount += 1
	if cs.CrawlWallContInsRvalueNominal > 0
		grndinsunfincswall.insertLayer(layercount,cwi)
	end
	
	# GrndUninsUnfinCSFloor
	grnduninsunfincsfloor = OpenStudio::Model::Construction.new(model)
	grnduninsunfincsfloor.setName("GrndUninsUnfinCSFloor")
	grnduninsunfincsfloor.insertLayer(0,cffr)
	grnduninsunfincsfloor.insertLayer(1,soil)	
	
	# CSRimJoist
	layercount = 0
	csrimjoist = OpenStudio::Model::Construction.new(model)
	csrimjoist.setName("CSRimJoist")
	csrimjoist.insertLayer(layercount,extfin)
	layercount += 1
	if wallsh.WallSheathingContInsRvalue > 0
		csrimjoist.insertLayer(layercount,rigid)
		layercount += 1
	end
	csrimjoist.insertLayer(layercount,ply3_2)
	layercount += 1
	csrimjoist.insertLayer(layercount,cjc)

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_crawlspace.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grndinsunfincswall)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndInsUnfinCSWall"]
          elsif surface.surfaceType == "RoofCeiling" and surface.outsideBoundaryCondition == "Surface"
            surface.resetConstruction
            surface.setConstruction(revunfincsinsfinfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"RevUnfinCSInsFinFloor"]
          elsif surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(grnduninsunfincsfloor)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"GrndUninsUnfinCSFloor"]
          elsif surface.surfaceType == "Wall" and surface.outsideBoundaryCondition == "Outdoors"
            surface.resetConstruction
            surface.setConstruction(csrimjoist)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"CSRimJoist"]
          end
        end
      elsif selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Surface"
            adjacentSpaces = model.getSpaces
            adjacentSpaces.each do |adjacentSpace|
              if selected_crawlspace.get.handle.to_s == adjacentSpace.spaceType.get.handle.to_s
                adjacentSurfaces = adjacentSpace.surfaces
                adjacentSurfaces.each do |adjacentSurface|
                  if surface.adjacentSurface.get.handle.to_s == adjacentSurface.handle.to_s
                    surface.resetConstruction
                    surface.setConstruction(unfincsinsfinfloor)
                    constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"UnfinCSInsFinFloor"]
                  end
                end
              end
            end
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
ProcessConstructionsCrawlspace.new.registerWithApplication