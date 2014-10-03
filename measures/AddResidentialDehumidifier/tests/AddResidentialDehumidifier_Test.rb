# developed for use with Ruby 2.0.0 (have your Ruby evaluate RUBY_VERSION)

require 'openstudio'

#require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddResidentialDehumidifier_Test < Test::Unit::TestCase

    def test_autoSizedEnergyFactor
        measure = AddResidentialDehumidifier.new
        oneRange = lambda{|expected,removalRate1,removalRate2=nil| 
            assert_equal(expected , measure.autoSizedEnergyFactor(removalRate1))
            assert_equal(expected , measure.autoSizedEnergyFactor(removalRate2)) if removalRate2
        }
        
        oneRange[1.2 , 1 , 25]
        oneRange[1.4 , 25.1 , 35]
        oneRange[1.5 , 35.1 , 45]
        oneRange[1.6 , 45.1 , 54]
        oneRange[1.8 , 54.1 , 75]
        oneRange[1.8 , 54.1 , 75]
        oneRange[2.5 , 75.1]
    end
    
    def test_litresFromPints
        measure = AddResidentialDehumidifier.new
        precision = 7
        assert_equal(0.47317647.round(precision) , measure.litresFromPints(1).round(precision)) # expected value was determined with independent unit conversion tool
    end
        
    def test_pintsFromLitres_against_litresFromPints
        measure = AddResidentialDehumidifier.new
        assert_equal(1.0 , measure.pintsFromLitres(measure.litresFromPints(1))) #should invert litresFromPints
    end
    
    def test_cmsFromCfm
        measure = AddResidentialDehumidifier.new
        precision = 7
        assert_equal((0.02831685/60.0).round(precision) , measure.cmsFromCfm(1).round(precision)) # expected value was determined with independent unit conversion tool
    end

end # AddResidentialDehumidifier_Test