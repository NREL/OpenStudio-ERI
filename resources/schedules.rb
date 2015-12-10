class MonthHourSchedule
    def initialize(weekday_hourly_values, weekend_hourly_values, monthly_values, model, sch_name, runner)
		@validated = true
		@model = model
        @runner = runner
		@sch_name = sch_name
        @weekday_hourly_values = validateValues(weekday_hourly_values, 24, "weekday")
	    @weekend_hourly_values = validateValues(weekend_hourly_values, 24, "weekend")
	    @monthly_values = validateValues(monthly_values, 12, "monthly")
		if not @validated
			return
		end
		@weekday_hourly_values = normalizeSumToOne(@weekday_hourly_values)
		@weekend_hourly_values = normalizeSumToOne(@weekend_hourly_values)
		@monthly_values = normalizeAvgToOne(@monthly_values)
		@maxval = calcMaxval()
		@schadjust = calcSchadjust()
		@schedule = createSchedule()
    end
  
	def validated?
		return @validated
	end
	
	def calcDesignLevelElec(daily_kwh)
		return daily_kwh * @maxval * 1000 * @schadjust
	end

	def calcDesignLevelGas(daily_therm)
		return calcDesignLevelElec(OpenStudio.convert(daily_therm, "therm", "kWh").get)
	end

	def setSchedule(obj)
		# Helper method to set (or replace) the object's schedule
		if not obj.schedule.empty?
			sch = obj.schedule.get
			sch.remove
		end
		obj.setSchedule(@schedule)
	end

	private 
	
		def validateValues(values_str, num_values, sch_name)
			begin
				vals = values_str.split(",")
				vals.each do |val|
					if not valid_float?(val)
						@runner.registerError(num_values.to_s + " comma-separated numbers must be entered for the " + sch_name + " schedule.")
						@validated = false
					end
				end
				floats = vals.map {|i| i.to_f}
				if floats.length != num_values
					@runner.registerError(num_values.to_s + " comma-separated numbers must be entered for the " + sch_name + " schedule.")
					@validated = false
				end
			rescue
				@runner.registerError(num_values.to_s + " comma-separated numbers must be entered for the " + sch_name + " schedule.")
				@validated = false
			end
			return floats
		end

		def valid_float?(str)
			!!Float(str) rescue false
		end

		def normalizeSumToOne(values)
			sum = values.reduce(:+).to_f
			return values.map{|val| val/sum}
		end
		
		def normalizeAvgToOne(values)
			avg = values.reduce(:+).to_f/values.size
			return values.map{|val| val/avg}
		end

		def calcMaxval()
			if @weekday_hourly_values.max > @weekend_hourly_values.max
			  return @monthly_values.max * @weekday_hourly_values.max
			else
			  return @monthly_values.max * @weekend_hourly_values.max
			end
		end
		
		def calcSchadjust()
			#if sum != 1, normalize to get correct max val
			sum_wkdy = 0
			sum_wknd = 0
			@weekday_hourly_values.each do |v|
				sum_wkdy = sum_wkdy + v
			end
			@weekend_hourly_values.each do |v|
				sum_wknd = sum_wknd + v
			end
			if sum_wkdy < sum_wknd
				return 1/sum_wknd
			end
			return 1/sum_wkdy
		end
		
		def createSchedule()
			wkdy = []
			wknd = []
			day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
			day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
			
			time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
			for h in 1..24
				time[h] = OpenStudio::Time.new(0,h,0,0)
			end

			schedule = OpenStudio::Model::ScheduleRuleset.new(@model)
			schedule.setName(@sch_name + "_annual_schedule")
			
			for m in 1..12
				date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
				date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
				for w in 1..2
					if w == 1
						wkdy_rule = OpenStudio::Model::ScheduleRule.new(schedule)
						wkdy_rule.setName(@sch_name + "_weekday_ruleset#{m}")
						wkdy[m] = wkdy_rule.daySchedule
						wkdy[m].setName(@sch_name + "_weekday#{m}")
						for h in 1..24
							val = (@monthly_values[m-1].to_f*@weekday_hourly_values[h-1].to_f)/@maxval
							wkdy[m].addValue(time[h],val)
						end
						wkdy_rule.setApplySunday(false)
						wkdy_rule.setApplyMonday(true)
						wkdy_rule.setApplyTuesday(true)
						wkdy_rule.setApplyWednesday(true)
						wkdy_rule.setApplyThursday(true)
						wkdy_rule.setApplyFriday(true)
						wkdy_rule.setApplySaturday(false)
						wkdy_rule.setStartDate(date_s)
						wkdy_rule.setEndDate(date_e)
						
					elsif w == 2
						wknd_rule = OpenStudio::Model::ScheduleRule.new(schedule)
						wknd_rule.setName(@sch_name + "_weekend_ruleset#{m}")
						wknd[m] = wknd_rule.daySchedule
						wknd[m].setName(@sch_name + "_weekend#{m}")
						for h in 1..24
							val = (@monthly_values[m-1].to_f*@weekend_hourly_values[h-1].to_f)/@maxval
							wknd[m].addValue(time[h],val)
						end
						wknd_rule.setApplySunday(true)
						wknd_rule.setApplyMonday(false)
						wknd_rule.setApplyTuesday(false)
						wknd_rule.setApplyWednesday(false)
						wknd_rule.setApplyThursday(false)
						wknd_rule.setApplyFriday(false)
						wknd_rule.setApplySaturday(true)
						wknd_rule.setStartDate(date_s)
						wknd_rule.setEndDate(date_e)
					end
				end
			end
			
			sumDesSch = wkdy[6] # FIXME: Where did this come from?
			sumDesSch.setName(@sch_name + "_summer")
			winDesSch = wkdy[1] # FIXME: Where did this come from?
			winDesSch.setName(@sch_name + "_winter")
			schedule.setSummerDesignDaySchedule(sumDesSch)
			schedule.setWinterDesignDaySchedule(winDesSch)
			
			return schedule
		end
	
