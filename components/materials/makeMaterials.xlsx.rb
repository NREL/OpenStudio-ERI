require 'sqlite3'
require 'win32ole'
require 'find'
require 'C:/Program Files (x86)/OpenStudio 1.3.1/Ruby/openstudio'

root_path = "C:/OpenStudioLocal/Materials"
x1 = WIN32OLE::new('Excel.Application')
wb = x1.workbooks.Add
ws = wb.worksheets(1)
ws.name = "All Materials"
ws.Cells(1, 1).Value = "Category"
ws.Cells(1, 2).Value = "Sub-Category"
ws.Cells(1, 3).Value = "Name"
ws.Cells(1, 4).Value = "Roughness"
ws.Cells(1, 5).Value = "Thickness (m)"
ws.Cells(1, 6).Value = "Conductivity (W/m*K)"
ws.Cells(1, 7).Value = "Resistance (m^2*K/W)"
ws.Cells(1, 8).Value = "Density (kg/m^3)"
ws.Cells(1, 9).Value = "Specific Heat (J/kg*K)"
ws.Cells(1, 10).Value = "Concrete Block.Fill Type"
ws.Cells(1, 11).Value = "Stud-Cavity.Nominal Stud Width (in)"
ws.Cells(1, 12).Value = "Stud-Cavity.Stud On-Center Spacing (in)"
ws.Cells(1, 13).Value = "Stud-Cavity.Nominal Cavity Insulation Resistance (hr*ft^2*R/Btu)"
ws.Cells(1, 14).Value = "Stud-Cavity.Nominal Header Insulation Resistance (hr*ft^2*R/Btu)"
ws.Cells(1, 15).Value = "Exterior Wall"
ws.Cells(1, 16).Value = "Interior Wall"
ws.Cells(1, 17).Value = "Below Grade Wall"
ws.Cells(1, 18).Value = "Slab-On-Grade Floor"
ws.Cells(1, 19).Value = "Attic Floor"
ws.Cells(1, 20).Value  = "Outdoor Exposed Floor"
ws.Cells(1, 21).Value = "Interior Floor"
ws.Cells(1, 22).Value = "Exterior Roof"
ws.Cells(1, 23).Value = "Attic Roof"
ws.Cells(1, 24).Value = "Interior Ceiling"
ws.Cells(1, 25).Value = "Thermal Absorptance"
ws.Cells(1, 26).Value = "Solar Absorptance"
ws.Cells(1, 27).Value = "Visible Absorptance"
ws.Cells(1, 28).Value = "Note"

