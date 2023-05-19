# frozen_string_literal: true

require 'oga'
require 'json'
require 'json-schema'
require_relative '../design'
require_relative '../../rulesets/main'
require_relative '../../rulesets/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac_sizing'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlvalidator'

def _run_ruleset(design, xml, out_xml)
  designs = [Design.new(calc_type: design)]
  designs[0].hpxml_output_path = out_xml
  success, _, _, _, _ = run_rulesets(File.absolute_path(xml), designs)

  assert(success)
  assert(File.exist?(out_xml))
end

def _run_workflow(xml, test_name, timeseries_frequency: 'none', component_loads: false,
                  skip_simulation: false, rated_home_only: false, diagnostic_output: false)
  xml = File.absolute_path(xml)
  hpxml = HPXML.new(hpxml_path: xml)

  eri_version = hpxml.header.eri_calculation_version
  co2_version = hpxml.header.co2index_calculation_version
  iecc_eri_version = hpxml.header.iecc_eri_calculation_version
  es_version = hpxml.header.energystar_calculation_version
  zerh_version = hpxml.header.zerh_calculation_version

  rundir = File.join(@test_files_dir, test_name, File.basename(xml))

  flags = ''
  if timeseries_frequency != 'none'
    flags += " --#{timeseries_frequency} ALL"
  end
  if component_loads
    flags += ' --add-component-loads'
  end
  if skip_simulation
    flags += ' --skip-simulation'
  end
  if rated_home_only
    flags += ' --rated-home-only'
  end
  if diagnostic_output && (not eri_version.nil?)
    # ERI required to generate diagnostic output
    flags += ' --diagnostic-output'
  end

  # Run workflow
  workflow_rb = 'energy_rating_index.rb'
  command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(File.dirname(__FILE__), "../#{workflow_rb}")}\" -x \"#{xml}\"#{flags} -o \"#{rundir}\" --debug"
  system(command)

  hpxmls = {}
  csvs = {}
  if rated_home_only
    # ERI w/ Rated Home only
    hpxmls[:rated] = File.join(rundir, 'results', 'ERIRatedHome.xml')
    csvs[:rated_results] = File.join(rundir, 'results', 'ERIRatedHome.csv')
  else
    if not eri_version.nil?
      # ERI
      hpxmls[:ref] = File.join(rundir, 'results', 'ERIReferenceHome.xml')
      hpxmls[:rated] = File.join(rundir, 'results', 'ERIRatedHome.xml')
      csvs[:eri_results] = File.join(rundir, 'results', 'ERI_Results.csv')
      csvs[:eri_worksheet] = File.join(rundir, 'results', 'ERI_Worksheet.csv')
      csvs[:rated_results] = File.join(rundir, 'results', 'ERIRatedHome.csv')
      csvs[:ref_results] = File.join(rundir, 'results', 'ERIReferenceHome.csv')
      if timeseries_frequency != 'none'
        csvs[:rated_timeseries_results] = File.join(rundir, 'results', "ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
        csvs[:ref_timeseries_results] = File.join(rundir, 'results', "ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
      end
    end
    if not co2_version.nil?
      hpxmls[:co2ref] = File.join(rundir, 'results', 'CO2eReferenceHome.xml')
      if File.exist? File.join(rundir, 'results', 'CO2e_Results.csv') # Some HPXMLs (e.g., in AK/HI or with wood fuel) won't produce a CO2 Index
        csvs[:co2e_results] = File.join(rundir, 'results', 'CO2e_Results.csv')
      end
    end
    if not es_version.nil?
      # ENERGY STAR
      hpxmls[:es_ref] = File.join(rundir, 'results', 'ESReference.xml')
      hpxmls[:es_rated] = File.join(rundir, 'results', 'ESRated.xml')
      hpxmls[:esrd_ref] = File.join(rundir, 'results', 'ESReference_ERIReferenceHome.xml')
      hpxmls[:esrd_rated] = File.join(rundir, 'results', 'ESReference_ERIRatedHome.xml')
      hpxmls[:esrd_iad] = File.join(rundir, 'results', 'ESReference_ERIIndexAdjustmentDesign.xml')
      hpxmls[:esrd_iadref] = File.join(rundir, 'results', 'ESReference_ERIIndexAdjustmentReferenceHome.xml')
      hpxmls[:esrat_ref] = File.join(rundir, 'results', 'ESRated_ERIReferenceHome.xml')
      hpxmls[:esrat_rated] = File.join(rundir, 'results', 'ESRated_ERIRatedHome.xml')
      hpxmls[:esrat_iad] = File.join(rundir, 'results', 'ESRated_ERIIndexAdjustmentDesign.xml')
      hpxmls[:esrat_iadref] = File.join(rundir, 'results', 'ESRated_ERIIndexAdjustmentReferenceHome.xml')
      csvs[:es_results] = File.join(rundir, 'results', 'ES_Results.csv')
      csvs[:esrd_eri_results] = File.join(rundir, 'results', 'ESReference_ERI_Results.csv')
      csvs[:esrd_eri_worksheet] = File.join(rundir, 'results', 'ESReference_ERI_Worksheet.csv')
      csvs[:esrat_eri_results] = File.join(rundir, 'results', 'ESRated_ERI_Results.csv')
      csvs[:esrat_eri_worksheet] = File.join(rundir, 'results', 'ESRated_ERI_Worksheet.csv')
      csvs[:esrd_rated_results] = File.join(rundir, 'results', 'ESReference_ERIRatedHome.csv')
      csvs[:esrd_ref_results] = File.join(rundir, 'results', 'ESReference_ERIReferenceHome.csv')
      csvs[:esrd_iad_results] = File.join(rundir, 'results', 'ESReference_ERIIndexAdjustmentDesign.csv')
      csvs[:esrd_iadref_results] = File.join(rundir, 'results', 'ESReference_ERIIndexAdjustmentReferenceHome.csv')
      csvs[:esrat_rated_results] = File.join(rundir, 'results', 'ESRated_ERIRatedHome.csv')
      csvs[:esrat_ref_results] = File.join(rundir, 'results', 'ESRated_ERIReferenceHome.csv')
      csvs[:esrat_iad_results] = File.join(rundir, 'results', 'ESRated_ERIIndexAdjustmentDesign.csv')
      csvs[:esrat_iadref_results] = File.join(rundir, 'results', 'ESRated_ERIIndexAdjustmentReferenceHome.csv')
      if timeseries_frequency != 'none'
        csvs[:esrat_timeseries_results] = File.join(rundir, 'results', "ESRated_ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
        csvs[:esrd_timeseries_results] = File.join(rundir, 'results', "ESReference_ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
      end
    end
    if not zerh_version.nil?
      # Zero Energy Ready Home
      hpxmls[:zerh_ref] = File.join(rundir, 'results', 'ZERHReference.xml')
      hpxmls[:zerh_rated] = File.join(rundir, 'results', 'ZERHRated.xml')
      hpxmls[:zerhrd_ref] = File.join(rundir, 'results', 'ZERHReference_ERIReferenceHome.xml')
      hpxmls[:zerhrd_rated] = File.join(rundir, 'results', 'ZERHReference_ERIRatedHome.xml')
      hpxmls[:zerhrd_iad] = File.join(rundir, 'results', 'ZERHReference_ERIIndexAdjustmentDesign.xml')
      hpxmls[:zerhrd_iadref] = File.join(rundir, 'results', 'ZERHReference_ERIIndexAdjustmentReferenceHome.xml')
      hpxmls[:zerhrat_ref] = File.join(rundir, 'results', 'ZERHRated_ERIReferenceHome.xml')
      hpxmls[:zerhrat_rated] = File.join(rundir, 'results', 'ZERHRated_ERIRatedHome.xml')
      hpxmls[:zerhrat_iad] = File.join(rundir, 'results', 'ZERHRated_ERIIndexAdjustmentDesign.xml')
      hpxmls[:zerhrat_iadref] = File.join(rundir, 'results', 'ZERHRated_ERIIndexAdjustmentReferenceHome.xml')
      csvs[:zerh_results] = File.join(rundir, 'results', 'ZERH_Results.csv')
      csvs[:zerhrd_eri_results] = File.join(rundir, 'results', 'ZERHReference_ERI_Results.csv')
      csvs[:zerhrd_eri_worksheet] = File.join(rundir, 'results', 'ZERHReference_ERI_Worksheet.csv')
      csvs[:zerhrat_eri_results] = File.join(rundir, 'results', 'ZERHRated_ERI_Results.csv')
      csvs[:zerhrat_eri_worksheet] = File.join(rundir, 'results', 'ZERHRated_ERI_Worksheet.csv')
      csvs[:zerhrd_rated_results] = File.join(rundir, 'results', 'ZERHReference_ERIRatedHome.csv')
      csvs[:zerhrd_ref_results] = File.join(rundir, 'results', 'ZERHReference_ERIReferenceHome.csv')
      csvs[:zerhrd_iad_results] = File.join(rundir, 'results', 'ZERHReference_ERIIndexAdjustmentDesign.csv')
      csvs[:zerhrd_iadref_results] = File.join(rundir, 'results', 'ZERHReference_ERIIndexAdjustmentReferenceHome.csv')
      csvs[:zerhrat_rated_results] = File.join(rundir, 'results', 'ZERHRated_ERIRatedHome.csv')
      csvs[:zerhrat_ref_results] = File.join(rundir, 'results', 'ZERHRated_ERIReferenceHome.csv')
      csvs[:zerhrat_iad_results] = File.join(rundir, 'results', 'ZERHRated_ERIIndexAdjustmentDesign.csv')
      csvs[:zerhrat_iadref_results] = File.join(rundir, 'results', 'ZERHRated_ERIIndexAdjustmentReferenceHome.csv')
      if timeseries_frequency != 'none'
        csvs[:zerhrat_timeseries_results] = File.join(rundir, 'results', "ZERHRated_ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
        csvs[:zerhrd_timeseries_results] = File.join(rundir, 'results', "ZERHReference_ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
      end
    end
    if not iecc_eri_version.nil?
      hpxmls[:iecc_eri_ref] = File.join(rundir, 'results', 'IECC_ERIReferenceHome.xml')
      hpxmls[:iecc_eri_rated] = File.join(rundir, 'results', 'IECC_ERIRatedHome.xml')
      csvs[:iecc_eri_results] = File.join(rundir, 'results', 'IECC_ERI_Results.csv')
      csvs[:iecc_eri_worksheet] = File.join(rundir, 'results', 'IECC_ERI_Worksheet.csv')
      csvs[:iecc_eri_rated_results] = File.join(rundir, 'results', 'IECC_ERIRatedHome.csv')
      csvs[:iecc_eri_ref_results] = File.join(rundir, 'results', 'IECC_ERIReferenceHome.csv')
      if timeseries_frequency != 'none'
        csvs[:iecc_eri_rated_timeseries_results] = File.join(rundir, 'results', "IECC_ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
        csvs[:iecc_eri_ref_timeseries_results] = File.join(rundir, 'results', "IECC_ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
      end
    end
  end

  # Check all output files exist
  hpxmls.values.each do |hpxml_path|
    puts "Did not find #{hpxml_path}" unless File.exist?(hpxml_path)
    assert(File.exist?(hpxml_path))
  end
  if not skip_simulation
    csvs.values.each do |csv_path|
      puts "Did not find #{csv_path}" unless File.exist?(csv_path)
      assert(File.exist?(csv_path))
    end
  end
  if diagnostic_output && (not eri_version.nil?)
    diag_output_path = File.join(rundir, 'results', 'HERS_Diagnostic.json')
    puts "Did not find #{diag_output_path}" unless File.exist?(diag_output_path)
    assert(File.exist?(diag_output_path))

    # FIXME: Temporarily skip validation on files w/ dehumidifiers
    if hpxml.dehumidifiers.empty?
      # Validate JSON
      valid = true
      schema_dir = File.join(File.dirname(__FILE__), '..', '..', 'rulesets', 'resources', 'hers_diagnostic_output')
      begin
        json_schema_path = File.join(schema_dir, 'HERSDiagnosticOutput.schema.json')
        JSON::Validator.validate!(json_schema_path, JSON.parse(File.read(diag_output_path)))
      rescue JSON::Schema::ValidationError => e
        valid = false
        puts "HERS diagnostic output file did not validate: #{diag_output_path}."
        puts e.message
      end
      assert(valid)
    end
  end

  # Check run.log for OS warnings
  Dir["#{rundir}/*/run.log"].sort.each do |log_path|
    run_log = File.readlines(log_path).map(&:strip)
    run_log.each do |log_line|
      next unless log_line.include? 'OS Message:'
      next if log_line.include?('OS Message: Minutes field (60) on line 9 of EPW file')

      flunk "Unexpected warning found in #{log_path} run.log: #{log_line}"
    end
  end

  return rundir, hpxmls, csvs
end

def _run_simulation(xml, test_name)
  measures_dir = File.join(File.dirname(__FILE__), '..', '..')
  xml = File.absolute_path(xml)
  rundir = File.join(@test_files_dir, test_name, File.basename(xml))

  measures = {}

  # Add HPXML translator measure to workflow
  measure_subdir = 'hpxml-measures/HPXMLtoOpenStudio'
  args = {}
  args['output_dir'] = File.absolute_path(rundir)
  args['hpxml_path'] = xml
  update_args_hash(measures, measure_subdir, args)

  # Add reporting measure to workflow
  measure_subdir = 'hpxml-measures/ReportSimulationOutput'
  args = {}
  args['timeseries_frequency'] = 'none'
  update_args_hash(measures, measure_subdir, args)

  results = run_hpxml_workflow(rundir, measures, measures_dir)

  assert(results[:success])

  csv_path = File.join(rundir, 'results_annual.csv')
  assert(File.exist?(csv_path))

  return csv_path
end

def _get_simulation_load_results(csv_path)
  results = _get_csv_results([csv_path])
  htg_load = results['Load: Heating: Delivered (MBtu)'].round(2)
  clg_load = results['Load: Cooling: Delivered (MBtu)'].round(2)

  return htg_load, clg_load
end

def _get_csv_results(csvs)
  results = {}
  csvs.each do |csv|
    next if csv.nil?
    next unless File.exist? csv

    CSV.foreach(csv) do |row|
      next if row.nil? || (row.size < 2)

      key, value = row

      # Convert to numeric values for CI comparison
      value = 1 if value == 'PASS'
      value = 0 if value == 'FAIL'

      if csv.include? 'IECC_'
        key = "IECC #{key}"
      elsif csv.include? 'ES_'
        key = "ES #{key}"
      elsif csv.include? 'ZERH_'
        key = "ZERH #{key}"
      end
      if value.to_s.include? ',' # Sum values for visualization on CI
        results[key] = value.split(',').map(&:to_f).sum
      else
        results[key] = Float(value)
      end
    end
  end

  return results
end

def _rm_path(path)
  if Dir.exist?(path)
    FileUtils.rm_r(path)
  end
  while true
    break if not Dir.exist?(path)

    sleep(0.01)
  end
end

def _test_resnet_hot_water(test_name, dir_name)
  test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
  File.delete(test_results_csv) if File.exist? test_results_csv

  # Run simulations
  all_results = {}
  xmldir = File.join(File.dirname(__FILE__), dir_name)
  Dir["#{xmldir}/*.xml"].sort.each do |xml|
    # TODO: We can remove the _run_ruleset call if we address https://github.com/NREL/OpenStudio-ERI/issues/541
    out_xml = File.join(@test_files_dir, File.basename(xml))
    _run_ruleset(Constants.CalcTypeERIRatedHome, xml, out_xml)

    csv_path = _run_simulation(out_xml, test_name)

    all_results[File.basename(xml)] = _get_hot_water(csv_path)
    assert_operator(all_results[File.basename(xml)][0], :>, 0)

    File.delete(out_xml)
  end
  assert(all_results.size > 0)

  # Write results to csv
  dhw_energy = {}
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Test Case', 'DHW Energy (therms)', 'Recirc Pump (kWh)', 'GPD']
    all_results.each do |xml, result|
      rated_dhw, rated_recirc, rated_gpd = result
      csv << [xml, (rated_dhw * 10.0).round(1), (rated_recirc * 293.08).round(1), rated_gpd]
      test_name = File.basename(xml, File.extname(xml))
      dhw_energy[test_name] = rated_dhw + rated_recirc
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return dhw_energy
end

def _test_resnet_hers_reference_home_auto_generation(test_name, dir_name)
  test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
  File.delete(test_results_csv) if File.exist? test_results_csv

  # Run simulations
  all_results = {}
  xmldir = File.join(File.dirname(__FILE__), dir_name)
  Dir["#{xmldir}/*.xml"].sort.each do |xml|
    out_xml = File.join(@test_files_dir, test_name, File.basename(xml), File.basename(xml))
    _run_ruleset(Constants.CalcTypeERIReferenceHome, xml, out_xml)
    test_num = File.basename(xml)[0, 2].to_i
    all_results[File.basename(xml)] = _get_reference_home_components(out_xml, test_num)

    # Update HPXML to override mech vent fan power for eRatio test
    new_hpxml = HPXML.new(hpxml_path: out_xml)
    new_hpxml.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      if (vent_fan.fan_type == HPXML::MechVentTypeSupply) || (vent_fan.fan_type == HPXML::MechVentTypeExhaust)
        vent_fan.fan_power = 0.35 * vent_fan.tested_flow_rate
      elsif vent_fan.fan_type == HPXML::MechVentTypeBalanced
        vent_fan.fan_power = 0.70 * vent_fan.tested_flow_rate
      elsif (vent_fan.fan_type == HPXML::MechVentTypeERV) || (vent_fan.fan_type == HPXML::MechVentTypeHRV)
        vent_fan.fan_power = 1.00 * vent_fan.tested_flow_rate
      elsif vent_fan.fan_type == HPXML::MechVentTypeCFIS
        vent_fan.fan_power = 0.50 * vent_fan.tested_flow_rate
      end
    end
    XMLHelper.write_file(new_hpxml.to_oga, out_xml)

    _rundir, _hpxmls, csvs = _run_workflow(out_xml, test_name)
    worksheet_results = _get_csv_results([csvs[:eri_worksheet]])
    all_results[File.basename(xml)]['e-Ratio'] = (worksheet_results['Total Loads TnML'] / worksheet_results['Total Loads TRL']).round(7)
  end
  assert(all_results.size > 0)

  # Write results to csv
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Component', 'Test 1 Results', 'Test 2 Results', 'Test 3 Results', 'Test 4 Results']
    all_results['01-L100.xml'].keys.each do |component|
      csv << [component,
              all_results['01-L100.xml'][component],
              all_results['02-L100.xml'][component],
              all_results['03-L304.xml'][component],
              all_results['04-L324.xml'][component]]
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return all_results
end

def _test_resnet_hers_method(test_name, dir_name)
  test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
  File.delete(test_results_csv) if File.exist? test_results_csv

  # Run simulations
  all_results = {}
  xmldir = File.join(File.dirname(__FILE__), dir_name)
  Dir["#{xmldir}/*.xml"].sort.each do |xml|
    _rundir, _hpxmls, csvs = _run_workflow(xml, test_name)
    all_results[xml] = _get_csv_results([csvs[:eri_results]])
    all_results[xml].delete('EC_x Dehumid (MBtu)') # Not yet included in RESNET spreadsheet
  end
  assert(all_results.size > 0)

  # Write results to csv
  keys = all_results.values[0].keys
  CSV.open(test_results_csv, 'w') do |csv|
    csv << ['Test Case'] + keys
    all_results.each do |xml, results|
      csv_line = [File.basename(xml)]
      keys.each do |key|
        csv_line << results[key]
      end
      csv << csv_line
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return all_results
end

def _get_simulation_hvac_energy_results(csv_path, is_heat, is_electric_heat)
  results = _get_csv_results([csv_path])
  if not is_heat
    hvac = UnitConversions.convert(results["End Use: #{FT::Elec}: #{EUT::Cooling} (MBtu)"], 'MBtu', 'kwh').round(2)
    hvac_fan = UnitConversions.convert(results["End Use: #{FT::Elec}: #{EUT::CoolingFanPump} (MBtu)"], 'MBtu', 'kwh').round(2)
  else
    if is_electric_heat
      hvac = UnitConversions.convert(results["End Use: #{FT::Elec}: #{EUT::Heating} (MBtu)"], 'MBtu', 'kwh').round(2)
    else
      hvac = UnitConversions.convert(results["End Use: #{FT::Gas}: #{EUT::Heating} (MBtu)"], 'MBtu', 'therm').round(2)
    end
    hvac_fan = UnitConversions.convert(results["End Use: #{FT::Elec}: #{EUT::HeatingFanPump} (MBtu)"], 'MBtu', 'kwh').round(2)
  end

  assert_operator(hvac, :>, 0)
  assert_operator(hvac_fan, :>, 0)

  return hvac.round(2), hvac_fan.round(2)
end

def _check_ashrae_140_results(htg_loads, clg_loads)
  # Proposed acceptance criteria as of 8/17/2022
  htg_min = [48.06, 74.30, 35.98, 39.74, 45.72, 39.12, 42.16, 48.30, 58.15, 121.75, 126.71, 23.91, 26.93, 55.09, 46.62]
  htg_max = [61.35, 82.96, 48.09, 49.95, 51.97, 55.54, 58.15, 63.39, 74.24, 137.68, 146.84, 81.95, 70.53, 92.73, 56.46]
  htg_dt_min = [17.53, -16.08, -12.92, -12.14, -10.89, -0.56, -1.95, 8.16, 71.16, 3.20, -26.32, -3.05, 5.87, 5.10]
  htg_dt_max = [29.62, -9.45, -5.89, 0.24, -3.37, 6.42, 4.54, 15.14, 79.06, 11.26, 22.75, 11.45, 32.54, 39.08]
  clg_min = [42.49, 47.72, 41.14, 31.55, 21.03, 50.55, 36.62, 52.25, 34.16, 57.07, 50.19]
  clg_max = [58.66, 61.33, 51.69, 41.84, 29.35, 73.47, 59.72, 68.60, 47.58, 73.51, 60.72]
  clg_dt_min = [0.69, -8.24, -18.53, -30.58, 7.51, -16.52, 6.75, -12.95, 11.62, 5.12]
  clg_dt_max = [6.91, -0.22, -9.74, -20.47, 15.77, -11.16, 12.76, -6.58, 17.59, 14.14]

  # Annual Heating Loads
  assert_operator(htg_loads['L100AC'], :<=, htg_max[0])
  assert_operator(htg_loads['L100AC'], :>=, htg_min[0])
  assert_operator(htg_loads['L110AC'], :<=, htg_max[1])
  assert_operator(htg_loads['L110AC'], :>=, htg_min[1])
  assert_operator(htg_loads['L120AC'], :<=, htg_max[2])
  assert_operator(htg_loads['L120AC'], :>=, htg_min[2])
  assert_operator(htg_loads['L130AC'], :<=, htg_max[3])
  assert_operator(htg_loads['L130AC'], :>=, htg_min[3])
  assert_operator(htg_loads['L140AC'], :<=, htg_max[4])
  assert_operator(htg_loads['L140AC'], :>=, htg_min[4])
  assert_operator(htg_loads['L150AC'], :<=, htg_max[5])
  assert_operator(htg_loads['L150AC'], :>=, htg_min[5])
  assert_operator(htg_loads['L155AC'], :<=, htg_max[6])
  assert_operator(htg_loads['L155AC'], :>=, htg_min[6])
  assert_operator(htg_loads['L160AC'], :<=, htg_max[7])
  assert_operator(htg_loads['L160AC'], :>=, htg_min[7])
  assert_operator(htg_loads['L170AC'], :<=, htg_max[8])
  assert_operator(htg_loads['L170AC'], :>=, htg_min[8])
  assert_operator(htg_loads['L200AC'], :<=, htg_max[9])
  assert_operator(htg_loads['L200AC'], :>=, htg_min[9])
  assert_operator(htg_loads['L202AC'], :<=, htg_max[10])
  assert_operator(htg_loads['L202AC'], :>=, htg_min[10])
  assert_operator(htg_loads['L302XC'], :<=, htg_max[11])
  assert_operator(htg_loads['L302XC'], :>=, htg_min[11])
  assert_operator(htg_loads['L304XC'], :<=, htg_max[12])
  assert_operator(htg_loads['L304XC'], :>=, htg_min[12])
  assert_operator(htg_loads['L322XC'], :<=, htg_max[13])
  assert_operator(htg_loads['L322XC'], :>=, htg_min[13])
  assert_operator(htg_loads['L324XC'], :<=, htg_max[14])
  assert_operator(htg_loads['L324XC'], :>=, htg_min[14])

  # Annual Heating Load Deltas
  assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :<=, htg_dt_max[0])
  assert_operator(htg_loads['L110AC'] - htg_loads['L100AC'], :>=, htg_dt_min[0])
  assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :<=, htg_dt_max[1])
  assert_operator(htg_loads['L120AC'] - htg_loads['L100AC'], :>=, htg_dt_min[1])
  assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :<=, htg_dt_max[2])
  assert_operator(htg_loads['L130AC'] - htg_loads['L100AC'], :>=, htg_dt_min[2])
  assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :<=, htg_dt_max[3])
  assert_operator(htg_loads['L140AC'] - htg_loads['L100AC'], :>=, htg_dt_min[3])
  assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :<=, htg_dt_max[4])
  assert_operator(htg_loads['L150AC'] - htg_loads['L100AC'], :>=, htg_dt_min[4])
  assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :<=, htg_dt_max[5])
  assert_operator(htg_loads['L155AC'] - htg_loads['L150AC'], :>=, htg_dt_min[5])
  assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :<=, htg_dt_max[6])
  assert_operator(htg_loads['L160AC'] - htg_loads['L100AC'], :>=, htg_dt_min[6])
  assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :<=, htg_dt_max[7])
  assert_operator(htg_loads['L170AC'] - htg_loads['L100AC'], :>=, htg_dt_min[7])
  assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :<=, htg_dt_max[8])
  assert_operator(htg_loads['L200AC'] - htg_loads['L100AC'], :>=, htg_dt_min[8])
  assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :<=, htg_dt_max[9])
  assert_operator(htg_loads['L202AC'] - htg_loads['L200AC'], :>=, htg_dt_min[9])
  assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :<=, htg_dt_max[10])
  assert_operator(htg_loads['L302XC'] - htg_loads['L100AC'], :>=, htg_dt_min[10])
  assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :<=, htg_dt_max[11])
  assert_operator(htg_loads['L302XC'] - htg_loads['L304XC'], :>=, htg_dt_min[11])
  assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :<=, htg_dt_max[12])
  assert_operator(htg_loads['L322XC'] - htg_loads['L100AC'], :>=, htg_dt_min[12])
  assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :<=, htg_dt_max[13])
  assert_operator(htg_loads['L322XC'] - htg_loads['L324XC'], :>=, htg_dt_min[13])

  # Annual Cooling Loads
  assert_operator(clg_loads['L100AL'], :<=, clg_max[0])
  assert_operator(clg_loads['L100AL'], :>=, clg_min[0])
  assert_operator(clg_loads['L110AL'], :<=, clg_max[1])
  assert_operator(clg_loads['L110AL'], :>=, clg_min[1])
  assert_operator(clg_loads['L120AL'], :<=, clg_max[2])
  assert_operator(clg_loads['L120AL'], :>=, clg_min[2])
  assert_operator(clg_loads['L130AL'], :<=, clg_max[3])
  assert_operator(clg_loads['L130AL'], :>=, clg_min[3])
  assert_operator(clg_loads['L140AL'], :<=, clg_max[4])
  assert_operator(clg_loads['L140AL'], :>=, clg_min[4])
  assert_operator(clg_loads['L150AL'], :<=, clg_max[5])
  assert_operator(clg_loads['L150AL'], :>=, clg_min[5])
  assert_operator(clg_loads['L155AL'], :<=, clg_max[6])
  assert_operator(clg_loads['L155AL'], :>=, clg_min[6])
  assert_operator(clg_loads['L160AL'], :<=, clg_max[7])
  assert_operator(clg_loads['L160AL'], :>=, clg_min[7])
  assert_operator(clg_loads['L170AL'], :<=, clg_max[8])
  assert_operator(clg_loads['L170AL'], :>=, clg_min[8])
  assert_operator(clg_loads['L200AL'], :<=, clg_max[9])
  assert_operator(clg_loads['L200AL'], :>=, clg_min[9])
  assert_operator(clg_loads['L202AL'], :<=, clg_max[10])
  assert_operator(clg_loads['L202AL'], :>=, clg_min[10])

  # Annual Cooling Load Deltas
  assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :<=, clg_dt_max[0])
  assert_operator(clg_loads['L110AL'] - clg_loads['L100AL'], :>=, clg_dt_min[0])
  assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :<=, clg_dt_max[1])
  assert_operator(clg_loads['L120AL'] - clg_loads['L100AL'], :>=, clg_dt_min[1])
  assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :<=, clg_dt_max[2])
  assert_operator(clg_loads['L130AL'] - clg_loads['L100AL'], :>=, clg_dt_min[2])
  assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :<=, clg_dt_max[3])
  assert_operator(clg_loads['L140AL'] - clg_loads['L100AL'], :>=, clg_dt_min[3])
  assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :<=, clg_dt_max[4])
  assert_operator(clg_loads['L150AL'] - clg_loads['L100AL'], :>=, clg_dt_min[4])
  assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :<=, clg_dt_max[5])
  assert_operator(clg_loads['L155AL'] - clg_loads['L150AL'], :>=, clg_dt_min[5])
  assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :<=, clg_dt_max[6])
  assert_operator(clg_loads['L160AL'] - clg_loads['L100AL'], :>=, clg_dt_min[6])
  assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :<=, clg_dt_max[7])
  assert_operator(clg_loads['L170AL'] - clg_loads['L100AL'], :>=, clg_dt_min[7])
  assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :<=, clg_dt_max[8])
  assert_operator(clg_loads['L200AL'] - clg_loads['L100AL'], :>=, clg_dt_min[8])
  assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :<=, clg_dt_max[9])
  assert_operator(clg_loads['L200AL'] - clg_loads['L202AL'], :>=, clg_dt_min[9])
