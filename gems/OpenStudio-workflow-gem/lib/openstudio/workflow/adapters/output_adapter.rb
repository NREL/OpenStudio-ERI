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

module OpenStudio
  module Workflow
    # Base class for all output adapters. These methods define the expected return behavior of the adapter instance
    class OutputAdapters
      attr_accessor :options

      def initialize(options = {})
        @options = options
      end

      def communicate_started
        instance.communicate_started
      end

      def communicate_transition(message, type, options = {})
        instance.communicate_transition message, type, options
      end

      def communicate_energyplus_stdout(line, options = {})
        instance.communicate_energyplus_stdout line, options
      end

      def communicate_measure_result(result, options = {})
        instance.communicate_measure_result result, options
      end
      
      def communicate_measure_attributes(measure_attributes, options = {})
        instance.communicate_measure_attributes measure_attributes, options
      end

      def communicate_objective_function(objectives, options = {})
        instance.communicate_objective_function objectives, options
      end

      def communicate_results(directory, results)
        instance.communicate_results directory, results
      end

      def communicate_complete
        instance.communicate_complete
      end

      def communicate_failure
        instance.communicate_failure
      end

      protected

      # Zip up a folder and it's contents
      def zip_directory(directory, zip_filename, pattern = '*')
        # Submethod for adding the directory to the zip folder.
        def add_directory_to_zip(zip_file, local_directory, root_directory)
          Dir[File.join(local_directory.to_s, '**', '**')].each do |file|
            # remove the base directory from the zip file
            rel_dir = local_directory.sub("#{root_directory}/", '')
            zip_file_to_add = file.gsub(local_directory.to_s, rel_dir.to_s)
            if File.directory?(file)
              zip_file.addDirectory(file, zip_file_to_add)
            else
              zip_file.addFile(file, zip_file_to_add)
            end
          end

          zip_file
        end

        FileUtils.rm_f(zip_filename) if File.exist?(zip_filename)

        zf = OpenStudio::ZipFile.new(zip_filename, false)

        Dir[File.join(directory, pattern)].each do |file|
          if File.directory?(file)
            # skip a few directory that should not be zipped as they are inputs
            if File.basename(file) =~ /seed|measures|weather/
              next
            end
            # skip x-large directory
            if File.size?(file)
              next if File.size?(file) >= 15000000
            end
            add_directory_to_zip(zf, file, directory)
          else
            next if File.extname(file) =~ /\.rb.*/
            next if File.extname(file) =~ /\.zip.*/
            # skip large non-osm/idf files
            if File.size(file)
              if File.size(file) >= 100000000
                next unless File.extname(file) == '.osm' || File.extname(file) == '.idf'
              end
            end

            zip_file_to_add = file.gsub("#{directory}/", '')
            zf.addFile(file, zip_file_to_add)
          end
        end

        zf = nil
        GC.start
        
        File.chmod(0o664, zip_filename)
      end

      # Main method to zip up the results of the simulation results. This will append the UUID of the data point
      # if it exists. This method will create two zip files. One for the reports and one for the entire data point. The
      # Data Point ZIP will also contain the reports.
      #
      # @param directory [String] The data point directory to zip up.
      # @return nil
      #
      def zip_results(directory)
        # create zip file using a system call
        if Dir.exist?(directory) && File.directory?(directory)
          zip_filename = @datapoint ? "data_point_#{@datapoint.uuid}.zip" : 'data_point.zip'
          zip_filename = File.join(directory, zip_filename)
          zip_directory directory, zip_filename
        end

        # zip up only the reports folder
        report_dir = File.join(directory, 'reports')
        if Dir.exist?(report_dir) && File.directory?(report_dir)
          zip_filename = @datapoint ? "data_point_#{@datapoint.uuid}_reports.zip" : 'data_point_reports.zip'
          zip_filename = File.join(directory, zip_filename)
          zip_directory directory, zip_filename, 'reports'
        end
      end
    end
  end
end
