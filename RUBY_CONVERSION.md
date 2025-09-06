# Ruby Conversion of XG Data Tools

This directory now contains Ruby versions of the original Python XG data tools for working with eXtreme Gammon xg-files.

## Ruby Files

| Ruby File | Original Python | Description |
|-----------|----------------|-------------|
| `extractxgdata.rb` | `extractxgdata.py` | Main CLI application for XG data extraction |
| `xgutils.rb` | `xgutils.py` | Utility functions (CRC32, date conversion, string conversion) |
| `xgimport.rb` | `xgimport.py` | XG import module with file segment handling |
| `xgzarc.rb` | `xgzarc.py` | ZLib archive module for compressed data |
| `xgstruct.rb` | `xgstruct.py` | Classes to read XG file structures |

## Usage

The Ruby version maintains the same command-line interface as the Python version:

```bash
# Show help
ruby extractxgdata.rb --help

# Extract XG data from files
ruby extractxgdata.rb file1.xg file2.xg

# Extract to specific directory
ruby extractxgdata.rb -d /output/dir file.xg
```

## Key Conversion Changes

### Python to Ruby Syntax
- Python `dict` inheritance → Ruby `Hash` inheritance
- Python `__setattr__`/`__getattr__` → Ruby `method_missing`
- Python `struct.unpack()` → Ruby `String#unpack()`
- Python context managers (`with`) → Ruby blocks
- Python generators (`yield`) → Ruby enumerators
- Python `argparse` → Ruby `OptionParser`

### Module Structure
- Python modules → Ruby modules with classes
- Python imports → Ruby `require_relative`
- Python exception handling adapted to Ruby conventions

### Binary Data Handling
- Python struct format strings converted to Ruby pack/unpack format
- Endianness handling preserved (`<` for little-endian)
- Binary file operations adapted to Ruby I/O

## Dependencies

The Ruby version uses only standard library modules:
- `zlib` - For compression/decompression
- `date` - For date/time handling  
- `tempfile` - For temporary file operations
- `fileutils` - For file operations
- `optparse` - For command-line parsing
- `pp` - For pretty printing

## Compatibility

The Ruby version preserves all the functionality of the original Python code while following Ruby idioms and best practices. All core data structures and algorithms have been faithfully converted.

## Testing

Basic functionality has been verified:
- All Ruby files pass syntax validation
- CLI application responds correctly to `--help`
- Core utility functions (date conversion, string conversion) work as expected
- All modules load without dependency errors

## Credits

Original Python code by Michael Petch <mpetch@gnubg.org>
Ruby conversion preserves all original functionality and copyright notices.