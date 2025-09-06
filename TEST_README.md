# XGDataTools Test Suite

This directory contains comprehensive minitest tests for the XGDataTools Ruby modules.

## Test Files

- `test_helper.rb` - Common test utilities and helpers
- `test_xgutils.rb` - Tests for XGUtils module utility functions
- `test_xgstruct.rb` - Tests for XGStruct module classes
- `test_xgzarc.rb` - Tests for XGZarc module archive functionality
- `test_xgimport.rb` - Tests for XGImport module import functionality
- `test_all.rb` - Master test runner that executes all tests
- `Rakefile` - Rake tasks for running tests

## Running Tests

### Run All Tests
```bash
# Using the master test runner
ruby test_all.rb

# Using Rake
rake test
# or simply
rake
```

### Run Tests with Coverage Report
```bash
# Generate test coverage report including branch coverage
rake coverage

# This will run all tests and generate an HTML coverage report
# in the coverage/ directory. Open coverage/index.html to view the report.
```

### Run Individual Test Files
```bash
ruby test_xgutils.rb
ruby test_xgstruct.rb  
ruby test_xgzarc.rb
ruby test_xgimport.rb

# Or using Rake
rake test_xgutils
rake test_xgstruct
rake test_xgzarc
rake test_xgimport
```

## Test Coverage

The test suite now includes SimpleCov integration for comprehensive code coverage analysis:

- **Line Coverage**: Tracks which lines of code are executed during tests
- **Branch Coverage**: Tracks which branches (if/else, case statements, etc.) are taken
- **HTML Reports**: Interactive coverage reports generated in `coverage/index.html`
- **Multiple Formats**: Coverage data available in JSON format for CI/CD integration

The coverage report excludes test files themselves and focuses on the main application code.

### Test Suite Coverage by Module

The test suite provides comprehensive coverage of all modules:

### XGUtils Module (27 tests, 37 assertions)
- `streamcrc32` - CRC32 calculation on streams with various parameters
- `utf16intarraytostr` - UTF16 integer array to string conversion  
- `delphidatetimeconv` - Delphi datetime to Ruby DateTime conversion
- `delphishortstrtostr` - Delphi shortstring to Ruby string conversion

### XGStruct Module (41 tests, 108 assertions)
- `GameDataFormatHdrRecord` - Game data format header records
- `TimeSettingRecord` - Time setting records
- `EvalLevelRecord` - Evaluation level records
- `UnimplementedEntry` - Generic unimplemented entries
- `GameFileRecord` - Game file records
- `RolloutFileRecord` - Rollout file records
- `HeaderMatchEntry` - Header match entries

### XGZarc Module (24 tests, 83 assertions)
- `Error` - Custom error class
- `ArchiveRecord` - Archive record functionality
- `FileRecord` - File record functionality
- `ZlibArchive` - Main archive class structure

### XGImport Module (25 tests, 76 assertions)
- `Error` - Custom error class
- `Import` - Main import functionality
- `Import::Segment` - File segment handling

## Test Features

- **Hash-like behavior testing** - Tests dynamic method generation for Hash-based classes
- **Error condition testing** - Tests exception handling and error cases
- **Edge case coverage** - Tests boundary conditions, empty inputs, invalid data
- **Stream operations** - Tests file I/O and stream processing
- **Class initialization** - Tests constructor behavior with various parameters
- **Method missing handling** - Tests dynamic method dispatch

## Total Coverage

- **117 total test cases**
- **304 total assertions**
- **0 failures, 0 errors, 0 skips**

The test suite achieves comprehensive coverage of all public methods, classes, and functionality in the XGDataTools codebase.