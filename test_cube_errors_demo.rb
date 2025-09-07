#!/usr/bin/env ruby
#
# Test specific cube record with error values to show enhanced display
#

require_relative "demo_xgfile_parser"

def create_cube_with_errors_demo
  puts "Creating a cube record with error analysis for demonstration..."
  
  # Create minimal XG header
  header = [0] * 8232
  
  # Set magic number "RGMH" (little-endian: 0x484D4752)
  header[0..3] = [0x52, 0x47, 0x4D, 0x48]
  
  # Set header version (1)
  header[4..7] = [1, 0, 0, 0]
  
  # Set header size (8232)
  header[8..11] = [0x28, 0x20, 0, 0]
  
  # Set thumbnail offset and size (no thumbnail)
  header[12..19] = [0] * 8
  
  # Add some Unicode strings (UTF-16LE)
  game_name = "Cube Error Demo\0".encode("UTF-16LE").bytes
  save_name = "Error Analysis\0".encode("UTF-16LE").bytes
  
  # Place at correct offsets
  header[36, game_name.size] = game_name if game_name.size <= 2048
  header[36 + 2048, save_name.size] = save_name if save_name.size <= 2048
  
  # Record 1: HeaderMatch
  record1 = [0] * 2560
  record1[8] = 0  # tsHeaderMatch
  
  # Add player names
  player1 = "Expert"
  record1[9] = player1.length
  record1[10, player1.length] = player1.bytes
  
  player2 = "Beginner"
  record1[9 + 41] = player2.length
  record1[10 + 41, player2.length] = player2.bytes
  
  # Match length = 3
  record1[9 + 82, 4] = [3].pack("l<").bytes
  
  # Record 2: HeaderGame
  record2 = [0] * 2560
  record2[8] = 1  # tsHeaderGame
  record2[9, 4] = [0].pack("l<").bytes   # Score1 = 0
  record2[13, 4] = [0].pack("l<").bytes  # Score2 = 0

  # Record 3: Cube with error (Player made a doubling error)
  record3 = [0] * 2560
  record3[8] = 2  # tsCube
  record3[9, 4] = [1].pack("l<").bytes    # ActiveP = 1 (Player 1 - Expert)
  record3[13, 4] = [1].pack("l<").bytes   # Double = 1 (Yes - doubled)
  record3[17, 4] = [0].pack("l<").bytes   # Take = 0 (No - opponent dropped)
  record3[21, 4] = [0].pack("l<").bytes   # BeaverR = 0 (No)
  record3[25, 4] = [0].pack("l<").bytes   # RaccoonR = 0 (No)
  record3[29, 4] = [1].pack("l<").bytes   # CubeB = 1 (cube value 2 owned by player 1)
  
  # Advanced error analysis (simplified - actual format is complex)
  # Note: This is a simplified demonstration - real XG files have complex EngineStructDoubleAction data
  error_offset = 64 + 132 + 4  # After basic data + EngineStructDoubleAction + padding
  
  # Just set the basic error fields for demonstration
  # ErrCube at error_offset: 0.12 error (should not have doubled)
  record3[error_offset, 8] = [0.12].pack("E").bytes
  error_offset += 8 + 8  # Skip DiceRolled and padding
  
  # ErrTake: not applicable since opponent dropped
  record3[error_offset, 8] = [-1000.0].pack("E").bytes  # Not analyzed
  error_offset += 8 + 16  # Skip rollout data and padding
  
  # ErrBeaver, ErrRaccoon: not applicable
  record3[error_offset, 8] = [-1000.0].pack("E").bytes     # Not analyzed 
  record3[error_offset + 8, 8] = [-1000.0].pack("E").bytes # Not analyzed
  error_offset += 16
  
  # AnalyzeCR = 4 (4-ply analysis), isValid = 1 (error detected)
  record3[error_offset, 4] = [4].pack("V").bytes     # Analysis level 4
  record3[error_offset + 4, 4] = [1].pack("V").bytes # Error detected
  error_offset += 8 + 2 + 6  # Skip tutor data and padding
  
  # ErrTutorCube, ErrTutorTake: not in tutor mode
  record3[error_offset, 8] = [-1000.0].pack("E").bytes     
  record3[error_offset + 8, 8] = [-1000.0].pack("E").bytes 
  error_offset += 16
  
  # FlaggedDouble: 1 (flagged for review)
  record3[error_offset] = 1
  
  # Record 4: Cube with good decision for comparison
  record4 = [0] * 2560
  record4[8] = 2  # tsCube
  record4[9, 4] = [-1].pack("l<").bytes   # ActiveP = -1 (Player 2 - Beginner)
  record4[13, 4] = [0].pack("l<").bytes   # Double = 0 (No - correctly did not double)
  record4[17, 4] = [0].pack("l<").bytes   # Take = 0 (No decision needed)
  record4[21, 4] = [0].pack("l<").bytes   # BeaverR = 0
  record4[25, 4] = [0].pack("l<").bytes   # RaccoonR = 0  
  record4[29, 4] = [1].pack("l<").bytes   # CubeB = 1 (still owned by player 1)
  
  # Good decision - minimal error
  error_offset = 64 + 132 + 4
  record4[error_offset, 8] = [0.001].pack("E").bytes  # Excellent decision
  error_offset += 8 + 8
  record4[error_offset, 8] = [-1000.0].pack("E").bytes  # Take not analyzed
  error_offset += 8 + 16
  record4[error_offset, 8] = [-1000.0].pack("E").bytes     # Beaver not analyzed
  record4[error_offset + 8, 8] = [-1000.0].pack("E").bytes # Raccoon not analyzed
  error_offset += 16
  record4[error_offset, 4] = [3].pack("V").bytes     # Analysis level 3
  record4[error_offset + 4, 4] = [0].pack("V").bytes # Valid decision
  error_offset += 8 + 2 + 6
  record4[error_offset, 8] = [-1000.0].pack("E").bytes
  record4[error_offset + 8, 8] = [-1000.0].pack("E").bytes
  error_offset += 16
  record4[error_offset] = 0  # Not flagged

  # Record 5: FooterMatch  
  record5 = [0] * 2560
  record5[8] = 5  # tsFooterMatch
  record5[9, 4] = [3].pack("l<").bytes   # Score1 = 3
  record5[13, 4] = [1].pack("l<").bytes  # Score2 = 1  
  record5[17, 4] = [1].pack("l<").bytes  # Winner = 1 (Expert wins)
  
  # Combine game data
  game_data = (record1 + record2 + record3 + record4 + record5).pack("C*")
  
  # Compress the game data
  compressed_data = Zlib::Deflate.deflate(game_data)
  
  # Combine header + compressed data
  file_data = header + compressed_data.bytes
  
  # Write to file
  File.open("cube_errors_demo.xg", "wb") do |f|
    f.write(file_data.pack("C*"))
  end
  
  puts "Cube error demo file 'cube_errors_demo.xg' created (#{file_data.size} bytes)"
  "cube_errors_demo.xg"
end

if __FILE__ == $PROGRAM_NAME
  puts "Enhanced Cube Display Demonstration"
  puts "="*50
  
  # Create and parse demo file with cube errors
  demo_file = create_cube_with_errors_demo
  demo_parse_xg_file(demo_file)
  
  puts "\nCleaning up demo file..."
  File.delete(demo_file) if File.exist?(demo_file)
end