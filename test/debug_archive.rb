#!/usr/bin/env ruby

# Debug script to test index extraction

require_relative "../xgzarc"

fixture_path = File.join(__dir__, "fixtures", "test_archive.zla")

puts "=== Testing Index Extraction ==="

File.open(fixture_path, "rb") do |stream|
  # Read archive record
  stream.seek(-36, IO::SEEK_END)
  arcrec = XGZarc::ArchiveRecord.new
  arcrec.fromstream(stream)
  
  puts "compressedregistry: #{arcrec['compressedregistry']}"
  puts "registrysize: #{arcrec['registrysize']}"
  
  # Position at start of index
  stream.seek(-36 - arcrec["registrysize"], IO::SEEK_END)
  puts "Index starts at position: #{stream.tell}"
  
  # Try to read some of the index manually
  index_data = stream.read(50)  # Read first 50 bytes
  puts "First 50 bytes of index: #{index_data.bytes.map { |b| "%02x" % b }.join(' ')}"
  
  # Test extract_segment method if we can access it
  puts "\n=== Trying to create ZlibArchive directly ==="
  
  begin
    archive = XGZarc::ZlibArchive.new(filename: fixture_path)
    puts "SUCCESS: Archive created"
  rescue => e
    puts "ERROR: #{e.message}"
    puts "Class: #{e.class}"
  end
end