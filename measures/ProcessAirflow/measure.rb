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
require "#{File.dirname(__FILE__)}/resources/constants"

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
    attr_accessor(:height, :terrain_multiplier, :terrain_exponent, :ashrae_terrain_thickness, :ashrae_terrain_exponent, :site_terrain_multiplier, :site_terrain_exponent, :ashrae_site_terrain_thickness, :ashrae_site_terrain_exponent, :S_wo, :shielding_coef)
  end

  class Neighbors
    def initialize(min_nonzero_offset)
      @min_nonzero_offset = min_nonzero_offset
    end

    def min_nonzero_offset
      return @min_nonzero_offset
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
    def initialize(mechVentType, mechVentInfilCreditForExistingHomes, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
      @mechVentType = mechVentType
      @mechVentInfilCreditForExistingHomes = mechVentInfilCreditForExistingHomes
      @mechVentTotalEfficiency = mechVentTotalEfficiency
      @mechVentFractionOfASHRAE = mechVentFractionOfASHRAE
      @mechVentHouseFanPower = mechVentHouseFanPower
      @mechVentSensibleEfficiency = mechVentSensibleEfficiency
	  @mechVentASHRAEStandard = mechVentASHRAEStandard
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
	
	def MechVentASHRAEStandard
	  return @mechVentASHRAEStandard
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
    def initialize(nbeds, nbaths)
	  @nbeds = nbeds
	  @nbaths = nbaths
    end
	
	attr_accessor(:finished_floor_area, :above_grade_finished_floor_area, :building_height, :stories, :window_area, :num_units)
	
	def num_bedrooms
	  return @nbeds
	end
	
	def num_bathrooms
	  return @nbaths
	end
    
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
    return "Set Residential Airflow"
  end
  
  def description
    return "This measure processes infiltration for the living space, garage, finished basement, unfinished basement, crawlspace, and unfinished attic. It also processes mechanical ventilation and natural ventilation for the living space."
  end
  
  def modeler_description
    return "Using EMS code, this measure processes the building's airflow (infiltration, mechanical ventilation, and natural ventilation). Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end     
  
  def get_least_neighbor_offset(workspace)
	neighborOffset = 10000
	surfaces = workspace.getObjectsByType("BuildingSurface:Detailed".to_IddObjectType)
	surfaces.each do |surface|
		next unless surface.getString(1).to_s == "Wall"
		vertices1 = []
		vertices1 << [surface.getString(10).get.to_f, surface.getString(11).get.to_f, surface.getString(12).get.to_f]
		vertices1 << [surface.getString(13).get.to_f, surface.getString(14).get.to_f, surface.getString(15).get.to_f]
		vertices1 << [surface.getString(16).get.to_f, surface.getString(17).get.to_f, surface.getString(18).get.to_f]
		begin
			vertices1 << [surface.getString(19).get.to_f, surface.getString(20).get.to_f, surface.getString(21).get.to_f]
		rescue
		end
		vertices1.each do |vertex1|
			shading_surfaces = workspace.getObjectsByType("Shading:Building:Detailed".to_IddObjectType)
			shading_surfaces.each do |shading_surface|
				next unless shading_surface.getString(0).to_s.downcase.include? "neighbor"
				vertices2 = []
				vertices2 << [shading_surface.getString(3).get.to_f, shading_surface.getString(4).get.to_f, shading_surface.getString(5).get.to_f]
				vertices2 << [shading_surface.getString(6).get.to_f, shading_surface.getString(7).get.to_f, shading_surface.getString(8).get.to_f]
				vertices2 << [shading_surface.getString(9).get.to_f, shading_surface.getString(10).get.to_f, shading_surface.getString(11).get.to_f]
				begin
					vertices2 << [shading_surface.getString(12).get.to_f, shading_surface.getString(13).get.to_f, shading_surface.getString(14).get.to_f]
				rescue
				end
				vertices2.each do |vertex2|
					if Math.sqrt((vertex2[0] - vertex1[0]) ** 2 + (vertex2[1] - vertex1[1]) ** 2 + (vertex2[2] - vertex1[2]) ** 2) < neighborOffset
						neighborOffset = Math.sqrt((vertex2[0] - vertex1[0]) ** 2 + (vertex2[1] - vertex1[1]) ** 2 + (vertex2[2] - vertex1[2]) ** 2)
					end								
				end
			end
		end
	end
	if neighborOffset == 10000
		neighborOffset = 0
	end
	return OpenStudio::convert(neighborOffset,"m","ft").get
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Air Leakage

    #make a double argument for infiltration of living space
    userdefined_inflivingspace = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinflivingspace", false)
    userdefined_inflivingspace.setDisplayName("Air Leakage: Above-Grade Living Space ACH50")
	userdefined_inflivingspace.setUnits("1/hr")
	userdefined_inflivingspace.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including finished attic).")
    userdefined_inflivingspace.setDefaultValue(7)
    args << userdefined_inflivingspace

    #make a double argument for constant infiltration of living space
    userdefined_constinflivingspace = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedconstinflivingspace", false)
    userdefined_constinflivingspace.setDisplayName("Air Leakage: Above-Grade Living Space Constant ACH")
	userdefined_constinflivingspace.setUnits("1/hr")
	userdefined_constinflivingspace.setDescription("Air exchange rate, in natural Air Changes per Hour (ACH), for above-grade living space. Using this variable will override the AIM-2 calculation method with a constant air exchange rate.")
    userdefined_constinflivingspace.setDefaultValue(0)
    args << userdefined_constinflivingspace

    #make a double argument for shelter coefficient
    userdefined_infsheltercoef = OpenStudio::Ruleset::OSArgument::makeStringArgument("userdefinedinfsheltercoef", false)
    userdefined_infsheltercoef.setDisplayName("Air Leakage: Shelter Coefficient")
	userdefined_infsheltercoef.setDescription("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees and obstructions.")
    userdefined_infsheltercoef.setDefaultValue("auto")
    args << userdefined_infsheltercoef

    #make a double argument for infiltration of finished basement
    userdefined_inffbsmt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinffbsmt", false)
    userdefined_inffbsmt.setDisplayName("Finished Basement: Constant ACH")
	userdefined_inffbsmt.setUnits("1/hr")
	userdefined_inffbsmt.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the finished basement.")
    userdefined_inffbsmt.setDefaultValue(0.0)
    args << userdefined_inffbsmt
	
    #make a double argument for infiltration of unfinished basement
    userdefined_infufbsmt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfufbsmt", false)
    userdefined_infufbsmt.setDisplayName("Unfinished Basement: Constant ACH")
	userdefined_infufbsmt.setUnits("1/hr")
	userdefined_infufbsmt.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the unfinished basement. A value of 0.10 ACH or greater is recommended for modeling Heat Pump Water Heaters in unfinished basements.")
    userdefined_infufbsmt.setDefaultValue(0.1)
    args << userdefined_infufbsmt
	
    #make a double argument for infiltration of crawlspace
    userdefined_infcrawl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfcrawl", false)
    userdefined_infcrawl.setDisplayName("Crawlspace: Constant ACH")
	userdefined_infcrawl.setUnits("1/hr")
	userdefined_infcrawl.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the crawlspace.")
    userdefined_infcrawl.setDefaultValue(0.0)
    args << userdefined_infcrawl

    #make a double argument for infiltration of unfinished attic
    userdefined_infunfinattic = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfunfinattic", false)
    userdefined_infunfinattic.setDisplayName("Unfinished Attic: SLA")
	userdefined_infunfinattic.setDescription("Ratio of the effective leakage area (infiltration and/or ventilation) in the unfinished attic to the total floor area of the attic.")
    userdefined_infunfinattic.setDefaultValue(0.00333)
    args << userdefined_infunfinattic

    # Age of Home

    #make a double argument for existing or new construction
    userdefined_homeage = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhomeage", true)
    userdefined_homeage.setDisplayName("Age of Home")
	userdefined_homeage.setUnits("yrs")
	userdefined_homeage.setDescription("Age of home [Enter 0 for New Construction].")
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
    selected_terraintype.setDisplayName("Site Terrain")
	selected_terraintype.setDescription("The terrain of the site.")
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
    selected_venttype.setDisplayName("Mechanical Ventilation: Ventilation Type")
    selected_venttype.setDefaultValue("exhaust")
    args << selected_venttype

    #make a bool argument for infiltration credit for existing homes
    selected_infilcredit = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinfilcredit",false)
    selected_infilcredit.setDisplayName("Mechanical Ventilation: Include Infil Credit for Existing Homes")
	selected_infilcredit.setDescription("If True, the ASHRAE 62.2 infiltration credit will be included for buildings with infiltration that exceeds a default rate of 2 cfm per 100sqft of finished floor area.")
    selected_infilcredit.setDefaultValue(true)
    args << selected_infilcredit

    #make a double argument for total efficiency
    userdefined_totaleff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedtotaleff",false)
    userdefined_totaleff.setDisplayName("Mechanical Ventilation: Total Recovery Efficiency")
	userdefined_totaleff.setDescription("The net total energy (sensible plus latent, also called enthalpy) recovered by the supply airstream adjusted by electric consumption, case heat loss or heat gain, air leakage and airflow mass imbalance between the two airstreams, as a percent of the potential total energy that could be recovered plys the exhaust fan energy.")
    userdefined_totaleff.setDefaultValue(0)
    args << userdefined_totaleff

    #make a double argument for sensible efficiency
    userdefined_senseff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsenseff",false)
    userdefined_senseff.setDisplayName("Mechanical Ventilation: Sensible Recovery Efficiency")
	userdefined_senseff.setDescription("The net sensible energy recovered by the supply airstream as adjusted by electric consumption, case heat loss or heat gain, air leakage, airflow mass imbalance between the two airstreams and the energy used for defrost (when running the Very Low Temperature Test), as a percent of the potential sensible energy that could be recovered plus the exhaust fan energy.")
    userdefined_senseff.setDefaultValue(0)
    args << userdefined_senseff

    #make a double argument for house fan power
    userdefined_fanpower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfanpower",false)
    userdefined_fanpower.setDisplayName("Mechanical Ventilation: Fan Power")
	userdefined_fanpower.setUnits("W/cfm")
	userdefined_fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of fan(s) providing whole house ventilation. If the house uses a balanced ventilation system thtere is assumed to be two fans operating at this efficiency.")
    userdefined_fanpower.setDefaultValue(0.3)
    args << userdefined_fanpower

    #make a double argument for fraction of ashrae
    userdefined_fracofashrae = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracofashrae",false)
    userdefined_fracofashrae.setDisplayName("Mechanical Ventilation: Fraction of ASHRAE 62.2")
	userdefined_fracofashrae.setUnits("frac")
	userdefined_fracofashrae.setDescription("Fraction of the ventilation rate (including any infiltration credit) specified by ASHRAE 62.2 that is desired in the bulding.")
    userdefined_fracofashrae.setDefaultValue(1.0)
    args << userdefined_fracofashrae

    #make a choice argument for ashrae standard
    standard_types_names = OpenStudio::StringVector.new
    standard_types_names << "2010"
    standard_types_names << "2013"
	
    #make a double argument for ashrae standard
    selected_ashraestandard = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedashraestandard", standard_types_names, false)
    selected_ashraestandard.setDisplayName("Mechanical Ventilation: ASHRAE 62.2 Standard")
	selected_ashraestandard.setDescription("Specifies which version (year) of the ASHRAE 62.2 Standard should be used.")
    selected_ashraestandard.setDefaultValue("2010")
    args << selected_ashraestandard	

    #make a double argument for dryer exhaust
    userdefined_dryerexhaust = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineddryerexhaust",false)
    userdefined_dryerexhaust.setDisplayName("Clothes Dryer: Exhaust")
	userdefined_dryerexhaust.setUnits("cfm")
	userdefined_dryerexhaust.setDescription("Rated flow capacity of the clothes dryer exhaust. This fan is assumed to run 60 min/day between 11am and 12pm.")
    userdefined_dryerexhaust.setDefaultValue(100.0)
    args << userdefined_dryerexhaust

    # Natural Ventilation

    #make a double argument for heating season setpoint offset
    userdefined_htgoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhtgoffset",false)
    userdefined_htgoffset.setDisplayName("Natural Ventilation: Heating Season Setpoint Offset")
	userdefined_htgoffset.setUnits("degrees F")
	userdefined_htgoffset.setDescription("The temperature offset below the hourly cooling setpoint, to which the living space is allowed to cool during months that are only in the heating season.")
    userdefined_htgoffset.setDefaultValue(1.0)
    args << userdefined_htgoffset

    #make a double argument for cooling season setpoint offset
    userdefined_clgoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedclgoffset",false)
    userdefined_clgoffset.setDisplayName("Natural Ventilation: Cooling Season Setpoint Offset")
	userdefined_clgoffset.setUnits("degrees F")
	userdefined_clgoffset.setDescription("The temperature offset above the hourly heating setpoint, to which the living space is allowed to cool during months that are only in the cooling season.")
    userdefined_clgoffset.setDefaultValue(1.0)
    args << userdefined_clgoffset

    #make a double argument for overlap season setpoint offset
    userdefined_ovlpoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedovlpoffset",false)
    userdefined_ovlpoffset.setDisplayName("Natural Ventilation: Overlap Season Setpoint Offset")
	userdefined_ovlpoffset.setUnits("degrees F")
	userdefined_ovlpoffset.setDescription("The temperature offset above the maximum heating setpoint, to which the living space is allowed to cool during months that are in both the heating season and cooling season.")
    userdefined_ovlpoffset.setDefaultValue(1.0)
    args << userdefined_ovlpoffset

    #make a bool argument for heating season
    selected_heatingssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedheatingssn",false)
    selected_heatingssn.setDisplayName("Natural Ventilation: Heating Season")
	selected_heatingssn.setDescription("True if windows are allowed to be opened during months that are only in the heating season.")
    selected_heatingssn.setDefaultValue(true)
    args << selected_heatingssn

    #make a bool argument for cooling season
    selected_coolingssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedcoolingssn",false)
    selected_coolingssn.setDisplayName("Natural Ventilation: Cooling Season")
	selected_coolingssn.setDescription("True if windows are allowed to be opened during months that are only in the cooling season.")
    selected_coolingssn.setDefaultValue(true)
    args << selected_coolingssn

    #make a bool argument for overlap season
    selected_overlapssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedoverlapssn",false)
    selected_overlapssn.setDisplayName("Natural Ventilation: Overlap Season")
	selected_overlapssn.setDescription("True if windows are allowed to be opened during months that are in both the heating season and cooling season.")
    selected_overlapssn.setDefaultValue(true)
    args << selected_overlapssn

    #make a double argument for number weekdays
    userdefined_ventweekdays = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedventweekdays",false)
    userdefined_ventweekdays.setDisplayName("Natural Ventilation: Number Weekdays")
	userdefined_ventweekdays.setDescription("Number of weekdays in the week that natural ventilation can occur.")
    userdefined_ventweekdays.setDefaultValue(3.0)
    args << userdefined_ventweekdays

    #make a double argument for number weekend days
    userdefined_ventweekenddays = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedventweekenddays",false)
    userdefined_ventweekenddays.setDisplayName("Natural Ventilation: Number Weekend Days")
	userdefined_ventweekenddays.setDescription("Number of weekend days in the week that natural ventilation can occur.")
    userdefined_ventweekenddays.setDefaultValue(0.0)
    args << userdefined_ventweekenddays

    #make a double argument for fraction of windows open
    userdefined_fracwinopen = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracwinopen",false)
    userdefined_fracwinopen.setDisplayName("Natural Ventilation: Fraction of Openable Windows Open")
	userdefined_fracwinopen.setUnits("frac")
	userdefined_fracwinopen.setDescription("Specifies the fraction of the total openable window area in the building that is opened for ventilation.")
    userdefined_fracwinopen.setDefaultValue(0.33)
    args << userdefined_fracwinopen

    #make a double argument for fraction of window area open
    userdefined_fracwinareaopen = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracwinareaopen",false)
    userdefined_fracwinareaopen.setDisplayName("Natural Ventilation: Fraction Window Area Openable")
	userdefined_fracwinareaopen.setUnits("frac")
	userdefined_fracwinareaopen.setDescription("Specifies the fraction of total window area in the home that can be opened (e.g. typical sliding windows can be opened to half of their area).")
    userdefined_fracwinareaopen.setDefaultValue(0.2)
    args << userdefined_fracwinareaopen

    #make a double argument for humidity ratio
    userdefined_humratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhumratio",false)
    userdefined_humratio.setDisplayName("Natural Ventilation: Max OA Humidity Ratio")
	userdefined_humratio.setUnits("frac")
	userdefined_humratio.setDescription("Outdoor air humidity ratio above which windows will not open for natural ventilation.")
    userdefined_humratio.setDefaultValue(0.0115)
    args << userdefined_humratio

    #make a double argument for relative humidity ratio
    userdefined_relhumratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrelhumratio",false)
    userdefined_relhumratio.setDisplayName("Natural Ventilation: Max OA Relative Humidity")
	userdefined_relhumratio.setUnits("frac")
	userdefined_relhumratio.setDescription("Outdoor air relative humidity (0-1) above which windows will not open for natural ventilation.")
    userdefined_relhumratio.setDefaultValue(0.7)
    args << userdefined_relhumratio

    # Geometry
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

    #make a choice argument for living thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if not thermal_zone_args.include?(Constants.LivingZone)
        thermal_zone_args << Constants.LivingZone
    end
    living_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_thermal_zone", thermal_zone_args, true)
    living_thermal_zone.setDisplayName("Living thermal zone")
    living_thermal_zone.setDescription("Select the living thermal zone")
    living_thermal_zone.setDefaultValue(Constants.LivingZone)
    args << living_thermal_zone		
	
    #make a choice argument for garage thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if not thermal_zone_args.include?(Constants.GarageZone)
        thermal_zone_args << Constants.GarageZone
    end
    garage_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("garage_thermal_zone", thermal_zone_args, true)
    garage_thermal_zone.setDisplayName("Garage thermal zone")
    garage_thermal_zone.setDescription("Select the garage thermal zone")
    garage_thermal_zone.setDefaultValue(Constants.GarageZone)
    args << garage_thermal_zone	

    #make a choice argument for finished basement thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if not thermal_zone_args.include?(Constants.FinishedBasementZone)
        thermal_zone_args << Constants.FinishedBasementZone
    end
    fbasement_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_thermal_zone", thermal_zone_args, true)
    fbasement_thermal_zone.setDisplayName("Finished Basement thermal zone")
    fbasement_thermal_zone.setDescription("Select the finished basement thermal zone")
    fbasement_thermal_zone.setDefaultValue(Constants.FinishedBasementZone)
    args << fbasement_thermal_zone	

    #make a choice argument for unfinished basement thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if not thermal_zone_args.include?(Constants.UnfinishedBasementZone)
        thermal_zone_args << Constants.UnfinishedBasementZone
    end
    ufbasement_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("ufbasement_thermal_zone", thermal_zone_args, true)
    ufbasement_thermal_zone.setDisplayName("Unfinished Basement thermal zone")
    ufbasement_thermal_zone.setDescription("Select the unfinished basement thermal zone")
    ufbasement_thermal_zone.setDefaultValue(Constants.UnfinishedBasementZone)
    args << ufbasement_thermal_zone	

    #make a choice argument for crawl thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if not thermal_zone_args.include?(Constants.CrawlZone)
        thermal_zone_args << Constants.CrawlZone
    end
    crawl_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("crawl_thermal_zone", thermal_zone_args, true)
    crawl_thermal_zone.setDisplayName("Crawlspace thermal zone")
    crawl_thermal_zone.setDescription("Select the crawlspace thermal zone")
    crawl_thermal_zone.setDefaultValue(Constants.CrawlZone)
    args << crawl_thermal_zone	
	
    #make a choice argument for ufattic thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if not thermal_zone_args.include?(Constants.UnfinishedAtticZone)
        thermal_zone_args << Constants.UnfinishedAtticZone
    end
    ufattic_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("ufattic_thermal_zone", thermal_zone_args, true)
    ufattic_thermal_zone.setDisplayName("Unfinished Attic thermal zone")
    ufattic_thermal_zone.setDescription("Select the unfinished attic thermal zone")
    ufattic_thermal_zone.setDefaultValue(Constants.UnfinishedAtticZone)
    args << ufattic_thermal_zone		
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # Zones
	living_thermal_zone_r = runner.getStringArgumentValue("living_thermal_zone",user_arguments)
	living_thermal_zone = HelperMethods.get_thermal_zone_from_string_from_idf(workspace, living_thermal_zone_r, runner, false)
    if living_thermal_zone.nil?
        return false
    end
	garage_thermal_zone_r = runner.getStringArgumentValue("garage_thermal_zone",user_arguments)
	garage_thermal_zone = HelperMethods.get_thermal_zone_from_string_from_idf(workspace, garage_thermal_zone_r, runner, false)
	fbasement_thermal_zone_r = runner.getStringArgumentValue("fbasement_thermal_zone",user_arguments)
	fbasement_thermal_zone = HelperMethods.get_thermal_zone_from_string_from_idf(workspace, fbasement_thermal_zone_r, runner, false)
	ufbasement_thermal_zone_r = runner.getStringArgumentValue("ufbasement_thermal_zone",user_arguments)
	ufbasement_thermal_zone = HelperMethods.get_thermal_zone_from_string_from_idf(workspace, ufbasement_thermal_zone_r, runner, false)
	crawl_thermal_zone_r = runner.getStringArgumentValue("crawl_thermal_zone",user_arguments)
	crawl_thermal_zone = HelperMethods.get_thermal_zone_from_string_from_idf(workspace, crawl_thermal_zone_r, runner, false)
	ufattic_thermal_zone_r = runner.getStringArgumentValue("ufattic_thermal_zone",user_arguments)
	ufattic_thermal_zone = HelperMethods.get_thermal_zone_from_string_from_idf(workspace, ufattic_thermal_zone_r, runner, false)

    # Remove existing airflow objects
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["NatVentProbability"], "Schedule:Constant", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["MechanicalVentilationEnergyWk", "MechanicalVentilationWk", "BathExhaustWk", "ClothesDryerExhaustWk", "RangeHoodWk", "NatVentOffSeason-Week", "NatVent-Week", "NatVentClgSsnTempWeek", "NatVentHtgSsnTempWeek", "NatVentOvlpSsnTempWeek"], "Schedule:Week:Compact", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["MechanicalVentilationEnergy", "MechanicalVentilation", "BathExhaust", "ClothesDryerExhaust", "RangeHood", "NatVent", "NatVentTemp"], "Schedule:Year", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["MechanicalVentilationDay", "MechanicalVentilationEnergyDay", "BathExhaustDay", "ClothesDryerExhaustDay", "RangeHoodDay", "NatVentOn-Day", "NatVentOff-Day", "NatVentHtgSsnTempWkDay", "NatVentHtgSsnTempWkEnd", "NatVentClgSsnTempWkDay", "NatVentClgSsnTempWkEnd", "NatVentOvlpSsnTempWkDay", "NatVentOvlpSsnTempWkEnd", "NatVentOvlpSsnTempWkEnd"], "Schedule:Day:Hourly", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Living Infiltration"], "ZoneInfiltration:FlowCoefficient", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Natural Ventilation"], "ZoneVentilation:DesignFlowRate", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Tout", "Hout", "Pbar", "Tin", "Phiin", "Win", "Wout", "Vwind", "WH_sch", "Range_sch", "Bath_sch", "Clothes_dryer_sch", "NVAvail", "NVSP"], "EnergyManagementSystem:Sensor", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["NatVentFlow", "InfilFlow"], "EnergyManagementSystem:Actuator", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["InfiltrationProgram", "NaturalVentilationProgram"], "EnergyManagementSystem:Program", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Zone Infil/MechVent Flow Rate", "Whole House Fan Vent Flow Rate", "Range Hood Fan Vent Flow Rate", "Bath Exhaust Fan Vent Flow Rate", "Clothes Dryer Exhaust Fan Vent Flow Rate", "Local Wind Speed", "Zone Natural Ventilation Flow Rate"], "EnergyManagementSystem:OutputVariable", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["AirflowCalculator"], "EnergyManagementSystem:ProgramCallingManager", runner)
	workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["UAtcInfiltration"], "ZoneInfiltration:EffectiveLeakageArea", runner)
    
    infiltrationLivingSpaceACH50 = runner.getDoubleArgumentValue("userdefinedinflivingspace",user_arguments)
    infiltrationLivingSpaceConstantACH = runner.getDoubleArgumentValue("userdefinedconstinflivingspace",user_arguments)
    infiltrationShelterCoefficient = runner.getStringArgumentValue("userdefinedinfsheltercoef",user_arguments)
    crawlACH = runner.getDoubleArgumentValue("userdefinedinfcrawl",user_arguments)
    fbsmtACH = runner.getDoubleArgumentValue("userdefinedinffbsmt",user_arguments)
    ufbsmtACH = runner.getDoubleArgumentValue("userdefinedinfufbsmt",user_arguments)
    uaSLA = runner.getDoubleArgumentValue("userdefinedinfunfinattic",user_arguments)
    terrainType = runner.getStringArgumentValue("selectedterraintype",user_arguments)
    mechVentType = runner.getStringArgumentValue("selectedventtype",user_arguments)
    mechVentInfilCreditForExistingHomes = runner.getBoolArgumentValue("selectedinfilcredit",user_arguments)
    mechVentTotalEfficiency = runner.getDoubleArgumentValue("userdefinedtotaleff",user_arguments)
    mechVentSensibleEfficiency = runner.getDoubleArgumentValue("userdefinedsenseff",user_arguments)
    mechVentHouseFanPower = runner.getDoubleArgumentValue("userdefinedfanpower",user_arguments)
    mechVentFractionOfASHRAE = runner.getDoubleArgumentValue("userdefinedfracofashrae",user_arguments)
	mechVentASHRAEStandard = runner.getStringArgumentValue("selectedashraestandard",user_arguments)
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

    # Get number of bedrooms/bathrooms
    nbeds, nbaths = HelperMethods.get_bedrooms_bathrooms_from_idf(workspace, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end
	
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
      infiltrationShelterCoefficient = Constants.Auto
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
    neighbors = Neighbors.new(get_least_neighbor_offset(workspace))
    site = Site.new(terrainType)
    vent = MechanicalVentilation.new(mechVentType, mechVentInfilCreditForExistingHomes, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
    misc = Misc.new(ageOfHome, simTestSuiteBuilding)
    clothes_dryer = ClothesDryer.new(dryerExhaust)
    geometry = Geometry.new(nbeds, nbaths)
    nv = NaturalVentilation.new(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
    schedules = Schedules.new
    cooling_set_point = CoolingSetpoint.new
    heating_set_point = HeatingSetpoint.new

    zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    zones.each do |zone|
      zone_name = zone.getString(0).to_s # Name
      if zone_name == living_thermal_zone_r # tk need to figure out why idf doesn't get these values after OSM translation
        living_space.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        living_space.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        living_space.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        living_space.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == garage_thermal_zone_r
        garage.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        garage.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        garage.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        garage.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == fbasement_thermal_zone_r
        finished_basement.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        finished_basement.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        finished_basement.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        finished_basement.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == ufbasement_thermal_zone_r
        space_unfinished_basement.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        space_unfinished_basement.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        space_unfinished_basement.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        space_unfinished_basement.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == crawl_thermal_zone_r
        crawlspace.height = OpenStudio::convert(zone.getString(7).get.to_f,"m","ft").get # Ceiling Height {m}
        crawlspace.area = OpenStudio::convert(zone.getString(9).get.to_f,"m^2","ft^2").get # Floor Area {m2}
        crawlspace.volume = OpenStudio::convert(zone.getString(8).get.to_f,"m^3","ft^3").get # Volume {m3}
        crawlspace.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
      elsif zone_name == ufattic_thermal_zone_r
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
    geometry.finished_floor_area = runner.getDoubleArgumentValue("finished_floor_area",user_arguments)
    geometry.above_grade_finished_floor_area = runner.getDoubleArgumentValue("above_grade_finished_floor_area",user_arguments)
    geometry.building_height = runner.getDoubleArgumentValue("building_height",user_arguments)
    geometry.stories = runner.getDoubleArgumentValue("stories",user_arguments)
    geometry.window_area = runner.getDoubleArgumentValue("window_area",user_arguments)
	geometry.num_units = 1
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
    si, living_space, wind_speed, garage, fb, ub, cs, ua = sim._processInfiltration(si, living_space, garage, finished_basement, space_unfinished_basement, crawlspace, unfinished_attic, garage_thermal_zone, fbasement_thermal_zone, ufbasement_thermal_zone, crawl_thermal_zone, ufattic_thermal_zone, wind_speed, neighbors, site, geometry)
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
      #{living_thermal_zone_r},                                   !- Zone Name
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
      #{living_thermal_zone_r},                                   !- Zone Name
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
      #{living_thermal_zone_r},                                   !- Output:Variable or Output:Meter Index Key Name
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
      #{living_thermal_zone_r},                                   !- Output:Variable or Output:Meter Index Key Name
      Zone Mean Air Temperature;                                  !- Output:Variable or Output:Meter Index Key Name"

    # Phiin
    ems << "
    EnergyManagementSystem:Sensor,
      Phiin,                                                      !- Name
      #{living_thermal_zone_r},                                   !- Output:Variable or Output:Meter Index Key Name
      Zone Air Relative Humidity;                                 !- Output:Variable or Output:Meter Index Key Name"	  
	  
    # Win
    ems << "
    EnergyManagementSystem:Sensor,
      Win,                                                        !- Name
      #{living_thermal_zone_r},                                   !- Output:Variable or Output:Meter Index Key Name
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
      InfiltrationProgram,                                        !- Name
	    Set p_m = #{wind_speed.ashrae_terrain_exponent},
		Set p_s = #{wind_speed.ashrae_site_terrain_exponent},
		Set s_m = #{wind_speed.ashrae_terrain_thickness},
		Set s_s = #{wind_speed.ashrae_site_terrain_thickness},
		Set z_m = #{OpenStudio::convert(wind_speed.height,"ft","m").get},
		Set z_s = #{OpenStudio::convert(living_space.height,"ft","m").get},
		Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s)),
		Set VwindL = (f_t*Vwind),"
    if living_space.inf_method == Constants.InfMethodASHRAE
      if living_space.SLA > 0
        inf = si
        ems_program += "
          Set Tdiff = Tin - Tout,
          Set DeltaT = @Abs Tdiff,
          Set c = #{(OpenStudio::convert(inf.C_i,"cfm","m^3/s").get / (249.1 ** inf.n_i))},
          Set Cs = #{inf.stack_coef * (448.4 ** inf.n_i)},
          Set Cw = #{inf.wind_coef * (1246.0 ** inf.n_i)},
          Set n = #{inf.n_i},
          Set sft = (f_t*#{(((wind_speed.S_wo * (1.0 - inf.Y_i)) + (inf.S_wflue * (1.5 * inf.Y_i))))}),
          Set Qn = (((c*Cs*(DeltaT^n))^2)+(((c*Cw)*((sft*Vwind)^(2*n)))^2))^0.5,"
      else
        ems_program += "
          Set Qn = 0,"
      end
    elsif living_space.inf_method == Constants.InfMethodRes
      ems_program += "
      Set Qn = #{living_space.ACH * OpenStudio::convert(living_space.volume,"ft^3","m^3").get / OpenStudio::convert(1.0,"hr","s").get},"
    end

    ems_program += "
      Set Tdiff = Tin - Tout,
      Set DeltaT = @Abs Tdiff,"

    ems_program += "
      Set QWHV = WH_sch*#{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},
      Set Qrange = Range_sch*#{OpenStudio::convert(vent.range_hood_hour_avg_exhaust,"cfm","m^3/s").get},
      Set Qdryer = Clothes_dryer_sch*#{OpenStudio::convert(vent.clothes_dryer_hour_avg_exhaust,"cfm","m^3/s").get},
      Set Qbath = Bath_sch*#{OpenStudio::convert(vent.bathroom_hour_avg_exhaust,"cfm","m^3/s").get},
      Set QhpwhOut = 0,
      Set QhpwhIn = 0,
      Set QductsOut = DuctLeakExhaustFanEquivalent,
      Set QductsIn = DuctLeakSupplyFanEquivalent,"

    if vent.MechVentType == Constants.VentTypeBalanced
      ems_program += "
        Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut,          !- Exhaust flows
        Set Qin = QhpwhIn+QductsIn,                                 !- Supply flows
        Set Qu = (@Abs (Qout - Qin)),                               !- Unbalanced flow
        Set Qb = QWHV + (@Min Qout Qin),                            !- Balanced flow"
    else
      if vent.MechVentType == Constants.VentTypeExhaust
        ems_program += "
          Set Qout = QWHV+Qrange+Qbath+Qdryer+QhpwhOut+QductsOut,    !- Exhaust flows
          Set Qin = QhpwhIn+QductsIn,                                !- Supply flows
          Set Qu = (@Abs (Qout - Qin)),                              !- Unbalanced flow
          Set Qb = (@Min Qout Qin),                                  !- Balanced flow"
      else #vent.MechVentType == Constants.VentTypeSupply:
        ems_program += "
          Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut,         !- Exhaust flows
          Set Qin = QWHV+QhpwhIn+QductsIn,                            !- Supply flows
          Set Qu = @Abs (Qout - Qin),                                !- QductOA
          Set Qb = (@Min Qout Qin),                                  !- Balanced flow"
      end

      if vent.MechVentHouseFanPower != 0
        ems_program += "
          Set faneff_wh = #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get},      !- Fan Efficiency"
      else
        ems_program += "
          Set faneff_wh = 1,"
      end
      ems_program += "
        Set WholeHouseFanPowerOverride= (QWHV*300)/faneff_wh,"
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
      Set Q_acctd_for_elsewhere = QhpwhOut + QhpwhIn + QductsOut + QductsIn,
	  Set InfilFlow = (((Qu^2) + (Qn^2))^0.5) - Q_acctd_for_elsewhere,
	  Set InfilFlow = (@Max InfilFlow 0),
	  Set InfilFlow_display = (((Qu^2) + (Qn^2))^0.5) - Qu,
      Set InfMechVent = Qb + InfilFlow;"

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
      QWHV,                                                           !- EMS Variable Name
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
      InfiltrationProgram,                                            !- EMS Program or Subroutine Name
      m/s;                                                            !- Units"

    # Program

    # NaturalVentilationProgram
    ems << "
    EnergyManagementSystem:Program,
      NaturalVentilationProgram,                                      !- Name
      Set Tdiff = Tin - Tout,
      Set DeltaT = (@Abs Tdiff),
      Set Phiout = (@RhFnTdbWPb Tout Wout Pbar),
      Set Hin = (@HFnTdbRhPb Tin Phiin Pbar),
      Set NVArea = #{929.0304 * nv.area},
      Set Cs = #{0.001672 * nv.C_s},
      Set Cw = #{0.01 * nv.C_w},
      Set MaxNV = #{OpenStudio::convert(nv.max_flow_rate,"cfm","m^3/s").get},
      Set MaxHR = #{nv.NatVentMaxOAHumidityRatio},
      Set MaxRH = #{nv.NatVentMaxOARelativeHumidity},
      Set SGNV = (NVAvail*NVArea)*((((Cs*DeltaT)+(Cw*(Vwind^2)))^0.5)/1000),
      If (Wout < MaxHR) && (Phiout < MaxRH) && (Tin > NVSP),
        Set NVadj1 = (Tin - NVSP)/(Tin - Tout),
        Set NVadj2 = (@Min NVadj1 1),
        Set NVadj3 = (@Max NVadj2 0),
        Set NVadj = SGNV*NVadj3,
        Set NatVentFlow = (@Min NVadj MaxNV),
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
      NaturalVentilationProgram;                                      !- Program Name 2"

    # Mechanical Ventilation
    if vent.MechVentType == Constants.VentTypeBalanced # tk will need to complete _processSystemVentilationNodes for this to work

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
    if not garage_thermal_zone.nil?
      hasGarage = true
    end
    if not fbasement_thermal_zone.nil?
      hasFinishedBasement = true
    end
    if not ufbasement_thermal_zone.nil?
      hasUnfinishedBasement = true
    end
    if not crawl_thermal_zone.nil?
      hasCrawl = true
    end
    if not ufattic_thermal_zone.nil?
      hasUnfinAttic = true
    end

    # _processZoneGarage
    if hasGarage
      if garage.SLA > 0
        # Infiltration
        ems << "
        ZoneInfiltration:EffectiveLeakageArea,
          GarageInfiltration,                                                         !- Name
          #{garage_thermal_zone_r},                                                   !- Zone Name
          AlwaysOn,                                                                   !- Schedule Name
          #{OpenStudio::convert(garage.ELA,"ft^2","cm^2").get * 10.0},                !- Effective Air Leakage Area {cm}
          #{0.001672 * garage.C_s_SG},                                                !- Stack Coefficient {(L/s)/(cm^4-K)}
          #{0.01 * garage.C_w_SG};                                                    !- Wind Coefficient {(L/s)/(cm^4-(m/s))}"
      end
    end

    # _processZoneFinishedBasement
    if hasFinishedBasement
      #--- Infiltration
      if fb.inf_method == Constants.InfMethodRes
        if fb.ACH > 0
          ems << "
          ZoneInfiltration:DesignFlowRate,
            FBsmtInfiltration,                                                        !- Name
            #{fbasement_thermal_zone_r},                                              !- Zone Name
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
      if ub.inf_method == Constants.InfMethodRes
        if ub.ACH > 0
          ems << "
          ZoneInfiltration:DesignFlowRate,
            UBsmtInfiltration,                                                        !- Name
            #{ufbasement_thermal_zone_r},                                             !- Zone Name
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
        #{crawl_thermal_zone_r},                                                      !- Zone Name
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
        #{ufattic_thermal_zone_r},                                                    !- Zone Name
        AlwaysOn,                                                                     !- Schedule Name
        #{OpenStudio::convert(ua.ELA,"ft^2","cm^2").get * 10.0},                      !- Effective Air Leakage Area {cm}
        #{0.001672 * ua.C_s_SG},                                                      !- Stack Coefficient {(L/s)/(cm^4-K)}
        #{0.01 * ua.C_w_SG};                                                          !- Wind Coefficient {(L/s)/(cm^4-(m/s))}"
      end
    end

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