#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class ProcessElectricBaseboard < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add/Replace Residential Electric Baseboard"
  end
  
  def description
    return "This measure removes any existing electric baseboards from the building and adds electric baseboards."
  end
  
  def modeler_description
    return "This measure parses the OSM for the HeatingSeasonSchedule. Any existing baseboard convective electrics are removed from any existing zones. An HVAC baseboard convective electric is added to the living zone, as well as to the finished basement if it exists."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for entering furnace installed afue
    userdefined_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedeff",true)
    userdefined_eff.setDisplayName("Efficiency")
	userdefined_eff.setUnits("Btu/Btu")
	userdefined_eff.setDescription("The efficiency of the electric baseboard.")
    userdefined_eff.setDefaultValue(1.0)
    args << userdefined_eff

    #make a choice argument for furnace heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for furnace heating output capacity
    selected_baseboardcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedbaseboardcap", cap_display_names, true)
    selected_baseboardcap.setDisplayName("Heating Output Capacity")
    selected_baseboardcap.setDefaultValue("Autosize")
    args << selected_baseboardcap

    #make a choice argument for living thermal zone
    thermal_zones = model.getThermalZones
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
        thermal_zone_args << thermal_zone.name.to_s
    end
    if not thermal_zone_args.include?(Constants.LivingZone)
        thermal_zone_args << Constants.LivingZone
    end
    living_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_thermal_zone", thermal_zone_args, true)
    living_thermal_zone.setDisplayName("Living thermal zone")
    living_thermal_zone.setDescription("Select the living thermal zone")
    living_thermal_zone.setDefaultValue(Constants.LivingZone)
    args << living_thermal_zone		
	
    #make a choice argument for finished basement thermal zone
    thermal_zones = model.getThermalZones
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
        thermal_zone_args << thermal_zone.name.to_s
    end
    if not thermal_zone_args.include?(Constants.FinishedBasementZone)
        thermal_zone_args << Constants.FinishedBasementZone
    end
    fbasement_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("fbasement_thermal_zone", thermal_zone_args, true)
    fbasement_thermal_zone.setDisplayName("Finished Basement thermal zone")
    fbasement_thermal_zone.setDescription("Select the finished basement thermal zone")
    fbasement_thermal_zone.setDefaultValue(Constants.FinishedBasementZone)
    args << fbasement_thermal_zone		
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	living_thermal_zone_r = runner.getStringArgumentValue("living_thermal_zone",user_arguments)
    living_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, living_thermal_zone_r, runner)
    if living_thermal_zone.nil?
        return false
    end
	fbasement_thermal_zone_r = runner.getStringArgumentValue("fbasement_thermal_zone",user_arguments)
    fbasement_thermal_zone = HelperMethods.get_thermal_zone_from_string(model, fbasement_thermal_zone_r, runner, false)
	
    baseboardEfficiency = runner.getDoubleArgumentValue("userdefinedeff",user_arguments)
    baseboardOutputCapacity = runner.getStringArgumentValue("selectedbaseboardcap",user_arguments)
    if not baseboardOutputCapacity == "Autosize"
      baseboardOutputCapacity = OpenStudio::convert(baseboardOutputCapacity.split(" ")[0].to_f,"kBtu/h","Btu/h").get
    end

    heatingseasonschedule = nil
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "HeatingSeasonSchedule"
        heatingseasonschedule = scheduleRuleset
        break
      end
    end

    # Check if has equipment
    baseboards = model.getZoneHVACBaseboardConvectiveElectrics
    baseboards.each do |baseboard|
      thermalZone = baseboard.thermalZone.get
      runner.registerInfo("Removed '#{baseboard.name}' from thermal zone '#{thermalZone.name}'")
      baseboard.remove
    end

    zones = model.getThermalZones
    zones.each do |zone|

      if living_thermal_zone.handle.to_s == zone.handle.to_s

        htg_coil = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
        htg_coil.setName("Living Zone Electric Baseboards")
        htg_coil.setAvailabilitySchedule(heatingseasonschedule)
        if baseboardOutputCapacity != "Autosize"
          htg_coil.setNominalCapacity(OpenStudio::convert(baseboardOutputCapacity,"Btu/h","W").get)
        end
        htg_coil.setEfficiency(baseboardEfficiency)

        htg_coil.addToThermalZone(zone)
        runner.registerInfo("Added baseboard convective electric '#{htg_coil.name}' to thermal zone '#{zone.name}'")

      end

      if not fbasement_thermal_zone.nil?

        if fbasement_thermal_zone.handle.to_s == zone.handle.to_s

          htg_coil = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
          htg_coil.setName("FBsmt Zone Electric Baseboards")
          htg_coil.setAvailabilitySchedule(heatingseasonschedule)
          if baseboardOutputCapacity != "Autosize"
            htg_coil.setNominalCapacity(OpenStudio::convert(baseboardOutputCapacity,"Btu/h","W").get)
          end
          htg_coil.setEfficiency(baseboardEfficiency)

          htg_coil.addToThermalZone(zone)
          runner.registerInfo("Added baseboard convective electric '#{htg_coil.name}' to thermal zone '#{zone.name}'")

        end

      end

    end
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessElectricBaseboard.new.registerWithApplication