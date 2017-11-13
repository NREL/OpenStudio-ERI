module OpenStudio
  module Workflow
    class Job
      def initialize(input_adapter, output_adapter, registry, options = {})
        @options = options
        @input_adapter = input_adapter
        @output_adapter = output_adapter
        @registry = registry
        @logger = @registry[:logger]
        @results = {}

        @logger.debug "#{self.class} passed the following options #{@options}"
        @logger.debug "#{self.class} passed the following registry #{@registry.to_hash}" if @options[:debug]
      end
    end

    def self.new_class(current_job, input_adapter, output_adapter, registry, options = {})
      new_job = Object.const_get(current_job).new(input_adapter, output_adapter, registry, options)
      return new_job
    end
  end
end
