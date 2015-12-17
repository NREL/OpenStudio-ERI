# -*- coding: iso-8859-1 -*-
#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require 'OpenStudio'
require "#{File.dirname(__FILE__)}/resources/constants"
require_relative "resources/ba_protocol_table_8_page_13.rb"

#start the measure
class AddOSWaterHeaterMixedTanklessElectric < OpenStudio::Ruleset::ModelUserScript
  # define some units


  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddOSWaterHeaterMixedTanklessElectric"
  end

  OS = OpenStudio
  OSM = OS::Model
  OSR = OS::Ruleset
  
  Gallon = OS::createUnit("gal").get
  M3 = OS::createUnit("m^3").get
  Watt = OS::createUnit("W").get
  KiloWatt = OS::createUnit("kW").get
  Fahrenheit = OS::createUnit("F").get
  Rankine = OS::createUnit("R").get
  Celsius = OS::createUnit("C").get
  Kelvin = OS::createUnit("K").get
  Hour = OS::createUnit("h").get
  Btu = OS::createUnit("Btu").get
  
  #define the arguments that the user will input
  def arguments(model)
    ruleset = OSR
    
    osargument = ruleset::OSArgument
    
    args = ruleset::OSArgumentVector.new
    
    # make an argument for the existing plant loop
    existing_plant_loops = model.getPlantLoops
    existing_heating_plant_loops = existing_plant_loops.select{ |pl| pl.sizingPlant.loopType() == "Heating"}
    existing_plant_names = existing_heating_plant_loops.select{ |pl| not pl.name.empty?}.collect{ |pl| pl.name.get }
    existing_plant_names << "New Plant Loop"
    existing_Plant_Loop_name  = osargument::makeChoiceArgument("existing_plant_loop_name", existing_plant_names, true)
    existing_Plant_Loop_name.setDisplayName("Plant Loop to assign Water heater as a Supply Equipment")
    args << existing_Plant_Loop_name

    # make an argument for the rated energy factor
    rated_energy_factor = osargument::makeDoubleArgument("rated_energy_factor", true)
    rated_energy_factor.setDisplayName("Rated Energy Factor of Electric Tankless Water Heater. This field is ignored for NCTH and B10 protocols.")
    args << rated_energy_factor

    # make an argument for hot water setpoint temperature
    shw_setpoint = osargument::makeDoubleArgument("shw_setpoint_temperature", true)
    shw_setpoint.setDisplayName("Hot Water Temperature Setpoint")
    args << shw_setpoint

    # make an argument for water_heater_location
    thermal_zones = model.getThermalZones
    thermal_zone_names = thermal_zones.select { |tz| not tz.name.empty?}.collect{|tz| tz.name.get }
    water_heater_location = osargument::makeChoiceArgument("water_heater_location",thermal_zone_names, true)
    water_heater_location.setDisplayName("Thermal Zone where the Electric Tankless Water Heater is located")
    args << water_heater_location

    # make an argument for water_heater_capacity
    water_heater_capacity = osargument::makeDoubleArgument("water_heater_capacity", true)
    water_heater_capacity.setDisplayName("The nominal capacity [kW] of the electric storage water heater. Set to 0 to have this field autosized.")
    args << water_heater_capacity
    
    # make an argument for derate_for_cycling_inefficiencies
    derate = osargument::makeDoubleArgument("derate_for_cycling_inefficiencies", true)
    derate.setDisplayName("Annual Energy Derate for Cycling Inefficiencies - this factor accounts for the small water draws on the heat exchanger that are not currently reflected in the DOE Energy Factor test procedure. CEC 2008 Title 24 implemented an 8% derate for tankless water heaters.")
    args << derate
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    @model = model
    @runner = runner
    @user_arguments = user_arguments

    # copy inputs to local vars
    @args =  parse_arguments
                
    return false unless validate_arguments

    register_initial_conditions

    if @args[:existing_plant_loop] == "New Plant Loop"
      loop = create_new_loop
    else
      loop = model.getPlantLoops.find{|pl| pl.name.get == @args[:existing_plant_loop]}
    end

    if loop.components(OSM::PumpConstantSpeed::iddObjectType).empty?
      new_pump = create_new_pump
      new_pump.addToNode(loop.supplyInletNode)
    end

    if loop.supplyOutletNode.setpointManagers.empty?
      new_manager = create_new_schedule_manager
      new_manager.addToNode(loop.supplyOutletNode)
    end

    new_heater = create_new_heater
    loop.addSupplyBranchForComponent(new_heater)
        
    register_final_conditions(runner, model)
  
    return true
 
  end #end the run method

  private

  def validate_arguments
      #use the built-in error checking 
    if not @runner.validateUserArguments(arguments(@model), @user_arguments)
      return false
    end

    # Validate inputs further
    validate_existing_plant_loop
    validate_rated_energy_factor
    validate_setpoint_temperature
    validate_water_heater_capacity
    validate_derate_for_cycling

    return @runner.result.errors.empty?    
  end
  
  def qty(value, unit)
    return OS::Quantity.new(value, unit)
  end

  def convert(qty, unit)
    value = qty.value
    oldUnit = qty.units.standardString
    newUnit = unit.standardString
    
    OS::convert(value, oldUnit, newUnit).get
  end
  

  def create_new_loop
    loop = OSM::PlantLoop.new(@model)
    loop.setName(Constants.PlantLoopServiceWater)
    loop.sizingPlant.setDesignLoopExitTemperature(60)
    loop.sizingPlant.setLoopDesignTemperatureDifference(50)
        
    bypass_pipe  = OSM::PipeAdiabatic.new(@model)
    out_pipe = OSM::PipeAdiabatic.new(@model)
    
    loop.addSupplyBranchForComponent(bypass_pipe)
    out_pipe.addToNode(loop.supplyOutletNode)      
    return loop
  end

  def create_new_pump
    # pump seems to default to an autosized flow rate and intermittent control type
    pump = OSM::PumpConstantSpeed.new(@model)
    pump.setFractionofMotorInefficienciestoFluidStream(1)
    pump.setMotorEfficiency(0.999)
    pump.setRatedPowerConsumption(0.001)
    pump.setRatedPumpHead(0.001)
    return pump
  end

  def create_new_schedule_manager
    new_schedule = create_new_schedule_ruleset("SHW Temp", "HW Temp Default", @args[:shw_setpoint_temperature])
    OSM::SetpointManagerScheduled.new(@model, new_schedule)
  end

  def create_new_schedule_ruleset(name, schedule_name, temperature)
    new_schedule = OSM::ScheduleRuleset.new(@model)
    new_schedule.setName(name)
    new_schedule.defaultDaySchedule.setName(schedule_name)
    new_schedule.defaultDaySchedule.addValue(OS::Time.new("24:00:00"), convert(temperature, Celsius))
    return new_schedule
  end
  

  def create_new_heater
    new_heater = OSM::WaterHeaterMixed.new(@model)
    configure_tank_volume(new_heater)
    configure_setpoint_schedule(new_heater)
    new_heater.setDeadbandTemperatureDifference(0)
    new_heater.setHeaterMaximumCapacity(@args[:water_heater_capacity])
    new_heater.setMaximumTemperatureLimit(qty(99, Celsius))
    new_heater.setHeaterControlType("Modulate")
    configure_heater_capacity(new_heater)
    new_heater.setHeaterMinimumCapacity(0)
    new_heater.setHeaterFuelType("Electricity")
    configure_thermal_efficiency(new_heater)
    new_heater.setAmbientTemperatureIndicator("ThermalZone")
    thermal_zone = @model.getThermalZones.find{|tz| tz.name.get == @args[:water_heater_location]}
    
    new_heater.setAmbientTemperatureThermalZone(thermal_zone)
    configure_cycle_loss_coeficients(new_heater)

    info_prefix = "Water heater '#{new_heater.name}' has "

    max_temp_si = new_heater.getMaximumTemperatureLimit.get
    max_temp_ip = OS::convert(max_temp_si, Fahrenheit).get
    
    @runner.registerInfo info_prefix + "a deadband temperature difference of #{new_heater.getDeadbandTemperatureDifference.to_s}"
    @runner.registerInfo info_prefix + "a maximum temperature limit of #{max_temp_ip.to_s}"
    @runner.registerInfo info_prefix + "a heater minimum capacity of #{new_heater.getHeaterMinimumCapacity.get.to_s}"
    @runner.registerInfo info_prefix + "a heater fuel type of '#{new_heater.heaterFuelType}'"
    @runner.registerInfo info_prefix + "a heater thermal efficiency of #{new_heater.heaterThermalEfficiency}"
    @runner.registerInfo info_prefix + "an ambient temperature indicator of '#{new_heater.ambientTemperatureIndicator}'"
    @runner.registerInfo info_prefix + "an on-cycle loss fraction to thermal zone of #{new_heater.onCycleLossFractiontoThermalZone}"
    @runner.registerInfo info_prefix + "an off-cycle loss fraction to thermal zone of #{new_heater.onCycleLossFractiontoThermalZone}"
    @runner.registerInfo info_prefix + "a use side effectiveness of #{new_heater.useSideEffectiveness}"
    @runner.registerInfo info_prefix + "a source side effectiveness of #{new_heater.sourceSideEffectiveness}"
    @runner.registerInfo info_prefix + "an ambient temperature thermal zone of '#{new_heater.ambientTemperatureThermalZone.get.name.get}'"
    
    return new_heater
  end

  def configure_tank_volume(new_heater)
    info_msg = "Water heater of type has tank volume "

    nominal_volume = qty(1,Gallon)
    
    actual_volume = nominal_volume
    new_heater.setTankVolume(actual_volume)
    @runner.registerInfo (info_msg + actual_volume.to_s)    
  end    

  def configure_setpoint_schedule(new_heater)
    set_temp = @args[:shw_setpoint_temperature]
    
    new_schedule = create_new_schedule_ruleset("SHW Set Temp", "SHW Set Temp Default", set_temp)
    new_heater.setSetpointTemperatureSchedule(new_schedule)
    
    @runner.registerInfo "A schedule named SHW Set Temp was created and applied to #{new_heater.name.get}, using a constant temperature of #{set_temp.to_s} for generating service hot water."
  end

  def configure_heater_capacity(new_heater)

    info_prefix = "Water heater '#{new_heater.name}' has a heater maximum capacity of "
    given_capacity = @args[:water_heater_capacity]
    if given_capacity.value == 0
      new_heater.autosizeHeaterMaximumCapacity
      @runner.registerInfo info_prefix + "autosized."
      return
    end
    
    new_heater.setHeaterMaximumCapacity(given_capacity)
    @runner.registerInfo info_prefix + new_heater.getHeaterMaximumCapacity.get.to_s
      
  end

  def configure_thermal_efficiency(new_heater)
    energy_factor = @args[:rated_energy_factor]
    derate = @args[:derate_for_cycling_inefficiencies]

    efficiency = energy_factor*(1-derate)
    new_heater.setHeaterThermalEfficiency(efficiency)
  end
  
  def configure_cycle_loss_coeficients(new_heater)
    # based on cell Q4594 of the Options sheed to BA_Analysis_FY10.xlsm spreadsheet

    # Note: OpenStudio conversions based on DegF or DegC don't work well. Defining temperatures in Rankine instead.

    loss_coeff = 0

    new_heater.setOnCycleLossCoefficienttoAmbientTemperature(loss_coeff)
    new_heater.setOffCycleLossCoefficienttoAmbientTemperature(loss_coeff)
    @runner.registerInfo "Water heater '#{new_heater.name.get}' has an on-cycle loss coefficient to ambient temperature of #{loss_coeff}"
    @runner.registerInfo "Water heater '#{new_heater.name.get}' has an off-cycle loss coefficient to ambient temperature of #{loss_coeff}"
  end
      
  
  def register_initial_conditions
    initial_condition = list_water_heaters.join("\n")
    if initial_condition.empty?
      initial_condition = "No water heaters in initial model"
    end
    
    @runner.registerInitialCondition(initial_condition)
  end

  def register_final_conditions(runner, model)
    final_condition = list_water_heaters.join("\n")
    @runner.registerFinalCondition(final_condition)
  end    

  def list_water_heaters
    water_heaters = []

    existing_heaters = @model.getWaterHeaterMixeds
    for heater in existing_heaters do
      heatername = heater.name.get
      loopname = heater.plantLoop.get.name.get
      if heater.isHeaterMaximumCapacityAutosized
        capacity = "autosized"
      else
        capacity = heater.getHeaterMaximumCapacity.get
      end
      
      if heater.isTankVolumeAutosized
        volume = "autosized"
      else
        volume_si = heater.getTankVolume.get
        volume = OS::convert(volume_si, Gallon).get
        # volume_si = heater.tankVolume.get
        # volume_ip = OS::convert(volume_si, "m^3", 'gal').get
        # volume = qty(volume_ip, Gallon)
        if volume.value <= 1
          volume = "tankless"
        end
      end
      
      water_heaters << "Water heater '#{heatername}' on plant loop '#{loopname}', with capacity #{capacity}" +
        " and tank volume #{volume}"
    end

    water_heaters
  end

    
  
  def parse_arguments
    return {
      existing_plant_loop: @runner.getStringArgumentValue("existing_plant_loop_name", @user_arguments),
      rated_energy_factor: @runner.getDoubleArgumentValue("rated_energy_factor", @user_arguments),
      shw_setpoint_temperature: qty(@runner.getDoubleArgumentValue("shw_setpoint_temperature", @user_arguments),Fahrenheit),
      water_heater_capacity: qty(@runner.getDoubleArgumentValue("water_heater_capacity", @user_arguments),KiloWatt),
      water_heater_location: @runner.getStringArgumentValue("water_heater_location", @user_arguments),
      derate_for_cycling_inefficiencies: @runner.getDoubleArgumentValue("derate_for_cycling_inefficiencies", @user_arguments)
    }    
  end

  def validate_existing_plant_loop
    existing_plant_loop = @args[:existing_plant_loop]
    if existing_plant_loop == "New Plant Loop"
      @runner.registerWarning("The water heater will be applied to a new OS:PlantLoop object. The plant loop object will be created using default values. Please review the values for appropriateness.")
    else
      @runner.registerWarning("Additional Water heater being added to #{existing_plant_loop}. User will need to confirm controls.")
    end
  end

  def validate_rated_energy_factor
    rated_energy_factor = @args[:rated_energy_factor]
    if (rated_energy_factor > 1 || rated_energy_factor <= 0)
      @runner.registerError("Rated Energy Factor must be between 0.0 and 1.0.")
    end
    if (rated_energy_factor < 0.98)
      @runner.registerWarning("AHRI Certified Energy Factors for Commercially available Electric Tankless Water Heaters should be 0.98 or greater.")
    end    
  end
  
  def validate_setpoint_temperature
    shw_setpoint_temperature = convert(@args[:shw_setpoint_temperature], Fahrenheit)
    if (shw_setpoint_temperature <= 0)
      @runner.registerError("Hot water temperature should be greater than 0")
    end
    if (shw_setpoint_temperature > 140)
      @runner.registerWarning("Hot Water Setpoint schedule SHW_Temp has values greater than 140F. This temperature, if achieved, may cause scalding.")
    end    
    if (shw_setpoint_temperature < 120)
      @runner.registerWarning("Hot Water Setpoint schedule SHW_Temp has values less than 120F. This temperature may promote the growth of Legionellae or other bacteria.")               

    end    
  end

  def validate_water_heater_effectiveness
    water_heater_effectiveness = @args[:water_heater_effectiveness]
    if (water_heater_effectiveness < 0)
      @runner.registerError("Electric Water Heater Heat Exchange Effectiveness must be greater than 0")
    end
    if (water_heater_effectiveness > 1)
      @runner.registerError("Electric Water Heater Heat Exchange Effectiveness must be less than 1")
    end
    if (water_heater_effectiveness < 0.8)
      @runner.registerWarning "Actual Performance of modeled water heater may not match Rated EF and RE per GAMA and 10CFR430 test procedures. Check EPlusout.eio file for calculated EF and RE."
    end
  end

  def validate_water_heater_capacity
    water_heater_capacity = convert(@args[:water_heater_capacity], Watt)
    if water_heater_capacity < 0
      @runner.registerError("Electric Tankless Water Heater Nominal Capacity must be greater than 0 kW.")
    end
    if water_heater_capacity < 2400
      @runner.registerWarning("Commercially Available Electric Tankless Water Heaters should have a minimum Nominal Capacity of 2.4 kW.")
    end
  end
  
  def validate_derate_for_cycling
    derate = @args[:derate_for_cycling_inefficiencies]
    if (derate < 0.0 || derate > 1.0)
      @runner.registerError("Derate for cycling inefficiencies must be between 0.0 and 1.0.")
    end
    if derate > 0.12
      @runner.registerWarning("Derate for cycling inefficiencies of #{derate} appears large. CEC 2008 Title 24 recommends 0.088.")
    end    
  end
  
  
  
end #end the measure

#this allows the measure to be use by the application
AddOSWaterHeaterMixedTanklessElectric.new.registerWithApplication
