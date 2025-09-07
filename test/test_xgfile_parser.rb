require "minitest/autorun"
require "stringio"
require "tempfile"
require "fileutils"
require_relative "../xgfile_parser"

class TestXGFileParser < Minitest::Test
  def setup
    @temp_files = []
  end
  
  def teardown
    @temp_files.each { |f| f.close! if f.respond_to?(:close!) }
  end
  
  # Helper to create temporary XG file with given data
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
  
  def test_xgfile_initialization
    parser = XGFileParser::XGFile.new("test.xg")
    assert_equal "test.xg", parser.filename
    assert_nil parser.header
    assert_nil parser.thumbnail_data
    assert_equal [], parser.game_records
  end
  
  def test_parse_file_not_found
    parser = XGFileParser::XGFile.new("nonexistent.xg")
    
    assert_raises(Errno::ENOENT) do
      parser.parse
    end
  end
  
  def test_parse_file_too_small
    # Create file smaller than header size
    small_data = [1, 2, 3, 4, 5]
    filename = create_temp_xg_file(small_data)
    
    parser = XGFileParser::XGFile.new(filename)
    
    error = assert_raises(XGFileParser::Error) do
      parser.parse
    end
    
    assert_equal :file_too_small, error.code
    assert_match /File too small/, error.message
  end
  
  def test_parse_invalid_magic_number
    # Create file with wrong magic number
    header = create_minimal_xg_header
    header[0..3] = [0x11, 0x22, 0x33, 0x44]  # Wrong magic
    
    filename = create_temp_xg_file(header)
    parser = XGFileParser::XGFile.new(filename)
    
    error = assert_raises(XGFileParser::Error) do
      parser.parse
    end
    
    assert_equal :invalid_magic, error.code
    assert_match /Invalid magic number/, error.message
  end
  
  def test_parse_invalid_header_size
    # Create file with wrong header size
    header = create_minimal_xg_header
    header[8..11] = [0xFF, 0xFF, 0, 0]  # Wrong size
    
    filename = create_temp_xg_file(header)
    parser = XGFileParser::XGFile.new(filename)
    
    error = assert_raises(XGFileParser::Error) do
      parser.parse
    end
    
    assert_equal :invalid_header_size, error.code
    assert_match /Invalid header size/, error.message
  end
  
  def test_parse_valid_minimal_file
    # Create minimal valid XG file
    file_data = create_xg_file_with_data("")
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    result = parser.parse
    
    assert_same parser, result
    refute_nil parser.header
    assert_equal XGFileParser::XGFile::XG_MAGIC_NUMBER, parser.header["MagicNumber"]
    assert_equal 1, parser.header["HeaderVersion"]
    assert_equal XGFileParser::XGFile::RICH_GAME_HEADER_SIZE, parser.header["HeaderSize"]
    assert_equal 0, parser.header["ThumbnailOffset"]
    assert_equal 0, parser.header["ThumbnailSize"]
  end
  
  def test_parse_header_with_unicode_strings
    header = create_minimal_xg_header
    
    # Add test Unicode strings (UTF-16LE)
    game_name = "Test Game\0".encode("UTF-16LE").bytes
    save_name = "Test Save\0".encode("UTF-16LE").bytes
    
    # Place strings at correct offsets (36, 36+2048, 36+4096, 36+6144)
    header[36, game_name.size] = game_name if game_name.size <= 2048
    header[36 + 2048, save_name.size] = save_name if save_name.size <= 2048
    
    file_data = header + Zlib::Deflate.deflate("").bytes
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal "Test Game", parser.header["GameName"]
    assert_equal "Test Save", parser.header["SaveName"]
  end
  
  def test_parse_with_thumbnail
    header = create_minimal_xg_header
    
    # Set thumbnail offset and size
    thumbnail_offset = XGFileParser::XGFile::RICH_GAME_HEADER_SIZE
    thumbnail_size = 10
    
    # Update header with thumbnail info (little-endian)
    header[12..19] = [thumbnail_offset].pack("Q<").bytes
    header[20..23] = [thumbnail_size].pack("L<").bytes
    
    # Create fake JPEG thumbnail (starts with 0xFF 0xD8)
    thumbnail_data = [0xFF, 0xD8, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
    
    # Create compressed payload
    compressed_data = Zlib::Deflate.deflate("")
    
    file_data = header + thumbnail_data + compressed_data.bytes
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal thumbnail_offset, parser.header["ThumbnailOffset"]
    assert_equal thumbnail_size, parser.header["ThumbnailSize"]
    assert_equal thumbnail_data, parser.thumbnail_data.bytes
  end
  
  def test_parse_with_invalid_thumbnail
    header = create_minimal_xg_header
    
    # Set thumbnail offset and size
    thumbnail_offset = XGFileParser::XGFile::RICH_GAME_HEADER_SIZE
    thumbnail_size = 10
    
    header[12..19] = [thumbnail_offset].pack("Q<").bytes
    header[20..23] = [thumbnail_size].pack("L<").bytes
    
    # Create invalid thumbnail (doesn't start with JPEG magic)
    thumbnail_data = [0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
    
    file_data = header + thumbnail_data + Zlib::Deflate.deflate("").bytes
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    # Invalid JPEG should result in nil thumbnail_data
    assert_nil parser.thumbnail_data
  end
  
  def test_parse_with_game_records
    # Create a simple game record (2560 bytes)
    record_data = [0] * 2560
    
    # Set record type (9th byte) to HeaderMatch (0)
    record_data[8] = 0
    
    # Add some Pascal strings for Player1 and Player2
    # Player1 at offset 9: length + string
    player1 = "Alice"
    record_data[9] = player1.length
    record_data[10, player1.length] = player1.bytes
    
    # Player2 at offset 9 + 41: length + string
    player2 = "Bob"
    record_data[9 + 41] = player2.length
    record_data[10 + 41, player2.length] = player2.bytes
    
    # MatchLength at offset 9 + 82 (little-endian integer)
    match_length = 7
    record_data[9 + 82, 4] = [match_length].pack("l<").bytes
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal 1, parser.game_records.size
    record = parser.game_records.first
    
    assert_equal 0, record["EntryType"]
    assert_equal "HeaderMatch", record["Type"]
    assert_equal "Alice", record["Player1"]
    assert_equal "Bob", record["Player2"]
    assert_equal match_length, record["MatchLength"]
  end
  
  def test_parse_multiple_game_records
    # Create two different record types
    record1 = [0] * 2560
    record1[8] = 0  # HeaderMatch
    
    record2 = [0] * 2560  
    record2[8] = 1  # HeaderGame
    record2[9, 4] = [10].pack("l<").bytes   # Score1
    record2[13, 4] = [5].pack("l<").bytes   # Score2
    
    game_data = (record1 + record2).pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal 2, parser.game_records.size
    
    # Check first record
    assert_equal "HeaderMatch", parser.game_records[0]["Type"]
    
    # Check second record  
    assert_equal "HeaderGame", parser.game_records[1]["Type"]
    assert_equal 10, parser.game_records[1]["Score1"]
    assert_equal 5, parser.game_records[1]["Score2"]
  end
  
  def test_parse_unknown_record_type
    record_data = [0] * 2560
    record_data[8] = 99  # Unknown record type
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    assert_equal 1, parser.game_records.size
    record = parser.game_records.first
    
    assert_equal 99, record["EntryType"]
    refute_nil record["RawData"]  # Should contain hex data
  end
  
  def test_parse_corrupted_compression
    header = create_minimal_xg_header
    # Add invalid compressed data
    bad_compressed_data = [1, 2, 3, 4, 5]
    
    file_data = header + bad_compressed_data
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    
    error = assert_raises(XGFileParser::Error) do
      parser.parse
    end
    
    assert_equal :decompression_failed, error.code
    assert_match /Failed to decompress/, error.message
    assert_kind_of Zlib::Error, error.details
  end
  
  def test_parse_cube_record
    record_data = [0] * 2560
    record_data[8] = 2  # Cube record
    record_data[9, 4] = [1].pack("l<").bytes    # Active = 1
    record_data[13, 4] = [1].pack("l<").bytes   # Double = 1
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    record = parser.game_records.first
    assert_equal "Cube", record["Type"]
    assert_equal 1, record["Active"]
    assert_equal 1, record["Double"]
  end
  
  def test_parse_move_record
    record_data = [0] * 2560
    record_data[8] = 3  # Move record
    record_data[9 + 52, 4] = [-1].pack("l<").bytes  # ActivePlayer = -1
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    record = parser.game_records.first
    assert_equal "Move", record["Type"]
    assert_equal(-1, record["ActivePlayer"])
  end
  
  def test_parse_footer_game_record
    record_data = [0] * 2560
    record_data[8] = 4  # FooterGame record
    record_data[9, 4] = [15].pack("l<").bytes   # Score1
    record_data[13, 4] = [7].pack("l<").bytes   # Score2
    record_data[18, 4] = [1].pack("l<").bytes   # Winner
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    record = parser.game_records.first
    assert_equal "FooterGame", record["Type"]
    assert_equal 15, record["Score1"]
    assert_equal 7, record["Score2"]
    assert_equal 1, record["Winner"]
  end
  
  def test_parse_footer_match_record
    record_data = [0] * 2560
    record_data[8] = 5  # FooterMatch record
    record_data[9, 4] = [7].pack("l<").bytes    # Score1
    record_data[13, 4] = [5].pack("l<").bytes   # Score2
    record_data[17, 4] = [1].pack("l<").bytes   # Winner
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    record = parser.game_records.first
    assert_equal "FooterMatch", record["Type"]
    assert_equal 7, record["Score1"]
    assert_equal 5, record["Score2"]
    assert_equal 1, record["Winner"]
  end
  
  def test_extract_pascal_string_empty
    parser = XGFileParser::XGFile.new("dummy")
    data = [0, 65, 66, 67].pack("C*")  # Length 0, followed by ABC
    
    result = parser.send(:extract_pascal_string, data, 0, 10)
    assert_equal "", result
  end
  
  def test_extract_pascal_string_normal
    parser = XGFileParser::XGFile.new("dummy")
    data = [3, 65, 66, 67, 0].pack("C*")  # Length 3, "ABC", null
    
    result = parser.send(:extract_pascal_string, data, 0, 10)
    assert_equal "ABC", result
  end
  
  def test_extract_pascal_string_truncated
    parser = XGFileParser::XGFile.new("dummy")
    data = [5, 65, 66, 67].pack("C*")  # Length 5, but only "AB" available
    
    result = parser.send(:extract_pascal_string, data, 0, 10)
    assert_equal "ABC", result
  end
  
  def test_error_class
    error = XGFileParser::Error.new("Test message", code: :test_code, details: "test details")
    
    assert_equal "Test message", error.message
    assert_equal :test_code, error.code
    assert_equal "test details", error.details
  end
  
  def test_cube_record_with_large_cube_value
    # Test that large CubeB values don't cause issues when displaying
    record_data = [0] * 2560
    record_data[8] = 2  # Cube record
    record_data[9, 4] = [1].pack("l<").bytes    # ActiveP = 1
    record_data[13, 4] = [1].pack("l<").bytes   # Double = 1
    record_data[17, 4] = [1].pack("l<").bytes   # Take = 1
    record_data[29, 4] = [900].pack("l<").bytes # CubeB = 900 (very large)
    
    game_data = record_data.pack("C*")
    file_data = create_xg_file_with_data(game_data)
    filename = create_temp_xg_file(file_data)
    
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    record = parser.game_records.first
    assert_equal "Cube", record["Type"]
    assert_equal 1, record["ActiveP"]
    assert_equal 1, record["Double"]
    assert_equal 1, record["Take"]
    assert_equal 900, record["CubeB"]
    
    # This large value should be handled gracefully in display logic
    # The value 2^900 would have hundreds of digits - this is the issue we need to fix
  end
end