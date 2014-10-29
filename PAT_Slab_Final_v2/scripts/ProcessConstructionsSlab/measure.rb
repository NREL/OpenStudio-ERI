#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessConstructionsSlab < OpenStudio::Ruleset::ModelUserScript
  
	class Slab
		def initialize(slabThickness, slabConductivity, slabDensity, slabSpecificHeat, slabPerimeterRvalue, slabPerimeterInsWidth, slabExtRvalue, slabExtInsDepth, slabGapRvalue, slabWholeInsRvalue)
			@slabThickness = slabThickness
			@slabConductivity = slabConductivity
			@slabDensity = slabDensity
			@slabSpecificHeat = slabSpecificHeat
			@slabPerimeterRvalue = slabPerimeterRvalue
			@slabPerimeterInsWidth = slabPerimeterInsWidth
			@slabExtRvalue = slabExtRvalue
			@slabExtInsDepth = slabExtInsDepth
			@slabGapRvalue = slabGapRvalue
			@slabWholeInsRvalue = slabWholeInsRvalue
		end
		
		attr_accessor(:SlabHasWholeInsulation, :SlabCarpetPerimeterConduction, :SlabBarePerimeterConduction, :ext_perimeter, :area, :slab_carp_ext_perimeter, :bare_ext_perimeter, :area_perimeter_ratio, :fictitious_carpet_Rvalue, :carp_slab_factor, :fictitious_bare_Rvalue, :bare_slab_factor, :fictitious_slab_Rvalue, :slab_factor)
		
		def SlabMassThickness
			return @slabThickness
		end
		
		def SlabMassConductivity
			return @slabConductivity
		end
		
		def SlabMassDensity
			return @slabDensity
		end

		def SlabMassSpecificHeat
			return @slabSpecificHeat
		end

		def SlabPerimeterRvalue
			return @slabPerimeterRvalue
		end

		def SlabPerimeterInsWidth
			return @slabPerimeterInsWidth
		end		
		
		def SlabExtRvalue
			return @slabExtRvalue
		end

		def SlabExtInsDepth
			return @slabExtInsDepth
		end
		
		def SlabGapRvalue
			return @slabGapRvalue
		end
		
		def SlabWholeInsRvalue
			return @slabWholeInsRvalue
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
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessConstructionsSlab"
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
	
	#make a choice argument for model objects
	slabins_display_names = OpenStudio::StringVector.new
	slabins_display_names << "Uninsulated"
	slabins_display_names << "Perimeter"
	slabins_display_names << "Exterior"
	slabins_display_names << "Whole Slab"
	
	#make a choice argument for slab insulation type
	selected_slabins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedslabins", slabins_display_names, true)
	selected_slabins.setDisplayName("Slab insulation type.")
	args << selected_slabins
		
	# Perimeter / Exterior Insulation
	#make a choice argument for perimeter / exterior / insulation
	selected_slabperiext = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedslabperiext", material_handles, material_display_names, false)
	selected_slabperiext.setDisplayName("Slab perimeter or exterior insulation. For manually entering slab perimeter or exterior insulation properties, leave blank.")
	args << selected_slabperiext	

	#make a double argument for slab perimeter / exterior insulation R-value
	userdefined_slabperiextr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextr", false)
	userdefined_slabperiextr.setDisplayName("Slab perimeter insulation R-value or exterior insulation R-value [hr-ft^2-R/Btu].")
	args << userdefined_slabperiextr
	
	#make a double argument for slab perimeter insulation width / exterior insulation depth
	userdefined_slabperiextwidthdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextwidthdepth", false)
	userdefined_slabperiextwidthdepth.setDisplayName("Slab perimeter insulation width or exterior insulation depth [ft].")
	args << userdefined_slabperiextwidthdepth
	
	# Gap
	#make a choice argument for slab perimeter gap
	selected_slabgap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedslabgap", material_handles, material_display_names, false)
	selected_slabgap.setDisplayName("Perimeter or whole slab gap. For manually entering slab gap properties, leave blank.")
	args << selected_slabgap	
	
	#make a double argument for slab perimeter gap R-value
	userdefined_slabgapr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabgapr", false)
	userdefined_slabgapr.setDisplayName("Perimeter gap R-value or whole slab gap R-value [hr-ft^2-R/Btu].")
	args << userdefined_slabgapr

	# Whole Slab Insulation
	#make a double argument for whole slab insulation R-value
	userdefined_slabwholer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabwholer", false)
	userdefined_slabwholer.setDisplayName("Whole slab insulation R-value [hr-ft^2-R/Btu].")
	args << userdefined_slabwholer
	
	# Carpet
	#make a choice argument for carpet pad R-value
	selected_carpet = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcarpet", material_handles, material_display_names, false)
	selected_carpet.setDisplayName("Carpet. For manually entering carpet properties, leave blank.")
	args << selected_carpet
	
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

	slabPerimeterRvalue = 0
	slabPerimeterInsWidth = nil
	slabExtRvalue = 0
	slabExistInsDepth = nil
	slabGapRvalue = nil
	slabWholeInsRvalue = 0
	carpetPadRValue = 0

    # Space Type
    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)

	# Slab Insulation
	selected_slabins = runner.getStringArgumentValue("selectedslabins",user_arguments)
	
	# Perimeter / Exterior Insulation
	if ["Perimeter", "Exterior"].include? selected_slabins.to_s
		selected_slabperiext = runner.getOptionalWorkspaceObjectChoiceValue("selectedslabperiext",user_arguments,model)
		if selected_slabperiext.empty?
			userdefined_slabperiextr = runner.getDoubleArgumentValue("userdefinedslabperiextr",user_arguments)
			userdefined_slabperiextwidthdepth = runner.getDoubleArgumentValue("userdefinedslabperiextwidthdepth",user_arguments)
		end
	end
		
	# Gap
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		selected_slabgap = runner.getOptionalWorkspaceObjectChoiceValue("selectedslabgap",user_arguments,model)
		if selected_slabgap.empty?
			userdefined_slabgapr = runner.getDoubleArgumentValue("userdefinedslabgapr",user_arguments)
		end
	end
	
	# Whole Slab Insulation
	if selected_slabins.to_s == "Whole Slab"
		userdefined_slabwholer = runner.getDoubleArgumentValue("userdefinedslabwholer",user_arguments)
	end
	
	# Carpet
	selected_carpet = runner.getOptionalWorkspaceObjectChoiceValue("selectedcarpet",user_arguments,model)
	if selected_carpet.empty?
		userdefined_carpetr = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
	end
	userdefined_carpetfrac = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

  # Constants
  constants = Constants.new
	
	# Insulation
	if selected_slabins == "Perimeter"
		if userdefined_slabperiextr.nil?
			slabPerimeterThickness = OpenStudio::convert(selected_slabperiext.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			slabPerimeterConductivity = OpenStudio::convert(selected_slabperiext.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			slabPerimeterRvalue = OpenStudio::convert(slabPerimeterThickness,"in","ft").get / slabPerimeterConductivity
			slabPerimeterInsWidth = OpenStudio::convert(slabPerimeterThickness,"in","ft").get
		else
			slabPerimeterRvalue = userdefined_slabperiextr
			slabPerimeterInsWidth = userdefined_slabperiextwidthdepth
		end
	elsif selected_slabins == "Exterior"
		if userdefined_slabperiextr.nil?
			slabExtThickness = OpenStudio::convert(selected_slabperiext.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			slabExtConductivity = OpenStudio::convert(selected_slabperiext.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			slabExtRvalue = OpenStudio::convert(slabExtThickness,"in","ft").get / slabExtConductivity
			slabExtInsDepth = OpenStudio::convert(slabExtThickness,"in","ft").get
		else
			slabExtRvalue = userdefined_slabperiextr
			slabExtInsDepth = userdefined_slabperiextwidthdepth
		end	
	elsif selected_slabins == "Whole Slab"
		slabWholeInsRvalue = userdefined_slabwholer	
	end

	# Gap
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		if userdefined_slabgapr.nil?
			slabGapThickness = OpenStudio::convert(selected_slabgap.get.to_StandardOpaqueMaterial.get.getThickness.value,"m","in").get
			slabGapConductivity = OpenStudio::convert(selected_slabgap.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
			slabGapRvalue = OpenStudio::convert(slabGapThickness,"in","ft").get / slabGapConductivity
		else
			slabGapRvalue = userdefined_slabgapr
		end		
	end
	
	# Carpet
	if userdefined_carpetr.nil?
		carpetPadThickness = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getThickness.value,"in","ft").get
		carpetPadConductivity = OpenStudio::convert(selected_carpet.get.to_StandardOpaqueMaterial.get.getConductivity.value,"W/m*K","Btu/hr*ft*R").get
		carpetPadRValue = OpenStudio::convert(carpetPadThickness,"in","ft").get / carpetPadConductivity
	else
		carpetPadRValue = userdefined_carpetr
	end
	carpetFloorFraction = userdefined_carpetfrac

	# Create the material class instances
	slabThickness = 4.0
	slabConductivity = 9.1
	slabDensity = 140.0
	slabSpecificHeat = 0.2
	slab = Slab.new(slabThickness, slabConductivity, slabDensity, slabSpecificHeat, slabPerimeterRvalue, slabPerimeterInsWidth, slabExtRvalue, slabExtInsDepth, slabGapRvalue, slabWholeInsRvalue)
	carpet = Carpet.new(carpetFloorFraction, carpetPadRValue)

	# Create the sim object
	sim = Sim.new(model)
	
	# Process the slab
	slab = sim._processConstructionsSlab(slab, carpet)
	
	# Mat-Fic-Slab
	if slab.fictitious_slab_Rvalue > 0
		# Fictitious layer below slab to achieve equivalent R-value. See Winkelmann article.
		mfs = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		mfs.setName("Mat-Fic-Slab")
		mfs.setRoughness("Rough")
		mfs.setThickness(OpenStudio::convert(1.0/12.0,"ft","m").get)
		mfs.setConductivity(OpenStudio::convert(1.0/12.0,"ft","m").get / (0.1761 * slab.fictitious_slab_Rvalue)) # tk used 0.1761 instead of OpenStudio::convert(slab.fictitious_slab_Rvalue,"Btu/hr*ft*R","W/m*K").get because not getting correct value
		mfs.setDensity(OpenStudio::convert(2.5,"lb/ft^3","kg/m^3").get)
		mfs.setSpecificHeat(OpenStudio::convert(0.29,"Btu/lb*R","J/kg*K").get)
	end
	
	# Slab Mass Material
	sm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	sm.setName("SlabMass")
	sm.setRoughness("Rough")
	sm.setThickness(OpenStudio::convert(slab.SlabMassThickness,"in","m").get)
	sm.setConductivity(OpenStudio::convert(OpenStudio::convert(slab.SlabMassConductivity,"in","ft").get,"Btu/hr*ft*R","W/m*K").get)
	sm.setDensity(OpenStudio::convert(slab.SlabMassDensity,"lb/ft^3","kg/m^3").get)
	sm.setSpecificHeat(OpenStudio::convert(slab.SlabMassSpecificHeat,"Btu/lb*R","J/kg*K").get)
	sm.setThermalAbsorptance(0.9)
	sm.setSolarAbsorptance(constants.DefaultSolarAbsFloor)
	
	if carpet.CarpetFloorFraction > 0
		# Equivalent carpeted/bare material
		scbem = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		scbem.setName("SlabCarpetBareEquivalentMaterial")
		scbem.setRoughness("Rough")
		scbem.setThickness(OpenStudio::convert(1.0/12.0,"ft","m").get)
		scbem.setConductivity(OpenStudio::convert(1.0/12.0,"ft","m").get / (carpet.CarpetPadRValue * carpet.CarpetFloorFraction * slab.slab_factor * 0.1761)) # tk the 0.1761 in place of OpenStudio::convert(1.0,"hr*ft^2*F/Btu","m^2*K/W").get because wasn't returning correct value
		scbem.setDensity(OpenStudio::convert(2.5,"lb/ft^3","kg/m^3").get)
		scbem.setSpecificHeat(OpenStudio::convert(0.29,"Btu/lb*R","J/kg*K").get)
		scbem.setThermalAbsorptance(0.9)
		scbem.setSolarAbsorptance(constants.DefaultSolarAbsFloor)
	end
		
	# Soil layer for simulated slab, copied from Winkelmann article
	ss = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ss.setName("SlabSoil-12in")
	ss.setRoughness("Rough")
	ss.setThickness(OpenStudio::convert(slab.slab_factor,"ft","m").get)
	ss.setConductivity(OpenStudio::convert(1.0,"Btu/hr*ft*R","W/m*K").get)
	ss.setDensity(OpenStudio::convert(115.0,"lb/ft^3","kg/m^3").get)
	ss.setSpecificHeat(OpenStudio::convert(0.1,"Btu/lb*R","J/kg*K").get)
	
	# Living Area Slab with Equivalent Carpeted/Bare R-value
	layercount = 0
	s = OpenStudio::Model::Construction.new(model)
  s.setName("Slab")
	if slab.fictitious_slab_Rvalue > 0
    s.insertLayer(layercount,mfs)
		layercount += 1
	end
  s.insertLayer(layercount,ss)
	layercount += 1
  s.insertLayer(layercount,sm)
	layercount += 1
	if carpet.CarpetFloorFraction > 0
    s.insertLayer(layercount,scbem)
	end

    # loop thru all the spaces
    spaces = model.getSpaces
    spaces.each do |space|
      constructions_hash = {}
      if selected_living.get.handle.to_s == space.spaceType.get.handle.to_s
        # loop thru all surfaces attached to the space
        surfaces = space.surfaces
        surfaces.each do |surface|
          if surface.surfaceType == "Floor" and surface.outsideBoundaryCondition == "Ground"
            surface.resetConstruction
            surface.setConstruction(s)
            constructions_hash[surface.name.to_s] = [surface.surfaceType,surface.outsideBoundaryCondition,"Slab"]
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
ProcessConstructionsSlab.new.registerWithApplication