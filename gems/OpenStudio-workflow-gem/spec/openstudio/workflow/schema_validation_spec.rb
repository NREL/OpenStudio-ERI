require_relative './../../spec_helper'
require 'json-schema'

def get_schema(allow_optionals = true)
  schema = nil
  schema_path = File.dirname(__FILE__) + '/../../schema/osw.json'
  expect(File.exist?(schema_path)).to be true
  File.open(schema_path) do |f|
    schema = JSON.parse(f.read, symbolize_names: true)
  end
  expect(schema).to_not be_nil

  schema[:definitions].each_value do |definition|
    definition[:additionalProperties] = allow_optionals
  end

  schema
end

def get_osw(path)
  osw = nil
  osw_path = File.dirname(__FILE__) + '/../../files/' + path
  expect(File.exist?(osw_path)).to be true
  File.open(osw_path) do |f|
    osw = JSON.parse(f.read, symbolize_names: true)
  end
  expect(osw).to_not be_nil

  osw
end

def validate_osw(path, allow_optionals = true)
  schema = get_schema(allow_optionals)
  osw = get_osw(path)

  errors = JSON::Validator.fully_validate(schema, osw)
  expect(errors.empty?).to eq(true), "OSW '#{path}' is not valid, #{errors}"
end

describe 'OSW Schema' do
  it 'should be a valid OSW file' do
    validate_osw('compact_osw/compact.osw', true)
    validate_osw('extended_osw/example/workflows/extended.osw', true)
  end

  # @todo (rhorsey) make another schema which has a measure load the seed model to allow for testing a no-opt OSW
  it 'should be a strictly valid OSW file' do
    validate_osw('compact_osw/compact.osw', true)
    validate_osw('extended_osw/example/workflows/extended.osw', true)
  end
end
