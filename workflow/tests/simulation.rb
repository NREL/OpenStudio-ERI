start_time = Time.now

require 'optparse'
require 'csv'
require 'pathname'
require 'fileutils'
require 'openstudio'
require_relative "../../measures/301EnergyRatingIndexRuleset/resources/unit_conversions"
require_relative "../../measures/301EnergyRatingIndexRuleset/resources/util"

# TODO: Add error-checking
# TODO: Add standardized reporting of errors

basedir = File.expand_path(File.dirname(__FILE__))
      
def rm_path(path)
  if Dir.exists?(path)
    FileUtils.rm_r(path)
  end
  for retries in 1..50
    break if not Dir.exists?(path)
    sleep(0.01)
  end
end
      
def remove_design_dir(design, basedir)

  designdir = File.join(basedir, design.gsub(' ',''))
  rm_path(designdir)
  
  return designdir
end
      
def create_osw(design, designdir, basedir, resultsdir, options)

  # Create dir
  Dir.mkdir(designdir)
  
  # Create OSW
  osw_path = File.join(designdir, "run.osw")
  osw = OpenStudio::WorkflowJSON.new
  osw.setOswPath(osw_path)
  osw.addMeasurePath("../../../measures")
  
  # Add measures (w/args) to OSW
  schemas_dir = File.absolute_path(File.join(basedir, "..", "..", "hpxml_schemas"))
  weather_dir = File.absolute_path(File.join(File.dirname(options[:hpxml]), "weather"))
  output_hpxml_path = File.join(resultsdir, File.basename(designdir) + ".xml")
  measures = {}
  measures['301EnergyRatingIndexRuleset'] = {}
  measures['301EnergyRatingIndexRuleset']['calc_type'] = "None"
  measures['301EnergyRatingIndexRuleset']['hpxml_file_path'] = options[:hpxml]
  measures['301EnergyRatingIndexRuleset']['weather_dir'] = weather_dir
  #measures['301EnergyRatingIndexRuleset']['schemas_dir'] = schemas_dir # FIXME
  measures['301EnergyRatingIndexRuleset']['hpxml_output_file_path'] = output_hpxml_path
  measures['301EnergyRatingIndexRuleset']['debug'] = options[:debug].to_s
  steps = OpenStudio::WorkflowStepVector.new
  measures.keys.each do |measure|
    step = OpenStudio::MeasureStep.new(measure)
    step.setName(measure)
    measures[measure].each do |arg,val|
      step.setArgument(arg, val)
    end
    steps.push(step)
  end  
  osw.setWorkflowSteps(steps)
  
  # Save OSW
  osw.save
  
  return osw_path, output_hpxml_path
  
end

def run_osw(osw_path, options)

  # Redirect to a log file
  log_str = " >> \"#{osw_path.gsub('.osw','.log')}\""
  
  # FIXME: Push changes upstream to OpenStudio-workflow gem
  gem_str = '-I ../../gems/OpenStudio-workflow-gem/lib/ '
  
  debug_str = ''
  verbose_str = ''
  if options[:debug]
    debug_str = '--debug '
    verbose_str = '--verbose '
  end

  cli_path = OpenStudio.getOpenStudioCLI
  command = "\"#{cli_path}\" #{verbose_str}#{gem_str}run #{debug_str}-w \"#{osw_path}\"#{log_str}"
  system(command)
  
  return File.join(File.dirname(osw_path), "run", "eplusout.sql")
  
end

def get_sql_query_result(sqlFile, query)
  result = sqlFile.execAndReturnFirstDouble(query)
  if result.is_initialized
    return UnitConversions.convert(result.get, "GJ", "MBtu")
  end
  return 0
end

def read_output(design, sql_path, output_hpxml_path)
  if not File.exists?(sql_path)
    fail "ERROR: Simulation unsuccessful for #{design}."
  end
  
  sqlFile = OpenStudio::SqlFile.new(sql_path, false)
  
  design_output = {}
  
  # Space Heating Load
  vars = "'" + BuildingLoadVars.get_space_heating_load_vars.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadHeating] = get_sql_query_result(sqlFile, query)
  
  # Space Cooling Load
  vars = "'" + BuildingLoadVars.get_space_cooling_load_vars.join("','") + "'"
  query = "SELECT SUM(ABS(VariableValue)/1000000000) FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex IN (SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableType='Sum' AND IndexGroup='System' AND TimestepType='Zone' AND VariableName IN (#{vars}) AND ReportingFrequency='Run Period' AND VariableUnits='J')"
  design_output[:loadCooling] = get_sql_query_result(sqlFile, query)
  
  return design_output
  
end

def write_results(output, resultsdir)

  # Results file
  results_csv = File.join(resultsdir, "Loads_Results.csv")
  results_out = {}
  results_out["Heating Load (MBtu)"] = output[:loadHeating].round(2)
  results_out["Cooling Load (MBtu)"] = output[:loadCooling].round(2)
  CSV.open(results_csv, "wb") {|csv| results_out.to_a.each {|elem| csv << elem} }
  
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -x building.xml\n e.g., #{File.basename(__FILE__)} -x sample_files/valid.xml\n"

  opts.on('-x', '--xml <FILE>', 'HPXML file') do |t|
    options[:hpxml] = t
  end

  options[:debug] = false
  opts.on('-d', '--debug') do |t|
    options[:debug] = true
  end
  
  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end

end.parse!

if not options[:hpxml]
  fail "ERROR: HPXML argument is required. Call #{File.basename(__FILE__)} -h for usage."
end

unless (Pathname.new options[:hpxml]).absolute?
  options[:hpxml] = File.expand_path(File.join(File.dirname(__FILE__), options[:hpxml]))
end 
unless File.exists?(options[:hpxml]) and options[:hpxml].downcase.end_with? ".xml"
  fail "ERROR: '#{options[:hpxml]}' does not exist or is not an .xml file."
end

# Check for correct versions of OS
os_version = "2.5.1"
if OpenStudio.openStudioVersion != os_version
  fail "ERROR: OpenStudio version #{os_version} is required."
end

# Create results dir
resultsdir = File.join(basedir, "results")
rm_path(resultsdir)
Dir.mkdir(resultsdir)

design = "SimulationHome"
puts "HPXML: #{options[:hpxml]}"

designdir = remove_design_dir(design, basedir)

puts "[#{design}] Running workflow...\n"
osw_path, output_hpxml_path = create_osw(design, designdir, basedir, resultsdir, options)
sql_path = run_osw(osw_path, options)

puts "[#{design}] Gathering results...\n"
output = read_output(design, sql_path, output_hpxml_path)

puts "[#{design}] Done.\n"

puts "Writing output files..."
write_results(output, resultsdir)

puts "Completed in #{(Time.now - start_time).round(1)} seconds."