# frozen_string_literal: true

require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require_relative '../main.rb'
require 'fileutils'
require_relative 'util.rb'

class EnergyStarZeroEnergyReadyHomeEnclosureTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @tmp_hpxml_path = File.join(@root_path, 'workflow', 'sample_files', 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_enclosure_infiltration
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.SFNationalVer3_0
        value, units = 4.0, 'ACH'
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFOregonWashingtonVer3_2].include? program_version
        value, units = 3.0, 'ACH'
      elsif program_version == ESConstants.SFPacificVer3_0
        value, units = 6.0, 'ACH'
      elsif program_version == ESConstants.SFFloridaVer3_1
        value, units = 5.0, 'ACH'
      elsif ESConstants.MFVersions.include? program_version
        value, units = 1564.8, 'CFM'
      elsif [ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        value, units = 2.0, 'ACH'
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_infiltration(hpxml, value, units)
    end

    ESConstants.MFVersions.each do |program_version|
      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_infiltration(hpxml, 834.0, 'CFM')
    end

    [*ESConstants.NationalVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.SFNationalVer3_0
        value, units = 6.0, 'ACH'
      elsif program_version == ESConstants.SFNationalVer3_1
        value, units = 4.0, 'ACH'
      elsif [ESConstants.SFNationalVer3_2, ZERHConstants.Ver1].include? program_version
        value, units = 3.0, 'ACH'
      elsif program_version == ZERHConstants.SFVer2
        value, units = 2.75, 'ACH'
      elsif ESConstants.MFVersions.include? program_version
        value, units = 1170.0, 'CFM'
      end

      _convert_to_es_zerh('base-location-miami-fl.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_infiltration(hpxml, value, units)
    end
  end

  def test_enclosure_roofs
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      next if program_version == ESConstants.SFPacificVer3_0

      if [ESConstants.SFFloridaVer3_1].include? program_version
        rb_grade = 1
      else
        rb_grade = nil
      end
      adjacent_to = HPXML::LocationAtticVented
      rvalue = 2.3

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_roofs(hpxml, area: 1510, rvalue: rvalue, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: adjacent_to)

      if [ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        # Ducts remain in living space, so no need to transition roof to vented attic
        adjacent_to = HPXML::LocationLivingSpace
        rvalue = 25.8
      end

      _convert_to_es_zerh('base-atticroof-cathedral.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_roofs(hpxml, area: 1510, rvalue: rvalue, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: adjacent_to)

      _convert_to_es_zerh('base-atticroof-flat.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_roofs(hpxml, area: 1350, rvalue: rvalue, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: adjacent_to)
    end

    ESConstants.MFVersions.each do |program_version|
      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_roofs(hpxml)
    end

    # Radiant barrier: In climate zones 1-3, if > 10 linear ft. of ductwork are located in unconditioned attic
    [*ESConstants.NationalVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '1A'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0].include? program_version
        rb_grade = 1
      else
        rb_grade = nil
      end
      _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: HPXML::LocationAtticVented)
    end

    # SFPacificVer3_0 - Regional test
    ['HI', 'GU', 'MP'].each do |state_code|
      if state_code == 'HI'
        rb_grade = nil
      else
        rb_grade = 1
      end

      # In both HI and GU, if > 10 linear ft. of ductwork are located in unconditioned attic, place radiant barrier
      _convert_to_es_zerh('base.xml', ESConstants.SFPacificVer3_0, state_code)
      hpxml = _test_ruleset(ESConstants.SFPacificVer3_0)
      _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: 1, adjacent_to: HPXML::LocationAtticVented)

      _convert_to_es_zerh('base-atticroof-cathedral.xml', ESConstants.SFPacificVer3_0, state_code)
      hpxml = _test_ruleset(ESConstants.SFPacificVer3_0)
      _check_roofs(hpxml, area: 1510, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: HPXML::LocationAtticVented)

      _convert_to_es_zerh('base-atticroof-flat.xml', ESConstants.SFPacificVer3_0, state_code)
      hpxml = _test_ruleset(ESConstants.SFPacificVer3_0)
      _check_roofs(hpxml, area: 1350, rvalue: 2.3, sabs: 0.92, emit: 0.9, rb_grade: rb_grade, adjacent_to: HPXML::LocationAtticVented)
    end
  end

  def test_enclosure_walls
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      next if program_version == ESConstants.SFPacificVer3_0

      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ESConstants.SFFloridaVer3_1].include? program_version
        rvalue = 1.0 / 0.082
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.056
      elsif [ZERHConstants.Ver1].include? program_version
        rvalue = 1.0 / 0.060
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
        rvalue = 1.0 / 0.045
      else
        rvalue = 1.0 / 0.057
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_walls(hpxml, area: 1425, rvalue: (rvalue * 1200 + 4.0 * 225) / 1425, sabs: 0.75, emit: 0.9)

      _convert_to_es_zerh('base-atticroof-conditioned.xml', program_version)
      hpxml = _test_ruleset(program_version)
      if ESConstants.MFVersions.include? program_version
        _check_walls(hpxml, area: 1806, rvalue: (rvalue * 1440 + 4.0 * 366) / 1806, sabs: 0.75, emit: 0.9)
      else
        _check_walls(hpxml, area: 1806, rvalue: (rvalue * 1756 + 4.0 * 50) / 1806, sabs: 0.75, emit: 0.9)
      end

      _convert_to_es_zerh('base-enclosure-garage.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_walls(hpxml, area: 2098, rvalue: (rvalue * 1200 + 4.0 * 898) / 2098, sabs: 0.75, emit: 0.9)
    end

    ESConstants.MFVersions.each do |program_version|
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif program_version == ESConstants.MFNationalVer1_2
        rvalue = 1.0 / 0.045
      elsif program_version == ESConstants.MFOregonWashingtonVer1_2
        rvalue = 1.0 / 0.056
      end

      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_walls(hpxml, area: 980, rvalue: (rvalue * 686 + 4.0 * 294) / 980, sabs: 0.75, emit: 0.9)

      _convert_to_es_zerh('base-bldgtype-multifamily-adjacent-to-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_walls(hpxml, area: 1086, rvalue: (rvalue * 686 + 4.0 * 400) / 1086, sabs: 0.75, emit: 0.9)
    end

    # SFPacificVer3_0 - Regional test
    ['HI', 'GU', 'MP'].each do |state_code|
      if state_code == 'HI'
        rvalue = 1 / 0.082
      else
        rvalue = 1 / 0.401
      end

      _convert_to_es_zerh('base.xml', ESConstants.SFPacificVer3_0, state_code)
      hpxml = _test_ruleset(ESConstants.SFPacificVer3_0)
      _check_walls(hpxml, area: 1425, rvalue: (rvalue * 1200 + 4.0 * 225) / 1425, sabs: 0.75, emit: 0.9)

      _convert_to_es_zerh('base-atticroof-conditioned.xml', ESConstants.SFPacificVer3_0, state_code)
      hpxml = _test_ruleset(ESConstants.SFPacificVer3_0)
      _check_walls(hpxml, area: 1806, rvalue: (rvalue * 1756 + 4.0 * 50) / 1806, sabs: 0.75, emit: 0.9)

      _convert_to_es_zerh('base-enclosure-garage.xml', ESConstants.SFPacificVer3_0, state_code)
      hpxml = _test_ruleset(ESConstants.SFPacificVer3_0)
      _check_walls(hpxml, area: 2098, rvalue: (rvalue * 1200 + 4.0 * 898) / 2098, sabs: 0.75, emit: 0.9)
    end
  end

  def test_enclosure_rim_joists
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        rvalue = 1.0 / 0.082
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.056
      elsif [ZERHConstants.Ver1].include? program_version
        rvalue = 1.0 / 0.060
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
        rvalue = 1.0 / 0.045
      else
        rvalue = 1.0 / 0.057
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_rim_joists(hpxml, area: 116, rvalue: rvalue, sabs: 0.75, emit: 0.90)

      _convert_to_es_zerh('base-foundation-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_rim_joists(hpxml, area: 197, rvalue: 4.0, sabs: 0.75, emit: 0.90)
    end
  end

  def test_enclosure_foundation_walls
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.SFNationalVer3_0
        assembly_rvalue = 1.0 / 0.059
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        assembly_rvalue = 1.0 / 0.050
      elsif [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
        ins_interior_rvalue = 7.5
      elsif program_version == ESConstants.MFOregonWashingtonVer1_2
        ins_interior_rvalue = 15.0
      elsif program_version == ESConstants.SFOregonWashingtonVer3_2
        assembly_rvalue = 1.0 / 0.042
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        assembly_rvalue = 1.0 / 0.360
      end

      hpxml_names = ['base.xml',
                     'base-foundation-conditioned-basement-wall-insulation.xml']
      hpxml_names.each do |hpxml_name|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = _test_ruleset(program_version)
        if hpxml_name == 'base-foundation-conditioned-basement-wall-insulation.xml'
          type = HPXML::FoundationWallTypeConcreteBlockFoamCore
        else
          type = nil
        end
        _check_foundation_walls(hpxml, area: 1200, assembly_rvalue: assembly_rvalue, ins_interior_rvalue: ins_interior_rvalue, ins_bottom: 8, height: 8, depth_bg: 7, type: type)
      end
    end

    [*ESConstants.NationalVersions, *ZERHConstants.AllVersions].each do |program_version|
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
        ins_interior_rvalue = 0.0
      else
        assembly_rvalue = 1.0 / 0.360
      end

      hpxml_names = ['base.xml',
                     'base-foundation-conditioned-basement-wall-insulation.xml']
      hpxml_names.each do |hpxml_name|
        _convert_to_es_zerh(hpxml_name, program_version)
        hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
        hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
          climate_zone_iecc.zone = '1A'
        end
        hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
        hpxml.climate_and_risk_zones.weather_station_wmo = 722020
        XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
        hpxml = _test_ruleset(program_version)
        if hpxml_name == 'base-foundation-conditioned-basement-wall-insulation.xml'
          type = HPXML::FoundationWallTypeConcreteBlockFoamCore
        else
          type = nil
        end
        _check_foundation_walls(hpxml, area: 1200, assembly_rvalue: assembly_rvalue, ins_interior_rvalue: ins_interior_rvalue, ins_bottom: 8, height: 8, depth_bg: 7, type: type)
      end
    end

    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_foundation_walls(hpxml, area: 1200, height: 8, depth_bg: 7)

      hpxml_names = ['base-foundation-unvented-crawlspace.xml',
                     'base-foundation-vented-crawlspace.xml']
      hpxml_names.each do |name|
        _convert_to_es_zerh(name, program_version)
        hpxml = _test_ruleset(program_version)
        _check_foundation_walls(hpxml, area: 600, height: 4, depth_bg: 3)
      end
    end
  end

  def test_enclosure_ceilings
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.SFNationalVer3_0
        rvalue = 1.0 / 0.030
      elsif [ESConstants.SFNationalVer3_1, ZERHConstants.Ver1, ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.026
      elsif program_version == ESConstants.MFNationalVer1_0
        rvalue = 1.0 / 0.027
      elsif program_version == ESConstants.MFNationalVer1_1
        rvalue = 1.0 / 0.021
      elsif [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        rvalue = 1.0 / 0.035
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
        rvalue = 1.0 / 0.024
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_ceilings(hpxml, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_zerh('base-enclosure-garage.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_ceilings(hpxml, area: 1950, rvalue: (rvalue * 1350 + 2.1 * 600) / 1950, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_zerh('base-atticroof-cathedral.xml', program_version)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        _check_ceilings(hpxml)
      else
        _check_ceilings(hpxml, area: (1510 * Math.cos(Math.atan(6.0 / 12.0))), rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
      end

      _convert_to_es_zerh('base-atticroof-conditioned.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_ceilings(hpxml, area: 450, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_zerh('base-atticroof-flat.xml', program_version)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        _check_ceilings(hpxml)
      else
        _check_ceilings(hpxml, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
      end
    end

    ESConstants.MFVersions.each do |program_version|
      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_ceilings(hpxml, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_zerh('base-bldgtype-multifamily-adjacent-to-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_ceilings(hpxml, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)

      # Check w/ mass ceilings
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.floors.each do |floor|
        next unless floor.is_ceiling

        floor.floor_type = HPXML::FloorTypeConcrete
      end
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_ceilings(hpxml, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)
    end
  end

  def test_enclosure_floors
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      if [ESConstants.SFNationalVer3_1, ZERHConstants.Ver1, ZERHConstants.SFVer2, ESConstants.SFNationalVer3_0, ESConstants.MFNationalVer1_0,
          ESConstants.MFNationalVer1_1, ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2].include? program_version
        rvalue = 1.0 / 0.033
      elsif program_version == ESConstants.SFPacificVer3_0
        rvalue = 1.0 / 0.257
      elsif program_version == ESConstants.SFFloridaVer3_1
        rvalue = 1.0 / 0.064
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        rvalue = 1.0 / 0.028
      end

      _convert_to_es_zerh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_floors(hpxml, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_zerh('base-foundation-unconditioned-basement-wall-insulation.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_floors(hpxml, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
    end

    ESConstants.MFVersions.each do |program_version|
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        rvalue = 1.0 / 0.033
      elsif program_version == ESConstants.MFOregonWashingtonVer1_2
        rvalue = 1.0 / 0.028
      end

      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_floors(hpxml, area: 900, rvalue: 2.1, floor_type: HPXML::FloorTypeWoodFrame)

      _convert_to_es_zerh('base-bldgtype-multifamily-adjacent-to-multiple.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_floors(hpxml, area: 900, rvalue: (2.1 * 150 + rvalue * 750) / 900, floor_type: HPXML::FloorTypeWoodFrame)

      # Check w/ mass floors
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.floors.each do |floor|
        floor.floor_type = HPXML::FloorTypeConcrete
      end
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      if [ESConstants.MFNationalVer1_0, ESConstants.MFNationalVer1_1].include? program_version
        rvalue = 1.0 / 0.064
      elsif [ESConstants.MFNationalVer1_2].include? program_version
        rvalue = 1.0 / 0.051
      end
      _check_floors(hpxml, area: 900, rvalue: (2.1 * 150 + rvalue * 750) / 900, floor_type: HPXML::FloorTypeWoodFrame)
    end

    [*ESConstants.NationalVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.MFNationalVer1_0
        rvalue = 1.0 / 0.282
      elsif program_version == ESConstants.MFNationalVer1_1
        rvalue = 1.0 / 0.066
      else
        rvalue = 1.0 / 0.064
      end

      _convert_to_es_zerh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '1A'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_floors(hpxml, area: 1350, rvalue: rvalue, floor_type: HPXML::FloorTypeWoodFrame)
    end
  end

  def test_enclosure_slabs
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_slabs(hpxml, area: 1350, exp_perim: 150)
      if [ESConstants.SFPacificVer3_0, ESConstants.SFFloridaVer3_1].include? program_version
        perim_ins_depth = 0
        perim_ins_r = 0
        under_ins_width = 0
        under_ins_r = 0
      elsif [ESConstants.SFOregonWashingtonVer3_2, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        perim_ins_depth = 4
        perim_ins_r = 10
        under_ins_width = 999
        under_ins_r = 10
      elsif [ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2, ZERHConstants.SFVer2].include? program_version
        perim_ins_depth = 4
        perim_ins_r = 10
        under_ins_width = 0
        under_ins_r = 0
      else
        perim_ins_depth = 2
        perim_ins_r = 10
        under_ins_width = 0
        under_ins_r = 0
      end

      _convert_to_es_zerh('base-foundation-slab.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_slabs(hpxml, area: 1350, exp_perim: 150, perim_ins_depth: perim_ins_depth, perim_ins_r: perim_ins_r,
                          under_ins_width: under_ins_width, under_ins_r: under_ins_r, depth_below_grade: 0)
    end

    [*ESConstants.NationalVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_slabs(hpxml, area: 1350, exp_perim: 150)

      _convert_to_es_zerh('base-foundation-slab.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '1A'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_slabs(hpxml, area: 1350, exp_perim: 150, depth_below_grade: 0)
    end
  end

  def test_enclosure_windows
    # SF tests
    [*ESConstants.SFVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.SFNationalVer3_0
        ufactor, shgc = 0.30, 0.40
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.MFNationalVer1_2,
             ZERHConstants.Ver1, ZERHConstants.SFVer2].include? program_version
        ufactor, shgc = 0.27, 0.40
      elsif program_version == ESConstants.SFPacificVer3_0
        ufactor, shgc = 0.60, 0.27
      elsif program_version == ESConstants.SFFloridaVer3_1
        ufactor, shgc = 0.65, 0.27
      elsif program_version == ESConstants.SFOregonWashingtonVer3_2
        ufactor, shgc = 0.27, 0.30
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 74.55, ufactor: ufactor, shgc: shgc },
                                                 180 => { area: 74.55, ufactor: ufactor, shgc: shgc },
                                                 90 => { area: 74.55, ufactor: ufactor, shgc: shgc },
                                                 270 => { area: 74.55, ufactor: ufactor, shgc: shgc } })

      _convert_to_es_zerh('base-foundation-unconditioned-basement.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 50.63, ufactor: ufactor, shgc: shgc },
                                                 180 => { area: 50.63, ufactor: ufactor, shgc: shgc },
                                                 90 => { area: 50.63, ufactor: ufactor, shgc: shgc },
                                                 270 => { area: 50.63, ufactor: ufactor, shgc: shgc } })

      _convert_to_es_zerh('base-atticroof-cathedral.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 77.95, ufactor: ufactor, shgc: shgc },
                                                 180 => { area: 77.95, ufactor: ufactor, shgc: shgc },
                                                 90 => { area: 77.95, ufactor: ufactor, shgc: shgc },
                                                 270 => { area: 77.95, ufactor: ufactor, shgc: shgc } })

      _convert_to_es_zerh('base-atticroof-conditioned.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 107.17, ufactor: ufactor, shgc: shgc },
                                                 180 => { area: 107.17, ufactor: ufactor, shgc: shgc },
                                                 90 => { area: 107.17, ufactor: ufactor, shgc: shgc },
                                                 270 => { area: 107.17, ufactor: ufactor, shgc: shgc } })
    end

    # MF tests
    ESConstants.MFVersions.each do |program_version|
      # Base test (non-structural windows)
      if program_version == ESConstants.MFNationalVer1_0
        ufactor, shgc = 0.30, 0.40
      elsif [ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        ufactor, shgc = 0.27, 0.40
      elsif program_version == ESConstants.MFOregonWashingtonVer1_2
        ufactor, shgc = 0.27, 0.30
      end
      _convert_to_es_zerh('base-bldgtype-multifamily.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 33.34, ufactor: ufactor, shgc: shgc },
                                                 180 => { area: 33.34, ufactor: ufactor, shgc: shgc },
                                                 270 => { area: 50.49, ufactor: ufactor, shgc: shgc } })

      # Test w/ structural fixed windows
      if program_version == ESConstants.MFNationalVer1_0
        ufactor2 = 0.38
      elsif [ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2].include? program_version
        ufactor2 = 0.36
      elsif program_version == ESConstants.MFNationalVer1_2
        ufactor2 = 0.34
      end
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.windows.each do |window|
        next unless window.azimuth == 0

        window.performance_class = HPXML::WindowClassArchitectural
        window.fraction_operable = 0.0
      end
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 33.34, ufactor: ufactor2, shgc: shgc },
                                                 180 => { area: 33.34, ufactor: ufactor, shgc: shgc },
                                                 270 => { area: 50.49, ufactor: ufactor, shgc: shgc } })

      # Test w/ structural operable windows
      if program_version == ESConstants.MFNationalVer1_0
        ufactor3 = 0.45
      elsif [ESConstants.MFNationalVer1_1, ESConstants.MFOregonWashingtonVer1_2, ESConstants.MFNationalVer1_2].include? program_version
        ufactor3 = 0.43
      end
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.windows.each do |window|
        next unless window.azimuth == 180

        window.performance_class = HPXML::WindowClassArchitectural
        window.fraction_operable = 1.0
      end
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: 33.34, ufactor: ufactor2, shgc: shgc },
                                                 180 => { area: 33.34, ufactor: ufactor3, shgc: shgc },
                                                 270 => { area: 50.49, ufactor: ufactor, shgc: shgc } })
    end

    # Test in Climate Zone 1A
    [*ESConstants.NationalVersions, *ZERHConstants.AllVersions].each do |program_version|
      if program_version == ESConstants.SFNationalVer3_0
        ufactor, shgc = 0.60, 0.27
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ZERHConstants.Ver1].include? program_version
        ufactor, shgc = 0.40, 0.25
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif [ZERHConstants.SFVer2].include? program_version
        ufactor, shgc = 0.40, 0.23
        areas = [74.55, 74.55, 74.55, 74.55]
      elsif program_version == ESConstants.MFNationalVer1_0
        ufactor, shgc = 0.60, 0.27
        areas = [89.46, 89.46, 59.64, 59.64]
      elsif [ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2].include? program_version
        ufactor, shgc = 0.40, 0.25
        areas = [89.46, 89.46, 59.64, 59.64]
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = HPXML.new(hpxml_path: @tmp_hpxml_path)
      hpxml.climate_and_risk_zones.climate_zone_ieccs.each do |climate_zone_iecc|
        climate_zone_iecc.zone = '1A'
      end
      hpxml.climate_and_risk_zones.weather_station_name = 'Miami, FL'
      hpxml.climate_and_risk_zones.weather_station_wmo = 722020
      XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
      hpxml = _test_ruleset(program_version)
      _check_windows(hpxml, frac_operable: 0.67,
                            values_by_azimuth: { 0 => { area: areas[0], ufactor: ufactor, shgc: shgc },
                                                 180 => { area: areas[1], ufactor: ufactor, shgc: shgc },
                                                 90 => { area: areas[2], ufactor: ufactor, shgc: shgc },
                                                 270 => { area: areas[3], ufactor: ufactor, shgc: shgc } })
    end
  end

  def test_enclosure_skylights
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-enclosure-skylights.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_skylights(hpxml)
    end
  end

  def test_enclosure_overhangs
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      _convert_to_es_zerh('base-enclosure-overhangs.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_overhangs(hpxml)
    end
  end

  def test_enclosure_doors
    [*ESConstants.AllVersions, *ZERHConstants.AllVersions].each do |program_version|
      if [ESConstants.SFNationalVer3_1, ESConstants.SFNationalVer3_2, ESConstants.SFOregonWashingtonVer3_2,
          ESConstants.MFNationalVer1_1, ESConstants.MFNationalVer1_2, ESConstants.MFOregonWashingtonVer1_2,
          ZERHConstants.SFVer2].include? program_version
        rvalue = 1.0 / 0.17
      else
        rvalue = 1.0 / 0.21
      end

      _convert_to_es_zerh('base.xml', program_version)
      hpxml = _test_ruleset(program_version)
      _check_doors(hpxml, values_by_azimuth: { 180 => { area: 40, rvalue: rvalue } })
    end
  end

  def _test_ruleset(program_version)
    require_relative '../../workflow/design'
    if ESConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ESConstants.CalcTypeEnergyStarReference)]
    elsif ZERHConstants.AllVersions.include? program_version
      designs = [Design.new(init_calc_type: ZERHConstants.CalcTypeZERHReference)]
    end

    success, errors, _, _, hpxml = run_rulesets(@tmp_hpxml_path, designs)

    errors.each do |s|
      puts "Error: #{s}"
    end

    # assert that it ran correctly
    assert_equal(true, success)

    return hpxml
  end

  def _check_infiltration(hpxml, value, units)
    assert_equal(1, hpxml.air_infiltration_measurements.size)
    air_infiltration_measurement = hpxml.air_infiltration_measurements[0]
    assert_equal(units, air_infiltration_measurement.unit_of_measure)
    assert_equal(50.0, air_infiltration_measurement.house_pressure)
    assert_in_epsilon(value, air_infiltration_measurement.air_leakage, 0.01)
  end

  def _check_roofs(hpxml, area: nil, rvalue: nil, sabs: nil, emit: nil, rb_grade: nil, adjacent_to: nil)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.roofs.each do |roof|
      area_values << roof.area
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
      assert(area_values.empty?)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
  end

  def _check_walls(hpxml, area:, rvalue:, sabs:, emit:)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.walls.each do |wall|
      area_values << wall.area
      rvalue_x_area_values << wall.insulation_assembly_r_value * wall.area
      sabs_x_area_values << wall.solar_absorptance * wall.area
      emit_x_area_values << wall.emittance * wall.area
    end
    assert_in_epsilon(area, area_values.inject(:+), 0.01)
    assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(sabs, sabs_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(emit, emit_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
  end

  def _check_rim_joists(hpxml, area: nil, rvalue: nil, sabs: nil, emit: nil)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    sabs_x_area_values = [] # Area-weighted
    emit_x_area_values = [] # Area-weighted
    hpxml.rim_joists.each do |rim_joist|
      area_values << rim_joist.area
      rvalue_x_area_values << rim_joist.insulation_assembly_r_value * rim_joist.area
      sabs_x_area_values << rim_joist.solar_absorptance * rim_joist.area
      emit_x_area_values << rim_joist.emittance * rim_joist.area
    end

    if area.nil?
      assert(area_values.empty?)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
    if sabs.nil?
      assert(sabs_x_area_values.empty?)
    else
      assert_in_epsilon(sabs, sabs_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
    if emit.nil?
      assert(emit_x_area_values.empty?)
    else
      assert_in_epsilon(emit, emit_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
  end

  def _check_foundation_walls(hpxml, area:, assembly_rvalue: 0, ins_interior_rvalue: 0, ins_top: 0, ins_bottom: 0, height:, depth_bg: 0, type: nil)
    area_values = []
    assembly_rvalue_x_area_values = [] # Area-weighted
    ins_interior_rvalue_x_area_values = [] # Area-weighted
    ins_top_x_area_values = [] # Area-weighted
    ins_bottom_x_area_values = [] # Area-weighted
    height_x_area_values = [] # Area-weighted
    depth_bg_x_area_values = [] # Area-weighted
    hpxml.foundation_walls.each do |foundation_wall|
      area_values << foundation_wall.area
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

    assert_in_epsilon(area, area_values.inject(:+), 0.01)
    assert_in_epsilon(assembly_rvalue, assembly_rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01) unless assembly_rvalue_x_area_values.empty?
    assert_in_epsilon(ins_interior_rvalue, ins_interior_rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01) unless ins_interior_rvalue_x_area_values.empty?
    assert_in_epsilon(ins_top, ins_top_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(ins_bottom, ins_bottom_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(height, height_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(depth_bg, depth_bg_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
  end

  def _check_ceilings(hpxml, area: nil, rvalue: nil, floor_type: nil)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    hpxml.floors.each do |floor|
      next unless floor.is_ceiling

      area_values << floor.area
      rvalue_x_area_values << floor.insulation_assembly_r_value * floor.area
      assert_equal(floor_type, floor.floor_type)
    end

    if area.nil?
      assert(area_values.empty?)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
  end

  def _check_floors(hpxml, area: nil, rvalue: nil, floor_type: nil)
    area_values = []
    rvalue_x_area_values = [] # Area-weighted
    hpxml.floors.each do |floor|
      next unless floor.is_floor

      area_values << floor.area
      rvalue_x_area_values << floor.insulation_assembly_r_value * floor.area
      assert_equal(floor_type, floor.floor_type)
    end

    if area.nil?
      assert(area_values.empty?)
    else
      assert_in_epsilon(area, area_values.inject(:+), 0.01)
    end
    if rvalue.nil?
      assert(rvalue_x_area_values.empty?)
    else
      assert_in_epsilon(rvalue, rvalue_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
  end

  def _check_slabs(hpxml, area:, exp_perim:, perim_ins_depth: 0, perim_ins_r: 0, under_ins_width: 0,
                   under_ins_r: 0, depth_below_grade: nil)
    area_values = []
    exp_perim_x_area_values = [] # Area-weighted
    perim_ins_depth_x_area_values = [] # Area-weighted
    perim_ins_r_x_area_values = [] # Area-weighted
    under_ins_width_x_area_values = [] # Area-weighted
    under_ins_r_x_area_values = [] # Area-weighted
    depth_bg_x_area_values = [] # Area-weighted
    hpxml.slabs.each do |slab|
      area_values << slab.area
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

    assert_in_epsilon(area, area_values.inject(:+), 0.01)
    assert_in_epsilon(exp_perim, exp_perim_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(perim_ins_depth, perim_ins_depth_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(perim_ins_r, perim_ins_r_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(under_ins_width, under_ins_width_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    assert_in_epsilon(under_ins_r, under_ins_r_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    if depth_below_grade.nil?
      assert(depth_bg_x_area_values.empty?)
    else
      assert_in_epsilon(depth_below_grade, depth_bg_x_area_values.inject(:+) / area_values.inject(:+), 0.01)
    end
  end

  def _check_windows(hpxml, frac_operable:, values_by_azimuth: {})
    area_total = 0.0
    area_operable = 0.0
    azimuth_area_values = {}
    azimuth_ufactor_x_area_values = {} # Area-weighted
    azimuth_shgc_x_area_values = {} # Area-weighted
    hpxml.windows.each do |window|
      area_total += window.area
      area_operable += (window.area * window.fraction_operable)

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

    assert_in_epsilon(frac_operable, area_operable / area_total, 0.01)

    values_by_azimuth.each do |azimuth, values|
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].inject(:+), 0.01)
      assert_in_epsilon(values[:ufactor], azimuth_ufactor_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.01)
      assert_in_epsilon(values[:shgc], azimuth_shgc_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.01)
    end
  end

  def _check_overhangs(hpxml)
    num_overhangs = 0
    hpxml.windows.each do |window|
      next if window.overhangs_depth.nil?

      num_overhangs += 1
    end
    assert_equal(0, num_overhangs)
  end

  def _check_skylights(hpxml)
    assert_equal(0, hpxml.skylights.size)
  end

  def _check_doors(hpxml, values_by_azimuth: {})
    azimuth_area_values = {}
    azimuth_rvalue_x_area_values = {} # Area-weighted
    hpxml.doors.each do |door|
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
      assert_in_epsilon(values[:area], azimuth_area_values[azimuth].inject(:+), 0.01)
      assert_in_epsilon(values[:rvalue], azimuth_rvalue_x_area_values[azimuth].inject(:+) / azimuth_area_values[azimuth].inject(:+), 0.01)
    end
  end

  def _convert_to_es_zerh(hpxml_name, program_version, state_code = nil)
    return convert_to_es_zerh(hpxml_name, program_version, @root_path, @tmp_hpxml_path, state_code)
  end
end