end

def _get_reference_home_components(hpxml, test_num)
  results = {}
  hpxml = HPXML.new(hpxml_path: hpxml)

  # Above-grade walls
  wall_u, wall_solar_abs, wall_emiss, _wall_area = _get_above_grade_walls(hpxml)
  results['Above-grade walls (Uo)'] = wall_u.round(3)
  results['Above-grade wall solar absorptance (α)'] = wall_solar_abs.round(2)
  results['Above-grade wall infrared emittance (ε)'] = wall_emiss.round(2)

  # Basement walls
  bsmt_wall_r = _get_basement_walls(hpxml)
  if test_num == 4
    results['Basement walls insulation R-Value'] = bsmt_wall_r.round(0)
  else
    results['Basement walls insulation R-Value'] = 'n/a'
  end
  results['Basement walls (Uo)'] = 'n/a'

  # Above-grade floors
  floors_u = _get_above_grade_floors(hpxml)
  if test_num <= 2
    results['Above-grade floors (Uo)'] = floors_u.round(3)
  else
    results['Above-grade floors (Uo)'] = 'n/a'
  end

  # Slab insulation
  slab_r, carpet_r, exp_mas_floor_area = _get_hpxml_slabs(hpxml)
  if test_num >= 3
    results['Slab insulation R-Value'] = slab_r.round(0)
  else
    results['Slab insulation R-Value'] = 'n/a'
  end

  # Ceilings
  ceil_u, _ceil_area = _get_ceilings(hpxml)
  results['Ceilings (Uo)'] = ceil_u.round(3)

  # Roofs
  roof_solar_abs, roof_emiss, _roof_area = _get_roofs(hpxml)
  results['Roof solar absorptance (α)'] = roof_solar_abs.round(2)
  results['Roof infrared emittance (ε)'] = roof_emiss.round(2)

  # Attic vent area
  attic_vent_area = _get_attic_vent_area(hpxml)
  results['Attic vent area (ft2)'] = attic_vent_area.round(2)

  # Crawlspace vent area
  crawl_vent_area = _get_crawl_vent_area(hpxml)
  if test_num == 2
    results['Crawlspace vent area (ft2)'] = crawl_vent_area.round(2)
  else
    results['Crawlspace vent area (ft2)'] = 'n/a'
  end

  # Slabs
  if test_num >= 3
    results['Exposed masonry floor area (ft2)'] = exp_mas_floor_area.round(1)
    results['Carpet & pad R-Value'] = carpet_r.round(1)
  else
    results['Exposed masonry floor area (ft2)'] = 'n/a'
    results['Carpet & pad R-Value'] = 'n/a'
  end

  # Doors
  door_u, door_area = _get_doors(hpxml)
  results['Door Area (ft2)'] = door_area.round(0)
  results['Door U-Factor'] = door_u.round(2)

  # Windows
  win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml)
  results['North window area (ft2)'] = win_areas[0].round(2)
  results['South window area (ft2)'] = win_areas[180].round(2)
  results['East window area (ft2)'] = win_areas[90].round(2)
  results['West window area (ft2)'] = win_areas[270].round(2)
  results['Window U-Factor'] = win_u.round(2)
  results['Window SHGCo (heating)'] = win_shgc_htg.round(2)
  results['Window SHGCo (cooling)'] = win_shgc_clg.round(2)

  # Infiltration
  sla, _ach50 = _get_infiltration(hpxml)
  results['SLAo (ft2/ft2)'] = sla.round(5)

  # Internal gains
  xml_it_sens, xml_it_lat = _get_internal_gains(hpxml)
  results['Sensible Internal gains (Btu/day)'] = xml_it_sens.round(0)
  results['Latent Internal gains (Btu/day)'] = xml_it_lat.round(0)

  # HVAC
  afue, hspf, seer, dse = _get_hvac(hpxml)
  if (test_num == 1) || (test_num == 4)
    results['Labeled heating system rating and efficiency'] = afue.round(2)
  else
    results['Labeled heating system rating and efficiency'] = hspf.round(1)
  end
  results['Labeled cooling system rating and efficiency'] = seer.round(1)
  results['Air Distribution System Efficiency'] = dse.round(2)

  # Thermostat
  tstat, htg_sp, clg_sp = _get_tstat(hpxml)
  results['Thermostat Type'] = tstat
  results['Heating thermostat settings'] = htg_sp.round(0)
  results['Cooling thermostat settings'] = clg_sp.round(0)

  # Mechanical ventilation
  mv_kwh, _mv_cfm = _get_mech_vent(hpxml)
  results['Mechanical ventilation (kWh/y)'] = mv_kwh.round(2)

  # Domestic hot water
  ref_pipe_l, ref_loop_l = _get_dhw(hpxml)
  results['DHW pipe length refPipeL'] = ref_pipe_l.round(1)
  results['DHW loop length refLoopL'] = ref_loop_l.round(1)

  return results
