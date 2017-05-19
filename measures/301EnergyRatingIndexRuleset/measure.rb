# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require "#{File.dirname(__FILE__)}/resources/301"
require "#{File.dirname(__FILE__)}/resources/hpxml"
require "#{File.dirname(__FILE__)}/resources/constants"

# start the measure
class EnergyRatingIndex301 < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Generate Energy Rating Index Model"
  end

  # human readable description
  def description
    return "Generates a model from a HPXML building description as defined by the ANSI/RESNET 301-2014 ruleset. Used as part of the caclulation of an Energy Rating Index."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the provided HPXML building description and choice of calculation type (e.g., #{Constants.CalcTypeERIReferenceHome}, #{Constants.CalcTypeERIRatedHome}, etc.), creates an updated version of the HPXML file as well as an OpenStudio model, as specified by ANSI/RESNET 301-2014 \"Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index\"."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for design type
    calc_types = []
    calc_types << Constants.CalcTypeERIReferenceHome
    calc_types << Constants.CalcTypeERIRatedHome
    #calc_types << Constants.CalcTypeERIIndexAdjustmentDesign
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("calc_type", calc_types, true)
    calc_type.setDisplayName("Calculation Type")
    calc_type.setDescription("'#{Constants.CalcTypeStandard}' will use the DOE Building America Simulation Protocols. HERS options will use the ANSI/RESNET 301-2014 Standard.")
    calc_type.setDefaultValue(Constants.CalcTypeStandard)
    args << calc_type

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_file_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute (or relative) path of the HPXML file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", true)
    arg.setDisplayName("EPW File Path")
    arg.setDescription("Absolute (or relative) path of the EPW weather file to assign. The corresponding DDY file must also be in the same directory.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("measures_dir", true)
    arg.setDisplayName("Residential Measures Directory")
    arg.setDescription("Absolute path of the residential measures.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_api_key", false)
    arg.setDisplayName("HPXML API Key")
    arg.setDescription("The API key is needed to validate HPXML files and can be obtained at https://hpxml.nrel.gov/. Alternatively, you can set an environment variable on your system called HPXML_API_KEY.")
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
    hpxml_file_path = runner.getStringArgumentValue("hpxml_file_path", user_arguments)
    weather_file_path = runner.getStringArgumentValue("weather_file_path", user_arguments)
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)
    hpxml_api_key = runner.getOptionalStringArgumentValue("hpxml_api_key", user_arguments)

    unless (Pathname.new hpxml_file_path).absolute?
      hpxml_file_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_file_path))
    end 
    unless File.exists?(hpxml_file_path) and hpxml_file_path.downcase.end_with? ".xml"
      runner.registerError("'#{hpxml_file_path}' does not exist or is not an .xml file.")
      return false
    end
    
    unless weather_file_path.nil?
      unless (Pathname.new weather_file_path).absolute?
        weather_file_path = File.expand_path(File.join(File.dirname(__FILE__), weather_file_path))
      end
      unless File.exists?(weather_file_path) and weather_file_path.downcase.end_with? ".epw"
        runner.registerError("'#{weather_file_path}' does not exist or is not an .epw file.")
        return false
      end
    end
    
    unless (Pathname.new measures_dir).absolute?
      measures_dir = File.expand_path(File.join(File.dirname(__FILE__), measures_dir))
    end
    unless Dir.exists?(measures_dir)
      runner.registerError("'#{measures_dir}' does not exist.")
      return false
    end
    
    if hpxml_api_key.is_initialized
        hpxml_api_key = hpxml_api_key.get
    else
        # Try HPXML_API_KEY environment variable
        hpxml_api_key = ENV['HPXML_API_KEY']
        if hpxml_api_key.nil?
            runner.registerWarning("HPXML API key not found. Will proceed with validation.")
        end
    end
    
    hpxml_doc = REXML::Document.new(File.read(hpxml_file_path))
    
    # Validate input HPXML
    if not validate_hpxml(runner, hpxml_doc.to_s, hpxml_api_key, true)
        return false
    end
    
    # Apply 301 ruleset on HPXML object
    errors, building = EnergyRatingIndex301Ruleset.apply_ruleset(hpxml_doc, calc_type)
    
    # Write HPXML file
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    formatter.width = 1000
    hpxml_path = File.join(File.dirname(__FILE__), "301.xml")
    #File.open(hpxml_path, 'w') do |f|
    #  formatter.write(hpxml_doc, f)
    #end
    
    # Validate new HPXML
    if not validate_hpxml(runner, hpxml_doc.to_s, hpxml_api_key, false)
        return false
    end
    
    # Obtain list of OpenStudio measures (and arguments)
    errors, measures = OSMeasures.build_measure_args_from_hpxml(building, weather_file_path, calc_type)
	
    errors.each do |error|
      runner.registerError(error)
    end

    unless errors.empty?
      return false
    end
    
    # Create OpenStudio model
    if not OSModel.create_geometry(building, runner, model)
      return false
    end
    if not OSModel.apply_measures(measures_dir, measures, runner, model)
      return false
    end
    
    return true

  end
  
  def validate_hpxml(runner, hpxml_str, hpxml_api_key, is_input)
  
    return true if hpxml_api_key.nil?
  
    uri = URI.parse("https://hpxml.nrel.gov/api/#{hpxml_api_key}/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'text/xml'
    request.body = hpxml_str
    
    response = http.request(request)
    response_json = JSON.parse(response.body)
    
    if not response_json['HPXMLSchema']['valid']
        str = "Invalid HPXML file provided."
        if !is_input
            str = "Invalid HPXML file produced. Please report this to the development team."
        end
        runner.registerError("#{str} #{response_json['HPXMLSchema']['errors'].join('\n')}")
        return false
    end
    
    return true
  end
  
end

# register the measure to be used by the application
EnergyRatingIndex301.new.registerWithApplication
