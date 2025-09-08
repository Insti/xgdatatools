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

### XG Binary Component Extraction

Extract XG file components into individual binary files with descriptive naming:

```bash
# Extract components to current directory
ruby xgbinaryextract.rb game.xg

# Extract to specific directory  
ruby xgbinaryextract.rb -d /output/path game.xg

# Extract multiple files with verbose output
ruby xgbinaryextract.rb -v debug -d /tmp *.xg
```

This creates binary files with the naming pattern `[type]_[number]_[subtype].bin`:
- `gdf_hdr_001_header.bin` - Game Data Format header
- `gdf_image_001_thumbnail.bin` - Embedded thumbnail (if present)
- `xg_gamehdr_001_header.bin` - XG game header
- `xg_gamefile_001_data.bin` - Game file data
- `xg_rollouts_001_data.bin` - Rollout data
- `xg_comment_001_text.bin` - Comments

### Demonstration
```bash
# Demo the new XG file parser
ruby demo_xgfile_parser.rb

# Parse existing XG files  
ruby demo_xgfile_parser.rb game1.xg game2.xg

# Demo the backgammon board ASCII renderer
ruby demo_board_render.rb

# Demo board rendering with parsed move data
ruby demo_board_with_move.rb
```

### Backgammon Board Rendering

A utility method has been added to render ASCII representations of backgammon boards from position arrays:

```ruby
require_relative "xgutils"

# Create a position array (26 elements representing the board)
position = [0] * 26

# Set up a simple position
position[1] = 2    # 2 Player 1 checkers on point 1
position[24] = -3  # 3 Player 2 checkers on point 24
position[0] = 1    # 1 Player 1 checker in bear-off

# Render the board
puts XGUtils.render_board(position)
```

The position array follows the XG PositionEngine format:
- **Index 0**: Opponent's bar (negative values for opponent checkers on bar)
- **Indices 1-24**: The 24 points on the board (standard backgammon numbering)
- **Index 25**: Player's bar (positive values for player checkers on bar)
- **Positive values**: Player's checkers
- **Negative values**: Opponent's checkers
- **Bear-off checkers**: Handled separately from this positional array

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

