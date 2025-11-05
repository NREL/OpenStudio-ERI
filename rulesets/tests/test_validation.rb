# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlvalidator.rb'
require_relative '../../workflow/design'

class ERI301ValidationTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.absolute_path(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')))
    @schematron_path = File.join(@root_path, 'rulesets', 'resources', '301validator.sch')
    @schematron_validator = XMLValidator.get_xml_validator(@schematron_path)

    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
    puts
  end

  def test_validation_of_schematron_doc
    # Check that the schematron file is valid

    schematron_schema_path = File.absolute_path(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'iso-schematron.xsd'))
    schematron_schema_validator = XMLValidator.get_xml_validator(schematron_schema_path)
    _test_schema_validation(@schematron_path, schematron_schema_validator)
  end

  def test_role_attributes_in_schematron_doc
    # Test for consistent use of errors/warnings
    puts
    puts 'Checking for correct role attributes...'

    schematron_doc = XMLHelper.parse_file(@schematron_path)

    # check that every assert element has a role attribute
    XMLHelper.get_elements(schematron_doc, '/sch:schema/sch:pattern/sch:rule/sch:assert').each do |assert_element|
      assert_test = XMLHelper.get_attribute_value(assert_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(assert_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='ERROR'\" found for assertion test: #{assert_test}"
      end

      assert_equal('ERROR', role_attribute)
    end

    # check that every report element has a role attribute
    XMLHelper.get_elements(schematron_doc, '/sch:schema/sch:pattern/sch:rule/sch:report').each do |report_element|
      report_test = XMLHelper.get_attribute_value(report_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(report_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='WARN'\" found for report test: #{report_test}"
      end

      assert_equal('WARN', role_attribute)
    end
  end

  def test_schema_schematron_error_messages
    OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
    # Test case => Error message
    all_expected_errors = { 'dhw-frac-load-served' => ['Expected sum(FractionDHWLoadServed) to be 1'],
                            'hvac-frac-load-served' => ['Expected sum(FractionHeatLoadServed) to be less than or equal to 1',
                                                        'Expected sum(FractionCoolLoadServed) to be less than or equal to 1'],
                            'enclosure-floor-area-exceeds-cfa' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas.'],
                            'energy-star-SF_Florida_3.1' => ['Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="FL"]'],
                            'energy-star-SF_OregonWashington_3.2' => ['Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]'],
                            'energy-star-SF_Pacific_3.0' => ['Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="HI" or text()="GU" or text()="MP"]'],
                            'energy-star-MF_OregonWashington_1.2' => ['Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]'] }

    ES::SFVersions.each do |es_version|
      key = "energy-star-#{es_version}"
      all_expected_errors[key] = [] if all_expected_errors[key].nil?
      all_expected_errors[key] << 'Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]'
    end
    ES::MFVersions.each do |es_version|
      key = "energy-star-#{es_version}"
      all_expected_errors[key] = [] if all_expected_errors[key].nil?
      all_expected_errors[key] << 'Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType="apartment unit"]'
    end

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      if ['dhw-frac-load-served'].include? error_case
        hpxml, hpxml_bldg = _create_hpxml('base-dhw-multiple.xml')
        hpxml_bldg.water_heating_systems[0].fraction_dhw_load_served = 0.35
      elsif ['hvac-frac-load-served'].include? error_case
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-multiple.xml')
        hpxml_bldg.heating_systems[0].fraction_heat_load_served += 0.1
        hpxml_bldg.cooling_systems[0].fraction_cool_load_served += 0.2
        hpxml_bldg.heating_systems[0].primary_system = true
        hpxml_bldg.cooling_systems[0].primary_system = true
        hpxml_bldg.heat_pumps[-1].primary_heating_system = false
        hpxml_bldg.heat_pumps[-1].primary_cooling_system = false
      elsif ['enclosure-floor-area-exceeds-cfa'].include? error_case
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.building_construction.conditioned_floor_area = 1348.8
      elsif error_case.include? 'energy-star'
        version = error_case.gsub('energy-star-', '')
        if ES::SFVersions.include? version
          bldg_type = HPXML::ResidentialTypeApartment
        elsif ES::MFVersions.include? version
          bldg_type = HPXML::ResidentialTypeSFD
        end

        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml.header.energystar_calculation_versions = [version]
        hpxml.header.iecc_eri_calculation_versions = nil
        hpxml.header.denh_calculation_versions = nil
        hpxml_bldg.building_construction.residential_facility_type = bldg_type
        if bldg_type == HPXML::ResidentialTypeApartment
          hpxml_bldg.walls[-1].exterior_adjacent_to = HPXML::LocationOtherHousingUnit
        end
        hpxml_bldg.state_code = 'CO'
        zone = hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.clear
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                                 zone: zone)
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_doc()

      # Test against schematron
      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_schema_and_schematron_validation(@tmp_hpxml_path, hpxml_doc, expected_errors: expected_errors)
    end
  end

  def test_ruleset_error_messages
    # Test case => Error message
    all_expected_errors = { 'invalid-epw-filepath' => ["foo.epw' could not be found."],
                            'invalid-zip-code' => ["Zip code '00000' could not be found in zipcode_weather_stations.csv"] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      case error_case
      when 'invalid-epw-filepath'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
        hpxml_bldg.climate_and_risk_zones.weather_station_name = 'foo'
        hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'foo.epw'
      when 'invalid-zip-code'
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.zip_code = '00000'
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_doc()

      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_ruleset(expected_errors)
    end
  end

  private

  def _test_schema_validation(hpxml_path, schema_validator)
    errors, _warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)
    if errors.size > 0
      flunk "#{hpxml_path}: #{errors}"
    end
  end

  def _test_schema_and_schematron_validation(hpxml_path, hpxml_doc, expected_errors: nil, expected_warnings: nil)
    sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, @schematron_validator, hpxml_doc)
    xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, @schema_validator)
    if not expected_errors.nil?
      _compare_errors_or_warnings('error', sct_errors + xsd_errors, expected_errors)
    end
    if not expected_warnings.nil?
      _compare_errors_or_warnings('warning', sct_warnings + xsd_warnings, expected_warnings)
    end
  end

  def _test_ruleset(expected_errors)
    print '.'
    designs = [Design.new(run_type: RunType::ERI,
                          calc_type: CalcType::RatedHome)]
    designs[0].hpxml_output_path = File.absolute_path(@tmp_output_path)

    success, errors, _, _, _ = run_rulesets(File.absolute_path(@tmp_hpxml_path), designs)

    if expected_errors.empty?
      assert(success)
    else
      refute(success)
    end

    _compare_errors_or_warnings('error', errors, expected_errors)
  end

  def _compare_errors_or_warnings(type, actual_msgs, expected_msgs)
    if expected_msgs.empty?
      if actual_msgs.size > 0
        flunk "Found unexpected #{type} messages:\n#{actual_msgs}"
      end
    else
      expected_msgs.each do |expected_msg|
        found_msg = false
        actual_msgs.each do |actual_msg|
          next unless actual_msg.include? expected_msg

          found_msg = true
          actual_msgs.delete(actual_msg)
          break
        end

        if not found_msg
          flunk "Did not find expected #{type} message\n'#{expected_msg}'\nin\n#{actual_msgs}"
        end
      end
      if actual_msgs.size > 0
        flunk "Found extra #{type} messages:\n#{actual_msgs}"
      end
    end
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end
end
