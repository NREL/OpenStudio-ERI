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
    return "ProcessElectricBaseboard"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    zone_handles = OpenStudio::StringVector.new
    zone_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    zone_args = model.getThermalZones
    zone_args_hash = {}
    zone_args.each do |zone_arg|
      zone_args_hash[zone_arg.name.to_s] = zone_arg
    end

    #looping through sorted hash of model objects
    zone_args_hash.sort.map do |key,value|
      zone_handles << value.handle.to_s
      zone_display_names << key
    end

    #make a choice argument for living zone
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", zone_handles, zone_display_names, true)
    selected_living.setDisplayName("Which is the living space zone?")
    args << selected_living

    #make a choice argument for fbsmt
    selected_fbsmt = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedfbsmt", zone_handles, zone_display_names, false)
    selected_fbsmt.setDisplayName("Which is the finished basement zone?")
    args << selected_fbsmt

    #make an argument for entering furnace installed afue
    userdefined_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedeff",true)
    userdefined_eff.setDisplayName("The efficiency of the electric baseboard.")
    userdefined_eff.setDefaultValue(1)
    args << userdefined_eff

    #make a choice argument for furnace heating output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << "Autosize"
    (5..150).step(5) do |kbtu|
      cap_display_names << "#{kbtu} kBtu/hr"
    end

    #make a string argument for furnace heating output capacity
    selected_baseboardcap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedbaseboardcap", cap_display_names, true)
    selected_baseboardcap.setDisplayName("Heating Output Capacity.")
    selected_baseboardcap.setDefaultValue("Autosize")
    args << selected_baseboardcap

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    selected_living = runner.getOptionalWorkspaceObjectChoiceValue("selectedliving",user_arguments,model)
    selected_fbsmt = runner.getOptionalWorkspaceObjectChoiceValue("selectedfbsmt",user_arguments,model)
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

      if selected_living.get.handle.to_s == zone.handle.to_s

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

      if not selected_fbsmt.empty?

        if selected_fbsmt.get.handle.to_s == zone.handle.to_s

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