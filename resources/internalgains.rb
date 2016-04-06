
require "#{File.dirname(__FILE__)}/dhw"

#Instance variables are used to hold measure-argument values, adopting the argument names.

class InternalGains
  include DHW      
		
  def initialize(number_of_bedrooms)
    @number_of_bedrooms = number_of_bedrooms
  end
  
  def hourly_sense_internal_gain_btu(devType,hour)
    gainPortionByHour[devType][hour] * daily_sense_internal_gain_btu(devType)
  end
   
  def hourly_latent_internal_gain_btu(devType,hour)
    gainPortionByHour[devType][hour] * daily_latent_internal_gain_btu(devType)
  end
 
  # Max(hour)(hourly_sense_internal_gain_btu(devType,hour))
  def peak_sense_internal_gain_btuperhr(devType)
    gainPortionByHour_MAX[devType]  * daily_sense_internal_gain_btu(devType)
  end
 
  # Max(hour)(hourly_latent_internal_gain_btu(devType,hour))
  def peak_latent_internal_gain_btuperhr(devType)
    gainPortionByHour_MAX[devType]  * daily_latent_internal_gain_btu(devType) 
  end
  
  def design_btuperhr(devType)
    peak_latent_internal_gain_btuperhr(devType) + peak_sense_internal_gain_btuperhr(devType)
    # == gainPortionByHour[devType].values.max * ( daily_sense_internal_gain_btu(devType) + daily_latent_internal_gain_btu(devType) )
  end
   
  def latent_fraction(devType)
	{showers:           0.487197,
     sinks:             0.31222,
     dishwasher:        0.0,
     baths:             0.0,
     clothes_washer:    0.0,
    }[devType]
  end
  
  def load_profile(devType,month,hour)
    raise FormulaCalculationError.new("Load profile (#{devType.to_s}) requires non-zero peak gain") if gainPortionByHour_MAX[devType] == 0
    
    gainPortionByHour[devType][hour] / gainPortionByHour_MAX[devType]
    #This ratio is the same as each of the following two when their denominators are non-zero:
    # hourly_latent_internal_gain_btu(devType,hour) / peak_latent_internal_gain_btuperhr(devType)
    # hourly_sense_internal_gain_btu(devType,hour) / peak_sense_internal_gain_btuperhr(devType)
  end
  
  def daily_sense_internal_gain_btu(devType) # in Btu/day
  
    a = daily_sense_internal_gain_constants[devType][0]
    b = daily_sense_internal_gain_constants[devType][1]
    
    a + b * @number_of_bedrooms
  end
  def daily_sense_internal_gain_constants
    {showers:           [741 , 247 ],
     sinks:             [310 , 103 ],
     baths:             [185 , 62 ],
     clothes_washer:    [0 , 0],
     dishwasher:        [0 , 0],
    }
  end
  
  def daily_latent_internal_gain_constants
    {showers:           [703 , 235 ],
     sinks:             [147 , 47 ],
     clothes_washer:    [0 , 0],
     dishwasher:        [0 , 0],
     baths:             [0 , 0],
    }
  end 
  
  def daily_latent_internal_gain_btu(devType) # in Btu/day
  
    a = daily_latent_internal_gain_constants[devType][0]
    b = daily_latent_internal_gain_constants[devType][1]
    
    a + b * @number_of_bedrooms
  end
  
  # gainPortionByHour[devType][hour] returns float value as defined in resources/TABLE.gainPortionByHour.<name of devType>
  #Memoizing to avoid recalculations
  def gainPortionByHour
    return @memo_gainPortionByHour if defined? @memo_gainPortionByHour
    
    namedDevTypes =
    {showers:       "showers",
     sinks:         "sinks",
     baths:         "baths",
    }
    @memo_gainPortionByHour = ingestTableFiles("gainPortionByHour" , namedDevTypes)
  end 
  
  # the Max(hour)(gainPortionByHour[devType][hour])
  #Memoizing to avoid recalculations
  def gainPortionByHour_MAX
    return @memo_gainPortionByHour_MAX if defined? @memo_gainPortionByHour_MAX
    
    h = Hash.new(0.0)
    
    gainPortionByHour.map{|devType,hoursMap| h[devType] = hoursMap.values.max} 
    
    @memo_gainPortionByHour_MAX = h
  end
  
end

class RecircInternalGains

	def initialize(base_gains, recirculation)
		@base_gains = base_gains
		@recirculation = recirculation
	end
	
  def design_btuperhr(devType)
	@base_gains.design_btuperhr(devType) + @recirculation.internal_gains_adjustment_max(devType) / 24.0
  end
   
  def latent_fraction(devType)
	@base_gains.latent_fraction(devType)
  end
  
  def load_profile(devType,month,hour)
	@base_gains.load_profile(devType, month, hour) * monthly_load_factor(devType, month)
  end
  
  def monthly_load_factor(devType, month)
	max = @recirculation.internal_gains_adjustment_max(devType)
	
	if (max > 0)
		return @recirculation.internal_gains_adjustment(devType, month) / max
	else
		return 1.0
	end
  end
end
