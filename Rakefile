require 'fileutils'

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'
require_relative "measures/HPXMLtoOpenStudio/resources/hpxml"

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
  command = "\"#{cli_path}\" --no-ssl energy_rating_index.rb -x sample_files/valid.xml"
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

desc 'process weather'
task :process_weather do
  require 'openstudio'
  require_relative 'measures/HPXMLtoOpenStudio/resources/weather'

  # Download all weather files
  Dir.chdir('workflow')
  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" --no-ssl energy_rating_index.rb --download-weather"
  system(command)
  Dir.chdir('../weather')

  # Process all epw files through weather.rb and serialize objects
  # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  Dir["*.epw"].each do |epw|
    puts epw
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    if weather.error? or weather.data.WSF.nil?
      fail "Error."
    end

    File.open(epw.gsub(".epw", ".cache"), "wb") do |file|
      Marshal.dump(weather, file)
    end
  end
  puts "Done."
end

desc 'update all measures'
task :update_measures do
  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  create_hpxmls
end

def create_hpxmls
  puts "Generating HPXML files..."

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
    'RESNET_Tests/4.5_DSE/HVAC3c.xml' => 'RESNET_Tests/4.5_DSE/HVAC3a.xml',
    'RESNET_Tests/4.5_DSE/HVAC3d.xml' => 'RESNET_Tests/4.5_DSE/HVAC3a.xml',
    'RESNET_Tests/4.5_DSE/HVAC3e.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/4.5_DSE/HVAC3f.xml' => 'RESNET_Tests/4.5_DSE/HVAC3e.xml',
    'RESNET_Tests/4.5_DSE/HVAC3g.xml' => 'RESNET_Tests/4.5_DSE/HVAC3e.xml',
    'RESNET_Tests/4.5_DSE/HVAC3h.xml' => 'RESNET_Tests/4.5_DSE/HVAC3e.xml',
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
    'RESNET_Tests/Other_HERS_Method_IAF/L100A-01.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml',
    'RESNET_Tests/Other_HERS_Method_IAF/L100A-02.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-02.xml',
    'RESNET_Tests/Other_HERS_Method_IAF/L100A-03.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml',
    'RESNET_Tests/Other_HERS_Method_IAF/L100A-04.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-04.xml',
    'RESNET_Tests/Other_HERS_Method_IAF/L100A-05.xml' => 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml' => 'RESNET_Tests/4.1_Standard_140/L100AC.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-07.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-08.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-12.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-13.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
    'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-14.xml' => 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml',
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
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml.skip' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml.skip',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-09.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-10.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-11.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-12.xml.skip' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml.skip',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml' => 'RESNET_Tests/4.1_Standard_140/L100AL.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-06.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml.skip' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml.skip',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-09.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-10.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-11.xml' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml',
    'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-12.xml.skip' => 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml.skip',
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

  hpxmls_files.each do |derivative, parent|
    puts "Generating #{derivative}..."

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
    building_occupancys_values = []
    building_construction_values = {}
    climate_and_risk_zones_values = {}
    air_infiltration_measurement_values = {}
    attics_values = []
    attics_roofs_values = []
    attics_floors_values = []
    attics_walls_values = []
    foundations_values = []
    foundations_framefloors_values = []
    foundations_walls_values = []
    foundations_slabs_values = []
    rim_joists_values = []
    walls_values = []
    windows_values = []
    skylights_values = []
    doors_values = []
    heating_systems_values = []
    cooling_systems_values = []
    heat_pumps_values = []
    hvac_controls_values = []
    hvac_distributions_values = []
    duct_leakage_measurements_values = []
    ducts_values = []
    ventilation_fans_values = []
    water_heating_systems_values = []
    hot_water_distributions_values = []
    water_fixtures_values = []
    pv_systems_values = []
    clothes_washers_values = []
    clothes_dryers_values = []
    dishwashers_values = []
    refrigerators_values = []
    cooking_ranges_values = []
    ovens_values = []
    lightings_values = []
    ceiling_fans_values = []
    plug_loads_values = []
    misc_loads_schedules_values = []
    hpxml_files.each do |hpxml_file|
      hpxml_values = get_hpxml_file_hpxml_values(hpxml_file, hpxml_values)
      site_values = get_hpxml_file_site_values(hpxml_file, site_values)
      building_occupancys_values = get_hpxml_file_building_occupancy_values(hpxml_file, building_occupancys_values)
      building_construction_values = get_hpxml_file_building_construction_values(hpxml_file, building_construction_values)
      climate_and_risk_zones_values = get_hpxml_file_climate_and_risk_zones_values(hpxml_file, climate_and_risk_zones_values)
      air_infiltration_measurement_values = get_hpxml_file_air_infiltration_measurement_values(hpxml_file, air_infiltration_measurement_values)
      attics_values = get_hpxml_file_attic_values(hpxml_file, attics_values)
      attics_roofs_values = get_hpxml_file_attic_roofs_values(hpxml_file, attics_roofs_values)
      attics_floors_values = get_hpxml_file_attic_floors_values(hpxml_file, attics_floors_values)
      attics_walls_values = get_hpxml_file_attic_walls_values(hpxml_file, attics_walls_values)
      foundations_values = get_hpxml_file_foundation_values(hpxml_file, foundations_values)
      foundations_framefloors_values = get_hpxml_file_frame_floor_values(hpxml_file, foundations_framefloors_values)
      foundations_walls_values = get_hpxml_file_foundation_walls_values(hpxml_file, foundations_walls_values)
      foundations_slabs_values = get_hpxml_file_slab_values(hpxml_file, foundations_slabs_values)
      rim_joists_values = get_hpxml_file_rim_joists_values(hpxml_file, rim_joists_values)
      walls_values = get_hpxml_file_walls_values(hpxml_file, walls_values)
      windows_values = get_hpxml_file_windows_values(hpxml_file, windows_values)
      doors_values = get_hpxml_file_doors_values(hpxml_file, doors_values)
      heating_systems_values = get_hpxml_file_heating_systems_values(hpxml_file, heating_systems_values)
      cooling_systems_values = get_hpxml_file_cooling_systems_values(hpxml_file, cooling_systems_values)
      heat_pumps_values = get_hpxml_file_heat_pumps_values(hpxml_file, heat_pumps_values)
      hvac_controls_values = get_hpxml_file_hvac_control_values(hpxml_file, hvac_controls_values)
      hvac_distributions_values = get_hpxml_file_hvac_distribution_values(hpxml_file, hvac_distributions_values)
      duct_leakage_measurements_values = get_hpxml_file_duct_leakage_measurements_values(hpxml_file, duct_leakage_measurements_values)
      ducts_values = get_hpxml_file_ducts_values(hpxml_file, ducts_values)
      ventilation_fans_values = get_hpxml_file_ventilation_fan_values(hpxml_file, ventilation_fans_values)
      water_heating_systems_values = get_hpxml_file_water_heating_system_values(hpxml_file, water_heating_systems_values)
      hot_water_distributions_values = get_hpxml_file_hot_water_distribution_values(hpxml_file, hot_water_distributions_values)
      water_fixtures_values = get_hpxml_file_water_fixtures_values(hpxml_file, water_fixtures_values)
      clothes_washers_values = get_hpxml_file_clothes_washer_values(hpxml_file, clothes_washers_values)
      clothes_dryers_values = get_hpxml_file_clothes_dryer_values(hpxml_file, clothes_dryers_values)
      dishwashers_values = get_hpxml_file_dishwasher_values(hpxml_file, dishwashers_values)
      refrigerators_values = get_hpxml_file_refrigerator_values(hpxml_file, refrigerators_values)
      cooking_ranges_values = get_hpxml_file_cooking_range_values(hpxml_file, cooking_ranges_values)
      ovens_values = get_hpxml_file_oven_values(hpxml_file, ovens_values)
      lightings_values = get_hpxml_file_lighting_values(hpxml_file, lightings_values)
      plug_loads_values = get_hpxml_file_plug_load_values(hpxml_file, plug_loads_values)
      misc_loads_schedules_values = get_hpxml_file_misc_loads_schedule_values(hpxml_file, misc_loads_schedules_values)
    end

    hpxml_doc = HPXML.create_hpxml(**hpxml_values)
    hpxml = hpxml_doc.elements["HPXML"]

    if File.exists? File.join(tests_dir, derivative)
      old_hpxml_doc = XMLHelper.parse_file(File.join(tests_dir, derivative))
      created_date_and_time = HPXML.get_hpxml_values(hpxml: old_hpxml_doc.elements["HPXML"])[:created_date_and_time]
      hpxml.elements["XMLTransactionHeaderInformation/CreatedDateAndTime"].text = created_date_and_time
    end

    HPXML.add_site(hpxml: hpxml, **site_values) unless site_values.nil?
    building_occupancys_values.each do |building_occupancy_values|
      HPXML.add_building_occupancy(hpxml: hpxml, **building_occupancy_values)
    end
    HPXML.add_building_construction(hpxml: hpxml, **building_construction_values)
    HPXML.add_climate_and_risk_zones(hpxml: hpxml, **climate_and_risk_zones_values)
    HPXML.add_air_infiltration_measurement(hpxml: hpxml, **air_infiltration_measurement_values)
    attics_values.each_with_index do |attic_values, i|
      attic = HPXML.add_attic(hpxml: hpxml, **attic_values)
      attics_roofs_values[i].each do |attic_roof_values|
        HPXML.add_attic_roof(attic: attic, **attic_roof_values)
      end
      attics_floors_values[i].each do |attic_floor_values|
        HPXML.add_attic_floor(attic: attic, **attic_floor_values)
      end
      attics_walls_values[i].each do |attic_wall_values|
        HPXML.add_attic_wall(attic: attic, **attic_wall_values)
      end
    end
    foundations_values.each_with_index do |foundation_values, i|
      foundation = HPXML.add_foundation(hpxml: hpxml, **foundation_values)
      unless foundations_framefloors_values[i].nil?
        foundations_framefloors_values[i].each do |foundation_framefloor_values|
          HPXML.add_frame_floor(foundation: foundation, **foundation_framefloor_values)
        end
      end
      unless foundations_walls_values[i].nil?
        foundations_walls_values[i].each do |foundation_wall_values|
          HPXML.add_foundation_wall(foundation: foundation, **foundation_wall_values)
        end
      end
      unless foundations_slabs_values[i].nil?
        foundations_slabs_values[i].each do |foundation_slab_values|
          HPXML.add_slab(foundation: foundation, **foundation_slab_values)
        end
      end
    end
    rim_joists_values.each do |rim_joist_values|
      HPXML.add_rim_joist(hpxml: hpxml, **rim_joist_values)
    end
    walls_values.each do |wall_values|
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
    windows_values.each do |window_values|
      HPXML.add_window(hpxml: hpxml, **window_values)
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
    hvac_controls_values.each do |hvac_control_values|
      HPXML.add_hvac_control(hpxml: hpxml, **hvac_control_values)
    end
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
    hot_water_distributions_values.each do |hot_water_distribution_values|
      HPXML.add_hot_water_distribution(hpxml: hpxml, **hot_water_distribution_values)
    end
    water_fixtures_values.each do |water_fixture_values|
      HPXML.add_water_fixture(hpxml: hpxml, **water_fixture_values)
    end
    clothes_washers_values.each do |clothes_washer_values|
      HPXML.add_clothes_washer(hpxml: hpxml, **clothes_washer_values)
    end
    clothes_dryers_values.each do |clothes_dryer_values|
      HPXML.add_clothes_dryer(hpxml: hpxml, **clothes_dryer_values)
    end
    dishwashers_values.each do |dishwasher_values|
      HPXML.add_dishwasher(hpxml: hpxml, **dishwasher_values)
    end
    refrigerators_values.each do |refrigerator_values|
      HPXML.add_refrigerator(hpxml: hpxml, **refrigerator_values)
    end
    cooking_ranges_values.each do |cooking_range_values|
      HPXML.add_cooking_range(hpxml: hpxml, **cooking_range_values)
    end
    ovens_values.each do |oven_values|
      HPXML.add_oven(hpxml: hpxml, **oven_values)
    end
    lightings_values.each do |lighting_values|
      HPXML.add_lighting(hpxml: hpxml, **lighting_values)
    end
    plug_loads_values.each do |plug_load_values|
      HPXML.add_plug_load(hpxml: hpxml, **plug_load_values)
    end
    misc_loads_schedules_values.each do |misc_loads_schedule_values|
      HPXML.add_misc_loads_schedule(hpxml: hpxml, **misc_loads_schedule_values)
    end

    hpxml_path = File.join(tests_dir, derivative)
    XMLHelper.write_file(hpxml_doc, hpxml_path)
  end

  puts "Generated #{hpxmls_files.length} files."
