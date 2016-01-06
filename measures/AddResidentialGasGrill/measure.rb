require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class ResidentialGasGrill < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Add/Replace Residential Gas Grill"
  end
  
  def description
    return "Adds (or replaces) a residential gas grill with the specified efficiency and schedule. The grill is assumed to be outdoors."
  end
  
  def modeler_description
    return "Since there is no Gas Grill object in OpenStudio/EnergyPlus, we look for a GasEquipment object with the name that denotes it is a residential gas grill. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#make a double argument for Base Energy Use
	base_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("base_energy")
	base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("therm/yr")
	base_energy.setDescription("The national average (Building America Benchmark) energy use.")
	base_energy.setDefaultValue(30)
	args << base_energy

	#make a double argument for Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Energy Multiplier")
	mult.setDescription("Sets the annual energy use equal to the base energy use times this multiplier.")
	mult.setDefaultValue(1)
	args << mult
	
    #make a boolean argument for Scale Energy Use
	scale_energy = OpenStudio::Ruleset::OSArgument::makeBoolArgument("scale_energy",true)
	scale_energy.setDisplayName("Scale Energy Use")
	scale_energy.setDescription("If true, scales the energy use relative to a 3-bedroom, 1920 sqft house using the following equation: Fscale = (0.5 + 0.25 x Nbr/3 + 0.25 x FFA/1920) where Nbr is the number of bedrooms and FFA is the finished floor area.")
	scale_energy.setDefaultValue(true)
	args << scale_energy

	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097")
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
    living_space_type.setDescription("Select the living space type. The grill will be located outdoors, but the living space floor area is needed to scale energy use.")
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
    fbasement_space_type.setDescription("Select the finished basement space type. The grill will be located outdoors, but the finished basement space floor area is needed to scale energy use.")
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
    base_energy = runner.getDoubleArgumentValue("base_energy",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
    scale_energy = runner.getBoolArgumentValue("scale_energy",user_arguments)
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
    ann_g = base_energy * mult # therm/yr
    
    if scale_energy
        #Scale energy use by num beds and floor area
        constant = ann_g/2
        nbr_coef = ann_g/4/3
        cfa_coef = ann_g/4/1920
        gg_ann_g = constant + nbr_coef * nbeds + cfa_coef * cfa_total # therm/yr
    else
        gg_ann_g = ann_g # therm/yr
    end

    #hard coded convective, radiative, latent, and lost fractions
    gg_lat = 0
    gg_rad = 0
    gg_conv = 0
    gg_lost = 1 - gg_lat - gg_rad - gg_conv
	
	obj_name = Constants.ObjectNameGasGrill
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
	design_level = sch.calcDesignLevelFromDailyTherm(gg_ann_g/365.0)
	
	#add grill to the living space
    #because there are no space gains, the choice of space is arbitrary
	has_gg = 0
	replace_gg = 0
    space_equipments_g = living_space_type.gasEquipment
    space_equipments_g.each do |space_equipment_g| #check for an existing gas heater
        if space_equipment_g.gasEquipmentDefinition.name.get.to_s == obj_name
            has_gg = 1
            runner.registerInfo("There is already a gas grill. The existing gas grill will be replaced with the specified gas grill.")
            space_equipment_g.gasEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment_g)
            replace_gg = 1
        end
    end

    if has_gg == 0 
        has_gg = 1
        
        #Add gas equipment for the grill
        gg_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
        gg = OpenStudio::Model::GasEquipment.new(gg_def)
        gg.setName(obj_name)
        gg.setSpaceType(living_space_type)
        gg_def.setName(obj_name)
        gg_def.setDesignLevel(design_level)
        gg_def.setFractionRadiant(gg_rad)
        gg_def.setFractionLatent(gg_lat)
        gg_def.setFractionLost(gg_lost)
        sch.setSchedule(gg)
        
    end
	
    #reporting final condition of model
    if replace_gg == 1
        runner.registerFinalCondition("The existing gas grill has been replaced by one with #{gg_ann_g.round} therms annual energy consumption.")
    else
        runner.registerFinalCondition("A gas grill has been added with #{gg_ann_g.round} therms annual energy consumption.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialGasGrill.new.registerWithApplication