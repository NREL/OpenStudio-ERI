class Units

	def self.therms2kWh(x)
		# therms -> kWh
		return x*29.3
	end
	
	def self.kWh2therms(x)
		# kWh -> therms
		return x/29.3
	end
  
end
