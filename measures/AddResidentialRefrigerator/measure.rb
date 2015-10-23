#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/schedules"

#start the measure
class ResidentialRefrigerator < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ResidentialRefrigerator"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for fridges (alternate schedules if automatic DR control is specified)
	
	#make a double argument for user defined fridge options
	fridge_E = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fridge_E",true)
	fridge_E.setDisplayName("Rated Annual Consumption (kWh/yr)")
	fridge_E.setDefaultValue(434)
	args << fridge_E
	
	#make a double argument for Occupancy Energy Multiplier
	mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mult")
	mult.setDisplayName("Occupancy Energy Multiplier")
	mult.setDefaultValue(1)
	args << mult
	
	#make a choice argument for which zone to put the space in
	#make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end
	
	#make a choice argument for space type
    space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_handles, space_type_display_names)
    space_type.setDisplayName("Select the space where the refrigerator is located")
    space_type.setDefaultValue("*None*") #if none is chosen this will error out
    args << space_type
	
	#Make a string argument for 24 weekday schedule values
	weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch")
	weekday_sch.setDisplayName("Specify the 24-hour weekday schedule")
	weekday_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
	args << weekday_sch
    
	#Make a string argument for 24 weekend schedule values
	weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch")
	weekend_sch.setDisplayName("Specify the 24-hour weekend schedule")
	weekend_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
	args << weekend_sch

	#Make a string argument for 12 monthly schedule values
	monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch")
	monthly_sch.setDisplayName("Specify the 12-month schedule")
	monthly_sch.setDefaultValue("0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837")
	args << monthly_sch

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
	space_type_r = runner.getStringArgumentValue("space_type",user_arguments)
	mult = runner.getDoubleArgumentValue("mult",user_arguments)
    fridge_E = runner.getDoubleArgumentValue("fridge_E",user_arguments)
	weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
	weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
	monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
	
	#if fridge energy consumption is defined, check for reasonable energy consumption
	if fridge_E < 0
		runner.registerError("Refrigerator energy consumption must be greater than or equal to 0")
		return false
	elsif fridge_E < 100
		runner.registerError("Refrigerator energy consumption seems low, double check inputs") 
		return false
	elsif fridge_E > 3000
		runner.registerError("Refrigerator energy consumption seems high, double check inputs") 
		return false
	end
	
	#Calculate fridge daily energy use
	fridge_ann = fridge_E*mult
	fridge_daily = fridge_ann/365.0

    #hard coded convective, radiative, latent, and lost fractions for fridges
    fridge_lat = 0
    fridge_rad = 0
    fridge_lost = 0
    fridge_conv = 1
	
	s = Schedule.new(weekday_sch, weekend_sch, monthly_sch, runner)
	if not s.validated?
		return false
	end
	fridge_max = s.calcDesignLevel(fridge_daily)
	
	#add refrigerator to the selected space
	fridge_name = "residential_refrigerator"
	has_fridge = 0
	replace_fridge = 0
	num_equip = 1
	model.getSpaceTypes.each do |spaceType|
		spacename = spaceType.name.to_s
		spacehandle = spaceType.handle.to_s
		if spacehandle == space_type_r #add refrigerator
			space_equipments = spaceType.electricEquipment
			space_equipments.each do |space_equipment|
				if space_equipment.electricEquipmentDefinition.name.get.to_s == fridge_name #TODO: double check that this actually gets equipment name
					has_fridge = 1
					runner.registerWarning("This space already has a refrigerator, the existing refrigerator will be replaced with the the currently selected option")
					space_equipment.electricEquipmentDefinition.setDesignLevel(fridge_max)
					
					#Assign schedule
					#TODO: This apparently leaves the old, unused schedule in the file
					refrig_ruleset = s.createSchedule(model, fridge_name)
					space_equipment.setSchedule(refrig_ruleset)
					
					num_equip += 1
					replace_fridge = 1
				end
			end
			if has_fridge == 0 
				has_fridge = 1
				
				#Add electric equipment for the fridge
				frg_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
				frg = OpenStudio::Model::ElectricEquipment.new(frg_def)
				frg.setName(fridge_name)
				frg.setSpaceType(spaceType)
				frg_def.setName(fridge_name)
				frg_def.setDesignLevel(fridge_max)
				frg_def.setFractionRadiant(fridge_rad)
				frg_def.setFractionLatent(fridge_lat)
				frg_def.setFractionLost(fridge_lost)
				
				#Assign schedule
				refrig_ruleset = s.createSchedule(model, fridge_name)
				frg.setSchedule(refrig_ruleset)
				
			end
		end
	end
	
	
	
    #reporting final condition of model
	if has_fridge == 1
		if replace_fridge == 1
			runner.registerFinalCondition("The existing fridge has been replaced by one with #{fridge_ann} kWh annual energy consumption.")
		else
			runner.registerFinalCondition("A fridge has been added with #{fridge_ann} kWh annual energy consumption.")
		end
	else
		runner.registerFinalCondition("Refrigerator was not added to #{space_type_r}.")
    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialRefrigerator.new.registerWithApplication