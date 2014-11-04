require 'erb'

#start the measure
class ExportTimeSeriesDatatoCSV < OpenStudio::Ruleset::ReportingUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ExportTimeSeriesDatatoCSV"
  end
  
  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    #get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end

    header = ["Date/Time"]
    month_dict = {"Jan"=>"01", "Feb"=>"02", "Mar"=>"03", "Apr"=>"04", "May"=>"05", "Jun"=>"06", "Jul"=>"07", "Aug"=>"08", "Sep"=>"09", "Oct"=>"10", "Nov"=>"11", "Dec"=>"12"}
    output_time_series_dict = {}

    #only try to get the annual time series if an annual simulation was run
    if ann_env_pd
      reportingFrequencies = sqlFile.availableReportingFrequencies(ann_env_pd)
      reportingFrequencies.each do |reportingFrequency|
        variableNames = sqlFile.availableVariableNames(ann_env_pd, reportingFrequency.to_s)
        variableNames.each do |variableName|
          keyValues = sqlFile.availableKeyValues(ann_env_pd, reportingFrequency.to_s, variableName.to_s)
          keyValues.each do |keyValue|
            output_time_series = sqlFile.timeSeries(ann_env_pd, reportingFrequency.to_s, variableName.to_s, keyValue.to_s).get
            if keyValue != ""
              header << "#{keyValue.to_s}:#{variableName.to_s} [#{output_time_series.units}](#{reportingFrequency.to_s})"
            else
              header << "#{variableName.to_s} [#{output_time_series.units}](#{reportingFrequency.to_s})"
            end
            dateTimes = output_time_series.dateTimes
            dateTimes.each do |dateTime|
              value = output_time_series.value(dateTime)
              month_str = dateTime.to_s.split("-")[1]
              day_time = dateTime.to_s.split("-")[2]
              month = "#{month_dict[month_str]}"
              day = day_time[0..1]
              hour = day_time[3..4]
              min = day_time[6..7]
              sec = day_time[9..10]

              if month == "01" and day == "01" and hour == "00" and min == "00" and sec == "00"
                month = "12"
                day = "31"
                hour = "24"
              elsif hour == "00" and min == "00" and sec == "00"
                hour = "24"
                if min == "00" and sec == "00"
                  if day == "01"
                    if month == "02"
                      month = "01"
                      day = "31"
                    elsif month == "03"
                      month = "02"
                      day = "28"
                    elsif month == "04"
                      month = "03"
                      day = "31"
                    elsif month == "05"
                      month = "04"
                      day = "30"
                    elsif month == "06"
                      month = "05"
                      day = "31"
                    elsif month == "07"
                      month = "06"
                      day = "30"
                    elsif month == "08"
                      month = "07"
                      day = "31"
                    elsif month == "09"
                      month = "08"
                      day = "31"
                    elsif month == "10"
                      month = "09"
                      day = "30"
                    elsif month == "11"
                      month = "10"
                      day = "31"
                    elsif month == "12"
                      month = "11"
                      day = "30"
                    end
                  else
                    day = "%02d" % (day.to_f - 1.0).to_i.to_s
                  end
                end
              end

              begin
                output_time_series_dict[" #{month}/#{day}  #{hour}:#{min}:#{sec}"] << value.to_s
              rescue
                output_time_series_dict[" #{month}/#{day}  #{hour}:#{min}:#{sec}"] = [value.to_s]
              end
            end
          end
        end
      end
    end

    File.open("./out.csv", 'w') do |file|
      file.puts header.join(',')
      output_time_series_dict.sort.map do |key, values|
        row = [key.to_s]
        values.each do |value|
          row << value
        end
        file.puts row.join(',')
      end
    end

    File.open("./config.cfg", 'w') do |file|
      file.puts ["column","label","key","unit"].join(',')
      header.each_with_index do |eplus_col, index|
        if eplus_col == "Date/Time"
          file.puts [(index+1).to_s, eplus_col, "%m/%d %H:%M:%S"].join(',')
        else
          file.puts [(index+1).to_s, eplus_col, r_col(eplus_col), pretty_units(/\[.+]/.match(eplus_col).to_s.gsub("[","").gsub("]",""))].join(',')
        end
      end
    end

    #closing the sql file
    sqlFile.close()

    return true

  end #end the run method

  def r_col(eplus_col)
    return eplus_col.gsub(/\s\[.+/,"").gsub(": ","_").gsub(":","_").gsub(" ","_").downcase
  end

  def pretty_units(str)
    unit_dict = {"C"=>"°C", "W/m2"=>"W/m²", "J"=>"J/min"}
    if unit_dict[str].nil?
      return str
    else
      return unit_dict[str]
    end
  end

end #end the measure

#this allows the measure to be use by the application
ExportTimeSeriesDatatoCSV.new.registerWithApplication