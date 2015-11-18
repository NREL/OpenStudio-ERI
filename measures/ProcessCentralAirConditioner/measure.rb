#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessCentralAirConditioner < OpenStudio::Ruleset::ModelUserScript

  class AirConditioner
    def initialize(acCoolingInstalledSEER, acNumberSpeeds, acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio, acCoolingEER, acSupplyFanPowerInstalled, acSupplyFanPowerRated, acSHRRated, acCondenserType, acCrankcase, acCrankcaseMaxT, acEERCapacityDerateFactor)
      @acCoolingInstalledSEER = acCoolingInstalledSEER
      @acNumberSpeeds = acNumberSpeeds
      @acRatedAirFlowRate = acRatedAirFlowRate
      @acFanspeedRatio = acFanspeedRatio
      @acCapacityRatio = acCapacityRatio
      @acCoolingEER = acCoolingEER
      @acSupplyFanPowerInstalled = acSupplyFanPowerInstalled
      @acSupplyFanPowerRated = acSupplyFanPowerRated
      @acSHRRated = acSHRRated
      @acCondenserType = acCondenserType
      @acCrankcase = acCrankcase
      @acCrankcaseMaxT = acCrankcaseMaxT
      @acEERCapacityDerateFactor = acEERCapacityDerateFactor
    end

    attr_accessor(:IsIdealAC)

    def ACCoolingInstalledSEER
      return @acCoolingInstalledSEER
    end

    def ACNumberSpeeds
      return @acNumberSpeeds
    end

    def ACRatedAirFlowRate
      return @acRatedAirFlowRate
    end

    def ACFanspeedRatio
      return @acFanspeedRatio
    end

    def ACCapacityRatio
      return @acCapacityRatio
    end

    def ACCoolingEER
      return @acCoolingEER
    end

    def ACSupplyFanPowerInstalled
      return @acSupplyFanPowerInstalled
    end

    def ACSupplyFanPowerRated
      return @acSupplyFanPowerRated
    end

    def ACSHRRated
      return @acSHRRated
    end

    def ACCondenserType
      return @acCondenserType
    end

    def ACCrankcase
      return @acCrankcase
    end

    def ACCrankcaseMaxT
      return @acCrankcaseMaxT
    end

    def ACEERCapacityDerateFactor
      return @acEERCapacityDerateFactor
    end
  end

  class Supply
    def initialize
    end
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor)
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
    return "Add/Replace Residential Central Air Conditioner"
  end
  
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a central air conditioner along with an on/off supply fan to a unitary air loop."
  end
  
  def modeler_description
    return "This measure parses the OSM for the CoolingSeasonSchedule. Any supply components, except for heating coils, are removed from any existing air loops or zones. Any existing air loops are also removed. A cooling DX coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A single zone reheat setpoint manager is added to the supply outlet node, and a diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
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
    selected_living.setDisplayName("Living Zone")
	selected_living.setDescription("The living zone.")
    args << selected_living

    #make a choice argument for fbsmt
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", zone_handles, zone_display_names, false)
    selected_fbsmt.setDisplayName("Finished Basement Zone")
	selected_fbsmt.setDescription("The finished basement zone.")
    args << selected_fbsmt

    #make a choice argument for central air options
    ac_display_names = OpenStudio::StringVector.new
    ac_display_names << "SEER 8"
    ac_display_names << "SEER 10"
    ac_display_names << "SEER 13"
    ac_display_names << "SEER 14"
    ac_display_names << "SEER 15"
    ac_display_names << "SEER 16"
    ac_display_names << "SEER 16 (2 Stage)"
    ac_display_names << "SEER 17"
    ac_display_names << "SEER 18"
    ac_display_names << "SEER 21"
    # ac_display_names << "SEER 24.5"

    #make a string argument for central air options
    selected_ac = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedac", ac_display_names, true)
    selected_ac.setDisplayName("Installed SEER")
	selected_ac.setUnits("Btu/W-h")
	selected_ac.setDescription("The installed Seasonal Energy Efficiency Ratio (SEER) of the air conditioner, which can be used to account for performance derating or degradation relative to the rated value.")
    selected_ac.setDefaultValue("SEER 13")
    args << selected_ac

    #make a choice argument for central air cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << "#{tons} tons"
    end

    #make a string argument for central air cooling output capacity
    selected_accap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedaccap", cap_display_names, true)
    selected_accap.setDisplayName("Cooling Output Capacity")
    selected_accap.setDefaultValue("Autosize")
    args << selected_accap

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
    selected_ac = runner.getStringArgumentValue("selectedac",user_arguments)
    acOutputCapacity = runner.getStringArgumentValue("selectedaccap",user_arguments)
    if not acOutputCapacity == "Autosize"
      acOutputCapacity = OpenStudio::convert(acOutputCapacity.split(" ")[0].to_f,"ton","Btu/h").get
    end

    acCoolingInstalledSEER = {"SEER 8"=>8.0, "SEER 10"=>10.0, "SEER 13"=>13.0, "SEER 14"=>14.0, "SEER 15"=>15.0, "SEER 16"=>16.0, "SEER 16 (2 Stage)"=>16.0, "SEER 17"=>17.0, "SEER 18"=>18.0, "SEER 21"=>21.0, "SEER 24.5"=>24.5}[selected_ac]
    acNumberSpeeds = {"SEER 8"=>1.0, "SEER 10"=>1.0, "SEER 13"=>1.0, "SEER 14"=>1.0, "SEER 15"=>1.0, "SEER 16"=>1.0, "SEER 16 (2 Stage)"=>2.0, "SEER 17"=>2.0, "SEER 18"=>2.0, "SEER 21"=>2.0, "SEER 24.5"=>4.0}[selected_ac]
    acRatedAirFlowRate = {"SEER 8"=>386.1, "SEER 10"=>386.1, "SEER 13"=>386.1, "SEER 14"=>386.1, "SEER 15"=>386.1, "SEER 16"=>386.1, "SEER 16 (2 Stage)"=>355.2, "SEER 17"=>355.2, "SEER 18"=>355.2, "SEER 21"=>355.2, "SEER 24.5"=>315.8}[selected_ac]
    acFanspeedRatio = {"SEER 8"=>[1.0], "SEER 10"=>[1.0], "SEER 13"=>[1.0], "SEER 14"=>[1.0], "SEER 15"=>[1.0], "SEER 16"=>[1.0], "SEER 16 (2 Stage)"=>[0.86,1.0], "SEER 17"=>[0.86,1.0], "SEER 18"=>[0.86,1.0], "SEER 21"=>[0.86,1.0], "SEER 24.5"=>[0.51,0.84,1.0,1.19]}[selected_ac]
    acCapacityRatio = {"SEER 8"=>[1.0], "SEER 10"=>[1.0], "SEER 13"=>[1.0], "SEER 14"=>[1.0], "SEER 15"=>[1.0], "SEER 16"=>[1.0], "SEER 16 (2 Stage)"=>[0.72,1.0], "SEER 17"=>[0.72,1.0], "SEER 18"=>[0.72,1.0], "SEER 21"=>[0.72,1.0], "SEER 24.5"=>[0.36,0.64,1.0,1.16]}[selected_ac]
    acCoolingEER = {"SEER 8"=>[7.3], "SEER 10"=>[8.9], "SEER 13"=>[11.1], "SEER 14"=>[12.0], "SEER 15"=>[13.0], "SEER 16"=>[14.0], "SEER 16 (2 Stage)"=>[13.5,12.4], "SEER 17"=>[14.4,13.2], "SEER 18"=>[15.2,14.0], "SEER 21"=>[17.7,15.3], "SEER 24.5"=>[19.2,18.3,16.5,14.6]}[selected_ac]
    acSupplyFanPowerInstalled = {"SEER 8"=>0.5, "SEER 10"=>0.5, "SEER 13"=>0.5, "SEER 14"=>0.5, "SEER 15"=>0.5, "SEER 16"=>0.5, "SEER 16 (2 Stage)"=>0.3, "SEER 17"=>0.3, "SEER 18"=>0.3, "SEER 21"=>0.3, "SEER 24.5"=>0.3}[selected_ac]
    acSupplyFanPowerRated = {"SEER 8"=>0.365, "SEER 10"=>0.365, "SEER 13"=>0.365, "SEER 14"=>0.365, "SEER 15"=>0.365, "SEER 16"=>0.14, "SEER 16 (2 Stage)"=>0.14, "SEER 17"=>0.14, "SEER 18"=>0.14, "SEER 21"=>0.14, "SEER 24.5"=>0.14}[selected_ac]
    acSHRRated = {"SEER 8"=>[0.73], "SEER 10"=>[0.73], "SEER 13"=>[0.73], "SEER 14"=>[0.73], "SEER 15"=>[0.73], "SEER 16"=>[0.73], "SEER 16 (2 Stage)"=>[0.71,0.73], "SEER 17"=>[0.71,0.73], "SEER 18"=>[0.71,0.73], "SEER 21"=>[0.71,0.73], "SEER 24.5"=>[0.98,0.82,0.745,0.77]}[selected_ac]
    acCondenserType = {"SEER 8"=>"aircooled", "SEER 10"=>"aircooled", "SEER 13"=>"aircooled", "SEER 14"=>"aircooled", "SEER 15"=>"aircooled", "SEER 16"=>"aircooled", "SEER 16 (2 Stage)"=>"aircooled", "SEER 17"=>"aircooled", "SEER 18"=>"aircooled", "SEER 21"=>"aircooled", "SEER 24.5"=>"aircooled"}[selected_ac]
    acCrankcase = {"SEER 8"=>0.0, "SEER 10"=>0.0, "SEER 13"=>0.0, "SEER 14"=>0.0, "SEER 15"=>0.0, "SEER 16"=>0.0, "SEER 16 (2 Stage)"=>0.0, "SEER 17"=>0.0, "SEER 18"=>0.0, "SEER 21"=>0.0, "SEER 24.5"=>0.0}[selected_ac]
    acCrankcaseMaxT = {"SEER 8"=>55.0, "SEER 10"=>55.0, "SEER 13"=>55.0, "SEER 14"=>55.0, "SEER 15"=>55.0, "SEER 16"=>55.0, "SEER 16 (2 Stage)"=>55.0, "SEER 17"=>55.0, "SEER 18"=>55.0, "SEER 21"=>55.0, "SEER 24.5"=>55.0}[selected_ac]
    acEERCapacityDerateFactor = {"SEER 8"=>1.0, "SEER 10"=>1.0, "SEER 13"=>1.0, "SEER 14"=>1.0, "SEER 15"=>1.0, "SEER 16"=>1.0, "SEER 16 (2 Stage)"=>1.0, "SEER 17"=>1.0, "SEER 18"=>1.0, "SEER 21"=>1.0, "SEER 24.5"=>1.0}[selected_ac]

    constants = Constants.new

    # Create the material class instances
    air_conditioner = AirConditioner.new(acCoolingInstalledSEER, acNumberSpeeds, acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio, acCoolingEER, acSupplyFanPowerInstalled, acSupplyFanPowerRated, acSHRRated, acCondenserType, acCrankcase, acCrankcaseMaxT, acEERCapacityDerateFactor)
    supply = Supply.new
    test_suite = TestSuite.new(false, false)
    misc = Misc.new(nil)

    # Create the sim object
    sim = Sim.new(model, runner)

    hasFurnace = false
    hasCoolingEquipment = true
    hasAirConditioner = true
    hasHeatPump = false
    hasMiniSplitHP = false
    hasRoomAirConditioner = false
    hasGroundSourceHP = false

    # Process the air system
    air_conditioner, supply = sim._processAirSystem(supply, nil, air_conditioner, nil, hasFurnace, hasCoolingEquipment, hasAirConditioner, hasHeatPump, hasMiniSplitHP, hasRoomAirConditioner, hasGroundSourceHP, test_suite)

    coolingseasonschedule = nil
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "CoolingSeasonSchedule"
        coolingseasonschedule = scheduleRuleset
        break
      end
    end

    # Check if has equipment
    htg_coil = nil
    airLoopHVACs = model.getAirLoopHVACs
    airLoopHVACs.each do |airLoopHVAC|
      thermalZones = airLoopHVAC.thermalZones
      thermalZones.each do |thermalZone|
        if selected_living.get.handle.to_s == thermalZone.handle.to_s
          supplyComponents = airLoopHVAC.supplyComponents
          supplyComponents.each do |supplyComponent|
            if supplyComponent.to_AirLoopHVACUnitarySystem.is_initialized
              air_loop_unitary = supplyComponent.to_AirLoopHVACUnitarySystem.get
              if air_loop_unitary.heatingCoil.is_initialized
                htg_coil = air_loop_unitary.heatingCoil.get
                if htg_coil.to_CoilHeatingGas.is_initialized
                  htg_coil = htg_coil.clone
                  htg_coil = htg_coil.to_CoilHeatingGas.get
                end
                if htg_coil.to_CoilHeatingElectric.is_initialized
                  htg_coil = htg_coil.clone
                  htg_coil = htg_coil.to_CoilHeatingElectric.get
                end
              end
            end
            runner.registerInfo("Removed '#{supplyComponent.name}' from air loop '#{airLoopHVAC.name}'")
            supplyComponent.remove
          end
          runner.registerInfo("Removed air loop '#{airLoopHVAC.name}'")
          airLoopHVAC.remove
        end
      end
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

    # _processSystemCoolingCoil
    # Cooling Coil

    if hasAirConditioner

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
        if acOutputCapacity != "Autosize"
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(acOutputCapacity,"Btu/h","W").get)
        end
        if air_conditioner.IsIdealAC
          clg_coil.setRatedSensibleHeatRatio(0.8)
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0))
          if acOutputCapacity != "Autosize"
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
        else
          clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[0])
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0 / supply.CoolingEIR[0]))
          if acOutputCapacity != "Autosize"
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
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
        if acOutputCapacity != "Autosize"
          flowrates = Array.new
          (0...supply.Number_Speeds).to_a.each do |speed|
            flowrates << supply.CFM_TON_Rated[speed] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get * supply.Capacity_Ratio_Cooling[speed]
          end
        end

        # if not flowrates == flowrates.sort
        #   runner.registerError("AC or heat pump cooling coil rated air flow rates are not in ascending order ({value:.{digits}f}). Ensure that Capacity Ratio and Fan Speed Ratio inputs are correct.".format(value=flowrates, digits=2)")
        # end

        (0...supply.Number_Speeds).to_a.each do |speed|
          if acOutputCapacity != "Autosize"
            clg_coil.setRatedHighSpeedTotalCoolingCapacity(OpenStudio::OptionalDouble.new(acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","W").get * supply.Capacity_Ratio_Cooling[speed]))
          end
          clg_coil.setRatedHighSpeedSensibleHeatRatio(OpenStudio::OptionalDouble.new(supply.SHR_Rated[speed]))
          clg_coil.setRatedHighSpeedCOP(1.0 / supply.CoolingEIR[speed])
          if acOutputCapacity != "Autosize"
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

	#if acOutputCapacity != "Autosize"
	#	capacity = furnaceOutputCapacity #Btu/hr
	#	deltaT = furnaceMaxSupplyTemp - 70.0 # F
	#	flowrate = ((60.0 *capacity) / (8.273 * 0.24 * deltaT))/0.000471947443 #flow rate in cfm
	#	fan.setMaximumFlowRate(flowrate)
	#end
	
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

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName("Forced Air System")
    air_loop_unitary.setAvailabilitySchedule(always_on)
    air_loop_unitary.setCoolingCoil(clg_coil)

    air_loop_unitary.setSupplyAirFlowRateMethodWhenNoCoolingorHeatingisRequired("SupplyAirFlowRate")
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0.0)

    air_loop_unitary.setSupplyAirFlowRateMethodDuringHeatingOperation("SupplyAirFlowRate")

    air_loop_unitary.setSupplyAirFlowRateMethodDuringCoolingOperation("SupplyAirFlowRate")

    if not htg_coil.nil?
      # Add the existing furnace back in
      air_loop_unitary.setHeatingCoil(htg_coil)
      runner.registerInfo("Added heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    else
      air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0000001) # this is when there is no heating present
    end
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
    # air_loop_unitary.setMaximumSupplyAirTemperature() tk

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    runner.registerInfo("Added cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")

    zones = model.getThermalZones
    zones.each do |zone|

      if selected_living.get.handle.to_s == zone.handle.to_s

        air_loop.addBranchForZone(zone, air_loop_unitary.to_StraightComponent)
        air_loop_unitary.setControllingZoneorThermostatLocation(zone)

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
ProcessCentralAirConditioner.new.registerWithApplication