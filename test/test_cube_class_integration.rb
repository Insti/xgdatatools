require_relative "test_helper"
require_relative "../xgfile_parser"
require_relative "../xgstruct"

class TestCubeClassIntegration < Minitest::Test
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

  def test_cube_entry_from_2_cube_bin_fixture
    # Test parsing the actual 2_Cube.bin fixture file
    fixture_path = File.join(File.dirname(__FILE__), "fixtures", "2_Cube.bin")

    # Verify fixture exists
    assert File.exist?(fixture_path)

    # Read and parse the fixture
    data = File.binread(fixture_path)
    assert_equal 2560, data.length

    stream = StringIO.new(data)
    cube = XGStruct::CubeEntry.new
    result = cube.fromstream(stream)

    # Verify parsing succeeded
    refute_nil result
    assert_instance_of XGStruct::CubeEntry, result

    # Test basic cube information
    assert_equal "Cube", result["Type"]
    assert_equal 2, result["EntryType"]

    # Test core cube fields that were set in the fixture
    assert_equal(-1, result["ActiveP"])
    assert_equal(-2, result["Double"])
    assert_equal(-1, result["Take"])
    assert_equal(-1, result["BeaverR"])
    assert_equal(-1, result["RaccoonR"])
    assert_equal 0, result["CubeB"]

    # Test position array (26 elements for backgammon board)
    position = result["Position"]

    # Standard backgammon starting position
    starting_position = [0] * 26
    starting_position[24] = 2   # 2 checkers on point 24
    starting_position[13] = 5   # 5 checkers on point 13
    starting_position[8] = 3    # 3 checkers on point 8
    starting_position[6] = 5    # 5 checkers on point 6
    starting_position[1] = -2   # 2 checkers on point 1
    starting_position[12] = -5  # 5 checkers on point 12
    starting_position[17] = -3  # 3 checkers on point 17
    starting_position[19] = -5  # 5 checkers on point 19

    assert_equal starting_position, position, "Should be the backgammon starting position"

    # Test error fields
    assert_in_delta(-1000.0, result["ErrCube"], 0.001)
    assert_in_delta(-1000.0, result["ErrTake"], 0.001)
    assert_equal(-1000.0, result["ErrBeaver"])
    assert_equal(-1000.0, result["ErrRaccoon"])

    # Test dice rolled
    dice_rolled = result["DiceRolled"]
    refute_nil dice_rolled
    assert_kind_of String, dice_rolled
    assert_equal "63", dice_rolled

    # Test analysis fields
    assert_equal(-1, result["RolloutIndexD"])
    assert_equal 0, result["CompChoiceD"]
    assert_equal(-1, result["AnalyzeC"])
    assert_equal(-1, result["AnalyzeCR"])
    assert_equal 0, result["isValid"]

    # Test tutor fields
    assert_equal(-1, result["TutorCube"])
    assert_equal(-1, result["TutorTake"])
    assert_equal 0.0, result["ErrTutorCube"]
    assert_equal 0.0, result["ErrTutorTake"]

    # Test flag and version fields
    assert_equal false, result["FlaggedDouble"]
    assert_equal(-1, result["CommentCube"])
    assert_equal false, result["EditedCube"]
    assert_equal false, result["TimeDelayCube"]
    assert_equal false, result["TimeDelayCubeDone"]
    assert_equal 0, result["NumberOfAutoDoubleCube"]

    # Test timing fields
    assert_equal 0, result["TimeBot"]
    assert_equal 0, result["TimeTop"]

    # Test accessor methods work with the fixture data
    assert_equal(-1, result.ActiveP)
    assert_equal(-2, result.Double)
    assert_equal(-1, result.Take)
    assert_equal 0, result.CubeB
    assert_equal starting_position, result.Position
  end

  def test_cube_entry_from_2_cube_bin_via_xgfile_parser
    # Test parsing 2_Cube.bin through XGFileParser (simulating an XG file)
    fixture_path = File.join(File.dirname(__FILE__), "fixtures", "2_Cube.bin")
    cube_data = File.binread(fixture_path)

    # Create XG file with cube record
    record_data = [0] * 2560
    record_data[8] = 2  # EntryType = tsCube

    # Copy the cube data starting from offset 9 in XG format
    cube_bytes = cube_data[12..-1].bytes  # Convert to byte array first
    record_data[9, cube_bytes.length] = cube_bytes  # Copy byte data

    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)

    parser = XGFileParser::XGFile.new(filename)
    parser.parse

    assert_equal 1, parser.game_records.size
    record = parser.game_records.first

    # Verify XGFileParser correctly parses the cube data
    assert_equal "Cube", record["Type"]
    assert_equal 2, record["EntryType"]

    # Test that core fields are correctly parsed
    assert_equal(-1, record["ActiveP"])
    assert_equal(-2, record["Double"])
    assert_equal(-1, record["Take"])
    assert_equal 0, record["CubeB"]

    # Test backward compatibility field
    assert_equal(-1, record["Active"])

    # Verify position data is available
    position = record["Position"]
    refute_nil position
    assert_equal 26, position.length
  end

  def test_comprehensive_cube_field_validation
    # Additional test to validate that all possible cube field combinations work
    fixture_path = File.join(File.dirname(__FILE__), "fixtures", "2_Cube.bin")
    data = File.binread(fixture_path)

    stream = StringIO.new(data)
    cube = XGStruct::CubeEntry.new
    result = cube.fromstream(stream)

    # Test that all expected fields are present and have the correct types
    expected_fields = {
      "Name" => String,
      "Type" => String,
      "EntryType" => Integer,
      "ActiveP" => Integer,
      "Double" => Integer,
      "Take" => Integer,
      "BeaverR" => Integer,
      "RaccoonR" => Integer,
      "CubeB" => Integer,
      "Position" => Array,
      "ErrCube" => Float,
      "DiceRolled" => String,
      "ErrTake" => Float,
      "RolloutIndexD" => Integer,
      "CompChoiceD" => Integer,
      "AnalyzeC" => Integer,
      "ErrBeaver" => Float,
      "ErrRaccoon" => Float,
      "AnalyzeCR" => Integer,
      "isValid" => Integer,
      "TutorCube" => Integer,
      "TutorTake" => Integer,
      "ErrTutorCube" => Float,
      "ErrTutorTake" => Float,
      "CommentCube" => Integer,
      "NumberOfAutoDoubleCube" => Integer,
      "TimeBot" => Integer,
      "TimeTop" => Integer
    }

    expected_fields.each do |field_name, expected_type|
      assert result.key?(field_name), "Field #{field_name} should be present"
      actual_value = result[field_name]

      # Handle boolean fields specially since they can be TrueClass/FalseClass
      if field_name.include?("Flagged") || field_name.include?("Edited") || field_name.include?("Delay")
        assert [TrueClass, FalseClass].include?(actual_value.class),
          "Field #{field_name} should be boolean, got #{actual_value.class}"
      elsif expected_type == Array
        assert_kind_of Array, actual_value, "Field #{field_name} should be an Array"
      else
        assert_kind_of expected_type, actual_value,
          "Field #{field_name} should be #{expected_type}, got #{actual_value.class}"
      end
    end

    # Test that Position array has correct structure
    position = result["Position"]
    assert_equal 26, position.length
    position.each_with_index do |point_value, index|
      assert_kind_of Integer, point_value, "Position[#{index}] should be an integer"
      assert point_value.between?(-15, 15), "Position[#{index}] should be reasonable backgammon value"
    end
  end
end
