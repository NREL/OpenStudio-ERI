# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'rexml/document'
require 'rexml/xpath'
require 'pathname'
require "#{File.dirname(__FILE__)}/resources/301"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/helper_methods"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class EnergyRatingIndex301 < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Generate Energy Rating Index Model"
  end

  # human readable description
  def description
    return "Generates a model from a HPXML building description as defined by the ANSI/RESNET 301-2014 ruleset. Used as part of the caclulation of an Energy Rating Index."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on the provided HPXML building description and choice of calculation type (e.g., #{Constants.CalcTypeERIReferenceHome}, #{Constants.CalcTypeERIRatedHome}, etc.), creates an updated version of the HPXML file as well as an OpenStudio model, as specified by ANSI/RESNET 301-2014 \"Standard for the Calculation and Labeling of the Energy Performance of Low-Rise Residential Buildings using the HERS Index\"."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for design type
    calc_types = []
    #calc_types << Constants.CalcTypeStandard
    calc_types << Constants.CalcTypeERIReferenceHome
    calc_types << Constants.CalcTypeERIRatedHome
    #calc_types << Constants.CalcTypeERIIndexAdjustmentDesign
    calc_type = OpenStudio::Measure::OSArgument.makeChoiceArgument("calc_type", calc_types, true)
    calc_type.setDisplayName("Calculation Type")
    calc_type.setDescription("'#{Constants.CalcTypeStandard}' will use the DOE Building America Simulation Protocols. HERS options will use the ANSI/RESNET 301-2014 Standard.")
    calc_type.setDefaultValue(Constants.CalcTypeStandard)
    args << calc_type

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_file_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute (or relative) path of the HPXML file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", true)
    arg.setDisplayName("EPW File Path")
    arg.setDescription("Absolute (or relative) path of the EPW weather file to assign. The corresponding DDY file must also be in the same directory.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("measures_dir", true)
    arg.setDisplayName("Residential Measures Directory")
    arg.setDescription("Absolute path of the residential measures.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("schemas_dir", false)
    arg.setDisplayName("HPXML Schemas Directory")
    arg.setDescription("Absolute path of the hpxml schemas.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_output_file_path", false)
    arg.setDisplayName("HPXML Output File Path")
    arg.setDescription("Absolute (or relative) path of the output HPXML file.")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("osm_output_file_path", false)
    arg.setDisplayName("OSM Output File Path")
    arg.setDescription("Absolute (or relative) path of the output OSM file.")
    args << arg    
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    calc_type = runner.getStringArgumentValue("calc_type", user_arguments)
    hpxml_file_path = runner.getStringArgumentValue("hpxml_file_path", user_arguments)
    weather_file_path = runner.getStringArgumentValue("weather_file_path", user_arguments)
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)
    schemas_dir = runner.getOptionalStringArgumentValue("schemas_dir", user_arguments)
    hpxml_output_file_path = runner.getOptionalStringArgumentValue("hpxml_output_file_path", user_arguments)
    osm_output_file_path = runner.getOptionalStringArgumentValue("osm_output_file_path", user_arguments)

    unless (Pathname.new hpxml_file_path).absolute?
      hpxml_file_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_file_path))
    end 
    unless File.exists?(hpxml_file_path) and hpxml_file_path.downcase.end_with? ".xml"
      runner.registerError("'#{hpxml_file_path}' does not exist or is not an .xml file.")
      return false
    end
    
    unless (Pathname.new weather_file_path).absolute?
      weather_file_path = File.expand_path(File.join(File.dirname(__FILE__), weather_file_path))
    end
    unless File.exists?(weather_file_path) and weather_file_path.downcase.end_with? ".epw"
      runner.registerError("'#{weather_file_path}' does not exist or is not an .epw file.")
      return false
    end
    
    unless (Pathname.new measures_dir).absolute?
      measures_dir = File.expand_path(File.join(File.dirname(__FILE__), measures_dir))
    end
    unless Dir.exists?(measures_dir)
      runner.registerError("'#{measures_dir}' does not exist.")
      return false
    end
    
    if schemas_dir.is_initialized
      schemas_dir = schemas_dir.get
      unless (Pathname.new schemas_dir).absolute?
        schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
      end
      unless Dir.exists?(schemas_dir)
        runner.registerError("'#{schemas_dir}' does not exist.")
        return false
      end
    else
      schemas_dir = nil
    end
    
    hpxml_doc = REXML::Document.new(File.read(hpxml_file_path))
    
    show_measure_calls=false
    
    # Validate input HPXML
    if not schemas_dir.nil?
      has_errors = false
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        runner.registerError("Input HPXML: #{error.to_s}")
        has_errors = true
      end
      if has_errors
        return false
      end
    else
      runner.registerWarning("Could not load nokogiri, no HPXML validation performed.")
    end
    
    # Apply Location measure to obtain weather data
    measures = {}
    measure_subdir = "ResidentialLocation"
    args = {
            "weather_directory"=>File.dirname(weather_file_path),
            "weather_file_name"=>File.basename(weather_file_path),
            "dst_start_date"=>"NA",
            "dst_end_date"=>"NA"
           }
    measures[measure_subdir] = args
    if not apply_measures(measures_dir, measures, runner, model, show_measure_calls)
      return false
    end
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    
    # Apply 301 ruleset on HPXML object
    errors, building = EnergyRatingIndex301Ruleset.apply_ruleset(hpxml_doc, calc_type, weather)
    errors.each do |error|
      runner.registerError(error)
    end
    unless errors.empty?
      return false
    end
    
    if hpxml_output_file_path.is_initialized
      XMLHelper.write_file(hpxml_doc, hpxml_output_file_path.get)
    end
    
    # Validate new HPXML
    if not schemas_dir.nil?
      has_errors = false
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        runner.registerError("Generated HPXML: #{error.to_s}")
        has_errors = true
      end
      if has_errors
        return false
      end
    else
      runner.registerWarning("Could not load nokogiri, no HPXML validation performed.")
    end
    
    # Obtain list of OpenStudio measures (and arguments)
    measures = OSMeasures.build_measures_from_hpxml(building, weather_file_path)
    
    #puts "measures #{measures.to_s}"
    
    # Create OpenStudio model
    if not OSModel.create_geometry(building, runner, model)
      return false
    end

    if not apply_measures(measures_dir, measures, runner, model, show_measure_calls)
      return false
    end
    
    if osm_output_file_path.is_initialized
      File.write(osm_output_file_path.get, model.to_s)
    end
    
    # Add output variables for RESNET building loads
    if not generate_building_loads(model, runner)
      return false
    end

    return true

  end
  
  def generate_building_loads(model, runner)
    # Note: Duct losses are included the heating/cooling energy values. For the 
    # RESNET Reference Home, the effect of DSE will be removed during post-processing.
    
    # FIXME: Are HW distribution losses included in the HW energy values?
    # FIXME: Handle fan/pump energy (requires EMS or timeseries output to split apart heating/cooling)
    
    clg_objs = []
    htg_objs = []
    model.getThermalZones.each do |zone|
      HVAC.existing_cooling_equipment(model, runner, zone).each do |clg_equip|
        if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          clg_objs << HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil.get).name.to_s
        elsif clg_equip.to_ZoneHVACComponent.is_initialized
          clg_objs << HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil).name.to_s
        end
      end
      HVAC.existing_heating_equipment(model, runner, zone).each do |htg_equip|
        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          htg_objs << HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get).name.to_s
        elsif htg_equip.to_ZoneHVACComponent.is_initialized
          if not htg_equip.is_a?(OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric)
            htg_objs << HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil).name.to_s
          else
            htg_objs << htg_equip.name.to_s
          end
        end
      end
    end
    
    if clg_objs.size == 0
      runner.registerError("Could not identify cooling object.")
      return false
    elsif htg_objs.size == 0
      runner.registerError("Could not identify heating coil.")
      return false
    end
    
    add_output_variables(model, BuildingLoadVars.get_space_heating_load_vars, htg_objs)
    add_output_variables(model, BuildingLoadVars.get_space_cooling_load_vars, clg_objs)
    add_output_variables(model, BuildingLoadVars.get_water_heating_load_vars)
    
    return true
    
  end
  
  def add_output_variables(model, vars, keys=['*'])
  
    vars.each do |var|
      keys.each do |key|
        outputVariable = OpenStudio::Model::OutputVariable.new(var, model)
        outputVariable.setReportingFrequency('runperiod')
        outputVariable.setKeyValue(key)
      end
    end
    
  end
  
end

