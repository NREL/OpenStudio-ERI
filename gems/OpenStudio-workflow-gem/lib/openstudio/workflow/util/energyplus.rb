module OpenStudio
  module Workflow
    module Util
      # The methods needed to run simulations using EnergyPlus are stored here. See the run_simulation class for
      #   implementation details.
      module EnergyPlus
        require 'openstudio/workflow/util/io'
        include OpenStudio::Workflow::Util::IO
        ENERGYPLUS_REGEX = /^energyplus\D{0,4}$/i
        EXPAND_OBJECTS_REGEX = /^expandobjects\D{0,4}$/i

        # Find the installation directory of EnergyPlus linked to the OpenStudio version being used
        #
        # @return [String] Returns the path to EnergyPlus
        #
        def find_energyplus
          path = OpenStudio.getEnergyPlusDirectory.to_s
          raise 'Unable to find the EnergyPlus executable' unless File.exist? path
          path
        end

        # Does something
        #
        # @param [String] run_directory Directory to run the EnergyPlus simulation in
        # @param [Array] energyplus_files Array of files containing the EnergyPlus and ExpandObjects EXEs
        # @return [Void]
        #
        def clean_directory(run_directory, energyplus_files, logger)
          logger.info 'Removing any copied EnergyPlus files'
          energyplus_files.each do |file|
            if File.exist? file
              FileUtils.rm_f file
            end
          end

          paths_to_rm = []
          paths_to_rm << "#{run_directory}/packaged_measures"
          paths_to_rm << "#{run_directory}/Energy+.ini"
          paths_to_rm.each { |p| FileUtils.rm_rf(p) if File.exist?(p) }
        end

        # Prepare the directory to run EnergyPlus
        #
        # @param [String] run_directory Directory to copy the required EnergyPlus files to
        # @param [Object] logger Logger object
        # @param [String] energyplus_path Path to the EnergyPlus EXE
        # @return [Array, file, file] Returns an array of strings of EnergyPlus files copied to the run_directory, the
        # ExpandObjects EXE file, and EnergyPlus EXE file
        #
        def prepare_energyplus_dir(run_directory, logger, energyplus_path = nil)
          logger.info "Copying EnergyPlus files to run directory: #{run_directory}"
          energyplus_path ||= find_energyplus
          logger.info "EnergyPlus path is #{energyplus_path}"
          energyplus_files = []
          energyplus_exe, expand_objects_exe = nil
          Dir["#{energyplus_path}/*"].each do |file|
            next if File.directory? file
            
            # copy idd and ini files
            if File.extname(file).downcase =~ /.idd|.ini/
              dest_file = "#{run_directory}/#{File.basename(file)}"
              energyplus_files << dest_file
              FileUtils.copy file, dest_file
            end

            energyplus_exe = file if File.basename(file) =~ ENERGYPLUS_REGEX
            expand_objects_exe = file if File.basename(file) =~ EXPAND_OBJECTS_REGEX
            
          end

          raise "Could not find EnergyPlus executable in #{energyplus_path}" unless energyplus_exe
          raise "Could not find ExpandObjects executable in #{energyplus_path}" unless expand_objects_exe

          logger.info "EnergyPlus executable path is #{energyplus_exe}"
          logger.info "ExpandObjects executable path is #{expand_objects_exe}"

          return energyplus_files, energyplus_exe, expand_objects_exe
        end

        # Configures and executes the EnergyPlus simulation and checks to see if the simulation was successful
        #
        # @param [String] run_directory Directory to execute the EnergyPlus simulation in. It is assumed that this
        #   directory already has the IDF and weather file in it
        # @param [String] energyplus_path (nil) Optional path to override the default path associated with the
        #   OpenStudio package being used
        # @param [Object] output_adapter (nil) Optional output adapter to update
        # @param [Object] logger (nil) Optional logger, will log to STDOUT if none provided
        # @return [Void]
        #
        def call_energyplus(run_directory, energyplus_path = nil, output_adapter = nil, logger = nil, workflow_json = nil)
          logger ||= ::Logger.new(STDOUT) unless logger
          
          current_dir = Dir.pwd
          energyplus_path ||= find_energyplus
          logger.info "EnergyPlus path is #{energyplus_path}"
          energyplus_files, energyplus_exe, expand_objects_exe = prepare_energyplus_dir(run_directory, logger, energyplus_path)
          Dir.chdir(run_directory)
          logger.info "Starting simulation in run directory: #{Dir.pwd}"

          #command = popen_command("\"#{expand_objects_exe}\"")
          #logger.info "Running command '#{command}'"
          #File.open('stdout-expandobject', 'w') do |file|
          #  ::IO.popen(command) do |io|
          #    while (line = io.gets)
          #      file << line
          #    end
          #  end
          #end
          #
          ## Check if expand objects did anything
          #if File.exist? 'expanded.idf'
          #  FileUtils.mv('in.idf', 'pre-expand.idf', force: true) if File.exist?('in.idf')
          #  FileUtils.mv('expanded.idf', 'in.idf', force: true)
          #end

          # create stdout
          command = popen_command("\"#{energyplus_exe}\" 2>&1")
          logger.info "Running command '#{command}'"
          File.open('stdout-energyplus', 'w') do |file|
            ::IO.popen(command) do |io|
              while (line = io.gets)
                file << line
                output_adapter.communicate_energyplus_stdout(line) if output_adapter
              end
            end
          end
          r = $?

          logger.info "EnergyPlus returned '#{r}'"
          unless r.to_i.zero?
            logger.warn 'EnergyPlus returned a non-zero exit code. Check the stdout-energyplus log.'
          end

          if File.exist? 'eplusout.err'
            eplus_err = File.read('eplusout.err').force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
            
            if workflow_json
              begin
                workflow_json.setEplusoutErr(eplus_err)
              rescue => e
                # older versions of OpenStudio did not have the setEplusoutErr method
              end
            end
            
            if eplus_err =~ /EnergyPlus Terminated--Fatal Error Detected/
              raise 'EnergyPlus Terminated with a Fatal Error. Check eplusout.err log.'
            end
          end
          
          if File.exist? 'eplusout.end'
            f = File.read('eplusout.end').force_encoding('ISO-8859-1').encode('utf-8', replace: nil)
            warnings_count = f[/(\d*).Warning/, 1]
            error_count = f[/(\d*).Severe.Errors/, 1]
            logger.info "EnergyPlus finished with #{warnings_count} warnings and #{error_count} severe errors"
            if f =~ /EnergyPlus Terminated--Fatal Error Detected/
              raise 'EnergyPlus Terminated with a Fatal Error. Check eplusout.err log.'
            end
          else
            raise 'EnergyPlus failed and did not create an eplusout.end file. Check the stdout-energyplus log.'
          end
          
        rescue => e
          log_message = "#{__FILE__} failed with #{e.message}, #{e.backtrace.join("\n")}"
          logger.error log_message
          raise log_message
        ensure
          logger.info "Ensuring 'clean' directory"
          clean_directory(run_directory, energyplus_files, logger)

          Dir.chdir(current_dir)
          logger.info 'EnergyPlus Completed'
        end

        # Run this code before running EnergyPlus to make sure the reporting variables are setup correctly
        #
        # @param [Object] idf The IDF Workspace to be simulated
        # @return [Void]
        #
        def energyplus_preprocess(idf, logger)
          logger.info 'Running EnergyPlus Preprocess'

          new_objects = []

          needs_sqlobj = idf.getObjectsByType('Output:SQLite'.to_IddObjectType).empty?

          if needs_sqlobj
            # just add this, we don't allow this type in add_energyplus_output_request
            logger.info 'Adding SQL Output to IDF'
            object = OpenStudio::IdfObject.load('Output:SQLite,SimpleAndTabular;').get
            idf.addObjects(object)
          end

          # merge in monthly reports
          EnergyPlus.monthly_report_idf_text.split(/^[\s]*$/).each do |object|
            object = object.strip
            next if object.empty?

            new_objects << object
          end

          # These are needed for the calibration report
          new_objects << 'Output:Meter:MeterFileOnly,Gas:Facility,Daily;'
          new_objects << 'Output:Meter:MeterFileOnly,Electricity:Facility,Timestep;'
          new_objects << 'Output:Meter:MeterFileOnly,Electricity:Facility,Daily;'

          # Always add in the timestep facility meters
          new_objects << 'Output:Meter,Electricity:Facility,Timestep;'
          new_objects << 'Output:Meter,Gas:Facility,Timestep;'
          new_objects << 'Output:Meter,DistrictCooling:Facility,Timestep;'
          new_objects << 'Output:Meter,DistrictHeating:Facility,Timestep;'

          new_objects.each do |obj|
            object = OpenStudio::IdfObject.load(obj).get
            OpenStudio::Workflow::Util::EnergyPlus.add_energyplus_output_request(idf, object)
          end

          # this is a workaround for issue #1699 -- remove when 1699 is closed.
          needs_hourly = true
          needs_timestep = true
          needs_daily = true
          needs_monthy = true
          idf.getObjectsByType('Output:Variable'.to_IddObjectType).each do |object|
            timestep = object.getString(2, true).get
            if /Hourly/i =~ timestep
              needs_hourly = false
            elsif /Timestep/i =~ timestep
              needs_timestep = false
            elsif /Daily/i =~ timestep
              needs_daily = false
            elsif /Monthly/i =~ timestep
              needs_monthy = false
            end
          end

          new_objects = []
          new_objects << 'Output:Variable,*,Zone Air Temperature,Hourly;' if needs_hourly
          new_objects << 'Output:Variable,*,Site Outdoor Air Wetbulb Temperature,Timestep;' if needs_timestep
          new_objects << 'Output:Variable,*,Zone Air Relative Humidity,Daily;' if needs_daily
          new_objects << 'Output:Variable,*,Site Outdoor Air Drybulb Temperature,Monthly;' if needs_monthy

          new_objects.each do |obj|
            object = OpenStudio::IdfObject.load(obj).get
            OpenStudio::Workflow::Util::EnergyPlus.add_energyplus_output_request(idf, object)
          end

          logger.info 'Finished EnergyPlus Preprocess'
        end

        # examines object and determines whether or not to add it to the workspace
        def self.add_energyplus_output_request(workspace, idf_object)
          num_added = 0
          idd_object = idf_object.iddObject

          allowed_objects = []
          allowed_objects << 'Output:Surfaces:List'
          allowed_objects << 'Output:Surfaces:Drawing'
          allowed_objects << 'Output:Schedules'
          allowed_objects << 'Output:Constructions'
          allowed_objects << 'Output:Table:TimeBins'
          allowed_objects << 'Output:Table:Monthly'
          allowed_objects << 'Output:Variable'
          allowed_objects << 'Output:Meter'
          allowed_objects << 'Output:Meter:MeterFileOnly'
          allowed_objects << 'Output:Meter:Cumulative'
          allowed_objects << 'Output:Meter:Cumulative:MeterFileOnly'
          allowed_objects << 'Meter:Custom'
          allowed_objects << 'Meter:CustomDecrement'

          if allowed_objects.include?(idd_object.name)
            unless check_for_object(workspace, idf_object, idd_object.type)
              workspace.addObject(idf_object)
              num_added += 1
            end
          end

          allowed_unique_objects = []
          # allowed_unique_objects << "Output:EnergyManagementSystem" # TODO: have to merge
          # allowed_unique_objects << "OutputControl:SurfaceColorScheme" # TODO: have to merge
          allowed_unique_objects << 'Output:Table:SummaryReports' # TODO: have to merge
          # OutputControl:Table:Style # not allowed
          # OutputControl:ReportingTolerances # not allowed
          # Output:SQLite # not allowed

          if allowed_unique_objects.include?(idf_object.iddObject.name)
            if idf_object.iddObject.name == 'Output:Table:SummaryReports'
              summary_reports = workspace.getObjectsByType(idf_object.iddObject.type)
              if summary_reports.empty?
                workspace.addObject(idf_object)
                num_added += 1
              else
                merge_output_table_summary_reports(summary_reports[0], idf_object)
              end
            end
          end

          return num_added
        end

        # check to see if we have an exact match for this object already
        def self.check_for_object(workspace, idf_object, idd_object_type)
          workspace.getObjectsByType(idd_object_type).each do |object|
            # all of these objects fields are data fields
            if idf_object.dataFieldsEqual(object)
              return true
            end
          end
          return false
        end

        # merge all summary reports that are not in the current workspace
        def self.merge_output_table_summary_reports(current_object, new_object)
          current_fields = []
          current_object.extensibleGroups.each do |current_extensible_group|
            current_fields << current_extensible_group.getString(0).to_s
          end

          fields_to_add = []
          new_object.extensibleGroups.each do |new_extensible_group|
            field = new_extensible_group.getString(0).to_s
            unless current_fields.include?(field)
              current_fields << field
              fields_to_add << field
            end
          end

          unless fields_to_add.empty?
            fields_to_add.each do |field|
              values = OpenStudio::StringVector.new
              values << field
              current_object.pushExtensibleGroup(values)
            end
            return true
          end

          return false
        end

        def self.monthly_report_idf_text
          <<-HEREDOC
