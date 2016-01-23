#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load sim.rb
require "#{File.dirname(__FILE__)}/resources/sim"
require "#{File.dirname(__FILE__)}/resources/constants"

#start the measure
class ProcessFurnace < OpenStudio::Ruleset::ModelUserScript

  class Furnace
    def initialize(furnaceInstalledAFUE, furnaceMaxSupplyTemp, furnaceFuelType, furnaceInstalledSupplyFanPower)
      @furnaceInstalledAFUE = furnaceInstalledAFUE
      @furnaceMaxSupplyTemp = furnaceMaxSupplyTemp
      @furnaceFuelType = furnaceFuelType
	  @furnaceInstalledSupplyFanPower = furnaceInstalledSupplyFanPower
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
	
	def FurnaceSupplyFanPowerInstalled
	  return @furnaceInstalledSupplyFanPower
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
    attr_accessor(:static, :cfm_ton, :HPCoolingOversizingFactor, :SpaceConditionedMult, :fan_power, :eff, :min_flow_ratio, :FAN_EIR_FPLR_SPEC_coefficients, :max_temp, :Heat_Capacity, :compressor_speeds, :Zone_Water_Remove_Cap_Ft_DB_RH_Coefficients, :Zone_Energy_Factor_Ft_DB_RH_Coefficients, :Zone_DXDH_PLF_F_PLR_Coefficients, :Number_Speeds, :fanspeed_ratio, :Heat_AirFlowRate, :Cool_AirFlowRate, :Fan_AirFlowRate)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Furnace"
  end
  
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a furnace along with an on/off supply fan to a unitary air loop."
  end
  
  def modeler_description
    return "This measure parses the OSM for the HeatingSeasonSchedule. Any supply components or baseboard convective electrics, except for cooling DX coils, are removed from any existing air loops or zones. Any existing air loops are also removed. An electric or gas heating coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A single zone reheat setpoint manager is added to the supply outlet node, and a diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for furnace fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypeElectric

    #make a string argument for furnace fuel type
    selected_furnacefuel = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfurnacefuel", fuel_display_names, true)
    selected_furnacefuel.setDisplayName("Fuel Type")
	selected_furnacefuel.setDescription("Type of fuel used for heating.")
    selected_furnacefuel.setDefaultValue("gas")
    args << selected_furnacefuel	
	
    #make an argument for entering furnace installed afue
    userdefined_afue = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedafue",true)
    userdefined_afue.setDisplayName("Installed AFUE")
	userdefined_afue.setUnits("Btu/Btu")
    userdefined_afue.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the furnace, which can be used to account for performance derating or degradation relative to the rated value.")
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
    selected_furnacecap.setDisplayName("Heating Output Capacity")
    selected_furnacecap.setDefaultValue("Autosize")
    args << selected_furnacecap

    #make an argument for entering furnace max supply temp
    userdefined_maxtemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedmaxtemp",true)
    userdefined_maxtemp.setDisplayName("Max Supply Temp")
	userdefined_maxtemp.setUnits("F")
	userdefined_maxtemp.setDescription("Maximum supply air temperature.")
    userdefined_maxtemp.setDefaultValue(120.0)
    args << userdefined_maxtemp

	#make an argument for entering furnace installed supply fan power
    userdefined_fanpower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfanpower",true)
    userdefined_fanpower.setDisplayName("Installed Supply Fan Power")
	userdefined_fanpower.setUnits("W/cfm")
	userdefined_fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the indoor fan for the maximum fan speed under actual operating conditions.")
    userdefined_fanpower.setDefaultValue(0.5)
    args << userdefined_fanpower	

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
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	living_thermal_zone_r = runner.getStringArgumentValue("living_thermal_zone",user_arguments)
    living_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, living_thermal_zone_r, runner)
    if living_thermal_zone.nil?
        return false
    end
	fbasement_thermal_zone_r = runner.getStringArgumentValue("fbasement_thermal_zone",user_arguments)
    fbasement_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, fbasement_thermal_zone_r, runner, false)
	
    furnaceFuelType = runner.getStringArgumentValue("selectedfurnacefuel",user_arguments)
	furnaceInstalledAFUE = runner.getDoubleArgumentValue("userdefinedafue",user_arguments)
    furnaceOutputCapacity = runner.getStringArgumentValue("selectedfurnacecap",user_arguments)
    if not furnaceOutputCapacity == "Autosize"
      furnaceOutputCapacity = OpenStudio::convert(furnaceOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end
    furnaceMaxSupplyTemp = runner.getDoubleArgumentValue("userdefinedmaxtemp",user_arguments)
    furnaceInstalledSupplyFanPower = runner.getDoubleArgumentValue("userdefinedfanpower",user_arguments)

    # Create the material class instances
    furnace = Furnace.new(furnaceInstalledAFUE, furnaceMaxSupplyTemp, furnaceFuelType, furnaceInstalledSupplyFanPower)
    air_conditioner = AirConditioner.new(nil)
    supply = Supply.new

    # Create the sim object
    sim = Sim.new(model, runner)

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
        if living_thermal_zone.handle.to_s == thermalZone.handle.to_s
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

    # Air System

    if not hasCoolingEquipment
      # Initialize simulation variables not being used
      supply.Number_Speeds = 1.0
      supply.fanspeed_ratio = [1.0]
      supply.compressor_speeds = 1.0
    end

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName("Central Air System")
    # if air_conditioner.hasIdealAC
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

      if furnace.FurnaceFuelType == Constants.FuelTypeElectric

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

      elsif furnace.FurnaceFuelType != Constants.FuelTypeElectric

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

    # if air_conditioner.hasIdealAC
    #   fan.setMaximumFlowRate(OpenStudio::convert(supply.Fan_AirFlowRate + 0.05,"cfm","m^3/s").get)
    # else
    #   fan.setMaximumFlowRate(supply.fanspeed_ratio.max * OpenStudio::convert(supply.Fan_AirFlowRate + 0.01,"cfm","m^3/s").get)
    # end

	if furnaceOutputCapacity != "Autosize"
		capacity = furnaceOutputCapacity #Btu/hr
		deltaT = furnaceMaxSupplyTemp - 70.0 # F
		flowrate = ((60.0 * capacity) / (8.273 * 0.24 * deltaT)) * 0.000471947443 #flow rate in cfm
		fan.setMaximumFlowRate(flowrate)
	end
	
    fan.setMotorEfficiency(1)

    # fan.setMaximumFlowRate(0.4290584054901815)

    if air_conditioner.hasIdealAC
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
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0000001) # this is when there is no cooling present
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

      if living_thermal_zone.handle.to_s == zone.handle.to_s

        air_loop_unitary.setControllingZoneorThermostatLocation(zone)

        # _processSystemDemandSideAir
        # Demand Side

        # Supply Air
        zone_splitter = air_loop.zoneSplitter
        zone_splitter.setName("Zone Splitter")

        diffuser_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, always_on)
        diffuser_living.setName("Living Zone Direct Air")
        # diffuser_living.setMaximumAirFlowRate(OpenStudio::convert(supply.Living_AirFlowRate,"cfm","m^3/s").get)
        air_loop.addBranchForZone(zone, diffuser_living.to_StraightComponent)
		
        setpoint_mgr = OpenStudio::Model::SetpointManagerSingleZoneReheat.new(model)
        setpoint_mgr.setControlZone(zone)
        setpoint_mgr.addToNode(air_supply_outlet_node)

        # Return Air

        # TODO: need to replace the mixer with a return plenum
        # zone_mixer = air_loop.zoneMixer
        # zone_mixer.disconnect
        # return_plenum = OpenStudio::Model::AirLoopHVACReturnPlenum.new(model)
        # return_plenum.setName("Return Plenum")
        # return_plenum.addToNode(air_demand_outlet_node)
        # air_loop.addBranchForZone(zone, return_plenum.to_StraightComponent)

        air_loop.addBranchForZone(zone)
        runner.registerInfo("Added air loop '#{air_loop.name}' to thermal zone '#{zone.name}'")

      end

      unless fbasement_thermal_zone.nil?

        if fbasement_thermal_zone.handle.to_s == zone.handle.to_s

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