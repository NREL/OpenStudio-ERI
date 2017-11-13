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

require_relative 'workflow_json'

# Extend OS Runner to persist measure information throughout the workflow
# Provide shims to support OpenStudio 2.X functionality in OpenStudio 1.X
class WorkflowRunner < OpenStudio::Ruleset::OSRunner
  def initialize(multi_logger, workflow_json, openstudio_2)
    @multi_logger = multi_logger
    @workflow_json = workflow_json
    @openstudio_2 = openstudio_2
    @datapoint = nil
    @analysis = nil
    @halted = false
    @use_os_halted = OpenStudio::Ruleset::OSRunner.method_defined?(:halted)
    
    begin
      # OpenStudio 2.X
      super(@workflow_json)
    rescue Exception => e
      # OpenStudio 1.X
      @workflow = workflow_json
      @units_preference = 'SI'
      @language_preference = 'EN'
      super()
    end
  end
  
  def timeString
    ::Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
  end
  
  def datapoint
    @datapoint
  end
  
  def setDatapoint(datapoint)
    @datapoint = datapoint
  end
  
  def analysis
    @analysis
  end
  
  def setAnalysis(analysis)
    @analysis = analysis
  end
  
  # Returns the workflow currently being run. New in OS 2.0.
  # WorkflowJSON workflow() const;
  def workflow
    if @openstudio_2
      super
    else
      @workflow
    end
  end

  # Returns preferred unit system, either 'IP' or 'SI'. New in OS 2.0. */
  # std::string unitsPreference() const;
  def unitsPreference
    if @openstudio_2
      super
    else
      @units_preference
    end
  end

  # Returns preferred language, e.g. 'en' or 'fr'. New in OS 2.0. */
  # std::string languagePreference() const;
  def languagePreference
    if @openstudio_2
      super
    else
      @language_preference
    end
  end

  # called right when each measure is run
  # only called in OpenStudio 1.X
  # virtual void prepareForUserScriptRun(const UserScript& userScript);
  def prepareForUserScriptRun(userScript)
    
    if @openstudio_2
      prepareForMeasureRun(userScript)
    else
      current_step = @workflow.currentStep

      unless current_step.empty?
        current_step.get.step[:result] = {}
        current_step.get.step[:result][:started_at] = timeString
      end

      # TODO: capture std out and err

      # TODO: get initial list of files

      super
    end
  end

  def result
    if @openstudio_2
      super
    else
      os_result = super

      current_step = @workflow.currentStep

      if current_step.empty?
        raise 'Cannot find current_step'
      end
      current_step = current_step.get

      if current_step.step[:result].nil?
        # skipped, prepareForUserScriptRun was not called
        current_step.step[:result] = {}
        current_step.step[:result][:started_at] = timeString
        current_step.step[:result][:step_result] = 'Skip'
      else
        current_step.step[:result][:step_result] = os_result.value.valueName
      end

      current_step.step[:result][:completed_at] = timeString

      # TODO: restore stdout and stderr

      # TODO: check for created files

      current_step.step[:result][:step_errors] = []
      os_result.errors.each do |error|
        current_step.step[:result][:step_errors] << error.logMessage
      end

      current_step.step[:result][:step_warnings] = []
      os_result.warnings.each do |warning|
        current_step.step[:result][:step_warnings] << warning.logMessage
      end

      current_step.step[:result][:step_info] = []
      os_result.info.each do |info|
        current_step.step[:result][:step_info] << info.logMessage
      end

      unless os_result.initialCondition.empty?
        current_step.step[:result][:initial_condition] = os_result.initialCondition.get.logMessage
        current_step.step[:result][:step_initial_condition] = os_result.initialCondition.get.logMessage
      end

      unless os_result.finalCondition.empty?
        current_step.step[:result][:final_condition] = os_result.finalCondition.get.logMessage
        current_step.step[:result][:step_final_condition] = os_result.finalCondition.get.logMessage
      end

      current_step.step[:result][:step_values] = []
      os_result.attributes.each do |attribute|
        result = nil
        if attribute.valueType == 'Boolean'.to_AttributeValueType
          result = { name: attribute.name, value: attribute.valueAsBoolean, type: 'Boolean' }
        elsif attribute.valueType == 'Double'.to_AttributeValueType
          result = { name: attribute.name, value: attribute.valueAsDouble, type: 'Double' }
        elsif attribute.valueType == 'Integer'.to_AttributeValueType
          result = { name: attribute.name, value: attribute.valueAsInteger, type: 'Integer' }
        elsif attribute.valueType == 'Unsigned'.to_AttributeValueType
          result = { name: attribute.name, value: attribute.valueAsUnsigned, type: 'Integer' }
        elsif attribute.valueType == 'String'.to_AttributeValueType
          result = { name: attribute.name, value: attribute.valueAsString, type: 'String' }
        end

        current_step.step[:result][:step_values] << result unless result.nil?
      end

      return WorkflowStepResult_Shim.new(current_step.step[:result])
    end
  end

  # incrementing step copies result to previous results
  # void incrementStep();
  def incrementStep
    if @openstudio_2
      super
    else
      # compute result
      current_result = result

      @workflow.incrementStep
    end
  end

  # Overload registerInfo
  def registerInfo(message)
    super
    @multi_logger.info message
  end

  # Overload registerInfo
  def registerWarning(message)
    super
    @multi_logger.warn message
  end

  # Overload registerError
  def registerError(message)
    super
    @multi_logger.error message
  end

  # Overload registerInitialCondition
  def registerInitialCondition(message)
    super
    @multi_logger.info message
  end

  # Overload registerFinalCondition
  def registerFinalCondition(message)
    super
    @multi_logger.info message
  end

  # Overload haltSimulation
  def haltWorkflow(completed_status)
    if @use_os_halted
      super
    else
      @halted = true
      @workflow_json.setCompletedStatus(completed_status)
    end
  end

  # Overload halted
  def halted
    return @halted unless @use_os_halted
    super
  end
end
