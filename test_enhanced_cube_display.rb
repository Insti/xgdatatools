#!/usr/bin/env ruby
#
# Test for enhanced cube display functionality
#

require_relative "xgfile_parser"
require_relative "xgstruct"
require "stringio"

def create_test_cube_record
  # Create a cube record with rich error data for testing
  record_data = [0] * 2560
  record_data[8] = 2  # Cube record type
  
  # Basic cube data at offset 13 (matching CubeEntry.fromstream format)
  record_data[13, 4] = [1].pack("V").bytes     # ActiveP = 1 (Player 1)
  record_data[17, 4] = [1].pack("V").bytes     # Double = 1 (Yes)
  record_data[21, 4] = [1].pack("V").bytes     # Take = 1 (Yes)
  record_data[25, 4] = [0].pack("V").bytes     # BeaverR = 0 (No)
  record_data[29, 4] = [0].pack("V").bytes     # RaccoonR = 0 (No)
  record_data[33, 4] = [2].pack("V").bytes     # CubeB = 2 (cube value 4 owned by player)
  
  # Skip to error data section (after initial 64 bytes + doubled data)
  error_offset = 64 + 132 + 4  # 64 initial + 132 EngineStructDoubleAction + 4 padding
  
  # ErrCube: error made on doubling (8 bytes double)
  record_data[error_offset, 8] = [0.15].pack("E").bytes  # 0.15 error on doubling
  error_offset += 8
  
  # Skip DiceRolled (3 bytes) + padding (5 bytes)
  error_offset += 8
  
  # ErrTake: error made on taking (8 bytes double) 
  record_data[error_offset, 8] = [0.05].pack("E").bytes  # 0.05 error on taking
  error_offset += 8
  
  # Skip rollout data (12 bytes) + padding (4 bytes)
  error_offset += 16
  
  # ErrBeaver, ErrRaccoon: 2 doubles (16 bytes)
  record_data[error_offset, 8] = [-1000.0].pack("E").bytes     # Not analyzed 
  record_data[error_offset + 8, 8] = [-1000.0].pack("E").bytes # Not analyzed
  error_offset += 16
  
  # AnalyzeCR, isValid: 2 longs (8 bytes)
  record_data[error_offset, 4] = [3].pack("V").bytes     # Analysis level 3
  record_data[error_offset + 4, 4] = [0].pack("V").bytes # Valid decision (0=Ok, 1=error, 2=invalid)
  error_offset += 8
  
  # TutorCube, TutorTake: 2 signed bytes
  record_data[error_offset] = 0     # No tutor cube
  record_data[error_offset + 1] = 0 # No tutor take
  error_offset += 2
  
  # Skip padding (6 bytes)
  error_offset += 6
  
  # ErrTutorCube, ErrTutorTake: 2 doubles (16 bytes)
  record_data[error_offset, 8] = [-1000.0].pack("E").bytes     # Not in tutor mode
  record_data[error_offset + 8, 8] = [-1000.0].pack("E").bytes # Not in tutor mode
  error_offset += 16
  
  # FlaggedDouble: 1 byte
  record_data[error_offset] = 1  # Cube decision has been flagged
  
  record_data.pack("C*")
end

def test_enhanced_cube_parsing
  puts "Testing enhanced cube parsing..."
  
  # Create test data and parse it
  cube_data = create_test_cube_record
  stream = StringIO.new(cube_data)
  
  cube_entry = XGStruct::CubeEntry.new
  parsed = cube_entry.fromstream(stream)
  
  puts "Parsed cube entry:"
  puts "  ActiveP: #{parsed['ActiveP']}"
  puts "  Double: #{parsed['Double']}"
  puts "  Take: #{parsed['Take']}"
  puts "  CubeB: #{parsed['CubeB']}"
  puts "  ErrCube: #{parsed['ErrCube']}"
  puts "  ErrTake: #{parsed['ErrTake']}"
  puts "  isValid: #{parsed['isValid']}"
  puts "  AnalyzeCR: #{parsed['AnalyzeCR']}"
  puts "  FlaggedDouble: #{parsed['FlaggedDouble']}"
  
  puts "\nTesting file parser integration..."
  
  # Test through the file parser
  temp_file = "/tmp/test_cube_enhanced.xg"
  
  # Create minimal XG file with this cube record
  header = [0] * 8232
  header[0..3] = [0x52, 0x47, 0x4D, 0x48]  # Magic
  header[4..7] = [1, 0, 0, 0]               # Version
  header[8..11] = [0x28, 0x20, 0, 0]        # Header size
  header[12..19] = [0] * 8                  # No thumbnail
  
  # Compress cube data
  compressed = Zlib::Deflate.deflate(cube_data)
  file_data = header + compressed.bytes
  
  File.open(temp_file, "wb") { |f| f.write(file_data.pack("C*")) }
  
  # Parse with XGFileParser
  parser = XGFileParser::XGFile.new(temp_file)
  parser.parse
  
  record = parser.game_records.first
  puts "\nParsed through XGFileParser:"
  puts "  Type: #{record['Type']}"
  puts "  Active: #{record['Active']} (ActiveP: #{record['ActiveP']})"
  puts "  Double: #{record['Double']}"
  puts "  Take: #{record['Take']}"
  puts "  CubeB: #{record['CubeB']}"
  puts "  ErrCube: #{record['ErrCube']}"
  puts "  ErrTake: #{record['ErrTake']}"
  puts "  isValid: #{record['isValid']}"
  puts "  FlaggedDouble: #{record['FlaggedDouble']}"
  
  File.delete(temp_file) if File.exist?(temp_file)
  
  puts "\nEnhanced cube parsing test completed successfully!"
end

if __FILE__ == $PROGRAM_NAME
  test_enhanced_cube_parsing
end