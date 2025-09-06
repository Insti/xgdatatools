require_relative "test_helper"
require_relative "../xgimport"

class TestXGImport < Minitest::Test
  include TestHelper

  # Test Error class
  def test_error_initialization
    error = XGImport::Error.new("Test error", "test.xg")

    assert_equal "Test error", error.error
    assert_equal "test.xg", error.filename
    assert_equal "XG Import Error processing 'test.xg': Test error", error.value
    assert_equal "\"XG Import Error processing 'test.xg': Test error\"", error.message  # to_s calls value.inspect
  end

  def test_error_to_s
    error = XGImport::Error.new("Test error", "file.xg")

    assert_equal error.value.inspect, error.to_s
  end

  def test_error_inheritance
    error = XGImport::Error.new("Test", "file")

    assert error.is_a?(StandardError)
  end

  # Test Import::Segment class
  def test_segment_constants
    # Test segment type constants
    assert_equal 0, XGImport::Import::Segment::GDF_HDR
    assert_equal 1, XGImport::Import::Segment::GDF_IMAGE
    assert_equal 2, XGImport::Import::Segment::XG_GAMEHDR
    assert_equal 3, XGImport::Import::Segment::XG_GAMEFILE
    assert_equal 4, XGImport::Import::Segment::XG_ROLLOUTS
    assert_equal 5, XGImport::Import::Segment::XG_COMMENT
    assert_equal 6, XGImport::Import::Segment::ZLIBARC_IDX
    assert_equal 7, XGImport::Import::Segment::XG_UNKNOWN

    # Test extensions array
    expected_extensions = ["_gdh.bin", ".jpg", "_gamehdr.bin", "_gamefile.bin",
      "_rollouts.bin", "_comments.bin", "_idx.bin", nil]
    assert_equal expected_extensions, XGImport::Import::Segment::EXTENSIONS

    # Test individual extension constants
    assert_equal "_gdh.bin", XGImport::Import::Segment::GDF_HDR_EXT
    assert_equal ".jpg", XGImport::Import::Segment::GDF_IMAGE_EXT
    assert_equal "_gamehdr.bin", XGImport::Import::Segment::XG_GAMEHDR_EXT
    assert_equal "_gamefile.bin", XGImport::Import::Segment::XG_GAMEFILE_EXT
    assert_equal "_rollouts.bin", XGImport::Import::Segment::XG_ROLLOUTS_EXT
    assert_equal "_comments.bin", XGImport::Import::Segment::XG_COMMENTS_EXT
    assert_equal "_idx.bin", XGImport::Import::Segment::XG_IDX_EXT

    # Test file map
    expected_filemap = {
      "temp.xgi" => XGImport::Import::Segment::XG_GAMEHDR,
      "temp.xgr" => XGImport::Import::Segment::XG_ROLLOUTS,
      "temp.xgc" => XGImport::Import::Segment::XG_COMMENT,
      "temp.xg" => XGImport::Import::Segment::XG_GAMEFILE
    }
    assert_equal expected_filemap, XGImport::Import::Segment::XG_FILEMAP

    # Test other constants
    assert_equal 556, XGImport::Import::Segment::XG_GAMEHDR_LEN
    assert_equal "tmpXGI", XGImport::Import::Segment::TMP_PREFIX
  end

  def test_segment_initialization
    segment = XGImport::Import::Segment.new

    # Test default values
    assert_nil segment.filename
    assert_nil segment.fd
    assert_nil segment.file
    assert_equal XGImport::Import::Segment::GDF_HDR, segment.type
    assert_equal "_gdh.bin", segment.ext
  end

  def test_segment_initialization_with_params
    segment = XGImport::Import::Segment.new(
      type: XGImport::Import::Segment::XG_GAMEFILE,
      delete: false,
      prefix: "custom"
    )

    assert_equal XGImport::Import::Segment::XG_GAMEFILE, segment.type
    assert_equal "_gamefile.bin", segment.ext
  end

  def test_segment_createtempfile
    segment = XGImport::Import::Segment.new
    result = segment.createtempfile

    # Should return self
    assert_equal segment, result

    # Should have created temp file attributes
    refute_nil segment.filename
    refute_nil segment.fd
    refute_nil segment.file

    # File should exist
    assert File.exist?(segment.filename)

    # Clean up
    segment.closetempfile
  end

  def test_segment_createtempfile_with_mode
    segment = XGImport::Import::Segment.new
    segment.createtempfile("r+b")

    # Should have created file
    refute_nil segment.filename

    # Clean up
    segment.closetempfile
  end

  def test_segment_closetempfile
    segment = XGImport::Import::Segment.new
    segment.createtempfile

    filename = segment.filename
    assert File.exist?(filename)

    # Close temp file
    segment.closetempfile

    # File attributes should be nil
    assert_nil segment.fd
    assert_nil segment.file

    # File should be deleted (since autodelete defaults to true)
    refute File.exist?(filename)
  end

  def test_segment_closetempfile_no_autodelete
    segment = XGImport::Import::Segment.new(delete: false)
    segment.createtempfile

    filename = segment.filename
    assert File.exist?(filename)

    # Close temp file
    segment.closetempfile

    # File should still exist (autodelete is false)
    assert File.exist?(filename)

    # Manual cleanup
    File.unlink(filename) if File.exist?(filename)
  end

  def test_segment_closetempfile_already_closed
    segment = XGImport::Import::Segment.new
    segment.createtempfile

    # Close once
    segment.closetempfile

    # Should not raise error when closing again
    begin
      segment.closetempfile
      assert true  # If we get here, no exception was raised
    rescue => e
      flunk "Unexpected exception: #{e}"
    end
  end

  def test_segment_copyto
    segment = XGImport::Import::Segment.new
    segment.createtempfile

    # Write some test data
    segment.file.write("test data")
    segment.file.flush

    # Copy to destination
    dest_file = "/tmp/test_copyto_dest"
    segment.copyto(dest_file)

    # Destination should exist and have same content
    assert File.exist?(dest_file)
    assert_equal "test data", File.read(dest_file)

    # Clean up
    segment.closetempfile
    File.unlink(dest_file) if File.exist?(dest_file)
  end

  # Test Import class
  def test_import_initialization
    import = XGImport::Import.new("test.xg")

    assert_equal "test.xg", import.filename
  end

  def test_import_filename_accessor
    import = XGImport::Import.new("test.xg")

    # Test getter
    assert_equal "test.xg", import.filename

    # Test setter
    import.filename = "new.xg"
    assert_equal "new.xg", import.filename
  end

  def test_import_getfilesegment_nonexistent_file
    import = XGImport::Import.new("/nonexistent/file.xg")

    # Should raise error for nonexistent file
    assert_raises(Errno::ENOENT) do
      import.getfilesegment.to_a
    end
  end

  def test_import_getfilesegment_invalid_file
    # Create temp file with invalid data
    temp_file = create_temp_file("invalid xg data")

    import = XGImport::Import.new(temp_file.path)

    # Should raise XGImport::Error for invalid format
    assert_raises(XGImport::Error) do
      import.getfilesegment.to_a
    end

    temp_file.close
    temp_file.unlink
  end

  def test_import_getfilesegment_returns_enumerator
    # Test that getfilesegment returns an enumerator when no block given
    temp_file = create_temp_file("invalid data")

    import = XGImport::Import.new(temp_file.path)
    result = import.getfilesegment

    assert result.is_a?(Enumerator)

    temp_file.close
    temp_file.unlink
  end

  def test_import_getfilesegment_with_minimal_valid_data
    # Create temp file with minimal valid GDF header
    data = create_minimal_gdf_header
    temp_file = create_temp_file(data)

    import = XGImport::Import.new(temp_file.path)

    # This should raise an error when trying to create archive object
    # due to missing archive data, but we test that it tries to process the header
    assert_raises(Exception) do  # Could be IOError or other exception
      import.getfilesegment.to_a
    end

    temp_file.close
    temp_file.unlink
  end

  # Test module structure
  def test_module_exists
    assert defined?(XGImport)
    assert XGImport.is_a?(Module)
  end

  def test_all_classes_exist
    expected_classes = [:Error, :Import]

    expected_classes.each do |class_name|
      assert XGImport.const_defined?(class_name), "XGImport should define #{class_name}"
    end
  end

  def test_nested_segment_class_exists
    assert XGImport::Import.const_defined?(:Segment), "Import should define Segment class"
  end

  def test_error_class_inheritance
    assert XGImport::Error.new("test", "file").is_a?(StandardError)
  end

  def test_import_class_basic_structure
    import = XGImport::Import.new("test")

    # Should have filename attribute
    assert import.respond_to?(:filename)
    assert import.respond_to?(:filename=)

    # Should have getfilesegment method
    assert import.respond_to?(:getfilesegment)
  end

  def test_segment_class_attribute_accessors
    segment = XGImport::Import::Segment.new

    # Test all attribute accessors exist
    [:filename, :fd, :file, :type, :ext].each do |attr|
      assert segment.respond_to?(attr), "Segment should have #{attr} accessor"
      assert segment.respond_to?("#{attr}="), "Segment should have #{attr}= accessor"
    end
  end

  def test_segment_class_methods
    segment = XGImport::Import::Segment.new

    # Test all methods exist
    [:createtempfile, :closetempfile, :copyto].each do |method|
      assert segment.respond_to?(method), "Segment should have #{method} method"
    end
  end

  def test_segment_copyto_functionality
    # Test copyto method functionality
    segment = XGImport::Import::Segment.new
    segment.createtempfile
    
    # Write some test data
    test_data = "Test file content"
    segment.file.write(test_data)
    segment.file.flush

    # Create destination file path
    dest_path = "/tmp/test_copy_dest.txt"

    # Copy the file
    segment.copyto(dest_path)

    # Verify the copy was successful
    assert File.exist?(dest_path)
    assert_equal test_data, File.read(dest_path)

    # Cleanup
    segment.closetempfile
    File.unlink(dest_path) if File.exist?(dest_path)
  end

  def test_segment_closetempfile_with_autodelete_false
    # Test closetempfile with autodelete disabled
    segment = XGImport::Import::Segment.new(delete: false)
    segment.createtempfile
    
    filename = segment.filename
    
    # Write some data
    segment.file.write("test data")
    segment.file.flush

    # Close temp file
    segment.closetempfile

    # File should still exist since autodelete is false
    assert File.exist?(filename)

    # Cleanup manually
    File.unlink(filename) if File.exist?(filename)
  end

  def test_segment_closetempfile_when_already_closed
    # Test closetempfile when file is already closed
    segment = XGImport::Import::Segment.new
    segment.createtempfile
    
    # Close file manually first
    segment.file.close
    
    # Should handle already closed file gracefully
    begin
      segment.closetempfile
      # If no exception is raised, that's good
      assert true
    rescue => e
      flunk "Should handle already closed file gracefully, but raised: #{e}"
    end
  end

  def test_segment_initialization_with_different_types
    # Test initialization with different segment types
    types = [
      XGImport::Import::Segment::GDF_HDR,
      XGImport::Import::Segment::GDF_IMAGE,
      XGImport::Import::Segment::XG_GAMEHDR,
      XGImport::Import::Segment::XG_GAMEFILE,
      XGImport::Import::Segment::XG_ROLLOUTS,
      XGImport::Import::Segment::XG_COMMENT,
      XGImport::Import::Segment::ZLIBARC_IDX
    ]

    types.each do |type|
      segment = XGImport::Import::Segment.new(type: type)
      assert_equal type, segment.type
      assert_equal XGImport::Import::Segment::EXTENSIONS[type], segment.ext
    end
  end

  def test_segment_unknown_type
    # Test with unknown segment type (no extension)
    segment = XGImport::Import::Segment.new(type: XGImport::Import::Segment::XG_UNKNOWN)
    assert_equal XGImport::Import::Segment::XG_UNKNOWN, segment.type
    assert_nil segment.ext
  end

  def test_error_filename_accessor
    # Test that Error class properly stores and returns filename
    error = XGImport::Error.new("test error", "test_file.xg")
    assert_equal "test_file.xg", error.filename
  end

  def test_segment_initialization_edge_cases
    # Test initialization with edge case parameters
    segment = XGImport::Import::Segment.new(type: 99, delete: true, prefix: "custom_prefix")
    
    # Type outside normal range should still work
    assert_equal 99, segment.type
    # Extension should be nil for unknown types
    assert_nil segment.ext
  end

  def test_import_class_structure_validation
    # Test Import class structure and initialization
    import = XGImport::Import.new("test_filename.xg")
    assert_equal "test_filename.xg", import.filename
    
    # Test filename setter
    import.filename = "new_filename.xg" 
    assert_equal "new_filename.xg", import.filename
    
    # Test that getfilesegment method exists and returns enumerator
    enum = import.getfilesegment
    assert_kind_of Enumerator, enum
  end

  def test_segment_filemap_coverage
    # Test the XG_FILEMAP constant comprehensively
    filemap = XGImport::Import::Segment::XG_FILEMAP
    
    assert_equal XGImport::Import::Segment::XG_GAMEHDR, filemap["temp.xgi"]
    assert_equal XGImport::Import::Segment::XG_ROLLOUTS, filemap["temp.xgr"]
    assert_equal XGImport::Import::Segment::XG_COMMENT, filemap["temp.xgc"]
    assert_equal XGImport::Import::Segment::XG_GAMEFILE, filemap["temp.xg"]
    
    # Test that map is complete
    assert_equal 4, filemap.size
  end

  def test_segment_attribute_assignment
    # Test direct attribute assignment
    segment = XGImport::Import::Segment.new
    
    segment.filename = "/tmp/test.dat"
    assert_equal "/tmp/test.dat", segment.filename
    
    segment.type = XGImport::Import::Segment::XG_ROLLOUTS
    assert_equal XGImport::Import::Segment::XG_ROLLOUTS, segment.type
    
    segment.ext = ".custom"
    assert_equal ".custom", segment.ext
  end

  def test_module_and_class_constants_comprehensive
    # Test all module constants are defined correctly
    assert_equal 0, XGImport::Import::Segment::GDF_HDR
    assert_equal 1, XGImport::Import::Segment::GDF_IMAGE
    assert_equal 2, XGImport::Import::Segment::XG_GAMEHDR
    assert_equal 3, XGImport::Import::Segment::XG_GAMEFILE
    assert_equal 4, XGImport::Import::Segment::XG_ROLLOUTS
    assert_equal 5, XGImport::Import::Segment::XG_COMMENT
    assert_equal 6, XGImport::Import::Segment::ZLIBARC_IDX
    assert_equal 7, XGImport::Import::Segment::XG_UNKNOWN
    
    # Test extension constants
    assert_equal "_gdh.bin", XGImport::Import::Segment::GDF_HDR_EXT
    assert_equal ".jpg", XGImport::Import::Segment::GDF_IMAGE_EXT
    assert_equal "_gamehdr.bin", XGImport::Import::Segment::XG_GAMEHDR_EXT
    assert_equal "_gamefile.bin", XGImport::Import::Segment::XG_GAMEFILE_EXT
    assert_equal "_rollouts.bin", XGImport::Import::Segment::XG_ROLLOUTS_EXT
    assert_equal "_comments.bin", XGImport::Import::Segment::XG_COMMENTS_EXT
    assert_equal "_idx.bin", XGImport::Import::Segment::XG_IDX_EXT
    
    # Test numeric constants
    assert_equal 556, XGImport::Import::Segment::XG_GAMEHDR_LEN
    assert_equal "tmpXGI", XGImport::Import::Segment::TMP_PREFIX
  end

  private

  def create_minimal_gdf_header
    # Create minimal valid GDF header data
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

    # Set header size to the size of the record
    header_size = XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    data[8] = header_size & 0xFF
    data[9] = (header_size >> 8) & 0xFF
    data[10] = (header_size >> 16) & 0xFF
    data[11] = (header_size >> 24) & 0xFF

    # Set thumbnail offset and size to 0
    data[12] = 0  # ThumbnailOffset
    data[13] = 0
    data[14] = 0
    data[15] = 0
    data[16] = 0  # ThumbnailSize
    data[17] = 0
    data[18] = 0
    data[19] = 0

    data.pack("C*")
  end
end