Output:Table:Monthly,
  Building Energy Performance - Electricity,  !- Name
    2,                       !- Digits After Decimal
    InteriorLights:Electricity,  !- Variable or Meter 1 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 1
    ExteriorLights:Electricity,  !- Variable or Meter 2 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 2
    InteriorEquipment:Electricity,  !- Variable or Meter 3 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 3
    ExteriorEquipment:Electricity,  !- Variable or Meter 4 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 4
    Fans:Electricity,        !- Variable or Meter 5 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 5
    Pumps:Electricity,       !- Variable or Meter 6 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 6
    Heating:Electricity,     !- Variable or Meter 7 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 7
    Cooling:Electricity,     !- Variable or Meter 8 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 8
    HeatRejection:Electricity,  !- Variable or Meter 9 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 9
    Humidifier:Electricity,  !- Variable or Meter 10 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 10
    HeatRecovery:Electricity,!- Variable or Meter 11 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 11
    WaterSystems:Electricity,!- Variable or Meter 12 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 12
    Cogeneration:Electricity,!- Variable or Meter 13 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 13
    Refrigeration:Electricity,!- Variable or Meter 14 Name
    SumOrAverage;            !- Aggregation Type for Variable or Meter 14

Output:Table:Monthly,
  Building Energy Performance - Natural Gas,  !- Name
    2,                       !- Digits After Decimal
    InteriorEquipment:Gas,   !- Variable or Meter 1 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 1
    ExteriorEquipment:Gas,   !- Variable or Meter 2 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 2
    Heating:Gas,             !- Variable or Meter 3 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 3
    Cooling:Gas,             !- Variable or Meter 4 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 4
    WaterSystems:Gas,        !- Variable or Meter 5 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 5
    Cogeneration:Gas,        !- Variable or Meter 6 Name
    SumOrAverage;            !- Aggregation Type for Variable or Meter 6

