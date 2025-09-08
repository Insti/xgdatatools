# XGDataTools Copilot Instructions

## Project Overview

XGDataTools is a Ruby toolkit for working with eXtreme Gammon (XG) file formats used in backgammon analysis software.

## Domain Context

- **eXtreme Gammon**: Professional backgammon analysis software
- **XG files**: Binary format with game data, positions, analysis, and rollouts
- **File format**: Complex nested binary structures with ZLib compression
- **Endianness**: Little-endian byte order throughout

## Architecture

- The xg File format is documented in XGFile_format.txt

### Core Modules

- **`xgutils.rb`**: CRC32, date conversion, UTF16 string handling
- **`xgimport.rb`**: File segmentation and stream processing  
- **`xgstruct.rb`**: Hash-based record classes with binary deserialization
- **`xgzarc.rb`**: ZLib archive handling
- **`extractxgdata.rb`**: CLI application for data extraction

### Ruby Style
- Use modules for namespacing
- Snake_case naming conventions
- Explicit binary mode for file I/O

### Testing
- Use TDD, write tests first
- **Minitest framework** for all tests
- Use test helpers for common operations
- Ensure 100% test coverage for statements and branches
- **ALWAYS run tests before making changes and after completing changes**
- All tests must pass before any code submission

```ruby
class TestXGUtils < Minitest::Test
  def test_method_with_valid_input
    result = XGUtils.method(valid_input)
    assert_equal expected_result, result
  end
  
  def test_method_with_error
    assert_raises(StandardError) do
      XGUtils.method(invalid_input)
    end
  end
end
```

#### Test Commands
```bash
# Run all tests
rake test
# OR
ruby test/test_all.rb

# Run specific test suite
rake test_xgutils
rake test_xgstruct
rake test_xgzarc
# etc.

# Run with coverage (if SimpleCov available)
rake coverage
```

### Code Formatting
- **MUST use standardrb for all Ruby code formatting**
- Format code before any submission
- All code must pass standardrb linting

#### Installing standardrb
```bash
gem install standard --user-install

# Add gem bin directory to PATH (if needed)
export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"
# Or for other systems:
# export PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"
```

#### Formatting Commands
```bash
# Check formatting (lint)
standardrb

# Auto-fix formatting issues
standardrb --fix

# Fix unsafe issues (use with caution)
standardrb --fix-unsafely

# Check specific files
standardrb path/to/file.rb

# Fix specific files
standardrb --fix path/to/file.rb
```

**Note**: Some style issues cannot be auto-fixed safely. As long as tests pass, remaining style warnings are acceptable but should be addressed when possible.

### Dependencies
- **Standard library only** (no external gems)
- Exception: SimpleCov for test coverage
- Exception: standardrb for code formatting
- Core libraries: `zlib`, `date`, `tempfile`, `fileutils`

## Key Considerations

- **Binary data**: Always use little-endian format (`<`) in pack/unpack
- **Stream processing**: Handle large files efficiently 
- **Hash inheritance**: Support both `obj['key']` and `obj.key` syntax
- **Error handling**: Provide meaningful context with filenames
- **Memory efficiency**: Use streaming for large file operations

## Development Workflow

### Before Making Changes
1. **Verify tests pass**: Run `rake test` to ensure all tests pass
2. **Check current formatting**: Run `standardrb` to check code style

### During Development
1. **Write tests first** (TDD approach)
2. **Make minimal code changes**
3. **Run tests frequently** to verify changes work
4. **Format code regularly** with `standardrb --fix`

### Before Submitting Changes
1. **Run all tests**: `rake test` - must have 0 failures, 0 errors
2. **Format all code**: `standardrb --fix` - fix any style issues
3. **Final check**: `standardrb` - should report no offenses
4. **Verify tests still pass**: Final `rake test` run

### Required Commands for Every Change
```bash
# 1. Test before changes
rake test

# 2. Make your changes...

# 3. Format code
standardrb --fix

# 4. Test after changes  
rake test

# 5. Final formatting check
standardrb
```

**All steps must pass before submitting any code changes.**
