
require "#{File.dirname(__FILE__)}/dhw"

#Instance variables are used to hold measure-argument values, adopting the argument names.

class SiteWaterMainsTemperature
  
  def initialize(avg_annual_temp, max_monthly_avg_temp, min_monthly_avg_temp)
    @average_annual_temp = avg_annual_temp
    @max_monthly_average_temp = max_monthly_avg_temp
    @min_monthly_average_temp = min_monthly_avg_temp
  end

  def site_water_mains_temp(month) #in F
  
    w = 0.4 + 0.01 * (@average_annual_temp - 44)
    
    v = @max_monthly_average_temp - @min_monthly_average_temp
    
    u = 0.986 * ((month * 30 - 15) - 15 - (35 - 1 * (@average_annual_temp - 44))) - 90
    
    y = @average_annual_temp + 6 + w * v / 2 * Math::sin(u * Math::PI/180)
	
	raise FormulaCalculationError.new("Calculated site water mains temperature for month #{month} is greater than 110.  Please check your inputs for min, max and average monthly temperatures.") if y > 110
    
    [32,y].max
  end
 
  
end # Formulas
