require_relative "test_helper_simple"
require_relative "../xgstruct"

class TestXGStruct < Minitest::Test
  include TestHelper

  # Test GameDataFormatHdrRecord
  def test_game_data_format_hdr_record_initialization
    record = XGStruct::GameDataFormatHdrRecord.new

    # Test default values
    assert_equal 0, record["MagicNumber"]
    assert_equal 0, record["HeaderVersion"]
    assert_equal 0, record["HeaderSize"]
    assert_equal 0, record["ThumbnailOffset"]
    assert_equal 0, record["ThumbnailSize"]
    assert_nil record["GameGUID"]
    assert_nil record["GameName"]
    assert_nil record["SaveName"]
    assert_nil record["LevelName"]
    assert_nil record["Comments"]
  end

  def test_game_data_format_hdr_record_initialization_with_params
    record = XGStruct::GameDataFormatHdrRecord.new(
      "MagicNumber" => 123,
      "HeaderVersion" => 1,
      "GameName" => "Test Game"
    )

    assert_equal 123, record["MagicNumber"]
    assert_equal 1, record["HeaderVersion"]
    assert_equal "Test Game", record["GameName"]
    assert_equal 0, record["HeaderSize"]  # Default value preserved
  end

  def test_game_data_format_hdr_record_hash_behavior
    record = XGStruct::GameDataFormatHdrRecord.new

    # Test hash-like access
    assert_hash_like_behavior(record, "TestKey", "TestValue")
  end

  def test_game_data_format_hdr_record_method_missing
    record = XGStruct::GameDataFormatHdrRecord.new

    # Test setter method
    record.GameName = "New Game"
    assert_equal "New Game", record["GameName"]

    # Test getter method
    record["HeaderVersion"] = 2
    assert_equal 2, record.HeaderVersion

    # Test unknown method
    assert_raises(NoMethodError) { record.unknown_method }
  end

  def test_game_data_format_hdr_record_respond_to_missing
    record = XGStruct::GameDataFormatHdrRecord.new
    record["TestKey"] = "value"

    # Should respond to setter
    assert record.respond_to?(:TestKey=)

    # Should respond to getter for existing key
    assert record.respond_to?(:TestKey)

    # Should not respond to unknown method
    refute record.respond_to?(:unknown_method)
  end

  def test_game_data_format_hdr_record_fromstream_invalid_data
    # Test with invalid stream data
    stream = StringIO.new("invalid data")
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  def test_game_data_format_hdr_record_fromstream_short_data
    # Test with insufficient data
    data = [0] * 100  # Not enough bytes
    stream = create_string_io(data)
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  def test_game_data_format_hdr_record_fromstream_valid_data
    # Create valid test data
    data = [0] * XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    # Set magic number to 'HMGR' (reversed for little-endian)
    data[0] = 82   # 'R'
    data[1] = 71   # 'G'
    data[2] = 77   # 'M'
    data[3] = 72   # 'H'
    # Set version to 1
    data[4] = 1
    data[5] = 0
    data[6] = 0
    data[7] = 0

    stream = create_string_io(data)
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_equal record, result
    assert_equal "HMGR", record["MagicNumber"]
    assert_equal 1, record["HeaderVersion"]
  end

  def test_game_data_format_hdr_record_fromstream_invalid_magic
    # Test with invalid magic number
    data = [0] * XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    # Set wrong magic number
    data[0] = 88   # Wrong magic
    data[1] = 88
    data[2] = 88
    data[3] = 88
    # Set version to 1
    data[4] = 1
    data[5] = 0
    data[6] = 0
    data[7] = 0

    stream = create_string_io(data)
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  def test_game_data_format_hdr_record_fromstream_invalid_version
    # Test with invalid version
    data = [0] * XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    # Set magic number to 'HMGR' (reversed for little-endian)
    data[0] = 82   # 'R'
    data[1] = 71   # 'G'
    data[2] = 77   # 'M'
    data[3] = 72   # 'H'
    # Set wrong version
    data[4] = 2
    data[5] = 0
    data[6] = 0
    data[7] = 0

    stream = create_string_io(data)
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  # Test TimeSettingRecord
  def test_time_setting_record_initialization
    record = XGStruct::TimeSettingRecord.new

    # Test default values
    assert_equal 0, record["ClockType"]
    assert_equal false, record["PerGame"]
    assert_equal 0, record["Time1"]
    assert_equal 0, record["Time2"]
    assert_equal 0, record["Penalty"]
    assert_equal 0, record["TimeLeft1"]
    assert_equal 0, record["TimeLeft2"]
    assert_equal 0, record["PenaltyMoney"]
  end

  def test_time_setting_record_initialization_with_params
    record = XGStruct::TimeSettingRecord.new(
      "ClockType" => 1,
      "PerGame" => true,
      "Time1" => 300
    )

    assert_equal 1, record["ClockType"]
    assert_equal true, record["PerGame"]
    assert_equal 300, record["Time1"]
    assert_equal 0, record["Time2"]  # Default preserved
  end

  def test_time_setting_record_method_missing
    record = XGStruct::TimeSettingRecord.new

    # Test setter and getter
    record.ClockType = 2
    assert_equal 2, record["ClockType"]

    record["Time1"] = 600
    assert_equal 600, record.Time1
  end

  def test_time_setting_record_fromstream
    # Create test data for TimeSettingRecord
    data = [
      1, 0, 0, 0,      # ClockType = 1
      1, 0, 0, 0,      # PerGame = true (1)
      100, 1, 0, 0,    # Time1 = 356 (little-endian)
      200, 0, 0, 0,    # Time2 = 200
      50, 0, 0, 0,     # Penalty = 50
      80, 0, 0, 0,     # TimeLeft1 = 80
      90, 0, 0, 0,     # TimeLeft2 = 90
      25, 0, 0, 0      # PenaltyMoney = 25
    ]

    stream = create_string_io(data)
    record = XGStruct::TimeSettingRecord.new

    result = record.fromstream(stream)
    assert_equal record, result
    assert_equal 1, record["ClockType"]
    assert_equal true, record["PerGame"]
    assert_equal 356, record["Time1"]
    assert_equal 200, record["Time2"]
    assert_equal 50, record["Penalty"]
    assert_equal 80, record["TimeLeft1"]
    assert_equal 90, record["TimeLeft2"]
    assert_equal 25, record["PenaltyMoney"]
  end

  # Test EvalLevelRecord
  def test_eval_level_record_initialization
    record = XGStruct::EvalLevelRecord.new

    # Test default values
    assert_equal 0, record["Level"]
    assert_equal false, record["isDouble"]
  end

  def test_eval_level_record_initialization_with_params
    record = XGStruct::EvalLevelRecord.new("Level" => 5, "isDouble" => true)

    assert_equal 5, record["Level"]
    assert_equal true, record["isDouble"]
  end

  def test_eval_level_record_method_missing
    record = XGStruct::EvalLevelRecord.new

    # Test setter and getter
    record.Level = 3
    assert_equal 3, record["Level"]

    record["isDouble"] = true
    assert_equal true, record.isDouble
  end

  def test_eval_level_record_fromstream
    # Create test data for EvalLevelRecord
    data = [
      5, 0,    # Level = 5 (little-endian short)
      1,       # isDouble = true
      0        # padding
    ]

    stream = create_string_io(data)
    record = XGStruct::EvalLevelRecord.new

    result = record.fromstream(stream)
    assert_equal record, result
    assert_equal 5, record["Level"]
    assert_equal true, record["isDouble"]
  end

  # Test UnimplementedEntry
  def test_unimplemented_entry_initialization
    entry = XGStruct::UnimplementedEntry.new

    # Test default values
    assert_equal "UNKNOWN", entry["EntryType"]
    assert_equal "UnimplementedEntry", entry["Name"]
  end

  def test_unimplemented_entry_initialization_with_params
    entry = XGStruct::UnimplementedEntry.new("EntryType" => "TEST", "Name" => "TestEntry")

    assert_equal "TEST", entry["EntryType"]
    assert_equal "TestEntry", entry["Name"]
  end

  def test_unimplemented_entry_method_missing
    entry = XGStruct::UnimplementedEntry.new

    # Test setter and getter
    entry.EntryType = "CUSTOM"
    assert_equal "CUSTOM", entry["EntryType"]

    entry["Name"] = "CustomEntry"
    assert_equal "CustomEntry", entry.Name
  end

  def test_unimplemented_entry_fromstream
    # Should return self regardless of stream content
    stream = StringIO.new("any data")
    entry = XGStruct::UnimplementedEntry.new

    result = entry.fromstream(stream)
    assert_equal entry, result
  end

  # Test GameFileRecord
  def test_game_file_record_initialization
    record = XGStruct::GameFileRecord.new

    # Should be empty hash by default
    assert_equal({}, record)
  end

  def test_game_file_record_initialization_with_version
    record = XGStruct::GameFileRecord.new(version: 2)

    # Should have version set but hash empty
    assert_equal 2, record.instance_variable_get(:@version)
    assert_equal({}, record)
  end

  def test_game_file_record_initialization_with_params
    record = XGStruct::GameFileRecord.new(:version => 1, "TestKey" => "TestValue")

    assert_equal "TestValue", record["TestKey"]
  end

  def test_game_file_record_method_missing
    record = XGStruct::GameFileRecord.new

    # Test setter and getter
    record.TestKey = "TestValue"
    assert_equal "TestValue", record["TestKey"]

    record["AnotherKey"] = "AnotherValue"
    assert_equal "AnotherValue", record.AnotherKey
  end

  def test_game_file_record_fromstream
    # Should return UnimplementedEntry
    stream = StringIO.new("any data")
    record = XGStruct::GameFileRecord.new

    result = record.fromstream(stream)
    assert_instance_of XGStruct::UnimplementedEntry, result
  end

  # Test RolloutFileRecord
  def test_rollout_file_record_initialization
    record = XGStruct::RolloutFileRecord.new

    # Should be empty hash by default
    assert_equal({}, record)
  end

  def test_rollout_file_record_initialization_with_params
    record = XGStruct::RolloutFileRecord.new("TestKey" => "TestValue")

    assert_equal "TestValue", record["TestKey"]
  end

  def test_rollout_file_record_method_missing
    record = XGStruct::RolloutFileRecord.new

    # Test setter and getter
    record.TestKey = "TestValue"
    assert_equal "TestValue", record["TestKey"]

    record["AnotherKey"] = "AnotherValue"
    assert_equal "AnotherValue", record.AnotherKey
  end

  def test_rollout_file_record_fromstream
    # Should return UnimplementedEntry
    stream = StringIO.new("any data")
    record = XGStruct::RolloutFileRecord.new

    result = record.fromstream(stream)
    assert_instance_of XGStruct::UnimplementedEntry, result
  end

  # Test HeaderMatchEntry
  def test_header_match_entry_initialization
    entry = XGStruct::HeaderMatchEntry.new

    # Test default Version
    assert_equal(-1, entry.version)
    assert_equal({}, entry)
  end

  def test_header_match_entry_initialization_with_params
    entry = XGStruct::HeaderMatchEntry.new("TestKey" => "TestValue")

    assert_equal(-1, entry.version)
    assert_equal "TestValue", entry["TestKey"]
  end

  def test_header_match_entry_version_accessor
    entry = XGStruct::HeaderMatchEntry.new

    # Test Version setter and getter
    entry.version = 5
    assert_equal 5, entry.version
  end

  # Test module structure
  def test_module_exists
    assert defined?(XGStruct)
    assert XGStruct.is_a?(Module)
  end

  def test_all_classes_exist
    expected_classes = [
      :GameDataFormatHdrRecord,
      :TimeSettingRecord,
      :EvalLevelRecord,
      :UnimplementedEntry,
      :GameFileRecord,
      :RolloutFileRecord,
      :HeaderMatchEntry
    ]

    expected_classes.each do |class_name|
      assert XGStruct.const_defined?(class_name), "XGStruct should define #{class_name}"
    end
  end

  def test_classes_inherit_from_hash
    hash_classes = [
      XGStruct::GameDataFormatHdrRecord,
      XGStruct::TimeSettingRecord,
      XGStruct::EvalLevelRecord,
      XGStruct::UnimplementedEntry,
      XGStruct::GameFileRecord,
      XGStruct::RolloutFileRecord,
      XGStruct::HeaderMatchEntry
    ]

    hash_classes.each do |klass|
      assert klass.new.is_a?(Hash), "#{klass} should inherit from Hash"
    end
  end

  def test_constants_defined
    assert_equal 8232, XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    assert_equal 32, XGStruct::TimeSettingRecord::SIZEOFREC
    assert_equal 4, XGStruct::EvalLevelRecord::SIZEOFREC
  end

  # Additional edge case tests for better coverage
  def test_all_classes_method_missing_with_non_string_keys
    # Test method_missing with non-string method names
    record = XGStruct::GameDataFormatHdrRecord.new

    # Test with symbol-like method
    record.send(:test_key=, "value")
    assert_equal "value", record["test_key"]
  end

  def test_all_classes_respond_to_missing_edge_cases
    record = XGStruct::UnimplementedEntry.new

    # Test respond_to_missing with include_private parameter
    assert record.respond_to?(:test=, false)
    assert record.respond_to?(:test=, true)
  end

  def test_game_data_format_hdr_record_fromstream_exception_handling
    # Test exception handling in fromstream
    stream = StringIO.new("") # Empty stream will cause read to fail
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  # Additional edge case tests for better coverage
  def test_game_data_format_hdr_record_fromstream_insufficient_data
    # Test with insufficient data
    data = "HMGR" + ([0] * 100).pack("C*")  # Much less than SIZEOFREC
    stream = StringIO.new(data)
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  def test_game_data_format_hdr_record_fromstream_wrong_magic
    # Test with wrong magic number
    data = [0] * XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    # Set wrong magic number
    data[0] = 88  # 'X'
    data[1] = 71  # 'G'
    data[2] = 77  # 'M'
    data[3] = 72  # 'H'
    # Set version to 1
    data[4] = 1
    data[5] = 0
    data[6] = 0
    data[7] = 0

    stream = StringIO.new(data.pack("C*"))
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  def test_game_data_format_hdr_record_fromstream_wrong_version
    # Test with wrong version
    data = [0] * XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    # Set correct magic number 'HMGR' (reversed for little-endian)
    data[0] = 82  # 'R'
    data[1] = 71  # 'G' 
    data[2] = 77  # 'M'
    data[3] = 72  # 'H'
    # Set wrong version
    data[4] = 2  # Wrong version (should be 1)
    data[5] = 0
    data[6] = 0
    data[7] = 0

    stream = StringIO.new(data.pack("C*"))
    record = XGStruct::GameDataFormatHdrRecord.new

    result = record.fromstream(stream)
    assert_nil result
  end

  def test_time_setting_record_fromstream_with_invalid_boolean
    # Test TimeSettingRecord with different boolean values
    data = [0] * XGStruct::TimeSettingRecord::SIZEOFREC
    
    # Set ClockType = 2
    data[0] = 2
    data[1] = 0
    data[2] = 0
    data[3] = 0
    
    # Set PerGame to non-zero (should convert to true)
    data[4] = 255
    
    stream = StringIO.new(data.pack("C*"))
    record = XGStruct::TimeSettingRecord.new
    
    result = record.fromstream(stream)
    assert_equal record, result
    assert_equal 2, record["ClockType"]
    assert_equal true, record["PerGame"]
  end

  def test_eval_level_record_fromstream_with_boolean_conversion
    # Test EvalLevelRecord with different boolean values  
    data = [0] * XGStruct::EvalLevelRecord::SIZEOFREC
    
    # Set Level = -1 (signed short)
    data[0] = 0xFF  # -1 in little-endian signed short
    data[1] = 0xFF
    
    # Set isDouble to non-zero
    data[2] = 1
    
    stream = StringIO.new(data.pack("C*"))
    record = XGStruct::EvalLevelRecord.new
    
    result = record.fromstream(stream)
    assert_equal record, result
    assert_equal -1, record["Level"]
    assert_equal true, record["isDouble"]
  end

  def test_game_file_record_version_attribute
    # Test that version attribute is stored separately from hash
    record = XGStruct::GameFileRecord.new(version: 25)
    
    # Version should be accessible via instance variable but not hash
    assert_equal 25, record.instance_variable_get(:@version)
    refute record.has_key?("version")
  end

  def test_header_match_entry_version_edge_cases
    # Test HeaderMatchEntry version handling
    entry = XGStruct::HeaderMatchEntry.new
    
    # Test default version
    assert_equal -1, entry.version
    
    # Test version assignment
    entry.version = 99
    assert_equal 99, entry.version
  end

  # Test method_missing and respond_to_missing for all classes
  def test_all_hash_classes_method_missing_behavior
    classes = [
      XGStruct::GameDataFormatHdrRecord,
      XGStruct::TimeSettingRecord, 
      XGStruct::EvalLevelRecord,
      XGStruct::UnimplementedEntry,
      XGStruct::GameFileRecord,
      XGStruct::RolloutFileRecord
    ]

    classes.each do |klass|
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

  def test_game_data_format_hdr_record_fromstream_with_valid_guid
    # Test with valid data including proper GUID handling
    data = [0] * XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    
    # Set magic number 'HMGR' (reversed for little-endian)
    data[0] = 82   # 'R'
    data[1] = 71   # 'G'
    data[2] = 77   # 'M'
    data[3] = 72   # 'H'
    
    # Set version to 1 (32-bit little-endian)
    data[4] = 1
    data[5] = 0
    data[6] = 0
    data[7] = 0
    
    # Set header size (32-bit little-endian) = 1000
    data[8] = 232   # 1000 & 0xFF
    data[9] = 3     # (1000 >> 8) & 0xFF  
    data[10] = 0    # (1000 >> 16) & 0xFF
    data[11] = 0    # (1000 >> 24) & 0xFF
    
    # Set thumbnail offset (64-bit little-endian) = 100
    data[12] = 100
    data[13] = 0
    data[14] = 0
    data[15] = 0
    data[16] = 0
    data[17] = 0
    data[18] = 0
    data[19] = 0
    
    # Set thumbnail size (32-bit little-endian) = 50
    data[20] = 50
    data[21] = 0
    data[22] = 0
    data[23] = 0
    
    stream = StringIO.new(data.pack("C*"))
    record = XGStruct::GameDataFormatHdrRecord.new
    
    result = record.fromstream(stream)
    assert_equal record, result
    assert_equal "HMGR", record["MagicNumber"]
    assert_equal 1, record["HeaderVersion"]
    assert_equal 1000, record["HeaderSize"]
    assert_equal 100, record["ThumbnailOffset"]
    assert_equal 50, record["ThumbnailSize"]
    assert_match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, record["GameGUID"])
  end

  def test_unimplemented_entry_default_behavior
    # Test that UnimplementedEntry has correct defaults and behavior
    entry = XGStruct::UnimplementedEntry.new
    
    assert_equal "UNKNOWN", entry["EntryType"]
    assert_equal "UnimplementedEntry", entry["Name"]
    
    # Test fromstream always returns self
    stream = StringIO.new("any data here")
    result = entry.fromstream(stream)
    assert_equal entry, result
  end

  def test_module_constants_and_structure
    # Test module structure and constants
    assert defined?(XGStruct)
    assert XGStruct.is_a?(Module)
    
    # Test all classes are defined
    classes = [
      :GameDataFormatHdrRecord, :TimeSettingRecord, :EvalLevelRecord,
      :UnimplementedEntry, :GameFileRecord, :RolloutFileRecord, :HeaderMatchEntry
    ]
    
    classes.each do |class_name|
      assert XGStruct.const_defined?(class_name), "XGStruct should define #{class_name}"
    end
    
    # Test SIZE constants
    assert_equal 8232, XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    assert_equal 32, XGStruct::TimeSettingRecord::SIZEOFREC
    assert_equal 4, XGStruct::EvalLevelRecord::SIZEOFREC
  end
end
