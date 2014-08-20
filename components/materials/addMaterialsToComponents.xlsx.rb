require 'rubygems'
require 'uuid'
require 'json'
require 'win32ole'
require 'csv'
require 'C:/Program Files (x86)/OpenStudio 1.3.1/Ruby/openstudio'

#get E+ version
ep_version = OpenStudio::Workspace.new("Draft".to_StrictnessLevel,"EnergyPlus".to_IddFileType).iddFile.version
#os_version = OpenStudio::Model::Model.new.getVersion.versionIdentifier
os_version = "1.3.1"

#log the start time
puts "started: #{Time.new}"

#set up the path to start working from
root_path = "#{File.dirname(__FILE__)}"

#load the material data into a nested hash and close the spreadsheet
#path to the SAM CEC PV module data
materials_path = "#{root_path}/lib/Materials.xlsx"
#enable Excel
xl = WIN32OLE::new('Excel.Application')
#open workbook
wb = xl.workbooks.open(materials_path)
#specify worksheet
ws = wb.worksheets("All Materials")
#specify data range
#data = ws.range('A2:Y322')['Value']
data = ws.range('A2:AB624').value # tk need to update this number if Materials.xlsx changes
#get the category column.  each material type goes on a different sheet in Components.xlsx
#material_types = ws.range('A2:A322')['Value']
material_types = ws.range('A2:A624').value # tk need to update this number if Materials.xlsx changes
material_types = material_types.uniq
#close workbook
#wb.Close(1)
wb.Close(0)
#quit Excel
xl.Quit

#load the hash that holds the material UIDs for future updates
#(in case order changes in Materials.xlsx or new materials are added)   
material_uid_hash = Hash.new
temp = File.read("#{root_path}/lib/material_uid_hash.json")
material_uid_hash = JSON.parse(temp)

# ================== PROCESS MATERIAL DATA ==========================

#define the columns where the data live in the spreadsheet Materials.xlsx (which was saved to 'data')
material_type_col = 0
category_col = 1
name_col = 2
roughness_col = 3
thickness_col = 4
conductivity_col = 5
resistance_col = 6
density_col = 7
specific_heat_col = 8
block_fill_type_col = 9
nominal_framing_width_col = 10
framing_on_center_spacing_col = 11
nominal_cavity_insulation_resistance_col = 12
nominal_header_insulation_resistance_col = 13
exterior_wall_col = 14
interior_wall_col = 15
below_grade_wall_col = 16
slab_on_grade_floor_col = 17
attic_floor_col = 18
outdoor_exposed_floor_col = 19
interior_floor_col = 20
exterior_roof_col = 21
attic_roof_col = 22
interior_ceiling_col = 23
thermalabs_col = 24
solarabs_col = 25
visibleabs_col = 26
note_col = 27

#array to hold the idf data for all modules.  used to make E+ library
eplus_material_library = Array.new
  
#iterator to write to xlsx file; data start on 3rd row (1,2)
i = 3

#counter to determine how many new UIDs were created.
#should be equal to number of new modules added to the CEC/SAM spreadhseet
new_material_new_uid = 0

#model to hold the data for all materials.  used to make E+ library
eplus_material_library = OpenStudio::Model::Model.new

#class to hold info from each material
class Material
 def initialize()
  #creates a new material with nothing set
 end
 
 #the properties of a material 
 attr_accessor(:name, 
              :uid,
              :material_type,
              :category,
              :comment,
              :roughness,
              :thickness_mm,
              :thickness_m,
              :conductivity_W_per_mK,
              :resistance_m2K_per_W,
              :density_kg_per_m3,
              :specific_heat_J_per_kgK,
              :block_fill_type,
              :nominal_framing_width_mm,
              :framing_on_center_spacing_m,
              :cavity_insulation_resistance_m2K_per_W,
              :header_insulation_resistance_m2K_per_W,
              :exterior_wall,
              :interior_wall,
              :below_grade_wall,
              :slab_on_grade_floor,
              :attic_floor,
              :outdoor_exposed_floor,
              :interior_floor,
              :exterior_roof,
              :attic_roof,
              :interior_ceiling,
              :thermalabs,
              :solarabs,
              :visibleabs,
              :osm_file_type,
              :osc_file_type,
              :idf_file_type,
              :osm_file_name,
              :osc_file_name,
              :idf_file_name,
              :osm_file_path,
              :osc_file_path,
              :idf_file_path)

