require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class ResidentialHotTubHeater < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Hot Tub Electric Heater"
  end
  
  def description
    return "Adds (or replaces) a residential hot tub electric heater with the specified efficiency and schedule. The hot tub is assumed to be outdoors."
  end
  
  def modeler_description
    return "Since there is no Hot Tub Electric Heater object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential hot tub electric heater. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for hot tub heaters (alternate schedules if automatic DR control is specified)
	
	#make a double argument for Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Energy Multiplier")
	mult.setDescription("Sets the annual energy use equal to the national average (Building America Benchmark) energy use times this multiplier.")
	mult.setDefaultValue(1)
	args << mult
	
	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837")
	args << monthly_sch

    #make a choice argument for living space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.LivingSpaceType)
        space_type_args << Constants.LivingSpaceType
    end
    living_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_space_type", space_type_args, true)
    living_space_type.setDisplayName("Living space type")
    living_space_type.setDescription("Select the living space type. The hot tub will be located outdoors, but the living space floor area is needed to scale energy use.")
    living_space_type.setDefaultValue(Constants.LivingSpaceType)
    args << living_space_type

    #make a choice argument for finished basement space type
    space_types = model.getSpaceTypes
    space_type_args = OpenStudio::StringVector.new
    space_types.each do |space_type|
        space_type_args << space_type.name.to_s
    end
    if not space_type_args.include?(Constants.FinishedBasementSpaceType)
        space_type_args << Constants.FinishedBasementSpaceType
    end
    fbasement_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_space_type", space_type_args, true)
    fbasement_space_type.setDisplayName("Finished Basement space type")
    fbasement_space_type.setDescription("Select the finished basement space type. The hot tub will be located outdoors, but the finished basement space floor area is needed to scale energy use.")
    fbasement_space_type.setDefaultValue(Constants.FinishedBasementSpaceType)
    args << fbasement_space_type

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
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)

	# Space type
	living_space_type_r = runner.getStringArgumentValue("living_space_type",user_arguments)
    living_space_type = HelperMethods.get_space_type_from_string(model, living_space_type_r, runner)
    if living_space_type.nil?
        return false
    end
	fbasement_space_type_r = runner.getStringArgumentValue("fbasement_space_type",user_arguments)
    fbasement_space_type = HelperMethods.get_space_type_from_string(model, fbasement_space_type_r, runner, false)

    # Get number of bedrooms/bathrooms
    nbeds, nbaths = HelperMethods.get_bedrooms_bathrooms(model, living_space_type.handle, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end
    
    cfa_living = HelperMethods.get_floor_area(model, living_space_type.handle, runner)
    cfa_fbasement = 0.0
    if not fbasement_space_type.nil?
        cfa_fbasement = HelperMethods.get_floor_area(model, fbasement_space_type.handle, runner)
    end
    cfa_total = cfa_living + cfa_fbasement

	#Calculate annual energy use
	ann_elec = 1027.3 # kWh/yr, per the 2010 BA Benchmark
    ann_elec = ann_elec * mult # kWh/yr
    
    #Scale energy use by num beds and floor area
    constant = ann_elec/2
    nbr_coef = ann_elec/4/3
    cfa_coef = ann_elec/4/1920
    hth_ann = constant + nbr_coef * nbeds + cfa_coef * cfa_total # kWh/yr

    #hard coded convective, radiative, latent, and lost fractions
    hth_lat = 0
    hth_rad = 0
    hth_conv = 0
    hth_lost = 1 - hth_lat - hth_rad - hth_conv
	
	obj_name = Constants.ObjectNameHotTubHeater
	obj_name_e = obj_name + "_" + Constants.FuelTypeElectric
	obj_name_g = obj_name + "_" + Constants.FuelTypeGas
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name_e, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailykWh(hth_ann/365.0)
	
	#add hot tub heater to the living space
    #because there are no space gains, the choice of space is arbitrary
	has_elec_hth = 0
	replace_elec_hth = 0
    replace_g_hth = 0
    space_equipments_g = living_space_type.gasEquipment
    space_equipments_g.each do |space_equipment_g| #check for an existing gas range
        if space_equipment_g.gasEquipmentDefinition.name.get.to_s == obj_name_g
            runner.registerInfo("There is already a hot tub gas heater. The existing hot tub gas heater will be replaced with the specified hot tub electric heater.")
            space_equipment_g.remove
            replace_g_hth = 1
        end
    end
    space_equipments = living_space_type.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name_e
            has_elec_hth = 1
            runner.registerInfo("There is already a hot tub electric heater. The existing hot tub electric heater will be replaced with the specified hot tub electric heater.")
            space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment)
            replace_elec_hth = 1
        end
    end
    if has_elec_hth == 0 
        has_elec_hth = 1
        
        #Add electric equipment for the hot tub heater
        hth_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        hth = OpenStudio::Model::ElectricEquipment.new(hth_def)
        hth.setName(obj_name_e)
        hth.setSpaceType(living_space_type)
        hth_def.setName(obj_name_e)
        hth_def.setDesignLevel(design_level)
        hth_def.setFractionRadiant(hth_rad)
        hth_def.setFractionLatent(hth_lat)
        hth_def.setFractionLost(hth_lost)
        sch.setSchedule(hth)
        
    end
	
    #reporting final condition of model
    if replace_elec_hth == 1
        runner.registerFinalCondition("The existing hot tub electric heater has been replaced by one with #{hth_ann.round} kWhs annual energy consumption.")
    elsif replace_g_hth == 1
        runner.registerFinalCondition("The existing hot tub gas heater has been replaced by a hot tub electric heater with #{hth_ann.round} kWhs annual energy consumption.")
    else
        runner.registerFinalCondition("A hot tub electric heater has been added with #{hth_ann.round} kWhs annual energy consumption.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialHotTubHeater.new.registerWithApplication