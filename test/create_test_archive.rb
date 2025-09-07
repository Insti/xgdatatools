#!/usr/bin/env ruby

# Test archive creator for xgzarc.rb testing
# This creates a minimal but valid ZLibArchive file for testing

require "zlib"
require "tempfile"
require "fileutils"
require_relative "../xgutils"

class TestArchiveCreator
  def self.create_test_archive(output_file)
    create_archive(output_file, compressed_files: false)
  end

  def self.create_compressed_test_archive(output_file)
    create_archive(output_file, compressed_files: true)
  end

  private

  private_class_method def self.create_archive(output_file, compressed_files: false)
    # Test file content (make it simple)
    test_content = "Hello, World!\n"

    # Calculate CRC32 of original content
    content_crc = Zlib.crc32(test_content)

    file_data = if compressed_files
      # Compress the file content
      Zlib::Deflate.deflate(test_content)
    else
      test_content
    end

    # Create file record for the test file
    file_record_data = create_file_record(
      name: "test.txt",
      path: "",
      original_size: test_content.length,
      compressed_size: file_data.length,
      crc: content_crc,
      compressed: compressed_files,
      start: 0
    )

    # Create file index containing just our file record
    file_index = file_record_data

    # Compress the file index for compatibility with the current code
    compressed_index = Zlib::Deflate.deflate(file_index)

    # Calculate CRC32 of file_data + compressed_index (but NOT the archive record)
    archive_crc = Zlib.crc32(file_data + compressed_index)

    # Create archive record
    archive_record = create_archive_record(
      crc: archive_crc,
      filecount: 1,
      version: 1,
      registrysize: compressed_index.length,
      archivesize: file_data.length,  # Just the file data size, not data+index
      compressedregistry: true  # Use compressed index
    )

    # Write complete archive: [file_data][compressed_index][archive_record]
    File.open(output_file, "wb") do |f|
      f.write(file_data)
      f.write(compressed_index)
      f.write(archive_record)
    end

    compression_type = compressed_files ? "compressed" : "uncompressed"
    puts "Created #{compression_type} test archive: #{output_file}"
    puts "Archive size: #{File.size(output_file)} bytes"
    puts "Content: '#{test_content.strip}'"
    puts "Layout: [#{file_data.length} bytes #{compression_type} file][#{compressed_index.length} bytes compressed index][#{archive_record.length} bytes record]"
  end

  private

  private_class_method def self.create_file_record(name:, path:, original_size:, compressed_size:, crc:, compressed:, start:)
    # FileRecord structure: 532 bytes total
    # Bytes 0-255: name (shortstring format)
    # Bytes 256-511: path (shortstring format)
    # Bytes 512-515: osize (int32 little-endian)
    # Bytes 516-519: csize (int32 little-endian)
    # Bytes 520-523: start (int32 little-endian)
    # Bytes 524-527: crc (uint32 little-endian)
    # Byte 528: compressed flag (0 = compressed, non-zero = uncompressed)
    # Bytes 529-530: padding
    # Byte 531: compression level

    record = "\x00" * 532

    # Name (shortstring format: length byte + string)
    record[0] = name.length.chr
    record[1, name.length] = name

    # Path (shortstring format: length byte + string)
    record[256] = path.length.chr
    if path.length > 0
      record[257, path.length] = path
    end

    # Pack the numeric fields at the correct positions
    record[512, 4] = [original_size].pack("l<")
    record[516, 4] = [compressed_size].pack("l<")
    record[520, 4] = [start].pack("l<")
    record[524, 4] = [crc].pack("L<")  # Unsigned for CRC

    # Compressed flag (0 = compressed, 1 = not compressed)
    record[528] = (compressed ? 0 : 1).chr

    # Padding
    record[529] = "\x00"
    record[530] = "\x00"

    # Compression level
    record[531] = 6.chr  # Default zlib compression level

    record
  end

  private_class_method def self.create_archive_record(crc:, filecount:, version:, registrysize:, archivesize:, compressedregistry:)
    # ArchiveRecord structure: 36 bytes total
    # Bytes 0-3: crc (uint32 little-endian)
    # Bytes 4-7: filecount (int32 little-endian)
    # Bytes 8-11: version (int32 little-endian)
    # Bytes 12-15: registrysize (int32 little-endian)
    # Bytes 16-19: archivesize (int32 little-endian)
    # Bytes 20-23: compressedregistry (int32 little-endian, 0=false, 1=true)
    # Bytes 24-35: reserved (12 bytes of zeros)

    record = "\x00" * 36

    # Pack all the fields
    record[0, 4] = [crc].pack("L<")  # Unsigned for CRC
    record[4, 4] = [filecount].pack("l<")
    record[8, 4] = [version].pack("l<")
    record[12, 4] = [registrysize].pack("l<")
    record[16, 4] = [archivesize].pack("l<")
    record[20, 4] = [compressedregistry ? 1 : 0].pack("l<")

    # Reserved bytes (24-35) are already initialized to zeros

    record
  end
end

# Create the test archives if run directly
if __FILE__ == $0
  output_file = File.join(__dir__, "fixtures", "test_archive.zla")
  compressed_output_file = File.join(__dir__, "fixtures", "test_archive_compressed.zla")
  FileUtils.mkdir_p(File.dirname(output_file))
  TestArchiveCreator.create_test_archive(output_file)
  TestArchiveCreator.create_compressed_test_archive(compressed_output_file)
end
