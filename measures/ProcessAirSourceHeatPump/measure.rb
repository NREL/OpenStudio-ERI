#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

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

    attr_accessor(:IsIdealAC)

    def ACCoolingInstalledSEER
      return @acCoolingInstalledSEER
    end
  end

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :CFM_TON_Rated_Heat, :HeatingEIR, :HEAT_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Heating, :fanspeed_ratio_heating, :min_hp_temp, :max_supp_heating_temp, :max_defrost_temp, :COP_CapacityDerateFactor)
  end

  class TestSuite
    def initialize(min_test_ideal_systems, min_test_ideal_loads)
      @min_test_ideal_systems = min_test_ideal_systems
      @min_test_ideal_loads = min_test_ideal_loads
    end

    def min_test_ideal_systems
      return @min_test_ideal_systems
    end

    def min_test_ideal_loads
      return @min_test_ideal_loads
    end
  end

  class Misc
    def initialize(simTestSuiteBuilding)
      @simTestSuiteBuilding = simTestSuiteBuilding
    end

    def SimTestSuiteBuilding
      return @simTestSuiteBuilding
    end
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessAirSourceHeatPump"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    zone_handles = OpenStudio::StringVector.new
    zone_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    zone_args = model.getThermalZones
    zone_args_hash = {}
    zone_args.each do |zone_arg|
      zone_args_hash[zone_arg.name.to_s] = zone_arg
    end

    #looping through sorted hash of model objects
    zone_args_hash.sort.map do |key,value|
      zone_handles << value.handle.to_s
      zone_display_names << key
    end

    #make a choice argument for living zone
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", zone_handles, zone_display_names, true)
    selected_living.setDisplayName("Which is the living space zone?")
    args << selected_living

    #make a choice argument for fbsmt
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", zone_handles, zone_display_names, false)
    selected_fbsmt.setDisplayName("Which is the finished basement zone?")
    args << selected_fbsmt

    #make a choice argument for ashp options
    hp_display_names = OpenStudio::StringVector.new
    hp_display_names << "SEER 8, 6.0 HSPF"
    hp_display_names << "SEER 10, 6.2 HSPF"
    hp_display_names << "SEER 13, 7.7 HSPF"
    hp_display_names << "SEER 14, 8.2 HSPF"
    hp_display_names << "SEER 15, 8.5 HSPF"
    # hp_display_names << "SEER 16, 8.6 HSPF"
    # hp_display_names << "SEER 17, 8.7 HSPF"
    # hp_display_names << "SEER 18, 9.3 HSPF"
    # hp_display_names << "SEER 19, 9.5 HSPF"
    # hp_display_names << "SEER 22, 10 HSPF"

    #make a string argument for ashp options
    selected_hp = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedhp", hp_display_names, true)
    selected_hp.setDisplayName("Air Source Heat Pump: Installed SEER [Btu/W-h], Installed HSPF [Btu/W-h]")
	selected_hp.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the heat pump, and the installed Heating Seasonal Performance Factor (HSPF) of the heat pump.")
    selected_hp.setDefaultValue("SEER 13, 7.7 HSPF")
    args << selected_hp

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

    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)
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

    constants = Constants.new

    # Create the material class instances
    air_conditioner = AirConditioner.new(nil)
    heat_pump = HeatPump.new(hpNumberSpeeds, hpCoolingEER, hpCoolingInstalledSEER, hpSupplyFanPowerInstalled, hpSupplyFanPowerRated, hpSHRRated, hpCapacityRatio, hpFanspeedRatioCooling, hpCondenserType, hpCrankcase, hpCrankcaseMaxT, hpEERCapacityDerateFactor, hpHeatingCOP, hpHeatingInstalledHSPF, hpFanspeedRatioHeating, hpMinT, hpCOPCapacityDerateFactor, hpRatedAirFlowRateCooling, hpRatedAirFlowRateHeating)
    supply = Supply.new
    test_suite = TestSuite.new(false, false)
    misc = Misc.new(nil)

    # Create the sim object
    sim = Sim.new(model, runner)

    hasFurnace = false
    hasCoolingEquipment = true
    hasAirConditioner = false
    hasHeatPump = true
    hasMiniSplitHP = false
    hasRoomAirConditioner = false
    hasGroundSourceHP = false

    # Process the air system
    air_conditioner, supply = sim._processAirSystem(supply, nil, air_conditioner, heat_pump, hasFurnace, hasCoolingEquipment, hasAirConditioner, hasHeatPump, hasMiniSplitHP, hasRoomAirConditioner, hasGroundSourceHP, test_suite)

    heatingseasonschedule = nil
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "HeatingSeasonSchedule"
        heatingseasonschedule = scheduleRuleset
        break
      end
    end

    coolingseasonschedule = nil
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "CoolingSeasonSchedule"
        coolingseasonschedule = scheduleRuleset
        break
      end
    end

    # Check if has equipment
    airLoopHVACs = model.getAirLoopHVACs
    airLoopHVACs.each do |airLoopHVAC|
      thermalZones = airLoopHVAC.thermalZones
      thermalZones.each do |thermalZone|
        if selected_living.get.handle.to_s == thermalZone.handle.to_s
          supplyComponents = airLoopHVAC.supplyComponents
          supplyComponents.each do |supplyComponent|
            runner.registerInfo("Removed '#{supplyComponent.name}' from air loop '#{airLoopHVAC.name}'")
            supplyComponent.remove
          end
          runner.registerInfo("Removed air loop '#{airLoopHVAC.name}'")
          airLoopHVAC.remove
        end
      end
    end
    baseboards = model.getZoneHVACBaseboardConvectiveElectrics
    baseboards.each do |baseboard|
      thermalZone = baseboard.thermalZone.get
      runner.registerInfo("Removed '#{baseboard.name}' from thermal zone '#{thermalZone.name}'")
      baseboard.remove
    end

    always_on = model.alwaysOnDiscreteSchedule

    # _processSystemAir
    # Air System

    if not hasCoolingEquipment
      # Initialize simulation variables not being used
      supply.Number_Speeds = 1.0
      supply.fanspeed_ratio = [1.0]
      supply.compressor_speeds = 1.0
    end

    # if not sim.hasForcedAirEquipment:
    #     return

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName("Central Air System")
    # if test_suite.min_test_ideal_systems or air_conditioner.IsIdealAC
    #     air_loop.setDesignSupplyAirFlowRate(OpenStudio::convert(supply.Fan_AirFlowRate,"cfm","m^3/s").get)
    # else
    #   air_loop.setDesignSupplyAirFlowRate(supply.fanspeed_ratio.max * OpenStudio::convert(supply.Fan_AirFlowRate,"cfm","m^3/s").get)
    # end

    # stuff

    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode

    # _processSystemHeatingCoil
    # Heating Coil

    if hasHeatPump

      htg_cap_f_of_temp = Array.new
      htg_cap_f_of_flow = Array.new
      htg_energy_input_ratio_f_of_temp = Array.new
      htg_energy_input_ratio_f_of_flow = Array.new
      htg_part_load_ratio = Array.new

      # Loop through speeds to create curves for each speed
      (0...supply.Number_Speeds).to_a.each do |speed|
        # Heating Capacity f(T). Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.HEAT_CAP_FT_SPEC_coefficients[speed]
        else
          c = supply.HEAT_CAP_FT_SPEC_coefficients
        end
        heat_Cap_fT_coeff = Array.new
        heat_Cap_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        heat_Cap_fT_coeff << 9.0 / 5.0 * c[1] + 576.0 / 5.0 * c[2] + 288.0 / 5.0 * c[5]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[2]
        heat_Cap_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[4]
        heat_Cap_fT_coeff << 81.0 / 25.0 * c[5]

        htg_cap_f_of_temp_object = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          htg_cap_f_of_temp_object.setName("HP_Heat-Cap-fT#{speed + 1}")
        else
          htg_cap_f_of_temp_object.setName("HP_Heat-Cap-fT")
        end
        htg_cap_f_of_temp_object.setCoefficient1Constant(heat_Cap_fT_coeff[0])
        htg_cap_f_of_temp_object.setCoefficient2x(heat_Cap_fT_coeff[1])
        htg_cap_f_of_temp_object.setCoefficient3xPOW2(heat_Cap_fT_coeff[2])
        htg_cap_f_of_temp_object.setCoefficient4y(heat_Cap_fT_coeff[3])
        htg_cap_f_of_temp_object.setCoefficient5yPOW2(heat_Cap_fT_coeff[4])
        htg_cap_f_of_temp_object.setCoefficient6xTIMESY(heat_Cap_fT_coeff[5])
        htg_cap_f_of_temp_object.setMinimumValueofx(13.88)
        htg_cap_f_of_temp_object.setMaximumValueofx(23.88)
        htg_cap_f_of_temp_object.setMinimumValueofy(18.33)
        htg_cap_f_of_temp_object.setMaximumValueofy(51.66)
        htg_cap_f_of_temp << htg_cap_f_of_temp_object

        # Heating EIR f(T) Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.HEAT_EIR_FT_SPEC_coefficients[speed]
        else
          c = supply.HEAT_EIR_FT_SPEC_coefficients
        end
        hp_heat_EIR_fT_coeff = Array.new
        hp_heat_EIR_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        hp_heat_EIR_fT_coeff << 9.0 / 5 * c[1] + 576.0 / 5 * c[2] + 288.0 / 5.0 * c[5]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[2]
        hp_heat_EIR_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[4]
        hp_heat_EIR_fT_coeff << 81.0 / 25.0 * c[5]

        htg_energy_input_ratio_f_of_temp_object = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          htg_energy_input_ratio_f_of_temp_object.setName("HP_Heat-EIR-fT#{speed + 1}")
        else
          htg_energy_input_ratio_f_of_temp_object.setName("HP_Heat-EIR-fT")
        end
        htg_energy_input_ratio_f_of_temp_object.setCoefficient1Constant(hp_heat_EIR_fT_coeff[0])
        htg_energy_input_ratio_f_of_temp_object.setCoefficient2x(hp_heat_EIR_fT_coeff[1])
        htg_energy_input_ratio_f_of_temp_object.setCoefficient3xPOW2(hp_heat_EIR_fT_coeff[2])
        htg_energy_input_ratio_f_of_temp_object.setCoefficient4y(hp_heat_EIR_fT_coeff[3])
        htg_energy_input_ratio_f_of_temp_object.setCoefficient5yPOW2(hp_heat_EIR_fT_coeff[4])
        htg_energy_input_ratio_f_of_temp_object.setCoefficient6xTIMESY(hp_heat_EIR_fT_coeff[5])
        htg_energy_input_ratio_f_of_temp_object.setMinimumValueofx(13.88)
        htg_energy_input_ratio_f_of_temp_object.setMaximumValueofx(23.88)
        htg_energy_input_ratio_f_of_temp_object.setMinimumValueofy(18.33)
        htg_energy_input_ratio_f_of_temp_object.setMaximumValueofy(51.66)
        htg_energy_input_ratio_f_of_temp << htg_energy_input_ratio_f_of_temp_object

        # Heating PLF f(PLR) Convert DOE-2 curves to E+ curves
        htg_part_load_ratio_object = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          htg_part_load_ratio_object.setName("HP_Heat-PLF-fPLR#{speed + 1}")
        else
          htg_part_load_ratio_object.setName("HP_Heat-PLF-fPLR")
        end
        htg_part_load_ratio_object.setCoefficient1Constant(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[0])
        htg_part_load_ratio_object.setCoefficient2x(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[1])
        htg_part_load_ratio_object.setCoefficient3xPOW2(supply.HEAT_CLOSS_FPLR_SPEC_coefficients[2])
        htg_part_load_ratio_object.setMinimumValueofx(0.0)
        htg_part_load_ratio_object.setMaximumValueofx(1.0)
        # htg_part_load_ratio_object.setMinimumValueofy(0.7) # tk
        # htg_part_load_ratio_object.setMaximumValueofy(1.0) # tk
        htg_part_load_ratio << htg_part_load_ratio_object

        # Heating CAP f(FF) Convert DOE-2 curves to E+ curves
        htg_cap_f_of_flow_object = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          htg_cap_f_of_flow_object.setName("HP_Heat-Cap-fFF#{speed + 1}")
          htg_cap_f_of_flow_object.setCoefficient1Constant(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][0])
          htg_cap_f_of_flow_object.setCoefficient2x(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][1])
          htg_cap_f_of_flow_object.setCoefficient3xPOW2(supply.HEAT_CAP_FFLOW_SPEC_coefficients[speed][2])
        else
          htg_cap_f_of_flow_object.setName("HP_Heat-CAP-fFF")
          htg_cap_f_of_flow_object.setCoefficient1Constant(supply.HEAT_CAP_FFLOW_SPEC_coefficients[0])
          htg_cap_f_of_flow_object.setCoefficient2x(supply.HEAT_CAP_FFLOW_SPEC_coefficients[1])
          htg_cap_f_of_flow_object.setCoefficient3xPOW2(supply.HEAT_CAP_FFLOW_SPEC_coefficients[2])
        end
        htg_cap_f_of_flow_object.setMinimumValueofx(0.0)
        htg_cap_f_of_flow_object.setMaximumValueofx(2.0)
        # htg_cap_f_of_flow_object.setMinimumValueofy(0.0) # tk
        # htg_cap_f_of_flow_object.setMaximumValueofy(2.0) # tk
        htg_cap_f_of_flow << htg_cap_f_of_flow_object

        # Heating EIR f(FF) Convert DOE-2 curves to E+ curves
        htg_energy_input_ratio_f_of_flow_object = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          htg_energy_input_ratio_f_of_flow_object.setName("HP_Heat-EIR-fFF#{speed + 1}")
          htg_energy_input_ratio_f_of_flow_object.setCoefficient1Constant(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][0])
          htg_energy_input_ratio_f_of_flow_object.setCoefficient2x(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][1])
          htg_energy_input_ratio_f_of_flow_object.setCoefficient3xPOW2(supply.HEAT_EIR_FFLOW_SPEC_coefficients[speed][2])
        else
          htg_energy_input_ratio_f_of_flow_object.setName("HP_Heat-EIR-fFF")
          htg_energy_input_ratio_f_of_flow_object.setCoefficient1Constant(supply.HEAT_EIR_FFLOW_SPEC_coefficients[0])
          htg_energy_input_ratio_f_of_flow_object.setCoefficient2x(supply.HEAT_EIR_FFLOW_SPEC_coefficients[1])
          htg_energy_input_ratio_f_of_flow_object.setCoefficient3xPOW2(supply.HEAT_EIR_FFLOW_SPEC_coefficients[2])
        end
        htg_energy_input_ratio_f_of_flow_object.setMinimumValueofx(0.0)
        htg_energy_input_ratio_f_of_flow_object.setMaximumValueofx(2.0)
        # htg_energy_input_ratio_f_of_flow_object.setMinimumValueofy(0.0) # tk
        # htg_energy_input_ratio_f_of_flow_object.setMaximumValueofy(2.0) # tk
        htg_energy_input_ratio_f_of_flow << htg_energy_input_ratio_f_of_flow_object

      end

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

      hp_supp_heater = OpenStudio::Model::CoilHeatingElectric.new(model, heatingseasonschedule)
      hp_supp_heater.setName("HeatPump Supp Heater")
      hp_supp_heater.setEfficiency(1.0)
      if supplementalOutputCapacity != "Autosize"
        hp_supp_heater.setNominalCapacity(OpenStudio::convert(supplementalOutputCapacity,"Btu/h","W").get)
      end

      if supply.compressor_speeds == 1.0

        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, heatingseasonschedule, htg_cap_f_of_temp[0], htg_cap_f_of_flow[0], htg_energy_input_ratio_f_of_temp[0], htg_energy_input_ratio_f_of_flow[0], htg_part_load_ratio[0])
        htg_coil.setName("DX Heating Coil")
        if test_suite.min_test_ideal_systems
          # self.addline(units.Btu_h2W(sim.supply.Cool_Capacity),'Rated High Speed Total Cooling Capacity {W}')
          # self.addline(1 / sim.supply.HeatingEIR[0],'Rated High Speed COP')
        else
          if hpOutputCapacity != "Autosize"
            htg_coil.setRatedTotalHeatingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get)
          end
          htg_coil.setRatedCOP(1.0 / supply.HeatingEIR[0])
        end
        # self.addline(units.cfm2m3_s(sim.supply.Heat_AirFlowRate),'Rated Air Flow Rate {m^3/s}')
        # self.addline(sim.supply.fan_power/units.cfm2m3_s(1),'Rated Evaporator Fan Power Per Volume Flow Rate {W/(m/s)}')
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)

        # Crankcase heaters are handled using EMS
        htg_coil.setCrankcaseHeaterCapacity(0.0)
        htg_coil.setDefrostStrategy("ReverseCycle")
        htg_coil.setDefrostControl("OnDemand")

        htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir)

      else # Multi-speed compressors

        htg_coil = OpenStudio::Model::CoilHeatingDXTwoSpeed.new(model, heatingseasonschedule, htg_cap_f_of_temp[1], htg_cap_f_of_flow[1], htg_energy_input_ratio_f_of_temp[1], htg_energy_input_ratio_f_of_flow[1], htg_part_load_ratio[1], htg_cap_f_of_temp[0], htg_energy_input_ratio_f_of_temp[0])
        htg_coil.setName("DX Heating Coil")
        htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)

        # Crankcase heaters are handled using EMS
        htg_coil.setCrankcaseHeaterCapacity(0.0)
        htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
        htg_coil.setDefrostStrategy("ReverseCryle")
        htg_coil.setDefrostControl("OnDemand")

      end

    end

    # _processSystemCoolingCoil
    # Cooling Coil

    if hasHeatPump

      clg_cap_f_of_temp = Array.new
      clg_cap_f_of_flow = Array.new
      clg_energy_input_ratio_f_of_temp = Array.new
      clg_energy_input_ratio_f_of_flow = Array.new
      clg_part_load_ratio = Array.new

      (0...supply.Number_Speeds).to_a.each do |speed|
        # Cooling Capacity f(T). Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.COOL_CAP_FT_SPEC_coefficients[speed]
        else
          c = supply.COOL_CAP_FT_SPEC_coefficients
        end
        cool_Cap_fT_coeff = Array.new
        cool_Cap_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        cool_Cap_fT_coeff << 9.0 / 5.0 * c[1] + 576.0 / 5.0 * c[2] + 288.0 / 5.0 * c[5]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[2]
        cool_Cap_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[4]
        cool_Cap_fT_coeff << 81.0 / 25.0 * c[5]

        clg_cap_f_of_temp_object = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          clg_cap_f_of_temp_object.setName("Cool-Cap-fT#{speed + 1}")
        else
          clg_cap_f_of_temp_object.setName("Cool-Cap-fT")
        end
        clg_cap_f_of_temp_object.setCoefficient1Constant(cool_Cap_fT_coeff[0])
        clg_cap_f_of_temp_object.setCoefficient2x(cool_Cap_fT_coeff[1])
        clg_cap_f_of_temp_object.setCoefficient3xPOW2(cool_Cap_fT_coeff[2])
        clg_cap_f_of_temp_object.setCoefficient4y(cool_Cap_fT_coeff[3])
        clg_cap_f_of_temp_object.setCoefficient5yPOW2(cool_Cap_fT_coeff[4])
        clg_cap_f_of_temp_object.setCoefficient6xTIMESY(cool_Cap_fT_coeff[5])
        clg_cap_f_of_temp_object.setMinimumValueofx(13.88)
        clg_cap_f_of_temp_object.setMaximumValueofx(23.88)
        clg_cap_f_of_temp_object.setMinimumValueofy(18.33)
        clg_cap_f_of_temp_object.setMaximumValueofy(51.66)
        clg_cap_f_of_temp << clg_cap_f_of_temp_object

        # Cooling EIR f(T) Convert DOE-2 curves to E+ curves
        if supply.Number_Speeds > 1.0
          c = supply.COOL_EIR_FT_SPEC_coefficients[speed]
        else
          c = supply.COOL_EIR_FT_SPEC_coefficients
        end
        cool_EIR_fT_coeff = Array.new
        cool_EIR_fT_coeff << c[0] + 32.0 * (c[1] + c[3]) + 1024.0 * (c[2] + c[4] + c[5])
        cool_EIR_fT_coeff << 9.0 / 5 * c[1] + 576.0 / 5 * c[2] + 288.0 / 5.0 * c[5]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[2]
        cool_EIR_fT_coeff << 9.0 / 5.0 * c[3] + 576.0 / 5.0 * c[4] + 288.0 / 5.0 * c[5]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[4]
        cool_EIR_fT_coeff << 81.0 / 25.0 * c[5]

        clg_energy_input_ratio_f_of_temp_object = OpenStudio::Model::CurveBiquadratic.new(model)
        if supply.Number_Speeds > 1.0
          clg_energy_input_ratio_f_of_temp_object.setName("Cool-EIR-fT#{speed + 1}")
        else
          clg_energy_input_ratio_f_of_temp_object.setName("Cool-EIR-fT")
        end
        clg_energy_input_ratio_f_of_temp_object.setCoefficient1Constant(cool_EIR_fT_coeff[0])
        clg_energy_input_ratio_f_of_temp_object.setCoefficient2x(cool_EIR_fT_coeff[1])
        clg_energy_input_ratio_f_of_temp_object.setCoefficient3xPOW2(cool_EIR_fT_coeff[2])
        clg_energy_input_ratio_f_of_temp_object.setCoefficient4y(cool_EIR_fT_coeff[3])
        clg_energy_input_ratio_f_of_temp_object.setCoefficient5yPOW2(cool_EIR_fT_coeff[4])
        clg_energy_input_ratio_f_of_temp_object.setCoefficient6xTIMESY(cool_EIR_fT_coeff[5])
        clg_energy_input_ratio_f_of_temp_object.setMinimumValueofx(13.88)
        clg_energy_input_ratio_f_of_temp_object.setMaximumValueofx(23.88)
        clg_energy_input_ratio_f_of_temp_object.setMinimumValueofy(18.33)
        clg_energy_input_ratio_f_of_temp_object.setMaximumValueofy(51.66)
        clg_energy_input_ratio_f_of_temp << clg_energy_input_ratio_f_of_temp_object

        # Cooling PLF f(PLR) Convert DOE-2 curves to E+ curves
        clg_part_load_ratio_object = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          clg_part_load_ratio_object.setName("Cool-PLF-fPLR#{speed + 1}")
        else
          clg_part_load_ratio_object.setName("Cool-PLF-fPLR")
        end
        clg_part_load_ratio_object.setCoefficient1Constant(supply.COOL_CLOSS_FPLR_SPEC_coefficients[0])
        clg_part_load_ratio_object.setCoefficient2x(supply.COOL_CLOSS_FPLR_SPEC_coefficients[1])
        clg_part_load_ratio_object.setCoefficient3xPOW2(supply.COOL_CLOSS_FPLR_SPEC_coefficients[2])
        clg_part_load_ratio_object.setMinimumValueofx(0.0)
        clg_part_load_ratio_object.setMaximumValueofx(1.0)
        # clg_part_load_ratio_object.setMinimumValueofy(0.7) # tk
        # clg_part_load_ratio_object.setMaximumValueofy(1.0) # tk
        clg_part_load_ratio << clg_part_load_ratio_object

        # Cooling CAP f(FF) Convert DOE-2 curves to E+ curves
        clg_cap_f_of_flow_object = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          clg_cap_f_of_flow_object.setName("Cool-Cap-fFF#{speed + 1}")
          clg_cap_f_of_flow_object.setCoefficient1Constant(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][0])
          clg_cap_f_of_flow_object.setCoefficient2x(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][1])
          clg_cap_f_of_flow_object.setCoefficient3xPOW2(supply.COOL_CAP_FFLOW_SPEC_coefficients[speed][2])
        else
          clg_cap_f_of_flow_object.setName("Cool-CAP-fFF")
          clg_cap_f_of_flow_object.setCoefficient1Constant(supply.COOL_CAP_FFLOW_SPEC_coefficients[0])
          clg_cap_f_of_flow_object.setCoefficient2x(supply.COOL_CAP_FFLOW_SPEC_coefficients[1])
          clg_cap_f_of_flow_object.setCoefficient3xPOW2(supply.COOL_CAP_FFLOW_SPEC_coefficients[2])
        end
        clg_cap_f_of_flow_object.setMinimumValueofx(0.0)
        clg_cap_f_of_flow_object.setMaximumValueofx(2.0)
        # clg_cap_f_of_flow_object.setMinimumValueofy(0.0) # tk
        # clg_cap_f_of_flow_object.setMaximumValueofy(2.0) # tk
        clg_cap_f_of_flow << clg_cap_f_of_flow_object

        # Cooling EIR f(FF) Convert DOE-2 curves to E+ curves
        clg_energy_input_ratio_f_of_flow_object = OpenStudio::Model::CurveQuadratic.new(model)
        if supply.Number_Speeds > 1.0
          clg_energy_input_ratio_f_of_flow_object.setName("Cool-EIR-fFF#{speed + 1}")
          clg_energy_input_ratio_f_of_flow_object.setCoefficient1Constant(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][0])
          clg_energy_input_ratio_f_of_flow_object.setCoefficient2x(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][1])
          clg_energy_input_ratio_f_of_flow_object.setCoefficient3xPOW2(supply.COOL_EIR_FFLOW_SPEC_coefficients[speed][2])
        else
          clg_energy_input_ratio_f_of_flow_object.setName("Cool-EIR-fFF")
          clg_energy_input_ratio_f_of_flow_object.setCoefficient1Constant(supply.COOL_EIR_FFLOW_SPEC_coefficients[0])
          clg_energy_input_ratio_f_of_flow_object.setCoefficient2x(supply.COOL_EIR_FFLOW_SPEC_coefficients[1])
          clg_energy_input_ratio_f_of_flow_object.setCoefficient3xPOW2(supply.COOL_EIR_FFLOW_SPEC_coefficients[2])
        end
        clg_energy_input_ratio_f_of_flow_object.setMinimumValueofx(0.0)
        clg_energy_input_ratio_f_of_flow_object.setMaximumValueofx(2.0)
        # clg_energy_input_ratio_f_of_flow_object.setMinimumValueofy(0.0) # tk
        # clg_energy_input_ratio_f_of_flow_object.setMaximumValueofy(2.0) # tk
        clg_energy_input_ratio_f_of_flow << clg_energy_input_ratio_f_of_flow_object

      end

      if supply.compressor_speeds == 1.0

        if air_conditioner.IsIdealAC
          # tk constant curves here
        else

        end

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, coolingseasonschedule, clg_cap_f_of_temp[0], clg_cap_f_of_flow[0], clg_energy_input_ratio_f_of_temp[0], clg_energy_input_ratio_f_of_flow[0], clg_part_load_ratio[0])
        clg_coil.setName("DX Cooling Coil")
        if hpOutputCapacity != "Autosize"
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(hpOutputCapacity,"Btu/h","W").get)
        end
        if air_conditioner.IsIdealAC
          clg_coil.setRatedSensibleHeatRatio(0.8)
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0))
          if hpOutputCapacity != "Autosize"
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
        else
          clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[0])
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0 / supply.CoolingEIR[0]))
          if hpOutputCapacity != "Autosize"
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
        end
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(supply.fan_power / OpenStudio::convert(1.0,"cfm","m^3/s").get))

        if misc.SimTestSuiteBuilding == constants.TestBldgMinimal or air_conditioner.IsIdealAC
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

        if supply.CondenserType == constants.CondenserTypeAir
          clg_coil.setCondenserType("AirCooled")
        else
          clg_coil.setCondenserType("EvaporativelyCooled")
          clg_coil.setEvaporativeCondenserEffectiveness(OpenStudio::OptionalDouble.new(1))
          clg_coil.setEvaporativeCondenserAirFlowRate(OpenStudio::OptionalDouble.new(OpenStudio::convert(850.0,"cfm","m^3/s").get * sizing.cooling_cap))
          clg_coil.setEvaporativeCondenserPumpRatePowerConsumption(OpenStudio::OptionalDouble.new(0))
        end

        if not hasHeatPump
          clg_coil.setCrankcaseHeaterCapacity(OpenStudio::OptionalDouble.new(OpenStudio::convert(supply.Crankcase,"kW","W").get))
          clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get))
        else
          #For heat pumps, we handle the crankcase heater using EMS so the heater energy shows up under cooling energy
          clg_coil.setCrankcaseHeaterCapacity(OpenStudio::OptionalDouble.new(0.0))
          clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(10.0))
        end

        if air_conditioner.IsIdealAC
          # stuff
        end

      else

        clg_coil = OpenStudio::Model::CoilCoolingDXTwoSpeed.new(model, coolingseasonschedule, clg_cap_f_of_temp[1], clg_cap_f_of_flow[1], clg_energy_input_ratio_f_of_temp[1], clg_energy_input_ratio_f_of_flow[1], clg_part_load_ratio[1], clg_cap_f_of_temp[0], clg_energy_input_ratio_f_of_temp[0])
        clg_coil.setName("DX Cooling Coil")

        clg_coil.setCondenserType(supply.CondenserType)

        # stuff

        # Make sure Rated Air Flow Rates are in descending order
        if hpOutputCapacity != "Autosize"
          flowrates = Array.new
          (0...supply.Number_Speeds).to_a.each do |speed|
            flowrates << supply.CFM_TON_Rated[speed] * hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * supply.Capacity_Ratio_Cooling[speed]
          end
        end

        # if not flowrates == flowrates.sort
        #   runner.registerError("AC or heat pump cooling coil rated air flow rates are not in ascending order ({value:.{digits}f}). Ensure that Capacity Ratio and Fan Speed Ratio inputs are correct.".format(value=flowrates, digits=2)")
        # end

        (0...supply.Number_Speeds).to_a.each do |speed|
          if hpOutputCapacity != "Autosize"
            clg_coil.setRatedHighSpeedTotalCoolingCapacity(OpenStudio::OptionalDouble.new(hpOutputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[speed]))
          end
          clg_coil.setRatedHighSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(supply.SHR_Rated[speed]))
          clg_coil.setRatedHighSpeedCOP(1.0 / supply.CoolingEIR[speed])
          if hpOutputCapacity != "Autosize"
            clg_coil.setRatedHighSpeedAirFlowRate(OpenStudio::OptionalDouble.new(flowrates[speed]))
          end

          # stuff

          if supply.CondenserType == constants.CondenserTypeAir

          else

          end

        end

      end

    end

    # _processSystemFan
    # HVAC Supply Fan

    supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
    supply_fan_availability.setName("SupplyFanAvailability")
    supply_fan_availability.setValue(1)

    # # This allows for simulation of constant speed fans for all systems other than 2-speed AC or HP
    # if (hasHeatPump or hasAirConditioner or hasMiniSplitHP) and supply.Number_Speeds > 1
    #
    #   fan_power_curve = OpenStudio::Model::CurveExponent.new(model)
    #   fan_power_curve.setName("FanPowerCurve")
    #   fan_power_curve.setCoefficient1Constant(0)
    #   fan_power_curve.setCoefficient2Constant(1)
    #   fan_power_curve.setCoefficient3Constant(3)
    #   fan_power_curve.setMinimumValueofx(-100)
    #   fan_power_curve.setMaximumValueofx(100)
    #
    #   fan_eff_curve = OpenStudio::Model::CurveCubic.new(model)
    #   fan_eff_curve.setName"FanEffCurve"
    #   fan_eff_curve.setCoefficient1Constant(0)
    #   fan_eff_curve.setCoefficient2x(1)
    #   fan_eff_curve.setCoefficient3xPOW2(0)
    #   fan_eff_curve.setCoefficient4xPOW3(0)
    #   fan_eff_curve.setMinimumValueofx(0)
    #   fan_eff_curve.setMaximumValueofx(1)
    #   fan_eff_curve.setMinimumCurveOutput(0)
    #   fan_eff_curve.setMaximumCurveOutput(1)
    #
    #   fan = OpenStudio::Model::FanOnOff.new(model, always_on, fan_power_curve, fan_eff_curve)
    #
    #   fan.setEndUseSubcategory("HVACFan")
    # else
    #
    #   fan = OpenStudio::Model::FanOnOff.new(model, always_on)
    #
    #   fan.setEndUseSubcategory("HVACFan")
    # end

    fan = OpenStudio::Model::FanOnOff.new(model, supply_fan_availability)
    fan.setName("Supply Fan")

    fan.setEndUseSubcategory("HVACFan")

    fan.setFanEfficiency(supply.eff)
    fan.setPressureRise(supply.static)

    # if test_suite.min_test_ideal_systems or air_conditioner.IsIdealAC
    #   fan.setMaximumFlowRate(OpenStudio::convert(supply.Fan_AirFlowRate + 0.05,"cfm","m^3/s").get)
    # else
    #   fan.setMaximumFlowRate(supply.fanspeed_ratio.max * OpenStudio::convert(supply.Fan_AirFlowRate + 0.01,"cfm","m^3/s").get)
    # end

    fan.setMotorEfficiency(1)

    if test_suite.min_test_ideal_systems or air_conditioner.IsIdealAC
      fan.setMotorInAirstreamFraction(0)
    else
      fan.setMotorInAirstreamFraction(1)
    end

    supply_fan_operation = OpenStudio::Model::ScheduleConstant.new(model)
    supply_fan_operation.setName("SupplyFanOperation")
    supply_fan_operation.setValue(0)

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAir.new(model, always_on, fan, htg_coil, clg_coil, hp_supp_heater)
    air_loop_unitary.setName("Forced Air System")
    air_loop_unitary.setMaximumSupplyAirTemperaturefromSupplementalHeater(OpenStudio::convert(supply.max_temp,"F","C").get)
    air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(OpenStudio::convert(supply.max_supp_heating_temp,"F","C").get)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
    # air_loop_unitary.setMaximumSupplyAirTemperature() tk

    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisNeeded(0.0)

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    runner.registerInfo("Added #{selected_hp} DX cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    runner.registerInfo("Added #{selected_hp} DX heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    runner.registerInfo("Added electric heating coil '#{hp_supp_heater.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")

    zones = model.getThermalZones
    zones.each do |zone|

      if selected_living.get.handle.to_s == zone.handle.to_s

        air_loop.addBranchForZone(zone, air_loop_unitary.to_StraightComponent)
        air_loop_unitary.setControllingZone(zone)

        # _processSystemDemandSideAir
        # Demand Side

        # Supply Air
        zone_splitter = air_loop.zoneSplitter
        zone_splitter.setName("Zone Splitter")
        # zone_splitter.addToNote(air_demand_inlet_node)

        diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, always_on)
        diffuser_living.setName("Living Zone Direct Air")
        # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
        air_loop.addBranchForZone(zone, diffuser_living.to_StraightComponent)

        setpoint_mgr = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
        setpoint_mgr.setControlZone(zone)
        setpoint_mgr.addToNode(air_supply_outlet_node)

        # Return Air

        # tk need to replace the mixer with a return plenum
        # zone_mixer = air_loop.zoneMixer
        # zone_mixer.disconnect
        # return_plenum = OpenStudio::Model::AirLoopHVACReturnPlenum.new(model)
        # return_plenum.setName("Return Plenum")
        # return_plenum.addToNode(air_demand_outlet_node)
        # air_loop.addBranchForZone(zone, return_plenum.to_StraightComponent)

        air_loop.addBranchForZone(zone)
        runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{zone.name}'")

      end

      if not selected_fbsmt.empty?

        if selected_fbsmt.get.handle.to_s == zone.handle.to_s

          diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, always_on)
          diffuser_fbsmt.setName("FBsmt Zone Direct Air")
          # diffuser_fbsmt.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
          air_loop.addBranchForZone(zone, diffuser_fbsmt.to_StraightComponent)

          air_loop.addBranchForZone(zone)
          runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{zone.name}'")

        end

      end

    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessAirSourceHeatPump.new.registerWithApplication