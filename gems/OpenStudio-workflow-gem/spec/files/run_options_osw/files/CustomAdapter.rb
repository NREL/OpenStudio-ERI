require 'openstudio'
require 'openstudio-workflow'
require 'openstudio/workflow/adapters/output_adapter'

# Custom Output Adapter

class CustomAdapter < OpenStudio::Workflow::OutputAdapters
  def initialize(options = {})
    raise 'The required :output_directory option was not passed to the local output adapter' unless options[:output_directory]
    raise 'The required :custom_option option was not passed to the local output adapter' unless options[:custom_option]
    
    super
  end
  
  # Write to the filesystem that the process has started
  #
  def communicate_started
    File.open("#{@options[:output_directory]}/custom_started.job", 'w') { |f| f << "Started Workflow #{::Time.now} #{@options}" }
  end

  # Write to the filesystem that the process has completed
  #
  def communicate_complete
    File.open("#{@options[:output_directory]}/custom_finished.job", 'w') { |f| f << "Finished Workflow #{::Time.now} #{@options}" }
  end

  # Write to the filesystem that the process has failed
  #
  def communicate_failure
    File.open("#{@options[:output_directory]}/custom_failed.job", 'w') { |f| f << "Failed Workflow #{::Time.now} #{@options}" }
  end

  # Do nothing on a state transition
  #
  def communicate_transition(_ = nil, _ = nil, _ = nil)
  end

  # Do nothing on EnergyPlus stdout
  #
  def communicate_energyplus_stdout(_ = nil, _ = nil)
  end
  
  # Do nothing on Measure result
  #
  def communicate_measure_result(_ = nil, _ = nil)
  end

  # Write the measure attributes to the filesystem
  #
  def communicate_measure_attributes(measure_attributes, _ = nil)
    File.open("#{@options[:output_directory]}/measure_attributes.json", 'w') do |f|
      f << JSON.pretty_generate(measure_attributes)
    end
  end

  # Write the objective function results to the filesystem
  #
  def communicate_objective_function(objectives, _ = nil)
    obj_fun_file = "#{@options[:output_directory]}/objectives.json"
    FileUtils.rm_f(obj_fun_file) if File.exist?(obj_fun_file)
    File.open(obj_fun_file, 'w') { |f| f << JSON.pretty_generate(objectives) }
  end

  # Write the results of the workflow to the filesystem
  #
  def communicate_results(directory, results)
    zip_results(directory)

    if results.is_a? Hash
      File.open("#{@options[:output_directory]}/data_point_out.json", 'w') { |f| f << JSON.pretty_generate(results) }
    else
      puts "Unknown datapoint result type. Please handle #{results.class}"
    end
  end

end
