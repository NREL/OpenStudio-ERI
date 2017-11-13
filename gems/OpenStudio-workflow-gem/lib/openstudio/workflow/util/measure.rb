module OpenStudio
  module Workflow
    module Util

      # Handles all interaction with measure objects in the gem. This includes measure.xml and measure.rb files
      #
      module Measure

        # Wrapper method around #apply_measure to allow all measures of a type to be executed
        #
        # @param [String] measure_type Accepts OpenStudio::MeasureType argument
        # @param [Object] registry Hash access to objects
        # @param [Hash] options ({}) User-specified options used to override defaults
        # @option options [Object] :time_logger A special logger used to debug performance issues
        # @option options [Object] :output_adapter An output adapter to register measure transitions to
        # @param  [Boolean] energyplus_output_requests If true then the energyPlusOutputRequests is called instead of the run method
        # @return [Void] 
        #
        def apply_measures(measure_type, registry, options = {}, energyplus_output_requests = false)
        
          # DLM: time_logger is in the registry but docs say it is in options?
          registry[:time_logger].start "#{measure_type.valueName}:apply_measures" if registry[:time_logger]

          logger = registry[:logger]
          runner = registry[:runner]
          workflow_json = registry[:workflow_json]
          
          workflow_steps = workflow_json.workflowSteps
          fail "The 'steps' array of the OSW is required." unless workflow_steps
          
          logger.debug "Finding measures of type #{measure_type.valueName}"
          workflow_steps.each_index do |step_index|
            
            step = workflow_steps[step_index]

            if @registry[:openstudio_2]
              if !step.to_MeasureStep.empty?
                step = step.to_MeasureStep.get
              end
            end
            
            measure_dir_name = step.measureDirName
              
            measure_dir = workflow_json.findMeasure(measure_dir_name)
            fail "Cannot find #{measure_dir_name}" if measure_dir.empty?
            measure_dir = measure_dir.get
            
            measure = OpenStudio::BCLMeasure.load(measure_dir)
            fail "Cannot load measure at #{measure_dir}" if measure.empty?
            measure = measure.get
            
            class_name = measure.className
            measure_instance_type = measure.measureType
            if measure_instance_type == measure_type
              if energyplus_output_requests
                logger.info "Found measure #{class_name} of type #{measure_type.valueName}. Collecting EnergyPlus Output Requests now."
                apply_measure(registry, step, options, energyplus_output_requests)              
              else
                logger.info "Found measure #{class_name} of type #{measure_type.valueName}. Applying now."
                
                # check if simulation has been halted
                halted = runner.halted
                
                # fast forward current step index to this index, skips any previous steps
                # DLM: this is needed when running reporting measures only
                if !halted
                  while workflow_json.currentStepIndex < step_index
                    workflow_json.incrementStep 
                  end
                end

                # DLM: why is output_adapter in options instead of registry?
                options[:output_adapter].communicate_transition("Applying #{class_name}", :measure) if options[:output_adapter]
                apply_measure(registry, step, options, energyplus_output_requests, halted)
                options[:output_adapter].communicate_transition("Applied #{class_name}", :measure) if options[:output_adapter]
              end
              
              logger.info 'Moving to the next workflow step.'
            else
              logger.debug "Passing measure #{class_name} of type #{measure_type.valueName}"
            end
          end
          
          registry[:time_logger].stop "#{measure_type.valueName}:apply_measures" if registry[:time_logger]
        end

        # Determine if a given workflow can find and load all measures defined in steps
        #
        # @param [Hash] workflow See the schema for an OSW defined in the spec folder of this repo. Note that this
        #   method requires the OSW to have been loaded with symbolized keys
        # @param [String] directory The directory that will be passed to the find_measure_dir method
        # @return [true] If the method doesn't fail the workflow measures were validated
        #
        def validate_measures(registry, logger)
        
          logger = registry[:logger] if logger.nil?
          workflow_json = registry[:workflow_json]
          
          state = 'ModelMeasure'.to_MeasureType
          steps = workflow_json.workflowSteps
          steps.each_with_index do |step, index|
            begin
              logger.debug "Validating step #{index}"
              
              if @registry[:openstudio_2]
                if !step.to_MeasureStep.empty?
                  step = step.to_MeasureStep.get
                end
              end

              # Verify the existence of the required files
              measure_dir_name = step.measureDirName

              measure_dir = workflow_json.findMeasure(measure_dir_name)
              fail "Cannot find measure #{measure_dir_name}" if measure_dir.empty?
              measure_dir = measure_dir.get
              
              measure = OpenStudio::BCLMeasure.load(measure_dir)
              fail "Cannot load measure at #{measure_dir}" if measure.empty?
              measure = measure.get
              
              class_name = measure.className
              measure_instance_type = measure.measureType

              # Ensure that measures are in order, i.e. no OS after E+, E+ or OS after Reporting
              if measure_instance_type == 'ModelMeasure'.to_MeasureType
                fail "OpenStudio measure #{measure_dir} called after transition to EnergyPlus." if state == 'EnergyPlusMeasure'.to_MeasureType
                fail "OpenStudio measure #{measure_dir} called after after Energyplus simulation." if state == 'ReportingMeasure'.to_MeasureType
              elsif measure_instance_type == "EnergyPlusMeasure".to_MeasureType
                state = 'EnergyPlusMeasure'.to_MeasureType if state == 'ModelMeasure'.to_MeasureType
                fail "EnergyPlus measure #{measure_dir} called after Energyplus simulation." if state == 'ReportingMeasure'.to_MeasureType
              elsif measure_instance_type == 'ReportingMeasure'.to_MeasureType
                state = 'ReportingMeasure'.to_MeasureType if state != 'ReportingMeasure'.to_MeasureType
              else
                fail "Error: MeasureType #{measure_instance_type.valueName} of measure #{measure_dir} is not supported"
              end

              logger.debug "Validated step #{index}"
            end
          end
        end

        # Sets the argument map for argument_map argument pair
        #
        # @param [Object] argument_map See the OpenStudio SDK for a description of the OSArgumentMap structure
        # @param [Object] argument_name, user defined argument name
        # @param [Object] argument_value, user defined argument value
        # @param [Object] logger, logger object 
        # @return [Object] Returns an updated ArgumentMap object
        #
        def apply_arguments(argument_map, argument_name, argument_value, logger)
          unless argument_value.nil?
            logger.info "Setting argument value '#{argument_name}' to '#{argument_value}'"

            v = argument_map[argument_name.to_s]
            fail "Could not find argument '#{argument_name}' in argument_map" unless v
            value_set = v.setValue(argument_value)
            fail "Could not set argument '#{argument_name}' to value '#{argument_value}'" unless value_set
            argument_map[argument_name.to_s] = v.clone
          else
            logger.warn "Value for argument '#{argument_name}' not set in argument list therefore will use default"
          end
        end
        
        def apply_arguments_2(argument_map, argument_name, argument_value, logger)
          unless argument_value.nil?
            logger.info "Setting argument value '#{argument_name}' to '#{argument_value}'"

            v = argument_map[argument_name.to_s]
            fail "Could not find argument '#{argument_name}' in argument_map" unless v
            value_set = false
            variant_type = argument_value.variantType
            if variant_type == "String".to_VariantType
              argument_value = argument_value.valueAsString
              value_set = v.setValue(argument_value)
            elsif variant_type == "Double".to_VariantType
              argument_value = argument_value.valueAsDouble
              value_set = v.setValue(argument_value)
            elsif variant_type == "Integer".to_VariantType
              argument_value = argument_value.valueAsInteger
              value_set = v.setValue(argument_value)
            elsif variant_type == "Boolean".to_VariantType
              argument_value = argument_value.valueAsBoolean
              value_set = v.setValue(argument_value)
            end
            fail "Could not set argument '#{argument_name}' to value '#{argument_value}'" unless value_set
            argument_map[argument_name.to_s] = v.clone
          else
            logger.warn "Value for argument '#{argument_name}' not set in argument list therefore will use default"
          end
        end
        
        # Method to add measure info to WorkflowStepResult
        #
        # @param [Object] result Current WorkflowStepResult
        # @param [Object] measure Current BCLMeasure
        def add_result_measure_info(result, measure)
          begin
            result.setMeasureType(measure.measureType)
            result.setMeasureName(measure.name)
            result.setMeasureId(measure.uid)
            result.setMeasureVersionId(measure.versionId)
            version_modified = measure.versionModified
            if !version_modified.empty?
              result.setMeasureVersionModified(version_modified.get)
            end
            result.setMeasureXmlChecksum(measure.xmlChecksum)
            result.setMeasureClassName(measure.className)
            result.setMeasureDisplayName(measure.displayName)
            result.setMeasureTaxonomy(measure.taxonomyTag)
          rescue NameError
          end
        end
        
        # Method to allow for a single measure of any type to be run
        #
        # @param [String] directory Location of the datapoint directory to run. This is needed
        #   independent of the adapter that is being used. Note that the simulation will actually run in 'run'
        # @param [Object] adapter An instance of the adapter class
        # @param [String] current_weather_filepath The path which will be used to set the runner and returned to update
        #   the OSW for future measures and the simulation
        # @param [Object] model The model object being used in the measure, either a OSM or IDF
        # @param [Hash] step Definition of the to be run by the workflow
        # @option step [String] :measure_dir_name The name of the directory which contains the measure files
        # @option step [Object] :arguments name value hash which defines the arguments to the measure, e.g.
        #   {has_bool: true, cost: 3.1}
        # @param output_attributes [Hash] The results of previous measure applications which are persisted through the
        #   runner to allow measures to react to previous events in the workflow
        # @param [Hash] options ({}) User-specified options used to override defaults
        # @option options [Array] :measure_search_array Ordered set of measure directories used to search for
        #   step[:measure_dir_name], e.g. ['measures', '../../measures']
        # @option options [Object] :time_logger Special logger used to debug performance issues
        # @param  [Boolean] energyplus_output_requests If true then the energyPlusOutputRequests is called instead of the run method
        # @param  [Boolean] halted True if the workflow has been halted and all measures should be skipped
        # @return [Hash, String] Returns two objects. The first is the (potentially) updated output_attributes hash, and
        #   the second is the (potentially) updated current_weather_filepath
        #
        def apply_measure(registry, step, options = {}, energyplus_output_requests = false, halted = false)

          logger = registry[:logger]
          runner = registry[:runner]
          workflow_json = registry[:workflow_json]
          measure_dir_name = step.measureDirName
     
          run_dir = registry[:run_dir]
          fail 'No run directory set in the registry' unless run_dir
          
          output_attributes = registry[:output_attributes]
          
          # todo: get weather file from appropriate location 
          @wf = registry[:wf]
          @model = registry[:model]
          @model_idf = registry[:model_idf]
          @sql_filename = registry[:sql]
          
          runner.setLastOpenStudioModel(@model) if @model
          #runner.setLastOpenStudioModelPath(const openstudio::path& lastOpenStudioModelPath); #DLM - deprecate?
          runner.setLastEnergyPlusWorkspace(@model_idf) if @model_idf
          #runner.setLastEnergyPlusWorkspacePath(const openstudio::path& lastEnergyPlusWorkspacePath); #DLM - deprecate?
          runner.setLastEnergyPlusSqlFilePath(@sql_filename) if @sql_filename
          runner.setLastEpwFilePath(@wf) if @wf

          logger.debug "Starting #{__method__} for #{measure_dir_name}"
          registry[:time_logger].start("Measure:#{measure_dir_name}") if registry[:time_logger]
          current_dir = Dir.pwd

          success = nil
          begin
          
            measure_dir = workflow_json.findMeasure(measure_dir_name)
            fail "Cannot find #{measure_dir_name}" if measure_dir.empty?
            measure_dir = measure_dir.get
            
            measure = OpenStudio::BCLMeasure.load(measure_dir)
            fail "Cannot load measure at #{measure_dir}" if measure.empty?
            measure = measure.get
            
            step_index = workflow_json.currentStepIndex

            measure_run_dir = File.join(run_dir, "#{step_index.to_s.rjust(3,'0')}_#{measure_dir_name}")
            logger.debug "Creating run directory for measure in #{measure_run_dir}"
            FileUtils.mkdir_p measure_run_dir
            Dir.chdir measure_run_dir
            
            if energyplus_output_requests
              logger.debug "energyPlusOutputRequests running in #{Dir.pwd}"
            else
              logger.debug "Apply measure running in #{Dir.pwd}"
            end

            class_name = measure.className
            measure_type = measure.measureType
            
            measure_path = measure.primaryRubyScriptPath
            fail "Measure does not have a primary ruby script specified" if measure_path.empty?
            measure_path = measure_path.get
            fail "#{measure_path} file does not exist" unless File.exist?(measure_path.to_s)
            
            logger.debug "Loading Measure from #{measure_path}"

            measure_object = nil
            result = nil
            begin
              load measure_path.to_s
              measure_object = Object.const_get(class_name).new
            rescue => e
 
              # add the error to the osw.out
              runner.registerError("#{e.message}\n\t#{e.backtrace.join("\n\t")}")
              
              # @todo (rhorsey) Clean up the error class here.
              log_message = "Error requiring measure #{__FILE__}. Failed with #{e.message}, #{e.backtrace.join("\n")}"
              raise log_message
            end

            arguments = nil
            skip_measure = false
            begin

              # Initialize arguments which may be model dependent, don't allow arguments method access to real model in case it changes something
              if measure_type == 'ModelMeasure'.to_MeasureType
                arguments = measure_object.arguments(@model.clone(true).to_Model)
              elsif measure_type == 'EnergyPlusMeasure'.to_MeasureType
                arguments = measure_object.arguments(@model_idf.clone(true))
              else measure_type == 'ReportingMeasure'.to_MeasureType
                arguments = measure_object.arguments
              end

              # Create argument map and initialize all the arguments
              argument_map = OpenStudio::Ruleset::OSArgumentMap.new
              if arguments
                arguments.each do |v|
                  argument_map[v.name] = v.clone
                end
              end

              # Set argument values if they exist
              logger.debug "Iterating over arguments for workflow item '#{measure_dir_name}'"
              if step.arguments 
                step.arguments.each do |argument_name, argument_value|
                  if argument_name.to_s == '__SKIP__'
                    if registry[:openstudio_2]
                      variant_type = argument_value.variantType
                      if variant_type == "String".to_VariantType
                        argument_value = argument_value.valueAsString
                      elsif variant_type == "Double".to_VariantType
                        argument_value = argument_value.valueAsDouble
                      elsif variant_type == "Integer".to_VariantType
                        argument_value = argument_value.valueAsInteger
                      elsif variant_type == "Boolean".to_VariantType
                        argument_value = argument_value.valueAsBoolean
                      end
                    end
                    
                    if argument_value.class == String
                      argument_value = argument_value.downcase
                      if argument_value == "false"
                        skip_measure = false
                      else
                        skip_measure = true
                      end
                    elsif argument_value.class == Fixnum
                      skip_measure = (argument_value != 0)
                    elsif argument_value.class == Float
                      skip_measure = (argument_value != 0.0)
                    elsif argument_value.class == FalseClass
                      skip_measure = false
                    elsif argument_value.class == TrueClass
                      skip_measure = true
                    elsif argument_value.class == NilClass
                      skip_measure = false
                    end
                  else
                    # regular argument
                    if registry[:openstudio_2]
                      success = apply_arguments_2(argument_map, argument_name, argument_value, logger)
                    else
                      success = apply_arguments(argument_map, argument_name, argument_value, logger)
                    end
                    fail 'Could not set arguments' unless success
                  end
                end
              end

              # map any choice display names to choice values, in either set values or defaults
              argument_map.each_key do |argument_name|
                v = argument_map[argument_name]
                choice_values = v.choiceValues
                if !choice_values.empty?
                  value = nil
                  value = v.defaultValueAsString if v.hasDefaultValue
                  value = v.valueAsString if v.hasValue
                  if value && choice_values.index(value).nil?
                    display_names = v.choiceValueDisplayNames
                    i = display_names.index(value)
                    if i && choice_values[i]
                      logger.debug "Mapping display name '#{value}' to value '#{choice_values[i]}' for argument '#{argument_name}'"
                      value_set = v.setValue(choice_values[i])
                      fail "Could not set argument '#{argument_name}' to mapped value '#{choice_values[i]}'" unless value_set
                      argument_map[argument_name.to_s] = v.clone
                    end
                  end
                end
              end
              
            rescue => e

              # add the error to the osw.out
              runner.registerError("#{e.message}\n\t#{e.backtrace.join("\n\t")}")
                
              log_message = "Error assigning argument in measure #{__FILE__}. Failed with #{e.message}, #{e.backtrace.join("\n")}"
              raise log_message
            end

            if skip_measure || halted
              if !energyplus_output_requests
                if halted
                  # if halted then this measure will not get run, there are no results, not even "Skip"
                  logger.info "Skipping measure '#{measure_dir_name}' because simulation halted"
                  
                else
                  logger.info "Skipping measure '#{measure_dir_name}'"
                  
                  # required to update current step, will do nothing if halted
                  runner.prepareForUserScriptRun(measure_object)
                  
                  # don't want to log errors about arguments passed to skipped measures
                  #runner.validateUserArguments(arguments, argument_map
                
                  current_result = runner.result
                  runner.incrementStep
                  add_result_measure_info(current_result, measure)
                  current_result.setStepResult('Skip'.to_StepResult)
                end
              end
            else
            
              begin
                if energyplus_output_requests
                  logger.debug "Calling measure.energyPlusOutputRequests for '#{measure_dir_name}'"
                  idf_objects = measure_object.energyPlusOutputRequests(runner, argument_map)
                  num_added = 0
                  idf_objects.each do |idf_object|
                    num_added += OpenStudio::Workflow::Util::EnergyPlus.add_energyplus_output_request(@model_idf, idf_object)
                  end
                  logger.debug "Finished measure.energyPlusOutputRequests for '#{measure_dir_name}', #{num_added} output requests added"
                else
                  logger.debug "Calling measure.run for '#{measure_dir_name}'"
                  if measure_type == 'ModelMeasure'.to_MeasureType
                    measure_object.run(@model, runner, argument_map)
                  elsif measure_type == 'EnergyPlusMeasure'.to_MeasureType
                    measure_object.run(@model_idf, runner, argument_map)
                  elsif measure_type == 'ReportingMeasure'.to_MeasureType
                    measure_object.run(runner, argument_map)
                  end
                  logger.debug "Finished measure.run for '#{measure_dir_name}'"
                end

                # Run garbage collector after every measure to help address race conditions
                GC.start
              rescue => e

                # add the error to the osw.out
                runner.registerError("#{e.message}\n\t#{e.backtrace.join("\n\t")}")
                
                result = runner.result
                
                if !energyplus_output_requests
                  # incrementStep must be called after run
                  runner.incrementStep
                  
                  add_result_measure_info(result, measure)
                end
                
                options[:output_adapter].communicate_measure_result(result) if options[:output_adapter]
                
                log_message = "Runner error #{__FILE__} failed with #{e.message}, #{e.backtrace.join("\n")}"
                raise log_message
              end
              
              # if doing output requests we are done now
              if energyplus_output_requests
                registry.register(:model_idf) { @model_idf }
                return 
              end

              result = nil
              begin
                result = runner.result
                
                # incrementStep must be called after run
                runner.incrementStep
                
                add_result_measure_info(result, measure)
                
                options[:output_adapter].communicate_measure_result(result) if options[:output_adapter]

                errors = result.stepErrors
                
                fail "Measure #{measure_dir_name} reported an error with #{errors}" if errors.size != 0
                logger.debug "Running of measure '#{measure_dir_name}' completed. Post-processing measure output"
                
                # TODO: fix this
                #unless @wf == runner.weatherfile_path
                #  logger.debug "Updating the weather file to be '#{runner.weatherfile_path}'"
                #  registry.register(:wf) { runner.weatherfile_path }
                #end

                # @todo add note about why reassignment and not eval
                registry.register(:model) { @model }
                registry.register(:model_idf) { @model_idf }
                registry.register(:sql) { @sql_filename }
                
                if measure_type == 'ModelMeasure'.to_MeasureType
                  # check if weather file has changed
                  weather_file = @model.getOptionalWeatherFile
                  if !weather_file.empty?
                    weather_file_path = weather_file.get.path
                    if weather_file_path.empty?
                      logger.debug "Weather file object found in model but no path is given"
                    else
                      weather_file_path2 = workflow_json.findFile(weather_file_path.get)
                      if weather_file_path2.empty?
                        logger.warn "Could not find weather file '#{weather_file_path}' referenced in model"
                      else
                        if weather_file_path2.get.to_s != @wf
                          logger.debug "Updating weather file path to '#{weather_file_path2.get.to_s}'"
                          @wf = weather_file_path2.get.to_s
                          registry.register(:wf) { @wf }
                        end
                      end
                    end
                  end
                end

              rescue => e
                log_message = "Runner error #{__FILE__} failed with #{e.message}, #{e.backtrace.join("\n")}"
                raise log_message
              end

              # DLM: this section creates the measure_attributes.json file which should be deprecated
              begin
                measure_name = step.name.is_initialized ? step.name.get : class_name

                output_attributes[measure_name.to_sym] = {} if output_attributes[measure_name.to_sym].nil?
                
                result.stepValues.each do |step_value|
                  step_value_name = step_value.name
                  step_value_type = step_value.variantType
                
                  value = nil
                  if (step_value_type == "String".to_VariantType)
                    value = step_value.valueAsString
                  elsif (step_value_type == "Double".to_VariantType)
                    value = step_value.valueAsDouble
                  elsif (step_value_type == "Integer".to_VariantType)
                    value = step_value.valueAsInteger
                  elsif (step_value_type == "Boolean".to_VariantType)
                    value = step_value.valueAsBoolean
                  end
    
                  output_attributes[measure_name.to_sym][step_value_name] = value
                end
              
                # Add an applicability flag to all the measure results
                step_result = result.stepResult
                fail "Step Result not set" if step_result.empty?
                step_result = step_result.get
                
                if (step_result == "Skip".to_StepResult) || (step_result == "NA".to_StepResult)
                  output_attributes[measure_name.to_sym][:applicable] = false
                else
                  output_attributes[measure_name.to_sym][:applicable] = true
                end
                registry.register(:output_attributes) { output_attributes }
              rescue => e
                log_message = "#{__FILE__} failed with #{e.message}, #{e.backtrace.join("\n")}"
                logger.error log_message
                raise log_message
              end
              
            end
            
          rescue ScriptError, StandardError, NoMemoryError => e
            log_message = "#{__FILE__} failed with message #{e.message} in #{e.backtrace.join("\n")}"
            logger.error log_message
            raise log_message
          ensure
            Dir.chdir current_dir
            registry[:time_logger].stop("Measure:#{measure_dir_name}") if registry[:time_logger]

            logger.info "Finished #{__method__} for #{measure_dir_name} in #{@registry[:time_logger].delta("Measure:#{measure_dir_name}")} s" if registry[:time_logger]
          end
        end
      end
    end
  end
end
