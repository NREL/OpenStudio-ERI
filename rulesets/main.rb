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

def run_rulesets(hpxml_input_path, designs)
  errors, warnings = [], []

  unless (Pathname.new hpxml_input_path).absolute?
    hpxml_input_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_input_path))
  end
  unless File.exist?(hpxml_input_path) && hpxml_input_path.downcase.end_with?('.xml')
    errors << "'#{hpxml_input_path}' does not exist or is not an .xml file."
    return false, errors, warnings
  end

  begin
    xsd_path = File.join(File.dirname(__FILE__), '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    stron_path = File.join(File.dirname(__FILE__), 'resources', '301validator.xml')
    orig_hpxml = HPXML.new(hpxml_path: hpxml_input_path, schema_path: xsd_path, schematron_path: stron_path)
    orig_hpxml.errors.each do |error|
      errors << error
    end
    orig_hpxml.warnings.each do |warning|
      warnings << warning
    end
    return false, errors, warnings unless orig_hpxml.errors.empty?

    # Weather file
    epw_path = orig_hpxml.climate_and_risk_zones.weather_station_epw_filepath
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

    cache_path = epw_path.gsub('.epw', '-cache.csv')
    if not File.exist?(cache_path)
      errors << "'#{cache_path}' could not be found. Perhaps you need to run: openstudio energy_rating_index.rb --cache-weather"
      return false, errors, warnings
    end

    # Obtain weather object
    weather = WeatherProcess.new(nil, nil, cache_path)

    eri_version = orig_hpxml.header.eri_calculation_version
    eri_version = Constants.ERIVersions[-1] if eri_version == 'latest'
    zip_code = orig_hpxml.header.zip_code
    if not eri_version.nil?
      # Obtain egrid subregion & cambium gea region
      egrid_subregion = get_epa_egrid_subregion(zip_code)
      if not egrid_subregion.nil?
        warnings << "Could not look up eGRID subregion for zip code: '#{zip_code}'. Emissions will not be calculated."
      end
      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019ABCD')
        cambium_gea = get_cambium_gea_region(zip_code)
        if not cambium_gea.nil?
          warnings << "Could not look up Cambium GEA for zip code: '#{zip_code}'. CO2e emissions will not be calculated."
        end
      end
    end

    create_time = Time.now.strftime('%Y-%m-%dT%H:%M:%S%:z')

    last_hpxml = nil
    hpxml_strings = {}
    designs.each do |design|
      # Ensure we don't modify the original HPXML
      new_hpxml = Marshal.load(Marshal.dump(orig_hpxml))

      # Apply initial ruleset on HPXML object
      if [ESConstants.CalcTypeEnergyStarReference,
          ESConstants.CalcTypeEnergyStarRated,
          ZERHConstants.CalcTypeZERHReference,
          ZERHConstants.CalcTypeZERHRated].include? design.init_calc_type
        new_hpxml = EnergyStarZeroEnergyReadyHomeRuleset.apply_ruleset(new_hpxml, design.init_calc_type)
      end

      # Write initial HPXML file
      if not design.init_hpxml_output_path.nil?
        if not File.exist? design.init_hpxml_output_path
          XMLHelper.write_file(new_hpxml.to_oga, design.init_hpxml_output_path)
        end
      end

      # Apply 301 ruleset on HPXML object
      if not design.calc_type.nil?
        new_hpxml = EnergyRatingIndex301Ruleset.apply_ruleset(new_hpxml, design.calc_type, weather,
                                                              design.iecc_version, egrid_subregion, cambium_gea, create_time)
      end
      last_hpxml = new_hpxml

      # Write final HPXML file
      if not design.hpxml_output_path.nil?
        hpxml_strings[design.hpxml_output_path] = XMLHelper.write_file(new_hpxml.to_oga, design.hpxml_output_path)
      end
    end
  rescue Exception => e
    errors << "#{e.message}\n#{e.backtrace.join("\n")}"
    return false, errors, warnings
  end

  # Check for duplicate HPXML files

  # First, replace IECC year strings so that we don't miss a duplicate just because the year is different
  hpxml_strings.keys.each do |k|
    hpxml_strings[k] = hpxml_strings[k].gsub(/<Year>.*<\/Year>/, '')
  end

  # Now identify duplicates
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

  return true, errors, warnings, duplicates, last_hpxml
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
