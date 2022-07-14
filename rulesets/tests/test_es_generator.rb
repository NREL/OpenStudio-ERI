# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class EnergyStarGeneratorTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_generator
    ESConstants.AllVersions.each do |es_version|
      _convert_to_es('base-misc-generators.xml', es_version)
      hpxml = _test_ruleset()
      _check_generator(hpxml)
    end
  end

  def _test_ruleset()
    require_relative '../../workflow/design'
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    designs = [Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference)]

    success, _, hpxml = run_rulesets(runner, @tmp_hpxml_path, designs)

    runner.result.stepErrors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    return hpxml
  end

  def _check_generator(hpxml)
    assert_equal(0, hpxml.generators.size)
  end

  def _convert_to_es(hpxml_name, program_version, state_code = nil)
    return convert_to_es(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
