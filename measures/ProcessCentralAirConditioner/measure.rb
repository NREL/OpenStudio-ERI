# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

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

    attr_accessor(:hasIdealAC)

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
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :fan_power_rated, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :CFM_TON_Rated, :COOL_CAP_FT_SPEC_coefficients, :COOL_EIR_FT_SPEC_coefficients, :COOL_CAP_FFLOW_SPEC_coefficients, :COOL_EIR_FFLOW_SPEC_coefficients, :CoolingEIR, :SHR_Rated, :COOL_CLOSS_FPLR_SPEC_coefficients, :Capacity_Ratio_Cooling, :CondenserType, :Crankcase, :Crankcase_MaxT, :EER_CapacityDerateFactor)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Central Air Conditioner"
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
    ac_display_names << "SEER 24.5"

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

    coolingseasonschedule = HelperMethods.get_heating_or_cooling_season_schedule_object(model, runner, "CoolingSeasonSchedule")
    if coolingseasonschedule.nil?
        runner.registerError("A cooling season schedule named 'CoolingSeasonSchedule' has not yet been assigned. Apply the 'Set Residential Heating/Cooling Setpoints and Schedules' measure first.")
        return false
    end   
    
    # Create the material class instances
    air_conditioner = AirConditioner.new(acCoolingInstalledSEER, acNumberSpeeds, acRatedAirFlowRate, acFanspeedRatio, acCapacityRatio, acCoolingEER, acSupplyFanPowerInstalled, acSupplyFanPowerRated, acSHRRated, acCondenserType, acCrankcase, acCrankcaseMaxT, acEERCapacityDerateFactor)
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
    if air_conditioner.hasIdealAC
      supply = HVAC.get_cooling_coefficients(runner, air_conditioner.ACNumberSpeeds, true, false, supply)
    else
      supply = HVAC.get_cooling_coefficients(runner, air_conditioner.ACNumberSpeeds, false, false, supply)
    end
    supply.CFM_TON_Rated = HVAC.calc_cfm_ton_rated(air_conditioner.ACRatedAirFlowRate, air_conditioner.ACFanspeedRatio, air_conditioner.ACCapacityRatio)
    supply = HVAC._processAirSystemCoolingCoil(air_conditioner.ACNumberSpeeds, air_conditioner.ACCoolingEER, air_conditioner.ACCoolingInstalledSEER, air_conditioner.ACSupplyFanPowerInstalled, air_conditioner.ACSupplyFanPowerRated, air_conditioner.ACSHRRated, air_conditioner.ACCapacityRatio, air_conditioner.ACFanspeedRatio, air_conditioner.ACCondenserType, air_conditioner.ACCrankcase, air_conditioner.ACCrankcaseMaxT, air_conditioner.ACEERCapacityDerateFactor, air_conditioner, supply, false)
        
    # Determine if the compressor is multi-speed (in our case 2 speed).
    # If the minimum flow ratio is less than 1, then the fan and
    # compressors can operate at lower speeds.
    if supply.min_flow_ratio == 1.0
      supply.compressor_speeds = 1.0
    else
      supply.compressor_speeds = supply.Number_Speeds
    end
    
    control_slave_zones_hash = Geometry.get_control_and_slave_zones(model)
    control_slave_zones_hash.each do |control_zone, slave_zones|
    
      # Check if has equipment
      htg_coil = HelperMethods.remove_existing_hvac_equipment_except_for_specified_object(model, runner, control_zone, "Furnace")
      ptacs = model.getZoneHVACPackagedTerminalAirConditioners
      ptacs.each do |ptac|
        thermalZone = ptac.thermalZone.get
        if control_zone.handle.to_s == thermalZone.handle.to_s
          runner.registerInfo("Removed '#{ptac.name}' from thermal zone '#{thermalZone.name}'")
          ptac.remove
        end
      end
    
      # _processCurvesDXCooling
      
      clg_coil_stage_data = HVAC._processCurvesDXCooling(model, supply, acOutputCapacity)

      # _processSystemCoolingCoil
      
      if supply.compressor_speeds == 1.0

        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, coolingseasonschedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
        clg_coil.setName("DX Cooling Coil")
        if acOutputCapacity != "Autosize"
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(acOutputCapacity,"Btu/h","W").get)
        end
        if air_conditioner.hasIdealAC
          if acOutputCapacity != "Autosize"
            clg_coil.setRatedSensibleHeatRatio(0.8)
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
          end
          clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(1.0))
        else
          if acOutputCapacity != "Autosize"
            clg_coil.setRatedSensibleHeatRatio(supply.SHR_Rated[0])
            clg_coil.setRatedAirFlowRate(supply.CFM_TON_Rated[0] * acOutputCapacity * OpenStudio::convert(1.0,"Btu/h","ton").get * OpenStudio::convert(1.0,"cfm","m^3/s").get)
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

        clg_coil.setCrankcaseHeaterCapacity(OpenStudio::OptionalDouble.new(OpenStudio::convert(supply.Crankcase,"kW","W").get))
        clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get))

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
        air_loop_unitary.setCoolingCoil(clg_coil)
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0.0)
        air_loop_unitary.setSupplyFan(fan)
        air_loop_unitary.setFanPlacement("BlowThrough")
        if not htg_coil.nil?
          # Add the existing furnace back in
          air_loop_unitary.setHeatingCoil(htg_coil)
        else
          air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0000001) # this is when there is no heating present
        end
      
      elsif supply.compressor_speeds > 1
      
        supp_htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule)
        supp_htg_coil.setName("Furnace Heating Coil")
        supp_htg_coil.setEfficiency(1)
        supp_htg_coil.setNominalCapacity(0.001)
        
        new_htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
        new_htg_coil.setName("DX Heating Coil")
        new_htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(-20)
        new_htg_coil.setCrankcaseHeaterCapacity(0)
        new_htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(0)
        new_htg_coil.setDefrostStrategy("Resistive")
        new_htg_coil.setDefrostControl("Timed")
        new_htg_coil.setDefrostTimePeriodFraction(0)
        new_htg_coil.setResistiveDefrostHeaterCapacity(0)
        new_htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
        if htg_coil.nil?
          new_htg_coil.setAvailabilitySchedule(model.alwaysOffDiscreteSchedule)
          new_htg_coil.setFuelType("Electricity")
          htg_coil_stage_data = _processCurvesFurnaceForMultiSpeedAC(model, supply, 1.0, 1.0)
        else
          # TODO: figure out how to handle the EMS with adding back in the furnace with multispeed ACs
          new_htg_coil.setAvailabilitySchedule(htg_coil.availabilitySchedule)
          if htg_coil.to_CoilHeatingGas.is_initialized
            new_htg_coil.setFuelType("NaturalGas")
            nominalCapacity = htg_coil.nominalCapacity
            if nominalCapacity.is_initialized
              nominalCapacity = nominalCapacity.get
            else
              nominalCapacity = "Autosize"
            end
            htg_coil_stage_data = _processCurvesFurnaceForMultiSpeedAC(model, supply, nominalCapacity, htg_coil.gasBurnerEfficiency)
          elsif htg_coil.to_CoilHeatingElectric.is_initialized
            new_htg_coil.setFuelType("Electricity")
            nominalCapacity = htg_coil.nominalCapacity
            if nominalCapacity.is_initialized
              nominalCapacity = nominalCapacity.get
            else
              nominalCapacity = "Autosize"
            end
            htg_coil_stage_data = _processCurvesFurnaceForMultiSpeedAC(model, supply, nominalCapacity, htg_coil.efficiency)
          end                
          htg_coil.remove
        end
        (0...supply.Number_Speeds).each do |i|
            new_htg_coil.addStage(htg_coil_stage_data[0])    
        end
        
        air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.new(model, fan, new_htg_coil, clg_coil, supp_htg_coil)
        air_loop_unitary.setName("Forced Air System")
        air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        air_loop_unitary.setSupplyAirFanPlacement("BlowThrough")
        air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
        air_loop_unitary.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(-20)
        air_loop_unitary.setMaximumSupplyAirTemperaturefromSupplementalHeater(OpenStudio::convert(120.0,"F","C").get)
        air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(21)
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
      unless htg_coil.nil?
        runner.registerInfo("Added heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
      end
      
      air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)
      
      # _processSystemDemandSideAir
      # Demand Side

      # Supply Air
      zone_splitter = air_loop.zoneSplitter
      zone_splitter.setName("Zone Splitter")

      diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      diffuser_living.setName("Living Zone Direct Air")
      # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
      air_loop.addBranchForZone(control_zone, diffuser_living.to_StraightComponent)

      setpoint_mgr = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
      setpoint_mgr.setControlZone(control_zone)
      setpoint_mgr.addToNode(air_supply_outlet_node)

      air_loop.addBranchForZone(control_zone)
      runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{control_zone.name}'")

      slave_zones.each do |slave_zone|

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
  
  def _processCurvesFurnaceForMultiSpeedAC(model, supply, outputCapacity, efficiency)
    # Simulate the furnace using a heat pump for multi-speed AC simulations.
    # This object gets created in all situations when a 2 speed
    # AC is used (w/ furnace, boiler, or no heat).  
    htg_coil_stage_data = []
    (0...1).to_a.each do |speed|
    
      hp_heat_cap_ft = OpenStudio::Model::CurveBiquadratic.new(model)
      hp_heat_cap_ft.setName("HP_Heat-Cap-fT")
      hp_heat_cap_ft.setCoefficient1Constant(1)
      hp_heat_cap_ft.setCoefficient2x(0)
      hp_heat_cap_ft.setCoefficient3xPOW2(0)
      hp_heat_cap_ft.setCoefficient4y(0)
      hp_heat_cap_ft.setCoefficient5yPOW2(0)
      hp_heat_cap_ft.setCoefficient6xTIMESY(0)
      hp_heat_cap_ft.setMinimumValueofx(-100)
      hp_heat_cap_ft.setMaximumValueofx(100)
      hp_heat_cap_ft.setMinimumValueofy(-100)
      hp_heat_cap_ft.setMaximumValueofy(100)

      hp_heat_eir_ft = OpenStudio::Model::CurveBiquadratic.new(model)
      hp_heat_eir_ft.setName("HP_Heat-EIR-fT")
      hp_heat_eir_ft.setCoefficient1Constant(1)
      hp_heat_eir_ft.setCoefficient2x(0)
      hp_heat_eir_ft.setCoefficient3xPOW2(0)
      hp_heat_eir_ft.setCoefficient4y(0)
      hp_heat_eir_ft.setCoefficient5yPOW2(0)
      hp_heat_eir_ft.setCoefficient6xTIMESY(0)
      hp_heat_eir_ft.setMinimumValueofx(-100)
      hp_heat_eir_ft.setMaximumValueofx(100)
      hp_heat_eir_ft.setMinimumValueofy(-100)
      hp_heat_eir_ft.setMaximumValueofy(100)

      const_cubic = OpenStudio::Model::CurveCubic.new(model)
      const_cubic.setName("ConstantCubic")
      const_cubic.setCoefficient1Constant(1)
      const_cubic.setCoefficient2x(0)
      const_cubic.setCoefficient3xPOW2(0)
      const_cubic.setCoefficient4xPOW3(0)
      const_cubic.setMinimumValueofx(0)
      const_cubic.setMaximumValueofx(1)
      const_cubic.setMinimumCurveOutput(0.7)
      const_cubic.setMaximumCurveOutput(1)

      stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, hp_heat_cap_ft, const_cubic, hp_heat_eir_ft, const_cubic, const_cubic, HVAC._processCurvesSupplyFan(model))
      if outputCapacity != "Autosize"
        stage_data.setGrossRatedHeatingCapacity(outputCapacity)
        stage_data.setRatedAirFlowRate(outputCapacity * 0.00005)
      end
      stage_data.setGrossRatedHeatingCOP(efficiency)
      stage_data.setRatedWasteHeatFractionofPowerInput(0.00000001)
      htg_coil_stage_data[speed] = stage_data
    end
    return htg_coil_stage_data
  end  
  
end #end the measure

#this allows the measure to be use by the application
ProcessCentralAirConditioner.new.registerWithApplication