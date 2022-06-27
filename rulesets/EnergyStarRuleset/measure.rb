# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'oga'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/airflow'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/weather'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlvalidator'
require_relative 'resources/EnergyStarRuleset'
require_relative 'resources/constants'

# start the measure
class EnergyStarMeasure < OpenStudio::Measure::ModelMeasure
  attr_accessor(:orig_hpxml, :new_hpxml)

  # human readable name
  def name
    return 'Apply ENERGY STAR Ruleset'
  end

  # human readable description
  def description
    return 'Generates a HPXML building description for, e.g., the Reference Home or Rated Home, based on the ENERGY STAR requirements.'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for design type
    calc_types = []
    calc_types << ESConstants.CalcTypeEnergyStarRated
    calc_types << ESConstants.CalcTypeEnergyStarReference
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('calc_type', calc_types, true)
    calc_type.setDisplayName('Calculation Type')
    calc_type.setDefaultValue(ESConstants.CalcTypeEnergyStarReference)
    args << calc_type

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_input_path', true)
    arg.setDisplayName('HPXML Input File Path')
    arg.setDescription('Absolute (or relative) path of the input HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_output_path', false)
    arg.setDisplayName('HPXML Output File Path')
    arg.setDescription('Absolute (or relative) path of the output HPXML file.')
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
    calc_type = runner.getStringArgumentValue('calc_type', user_arguments)
    hpxml_input_path = runner.getStringArgumentValue('hpxml_input_path', user_arguments)
    hpxml_output_path = runner.getOptionalStringArgumentValue('hpxml_output_path', user_arguments)

    unless (Pathname.new hpxml_input_path).absolute?
      hpxml_input_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_input_path))
    end
    unless File.exist?(hpxml_input_path) && hpxml_input_path.downcase.end_with?('.xml')
      runner.registerError("'#{hpxml_input_path}' does not exist or is not an .xml file.")
      return false
    end

    begin
      if calc_type == ESConstants.CalcTypeEnergyStarRated # Only need to validate once
        xsd_path = File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
        stron_path = File.join(File.dirname(__FILE__), '..', '301EnergyRatingIndexRuleset', 'resources', '301validator.xml')
      end
      @orig_hpxml = HPXML.new(hpxml_path: hpxml_input_path, schema_path: xsd_path, schematron_path: stron_path)
      @orig_hpxml.errors.each do |error|
        runner.registerError(error)
      end
      @orig_hpxml.warnings.each do |warning|
        runner.registerWarning(warning)
      end
      return false unless @orig_hpxml.errors.empty?

      # Apply ENERGY STAR ruleset on HPXML object
      @new_hpxml = EnergyStarRuleset.apply_ruleset(@orig_hpxml, calc_type)

      # Write new HPXML file
      if hpxml_output_path.is_initialized
        XMLHelper.write_file(@new_hpxml.to_oga, hpxml_output_path.get)
        runner.registerInfo("Wrote file: #{hpxml_output_path.get}")
      end
    rescue Exception => e
      runner.registerError("#{e.message}\n#{e.backtrace.join("\n")}")
      return false
    end

    return true
  end
end

# register the measure to be used by the application
EnergyStarMeasure.new.registerWithApplication