end

#array to hold the materials we create
material_array = []

#loop through all the material rows, create a material object for each one, and store them all in an array

data.each do |material_row|

  #create a new material
  m = Material.new
  
  #material name
  m.name = material_row[name_col].strip

  #check if the material already has a UID
  if material_uid_hash.has_key? m.name
    #if yes, we'll reuse this uid
    m.uid = material_uid_hash[m.name]
  else
    #if not, we'll generate a new uid for it and store that
    m.uid = UUID.new.generate
    material_uid_hash[m.name] = m.uid
    new_material_new_uid += 1
  end  

  #material type
  m.material_type = material_row[material_type_col]
  
  #material category
  m.category = material_row[category_col]
  
  #comment
  m.comment = material_row[note_col]
  
  #roughness
  m.roughness = material_row[roughness_col]
  
  #thickness
  m_unit = OpenStudio::createUnit("m", "SI".to_UnitSystem).get
  mm_unit = OpenStudio::createUnit("mm", "SI".to_UnitSystem).get
  in_unit = OpenStudio::createUnit("in", "IP".to_UnitSystem).get
  if not material_row[thickness_col].nil?
    thickness_m = OpenStudio::Quantity.new(material_row[thickness_col], m_unit)
    m.thickness_m = thickness_m
    m.thickness_mm = OpenStudio::convert(thickness_m, mm_unit).get
  end
  
  #conductivity
  conductivity_W_per_mK_unit = OpenStudio::createUnit("W/m*K", "SI".to_UnitSystem).get
  if not material_row[conductivity_col].nil?
    conductivity_W_per_mK = OpenStudio::Quantity.new(material_row[conductivity_col], conductivity_W_per_mK_unit)
    m.conductivity_W_per_mK = conductivity_W_per_mK
  end
  
  #thermal resistance
  resistance_hrft2R_per_Btu_unit = OpenStudio::createUnit("hr*ft^2*R/Btu", "Btu".to_UnitSystem).get
  resistance_m2K_per_W_unit = OpenStudio::createUnit("m^2*K/W", "SI".to_UnitSystem).get
  resistance_m2K_per_W = OpenStudio::Quantity.new(material_row[resistance_col], resistance_m2K_per_W_unit)
  m.resistance_m2K_per_W = resistance_m2K_per_W
  
  #density
  density_kg_per_m3_unit = OpenStudio::createUnit("kg/m^3", "SI".to_UnitSystem).get
  if not material_row[density_col].nil?
    density_kg_per_m3 = OpenStudio::Quantity.new(material_row[density_col], density_kg_per_m3_unit)
    m.density_kg_per_m3 = density_kg_per_m3
  end
  
  #specific heat
  specific_heat_J_per_kgK_unit = OpenStudio::createUnit("J/kg*K", "SI".to_UnitSystem).get
  if not material_row[specific_heat_col].nil?
    specific_heat_J_per_kgK = OpenStudio::Quantity.new(material_row[specific_heat_col], specific_heat_J_per_kgK_unit)
    m.specific_heat_J_per_kgK = specific_heat_J_per_kgK
  end

  #thermal absorptance
  unless material_row[thermalabs_col].nil?
    m.thermalabs = material_row[thermalabs_col]
  end

  #solar absorptance
  unless material_row[solarabs_col].nil?
    m.solarabs = material_row[solarabs_col]
  end

  #visible absorptance
  unless material_row[visibleabs_col].nil?
    m.visibleabs = material_row[visibleabs_col]
  end

  #only for masonry
    #block fill type  
    m.block_fill_type = material_row[block_fill_type_col]
  
  #only for framing with cavity

    #framing width
    unless material_row[nominal_framing_width_col].nil?
      nominal_framing_width_in = OpenStudio::Quantity.new(material_row[nominal_framing_width_col], in_unit)
      m.nominal_framing_width_mm = OpenStudio::convert(nominal_framing_width_in, mm_unit).get
    end
    
    #framing spacing
    unless material_row[framing_on_center_spacing_col].nil?
      framing_on_center_spacing_in = OpenStudio::Quantity.new(material_row[framing_on_center_spacing_col], in_unit)
      m.framing_on_center_spacing_m = OpenStudio::convert(framing_on_center_spacing_in, m_unit).get  
    end
      
    #cavity insulation nominal resistance
    unless material_row[nominal_cavity_insulation_resistance_col].nil?
      cavity_insulation_resistance_hrft2R_per_Btu = OpenStudio::Quantity.new(material_row[nominal_cavity_insulation_resistance_col], resistance_hrft2R_per_Btu_unit)
      m.cavity_insulation_resistance_m2K_per_W = OpenStudio::convert(cavity_insulation_resistance_hrft2R_per_Btu, resistance_m2K_per_W_unit).get
    end
    
    #header insulation nominal resistance
    unless material_row[nominal_header_insulation_resistance_col].nil?
      header_insulation_resistance_hrft2R_per_Btu = OpenStudio::Quantity.new(material_row[nominal_header_insulation_resistance_col], resistance_hrft2R_per_Btu_unit)
      m.header_insulation_resistance_m2K_per_W = OpenStudio::convert(header_insulation_resistance_hrft2R_per_Btu, resistance_m2K_per_W_unit).get
    end

  #typical application cols
  m.exterior_wall = "Exterior Wall" if material_row[exterior_wall_col] == true   
  m.interior_wall = "Interior Wall" if material_row[interior_wall_col] == true
  m.below_grade_wall = "Below Grade Wall" if material_row[below_grade_wall_col] == true
  m.slab_on_grade_floor = "Slab-On-Grade Floor" if material_row[slab_on_grade_floor_col] == true
  m.attic_floor = "Attic Floor" if material_row[attic_floor_col] == true
  m.outdoor_exposed_floor = "Outdoor Exposed Floor" if material_row[outdoor_exposed_floor_col] == true
  m.interior_floor = "Interior Floor" if material_row[interior_floor_col] == true
  m.exterior_roof = "Exterior Roof" if material_row[exterior_roof_col] == true
  m.attic_roof = "Attic Roof" if material_row[attic_roof_col] == true
  m.interior_ceiling = "Interior Ceiling" if material_row[interior_ceiling_col] == true

  #MAKE THE SUPPORTING FILES (IDF, OSM, OSC)
  
  #setup the file names and save paths that will be used
  #file_name = m.name.gsub(" ","_").gsub("/","_").gsub("-","_").gsub("___","_").gsub("__","_").gsub("in.","in").gsub(",","").strip
  file_name = m.name.gsub(" ","_").gsub("/","_").gsub("-","_").gsub("___","_").gsub("__","_").gsub("in.","in").gsub(",","").gsub('"',"_in").strip

  m.osm_file_type = "osm"
  m.osc_file_type = "osc"
  m.idf_file_type = "idf"
  m.osm_file_name = "#{file_name}.#{m.osm_file_type}"
  m.osc_file_name = "#{file_name}.#{m.osc_file_type}"
  m.idf_file_name = "#{file_name}.#{m.idf_file_type}"
  m.osm_file_path = OpenStudio::Path.new("#{root_path}/osm_files/#{m.osm_file_name}")
  m.osc_file_path = OpenStudio::Path.new("#{root_path}/osc_files/#{m.osc_file_name}")
  m.idf_file_path = OpenStudio::Path.new("#{root_path}/idf_files/#{m.idf_file_name}")
  # OS:Material,
  # {3bbbdc32-efbd-4df1-b044-fabd70e67582},  ! Handle
  # 000_F08 Metal surface,    ! Name
  # Smooth,                   ! Roughness
  # 0.00080000000000000004,   ! Thickness
  # 45.280000000000001,       ! Conductivity
  # 7824,                     ! Density
  # 500;                      ! Specific Heat
  
  #make a model to hold the material
  model = OpenStudio::Model::Model.new
  
  #make the material
  if not m.thickness_m.nil?
    os_material = OpenStudio::Model::StandardOpaqueMaterial.new(model)
    if m.category == "Material"
      os_material.setName(file_name)
    else
      os_material.setName(m.name.split("_")[0])
    end
    os_material.setRoughness(m.roughness)
    os_material.setThickness(m.thickness_m.value)
    os_material.setThermalConductivity(m.conductivity_W_per_mK.value)
    os_material.setDensity(m.density_kg_per_m3.value)
    os_material.setSpecificHeat(m.specific_heat_J_per_kgK.value)
    unless material_row[thermalabs_col].nil?
      os_material.setThermalAbsorptance(m.thermalabs)
    end
    unless material_row[solarabs_col].nil?
      os_material.setSolarAbsorptance(m.solarabs)
    end
    unless material_row[visibleabs_col].nil?
      os_material.setVisibleAbsorptance(m.visibleabs)
    end
  else
    os_material = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
    os_material.setName(file_name)
    os_material.setRoughness(m.roughness)
    os_material.setThermalResistance(m.resistance_m2K_per_W.value)
  end

  #save the model as an .osm
  model.save(m.osm_file_path,true)
  
  #componentize the material
  os_material_component = os_material.createComponent

  #save the componentized material as an .osc
  os_material_component.save(m.osc_file_path,true)
  
  #translate the .osm to .idf and save
  ft = OpenStudio::EnergyPlus::ForwardTranslator.new
  #idf = ft.translateModel(model)
  idf = ft.translateModelObject(os_material)
  idf.save(m.idf_file_path,true)

  #add the material to the material library file 
  os_material.clone(eplus_material_library)
  
  material_array << m

