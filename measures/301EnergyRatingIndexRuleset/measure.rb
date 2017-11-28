# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'rexml/document'
require 'rexml/xpath'
require 'pathname'
require "#{File.dirname(__FILE__)}/resources/301"
require "#{File.dirname(__FILE__)}/resources/301validator"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/xmlhelper"
require "#{File.dirname(__FILE__)}/resources/meta_measure"
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
    
    arg = OpenStudio::Measure::OSArgument.makeBoolArgument("debug", false)
    arg.setDisplayName("Debug")
    arg.setDescription("Enable debugging.")
    arg.setDefaultValue(false)
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
    measures_dir = runner.getStringArgumentValue("measures_dir", user_arguments)
    schemas_dir = runner.getOptionalStringArgumentValue("schemas_dir", user_arguments)
    hpxml_output_file_path = runner.getOptionalStringArgumentValue("hpxml_output_file_path", user_arguments)
    osm_output_file_path = runner.getOptionalStringArgumentValue("osm_output_file_path", user_arguments)
    debug = runner.getBoolArgumentValue("debug", user_arguments)

    unless (Pathname.new hpxml_file_path).absolute?
      hpxml_file_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_file_path))
    end 
    unless File.exists?(hpxml_file_path) and hpxml_file_path.downcase.end_with? ".xml"
      runner.registerError("'#{hpxml_file_path}' does not exist or is not an .xml file.")
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
    
    show_measure_calls = false
    apply_measures_osw1 = nil
    apply_measures_osw2 = nil
    if debug
      show_measure_calls = true
      apply_measures_osw1 = "apply_measures1.osw"
      apply_measures_osw2 = "apply_measures2.osw"
    end
    
    # Validate input HPXML against schema
    if not schemas_dir.nil?
      has_errors = false
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        runner.registerError("Input HPXML: #{error.to_s}")
        has_errors = true
      end
      if has_errors
        return false
      end
      runner.registerInfo("Validated input HPXML against schema.")
    else
      runner.registerWarning("No schema dir provided, no HPXML validation performed.")
    end
    
    # Validate input HPXML against ERI Use Case
    errors = EnergyRatingIndex301Validator.run_validator(hpxml_doc)
    errors.each do |error|
      runner.registerError(error)
    end
    unless errors.empty?
      return false
    end
    runner.registerInfo("Validated input HPXML against ERI Use Case.")
    
    workflow_json = File.join(File.dirname(__FILE__), "resources", "measure-info.json")
    
    epw_path = XMLHelper.get_value(hpxml_doc, "/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation/extension/EPWFileName")
    unless (Pathname.new epw_path).absolute?
      epw_path = File.expand_path(File.join(File.dirname(hpxml_file_path), epw_path))
    end
    unless File.exists?(epw_path) and epw_path.downcase.end_with? ".epw"
      runner.registerError("'#{epw_path}' does not exist or is not an .epw file.")
      return false
    end
    
    # Apply Location measure to obtain weather data
    measures = {}
    measure_subdir = "ResidentialLocation"
    args = {
            "weather_directory"=>File.dirname(epw_path),
            "weather_file_name"=>File.basename(epw_path),
            "dst_start_date"=>"NA",
            "dst_end_date"=>"NA"
           }
    update_args_hash(measures, measure_subdir, args)

    if not apply_measures(measures_dir, measures, runner, model, workflow_json, apply_measures_osw1, show_measure_calls)
      return false
    end
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    
    # Apply 301 ruleset on HPXML object
    EnergyRatingIndex301Ruleset.apply_ruleset(hpxml_doc, calc_type, weather)
    if hpxml_output_file_path.is_initialized
      XMLHelper.write_file(hpxml_doc, hpxml_output_file_path.get)
      runner.registerInfo("Wrote file: #{hpxml_output_file_path.get}")
    end
    unless errors.empty?
      return false
    end
    
    # Validate output HPXML against schema
    if not schemas_dir.nil?
      has_errors = false
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        runner.registerError("Output HPXML: #{error.to_s}")
        has_errors = true
      end
      if has_errors
        return false
      end
      runner.registerInfo("Validated output HPXML.")
    else
      runner.registerWarning("No schema dir provided, no HPXML validation performed.")
    end
    
    # Obtain list of OpenStudio measures (and arguments)
    measures = OSMeasures.build_measures_from_hpxml(hpxml_doc)
    
    # Create OpenStudio model
    if not OSModel.create_geometry(hpxml_doc, runner, model)
      return false
    end 

    if osm_output_file_path.is_initialized
      File.write(osm_output_file_path.get, model.to_s)
      runner.registerInfo("Wrote file: #{osm_output_file_path.get}")
    end
    
    if not apply_measures(measures_dir, measures, runner, model, workflow_json, apply_measures_osw2, show_measure_calls)
      return false
    end
    
    if osm_output_file_path.is_initialized
      File.write(osm_output_file_path.get, model.to_s)
      runner.registerInfo("Wrote file: #{osm_output_file_path.get}")
    end
    
    # Add output variables for RESNET building loads
    if not generate_building_loads(model, runner)
      return false
    end
    
    return true

  end
  
  def generate_building_loads(model, runner)
    # Note: Duct losses are included the heating/cooling energy values. For the 
    # RESNET Reference Home, the effect of DSE is removed during post-processing.
    
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

  def self.build_measures_from_hpxml(hpxml_doc)

    measures = {}
    building = hpxml_doc.elements["/HPXML/Building"]
    
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

    # Water Heating & Appliances
    get_water_heating(building, measures)
    # TODO: ResidentialHotWaterSolar
    get_hot_water_and_appliances(building, measures)
    
    # HVAC
    get_heating_system(building, measures)
    get_cooling_system(building, measures)
    get_heat_pump(building, measures)
    get_setpoints(building, measures)
    get_ceiling_fan(building, measures)
    get_dehumidifier(building, measures)
    
    # Plug Loads and Lighting
    # get_lighting(building, measures)
    get_mels(building, measures)
    
    # Other
    get_airflow(building, measures)
    get_hvac_sizing(building, measures)
    get_photovoltaics(building, measures)

    return measures

  end
  
  private
  
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
      next if overhangs.nil?
      name = window.elements["SystemIdentifier"].attributes["id"]
      depth = Float(XMLHelper.get_value(overhangs, "Depth"))
      offset = Float(XMLHelper.get_value(overhangs, "DistanceToTopOfWindow"))
      
      measure_subdir = "ResidentialGeometryOverhangs"
      args = {
              "sub_surface"=>name,
              "depth"=>OpenStudio.convert(depth,"in","ft").get,
              "offset"=>OpenStudio.convert(offset,"in","ft").get,
              "front_facade"=>true,
              "back_facade"=>true,
              "left_facade"=>true,
              "right_facade"=>true
             }
      update_args_hash(measures, measure_subdir, args)      
      
    end

  end
      
  def self.get_beds_and_baths(building, measures)

    measure_subdir = "ResidentialGeometryNumBedsAndBaths"  
    num_bedrooms = Integer(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    num_bathrooms = Float(XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms"))
    args = {
            "num_bedrooms"=>num_bedrooms,
            "num_bathrooms"=>num_bathrooms
           }  
    update_args_hash(measures, measure_subdir, args)
    
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
    update_args_hash(measures, measure_subdir, args)
    
  end
      
  def self.get_windows(building, measures)

    # FIXME
  
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
  
      name = window.elements["SystemIdentifier"].attributes["id"]
      ufactor = XMLHelper.get_value(window, "UFactor")
      shgc = XMLHelper.get_value(window, "SHGC")
      cooling_shade_mult = XMLHelper.get_value(window, "extension/InteriorShadingFactorSummer")
      heating_shade_mult = XMLHelper.get_value(window, "extension/InteriorShadingFactorWinter")
  
      measure_subdir = "ResidentialConstructionsWindows"
      args = {
              "sub_surface"=>name,
              "ufactor"=>ufactor,
              "shgc"=>shgc,
              "heating_shade_mult"=>heating_shade_mult,
              "cooling_shade_mult"=>cooling_shade_mult
             }  
      update_args_hash(measures, measure_subdir, args)
      
    end

  end
  
  def self.get_doors(building, measures)
  
    # FIXME

    building.elements.each("BuildingDetails/Enclosure/Doors/Door") do |door|
    
      name = door.elements["SystemIdentifier"].attributes["id"]
      area = Float(XMLHelper.get_value(door, "Area"))
      ua = area/Float(XMLHelper.get_value(door, "RValue"))
      
      if area > 0
        measure_subdir = "ResidentialConstructionsDoors"
        args = {
                "sub_surface"=>name,
                "door_ufactor"=>ua/area
               }  
        update_args_hash(measures, measure_subdir, args)
      end

    end
    
  end

  def self.get_ceiling_roof_constructions(building, measures)
  
    # FIXME

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|

      attic_type = XMLHelper.get_value(attic, "AtticType")

      floors = attic.elements["Floors"]
      floors.elements.each("Floor") do |floor|
      
        name = floor.elements["SystemIdentifier"].attributes["id"]
        framing_factor = Float(XMLHelper.get_value(floor, "FloorJoists/FramingFactor"))
        install_grade = Integer(XMLHelper.get_value(floor, "Insulation/InsulationGrade"))
        
        exterior_adjacent_to = floor.elements["extension/ExteriorAdjacentTo"].text

        if ["vented attic", "unvented attic"].include? attic_type
        
          if exterior_adjacent_to == "living space"
        
            measure_subdir = "ResidentialConstructionsCeilingsRoofsUnfinishedAttic"
            args = {
                    "surface"=>name,
                    "ceil_r"=>30,
                    "ceil_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                    "ceil_ins_thick_in"=>8.55,
                    "ceil_ff"=>framing_factor,
                    "ceil_joist_height"=>3.5,
                    "roof_cavity_r"=>0,
                    "roof_cavity_grade"=>"I",
                    "roof_cavity_ins_thick_in"=>0,
                    "roof_ff"=>0.07,
                    "roof_fram_thick_in"=>7.25
                   }  
            update_args_hash(measures, measure_subdir, args)
            
            measure_subdir = "ResidentialConstructionsCeilingsRoofsThermalMass"
            args = {
                    "surface"=>"#{name} Reversed", # FIXME: I can't rename the adjacent roofceiling to the id in the hpxml because then the unfinished attic measure gets the wrong surface name. Can we modify this measure to input the floor instead of the roofceiling?
                    "thick_in1"=>0.5,
                    "thick_in2"=>nil,
                    "cond1"=>1.1112,
                    "cond2"=>nil,
                    "dens1"=>50.0,
                    "dens2"=>nil,
                    "specheat1"=>0.2,
                    "specheat2"=>nil
                   }
            update_args_hash(measures, measure_subdir, args)          
            
          elsif exterior_adjacent_to == "garage"
          
            measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
            args = {
                    "surface"=>name
                    }
            update_args_hash(measures, measure_subdir, args)        
          
          elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          
            fail "Unhandled value (#{exterior_adjacent_to})."
          
          end
         
        elsif ["cape cod"].include? attic_type

          if exterior_adjacent_to == "living space"
          
            measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
            args = {
                    "surface"=>name
                    }
            update_args_hash(measures, measure_subdir, args)
          
          elsif exterior_adjacent_to == "garage"
          
            measure_subdir = "ResidentialConstructionsFoundationsFloorsInterzonalFloors"
            args = {
                    "surface"=>name,
                    "cavity_r"=>19,
                    "install_grade"=>"I",
                    "framing_factor"=>0.13
                   }
            update_args_hash(measures, measure_subdir, args)  

          elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          
            fail "Unhandled value (#{exterior_adjacent_to})."
          
          end
          
        end
        
      end
      
    end

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      attic_type = attic.elements["AtticType"].text
      
      roofs = attic.elements["Roofs"]
      roofs.elements.each("Roof") do |roof|
      
        name = roof.elements["SystemIdentifier"].attributes["id"]
        has_rb = Boolean(XMLHelper.get_value(roof, "RadiantBarrier"))        
        solar_abs = Float(XMLHelper.get_value(roof, "SolarAbsorptance"))
        emittance = Float(XMLHelper.get_value(roof, "Emittance"))
        framing_factor = Float(XMLHelper.get_value(roof, "Rafters/FramingFactor"))
        install_grade = Integer(XMLHelper.get_value(roof, "Insulation/InsulationGrade"))

        measure_subdir = "ResidentialConstructionsCeilingsRoofsRoofingMaterial"
        args = {
                "surface"=>name,
                "solar_abs"=>solar_abs,
                "emissivity"=>emittance,
                "material"=>Constants.RoofMaterialAsphaltShingles,
                "color"=>Constants.ColorMedium # FIXME
               }  
        update_args_hash(measures, measure_subdir, args)
        
        measure_subdir = "ResidentialConstructionsCeilingsRoofsSheathing"
        args = {
                "surface"=>name,
                "osb_thick_in"=>0.75,
                "rigid_r"=>0.0,
                "rigid_thick_in"=>0.0,
               }
        update_args_hash(measures, measure_subdir, args)
        
        if ["vented attic", "unvented attic"].include? attic_type
        
          measure_subdir = "ResidentialConstructionsCeilingsRoofsUnfinishedAttic"
          args = {
                  "surface"=>name,
                  "ceil_r"=>30,
                  "ceil_grade"=>"I",
                  "ceil_ins_thick_in"=>8.55,
                  "ceil_ff"=>0.07,
                  "ceil_joist_height"=>3.5,
                  "roof_cavity_r"=>0,
                  "roof_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                  "roof_cavity_ins_thick_in"=>0,
                  "roof_ff"=>framing_factor,
                  "roof_fram_thick_in"=>7.25
                 }  
          update_args_hash(measures, measure_subdir, args)        
        
          measure_subdir = "ResidentialConstructionsCeilingsRoofsRadiantBarrier"
          args = {
                  "surface"=>name,
                  "has_rb"=>has_rb
                 }
          update_args_hash(measures, measure_subdir, args)
          
        else
        
          measure_subdir = "ResidentialConstructionsCeilingsRoofsFinishedRoof"
          args = {
                  "surface"=>name,
                  "cavity_r"=>30,
                  "install_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                  "cavity_depth"=>9.25,
                  "ins_fills_cavity"=>false,
                  "framing_factor"=>framing_factor
                 }  
          update_args_hash(measures, measure_subdir, args)      
        
        end
        
      end
      
    end
    
  end
  
  def self.get_foundation_wall_properties(foundation, measures)
  
    foundation.elements.each("FoundationWall") do |fnd_wall|
    
      name = fnd_wall.elements["SystemIdentifier"].attributes["id"]
  
      if XMLHelper.has_element(fnd_wall, "Insulation/AssemblyEffectiveRValue")
      
        wall_R = Float(XMLHelper.get_value(fnd_wall, "Insulation/AssemblyEffectiveRValue"))
        
        wall_cav_r = 0.0
        wall_cav_depth = 0.0
        wall_grade = 1
        wall_ff = 0.0        
        wall_cont_height = Float(XMLHelper.get_value(fnd_wall, "Height"))
        wall_cont_r = wall_R - Material.Concrete8in.rvalue - Material.DefaultWallSheathing.rvalue - Material.AirFilmVertical.rvalue
        wall_cont_depth = 1.0
      
      else
    
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
      
      if XMLHelper.has_element(foundation, "FoundationType/Basement")
        if Boolean(XMLHelper.get_value(foundation, "FoundationType/Basement/Conditioned"))
          measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementFinished"
          args = {
                  "surface"=>name,
                  "wall_ins_height"=>wall_cont_height,
                  "wall_cavity_r"=>wall_cav_r,
                  "wall_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[wall_grade],
                  "wall_cavity_depth"=>wall_cav_depth,
                  "wall_cavity_insfills"=>true, # FIXME
                  "wall_ff"=>wall_ff,
                  "wall_rigid_r"=>wall_cont_r,
                  "wall_rigid_thick_in"=>wall_cont_depth,
                  "ceil_ff"=>0.13,
                  "ceil_joist_height"=>9.25,
                  "exposed_perim"=>get_exposed_perimeter(foundation)
                 }  
          update_args_hash(measures, measure_subdir, args)        
        else
          measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementUnfinished"
          args = {
                  "surface"=>name,
                  "wall_ins_height"=>wall_cont_height,
                  "wall_cavity_r"=>wall_cav_r,
                  "wall_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[wall_grade],
                  "wall_cavity_depth"=>wall_cav_depth,
                  "wall_cavity_insfills"=>true, # FIXME
                  "wall_ff"=>wall_ff,
                  "wall_rigid_r"=>wall_cont_r,
                  "wall_rigid_thick_in"=>wall_cont_depth,
                  "ceil_cavity_r"=>0,
                  "ceil_cavity_grade"=>"I",
                  "ceil_ff"=>0.13,
                  "ceil_joist_height"=>9.25,
                  "exposed_perim"=>get_exposed_perimeter(foundation)
                 }
          update_args_hash(measures, measure_subdir, args)      
        end   
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace")
        measure_subdir = "ResidentialConstructionsFoundationsFloorsCrawlspace"
        args = {
                "surface"=>name,
                "wall_rigid_r"=>wall_cont_r,
                "wall_rigid_thick_in"=>wall_cont_depth,
                "ceil_cavity_r"=>0,
                "ceil_cavity_grade"=>"I",
                "ceil_ff"=>0.13,
                "ceil_joist_height"=>9.25,
                "exposed_perim"=>get_exposed_perimeter(foundation)
               }
        update_args_hash(measures, measure_subdir, args)      
      elsif XMLHelper.has_element(foundation, "FoundationType/SlabOnGrade")      
      elsif XMLHelper.has_element(foundation, "FoundationType/Ambient")
      end       
       
    end
    
  end
  
  def self.get_foundation_frame_floor_properties(foundation, measures)
          
    foundation.elements.each("FrameFloor") do |fnd_floor|
    
      name = fnd_floor.elements["SystemIdentifier"].attributes["id"]

      if XMLHelper.has_element(fnd_floor, "Insulation/AssemblyEffectiveRValue")
      
        # FIXME
        floor_cav_r = 0.0
        floor_cav_depth = 5.5
        floor_grade = 1
        floor_ff = 0.0
        floor_cont_r = 0.0
        floor_cont_depth = 0.0
      
      else
    
        fnd_floor_cavity = fnd_floor.elements["Insulation/Layer[InstallationType='cavity']"]
        floor_cav_r = Float(XMLHelper.get_value(fnd_floor_cavity, "NominalRValue"))
        floor_cav_depth = Float(XMLHelper.get_value(fnd_floor_cavity, "Thickness"))
        floor_grade = Integer(XMLHelper.get_value(fnd_floor, "Insulation/InsulationGrade"))
        floor_ff = Float(XMLHelper.get_value(fnd_floor, "FloorJoists/FramingFactor"))
        fnd_floor_cont = fnd_floor.elements["Insulation/Layer[InstallationType='continuous']"]
        floor_cont_r = Float(XMLHelper.get_value(fnd_floor_cont, "NominalRValue"))
        floor_cont_depth = Float(XMLHelper.get_value(fnd_floor_cont, "Thickness"))
      
      end
      
      if XMLHelper.has_element(foundation, "FoundationType/Basement")
        if Boolean(XMLHelper.get_value(foundation, "FoundationType/Basement/Conditioned"))
        else
          measure_subdir = "ResidentialConstructionsFoundationsFloorsBasementUnfinished"
          args = {
                  "surface"=>name,
                  "wall_ins_height"=>8,
                  "wall_cavity_r"=>0,
                  "wall_cavity_grade"=>"I",
                  "wall_cavity_depth"=>0,
                  "wall_cavity_insfills"=>false,
                  "wall_ff"=>0,
                  "wall_rigid_r"=>10,
                  "wall_rigid_thick_in"=>2,
                  "ceil_cavity_r"=>floor_cav_r,
                  "ceil_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[floor_grade],
                  "ceil_ff"=>floor_ff,
                  "ceil_joist_height"=>floor_cav_depth,
                  "exposed_perim"=>get_exposed_perimeter(foundation)
                 }
          update_args_hash(measures, measure_subdir, args)      
        end
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
        args = {
                "surface"=>"#{name} Reversed", # FIXME: same issue as with ceilings thermal mass. also, this doesn't assign constructions to "inferred" floors.
                "osb_thick_in"=>0.75,
                "rigid_r"=>floor_cont_r,
                "rigid_thick_in"=>floor_cont_depth
               }
        update_args_hash(measures, measure_subdir, args)
        measure_subdir = "ResidentialConstructionsFoundationsFloorsThermalMass"
        args = {
                "surface"=>"#{name} Reversed", # FIXME: same issue as with ceilings thermal mass. also, this doesn't assign constructions to "inferred" floors.
                "thick_in"=>0.625,
                "cond"=>0.8004,
                "dens"=>34.0,
                "specheat"=>0.29
               }
        update_args_hash(measures, measure_subdir, args)
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace")
        measure_subdir = "ResidentialConstructionsFoundationsFloorsCrawlspace"
        args = {
                "surface"=>name,
                "wall_rigid_r"=>10,
                "wall_rigid_thick_in"=>2,
                "ceil_cavity_r"=>floor_cav_r,
                "ceil_cavity_grade"=>{1=>"I",2=>"II",3=>"III"}[floor_grade],
                "ceil_ff"=>floor_ff,
                "ceil_joist_height"=>floor_cav_depth,
                "exposed_perim"=>get_exposed_perimeter(foundation)
               }
        update_args_hash(measures, measure_subdir, args)
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
        args = {
                "surface"=>"#{name} Reversed", # FIXME: same issue as with ceilings thermal mass. also, this doesn't assign constructions to "inferred" floors.
                "osb_thick_in"=>0.75,
                "rigid_r"=>floor_cont_r,
                "rigid_thick_in"=>floor_cont_depth
               }
        update_args_hash(measures, measure_subdir, args)
        measure_subdir = "ResidentialConstructionsFoundationsFloorsThermalMass"
        args = {
                "surface"=>"#{name} Reversed", # FIXME: same issue as with ceilings thermal mass. also, this doesn't assign constructions to "inferred" floors.
                "thick_in"=>0.625,
                "cond"=>0.8004,
                "dens"=>34.0,
                "specheat"=>0.29
               }
        update_args_hash(measures, measure_subdir, args)
      elsif XMLHelper.has_element(foundation, "FoundationType/SlabOnGrade")
      elsif XMLHelper.has_element(foundation, "FoundationType/Ambient")
        measure_subdir = "ResidentialConstructionsFoundationsFloorsPierBeam"
        args = {
                "surface"=>name,
                "cavity_r"=>floor_cav_r,
                "install_grade"=>{1=>"I",2=>"II",3=>"III"}[floor_grade],
                "framing_factor"=>floor_ff
               }
        update_args_hash(measures, measure_subdir, args)        
        measure_subdir = "ResidentialConstructionsFoundationsFloorsSheathing"
        args = {
                "surface"=>"#{name} Reversed", # FIXME: same issue as with ceilings thermal mass. also, this doesn't assign constructions to "inferred" floors.
                "osb_thick_in"=>0.75,
                "rigid_r"=>floor_cont_r,
                "rigid_thick_in"=>floor_cont_depth
               }
        update_args_hash(measures, measure_subdir, args)
        measure_subdir = "ResidentialConstructionsFoundationsFloorsThermalMass"
        args = {
                "surface"=>"#{name} Reversed", # FIXME: same issue as with ceilings thermal mass. also, this doesn't assign constructions to "inferred" floors.
                "thick_in"=>0.625,
                "cond"=>0.8004,
                "dens"=>34.0,
                "specheat"=>0.29
               }
        update_args_hash(measures, measure_subdir, args)
      end
      
    end
      
  end

  def self.get_foundation_slab_properties(foundation, measures)
          
    foundation.elements.each("Slab") do |fnd_slab|
    
      name = fnd_slab.elements["SystemIdentifier"].attributes["id"]
      
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
      
      if XMLHelper.has_element(foundation, "FoundationType/Basement")
        # Uninsulated floor assumed in model
      elsif XMLHelper.has_element(foundation, "FoundationType/Crawlspace")
        # Uninsulated floor assumed in model
      elsif XMLHelper.has_element(foundation, "FoundationType/SlabOnGrade")

        measure_subdir = "ResidentialConstructionsFoundationsFloorsSlab"
        args = {
                "surface"=>name,
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
                "exposed_perim"=>get_exposed_perimeter(foundation)
               }  
        update_args_hash(measures, measure_subdir, args)
        
        carpet_frac = Float(XMLHelper.get_value(fnd_slab, "extension/CarpetFraction"))
        carpet_r = Float(XMLHelper.get_value(fnd_slab, "extension/CarpetRValue"))
        
        measure_subdir = "ResidentialConstructionsFoundationsFloorsCovering"
        args = {
                "surface"=>name,
                "covering_frac"=>carpet_frac,
                "covering_r"=>carpet_r
               }
        update_args_hash(measures, measure_subdir, args)

      elsif XMLHelper.has_element(foundation, "FoundationType/Ambient")
      end    
      
    end
    
  end

  def self.get_exposed_perimeter(foundation)
    exposed_perim = 0
    foundation.elements.each("Slab") do |slab|        
      unless slab.elements["ExposedPerimeter"].nil?
        exposed_perim += Float(slab.elements["ExposedPerimeter"].text)
      end
    end
    return exposed_perim
  end
  
  def self.get_foundation_constructions(building, measures)
  
    # FIXME
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      get_foundation_wall_properties(foundation, measures)
      get_foundation_frame_floor_properties(foundation, measures)
      get_foundation_slab_properties(foundation, measures)
    end

  end
  
  def self.get_siding_material(siding, solar_abs, emitt)
    
    if siding == "stucco"    
      k_in = 4.5
      rho = 80.0
      cp = 0.21
      thick_in = 1.0
    elsif siding == "brick veneer"
      k_in = 5.5
      rho = 110.0
      cp = 0.19
      thick_in = 4.0
    elsif siding == "wood siding"
      k_in = 0.71
      rho = 34.0
      cp = 0.28
      thick_in = 1.0
    elsif siding == "aluminum siding"
      k_in = 0.61
      rho = 10.9
      cp = 0.29
      thick_in = 0.375
    elsif siding == "vinyl siding"
      k_in = 0.62
      rho = 11.1
      cp = 0.25
      thick_in = 0.375
    elsif siding == "fiber cement siding"
      k_in = 1.79
      rho = 21.7
      cp = 0.24
      thick_in = 0.375
    else
      fail "Unexpected siding type: #{siding}."
    end
    
    return Material.new(name="Siding", thick_in=thick_in, mat_base=nil, k_in=k_in, rho=rho, cp=cp, tAbs=emitt, sAbs=solar_abs, vAbs=solar_abs)
    
  end

  def self.get_wall_constructions(building, measures)
  
    mat_mass = Material.DefaultWallMass
    mat_sheath = Material.DefaultWallSheathing
  
    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      name = wall.elements["SystemIdentifier"].attributes["id"]
      interior_adjacent_to = XMLHelper.get_value(wall, "extension/InteriorAdjacentTo")
      exterior_adjacent_to = XMLHelper.get_value(wall, "extension/ExteriorAdjacentTo")
      material = XMLHelper.get_value(wall, "Siding")
      solar_abs = XMLHelper.get_value(wall, "SolarAbsorptance")
      emitt = XMLHelper.get_value(wall, "Emittance")
      mat_siding = get_siding_material(material, solar_abs, emitt)
        
      # TODO: Handle other wall types
      if XMLHelper.has_element(wall, "WallType/WoodStud")
      
        if XMLHelper.has_element(wall, "Insulation/AssemblyEffectiveRValue")
        
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

          if exterior_adjacent_to == "ambient" and ["living space", "cape cod"].include? interior_adjacent_to

            measure_subdir = "ResidentialConstructionsWallsExteriorGeneric"
            args = {
                    "surface"=>name,
                    "thick_in_1"=>layer_t,
                    "conductivity_1"=>layer_k,
                    "density_1"=>rho,
                    "specific_heat_1"=>cp
                   }
            update_args_hash(measures, measure_subdir, args)
            
            measure_subdir = "ResidentialConstructionsWallsSheathing"
            args = {
                    "surface"=>name,
                    "osb_thick_in"=>mat_sheath.thick_in,
                    "rigid_r"=>0.0,
                    "rigid_thick_in"=>0.0
                   }
            update_args_hash(measures, measure_subdir, args)

          elsif exterior_adjacent_to != "ambient" and ["living space"].include? interior_adjacent_to
          
            measure_subdir = "ResidentialConstructionsWallsInterzonal"
            args = {
                    "surface"=>name,
                    "cavity_r"=>layer_R,
                    "install_grade"=>"I",
                    "cavity_depth"=>layer_t,
                    "ins_fills_cavity"=>true,
                    "framing_factor"=>framing_factor
                   }
            update_args_hash(measures, measure_subdir, args)
            
          else
          
              fail "Unhandled values (#{exterior_adjacent_to} and #{interior_adjacent_to})."
          
          end

        else
      
          cavity_layer = wall.elements["Insulation/Layer[InstallationType='cavity']"]
          cavity_r = Float(XMLHelper.get_value(cavity_layer, "NominalRValue"))
          cavity_depth = Float(XMLHelper.get_value(cavity_layer, "Thickness"))
          install_grade = Integer(XMLHelper.get_value(wall, "Insulation/InsulationGrade"))
          framing_factor = Float(XMLHelper.get_value(wall, "Studs/FramingFactor"))
          ins_fills_cavity = true # FIXME
          cont_layer = wall.elements["Insulation/Layer[InstallationType='continuous']"]
          cont_r = Float(XMLHelper.get_value(cont_layer, "NominalRValue"))
          cont_depth = Float(XMLHelper.get_value(cont_layer, "Thickness"))

          if exterior_adjacent_to == "ambient" and ["living space", "cape cod"].include? interior_adjacent_to

            measure_subdir = "ResidentialConstructionsWallsExteriorWoodStud"
            args = {
                    "surface"=>name,
                    "cavity_r"=>cavity_r,
                    "install_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                    "cavity_depth"=>cavity_depth,
                    "ins_fills_cavity"=>ins_fills_cavity,
                    "framing_factor"=>framing_factor
                   }
            update_args_hash(measures, measure_subdir, args)

            measure_subdir = "ResidentialConstructionsWallsSheathing"
            args = {
                    "surface"=>name,
                    "osb_thick_in"=>mat_sheath.thick_in,
                    "rigid_r"=>cont_r,
                    "rigid_thick_in"=>cont_depth
                   }
            update_args_hash(measures, measure_subdir, args)
            
          elsif exterior_adjacent_to != "ambient" and ["living space"].include? interior_adjacent_to
          
            measure_subdir = "ResidentialConstructionsWallsInterzonal"
            args = {
                    "surface"=>name,
                    "cavity_r"=>cavity_r,
                    "install_grade"=>{1=>"I",2=>"II",3=>"III"}[install_grade],
                    "cavity_depth"=>cavity_depth,
                    "ins_fills_cavity"=>ins_fills_cavity,
                    "framing_factor"=>framing_factor
                   }
            update_args_hash(measures, measure_subdir, args)          
          
          end
          
        end

        if exterior_adjacent_to == "ambient"

          measure_subdir = "ResidentialConstructionsWallsExteriorFinish"
          args = {
                  "surface"=>name,
                  "solar_abs"=>mat_siding.sAbs,
                  "conductivity"=>mat_siding.k_in,
                  "density"=>mat_siding.rho,
                  "specific_heat"=>mat_siding.cp,
                  "thick_in"=>mat_siding.thick_in,
                  "emissivity"=>mat_siding.tAbs
                 }          
          update_args_hash(measures, measure_subdir, args)

          if ["living space", "cape cod"].include? interior_adjacent_to
          
            measure_subdir = "ResidentialConstructionsWallsExteriorThermalMass"
            args = {
                    "surface"=>name,
                    "thick_in1"=>mat_mass.thick_in,
                    "thick_in2"=>nil,
                    "cond1"=>mat_mass.k_in,
                    "cond2"=>nil,
                    "dens1"=>mat_mass.rho,
                    "dens2"=>nil,
                    "specheat1"=>mat_mass.cp,
                    "specheat2"=>nil
                   }
            update_args_hash(measures, measure_subdir, args)
          
          end
          
        end
      
      else
      
        fail "Unexpected wall type."
        
      end
      
    end

    measure_subdir = "ResidentialConstructionsWallsPartitionThermalMass"
    args = {
            "frac"=>1.0,
            "thick_in1"=>mat_mass.thick_in,
            "thick_in2"=>nil,
            "cond1"=>mat_mass.k_in,
            "cond2"=>nil,
            "dens1"=>mat_mass.rho,
            "dens2"=>nil,
            "specheat1"=>mat_mass.cp,
            "specheat2"=>nil
           }
    update_args_hash(measures, measure_subdir, args)

  end

  def self.get_other_constructions(building, measures)
  
    # FIXME

    # measure_subdir = "ResidentialConstructionsUninsulatedSurfaces"
    # args = {
            # # "surface"=>name # FIXME: how to apply this to, e.g., adiabatic floors between stories?
            # }
    # update_args_hash(measures, measure_subdir, args)

    measure_subdir = "ResidentialConstructionsFurnitureThermalMass"
    args = {
            "area_fraction"=>0.4,
            "mass"=>8.0,
            "solar_abs"=>0.6,
            "conductivity"=>BaseMaterial.Wood.k_in,
            "density"=>40.0,
            "specific_heat"=>BaseMaterial.Wood.cp,
           }
    update_args_hash(measures, measure_subdir, args)
    
  end

  def self.get_water_heating(building, measures)

    dhw = building.elements["BuildingDetails/Systems/WaterHeating/WaterHeatingSystem"]
    
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
        update_args_hash(measures, measure_subdir, args)
        
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
        update_args_hash(measures, measure_subdir, args)
        
      else
      
        fail "Unhandled water heater (#{wh_type}, #{fuel})."
        
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
        update_args_hash(measures, measure_subdir, args)
        
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
        update_args_hash(measures, measure_subdir, args)
        
      else
      
        fail "Unhandled water heater (#{wh_type}, #{fuel})."
        
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
      update_args_hash(measures, measure_subdir, args)
      
    else
    
      fail "Unhandled water heater (#{wh_type})."
      
    end

  end
  
  def self.get_hot_water_and_appliances(building, measures)
  
    wh = building.elements["BuildingDetails/Systems/WaterHeating"]
    appl = building.elements["BuildingDetails/Appliances"]
    
    # Clothes Washer
    cw = appl.elements["ClothesWasher"]
    cw_annual_kwh = Float(XMLHelper.get_value(cw, "extension/AnnualkWh"))
    cw_frac_sens = Float(XMLHelper.get_value(cw, "extension/FracSensible"))
    cw_frac_lat = Float(XMLHelper.get_value(cw, "extension/FracLatent"))
    cw_gpd = Float(XMLHelper.get_value(cw, "extension/HotWaterGPD"))
    
    # Clothes Dryer
    cd = appl.elements["ClothesDryer"]
    cd_annual_kwh = Float(XMLHelper.get_value(cd, "extension/AnnualkWh"))
    cd_annual_therm = Float(XMLHelper.get_value(cd, "extension/AnnualTherm"))
    cd_frac_sens = Float(XMLHelper.get_value(cd, "extension/FracSensible"))
    cd_frac_lat = Float(XMLHelper.get_value(cd, "extension/FracLatent"))
    cd_fuel_type = XMLHelper.get_value(cd, "FuelType")
    
    # Dishwasher
    dw = appl.elements["Dishwasher"]
    dw_annual_kwh = Float(XMLHelper.get_value(dw, "extension/AnnualkWh"))
    dw_frac_sens = Float(XMLHelper.get_value(dw, "extension/FracSensible"))
    dw_frac_lat = Float(XMLHelper.get_value(dw, "extension/FracLatent"))
    dw_gpd = Float(XMLHelper.get_value(dw, "extension/HotWaterGPD"))
  
    # Refrigerator
    fridge = appl.elements["Refrigerator"]
    fridge_annual_kwh = Float(XMLHelper.get_value(fridge, "RatedAnnualkWh"))
    
    # Cooking Range
    cook = appl.elements["CookingRange"]
    cook_annual_kwh = Float(XMLHelper.get_value(cook, "extension/AnnualkWh"))
    cook_annual_therm = Float(XMLHelper.get_value(cook, "extension/AnnualTherm"))
    cook_frac_sens = Float(XMLHelper.get_value(cook, "extension/FracSensible"))
    cook_frac_lat = Float(XMLHelper.get_value(cook, "extension/FracLatent"))
    cook_fuel_type = XMLHelper.get_value(cook, "FuelType")
    
    # Fixtures
    fx = wh.elements["WaterFixture[WaterFixtureType='shower head']"]
    fx_gpd = Float(XMLHelper.get_value(fx, "extension/MixedWaterGPD"))
    
    # Distribution
    dist = wh.elements["HotWaterDistribution"]
    if XMLHelper.has_element(dist, "SystemType/Standard")
      dist_type = "standard"
      dist_pump_annual_kwh = 0.0
    elsif XMLHelper.has_element(dist, "SystemType/Recirculation")
      dist_type = "recirculation"
      dist_pump_annual_kwh = Float(XMLHelper.get_value(dist, "extension/RecircPumpAnnualkWh"))
    end
    dist_gpd = Float(XMLHelper.get_value(dist, "extension/MixedWaterGPD"))
    
    # Drain Water Heat Recovery
    dwhr_avail = false
    dwhr_eff = 0.0
    dwhr_eff_adj = 0.0
    dwhr_iFrac = 0.0
    dwhr_plc = 0.0
    dwhr_locF = 0.0
    dwhr_fixF = 0.0
    if XMLHelper.has_element(dist, "DrainWaterHeatRecovery")
      dwhr_avail = true
      dwhr_eff = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/Efficiency"))
      dwhr_eff_adj = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/EfficiencyAdjustment"))
      dwhr_iFrac = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/FracImpactedHotWater"))
      dwhr_plc = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/PipingLossCoefficient"))
      dwhr_locF = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/LocationFactor"))
      dwhr_fixF = Float(XMLHelper.get_value(dist, "DrainWaterHeatRecovery/extension/FixtureFactor"))
    end
    
    # FIXME: Need to ensure this measure executes at the right time
    measure_subdir = "ERIHotWaterAndAppliances"
    args = {
            "cw_annual_kwh"=>cw_annual_kwh,
            "cw_frac_sens"=>cw_frac_sens,
            "cw_frac_lat"=>cw_frac_lat,
            "cw_gpd"=>cw_gpd,
            "cd_annual_kwh"=>cd_annual_kwh,
            "cd_annual_therm"=>cd_annual_therm,
            "cd_frac_sens"=>cd_frac_sens,
            "cd_frac_lat"=>cd_frac_lat,
            "cd_fuel_type"=>to_beopt_fuel(cd_fuel_type),
            "dw_annual_kwh"=>dw_annual_kwh,
            "dw_frac_sens"=>dw_frac_sens,
            "dw_frac_lat"=>dw_frac_lat,
            "dw_gpd"=>dw_gpd,
            "fridge_annual_kwh"=>fridge_annual_kwh,
            "cook_annual_kwh"=>cook_annual_kwh,
            "cook_annual_therm"=>cook_annual_therm,
            "cook_frac_sens"=>cook_frac_sens,
            "cook_frac_lat"=>cook_frac_lat,
            "cook_fuel_type"=>to_beopt_fuel(cook_fuel_type),
            "fx_gpd"=>fx_gpd,
            "dist_type"=>dist_type,
            "dist_gpd"=>dist_gpd,
            "dist_pump_annual_kwh"=>dist_pump_annual_kwh,
            "dwhr_avail"=>dwhr_avail,
            "dwhr_eff"=>dwhr_eff,
            "dwhr_eff_adj"=>dwhr_eff_adj,
            "dwhr_iFrac"=>dwhr_iFrac,
            "dwhr_plc"=>dwhr_plc,
            "dwhr_locF"=>dwhr_locF,
            "dwhr_fixF"=>dwhr_fixF,
           }
    update_args_hash(measures, measure_subdir, args)
    
  end

  def self.get_heating_system(building, measures)

    htgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem"]
    
    return if not building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"].nil? # FIXME: Temporary
    
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
        update_args_hash(measures, measure_subdir, args)
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        measure_subdir = "ResidentialHVACFurnaceFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "afue"=>afue,
                "fan_power_installed"=>0.5,
                "capacity"=>heat_capacity_kbtuh
               }
        update_args_hash(measures, measure_subdir, args)
        
      end
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/Boiler")
    
      afue = Float(XMLHelper.get_value(htgsys,"AnnualHeatingEfficiency[Units='AFUE']/Value"))
    
      if fuel == "electricity"
      
        measure_subdir = "ResidentialHVACBoilerElectric"
        args = {
                "system_type"=>Constants.BoilerTypeForcedDraft,
                "afue"=>afue,
                "oat_reset_enabled"=>false,
                "oat_high"=>nil, # FIXME
                "oat_low"=>nil, # FIXME
                "oat_hwst_high"=>nil, # FIXME
                "oat_hwst_low"=>nil, # FIXME
                "design_temp"=>180, # FIXME
                "capacity"=>heat_capacity_kbtuh
               }
        update_args_hash(measures, measure_subdir, args)
        
      elsif ["natural gas", "fuel oil", "propane"].include? fuel
      
        measure_subdir = "ResidentialHVACBoilerFuel"
        args = {
                "fuel_type"=>to_beopt_fuel(fuel),
                "system_type"=>Constants.BoilerTypeForcedDraft,
                "afue"=>afue,
                "oat_reset_enabled"=>false, # FIXME
                "oat_high"=>nil, # FIXME
                "oat_low"=>nil, # FIXME
                "oat_hwst_high"=>nil, # FIXME
                "oat_hwst_low"=>nil, # FIXME
                "design_temp"=>180, # FIXME
                "modulation"=>false,
                "capacity"=>heat_capacity_kbtuh
               }
        update_args_hash(measures, measure_subdir, args)
        
      end
      
    elsif XMLHelper.has_element(htgsys, "HeatingSystemType/ElectricResistance")
    
      percent = Float(XMLHelper.get_value(htgsys, "AnnualHeatingEfficiency[Units='Percent']/Value"))
    
      measure_subdir = "ResidentialHVACElectricBaseboard"
      args = {
              "efficiency"=>percent,
              "capacity"=>heat_capacity_kbtuh
             }
      update_args_hash(measures, measure_subdir, args)
             
    end

  end

  def self.get_cooling_system(building, measures)
  
    clgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
    
    return if not building.elements["BuildingDetails/Systems/HVAC/HVACPlant/HeatPump"].nil? # FIXME: Temporary
    
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
        update_args_hash(measures, measure_subdir, args)
        
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
        update_args_hash(measures, measure_subdir, args)
        
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
        update_args_hash(measures, measure_subdir, args)
        
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
      update_args_hash(measures, measure_subdir, args)
      
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
    
      if not hp.elements["AnnualCoolEfficiency"].nil?
        seer_nom = Float(XMLHelper.get_value(hp, "AnnualCoolEfficiency[Units='SEER']/Value"))
        seer_adj = Float(XMLHelper.get_value(hp, "extension/PerformanceAdjustmentSEER"))
      else
        # FIXME: Currently getting from AC
        clgsys = building.elements["BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem"]
        seer_nom = Float(XMLHelper.get_value(clgsys, "AnnualCoolingEfficiency[Units='SEER']/Value"))
        seer_adj = Float(XMLHelper.get_value(clgsys, "extension/PerformanceAdjustmentSEER"))
      end
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
                "supplemental_efficiency"=>1,
                "supplemental_capacity"=>backup_heat_capacity_kbtuh
               }
        update_args_hash(measures, measure_subdir, args)
        
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
        update_args_hash(measures, measure_subdir, args)
        
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
        update_args_hash(measures, measure_subdir, args)
        
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
      update_args_hash(measures, measure_subdir, args)
             
    elsif hp_type == "ground-to-air"
    
      eer = Float(XMLHelper.get_value(hp, "AnnualCoolEfficiency[Units='EER']/Value"))
      cop = Float(XMLHelper.get_value(hp, "AnnualHeatEfficiency[Units='COP']/Value"))
    
      measure_subdir = "ResidentialHVACGroundSourceHeatPumpVerticalBore"
      args = {
              "cop"=>cop,
              "eer"=>eer,
              "ground_conductivity"=>0.6,
              "grout_conductivity"=>0.4,
              "bore_config"=>Constants.SizingAuto,
              "bore_holes"=>Constants.SizingAuto,
              "bore_depth"=>Constants.SizingAuto,
              "bore_spacing"=>20.0,
              "bore_diameter"=>5.0,
              "pipe_size"=>0.75,
              "ground_diffusivity"=>0.0208,
              "fluid_type"=>Constants.FluidPropyleneGlycol,
              "frac_glycol"=>0.3,
              "design_delta_t"=>10.0,
              "pump_head"=>50.0,
              "u_tube_leg_spacing"=>0.9661,
              "u_tube_spacing_type"=>"b",
              "rated_shr"=>0.732,
              "fan_power"=>0.5,
              "heat_pump_capacity"=>cool_capacity_tons,
              "supplemental_efficiency"=>1,
              "supplemental_capacity"=>backup_heat_capacity_kbtuh
             }
      update_args_hash(measures, measure_subdir, args)
             
    end

  end

  def self.get_setpoints(building, measures) 

    control = building.elements["BuildingDetails/Systems/HVAC/HVACControl"]
    
    # TODO: Setbacks and setups
  
    htg_sp = Float(XMLHelper.get_value(control, "SetpointTempHeatingSeason"))
    clg_sp = Float(XMLHelper.get_value(control, "SetpointTempCoolingSeason"))
    
    measure_subdir = "ResidentialHVACHeatingSetpoints"
    args = {
            "weekday_setpoint"=>htg_sp,
            "weekend_setpoint"=>htg_sp,
            "use_auto_season"=>false,
            "season_start_month"=>"Jan",
            "season_end_month"=>"Dec"
           }  
    update_args_hash(measures, measure_subdir, args)
    
    measure_subdir = "ResidentialHVACCoolingSetpoints"
    args = {
            "weekday_setpoint"=>clg_sp,
            "weekend_setpoint"=>clg_sp,
            "use_auto_season"=>false,
            "season_start_month"=>"Jan",
            "season_end_month"=>"Dec"
           }  
    update_args_hash(measures, measure_subdir, args)

  end

  def self.get_ceiling_fan(building, measures)

    # FIXME
    cf = building.elements["BuildingDetails/Lighting/CeilingFan"]
    
    measure_subdir = "ResidentialHVACCeilingFan"
    args = {
            "coverage"=>"NA",
            "specified_num"=>1,
            "power"=>45,
            "control"=>Constants.CeilingFanControlTypical,
            "use_benchmark_energy"=>true,
            "mult"=>1,
            "cooling_setpoint_offset"=>0,
            "weekday_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "weekend_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "monthly_sch"=>"1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248"
           }  
    update_args_hash(measures, measure_subdir, args)

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
            "air_flow_rate"=>air_flow_rate,
            "energy_factor"=>energy_factor,
            "humidity_setpoint"=>humidity_setpoint,
            "water_removal_rate"=>water_removal_rate
           }  
    update_args_hash(measures, measure_subdir, args)    
  
  end
  
  def self.get_lighting(building, measures)
  
    lighting = building.elements["BuildingDetails/Lighting"]
  
    annual_kwh_interior = Float(XMLHelper.get_value(lighting, "extension/AnnualInteriorkWh"))
    annual_kwh_exterior = Float(XMLHelper.get_value(lighting, "extension/AnnualExteriorkWh"))
    annual_kwh_garage = Float(XMLHelper.get_value(lighting, "extension/AnnualGaragekWh"))

    measure_subdir = "ResidentialLighting"
    args = {
            "option_type"=>Constants.OptionTypeLightingEnergyUses,
            "hw_cfl"=>0, # not used
            "hw_led"=>0, # not used
            "hw_lfl"=>0, # not used
            "pg_cfl"=>0, # not used
            "pg_led"=>0, # not used
            "pg_lfl"=>0, # not used
            "in_eff"=>15, # not used
            "cfl_eff"=>55, # not used
            "led_eff"=>80, # not used
            "lfl_eff"=>88, # not used
            "energy_use_interior"=>annual_kwh_interior,
            "energy_use_exterior"=>annual_kwh_exterior,
            "energy_use_garage"=>annual_kwh_garage
           }  
    update_args_hash(measures, measure_subdir, args)  

  end
  
  def self.get_mels(building, measures)
  
    # TODO: Split apart residual MELs and TVs for reporting
    
    sens_kWhs = 0
    lat_kWhs = 0
    building.elements.each("BuildingDetails/MiscLoads/PlugLoad[PlugLoadType='other' or PlugLoadType='TV other']") do |pl|
      kWhs = Float(XMLHelper.get_value(pl, "Load[Units='kWh/year']/Value"))
      sens_kWhs += kWhs * Float(XMLHelper.get_value(pl, "extension/FracSensible"))
      lat_kWhs += kWhs * Float(XMLHelper.get_value(pl, "extension/FracLatent"))
    end
    tot_kWhs = sens_kWhs + lat_kWhs
    
    measure_subdir = "ResidentialMiscPlugLoads"
    args = {
            "option_type"=>Constants.OptionTypePlugLoadsEnergyUse,
            "mult"=>0, # not used
            "energy_use"=>tot_kWhs,
            "sens_frac"=>(sens_kWhs/tot_kWhs),
            "lat_frac"=>(lat_kWhs/tot_kWhs),
            "weekday_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "weekend_sch"=>"0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05",
            "monthly_sch"=>"1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248",
           }  
    update_args_hash(measures, measure_subdir, args)  
  
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
      # FIXME: HoursInOperation isn't being used
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
      mech_vent_cfm = Float(XMLHelper.get_value(whole_house_fan, "RatedFlowRate"))
      mech_vent_w = Float(XMLHelper.get_value(whole_house_fan, "FanPower"))
      mech_vent_fan_power = mech_vent_w/mech_vent_cfm
      mech_vent_frac_62_2 = 1.0 # FIXME: Would prefer to provide airflow rate as measure input...
    end
    
    natural_ventilation = building.elements["BuildingDetails/Systems/HVAC/extension/natural_ventilation"]
    
    if natural_ventilation.nil?
      nat_vent_htg_offset = 1
      nat_vent_clg_offset = 1
      nat_vent_ovlp_offset = 1
      nat_vent_htg_season = true
      nat_vent_clg_season = true
      nat_vent_ovlp_season = true
      nat_vent_num_weekdays = 5
      nat_vent_num_weekends = 2
      nat_vent_frac_windows_open = 0.33
      nat_vent_frac_window_area_openable = 0.2
      nat_vent_max_oa_hr = 0.0115
      nat_vent_max_oa_rh = 0.7
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
  
    hvac_distribution = building.elements["BuildingDetails/Systems/HVAC/HVACDistribution"]
    air_distribution = nil
    if not hvac_distribution.nil?
      air_distribution = hvac_distribution.elements["DistributionSystemType/AirDistribution"]
    end
    
    if not air_distribution.nil?
      # Ducts
      supply_cfm25 = Float(XMLHelper.get_value(air_distribution, "DuctLeakageMeasurement[DuctType='supply']/DuctLeakage[Units='CFM25' and TotalOrToOutside='to outside']/Value"))
      return_cfm25 = Float(XMLHelper.get_value(air_distribution, "DuctLeakageMeasurement[DuctType='return']/DuctLeakage[Units='CFM25' and TotalOrToOutside='to outside']/Value"))
      supply_r = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='supply']/DuctInsulationRValue"))
      return_r = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='return']/DuctInsulationRValue"))
      supply_area = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='supply']/DuctSurfaceArea"))
      return_area = Float(XMLHelper.get_value(air_distribution, "Ducts[DuctType='return']/DuctSurfaceArea"))
      # FIXME: Values below
      duct_location = Constants.Auto
      duct_total_leakage = 0.3
      duct_supply_frac = 0.6
      duct_return_frac = 0.067
      duct_ah_supply_frac = 0.067
      duct_ah_return_frac = 0.267
      duct_location_frac = Constants.Auto
      duct_num_returns = 1
      duct_supply_area_mult = 1
      duct_return_area_mult = 1
      duct_r = 4.0
      duct_dse = "NA"
    else
      # DSE or no ducts
      if hvac_distribution.elements["AnnualHeatingDistributionSystemEfficiency"].nil? and hvac_distribution.elements["AnnualCoolingDistributionSystemEfficiency"].nil?
        # No ducts
        duct_location = "none"
        duct_total_leakage = 0
        duct_supply_frac = 0
        duct_return_frac = 0
        duct_ah_supply_frac = 0
        duct_ah_return_frac = 0
        duct_location_frac = Constants.Auto
        duct_num_returns = Constants.Auto
        duct_supply_area_mult = 1
        duct_return_area_mult = 1
        duct_r = 0
        duct_dse = "NA"
      else
        heat_dse = Float(XMLHelper.get_value(hvac_distribution, "AnnualHeatingDistributionSystemEfficiency"))
        cool_dse = Float(XMLHelper.get_value(hvac_distribution, "AnnualCoolingDistributionSystemEfficiency"))
        # FIXME: error if heat_dse != cool_dse
        duct_location = "none"
        duct_total_leakage = 0
        duct_supply_frac = 0
        duct_return_frac = 0
        duct_ah_supply_frac = 0
        duct_ah_return_frac = 0
        duct_location_frac = Constants.Auto
        duct_num_returns = Constants.Auto
        duct_supply_area_mult = 1
        duct_return_area_mult = 1
        duct_r = 0
        duct_dse = heat_dse
      end
    end
  
    measure_subdir = "ResidentialAirflow"
    args = {
            "living_ach50"=>infil_ach50,
            "garage_ach50"=>infil_ach50,
            "finished_basement_ach"=>0, # TODO: Need to handle above-grade basement
            "unfinished_basement_ach"=>0.1, # TODO: Need to handle above-grade basement
            "crawl_ach"=>crawl_sla,
            "pier_beam_ach"=>100,
            "unfinished_attic_sla"=>attic_sla,
            "shelter_coef"=>Constants.Auto,
            "has_hvac_flue"=>false, # FIXME
            "has_water_heater_flue"=>false, # FIXME
            "has_fireplace_chimney"=>false, # FIXME
            "terrain"=>Constants.TerrainSuburban,
            "mech_vent_type"=>mech_vent_type,
            "mech_vent_total_efficiency"=>mech_vent_total_efficiency,
            "mech_vent_sensible_efficiency"=>mech_vent_sensible_efficiency,
            "mech_vent_fan_power"=>mech_vent_fan_power,
            "mech_vent_frac_62_2"=>mech_vent_frac_62_2,
            "mech_vent_ashrae_std"=>2013,
            "mech_vent_infil_credit"=>true,
            "is_existing_home"=>false, # FIXME
            "clothes_dryer_exhaust"=>0,
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
            "duct_location"=>duct_location,
            "duct_total_leakage"=>duct_total_leakage,
            "duct_supply_frac"=>duct_supply_frac,
            "duct_return_frac"=>duct_return_frac,
            "duct_ah_supply_frac"=>duct_ah_supply_frac,
            "duct_ah_return_frac"=>duct_ah_return_frac,
            "duct_location_frac"=>duct_location_frac,
            "duct_num_returns"=>duct_num_returns,
            "duct_supply_area_mult"=>duct_supply_area_mult,
            "duct_return_area_mult"=>duct_return_area_mult,
            "duct_r"=>duct_r,
            "duct_dse"=>duct_dse,
           }  
    update_args_hash(measures, measure_subdir, args) # FIXME (need to figure out approach for dealing with volumes)

  end

  def self.get_hvac_sizing(building, measures)
    
    measure_subdir = "ResidentialHVACSizing"
    args = {
            "show_debug_info"=>false
           }  
    update_args_hash(measures, measure_subdir, args) # FIXME (need to figure out approach for dealing with volumes)

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
              "size"=>power_kw,
              "module_type"=>Constants.PVModuleTypeStandard,
              "system_losses"=>0.14,
              "inverter_efficiency"=>inv_eff,
              "azimuth_type"=>Constants.CoordAbsolute,
              "azimuth"=>az, # TODO: Double-check
              "tilt_type"=>Constants.CoordAbsolute,
              "tilt"=>tilt # TODO: Double-check
             }  
      update_args_hash(measures, measure_subdir, args)
      
    end

  end
  
