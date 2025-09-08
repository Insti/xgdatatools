#!/usr/bin/env ruby
#
# demo_xgfile_parser.rb - Demonstration script for the new XG file parser
#
# This script demonstrates the from-scratch parsing capabilities of the
# new XGFileParser module.

require_relative "xgfile_parser"
require_relative "xgutils"
require "pp"
require "debug"

# Helper function to safely display cube values
# Prevents displaying numbers with hundreds/thousands of digits
def safe_cube_value_display(cube_power)
  # In backgammon, cube values rarely go beyond 2^10 = 1024
  # Values like 2^900 are likely data corruption or parsing errors
  max_reasonable_power = 10

  if cube_power > max_reasonable_power
    "INVALID (#{cube_power} - unreasonable cube power, would be 2^#{cube_power})"
  else
    2**cube_power
  end
end

def demo_create_sample_xg_file
  puts "Creating a sample XG file for demonstration..."

  # Create minimal XG header
  header = [0] * XGFileParser::XGFile::RICH_GAME_HEADER_SIZE

  # Set magic number "RGMH" (little-endian: 0x484D4752)
  header[0..3] = [0x52, 0x47, 0x4D, 0x48]

  # Set header version (1)
  header[4..7] = [1, 0, 0, 0]

  # Set header size (8232)
  header[8..11] = [0x28, 0x20, 0, 0]

  # Set thumbnail offset and size (no thumbnail)
  header[12..19] = [0] * 8

  # Add some Unicode strings (UTF-16LE)
  game_name = "Demo XG Game\0".encode("UTF-16LE").bytes
  save_name = "Demo Save\0".encode("UTF-16LE").bytes

  # Place at correct offsets
  header[36, game_name.size] = game_name if game_name.size <= 2048
  header[36 + 2048, save_name.size] = save_name if save_name.size <= 2048

  # Create sample game data with two records
  # Record 1: HeaderMatch
  record1 = [0] * 2560
  record1[8] = 0  # tsHeaderMatch

  # Add player names
  player1 = "Alice"
  record1[9] = player1.length
  record1[10, player1.length] = player1.bytes

  player2 = "Bob"
  record1[9 + 41] = player2.length
  record1[10 + 41, player2.length] = player2.bytes

  # Match length = 7
  record1[9 + 82, 4] = [7].pack("l<").bytes

  # Record 2: HeaderGame
  record2 = [0] * 2560
  record2[8] = 1  # tsHeaderGame
  record2[9, 4] = [0].pack("l<").bytes   # Score1 = 0
  record2[13, 4] = [0].pack("l<").bytes  # Score2 = 0

  # Record 3: Simple Cube record for demonstration
  record3 = [0] * 2560
  record3[8] = 2  # tsCube
  record3[9, 4] = [1].pack("l<").bytes    # ActiveP = 1 (Player 1) - at offset 9 for XG file format
  record3[13, 4] = [1].pack("l<").bytes   # Double = 1 (Yes) - at offset 13 for XG file format
  record3[17, 4] = [1].pack("l<").bytes   # Take = 1 (Yes)
  record3[21, 4] = [0].pack("l<").bytes   # BeaverR = 0 (No)
  record3[25, 4] = [0].pack("l<").bytes   # RaccoonR = 0 (No)
  record3[29, 4] = [1].pack("l<").bytes   # CubeB = 1 (cube value 2 owned by player 1)

  # Record 4: FooterMatch
  record4 = [0] * 2560
  record4[8] = 5  # tsFooterMatch
  record4[9, 4] = [7].pack("l<").bytes   # Score1 = 7
  record4[13, 4] = [3].pack("l<").bytes  # Score2 = 3
  record4[17, 4] = [1].pack("l<").bytes  # Winner = 1 (Player1)

  # Combine game data
  game_data = (record1 + record2 + record3 + record4).pack("C*")

  # Compress the game data
  compressed_data = Zlib::Deflate.deflate(game_data)

  # Combine header + compressed data
  file_data = header + compressed_data.bytes

  # Write to file
  File.binwrite("demo.xg", file_data.pack("C*"))

  puts "Sample XG file 'demo.xg' created (#{file_data.size} bytes) - includes cube record"
  "demo.xg"
end

