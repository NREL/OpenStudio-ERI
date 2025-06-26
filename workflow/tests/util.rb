# frozen_string_literal: true

require 'oga'
require 'json'
require 'json-schema'
require_relative '../design'
require_relative '../util'
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

def _run_workflow(xml, test_name, timeseries_frequency: 'none', component_loads: false, skip_simulation: false,
                  rated_home_only: false, output_format: 'csv', diagnostic_output: false)
  xml = File.absolute_path(xml)
  hpxml = HPXML.new(hpxml_path: xml)

  eri_versions = hpxml.header.eri_calculation_versions
  co2_versions = hpxml.header.co2index_calculation_versions
  iecc_versions = hpxml.header.iecc_eri_calculation_versions
  es_versions = hpxml.header.energystar_calculation_versions
  zerh_versions = hpxml.header.zerh_calculation_versions

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
  if diagnostic_output && (not eri_versions.empty?)
    # ERI required to generate diagnostic output
    flags += ' --diagnostic-output'
  end

  # Run workflow
  workflow_rb = 'energy_rating_index.rb'
  command = "\"#{OpenStudio.getOpenStudioCLI}\" \"#{File.join(File.dirname(__FILE__), "../#{workflow_rb}")}\" -x \"#{xml}\"#{flags} -o \"#{rundir}\" --output-format #{output_format} --debug"
  system(command)

  hpxmls = {}
  outputs = {}
  if rated_home_only
    # ERI w/ Rated Home only
    eri_versions.each do |eri_version|
      results_dir = File.join(rundir, "ERI_#{eri_version}", 'results')
      hpxmls[:rated] = File.join(results_dir, 'RatedHome.xml')
      outputs[:rated_results] = File.join(results_dir, "RatedHome.#{output_format}")
    end
  else
    # ERI
    eri_versions.each do |eri_version|
      results_dir = File.join(rundir, "ERI_#{eri_version}", 'results')
      hpxmls[:ref] = File.join(results_dir, 'ReferenceHome.xml')
      hpxmls[:rated] = File.join(results_dir, 'RatedHome.xml')
      if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014AE')
        hpxmls[:iad] = File.join(results_dir, 'IndexAdjustmentHome.xml')
        hpxmls[:iadref] = File.join(results_dir, 'IndexAdjustmentReferenceHome.xml')
      end
      outputs[:eri_results] = File.join(results_dir, "results.#{output_format}")
      outputs[:rated_results] = File.join(results_dir, "RatedHome.#{output_format}")
      outputs[:ref_results] = File.join(results_dir, "ReferenceHome.#{output_format}")
      if Constants::ERIVersions.index(eri_version) >= Constants::ERIVersions.index('2014AE')
        outputs[:iad] = File.join(results_dir, "IndexAdjustmentHome.#{output_format}")
        outputs[:iadref] = File.join(results_dir, "IndexAdjustmentReferenceHome.#{output_format}")
      end
      if timeseries_frequency != 'none'
        outputs[:rated_timeseries_results] = File.join(results_dir, "RatedHome_#{timeseries_frequency.capitalize}.#{output_format}")
        outputs[:ref_timeseries_results] = File.join(results_dir, "ReferenceHome_#{timeseries_frequency.capitalize}.#{output_format}")
      end
    end
    # CO2e
    co2_versions.each do |co2_version|
      results_dir = File.join(rundir, "CO2e_#{co2_version}", 'results')
      hpxmls[:co2ref] = File.join(results_dir, 'ReferenceHome.xml')
      if File.exist? File.join(results_dir, 'results.csv') # Some HPXMLs (e.g., in AK/HI or with wood fuel) won't produce a CO2 Index
        outputs[:co2e_results] = File.join(results_dir, "results.#{output_format}")
      end
    end
    # IECC
    iecc_versions.each do |iecc_version|
      results_dir = File.join(rundir, "IECC_#{iecc_version}", 'results')
      hpxmls[:iecc_eri_ref] = File.join(results_dir, 'ReferenceHome.xml')
      hpxmls[:iecc_eri_rated] = File.join(results_dir, 'RatedHome.xml')
      outputs[:iecc_eri_results] = File.join(results_dir, "results.#{output_format}")
      outputs[:iecc_eri_rated_results] = File.join(results_dir, "RatedHome.#{output_format}")
      outputs[:iecc_eri_ref_results] = File.join(results_dir, "ReferenceHome.#{output_format}")
      if timeseries_frequency != 'none'
        outputs[:iecc_eri_rated_timeseries_results] = File.join(results_dir, "RatedHome_#{timeseries_frequency.capitalize}.#{output_format}")
        outputs[:iecc_eri_ref_timeseries_results] = File.join(results_dir, "ReferenceHome_#{timeseries_frequency.capitalize}.#{output_format}")
      end
    end
    # ENERGY STAR
    es_versions.each do |es_version|
      top_results_dir = File.join(rundir, "ES_#{es_version}", 'results')
      target_results_dir = File.join(rundir, "ES_#{es_version}", 'TargetHome', 'results')
      rated_results_dir = File.join(rundir, "ES_#{es_version}", 'RatedHome', 'results')
      hpxmls[:esref] = File.join(top_results_dir, 'TargetHome.xml')
      hpxmls[:esrat] = File.join(top_results_dir, 'RatedHome.xml')
      hpxmls[:esref_ref] = File.join(target_results_dir, 'ReferenceHome.xml')
      hpxmls[:esref_rated] = File.join(target_results_dir, 'RatedHome.xml')
      hpxmls[:esref_iad] = File.join(target_results_dir, 'IndexAdjustmentHome.xml')
      hpxmls[:esref_iadref] = File.join(target_results_dir, 'IndexAdjustmentReferenceHome.xml')
      hpxmls[:esrat_ref] = File.join(rated_results_dir, 'ReferenceHome.xml')
      hpxmls[:esrat_rated] = File.join(rated_results_dir, 'RatedHome.xml')
      hpxmls[:esrat_iad] = File.join(rated_results_dir, 'IndexAdjustmentHome.xml')
      hpxmls[:esrat_iadref] = File.join(rated_results_dir, 'IndexAdjustmentReferenceHome.xml')
      outputs[:es_results] = File.join(top_results_dir, "results.#{output_format}")
      outputs[:esref_eri_results] = File.join(target_results_dir, "results.#{output_format}")
      outputs[:esrat_eri_results] = File.join(rated_results_dir, "results.#{output_format}")
      outputs[:esref_rated_results] = File.join(target_results_dir, "RatedHome.#{output_format}")
      outputs[:esref_ref_results] = File.join(target_results_dir, "ReferenceHome.#{output_format}")
      outputs[:esref_iad_results] = File.join(target_results_dir, "IndexAdjustmentHome.#{output_format}")
      outputs[:esref_iadref_results] = File.join(target_results_dir, "IndexAdjustmentReferenceHome.#{output_format}")
      outputs[:esrat_rated_results] = File.join(rated_results_dir, "RatedHome.#{output_format}")
      outputs[:esrat_ref_results] = File.join(rated_results_dir, "ReferenceHome.#{output_format}")
      outputs[:esrat_iad_results] = File.join(rated_results_dir, "IndexAdjustmentHome.#{output_format}")
      outputs[:esrat_iadref_results] = File.join(rated_results_dir, "IndexAdjustmentReferenceHome.#{output_format}")
      if timeseries_frequency != 'none'
        outputs[:esrat_timeseries_results] = File.join(rated_results_dir, "RatedHome_#{timeseries_frequency.capitalize}.#{output_format}")
        outputs[:esref_timeseries_results] = File.join(target_results_dir, "ReferenceHome_#{timeseries_frequency.capitalize}.#{output_format}")
      end
    end
    # ZERH
    zerh_versions.each do |zerh_version|
      top_results_dir = File.join(rundir, "ZERH_#{zerh_version}", 'results')
      target_results_dir = File.join(rundir, "ZERH_#{zerh_version}", 'TargetHome', 'results')
      rated_results_dir = File.join(rundir, "ZERH_#{zerh_version}", 'RatedHome', 'results')
      hpxmls[:zerhrref] = File.join(top_results_dir, 'TargetHome.xml')
      hpxmls[:zerhrat] = File.join(top_results_dir, 'RatedHome.xml')
      hpxmls[:zerhrref_ref] = File.join(target_results_dir, 'ReferenceHome.xml')
      hpxmls[:zerhrref_rated] = File.join(target_results_dir, 'RatedHome.xml')
      hpxmls[:zerhrref_iad] = File.join(target_results_dir, 'IndexAdjustmentHome.xml')
      hpxmls[:zerhrref_iadref] = File.join(target_results_dir, 'IndexAdjustmentReferenceHome.xml')
      hpxmls[:zerhrat_ref] = File.join(rated_results_dir, 'ReferenceHome.xml')
      hpxmls[:zerhrat_rated] = File.join(rated_results_dir, 'RatedHome.xml')
      hpxmls[:zerhrat_iad] = File.join(rated_results_dir, 'IndexAdjustmentHome.xml')
      hpxmls[:zerhrat_iadref] = File.join(rated_results_dir, 'IndexAdjustmentReferenceHome.xml')
      outputs[:zerh_results] = File.join(top_results_dir, "results.#{output_format}")
      outputs[:zerhrref_eri_results] = File.join(target_results_dir, "results.#{output_format}")
      outputs[:zerhrat_eri_results] = File.join(rated_results_dir, "results.#{output_format}")
      outputs[:zerhrref_rated_results] = File.join(target_results_dir, "RatedHome.#{output_format}")
      outputs[:zerhrref_ref_results] = File.join(target_results_dir, "ReferenceHome.#{output_format}")
      outputs[:zerhrref_iad_results] = File.join(target_results_dir, "IndexAdjustmentHome.#{output_format}")
      outputs[:zerhrref_iadref_results] = File.join(target_results_dir, "IndexAdjustmentReferenceHome.#{output_format}")
      outputs[:zerhrat_rated_results] = File.join(rated_results_dir, "RatedHome.#{output_format}")
      outputs[:zerhrat_ref_results] = File.join(rated_results_dir, "ReferenceHome.#{output_format}")
      outputs[:zerhrat_iad_results] = File.join(rated_results_dir, "IndexAdjustmentHome.#{output_format}")
      outputs[:zerhrat_iadref_results] = File.join(rated_results_dir, "IndexAdjustmentReferenceHome.#{output_format}")
      if timeseries_frequency != 'none'
        outputs[:zerhrat_timeseries_results] = File.join(rated_results_dir, "RatedHome_#{timeseries_frequency.capitalize}.#{output_format}")
        outputs[:zerhrref_timeseries_results] = File.join(target_results_dir, "ReferenceHome_#{timeseries_frequency.capitalize}.#{output_format}")
      end
    end
  end

  # Check all output files exist
  hpxmls.values.each do |hpxml_path|
    puts "Did not find #{hpxml_path}" unless File.exist?(hpxml_path)
    assert(File.exist?(hpxml_path))
  end
  if not skip_simulation
    outputs.values.each do |output_path|
      puts "Did not find #{output_path}" unless File.exist?(output_path)
      assert(File.exist?(output_path))
    end
  end
  if diagnostic_output && (eri_versions.size == 1) && (Constants::ERIVersions.index(eri_versions[0]) >= Constants::ERIVersions.index('2014AE'))
    results_dir = File.join(rundir, "ERI_#{eri_versions[0]}", 'results')
    diag_output_path = File.join(results_dir, 'HERS_Diagnostic.json')
    puts "Did not find #{diag_output_path}" unless File.exist?(diag_output_path)
    assert(File.exist?(diag_output_path))

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

  # Check run.log for OS warnings
  Dir["#{rundir}/*/run.log"].sort.each do |log_path|
    run_log = File.readlines(log_path).map(&:strip)
    run_log.each do |log_line|
      next unless log_line.include? 'OS Message:'
      next if log_line.include?('OS Message: Minutes field (60) on line 9 of EPW file')
      next if log_line.include?('OS Message: Error removing temporary directory at')

      flunk "Unexpected warning found in #{log_path} run.log: #{log_line}"
    end
  end

  return rundir, hpxmls, outputs
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
  measures[measure_subdir] = [args]

  # Add reporting measure to workflow
  measure_subdir = 'hpxml-measures/ReportSimulationOutput'
  args = {}
  args['timeseries_frequency'] = 'none'
  measures[measure_subdir] = [args]

  results = run_hpxml_workflow(rundir, measures, measures_dir)

  assert(results[:success])

  csv_path = File.join(rundir, 'results_annual.csv')
  assert(File.exist?(csv_path))

  return csv_path
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
        key = "IECC #{key}" unless key.start_with?('IECC ')
      elsif csv.include? 'ES_'
        key = "ES #{key}" unless key.start_with?('ES ')
      elsif csv.include? 'ZERH_'
        key = "ZERH #{key}" unless key.start_with?('ZERH ')
      elsif csv.include? 'CO2e_'
        key = "CO2e #{key}" unless key.start_with?('CO2e ')
      end
      if not results[key].nil?
        fail "Duplicate key: #{key}"
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