end

#define the columns where the data will go in the component spreadsheet
#all of the sheets for different material.opaque.xxx have the same columns
#(the _c at the end differentiates it from the materials spreadsheet columns)
name_col_c = 1
uid_col_c = 2
version_id_col_c = 3
description_col_c = 4
fidelity_level_col_c = 5
author_col_c = 6
datetime_col_c = 7
comment_col_c = 8
category_col_c = 9
thickness_col_c = 10
conductivity_col_c = 11
resistance_col_c = 12
density_col_c = 13
specific_heat_col_c = 14
block_fill_type_col_c = 15
nominal_framing_width_col_c = 16
stud_spacing_col_c = 17
nominal_cavity_insulation_resistance_col_c = 18
nominal_header_insulation_resistance_col_c = 19
exterior_wall_col_c = 20
interior_wall_col_c = 21
below_grade_wall_col_c = 22
slab_on_grade_floor_col_c = 23
attic_floor_col_c = 24
outdoor_exposed_floor_col_c = 25
interior_floor_col_c = 26
exterior_roof_col_c = 27
attic_roof_col_c = 28
interior_ceiling_col_c = 29
thermalabs_col_c = 30
solarabs_col_c = 31
visibleabs_col_c = 32
openstudio_type_col_c = 33
osm_software_program_col_c = 34
osm_version_col_c = 35
osm_filename_col_c = 36
osm_filetype_col_c = 37
osm_filepath_col_c = 38
osc_software_program_col_c = 39
osc_version_col_c = 40
osc_filename_col_c = 41
osc_filetype_col_c = 42
osc_filepath_col_c = 43
idf_software_program_col_c = 44
idf_version_col_c = 45
idf_filename_col_c = 46
idf_filetype_col_c = 47
idf_filepath_col_c = 48
 
