
require "#{File.dirname(__FILE__)}/dhw"

class SimpleScheduleDraws
	
	def initialize(daily_usage)
		@daily_usage = daily_usage
	end
	
	def peak_gph(devType)
		unless @memo_peak_gph
			@memo_peak_gph = {}
			DHW::DEVTYPES.each do |dt|
				@memo_peak_gph[dt] = ((1..12).map { |m| @daily_usage.daily_usage_gals(dt, m) }.max) / 24.0
			end
		end
		return @memo_peak_gph[devType]
	end
	
	def draw_profile(devType, month, hour)
		@daily_usage.daily_usage_gals(devType, month) / 24.0 / peak_gph(devType)
	end
end

class StandardScheduleDraws
  include DHW
  
  def initialize(daily_usage)
	@daily_usage = daily_usage
  end
  
  # the Max(month,hour)(hourly_usage_gals(devType,month,hour))
  #Memoizing to avoid recalculations
  def peak_gph(devType) 
    return @memo_peak_gph[devType] if defined? @memo_peak_gph
    
    h = {}
    flowPortionByHour.keys.each{|dt| 
        h[dt] = 
        flowPortionByHour[dt].values.max  * (1..12).map{|m| daily_usage_gals(dt, m)}.max
        # we exploit that: Max[y,z](f(y)*g(z)) = Max[y](f(y)) * Max[z](g(z)) if f(y) >= 0 and g(z) >= 0
    } 
    (@memo_peak_gph = h)[devType]
  end
  
  def draw_profile(devType,month,hour) # unitless ratio
    raise FormulaCalculationError.new("Draw profile requires non-zero peak flow") if peak_gph(devType) == 0
    
    hourly_usage_gals(devType,month,hour) / peak_gph(devType)
  end
  
  
  # Internal Methods
  
  def hourly_usage_gals(devType,month,hour)
    flowPortionByHour[devType][hour] * daily_usage_gals(devType,month)
  end
  
  # flowPortionByHour[devType][hour] returns float value as defined in resources/TABLE.flowPortionByHour.<name of devType>
  #Memoizing to avoid recalculations
  def flowPortionByHour
    return @memo_flowPortionByHour if defined? @memo_flowPortionByHour

    namedDevTypes =
    {clothes_washer:"clothes_washer",
     dishwasher:    "dishwasher",
     showers:       "showers",
     sinks:         "sinks",
     baths:         "baths",
    }
    @memo_flowPortionByHour = ingestTableFiles("flowPortionByHour" , namedDevTypes)
  end
  
  def daily_usage_gals(devType, month)
	@daily_usage.daily_usage_gals(devType, month)
  end
  
end
