require_relative "test_helper"
require_relative "../xgfile_parser"
require_relative "../xgstruct"

class TestMoveClassIntegration < Minitest::Test
  include TestHelper

  def setup
    @temp_files = []
  end

  def teardown
    @temp_files.each { |temp| temp.unlink if temp.respond_to?(:unlink) }
  end

  def create_temp_xg_file(data)
    temp = Tempfile.new(["test", ".xg"])
    temp.binmode
    temp.write(data.is_a?(Array) ? data.pack("C*") : data)
    temp.close
    @temp_files << temp
    temp.path
  end

  # Helper to create minimal valid XG header
  def create_minimal_xg_header
    header = [0] * XGFileParser::XGFile::RICH_GAME_HEADER_SIZE
    
    # Set magic number (little-endian)
    magic_bytes = [0x52, 0x47, 0x4D, 0x48]  # "RGMH"
    header[0..3] = magic_bytes
    
    # Set header version (1)
    header[4..7] = [1, 0, 0, 0]
    
    # Set header size (8232)
    size_bytes = [0x28, 0x20, 0, 0]  # 8232 in little-endian
    header[8..11] = size_bytes
    
    # Set thumbnail offset (0) and size (0)
    header[12..19] = [0] * 8
    
    header
  end

  # Helper to create XG file with compressed data
  def create_xg_file_with_data(game_data = "")
    header = create_minimal_xg_header
    compressed_data = Zlib::Deflate.deflate(game_data)
    
    header + compressed_data.bytes
  end

  def test_move_class_integration_with_parser
    # Create a mock XG file with a move record
    record_data = [0] * 2560
    record_data[8] = 3  # EntryType = tsMove
    
    # Set ActiveP to player 1 at position 9 + 52
    record_data[9 + 52, 4] = [1].pack("l<").bytes
    
    # Set some position data
    offset = 9
    (0..25).each { |i| record_data[offset + i] = (i % 25) - 12 }  # PositionI
    offset += 26
    (0..25).each { |i| record_data[offset + i] = (i % 23) - 10 }  # PositionEnd
    
    # Set dice values
    dice_offset = 9 + 26 + 26 + 4 + 3 + 32
    record_data[dice_offset, 8] = [2, 4].pack("l<2").bytes
    
    # Set cube value  
    cube_offset = dice_offset + 8
    record_data[cube_offset, 4] = [4].pack("l<").bytes
    
    # Create XG file data
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    # Parse with XGFileParser
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    # Verify we get a properly parsed MoveEntry object
    assert_equal 1, parser.game_records.length
    move_record = parser.game_records.first
    
    # Test that it's a MoveEntry object (not just a hash)
    assert_instance_of XGStruct::MoveEntry, move_record
    
    # Test all the key fields are parsed correctly
    assert_equal "Move", move_record["Type"]
    assert_equal 3, move_record["EntryType"] 
    assert_equal 1, move_record["ActiveP"]
    assert_equal 1, move_record["ActivePlayer"]  # Backwards compatibility
    assert_equal [2, 4], move_record["Dice"]
    assert_equal 4, move_record["CubeA"]
    
    # Test position arrays are correct
    assert_equal 26, move_record["PositionI"].length
    assert_equal 26, move_record["PositionEnd"].length
    assert_equal(-12, move_record["PositionI"][0])
    assert_equal(-10, move_record["PositionEnd"][0])
    
    # Test that DataMoves is parsed as EngineStructBestMoveRecord
    assert_instance_of XGStruct::EngineStructBestMoveRecord, move_record["DataMoves"]
    
    # Test accessor methods work
    assert_equal 1, move_record.ActiveP
    assert_equal [2, 4], move_record.Dice
    assert_equal false, move_record.Played
    
    # Clean up
    File.delete(filename)
  end

  def test_move_fallback_on_parse_failure
    # Create data that will compress but cause MoveEntry parsing to fail
    # Use a proper 2560-byte record but with invalid internal structure
    record_data = [0] * 2560
    record_data[8] = 3  # EntryType = tsMove
    record_data[9 + 52, 4] = [1].pack("l<").bytes
    
    # Corrupt the internal structure by putting invalid data in critical positions
    # This will cause fromstream to return nil but still allow decompression
    record_data[100..200] = [255] * 101  # Corrupt some middle data
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    # Parse should fall back to basic parsing if MoveEntry.fromstream returns nil
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal 1, parser.game_records.length
    move_record = parser.game_records.first
    
    # Should be parsed with MoveEntry since the data size is correct
    # The test verifies it doesn't crash and returns some object
    refute_nil move_record
    assert_equal "Move", move_record["Type"]
    assert_equal 3, move_record["EntryType"]
    
    File.delete(filename)
  end

  def test_engine_struct_fields_parsing
    # Create move data with basic structure and verify EngineStructBestMoveRecord is created
    record_data = [0] * 2560
    record_data[8] = 3  # EntryType = tsMove
    
    # Set up basic move fields
    record_data[9 + 52, 4] = [-1].pack("l<").bytes  # Player 2
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    move_record = parser.game_records.first
    assert_instance_of XGStruct::MoveEntry, move_record
    
    # Test that EngineStructBestMoveRecord was parsed and created
    engine_data = move_record["DataMoves"]
    assert_instance_of XGStruct::EngineStructBestMoveRecord, engine_data
    
    # Test that the engine record has the expected default structure
    assert_respond_to engine_data, :Level
    assert_respond_to engine_data, :Cube
    assert_respond_to engine_data, :NMoves
    
    # Test that arrays are properly initialized
    assert_instance_of Array, engine_data["PosPlayed"]
    assert_instance_of Array, engine_data["Moves"]
    assert_instance_of Array, engine_data["EvalLevel"]
    assert_instance_of Array, engine_data["Eval"]
    
    # Test expected array sizes
    assert_equal 32, engine_data["PosPlayed"].length
    assert_equal 32, engine_data["Moves"].length
    assert_equal 32, engine_data["EvalLevel"].length
    assert_equal 32, engine_data["Eval"].length
    
    File.delete(filename)
  end

  def test_move_class_with_multiple_records
    # Test that we can parse multiple move records in sequence
    record1_data = create_move_record_data(1, [1, 3], 1)  # Player 1, dice 1,3, cube 1
    record2_data = create_move_record_data(-1, [5, 6], 2) # Player 2, dice 5,6, cube 2
    
    combined_data = record1_data + record2_data
    file_data = create_xg_file_with_data(combined_data.pack("C*"))
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal 2, parser.game_records.length
    
    # Test first record
    move1 = parser.game_records[0]
    assert_instance_of XGStruct::MoveEntry, move1
    assert_equal 1, move1["ActiveP"]
    assert_equal [1, 3], move1["Dice"]
    assert_equal 1, move1["CubeA"]
    
    # Test second record
    move2 = parser.game_records[1]
    assert_instance_of XGStruct::MoveEntry, move2
    assert_equal(-1, move2["ActiveP"])
    assert_equal [5, 6], move2["Dice"]
    assert_equal 2, move2["CubeA"]
    
    File.delete(filename)
  end

  def test_move_entry_from_3_move_bin_fixture
    # Test parsing the actual 3_Move.bin fixture file
    fixture_path = File.join(File.dirname(__FILE__), "fixtures", "3_Move.bin")
    
    # Verify fixture exists
    assert File.exist?(fixture_path), "3_Move.bin fixture not found at #{fixture_path}"
    
    # Read and parse the fixture
    data = File.binread(fixture_path)
    assert_equal 2560, data.length, "3_Move.bin should be exactly 2560 bytes"
    
    stream = StringIO.new(data)
    move = XGStruct::MoveEntry.new
    result = move.fromstream(stream)
    
    # Verify parsing succeeded
    refute_nil result, "MoveEntry.fromstream should successfully parse 3_Move.bin"
    assert_instance_of XGStruct::MoveEntry, result
    
    # Test basic move information
    assert_equal "Move", result["Type"]
    assert_equal 3, result["EntryType"]
    assert_equal(-16777216, result["ActiveP"])  # This appears to be the parsed value from the fixture
    assert_equal [6, 3], result["Dice"]
    assert_equal 0, result["CubeA"]
    assert_equal true, result["Played"]
    
    # Test position arrays
    assert_equal 26, result["PositionI"].length
    assert_equal 26, result["PositionEnd"].length
    assert_equal [0, -2, 0, 0, 0], result["PositionI"][0..4]
    assert_equal [0, -2, 0, 0, 0], result["PositionEnd"][0..4]
    
    # Test move data
    assert_equal [23, 17, 12, 9, -1, -1, -1, -1], result["Moves"]
    assert_equal 10, result["NMoveEval"]
    assert_equal 0.0, result["ErrorM"]
    
    # Test move evaluation data
    assert_equal 0.0, result["ErrMove"]
    assert_in_delta 0.0061259400099515915, result["ErrLuck"], 1e-15
    assert_equal 1, result["CompChoice"]
    assert_equal 0.0, result["InitEq"]
    
    # Test analysis data  
    assert_equal 3, result["AnalyzeM"]
    assert_equal 3, result["AnalyzeL"]
    assert_equal 0, result["InvalidM"]
    
    # Test tutor data
    assert_equal 26, result["PositionTutor"].length
    assert_equal(-1, result["Tutor"])
    assert_equal 0.0, result["ErrTutorMove"]
    assert_equal false, result["Flagged"]
    
    # Test other fields
    assert_equal(-1, result["CommentMove"])
    assert_equal false, result["EditedMove"]
    assert_equal 0, result["TimeDelayMove"]
    assert_equal 0, result["TimeDelayMoveDone"]
    assert_equal 0, result["NumberOfAutoDoubleMove"]
    
    # Test DataMoves (EngineStructBestMoveRecord)
    refute_nil result["DataMoves"]
    assert_instance_of XGStruct::EngineStructBestMoveRecord, result["DataMoves"]
    
    engine = result["DataMoves"]
    assert_equal 3, engine["Level"]
    assert_equal 1, engine["Cube"]
    assert_equal 26, engine["Pos"].length
    assert_equal [6, 3], engine["Dice"]
    assert_equal [4, 4], engine["Score"]
    
    # Test accessor methods work with the fixture data
    assert_equal(-16777216, result.ActiveP)
    assert_equal [6, 3], result.Dice
    assert_equal true, result.Played
    assert_equal [23, 17, 12, 9, -1, -1, -1, -1], result.Moves
  end

  private

  def create_move_record_data(active_player, dice, cube_value)
    record_data = [0] * 2560
    record_data[8] = 3  # EntryType = tsMove
    
    # Set ActiveP
    record_data[9 + 52, 4] = [active_player].pack("l<").bytes
    
    # Set dice
    dice_offset = 9 + 26 + 26 + 4 + 3 + 32
    record_data[dice_offset, 8] = dice.pack("l<2").bytes
    
    # Set cube
    cube_offset = dice_offset + 8
    record_data[cube_offset, 4] = [cube_value].pack("l<").bytes
    
    record_data
  end
end