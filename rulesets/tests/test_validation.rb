# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class ERI301ValidationTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @eri_validator_stron_path = File.join(@root_path, 'rulesets', 'resources', '301validator.xml')
    @hpxml_stron_path = File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'HPXMLvalidator.xml')

    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @tmp_output_path = File.join(@sample_files_path, 'tmp_output')
    FileUtils.mkdir_p(@tmp_output_path)
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    FileUtils.rm_rf(@tmp_output_path)
  end

  def test_validation_of_sample_files
    xmls = []
    Dir["#{@root_path}/workflow/sample_files/*.xml"].sort.each do |xml|
      next if xml.split('/').include? 'run'

      xmls << xml
    end

    xmls.each_with_index do |xml, i|
      puts "[#{i + 1}/#{xmls.size}] Testing #{File.basename(xml)}..."

      # Test validation
      hpxml_doc = HPXML.new(hpxml_path: xml, building_id: 'MyBuilding').to_oga()
      _test_schema_validation(hpxml_doc, xml)
      _test_schematron_validation(hpxml_doc)
    end
    puts
  end

  def test_validation_of_schematron_doc
    # Check that the schematron file is valid

    begin
      require 'schematron-nokogiri'

      [@eri_validator_stron_path, @hpxml_stron_path].each do |s_path|
        xml_doc = Nokogiri::XML(File.open(s_path)) do |config|
          config.options = Nokogiri::XML::ParseOptions::STRICT
        end
        SchematronNokogiri::Schema.new(xml_doc)
      end
    rescue LoadError
    end
  end

  def test_role_attributes_in_schematron_doc
    # Test for consistent use of errors/warnings
    puts
    puts 'Checking for correct role attributes...'

    epvalidator_stron_doc = XMLHelper.parse_file(@eri_validator_stron_path)

    # check that every assert element has a role attribute
    XMLHelper.get_elements(epvalidator_stron_doc, '/sch:schema/sch:pattern/sch:rule/sch:assert').each do |assert_element|
      assert_test = XMLHelper.get_attribute_value(assert_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(assert_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='ERROR'\" found for assertion test: #{assert_test}"
      end

      assert_equal('ERROR', role_attribute)
    end

    # check that every report element has a role attribute
    XMLHelper.get_elements(epvalidator_stron_doc, '/sch:schema/sch:pattern/sch:rule/sch:report').each do |report_element|
      report_test = XMLHelper.get_attribute_value(report_element, 'test').gsub('h:', '')
      role_attribute = XMLHelper.get_attribute_value(report_element, 'role')
      if role_attribute.nil?
        fail "No attribute \"role='WARN'\" found for report test: #{report_test}"
      end

      assert_equal('WARN', role_attribute)
    end
  end

  def test_schematron_error_messages
    # Test case => Error message
    all_expected_errors = { 'dhw-frac-load-served' => ['Expected sum(FractionDHWLoadServed) to be 1'],
                            'hvac-frac-load-served' => ['Expected sum(FractionHeatLoadServed) to be less than or equal to 1',
                                                        'Expected sum(FractionCoolLoadServed) to be less than or equal to 1'],
                            'enclosure-floor-area-exceeds-cfa' => ['Expected ConditionedFloorArea to be greater than or equal to the sum of conditioned slab/floor areas.'],
                            'energy-star-SF_Florida_3.1' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                             'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="FL"]'],
                            'energy-star-SF_National_3.0' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]'],
                            'energy-star-SF_National_3.1' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]'],
                            'energy-star-SF_National_3.2' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                              'Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year="2021"]/ClimateZone'],
                            'energy-star-SF_OregonWashington_3.2' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                                      'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]'],
                            'energy-star-SF_Pacific_3.0' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family detached" or text()="single-family attached"]]',
                                                             'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="HI" or text()="GU" or text()="MP"]'],
                            'energy-star-MF_National_1.0' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]'],
                            'energy-star-MF_National_1.1' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]'],
                            'energy-star-MF_National_1.2' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]',
                                                              'Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC[Year="2021"]/ClimateZone'],
                            'energy-star-MF_OregonWashington_1.2' => ['Expected 1 element(s) for xpath: ../../../../Building/BuildingDetails/BuildingSummary/BuildingConstruction[ResidentialFacilityType[text()="single-family attached" or text()="apartment unit"]]',
                                                                      'Expected 1 element(s) for xpath: ../../../../Building/Site/Address/StateCode[text()="OR" or text()="WA"]'] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      if ['dhw-frac-load-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-multiple.xml'))
        hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.35
      elsif ['hvac-frac-load-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-multiple.xml'))
        hpxml.heating_systems[0].fraction_heat_load_served += 0.1
        hpxml.cooling_systems[0].fraction_cool_load_served += 0.2
        hpxml.heating_systems[0].primary_system = true
        hpxml.cooling_systems[0].primary_system = true
        hpxml.heat_pumps[-1].primary_heating_system = false
        hpxml.heat_pumps[-1].primary_cooling_system = false
      elsif ['enclosure-floor-area-exceeds-cfa'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.building_construction.conditioned_floor_area = 1348.8
      elsif error_case.include? 'energy-star'
        es_props = { 'energy-star-SF_Florida_3.1' => [ESConstants.SFFloridaVer3_1, HPXML::ResidentialTypeApartment],
                     'energy-star-SF_National_3.0' => [ESConstants.SFNationalVer3_0, HPXML::ResidentialTypeApartment],
                     'energy-star-SF_National_3.1' => [ESConstants.SFNationalVer3_1, HPXML::ResidentialTypeApartment],
                     'energy-star-SF_National_3.2' => [ESConstants.SFNationalVer3_2, HPXML::ResidentialTypeApartment],
                     'energy-star-SF_OregonWashington_3.2' => [ESConstants.SFOregonWashingtonVer3_2, HPXML::ResidentialTypeApartment],
                     'energy-star-SF_Pacific_3.0' => [ESConstants.SFPacificVer3_0, HPXML::ResidentialTypeApartment],
                     'energy-star-MF_National_1.0' => [ESConstants.MFNationalVer1_0, HPXML::ResidentialTypeSFD],
                     'energy-star-MF_National_1.1' => [ESConstants.MFNationalVer1_1, HPXML::ResidentialTypeSFD],
                     'energy-star-MF_National_1.2' => [ESConstants.MFNationalVer1_2, HPXML::ResidentialTypeSFD],
                     'energy-star-MF_OregonWashington_1.2' => [ESConstants.MFOregonWashingtonVer1_2, HPXML::ResidentialTypeSFD] }
        es_version, bldg_type = es_props[error_case]
        hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files', 'base.xml'))
        hpxml.header.energystar_calculation_version = es_version
        hpxml.header.iecc_eri_calculation_version = nil
        hpxml.building_construction.residential_facility_type = bldg_type
        hpxml.header.state_code = 'CO'
        zone = hpxml.climate_and_risk_zones.climate_zone_ieccs[0].zone
        hpxml.climate_and_risk_zones.climate_zone_ieccs.clear
        hpxml.climate_and_risk_zones.climate_zone_ieccs.add(year: 2006,
                                                            zone: zone)
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_oga()

      # Test against schematron
      _test_schematron_validation(hpxml_doc, expected_errors)
    end
  end

  def test_ruleset_error_messages
    # Test case => Error message
    all_expected_errors = { 'invalid-epw-filepath' => ["foo.epw' could not be found."] }

    all_expected_errors.each_with_index do |(error_case, expected_errors), i|
      puts "[#{i + 1}/#{all_expected_errors.size}] Testing #{error_case}..."
      # Create HPXML object
      if ['invalid-epw-filepath'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base.xml'))
        hpxml.climate_and_risk_zones.weather_station_epw_filepath = 'foo.epw'
      elsif ['dhw-frac-load-served'].include? error_case
        hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-dhw-multiple.xml'))
        hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.35
      else
        fail "Unhandled case: #{error_case}."
      end

      hpxml_doc = hpxml.to_oga()

      XMLHelper.write_file(hpxml_doc, @tmp_hpxml_path)
      _test_ruleset(expected_errors)
    end
  end

  private

  def _test_schematron_validation(hpxml_doc, expected_errors = [])
    # Validate via validator.rb
    errors, _warnings = Validator.run_validators(hpxml_doc, [@eri_validator_stron_path, @hpxml_stron_path])
    _compare_errors(errors, expected_errors)
  end

  def _test_schema_validation(hpxml_doc, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema'))
    errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
    if errors.size > 0
      puts "#{xml}: #{errors}"
    end
    assert_equal(0, errors.size)
  end

  def _test_ruleset(expected_errors)
    require_relative '../../workflow/design'
    designs = [Design.new(calc_type: Constants.CalcTypeERIRatedHome)]
    designs[0].hpxml_output_path = File.absolute_path(@tmp_output_path)

    success, errors, _, _, _ = run_rulesets(File.absolute_path(@tmp_hpxml_path), designs)

    if expected_errors.empty?
      assert_equal(true, success)
    else
      assert_equal(false, success)
    end

    _compare_errors(errors, expected_errors)
  end

  def _compare_errors(actual_errors, expected_errors)
    if expected_errors.empty?
      if actual_errors.size > 0
        puts "Found unexpected error messages:\n#{actual_errors}"
      end
      assert(actual_errors.size == 0)
    else
      expected_errors.each do |expected_error|
        found_error = false
        actual_errors.each do |actual_error|
          found_error = true if actual_error.include? expected_error
        end

        if not found_error
          puts "Did not find expected error message\n'#{expected_error}'\nin\n#{actual_errors}"
        end
        assert(found_error)
      end
      if expected_errors.size != actual_errors.size
        puts "Found extra error messages:\n#{actual_errors}"
      end
      assert_equal(expected_errors.size, actual_errors.size)
    end
  end
end
