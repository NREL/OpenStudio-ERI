#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessInfiltration < OpenStudio::Ruleset::WorkspaceUserScript

  class Infiltration
    def initialize(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient)
      @infiltrationLivingSpaceACH50 = infiltrationLivingSpaceACH50
      @infiltrationShelterCoefficient = infiltrationShelterCoefficient
    end

    attr_accessor(:assumed_inside_temp, :n_i, :A_o, :C_i, :Y_i, :flue_height, :S_wflue, :R_i, :X_i, :Z_f, :M_o, :M_i, :X_c, :F_i, :f_s, :stack_coef, :R_x, :Y_x, :X_s, :X_x, :f_w, :J_i, :f_w, :wind_coef, :default_rate, :rate_credit)

    def InfiltrationLivingSpaceACH50
      return @infiltrationLivingSpaceACH50
    end

    def InfiltrationShelterCoefficient
      return @infiltrationShelterCoefficient
    end

    def InfiltrationGarageACH50
      return @infiltrationLivingSpaceACH50
    end

  end

  class LivingSpace
    def initialize
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class Garage
    def initialize
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class FinBasement
    def initialize(fbsmtACH)
      @fbsmtACH = fbsmtACH
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def FBsmtACH
      return @fbsmtACH
    end
  end

  class UnfinBasement
    def initialize(ufbsmtACH)
      @ufbsmtACH = ufbsmtACH
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def UFBsmtACH
      return @ufbsmtACH
    end
  end

  class Crawl
    def initialize(crawlACH)
      @crawlACH = crawlACH
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def CrawlACH
      return @crawlACH
    end
  end

  class UnfinAttic
    def initialize(uaSLA)
      @uaSLA = uaSLA
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def UASLA
      return @uaSLA
    end
  end

  class WindSpeed
    def initialize
    end
    attr_accessor(:height, :terrain_multiplier, :terrain_exponent, :boundary_layer_thickness, :site_terrain_multiplier, :site_terrain_exponent, :site_boundary_layer_thickness, :ref_wind_speed, :S_wo, :shielding_coef)
  end

  class Neighbors
    def initialize(neighborOffset)
      @neighborOffset = neighborOffset
    end

    def NeighborOffset
      return @neighborOffset
    end
  end

  class Site
    def initialize(terrainType)
      @terrainType = terrainType
    end

    def TerrainType
      return @terrainType
    end
  end

  class MechanicalVentilation
    def initialize(mechVentType, mechVentInfilCreditForExistingHomes, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower)
      @mechVentType = mechVentType
      @mechVentInfilCreditForExistingHomes = mechVentInfilCreditForExistingHomes
      @mechVentTotalEfficiency = mechVentTotalEfficiency
      @mechVentFractionOfASHRAE = mechVentFractionOfASHRAE
      @mechVentHouseFanPower = mechVentHouseFanPower
    end

    attr_accessor(:MechVentBathroomExhaust, :MechVentRangeHoodExhaust, :MechVentSpotFanPower, :bath_exhaust_operation, :range_hood_exhaust_operation, :clothes_dryer_exhaust_operation, :ashrae_vent_rate, :num_vent_fans, :percent_fan_heat_to_space, :whole_house_vent_rate, :bathroom_hour_avg_exhaust, :range_hood_hour_avg_exhaust, :clothes_dryer_hour_avg_exhaust, :max_power, :base_vent_rate, :max_vent_rate, :MechVentApparentSensibleEffectiveness, :MechVentHXCoreSensibleEffectiveness, :MechVentLatentEffectiveness, :hourly_energy_schedule, :hourly_schedule, :average_vent_fan_eff)

    def MechVentType
      return @mechVentType
    end

    def MechVentInfilCreditForExistingHomes
      return @mechVentInfilCreditForExistingHomes
    end

    def MechVentTotalEfficiency
      return @mechVentTotalEfficiency
    end

    def MechVentFractionOfASHRAE
      return @mechVentFractionOfASHRAE
    end

    def MechVentHouseFanPower
      return @mechVentHouseFanPower
    end
  end

  class Misc
    def initialize(ageOfHome, simTestSuiteBuilding)
      @ageOfHome = ageOfHome
      @simTestSuiteBuilding = simTestSuiteBuilding
    end

    def AgeOfHome
      return @ageOfHome
    end

    def SimTestSuiteBuilding
      return @simTestSuiteBuilding
    end
  end

  class ClothesDryer
    def initialize(dryerExhaust)
      @dryerExhaust = dryerExhaust
    end

    def DryerExhaust
      return @dryerExhaust
    end
  end

  class Geometry
    def initialize
    end
    attr_accessor(:num_bedrooms, :finished_floor_area, :num_bathrooms)
  end

  class NaturalVentilation
    def initialize(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
      @natVentHtgSsnSetpointOffset = natVentHtgSsnSetpointOffset
      @natVentClgSsnSetpointOffset = natVentClgSsnSetpointOffset
      @natVentOvlpSsnSetpointOffset = natVentOvlpSsnSetpointOffset
      @natVentHeatingSeason = natVentHeatingSeason
      @natVentCoolingSeason = natVentCoolingSeason
      @natVentOverlapSeason = natVentOverlapSeason
      @natVentNumberWeekdays = natVentNumberWeekdays
      @natVentNumberWeekendDays = natVentNumberWeekendDays
      @natVentFractionWindowsOpen = natVentFractionWindowsOpen
      @natVentFractionWindowAreaOpen = natVentFractionWindowAreaOpen
      @natVentMaxOAHumidityRatio = natVentMaxOAHumidityRatio
      @natVentMaxOARelativeHumidity = natVentMaxOARelativeHumidity
    end

    attr_accessor(:htg_ssn_hourly_temp, :htg_ssn_hourly_weekend_temp, :clg_ssn_hourly_temp, :clg_ssn_hourly_weekend_temp, :ovlp_ssn_hourly_temp, :ovlp_ssn_hourly_weekend_temp, :season_type, :area, :max_rate, :max_flow_rate, :hor_vent_frac, :C_s, :C_w)

    def NatVentHtgSsnSetpointOffset
      return @natVentHtgSsnSetpointOffset
    end

    def NatVentClgSsnSetpointOffset
      return @natVentClgSsnSetpointOffset
    end

    def NatVentOvlpSsnSetpointOffset
      return @natVentOvlpSsnSetpointOffset
    end

    def NatVentHeatingSeason
      return @natVentHeatingSeason
    end

    def NatVentCoolingSeason
      return @natVentCoolingSeason
    end

    def NatVentOverlapSeason
      return @natVentOverlapSeason
    end

    def NatVentNumberWeekdays
      return @natVentNumberWeekdays
    end

    def NatVentNumberWeekendDays
      return @natVentNumberWeekendDays
    end

    def NatVentFractionWindowsOpen
      return @natVentFractionWindowsOpen
    end

    def NatVentFractionWindowAreaOpen
      return @natVentFractionWindowAreaOpen
    end

    def NatVentMaxOAHumidityRatio
      return @natVentMaxOAHumidityRatio
    end

    def NatVentMaxOARelativeHumidity
      return @natVentMaxOARelativeHumidity
    end
  end

  class Schedules
    def initialize
    end
    attr_accessor(:MechanicalVentilationEnergy, :MechanicalVentilation, :BathExhaust, :ClothesDryerExhaust, :RangeHood)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessInfiltration"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # #make a choice argument for model objects
    # zone_display_names = OpenStudio::StringVector.new
    #
    # #get all thermal zones in model
    # zone_args = workspace.getObjectsByType("Zone".to_IddObjectType)
    # zone_args.each do |zone_arg|
    #   zone_arg_name = zone_arg.getString(0) # Name
    #   zone_display_names << zone_arg_name.to_s
    # end
    #
    # zone_display_names << "N/A"
    #
    # #make a choice argument for living space
    # selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", zone_display_names, true)
    # selected_living.setDisplayName("Of what space type is the living space?")
    # args << selected_living
    #
    # #make a double argument for infiltration of living space
    # userdefined_inflivingspace = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinflivingspace", true)
    # userdefined_inflivingspace.setDisplayName("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including finished attic).")
    # userdefined_inflivingspace.setDefaultValue(7.0)
    # args << userdefined_inflivingspace
    #
    # #make a double argument for shelter coefficient
    # userdefined_infsheltercoef = OpenStudio::Ruleset::OSArgument::makeStringArgument("userdefinedinfsheltercoef", false)
    # userdefined_infsheltercoef.setDisplayName("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees and obstructions.")
    # userdefined_infsheltercoef.setDefaultValue("auto")
    # args << userdefined_infsheltercoef
    #
    # #make a choice argument for garage
    # selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", zone_display_names, false)
    # selected_garage.setDisplayName("Of what space type is the garage?")
    # args << selected_garage
    #
    # #make a choice argument for fbsmt
    # selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", zone_display_names, false)
    # selected_fbsmt.setDisplayName("Of what space type is the finished basement?")
    # args << selected_fbsmt
    #
    # #make a choice argument for ufbsmt
    # selected_ufbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmt", zone_display_names, false)
    # selected_ufbsmt.setDisplayName("Of what space type is the unfinished basement?")
    # args << selected_ufbsmt
    #
    # #make a choice argument for crawl
    # selected_crawl = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcrawl", zone_display_names, false)
    # selected_crawl.setDisplayName("Of what space type is the crawlspace?")
    # args << selected_crawl
    #
    # #make a double argument for infiltration of crawlspace
    # userdefined_infcrawl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfcrawl", false)
    # userdefined_infcrawl.setDisplayName("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the crawlspace.")
    # userdefined_infcrawl.setDefaultValue(2.0)
    # args << userdefined_infcrawl
    #
    #
    # #make a choice argument for unfinattic
    # selected_unfinattic = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedunfinattic", zone_display_names, false)
    # selected_unfinattic.setDisplayName("Of what space type is the unfinished attic?")
    # args << selected_unfinattic

    # #make a double argument for infiltration of unfinished attic
    # userdefined_infunfinattic = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfunfinattic", false)
    # userdefined_infunfinattic.setDisplayName("Ratio of the effective leakage area (infiltration and/or ventilation) in the unfinished attic to the total floor area of the attic.")
    # userdefined_infunfinattic.setDefaultValue(0.00333)
    # args << userdefined_infunfinattic

    # #make a double argument for neighbor offset
    # userdefined_neighboroffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedneighboroffset", false)
    # userdefined_neighboroffset.setDisplayName("The minimum distance between the simulated house and the neighboring houses (not including eaves) [ft].")
    # userdefined_neighboroffset.setDefaultValue(10.0)
    # args << userdefined_neighboroffset

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # #use the built-in error checking
    # if not runner.validateUserArguments(arguments(workspace), user_arguments)
    #   return false
    # end

    # Space Type
    # selected_living = runner.getStringArgumentValue("selectedliving",user_arguments)
    # selected_garage = runner.getStringArgumentValue("selectedgarage",user_arguments)
    # selected_fbsmt = runner.getStringArgumentValue("selectedfbsmt",user_arguments)
    # selected_ufbsmt = runner.getStringArgumentValue("selectedufbsmt",user_arguments)
    # selected_crawl = runner.getStringArgumentValue("selectedcrawl",user_arguments)
    # selected_unfinattic = runner.getStringArgumentValue("selectedunfinattic",user_arguments)
    selected_living = "living"
    selected_garage = "garage"
    selected_fbsmt = nil
    selected_ufbsmt = nil
    selected_crawl = "crawlspace"
    selected_unfinattic = "attic"

    # infiltrationLivingSpaceACH50 = runner.getDoubleArgumentValue("userdefinedinflivingspace",user_arguments)
    infiltrationLivingSpaceACH50 = 7.0
    # infiltrationShelterCoefficient = runner.getStringArgumentValue("userdefinedinfsheltercoef",user_arguments)
    infiltrationShelterCoefficient = "auto"
    # crawlACH = runner.getDoubleArgumentValue("userdefinedinfcrawl",user_arguments)
    crawlACH = 2.0
    fbsmtACH = 0.0
    ufbsmtACH = 0.1
    # uaSLA = runner.getDoubleArgumentValue("userdefinedinfunfinattic",user_arguments)
    uaSLA = 0.00333
    # neighborOffset = runner.getDoubleArgumentValue("userdefinedneighboroffset",user_arguments)
    neighborOffset = 10.0
    terrainType = "suburban"
    mechVentType = "exhaust"
    mechVentInfilCreditForExistingHomes = true
    mechVentTotalEfficiency = 0.0
    mechVentFractionOfASHRAE = 1.0
    mechVentHouseFanPower = 0.3
    ageOfHome = 10.0
    simTestSuiteBuilding = nil
    dryerExhaust = 100.0
    natVentHtgSsnSetpointOffset = 1.0
    natVentClgSsnSetpointOffset = 1.0
    natVentOvlpSsnSetpointOffset = 1.0
    natVentHeatingSeason = true
    natVentCoolingSeason = true
    natVentOverlapSeason = true
    natVentNumberWeekdays = 3.0
    natVentNumberWeekendDays = 0.0
    natVentFractionWindowsOpen = 0.33
    natVentFractionWindowAreaOpen = 0.2
    natVentMaxOAHumidityRatio = 0.0115
    natVentMaxOARelativeHumidity = 0.7

    # Create the material class instances
    si = Infiltration.new(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient)
    living_space = LivingSpace.new
    garage = Garage.new
    finished_basement = FinBasement.new(fbsmtACH)
    space_unfinished_basement = UnfinBasement.new(ufbsmtACH)
    crawlspace = Crawl.new(crawlACH)
    unfinished_attic = UnfinAttic.new(uaSLA)
    wind_speed = WindSpeed.new
    neighbors = Neighbors.new(neighborOffset)
    site = Site.new(terrainType)
    vent = MechanicalVentilation.new(mechVentType, mechVentInfilCreditForExistingHomes, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower)
    misc = Misc.new(ageOfHome, simTestSuiteBuilding)
    clothes_dryer = ClothesDryer.new(dryerExhaust)
    geometry = Geometry.new
    nv = NaturalVentilation.new(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
    schedules = Schedules.new

    zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    zones.each do |zone|
      zone_name = zone.getString(0) # Name
      if zone_name == selected_living
        # living_space.height = OpenStudio::convert(zone.getString(7).to_f,"m","ft").get # Ceiling Height {m}
        # living_space.area = OpenStudio::convert(zone.getString(9).to_f,"m","ft").get # Floor Area {m2}
        # living_space.volume = OpenStudio::convert(zone.getString(8).to_f,"m^3","ft^3").get # Volume {m3}
        # living_space.coord_z = OpenStudio::convert(zone.getString(4).to_f,"m^3","ft^3").get # Z Origin {m}
      elsif zone_name == selected_garage
        # garage.height = OpenStudio::convert(zone.getString(7).to_f,"m","ft").get # Ceiling Height {m}
        # garage.area = OpenStudio::convert(zone.getString(9).to_f,"m","ft").get # Floor Area {m2}
        # garage.volume = OpenStudio::convert(zone.getString(8).to_f,"m^3","ft^3").get # Volume {m3}
        # garage.coord_z = OpenStudio::convert(zone.getString(4).to_f,"m^3","ft^3").get # Z Origin {m}
      elsif zone_name == selected_fbsmt
        # finished_basement.height = OpenStudio::convert(zone.getString(7).to_f,"m","ft").get # Ceiling Height {m}
        # finished_basement.area = OpenStudio::convert(zone.getString(9).to_f,"m","ft").get # Floor Area {m2}
        # finished_basement.volume = OpenStudio::convert(zone.getString(8).to_f,"m^3","ft^3").get # Volume {m3}
        # finished_basement.coord_z = OpenStudio::convert(zone.getString(4).to_f,"m^3","ft^3").get # Z Origin {m}
      elsif zone_name == selected_ufbsmt
        # space_unfinished_basement.height = OpenStudio::convert(zone.getString(7).to_f,"m","ft").get # Ceiling Height {m}
        # space_unfinished_basement.area = OpenStudio::convert(zone.getString(9).to_f,"m","ft").get # Floor Area {m2}
        # space_unfinished_basement.volume = OpenStudio::convert(zone.getString(8).to_f,"m^3","ft^3").get # Volume {m3}
        # space_unfinished_basement.coord_z = OpenStudio::convert(zone.getString(4).to_f,"m^3","ft^3").get # Z Origin {m}
      elsif zone_name == selected_ufbsmt
        # crawlspace.height = OpenStudio::convert(zone.getString(7).to_f,"m","ft").get # Ceiling Height {m}
        # crawlspace.area = OpenStudio::convert(zone.getString(9).to_f,"m","ft").get # Floor Area {m2}
        # crawlspace.volume = OpenStudio::convert(zone.getString(8).to_f,"m^3","ft^3").get # Volume {m3}
        # crawlspace.coord_z = OpenStudio::convert(zone.getString(4).to_f,"m^3","ft^3").get # Z Origin {m}
      elsif zone_name == selected_unfinattic
        # unfinished_attic.height = OpenStudio::convert(zone.getString(7).to_f,"m","ft").get # Ceiling Height {m}
        # unfinished_attic.area = OpenStudio::convert(zone.getString(9).to_f,"m","ft").get # Floor Area {m2}
        # unfinished_attic.volume = OpenStudio::convert(zone.getString(8).to_f,"m^3","ft^3").get # Volume {m3}
        # unfinished_attic.coord_z = OpenStudio::convert(zone.getString(4).to_f,"m^3","ft^3").get # Z Origin {m}
      end
    end

    # temp code
    living_space.height = 8.0
    living_space.area = 1200.0
    living_space.volume = 1200.0 * 8.0
    living_space.coord_z = 0.0
    garage.height = 8.0
    garage.area = 15.0 * 20.0
    garage.volume = 8.0 * 15.0 * 20.0
    garage.coord_z = 0.0
    finished_basement.height = 8.0
    finished_basement.area = 300.0
    finished_basement.volume = 1200.0 * 8.0
    finished_basement.coord_z = -8.0
    space_unfinished_basement.height = 8.0
    space_unfinished_basement.area = 1200.0
    space_unfinished_basement.volume = 1200.0 * 8.0
    space_unfinished_basement.coord_z = -8.0
    crawlspace.height = 4.0
    crawlspace.area = 1200.0
    crawlspace.volume = 4.0 * 1200.0
    crawlspace.coord_z = -4.0
    unfinished_attic.height = 3.0
    unfinished_attic.area = 1200.0
    unfinished_attic.volume = 3.0 * 1200.0
    unfinished_attic.coord_z = 8.0
    geometry.num_bedrooms = 3.0
    geometry.finished_floor_area = 1200.0
    geometry.num_bathrooms = 2.0
    #

    # Create the sim object
    sim = Sim.new(workspace)

    # Process the infiltration
    si, living_space, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic, wind_speed = sim._processInfiltration(si, living_space, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic, selected_garage, selected_fbsmt, selected_ufbsmt, selected_crawl, selected_unfinattic, wind_speed, neighbors, site)
    # Process the mechanical ventilation
    vent, schedules = sim._processMechanicalVentilation(si, vent, misc, clothes_dryer, geometry, living_space, schedules)
    # Process the natural ventilation
    nv = sim._processNaturalVentilation(nv, living_space, wind_speed, si)

    # Constants
    constants = Constants.new

    # Schedules
    sch = "
    ScheduleTypeLimits,
      Fraction,                     !- Name
      0,                            !- Lower Limit Value
      1,                            !- Upper Limit Value
      Continuous;                   !- Numeric Type"
    idfObject = OpenStudio::IdfObject::load(sch)
    object = idfObject.get
    wsObject = workspace.addObject(object)

    schedules.MechanicalVentilationEnergy.each do |sch|
      idfObject = OpenStudio::IdfObject::load(sch)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end
    schedules.MechanicalVentilation.each do |sch|
      idfObject = OpenStudio::IdfObject::load(sch)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end
    schedules.BathExhaust.each do |sch|
      idfObject = OpenStudio::IdfObject::load(sch)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end
    schedules.ClothesDryerExhaust.each do |sch|
      idfObject = OpenStudio::IdfObject::load(sch)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end
    schedules.RangeHood.each do |sch|
      idfObject = OpenStudio::IdfObject::load(sch)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end

    ems = []

    # Sensors

    # Tout
    ems << "
    EnergyManagementSystem:Sensor,
      Tout,                                                       !- Name
      living,                                                     !- Output:Variable or Output:Meter Index Key Name
      Zone Outdoor Air Drybulb Temperature;                       !- Output:Variable or Output:Meter Index Key Name"

    # Hout
    ems << "
    EnergyManagementSystem:Sensor,
      Hout,                                                       !- Name
      ,                                                           !- Output:Variable or Output:Meter Index Key Name
      Site Outdoor Air Enthalpy;                                  !- Output:Variable or Output:Meter Index Key Name"

    # Pbar
    ems << "
    EnergyManagementSystem:Sensor,
      Pbar,                                                       !- Name
      ,                                                           !- Output:Variable or Output:Meter Index Key Name
      Site Outdoor Air Barometric Pressure;                       !- Output:Variable or Output:Meter Index Key Name"

    # Tin
    ems << "
    EnergyManagementSystem:Sensor,
      Tin,                                                        !- Name
      living,                                                     !- Output:Variable or Output:Meter Index Key Name
      Zone Mean Air Temperature;                                  !- Output:Variable or Output:Meter Index Key Name"

    # Win
    ems << "
    EnergyManagementSystem:Sensor,
      TWin,                                                       !- Name
      living,                                                     !- Output:Variable or Output:Meter Index Key Name
      Zone Mean Air Humidity Ratio;                               !- Output:Variable or Output:Meter Index Key Name"

    # Wout
    ems << "
    EnergyManagementSystem:Sensor,
      Wout,                                                       !- Name
      ,                                                           !- Output:Variable or Output:Meter Index Key Name
      Site Outdoor Air Humidity Ratio;                            !- Output:Variable or Output:Meter Index Key Name"

    # Vwind
    ems << "
    EnergyManagementSystem:Sensor,
      Vwind,                                                      !- Name
      ,                                                           !- Output:Variable or Output:Meter Index Key Name
      Site Wind Speed;                                            !- Output:Variable or Output:Meter Index Key Name"

    # WH_sch
    ems << "
    EnergyManagementSystem:Sensor,
      WH_sch,                                                     !- Name
      AlwaysOn,                                                   !- Output:Variable or Output:Meter Index Key Name
      Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

    # Range_sch
    ems << "
    EnergyManagementSystem:Sensor,
      Range_sch,                                                  !- Name
      RangeHood,                                                  !- Output:Variable or Output:Meter Index Key Name
      Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

    # Bath_sch
    ems << "
    EnergyManagementSystem:Sensor,
      Bath_sch,                                                   !- Name
      BathExhaust,                                                !- Output:Variable or Output:Meter Index Key Name
      Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

    # Clothes_dryer_sch
    ems << "
    EnergyManagementSystem:Sensor,
      Clothes_dryer_sch,                                          !- Name
      ClothesDryerExhaust,                                        !- Output:Variable or Output:Meter Index Key Name
      Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

    # NVAvail
    ems << "
    EnergyManagementSystem:Sensor,
      NVAvail,                                                    !- Name
      NatVent,                                                    !- Output:Variable or Output:Meter Index Key Name
      Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

    # NVSP
    ems << "
    EnergyManagementSystem:Sensor,
      NVSP,                                                       !- Name
      NatVentTemp,                                                !- Output:Variable or Output:Meter Index Key Name
      Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

    # Actuators

    # NatVentFlow
    ems << "
    EnergyManagementSystem:Actuator,
      NatVentFlow,                                                !- Name
      Natural Ventilation,                                        !- Actuated Component Unique Name
      Zone Ventilation,                                           !- Actuated Component Type
      Air Exchange Flow Rate;                                     !- Actuated Component Control Type"

    # InfilFlow
    ems << "
    EnergyManagementSystem:Actuator,
      InfilFlow,                                                  !- Name
      Living Ventilation,                                         !- Actuated Component Unique Name
      Zone Ventilation,                                           !- Actuated Component Type
      Air Exchange Flow Rate;                                     !- Actuated Component Control Type"

    # Program

    # InfiltrationProgram
    ems_program = "
    EnergyManagementSystem:Program,
      InfiltrationProgram,                                        !- Name"

    if living_space.inf_method == constants.InfMethodASHRAE
      if living_space.SLA > 0
        inf = si
        ems_program += "
          Set Tdiff = Tin - Tout,
          Set DeltaT = @Abs Tdiff,
          Set c = #{(OpenStudio::convert(inf.C_i,"cfm","m^3/s").get / (249.1 ** inf.n_i))},
          Set Cs = #{inf.stack_coef * (448.4 ** inf.n_i)},
          Set Cw = #{inf.wind_coef * (1246.0 ** inf.n_i)},
          Set n = #{inf.n_i},
          Set sft = #{((wind_speed.S_wo * (1 - inf.Y_i)) + (inf.S_wflue * (1.5 * inf.Y_i))) * living_space.f_t_SG},
          Set Qn = (((c*Cs*(DeltaT^n))^2)+(((c*Cw)*((sft*Vwind)^(2*n)))^2))^0.5,"
      else
        ems_program += "
          Set Qn = 0,"
      end
    elsif living_space.inf_method == constants.InfMethodRes
      ems_program += "
      Set Qn = #{living_space.ACH * OpenStudio::convert(living_space.volume,"ft^3","m^3").get / OpenStudio::convert(1.0,"hr","sec").get},"
    end

    ems_program += "
      Set Tdiff = Tin - Tout,
      Set DeltaT = @Abs Tdiff,"

    ems_program += "
      Set QWH = WH_sch*#{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},
      Set Qrange = Range_sch*#{OpenStudio::convert(vent.range_hood_hour_avg_exhaust,"cfm","m^3/s").get},
      Set Qdryer = Clothes_dryer_sch*#{OpenStudio::convert(vent.clothes_dryer_hour_avg_exhaust,"cfm","m^3/s").get},
      Set Qbath = Bath_sch*#{OpenStudio::convert(vent.bathroom_hour_avg_exhaust,"cfm","m^3/s").get},
      Set QhpwhOut = 0,
      Set QhpwhIn = 0,
      Set QductsOut = DuctLeakExhaustFanEquivalent,
      Set QductsIn = DuctLeakSupplyFanEquivalent,"

    if vent.MechVentType == constants.VentTypeBalanced
      ems_program += "
        Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut,          !- Exhaust flows
        Set Qin = QhpwhIn+QductsIn,                                 !- Supply flows
        Set Qu = @Abs (Qout - Qin),                                 !- Unbalanced flow
        Set Qb = QWH + @Min Qout Qin,                               !- Balanced flow"
    else
      if vent.MechVentType == constants.VentTypeExhaust
        ems_program += "
          Set Qout = QWH+Qrange+Qbath+Qdryer+QhpwhOut+QductsOut,      !- Exhaust flows
          Set Qin = QhpwhIn+QductsIn,                                 !- Supply flows
          Set Qu = @Abs (Qout - Qin),                                 !- Unbalanced flow
          Set Qb = QWH + @Min Qout Qin,                               !- Balanced flow"
      else #vent.MechVentType == Constants.VentTypeSupply:
        ems_program += "
          Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut,          !- Exhaust flows
          Set Qin = QWH+QhpwhIn+QductsIn,                             !- Supply flows
          Set Qu = @Abs (Qout - Qin),                                 !- QductOA
          Set Qb = QWH + @Min Qout Qin,                               !- Balanced flow"
      end

      if vent.MechVentHouseFanPower != 0
        ems_program += "
          Set faneff_wh = #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get},      !- Fan Efficiency"
      else
        ems_program += "
          Set faneff_wh = 1,"
      end
      ems_program += "
        Set WholeHouseFanPowerOverride= (QWH*300)/faneff_wh,"
    end
    if vent.MechVentSpotFanPower != 0
      ems_program += "
        Set faneff_sp = #{OpenStudio::convert(300.0 / vent.MechVentSpotFanPower,"cfm","m^3/s").get},        !- Fan Efficiency"
    else
      ems_program += "
        Set faneff_sp = 1,"
    end

    ems_program += "
      Set RangeHoodFanPowerOverride = (Qrange*300)/faneff_sp,
      Set BathExhaustFanPowerOverride = (Qbath*300)/faneff_sp,
      Set Infilflow = ((Qu^2) + (Qn^2))^0.5,
      Set Q_acctd_for_elsewhere = QhpwhOut + QhpwhIn + QductsOut + QductsIn," # These flows are accounted for with actuators in other EMS programs.
    ems_program += "
      Set InfMechVent = Qb + Infilflow - Q_acctd_for_elsewhere;" # so subtract them out here

    ems << ems_program

    # OutputVariable

    # Zone Infil/MechVent Flow Rate
    ems << "
    EnergyManagementSystem:OutputVariable,
      Zone Infil/MechVent Flow Rate,                                  !- Name
      InfMechVent,                                                    !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      InfiltrationProgram,                                            !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # Whole House Fan Vent Flow Rate
    ems << "
    EnergyManagementSystem:OutputVariable,
      Whole House Fan Vent Flow Rate,                                 !- Name
      QWH,                                                            !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      InfiltrationProgram,                                            !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # Range Hood Fan Vent Flow Rate
    ems << "
    EnergyManagementSystem:OutputVariable,
      Range Hood Fan Vent Flow Rate,                                  !- Name
      Qrange,                                                         !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      InfiltrationProgram,                                            !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # Bath Exhaust Fan Vent Flow Rate
    ems << "
    EnergyManagementSystem:OutputVariable,
      Bath Exhaust Fan Vent Flow Rate,                                !- Name
      Qbath,                                                          !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      InfiltrationProgram,                                            !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # Clothes Dryer Exhaust Fan Vent Flow Rate
    ems << "
    EnergyManagementSystem:OutputVariable,
      Clothes Dryer Exhaust Fan Vent Flow Rate,                       !- Name
      Qdryer,                                                         !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      InfiltrationProgram,                                            !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # Local Wind Speed
    ems << "
    EnergyManagementSystem:OutputVariable,
      Local Wind Speed,                                               !- Name
      VwindL,                                                         !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      LocalWindSpeedProgram,                                          !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # Program

    # LocalWindSpeedProgram
    ems <<  "
    EnergyManagementSystem:Program,
      LocalWindSpeedProgram,                                          !- Name
      Set VwindL = Vwind*#{living_space.f_t_SG};"

    # NaturalVentilationProgram
    ems << "
    EnergyManagementSystem:Program,
      NaturalVentilationProgram,                                      !- Name
      Set Tdiff = Tin - Tout,
      Set DeltaT = @Abs Tdiff,
      Set Phiout = @RhFnTdbWPb Tout Wout Pbar,
      Set Hin = @HFnTdbRhPb Tin Phiin Pbar,
      Set NVArea = #{OpenStudio::convert(nv.area,"ft^2","cm^2").get},
      Set Cs = #{0.001672 * nv.C_s},
      Set Cw = #{0.01 * nv.C_w},
      Set MaxNV = #{OpenStudio::convert(nv.max_flow_rate,"cfm","m^3/s").get},
      Set MaxHR = #{nv.NatVentMaxOAHumidityRatio},
      Set MaxRH = #{nv.NatVentMaxOARelativeHumidity},
      Set SGNV = (NVAvail*NVArea)*((((Cs*DeltaT)+(Cw*(Vwind^2)))^0.5)/1000),
      If Wout < MaxHR && Phiout < MaxRH && Tin > NVSP,
        Set NVadj1 = (Tin - NVSP)/(Tin - Tout),
        Set NVadj2 = @Min NVadj1 1,
        Set NVadj3 = @Max NVadj2 0,
        Set NVadj = SGNV*NVadj3,
        Set NatVentFlow = @Min NVadj MaxNV,
      Else,
        Set NatVentFlow = 0,
      EndIf;"

    # OutputVariable

    # Zone Natural Ventilation Flow Rate
    ems << "
    EnergyManagementSystem:OutputVariable,
      Zone Natural Ventilation Flow Rate,                             !- Name
      NatVentFlow,                                                    !- EMS Variable Name
      Averaged,                                                       !- Type of Data in Variable
      ZoneTimestep,                                                   !- Update Frequency
      NaturalVentilationProgram,                                      !- EMS Program or Subroutine Name
      m3/s;                                                           !- Units"

    # ProgramCallingManager

    # AirflowCalculator
    ems << "
    EnergyManagementSystem:ProgramCallingManager,
      AirflowCalculator,                                          !- Name
      BeginTimestepBeforePredictor,                               !- EnergyPlus Model Calling Point
      InfiltrationProgram,                                        !- Program Name 1
      NaturalVentilationProgram,                                  !- Program Name 2
      LocalWindSpeedProgram;                                      !- Program Name 3"

    # Mechanical Ventilation
    if vent.MechVentType == constants.VentTypeBalanced

      # ERV

    end

    ems.each do |str|
      idfObject = OpenStudio::IdfObject::load(str)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessInfiltration.new.registerWithApplication