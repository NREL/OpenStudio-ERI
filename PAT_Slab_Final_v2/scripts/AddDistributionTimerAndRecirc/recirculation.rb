
#Instance variables are used to hold measure-argument values, adopting the argument names.

require "#{File.dirname(__FILE__)}/dhw"

class RecirculationFormulas

	def initialize(args)
		@distribution_location = args[:distribution_location]
		@distribution_type = args[:distribution_type]
		@pipe_material =args[:pipe_material]
		@insulation_nominal_r_value = args[:insulation_nominal_r_value]
		@recirculation_type = args[:recirculation_type]
		@number_of_bedrooms = args[:number_of_bedrooms]
		@dhw_draws = args[:dhw_draws] || NullDHW.new
		@dhw_gains = args[:dhw_gains] || NullDHW.new
		@site_water_temp = args[:site_water_temp] || NullDHW.new
	end

	def recirculation_case_number
		unless @memo_recirc_case_number
			# Use regular expressions to find the first case that matches a key we build from the user inputs.
			key = "#{@distribution_type}_#{@pipe_material}_#{@distribution_location}_#{@recirculation_type}"
			cases = {
				1 => /Trunk and Branch_Copper_Basement or Interior Space_None/,
				2 => /Trunk and Branch_Pex_Basement or Interior Space_None/,
				3 => /Trunk and Branch_Copper_(Attic|Garage)_None/,
				4 => /Trunk and Branch_Pex_(Attic|Garage)_None/,
				5 => /Home run_(Pex|Copper)_Basement or Interior Space_None/,
				6 => /Home run_(Pex|Copper)_(Attic|Garage)_None/,
				7 => /Trunk and Branch_Copper_Basement or Interior Space_Timer/,
				8 => /Trunk and Branch_Copper_Basement or Interior Space_Demand/,
				9 => /Trunk and Branch_Pex_Basement or Interior Space_Timer/,
				10 => /Trunk and Branch_Pex_Basement or Interior Space_Demand/
			}
			cases.each do |case_num, filter|
				if filter =~ key
					return @memo_recirc_case_number = case_num
				end
			end
			@memo_recirc_case_number = -1
		end
		return @memo_recirc_case_number
	end
	
	def draw_coefficients
		unless @memo_coefficients
			# Load a set of coefficients for the draw equations (see daily_usage_adjustment) from a file.
			# The file has columns of coefficients separated by tabs.  Each recirculation case has three columns for 30 columns total.
			# For each case the columns represent the coefficients for showers, baths and sinks in that order.
			# Each row in a column holds a coefficient a-f
			f = File.open("#{File.dirname(__FILE__)}/resources/TABLE.recirculationGPDCoefficients.txt")
			# Read the file into nested arrays
			lines = f.read.split(/\n/).map {|l| l.split(/\s+/)}
			
			@memo_coefficients = {}
			
			# We load the coefficients into a hash. The key for the hash is a concatenation of the equipment type and case number
			(1..10).each do |casenum|
				[:showers, :baths, :sinks].each_with_index do |equip, i|
					col = (casenum-1)*3+i
					@memo_coefficients["#{equip}#{casenum}"] = (0..6).map{|row| lines[row][col].to_f}
				end
			end
			
			f.close
		end
		return @memo_coefficients
	end
	
	# in units of gal/day
	def daily_usage_adjustment(devType, month)
		return 0.0 unless DHW::FAUCETTYPES.include? devType
		return 0.0 if recirculation_case_number == -1

		a, b, c, d, e, f, g = draw_coefficients["#{devType}#{recirculation_case_number}"]
		avg_gpd = @dhw_draws.avg_annual_gpd(devType)
		return 0.0 unless avg_gpd > 0
		
		w = f +	g * @number_of_bedrooms
		t = (avg_gpd + w) / avg_gpd
		u = c + d * @number_of_bedrooms
		v = (a + b * @number_of_bedrooms) * @insulation_nominal_r_value / 2.0
		x = 1 + e * Math::sin((month/12.0 + 0.3)* 2.0 * Math::PI)
		
		#puts "w:#{w} t:#{t} u:#{u} v:#{v} x:#{x}"
		return w + t * (u + v) * x
	end
	
	def recirculation_coefficients
		{
			1 => [0, 0, 0, 0],
			2 => [0, 0, 0, 0],
			3 => [0, 0, 0, 0],
			4 => [0, 0, 0, 0],
			5 => [0, 0, 0, 0],
			6 => [0, 0, 0, 0],
			7 => [0, 0, 0, 0],
			8 => [0, 0, 0, 0],
			9 => [18125, 2538, -12265, -1495],
			10 => [-3648, 2344, -1328, -761]
		}
	end
		
	# For entire system in units of gal/day
	def recovery_adjustment(devType, month)
		return 0.0 unless DHW::FAUCETTYPES.include? devType
		return 0.0 if recirculation_case_number == -1
		
		a, b, c, d = recirculation_coefficients[recirculation_case_number]
		
		u = a + b * @number_of_bedrooms + (c + d * @number_of_bedrooms) * @insulation_nominal_r_value / 2.0
		v = 8.33 * (120 - @site_water_temp.site_water_mains_temp(month))*4184*0.00023886
		#puts "u:#{u} v:#{v}"
		return u/v / 3.0
	end
	
	def internal_gain_equations
		# Equation parameters are:
		#  b: number of bedrooms - 3
		#  m: month of the year (1-12)
		#  r: nominal R value of insulation
		{
			1 => lambda { |b, m, r|  (4257+735*b-(948+158*b)*r/2.0) *                                                        (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			2 => lambda { |b, m, r|  (4257-1047-732*r/2.0)*                                                 (1 + 1/4257.0*735*b + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			3 => lambda { |b, m, r|  (4257+735*b-(3356+589*b)-(90+11*b)*r/2.0) *                                             (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			4 => lambda { |b, m, r|  (4257-1047)*(1+1/4257.0*735*b-1/4257.0*(3356+589*b+(90+11*b)*r/2.0)) *                  (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			5 => lambda { |b, m, r|  (4257+735*b-(1142+378*b)-(649+73*b)*r/2.0) *                                            (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			6 => lambda { |b, m, r|  (4257+735*b-(1142+378*b))*(1-1/4257.0*(3356+589*b+(90+11*b)*r/2.0)) *                   (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			7 => lambda { |b, m, r|  (4257+735*b+(20148+2140*b)-(11956+1355*b)*r/2.0) *                                      (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			8 => lambda { |b, m, r|  (4257+735*b+(1458+1066*b)-(1332+545*b)*r/2.0) *                                         (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			9 => lambda { |b, m, r|  (4257-1047)*(1+1/4257.0*735*b+1/4257.0*(20148+2140*b)-1/4257.0*(11956+1355*b)*r/2.0) *  (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) },
			10 => lambda { |b, m, r| (4257-1047)*(1+1/4257.0*735*b+1/4257.0*(1458+1066*b)-1/4257.0*(1332+545*b)*r/2.0) *     (1 + 1/4257.0 * (362+63*b)*Math::sin(Math::PI*2*(m/12.0 + 0.3))) }
		}
	end
	
	def internal_gains_distribution
		unless @memo_normalized_gain_ratios
			# Internal gains will be split between equipment based on the design energy before adjusting for recirculation.  If there are no internal gains (0 for all equipment)
			# the internal gains distribution and therefore adjustment will be zero for all equipment.
			ratios = Hash[DHW::FAUCETTYPES.zip(DHW::FAUCETTYPES.map { |dt| @dhw_gains.design_btuperhr(dt) })]
			# If any internal gains are negative our algorithm will not return a correct result
			raise FormulaCalculationError.new("Negative internal gains cannot be normalized") if ratios.values.index { |v| v < 0 }
			
			mag = ratios.values.inject(0) { |sum, v| sum + v }
			if mag > 0
				@memo_normalized_gain_ratios = {}
				ratios.each do |k,v|
					@memo_normalized_gain_ratios[k] = v / mag.to_f
				end
			else
				# gain ratio is zero for all devices
				@memo_normalized_gain_ratios = Hash[DHW::FAUCETTYPES.zip(DHW::FAUCETTYPES.map { 0.0 })]
			end
		end
		return @memo_normalized_gain_ratios
	end
	
	# in units of btu/day
	def internal_gains_adjustment(devType, month)
		return 0.0 unless DHW::FAUCETTYPES.include? devType
		return 0.0 if recirculation_case_number == -1
	
		total_gains = total_internal_gains = internal_gain_equations[recirculation_case_number][@number_of_bedrooms-3, month, @insulation_nominal_r_value]
		return internal_gains_distribution[devType] * total_gains
	end
	
	# in units of btu/day
	def internal_gains_adjustment_max(devType)
		return 0.0 unless DHW::FAUCETTYPES.include? devType
	
		unless @memo_internal_gains_max
			@memo_internal_gains_max = {}
			DHW::FAUCETTYPES.each do |dt|
				@memo_internal_gains_max[dt] = (1..12).map{|m| internal_gains_adjustment(dt, m)}.max
			end
		end
		return @memo_internal_gains_max[devType]
	end
	
	def pump_energy_coefficients
		{
			1 => [0, 0, 0, 0, 0],
			2 => [0, 0, 0, 0, 0],
			3 => [0, 0, 0, 0, 0],
			4 => [0, 0, 0, 0, 0],
			5 => [0, 0, 0, 0, 0],
			6 => [0, 0, 0, 0, 0],
			7 => [0, 0, 0, 0, 1],
			8 => [-0.13, 0.72, 0.13, -0.17, 0],
			9 => [0, 0, 0, 0, 1],
			10 => [-0.13, 0.72, 0.13, -0.17, 0]
		}
	end
		
	# in units of kWh
	def daily_pump_energy
		return 0.0 if recirculation_case_number == -1
		a,b,c,d,e = pump_energy_coefficients[recirculation_case_number]
		t = a+b*@number_of_bedrooms
		u = (c+d*@number_of_bedrooms) * @insulation_nominal_r_value/2.0
		v = e * 193
		#puts "t:#{t} u:#{u} v:#{v}"
		return (t + u + v)/365.0
	end
		
	# in units of kWh
	def pump_energy(month)

		return daily_pump_energy * DHW::DAYSINMONTH[month]
	end
	
end # Recirculation