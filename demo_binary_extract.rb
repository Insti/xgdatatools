#!/usr/bin/env ruby
#
# Demo script to create a test XG file and show the binary extraction tool
#

require_relative "xgfile_parser"
require "zlib"
require "tempfile"

# Helper to create minimal valid XG header (adapted from test files)
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

# Create a sample XG file
puts "Creating sample XG file..."

# Create simple game data
game_data = "Sample XG game data with some content to be compressed"
file_data = create_xg_file_with_data(game_data)

# Write to a test file
test_filename = "/tmp/sample.xg"
File.binwrite(test_filename, file_data.pack("C*"))

puts "Created test file: #{test_filename} (#{File.size(test_filename)} bytes)"
puts "File exists: #{File.exist?(test_filename)}"

# Test the extraction tool
puts "\nTesting binary extraction tool..."
system("ruby", "./xgbinaryextract.rb", "-v", "debug", "-d", "/tmp", test_filename)

# Show what files were created
puts "\nGenerated binary files:"
Dir.glob("/tmp/*_*_*.bin").each do |file|
  puts "  #{File.basename(file)} (#{File.size(file)} bytes)"
end

# Cleanup
File.delete(test_filename) if File.exist?(test_filename)
Dir.glob("/tmp/*_*_*.bin").each { |f| File.delete(f) }

puts "\nDemo completed."
