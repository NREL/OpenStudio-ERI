# developed for use with Ruby 2.0.0 (have your Ruby evaluate RUBY_VERSION)

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ModifySiteWaterMainsTemperature_Test < Test::Unit::TestCase
    def tempCfromF(d)
        ModifySiteWaterMainsTemperature.new.tempCfromF(d)
    end
    def test_tempCfromF
        precision = 5;
        
        assert_equal(0,tempCfromF(32).round(precision) , "water freezes")
        assert_equal(100,tempCfromF(212).round(precision) , "water boils")
    end

    def tempDiffCfromF(d)
        ModifySiteWaterMainsTemperature.new.tempDiffCfromF(d)
    end
    def test_tempDiffCfromF
        precision = 5;
        
        assert_equal(100, tempDiffCfromF(212-32).round(precision) , "water freeze to boil span")
        assert_equal(  0, tempDiffCfromF(     0).round(precision) , "zero span")
    end
    
    def argNamed(args,name)
        xs = args.to_a.select{|a| a.name==name}
        (xs.any?) ? xs[0] : nil
    end
    
    def newArgumentMap(avgOATval,maxDiffOATval,model)

        argument_map = OpenStudio::Ruleset::OSArgumentMap.new
     
        measure = ModifySiteWaterMainsTemperature.new

        arguments = measure.arguments(model)
        
        avgOATarg = argNamed(arguments,"avgOAT").clone
        assert(avgOATarg.setValue(avgOATval))
        argument_map["avgOAT"] = avgOATarg
        
        maxDiffOATarg = argNamed(arguments,"maxDiffOAT").clone 
        assert(maxDiffOATarg.setValue(maxDiffOATval))
        argument_map["maxDiffOAT"] = maxDiffOATarg
        
        argument_map
    end 

    def prevalidation_result(avgOATval,maxDiffOATval,model)

        argument_map = newArgumentMap(avgOATval,maxDiffOATval,model)
     
        measure = ModifySiteWaterMainsTemperature.new

        runner = OpenStudio::Ruleset::OSRunner.new

        measure.prevalidate(model, runner, argument_map)
         
        runner.result 
    end 
    
    def run_result(avgOATval,maxDiffOATval,model)

        argument_map = newArgumentMap(avgOATval,maxDiffOATval,model)
     
        measure = ModifySiteWaterMainsTemperature.new

        runner = OpenStudio::Ruleset::OSRunner.new
        
        measure.run(model, runner, argument_map)  
        runner.result 
    end 
    
    VALID_avgOAT = 60.0
    VALID_maxDiffOAT = 1.0
    # confirm that prevalidation on VALID_avgOAT and VALID_maxDiffOAT succeeds with no messages
    def test_prevalidation_clean_case
        result = prevalidation_result(VALID_avgOAT,VALID_maxDiffOAT, OpenStudio::Model::Model.new)
        
        assert_equal(0, (result.errors.size + result.warnings.size + result.info.size) )
        
        assert_equal("Success", result.value.valueName)
    end
    
    def prevalidation_error_case(avgOATval,maxDiffOATval,condition, testMsg)

        result = prevalidation_result(avgOATval,maxDiffOATval, OpenStudio::Model::Model.new)
 
        assert_equal(1, (result.errors.size + result.warnings.size + result.info.size) )

        assert(condition[result.errors[0].logMessage] , testMsg )
       
        assert_equal("Fail", result.value.valueName)

    end 
     
    def prevalidation_warning_case(avgOATval,maxDiffOATval,condition,testMsg)

        result = prevalidation_result(avgOATval,maxDiffOATval, OpenStudio::Model::Model.new)

        assert_equal(1, (result.errors.size + result.warnings.size + result.info.size) )

        assert(condition[result.warnings[0].logMessage] , testMsg )
        
        assert_equal("Success", result.value.valueName)

    end 
  
    # Confirm that the various error and warning conditions on the arguments are checked
    
    def test_prevalidation_avgOAT_too_high       
        prevalidation_error_case(160.0, VALID_maxDiffOAT , lambda{|m| m.include?"high"} , "Expected temperature-too-high error message")       
    end 
    
    def test_prevalidation_avgOAT_too_low
        prevalidation_error_case(-100.0,VALID_maxDiffOAT  , lambda{|m| m.include?"low"} , "Expected temperature-too-low error message")
    end  
       
    def avgOATDefaultValue
        args = ModifySiteWaterMainsTemperature.new.arguments(OpenStudio::Model::Model.new)
        argNamed(args,"avgOAT").defaultValueAsDouble
    end
 
    def test_prevalidation_avgOAT_default_value_warning
        prevalidation_warning_case(avgOATDefaultValue, VALID_maxDiffOAT , lambda{|m| m.include?"default"} , "Expected default-temperature warning message")   
    end
    
    def test_prevalidation_avgOAT_high_warning
        prevalidation_warning_case(75,VALID_maxDiffOAT , lambda{|m| m.include?"high"} , "Expected temperature-high warning message")       
    end
    
    def test_prevalidation_avgOAT_low_warning
        prevalidation_warning_case(-60.0,VALID_maxDiffOAT , lambda{|m| m.include?"low"} , "Expected temperature-low warning message")       
    end
    
    def test_prevalidation_maxDiffOAT_too_high       
        prevalidation_error_case(VALID_avgOAT, 100.0 , lambda{|m| m.include?"high"} , "Expected max-diff-too-high error message")       
    end 
    
    def test_prevalidation_maxDiffOAT_negative      
        prevalidation_error_case(VALID_avgOAT, -100.0 , lambda{|m| m.include?"negative"} , "Expected max-diff-negative error message")       
    end 
        
    def test_prevalidation_maxDiffOAT_high_warning      
        prevalidation_warning_case(VALID_avgOAT, 31 , lambda{|m| m.include?"high"} , "Expected max-diff-high warning message")       
    end 
  
    # Confirm that the Not-Applicable condition is checked
    def test_run_skips_NotApplicable_model
        result = run_result(VALID_avgOAT, VALID_maxDiffOAT, OpenStudio::Model::Model.new) 
        assert_equal("NA", result.value.valueName)
        assert(result.info.to_a.any?{|x| x.logMessage.include?"not updated"} , "There should be an mssage that nothing was done" )
    end 
    
    # Confirm that, when applicable, the measure sets the SiteWaterMainsTemperature fields in the model, and emits a final condition message
    def test_run_updates_model
        model = countingTestModel
        
        result = run_result(VALID_avgOAT, VALID_maxDiffOAT, model) 
        
        assert_equal("Success", result.value.valueName)     

        swmt = model.getSiteWaterMainsTemperature
        assert_equal("Correlation"                             , swmt.calculationMethod   ,"calculationMethod")
        assert_equal(tempCfromF(VALID_avgOAT).round(5)         , swmt.annualAverageOutdoorAirTemperature.get.round(5) ,"annualAverageOutdoorAirTemperature")
        assert_equal(tempDiffCfromF(VALID_maxDiffOAT).round(5) , swmt.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get.round(5) ,"maximumDifferenceInMonthlyAverageOutdoorAirTemperatures")
       
        assert(result.finalCondition.get.logMessage.include?("updated") , "updated")
    end
     
    # Confirm that running the measure emits an initial conditions message
     def test_run_initial_condition
        model = countingTestModel
        result = run_result(VALID_avgOAT, VALID_maxDiffOAT, model)     
        
        initialCondition = result.initialCondition.get.logMessage;
        a = lambda{|s| # confirm that the initial condition mentions the count, embedded in spaces
            sign = " " + (model.send(s).length.to_s) + " "
            assert(initialCondition.include?(sign) ,s.to_s)  
        }
        a[:getWaterHeaterMixeds]
        a[:getWaterUseEquipments]
        a[:getWaterUseConnectionss]    
    end
    
    def modelFromTestFile(filename)
         OpenStudio::OSVersion::VersionTranslator.new
         .loadModel(OpenStudio::Path.new(File.dirname(__FILE__) + "/"+filename))
    end
    def countingTestModel
        model = modelFromTestFile("countTesting.osm").get
        waterUserEquipmentCount = model.getWaterUseEquipments.length
        waterUseConnectionCount = model.getWaterUseConnectionss.length
        waterHeaterMixedCount = model.getWaterHeaterMixeds.length
        #confirm expected preconditions on the model
        assert_equal(4,waterUserEquipmentCount)
        assert_equal(2,waterUseConnectionCount)
        assert_equal(1,waterHeaterMixedCount)     
        
        model
    end
end
