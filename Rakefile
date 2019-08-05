require 'fileutils'

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'
require 'pp'
require 'colored'
require 'json'

namespace :test do
  desc 'Run all tests'
  Rake::TestTask.new('all') do |t|
    t.libs << 'test'
    t.test_files = Dir['measures/*/tests/*.rb'] + Dir['workflow/tests/*.rb'] - Dir['measures/HPXMLtoOpenStudio/tests/*.rb'] # HPXMLtoOpenStudio is tested upstream
    t.warning = false
    t.verbose = true
  end
end

desc 'generate sample outputs'
task :generate_sample_outputs do
  require 'openstudio'
  Dir.chdir('workflow')

  FileUtils.rm_rf("sample_results/.", secure: true)
  sleep 1
  FileUtils.mkdir_p("sample_results")

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" --no-ssl energy_rating_index.rb -x sample_files/base.xml"
  system(command)

  dirs = ["ERIRatedHome",
          "ERIReferenceHome",
          "ERIIndexAdjustmentDesign",
          "ERIIndexAdjustmentReferenceHome",
          "results"]
  dirs.each do |dir|
    FileUtils.copy_entry dir, "sample_results/#{dir}"
  end
end

desc 'update all measures'
task :update_measures do
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? and ENV['HOME'].start_with? 'U:'
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? and ENV['HOMEDRIVE'].start_with? 'U:'

  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  create_hpxmls

  copy_sample_files

  puts "Done."
end

