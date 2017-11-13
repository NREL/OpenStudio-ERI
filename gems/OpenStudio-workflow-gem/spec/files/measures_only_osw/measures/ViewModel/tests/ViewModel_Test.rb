require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'minitest/autorun'

class ViewModel_Test < MiniTest::Unit::TestCase
    
  # paths to expected test files, includes osm and eplusout.sql
  def modelPath
    #return "#{File.dirname(__FILE__)}/SimpleModel.osm"
    return "#{File.dirname(__FILE__)}/ExampleModel.osm"
  end

  def reportPath
    return 'output/report.json'
  end
  
  # create test files if they do not exist
  def setup

    if File.exist?(reportPath())
      FileUtils.rm(reportPath())
    end
    
    assert(File.exist?(modelPath()))
  end

  # delete output files
  def teardown
    
    # comment this out if you want to see the resulting report
    if File.exist?(reportPath())
      #FileUtils.rm(reportPath())
    end
  end
  
  # the actual test
  def test_ViewModel
     
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    assert(File.exist?(modelPath()))
    model = translator.loadModel(modelPath())
    assert((not model.empty?))
    model = model.get
    
    # create an instance of the measure
    measure = ViewModel.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(0, arguments.size)

    current_dir = Dir.pwd
    run_dir = File.dirname(__FILE__) + '/output'
    FileUtils.rm_rf(run_dir) if File.exists?(run_dir)
    FileUtils.mkdir_p(run_dir)
    Dir.chdir(run_dir)
    
    # set argument values to good values and run the measure
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'NA')
    assert(result.warnings.size == 0)
    #assert(result.info.size == 1)
    
    Dir.chdir(current_dir)
    
    assert(File.exist?(reportPath()))
    
    # load the output in http://threejs.org/editor/ to test
    
  end  

end
