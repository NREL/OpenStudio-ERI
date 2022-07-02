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
require_relative 'resources/301ruleset'
require_relative 'resources/ESruleset'
require_relative 'resources/ESconstants' # FIXME

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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_input_path', true)
    arg.setDisplayName('HPXML Input File Path')
    arg.setDescription('Absolute (or relative) path of the input HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('init_calc_type', false)
    arg.setDisplayName('Initial Calculation Type(s)')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('calc_type', false)
    arg.setDisplayName('ERI Calculation Type(s)')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_output_paths', false)
    arg.setDisplayName('HPXML Output File Path(s)')
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
    hpxml_input_path = runner.getStringArgumentValue('hpxml_input_path', user_arguments)
    calc_type = runner.getOptionalStringArgumentValue('calc_type', user_arguments).to_s.split(',')
    init_calc_type = runner.getOptionalStringArgumentValue('init_calc_type', user_arguments).to_s.split(',')
    hpxml_output_paths = runner.getOptionalStringArgumentValue('hpxml_output_paths', user_arguments).to_s.split(',')

    num_designs = [calc_type.size, init_calc_type.size, hpxml_output_paths.size].max
    calc_type = [nil] * num_designs if calc_type.empty?
    init_calc_type = [nil] * num_designs if init_calc_type.empty?
    hpxml_output_paths = [nil] * num_designs if hpxml_output_paths.empty?

    if calc_type.size != init_calc_type.size || calc_type.size != hpxml_output_paths.size
      fail 'Unexpected measure arguments.'
    end

    unless (Pathname.new hpxml_input_path).absolute?
      hpxml_input_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_input_path))
    end
    unless File.exist?(hpxml_input_path) && hpxml_input_path.downcase.end_with?('.xml')
      runner.registerError("'#{hpxml_input_path}' does not exist or is not an .xml file.")
      return false
    end

    begin
      stron_paths = []
      stron_paths << File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'HPXMLvalidator.xml')
      stron_paths << File.join(File.dirname(__FILE__), 'resources', '301validator.xml')
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

      # Obtain egrid subregion & cambium gea region
      eri_version = @orig_hpxml.header.eri_calculation_version
      eri_version = Constants.ERIVersions[-1] if eri_version == 'latest'
      egrid_subregion = get_epa_egrid_subregion(runner, @orig_hpxml)
      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019ABCD')
        cambium_gea = get_cambium_gea_region(runner, @orig_hpxml)
      end

      create_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z')

      new_hpxmls = {}
      calc_type.zip(init_calc_type, hpxml_output_paths).each do |this_calc_type, this_init_calc_type, hpxml_output_path|
        # Ensure we don't modify the original HPXML
        @new_hpxml = Marshal.load(Marshal.dump(@orig_hpxml))

        # Apply initial ruleset on HPXML object
        if [ESConstants.CalcTypeEnergyStarReference,
            ESConstants.CalcTypeEnergyStarRated].include? this_init_calc_type
          @new_hpxml = EnergyStarRuleset.apply_ruleset(@new_hpxml, this_init_calc_type)
        end

        if not this_calc_type.nil?
          # Apply 301 ruleset on HPXML object
          @new_hpxml = EnergyRatingIndex301Ruleset.apply_ruleset(runner, @new_hpxml, this_calc_type, weather,
                                                                 egrid_subregion, cambium_gea, create_time)
        end

        # Write new HPXML file
        if not hpxml_output_path.nil?
          new_hpxmls[hpxml_output_path] = XMLHelper.write_file(@new_hpxml.to_oga, hpxml_output_path)
          runner.registerInfo("Wrote file: #{hpxml_output_path}")
        end
      end
    rescue Exception => e
      runner.registerError("#{e.message}\n#{e.backtrace.join("\n")}")
      return false
    end

    duplicates = {}
    new_hpxmls.each_with_index do |(hpxml_output_path, new_hpxml), i|
      next if i == 0

      new_hpxmls.each_with_index do |(hpxml_output_path2, new_hpxml2), j|
        next if j >= i

        if new_hpxml == new_hpxml2
          duplicates[hpxml_output_path] = hpxml_output_path2
        end
      end
    end
    model.getBuilding.additionalProperties.setFeature('Duplicates', duplicates.to_s)

    return true
  end

  def get_epa_egrid_subregion(runner, hpxml)
    egrid_zip_filepath = File.join(File.dirname(__FILE__), 'resources', 'data', 'egrid', 'ZIP_mappings.csv')
    egrid_subregion = lookup_region_from_zip(hpxml.header.zip_code, egrid_zip_filepath, 0, 1)
    if egrid_subregion.nil?
      runner.registerWarning("Could not look up eGRID subregion for zip code: '#{hpxml.header.zip_code}'. Emissions will not be calculated.")
    end
    return egrid_subregion
  end

  def get_cambium_gea_region(runner, hpxml)
    cambium_zip_filepath = File.join(File.dirname(__FILE__), 'resources', 'data', 'cambium', 'ZIP_mappings.csv')
    cambium_gea = lookup_region_from_zip(hpxml.header.zip_code, cambium_zip_filepath, 0, 1)
    if cambium_gea.nil?
      runner.registerWarning("Could not look up Cambium GEA for zip code: '#{hpxml.header.zip_code}'. CO2e emissions will not be calculated.")
    end
    return cambium_gea
  end

  def lookup_region_from_zip(zip_code, zip_filepath, zip_column_index, output_column_index)
    return if zip_code.nil?

    if zip_code.include? '-'
      zip_code = zip_code.split('-')[0]
    end
    zip_code = zip_code.rjust(5, '0')

    return if zip_code.size != 5

    begin
      Integer(zip_code)
    rescue
      return
    end

    CSV.foreach(zip_filepath) do |row|
      fail "Zip code in #{zip_filepath} needs to be 5 digits." if zip_code.size != 5
      next unless row[zip_column_index] == zip_code

      return row[output_column_index]
    end

    return
  end
end

# register the measure to be used by the application
EnergyRatingIndex301Measure.new.registerWithApplication