def _test_resnet_hers_reference_home_auto_generation(test_name, dir_name, version)
  test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
  File.delete(test_results_csv) if File.exist? test_results_csv

  # Run simulations
  all_results = {}
  xmldir = File.join(File.dirname(__FILE__), dir_name)
  Dir["#{xmldir}/*.xml"].sort.each do |xml|
    _rundir, hpxmls, _csvs = _run_workflow(xml, test_name, skip_simulation: true)

    test_num = File.basename(xml)[0, 2].to_i
    all_results[File.basename(xml)] = _get_reference_home_components(hpxmls[:ref], test_num, version)

    # Update HPXML to override mech vent fan power for eRatio test
    new_hpxml = HPXML.new(hpxml_path: hpxmls[:ref])
    new_hpxml_bldg = new_hpxml.buildings[0]
    new_hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      if (vent_fan.fan_type == HPXML::MechVentTypeSupply) || (vent_fan.fan_type == HPXML::MechVentTypeExhaust)
        vent_fan.fan_power = 0.35 * vent_fan.tested_flow_rate
      elsif vent_fan.fan_type == HPXML::MechVentTypeBalanced
        vent_fan.fan_power = 0.70 * vent_fan.tested_flow_rate
      elsif (vent_fan.fan_type == HPXML::MechVentTypeERV) || (vent_fan.fan_type == HPXML::MechVentTypeHRV)
        vent_fan.fan_power = 1.00 * vent_fan.tested_flow_rate
      end
    end
    new_hpxml_bldg.heat_pumps[0].backup_heating_lockout_temp = nil unless new_hpxml_bldg.heat_pumps.empty?
    XMLHelper.write_file(new_hpxml.to_doc, hpxmls[:ref])

    _rundir, _hpxmls, csvs = _run_workflow(hpxmls[:ref], test_name)
    eri_results = _get_csv_results([csvs[:eri_results]])
    all_results[File.basename(xml)]['e-Ratio'] = (eri_results['Total Loads TnML'] / eri_results['Total Loads TRL']).round(7)
  end
  assert(all_results.size > 0)

  # Write results to CSV
  CSV.open(test_results_csv, 'w') do |csv|
    # Write the header row with filenames
    header = ['Component'] + all_results.keys
    csv << header

    # Dynamically get the first file's components
    first_file = all_results.keys.first

    # Iterate over the components in the first file
    all_results[first_file].keys.each do |component|
      # Gather results from all files for the current component
      row = [component] + all_results.keys.map { |file| all_results[file][component] }
      csv << row
    end
  end
  puts "Wrote results to #{test_results_csv}."

  return all_results
