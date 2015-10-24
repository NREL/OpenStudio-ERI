
class WeatherHeader
  def initialize
  end
  attr_accessor(:City, :State, :Country, :DataSource, :Station, :Latitude, :Longitude, :Timezone, :Altitude)
end

class WeatherData
  def initialize
  end
  attr_accessor(:AnnualAvgDrybulb, :AnnualMinDrybulb, :AnnualMaxDrybulb, :CDD50F, :CDD65F, :HDD50F, :HDD64F, :HDD65F, :HDD66F, :DailyAvgDrybulbs, :DailyMaxDrybulbs, :DailyMinDrybulbs, :AnnualAvgWindspeed, :MonthlyAvgDrybulbs)
end

class WeatherDesign
  def initialize
  end
  attr_accessor(:HeatingDrybulb, :HeatingWindspeed, :CoolingDrybulb, :CoolingWetbulb, :CoolingHumidityRatio, :CoolingWindspeed, :DailyTemperatureRange, :DehumidDrybulb, :DehumidHumidityRatio)
end

class WeatherProcess

  def initialize(epwfile)
    @header, @data, @design = WeatherProcess._process_epw_text(epwfile)
  end

  def header
    return @header
  end

  def data
    return @data
  end

  def design
    return @design
  end

  def self._process_epw_text(epwfile)

    # if not os.path.exists(epwfile):
    #     raise IOError("Cannot find file " + epwfile)
	
    epwlines = []
    File.open(epwfile) do |file|
      file.each do |line|
        epwlines << line
      end
    end

    # Header line:
    header = WeatherHeader.new
    headerline = epwlines.delete_at(0).split(',')
    header.City = headerline[1]
    header.State = headerline[2]
    header.Country = headerline[3]
    header.DataSource = headerline[4]
    header.Station = headerline[5]
    header.Latitude = WeatherProcess._fmt(headerline[6],3)
    header.Longitude = WeatherProcess._fmt(headerline[7],3)
    header.Timezone = headerline[8].to_f
    header.Altitude = WeatherProcess._fmt(OpenStudio::convert(headerline[9].to_f,"m","ft").get,4)

    # Design data line:

    design = WeatherDesign.new
    designData = epwlines.delete_at(0).split(',')
    epwHasDesignData = false
    if designData.length > 5
      begin
        psychrometrics = Psychrometrics.new
        design.HeatingDrybulb = WeatherProcess._fmt(OpenStudio::convert(designData[7].to_f,"C","F").get, 2)
        design.HeatingWindspeed = designData[16].to_f

        design.CoolingDrybulb = WeatherProcess._fmt(OpenStudio::convert(designData[25].to_f,"C","F").get, 2)
        design.CoolingWetbulb = WeatherProcess._fmt(OpenStudio::convert(designData[26].to_f,"C","F").get, 2)
        std_press = psychrometrics.Pstd_fZ(header.Altitude)
        design.CoolingHumidityRatio = WeatherProcess._fmt(psychrometrics.w_fT_Twb_P(design.CoolingDrybulb, design.CoolingWetbulb, std_press), 4)
        design.CoolingWindspeed = designData[35].to_f

        design.DailyTemperatureRange = WeatherProcess._fmt(OpenStudio::convert(designData[22].to_f,"C","F").get, 2)

        dehum02per_dp = WeatherProcess._fmt(OpenStudio::convert(designData[43].to_f,"C","F").get, 2)
        design.DehumidDrybulb = WeatherProcess._fmt(OpenStudio::convert(designData[45].to_f,"C","F").get, 2)
        design.DehumidHumidityRatio = WeatherProcess._fmt(psychrometrics.w_fT_Twb_P(dehum02per_dp, dehum02per_dp, std_press), 4)

        epwHasDesignData = true
      rescue
        epwHasDesignData = false
      end
    end

    epwlines = WeatherProcess._remove_non_hourly_lines(epwlines)

    # Read data:
    hourdata = []
    dailydbs = []
    dailyhighdbs = []
    dailylowdbs = []
    epwlines.each_with_index do |epwline, hournum|

      data = epwline.split(',')
      hourdict = {}

      hourdict['month'] = data[1]
      hourdict['day'] = data[2]
      hourdict['hour'] = data[3]
      hourdict['db'] = data[6].to_f
      hourdict['dp'] = data[7].to_f
      hourdict['rh'] = data[8].to_f / 100.0
      hourdict['ethoriz'] = data[10].to_f
      hourdict['ghoriz'] = data[13].to_f
      hourdict['dirnormal'] = data[14].to_f # W/m^2
      hourdict['diffhoriz'] = data[15].to_f # W/m^2
      hourdict['ws'] = data[21].to_f

      hourdata << hourdict

      if (hournum + 1) % 24 == 0

        db = []
        maxdb = hourdata[hourdata.length - 24]['db']
        mindb = hourdata[hourdata.length - 24]['db']
        hourdata[hourdata.length - 24..-1].each do |x|
          if x['db'] > maxdb
            maxdb = x['db']
          end
          if x['db'] < mindb
            mindb = x['db']
          end
          db << x['db']
        end

        dailydbs << db.inject{ |sum, n| sum + n } / 24.0
        dailyhighdbs << maxdb
        dailylowdbs << mindb

      end

    end

    data = WeatherData.new
    data = WeatherProcess._calc_annual_drybulbs(data, hourdata)
    data = WeatherProcess._calc_monthly_drybulbs(data, hourdata)
    data = WeatherProcess._calc_heat_cool_degree_days(data, hourdata, dailydbs)
    data = WeatherProcess._calc_avg_windspeed(data, hourdata)

    return header, data, design

  end

  def self._remove_non_hourly_lines(epwlines)
    # Strips header lines until we get to the hourly data
    epwlines.each do |epwline|
      data = epwline.split(',')
      if data.length <= 4
        epwlines = epwlines[1..-1]
      elsif not (data[1] == "1" and data[2] == "1" and data[3] == "1")
        epwlines = epwlines[1..-1]
      else
        break
      end
    end
    return epwlines[0..8760] # Exclude any text beyond the 8760th line
  end

  def self._fmt(num, dec)
    # Formats number to the specified number of decimal places
    return sprintf("%.#{dec}f", num.to_f).to_f
  end

  def _calc_design_info

  end

  def self._calc_annual_drybulbs(data, hd)
    # Calculates and stores annual average, minimum, and maximum drybulbs
    db = []
    mindict = hd[0]
    maxdict = hd[0]
    hd.each do |x|
      if x['db'] > maxdict['db']
        maxdict = x
      end
      if x['db'] < mindict['db']
        mindict = x
      end
      db << x['db']
    end

    data.AnnualAvgDrybulb = WeatherProcess._fmt(OpenStudio::convert(db.inject{ |sum, n| sum + n } / 8760.0,"C","F").get, 2)

    # Peak temperatures:
    data.AnnualMinDrybulb = WeatherProcess._fmt(OpenStudio::convert(mindict['db'],"C","F").get, 2)
    data.AnnualMaxDrybulb = WeatherProcess._fmt(OpenStudio::convert(maxdict['db'],"C","F").get, 2)

    return data

  end

  def self._calc_monthly_drybulbs(data, hd)
    # Calculates and stores monthly average drybulbs
    data.MonthlyAvgDrybulbs = []
    (1...13).to_a.each do |month|
      y = []
      hd.each do |x|
        if x['month'] == month.to_s
          y << x['db']
        end
      end
      month_dbtotal = y.inject{ |sum, n| sum + n }
      month_hours = y.length
      data.MonthlyAvgDrybulbs << WeatherProcess._fmt(OpenStudio::convert(month_dbtotal / month_hours,"C","F").get, 2)
    end

    return data
  end

  def self._calc_avg_windspeed(data, hd)
    # Calculates and stores annual average windspeed
    ws = []
    hd.each do |x|
      ws << x['ws']
    end
    avgws = WeatherProcess._fmt(ws.inject{ |sum, n| sum + n } / 8760.0, 1)
    data.AnnualAvgWindspeed = avgws
    return data
  end

  def self._calc_heat_cool_degree_days(data, hd, dailydbs)
    # Calculates and stores heating/cooling degree days
    data.CDD50F = WeatherProcess._calc_degree_days(dailydbs, 50, false)
    data.CDD65F = WeatherProcess._calc_degree_days(dailydbs, 65, false)
    data.HDD50F = WeatherProcess._calc_degree_days(dailydbs, 50, true)
    data.HDD64F = WeatherProcess._calc_degree_days(dailydbs, 64, true)
    data.HDD65F = WeatherProcess._calc_degree_days(dailydbs, 65, true)
    data.HDD66F = WeatherProcess._calc_degree_days(dailydbs, 66, true)

    return data

  end

  def self._calc_degree_days(daily_dbs, base_temp_f, is_heating)
    # Calculates and returns degree days from a base temperature for either heating or cooling
    base_temp_c = OpenStudio::convert(base_temp_f,"F","C").get

    deg_days = []
    if is_heating
      daily_dbs.each do |x|
        if x < base_temp_c
          deg_days << base_temp_c - x
        end
      end
    else
      daily_dbs.each do |x|
        if x > base_temp_c
          deg_days << x - base_temp_c
        end
      end
    end
    deg_days = deg_days.inject{ |sum, n| sum + n }
    return WeatherProcess._fmt(1.8 * deg_days, 0)

  end

  def _calc_avg_highs_lows

  end

  def _calc_clearness_indices

  end

  def _calc_clearness_index

  end

  def _calc_design_solar_radiation

  end

  def _get_climate_zones_ba

  end

  def _get_climate_zones_iecc

  end

  def _calc_iecc_cz_intl

  end

  def _calc_iecc_cz_is_marine

  end

  def _get_states_in_ba_zone

  end

  def printData

  end

  def writeData

  end

end