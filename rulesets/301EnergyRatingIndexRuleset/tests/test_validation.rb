# frozen_string_literal: true

require_relative '../../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'

class ERI301ValidationTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @eri_validator_stron_path = File.join(@root_path, 'rulesets', '301EnergyRatingIndexRuleset', 'resources', '301validator.xml')
    @hpxml_stron_path = File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'HPXMLvalidator.xml')
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
        stron_doc = SchematronNokogiri::Schema.new(xml_doc)
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

  private

  def _test_schematron_validation(hpxml_doc, expected_errors = [])
    # Validate via validator.rb
    errors, warnings = Validator.run_validators(hpxml_doc, [@eri_validator_stron_path, @hpxml_stron_path])
    _compare_errors(errors, expected_errors)
  end

  def _test_schema_validation(hpxml_doc, xml)
    # TODO: Remove this when schema validation is included with CLI calls
    schemas_dir = File.absolute_path(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources'))
    errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
    if errors.size > 0
      puts "#{xml}: #{errors}"
    end
    assert_equal(0, errors.size)
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
