# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'
require 'rexml/xpath'

# start the measure
class HPXMLBuildModel < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "HPXML Build Model"
  end

  # human readable description
  def description
    return "E+ RESNET"
  end

  # human readable description of modeling approach
  def modeler_description
    return "E+ RESNET"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument("hpxml_directory", true)
    arg.setDisplayName("HPXML Directory")
    arg.setDescription("Absolute (or relative) directory to HPXML files.")
    arg.setDefaultValue("./resources")
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument("hpxml_file_name", true)
    arg.setDisplayName("HPXML File Name")
    arg.setDescription("Name of the HPXML file.")
    arg.setDefaultValue("audit.xml")
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

    hpxml_directory = runner.getStringArgumentValue("hpxml_directory", user_arguments)
    hpxml_file_name = runner.getStringArgumentValue("hpxml_file_name", user_arguments)    

    unless (Pathname.new hpxml_directory).absolute?
      hpxml_directory = File.expand_path(File.join(File.dirname(__FILE__), hpxml_directory))
    end
    hpxml_file = File.join(hpxml_directory, hpxml_file_name)    

    # Get file/dir paths
    resources_dir = File.join(File.dirname(__FILE__), "resources")
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    measures_dir = File.join(resources_dir, "measures")
    measures_zip = OpenStudio::toPath(File.join(resources_dir, "measures.zip"))
    unzip_file = OpenStudio::UnzipFile.new(measures_zip)
    unzip_file.extractAllFiles(OpenStudio::toPath(measures_dir))
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))    
    
    # Obtain measures and default arguments
    measures = {}
    Dir.foreach(measures_dir) do |measure_subdir|
      next if !measure_subdir.include? 'Residential'
      next if !measure_subdir.include? 'ResidentialLocation' # TODO: remove
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
      check_file_exists(full_measure_path, runner)      
      measure_instance = get_measure_instance(full_measure_path)
      measures[measure_subdir] = default_args_hash(model, measure_instance)
    end
    
    # Parse hpxml and update measure arguments    
    doc = REXML::Document.new(File.read(hpxml_file))
    zip = REXML::XPath.first(doc, '//HPXML/Building/Site/Address/ZipCode').text
    
    measures = measures.select {|k, v| k == "ResidentialLocation"} # TODO: remove
    
    # Call each measure for sample to build up model
    measures.keys.each do |measure_subdir|
      next if measure_subdir == "ResidentialAirflowOriginalModel" # Temporary while Airflow is an EnergyPlus measure
      # Gather measure arguments and call measure
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")      
      measure_instance = get_measure_instance(full_measure_path)
      argument_map = get_argument_map(model, measure_instance, measures[measure_subdir], measure_subdir, runner)
      print_measure_call(measures[measure_subdir], measure_subdir, runner)

      if not run_measure(model, measure_instance, argument_map, runner)
        return false
      end
    end
    
    return true

  end  
  
  def default_args_hash(model, measure)
    args_hash = {}
    arguments = measure.arguments(model)
    arguments.each do |arg|	
      if arg.hasDefaultValue
        type = arg.type.valueName
        case type
        when "Boolean"
          args_hash[arg.name] = arg.defaultValueAsBool
        when "Double"
          args_hash[arg.name] = arg.defaultValueAsDouble
        when "Integer"
          args_hash[arg.name] = arg.defaultValueAsInteger
        when "String"
          args_hash[arg.name] = arg.defaultValueAsString
        when "Choice"
          args_hash[arg.name] = arg.defaultValueAsString
        end
      else
        args_hash[arg.name] = nil
      end
    end
    return args_hash
  end  
  
end

# register the measure to be used by the application
HPXMLBuildModel.new.registerWithApplication