end

def _get_iad_home_components(hpxml, test_num)
  results = {}
  hpxml = HPXML.new(hpxml_path: hpxml)

  # Geometry
  results['Number of Stories'] = hpxml.building_construction.number_of_conditioned_floors
  results['Number of Bedrooms'] = hpxml.building_construction.number_of_bedrooms
  results['Conditioned Floor Area (ft2)'] = hpxml.building_construction.conditioned_floor_area
  results['Infiltration Volume (ft3)'] = hpxml.air_infiltration_measurements[0].infiltration_volume

  # Above-grade Walls
  wall_u, _wall_solar_abs, _wall_emiss, wall_area = _get_above_grade_walls(hpxml)
  results['Above-grade walls area (ft2)'] = wall_area
  results['Above-grade walls (Uo)'] = wall_u

  # Roof
  _roof_solar_abs, _roof_emiss, roof_area = _get_roofs(hpxml)
  results['Roof gross area (ft2)'] = roof_area

  # Ceilings
  ceil_u, ceil_area = _get_ceilings(hpxml)
  results['Ceiling gross projected footprint area (ft2)'] = ceil_area
  results['Ceilings (Uo)'] = ceil_u

  # Crawlspace
  crawl_vent_area = _get_crawl_vent_area(hpxml)
  results['Crawlspace vent area (ft2)'] = crawl_vent_area

  # Doors
  door_u, door_area = _get_doors(hpxml)
  results['Door Area (ft2)'] = door_area
  results['Door R-value'] = 1.0 / door_u

  # Windows
  win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml)
  results['North window area (ft2)'] = win_areas[0]
  results['South window area (ft2)'] = win_areas[180]
  results['East window area (ft2)'] = win_areas[90]
  results['West window area (ft2)'] = win_areas[270]
  results['Window U-Factor'] = win_u
  results['Window SHGCo (heating)'] = win_shgc_htg
  results['Window SHGCo (cooling)'] = win_shgc_clg

  # Infiltration
  _sla, ach50 = _get_infiltration(hpxml)
  results['Infiltration rate (ACH50)'] = ach50

  # Mechanical Ventilation
  mv_kwh, mv_cfm = _get_mech_vent(hpxml)
  results['Mechanical ventilation rate'] = mv_cfm
  results['Mechanical ventilation'] = mv_kwh

  # HVAC
  afue, hspf, seer, _dse = _get_hvac(hpxml)
  if (test_num == 1) || (test_num == 4)
    results['Labeled heating system rating and efficiency'] = afue
  else
    results['Labeled heating system rating and efficiency'] = hspf
  end
  results['Labeled cooling system rating and efficiency'] = seer

  # Thermostat
  tstat, htg_sp, clg_sp = _get_tstat(hpxml)
  results['Thermostat Type'] = tstat
  results['Heating thermostat settings'] = htg_sp
  results['Cooling thermostat settings'] = clg_sp

  return results
