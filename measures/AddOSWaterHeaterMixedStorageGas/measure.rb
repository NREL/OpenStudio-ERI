# -*- coding: iso-8859-1 -*-
#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require 'OpenStudio'
require "#{File.dirname(__FILE__)}/resources/util"
require"#{File.dirname(__FILE__)}/resources/waterheater"
require"#{File.dirname(__FILE__)}/resources/constants"
require"#{File.dirname(__FILE__)}/resources/unit_conversions"


#start the measure
class AddOSWaterHeaterMixedStorageGas < OpenStudio::Ruleset::ModelUserScript
  # define some units


  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AddOSWaterHeaterMixedStorageGas"
  end
  
  def description
    return "This measure adds a new residential gas storage water heater to the model based on user inputs. If there is already an existing residential water heater in the model, it is replaced."
  end
  
  def modeler_description
    return "The measure will create a new instance of the OS:WaterHeater:Mixed object representing a gas storage water heater. The measure will be placed on the plant loop 'Domestic Hot Water Loop'. If this loop already exists, any water heater on that loop will be removed and replaced with a water heater consistent with this measure. If it doesn't exist, it will be created."
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

    # make an argument for the storage tank volume
    storage_tank_volume = osargument::makeStringArgument("storage_tank_volume", true)
    storage_tank_volume.setDisplayName("Volume of the storage tank (gallons) of the gas water heater. Set to 'auto' to have volume autosized.")
    storage_tank_volume.setDefaultValue("auto")
	args << storage_tank_volume

    # make an argument for hot water setpoint temperature
    dhw_setpoint = osargument::makeDoubleArgument("dhw_setpoint_temperature", true)
    dhw_setpoint.setDisplayName("Water heater setpoint temperature (degrees F).")
	dhw_setpoint.setDefaultValue(125)
    args << dhw_setpoint
	
	   # make an argument for water_heater_location
    thermal_zones = model.getThermalZones
    thermal_zone_names = thermal_zones.select { |tz| not tz.name.empty?}.collect{|tz| tz.name.get }
	if not thermal_zone_names.include?(Constants.LivingZone)
        thermal_zone_names << Constants.LivingZone
	end
    water_heater_location = osargument::makeChoiceArgument("water_heater_location",thermal_zone_names, true)
	water_heater_location.setDefaultValue(Constants.LivingZone)
    water_heater_location.setDisplayName("Thermal zone where the water heater is located.")
	
    args << water_heater_location

    # make an argument for water_heater_capacity
    water_heater_capacity = osargument::makeStringArgument("water_heater_capacity", true)
    water_heater_capacity.setDisplayName("The nominal capacity [kBtu/hr] of the gas storage water heater. Set to 'auto' to have this field autosized.")
    water_heater_capacity.setDefaultValue("40.0")
	args << water_heater_capacity

    # make an argument for the rated energy factor
    rated_energy_factor = osargument::makeStringArgument("rated_energy_factor", true)
    rated_energy_factor.setDisplayName("Rated energy factor of gas storage water heater. Enter 'auto' for a water heater that meets the minimum federal efficiency requirements.")
    rated_energy_factor.setDefaultValue("0.59")
	args << rated_energy_factor

    # make an argument for water_heater_recovery_efficiency
    water_heater_recovery_efficiency = osargument::makeDoubleArgument("water_heater_recovery_efficiency", true)
    water_heater_recovery_efficiency.setDisplayName("Rated recovery efficiency of the water heater. Enter a number between 0 and 1. This is used to calculate the thermal efficiency of the burner.")
    water_heater_recovery_efficiency.setDefaultValue(0.76)
    args << water_heater_recovery_efficiency
	
	# make an argument on cycle electricity consumption
    offcyc_power = osargument::makeDoubleArgument("offcyc_power", true)
    offcyc_power.setDisplayName("Forced draft fan power of the water heater (W)")
	offcyc_power.setDefaultValue(0)
    args << offcyc_power
	
	# make an argument on cycle electricity consumption
    oncyc_power = osargument::makeDoubleArgument("oncyc_power", true)
    oncyc_power.setDisplayName("Parasitic electricity power of the water heater (W)")
	oncyc_power.setDefaultValue(0)
    args << oncyc_power
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

	
	#Assign user inputs to variables
	cap = runner.getStringArgumentValue("water_heater_capacity",user_arguments)
	vol = runner.getStringArgumentValue("storage_tank_volume",user_arguments)
	ef = runner.getStringArgumentValue("rated_energy_factor",user_arguments)
	re = runner.getDoubleArgumentValue("water_heater_recovery_efficiency",user_arguments)
	water_heater_tz = runner.getStringArgumentValue("water_heater_location",user_arguments)
	t_set = runner.getDoubleArgumentValue("dhw_setpoint_temperature",user_arguments).to_f
	oncycle_p = runner.getDoubleArgumentValue("oncyc_power",user_arguments)
	offcycle_p = runner.getDoubleArgumentValue("offcyc_power",user_arguments)
	
	#Validate inputs
	if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    # Validate inputs further
    validate_storage_tank_volume(vol, runner)
    validate_rated_energy_factor(ef, runner)
    validate_setpoint_temperature(t_set, runner)
    validate_water_heater_capacity(cap, runner)
    validate_water_heater_recovery_efficiency(re, runner)
	validate_parasitic_elec(oncycle_p, offcycle_p, runner)
	
	# Get number of bedrooms/bathrooms
    nbeds, nbaths = HelperMethods.get_bedrooms_bathrooms(model, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end
	
	#Check if a DHW plant loop already exists, if not add it
	loop = nil
	
	model.getPlantLoops.each do |pl|
		if pl.name.to_s == Constants.PlantLoopDomesticWater
			runner.registerInfo("A gas water heater will be added to the existing DHW plant loop")
			loop = HelperMethods.get_plant_loop_from_string(model, Constants.PlantLoopDomesticWater, runner)
			if loop.nil?
				return false
			end
			#Remove the existing water heater
			pl.supplyComponents.each do |wh|
				if wh.to_WaterHeaterMixed.is_initialized
					waterHeater = wh.to_WaterHeaterMixed.get
					waterHeater.remove
					runner.registerInfo("The existing mixed water heater has been removed and will be replaced with the new user specified water heater")
				elsif wh.to_WaterHeaterStratified.is_initialized
					waterHeater = wh.to_WaterHeaterStratified.get
					waterHeater.remove
					runner.registerInfo("The existing stratified water heater has been removed and will be replaced with the new user specified water heater")
				end
			end
		end
	end

	if loop.nil?
		runner.registerInfo("A new plant loop for DHW will be added to the model")
		loop = Waterheater.create_new_loop(model)
	end

    register_initial_conditions(model, runner)

    if loop.components(OSM::PumpConstantSpeed::iddObjectType).empty?
      new_pump = Waterheater.create_new_pump(model)
      new_pump.addToNode(loop.supplyInletNode)
    end

    if loop.supplyOutletNode.setpointManagers.empty?
      new_manager = create_new_schedule_manager(t_set, model)
      new_manager.addToNode(loop.supplyOutletNode)
    end
	
			
	new_heater = Waterheater.create_new_heater(cap, Constants.FuelTypeGas, vol, nbeds, nbaths, ef, re, t_set, water_heater_tz, oncycle_p, offcycle_p, model, runner)
	
    loop.addSupplyBranchForComponent(new_heater)
        
    register_final_conditions(runner, model)
  
    return true
 
  end #end the run method

  private
  
  def qty(value, unit)
    return OS::Quantity.new(value, unit)
  end

  def convert(qty, unit)
    value = qty.value
    oldUnit = qty.units.standardString
    newUnit = unit.standardString
    
    OS::convert(value, oldUnit, newUnit).get
  end

  def create_new_schedule_manager(t_set, model)
    new_schedule = Waterheater.create_new_schedule_ruleset("DHW Temp", "DHW Temp Default", t_set, model)
    OSM::SetpointManagerScheduled.new(model, new_schedule)
  end 
  
  def register_initial_conditions(model, runner)
    initial_condition = list_water_heaters(model).join("\n")
    if initial_condition.empty?
      initial_condition = "No water heaters in initial model"
    end
    
    runner.registerInitialCondition(initial_condition)
  end

  def register_final_conditions(runner, model)
    final_condition = list_water_heaters(model).join("\n")
    runner.registerFinalCondition(final_condition)
  end    

  def list_water_heaters(model)
    water_heaters = []

    existing_heaters = model.getWaterHeaterMixeds
    for heater in existing_heaters do
      heatername = heater.name.get
      loopname = heater.plantLoop.get.name.get

      capacity_si = heater.getHeaterMaximumCapacity.get
      capacity = OS::convert(capacity_si, KBtuhr).get
      
      volume_si = heater.getTankVolume.get
      volume = OS::convert(volume_si, Gallon).get
      
      water_heaters << "Water heater '#{heatername}' added to plant loop '#{loopname}', with a capacity of #{capacity}" +
        " and an actual tank volume of #{volume}"
    end

    water_heaters
  end

  def validate_storage_tank_volume(vol, runner)
    return if (vol == 'auto')  # flag for autosizing
	vol = vol.to_f
    if (vol < 0)
      runner.registerError("Storage tank volume must be greater than 0 gallons.")      
    end
    if vol < 25
      runner.registerWarning("A storage tank volume of less than 25 gallons and a certified rating is not commercially available. Please review the input.")
    end                             
    if vol > 120
      runner.registerWarning("A water heater with a storage tank volume of greater than 120 gallons and a certified rating is not commercially available. Please review the input.")
    end                             
  end

  def validate_rated_energy_factor(ef, runner)
	return if (ef == 'auto')  # flag for autosizing
	ef = ef.to_f
    if (ef > 1)
      runner.registerError("Rated energy factor has a maximum value of 1.0")
    end
    if (ef <= 0)
      runner.registerError("Rated energy factor must be greater than 0")
    end
    if (ef >0.82)
      runner.registerWarning("Rated energy factor for commercially available gas storage water heaters should be less than 0.82")
    end    
    if (ef <0.48)
      runner.registerWarning("Rated energy factor for commercially available gas storage water heaters should be greater than 0.48")
    end    
  end
  
  def validate_setpoint_temperature(t_set, runner)
    if (t_set <= 0)
      runner.registerError("Hot water temperature must be greater than 0")
    end
    if (t_set > 140)
      runner.registerWarning("Hot water setpoint schedule DHW_Temp has values greater than 140F. This temperature, if achieved, may cause scalding.")
    end    
    if (t_set < 120)
      runner.registerWarning("Hot water setpoint schedule DHW_Temp has values less than 120F. This temperature may promote the growth of Legionellae or other bacteria.")               

    end    
  end

  def validate_water_heater_capacity(cap, runner)
    return if cap == 'auto' # Autosized
	cap = cap.to_f
    if cap < 0
      runner.registerError("Gas storage water heater nominal capacity must be greater than 0 kBtu/hr.")
    end
    if cap < 25
      runner.registerWarning("Commercially available residential gas storage water heaters should have a minimum nominal capacity of 25 kBtu/h.")
    end
    if cap > 75
      runner.registerWarning("Commercially available residential gas storage water heaters should have a maximum nominal capacity of 75 kBtu/h.")
    end
  end
    
  def validate_water_heater_recovery_efficiency(re, runner)
    if (re < 0)
      runner.registerError("Gas storage water heater recovery efficiency must be at least 0 and at most 1.")
    end
    if (re > 1)
      runner.registerError("Gas storage water heater recovery efficiency must be at least 0 and at most 1.")
    end
    if (re < 0.70)
      runner.registerWarning("Commercially available gas storage water heaters should have a minimum rated recovery efficiency of 0.70.")
    end
    if (re > 0.90)
      runner.registerWarning("Commercially available gas storage water heaters should have a maximum rated recovery efficiency of 0.90.")
    end
    
  end
  
  def validate_parasitic_elec(oncycle_p, offcycle_p, runner)
	if oncycle_p < 0
	  runner.registerError("Forced draft fan power must be greater than 0")
	end
	if offcycle_p < 0
	  runner.registerError("Parasitic electricity power must be greater than 0")
	end
	if oncycle_p > 100
	  runner.registerWarning("Forced draft power consumption is larger than typically seen for residential water heaters, double check inputs")
	end
	if offcycle_p > 30
	  runner.registerWarning("Parasitic power consumption is larger than typically seen for residential water heaters, double check inputs")
	end
  end
  
  
end #end the measure

#this allows the measure to be use by the application
AddOSWaterHeaterMixedStorageGas.new.registerWithApplication
