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

require 'openstudio/workflow_json'

# Local file based workflow
module OpenStudio
  module Workflow
    module InputAdapter
      class Local
        def initialize(osw_path = './workflow.osw')
          @osw_abs_path = File.absolute_path(osw_path, Dir.pwd)

          @workflow = nil
          if File.exist? @osw_abs_path
            @workflow = ::JSON.parse(File.read(@osw_abs_path), symbolize_names: true)
          end
                   
          @workflow_json = nil
          @run_options = nil
          if @workflow
            begin
              # Create a temporary WorkflowJSON, will not be same one used in registry during simulation
              @workflow_json = OpenStudio::WorkflowJSON.new(JSON.fast_generate(workflow))
              @workflow_json.setOswDir(osw_dir)
            rescue NameError => e
              @workflow_json = WorkflowJSON_Shim.new(workflow, osw_dir)
            end
            
            begin 
              @run_options = @workflow_json.runOptions
            rescue
            end
          end
        end

        # Get the OSW file from the local filesystem
        #
        def workflow
          raise "Could not read workflow from #{@osw_abs_path}" if @workflow.nil?
          @workflow
        end

        # Get the OSW path
        #
        def osw_path
          @osw_abs_path
        end

        # Get the OSW dir
        #
        def osw_dir
          File.dirname(@osw_abs_path)
        end

        # Get the run dir
        #
        def run_dir
          result = File.join(osw_dir, 'run')
          if @workflow_json
            begin
              result = @workflow_json.absoluteRunDir.to_s
            rescue
            end
          end
          result
        end
        
        def output_adapter(user_options, default, logger)
          
          # user option trumps all others
          return user_options[:output_adapter] if user_options[:output_adapter]
          
          # try to read from OSW
          if @run_options && !@run_options.empty?
            custom_adapter = @run_options.get.customOutputAdapter
            if !custom_adapter.empty?
              begin
                custom_file_name = custom_adapter.get.customFileName
                class_name = custom_adapter.get.className
                options = ::JSON.parse(custom_adapter.get.options, :symbolize_names => true)
                
                # merge with user options, user options will replace options loaded from OSW
                options.merge!(user_options)
                  
                # stick output_directory in options
                options[:output_directory] = run_dir
                
                p = @workflow_json.findFile(custom_file_name)
                if !p.empty?
                  load(p.get.to_s)
                  output_adapter = eval("#{class_name}.new(options)")
                  return output_adapter
                else
                  log_message = "Failed to load custom adapter file '#{custom_file_name}'"
                  logger.error log_message
                  raise log_message
                end
              rescue
                log_message = "Failed to load custom adapter '#{class_name}' from file '#{custom_file_name}'"
                logger.error log_message
                raise log_message
              end
            end
          end
        
          return default
        end
        
        def jobs(user_options, default, logger)
          
          # user option trumps all others
          return user_options[:jobs] if user_options[:jobs]

          # try to read from OSW
          begin
            #log_message = "Reading custom job states from OSW is not currently supported'"
            #logger.info log_message
          rescue
          end
        
          return default
        end
        
        def debug(user_options, default)
          
          # user option trumps all others
          return user_options[:debug] if user_options[:debug]
          
          # try to read from OSW
          if @run_options && !@run_options.empty?
            return @run_options.get.debug
          end
        
          return default
        end
        
        def preserve_run_dir(user_options, default)
          
          # user option trumps all others
          return user_options[:preserve_run_dir] if user_options[:preserve_run_dir]
          
          # try to read from OSW
          if @run_options && !@run_options.empty?
            return @run_options.get.preserveRunDir
          end
        
          return default
        end
        
        def cleanup(user_options, default)
          
          # user option trumps all others
          return user_options[:cleanup] if user_options[:cleanup]
          
          # try to read from OSW
          if @run_options && !@run_options.empty?
            return @run_options.get.cleanup
          end
        
          return default
        end
        
        def energyplus_path(user_options, default)
          
          # user option trumps all others
          return user_options[:energyplus_path] if user_options[:energyplus_path]
        
          return default
        end
        
        def profile(user_options, default)
          
          # user option trumps all others
          return user_options[:profile] if user_options[:profile]
        
          return default
        end   
        
        def verify_osw(user_options, default)
          
          # user option trumps all others
          return user_options[:verify_osw] if user_options[:verify_osw]
        
          return default
        end   
        
        def weather_file(user_options, default)
          
          # user option trumps all others
          return user_options[:weather_file] if user_options[:weather_file]
          
          # try to read from OSW
          if !@workflow_json.weatherFile.empty?
            return @workflow_json.weatherFile.get.to_s
          end
        
          return default
        end
        
        # Get the associated OSD (datapoint) file from the local filesystem
        #
        def datapoint
          # DLM: should this come from the OSW?  the osd id and checksum are specified there.
          osd_abs_path = File.join(osw_dir, 'datapoint.osd')
          result = nil
          if File.exist? osd_abs_path
            result = ::JSON.parse(File.read(osd_abs_path), symbolize_names: true)
          end
          return result
        end

        # Get the associated OSA (analysis) definition from the local filesystem
        #
        def analysis
          # DLM: should this come from the OSW?  the osd id and checksum are specified there.
          osa_abs_path = File.join(osw_dir, '../analysis.json')
          result = nil
          if File.exist? osa_abs_path
            result = ::JSON.parse(File.read(osa_abs_path), symbolize_names: true)
          end
          return result
        end
        
      end
    end
  end
end