def wood_stud_constructions(name, file, options)
  if ["StudandCavity"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def double_stud_constructions(name, file, options)
  if ["StudandCavity", "Cavity"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def cmu_constructions(name, file, options)
  if ["CMU", "Furring"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def sip_constructions(name, file, options)
  if ["SplineLayer", "WallIns", "IntSheathing"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def icf_constructions(name, file, options)
  if ["ICFConcrete", "ICFInsForm"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def other_constructions(name, file, options)
  if ["Layer1", "Layer2", "Layer3"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def interzonal_walls_constructions(name, file, options)
  if ["IntWallIns"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def unfinishedattics_constructions(name, file, options)
  if ["UAAdditionalCeilingIns", "UATrussandIns"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def finishedroof_constructions(name, file, options)
  if ["RoofIns"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def slab_constructions(name, file, options)
  if ["Mat-Fic-Slab"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def crawlspace_constructions(name, file, options)
  if ["CFloor-FicR", "CSJoistandCavity", "CWall-FicR", "CWallIns", "CrawlCeilingIns"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def ufbsmt_constructions(name, file, options)
  if ["UFBaseWall-FicR", "UFBaseFloor-FicR", "UFBsmtJoistandCavity", "UFBaseWallIns", "UFBsmtCeilingIns"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def fbsmt_constructions(name, file, options)
  if ["FBaseWall-FicR", "FBaseWallIns", "FBaseFloor-FicR", "FBsmtJoistandCavity"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def interzonal_floors_constructions(name, file, options)
  if ["IntFloorIns"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def carpet_constructions(name, file, options)
  if ["CarpetBareLayer", "SlabCarpetBareEquivalentMaterial"].include? name
    name = "#{name}_#{options[File.basename(file)]}"
  end
  return name
end

def get_nom_cav_r(option)
  nomcavr = nil
  strsplit = "#{option}".split(" ")
  strsplit.each_with_index do |str,i|
    if str.include? "R-" and ["Fiberglass", "Fiberglass,", "Cellulose,", "Spray", "Closed", "SIP", "SIPs"].include? strsplit[i+1]
      nomcavr = str.gsub("R-","")
    end
  end
  return nomcavr
end

def get_stud_width(option)
  studwidth = nil
  strsplit = "#{option}".split(" ")
  strsplit.each do |str|
    if str.include? "x"
      studwidth = {"2x4"=>"3.5",
                   "2x6"=>"5.5",
                   "2x8"=>"7.5",
                   "2x10"=>"9.5",
                   "2x12"=>"11.5",
                   "2x14"=>"13.5"
      }[str.gsub(",","")]
    end
  end
  return studwidth
end

def get_stud_spacing(studwidth)
  studspacing = nil
  studspacing = {"3.5"=>"16",
                 "5.5"=>"24"
  }[studwidth]
  return studspacing
end

$materialslist = ["2x4", "2x6", "AddforCTFCalc", "CarpetLayer", "Concrete-4in", "Concrete-8in", "DoorMaterial", "GarageDoorMaterial", "GypsumBoard-1_2in", "Plywood-1_2in", "Plywood-3_2in", "Plywood-3_4in", "Soil-12in", "WoodFlooring", "SlabMass", "LivingFurnitureMaterial", "GarageFurnitureMaterial", "UBsmtFurnitureMaterial", "FBsmtFurnitureMaterial", "RadiantBarrier", "Adiabatic", "GrgRoofStudandAir", "StudandAirWall", "StudandAirRoof", "StudandAirFloor"]
$noadds = ["2x", "AddforCTFCalc", "CarpetBareLayer", "ExteriorFinish", "FloorMass", "GrgRoofStudandAir", "GypsumBoard-Ceiling", "GypsumBoard-ExtWall", "IntSheathing", "IntWallIns", "IntWallRigidIns", "Mat-Fic-Slab", "PartitionWallMass", "RigidRoofIns", "RoofingMaterial", "RoofIns", "SlabSoil-12in", "SlabCarpetBareEquivalentMaterial", "StudandAirFloor", "StudandAirRoof", "StudandAirWall", "StudandCavity", "UAAdditionalCeilingIns", "UARigidRoofIns", "UARoofIns", "UATrussandIns", "UBsmtFurnitureMaterial", "FBsmtFurnitureMaterial"]

db = SQLite3::Database.new 'C:/OpenStudioLocal/Measures.sqlite'

# Write rows of the excel file
db.results_as_hash = true
$r = 2
names = []
db.execute("select * from CategoryGroup").each do |row1|
  groupname = row1["GroupName"]
  categorygroupid = row1["CategoryGroupID"]
  # Walls
  if groupname == "Walls"
    db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
      categoryname = row2["CategoryName"]
      # Wood Stud
      if categoryname == "Wood Stud"
        foldername = "#{groupname}_#{categoryname}"
        walls_woodstud = { "01.idf"=>"Uninsulated, 2x4, 16 in o.c.",
                           "02.idf"=>"Uninsulated, 2x6, 24 in o.c.",
                           "03.idf"=>"R-7 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                           "04.idf"=>"R-7 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                           "05.idf"=>"R-7 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                           "06.idf"=>"R-11 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                           "07.idf"=>"R-11 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                           "08.idf"=>"R-11 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                           "09.idf"=>"R-13 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                           "10.idf"=>"R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                           "11.idf"=>"R-13 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                           "12.idf"=>"R-15 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                           "13.idf"=>"R-15 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                           "14.idf"=>"R-15 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                           "15.idf"=>"R-19 Fiberglass Batt, Gr-3, 2x6, 24 in o.c.",
                           "16.idf"=>"R-19 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                           "17.idf"=>"R-19 Fiberglass Batt, Gr-1, 2x6, 24 in o.c.",
                           "18.idf"=>"R-21 Fiberglass Batt, Gr-3, 2x6, 24 in o.c.",
                           "19.idf"=>"R-21 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                           "20.idf"=>"R-21 Fiberglass Batt, Gr-1, 2x6, 24 in o.c.",
                           "21.idf"=>"R-13 Cellulose, Gr-3, 2x4, 16 in o.c.",
                           "22.idf"=>"R-13 Cellulose, Gr-2, 2x4, 16 in o.c.",
                           "23.idf"=>"R-13 Cellulose, Gr-1, 2x4, 16 in o.c.",
                           "24.idf"=>"R-19 Cellulose, Gr-3, 2x6, 24 in o.c.",
                           "25.idf"=>"R-19 Cellulose, Gr-2, 2x6, 24 in o.c.",
                           "26.idf"=>"R-19 Cellulose, Gr-1, 2x6, 24 in o.c.",
                           "27.idf"=>"R-13 Fiberglass, Gr-3, 2x4, 16 in o.c.",
                           "28.idf"=>"R-13 Fiberglass, Gr-2, 2x4, 16 in o.c.",
                           "29.idf"=>"R-13 Fiberglass, Gr-1, 2x4, 16 in o.c.",
                           "30.idf"=>"R-19 Fiberglass, Gr-3, 2x6, 24 in o.c.",
                           "31.idf"=>"R-19 Fiberglass, Gr-2, 2x6, 24 in o.c.",
                           "32.idf"=>"R-19 Fiberglass, Gr-1, 2x6, 24 in o.c.",
                           "33.idf"=>"R-23 Spray Foam, Gr-3, 2x4, 16 in o.c.",
                           "34.idf"=>"R-23 Spray Foam, Gr-2, 2x4, 16 in o.c.",
                           "35.idf"=>"R-23 Spray Foam, Gr-1, 2x4, 16 in o.c.",
                           "36.idf"=>"R-36 Spray Foam, Gr-3, 2x6, 24 in o.c.",
                           "37.idf"=>"R-36 Spray Foam, Gr-2, 2x6, 24 in o.c.",
                           "38.idf"=>"R-36 Spray Foam, Gr-1, 2x6, 24 in o.c."
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            $thermalresistance = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material," or "+#{line}".include? "+Material:NoMass,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                  $thermalresistance = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Resistance {m2-K/W)"
                    $thermalresistance = val_prop[0].gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = wood_stud_constructions($name, file, walls_woodstud)
                $nomcavr = get_nom_cav_r(walls_woodstud[File.basename(file)])
                $studwidth = get_stud_width(walls_woodstud[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "StudandCavity"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 12).Value = $studspacing
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              elsif $name != nil and $roughness != nil and $thermalresistance != nil
                if not names.include? $name
                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end
                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 7).Value = $thermalresistance.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # Double Wood Stud
      elsif categoryname == "Double Wood Stud"
        foldername = "#{groupname}_#{categoryname}"
        walls_doublewoodstud = { "01.idf"=>"R-33 Fiberglass Batt, 2x4 Centered, 24 in o.c.",
                                 "02.idf"=>"R-33 Fiberglass Batt, 2x4 Staggered, 24 in o.c.",
                                 "03.idf"=>"R-39 Fiberglass Batt, 2x4 Centered, 24 in o.c.",
                                 "04.idf"=>"R-39 Fiberglass Batt, 2x4 Staggered, 24 in o.c.",
                                 "05.idf"=>"R-45 Fiberglass Batt, 2x4 Centered, 24 in o.c.",
                                 "06.idf"=>"R-45 Fiberglass Batt, 2x4 Staggered, 24 in o.c.",
                                 "07.idf"=>"R-33 Cellulose, 2x4 Centered, 24 in o.c.",
                                 "08.idf"=>"R-33 Cellulose, 2x4 Staggered, 24 in o.c.",
                                 "09.idf"=>"R-39 Cellulose, 2x4 Centered, 24 in o.c.",
                                 "10.idf"=>"R-39 Cellulose, 2x4 Staggered, 24 in o.c.",
                                 "11.idf"=>"R-45 Cellulose, 2x4 Centered, 24 in o.c.",
                                 "12.idf"=>"R-45 Cellulose, 2x4 Staggered, 24 in o.c.",
                                 "13.idf"=>"R-33 Fiberglass, 2x4 Centered, 24 in o.c.",
                                 "14.idf"=>"R-33 Fiberglass, 2x4 Staggered, 24 in o.c.",
                                 "15.idf"=>"R-39 Fiberglass, 2x4 Centered, 24 in o.c.",
                                 "16.idf"=>"R-39 Fiberglass, 2x4 Staggered, 24 in o.c.",
                                 "17.idf"=>"R-45 Fiberglass, 2x4 Centered, 24 in o.c.",
                                 "18.idf"=>"R-45 Fiberglass, 2x4 Staggered, 24 in o.c."
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = double_stud_constructions($name, file, walls_doublewoodstud)
                $nomcavr = get_nom_cav_r(walls_doublewoodstud[File.basename(file)])
                $studwidth = get_stud_width(walls_doublewoodstud[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "StudandCavity" or $name.include? "Cavity"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 12).Value = $studspacing
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # CMU
      elsif categoryname == "CMU"
        foldername = "#{groupname}_#{categoryname}"
        walls_cmu = { "01.idf"=>"6-in Concrete Filled",
                      "02.idf"=>"6-in Concrete Filled, R-10 XPS",
                      "03.idf"=>"6-in Concrete Filled, R-12 Polyiso",
                      "04.idf"=>"6-in Concrete Filled, R-13 Closed Cell Spray Foam",
                      "05.idf"=>"6-in Concrete Filled, R-19 Fiberglass Batt, 2x6, 24 in o.c.",
                      "06.idf"=>"6-in Hollow",
                      "07.idf"=>"6-in Hollow, R-10 XPS",
                      "08.idf"=>"6-in Hollow, R-12 Polyiso",
                      "09.idf"=>"6-in Hollow, R-13 Closed Cell Spray Foam",
                      "10.idf"=>"6-in Hollow, R-19 Fiberglass Batt, 2x6, 24 in o.c.",
                      "11.idf"=>"8-in Hollow",
                      "12.idf"=>"8-in Hollow, R-10 XPS",
                      "13.idf"=>"8-in Hollow, R-12 Polyiso",
                      "14.idf"=>"8-in Hollow, R-13 Closed Cell Spray Foam",
                      "15.idf"=>"8-in Hollow, R-19 Fiberglass Batt, 2x6, 24 in o.c.",
                      "16.idf"=>"12-in Hollow",
                      "17.idf"=>"12-in Hollow, R-10 XPS",
                      "18.idf"=>"12-in Hollow, R-12 Polyiso",
                      "19.idf"=>"12-in Hollow, R-13 Closed Cell Spray Foam",
                      "20.idf"=>"12-in Hollow, R-19 Fiberglass Batt, 2x6, 24 in o.c.",
                      "21.idf"=>"6-in Perlite Filled",
                      "22.idf"=>"6-in Perlite Filled, R-10 XPS",
                      "23.idf"=>"6-in Perlite Filled, R-12 Polyiso",
                      "24.idf"=>"6-in Perlite Filled, R-13 Closed Cell Spray Foam",
                      "25.idf"=>"6-in Perlite Filled, R-19 Fiberglass Batt, 2x6, 24 in o.c."
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = cmu_constructions($name, file, walls_cmu)
                $nomcavr = get_nom_cav_r(walls_cmu[File.basename(file)])
                $studwidth = get_stud_width(walls_cmu[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # SIP
      elsif categoryname == "SIP"
        foldername = "#{groupname}_#{categoryname}"
        walls_sip = { "1.idf"=>"3.6 in EPS Core, OSB int.",
                      "2.idf"=>"5.6 in EPS Core, OSB int.",
                      "3.idf"=>"7.4 in EPS Core, OSB int.",
                      "4.idf"=>"9.4 in EPS Core, OSB int.",
                      "5.idf"=>"3.6 in EPS Core, Gypsum int.",
                      "6.idf"=>"5.6 in EPS Core, Gypsum int.",
                      "7.idf"=>"7.4 in EPS Core, Gypsum int.",
                      "8.idf"=>"9.4 in EPS Core, Gypsum int."
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = sip_constructions($name, file, walls_sip)
                $nomcavr = get_nom_cav_r(walls_sip[File.basename(file)])
                $studwidth = get_stud_width(walls_sip[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # ICF
      elsif categoryname == "ICF"
        foldername = "#{groupname}_#{categoryname}"
        walls_icf = { "1.idf"=>'2" EPS, 4" Concrete, 2" EPS',
                      "2.idf"=>'2" EPS, 8" Concrete, 2" EPS',
                      "3.idf"=>'2" EPS, 12" Concrete, 2" EPS',
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = icf_constructions($name, file, walls_icf)
                $nomcavr = get_nom_cav_r(walls_icf[File.basename(file)])
                $studwidth = get_stud_width(walls_icf[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # Other
      elsif categoryname == "Other"
        foldername = "#{groupname}_#{categoryname}"
        walls_other = { "1.idf"=>"T-Mass Wall w/ Metal Ties (ORNL)",
                        "2.idf"=>"T-Mass Wall w/ Plastic Ties (ORNL)",
                        "3.idf"=>'10" Grid ICF (ORNL)',
                        "4.idf"=>"Superinsulated"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = other_constructions($name, file, walls_other)
                $nomcavr = get_nom_cav_r(walls_other[File.basename(file)])
                $studwidth = get_stud_width(walls_other[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # Wall Sheathing
      elsif categoryname == "Wall Sheathing"
        foldername = "#{groupname}_#{categoryname}"
        walls_wallsheathing = { "01.idf"=>"OSB",
                                "02.idf"=>"R-5 XPS",
                                "03.idf"=>"R-10 XPS",
                                "04.idf"=>"R-15 XPS",
                                "05.idf"=>"R-6 Polyiso",
                                "06.idf"=>"R-12 Polyiso",
                                "07.idf"=>"OSB, R-5 XPS",
                                "08.idf"=>"OSB, R-10 XPS",
                                "09.idf"=>"OSB, R-15 XPS",
                                "10.idf"=>"OSB, R-6 Polyiso",
                                "11.idf"=>"OSB, R-12 Polyiso"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $name.include? "WallRigidIns" and not walls_wallsheathing[File.basename(file)].include? "OSB"
                    ws.Cells($r, 2).Value = "Material"
                    $name = "Wall Sheathing-#{walls_wallsheathing[File.basename(file)]}, #{OpenStudio::convert($thickness.to_f,"m","in").get.round(1)}-in"
                  else
                    next
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # Exterior Finish
      elsif categoryname == "Exterior Finish"
        foldername = "#{groupname}_#{categoryname}"
        walls_exteriorfinish = { "01.idf"=>"Stucco, Medium/Dark",
                                 "02.idf"=>"Brick, Light",
                                 "03.idf"=>"Brick, Medium/Dark",
                                 "04.idf"=>"Wood, Light",
                                 "05.idf"=>"Wood, Medium/Dark",
                                 "06.idf"=>"Aluminum, Light",
                                 "07.idf"=>"Aluminum, Medium/Dark",
                                 "08.idf"=>"Vinyl, Light",
                                 "09.idf"=>"Vinyl, Medium/Dark",
                                 "10.idf"=>"Fiber-Cement, Light",
                                 "11.idf"=>"Fiber-Cement, Medium/Dark"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Absorptance"
                    $thermalabs = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Solar Absorptance"
                    $solarabs = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Visible Absorptance"
                    $visibleabs = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil and $thermalabs != nil and $solarabs != nil and $visibleabs != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $name.include? "ExteriorFinish"
                    ws.Cells($r, 2).Value = "Material"
                    $name = "Exterior Finish-#{walls_exteriorfinish[File.basename(file)]}"
                  else
                    next
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s
                  ws.Cells($r, 25).Value = $thermalabs.to_s
                  ws.Cells($r, 26).Value = $solarabs.to_s
                  ws.Cells($r, 27).Value = $visibleabs.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end
            f.close
          end
        end
      # Interzonal Walls
      elsif categoryname == "Interzonal Walls"
        foldername = "#{groupname}_#{categoryname}"
        walls_interzonalwall = { "01.idf"=>"Uninsulated, 2x4, 16 in o.c.",
                                 "02.idf"=>"Uninsulated, 2x6, 24 in o.c.",
                                 "03.idf"=>"R-7 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                                 "04.idf"=>"R-7 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                 "05.idf"=>"R-7 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                                 "06.idf"=>"R-11 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                                 "07.idf"=>"R-11 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                 "08.idf"=>"R-11 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                                 "09.idf"=>"R-13 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                                 "10.idf"=>"R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                 "11.idf"=>"R-13 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                                 "12.idf"=>"R-15 Fiberglass Batt, Gr-3, 2x4, 16 in o.c.",
                                 "13.idf"=>"R-15 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                 "14.idf"=>"R-15 Fiberglass Batt, Gr-1, 2x4, 16 in o.c.",
                                 "15.idf"=>"R-19 Fiberglass Batt, Gr-3, 2x6, 24 in o.c.",
                                 "16.idf"=>"R-19 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                                 "17.idf"=>"R-19 Fiberglass Batt, Gr-1, 2x6, 24 in o.c.",
                                 "18.idf"=>"R-21 Fiberglass Batt, Gr-3, 2x6, 24 in o.c.",
                                 "19.idf"=>"R-21 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                                 "20.idf"=>"R-21 Fiberglass Batt, Gr-1, 2x6, 24 in o.c.",
                                 "21.idf"=>"R-13 Fiberglass Batt, Gr-3, 2x4, 16 in o.c., R-5 XPS",
                                 "22.idf"=>"R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c., R-5 XPS",
                                 "23.idf"=>"R-13 Fiberglass Batt, Gr-1, 2x4, 16 in o.c., R-5 XPS",
                                 "24.idf"=>"R-13 Fiberglass Batt, Gr-3, 2x4, 16 in o.c., R-6 Polyiso",
                                 "25.idf"=>"R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c., R-6 Polyiso",
                                 "26.idf"=>"R-13 Fiberglass Batt, Gr-1, 2x4, 16 in o.c., R-6 Polyiso",
                                 "27.idf"=>"R-19 Fiberglass Batt, Gr-3, 2x6, 24 in o.c., R-5 XPS",
                                 "28.idf"=>"R-19 Fiberglass Batt, Gr-2, 2x6, 24 in o.c., R-5 XPS",
                                 "29.idf"=>"R-19 Fiberglass Batt, Gr-1, 2x6, 24 in o.c., R-5 XPS",
                                 "30.idf"=>"R-19 Fiberglass Batt, Gr-3, 2x6, 24 in o.c., R-6 Polyiso",
                                 "31.idf"=>"R-19 Fiberglass Batt, Gr-2, 2x6, 24 in o.c., R-6 Polyiso",
                                 "32.idf"=>"R-19 Fiberglass Batt, Gr-1, 2x6, 24 in o.c., R-6 Polyiso",
                                 "33.idf"=>"R-13 Cellulose, Gr-3, 2x4, 16 in o.c.",
                                 "34.idf"=>"R-13 Cellulose, Gr-2, 2x4, 16 in o.c.",
                                 "35.idf"=>"R-13 Cellulose, Gr-1, 2x4, 16 in o.c.",
                                 "36.idf"=>"R-19 Cellulose, Gr-3, 2x6, 24 in o.c.",
                                 "37.idf"=>"R-19 Cellulose, Gr-2, 2x6, 24 in o.c.",
                                 "38.idf"=>"R-19 Cellulose, Gr-1, 2x6, 24 in o.c.",
                                 "39.idf"=>"R-13 Fiberglass, Gr-3, 2x4, 16 in o.c.",
                                 "40.idf"=>"R-13 Fiberglass, Gr-2, 2x4, 16 in o.c.",
                                 "41.idf"=>"R-13 Fiberglass, Gr-1, 2x4, 16 in o.c.",
                                 "42.idf"=>"R-19 Fiberglass, Gr-3, 2x6, 24 in o.c.",
                                 "43.idf"=>"R-19 Fiberglass, Gr-2, 2x6, 24 in o.c.",
                                 "44.idf"=>"R-19 Fiberglass, Gr-1, 2x6, 24 in o.c.",
                                 "45.idf"=>"R-23 Spray Foam, Gr-3, 2x4, 16 in o.c.",
                                 "46.idf"=>"R-23 Spray Foam, Gr-2, 2x4, 16 in o.c.",
                                 "47.idf"=>"R-23 Spray Foam, Gr-1, 2x4, 16 in o.c.",
                                 "48.idf"=>"R-36 Spray Foam, Gr-3, 2x6, 24 in o.c.",
                                 "49.idf"=>"R-36 Spray Foam, Gr-2, 2x6, 24 in o.c.",
                                 "50.idf"=>"R-36 Spray Foam, Gr-1, 2x6, 24 in o.c."
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = interzonal_walls_constructions($name, file, walls_interzonalwall)
                $nomcavr = get_nom_cav_r(walls_interzonalwall[File.basename(file)])
                $studwidth = get_stud_width(walls_interzonalwall[File.basename(file)])
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "StudandCavity"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 12).Value = $studspacing
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      else
        puts "#{groupname} - #{categoryname} skipped."
      end # end of if categoryname == "Wood Stud"
    end # end of db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
  # Ceilings/Roofs
  elsif groupname == "Ceilings/Roofs"
    groupname = "CeilingsRoofs"
    db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
      categoryname = row2["CategoryName"]
      # Unfinished Attic
      if categoryname == "Unfinished Attic"
        foldername = "#{groupname}_#{categoryname}"
        ceilingsroofs_unfinishedattic = { "01.idf"=>"Uninsulated, Vented",
                                          "02.idf"=>"Ceiling R-11 Fiberglass, Vented",
                                          "03.idf"=>"Ceiling R-19 Fiberglass, Vented",
                                          "04.idf"=>"Ceiling R-21 Fiberglass, Vented",
                                          "05.idf"=>"Ceiling R-25 Fiberglass, Vented",
                                          "06.idf"=>"Ceiling R-30 Fiberglass, Vented",
                                          "07.idf"=>"Ceiling R-38 Fiberglass, Vented",
                                          "08.idf"=>"Ceiling R-44 Fiberglass, Vented",
                                          "09.idf"=>"Ceiling R-49 Fiberglass, Vented",
                                          "10.idf"=>"Ceiling R-60 Fiberglass, Vented",
                                          "11.idf"=>"Ceiling R-11 Cellulose, Vented",
                                          "12.idf"=>"Ceiling R-19 Cellulose, Vented",
                                          "13.idf"=>"Ceiling R-21 Cellulose, Vented",
                                          "14.idf"=>"Ceiling R-25 Cellulose, Vented",
                                          "15.idf"=>"Ceiling R-30 Cellulose, Vented",
                                          "16.idf"=>"Ceiling R-38 Cellulose, Vented",
                                          "17.idf"=>"Ceiling R-44 Cellulose, Vented",
                                          "18.idf"=>"Ceiling R-49 Cellulose, Vented",
                                          "19.idf"=>"Ceiling R-60 Cellulose, Vented",
                                          "20.idf"=>"Ceiling R-30 Fiberglass Batt, Vented",
                                          "21.idf"=>"Ceiling R-38 Fiberglass Batt, Vented",
                                          "22.idf"=>"Ceiling R-49 Fiberglass Batt, Vented",
                                          "23.idf"=>"Ceiling R-19 Closed Cell Spray Foam, Vented",
                                          "24.idf"=>"Ceiling R-30 Closed Cell Spray Foam, Vented",
                                          "25.idf"=>"Ceiling R-38 Closed Cell Spray Foam, Vented",
                                          "26.idf"=>"Ceiling R-49 Closed Cell Spray Foam, Vented",
                                          "27.idf"=>"Ceiling R-60 Closed Cell Spray Foam, Vented",
                                          "28.idf"=>"Roof R-19 Fiberglass Batt",
                                          "29.idf"=>"Roof R-30 Fiberglass Batt",
                                          "30.idf"=>"Roof R-38 Fiberglass Batt",
                                          "31.idf"=>"Roof R-38 Fiberglass Batt, R-24 Polyiso",
                                          "32.idf"=>"Roof R-38 Fiberglass Batt, R-25 XPS",
                                          "33.idf"=>"Roof R-19 Closed Cell Spray Foam",
                                          "34.idf"=>"Roof R-30 Closed Cell Spray Foam",
                                          "35.idf"=>"Roof R-38 Closed Cell Spray Foam",
                                          "36.idf"=>"Roof R-49 Closed Cell Spray Foam",
                                          "37.idf"=>"Roof R-60 Closed Cell Spray Foam",
                                          "38.idf"=>"Roof R-27.5 SIP",
                                          "39.idf"=>"Roof R-37.5 SIP",
                                          "40.idf"=>"Roof R-47.5 SIP"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = unfinishedattics_constructions($name, file, ceilingsroofs_unfinishedattic)
                $nomcavr = get_nom_cav_r(ceilingsroofs_unfinishedattic[File.basename(file)])
                $studwidth = "3.5"
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "UATrussandIns"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Roof Material
      elsif categoryname == "Roof Material"
        foldername = "#{groupname}_#{categoryname}"
        ceilingsroofs_roofmaterial = { "01.idf"=>"Asphalt Shingles, Dark",
                                       "02.idf"=>"Asphalt Shingles, Medium",
                                       "03.idf"=>"Asphalt Shingles, Light",
                                       "04.idf"=>"Asphalt Shingles, White or cool colors",
                                       "05.idf"=>"Tile, Dark",
                                       "06.idf"=>"Tile, Medium (Mottled, Terra Cotta, Buff)",
                                       "07.idf"=>"Tile, Light",
                                       "08.idf"=>"Tile, White",
                                       "09.idf"=>"Metal, Dark",
                                       "10.idf"=>"Metal, Medium",
                                       "11.idf"=>"Metal, Light",
                                       "12.idf"=>"Metal, White",
                                       "13.idf"=>"Galvanized Steel"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Absorptance"
                    $thermalabs = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Solar Absorptance"
                    $solarabs = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Visible Absorptance"
                    $visibleabs = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil and $thermalabs != nil and $solarabs != nil and $visibleabs != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $name.include? "RoofingMaterial"
                    ws.Cells($r, 2).Value = "Material"
                    $name = "Roofing Material-#{ceilingsroofs_roofmaterial[File.basename(file)]}"
                  else
                    next
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s
                  ws.Cells($r, 25).Value = $thermalabs.to_s
                  ws.Cells($r, 26).Value = $solarabs.to_s
                  ws.Cells($r, 27).Value = $visibleabs.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      elsif categoryname == "Finished Roof"
        foldername = "#{groupname}_#{categoryname}"
        ceilingsroofs_finishedroof = { "01.idf"=>"Uninsulated, 2x4",
                                       "02.idf"=>"Uninsulated, 2x6",
                                       "03.idf"=>"Uninsulated, 2x8",
                                       "04.idf"=>"Uninsulated, 2x10",
                                       "05.idf"=>"Uninsulated, 2x12",
                                       "06.idf"=>"Uninsulated, 2x10, R-15 XPS",
                                       "07.idf"=>"Uninsulated, 2x10, R-20 XPS",
                                       "08.idf"=>"Uninsulated, 2x10, R-25 XPS",
                                       "09.idf"=>"R-13 Fiberglass Batt, 2x4",
                                       "10.idf"=>"R-19 Fiberglass Batt, 2x6",
                                       "11.idf"=>"R-19 Fiberglass Batt, 2x8",
                                       "12.idf"=>"R-19 Fiberglass, Batt, 2x10",
                                       "13.idf"=>"R-30C Fiberglass Batt, 2x8",
                                       "14.idf"=>"R-30C Fiberglass Batt, 2x10",
                                       "15.idf"=>"R-30 Fiberglass Batt, 2x10",
                                       "16.idf"=>"R-30 Fiberglass, Batt, 2x12",
                                       "17.idf"=>"R-38 Fiberglass Batt, 2x10",
                                       "18.idf"=>"R-38 Fiberglass Batt, 2x12",
                                       "19.idf"=>"R-38 Fiberglass Batt, 2x14",
                                       "20.idf"=>"R-38C Fiberglass Batt, 2x10",
                                       "21.idf"=>"R-38C Fiberglass, Batt, 2x12",
                                       "22.idf"=>"R-38C Fiberglass Batt, 2x10, R-24 Polyiso",
                                       "23.idf"=>"R-38C Fiberglass Batt, 2x10, R-25 XPS",
                                       "24.idf"=>"R-30 + R-19 Fiberglass Batt",
                                       "25.idf"=>"R-13 Fiberglass, 2x4",
                                       "26.idf"=>"R-13 Fiberglass, 2x4, R-15 XPS",
                                       "27.idf"=>"R-13 Fiberglass, 2x4, R-20 XPS",
                                       "28.idf"=>"R-13 Fiberglass, 2x4, R-25 XPS",
                                       "29.idf"=>"R-19 Fiberglass, 2x6",
                                       "30.idf"=>"R-19 Fiberglass, 2x6, R-15 XPS",
                                       "31.idf"=>"R-19 Fiberglass, 2x6, R-20 XPS",
                                       "32.idf"=>"R-19 Fiberglass, 2x6, R-25 XPS",
                                       "33.idf"=>"R-30 Fiberglass, 2x8",
                                       "34.idf"=>"R-30 Fiberglass, 2x8, R-15 XPS",
                                       "35.idf"=>"R-30 Fiberglass, 2x8, R-20 XPS",
                                       "36.idf"=>"R-30 Fiberglass, 2x8, R-25 XPS",
                                       "37.idf"=>"R-38 Fiberglass, 2x10",
                                       "38.idf"=>"R-38 Fiberglass, 2x10, R-15 XPS",
                                       "39.idf"=>"R-38 Fiberglass, 2x10, R-20 XPS",
                                       "40.idf"=>"R-38 Fiberglass, 2x10, R-25 XPS",
                                       "41.idf"=>"R-49 Fiberglass, 2x12",
                                       "42.idf"=>"R-49 Fiberglass, 2x12, R-15 XPS",
                                       "43.idf"=>"R-49 Fiberglass, 2x12, R-20 XPS",
                                       "44.idf"=>"R-49 Fiberglass, 2x12, R-25 XPS",
                                       "45.idf"=>"R-27.5 SIPs",
                                       "46.idf"=>"R-37.5 SIPs",
                                       "47.idf"=>"R-47.5 SIPs"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = finishedroof_constructions($name, file, ceilingsroofs_finishedroof)
                $nomcavr = get_nom_cav_r(ceilingsroofs_finishedroof[File.basename(file)])
                if $nomcavr == "30C"
                  $nomcavr = "30"
                elsif $nomcavr == "38C"
                  $nomcavr = "38"
                end
                $studwidth = get_stud_width(ceilingsroofs_finishedroof)
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Radiant Barrier
      elsif categoryname == "Radiant Barrier"
        foldername = "#{groupname}_#{categoryname}"
        ceilingsroofs_radiantbarrier = { "1.idf"=>"Double-Sided, Foil"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $name.include? "RadiantBarrier"
                    ws.Cells($r, 2).Value = "Material"
                    $name = "Radiant Barrier-#{ceilingsroofs_radiantbarrier[File.basename(file)]}"
                  else
                    next
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      else
        puts "#{groupname} - #{categoryname} skipped."
      end # end of if categoryname == "Unfinished Attic"
    end # end of db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
  # Foundation/Floors
  elsif groupname == "Foundation/Floors"
    groupname = "FoundationFloors"
    db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
      categoryname = row2["CategoryName"]
      # Slab
      if categoryname == "Slab"
        foldername = "#{groupname}_#{categoryname}"
        foundationfloors_slab = { "01.idf"=>"Uninsulated",
                                  "02.idf"=>"2ft R5 Perimeter, R5 Gap XPS",
                                  "03.idf"=>"2ft R10 Perimeter, R5 Gap XPS",
                                  "04.idf"=>"4ft R5 Perimeter, R5 Gap XPS",
                                  "05.idf"=>"4ft R10 Perimeter, R5 Gap XPS",
                                  "06.idf"=>"2ft R5 Exterior XPS",
                                  "07.idf"=>"2ft R10 Exterior XPS",
                                  "08.idf"=>"4ft R5 Exterior XPS",
                                  "09.idf"=>"4ft R10 Exterior XPS",
                                  "10.idf"=>"4ft R15 Exterior XPS",
                                  "11.idf"=>"4ft R20 Exterior XPS",
                                  "12.idf"=>"Whole Slab R10, R5 Gap XPS",
                                  "13.idf"=>"Whole Slab R10, R10 Gap XPS",
                                  "14.idf"=>"Whole Slab R20, R5 Gap XPS",
                                  "15.idf"=>"Whole Slab R20, R10 Gap XPS",
                                  "16.idf"=>"Whole Slab R30, R10 Gap XPS",
                                  "17.idf"=>"Whole Slab R40, R10 Gap XPS"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = slab_constructions($name, file, foundationfloors_slab)
                $nomcavr = get_nom_cav_r(foundationfloors_slab[File.basename(file)])
                $studwidth = get_stud_width(foundationfloors_slab)
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Crawlspace
      elsif categoryname == "Crawlspace"
        foldername = "#{groupname}_#{categoryname}"
        foundationfloors_crawlspace = { "01.idf"=>"Uninsulated",
                                        "02.idf"=>"Wall R-5 XPS",
                                        "03.idf"=>"Wall R-10 XPS",
                                        "04.idf"=>"Wall R-15 XPS",
                                        "05.idf"=>"Wall R-20 XPS",
                                        "06.idf"=>"Wall R-6 Polyiso",
                                        "07.idf"=>"Wall R-12 Polyiso",
                                        "08.idf"=>"Wall R-18 Polyiso",
                                        "09.idf"=>"Wall R-11 Fiberglass Batt",
                                        "10.idf"=>"Wall R-13 Fiberglass Batt",
                                        "11.idf"=>"Wall R-19 Fiberglass Batt",
                                        "12.idf"=>"Wall R-21 Fiberglass Batt",
                                        "13.idf"=>"Ceiling R-13 Fiberglass Batt",
                                        "14.idf"=>"Ceiling R-19 Fiberglass Batt",
                                        "15.idf"=>"Ceiling R-30 Fiberglass Batt",
                                        "16.idf"=>"Ceiling R-38 Fiberglass Batt",
                                        "17.idf"=>"Ceiling R-13 Closed Cell Spray Foam",
                                        "18.idf"=>"Ceiling R-19 Closed Cell Spray Foam",
                                        "19.idf"=>"Ceiling R-30 Closed Cell Spray Foam",
                                        "20.idf"=>"Ceiling R-38 Closed Cell Spray Foam"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            $thermalresistance = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material," or "+#{line}".include? "+Material:NoMass,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                  $thermalresistance = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Resistance {m2-K/W)"
                    $thermalresistance = val_prop[0].gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = crawlspace_constructions($name, file, foundationfloors_crawlspace)
                $nomcavr = get_nom_cav_r(foundationfloors_crawlspace[File.basename(file)])
                $studwidth = "9.25"
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "CSJoistandCavity"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 12).Value = $studspacing
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              elsif $name != nil and $roughness != nil and $thermalresistance != nil

                $name = crawlspace_constructions($name, file, foundationfloors_crawlspace)

                if not names.include? $name
                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end
                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 7).Value = $thermalresistance.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Unfinished Basement
      elsif categoryname == "Unfinished Basement"
        foldername = "#{groupname}_#{categoryname}"
        foundationfloors_ufbsmt = { "01.idf"=>"Uninsulated",
                                    "02.idf"=>"Half Wall R-5 XPS",
                                    "03.idf"=>"Half Wall R-10 XPS",
                                    "04.idf"=>"Half Wall R-6 Polyiso",
                                    "05.idf"=>"Half Wall R-12 Polyiso",
                                    "06.idf"=>"Whole Wall R-5 XPS",
                                    "07.idf"=>"Whole Wall R-10 XPS",
                                    "08.idf"=>"Whole Wall R-15 XPS",
                                    "09.idf"=>"Whole Wall R-20 XPS",
                                    "10.idf"=>"Whole Wall R-6 Polyiso",
                                    "11.idf"=>"Whole Wall R-12 Polyiso",
                                    "12.idf"=>"Whole Wall R-18 Polyiso",
                                    "13.idf"=>"Whole Wall R-11 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                    "14.idf"=>"Whole Wall R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                    "15.idf"=>"Whole Wall R-19 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                                    "16.idf"=>"Whole Wall R-21 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                                    "17.idf"=>"Whole Wall R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c., R-5 XPS",
                                    "18.idf"=>"Whole Wall R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c., R-10 XPS",
                                    "19.idf"=>"Ceiling R-13 Fiberglass Batt",
                                    "20.idf"=>"Ceiling R-19 Fiberglass Batt",
                                    "21.idf"=>"Ceiling R-30 Fiberglass Batt",
                                    "22.idf"=>"Ceiling R-38 Fiberglass Batt"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            $thermalresistance = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material," or "+#{line}".include? "+Material:NoMass,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                  $thermalresistance = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Resistance {m2-K/W)"
                    $thermalresistance = val_prop[0].gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = ufbsmt_constructions($name, file, foundationfloors_ufbsmt)
                $nomcavr = get_nom_cav_r(foundationfloors_ufbsmt[File.basename(file)])
                $studwidth = get_stud_width(foundationfloors_ufbsmt)
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "UFBsmtJoistandCavity"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 12).Value = $studspacing
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              elsif $name != nil and $roughness != nil and $thermalresistance != nil

                $name = ufbsmt_constructions($name, file, foundationfloors_ufbsmt)

                if not names.include? $name
                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end
                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 7).Value = $thermalresistance.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Interzonal Floor
      elsif categoryname == "Interzonal Floor"
        foldername = "#{groupname}_#{categoryname}"
        foundationfloors_intzflr = { "01.idf"=>"Uninsulated",
                                     "02.idf"=>"R-13 Fiberglass Batt",
                                     "03.idf"=>"R-19 Fiberglass Batt",
                                     "04.idf"=>"R-30 Fiberglass Batt",
                                     "05.idf"=>"R-38 Fiberglass Batt",
                                     "06.idf"=>"R-13 Fiberglass",
                                     "07.idf"=>"R-19 Fiberglass",
                                     "08.idf"=>"R-30 Fiberglass",
                                     "09.idf"=>"R-38 Fiberglass",
                                     "10.idf"=>"R-13 Cellulose",
                                     "11.idf"=>"R-19 Cellulose",
                                     "12.idf"=>"R-30 Cellulose",
                                     "13.idf"=>"R-38 Cellulose",
                                     "14.idf"=>"R-23 Spray Foam",
                                     "15.idf"=>"R-36 Spray Foam"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = interzonal_floors_constructions($name, file, foundationfloors_intzflr)
                $nomcavr = get_nom_cav_r(foundationfloors_intzflr[File.basename(file)])
                $studwidth = get_stud_width(foundationfloors_intzflr)
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Finished Basement
      elsif categoryname == "Finished Basement"
        foldername = "#{groupname}_#{categoryname}"
        foundationfloors_fbsmt = { "01.idf"=>"Uninsulated",
                                   "02.idf"=>"Half Wall R-5 XPS",
                                   "03.idf"=>"Half Wall R-10 XPS",
                                   "04.idf"=>"Whole Wall R-5 XPS",
                                   "05.idf"=>"Whole Wall R-10 XPS",
                                   "06.idf"=>"Whole Wall R-15 XPS",
                                   "07.idf"=>"Whole Wall R-20 XPS",
                                   "08.idf"=>"Whole Wall R-11 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                   "09.idf"=>"Whole Wall R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c.",
                                   "10.idf"=>"Whole Wall R-19 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                                   "11.idf"=>"Whole Wall R-21 Fiberglass Batt, Gr-2, 2x6, 24 in o.c.",
                                   "12.idf"=>"Whole Wall R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c., R-5 XPS",
                                   "13.idf"=>"Whole Wall R-13 Fiberglass Batt, Gr-2, 2x4, 16 in o.c., R-10 XPS"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            $thermalresistance = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material," or "+#{line}".include? "+Material:NoMass,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                  $thermalresistance = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Resistance {m2-K/W)"
                    $thermalresistance = val_prop[0].gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = fbsmt_constructions($name, file, foundationfloors_fbsmt)
                $nomcavr = get_nom_cav_r(foundationfloors_fbsmt[File.basename(file)])
                $studwidth = get_stud_width(foundationfloors_fbsmt)
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  if $name.include? "FBsmtJoistandCavity"
                    ws.Cells($r, 11).Value = $studwidth
                    ws.Cells($r, 12).Value = $studspacing
                    ws.Cells($r, 13).Value = $nomcavr
                  end

                  $r += 1
                  names << $name.to_s
                end
              elsif $name != nil and $roughness != nil and $thermalresistance != nil

                $name = fbsmt_constructions($name, file, foundationfloors_fbsmt)

                if not names.include? $name
                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end
                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 7).Value = $thermalresistance.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      # Carpet
      elsif categoryname == "Carpet"
        foldername = "#{groupname}_#{categoryname}"
        foundationfloors_carpet = { "1.idf"=>"0% Carpet",
                                   "2.idf"=>"20% Carpet",
                                   "3.idf"=>"40% Carpet",
                                   "4.idf"=>"60% Carpet",
                                   "5.idf"=>"80% Carpet",
                                   "6.idf"=>"100% Carpet"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            $visibleabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                  $visibleabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                $name = carpet_constructions($name, file, foundationfloors_carpet)
                $nomcavr = get_nom_cav_r(foundationfloors_carpet[File.basename(file)])
                $studwidth = get_stud_width(foundationfloors_carpet)
                $studspacing = get_stud_spacing($studwidth)

                if not names.include? $name

                  ws.Cells($r, 1).Value = groupname.to_s
                  if $materialslist.include? $name
                    ws.Cells($r, 2).Value = "Material"
                  elsif $noadds.include? $name
                    next
                  else
                    ws.Cells($r, 2).Value = categoryname.to_s
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      else
        puts "#{groupname} - #{categoryname} skipped."
      end # end of if categoryname == "Slab"
    end # end of db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
  elsif groupname == "Thermal Mass"
    groupname = "ThermalMass"
    db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
      categoryname = row2["CategoryName"]
      # Floor Mass
      if categoryname == "Floor Mass"
        foldername = "#{groupname}_#{categoryname}"
        thermalmass_floormass = { "1.idf"=>"Wood Surface",
                                  "2.idf"=>"2 in. Gypsum Concrete"
        }
        path = "#{root_path}/lib/#{foldername}"
        Find.find(path) do |file|
          if File.extname(file).include? "idf"
            $newmaterial = false
            f = File.open(file, "r")
            $name = nil
            $roughness = nil
            $thickness = nil
            $conductivity = nil
            $resistance = nil
            $density = nil
            $specificheat = nil
            $thermalabs = nil
            $solarabs = nil
            f.each_line do |line|
              line = line.strip
              if "+#{line}".include? "+Material,"
                $newmaterial = true
              end
              if $newmaterial == true
                if line.empty?
                  $newmaterial = false
                  $name = nil
                  $roughness = nil
                  $thickness = nil
                  $conductivity = nil
                  $resistance = nil
                  $density = nil
                  $specificheat = nil
                  $thermalabs = nil
                  $solarabs = nil
                else
                  val_prop = line.split("!- ")
                  if val_prop[1] == "Name"
                    $name = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Roughness"
                    $roughness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Thickness {m}"
                    $thickness = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Conductivity {W/m-K}"
                    $conductivity = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m^3}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Density {kg/m}"
                    $density = val_prop[0].gsub(",","").strip
                  elsif val_prop[1] == "Specific Heat {J/kg-K}"
                    $specificheat = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Thermal Absorptance"
                    $thermalabs = val_prop[0].gsub(",","").gsub(";","").strip
                  elsif val_prop[1] == "Solar Absorptance"
                    $solarabs = val_prop[0].gsub(",","").gsub(";","").strip
                  end
                end
              end

              if $name != nil and $roughness != nil and $thickness != nil and $conductivity != nil and $density != nil and $specificheat != nil and $thermalabs != nil and $solarabs != nil
                $resistance = $thickness.to_f / $conductivity.to_f

                if not names.include? $name

                  if $name.include? "FloorMass"
                    ws.Cells($r, 1).Value = groupname.to_s
                    ws.Cells($r, 2).Value = "Material"
                    $name = "Floor Mass-#{thermalmass_floormass[File.basename(file)]}"
                  else
                    next
                  end

                  ws.Cells($r, 3).Value = $name.to_s
                  ws.Cells($r, 4).Value = $roughness.to_s
                  ws.Cells($r, 5).Value = $thickness.to_s
                  ws.Cells($r, 6).Value = $conductivity.to_s
                  ws.Cells($r, 7).Value = $resistance.to_s
                  ws.Cells($r, 8).Value = $density.to_s
                  ws.Cells($r, 9).Value = $specificheat.to_s
                  ws.Cells($r, 25).Value = $thermalabs.to_s
                  ws.Cells($r, 26).Value = $solarabs.to_s

                  $r += 1
                  names << $name.to_s
                end
              end
            end # end of f.each_line do |line|
            f.close
          end # end of if File.extname(file).include? "idf"
        end # end of Find.find(path) do |file|
      else
        puts "#{groupname} - #{categoryname} skipped."
      end # end of if categoryname == "Floor Mass"
    end # end of db.execute("select * from Category where CategoryGroupID = ?", categorygroupid).each do |row2|
  end # end of if groupname == "Thermal Mass"
end # end of db.execute("select * from CategoryGroup").each do |row1|

path = "C:/OpenStudio/OS-BEopt/components/materials/lib/Materials.xlsx"
path = path.gsub(/\//, "\\\\")
wb.SaveAs(path)
wb.Close
x1.Quit