require 'rexml/document'
require 'rexml/xpath'
require "#{File.dirname(__FILE__)}/constants"

class EnergyRatingIndex301Ruleset

  def self.apply_ruleset(hpxml_doc, calc_type)
  
    errors = []
    
    # Update XML type
    header = hpxml_doc.elements["//XMLTransactionHeaderInformation"]
    if header.elements["XMLType"].nil?
      header.elements["XMLType"].text = calc_type
    else
      header.elements["XMLType"].text += calc_type
    end
    
    # Get the building element
    building = []
    hpxml_doc.elements.each("//Building") do |bldg|
      building << bldg
    end
    if building.size == 0
      errors << "Building not found."
      return errors, nil
    elsif building.size > 1
      errors << "Multiple buildings found."
      return errors, nil
    end
    building = building[0]
  
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
    # FIXME: Add code to preserve building position above Project, Utility, etc.
    orig_details = XMLHelper.delete_element(building, "BuildingDetails")
    new_details = XMLHelper.add_element(building, "BuildingDetails")
    
    # Building Summary
    new_summary = XMLHelper.add_element(new_details, "BuildingSummary")
    set_summary_reference(new_summary, orig_details)
    
    # Climate And Risk Zones
    XMLHelper.copy_element(new_details, orig_details, "ClimateandRiskZones")
    
    # Zones
    XMLHelper.copy_element(new_details, orig_details, "Zones")
    
    # Enclosure
    new_enclosure = XMLHelper.add_element(new_details, "Enclosure")
    set_enclosure_air_infiltration_reference(new_enclosure)
    set_enclosure_attics_roofs_reference(new_enclosure, orig_details, climate_zone)
    set_enclosure_foundations_reference(new_enclosure, orig_details, climate_zone)
    set_enclosure_rim_joists_reference(new_enclosure)
    set_enclosure_walls_reference(new_enclosure, orig_details, climate_zone)
    set_enclosure_windows_reference(new_enclosure, cfa, climate_zone)
    set_enclosure_skylights_reference(new_enclosure)
    set_enclosure_doors_reference(new_enclosure, climate_zone)
    
    # Systems
    new_systems = XMLHelper.add_element(new_details, "Systems")
    set_systems_hvac_reference(new_systems, orig_details)
    set_systems_mechanical_ventilation_reference(new_systems)
    set_systems_water_heating_reference(new_systems, orig_details, nbeds)
    
    # Appliances
    new_appliances = XMLHelper.add_element(new_details, "Appliances")
    set_appliances_clothes_washer_reference(new_appliances, cfa, nbeds)
    set_appliances_clothes_dryer_reference(new_appliances, orig_details, cfa, nbeds)
    set_appliances_dishwasher_reference(new_appliances, cfa, nbeds)
    set_appliances_refrigerator_reference(new_appliances, cfa, nbeds)
    set_appliances_cooking_range_oven_reference(new_appliances, orig_details, cfa, nbeds)
    
    # Lighting
    new_lighting = XMLHelper.add_element(new_details, "Lighting")
    set_lighting_reference(new_lighting, orig_details, cfa, nbeds)
    set_lighting_ceiling_fans_reference(new_lighting)
    
    # Misc Loads
    new_misc_loads = XMLHelper.add_element(new_details, "MiscLoads")
    set_misc_loads_reference(new_misc_loads, cfa, nbeds)
    
  end
  
  def self.apply_rated_home_ruleset(building)
  end
  
  def self.apply_index_adjustment_design_ruleset(building)
  
  end
  
  def self.set_summary_reference(new_summary, orig_details)
    new_occupancy = XMLHelper.add_element(new_summary, "BuildingOccupancy")
    orig_occupancy = orig_details.elements["BuildingSummary/BuildingOccupancy"]
    XMLHelper.copy_element(new_occupancy, orig_occupancy, "NumberofResidents")
    
    new_construction = XMLHelper.add_element(new_summary, "BuildingConstruction")
    orig_construction = orig_details.elements["BuildingSummary/BuildingConstruction"]
    XMLHelper.copy_element(new_construction, orig_construction, "ResidentialFacilityType")
    XMLHelper.copy_element(new_construction, orig_construction, "BuildingHeight")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloors")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofConditionedFloorsFloorsAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "AverageCeilingHeight")
    XMLHelper.copy_element(new_construction, orig_construction, "FloorToFloorHeight ")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBedrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofBathrooms")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "FinishedFloorArea")
    XMLHelper.copy_element(new_construction, orig_construction, "NumberofStoriesAboveGrade")
    XMLHelper.copy_element(new_construction, orig_construction, "BuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "ConditionedBuildingVolume")
    XMLHelper.copy_element(new_construction, orig_construction, "FoundationType")
    XMLHelper.copy_element(new_construction, orig_construction, "AtticType")
    XMLHelper.copy_element(new_construction, orig_construction, "GaragePresent")
    XMLHelper.copy_element(new_construction, orig_construction, "GarageLocation")
    XMLHelper.copy_element(new_construction, orig_construction, "SpaceAboveGarage")
  end
  
  def self.set_enclosure_air_infiltration_reference(new_enclosure)
    
    new_infil = XMLHelper.add_element(new_enclosure, "AirInfiltration")
    extension = XMLHelper.add_element(new_infil, "extension")
    
    '''
    Table 4.2.2(1) - Air exchange rate
    Specific Leakage Area (SLA) = 0.00036 assuming no energy recovery and with energy loads calculated in 
    quadrature
    '''
    XMLHelper.add_element(extension, "BuildingSpecificLeakageArea", 0.00036)
    
    '''
    Table 4.2.2(1) - Attics
    Type: vented with aperture = 1ft2 per 300 ft2 ceiling area

    Table 4.2.2(1) - Crawlspaces
    Type: vented with net free vent aperture = 1ft2 per 150 ft2 of crawlspace floor area.
    U-factor: from Table 4.2.2(2) for floors over unconditioned spaces or outdoor environment.
    '''
    # FIXME: Only set if the building has an attic or crawlspace
    # FIXME: Use AirInfiltration extension or Attic/Foundation extensions?
    XMLHelper.add_element(extension, "AtticSpecificLeakageArea", 1.0/300.0)
    XMLHelper.add_element(extension, "CrawlspaceSpecificLeakageArea", 1.0/150.0)

  end
  
  def self.set_enclosure_attics_roofs_reference(new_enclosure, orig_details, climate_zone)
  
    attic_roof = XMLHelper.add_element(new_enclosure, "AtticAndRoof")
    
    '''
    Table 4.2.2(1) - Roofs
    Type: composition shingle on wood sheathing
    Gross area: same as Rated Home
    Solar absorptance = 0.75
    Emittance = 0.90
    '''
    
    new_roofs = XMLHelper.add_element(attic_roof, "Roofs")
    orig_details.elements.each("Enclosure/AtticAndRoof/Roofs/Roof") do |orig_roof|
      # Create new roof
      new_roof = XMLHelper.add_element(new_roofs, "Roof")
      XMLHelper.copy_element(new_roof, orig_roof, "SystemIdentifier")
      XMLHelper.copy_element(new_roof, orig_roof, "AttachedToSpace")
      XMLHelper.add_element(new_roof, "RoofType", "shingles")
      XMLHelper.add_element(new_roof, "DeckType", "wood")
      XMLHelper.copy_element(new_roof, orig_roof, "Pitch")
      XMLHelper.copy_element(new_roof, orig_roof, "RoofArea")
      XMLHelper.add_element(new_roof, "RadiantBarrier", false)
      extension = XMLHelper.add_element(new_roof, "extension")
      XMLHelper.add_element(extension, "SolarAbsorptance", 0.75)
      XMLHelper.add_element(extension, "Emittance", 0.90)
    end
    
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
    
    new_attics = XMLHelper.add_element(attic_roof, "Attics")
    orig_details.elements.each("Enclosure/AtticAndRoof/Attics/Attic") do |orig_attic|
      # Create new attic
      new_attic = XMLHelper.add_element(new_attics, "Attic")
      XMLHelper.copy_element(new_attic, orig_attic, "SystemIdentifier")
      XMLHelper.copy_element(new_attic, orig_attic, "AttachedToSpace")
      XMLHelper.copy_element(new_attic, orig_attic, "AttachedToRoof")
      XMLHelper.copy_element(new_attic, orig_attic, "ExteriorAdjacentTo")
      XMLHelper.copy_element(new_attic, orig_attic, "InteriorAdjacentTo")
      XMLHelper.copy_element(new_attic, orig_attic, "AtticKneeWall")
      XMLHelper.add_element(new_attic, "AtticType", "vented attic")
      insulation = XMLHelper.add_element(new_attic, "AtticFloorInsulation")
      XMLHelper.copy_element(insulation, orig_attic, "AtticFloorInsulation/SystemIdentifier")
      XMLHelper.add_element(insulation, "InsulationGrade", 1)
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      XMLHelper.copy_element(new_attic, orig_attic, "Area")
    end
    
  end
  
  def self.set_enclosure_foundations_reference(new_enclosure, orig_details, climate_zone)
    
    new_foundations = XMLHelper.add_element(new_enclosure, "Foundations")
    
    floor_ufactor = get_reference_component_characteristics(climate_zone, "floor")
    wall_ufactor = get_reference_component_characteristics(climate_zone, "basement_wall")
    slab_rvalue, slab_depth = get_reference_component_characteristics(climate_zone, "foundation")
          
    orig_details.elements.each("Enclosure/Foundations/Foundation") do |orig_foundation|
    
      new_foundation = XMLHelper.add_element(new_foundations, "Foundation")
      XMLHelper.copy_element(new_foundation, orig_foundation, "SystemIdentifier")
      XMLHelper.copy_element(new_foundation, orig_foundation, "AttachedToSpace")
      XMLHelper.copy_element(new_foundation, orig_foundation, "FoundationType")
      XMLHelper.copy_element(new_foundation, orig_foundation, "ThermalBoundary")
        
      '''
      Table 4.2.2(1) - Floors over unconditioned spaces or outdoor environment
      Type: wood frame
      Gross area: same as Rated Home
      U-Factor: from Table 4.2.2(2)
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      
      # FIXME: Need to check the floor is over unconditioned space or outdoors?
      
      orig_foundation.elements.each("FrameFloor") do |orig_floor|
        # Create new floor
        new_floor = XMLHelper.add_element(new_foundation, "FrameFloor")
        XMLHelper.copy_element(new_floor, orig_floor, "SystemIdentifier")
        XMLHelper.copy_element(new_floor, orig_floor, "Area")
        insulation = XMLHelper.add_element(new_floor, "Insulation")
        XMLHelper.copy_element(insulation, orig_floor, "Insulation/SystemIdentifier")
        XMLHelper.add_element(insulation, "InsulationGrade", 1)
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/floor_ufactor)
      end
  
      '''
      Table 4.2.2(1) - Conditioned basement walls
      Type: same as Rated Home
      Gross area: same as Rated Home
      U-Factor: from Table 4.2.2(2) with the insulation layer on the interior side of walls
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      
      # FIXME: Need to check if the foundation wall is adjacent to living space?
    
      orig_foundation.elements.each("FoundationWall") do |orig_wall|
        # Create new wall
        new_wall = XMLHelper.add_element(new_foundation, "FoundationWall")
        XMLHelper.copy_element(new_wall, orig_wall, "SystemIdentifier")
        XMLHelper.copy_element(new_wall, orig_wall, "Type")
        XMLHelper.copy_element(new_wall, orig_wall, "Length")
        XMLHelper.copy_element(new_wall, orig_wall, "Height")
        XMLHelper.copy_element(new_wall, orig_wall, "Area")
        XMLHelper.copy_element(new_wall, orig_wall, "BelowGradeDepth")
        XMLHelper.copy_element(new_wall, orig_wall, "AdjacentToFoundation")
        XMLHelper.copy_element(new_wall, orig_wall, "AdjacentTo")
        insulation = XMLHelper.add_element(new_wall, "Insulation")
        XMLHelper.copy_element(insulation, orig_wall, "Insulation/SystemIdentifier")
        XMLHelper.add_element(insulation, "InsulationGrade", 1)
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/wall_ufactor)
      end
  
      '''
      Table 4.2.2(1) - Foundations
      Type: same as Rated Home
      Gross Area: same as Rated Home
      U-Factor / R-value: from Table 4.2.2(2)
      
      4.2.2.2.1. The insulation of the HERS Reference Home enclosure elements shall be modeled as Grade I.
      '''
      # FIXME: Need to check for SlabOnGrade foundation type?
    
      orig_foundation.elements.each("Slab") do |orig_slab|
        # Create new slab
        new_slab = XMLHelper.add_element(new_foundation, "Slab")
        XMLHelper.copy_element(new_slab, orig_slab, "SystemIdentifier")
        XMLHelper.copy_element(new_slab, orig_slab, "Area")
        XMLHelper.copy_element(new_slab, orig_slab, "Perimeter")
        XMLHelper.copy_element(new_slab, orig_slab, "ExposedPerimeter")
        XMLHelper.add_element(new_slab, "PerimeterInsulationDepth", slab_depth)
        XMLHelper.copy_element(new_slab, orig_slab, "OnGradeExposedPerimeter")
        XMLHelper.copy_element(new_slab, orig_slab, "DepthBelowGrade")
        XMLHelper.add_element(new_slab, "FloorCovering", "carpet")
        insulation = XMLHelper.add_element(new_slab, "PerimeterInsulation")
        XMLHelper.copy_element(insulation, orig_slab, "PerimeterInsulation/SystemIdentifier")
        XMLHelper.add_element(insulation, "InsulationGrade", 1)
        XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", slab_rvalue)
        extension = XMLHelper.add_element(new_slab, "extension")
        XMLHelper.add_element(extension, "FloorCoveringFraction", 0.8)
        XMLHelper.add_element(extension, "FloorCoveringRValue", 2.0)
      end
      
    end
    
  end
  
  def self.set_enclosure_rim_joists_reference(new_enclosure)
    # FIXME
    #new_rim_joists = XMLHelper.add_element(new_enclosure, "RimJoists")
  end

  def self.set_enclosure_walls_reference(new_enclosure, orig_details, climate_zone)
  
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
    
    new_walls = XMLHelper.add_element(new_enclosure, "Walls")
    orig_details.elements.each("Enclosure/Walls/Wall") do |orig_wall|
      # Create new wall
      new_wall = XMLHelper.add_element(new_walls, "Wall")
      XMLHelper.copy_element(new_wall, orig_wall, "SystemIdentifier")
      XMLHelper.copy_element(new_wall, orig_wall, "AttachedToSpace")
      XMLHelper.copy_element(new_wall, orig_wall, "ExteriorAdjacentTo")
      XMLHelper.copy_element(new_wall, orig_wall, "InteriorAdjacentTo")
      XMLHelper.add_element(new_wall, "WallType/WoodStud")
      XMLHelper.copy_element(new_wall, orig_wall, "Area")
      insulation = XMLHelper.add_element(new_wall, "Insulation")
      XMLHelper.copy_element(insulation, orig_wall, "Insulation/SystemIdentifier")
      XMLHelper.add_element(insulation, "InsulationGrade", 1)
      XMLHelper.add_element(insulation, "AssemblyEffectiveRValue", 1.0/ufactor)
      extension = XMLHelper.add_element(new_wall, "extension")
      XMLHelper.add_element(extension, "SolarAbsorptance", 0.75)
      XMLHelper.add_element(extension, "Emittance", 0.90)
    end
    
  end

  def self.set_enclosure_windows_reference(new_enclosure, cfa, climate_zone)
    
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
    new_windows = XMLHelper.add_element(new_enclosure, "Windows")
    for orientation, azimuth in {"north"=>0,"south"=>180,"east"=>90,"west"=>180}
      # Create new window
      new_window = XMLHelper.add_element(new_windows, "Window")
      sys_id = XMLHelper.add_element(new_window, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "Window_#{orientation}")
      XMLHelper.add_element(new_window, "Area", 0.18 * 0.25 * cfa) # FIXME: Adjustment for conditioned basements
      XMLHelper.add_element(new_window, "Azimuth", azimuth)
      XMLHelper.add_element(new_window, "Orientation", orientation)
      XMLHelper.add_element(new_window, "UFactor", ufactor)
      XMLHelper.add_element(new_window, "SHGC", shgc)
      XMLHelper.add_element(new_window, "NFRCCertified", true)
      XMLHelper.add_element(new_window, "ExteriorShading", "none")
      XMLHelper.add_element(new_window, "Operable", true)
      extension = XMLHelper.add_element(new_window, "extension")
      XMLHelper.add_element(extension, "InteriorShadingFactorSummer", 0.70)
      XMLHelper.add_element(extension, "InteriorShadingFactorWinter", 0.85)
    end

  end

  def self.set_enclosure_skylights_reference(enclosure)
    '''
    Table 4.2.2(1) - Skylights
    None
    '''
  end

  def self.set_enclosure_doors_reference(new_enclosure, climate_zone)

    '''
    Table 4.2.2(1) - Doors
    Area: 40 ft2
    U-factor: same as fenestration from Table 4.2.2(2)
    Orientation: North
    '''
    
    ufactor, shgc = get_reference_component_characteristics(climate_zone, "door")
    
    # Create new door
    new_doors = XMLHelper.add_element(new_enclosure, "Doors")
    new_door = XMLHelper.add_element(new_doors, "Door")
    sys_id = XMLHelper.add_element(new_door, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Door")
    XMLHelper.add_element(new_door, "Area", 40)
    XMLHelper.add_element(new_door, "Azimuth", 0)
    XMLHelper.add_element(new_door, "Orientation", "north")
    XMLHelper.add_element(new_door, "DoorType", "exterior")
    XMLHelper.add_element(new_door, "RValue", 1.0/ufactor)
    
  end
  
  def self.set_systems_hvac_reference(new_systems, orig_details)
  
    new_hvac = XMLHelper.add_element(new_systems, "HVAC")
  
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
    
    hvac_plant = orig_details.elements["Systems/HVAC/HVACPlant"]
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
    
    # FIXME: Add PrimarySystems
    
    new_hvac_plant = XMLHelper.add_element(new_hvac, "HVACPlant")
    if fuel_type == 'eletricity' or not has_fuel_hookup_or_delivery
    
      # 7.7 HSPF air source heat pump
      heat_pump = XMLHelper.add_element(new_hvac_plant, "HeatPump")
      sys_id = XMLHelper.add_element(heat_pump, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "HeatPump")
      XMLHelper.add_element(heat_pump, "HeatPumpType", "air-to-air")
      cool_eff = XMLHelper.add_element(heat_pump, "AnnualCoolEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      heat_eff = XMLHelper.add_element(heat_pump, "AnnualHeatEfficiency")
      XMLHelper.add_element(heat_eff, "Units", "HSPF")
      XMLHelper.add_element(heat_eff, "Value", 7.7)
      
    else
    
      if has_boiler
      
        # 80% AFUE gas boiler
        heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
        boiler = XMLHelper.add_element(sys_type, "Boiler")
        XMLHelper.add_element(boiler, "BoilerType", "hot water")
        XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "electricity")
        heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.add_element(heat_eff, "Units", "AFUE")
        XMLHelper.add_element(heat_eff, "Value", 0.80)
        
      else
      
        # 78% AFUE gas furnace
        heat_sys = XMLHelper.add_element(new_hvac_plant, "HeatingSystem")
        sys_id = XMLHelper.add_element(heat_sys, "SystemIdentifier")
        XMLHelper.add_attribute(sys_id, "id", "HeatingSystem")
        sys_type = XMLHelper.add_element(heat_sys, "HeatingSystemType")
        furnace = XMLHelper.add_element(sys_type, "Furnace")
        XMLHelper.add_element(heat_sys, "HeatingSystemFuel", "electricity")
        heat_eff = XMLHelper.add_element(heat_sys, "AnnualHeatingEfficiency")
        XMLHelper.add_element(heat_eff, "Units", "AFUE")
        XMLHelper.add_element(heat_eff, "Value", 0.78)
        
      end
      
      # 13 SEER electric air conditioner
      cool_sys = XMLHelper.add_element(new_hvac_plant, "CoolingSystem")
      sys_id = XMLHelper.add_element(cool_sys, "SystemIdentifier")
      XMLHelper.add_attribute(sys_id, "id", "CoolingSystem")
      XMLHelper.add_element(cool_sys, "CoolingSystemType", "central air conditioning")
      XMLHelper.add_element(cool_sys, "CoolingSystemFuel", "electricity")
      cool_eff = XMLHelper.add_element(cool_sys, "AnnualCoolingEfficiency")
      XMLHelper.add_element(cool_eff, "Units", "SEER")
      XMLHelper.add_element(cool_eff, "Value", 13.0)
      
    end
    
    '''
    Table 303.4.1(1) - Thermostat
    Type: manual
    Temperature setpoints: heating temperature set point = 68 F
    Temperature setpoints: cooling temperature set point = 78 F
    '''
    
    new_hvac_control = XMLHelper.add_element(new_hvac, "HVACControl")
    sys_id = XMLHelper.add_element(new_hvac_control, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACControl")
    XMLHelper.add_element(new_hvac_control, "SetpointTempHeatingSeason", 68)
    XMLHelper.add_element(new_hvac_control, "SetpointTempCoolingSeason", 78)
    
    new_hvac_dist = XMLHelper.add_element(new_hvac, "HVACDistribution")
    
    '''
    TODO
    '''

    sys_id = XMLHelper.add_element(new_hvac_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HVACDistribution")
    # FIXME
    
  end
  
  def self.set_systems_mechanical_ventilation_reference(new_systems)
  
    new_mech_vent = XMLHelper.add_element(new_systems, "MechanicalVentilation")
  
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
    
    # FIXME
    
  end
  
  def self.set_systems_water_heating_reference(new_systems, orig_details, nbeds)
  
    new_water_heating = XMLHelper.add_element(new_systems, "WaterHeating")
  
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
    
    water_heaters = []
    orig_details.elements.each("Systems/WaterHeating/WaterHeatingSystem") do |sys|
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
      wh_fuel_type = XMLHelper.get_value(orig_details, "Systems/HVAC/HVACPlant/HeatingSystem/HeatingSystemFuel")
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
    wh_sys = XMLHelper.add_element(new_water_heating, "WaterHeatingSystem")
    sys_id = XMLHelper.add_element(wh_sys, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterHeatingSystem")
    XMLHelper.add_element(wh_sys, "FuelType", wh_fuel_type)
    XMLHelper.add_element(wh_sys, "WaterHeaterType", wh_type)
    XMLHelper.add_element(wh_sys, "TankVolume", wh_tank_vol)
    XMLHelper.add_element(wh_sys, "EnergyFactor", wh_ef)
    XMLHelper.add_element(wh_sys, "HotWaterTemperature", 125)
    
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refWgpd = 9.8*Nbr^0.43 
                        = reference climate-normalized daily hot water waste due to distribution system 
                          losses in Reference Home (in gallons per day)
    '''
    
    dist_gpd = 9.8 * (nbeds**0.43)
    
    # New hot water distribution
    new_hw_dist = XMLHelper.add_element(new_water_heating, "HotWaterDistribution")
    sys_id = XMLHelper.add_element(new_hw_dist, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "HotWaterDistribution")
    extension = XMLHelper.add_element(new_hw_dist, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", dist_gpd)
    
    '''
    ANSI/RESNET 301-2014 Addendum A-2015
    Amendment on Domestic Hot Water (DHW) Systems
    4.2.2.5.1.4 refFgpd = 14.6 + 10.0*Nbr
                        = reference climate-normalized daily fixture water use in Reference Home (in 
                          gallons per day)
    '''
    
    fixture_gpd = 14.6 + 10.0 * nbeds
    
    # New water fixture
    new_fixture = XMLHelper.add_element(new_water_heating, "WaterFixture")
    sys_id = XMLHelper.add_element(new_fixture, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "WaterFixture")
    XMLHelper.add_element(new_fixture, "WaterFixtureType", "other")
    extension = XMLHelper.add_element(new_fixture, "extension")
    XMLHelper.add_element(extension, "MixedWaterGPD", fixture_gpd)
    
  end
  
  def self.set_appliances_clothes_washer_reference(new_appliances, cfa, nbeds)
  
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
    
    new_clothes_washer = XMLHelper.add_element(new_appliances, "ClothesWasher")
    sys_id = XMLHelper.add_element(new_clothes_washer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesWasher")
    extension = XMLHelper.add_element(new_clothes_washer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_washer_kwh)
    XMLHelper.add_element(extension, "FracSensible", clothes_washer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_washer_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", clothes_washer_gpd)
  end

  def self.set_appliances_clothes_dryer_reference(new_appliances, orig_details, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
  
    dryer_fuel = get_fuel_type(orig_details, ["Appliances/ClothesDryer"])
    clothes_dryer_kwh = 524.0 + 0.0 * cfa + 149.0 * nbeds # default to electric
    clothes_dryer_therm = 0.0 # default to electric
    if dryer_fuel != 'electricity'
      clothes_dryer_kwh = 41.0 + 0.0 * cfa + 11.7 * nbeds
      clothes_dryer_therm = 18.8 + 0.0 * cfa + 5.3 * nbeds
    end
    clothes_dryer_sens = 0.15 * 0.9
    clothes_dryer_lat = 0.15 * 0.1
    
    new_clothes_dryer = XMLHelper.add_element(new_appliances, "ClothesDryer")
    sys_id = XMLHelper.add_element(new_clothes_dryer, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "ClothesDryer")
    XMLHelper.add_element(new_clothes_dryer, "FuelType", dryer_fuel)
    extension = XMLHelper.add_element(new_clothes_dryer, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", clothes_dryer_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", clothes_dryer_therm)
    XMLHelper.add_element(extension, "FracSensible", clothes_dryer_sens)
    XMLHelper.add_element(extension, "FracLatent", clothes_dryer_lat)
    
  end

  def self.set_appliances_dishwasher_reference(new_appliances, cfa, nbeds)
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
    
    new_dishwasher = XMLHelper.add_element(new_appliances, "Dishwasher")
    sys_id = XMLHelper.add_element(new_dishwasher, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Dishwasher")
    extension = XMLHelper.add_element(new_dishwasher, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", dishwasher_kwh)
    XMLHelper.add_element(extension, "FracSensible", dishwasher_sens)
    XMLHelper.add_element(extension, "FracLatent", dishwasher_lat)
    XMLHelper.add_element(extension, "HotWaterGPD", dishwasher_gpd)
    
  end

  def self.set_appliances_refrigerator_reference(new_appliances, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
  
    refrigerator_kwh = 637.0 + 0.0 * cfa + 18.0 * nbeds

    new_fridge = XMLHelper.add_element(new_appliances, "Refrigerator")
    sys_id = XMLHelper.add_element(new_fridge, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Refrigerator")
    extension = XMLHelper.add_element(new_fridge, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", refrigerator_kwh)
    
  end

  def self.set_appliances_cooking_range_oven_reference(new_appliances, orig_details, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    Table 4.2.2.5(2) Natural Gas Appliance Loads for HERS Reference Homes with gas appliances
    '''
    
    cooking_fuel = get_fuel_type(orig_details, ["Appliances/CookingRange","Appliances/Oven"])
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
    
    new_cooking_range = XMLHelper.add_element(new_appliances, "CookingRange")
    sys_id = XMLHelper.add_element(new_cooking_range, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "CookingRange")
    XMLHelper.add_element(new_cooking_range, "FuelType", cooking_fuel)
    extension = XMLHelper.add_element(new_cooking_range, "extension")
    XMLHelper.add_element(extension, "AnnualkWh", cooking_range_kwh)
    XMLHelper.add_element(extension, "AnnualTherm", cooking_range_therm)
    XMLHelper.add_element(extension, "FracSensible", cooking_range_sens)
    XMLHelper.add_element(extension, "FracLatent", cooking_range_lat)
    
  end

  def self.set_lighting_reference(new_lighting, orig_details, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    4.2.2.5.1.3. Garage Lighting. Where the Rated Home includes an enclosed garage, 100 kWh/y shall be added
    to the energy use of the Reference Home to account for garage lighting.
    '''
    
    extension = XMLHelper.add_element(new_lighting, "extension")
    
    # Interior lighting
    interior_lighting_kwh = 455.0 + 0.80 * cfa + 0.0 * nbeds
    XMLHelper.add_element(extension, "AnnualInteriorkWh", interior_lighting_kwh)
    
    # Exterior lighting
    exterior_lighting_kwh = 100.0 + 0.05 * cfa + 0.0 * nbeds
    XMLHelper.add_element(extension, "AnnualExteriorkWh", exterior_lighting_kwh)
    
    # Garage lighting
    garage_lighting_kwh = 0.0
    if XMLHelper.get_value(orig_details, "BuildingSummary/BuildingConstruction/GaragePresent") == "true"
      garage_lighting_kwh = 100.0
    end
    XMLHelper.add_element(extension, "AnnualGaragekWh", garage_lighting_kwh)
    
  end

  def self.set_lighting_ceiling_fans_reference(new_lighting)
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

  def self.set_misc_loads_reference(new_misc_loads, cfa, nbeds)
    '''
    Table 4.2.2.5(1) Lighting, Appliance and Miscellaneous Electric Loads in electric HERS Reference Homes
    '''
    
    # Residual MELs
    residual_mels_kwh = 0.0 + 0.91 * cfa + 0.0 * nbeds
    residual_mels = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(residual_mels, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Residual_MELs")
    XMLHelper.add_element(residual_mels, "PlugLoadType", "other")
    residual_mels_load = XMLHelper.add_element(residual_mels, "Load")
    XMLHelper.add_element(residual_mels_load, "Units", "kWh/year")
    XMLHelper.add_element(residual_mels_load, "Value", residual_mels_kwh)
    # TODO: Sens/lat frac
    
    # Televisions
    televisions_kwh = 413.0 + 0.0 * cfa + 69.0 * nbeds
    television = XMLHelper.add_element(new_misc_loads, "PlugLoad")
    sys_id = XMLHelper.add_element(television, "SystemIdentifier")
    XMLHelper.add_attribute(sys_id, "id", "Television")
    XMLHelper.add_element(television, "PlugLoadType", "TV other")
    television_load = XMLHelper.add_element(television, "Load")
    XMLHelper.add_element(television_load, "Units", "kWh/year")
    XMLHelper.add_element(television_load, "Value", televisions_kwh)
    
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

  # Adds the child element with 'element_name' and sets its value. Returns the
  # child element.
  def self.add_element(parent, element_name, value=nil)
    added = nil
    element_name.split("/").each do |name|
      added = REXML::Element.new(name)
      parent << added
      parent = added
    end
    if not value.nil?
      added.text = value
    end
    return added
  end
  
  # Deletes the child element with element_name. Returns the deleted element.
  def self.delete_element(parent, element_name)
    element = parent.elements.delete(element_name)
    return element
  end
  
  # Returns the value of 'element_name' in the parent element or nil.
  def self.get_value(parent, element_name)
    val = parent.elements[element_name]
    if val.nil?
      return val
    end
    return val.text
  end
  
  # Returns true if the element exists.
  def self.has_element(parent, element_name)
    element_name.split("/").each do |name|
      element = parent.elements[name]
      return false if element.nil?
      parent = element
    end
    return true
  end
  
  # Copies the element if it exists
  def self.copy_element(dest, src, element_name)
    if not src.elements[element_name].nil?
      dest << src.elements[element_name]
    end
  end
  
  # Returns the attribute added
  def self.add_attribute(element, attr_name, attr_val)
    added = element.add_attribute(attr_name, attr_val)
    return added
  end
  
end
