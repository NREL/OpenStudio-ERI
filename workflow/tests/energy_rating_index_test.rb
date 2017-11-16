require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../../resources/xmlhelper.rb'

class EnergyRatingIndexTest < MiniTest::Test

  def test_simulations
    os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
    assert(os_clis.size > 0)
    os_cli = os_clis[-1]
    
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    ref_hpxml = File.join(parent_dir, "results", "HERSReferenceHome.xml")
    ref_osm = File.join(parent_dir, "results", "HERSReferenceHome.osm")
    rated_hpxml = File.join(parent_dir, "results", "HERSRatedHome.xml")
    rated_osm = File.join(parent_dir, "results", "HERSRatedHome.osm")
    results_csv = File.join(parent_dir, "results", "results.csv")
    worksheet_csv = File.join(parent_dir, "results", "worksheet.csv")
    
    xmls = Dir["#{parent_dir}/sample_files/*.xml"]
    
    xmls.each do |xml|
      xml = File.absolute_path(xml)
      _test_schema_validation(parent_dir, xml)
    
      command = "cd #{parent_dir} && \"#{os_cli}\" execute_ruby_script energy_rating_index.rb -x #{xml} --debug"
      system(command)
    
      assert(File.exists?(ref_hpxml))
      assert(File.exists?(rated_hpxml))
      assert(File.exists?(results_csv))
      assert(File.exists?(worksheet_csv))
    
      _test_schema_validation(parent_dir, ref_hpxml)
      _test_schema_validation(parent_dir, rated_hpxml)
    end
  end

  private
  
  def _test_schema_validation(parent_dir, xml)
    # FIXME: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(parent_dir, "..", "hpxml_schemas"))
    hpxml_doc = REXML::Document.new(File.read(xml))
    errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
    if errors.size > 0
      puts "#{xml}: #{errors.to_s}"
    end
    assert_equal(errors.size, 0)
  end
  
end
