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
  
  # Record 3: FooterMatch  
  record3 = [0] * 2560
  record3[8] = 5  # tsFooterMatch
  record3[9, 4] = [7].pack("l<").bytes   # Score1 = 7
  record3[13, 4] = [3].pack("l<").bytes  # Score2 = 3
  record3[17, 4] = [1].pack("l<").bytes  # Winner = 1 (Player1)
  
  # Combine game data
  game_data = (record1 + record2 + record3).pack("C*")
  
  # Compress the game data
  compressed_data = Zlib::Deflate.deflate(game_data)
  
  # Combine header + compressed data
  file_data = header + compressed_data.bytes
  
  # Write to file
  File.open("demo.xg", "wb") do |f|
    f.write(file_data.pack("C*"))
  end
  
  puts "Sample XG file 'demo.xg' created (#{file_data.size} bytes)"
  "demo.xg"
end

def demo_parse_xg_file(filename)
  puts "\n" + "="*60
  puts "PARSING XG FILE: #{filename}"
  puts "="*60
  
  begin
    parser = XGFileParser::XGFile.new(filename)
    parser.parse
    
    puts "\nHEADER INFORMATION:"
    puts "-" * 30
    puts "Magic Number: 0x#{parser.header['MagicNumber'].to_s(16).upcase}"
    puts "Header Version: #{parser.header['HeaderVersion']}"
    puts "Header Size: #{parser.header['HeaderSize']} bytes"
    puts "Thumbnail Offset: #{parser.header['ThumbnailOffset']}"
    puts "Thumbnail Size: #{parser.header['ThumbnailSize']} bytes"
    puts "Game Name: #{parser.header['GameName'] || '(none)'}"
    puts "Save Name: #{parser.header['SaveName'] || '(none)'}"
    puts "Level Name: #{parser.header['LevelName'] || '(none)'}"
    puts "Comments: #{parser.header['Comments'] || '(none)'}"
    
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
      puts "\nRecord #{i + 1}: #{record['Type']} (EntryType: #{record['EntryType']})"
      
      case record["Type"]
      when "HeaderMatch"
        puts "  Player 1: #{record['Player1'] || '(none)'}"
        puts "  Player 2: #{record['Player2'] || '(none)'}"
        puts "  Match Length: #{record['MatchLength']}"
      when "HeaderGame"
        puts "  Score 1: #{record['Score1']}"
        puts "  Score 2: #{record['Score2']}"
      when "Cube"
        puts "  Active Player: #{XGUtils.player_to_symbol(record['Active'])}"
        puts "  Double: #{record['Double']}"
      when "Move"
        puts "  Active Player: #{XGUtils.player_to_symbol(record['ActivePlayer'])}"
        position = record['PositionI'] # or record['XGID']
        puts XGUtils.render_board(position)
        puts XGUtils.render_dice(record['Dice'])
        puts XGUtils.render_moves(record['Moves'])
      when "FooterGame"
        puts "  Final Score 1: #{record['Score1']}"
        puts "  Final Score 2: #{record['Score2']}"
        puts "  Winner: #{record['Winner']}"
      when "FooterMatch"
        puts "  Match Score 1: #{record['Score1']}"
        puts "  Match Score 2: #{record['Score2']}"
        puts "  Match Winner: #{record['Winner']}"
      else
        puts "  Raw data: #{record['RawData'][0..40]}..."
      end
    end
    
    puts "\n" + "="*60
    puts "PARSING COMPLETED SUCCESSFULLY"
    puts "="*60
    
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
  puts "="*40
  
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