def create_hpxmls
  require_relative "measures/HPXMLtoOpenStudio/resources/hpxml"
  require_relative "measures/HPXMLtoOpenStudio/resources/hotwater_appliances"
  require_relative "measures/HPXMLtoOpenStudio/resources/lighting"

  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, "workflow/tests")

  # Hash of HPXML -> Parent HPXML
  hpxmls_files = {
    'RESNET_Tests/4.1_Standard_140/L100AC.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L100AL.xml' => nil,
    'RESNET_Tests/4.1_Standard_140/L110AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L110AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L120AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L120AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L130AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L130AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L140AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L140AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L150AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L150AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L160AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L160AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L170AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L170AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L200AC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L200AL.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.1_Standard_140/L302XC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L322XC.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.1_Standard_140/L155AC.xml' => 'RESNET_Tests/4.1_Standard_140/L150AC.xml',
    'RESNET_Tests/4.1_Standard_140/L155AL.xml' => 'RESNET_Tests/4.1_Standard_140/L150AL.xml',
    'RESNET_Tests/4.1_Standard_140/L202AC.xml' => 'RESNET_Tests/4.1_Standard_140/L200AC.xml',
    'RESNET_Tests/4.1_Standard_140/L202AL.xml' => 'RESNET_Tests/4.1_Standard_140/L200AL.xml',
    'RESNET_Tests/4.1_Standard_140/L304XC.xml' => 'RESNET_Tests/4.1_Standard_140/L302XC.xml',
    'RESNET_Tests/4.1_Standard_140/L324XC.xml' => 'RESNET_Tests/4.1_Standard_140/L322XC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml' => 'RESNET_Tests/4.1_Standard_140/L304XC.xml',
    'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml' => 'RESNET_Tests/4.1_Standard_140/L324XC.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.3_HERS_Method/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/4.4_HVAC/HVAC1a.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.4_HVAC/HVAC1b.xml' => 'RESNET_Tests/4.4_HVAC/HVAC1a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2a.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2b.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2c.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2d.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.4_HVAC/HVAC2e.xml' => 'RESNET_Tests/4.4_HVAC/HVAC2a.xml',
    'RESNET_Tests/4.5_DSE/HVAC3a.xml' => 'RESNET_Tests/4.1_Standard_140/L322XC.xml',
    'RESNET_Tests/4.5_DSE/HVAC3b.xml' => 'RESNET_Tests/4.5_DSE/HVAC3a.xml',
    'RESNET_Tests/4.5_DSE/HVAC3c.xml' => 'RESNET_Tests/4.5_DSE/HVAC3b.xml',
    'RESNET_Tests/4.5_DSE/HVAC3d.xml' => 'RESNET_Tests/4.5_DSE/HVAC3c.xml',
    'RESNET_Tests/4.5_DSE/HVAC3e.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.5_DSE/HVAC3f.xml' => 'RESNET_Tests/4.5_DSE/HVAC3e.xml',
    'RESNET_Tests/4.5_DSE/HVAC3g.xml' => 'RESNET_Tests/4.5_DSE/HVAC3f.xml',
    'RESNET_Tests/4.5_DSE/HVAC3h.xml' => 'RESNET_Tests/4.5_DSE/HVAC3g.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-04.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-06.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AD-HW-07.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-04.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-06.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml',
    'RESNET_Tests/4.6_Hot_Water/L100AM-HW-07.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/01-L100.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/02-L100.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/03-L304.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
    'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/04-L324.xml' => 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-01.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
    'RESNET_Tests/Other_HERS_Method_PreAddendumE/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-07.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-08.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-12.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-13.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-14.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-15.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-17.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-18.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-21.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-07.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-08.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-12.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-13.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-14.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-15.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-17.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-18.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-21.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-06.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-09.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-10.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-11.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-12.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-06.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-09.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-10.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-11.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-12.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-01.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-01.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-02.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
    'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-03.xml' => 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml',
    'NASEO_Technical_Exercises/NASEO-01.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-06.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-07.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-08.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-09.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-09b.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-10.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-10b.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-11.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-12.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-13.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-14.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-15.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-16.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-17.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-18.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-19.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-20.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'NASEO_Technical_Exercises/NASEO-21.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml'
  }

  puts "Generating #{hpxmls_files.size} HPXML files..."

  hpxmls_files.each do |derivative, parent|
    print "."

    begin
      hpxml_files = [derivative]
      unless parent.nil?
        hpxml_files.unshift(parent)
      end
      while not parent.nil?
        if hpxmls_files.keys.include? parent
          unless hpxmls_files[parent].nil?
            hpxml_files.unshift(hpxmls_files[parent])
          end
          parent = hpxmls_files[parent]
        end
      end

      hpxml_values = {}
      site_values = {}
      building_occupancy_values = {}
      building_construction_values = {}
      climate_and_risk_zones_values = {}
      air_infiltration_measurement_values = {}
      attic_values = {}
      foundation_values = {}
      roofs_values = []
      rim_joists_values = []
      walls_values = []
      foundation_walls_values = []
      framefloors_values = []
      slabs_values = []
      windows_values = []
      skylights_values = []
      doors_values = []
      heating_systems_values = []
      cooling_systems_values = []
      heat_pumps_values = []
      hvac_control_values = {}
      hvac_distributions_values = []
      duct_leakage_measurements_values = []
      ducts_values = []
      ventilation_fans_values = []
      water_heating_systems_values = []
      hot_water_distribution_values = {}
      water_fixtures_values = []
      pv_systems_values = []
      clothes_washer_values = {}
      clothes_dryer_values = {}
      dishwasher_values = {}
      refrigerator_values = {}
      cooking_range_values = {}
      oven_values = {}
      lighting_values = {}
      ceiling_fans_values = []
      plug_loads_values = []
      misc_load_schedule_values = {}
      hpxml_files.each do |hpxml_file|
        hpxml_values = get_hpxml_file_hpxml_values(hpxml_file, hpxml_values)
        site_values = get_hpxml_file_site_values(hpxml_file, site_values)
        building_occupancy_values = get_hpxml_file_building_occupancy_values(hpxml_file, building_occupancy_values)
        building_construction_values = get_hpxml_file_building_construction_values(hpxml_file, building_construction_values)
        climate_and_risk_zones_values = get_hpxml_file_climate_and_risk_zones_values(hpxml_file, climate_and_risk_zones_values)
        air_infiltration_measurement_values = get_hpxml_file_air_infiltration_measurement_values(hpxml_file, air_infiltration_measurement_values, building_construction_values)
        attic_values = get_hpxml_file_attic_values(hpxml_file, attic_values)
        foundation_values = get_hpxml_file_foundation_values(hpxml_file, foundation_values)
        roofs_values = get_hpxml_file_roofs_values(hpxml_file, roofs_values)
        rim_joists_values = get_hpxml_file_rim_joists_values(hpxml_file, rim_joists_values)
        walls_values = get_hpxml_file_walls_values(hpxml_file, walls_values)
        foundation_walls_values = get_hpxml_file_foundation_walls_values(hpxml_file, foundation_walls_values)
        framefloors_values = get_hpxml_file_framefloors_values(hpxml_file, framefloors_values)
        slabs_values = get_hpxml_file_slabs_values(hpxml_file, slabs_values)
        windows_values = get_hpxml_file_windows_values(hpxml_file, windows_values)
        skylights_values = get_hpxml_file_skylights_values(hpxml_file, skylights_values)
        doors_values = get_hpxml_file_doors_values(hpxml_file, doors_values)
        heating_systems_values = get_hpxml_file_heating_systems_values(hpxml_file, heating_systems_values)
        cooling_systems_values = get_hpxml_file_cooling_systems_values(hpxml_file, cooling_systems_values)
        heat_pumps_values = get_hpxml_file_heat_pumps_values(hpxml_file, heat_pumps_values)
        hvac_control_values = get_hpxml_file_hvac_control_values(hpxml_file, hvac_control_values)
        hvac_distributions_values = get_hpxml_file_hvac_distributions_values(hpxml_file, hvac_distributions_values)
        duct_leakage_measurements_values = get_hpxml_file_duct_leakage_measurements_values(hpxml_file, duct_leakage_measurements_values)
        ducts_values = get_hpxml_file_ducts_values(hpxml_file, ducts_values)
        ventilation_fans_values = get_hpxml_file_ventilation_fan_values(hpxml_file, ventilation_fans_values)
        water_heating_systems_values = get_hpxml_file_water_heating_system_values(hpxml_file, water_heating_systems_values)
        hot_water_distribution_values = get_hpxml_file_hot_water_distribution_values(hpxml_file, hot_water_distribution_values, building_construction_values, foundation_walls_values)
        water_fixtures_values = get_hpxml_file_water_fixtures_values(hpxml_file, water_fixtures_values)
        pv_systems_values = get_hpxml_file_pv_system_values(hpxml_file, pv_systems_values)
        clothes_washer_values = get_hpxml_file_clothes_washer_values(hpxml_file, clothes_washer_values)
        clothes_dryer_values = get_hpxml_file_clothes_dryer_values(hpxml_file, clothes_dryer_values)
        dishwasher_values = get_hpxml_file_dishwasher_values(hpxml_file, dishwasher_values)
        refrigerator_values = get_hpxml_file_refrigerator_values(hpxml_file, refrigerator_values, building_construction_values)
        cooking_range_values = get_hpxml_file_cooking_range_values(hpxml_file, cooking_range_values)
        oven_values = get_hpxml_file_oven_values(hpxml_file, oven_values)
        lighting_values = get_hpxml_file_lighting_values(hpxml_file, lighting_values)
        ceiling_fans_values = get_hpxml_file_ceiling_fan_values(hpxml_file, ceiling_fans_values)
        plug_loads_values = get_hpxml_file_plug_loads_values(hpxml_file, plug_loads_values)
        misc_load_schedule_values = get_hpxml_file_misc_load_schedule_values(hpxml_file, misc_load_schedule_values)
      end

      hpxml_doc = HPXML.create_hpxml(**hpxml_values)
      hpxml = hpxml_doc.elements["HPXML"]

      if File.exists? File.join(tests_dir, derivative)
        old_hpxml_doc = XMLHelper.parse_file(File.join(tests_dir, derivative))
        created_date_and_time = HPXML.get_hpxml_values(hpxml: old_hpxml_doc.elements["HPXML"])[:created_date_and_time]
        hpxml.elements["XMLTransactionHeaderInformation/CreatedDateAndTime"].text = created_date_and_time
      end

      HPXML.add_site(hpxml: hpxml, **site_values) unless site_values.nil?
      HPXML.add_building_occupancy(hpxml: hpxml, **building_occupancy_values) unless building_occupancy_values.empty?
      HPXML.add_building_construction(hpxml: hpxml, **building_construction_values)
      HPXML.add_climate_and_risk_zones(hpxml: hpxml, **climate_and_risk_zones_values)
      HPXML.add_air_infiltration_measurement(hpxml: hpxml, **air_infiltration_measurement_values)
      HPXML.add_attic(hpxml: hpxml, **attic_values) unless attic_values.empty?
      HPXML.add_foundation(hpxml: hpxml, **foundation_values) unless foundation_values.empty?
      roofs_values.each do |roof_values|
        HPXML.add_roof(hpxml: hpxml, **roof_values)
      end
      rim_joists_values.each do |rim_joist_values|
        HPXML.add_rim_joist(hpxml: hpxml, **rim_joist_values)
      end
      walls_values.each do |wall_values|
        HPXML.add_wall(hpxml: hpxml, **wall_values)
      end
      foundation_walls_values.each do |foundation_wall_values|
        HPXML.add_foundation_wall(hpxml: hpxml, **foundation_wall_values)
      end
      framefloors_values.each do |framefloor_values|
        HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
      end
      slabs_values.each do |slab_values|
        HPXML.add_slab(hpxml: hpxml, **slab_values)
      end
      windows_values.each do |window_values|
        HPXML.add_window(hpxml: hpxml, **window_values)
      end
      skylights_values.each do |skylight_values|
        HPXML.add_skylight(hpxml: hpxml, **skylight_values)
      end
      doors_values.each do |door_values|
        HPXML.add_door(hpxml: hpxml, **door_values)
      end
      heating_systems_values.each do |heating_system_values|
        HPXML.add_heating_system(hpxml: hpxml, **heating_system_values)
      end
      cooling_systems_values.each do |cooling_system_values|
        HPXML.add_cooling_system(hpxml: hpxml, **cooling_system_values)
      end
      heat_pumps_values.each do |heat_pump_values|
        HPXML.add_heat_pump(hpxml: hpxml, **heat_pump_values)
      end
      HPXML.add_hvac_control(hpxml: hpxml, **hvac_control_values) unless hvac_control_values.empty?
      hvac_distributions_values.each_with_index do |hvac_distribution_values, i|
        hvac_distribution = HPXML.add_hvac_distribution(hpxml: hpxml, **hvac_distribution_values)
        air_distribution = hvac_distribution.elements["DistributionSystemType/AirDistribution"]
        next if air_distribution.nil?

        duct_leakage_measurements_values[i].each do |duct_leakage_measurement_values|
          HPXML.add_duct_leakage_measurement(air_distribution: air_distribution, **duct_leakage_measurement_values)
        end
        ducts_values[i].each do |duct_values|
          HPXML.add_ducts(air_distribution: air_distribution, **duct_values)
        end
      end
      ventilation_fans_values.each do |ventilation_fan_values|
        HPXML.add_ventilation_fan(hpxml: hpxml, **ventilation_fan_values)
      end
      water_heating_systems_values.each do |water_heating_system_values|
        HPXML.add_water_heating_system(hpxml: hpxml, **water_heating_system_values)
      end
      HPXML.add_hot_water_distribution(hpxml: hpxml, **hot_water_distribution_values) unless hot_water_distribution_values.empty?
      water_fixtures_values.each do |water_fixture_values|
        HPXML.add_water_fixture(hpxml: hpxml, **water_fixture_values)
      end
      pv_systems_values.each do |pv_system_values|
        HPXML.add_pv_system(hpxml: hpxml, **pv_system_values)
      end
      HPXML.add_clothes_washer(hpxml: hpxml, **clothes_washer_values) unless clothes_washer_values.empty?
      HPXML.add_clothes_dryer(hpxml: hpxml, **clothes_dryer_values) unless clothes_dryer_values.empty?
      HPXML.add_dishwasher(hpxml: hpxml, **dishwasher_values) unless dishwasher_values.empty?
      HPXML.add_refrigerator(hpxml: hpxml, **refrigerator_values) unless refrigerator_values.empty?
      HPXML.add_cooking_range(hpxml: hpxml, **cooking_range_values) unless cooking_range_values.empty?
      HPXML.add_oven(hpxml: hpxml, **oven_values) unless oven_values.empty?
      HPXML.add_lighting(hpxml: hpxml, **lighting_values) unless lighting_values.empty?
      ceiling_fans_values.each do |ceiling_fan_values|
        HPXML.add_ceiling_fan(hpxml: hpxml, **ceiling_fan_values)
      end
      plug_loads_values.each do |plug_load_values|
        HPXML.add_plug_load(hpxml: hpxml, **plug_load_values)
      end
      HPXML.add_misc_loads_schedule(hpxml: hpxml, **misc_load_schedule_values) unless misc_load_schedule_values.empty?

      hpxml_path = File.join(tests_dir, derivative)

      # Validate file against HPXML schema
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), "measures", "HPXMLtoOpenStudio", "hpxml_schemas"))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
      if errors.size > 0
        fail errors.to_s
      end

      XMLHelper.write_file(hpxml_doc, hpxml_path)
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end

  puts "\n"

  # Print warnings about extra files
  abs_hpxml_files = []
  dirs = [nil]
  hpxmls_files.keys.each do |hpxml_file|
    abs_hpxml_files << File.join(tests_dir, hpxml_file)
    next unless hpxml_file.include? '/'

    dirs << hpxml_file.split('/')[0] + '/'
  end
  dirs.uniq.each do |dir|
    Dir["#{tests_dir}/#{dir}*.xml"].each do |xml|
      next if abs_hpxml_files.include? File.absolute_path(xml)

      puts "Warning: Extra HPXML file found at #{File.absolute_path(xml)}"
    end
  end
end

