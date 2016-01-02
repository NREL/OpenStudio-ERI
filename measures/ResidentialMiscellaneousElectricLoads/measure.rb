#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/schedules"

#start the measure
class ResidentialMiscellaneousElectricLoads < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add/Replace Residential Plug Loads"
  end
  
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for mels (alternate schedules if automatic DR control is specified)
	
	#make a double argument for BA Benchamrk multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Building America Benchmark Multipler")
	mult.setDefaultValue(1)
	args << mult
	
	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch", true)
	weekday_sch.setDisplayName("Weekday schedule")
	weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
	weekday_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch", true)
	weekend_sch.setDisplayName("Weekend schedule")
	weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
	weekend_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch", true)
	monthly_sch.setDisplayName("Month schedule")
	monthly_sch.setDescription("Specify the 12-month schedule.")
	monthly_sch.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
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
    space_type.setDescription("Select the space type where the plug loads are located")
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
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)

    #Get space type
    space_type = HelperMethods.get_space_type_from_string(model, space_type_r, runner)
    if space_type.nil?
        return false
    end

    # Get number of bedrooms/bathrooms
    nbeds, nbaths = HelperMethods.get_bedrooms_bathrooms(model, space_type.handle, runner)
    if nbeds.nil? or nbaths.nil?
        return false
    end
	
    cfa = HelperMethods.get_floor_area(model, space_type.handle, runner)
    
	#if multiplier is defined, make sure it is positive
	if mult <= 0
		runner.registerError("Multiplier must be greater than or equal to 0.0.")
        return false
	end
	
	#Calculate electric mel daily energy use
    mel_ann = (1108.1 + 180.2 * nbeds + 0.2785 * cfa) * mult
	mel_daily = mel_ann / 365.0
	
	#hard coded convective, radiative, latent, and lost fractions
	mel_lat = 0.021
	mel_rad = 0.558
	mel_conv = 0.372
	mel_lost = 1 - mel_lat - mel_rad - mel_conv

    obj_name = Constants.ObjectNameMiscPlugLoads
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
    design_level = sch.calcDesignLevelElec(mel_daily)    
	
	#add mel to the selected space
	has_elec_mel = 0
	replace_mel = 0
    space_equipments = space_type.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name
            has_elec_mel = 1
            runner.registerWarning("This space already has misc plug loads, the existing plug loads will be replaced with the the currently selected option")
            space_equipment.electricEquipmentDefinition.setDesignLevel(design_level)
            sch.setSchedule(space_equipment)
            replace_mel = 1
        end
    end
    if has_elec_mel == 0 
        has_elec_mel = 1

        #Add electric equipment for the mel
        mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
        mel.setName(obj_name)
        mel.setSpaceType(space_type)
        mel_def.setName(obj_name)
        mel_def.setDesignLevel(design_level)
        mel_def.setFractionRadiant(mel_rad)
        mel_def.setFractionLatent(mel_lat)
        mel_def.setFractionLost(mel_lost)
        sch.setSchedule(mel)
        
    end

    #reporting final condition of model
    if replace_mel == 1
        runner.registerFinalCondition("The existing misc plug loads have been replaced by plug loads with #{mel_ann.round} kWh annual energy consumption.")
    else
        runner.registerFinalCondition("Misc plug loads have been added with #{mel_ann.round} kWh annual energy consumption.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialMiscellaneousElectricLoads.new.registerWithApplication