require 'C:/Program Files (x86)/OpenStudio 1.3.1/Ruby/openstudio'
require 'bcl'
require 'sqlite3'
require 'find'
require 'fileutils'

class WindowComponentMaker

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

    root_path = "C:/OpenStudioLocal/Windows"

    db = SQLite3::Database.new 'C:/OpenStudioLocal/Measures.sqlite'

    db.results_as_hash = true
    db.execute("select * from CategoryGroup").each do |row1|
      groupname = row1["GroupName"]
      categorygroupid = row1["CategoryGroupID"]

      # Windows & Doors
      if groupname == "Windows & Doors"
        db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
          categoryname = row2["CategoryName"]
          # Windows
          if categoryname == "Windows"
            foldername = "#{groupname}_#{categoryname}"
            windowsanddoors_windows = { "24.idf"=>"Single-Pane, Clear, Metal Frame",
                                        "25.idf"=>"Single-Pane, Clear, Non-metal Frame",
                                        "01.idf"=>"Double-Pane, Clear, Metal Frame, Air Fill",
                                        "02.idf"=>"Double-Pane, Clear, Metal w Thermal Break Frame, Air Fill",
                                        "03.idf"=>"Double-Pane, Clear, Non-metal Frame, Air Fill",
                                        "04.idf"=>"Double-Pane, High-Gain Low-E, Non-metal Frame, Air Fill",
                                        "05.idf"=>"Double-Pane, Medium-Gain Low-E, Non-metal Frame, Air Fill",
                                        "06.idf"=>"Double-Pane, Low-Gain Low-E, Non-metal Frame, Air Fill",
                                        "07.idf"=>"Double-Pane, High-Gain Low-E, Non-metal Frame, Argon Fill",
                                        "08.idf"=>"Double-Pane, Medium-Gain Low-E, Non-metal Frame, Argon Fill",
                                        "09.idf"=>"Double-Pane, Low-Gain Low-E, Non-metal Frame, Argon Fill",
                                        "10.idf"=>"Double-Pane, High-Gain Low-E, Insulated Frame, Air Fill",
                                        "11.idf"=>"Double-Pane, Medium-Gain Low-E, Insulated Frame, Air Fill",
                                        "12.idf"=>"Double-Pane, Low-Gain Low-E, Insulated Frame, Air Fill",
                                        "13.idf"=>"Double-Pane, High-Gain Low-E, Insulated Frame, Argon Fill",
                                        "14.idf"=>"Double-Pane, Medium-Gain Low-E, Insulated Frame, Argon Fill",
                                        "15.idf"=>"Double-Pane, Low-Gain Low-E, Insulated Frame, Argon Fill",
                                        "16.idf"=>"Triple-Pane, High-Gain Low-E, Non-metal Frame, Air Fill",
                                        "17.idf"=>"Triple-Pane, Low-Gain Low-E, Non-metal Frame, Air Fill",
                                        "18.idf"=>"Triple-Pane, High-Gain Low-E, Non-metal Frame, Argon Fill",
                                        "19.idf"=>"Triple-Pane, Low-Gain Low-E, Non-metal Frame, Argon Fill",
                                        "20.idf"=>"Triple-Pane, High-Gain Low-E, Insulated Frame, Air Fill",
                                        "21.idf"=>"Triple-Pane, Low-Gain Low-E, Insulated Frame, Air Fill",
                                        "22.idf"=>"Triple-Pane, High-Gain Low-E, Insulated Frame, Argon Fill",
                                        "23.idf"=>"Triple-Pane, Low-Gain Low-E, Insulated Frame, Argon Fill"
            }
            path = "#{root_path}/lib/#{foldername}"
            Find.find(path) do |file|
              if File.extname(file).include? "idf"
                $newwindow = false
                $foundwindow = false
                $uvalue = nil
                $shgc = nil
                f = File.open(file, "r")
                f.each_line do |line|
                  if $foundwindow == true
                    break
                  else
                    line = line.strip
                    if "+#{line}".include? "+WindowMaterial:SimpleGlazingSystem,"
                      $newwindow = true
                    end
                    if $newwindow == true
                      if not line.empty?
                        val_prop = line.split("!- ")
                        if val_prop[1] == "U-Factor {W/m2-K}"
                          $u = val_prop[0].gsub(",","").strip.to_f
                        elsif val_prop[1] == "Solar Heat Gain Coefficient"
                          $shgc = val_prop[0].gsub(",","").strip.to_f
                        end
                      else
                        $name = "#{windowsanddoors_windows[File.basename(file)]}"

                        raise "u unknown" if $u.nil?
                        raise "shgc unknown" if $shgc.nil?

                        $foundwindow = true
                      end
                    end
                  end
                end

                model = OpenStudio::Model::Model.new
                os_windowmat = OpenStudio::Model::SimpleGlazing.new(model)
                if $name.include? "Single"
                  os_windowmat.setName("Single-Pane Glass")
                elsif $name.include? "Double"
                  os_windowmat.setName("Double-Pane Glass")
                elsif $name.include? "Triple"
                  os_windowmat.setName("Triple-Pane Glass")
                end
                os_windowmat.setUFactor($u)
                os_windowmat.setSolarHeatGainCoefficient($shgc)
                os_windowconst = OpenStudio::Model::Construction.new(model)
                os_windowconst.setName($name.gsub(",",""))
                os_windowconst.insertLayer(0,os_windowmat)

                constructionStandard = os_windowconst.standardsInformation
                constructionStandard.setIntendedSurfaceType("ExteriorWindow")

                num_panes = nil
                if /Single-Pane/.match($name)
                  num_panes = "Single pane"
                elsif /Double-Pane/.match($name)
                  num_panes = "Double pane"
                elsif /Triple-Pane/.match($name)
                  num_panes = "Triple pane"
                end

                tint = nil
                if /Clear/.match($name)
                  tint = "Clear"
                end

                gas = nil
                if /Air Fill/.match($name)
                  gas = "Air"
                elsif /Argon Fill/.match($name)
                  gas = "Argon"
                end

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
                new_comp.add_provenance("jrobertson", Time.now.gmtime.strftime('%Y-%m-%dT%H:%M:%SZ'), "Window construction from BEopt library.")

                #add_tag(tag_name)
                new_comp.add_tag("Construction Assembly.Fenestration.Window")

                # add attributes
                new_comp.add_attribute("Number of Panes", num_panes, "")
                if gas
                  new_comp.add_attribute("Gas Fill", gas, "")
                end
                if tint
                  new_comp.add_attribute("Tint", tint, "")
                end
                new_comp.add_attribute("Overall U-factor", $u, "W/m^2*K")
                new_comp.add_attribute("Solar Heat Gain Coefficient", $shgc, "")

                new_comp.add_attribute("OpenStudio Type", os_windowconst.iddObjectType.valueDescription, "")
                new_comp.add_attribute("Standard Type", "Residential", "")

                file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@osversion}.osm"
                model.save(OpenStudio::Path.new(file_str), true)
                #new_comp.add_file("OpenStudio", "#{@osversion}", file_str, "#{new_comp.name}_v#{@osversion}.osm", "osm")

                forward_translator = OpenStudio::EnergyPlus::ForwardTranslator.new
                new_workspace = forward_translator.translateModel(model)
                file_str = new_comp.resolve_path + "/#{new_comp.name}_v#{@epversion}.idf"
                new_workspace.save(OpenStudio::Path.new(file_str), true)
                #new_comp.add_file("EnergyPlus", "#{@epversion}", file_str, "#{new_comp.name}_v#{@epversion}.idf", "idf")

                component = os_windowconst.createComponent
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

    #BCL::gather_components(build_dir)

    #File.open(build_dir + "/report.csv", 'w') do |file|
    #  file.puts report
    #end

    #constructions.save(OpenStudio::Path.new(build_dir + "/WindowConstructs_modified.idf"), true)

  end

end

window_component_maker = WindowComponentMaker.new("C:/OpenStudio/OS-BEopt/components/constructions/window")
#FileUtils.mkdir_p("./window")
window_component_maker.make("C:/OpenStudio/OS-BEopt/components/constructions/window")