end

def _test_resnet_hers_method(test_name, dir_name)
  test_results_csv = File.absolute_path(File.join(@test_results_dir, "#{test_name}.csv"))
  File.delete(test_results_csv) if File.exist? test_results_csv

  columns_of_interest = ['ERI',
                         'REUL Heating (MBtu)',
                         'REUL Cooling (MBtu)',
                         'REUL Hot Water (MBtu)',
                         'EC_r Heating (MBtu)',
                         'EC_r Cooling (MBtu)',
                         'EC_r Hot Water (MBtu)',
                         'EC_x Heating (MBtu)',
                         'EC_x Cooling (MBtu)',
                         'EC_x Hot Water (MBtu)',
                         'EC_x L&A (MBtu)',
                         'IAD_Save (%)']

  # Run simulations
  all_results = {}
  xmldir = File.join(File.dirname(__FILE__), dir_name)
  Dir["#{xmldir}/*.xml"].sort.each do |xml|
    _rundir, _hpxmls, csvs = _run_workflow(xml, test_name)
    results = _get_csv_results([csvs[:eri_results]])

    # Include columns only in the RESNET accreditation spreadsheet
    all_results[xml] = {}
    columns_of_interest.each do |col|
      all_results[xml][col] = results[col]
    end
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

def _get_reference_home_components(hpxml, test_num, version)
  results = {}
  hpxml = HPXML.new(hpxml_path: hpxml)
  hpxml_bldg = hpxml.buildings[0]
  eri_version = hpxml.header.eri_calculation_versions[0]

  # Above-grade walls
  wall_u, wall_solar_abs, wall_emiss, _wall_area = _get_above_grade_walls(hpxml_bldg)
  results['Above-grade walls (Uo)'] = wall_u.round(3)
  results['Above-grade wall solar absorptance (α)'] = wall_solar_abs.round(2)
  results['Above-grade wall infrared emittance (ε)'] = wall_emiss.round(2)

  # Basement walls
  bsmt_wall_r = _get_basement_walls(hpxml_bldg)
  if test_num == 4
    results['Basement walls insulation R-Value'] = bsmt_wall_r.round(0)
  else
    results['Basement walls insulation R-Value'] = 'n/a'
  end
  results['Basement walls (Uo)'] = 'n/a'

  # Above-grade floors
  floors_u = _get_above_grade_floors(hpxml_bldg)
  if test_num <= 2
    results['Above-grade floors (Uo)'] = floors_u.round(3)
  else
    results['Above-grade floors (Uo)'] = 'n/a'
  end

  # Slab insulation
  slab_r, carpet_r, exp_mas_floor_area = _get_slabs(hpxml_bldg)
  if test_num >= 3
    results['Slab insulation R-Value'] = slab_r.round(0)
  else
    results['Slab insulation R-Value'] = 'n/a'
  end

  # Ceilings
  ceil_u, _ceil_area = _get_ceilings(hpxml_bldg)
  results['Ceilings (Uo)'] = ceil_u.round(3)

  # Roofs
  roof_solar_abs, roof_emiss, _roof_area = _get_roofs(hpxml_bldg)
  results['Roof solar absorptance (α)'] = roof_solar_abs.round(2)
  results['Roof infrared emittance (ε)'] = roof_emiss.round(2)

  # Attic vent area
  attic_vent_area = _get_attic_vent_area(hpxml_bldg)
  results['Attic vent area (ft2)'] = attic_vent_area.round(2)

  # Crawlspace vent area
  crawl_vent_area = _get_crawl_vent_area(hpxml_bldg)
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
  door_u, door_area = _get_doors(hpxml_bldg)
  results['Door Area (ft2)'] = door_area.round(0)
  results['Door U-Factor'] = door_u.round(2)

  # Windows
  win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml_bldg)
  results['North window area (ft2)'] = win_areas[0].round(2)
  results['South window area (ft2)'] = win_areas[180].round(2)
  results['East window area (ft2)'] = win_areas[90].round(2)
  results['West window area (ft2)'] = win_areas[270].round(2)
  results['Window U-Factor'] = win_u.round(2)
  if version == '2022C'
    results['Window SHGCo'] = win_shgc_htg.round(2)
    assert_equal(win_shgc_htg, win_shgc_clg)
  else
    results['Window SHGCo (heating)'] = win_shgc_htg.round(2)
    results['Window SHGCo (cooling)'] = win_shgc_clg.round(2)
  end

  # Infiltration
  sla, _ach50 = _get_infiltration(hpxml_bldg)
  results['SLAo (ft2/ft2)'] = sla.round(5)

  # Internal gains
  xml_it_sens, xml_it_lat = _get_internal_gains(hpxml_bldg, eri_version)
  results['Sensible Internal gains (Btu/day)'] = xml_it_sens.round(0)
  results['Latent Internal gains (Btu/day)'] = xml_it_lat.round(0)

  # HVAC
  afue, hspf, seer, dse = _get_hvac(hpxml_bldg)
  if (test_num == 1) || (test_num == 4)
    results['Labeled heating system rating and efficiency'] = afue.round(2)
  else
    results['Labeled heating system rating and efficiency'] = hspf.round(1)
  end
  results['Labeled cooling system rating and efficiency'] = seer.round(1)
  results['Air Distribution System Efficiency'] = dse.round(2)

  # Thermostat
  tstat, htg_sp, clg_sp = _get_tstat(eri_version, hpxml_bldg)
  results['Thermostat Type'] = tstat
  results['Heating thermostat settings'] = htg_sp.round(0)
  results['Cooling thermostat settings'] = clg_sp.round(0)

  # Mechanical ventilation
  mv_kwh, _mv_cfm = _get_mech_vent(hpxml_bldg)
  results['Mechanical ventilation (kWh/y)'] = mv_kwh.round(2)

  # Domestic hot water
  ref_pipe_l, ref_loop_l = _get_dhw(hpxml_bldg)
  results['DHW pipe length refPipeL'] = ref_pipe_l.round(1)
  results['DHW loop length refLoopL'] = ref_loop_l.round(1)

  return results
