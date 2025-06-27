# frozen_string_literal: true

require 'pathname'
require 'csv'
require 'oga'
Dir["#{File.dirname(__FILE__)}/../hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  require resource_file
end

def run_rulesets(hpxml_input_path, designs, schema_validator = nil, schematron_validator = nil)
  errors, warnings = [], []

  unless (Pathname.new hpxml_input_path).absolute?
    hpxml_input_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_input_path))
  end
  unless File.exist?(hpxml_input_path) && hpxml_input_path.downcase.end_with?('.xml')
    errors << "'#{hpxml_input_path}' does not exist or is not an .xml file."
    return false, errors, warnings
  end

  begin
    if schema_validator.nil?
      schema_path = File.join(File.dirname(__FILE__), '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
      schema_validator = XMLValidator.get_xml_validator(schema_path)
    end
    if schematron_validator.nil?
      schematron_path = File.join(File.dirname(__FILE__), 'resources', '301validator.sch')
      schematron_validator = XMLValidator.get_xml_validator(schematron_path)
    end
    orig_hpxml = HPXML.new(hpxml_path: hpxml_input_path, schema_validator: schema_validator, schematron_validator: schematron_validator)
    orig_hpxml.errors.each do |error|
      errors << error
    end
    orig_hpxml.warnings.each do |warning|
      warnings << warning
    end
    return false, errors, warnings unless orig_hpxml.errors.empty?

    orig_hpxml_bldg = orig_hpxml.buildings[0]

    # Weather file
    epw_path = orig_hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath
    if epw_path.nil?
      weather_data = Defaults.lookup_weather_data_from_zipcode(orig_hpxml_bldg.zip_code)
      epw_path = weather_data[:station_filename]
    end
    if not File.exist? epw_path
      test_epw_path = File.join(File.dirname(hpxml_input_path), epw_path)
      epw_path = test_epw_path if File.exist? test_epw_path
    end
    if not File.exist? epw_path
      test_epw_path = File.join(File.dirname(__FILE__), '..', 'weather', epw_path)
      epw_path = test_epw_path if File.exist? test_epw_path
    end
    if not File.exist?(epw_path)
      errors << "'#{epw_path}' could not be found."
      return false, errors, warnings
    end

    # Obtain weather object
    weather = WeatherFile.new(epw_path: epw_path, runner: nil)

    zip_code = orig_hpxml_bldg.zip_code
    egrid_subregion = get_epa_egrid_subregion(zip_code)
    if egrid_subregion.nil?
      warnings << "Could not look up eGRID subregion for zip code: '#{zip_code}'. Emissions will not be calculated."
    end
    cambium_gea = get_cambium_gea_region(zip_code)
    if cambium_gea.nil?
      warnings << "Could not look up Cambium GEA for zip code: '#{zip_code}'. CO2e emissions will not be calculated."
    end

    lookup_program_data = {}
    init_hpxmls_written = []

    create_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z')

    new_hpxml_blgs = {}
    hpxml_strings = {}
    designs.each do |design|
      # Ensure we don't modify the original HPXML
      new_hpxml = Marshal.load(Marshal.dump(orig_hpxml))

      # Determine 301 version for ERI calculations
      iecc_version = nil
      if [RunType::IECC].include? design.run_type
        iecc_version = design.version
        if ['2015', '2018'].include? design.version
          # Use 2014 w/ all addenda
          eri_version = Constants::ERIVersions.select { |v| v.include? '2014' }[-1]
        elsif ['2021'].include? design.version
          # Use 2019 w/ all addenda
          eri_version = Constants::ERIVersions.select { |v| v.include? '2019' }[-1]
        elsif ['2024'].include? design.version
          # Use 2022 w/ all addenda
          eri_version = Constants::ERIVersions.select { |v| v.include? '2022' }[-1]
        else
          fail "Unhandled IECC version: #{design.version}."
        end
      elsif [RunType::ES, RunType::ZERH].include? design.run_type
        # Use latest ANSI version/addenda
        eri_version = Constants::ERIVersions[-2]
      elsif [RunType::ERI, RunType::CO2e].include? design.run_type
        eri_version = design.version
      else
        fail 'Unexpected design run type.'
      end
      if eri_version.nil?
        fail 'Unexpected error; ERI version not set.'
      end

      # Set egrid subregion & cambium gea region
      design_egrid_subregion = egrid_subregion
      if (not eri_version.nil?) && (Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2019ABCD'))
        design_cambium_gea = cambium_gea
      else
        design_cambium_gea = nil
      end

      # Apply initial ruleset on HPXML object
      if not design.init_calc_type.nil?
        if design.run_type == RunType::ES
          lookup_program = 'es_' + design.version.gsub('.', '_').downcase
        elsif design.run_type == RunType::ZERH
          lookup_program = 'zerh_' + design.version.gsub('.', '_').downcase
        end
        if (not lookup_program.nil?) && lookup_program_data[lookup_program].nil?
          lookup_program_data[lookup_program] = CSV.read(File.join(File.dirname(__FILE__), "data/#{lookup_program}_lookup.tsv"), headers: true, col_sep: "\t")
        end
        new_hpxml = ES_ZERH_Ruleset.apply_ruleset(new_hpxml, design.init_calc_type, design.version, eri_version, lookup_program_data[lookup_program])
      end

      # Write initial HPXML file
      if not design.init_hpxml_output_path.nil?
        if not init_hpxmls_written.include?(design.init_hpxml_output_path)
          XMLHelper.write_file(new_hpxml.to_doc, design.init_hpxml_output_path)
          init_hpxmls_written << design.init_hpxml_output_path
        end
      end

      # Apply 301 ruleset on HPXML object
      if not design.calc_type.nil?
        new_hpxml = ERI_301_Ruleset.apply_ruleset(new_hpxml, design.run_type, design.calc_type, weather, eri_version, iecc_version, design_egrid_subregion, design_cambium_gea, create_time)
      end
      new_hpxml_blgs[[design.run_type, design.calc_type]] = new_hpxml.buildings[0]

      # Write final HPXML file
      if (not design.hpxml_output_path.nil?) && (not design.calc_type.nil?)
        hpxml_strings[design.hpxml_output_path] = XMLHelper.write_file(new_hpxml.to_doc, design.hpxml_output_path)
        fail 'Unexpected error.' unless hpxml_strings[design.hpxml_output_path].is_a?(String)
      end
    end
  rescue Exception => e
    errors << "#{e.message}\n#{e.backtrace.join("\n")}"
    return false, errors, warnings
  end

  # Check for duplicate HPXML files
  duplicates = {}
  hpxml_strings.each_with_index do |(hpxml_output_path, new_hpxml), i|
    next if i == 0

    hpxml_strings.each_with_index do |(hpxml_output_path2, new_hpxml2), j|
      next if j >= i

      if new_hpxml == new_hpxml2
        duplicates[hpxml_output_path] = hpxml_output_path2
        break
      end
    end
  end

  # Issue warning if equipment autosizing is used
  has_autosizing = false
  orig_hpxml_bldg.hvac_systems.each do |hvac_system|
    if hvac_system.respond_to?(:heating_capacity) && hvac_system.heating_capacity == -1
      has_autosizing = true
    end
    if hvac_system.respond_to?(:cooling_capacity) && hvac_system.cooling_capacity == -1
      has_autosizing = true
    end
    if hvac_system.respond_to?(:backup_heating_capacity) && hvac_system.backup_heating_capacity == -1
      has_autosizing = true
    end
    if hvac_system.respond_to?(:integrated_heating_system_capacity) && hvac_system.integrated_heating_system_capacity == -1
      has_autosizing = true
    end
  end
  if has_autosizing
    warnings << 'Autosized HVAC equipment (e.g., Capacity=-1) found in the HPXML. This should only be used for research purposes or to run tests. It should *not* be used for a real home.'
  end

  return true, errors, warnings, duplicates, new_hpxml_blgs
end

def get_epa_egrid_subregion(zip_code)
  egrid_zip_filepath = File.join(File.dirname(__FILE__), 'data', 'egrid', 'ZIP_mappings.csv')
  egrid_subregion = lookup_region_from_zip(zip_code, egrid_zip_filepath, 0, 1)
  return egrid_subregion
end

def get_cambium_gea_region(zip_code)
  cambium_zip_filepath = File.join(File.dirname(__FILE__), 'data', 'cambium', 'ZIP_mappings.csv')
  cambium_gea = lookup_region_from_zip(zip_code, cambium_zip_filepath, 0, 1)
  return cambium_gea
end

def lookup_region_from_zip(zipcode, zip_filepath, zip_column_index, output_column_index)
  return if zipcode.nil?

  # Gets the region for the specified zipcode. If the exact zipcode is not found, we
  # find the closest zipcode that shares the first 3 digits.
  begin
    zipcode3 = zipcode[0, 3]
    zipcode_int = Integer(Float(zipcode[0, 5])) # Convert to 5-digit integer
  rescue
    fail "Unexpected zip code: #{zipcode}."
  end

  # Note: We don't use the CSV library here because it's slow for large files
  zip_distance = 99999 # init
  region = nil
  File.foreach(zip_filepath) do |row|
    row = row.strip.split(',')
    next unless row[zip_column_index].start_with?(zipcode3) # Only allow match if first 3 digits are the same

    distance = (Integer(Float(row[0])) - zipcode_int).abs() # Find closest zip code
    if distance < zip_distance
      zip_distance = distance
      region = row[output_column_index]
    end
    if distance == 0
      return region # Exact match
    end
  end

  return region
end
