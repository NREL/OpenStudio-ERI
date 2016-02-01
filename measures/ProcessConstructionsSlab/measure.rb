#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessConstructionsSlab < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Slab Construction"
  end
  
  def description
    return "This measure assigns a construction to the living space slab."
  end
  
  def modeler_description
    return "Calculates material layer properties of slab constructions for the living space floor. Finds surfaces adjacent to the living space and sets applicable constructions."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a choice argument for model objects
	slabins_display_names = OpenStudio::StringVector.new
	slabins_display_names << "Uninsulated"
	slabins_display_names << "Perimeter"
	slabins_display_names << "Exterior"
	slabins_display_names << "Whole Slab"
	
	#make a choice argument for slab insulation type
	selected_slabins = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedslabins", slabins_display_names, true)
	selected_slabins.setDisplayName("Slab: Insulation Type")
	selected_slabins.setDescription("The type of insulation.")
	selected_slabins.setDefaultValue("Uninsulated")
	args << selected_slabins

	#make a double argument for slab perimeter / exterior insulation R-value
	userdefined_slabperiextr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextr", false)
	userdefined_slabperiextr.setDisplayName("Slab: Perimeter/Exterior Insulation Nominal R-value")
	userdefined_slabperiextr.setUnits("hr-ft^2-R/Btu")
	userdefined_slabperiextr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabperiextr.setDefaultValue(0.0)
	args << userdefined_slabperiextr
	
	#make a double argument for slab perimeter insulation width / exterior insulation depth
	userdefined_slabperiextwidthdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextwidthdepth", false)
	userdefined_slabperiextwidthdepth.setDisplayName("Slab: Perimeter/Exterior Insulation Width/Depth")
	userdefined_slabperiextwidthdepth.setUnits("ft")
	userdefined_slabperiextwidthdepth.setDescription("The width or depth of the perimeter or exterior insulation.")
	userdefined_slabperiextwidthdepth.setDefaultValue(0.0)
	args << userdefined_slabperiextwidthdepth
	
	#make a double argument for slab perimeter gap R-value
	userdefined_slabgapr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabgapr", false)
	userdefined_slabgapr.setDisplayName("Slab: Gap Insulation Nominal R-value")
	userdefined_slabgapr.setUnits("hr-ft^2-R/Btu")
	userdefined_slabgapr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabgapr.setDefaultValue(0.0)
	args << userdefined_slabgapr

	# Whole Slab Insulation
	#make a double argument for whole slab insulation R-value
	userdefined_slabwholer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabwholer", false)
	userdefined_slabwholer.setDisplayName("Slab: Whole Slab Insulation Nominal R-value")
	userdefined_slabwholer.setUnits("hr-ft^2-R/Btu")
	userdefined_slabwholer.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabwholer.setDefaultValue(0.0)
	args << userdefined_slabwholer
	
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
    userdefinedslabarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabarea", true)
    userdefinedslabarea.setDisplayName("Slab Area")
	userdefinedslabarea.setUnits("ft^2")
	userdefinedslabarea.setDescription("The area of the slab.")
    userdefinedslabarea.setDefaultValue(1200.0)
    args << userdefinedslabarea

    userdefinedslabextperim = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabextperim", true)
    userdefinedslabextperim.setDisplayName("Slab Perimeter")
	userdefinedslabextperim.setUnits("ft")
	userdefinedslabextperim.setDescription("The perimeter of the slab.")
    userdefinedslabextperim.setDefaultValue(140.0)
    args << userdefinedslabextperim
	
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

	slabPerimeterRvalue = 0
	slabPerimeterInsWidth = nil
	slabExtRvalue = 0
	slabExistInsDepth = nil
	slabGapRvalue = nil
	slabWholeInsRvalue = 0
	carpetPadRValue = 0

    # Space Type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end

    # Initialize hashes
    constructions_to_surfaces = {"Slab"=>[]}
    constructions_to_objects = Hash.new    

	living_space_type.spaces.each do |living_space|
	  living_space.surfaces.each do |living_surface|
	    next unless living_surface.surfaceType.downcase == "floor" and living_surface.outsideBoundaryCondition.downcase == "ground"
        constructions_to_surfaces["Slab"] << living_surface
	  end	
	end
  
   # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
      return true
    end     
  
	# Slab Insulation
	selected_slabins = runner.getStringArgumentValue("selectedslabins",user_arguments)
	
	# Perimeter / Exterior Insulation
	if ["Perimeter", "Exterior"].include? selected_slabins.to_s
		userdefined_slabperiextr = runner.getDoubleArgumentValue("userdefinedslabperiextr",user_arguments)
		userdefined_slabperiextwidthdepth = runner.getDoubleArgumentValue("userdefinedslabperiextwidthdepth",user_arguments)
	end
		
	# Gap
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		userdefined_slabgapr = runner.getDoubleArgumentValue("userdefinedslabgapr",user_arguments)
	end
	
	# Whole Slab Insulation
	if selected_slabins.to_s == "Whole Slab"
		userdefined_slabwholer = runner.getDoubleArgumentValue("userdefinedslabwholer",user_arguments)
	end
	
	# Carpet
	carpetPadRValue = runner.getDoubleArgumentValue("userdefinedcarpetr",user_arguments)
	carpetFloorFraction = runner.getDoubleArgumentValue("userdefinedcarpetfrac",user_arguments)

	# Insulation
	if selected_slabins == "Perimeter"
		slabPerimeterRvalue = userdefined_slabperiextr
		slabPerimeterInsWidth = userdefined_slabperiextwidthdepth
	elsif selected_slabins == "Exterior"
		slabExtRvalue = userdefined_slabperiextr
		slabExtInsDepth = userdefined_slabperiextwidthdepth
	elsif selected_slabins == "Whole Slab"
		slabWholeInsRvalue = userdefined_slabwholer	
	end

	# Gap
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		slabGapRvalue = userdefined_slabgapr
	end
	
	# Create the material class instances
	slabThickness = 4.0
	slabConductivity = 9.1
	slabDensity = 140.0
	slabSpecificHeat = 0.2

    slabArea = runner.getDoubleArgumentValue("userdefinedslabarea",user_arguments)
    slabExtPerimeter = runner.getDoubleArgumentValue("userdefinedslabextperim",user_arguments)
	
	# Process the slab
	fictitious_slab_Rvalue, slab_factor = _processConstructionsSlab(slabThickness, slabConductivity, slabDensity, slabSpecificHeat, slabPerimeterRvalue, slabPerimeterInsWidth, slabExtRvalue, slabExtInsDepth, slabGapRvalue, slabWholeInsRvalue, slabArea, slabExtPerimeter, carpetFloorFraction, carpetPadRValue)
	
	# Mat-Fic-Slab
	if fictitious_slab_Rvalue > 0
		# Fictitious layer below slab to achieve equivalent R-value. See Winkelmann article.
		mfs = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		mfs.setName("Mat-Fic-Slab")
		mfs.setRoughness("Rough")
		mfs.setThickness(OpenStudio::convert(1.0/12.0,"ft","m").get)
		mfs.setConductivity(OpenStudio::convert(1.0/12.0,"ft","m").get / (0.1761 * fictitious_slab_Rvalue)) # tk used 0.1761 instead of OpenStudio::convert(fictitious_slab_Rvalue,"Btu/hr*ft*R","W/m*K").get because not getting correct value
		mfs.setDensity(OpenStudio::convert(2.5,"lb/ft^3","kg/m^3").get)
		mfs.setSpecificHeat(OpenStudio::convert(0.29,"Btu/lb*R","J/kg*K").get)
	end
	
	# Slab Mass Material
	sm = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	sm.setName("SlabMass")
	sm.setRoughness("Rough")
	sm.setThickness(OpenStudio::convert(slabThickness,"in","m").get)
	sm.setConductivity(OpenStudio::convert(OpenStudio::convert(slabConductivity,"in","ft").get,"Btu/hr*ft*R","W/m*K").get)
	sm.setDensity(OpenStudio::convert(slabDensity,"lb/ft^3","kg/m^3").get)
	sm.setSpecificHeat(OpenStudio::convert(slabSpecificHeat,"Btu/lb*R","J/kg*K").get)
	sm.setThermalAbsorptance(0.9)
	sm.setSolarAbsorptance(Constants.DefaultSolarAbsFloor)
	
	if carpetFloorFraction > 0
		# Equivalent carpeted/bare material
		scbem = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		scbem.setName("SlabCarpetBareEquivalentMaterial")
		scbem.setRoughness("Rough")
		scbem.setThickness(OpenStudio::convert(1.0/12.0,"ft","m").get)
		scbem.setConductivity(OpenStudio::convert(1.0/12.0,"ft","m").get / (carpetPadRValue * carpetFloorFraction * slab_factor * 0.1761)) # tk the 0.1761 in place of OpenStudio::convert(1.0,"hr*ft^2*F/Btu","m^2*K/W").get because wasn't returning correct value
		scbem.setDensity(OpenStudio::convert(2.5,"lb/ft^3","kg/m^3").get)
		scbem.setSpecificHeat(OpenStudio::convert(0.29,"Btu/lb*R","J/kg*K").get)
		scbem.setThermalAbsorptance(0.9)
		scbem.setSolarAbsorptance(Constants.DefaultSolarAbsFloor)
	end
		
	# Soil layer for simulated slab, copied from Winkelmann article
	ss = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	ss.setName("SlabSoil-12in")
	ss.setRoughness("Rough")
	ss.setThickness(OpenStudio::convert(slab_factor,"ft","m").get)
	ss.setConductivity(OpenStudio::convert(1.0,"Btu/hr*ft*R","W/m*K").get)
	ss.setDensity(OpenStudio::convert(115.0,"lb/ft^3","kg/m^3").get)
	ss.setSpecificHeat(OpenStudio::convert(0.1,"Btu/lb*R","J/kg*K").get)
	
	# Living Area Slab with Equivalent Carpeted/Bare R-value
	materials = []

	if fictitious_slab_Rvalue > 0
		materials << mfs
	end
    materials << ss
    materials << sm
	if carpetFloorFraction > 0
		materials << scbem
	end
    unless constructions_to_surfaces["Slab"].empty?
        s = OpenStudio::Model::Construction.new(materials)
        s.setName("Slab")
        constructions_to_objects["Slab"] = s
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

  def _processConstructionsSlab(slabThickness, slabConductivity, slabDensity, slabSpecificHeat, slabPerimeterRvalue, slabPerimeterInsWidth, slabExtRvalue, slabExtInsDepth, slabGapRvalue, slabWholeInsRvalue, slabArea, slabExtPerimeter, carpetFloorFraction, carpetPadRValue)

        slab_concrete_Rvalue = OpenStudio::convert(slabThickness,"in","ft").get / slabConductivity
        
        slabCarpetPerimeterConduction, slabBarePerimeterConduction, slabHasWholeInsulation = SlabPerimeterConductancesByType(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabExtRvalue, slabWholeInsRvalue, slabExtInsDepth)

        slab_carp_ext_perimeter = slabExtPerimeter * carpetFloorFraction
        bare_ext_perimeter = slabExtPerimeter * (1 - carpetFloorFraction)
        
        # Calculate R-Values from conductances and geometry
        slab_warning = false
        
        # Models one floor surface with an equivalent carpented/bare material (Better alternative
        # to having two floors with twice the total area, compensated by thinning mass thickness.)
        slab_perimeter_conduction = slabCarpetPerimeterConduction * carpetFloorFraction + slabBarePerimeterConduction * (1 - carpetFloorFraction)

        if slabExtPerimeter > 0
            effective_slab_Rvalue = slabArea / (slabExtPerimeter * slab_perimeter_conduction)
        else
            effective_slab_Rvalue = 1000 # hr*ft^2*F/Btu
        end

        fictitious_slab_Rvalue = effective_slab_Rvalue - slab_concrete_Rvalue - AirFilms.FlatReducedR - Material.Soil12in.Rvalue - (carpetPadRValue * carpetFloorFraction)

        if fictitious_slab_Rvalue <= 0
            slab_warning = true
            slab_factor = effective_slab_Rvalue / (slab_concrete_Rvalue + AirFilms.FlatReducedR + Material.Soil12in.Rvalue + carpetPadRValue * carpetFloorFraction)
        else
            slab_factor = 1.0
        end

        if slab_warning
            runner.registerWarning("The slab foundation thickness will be automatically reduced to avoid simulation errors, but overall R-value will remain the same.")
        end
        
        return fictitious_slab_Rvalue, slab_factor
        
  end

  def SlabPerimeterConductancesByType(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabExtRvalue, slabWholeInsRvalue, slabExtInsDepth)
    slabWidth = 28 # Width (shorter dimension) of slab, feet, to match Winkelmann analysis.
    slabLength = 55 # Longer dimension of slab, feet, to match Winkelmann analysis.
    soilConductivity = 1
    slabHasWholeInsulation = false
    if slabPerimeterRvalue > 0
        slabCarpetPerimeterConduction = PerimeterSlabInsulation(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabWidth, slabLength, 1, soilConductivity)
        slabBarePerimeterConduction = PerimeterSlabInsulation(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabWidth, slabLength, 0, soilConductivity)
    elsif slabExtRvalue > 0
        slabCarpetPerimeterConduction = ExteriorSlabInsulation(slabExtInsDepth, slabExtRvalue, 1)
        slabBarePerimeterConduction = ExteriorSlabInsulation(slabExtInsDepth, slabExtRvalue, 0)
    elsif slabWholeInsRvalue > 0
        slabHasWholeInsulation = true
        if slabWholeInsRvalue >= 999
            # Super insulated slab option
            slabCarpetPerimeterConduction = 0.001
            slabBarePerimeterConduction = 0.001
        else
            slabCarpetPerimeterConduction = FullSlabInsulation(slabWholeInsRvalue, slabGapRvalue, slabWidth, slabLength, 1, soilConductivity)
            slabBarePerimeterConduction = FullSlabInsulation(slabWholeInsRvalue, slabGapRvalue, slabWidth, slabLength, 0, soilConductivity)
        end
    else
        slabCarpetPerimeterConduction = FullSlabInsulation(0, 0, slabWidth, slabLength, 1, soilConductivity)
        slabBarePerimeterConduction = FullSlabInsulation(0, 0, slabWidth, slabLength, 0, soilConductivity)
    end
    
    return slabCarpetPerimeterConduction, slabBarePerimeterConduction, slabHasWholeInsulation
    
  end
  

  def PerimeterSlabInsulation(rperim, rgap, wperim, slabWidth, slabLength, carpet, k)
    # Coded by Dennis Barley, April 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   under the slab perimeter as well as gap insulation around the edge.
    #   The algorithm is based on a correlation to a set of related, fully insulated
    #   and uninsulated slab (sections), using the FullSlabInsulation function above.
    # Parameters:
    #   Rperim     = R-factor of insulation placed horizontally under the slab perimeter, h*ft2*F/Btu
    #   Rgap       = R-factor of insulation placed vertically between edge of slab & foundation wall, h*ft2*F/Btu
    #   Wperim     = Width of the perimeter insulation, ft.  Must be > 0.
    #   SlabWidth  = width (shorter dimension) of the slab, ft
    #   SlabLength = longer dimension of the slab, ft
    #   Carpet     = 1 if carpeted, 0 if not carpeted
    #   k          = thermal conductivity of the soil, Btu/h*ft*F
    # Constants:
    k2 =  0.329201  # 1st curve fit coefficient
    p = -0.327734  # 2nd curve fit coefficient
    q =  1.158418  # 3rd curve fit coefficient
    r =  0.144171  # 4th curve fit coefficient
    # Related, fully insulated slabs:
    b = FullSlabInsulation(rperim, rgap, 2 * wperim, slabLength, carpet, k)
    c = FullSlabInsulation(0 ,0 , slabWidth, slabLength, carpet, k)
    d = FullSlabInsulation(0, 0, 2 * wperim, slabLength, carpet, k)
    # Trap zeros or small negatives before exponents are applied:
    dB = [d-b, 0.0000001].max
    cD = [c-d, 0.0000001].max
    wp = [wperim, 0.0000001].max
    # Result:
    perimeterConductance = b + c - d + k2 * (2 * wp / slabWidth) ** p * dB ** q * cD ** r 
    return perimeterConductance 
  end

  def FullSlabInsulation(rbottom, rgap, w, l, carpet, k)
    # Coded by Dennis Barley, March 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   under the entire slab as well as gap insulation around the edge.
    # Parameters:
    #   Rbottom = R-factor of insulation placed horizontally under the entire slab, h*ft2*F/Btu
    #   Rgap    = R-factor of insulation placed vertically between edge of slab & foundation wall, h*ft2*F/Btu
    #   W       = width (shorter dimension) of the slab, ft.  Set to 28 to match Winkelmann analysis.
    #   L       = longer dimension of the slab, ft.  Set to 55 to match Winkelmann analysis. 
    #   Carpet  = 1 if carpeted, 0 if not carpeted
    #   k       = thermal conductivity of the soil, Btu/h*ft*F.  Set to 1 to match Winkelmann analysis.
    # Constants:
    zf = 0      # Depth of slab bottom, ft
    r0 = 1.47    # Thermal resistance of concrete slab and inside air film, h*ft2*F/Btu
    rca = 0      # R-value of carpet, if absent,  h*ft2*F/Btu
    rcp = 2.0      # R-value of carpet, if present, h*ft2*F/Btu
    rsea = 0.8860  # Effective resistance of slab edge if carpet is absent,  h*ft2*F/Btu
    rsep = 1.5260  # Effective resistance of slab edge if carpet is present, h*ft2*F/Btu
    t  = 4.0 / 12.0  # Thickness of slab: Assumed value if 4 inches; not a variable in the analysis, ft
    # Carpet factors:
    if carpet == 0
        rc  = rca
        rse = rsea
    else
        if carpet == 1
            rc  = rcp
            rse = rsep
        else
            runner.registerError("In FullSlabInsulation, Carpet must be 0 or 1.")
            return false
        end
    end
            
    rother = rc + r0 + rbottom   # Thermal resistance other than the soil (from inside air to soil)
    # Ubottom:
    term1 = 2.0 * k / (Math::PI * w)
    term3 = zf / 2.0 + k * rother / Math::PI
    term2 = term3 + w / 2.0
    ubottom = term1 * Math::log(term2 / term3)
    pbottom = ubottom * (l * w) / (2.0 * (l + w))
    # Uedge:
    uedge = 1.0 / (rse + rgap)
    pedge = t * uedge
    # Result:
    perimeterConductance = pbottom + pedge
    return perimeterConductance
  end

  def ExteriorSlabInsulation(depth, rvalue, carpet)
    # Coded by Dennis Barley, April 2013.
    # This routine calculates the perimeter conductance for a slab with insulation 
    #   placed vertically outside the foundation.
    #   This is a correlation to Winkelmann results.
    # Parameters:
    #   Depth     = Depth to which insulation extends into the ground, ft
    #   Rvalue    = R-factor of insulation, h*ft2*F/Btu
    #   Carpet    = 1 if carpeted, 0 if not carpeted
    # Carpet factors:
    if carpet == 0
        a  = 9.02928
        b  = 8.20902
        e1 = 0.54383
        e2 = 0.74266
    else
        if carpet == 1
            a  =  8.53957
            b  = 11.09168
            e1 =  0.57937
            e2 =  0.80699
        else
            runner.registerError("In ExteriorSlabInsulation, Carpet must be 0 or 1.")
            return false
        end
    end
    perimeterConductance = a / (b + rvalue ** e1 * depth ** e2) 
    return perimeterConductance
  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsSlab.new.registerWithApplication