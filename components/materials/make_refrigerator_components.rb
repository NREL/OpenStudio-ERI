require 'C:/Program Files (x86)/OpenStudio 1.3.1/Ruby/openstudio'
require 'bcl'
require 'sqlite3'
require 'find'
require 'fileutils'

class RefrigeratorComponentMaker

  def initialize(dir)
    @dir = dir

    # get EP and OS versions
    @epversion = OpenStudio::Workspace.new("Draft".to_StrictnessLevel,"EnergyPlus".to_IddFileType).iddFile.version
    @osversion = OpenStudio::Workspace.new.iddFile.version

    # create hash to store uids in
    @uid_file = dir + "/uid_hash.txt"
    @uid_hash = nil
    if File.exists?(@uid_file)
      File.open(@uid_file, 'r') do |file|
        @uid_hash = Marshal.load(file)
        if (@uid_hash.class != Hash) or @uid_hash.nil?
          raise "Invalid Hash read from disk"
        end
      end
    else
      @uid_hash = Hash.new
    end

  end

  # save the uid hash for next time
  def save_uid_hash
    File.open(@uid_file, 'w') do |file|
      Marshal.dump(@uid_hash, file)
    end
  end

  #utility method because ruby 1.8.7 doesn't do rounding
  def round(number, dec_place)

    multiplier = "1"
    dec_place.times do |i|
      multiplier << "0"
    end
    multiplier << ".0"

    multiplier = multiplier.to_f

    result = (number*multiplier).round / multiplier

    return result

  end

  def make(build_dir)

    # load master taxonomy to validate components
    taxonomy = BCL::MasterTaxonomy.new

    root_path = "C:/OpenStudioLocal/ElectricEquipment"

    db = SQLite3::Database.new 'C:/OpenStudioLocal/Measures.sqlite'

    db.results_as_hash = true
    db.execute("select * from CategoryGroup").each do |row1|
      groupname = row1["GroupName"]
      categorygroupid = row1["CategoryGroupID"]

      # Major Appliances
      if groupname == "Major Appliances"
        groupname = "MajorAppliances"
        db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
          categoryname = row2["CategoryName"]
          # Refrigerator
          if categoryname == "Refrigerator"
            foldername = "#{groupname}_#{categoryname}"
            majorappl_refrigerators = { "01.idf"=>"Benchmark",
                                        "02.idf"=>"0.8 x Benchmark",
                                        "03.idf"=>"25 cu ft., EF = 15.7, side freezer",
                                        "04.idf"=>"25 cu ft., EF = 19.6, side freezer",
                                        "05.idf"=>"25 cu ft., EF = 19.8, side freezer",
                                        "06.idf"=>"25 cu ft., EF = 20.6, side freezer",
                                        "07.idf"=>"25 cu ft., EF = 20.6, side freezer, DR control",
                                        "08.idf"=>"21 cu ft., EF = 15.9, bottom freezer",
                                        "09.idf"=>"21 cu ft., EF = 19.8, bottom freezer",
                                        "10.idf"=>"21 cu ft., EF = 20.1, bottom freezer",
                                        "11.idf"=>"21 cu ft., EF = 21.3, bottom freezer",
                                        "12.idf"=>"18 cu ft., EF = 15.9, top freezer",
                                        "13.idf"=>"18 cu ft., EF = 19.9, top freezer",
                                        "14.idf"=>"18 cu ft., EF = 20.4, top freezer",
                                        "15.idf"=>"18 cu ft., EF = 21.9, top freezer"
            }
            path = "#{root_path}/lib/#{foldername}"
            Find.find(path) do |file|
              if File.extname(file).include? "idf"
                $newrefrigerator = false
                $foundrefrigerator = false
                $designlevel = nil
                f = File.open(file, "r")
                f.each_line do |line|
                  if $foundrefrigerator == true
                    break
                  else
                    line = line.strip
                    if "+#{line}".include? "+ElectricEquipment,"
                      $newrefrigerator = true
                    end
                    if $newrefrigerator == true
                      if not line.empty?
                        val_prop = line.split("!- ")
                        if val_prop[1] == "Design Level {W}"
                          $dl = val_prop[0].gsub(",","").strip.to_f
                        end
                      else
                        $name = "#{majorappl_refrigerators[File.basename(file)]}"

                        raise "design level unknown" if $dl.nil?

                        $foundrefrigerator = true
                      end
                    end
                  end
                end

                model = OpenStudio::Model::Model.new
                os_elecequipdef = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
                os_elecequipdef.setName($name.gsub(",",""))
                os_elecequipdef.setDesignLevel($dl)
                os_elecequipdef.setFractionLatent(0)
                os_elecequipdef.setFractionRadiant(0)
                os_elecequipdef.setFractionLost(0)

                monthly_mult = Process_refrigerator::Monthly_mult_fridge
                weekday_hourly = Process_refrigerator::Weekday_hourly_fridge
                weekend_hourly = Process_refrigerator::Weekend_hourly_fridge
                maxval = Process_refrigerator::Maxval_fridge

                refrig_wkdy = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
                refrig_wknd = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
                refrig_wk = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
                time = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0']
                wkdy_refrig_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
                wknd_refrig_rule = ['0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' ]
                day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
                day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

                refrig_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
                refrig_ruleset.setName("refrigerator_ruleset")


                for m in 1..12
                  date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
                  date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
                  for w in 1..2
                    if w == 1
                      wkdy_refrig_rule[m] = OpenStudio::Model::ScheduleRule.new(refrig_ruleset)
                      wkdy_refrig_rule[m].setName("fridge_weekday_ruleset#{m}")
                      wkdy_refrig_rule
                      refrig_wkdy[m] = wkdy_refrig_rule[m].daySchedule
                      refrig_wkdy[m].setName("RefrigeratorWeekday#{m}")
                      for h in 1..24
                        time[h] = OpenStudio::Time.new(0,h,0,0)
                        val = (monthly_mult[m-1].to_f*weekday_hourly[h-1].to_f)/maxval
                        #runner.registerWarning("#{monthly_mult[m-1]}")
                        #runner.registerWarning("#{weekday_hourly[h]}")
                        #runner.registerWarning("#{val}")
                        refrig_wkdy[m].addValue(time[h],val)
                      end
                      wkdy_refrig_rule[m].setApplySunday(false)
                      wkdy_refrig_rule[m].setApplyMonday(true)
                      wkdy_refrig_rule[m].setApplyTuesday(true)
                      wkdy_refrig_rule[m].setApplyWednesday(true)
                      wkdy_refrig_rule[m].setApplyThursday(true)
                      wkdy_refrig_rule[m].setApplyFriday(true)
                      wkdy_refrig_rule[m].setApplySaturday(false)
                      wkdy_refrig_rule[m].setStartDate(date_s)
                      wkdy_refrig_rule[m].setEndDate(date_e)

                    elsif w == 2
                      wknd_refrig_rule[m] = OpenStudio::Model::ScheduleRule.new(refrig_ruleset)
                      wknd_refrig_rule[m].setName("fridge_weekend_ruleset#{m}")
                      refrig_wknd[m] = wknd_refrig_rule[m].daySchedule
                      refrig_wknd[m].setName("RefrigeratorWeekend#{m}")
                      for h in 1..24
                        time[h] = OpenStudio::Time.new(0,h,0,0)
                        val = (monthly_mult[m-1].to_f*weekend_hourly[h-1].to_f)/maxval
                        refrig_wknd[m].addValue(time[h],val)
                      end
                      wknd_refrig_rule[m].setApplySunday(true)
                      wknd_refrig_rule[m].setApplyMonday(false)
                      wknd_refrig_rule[m].setApplyTuesday(false)
                      wknd_refrig_rule[m].setApplyWednesday(false)
                      wknd_refrig_rule[m].setApplyThursday(false)
                      wknd_refrig_rule[m].setApplyFriday(false)
                      wknd_refrig_rule[m].setApplySaturday(true)
                      wknd_refrig_rule[m].setStartDate(date_s)
                      wknd_refrig_rule[m].setEndDate(date_e)
                    end
                  end
                end

                sumDesSch = refrig_wkdy[6]
                sumDesSch.setName("RefrigeratorSummer")
                winDesSch = refrig_wkdy[1]
                winDesSch.setName("RefrigeratorWinter")
                refrig_ruleset.setSummerDesignDaySchedule(sumDesSch)
                refrig_ruleset.setWinterDesignDaySchedule(winDesSch)

                new_comp = BCL::Component.new("#{build_dir}")

                # pretty up the name
                comp_name = $name
                comp_name = comp_name.gsub('/', '-')
                new_comp.name = "#{comp_name}"

                # look up uid for name (use old E+ name as key)
                previous_uid = @uid_hash[$name.downcase]
                if previous_uid
                  new_comp.uid = previous_uid
                else
                  @uid_hash[$name.downcase] = new_comp.uid
                  save_uid_hash
                end

                #new_comp.description = "Window construction from EnergyPlus 8.0 WindowConstructs.idf dataset."
                new_comp.fidelity_level = 3

                #add_provenance(author, date, comment)
                new_comp.add_provenance("jrobertson", Time.now.gmtime.strftime('%Y-%m-%dT%H:%M:%SZ'), "Refrigerator electric equipment from BEopt library.")

                #add_tag(tag_name)
                new_comp.add_tag("MEL.Appliance.Refrigerator")

                # add attributes
                new_comp.add_attribute("OpenStudio Type", os_elecequipdef.iddObjectType.valueDescription, "")
                new_comp.add_attribute("Standard Type", "Residential", "")

                file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@osversion}.osm"
                model.save(OpenStudio::Path.new(file_str), true)
                #new_comp.add_file("OpenStudio", "#{@osversion}", file_str, "#{new_comp.name}_v#{@osversion}.osm", "osm")

                forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
                new_workspace = forward_translator.translateModel(model)
                file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@epversion}.idf"
                new_workspace.save(OpenStudio::Path.new(file_str), true)
                #new_comp.add_file("EnergyPlus", "#{@epversion}", file_str, "#{new_comp.name}_v#{@epversion}.idf", "idf")

                component = os_elecequipdef.createComponent
                file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@osversion}.osc"
                component.save(OpenStudio::Path.new(file_str), true)
                #new_comp.add_file("OpenStudio", "#{@osversion}", file_str, "#{new_comp.name}_v#{@osversion}.osc", "osc")

                taxonomy.check_component(new_comp)

                #new_comp.save_tar_gz(false)

              end
            end
          end
        end
      end
    end

    #new_comp.save_tar_gz(false)

    #BCL::gather_components(build_dir)

    #File.open(build_dir + "/report.csv", 'w') do |file|
    #  file.puts report
    #end

    #constructions.save(OpenStudio::Path.new(build_dir + "/WindowConstructs_modified.idf"), true)

  end

