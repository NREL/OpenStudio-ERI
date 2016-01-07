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
    living_space_type.setDescription("Select the living space type")
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
    fbasement_space_type.setDescription("Select the finished basement space type")
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

    #check for valid inputs
    if mult < 0
		runner.registerError("Energy multiplier must be greater than or equal to 0.")
		return false
    end
    
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
	
    living_cfa = HelperMethods.get_floor_area(model, living_space_type.handle, runner)
    fbasement_cfa = 0.0
    if not fbasement_space_type.nil?
        fbasement_cfa = HelperMethods.get_floor_area(model, fbasement_space_type.handle, runner)
    end
    total_cfa = living_cfa + fbasement_cfa
    
	#if multiplier is defined, make sure it is positive
	if mult <= 0
		runner.registerError("Multiplier must be greater than or equal to 0.0.")
        return false
	end
	
	#Calculate electric mel daily energy use
    mel_ann = (1108.1 + 180.2 * nbeds + 0.2785 * total_cfa) * mult
	mel_daily = mel_ann / 365.0
    
    #Split total mel into living and fbasement portions
    living_ann = mel_ann * living_cfa / total_cfa
    fbasement_ann = mel_ann * fbasement_cfa / total_cfa
    living_daily = living_ann / 365.0
	fbasement_daily = fbasement_ann / 365.0
    
	#hard coded convective, radiative, latent, and lost fractions
	mel_lat = 0.021
	mel_rad = 0.558
	mel_conv = 0.372
	mel_lost = 1 - mel_lat - mel_rad - mel_conv

    obj_name = Constants.ObjectNameMiscPlugLoads
    obj_name_living = Constants.ObjectNameMiscPlugLoads + "_living"
    obj_name_fbasement = Constants.ObjectNameMiscPlugLoads + "_finished_basement"
	sch = MonthHourSchedule.new(weekday_sch, weekend_sch, monthly_sch, model, obj_name, runner)
	if not sch.validated?
		return false
	end
    living_design_level = sch.calcDesignLevelFromDailykWh(living_daily)
    fbasement_design_level = sch.calcDesignLevelFromDailykWh(fbasement_daily)
	
	#add mel to the living space
	has_elec_mel_living = 0
	replace_mel_living = 0
    space_equipments = living_space_type.electricEquipment
    space_equipments.each do |space_equipment|
        if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name_living
            has_elec_mel_living = 1
            runner.registerWarning("This space (#{living_space_type.name}) already has misc plug loads, the existing plug loads will be replaced with the specific misc plug loads.")
            space_equipment.electricEquipmentDefinition.setDesignLevel(living_design_level)
            sch.setSchedule(space_equipment)
            replace_mel_living = 1
        end
    end
    if has_elec_mel_living == 0 
        has_elec_mel_living = 1

        #Add electric equipment for the mel
        mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
        mel.setName(obj_name_living)
        mel.setSpaceType(living_space_type)
        mel_def.setName(obj_name_living)
        mel_def.setDesignLevel(living_design_level)
        mel_def.setFractionRadiant(mel_rad)
        mel_def.setFractionLatent(mel_lat)
        mel_def.setFractionLost(mel_lost)
        sch.setSchedule(mel)
    end
    
	#add mel to the finished basement space
	has_elec_mel_fbasement = 0
	replace_mel_fbasement = 0
    if not fbasement_space_type.nil?
        space_equipments = fbasement_space_type.electricEquipment
        space_equipments.each do |space_equipment|
            if space_equipment.electricEquipmentDefinition.name.get.to_s == obj_name_fbasement
                has_elec_mel_fbasement = 1
                runner.registerWarning("This space (#{fbasement_space_type.name}) already has misc plug loads, the existing plug loads will be replaced with the specified misc plug loads.")
                space_equipment.electricEquipmentDefinition.setDesignLevel(fbasement_design_level)
                sch.setSchedule(space_equipment)
                replace_mel_fbasement = 1
            end
        end
        if has_elec_mel_fbasement == 0 
            has_elec_mel_fbasement = 1

            #Add electric equipment for the mel
            mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
            mel.setName(obj_name_fbasement)
            mel.setSpaceType(fbasement_space_type)
            mel_def.setName(obj_name_fbasement)
            mel_def.setDesignLevel(fbasement_design_level)
            mel_def.setFractionRadiant(mel_rad)
            mel_def.setFractionLatent(mel_lat)
            mel_def.setFractionLost(mel_lost)
            sch.setSchedule(mel)
        end
    end
    
    #reporting final condition of model
    if replace_mel_living == 1 or replace_mel_fbasement == 1
        runner.registerFinalCondition("The existing misc plug loads have been replaced by plug loads with #{mel_ann.round} kWhs annual energy consumption.")
    else
        runner.registerFinalCondition("Misc plug loads have been added with #{mel_ann.round} kWhs annual energy consumption.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialMiscellaneousElectricLoads.new.registerWithApplication