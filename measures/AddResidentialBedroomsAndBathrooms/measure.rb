# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class AddResidentialBedroomsAndBathrooms < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Number of Beds and Baths"
  end

  # human readable description
  def description
    return "Sets the number of bedrooms and bathrooms in the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets (or replaces) dummy ElectricEquipment objects that store the number of bedrooms and bathrooms associated with the model. Also sets the People object for each finished space in the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new		

    #make a string argument for number of bedrooms
    num_br = OpenStudio::Ruleset::OSArgument::makeStringArgument("Num_Br", false)
    num_br.setDisplayName("Number of Bedrooms")
    num_br.setDescription("Specify the number of bedrooms for all units, or a comma-separated string of numbers of bedrooms (in the correct order) for each unit. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
    num_br.setDefaultValue("3.0")
    args << num_br
    
    #make a string argument for number of bathrooms
    num_ba = OpenStudio::Ruleset::OSArgument::makeStringArgument("Num_Ba", false)
    num_ba.setDisplayName("Number of Bathrooms")
    num_ba.setDescription("Specify the number of bathrooms for all units, or a comma-separated string of numbers of bathrooms (in the correct order) for each unit. Used to determine the hot water usage, etc.")
    num_ba.setDefaultValue("2.0")
    args << num_ba
    
    # NOTE
    # Occupant arguments commented out for now since they are confusing. Num occupants and schedules
    # only affect occupant heat gain, not plug loads, hot water usage, etc. When we refactor HSP
    # equations to be based on num occupants rather than num bedrooms, we should uncomment this.
    
    #Make a string argument for occupants (auto or number)
    #occupants = OpenStudio::Ruleset::OSArgument::makeStringArgument("occupants", false)
    #occupants.setDisplayName("Number of Occupants")
    #occupants.setDescription("Use '#{Constants.Auto}' to calculate the average number of occupants from the number of bedrooms. Only used to specify the internal gains from people.")
    #occupants.setDefaultValue(Constants.Auto)
    #args << occupants

    #Make a string argument for 24 weekday schedule values
    #weekday_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekday_sch", true)
    #weekday_sch.setDisplayName("Weekday schedule")
    #weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    #weekday_sch.setDefaultValue("1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000")
    #args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    #weekend_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("weekend_sch", true)
    #weekend_sch.setDisplayName("Weekend schedule")
    #weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    #weekend_sch.setDefaultValue("1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000")
    #args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    #monthly_sch = OpenStudio::Ruleset::OSArgument::makeStringArgument("monthly_sch", true)
    #monthly_sch.setDisplayName("Month schedule")
    #monthly_sch.setDescription("Specify the 12-month schedule.")
    #monthly_sch.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
    #args << monthly_sch

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    num_br = runner.getStringArgumentValue("Num_Br", user_arguments)
    num_ba = runner.getStringArgumentValue("Num_Ba", user_arguments)
    
    # See NOTE in arguments method regarding hard-coded values below.
    #occupants = runner.getStringArgumentValue("occupants",user_arguments)
    #weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    #weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    #monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    occupants = Constants.Auto
    weekday_sch = "1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000"
    weekend_sch = "1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 1.00000, 0.88310, 0.40861, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.24189, 0.29498, 0.55310, 0.89693, 0.89693, 0.89693, 1.00000, 1.00000, 1.00000"
    monthly_sch = "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"

    if occupants != Constants.Auto 
        if not HelperMethods.valid_float?(occupants)
            runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
            return false
        elsif occupants.to_f < 0
            runner.registerError("Number of Occupants must be either '#{Constants.Auto}' or a number greater than or equal to 0.")
            return false
        end
    end

    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
      return false
    end
    num_br = num_br.split(",").map(&:strip)
    num_ba = num_ba.split(",").map(&:strip)
    
    #error checking
    if num_br.length != num_ba.length
      runner.registerError("Number of units based on number of bedroom elements specified inconsistent with number of units based on number of bathroom elements specified.")
      return false
    end
    if num_br.length > 1 and num_br.length != num_units
      runner.registerError("Number of units based on number of bedrooms elements specified in consistent with number of units defined in the model.")
      return false
    end
    
    if num_units > 1 and num_br.length == 1
      num_br = Array.new(num_units, num_br[0])
      num_ba = Array.new(num_units, num_ba[0])
    end 
    
    obj_name = Constants.ObjectNameOccupants
    
    people_sch = MonthWeekdayWeekendSchedule.new(model, runner, obj_name + " schedule", weekday_sch, weekend_sch, monthly_sch)
    if not people_sch.validated?
        return false
    end
    activity_per_person = 112.5504
    activity_sch = OpenStudio::Model::ScheduleRuleset.new(model, activity_per_person)    
    
    # Update number of bedrooms/bathrooms
    (0...num_units).to_a.each do |unit_num|
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num + 1, runner)
      if unit_spaces.nil?
          runner.registerError("Could not determine the spaces associated with unit #{unit_num + 1}.")
          return false
      end
      if num_br[unit_num].to_f > 5
        runner.registerWarning("Number of bedrooms for Unit #{unit_num + 1} exceeds 5.0; setting number of bedrooms to 5.0.")
        num_br[unit_num] = "5.0"
      end
      if num_ba[unit_num].to_f > 3
        runner.registerWarning("Number of bathrooms for Unit #{unit_num + 1} exceeds 3.0; setting number of bathrooms to 3.0.")
        num_ba[unit_num] = "3.0"
      end
      num_br[unit_num] = num_br[unit_num].to_f.round(1).to_s
      num_ba[unit_num] = num_ba[unit_num].to_f.round(1).to_s
      Geometry.set_unit_beds_baths_spaces(model, unit_num + 1, unit_spaces, num_br[unit_num], num_ba[unit_num])
      if num_units > 1
        runner.registerInfo("Unit #{unit_num + 1} has been assigned #{num_br[unit_num]} bedroom(s) and #{num_ba[unit_num]} bathroom(s).")
      end

      # Get FFA
      ffa = Geometry.get_unit_finished_floor_area(model, unit_spaces, runner)
      if ffa.nil?
          return false
      end
      
      #hard coded convective, radiative, latent, and lost fractions
      occ_lat = 0.427
      occ_conv = 0.253
      occ_rad = 0.32
      occ_lost = 1 - occ_lat - occ_conv - occ_rad
      occ_sens = occ_rad + occ_conv
      
      spaces = Geometry.get_finished_spaces(model, unit_spaces)      
      spaces.each do |space|
      
          #Calculate number of occupants & activity level
          if occupants == Constants.Auto
              num_occ = 0.87 + 0.59 * num_br[unit_num].to_f
          else
              num_occ = occupants.to_f
          end
      
          obj_name_space = "#{obj_name} #{space.name.to_s}"
          space_num_occ = num_occ * OpenStudio.convert(space.floorArea, "m^2", "ft^2").get / ffa

          #Add people definition for the occ
          occ_def = OpenStudio::Model::PeopleDefinition.new(model)
          occ = OpenStudio::Model::People.new(occ_def)
          occ.setName(obj_name_space)
          occ.setSpace(space)
          occ_def.setName(obj_name_space)
          occ_def.setNumberOfPeopleCalculationMethod("People",1)
          occ_def.setNumberofPeople(space_num_occ)
          occ_def.setFractionRadiant(occ_rad)
          occ_def.setSensibleHeatFraction(occ_sens)
          occ_def.setMeanRadiantTemperatureCalculationType("ZoneAveraged")
          occ_def.setCarbonDioxideGenerationRate(0)
          occ_def.setEnableASHRAE55ComfortWarnings(false)
          occ.setActivityLevelSchedule(activity_sch)
          people_sch.setSchedule(occ)
      end

    end
    
    #reporting final condition of model
    if num_units > 1
      runner.registerFinalCondition("The building has been assigned #{num_br.collect { |i| i.to_f }.inject(:+)} bedroom(s) and #{num_ba.collect { |i| i.to_f }.inject(:+)} bathroom(s) across #{num_units} units.")
    else
      runner.registerFinalCondition("The building has been assigned #{num_br[0]} bedroom(s) and #{num_ba[0]} bathroom(s).")
    end

    return true

  end
  
end

# register the measure to be used by the application
AddResidentialBedroomsAndBathrooms.new.registerWithApplication
