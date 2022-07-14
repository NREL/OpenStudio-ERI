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

def _run_workflow(xml, test_name, timeseries_frequency: 'none', component_loads: false,
                  skip_simulation: false, rated_home_only: false)
  xml = File.absolute_path(xml)
  hpxml_doc = XMLHelper.parse_file(xml)
  eri_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/ERICalculation/Version', :string)
  iecc_eri_version = XMLHelper.get_value(hpxml_doc, '/HPXML/SoftwareInfo/extension/IECCERICalculation/Version', :string)
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
      if File.exist? File.join(rundir, 'results', 'CO2e_Results.csv')
        hpxmls[:co2ref] = File.join(rundir, 'results', 'CO2eReferenceHome.xml')
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

  # Check HPXMLs are valid
  _test_schema_validation(xml)
  hpxmls.values.each do |hpxml_path|
    _test_schema_validation(hpxml_path)
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
      if csv.include? 'IECC'
        key = "IECC #{key}"
      end
      if key == 'ENERGY STAR Certification' # String outputs
        results[key] = value
      elsif value.include? ',' # Sum values for visualization on CI
        results[key] = value.split(',').map(&:to_f).sum
      else
        results[key] = Float(value)
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
