#!/usr/bin/env ruby

require "minitest/autorun"
require "stringio"
require_relative "xgstruct"
require_relative "xgzarc"

class SimpleTest < Minitest::Test
  def test_method_missing_behavior
    # Test XGStruct classes
    classes = [
      XGStruct::GameDataFormatHdrRecord,
      XGStruct::TimeSettingRecord, 
      XGStruct::EvalLevelRecord,
      XGStruct::UnimplementedEntry,
      XGStruct::GameFileRecord,
      XGStruct::RolloutFileRecord
    ]

    classes.each do |klass|
      puts "Testing #{klass}"
      obj = klass.new
      
      # Test setter method_missing
      obj.TestField = "test_value"
      assert_equal "test_value", obj["TestField"]
      
      # Test getter method_missing for existing key
      obj["ExistingKey"] = "existing_value"
      assert_equal "existing_value", obj.ExistingKey
      
      # Test respond_to_missing for setter
      assert obj.respond_to?(:TestField=)
      
      # Test respond_to_missing for getter of existing key
      assert obj.respond_to?(:ExistingKey)
      
      # Test respond_to_missing for non-existent key
      refute obj.respond_to?(:NonExistentKey)
      
      # Test NoMethodError for non-existent getter
      assert_raises(NoMethodError) { obj.NonExistentKey }
    end
    
    # Test XGZarc classes
    zarc_classes = [XGZarc::ArchiveRecord, XGZarc::FileRecord]
    
    zarc_classes.each do |klass|
      puts "Testing #{klass}"
      obj = klass.new
      
      # Test setter method_missing
      obj.TestField = "test_value"
      assert_equal "test_value", obj["TestField"]
      
      # Test getter method_missing for existing key
      obj["ExistingKey"] = "existing_value"
      assert_equal "existing_value", obj.ExistingKey
      
      # Test respond_to_missing for setter
      assert obj.respond_to?(:TestField=)
      
      # Test respond_to_missing for getter of existing key
      assert obj.respond_to?(:ExistingKey)
      
      # Test respond_to_missing for non-existent key
      refute obj.respond_to?(:NonExistentKey)
      
      # Test NoMethodError for non-existent getter
      assert_raises(NoMethodError) { obj.NonExistentKey }
    end
  end
end