Output:Table:Monthly,
  Building Energy Performance - District Heating,  !- Name
    2,                       !- Digits After Decimal
    InteriorLights:DistrictHeating,  !- Variable or Meter 1 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 1
    ExteriorLights:DistrictHeating,  !- Variable or Meter 2 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 2
    InteriorEquipment:DistrictHeating,  !- Variable or Meter 3 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 3
    ExteriorEquipment:DistrictHeating,  !- Variable or Meter 4 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 4
    Fans:DistrictHeating,        !- Variable or Meter 5 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 5
    Pumps:DistrictHeating,       !- Variable or Meter 6 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 6
    Heating:DistrictHeating,     !- Variable or Meter 7 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 7
    Cooling:DistrictHeating,     !- Variable or Meter 8 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 8
    HeatRejection:DistrictHeating,  !- Variable or Meter 9 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 9
    Humidifier:DistrictHeating,  !- Variable or Meter 10 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 10
    HeatRecovery:DistrictHeating,!- Variable or Meter 11 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 11
    WaterSystems:DistrictHeating,!- Variable or Meter 12 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 12
    Cogeneration:DistrictHeating,!- Variable or Meter 13 Name
    SumOrAverage;            !- Aggregation Type for Variable or Meter 13

Output:Table:Monthly,
  Building Energy Performance - District Cooling,  !- Name
    2,                       !- Digits After Decimal
    InteriorLights:DistrictCooling,  !- Variable or Meter 1 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 1
    ExteriorLights:DistrictCooling,  !- Variable or Meter 2 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 2
    InteriorEquipment:DistrictCooling,  !- Variable or Meter 3 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 3
    ExteriorEquipment:DistrictCooling,  !- Variable or Meter 4 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 4
    Fans:DistrictCooling,        !- Variable or Meter 5 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 5
    Pumps:DistrictCooling,       !- Variable or Meter 6 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 6
    Heating:DistrictCooling,     !- Variable or Meter 7 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 7
    Cooling:DistrictCooling,     !- Variable or Meter 8 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 8
    HeatRejection:DistrictCooling,  !- Variable or Meter 9 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 9
    Humidifier:DistrictCooling,  !- Variable or Meter 10 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 10
    HeatRecovery:DistrictCooling,!- Variable or Meter 11 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 11
    WaterSystems:DistrictCooling,!- Variable or Meter 12 Name
    SumOrAverage,            !- Aggregation Type for Variable or Meter 12
    Cogeneration:DistrictCooling,!- Variable or Meter 13 Name
    SumOrAverage;            !- Aggregation Type for Variable or Meter 13

