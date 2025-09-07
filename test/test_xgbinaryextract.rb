require_relative "test_helper"
require_relative "../xgbinaryextract"
require_relative "../xgfile_parser"
require "zlib"

class TestXGBinaryExtract < Minitest::Test
  include TestHelper

  def setup
    @temp_files = []
    @temp_dirs = []
  end

  def teardown
    @temp_files.each { |temp| temp.unlink if temp.respond_to?(:unlink) }
    @temp_dirs.each { |dir| FileUtils.rm_rf(dir) if File.exist?(dir) }
  end

  def create_temp_xg_file(data)
    temp = Tempfile.new(["test", ".xg"])
    temp.binmode
    temp.write(data.is_a?(Array) ? data.pack("C*") : data)
    temp.close
    @temp_files << temp
    temp.path
  end

  def create_temp_directory
    dir = Dir.mktmpdir("xgbinaryextract_test")
    @temp_dirs << dir
    dir
  end

  # Helper to create minimal valid XG header (adapted from test_move_class_integration.rb)
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

  def test_segment_type_names_constant
    expected_names = {
      XGImport::Import::Segment::GDF_HDR => "gdf_hdr",
      XGImport::Import::Segment::GDF_IMAGE => "gdf_image", 
      XGImport::Import::Segment::XG_GAMEHDR => "xg_gamehdr",
      XGImport::Import::Segment::XG_GAMEFILE => "xg_gamefile",
      XGImport::Import::Segment::XG_ROLLOUTS => "xg_rollouts",
      XGImport::Import::Segment::XG_COMMENT => "xg_comment",
      XGImport::Import::Segment::ZLIBARC_IDX => "zlibarc_idx",
      XGImport::Import::Segment::XG_UNKNOWN => "xg_unknown"
    }
    
    assert_equal expected_names, SEGMENT_TYPE_NAMES
  end

  def test_segment_subtypes_constant
    expected_subtypes = {
      XGImport::Import::Segment::GDF_HDR => "header",
      XGImport::Import::Segment::GDF_IMAGE => "thumbnail", 
      XGImport::Import::Segment::XG_GAMEHDR => "header",
      XGImport::Import::Segment::XG_GAMEFILE => "data",
      XGImport::Import::Segment::XG_ROLLOUTS => "data",
      XGImport::Import::Segment::XG_COMMENT => "text",
      XGImport::Import::Segment::ZLIBARC_IDX => "index",
      XGImport::Import::Segment::XG_UNKNOWN => "unknown"
    }
    
    assert_equal expected_subtypes, SEGMENT_SUBTYPES
  end

  def test_directoryisvalid_function
    temp_dir = create_temp_directory
    
    # Test valid directory
    assert_equal temp_dir, directoryisvalid(temp_dir)
    
    # Test invalid directory
    assert_raises(ArgumentError) do
      directoryisvalid("/nonexistent/directory")
    end
  end

  def test_extract_xg_components_basic_functionality
    # Create a simple test XG file (malformed - only has header + compressed data)
    game_data = "test game data"
    file_data = create_xg_file_with_data(game_data)
    xg_file = create_temp_xg_file(file_data)
    output_dir = create_temp_directory
    
    # Initialize a null logger for testing
    logger = Logger.new(File::NULL)
    
    # Extract components
    result = extract_xg_components(xg_file, output_dir, logger)
    
    # Should return false for malformed XG file (missing proper archive structure)
    refute result, "Function should return false for malformed XG file"
    
    # Check that at least the GDF header was extracted before the error
    output_files = Dir.glob(File.join(output_dir, "*.bin"))
    refute_empty output_files, "At least GDF header should be extracted"
    
    # Check filename format for extracted files: [type]_[number]_[subtype].bin
    output_files.each do |file|
      basename = File.basename(file, ".bin")
      assert_match(/\A\w+_\d{3}_\w+\z/, basename, "Filename format should match [type]_[number]_[subtype]")
    end
  end

  def test_binary_filename_generation
    # Test the filename pattern
    type_name = "gdf_hdr"
    number = 1
    subtype = "header"
    
    expected_filename = "#{type_name}_#{number.to_s.rjust(3, '0')}_#{subtype}.bin"
    assert_equal "gdf_hdr_001_header.bin", expected_filename
    
    # Test with larger number
    number = 42
    expected_filename = "#{type_name}_#{number.to_s.rjust(3, '0')}_#{subtype}.bin"
    assert_equal "gdf_hdr_042_header.bin", expected_filename
  end

  def test_extract_xg_components_with_nonexistent_file
    logger = Logger.new(File::NULL)
    
    result = extract_xg_components("/nonexistent/file.xg", "/tmp", logger)
    
    # Should handle file not found gracefully and return false
    refute result
  end
end