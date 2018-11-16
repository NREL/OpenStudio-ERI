require 'rexml/document'
require 'rexml/xpath'
require 'pathname' 
require 'optparse'
require_relative "resources/301validator"
require_relative "../HPXMLtoOpenStudio/resources/XMLHelper"

if ARGV.length != 1
    puts "Usage: ruby validate.rb file"
end

schemas_dir = (Pathname.new "../HPXMLtoOpenStudio/hpxml_schemas").expand_path()
hpxml_file_path = (Pathname.new ARGV[0]).expand_path()

unless File.exists?(hpxml_file_path)
    puts "'#{hpxml_file_path}' does not exist"
    exit(-1)
end   

unless Dir.exists?(schemas_dir)
    puts "Expected schemas at '#{schemas_dir}' but the directory does not exist"
    exit(-1)
end

hpxml_doc = REXML::Document.new(File.read(hpxml_file_path))

eri_use_case_errors = EnergyRatingIndex301Validator.run_validator(hpxml_doc)
hpxml_errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"))

unless eri_use_case_errors.empty?
    puts "ERI Use Case:"
    eri_use_case_errors.each do |error|
        puts "\t#{error}"
    end
    puts "\n\n"
end

unless hpxml_errors.empty?
    puts "HPXML Schema:"
    hpxml_errors.each do |error|
        puts "\t#{error}"
    end
    puts "\n\n"
end

unless eri_use_case_errors.empty? and hpxml_errors.empty?
    puts "'#{hpxml_file_path}' had validation errors"
end

