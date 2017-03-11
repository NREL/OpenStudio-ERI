require 'simplecov'
require 'coveralls'

# Get the code coverage in html for local viewing
# and in JSON for coveralls
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
])

# Ignore some of the code in coverage testing
SimpleCov.start do
  add_filter '/measures/.*/resources/'
  add_filter '/measures/.*/tests/'
end

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress


# Helper methods below for unit tests

def get_model(measure_dir, osm_file_or_model)
    if osm_file_or_model.is_a?(OpenStudio::Model::Model)
        # nothing to do
        model = osm_file_or_model
    elsif osm_file_or_model.nil?
        # make an empty model
        model = OpenStudio::Model::Model.new
    else
        # load the test model
        translator = OpenStudio::OSVersion::VersionTranslator.new
        path = OpenStudio::Path.new(File.join(measure_dir, osm_file_or_model))
        model = translator.loadModel(path)
        assert((not model.empty?))
        model = model.get
    end
    return model
end  
  
def get_objects(model)
    # Returns a list with [ObjectTypeString, ModelObject] items
    objects = []
    model.modelObjects.each do |obj|
        objects << [get_model_object_type(obj), obj]
    end
    return objects
end
  
def get_object_additions(list1, list2, obj_type_exclusions=nil)
    # Identifies all objects in list2 that aren't in list1.
    # Returns a hash with key=ObjectTypeString, value=[ModelObjects]
    additions = {}
    list2.each do |obj_type2, obj2|
        next if list1.include?([obj_type2, obj2])
        next if not obj_type_exclusions.nil? and obj_type_exclusions.include?(obj_type2)
        if not additions.keys.include?(obj_type2)
            additions[obj_type2] = []
        end
        additions[obj_type2] << obj2
    end
    return additions
end
  
def get_model_object_type(model_object)
    # Hacky; is there a better way to get this?
    obj_type = model_object.to_s.split(',')[0].gsub('OS:','').gsub(':','')
    if obj_type == "MaterialNoMass"
        obj_type = "Material"
    elsif obj_type == "WindowMaterialSimpleGlazingSystem"
        obj_type = "SimpleGlazing"
    end
    return obj_type
end
  
def check_num_objects(objects, expected_num_objects, mode)
    # Checks for the exact number of objects as defined in expected_num_objects
    objects.each do |obj_type, new_objects|
        next if not new_objects[0].respond_to?("to_#{obj_type}")
        if expected_num_objects.include?(obj_type)
            puts "Incorrect number of #{obj_type} objects #{mode}." if new_objects.size != expected_num_objects[obj_type]
            assert_equal(expected_num_objects[obj_type], new_objects.size)
        else
            puts "Incorrect number of #{obj_type} objects #{mode}." if new_objects.size != 0
            assert_equal(0, new_objects.size)
        end
    end
    expected_num_objects.each do |obj_type, num_objects|
        next if objects.keys.include?(obj_type)
        puts "Incorrect number of #{obj_type} objects #{mode}." if num_objects != 0
        assert_equal(num_objects, 0)
    end
end