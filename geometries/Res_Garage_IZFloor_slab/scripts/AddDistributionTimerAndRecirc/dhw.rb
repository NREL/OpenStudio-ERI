
class FormulaCalculationError < StandardError #throw these to make the measure fail with an error
end

class ModelStateError < StandardError #throw these to make the measure fail with an error
end

################################################################################################################
# DHW Calculation Architecture
#
# Hot water draws are calculated in two parts, a daily usage component and a scheduling component:
#		<daily_usage> -> <draw_schedule>
# The daily usage component provides gpd values for each month of the year for each device type.
# The scheduling component is fed by the daily use and calculates a peak hourly value and a draw
# profile day for each month.
#
# Available Usage Classes:
#   UserDailyUsage: uses direct input from the user to calculate daily usage
#	StandardDailyUsage: uses number of bedrooms and site water temperature to estimate usage
#
# Available Scheduling Classes:
#   SimpleScheduleDraws: a simple profile that may vary monthly but not hourly
#   StandardScheduleDraws: a standard profile that varies both monthly and hourly
#
# An adjustment for distribution and recirculation may sit between the usage and schedule components:
#		<daily_usage> -> [<distribution_adjustments>] -> <draw_schedule>
# 
# The RecircDailyUsage class combines an existing usage component with a RecirculationFormulas to provide
# adjusted usage to a draw schedule
#
# Based on the choices using_distribution and using_standard_dhw_event_schedules some combination of the above
# classes are used to create openstudio schedules and object definitions
#
#################################################################################################################
module DHW
  FAUCETTYPES = [:showers,:sinks,:baths]
  DEVTYPES = [:clothes_washer,:dishwasher] + FAUCETTYPES
  DAYSINMONTH = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  
  #This supports provisioning tables by cut-n-paste from the spec into files
  #Format per line is hour (1..24) then parseable float numeral, separated by space.
  #Extra whitespace is ignored; extra text at the end of the line is okay.
  #Lines not meeting this format are ignored.
  def hoursHashFromTableText(t) 
    h = {}
    
    t
    .split(/\n/)                                    # lines
    .map{|x| x.match(/^\s*(\d+)\s+(\S+)(?:$|\s)/)}  # select first spaceless fields, rest of line ignored
    .select{|m| m.class==MatchData}                 # ignore non-matches
    .map{|m| h[m[1].to_i] = m[2].to_f }             # accumulate integer,float pairs
    
    h
  end
  
  #This supports organizing tables into resource files with names indicating what goes together.
  # ingestTableFiles(tableName,namedDevTypes)[devType][n] will map to a value specified in the 
  # files resources/TABLE.<tableName>.<name of devType>, 
  # but defaults to 0.0 whenever unspecified.
  def ingestTableFiles(tableName,namedDevTypes)
    filePathPrefix = "#{File.dirname(__FILE__)}/resources/TABLE.#{tableName}."
    fileSuffix = ".txt"
    h = Hash.new(Hash.new(0.0))  
    namedDevTypes
    .map{|devType,name| h[devType] = 
                        hoursHashFromTableText File.open("#{filePathPrefix}#{name}#{fileSuffix}").read
    }
    h
  end
 
 # Support calculating average gpd in daily usage classes
	def avg_annual_gpd(devType)
		unless @memo_avg_annual_gpd
			@memo_avg_annual_gpd = {}
			DEVTYPES.each do |dt|
				@memo_avg_annual_gpd[dt] = ((1..12).inject(0) {|sum, m| sum + daily_usage_gals(dt, m) * DAYSINMONTH[m]}) / 365.0
			end
		end
		return @memo_avg_annual_gpd[devType]
	end

end