end

def get_hpxml_file_hpxml_values(hpxml_file, hpxml_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    hpxml_values = { :xml_type => "HPXML",
                     :xml_generated_by => "Rakefile",
                     :transaction => "create",
                     :software_program_used => nil,
                     :software_program_version => nil,
                     :eri_calculation_version => "2014A",
                     :building_id => "MyBuilding",
                     :event_type => "proposed workscope" }
  elsif ['RESNET_Tests/Other_HERS_AutoGen_IAD_Home/01-L100.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/02-L100.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/03-L304.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/04-L324.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-01.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-02.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-03.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-04.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-05.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = "2014AE"
  elsif ['RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-01.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-02.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-03.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-01.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-02.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-03.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = "2014"
  end
  return hpxml_values
end

def get_hpxml_file_site_values(hpxml_file, site_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    site_values = { :fuels => ["electricity", "natural gas"],
                    :disable_natural_ventilation => true }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    site_values[:disable_natural_ventilation] = nil
  end
  return site_values
end

def get_hpxml_file_building_occupancy_values(hpxml_file, building_occupancys_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    building_occupancys_values << { :number_of_residents => 0 }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    building_occupancys_values = []
  end
  return building_occupancys_values
end

def get_hpxml_file_building_construction_values(hpxml_file, building_construction_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    building_construction_values = { :number_of_conditioned_floors => 1,
                                     :number_of_conditioned_floors_above_grade => 1,
                                     :number_of_bedrooms => 3,
                                     :conditioned_floor_area => 1539,
                                     :conditioned_building_volume => 12312,
                                     :garage_present => false,
                                     :use_only_ideal_air_system => true }
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml', 'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    building_construction_values[:number_of_conditioned_floors] = 2
    building_construction_values[:conditioned_floor_area] = 3078
    building_construction_values[:conditioned_building_volume] = 24624
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.4_HVAC/HVAC1a.xml', 'RESNET_Tests/4.4_HVAC/HVAC2a.xml', 'RESNET_Tests/4.5_DSE/HVAC3e.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    building_construction_values[:use_only_ideal_air_system] = nil
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 2
    building_construction_values[:use_only_ideal_air_system] = nil
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 4
    building_construction_values[:use_only_ideal_air_system] = nil
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 2
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-02.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-02.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 4
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    building_construction_values[:number_of_conditioned_floors] = 1
    building_construction_values[:conditioned_floor_area] = 1539
    building_construction_values[:conditioned_building_volume] = 12312
    building_construction_values[:use_only_ideal_air_system] = nil
  end
  return building_construction_values
end

def get_hpxml_file_climate_and_risk_zones_values(hpxml_file, climate_and_risk_zones_values)
  if hpxml_file == 'RESNET_Tests/4.1_Standard_140/L100AC.xml'
    climate_and_risk_zones_values = { :iecc2006 => "5B",
                                      :iecc2012 => "5B",
                                      :weather_station_id => "Weather_Station",
                                      :weather_station_name => "Colorado Springs, CO",
                                      :weather_station_wmo => "724660" }
  elsif hpxml_file == 'RESNET_Tests/4.1_Standard_140/L100AL.xml'
    climate_and_risk_zones_values = { :iecc2006 => "3B",
                                      :iecc2012 => "3B",
                                      :weather_station_id => "Weather_Station",
                                      :weather_station_name => "Las Vegas, NV",
                                      :weather_station_wmo => "723860" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    climate_and_risk_zones_values[:iecc2006] = "4A"
    climate_and_risk_zones_values[:iecc2012] = "4A"
    climate_and_risk_zones_values[:weather_station_name] = "Baltimore, MD"
    climate_and_risk_zones_values[:weather_station_wmo] = "724060"
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    climate_and_risk_zones_values[:iecc2006] = "3A"
    climate_and_risk_zones_values[:iecc2012] = "3A"
    climate_and_risk_zones_values[:weather_station_name] = "Dallas, TX"
    climate_and_risk_zones_values[:weather_station_wmo] = "722590"
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    climate_and_risk_zones_values[:iecc2006] = "1A"
    climate_and_risk_zones_values[:iecc2012] = "1A"
    climate_and_risk_zones_values[:weather_station_name] = "Miami, FL"
    climate_and_risk_zones_values[:weather_station_wmo] = "722020"
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml'].include? hpxml_file
    climate_and_risk_zones_values[:iecc2006] = "7"
    climate_and_risk_zones_values[:iecc2012] = "7"
    climate_and_risk_zones_values[:weather_station_name] = "Duluth, MN"
    climate_and_risk_zones_values[:weather_station_wmo] = "727450"
  end
  return climate_and_risk_zones_values
end

def get_hpxml_file_air_infiltration_measurement_values(hpxml_file, air_infiltration_measurement_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    air_infiltration_measurement_values = { :id => "InfiltMeas64",
                                            :constant_ach_natural => 0.67,
                                            :infiltration_volume => 12312 }
  elsif ['RESNET_Tests/4.1_Standard_140/L110AC.xml', 'RESNET_Tests/4.1_Standard_140/L110AL.xml', 'RESNET_Tests/4.1_Standard_140/L200AC.xml', 'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    air_infiltration_measurement_values[:constant_ach_natural] = 1.5
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml', 'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    air_infiltration_measurement_values[:infiltration_volume] = 24624
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    air_infiltration_measurement_values[:constant_ach_natural] = nil
    air_infiltration_measurement_values[:unit_of_measure] = "ACHnatural"
    air_infiltration_measurement_values[:air_leakage] = 0.67
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    air_infiltration_measurement_values[:constant_ach_natural] = nil
    air_infiltration_measurement_values[:house_pressure] = 50
    air_infiltration_measurement_values[:unit_of_measure] = "ACH"
    air_infiltration_measurement_values[:air_leakage] = 7.5
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    air_infiltration_measurement_values[:constant_ach_natural] = nil
    air_infiltration_measurement_values[:house_pressure] = 50
    air_infiltration_measurement_values[:unit_of_measure] = "ACH"
    air_infiltration_measurement_values[:air_leakage] = 3
  end
  return air_infiltration_measurement_values
end

def get_hpxml_file_attic_values(hpxml_file, attics_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    attics_values = [{ :id => "Attic_ID1",
                       :attic_type => "VentedAttic",
                       :constant_ach_natural => 2.4 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include? hpxml_file
    attics_values[0][:constant_ach_natural] = nil
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    attics_values[0][:constant_ach_natural] = nil
    attics_values[0][:specific_leakage_area] = 0.0008
  elsif ['RESNET_Tests/Other_HERS_AutoGen_IAD_Home/01-L100.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/02-L100.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/03-L304.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/04-L324.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-01.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-02.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-03.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-04.xml', 'RESNET_Tests/Other_HERS_Method_IAF/L100A-05.xml', 'NASEO_Technical_Exercises/NASEO-01.xml', 'NASEO_Technical_Exercises/NASEO-02.xml', 'NASEO_Technical_Exercises/NASEO-03.xml', 'NASEO_Technical_Exercises/NASEO-04.xml', 'NASEO_Technical_Exercises/NASEO-05.xml', 'NASEO_Technical_Exercises/NASEO-06.xml', 'NASEO_Technical_Exercises/NASEO-07.xml', 'NASEO_Technical_Exercises/NASEO-08.xml', 'NASEO_Technical_Exercises/NASEO-09.xml', 'NASEO_Technical_Exercises/NASEO-09b.xml', 'NASEO_Technical_Exercises/NASEO-10.xml', 'NASEO_Technical_Exercises/NASEO-10b.xml', 'NASEO_Technical_Exercises/NASEO-11.xml', 'NASEO_Technical_Exercises/NASEO-12.xml', 'NASEO_Technical_Exercises/NASEO-13.xml', 'NASEO_Technical_Exercises/NASEO-14.xml', 'NASEO_Technical_Exercises/NASEO-15.xml', 'NASEO_Technical_Exercises/NASEO-16.xml', 'NASEO_Technical_Exercises/NASEO-17.xml', 'NASEO_Technical_Exercises/NASEO-18.xml', 'NASEO_Technical_Exercises/NASEO-19.xml', 'NASEO_Technical_Exercises/NASEO-20.xml', 'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    attics_values[0][:specific_leakage_area] = 0.0008
  end
  return attics_values
end

def get_hpxml_file_attic_roofs_values(hpxml_file, attics_roofs_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    attics_roofs_values = [[{ :id => "attic-roof-north",
                              :area => 811.1,
                              :azimuth => 0,
                              :solar_absorptance => 0.6,
                              :emittance => 0.9,
                              :pitch => 4,
                              :radiant_barrier => false,
                              :insulation_id => "Attic_Roof_Ins_north",
                              :insulation_assembly_r_value => 1.99 },
                            {  :id => "attic-roof-south",
                               :area => 811.1,
                               :azimuth => 180,
                               :solar_absorptance => 0.6,
                               :emittance => 0.9,
                               :pitch => 4,
                               :radiant_barrier => false,
                               :insulation_id => "Attic_Roof_Ins_south",
                               :insulation_assembly_r_value => 1.99 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml', 'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    attics_roofs_values[0][0][:solar_absorptance] = 0.2
    attics_roofs_values[0][1][:solar_absorptance] = 0.2
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    attics_roofs_values = [[{ :id => "attic-roof-1",
                              :area => 1622.2,
                              :solar_absorptance => 0.6,
                              :emittance => 0.9,
                              :pitch => 4,
                              :radiant_barrier => false,
                              :insulation_id => "Attic_Roof_Ins_ID1",
                              :insulation_assembly_r_value => 1.99 }]]
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-09.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-10.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-09.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-10.xml'].include? hpxml_file
    attics_roofs_values[0][0][:radiant_barrier] = true
    attics_roofs_values[0][1][:radiant_barrier] = true
  end
  return attics_roofs_values
end

def get_hpxml_file_attic_floors_values(hpxml_file, attics_floors_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    attics_floors_values = [[{ :id => "attic-floor-1",
                               :adjacent_to => "living space",
                               :area => 1539,
                               :insulation_id => "Attic_Floor_Ins_ID1",
                               :insulation_assembly_r_value => 18.45 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L120AC.xml', 'RESNET_Tests/4.1_Standard_140/L120AL.xml'].include? hpxml_file
    attics_floors_values[0][0][:insulation_assembly_r_value] = 57.49
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml', 'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    attics_floors_values[0][0][:insulation_assembly_r_value] = 11.75
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    attics_floors_values[0][0][:insulation_assembly_r_value] = 39.3
  end
  return attics_floors_values
end

def get_hpxml_file_attic_walls_values(hpxml_file, attics_walls_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    attics_walls_values = [[{ :id => "attic-wall-east",
                              :adjacent_to => "outside",
                              :wall_type => "WoodStud",
                              :area => 60.75,
                              :azimuth => 90,
                              :solar_absorptance => 0.6,
                              :emittance => 0.9,
                              :insulation_id => "Attic_Wall_Ins_east",
                              :insulation_assembly_r_value => 2.15 },
                            {  :id => "attic-wall-west",
                               :adjacent_to => "outside",
                               :wall_type => "WoodStud",
                               :area => 60.75,
                               :azimuth => 270,
                               :solar_absorptance => 0.6,
                               :emittance => 0.9,
                               :insulation_id => "Attic_Wall_Ins_west",
                               :insulation_assembly_r_value => 2.15 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml', 'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    attics_walls_values[0][0][:solar_absorptance] = 0.2
    attics_walls_values[0][1][:solar_absorptance] = 0.2
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    attics_walls_values = [[{ :id => "attic-wall-1",
                              :adjacent_to => "outside",
                              :wall_type => "WoodStud",
                              :area => 121.5,
                              :solar_absorptance => 0.6,
                              :emittance => 0.9,
                              :insulation_id => "Attic_Wall_Ins_ID1",
                              :insulation_assembly_r_value => 2.15 }]]
  end
  return attics_walls_values
end

def get_hpxml_file_foundation_values(hpxml_file, foundations_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    foundations_values = [{ :id => "Foundation_ID1",
                            :foundation_type => "Ambient" }]
  elsif ['RESNET_Tests/4.1_Standard_140/L302XC.xml', 'NASEO_Technical_Exercises/NASEO-17.xml'].include? hpxml_file
    foundations_values[0][:foundation_type] = "SlabOnGrade"
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml', 'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    foundations_values[0][:foundation_type] = "ConditionedBasement"
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'NASEO_Technical_Exercises/NASEO-13.xml'].include? hpxml_file
    foundations_values[0][:foundation_type] = "UnventedCrawlspace"
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml', 'NASEO_Technical_Exercises/NASEO-15.xml'].include? hpxml_file
    foundations_values[0][:foundation_type] = "UnconditionedBasement"
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    foundations_values[0][:foundation_type] = "VentedCrawlspace"
    foundations_values[0][:specific_leakage_area] = 0.00667
  end
  return foundations_values
end

def get_hpxml_file_foundation_walls_values(hpxml_file, foundations_walls_values)
  if ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    foundations_walls_values = [[{ :id => "fndwall-all",
                                   :height => 7.25,
                                   :area => 1218,
                                   :thickness => 6,
                                   :depth_below_grade => 6.583,
                                   :adjacent_to => "ground",
                                   :insulation_id => "FWall_Ins_all",
                                   :insulation_assembly_r_value => 1.165 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L324XC.xml'].include? hpxml_file
    foundations_walls_values[0][0][:insulation_assembly_r_value] = 10.69
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    foundations_walls_values = [[{ :id => "fndwall-1",
                                   :height => 4,
                                   :area => 672,
                                   :thickness => 8,
                                   :depth_below_grade => 3,
                                   :adjacent_to => "ground",
                                   :insulation_id => "FWall_Ins_ID1",
                                   :insulation_assembly_r_value => 8.165 }]]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    foundations_walls_values = [[{ :id => "fndwall-1",
                                   :height => 2,
                                   :area => 336,
                                   :thickness => 6,
                                   :depth_below_grade => 0,
                                   :adjacent_to => "ground",
                                   :insulation_id => "FWall_Ins_ID1",
                                   :insulation_assembly_r_value => 1.34 }]]
  elsif ['NASEO_Technical_Exercises/NASEO-13.xml'].include? hpxml_file
    foundations_walls_values = [[{ :id => "fndwall-1",
                                   :height => 4,
                                   :area => 672,
                                   :thickness => 8,
                                   :depth_below_grade => 3,
                                   :adjacent_to => "ground",
                                   :insulation_id => "FWall_Ins_ID1",
                                   :insulation_assembly_r_value => 8.6 }]]
  elsif ['NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    foundations_walls_values = [[{ :id => "fndwall-1",
                                   :height => 4,
                                   :area => 672,
                                   :thickness => 8,
                                   :depth_below_grade => 3,
                                   :adjacent_to => "ground",
                                   :insulation_id => "FWall_Ins_ID1",
                                   :insulation_assembly_r_value => 1.6 }]]
  elsif ['NASEO_Technical_Exercises/NASEO-15.xml', 'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    foundations_walls_values = [[{ :id => "fndwall-1",
                                   :height => 8,
                                   :area => 1344,
                                   :thickness => 8,
                                   :depth_below_grade => 7,
                                   :adjacent_to => "ground",
                                   :insulation_id => "FWall_Ins_ID1",
                                   :insulation_assembly_r_value => 20.6 }]]
  end
  return foundations_walls_values
end

def get_hpxml_file_slab_values(hpxml_file, foundations_slabs_values)
  if ['RESNET_Tests/4.1_Standard_140/L302XC.xml'].include? hpxml_file
    foundations_slabs_values = [[{ :id => "Slab_ID1",
                                   :area => 1539,
                                   :thickness => 4,
                                   :exposed_perimeter => 168,
                                   :perimeter_insulation_depth => 0,
                                   :under_slab_insulation_width => 0,
                                   :depth_below_grade => 0,
                                   :perimeter_insulation_id => "PerimeterInsulation_ID1",
                                   :perimeter_insulation_r_value => 0,
                                   :under_slab_insulation_id => "UnderSlabInsulation_ID1",
                                   :under_slab_insulation_r_value => 0,
                                   :carpet_fraction => 1,
                                   :carpet_r_value => 2.08 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    foundations_slabs_values = [[{ :id => "fndslab-1",
                                   :area => 1539,
                                   :thickness => 4,
                                   :exposed_perimeter => 168,
                                   :perimeter_insulation_depth => 0,
                                   :under_slab_insulation_width => 0,
                                   :depth_below_grade => 6.583,
                                   :perimeter_insulation_id => "FSlab_PerimIns_ID1",
                                   :perimeter_insulation_r_value => 0,
                                   :under_slab_insulation_id => "FSlab_UnderIns_ID1",
                                   :under_slab_insulation_r_value => 0,
                                   :carpet_fraction => 0,
                                   :carpet_r_value => 0 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L304XC.xml'].include? hpxml_file
    foundations_slabs_values[0][0][:perimeter_insulation_depth] = 2.5
    foundations_slabs_values[0][0][:perimeter_insulation_r_value] = 5.4
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'NASEO_Technical_Exercises/NASEO-13.xml', 'NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    foundations_slabs_values = [[{ :id => "Slab_ID1",
                                   :area => 1539,
                                   :thickness => 0,
                                   :exposed_perimeter => 168,
                                   :perimeter_insulation_depth => 0,
                                   :under_slab_insulation_width => 0,
                                   :depth_below_grade => 3,
                                   :perimeter_insulation_id => "PerimeterInsulation_ID1",
                                   :perimeter_insulation_r_value => 0,
                                   :under_slab_insulation_id => "UnderSlabInsulation_ID1",
                                   :under_slab_insulation_r_value => 0,
                                   :carpet_fraction => 0,
                                   :carpet_r_value => 2.5 }]]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    foundations_slabs_values = [[{ :id => "fndslab-1",
                                   :area => 1539,
                                   :thickness => 0,
                                   :exposed_perimeter => 168,
                                   :perimeter_insulation_depth => 0,
                                   :under_slab_insulation_width => 0,
                                   :depth_below_grade => 0,
                                   :perimeter_insulation_id => "PerimeterInsulation_ID1",
                                   :perimeter_insulation_r_value => 0,
                                   :under_slab_insulation_id => "UnderSlabInsulation_ID1",
                                   :under_slab_insulation_r_value => 0,
                                   :carpet_fraction => 1,
                                   :carpet_r_value => 2 }]]
  elsif ['NASEO_Technical_Exercises/NASEO-15.xml', 'NASEO_Technical_Exercises/NASEO-16.xml'].include? hpxml_file
    foundations_slabs_values = [[{ :id => "Slab_ID1",
                                   :area => 1539,
                                   :thickness => 4,
                                   :exposed_perimeter => 168,
                                   :perimeter_insulation_depth => 0,
                                   :under_slab_insulation_width => 0,
                                   :depth_below_grade => 7,
                                   :perimeter_insulation_id => "PerimeterInsulation_ID1",
                                   :perimeter_insulation_r_value => 0,
                                   :under_slab_insulation_id => "UnderSlabInsulation_ID1",
                                   :under_slab_insulation_r_value => 0,
                                   :carpet_fraction => 0,
                                   :carpet_r_value => 2.5 }]]
  elsif ['NASEO_Technical_Exercises/NASEO-17.xml'].include? hpxml_file
    foundations_slabs_values = [[{ :id => "Slab_ID1",
                                   :area => 1539,
                                   :thickness => 4,
                                   :exposed_perimeter => 168,
                                   :perimeter_insulation_depth => 0,
                                   :under_slab_insulation_width => 4,
                                   :depth_below_grade => 0,
                                   :perimeter_insulation_id => "PerimeterInsulation_ID1",
                                   :perimeter_insulation_r_value => 0,
                                   :under_slab_insulation_id => "UnderSlabInsulation_ID1",
                                   :under_slab_insulation_r_value => 5,
                                   :carpet_fraction => 0,
                                   :carpet_r_value => 2.5 }]]
  end
  return foundations_slabs_values
end

def get_hpxml_file_frame_floor_values(hpxml_file, foundations_framefloors_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    foundations_framefloors_values = [[{ :id => "Floor_ID1",
                                         :adjacent_to => "living space",
                                         :area => 1539,
                                         :insulation_id => "Floor_Ins_ID1",
                                         :insulation_assembly_r_value => 14.15 }]]
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml', 'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    foundations_framefloors_values[0][0][:insulation_assembly_r_value] = 4.24
  elsif ['RESNET_Tests/4.1_Standard_140/L302XC.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'NASEO_Technical_Exercises/NASEO-16.xml', 'NASEO_Technical_Exercises/NASEO-17.xml'].include? hpxml_file
    foundations_framefloors_values = []
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'NASEO_Technical_Exercises/NASEO-13.xml', 'NASEO_Technical_Exercises/NASEO-15.xml'].include? hpxml_file
    foundations_framefloors_values[0][0][:insulation_assembly_r_value] = 3.1
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    foundations_framefloors_values[0][0][:insulation_assembly_r_value] = 13.8
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    foundations_framefloors_values[0][0][:insulation_assembly_r_value] = 20.4
  elsif ['NASEO_Technical_Exercises/NASEO-14.xml'].include? hpxml_file
    foundations_framefloors_values[0][0][:insulation_assembly_r_value] = 15.6
  end
  return foundations_framefloors_values
end

def get_hpxml_file_rim_joists_values(hpxml_file, rim_joists_values)
  if ['RESNET_Tests/4.1_Standard_140/L322XC.xml'].include? hpxml_file
    rim_joists_values = [{ :id => "RimJoist_ID1",
                           :exterior_adjacent_to => "outside",
                           :interior_adjacent_to => "living space",
                           :area => 126,
                           :solar_absorptance => 0.6,
                           :emittance => 0.9,
                           :insulation_id => "RimJoist_Ins_ID1",
                           :insulation_assembly_r_value => 5.01 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L324XC.xml'].include? hpxml_file
    rim_joists_values[0][:insulation_assembly_r_value] = 13.14
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    rim_joists_values = []
  end
  return rim_joists_values
end

def get_hpxml_file_walls_values(hpxml_file, walls_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    walls_values = [{ :id => "agwall-north",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 456,
                      :azimuth => 0,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_id => "AGW_Ins_north",
                      :insulation_assembly_r_value => 11.76 },
                    { :id => "agwall-east",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 216,
                      :azimuth => 90,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_id => "AGW_Ins_east",
                      :insulation_assembly_r_value => 11.76 },
                    { :id => "agwall-south",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 456,
                      :azimuth => 180,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_id => "AGW_Ins_south",
                      :insulation_assembly_r_value => 11.76 },
                    { :id => "agwall-west",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 216,
                      :azimuth => 270,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_id => "AGW_Ins_west",
                      :insulation_assembly_r_value => 11.76 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L120AC.xml', 'RESNET_Tests/4.1_Standard_140/L120AL.xml'].include? hpxml_file
    walls_values[0][:insulation_assembly_r_value] = 23.58
    walls_values[1][:insulation_assembly_r_value] = 23.58
    walls_values[2][:insulation_assembly_r_value] = 23.58
    walls_values[3][:insulation_assembly_r_value] = 23.58
  elsif ['RESNET_Tests/4.1_Standard_140/L200AC.xml', 'RESNET_Tests/4.1_Standard_140/L200AL.xml'].include? hpxml_file
    walls_values[0][:insulation_assembly_r_value] = 4.84
    walls_values[1][:insulation_assembly_r_value] = 4.84
    walls_values[2][:insulation_assembly_r_value] = 4.84
    walls_values[3][:insulation_assembly_r_value] = 4.84
  elsif ['RESNET_Tests/4.1_Standard_140/L202AC.xml', 'RESNET_Tests/4.1_Standard_140/L202AL.xml'].include? hpxml_file
    walls_values[0][:solar_absorptance] = 0.2
    walls_values[1][:solar_absorptance] = 0.2
    walls_values[2][:solar_absorptance] = 0.2
    walls_values[3][:solar_absorptance] = 0.2
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    walls_values = [{ :id => "agwall-1",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 1344,
                      :solar_absorptance => 0.6,
                      :emittance => 0.9,
                      :insulation_id => "AGW_Ins_ID1",
                      :insulation_assembly_r_value => 11.76 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    walls_values = [{ :id => "agwall-1",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 1344,
                      :solar_absorptance => 0.75,
                      :emittance => 0.9,
                      :insulation_id => "AGW_Ins_ID1",
                      :insulation_assembly_r_value => 16.9 }]
  end
  return walls_values
end

def get_hpxml_file_windows_values(hpxml_file, windows_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    windows_values = [{ :id => "Window_North",
                        :area => 90,
                        :azimuth => 0,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-north",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 },
                      { :id => "Window_East",
                        :area => 45,
                        :azimuth => 90,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-east",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 },
                      { :id => "Window_South",
                        :area => 90,
                        :azimuth => 180,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-south",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 },
                      { :id => "Window_West",
                        :area => 45,
                        :azimuth => 270,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-west",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L130AC.xml', 'RESNET_Tests/4.1_Standard_140/L130AL.xml'].include? hpxml_file
    windows_values[0][:ufactor] = 0.3
    windows_values[0][:shgc] = 0.335
    windows_values[1][:ufactor] = 0.3
    windows_values[1][:shgc] = 0.335
    windows_values[2][:ufactor] = 0.3
    windows_values[2][:shgc] = 0.335
    windows_values[3][:ufactor] = 0.3
    windows_values[3][:shgc] = 0.335
  elsif ['RESNET_Tests/4.1_Standard_140/L140AC.xml', 'RESNET_Tests/4.1_Standard_140/L140AL.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-06.xml'].include? hpxml_file
    windows_values = []
  elsif ['RESNET_Tests/4.1_Standard_140/L150AC.xml', 'RESNET_Tests/4.1_Standard_140/L150AL.xml'].include? hpxml_file
    windows_values = [{ :id => "Window_South",
                        :area => 270,
                        :azimuth => 180,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-south",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L160AC.xml', 'RESNET_Tests/4.1_Standard_140/L160AL.xml'].include? hpxml_file
    windows_values = [{ :id => "Window_East",
                        :area => 135,
                        :azimuth => 90,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-east",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 },
                      { :id => "Window_West",
                        :area => 135,
                        :azimuth => 270,
                        :ufactor => 1.039,
                        :shgc => 0.67,
                        :wall_idref => "agwall-south",
                        :interior_shading_factor_summer => 1,
                        :interior_shading_factor_winter => 1 }]
  elsif ['RESNET_Tests/4.1_Standard_140/L155AC.xml', 'RESNET_Tests/4.1_Standard_140/L155AL.xml'].include? hpxml_file
    windows_values[0][:overhangs_depth] = 2.5
    windows_values[0][:overhangs_distance_to_top_of_window] = 1
    windows_values[0][:overhangs_distance_to_bottom_of_window] = 6
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    windows_values[0][:interior_shading_factor_summer] = nil
    windows_values[0][:interior_shading_factor_winter] = nil
    windows_values[1][:interior_shading_factor_summer] = nil
    windows_values[1][:interior_shading_factor_winter] = nil
    windows_values[2][:interior_shading_factor_summer] = nil
    windows_values[2][:interior_shading_factor_winter] = nil
    windows_values[3][:interior_shading_factor_summer] = nil
    windows_values[3][:interior_shading_factor_winter] = nil
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    windows_values[0][:wall_idref] = "agwall-1"
    windows_values[0][:interior_shading_factor_summer] = nil
    windows_values[0][:interior_shading_factor_winter] = nil
    windows_values[1][:wall_idref] = "agwall-1"
    windows_values[1][:interior_shading_factor_summer] = nil
    windows_values[1][:interior_shading_factor_winter] = nil
    windows_values[2][:wall_idref] = "agwall-1"
    windows_values[2][:interior_shading_factor_summer] = nil
    windows_values[2][:interior_shading_factor_winter] = nil
    windows_values[3][:wall_idref] = "agwall-1"
    windows_values[3][:interior_shading_factor_summer] = nil
    windows_values[3][:interior_shading_factor_winter] = nil
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    windows_values[0][:ufactor] = 0.32
    windows_values[0][:shgc] = 0.4
    windows_values[0][:wall_idref] = "agwall-1"
    windows_values[0][:interior_shading_factor_summer] = nil
    windows_values[0][:interior_shading_factor_winter] = nil
    windows_values[1][:ufactor] = 0.32
    windows_values[1][:shgc] = 0.4
    windows_values[1][:wall_idref] = "agwall-1"
    windows_values[1][:interior_shading_factor_summer] = nil
    windows_values[1][:interior_shading_factor_winter] = nil
    windows_values[2][:ufactor] = 0.32
    windows_values[2][:shgc] = 0.4
    windows_values[2][:wall_idref] = "agwall-1"
    windows_values[2][:interior_shading_factor_summer] = nil
    windows_values[2][:interior_shading_factor_winter] = nil
    windows_values[3][:ufactor] = 0.32
    windows_values[3][:shgc] = 0.4
    windows_values[3][:wall_idref] = "agwall-1"
    windows_values[3][:interior_shading_factor_summer] = nil
    windows_values[3][:interior_shading_factor_winter] = nil
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-11.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-11.xml'].include? hpxml_file
    windows_values[0][:shgc] = 0.01
    windows_values[1][:shgc] = 0.01
    windows_values[2][:shgc] = 0.01
    windows_values[3][:shgc] = 0.01
  end
  return windows_values
end

def get_hpxml_file_doors_values(hpxml_file, doors_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    doors_values = [{ :id => "Door_South",
                      :wall_idref => "agwall-south",
                      :area => 20,
                      :azimuth => 180,
                      :r_value => 3.04 },
                    { :id => "Door_North",
                      :wall_idref => "agwall-north",
                      :area => 20,
                      :azimuth => 0,
                      :r_value => 3.04 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    doors_values[0][:wall_idref] = "agwall-1"
    doors_values[1][:wall_idref] = "agwall-1"
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    doors_values[0][:wall_idref] = "agwall-1"
    doors_values[0][:r_value] = 3.125
    doors_values[1][:wall_idref] = "agwall-1"
    doors_values[1][:r_value] = 3.125
  end
  return doors_values
end

def get_hpxml_file_heating_systems_values(hpxml_file, heating_systems_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.82,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'NASEO_Technical_Exercises/NASEO-07.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :heating_system_type => "ElectricResistance",
                                :heating_system_fuel => "electricity",
                                :heating_capacity => 60000,
                                :heating_efficiency_percent => 1,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.95,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.78,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.96,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 56100,
                                :heating_efficiency_afue => 0.78,
                                :fraction_heat_load_served => 1,
                                :electric_auxiliary_energy => 1040 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml'].include? hpxml_file
    heating_systems_values[0][:heating_efficiency_afue] = 0.9
    heating_systems_values[0][:electric_auxiliary_energy] = 780
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2b.xml', 'RESNET_Tests/4.4_HVAC/HVAC2d.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    heating_systems_values = []
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = 1
    heating_systems_values[0][:electric_auxiliary_energy] = nil
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 46600,
                                :heating_efficiency_afue => 0.78,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    heating_systems_values[0][:heating_capacity] = 56000
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml'].include? hpxml_file
    heating_systems_values[0][:heating_capacity] = 49000
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml'].include? hpxml_file
    heating_systems_values[0][:heating_capacity] = 61000
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 1 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-07.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-07.xml'].include? hpxml_file
    heating_systems_values[0][:heating_efficiency_afue] = 0.96
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :heating_system_type => "Boiler",
                                :heating_system_fuel => "fuel oil",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 1 }]
  elsif ['NASEO_Technical_Exercises/NASEO-20.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :heating_system_type => "WallFurnace",
                                :heating_system_fuel => "propane",
                                :heating_capacity => 60000,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 1 }]
  elsif ['NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "SpaceHeat_ID1",
                                :heating_system_type => "Stove",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 60000,
                                :heating_efficiency_percent => 0.6,
                                :fraction_heat_load_served => 1 }]
  end
  return heating_systems_values
end

def get_hpxml_file_cooling_systems_values(hpxml_file, cooling_systems_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 11 }]
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 15 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml', 'NASEO_Technical_Exercises/NASEO-07.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 38300,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1b.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_efficiency_seer] = 13
  elsif ['RESNET_Tests/4.5_DSE/HVAC3e.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 38400,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_capacity] = 49900
  elsif ['RESNET_Tests/4.5_DSE/HVAC3g.xml', 'RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_capacity] = 42200
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID1",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 13 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-14.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-14.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_efficiency_seer] = 21
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    cooling_systems_values = []
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "SpaceCool_ID1",
                                :distribution_system_idref => "HVAC_Dist_ID2",
                                :cooling_system_type => "central air conditioning",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 60000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 10 }]
  end
  return cooling_systems_values
end

def get_hpxml_file_heat_pumps_values(hpxml_file, heat_pumps_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 7.5,
                           :cooling_efficiency_seer => 12 }
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 6.8,
                           :cooling_efficiency_seer => 10 }
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-03.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml', 'NASEO_Technical_Exercises/NASEO-07.xml', 'NASEO_Technical_Exercises/NASEO-08.xml', 'NASEO_Technical_Exercises/NASEO-20.xml', 'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    heat_pumps_values = []
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-04.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-04.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-04.xml'].include? hpxml_file
    heat_pumps_values[0][:heating_efficiency_hspf] = 9.85
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 56100,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 0,
                           :heating_efficiency_hspf => 6.8,
                           :cooling_efficiency_seer => 13 }
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2d.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 56100,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 0,
                           :heating_efficiency_hspf => 9.85,
                           :cooling_efficiency_seer => 13 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-19.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 8.2,
                           :cooling_efficiency_seer => 13 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-19.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 8.2,
                           :cooling_efficiency_seer => 14 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-20.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 12,
                           :cooling_efficiency_seer => 13 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-20.xml'].include? hpxml_file
    heat_pumps_values << { :id => "SpaceHeatPump_ID1",
                           :distribution_system_idref => "HVAC_Dist_ID1",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :cooling_capacity => 60000,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 12,
                           :cooling_efficiency_seer => 14 }
  elsif ['NASEO_Technical_Exercises/NASEO-18.xml'].include? hpxml_file
    heat_pumps_values[0][:heat_pump_type] = "ground-to-air"
    heat_pumps_values[0][:heating_efficiency_hspf] = nil
    heat_pumps_values[0][:heating_efficiency_cop] = 4.2
    heat_pumps_values[0][:cooling_efficiency_seer] = nil
    heat_pumps_values[0][:cooling_efficiency_eer] = 20.2
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml'].include? hpxml_file
    heat_pumps_values[0][:distribution_system_idref] = nil
    heat_pumps_values[0][:heat_pump_type] = "mini-split"
    heat_pumps_values[0][:heating_efficiency_hspf] = 10.5
    heat_pumps_values[0][:cooling_efficiency_seer] = 23
  end
  return heat_pumps_values
end

def get_hpxml_file_hvac_control_values(hpxml_file, hvac_controls_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    hvac_controls_values = [{ :id => "HVAC_Ctrl_ID1",
                              :control_type => "manual thermostat" }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    hvac_controls_values = []
  elsif ['NASEO_Technical_Exercises/NASEO-06.xml'].include? hpxml_file
    hvac_controls_values[0][:control_type] = "programmable thermostat"
  end
  return hvac_controls_values
end

def get_hpxml_file_hvac_distribution_values(hpxml_file, hvac_distributions_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.5_DSE/HVAC3a.xml', 'RESNET_Tests/4.5_DSE/HVAC3e.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVAC_Dist_ID1",
                                   :distribution_system_type => "AirDistribution" }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC1a.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVAC_Dist_ID1",
                                   :distribution_system_type => "DSE",
                                   :annual_cooling_dse => 1 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2a.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVAC_Dist_ID1",
                                   :distribution_system_type => "DSE",
                                   :annual_heating_dse => 1 }]
  elsif ['RESNET_Tests/4.4_HVAC/HVAC2c.xml', 'RESNET_Tests/4.4_HVAC/HVAC2d.xml', 'RESNET_Tests/4.4_HVAC/HVAC2e.xml'].include? hpxml_file
    hvac_distributions_values[0][:annual_cooling_dse] = 1
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml', 'NASEO_Technical_Exercises/NASEO-20.xml', 'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    hvac_distributions_values = []
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVAC_Dist_ID1",
                                   :distribution_system_type => "HydronicDistribution" },
                                 { :id => "HVAC_Dist_ID2",
                                   :distribution_system_type => "AirDistribution" }]
  end
  return hvac_distributions_values
end

def get_hpxml_file_duct_leakage_measurements_values(hpxml_file, duct_leakage_measurements_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.5_DSE/HVAC3a.xml', 'RESNET_Tests/4.5_DSE/HVAC3e.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-12.xml.skip', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-12.xml.skip'].include? hpxml_file
    duct_leakage_measurements_values = [[{ :duct_type => "supply",
                                           :duct_leakage_value => 0 },
                                         { :duct_type => "return",
                                           :duct_leakage_value => 0 }]]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3d.xml', 'RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 125
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 125
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 30.78
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 30.78
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml.skip', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml.skip'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 61.5
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 61.5
  elsif ['NASEO_Technical_Exercises/NASEO-01.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 30
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 30
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml', 'NASEO_Technical_Exercises/NASEO-20.xml', 'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    duct_leakage_measurements_values = []
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    duct_leakage_measurements_values.unshift([])
  end
  return duct_leakage_measurements_values
end

def get_hpxml_file_ducts_values(hpxml_file, ducts_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    ducts_values = [[{ :duct_type => "supply",
                       :duct_insulation_r_value => 0,
                       :duct_location => "living space",
                       :duct_surface_area => 100 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "living space",
                       :duct_surface_area => 100 }]]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3a.xml', 'RESNET_Tests/4.5_DSE/HVAC3e.xml'].include? hpxml_file
    ducts_values = [[{ :duct_type => "supply",
                       :duct_insulation_r_value => 0,
                       :duct_location => "living space",
                       :duct_surface_area => 308 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "living space",
                       :duct_surface_area => 77 }]]
  elsif ['RESNET_Tests/4.5_DSE/HVAC3b.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "basement - unconditioned"
    ducts_values[0][1][:duct_location] = "basement - unconditioned"
  elsif ['RESNET_Tests/4.5_DSE/HVAC3c.xml', 'RESNET_Tests/4.5_DSE/HVAC3d.xml'].include? hpxml_file
    ducts_values[0][0][:duct_insulation_r_value] = 6
    ducts_values[0][0][:duct_location] = "basement - unconditioned"
    ducts_values[0][1][:duct_insulation_r_value] = 6
    ducts_values[0][1][:duct_location] = "basement - unconditioned"
  elsif ['RESNET_Tests/4.5_DSE/HVAC3f.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-08.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-08.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "attic - vented"
    ducts_values[0][1][:duct_location] = "attic - vented"
  elsif ['RESNET_Tests/4.5_DSE/HVAC3g.xml', 'RESNET_Tests/4.5_DSE/HVAC3h.xml'].include? hpxml_file
    ducts_values[0][0][:duct_insulation_r_value] = 6
    ducts_values[0][0][:duct_location] = "attic - vented"
    ducts_values[0][1][:duct_insulation_r_value] = 6
    ducts_values[0][1][:duct_location] = "attic - vented"
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    ducts_values = [[{ :duct_type => "supply",
                       :duct_insulation_r_value => 6,
                       :duct_location => "living space",
                       :duct_surface_area => 0.001 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 6,
                       :duct_location => "living space",
                       :duct_surface_area => 0.001 }]]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-22.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-22.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "crawlspace - vented"
    ducts_values[0][1][:duct_location] = "crawlspace - vented"
  elsif ['RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-07.xml.skip', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-07.xml.skip'].include? hpxml_file
    ducts_values[0][0][:duct_insulation_r_value] = 6
    ducts_values[0][0][:duct_location] = "outside"
    ducts_values[0][0][:duct_surface_area] = 385
    ducts_values[0][1][:duct_insulation_r_value] = 6
    ducts_values[0][1][:duct_location] = "outside"
    ducts_values[0][1][:duct_surface_area] = 77
  elsif ['NASEO_Technical_Exercises/NASEO-01.xml'].include? hpxml_file
    ducts_values[0][0][:duct_insulation_r_value] = 6
    ducts_values[0][0][:duct_location] = "attic - vented"
    ducts_values[0][0][:duct_surface_area] = 300
    ducts_values[0][1][:duct_insulation_r_value] = 6
    ducts_values[0][1][:duct_location] = "attic - vented"
    ducts_values[0][1][:duct_surface_area] = 75
  elsif ['NASEO_Technical_Exercises/NASEO-19.xml', 'NASEO_Technical_Exercises/NASEO-20.xml', 'NASEO_Technical_Exercises/NASEO-21.xml'].include? hpxml_file
    ducts_values = []
  elsif ['NASEO_Technical_Exercises/NASEO-08.xml'].include? hpxml_file
    ducts_values.unshift([])
  end
  return ducts_values
end

def get_hpxml_file_ventilation_fan_values(hpxml_file, ventilation_fans_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "Mech_Vent_ID1",
                                 :fan_type => "exhaust only",
                                 :rated_flow_rate => 56.2,
                                 :hours_in_operation => 24,
                                 :fan_power => 14 }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "Mech_Vent_ID1",
                                 :fan_type => "heat recovery ventilator",
                                 :rated_flow_rate => 56.2,
                                 :hours_in_operation => 24,
                                 :sensible_recovery_efficiency => 0.6,
                                 :fan_power => 14 }
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-09.xml'].include? hpxml_file
    ventilation_fans_values[0][:rated_flow_rate] = 48.7
    ventilation_fans_values[0][:fan_power] = 12.2
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-09.xml'].include? hpxml_file
    ventilation_fans_values[0][:rated_flow_rate] = 51.2
    ventilation_fans_values[0][:fan_power] = 12.8
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-10.xml'].include? hpxml_file
    ventilation_fans_values[0][:rated_flow_rate] = 63.7
    ventilation_fans_values[0][:fan_power] = 15.9
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-10.xml'].include? hpxml_file
    ventilation_fans_values[0][:rated_flow_rate] = 66.2
    ventilation_fans_values[0][:fan_power] = 16.6
  elsif ['NASEO_Technical_Exercises/NASEO-04.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "Mech_Vent_ID1",
                                 :fan_type => "exhaust only",
                                 :rated_flow_rate => 50,
                                 :hours_in_operation => 24,
                                 :fan_power => 15 }
  end
  return ventilation_fans_values
end

def get_hpxml_file_water_heating_system_values(hpxml_file, water_heating_systems_values)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    water_heating_systems_values = [{ :id => "DHW_ID1",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 15355,
                                      :energy_factor => 0.88 }]
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "natural gas"
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.82
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    water_heating_systems_values = [{ :id => "DHW_ID1",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 40000,
                                      :energy_factor => 0.56,
                                      :recovery_efficiency => 0.78 }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-03.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-03.xml'].include? hpxml_file
    water_heating_systems_values[0][:energy_factor] = 0.62
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml'].include? hpxml_file
    water_heating_systems_values = [{ :id => "DHW_ID1",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 38000,
                                      :energy_factor => 0.62,
                                      :recovery_efficiency => 0.78 }]
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-08.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-08.xml'].include? hpxml_file
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.83
    water_heating_systems_values[0][:recovery_efficiency] = nil
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-12.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-12.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "electricity"
    water_heating_systems_values[0][:heating_capacity] = 15355
    water_heating_systems_values[0][:energy_factor] = 0.95
    water_heating_systems_values[0][:recovery_efficiency] = 0.98
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-13.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-13.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "electricity"
    water_heating_systems_values[0][:water_heater_type] = "heat pump water heater"
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 2.5
    water_heating_systems_values[0][:recovery_efficiency] = nil
  end
  return water_heating_systems_values
end

def get_hpxml_file_hot_water_distribution_values(hpxml_file, hot_water_distributions_values)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    hot_water_distributions_values = [{ :id => "HWDist_ID1",
                                        :system_type => "Standard",
                                        :pipe_r_value => 0.0 }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-05.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-05.xml'].include? hpxml_file
    hot_water_distributions_values[0][:system_type] = "Recirculation"
    hot_water_distributions_values[0][:recirculation_control_type] = "no control"
    hot_water_distributions_values[0][:recirculation_branch_piping_length] = 10
    hot_water_distributions_values[0][:recirculation_pump_power] = 50
    hot_water_distributions_values[0][:pipe_r_value] = 3
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-07.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-07.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-18.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-18.xml', 'NASEO_Technical_Exercises/NASEO-03.xml'].include? hpxml_file
    hot_water_distributions_values[0][:dwhr_facilities_connected] = "all"
    hot_water_distributions_values[0][:dwhr_equal_flow] = true
    hot_water_distributions_values[0][:dwhr_efficiency] = 0.54
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-06.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-17.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-17.xml'].include? hpxml_file
    hot_water_distributions_values[0][:recirculation_control_type] = "manual demand control"
  elsif ['RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-16.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-16.xml'].include? hpxml_file
    hot_water_distributions_values[0][:system_type] = "Recirculation"
    hot_water_distributions_values[0][:recirculation_control_type] = "no control"
    hot_water_distributions_values[0][:recirculation_piping_length] = 156.92
    hot_water_distributions_values[0][:recirculation_branch_piping_length] = 10
    hot_water_distributions_values[0][:recirculation_pump_power] = 50
    hot_water_distributions_values[0][:pipe_r_value] = 3
  elsif ['NASEO_Technical_Exercises/NASEO-02.xml'].include? hpxml_file
    hot_water_distributions_values[0][:system_type] = "Recirculation"
    hot_water_distributions_values[0][:recirculation_control_type] = "no control"
    hot_water_distributions_values[0][:recirculation_piping_length] = 150
    hot_water_distributions_values[0][:recirculation_branch_piping_length] = 10
    hot_water_distributions_values[0][:recirculation_pump_power] = 50
    hot_water_distributions_values[0][:pipe_r_value] = 3
  end
  return hot_water_distributions_values
end

def get_hpxml_file_water_fixtures_values(hpxml_file, water_fixtures_values)
  if ['RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-04.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-04.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    water_fixtures_values = [{ :id => "WF_ID1",
                               :water_fixture_type => "shower head",
                               :low_flow => true },
                             { :id => "WF_ID2",
                               :water_fixture_type => "faucet",
                               :low_flow => true }]
  elsif ['RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml'].include? hpxml_file
    water_fixtures_values = [{ :id => "WF_ID1",
                               :water_fixture_type => "shower head",
                               :low_flow => false },
                             { :id => "WF_ID2",
                               :water_fixture_type => "faucet",
                               :low_flow => false }]
  end
  return water_fixtures_values
end

def get_hpxml_file_clothes_washer_values(hpxml_file, clothes_washers_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    clothes_washers_values << { :id => "ClothesWasher",
                                :location => "living space" }
  elsif ['NASEO_Technical_Exercises/NASEO-09.xml'].include? hpxml_file
    clothes_washers_values[0][:integrated_modified_energy_factor] = 2.2
    clothes_washers_values[0][:rated_annual_kwh] = 150
    clothes_washers_values[0][:label_electric_rate] = 0.11
    clothes_washers_values[0][:label_gas_rate] = 1.1
    clothes_washers_values[0][:label_annual_gas_cost] = 12
    clothes_washers_values[0][:capacity] = 3.3
  elsif ['NASEO_Technical_Exercises/NASEO-09b.xml'].include? hpxml_file
    clothes_washers_values[0][:modified_energy_factor] = 2.593
    clothes_washers_values[0][:rated_annual_kwh] = 150
    clothes_washers_values[0][:label_electric_rate] = 0.11
    clothes_washers_values[0][:label_gas_rate] = 1.1
    clothes_washers_values[0][:label_annual_gas_cost] = 12
    clothes_washers_values[0][:capacity] = 3.3
  end
  return clothes_washers_values
end

def get_hpxml_file_clothes_dryer_values(hpxml_file, clothes_dryers_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    clothes_dryers_values << { :id => "ClothesDryer",
                               :location => "living space",
                               :fuel_type => "natural gas" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    clothes_dryers_values << { :id => "ClothesDryer",
                               :location => "living space",
                               :fuel_type => "electricity" }
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    clothes_dryers_values[0][:fuel_type] = "natural gas"
  elsif ['NASEO_Technical_Exercises/NASEO-09.xml'].include? hpxml_file
    clothes_dryers_values[0][:fuel_type] = "natural gas"
    clothes_dryers_values[0][:combined_energy_factor] = 2.3
    clothes_dryers_values[0][:control_type] = "moisture"
  elsif ['NASEO_Technical_Exercises/NASEO-09b.xml'].include? hpxml_file
    clothes_dryers_values[0][:fuel_type] = "natural gas"
    clothes_dryers_values[0][:energy_factor] = 2.645
    clothes_dryers_values[0][:control_type] = "moisture"
  end
  return clothes_dryers_values
end

def get_hpxml_file_dishwasher_values(hpxml_file, dishwashers_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    dishwashers_values << { :id => "Dishwasher_ID1" }
  elsif ['NASEO_Technical_Exercises/NASEO-10.xml'].include? hpxml_file
    dishwashers_values[0][:energy_factor] = 0.5
    dishwashers_values[0][:place_setting_capacity] = 12
  elsif ['NASEO_Technical_Exercises/NASEO-10b.xml'].include? hpxml_file
    dishwashers_values[0][:rated_annual_kwh] = 430
    dishwashers_values[0][:place_setting_capacity] = 12
  end
  return dishwashers_values
end

def get_hpxml_file_refrigerator_values(hpxml_file, refrigerators_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    refrigerators_values << { :id => "Refrigerator",
                              :location => "living space" }
  elsif ['NASEO_Technical_Exercises/NASEO-11.xml'].include? hpxml_file
    refrigerators_values[0][:rated_annual_kwh] = 614
  end
  return refrigerators_values
end

def get_hpxml_file_cooking_range_values(hpxml_file, cooking_ranges_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml'].include? hpxml_file
    cooking_ranges_values << { :id => "Range_ID1",
                               :fuel_type => "natural gas" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    cooking_ranges_values << { :id => "Range_ID1",
                               :fuel_type => "electricity" }
  elsif ['RESNET_Tests/4.3_HERS_Method/L100A-02.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-03.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-11.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-11.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-02.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-05.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-02.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-03.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-05.xml'].include? hpxml_file
    cooking_ranges_values[0][:fuel_type] = "natural gas"
  elsif ['NASEO_Technical_Exercises/NASEO-12.xml'].include? hpxml_file
    cooking_ranges_values[0][:is_induction] = true
  end
  return cooking_ranges_values
end

def get_hpxml_file_oven_values(hpxml_file, ovens_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    ovens_values << { :id => "Oven_ID1" }
  elsif ['NASEO_Technical_Exercises/NASEO-12.xml'].include? hpxml_file
    ovens_values[0][:is_convection] = true
  end
  return ovens_values
end

def get_hpxml_file_lighting_values(hpxml_file, lightings_values)
  if ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/01-L100.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/02-L100.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/03-L304.xml', 'RESNET_Tests/Other_HERS_AutoGen_IAD_Home/04-L324.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-01.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-02.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AD-HW-03.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-01.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-02.xml', 'RESNET_Tests/Other_Hot_Water_PreAddendumA/L100AM-HW-03.xml'].include? hpxml_file
    lightings_values = [{}]
  elsif ['NASEO_Technical_Exercises/NASEO-05.xml'].include? hpxml_file
    lightings_values = [{ :fraction_tier_i_interior => 0.75,
                          :fraction_tier_i_exterior => 0.75,
                          :fraction_tier_i_garage => 0,
                          :fraction_tier_ii_interior => 0,
                          :fraction_tier_ii_exterior => 0,
                          :fraction_tier_ii_garage => 0 }]
  end
  return lightings_values
end

def get_hpxml_file_plug_load_values(hpxml_file, plug_loads_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    plug_loads_values << { :id => "Misc",
                           :plug_load_type => "other",
                           :kWh_per_year => 7302,
                           :frac_sensible => 0.82,
                           :frac_latent => 0.18 }
  elsif ['RESNET_Tests/4.1_Standard_140/L170AC.xml', 'RESNET_Tests/4.1_Standard_140/L170AL.xml'].include? hpxml_file
    plug_loads_values[0][:kWh_per_year] = 0
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    plug_loads_values = []
  end
  return plug_loads_values
end

def get_hpxml_file_misc_loads_schedule_values(hpxml_file, misc_loads_schedules_values)
  if ['RESNET_Tests/4.1_Standard_140/L100AC.xml', 'RESNET_Tests/4.1_Standard_140/L100AL.xml'].include? hpxml_file
    misc_loads_schedules_values << { :weekday_fractions => "0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066",
                                     :weekend_fractions => "0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066",
                                     :monthly_multipliers => "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0" }
  elsif ['RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/01-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/02-L100.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/03-L304.xml', 'RESNET_Tests/4.2_HERS_AutoGen_Reference_Home/04-L324.xml', 'RESNET_Tests/4.3_HERS_Method/L100A-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AD-HW-01.xml', 'RESNET_Tests/4.6_Hot_Water/L100AM-HW-01.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AC-06.xml', 'RESNET_Tests/Other_HERS_Method_Proposed/L100-AL-06.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-CO-01.xml', 'RESNET_Tests/Other_HERS_Method_Task_Group/L100A-LV-01.xml'].include? hpxml_file
    misc_loads_schedules_values = []
  end
  return misc_loads_schedules_values
end
