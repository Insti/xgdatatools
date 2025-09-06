# xgdatatools
Tools to work with eXtreme Gammon xg-files

This is an AI translation to ruby of the original Python files.
Further work done by @insti to add test coverage and make it work with ruby.

## New Features

### XGFileParser - Complete From-Scratch XG File Parser

A new comprehensive parser has been added that can parse .xg files completely from scratch according to the XGFormat specification:

- **Complete file parsing**: Handles the full DirectX RichGameFormat container
- **Header validation**: Validates magic numbers and file structure  
- **Thumbnail extraction**: Extracts embedded JPEG thumbnails
- **Game record parsing**: Parses all record types (HeaderMatch, HeaderGame, Cube, Move, etc.)
- **Unicode support**: Proper UTF-16LE string handling
- **Comprehensive testing**: 21 test cases with 68 assertions

```ruby
require_relative "xgfile_parser"

parser = XGFileParser::XGFile.new("game.xg")
parser.parse

puts "Game: #{parser.header['GameName']}"
puts "Players: #{parser.header['SaveName']}" 
puts "Records: #{parser.game_records.size}"
```

See [XGFILEPARSER_README.md](XGFILEPARSER_README.md) for detailed documentation.

## Usage

### Demonstration
```bash
# Demo the new XG file parser
ruby demo_xgfile_parser.rb

# Parse existing XG files  
ruby demo_xgfile_parser.rb game1.xg game2.xg
```

### Testing
```bash
# Run all tests
rake test

# Run specific parser tests
rake test_xgfile_parser
```


-----
These are the tools that Michael Petch once wrote.
It is not a fork, since Michael's git repo seems to be down.

The files here are rather a copy of the files which was posted
to the GNU Backgammon mailinglist in August 2022. There is hence
no history and maybe the repo is not even complete with all files
from Michael.

All credit should go to Michael Petch! (A great guy!)
-----

There is some documentation about the xg format at [this page](https://www.extremegammon.com/XGformat.aspx).

