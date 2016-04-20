#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ProcessAirSourceHeatPump < OpenStudio::Ruleset::ModelUserScript

  class HeatPump
    def initialize(hpNumberSpeeds, hpCoolingEER, hpCoolingInstalledSEER, hpSupplyFanPowerInstalled, hpSupplyFanPowerRated, hpSHRRated, hpCapacityRatio, hpFanspeedRatioCooling, hpCondenserType, hpCrankcase, hpCrankcaseMaxT, hpEERCapacityDerateFactor, hpHeatingCOP, hpHeatingInstalledHSPF, hpFanspeedRatioHeating, hpMinT, hpCOPCapacityDerateFactor, hpRatedAirFlowRateCooling, hpRatedAirFlowRateHeating)
      @hpNumberSpeeds = hpNumberSpeeds
      @hpCoolingEER = hpCoolingEER
      @hpCoolingInstalledSEER = hpCoolingInstalledSEER
      @hpSupplyFanPowerInstalled = hpSupplyFanPowerInstalled
      @hpSupplyFanPowerRated = hpSupplyFanPowerRated
      @hpSHRRated = hpSHRRated
      @hpCapacityRatio = hpCapacityRatio
      @hpFanspeedRatioCooling = hpFanspeedRatioCooling
      @hpCondenserType = hpCondenserType
      @hpCrankcase = hpCrankcase
      @hpCrankcaseMaxT = hpCrankcaseMaxT
      @hpEERCapacityDerateFactor = hpEERCapacityDerateFactor
      @hpHeatingCOP = hpHeatingCOP
      @hpHeatingInstalledHSPF = hpHeatingInstalledHSPF
      @hpFanspeedRatioHeating = hpFanspeedRatioHeating
      @hpMinT = hpMinT
      @hpCOPCapacityDerateFactor = hpCOPCapacityDerateFactor
      @hpRatedAirFlowRateCooling = hpRatedAirFlowRateCooling
      @hpRatedAirFlowRateHeating = hpRatedAirFlowRateHeating
    end

    def HPNumberSpeeds
      return @hpNumberSpeeds
    end

    def HPCoolingEER
      return @hpCoolingEER
    end

    def HPCoolingInstalledSEER
      return @hpCoolingInstalledSEER
    end

    def HPSupplyFanPowerInstalled
      return @hpSupplyFanPowerInstalled
    end

    def HPSupplyFanPowerRated
      return @hpSupplyFanPowerRated
    end

    def HPSHRRated
      return @hpSHRRated
    end

    def HPCapacityRatio
      return @hpCapacityRatio
    end

    def HPFanspeedRatioCooling
      return @hpFanspeedRatioCooling
    end

    def HPCondenserType
      return @hpCondenserType
    end

    def HPCrankcase
      return @hpCrankcase
    end

    def HPCrankcaseMaxT
      return @hpCrankcaseMaxT
    end

    def HPEERCapacityDerateFactor
      return @hpEERCapacityDerateFactor
    end

    def HPHeatingCOP
      return @hpHeatingCOP
    end

    def HPHeatingInstalledHSPF
      return @hpHeatingInstalledHSPF
    end

    def HPFanspeedRatioHeating
      return @hpFanspeedRatioHeating
    end

    def HPMinT
      return @hpMinT
    end

    def HPCOPCapacityDerateFactor
      return @hpCOPCapacityDerateFactor
    end

    def HPRatedAirFlowRateCooling
      return @hpRatedAirFlowRateCooling
    end

    def HPRatedAirFlowRateHeating
      return @hpRatedAirFlowRateHeating
    end
  end

  class AirConditioner
    def initialize(acCoolingInstalledSEER)
      @acCoolingInstalledSEER = acCoolingInstalledSEER
    end

    attr_accessor(:hasIdealAC)

    def ACCoolingInstalledSEER
      return @acCoolingInstalledSEER
    end
  end

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :CFM_TON_Rated_Heat, :HeatingEIR, :HEAT_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Heating, :fanspeed_ratio_heating, :min_hp_temp, :max_defrost_temp, :COP_CapacityDerateFactor, :fan_power_rated, :htg_supply_air_temp, :supp_htg_max_supply_temp, :supp_htg_max_outdoor_temp)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Air Source Heat Pump"
  end
  
  def description
    return "This measure removes any existing HVAC components from the building and adds an air source heat pump along with an on/off supply fan to a unitary air loop."
  end
  
  def modeler_description
    return "This measure parses the OSM for the HeatingSeasonSchedule and CoolingSeasonSchedule. Any supply components or baseboard convective electrics are removed from any existing air loops or zones. Any existing air loops are also removed. A heating DX coil, cooling DX coil, electric supplemental heating coil, and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A single zone reheat setpoint manager is added to the supply outlet node, and a diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for ashp options
    hp_display_names = OpenStudio::StringVector.new
    hp_display_names << "SEER 8, 6.0 HSPF"
    hp_display_names << "SEER 10, 6.2 HSPF"
    hp_display_names << "SEER 13, 7.7 HSPF"
    hp_display_names << "SEER 14, 8.2 HSPF"
    hp_display_names << "SEER 15, 8.5 HSPF"
    hp_display_names << "SEER 16, 8.6 HSPF"
    hp_display_names << "SEER 17, 8.7 HSPF"
    hp_display_names << "SEER 18, 9.3 HSPF"
    hp_display_names << "SEER 19, 9.5 HSPF"
    hp_display_names << "SEER 22, 10 HSPF"

    #make a string argument for ashp options
    selected_hp = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedhp", hp_display_names, true)
    selected_hp.setDisplayName("Air Source Heat Pump: Installed SEER, Installed HSPF")
	  selected_hp.setUnits("Btu/W-h")
	  selected_hp.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump, and the installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    selected_hp.setDefaultValue("SEER 13, 7.7 HSPF")
    args << selected_hp

    #make a bool argument for whether the ashp is cold climate
    selected_cchp = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedcchp", true)
    selected_cchp.setDisplayName("Is Cold Climate")
    selected_cchp.setDescription("Specifies whether the heat pump is a so called 'cold climate heat pump'.")
    selected_cchp.setDefaultValue(false)
    args << selected_cchp    
    
    #make a choice argument for ashp cooling/heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end

    #make a string argument for ashp cooling/heating output capacity
    selected_hpcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedhpcap", cap_display_names, true)
    selected_hpcap.setDisplayName("Cooling/Heating Output Capacity")
    selected_hpcap.setDefaultValue("Autosize")
    args << selected_hpcap

    #make a choice argument for supplemental heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for supplemental heating output capacity
    selected_supcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedsupcap", cap_display_names, true)
    selected_supcap.setDisplayName("Supplemental Heating Output Capacity")
    selected_supcap.setDefaultValue("Autosize")
    args << selected_supcap 
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    selected_hp = runner.getStringArgumentValue("selectedhp",user_arguments)
    hpOutputCapacity = runner.getStringArgumentValue("selectedhpcap",user_arguments)
    if not hpOutputCapacity == "Autosize"
      hpOutputCapacity = OpenStudio::convert(hpOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
    end
    supplementalOutputCapacity = runner.getStringArgumentValue("selectedsupcap",user_arguments)
    if not supplementalOutputCapacity == "Autosize"
      supplementalOutputCapacity = OpenStudio::convert(supplementalOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end

    hpNumberSpeeds = {"SEER 8, 6.0 HSPF"=>1.0, "SEER 10, 6.2 HSPF"=>1.0, "SEER 13, 7.7 HSPF"=>1.0, "SEER 14, 8.2 HSPF"=>1.0, "SEER 15, 8.5 HSPF"=>1.0, "SEER 16, 8.6 HSPF"=>2.0, "SEER 17, 8.7 HSPF"=>2.0, "SEER 18, 9.3 HSPF"=>2.0, "SEER 19, 9.5 HSPF"=>2.0, "SEER 22, 10 HSPF"=>4.0}[selected_hp]
    hpCoolingEER = {"SEER 8, 6.0 HSPF"=>7.3, "SEER 10, 6.2 HSPF"=>8.9, "SEER 13, 7.7 HSPF"=>[11.4], "SEER 14, 8.2 HSPF"=>[12.2], "SEER 15, 8.5 HSPF"=>[12.7], "SEER 16, 8.6 HSPF"=>[13.1, 11.7], "SEER 17, 8.7 HSPF"=>[13.9, 12.8], "SEER 18, 9.3 HSPF"=>[14.5, 13.3], "SEER 19, 9.5 HSPF"=>[15.5, 13.8], "SEER 22, 10 HSPF"=> [17.4, 16.8, 14.3, 13.0]}[selected_hp]
    hpCoolingInstalledSEER = {"SEER 8, 6.0 HSPF"=>8.0, "SEER 10, 6.2 HSPF"=>10.0, "SEER 13, 7.7 HSPF"=>13.0, "SEER 14, 8.2 HSPF"=>14.0, "SEER 15, 8.5 HSPF"=>15.0, "SEER 16, 8.6 HSPF"=>16.0, "SEER 17, 8.7 HSPF"=>17.0, "SEER 18, 9.3 HSPF"=>18.0, "SEER 19, 9.5 HSPF"=>19.0, "SEER 22, 10 HSPF"=>22.0}[selected_hp]
    hpSupplyFanPowerInstalled = {"SEER 8, 6.0 HSPF"=>0.5, "SEER 10, 6.2 HSPF"=>0.5, "SEER 13, 7.7 HSPF"=>0.5, "SEER 14, 8.2 HSPF"=>0.5, "SEER 15, 8.5 HSPF"=>0.5, "SEER 16, 8.6 HSPF"=>0.3, "SEER 17, 8.7 HSPF"=>0.3, "SEER 18, 9.3 HSPF"=>0.3, "SEER 19, 9.5 HSPF"=>0.3, "SEER 22, 10 HSPF"=>0.3}[selected_hp]
    hpSupplyFanPowerRated = {"SEER 8, 6.0 HSPF"=>0.365, "SEER 10, 6.2 HSPF"=>0.365, "SEER 13, 7.7 HSPF"=>0.365, "SEER 14, 8.2 HSPF"=>0.365, "SEER 15, 8.5 HSPF"=>0.365, "SEER 16, 8.6 HSPF"=>0.14, "SEER 17, 8.7 HSPF"=>0.14, "SEER 18, 9.3 HSPF"=>0.14, "SEER 19, 9.5 HSPF"=>0.14, "SEER 22, 10 HSPF"=>0.14}[selected_hp]
    hpSHRRated = {"SEER 8, 6.0 HSPF"=>[0.73], "SEER 10, 6.2 HSPF"=>[0.73], "SEER 13, 7.7 HSPF"=>[0.73], "SEER 14, 8.2 HSPF"=>[0.73], "SEER 15, 8.5 HSPF"=>[0.73], "SEER 16, 8.6 HSPF"=>[0.71, 0.723], "SEER 17, 8.7 HSPF"=>[0.71, 0.724], "SEER 18, 9.3 HSPF"=>[0.71, 0.725], "SEER 19, 9.5 HSPF"=>[0.71, 0.725], "SEER 22, 10 HSPF"=>[0.84, 0.79, 0.76, 0.77]}[selected_hp]
    hpCapacityRatio = {"SEER 8, 6.0 HSPF"=>[1.0], "SEER 10, 6.2 HSPF"=>[1.0], "SEER 13, 7.7 HSPF"=>[1.0], "SEER 14, 8.2 HSPF"=>[1.0], "SEER 15, 8.5 HSPF"=>[1.0], "SEER 16, 8.6 HSPF"=>[0.72, 1.0], "SEER 17, 8.7 HSPF"=>[0.72, 1.0], "SEER 18, 9.3 HSPF"=>[0.72, 1.0], "SEER 19, 9.5 HSPF"=> [0.72, 1.0], "SEER 22, 10 HSPF"=>[0.49, 0.67, 1.0, 1.2]}[selected_hp]
    hpFanspeedRatioCooling = {"SEER 8, 6.0 HSPF"=>[1.0], "SEER 10, 6.2 HSPF"=>[1.0], "SEER 13, 7.7 HSPF"=>[1.0], "SEER 14, 8.2 HSPF"=>[1.0], "SEER 15, 8.5 HSPF"=>[1.0], "SEER 16, 8.6 HSPF"=>[0.86, 1.0], "SEER 17, 8.7 HSPF"=>[0.86, 1.0], "SEER 18, 9.3 HSPF"=>[0.86, 1.0], "SEER 19, 9.5 HSPF"=>[0.86, 1.0], "SEER 22, 10 HSPF"=>[0.7, 0.9, 1.0, 1.26]}[selected_hp]
    hpCondenserType = {"SEER 8, 6.0 HSPF"=>"aircooled", "SEER 10, 6.2 HSPF"=>"aircooled", "SEER 13, 7.7 HSPF"=>"aircooled", "SEER 14, 8.2 HSPF"=>"aircooled", "SEER 15, 8.5 HSPF"=>"aircooled", "SEER 16, 8.6 HSPF"=>"aircooled", "SEER 17, 8.7 HSPF"=>"aircooled", "SEER 18, 9.3 HSPF"=>"aircooled", "SEER 19, 9.5 HSPF"=>"aircooled", "SEER 22, 10 HSPF"=>"aircooled"}[selected_hp]
    hpCrankcase = {"SEER 8, 6.0 HSPF"=>0.02, "SEER 10, 6.2 HSPF"=>0.02, "SEER 13, 7.7 HSPF"=>0.02, "SEER 14, 8.2 HSPF"=> 0.02, "SEER 15, 8.5 HSPF"=>0.02, "SEER 16, 8.6 HSPF"=>0.02, "SEER 17, 8.7 HSPF"=>0.02, "SEER 18, 9.3 HSPF"=>0.02, "SEER 19, 9.5 HSPF"=>0.02, "SEER 22, 10 HSPF"=>0.02}[selected_hp]
    hpCrankcaseMaxT = {"SEER 8, 6.0 HSPF"=>55.0, "SEER 10, 6.2 HSPF"=>55.0, "SEER 13, 7.7 HSPF"=>55.0, "SEER 14, 8.2 HSPF"=>55.0, "SEER 15, 8.5 HSPF"=>55.0, "SEER 16, 8.6 HSPF"=>55.0, "SEER 17, 8.7 HSPF"=>55.0, "SEER 18, 9.3 HSPF"=>55.0, "SEER 19, 9.5 HSPF"=>55.0, "SEER 22, 10 HSPF"=>55.0}[selected_hp]
    hpEERCapacityDerateFactor = {"SEER 8, 6.0 HSPF"=>1.0, "SEER 10, 6.2 HSPF"=>1.0, "SEER 13, 7.7 HSPF"=>1.0, "SEER 14, 8.2 HSPF"=>1.0, "SEER 15, 8.5 HSPF"=>1.0, "SEER 16, 8.6 HSPF"=>1.0, "SEER 17, 8.7 HSPF"=>1.0, "SEER 18, 9.3 HSPF"=>1.0, "SEER 19, 9.5 HSPF"=>1.0, "SEER 22, 10 HSPF"=>1.0}[selected_hp]
    hpHeatingCOP = {"SEER 8, 6.0 HSPF"=>[2.4], "SEER 10, 6.2 HSPF"=>[2.4], "SEER 13, 7.7 HSPF"=>[3.05], "SEER 14, 8.2 HSPF"=>[3.35], "SEER 15, 8.5 HSPF"=>[3.5], "SEER 16, 8.6 HSPF"=>[3.8, 3.3], "SEER 17, 8.7 HSPF"=>[3.85, 3.4], "SEER 18, 9.3 HSPF"=>[4.2, 3.7], "SEER 19, 9.5 HSPF"=>[4.35, 3.75], "SEER 22, 10 HSPF"=>[4.82, 4.56, 3.89, 3.92]}[selected_hp]
    hpHeatingInstalledHSPF = {"SEER 8, 6.0 HSPF"=>6.0, "SEER 10, 6.2 HSPF"=>6.2, "SEER 13, 7.7 HSPF"=>7.7, "SEER 14, 8.2 HSPF"=>8.2, "SEER 15, 8.5 HSPF"=>8.5, "SEER 16, 8.6 HSPF"=>8.6, "SEER 17, 8.7 HSPF"=>8.7, "SEER 18, 9.3 HSPF"=>9.3, "SEER 19, 9.5 HSPF"=>9.5, "SEER 22, 10 HSPF"=>10.0}[selected_hp]
    hpFanspeedRatioHeating = {"SEER 8, 6.0 HSPF"=>[1.0], "SEER 10, 6.2 HSPF"=>[1.0], "SEER 13, 7.7 HSPF"=>[1.0], "SEER 14, 8.2 HSPF"=>[1.0], "SEER 15, 8.5 HSPF"=>[1.0], "SEER 16, 8.6 HSPF"=>[0.8, 1.0], "SEER 17, 8.7 HSPF"=>[0.8, 1.0], "SEER 18, 9.3 HSPF"=>[0.8, 1.0], "SEER 19, 9.5 HSPF"=>[0.8, 1.0], "SEER 22, 10 HSPF"=>[0.74, 0.92, 1.0, 1.22]}[selected_hp]
    hpMinT = {"SEER 8, 6.0 HSPF"=>0.0, "SEER 10, 6.2 HSPF"=>0.0, "SEER 13, 7.7 HSPF"=>0.0, "SEER 14, 8.2 HSPF"=>0.0, "SEER 15, 8.5 HSPF"=>0.0, "SEER 16, 8.6 HSPF"=>0.0, "SEER 17, 8.7 HSPF"=>0.0, "SEER 18, 9.3 HSPF"=>0.0, "SEER 19, 9.5 HSPF"=>0.0, "SEER 22, 10 HSPF"=>0.0}[selected_hp]
    hpCOPCapacityDerateFactor = {"SEER 8, 6.0 HSPF"=>0.0, "SEER 10, 6.2 HSPF"=>0.0, "SEER 13, 7.7 HSPF"=>1.0, "SEER 14, 8.2 HSPF"=>1.0, "SEER 15, 8.5 HSPF"=>1.0, "SEER 16, 8.6 HSPF"=>1.0, "SEER 17, 8.7 HSPF"=>1.0, "SEER 18, 9.3 HSPF"=>1.0, "SEER 19, 9.5 HSPF"=>1.0, "SEER 22, 10 HSPF"=>1.0}[selected_hp]
    hpRatedAirFlowRateCooling = {"SEER 8, 6.0 HSPF"=>394.2, "SEER 10, 6.2 HSPF"=>394.2, "SEER 13, 7.7 HSPF"=>394.2, "SEER 14, 8.2 HSPF"=>394.2, "SEER 15, 8.5 HSPF"=>394.2, "SEER 16, 8.6 HSPF"=>344.1, "SEER 17, 8.7 HSPF"=>344.1, "SEER 18, 9.3 HSPF"=>344.1, "SEER 19, 9.5 HSPF"=>344.1, "SEER 22, 10 HSPF"=>315.8}[selected_hp]
    hpRatedAirFlowRateHeating = {"SEER 8, 6.0 HSPF"=>384.1, "SEER 10, 6.2 HSPF"=>384.1, "SEER 13, 7.7 HSPF"=>384.1, "SEER 14, 8.2 HSPF"=>384.1, "SEER 15, 8.5 HSPF"=>384.1, "SEER 16, 8.6 HSPF"=>352.2, "SEER 17, 8.7 HSPF"=>352.2, "SEER 18, 9.3 HSPF"=>352.2, "SEER 19, 9.5 HSPF"=>352.2, "SEER 22, 10 HSPF"=>296.9}[selected_hp]
    hpIsColdClimate = runner.getBoolArgumentValue("selectedcchp",user_arguments)
    
    heatingseasonschedule = HelperMethods.get_heating_or_cooling_season_schedule_object(model, runner, "HeatingSeasonSchedule")
    coolingseasonschedule = HelperMethods.get_heating_or_cooling_season_schedule_object(model, runner, "CoolingSeasonSchedule")
    if heatingseasonschedule.nil? or coolingseasonschedule.nil?
        runner.registerError("A heating season schedule named 'HeatingSeasonSchedule' and/or cooling season schedule named 'CoolingSeasonSchedule' has not yet been assigned. Apply the 'Set Residential Heating/Cooling Setpoints and Schedules' measure first.")
        return false
    end
    
    # Create the material class instances
    air_conditioner = AirConditioner.new(nil)
    heat_pump = HeatPump.new(hpNumberSpeeds, hpCoolingEER, hpCoolingInstalledSEER, hpSupplyFanPowerInstalled, hpSupplyFanPowerRated, hpSHRRated, hpCapacityRatio, hpFanspeedRatioCooling, hpCondenserType, hpCrankcase, hpCrankcaseMaxT, hpEERCapacityDerateFactor, hpHeatingCOP, hpHeatingInstalledHSPF, hpFanspeedRatioHeating, hpMinT, hpCOPCapacityDerateFactor, hpRatedAirFlowRateCooling, hpRatedAirFlowRateHeating)
    supply = Supply.new

    # _processAirSystem
    
    if air_conditioner.ACCoolingInstalledSEER == 999
      air_conditioner.hasIdealAC = true
    else
      air_conditioner.hasIdealAC = false
    end

    supply.static = UnitConversion.inH2O2Pa(0.5) # Pascal

    # Flow rate through AC units - hardcoded assumption of 400 cfm/ton
    supply.cfm_ton = 400 # cfm / ton

    supply.HPCoolingOversizingFactor = 1 # Default to a value of 1 (currently only used for MSHPs)
    supply.SpaceConditionedMult = 1 # Default used for central equipment    
    
    # Cooling Coil
    supply = HVAC.get_cooling_coefficients(runner, heat_pump.HPNumberSpeeds, false, true, supply)
    supply.CFM_TON_Rated = HVAC.calc_cfm_ton_rated(heat_pump.HPRatedAirFlowRateCooling, heat_pump.HPFanspeedRatioCooling, heat_pump.HPCapacityRatio)
    supply = HVAC._processAirSystemCoolingCoil(heat_pump.HPNumberSpeeds, heat_pump.HPCoolingEER, heat_pump.HPCoolingInstalledSEER, heat_pump.HPSupplyFanPowerInstalled, heat_pump.HPSupplyFanPowerRated, heat_pump.HPSHRRated, heat_pump.HPCapacityRatio, heat_pump.HPFanspeedRatioCooling, heat_pump.HPCondenserType, heat_pump.HPCrankcase, heat_pump.HPCrankcaseMaxT, heat_pump.HPEERCapacityDerateFactor, air_conditioner, supply, true)

    # Heating Coil
    has_cchp = hpIsColdClimate
    supply = HVAC.get_heating_coefficients(runner, supply.Number_Speeds, false, supply, heat_pump.HPMinT)
    supply.CFM_TON_Rated_Heat = HVAC.calc_cfm_ton_rated(heat_pump.HPRatedAirFlowRateHeating, heat_pump.HPFanspeedRatioHeating, heat_pump.HPCapacityRatio)
    supply = HVAC._processAirSystemHeatingCoil(heat_pump.HPHeatingCOP, heat_pump.HPHeatingInstalledHSPF, heat_pump.HPSupplyFanPowerRated, heat_pump.HPCapacityRatio, heat_pump.HPFanspeedRatioHeating, heat_pump.HPMinT, heat_pump.HPCOPCapacityDerateFactor, supply)    

    # Determine if the compressor is multi-speed (in our case 2 speed).
    # If the minimum flow ratio is less than 1, then the fan and
    # compressors can operate at lower speeds.
    if supply.min_flow_ratio == 1.0
      supply.compressor_speeds = 1.0
    else
      supply.compressor_speeds = supply.Number_Speeds
    end
    
    htg_coil_stage_data = HVAC._processCurvesDXHeating(model, supply, hpOutputCapacity)
    
    # Heating defrost curve for reverse cycle
    defrost_eir = OpenStudio::Model::CurveBiquadratic.new(model)
    defrost_eir.setName("DefrostEIR")
    defrost_eir.setCoefficient1Constant(0.1528)
    defrost_eir.setCoefficient2x(0)
    defrost_eir.setCoefficient3xPOW2(0)
    defrost_eir.setCoefficient4y(0)
    defrost_eir.setCoefficient5yPOW2(0)
    defrost_eir.setCoefficient6xTIMESY(0)
    defrost_eir.setMinimumValueofx(-100)
    defrost_eir.setMaximumValueofx(100)
    defrost_eir.setMinimumValueofy(-100)
    defrost_eir.setMaximumValueofy(100)    
    
    # _processCurvesDXCooling

    clg_coil_stage_data = HVAC._processCurvesDXCooling(model, supply, hpOutputCapacity)

    master_zones, slave_zones = Geometry.get_master_and_slave_zones(model)
    
    master_zones.each do |master_zone|
    
      # Check if has equipment
      HelperMethods.remove_existing_hvac_equipment_except_for_specified_object(model, runner, master_zone)
      baseboards = model.getZoneHVACBaseboardConvectiveElectrics
      baseboards.each do |baseboard|
        thermalZone = baseboard.thermalZone.get
        if master_zone.handle.to_s == thermalZone.handle.to_s
          runner.registerInfo("Removed '#{baseboard.name}' from thermal zone '#{thermalZone.name}'")
          baseboard.remove
        end    
      end
      ptacs = model.getZoneHVACPackagedTerminalAirConditioners
      ptacs.each do |ptac|
        thermalZone = ptac.thermalZone.get
        if master_zone.handle.to_s == thermalZone.handle.to_s
          runner.registerInfo("Removed '#{ptac.name}' from thermal zone '#{thermalZone.name}'")
          ptac.remove
        end
      end    
    
      # _processSystemHeatingCoil
      
      if supply.compressor_speeds == 1.0

        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, heatingseasonschedule, htg_coil_stage_data[0].heatingCapacityFunctionofTemperatureCurve, htg_coil_stage_data[0].heatingCapacityFunctionofFlowFractionCurve, htg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, htg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, htg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        htg_coil.setName("DX Heating Coil")
        if hpOutputCapacity != "Autosize"
          htg_coil.setRatedTotalHeatingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get)
        end
        htg_coil.setRatedCOP(1.0 / supply.HeatingEIR[0])
        # self.addline(units.cfm2m3_s(sim.supply.Heat_AirFlowRate),'Rated Air Flow Rate {m^3/s}')
        # self.addline(unit.supply.fan_power_rated/units.cfm2m3_s(1),'Rated Evaporator Fan Power Per Volume Flow Rate {W/(m/s)}')
        htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir)
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)

        # Crankcase heaters are handled using EMS
        htg_coil.setCrankcaseHeaterCapacity(0.0)
        htg_coil.setDefrostStrategy("ReverseCycle")
        htg_coil.setDefrostControl("OnDemand")

      else # Multi-speed compressors

        htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
        htg_coil.setName("DX Heating Coil")
        htg_coil.setAvailabilitySchedule(heatingseasonschedule)
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
      
        # Crankcase heaters are handled using EMS
        htg_coil.setCrankcaseHeaterCapacity(0.0)
        htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
        htg_coil.setDefrostStrategy("ReverseCryle")
        htg_coil.setDefrostControl("OnDemand")
        htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        htg_coil.setFuelType("Electricity")
        
        htg_coil_stage_data.each do |i|
            htg_coil.addStage(i)    
        end

      end
      
      supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, heatingseasonschedule)
      supp_htg_coil.setName("HeatPump Supp Heater")
      supp_htg_coil.setEfficiency(1)
      if supplementalOutputCapacity != "Autosize"
        supp_htg_coil.setNominalCapacity(OpenStudio::convert(supplementalOutputCapacity,"Btu/h","W").get)
      end
      
      # _processSystemCoolingCoil
      
      if supply.compressor_speeds == 1.0

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, coolingseasonschedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        clg_coil.setName("DX Cooling Coil")
        if hpOutputCapacity != "Autosize"
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get)
        end
        if air_conditioner.hasIdealAC
          if hpOutputCapacity != "Autosize"
            clg_coil.setRatedSensibleHeatRatio(0.8)
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0))
        else
          if hpOutputCapacity != "Autosize"
            clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[0])
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0 / supply.CoolingEIR[0]))
        end
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(supply.fan_power_rated / OpenStudio::convert(1.0,"cfm","m^3/s").get))

        if air_conditioner.hasIdealAC
          clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(0))
          clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(0))
          clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(0))
          clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(0))
        else
          clg_coil.setNominalTimeForCondensateRemovalToBegin(OpenStudio::OptionalDouble.new(1000.0))
          clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(OpenStudio::OptionalDouble.new(1.5))
          clg_coil.setMaximumCyclingRate(OpenStudio::OptionalDouble.new(3.0))
          clg_coil.setLatentCapacityTimeConstant(OpenStudio::OptionalDouble.new(45.0))
        end

        if supply.CondenserType == Constants.CondenserTypeAir
          clg_coil.setCondenserType("AirCooled")
        else
          clg_coil.setCondenserType("EvaporativelyCooled")
          clg_coil.setEvaporativeCondenserEffectiveness(OpenStudio::OptionalDouble.new(1))
          clg_coil.setEvaporativeCondenserAirFlowRate(OpenStudio::OptionalDouble.new(OpenStudio::convert(850.0,"cfm","m^3/s").get * sizing.cooling_cap))
          clg_coil.setEvaporativeCondenserPumpRatePowerConsumption(OpenStudio::OptionalDouble.new(0))
        end

        #For heat pumps, we handle the crankcase heater using EMS so the heater energy shows up under cooling energy
        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::OptionalDouble.new(0.0))
        clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(10.0))

      else

        clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
        clg_coil.setName("DX Cooling Coil")
        clg_coil.setAvailabilitySchedule(coolingseasonschedule)
        clg_coil.setCondenserType(supply.CondenserType)
        clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)

        #Multi-speed ACs and HPs, we handle the crankcase heater using EMS so the heater energy shows up under cooling energy
        clg_coil.setCrankcaseHeaterCapacity(0)
        clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(10.0)
        
        clg_coil.setFuelType("Electricity")
             
        clg_coil_stage_data.each do |i|
            clg_coil.addStage(i)
        end  

      end    
      
      # _processSystemFan
      
      supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
      supply_fan_availability.setName("SupplyFanAvailability")
      supply_fan_availability.setValue(1)

      fan = OpenStudio::Model::FanOnOff.new(model, supply_fan_availability)
      fan.setName("Supply Fan")
      fan.setEndUseSubcategory("HVACFan")
      fan.setFanEfficiency(supply.eff)
      fan.setPressureRise(supply.static)
      fan.setMotorEfficiency(1)
      fan.setMotorInAirstreamFraction(1)

      supply_fan_operation = OpenStudio::Model::ScheduleConstant.new(model)
      supply_fan_operation.setName("SupplyFanOperation")
      supply_fan_operation.setValue(0)     
      
      # _processSystemAir

      if supply.compressor_speeds == 1

        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
        air_loop_unitary.setName("Forced Air System")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setHeatingCoil(htg_coil)
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplementalHeatingCoil(supp_htg_coil)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(supply.supp_htg_max_supply_temp,"F","C").get) # TODO: is this the same as AirLoopHVACUnitaryHeatPumpAirToAir's setMaximumSupplyAirTemperaturefromSupplementalHeater?
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(supply.supp_htg_max_outdoor_temp,"F","C").get)      
        air_loop_unitary.setFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        
      elsif supply.compressor_speeds > 1
      
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model, fan, htg_coil, clg_coil, supp_htg_coil)
        air_loop_unitary.setName("Forced Air System")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyAirFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        air_loop_unitary.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
        air_loop_unitary.setMaximumSupplyAirTemperaturefromSupplementalHeater(OpenStudio::convert(supply.supp_htg_max_supply_temp,"F","C").get)
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(supply.supp_htg_max_outdoor_temp,"F","C").get)
        air_loop_unitary.setAuxiliaryOnCycleElectricPower(0)
        air_loop_unitary.setAuxiliaryOffCycleElectricPower(0)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisNeeded(0)
        air_loop_unitary.setNumberofSpeedsforHeating(supply.Number_Speeds.to_i)
        air_loop_unitary.setNumberofSpeedsforCooling(supply.Number_Speeds.to_i)      
        
      end

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName("Central Air System")
      air_supply_inlet_node = air_loop.supplyInletNode
      air_supply_outlet_node = air_loop.supplyOutletNode
      air_demand_inlet_node = air_loop.demandInletNode
      air_demand_outlet_node = air_loop.demandOutletNode    
      
      air_loop_unitary.addToNode(air_supply_inlet_node)
      
      runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added DX cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added DX heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      runner.registerInfo("Added electric heating coil '#{supp_htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")    
      
      air_loop_unitary.setControllingZoneorThermostatLocation(master_zone)
        
      # _processSystemDemandSideAir
      # Demand Side

      # Supply Air
      zone_splitter = air_loop.zoneSplitter
      zone_splitter.setName("Zone Splitter")

      diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      diffuser_living.setName("Living Zone Direct Air")
      # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
      air_loop.addBranchForZone(master_zone, diffuser_living.to_StraightComponent)

      setpoint_mgr = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
      setpoint_mgr.setControlZone(master_zone)
      setpoint_mgr.addToNode(air_supply_outlet_node)

      air_loop.addBranchForZone(master_zone)
      runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{master_zone.name}'")

      slave_zones.each do |slave_zone|

          # Check if has equipment
          baseboards = model.getZoneHVACBaseboardConvectiveElectrics
          baseboards.each do |baseboard|
            thermalZone = baseboard.thermalZone.get      
            if slave_zone.handle.to_s == thermalZone.handle.to_s
              runner.registerInfo("Removed '#{baseboard.name}' from thermal zone '#{thermalZone.name}'")
              baseboard.remove
            end
          end
      
          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          diffuser_fbsmt.setName("FBsmt Zone Direct Air")
          # diffuser_fbsmt.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
          air_loop.addBranchForZone(slave_zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(slave_zone)
          runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{slave_zone.name}'")

      end    
    
    end
	
    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessAirSourceHeatPump.new.registerWithApplication