Output:Table:Monthly,
  Building Energy Performance - Electricity Peak Demand,  !- Name
    2,                       !- Digits After Decimal
    Electricity:Facility,  !- Variable or Meter 1 Name
    Maximum,            !- Aggregation Type for Variable or Meter 1
    InteriorLights:Electricity,  !- Variable or Meter 1 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 1
    ExteriorLights:Electricity,  !- Variable or Meter 2 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 2
    InteriorEquipment:Electricity,  !- Variable or Meter 3 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 3
    ExteriorEquipment:Electricity,  !- Variable or Meter 4 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 4
    Fans:Electricity,        !- Variable or Meter 5 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 5
    Pumps:Electricity,       !- Variable or Meter 6 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 6
    Heating:Electricity,     !- Variable or Meter 7 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 7
    Cooling:Electricity,     !- Variable or Meter 8 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 8
    HeatRejection:Electricity,  !- Variable or Meter 9 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 9
    Humidifier:Electricity,  !- Variable or Meter 10 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 10
    HeatRecovery:Electricity,!- Variable or Meter 11 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 11
    WaterSystems:Electricity,!- Variable or Meter 12 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 12
    Cogeneration:Electricity,!- Variable or Meter 13 Name
    ValueWhenMaximumOrMinimum;            !- Aggregation Type for Variable or Meter 13