end

def _check_reference_home_components(results, test_num, version)
  # Table 4.2.3.1(1): Acceptance Criteria for Test Cases 1 - 4

  epsilon = 0.001 # 0.1%

  # Above-grade walls
  if test_num <= 3
    assert_equal(0.082, results['Above-grade walls (Uo)'])
  else
    assert_equal(0.060, results['Above-grade walls (Uo)'])
  end
  assert_equal(0.75, results['Above-grade wall solar absorptance (α)'])
  assert_equal(0.90, results['Above-grade wall infrared emittance (ε)'])

  # Basement walls
  if test_num == 4
    assert_equal(10, results['Basement walls insulation R-Value'])
  else
    assert_equal('n/a', results['Basement walls insulation R-Value'])
  end

  # Above-grade floors
  if test_num <= 2
    assert_equal(0.047, results['Above-grade floors (Uo)'])
  else
    assert_equal('n/a', results['Above-grade floors (Uo)'])
  end

  # Slab insulation
  if test_num >= 3
    assert_equal(0, results['Slab insulation R-Value'])
  else
    assert_equal('n/a', results['Slab insulation R-Value'])
  end

  # Ceilings
  if (test_num == 1) || (test_num == 4)
    assert_equal(0.030, results['Ceilings (Uo)'])
  else
    assert_equal(0.035, results['Ceilings (Uo)'])
  end

  # Roofs
  assert_equal(0.75, results['Roof solar absorptance (α)'])
  assert_equal(0.90, results['Roof infrared emittance (ε)'])

  # Attic vent area
  assert_in_epsilon(5.13, results['Attic vent area (ft2)'], epsilon)

  # Crawlspace vent area
  if test_num == 2
    assert_in_epsilon(10.26, results['Crawlspace vent area (ft2)'], epsilon)
  else
    assert_equal('n/a', results['Crawlspace vent area (ft2)'])
  end

  # Slabs
  if test_num >= 3
    assert_in_epsilon(307.8, results['Exposed masonry floor area (ft2)'], epsilon)
    assert_equal(2.0, results['Carpet & pad R-Value'])
  else
    assert_equal('n/a', results['Exposed masonry floor area (ft2)'])
    assert_equal('n/a', results['Carpet & pad R-Value'])
  end

  # Doors
  assert_equal(40, results['Door Area (ft2)'])
  if test_num == 1
    assert_equal(0.40, results['Door U-Factor'])
  elsif test_num == 2
    assert_equal(0.65, results['Door U-Factor'])
  elsif test_num == 3
    assert_equal(1.20, results['Door U-Factor'])
  else
    assert_equal(0.35, results['Door U-Factor'])
  end

  # Windows
  if test_num <= 3
    assert_in_epsilon(69.26, results['North window area (ft2)'], epsilon)
    assert_in_epsilon(69.26, results['South window area (ft2)'], epsilon)
    assert_in_epsilon(69.26, results['East window area (ft2)'], epsilon)
    assert_in_epsilon(69.26, results['West window area (ft2)'], epsilon)
  else
    assert_in_epsilon(102.63, results['North window area (ft2)'], epsilon)
    assert_in_epsilon(102.63, results['South window area (ft2)'], epsilon)
    assert_in_epsilon(102.63, results['East window area (ft2)'], epsilon)
    assert_in_epsilon(102.63, results['West window area (ft2)'], epsilon)
  end
  if test_num == 1
    assert_equal(0.40, results['Window U-Factor'])
  elsif test_num == 2
    assert_equal(0.65, results['Window U-Factor'])
  elsif test_num == 3
    assert_equal(1.20, results['Window U-Factor'])
  else
    assert_equal(0.35, results['Window U-Factor'])
  end
  assert_equal(0.34, results['Window SHGCo (heating)'])
  assert_equal(0.28, results['Window SHGCo (cooling)'])

  # Infiltration
  assert_equal(0.00036, results['SLAo (ft2/ft2)'])

  # Internal gains
  if version == '2019A'
    # Pub 002-2020 (June 2020)
    if test_num == 1
      assert_in_epsilon(55115, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(13666, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 2
      assert_in_epsilon(52470, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(12568, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 3
      assert_in_epsilon(47839, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(9152, results['Latent Internal gains (Btu/day)'], epsilon)
    else
      assert_in_epsilon(82691, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(17769, results['Latent Internal gains (Btu/day)'], epsilon)
    end
  else
    if test_num == 1
      assert_in_epsilon(55470, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(13807, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 2
      assert_in_epsilon(52794, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(12698, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 3
      assert_in_epsilon(48111, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(9259, results['Latent Internal gains (Btu/day)'], epsilon)
    else
      assert_in_epsilon(83103, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(17934, results['Latent Internal gains (Btu/day)'], epsilon)
    end
  end

  # HVAC
  if (test_num == 1) || (test_num == 4)
    assert_equal(0.78, results['Labeled heating system rating and efficiency'])
  else
    assert_equal(7.7, results['Labeled heating system rating and efficiency'])
  end
  assert_equal(13.0, results['Labeled cooling system rating and efficiency'])
  assert_equal(0.80, results['Air Distribution System Efficiency'])

  # Thermostat
  assert_equal('manual', results['Thermostat Type'])
  assert_equal(68, results['Heating thermostat settings'])
  assert_equal(78, results['Cooling thermostat settings'])

  # Mechanical ventilation
  mv_kwh_yr = nil
  if version == '2014'
    if test_num == 1
      mv_kwh_yr = 0.0
    elsif test_num == 2
      mv_kwh_yr = 77.9
    elsif test_num == 3
      mv_kwh_yr = 140.4
    else
      mv_kwh_yr = 379.1
    end
  else
    # Pub 002-2020 (June 2020)
    if test_num == 1
      mv_kwh_yr = 0.0
    elsif test_num == 2
      mv_kwh_yr = 222.1
    elsif test_num == 3
      mv_kwh_yr = 287.8
    else
      mv_kwh_yr = 762.8
    end
  end
  assert_in_epsilon(mv_kwh_yr, results['Mechanical ventilation (kWh/y)'], epsilon)

  # Domestic hot water
  dhw_epsilon = 0.1 # 0.1 ft
  if test_num <= 3
    assert_in_delta(88.5, results['DHW pipe length refPipeL'], dhw_epsilon)
    assert_in_delta(156.9, results['DHW loop length refLoopL'], dhw_epsilon)
  else
    assert_in_delta(98.5, results['DHW pipe length refPipeL'], dhw_epsilon)
    assert_in_delta(176.9, results['DHW loop length refLoopL'], dhw_epsilon)
  end

  # e-Ratio
  assert_in_delta(1, results['e-Ratio'], 0.005)
end

def _check_iad_home_components(results, test_num)
  epsilon = 0.0005 # 0.05%

  # Geometry
  assert_equal(2, results['Number of Stories'])
  assert_equal(3, results['Number of Bedrooms'])
  assert_equal(2400, results['Conditioned Floor Area (ft2)'])
  assert_equal(20400, results['Infiltration Volume (ft3)'])

  # Above-grade Walls
  assert_in_delta(2355.52, results['Above-grade walls area (ft2)'], 0.01)
  assert_in_delta(0.085, results['Above-grade walls (Uo)'], 0.001)

  # Roof
  assert_equal(1300, results['Roof gross area (ft2)'])

  # Ceilings
  assert_equal(1200, results['Ceiling gross projected footprint area (ft2)'])
  assert_in_delta(0.054, results['Ceilings (Uo)'], 0.01)

  # Crawlspace
  assert_in_epsilon(8, results['Crawlspace vent area (ft2)'], 0.01)

  # Doors
  assert_equal(40, results['Door Area (ft2)'])
  assert_in_delta(3.04, results['Door R-value'], 0.01)

  # Windows
  assert_in_epsilon(108.00, results['North window area (ft2)'], epsilon)
  assert_in_epsilon(108.00, results['South window area (ft2)'], epsilon)
  assert_in_epsilon(108.00, results['East window area (ft2)'], epsilon)
  assert_in_epsilon(108.00, results['West window area (ft2)'], epsilon)
  assert_in_delta(1.039, results['Window U-Factor'], 0.01)
  assert_in_delta(0.57, results['Window SHGCo (heating)'], 0.01)
  assert_in_delta(0.47, results['Window SHGCo (cooling)'], 0.01)

  # Infiltration
  if test_num != 3
    assert_equal(3.0, results['Infiltration rate (ACH50)'])
  else
    assert_equal(5.0, results['Infiltration rate (ACH50)'])
  end

  # Mechanical Ventilation
  if test_num == 1
    assert_in_delta(66.4, results['Mechanical ventilation rate'], 0.2)
    assert_in_delta(407, results['Mechanical ventilation'], 1.0)
  elsif test_num == 2
    assert_in_delta(64.2, results['Mechanical ventilation rate'], 0.2)
    assert_in_delta(394, results['Mechanical ventilation'], 1.0)
  elsif test_num == 3
    assert_in_delta(53.3, results['Mechanical ventilation rate'], 0.2)
    assert_in_delta(327, results['Mechanical ventilation'], 1.0)
  elsif test_num == 4
    assert_in_delta(57.1, results['Mechanical ventilation rate'], 0.2)
    assert_in_delta(350, results['Mechanical ventilation'], 1.0)
  end

  # HVAC
  if (test_num == 1) || (test_num == 4)
    assert_equal(0.78, results['Labeled heating system rating and efficiency'])
  else
    assert_equal(7.7, results['Labeled heating system rating and efficiency'])
  end
  assert_equal(13.0, results['Labeled cooling system rating and efficiency'])

  # Thermostat
  assert_equal('manual', results['Thermostat Type'])
  assert_equal(68, results['Heating thermostat settings'])
  assert_equal(78, results['Cooling thermostat settings'])
end

def _get_above_grade_walls(hpxml)
  u_factor = solar_abs = emittance = area = num = 0.0
  hpxml.walls.each do |wall|
    next unless wall.is_exterior_thermal_boundary

    u_factor += 1.0 / wall.insulation_assembly_r_value
    solar_abs += wall.solar_absorptance
    emittance += wall.emittance
    area += wall.area
    num += 1
  end
  return u_factor / num, solar_abs / num, emittance / num, area
end

def _get_basement_walls(hpxml)
  r_value = num = 0.0
  hpxml.foundation_walls.each do |foundation_wall|
    next unless foundation_wall.is_exterior_thermal_boundary

    r_value += foundation_wall.insulation_exterior_r_value
    r_value += foundation_wall.insulation_interior_r_value
    num += 1
  end
  return r_value / num
end

def _get_above_grade_floors(hpxml)
  u_factor = num = 0.0
  hpxml.floors.each do |floor|
    next unless floor.is_floor

    u_factor += 1.0 / floor.insulation_assembly_r_value
    num += 1
  end
  return u_factor / num
end

def _get_hpxml_slabs(hpxml)
  r_value = carpet_r_value = exp_area = carpet_num = r_num = 0.0
  hpxml.slabs.each do |slab|
    exp_area += (slab.area * (1.0 - slab.carpet_fraction))
    carpet_r_value += Float(slab.carpet_r_value)
    carpet_num += 1
    r_value += slab.perimeter_insulation_r_value
    r_num += 1
    r_value += slab.under_slab_insulation_r_value
    r_num += 1
  end
  return r_value / r_num, carpet_r_value / carpet_num, exp_area
end

def _get_ceilings(hpxml)
  u_factor = area = num = 0.0
  hpxml.floors.each do |floor|
    next unless floor.is_ceiling

    u_factor += 1.0 / floor.insulation_assembly_r_value
    area += floor.area
    num += 1
  end
  return u_factor / num, area
end

def _get_roofs(hpxml)
  solar_abs = emittance = area = num = 0.0
  hpxml.roofs.each do |roof|
    solar_abs += roof.solar_absorptance
    emittance += roof.emittance
    area += roof.area
    num += 1
  end
  return solar_abs / num, emittance / num, area
end

def _get_attic_vent_area(hpxml)
  area = sla = 0.0
  hpxml.attics.each do |attic|
    next unless attic.attic_type == HPXML::AtticTypeVented

    sla = attic.vented_attic_sla
  end
  hpxml.floors.each do |floor|
    next unless floor.is_ceiling && (floor.exterior_adjacent_to == HPXML::LocationAtticVented)

    area += floor.area
  end
  return sla * area
end

def _get_crawl_vent_area(hpxml)
  area = sla = 0.0
  hpxml.foundations.each do |foundation|
    next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

    sla = foundation.vented_crawlspace_sla
  end
  hpxml.floors.each do |floor|
    next unless floor.is_floor && (floor.exterior_adjacent_to == HPXML::LocationCrawlspaceVented)

    area += floor.area
  end
  return sla * area
end

def _get_doors(hpxml)
  area = u_factor = num = 0.0
  hpxml.doors.each do |door|
    area += door.area
    u_factor += 1.0 / door.r_value
    num += 1
  end
  return u_factor / num, area
end

def _get_windows(hpxml)
  areas = { 0 => 0.0, 90 => 0.0, 180 => 0.0, 270 => 0.0 }
  u_factor = shgc_htg = shgc_clg = num = 0.0
  hpxml.windows.each do |window|
    areas[window.azimuth] += window.area
    u_factor += window.ufactor
    shgc = window.shgc
    shading_winter = window.interior_shading_factor_winter
    shading_summer = window.interior_shading_factor_summer
    shgc_htg += (shgc * shading_winter)
    shgc_clg += (shgc * shading_summer)
    num += 1
  end
  return areas, u_factor / num, shgc_htg / num, shgc_clg / num
end

def _get_infiltration(hpxml)
  air_infil = hpxml.air_infiltration_measurements[0]
  ach50 = air_infil.air_leakage
  cfa = hpxml.building_construction.conditioned_floor_area
  infil_volume = air_infil.infiltration_volume
  sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, 0.65, cfa, infil_volume)
  return sla, ach50
end

def _get_internal_gains(hpxml)
  s = ''
  nbeds = hpxml.building_construction.number_of_bedrooms
  cfa = hpxml.building_construction.conditioned_floor_area
  eri_version = hpxml.header.eri_calculation_version
  gfa = hpxml.slabs.select { |s| s.interior_adjacent_to == HPXML::LocationGarage }.map { |s| s.area }.inject(0, :+)

  xml_pl_sens = 0.0
  xml_pl_lat = 0.0

  # Plug loads
  hpxml.plug_loads.each do |plug_load|
    btu = UnitConversions.convert(plug_load.kwh_per_year, 'kWh', 'Btu')
    xml_pl_sens += (plug_load.frac_sensible * btu)
    xml_pl_lat += (plug_load.frac_latent * btu)
    s += "#{xml_pl_sens} #{xml_pl_lat}\n"
  end

  xml_appl_sens = 0.0
  xml_appl_lat = 0.0

  # Appliances: CookingRange
  cooking_range = hpxml.cooking_ranges[0]
  cooking_range.usage_multiplier = 1.0 if cooking_range.usage_multiplier.nil?
  oven = hpxml.ovens[0]
  cr_annual_kwh, cr_annual_therm, cr_frac_sens, cr_frac_lat = HotWaterAndAppliances.calc_range_oven_energy(nbeds, cooking_range, oven)
  btu = UnitConversions.convert(cr_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cr_annual_therm, 'therm', 'Btu')
  xml_appl_sens += (cr_frac_sens * btu)
  xml_appl_lat += (cr_frac_lat * btu)

  # Appliances: Refrigerator
  refrigerator = hpxml.refrigerators[0]
  refrigerator.usage_multiplier = 1.0 if refrigerator.usage_multiplier.nil?
  rf_annual_kwh, rf_frac_sens, rf_frac_lat = HotWaterAndAppliances.calc_refrigerator_or_freezer_energy(refrigerator)
  btu = UnitConversions.convert(rf_annual_kwh, 'kWh', 'Btu')
  xml_appl_sens += (rf_frac_sens * btu)
  xml_appl_lat += (rf_frac_lat * btu)

  # Appliances: Dishwasher
  dishwasher = hpxml.dishwashers[0]
  dishwasher.usage_multiplier = 1.0 if dishwasher.usage_multiplier.nil?
  dw_annual_kwh, dw_frac_sens, dw_frac_lat, _dw_gpd = HotWaterAndAppliances.calc_dishwasher_energy_gpd(eri_version, nbeds, dishwasher)
  btu = UnitConversions.convert(dw_annual_kwh, 'kWh', 'Btu')
  xml_appl_sens += (dw_frac_sens * btu)
  xml_appl_lat += (dw_frac_lat * btu)

  # Appliances: ClothesWasher
  clothes_washer = hpxml.clothes_washers[0]
  clothes_washer.usage_multiplier = 1.0 if clothes_washer.usage_multiplier.nil?
  cw_annual_kwh, cw_frac_sens, cw_frac_lat, _cw_gpd = HotWaterAndAppliances.calc_clothes_washer_energy_gpd(eri_version, nbeds, clothes_washer)
  btu = UnitConversions.convert(cw_annual_kwh, 'kWh', 'Btu')
  xml_appl_sens += (cw_frac_sens * btu)
  xml_appl_lat += (cw_frac_lat * btu)

  # Appliances: ClothesDryer
  clothes_dryer = hpxml.clothes_dryers[0]
  clothes_dryer.usage_multiplier = 1.0 if clothes_dryer.usage_multiplier.nil?
  cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = HotWaterAndAppliances.calc_clothes_dryer_energy(eri_version, nbeds, clothes_dryer, clothes_washer)
  btu = UnitConversions.convert(cd_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cd_annual_therm, 'therm', 'Btu')
  xml_appl_sens += (cd_frac_sens * btu)
  xml_appl_lat += (cd_frac_lat * btu)

  s += "#{xml_appl_sens} #{xml_appl_lat}\n"

  # Water Use
  xml_water_sens, xml_water_lat = HotWaterAndAppliances.get_water_gains_sens_lat(nbeds)
  s += "#{xml_water_sens} #{xml_water_lat}\n"

  # Occupants
  xml_occ_sens = 0.0
  xml_occ_lat = 0.0
  heat_gain, hrs_per_day, frac_sens, frac_lat = Geometry.get_occupancy_default_values()
  btu = nbeds * heat_gain * hrs_per_day * 365.0
  xml_occ_sens += (frac_sens * btu)
  xml_occ_lat += (frac_lat * btu)
  s += "#{xml_occ_sens} #{xml_occ_lat}\n"

  # Lighting
  xml_ltg_sens = 0.0
  f_int_cfl, f_grg_cfl, f_int_lfl, f_grg_lfl, f_int_led, f_grg_led = nil
  hpxml.lighting_groups.each do |lg|
    if (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationInterior)
      f_int_cfl = lg.fraction_of_units_in_location
    elsif (lg.lighting_type == HPXML::LightingTypeCFL) && (lg.location == HPXML::LocationGarage)
      f_grg_cfl = lg.fraction_of_units_in_location
    elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationInterior)
      f_int_lfl = lg.fraction_of_units_in_location
    elsif (lg.lighting_type == HPXML::LightingTypeLFL) && (lg.location == HPXML::LocationGarage)
      f_grg_lfl = lg.fraction_of_units_in_location
    elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationInterior)
      f_int_led = lg.fraction_of_units_in_location
    elsif (lg.lighting_type == HPXML::LightingTypeLED) && (lg.location == HPXML::LocationGarage)
      f_grg_led = lg.fraction_of_units_in_location
    end
  end
  int_kwh = Lighting.calc_interior_energy(eri_version, cfa, f_int_cfl, f_int_lfl, f_int_led)
  grg_kwh = Lighting.calc_garage_energy(eri_version, gfa, f_grg_cfl, f_grg_lfl, f_grg_led)
  xml_ltg_sens += UnitConversions.convert(int_kwh + grg_kwh, 'kWh', 'Btu')
  s += "#{xml_ltg_sens}\n"

  xml_btu_sens = (xml_pl_sens + xml_appl_sens + xml_water_sens + xml_occ_sens + xml_ltg_sens) / 365.0
  xml_btu_lat = (xml_pl_lat + xml_appl_lat + xml_water_lat + xml_occ_lat) / 365.0

  return xml_btu_sens, xml_btu_lat
end

def _get_hvac(hpxml)
  afue = hspf = seer = dse = num_afue = num_hspf = num_seer = num_dse = 0.0
  hpxml.heating_systems.each do |heating_system|
    afue += heating_system.heating_efficiency_afue
    num_afue += 1
  end
  hpxml.cooling_systems.each do |cooling_system|
    seer += cooling_system.cooling_efficiency_seer
    num_seer += 1
  end
  hpxml.heat_pumps.each do |heat_pump|
    if not heat_pump.heating_efficiency_hspf.nil?
      hspf += heat_pump.heating_efficiency_hspf
      num_hspf += 1
    end
    if not heat_pump.cooling_efficiency_seer.nil?
      seer += heat_pump.cooling_efficiency_seer
      num_seer += 1
    end
  end
  hpxml.hvac_distributions.each do |hvac_distribution|
    dse += hvac_distribution.annual_heating_dse
    num_dse += 1
    dse += hvac_distribution.annual_cooling_dse
    num_dse += 1
  end
  return afue / num_afue, hspf / num_hspf, seer / num_seer, dse / num_dse
end

def _get_tstat(hpxml)
  hvac_control = hpxml.hvac_controls[0]
  tstat = hvac_control.control_type.gsub(' thermostat', '')
  htg_sp, _htg_setback_sp, _htg_setback_hrs_per_week, _htg_setback_start_hr = HVAC.get_default_heating_setpoint(hvac_control.control_type)
  clg_sp, _clg_setup_sp, _clg_setup_hrs_per_week, _clg_setup_start_hr = HVAC.get_default_cooling_setpoint(hvac_control.control_type)
  return tstat, htg_sp, clg_sp
end

def _get_mech_vent(hpxml)
  mv_kwh = mv_cfm = 0.0
  hpxml.ventilation_fans.each do |vent_fan|
    next unless vent_fan.used_for_whole_building_ventilation

    hours = vent_fan.hours_in_operation
    fan_w = vent_fan.fan_power
    mv_kwh += fan_w * 8.76 * hours / 24.0
    mv_cfm += vent_fan.tested_flow_rate
  end
  return mv_kwh, mv_cfm
end

def _get_dhw(hpxml)
  has_uncond_bsmnt = hpxml.has_location(HPXML::LocationBasementUnconditioned)
  cfa = hpxml.building_construction.conditioned_floor_area
  ncfl = hpxml.building_construction.number_of_conditioned_floors
  ref_pipe_l = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
  ref_loop_l = HotWaterAndAppliances.get_default_recirc_loop_length(ref_pipe_l)
  return ref_pipe_l, ref_loop_l
end

def _check_method_results(results, test_num, has_tankless_water_heater, version)
  using_iaf = false

  cooling_mepr =  { 1 => 10.00,  2 => 10.00,  3 => 10.00,  4 => 10.00,  5 => 10.00 }
  heating_fuel =  { 1 => 'elec', 2 => 'elec', 3 => 'gas',  4 => 'elec', 5 => 'gas' }
  heating_mepr =  { 1 => 6.80,   2 => 6.80,   3 => 0.78,   4 => 9.85,   5 => 0.96  }
  hotwater_fuel = { 1 => 'elec', 2 => 'gas',  3 => 'elec', 4 => 'elec', 5 => 'elec' }
  hotwater_mepr = { 1 => 0.88,   2 => 0.82,   3 => 0.88,   4 => 0.88,   5 => 0.88 }
  if version == '2019A'
    ec_x_la = { 1 => 20.45,  2 => 22.42,  3 => 21.28,  4 => 21.40,  5 => 22.42 }
  else
    ec_x_la = { 1 => 21.27,  2 => 23.33,  3 => 22.05,  4 => 22.35,  5 => 23.33 }
  end
  cfa = { 1 => 1539, 2 => 1539, 3 => 1539, 4 => 1539, 5 => 1539 }
  nbr = { 1 => 3,    2 => 3,    3 => 2,    4 => 4,    5 => 3 }
  nst = { 1 => 1,    2 => 1,    3 => 1,    4 => 1,    5 => 1 }
  using_iaf = true if version != '2014'

  if heating_fuel[test_num] == 'gas'
    heating_a = 1.0943
    heating_b = 0.403
    heating_eec_r = 1.0 / 0.78
    heating_eec_x = 1.0 / heating_mepr[test_num]
  else
    heating_a = 2.2561
    heating_b = 0.0
    heating_eec_r = 3.413 / 7.7
    heating_eec_x = 3.413 / heating_mepr[test_num]
  end

  cooling_a = 3.8090
  cooling_b = 0.0
  cooling_eec_r = 3.413 / 13.0
  cooling_eec_x = 3.413 / cooling_mepr[test_num]

  if hotwater_fuel[test_num] == 'gas'
    hotwater_a = 1.1877
    hotwater_b = 1.013
    hotwater_eec_r = 1.0 / 0.59
  else
    hotwater_a = 0.92
    hotwater_b = 0.0
    hotwater_eec_r = 1.0 / 0.92
  end
  if not has_tankless_water_heater
    hotwater_eec_x = 1.0 / hotwater_mepr[test_num]
  else
    hotwater_eec_x = 1.0 / (hotwater_mepr[test_num] * 0.92)
  end

  heating_dse_r = results['REUL Heating (MBtu)'] / results['EC_r Heating (MBtu)'] * heating_eec_r
  cooling_dse_r = results['REUL Cooling (MBtu)'] / results['EC_r Cooling (MBtu)'] * cooling_eec_r
  hotwater_dse_r = results['REUL Hot Water (MBtu)'] / results['EC_r Hot Water (MBtu)'] * hotwater_eec_r

  heating_nec_x = (heating_a * heating_eec_x - heating_b) * (results['EC_x Heating (MBtu)'] * results['EC_r Heating (MBtu)'] * heating_dse_r) / (heating_eec_x * results['REUL Heating (MBtu)'])
  cooling_nec_x = (cooling_a * cooling_eec_x - cooling_b) * (results['EC_x Cooling (MBtu)'] * results['EC_r Cooling (MBtu)'] * cooling_dse_r) / (cooling_eec_x * results['REUL Cooling (MBtu)'])
  hotwater_nec_x = (hotwater_a * hotwater_eec_x - hotwater_b) * (results['EC_x Hot Water (MBtu)'] * results['EC_r Hot Water (MBtu)'] * hotwater_dse_r) / (hotwater_eec_x * results['REUL Hot Water (MBtu)'])

  heating_nmeul = results['REUL Heating (MBtu)'] * (heating_nec_x / results['EC_r Heating (MBtu)'])
  cooling_nmeul = results['REUL Cooling (MBtu)'] * (cooling_nec_x / results['EC_r Cooling (MBtu)'])
  hotwater_nmeul = results['REUL Hot Water (MBtu)'] * (hotwater_nec_x / results['EC_r Hot Water (MBtu)'])

  if using_iaf
    iaf_cfa = ((2400.0 / cfa[test_num])**(0.304 * results['IAD_Save (%)']))
    iaf_nbr = (1.0 + (0.069 * results['IAD_Save (%)'] * (nbr[test_num] - 3.0)))
    iaf_nst = ((2.0 / nst[test_num])**(0.12 * results['IAD_Save (%)']))
    iaf_rh = iaf_cfa * iaf_nbr * iaf_nst
  end

  tnml = heating_nmeul + cooling_nmeul + hotwater_nmeul + results['EC_x L&A (MBtu)']
  trl = results['REUL Heating (MBtu)'] + results['REUL Cooling (MBtu)'] + results['REUL Hot Water (MBtu)'] + ec_x_la[test_num]

  if using_iaf
    trl_iaf = trl * iaf_rh
    eri = 100 * tnml / trl_iaf
  else
    eri = 100 * tnml / trl
  end

  assert_operator((results['ERI'] - eri).abs / results['ERI'], :<, 0.005)
end

def _check_hvac_test_results(energy)
  # Proposed acceptance criteria as of 8/17/2022
  min = [-24.58, -13.18, -42.75, 57.19]
  max = [-18.18, -12.58, -15.84, 111.39]

  # Cooling cases
  assert_operator((energy['HVAC1b'] - energy['HVAC1a']) / energy['HVAC1a'] * 100, :>, min[0])
  assert_operator((energy['HVAC1b'] - energy['HVAC1a']) / energy['HVAC1a'] * 100, :<, max[0])

  # Gas heating cases
  assert_operator((energy['HVAC2b'] - energy['HVAC2a']) / energy['HVAC2a'] * 100, :>, min[1])
  assert_operator((energy['HVAC2b'] - energy['HVAC2a']) / energy['HVAC2a'] * 100, :<, max[1])

  # Electric heating cases
  assert_operator((energy['HVAC2d'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :>, min[2])
  assert_operator((energy['HVAC2d'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :<, max[2])
  assert_operator((energy['HVAC2e'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :>, min[3])
  assert_operator((energy['HVAC2e'] - energy['HVAC2c']) / energy['HVAC2c'] * 100, :<, max[3])
end

def _check_dse_test_results(energy)
  # Proposed acceptance criteria as of 8/17/2022
  htg_min = [8.68, 2.87, 6.94]
  htg_max = [26.12, 6.63, 20.04]
  clg_min = [19.33, 5.35, 15.96]
  clg_max = [28.08, 8.52, 28.29]

  # Heating cases
  assert_operator((energy['HVAC3b'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, htg_min[0])
  assert_operator((energy['HVAC3b'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, htg_max[0])
  # Note: OS-ERI does not pass this test because of differences in duct insulation
  #       R-values; see get_duct_insulation_rvalue() in airflow.rb.
  # See https://github.com/resnet-us/software-consistency-inquiries/issues/21
  # assert_operator((energy['HVAC3c'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, htg_min[1])
  # assert_operator((energy['HVAC3c'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, htg_max[1])
  assert_operator((energy['HVAC3d'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :>, htg_min[2])
  assert_operator((energy['HVAC3d'] - energy['HVAC3a']) / energy['HVAC3a'] * 100, :<, htg_max[2])

  # Cooling cases
  assert_operator((energy['HVAC3f'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, clg_min[0])
  assert_operator((energy['HVAC3f'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, clg_max[0])
  assert_operator((energy['HVAC3g'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, clg_min[1])
  assert_operator((energy['HVAC3g'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, clg_max[1])
  assert_operator((energy['HVAC3h'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :>, clg_min[2])
  assert_operator((energy['HVAC3h'] - energy['HVAC3e']) / energy['HVAC3e'] * 100, :<, clg_max[2])
end

def _get_hot_water(results_csv)
  rated_dhw = nil
  rated_recirc = nil
  rated_gpd = 0
  CSV.foreach(results_csv) do |row|
    next if row.nil? || row[0].nil?

    if ["End Use: #{FT::Gas}: #{EUT::HotWater} (MBtu)",
        "End Use: #{FT::Elec}: #{EUT::HotWater} (MBtu)"].include? row[0]
      rated_dhw = Float(row[1]).round(2)
    elsif row[0] == "End Use: #{FT::Elec}: #{EUT::HotWaterRecircPump} (MBtu)"
      rated_recirc = Float(row[1]).round(2)
    elsif row[0].start_with?('Hot Water:') && row[0].include?('(gal)')
      rated_gpd += (Float(row[1]) / 365.0).round
    end
  end
  return rated_dhw, rated_recirc, rated_gpd
end

def _check_hot_water(energy)
  # Proposed acceptance criteria as of 8/17/2022
  mn_min = [19.34, 25.76, 17.20, 24.94, 55.93, 22.61, 20.51]
  mn_max = [19.88, 26.55, 17.70, 25.71, 57.58, 23.28, 21.09]
  fl_min = [10.74, 13.37, 8.83, 13.06, 30.84, 12.09, 11.84]
  fl_max = [11.24, 13.87, 9.33, 13.56, 31.55, 12.59, 12.34]
  mn_dt_min = [-6.77, 1.92, 0.58, -31.03, 2.95, 5.09]
  mn_dt_max = [-6.27, 2.42, 1.08, -30.17, 3.45, 5.59]
  fl_dt_min = [-2.88, 1.67, 0.07, -17.82, 1.04, 1.28]
  fl_dt_max = [-2.38, 2.17, 0.57, -17.32, 1.54, 1.78]
  mn_fl_dt_min = [8.37, 12.26, 8.13, 11.75, 25.05, 10.35, 8.46]
  mn_fl_dt_max = [8.87, 12.77, 8.63, 12.25, 26.04, 10.85, 8.96]

  # Duluth MN cases
  assert_operator(energy['L100AD-HW-01'], :>, mn_min[0])
  assert_operator(energy['L100AD-HW-01'], :<, mn_max[0])
  assert_operator(energy['L100AD-HW-02'], :>, mn_min[1])
  assert_operator(energy['L100AD-HW-02'], :<, mn_max[1])
  assert_operator(energy['L100AD-HW-03'], :>, mn_min[2])
  assert_operator(energy['L100AD-HW-03'], :<, mn_max[2])
  assert_operator(energy['L100AD-HW-04'], :>, mn_min[3])
  assert_operator(energy['L100AD-HW-04'], :<, mn_max[3])
  assert_operator(energy['L100AD-HW-05'], :>, mn_min[4])
  assert_operator(energy['L100AD-HW-05'], :<, mn_max[4])
  assert_operator(energy['L100AD-HW-06'], :>, mn_min[5])
  assert_operator(energy['L100AD-HW-06'], :<, mn_max[5])
  assert_operator(energy['L100AD-HW-07'], :>, mn_min[6])
  assert_operator(energy['L100AD-HW-07'], :<, mn_max[6])

  # Miami FL cases
  assert_operator(energy['L100AM-HW-01'], :>, fl_min[0])
  assert_operator(energy['L100AM-HW-01'], :<, fl_max[0])
  assert_operator(energy['L100AM-HW-02'], :>, fl_min[1])
  assert_operator(energy['L100AM-HW-02'], :<, fl_max[1])
  assert_operator(energy['L100AM-HW-03'], :>, fl_min[2])
  assert_operator(energy['L100AM-HW-03'], :<, fl_max[2])
  assert_operator(energy['L100AM-HW-04'], :>, fl_min[3])
  assert_operator(energy['L100AM-HW-04'], :<, fl_max[3])
  assert_operator(energy['L100AM-HW-05'], :>, fl_min[4])
  assert_operator(energy['L100AM-HW-05'], :<, fl_max[4])
  assert_operator(energy['L100AM-HW-06'], :>, fl_min[5])
  assert_operator(energy['L100AM-HW-06'], :<, fl_max[5])
  assert_operator(energy['L100AM-HW-07'], :>, fl_min[6])
  assert_operator(energy['L100AM-HW-07'], :<, fl_max[6])

  # MN Delta cases
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-02'], :>, mn_dt_min[0])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-02'], :<, mn_dt_max[0])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-03'], :>, mn_dt_min[1])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AD-HW-03'], :<, mn_dt_max[1])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-04'], :>, mn_dt_min[2])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-04'], :<, mn_dt_max[2])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-05'], :>, mn_dt_min[3])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-05'], :<, mn_dt_max[3])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-06'], :>, mn_dt_min[4])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-06'], :<, mn_dt_max[4])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-07'], :>, mn_dt_min[5])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AD-HW-07'], :<, mn_dt_max[5])

  # FL Delta cases
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-02'], :>, fl_dt_min[0])
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-02'], :<, fl_dt_max[0])
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-03'], :>, fl_dt_min[1])
  assert_operator(energy['L100AM-HW-01'] - energy['L100AM-HW-03'], :<, fl_dt_max[1])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-04'], :>, fl_dt_min[2])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-04'], :<, fl_dt_max[2])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-05'], :>, fl_dt_min[3])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-05'], :<, fl_dt_max[3])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-06'], :>, fl_dt_min[4])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-06'], :<, fl_dt_max[4])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-07'], :>, fl_dt_min[5])
  assert_operator(energy['L100AM-HW-02'] - energy['L100AM-HW-07'], :<, fl_dt_max[5])

  # MN-FL Delta cases
  assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :>, mn_fl_dt_min[0])
  assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :<, mn_fl_dt_max[0])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AM-HW-02'], :>, mn_fl_dt_min[1])
  assert_operator(energy['L100AD-HW-02'] - energy['L100AM-HW-02'], :<, mn_fl_dt_max[1])
  assert_operator(energy['L100AD-HW-03'] - energy['L100AM-HW-03'], :>, mn_fl_dt_min[2])
  assert_operator(energy['L100AD-HW-03'] - energy['L100AM-HW-03'], :<, mn_fl_dt_max[2])
  assert_operator(energy['L100AD-HW-04'] - energy['L100AM-HW-04'], :>, mn_fl_dt_min[3])
  assert_operator(energy['L100AD-HW-04'] - energy['L100AM-HW-04'], :<, mn_fl_dt_max[3])
  assert_operator(energy['L100AD-HW-05'] - energy['L100AM-HW-05'], :>, mn_fl_dt_min[4])
  assert_operator(energy['L100AD-HW-05'] - energy['L100AM-HW-05'], :<, mn_fl_dt_max[4])
  assert_operator(energy['L100AD-HW-06'] - energy['L100AM-HW-06'], :>, mn_fl_dt_min[5])
  assert_operator(energy['L100AD-HW-06'] - energy['L100AM-HW-06'], :<, mn_fl_dt_max[5])
  assert_operator(energy['L100AD-HW-07'] - energy['L100AM-HW-07'], :>, mn_fl_dt_min[6])
  assert_operator(energy['L100AD-HW-07'] - energy['L100AM-HW-07'], :<, mn_fl_dt_max[6])
end

def _check_hot_water_301_2019_pre_addendum_a(energy)
  # Acceptance Criteria for Hot Water Tests

  # Duluth MN cases
  assert_operator(energy['L100AD-HW-01'], :>, 19.11)
  assert_operator(energy['L100AD-HW-01'], :<, 19.73)
  assert_operator(energy['L100AD-HW-02'], :>, 25.54)
  assert_operator(energy['L100AD-HW-02'], :<, 26.36)
  assert_operator(energy['L100AD-HW-03'], :>, 17.03)
  assert_operator(energy['L100AD-HW-03'], :<, 17.50)
  assert_operator(energy['L100AD-HW-04'], :>, 24.75)
  assert_operator(energy['L100AD-HW-04'], :<, 25.52)
  assert_operator(energy['L100AD-HW-05'], :>, 55.43)
  assert_operator(energy['L100AD-HW-05'], :<, 57.15)
  assert_operator(energy['L100AD-HW-06'], :>, 22.39)
  assert_operator(energy['L100AD-HW-06'], :<, 23.09)
  assert_operator(energy['L100AD-HW-07'], :>, 20.29)
  assert_operator(energy['L100AD-HW-07'], :<, 20.94)

  # Miami FL cases
  assert_operator(energy['L100AM-HW-01'], :>, 10.59)
  assert_operator(energy['L100AM-HW-01'], :<, 11.03)
  assert_operator(energy['L100AM-HW-02'], :>, 13.17)
  assert_operator(energy['L100AM-HW-02'], :<, 13.68)
  assert_operator(energy['L100AM-HW-03'], :>, 8.81)
  assert_operator(energy['L100AM-HW-03'], :<, 9.13)
  assert_operator(energy['L100AM-HW-04'], :>, 12.87)
  assert_operator(energy['L100AM-HW-04'], :<, 13.36)
  assert_operator(energy['L100AM-HW-05'], :>, 30.19)
  assert_operator(energy['L100AM-HW-05'], :<, 31.31)
  assert_operator(energy['L100AM-HW-06'], :>, 11.90)
  assert_operator(energy['L100AM-HW-06'], :<, 12.38)
  assert_operator(energy['L100AM-HW-07'], :>, 11.68)
  assert_operator(energy['L100AM-HW-07'], :<, 12.14)

  # MN Delta cases
  assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-02']) / energy['L100AD-HW-01'] * 100, :>, -34.01)
  assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-02']) / energy['L100AD-HW-01'] * 100, :<, -32.49)
  assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-03']) / energy['L100AD-HW-01'] * 100, :>, 10.74)
  assert_operator((energy['L100AD-HW-01'] - energy['L100AD-HW-03']) / energy['L100AD-HW-01'] * 100, :<, 11.57)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-04']) / energy['L100AD-HW-02'] * 100, :>, 3.06)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-04']) / energy['L100AD-HW-02'] * 100, :<, 3.22)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-05']) / energy['L100AD-HW-02'] * 100, :>, -118.52)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-05']) / energy['L100AD-HW-02'] * 100, :<, -115.63)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-06']) / energy['L100AD-HW-02'] * 100, :>, 12.17)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-06']) / energy['L100AD-HW-02'] * 100, :<, 12.51)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-07']) / energy['L100AD-HW-02'] * 100, :>, 20.15)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-07']) / energy['L100AD-HW-02'] * 100, :<, 20.78)

  # FL Delta cases
  assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-02']) / energy['L100AM-HW-01'] * 100, :>, -24.54)
  assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-02']) / energy['L100AM-HW-01'] * 100, :<, -23.44)
  assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-03']) / energy['L100AM-HW-01'] * 100, :>, 16.65)
  assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-03']) / energy['L100AM-HW-01'] * 100, :<, 18.12)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-04']) / energy['L100AM-HW-02'] * 100, :>, 2.20)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-04']) / energy['L100AM-HW-02'] * 100, :<, 2.38)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-05']) / energy['L100AM-HW-02'] * 100, :>, -130.88)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-05']) / energy['L100AM-HW-02'] * 100, :<, -127.52)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-06']) / energy['L100AM-HW-02'] * 100, :>, 9.38)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-06']) / energy['L100AM-HW-02'] * 100, :<, 9.74)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-07']) / energy['L100AM-HW-02'] * 100, :>, 11.00)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-07']) / energy['L100AM-HW-02'] * 100, :<, 11.40)

  # MN-FL Delta cases
  assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :>, 43.35)
  assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :<, 45.00)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AM-HW-02']) / energy['L100AD-HW-02'] * 100, :>, 47.26)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AM-HW-02']) / energy['L100AD-HW-02'] * 100, :<, 48.93)
  assert_operator((energy['L100AD-HW-03'] - energy['L100AM-HW-03']) / energy['L100AD-HW-03'] * 100, :>, 47.38)
  assert_operator((energy['L100AD-HW-03'] - energy['L100AM-HW-03']) / energy['L100AD-HW-03'] * 100, :<, 48.74)
  assert_operator((energy['L100AD-HW-04'] - energy['L100AM-HW-04']) / energy['L100AD-HW-04'] * 100, :>, 46.81)
  assert_operator((energy['L100AD-HW-04'] - energy['L100AM-HW-04']) / energy['L100AD-HW-04'] * 100, :<, 48.48)
  assert_operator((energy['L100AD-HW-05'] - energy['L100AM-HW-05']) / energy['L100AD-HW-05'] * 100, :>, 44.41)
  assert_operator((energy['L100AD-HW-05'] - energy['L100AM-HW-05']) / energy['L100AD-HW-05'] * 100, :<, 45.99)
  assert_operator((energy['L100AD-HW-06'] - energy['L100AM-HW-06']) / energy['L100AD-HW-06'] * 100, :>, 45.60)
  assert_operator((energy['L100AD-HW-06'] - energy['L100AM-HW-06']) / energy['L100AD-HW-06'] * 100, :<, 47.33)
  assert_operator((energy['L100AD-HW-07'] - energy['L100AM-HW-07']) / energy['L100AD-HW-07'] * 100, :>, 41.32)
  assert_operator((energy['L100AD-HW-07'] - energy['L100AM-HW-07']) / energy['L100AD-HW-07'] * 100, :<, 42.86)
