# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'
require_relative '../../workflow/design'

class EnergyStarDOEEfficientNewHomeEnclosureTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @schema_validator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd'))
    @epvalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.sch'))
    @erivalidator = XMLValidator.get_xml_validator(File.join(@root_path, 'rulesets', 'resources', '301validator.sch'))
    @results_paths = []
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    @results_paths.each do |results_path|
      FileUtils.rm_rf(results_path) if Dir.exist? results_path
    end
    @results_paths.clear
    puts
  end

  def test_enclosure_infiltration
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      if program_version == ES::SFNationalVer3_0
        value, units = 4.0, 'ACH'
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFOregonWashingtonVer3_2].include? program_version
        value, units = 3.0, 'ACH'
      elsif program_version == ES::SFPacificVer3_0
        value, units = 6.0, 'ACH'
      elsif program_version == ES::SFFloridaVer3_1
        value, units = 5.0, 'ACH'
      elsif [ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFOregonWashingtonVer1_2].include? program_version
        value, units = 1564.8, 'CFM'
      elsif program_version == ES::MFNationalVer1_3
        value, units = 1408.2, 'CFM'
      elsif program_version == DENH::MFVer2
        value, units = 1303.9, 'CFM'
      elsif [DENH::Ver1, DENH::SFVer2].include? program_version
        value, units = 2.0, 'ACH'
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_infiltration(hpxml_bldg, value, units)
    end

    [*ES::MFVersions, *DENH::MFVersions].each do |program_version|
      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if program_version == DENH::Ver1
        _check_infiltration(hpxml_bldg, 3.0, 'ACH')
      elsif program_version == DENH::MFVer2
        _check_infiltration(hpxml_bldg, 695.0, 'CFM')
      elsif program_version == ES::MFNationalVer1_3
        _check_infiltration(hpxml_bldg, 750.5, 'CFM')
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2,
             DENH::SFVer2].include? program_version
        _check_infiltration(hpxml_bldg, 834.0, 'CFM')
      else
        fail "Unhandled program version: #{program_version}"
      end
    end

    [*ES::NationalVersions, *DENH::AllVersions].each do |program_version|
      if program_version == ES::SFNationalVer3_0
        value, units = 6.0, 'ACH'
      elsif program_version == ES::SFNationalVer3_1
        value, units = 4.0, 'ACH'
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3, DENH::Ver1].include? program_version
        value, units = 3.0, 'ACH'
      elsif program_version == DENH::SFVer2
        value, units = 2.75, 'ACH'
      elsif [ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2].include? program_version
        value, units = 1170.0, 'CFM'
      elsif program_version == ES::MFNationalVer1_3
        value, units = 1053.0, 'CFM'
      elsif program_version == DENH::MFVer2
        value, units = 975.0, 'CFM'
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-location-miami-fl.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_infiltration(hpxml_bldg, value, units)
    end
  end

  def test_enclosure_roofs
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      next if program_version == ES::SFPacificVer3_0

      if [ES::SFFloridaVer3_1].include? program_version
        rb_grade = 1
      elsif [ES::SFOregonWashingtonVer3_2, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1, DENH::SFVer2, DENH::MFVer2].include? program_version
        rb_grade = nil
      else
        fail "Unhandled program version: #{program_version}"
      end
      adjacent_to = HPXML::LocationAtticVented
      rvalue = 2.3

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_roofs(hpxml_bldg, area: 1510, rvalue: rvalue, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: adjacent_to)

      if [ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::MFVer2].include? program_version
        # Ducts remain in conditioned space, so no need to transition roof to vented attic
        adjacent_to = HPXML::LocationConditionedSpace
        if program_version == ES::MFNationalVer1_1
          rvalue = 1.0 / 0.021
        elsif [ES::MFNationalVer1_2, DENH::MFVer2].include? program_version
          rvalue = 1.0 / 0.024
        elsif program_version == ES::MFNationalVer1_3
          rvalue = 1.0 / 0.026
        else
          fail "Unhandled program version: #{program_version}"
        end
      end

      _convert_to_es_denh('base-atticroof-cathedral.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_roofs(hpxml_bldg, area: 1510, rvalue: rvalue, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: adjacent_to)

      _convert_to_es_denh('base-atticroof-flat.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_roofs(hpxml_bldg, area: 1350, rvalue: rvalue, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: adjacent_to)
    end

    [*ES::MFVersions, *DENH::MFVersions].each do |program_version|
      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_roofs(hpxml_bldg)
    end

    # Radiant barrier: In climate zones 1-3, if > 10 linear ft. of ductwork are located in unconditioned attic
    [*ES::NationalVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::SFNationalVer3_0, ES::MFNationalVer1_0].include? program_version
        rb_grade = 1
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1, DENH::SFVer2, DENH::MFVer2].include? program_version
        rb_grade = nil
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: HPXML::LocationAtticVented)
    end

    # SFPacificVer3_0 - Regional test
    ['HI', 'GU', 'MP'].each do |state_code|
      if state_code == 'HI'
        rb_grade = nil
      else
        rb_grade = 1
      end

      # In both HI and GU, if > 10 linear ft. of ductwork are located in unconditioned attic, place radiant barrier
      _convert_to_es_denh('base.xml', ES::SFPacificVer3_0, state_code)
      hpxml_bldg = _test_ruleset(ES::SFPacificVer3_0)
      _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: 1, adjacent_to: HPXML::LocationAtticVented)

      _convert_to_es_denh('base-atticroof-cathedral.xml', ES::SFPacificVer3_0, state_code)
      hpxml_bldg = _test_ruleset(ES::SFPacificVer3_0)
      _check_roofs(hpxml_bldg, area: 1510, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: HPXML::LocationAtticVented)

      _convert_to_es_denh('base-atticroof-flat.xml', ES::SFPacificVer3_0, state_code)
      hpxml_bldg = _test_ruleset(ES::SFPacificVer3_0)
      _check_roofs(hpxml_bldg, area: 1350, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: HPXML::LocationAtticVented)
    end
  end

  def test_enclosure_walls
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      next if program_version == ES::SFPacificVer3_0

      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ES::SFFloridaVer3_1].include? program_version
        rvalue = 1.0 / 0.082
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.056
      elsif [DENH::Ver1].include? program_version
        rvalue = 1.0 / 0.060
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::SFVer2, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.045
      elsif [ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        rvalue = 1.0 / 0.057
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_walls(hpxml_bldg, area: 1425, rvalue: (rvalue * 1200 + 4.0 * 225) / 1425, sabs: 0.75, emit: 0.9)

      _convert_to_es_denh('base-atticroof-conditioned.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_walls(hpxml_bldg, area: 1806, rvalue: (rvalue * 1756 + 4.0 * 50) / 1806, sabs: 0.75, emit: 0.9)

      _convert_to_es_denh('base-enclosure-garage.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_walls(hpxml_bldg, area: 2098, rvalue: (rvalue * 1200 + 4.0 * 898) / 2098, sabs: 0.75, emit: 0.9)
    end

    [*ES::MFVersions, *DENH::MFVersions].each do |program_version|
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.045
      elsif program_version == ES::MFOregonWashingtonVer1_2
        rvalue = 1.0 / 0.056
      elsif [DENH::Ver1].include? program_version
        rvalue = 1.0 / 0.060
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_walls(hpxml_bldg, area: 980, rvalue: (rvalue * 686 + 4.0 * 294) / 980, sabs: 0.75, emit: 0.9)

      _convert_to_es_denh('base-bldgtype-mf-unit-adjacent-to-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_walls(hpxml_bldg, area: 1086, rvalue: (rvalue * 686 + 4.0 * 400) / 1086, sabs: 0.75, emit: 0.9)
    end

    # SFPacificVer3_0 - Regional test
    ['HI', 'GU', 'MP'].each do |state_code|
      if state_code == 'HI'
        rvalue = 1 / 0.082
      else
        rvalue = 1 / 0.401
      end

      _convert_to_es_denh('base.xml', ES::SFPacificVer3_0, state_code)
      hpxml_bldg = _test_ruleset(ES::SFPacificVer3_0)
      _check_walls(hpxml_bldg, area: 1425, rvalue: (rvalue * 1200 + 4.0 * 225) / 1425, sabs: 0.75, emit: 0.9)

      _convert_to_es_denh('base-atticroof-conditioned.xml', ES::SFPacificVer3_0, state_code)
      hpxml_bldg = _test_ruleset(ES::SFPacificVer3_0)
      _check_walls(hpxml_bldg, area: 1806, rvalue: (rvalue * 1756 + 4.0 * 50) / 1806, sabs: 0.75, emit: 0.9)

      _convert_to_es_denh('base-enclosure-garage.xml', ES::SFPacificVer3_0, state_code)
      hpxml_bldg = _test_ruleset(ES::SFPacificVer3_0)
      _check_walls(hpxml_bldg, area: 2098, rvalue: (rvalue * 1200 + 4.0 * 898) / 2098, sabs: 0.75, emit: 0.9)
    end
  end

  def test_enclosure_rim_joists
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        rvalue = 1.0 / 0.082
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.056
      elsif [DENH::Ver1].include? program_version
        rvalue = 1.0 / 0.060
      elsif [ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::SFVer2, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.045
      elsif [ES::SFNationalVer3_0, ES::SFNationalVer3_1].include? program_version
        rvalue = 1.0 / 0.057
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_rim_joists(hpxml_bldg, area: 116, rvalue: rvalue, sabs: 0.75, emit: 0.90)

      _convert_to_es_denh('base-foundation-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_rim_joists(hpxml_bldg, area: 197, rvalue: 4.0, sabs: 0.75, emit: 0.90)
    end
  end

  def test_enclosure_foundation_walls
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      if program_version == ES::SFNationalVer3_0
        assembly_rvalue = 1.0 / 0.059
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1, DENH::SFVer2, DENH::MFVer2].include? program_version
        assembly_rvalue = 1.0 / 0.050
      elsif [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        ins_interior_rvalue = 7.5
      elsif program_version == ES::MFOregonWashingtonVer1_2
        ins_interior_rvalue = 15.0
      elsif program_version == ES::SFOregonWashingtonVer3_2
        assembly_rvalue = 1.0 / 0.042
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        assembly_rvalue = 1.0 / 0.360
      else
        fail "Unhandled program version: #{program_version}"
      end

      hpxml_names = ['base.xml',
                     'base-foundation-conditioned-basement-wall-insulation.xml']
      hpxml_names.each do |hpxml_name|
        _convert_to_es_denh(hpxml_name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        if hpxml_name == 'base-foundation-conditioned-basement-wall-insulation.xml'
          type = HPXML::FoundationWallTypeConcreteBlockFoamCore
        else
          type = HPXML::FoundationWallTypeSolidConcrete
        end
        _check_foundation_walls(hpxml_bldg, area: 1200, assembly_rvalue: assembly_rvalue, ins_interior_rvalue: ins_interior_rvalue, ins_bottom: 8, height: 8, depth_bg: 7, type: type)
      end
    end

    [*ES::NationalVersions, *DENH::AllVersions].each do |program_version|
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        ins_interior_rvalue = 0.0
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1, DENH::SFVer2, DENH::MFVer2].include? program_version
        assembly_rvalue = 1.0 / 0.360
      else
        fail "Unhandled program version: #{program_version}"
      end

      hpxml_names = ['base.xml',
                     'base-foundation-conditioned-basement-wall-insulation.xml']
      hpxml_names.each do |hpxml_name|
        _convert_to_es_denh(hpxml_name, program_version)
        hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
        hpxml_bldg = hpxml.buildings[0]
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
        hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
        hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        hpxml_bldg = _test_ruleset(program_version)
        if hpxml_name == 'base-foundation-conditioned-basement-wall-insulation.xml'
          type = HPXML::FoundationWallTypeConcreteBlockFoamCore
        else
          type = HPXML::FoundationWallTypeSolidConcrete
        end
        _check_foundation_walls(hpxml_bldg, area: 1200, assembly_rvalue: assembly_rvalue, ins_interior_rvalue: ins_interior_rvalue, ins_bottom: 8, height: 8, depth_bg: 7, type: type)
      end
    end

    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_foundation_walls(hpxml_bldg, area: 1200, height: 8, depth_bg: 7, type: HPXML::FoundationWallTypeSolidConcrete)

      hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                     'base-foundation-vented-crawlspace.xml']
      hpxml_names.each do |name|
        _convert_to_es_denh(name, program_version)
        hpxml_bldg = _test_ruleset(program_version)
        _check_foundation_walls(hpxml_bldg, area: 600, height: 4, depth_bg: 3, type: HPXML::FoundationWallTypeSolidConcrete)
      end
    end
  end

  def test_enclosure_ceilings
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      if program_version == ES::SFNationalVer3_0
        rvalue = 1.0 / 0.030
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_3, ES::SFOregonWashingtonVer3_2,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1].include? program_version
        rvalue = 1.0 / 0.026
      elsif program_version == ES::MFNationalVer1_0
        rvalue = 1.0 / 0.027
      elsif program_version == ES::MFNationalVer1_1
        rvalue = 1.0 / 0.021
      elsif [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        rvalue = 1.0 / 0.035
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2, DENH::SFVer2, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.024
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_ceilings(hpxml_bldg, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_denh('base-enclosure-garage.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_ceilings(hpxml_bldg, area: 1950, rvalue: (rvalue * 1350 + 2.1 * 600) / 1950, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_denh('base-atticroof-cathedral.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::MFVer2].include? program_version
        _check_ceilings(hpxml_bldg)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0,
             DENH::Ver1, DENH::SFVer2].include? program_version
        _check_ceilings(hpxml_bldg, area: (1510 * Math.cos(Math.atan(6.0 / 12.0))), rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-atticroof-conditioned.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_ceilings(hpxml_bldg, area: 450, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_denh('base-atticroof-flat.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::MFVer2].include? program_version
        _check_ceilings(hpxml_bldg)
      elsif [ES::SFFloridaVer3_1, ES::SFOregonWashingtonVer3_2, ES::SFPacificVer3_0, ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_0,
             DENH::Ver1, DENH::SFVer2].include? program_version
        _check_ceilings(hpxml_bldg, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
      else
        fail "Unhandled program version: #{program_version}"
      end

      if [*ES::SFVersions, DENH::SFVer2].include? program_version
        _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
        hpxml_bldg = _test_ruleset(program_version)
        _check_ceilings(hpxml_bldg, area: 900, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
      elsif [*ES::MFVersions, *DENH::MFVersions].include? program_version
        _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
        hpxml_bldg = _test_ruleset(program_version)
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)

        _convert_to_es_denh('base-bldgtype-mf-unit-adjacent-to-multiple.xml', program_version)
        hpxml_bldg = _test_ruleset(program_version)
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)

        # Check w/ mass ceilings
        hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
        hpxml_bldg = hpxml.buildings[0]
        hpxml_bldg.floors.each do |floor|
          next unless floor.is_ceiling

          floor.floor_type = HPXML::FloorTypeConcrete
        end
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        hpxml_bldg = _test_ruleset(program_version)
        _check_ceilings(hpxml_bldg, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeConcrete)
      else
        fail "Unhandled program version: #{program_version}"
      end
    end
  end

  def test_enclosure_floors
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      if [ES::SFNationalVer3_1, DENH::Ver1, DENH::SFVer2, DENH::MFVer2, ES::SFNationalVer3_0, ES::MFNationalVer1_0,
          ES::MFNationalVer1_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        rvalue = 1.0 / 0.033
      elsif program_version == ES::SFPacificVer3_0
        rvalue = 1.0 / 0.257
      elsif program_version == ES::SFFloridaVer3_1
        rvalue = 1.0 / 0.064
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.028
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_floors(hpxml_bldg, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_denh('base-foundation-unconditioned-basement-wall-insulation.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_floors(hpxml_bldg, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
    end

    [*ES::MFVersions, *DENH::MFVersions].each do |program_version|
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::Ver1, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.033
      elsif program_version == ES::MFOregonWashingtonVer1_2
        rvalue = 1.0 / 0.028
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_floors(hpxml_bldg, area: 900, rvalue: 3.1, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_denh('base-bldgtype-mf-unit-adjacent-to-multiple.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_floors(hpxml_bldg, area: 900, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      # Check w/ mass floors
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.floors.each do |floor|
        floor.floor_type = HPXML::FloorTypeConcrete
      end
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      if [ES::MFNationalVer1_0, ES::MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ES::MFNationalVer1_2, ES::MFNationalVer1_3, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.051
      elsif program_version == DENH::Ver1
        rvalue = 1.0 / 0.033  # Assembly R-value of non-mass floor
      elsif program_version == ES::MFOregonWashingtonVer1_2
        rvalue = 1.0 / 0.028  # Assembly R-value of non-mass floor
      else
        fail "Unhandled program version: #{program_version}"
      end
      _check_floors(hpxml_bldg, area: 900, rvalue: rvalue, floor_type: HPXML::FloorTypeConcrete)
    end

    [*ES::NationalVersions, *DENH::AllVersions].each do |program_version|
      if program_version == ES::MFNationalVer1_0
        rvalue = 1.0 / 0.282
      elsif program_version == ES::MFNationalVer1_1
        rvalue = 1.0 / 0.066
      elsif [ES::SFNationalVer3_0, ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3,
             ES::MFNationalVer1_2, ES::MFNationalVer1_3,
             DENH::Ver1, DENH::SFVer2, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.064
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_floors(hpxml_bldg, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
    end
  end

  def test_enclosure_slabs
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150)
      if [ES::SFPacificVer3_0, ES::SFFloridaVer3_1].include? program_version
        perim_ins_depth = 0
        perim_ins_r = 0
        under_ins_width = 0
        under_ins_r = 0
      elsif [ES::SFOregonWashingtonVer3_2, ES::MFOregonWashingtonVer1_2].include? program_version
        perim_ins_depth = 4
        perim_ins_r = 10
        under_ins_width = 999
        under_ins_r = 10
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2, DENH::SFVer2, DENH::MFVer2].include? program_version
        perim_ins_depth = 4
        perim_ins_r = 10
        under_ins_width = 0
        under_ins_r = 0
      elsif [ES::SFNationalVer3_3, ES::MFNationalVer1_3].include? program_version
        perim_ins_depth = 3
        perim_ins_r = 10
        under_ins_width = 0
        under_ins_r = 0
      elsif [ES::SFNationalVer3_0, ES::SFNationalVer3_1,
             ES::MFNationalVer1_0, ES::MFNationalVer1_1,
             DENH::Ver1].include? program_version
        perim_ins_depth = 2
        perim_ins_r = 10
        under_ins_width = 0
        under_ins_r = 0
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base-foundation-slab.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150, perim_ins_depth: perim_ins_depth, perim_ins_r: perim_ins_r,
                               under_ins_width: under_ins_width, under_ins_r: under_ins_r)
    end

    [*ES::NationalVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150)

      _convert_to_es_denh('base-foundation-slab.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_slabs(hpxml_bldg, area: 1350, exp_perim: 150)
    end
  end

  def test_enclosure_windows
    # SF tests
    [*ES::SFVersions, *DENH::SFVersions].each do |program_version|
      if program_version == ES::SFNationalVer3_0
        ufactor, shgc = 0.30, 0.40
      elsif [ES::SFNationalVer3_1, DENH::Ver1].include? program_version
        ufactor, shgc = 0.27, 0.40
      elsif [ES::SFNationalVer3_2, ES::MFNationalVer1_2, DENH::SFVer2].include? program_version
        ufactor, shgc = 0.27, 0.30
      elsif program_version == ES::SFPacificVer3_0
        ufactor, shgc = 0.60, 0.27
      elsif program_version == ES::SFFloridaVer3_1
        ufactor, shgc = 0.65, 0.27
      elsif program_version == ES::SFOregonWashingtonVer3_2
        ufactor, shgc = 0.27, 0.30
      elsif program_version == ES::SFNationalVer3_3
        ufactor, shgc = 0.25, 0.30
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.67,
                                 values_by_azimuth: { 0 => { area: 74.55, ufactor: ufactor, shgc: shgc },
                                                      180 => { area: 74.55, ufactor: ufactor, shgc: shgc },
                                                      90 => { area: 74.55, ufactor: ufactor, shgc: shgc },
                                                      270 => { area: 74.55, ufactor: ufactor, shgc: shgc } })

      _convert_to_es_denh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.67,
                                 values_by_azimuth: { 0 => { area: 50.63, ufactor: ufactor, shgc: shgc },
                                                      180 => { area: 50.63, ufactor: ufactor, shgc: shgc },
                                                      90 => { area: 50.63, ufactor: ufactor, shgc: shgc },
                                                      270 => { area: 50.63, ufactor: ufactor, shgc: shgc } })

      _convert_to_es_denh('base-atticroof-cathedral.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.67,
                                 values_by_azimuth: { 0 => { area: 77.95, ufactor: ufactor, shgc: shgc },
                                                      180 => { area: 77.95, ufactor: ufactor, shgc: shgc },
                                                      90 => { area: 77.95, ufactor: ufactor, shgc: shgc },
                                                      270 => { area: 77.95, ufactor: ufactor, shgc: shgc } })

      _convert_to_es_denh('base-atticroof-conditioned.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.57,
                                 values_by_azimuth: { 0 => { area: 107.17, ufactor: ufactor, shgc: shgc },
                                                      180 => { area: 107.17, ufactor: ufactor, shgc: shgc },
                                                      90 => { area: 107.17, ufactor: ufactor, shgc: shgc },
                                                      270 => { area: 107.17, ufactor: ufactor, shgc: shgc } })
    end

    # MF tests
    ES::MFVersions.each do |program_version|
      # Base test (non-structural windows)
      if program_version == ES::MFNationalVer1_0
        ufactor, shgc = 0.30, 0.40
      elsif program_version == ES::MFNationalVer1_1
        ufactor, shgc = 0.27, 0.40
      elsif [ES::MFNationalVer1_2, DENH::MFVer2].include? program_version
        ufactor, shgc = 0.27, 0.30
      elsif program_version == ES::MFOregonWashingtonVer1_2
        ufactor, shgc = 0.27, 0.30
      elsif program_version == ES::MFNationalVer1_3
        ufactor, shgc = 0.25, 0.30
      else
        fail "Unhandled program version: #{program_version}"
      end
      _convert_to_es_denh('base-bldgtype-mf-unit.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.67,
                                 values_by_azimuth: { 0 => { area: 33.34, ufactor: ufactor, shgc: shgc },
                                                      180 => { area: 33.34, ufactor: ufactor, shgc: shgc },
                                                      270 => { area: 50.49, ufactor: ufactor, shgc: shgc } })

      # Test w/ structural fixed windows
      if program_version == ES::MFNationalVer1_0
        ufactor2 = 0.38
      elsif [ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2].include? program_version
        ufactor2 = 0.36
      elsif [ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        ufactor2 = 0.34
      else
        fail "Unhandled program version: #{program_version}"
      end
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.windows.each do |window|
        next unless window.azimuth == 0

        window.performance_class = HPXML::WindowClassArchitectural
        window.fraction_operable = 0.0
      end
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.48,
                                 values_by_azimuth: { 0 => { area: 33.34, ufactor: ufactor2, shgc: shgc },
                                                      180 => { area: 33.34, ufactor: ufactor, shgc: shgc },
                                                      270 => { area: 50.49, ufactor: ufactor, shgc: shgc } })

      # Test w/ structural operable windows
      if program_version == ES::MFNationalVer1_0
        ufactor3 = 0.45
      elsif [ES::MFNationalVer1_1, ES::MFOregonWashingtonVer1_2, ES::MFNationalVer1_2, ES::MFNationalVer1_3].include? program_version
        ufactor3 = 0.43
      else
        fail "Unhandled program version: #{program_version}"
      end
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.windows.each do |window|
        next unless window.azimuth == 180

        window.performance_class = HPXML::WindowClassArchitectural
        window.fraction_operable = 1.0
      end
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.57,
                                 values_by_azimuth: { 0 => { area: 33.34, ufactor: ufactor2, shgc: shgc },
                                                      180 => { area: 33.34, ufactor: ufactor3, shgc: shgc },
                                                      270 => { area: 50.49, ufactor: ufactor, shgc: shgc } })
    end

    # Test in Climate Zone 1A
    [*ES::NationalVersions, *DENH::AllVersions].each do |program_version|
      if program_version == ES::SFNationalVer3_0
        ufactor, shgc = 0.60, 0.27
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif [ES::SFNationalVer3_1, ES::SFNationalVer3_2, DENH::Ver1].include? program_version
        ufactor, shgc = 0.40, 0.25
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif program_version == ES::SFNationalVer3_3
        ufactor, shgc = 0.32, 0.23
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif program_version == DENH::SFVer2
        ufactor, shgc = 0.40, 0.23
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif program_version == ES::MFNationalVer1_0
        ufactor, shgc = 0.60, 0.27
        areas = [89.46, 89.46, 59.64, 59.64]
      elsif [ES::MFNationalVer1_1, ES::MFNationalVer1_2].include? program_version
        ufactor, shgc = 0.40, 0.25
        areas = [89.46, 89.46, 59.64, 59.64]
      elsif program_version == ES::MFNationalVer1_3
        ufactor, shgc = 0.32, 0.23
        areas = [89.46, 89.46, 59.64, 59.64]
      elsif program_version == DENH::MFVer2
        ufactor, shgc = 0.40, 0.23
        areas = [89.46, 89.46, 59.64, 59.64]
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml_bldg = hpxml.buildings[0]
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml_bldg.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      hpxml_bldg = _test_ruleset(program_version)
      _check_windows(hpxml_bldg, frac_operable: 0.67,
                                 values_by_azimuth: { 0 => { area: areas[0], ufactor: ufactor, shgc: shgc },
                                                      180 => { area: areas[1], ufactor: ufactor, shgc: shgc },
                                                      90 => { area: areas[2], ufactor: ufactor, shgc: shgc },
                                                      270 => { area: areas[3], ufactor: ufactor, shgc: shgc } })
    end
  end

  def test_enclosure_skylights
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-enclosure-skylights.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_skylights(hpxml_bldg)
    end
  end

  def test_enclosure_overhangs
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      _convert_to_es_denh('base-enclosure-overhangs.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_overhangs(hpxml_bldg)
    end
  end

  def test_enclosure_doors
    [*ES::AllVersions, *DENH::AllVersions].each do |program_version|
      if [ES::SFNationalVer3_1, ES::SFNationalVer3_2, ES::SFNationalVer3_3, ES::SFOregonWashingtonVer3_2,
          ES::MFNationalVer1_1, ES::MFNationalVer1_2, ES::MFNationalVer1_3, ES::MFOregonWashingtonVer1_2,
          DENH::SFVer2, DENH::MFVer2].include? program_version
        rvalue = 1.0 / 0.17
      elsif [ES::SFFloridaVer3_1, ES::SFPacificVer3_0, ES::SFNationalVer3_0,
             ES::MFNationalVer1_0,
             DENH::Ver1].include? program_version
        rvalue = 1.0 / 0.21
      else
        fail "Unhandled program version: #{program_version}"
      end

      _convert_to_es_denh('base.xml', program_version)
      hpxml_bldg = _test_ruleset(program_version)
      _check_doors(hpxml_bldg, values_by_azimuth: { 180 => { area: 40, rvalue: rvalue } })
    end
  end

  def _test_ruleset(program_version)
    print '.'

    if ES::AllVersions.include? program_version
      run_type = RunType::ES
    elsif DENH::AllVersions.include? program_version
      run_type = RunType::DENH
    end
    designs = [Design.new(run_type: run_type,
                          init_calc_type: InitCalcType::TargetHome,
                          output_dir: @sample_files_path,
                          version: program_version)]

    success, errors, _, _, hpxml_bldgs = run_rulesets(@tmp_hpxml_path, designs, @schema_validator, @erivalidator)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert(success)

    # validate against 301 schematron
    designs.each do |design|
      valid = @erivalidator.validate(design.init_hpxml_output_path)
      puts @erivalidator.errors.map { |e| e.logMessage } unless valid
      assert(valid)
      @results_paths << File.absolute_path(File.join(File.dirname(design.init_hpxml_output_path), '..'))
    end

    return hpxml_bldgs.values[0]
  end

  def _check_infiltration(hpxml_bldg, value, units)
    assert_equal(1, hpxml_bldg.air_infiltration_measurements.size)
    air_infiltration_measurement = hpxml_bldg.air_infiltration_measurements[0]
    assert_equal(units, air_infiltration_measurement.unit_of_measure)
    assert_equal(50.0, air_infiltration_measurement.house_pressure)
    assert_in_epsilon(value, air_infiltration_measurement.air_leakage, 0.01)
  end

  def _check_roofs(hpxml_bldg, area: nil, rvalue: nil, sabs: nil, emit: nil, rb_grade: nil, adjacent_to: nil)
    tot_area = 0
    rvalue_x_area_values, sabs_x_area_values, emit_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.roofs.each do |roof|
      tot_area += roof.area
      rvalue_x_area_values << roof.insulation_assembly_r_value * roof.area
      sabs_x_area_values << roof.solar_absorptance * roof.area
      emit_x_area_values << roof.emittance * roof.area
      if rb_grade.nil?
        assert_equal(false, roof.radiant_barrier)
        assert_nil(roof.radiant_barrier_grade)
      else
        assert_equal(true, roof.radiant_barrier)
        assert_equal(rb_grade, roof.radiant_barrier_grade)
      end
      assert_equal(adjacent_to, roof.interior_adjacent_to)
    end

    if area.nil?
      assert_equal(0, tot_area)
    else
      assert_in_epsilon(area, tot_area, 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.sum / tot_area, 0.01)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.sum / tot_area, 0.01)
    end
  end

  def _check_walls(hpxml_bldg, area:, rvalue:, sabs:, emit:)
    tot_area, ext_area = 0, 0
    rvalue_x_area_values, sabs_x_area_values, emit_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.walls.each do |wall|
      tot_area += wall.area
      rvalue_x_area_values << wall.insulation_assembly_r_value * wall.area
      next unless wall.is_exterior

      ext_area += wall.area
      sabs_x_area_values << wall.solar_absorptance * wall.area
      emit_x_area_values << wall.emittance * wall.area
    end
    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(sabs, sabs_x_area_values.sum / ext_area, 0.01)
    assert_in_epsilon(emit, emit_x_area_values.sum / ext_area, 0.01)
  end

  def _check_rim_joists(hpxml_bldg, area: nil, rvalue: nil, sabs: nil, emit: nil)
    tot_area, ext_area = 0, 0
    rvalue_x_area_values, sabs_x_area_values, emit_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.rim_joists.each do |rim_joist|
      tot_area += rim_joist.area
      rvalue_x_area_values << rim_joist.insulation_assembly_r_value * rim_joist.area
      next unless rim_joist.is_exterior

      ext_area += rim_joist.area
      sabs_x_area_values << rim_joist.solar_absorptance * rim_joist.area
      emit_x_area_values << rim_joist.emittance * rim_joist.area
    end

    if area.nil?
      assert_equal(0, tot_area)
    else
      assert_in_epsilon(area, tot_area, 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.sum / ext_area, 0.01)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.sum / ext_area, 0.01)
    end
  end

  def _check_foundation_walls(hpxml_bldg, area:, assembly_rvalue: 0, ins_interior_rvalue: 0, ins_top: 0, ins_bottom: 0, height:, depth_bg: 0, type: nil)
    tot_area = 0
    assembly_rvalue_x_area_values, ins_interior_rvalue_x_area_values, ins_top_x_area_values = [], [], [] # Area-weighted
    ins_bottom_x_area_values, height_x_area_values, depth_bg_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.foundation_walls.each do |foundation_wall|
      tot_area += foundation_wall.area
      if not foundation_wall.insulation_assembly_r_value.nil?
        assembly_rvalue_x_area_values << foundation_wall.insulation_assembly_r_value * foundation_wall.area
        ins_top_x_area_values << 0.0
        ins_bottom_x_area_values << foundation_wall.height * foundation_wall.area # Total wall height applies to R-value
      end
      if not foundation_wall.insulation_interior_r_value.nil?
        ins_interior_rvalue_x_area_values << foundation_wall.insulation_interior_r_value * foundation_wall.area
        ins_top_x_area_values << foundation_wall.insulation_interior_distance_to_top * foundation_wall.area
        ins_bottom_x_area_values << foundation_wall.insulation_interior_distance_to_bottom * foundation_wall.area
      end
      height_x_area_values << foundation_wall.height * foundation_wall.area
      depth_bg_x_area_values << foundation_wall.depth_below_grade * foundation_wall.area
      if type.nil?
        assert_nil(foundation_wall.type)
      else
        assert_equal(type, foundation_wall.type)
      end
    end

    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(assembly_rvalue, assembly_rvalue_x_area_values.sum / tot_area, 0.01) unless assembly_rvalue_x_area_values.empty?
    assert_in_epsilon(ins_interior_rvalue, ins_interior_rvalue_x_area_values.sum / tot_area, 0.01) unless ins_interior_rvalue_x_area_values.empty?
    assert_in_epsilon(ins_top, ins_top_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(ins_bottom, ins_bottom_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(height, height_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(depth_bg, depth_bg_x_area_values.sum / tot_area, 0.01)
  end

  def _check_ceilings(hpxml_bldg, area: nil, rvalue: nil, floor_type: nil)
    tot_area = 0
    rvalue_x_area_values = [] # Area-weighted
    hpxml_bldg.floors.each do |floor|
      next unless floor.is_ceiling

      tot_area += floor.area
      rvalue_x_area_values << floor.insulation_assembly_r_value * floor.area
      assert_equal(floor_type, floor.floor_type)
    end

    if area.nil?
      assert_equal(0, tot_area)
    else
      assert_in_epsilon(area, tot_area, 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    end
  end

  def _check_floors(hpxml_bldg, area: nil, rvalue: nil, floor_type: nil)
    tot_area = 0
    rvalue_x_area_values = [] # Area-weighted
    hpxml_bldg.floors.each do |floor|
      next unless floor.is_floor

      tot_area += floor.area
      rvalue_x_area_values << floor.insulation_assembly_r_value * floor.area
      assert_equal(floor_type, floor.floor_type)
    end

    if area.nil?
      assert_equal(0, tot_area)
    else
      assert_in_epsilon(area, tot_area, 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.sum / tot_area, 0.01)
    end
  end

  def _check_slabs(hpxml_bldg, area:, exp_perim:, perim_ins_depth: 0, perim_ins_r: 0, under_ins_width: 0,
                   under_ins_r: 0, depth_below_grade: nil)
    tot_area = 0
    exp_perim_x_area_values, perim_ins_depth_x_area_values, perim_ins_r_x_area_values = [], [], [] # Area-weighted
    under_ins_width_x_area_values, under_ins_r_x_area_values, depth_bg_x_area_values = [], [], [] # Area-weighted
    hpxml_bldg.slabs.each do |slab|
      tot_area += slab.area
      exp_perim_x_area_values << slab.exposed_perimeter * slab.area
      perim_ins_depth_x_area_values << slab.perimeter_insulation_depth * slab.area
      perim_ins_r_x_area_values << slab.perimeter_insulation_r_value * slab.area
      if not slab.under_slab_insulation_width.nil?
        under_ins_width_x_area_values << slab.under_slab_insulation_width * slab.area
      elsif slab.under_slab_insulation_spans_entire_slab
        under_ins_width_x_area_values << 999 * slab.area
      end
      under_ins_r_x_area_values << slab.under_slab_insulation_r_value * slab.area
      if not slab.depth_below_grade.nil?
        depth_bg_x_area_values << slab.depth_below_grade * slab.area
      end
    end

    assert_in_epsilon(area, tot_area, 0.01)
    assert_in_epsilon(exp_perim, exp_perim_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(perim_ins_depth, perim_ins_depth_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(perim_ins_r, perim_ins_r_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(under_ins_width, under_ins_width_x_area_values.sum / tot_area, 0.01)
    assert_in_epsilon(under_ins_r, under_ins_r_x_area_values.sum / tot_area, 0.01)
    if depth_below_grade.nil?
      assert(depth_bg_x_area_values.empty?)
    else
      assert_in_epsilon(depth_below_grade, depth_bg_x_area_values.sum / tot_area, 0.01)
    end
  end

  def _check_windows(hpxml_bldg, frac_operable:, values_by_azimuth: {})
    tot_area, operable_area = 0, 0
    azimuth_area_values = {}
    azimuth_ufactor_x_area_values, azimuth_shgc_x_area_values = {}, {} # Area-weighted
    hpxml_bldg.windows.each do |window|
      tot_area += window.area
      operable_area += (window.area * window.fraction_operable)

      # Init if needed
      azimuth_area_values[window.azimuth] = [] if azimuth_area_values[window.azimuth].nil?
      azimuth_ufactor_x_area_values[window.azimuth] = [] if azimuth_ufactor_x_area_values[window.azimuth].nil?
      azimuth_shgc_x_area_values[window.azimuth] = [] if azimuth_shgc_x_area_values[window.azimuth].nil?

      # Update
      azimuth_area_values[window.azimuth] << window.area
      azimuth_ufactor_x_area_values[window.azimuth] << window.ufactor * window.area
      azimuth_shgc_x_area_values[window.azimuth] << window.shgc * window.area
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_ufactor_x_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_shgc_x_area_values.size)

    assert_in_epsilon(frac_operable, operable_area / tot_area, 0.01)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:ufactor], azimuth_ufactor_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:shgc], azimuth_shgc_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
    end
  end

  def _check_overhangs(hpxml_bldg)
    num_overhangs = 0
    hpxml_bldg.windows.each do |window|
      next if window.overhangs_depth.nil?

      num_overhangs += 1
    end
    assert_equal(0, num_overhangs)
  end

  def _check_skylights(hpxml_bldg)
    assert_equal(0, hpxml_bldg.skylights.size)
  end

  def _check_doors(hpxml_bldg, values_by_azimuth: {})
    azimuth_area_values = {}
    azimuth_rvalue_x_area_values = {} # Area-weighted
    hpxml_bldg.doors.each do |door|
      # Init if needed
      azimuth_area_values[door.azimuth] = [] if azimuth_area_values[door.azimuth].nil?
      azimuth_rvalue_x_area_values[door.azimuth] = [] if azimuth_rvalue_x_area_values[door.azimuth].nil?

      # Update
      azimuth_area_values[door.azimuth] << door.area
      azimuth_rvalue_x_area_values[door.azimuth] << door.r_value * door.area
    end

    assert_equal(values_by_azimuth.keys.size, azimuth_area_values.size)
    assert_equal(values_by_azimuth.keys.size, azimuth_rvalue_x_area_values.size)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].sum, 0.01)
      assert_in_epsilon(values[:rvalue], azimuth_rvalue_x_area_values[azimuth].sum / azimuth_area_values[azimuth].sum, 0.01)
    end
  end
end
