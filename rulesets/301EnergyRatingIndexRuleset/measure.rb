# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'oga'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/airflow'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/battery'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constructions'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/geometry'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml_defaults'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac_sizing'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/lighting'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/materials'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/psychrometrics'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/schedules'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/util'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/validator'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/waterheater'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/weather'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'
require_relative 'resources/301'

# start the measure
class EnergyRatingIndex301Measure < OpenStudio::Measure::ModelMeasure
  attr_accessor(:orig_hpxml, :new_hpxml)

  # human readable name
  def name
    return 'Apply Energy Rating Index Ruleset'
  end

  # human readable description
  def description
    return 'Generates a HPXML building description for, e.g., the Reference Home or Rated Home, as defined by the ANSI/RESNET 301-2014 ruleset. Used as part of the calculation of an Energy Rating Index.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the provided HPXML building description and choice of calculation type (e.g., #{Constants.CalcTypeERIReferenceHome}, #{Constants.CalcTypeERIRatedHome}, etc.), creates an updated version of the HPXML file as specified by ANSI/RESNET/ICC 301-2014 \"Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using an Energy Rating Index\"."
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for design type
    calc_types = []
    calc_types << Constants.CalcTypeERIReferenceHome
    calc_types << Constants.CalcTypeERIRatedHome
    calc_types << Constants.CalcTypeERIIndexAdjustmentDesign
    calc_types << Constants.CalcTypeERIIndexAdjustmentReferenceHome
    calc_types << Constants.CalcTypeCO2eReferenceHome
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('calc_type', calc_types, true)
    calc_type.setDisplayName('Calculation Type')
    calc_type.setDefaultValue(Constants.CalcTypeERIRatedHome)
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
      stron_paths = []
      if calc_type == Constants.CalcTypeERIRatedHome # Only need to validate once
        stron_paths << File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'HPXMLvalidator.xml')
        stron_paths << File.join(File.dirname(__FILE__), 'resources', '301validator.xml')
      end
      @orig_hpxml = HPXML.new(hpxml_path: hpxml_input_path, schematron_validators: stron_paths)
      @orig_hpxml.errors.each do |error|
        runner.registerError(error)
      end
      @orig_hpxml.warnings.each do |warning|
        runner.registerWarning(warning)
      end
      return false unless @orig_hpxml.errors.empty?

      # Weather file
      epw_path = @orig_hpxml.climate_and_risk_zones.weather_station_epw_filepath
      if not File.exist? epw_path
        test_epw_path = File.join(File.dirname(hpxml_input_path), epw_path)
        epw_path = test_epw_path if File.exist? test_epw_path
      end
      if not File.exist? epw_path
        test_epw_path = File.join(File.dirname(__FILE__), '..', '..', 'weather', epw_path)
        epw_path = test_epw_path if File.exist? test_epw_path
      end
      if not File.exist?(epw_path)
        fail "'#{epw_path}' could not be found."
      end

      cache_path = epw_path.gsub('.epw', '-cache.csv')
      if not File.exist?(cache_path)
        runner.registerError("'#{cache_path}' could not be found. Perhaps you need to run: openstudio energy_rating_index.rb --cache-weather")
        return false
      end

      # Obtain weather object
      weather = WeatherProcess.new(nil, nil, cache_path)

      # Apply 301 ruleset on HPXML object
      @new_hpxml = EnergyRatingIndex301Ruleset.apply_ruleset(runner, @orig_hpxml, calc_type, weather)

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
EnergyRatingIndex301Measure.new.registerWithApplication
