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
class AddOSWaterHeaterMixedStorageGas < OpenStudio::Ruleset::ModelUserScript
  # define some units


  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddOSWaterHeaterMixedStorageGas"
  end

  OS = OpenStudio
  OSM = OS::Model
  OSR = OS::Ruleset
  
  Gallon = OS::createUnit("gal").get
  M3 = OS::createUnit("m^3").get
  Watt = OS::createUnit("W").get
  Fahrenheit = OS::createUnit("F").get
  Rankine = OS::createUnit("R").get
  Celsius = OS::createUnit("C").get
  Kelvin = OS::createUnit("K").get
  Hour = OS::createUnit("h").get
  Btu = OS::createUnit("Btu").get
  KBtuhr = OS::createUnit("kBtu/hr").get
  
  #define the arguments that the user will input
  def arguments(model)
    ruleset = OSR
    
    osargument = ruleset::OSArgument
    
    args = ruleset::OSArgumentVector.new
    
    #  Choice list of use_case
    measure_uses = [ "Create a water heater representing B10 Benchmark standard",
      "Create a water heater representing NCTH standard",
      "Create a water heater representing BA Pre-Retrofit Case standard",
      "General"]
    use_case = osargument::makeChoiceArgument("use_case", measure_uses,true)
    use_case.setDisplayName("How will this measure be used?")
    args << use_case
    
    # make an argument for the number of bedrooms
    bed_choices = (1..5).to_a.collect{|c| c.to_s}
    number_of_bedrooms = osargument::makeChoiceArgument("number_of_bedrooms", bed_choices, true)
    number_of_bedrooms.setDisplayName("Number of Bedrooms in the Proposed Home")
    args << number_of_bedrooms

    # make an argument for the number of bedrooms
    possible_number_of_bathrooms = ["1", "1.5", "2", "2.5", "3", "3.5 or more"]
    number_of_bathrooms = osargument::makeChoiceArgument("number_of_bathrooms", possible_number_of_bathrooms, true)
    number_of_bathrooms.setDisplayName("Number of Bathrooms in the Proposed Home")
    args << number_of_bathrooms

    # make an argument for the existing plant loop
    existing_plant_loops = model.getPlantLoops
    existing_heating_plant_loops = existing_plant_loops.select{ |pl| pl.sizingPlant.loopType() == "Heating"}
    existing_plant_names = existing_heating_plant_loops.select{ |pl| not pl.name.empty?}.collect{ |pl| pl.name.get }
    existing_plant_names << "New Plant Loop"
    existing_Plant_Loop_name  = osargument::makeChoiceArgument("existing_plant_loop_name", existing_plant_names, true)
    existing_Plant_Loop_name.setDisplayName("Plant Loop to assign Water heater as a Supply Equipment")
    args << existing_Plant_Loop_name

    # make an argument for the storage tank volume
    storage_tank_volume = osargument::makeDoubleArgument("storage_tank_volume", true)
    storage_tank_volume.setDisplayName("Volume of the Storage Tank (gallons) of the Gas Hot Water Heater. Set to 0 to have Storage tank volume autosized. This field is ignored for NCTH and B10 protocols.")
    args << storage_tank_volume

    # make an argument for hot water setpoint temperature
    shw_setpoint = osargument::makeDoubleArgument("shw_setpoint_temperature", true)
    shw_setpoint.setDisplayName("Hot Water Temperature Setpoint (Deg F).")
    args << shw_setpoint

    # make an argument for water_heater_location
    thermal_zones = model.getThermalZones
    thermal_zone_names = thermal_zones.select { |tz| not tz.name.empty?}.collect{|tz| tz.name.get }
    water_heater_location = osargument::makeChoiceArgument("water_heater_location",thermal_zone_names, true)
    water_heater_location.setDisplayName("Thermal Zone where the Gas Storage Water Heater is located")
    args << water_heater_location

    # make an argument for water_heater_capacity
    water_heater_capacity = osargument::makeDoubleArgument("water_heater_capacity", true)
    water_heater_capacity.setDisplayName("The nominal capacity [kBtu/hr] of the gas storage water heater. Set to 0 to have this field autosized. This field is ignored for NCTH and B10 protocols.")
    args << water_heater_capacity

    # make an argument for the rated energy factor
    rated_energy_factor = osargument::makeDoubleArgument("rated_energy_factor", true)
    rated_energy_factor.setDisplayName("Rated Energy Factor of Gas Storage Tank Water Heater. This field is ignored for NCTH and B10 protocols.")
    args << rated_energy_factor

    # make an argument for water_heater_recovery_efficiency
    water_heater_recovery_efficiency = osargument::makeDoubleArgument("water_heater_recovery_efficiency", true)
    water_heater_recovery_efficiency.setDisplayName("Rated Recovery Efficiency of the water heater equal to the ratio of energy delivered to the water to the energy content of the fuel consumed by the water heater. Test procedures to test recovery efficiency are defined by the DOE in 10 CFR Part 430, Appendix E to Subpart B. Enter a number between 0 and 1.0. This is used to calculate the thermal efficiency. Users wil need to review the E+out.eio file to confirm Calculated recovery efficiency - Rated recovery efficiency.")
    water_heater_recovery_efficiency.setDefaultValue(0.80)
    args << water_heater_recovery_efficiency

    # make an argument for water_heater_fuel_type
    acceptable_fuels = [ "Natural Gas", "Propane Gas"]
    water_heater_fuel_type = osargument::makeChoiceArgument("water_heater_fuel_type", acceptable_fuels, true)
    water_heater_fuel_type.setDisplayName("The Type of Fuel used for heating.")
    args << water_heater_fuel_type
    
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
    validate_use_case
    validate_existing_plant_loop
    validate_storage_tank_volume
    validate_rated_energy_factor
    validate_setpoint_temperature
    validate_water_heater_capacity
    validate_water_heater_recovery_efficiency

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
    new_heater.setMaximumTemperatureLimit(qty(212, Fahrenheit))
    new_heater.setHeaterControlType("Modulate")
    configure_heater_capacity(new_heater)
    new_heater.setHeaterMinimumCapacity(0)
    new_heater.setHeaterFuelType("Natural Gas")
    new_heater.setHeaterThermalEfficiency(@args[:water_heater_recovery_efficiency])
    new_heater.setAmbientTemperatureIndicator("ThermalZone")

    thermal_zone = @model.getThermalZones.find{|tz| tz.name.get == @args[:water_heater_location]}
    
    new_heater.setAmbientTemperatureThermalZone(thermal_zone)
    configure_cycle_loss_coeficients(new_heater)

    register_info_messages(new_heater)
    return new_heater
  end

  def configure_tank_volume(new_heater)
    type = @args[:use_case]
    if type == "General" || type == "Create a water heater representing BA Pre-Retrofit Case standard"         

      if @args[:storage_tank_volume].value == 0
        new_heater.autosizeTankVolume
        return
      end
      
      nominal_volume = @args[:storage_tank_volume]
    end
    
    if type == "Create a water heater representing B10 Benchmark standard" ||
        type == "Create a water heater representing NCTH standard"
      nominal_volume = lookup_from_table(:storage)
    end

    actual_volume = nominal_volume
    new_heater.setTankVolume(actual_volume)
    
  end    

  def lookup_from_table(key)
    beds = @args[:number_of_bedrooms]
    baths = @args[:number_of_bathrooms]
    return BA_Protocol::Table_8_gas[[beds,baths]][key]
  end

  def configure_setpoint_schedule(new_heater)
    if @args[:use_case] == "General"
      set_temp = @args[:shw_setpoint_temperature]
      else
      set_temp = qty(125,Fahrenheit)
    end
    
    new_schedule = create_new_schedule_ruleset("SHW Set Temp", "SHW Set Temp Default", set_temp)
    new_heater.setSetpointTemperatureSchedule(new_schedule)

    @runner.registerInfo "A schedule named SHW Set Temp was created and applied to #{new_heater.name.get}, using a constant temperature of #{set_temp.to_s} for generating service hot water."
  end

  def configure_heater_capacity(new_heater)
    if @args[:use_case] == "General" ||
        @args[:use_case] == "Create a water heater representing BA Pre-Retrofit Case standard"         

      given_capacity = @args[:water_heater_capacity]
      if given_capacity.value == 0
        new_heater.autosizeHeaterMaximumCapacity
        return
      else        
      capacity = @args[:water_heater_capacity]
    end
    
    end
    
    if @args[:use_case] == "Create a water heater representing B10 Benchmark standard" ||
        @args[:use_case] == "Create a water heater representing NCTH standard" 
      capacity = lookup_from_table(:capacity)
    end
    
    new_heater.setHeaterMaximumCapacity(capacity)      
  end

  def configure_cycle_loss_coeficients(new_heater)
    # based on cell N4594 of the Options sheed to BA_Analysis_FY10.xlsm spreadsheet

    # Note: OpenStudio conversions based on DegF or DegC don't work well. Defining temperatures in Rankine instead.

    use_case = @args[:use_case]
    if use_case.include?("B10") || use_case.include?("NCTH")
      energy_factor = lookup_from_table(:energy_factor)
      rated_input_power = lookup_from_table(:capacity)
    else
      energy_factor = @args[:rated_energy_factor]
      rated_input_power = @args[:water_heater_capacity]
      if rated_input_power.value == 0 # autosized
        # use 36 kBtu/hr based on BA protocol table for buildings with less
        # than 4 bedrooms.
        rated_input_power = qty(36, KBtuhr)
      end      
    end
    
    tank_temperature = qty(135, Rankine)
    environment_temperature = qty(67.5, Rankine)
    day = qty(24, Hour)

    unitless = OpenStudio::createUnit("").get
    
    unexplained_constant = qty(41073, Btu)
    deltaT = tank_temperature - environment_temperature

    energy_factor = qty(energy_factor, unitless)
    recovery_efficiency = qty(@args[:water_heater_recovery_efficiency], unitless)

