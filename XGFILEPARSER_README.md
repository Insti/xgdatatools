# XGFileParser - Complete XG File Parser

## Overview

The `XGFileParser` module provides a complete, from-scratch parser for eXtreme Gammon .xg files according to the official XGFormat specification. Unlike the existing tools that work with pre-extracted file segments, this parser handles the entire .xg file container format.

## Features

- **Complete File Parsing**: Handles the full DirectX RichGameFormat container
- **Header Validation**: Validates magic number ($484D4752 "RGMH") and structure
- **Thumbnail Extraction**: Extracts embedded JPEG thumbnails when present
- **ZLIB Decompression**: Automatically decompresses the payload data
- **Game Record Parsing**: Parses all game record types (HeaderMatch, HeaderGame, Cube, Move, FooterGame, FooterMatch)
- **Unicode Support**: Properly handles UTF-16LE encoded strings
- **Error Handling**: Comprehensive error handling with detailed error codes
- **Extensive Testing**: 21 test cases covering all functionality

## Usage

### Basic Usage

```ruby
require_relative "xgfile_parser"

# Parse an XG file
parser = XGFileParser::XGFile.new("game.xg")
parser.parse

# Access header information
puts "Game: #{parser.header['GameName']}"
puts "Players: #{parser.header['SaveName']}"
puts "Magic: 0x#{parser.header['MagicNumber'].to_s(16).upcase}"

# Access thumbnail if present
if parser.thumbnail_data
  File.write("thumbnail.jpg", parser.thumbnail_data)
end

# Access game records
parser.game_records.each do |record|
  puts "Record: #{record['Type']}"
  case record['Type']
  when "HeaderMatch"
    puts "  Player 1: #{record['Player1']}"
    puts "  Player 2: #{record['Player2']}"
    puts "  Match Length: #{record['MatchLength']}"
  when "FooterMatch"
    puts "  Final Score: #{record['Score1']}-#{record['Score2']}"
    puts "  Winner: #{record['Winner']}"
  end
end
```

### Error Handling

```ruby
begin
  parser = XGFileParser::XGFile.new("game.xg")
  parser.parse
rescue XGFileParser::Error => e
  case e.code
  when :file_too_small
    puts "File is too small to be a valid XG file"
  when :invalid_magic
    puts "Not a valid XG file (wrong magic number)"
  when :invalid_header_size  
    puts "Invalid header size"
  when :decompression_failed
    puts "Failed to decompress game data: #{e.details}"
  else
    puts "Parse error: #{e.message}"
  end
end
```

## File Format Support

The parser implements the complete XGFormat specification:

### RichGameHeader (8232 bytes)
- Magic number validation ($484D4752)
- Header version and size
- Thumbnail offset and size
- Game GUID
- Unicode strings (GameName, SaveName, LevelName, Comments)

### Thumbnail Support
- JPEG thumbnail extraction
- Magic number validation (0xFF 0xD8)
- Automatic size validation

### Game Records (2560 bytes each)
- **HeaderMatch**: Match setup, player names, match length
- **HeaderGame**: Game initialization, scores
- **Cube**: Doubling cube actions
- **Move**: Player moves and positions  
- **FooterGame**: Game completion, winner
- **FooterMatch**: Match completion, final scores

### Data Types
- Little-endian integers (1, 2, 4, 8 bytes)
- IEEE floats (4, 8 bytes)
- Pascal strings (length-prefixed ANSI)
- Unicode strings (UTF-16LE, null-terminated)
- Boolean values (0/1)
- Delphi TDateTime (8-byte double)

## Testing

Run the comprehensive test suite:

```bash
# Run parser-specific tests
ruby test/test_xgfile_parser.rb

# Run all tests including the new parser
ruby test/test_all.rb

# Use Rake
rake test_xgfile_parser
rake test  # all tests
```

### Test Coverage
- 21 test methods
- 68 assertions
- Tests all error conditions
- Tests all record types
- Tests Unicode string handling
- Tests thumbnail extraction
- Tests compression/decompression

## Demonstration

A demonstration script is included:

```bash
# Create and parse a demo file
ruby demo_xgfile_parser.rb

# Parse existing XG files
ruby demo_xgfile_parser.rb game1.xg game2.xg
```

## Implementation Details

### Parser Architecture
- **XGFile class**: Main parser class
- **Error class**: Custom exception with error codes
- **Modular parsing**: Separate methods for each component
- **Stream-based**: Efficient memory usage for large files

### Record Parsing
Each record type has dedicated parsing logic:
- Header validation and field extraction
- Type-specific field parsing
- Raw data preservation for debugging
- Error recovery for unknown record types

### String Handling
- Pascal strings: length byte + ANSI data
- Unicode strings: UTF-16LE with null termination
- Encoding conversion with fallback to hex
- Proper null terminator handling

### Binary Data
- Little-endian byte order throughout
- Proper struct alignment according to Pascal rules
- ZLIB compression/decompression
- Binary stream positioning and seeking

## Compatibility

The parser is designed to be compatible with:
- XG format versions up to 40 (MaxSaveFileVersion)
- All ExtremeGammon file variants
- Both legacy ANSI and modern Unicode strings
- Files with and without thumbnails
- Partial/corrupted files (graceful error handling)

## Integration

The parser integrates seamlessly with existing xgdatatools:
- Uses existing `xgutils` for utilities
- Compatible with `xgstruct` record types
- Follows same error handling patterns
- Maintains same coding style and conventions

## Performance

- Efficient binary parsing with minimal memory allocation
- Stream-based processing for large files
- Single-pass parsing with no temporary files
- Optional thumbnail extraction
- Lazy evaluation where possible