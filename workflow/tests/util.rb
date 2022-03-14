# frozen_string_literal: true

def _run_ruleset(design, xml, out_xml)
  model = OpenStudio::Model::Model.new
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  measures_dir = File.join(File.dirname(__FILE__), '..', '..')

  measures = {}

  # Add 301 measure to workflow
  measure_subdir = 'rulesets/301EnergyRatingIndexRuleset'
  args = {}
  args['calc_type'] = design
  args['hpxml_input_path'] = File.absolute_path(xml)
  args['hpxml_output_path'] = out_xml
  update_args_hash(measures, measure_subdir, args)

  # Apply measures
  FileUtils.mkdir_p(File.dirname(out_xml))
  success = apply_measures(measures_dir, measures, runner, model)
  show_output(runner.result) unless success
  assert(success)
  assert(File.exist?(out_xml))

  hpxml = XMLHelper.parse_file(out_xml)
  XMLHelper.delete_element(XMLHelper.get_element(hpxml, '/HPXML/SoftwareInfo/extension/ERICalculation'), 'Design')
  XMLHelper.write_file(hpxml, out_xml)
end

def _run_workflow(xml, test_name, expect_error: false, expect_error_msgs: nil, timeseries_frequency: 'none', run_energystar: false, component_loads: false)
  xml = File.absolute_path(xml)

  rundir = File.join(@test_files_dir, test_name, File.basename(xml))

  timeseries = ''
  if timeseries_frequency != 'none'
    timeseries = " --#{timeseries_frequency} ALL"
  end
  comploads = ''
  if component_loads
    comploads = ' --add-component-loads'
  end

  # Run workflow
  if run_energystar
    workflow_rb = 'energy_star.rb'
  else
    workflow_rb = 'energy_rating_index.rb'
  end
  command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(File.dirname(__FILE__), "../#{workflow_rb}")}\" -x #{xml}#{timeseries}#{comploads} -o #{rundir} --debug"
  start_time = Time.now
  system(command)
  runtime = (Time.now - start_time).round(2)

  hpxmls = {}
  csvs = {}
  if not run_energystar
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
    log_dirs = [Constants.CalcTypeERIRatedHome,
                Constants.CalcTypeERIReferenceHome,
                Constants.CalcTypeERIIndexAdjustmentDesign,
                Constants.CalcTypeERIIndexAdjustmentReferenceHome].map { |d| d.gsub(' ', '') }
    if File.exist? File.join(rundir, 'results', 'CO2_Results.csv')
      csvs[:co2_results] = File.join(rundir, 'results', 'CO2_Results.csv')
      log_dirs << Constants.CalcTypeCO2ReferenceHome.gsub(' ', '')
    end
  else
    hpxmls[:ref] = File.join(rundir, 'results', 'ESReference.xml')
    hpxmls[:rated] = File.join(rundir, 'results', 'ESRated.xml')
    hpxmls[:ref_ref] = File.join(rundir, 'ESReference', 'results', 'ERIReferenceHome.xml')
    hpxmls[:ref_rated] = File.join(rundir, 'ESReference', 'results', 'ERIRatedHome.xml')
    hpxmls[:ref_iad] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentDesign.xml')
    hpxmls[:ref_iadref] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentReferenceHome.xml')
    hpxmls[:rated_ref] = File.join(rundir, 'ESRated', 'results', 'ERIReferenceHome.xml')
    hpxmls[:rated_rated] = File.join(rundir, 'ESRated', 'results', 'ERIRatedHome.xml')
    hpxmls[:rated_iad] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentDesign.xml')
    hpxmls[:rated_iadref] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentReferenceHome.xml')
    csvs[:es_results] = File.join(rundir, 'results', 'ES_Results.csv')
    csvs[:ref_eri_results] = File.join(rundir, 'ESReference', 'results', 'ERI_Results.csv')
    csvs[:ref_eri_worksheet] = File.join(rundir, 'ESReference', 'results', 'ERI_Worksheet.csv')
    csvs[:ref_rated_results] = File.join(rundir, 'ESReference', 'results', 'ERIRatedHome.csv')
    csvs[:ref_ref_results] = File.join(rundir, 'ESReference', 'results', 'ERIReferenceHome.csv')
    csvs[:ref_iad_results] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentDesign.csv')
    csvs[:ref_iadref_results] = File.join(rundir, 'ESReference', 'results', 'ERIIndexAdjustmentReferenceHome.csv')
    csvs[:rated_eri_results] = File.join(rundir, 'ESRated', 'results', 'ERI_Results.csv')
    csvs[:rated_eri_worksheet] = File.join(rundir, 'ESRated', 'results', 'ERI_Worksheet.csv')
    csvs[:rated_rated_results] = File.join(rundir, 'ESRated', 'results', 'ERIRatedHome.csv')
    csvs[:rated_ref_results] = File.join(rundir, 'ESRated', 'results', 'ERIReferenceHome.csv')
    csvs[:rated_iad_results] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentDesign.csv')
    csvs[:rated_iadref_results] = File.join(rundir, 'ESRated', 'results', 'ERIIndexAdjustmentReferenceHome.csv')
    if timeseries_frequency != 'none'
      csvs[:rated_timeseries_results] = File.join(rundir, 'ESRated', 'results', "ERIRatedHome_#{timeseries_frequency.capitalize}.csv")
      csvs[:ref_timeseries_results] = File.join(rundir, 'ESReference', 'results', "ERIReferenceHome_#{timeseries_frequency.capitalize}.csv")
    end
    log_dirs = [File.join('ESRated', Constants.CalcTypeERIRatedHome),
                File.join('ESRated', Constants.CalcTypeERIReferenceHome),
                File.join('ESRated', Constants.CalcTypeERIIndexAdjustmentDesign),
                File.join('ESRated', Constants.CalcTypeERIIndexAdjustmentReferenceHome),
                File.join('ESReference', Constants.CalcTypeERIRatedHome),
                File.join('ESReference', Constants.CalcTypeERIReferenceHome),
                File.join('ESReference', Constants.CalcTypeERIIndexAdjustmentDesign),
                File.join('ESReference', Constants.CalcTypeERIIndexAdjustmentReferenceHome)].map { |d| d.gsub(' ', '') }
    log_dirs << 'results'
  end

  if expect_error
    if expect_error_msgs.nil?
      flunk "No error message defined for #{File.basename(xml)}."
    else
      found_error_msg = false
      log_dirs.each do |log_dir|
        next unless File.exist? File.join(rundir, log_dir, 'run.log')

        run_log = File.readlines(File.join(rundir, log_dir, 'run.log')).map(&:strip)
        expect_error_msgs.each do |error_msg|
          run_log.each do |run_line|
            next unless run_line.include? error_msg

            found_error_msg = true
            break
          end
        end
      end
      assert(found_error_msg)
    end
  else
    # Check all output files exist
    hpxmls.keys.each do |k|
      assert(File.exist?(hpxmls[k]))
    end
    csvs.keys.each do |k|
      assert(File.exist?(csvs[k]))
    end

    # Check HPXMLs are valid
    _test_schema_validation(xml)
    hpxmls.keys.each do |k|
      _test_schema_validation(hpxmls[k])
    end

    # Check run.log for OS warnings
    log_dirs.each do |log_dir|
      next unless File.exist? File.join(rundir, log_dir, 'run.log')

      run_log = File.readlines(File.join(rundir, log_dir, 'run.log')).map(&:strip)
      run_log.each do |log_line|
        next unless log_line.include? 'OS Message:'
        next if log_line.include?('OS Message: Minutes field (60) on line 9 of EPW file')

        flunk "Unexpected warning found in #{log_dir} run.log: #{log_line}"
      end
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
  args['include_timeseries_fuel_consumptions'] = false
  args['include_timeseries_end_use_consumptions'] = false
  args['include_timeseries_emissions'] = false
  args['include_timeseries_hot_water_uses'] = false
  args['include_timeseries_total_loads'] = false
  args['include_timeseries_component_loads'] = false
  args['include_timeseries_zone_temperatures'] = false
  args['include_timeseries_airflows'] = false
  args['include_timeseries_weather'] = false
  update_args_hash(measures, measure_subdir, args)

  results = run_hpxml_workflow(rundir, measures, measures_dir)

  assert(results[:success])

  sql_path = File.join(rundir, 'eplusout.sql')
  assert(File.exist?(sql_path))

  csv_path = File.join(rundir, 'results_annual.csv')
  assert(File.exist?(csv_path))

  return sql_path, csv_path, results[:sim_time]
end

def _get_simulation_load_results(csv_path)
  results = _get_csv_results(csv_path)
  htg_load = results['Load: Heating: Delivered (MBtu)'].round(2)
  clg_load = results['Load: Cooling: Delivered (MBtu)'].round(2)

  return htg_load, clg_load
end

def _get_csv_results(csv1, csv2 = nil)
  results = {}
  [csv1, csv2].each do |csv|
    next if csv.nil?
    next unless File.exist? csv

    CSV.foreach(csv) do |row|
      next if row.nil? || (row.size < 2)

      if row[0] == 'ENERGY STAR Certification' # String outputs
        results[row[0]] = row[1]
      elsif row[1].include? ',' # Sum values for visualization on CI
        results[row[0]] = row[1].split(',').map(&:to_f).sum
      else
        results[row[0]] = Float(row[1])
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
