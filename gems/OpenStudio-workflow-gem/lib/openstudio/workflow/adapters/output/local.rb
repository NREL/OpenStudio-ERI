######################################################################
#  Copyright (c) 2008-2014, Alliance for Sustainable Energy.
#  All rights reserved.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

require 'openstudio/workflow/adapters/output_adapter'

# Local file based workflow
module OpenStudio
  module Workflow
    module OutputAdapter
      class Local < OutputAdapters
        def initialize(options = {})
          raise 'The required :output_directory option was not passed to the local output adapter' unless options[:output_directory]
          super
        end

        # Write to the filesystem that the process has started
        #
        def communicate_started
          File.open("#{@options[:output_directory]}/started.job", 'w') { |f| f << "Started Workflow #{::Time.now}" }
        end

        # Write to the filesystem that the process has completed
        #
        def communicate_complete
          File.open("#{@options[:output_directory]}/finished.job", 'w') { |f| f << "Finished Workflow #{::Time.now}" }
        end

        # Write to the filesystem that the process has failed
        #
        def communicate_failure
          File.open("#{@options[:output_directory]}/failed.job", 'w') { |f| f << "Failed Workflow #{::Time.now}" }
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
            # DLM: don't we want this in the results zip?
            # DLM: deprecate in favor of out.osw
            File.open("#{@options[:output_directory]}/data_point_out.json", 'w') { |f| f << JSON.pretty_generate(results) }
          else
            #puts "Unknown datapoint result type. Please handle #{results.class}"
          end
        end
      end
    end
  end
end
