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
class ProcessAirflow < OpenStudio::Ruleset::WorkspaceUserScript

  class Infiltration
    def initialize(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationLivingSpaceConstantACH, infiltrationGarageACH50)
      @infiltrationLivingSpaceACH50 = infiltrationLivingSpaceACH50
      @infiltrationShelterCoefficient = infiltrationShelterCoefficient
      @infiltrationLivingSpaceConstantACH = infiltrationLivingSpaceConstantACH
      @infiltrationGarageACH50 = infiltrationGarageACH50
    end

    attr_accessor(:assumed_inside_temp, :n_i, :A_o, :C_i, :Y_i, :flue_height, :S_wflue, :R_i, :X_i, :Z_f, :M_o, :M_i, :X_c, :F_i, :f_s, :stack_coef, :R_x, :Y_x, :X_s, :X_x, :f_w, :J_i, :f_w, :wind_coef, :default_rate, :rate_credit)

    def InfiltrationLivingSpaceACH50
      return @infiltrationLivingSpaceACH50
    end

    def InfiltrationLivingSpaceConstantACH
      return @infiltrationLivingSpaceConstantACH
    end

    def InfiltrationShelterCoefficient
      return @infiltrationShelterCoefficient
    end

    def InfiltrationGarageACH50
      return @infiltrationGarageACH50
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
    def initialize(mechVentType, mechVentInfilCreditForExistingHomes, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency)
      @mechVentType = mechVentType
      @mechVentInfilCreditForExistingHomes = mechVentInfilCreditForExistingHomes
      @mechVentTotalEfficiency = mechVentTotalEfficiency
      @mechVentFractionOfASHRAE = mechVentFractionOfASHRAE
      @mechVentHouseFanPower = mechVentHouseFanPower
      @mechVentSensibleEfficiency = mechVentSensibleEfficiency
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

    def MechVentSensibleEfficiency
      return @mechVentSensibleEfficiency
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
    attr_accessor(:num_bedrooms, :finished_floor_area, :num_bathrooms, :above_grade_finished_floor_area, :building_height, :stories, :window_area)
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
    attr_accessor(:MechanicalVentilationEnergy, :MechanicalVentilation, :BathExhaust, :ClothesDryerExhaust, :RangeHood, :NatVentProbability, :NatVentAvailability, :NatVentTemp)
  end

  class HeatingSetpoint
    def initialize
    end
    attr_accessor(:HeatingSetpointWeekday, :HeatingSetpointWeekend)
  end

  class CoolingSetpoint
    def initialize
    end
    attr_accessor(:CoolingSetpointWeekday, :CoolingSetpointWeekend)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessAirflow"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Air Leakage

    #make a choice argument for model objects
    zone_display_names = OpenStudio::StringVector.new
	
    #get all thermal zones in model
    #zone_args = workspace.getObjectsByType("Zone".to_IddObjectType)
    #zone_args.each do |zone_arg|
    #  zone_arg_name = zone_arg.getString(0) # Name
    #  zone_display_names << zone_arg_name.to_s
    #end
	# TODO: figure out why in spreadsheet workspace.getObjectsByType returns an empty list
    zone_display_names << "living"
	zone_display_names << "basement"
	zone_display_names << "crawl"
	zone_display_names << "attic"
	zone_display_names << "garage"
	zone_display_names << "NA"

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", zone_display_names, true)
    selected_living.setDisplayName("Which is the living space zone?")
    args << selected_living

    #make a double argument for infiltration of living space
    userdefined_inflivingspace = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinflivingspace", false)
    userdefined_inflivingspace.setDisplayName("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including finished attic).")
    userdefined_inflivingspace.setDefaultValue(7)
    args << userdefined_inflivingspace

    #make a double argument for constant infiltration of living space
    userdefined_constinflivingspace = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedconstinflivingspace", false)
    userdefined_constinflivingspace.setDisplayName("Air exchange rate, in natural Air Changes per Hour (ACH), for above-grade living space. Using this variable will override the AIM-2 calculation method with a constant air exchange rate.")
    userdefined_constinflivingspace.setDefaultValue(0)
    args << userdefined_constinflivingspace

    #make a double argument for shelter coefficient
    userdefined_infsheltercoef = OpenStudio::Ruleset::OSArgument::makeStringArgument("userdefinedinfsheltercoef", false)
    userdefined_infsheltercoef.setDisplayName("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees and obstructions.")
    userdefined_infsheltercoef.setDefaultValue("auto")
    args << userdefined_infsheltercoef

    #make a choice argument for garage
    selected_garage = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedgarage", zone_display_names, false)
    selected_garage.setDisplayName("Which is the garage zone?")
    selected_garage.setDefaultValue("NA")
    args << selected_garage

    #make a choice argument for fbsmt
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", zone_display_names, false)
    selected_fbsmt.setDisplayName("Which is the finished basement zone?")
    selected_fbsmt.setDefaultValue("NA")
    args << selected_fbsmt

    #make a double argument for infiltration of finished basement
    userdefined_inffbsmt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinffbsmt", false)
    userdefined_inffbsmt.setDisplayName("Constant air exchange rate, in Air Changes per Hour (ACH), for the finished basement.")
    userdefined_inffbsmt.setDefaultValue(0.0)
    args << userdefined_inffbsmt

    #make a choice argument for ufbsmt
    selected_ufbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedufbsmt", zone_display_names, false)
    selected_ufbsmt.setDisplayName("Which is the unfinished basement zone?")
    selected_ufbsmt.setDefaultValue("NA")
    args << selected_ufbsmt

    #make a double argument for infiltration of unfinished basement
    userdefined_infufbsmt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfufbsmt", false)
    userdefined_infufbsmt.setDisplayName("Constant air exchange rate, in Air Changes per Hour (ACH), for the unfinished basement. A value of 0.10 ACH or greater is recommended for modeling Heat Pump Water Heaters in unfinished basements.")
    userdefined_infufbsmt.setDefaultValue(0.1)
    args << userdefined_infufbsmt

    #make a choice argument for crawl
    selected_crawl = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedcrawl", zone_display_names, false)
    selected_crawl.setDisplayName("Which is the crawlspace zone?")
    selected_crawl.setDefaultValue("NA")
    args << selected_crawl

    #make a double argument for infiltration of crawlspace
    userdefined_infcrawl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfcrawl", false)
    userdefined_infcrawl.setDisplayName("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the crawlspace.")
    userdefined_infcrawl.setDefaultValue(2.0)
    args << userdefined_infcrawl

    #make a choice argument for unfinattic
    selected_unfinattic = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedunfinattic", zone_display_names, false)
    selected_unfinattic.setDisplayName("Which is the unfinished attic zone?")
    selected_unfinattic.setDefaultValue("NA")
    args << selected_unfinattic

    #make a double argument for infiltration of unfinished attic
    userdefined_infunfinattic = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfunfinattic", false)
    userdefined_infunfinattic.setDisplayName("Ratio of the effective leakage area (infiltration and/or ventilation) in the unfinished attic to the total floor area of the attic.")
    userdefined_infunfinattic.setDefaultValue(0.00333)
    args << userdefined_infunfinattic

    # Neighbors

    #make a double argument for neighbor offset
    userdefined_neighboroffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedneighboroffset", false)
    userdefined_neighboroffset.setDisplayName("The minimum distance between the simulated house and the neighboring houses (not including eaves) [ft].")
    userdefined_neighboroffset.setDefaultValue(0)
    args << userdefined_neighboroffset

    # Age of Home

    #make a double argument for existing or new construction
    userdefined_homeage = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhomeage", true)
    userdefined_homeage.setDisplayName("Age of home [yrs]. Enter 0 for new construction.")
    userdefined_homeage.setDefaultValue(0)
    args << userdefined_homeage

    # Terrain

    #make a choice arguments for terrain type
    terrain_types_names = OpenStudio::StringVector.new
    terrain_types_names << "ocean"
    terrain_types_names << "plains"
    terrain_types_names << "rural"
    terrain_types_names << "suburban"
    terrain_types_names << "city"
    selected_terraintype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedterraintype", terrain_types_names, true)
    selected_terraintype.setDisplayName("Site terrain type.")
    selected_terraintype.setDefaultValue("suburban")
    args << selected_terraintype

    # Mechanical Ventilation

    #make a choice argument for ventilation type
    ventilation_types_names = OpenStudio::StringVector.new
    ventilation_types_names << "none"
    ventilation_types_names << "exhaust"
    ventilation_types_names << "supply"
    ventilation_types_names << "balanced"
    selected_venttype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedventtype", ventilation_types_names, false)
    selected_venttype.setDisplayName("Ventilation strategy used (none, exhaust, supply, or balanced).")
    selected_venttype.setDefaultValue("exhaust")
    args << selected_venttype

    #make a bool argument for infiltration credit for existing homes
    selected_infilcredit = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinfilcredit",false)
    selected_infilcredit.setDisplayName("If True, the ASHRAE 62.2 infiltration credit will be included for buildings with infiltration that exceeds a default rate of 2 cfm per 100sqft of finished floor area.")
    selected_infilcredit.setDefaultValue(true)
    args << selected_infilcredit

    #make a double argument for total efficiency
    userdefined_totaleff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedtotaleff",false)
    userdefined_totaleff.setDisplayName("The net total energy (sensible plus latent, also called enthalpy) recovered by the supply airstream adjusted by electric consumption, case heat loss or heat gain, air leakage and airflow mass imbalance between the two airstreams, as a percent of the potential total energy that could be recovered plys the exhaust fan energy.")
    userdefined_totaleff.setDefaultValue(0)
    args << userdefined_totaleff

    #make a double argument for sensible efficiency
    userdefined_senseff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsenseff",false)
    userdefined_senseff.setDisplayName("The net sensible energy recovered by the supply airstream as adjusted by electric consumption, case heat loss or heat gain, air leakage, airflow mass imbalance between the two airstreams and the energy used for defrost (when running the Very Low Temperature Test), as a percent of the potential sensible energy that could be recovered plus the exhaust fan energy.")
    userdefined_senseff.setDefaultValue(0)
    args << userdefined_senseff

    #make a double argument for house fan power
    userdefined_fanpower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfanpower",false)
    userdefined_fanpower.setDisplayName("Fan power (in W) per delivered airflow rate (in cfm) of fan(s) providing whole house ventilation. If the house uses a balanced ventilation system thtere is assumed to be two fans operating at this efficiency.")
    userdefined_fanpower.setDefaultValue(0.3)
    args << userdefined_fanpower

    #make a double argument for fraction of ashrae
    userdefined_fracofashrae = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracofashrae",false)
    userdefined_fracofashrae.setDisplayName("Fraction of the ventilation rate (including any infiltration credit) specified by 2010 ASHRAE 62.2 that is desired in the bulding.")
    userdefined_fracofashrae.setDefaultValue(1.0)
    args << userdefined_fracofashrae

    #make a double argument for dryer exhaust
    userdefined_dryerexhaust = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineddryerexhaust",false)
    userdefined_dryerexhaust.setDisplayName("Rated flow capacity of the clothes dryer exhaust. This fan is assumed to run 60 min/day between 11am and 12pm.")
    userdefined_dryerexhaust.setDefaultValue(100.0)
    args << userdefined_dryerexhaust

    # Natural Ventilation

    #make a double argument for heating season setpoint offset
    userdefined_htgoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhtgoffset",false)
    userdefined_htgoffset.setDisplayName("The temperature offset below the hourly cooling setpoint, to which the living space is allowed to cool during months that are only in the heating season [F].")
    userdefined_htgoffset.setDefaultValue(1.0)
    args << userdefined_htgoffset

    #make a double argument for cooling season setpoint offset
    userdefined_clgoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedclgoffset",false)
    userdefined_clgoffset.setDisplayName("The temperature offset above the hourly heating setpoint, to which the living space is allowed to cool during months that are only in the cooling season [F].")
    userdefined_clgoffset.setDefaultValue(1.0)
    args << userdefined_clgoffset

    #make a double argument for overlap season setpoint offset
    userdefined_ovlpoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedovlpoffset",false)
    userdefined_ovlpoffset.setDisplayName("The temperature offset above the maximum heating setpoint, to which the living space is allowed to cool during months that are in both the heating season and cooling season [F].")
    userdefined_ovlpoffset.setDefaultValue(1.0)
    args << userdefined_ovlpoffset

    #make a bool argument for heating season
    selected_heatingssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedheatingssn",false)
    selected_heatingssn.setDisplayName("True if windows are allowed to be opened during months that are only in the heating season.")
    selected_heatingssn.setDefaultValue(true)
    args << selected_heatingssn

    #make a bool argument for cooling season
    selected_coolingssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedcoolingssn",false)
    selected_coolingssn.setDisplayName("True if windows are allowed to be opened during months that are only in the cooling season.")
    selected_coolingssn.setDefaultValue(true)
    args << selected_coolingssn

    #make a bool argument for overlap season
    selected_overlapssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedoverlapssn",false)
    selected_overlapssn.setDisplayName("True if windows are allowed to be opened during months that are in both the heating season and cooling season.")
    selected_overlapssn.setDefaultValue(true)
    args << selected_overlapssn

    #make a double argument for number weekdays
    userdefined_ventweekdays = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedventweekdays",false)
    userdefined_ventweekdays.setDisplayName("Number of weekdays in the week that natural ventilation can occur.")
    userdefined_ventweekdays.setDefaultValue(3.0)
    args << userdefined_ventweekdays

    #make a double argument for number weekend days
    userdefined_ventweekenddays = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedventweekenddays",false)
    userdefined_ventweekenddays.setDisplayName("Number of weekend days in the week that natural ventilation can occur.")
    userdefined_ventweekenddays.setDefaultValue(0.0)
    args << userdefined_ventweekenddays

    #make a double argument for fraction of windows open
    userdefined_fracwinopen = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracwinopen",false)
    userdefined_fracwinopen.setDisplayName("Specifies the fraction of the total openable window area in the building that is opened for ventilation.")
    userdefined_fracwinopen.setDefaultValue(0.33)
    args << userdefined_fracwinopen

    #make a double argument for fraction of window area open
    userdefined_fracwinareaopen = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracwinareaopen",false)
    userdefined_fracwinareaopen.setDisplayName("Specifies the fraction of total window area in the home that can be opened (e.g. typical sliding windows can be opened to half of their area.")
    userdefined_fracwinareaopen.setDefaultValue(0.2)
    args << userdefined_fracwinareaopen

    #make a double argument for humidity ratio
    userdefined_humratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhumratio",false)
    userdefined_humratio.setDisplayName("Outdoor air humidity ratio above which windows will not open for natural ventilation.")
    userdefined_humratio.setDefaultValue(0.0115)
    args << userdefined_humratio

    #make a double argument for relative humidity ratio
    userdefined_relhumratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrelhumratio",false)
    userdefined_relhumratio.setDisplayName("Outdoor air relative humidity (0-1) above which windows will not open for natural ventilation.")
    userdefined_relhumratio.setDefaultValue(0.7)
    args << userdefined_relhumratio

    # Geometry
    num_bedrooms = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("num_bedrooms",true)
    num_bedrooms.setDisplayName("Number of bedrooms.")
    num_bedrooms.setDefaultValue(3.0)
    args << num_bedrooms

    num_bathrooms = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("num_bathrooms",true)
    num_bathrooms.setDisplayName("Number of bathrooms.")
    num_bathrooms.setDefaultValue(2.0)
    args << num_bathrooms

    finished_floor_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("finished_floor_area",true)
    finished_floor_area.setDisplayName("Finished floor area [ft^2].")
    finished_floor_area.setDefaultValue(2700.0)
    args << finished_floor_area

    above_grade_finished_floor_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("above_grade_finished_floor_area",true)
    above_grade_finished_floor_area.setDisplayName("Above grade finished floor area [ft^2].")
    above_grade_finished_floor_area.setDefaultValue(2700.0)
    args << above_grade_finished_floor_area

    building_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("building_height",true)
    building_height.setDisplayName("Height of building [ft].")
    building_height.setDefaultValue(24.5)
    args << building_height

    stories = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("stories",true)
    stories.setDisplayName("Number of stories.")
    stories.setDefaultValue(2.0)
    args << stories

    window_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("window_area",true)
    window_area.setDisplayName("Window area [ft^2].")
    window_area.setDefaultValue(348.0)
    args << window_area

    livingspacevolume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("livingspacevolume",true)
    livingspacevolume.setDisplayName("Volume of living space [ft^3].")
    livingspacevolume.setDefaultValue(21600.0)
    args << livingspacevolume

    livingspaceheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("livingspaceheight",true)
    livingspaceheight.setDisplayName("Height of living space [ft].")
    livingspaceheight.setDefaultValue(16.0)
    args << livingspaceheight

    livingspacearea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("livingspacearea",true)
    livingspacearea.setDisplayName("Area of living space [ft^2].")
    livingspacearea.setDefaultValue(2700.0)
    args << livingspacearea

    uavolume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("uavolume",true)
    uavolume.setDisplayName("Volume of unfinished attic [ft^3].")
    uavolume.setDefaultValue(5250.0)
    args << uavolume

    uaheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("uaheight",true)
    uaheight.setDisplayName("Height of unfinished attic [ft].")
    uaheight.setDefaultValue(8.5)
    args << uaheight

    uaarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("uaarea",true)
    uaarea.setDisplayName("Area of unfinished attic [ft^2].")
    uaarea.setDefaultValue(1500.0)
    args << uaarea

    cvolume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cvolume",true)
    cvolume.setDisplayName("Volume of crawlspace [ft^3].")
    cvolume.setDefaultValue(4800.0)
    args << cvolume

    cheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cheight",true)
    cheight.setDisplayName("Height of crawlspace [ft].")
    cheight.setDefaultValue(4.0)
    args << cheight

    carea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("carea",true)
    carea.setDisplayName("Area of crawlspace [ft^2].")
    carea.setDefaultValue(1200.0)
    args << carea

    gvolume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gvolume",true)
    gvolume.setDisplayName("Volume of garage [ft^3].")
    gvolume.setDefaultValue(2400.0)
    args << gvolume

    gheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gheight",true)
    gheight.setDisplayName("Height of garage [ft].")
    gheight.setDefaultValue(8.0)
    args << gheight

    garea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("garea",true)
    garea.setDisplayName("Area of garage [ft^2].")
    garea.setDefaultValue(300.0)
    args << garea

    fbvolume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fbvolume",true)
    fbvolume.setDisplayName("Volume of finished basement [ft^3].")
    fbvolume.setDefaultValue(9600.0)
    args << fbvolume

    fbheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fbheight",true)
    fbheight.setDisplayName("Height of finished basement [ft].")
    fbheight.setDefaultValue(8.0)
    args << fbheight

    fbarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fbarea",true)
    fbarea.setDisplayName("Area of finished basement [ft^2].")
    fbarea.setDefaultValue(1200.0)
    args << fbarea

    ufbvolume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ufbvolume",true)
    ufbvolume.setDisplayName("Volume of unfinished basement [ft^3].")
    ufbvolume.setDefaultValue(9600.0)
    args << ufbvolume

    ufbheight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ufbheight",true)
    ufbheight.setDisplayName("Height of unfinished basement [ft].")
    ufbheight.setDefaultValue(8.0)
    args << ufbheight

    ufbarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ufbarea",true)
    ufbarea.setDisplayName("Area of unfinished basement [ft^2].")
    ufbarea.setDefaultValue(1200.0)
    args << ufbarea

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # Constants
    constants = Constants.new

    # Space Type
    selected_living = runner.getStringArgumentValue("selectedliving",user_arguments)
    selected_garage = runner.getStringArgumentValue("selectedgarage",user_arguments)
    selected_fbsmt = runner.getStringArgumentValue("selectedfbsmt",user_arguments)
    selected_ufbsmt = runner.getStringArgumentValue("selectedufbsmt",user_arguments)
    selected_crawl = runner.getStringArgumentValue("selectedcrawl",user_arguments)
    selected_unfinattic = runner.getStringArgumentValue("selectedunfinattic",user_arguments)

    infiltrationLivingSpaceACH50 = runner.getDoubleArgumentValue("userdefinedinflivingspace",user_arguments)
    infiltrationLivingSpaceConstantACH = runner.getDoubleArgumentValue("userdefinedconstinflivingspace",user_arguments)
    infiltrationShelterCoefficient = runner.getStringArgumentValue("userdefinedinfsheltercoef",user_arguments)
    crawlACH = runner.getDoubleArgumentValue("userdefinedinfcrawl",user_arguments)
    fbsmtACH = runner.getDoubleArgumentValue("userdefinedinffbsmt",user_arguments)
    ufbsmtACH = runner.getDoubleArgumentValue("userdefinedinfufbsmt",user_arguments)
    uaSLA = runner.getDoubleArgumentValue("userdefinedinfunfinattic",user_arguments)
    neighborOffset = runner.getDoubleArgumentValue("userdefinedneighboroffset",user_arguments)
    terrainType = runner.getStringArgumentValue("selectedterraintype",user_arguments)
    mechVentType = runner.getStringArgumentValue("selectedventtype",user_arguments)
    mechVentInfilCreditForExistingHomes = runner.getBoolArgumentValue("selectedinfilcredit",user_arguments)
    mechVentTotalEfficiency = runner.getDoubleArgumentValue("userdefinedtotaleff",user_arguments)
    mechVentSensibleEfficiency = runner.getDoubleArgumentValue("userdefinedsenseff",user_arguments)
    mechVentHouseFanPower = runner.getDoubleArgumentValue("userdefinedfanpower",user_arguments)
    mechVentFractionOfASHRAE = runner.getDoubleArgumentValue("userdefinedfracofashrae",user_arguments)
    if mechVentType == "none"
      mechVentFractionOfASHRAE = 0.0
      mechVentHouseFanPower = 0.0
      mechVentTotalEfficiency = 0.0
      mechVentSensibleEfficiency = 0.0
    end
    dryerExhaust = runner.getDoubleArgumentValue("userdefineddryerexhaust",user_arguments)
    has_cd = false
    electricEquipments = workspace.getObjectsByType("ElectricEquipment".to_IddObjectType)
    electricEquipments.each do |electricEquipment|
      electricEquipment_name = electricEquipment.getString(0).to_s # Name
      if electricEquipment_name.downcase.include? "clothes" and electricEquipment_name.downcase.include? "dryer"
        has_cd = true
      end
    end
    if not has_cd and dryerExhaust > 0
      runner.registerWarning("There is no clothes dryer but the clothes dryer exhaust specified is nonzero. Assuming clothes dryer exhaust is 0 cfm.")
      dryerExhaust = 0
    end

    ageOfHome = runner.getDoubleArgumentValue("userdefinedhomeage",user_arguments)

    natVentHtgSsnSetpointOffset = runner.getDoubleArgumentValue("userdefinedhtgoffset",user_arguments)
    natVentClgSsnSetpointOffset = runner.getDoubleArgumentValue("userdefinedclgoffset",user_arguments)
    natVentOvlpSsnSetpointOffset = runner.getDoubleArgumentValue("userdefinedovlpoffset",user_arguments)
    natVentHeatingSeason = runner.getBoolArgumentValue("selectedheatingssn",user_arguments)
    natVentCoolingSeason = runner.getBoolArgumentValue("selectedcoolingssn",user_arguments)
    natVentOverlapSeason = runner.getBoolArgumentValue("selectedoverlapssn",user_arguments)
    natVentNumberWeekdays = runner.getDoubleArgumentValue("userdefinedventweekdays",user_arguments)
    natVentNumberWeekendDays = runner.getDoubleArgumentValue("userdefinedventweekenddays",user_arguments)
    natVentFractionWindowsOpen = runner.getDoubleArgumentValue("userdefinedfracwinopen",user_arguments)
    natVentFractionWindowAreaOpen = runner.getDoubleArgumentValue("userdefinedfracwinareaopen",user_arguments)
    natVentMaxOAHumidityRatio = runner.getDoubleArgumentValue("userdefinedhumratio",user_arguments)
    natVentMaxOARelativeHumidity = runner.getDoubleArgumentValue("userdefinedrelhumratio",user_arguments)

    if infiltrationLivingSpaceACH50 == 0
      infiltrationLivingSpaceACH50 = nil
      infiltrationGarageACH50 = 15.0
    end
    if infiltrationLivingSpaceConstantACH == 0
      infiltrationLivingSpaceConstantACH = nil
      infiltrationGarageACH50 = infiltrationLivingSpaceACH50
    end
    if infiltrationGarageACH50 == nil
      infiltrationLivingSpaceACH50 = 0.0
      infiltrationGarageACH50 = 0.0
      infiltrationShelterCoefficient = constants.Auto
    end
    if neighborOffset == 0
      neighborOffset = nil
    end
    simTestSuiteBuilding = nil

    # Create the material class instances
    si = Infiltration.new(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationLivingSpaceConstantACH, infiltrationGarageACH50)
    living_space = LivingSpace.new
    garage = Garage.new
    finished_basement = FinBasement.new(fbsmtACH)
    space_unfinished_basement = UnfinBasement.new(ufbsmtACH)
    crawlspace = Crawl.new(crawlACH)
    unfinished_attic = UnfinAttic.new(uaSLA)
    wind_speed = WindSpeed.new
    neighbors = Neighbors.new(neighborOffset)
    site = Site.new(terrainType)
    vent = MechanicalVentilation.new(mechVentType, mechVentInfilCreditForExistingHomes, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency)
    misc = Misc.new(ageOfHome, simTestSuiteBuilding)
    clothes_dryer = ClothesDryer.new(dryerExhaust)
    geometry = Geometry.new
    nv = NaturalVentilation.new(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
    schedules = Schedules.new
    cooling_set_point = CoolingSetpoint.new
    heating_set_point = HeatingSetpoint.new

    zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    zones.each do |zone|
      zone_name = zone.getString(0).to_s # Name
      if zone_name == selected_living # tk need to figure out why idf doesn't get these values after OSM translation
        living_space.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        living_space.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        living_space.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        living_space.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == selected_garage
        garage.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        garage.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        garage.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        garage.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == selected_fbsmt
        finished_basement.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        finished_basement.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        finished_basement.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        finished_basement.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == selected_ufbsmt
        space_unfinished_basement.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        space_unfinished_basement.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        space_unfinished_basement.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        space_unfinished_basement.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == selected_crawl
        crawlspace.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        crawlspace.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        crawlspace.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        crawlspace.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == selected_unfinattic
        unfinished_attic.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        unfinished_attic.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        unfinished_attic.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        unfinished_attic.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      end
    end

    heating_set_point.HeatingSetpointWeekday = Array.new
    cooling_set_point.CoolingSetpointWeekday = Array.new
    schedule_days = workspace.getObjectsByType("Schedule:Day:Interval".to_IddObjectType)
    (1..12).to_a.each do |m|
      schedule_days.each do |schedule_day|
        schedule_day_name = schedule_day.getString(0).to_s # Name
        if schedule_day_name == "HeatingSetPointSchedule%02dd" % m.to_s
          if not schedule_day.getString(4).get.to_f == -1000
            if heating_set_point.HeatingSetpointWeekday.empty?
              (4..50).step(2) do |x|
                deg = OpenStudio::convert(schedule_day.getString(x).get.to_f,"C","F").get
                heating_set_point.HeatingSetpointWeekday << deg
              end
            end
          end
        end
        if schedule_day_name == "CoolingSetPointSchedule%02dd" % m.to_s
          if not schedule_day.getString(4).get.to_f == 1000
            if cooling_set_point.CoolingSetpointWeekday.empty?
              (4..50).step(2) do |x|
                deg = OpenStudio::convert(schedule_day.getString(x).get.to_f,"C","F").get
                cooling_set_point.CoolingSetpointWeekday << deg
              end
            end
          end
        end
      end
    end

    if heating_set_point.HeatingSetpointWeekday.empty?
      (0..23).to_a.each do |x|
        heating_set_point.HeatingSetpointWeekday << 1000
      end
    end
    if cooling_set_point.CoolingSetpointWeekday.empty?
      (0..23).to_a.each do |x|
        cooling_set_point.CoolingSetpointWeekday << 1000
      end
    end

    heating_set_point.HeatingSetpointWeekend = heating_set_point.HeatingSetpointWeekday
    cooling_set_point.CoolingSetpointWeekend = cooling_set_point.CoolingSetpointWeekday

    # temp code for testing
    geometry.num_bedrooms = runner.getDoubleArgumentValue("num_bedrooms",user_arguments)
    geometry.num_bathrooms = runner.getDoubleArgumentValue("num_bathrooms",user_arguments)
    geometry.finished_floor_area = runner.getDoubleArgumentValue("finished_floor_area",user_arguments)
    geometry.above_grade_finished_floor_area = runner.getDoubleArgumentValue("above_grade_finished_floor_area",user_arguments)
    geometry.building_height = runner.getDoubleArgumentValue("building_height",user_arguments)
    geometry.stories = runner.getDoubleArgumentValue("stories",user_arguments)
    geometry.window_area = runner.getDoubleArgumentValue("window_area",user_arguments)
    living_space.volume = runner.getDoubleArgumentValue("livingspacevolume",user_arguments)
    living_space.height = runner.getDoubleArgumentValue("livingspaceheight",user_arguments)
    living_space.area = runner.getDoubleArgumentValue("livingspacearea",user_arguments)
    unfinished_attic.volume = runner.getDoubleArgumentValue("uavolume",user_arguments)
    unfinished_attic.height = runner.getDoubleArgumentValue("uaheight",user_arguments)
    unfinished_attic.area = runner.getDoubleArgumentValue("uaarea",user_arguments)
    crawlspace.volume = runner.getDoubleArgumentValue("cvolume",user_arguments)
    crawlspace.height = runner.getDoubleArgumentValue("cheight",user_arguments)
    crawlspace.area = runner.getDoubleArgumentValue("carea",user_arguments)
    garage.volume = runner.getDoubleArgumentValue("gvolume",user_arguments)
    garage.height = runner.getDoubleArgumentValue("gheight",user_arguments)
    garage.area = runner.getDoubleArgumentValue("garea",user_arguments)
    finished_basement.volume = runner.getDoubleArgumentValue("fbvolume",user_arguments)
    finished_basement.height = runner.getDoubleArgumentValue("fbheight",user_arguments)
    finished_basement.area = runner.getDoubleArgumentValue("fbarea",user_arguments)
    space_unfinished_basement.volume = runner.getDoubleArgumentValue("ufbvolume",user_arguments)
    space_unfinished_basement.height = runner.getDoubleArgumentValue("ufbheight",user_arguments)
    space_unfinished_basement.area = runner.getDoubleArgumentValue("ufbarea",user_arguments)
    #

    # Create the sim object
    sim = Sim.new(workspace, runner)

    # Process the infiltration
    si, living_space, wind_speed, garage, fb, ub, cs, ua = sim._processInfiltration(si, living_space, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic, selected_garage, selected_fbsmt, selected_ufbsmt, selected_crawl, selected_unfinattic, wind_speed, neighbors, site, geometry)
    # Process the mechanical ventilation
    vent, schedules = sim._processMechanicalVentilation(si, vent, misc, clothes_dryer, geometry, living_space, schedules)
    # Process the natural ventilation
    nv, schedules = sim._processNaturalVentilation(nv, living_space, wind_speed, si, schedules, geometry, cooling_set_point, heating_set_point)

    ems = []

    # Schedules
    sch = "
    ScheduleTypeLimits,
      Fraction,                     !- Name
      0,                            !- Lower Limit Value
      1,                            !- Upper Limit Value
      Continuous;                   !- Numeric Type"
    ems << sch

    sch = "
    ScheduleTypeLimits,
      Temperature,                  !- Name
      -60,                          !- Lower Limit Value
      200,                          !- Upper Limit Value
      Continuous;                   !- Numeric Type"
    ems << sch

    sch = "
    Schedule:Constant,
      AlwaysOff,                    !- Name
      FRACTION,                     !- Schedule Type
      0;                            !- Hourly Value"
    ems << sch

    sch = "
    Schedule:Constant,
      AlwaysOn,                     !- Name
      FRACTION,                     !- Schedule Type
      1;                            !- Hourly Value"
    ems << sch

    schedules.MechanicalVentilationEnergy.each do |sch|
      ems << sch
    end
    schedules.MechanicalVentilation.each do |sch|
      ems << sch
    end
    schedules.BathExhaust.each do |sch|
      ems << sch
    end
    schedules.ClothesDryerExhaust.each do |sch|
      ems << sch
    end
    schedules.RangeHood.each do |sch|
      ems << sch
    end
    schedules.NatVentProbability.each do |sch|
      ems << sch
    end
    schedules.NatVentAvailability.each do |sch|
      ems << sch
    end
    schedules.NatVentTemp.each do |sch|
      ems << sch
    end

    # _processZoneLiving

    # Infiltration (Overridden by EMS. Values here are arbitrary)
    # Living Infiltration
    ems << "
    ZoneInfiltration:FlowCoefficient,
      Living Infiltration,                                        !- Name
      #{selected_living},                                         !- Zone Name
      AlwaysOn,                                                   !- Schedule Name
      1,                                                          !- Flow Coefficient {m/s-Pa^n}
      1,                                                          !- Stack Coefficient {Pa^n/K^n}
      1,                                                          !- Pressure Exponent
      1,                                                          !- Wind Coefficient {Pa^n-s^n/m^n}
      1;                                                          !- Shelter Factor (From Walker and Wilson (1998) (eq. 16))"

    # The ventilation flow rate from this object is overriden by EMS language
    # Natural Ventilation
    ems << "
    ZoneVentilation:DesignFlowRate,
      Natural Ventilation,                                        !- Name
      #{selected_living},                                         !- Zone Name
      NatVent,                                                    !- Schedule Name
      Flow/Zone,                                                  !- Design Flow Rate Calculation Method
      0.001,                                                      !- Design Flow rate {m^3/s}
      ,                                                           !- Flow Rate per Zone Floor Area {m/s-m}
      ,                                                           !- Flow Rate per Person {m/s-person}
      ,                                                           !- Air Changes per Hour {1/hr}
      Natural,                                                    !- Ventilation Type
      0,                                                          !- Fan Pressure Rise {Pa} (Fan Energy is accounted for in Fan:ZoneExhaust)
      1,                                                          !- Fan Total Efficiency
      1,                                                          !- Constant Term Coefficient
      0,                                                          !- Temperature Term Coefficient
      0,                                                          !- Velocity Term Coefficient
      0;                                                          !- Velocity Squared Term Coefficient"

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
      Living Infiltration,                                        !- Actuated Component Unique Name
      Zone Infiltration,                                          !- Actuated Component Type
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
          Set sft = #{((wind_speed.S_wo * (1.0 - inf.Y_i)) + (inf.S_wflue * (1.5 * inf.Y_i))) * living_space.f_t_SG},
          Set Qn = (((c*Cs*(DeltaT^n))^2)+(((c*Cw)*((sft*Vwind)^(2*n)))^2))^0.5,"
      else
        ems_program += "
          Set Qn = 0,"
      end
    elsif living_space.inf_method == constants.InfMethodRes
      ems_program += "
      Set Qn = #{living_space.ACH * OpenStudio::convert(living_space.volume,"ft^3","m^3").get / OpenStudio::convert(1.0,"hr","s").get},"
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
      Set NVArea = #{929.0304 * nv.area},
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
      AirflowCalculator,                                              !- Name
      BeginTimestepBeforePredictor,                                   !- EnergyPlus Model Calling Point
      InfiltrationProgram,                                            !- Program Name 1
      NaturalVentilationProgram,                                      !- Program Name 2
      LocalWindSpeedProgram;                                          !- Program Name 3"

    # Mechanical Ventilation
    if vent.MechVentType == constants.VentTypeBalanced # tk will need to complete _processSystemVentilationNodes for this to work

      ems << "
      Fan:OnOff,
        ERV Supply Fan,                                                               !- Name
        AlwaysOn,                                                                     !- Availability Schedule Name
        #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get}, !- Fan Efficiency
        300,                                                                          !- Pressure Rise {Pa}
        #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},         !- Maximum Flow rate {m^3/s}
        1,                                                                            !- Motor Efficiency
        1,                                                                            !- Motor in Airstream Fraction
        ERV Supply Fan Inlet Node,                                                    !- Air Inlet Node Name
        ERV Supply Fan Outlet Node,                                                   !- Air Outlet Node Name
        Fan-EIR-fPLR,                                                                 !- Fan Power Ratio Function of Speed Ratio Curve Name
        ,                                                                             !- Fan Efficiency Ratio Function of Speed Ratio Curve Name
        VentFans;                                                                     !- End-Use Subcategory"

      # tk Fan-EIR-fPLR has not been added so does not show up in IDF (does it need to?)

      ems << "
      Fan:OnOff,
        ERV Exhaust Fan,                                                              !- Name
        AlwaysOn,                                                                     !- Availability Schedule Name
        #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get}, !- Fan Efficiency
        300,                                                                          !- Pressure Rise {Pa}
        #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},         !- Maximum Flow rate {m^3/s}
        1,                                                                            !- Motor Efficiency
        0,                                                                            !- Motor in Airstream Fraction
        ERV Exhaust Fan Inlet Node,                                                   !- Air Inlet Node Name
        ERV Exhaust Fan Outlet Node,                                                  !- Air Outlet Node Name
        Fan-EIR-fPLR,                                                                 !- Fan Power Ratio Function of Speed Ratio Curve Name
        ,                                                                             !- Fan Efficiency Ratio Function of Speed Ratio Curve Name
        VentFans;                                                                     !- End-Use Subcategory"

      # tk Fan-EIR-fPLR has not been added so does not show up in IDF (does it need to?)

      ems << "
      ZoneHVAC:EnergyRecoveryVentilator:Controller,
        ERV Controller,                                                         !- Name
        ,                                                                       !- Temperature High Limit {C}
        ,                                                                       !- Temperature Low Limit {C}
        ,                                                                       !- Enthalpy High Limit {J/kg}
        ,                                                                       !- Dewpoint Temperature Limit {C}
        ,                                                                       !- Electronic Enthalpy Limit Curve Name
        NoExhaustAirTemperatureLimit,                                           !- Exhaust Air Temperature Limit
        NoExhaustAirEnthalpyLimit,                                              !- Exhaust Air Enthalpy Limit
        AlwaysOff,                                                              !- Time of Day Economizer Flow Control Schedule Name
        No;                                                                     !- High Humidity Control Flag"

      ems << "
      OutdoorAir:Node,
        ERV Outside Air Inlet Node,                                             !- Name
        #{OpenStudio::convert(living_space.height,"ft","m").get / 2.0};         !- Height Above Ground"

      ems << "
      HeatExchanger:AirToAir:SensibleAndLatent,
        ERV Heat Exchanger,                                                     !- Name
        AlwaysOn,                                                               !- Availability Schedule Name
        #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},   !- Nominal Supply Air Flow Rate
        #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 100% Heating Air Flow
        #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 100% Heating Air Flow
        #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 75% Heating Air Flow
        #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 75% Heating Air Flow
        #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 100% Cooling Air Flow
        #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 100% Cooling Air Flow
        #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 75% Cooling Air Flow
        #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 75% Cooling Air Flow
        ERV Outside Air Inlet Node,                                             !- Supply Air Inlet Node Name
        ERV Supply Fan Inlet Node,                                              !- Supply Air Outlet Node Name
        Living Exhaust Node,                                                    !- Exhaust Air Inlet Node Name
        ERV Exhaust Fan Inlet Node;                                             !- Exhaust Air Outlet Node Name"

      ems << "
      ZoneHVAC:EnergyRecoveryVentilator,
        ERV,                                                                    !- Name
        AlwaysOn,                                                               !- Availability Schedule Name
        ERV Heat Exchanger,                                                     !- Heat Exchanger Name
        #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},   !- Supply Air Flow rate {m^3/s}
        #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},   !- Exhaust Air Flor rate {m^3/s}
        ERV Supply Fan,                                                         !- Supply Air Fan Name
        ERV Exhaust Fan,                                                        !- Exhaust Air Fan Name
        ERV Controller;                                                         !- Controller Name"

    end

    hasGarage = false
    hasFinishedBasement = false
    hasUnfinishedBasement = false
    hasCrawl = false
    hasUnfinAttic = false
    if not selected_garage == "NA"
      hasGarage = true
    end
    if not selected_fbsmt == "NA"
      hasFinishedBasement = true
    end
    if not selected_ufbsmt == "NA"
      hasUnfinishedBasement = true
    end
    if not selected_crawl == "NA"
      hasCrawl = true
    end
    if not selected_unfinattic == "NA"
      hasUnfinAttic = true
    end

    # _processZoneGarage
    if hasGarage
      if garage.SLA > 0
        # Infiltration
        ems << "
        ZoneInfiltration:EffectiveLeakageArea,
          GarageInfiltration,                                                         !- Name
          #{selected_garage},                                                         !- Zone Name
          AlwaysOn,                                                                   !- Schedule Name
          #{OpenStudio::convert(garage.ELA,"ft^2","cm^2").get * 10.0},                !- Effective Air Leakage Area {cm}
          #{0.001672 * garage.C_s_SG},                                                !- Stack Coefficient {(L/s)/(cm^4-K)}
          #{0.01 * garage.C_w_SG};                                                    !- Wind Coefficient {(L/s)/(cm^4-(m/s))}"
      end
    end

    # _processZoneFinishedBasement
    if hasFinishedBasement
      #--- Infiltration
      if fb.inf_method == constants.InfMethodRes
        if fb.ACH > 0
          ems << "
          ZoneInfiltration:DesignFlowRate,
            FBsmtInfiltration,                                                        !- Name
            #{selected_fbsmt},                                                        !- Zone Name
            AlwaysOn,                                                                 !- Schedule Name
            AirChanges/Hour,                                                          !- Design Flow Rate Calculation Method
            ,                                                                         !- Design Flow rate {m^3/s}
            ,                                                                         !- Flow per Zone Floor Area {m/s-m}
            ,                                                                         !- Flow per Exterior Surface Area {m/s-m}
            #{fb.ACH},                                                                !- Air Changes per Hour {1/hr}
            1,                                                                        !- Constant Term Coefficient
            0,                                                                        !- Temperature Term Coefficient
            0,                                                                        !- Velocity Term Coefficient
            0;                                                                        !- Velocity Squared Term Coefficient"
        end
      end
    end

    # _processZoneUnfinishedBasement
    if hasUnfinishedBasement
      #--- Infiltration
      if ub.inf_method == constants.InfMethodRes
        if ub.ACH > 0
          ems << "
          ZoneInfiltration:DesignFlowRate,
            UBsmtInfiltration,                                                        !- Name
            #{selected_ufbsmt},                                                       !- Zone Name
            AlwaysOn,                                                                 !- Schedule Name
            AirChanges/Hour,                                                          !- Design Flow Rate Calculation Method
            ,                                                                         !- Design Flow rate {m^3/s}
            ,                                                                         !- Flow per Zone Floor Area {m/s-m}
            ,                                                                         !- Flow per Exterior Surface Area {m/s-m}
            #{ub.ACH},                                                                !- Air Changes per Hour {1/hr}
            1,                                                                        !- Constant Term Coefficient
            0,                                                                        !- Temperature Term Coefficient
            0,                                                                        !- Velocity Term Coefficient
            0;                                                                        !- Velocity Squared Term Coefficient"
        end
      end
    end

    # _processZoneCrawlspace
    if hasCrawl
      #--- Infiltration
      ems << "
      ZoneInfiltration:DesignFlowRate,
        UBsmtInfiltration,                                                            !- Name
        #{selected_crawl},                                                            !- Zone Name
        AlwaysOn,                                                                     !- Schedule Name
        AirChanges/Hour,                                                              !- Design Flow Rate Calculation Method
        ,                                                                             !- Design Flow rate {m^3/s}
        ,                                                                             !- Flow per Zone Floor Area {m/s-m}
        ,                                                                             !- Flow per Exterior Surface Area {m/s-m}
        #{cs.ACH},                                                                    !- Air Changes per Hour {1/hr}
        1,                                                                            !- Constant Term Coefficient
        0,                                                                            !- Temperature Term Coefficient
        0,                                                                            !- Velocity Term Coefficient
        0;                                                                            !- Velocity Squared Term Coefficient"
    end

    # _processZoneUnfinishedAttic
    if hasUnfinAttic
      #--- Infiltration
      if ua.ELA > 0
        ems << "
        ZoneInfiltration:EffectiveLeakageArea,
        UAtcInfiltration,                                                             !- Name
        #{selected_unfinattic},                                                       !- Zone Name
        AlwaysOn,                                                                     !- Schedule Name
        #{OpenStudio::convert(ua.ELA,"ft^2","cm^2").get * 10.0},                      !- Effective Air Leakage Area {cm}
        #{0.001672 * ua.C_s_SG},                                                      !- Stack Coefficient {(L/s)/(cm^4-K)}
        #{0.01 * ua.C_w_SG};                                                          !- Wind Coefficient {(L/s)/(cm^4-(m/s))}"
      end
    end

    # _processSiteDescription
    ems << "
    Site:WeatherStation,
      #{OpenStudio::convert(wind_speed.height,"ft","m").get},                         !- Wind Sensor Height Above Ground {m}
      #{wind_speed.terrain_exponent},                                                 !- Wind Speed Profile Exponent
      #{OpenStudio::convert(wind_speed.boundary_layer_thickness,"ft","m").get},       !- Wind Speed Profile Boundary Layer Thickness {m}
      #{1.5};                                                                         !- Air Temperature Sensor Height Above Ground {m}"

    ems << "
    Site:HeightVariation,
      #{wind_speed.site_terrain_exponent},                                            !- Wind Speed Profile Exponent
      #{OpenStudio::convert(wind_speed.site_boundary_layer_thickness,"ft","m").get},  !- Wind Speed Profile Boundary Layer Thickness {m}
      #{0.0065};                                                                      !- Air Temperature Gradient Coefficient {K/m}"

    ems.each do |str|
      idfObject = OpenStudio::IdfObject::load(str)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      runner.registerInfo("Set object '#{str.split("\n")[1].gsub(",","")} - #{str.split("\n")[2].split(",")[0]}'")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessAirflow.new.registerWithApplication