#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#load util.rb
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

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
    return "Set Residential Crankcase Heater for Heat Pump and Multispeed Air Conditioner"
  end
  
  def description
    return "This measure creates a crankcase heater for heat pumps and multispeed air conditioners."
  end
  
  def modeler_description
    return "Using EMS code, this measure creates a crankcase heater electric equipment object for heat pumps and also air conditioners with number of compressor speeds greater than one."
  end     
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for entering crankcase heater capacity
    userdefined_crankcase = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcrankcase",true)
    userdefined_crankcase.setDisplayName("Crankcase [kW]")
    userdefined_crankcase.setDescription("Capacity of the crankcase heater for the compressor.")
    userdefined_crankcase.setDefaultValue(0.02)
    args << userdefined_crankcase

    #make an argument for entering crankcase heater max temp
    userdefined_crankcasemaxt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcrankcasemaxt",true)
    userdefined_crankcasemaxt.setDisplayName("Crankcase Max Temp [degrees F]")
    userdefined_crankcasemaxt.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    userdefined_crankcasemaxt.setDefaultValue(55.0)
    args << userdefined_crankcasemaxt

    #make a choice argument for living thermal zone
    thermal_zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    thermal_zone_args = OpenStudio::StringVector.new
    thermal_zones.each do |thermal_zone|
		zone_arg_name = thermal_zone.getString(0) # Name
        thermal_zone_args << zone_arg_name.to_s
    end
    if thermal_zone_args.empty?
        thermal_zone_args << Constants.LivingZone
    end
    living_thermal_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("living_thermal_zone", thermal_zone_args, true)
    living_thermal_zone.setDisplayName("Living thermal zone")
    living_thermal_zone.setDescription("Select the living thermal zone")
    if thermal_zone_args.include?(Constants.LivingZone)
        living_thermal_zone.setDefaultValue(Constants.LivingZone)
    end
    args << living_thermal_zone		    
    
    return args

  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end
    
    model = runner.lastOpenStudioModel.get

    living_thermal_zone_r = runner.getStringArgumentValue("living_thermal_zone",user_arguments)
    living_thermal_zone = Geometry.get_thermal_zone_from_string(model, living_thermal_zone_r, runner, false)
    if living_thermal_zone.nil?
      return false
    end

    # Remove existing crankcase heater objects
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Crankcase Heater"], "ElectricEquipment", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["CrankcaseHeaterManager"], "EnergyManagementSystem:ProgramCallingManager", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["CrankcaseHeaterActuator"], "EnergyManagementSystem:Actuator", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["CoolingCoilRTF", "HeatingCoilRTF"], "EnergyManagementSystem:Sensor", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["CrankcaseHeaterProgram"], "EnergyManagementSystem:Program", runner)

    # Find heat pump
    hasHeatPump = true
    if workspace.getObjectsByType("AirLoopHVAC:UnitaryHeatPump:AirToAir".to_IddObjectType).empty? and workspace.getObjectsByType("AirLoopHVAC:UnitaryHeatPump:AirToAir:MultiSpeed".to_IddObjectType).empty?
      hasHeatPump = false  
    end

    # Get compressor speeds
    compressor_speeds = nil
    if not workspace.getObjectsByType("Coil:Cooling:DX:SingleSpeed".to_IddObjectType).empty?
      compressor_speeds = 1.0
    elsif not workspace.getObjectsByType("Coil:Cooling:DX:MultiSpeed".to_IddObjectType).empty?
      compressor_speeds = 2.0
    end
    
    # Error checking
    if compressor_speeds.nil?
      runner.registerWarning("No Coil:Cooling:DX object found, so crankcase heater is not necessary.")
      return true
    end
    if not hasHeatPump and compressor_speeds == 1.0
      runner.registerWarning("Crankcase heater is not necessary for building with HP=false and compressor_speeds=1")
      return true
    end
    
    # Create the material class instances
    supply = Supply.new

    supply.Crankcase = runner.getDoubleArgumentValue("userdefinedcrankcase",user_arguments)
    supply.Crankcase_MaxT = runner.getDoubleArgumentValue("userdefinedcrankcasemaxt",user_arguments)
    supply.compressor_speeds = compressor_speeds

    # Crankcase heater for heat pumps and multispeed air conditioners
    # These EMS components are used to account for the crankcase heater power use for heat pumps and multi-stage/speed air conditioners
    # For heat pumps, E+ assigns crankcase power to the heating coil by default
    # For multi-stage ACs, using the heat coil crankcase heater inputs will not work since the crankcase could be operating while the furnace is on
    # This EMS code fixes both issues.

    ems = []

    ems << "
    Schedule:Constant,
      AlwaysOn,                                             !- Name
      FRACTION,                                             !- Schedule Type
      1;                                                    !- Hourly Value"
    
    ems << "
    ElectricEquipment,
      Crankcase Heater,                                     !- Name
      #{living_thermal_zone_r},                             !- Zone Name
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
      CrankcaseHeaterActuator,                              !- Name
      Crankcase Heater,                                     !- Actuated Component Unique Name
      ElectricEquipment,                                    !- Actuated Component Type
      Electric Power Level;                                 !- Actuated Component Control Type"

    ems << "
    EnergyManagementSystem:Sensor,                          
      CoolingCoilRTF,                                       !- Name
      DX Cooling Coil,                                      !- Output:Variable or Output:Meter Index Key Name
      Cooling Coil Runtime Fraction;                        !- Output:Variable or Output:Meter Name"

    if hasHeatPump
      ems << "
      EnergyManagementSystem:Sensor,    
        HeatingCoilRTF,                                     !- Name
        DX Heating Coil,                                    !- Output:Variable or Output:Meter Index Key Name
        Heating Coil Runtime Fraction;                      !- Output:Variable or Output:Meter Name"
    end

    if supply.compressor_speeds > 1.0
      ems << "
      EnergyManagementSystem:Sensor,
        UnitaryEquipCyclingRatio,                           !- Name
        Forced Air System,                                  !- Output:Variable or Output:Meter Index Key Name
        Unitary System DX Coil Cycling Ratio;               !- Output:Variable or Output:Meter Name"
    end

    ems_program = "
    EnergyManagementSystem:Program,
      CrankcaseHeaterProgram,                               !- Name
      If Tout > #{OpenStudio::convert(supply.Crankcase_MaxT,"F","C").get},
      Set CrankcaseHeaterActuator = 0,
      Else,"

    if not hasHeatPump
      # Handles multi-speed ACs
      ems_program += "
      If CoolingCoilRTF > 0,"
    else
      # Handles all HPs
      ems_program += "
      If (CoolingCoilRTF > 0) || (HeatingCoilRTF > 0),"
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

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessSystemCrankcaseHeater.new.registerWithApplication