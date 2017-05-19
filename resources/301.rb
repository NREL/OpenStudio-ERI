require 'rexml/document'
require 'rexml/xpath'
require "#{File.dirname(__FILE__)}/constants"

class EnergyRatingIndex301Ruleset

  def self.apply_ruleset(hpxml_doc, calc_type)
  
    errors = []
    
    # Update XML type
    header = hpxml_doc.elements["//XMLTransactionHeaderInformation"]
    xmltype = XMLHelper.get_value(header, "XMLType")
    XMLHelper.set_element(header, "XMLType", "#{xmltype} - #{calc_type}")
    
    # Get the building element
    event_types = []
    hpxml_doc.elements.each("*/*/ProjectStatus/EventType") do |el|
      next unless el.text == "audit" # TODO: consider all event types?
      event_types << el.text
    end
    building = hpxml_doc.elements["//Building[ProjectStatus/EventType='#{event_types[0]}']"]
  
    # Get high-level inputs needed by multiple methods
    cfa = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/ConditionedFloorArea").to_f
    nbeds = XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/NumberofBedrooms").to_i
    climate_zone = XMLHelper.get_value(building, "BuildingDetails/ClimateandRiskZones/ClimateZoneIECC/ClimateZone")
    
    # Update HPXML object based on calculation type
    if calc_type == Constants.CalcTypeERIReferenceHome
        apply_reference_home_ruleset(building, cfa, nbeds, climate_zone)
    elsif calc_type == Constants.CalcTypeERIRatedHome
        apply_rated_home_ruleset(building)
    elsif calc_type == Constants.CalcTypeERIndexAdjustmentDesign
        apply_index_adjustment_design_ruleset(building)
    end
    
    return errors, building
    
  end

  def self.apply_reference_home_ruleset(building, cfa, nbeds, climate_zone)
    set_air_infiltration_reference(building)
    set_roofs_reference(building)
    set_attics_reference(building, climate_zone)
    set_frame_floors_reference(building, climate_zone)
    set_foundation_walls_reference(building, climate_zone)
    set_slabs_reference(building, climate_zone)
    set_rim_joists_reference(building)
    set_walls_reference(building, climate_zone)
    set_windows_reference(building, cfa, climate_zone)
    set_skylights_reference(building)
    set_doors_reference(building, climate_zone)
    set_hvac_plants_reference(building)
    set_hvac_controls_reference(building)
    set_hvac_distributions_reference(building)
    set_mechanical_ventilation_reference(building)
    set_combustion_ventilation_reference(building)
    set_water_heating_reference(building)
    set_hot_water_distribution_reference(building, nbeds)
    set_water_fixture_reference(building, nbeds)
    set_solar_thermal_reference(building)
    set_photovoltaics_reference(building)
    set_wind_reference(building)
    set_clothes_washer_reference(building, cfa, nbeds)
    set_clothes_dryer_reference(building, cfa, nbeds)
    set_dishwasher_reference(building, cfa, nbeds)
    set_refrigerator_reference(building, cfa, nbeds)
    set_freezer_reference(building)
    set_dehumidifier_reference(building)
    set_cooking_range_oven_reference(building, cfa, nbeds)
    set_lighting_reference(building, cfa, nbeds)
    set_ceiling_fans_reference(building)
    set_pools_reference(building)
    set_misc_loads_reference(building, cfa, nbeds)
    set_health_and_safety_reference(building)
  end
  
  def self.apply_rated_home_ruleset(building)
  end
  
  def self.apply_index_adjustment_design_ruleset(building)
  
  end
  
  def self.set_air_infiltration_reference(building)
    '''
    Table 4.2.2(1) - Air exchange rate
    Specific Leakage Area (SLA) = 0.00036 assuming no energy recovery and with energy loads calculated in 
    quadrature
    
    Table 4.2.2(1) - Attics
    Type: vented with aperture = 1ft2 per 300 ft2 ceiling area
    
    Table 4.2.2(1) - Crawlspaces
    Type: vented with net free vent aperture = 1ft2 per 150 ft2 of crawlspace floor area.
    U-factor: from Table 4.2.2(2) for floors over unconditioned spaces or outdoor environment.
    '''
    
    air_infiltration = building.elements["BuildingDetails/Enclosure/AirInfiltration"]
    extension = XMLHelper.set_element(air_infiltration, "extension")
    
    XMLHelper.set_element(extension, "BuildingSpecificLeakageArea", 0.00036)
    
    # FIXME: Only set if the building has an attic or crawlspace
    # FIXME: Use AirInfiltration extension or Attic/Foundation extensions?
    XMLHelper.set_element(extension, "AtticSpecificLeakageArea", 1.0/300.0)
    XMLHelper.set_element(extension, "CrawlspaceSpecificLeakageArea", 1.0/150.0)

  end
  
  def self.set_roofs_reference(building)
    '''
    Table 4.2.2(1) - Roofs
    Type: composition shingle on wood sheathing
    Gross area: same as Rated Home
    Solar absorptance = 0.75
    Emittance = 0.90
    '''
    
    roofs = building.elements["BuildingDetails/Enclosure/AtticAndRoof/Roofs"]
    orig_roofs = XMLHelper.delete_elements(roofs, "Roof")
    
    orig_roofs.each do |orig_roof|
    
      # Create new roof
      new_roof = XMLHelper.add_element(roofs, "Roof")
      XMLHelper.copy_element(new_roof, orig_roof, "SystemIdentifier")
      XMLHelper.copy_element(new_roof, orig_roof, "AttachedToSpace")
      XMLHelper.set_element(new_roof, "RoofType", "shingles")
      XMLHelper.set_element(new_roof, "DeckType", "wood")
      XMLHelper.copy_element(new_roof, orig_roof, "Pitch")
      XMLHelper.copy_element(new_roof, orig_roof, "RoofArea")
      XMLHelper.set_element(new_roof, "RadiantBarrier", false)
      extension = XMLHelper.set_element(new_roof, "extension")
      XMLHelper.set_element(extension, "SolarAbsorptance", 0.75)
      XMLHelper.set_element(extension, "Emittance", 0.90)
      
    end
    
  end

  def self.set_attics_reference(building, climate_zone)
    '''
    Table 4.2.2(1) - Ceilings
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    # FIXME: Need to look out for conditioned attics, etc.?
    # FIXME: If rated home has flat roof or cathedral ceiling, reference home still has vented attic with floor insulation or no attic?
    
    ufactor = get_reference_component_characteristics(climate_zone, "ceiling")
    
    attics = building.elements["BuildingDetails/Enclosure/AtticAndRoof/Attics"]
    orig_attics = XMLHelper.delete_elements(attics, "Attic")
    
    orig_attics.each do |orig_attic|
    
      # Create new attic
      new_attic = XMLHelper.add_element(attics, "Attic")
      XMLHelper.copy_element(new_attic, orig_attic, "SystemIdentifier")
      XMLHelper.copy_element(new_attic, orig_attic, "AttachedToSpace")
      XMLHelper.copy_element(new_attic, orig_attic, "AttachedToRoof")
      XMLHelper.copy_element(new_attic, orig_attic, "ExteriorAdjacentTo")
      XMLHelper.copy_element(new_attic, orig_attic, "InteriorAdjacentTo")
      XMLHelper.copy_element(new_attic, orig_attic, "AtticKneeWall")
      XMLHelper.set_element(new_attic, "AtticType", "vented attic")
      insulation = XMLHelper.set_element(new_attic, "AtticFloorInsulation")
      XMLHelper.copy_element(insulation, orig_attic, "AtticFloorInsulation/SystemIdentifier")
      XMLHelper.set_element(insulation, "InsulationGrade", 1)
      XMLHelper.set_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      XMLHelper.copy_element(new_attic, orig_attic, "Area")

    end
    
  end

  def self.set_frame_floors_reference(building, climate_zone)
    '''
    Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    # FIXME: Need to check the floor is over unconditioned space or outdoors?
    
    ufactor = get_reference_component_characteristics(climate_zone, "floor")

    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
      
      orig_floors = XMLHelper.delete_elements(foundation, "FrameFloor")
      orig_floors.each do |orig_floor|
      
        # Create new floor
        new_floor = XMLHelper.add_element(foundation, "FrameFloor")
        XMLHelper.copy_element(new_floor, orig_floor, "SystemIdentifier")
        XMLHelper.copy_element(new_floor, orig_floor, "Area")
        insulation = XMLHelper.set_element(new_floor, "Insulation")
        XMLHelper.copy_element(insulation, orig_floor, "Insulation/SystemIdentifier")
        XMLHelper.set_element(insulation, "InsulationGrade", 1)
        XMLHelper.set_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
        
      end
    end
    
  end

  def self.set_foundation_walls_reference(building, climate_zone)
    '''
    Table 4.2.2(1) - Conditioned basement walls
    Type: same as Rated Home
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2) with the insulation layer on the interior side of walls
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    # FIXME: Need to check if the foundation wall is adjacent to living space?
    
    ufactor = get_reference_component_characteristics(climate_zone, "basement_wall")
    
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|
    
      orig_walls = XMLHelper.delete_elements(foundation, "FoundationWall")
      orig_walls.each do |orig_wall|
      
        # Create new wall
        new_wall = XMLHelper.add_element(foundation, "FoundationWall")
        XMLHelper.copy_element(new_wall, orig_wall, "SystemIdentifier")
        XMLHelper.copy_element(new_wall, orig_wall, "Type")
        XMLHelper.copy_element(new_wall, orig_wall, "Length")
        XMLHelper.copy_element(new_wall, orig_wall, "Height")
        XMLHelper.copy_element(new_wall, orig_wall, "Area")
        XMLHelper.copy_element(new_wall, orig_wall, "BelowGradeDepth")
        XMLHelper.copy_element(new_wall, orig_wall, "AdjacentToFoundation")
        XMLHelper.copy_element(new_wall, orig_wall, "AdjacentTo")
        insulation = XMLHelper.set_element(new_wall, "Insulation")
        XMLHelper.copy_element(insulation, orig_wall, "Insulation/SystemIdentifier")
        XMLHelper.set_element(insulation, "InsulationGrade", 1)
        XMLHelper.set_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
        
      end
    end
    
  end

  def self.set_slabs_reference(building, climate_zone)
    '''
    Table 4.2.2(1) - Foundations
    Type: same as Rated Home
    Gross Area: same as Rated Home
    U-Factor / R-value: from Table 4.2.2(2)
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    # FIXME: Need to check for SlabOnGrade foundation type?
    
    rvalue, depth = get_reference_component_characteristics(climate_zone, "foundation")
    
    building.elements.each("BuildingDetails/Enclosure/Foundations/Foundation") do |foundation|

      orig_slabs = XMLHelper.delete_elements(foundation, "Slab")
      orig_slabs.each do |orig_slab|
      
        # Create new slab
        new_slab = XMLHelper.add_element(foundation, "Slab")
        XMLHelper.copy_element(new_slab, orig_slab, "SystemIdentifier")
        XMLHelper.copy_element(new_slab, orig_slab, "Area")
        XMLHelper.copy_element(new_slab, orig_slab, "Perimeter")
        XMLHelper.copy_element(new_slab, orig_slab, "ExposedPerimeter")
        XMLHelper.set_element(new_slab, "PerimeterInsulationDepth", depth)
        XMLHelper.copy_element(new_slab, orig_slab, "OnGradeExposedPerimeter")
        XMLHelper.copy_element(new_slab, orig_slab, "DepthBelowGrade")
        XMLHelper.set_element(new_slab, "FloorCovering", "carpet")
        insulation = XMLHelper.set_element(new_slab, "PerimeterInsulation")
        XMLHelper.copy_element(insulation, orig_slab, "PerimeterInsulation/SystemIdentifier")
        XMLHelper.set_element(insulation, "InsulationGrade", 1)
        XMLHelper.set_element(insulation, "AssemblyEffectiveRValue", rvalue)
        extension = XMLHelper.set_element(new_slab, "extension")
        XMLHelper.set_element(extension, "FloorCoveringFraction", 0.8)
        XMLHelper.set_element(extension, "FloorCoveringRValue", 2.0)
        
      end
    end
    
  end
  
  def self.set_rim_joists_reference(building)
    # FIXME
    enclosure = building.elements["BuildingDetails/Enclosure"]
    XMLHelper.delete_elements(enclosure, "RimJoists")
  end

  def self.set_walls_reference(building, climate_zone)
    '''
    Table 4.2.2(1) - Above-grade walls
    Type: wood frame
    Gross area: same as Rated Home
    U-Factor: from Table 4.2.2(2)
    Solar absorptance = 0.75
    Emittance = 0.90
    
    4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
    '''
    
    # FIXME: Need to check wall is between living space and outside/unconditioned space?
    
    ufactor = get_reference_component_characteristics(climate_zone, "frame_wall")
    
    walls = building.elements["BuildingDetails/Enclosure/Walls"]
    orig_walls = XMLHelper.delete_elements(walls, "Wall")
    
    orig_walls.each do |orig_wall|
    
      # Create new wall
      new_wall = XMLHelper.add_element(walls, "Wall")
      XMLHelper.copy_element(new_wall, orig_wall, "SystemIdentifier")
      XMLHelper.copy_element(new_wall, orig_wall, "AttachedToSpace")
      XMLHelper.copy_element(new_wall, orig_wall, "ExteriorAdjacentTo")
      XMLHelper.copy_element(new_wall, orig_wall, "InteriorAdjacentTo")
      XMLHelper.set_element(new_wall, "WallType/WoodStud")
      XMLHelper.copy_element(new_wall, orig_wall, "Area")
      insulation = XMLHelper.set_element(new_wall, "Insulation")
      XMLHelper.copy_element(insulation, orig_wall, "Insulation/SystemIdentifier")
      XMLHelper.set_element(insulation, "InsulationGrade", 1)
      XMLHelper.set_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      extension = XMLHelper.set_element(new_wall, "extension")
      XMLHelper.set_element(extension, "SolarAbsorptance", 0.75)
      XMLHelper.set_element(extension, "Emittance", 0.90)
      
    end
    
  end

  def self.set_windows_reference(building, cfa, climate_zone)
    '''
    Table 4.2.2(1) - Glazing
    Total area = 18% of CFA
    Orientation: equally distributed to four (4) cardinal compass orientations (N,E,S,&W)
    U-factor: from Table 4.2.2(2)
    SHGC: from Table 4.2.2(2)    
    Interior shade coefficient: Summer = 0.70; Winter = 0.85
    External shading: none
    
    For one- and two-family dwellings with conditioned basements and dwelling units in residential 
    buildings not over three stories in height above grade containing multiple dwelling units the following 
    formula shall be used to determine total window area:
    AG = 0.18 x CFA x FA x F
    where:
    AG = Total glazing area
    CFA = Total Conditioned Floor Area
    ANSI/RESNET 301-2014 17
    FA = (gross above-grade thermal boundary wall area) / (gross above-grade thermal boundary wall area + 
    0.5*gross below-grade thermal boundary wall area)
    F = 1- 0.44* (gross common wall Area) / (gross above-grade thermal boundary wall area + gross common 
    wall area)
    and where:
    Thermal boundary wall is any wall that separates Conditioned Space from Unconditioned Space, outdoor 
    environment or the surrounding soil.
    Above-grade thermal boundary wall is any portion of a thermal boundary wall not in contact with soil.
    Below-grade thermal boundary wall is any portion of a thermal boundary wall in soil contact
    Common wall is the total wall area of walls adjacent to another conditioned living unit, not including 
    foundation walls.
    
    4.3.7. Natural Ventilation. Natural ventilation shall be assumed in both the Reference and Rated Homes 
    during hours when natural ventilation will reduce annual cooling energy use.
    '''

    ufactor, shgc = get_reference_component_characteristics(climate_zone, "window")
    
    # Remove all windows
    windows = building.elements["BuildingDetails/Enclosure/Windows"]
    XMLHelper.delete_elements(windows, "Window")
    
    for orientation, azimuth in {"north"=>0,"south"=>180,"east"=>90,"west"=>180}
    
      # Create new window
      new_window = XMLHelper.add_element(windows, "Window")
      sys_id = XMLHelper.set_element(new_window, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Window_#{orientation}")
      XMLHelper.set_element(new_window, "Area", 0.18 * 0.25 * cfa) # FIXME: Adjustment for conditioned basements
      XMLHelper.set_element(new_window, "Azimuth", azimuth)
      XMLHelper.set_element(new_window, "Orientation", orientation)
      XMLHelper.set_element(new_window, "UFactor", ufactor)
      XMLHelper.set_element(new_window, "SHGC", shgc)
      XMLHelper.set_element(new_window, "NFRCCertified", true)
      XMLHelper.set_element(new_window, "ExteriorShading", "none")
      XMLHelper.set_element(new_window, "Operable", true)
      extension = XMLHelper.set_element(new_window, "extension")
      XMLHelper.set_element(extension, "InteriorShadingFactorSummer", 0.70)
      XMLHelper.set_element(extension, "InteriorShadingFactorWinter", 0.85)
      
    end

  end

  def self.set_skylights_reference(building)
    '''
    Table 4.2.2(1) - Skylights
    None
    '''
    
    enclosure = building.elements["BuildingDetails/Enclosure"]
    XMLHelper.delete_elements(enclosure, "Skylights")
    
  end

  def self.set_doors_reference(building, climate_zone)
    '''
    Table 4.2.2(1) - Doors
    Area: 40 ft2
    U-factor: same as fenestration from Table 4.2.2(2)
    Orientation: North
    '''
    
    ufactor, shgc = get_reference_component_characteristics(climate_zone, "door")
    
    # Remove all doors
    doors = building.elements["BuildingDetails/Enclosure/Doors"]
    XMLHelper.delete_elements(doors, "Door")
    
    # Create new door
    new_door = XMLHelper.add_element(doors, "Door")
    sys_id = XMLHelper.set_element(new_door, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Door")
    XMLHelper.set_element(new_door, "Area", 40)
    XMLHelper.set_element(new_door, "Azimuth", 0)
    XMLHelper.set_element(new_door, "Orientation", "north")
    XMLHelper.set_element(new_door, "DoorType", "exterior")
    XMLHelper.set_element(new_door, "RValue", 1.0/ufactor)
    
  end
  
  def self.set_hvac_plants_reference(building)
    '''
    Table 4.2.2(1) - Heating systems
    Fuel type: same as Rated Home
    Efficiencies:
    - Electric: air source heat pump in accordance with Table 4.2.2(1a)
    - Non-electric furnaces: natural gas furnace in accordance with Table 4.2.2(1a)
    - Non-electric boilers: natural gas boiler in accordance with Table 4.2.2(1a)
    - Capacity: sized in accordance with Section 4.3.3.1.
    
    Table 4.2.2(1) - Cooling systems
    Fuel type: Electric
    Efficiency: in accordance with Table 4.2.2(1a)
    Capacity: sized in accordance with Section 4.3.3.1.
    
    (i) For a Rated Home with multiple heating, cooling, or water heating systems using different fuel types, 
    the applicable system capacities and fuel types shall be weighted in accordance with the loads 
    distribution (as calculated by accepted engineering practice for that equipment and fuel type) of the 
    subject multiple systems.
    
    (k) For a Rated Home without a heating system, a gas heating system with the efficiency provided in Table 
    4.2.2(1a) shall be assumed for both the HERS Reference Home and Rated Home. For a Rated home that has 
    no access to natural gas or fossil fuel delivery, an air-source heat pump with the efficiency provided 
    in Table 4.2.2(1a) shall be assumed for both the HERS Reference Home and Rated Home.
    
    (m) For a Rated Home without a cooling system, an electric air conditioner with the efficiency provided in 
    Table 4.2.2(1a) shall be assumed for both the HERS Reference Home and the Rated Home.
    '''
    
    hvac = building.elements["BuildingDetails/Systems/HVAC"]
    hvac_plant = hvac.elements["HVACPlant"]
    heating_systems = []
    hvac_plant.elements.each("HeatingSystem") do |sys|
      heating_systems << sys
    end
    cooling_systems = []
    hvac_plant.elements.each("CoolingSystem") do |sys|
      cooling_systems << sys
    end
    heat_pumps = []
    hvac_plant.elements.each("HeatPump") do |sys|
      heat_pumps << sys
    end
    
    if (heating_systems.size + heat_pumps.size) > 1 or (cooling_systems.size + heat_pumps.size) > 1
      puts "too many hvac systems"
      return false # FIXME
    end
    
    # Init
    has_boiler = false
    fuel_type = nil
    has_fuel_hookup_or_delivery = true # FIXME
    
    # Obtain input values
    heating_systems.each do |sys|
      fuel_type = XMLHelper.get_value(sys, "HeatingSystemFuel")
      has_boiler = XMLHelper.has_element(sys, "HeatingSystemType/Boiler")
    end
    
    hvac_plant = XMLHelper.reset_element(hvac, "HVACPlant")
    
    # FIXME: Add PrimarySystems
    
    if fuel_type == 'eletricity' or not has_fuel_hookup_or_delivery
    
      # 7.7 HSPF air source heat pump
      heat_pump = XMLHelper.add_element(hvac_plant, "HeatPump")
      sys_id = XMLHelper.set_element(heat_pump, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      XMLHelper.set_element(heat_pump, "HeatPumpType", "air-to-air")
      cool_eff = XMLHelper.set_element(heat_pump, "AnnualCoolEfficiency")
      XMLHelper.set_element(cool_eff, "Units", "SEER")
      XMLHelper.set_element(cool_eff, "Value", 13.0)
      heat_eff = XMLHelper.set_element(heat_pump, "AnnualHeatEfficiency")
      XMLHelper.set_element(heat_eff, "Units", "HSPF")
      XMLHelper.set_element(heat_eff, "Value", 7.7)
      
    else
    
      if has_boiler
      
        # 80% AFUE gas boiler
        heat_sys = XMLHelper.add_element(hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.set_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.set_element(heat_sys, "HeatingSystemType")
        boiler = XMLHelper.set_element(sys_type, "Boiler")
        XMLHelper.set_element(boiler, "BoilerType", "hot water")
        XMLHelper.set_element(heat_sys, "HeatingSystemFuel", "electricity")
        heat_eff = XMLHelper.set_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.set_element(heat_eff, "Units", "AFUE")
        XMLHelper.set_element(heat_eff, "Value", 0.80)
        
      else
      
        # 78% AFUE gas furnace
        heat_sys = XMLHelper.add_element(hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.set_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.set_element(heat_sys, "HeatingSystemType")
        furnace = XMLHelper.set_element(sys_type, "Furnace")
        XMLHelper.set_element(heat_sys, "HeatingSystemFuel", "electricity")
        heat_eff = XMLHelper.set_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.set_element(heat_eff, "Units", "AFUE")
        XMLHelper.set_element(heat_eff, "Value", 0.78)
        
      end
      
      # 13 SEER electric air conditioner
      cool_sys = XMLHelper.add_element(hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.set_element(cool_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      XMLHelper.set_element(cool_sys, "CoolingSystemType", "central air conditioning")
      XMLHelper.set_element(cool_sys, "CoolingSystemFuel", "electricity")
      cool_eff = XMLHelper.set_element(cool_sys, "AnnualCoolingEfficiency")
      XMLHelper.set_element(cool_eff, "Units", "SEER")
      XMLHelper.set_element(cool_eff, "Value", 13.0)
      
    end
    
  end
  
  def self.set_hvac_controls_reference(building)
    '''
    Table 303.4.1(1) - Thermostat
    Type: manual
    Temperature setpoints: heating temperature set point = 68 F
    Temperature setpoints: cooling temperature set point = 78 F
    '''
    
    hvac = building.elements["BuildingDetails/Systems/HVAC"]
    hvac_control = XMLHelper.reset_element(hvac, "HVACControl")
    sys_id = XMLHelper.set_element(hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.set_element(hvac_control, "SetpointTempHeatingSeason", 68)
    XMLHelper.set_element(hvac_control, "SetpointTempCoolingSeason", 78)

  end
  
  def self.set_hvac_distributions_reference(building)
    hvac = building.elements["BuildingDetails/Systems/HVAC"]
    hvac_distribution = XMLHelper.reset_element(hvac, "HVACDistribution")
    sys_id = XMLHelper.set_element(hvac_distribution, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACDistribution")
    # FIXME
  end
  
  def self.set_mechanical_ventilation_reference(building)
    '''
    Table 4.2.2(1) - Whole-House Mechanical ventilation
    None, except where a mechanical ventilation system is specified by the Rated Home, in which case:
    Where Rated Home has supply-only or exhaust-only Whole-House Ventilation System:
    0.35*fanCFM*8.76 kWh/y
    Where Rated Home has balanced Whole-House Ventilation System without energy recovery:
    0.70* fanCFM*8.76 kWh/y
    Where Rated Home has balanced Whole-House Ventilation System with energy recovery:
    1.00*fanCFM*8.76 kWh/y
    And where fanCFM is calculated in accordance with Section 4.1.2 ASHRAE Standard 62.2-2013 for a 
    continuous Whole-House Ventilation System.
    '''
    
    systems = building.elements["BuildingDetails/Systems"]
    mech_vent = XMLHelper.reset_element(systems, "MechanicalVentilation")
    # FIXME
    
  end
  
  def self.set_combustion_ventilation_reference(building)
    systems = building.elements["BuildingDetails/Systems"]
    XMLHelper.delete_elements(systems, "CombustionVentilation")
  end
  
  def self.set_water_heating_reference(building)
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    
    Table 4.2.2(1) - Service water heating systems
    Fuel type: same as Rated Home
    Efficiency
    - Electric: EF = 0.97 - (0.00132 * store gal)
    - Fossil fuel: EF = 0.67 - (0.0019 * store gal)
    Tank temperature: 125 F
    
    (n) For a Rated Home with a non-storage type water heater, a 40-gallon storage-type water heater of the 
    same fuel as the proposed water heater shall be assumed for the HERS Reference Home. For a Rated 
    Home without a proposed water heater, a 40-gallon storage-type water heater of the same fuel as the 
    predominant fuel type used for the heating system(s) shall be assumed for both the Rated and HERS 
    Reference Homes. In both cases the Energy Factor of the water heater shall be as prescribed for water 
    heaters by CFR 430.32(d), published in the Federal Register/Volume 66, No. 11, Wednesday, January 17, 
    2001 for water heaters manufactured after January 20, 2004.
    '''
    systems = building.elements["BuildingDetails/Systems"]
    water_heating = XMLHelper.reset_element(systems, "WaterHeating")
    
    water_heaters = []
    water_heating.elements.each("WaterHeatingSystem") do |sys|
      water_heaters << sys
    end
    
    if water_heaters.size > 1
      puts "too many water heating systems"
      return false # FIXME
    end
    
    # Init
    wh_type = nil
    wh_tank_vol = nil
    wh_fuel_type = nil

    # Obtain input values
    water_heaters.each do |sys|
      wh_type = XMLHelper.get_value(sys, "WaterHeaterType")
      wh_tank_vol = XMLHelper.get_value(sys, "TankVolume").to_f
      wh_fuel_type = XMLHelper.get_value(sys, "FuelType")
    end

    # 301 Logic
    if wh_type.nil?
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
      wh_fuel_type = XMLHelper.get_value(building, "BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
    elsif wh_type == 'instantaneous water heater'
      wh_type = 'storage water heater'
      wh_tank_vol = 40.0
    end
    
    wh_ef = nil
    if wh_fuel_type == 'electricity'
      wh_ef = 0.97 - (0.00132 * wh_tank_vol)
    else
      wh_ef = 0.67 - (0.0019 * wh_tank_vol)
    end
    
    # New water heater
    wh_sys = XMLHelper.set_element(water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.set_element(wh_sys, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
    XMLHelper.set_element(wh_sys, "FuelType", wh_fuel_type)
    XMLHelper.set_element(wh_sys, "WaterHeaterType", wh_type)
    XMLHelper.set_element(wh_sys, "TankVolume", wh_tank_vol)
    XMLHelper.set_element(wh_sys, "EnergyFactor", wh_ef)
    XMLHelper.set_element(wh_sys, "HotWaterTemperature", 125)
    
  end
  
  def self.set_hot_water_distribution_reference(building, nbeds)
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refWgpd = 9.8*Nbr^0.43 
                        = reference climate-normalized daily hot water waste due to distribution system 
                          losses in Reference Home (in gallons per day)
    '''
    
    water_heating = building.elements["BuildingDetails/Systems/WaterHeating"]
    
    dist_gpd = 9.8 * (nbeds**0.43)
    
    # New hot water distribution
    hw_dist = XMLHelper.reset_element(water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.set_element(hw_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    extension = XMLHelper.set_element(hw_dist, "extension")
    XMLHelper.set_element(extension, "MixedWaterGPD", dist_gpd)
    
  end
  
  def self.set_water_fixture_reference(building, nbeds)
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refFgpd = 14.6 + 10.0*Nbr
                        = reference climate-normalized daily fixture water use in Reference Home (in 
                          gallons per day)
    '''
    
    water_heating = building.elements["BuildingDetails/Systems/WaterHeating"]
    
    fixture_gpd = 14.6 + 10.0 * nbeds
    
    # New water fixture
    fixture = XMLHelper.reset_element(water_heating, "WaterFixture")
    sys_id = XMLHelper.set_element(fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
    XMLHelper.set_element(fixture, "WaterFixtureType", "other")
    extension = XMLHelper.set_element(fixture, "extension")
    XMLHelper.set_element(extension, "MixedWaterGPD", fixture_gpd)
    
  end
  
  def self.set_solar_thermal_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/Systems/SolarThermal")
  end
  
  def self.set_photovoltaics_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/Systems/Photovoltaics")
  end
  
  def self.set_wind_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/Systems/Wind")
  end
  
  def self.set_clothes_washer_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refCWgpd = reference clothes washer gallons per day
                         = (4.52*(164+46.5*Nbr))*((3*2.08+1.59)/(2.874*2.08+1.59))/365
    '''
  
    clothes_washer_kwh = 38.0 + 0.0 * cfa + 10.0 * nbeds
    clothes_washer_sens = 0.3 * 0.9
    clothes_washer_lat = 0.3 * 0.1
    clothes_washer_gpd = (4.52 * (164.0 + 46.5 * nbeds)) * ((3.0 * 2.08 + 1.59)/(2.874 * 2.08 + 1.59)) / 365.0
    
    appliances = building.elements["BuildingDetails/Appliances"]
    clothes_washer = XMLHelper.reset_element(appliances, "ClothesWasher")
    sys_id = XMLHelper.set_element(clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesWasher")
    extension = XMLHelper.set_element(clothes_washer, "extension")
    XMLHelper.set_element(extension, "AnnualkWh", clothes_washer_kwh)
    XMLHelper.set_element(extension, "FracSensible", clothes_washer_sens)
    XMLHelper.set_element(extension, "FracLatent", clothes_washer_lat)
    XMLHelper.set_element(extension, "HotWaterGPD", clothes_washer_gpd)
  end

  def self.set_clothes_dryer_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
  
    dryer_fuel = get_fuel_type(building, ["BuildingDetails/Appliances/ClothesDryer"])
    clothes_dryer_kwh = 524.0 + 0.0 * cfa + 149.0 * nbeds # default to electric
    clothes_dryer_therm = 0.0 # default to electric
    if dryer_fuel != 'electricity'
      clothes_dryer_kwh = 41.0 + 0.0 * cfa + 11.7 * nbeds
      clothes_dryer_therm = 18.8 + 0.0 * cfa + 5.3 * nbeds
    end
    clothes_dryer_sens = 0.15 * 0.9
    clothes_dryer_lat = 0.15 * 0.1
    
    appliances = building.elements["BuildingDetails/Appliances"]
    clothes_dryer = XMLHelper.reset_element(appliances, "ClothesDryer")
    sys_id = XMLHelper.set_element(clothes_dryer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesDryer")
    XMLHelper.set_element(clothes_dryer, "FuelType", dryer_fuel)
    extension = XMLHelper.set_element(clothes_dryer, "extension")
    XMLHelper.set_element(extension, "AnnualkWh", clothes_dryer_kwh)
    XMLHelper.set_element(extension, "AnnualTherm", clothes_dryer_therm)
    XMLHelper.set_element(extension, "FracSensible", clothes_dryer_sens)
    XMLHelper.set_element(extension, "FracLatent", clothes_dryer_lat)
    
  end

  def self.set_dishwasher_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes

    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refDWgpd = reference dishwasher gallons per day
                         = ((88.4+34.9*Nbr)*8.16)/365
    '''
  
    dishwasher_kwh = 78.0 + 0.0 * cfa + 31.0 * nbeds
    dishwasher_sens = 0.6 * 0.5
    dishwasher_lat = 0.6 * 0.5
    dishwasher_gpd = ((88.4 + 34.9 * nbeds) * 8.16) / 365.0
    
    appliances = building.elements["BuildingDetails/Appliances"]
    dishwasher = XMLHelper.reset_element(appliances, "Dishwasher")
    sys_id = XMLHelper.set_element(dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Dishwasher")
    extension = XMLHelper.set_element(dishwasher, "extension")
    XMLHelper.set_element(extension, "AnnualkWh", dishwasher_kwh)
    XMLHelper.set_element(extension, "FracSensible", dishwasher_sens)
    XMLHelper.set_element(extension, "FracLatent", dishwasher_lat)
    XMLHelper.set_element(extension, "HotWaterGPD", dishwasher_gpd)
    
  end

  def self.set_refrigerator_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
  
    refrigerator_kwh = 637.0 + 0.0 * cfa + 18.0 * nbeds

    appliances = building.elements["BuildingDetails/Appliances"]
    fridge = XMLHelper.reset_element(appliances, "Refrigerator")
    sys_id = XMLHelper.set_element(fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    extension = XMLHelper.set_element(fridge, "extension")
    XMLHelper.set_element(extension, "AnnualkWh", refrigerator_kwh)
    
  end

  def self.set_freezer_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/Appliances/Freezer")
  end
  
  def self.set_dehumidifier_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/Appliances/Dehumidifier")
  end

  def self.set_cooking_range_oven_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
    
    cooking_fuel = get_fuel_type(building, ["BuildingDetails/Appliances/CookingRange","BuildingDetails/Appliances/Oven"])
    cooking_range_kwh = 331.0 + 0.0 * cfa + 39.0 * nbeds # default to electric
    cooking_range_therm = 0.0 # default to electric
    cooking_range_sens = 0.8 * 0.9 # default to electric
    cooking_range_lat = 0.8 * 0.1 # default to electric
    if cooking_fuel != 'electricity'
      cooking_range_kwh = 22.6 + 0.0 * cfa + 2.7 * nbeds
      cooking_range_therm = 22.6 + 0.0 * cfa + 2.7 * nbeds
      cooking_range_sens = 0.8 * 0.8
      cooking_range_lat = 0.8 * 0.2
    end
    
    appliances = building.elements["BuildingDetails/Appliances"]
    cooking_range = XMLHelper.reset_element(appliances, "CookingRange")
    sys_id = XMLHelper.set_element(cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CookingRange")
    XMLHelper.set_element(cooking_range, "FuelType", cooking_fuel)
    extension = XMLHelper.set_element(cooking_range, "extension")
    XMLHelper.set_element(extension, "AnnualkWh", cooking_range_kwh)
    XMLHelper.set_element(extension, "AnnualTherm", cooking_range_therm)
    XMLHelper.set_element(extension, "FracSensible", cooking_range_sens)
    XMLHelper.set_element(extension, "FracLatent", cooking_range_lat)
    
    XMLHelper.delete_elements(appliances, "Oven")
    
  end

  def self.set_lighting_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    4.2.2.5.1.3. Garage Lighting. Where the Rated Home includes an enclosed garage, 100 kWh/y shall be added
    to the energy use of the Reference Home to account for garage lighting.
    '''
    
    building_details = building.elements["BuildingDetails"]
    lighting = XMLHelper.reset_element(building_details, "Lighting")
    
    # Interior lighting
    interior_lighting_kwh = 455.0 + 0.80 * cfa + 0.0 * nbeds
    XMLHelper.set_element(lighting, "extension/AnnualInteriorkWh", interior_lighting_kwh)
    
    # Exterior lighting
    exterior_lighting_kwh = 100.0 + 0.05 * cfa + 0.0 * nbeds
    XMLHelper.set_element(lighting, "extension/AnnualExteriorkWh", exterior_lighting_kwh)
    
    # Garage lighting
    garage_lighting_kwh = 0.0
    if XMLHelper.get_value(building, "BuildingDetails/BuildingSummary/BuildingConstruction/GaragePresent") == "true"
      garage_lighting_kwh = 100.0
    end
    XMLHelper.set_element(lighting, "extension/AnnualGaragekWh", garage_lighting_kwh)
    
  end

  def self.set_ceiling_fans_reference(building)
    '''
    4.2.2.5.1.4. Ceiling Fans. Where ceiling fans are included in the Rated Home they shall also be included
    in the Reference Home in accordance with the provisions of Section 4.2.2.5.2.11
    
    4.2.2.5.2.11. Ceiling Fans. If ceiling fans are included in the Rated home, they shall also be included 
    in the Reference home. The number of Bedrooms plus one (Nbr+1) ceiling fans shall be assumed in both the
    Reference Home and the Rated Home. A daily ceiling fan operating schedule equal to 10.5 full-load hours 
    shall be assumed in both the Reference Home and the Rated Home during months with an average outdoor 
    temperature greater than 63 oF. The cooling thermostat (but not the heating thermostat) shall be set up 
    by 0.5 oF in both the Reference and Rated Home during these months.
    
    The Reference Home shall use number of Bedrooms plus one (Nbr+1) Standard Ceiling Fans of 42.6 watts 
    each. The Rated Home shall use the Labeled Ceiling Fan Standardized Watts (LCFSW), also multiplied by 
    number of Bedrooms plus one (Nbr+1) fans to obtain total ceiling fan wattage for the Rated Home. The 
    Rated Home LCFSW shall be calculated in accordance with Equation 4.2-10.
    '''
    
    # FIXME
    
  end

  def self.set_pools_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/Pools")
  end

  def self.set_misc_loads_reference(building, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
    
    building_details = building.elements["BuildingDetails"]
    misc_loads = XMLHelper.reset_element(building_details, "MiscLoads")
    
    # Residual MELs
    residual_mels_kwh = 0.0 + 0.91 * cfa + 0.0 * nbeds
    residual_mels = XMLHelper.add_element(misc_loads, "PlugLoad")
    sys_id = XMLHelper.set_element(residual_mels, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Residual_MELs")
    XMLHelper.set_element(residual_mels, "PlugLoadType", "other")
    residual_mels_load = XMLHelper.set_element(residual_mels, "Load")
    XMLHelper.set_element(residual_mels_load, "Units", "kWh/year")
    XMLHelper.set_element(residual_mels_load, "Value", residual_mels_kwh)
    # TODO: Sens/lat frac
    
    # Televisions
    televisions_kwh = 413.0 + 0.0 * cfa + 69.0 * nbeds
    television = XMLHelper.add_element(misc_loads, "PlugLoad")
    sys_id = XMLHelper.set_element(television, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Television")
    XMLHelper.set_element(television, "PlugLoadType", "TV other")
    television_load = XMLHelper.set_element(television, "Load")
    XMLHelper.set_element(television_load, "Units", "kWh/year")
    XMLHelper.set_element(television_load, "Value", televisions_kwh)
    
  end

  def self.set_health_and_safety_reference(building)
    XMLHelper.delete_elements(building, "BuildingDetails/HealthAndSafety")
  end

  def self.get_reference_component_characteristics(climate_zone, component_type)
    '''
    Table 4.2.2(2) - Component Heat Transfer Characteristics for HERS Reference Home
    '''
    if component_type == "window" or component_type == "door"
      # Fenestration and Opaque Door U-Factor
      # Glazed Fene-stration Assembly SHGC
      if ["1A", "1B", "1C"].include? climate_zone
        return 1.2, 0.40
      elsif ["2A", "2B", "2C"].include? climate_zone
        return 0.75, 0.40
      elsif ["3A", "3B", "3C"].include? climate_zone
        return 0.65, 0.40
      elsif ["4A", "4B"].include? climate_zone
        return 0.40, 0.40
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"]
        return 0.35, 0.40
      else
        return nil
      end
    elsif component_type == "frame_wall"
      # Frame Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B"].include? climate_zone
        return 0.082
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C"].include? climate_zone
        return 0.060
      elsif ["7", "8"].include? climate_zone
        return 0.057
      else
        return nil
      end
    elsif component_type == "basement_wall"
      # Basement Wall U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? climate_zone
        return 0.360
      elsif ["4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? climate_zone
        return 0.059
      else
        return nil
      end
    elsif component_type == "floor"
      # Floor Over Uncond-itioned Space U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C"].include? climate_zone
        return 0.064
      elsif ["3A", "3B", "3C", "4A", "4B"].include? climate_zone
        return 0.047
      elsif ["4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"].include? climate_zone
        return 0.033
      else
        return nil
      end
    elsif component_type == "ceiling"
      # Ceiling U-Factor
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? climate_zone
        return 0.035
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? climate_zone
        return 0.030
      elsif ["6A", "6B", "6C", "7", "8"].include? climate_zone
        return 0.026
      else
        return nil
      end
    elsif component_type == "foundation"
      # Slab-on-Grade R-Value & Depth (ft)
      if ["1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C"].include? climate_zone
        return 0.0, nil
      elsif ["4A", "4B", "4C", "5A", "5B", "5C"].include? climate_zone
        return 10.0, 2.0
      elsif ["6A", "6B", "6C", "7", "8"].include? climate_zone
        return 10.0, 4.0
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def self.get_fuel_type(building, elements)
    fuels = []
    elements.each do |element|
      building.elements.each(element) do |el|
        fuels << XMLHelper.get_value(el, "FuelType")
      end
    end
    fuels.uniq!
    if fuels.size != 1
      return nil # FIXME
    end
    return fuels[0]
  end
  
end
  
class XMLHelper

  # Creates the child element with 'element_name' if it doesn't already exist. Sets
  # its value. Returns the child element.
  def self.set_element(parent, element_name, value=nil)
    element = nil
    element_names = element_name.split("/")
    element_names.each_with_index do |name,idx|
      element = parent.elements[name]
      if element.nil?
        # Add remainder of element_names
        return XMLHelper.add_element(parent, element_names[idx, element_names.size-idx].join("/"), value)
      end
      parent = element
    end
    if not value.nil?
      element.text = value
    end
    return element
  end
  
  # Adds the child element with 'element_name' and sets its value. Returns the
  # child element.
  def self.add_element(parent, element_name, value=nil)
    new_element = nil
    element_name.split("/").each do |name|
      new_element = REXML::Element.new(name)
      parent << new_element
      parent = new_element
    end
    if not value.nil?
      new_element.text = value
    end
    return new_element
  end
  
  # Deletes the child element and then adds it. Returns the child element.
  def self.reset_element(parent, element_name)
    XMLHelper.delete_elements(parent, element_name)
    # FIXME: Add code to preserve position where element is added
    return XMLHelper.add_element(parent, element_name)
  end
  
  # Deletes all child elements with element_name. Returns the deleted elements.
  def self.delete_elements(parent, element_name)
    elements = parent.elements.delete_all(element_name)
    return elements
  end
  
  # Returns the value of 'element_name' in the parent element or nil.
  def self.get_value(parent, element_name)
    val = parent.elements[element_name]
    if val.nil?
      return val
    end
    return val.text
  end
  
  def self.has_element(parent, element_name)
    element_name.split("/").each do |name|
      element = parent.elements[name]
      return false if element.nil?
      parent = element
    end
    return true
  end
  
  def self.copy_element(dest, src, element_name)
    if not src.elements[element_name].nil?
      dest << src.elements[element_name]
    end
  end
  
  # Returns the attribute added
  def self.add_attribute(element, attr_name, attr_val)
    return element.add_attribute(attr_name, attr_val)
  end
  
end
