require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class DoorAreaTest < MiniTest::Test
  
  def osm_geo
    return "2000sqft_2story_FB_GRG_UA.osm"
  end
  
  def osm_geo_rotated
    return "2000sqft_2story_FB_GRG_UA_Southwest_Orientation.osm"
  end
  
  def osm_geo_multifamily
    return "multifamily_3_units.osm"
  end
  
  def osm_geo_multifamily_urbanopt
    return "multifamily_urbanopt.osm"
  end
  
  def osm_geo_multifamily_interior_corridor
    return "multifamily_interior_corridor.osm"
  end
  
  def osm_geo_multifamily_exterior_corridor_inset
    return "multifamily_exterior_corridor_inset.osm"
  end
  
  def test_no_door_area
    args_hash = {}
    args_hash["door_area"] = 0
    result = _test_measure(osm_geo, args_hash, 0, 0, 0)
  end

  def test_sfd_new_construction_rotated
    args_hash = {}
    model = _test_measure(osm_geo_rotated, args_hash, 0, 20, 0)
  end
  
  def test_sfd_retrofit_replace
    args_hash = {}
    model = _test_measure(osm_geo, args_hash, 0, 20, 0)
    args_hash = {}
    args_hash["door_area"] = 30
    _test_measure(model, args_hash, 20, 30, 0)
  end
  
  def test_mf_retrofit_replace
    num_units = 3
    args_hash = {}
    model = _test_measure(osm_geo_multifamily, args_hash, 0, 20*num_units, 0)
    args_hash = {}
    args_hash["door_area"] = 30
    _test_measure(model, args_hash, 20*num_units, 30*num_units, 0)
  end
  
  def test_mf_urbanopt_retrofit_replace
    num_units = 8
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_urbanopt, args_hash, 0, 20*(num_units-1), 0)
    args_hash = {}
    args_hash["door_area"] = 30
    _test_measure(model, args_hash, 20*(num_units-1), 30*(num_units-1), 0)
  end
  
  def test_mf_interior_corridor
    num_units = 12
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_interior_corridor, args_hash, 0, 0, 20*num_units)
    args_hash = {}
    args_hash["door_area"] = 30
    _test_measure(model, args_hash, 20*num_units, 0, 30*num_units)
  end  
  
  def test_mf_exterior_corridor_inset
    num_units = 12
    args_hash = {}
    model = _test_measure(osm_geo_multifamily_exterior_corridor_inset, args_hash, 0, 20*num_units, 0)
    args_hash = {}
    args_hash["door_area"] = 30
    _test_measure(model, args_hash, 20*num_units, 30*num_units, 0)
  end

  def test_argument_error_invalid_door_area
    args_hash = {}
    args_hash["door_area"] = -20
    result = _test_error(osm_geo, args_hash)
    assert_equal(result.errors[0].logMessage, "Invalid door area.")
  end
  
  private
  
  def _test_error(osm_file, args_hash)
    # create an instance of the measure
    measure = CreateResidentialDoorArea.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    model = _get_model(osm_file)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
      
    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
    
  end
  
  def _test_measure(osm_file_or_model, args_hash, expected_door_area_removed, expected_exterior_door_area_added, expected_corridor_door_area_added)
    # create an instance of the measure
    measure = CreateResidentialDoorArea.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)
    assert(!measure.modeler_description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    model = _get_model(osm_file_or_model)

    # store the original doors in the model
    orig_doors = []
    model.getSubSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType.downcase != "door"
        orig_doors << sub_surface
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    
    # show the output
    #show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.finalCondition.is_initialized)

    # get new/deleted door objects
    new_objects = []
    model.getSubSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType.downcase != "door"
        next if orig_doors.include?(sub_surface)
        new_objects << sub_surface
    end
    del_objects = []
    orig_doors.each do |orig_door|
        has_door = false
        model.getSubSurfaces.each do |sub_surface|
            next if sub_surface != orig_door
            has_door = true
        end
        next if has_door
        del_objects << orig_door
    end
    
    new_exterior_door_area = 0
    new_corridor_door_area = 0
    new_objects.each do |door|
        if door.surface.get.outsideBoundaryCondition.downcase == "adiabatic"
            new_corridor_door_area += OpenStudio.convert(door.grossArea, "m^2", "ft^2").get
        else
            new_exterior_door_area += OpenStudio.convert(door.grossArea, "m^2", "ft^2").get
        end
    end

    del_door_area = 0
    del_objects.each do |door|
        del_door_area += OpenStudio.convert(door.grossArea, "m^2", "ft^2").get
    end

    assert_in_epsilon(expected_exterior_door_area_added, new_exterior_door_area, 0.01)
    assert_in_epsilon(expected_corridor_door_area_added, new_corridor_door_area, 0.01)
    assert_in_epsilon(expected_door_area_removed, del_door_area, 0.01)

    return model
  end  
  
  def _get_model(osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(File.dirname(__FILE__), osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
  end  
  
  def _get_doors(model)
    doors = []
    model.getSpaces.each do |space|
        space.surfaces.each do |surface|
            surface.subSurfaces.each do |sub_surface|
                next if sub_surface.subSurfaceType.downcase != "door"
                doors << door
            end
        end
    end
    return doors
  end

end