class OSMeasures    

  # FIXME: Allow args to have non-string values; atuo-convert all args to strings later.
  # FIXME: Add surface argument to envelope construction measures

  def self.build_measures_from_hpxml(building, weather_file_path)

    measures = {}
    
    # TODO
    # ResidentialGeometryOrientation
    # ResidentialGeometryEaves
    get_overhangs(building, measures) # TODO
    # ResidentialGeometryNeighbors
    
    get_beds_and_baths(building, measures)
    get_num_occupants(building, measures)
    
    # Envelope
    get_windows(building, measures)
    get_doors(building, measures)
    get_ceiling_roof_constructions(building, measures)
    get_foundation_constructions(building, measures)
    get_wall_constructions(building, measures)
    get_other_constructions(building, measures)
    
    # Water Heating
    get_water_heating(building, measures)
    
    # HVAC
    get_heating_system(building, measures)
    get_cooling_system(building, measures)
    get_heat_pump(building, measures)
    get_setpoints(building, measures)
    get_ceiling_fan(building, measures)
    get_dehumidifier(building, measures)
    
    # Appliances, Plug Loads, and Lighting
    get_refrigerator(building, measures)
    get_clothes_washer(building, measures)
    get_clothes_dryer(building, measures)
    get_dishwasher(building, measures)
    get_cooking_range(building, measures)
    get_lighting(building, measures)
    get_mels(building, measures)
    
    # Other
    get_airflow(building, measures)
    get_hvac_sizing(building, measures)
    get_photovoltaics(building, measures)

    return measures

  end
  
  def self.to_beopt_fuel(fuel)
    conv = {"natural gas"=>Constants.FuelTypeGas, 
            "fuel oil"=>Constants.FuelTypeOil, 
            "propane"=>Constants.FuelTypePropane, 
            "electricity"=>Constants.FuelTypeElectric}
    return conv[fuel]
  end
      
  def self.get_overhangs(building, measures)
    
    depth = 0
    offset = 0
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
      overhangs = window.elements["Overhangs"]
      break if overhangs.nil?
      depth = Float(XMLHelper.get_value(overhangs, "Depth"))
      offset = Float(XMLHelper.get_value(overhangs, "DistanceToTopOfWindow"))
      break
    end
    measure_subdir = "ResidentialGeometryOverhangs"
    args = {
            "depth"=>OpenStudio.convert(depth,"in","ft").get.to_s,
            "offset"=>OpenStudio.convert(offset,"in","ft").get.to_s,
            "front_facade"=>"true",
            "back_facade"=>"true",
            "left_facade"=>"true",
            "right_facade"=>"true"
           }
    measures[measure_subdir] = args
    
  end
      
  def self.get_beds_and_baths(building, measures)

    measure_subdir = "ResidentialGeometryNumBedsAndBaths"  
    num_bedrooms = Integer(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    num_bathrooms = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    args = {
            "num_bedrooms"=>num_bedrooms,
            "num_bathrooms"=>num_bathrooms
           }  
    measures[measure_subdir] = args
    
  end
      
  def self.get_num_occupants(building, measures)

    num_occ = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents"))
    occ_gain = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/HeatGainPerPerson"))
    sens_frac = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/FracSensible"))
    lat_frac = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingOccupancy/extension/FracLatent"))
    
    measure_subdir = "ResidentialGeometryNumOccupants"  
    args = {
            "num_occ"=>num_occ,
            "occ_gain"=>occ_gain,
            "sens_frac"=>sens_frac,
            "lat_frac"=>lat_frac,
            "weekday_sch"=>"1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000",
            "weekend_sch"=>"1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000",
            "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"
           }
    measures[measure_subdir] = args
    
  end
      
  def self.get_windows(building, measures)

    # FIXME
  
    measure_subdir = "ResidentialConstructionsWindows"
    args = {
            "ufactor_front"=>0.3,
            "ufactor_back"=>0.3,
            "ufactor_left"=>0.3,
            "ufactor_right"=>0.3,
            "shgc_front"=>0.3,
            "shgc_back"=>0.3,
            "shgc_left"=>0.3,
            "shgc_right"=>0.3,
            "heating_shade_mult"=>0.7,
            "cooling_shade_mult"=>0.7
           }  
    measures[measure_subdir] = args

  end
  
  def self.get_doors(building, measures)
  
    # FIXME

    tot_area = 0.0
    tot_ua = 0.0
    building.elements.each("BuildingDetails/Enclosure/Doors/Door") do |door|
      area = Float(XMLHelper.get_value(door, "Area"))
      ua = area/Float(XMLHelper.get_value(door, "RValue"))
      tot_area += area
      tot_ua += ua
    end

    if tot_area > 0
      measure_subdir = "ResidentialConstructionsDoors"
      args = {
              "door_ufactor"=>tot_ua/tot_area
             }  
      measures[measure_subdir] = args
    end
    
  end

  def self.get_ceiling_roof_constructions(building, measures)
  
    # FIXME

    measure_subdir = "ResidentialConstructionsCeilingsRoofsUnfinishedAttic"
    args = {
            "ceil_r"=>30,
            "ceil_grade"=>"I",
            "ceil_ins_thick_in"=>8.55,
            "ceil_ff"=>0.07,
            "ceil_joist_height"=>3.5,
            "roof_cavity_r"=>0,
            "roof_cavity_grade"=>"I",
            "roof_cavity_ins_thick_in"=>0,
            "roof_ff"=>0.07,
            "roof_fram_thick_in"=>7.25
           }  
    measures[measure_subdir] = args

    measure_subdir = "ResidentialConstructionsCeilingsRoofsFinishedRoof"
    args = {
            "cavity_r"=>30,
            "install_grade"=>"I",
            "cavity_depth"=>9.25,
            "ins_fills_cavity"=>"false",
            "framing_factor"=>0.07
           }  
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsCeilingsRoofsRoofingMaterial"
    args = {
            "solar_abs"=>0.85,
            "emissivity"=>0.91,
            "material"=>Constants.RoofMaterialAsphaltShingles,
            "color"=>Constants.ColorMedium
           }  
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsCeilingsRoofsSheathing"
    args = {
            "osb_thick_in"=>0.75,
            "rigid_r"=>0.0,
            "rigid_thick_in"=>0.0,
           }
    measures[measure_subdir] = args
           
    measure_subdir = "ResidentialConstructionsCeilingsRoofsThermalMass"
    args = {
            "thick_in1"=>0.5,
            "thick_in2"=>nil,
            "cond1"=>1.1112,
            "cond2"=>nil,
            "dens1"=>50.0,
            "dens2"=>nil,
            "specheat1"=>0.2,
            "specheat2"=>nil
           }
    measures[measure_subdir] = args

    has_rb = false
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Roofs/Roof") do |roof|
      if Boolean(XMLHelper.get_value(roof, "RadiantBarrier"))
        has_rb = true
      end
    end

    if has_rb
      measure_subdir = "ResidentialConstructionsCeilingsRoofsRadiantBarrier"
      args = {
              "has_rb"=>"true"
             }
      measures[measure_subdir] = args
    end
    
  end
  
  def self.get_foundation_wall_properties(foundation)
  
    foundation.elements.each("FoundationWall") do |fnd_wall|
  
      if XMLHelper.has_element(fnd_wall, "Insulation/AssemblyEffectiveRValue") # Reference Home
      
        wall_R = Float(XMLHelper.get_value(fnd_wall, "Insulation/AssemblyEffectiveRValue"))
        
        wall_cav_r = 0.0
        wall_cav_depth = 0.0
        wall_grade = 1
        wall_ff = 0.0
        
        wall_cont_height = Float(XMLHelper.get_value(fnd_wall, "Height"))
        wall_cont_r = wall_R - Material.Concrete8in.rvalue - Material.DefaultWallSheathing.rvalue - Material.AirFilmVertical.rvalue
        wall_cont_depth = 1.0
      
      else # Rated Home
    
        fnd_wall_cavity = fnd_wall.elements["Insulation/Layer[InstallationType='cavity']"]
        wall_cav_r = Float(XMLHelper.get_value(fnd_wall_cavity, "NominalRValue"))
        wall_cav_depth = Float(XMLHelper.get_value(fnd_wall_cavity, "Thickness"))
        wall_grade = Integer(XMLHelper.get_value(fnd_wall, "Insulation/InsulationGrade"))
        wall_ff = Float(XMLHelper.get_value(fnd_wall, "InteriorStuds/FramingFactor"))
        
        fnd_wall_cont = fnd_wall.elements["Insulation/Layer[InstallationType='continuous']"]
        if XMLHelper.has_element(fnd_wall_cont, "extension/InsulationHeight")
          wall_cont_height = Float(XMLHelper.get_value(fnd_wall_cont, "extension/InsulationHeight")) # For basement
        else
          wall_cont_height = Float(XMLHelper.get_value(fnd_wall, "Height")) # For crawlspace, doesn't matter
        end
        wall_cont_r = Float(XMLHelper.get_value(fnd_wall_cont, "NominalRValue"))
        wall_cont_depth = Float(XMLHelper.get_value(fnd_wall_cont, "Thickness"))
        
      end
       
      # FIXME
      return wall_cav_r, wall_cav_depth, wall_grade, wall_ff, wall_cont_height, wall_cont_r, wall_cont_depth
       
    end
    
  end
  
  def self.get_foundation_frame_floor_properties(foundation)
          
    foundation.elements.each("FrameFloor") do |fnd_floor|
    
      carpet_frac = Float(XMLHelper.get_value(fnd_floor, "extension/CarpetFraction"))
      carpet_r = Float(XMLHelper.get_value(fnd_floor, "extension/CarpetRValue"))

      if XMLHelper.has_element(fnd_floor, "Insulation/AssemblyEffectiveRValue") # Reference Home
      
        # FIXME
        floor_cav_r = 0.0
        floor_cav_depth = 5.5
        floor_grade = 1
        floor_ff = 0.0
        floor_cont_r = 0.0
        floor_cont_depth = 0.0
      
      else # Rated Home
    
        fnd_floor_cavity = fnd_floor.elements["Insulation/Layer[InstallationType='cavity']"]
        floor_cav_r = Float(XMLHelper.get_value(fnd_floor_cavity, "NominalRValue"))
        floor_cav_depth = Float(XMLHelper.get_value(fnd_floor_cavity, "Thickness"))
        floor_grade = Integer(XMLHelper.get_value(fnd_floor, "Insulation/InsulationGrade"))
        floor_ff = Float(XMLHelper.get_value(fnd_floor, "FloorJoists/FramingFactor"))
        fnd_floor_cont = fnd_floor.elements["Insulation/Layer[InstallationType='continuous']"]
        floor_cont_r = Float(XMLHelper.get_value(fnd_floor_cont, "NominalRValue"))
        floor_cont_depth = Float(XMLHelper.get_value(fnd_floor_cont, "Thickness"))
      
      end
      
      # FIXME
      return floor_cav_r, floor_cav_depth, floor_grade, floor_ff, floor_cont_r, floor_cont_depth, carpet_frac, carpet_r
      
    end
      
  end

  def self.get_foundation_slab_properties(foundation)
          
    foundation.elements.each("Slab") do |fnd_slab|
    
      carpet_frac = Float(XMLHelper.get_value(fnd_slab, "extension/CarpetFraction"))
      carpet_r = Float(XMLHelper.get_value(fnd_slab, "extension/CarpetRValue"))
      
      fnd_slab_perim = fnd_slab.elements["PerimeterInsulation/Layer[InstallationType='continuous']"]
      ext_r = Float(XMLHelper.get_value(fnd_slab_perim, "NominalRValue"))
      ext_depth = Float(XMLHelper.get_value(fnd_slab, "PerimeterInsulationDepth"))
      if ext_r == 0 or ext_depth == 0
        ext_r = 0
        ext_depth = 0
      end
      
      fnd_slab_under = fnd_slab.elements["PerimeterInsulation/Layer[InstallationType='continuous']"]
      perim_r = Float(XMLHelper.get_value(fnd_slab_under, "NominalRValue"))
      perim_width = Float(XMLHelper.get_value(fnd_slab, "UnderSlabInsulationWidth"))
      if perim_r == 0 or perim_width == 0
        perim_r = 0
        perim_width = 0
      end
      
      # FIXME
      return ext_r, ext_depth, perim_r, perim_width, carpet_frac, carpet_r
      
    end
    
  end

  def self.get_foundation_constructions(building, measures)
  
    # FIXME
    exposed_perim = 0
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      foundation.elements.each("Slab") do |slab|        
        unless slab.elements["ExposedPerimeter"].nil?
          exposed_perim += Float(slab.elements["ExposedPerimeter"].text)
        end
      end
    end
    
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      if XMLHelper.has_element(foundation, "FoundationType/Basement")
    
        is_cond = Boolean(XMLHelper.get_value(foundation, "FoundationType/Basement/Conditioned"))
        
        wall_cav_r, wall_cav_depth, wall_grade, wall_ff, wall_cont_height, wall_cont_r, wall_cont_depth = get_foundation_wall_properties(foundation)
        floor_cav_r, floor_cav_depth, floor_grade, floor_ff, floor_cont_r, floor_cont_depth, carpet_frac, carpet_r = get_foundation_frame_floor_properties(foundation)
        
        if is_cond
        
          measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementFinished"
          args = {
                  "wall_ins_height"=>wall_cont_height,
                  "wall_cavity_r"=>wall_cav_r,
                  "wall_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[wall_grade],
                  "wall_cavity_depth"=>wall_cav_depth,
                  "wall_cavity_insfills"=>"true", # FIXME
                  "wall_ff"=>wall_ff,
                  "wall_rigid_r"=>wall_cont_r,
                  "wall_rigid_thick_in"=>wall_cont_depth,
                  "ceil_ff"=>floor_ff,
                  "ceil_joist_height"=>floor_cav_depth,
                  "exposed_perim"=>exposed_perim
                 }  
          measures[measure_subdir] = args
          
        else
          
          measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementUnfinished"
          args = {
                  "wall_ins_height"=>wall_cont_height,
                  "wall_cavity_r"=>wall_cav_r,
                  "wall_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[wall_grade],
                  "wall_cavity_depth"=>wall_cav_depth,
                  "wall_cavity_insfills"=>"true", # FIXME
                  "wall_ff"=>wall_ff,
                  "wall_rigid_r"=>wall_cont_r,
                  "wall_rigid_thick_in"=>wall_cont_depth,
                  "ceil_cavity_r"=>floor_cav_r,
                  "ceil_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[floor_grade],
                  "ceil_ff"=>floor_ff,
                  "ceil_joist_height"=>floor_cav_depth,
                  "exposed_perim"=>exposed_perim
                 }
          measures[measure_subdir] = args
    
        end
        
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
        args = {
                "osb_thick_in"=>0.75,
                "rigid_r"=>floor_cont_r,
                "rigid_thick_in"=>floor_cont_depth
               }
        measures[measure_subdir] = args
        
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace")
      
        is_vented = Boolean(XMLHelper.get_value(foundation, "FoundationType/Crawlspace/Vented"))
        
        wall_cav_r, wall_cav_depth, wall_grade, wall_ff, wall_cont_height, wall_cont_r, wall_cont_depth = get_foundation_wall_properties(foundation)
        floor_cav_r, floor_cav_depth, floor_grade, floor_ff, floor_cont_r, floor_cont_depth, carpet_frac, carpet_r = get_foundation_frame_floor_properties(foundation)
        
        measure_subdir = "ResidentialConstructionsFoundationsFloorsCrawlspace"
        args = {
                "wall_rigid_r"=>wall_cont_r,
                "wall_rigid_thick_in"=>wall_cont_depth,
                "ceil_cavity_r"=>floor_cav_r,
                "ceil_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[floor_grade],
                "ceil_ff"=>floor_ff,
                "ceil_joist_height"=>floor_cav_depth,
                "exposed_perim"=>exposed_perim
               }  
        measures[measure_subdir] = args
        
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
        args = {
                "osb_thick_in"=>0.75,
                "rigid_r"=>floor_cont_r,
                "rigid_thick_in"=>floor_cont_depth
               }
        measures[measure_subdir] = args

      elsif XMLHelper.has_element(foundation, "FoundationType/SlabOnGrade")
      
        ext_r, ext_depth, perim_r, perim_width, carpet_frac, carpet_r = get_foundation_slab_properties(foundation)
      
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSlab"
        args = {
                "perim_r"=>perim_r,
                "perim_width"=>perim_width,
                "whole_r"=>0, # FIXME
                "gap_r"=>0, # FIXME
                "ext_r"=>ext_r,
                "ext_depth"=>ext_depth,
                "mass_thick_in"=>4,
                "mass_conductivity"=>9.1,
                "mass_density"=>140,
                "mass_specific_heat"=>0.2,
                "exposed_perim"=>exposed_perim
               }  
        measures[measure_subdir] = args
        
        
      elsif XMLHelper.has_element(foundation, "FoundationType/Ambient")
        
        floor_cav_r, floor_cav_depth, floor_grade, floor_ff, floor_cont_r, floor_cont_depth, carpet_frac, carpet_r = get_foundation_frame_floor_properties(foundation)

        measure_subdir = "ResidentialConstructionsFoundationsFloorsPierBeam"
        args = {
                "cavity_r"=>floor_cav_r,
                "install_grade"=>{1=>"I",2=>"II",3=>"III"}[floor_grade],
                "framing_factor"=>floor_ff
               }
        measures[measure_subdir] = args
        
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
        args = {
                "osb_thick_in"=>0.75,
                "rigid_r"=>floor_cont_r,
                "rigid_thick_in"=>floor_cont_depth
               }
        measures[measure_subdir] = args

      end
    
      measure_subdir = "ResidentialConstructionsFoundationsFloorsCovering"
      args = {
              "covering_frac"=>carpet_frac,
              "covering_r"=>carpet_r
             }
      measures[measure_subdir] = args

    end
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsInterzonalFloors"
    args = {
            "cavity_r"=>19,
            "install_grade"=>"I",
            "framing_factor"=>0.13
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsFoundationsFloorsThermalMass"
    args = {
            "thick_in"=>0.625,
            "cond"=>0.8004,
            "dens"=>34.0,
            "specheat"=>0.29
           }
    measures[measure_subdir] = args
    
  end
  
  def self.get_siding_material(siding, color)
    
    if siding == "stucco"
    
      k_in = 4.5
      rho = 80.0
      cp = 0.21
      thick_in = 1.0
      sAbs = 0.75
      tAbs = 0.9
      
    elsif siding == "brick veneer"
    
      k_in = 5.5
      rho = 110.0
      cp = 0.19
      thick_in = 4.0
      if ["reflective","light"].include? color
        sAbs = 0.55
        tAbs = 0.93
      elsif ["medium","dark"].include? color
        sAbs = 0.88
        tAbs = 0.96
      end
      
    elsif siding == "wood siding"
    
      k_in = 0.71
      rho = 34.0
      cp = 0.28
      thick_in = 1.0
      if ["reflective","light"].include? color
        sAbs = 0.3
        tAbs = 0.82
      elsif ["medium","dark"].include? color
        sAbs = 0.75
        tAbs = 0.92
      end
      
    elsif siding == "aluminum siding"
    
      k_in = 0.61
      rho = 10.9
      cp = 0.29
      thick_in = 0.375
      if ["reflective","light"].include? color
        sAbs = 0.3
        tAbs = 0.9
      elsif ["medium","dark"].include? color
        sAbs = 0.75
        tAbs = 0.94
      end
      
    elsif siding == "vinyl siding"
    
      k_in = 0.62
      rho = 11.1
      cp = 0.25
      thick_in = 0.375
      if ["reflective","light"].include? color
        sAbs = 0.3
        tAbs = 0.9
      elsif ["medium","dark"].include? color
        sAbs = 0.75
        tAbs = 0.9
      end
      
    elsif siding == "fiber cement siding"
    
      k_in = 1.79
      rho = 21.7
      cp = 0.24
      thick_in = 0.375
      if ["reflective","light"].include? color
        sAbs = 0.3
        tAbs = 0.9
      elsif ["medium","dark"].include? color
        sAbs = 0.75
        tAbs = 0.9
      end
      
    else
    
      fail "Unexpected siding type: #{siding}."
    
    end
    
    return Material.new(name="Siding", thick_in=thick_in, mat_base=nil, k_in=k_in, rho=rho, cp=cp, tAbs=tAbs, sAbs=sAbs, vAbs=sAbs)
    
  end

  def self.get_wall_constructions(building, measures)
  
    mat_mass = Material.DefaultWallMass
    mat_sheath = Material.DefaultWallSheathing
  
    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      siding = XMLHelper.get_value(wall, "Siding")
      color = XMLHelper.get_value(wall, "Color")
      mat_siding = get_siding_material(siding, color)
        
      # TODO: Handle other wall types
      if XMLHelper.has_element(wall, "WallType/WoodStud")
      
        if XMLHelper.has_element(wall, "Insulation/AssemblyEffectiveRValue") # Reference Home
        
          wall_R = Float(XMLHelper.get_value(wall, "Insulation/AssemblyEffectiveRValue"))
          layer_R = wall_R - mat_mass.rvalue - mat_sheath.rvalue - mat_siding.rvalue - Material.AirFilmVertical.rvalue - Material.AirFilmOutside.rvalue
          layer_t = 3.5
          layer_k = layer_t/layer_R
          framing_factor = 0.23
          mat_ins = BaseMaterial.InsulationGenericDensepack
          mat_wood = BaseMaterial.Wood
          rho = (1.0 - framing_factor) * mat_ins.rho + framing_factor * mat_wood.rho
          cp = (1.0 - framing_factor) * mat_ins.cp + framing_factor * mat_wood.cp
          cont_r = 0.0
          cont_depth = 0.0
    
          measure_subdir = "ResidentialConstructionsWallsExteriorGeneric"
          args = {
                  "thick_in_1"=>layer_t,
                  "conductivity_1"=>layer_k,
                  "density_1"=>rho,
                  "specific_heat_1"=>cp
                 }
          measures[measure_subdir] = args
          
          measure_subdir = "ResidentialConstructionsWallsSheathing"
          args = {
                  "osb_thick_in"=>mat_sheath.thick_in,
                  "rigid_r"=>0.0,
                  "rigid_thick_in"=>0.0
                 }
          measures[measure_subdir] = args
          
        else # Rated Home
      
          cavity_layer = wall.elements["Insulation/Layer[InstallationType='cavity']"]
          cavity_r = Float(XMLHelper.get_value(cavity_layer, "NominalRValue"))
          cavity_depth = Float(XMLHelper.get_value(cavity_layer, "Thickness"))
          install_grade = Integer(XMLHelper.get_value(wall, "Insulation/InsulationGrade"))
          framing_factor = Float(XMLHelper.get_value(wall, "Studs/FramingFactor"))
          ins_fills_cavity = true # FIXME
          cont_layer = wall.elements["Insulation/Layer[InstallationType='continuous']"]
          cont_r = Float(XMLHelper.get_value(cont_layer, "NominalRValue"))
          cont_depth = Float(XMLHelper.get_value(cont_layer, "Thickness"))
        
          measure_subdir = "ResidentialConstructionsWallsExteriorWoodStud"
          args = {
                  "cavity_r"=>cavity_r,
                  "install_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                  "cavity_depth"=>cavity_depth,
                  "ins_fills_cavity"=>ins_fills_cavity,
                  "framing_factor"=>framing_factor
                 }
          measures[measure_subdir] = args
          
          measure_subdir = "ResidentialConstructionsWallsInterzonal"
          args = {
                  "cavity_r"=>cavity_r,
                  "install_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                  "cavity_depth"=>cavity_depth,
                  "ins_fills_cavity"=>ins_fills_cavity,
                  "framing_factor"=>framing_factor
                 }  
          measures[measure_subdir] = args
          
        end
        
        measure_subdir = "ResidentialConstructionsWallsSheathing"
        args = {
                "osb_thick_in"=>mat_sheath.thick_in,
                "rigid_r"=>cont_r,
                "rigid_thick_in"=>cont_depth
               }
        measures[measure_subdir] = args

        measure_subdir = "ResidentialConstructionsWallsExteriorFinish"
        args = {
                "solar_abs"=>mat_siding.sAbs,
                "conductivity"=>mat_siding.k_in,
                "density"=>mat_siding.rho,
                "specific_heat"=>mat_siding.cp,
                "thick_in"=>mat_siding.thick_in,
                "emissivity"=>mat_siding.tAbs
               }
        measures[measure_subdir] = args

        break # FIXME
      
      else
      
        fail "Unexpected wall type."
        
      end
      
    end
    
    measure_subdir = "ResidentialConstructionsWallsExteriorThermalMass"
    args = {
            "thick_in1"=>mat_mass.thick_in,
            "thick_in2"=>nil,
            "cond1"=>mat_mass.k_in,
            "cond2"=>nil,
            "dens1"=>mat_mass.rho,
            "dens2"=>nil,
            "specheat1"=>mat_mass.cp,
            "specheat2"=>nil
           }
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialConstructionsWallsPartitionThermalMass"
    args = {
            "frac"=>"1.0",
            "thick_in1"=>mat_mass.thick_in,
            "thick_in2"=>nil,
            "cond1"=>mat_mass.k_in,
            "cond2"=>nil,
            "dens1"=>mat_mass.rho,
            "dens2"=>nil,
            "specheat1"=>mat_mass.cp,
            "specheat2"=>nil
           }
    measures[measure_subdir] = args

  end

  def self.get_other_constructions(building, measures)
  
    # FIXME

    measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
    args = {}
    measures[measure_subdir] = args

    measure_subdir = "ResidentialConstructionsFurnitureThermalMass"
    args = {
            "area_fraction"=>0.4,
            "mass"=>8.0,
            "solar_abs"=>0.6,
            "conductivity"=>BaseMaterial.Wood.k_in.to_s,
            "density"=>40.0,
            "specific_heat"=>BaseMaterial.Wood.cp.to_s,
           }
    measures[measure_subdir] = args
    
  end

  def self.get_water_heating(building, measures)

    dhw = building.elements["BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
    
    return if dhw.nil?
    
    setpoint_temp = Float(XMLHelper.get_value(dhw, "HotWaterTemperature"))
    tank_vol = Float(XMLHelper.get_value(dhw, "TankVolume"))
    wh_type = XMLHelper.get_value(dhw, "WaterHeaterType")
    fuel = XMLHelper.get_value(dhw, "FuelType")
    
    if wh_type == "storage water heater"
    
      ef = Float(XMLHelper.get_value(dhw, "EnergyFactor"))
      cap_btuh = Float(XMLHelper.get_value(dhw, "HeatingCapacity"))
      
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHotWaterHeaterTankElectric"
        args = {
                "tank_volume"=>tank_vol,
                "setpoint_temp"=>setpoint_temp,
                "location"=>Constants.Auto,
                "capacity"=>OpenStudio::convert(cap_btuh,"Btu/h","kW").get,
                "energy_factor"=>ef
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        re = Float(XMLHelper.get_value(dhw, "RecoveryEfficiency"))
        
        measure_subdir = "ResidentialHotWaterHeaterTankFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "tank_volume"=>tank_vol,
                "setpoint_temp"=>setpoint_temp,
                "location"=>Constants.Auto,
                "capacity"=>cap_btuh/1000.0,
                "energy_factor"=>ef,
                "recovery_efficiency"=>re,
                "offcyc_power"=>0,
                "oncyc_power"=>0
               }
        measures[measure_subdir] = args
        
      end      
      
    elsif wh_type == "instantaneous water heater"
    
      ef = Float(XMLHelper.get_value(dhw, "EnergyFactor"))
      ef_adj = Float(XMLHelper.get_value(dhw, "extension/PerformanceAdjustmentEnergyFactor"))
      
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHotWaterHeaterTanklessElectric"
        args = {
                "setpoint_temp"=>setpoint_temp,
                "location"=>Constants.Auto,
                "capacity"=>100000000.0,
                "energy_factor"=>ef,
                "cycling_derate"=>ef_adj
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
        
        measure_subdir = "ResidentialHotWaterHeaterTanklessFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "location"=>Constants.Auto,
                "capacity"=>100000000.0,
                "energy_factor"=>ef,
                "cycling_derate"=>ef_adj,
                "offcyc_power"=>0,
                "oncyc_power"=>0,
               }
        measures[measure_subdir] = args
        
      end
      
    elsif wh_type == "heat pump water heater"
    
      measure_subdir = "ResidentialHotWaterHeaterHeatPump"
      # FIXME
      args = {
              "storage_tank_volume"=>tank_vol,
              "setpoint_temp"=>setpoint_temp,
              "space"=>Constants.Auto,
              "element_capacity"=>4.5,
              "min_temp"=>45,
              "max_temp"=>120,
              "cap"=>0.5,
              "cop"=>2.8,
              "shr"=>0.88,
              "airflow_rate"=>181,
              "fan_power"=>0.0462,
              "parasitics"=>3,
              "tank_ua"=>3.9,
              "int_factor"=>1.0,
              "temp_depress"=>0
             }
      measures[measure_subdir] = args
      
    end
    
    # TODO: ResidentialHotWaterDistribution
    # TODO: ResidentialHotWaterFixtures
    # TODO: ResidentialHotWaterSolar

  end

  def self.get_heating_system(building, measures)

    htgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
    
    return if htgsys.nil?
    
    fuel = XMLHelper.get_value(htgsys, "HeatingSystemFuel")
    
    heat_capacity_btuh = XMLHelper.get_value(htgsys, "HeatingCapacity")
    if heat_capacity_btuh.nil?
      heat_capacity_kbtuh = Constants.SizingAuto
    else
      heat_capacity_kbtuh = OpenStudio.convert(heat_capacity_btuh.to_f, "Btu/hr", "kBtu/hr").get
    end
    
    if XMLHelper.has_element(htgsys, "HeatingSystemType/Furnace")
    
      afue = Float(XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value"))
    
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHVACFurnaceElectric"
        args = {
                "afue"=>afue,
                "fan_power_installed"=>0.5,
                "capacity"=>heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        measure_subdir = "ResidentialHVACFurnaceFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "afue"=>afue,
                "fan_power_installed"=>0.5,
                "capacity"=>heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      end
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/Boiler")
    
      afue = Float(XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value"))
    
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHVACBoilerElectric"
        args = {
                "system_type"=>Constants.BoilerTypeForcedDraft,
                "afue"=>afue,
                "oat_reset_enabled"=>"false",
                "oat_high"=>nil, # FIXME
                "oat_low"=>nil, # FIXME
                "oat_hwst_high"=>nil, # FIXME
                "oat_hwst_low"=>nil, # FIXME
                "design_temp"=>180, # FIXME
                "capacity"=>heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        measure_subdir = "ResidentialHVACBoilerFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "system_type"=>Constants.BoilerTypeForcedDraft,
                "afue"=>afue,
                "oat_reset_enabled"=>"false", # FIXME
                "oat_high"=>nil, # FIXME
                "oat_low"=>nil, # FIXME
                "oat_hwst_high"=>nil, # FIXME
                "oat_hwst_low"=>nil, # FIXME
                "design_temp"=>180, # FIXME
                "modulation"=>"false",
                "capacity"=>heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      end
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/ElectricResistance")
    
      percent = Float(XMLHelper.get_value(htgsys, "AnnualHeatingEfficiency[Units='Percent']/Value"))
    
      measure_subdir = "ResidentialHVACElectricBaseboard"
      args = {
              "efficiency"=>percent,
              "capacity"=>heat_capacity_kbtuh
             }
      measures[measure_subdir] = args
             
    end

  end

  def self.get_cooling_system(building, measures)
  
    clgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
    
    return if clgsys.nil?
    
    clg_type = XMLHelper.get_value(clgsys, "CoolingSystemType")
    
    cool_capacity_btuh = XMLHelper.get_value(clgsys, "CoolingCapacity")
    if cool_capacity_btuh.nil?
      cool_capacity_tons = Constants.SizingAuto
    else
      cool_capacity_tons = OpenStudio.convert(cool_capacity_btuh.to_f, "Btu/hr", "ton").get
    end
    
    if clg_type == "central air conditioning"
    
      seer_nom = Float(XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='SEER']/Value"))
      seer_adj = Float(XMLHelper.get_value(clgsys, "extension/PerformanceAdjustmentSEER"))
      seer = seer_nom * seer_adj
      num_speeds = XMLHelper.get_value(clgsys, "extension/NumberSpeeds")
      crankcase_kw = 0.0
      crankcase_temp = 55.0
    
      if num_speeds == "1-Speed"
      
        measure_subdir = "ResidentialHVACCentralAirConditionerSingleSpeed"
        args = {
                "seer"=>seer,
                "eer"=>0.82 * seer_nom + 0.64,       
                "shr"=>0.73,
                "fan_power_rated"=>0.365,
                "fan_power_installed"=>0.5,
                "crankcase_capacity"=>crankcase_kw,
                "crankcase_max_temp"=>crankcase_temp,
                "eer_capacity_derate_1ton"=>1,
                "eer_capacity_derate_2ton"=>1,
                "eer_capacity_derate_3ton"=>1,
                "eer_capacity_derate_4ton"=>1,
                "eer_capacity_derate_5ton"=>1,
                "capacity"=>cool_capacity_tons
               }
        measures[measure_subdir] = args
        
      elsif num_speeds == "2-Speed"
      
        measure_subdir = "ResidentialHVACCentralAirConditionerTwoSpeed"
        args = {
                "seer"=>seer,
                "eer"=>0.83 * seer_nom + 0.15,
                "eer2"=>0.56 * seer_nom + 3.57,
                "shr"=>0.71,
                "shr2"=>0.73,
                "capacity_ratio"=>0.72,
                "capacity_ratio2"=>1,
                "fan_speed_ratio"=>0.86,
                "fan_speed_ratio2"=>1,
                "fan_power_rated"=>0.14,
                "fan_power_installed"=>0.3,
                "crankcase_capacity"=>crankcase_kw,
                "crankcase_max_temp"=>crankcase_temp,
                "eer_capacity_derate_1ton"=>1,
                "eer_capacity_derate_2ton"=>1,
                "eer_capacity_derate_3ton"=>1,
                "eer_capacity_derate_4ton"=>1,
                "eer_capacity_derate_5ton"=>1,
                "capacity"=>cool_capacity_tons
               }
        measures[measure_subdir] = args
        
      elsif num_speeds == "Variable-Speed"
      
        measure_subdir = "ResidentialHVACCentralAirConditionerVariableSpeed"
        args = {
                "seer"=>seer,
                "eer"=>0.80 * seer_nom,
                "eer2"=>0.75 * seer_nom,
                "eer3"=>0.65 * seer_nom,
                "eer4"=>0.60 * seer_nom,
                "shr"=>0.98,
                "shr2"=>0.82,
                "shr3"=>0.745,
                "shr4"=>0.77,
                "capacity_ratio"=>0.36,
                "capacity_ratio2"=>0.64,
                "capacity_ratio3"=>1,
                "capacity_ratio4"=>1.16,
                "fan_speed_ratio"=>0.51,
                "fan_speed_ratio2"=>84,
                "fan_speed_ratio3"=>1,
                "fan_speed_ratio4"=>1.19,
                "fan_power_rated"=>0.14,
                "fan_power_installed"=>0.3,
                "crankcase_capacity"=>crankcase_kw,
                "crankcase_max_temp"=>crankcase_temp,
                "eer_capacity_derate_1ton"=>1,
                "eer_capacity_derate_2ton"=>1,
                "eer_capacity_derate_3ton"=>1,
                "eer_capacity_derate_4ton"=>1,
                "eer_capacity_derate_5ton"=>1,
                "capacity"=>cool_capacity_tons
               }
        measures[measure_subdir] = args
        
      else
      
        fail "Unexpected number of speeds (#{num_speeds}) for cooling system."
        
      end
      
    elsif clg_type == "room air conditioner"
    
      eer = Float(XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='EER']/Value"))

      measure_subdir = "ResidentialHVACRoomAirConditioner"
      args = {
              "eer"=>eer,
              "shr"=>0.65,
              "airflow_rate"=>350,
              "capacity"=>cool_capacity_tons
             }
      measures[measure_subdir] = args
      
    end  

  end

  def self.get_heat_pump(building, measures)

    hp = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"]
    
    return if hp.nil?
    
    hp_type = XMLHelper.get_value(hp, "HeatPumpType")
    num_speeds = XMLHelper.get_value(hp, "extension/NumberSpeeds")
    
    cool_capacity_btuh = XMLHelper.get_value(hp, "CoolingCapacity")
    if cool_capacity_btuh.nil?
      cool_capacity_tons = Constants.SizingAuto
    else
      cool_capacity_tons = OpenStudio.convert(cool_capacity_btuh.to_f, "Btu/hr", "ton").get
    end
    
    backup_heat_capacity_btuh = XMLHelper.get_value(hp, "BackupHeatingCapacity")
    if backup_heat_capacity_btuh.nil?
      backup_heat_capacity_kbtuh = Constants.SizingAuto
    else
      backup_heat_capacity_kbtuh = OpenStudio.convert(backup_heat_capacity_btuh.to_f, "Btu/hr", "kBtu/hr").get
    end
    
    if hp_type == "air-to-air"        
    
      seer_nom = Float(XMLHelper.get_value(hp, "AnnualCoolEfficiency[Units='SEER']/Value"))
      seer_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER"))
      seer = seer_nom * seer_adj
      hspf_nom = Float(XMLHelper.get_value(hp, "AnnualHeatEfficiency[Units='HSPF']/Value"))
      hspf_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentHSPF"))
      hspf = hspf_nom * hspf_adj
      
      crankcase_kw = 0.02
      crankcase_temp = 55.0
      
      if num_speeds == "1-Speed"
      
        measure_subdir = "ResidentialHVACAirSourceHeatPumpSingleSpeed"
        args = {
                "seer"=>seer,
                "hspf"=>hspf,
                "eer"=>0.80 * seer_nom + 1.0,
                "cop"=>0.45 * seer_nom - 0.34,
                "shr"=>0.73,
                "fan_power_rated"=>0.365,
                "fan_power_installed"=>0.5,
                "min_temp"=>0,
                "crankcase_capacity"=>crankcase_kw,
                "crankcase_max_temp"=>crankcase_temp,
                "eer_capacity_derate_1ton"=>1,
                "eer_capacity_derate_2ton"=>1,
                "eer_capacity_derate_3ton"=>1,
                "eer_capacity_derate_4ton"=>1,
                "eer_capacity_derate_5ton"=>1,
                "cop_capacity_derate_1ton"=>1,
                "cop_capacity_derate_2ton"=>1,
                "cop_capacity_derate_3ton"=>1,
                "cop_capacity_derate_4ton"=>1,
                "cop_capacity_derate_5ton"=>1,
                "heat_pump_capacity"=>cool_capacity_tons,
                "supplemental_capacity"=>backup_heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      elsif num_speeds == "2-Speed"
      
        measure_subdir = "ResidentialHVACAirSourceHeatPumpTwoSpeed"
        args = {
                "seer"=>seer,
                "hspf"=>hspf,
                "eer"=>0.78 * seer_nom + 0.6,
                "eer2"=>0.68 * seer_nom + 1.0,
                "cop"=>0.60 * seer_nom - 1.40,
                "cop2"=>0.50 * seer_nom - 0.94,
                "shr"=>0.71,
                "shr2"=>0.724,
                "capacity_ratio"=>0.72,
                "capacity_ratio2"=>1,
                "fan_speed_ratio_cooling"=>0.86,
                "fan_speed_ratio_cooling2"=>1,
                "fan_speed_ratio_heating"=>0.8,
                "fan_speed_ratio_heating2"=>1,
                "fan_power_rated"=>0.14,
                "fan_power_installed"=>0.3,
                "min_temp"=>0,
                "crankcase_capacity"=>crankcase_kw,
                "crankcase_max_temp"=>crankcase_temp,
                "eer_capacity_derate_1ton"=>1,
                "eer_capacity_derate_2ton"=>1,
                "eer_capacity_derate_3ton"=>1,
                "eer_capacity_derate_4ton"=>1,
                "eer_capacity_derate_5ton"=>1,
                "cop_capacity_derate_1ton"=>1,
                "cop_capacity_derate_2ton"=>1,
                "cop_capacity_derate_3ton"=>1,
                "cop_capacity_derate_4ton"=>1,
                "cop_capacity_derate_5ton"=>1,
                "heat_pump_capacity"=>cool_capacity_tons,
                "supplemental_capacity"=>backup_heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      elsif num_speeds == "Variable-Speed"
      
        measure_subdir = "ResidentialHVACAirSourceHeatPumpVariableSpeed"
        args = {
                "seer"=>seer,
                "hspf"=>hspf,
                "eer"=>0.80 * seer_nom,
                "eer2"=>0.75 * seer_nom,
                "eer3"=>0.65 * seer_nom,
                "eer4"=>0.60 * seer_nom,
                "cop"=>0.48 * seer_nom,
                "cop2"=>0.45 * seer_nom,
                "cop3"=>0.39 * seer_nom,
                "cop4"=>0.39 * seer_nom,                  
                "shr"=>0.84,
                "shr2"=>0.79,
                "shr3"=>0.76,
                "shr4"=>0.77,
                "capacity_ratio"=>0.49,
                "capacity_ratio2"=>0.67,
                "capacity_ratio3"=>0.1,
                "capacity_ratio4"=>1.2,
                "fan_speed_ratio_cooling"=>0.7,
                "fan_speed_ratio_cooling2"=>0.9,
                "fan_speed_ratio_cooling3"=>1,
                "fan_speed_ratio_cooling4"=>1.26,                  
                "fan_speed_ratio_heating"=>0.74,
                "fan_speed_ratio_heating2"=>0.92,
                "fan_speed_ratio_heating3"=>1,
                "fan_speed_ratio_heating4"=>1.22,                  
                "fan_power_rated"=>0.14,
                "fan_power_installed"=>0.3,
                "min_temp"=>0,
                "crankcase_capacity"=>crankcase_kw,
                "crankcase_max_temp"=>crankcase_temp,
                "eer_capacity_derate_1ton"=>1,
                "eer_capacity_derate_2ton"=>1,
                "eer_capacity_derate_3ton"=>1,
                "eer_capacity_derate_4ton"=>1,
                "eer_capacity_derate_5ton"=>1,
                "cop_capacity_derate_1ton"=>1,
                "cop_capacity_derate_2ton"=>1,
                "cop_capacity_derate_3ton"=>1,
                "cop_capacity_derate_4ton"=>1,
                "cop_capacity_derate_5ton"=>1,
                "heat_pump_capacity"=>cool_capacity_tons,
                "supplemental_capacity"=>backup_heat_capacity_kbtuh
               }
        measures[measure_subdir] = args
        
      else
      
        fail "Unexpected number of speeds (#{num_speeds}) for heat pump system."
        
      end
      
    elsif hp_type == "mini-split"
      
      seer_nom = Float(XMLHelper.get_value(hp, "AnnualCoolEfficiency[Units='SEER']/Value"))
      seer_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER"))
      seer = seer_nom * seer_adj
      hspf_nom = Float(XMLHelper.get_value(hp, "AnnualHeatEfficiency[Units='HSPF']/Value"))
      hspf_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentHSPF"))
      hspf = hspf_nom * hspf_adj
      
      measure_subdir = "ResidentialHVACMiniSplitHeatPump"
      args = {
              "seer"=>seer,
              "min_cooling_capacity"=>0.4,
              "max_cooling_capacity"=>1.2,
              "shr"=>0.73,
              "min_cooling_airflow_rate"=>200,
              "max_cooling_airflow_rate"=>425,
              "hspf"=>hspf,
              "heating_capacity_offset"=>2300,
              "min_heating_capacity"=>0.3,
              "max_heating_capacity"=>1.2,
              "min_heating_airflow_rate"=>200,
              "max_heating_airflow_rate"=>400,
              "cap_retention_frac"=>0.25,
              "cap_retention_temp"=>-5,
              "pan_heater_power"=>0,
              "fan_power"=>0.07,
              "heat_pump_capacity"=>cool_capacity_tons,
              "supplemental_efficiency"=>1,
              "supplemental_capacity"=>backup_heat_capacity_kbtuh
             }
      measures[measure_subdir] = args
             
    elsif hp_type == "ground-to-air"
    
      eer = Float(XMLHelper.get_value(hp, "AnnualCoolEfficiency[Units='EER']/Value"))
      cop = Float(XMLHelper.get_value(hp, "AnnualHeatEfficiency[Units='COP']/Value"))
    
      measure_subdir = "ResidentialHVACGroundSourceHeatPumpVerticalBore"
      args = {
              "cop"=>cop.to_s,
              "eer"=>eer.to_s,
              "ground_conductivity"=>"0.6",
              "grout_conductivity"=>"0.4",
              "bore_config"=>Constants.SizingAuto,
              "bore_holes"=>Constants.SizingAuto,
              "bore_depth"=>Constants.SizingAuto,
              "bore_spacing"=>"20.0",
              "bore_diameter"=>"5.0",
              "pipe_size"=>"0.75",
              "ground_diffusivity"=>"0.0208",
              "fluid_type"=>Constants.FluidPropyleneGlycol,
              "frac_glycol"=>"0.3",
              "design_delta_t"=>"10.0",
              "pump_head"=>"50.0",
              "u_tube_leg_spacing"=>"0.9661",
              "u_tube_spacing_type"=>"b",
              "rated_shr"=>"0.732",
              "fan_power"=>"0.5",
              "heat_pump_capacity"=>cool_capacity_tons.to_s,
              "supplemental_capacity"=>backup_heat_capacity_kbtuh.to_s
             }
      measures[measure_subdir] = args
             
    end

  end

  def self.get_setpoints(building, measures) 

    control = building.elements["BuildingDetails/Systems/HVAC/HVACControl"]
  
    htg_sp = Float(XMLHelper.get_value(control, "SetpointTempHeatingSeason"))
    clg_sp = Float(XMLHelper.get_value(control, "SetpointTempCoolingSeason"))
    
    measure_subdir = "ResidentialHVACHeatingSetpoints"
    args = {
            "htg_wkdy"=>htg_sp.to_s,
            "htg_wked"=>htg_sp.to_s
           }  
    measures[measure_subdir] = args
    
    measure_subdir = "ResidentialHVACCoolingSetpoints"
    args = {
            "clg_wkdy"=>clg_sp.to_s,
            "clg_wked"=>clg_sp.to_s
           }  
    measures[measure_subdir] = args

  end

  def self.get_ceiling_fan(building, measures)

    # FIXME
    cf = building.elements["BuildingDetails/Lighting/CeilingFan"]
    
    measure_subdir = "ResidentialHVACCeilingFan"
    args = {
            "coverage"=>"NA",
            "specified_num"=>"1",
            "power"=>"45",
            "control"=>"typical",
            "use_benchmark_energy"=>"true",
            "mult"=>"1",
            "cooling_setpoint_offset"=>"0",
            "weekday_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "weekend_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "monthly_sch"=>"1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248"
           }  
    measures[measure_subdir] = args

  end

  def self.get_dehumidifier(building, measures)
  
    dehumidifier = building.elements["BuildingDetails/Systems/HVAC/extension/dehumidifier"]
    
    return if dehumidifier.nil?
    
    air_flow_rate = XMLHelper.get_value(dehumidifier, "air_flow_rate")
    energy_factor = XMLHelper.get_value(dehumidifier, "energy_factor")
    humidity_setpoint = XMLHelper.get_value(dehumidifier, "humidity_setpoint")
    water_removal_rate = XMLHelper.get_value(dehumidifier, "water_removal_rate")
  
    measure_subdir = "ResidentialHVACDehumidifier"
    args = {
            "air_flow_rate"=>air_flow_rate.to_s,
            "energy_factor"=>energy_factor.to_s,
            "humidity_setpoint"=>humidity_setpoint.to_s,
            "water_removal_rate"=>water_removal_rate.to_s
           }  
    measures[measure_subdir] = args    
  
  end
  
  def self.get_refrigerator(building, measures)

    fridge = building.elements["BuildingDetails/Appliances/Refrigerator"]
    
    kWhs = Float(XMLHelper.get_value(fridge, "RatedAnnualkWh"))
    
    measure_subdir = "ResidentialApplianceRefrigerator"  
    args = {
            "fridge_E"=>kWhs.to_s,
            "mult"=>"1",
            "weekday_sch"=>"0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041",
            "weekend_sch"=>"0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041",
            "monthly_sch"=>"0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837",
            "space"=>Constants.Auto
           }  
    measures[measure_subdir] = args
    
  end

  def self.get_clothes_washer(building, measures)

    # FIXME
    cw = building.elements["BuildingDetails/Appliances/ClothesWasher"]
    
    measure_subdir = "ResidentialApplianceClothesWasher"  
    args = {
            "imef"=>"0.95",
            "rated_annual_energy"=>"387",
            "annual_cost"=>"24",
            "test_date"=>"2007",
            "drum_volume"=>"3.5",
            "cold_cycle"=>"false",
            "thermostatic_control"=>"true",
            "internal_heater"=>"false",
            "fill_sensor"=>"false",
            "mult_e"=>"1",
            "mult_hw"=>"1",
            "space"=>Constants.Auto,
            "plant_loop"=>Constants.Auto
           }  
    measures[measure_subdir] = args
    
  end

  def self.get_clothes_dryer(building, measures)
    
    # FIXME
    cd = building.elements["BuildingDetails/Appliances/ClothesDryer"]
    
    cd_fuel = XMLHelper.get_value(cd, "FuelType")
    
    if cd_fuel == "electricity"
      measure_subdir = "ResidentialApplianceClothesDryerElectric"
      args = {
              "cef"=>"2.7",
              "mult"=>"1",
              "weekday_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "weekend_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    else
      measure_subdir = "ResidentialApplianceClothesDryerFuel"
      args = {
              "fuel_type"=>to_beopt_fuel(cd_fuel),
              "cef"=>"2.4",
              "fuel_split"=>"0.07",
              "mult"=>"1",
              "weekday_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "weekend_sch"=>"0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024",
              "monthly_sch"=>"1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    end
    
  end

  def self.get_dishwasher(building, measures)

    # FIXME
    dw = building.elements["BuildingDetails/Appliances/Dishwasher"]
    
    measure_subdir = "ResidentialApplianceDishwasher"
    args = {
            "num_settings"=>"12",
            "dw_E"=>"290",
            "int_htr"=>"true",
            "cold_inlet"=>"false",
            "cold_use"=>"0",
            "eg_date"=>"2007",
            "eg_gas_cost"=>"23",
            "mult_e"=>"1",
            "mult_hw"=>"1",
            "space"=>Constants.Auto,
            "plant_loop"=>Constants.Auto
           }  
    measures[measure_subdir] = args

  end

  def self.get_cooking_range(building, measures)
    
    # FIXME
    crange = building.elements["BuildingDetails/Appliances/CookingRange"]
    ov = building.elements["BuildingDetails/Appliances/Oven"] # TODO
    
    crange_fuel = XMLHelper.get_value(crange, "FuelType")
    
    if crange_fuel == "electricity"
      measure_subdir = "ResidentialApplianceCookingRangeElectric"
      args = {
              "c_ef"=>"0.74",
              "o_ef"=>"0.11",
              "mult"=>"1",
              "weekday_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "weekend_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "monthly_sch"=>"1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    else
      measure_subdir = "ResidentialApplianceCookingRangeFuel"
      args = {
              "fuel_type"=>to_beopt_fuel(crange_fuel),
              "c_ef"=>"0.4",
              "o_ef"=>"0.058",
              "e_ignition"=>"true",
              "mult"=>"1",
              "weekday_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "weekend_sch"=>"0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011",
              "monthly_sch"=>"1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097",
              "space"=>Constants.Auto
             }
      measures[measure_subdir] = args
    end
    
  end

  def self.get_lighting(building, measures)
  
    lighting = building.elements["BuildingDetails/Lighting"]
  
    annual_kwh_interior = Float(XMLHelper.get_value(lighting, "extension/AnnualInteriorkWh"))
    annual_kwh_exterior = Float(XMLHelper.get_value(lighting, "extension/AnnualExteriorkWh"))
    annual_kwh_garage = Float(XMLHelper.get_value(lighting, "extension/AnnualGaragekWh"))

    measure_subdir = "ResidentialLighting"
    args = {
            "option_type"=>Constants.OptionTypeLightingEnergyUses,
            "hw_cfl"=>"0", # not used
            "hw_led"=>"0", # not used
            "hw_lfl"=>"0", # not used
            "pg_cfl"=>"0", # not used
            "pg_led"=>"0", # not used
            "pg_lfl"=>"0", # not used
            "in_eff"=>"15", # not used
            "cfl_eff"=>"55", # not used
            "led_eff"=>"80", # not used
            "lfl_eff"=>"88", # not used
            "energy_use_interior"=>annual_kwh_interior.to_s,
            "energy_use_exterior"=>annual_kwh_exterior.to_s,
            "energy_use_garage"=>annual_kwh_garage.to_s
           }  
    measures[measure_subdir] = args  

  end
  
  def self.get_mels(building, measures)
  
    # TODO: Split apart residual MELs and TVs for reporting
    
    sens_kWhs = 0
    lat_kWhs = 0
    building.elements.each("BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other' or PlugLoadType='TV other']") do |pl|
      kWhs = Float(XMLHelper.get_value(pl, "Load[Units='kWh/year']/Value"))
      if XMLHelper.has_element(pl, "extension/FracSensible") and XMLHelper.has_element(pl, "extension/FracLatent")
        sens_kWhs += kWhs * Float(XMLHelper.get_value(pl, "extension/FracSensible"))
        lat_kWhs += kWhs * Float(XMLHelper.get_value(pl, "extension/FracLatent"))
      else # No fractions; all sensible
        sens_kWhs += kWhs
      end
    end
    tot_kWhs = sens_kWhs + lat_kWhs
    
    measure_subdir = "ResidentialMiscPlugLoads"
    args = {
            "option_type"=>Constants.OptionTypePlugLoadsEnergyUse,
            "mult"=>"0", # not used
            "energy_use"=>tot_kWhs.to_s,
            "sens_frac"=>(sens_kWhs/tot_kWhs).to_s,
            "lat_frac"=>(lat_kWhs/tot_kWhs).to_s,
            "weekday_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "weekend_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "monthly_sch"=>"1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248",
           }  
    measures[measure_subdir] = args  
  
  end

  def self.get_airflow(building, measures)
  
    infil = building.elements["BuildingDetails/Enclosure/AirInfiltration"]
    whole_house_fan = building.elements["BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation='true']"]
    
    infil_ach50 = Float(XMLHelper.get_value(infil, "AirInfiltrationMeasurement/BuildingAirLeakage[UnitofMeasure='ACH']/AirLeakage"))
    attic_sla = XMLHelper.get_value(infil, "extension/AtticSpecificLeakageArea").to_f
    crawl_sla = XMLHelper.get_value(infil, "extension/CrawlspaceSpecificLeakageArea").to_f

    if whole_house_fan.nil?
      mech_vent_type = Constants.VentTypeNone
      mech_vent_total_efficiency = 0
      mech_vent_sensible_efficiency = 0
      mech_vent_fan_power = 0
      mech_vent_frac_62_2 = 0
    else
      fan_type = XMLHelper.get_value(whole_house_fan, "FanType")
      if fan_type == "supply only"
        mech_vent_type = Constants.VentTypeSupply
      elsif fan_type == "exhaust only"
        mech_vent_type = Constants.VentTypeExhaust
      else
        mech_vent_type = Constants.VentTypeBalanced
      end
      mech_vent_total_efficiency = 0
      mech_vent_sensible_efficiency = 0
      if fan_type == "energy recovery ventilator" or fan_type == "heat recovery ventilator"
        mech_vent_sensible_efficiency = Float(XMLHelper.get_value(whole_house_fan, "SensibleRecoveryEfficiency"))
      end
      if fan_type == "energy recovery ventilator"
        mech_vent_total_efficiency = Float(XMLHelper.get_value(whole_house_fan, "TotalRecoveryEfficiency"))
      end
      mech_vent_fan_power = Float(XMLHelper.get_value(whole_house_fan, "extension/FanPowerWperCFM"))
      mech_vent_frac_62_2 = Float(XMLHelper.get_value(whole_house_fan, "extension/Frac2013ASHRAE622"))
    end
    
    natural_ventilation = building.elements["BuildingDetails/Systems/HVAC/extension/natural_ventilation"]
    
    if natural_ventilation.nil?
      nat_vent_htg_offset = "1"
      nat_vent_clg_offset = "1"
      nat_vent_ovlp_offset = "1"
      nat_vent_htg_season = "true"
      nat_vent_clg_season = "true"
      nat_vent_ovlp_season = "true"
      nat_vent_num_weekdays = "5"
      nat_vent_num_weekends = "2"
      nat_vent_frac_windows_open = "0.33"
      nat_vent_frac_window_area_openable = "0.2"
      nat_vent_max_oa_hr = "0.0115"
      nat_vent_max_oa_rh = "0.7"
    else
      nat_vent_htg_offset = XMLHelper.get_value(natural_ventilation, "nat_vent_htg_offset")
      nat_vent_clg_offset = XMLHelper.get_value(natural_ventilation, "nat_vent_clg_offset")
      nat_vent_ovlp_offset = XMLHelper.get_value(natural_ventilation, "nat_vent_ovlp_offset")
      nat_vent_htg_season = XMLHelper.get_value(natural_ventilation, "nat_vent_htg_season")
      nat_vent_clg_season = XMLHelper.get_value(natural_ventilation, "nat_vent_clg_season")
      nat_vent_ovlp_season = XMLHelper.get_value(natural_ventilation, "nat_vent_ovlp_season")
      nat_vent_num_weekdays = XMLHelper.get_value(natural_ventilation, "nat_vent_num_weekdays")
      nat_vent_num_weekends = XMLHelper.get_value(natural_ventilation, "nat_vent_num_weekends")
      nat_vent_frac_windows_open = XMLHelper.get_value(natural_ventilation, "nat_vent_frac_windows_open")
      nat_vent_frac_window_area_openable = XMLHelper.get_value(natural_ventilation, "nat_vent_frac_window_area_openable")
      nat_vent_max_oa_hr = XMLHelper.get_value(natural_ventilation, "nat_vent_max_oa_hr")
      nat_vent_max_oa_rh = XMLHelper.get_value(natural_ventilation, "nat_vent_max_oa_rh")
    end
  
    air_distribution = building.elements["BuildingDetails/Systems/HVAC/HVACDistribution/DistributionSystemType/AirDistribution"]
    
    if air_distribution.nil?
      duct_location = Constants.Auto
      duct_total_leakage = "0.3"
      duct_supply_frac = "0.6"
      duct_return_frac = "0.067"
      duct_ah_supply_frac = "0.067"
      duct_ah_return_frac = "0.267"
      duct_location_frac = Constants.Auto
      duct_num_returns = Constants.Auto
      duct_supply_area_mult = "1"
      duct_return_area_mult = "1"
      duct_unconditioned_r = "0"
    else
      duct_location = Constants.Auto
      duct_total_leakage = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageMeasurement/extension/duct_total_leakage")
      duct_supply_frac = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageMeasurement/extension/duct_supply_frac")
      duct_return_frac = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageMeasurement/extension/duct_return_frac")
      duct_ah_supply_frac = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageMeasurement/extension/duct_ah_supply_frac")
      duct_ah_return_frac = XMLHelper.get_value(duct_leakage_measurement, "DuctLeakageMeasurement/extension/duct_ah_return_frac")
      duct_location_frac = Constants.Auto
      duct_num_returns = XMLHelper.get_value(air_distribution, "NumberofReturnRegisters")
      duct_supply_area_mult = "1"
      duct_return_area_mult = "1"      
      duct_unconditioned_r = XMLHelper.get_value(air_distribution, "Ducts[DuctType='return']/DuctInsulationRValue")
    end
  
    measure_subdir = "ResidentialAirflow"
    args = {
            "living_ach50"=>infil_ach50.to_s,
            "garage_ach50"=>infil_ach50.to_s,
            "finished_basement_ach"=>"0", # TODO: Need to handle above-grade basement
            "unfinished_basement_ach"=>"0.1", # TODO: Need to handle above-grade basement
            "crawl_ach"=>crawl_sla.to_s,
            "pier_beam_ach"=>"100",
            "unfinished_attic_sla"=>attic_sla.to_s,
            "shelter_coef"=>Constants.Auto,
            "has_hvac_flue"=>"false", # FIXME
            "has_water_heater_flue"=>"false", # FIXME
            "has_fireplace_chimney"=>"false", # FIXME
            "terrain"=>"suburban",
            "mech_vent_type"=>mech_vent_type.to_s,
            "mech_vent_total_efficiency"=>mech_vent_total_efficiency.to_s,
            "mech_vent_sensible_efficiency"=>mech_vent_sensible_efficiency.to_s,
            "mech_vent_fan_power"=>mech_vent_fan_power.to_s,
            "mech_vent_frac_62_2"=>mech_vent_frac_62_2.to_s,
            "mech_vent_ashrae_std"=>"2013",
            "mech_vent_infil_credit"=>"true",
            "is_existing_home"=>"false", # FIXME
            "clothes_dryer_exhaust"=>"0",
            "nat_vent_htg_offset"=>nat_vent_htg_offset,
            "nat_vent_clg_offset"=>nat_vent_clg_offset,
            "nat_vent_ovlp_offset"=>nat_vent_ovlp_offset,
            "nat_vent_htg_season"=>nat_vent_htg_season,
            "nat_vent_clg_season"=>nat_vent_clg_season,
            "nat_vent_ovlp_season"=>nat_vent_ovlp_season,
            "nat_vent_num_weekdays"=>nat_vent_num_weekdays,
            "nat_vent_num_weekends"=>nat_vent_num_weekends,
            "nat_vent_frac_windows_open"=>nat_vent_frac_windows_open,
            "nat_vent_frac_window_area_openable"=>nat_vent_frac_window_area_openable,
            "nat_vent_max_oa_hr"=>nat_vent_max_oa_hr,
            "nat_vent_max_oa_rh"=>nat_vent_max_oa_rh,
            "duct_location"=>duct_location, # FIXME
            "duct_total_leakage"=>duct_total_leakage, # FIXME
            "duct_supply_frac"=>duct_supply_frac, # FIXME
            "duct_return_frac"=>duct_return_frac, # FIXME
            "duct_ah_supply_frac"=>duct_ah_supply_frac, # FIXME
            "duct_ah_return_frac"=>duct_ah_return_frac, # FIXME
            "duct_location_frac"=>duct_location_frac, # FIXME
            "duct_num_returns"=>duct_num_returns, # FIXME
            "duct_supply_area_mult"=>duct_supply_area_mult, # FIXME
            "duct_return_area_mult"=>duct_return_area_mult, # FIXME
            "duct_unconditioned_r"=>duct_unconditioned_r # FIXME
           }  
    # measures[measure_subdir] = args # FIXME (need to figure out approach for dealing with volumes)

  end

  def self.get_hvac_sizing(building, measures)
    
    measure_subdir = "ResidentialHVACSizing"
    args = {
            "show_debug_info"=>"false"
           }  
    # measures[measure_subdir] = args # FIXME (need to figure out approach for dealing with volumes)

  end

  def self.get_photovoltaics(building, measures)

    pvsys = building.elements["BuildingDetails/Systems/Photovoltaics/PVSystem"]
    
    if not pvsys.nil?
    
      az = Float(XMLHelper.get_value(pvsys, "ArrayAzimuth"))
      tilt = Float(XMLHelper.get_value(pvsys, "ArrayTilt"))
      inv_eff = Float(XMLHelper.get_value(pvsys, "InverterEfficiency"))
      power_kw = Float(XMLHelper.get_value(pvsys, "MaxPowerOutput"))/1000.0
      
      measure_subdir = "ResidentialPhotovoltaics"
      args = {
              "size"=>power_kw.to_s,
              "module_type"=>Constants.PVModuleTypeStandard,
              "system_losses"=>"0.14",
              "inverter_efficiency"=>inv_eff.to_s,
              "azimuth_type"=>Constants.CoordAbsolute,
              "azimuth"=>az.to_s, # TODO: Double-check
              "tilt_type"=>Constants.CoordAbsolute,
              "tilt"=>tilt.to_s # TODO: Double-check
             }  
      measures[measure_subdir] = args
      
    end

  end
  
end

class OSModel

  def self.create_geometry(building, runner, model)

    geometry_errors = []
  
    # Geometry
    avg_ceil_hgt = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/AverageCeilingHeight"]
    if avg_ceil_hgt.nil?
      avg_ceil_hgt = 8.0
    else
      avg_ceil_hgt = avg_ceil_hgt.text.to_f
    end
    
    foundation_spaces = {}
    fenestration_areas = {}
    living_space = build_living_space(model, building)
    attic_space, attic_zone = build_attic_space(model, building)
    add_windows(model, building, geometry_errors, living_space, fenestration_areas)
    add_doors(model, building, geometry_errors, living_space, fenestration_areas)
    add_foundation_floors(model, building, living_space, foundation_spaces)
    add_foundation_walls(model, building, living_space, foundation_spaces, fenestration_areas)
    foundation_ceiling_area = add_foundation_ceilings(model, building, living_space, foundation_spaces)
    add_living_floors(model, building, geometry_errors, living_space, foundation_ceiling_area)
    add_living_walls(model, building, geometry_errors, avg_ceil_hgt, living_space, attic_space, fenestration_areas)
    add_attic_floors(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)
    add_attic_walls(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space, fenestration_areas)
    add_attic_ceilings(model, building, geometry_errors, avg_ceil_hgt, attic_space, living_space)    
    
    geometry_errors.each do |error|
      runner.registerError(error)
    end

    unless geometry_errors.empty?
      return false
    end    
    
    # Set the zone volumes based on the sum of space volumes
    model.getThermalZones.each do |thermal_zone|
      zone_volume = 0
      if not Geometry.get_volume_from_spaces(thermal_zone.spaces) > 0 # space doesn't have a floor
        if thermal_zone.name.to_s == Constants.CrawlZone
          floor_area = nil
          thermal_zone.spaces.each do |space|
            space.surfaces.each do |surface|
              next unless surface.surfaceType.downcase == "roofceiling"
              floor_area = surface.grossArea
            end
          end
          zone_volume = OpenStudio.convert(floor_area,"m^2","ft^2").get * Geometry.get_height_of_spaces(thermal_zone.spaces)
        end
      else # space has a floor
        zone_volume = Geometry.get_volume_from_spaces(thermal_zone.spaces)
      end
      thermal_zone.setVolume(OpenStudio.convert(zone_volume,"ft^3","m^3").get)
    end
    
    # Explode the walls
    wall_offset = 10.0
    surfaces_moved = []
    model.getSurfaces.each do |surface|

      next unless surface.surfaceType.downcase == "wall"
      next if surface.subSurfaces.any? { |subsurface| subsurface.subSurfaceType.downcase == "fixedwindow" }
      
      if surface.adjacentSurface.is_initialized
        next if surfaces_moved.include? surface.adjacentSurface.get
      end
      
      transformation = get_surface_transformation(wall_offset, surface.outwardNormal.x, surface.outwardNormal.y, 0)   
      
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.setVertices(transformation * surface.vertices)
      
      surface.subSurfaces.each do |subsurface|
        next unless subsurface.subSurfaceType.downcase == "door"
        subsurface.setVertices(transformation * subsurface.vertices)
      end
      
      wall_offset += 2.5
      
      surfaces_moved << surface
      
    end
    
    # Explode the floors
    floor_offset = 0.0
    surfaces_moved = []
    model.getSurfaces.each do |surface|

      next unless surface.surfaceType.downcase == "floor" or surface.surfaceType.downcase == "roofceiling"
      
      if surface.adjacentSurface.is_initialized
        next if surfaces_moved.include? surface.adjacentSurface.get
      end
      
      transformation = get_surface_transformation(floor_offset, 0, 0, surface.outwardNormal.z)

      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.setVertices(transformation * surface.vertices)
      
      floor_offset += 2.5
      
      surfaces_moved << surface
      
    end
    
    # Explode the windows TODO: calculate window_offset dynamically
    window_offset = 50.0
    model.getSubSurfaces.each do |sub_surface|

      next unless sub_surface.subSurfaceType.downcase == "fixedwindow"
      
      transformation = get_surface_transformation(window_offset, sub_surface.outwardNormal.x, sub_surface.outwardNormal.y, 0)

      surface = sub_surface.surface.get
      sub_surface.setVertices(transformation * sub_surface.vertices)      
      if surface.adjacentSurface.is_initialized
        surface.adjacentSurface.get.setVertices(transformation * surface.adjacentSurface.get.vertices)
      end
      surface.setVertices(transformation * surface.vertices)
      
      window_offset += 2.5
      
    end
    
    # Store building name
    model.getBuilding.setName("FIXME")
        
    # Store building unit information
    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
    unit.setName(Constants.ObjectNameBuildingUnit)
    model.getSpaces.each do |space|
      space.setBuildingUnit(unit)
    end

    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(1)    
    
    # Store number of stories
    num_floors = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/NumberofStoriesAboveGrade"]
    if num_floors.nil?
      num_floors = 1
    else
      num_floors = num_floors.text.to_i
    end    
    
    if (REXML::XPath.first(building, "count(BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cathedral ceiling'])") + REXML::XPath.first(building, "count(BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic[AtticType='cape cod'])")) > 0
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(num_floors)
    model.getSpaces.each do |space|
      if space.name.to_s == Constants.FinishedBasementSpace
        num_floors += 1  
        break
      end
    end
    model.getBuilding.setStandardsNumberOfStories(num_floors)
    
    # Store the building type
    facility_types_map = {"single-family detached"=>Constants.BuildingTypeSingleFamilyDetached}
    model.getBuilding.setStandardsBuildingType(facility_types_map[building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ResidentialFacilityType"].text])

    return true
    
  end

  def self.get_surface_transformation(offset, x, y, z)
  
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0,0] = 1
    m[1,1] = 1
    m[2,2] = 1
    m[3,3] = 1
    m[0,3] = x * offset
    m[1,3] = y * offset
    m[2,3] = z.abs * offset
 
    return OpenStudio::Transformation.new(m)
      
  end
  
  def self.add_floor_polygon(x, y, z)
      
    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0-x/2, 0-y/2, z)
    vertices << OpenStudio::Point3d.new(0-x/2, y/2, z)
    vertices << OpenStudio::Point3d.new(x/2, y/2, z)
    vertices << OpenStudio::Point3d.new(x/2, 0-y/2, z)
      
    return vertices
      
  end

  def self.add_wall_polygon(x, y, z, azimuth=0, offsets=[0]*4)

    vertices = OpenStudio::Point3dVector.new
    vertices << OpenStudio::Point3d.new(0-(x/2) - offsets[1], 0, z - offsets[0])
    vertices << OpenStudio::Point3d.new(0-(x/2) - offsets[1], 0, z + y + offsets[2])
    vertices << OpenStudio::Point3d.new(x-(x/2) + offsets[3], 0, z + y + offsets[2])
    vertices << OpenStudio::Point3d.new(x-(x/2) + offsets[3], 0, z - offsets[0])
    
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0,0] = Math::cos(-azimuth * Math::PI / 180.0)
    m[1,1] = Math::cos(-azimuth * Math::PI / 180.0)
    m[0,1] = -Math::sin(-azimuth * Math::PI / 180.0)
    m[1,0] = Math::sin(-azimuth * Math::PI / 180.0)
    m[2,2] = 1
    m[3,3] = 1
    transformation = OpenStudio::Transformation.new(m)
  
    return transformation * vertices
      
  end

  def self.add_ceiling_polygon(x, y, z)
      
    return OpenStudio::reverse(add_floor_polygon(x, y, z))
      
  end

  def self.build_living_space(model, building)
      
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName(Constants.LivingZone)
    living_space = OpenStudio::Model::Space.new(model)
    living_space.setName(Constants.LivingSpace)
    living_space.setThermalZone(living_zone)   
    
    return living_space
      
  end

  def self.net_wall_area(gross_wall_area, wall_fenestration_areas, wall_id)
    if wall_fenestration_areas.keys.include? wall_id
      return gross_wall_area - OpenStudio.convert(wall_fenestration_areas[wall_id],"ft^2","m^2").get
    end    
    return gross_wall_area
  end
  
  def self.add_living_walls(model, building, errors, avg_ceil_hgt, living_space, attic_space, fenestration_areas)

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "living space"
      next if wall.elements["Area"].nil?
    
      wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
      wall_length = net_wall_area(OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get, fenestration_areas, wall.elements["SystemIdentifier"].attributes["id"]) / wall_height

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, 0), model)
      surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
      surface.setSurfaceType("Wall") 
      surface.setSpace(living_space)
      if wall.elements["ExteriorAdjacentTo"].text == "attic"
        surface.createAdjacentSurface(attic_space)
      elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
        surface.setOutsideBoundaryCondition("Outdoors")
      else
        errors << "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
      end
      
    end
    
  end

  def self.build_foundation_spaces(model, foundation_type)

    unless foundation_type.nil?
      foundation_space_name = nil
      if foundation_type.elements["Basement/Conditioned/text()='true'"] or foundation_type.elements["Basement/Finished/text()='true'"]
        foundation_space_name = Constants.FinishedBasementSpace
      elsif foundation_type.elements["Basement/Conditioned/text()='false'"] or foundation_type.elements["Basement/Finished/text()='false'"]
        foundation_space_name = Constants.UnfinishedBasementSpace
      elsif foundation_type.elements["Crawlspace/Vented/text()='true'"] or foundation_type.elements["Crawlspace/Vented/text()='false'"] or foundation_type.elements["Crawlspace/Conditioned/text()='true'"] or foundation_type.elements["Crawlspace/Conditioned/text()='false'"]
        foundation_space_name = Constants.CrawlSpace
      elsif foundation_type.elements["Garage/Conditioned/text()='true'"] or foundation_type.elements["Garage/Conditioned/text()='false'"]
        foundation_space_name = Constants.GarageSpace
      end
      if not foundation_space_name.nil?
        foundation_space = OpenStudio::Model::Space.new(model)
        foundation_space.setName(foundation_space_name)
      end
    end
    
    return foundation_space
      
  end
  
  def self.build_foundation_zones(model, foundation_spaces)
  
    foundation_spaces.each do |foundation_type, spaces|
    
      foundation_zone_name = nil
      if foundation_type.elements["Basement/Conditioned/text()='true'"] or foundation_type.elements["Basement/Finished/text()='true'"]
        foundation_zone_name = Constants.FinishedBasementZone
      elsif foundation_type.elements["Basement/Conditioned/text()='false'"] or foundation_type.elements["Basement/Finished/text()='false'"]
        foundation_zone_name = Constants.UnfinishedBasementZone
      elsif foundation_type.elements["Crawlspace/Vented/text()='true'"] or foundation_type.elements["Crawlspace/Vented/text()='false'"] or foundation_type.elements["Crawlspace/Conditioned/text()='true'"] or foundation_type.elements["Crawlspace/Conditioned/text()='false'"]
        foundation_zone_name = Constants.CrawlZone
      elsif foundation_type.elements["Garage/Conditioned/text()='true'"] or foundation_type.elements["Garage/Conditioned/text()='false'"]
        foundation_zone_name = Constants.GarageZone
      end

      if not foundation_zone_name.nil?
        
        foundation_zone = OpenStudio::Model::ThermalZone.new(model)
        foundation_zone.setName(foundation_zone_name)
        
        spaces.each do |foundation_id, foundation_space|
          foundation_space.setThermalZone(foundation_zone)
        end
        
      end

    end
  
  end

  def self.add_foundation_floors(model, building, living_space, foundation_spaces)

    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      if not foundation_spaces.keys.include? foundation.elements["FoundationType"]
        foundation_spaces[foundation.elements["FoundationType"]] = {foundation.elements["SystemIdentifier"].attributes["id"]=>build_foundation_spaces(model, foundation.elements["FoundationType"])}
      else
        foundation_spaces[foundation.elements["FoundationType"]][foundation.elements["SystemIdentifier"].attributes["id"]] = build_foundation_spaces(model, foundation.elements["FoundationType"])
      end

      foundation.elements.each("Slab") do |slab|
      
        next if slab.elements["Area"].nil?
        
        slab_width = OpenStudio.convert(Math::sqrt(slab.elements["Area"].text.to_f),"ft","m").get
        slab_length = OpenStudio.convert(slab.elements["Area"].text.to_f,"ft^2","m^2").get / slab_width
        
        z_origin = 0
        unless slab.elements["DepthBelowGrade"].nil?
          z_origin = -OpenStudio.convert(slab.elements["DepthBelowGrade"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(slab_length, slab_width, z_origin), model)
        surface.setName(slab.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Floor") 
        surface.setOutsideBoundaryCondition("Ground")
        if z_origin < 0
          surface.setSpace(foundation_spaces[foundation.elements["FoundationType"]][foundation.elements["SystemIdentifier"].attributes["id"]])
        else
          surface.setSpace(living_space)
        end
        
      end
      
    end
    
    build_foundation_zones(model, foundation_spaces)

  end

  def self.add_foundation_walls(model, building, living_space, foundation_spaces, fenestration_areas)
  
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation.elements.each("FoundationWall") do |wall|
        
        wall_height = OpenStudio.convert(wall.elements["Height"].text.to_f,"ft","m").get
        wall_length = net_wall_area(OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get, fenestration_areas, foundation.elements["SystemIdentifier"].attributes["id"]) / wall_height
        
        z_origin = 0
        unless wall.elements["BelowGradeDepth"].nil?
          z_origin = -OpenStudio.convert(wall.elements["BelowGradeDepth"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin), model)
        surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("Wall") 
        surface.setOutsideBoundaryCondition("Ground")
        surface.setSpace(foundation_spaces[foundation.elements["FoundationType"]][foundation.elements["SystemIdentifier"].attributes["id"]])
        
      end
    
    end

  end

  def self.add_foundation_ceilings(model, building, living_space, foundation_spaces)
       
    foundation_ceiling_area = 0
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
     
      foundation.elements.each("FrameFloor") do |framefloor|
      
        next if framefloor.elements["Area"].nil?

        framefloor_width = OpenStudio.convert(Math::sqrt(framefloor.elements["Area"].text.to_f),"ft","m").get
        framefloor_length = OpenStudio.convert(framefloor.elements["Area"].text.to_f,"ft^2","m^2").get / framefloor_width
        
        z_origin = 0
        
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(framefloor_length, framefloor_width, z_origin), model)
        surface.setName(framefloor.elements["SystemIdentifier"].attributes["id"])
        surface.setSurfaceType("RoofCeiling")
        surface.setSpace(foundation_spaces[foundation.elements["FoundationType"]][foundation.elements["SystemIdentifier"].attributes["id"]])
        surface.createAdjacentSurface(living_space)
        
        foundation_ceiling_area += framefloor.elements["Area"].text.to_f
      
      end
    
    end
    
    return foundation_ceiling_area
      
  end

  def self.add_living_floors(model, building, errors, living_space, foundation_ceiling_area) # TODO: loop thru extension element other_floors instead of the following?

    finished_floor_area = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].text.to_f
    above_grade_finished_floor_area = finished_floor_area - foundation_ceiling_area
    return unless above_grade_finished_floor_area > 0
    
    finishedfloor_width = OpenStudio.convert(Math::sqrt(above_grade_finished_floor_area),"ft","m").get
    finishedfloor_length = OpenStudio.convert(above_grade_finished_floor_area,"ft^2","m^2").get / finishedfloor_width
    
    surface = OpenStudio::Model::Surface.new(add_floor_polygon(-finishedfloor_width, -finishedfloor_length, 0), model)
    surface.setName("inferred finished floor")
    surface.setSurfaceType("Floor")
    surface.setSpace(living_space)
    surface.setOutsideBoundaryCondition("Adiabatic")

  end

  def self.build_attic_space(model, building)

    attic_space = nil
    attic_zone = nil
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if attic.elements["Area"].nil?
    
      if ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
        if attic_space.nil?
          attic_zone = OpenStudio::Model::ThermalZone.new(model)
          attic_zone.setName(Constants.UnfinishedAtticZone)
          attic_space = OpenStudio::Model::Space.new(model)
          attic_space.setName(Constants.UnfinishedAtticSpace)
          attic_space.setThermalZone(attic_zone)
        end
      end
      
    end
    
    return attic_space, attic_zone
      
  end

  def self.add_attic_floors(model, building, errors, avg_ceil_hgt, attic_space, living_space)

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
      next if attic.elements["Area"].nil?
    
      attic_width = OpenStudio.convert(Math::sqrt(attic.elements["Area"].text.to_f),"ft","m").get
      attic_length = OpenStudio.convert(attic.elements["Area"].text.to_f,"ft^2","m^2").get / attic_width
     
      if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
      elsif ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(attic_length, attic_width, 0), model)
        surface.setName(attic.elements["SystemIdentifier"].attributes["id"])        
        surface.setSpace(attic_space)
        surface.setSurfaceType("Floor")
        surface.createAdjacentSurface(living_space)
      else
        errors << "#{attic.elements["AtticType"].text} not handled yet."
      end
      
    end
      
  end

  def self.add_attic_walls(model, building, errors, avg_ceil_hgt, attic_space, living_space, fenestration_areas)

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      next unless wall.elements["InteriorAdjacentTo"].text == "attic"
      next if wall.elements["Area"].nil?
      
      wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
      wall_length = net_wall_area(OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get, fenestration_areas, wall.elements["SystemIdentifier"].attributes["id"]) / wall_height

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_height, wall_length, 0), model)
      surface.setName(wall.elements["SystemIdentifier"].attributes["id"])
      surface.setSurfaceType("Wall")
      surface.setSpace(living_space)
      if wall.elements["ExteriorAdjacentTo"].text == "living space"
        surface.createAdjacentSurface(living_space)
      elsif wall.elements["ExteriorAdjacentTo"].text == "ambient"
        surface.setOutsideBoundaryCondition("Outdoors")
      else
        errors << "#{wall.elements["ExteriorAdjacentTo"].text} not handled yet."
      end
      
    end
      
  end

  def self.add_attic_ceilings(model, building, errors, avg_ceil_hgt, attic_space, living_space)

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      next if ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text
      next if attic.elements["Area"].nil?
    
      attic_width = OpenStudio.convert(Math::sqrt(attic.elements["Area"].text.to_f),"ft","m").get
      attic_length = OpenStudio.convert(attic.elements["Area"].text.to_f,"ft^2","m^2").get / attic_width
     
      if ["cathedral ceiling", "cape cod"].include? attic.elements["AtticType"].text
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(attic_length, attic_width, 0), model)
        surface.setName(attic.elements["SystemIdentifier"].attributes["id"])
        surface.setSpace(living_space)
        surface.setSurfaceType("RoofCeiling")
        surface.setOutsideBoundaryCondition("Outdoors")
      elsif ["venting unknown attic", "vented attic", "unvented attic"].include? attic.elements["AtticType"].text     
      else
        errors << "#{attic.elements["AtticType"].text} not handled yet."
      end
      
    end  

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Roofs/Roof") do |roof|
    
      next if roof.elements["RoofArea"].nil?
    
      roof_width = OpenStudio.convert(Math::sqrt(roof.elements["RoofArea"].text.to_f),"ft","m").get
      roof_length = OpenStudio.convert(roof.elements["RoofArea"].text.to_f,"ft^2","m^2").get / roof_width

      surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(roof_length, roof_width, 0), model)
      surface.setName("#{roof.elements["SystemIdentifier"].attributes["id"]}")
      surface.setSurfaceType("RoofCeiling")
      surface.setOutsideBoundaryCondition("Outdoors")
      surface.setSpace(attic_space)

    end
        
  end
  
  def self.add_windows(model, building, errors, living_space, fenestration_areas)
  
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|

      window_height = OpenStudio.convert(5.0,"ft","m").get
      window_width = OpenStudio.convert(window.elements["Area"].text.to_f,"ft^2","m^2").get / window_height

      if not fenestration_areas.keys.include? window.elements["AttachedToWall"].attributes["idref"]
        fenestration_areas[window.elements["AttachedToWall"].attributes["idref"]] = window.elements["Area"].text.to_f
      else
        fenestration_areas[window.elements["AttachedToWall"].attributes["idref"]] += window.elements["Area"].text.to_f
      end

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(window_width, window_height, 0, window.elements["Azimuth"].text.to_f, [0, 0.001, 0.001 * 2, 0.001]), model) # offsets B, L, T, R
      surface.setName("surface #{window.elements["SystemIdentifier"].attributes["id"]}")
      surface.setSurfaceType("Wall")
      surface.setSpace(living_space)
      surface.setOutsideBoundaryCondition("Outdoors")

      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(window_width, window_height, 0, window.elements["Azimuth"].text.to_f, [-0.001, 0, 0.001, 0]), model) # offsets B, L, T, R
      sub_surface.setName(window.elements["SystemIdentifier"].attributes["id"])
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType("FixedWindow")
      
    end
   
  end
  
  def self.add_doors(model, building, errors, living_space, fenestration_areas)
  
    building.elements.each("BuildingDetails/Enclosure/Doors/Door") do |door|

      door_height = OpenStudio.convert(6.666,"ft","m").get
      door_width = OpenStudio.convert(door.elements["Area"].text.to_f,"ft^2","m^2").get / door_height
    
      if not fenestration_areas.keys.include? door.elements["AttachedToWall"].attributes["idref"]
        fenestration_areas[door.elements["AttachedToWall"].attributes["idref"]] = door.elements["Area"].text.to_f
      else
        fenestration_areas[door.elements["AttachedToWall"].attributes["idref"]] += door.elements["Area"].text.to_f
      end
      
      surface = OpenStudio::Model::Surface.new(add_wall_polygon(door_width, door_height, 0, door.elements["Azimuth"].text.to_f, [0, 0.001, 0.001, 0.001]), model) # offsets B, L, T, R
      surface.setName("surface #{door.elements["SystemIdentifier"].attributes["id"]}")
      surface.setSurfaceType("Wall")
      surface.setSpace(living_space)
      surface.setOutsideBoundaryCondition("Outdoors")

      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(door_width, door_height, 0, door.elements["Azimuth"].text.to_f, [0, 0, 0, 0]), model) # offsets B, L, T, R
      sub_surface.setName(door.elements["SystemIdentifier"].attributes["id"])
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType("Door")
      
    end
   
  end  
    
end

# register the measure to be used by the application
EnergyRatingIndex301.new.registerWithApplication
