
require "#{File.dirname(__FILE__)}/dhw"

class UserDailyUsage
	include DHW
	
  def initialize(gpdhash)
	@gpds = gpdhash
  end

	def daily_usage_gals(devType, month)
		@gpds[devType]
	end
end

class StandardDailyUsage
	include DHW

	def initialize(number_of_bedrooms, site_mains_temp)
		@site_mains_temp = site_mains_temp
		@number_of_bedrooms = number_of_bedrooms
	end

  def daily_usage_gals(devType, month) # in gpd
    
    a = StandardDailyUsage.daily_usage_constants[devType][0]
    b = StandardDailyUsage.daily_usage_constants[devType][1]
    c = StandardDailyUsage.daily_usage_constants[devType][2]

    k = c ? [daily_usage_temp_diff_ratio(month) ,0].max : 1
  
    return a + b * @number_of_bedrooms * k
  end
  
  def self.daily_usage_constants 
    {clothes_washer:[2.35 , 0.78 , false],
     dishwasher:    [2.26 , 0.75 , false],
     showers:       [14.0 , 4.67 , true ],
     sinks:         [12.5 , 4.16 , true ],
     baths:         [3.5  , 2.27 , true ],
    }
  end
  
  def daily_usage_temp_diff_ratio(month)
    swmt = @site_mains_temp.site_water_mains_temp(month)
    if swmt.round(60)==125 
        raise FormulaCalculationError.new("Site Water Mains Temp must not be 125 (as it is for month=#{month}) to calculate daily usage")
    end
    
    (110 - swmt) / (125 - swmt)
  end
end

class RecircDailyUsage
	include DHW

	def initialize(base_usage, recirculation)
		@base_usage = base_usage
		@recirculation = recirculation
	end
	
	def daily_usage_gals(devType, month)
		@base_usage.daily_usage_gals(devType, month) + @recirculation.daily_usage_adjustment(devType, month) + @recirculation.recovery_adjustment(devType, month)
	end
end
