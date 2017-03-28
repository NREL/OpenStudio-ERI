# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'rexml/document'
require 'rexml/xpath'

# start the measure
class HPXMLBuildModel < OpenStudio::Measure::ModelMeasure

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
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_file_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute (or relative) path of the HPXML file.")
    arg.setDefaultValue("./resources/audit.xml")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", false)
    arg.setDisplayName("EPW File Path")
    arg.setDescription("Absolute (or relative) path of the EPW weather file to assign. The corresponding DDY file must also be in the same directory.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("measures_dir", true)
    arg.setDisplayName("Residential Measures Directory")
    arg.setDescription("Absolute path of the residential measures.")
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

    hpxml_file_path = runner.getStringArgumentValue("hpxml_file_path", user_arguments)
    weather_file_path = runner.getOptionalStringArgumentValue("weather_file_path", user_arguments)
    weather_file_path.is_initialized ? weather_file_path = weather_file_path.get : weather_file_path = nil
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)

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
    
    # Get file/dir paths
    resources_dir = File.join(File.dirname(__FILE__), "resources")
    helper_methods_file = File.join(resources_dir, "helper_methods.rb")
    
    # Load helper_methods
    require File.join(File.dirname(helper_methods_file), File.basename(helper_methods_file, File.extname(helper_methods_file)))    
    
    # Need to ensure this has the same order as https://github.com/NREL/OpenStudio-Beopt#new-construction-workflow-for-users
    measures_tested = ["ResidentialLocation", 
                       "ResidentialGeometrySingleFamilyDetached", 
                       "ResidentialGeometryNumBedsAndBaths", 
                       "ResidentialGeometryNumOccupants", 
                       "ResidentialConstructionsCeilingsRoofsUnfinishedAttic", 
                       "ResidentialConstructionsFoundationsFloorsSlab", 
                       "ResidentialConstructionsWallsExteriorWoodStud", 
                       "ResidentialConstructionsUninsulatedSurfaces", 
                       "ResidentialHVACFurnaceFuel", 
                       "ResidentialHVACHeatingSetpoints"] # TODO: Remove
    
    # Obtain measures and default arguments
    measures = {}
    Dir.foreach(measures_dir) do |measure_subdir|
      next if !measure_subdir.include? 'Residential'
      next if !measures_tested.include? measure_subdir # TODO: Remove
      full_measure_path = File.join(measures_dir, measure_subdir, "measure.rb")
      check_file_exists(full_measure_path, runner)      
      measure_instance = get_measure_instance(full_measure_path)
      measures[measure_subdir] = default_args_hash(model, measure_instance)
    end
    
    # TODO: Parse hpxml and update measure arguments
    doc = REXML::Document.new(File.read(hpxml_file_path))
    
    event_types = []
    doc.elements.each("*/*/ProjectStatus/EventType") do |el|
      next unless el.text == "audit" # TODO: consider all event types?
      event_types << el.text
    end
    
    # ResidentialLocation
    if weather_file_path.nil?
    
      city_municipality = doc.elements.each("//HPXML/Building[ProjectStatus/EventType='#{event_types[0]}']/Site/Address/CityMunicipality/text()")
      state_code = doc.elements.each("//HPXML/Building[ProjectStatus/EventType='#{event_types[0]}']/Site/Address/StateCode/text()")
      zip_code = doc.elements.each("//HPXML/Building[ProjectStatus/EventType='#{event_types[0]}']/Site/Address/ZipCode/text()")
      
      lat, lng = get_lat_lng_from_address(runner, resources_dir, city_municipality, state_code, zip_code)
      if lat.nil? and lng.nil?
        return false
      end
      
      weather_file_path = File.join(measures["ResidentialLocation"]["weather_directory"], get_epw_from_lat_lng(runner, resources_dir, lat, lng))
      if weather_file_path.nil?
        return false
      end
      runner.registerInfo("Found #{File.expand_path(File.join(measures_dir, "ResidentialLocation", weather_file_path))} based on lat, lng.")
      
    else      
      runner.registerInfo("Found user-specified #{weather_file_path}.")
    end

    measures["ResidentialLocation"]["weather_directory"] = File.dirname(weather_file_path)
    measures["ResidentialLocation"]["weather_file_name"] = File.basename(weather_file_path)
    
    # ResidentialGeometryNumBedsAndBaths
    measures = update_measure_args(doc, measures, "ResidentialGeometryNumBedsAndBaths", "num_bedrooms", "//HPXML/Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms/text()")
    measures = update_measure_args(doc, measures, "ResidentialGeometryNumBedsAndBaths", "num_bathrooms", "//HPXML/Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBathrooms/text()")

    # ResidentialGeometryNumOccupants
    measures = update_measure_args(doc, measures, "ResidentialGeometryNumOccupants", "num_occ", "//HPXML/Building[ProjectStatus/EventType='#{event_types[0]}']/BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents/text()")
    
    # Residentialxx...
    # Residentialyy...
    
    select_measures = {} # TODO: Remove
    measures_tested.each do |k|
      select_measures[k] = measures[k]
    end
    measures = select_measures
    
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
  
  def update_measure_args(doc, measures, measure, arg, xpath)
    new_measure_args = measures[measure]
    val = doc.elements.each(xpath)
    unless val.empty?
      new_measure_args[arg] = val[0].to_s
    end
    measures[measure].update(new_measure_args)
    return measures
  end  
  
  def default_args_hash(model, measure)
    args_hash = {}
    arguments = measure.arguments(model)
    arguments.each do |arg|	
      if arg.hasDefaultValue
        type = arg.type.valueName
        case type
        when "Boolean"
          args_hash[arg.name] = arg.defaultValueAsBool.to_s
        when "Double"
          args_hash[arg.name] = arg.defaultValueAsDouble.to_s
        when "Integer"
          args_hash[arg.name] = arg.defaultValueAsInteger.to_s
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
  
  def get_lat_lng_from_address(runner, resources_dir, city_municipality, state_code, zip_code)
    postalcodes = CSV.read(File.expand_path(File.join(resources_dir, "postalcodes.csv")))
    postalcodes.each do |row|
      if not zip_code.empty?
        if zip_code[0] == row[0]
          return row[4], row[5]
        end
      elsif not city_municipality.empty? and not state_code.empty?
        if city_municipality[0].downcase == row[1].downcase and state_code[0].downcase == row[2].downcase
          return row[4], row[5]
        end
      else
        runner.registerError("Could not find lat, lng from address.")
        return nil, nil
      end
    end
  end
  
  def get_epw_from_lat_lng(runner, resources_dir, lat, lng)
    lat_lng_table = CSV.read(File.expand_path(File.join(resources_dir, "lat_long_table.csv")))
    meters = []
    lat_lng_table.each do |row|
      meters << haversine(lat.to_f, lng.to_f, row[1].to_f, row[2].to_f)
    end
    row = lat_lng_table[meters.each_with_index.min[1]]
    return "USA_CO_Denver_Intl_AP_725650_TMY3.epw" # TODO: Remove
    return row[0]  
  end
  
  def haversine(lat1, long1, lat2, long2)
    dtor = Math::PI/180
    r = 6378.14*1000

    rlat1 = lat1 * dtor 
    rlong1 = long1 * dtor 
    rlat2 = lat2 * dtor 
    rlong2 = long2 * dtor 

    dlon = rlong1 - rlong2
    dlat = rlat1 - rlat2

    a = Math::sin(dlat/2) ** 2 + Math::cos(rlat1) * Math::cos(rlat2) * Math::sin(dlon/2) ** 2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
    d = r * c

    return d
  end
  
end

# register the measure to be used by the application
HPXMLBuildModel.new.registerWithApplication