end

def _get_iad_home_components(hpxml, test_num)
  results = {}
  hpxml = HPXML.new(hpxml_path: hpxml)
  hpxml_bldg = hpxml.buildings[0]
  eri_version = hpxml.header.eri_calculation_versions[0]

  # Geometry
  results['Number of Stories'] = hpxml_bldg.building_construction.number_of_conditioned_floors
  results['Number of Bedrooms'] = hpxml_bldg.building_construction.number_of_bedrooms
  results['Conditioned Floor Area (ft2)'] = hpxml_bldg.building_construction.conditioned_floor_area
  results['Infiltration Volume (ft3)'] = hpxml_bldg.air_infiltration_measurements[0].infiltration_volume

  # Above-grade Walls
  wall_u, _wall_solar_abs, _wall_emiss, wall_area = _get_above_grade_walls(hpxml_bldg)
  results['Above-grade walls area (ft2)'] = wall_area
  results['Above-grade walls (Uo)'] = wall_u

  # Roof
  _roof_solar_abs, _roof_emiss, roof_area = _get_roofs(hpxml_bldg)
  results['Roof gross area (ft2)'] = roof_area

  # Ceilings
  ceil_u, ceil_area = _get_ceilings(hpxml_bldg)
  results['Ceiling gross projected footprint area (ft2)'] = ceil_area
  results['Ceilings (Uo)'] = ceil_u

  # Crawlspace
  crawl_vent_area = _get_crawl_vent_area(hpxml_bldg)
  results['Crawlspace vent area (ft2)'] = crawl_vent_area

  # Doors
  door_u, door_area = _get_doors(hpxml_bldg)
  results['Door Area (ft2)'] = door_area
  results['Door R-value'] = 1.0 / door_u

  # Windows
  win_areas, win_u, win_shgc_htg, win_shgc_clg = _get_windows(hpxml_bldg)
  results['North window area (ft2)'] = win_areas[0]
  results['South window area (ft2)'] = win_areas[180]
  results['East window area (ft2)'] = win_areas[90]
  results['West window area (ft2)'] = win_areas[270]
  results['Window U-Factor'] = win_u
  results['Window SHGCo (heating)'] = win_shgc_htg
  results['Window SHGCo (cooling)'] = win_shgc_clg

  # Infiltration
  _sla, ach50 = _get_infiltration(hpxml_bldg)
  results['Infiltration rate (ACH50)'] = ach50

  # Mechanical Ventilation
  mv_kwh, mv_cfm = _get_mech_vent(hpxml_bldg)
  results['Mechanical ventilation rate'] = mv_cfm
  results['Mechanical ventilation'] = mv_kwh

  # HVAC
  afue, hspf, seer, _dse = _get_hvac(hpxml_bldg)
  if (test_num == 1) || (test_num == 4)
    results['Labeled heating system rating and efficiency'] = afue
  else
    results['Labeled heating system rating and efficiency'] = hspf
  end
  results['Labeled cooling system rating and efficiency'] = seer

  # Thermostat
  tstat, htg_sp, clg_sp = _get_tstat(eri_version, hpxml_bldg)
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
  if version == '2022C'
    # Pub 002-2024
    assert_equal(0.33, results['Window SHGCo'])
  else
    assert_equal(0.34, results['Window SHGCo (heating)'])
    assert_equal(0.28, results['Window SHGCo (cooling)'])
  end

  # Infiltration
  assert_equal(0.00036, results['SLAo (ft2/ft2)'])

  # Internal gains
  if version == 'latest'
    # Includes updated values due to MINHERS Addenda 81 and 90f and provided by Philip on 5/29/25
    if test_num == 1
      assert_in_epsilon(55037, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(13589, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 2
      assert_in_epsilon(52367, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(12519, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 3
      assert_in_epsilon(47826, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(9146, results['Latent Internal gains (Btu/day)'], epsilon)
    else
      assert_in_epsilon(82522, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(17646, results['Latent Internal gains (Btu/day)'], epsilon)
    end
  elsif version == '2022C'
    # Pub 002-2024
    if test_num == 1
      assert_in_epsilon(55142, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(13635, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 2
      assert_in_epsilon(52470, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(12565, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 3
      assert_in_epsilon(47839, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(9150, results['Latent Internal gains (Btu/day)'], epsilon)
    else
      assert_in_epsilon(82721, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(17734, results['Latent Internal gains (Btu/day)'], epsilon)
    end
  else
    # Note: Values have been updated slightly relative to Pub 002 because we are
    # using rounded F_sensible values from 301-2022 Addendum C instead of the
    # previously prescribed internal gains.
    if test_num == 1
      assert_in_epsilon(55520, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(13776, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 2
      assert_in_epsilon(52809, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(12701, results['Latent Internal gains (Btu/day)'], epsilon)
    elsif test_num == 3
      assert_in_epsilon(48124, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(9263, results['Latent Internal gains (Btu/day)'], epsilon)
    else
      assert_in_epsilon(83160, results['Sensible Internal gains (Btu/day)'], epsilon)
      assert_in_epsilon(17899, results['Latent Internal gains (Btu/day)'], epsilon)
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
  if version == '2022C'
    # Pub 002-2024
    mv_kwh_yr = { 1 => 0.0, 2 => 223.9, 3 => 288.1, 4 => 763.4 }[test_num]
  elsif version == '2019'
    mv_kwh_yr = { 1 => 0.0, 2 => 222.1, 3 => 288.1, 4 => 763.4 }[test_num]
  elsif version == '2014'
    mv_kwh_yr = { 1 => 0.0, 2 => 77.9, 3 => 140.4, 4 => 379.1 }[test_num]
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
  mv_cfm = { 1 => 66.4, 2 => 64.2, 3 => 53.3, 4 => 57.1 }[test_num]
  mv_kwh = { 1 => 407, 2 => 394, 3 => 327, 4 => 350 }[test_num]
  assert_in_delta(mv_cfm, results['Mechanical ventilation rate'], 0.2)
  assert_in_delta(mv_kwh, results['Mechanical ventilation'], 1.0)

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

def _get_above_grade_walls(hpxml_bldg)
  u_factor = solar_abs = emittance = area = num = 0.0
  hpxml_bldg.walls.each do |wall|
    next unless wall.is_exterior_thermal_boundary

    u_factor += 1.0 / wall.insulation_assembly_r_value
    solar_abs += wall.solar_absorptance
    emittance += wall.emittance
    area += wall.area
    num += 1
  end
  return u_factor / num, solar_abs / num, emittance / num, area
end

def _get_basement_walls(hpxml_bldg)
  r_value = num = 0.0
  hpxml_bldg.foundation_walls.each do |foundation_wall|
    next unless foundation_wall.is_exterior_thermal_boundary

    r_value += foundation_wall.insulation_exterior_r_value
    r_value += foundation_wall.insulation_interior_r_value
    num += 1
  end
  return r_value / num
end

def _get_above_grade_floors(hpxml_bldg)
  u_factor = num = 0.0
  hpxml_bldg.floors.each do |floor|
    next unless floor.is_floor

    u_factor += 1.0 / floor.insulation_assembly_r_value
    num += 1
  end
  return u_factor / num
end

def _get_slabs(hpxml_bldg)
  r_value = carpet_r_value = exp_area = carpet_num = r_num = 0.0
  hpxml_bldg.slabs.each do |slab|
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

def _get_ceilings(hpxml_bldg)
  u_factor = area = num = 0.0
  hpxml_bldg.floors.each do |floor|
    next unless floor.is_ceiling

    u_factor += 1.0 / floor.insulation_assembly_r_value
    area += floor.area
    num += 1
  end
  return u_factor / num, area
end

def _get_roofs(hpxml_bldg)
  solar_abs = emittance = area = num = 0.0
  hpxml_bldg.roofs.each do |roof|
    solar_abs += roof.solar_absorptance
    emittance += roof.emittance
    area += roof.area
    num += 1
  end
  return solar_abs / num, emittance / num, area
end

def _get_attic_vent_area(hpxml_bldg)
  area = sla = 0.0
  hpxml_bldg.attics.each do |attic|
    next unless attic.attic_type == HPXML::AtticTypeVented

    sla = attic.vented_attic_sla
  end
  hpxml_bldg.floors.each do |floor|
    next unless floor.is_ceiling && (floor.exterior_adjacent_to == HPXML::LocationAtticVented)

    area += floor.area
  end
  return sla * area
end

def _get_crawl_vent_area(hpxml_bldg)
  area = sla = 0.0
  hpxml_bldg.foundations.each do |foundation|
    next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

    sla = foundation.vented_crawlspace_sla
  end
  hpxml_bldg.floors.each do |floor|
    next unless floor.is_floor && (floor.exterior_adjacent_to == HPXML::LocationCrawlspaceVented)

    area += floor.area
  end
  return sla * area
end

def _get_doors(hpxml_bldg)
  area = u_factor = num = 0.0
  hpxml_bldg.doors.each do |door|
    area += door.area
    u_factor += 1.0 / door.r_value
    num += 1
  end
  return u_factor / num, area
end

def _get_windows(hpxml_bldg)
  areas = { 0 => 0.0, 90 => 0.0, 180 => 0.0, 270 => 0.0 }
  u_factor = shgc_htg = shgc_clg = num = 0.0
  hpxml_bldg.windows.each do |window|
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

def _get_infiltration(hpxml_bldg)
  air_infil = hpxml_bldg.air_infiltration_measurements[0]
  ach50 = air_infil.air_leakage
  cfa = hpxml_bldg.building_construction.conditioned_floor_area
  infil_volume = air_infil.infiltration_volume
  sla = Airflow.get_infiltration_SLA_from_ACH50(ach50, infil_volume / cfa)
  return sla, ach50
end

def _get_internal_gains(hpxml_bldg, eri_version)
  s = ''
  nbeds = hpxml_bldg.building_construction.number_of_bedrooms
  cfa = hpxml_bldg.building_construction.conditioned_floor_area
  gfa = hpxml_bldg.slabs.select { |s| s.interior_adjacent_to == HPXML::LocationGarage }.map { |s| s.area }.sum

  xml_pl_sens = 0.0
  xml_pl_lat = 0.0

  # Plug loads
  hpxml_bldg.plug_loads.each do |plug_load|
    btu = UnitConversions.convert(plug_load.kwh_per_year, 'kWh', 'Btu')
    xml_pl_sens += (plug_load.frac_sensible * btu)
    xml_pl_lat += (plug_load.frac_latent * btu)
    s += "#{xml_pl_sens} #{xml_pl_lat}\n"
  end

  xml_appl_sens = 0.0
  xml_appl_lat = 0.0

  # Appliances: CookingRange
  cooking_range = hpxml_bldg.cooking_ranges[0]
  cooking_range.usage_multiplier = 1.0 if cooking_range.usage_multiplier.nil?
  oven = hpxml_bldg.ovens[0]
  cr_annual_kwh, cr_annual_therm, cr_frac_sens, cr_frac_lat = HotWaterAndAppliances.calc_range_oven_energy(nil, hpxml_bldg, cooking_range, oven)
  btu = UnitConversions.convert(cr_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cr_annual_therm, 'therm', 'Btu')
  xml_appl_sens += (cr_frac_sens * btu)
  xml_appl_lat += (cr_frac_lat * btu)

  # Appliances: Refrigerator
  refrigerator = hpxml_bldg.refrigerators[0]
  refrigerator.usage_multiplier = 1.0 if refrigerator.usage_multiplier.nil?
  rf_annual_kwh, rf_frac_sens, rf_frac_lat = HotWaterAndAppliances.calc_fridge_or_freezer_energy(nil, refrigerator)
  btu = UnitConversions.convert(rf_annual_kwh, 'kWh', 'Btu')
  xml_appl_sens += (rf_frac_sens * btu)
  xml_appl_lat += (rf_frac_lat * btu)

  # Appliances: Dishwasher
  dishwasher = hpxml_bldg.dishwashers[0]
  dishwasher.usage_multiplier = 1.0 if dishwasher.usage_multiplier.nil?
  dw_annual_kwh, dw_frac_sens, dw_frac_lat, _dw_gpd = HotWaterAndAppliances.calc_dishwasher_energy_gpd(nil, eri_version, hpxml_bldg, dishwasher)
  btu = UnitConversions.convert(dw_annual_kwh, 'kWh', 'Btu')
  xml_appl_sens += (dw_frac_sens * btu)
  xml_appl_lat += (dw_frac_lat * btu)

  # Appliances: ClothesWasher
  clothes_washer = hpxml_bldg.clothes_washers[0]
  clothes_washer.usage_multiplier = 1.0 if clothes_washer.usage_multiplier.nil?
  cw_annual_kwh, cw_frac_sens, cw_frac_lat, _cw_gpd = HotWaterAndAppliances.calc_clothes_washer_energy_gpd(nil, eri_version, hpxml_bldg, clothes_washer)
  btu = UnitConversions.convert(cw_annual_kwh, 'kWh', 'Btu')
  xml_appl_sens += (cw_frac_sens * btu)
  xml_appl_lat += (cw_frac_lat * btu)

  # Appliances: ClothesDryer
  clothes_dryer = hpxml_bldg.clothes_dryers[0]
  clothes_dryer.usage_multiplier = 1.0 if clothes_dryer.usage_multiplier.nil?
  cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = HotWaterAndAppliances.calc_clothes_dryer_energy(nil, eri_version, hpxml_bldg, clothes_dryer, clothes_washer)
  btu = UnitConversions.convert(cd_annual_kwh, 'kWh', 'Btu') + UnitConversions.convert(cd_annual_therm, 'therm', 'Btu')
  xml_appl_sens += (cd_frac_sens * btu)
  xml_appl_lat += (cd_frac_lat * btu)

  s += "#{xml_appl_sens} #{xml_appl_lat}\n"

  # Water Use
  xml_water_sens, xml_water_lat = Defaults.get_water_use_internal_gains(nbeds, nil, nil)
  s += "#{xml_water_sens} #{xml_water_lat}\n"

  # Occupants
  xml_occ_sens = 0.0
  xml_occ_lat = 0.0
  heat_gain, hrs_per_day, frac_sens, frac_lat = Defaults.get_occupancy_values()
  btu = nbeds * heat_gain * hrs_per_day * 365.0
  xml_occ_sens += (frac_sens * btu)
  xml_occ_lat += (frac_lat * btu)
  s += "#{xml_occ_sens} #{xml_occ_lat}\n"

  # Lighting
  xml_ltg_sens = 0.0
  f_int_cfl, f_grg_cfl, f_int_lfl, f_grg_lfl, f_int_led, f_grg_led = nil
  hpxml_bldg.lighting_groups.each do |lg|
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

def _get_hvac(hpxml_bldg)
  afue = hspf = seer = dse = num_afue = num_hspf = num_seer = num_dse = 0.0
  hpxml_bldg.heating_systems.each do |heating_system|
    afue += heating_system.heating_efficiency_afue
    num_afue += 1
  end
  hpxml_bldg.cooling_systems.each do |cooling_system|
    if not cooling_system.cooling_efficiency_seer.nil?
      seer += cooling_system.cooling_efficiency_seer
      num_seer += 1
    elsif not cooling_system.cooling_efficiency_seer2.nil?
      seer += HVAC.calc_seer_from_seer2(cooling_system)
      num_seer += 1
    end
  end
  hpxml_bldg.heat_pumps.each do |heat_pump|
    if not heat_pump.heating_efficiency_hspf.nil?
      hspf += heat_pump.heating_efficiency_hspf
      num_hspf += 1
    elsif not heat_pump.heating_efficiency_hspf2.nil?
      hspf += HVAC.calc_hspf_from_hspf2(heat_pump)
      num_hspf += 1
    end
    if not heat_pump.cooling_efficiency_seer.nil?
      seer += heat_pump.cooling_efficiency_seer
      num_seer += 1
    elsif not heat_pump.cooling_efficiency_seer2.nil?
      seer += HVAC.calc_seer_from_seer2(heat_pump)
      num_seer += 1
    end
  end
  hpxml_bldg.hvac_distributions.each do |hvac_distribution|
    dse += hvac_distribution.annual_heating_dse
    num_dse += 1
    dse += hvac_distribution.annual_cooling_dse
    num_dse += 1
  end
  return (afue / num_afue).round(2), (hspf / num_hspf).round(1), (seer / num_seer).round(1), (dse / num_dse).round(2)
end

def _get_tstat(eri_version, hpxml_bldg)
  hvac_control = hpxml_bldg.hvac_controls[0]
  tstat = hvac_control.control_type.gsub(' thermostat', '')
  htg_weekday_setpoints, htg_weekend_setpoints = Defaults.get_heating_setpoint(hvac_control.control_type, eri_version)
  clg_weekday_setpoints, clg_weekend_setpoints = Defaults.get_cooling_setpoint(hvac_control.control_type, eri_version)

  htg_weekday_setpoints = htg_weekday_setpoints.split(', ').map(&:to_f)
  htg_weekend_setpoints = htg_weekend_setpoints.split(', ').map(&:to_f)
  clg_weekday_setpoints = clg_weekday_setpoints.split(', ').map(&:to_f)
  clg_weekend_setpoints = clg_weekend_setpoints.split(', ').map(&:to_f)

  if htg_weekday_setpoints.uniq.size == 1 && htg_weekend_setpoints.uniq.size == 1 && htg_weekday_setpoints.uniq[0] == htg_weekend_setpoints.uniq[0]
    htg_sp = htg_weekday_setpoints.uniq[0]
  end
  if clg_weekday_setpoints.uniq.size == 1 && clg_weekend_setpoints.uniq.size == 1 && clg_weekday_setpoints.uniq[0] == clg_weekend_setpoints.uniq[0]
    clg_sp = clg_weekday_setpoints.uniq[0]
  end
  return tstat, htg_sp, clg_sp
end

def _get_mech_vent(hpxml_bldg)
  mv_kwh = mv_cfm = 0.0
  hpxml_bldg.ventilation_fans.each do |vent_fan|
    next unless vent_fan.used_for_whole_building_ventilation

    hours = vent_fan.hours_in_operation
    fan_w = vent_fan.fan_power
    mv_kwh += fan_w * 8.76 * hours / 24.0
    mv_cfm += vent_fan.tested_flow_rate
  end
  return mv_kwh, mv_cfm
end

def _get_dhw(hpxml_bldg)
  has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
  has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)
  cfa = hpxml_bldg.building_construction.conditioned_floor_area
  ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors
  ref_pipe_l = Defaults.get_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
  ref_loop_l = Defaults.get_recirc_loop_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
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

def _get_hot_water(results_csv)
  dhw_energy = 0
  recirc_energy = 0
  CSV.foreach(results_csv) do |row|
    next if row.nil? || row[0].nil?

    if ["End Use: #{FT::Gas}: #{EUT::HotWater} (MBtu)",
        "End Use: #{FT::Elec}: #{EUT::HotWater} (MBtu)"].include? row[0]
      dhw_energy += Float(row[1])
    elsif ["End Use: #{FT::Elec}: #{EUT::HotWaterRecircPump} (MBtu)"].include? row[0]
      recirc_energy += Float(row[1])
    end
  end
  return dhw_energy.round(2), recirc_energy.round(2)
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
  assert_operator((energy['L100AM-HW-01'] - energy['L100AM-HW-02']) / energy['L100AM-HW-01'] * 100, :<, -23.42)
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
