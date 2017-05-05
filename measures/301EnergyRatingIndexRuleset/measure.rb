# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require "#{File.dirname(__FILE__)}/resources/constants"

# start the measure
class EnergyRatingIndex301 < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "301 Energy Rating Index"
  end

  # human readable description
  def description
    return "Applies the ANSI/RESNET 301-2014 ruleset to the OpenStudio Model. Used as part of the caclulation of an Energy Rating Index."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Applies the Reference Building or Rated Building ruleset as specified by ANSI/RESNET 301-2014 \"Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index\"."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # the name of the space to add to the model
    building_types = []
    building_types << Constants.ERIReferenceHome
    building_types << Constants.ERIRatedHome
    #building_types << Constants.ERIndexAdjustmentDesign
    building_type = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("building_type", building_types, true)
    building_type.setDisplayName("Building Type")
    args << building_type

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("measures_dir", true)
    arg.setDisplayName("Residential Measures Directory")
    arg.setDescription("Absolute path of the residential measures.")
    args << arg
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    building_type = runner.getStringArgumentValue("building_type", user_arguments)
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)

    unless (Pathname.new measures_dir).absolute?
      measures_dir = File.expand_path(File.join(File.dirname(__FILE__), measures_dir))
    end
    unless Dir.exists?(measures_dir)
      runner.registerError("'#{measures_dir}' does not exist.")
      return false
    end
    
    # Get file/dir paths
    resources_dir = File.join(File.dirname(__FILE__), "resources")
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))
   
    measures = {}
    if building_type == Constants.ERIReferenceHome
        apply_reference_home_ruleset(model, measures_dir, runner, measures)
    elsif building_type == Constants.ERIRatedHome
        apply_rated_home_ruleset(model, measures_dir, runner, measures)
    elsif building_type == Constants.ERIndexAdjustmentDesign
        apply_index_adjustment_design_ruleset(model, measures_dir, runner, measures)
    end

    workflow_order = []
    workflow_json = JSON.parse(File.read(File.join(File.dirname(__FILE__), "resources", "measure-info.json")), :symbolize_names=>true)
    
    workflow_json.each do |group|
      group[:group_steps].each do |step|
        step[:measures].each do |measure|
          workflow_order << measure
        end
      end
    end
    
    # Call each measure for sample to build up model
    workflow_order.each do |measure_subdir|
      next unless measures.keys.include? measure_subdir

      # Gather measure arguments and call measure
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
      measure_instance = get_measure_instance(full_measure_path)
      argument_map = get_argument_map(model, measure_instance, measures[measure_subdir], measure_subdir, runner)
      print_measure_call(measures[measure_subdir], measure_subdir, runner)

      if not run_measure(model, measure_instance, argument_map, runner)
        return false
      end

    end
    
    return true

  end
  
  def apply_reference_home_ruleset(model, measures_dir, runner, measures)
    set_heating_setpoint_reference(model, measures_dir, runner, measures)
    set_cooling_setpoint_reference(model, measures_dir, runner, measures)
    set_orientation(model, measures_dir, runner, measures)
    set_neighbors(model, measures_dir, runner, measures)
    set_natural_ventilation(model, measures_dir, runner, measures)
    set_floor_covering_reference(model, measures_dir, runner, measures)
    set_floor_mass_reference(model, measures_dir, runner, measures)
    set_partition_wall_mass_reference(model, measures_dir, runner, measures)
    set_ceiling_mass_reference(model, measures_dir, runner, measures)
    set_roofing_material_reference(model, measures_dir, runner, measures)
    set_exterior_wall_reference(model, measures_dir, runner, measures)
    set_interzonal_wall_reference(model, measures_dir, runner, measures)
    set_interzonal_floor_reference(model, measures_dir, runner, measures)
    set_ceiling_reference(model, measures_dir, runner, measures)
    set_slab_reference(model, measures_dir, runner, measures)
    set_crawlspace_reference(model, measures_dir, runner, measures)
    set_unfinished_basement_reference(model, measures_dir, runner, measures)
    set_finished_basement_reference(model, measures_dir, runner, measures)
    set_pier_beam_reference(model, measures_dir, runner, measures)
    set_windows_reference(model, measures_dir, runner, measures)
    set_window_areas_reference(model, measures_dir, runner, measures)
    set_interior_shading(model, measures_dir, runner, measures)
    set_eaves_reference(model, measures_dir, runner, measures)
    set_overhangs_reference(model, measures_dir, runner, measures)
    set_doors_reference(model, measures_dir, runner, measures)
    set_door_areas_reference(model, measures_dir, runner, measures)
  end
  
  def apply_rated_home_ruleset(model, measures_dir, runner, measures)
    set_heating_setpoint_rated(model, measures_dir, runner, measures)
    set_cooling_setpoint_rated(model, measures_dir, runner, measures)
    set_neighbors(model, measures_dir, runner, measures)
    set_natural_ventilation(model, measures_dir, runner, measures)
    set_exterior_wall_rated(model, measures_dir, runner, measures)
    set_interzonal_wall_rated(model, measures_dir, runner, measures)
    set_interzonal_floor_rated(model, measures_dir, runner, measures)
    set_ceiling_rated(model, measures_dir, runner, measures)
    set_roofing_material_rated(model, measures_dir, runner, measures)
    set_crawlspace_rated(model, measures_dir, runner, measures)
    set_unfinished_basement_rated(model, measures_dir, runner, measures)
    set_finished_basement_rated(model, measures_dir, runner, measures)
    set_pier_beam_rated(model, measures_dir, runner, measures)
    set_interior_shading(model, measures_dir, runner, measures)
    set_infiltration_rated(model, measures_dir, runner, measures)
  end
  
  def apply_index_adjustment_design_ruleset(model, measures_dir, runner, measures)
  
  end
  
  def set_heating_setpoint_reference(model, measures_dir, runner, measures)
    '''
    Table 303.4.1(1) - Thermostat
    Type: manual
    Temperature setpoints: heating temperature set point = 68 F
    '''
    measure_subdir = "ResidentialHVACHeatingSetpoints"
    args = {
            "htg_wkdy" => 68,
            "htg_wked" => 68,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_heating_setpoint_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_cooling_setpoint_reference(model, measures_dir, runner, measures)
    '''
    Table 303.4.1(1) - Thermostat
    Type: manual
    Temperature setpoints: cooling temperature set point = 78 F
    '''
    measure_subdir = "ResidentialHVACCoolingSetpoints"
    args = {
            "clg_wkdy" => 78,
            "clg_wked" => 78,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_cooling_setpoint_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_orientation(model, measures_dir, runner, measures)
    '''
    Table 303.4.1(1) - Doors
    Orientation: North
    '''
    measure_subdir = "ResidentialGeometryOrientation"
    args = {
            "orientation" => 180,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_neighbors(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Glazing
    External shading: none
    '''
    measure_subdir = "ResidentialGeometryNeighbors"
    args = {
            "left_offset" => 0,
            "right_offset" => 0,
            "back_offset" => 0,
            "front_offset" => 0,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_natural_ventilation(model, measures_dir, runner, measures)
    '''
    4.3.7. Natural Ventilation. Natural ventilation shall be assumed in both the 
    Reference and Rated Homes during hours when natural ventilation will reduce 
    annual cooling energy use.
    '''
    measure_subdir = "ResidentialAirflow"
    args = {
            "nat_vent_htg_offset" => 1.0,
            "nat_vent_clg_offset" => 1.0,
            "nat_vent_ovlp_offset" => 1.0,
            "nat_vent_htg_season" => true,
            "nat_vent_clg_season" => true,
            "nat_vent_ovlp_season" => true,
            "nat_vent_num_weekdays" => 5,
            "nat_vent_num_weekends" => 2,
            "nat_vent_frac_windows_open" => 0.2,
            "nat_vent_frac_window_area_openable" => 0.33,
            "nat_vent_max_oa_hr" => 0.01115,
            "nat_vent_max_oa_rh" => 0.7
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_floor_covering_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Structural mass
    For masonry floor slabs, 80% of floor area covered by R-2 carpet and pad, and 
    20% of floor directly exposed to room air
    '''
    measure_subdir = "ResidentialConstructionsFoundationsFloorsCovering"
    args = {
            "covering_frac" => 0.8,
            "covering_r" => 2.0,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_floor_mass_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Structural mass
    For other walls, for ceilings, floors, and interior walls, wood frame construction
    '''
    measure_subdir = "ResidentialConstructionsFoundationsFloorsThermalMass"
    mass = Material.DefaultFloorMass
    args = {
            "thick_in" => mass.thick_in,
            "cond" => mass.k_in,
            "dens" => mass.rho,
            "specheat" => mass.cp,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_partition_wall_mass_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Structural mass
    For other walls, for ceilings, floors, and interior walls, wood frame construction
    '''
    measure_subdir = "ResidentialConstructionsWallsPartitionThermalMass"
    mass = Material.DefaultWallMass
    args = {
            "frac" => 1.0, # FIXME
            "thick_in1" => mass.thick_in,
            "cond1" => mass.k_in,
            "dens1" => mass.rho,
            "specheat1" => mass.cp,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_ceiling_mass_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Structural mass
    For other walls, for ceilings, floors, and interior walls, wood frame construction
    '''
    measure_subdir = "ResidentialConstructionsCeilingsRoofsThermalMass"
    mass = Material.DefaultCeilingMass
    args = {
            "thick_in1" => mass.thick_in,
            "cond1" => mass.k_in,
            "dens1" => mass.rho,
            "specheat1" => mass.cp,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_roofing_material_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Roofs
    Type: composition shingle on wood sheathing
    Gross area: same as Rated Home
    Solar absorptance = 0.75
    Emittance = 0.90
    '''
    measure_subdir = "ResidentialConstructionsCeilingsRoofsRoofingMaterial"
    args = {
            "solar_abs" => 0.75,
            "emissivity" => 0.90,
            "material" => Constants.RoofMaterialAsphaltShingles,
            "color" => Constants.ColorMedium,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_roofing_material_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_exterior_wall_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_exterior_wall_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_interzonal_wall_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_interzonal_wall_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_interzonal_floor_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_interzonal_floor_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_ceiling_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_ceiling_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_slab_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_crawlspace_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_crawlspace_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_unfinished_basement_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_unfinished_basement_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_finished_basement_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_finished_basement_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_pier_beam_reference(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_pier_beam_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_infiltration_rated(model, measures_dir, runner, measures)
    # TODO
  end
  
  def set_windows_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Glazing
    U-factor: from Table 4.2.2(2)
    SHGC: from Table 4.2.2(2)    
    '''
    measure_subdir = "ResidentialConstructionsWindows"
    climate_zone = "1A" # FIXME
    args = {
            "ufactor" => get_fenestration_door_u_value(climate_zone),
            "shgc" => 0.40,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end

  def set_window_areas_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Glazing
    Total area = 18% of CFA
    Orientation: equally distributed to four (4) cardinal compass orientations (N,E,S,&W)
    '''
    cfa = 2000.0 # FIXME
    front_wall_area = 1000.0 # FIXME
    back_wall_area = 1000.0 # FIXME
    left_wall_area = 1000.0 # FIXME
    right_wall_area = 1000.0 # FIXME
    measure_subdir = "ResidentialGeometryWindowArea"
    args = {
            "front_wwr" => cfa*0.18*0.25/front_wall_area,
            "back_wwr" => cfa*0.18*0.25/back_wall_area,
            "left_wwr" => cfa*0.18*0.25/left_wall_area,
            "right_wwr" => cfa*0.18*0.25/right_wall_area,
            "aspect_ratio" => 1.333,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_interior_shading(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Glazing
    Interior shade coefficient: Summer = 0.70; Winter = 0.85
    '''
    measure_subdir = "ResidentialConstructionsWindows"
    args = {
            "heating_shade_mult" => 0.85,
            "cooling_shade_mult" => 0.70,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def get_fenestration_door_u_value(cz)
    '''
    Table 4.2.2(2) - Fenestration and Opaque Door U-Factor
    '''
    if ["1A"].include? cz
        return 1.2
    elsif ["2A", "2B"].include? cz
        return 0.75
    elsif ["3A", "3B", "3C"].include? cz
        return 0.65
    elsif ["4A", "4B"].include? cz
        return 0.40
    else #4C-8; FIXME add error checking
        return 0.35
    end
  end
  
  def set_eaves_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Glazing
    External shading: none
    '''
    measure_subdir = "ResidentialGeometryEaves"
    args = {
            "roof_structure" => Constants.RoofStructureTrussCantilever,
            "eaves_depth" => 0.0,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end

  def set_overhangs_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Glazing
    External shading: none
    '''
    measure_subdir = "ResidentialGeometryOverhangs"
    args = {
            "depth" => 0.0,
            "offset" => 0.0,
            "front_facade" => false,
            "back_facade" => false,
            "left_facade" => false,
            "right_facade" => false,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_doors_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Doors
    U-factor: same as fenestration from Table 4.2.2(2)
    '''
    measure_subdir = "ResidentialConstructionsDoors"
    climate_zone = "1A" # FIXME
    args = {
            "door_uvalue" => get_fenestration_door_u_value(climate_zone),
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end
  
  def set_door_areas_reference(model, measures_dir, runner, measures)
    '''
    Table 4.2.2(1) - Doors
    Area: 40 ft2
    '''
    measure_subdir = "ResidentialGeometryDoorArea"
    args = {
            "door_area" => 40.0,
           }
    add_measure(model, measures_dir, measures, measure_subdir, runner)
    args.each do |arg, val|
      update_measure_args(measures, measure_subdir, arg, val)
    end
  end

  # TODO: Also in HPXML measure; move to common resource
  def add_measure(model, measures_dir, measures, measure_subdir, runner)
    unless measures.keys.include? measure_subdir
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
      check_file_exists(full_measure_path, runner)      
      measure_instance = get_measure_instance(full_measure_path)
      measures[measure_subdir] = default_args_hash(model, measure_instance)
    end
    return measures
  end
  
  # TODO: Similar in HPXML measure; move to common resource
  def update_measure_args(measures, measure, arg, val)
    new_measure_args = measures[measure]
    new_measure_args[arg] = val.to_s
    measures[measure].update(new_measure_args)
    return measures
  end  
  
  # TODO: Eventually remove this! We don't want to default any values
  def default_args_hash(model, measure)
    args_hash = {}
    arguments = measure.arguments(model)
    arguments.each do |arg|	
      if arg.hasDefaultValue
        type = arg.type.valueName
        case type
        when "Boolean"
          args_hash[arg.name] = arg.defaultValueAsBool.to_s
        when "Double"
          args_hash[arg.name] = arg.defaultValueAsDouble.to_s
        when "Integer"
          args_hash[arg.name] = arg.defaultValueAsInteger.to_s
        when "String"
          args_hash[arg.name] = arg.defaultValueAsString
        when "Choice"
          args_hash[arg.name] = arg.defaultValueAsString
        end
      else
        args_hash[arg.name] = nil
      end
    end
    return args_hash
  end
  
end

# register the measure to be used by the application
EnergyRatingIndex301.new.registerWithApplication