Output:Table:Monthly,
  Building Energy Performance - Natural Gas Peak Demand,  !- Name
    2,                       !- Digits After Decimal
    Gas:Facility,  !- Variable or Meter 1 Name
    Maximum,            !- Aggregation Type for Variable or Meter 1
    InteriorEquipment:Gas,   !- Variable or Meter 1 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 1
    ExteriorEquipment:Gas,   !- Variable or Meter 2 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 2
    Heating:Gas,             !- Variable or Meter 3 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 3
    Cooling:Gas,             !- Variable or Meter 4 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 4
    WaterSystems:Gas,        !- Variable or Meter 5 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 5
    Cogeneration:Gas,        !- Variable or Meter 6 Name
    ValueWhenMaximumOrMinimum;            !- Aggregation Type for Variable or Meter 6

Output:Table:Monthly,
  Building Energy Performance - District Heating Peak Demand,  !- Name
    2,                       !- Digits After Decimal
    DistrictHeating:Facility,  !- Variable or Meter 1 Name
    Maximum,            !- Aggregation Type for Variable or Meter 1
    InteriorLights:DistrictHeating,  !- Variable or Meter 1 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 1
    ExteriorLights:DistrictHeating,  !- Variable or Meter 2 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 2
    InteriorEquipment:DistrictHeating,  !- Variable or Meter 3 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 3
    ExteriorEquipment:DistrictHeating,  !- Variable or Meter 4 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 4
    Fans:DistrictHeating,        !- Variable or Meter 5 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 5
    Pumps:DistrictHeating,       !- Variable or Meter 6 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 6
    Heating:DistrictHeating,     !- Variable or Meter 7 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 7
    Cooling:DistrictHeating,     !- Variable or Meter 8 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 8
    HeatRejection:DistrictHeating,  !- Variable or Meter 9 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 9
    Humidifier:DistrictHeating,  !- Variable or Meter 10 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 10
    HeatRecovery:DistrictHeating,!- Variable or Meter 11 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 11
    WaterSystems:DistrictHeating,!- Variable or Meter 12 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 12
    Cogeneration:DistrictHeating,!- Variable or Meter 13 Name
    ValueWhenMaximumOrMinimum;            !- Aggregation Type for Variable or Meter 13

Output:Table:Monthly,
  Building Energy Performance - District Cooling Peak Demand,  !- Name
    2,                       !- Digits After Decimal
    DistrictCooling:Facility,  !- Variable or Meter 1 Name
    Maximum,            !- Aggregation Type for Variable or Meter 1
    InteriorLights:DistrictCooling,  !- Variable or Meter 1 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 1
    ExteriorLights:DistrictCooling,  !- Variable or Meter 2 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 2
    InteriorEquipment:DistrictCooling,  !- Variable or Meter 3 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 3
    ExteriorEquipment:DistrictCooling,  !- Variable or Meter 4 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 4
    Fans:DistrictCooling,        !- Variable or Meter 5 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 5
    Pumps:DistrictCooling,       !- Variable or Meter 6 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 6
    Heating:DistrictCooling,     !- Variable or Meter 7 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 7
    Cooling:DistrictCooling,     !- Variable or Meter 8 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 8
    HeatRejection:DistrictCooling,  !- Variable or Meter 9 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 9
    Humidifier:DistrictCooling,  !- Variable or Meter 10 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 10
    HeatRecovery:DistrictCooling,!- Variable or Meter 11 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 11
    WaterSystems:DistrictCooling,!- Variable or Meter 12 Name
    ValueWhenMaximumOrMinimum,            !- Aggregation Type for Variable or Meter 12
    Cogeneration:DistrictCooling,!- Variable or Meter 13 Name
    ValueWhenMaximumOrMinimum;            !- Aggregation Type for Variable or Meter 13
 HEREDOC
        end
      end
    end
  end
end
