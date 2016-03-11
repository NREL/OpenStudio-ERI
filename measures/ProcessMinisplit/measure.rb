# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/psychrometrics"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class ProcessMinisplit < OpenStudio::Ruleset::ModelUserScript

  class Supply
    def initialize
    end
    attr_accessor(:HPCoolingOversizingFactor, :SpaceConditionedMult, :MiniSplitHPHeatingCapacityOffset, :CoolingEIR, :Capacity_Ratio_Cooling, :CoolingCFMs, :SHR_Rated, :fanspeed_ratio, :min_flow_ratio, :static, :fan_power, :eff, :HeatingEIR, :Capacity_Ratio_Heating, :HeatingCFMs, :htg_supply_air_temp, :supp_htg_max_supply_temp, :min_hp_temp, :supp_htg_max_outdoor_temp, :max_defrost_temp)
  end
  
  class Curves
    def initialize
    end
    attr_accessor(:mshp_indices, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :Number_Speeds, :HEAT_CAP_FT_SPEC_coefficients, :HEAT_EIR_FT_SPEC_coefficients, :HEAT_CAP_FFLOW_SPEC_coefficients, :HEAT_EIR_FFLOW_SPEC_coefficients, :COOL_CLOSS_FPLR_SPEC_coefficients, :HEAT_CLOSS_FPLR_SPEC_coefficients)
  end

  # human readable name
  def name
    return "Set Residential Mini-Split Heat Pump"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC cooling components (except electric baseboard) from the building and adds a mini-split heat pump."
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make a double argument for minisplit cooling rated seer
    miniSplitHPCoolingRatedSEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingRatedSEER", true)
    miniSplitHPCoolingRatedSEER.setDisplayName("Rated SEER")
    miniSplitHPCoolingRatedSEER.setUnits("Btu/W-h")
    miniSplitHPCoolingRatedSEER.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    miniSplitHPCoolingRatedSEER.setDefaultValue(14.5)
    args << miniSplitHPCoolingRatedSEER
    
    #make a double argument for minisplit cooling oversize factor
    miniSplitHPCoolingOversizeFactor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingOversizeFactor", true)
    miniSplitHPCoolingOversizeFactor.setDisplayName("Oversize Factor")
    miniSplitHPCoolingOversizeFactor.setUnits("frac")
    miniSplitHPCoolingOversizeFactor.setDescription("Used to scale the auto-sized cooling capacity.")
    miniSplitHPCoolingOversizeFactor.setDefaultValue(1.0)
    args << miniSplitHPCoolingOversizeFactor    
    
    #make a double argument for minisplit cooling min capacity
    miniSplitHPCoolingMinCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMinCapacity", true)
    miniSplitHPCoolingMinCapacity.setDisplayName("Minimum Cooling Capacity")
    miniSplitHPCoolingMinCapacity.setUnits("frac")
    miniSplitHPCoolingMinCapacity.setDescription("Minimum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    miniSplitHPCoolingMinCapacity.setDefaultValue(0.4)
    args << miniSplitHPCoolingMinCapacity     
    
    #make a double argument for minisplit cooling max capacity
    miniSplitHPCoolingMaxCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMaxCapacity", true)
    miniSplitHPCoolingMaxCapacity.setDisplayName("Maximum Cooling Capacity")
    miniSplitHPCoolingMaxCapacity.setUnits("frac")
    miniSplitHPCoolingMaxCapacity.setDescription("Maximum cooling capacity as a fraction of the nominal cooling capacity at rated conditions.")
    miniSplitHPCoolingMaxCapacity.setDefaultValue(1.2)
    args << miniSplitHPCoolingMaxCapacity    
    
    #make a double argument for minisplit rated shr
    miniSplitHPRatedSHR = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPRatedSHR", true)
    miniSplitHPRatedSHR.setDisplayName("Rated SHR")
    miniSplitHPRatedSHR.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    miniSplitHPRatedSHR.setDefaultValue(0.73)
    args << miniSplitHPRatedSHR        
    
    #make a double argument for minisplit cooling min airflow
    miniSplitHPCoolingMinAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMinAirflow", true)
    miniSplitHPCoolingMinAirflow.setDisplayName("Minimum Cooling Airflow")
    miniSplitHPCoolingMinAirflow.setUnits("cfm/ton")
    miniSplitHPCoolingMinAirflow.setDescription("Minimum cooling cfm divided by the nominal rated cooling capacity.")
    miniSplitHPCoolingMinAirflow.setDefaultValue(200.0)
    args << miniSplitHPCoolingMinAirflow      
    
    #make a double argument for minisplit cooling max airflow
    miniSplitHPCoolingMaxAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPCoolingMaxAirflow", true)
    miniSplitHPCoolingMaxAirflow.setDisplayName("Maximum Cooling Airflow")
    miniSplitHPCoolingMaxAirflow.setUnits("cfm/ton")
    miniSplitHPCoolingMaxAirflow.setDescription("Maximum cooling cfm divided by the nominal rated cooling capacity.")
    miniSplitHPCoolingMaxAirflow.setDefaultValue(425.0)
    args << miniSplitHPCoolingMaxAirflow     
    
    #make a double argument for minisplit rated hspf
    miniSplitHPHeatingRatedHSPF = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingRatedHSPF", true)
    miniSplitHPHeatingRatedHSPF.setDisplayName("Rated HSPF")
    miniSplitHPHeatingRatedHSPF.setUnits("Btu/W-h")
    miniSplitHPHeatingRatedHSPF.setDescription("The Heating Seasonal Performance Factor (HSPF) is a measure of a heat pump's energy efficiency over one heating season.")
    miniSplitHPHeatingRatedHSPF.setDefaultValue(8.2)
    args << miniSplitHPHeatingRatedHSPF
    
    #make a double argument for minisplit heating capacity offset
    miniSplitHPHeatingCapacityOffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingCapacityOffset", true)
    miniSplitHPHeatingCapacityOffset.setDisplayName("Heating Capacity Offset")
    miniSplitHPHeatingCapacityOffset.setUnits("Btu/h")
    miniSplitHPHeatingCapacityOffset.setDescription("The difference between the nominal rated heating capacity and the nominal rated cooling capacity.")
    miniSplitHPHeatingCapacityOffset.setDefaultValue(2300.0)
    args << miniSplitHPHeatingCapacityOffset    
    
    #make a double argument for minisplit heating min capacity
    miniSplitHPHeatingMinCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMinCapacity", true)
    miniSplitHPHeatingMinCapacity.setDisplayName("Minimum Heating Capacity")
    miniSplitHPHeatingMinCapacity.setUnits("frac")
    miniSplitHPHeatingMinCapacity.setDescription("Minimum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    miniSplitHPHeatingMinCapacity.setDefaultValue(0.3)
    args << miniSplitHPHeatingMinCapacity     
    
    #make a double argument for minisplit heating max capacity
    miniSplitHPHeatingMaxCapacity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMaxCapacity", true)
    miniSplitHPHeatingMaxCapacity.setDisplayName("Maximum Heating Capacity")
    miniSplitHPHeatingMaxCapacity.setUnits("frac")
    miniSplitHPHeatingMaxCapacity.setDescription("Maximum heating capacity as a fraction of nominal heating capacity at rated conditions.")
    miniSplitHPHeatingMaxCapacity.setDefaultValue(1.2)
    args << miniSplitHPHeatingMaxCapacity        
    
    #make a double argument for minisplit heating min airflow
    miniSplitHPHeatingMinAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMinAirflow", true)
    miniSplitHPHeatingMinAirflow.setDisplayName("Minimum Heating Airflow")
    miniSplitHPHeatingMinAirflow.setUnits("cfm/ton")
    miniSplitHPHeatingMinAirflow.setDescription("Minimum heating cfm divided by the nominal rated heating capacity.")
    miniSplitHPHeatingMinAirflow.setDefaultValue(200.0)
    args << miniSplitHPHeatingMinAirflow     
    
    #make a double argument for minisplit heating min airflow
    miniSplitHPHeatingMaxAirflow = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPHeatingMaxAirflow", true)
    miniSplitHPHeatingMaxAirflow.setDisplayName("Maximum Heating Airflow")
    miniSplitHPHeatingMaxAirflow.setUnits("cfm/ton")
    miniSplitHPHeatingMaxAirflow.setDescription("Maximum heating cfm divided by the nominal rated heating capacity.")
    miniSplitHPHeatingMaxAirflow.setDefaultValue(400.0)
    args << miniSplitHPHeatingMaxAirflow         
    
    #make a double argument for minisplit supply fan power
    miniSplitHPSupplyFanPower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPSupplyFanPower", true)
    miniSplitHPSupplyFanPower.setDisplayName("Supply Fan Power")
    miniSplitHPSupplyFanPower.setUnits("W/cfm")
    miniSplitHPSupplyFanPower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the fan.")
    miniSplitHPSupplyFanPower.setDefaultValue(0.07)
    args << miniSplitHPSupplyFanPower     
    
    #make a double argument for minisplit min temp
    miniSplitHPMinT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("miniSplitHPMinT", true)
    miniSplitHPMinT.setDisplayName("Min Temp")
    miniSplitHPMinT.setUnits("degrees F")
    miniSplitHPMinT.setDescription("Outdoor dry-bulb temperature below which compressor turns off.")
    miniSplitHPMinT.setDefaultValue(5.0)
    args << miniSplitHPMinT
    
    #make a bool argument for whether the minisplit is cold climate
    miniSplitHPIsColdClimate = OpenStudio::Ruleset::OSArgument::makeBoolArgument("miniSplitHPIsColdClimate", true)
    miniSplitHPIsColdClimate.setDisplayName("Is Cold Climate")
    miniSplitHPIsColdClimate.setDescription("Specifies whether the heat pump is a so called 'cold climate heat pump'.")
    miniSplitHPIsColdClimate.setDefaultValue(false)
    args << miniSplitHPIsColdClimate
    
    #make a choice argument for minisplit cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end

    #make a string argument for minisplit cooling output capacity
    miniSplitCoolingOutputCapacity = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("miniSplitCoolingOutputCapacity", cap_display_names, true)
    miniSplitCoolingOutputCapacity.setDisplayName("Cooling Output Capacity")
    miniSplitCoolingOutputCapacity.setDefaultValue("Autosize")
    args << miniSplitCoolingOutputCapacity       
    
    #make a choice argument for living thermal zone
    thermal_zones = model.getThermalZones
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
        thermal_zone_args << thermal_zone.name.to_s
    end
    if not thermal_zone_args.include?(Constants.LivingZone)
        thermal_zone_args << Constants.LivingZone
    end
    living_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_thermal_zone", thermal_zone_args, true)
    living_thermal_zone.setDisplayName("Living thermal zone")
    living_thermal_zone.setDescription("Select the living thermal zone")
    living_thermal_zone.setDefaultValue(Constants.LivingZone)
    args << living_thermal_zone    
    
    #make a choice argument for finished basement thermal zone
    thermal_zones = model.getThermalZones
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
        thermal_zone_args << thermal_zone.name.to_s
    end
    if not thermal_zone_args.include?(Constants.FinishedBasementZone)
        thermal_zone_args << Constants.FinishedBasementZone
    end
    fbasement_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_thermal_zone", thermal_zone_args, true)
    fbasement_thermal_zone.setDisplayName("Finished Basement thermal zone")
    fbasement_thermal_zone.setDescription("Select the finished basement thermal zone")
    fbasement_thermal_zone.setDefaultValue(Constants.FinishedBasementZone)
    args << fbasement_thermal_zone    
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	living_thermal_zone_r = runner.getStringArgumentValue("living_thermal_zone",user_arguments)
    living_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, living_thermal_zone_r, runner)
    if living_thermal_zone.nil?
        return false
    end
	fbasement_thermal_zone_r = runner.getStringArgumentValue("fbasement_thermal_zone",user_arguments)
    fbasement_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, fbasement_thermal_zone_r, runner, false)    
    
    curves = Curves.new
    supply = Supply.new
    
    miniSplitHPCoolingRatedSEER = runner.getDoubleArgumentValue("miniSplitHPCoolingRatedSEER",user_arguments) 
    miniSplitHPCoolingMinCapacity = runner.getDoubleArgumentValue("miniSplitHPCoolingMinCapacity",user_arguments) 
    miniSplitHPCoolingMaxCapacity = runner.getDoubleArgumentValue("miniSplitHPCoolingMaxCapacity",user_arguments) 
    miniSplitHPCoolingMinAirflow = runner.getDoubleArgumentValue("miniSplitHPCoolingMinAirflow",user_arguments) 
    miniSplitHPCoolingMaxAirflow = runner.getDoubleArgumentValue("miniSplitHPCoolingMaxAirflow",user_arguments) 
    miniSplitHPRatedSHR = runner.getDoubleArgumentValue("miniSplitHPRatedSHR",user_arguments) 
    miniSplitHPSupplyFanPower = runner.getDoubleArgumentValue("miniSplitHPSupplyFanPower",user_arguments) 
    miniSplitHPCoolingOversizeFactor = runner.getDoubleArgumentValue("miniSplitHPCoolingOversizeFactor",user_arguments) 
    miniSplitHPHeatingCapacityOffset = runner.getDoubleArgumentValue("miniSplitHPHeatingCapacityOffset",user_arguments) 
    miniSplitHPHeatingRatedHSPF = runner.getDoubleArgumentValue("miniSplitHPHeatingRatedHSPF",user_arguments) 
    miniSplitHPHeatingMinCapacity = runner.getDoubleArgumentValue("miniSplitHPHeatingMinCapacity",user_arguments) 
    miniSplitHPHeatingMaxCapacity = runner.getDoubleArgumentValue("miniSplitHPHeatingMaxCapacity",user_arguments) 
    miniSplitHPHeatingMinAirflow = runner.getDoubleArgumentValue("miniSplitHPHeatingMinAirflow",user_arguments) 
    miniSplitHPHeatingMaxAirflow = runner.getDoubleArgumentValue("miniSplitHPHeatingMaxAirflow",user_arguments) 
    miniSplitHPMinT = runner.getDoubleArgumentValue("miniSplitHPMinT",user_arguments) 
    miniSplitHPIsColdClimate = runner.getBoolArgumentValue("miniSplitHPIsColdClimate",user_arguments)    
    miniSplitCoolingOutputCapacity = runner.getStringArgumentValue("miniSplitCoolingOutputCapacity",user_arguments)
    unless miniSplitCoolingOutputCapacity == "Autosize"
      miniSplitCoolingOutputCapacity = OpenStudio::convert(miniSplitCoolingOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
    end       
    
    heatingseasonschedule = HelperMethods.get_heating_or_cooling_season_schedule_object(model, runner, "HeatingSeasonSchedule")
    coolingseasonschedule = HelperMethods.get_heating_or_cooling_season_schedule_object(model, runner, "CoolingSeasonSchedule")
    if heatingseasonschedule.nil? or coolingseasonschedule.nil?
        runner.registerError("A heating season schedule named 'HeatingSeasonSchedule' and/or cooling season schedule named 'CoolingSeasonSchedule' has not yet been assigned. Apply the 'Set Residential Heating/Cooling Setpoints and Schedules' measure first.")
        return false
    end    
    
    # Check if has equipment
    ptacs = model.getZoneHVACPackagedTerminalAirConditioners
    ptacs.each do |ptac|
      thermalZone = ptac.thermalZone.get
      runner.registerInfo("Removed '#{ptac.name}' from thermal zone '#{thermalZone.name}'")
      ptac.remove
    end
    airLoopHVACs = model.getAirLoopHVACs
    airLoopHVACs.each do |airLoopHVAC|
      thermalZones = airLoopHVAC.thermalZones
      thermalZones.each do |thermalZone|
        if living_thermal_zone.handle.to_s == thermalZone.handle.to_s
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
    hasElecBaseboard = false
    if model.getZoneHVACBaseboardConvectiveElectrics.length > 0
      hasElecBaseboard = true
    end    
        
    # _processAirSystem       
        
    has_cchp = miniSplitHPIsColdClimate
    
    curves.mshp_indices = [1,3,5,9]
    
    # Cooling Coil
    curves = get_cooling_coefficients(runner, Constants.Num_Speeds_MSHP, false, true, curves)

    curves, supply = _processAirSystemMiniSplitCooling(runner, miniSplitHPCoolingRatedSEER, miniSplitHPCoolingMinCapacity, miniSplitHPCoolingMaxCapacity, miniSplitHPCoolingMinAirflow, miniSplitHPCoolingMaxAirflow, miniSplitHPRatedSHR, miniSplitHPSupplyFanPower, curves, supply)
                                           
    supply.HPCoolingOversizingFactor = miniSplitHPCoolingOversizeFactor
    supply.MiniSplitHPHeatingCapacityOffset = miniSplitHPHeatingCapacityOffset                                           
    
    if not hasElecBaseboard
        runner.registerWarning("Mini-split heat pumps are not simulated with back-up electric resistance heaters. Consider adding an Electric Baseboard heater, if desired.")
    end
    
    # Heating Coil
    curves = get_heating_coefficients(runner, Constants.Num_Speeds_MSHP, false, curves, miniSplitHPMinT)
                                                    
    curves, supply = _processAirSystemMiniSplitHeating(runner, miniSplitHPHeatingRatedHSPF, miniSplitHPHeatingMinCapacity, miniSplitHPHeatingMaxCapacity, miniSplitHPHeatingMinAirflow, miniSplitHPHeatingMaxAirflow, miniSplitHPSupplyFanPower, miniSplitHPMinT, curves, supply)    
    
    # _processCurvesSupplyFan
    
    const_biquadratic = OpenStudio::Model::CurveBiquadratic.new(model)
    const_biquadratic.setName("ConstantBiquadratic")
    const_biquadratic.setCoefficient1Constant(1)
    const_biquadratic.setCoefficient2x(0)
    const_biquadratic.setCoefficient3xPOW2(0)
    const_biquadratic.setCoefficient4y(0)
    const_biquadratic.setCoefficient5yPOW2(0)
    const_biquadratic.setCoefficient6xTIMESY(0)
    const_biquadratic.setMinimumValueofx(-100)
    const_biquadratic.setMaximumValueofx(100)
    const_biquadratic.setMinimumValueofy(-100)
    const_biquadratic.setMaximumValueofy(100)    
    
    # _processCurvesMiniSplitHP
    
    htg_coil_stage_data = []
    curves.mshp_indices.each do |i|
        # Heating Capacity f(T). These curves were designed for E+ and do not require unit conversion
        hp_heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        hp_heat_cap_ft.setName("HP_Heat-Cap-fT#{i+1}")
        hp_heat_cap_ft.setCoefficient1Constant(curves.HEAT_CAP_FT_SPEC_coefficients[i][0])
        hp_heat_cap_ft.setCoefficient2x(curves.HEAT_CAP_FT_SPEC_coefficients[i][1])
        hp_heat_cap_ft.setCoefficient3xPOW2(curves.HEAT_CAP_FT_SPEC_coefficients[i][2])
        hp_heat_cap_ft.setCoefficient4y(curves.HEAT_CAP_FT_SPEC_coefficients[i][3])
        hp_heat_cap_ft.setCoefficient5yPOW2(curves.HEAT_CAP_FT_SPEC_coefficients[i][4])
        hp_heat_cap_ft.setCoefficient6xTIMESY(curves.HEAT_CAP_FT_SPEC_coefficients[i][5])
        hp_heat_cap_ft.setMinimumValueofx(-100)
        hp_heat_cap_ft.setMaximumValueofx(100)
        hp_heat_cap_ft.setMinimumValueofy(-100)
        hp_heat_cap_ft.setMaximumValueofy(100)
    
        # Heating EIR f(T). These curves were designed for E+ and do not require unit conversion
        hp_heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        hp_heat_eir_ft.setName("HP_Heat-EIR-fT#{i+1}")
        hp_heat_eir_ft.setCoefficient1Constant(curves.HEAT_EIR_FT_SPEC_coefficients[i][0])
        hp_heat_eir_ft.setCoefficient2x(curves.HEAT_EIR_FT_SPEC_coefficients[i][1])
        hp_heat_eir_ft.setCoefficient3xPOW2(curves.HEAT_EIR_FT_SPEC_coefficients[i][2])
        hp_heat_eir_ft.setCoefficient4y(curves.HEAT_EIR_FT_SPEC_coefficients[i][3])
        hp_heat_eir_ft.setCoefficient5yPOW2(curves.HEAT_EIR_FT_SPEC_coefficients[i][4])
        hp_heat_eir_ft.setCoefficient6xTIMESY(curves.HEAT_EIR_FT_SPEC_coefficients[i][5])
        hp_heat_eir_ft.setMinimumValueofx(-100)
        hp_heat_eir_ft.setMaximumValueofx(100)
        hp_heat_eir_ft.setMinimumValueofy(-100)
        hp_heat_eir_ft.setMaximumValueofy(100)

        hp_heat_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        hp_heat_cap_fff.setName("HP_Heat-Cap-fFF#{i+1}")
        hp_heat_cap_fff.setCoefficient1Constant(curves.HEAT_CAP_FFLOW_SPEC_coefficients[i][0])
        hp_heat_cap_fff.setCoefficient2x(curves.HEAT_CAP_FFLOW_SPEC_coefficients[i][1])
        hp_heat_cap_fff.setCoefficient3xPOW2(curves.HEAT_CAP_FFLOW_SPEC_coefficients[i][2])
        hp_heat_cap_fff.setMinimumValueofx(0)
        hp_heat_cap_fff.setMaximumValueofx(2)
        hp_heat_cap_fff.setMinimumCurveOutput(0)
        hp_heat_cap_fff.setMaximumCurveOutput(2)

        hp_heat_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        hp_heat_eir_fff.setName("HP_Heat-EIR-fFF#{i+1}")
        hp_heat_eir_fff.setCoefficient1Constant(curves.HEAT_EIR_FFLOW_SPEC_coefficients[i][0])
        hp_heat_eir_fff.setCoefficient2x(curves.HEAT_EIR_FFLOW_SPEC_coefficients[i][1])
        hp_heat_eir_fff.setCoefficient3xPOW2(curves.HEAT_EIR_FFLOW_SPEC_coefficients[i][2])
        hp_heat_eir_fff.setMinimumValueofx(0)
        hp_heat_eir_fff.setMaximumValueofx(2)
        hp_heat_eir_fff.setMinimumCurveOutput(0)
        hp_heat_eir_fff.setMaximumCurveOutput(2)
        
        hp_heat_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        hp_heat_plf_fplr.setName("HP_Heat-PLF-fPLR#{i+1}")
        hp_heat_plf_fplr.setCoefficient1Constant(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[0])
        hp_heat_plf_fplr.setCoefficient2x(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[1])
        hp_heat_plf_fplr.setCoefficient3xPOW2(curves.HEAT_CLOSS_FPLR_SPEC_coefficients[2])
        hp_heat_plf_fplr.setMinimumValueofx(0)
        hp_heat_plf_fplr.setMaximumValueofx(1)
        hp_heat_plf_fplr.setMinimumCurveOutput(0.7)
        hp_heat_plf_fplr.setMaximumCurveOutput(1)        
        
        stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, hp_heat_cap_ft, hp_heat_cap_fff, hp_heat_eir_ft, hp_heat_eir_fff, hp_heat_plf_fplr, const_biquadratic)
        # stage_data.setGrossRatedHeatingCapacity(units.Btu_h2W(unit.supply.Heat_Capacity) * unit.supply.Capacity_Ratio_Heating[i])
        stage_data.setGrossRatedHeatingCOP(1 / supply.HeatingEIR[i])
        # stage_data.setRatedAirFlowRate(units.cfm2m3_s(unit.supply.HeatingCFMs[i] * units.Btu_h2Ton(unit.supply.Heat_Capacity)))
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil_stage_data[i] = stage_data
    end 
    
    clg_coil_stage_data = []
    curves.mshp_indices.each do |i|
        # Cooling Capacity f(T). These curves were designed for E+ and do not require unit conversion
        cool_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        cool_cap_ft.setName("Cool-Cap-fT#{i+1}")
        cool_cap_ft.setCoefficient1Constant(curves.COOL_CAP_FT_SPEC_coefficients[i][0])
        cool_cap_ft.setCoefficient2x(curves.COOL_CAP_FT_SPEC_coefficients[i][1])
        cool_cap_ft.setCoefficient3xPOW2(curves.COOL_CAP_FT_SPEC_coefficients[i][2])
        cool_cap_ft.setCoefficient4y(curves.COOL_CAP_FT_SPEC_coefficients[i][3])
        cool_cap_ft.setCoefficient5yPOW2(curves.COOL_CAP_FT_SPEC_coefficients[i][4])
        cool_cap_ft.setCoefficient6xTIMESY(curves.COOL_CAP_FT_SPEC_coefficients[i][5])
        cool_cap_ft.setMinimumValueofx(13.88)
        cool_cap_ft.setMaximumValueofx(23.88)
        cool_cap_ft.setMinimumValueofy(18.33)
        cool_cap_ft.setMaximumValueofy(51.66)

        # Cooling EIR f(T). These curves were designed for E+ and do not require unit conversion
        cool_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
        cool_eir_ft.setName("Cool-EIR-fT#{i+1}")
        cool_eir_ft.setCoefficient1Constant(curves.COOL_EIR_FT_SPEC_coefficients[i][0])
        cool_eir_ft.setCoefficient2x(curves.COOL_EIR_FT_SPEC_coefficients[i][1])
        cool_eir_ft.setCoefficient3xPOW2(curves.COOL_EIR_FT_SPEC_coefficients[i][2])
        cool_eir_ft.setCoefficient4y(curves.COOL_EIR_FT_SPEC_coefficients[i][3])
        cool_eir_ft.setCoefficient5yPOW2(curves.COOL_EIR_FT_SPEC_coefficients[i][4])
        cool_eir_ft.setCoefficient6xTIMESY(curves.COOL_EIR_FT_SPEC_coefficients[i][5])
        cool_eir_ft.setMinimumValueofx(13.88)
        cool_eir_ft.setMaximumValueofx(23.88)
        cool_eir_ft.setMinimumValueofy(18.33)
        cool_eir_ft.setMaximumValueofy(51.66)        
    
        cool_cap_fff = OpenStudio::Model::CurveQuadratic.new(model)
        cool_cap_fff.setName("Cool-Cap-fFF#{i+1}")
        cool_cap_fff.setCoefficient1Constant(curves.COOL_CAP_FFLOW_SPEC_coefficients[i][0])
        cool_cap_fff.setCoefficient2x(curves.COOL_CAP_FFLOW_SPEC_coefficients[i][1])
        cool_cap_fff.setCoefficient3xPOW2(curves.COOL_CAP_FFLOW_SPEC_coefficients[i][2])
        cool_cap_fff.setMinimumValueofx(0)
        cool_cap_fff.setMaximumValueofx(2)
        cool_cap_fff.setMinimumCurveOutput(0)
        cool_cap_fff.setMaximumCurveOutput(2)          

        cool_eir_fff = OpenStudio::Model::CurveQuadratic.new(model)
        cool_eir_fff.setName("Cool-EIR-fFF#{i+1}")
        cool_eir_fff.setCoefficient1Constant(curves.COOL_EIR_FFLOW_SPEC_coefficients[i][0])
        cool_eir_fff.setCoefficient2x(curves.COOL_EIR_FFLOW_SPEC_coefficients[i][1])
        cool_eir_fff.setCoefficient3xPOW2(curves.COOL_EIR_FFLOW_SPEC_coefficients[i][2])
        cool_eir_fff.setMinimumValueofx(0)
        cool_eir_fff.setMaximumValueofx(2)
        cool_eir_fff.setMinimumCurveOutput(0)
        cool_eir_fff.setMaximumCurveOutput(2)        
    
        cool_plf_fplr = OpenStudio::Model::CurveQuadratic.new(model)
        cool_plf_fplr.setName("Cool-PLF-fPLR#{i+1}")
        cool_plf_fplr.setCoefficient1Constant(curves.COOL_CLOSS_FPLR_SPEC_coefficients[0])
        cool_plf_fplr.setCoefficient2x(curves.COOL_CLOSS_FPLR_SPEC_coefficients[1])
        cool_plf_fplr.setCoefficient3xPOW2(curves.COOL_CLOSS_FPLR_SPEC_coefficients[2])
        cool_plf_fplr.setMinimumValueofx(0)
        cool_plf_fplr.setMaximumValueofx(1)
        cool_plf_fplr.setMinimumCurveOutput(0.7)
        cool_plf_fplr.setMaximumCurveOutput(1)        
        
        stage_data = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, cool_cap_ft, cool_cap_fff, cool_eir_ft, cool_eir_fff, cool_plf_fplr, const_biquadratic)
        # stage_data.setGrossRatedTotalCoolingCapacity(units.Btu_h2W(unit.supply.Cool_Capacity)*unit.supply.Capacity_Ratio_Cooling[i])
        stage_data.setGrossRatedSensibleHeatRatio(supply.SHR_Rated[i])
        stage_data.setGrossRatedCoolingCOP(1 / supply.CoolingEIR[i])
        # stage_data.setRatedAirFlowRate(units.cfm2m3_s(unit.supply.CoolingCFMs[i] * units.Btu_h2Ton(unit.supply.Cool_Capacity))) 
        stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage_data.setMaximumCyclingRate(3)
        stage_data.setLatentCapacityTimeConstant(45)
        stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
        clg_coil_stage_data[i] = stage_data        
    end
    
    # Cooling EIR f(T). These curves were designed for E+ and do not require unit conversion
    defrosteir = OpenStudio::Model::CurveBiquadratic.new(model)
    defrosteir.setName("DefrostEIR")
    defrosteir.setCoefficient1Constant(0.1528)
    defrosteir.setCoefficient2x(0)
    defrosteir.setCoefficient3xPOW2(0)
    defrosteir.setCoefficient4y(0)
    defrosteir.setCoefficient5yPOW2(0)
    defrosteir.setCoefficient6xTIMESY(0)
    defrosteir.setMinimumValueofx(-100)
    defrosteir.setMaximumValueofx(100)
    defrosteir.setMinimumValueofy(-100)
    defrosteir.setMaximumValueofy(100)
    
    # _processSystemHeatingCoil
    
    htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
    htg_coil.setName("DX Heating Coil")
    htg_coil.setAvailabilitySchedule(heatingseasonschedule)
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(OpenStudio::convert(supply.min_hp_temp,"F","C").get)
    htg_coil.setCrankcaseHeaterCapacity(0)
    htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrosteir)
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(OpenStudio::convert(supply.max_defrost_temp,"F","C").get)
    htg_coil.setDefrostStrategy("ReverseCycle")
    htg_coil.setDefrostControl("OnDemand")
    htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    htg_coil.setFuelType("Electricity")
    
    heating_indices = curves.mshp_indices
    heating_indices.each do |i|
        htg_coil.addStage(htg_coil_stage_data[i])    
    end
   
    supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, heatingseasonschedule)
    supp_htg_coil.setName("HeatPump Supp Heater")
    supp_htg_coil.setEfficiency(1)
   
    # _processSystemCoolingCoil
    
    clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
    clg_coil.setName("DX Cooling Coil")
    clg_coil.setAvailabilitySchedule(coolingseasonschedule)
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
    clg_coil.setCrankcaseHeaterCapacity(0)
    clg_coil.setFuelType("Electricity")
  
    cooling_indices = curves.mshp_indices
    cooling_indices.each do |i|
        clg_coil.addStage(clg_coil_stage_data[i])
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
    air_loop_unitary.setNumberofSpeedsforHeating(4)
    air_loop_unitary.setNumberofSpeedsforCooling(4)
    
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

    air_loop_unitary.setControllingZoneorThermostatLocation(living_thermal_zone)    
    
    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName("Zone Splitter")

    diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    diffuser_living.setName("Living Zone Direct Air")
    # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
    air_loop.addBranchForZone(living_thermal_zone, diffuser_living.to_StraightComponent)

    setpoint_mgr = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
    setpoint_mgr.setControlZone(living_thermal_zone)
    setpoint_mgr.addToNode(air_supply_outlet_node)

    air_loop.addBranchForZone(living_thermal_zone)
    runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{living_thermal_zone.name}'")

    unless fbasement_thermal_zone.nil?

        diffuser_fbsmt = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
        diffuser_fbsmt.setName("FBsmt Zone Direct Air")
        # diffuser_fbsmt.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
        air_loop.addBranchForZone(fbasement_thermal_zone, diffuser_fbsmt.to_StraightComponent)

        air_loop.addBranchForZone(fbasement_thermal_zone)
        runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{fbasement_thermal_zone.name}'")

    end    
    
    return true

  end
  
  def get_cooling_coefficients(runner, num_speeds, is_ideal_system, isHeatPump, curves)
    if not [1,2,4,Constants.Num_Speeds_MSHP].include? num_speeds
        runner.registerError("Number_Speeds = #{num_speeds} is not supported. Only 1, 2, 4, and 10 cooling equipment can be modeled.")
        return false
    end
    
    # Hard coded curves
    if is_ideal_system
        if num_speeds == 1
            curves.COOL_CAP_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.COOL_EIR_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.COOL_CAP_FFLOW_SPEC_coefficients = [1, 0, 0]
            curves.COOL_EIR_FFLOW_SPEC_coefficients = [1, 0, 0]
            
        elsif num_speeds > 1
            curves.COOL_CAP_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.COOL_EIR_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
            curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
        
        end
            
    else
        if isHeatPump
            if num_speeds == 1
                curves.COOL_CAP_FT_SPEC_coefficients = [3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]
                curves.COOL_EIR_FT_SPEC_coefficients = [-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [0.718664047, 0.41797409, -0.136638137]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [1.143487507, -0.13943972, -0.004047787]
                
            elsif num_speeds == 2
                # one set for low, one set for high
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716], [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405], [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[0.655239515, 0.511655216, -0.166894731], [0.618281092, 0.569060264, -0.187341356]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1.639108268, -0.998953996, 0.359845728], [1.570774717, -0.914152018, 0.343377302]]
        
            elsif num_speeds == 4
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.63396857, -0.093606786, 0.000918114, 0.011852512, -0.0000318307, -0.000206446],
                                                        [1.808745668, -0.041963484, 0.000545263, 0.011346539, -0.000023838, -0.000205162],
                                                        [0.112814745, 0.005638646, 0.000203427, 0.011981545, -0.0000207957, -0.000212379],
                                                        [1.141506147, -0.023973142, 0.000420763, 0.01038334, -0.0000174633, -0.000197092]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-1.380674217, 0.083176919, -0.000676029, -0.028120348, 0.000320593, -0.0000616147],
                                                        [4.817787321, -0.100122768, 0.000673499, -0.026889359, 0.00029445, -0.0000390331],
                                                        [-1.502227232, 0.05896401, -0.000439349, 0.002198465, 0.000148486, -0.000159553],
                                                        [-3.443078025, 0.115186164, -0.000852001, 0.004678056, 0.000134319, -0.000171976]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
        
            elsif num_speeds == Constants.Num_Speeds_MSHP
                # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
                curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
                curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds
                
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds

            end
                
        else #AC
            if num_speeds == 1
                curves.COOL_CAP_FT_SPEC_coefficients = [3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]
                curves.COOL_EIR_FT_SPEC_coefficients = [-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [0.718605468, 0.410099989, -0.128705457]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [1.32299905, -0.477711207, 0.154712157]
                
            elsif num_speeds == 2
                # one set for low, one set for high
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658], \
                                                        [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539], \
                                                        [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[0.65673024, 0.516470835, -0.172887149], [0.690334551, 0.464383753, -0.154507638]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1.562945114, -0.791859997, 0.230030877], [1.31565404, -0.482467162, 0.166239001]]
    
            elsif num_speeds == 4
                curves.COOL_CAP_FT_SPEC_coefficients = [[3.845135427537, -0.095933272242, 0.000924533273, 0.008939030321, -0.000021025870, -0.000191684744], \
                                                        [1.902445285801, -0.042809294549, 0.000555959865, 0.009928999493, -0.000013373437, -0.000211453245], \
                                                        [-3.176259152730, 0.107498394091, -0.000574951600, 0.005484032413, -0.000011584801, -0.000135528854], \
                                                        [1.216308942608, -0.021962441981, 0.000410292252, 0.007362335339, -0.000000025748, -0.000202117724]]
                curves.COOL_EIR_FT_SPEC_coefficients = [[-1.400822352, 0.075567798, -0.000589362, -0.024655521, 0.00032690848, -0.00010222178], \
                                                        [3.278112067, -0.07106453, 0.000468081, -0.014070845, 0.00022267912, -0.00004950051], \
                                                        [1.183747649, -0.041423179, 0.000390378, 0.021207528, 0.00011181091, -0.00034107189], \
                                                        [-3.97662986, 0.115338094, -0.000841943, 0.015962287, 0.00007757092, -0.00018579409]]
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
                
            elsif num_speeds == Constants.Num_Speeds_MSHP
                # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
                curves.COOL_CAP_FT_SPEC_coefficients = [[1.008993521905866, 0.006512749025457, 0.0, 0.003917565735935, -0.000222646705889, 0.0]] * num_speeds
                curves.COOL_EIR_FT_SPEC_coefficients = [[0.429214441601141, -0.003604841598515, 0.000045783162727, 0.026490875804937, -0.000159212286878, -0.000159062656483]] * num_speeds
                
                curves.COOL_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                curves.COOL_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
                
            end
        end
    end   
    return curves
  end
  
  def _processAirSystemMiniSplitCooling(runner, coolingSEER, cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, shr, supplyFanPower, curves, supply)
        
    curves.Number_Speeds = Constants.Num_Speeds_MSHP
    c_d = Constants.MSHP_Cd_Cooling
    cops_Norm = [1.901, 1.859, 1.746, 1.609, 1.474, 1.353, 1.247, 1.156, 1.079, 1]
    fanPows_Norm = [0.604, 0.634, 0.670, 0.711, 0.754, 0.800, 0.848, 0.898, 0.948, 1]
    
    dB_rated = 80.0      
    wB_rated = 67.0
    
    cap_nom_per = 1.0
    cfm_ton_nom = ((cfm_ton_max - cfm_ton_min)/(cap_max_per - cap_min_per)) * (cap_nom_per - cap_min_per) + cfm_ton_min
    ao = Psychrometrics.CoilAoFactor(dB_rated, wB_rated, Constants.Patm, OpenStudio::convert(1,"ton","kBtu/h").get, cfm_ton_nom, shr)
    
    supply.CoolingEIR = [0] * Constants.Num_Speeds_MSHP
    supply.Capacity_Ratio_Cooling = [0] * Constants.Num_Speeds_MSHP
    supply.CoolingCFMs = [0] * Constants.Num_Speeds_MSHP
    supply.SHR_Rated = [0] * Constants.Num_Speeds_MSHP
    
    fanPowsRated = [0] * Constants.Num_Speeds_MSHP
    eers_Rated = [0] * Constants.Num_Speeds_MSHP
    
    cop_maxSpeed = 3.5  # 3.5 is an initial guess, final value solved for below
    
    (0...Constants.Num_Speeds_MSHP).each do |i|
        supply.Capacity_Ratio_Cooling[i] = cap_min_per + i*(cap_max_per - cap_min_per)/(cops_Norm.length-1)
        supply.CoolingCFMs[i]= cfm_ton_min + i*(cfm_ton_max - cfm_ton_min)/(cops_Norm.length-1)
        
        # Calculate the SHR for each speed. Use mimnimum value of 0.98 to prevent E+ bypass factor calculation errors
        supply.SHR_Rated[i] = [Psychrometrics.CalculateSHR(dB_rated, wB_rated, Constants.Patm, 
                                                                   OpenStudio::convert(supply.Capacity_Ratio_Cooling[i],"ton","kBtu/h").get, 
                                                                   supply.CoolingCFMs[i], ao), 0.98].min
        
        fanPowsRated[i] = supplyFanPower * fanPows_Norm[i] 
        eers_Rated[i] = OpenStudio::convert(cop_maxSpeed,"W","Btu/h").get * cops_Norm[i]   
    end 
        
    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed                
    error = coolingSEER - calc_SEER_VariableSpeed(runner, eers_Rated, c_d, supply.Capacity_Ratio_Cooling, supply.CoolingCFMs, fanPowsRated, true, curves.Number_Speeds, curves)                                                            
    error1 = error
    error2 = error
    
    itmax = 50  # maximum iterations
    cvg = false
    final_n = nil
    
    (1...itmax+1).each do |n|
        final_n = n
        (0...Constants.Num_Speeds_MSHP).each do |i|
            eers_Rated[i] = OpenStudio::convert(cop_maxSpeed,"W","Btu/h").get * cops_Norm[i]
        end
        
        error = coolingSEER - calc_SEER_VariableSpeed(runner, eers_Rated, c_d, supply.Capacity_Ratio_Cooling, supply.CoolingCFMs, fanPowsRated, 
                                                     true, curves.Number_Speeds, curves)
        
        cop_maxSpeed,cvg,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2 = HelperMethods.Iterate(cop_maxSpeed,error,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2,n,cvg)
    
        if cvg 
            break
        end
    end

    if not cvg or final_n > itmax
        cop_maxSpeed = OpenStudio::Convert(0.547*coolingSEER - 0.104,"Btu/h","W").get  # Correlation developed from JonW's MatLab scripts. Only used is an EER cannot be found.   
        runner.registerWarning('Mini-split heat pump COP iteration failed to converge. Setting to default value.')
    end
        
    (0...Constants.Num_Speeds_MSHP).each do |i|
        supply.CoolingEIR[i] = HVAC.calc_EIR_from_EER(OpenStudio::convert(cop_maxSpeed,"W","Btu/h").get * cops_Norm[i], fanPowsRated[i])
    end

    curves.COOL_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0]    # Linear part load model

    supply.fanspeed_ratio = [1]
    supply.min_flow_ratio = supply.CoolingCFMs.min / supply.CoolingCFMs.max

    # Supply Fan
    supply.static = UnitConversion.inH2O2Pa(0.1) # Pascal
    supply.fan_power = supplyFanPower
    supply.eff = OpenStudio::convert(supply.static / supply.fan_power,"cfm","m^3/s").get  # Overall Efficiency of the Supply Fan, Motor and Drive
    
    return curves, supply

  end
  
  def calc_SEER_VariableSpeed(runner, eer_A, c_d, capacityRatio, cfm_Tons, supplyFanPower_Rated, isHeatPump, num_speeds, curves)
    
    #Note: Make sure this method still works for BEopt central, variable speed units, which have 4 speeds (if needed in future)
    
    curves = get_cooling_coefficients(runner, num_speeds, false, isHeatPump, curves)

    n_max = (eer_A.length-1)-3 # Don't use max speed
    n_min = 0
    n_int = (n_min + (n_max-n_min)/3.0).ceil.to_i

    wBin = 67
    tout_B = 82
    tout_E = 87
    tout_F = 67
    if num_speeds == Constants.Num_Speeds_MSHP
        wBin = OpenStudio::convert(wBin,"F","C").get
        tout_B = OpenStudio::convert(tout_B,"F","C").get
        tout_E = OpenStudio::convert(tout_E,"F","C").get
        tout_F = OpenStudio::convert(tout_F,"F","C").get
    end

    eir_A2 = HVAC.calc_EIR_from_EER(eer_A[n_max], supplyFanPower_Rated[n_max])    
    eir_B2 = eir_A2 * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_EIR_FT_SPEC_coefficients[n_max]) 
    
    eir_Av = HVAC.calc_EIR_from_EER(eer_A[n_int], supplyFanPower_Rated[n_int])    
    eir_Ev = eir_Av * HelperMethods.biquadratic(wBin, tout_E, curves.COOL_EIR_FT_SPEC_coefficients[n_int])
    
    eir_A1 = HVAC.calc_EIR_from_EER(eer_A[n_min], supplyFanPower_Rated[n_min])
    eir_B1 = eir_A1 * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_EIR_FT_SPEC_coefficients[n_min]) 
    eir_F1 = eir_A1 * HelperMethods.biquadratic(wBin, tout_F, curves.COOL_EIR_FT_SPEC_coefficients[n_min])
    
    q_A2 = capacityRatio[n_max]
    q_B2 = q_A2 * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_CAP_FT_SPEC_coefficients[n_max])    
    q_Ev = capacityRatio[n_int] * HelperMethods.biquadratic(wBin, tout_E, curves.COOL_CAP_FT_SPEC_coefficients[n_int])            
    q_B1 = capacityRatio[n_min] * HelperMethods.biquadratic(wBin, tout_B, curves.COOL_CAP_FT_SPEC_coefficients[n_min])
    q_F1 = capacityRatio[n_min] * HelperMethods.biquadratic(wBin, tout_F, curves.COOL_CAP_FT_SPEC_coefficients[n_min])
            
    q_A2_net = q_A2 - supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    q_B2_net = q_B2 - supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get       
    q_Ev_net = q_Ev - supplyFanPower_Rated[n_int] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    q_B1_net = q_B1 - supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    q_F1_net = q_F1 - supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    
    p_A2 = OpenStudio::convert(q_A2 * eir_A2,"Btu","W*h").get + supplyFanPower_Rated[n_max] * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_B2 = OpenStudio::convert(q_B2 * eir_B2,"Btu","W*h").get + supplyFanPower_Rated[n_max] * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_Ev = OpenStudio::convert(q_Ev * eir_Ev,"Btu","W*h").get + supplyFanPower_Rated[n_int] * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    p_B1 = OpenStudio::convert(q_B1 * eir_B1,"Btu","W*h").get + supplyFanPower_Rated[n_min] * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    p_F1 = OpenStudio::convert(q_F1 * eir_F1,"Btu","W*h").get + supplyFanPower_Rated[n_min] * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    
    q_k1_87 = q_F1_net + (q_B1_net - q_F1_net) / (82 - 67) * (87 - 67)
    q_k2_87 = q_B2_net + (q_A2_net - q_B2_net) / (95 - 82) * (87 - 82)
    n_Q = (q_Ev_net - q_k1_87) / (q_k2_87 - q_k1_87)
    m_Q = (q_B1_net - q_F1_net) / (82 - 67) * (1 - n_Q) + (q_A2_net - q_B2_net) / (95 - 82) * n_Q    
    p_k1_87 = p_F1 + (p_B1 - p_F1) / (82 - 67) * (87 - 67)
    p_k2_87 = p_B2 + (p_A2 - p_B2) / (95 - 82) * (87 - 82)
    n_E = (p_Ev - p_k1_87) / (p_k2_87 - p_k1_87)
    m_E = (p_B1 - p_F1) / (82 - 67) * (1 - n_E) + (p_A2 - p_B2) / (95 - 82) * n_E
    
    c_T_1_1 = q_A2_net / (1.1 * (95 - 65))
    c_T_1_2 = q_F1_net
    c_T_1_3 = (q_B1_net - q_F1_net) / (82 - 67)
    t_1 = (c_T_1_2 - 67*c_T_1_3 + 65*c_T_1_1) / (c_T_1_1 - c_T_1_3)
    q_T_1 = q_F1_net + (q_B1_net - q_F1_net) / (82 - 67) * (t_1 - 67)
    p_T_1 = p_F1 + (p_B1 - p_F1) / (82 - 67) * (t_1 - 67)
    eer_T_1 = q_T_1 / p_T_1 
     
    t_v = (q_Ev_net - 87*m_Q + 65*c_T_1_1) / (c_T_1_1 - m_Q)
    q_T_v = q_Ev_net + m_Q * (t_v - 87)
    p_T_v = p_Ev + m_E * (t_v - 87)
    eer_T_v = q_T_v / p_T_v
    
    c_T_2_1 = c_T_1_1
    c_T_2_2 = q_B2_net
    c_T_2_3 = (q_A2_net - q_B2_net) / (95 - 82)
    t_2 = (c_T_2_2 - 82*c_T_2_3 + 65*c_T_2_1) / (c_T_2_1 - c_T_2_3)
    q_T_2 = q_B2_net + (q_A2_net - q_B2_net) / (95 - 82) * (t_2 - 82)
    p_T_2 = p_B2 + (p_A2 - p_B2) / (95 - 82) * (t_2 - 82)
    eer_T_2 = q_T_2 / p_T_2 
    
    d = (t_2**2 - t_1**2) / (t_v**2 - t_1**2)
    b = (eer_T_1 - eer_T_2 - d * (eer_T_1 - eer_T_v)) / (t_1 - t_2 - d * (t_1 - t_v))
    c = (eer_T_1 - eer_T_2 - b * (t_1 - t_2)) / (t_1**2 - t_2**2)
    a = eer_T_2 - b * t_2 - c * t_2**2
    
    e_tot = 0
    q_tot = 0    
    t_bins = [67,72,77,82,87,92,97,102]
    frac_hours = [0.214,0.231,0.216,0.161,0.104,0.052,0.018,0.004]    
    
    (0...8).each do |_i|
        bL = ((t_bins[_i] - 65) / (95 - 65)) * (q_A2_net / 1.1)
        q_k1 = q_F1_net + (q_B1_net - q_F1_net) / (82 - 67) * (t_bins[_i] - 67)
        p_k1 = p_F1 + (p_B1 - p_F1) / (82 - 67) * (t_bins[_i] - 67)                                
        q_k2 = q_B2_net + (q_A2_net - q_B2_net) / (95 - 82) * (t_bins[_i] - 82)
        p_k2 = p_B2 + (p_A2 - p_B2) / (95 - 82) * (t_bins[_i] - 82)
                
        if bL <= q_k1
            x_k1 = bL / q_k1        
            q_Tj_N = x_k1 * q_k1 * frac_hours[_i]
            e_Tj_N = x_k1 * p_k1 * frac_hours[_i] / (1 - c_d * (1 - x_k1))
        elsif q_k1 < bL and bL <= q_k2
            q_Tj_N = bL * frac_hours[_i]
            eer_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
            e_Tj_N = q_Tj_N / eer_T_j
        else
            q_Tj_N = frac_hours[_i] * q_k2
            e_Tj_N = frac_hours[_i] * p_k2
        end
         
        q_tot = q_tot + q_Tj_N
        e_tot = e_tot + e_Tj_N   
    end

    seer = q_tot / e_tot
    return seer
  end    
  
  def get_heating_coefficients(runner, num_speeds, is_ideal_system, curves, min_compressor_temp=nil)
    # Hard coded curves
    if is_ideal_system
        if num_speeds == 1
            curves.HEAT_CAP_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.HEAT_EIR_FT_SPEC_coefficients = [1, 0, 0, 0, 0, 0]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [1, 0, 0]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [1, 0, 0]
            
        else
            curves.HEAT_CAP_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.HEAT_EIR_FT_SPEC_coefficients = [[1, 0, 0, 0, 0, 0]]*num_speeds
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]]*num_speeds
            
        end
    
    else
        if num_speeds == 1
            curves.HEAT_CAP_FT_SPEC_coefficients = [0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]
            curves.HEAT_EIR_FT_SPEC_coefficients = [0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [0.694045465, 0.474207981, -0.168253446]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [2.185418751, -1.942827919, 0.757409168]

        elsif num_speeds == 2
            
            if min_compressor_temp is None or not is_cold_climate_hp(num_speeds, min_compressor_temp)
            
                # one set for low, one set for high
                curves.HEAT_CAP_FT_SPEC_coefficients = [[0.335690634, 0.002405123, -0.0000464, 0.013498735, 0.0000499, -0.00000725], [0.306358843, 0.005376987, -0.0000579, 0.011645092, 0.0000591, -0.0000203]]
                curves.HEAT_EIR_FT_SPEC_coefficients = [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723], [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
                curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[0.741466907, 0.378645444, -0.119754733], [0.76634609, 0.32840943, -0.094701495]]
                curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[2.153618211, -1.737190609, 0.584269478], [2.001041353, -1.58869128, 0.587593517]]
                
            else
                 
                #ORNL cold climate heat pump
                curves.HEAT_CAP_FT_SPEC_coefficients = [[0.821139, 0, 0, 0.005111, -0.00002778, 0], [0.821139, 0, 0, 0.005111, -0.00002778, 0]]   
                curves.HEAT_EIR_FT_SPEC_coefficients = [[1.244947090, 0, 0, -0.006455026, 0.000026455, 0], [1.244947090, 0, 0, -0.006455026, 0.000026455, 0]]
                curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0]]
                curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0]]
             
            end
    
        elsif num_speeds == 4
            curves.HEAT_CAP_FT_SPEC_coefficients = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                                                    [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                                                    [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                                                    [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
            curves.HEAT_EIR_FT_SPEC_coefficients = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                                                    [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                                                    [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                                                    [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0], [1, 0, 0], [1, 0, 0], [1, 0, 0]]
            
        elsif num_speeds == Constants.Num_Speeds_MSHP
            # NOTE: These coefficients are in SI UNITS, which differs from the coefficients for 1, 2, and 4 speed units, which are in IP UNITS
            curves.HEAT_CAP_FT_SPEC_coefficients = [[1.1527124655908571, -0.010386676170938, 0.0, 0.011263752411403, -0.000392549621117, 0.0]] * num_speeds            
            curves.HEAT_EIR_FT_SPEC_coefficients = [[0.966475472847719, 0.005914950101249, 0.000191201688297, -0.012965668198361, 0.000042253229429, -0.000524002558712]] * num_speeds
            
            curves.HEAT_CAP_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
            curves.HEAT_EIR_FFLOW_SPEC_coefficients = [[1, 0, 0]] * num_speeds
        end
    end
    return curves
  end            
  
  def _processAirSystemMiniSplitHeating(runner, heatingHSPF, cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, supplyFanPower, min_T, curves, supply)
        
    curves.Number_Speeds = Constants.Num_Speeds_MSHP        
    c_d = Constants.MSHP_Cd_Heating        
    #COPs_Norm = [1.636, 1.757, 1.388, 1.240, 1.162, 1.119, 1.084, 1.062, 1.044, 1] #Report Avg
    #COPs_Norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1] #BEopt Default
    
    cops_Norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1] #BEopt Default
    
    fanPows_Norm = [0.577, 0.625, 0.673, 0.720, 0.768, 0.814, 0.861, 0.907, 0.954, 1]

    supply.HeatingEIR = [0] * Constants.Num_Speeds_MSHP
    supply.Capacity_Ratio_Heating = [0] * Constants.Num_Speeds_MSHP
    supply.HeatingCFMs = [0] * Constants.Num_Speeds_MSHP      
    
    fanPowsRated = [0] * Constants.Num_Speeds_MSHP
    cops_Rated = [0] * Constants.Num_Speeds_MSHP
    
    cop_maxSpeed = 3.25  # 3.35 is an initial guess, final value solved for below
    
    (0...Constants.Num_Speeds_MSHP).each do |i|        
        supply.Capacity_Ratio_Heating[i] = cap_min_per + i*(cap_max_per - cap_min_per)/(cops_Norm.length-1)
        supply.HeatingCFMs[i] = cfm_ton_min + i*(cfm_ton_max - cfm_ton_min)/(cops_Norm.length-1)            
        
        fanPowsRated[i] = supplyFanPower * fanPows_Norm[i] 
        cops_Rated[i] = cop_maxSpeed * cops_Norm[i]
    end
        
    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed                
    error = heatingHSPF - calc_HSPF_VariableSpeed(runner, cops_Rated, c_d, supply.Capacity_Ratio_Heating, supply.HeatingCFMs, 
                                                  fanPowsRated, min_T, curves.Number_Speeds, curves)                                                            
    
    error1 = error
    error2 = error
    
    itmax = 50  # maximum iterations
    cvg = false
    final_n = nil
    
    (1...itmax+1).each do |n|
        final_n = n
        (0...Constants.Num_Speeds_MSHP).each do |i|          
            cops_Rated[i] = cop_maxSpeed * cops_Norm[i]
        end
        
        error = heatingHSPF - calc_HSPF_VariableSpeed(runner, cops_Rated, c_d, supply.Capacity_Ratio_Heating, supply.CoolingCFMs, 
                                                      fanPowsRated, min_T, curves.Number_Speeds, curves)  

        cop_maxSpeed,cvg,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2 = \
                HelperMethods.Iterate(cop_maxSpeed,error,cop_maxSpeed_1,error1,cop_maxSpeed_2,error2,n,cvg)
    
        if cvg
            break
        end
    end
    
    if not cvg or final_n > itmax
        cop_maxSpeed = OpenStudio::convert(0.4174*heatingHSPF - 1.1134,"Btu/h","W").get  # Correlation developed from JonW's MatLab scripts. Only used is a COP cannot be found.   
        runner.registerWarning('Mini-split heat pump COP iteration failed to converge. Setting to default value.')
    end

    (0...Constants.Num_Speeds_MSHP).each do |i|
        supply.HeatingEIR[i] = HVAC.calc_EIR_from_COP(cop_maxSpeed * cops_Norm[i], fanPowsRated[i])
    end

    curves.HEAT_CLOSS_FPLR_SPEC_coefficients = [(1 - c_d), c_d, 0]    # Linear part load model
            
    # Supply Air Tempteratures     
    supply.htg_supply_air_temp = 105 # used for sizing heating flow rate
    supply.supp_htg_max_supply_temp = 200 # Setting to 200F since MSHPs use electric baseboard for backup, which shouldn't be limited by a supply air temperature limit
    supply.min_hp_temp = min_T          # Minimum temperature for Heat Pump operation
    supply.supp_htg_max_outdoor_temp = 40   # Moved from DOE-2. DOE-2 Default
    supply.max_defrost_temp = 40        # Moved from DOE-2. DOE-2 Default

    return curves, supply
    
  end
  
  
  def calc_HSPF_VariableSpeed(runner, cop_47, c_d, capacityRatio, cfm_Tons, supplyFanPower_Rated, min_temp, num_speeds, curves)
    
    #TODO: Make sure this method still works for BEopt central, variable speed units, which have 4 speeds, if needed in future
    
    curves = get_heating_coefficients(runner, 10, false, curves, min_temp)
    
    n_max = (cop_47.length-1.0)#-3 # Don't use max speed
    n_min = 0
    n_int = (n_min + (n_max-n_min)/3.0).ceil.to_i

    tin = 70.0
    tout_3 = 17.0
    tout_2 = 35.0
    tout_0 = 62.0
    if num_speeds == Constants.Num_Speeds_MSHP
        tin = OpenStudio::convert(tin,"F","C").get
        tout_3 = OpenStudio::convert(tout_3,"F","C").get
        tout_2 = OpenStudio::convert(tout_2,"F","C").get
        tout_0 = OpenStudio::convert(tout_0,"F","C").get
    end
    
    eir_H1_2 = HVAC.calc_EIR_from_COP(cop_47[n_max], supplyFanPower_Rated[n_max])    
    eir_H3_2 = eir_H1_2 * HelperMethods.biquadratic(tin, tout_3, curves.HEAT_EIR_FT_SPEC_coefficients[n_max])

    eir_adjv = HVAC.calc_EIR_from_COP(cop_47[n_int], supplyFanPower_Rated[n_int])    
    eir_H2_v = eir_adjv * HelperMethods.biquadratic(tin, tout_2, curves.HEAT_EIR_FT_SPEC_coefficients[n_int])
        
    eir_H1_1 = HVAC.calc_EIR_from_COP(cop_47[n_min], supplyFanPower_Rated[n_min])
    eir_H0_1 = eir_H1_1 * HelperMethods.biquadratic(tin, tout_0, curves.HEAT_EIR_FT_SPEC_coefficients[n_min])
        
    q_H1_2 = capacityRatio[n_max]
    q_H3_2 = q_H1_2 * HelperMethods.biquadratic(tin, tout_3, curves.HEAT_CAP_FT_SPEC_coefficients[n_max])    
        
    q_H2_v = capacityRatio[n_int] * HelperMethods.biquadratic(tin, tout_2, curves.HEAT_CAP_FT_SPEC_coefficients[n_int])
    
    q_H1_1 = capacityRatio[n_min]
    q_H0_1 = q_H1_1 * HelperMethods.biquadratic(tin, tout_0, curves.HEAT_CAP_FT_SPEC_coefficients[n_min])
                                  
    q_H1_2_net = q_H1_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H3_2_net = q_H3_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H2_v_net = q_H2_v + supplyFanPower_Rated[n_int] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H1_1_net = q_H1_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    q_H0_1_net = q_H0_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
                                 
    p_H1_2 = q_H1_2 * eir_H1_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H3_2 = q_H3_2 * eir_H3_2 + supplyFanPower_Rated[n_max] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_max] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H2_v = q_H2_v * eir_H2_v + supplyFanPower_Rated[n_int] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_int] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H1_1 = q_H1_1 * eir_H1_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
    p_H0_1 = q_H0_1 * eir_H0_1 + supplyFanPower_Rated[n_min] * OpenStudio::convert(1,"W","Btu/h").get * cfm_Tons[n_min] / OpenStudio::convert(1,"ton","Btu/h").get
        
    q_H35_2 = 0.9 * (q_H3_2_net + 0.6 * (q_H1_2_net - q_H3_2_net))
    p_H35_2 = 0.985 * (p_H3_2 + 0.6 * (p_H1_2 - p_H3_2))
    q_H35_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (35.0 - 47.0)
    p_H35_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (35.0 - 47.0)
    n_Q = (q_H2_v_net - q_H35_1) / (q_H35_2 - q_H35_1)
    m_Q = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (1 - n_Q) + n_Q * (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    n_E = (p_H2_v - p_H35_1) / (p_H35_2 - p_H35_1)
    m_E = (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (1.0 - n_E) + n_E * (p_H35_2 - p_H3_2) / (35.0 - 17.0)    
    
    t_OD = 5.0
    dHR = q_H1_2_net * (65.0 - t_OD) / 60.0
    
    c_T_3_1 = q_H1_1_net
    c_T_3_2 = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0)
    c_T_3_3 = 0.77 * dHR / (65.0 - t_OD)
    t_3 = (47.0 * c_T_3_2 + 65.0 * c_T_3_3 - c_T_3_1) / (c_T_3_2 + c_T_3_3)
    q_HT3_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_3 - 47.0)
    p_HT3_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_3 - 47.0)
    cop_T3_1 = q_HT3_1 / p_HT3_1
    
    c_T_v_1 = q_H2_v_net
    c_T_v_3 = c_T_3_3
    t_v = (35.0 * m_Q + 65.0 * c_T_v_3 - c_T_v_1) / (m_Q + c_T_v_3)
    q_HTv_v = q_H2_v_net + m_Q * (t_v - 35.0)
    p_HTv_v = p_H2_v + m_E * (t_v - 35.0)
    cop_Tv_v = q_HTv_v / p_HTv_v
    
    c_T_4_1 = q_H3_2_net
    c_T_4_2 = (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    c_T_4_3 = c_T_v_3
    t_4 = (17.0 * c_T_4_2 + 65.0 * c_T_4_3 - c_T_4_1) / (c_T_4_2 + c_T_4_3)
    q_HT4_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) / (35.0 - 17.0) * (t_4 - 17.0)
    p_HT4_2 = p_H3_2 + (p_H35_2 - p_H3_2) / (35.0 - 17.0) * (t_4 - 17.0)
    cop_T4_2 = q_HT4_2 / p_HT4_2
    
    d = (t_3**2 - t_4**2) / (t_v**2 - t_4**2)
    b = (cop_T4_2 - cop_T3_1 - d * (cop_T4_2 - cop_Tv_v)) / (t_4 - t_3 - d * (t_4 - t_v))
    c = (cop_T4_2 - cop_T3_1 - b * (t_4 - t_3)) / (t_4**2 - t_3**2)
    a = cop_T4_2 - b * t_4 - c * t_4**2
    
    t_bins = [62.0,57.0,52.0,47.0,42.0,37.0,32.0,27.0,22.0,17.0,12.0,7.0,2.0,-3.0,-8.0]
    frac_hours = [0.132,0.111,0.103,0.093,0.100,0.109,0.126,0.087,0.055,0.036,0.026,0.013,0.006,0.002,0.001]
        
    # T_off = min_temp
    t_off = 10.0
    t_on = t_off + 4.0
    etot = 0        
    bLtot = 0    
    
    (0...15).each do |_i|
        
        bL = ((65.0 - t_bins[_i]) / (65.0 - t_OD)) * 0.77 * dHR
        
        q_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_bins[_i] - 47.0)
        p_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_bins[_i] - 47.0)
        
        if t_bins[_i] <= 17.0 or t_bins[_i] >=45.0
            q_2 = q_H3_2_net + (q_H1_2_net - q_H3_2_net) * (t_bins[_i] - 17.0) / (47.0 - 17.0)
            p_2 = p_H3_2 + (p_H1_2 - p_H3_2) * (t_bins[_i] - 17.0) / (47.0 - 17.0)
        else
            q_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) * (t_bins[_i] - 17) / (35.0 - 17.0)
            p_2 = p_H3_2 + (p_H35_2 - p_H3_2) * (t_bins[_i] - 17.0) / (35.0 - 17.0)
        end
                
        if t_bins[_i] <= t_off
            delta = 0
        elsif t_bins[_i] >= t_on
            delta = 1.0
        else
            delta = 0.5        
        end
        
        if bL <= q_1
            x_1 = bL / q_1
            e_Tj_n = delta * x_1 * p_1 * frac_hours[_i] / (1.0 - c_d * (1.0 - x_1))
        elsif q_1 < bL and bL <= q_2
            cop_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
            e_Tj_n = delta * frac_hours[_i] * bL / cop_T_j + (1.0 - delta) * bL * (frac_hours[_i])
        else
            e_Tj_n = delta * frac_hours[_i] * p_2 + frac_hours[_i] * (bL - delta *  q_2)
        end
                
        bLtot = bLtot + frac_hours[_i] * bL
        etot = etot + e_Tj_n
    end

    hspf = bLtot / OpenStudio::convert(etot,"Btu/h","W").get    
    return hspf
  end    
  
end

# register the measure to be used by the application
ProcessMinisplit.new.registerWithApplication
