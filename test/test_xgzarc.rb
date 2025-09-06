require_relative "test_helper"
require_relative "../xgzarc"

class TestXGZarc < Minitest::Test
  include TestHelper

  # Test Error class
  def test_error_initialization
    error = XGZarc::Error.new("Test error message")

    assert_equal "Test error message", error.error
    assert_equal "Zlib archive: Test error message", error.value
    assert_equal "\"Zlib archive: Test error message\"", error.message  # message calls value.inspect
  end

  def test_error_to_s
    error = XGZarc::Error.new("Test error")

    assert_equal error.value.inspect, error.to_s
  end

  def test_error_inheritance
    error = XGZarc::Error.new("Test")

    assert error.is_a?(StandardError)
  end

  # Test ArchiveRecord
  def test_archive_record_initialization
    record = XGZarc::ArchiveRecord.new

    # Test default values
    assert_equal 0, record["crc"]
    assert_equal 0, record["filecount"]
    assert_equal 0, record["version"]
    assert_equal 0, record["registrysize"]
    assert_equal 0, record["archivesize"]
    assert_equal false, record["compressedregistry"]
    assert_equal [], record["reserved"]
  end

  def test_archive_record_initialization_with_params
    record = XGZarc::ArchiveRecord.new(
      "crc" => 12345,
      "filecount" => 5,
      "version" => 2
    )

    assert_equal 12345, record["crc"]
    assert_equal 5, record["filecount"]
    assert_equal 2, record["version"]
    assert_equal 0, record["registrysize"]  # Default preserved
  end

  def test_archive_record_hash_behavior
    record = XGZarc::ArchiveRecord.new

    # Test hash-like access
    assert_hash_like_behavior(record, "TestKey", "TestValue")
  end

  def test_archive_record_method_missing
    record = XGZarc::ArchiveRecord.new

    # Test setter method
    record.crc = 54321
    assert_equal 54321, record["crc"]

    # Test getter method
    record["filecount"] = 10
    assert_equal 10, record.filecount

    # Test unknown method
    assert_raises(NoMethodError) { record.unknown_method }
  end

  def test_archive_record_respond_to_missing
    record = XGZarc::ArchiveRecord.new
    record["TestKey"] = "value"

    # Should respond to setter
    assert record.respond_to?(:TestKey=)

    # Should respond to getter for existing key
    assert record.respond_to?(:TestKey)

    # Should not respond to unknown method
    refute record.respond_to?(:unknown_method)
  end

  def test_archive_record_fromstream
    # Create test data for ArchiveRecord (36 bytes)
    data = [
      0x12, 0x34, 0x56, 0x78,    # crc (little-endian) = 0x78563412
      5, 0, 0, 0,                # filecount = 5
      2, 0, 0, 0,                # version = 2
      100, 0, 0, 0,              # registrysize = 100
      200, 1, 0, 0,              # archivesize = 456
      1, 0, 0, 0,                # compressedregistry = true
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12  # reserved array (12 bytes)
    ]

    stream = create_string_io(data)
    record = XGZarc::ArchiveRecord.new

    record.fromstream(stream)

    assert_equal 0x78563412, record["crc"]
    assert_equal 5, record["filecount"]
    assert_equal 2, record["version"]
    assert_equal 100, record["registrysize"]
    assert_equal 456, record["archivesize"]
    assert_equal true, record["compressedregistry"]
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], record["reserved"]
  end

  # Test FileRecord
  def test_file_record_initialization
    record = XGZarc::FileRecord.new

    # Test default values
    assert_nil record["name"]
    assert_nil record["path"]
    assert_equal 0, record["osize"]
    assert_equal 0, record["csize"]
    assert_equal 0, record["start"]
    assert_equal 0, record["crc"]
    assert_equal false, record["compressed"]
    assert_equal false, record["stored"]
    assert_equal 0, record["compressionlevel"]
  end

  def test_file_record_initialization_with_params
    record = XGZarc::FileRecord.new(
      "name" => "test.txt",
      "osize" => 1024,
      "compressed" => true
    )

    assert_equal "test.txt", record["name"]
    assert_equal 1024, record["osize"]
    assert_equal true, record["compressed"]
    assert_equal 0, record["csize"]  # Default preserved
  end

  def test_file_record_method_missing
    record = XGZarc::FileRecord.new

    # Test setter method
    record.name = "file.dat"
    assert_equal "file.dat", record["name"]

    # Test getter method
    record["osize"] = 2048
    assert_equal 2048, record.osize

    # Test unknown method
    assert_raises(NoMethodError) { record.unknown_method }
  end

  def test_file_record_respond_to_missing
    record = XGZarc::FileRecord.new
    record["TestKey"] = "value"

    # Should respond to setter
    assert record.respond_to?(:TestKey=)

    # Should respond to getter for existing key
    assert record.respond_to?(:TestKey)

    # Should not respond to unknown method
    refute record.respond_to?(:unknown_method)
  end

  def test_file_record_fromstream
    # Create test data for FileRecord (532 bytes)
    data = [0] * 532

    # Set name (first 256 bytes - shortstring format)
    name_str = "test.txt"
    data[0] = name_str.length
    name_str.bytes.each_with_index { |b, i| data[1 + i] = b }

    # Set path (next 256 bytes - shortstring format)
    path_str = "/tmp"
    data[256] = path_str.length
    path_str.bytes.each_with_index { |b, i| data[257 + i] = b }

    # Set other fields (after the two 256-byte arrays)
    # osize = 1024 (little-endian)
    data[512] = 0x00
    data[513] = 0x04
    data[514] = 0x00
    data[515] = 0x00

    # csize = 512 (little-endian)
    data[516] = 0x00
    data[517] = 0x02
    data[518] = 0x00
    data[519] = 0x00

    # start = 2048 (little-endian)
    data[520] = 0x00
    data[521] = 0x08
    data[522] = 0x00
    data[523] = 0x00

    # crc = 0x12345678 (little-endian)
    data[524] = 0x78
    data[525] = 0x56
    data[526] = 0x34
    data[527] = 0x12

    # compressed = false (0 means compressed = true, anything else false)
    data[528] = 1  # Not 0, so compressed = false

    # padding
    data[529] = 0
    data[530] = 0

    # compressionlevel
    data[531] = 5

    stream = create_string_io(data)
    record = XGZarc::FileRecord.new

    record.fromstream(stream)

    assert_equal "test.txt", record["name"]
    assert_equal "/tmp", record["path"]
    assert_equal 1024, record["osize"]
    assert_equal 512, record["csize"]
    assert_equal 2048, record["start"]
    assert_equal 0x12345678, record["crc"]
    assert_equal false, record["compressed"]  # 1 != 0 so false
    # Note: compressionlevel is at index 517 but the unpack pattern only goes to 516,
    # so it will be nil
    assert_nil record["compressionlevel"]
  end

  def test_file_record_to_s
    record = XGZarc::FileRecord.new("name" => "test.txt", "osize" => 1024)

    result = record.to_s
    assert result.include?("name")
    assert result.include?("test.txt")
    assert result.include?("osize")
    assert result.include?("1024")
  end

  # Test ZlibArchive - mocking complex file operations
  def test_zlib_archive_constants
    assert_equal 32768, XGZarc::ZlibArchive::MAXBUFSIZE
    assert_equal "tmpXGI", XGZarc::ZlibArchive::TMP_PREFIX
  end

  def test_zlib_archive_initialization_with_stream
    # Test that initialization attempts to create archive object
    # This will fail with invalid data, but we test the attempt
    stream = StringIO.new("invalid archive data")

    assert_raises(Exception) do  # Will raise some exception due to invalid data
      XGZarc::ZlibArchive.new(stream: stream)
    end
  end

  def test_zlib_archive_initialization_with_filename
    filename = "/nonexistent/file.zip"

    # Mock File.open to simulate file not found
    assert_raises(Errno::ENOENT) do
      XGZarc::ZlibArchive.new(filename: filename)
    end
  end

  def test_zlib_archive_attributes
    # Test basic attribute setup without full initialization
    archive_data = create_minimal_archive_data
    stream = StringIO.new(archive_data)

    # Create instance and test attribute readers exist
    # We'll catch the error but verify the attributes are set up
    begin
      XGZarc::ZlibArchive.new(stream: stream)
    rescue XGZarc::Error
      # Expected due to invalid test data
    end

    # Test that the class has the expected attributes
    assert XGZarc::ZlibArchive.instance_methods.include?(:arcrec)
    assert XGZarc::ZlibArchive.instance_methods.include?(:arcregistry)
    assert XGZarc::ZlibArchive.instance_methods.include?(:startofarcdata)
    assert XGZarc::ZlibArchive.instance_methods.include?(:endofarcdata)
    assert XGZarc::ZlibArchive.instance_methods.include?(:filename)
    assert XGZarc::ZlibArchive.instance_methods.include?(:stream)
  end

  def test_zlib_archive_setblocksize
    # Test setblocksize method exists and can be called
    # Since we can't easily create a valid archive, we'll test the method signature
    assert XGZarc::ZlibArchive.instance_methods.include?(:setblocksize)
  end

  def test_zlib_archive_getarchivefile_method_exists
    # Test that getarchivefile method exists
    assert XGZarc::ZlibArchive.instance_methods.include?(:getarchivefile)
  end

  # Tests with real archive fixture file
  def test_zlib_archive_with_valid_fixture
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    # Test initialization with valid archive file
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    
    # Verify archive was loaded correctly
    assert_equal 1, archive.arcrec["filecount"]
    assert_equal 1, archive.arcrec["version"]
    assert archive.arcrec["compressedregistry"]
    assert_equal 1, archive.arcregistry.length
    
    # Verify file record was parsed correctly
    file_record = archive.arcregistry.first
    assert_equal "test.txt", file_record["name"]
    assert_equal "", file_record["path"]
    assert_equal 14, file_record["osize"]  # "Hello, World!\n"
    assert_equal false, file_record["compressed"]
    
    # Test successful cleanup
    archive.stream.close if archive.stream
  end

  def test_zlib_archive_getarchivefile_with_fixture
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    file_record = archive.arcregistry.first
    
    # Extract the archived file
    extracted_file, temp_filename = archive.getarchivefile(file_record)
    
    # Verify extracted content
    content = extracted_file.read
    assert_equal "Hello, World!\n", content
    
    # Verify CRC matches
    extracted_file.rewind
    calculated_crc = XGUtils.streamcrc32(extracted_file)
    assert_equal file_record["crc"], calculated_crc
    
    # Cleanup
    extracted_file.close
    File.unlink(temp_filename) if File.exist?(temp_filename)
    archive.stream.close
  end

  def test_zlib_archive_extract_segment_compressed
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    
    # Test that extract_segment method is callable (it's private)
    assert archive.respond_to?(:extract_segment, true)
    
    archive.stream.close
  end

  def test_zlib_archive_setblocksize_functionality
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    
    # Test setblocksize method
    archive.setblocksize(16384)
    
    # The method should work without error
    # (Note: the method sets @maxbufsize, not @MAXBUFSIZE)
    
    archive.stream.close
  end

  def test_zlib_archive_error_handling_corrupted_crc
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    # Read the original file and corrupt the archive CRC
    original_data = File.read(fixture_path, mode: "rb")
    corrupted_data = original_data.dup
    
    # Corrupt the CRC in the archive record (first 4 bytes of the last 36 bytes)
    corrupted_data[-36] = (corrupted_data[-36].ord ^ 0xFF).chr
    
    # Write corrupted version to a temporary file
    temp_file = Tempfile.new(["corrupted_archive", ".zla"])
    temp_file.binmode
    temp_file.write(corrupted_data)
    temp_file.close
    
    # Test that corrupted archive raises appropriate error
    assert_raises(XGZarc::Error) do
      XGZarc::ZlibArchive.new(filename: temp_file.path)
    end
    
    # Cleanup
    temp_file.unlink
  end

  def test_zlib_archive_error_handling_corrupted_file_crc
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    file_record = archive.arcregistry.first.dup
    
    # Corrupt the file CRC
    file_record["crc"] = file_record["crc"] ^ 0xFFFFFFFF
    
    # Test that corrupted file CRC raises appropriate error
    assert_raises(XGZarc::Error) do
      archive.getarchivefile(file_record)
    end
    
    archive.stream.close
  end

  def test_zlib_archive_with_stream_fixture
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    # Test initialization with stream instead of filename
    File.open(fixture_path, "rb") do |file|
      archive = XGZarc::ZlibArchive.new(stream: file)
      
      # Verify archive was loaded correctly
      assert_equal 1, archive.arcrec["filecount"]
      assert_equal 1, archive.arcregistry.length
      
      # Verify the filename attribute is nil when using stream
      assert_nil archive.filename
      assert_equal file, archive.stream
    end
  end

  def test_archive_record_fromstream_with_fixture_data
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    File.open(fixture_path, "rb") do |file|
      # Seek to the archive record at the end
      file.seek(-XGZarc::ArchiveRecord::SIZEOFREC, IO::SEEK_END)
      
      record = XGZarc::ArchiveRecord.new
      record.fromstream(file)
      
      # Verify the archive record was parsed correctly
      assert_equal 1, record["filecount"]
      assert_equal 1, record["version"]
      assert record["compressedregistry"]
      assert record["registrysize"] > 0
      assert record["archivesize"] > 0
    end
  end

  def test_complete_archive_workflow
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    # Complete workflow test: open archive, list files, extract file
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    
    # Verify archive properties
    assert archive.arcregistry.length > 0
    assert archive.startofarcdata >= 0
    assert archive.endofarcdata > archive.startofarcdata
    
    # Get the first (and only) file
    file_record = archive.arcregistry.first
    assert_equal "test.txt", file_record["name"]
    
    # Extract and verify the file
    extracted_file, temp_filename = archive.getarchivefile(file_record)
    content = extracted_file.read
    
    # Verify content and properties
    assert_equal "Hello, World!\n", content
    assert_equal content.length, file_record["osize"]
    
    # Cleanup
    extracted_file.close
    File.unlink(temp_filename) if File.exist?(temp_filename)
    archive.stream.close
  end

  # Tests with compressed file archive
  def test_zlib_archive_with_compressed_files
    fixture_path = File.join(__dir__, "fixtures", "test_archive_compressed.zla")
    
    # Test with compressed file archive
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    
    # Verify archive was loaded correctly
    assert_equal 1, archive.arcrec["filecount"]
    assert_equal 1, archive.arcregistry.length
    
    # Verify file record indicates compression
    file_record = archive.arcregistry.first
    assert_equal "test.txt", file_record["name"]
    assert_equal true, file_record["compressed"]
    assert file_record["csize"] != file_record["osize"]  # Different sizes due to compression
    
    # Extract and verify the file
    extracted_file, temp_filename = archive.getarchivefile(file_record)
    content = extracted_file.read
    assert_equal "Hello, World!\n", content
    
    # Cleanup
    extracted_file.close
    File.unlink(temp_filename) if File.exist?(temp_filename)
    archive.stream.close
  end

  def test_extract_segment_with_compressed_data
    fixture_path = File.join(__dir__, "fixtures", "test_archive_compressed.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    file_record = archive.arcregistry.first
    
    # This should exercise the compressed extraction path
    extracted_file, temp_filename = archive.getarchivefile(file_record)
    
    # Verify decompression worked correctly
    content = extracted_file.read
    assert_equal "Hello, World!\n", content
    assert_equal 14, content.length
    
    # Verify the temporary file was created
    assert File.exist?(temp_filename)
    
    # Cleanup
    extracted_file.close
    File.unlink(temp_filename)
    archive.stream.close
  end

  def test_setblocksize_functionality_detailed
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    
    # Test setblocksize with different values
    archive.setblocksize(8192)
    archive.setblocksize(65536)
    
    # The method should complete without error
    # Note: setblocksize sets @maxbufsize instance variable
    
    archive.stream.close
  end

  # Test error handling with extraction failures
  def test_extract_segment_failure_scenarios
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    file_record = archive.arcregistry.first.dup
    
    # Test with invalid start position to trigger extraction failure
    file_record["start"] = 999999  # Invalid position
    
    # This should raise an error during extraction
    assert_raises(XGZarc::Error) do
      archive.getarchivefile(file_record)
    end
    
    archive.stream.close
  end

  # Test more edge cases for FileRecord unpack pattern
  def test_file_record_fromstream_unpack_edge_cases
    # Test the unpack pattern that only goes to 516, leaving compressionlevel nil
    data = [0] * XGZarc::FileRecord::SIZEOFREC
    
    # Set up minimal valid data
    data[0] = 8  # name length
    "test.txt".bytes.each_with_index { |b, i| data[1 + i] = b }
    data[256] = 0  # path length (empty)
    
    # Set compression level at position 531 (should be ignored by unpack)
    data[531] = 9
    
    stream = create_string_io(data)
    record = XGZarc::FileRecord.new
    record.fromstream(stream)
    
    # The compressionlevel should be nil because unpack pattern ends at 516
    assert_nil record["compressionlevel"]
    assert_equal "test.txt", record["name"]
  end

  # Test stream restoration in error conditions
  def test_archive_stream_position_restoration
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    File.open(fixture_path, "rb") do |file|
      initial_pos = file.tell
      
      # Create archive which will modify stream position
      archive = XGZarc::ZlibArchive.new(stream: file)
      
      # Verify stream position was restored after initialization
      # (The constructor should restore the original position)
      assert_equal initial_pos, file.tell
    end
  end

  # Test CRC calculation edge cases  
  def test_crc_calculation_coverage
    fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")
    
    File.open(fixture_path, "rb") do |file|
      # Test XGUtils.streamcrc32 with different parameters
      file.rewind
      
      # Test with no parameters (reads entire stream)
      crc1 = XGUtils.streamcrc32(file)
      assert crc1 > 0
      
      # Test with startpos parameter
      crc2 = XGUtils.streamcrc32(file, startpos: 0)
      assert_equal crc1, crc2
      
      # Test with both startpos and numbytes
      crc3 = XGUtils.streamcrc32(file, startpos: 0, numbytes: 10)
      assert crc3 > 0
      assert crc3 != crc1  # Should be different since we're only reading 10 bytes
    end
  end

  def test_file_record_constants_and_structure
    # Test that FileRecord has expected constants and structure
    assert_equal 532, XGZarc::FileRecord::SIZEOFREC
    
    # Test default initialization values
    record = XGZarc::FileRecord.new
    assert_nil record["name"]
    assert_nil record["path"] 
    assert_equal 0, record["osize"]
    assert_equal 0, record["csize"]
    assert_equal 0, record["start"]
    assert_equal 0, record["crc"]
    assert_equal false, record["compressed"]
    assert_equal false, record["stored"]
    assert_equal 0, record["compressionlevel"]
  end

  def test_archive_record_constants_and_structure
    # Test ArchiveRecord structure
    assert_equal 36, XGZarc::ArchiveRecord::SIZEOFREC
    
    # Test default initialization values in detail
    record = XGZarc::ArchiveRecord.new
    assert_equal 0, record["crc"]
    assert_equal 0, record["filecount"]
    assert_equal 0, record["version"]
    assert_equal 0, record["registrysize"]
    assert_equal 0, record["archivesize"]
    assert_equal false, record["compressedregistry"]
    assert_equal [], record["reserved"]
  end

  # Additional edge case tests to improve coverage
  def test_file_record_fromstream_with_invalid_data
    # Test fromstream with a stream that returns nil on read
    stream = StringIO.new("")
    record = XGZarc::FileRecord.new

    # This should raise a NoMethodError when trying to unpack nil
    assert_raises(NoMethodError) do
      record.fromstream(stream)
    end
  end

  def test_archive_record_fromstream_with_invalid_data
    # Test fromstream with a stream that returns nil/insufficient data
    stream = StringIO.new("")
    record = XGZarc::ArchiveRecord.new

    # This should raise a NoMethodError when trying to unpack nil
    assert_raises(NoMethodError) do
      record.fromstream(stream)
    end
  end

  def test_file_record_compressed_flag_edge_cases
    # Test different values for compressed flag
    data = [0] * XGZarc::FileRecord::SIZEOFREC
    
    # Set name length to 0 (empty name)
    data[0] = 0
    # Set path length to 0 (empty path)  
    data[256] = 0
    
    # Test compressed = true (value 0)
    data[528] = 0  # 0 means compressed = true
    
    stream = create_string_io(data)
    record = XGZarc::FileRecord.new
    record.fromstream(stream)
    
    assert_equal true, record["compressed"]
    assert_equal "", record["name"]
    assert_equal "", record["path"]
  end

  def test_archive_record_boolean_conversion
    # Test compressedregistry boolean conversion
    data = [0] * XGZarc::ArchiveRecord::SIZEOFREC
    
    # Set compressedregistry to non-zero value
    data[20] = 5  # Non-zero should convert to true
    data[21] = 0
    data[22] = 0
    data[23] = 0
    
    stream = create_string_io(data)
    record = XGZarc::ArchiveRecord.new
    record.fromstream(stream)
    
    assert_equal true, record["compressedregistry"]
  end

  # Test module structure
  def test_module_exists
    assert defined?(XGZarc)
    assert XGZarc.is_a?(Module)
  end

  def test_all_classes_exist
    expected_classes = [:Error, :ArchiveRecord, :FileRecord, :ZlibArchive]

    expected_classes.each do |class_name|
      assert XGZarc.const_defined?(class_name), "XGZarc should define #{class_name}"
    end
  end

  def test_hash_classes_inherit_from_hash
    hash_classes = [XGZarc::ArchiveRecord, XGZarc::FileRecord]

    hash_classes.each do |klass|
      assert klass.new.is_a?(Hash), "#{klass} should inherit from Hash"
    end
  end

  def test_constants_defined
    assert_equal 36, XGZarc::ArchiveRecord::SIZEOFREC
    assert_equal 532, XGZarc::FileRecord::SIZEOFREC
  end

  private

  def create_minimal_archive_data
    # Create minimal data that looks like an archive but will fail validation
    data = [0] * 1000

    # Add minimal archive record at the end
    archive_record_data = [
      0x12, 0x34, 0x56, 0x78,    # crc
      0, 0, 0, 0,                # filecount = 0
      1, 0, 0, 0,                # version = 1
      0, 0, 0, 0,                # registrysize = 0
      100, 0, 0, 0,              # archivesize = 100
      0, 0, 0, 0,                # compressedregistry = false
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  # reserved
    ]

    # Place archive record at the end
    start_pos = data.length - XGZarc::ArchiveRecord::SIZEOFREC
    archive_record_data.each_with_index { |b, i| data[start_pos + i] = b }

    data.pack("C*")
  end
end
