# frozen_string_literal: true

require 'oga'
require_relative '../../rulesets/301EnergyRatingIndexRuleset/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/constants'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hotwater_appliances'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/hvac_sizing'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/misc_loads'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../hpxml-measures/HPXMLtoOpenStudio/resources/xmlhelper'

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

def _run_workflow(xml, test_name, expect_error: false, expect_error_msgs: nil, timeseries_frequency: 'none',
                  component_loads: false, skip_simulation: false, rated_home_only: false)
  xml = File.absolute_path(xml)
  hpxml_doc = XMLHelper.parse_file(xml)
  eri_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/ERICalculation/Version', :string)
  es_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/EnergyStarCalculation/Version', :string)

  rundir = File.join(@test_files_dir, test_name, File.basename(xml))

  timeseries = ''
  if timeseries_frequency != 'none'
    timeseries = " --#{timeseries_frequency} ALL"
  end
  comploads = ''
  if component_loads
    comploads = ' --add-component-loads'
  end
  skipsim = ''
  if skip_simulation
    skipsim = ' --skip-simulation'
  end
  ratedhome = ''
  if rated_home_only
    ratedhome = ' --rated-home-only'
  end

  # Run workflow
  workflow_rb = 'energy_rating_index.rb'
  command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(File.dirname(__FILE__), "../#{workflow_rb}")}\" -x \"#{xml}\"#{timeseries}#{comploads}#{skipsim}#{ratedhome} -o \"#{rundir}\" --debug"
  system(command)

  hpxmls = {}
  csvs = {}
  if rated_home_only
    # ERI w/ Rated Home only
    hpxmls[:rated] = File.join(rundir, 'results', 'ERIRatedHome.xml')
    csvs[:rated_results] = File.join(rundir, 'results', 'ERIRatedHome.csv')
    log_dirs = [Constants.CalcTypeERIRatedHome].map { |d| d.gsub(' ', '') }
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
      log_dirs = [Constants.CalcTypeERIRatedHome,
                  Constants.CalcTypeERIReferenceHome,
                  Constants.CalcTypeERIIndexAdjustmentDesign,
                  Constants.CalcTypeERIIndexAdjustmentReferenceHome].map { |d| d.gsub(' ', '') }
      if File.exist? File.join(rundir, 'results', 'CO2e_Results.csv')
        hpxmls[:co2ref] = File.join(rundir, 'results', 'CO2eReferenceHome.xml')
        csvs[:co2e_results] = File.join(rundir, 'results', 'CO2e_Results.csv')
        log_dirs << Constants.CalcTypeCO2eReferenceHome.gsub(' ', '')
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
      log_dirs = [[ESConstants.CalcTypeEnergyStarReference, Constants.CalcTypeERIRatedHome],
                  [ESConstants.CalcTypeEnergyStarReference, Constants.CalcTypeERIReferenceHome],
                  [ESConstants.CalcTypeEnergyStarReference, Constants.CalcTypeERIIndexAdjustmentDesign],
                  [ESConstants.CalcTypeEnergyStarReference, Constants.CalcTypeERIIndexAdjustmentReferenceHome],
                  [ESConstants.CalcTypeEnergyStarRated, Constants.CalcTypeERIRatedHome],
                  [ESConstants.CalcTypeEnergyStarRated, Constants.CalcTypeERIReferenceHome],
                  [ESConstants.CalcTypeEnergyStarRated, Constants.CalcTypeERIIndexAdjustmentDesign],
                  [ESConstants.CalcTypeEnergyStarRated, Constants.CalcTypeERIIndexAdjustmentReferenceHome]].map { |d| d[0].gsub(' ', '') + '_' + d[1].gsub(' ', '') }
    end
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
    if not skip_simulation
      csvs.keys.each do |k|
        assert(File.exist?(csvs[k]))
      end
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

def _test_schema_validation(xml)
  # TODO: Remove this when schema validation is included with CLI calls
  schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', 'hpxml-measures', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema'))
  hpxml_doc = XMLHelper.parse_file(xml)
  errors = XMLHelper.validate(hpxml_doc.to_xml, File.join(schemas_dir, 'HPXML.xsd'), nil)
  if errors.size > 0
    puts "#{xml}: #{errors}"
  end
  assert_equal(0, errors.size)
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
