#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require 'openstudio' 

require "#{File.dirname(__FILE__)}/sitewatermainstemperature"
require "#{File.dirname(__FILE__)}/scheduledraws"
require "#{File.dirname(__FILE__)}/dailyusage"
require "#{File.dirname(__FILE__)}/internalgains"
require "#{File.dirname(__FILE__)}/recirculation"
require "#{File.dirname(__FILE__)}/resources/constants"


#start the measure
class AddWaterUseEquipmentObject < OpenStudio::Ruleset::ModelUserScript
	OSM = OpenStudio::Model
	    
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
	def name
		return "Add Hot Water Draw and Distribution"
	end

	def arguments(model)
		ruleset = OpenStudio::Ruleset
		osargument = ruleset::OSArgument

		args = ruleset::OSArgumentVector.new

		# make an argument for the existing plant loop
		existing_plant_loops = model.getPlantLoops
		existing_heating_plant_loops = existing_plant_loops.select{ |pl| pl.sizingPlant.loopType() == "Heating"}
		existing_plant_names = existing_heating_plant_loops.select{ |pl| not pl.name.empty?}.collect{ |pl| pl.name.get }
		existing_plant_names << "New Plant Loop"
		existing_plant_loop_name  = osargument::makeChoiceArgument("existing_plant_loop_name", existing_plant_names, true)
		existing_plant_loop_name.setDisplayName("Hot Water Loop WaterUseEquipment will be assigned to")
		args << existing_plant_loop_name

		# Use Standard DHW Event Schedules and Event Draws
		using_standard_dhw_event_schedules = osargument::makeBoolArgument('using_standard_dhw_event_schedules', true)
		using_standard_dhw_event_schedules.setDisplayName('Check to use the standard SHW Event schedules and event draws from the spreadsheet found in the "Hourly Profiles" tab of the B10 Analysis - New Construction 2011.1.26.xlsm spreadsheet. If this box is checked, user arguments entered for gallons per day flow amounts below will be ignored. If this box is not checked, user arguments for gallons per day of usage will be used, and a schedule of constant hourly usage values (1.0 for each hour) will be created.')
		using_standard_dhw_event_schedules.setDefaultValue(false)
		args << using_standard_dhw_event_schedules

		# make an argument for the number of bedrooms
		number_of_bedrooms = osargument::makeChoiceArgument("number_of_bedrooms", ["1", "2", "3", "4", "5"], true)
		number_of_bedrooms.setDisplayName("Number of Bedrooms in the Proposed Home. If more than 5 bedrooms enter 5.")
		args << number_of_bedrooms

		# Shower GPD
		shower_gpd = osargument::makeDoubleArgument("shower_gpd", true)
		shower_gpd.setDisplayName("Gallons per day of shower water usage (combined hot and cold water draw, delivered at 110F). If standard event schedules are used this value is ignored.")
		args << shower_gpd

		# Bath GPD
		bath_gpd = osargument::makeDoubleArgument("bath_gpd", true)
		bath_gpd.setDisplayName("Gallons per day of bath water usage (combined hot and cold water draw, delivered at 110F). If standard event schedules are used this value is ignored.")
		args << bath_gpd

		# Sinks GPD
		sinks_gpd = osargument::makeDoubleArgument("sinks_gpd", true)
		sinks_gpd.setDisplayName("Gallons per day of sinks water usage (combined hot and cold water draw, delivered at 110F). If standard event schedules are used this value is ignored.")
		args << sinks_gpd

		# Shower/Bath/Sink Location
		space_names = model.getSpaces.select{ |s| not s.name.empty? }.collect{ |s| s.name.get }
		shower_sinks_bath_space_name = osargument::makeChoiceArgument('shower_sinks_bath_space_name', space_names, true)
		shower_sinks_bath_space_name.setDisplayName("Location of Showers, Sinks and Baths")
		args << shower_sinks_bath_space_name

		# Clothes Washer GPD
		clothes_washer_gpd = osargument::makeDoubleArgument("clothes_washer_gpd", true)
		clothes_washer_gpd.setDisplayName("Gallons per day of clothes washer usage (hot water only, delivered at the hot water setpoint). If standard event schedules are used this value is ignored.")
		args << clothes_washer_gpd

		# Clothes Washer Location
		clothes_washer_space_name = osargument::makeChoiceArgument('clothes_washer_space_name', space_names, true)
		clothes_washer_space_name.setDisplayName("Location of Clothes Washer")
		args << clothes_washer_space_name

		# Dishwasher GPD
		dishwasher_gpd = osargument::makeDoubleArgument("dishwasher_gpd", true)
		dishwasher_gpd.setDisplayName("Gallons per day of dishwasher usage (hot water only, delivered at the hot water setpoint). If standard event schedules are used this value is ignored.")
		args << dishwasher_gpd

		# Dishwasher Location
		dishwasher_space_name = osargument::makeChoiceArgument('dishwasher_space_name', space_names, true)
		dishwasher_space_name.setDisplayName("Location of Dishwasher")
		args << dishwasher_space_name

		# Average Annual Temperature
		avg_annual_temp = osargument::makeDoubleArgument('avg_annual_temp', true)
		avg_annual_temp.setDisplayName("The average annual outside dry bulb temperature of the building's location (Deg F).")
		args << avg_annual_temp

		# Min Monthly Average Temperature
		min_monthly_avg_temp = osargument::makeDoubleArgument('min_monthly_avg_temp', true)
		min_monthly_avg_temp.setDisplayName("The minimum value of the monthly average temperatures of the building's location (Deg F).")
		args << min_monthly_avg_temp

		# Max Monthly Average Temperature
		max_monthly_avg_temp = osargument::makeDoubleArgument('max_monthly_avg_temp', true)
		max_monthly_avg_temp.setDisplayName("The maximum value of the monthly average temperatures of the building's location (Deg F).")
		args << max_monthly_avg_temp

		# Use Distribution and Recirculation Calculations
		using_distribution = osargument::makeBoolArgument('using_distribution', true)
		using_distribution.setDisplayName('Include distribution and recirculation adjustments for draw schedules and internal gains')
		using_distribution.setDefaultValue(false)
		args << using_distribution

		# Distribution Location
		distribution_location = osargument::makeChoiceArgument("distribution_location", ["Basement or Interior Space", "Attic", "Garage"], true)
		distribution_location.setDisplayName("Primary location of the service hot water distribution piping.")
		distribution_location.setDefaultValue("Basement or Interior Space")
		args << distribution_location
		
		# Distribution Type
		distribution_type = osargument::makeChoiceArgument("distribution_type", ["Home run", "Trunk and Branch"], true)
		distribution_type.setDisplayName("The plumbing layout of the hot water distribution system. Trunk and branch uses a main trunk branch to supply various branch take-offs to specific fixtures. In the home run layout, all fixtures are fed from dedicated piping that runs directly from central manifolds.")
		distribution_type.setDefaultValue("Trunk and Branch")
		args << distribution_type

		# Pipe Material
		pipe_material = osargument::makeChoiceArgument("pipe_material", ["Copper", "Pex"], true)
		pipe_material.setDisplayName("The plumbing material.")
		pipe_material.setDefaultValue("Copper")
		args << pipe_material
		
		# Recirculation Type
		recirculation_type = osargument::makeChoiceArgument("recirculation_type", ["Demand", "Timer", "None"], true)
		recirculation_type.setDisplayName("The type of hot water recirculation control, if any. Timer recirculation assumes 16 hrs of daily pump operation (from 0600 to 2200). Demand recirculation assumes push button control at all non-appliance fixtures with 100% ideal control (button pushed for every draw event no false signals, and immediate use of hot water when it arrives at the fixture.")
		recirculation_type.setDefaultValue("None")
		args << recirculation_type
		
		# Nominal Insulation R Value
		insulation_nominal_r_value = osargument::makeDoubleArgument("insulation_nominal_r_value", true)
		insulation_nominal_r_value.setDisplayName("Nominal R value for hot water pipe insulation in units of Deg F-ft2-h/Btu. This variable is used to adjust the internal gains and fixture flows based on domestic hot water distribution description.")
		insulation_nominal_r_value.setDefaultValue(0.0)
		args << insulation_nominal_r_value

		return args
	end #end the arguments method



	#define what happens when the measure is run
	def run(model, runner, user_arguments)
		super(model, runner, user_arguments)

		#use the built-in error checking 
		if not runner.validateUserArguments(arguments(model), user_arguments)
			return false
		end

		# Capture arguments as instance variables for easy access
		@model = model
		@runner = runner
		parse_arguments(user_arguments)
		
		if not validate_arguments then return false end
		
		register_initial_conditions

		begin

			# Find spaces in which we will place our water use equipment.  If any of the spaces cannot be found we fail the measure.
				@shower_sinks_bath_space = @model.getSpaces.find{ |s| (not s.name.empty?) and (s.name.get == @shower_sinks_bath_space_name) }
				if not @shower_sinks_bath_space then
				runner.registerError("Space specified for showers, sinks and baths (#{@shower_sinks_bath_space_name}) was not found in model.")
				return false
			end
				@clothes_washer_space = @model.getSpaces.find{ |s| (not s.name.empty?) and (s.name.get == @clothes_washer_space_name) }
				if not @clothes_washer_space then
				runner.registerError("Space specified for clothes washers (#{@clothes_washer_space_name}) was not found in model.")
				return false
			end
				@dishwasher_space = @model.getSpaces.find{ |s| (not s.name.empty?) and (s.name.get == @dishwasher_space_name) }
				if not @dishwasher_space then
				runner.registerError("Space specified for dishwashers (#{@dishwasher_space_name}) was not found in model.")
				return false
			end
				
			# Find the loop in which the water use equipment will be placed - this might be a newly created loop (3.a)
			@loop = find_or_create_loop
			if not @loop then
				runner.registerError("Plant loop specified (#{@existing_plant_loop_name}) was not found in the model.")
				return false
			end
			
			water_use_equipment_types = [:dishwasher, :clothes_washer, :showers, :baths, :sinks]
			equipment_spaces = {:dishwasher => @dishwasher_space, :clothes_washer => @clothes_washer_space, :showers => @shower_sinks_bath_space, :baths => @shower_sinks_bath_space, :sinks => @shower_sinks_bath_space}
			equipment_gpd = {:dishwasher => @dishwasher_gpd, :clothes_washer => @clothes_washer_gpd, :showers => @shower_gpd, :baths => @bath_gpd, :sinks => @sinks_gpd}

			water_temp = SiteWaterMainsTemperature.new(@avg_annual_temp, @max_monthly_avg_temp, @min_monthly_avg_temp)
			daily_usage = if @using_standard_dhw_event_schedules then StandardDailyUsage.new(@number_of_bedrooms, water_temp) else UserDailyUsage.new(equipment_gpd) end
			@gains = InternalGains.new(@number_of_bedrooms)
			recirculation = nil
			if @using_distribution
				recircArgs = {:distribution_location => @distribution_location, :distribution_type => @distribution_type, :pipe_material => @pipe_material, :insulation_nominal_r_value => @insulation_nominal_r_value, :recirculation_type => @recirculation_type, :number_of_bedrooms => @number_of_bedrooms, :dhw_draws => daily_usage, :dhw_gains => @gains, :site_water_temp => water_temp}
				if @using_standard_dhw_event_schedules
					recircArgs[:distribution_location] = "Basement or Interior Space"
					recircArgs[:pipe_material] = "Copper"
					recircArgs[:distribution_type] = "Trunk and Branch"
					recircArgs[:recirculation_type] = "None"
				end
				recirculation = RecirculationFormulas.new(recircArgs)
				daily_usage = RecircDailyUsage.new(daily_usage, recirculation)
				@gains = RecircInternalGains.new(@gains, recirculation)
			end
			@draws = if @using_standard_dhw_event_schedules then StandardScheduleDraws.new(daily_usage) else SimpleScheduleDraws.new(daily_usage) end
			
			water_use_equipment_types.each do |equiptype|
				equip_space = equipment_spaces[equiptype]
				# Create WaterUseEquipment, WaterUseEquipmentDefinition, WaterUseConnections (2.a, 2.d)
				equip, equip_def, use_conn = create_water_use_equipment(equiptype)
				peak_gph, draw_schedule = water_draw(equiptype)
				# Peak Flow (2.a.1)
				if peak_gph < 0
					@runner.registerWarning("Calculated peak draw for #{equiptype} is below zero and will be clipped to zero.")
					peak_gph = 0
				end
				equip_def.setPeakFlowRate(OpenStudio::Quantity.new(peak_gph/60, OpenStudio::createUnit("gal/min").get))
				# Target Temperature Schedule (2.a.3)
				target_temp_schedule = target_temperature_schedule(equiptype)
				equip_def.setTargetTemperatureSchedule(target_temp_schedule)
				# Flow Schedule and Location (2.d)
				equip.setFlowRateFractionSchedule(draw_schedule)
				equip.setSpace(equip_space)
				# Loop (3.b)
				@loop.addDemandBranchForComponent(use_conn)
				info = "An OS:WaterUseConnections object named #{use_conn.name.get} was created with an OS:WaterUseEquipmentDefinition object named #{equip_def.name.get} with the following properties:\nPeak Flow Rate: #{peak_gph/60.0} gpm\nTarget Temperature Schedule: #{target_temp_schedule.name.get}"

				if [:showers, :sinks, :baths].include? equiptype
					# Internal Gains (2.c) 
					gains_equip, gains_equip_def = create_internal_gains_object( equiptype)
					design_btuhr, latent_fraction, gains_schedule = internal_gains(equiptype)
					# (2.c.1)
					gains_equip_def.setDesignLevelCalculationMethod("EquipmentLevel", 0, 0) #TODO - what to use for floor area and numPeople?
					gains_equip_def.setDesignLevel(convert(design_btuhr, "Btu/h", "W"))
					gains_equip_def.setFractionLatent(latent_fraction)
					# (2.c.2)
					gains_equip.setSchedule(gains_schedule)
					gains_equip.setSpace(equip_space)
					info = info + "\nInternal Gains Schedule: #{gains_schedule.name.get}\nLatent Fraction: #{latent_fraction}\nThe OS:WaterUseConnections object named #{use_conn.name.get} was added to the hot water plant loop named #{@loop.name.get}."
				end

				# (3.b.1)
				@runner.registerInfo(info)
			end
			
			if recirculation
				pump_info = add_recirculation_pump(recirculation)
				@runner.registerInfo(pump_info)
			end
		
		rescue FormulaCalculationError => e
			@runner.registerError(e.message)
			return false
		rescue ModelStateError => e
			@runner.registerError(e.message)
			return false
		end
		
		register_final_conditions

		return true
	end #end the run method

	def water_draw(equiptype)
		if @using_standard_dhw_event_schedules or @using_distribution then
			draw_schedule = build_monthly_schedule { |m, h| @draws.draw_profile(equiptype, m, h) }
			draw_schedule.setName("Monthly draw profile for #{equiptype}")
			return @draws.peak_gph(equiptype), draw_schedule
		else
			peak_gph = @draws.peak_gph(equiptype)
			draw_schedule = constant_flow_rate_schedule
			return peak_gph, draw_schedule
		end
	end
	
	def constant_flow_rate_schedule
		unless @constantflowrateschedule
			@constantflowrateschedule = build_simple_schedule(1.0)
			@constantflowrateschedule.setName("Constant Flow")
		end
		return @constantflowrateschedule
	end
  
	def target_temperature_schedule(equiptype)
		# Clothes washers and dishwashers use a schedule taken from water heater, other equipment uses a constant temperature schedule (2.a.2)
		if [:clothes_washer, :dishwasher].include? equiptype
			return waterheater_temperature_schedule
		else
			return constant_temperature_schedule
		end
	end
	
	def waterheater
		unless defined? @waterheater
			if @loop.components(OSM::WaterHeaterMixed::iddObjectType).empty?
				@waterheater = nil
			else
				@waterheater = @model.getWaterHeaterMixeds.find{ |wh| (not wh.loop.empty?) and (not wh.loop.get.name.empty?) and (wh.loop.get.name.get == @loop.name.get) }
			end
		end
		return @waterheater
	end

	def waterheater_temperature_schedule
		unless @waterheater_temperature_schedule
			# if there is no waterheater, use a default constant temperature schedule (2.a.2)
			if not waterheater
				@runner.registerWarning("No water heater exists in the selected water loop. A target temperature schedule of 110F has been created and assigned to added clothes washers and dishwashers.")
				@waterheater_temperature_schedule = constant_temperature_schedule
			else
				# Find our waterheater and use its schedule; or use the default constant schedule if the waterheater has no schedule
				if not waterheater.setpointTemperatureSchedule.empty?
					@waterheater_temperature_schedule = waterheater.setpointTemperatureSchedule.get
				else
					@runner.registerWarning("The water heater for the selected loop has no setpoint temperature schedule. A target temperature schedule of 110F has been created and assigned to added clothes washers and dishwashers.")
					@waterheater_temperature_schedule = constant_temperature_schedule
					waterheater.setSetpointTemperatureSchedule(@waterheater_temperature_schedule)
				end
			end
		end

		return @waterheater_temperature_schedule
	end
	
	def constant_temperature_schedule
		unless @constanttemperatureschedule
			@constanttemperatureschedule = build_simple_schedule(convert(110, "F", "C"))
			@constanttemperatureschedule.setName("Constant 110F Temperature")
		end
		return @constanttemperatureschedule
	end
	
	def convert(value, from, to)
		return OpenStudio::convert(value, from , to).get
	end
  
	def internal_gains(equiptype)
		design_btuhr = @gains.design_btuperhr(equiptype)
		latent_fraction = @gains.latent_fraction(equiptype)
		schedule = build_monthly_schedule { |m, h| @gains.load_profile(equiptype, m, h) }
		schedule.setName("#{equiptype} internal gains")
		return design_btuhr, latent_fraction, schedule
	end

	# Takes a block of the form { |m, h| schedule_value(m, h) } where m represents the month and h the hour of a day in that month.
	def build_monthly_schedule
		sch = OSM::ScheduleRuleset.new(@model)
		(1..12).to_a.each do |m|
			day_sch = OSM::ScheduleDay.new(@model)
			(1..24).to_a.each do |h|
				day_sch.addValue(OpenStudio::Time.new(0, h, 0, 0), yield(m, h))
			end
			rule = OpenStudio::Model::ScheduleRule.new(sch, day_sch)
			rule.setApplySunday(true)
			rule.setApplyMonday(true)
			rule.setApplyTuesday(true)
			rule.setApplyWednesday(true)
			rule.setApplyThursday(true)
			rule.setApplyFriday(true)
			rule.setApplySaturday(true)
			rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(m), 1))
		end
		return sch
	end
  
	# Takes a block of the form { |h| schedule_value(h) } where h represents the hour of a day.
	def build_hourly_schedule
		sch = OSM::ScheduleRuleset.new(@model)
		(1..24).to_a.each do |h|
			sch.defaultDaySchedule.addValue(OpenStudio::Time.new(0, h, 0, 0), yield(h))
		end
		return sch
	end
  
	def build_simple_schedule(value)
		simpleschedule = OSM::ScheduleRuleset.new(@model)
		simpleschedule.defaultDaySchedule.addValue(OpenStudio::Time.new(0, 24, 0, 0), value)
		return simpleschedule
	end
  
	def parse_arguments(args)
		@existing_plant_loop_name = @runner.getStringArgumentValue("existing_plant_loop_name", args)
		@using_standard_dhw_event_schedules = @runner.getBoolArgumentValue("using_standard_dhw_event_schedules", args)
		@number_of_bedrooms = @runner.getStringArgumentValue("number_of_bedrooms", args).to_i
		@shower_gpd = @runner.getDoubleArgumentValue("shower_gpd", args)
		@bath_gpd = @runner.getDoubleArgumentValue("bath_gpd", args)
		@sinks_gpd = @runner.getDoubleArgumentValue("sinks_gpd", args)
		@shower_sinks_bath_space_name = @runner.getStringArgumentValue("shower_sinks_bath_space_name", args)
		@clothes_washer_gpd = @runner.getDoubleArgumentValue("clothes_washer_gpd", args)
		@clothes_washer_space_name = @runner.getStringArgumentValue("clothes_washer_space_name", args)
		@dishwasher_gpd = @runner.getDoubleArgumentValue("dishwasher_gpd", args)
		@dishwasher_space_name = @runner.getStringArgumentValue("dishwasher_space_name", args)
		@avg_annual_temp = @runner.getDoubleArgumentValue("avg_annual_temp", args)
		@min_monthly_avg_temp = @runner.getDoubleArgumentValue("min_monthly_avg_temp", args)
		@max_monthly_avg_temp = @runner.getDoubleArgumentValue("max_monthly_avg_temp", args)
		@distribution_location = @runner.getStringArgumentValue("distribution_location", args)
		@distribution_type = @runner.getStringArgumentValue("distribution_type", args)
		@pipe_material = @runner.getStringArgumentValue("pipe_material", args)
		@recirculation_type = @runner.getStringArgumentValue("recirculation_type", args)
		@insulation_nominal_r_value = @runner.getDoubleArgumentValue("insulation_nominal_r_value", args)
		@using_distribution = @runner.getBoolArgumentValue("using_distribution", args)
	end
	
	def validate_arguments
		# Not applicable conditions
		if @model.getSpaces.length == 0 then @runner.registerAsNotApplicable("Model has no spaces. Measure will not run.") end
		if @model.getThermalZones.length == 0 then @runner.registerAsNotApplicable("Model has no thermal zones. Measure will not run.") end
		
		# Error conditions
		if not @using_standard_dhw_event_schedules
			if (@shower_gpd < 0 or @bath_gpd < 0 or @sinks_gpd < 0 or @clothes_washer_gpd < 0 or @dishwasher_gpd < 0)
				@runner.registerError("Daily usage values must be greater than or equal to zero.")
			end
		end
		if (@max_monthly_avg_temp < -30 or @max_monthly_avg_temp > 130) then @runner.registerError("Temperature entered for Maximum Monthly Average is not realistic") end
		if (@min_monthly_avg_temp < -50 or @min_monthly_avg_temp > 110) then @runner.registerError("Temperature entered for Minimum Monthly Average is not realistic") end
		if (@avg_annual_temp < -40 or @avg_annual_temp > 120) then @runner.registerError("Temperature entered for Annual Average is not realistic.") end
		if @insulation_nominal_r_value > 30 then @runner.registerError("Nominal R value of #{@insulation_nominal_r_value} Deg F-ft2-h per Btu for hot water pipe insulation is greater than allowed.") end
		if @insulation_nominal_r_value < 0 then @runner.registerError("Nominal R value for hot water pipe insulation must be greater than or equal to 0.") end
		
		# Warning conditions
		if not @using_standard_dhw_event_schedules
			gpds = StandardDailyUsage.daily_usage_constants.inject({}) { |h, (k, v)| h[k] = v[0]+v[1]*2.0*@number_of_bedrooms; h }
			if (@shower_gpd > gpds[:showers]) then @runner.registerWarning("Shower gpd of #{@shower_gpd} is high for a home with #{@number_of_bedrooms} bedrooms.  Please verify this input.") end
			if (@sinks_gpd > gpds[:sinks]) then @runner.registerWarning("Sink gpd of #{@shower_gpd} is high for a home with #{@number_of_bedrooms} bedrooms.  Please verify this input.") end
			if (@bath_gpd > gpds[:baths]) then @runner.registerWarning("Bath gpd of #{@shower_gpd} is high for a home with #{@number_of_bedrooms} bedrooms.  Please verify this input.") end
			if (@clothes_washer_gpd > gpds[:clothes_washer]) then @runner.registerWarning("Clothes washer gpd of #{@shower_gpd} is high for a home with #{@number_of_bedrooms} bedrooms.  Please verify this input.") end
			if (@dishwasher_gpd > gpds[:dishwasher]) then @runner.registerWarning("Dishwasher gpd of #{@shower_gpd} is high for a home with #{@number_of_bedrooms} bedrooms.  Please verify this input.") end
		end
		if (@max_monthly_avg_temp < 5) then @runner.registerWarning("Temperature entered for Maximum Monthly Average seems low.") end
		if (@max_monthly_avg_temp > 100) then @runner.registerWarning("Temperature entered for Maximum Monthly Average seems high") end
		if (@min_monthly_avg_temp < -10) then @runner.registerWarning("Temperature entered for Minimum Monthly Average seems low") end
		if (@min_monthly_avg_temp > 85) then @runner.registerWarning("Temperature entered for Minimum Monthly Average seems high") end
		if (@avg_annual_temp < -5) then @runner.registerWarning("Temperature entered for Annual Average seems low.") end
		if (@avg_annual_temp > 85) then @runner.registerWarning("Temperature entered for Annual Average seems high.") end
		if @insulation_nominal_r_value > 20 then @runner.registerWarning("Nominal R value of #{@insulation_nominal_r_value} Deg F-ft2-h per Btu for hot water pipe insulation seems excessive.") end
		
		return @runner.result.errors.empty?
	end
	
	def register_initial_conditions
		water_use_connections = @model.getWaterUseConnectionss.length
		water_use_definitions = @model.getWaterUseEquipmentDefinitions.length
		water_use_equipments = @model.getWaterUseEquipments.length
		@runner.registerInitialCondition("Model started with #{water_use_connections} OS:WaterUseConnection objects, #{water_use_definitions} OS:WaterUseEquipmentDefinition objects, #{water_use_equipments} OS:WaterUseEquipment objects.")
	end
	
	def register_final_conditions
		water_use_connections = @model.getWaterUseConnectionss.length
		water_use_definitions = @model.getWaterUseEquipmentDefinitions.length
		water_use_equipments = @model.getWaterUseEquipments.length
		@runner.registerFinalCondition("Model ended with #{water_use_connections} OS:WaterUseConnection objects, #{water_use_definitions} OS:WaterUseEquipmentDefinition objects, #{water_use_equipments} OS:WaterUseEquipment objects.")
	end
	
	def find_or_create_loop
		if @existing_plant_loop_name == "New Plant Loop"
			loop = create_new_loop
			new_pump = create_new_pump
			new_pump.addToNode(loop.supplyInletNode)
			new_manager = create_new_schedule_manager
			new_manager.addToNode(loop.supplyOutletNode)
			new_heater = create_new_heater
			loop.addSupplyBranchForComponent(new_heater)
			return loop
		else
			return @model.getPlantLoops.find{|pl| (not pl.name.empty?) and (pl.name.get == @existing_plant_loop_name)}
		end	
	end
	
	def create_new_loop
		loop = OSM::PlantLoop.new(@model)
		loop.setName(Constants.PlantLoopDomesticWater)
		loop.sizingPlant.setDesignLoopExitTemperature(60)
		loop.sizingPlant.setLoopDesignTemperatureDifference(50)
		bypass_pipe = OSM::PipeAdiabatic.new(@model)
		loop.addSupplyBranchForComponent(bypass_pipe)
		@runner.registerInfo("Created new loop #{loop.name.get}.")
		return loop
	end
  
	def create_new_pump
		# pump seems to default to an autosized flow rate and intermittent control type
		pump = OSM::PumpConstantSpeed.new(@model)
		pump.setFractionofMotorInefficienciestoFluidStream(1)
		pump.setMotorEfficiency(0.999)
		pump.setRatedPowerConsumption(0.001)
		pump.setRatedPumpHead(0.001)
		@runner.registerInfo("Created new constant speed pump.")
		return pump
	end

	def create_new_schedule_manager
		new_schedule = OSM::ScheduleRuleset.new(@model)
		new_schedule.setName("SHW Temp")
		new_schedule.defaultDaySchedule.setName("HW Temp Default")
		new_schedule.defaultDaySchedule.addValue(OpenStudio::Time.new("24:00:00"), convert(110, "F", "C"))
		new_manager = OSM::SetpointManagerScheduled.new(@model, new_schedule)
		@runner.registerInfo("Created setpoint manager with schedule schedule #{new_schedule.name.get}.")
		return new_manager
	end

	def create_new_heater
		new_heater = OSM::WaterHeaterMixed.new(@model)
		new_heater.setHeaterThermalEfficiency(0.8)
		# new_heater.autosizeTankVolume
		new_heater.setName("Mixed Water Heater")

		# Stick the water heater in the zone of the showers sinks and bath space
		tzone = @shower_sinks_bath_space.thermalZone
		raise ModelStateError.new("A new plant loop cannot be created because the space named #{@shower_sinks_bath_space.name.get} has no thermal zone set.") if tzone.empty?
		new_heater.setAmbientTemperatureThermalZone(tzone.get)
		new_heater.setAmbientTemperatureIndicator("ThermalZone")
		
		@runner.registerInfo("Created new water heater #{new_heater.name.get}.")
		return new_heater
	end
  
	def create_water_use_equipment(equiptype)
		equip_definition = OSM::WaterUseEquipmentDefinition.new(@model)
		equip_definition.setName("#{equiptype} definition")
		equip = OSM::WaterUseEquipment.new(equip_definition)
		equip.setName("#{equiptype}")
		connection = OSM::WaterUseConnections.new(@model)
		connection.addWaterUseEquipment(equip)
		return equip, equip_definition, connection
	end
	
	def create_internal_gains_object(equiptype)
		gains_equip_def = OSM::OtherEquipmentDefinition.new(@model)
		gains_equip_def.setName("#{equiptype} internal gains definition")
		gains_equip = OSM::OtherEquipment.new(gains_equip_def)
		gains_equip.setName("#{equiptype} internal gains")
		return gains_equip, gains_equip_def
	end
	
	def add_recirculation_pump(recirculation)
		if waterheater
			space = (not waterheater.ambientTemperatureThermalZone.empty?) && (waterheater.ambientTemperatureThermalZone.get.spaces.sort { |a,b| b.floorArea <=> a.floorArea }.first)
			unless space
				raise ModelStateError.new("The waterheater on the selected loop has no ambient temperature thermal zone or the thermal zone has no spaces.  A recirculation pump cannot be added.")
			end
			pump, pump_def = create_internal_gains_object(:pump)
			pump_def.setDesignLevelCalculationMethod("EquipmentLevel", 0, 0)
			pump_def.setDesignLevel(recirculation.daily_pump_energy / 24 * 1000)
			pump.setSpace(space)
			
			flat_sched = OpenStudio::Model::ScheduleRuleset.new(@model)
			flat_sched.setName("Pump flat load schedule")
			flat_sched.defaultDaySchedule().setName("Pump flat load schedule") 
			flat_sched.defaultDaySchedule().addValue(OpenStudio::Time.new(0,24,0,0),1.0)
			pump.setSchedule(flat_sched)

			return "An OS::OtherEquipment #{pump.name.get} was added to #{pump.space.get.name.get} with load schedule #{pump.schedule.get.name.get}"
		else
			raise ModelStateError.new("No waterheater is present on the selected loop.  A recirculation pump cannot be added.")
		end
	end

end #end the measure

#this allows the measure to be use by the application
AddWaterUseEquipmentObject.new.registerWithApplication
