#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class ProcessSystemCrankcaseHeater < OpenStudio::Ruleset::WorkspaceUserScript

  class Supply
    def initialize
    end
    attr_accessor(:Crankcase, :Crankcase_MaxT, :compressor_speeds)
  end

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ProcessSystemCrankcaseHeater"
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    zone_display_names = OpenStudio::StringVector.new

    #get all thermal zones in model
    zone_args = workspace.getObjectsByType("Zone".to_IddObjectType)
    zone_args.each do |zone_arg|
      zone_arg_name = zone_arg.getString(0) # Name
      zone_display_names << zone_arg_name.to_s
    end

    #make a choice argument for living space
    selected_living = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedliving", zone_display_names, true)
    selected_living.setDisplayName("Which is the living space zone?")
    args << selected_living

    #make an argument for entering crankcase heater capacity
    userdefined_crankcase = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcrankcase",true)
    userdefined_crankcase.setDisplayName("Crankcase heater capacity [kW].")
    userdefined_crankcase.setDefaultValue(0.0)
    args << userdefined_crankcase

    #make an argument for entering crankcase heater max temp
    userdefined_crankcasemaxt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcrankcasemaxt",true)
    userdefined_crankcasemaxt.setDisplayName("Maximum outdoor drybulb temperature for crankcase heater operation [F].")
    userdefined_crankcasemaxt.setDefaultValue(55.0)
    args << userdefined_crankcasemaxt

    #make a bool argument for heat pump
    selected_heatpump = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedheatpump",false)
    selected_heatpump.setDisplayName("The building has a heat pump.")
    selected_heatpump.setDefaultValue(false)
    args << selected_heatpump

    #make an argument for entering speeds
    userdefined_speeds = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedspeeds",true)
    userdefined_speeds.setDisplayName("Number of speeds of the compressor.")
    userdefined_speeds.setDefaultValue(1.0)
    args << userdefined_speeds

    return args

  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    selected_living = runner.getStringArgumentValue("selectedliving",user_arguments)
    hasHeatPump = runner.getBoolArgumentValue("selectedheatpump",user_arguments)

    # Create the material class instances
    supply = Supply.new

    supply.Crankcase = runner.getDoubleArgumentValue("userdefinedcrankcase",user_arguments)
    supply.Crankcase_MaxT = runner.getDoubleArgumentValue("userdefinedcrankcasemaxt",user_arguments)
    supply.compressor_speeds = runner.getDoubleArgumentValue("userdefinedspeeds",user_arguments)

    if not hasHeatPump and supply.compressor_speeds == 1.0
      runner.registerWarning("Crankcase heater is not necessary for building with HP=false and compressor_speeds=1")
    else

      # Crankcase heater for heat pumps and multispeed air conditioners
      # These EMS components are used to account for the crankcase heater power use for heat pumps and multi-stage/speed air conditioners
      # For heat pumps, E+ assigns crankcase power to the heating coil by default
      # For multi-stage ACs, using the heat coil crankcase heater inputs will not work since the crankcase could be operating while the furnace is on
      # This EMS code fixes both issues.

      ems = []

      ems << "
      ElectricEquipment,
        Crankcase Heater,                                      !- Name
        #{selected_living},                                   !- Zone Name
        AlwaysOn,                                             !- SCHEDULE Name
        EquipmentLevel,                                       !- Design Level calculation method
        0,                                                    !- Design Level {W}
        ,                                                     !- Watts per Zone Floor Area {watts/m2}
        ,                                                     !- Watts per Person {watts/person}
        0,                                                    !- Fraction Latent
        0,                                                    !- Fraction Radiant
        1,                                                    !- Fraction Lost
        CustomCrankcaseHeater;                                !- End-use Subcategory"

      ems << "
      EnergyManagementSystem:Actuator,
        CrankcaseHeaterActuator,                            !- Name
        Crankcase Heater,                                   !- Actuated Component Unique Name
        ElectricEquipment,                                  !- Actuated Component Type
        Electric Power Level;                               !- Actuated Component Control Type"

      ems << "
      EnergyManagementSystem:Sensor,
        CoolingCoilRTF,
        DX Cooling Coil,
        Cooling Coil Runtime Fraction;"

      if hasHeatPump
        ems << "
        EnergyManagementSystem:Sensor,
          HeatingCoilRTF,
          DX Heating Coil,
          Heating Coil Runtime Fraction;"
      end

      if supply.compressor_speeds > 1.0
        # tk what output variable do we need to add to get this to work?
        # ems << "
        # EnergyManagementSystem:Sensor,
        #   UnitaryEquipCyclingRatio,
        #   Forced Air System,
        #   Unitary System DX Coil Cycling Ratio;"
      end

      ems_program = "
      EnergyManagementSystem:Program,
        CrankcaseHeaterProgram,
        If Tout < #{OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get},
        Set CrankcaseHeaterActuator = 0,
        Else,"

      if not hasHeatPump
        # Handles multi-speed ACs
        ems_program += "
        If CoolingCoilRTF > 0,"
      else
        # Handles all HPs
        ems_program += "
        If CoolingCoilRTF > 0 || HeatingCoilRTF > 0,"
      end

      if supply.compressor_speeds > 1.0
        ems_program += "
        Set CrankcaseHeaterActuator = (1.0-UnitaryEquipCyclingRatio) * #{OpenStudio::convert(supply.Crankcase,"kW","W").get},"
      else
        #There must be a heat pump if this code is being executed
        ems_program += "
        Set CrankcaseHeaterActuator = (1.0-CoolingCoilRTF-HeatingCoilRTF) * #{OpenStudio::convert(supply.Crankcase,"kW","W").get},"
      end

      ems_program += "
      Else,
      Set CrankcaseHeaterActuator = #{OpenStudio::convert(supply.Crankcase,"kW","W").get},
      EndIf,
      EndIf;"

      ems << ems_program

      # Program Calling Manager
      ems << "
      EnergyManagementSystem:ProgramCallingManager,
        CrankcaseHeaterManager,                             !- Name
        EndOfZoneTimestepBeforeZoneReporting,               !- EnergyPlus Model Calling Point
        CrankcaseHeaterProgram;                             !- Program Name 1"

      ems.each do |str|
        idfObject = OpenStudio::IdfObject::load(str)
        object = idfObject.get
        wsObject = workspace.addObject(object)
        runner.registerInfo("Set object '#{str.split("\n")[1].gsub(",","")} - #{str.split("\n")[2].split(",")[0]}'")
      end

    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessSystemCrankcaseHeater.new.registerWithApplication