def get_hpxml_file_hpxml_values(hpxml_file, hpxml_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration w/ all Addenda
    hpxml_values = { :xml_type => "HPXML",
                     :xml_generated_by => "Rakefile",
                     :transaction => "create",
                     :software_program_used => nil,
                     :software_program_version => nil,
                     :eri_calculation_version => "2014AEG",
                     :building_id => "MyBuilding",
                     :event_type => "proposed workscope" }
  elsif hpxml_file.include? 'RESNET_Tests/Other_Hot_Water_PreAddendumA'
    # Pre-Addendum A
    hpxml_values[:eri_calculation_version] = "2014"
  elsif hpxml_file.include? 'RESNET_Tests/Other_HERS_Method_PreAddendumE'
    # Pre-Addendum E
    hpxml_values[:eri_calculation_version] = "2014A"
  end
  return hpxml_values
end

def get_hpxml_file_site_values(hpxml_file, site_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    site_values = { :fuels => ["electricity", "natural gas"],
                    :disable_natural_ventilation => true }
  else
    site_values = { :fuels => ["electricity", "natural gas"] }
  end
  return site_values
end

def get_hpxml_file_building_occupancy_values(hpxml_file, building_occupancy_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    building_occupancy_values = { :number_of_residents => 0 }
  else
    building_occupancy_values = {}
  end
  return building_occupancy_values
end

def get_hpxml_file_building_construction_values(hpxml_file, building_construction_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    building_construction_values = { :number_of_conditioned_floors => 1,
                                     :number_of_conditioned_floors_above_grade => 1,
                                     :number_of_bedrooms => 3,
                                     :conditioned_floor_area => 1539,
                                     :conditioned_building_volume => 12312 }
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml',
         'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    # Conditioned basement
    building_construction_values[:number_of_conditioned_floors] = 2
    building_construction_values[:conditioned_floor_area] = 3078
    building_construction_values[:conditioned_building_volume] = 24624
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml'].include? hpxml_file
    # 2 bedrooms
    building_construction_values[:number_of_bedrooms] = 2
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml'].include? hpxml_file
    # 4 bedrooms
    building_construction_values[:number_of_bedrooms] = 4
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Unconditioned basement
    building_construction_values[:number_of_conditioned_floors] = 1
    building_construction_values[:conditioned_floor_area] = 1539
    building_construction_values[:conditioned_building_volume] = 12312
  end
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140'
    building_construction_values[:use_only_ideal_air_system] = true
  else
    building_construction_values[:use_only_ideal_air_system] = nil
  end
  return building_construction_values
end

def get_hpxml_file_climate_and_risk_zones_values(hpxml_file, climate_and_risk_zones_values)
  if hpxml_file == 'RESNET_Tests/4.1_Standard_140/L100AC.xml'
    # Colorado Springs
    climate_and_risk_zones_values = { :iecc2006 => "5B",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Colorado Springs, CO",
                                      :weather_station_wmo => "724660" }
  elsif hpxml_file == 'RESNET_Tests/4.1_Standard_140/L100AL.xml'
    # Las Vegas
    climate_and_risk_zones_values = { :iecc2006 => "3B",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Las Vegas, NV",
                                      :weather_station_wmo => "723860" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    # Baltimore
    climate_and_risk_zones_values = { :iecc2006 => "4A",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Baltimore, MD",
                                      :weather_station_wmo => "724060" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Dallas
    climate_and_risk_zones_values = { :iecc2006 => "3A",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Dallas, TX",
                                      :weather_station_wmo => "722590" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    # Miami
    climate_and_risk_zones_values = { :iecc2006 => "1A",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Miami, FL",
                                      :weather_station_wmo => "722020" }
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml'].include? hpxml_file
    # Duluth
    climate_and_risk_zones_values = { :iecc2006 => "7",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Duluth, MN",
                                      :weather_station_wmo => "727450" }
  end
  return climate_and_risk_zones_values
end

def get_hpxml_file_air_infiltration_measurement_values(hpxml_file, air_infiltration_measurement_values, building_construction_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :constant_ach_natural => 0.67 }
  elsif ['RESNET_Tests/4.1_Standard_140/L110AC.xml',
         'RESNET_Tests/4.1_Standard_140/L110AL.xml',
         'RESNET_Tests/4.1_Standard_140/L200AC.xml',
         'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    # High Infiltration
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :constant_ach_natural => 1.5 }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :unit_of_measure => "ACHnatural",
                                            :air_leakage => 0.67 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 3 ACH50
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :house_pressure => 50,
                                            :unit_of_measure => "ACH",
                                            :air_leakage => 3 }
  end
  air_infiltration_measurement_values[:infiltration_volume] = building_construction_values[:conditioned_building_volume]
  return air_infiltration_measurement_values
end

def get_hpxml_file_attic_values(hpxml_file, attic_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    attic_values = { :id => "VentedAttic",
                     :attic_type => "VentedAttic",
                     :vented_attic_constant_ach => 2.4,
                     :vented_attic_sla => nil }
  else
    # Reference home
    attic_values = { :id => "VentedAttic",
                     :attic_type => "VentedAttic",
                     :vented_attic_constant_ach => nil,
                     :vented_attic_sla => (1.0 / 300.0).round(5) }
  end
end

def get_hpxml_file_foundation_values(hpxml_file, foundation_values)
  if hpxml_file.include? 'RESNET_Tests/Other_HERS_Method_Proposed' or
     ['NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    # Vented crawlspace
    foundation_values = { :id => "VentedCrawlspace",
                          :foundation_type => "VentedCrawlspace",
                          :vented_crawlspace_sla => (1.0 / 150.0).round(5) }
  else
    foundation_values = {}
  end
end

def get_hpxml_file_roofs_values(hpxml_file, roofs_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    roofs_values = [{ :id => "AtticRoof",
                      :interior_adjacent_to => "attic - vented",
                      :area => 1622.2,
                      :azimuth => nil,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :pitch => 4,
                      :radiant_barrier => false,
                      :insulation_assembly_r_value => 1.99 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml',
         'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    # Low Exterior Solar Absorptance
    roofs_values[0][:solar_absorptance] = 0.2
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-09.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-10.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-09.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-10.xml'].include? hpxml_file
    # Radiant barrier
    roofs_values[0][:radiant_barrier] = true
  end
  return roofs_values
end

def get_hpxml_file_rim_joists_values(hpxml_file, rim_joists_values)
  if ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Uninsulated ASHRAE Conditioned Basement
    rim_joists_values = [{ :id => "RimJoist",
                           :exterior_adjacent_to => "outside",
                           :interior_adjacent_to => "basement - conditioned",
                           :area => 126,
                           :azimuth => nil,
                           :solar_absorptance => 0.6,
                           :emittance => 0.9,
                           :insulation_assembly_r_value => 5.01 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L324XC.xml'].include? hpxml_file
    # Interior Insulation Applied to Uninsulated ASHRAE Conditioned Basement Wall
    rim_joists_values[0][:insulation_assembly_r_value] = 13.14
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    rim_joists_values = []
  end
  return rim_joists_values
end

def get_hpxml_file_walls_values(hpxml_file, walls_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    walls_values = [{ :id => "Wall",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 1344,
                      :azimuth => nil,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_assembly_r_value => 11.76 },
                    { :id => "WallAtticGable",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "attic - vented",
                      :wall_type => "WoodStud",
                      :area => 121.5,
                      :azimuth => nil,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_assembly_r_value => 2.15 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L120AC.xml',
         'RESNET_Tests/4.1_Standard_140/L120AL.xml'].include? hpxml_file
    # Well-Insulated Walls
    walls_values[0][:insulation_assembly_r_value] = 23.58
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml',
         'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    # Uninsulated
    walls_values[0][:insulation_assembly_r_value] = 4.84
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml',
         'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    # Low Exterior Solar Absorptance
    walls_values[0][:solar_absorptance] = 0.2
    walls_values[1][:solar_absorptance] = 0.2
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Cavity insulation = R-13, grade I; Continuous sheathing insulation = R-5; Framing fraction = 0.25; Solar absorptance = 0.75
    walls_values[0][:solar_absorptance] = 0.75
    walls_values[0][:insulation_assembly_r_value] = 16.9
  end
  return walls_values
end

def get_hpxml_file_foundation_walls_values(hpxml_file, foundation_walls_values)
  # TODO: Allow multiple foundation walls
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    foundation_walls_values = []
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Uninsulated ASHRAE Conditioned Basement
    foundation_walls_values = [{ :id => "FoundationWall",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 7.25,
                                 :area => 1218,
                                 :azimuth => nil,
                                 :thickness => 6,
                                 :depth_below_grade => 6.583,
                                 :insulation_distance_to_bottom => 0,
                                 :insulation_r_value => 0 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L324XC.xml'].include? hpxml_file
    # Interior Insulation Applied to Uninsulated ASHRAE Conditioned Basement Wall
    foundation_walls_values[0][:insulation_distance_to_bottom] = 7.25
    foundation_walls_values[0][:insulation_r_value] = 10.2
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'NASEO_Technical_Exercises/NASEO-13.xml'].include? hpxml_file
    # Un-vented crawlspace with R-7 crawlspace wall insulation
    foundation_walls_values = [{ :id => "FoundationWall",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "crawlspace - unvented",
                                 :height => 4,
                                 :area => 672,
                                 :azimuth => nil,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_distance_to_bottom => 4,
                                 :insulation_r_value => 7 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # 2 ft. high crawlspace above grade
    foundation_walls_values = [{ :id => "FoundationWall",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "crawlspace - vented",
                                 :height => 2,
                                 :area => 336,
                                 :azimuth => nil,
                                 :thickness => 6,
                                 :depth_below_grade => 0,
                                 :insulation_distance_to_bottom => 0,
                                 :insulation_r_value => 0 }]
  elsif ['NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    # Vented crawlspace foundation with 4 ft height and uninsulated crawlspace wall insulation
    foundation_walls_values = [{ :id => "FoundationWall",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "crawlspace - vented",
                                 :height => 4,
                                 :area => 672,
                                 :azimuth => nil,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_distance_to_bottom => 0,
                                 :insulation_r_value => 0 }]
  elsif ['NASEO_Technical_Exercises/NASEO-15.xml',
         'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    # R-19 basement wall insulation
    foundation_walls_values = [{ :id => "FoundationWall",
                                 :exterior_adjacent_to => "ground",
                                 :height => 8,
                                 :area => 1344,
                                 :azimuth => nil,
                                 :thickness => 8,
                                 :depth_below_grade => 7,
                                 :insulation_distance_to_bottom => 8,
                                 :insulation_r_value => 19 }]
    if ['NASEO_Technical_Exercises/NASEO-15.xml'].include? hpxml_file
      foundation_walls_values[0][:interior_adjacent_to] = "basement - unconditioned"
    else
      foundation_walls_values[0][:interior_adjacent_to] = "basement - conditioned"
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    foundation_walls_values[0][:interior_adjacent_to] = "basement - unconditioned"
  end
  return foundation_walls_values
end

def get_hpxml_file_framefloors_values(hpxml_file, framefloors_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Base configuration
    framefloors_values = [{ :id => "FloorUnderAttic",
                            :exterior_adjacent_to => "attic - vented",
                            :interior_adjacent_to => "living space",
                            :area => 1539,
                            :insulation_assembly_r_value => 18.45 },
                          { :id => "FloorOverFoundation",
                            :exterior_adjacent_to => "outside",
                            :interior_adjacent_to => "living space",
                            :area => 1539,
                            :insulation_assembly_r_value => 14.15 }]
    if ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
      framefloors_values[1][:exterior_adjacent_to] = "basement - unconditioned"
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L120AC.xml',
         'RESNET_Tests/4.1_Standard_140/L120AL.xml'].include? hpxml_file
    # Well-Insulated Walls and Roof
    framefloors_values[0][:insulation_assembly_r_value] = 57.49
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml',
         'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    # Energy Inefficient
    framefloors_values[0][:insulation_assembly_r_value] = 11.75
    framefloors_values[1][:insulation_assembly_r_value] = 4.24
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'NASEO_Technical_Exercises/NASEO-13.xml'].include? hpxml_file
    # Uninsulated
    framefloors_values[1][:insulation_assembly_r_value] = 4.24
    framefloors_values[1][:exterior_adjacent_to] = "crawlspace - unvented"
  elsif ['NASEO_Technical_Exercises/NASEO-15.xml'].include? hpxml_file
    # Uninsulated
    framefloors_values[1][:insulation_assembly_r_value] = 4.24
    framefloors_values[1][:exterior_adjacent_to] = "basement - unconditioned"
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Blown insulation = R-38, grade I; Framing fraction = 0.11
    framefloors_values[0][:insulation_assembly_r_value] = 39.3
    # Cavity insulation = R-30, grade I; Framing fraction = 0.13; Covering = 100% carpet and pad
    framefloors_values[1][:insulation_assembly_r_value] = 28.1
    framefloors_values[1][:exterior_adjacent_to] = "crawlspace - vented"
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Blown insulation = R-49, grade I; Framing fraction = 0.11
    framefloors_values[0][:insulation_assembly_r_value] = 50.3
    # Cavity insulation = R-19, grade I; Framing fraction = 0.13; Covering = 100% carpet and pad
    framefloors_values[1][:insulation_assembly_r_value] = 20.4
    framefloors_values[1][:exterior_adjacent_to] = "crawlspace - vented"
  elsif ['RESNET_Tests/4.1_Standard_140/L302XC.xml',
         'RESNET_Tests/4.1_Standard_140/L322XC.xml',
         'RESNET_Tests/4.1_Standard_140/L324XC.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'NASEO_Technical_Exercises/NASEO-16.xml',
         'NASEO_Technical_Exercises/NASEO-17.xml'].include? hpxml_file
    framefloors_values.delete_at(1)
  elsif ['NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    # R-13 crawlspace ceiling insulation
    framefloors_values[1][:exterior_adjacent_to] = "crawlspace - vented"
    framefloors_values[1][:insulation_assembly_r_value] = 15.6
  end
  return framefloors_values
end

def get_hpxml_file_slabs_values(hpxml_file, slabs_values)
  # TODO: Review carpet values
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    slabs_values = []
  elsif ['RESNET_Tests/4.1_Standard_140/L302XC.xml'].include? hpxml_file
    # Slab-on-Grade, Uninsulated ASHRAE Slab
    slabs_values = [{ :id => "Slab",
                      :interior_adjacent_to => "living space",
                      :area => 1539,
                      :thickness => 4,
                      :exposed_perimeter => 168,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :under_slab_insulation_spans_entire_slab => nil,
                      :depth_below_grade => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 1,
                      :carpet_r_value => 2.08 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L304XC.xml'].include? hpxml_file
    # Slab-on-Grade, Insulated ASHRAE Slab
    slabs_values[0][:perimeter_insulation_depth] = 2.5
    slabs_values[0][:perimeter_insulation_r_value] = 5.4
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    # Uninsulated ASHRAE Conditioned Basement
    slabs_values = [{ :id => "Slab",
                      :interior_adjacent_to => "basement - conditioned",
                      :area => 1539,
                      :thickness => 4,
                      :exposed_perimeter => 168,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :under_slab_insulation_spans_entire_slab => nil,
                      :depth_below_grade => 6.583,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'NASEO_Technical_Exercises/NASEO-13.xml',
         'NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    # Unvented/vented crawlspace
    slabs_values = [{ :id => "Slab",
                      :area => 1539,
                      :thickness => 0,
                      :exposed_perimeter => 168,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :under_slab_insulation_spans_entire_slab => nil,
                      :depth_below_grade => 3,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 2.5 }]
    if ['NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
      slabs_values[0][:interior_adjacent_to] = "crawlspace - vented"
    else
      slabs_values[0][:interior_adjacent_to] = "crawlspace - unvented"
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 2 ft. high crawlspace above grade
    slabs_values = [{ :id => "Slab",
                      :interior_adjacent_to => "crawlspace - vented",
                      :area => 1539,
                      :thickness => 0,
                      :exposed_perimeter => 168,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :under_slab_insulation_spans_entire_slab => nil,
                      :depth_below_grade => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 1,
                      :carpet_r_value => 2 }]
  elsif ['NASEO_Technical_Exercises/NASEO-15.xml',
         'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    slabs_values = [{ :id => "Slab",
                      :area => 1539,
                      :thickness => 4,
                      :exposed_perimeter => 168,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :under_slab_insulation_spans_entire_slab => nil,
                      :depth_below_grade => 7,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 2.5 }]
    if ['NASEO_Technical_Exercises/NASEO-15.xml'].include? hpxml_file
      slabs_values[0][:interior_adjacent_to] = "basement - unconditioned"
    elsif ['NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
      slabs_values[0][:interior_adjacent_to] = "basement - conditioned"
    end
  elsif ['NASEO_Technical_Exercises/NASEO-17.xml'].include? hpxml_file
    # Slab-on-grade foundation with 4 ft of R-5 horizontal under-slab insulation
    slabs_values = [{ :id => "Slab",
                      :interior_adjacent_to => "living space",
                      :area => 1539,
                      :thickness => 4,
                      :exposed_perimeter => 168,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 4,
                      :under_slab_insulation_spans_entire_slab => nil,
                      :depth_below_grade => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 5,
                      :carpet_fraction => 0,
                      :carpet_r_value => 2.5 }]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    slabs_values[0][:interior_adjacent_to] = "basement - unconditioned"
  end
  return slabs_values
end

def get_hpxml_file_windows_values(hpxml_file, windows_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    windows_values = []
    windows = { "WindowNorth" => [0, 90], "WindowEast" => [90, 45], "WindowSouth" => [180, 90], "WindowWest" => [270, 45] }
    windows.each do |window_name, window_values|
      azimuth, area = window_values
      windows_values << { :id => window_name,
                          :area => area,
                          :azimuth => azimuth,
                          :ufactor => 1.039,
                          :shgc => 0.67,
                          :wall_idref => "Wall" }
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L130AC.xml',
         'RESNET_Tests/4.1_Standard_140/L130AL.xml'].include? hpxml_file
    # Double-pane low-emissivity window with wood frame
    for i in 0..windows_values.size - 1
      windows_values[i][:ufactor] = 0.3
      windows_values[i][:shgc] = 0.335
    end
  elsif ['RESNET_Tests/4.1_Standard_140/L140AC.xml',
         'RESNET_Tests/4.1_Standard_140/L140AL.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-06.xml'].include? hpxml_file
    # No windows
    windows_values = []
  elsif ['RESNET_Tests/4.1_Standard_140/L150AC.xml',
         'RESNET_Tests/4.1_Standard_140/L150AL.xml'].include? hpxml_file
    # South windows only
    windows_values = [{ :id => "WindowsSouth",
                        :area => 270,
                        :azimuth => 180,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "Wall" }]
  elsif ['RESNET_Tests/4.1_Standard_140/L155AC.xml',
         'RESNET_Tests/4.1_Standard_140/L155AL.xml'].include? hpxml_file
    # South windows with overhangs
    windows_values[0][:overhangs_depth] = 2.5
    windows_values[0][:overhangs_distance_to_top_of_window] = 1
    windows_values[0][:overhangs_distance_to_bottom_of_window] = 6
  elsif ['RESNET_Tests/4.1_Standard_140/L160AC.xml',
         'RESNET_Tests/4.1_Standard_140/L160AL.xml'].include? hpxml_file
    # East and West windows only
    windows_values = []
    windows = { "WindowEast" => [90, 135], "WindowWest" => [270, 135] }
    windows.each do |window_name, window_values|
      azimuth, area = window_values
      windows_values << { :id => window_name,
                          :area => area,
                          :azimuth => azimuth,
                          :ufactor => 1.039,
                          :shgc => 0.67,
                          :wall_idref => "Wall" }
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Base configuration
    for i in 0..windows_values.size - 1
      windows_values[i][:ufactor] = 0.32
      windows_values[i][:shgc] = 0.4
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Base configuration
    for i in 0..windows_values.size - 1
      windows_values[i][:ufactor] = 0.35
      windows_values[i][:shgc] = 0.25
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-11.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-11.xml'].include? hpxml_file
    # Window SHGC set to 0.01
    for i in 0..windows_values.size - 1
      windows_values[i][:shgc] = 0.01
    end
  end
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # No interior shading
    for i in 0..windows_values.size - 1
      windows_values[i][:interior_shading_factor_summer] = 1
      windows_values[i][:interior_shading_factor_winter] = 1
    end
  else
    # Default interior shading
    for i in 0..windows_values.size - 1
      windows_values[i][:interior_shading_factor_summer] = nil
      windows_values[i][:interior_shading_factor_winter] = nil
    end
  end
  return windows_values
end

def get_hpxml_file_skylights_values(hpxml_file, skylights_values)
  return skylights_values
end

def get_hpxml_file_doors_values(hpxml_file, doors_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml',
      'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    # Base configuration
    doors_values = []
    doors = { "DoorSouth" => [180, 20], "DoorNorth" => [0, 20] }
    doors.each do |door_name, door_values|
      azimuth, area = door_values
      doors_values << { :id => door_name,
                        :wall_idref => "Wall",
                        :area => area,
                        :azimuth => azimuth,
                        :r_value => 3.04 }
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # U-factor = 0.35
    for i in 0..doors_values.size - 1
      doors_values[i][:r_value] = (1.0 / 0.35).round(2)
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # U-factor = 0.32
    for i in 0..doors_values.size - 1
      doors_values[i][:r_value] = (1.0 / 0.32).round(2)
    end
  end
  return doors_values
end

def get_hpxml_file_heating_systems_values(hpxml_file, heating_systems_values)
  if ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
      'RESNET_Tests/4.4_HVAC/HVAC2d.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    heating_systems_values = []
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    # Gas furnace with AFUE = 82%
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.82,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'NASEO_Technical_Exercises/NASEO-07.xml'].include? hpxml_file
    # Electric strip heating with COP = 1.0
    heating_systems_values = [{ :id => "HeatingSystem",
                                :heating_system_type => "ElectricResistance",
                                :heating_system_fuel => "electricity",
                                :heating_capacity => 60000,
                                :heating_efficiency_percent => 1,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    # Gas furnace with AFUE = 95%
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.95,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 78%
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.78,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Natural gas furnace with AFUE = 96%
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.96,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 78%; 0.0005 kW/cfm
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 56100,
                                :heating_efficiency_afue => 0.78,
                                :fraction_heat_load_served => 1,
                                :electric_auxiliary_energy => 1040 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml'].include? hpxml_file
    # Gas Furnace; 56.1 kBtu/h; AFUE = 90%; 0.000375 kW/cfm
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 56100,
                                :heating_efficiency_afue => 0.9,
                                :fraction_heat_load_served => 1,
                                :electric_auxiliary_energy => 780 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    # Electric Furnace; 56.1 kBtu/h; COP =1.0
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "electricity",
                                :heating_capacity => 56100,
                                :heating_efficiency_afue => 1,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    # Gas Furnace; 46.6 kBtu/h
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 46600,
                                :heating_efficiency_afue => 0.78,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    # Change to 56.0 kBtu/h
    heating_systems_values[0][:heating_capacity] = 56000
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml'].include? hpxml_file
    # Change to 49.0 kBtu/h
    heating_systems_values[0][:heating_capacity] = 49000
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml'].include? hpxml_file
    # Change to 61.0 kBtu/h
    heating_systems_values[0][:heating_capacity] = 61000
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Heating: gas furnace AFUE = 80%
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-07.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-07.xml'].include? hpxml_file
    # High-efficiency gas furnace with AFUE = 96%
    heating_systems_values[0][:heating_efficiency_afue] = 0.96
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    # Boiler heating system with 80% AFUE and fuel oil
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Boiler",
                                :heating_system_fuel => "fuel oil",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 1 }]
  elsif ['NASEO_Technical_Exercises/NASEO-20.xml'].include? hpxml_file
    # Wall furnace heating system with 80% AFUE and propane
    heating_systems_values = [{ :id => "HeatingSystem",
                                :heating_system_type => "WallFurnace",
                                :heating_system_fuel => "propane",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 1 }]
  elsif ['NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    # Stove heating system with 60% efficiency and natural gas
    heating_systems_values = [{ :id => "HeatingSystem",
                                :heating_system_type => "Stove",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_percent => 0.6,
                                :fraction_heat_load_served => 1 }]
  end
  return heating_systems_values
end

def get_hpxml_file_cooling_systems_values(hpxml_file, cooling_systems_values)
  if ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml'].include? hpxml_file
    cooling_systems_values = []
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    # central air conditioner with SEER = 11.0
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 11 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml'].include? hpxml_file
    # Central air conditioner with SEER = 15.0
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 15 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml',
         'NASEO_Technical_Exercises/NASEO-07.xml',
         'NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    # Cooling system – electric A/C with SEER = 10.0
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    # Air cooled air conditioner; 38.3 kBtu/h; SEER = 10
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 38300,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1b.xml'].include? hpxml_file
    # Change to SEER = 13
    cooling_systems_values[0][:cooling_efficiency_seer] = 13
  elsif ['RESNET_Tests/4.5_DSE/HVAC3e.xml'].include? hpxml_file
    # Air Conditioner; 38.4 kBtu/h; SEER 10
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 38400,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml'].include? hpxml_file
    # Change to 49.9 kBtu/h
    cooling_systems_values[0][:cooling_capacity] = 49900
  elsif ['RESNET_Tests/4.5_DSE/HVAC3g.xml'].include? hpxml_file
    # Change to 42.2 kBtu/h
    cooling_systems_values[0][:cooling_capacity] = 42200
  elsif ['RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    # Change to 55.0 kBtu/h
    cooling_systems_values[0][:cooling_capacity] = 55000
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Cooling: Air conditioner SEER = 14
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 14 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Cooling: Air conditioner SEER = 13
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 13 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-14.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-14.xml'].include? hpxml_file
    # Change to high efficiency air conditioner SEER = 21
    cooling_systems_values[0][:cooling_efficiency_seer] = 21
  end
  return cooling_systems_values
end

def get_hpxml_file_heat_pumps_values(hpxml_file, heat_pumps_values)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml',
      'NASEO_Technical_Exercises/NASEO-07.xml',
      'NASEO_Technical_Exercises/NASEO-08.xml',
      'NASEO_Technical_Exercises/NASEO-20.xml',
      'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    heat_pumps_values = []
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Electric heat pump with HSPF = 7.5 and SEER = 12.0
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 7.5,
                           :cooling_efficiency_seer => 12 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # TODO: Update this to be HP + AC
    # Heating system – electric HP with HSPF = 6.8
    # Cooling system – electric A/C with SEER
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 6.8,
                           :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml'].include? hpxml_file
    # TODO: Update this to be HP + AC
    # Change to a high efficiency HP with HSPF = 9.85
    heat_pumps_values[0][:heating_efficiency_hspf] = 9.85
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml'].include? hpxml_file
    # Air Source Heat Pump; 56.1 kBtu/h; HSPF = 6.8
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 56100,
                           :backup_heating_fuel => nil,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 0,
                           :heating_efficiency_hspf => 6.8,
                           :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include? hpxml_file
    # Air Source Heat Pump; 56.1 kBtu/h; HSPF = 9.85
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 56100,
                           :backup_heating_fuel => nil,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 0,
                           :heating_efficiency_hspf => 9.85,
                           :cooling_efficiency_seer => 13 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=14, HSPF = 8.2
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => nil,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 8.2,
                           :cooling_efficiency_seer => 14 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=14, HSPF = 12.0
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 12,
                           :cooling_efficiency_seer => 14 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=13, HSPF = 8.2
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 8.2,
                           :cooling_efficiency_seer => 13 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml'].include? hpxml_file
    # Heat pump HVAC system with SEER=13, HSPF = 12.0
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 12,
                           :cooling_efficiency_seer => 13 }]
  elsif ['NASEO_Technical_Exercises/NASEO-18.xml'].include? hpxml_file
    # Ground source heat pump system with EER 20.2 and COP 4.2
    heat_pumps_values = [{ :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "ground-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_cop => 4.2,
                           :cooling_efficiency_eer => 20.2 }]
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml'].include? hpxml_file
    # Ductless mini-split heat pump system with SEER 23 and HSPF 10.5
    heat_pumps_values = [{ :id => "HeatPump",
                           :heat_pump_type => "mini-split",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 100000,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 10.5,
                           :cooling_efficiency_seer => 23 }]
  end
  return heat_pumps_values
end

def get_hpxml_file_hvac_control_values(hpxml_file, hvac_control_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    hvac_control_values = { :id => "HVACControl",
                            :control_type => "manual thermostat" }
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    hvac_control_values = {}
  elsif ['NASEO_Technical_Exercises/NASEO-06.xml'].include? hpxml_file
    # Programmable thermostat
    hvac_control_values[:control_type] = "programmable thermostat"
  end
  return hvac_control_values
end

def get_hpxml_file_hvac_distributions_values(hpxml_file, hvac_distributions_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVACDistribution",
                                   :distribution_system_type => "AirDistribution" }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVACDistribution",
                                   :distribution_system_type => "DSE",
                                   :annual_cooling_dse => 1 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVACDistribution",
                                   :distribution_system_type => "DSE",
                                   :annual_heating_dse => 1 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2d.xml',
         'RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVACDistribution",
                                   :distribution_system_type => "DSE",
                                   :annual_heating_dse => 1,
                                   :annual_cooling_dse => 1 }]
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml',
         'NASEO_Technical_Exercises/NASEO-20.xml',
         'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    hvac_distributions_values = []
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVACDistribution",
                                   :distribution_system_type => "HydronicDistribution" },
                                 { :id => "HVACDistribution2",
                                   :distribution_system_type => "AirDistribution" }]
  end
  return hvac_distributions_values
end

def get_hpxml_file_duct_leakage_measurements_values(hpxml_file, duct_leakage_measurements_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
      'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-12.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-12.xml'].include? hpxml_file
    # No leakage
    duct_leakage_measurements_values = [[{ :duct_type => "supply",
                                           :duct_leakage_value => 0 },
                                         { :duct_type => "return",
                                           :duct_leakage_value => 0 }]]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml',
         'RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    # Supply and return duct leakage = 125 cfm each
    for i in 0..duct_leakage_measurements_values[0].size - 1
      duct_leakage_measurements_values[0][i][:duct_leakage_value] = 125
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml'].include? hpxml_file
    # 4 cfm25 per 100 ft2 CFA with 50% return side and 50% supply side leakage
    for i in 0..duct_leakage_measurements_values[0].size - 1
      duct_leakage_measurements_values[0][i][:duct_leakage_value] = 30.78
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml'].include? hpxml_file
    # 123 cfm duct leakage with 50% in supply and 50% in return
    for i in 0..duct_leakage_measurements_values[0].size - 1
      duct_leakage_measurements_values[0][i][:duct_leakage_value] = 61.5
    end
  elsif ['NASEO_Technical_Exercises/NASEO-01.xml'].include? hpxml_file
    # Leakage of 60 cfm25 with 50% return side and 50% supply side leakage
    for i in 0..duct_leakage_measurements_values[0].size - 1
      duct_leakage_measurements_values[0][i][:duct_leakage_value] = 30
    end
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml',
         'NASEO_Technical_Exercises/NASEO-20.xml',
         'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    duct_leakage_measurements_values = [[]]
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    duct_leakage_measurements_values.unshift([])
  end
  return duct_leakage_measurements_values
end

def get_hpxml_file_ducts_values(hpxml_file, ducts_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
      'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
      'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
      'RESNET_Tests/4.5_DSE/HVAC3a.xml',
      'RESNET_Tests/4.5_DSE/HVAC3e.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
      'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Supply duct area = 308 ft2; Return duct area = 77 ft2
    # Duct R-val = 0
    # Duct Location = 100% conditioned
    ducts_values = [[{ :duct_type => "supply",
                       :duct_insulation_r_value => 0,
                       :duct_location => "living space",
                       :duct_surface_area => 308 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "living space",
                       :duct_surface_area => 77 }]]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    # Change to Duct Location = 100% in basement
    for i in 0..ducts_values[0].size - 1
      ducts_values[0][i][:duct_location] = "basement - unconditioned"
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml'].include? hpxml_file
    # Change to Duct Location = 100% in attic
    for i in 0..ducts_values[0].size - 1
      ducts_values[0][i][:duct_location] = "attic - vented"
    end
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml',
         'RESNET_Tests/4.5_DSE/HVAC3g.xml'].include? hpxml_file
    # Change to Duct R-val = 6
    for i in 0..ducts_values[0].size - 1
      ducts_values[0][i][:duct_insulation_r_value] = 6
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 100% in conditioned space, including air handler; R-6 duct insulation
    ducts_values = [[{ :duct_type => "supply",
                       :duct_insulation_r_value => 6,
                       :duct_location => "living space",
                       :duct_surface_area => 308 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 6,
                       :duct_location => "living space",
                       :duct_surface_area => 77 }]]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml'].include? hpxml_file
    # Change to crawlspace
    for i in 0..ducts_values[0].size - 1
      ducts_values[0][i][:duct_location] = "crawlspace - vented"
    end
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml'].include? hpxml_file
    # Change to 385 ft2 supply ducts and 77 ft2 return ducts in ambient temperature environment with no solar radiation
    for i in 0..ducts_values[0].size - 1
      ducts_values[0][i][:duct_insulation_r_value] = 6
      ducts_values[0][i][:duct_location] = "outside"
    end
    ducts_values[0][0][:duct_surface_area] = 385
    ducts_values[0][1][:duct_surface_area] = 77
  elsif ['NASEO_Technical_Exercises/NASEO-01.xml'].include? hpxml_file
    # Air distribution system in the attic with R-6 duct insulation for 300 ft2 of supply duct area and 75 ft2 of return duct area
    for i in 0..ducts_values[0].size - 1
      ducts_values[0][i][:duct_insulation_r_value] = 6
      ducts_values[0][i][:duct_location] = "attic - vented"
    end
    ducts_values[0][0][:duct_surface_area] = 300
    ducts_values[0][1][:duct_surface_area] = 75
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml',
         'NASEO_Technical_Exercises/NASEO-20.xml',
         'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    # No ducts
    ducts_values = [[]]
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    ducts_values.unshift([])
  end
  return ducts_values
end

def get_hpxml_file_ventilation_fan_values(hpxml_file, ventilation_fans_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    ventilation_fans_values = []
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    # Exhaust-only whole-dwelling mechanical ventilation
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "exhaust only",
                                 :tested_flow_rate => 56.2,
                                 :hours_in_operation => 24,
                                 :fan_power => 14.7 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation without energy recovery
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "balanced",
                                 :tested_flow_rate => 56.2,
                                 :hours_in_operation => 24,
                                 :fan_power => 14.7 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    # Balanced whole-dwelling mechanical ventilation with a 60% heat recovery system
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "heat recovery ventilator",
                                 :tested_flow_rate => 56.2,
                                 :hours_in_operation => 24,
                                 :sensible_recovery_efficiency => 0.6,
                                 :fan_power => 14.7 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # Exhaust fan = 58.7 cfm, continuous; Fan power = 14.7 watts
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "exhaust only",
                                 :tested_flow_rate => 58.7,
                                 :hours_in_operation => 24,
                                 :fan_power => 14.7 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 51.2 cfm continuous with fan power = 12.8 watts
    ventilation_fans_values[0][:tested_flow_rate] = 51.2
    ventilation_fans_values[0][:fan_power] = 12.8
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 66.2 cfm continuous with fan power = 16.6 watts
    ventilation_fans_values[0][:tested_flow_rate] = 66.2
    ventilation_fans_values[0][:fan_power] = 16.6
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-15.xml'].include? hpxml_file
    # Change to CFIS system at flow rate of 176.1 cfm and 33.33% duty cycle (8 hours per day)
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "central fan integrated supply",
                                 :tested_flow_rate => 176.1,
                                 :hours_in_operation => 8,
                                 :fan_power => 14.7,
                                 :distribution_system_idref => "HVACDistribution" }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml'].include? hpxml_file
    # Exhaust fan = 56.2 cfm, continuous; Fan power = 14.0 watts
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "exhaust only",
                                 :tested_flow_rate => 56.2,
                                 :hours_in_operation => 24,
                                 :fan_power => 14 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 48.7 cfm continuous with fan power = 12.2 watts
    ventilation_fans_values[0][:tested_flow_rate] = 48.7
    ventilation_fans_values[0][:fan_power] = 12.2
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml'].include? hpxml_file
    # Change to exhaust mechanical ventilation = 63.7 cfm continuous with fan power = 15.9 watts
    ventilation_fans_values[0][:tested_flow_rate] = 63.7
    ventilation_fans_values[0][:fan_power] = 15.9
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-15.xml'].include? hpxml_file
    # Change to CFIS system at flow rate of 168.6 cfm and 33.33% duty cycle (8 hours per day)
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "central fan integrated supply",
                                 :tested_flow_rate => 168.6,
                                 :hours_in_operation => 8,
                                 :fan_power => 14,
                                 :distribution_system_idref => "HVACDistribution" }]
  elsif ['NASEO_Technical_Exercises/NASEO-04.xml'].include? hpxml_file
    # Exhaust mechanical ventilation system with 50 cfm and 15 watts
    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => "exhaust only",
                                 :tested_flow_rate => 50,
                                 :hours_in_operation => 24,
                                 :fan_power => 15 }]
  end
  return ventilation_fans_values
end

def get_hpxml_file_water_heating_system_values(hpxml_file, water_heating_systems_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    water_heating_systems_values = {}
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # 40 gal electric with EF = 0.88
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 15355,
                                      :energy_factor => 0.88 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml'].include? hpxml_file
    # Tankless natural gas with EF = 0.82
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "instantaneous water heater",
                                      :location => "living space",
                                      :fraction_dhw_load_served => 1,
                                      :energy_factor => 0.82 }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.56; RE = 0.78; conditioned space
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 40000,
                                      :energy_factor => 0.56,
                                      :recovery_efficiency => 0.78 }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    # 40 gallon storage; gas; EF = 0.62; RE = 0.78; conditioned space
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 40000,
                                      :energy_factor => 0.62,
                                      :recovery_efficiency => 0.78 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-08.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-08.xml'].include? hpxml_file
    # Tankless gas water heater with EF=0.83
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "instantaneous water heater",
                                      :location => "living space",
                                      :fraction_dhw_load_served => 1,
                                      :energy_factor => 0.83 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-12.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-12.xml'].include? hpxml_file
    # Standard electric water heater EF = 0.95, RE = 0.98
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 15355,
                                      :energy_factor => 0.95,
                                      :recovery_efficiency => 0.98 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-13.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-13.xml'].include? hpxml_file
    # Electric heat pump water heater EF = 2.5
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "heat pump water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :energy_factor => 2.5 }]
  end
  return water_heating_systems_values
end

def get_hpxml_file_hot_water_distribution_values(hpxml_file, hot_water_distribution_values, building_construction_values, foundation_walls_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    hot_water_distribution_values = {}
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard
    hot_water_distribution_values = { :id => "HotWaterDstribution",
                                      :system_type => "Standard",
                                      :pipe_r_value => 0.0 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml'].include? hpxml_file
    # Change to recirculation: loop length = 156.92 ft.; branch piping length = 10 ft.; pump power = 50 watts; R-3 piping insulation; and control = none
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "no control"
    hot_water_distribution_values[:recirculation_piping_length] = 156.92
    hot_water_distribution_values[:recirculation_branch_piping_length] = 10
    hot_water_distribution_values[:recirculation_pump_power] = 50
    hot_water_distribution_values[:pipe_r_value] = 3
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml'].include? hpxml_file
    # Change to recirculation: Control = none; 50 W pump; Loop length is same as reference loop length; Branch length is 10 ft; All hot water pipes insulated to R-3
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "no control"
    hot_water_distribution_values[:recirculation_branch_piping_length] = 10
    hot_water_distribution_values[:recirculation_pump_power] = 50
    hot_water_distribution_values[:pipe_r_value] = 3
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-06.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-17.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-17.xml'].include? hpxml_file
    # Change to recirculation: Control = manual
    hot_water_distribution_values[:recirculation_control_type] = "manual demand control"
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-07.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-07.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-18.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-18.xml',
         'NASEO_Technical_Exercises/NASEO-03.xml'].include? hpxml_file
    # Change to drain Water Heat Recovery (DWHR) with all facilities connected; equal flow; DWHR eff = 54%
    hot_water_distribution_values[:dwhr_facilities_connected] = "all"
    hot_water_distribution_values[:dwhr_equal_flow] = true
    hot_water_distribution_values[:dwhr_efficiency] = 0.54
  elsif ['NASEO_Technical_Exercises/NASEO-02.xml'].include? hpxml_file
    # Change to recirculation: loop length = 150 ft.; branch piping length = 10 ft.; pump power = 50 watts; R-3 piping insulation; and control = none
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "no control"
    hot_water_distribution_values[:recirculation_piping_length] = 150
    hot_water_distribution_values[:recirculation_branch_piping_length] = 10
    hot_water_distribution_values[:recirculation_pump_power] = 50
    hot_water_distribution_values[:pipe_r_value] = 3
  end

  has_uncond_bsmnt = false
  foundation_walls_values.each do |foundation_wall_values|
    next unless [foundation_wall_values[:interior_adjacent_to], foundation_wall_values[:exterior_adjacent_to]].include? "basement - unconditioned"

    has_uncond_bsmnt = true
  end
  cfa = building_construction_values[:conditioned_floor_area]
  ncfl = building_construction_values[:number_of_conditioned_floors]
  piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)

  if hot_water_distribution_values[:system_type] == "Standard" and hot_water_distribution_values[:standard_piping_length].nil?
    hot_water_distribution_values[:standard_piping_length] = piping_length.round(2)
  elsif hot_water_distribution_values[:system_type] == "Recirculation" and hot_water_distribution_values[:recirculation_piping_length].nil?
    hot_water_distribution_values[:recirculation_piping_length] = HotWaterAndAppliances.get_default_recirc_loop_length(piping_length).round(2)
  end
  return hot_water_distribution_values
end

def get_hpxml_file_water_fixtures_values(hpxml_file, water_fixtures_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    water_fixtures_values = []
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard
    water_fixtures_values = [{ :id => "WaterFixture",
                               :water_fixture_type => "shower head",
                               :low_flow => false },
                             { :id => "WaterFixture2",
                               :water_fixture_type => "faucet",
                               :low_flow => false }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-04.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-04.xml'].include? hpxml_file
    # Low-flow
    water_fixtures_values = [{ :id => "WaterFixture",
                               :water_fixture_type => "shower head",
                               :low_flow => true },
                             { :id => "WaterFixture2",
                               :water_fixture_type => "faucet",
                               :low_flow => true }]
  end
  return water_fixtures_values
end

def get_hpxml_file_pv_system_values(hpxml_file, pv_systems_values)
  return pv_systems_values
end

def get_hpxml_file_clothes_washer_values(hpxml_file, clothes_washer_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    clothes_washer_values = {}
  elsif ['NASEO_Technical_Exercises/NASEO-09.xml',
         'NASEO_Technical_Exercises/NASEO-09b.xml'].include? hpxml_file
    # 3.2 IMEF
    clothes_washer_values = { :id => "ClothesWasher",
                              :location => "living space",
                              :rated_annual_kwh => 150,
                              :label_electric_rate => 0.11,
                              :label_gas_rate => 1.1,
                              :label_annual_gas_cost => 12,
                              :capacity => 3.3 }
    if hpxml_file == 'NASEO_Technical_Exercises/NASEO-09.xml'
      clothes_washer_values[:integrated_modified_energy_factor] = 2.2
    elsif hpxml_file == 'NASEO_Technical_Exercises/NASEO-09b.xml'
      clothes_washer_values[:modified_energy_factor] = 2.593
    end
  else
    # Standard
    clothes_washer_values = { :id => "ClothesWasher",
                              :location => "living space",
                              :integrated_modified_energy_factor => HotWaterAndAppliances.get_clothes_washer_reference_imef(),
                              :rated_annual_kwh => HotWaterAndAppliances.get_clothes_washer_reference_ler(),
                              :label_electric_rate => HotWaterAndAppliances.get_clothes_washer_reference_elec_rate(),
                              :label_gas_rate => HotWaterAndAppliances.get_clothes_washer_reference_gas_rate(),
                              :label_annual_gas_cost => HotWaterAndAppliances.get_clothes_washer_reference_agc(),
                              :capacity => HotWaterAndAppliances.get_clothes_washer_reference_cap() }
  end
  return clothes_washer_values
end

def get_hpxml_file_clothes_dryer_values(hpxml_file, clothes_dryer_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    clothes_dryer_values = {}
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Standard gas
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :fuel_type => "natural gas",
                             :control_type => HotWaterAndAppliances.get_clothes_dryer_reference_control(),
                             :combined_energy_factor => HotWaterAndAppliances.get_clothes_dryer_reference_cef(Constants.FuelTypeGas) }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard electric
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :fuel_type => "electricity",
                             :control_type => HotWaterAndAppliances.get_clothes_dryer_reference_control(),
                             :combined_energy_factor => HotWaterAndAppliances.get_clothes_dryer_reference_cef(Constants.FuelTypeElectric) }
  elsif ['NASEO_Technical_Exercises/NASEO-09.xml',
         'NASEO_Technical_Exercises/NASEO-09b.xml'].include? hpxml_file
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :fuel_type => "natural gas",
                             :control_type => "moisture" }
    # 2.3 CEF electric
    if hpxml_file == 'NASEO_Technical_Exercises/NASEO-09.xml'
      clothes_dryer_values[:combined_energy_factor] = 2.3
    elsif hpxml_file == 'NASEO_Technical_Exercises/NASEO-09b.xml'
      clothes_dryer_values[:energy_factor] = 2.645
    end
  end
  return clothes_dryer_values
end

def get_hpxml_file_dishwasher_values(hpxml_file, dishwasher_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    dishwasher_values = {}
  elsif ['NASEO_Technical_Exercises/NASEO-10.xml',
         'NASEO_Technical_Exercises/NASEO-10b.xml'].include? hpxml_file
    # EF 0.5
    dishwasher_values = { :id => "Dishwasher",
                          :place_setting_capacity => 12 }
    if hpxml_file == 'NASEO_Technical_Exercises/NASEO-10.xml'
      dishwasher_values[:energy_factor] = 0.5
    elsif hpxml_file == 'NASEO_Technical_Exercises/NASEO-10b.xml'
      dishwasher_values[:rated_annual_kwh] = 430
    end
  else
    # Standard
    dishwasher_values = { :id => "Dishwasher",
                          :place_setting_capacity => 12,
                          :energy_factor => HotWaterAndAppliances.get_dishwasher_reference_ef() }
  end
  return dishwasher_values
end

def get_hpxml_file_refrigerator_values(hpxml_file, refrigerator_values, building_construction_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    refrigerator_values = {}
  elsif ['NASEO_Technical_Exercises/NASEO-11.xml'].include? hpxml_file
    # 614 kWh
    refrigerator_values = { :id => "Refrigerator",
                            :location => "living space",
                            :rated_annual_kwh => 614 }
  else
    # Standard
    rated_annual_kwh = HotWaterAndAppliances.get_refrigerator_reference_annual_kwh(building_construction_values[:number_of_bedrooms])
    refrigerator_values = { :id => "Refrigerator",
                            :location => "living space",
                            :rated_annual_kwh => rated_annual_kwh }
  end
  return refrigerator_values
end

def get_hpxml_file_cooking_range_values(hpxml_file, cooking_range_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    cooking_range_values = {}
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    # Standard gas
    cooking_range_values = { :id => "Range",
                             :fuel_type => "natural gas",
                             :is_induction => HotWaterAndAppliances.get_range_oven_reference_is_convection() }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml',
         'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml',
         'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml',
         'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
         'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    # Standard electric
    cooking_range_values = { :id => "Range",
                             :fuel_type => "electricity",
                             :is_induction => HotWaterAndAppliances.get_range_oven_reference_is_convection() }
  elsif ['NASEO_Technical_Exercises/NASEO-12.xml'].include? hpxml_file
    # Induction
    cooking_range_values = { :id => "Range",
                             :fuel_type => "electricity",
                             :is_induction => true }
  end
  return cooking_range_values
end

def get_hpxml_file_oven_values(hpxml_file, oven_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    oven_values = {}
  elsif ['NASEO_Technical_Exercises/NASEO-12.xml'].include? hpxml_file
    # Convection
    oven_values = { :id => "Oven",
                    :is_convection => true }
  else
    # Standard
    oven_values = { :id => "Oven",
                    :is_convection => HotWaterAndAppliances.get_range_oven_reference_is_induction() }
  end
  return oven_values
end

def get_hpxml_file_lighting_values(hpxml_file, lighting_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    lighting_values = {}
  elsif ['NASEO_Technical_Exercises/NASEO-05.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-21.xml',
         'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-21.xml'].include? hpxml_file
    # 75% high efficiency interior and exterior
    lighting_values = { :fraction_tier_i_interior => 0.75,
                        :fraction_tier_i_exterior => 0.75,
                        :fraction_tier_i_garage => 0.0,
                        :fraction_tier_ii_interior => 0.0,
                        :fraction_tier_ii_exterior => 0.0,
                        :fraction_tier_ii_garage => 0.0 }
  else
    # ERI Reference
    fFI_int, fFI_ext, fFI_grg, fFII_int, fFII_ext, fFII_grg = Lighting.get_reference_fractions()
    lighting_values = { :fraction_tier_i_interior => fFI_int,
                        :fraction_tier_i_exterior => fFI_ext,
                        :fraction_tier_i_garage => fFI_grg,
                        :fraction_tier_ii_interior => fFII_int,
                        :fraction_tier_ii_exterior => fFII_ext,
                        :fraction_tier_ii_garage => fFII_grg }
  end
  return lighting_values
end

def get_hpxml_file_ceiling_fan_values(hpxml_file, ceiling_fans_values)
  return ceiling_fans_values
end

def get_hpxml_file_plug_loads_values(hpxml_file, plug_loads_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    plug_loads_values = [{ :id => "PlugLoadMisc",
                           :plug_load_type => "other",
                           :kWh_per_year => 7302,
                           :frac_sensible => 0.82,
                           :frac_latent => 0.18 }]
    if ['RESNET_Tests/4.1_Standard_140/L170AC.xml',
        'RESNET_Tests/4.1_Standard_140/L170AL.xml'].include? hpxml_file
      plug_loads_values[0][:kWh_per_year] = 0
    end
  else
    plug_loads_values = []
  end
  return plug_loads_values
end

def get_hpxml_file_misc_load_schedule_values(hpxml_file, misc_load_schedule_values)
  if hpxml_file.include? 'RESNET_Tests/4.1_Standard_140' or
     hpxml_file.include? 'RESNET_Tests/4.4_HVAC' or
     hpxml_file.include? 'RESNET_Tests/4.5_DSE'
    # Base configuration
    misc_load_schedule_values = { :weekday_fractions => "0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066",
                                  :weekend_fractions => "0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066",
                                  :monthly_multipliers => "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0" }
  else
    misc_load_schedule_values = {}
  end
  return misc_load_schedule_values
end

def copy_sample_files
  # Copy sample files from HPXMLtoOpenStudio repo
  puts "Copying sample files..."
  FileUtils.rm_f(Dir.glob("workflow/sample_files/*.xml*"))
  FileUtils.rm_f(Dir.glob("workflow/sample_files/invalid_files/*.xml*"))
  FileUtils.cp(Dir.glob("measures/HPXMLtoOpenStudio/tests/*.xml*"), "workflow/sample_files")
  FileUtils.cp(Dir.glob("measures/HPXMLtoOpenStudio/tests/invalid_files/*.xml*"), "workflow/sample_files/invalid_files")

  # Remove files we're not interested in
  exclude_list = ['invalid_files/bad-site-neighbor-azimuth.xml',
                  'invalid_files/cfis-with-hydronic-distribution.xml',
                  'invalid_files/clothes-washer-location.xml',
                  'invalid_files/clothes-washer-location-other.xml',
                  'invalid_files/clothes-dryer-location.xml',
                  'invalid_files/clothes-dryer-location-other.xml',
                  'invalid_files/duct-location.xml',
                  'invalid_files/duct-location-other.xml',
                  'invalid_files/hvac-distribution-multiple-attached-cooling.xml',
                  'invalid_files/hvac-distribution-multiple-attached-heating.xml',
                  'invalid_files/missing-surfaces.xml',
                  'invalid_files/net-area-negative-roof.xml',
                  'invalid_files/net-area-negative-wall.xml',
                  'invalid_files/refrigerator-location.xml',
                  'invalid_files/refrigerator-location-other.xml',
                  'invalid_files/unattached-cfis.xml',
                  'invalid_files/unattached-door.xml',
                  'invalid_files/unattached-hvac-distribution.xml',
                  'invalid_files/unattached-skylight.xml',
                  'invalid_files/unattached-window.xml',
                  'invalid_files/water-heater-location.xml',
                  'invalid_files/water-heater-location-other.xml',
                  'invalid_files/two-repeating-idref-dhw-indirect.xml',
                  'invalid_files/invalid-idref-dhw-indirect.xml',
                  'base-appliances-none.xml',
                  'base-dhw-combi-tankless-outside.xml',
                  'base-dhw-indirect-outside.xml',
                  'base-dhw-jacket-electric.xml',
                  'base-dhw-jacket-hpwh.xml',
                  'base-dhw-jacket-indirect.xml',
                  'base-dhw-tank-gas-outside.xml',
                  'base-dhw-tank-heat-pump-outside.xml',
                  'base-dhw-tankless-electric-outside.xml',
                  'base-enclosure-no-natural-ventilation.xml',
                  'base-enclosure-windows-interior-shading.xml',
                  'base-foundation-multiple-slab.xml',
                  'base-hvac-boiler-gas-only-no-eae.xml',
                  'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
                  'base-hvac-furnace-gas-only-no-eae.xml',
                  'base-hvac-ideal-air.xml',
                  'base-hvac-mini-split-heat-pump-ductless-no-backup.xml',
                  'base-hvac-setpoints.xml',
                  'base-infiltration-ach-natural.xml',
                  'base-mechvent-exhaust-rated-flow-rate.xml',
                  'base-mechvent-erv-asre.xml',
                  'base-mechvent-erv-atre.xml',
                  'base-misc-lighting-none.xml',
                  'base-misc-loads-detailed.xml',
                  'base-misc-number-of-occupants.xml',
                  'base-site-neighbors.xml']
  exclude_list.each do |exclude_file|
    if File.exists? "workflow/sample_files/#{exclude_file}"
      FileUtils.rm_f("workflow/sample_files/#{exclude_file}")
    else
      puts "Warning: Excluded file workflow/sample_files/#{exclude_file} not found."
    end
  end
end
