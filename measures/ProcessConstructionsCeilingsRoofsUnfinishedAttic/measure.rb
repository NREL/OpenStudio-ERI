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
class ProcessConstructionsCeilingsRoofsUnfinishedAttic < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Ceilings/Roofs - Unfinished Attic Constructions"
  end
  
  def description
    return "This measure assigns constructions to unfinished attic floors and ceilings."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of constructions for 1) floors between unfinished space under a roof and finished space and 2) roofs of unfinished space."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    uains_display_names = OpenStudio::StringVector.new
    uains_display_names << "Uninsulated"
    uains_display_names << "Ceiling"
    uains_display_names << "Roof"

    #make a choice argument for unfinished attic insulation type
    selected_uains = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduains", uains_display_names, false)
    selected_uains.setDisplayName("Insulation Type")
    selected_uains.setDescription("The type of insulation.")
    selected_uains.setDefaultValue("Ceiling")
    args << selected_uains

    #make a double argument for ceiling / roof insulation thickness
    userdefined_ceilroofinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedceilroofinsthickness", false)
    userdefined_ceilroofinsthickness.setDisplayName("Ceiling/Roof Insulation Thickness")
    userdefined_ceilroofinsthickness.setUnits("in")
    userdefined_ceilroofinsthickness.setDescription("The thickness in inches of insulation required to obtain a certain R-value.")
    userdefined_ceilroofinsthickness.setDefaultValue(8.55)
    args << userdefined_ceilroofinsthickness

    #make a double argument for unfinished attic ceiling / roof insulation R-value
    userdefined_uaceilroofr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaceilroofr", false)
    userdefined_uaceilroofr.setDisplayName("Ceiling/Roof Insulation Nominal R-value")
    userdefined_uaceilroofr.setUnits("hr-ft^2-R/Btu")
    userdefined_uaceilroofr.setDescription("R-value is a measure of insulation's ability to resist heat traveling through it.")
    userdefined_uaceilroofr.setDefaultValue(30.0)
    args << userdefined_uaceilroofr

    #make a choice argument for model objects
    joistthickness_display_names = OpenStudio::StringVector.new
    joistthickness_display_names << "3.5"

    #make a string argument for wood stud size of wall cavity
    selected_joistthickness = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduaceiljoistthickness", joistthickness_display_names, false)
    selected_joistthickness.setDisplayName("Ceiling Joist Thickness")
    selected_joistthickness.setDescription("Thickness of joists in the ceiling.")
    selected_joistthickness.setDefaultValue("3.5")
    args << selected_joistthickness

    #make a choice argument for unfinished attic ceiling framing factor
    userdefined_uaceilff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaceilff", false)
    userdefined_uaceilff.setDisplayName("Ceiling Framing Factor")
    userdefined_uaceilff.setUnits("frac")
    userdefined_uaceilff.setDescription("The framing factor of the ceiling.")
    userdefined_uaceilff.setDefaultValue(0.07)
    args << userdefined_uaceilff

    #make a choice argument for model objects
    framethickness_display_names = OpenStudio::StringVector.new
    framethickness_display_names << "7.25"

    #make a string argument for unfinished attic roof framing factor
    selected_framethickness = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteduaroofframethickness", framethickness_display_names, false)
    selected_framethickness.setDisplayName("Roof Framing Thickness")
    selected_framethickness.setUnits("in")
    selected_framethickness.setDescription("Thickness of roof framing.")
    selected_framethickness.setDefaultValue("7.25")
    args << selected_framethickness

    #make a choice argument for unfinished attic roof framing factor
    userdefined_uaroofff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineduaroofff", false)
    userdefined_uaroofff.setDisplayName("Roof Framing Factor")
    userdefined_uaroofff.setUnits("frac")
    userdefined_uaroofff.setDescription("Fraction of roof that is made up of framing elements.")
    userdefined_uaroofff.setDefaultValue(0.07)
    args << userdefined_uaroofff

    #make a double argument for rigid insulation thickness of roof cavity
    userdefined_rigidinsthickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsthickness", false)
    userdefined_rigidinsthickness.setDisplayName("Roof Continuous Insulation Thickness")
    userdefined_rigidinsthickness.setUnits("in")
    userdefined_rigidinsthickness.setDescription("Thickness of rigid insulation added to the roof.")
    userdefined_rigidinsthickness.setDefaultValue(0)
    args << userdefined_rigidinsthickness

    #make a double argument for rigid insulation R-value of roof cavity
    userdefined_rigidinsr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrigidinsr", false)
    userdefined_rigidinsr.setDisplayName("Roof Continuous Insulation Nominal R-value")
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

    # Initialize hashes
    constructions_to_surfaces = {"FinInsUnfinUAFloor"=>[], "RevFinInsUnfinUAFloor"=>[], "UnfinInsExtRoof"=>[]}
    constructions_to_objects = Hash.new  
    
    spaces = Geometry.get_unfinished_attic_spaces(model)
    spaces.each do |space|
        space.surfaces.each do |surface|
            next unless ["roofceiling"].include? surface.surfaceType.downcase
            adjacent_surface = surface.adjacentSurface
            next unless adjacent_surface.is_initialized
            adjacent_surface = adjacent_surface.get
            adjacent_surface_r = adjacent_surface.name.to_s
            adjacent_space_type_r = Geometry.get_space_type_from_surface(model, adjacent_surface_r, runner).name.to_s
            next unless [unfin_attic_space_type_r].include? adjacent_space_type_r
            constructions_to_surfaces["RevFinInsUnfinUAFloor"] << surface
            constructions_to_surfaces["FinInsUnfinUAFloor"] << adjacent_surface
        end   
    end 
    
    spaces.each do |space|
        space.surfaces.each do |surface|
            next unless surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
            constructions_to_surfaces["UnfinInsExtRoof"] << surface
        end   
    end

    # Continue if no applicable surfaces
    if constructions_to_surfaces.all? {|construction, surfaces| surfaces.empty?}
        runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
        return true
    end   
    
    eavesDepth = 0 # FIXME: Currently hard-coded

    # Unfinished Attic Insulation
    selected_uains = runner.getStringArgumentValue("selecteduains",user_arguments)

    # Ceiling / Roof Insulation
    if ["Ceiling", "Roof"].include? selected_uains.to_s
        userdefined_uaceilroofr = runner.getDoubleArgumentValue("userdefineduaceilroofr",user_arguments)
        userdefined_ceilroofinsthickness = runner.getDoubleArgumentValue("userdefinedceilroofinsthickness",user_arguments)
    end

    # Ceiling Joist Thickness
    uACeilingJoistThickness = {"3.5"=>3.5}[runner.getStringArgumentValue("selecteduaceiljoistthickness",user_arguments)]

    # Ceiling Framing Factor
    uACeilingFramingFactor = runner.getDoubleArgumentValue("userdefineduaceilff",user_arguments)
    if not ( uACeilingFramingFactor > 0.0 and uACeilingFramingFactor < 1.0 )
        runner.registerError("Invalid unfinished attic ceiling framing factor")
        return false
    end

    # Roof Framing Thickness
    uARoofFramingThickness = {"7.25"=>7.25}[runner.getStringArgumentValue("selecteduaroofframethickness",user_arguments)]

    # Roof Framing Factor
    uARoofFramingFactor = runner.getDoubleArgumentValue("userdefineduaroofff",user_arguments)
    if not ( uARoofFramingFactor > 0.0 and uARoofFramingFactor < 1.0 )
        runner.registerError("Invalid unfinished attic roof framing factor")
        return false
    end

    # Rigid
    rigidInsThickness = 0
    rigidInsRvalue = 0
    if ["Roof"].include? selected_uains.to_s
        rigidInsThickness = runner.getDoubleArgumentValue("userdefinedrigidinsthickness",user_arguments)
        rigidInsRvalue = runner.getDoubleArgumentValue("userdefinedrigidinsr",user_arguments)
        rigidInsConductivity = OpenStudio::convert(rigidInsThickness,"in","ft").get / rigidInsRvalue
        rigidInsDensity = BaseMaterial.InsulationRigid.rho
        rigidInsSpecificHeat = BaseMaterial.InsulationRigid.cp
    end

    # Insulation
    uACeilingInsThickness = 0
    uACeilingInsRvalueNominal = 0
    uARoofInsThickness = 0
    uARoofInsRvalueNominal = 0
    if selected_uains.to_s == "Ceiling"
        uACeilingInsThickness = userdefined_ceilroofinsthickness
        uACeilingInsRvalueNominal = userdefined_uaceilroofr
    elsif selected_uains.to_s == "Roof"
        uARoofInsThickness = userdefined_ceilroofinsthickness
        uARoofInsRvalueNominal = userdefined_uaceilroofr
    end

    mat_film_roof = Material.AirFilmRoof(Geometry.calculate_avg_roof_pitch(spaces))

    # -------------------------------
    # Process the attic ceiling
    # -------------------------------

    unless constructions_to_surfaces["FinInsUnfinUAFloor"].empty?

      if uACeilingInsThickness == 0
        uACeilingInsThickness_Rev = uACeilingInsThickness
        
      else

        spaceArea_Rev_UAtc = 0
        windBaffleClearance = 2 # Minimum 2" wind baffle clearance

        if uARoofFramingThickness < 10
          birdMouthDepth = 0
        else
          birdMouthDepth = 1.5 # inches
        end
      
        #FIXME: Lots of hard-coded stuff here.

        #(2...@model.getBuildingStorys.length + 1).to_a.each do |i|
        # temp
        (2..2).to_a.each do |i|
        #
          spaceArea_UAtc = 0
          rfEdgeW_UAtc = 0
          rfEdgeMinH_UAtc = 0
          rfPerimeter_UAtc = 0
          spaceArea_UAtc_Perim = 0
          # index_num = story_num - 1

          #rfTilt = Geometry.roof_pitch.item[index_num]
          # temp
          rfTilt = 26.565052
          #

          # if Geometry.roof_structure.item[index_num].nil?
          #   next
          # end

          #Geometry.roofs.roof.each do |roof|
          # temp
          (0..1).each do |k|
          #

            # if not (roof.story == story_num and roof.space_below == Constants::SpaceUnfinAttic)
            #   next
            # end

            perimeterUAtc = 0

            # if Geometry.roof_structure.item[index_num] == Constants::RoofStructureRafter
            # temp
            roofstructurerafter = "trusscantilever"
            if roofstructurerafter == "rafter"
              rfEdgeMinH_UAtc = OpenStudio::convert([uACeilingInsThickness, (1 - uACeilingFramingFactor) * ((uARoofFramingThickness - windBaffleClearance) / Math::cos(rfTilt / 180 * Math::PI) - birdMouthDepth)].min,"in","ft").get # ft
              rfEdgeW_UAtc = [0, (OpenStudio::convert(uACeilingInsThickness,"in","ft").get - rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI)].max # ft
            else
              rfEdgeMinH_UAtc = OpenStudio::convert([uACeilingInsThickness, OpenStudio::convert(eaves_depth * Math::tan(rfTilt / 180 * Math::PI),"ft","in").get + [0, (1 - uACeilingFramingFactor) * ((uARoofFramingThickness - windBaffleClearance) / Math::cos(rfTilt / 180 * Math::PI) - birdMouthDepth)].max].min,"in","ft").get # ft
              rfEdgeW_UAtc = [0, (OpenStudio::convert(uACeilingInsThickness,"in","ft").get - rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI)].max # ft
            end

            # min_z = min(roof.vertices.coord.z)
            # roof.vertices.coord[:-1].each_with_index do |vertex,vnum|
            #   vertex_next = roof.vertices.coord[vnum + 1]
            #   if vertex.z < min_z + 0.1 and vertex_next.z < min_z + 0.1
            #     dRoofX = vertex_next.x - vertex.x
            #     dRoofY = vertex_next.y - vertex.y
            #     perimeterUAtc += sqrt(dRoofX ** 2 + dRoofY ** 2) # Calculate unfinished attic Mid edge perimeter
            #   end
            # end
            # temp
            if k == 0
              perimeterUAtc = 40
            elsif k == 1
              perimeterUAtc = 40
            end
            #

            rfPerimeter_UAtc += perimeterUAtc
            #spaceArea_UAtc += roof.area * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
            # temp
            if k == 0
              spaceArea_UAtc += 670.8204 * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
            elsif k == 1
              spaceArea_UAtc += 670.8204 * Math::cos(rfTilt / 180 * Math::PI) # Unfinished attic Area
            end
            #
            spaceArea_UAtc_Perim += (perimeterUAtc - 2 * rfEdgeW_UAtc) * rfEdgeW_UAtc

          end

          spaceArea_UAtc_Perim += 4 * rfEdgeW_UAtc ** 2

          if spaceArea_UAtc_Perim != 0 and rfEdgeMinH_UAtc < OpenStudio::convert(uACeilingInsThickness,"in","ft").get
            spaceArea_UAtc = spaceArea_UAtc - spaceArea_UAtc_Perim + Math::log((rfEdgeW_UAtc * Math::tan(rfTilt / 180 * Math::PI) + rfEdgeMinH_UAtc) / rfEdgeMinH_UAtc) / Math::tan(rfTilt / 180 * Math::PI) * rfPerimeter_UAtc * OpenStudio::convert(uACeilingInsThickness,"in","ft").get
          end

          spaceArea_Rev_UAtc += spaceArea_UAtc

        end

        area = 1000 # FIXME: Currently hard-coded
        uACeilingInsThickness_Rev = uACeilingInsThickness * area / spaceArea_Rev_UAtc
      end

    
      # Define materials
      mat_ins = nil
      mat_cavity = nil
      mat_framing = nil
      mat_ctf = nil
      if uACeilingInsThickness == 0
        uACeilingInsRvalueNominal_Rev = uACeilingInsRvalueNominal
      else
        uACeilingInsRvalueNominal_Rev = [uACeilingInsRvalueNominal * uACeilingInsThickness_Rev / uACeilingInsThickness, 0.0001].max
      end
      if uACeilingInsRvalueNominal_Rev != 0 and uACeilingInsThickness_Rev != 0
        if uACeilingInsThickness_Rev >= uACeilingJoistThickness
          # If the ceiling insulation thickness is greater than the joist thickness
          mat_cavity = Material.new(name=nil, thick_in=uACeilingJoistThickness, mat_base=BaseMaterial.InsulationGenericLoosefill, cond=OpenStudio::convert(uACeilingInsThickness_Rev,"in","ft").get / uACeilingInsRvalueNominal_Rev)
          if uACeilingInsThickness_Rev > uACeilingJoistThickness
            # If there is additional insulation, above the rafter height,
            # these inputs are used for defining an additional layer
            ins_thick_in = uACeilingInsThickness_Rev - uACeilingJoistThickness
            mat_ins = Material.new(name="UAAdditionalCeilingIns", thick_in=ins_thick_in, mat_base=BaseMaterial.InsulationGenericLoosefill, cond=OpenStudio::convert(uACeilingInsThickness_Rev,"in","ft").get / uACeilingInsRvalueNominal_Rev)
          end
        else
          # Else the joist thickness is greater than the ceiling insulation thickness
          if uACeilingInsRvalueNominal_Rev == 0
            cond_insul = 99999
          else
            cond_insul = uA_ceiling_joist_ins_thickness / uACeilingInsRvalueNominal_Rev
          end
          mat_cavity = Material.new(name=nil, thick_in=uACeilingJoistThickness, mat_base=BaseMaterial.InsulationGenericLoosefill, cond=cond_insul)
        end
        mat_framing = Material.new(name=nil, thick_in=uACeilingJoistThickness, mat_base=BaseMaterial.Wood)
      else
         # Without insulation, we run the risk of CTF errors ("Construction too thin or too light")
         # We add a layer here to prevent that error.
         mat_ctf = Material.new(name="AddforCTFCalc", thick_in=0.75, mat_base=BaseMaterial.Wood)
      end
      
      # Set paths
      path_fracs = [uACeilingFramingFactor, 1 - uACeilingFramingFactor]
      
      # Define construction
      attic_floor = Construction.new(path_fracs)
      attic_floor.addlayer(Material.AirFilmFloorAverage, false)
      attic_floor.addlayer(Material.GypsumCeiling1_2in, false) # thermal mass added in separate measure
      if not mat_framing.nil? and not mat_cavity.nil?
        attic_floor.addlayer([mat_framing, mat_cavity], true, "UATrussandIns")
      end
      if not mat_ins.nil?
        attic_floor.addlayer(mat_ins, true)
      end
      if not mat_ctf.nil?
        attic_floor.addlayer(mat_ctf, true)
      end
      attic_floor.addlayer(Material.AirFilmFloorAverage, false)
      

      # Create construction
      constr = ub_ceiling.create_construction(runner, model, "FinInsUnfinUAFloor")
      if constr.nil?
          return false
      end
      constructions_to_objects["FinInsUnfinUAFloor"] = constr
      revconstr = constr.reverseConstruction
      revconstr.setName("RevFinInsUnfinUAFloor")
      constructions_to_objects["RevFinInsUnfinUAFloor"] = revconstr
    end    
    
    # -------------------------------
    # Process the attic roof
    # -------------------------------
    
    # Define materials
    uA_roof_ins_thickness = OpenStudio::convert([uARoofInsThickness, uARoofFramingThickness].max,"in","ft").get
    if uARoofInsRvalueNominal == 0
      cavity_k = 1000000000
    else
      cavity_k = OpenStudio::convert(uARoofInsThickness,"in","ft").get / uARoofInsRvalueNominal
      if uARoofInsThickness < uARoofFramingThickness
        cavity_k = cavity_k * uARoofFramingThickness / uARoofInsThickness
      end
    end
    if uARoofInsThickness > uARoofFramingThickness and uARoofFramingThickness > 0
      wood_k = BaseMaterial.Wood.k * uARoofInsThickness / uARoofFramingThickness
    else
      wood_k = BaseMaterial.Wood.k
    end
    
    # Set paths
    path_fracs = [uARoofFramingFactor, 1 - uARoofFramingFactor]
    
    # Define construction
    roof_const = Construction.new(path_fracs)
    roof_const.addlayer(mat_film_roof, false)
    
    # Assign construction
    
    
    
    
    
    
    
    roof_const.addlayer(thickness=uA_roof_ins_thickness, conductivity_list=[wood_k, cavity_k])

    # Sheathing
    roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)

    # Rigid
    if uARoofContInsThickness > 0
      roof_const.addlayer(thickness=OpenStudio::convert(uARoofContInsThickness,"in","ft").get, conductivity_list=[OpenStudio::convert(uARoofContInsThickness,"in","ft").get / uARoofContInsRvalue])
      # More sheathing
      roof_const.addlayer(thickness=nil, conductivity_list=nil, material=Material.Plywood3_4in, material_list=nil)
    end

    # Exterior Film
    roof_const.addlayer(thickness=OpenStudio::convert(1.0,"in","ft").get, conductivity_list=[OpenStudio::convert(1.0,"in","ft").get / Material.AirFilmOutside.rvalue])

    uA_roof_overall_ins_Rvalue = roof_const.rvalue_parallel
    roof_ins_thick = uA_roof_ins_thickness

    if uARoofContInsThickness > 0
      uA_roof_overall_ins_Rvalue = (uA_roof_overall_ins_Rvalue - mat_film_roof.rvalue - Material.AirFilmOutside.rvalue - 2.0 * Material.Plywood3_4in.rvalue - uARoofContInsRvalue) # hr*ft^2*F/Btu

      roof_rigid_thick = OpenStudio::convert(uUARoofContInsThickness,"in","ft").get
      roof_rigid_cond = roof_rigid_thick / uARoofContInsRvalue # Btu/hr*ft*F
      roof_rigid_dens = BaseMaterial.InsulationRigid.rho # lbm/ft^3
      roof_rigid_sh = BaseMaterial.InsulationRigid.cp # Btu/lbm*F

    else

      uA_roof_overall_ins_Rvalue = (uA_roof_overall_ins_Rvalue - mat_film_roof.rvalue - Material.AirFilmOutside.rvalue - Material.Plywood3_4in.rvalue) # hr*ft^2*F/Btu
      
    end

    roof_ins_cond = roof_ins_thick / uA_roof_overall_ins_Rvalue # Btu/hr*ft*F

    if uARoofInsRvalueNominal == 0
      roof_ins_dens = uARoofFramingFactor * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * Gas.Air.cp # lbm/ft^3
      roof_ins_sh = (uARoofFramingFactor * BaseMaterial.Wood.cp * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * Gas.Air.cp * Gas.Air.cp) / roof_ins_dens # Btu/lb*F
    else
      roof_ins_dens = uARoofFramingFactor * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * BaseMaterial.InsulationGenericDensepack.rho # lbm/ft^3
      roof_ins_sh = (uARoofFramingFactor * BaseMaterial.Wood.cp * BaseMaterial.Wood.rho + (1 - uARoofFramingFactor) * BaseMaterial.InsulationGenericDensepack.cp * BaseMaterial.InsulationGenericDensepack.rho) / roof_ins_dens # Btu/lb*F
    end


    # RoofingMaterial
    mat_roof_mat = Material.RoofMaterial(roofMatEmissivity, roofMatAbsorptivity)
    roofmat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    roofmat.setName("RoofingMaterial")
    roofmat.setRoughness("Rough")
    roofmat.setThickness(OpenStudio::convert(mat_roof_mat.thick,"ft","m").get)
    roofmat.setConductivity(OpenStudio::convert(mat_roof_mat.k,"Btu/hr*ft*R","W/m*K").get)
    roofmat.setDensity(OpenStudio::convert(mat_roof_mat.rho,"lb/ft^3","kg/m^3").get)
    roofmat.setSpecificHeat(OpenStudio::convert(mat_roof_mat.cp,"Btu/lb*R","J/kg*K").get)
    roofmat.setThermalAbsorptance(mat_roof_mat.tAbs)
    roofmat.setSolarAbsorptance(mat_roof_mat.sAbs)
    roofmat.setVisibleAbsorptance(mat_roof_mat.vAbs)

    # Plywood-3_4in
    ply3_4 = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    ply3_4.setName("Plywood-3_4in")
    ply3_4.setRoughness("Rough")
    ply3_4.setThickness(OpenStudio::convert(Material.Plywood3_4in.thick,"ft","m").get)
    ply3_4.setConductivity(OpenStudio::convert(Material.Plywood3_4in.k,"Btu/hr*ft*R","W/m*K").get)
    ply3_4.setDensity(OpenStudio::convert(Material.Plywood3_4in.rho,"lb/ft^3","kg/m^3").get)
    ply3_4.setSpecificHeat(OpenStudio::convert(Material.Plywood3_4in.cp,"Btu/lb*R","J/kg*K").get)

    # UARigidRoofIns
    if rigidInsThickness > 0
      uarri = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      uarri.setName("UARigidRoofIns")
      uarri.setRoughness("Rough")
      uarri.setThickness(OpenStudio::convert(roof_rigid_thick,"ft","m").get)
      uarri.setConductivity(OpenStudio::convert(roof_rigid_cond,"Btu/hr*ft*R","W/m*K").get)
      uarri.setDensity(OpenStudio::convert(roof_rigid_dens,"lb/ft^3","kg/m^3").get)
      uarri.setSpecificHeat(OpenStudio::convert(roof_rigid_sh,"Btu/lb*R","J/kg*K").get)
    end

    # UARoofIns
    uari = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    uari.setName("UARoofIns")
    uari.setRoughness("Rough")
    uari.setThickness(OpenStudio::convert(roof_ins_thick,"ft","m").get)
    uari.setConductivity(OpenStudio::convert(roof_ins_cond,"Btu/hr*ft*R","W/m*K").get)
    uari.setDensity(OpenStudio::convert(roof_ins_dens,"lb/ft^3","kg/m^3").get)
    uari.setSpecificHeat(OpenStudio::convert(roof_ins_sh,"Btu/lb*R","J/kg*K").get)

    # UnfinInsExtRoof
    materials = []
    materials << roofmat
    materials << ply3_4
    if rigidInsThickness > 0
      materials << uarri
      materials << ply3_4
    end
    materials << uari
    unless constructions_to_surfaces["UnfinInsExtRoof"].empty?
        unfininsextroof = OpenStudio::Model::Construction.new(materials)
        unfininsextroof.setName("UnfinInsExtRoof")
        constructions_to_objects["UnfinInsExtRoof"] = unfininsextroof
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
ProcessConstructionsCeilingsRoofsUnfinishedAttic.new.registerWithApplication