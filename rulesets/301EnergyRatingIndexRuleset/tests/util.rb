# frozen_string_literal: true

def _change_eri_version(hpxml_name, version)
  # Create derivative file w/ changed ERI version
  hpxml = HPXML.new(hpxml_path: File.join(@root_path, 'workflow', 'sample_files', hpxml_name))
  hpxml.header.eri_calculation_version = version

  if Constants.ERIVersions.index(version) < Constants.ERIVersions.index('2019A')
    # Need old input for clothes dryers
    hpxml.clothes_dryers[0].control_type = HPXML::ClothesDryerControlTypeTimer
  end

  hpxml_name = File.basename(@tmp_hpxml_path)
  XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
  return hpxml_name
end

def _all_calc_types()
  return [Constants.CalcTypeERIReferenceHome,
          Constants.CalcTypeERIRatedHome,
          Constants.CalcTypeERIIndexAdjustmentDesign,
          Constants.CalcTypeERIIndexAdjustmentReferenceHome,
          Constants.CalcTypeCO2ReferenceHome]
end
