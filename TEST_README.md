# XGDataTools Test Suite

This directory contains comprehensive minitest tests for the XGDataTools Ruby modules.

## Test Files

- `test_helper.rb` - Common test utilities and helpers (with SimpleCov integration)
- `test_helper_simple.rb` - Simplified test utilities without SimpleCov dependency  
- `test_xgutils.rb` - Tests for XGUtils module utility functions
- `test_xgstruct.rb` - Tests for XGStruct module classes
- `test_xgzarc.rb` - Tests for XGZarc module archive functionality
- `test_xgimport.rb` - Tests for XGImport module import functionality
- `test_extractxgdata.rb` - Tests for extractxgdata.rb command-line tool
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
ruby test/test_xgutils.rb
ruby test/test_xgstruct.rb  
ruby test/test_xgzarc.rb
ruby test/test_xgimport.rb
ruby test/test_extractxgdata.rb

# Or using Rake
rake test_xgutils
rake test_xgstruct
rake test_xgzarc
rake test_xgimport
rake test_extractxgdata
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

### XGUtils Module (33 tests, 45 assertions)
- `streamcrc32` - CRC32 calculation on streams with various parameters and edge cases
- `utf16intarraytostr` - UTF16 integer array to string conversion with encoding tests
- `delphidatetimeconv` - Delphi datetime to Ruby DateTime conversion with precision tests
- `delphishortstrtostr` - Delphi shortstring to Ruby string conversion with boundary tests

### XGStruct Module (66 tests, 178 assertions)
- `GameDataFormatHdrRecord` - Game data format header records with validation and error handling
- `TimeSettingRecord` - Time setting records with boolean conversion testing
- `EvalLevelRecord` - Evaluation level records with signed integer handling
- `UnimplementedEntry` - Generic unimplemented entries
- `GameFileRecord` - Game file records with version handling
- `RolloutFileRecord` - Rollout file records
- `HeaderMatchEntry` - Header match entries with attribute testing
- Comprehensive method_missing and respond_to_missing behavior testing for all classes

### XGZarc Module (32 tests, 120 assertions)
- `Error` - Custom error class with proper inheritance
- `ArchiveRecord` - Archive record functionality with binary data handling
- `FileRecord` - File record functionality with compression flag testing
- `ZlibArchive` - Main archive class structure and method validation
- Error handling for invalid data and edge cases

### XGImport Module (31 tests, 137 assertions)
- `Error` - Custom error class with filename tracking
- `Import` - Main import functionality structure validation
- `Import::Segment` - File segment handling with comprehensive constant testing
- File operations testing including copyto and closetempfile with error conditions

### ExtractXGData Script (30 tests, 92 assertions)
- `parseoptsegments()` - Command line segment parsing with validation
- `directoryisvalid()` - Directory path validation with comprehensive error testing
- Option parser configuration and help text formatting
- File path processing and output filename generation logic
- Error handling patterns and script execution behavior
- Edge cases including empty inputs, case sensitivity, and whitespace handling
- Integration testing with XGImport, XGZarc, and XGStruct modules

## Test Features

- **Hash-like behavior testing** - Tests dynamic method generation for Hash-based classes
- **Error condition testing** - Tests exception handling and error cases
- **Edge case coverage** - Tests boundary conditions, empty inputs, invalid data
- **Stream operations** - Tests file I/O and stream processing
- **Class initialization** - Tests constructor behavior with various parameters
- **Method missing handling** - Tests dynamic method dispatch

## Total Coverage

**Current Status (After Adding ExtractXGData Tests):**
- **Total Tests**: 192 tests (increased from 162)
- **Total Assertions**: 572 assertions (increased from 480) 
- **0 failures, 0 errors, 0 skips**

The test suite now includes comprehensive coverage for the extractxgdata.rb command-line tool with focused testing on:
- Command line argument parsing and validation
- File path processing and output directory handling
- Error handling and edge cases for user input
- Integration with core XGDataTools modules
- Script execution behavior and help text formatting

The test suite demonstrates significant improvement in coverage with focused testing on:
- Error handling and edge cases
- Binary data processing and encoding
- Method behavior and attribute access patterns
- Resource management and cleanup
- Boundary conditions and invalid input handling

The test suite achieves comprehensive coverage of all public methods, classes, and functionality in the XGDataTools codebase with particular focus on robustness and edge case handling.