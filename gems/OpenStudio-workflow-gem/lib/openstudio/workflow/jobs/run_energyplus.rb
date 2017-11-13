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

# This class runs the EnergyPlus simulation
class RunEnergyPlus < OpenStudio::Workflow::Job
  require 'openstudio/workflow/util/energyplus'
  include OpenStudio::Workflow::Util::EnergyPlus

  def initialize(input_adapter, output_adapter, registry, options = {})
    super
  end

  def perform
    @logger.debug "Calling #{__method__} in the #{self.class} class"
    
    # skip if halted
    halted = @registry[:runner].halted
    @logger.info 'Workflow halted, skipping the EnergyPlus simulation' if halted
    return nil if halted

    # Checks and configuration
    raise 'No run_dir specified in the registry' unless @registry[:run_dir]
    ep_path = @options[:energyplus_path] ? @options[:energyplus_path] : nil
    @logger.warn "Using EnergyPlus path specified in options #{ep_path}" if ep_path

    @logger.info 'Starting the EnergyPlus simulation'
    @registry[:time_logger].start('Running EnergyPlus') if @registry[:time_logger]
    call_energyplus(@registry[:run_dir], ep_path, @output_adapter, @logger, @registry[:workflow_json])
    @registry[:time_logger].stop('Running EnergyPlus') if @registry[:time_logger]
    @logger.info 'Completed the EnergyPlus simulation'

    sql_path = File.join(@registry[:run_dir], 'eplusout.sql')
    @registry.register(:sql) { sql_path } if File.exist? sql_path
    @logger.warn "Unable to find sql file at #{sql_path}" unless @registry[:sql]

    nil
  end
end
