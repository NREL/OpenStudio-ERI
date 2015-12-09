class UnitConversion

	# Contains unit conversions not available in OpenStudio.convert.
	
	# See http://nrel.github.io/OpenStudio-user-documentation/reference/measure_code_examples/
	# for available OS unit conversions. Note that this list may not be complete, so try out
	# new unit conversions before adding them here.

	def self.knots2m_s(knots)
		# knots -> m/s
		return 0.51444444*knots
	end
  
end
