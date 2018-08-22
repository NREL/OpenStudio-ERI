# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'rexml/document'
require 'rexml/xpath'
require 'pathname'
require 'csv'
require "#{File.dirname(__FILE__)}/resources/301"
require "#{File.dirname(__FILE__)}/resources/301validator"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/xmlhelper"

# start the measure
class EnergyRatingIndex301 < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Apply Energy Rating Index Ruleset"
  end

  # human readable description
  def description
    return "Generates a HPXML building description for, e.g., the Reference Home or Rated Home, as defined by the ANSI/RESNET 301-2014 ruleset. Used as part of the calculation of an Energy Rating Index."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the provided HPXML building description and choice of calculation type (e.g., #{Constants.CalcTypeERIReferenceHome}, #{Constants.CalcTypeERIRatedHome}, etc.), creates an updated version of the HPXML file as specified by ANSI/RESNET 301-2014 \"Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index\"."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for design type
    calc_types = []
    #calc_types << Constants.CalcTypeStandard
    calc_types << Constants.CalcTypeERIReferenceHome
    calc_types << Constants.CalcTypeERIRatedHome
    calc_types << Constants.CalcTypeERIIndexAdjustmentDesign
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("calc_type", calc_types, true)
    calc_type.setDisplayName("Calculation Type")
    calc_type.setDescription("'#{Constants.CalcTypeStandard}' will use the DOE Building America Simulation Protocols. HERS options will use the ANSI/RESNET 301-2014 Standard.")
    calc_type.setDefaultValue(Constants.CalcTypeStandard)
    args << calc_type

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute (or relative) path of the HPXML file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_dir", true)
    arg.setDisplayName("Weather Directory")
    arg.setDescription("Absolute path of the weather directory.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("schemas_dir", false)
    arg.setDisplayName("HPXML Schemas Directory")
    arg.setDescription("Absolute path of the hpxml schemas directory.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_output_path", false)
    arg.setDisplayName("HPXML Output File Path")
    arg.setDescription("Absolute (or relative) path of the output HPXML file.")
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
    calc_type = runner.getStringArgumentValue("calc_type", user_arguments)
    hpxml_path = runner.getStringArgumentValue("hpxml_path", user_arguments)
    weather_dir = runner.getStringArgumentValue("weather_dir", user_arguments)
    schemas_dir = runner.getOptionalStringArgumentValue("schemas_dir", user_arguments)
    hpxml_output_path = runner.getOptionalStringArgumentValue("hpxml_output_path", user_arguments)

    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end 
    unless File.exists?(hpxml_path) and hpxml_path.downcase.end_with? ".xml"
      runner.registerError("'#{hpxml_path}' does not exist or is not an .xml file.")
      return false
    end
    
    if schemas_dir.is_initialized
      schemas_dir = schemas_dir.get
      unless (Pathname.new schemas_dir).absolute?
        schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
      end
      unless Dir.exists?(schemas_dir)
        runner.registerError("'#{schemas_dir}' does not exist.")
        return false
      end
    else
      schemas_dir = nil
    end
    
    hpxml_doc = REXML::Document.new(File.read(hpxml_path))
    
    # Validate input HPXML against schema
    if not schemas_dir.nil?
      has_errors = false
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        runner.registerError("Input HPXML: #{error.to_s}")
        has_errors = true
      end
      if has_errors
        return false
      end
      runner.registerInfo("Validated input HPXML against schema.")
    else
      runner.registerWarning("No schema dir provided, no HPXML validation performed.")
    end
    
    # Validate input HPXML against ERI Use Case
    errors = EnergyRatingIndex301Validator.run_validator(hpxml_doc)
    errors.each do |error|
      runner.registerError(error)
    end
    unless errors.empty?
      return false
    end
    runner.registerInfo("Validated input HPXML against ERI Use Case.")
    
    # Weather file
    weather_wmo = XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation/WMO")
    epw_path = nil
    cache_path = nil
    CSV.foreach(File.join(weather_dir, "data.csv"), headers:true) do |row|
      next if row["wmo"] != weather_wmo
      epw_path = File.join(weather_dir, row["filename"])
      if not File.exists?(epw_path)
        runner.registerError("'#{epw_path}' could not be found. Perhaps you need to run: openstudio energy_rating_index.rb --download-weather")
        return false
      end
      cache_path = epw_path.gsub('.epw','.cache')
      if not File.exists?(cache_path)
        runner.registerError("'#{cache_path}' could not be found. Perhaps you need to run: openstudio energy_rating_index.rb --download-weather")
        return false
      end
      break
    end
    if epw_path.nil?
      runner.registerError("Weather station WMO '#{weather_wmo}' could not be found in weather/data.csv.")
      return false
    end
    
    # Obtain weather object
    weather = Marshal.load(File.binread(cache_path))
    
    # Apply 301 ruleset on HPXML object
    EnergyRatingIndex301Ruleset.apply_ruleset(hpxml_doc, calc_type, weather)
    
    # Write new HPXML file
    if hpxml_output_path.is_initialized
      XMLHelper.write_file(hpxml_doc, hpxml_output_path.get)
      runner.registerInfo("Wrote file: #{hpxml_output_path.get}")
    end
    
    # Validate output HPXML against schema
    if not schemas_dir.nil?
      has_errors = false
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        runner.registerError("Output HPXML: #{error.to_s}")
        has_errors = true
      end
      if has_errors
        return false
      end
      runner.registerInfo("Validated output HPXML.")
    else
      runner.registerWarning("No schema dir provided, no HPXML validation performed.")
    end
    
    # Validate output HPXML against ERI Use Case
    errors = EnergyRatingIndex301Validator.run_validator(hpxml_doc)
    errors.each do |error|
      runner.registerError(error)
    end
    unless errors.empty?
      return false
    end
    runner.registerInfo("Validated output HPXML against ERI Use Case.")
    
    return true

  end
  
end

# register the measure to be used by the application
EnergyRatingIndex301.new.registerWithApplication
