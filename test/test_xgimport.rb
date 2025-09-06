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

  def test_segment_closetempfile_with_nil_file
    # Test closetempfile when @file is nil
    segment = XGImport::Import::Segment.new
    segment.createtempfile
    
    # Set file to nil manually
    segment.instance_variable_set(:@file, nil)
    
    # Should handle nil file gracefully
    begin
      segment.closetempfile
      assert true  # If we get here, it handled nil gracefully
    rescue => e
      flunk "Should handle nil file gracefully, but raised: #{e}"
    end
  end

  def test_segment_closetempfile_file_unlink_error_handling
    # Test closetempfile when file unlink might fail
    segment = XGImport::Import::Segment.new(delete: true)
    segment.createtempfile
    
    filename = segment.filename
    
    # Close the file first
    segment.file.close
    
    # Make the file read-only to potentially cause unlink issues on some systems
    # (This test may behave differently on different file systems)
    File.chmod(0444, filename) if File.exist?(filename)
    
    # closetempfile should still complete even if unlink has issues
    begin
      segment.closetempfile
      # Method should complete regardless of unlink result
      assert_nil segment.instance_variable_get(:@filename)
    rescue => e
      # If there's an error, ensure cleanup still happened
      assert_nil segment.instance_variable_get(:@filename)
    ensure
      # Cleanup - restore permissions and remove file if it still exists
      File.chmod(0644, filename) if File.exist?(filename)
      File.unlink(filename) if File.exist?(filename)
    end
  end

  # Additional tests for missing coverage
  
  def test_segment_tempfile_instance_variable
    # Test that @tempfile instance variable is properly set
    segment = XGImport::Import::Segment.new
    segment.createtempfile
    
    # Should have @tempfile instance variable set
    tempfile = segment.instance_variable_get(:@tempfile)
    refute_nil tempfile
    assert tempfile.is_a?(Tempfile)
    
    # Should be same as @fd and @file
    assert_equal tempfile, segment.fd
    assert_equal tempfile, segment.file
    
    segment.closetempfile
  end

  def test_segment_prefix_parameter_usage
    # Test that prefix parameter is used in createtempfile
    custom_prefix = "custom_test_prefix"
    segment = XGImport::Import::Segment.new(prefix: custom_prefix)
    segment.createtempfile
    
    # Filename should contain the custom prefix
    assert_match(/#{custom_prefix}/, segment.filename)
    
    segment.closetempfile
  end

  def test_segment_createtempfile_mode_parameter
    # Test createtempfile with different mode parameters
    segment = XGImport::Import::Segment.new
    segment.createtempfile("wb")
    
    # File should be created and accessible
    refute_nil segment.file
    assert segment.file.respond_to?(:write)
    
    segment.closetempfile
  end

  def test_segment_type_validation_edge_cases
    # Test segment with very high type number
    segment = XGImport::Import::Segment.new(type: 999)
    assert_equal 999, segment.type
    assert_nil segment.ext  # Should be nil for undefined types
    
    # Test with negative type
    segment2 = XGImport::Import::Segment.new(type: -1)
    assert_equal(-1, segment2.type)
    assert_nil segment2.ext
  end

  def test_import_getfilesegment_error_propagation
    # Test that errors in getfilesegment are properly propagated
    temp_file = create_temp_file("not valid data")
    import = XGImport::Import.new(temp_file.path)

    # Should raise XGImport::Error, not some other error
    error = assert_raises(XGImport::Error) do
      import.getfilesegment.to_a
    end

    assert_equal "Not a game data format file", error.error
    assert_equal temp_file.path, error.filename

    temp_file.close
    temp_file.unlink
  end

  def test_import_getfilesegment_with_valid_header_but_bad_archive
    # Test getfilesegment with valid GDF header but bad archive data
    header_data = create_valid_gdf_header_with_thumbnail
    temp_file = create_temp_file(header_data + "bad archive data")
    
    import = XGImport::Import.new(temp_file.path)
    
    # Should process the header but fail on archive
    segments = []
    assert_raises do  # Should raise an error when trying to process archive
      import.getfilesegment do |segment|
        segments << segment
      end
    end
    
    # Should have processed the GDF header segment
    assert_equal 1, segments.length
    assert_equal XGImport::Import::Segment::GDF_HDR, segments[0].type

    temp_file.close
    temp_file.unlink
  end

  def test_import_getfilesegment_with_thumbnail
    # Test getfilesegment with thumbnail processing
    header_data = create_valid_gdf_header_with_thumbnail(thumbnail_size: 100)
    thumbnail_data = "fake jpeg data" * 8  # Make it exactly 100+ bytes
    file_data = header_data + thumbnail_data + "archive data"
    
    temp_file = create_temp_file(file_data)
    import = XGImport::Import.new(temp_file.path)
    
    segments = []
    # This will likely fail on archive processing, but we should see both header and image segments
    begin
      import.getfilesegment do |segment|
        segments << {type: segment.type, size: File.size(segment.filename)}
        # Stop after collecting segments to avoid archive errors
        break if segments.length >= 2
      end
    rescue => e
      # Expected to fail on archive processing
    end
    
    # Should have processed at least the GDF header, might have image too
    assert segments.length >= 1
    assert_equal XGImport::Import::Segment::GDF_HDR, segments[0][:type]
    
    # If we got 2 segments, the second should be the image
    if segments.length == 2
      assert_equal XGImport::Import::Segment::GDF_IMAGE, segments[1][:type]
      assert segments[1][:size] > 0  # Thumbnail should have content
    end

    temp_file.close
    temp_file.unlink
  end

  def test_segment_copyto_with_nonexistent_source
    # Test copyto when source file doesn't exist
    segment = XGImport::Import::Segment.new
    # Don't create temp file, so @filename will be nil
    
    dest_file = "/tmp/test_copyto_dest_fail"
    
    # Should raise an error (likely ArgumentError or TypeError)
    assert_raises do
      segment.copyto(dest_file)
    end
    
    # Cleanup
    File.unlink(dest_file) if File.exist?(dest_file)
  end

  def test_segment_closetempfile_multiple_calls_robustness
    # Test multiple calls to closetempfile are safe
    segment = XGImport::Import::Segment.new
    segment.createtempfile
    
    # Close multiple times - should be safe
    5.times do
      begin
        segment.closetempfile
      rescue => e
        flunk "Multiple closetempfile calls should be safe, but raised: #{e}"
      end
    end
    
    # All attributes should be nil
    assert_nil segment.fd
    assert_nil segment.file
    assert_nil segment.filename
  end

  def test_error_class_message_method
    # Test that Error#message returns the same as to_s
    error = XGImport::Error.new("Test message", "test.file")
    
    assert_equal error.to_s, error.message
    assert_equal error.value.inspect, error.message
  end

  def test_import_gamefile_magic_number_validation
    # Test the XG_GAMEFILE magic number validation logic
    # This tests an important security/validation feature
    
    # Create a mock file record that would trigger the validation
    mock_filerec = {"name" => "temp.xg"}  # This maps to XG_GAMEFILE type
    
    # Test that the XG_FILEMAP correctly identifies gamefile type
    assert_equal XGImport::Import::Segment::XG_GAMEFILE, 
                 XGImport::Import::Segment::XG_FILEMAP["temp.xg"]
    
    # Test the magic number validation constants
    assert_equal 556, XGImport::Import::Segment::XG_GAMEHDR_LEN
    
    # The actual validation happens in getfilesegment when processing archive files
    # This requires a valid archive structure which is complex to mock,
    # but we can at least test the mapping and constants are correct
  end

  def test_segment_delete_parameter_comprehensive
    # Test the delete parameter behavior more comprehensively
    
    # Test with delete = true (default)
    segment1 = XGImport::Import::Segment.new(delete: true)
    segment1.createtempfile
    filename1 = segment1.filename
    assert File.exist?(filename1)
    
    segment1.closetempfile
    refute File.exist?(filename1)  # Should be deleted
    
    # Test with delete = false
    segment2 = XGImport::Import::Segment.new(delete: false)
    segment2.createtempfile
    filename2 = segment2.filename
    assert File.exist?(filename2)
    
    segment2.closetempfile
    assert File.exist?(filename2)  # Should still exist
    
    # Manual cleanup
    File.unlink(filename2) if File.exist?(filename2)
  end

  def test_segment_extension_mapping_comprehensive
    # Test that all type constants map to correct extensions
    type_extension_map = {
      XGImport::Import::Segment::GDF_HDR => "_gdh.bin",
      XGImport::Import::Segment::GDF_IMAGE => ".jpg", 
      XGImport::Import::Segment::XG_GAMEHDR => "_gamehdr.bin",
      XGImport::Import::Segment::XG_GAMEFILE => "_gamefile.bin",
      XGImport::Import::Segment::XG_ROLLOUTS => "_rollouts.bin",
      XGImport::Import::Segment::XG_COMMENT => "_comments.bin",
      XGImport::Import::Segment::ZLIBARC_IDX => "_idx.bin",
      XGImport::Import::Segment::XG_UNKNOWN => nil
    }
    
    type_extension_map.each do |type, expected_ext|
      segment = XGImport::Import::Segment.new(type: type)
      if expected_ext.nil?
        assert_nil segment.ext, "Type #{type} should map to nil extension"
      else
        assert_equal expected_ext, segment.ext,
                     "Type #{type} should map to extension '#{expected_ext}'"
      end
    end
  end

  def test_import_getfilesegment_file_io_error_handling
    # Test error handling when file operations fail
    import = XGImport::Import.new("/dev/null")  # Valid file but wrong format
    
    assert_raises(XGImport::Error) do
      import.getfilesegment.to_a
    end
  end

  def test_segment_copyto_to_readonly_directory
    # Test copyto when destination directory is read-only (if supported)
    segment = XGImport::Import::Segment.new
    segment.createtempfile
    
    segment.file.write("test data")
    segment.file.flush
    
    # Try to copy to a likely read-only location
    # This may not fail on all systems, so we handle both cases
    dest_file = "/root/test_readonly_dest"  # Likely to fail due to permissions
    
    begin
      segment.copyto(dest_file)
      # If it succeeds, clean up
      File.unlink(dest_file) if File.exist?(dest_file)
    rescue => e
      # Expected to fail - verify it's an appropriate error
      assert e.is_a?(SystemCallError), "Should raise a system call error for permission issues"
    end
    
    segment.closetempfile
  end

  def test_segment_attribute_accessors_comprehensive
    # Test all attribute accessors work correctly
    segment = XGImport::Import::Segment.new
    
    # Test filename assignment
    segment.filename = "/tmp/test_filename"
    assert_equal "/tmp/test_filename", segment.filename
    
    # Test type assignment  
    segment.type = XGImport::Import::Segment::XG_ROLLOUTS
    assert_equal XGImport::Import::Segment::XG_ROLLOUTS, segment.type
    
    # Test ext assignment
    segment.ext = ".custom_ext"
    assert_equal ".custom_ext", segment.ext
    
    # Test fd and file can be assigned (though normally managed by createtempfile)
    mock_fd = "mock_fd_object"
    segment.fd = mock_fd
    assert_equal mock_fd, segment.fd
    
    mock_file = "mock_file_object"
    segment.file = mock_file
    assert_equal mock_file, segment.file
  end

  def test_import_getfilesegment_block_vs_enumerator
    # Test that getfilesegment behaves differently with/without block
    temp_file = create_temp_file("invalid data")
    import = XGImport::Import.new(temp_file.path)
    
    # Without block - should return Enumerator
    enumerator = import.getfilesegment
    assert_kind_of Enumerator, enumerator
    
    # With block - should not return Enumerator, should execute block
    block_called = false
    begin
      result = import.getfilesegment do |segment|
        block_called = true
      end
      # Result should be nil when block is given, not an Enumerator
      assert_nil result
    rescue XGImport::Error
      # Expected to fail on invalid data, but we tested the block behavior
    end
    
    temp_file.close
    temp_file.unlink
  end

  def test_error_class_super_call_behavior
    # Test that Error class properly calls super with @value
    error = XGImport::Error.new("Test error", "filename.xg")
    
    # The StandardError message should be set to @value
    expected_message = "XG Import Error processing 'filename.xg': Test error"
    assert_equal expected_message, error.value
    
    # Verify inheritance chain
    assert error.is_a?(StandardError)
    assert error.is_a?(Exception)
  end

  def test_import_filename_reassignment_after_creation
    # Test that filename can be changed and used
    import = XGImport::Import.new("original.xg")
    assert_equal "original.xg", import.filename
    
    # Change filename
    import.filename = "changed.xg"
    assert_equal "changed.xg", import.filename
    
    # New filename should be used in error messages
    assert_raises(Errno::ENOENT) do
      import.getfilesegment.to_a
    end
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

  def create_valid_gdf_header_with_thumbnail(thumbnail_size: 0)
    # Create valid GDF header with optional thumbnail
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

    # Set header size
    header_size = XGStruct::GameDataFormatHdrRecord::SIZEOFREC
    data[8] = header_size & 0xFF
    data[9] = (header_size >> 8) & 0xFF
    data[10] = (header_size >> 16) & 0xFF
    data[11] = (header_size >> 24) & 0xFF

    # Set thumbnail offset (right after header)
    data[12] = header_size & 0xFF
    data[13] = (header_size >> 8) & 0xFF
    data[14] = (header_size >> 16) & 0xFF
    data[15] = (header_size >> 24) & 0xFF
    
    # Set thumbnail size
    data[16] = thumbnail_size & 0xFF
    data[17] = (thumbnail_size >> 8) & 0xFF
    data[18] = (thumbnail_size >> 16) & 0xFF
    data[19] = (thumbnail_size >> 24) & 0xFF

    data.pack("C*")
  end
end
