require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class ResidentialExtraRefrigerator < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Extra Refrigerator"
  end
  
  def description
    return "Adds (or replaces) a residential extra refrigerator with the specified efficiency, operation, and schedule."
  end
  
  def modeler_description
    return "Since there is no Extra Refrigerator object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential extra refrigerator. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for fridges (alternate schedules if automatic DR control is specified)
	
	#make a double argument for user defined fridge options
	fridge_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fridge_E",true)
	fridge_E.setDisplayName("Rated Annual Consumption")
	fridge_E.setUnits("kWh/yr")
	fridge_E.setDescription("The EnergyGuide rated annual energy consumption for a refrigerator.")
	fridge_E.setDefaultValue(434)
	args << fridge_E
	
	#make a double argument for Occupancy Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Occupancy Energy Multiplier")
	mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	mult.setDefaultValue(1)
	args << mult
	
	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837")
	args << monthly_sch

    #make a choice argument for space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_args, true)
    space_type.setDisplayName("Location")
    space_type.setDescription("Select the space type where the refrigerator is located")
    space_type.setDefaultValue(Constants.LivingSpaceType)
    args << space_type

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    #assign the user inputs to variables
    fridge_E = runner.getDoubleArgumentValue("fridge_E",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
	
	#check for reasonable energy consumption
	if fridge_E < 0
		runner.registerError("Refrigerator energy consumption must be greater than or equal to 0.")
		return false
	elsif fridge_E < 100
		runner.registerError("Refrigerator energy consumption seems low, double check inputs.") 
		return false
	elsif fridge_E > 3000
		runner.registerError("Refrigerator energy consumption seems high, double check inputs.") 
		return false
	end
	
    #Get space type
    space_type = HelperMethods.get_space_type_from_string(model, space_type_r, runner)
    if space_type.nil?
        return false
    end

	#Calculate fridge daily energy use
	fridge_ann = fridge_E*mult

    #hard coded convective, radiative, latent, and lost fractions
    fridge_lat = 0
    fridge_rad = 0
    fridge_conv = 1
    fridge_lost = 1 - fridge_lat - fridge_rad - fridge_conv
	
	obj_name = Constants.ObjectNameExtraRefrigerator
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailykWh(fridge_ann/365.0)
	
	#add extra refrigerator to the selected space
	has_fridge = 0
	replace_fridge = 0
    space_equipments = space_type.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
            has_fridge = 1
            runner.registerInfo("This space already has an extra refrigerator, the existing extra refrigerator will be replaced with the specified extra refrigerator.")
            space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment)
            replace_fridge = 1
        end
    end
    if has_fridge == 0 
        has_fridge = 1
        
        #Add electric equipment for the extra fridge
        frg_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        frg = OpenStudio::Model::ElectricEquipment.new(frg_def)
        frg.setName(obj_name)
        frg.setSpaceType(space_type)
        frg_def.setName(obj_name)
        frg_def.setDesignLevel(design_level)
        frg_def.setFractionRadiant(fridge_rad)
        frg_def.setFractionLatent(fridge_lat)
        frg_def.setFractionLost(fridge_lost)
        sch.setSchedule(frg)
        
    end
	
    #reporting final condition of model
    if replace_fridge == 1
        runner.registerFinalCondition("The existing extra fridge has been replaced by one with #{fridge_ann.round} kWhs annual energy consumption.")
    else
        runner.registerFinalCondition("An extra fridge has been added with #{fridge_ann.round} kWhs annual energy consumption.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialExtraRefrigerator.new.registerWithApplication