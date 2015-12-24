# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class AddResidentialBedroomsAndBathrooms < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "AddResidentialBedroomsAndBathrooms"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    spacetype_handles = OpenStudio::StringVector.new
    spacetype_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    spacetype_args = model.getSpaceTypes
    spacetype_args_hash = {}
    spacetype_args.each do |spacetype_arg|
      spacetype_args_hash[spacetype_arg.name.to_s] = spacetype_arg
    end

    #looping through sorted hash of model objects
    spacetype_args_hash.sort.map do |key,value|
      spacetype_handles << value.handle.to_s
      spacetype_display_names << key
    end

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", spacetype_handles, spacetype_display_names, true)
    selected_living.setDisplayName("Living Space")
	selected_living.setDescription("The living space type.")
    args << selected_living

	#make an integer argument for number of bedrooms
	chs = OpenStudio::StringVector.new
	chs << "1"
	chs << "2" 
	chs << "3"
	chs << "4"
	chs << "5+"
	num_br = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("Num_Br", chs, true)
	num_br.setDisplayName("Number of Bedrooms")
	num_br.setDefaultValue("3")
	args << num_br	
	
	#make an integer argument for number of bathrooms
	chs = OpenStudio::StringVector.new
	chs << "1"
	chs << "1.5" 
	chs << "2"
	chs << "2.5"
	chs << "3+"
	num_ba = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("Num_Ba", chs, true)
	num_ba.setDisplayName("Number of Bathrooms")
	num_ba.setDefaultValue("2")
	args << num_ba		
	
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
	num_br = runner.getStringArgumentValue("Num_Br", user_arguments)
	num_ba = runner.getStringArgumentValue("Num_Ba", user_arguments)
	
	#Convert num bedrooms to appropriate integer
	num_br = num_br.tr('+','').to_f

	#Convert num bathrooms to appropriate float
	num_ba = num_ba.tr('+','').to_f
	
	# Bedrooms
	br_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
	br_def.setName("#{num_br} Bedrooms")
	br = OpenStudio::Model::ElectricEquipment.new(br_def)
	br.setName("#{num_br} Bedrooms")
	
	# Bathrooms
	ba_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
	ba_def.setName("#{num_ba} Bathrooms")
	ba = OpenStudio::Model::ElectricEquipment.new(ba_def)
	ba.setName("#{num_ba} Bathrooms")
	
	# Set the space type
	model.getSpaceTypes.each do |spaceType|
		if spaceType.handle.to_s == selected_living.get.handle.to_s
			br.setSpaceType(spaceType)
			ba.setSpaceType(spaceType)
			break
		end
	end		
	
	# Test retrieving
	model.getSpaceTypes.each do |spaceType|
		if spaceType.handle.to_s == selected_living.get.handle.to_s
			space_equipments = spaceType.electricEquipment
			space_equipments.each do |space_equipment|
				name = space_equipment.electricEquipmentDefinition.name.get.to_s
				br_regexpr = /(?<br>\d+\.\d+)\s+Bedrooms/.match(name)
				ba_regexpr = /(?<ba>\d+\.\d+)\s+Bathrooms/.match(name)			
				if br_regexpr
					runner.registerInfo("Number of bedrooms set to #{br_regexpr[:br]} for the '#{selected_living.get.name}' space type.")
				elsif ba_regexpr
					runner.registerInfo("Number of bathrooms set to #{ba_regexpr[:ba]} for the '#{selected_living.get.name}' space type.")
				end
			end
		end
	end
	
    return true

  end
  
end

# register the measure to be used by the application
AddResidentialBedroomsAndBathrooms.new.registerWithApplication