def demo_parse_xg_file(filename)
  puts "\n" + "=" * 60
  puts "PARSING XG FILE: #{filename}"
  puts "=" * 60

  begin
    parser = XGFileParser::XGFile.new(filename)
    parser.parse

    puts "\nHEADER INFORMATION:"
    puts "-" * 30
    puts "Magic Number: 0x#{parser.header["MagicNumber"].to_s(16).upcase}"
    puts "Header Version: #{parser.header["HeaderVersion"]}"
    puts "Header Size: #{parser.header["HeaderSize"]} bytes"
    puts "Thumbnail Offset: #{parser.header["ThumbnailOffset"]}"
    puts "Thumbnail Size: #{parser.header["ThumbnailSize"]} bytes"
    puts "Game Name: #{parser.header["GameName"] || "(none)"}"
    puts "Save Name: #{parser.header["SaveName"] || "(none)"}"
    puts "Level Name: #{parser.header["LevelName"] || "(none)"}"
    puts "Comments: #{parser.header["Comments"] || "(none)"}"

    if parser.thumbnail_data
      puts "\nTHUMBNAIL:"
      puts "-" * 15
      puts "Found valid JPEG thumbnail (#{parser.thumbnail_data.size} bytes)"
    else
      puts "\nNo thumbnail data found."
    end

    puts "\nGAME RECORDS:"
    puts "-" * 20
    puts "Found #{parser.game_records.size} game record(s):"

    parser.game_records.each_with_index do |record, i|
      puts "\nRecord #{i + 1}: #{record["Type"]} (EntryType: #{record["EntryType"]})"

      case record["Type"]
      when "HeaderMatch"
        puts "  Player 1: #{record["Player1"] || "(none)"}"
        puts "  Player 2: #{record["Player2"] || "(none)"}"
        puts "  Match Length: #{record["MatchLength"]}"
      when "HeaderGame"
        puts "  Score 1: #{record["Score1"]}"
        puts "  Score 2: #{record["Score2"]}"
      when "Cube"
        puts "  === CUBE DECISION ==="
        puts "  Active Player: #{record["ActiveP"] || record["Active"]} #{if record["ActiveP"] == 1
                                                                            "(Player 1)"
                                                                          else
                                                                            (record["ActiveP"] == -1) ? "(Player 2)" : ""
                                                                          end}"
        puts "  Double Decision: #{(record["Double"] == 1) ? "YES" : "NO"}"
        puts "  Take Decision: #{if record["Take"] == 1
                                   "YES"
                                 else
                                   (record["Take"] == 2) ? "BEAVER" : "NO"
                                 end}"

        # Show cube position/ownership
        cube_val = record["CubeB"] || 0
        if cube_val == 0
          puts "  Cube Position: CENTER (value 1)"
        elsif cube_val > 0
          value_display = safe_cube_value_display(cube_val)
          puts "  Cube Position: OWNED by Player 1 (value #{value_display})"
        else
          value_display = safe_cube_value_display(-cube_val)
          puts "  Cube Position: OWNED by Player 2 (value #{value_display})"
        end

        # Show validation status
        valid_status = record["isValid"] || 0
        case valid_status
        when 0
          puts "  Decision Status: ✓ VALID"
        when 1
          puts "  Decision Status: ⚠ ERROR DETECTED"
        when 2
          puts "  Decision Status: ✗ INVALID"
        else
          puts "  Decision Status: UNKNOWN (#{valid_status})"
        end

        # Show error analysis (human-readable) - only show if values are reasonable
        if record["ErrCube"]&.is_a?(Numeric) && record["ErrCube"].abs < 100
          if (record["ErrCube"] + 1000.0).abs < 0.0001
            puts "  Double Analysis: Not analyzed"
          elsif record["ErrCube"] > 0.001
            puts "  Double Error: #{sprintf("%.3f", record["ErrCube"])} (should have NOT doubled)"
          elsif record["ErrCube"] < -0.001
            puts "  Double Error: #{sprintf("%.3f", -record["ErrCube"])} (should have doubled)"
          else
            puts "  Double Analysis: Perfect decision (#{sprintf("%.3f", record["ErrCube"])} error)"
          end
        end

        if record["ErrTake"]&.is_a?(Numeric) && record["ErrTake"].abs < 100
          if (record["ErrTake"] + 1000.0).abs < 0.0001
            puts "  Take Analysis: Not analyzed"
          elsif record["ErrTake"] > 0.001
            puts "  Take Error: #{sprintf("%.3f", record["ErrTake"])} (should have PASSED)"
          elsif record["ErrTake"] < -0.001
            puts "  Take Error: #{sprintf("%.3f", -record["ErrTake"])} (should have TAKEN)"
          else
            puts "  Take Analysis: Perfect decision (#{sprintf("%.3f", record["ErrTake"])} error)"
          end
        end

        # Show if flagged for review
        if record["FlaggedDouble"]
          puts "  🚩 FLAGGED for review"
        end

        # Show analysis level if available and reasonable
        if record["AnalyzeCR"]&.is_a?(Numeric) && record["AnalyzeCR"] > 0 && record["AnalyzeCR"] < 10
          puts "  Analysis Level: #{record["AnalyzeCR"]}-ply"
        end
      when "Move"
        puts "  Active Player: #{XGUtils.player_to_symbol(record["ActivePlayer"])}"
        position = record["PositionI"] # or record['XGID']
        puts XGUtils.render_board(position)
        puts XGUtils.render_dice(record["Dice"])
        puts XGUtils.render_moves(record["Moves"])
      when "FooterGame"
        puts "  Final Score 1: #{record["Score1"]}"
        puts "  Final Score 2: #{record["Score2"]}"
        puts "  Winner: #{record["Winner"]}"
      when "FooterMatch"
        puts "  Match Score 1: #{record["Score1"]}"
        puts "  Match Score 2: #{record["Score2"]}"
        puts "  Match Winner: #{record["Winner"]}"
      else
        puts "  Raw data: #{record["RawData"][0..40]}..."
      end
    end

    puts "\n" + "=" * 60
    puts "PARSING COMPLETED SUCCESSFULLY"
    puts "=" * 60
  rescue XGFileParser::Error => e
    puts "ERROR: #{e.message}"
    puts "Code: #{e.code}" if e.code
    puts "Details: #{e.details}" if e.details
  rescue => e
    puts "UNEXPECTED ERROR: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end
end

if __FILE__ == $PROGRAM_NAME
  puts "XG File Parser Demonstration"
  puts "=" * 40

  if ARGV.length > 0
    # Parse user-provided files
    ARGV.each do |filename|
      demo_parse_xg_file(filename)
    end
  else
    # Create and parse demo file
    demo_file = demo_create_sample_xg_file
    demo_parse_xg_file(demo_file)

    puts "\nCleaning up demo file..."
    File.delete(demo_file) if File.exist?(demo_file)
  end
end