#binding.pry    
    
    loss_coeff = (recovery_efficiency/energy_factor - qty(1,unitless)) / (deltaT * day/unexplained_constant - deltaT/(rated_input_power*energy_factor))

    new_heater.setOnCycleLossCoefficienttoAmbientTemperature(loss_coeff)
    new_heater.setOffCycleLossCoefficienttoAmbientTemperature(loss_coeff)
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
        capacity_si = heater.getHeaterMaximumCapacity.get
        capacity = OS::convert(capacity_si, KBtuhr).get
      end
      
      if heater.isTankVolumeAutosized
        volume = "autosized"
      else
        volume_si = heater.getTankVolume.get
        volume = OS::convert(volume_si, Gallon).get
      end
      
      water_heaters << "Water heater '#{heatername}' on plant loop '#{loopname}', with capacity #{capacity}" +
        " and tank volume #{volume}"
    end

    water_heaters
  end

  def register_info_messages(new_heater)
    info_prefix = "Water heater '#{new_heater.name}' has "

    max_temp = OS::convert(new_heater.getMaximumTemperatureLimit.get, Fahrenheit).get   
    min_cap = OS::convert(new_heater.getHeaterMinimumCapacity.get, KBtuhr).get

    if new_heater.isHeaterMaximumCapacityAutosized
      max_cap = "autosized"
    else
      max_cap = OS::convert(new_heater.getHeaterMaximumCapacity.get, KBtuhr).get
    end

    if new_heater.isTankVolumeAutosized
      tank_volume = "autosized"
    else
      tank_volume = OS::convert(new_heater.getTankVolume.get, Gallon).get
    end

    on_cycle_loss_coeff = new_heater.getOnCycleLossCoefficienttoAmbientTemperature.get
    off_cycle_loss_coeff = new_heater.getOffCycleLossCoefficienttoAmbientTemperature.get
    
    @runner.registerInfo "A new water heater '#{new_heater.name}' was created"
    @runner.registerInfo info_prefix + "a deadband temperature difference of #{new_heater.getDeadbandTemperatureDifference.to_s}"
    @runner.registerInfo info_prefix + "a maximum temperature limit of #{max_temp}"
    @runner.registerInfo info_prefix + "a tank volume of #{tank_volume}"
    @runner.registerInfo info_prefix + "a heater minimum capacity of #{min_cap}"
    @runner.registerInfo info_prefix + "a heater maximum capacity of #{max_cap}"
    @runner.registerInfo info_prefix + "a heater fuel type of '#{new_heater.heaterFuelType}'"
    @runner.registerInfo info_prefix + "a heater thermal efficiency of #{new_heater.heaterThermalEfficiency}"
    @runner.registerInfo info_prefix + "an ambient temperature indicator of '#{new_heater.ambientTemperatureIndicator}'"
    @runner.registerInfo info_prefix + "an on-cycle loss fraction to thermal zone of #{new_heater.onCycleLossFractiontoThermalZone}"
    @runner.registerInfo info_prefix + "an off-cycle loss fraction to thermal zone of #{new_heater.onCycleLossFractiontoThermalZone}"
    @runner.registerInfo info_prefix + "a use side effectiveness of #{new_heater.useSideEffectiveness}"
    @runner.registerInfo info_prefix + "a source side effectiveness of #{new_heater.sourceSideEffectiveness}"
    @runner.registerInfo info_prefix + "an ambient temperature thermal zone of '#{new_heater.ambientTemperatureThermalZone.get.name.get}'"
    @runner.registerInfo "Water heater '#{new_heater.name.get}' has an on-cycle loss coefficient to ambient temperature of #{on_cycle_loss_coeff}"
    @runner.registerInfo "Water heater '#{new_heater.name.get}' has an off-cycle loss coefficient to ambient temperature of #{off_cycle_loss_coeff}"

  end
  
  def parse_arguments
    return {
      use_case: @runner.getStringArgumentValue("use_case", @user_arguments),
      number_of_bedrooms: @runner.getStringArgumentValue("number_of_bedrooms", @user_arguments).to_i,
      number_of_bathrooms: @runner.getStringArgumentValue("number_of_bathrooms", @user_arguments),
      existing_plant_loop: @runner.getStringArgumentValue("existing_plant_loop_name", @user_arguments),
      storage_tank_volume: qty(@runner.getDoubleArgumentValue("storage_tank_volume", @user_arguments),Gallon),
      rated_energy_factor: @runner.getDoubleArgumentValue("rated_energy_factor", @user_arguments),
      shw_setpoint_temperature: qty(@runner.getDoubleArgumentValue("shw_setpoint_temperature", @user_arguments),Fahrenheit),
      water_heater_capacity: qty(@runner.getDoubleArgumentValue("water_heater_capacity", @user_arguments),KBtuhr),
      water_heater_location: @runner.getStringArgumentValue("water_heater_location", @user_arguments),
      water_heater_recovery_efficiency: @runner.getDoubleArgumentValue("water_heater_recovery_efficiency", @user_arguments)
    }    
  end

  def validate_use_case
    if @args[:use_case] != "General"
      @runner.registerWarning("BA protocols require water heater location to be in attached garage (if it exists and climate = hot-humid or hot-dry or unconditioned basement if it exists and climate = all others). Please check table 9 of 2014 simulation protocols.")
    end
  end
  

  def validate_existing_plant_loop
    existing_plant_loop = @args[:existing_plant_loop]
    if existing_plant_loop == "New Plant Loop"
      @runner.registerWarning("The water heater will be applied to a new OS:PlantLoop object. The plant loop object will be created using default values. Please review the values for appropriateness.")
    else
      @runner.registerWarning("Additional Water heater being added to #{existing_plant_loop}. User will need to confirm controls.")
    end
  end

  def validate_storage_tank_volume
    storage_tank_volume = convert(@args[:storage_tank_volume], Gallon)
    return if (storage_tank_volume == 0)  # flag for autosizing
    if (storage_tank_volume < 0)
      @runner.registerError("Storage Tank Volume cannot be less than 0 gallons. Please correct.")      
    end
    if storage_tank_volume < 25
      @runner.registerWarning("A storage tank volume of less than 25 gallons and a certified rating is not commercially available. Please review the input.")
    end                             
    if storage_tank_volume > 100
      @runner.registerWarning("A hot water heater with a storage tank volume of greater than 100 gallons and a certified rating is not commercially available. Please review the input.")
    end                             
  end

  def validate_rated_energy_factor
    rated_energy_factor = @args[:rated_energy_factor]
    if (rated_energy_factor > 1)
      @runner.registerError("Rated Energy Factor has a maximum value of 1.0")
    end
    if (rated_energy_factor <= 0)
      @runner.registerError("Rated Energy Factor must be greater than 0")
    end
    if (rated_energy_factor >0.82)
      @runner.registerWarning("Rated Energy Factor for Commercially available Gas Storage Water Heaters should be less than 0.82")
    end    
    if (rated_energy_factor <0.48)
      @runner.registerWarning("Rated Energy Factor for Commercially available Gas Storage Water Heaters should be greater than 0.48")
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
      @runner.registerError("Gas Water Heater Heat Exchange Effectiveness must be greater than 0")
    end
    if (water_heater_effectiveness > 1)
      @runner.registerError("Gas Water Heater Heat Exchange Effectiveness must be less than 1")
    end
    if (water_heater_effectiveness < 0.8)
      @runner.registerWarning "Actual Performance of modeled water heater may not match Rated EF and RE per GAMA and 10CFR430 test procedures. Check EPlusout.eio file for calculated EF and RE."
    end
  end

  def validate_water_heater_capacity
    water_heater_capacity = convert(@args[:water_heater_capacity], KBtuhr)
    return if water_heater_capacity == 0 # Autosized
    if water_heater_capacity < 0
      @runner.registerError("Gas Storage Water Heater Nominal Capacity must be greater than 0 kBtu/hr.")
    end

    if water_heater_capacity < 25
      @runner.registerWarning("Commercially Available Gas Storage Water Heaters should have a minimum Nominal Capacity of 25 kBtu/h.")
    end
    if water_heater_capacity > 75
      @runner.registerWarning("Commercially Available Gas Storage Water Heaters should have a maximum Nominal Capacity of 75 kBtu/h.")
    end
    end
    
  def validate_water_heater_recovery_efficiency
    water_heater_recovery_efficiency = @args[:water_heater_recovery_efficiency]
    if (water_heater_recovery_efficiency < 0)
      @runner.registerError("Gas Storage Water Heater Recovery Efficiency must be at least 0 and at most 1.")
    end
    if (water_heater_recovery_efficiency > 1)
      @runner.registerError("Gas Storage Water Heater Recovery Efficiency must be at least 0 and at most 1.")
    end
    if (water_heater_recovery_efficiency < 0.70)
      @runner.registerWarning("Commercially Available Gas Storage Water heaters should have a minimum rated recovery efficiency of 0.70.")
    end
    if (water_heater_recovery_efficiency > 0.90)
      @runner.registerWarning("Commercially Available Gas Storage Water heaters should have a maximum rated recovery efficiency of 0.90.")
    end

    energy_factor = @args[:rated_energy_factor]
    if (water_heater_recovery_efficiency <= energy_factor)
      @runner.registerError("Energy factor must be less than Recovery efficiency.")
    end
    
  end
  
  
  
  
end #end the measure

#this allows the measure to be use by the application
AddOSWaterHeaterMixedStorageGas.new.registerWithApplication