end

def _check_hot_water_301_2014_pre_addendum_a(energy)
  # Acceptance Criteria for Hot Water Tests

  # Duluth MN cases
  assert_operator(energy['L100AD-HW-01'], :>, 18.2)
  assert_operator(energy['L100AD-HW-01'], :<, 22.0)

  # Miami FL cases
  assert_operator(energy['L100AM-HW-01'], :>, 10.9)
  assert_operator(energy['L100AM-HW-01'], :<, 14.4)

  # MN Delta cases
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :>, 26.5)
  assert_operator((energy['L100AD-HW-02'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :<, 32.2)
  assert_operator((energy['L100AD-HW-03'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :>, -11.8)
  assert_operator((energy['L100AD-HW-03'] - energy['L100AD-HW-01']) / energy['L100AD-HW-01'] * 100, :<, -6.8)

  # FL Delta cases
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :>, 19.1)
  assert_operator((energy['L100AM-HW-02'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :<, 29.1)
  assert_operator((energy['L100AM-HW-03'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :>, -19.5)
  assert_operator((energy['L100AM-HW-03'] - energy['L100AM-HW-01']) / energy['L100AM-HW-01'] * 100, :<, -7.7)

  # MN-FL Delta cases
  assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :>, 5.5)
  assert_operator(energy['L100AD-HW-01'] - energy['L100AM-HW-01'], :<, 9.4)
  assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :>, 28.9)
  assert_operator((energy['L100AD-HW-01'] - energy['L100AM-HW-01']) / energy['L100AD-HW-01'] * 100, :<, 45.1)
end
