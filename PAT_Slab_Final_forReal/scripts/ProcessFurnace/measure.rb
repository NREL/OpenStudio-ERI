#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"

#start the measure
class ProcessFurnace < OpenStudio::Ruleset::ModelUserScript

  class Furnace
    def initialize(furnaceInstalledAFUE, furnaceMaxSupplyTemp, furnaceFuelType)
      @furnaceInstalledAFUE = furnaceInstalledAFUE
      @furnaceMaxSupplyTemp = furnaceMaxSupplyTemp
      @furnaceFuelType = furnaceFuelType
    end

    attr_accessor(:hir, :aux_elec)

    def FurnaceInstalledAFUE
      return @furnaceInstalledAFUE
    end

    def FurnaceMaxSupplyTemp
      return @furnaceMaxSupplyTemp
    end

    def FurnaceFuelType
      return @furnaceFuelType
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
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :Heat_AirFlowRate, :Cool_AirFlowRate, :Fan_AirFlowRate)
  end

  class TestSuite
    def initialize(min_test_ideal_systems)
      @min_test_ideal_systems = min_test_ideal_systems
    end

    def min_test_ideal_systems
      return @min_test_ideal_systems
    end
  end

  class MJ8
    def initialize
    end
    attr_accessor(:HeatingLoad, :HeatingLoad_Inter, :heating_setpoint)
  end

  class Site
    def initialize
    end
    attr_accessor(:acf, :acfs)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessFurnace"
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

    #make an argument for entering furnace installed afue
    userdefined_afue = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedafue",true)
    userdefined_afue.setDisplayName("The installed Annual Fuel Utilization Efficiency (AFUE) of the furnace, which can be used to account for performance derating or degradation relative to the rated value. [Btu/Btu].")
    userdefined_afue.setDefaultValue(0.78)
    args << userdefined_afue

    #make a choice argument for furnace heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for furnace heating output capacity
    selected_furnacecap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfurnacecap", cap_display_names, true)
    selected_furnacecap.setDisplayName("Heating Output Capacity.")
    selected_furnacecap.setDefaultValue("Autosize")
    args << selected_furnacecap

    #make an argument for entering furnace max supply temp
    userdefined_maxtemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedmaxtemp",true)
    userdefined_maxtemp.setDisplayName("Maximum supply air temperature [F].")
    userdefined_maxtemp.setDefaultValue(120.0)
    args << userdefined_maxtemp

    #make a choice argument for furnace fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << "gas"
    fuel_display_names << "electric"

    #make a string argument for furnace fuel type
    selected_furnacefuel = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfurnacefuel", fuel_display_names, true)
    selected_furnacefuel.setDisplayName("Type of fuel used for heating.")
    selected_furnacefuel.setDefaultValue("gas")
    args << selected_furnacefuel

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
    furnaceInstalledAFUE = runner.getDoubleArgumentValue("userdefinedafue",user_arguments)
    furnaceOutputCapacity = runner.getStringArgumentValue("selectedfurnacecap",user_arguments)
    if not furnaceOutputCapacity == "Autosize"
      furnaceOutputCapacity = OpenStudio::convert(furnaceOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end
    furnaceMaxSupplyTemp = runner.getDoubleArgumentValue("userdefinedmaxtemp",user_arguments)
    furnaceFuelType = runner.getStringArgumentValue("selectedfurnacefuel",user_arguments)

    constants = Constants.new

    # Create the material class instances
    furnace = Furnace.new(furnaceInstalledAFUE, furnaceMaxSupplyTemp, furnaceFuelType)
    air_conditioner = AirConditioner.new(nil)
    supply = Supply.new
    test_suite = TestSuite.new(false)
    mj8 = MJ8.new
    site = Site.new

    # Create the sim object
    sim = Sim.new(model)

    hasFurnace = true
    hasCoolingEquipment = false
    hasAirConditioner = false
    hasHeatPump = false
    hasMiniSplitHP = false
    hasRoomAirConditioner = false
    hasGroundSourceHP = false

    # Process the air system
    furnace, air_conditioner, supply = sim._processAirSystem(supply, furnace, air_conditioner, nil, hasFurnace, hasCoolingEquipment, hasAirConditioner, hasHeatPump, hasMiniSplitHP, hasRoomAirConditioner, hasGroundSourceHP)

    heatingseasonschedule = nil
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "HeatingSeasonSchedule"
        heatingseasonschedule = scheduleRuleset
        break
      end
    end

    # Check if has equipment
    clg_coil = nil
    airLoopHVACs = model.getAirLoopHVACs
    airLoopHVACs.each do |airLoopHVAC|
      thermalZones = airLoopHVAC.thermalZones
      thermalZones.each do |thermalZone|
        if selected_living.get.handle.to_s == thermalZone.handle.to_s
          supplyComponents = airLoopHVAC.supplyComponents
          supplyComponents.each do |supplyComponent|
            if supplyComponent.to_AirLoopHVACUnitarySystem.is_initialized
              air_loop_unitary = supplyComponent.to_AirLoopHVACUnitarySystem.get
              if air_loop_unitary.coolingCoil.is_initialized
                clg_coil = air_loop_unitary.coolingCoil.get
                if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
                  clg_coil = clg_coil.clone
                  clg_coil = clg_coil.to_CoilCoolingDXSingleSpeed.get
                end
                if clg_coil.to_CoilCoolingDXTwoSpeed.is_initialized
                  clg_coil = clg_coil.clone
                  clg_coil = clg_coil.to_CoilCoolingDXTwoSpeed.get
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

    if hasFurnace

      if furnace.FurnaceFuelType == constants.FuelTypeElectric

        htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, heatingseasonschedule)
        htg_coil.setName("Furnace Heating Coil")
        htg_coil.setEfficiency(1.0 / furnace.hir)
        if furnaceOutputCapacity != "Autosize"
          htg_coil.setNominalCapacity(OpenStudio::convert(furnaceOutputCapacity,"Btu/h","W").get)
        end

        if hasAirConditioner and supply.compressor_speeds == 1

        elsif hasAirConditioner and supply.compressor_speeds > 1

        else

        end

      elsif furnace.FurnaceFuelType != constants.FuelTypeElectric

        htg_coil = OpenStudio::Model::CoilHeatingGas.new(model, heatingseasonschedule)
        htg_coil.setName("Furnace Heating Coil")
        htg_coil.setGasBurnerEfficiency(1.0 / furnace.hir)
        if furnaceOutputCapacity != "Autosize"
          htg_coil.setNominalCapacity(OpenStudio::convert(furnaceOutputCapacity,"Btu/h","W").get)
        end

        if hasAirConditioner and supply.compressor_speeds == 1

        elsif hasAirConditioner and supply.compressor_speeds > 1

        else

        end

        htg_coil.setParasiticElectricLoad(furnace.aux_elec) # set to zero until we figure out a way to distribute to the correct end uses (DOE-2 limitation?)
        htg_coil.setParasiticGasLoad(0)

      end

    end

    # _processSystemFan
    # HVAC Supply Fan

    supply_fan_availability = OpenStudio::Model::ScheduleConstant.new(model)
    supply_fan_availability.setName"SupplyFanAvailability"
    supply_fan_availability.setValue(1)

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

    # fan.setMaximumFlowRate(0.4290584054901815)

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
    air_loop_unitary.setHeatingCoil(htg_coil)

    air_loop_unitary.setSupplyAirFlowRateMethodWhenNoCoolingorHeatingisRequired("SupplyAirFlowRate")
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0.0)

    air_loop_unitary.setSupplyAirFlowRateMethodDuringHeatingOperation("SupplyAirFlowRate")

    air_loop_unitary.setSupplyAirFlowRateMethodDuringCoolingOperation("SupplyAirFlowRate")

    if not clg_coil.nil?
      # Add the existing DX central air back in
      air_loop_unitary.setCoolingCoil(clg_coil)
      runner.registerInfo("Added cooling coil '#{clg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    else
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0000001) # tk this is when there is no cooling present
    end
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(supply_fan_operation)
    air_loop_unitary.setMaximumSupplyAirTemperature(OpenStudio::convert(supply.max_temp,"F","C").get)

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added on/off fan '#{fan.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")
    runner.registerInfo("Added heating coil '#{htg_coil.name}' to branch '#{air_loop_unitary.name}' of air loop '#{air_loop.name}'")

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
ProcessFurnace.new.registerWithApplication