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
class ProcessConstructionsSlab < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Finished Slab Construction"
  end
  
  def description
    return "This measure assigns a construction to finished slabs."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of slab constructions for floors between above-grade finished space and the ground."
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
	selected_slabins.setDisplayName("Insulation Type")
	selected_slabins.setDescription("The type of insulation.")
	selected_slabins.setDefaultValue("Uninsulated")
	args << selected_slabins

	#make a double argument for slab perimeter / exterior insulation R-value
	userdefined_slabperiextr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextr", false)
	userdefined_slabperiextr.setDisplayName("Perimeter/Exterior Insulation Nominal R-value")
	userdefined_slabperiextr.setUnits("hr-ft^2-R/Btu")
	userdefined_slabperiextr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabperiextr.setDefaultValue(0.0)
	args << userdefined_slabperiextr
	
	#make a double argument for slab perimeter insulation width / exterior insulation depth
	userdefined_slabperiextwidthdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabperiextwidthdepth", false)
	userdefined_slabperiextwidthdepth.setDisplayName("Perimeter/Exterior Insulation Width/Depth")
	userdefined_slabperiextwidthdepth.setUnits("ft")
	userdefined_slabperiextwidthdepth.setDescription("The width or depth of the perimeter or exterior insulation.")
	userdefined_slabperiextwidthdepth.setDefaultValue(0.0)
	args << userdefined_slabperiextwidthdepth
	
	#make a double argument for slab perimeter gap R-value
	userdefined_slabgapr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabgapr", false)
	userdefined_slabgapr.setDisplayName("Gap Insulation Nominal R-value")
	userdefined_slabgapr.setUnits("hr-ft^2-R/Btu")
	userdefined_slabgapr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabgapr.setDefaultValue(0.0)
	args << userdefined_slabgapr

	# Whole Slab Insulation
	#make a double argument for whole slab insulation R-value
	userdefined_slabwholer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedslabwholer", false)
	userdefined_slabwholer.setDisplayName("Whole Slab Insulation Nominal R-value")
	userdefined_slabwholer.setUnits("hr-ft^2-R/Btu")
	userdefined_slabwholer.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
	userdefined_slabwholer.setDefaultValue(0.0)
	args << userdefined_slabwholer

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    surfaces = []
    spaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if surface.outsideBoundaryCondition.downcase != "ground"
            surfaces << surface
            if not spaces.include? space
                # Floors between above-grade finished space and ground
                spaces << space
            end
        end
    end
  
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerNotApplicable("Measure not applied because no applicable surfaces were found.")
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
	
	# Insulation
	slabPerimeterRvalue = 0
	slabPerimeterInsWidth = nil
	slabExtRvalue = 0
	slabWholeInsRvalue = 0
    slabExtInsDepth = 0
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
	slabGapRvalue = nil
	if ["Perimeter", "Whole Slab"].include? selected_slabins.to_s
		slabGapRvalue = userdefined_slabgapr
	end
	
    slabArea = Geometry.calculate_floor_area(spaces)
    slabExtPerimeter = Geometry.calculate_perimeter_wall_area(spaces)
    
	# Process the slab

    # Define materials
    slabCarpetPerimeterConduction, slabBarePerimeterConduction, slabHasWholeInsulation = SlabPerimeterConductancesByType(slabPerimeterRvalue, slabGapRvalue, slabPerimeterInsWidth, slabExtRvalue, slabWholeInsRvalue, slabExtInsDepth)

    # Models one floor surface with an equivalent carpented/bare material (Better alternative
    # to having two floors with twice the total area, compensated by thinning mass thickness.)
    carpetFloorFraction = 0.8 # FIXME: Hard-coded
    slab_perimeter_conduction = slabCarpetPerimeterConduction * carpetFloorFraction + slabBarePerimeterConduction * (1 - carpetFloorFraction)

    if slabExtPerimeter > 0
        effective_slab_Rvalue = slabArea / (slabExtPerimeter * slab_perimeter_conduction)
    else
        effective_slab_Rvalue = 1000 # hr*ft^2*F/Btu
    end

    slab_Rvalue = Material.Concrete4in.rvalue - Material.AirFilmFlatReduced.rvalue - Material.Soil12in.rvalue - Material.DefaultCarpet.rvalue
    fictitious_slab_Rvalue = effective_slab_Rvalue - slab_Rvalue

    slab_factor = 1.0
    if fictitious_slab_Rvalue <= 0
        runner.registerWarning("The slab foundation thickness will be automatically reduced to avoid simulation errors, but overall R-value will remain the same.")
        slab_factor = effective_slab_Rvalue / slab_Rvalue
    end

    mat_fic = nil
    if fictitious_slab_Rvalue > 0
        # Fictitious layer below slab to achieve equivalent R-value. See Winkelmann article.
        mat_fic = Material.new(name="Mat-Fic-Slab", thick_in=1.0, mat_base=nil, cond=OpenStudio::convert(1.0,"in","ft").get/fictitious_slab_Rvalue, dens=2.5, sh=0.29)
    end
    mat_slab = Material.new(name='SlabMass', thick_in=Material.Concrete4in.thick_in*slab_factor, mat_base=Material.Concrete4in)

    # Define construction
    slab = Construction.new([1.0])
    if not mat_fic.nil?
        slab.addlayer(mat_fic, true)
    end
    slab.addlayer(Material.Soil12in, true)
    slab.addlayer(mat_slab, true)
    slab.addlayer(Material.DefaultCarpet, false) # carpet added in separate measure
    slab.addlayer(Material.AirFilmFlatReduced, false)
    
    # Create and assign construction to surfaces
    if not slab.create_and_assign_constructions(surfaces, runner, model, "Slab")
        return false
    end
    
    # Remove any materials which aren't used in any constructions
    HelperMethods.remove_unused_materials_and_constructions(model, runner)     

    return true
 
  end #end the run method

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
    elsif carpet == 1
        rc  = rcp
        rse = rsep
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
    elsif carpet == 1
        a  =  8.53957
        b  = 11.09168
        e1 =  0.57937
        e2 =  0.80699
    end
    perimeterConductance = a / (b + rvalue ** e1 * depth ** e2) 
    return perimeterConductance
  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsSlab.new.registerWithApplication