end

class HotWaterSchedule

    def initialize(runner, model, num_bedrooms, unit_num, column_header, sch_name)
        @validated = true
        @model = model
        @runner = runner
        @sch_name = sch_name
        @num_bedrooms = num_bedrooms.to_i
        @unit_index = unit_num % 10
        @column_header = column_header
        
        timestep_minutes = (60/@model.getTimestep.numberOfTimestepsPerHour).to_i
        
        data = loadMinuteDrawProfileFromFile(timestep_minutes)
        @totflow, @maxflow = loadDrawProfileStatsFromFile()
        if data.nil? or @totflow.nil? or @maxflow.nil?
            @validated = false
            return
        end
        @schedule = createSchedule(data, timestep_minutes)
    end

    def validated?
		return @validated
	end
    
    def calcDesignLevelElec(kWh_day)
        return OpenStudio.convert(kWh_day*365*60/(365*@totflow/@maxflow), "kW", "W").get
    end

	def setSchedule(obj)
		# Helper method to set (or replace) the object's schedule
		if not obj.schedule.empty?
			sch = obj.schedule.get
			sch.remove
		end
		obj.setSchedule(@schedule)
	end
    
    private
    
        def loadMinuteDrawProfileFromFile(timestep_minutes)
            data = []
            
            # Get appropriate file
            minute_draw_profile = "#{File.dirname(__FILE__)}/DHWDrawSchedule_#{@num_bedrooms}bed_unit#{@unit_index}_1min_fraction.csv"
            if not File.file?(minute_draw_profile)
                @runner.registerError("Unable to find file: #{minute_draw_profile}")
                return nil
            end
            
            skippedheader = false
            items = []
            col_num = nil
            File.open(minute_draw_profile).each do |line|
                linedata = line.strip.split(',')
                if not skippedheader
                    skippedheader = true
                    # Which column to read?
                    col_num = linedata.index(@column_header)
                    next
                end
                if col_num.nil?
                    @runner.registerError("Unable to find column header: #{@column_header}")
                    return nil
                end
                item = linedata[col_num]
                if not item.nil?
                    items.push(item.to_f)
                else
                    items.push(0.0)
                end
                if items.size == timestep_minutes
                    # Aggregate minute schedule up to the timestep level to reduce the size 
                    # and speed of processing.
                    avgitem = items.reduce(:+).to_f/items.size
                    data.push(avgitem)
                    items.clear
                end
            end
            
            return data
        end
        
        def loadDrawProfileStatsFromFile()
            totflow = 0 # daily gal/day
            maxflow = 0
            
            totflow_column_header = "#{@column_header} Sum"
            maxflow_column_header = "#{@column_header} Max"
            
            draw_file = "#{File.dirname(__FILE__)}/MinuteDrawProfilesMaxFlows.csv"
            
            datafound = false
            skippedheader = false
            totflow_col_num = nil
            maxflow_col_num = nil
            File.open(draw_file).each do |line|
                linedata = line.strip.split(',')
                if not skippedheader
                    skippedheader = true
                    # Which columns to read?
                    totflow_col_num = linedata.index(totflow_column_header)
                    maxflow_col_num = linedata.index(maxflow_column_header)
                    next
                end
                if totflow_col_num.nil?
                    @runner.registerError("Unable to find column header: #{totflow_column_header}")
                    return nil, nil
                end
                if maxflow_col_num.nil?
                    @runner.registerError("Unable to find column header: #{maxflow_column_header}")
                    return nil, nil
                end
                if linedata[0].to_i == @num_bedrooms and linedata[1].to_i == @unit_index
                    datafound = true
                    totflow = linedata[totflow_col_num].to_f
                    maxflow = linedata[maxflow_col_num].to_f
                    break
                end
            end
            
            if not datafound
                @runner.registerError("Unable to find data for bedrooms = #{@num_bedrooms} and unit index = #{@unit_index}.")
                return nil, nil
            end
            
            return totflow, maxflow
            
        end
    
        def createSchedule(data, timestep_minutes)
            # OpenStudio does not yet support ScheduleFile. So we use ScheduleInterval instead.
            # See https://unmethours.com/question/2877/has-anyone-used-the-variable-interval-schedule-sets-in-os-16/
            # for an example.
            
            yd = @model.getYearDescription
            start_date = yd.makeDate(1,1)
            interval = OpenStudio::Time.new(0, 0, timestep_minutes)
            
            time_series = OpenStudio::TimeSeries.new(start_date, interval, OpenStudio::createVector(data), "")
            
            schedule = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series, @model).get
            schedule.setName(@sch_name + "_annual_schedule")
            
            return schedule
        end

end