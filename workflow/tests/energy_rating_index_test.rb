require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'

class EnergyRatingIndexTest < MiniTest::Test

  def test_sample_hpxml_file
  
    os_clis = Dir["C:/openstudio-*/bin/openstudio.exe"] + Dir["/usr/bin/openstudio"] + Dir["/usr/local/bin/openstudio"]
    assert(os_clis.size > 0)
    os_cli = os_clis[-1]
    
    parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), ".."))
    ref_hpxml = File.join(parent_dir, "results", "HERSReferenceHome.xml")
    rated_hpxml = File.join(parent_dir, "results", "HERSRatedHome.xml")
    results_csv = File.join(parent_dir, "results", "results.csv")
    worksheet_csv = File.join(parent_dir, "results", "worksheet.csv")
    
    Dir["#{parent_dir}/sample_files/*.xml"].each do |xml|
      command = "cd #{parent_dir} && \"#{os_cli}\" execute_ruby_script energy_rating_index.rb -x #{xml}"
      system(command)
      
      assert(File.exists?(ref_hpxml))
      assert(File.exists?(rated_hpxml))
      assert(File.exists?(results_csv))
      assert(File.exists?(worksheet_csv))
    end
  end

end
