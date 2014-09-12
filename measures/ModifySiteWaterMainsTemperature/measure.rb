# developed for use with Ruby 2.0.0 (have your Ruby evaluate RUBY_VERSION)
require 'cgi'

class ModifySiteWaterMainsTemperature < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "ModifySiteWaterMainsTemperature"
  end
  
  # sets @avgOATarg and @maxDiffOATarg to our new arguments
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #Average Annual Outdoor Air Temp
    @avgOATarg = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("avgOAT",true) # true means required
    @avgOATarg.setDisplayName("Avg Annual Outdoor Air Temperature (?F)")
    @avgOATarg.setDefaultValue(50)
    args << @avgOATarg
    
    #Maximum Difference in Monthly Outdoor Air Temp
    @maxDiffOATarg = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("maxDiffOAT",true)
    @maxDiffOATarg.setDisplayName("Max Difference in Monthly Outdoor Air Temp (?F)")
    @maxDiffOATarg.setDefaultValue(30)
    args << @maxDiffOATarg
    
    return args
  end # arguments 

  #Put argument values in @avgOAT and @maxDiffOAT, returning true if they validate, false otherwise
  #(UserScript should exit(return false) if false is returned, like with registerWarning)
  def prevalidate(model, runner, user_arguments)

    modelArgs = arguments(model)
  
    #use the built-in error checking 
    return false unless runner.validateUserArguments(modelArgs, user_arguments)

    #isolate relevant user argument values
    @avgOAT = runner.getDoubleArgumentValue("avgOAT",user_arguments)
    @maxDiffOAT = runner.getDoubleArgumentValue("maxDiffOAT",user_arguments)

    
    #CHECK for INVALID arguments
    
    #"UserScripts should return false after calling [registerError]" see http://openstudio.nrel.gov/c-sdk-documentation/ruleset
    emit = lambda{|msg| runner.registerError(CGI.escapeHTML(msg +" -- please resubmit")) ;  false  }
    
    avgOATMax = 85;
    return false unless @avgOAT <= avgOATMax or emit["Temperature #{@avgOAT}F too high (>#{avgOATMax})"]
    
    avgOATMin = -70;
    return false unless avgOATMin <= @avgOAT or emit["Temperature #{@avgOAT}F too low (<#{avgOATMin})"]
    
    maxDiffOATMax = 40;
    return false unless @maxDiffOAT <= maxDiffOATMax or emit["Temperature Diff #{@maxDiffOAT}F too high (>#{maxDiffOATMax})"]

    return false unless 0 <= @maxDiffOAT or emit["Temperature Diff #{@maxDiffOAT}F must not be negative"]

    
    #CHECK for VALID-BUT-IFFY arguments
    
    #"The UserScript should exit (return false) if false is returned [from registerWarning]" see http://openstudio.nrel.gov/c-sdk-documentation/ruleset
    emit = lambda{|msg| runner.registerWarning(CGI.escapeHTML(msg)) } 
    
    return false unless @avgOAT != @avgOATarg.defaultValueAsDouble or emit["Using default Average temp (#{@avgOAT}F)"]
   
    avgOATRatherHigh = 70
    return false unless @avgOAT <= avgOATRatherHigh or emit["Temperature #{@avgOAT}F is rather high (>#{avgOATRatherHigh})"]
    
    avgOATRatherLow = -40
    return false unless avgOATRatherLow <= @avgOAT or emit["Temperature #{@avgOAT}F is rather low (<#{avgOATRatherLow})"]
    
    maxDiffOATRatherHigh = 30
    return false unless @maxDiffOAT <= maxDiffOATRatherHigh or emit["Temperature Diff #{@maxDiffOAT}F is rather high (>#{maxDiffOATRatherHigh})"]
    
    true
  end # prevalidate

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
  
    return false unless prevalidate(model, runner, user_arguments)
    
    waterUseEquipment  = Hash[:count=> model.getWaterUseEquipments.length   , :display=> "Water Use Equipment" ]
    waterUseConnection = Hash[:count=> model.getWaterUseConnectionss.length , :display=> "Water Use Connections"]
    waterHeaterMixed   = Hash[:count=> model.getWaterHeaterMixeds.length    , :display=> "Water Heaters (Mixed)"]
    
    displayCount = lambda{|x| "#{x[:count]} #{x[:display]}"}
    
    runner.registerInitialCondition CGI.escapeHTML(
                                    "Initially there were #{displayCount[waterUseEquipment]}"+
                                    ", #{displayCount[waterHeaterMixed]}"+
                                    ", and #{displayCount[waterUseConnection]}" 
                                    )
     
    if (0== waterUseEquipment[:count] +waterUseConnection[:count] +waterHeaterMixed[:count])
        runner.registerAsNotApplicable CGI.escapeHTML(
                                       "SiteWaterMainsTemperature was not updated, since there was"+
                                       " no #{waterUseEquipment[:display]}"+
                                       ", no #{waterHeaterMixed[:display]}"+
                                       ", and no #{waterUseConnection[:display]}"
                                       )
    else

        swmt = model.getSiteWaterMainsTemperature
        
        swmt.setCalculationMethod "Correlation"
        swmt.setAnnualAverageOutdoorAirTemperature tempCfromF(@avgOAT)
        swmt.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures  tempDiffCfromF(@maxDiffOAT)
        
        runner.registerFinalCondition CGI.escapeHTML(
                                      "SiteWaterMainsTemperature has been updated with"+
                                      " Avg Temperature #{@avgOAT}F (#{swmt.annualAverageOutdoorAirTemperature.get.round(1)}C)"+
                                      " and Max Diff #{@maxDiffOAT}F (#{swmt.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get.round(1)}C)"
                                      )
    end
    
    true
  end # run 

  def tempCfromF(x)
    OpenStudio::convert(x*1.0,"F","C").get
  end
  
  def tempDiffCfromF(d) #if d is the difference between two temps in F, then tempDiffCfromF(d) is the difference between the temps in C
    tempCfromF(d) -tempCfromF(0)
  end
  
end # ModifySiteWaterMainsTemperature

#this allows the measure to be use by the application
ModifySiteWaterMainsTemperature.new.registerWithApplication