end

class OSModel

  def self.create_geometry(hpxml_doc, runner, model)

    geometry_errors = []
    building = hpxml_doc.elements["/HPXML/Building"]
  
    # Geometry
    avg_ceil_hgt = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/AverageCeilingHeight"]
    if avg_ceil_hgt.nil?
      avg_ceil_hgt = 8.0
    else
      avg_ceil_hgt = avg_ceil_hgt.text.to_f
    end
    
    spaces = create_all_spaces_and_zones(model, building)

    fenestration_areas = {}
    add_windows(model, building, geometry_errors, spaces, fenestration_areas)
    add_doors(model, building, geometry_errors, spaces, fenestration_areas)
    add_foundation_floors(model, building, spaces)
    add_foundation_walls(model, building, spaces, fenestration_areas)
    foundation_ceiling_area = add_foundation_ceilings(model, building, spaces)
    add_living_floors(model, building, geometry_errors, spaces, foundation_ceiling_area)
    add_above_grade_walls(model, building, geometry_errors, avg_ceil_hgt, spaces, fenestration_areas)
    add_attic_floors(model, building, geometry_errors, spaces)    
    add_attic_roofs(model, building, geometry_errors, spaces)
    
    geometry_errors.each do |error|
      runner.registerError(error)
    end

    unless geometry_errors.empty?
      return false
    end    
    
    # FIXME: Set the zone volumes based on the sum of space volumes
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
    model.getSurfaces.sort.each do |surface|

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
    
    # Explode the above-grade floors
    # FIXME: Need to fix heights for airflow measure
    floor_offset = 0.5
    surfaces_moved = []
    model.getSurfaces.sort.each do |surface|

      next unless surface.surfaceType.downcase == "floor" or surface.surfaceType.downcase == "roofceiling"
      next if surface.outsideBoundaryCondition.downcase == "ground"
      
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
    model.getSubSurfaces.sort.each do |sub_surface|

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
    
    # Store building unit information
    unit = OpenStudio::Model::BuildingUnit.new(model)
    unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
    unit.setName(Constants.ObjectNameBuildingUnit)
    model.getSpaces.each do |space|
      space.setBuildingUnit(unit)
    end    
    
    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(1)    
    
    # Store number of stories TODO: Review this
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
    
    # Store info for HVAC Sizing measure
    if building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent"].text == "true"
      unit.setFeature(Constants.SizingInfoGarageFracUnderFinishedSpace, 1.0) # FIXME: assumption
    end

    return true
    
  end
  
  private
  
  def self.create_spaces_and_zones(model, spaces, space_name, thermal_zone_name)
    if not spaces.keys.include? space_name
      thermal_zone = create_zone(model, thermal_zone_name)
      create_space(model, space_name, spaces, thermal_zone)
    end
  end

  def self.create_zone(model, name)
    thermal_zone = OpenStudio::Model::ThermalZone.new(model)
    thermal_zone.setName(name)
    return thermal_zone
  end
  
  def self.create_space(model, name, spaces, thermal_zone)
    space = OpenStudio::Model::Space.new(model)
    space.setName(name)
    space.setThermalZone(thermal_zone)
    spaces[name] = space
  end

  def self.create_all_spaces_and_zones(model, building)
    
    spaces = {}
    
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      attic_type = attic.elements["AtticType"].text
      if ["vented attic", "unvented attic"].include? attic_type
        create_spaces_and_zones(model, spaces, Constants.UnfinishedAtticSpace, Constants.UnfinishedAtticZone)
      elsif attic_type == "cape cod"
        create_spaces_and_zones(model, spaces, Constants.FinishedAtticSpace, Constants.LivingZone)
      elsif attic_type != "flat roof" and attic_type != "cathedral ceiling"
        fail "Unhandled value (#{attic_type})."
      end
    
      floors = attic.elements["Floors"]
      floors.elements.each("Floor") do |floor|
    
        exterior_adjacent_to = floor.elements["extension/ExteriorAdjacentTo"].text
        if exterior_adjacent_to == "living space"
          create_spaces_and_zones(model, spaces, Constants.LivingSpace, Constants.LivingZone)
        elsif exterior_adjacent_to == "garage"
          create_spaces_and_zones(model, spaces, Constants.GarageSpace, Constants.GarageZone)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
      
      walls = attic.elements["Walls"]
      walls.elements.each("Wall") do |wall|
      
        exterior_adjacent_to = wall.elements["extension/ExteriorAdjacentTo"].text
        if exterior_adjacent_to == "living space"
          create_spaces_and_zones(model, spaces, Constants.LivingSpace, Constants.LivingZone)
        elsif exterior_adjacent_to == "garage"
          create_spaces_and_zones(model, spaces, Constants.GarageSpace, Constants.GarageZone)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end        

      end
      
    end
    
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation_type = foundation.elements["FoundationType"]      
      if foundation_type.elements["Basement/Conditioned/text()='true'"]        
        create_spaces_and_zones(model, spaces, Constants.FinishedBasementSpace, Constants.FinishedBasementZone)
      elsif foundation_type.elements["Basement/Conditioned/text()='false'"]      
        create_spaces_and_zones(model, spaces, Constants.UnfinishedBasementSpace, Constants.UnfinishedBasementZone)
      elsif foundation_type.elements["Crawlspace"]
        create_spaces_and_zones(model, spaces, Constants.CrawlSpace, Constants.CrawlZone)
      elsif foundation_type.elements["Ambient"]
        create_spaces_and_zones(model, spaces, Constants.PierBeamSpace, Constants.PierBeamZone)
      elsif not foundation_type.elements["SlabOnGrade"]
        fail "Unhandled value (#{foundation_type})."
      end
      
      foundation.elements.each("FrameFloor") do |frame_floor|
        
        exterior_adjacent_to = frame_floor.elements["extension/ExteriorAdjacentTo"].text
        if exterior_adjacent_to == "living space"
          create_spaces_and_zones(model, spaces, Constants.LivingSpace, Constants.LivingZone)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
      
      foundation.elements.each("FoundationWall") do |foundation_wall|
        
        exterior_adjacent_to = foundation_wall.elements["extension/ExteriorAdjacentTo"].text
        if exterior_adjacent_to == "unconditioned basement"
          create_spaces_and_zones(model, spaces, Constants.UnfinishedBasementSpace, Constants.UnfinishedBasementZone)
        elsif exterior_adjacent_to == "conditioned basement"
          create_spaces_and_zones(model, spaces, Constants.FinishedBasementSpace, Constants.FinishedBasementZone)
        elsif exterior_adjacent_to == "crawlspace"
          create_spaces_and_zones(model, spaces, Constants.CrawlSpace, Constants.CrawlZone)
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
    
    end

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      interior_adjacent_to = wall.elements["extension/InteriorAdjacentTo"].text
      if interior_adjacent_to == "living space"
        create_spaces_and_zones(model, spaces, Constants.LivingSpace, Constants.LivingZone)
      elsif interior_adjacent_to == "garage"
        create_spaces_and_zones(model, spaces, Constants.GarageSpace, Constants.GarageZone)
      else
        fail "Unhandled value (#{interior_adjacent_to})."
      end
      
      exterior_adjacent_to = wall.elements["extension/ExteriorAdjacentTo"].text
      if exterior_adjacent_to == "garage"
        create_spaces_and_zones(model, spaces, Constants.GarageSpace, Constants.GarageZone)
      elsif exterior_adjacent_to == "living space"
        create_spaces_and_zones(model, spaces, Constants.LivingSpace, Constants.LivingZone)
      elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
        fail "Unhandled value (#{exterior_adjacent_to})."
      end      
      
    end
    
    return spaces
    
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

  def self.net_wall_area(gross_wall_area, wall_fenestration_areas, wall_id)
    if wall_fenestration_areas.keys.include? wall_id
      return gross_wall_area - OpenStudio.convert(wall_fenestration_areas[wall_id],"ft^2","m^2").get
    end    
    return gross_wall_area
  end

  def self.get_foundation_space_name(foundation_type)
    if foundation_type.elements["Basement/Conditioned/text()='true'"]        
      return Constants.FinishedBasementSpace
    elsif foundation_type.elements["Basement/Conditioned/text()='false'"]      
      return Constants.UnfinishedBasementSpace
    elsif foundation_type.elements["Crawlspace"]
      return Constants.CrawlSpace
    elsif foundation_type.elements["SlabOnGrade"]
      return Constants.LivingSpace
    elsif foundation_type.elements["Ambient"]
      return Constants.PierBeamSpace
    else
      fail "Unhandled value (#{foundation_type})."
    end
  end
  
  def self.add_foundation_floors(model, building, spaces)

    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      foundation_space_name = get_foundation_space_name(foundation.elements["FoundationType"])

      foundation.elements.each("Slab") do |slab|
      
        slab_id = slab.elements["SystemIdentifier"].attributes["id"]
      
        slab_width = OpenStudio.convert(Math::sqrt(slab.elements["Area"].text.to_f),"ft","m").get
        slab_length = OpenStudio.convert(slab.elements["Area"].text.to_f,"ft^2","m^2").get / slab_width
        
        z_origin = 0
        unless slab.elements["DepthBelowGrade"].nil?
          z_origin = -OpenStudio.convert(slab.elements["DepthBelowGrade"].text.to_f,"ft","m").get
        end
        
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(slab_length, slab_width, z_origin), model)
        surface.setName(slab_id)
        surface.setSurfaceType("Floor") 
        surface.setOutsideBoundaryCondition("Ground")
        surface.setSpace(spaces[foundation_space_name])
        
      end
      
    end

  end

  def self.add_foundation_walls(model, building, spaces, fenestration_areas)
  
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      foundation_space_name = get_foundation_space_name(foundation.elements["FoundationType"])
      fnd_id = foundation.elements["SystemIdentifier"].attributes["id"]
      
      foundation.elements.each("FoundationWall") do |wall|
      
        wall_id = wall.elements["SystemIdentifier"].attributes["id"]
        
        exterior_adjacent_to = wall.elements["extension/ExteriorAdjacentTo"].text
        
        wall_height = OpenStudio.convert(wall.elements["Height"].text.to_f,"ft","m").get
        wall_length = net_wall_area(OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get, fenestration_areas, fnd_id) / wall_height
        
        z_origin = -OpenStudio.convert(wall.elements["BelowGradeDepth"].text.to_f,"ft","m").get
        
        surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, z_origin), model)
        surface.setName(wall_id)
        surface.setSurfaceType("Wall")
        if exterior_adjacent_to == "ground"
          surface.setOutsideBoundaryCondition("Ground")
        else
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        surface.setSpace(spaces[foundation_space_name])
        
      end
    
    end

  end

  def self.add_foundation_ceilings(model, building, spaces)
       
    foundation_ceiling_area = 0
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      foundation_space_name = get_foundation_space_name(foundation.elements["FoundationType"])
     
      foundation.elements.each("FrameFloor") do |framefloor|
      
        floor_id = framefloor.elements["SystemIdentifier"].attributes["id"]

        framefloor_width = OpenStudio.convert(Math::sqrt(framefloor.elements["Area"].text.to_f),"ft","m").get
        framefloor_length = OpenStudio.convert(framefloor.elements["Area"].text.to_f,"ft^2","m^2").get / framefloor_width
        
        z_origin = 0
        
        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(framefloor_length, framefloor_width, z_origin), model)
        surface.setName(floor_id)
        surface.setSurfaceType("RoofCeiling")
        surface.setSpace(spaces[foundation_space_name])
        surface.createAdjacentSurface(spaces[Constants.LivingSpace])
        
        foundation_ceiling_area += framefloor.elements["Area"].text.to_f
      
      end
      
      foundation.elements.each("Slab") do |slab|
      
        foundation_ceiling_area += slab.elements["Area"].text.to_f
      
      end
    
    end
    
    return foundation_ceiling_area
      
  end

  def self.add_living_floors(model, building, errors, spaces, foundation_ceiling_area)

    finished_floor_area = building.elements["BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea"].text.to_f
    above_grade_finished_floor_area = finished_floor_area - foundation_ceiling_area
    return unless above_grade_finished_floor_area > 0
    
    finishedfloor_width = OpenStudio.convert(Math::sqrt(above_grade_finished_floor_area),"ft","m").get
    finishedfloor_length = OpenStudio.convert(above_grade_finished_floor_area,"ft^2","m^2").get / finishedfloor_width
    
    surface = OpenStudio::Model::Surface.new(add_floor_polygon(-finishedfloor_width, -finishedfloor_length, 0), model)
    surface.setName("inferred finished floor")
    surface.setSurfaceType("Floor")
    surface.setSpace(spaces[Constants.LivingSpace])
    surface.setOutsideBoundaryCondition("Adiabatic")

  end

  def self.add_above_grade_walls(model, building, errors, avg_ceil_hgt, spaces, fenestration_areas)

    building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
    
      interior_adjacent_to = wall.elements["extension/InteriorAdjacentTo"].text
      exterior_adjacent_to = wall.elements["extension/ExteriorAdjacentTo"].text
      
      wall_id = wall.elements["SystemIdentifier"].attributes["id"]
      
      wall_height = OpenStudio.convert(avg_ceil_hgt,"ft","m").get
      wall_length = net_wall_area(OpenStudio.convert(wall.elements["Area"].text.to_f,"ft^2","m^2").get, fenestration_areas, wall_id) / wall_height

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(wall_length, wall_height, 0), model)
      surface.setName(wall_id)
      surface.setSurfaceType("Wall") 
      if ["living space"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.LivingSpace])
      elsif ["garage"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.GarageSpace])
      elsif ["unvented attic", "vented attic"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.UnfinishedAtticSpace])
      elsif ["cape cod"].include? interior_adjacent_to
        surface.setSpace(spaces[Constants.FinishedAtticSpace])
      else
        fail "Unhandled value (#{interior_adjacent_to})."
      end
      if ["ambient"].include? exterior_adjacent_to
        surface.setOutsideBoundaryCondition("Outdoors")
      elsif ["garage"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.GarageSpace])
      elsif ["unvented attic", "vented attic"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.UnfinishedAtticSpace])
      elsif ["cape cod"].include? exterior_adjacent_to
        surface.createAdjacentSurface(spaces[Constants.FinishedAtticSpace])
      elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
        fail "Unhandled value (#{exterior_adjacent_to})."
      end
      
    end
    
  end
  
  def self.add_attic_floors(model, building, errors, spaces)

    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      attic_type = attic.elements["AtticType"].text
    
      next if ["cathedral ceiling", "flat roof"].include? attic_type    

      floors = attic.elements["Floors"]
      floors.elements.each("Floor") do |floor|
      
        floor_id = floor.elements["SystemIdentifier"].attributes["id"]
        exterior_adjacent_to = floor.elements["extension/ExteriorAdjacentTo"].text
        
        floor_width = OpenStudio.convert(Math::sqrt(floor.elements["Area"].text.to_f),"ft","m").get
        floor_length = OpenStudio.convert(floor.elements["Area"].text.to_f,"ft^2","m^2").get / floor_width
       
        surface = OpenStudio::Model::Surface.new(add_floor_polygon(floor_length, floor_width, 0), model)
        surface.setName(floor_id)
        surface.setSurfaceType("Floor")
        if ["vented attic", "unvented attic"].include? attic_type
          surface.setSpace(spaces[Constants.UnfinishedAtticSpace])
        elsif ["cape cod"].include? attic_type
          surface.setSpace(spaces[Constants.FinishedAtticSpace])
        elsif attic_type != "flat roof" and attic_type != "cathedral ceiling"
          fail "Unhandled value (#{attic_type})."
        end
        if ["living space"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.LivingSpace])
        elsif ["garage"].include? exterior_adjacent_to
          surface.createAdjacentSurface(spaces[Constants.GarageSpace])
        elsif exterior_adjacent_to != "ambient" and exterior_adjacent_to != "ground"
          fail "Unhandled value (#{exterior_adjacent_to})."
        end
        
      end
      
    end
      
  end

  def self.add_attic_roofs(model, building, errors, spaces)
  
    building.elements.each("BuildingDetails/Enclosure/AtticAndRoof/Attics/Attic") do |attic|
    
      attic_type = attic.elements["AtticType"].text
      
      roofs = attic.elements["Roofs"]
      roofs.elements.each("Roof") do |roof|
  
        roof_id = roof.elements["SystemIdentifier"].attributes["id"]
        
        roof_width = OpenStudio.convert(Math::sqrt(roof.elements["Area"].text.to_f),"ft","m").get
        roof_length = OpenStudio.convert(roof.elements["Area"].text.to_f,"ft^2","m^2").get / roof_width

        surface = OpenStudio::Model::Surface.new(add_ceiling_polygon(roof_length, roof_width, 0), model)
        surface.setName(roof_id)
        surface.setSurfaceType("RoofCeiling")
        surface.setOutsideBoundaryCondition("Outdoors")
        if ["unvented attic", "vented attic"].include? attic_type
          surface.setSpace(spaces[Constants.UnfinishedAtticSpace])
        elsif ["flat roof", "cathedral ceiling"].include? attic_type
          surface.setSpace(spaces[Constants.LivingSpace])
        elsif ["cape cod"].include? attic_type
          surface.setSpace(spaces[Constants.FinishedAtticSpace])
        end
        
      end

    end
        
  end
  
  def self.add_windows(model, building, errors, spaces, fenestration_areas)
  
    building.elements.each("BuildingDetails/Enclosure/Windows/Window") do |window|
    
      window_id = window.elements["SystemIdentifier"].attributes["id"]

      window_height = OpenStudio.convert(5.0,"ft","m").get
      window_width = OpenStudio.convert(window.elements["Area"].text.to_f,"ft^2","m^2").get / window_height

      if not fenestration_areas.keys.include? window.elements["AttachedToWall"].attributes["idref"]
        fenestration_areas[window.elements["AttachedToWall"].attributes["idref"]] = window.elements["Area"].text.to_f
      else
        fenestration_areas[window.elements["AttachedToWall"].attributes["idref"]] += window.elements["Area"].text.to_f
      end

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(window_width, window_height, 0, window.elements["Azimuth"].text.to_f, [0, 0.001, 0.001 * 2, 0.001]), model) # offsets B, L, T, R
      surface.setName("surface #{window_id}")
      surface.setSurfaceType("Wall")
      building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
        next unless wall.elements["SystemIdentifier"].attributes["id"] == window.elements["AttachedToWall"].attributes["idref"]
        interior_adjacent_to = wall.elements["extension/InteriorAdjacentTo"].text
        if interior_adjacent_to == "living space"
          surface.setSpace(spaces[Constants.LivingSpace])
        elsif interior_adjacent_to == "garage"
          surface.setSpace(spaces[Constants.GarageSpace])
        elsif interior_adjacent_to == "vented attic" or interior_adjacent_to == "unvented attic"
          surface.setSpace(spaces[Constants.UnfinishedAtticSpace])
        elsif interior_adjacent_to == "cape cod"
          surface.setSpace(spaces[Constants.FinishedAtticSpace])
        else
          fail "Unhandled value (#{interior_adjacent_to})."
        end
      end
      surface.setOutsideBoundaryCondition("Adiabatic")

      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(window_width, window_height, 0, window.elements["Azimuth"].text.to_f, [-0.001, 0, 0.001, 0]), model) # offsets B, L, T, R
      sub_surface.setName(window_id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType("FixedWindow")
      
    end
   
  end
  
  def self.add_doors(model, building, errors, spaces, fenestration_areas)
  
    building.elements.each("BuildingDetails/Enclosure/Doors/Door") do |door|
    
      door_id = door.elements["SystemIdentifier"].attributes["id"]

      door_height = OpenStudio.convert(6.666,"ft","m").get
      door_width = OpenStudio.convert(door.elements["Area"].text.to_f,"ft^2","m^2").get / door_height
    
      if not fenestration_areas.keys.include? door.elements["AttachedToWall"].attributes["idref"]
        fenestration_areas[door.elements["AttachedToWall"].attributes["idref"]] = door.elements["Area"].text.to_f
      else
        fenestration_areas[door.elements["AttachedToWall"].attributes["idref"]] += door.elements["Area"].text.to_f
      end

      surface = OpenStudio::Model::Surface.new(add_wall_polygon(door_width, door_height, 0, door.elements["Azimuth"].text.to_f, [0, 0.001, 0.001, 0.001]), model) # offsets B, L, T, R
      surface.setName("surface #{door_id}")
      surface.setSurfaceType("Wall")
      building.elements.each("BuildingDetails/Enclosure/Walls/Wall") do |wall|
        next unless wall.elements["SystemIdentifier"].attributes["id"] == door.elements["AttachedToWall"].attributes["idref"]
        interior_adjacent_to = wall.elements["extension/InteriorAdjacentTo"].text
        if interior_adjacent_to == "living space"
          surface.setSpace(spaces[Constants.LivingSpace])
        elsif interior_adjacent_to == "garage"
          surface.setSpace(spaces[Constants.GarageSpace])
        elsif interior_adjacent_to == "vented attic" or interior_adjacent_to == "unvented attic"
          surface.setSpace(spaces[Constants.UnfinishedAtticSpace])
        elsif interior_adjacent_to == "cape cod"
          surface.setSpace(spaces[Constants.FinishedAtticSpace])
        else
          fail "Unhandled value (#{interior_adjacent_to})."
        end
      end
      surface.setOutsideBoundaryCondition("Adiabatic")

      sub_surface = OpenStudio::Model::SubSurface.new(add_wall_polygon(door_width, door_height, 0, door.elements["Azimuth"].text.to_f, [0, 0, 0, 0]), model) # offsets B, L, T, R
      sub_surface.setName(door_id)
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType("Door")
      
    end
   
  end  
  
end

# register the measure to be used by the application
EnergyRatingIndex301.new.registerWithApplication
