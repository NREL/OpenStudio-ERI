# Add classes or functions here than can be used across a variety of our python classes and modules.
require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/util"

class Waterheater
	def self.calc_nom_tankvol(vol, fuel, num_beds, num_baths)
		#Calculates the volume of a water heater
		if vol == 'auto'
			#Based on the BA HSP
			if fuel == Constants.FuelTypeElectric
			# Source: Table 5 HUD-FHA Minimum Water Heater Capacities for One- and 
			# Two-Family Living Units (ASHRAE HVAC Applications 2007)
				if num_baths < 2
					if num_beds < 2
						return 20
					elsif num_beds < 3
						return 30
					else
						return 40
					end
				elsif num_baths < 3
					if num_beds < 3
						return 40
					elsif num_beds < 5
						return 50
					else
						return 66
					end
				else
					if num_beds < 4
						return 50
					elsif num_beds < 6
						return 66
					else
						return 80
					end
				end
			
			else # Non-electric tank WHs
			# Source: 2010 HSP Addendum
				if num_beds <= 2
					return 30
				elsif num_beds == 3
					if num_baths <= 1.5
						return 30
					else
						return 40
					end
				elsif num_beds == 4
					if num_baths <= 2.5
						return 40
					else
						return 50
					end
				else
					return 50
				end
			end
		else #user entered volume
			return vol.to_f
		end
	end

    def self.calc_capacity(cap, fuel, num_beds, num_baths)
    #Calculate the capacity of the water heater based on the fuel type and number of bedrooms and bathrooms in a home
    #returns the capacity in kBtu/hr
		if cap == 'auto'
			if fuel != Constants.FuelTypeElectric
				if num_beds <= 3
					input_power = 36
				elsif num_beds == 4
					if num_baths <= 2.5
						input_power = 36
					else
						input_power = 38
					end
				elsif num_beds == 5
					input_power = 47
				else
					input_power = 50
				end
				return input_power
			
			else
				if num_beds == 1
					input_power = 2.5
				elsif num_beds == 2
					if num_baths <= 1.5
						input_power = 3.5
					else
						input_power = 4.5
					end
				elsif num_beds == 3
					if num_baths <= 1.5
						input_power = 4.5
					else
						input_power = 5.5
					end
				else
					input_power = 5.5
				end
				return OpenStudio.convert(input_power, "kW", "kBtu/hr").get
			end
			
		else #fixed heater size
			return cap.to_f
		end
	end

	def self.calc_actual_tankvol(vol, fuel)
	#Convert the nominal tank volume to an actual volume
		if fuel == Constants.FuelTypeElectric
			act_vol = 0.9 * vol
		else
			act_vol = 0.95 * vol
		end
		return act_vol
	end
	
	def self.calc_ef(ef, vol, fuel)
	#Calculate the energy factor as a function of the tank volume and fuel type
		if ef == 'auto'
			if fuel == Constants.FuelTypePropane or fuel == Constants.FuelTypeGas
				return 0.67 - (0.0019 * vol)
			elsif fuel == Constants.FuelTypeElectric
				return 0.97 - (0.00132 * vol)
			else
				return 0.59 - (0.0019 * vol)
			end
		else #user input energy factor
			return ef.to_f
		end
	end
	
	def self.calc_tank_UA(vol, fuel, ef, re, pow)
	#Calculates the U value, UA of the tank and conversion efficiency (eta_c)
	#based on the Energy Factor and recovery efficiency of the tank
	#Source: Burch and Erickson 2004 - http://www.nrel.gov/docs/gen/fy04/36035.pdf
		pi = Math::PI
		volume_drawn = 64.3 # gal/day
        density = 8.2938 # lb/gal
        draw_mass = volume_drawn * density # lb
        cp = 1.0007 # Btu/lb-F
        t = 135 # F
        t_in = 58 # F
        t_env = 67.5 # F
        q_load = draw_mass * cp * (t - t_in) # Btu/day
        height = 48 # inches
        diameter = 24 * ((vol * 0.1337) / (height / 12 * pi)) ** 0.5 # inches       
        surface_area = 2 * pi * (diameter / 12) ** 2 / 4 + pi * (diameter / 12) * (height / 12) # sqft

        if fuel != Constants.FuelTypeElectric
            ua = (re / ef - 1) / ((t - t_env) * (24 / q_load - 1 / (1000*(pow) * ef))) #Btu/hr-F
            eta_c = (re + ua * (t - t_env) / (1000 * pow))
        else # is Electric
            ua = q_load * (1 / ef - 1) / ((t - t_env) * 24)
			eta_c = 1.0
		end
		u = ua / surface_area #Btu/hr-ft^2-F
		return u, ua, eta_c
	end
	
	def self.create_new_pump(model)
		#Add a pump to the new DHW loop
		pump = OpenStudio::Model::PumpConstantSpeed.new(model)
		pump.setFractionofMotorInefficienciestoFluidStream(0)
		pump.setMotorEfficiency(1)
		pump.setRatedPowerConsumption(0)
		pump.setRatedPumpHead(1)
		return pump
	end
	
	def self.create_new_schedule_ruleset(name, schedule_name, t_set, model)
		#Create a setpoint schedule for the water heater
		new_schedule = OpenStudio::Model::ScheduleRuleset.new(model)
		t_set_c = OpenStudio::convert(t_set,"F","C").get
		new_schedule.setName(name)
		new_schedule.defaultDaySchedule.setName(schedule_name)
		new_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new("24:00:00"), t_set)
		return new_schedule
	end
	
	def self.create_new_heater(cap, fuel, vol, nbeds, nbaths, ef, re, t_set, loc, oncycle_p, offcycle_p, model, runner)
	
		new_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
		fuel_eplus = HelperMethods.eplus_fuel_map(fuel)
		capacity = self.calc_capacity(cap, fuel, nbeds, nbaths)
		capacity_w = OpenStudio::convert(capacity,"kBtu/hr","W").get
		nom_vol = self.calc_nom_tankvol(vol, fuel, nbeds, nbaths)
		act_vol = self.calc_actual_tankvol(nom_vol, fuel)
		energy_factor = self.calc_ef(ef, nom_vol, fuel)
		u, ua, eta_c = self.calc_tank_UA(act_vol, fuel, energy_factor, re, capacity)
		self.configure_setpoint_schedule(new_heater, t_set, model, runner)
		new_heater.setMaximumTemperatureLimit(99.0)
		new_heater.setHeaterControlType("Cycle")
		
		vol_m3 = OpenStudio::convert(act_vol, "gal", "m^3").get
		new_heater.setHeaterMinimumCapacity(0.0)
		new_heater.setHeaterMaximumCapacity(capacity_w)
		new_heater.setHeaterFuelType(fuel_eplus)
		new_heater.setHeaterThermalEfficiency(eta_c)
		new_heater.setAmbientTemperatureIndicator("ThermalZone")
		new_heater.setTankVolume(vol_m3)
		
		#Set parasitic power consumption
		new_heater.setOnCycleParasiticFuelConsumptionRate(oncycle_p)
		new_heater.setOnCycleParasiticFuelType("Electricity")
		new_heater.setOnCycleParasiticHeatFractiontoTank(0)
		
		new_heater.setOffCycleParasiticFuelConsumptionRate(offcycle_p)
		new_heater.setOffCycleParasiticFuelType("Electricity")
		new_heater.setOffCycleParasiticHeatFractiontoTank(0)
		
		#Set fraction of heat loss from tank to ambient (vs out flue)
		#Based on lab testing done by LBNL
		if fuel  == Constants.FuelTypeGas or fuel == Constants.FuelTypePropane
			if oncycle_p == 0
				skinlossfrac = 0.64
			elsif ef < 0.8
				skinlossfrac = 0.91
			else
				skinlossfrac = 0.96
			end
		else
			skinlossfrac = 1.0
		end
		new_heater.setOffCycleLossFractiontoThermalZone(skinlossfrac)
		new_heater.setOnCycleLossFractiontoThermalZone(1.0)

		thermal_zone = model.getThermalZones.find{|tz| tz.name.get == loc}
		
		new_heater.setAmbientTemperatureThermalZone(thermal_zone)
		ua_w_k = OpenStudio::convert(ua, "Btu/hr*R", "W/K").get
		new_heater.setOnCycleLossCoefficienttoAmbientTemperature(ua_w_k)
		new_heater.setOffCycleLossCoefficienttoAmbientTemperature(ua_w_k)
		
		return new_heater
	end 
  
    def self.configure_setpoint_schedule(new_heater, t_set, model, runner)
		set_temp = OpenStudio::convert(t_set,"F","C").get
		runner.registerInfo("t_set = #{t_set}")
		runner.registerInfo("set_temp = #{set_temp}")
		new_schedule = self.create_new_schedule_ruleset("DHW Set Temp", "DHW Set Temp", set_temp, model)
		new_heater.setSetpointTemperatureSchedule(new_schedule)
		runner.registerInfo "A schedule named DHW Set Temp was created and applied to the gas water heater, using a constant temperature of #{t_set.to_s} F for generating domestic hot water."
	end
	
	def self.create_new_loop(model)
		#Create a new plant loop for the water heater
		loop = OpenStudio::Model::PlantLoop.new(model)
		loop.setName("Domestic Hot Water Loop")
		loop.sizingPlant.setDesignLoopExitTemperature(60)
		loop.sizingPlant.setLoopDesignTemperatureDifference(50)
			
		bypass_pipe  = OpenStudio::Model::PipeAdiabatic.new(model)
		out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
		
		loop.addSupplyBranchForComponent(bypass_pipe)
		out_pipe.addToNode(loop.supplyOutletNode)
		
		return loop
	end
	
	def self.get_water_heater_setpoint(model, plant_loop, runner)
        waterHeater = nil
        plant_loop.supplyComponents.each do |wh|
            if wh.to_WaterHeaterMixed.is_initialized
                waterHeater = wh.to_WaterHeaterMixed.get
            elsif wh.to_WaterHeaterStratified.is_initialized
                waterHeater = wh.to_WaterHeaterStratified.get
            else
                next
            end
            if waterHeater.setpointTemperatureSchedule.nil?
                runner.registerError("Water heater found without a setpoint temperature schedule.")
                return nil
            end
        end
        if waterHeater.nil?
            runner.registerError("No water heater found; add a residential water heater first.")
            return nil
        end
        min_max_result = Schedule.getMinMaxAnnualProfileValue(model, waterHeater.setpointTemperatureSchedule.get)
        wh_setpoint = OpenStudio.convert((min_max_result['min'] + min_max_result['max'])/2.0, "C", "F").get
        if min_max_result['min'] != min_max_result['max']
            runner.registerWarning("Water heater setpoint is not constant. Using average setpoint temperature of #{wh_setpoint.round} F.")
        end
        return wh_setpoint
    end
end