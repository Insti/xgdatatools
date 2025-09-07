#!/usr/bin/env ruby

require_relative "xgstruct"
require_relative "test/create_test_archive"
require "zlib"
require "tempfile"

# Create a proper XG file that includes both GDF header and ZlibArchive
def create_proper_xg_file(filename)
  puts "Creating proper XG file: #{filename}"

  # Create GDF header (simplified version)
  header = [0] * 8232

  # Set magic number "RGMH" (little-endian: 0x484D4752)
  header[0..3] = [0x52, 0x47, 0x4D, 0x48]

  # Set header version (1)
  header[4..7] = [1, 0, 0, 0]

  # Set header size (8232)
  header[8..11] = [0x28, 0x20, 0, 0]

  # Set thumbnail offset and size (no thumbnail)
  header[12..19] = [0] * 8

  # Add some basic string data
  game_name = "Test Game\0".encode("UTF-16LE").bytes
  header[36, game_name.size] = game_name if game_name.size <= 2048

  # Create archive files
  # File 1: Game header info
  game_hdr_content = "XG Game Header\n"
  game_hdr_crc = Zlib.crc32(game_hdr_content)

  # File 2: Game file with magic number
  game_file_content = ("\x00" * 556) + "DMLI" + "Game data content\n"
  game_file_crc = Zlib.crc32(game_file_content)

  # Create file records
  file_record_1 = create_file_record(
    name: "temp.xgi",
    path: "",
    original_size: game_hdr_content.length,
    compressed_size: game_hdr_content.length,
    crc: game_hdr_crc,
    compressed: false,
    start: 0
  )

  file_record_2 = create_file_record(
    name: "temp.xg",
    path: "",
    original_size: game_file_content.length,
    compressed_size: game_file_content.length,
    crc: game_file_crc,
    compressed: false,
    start: game_hdr_content.length
  )

  # Create file index
  file_index = file_record_1 + file_record_2
  compressed_index = Zlib::Deflate.deflate(file_index)

  # Create archive data
  archive_data = game_hdr_content + game_file_content

  # Calculate archive CRC (data + index but not archive record)
  archive_crc = Zlib.crc32(archive_data + compressed_index)

  # Create archive record
  archive_record = create_archive_record(
    crc: archive_crc,
    filecount: 2,
    version: 1,
    registrysize: compressed_index.length,
    archivesize: archive_data.length,
    compressedregistry: true
  )

  # Write complete XG file: [GDF_header][archive_data][compressed_index][archive_record]
  File.open(filename, "wb") do |f|
    f.write(header.pack("C*"))
    f.write(archive_data)
    f.write(compressed_index)
    f.write(archive_record)
  end

  puts "Created XG file: #{filename} (#{File.size(filename)} bytes)"
  puts "Structure: GDF header (#{header.size}) + archive data (#{archive_data.length}) + index (#{compressed_index.length}) + record (#{archive_record.length})"
end

def create_file_record(name:, path:, original_size:, compressed_size:, crc:, compressed:, start:)
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

  # Padding and compression level
  record[529] = "\x00"
  record[530] = "\x00"
  record[531] = 6.chr

  record
end

def create_archive_record(crc:, filecount:, version:, registrysize:, archivesize:, compressedregistry:)
  record = "\x00" * 36

  # Pack all the fields
  record[0, 4] = [crc].pack("L<")  # Unsigned for CRC
  record[4, 4] = [filecount].pack("l<")
  record[8, 4] = [version].pack("l<")
  record[12, 4] = [registrysize].pack("l<")
  record[16, 4] = [archivesize].pack("l<")
  record[20, 4] = [compressedregistry ? 1 : 0].pack("l<")

  record
end

if __FILE__ == $0
  create_proper_xg_file("example.xg")
end