end

class Process_refrigerator
  #Refrigerator energy use comes from the measure (user specified), schedule is here

  #hard coded convective, radiative, latent, and lost fractions for fridges
  Fridge_lat = 0
  Fridge_rad = 0
  Fridge_lost = 0
  Fridge_conv = 1

  #Fridge weekday, weekend schedule and monthly multipliers

  #Right now hard coded simple schedules
  #TODO: Schedule inputs. Should be 24 or 48 hourly + 12 monthly, is 36-60 inputs too much? how to handle 8760 schedules (from a file?)
  Monthly_mult_fridge = [0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837]
  Weekday_hourly_fridge = [0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041]
  Weekend_hourly_fridge = Weekday_hourly_fridge

  #if sum != 1, normalize to get correct max val
  sum_fridge_wkdy = 0
  sum_fridge_wknd = 0

  Weekday_hourly_fridge.each do |v|
    sum_fridge_wkdy = sum_fridge_wkdy + v
  end

  Weekend_hourly_fridge.each do |v|
    sum_fridge_wknd = sum_fridge_wkdy + v
  end

  Sum_wkdy = sum_fridge_wkdy

  #for v in 0..23
  #Weekday_hourly_fridge[v] = Weekday_hourly_fridge[v]/sum_fridge_wkdy
  #Weekend_hourly_fridge[v] = Weekday_hourly_fridge[v]/sum_fridge_wknd
  #end

  #get max schedule value

  if Weekday_hourly_fridge.max > Weekend_hourly_fridge.max
    Maxval_fridge = Monthly_mult_fridge.max * Weekday_hourly_fridge.max #/ sum_fridge_wkdy
  else
    Maxval_fridge = Monthly_mult_fridge.max * Weekend_hourly_fridge.max #/ sum_fridge_wknd
  end
end

refrigerator_component_maker = RefrigeratorComponentMaker.new("C:/OpenStudio/OS-BEopt/components/electric equipment/refrigerator")
#FileUtils.mkdir_p("./window")
refrigerator_component_maker.make("C:/OpenStudio/OS-BEopt/components/electric equipment/refrigerator")