#open the component.xlsx, hold the workbook open for editing; closed after all modules are done
component_xlsx_path = "#{root_path}/Components.xlsx"
#enable Excel
xl = WIN32OLE::new('Excel.Application')
#open workbook
wb = xl.workbooks.open(component_xlsx_path)

#first, clear the old components out of the worksheets
material_types.each do |material_type|
  #specify the worksheet to clear
  ws = wb.worksheets(material_type.join.gsub("/","_"))

  #clear the cells.  have 39 cols, but set to 50 in case of expansion
  start_cell = "A3"
  end_cell = ws.range(start_cell).end(-4121).offset(0,50).address
  ws.range("#{start_cell}:#{end_cell}").clear
end

material_array.each do |mat|
  #specify worksheet
  ws = wb.worksheets(mat.material_type.gsub("/","_"))
  
  #find the first empty row in the sheet
  i = ws.range("A1").end(-4121).offset(1,0).row   #The parameter indicates the direction, the Excel constants are: #xlDown    = -4121
 
  #write out all the material information to the spreadsheet
  ws.cells(i, name_col_c).value = mat.name
  ws.cells(i, uid_col_c).value = mat.uid
  ws.cells(i, version_id_col_c).value = UUID.new.generate
  ws.cells(i, description_col_c).value = "Material from a data set created from Measures.sqlite"
  ws.cells(i, fidelity_level_col_c).value = "3"
  ws.cells(i, author_col_c).value = "jrobertson"
  ws.cells(i, datetime_col_c).value = Time.new
  ws.cells(i, comment_col_c).value = mat.comment
  ws.cells(i, category_col_c).value = mat.category   
  ws.cells(i, exterior_wall_col_c).value = mat.exterior_wall
  ws.cells(i, interior_wall_col_c).value = mat.interior_wall
  ws.cells(i, below_grade_wall_col_c).value = mat.below_grade_wall
  ws.cells(i, slab_on_grade_floor_col_c).value = mat.slab_on_grade_floor
  ws.cells(i, attic_floor_col_c).value = mat.attic_floor
  ws.cells(i, outdoor_exposed_floor_col_c).value = mat.outdoor_exposed_floor
  ws.cells(i, interior_floor_col_c).value = mat.interior_floor
  ws.cells(i, exterior_roof_col_c).value = mat.exterior_roof
  ws.cells(i, attic_roof_col_c).value = mat.attic_roof
  ws.cells(i, interior_ceiling_col_c).value = mat.interior_ceiling
  ws.cells(i, thickness_col_c).value = mat.thickness_mm  
  ws.cells(i, conductivity_col_c).value = mat.conductivity_W_per_mK
  ws.cells(i, resistance_col_c).value = mat.resistance_m2K_per_W
  ws.cells(i, density_col_c).value = mat.density_kg_per_m3
  ws.cells(i, specific_heat_col_c).value = mat.specific_heat_J_per_kgK
  ws.cells(i, thermalabs_col_c).value = mat.thermalabs
  ws.cells(i, solarabs_col_c).value = mat.solarabs
  ws.cells(i, visibleabs_col_c).value = mat.visibleabs
  ws.cells(i, block_fill_type_col_c).value = mat.block_fill_type
  ws.cells(i, nominal_framing_width_col_c).value = mat.nominal_framing_width_mm
  ws.cells(i, stud_spacing_col_c).value = mat.framing_on_center_spacing_m
  ws.cells(i, nominal_cavity_insulation_resistance_col_c).value = mat.cavity_insulation_resistance_m2K_per_W
  ws.cells(i, nominal_header_insulation_resistance_col_c).value = mat.header_insulation_resistance_m2K_per_W
  ws.cells(i, openstudio_type_col_c).value = "OS:Material"
  ws.cells(i, osm_software_program_col_c).value = "OpenStudio"
  ws.cells(i, osm_version_col_c).value = os_version
  ws.cells(i, osm_filename_col_c).value = mat.osm_file_name
  ws.cells(i, osm_filetype_col_c).value = mat.osm_file_type
  ws.cells(i, osm_filepath_col_c).value = mat.osm_file_path.to_s
  ws.cells(i, osc_software_program_col_c).value = "OpenStudio"
  ws.cells(i, osc_version_col_c).value = os_version
  ws.cells(i, osc_filename_col_c).value = mat.osc_file_name
  ws.cells(i, osc_filetype_col_c).value = mat.osc_file_type
  ws.cells(i, osc_filepath_col_c).value = mat.osc_file_path.to_s
  ws.cells(i, idf_software_program_col_c).value = "EnergyPlus"
  ws.cells(i, idf_version_col_c).value = ep_version
  ws.cells(i, idf_filename_col_c).value = mat.idf_file_name
  ws.cells(i, idf_filetype_col_c).value = mat.idf_file_type
  ws.cells(i, idf_filepath_col_c).value = mat.idf_file_path.to_s
  
end
  
#save the Components.xlsx workbook
wb.save
#close the Excel file after finished editing
xl.Quit

#re-save the UID hash, in case new materials were added
File.open("#{root_path}/lib/material_uid_hash.json", 'w') do |file|
  file << material_uid_hash.to_json
end

#save the material library
eplus_material_library_path = OpenStudio::Path.new("#{root_path}/eplus_material_library.idf")
ft = OpenStudio::EnergyPlus::ForwardTranslator.new
idf = ft.translateModel(eplus_material_library)
idf.save(eplus_material_library_path,true)

#log the end time
puts "finished: #{Time.new}"

#display the number of new materials added
puts "VERIFY! - #{new_material_new_uid} new materials were added"
