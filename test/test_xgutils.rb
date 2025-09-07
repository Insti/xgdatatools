require_relative "test_helper"
require_relative "../xgutils"

class TestXGUtils < Minitest::Test
  include TestHelper

  def test_streamcrc32_with_full_stream
    # Test CRC32 calculation on full stream
    test_data = "Hello, World!"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream)
    expected_crc = Zlib.crc32(test_data) & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_numbytes
    # Test CRC32 calculation with specific byte count
    test_data = "Hello, World! Extra data that should be ignored"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, numbytes: 13)
    expected_crc = Zlib.crc32("Hello, World!") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_startpos
    # Test CRC32 calculation with start position
    test_data = "Ignore this part. Hello, World!"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, startpos: 18)
    expected_crc = Zlib.crc32("Hello, World!") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_startpos_and_numbytes
    # Test CRC32 calculation with both start position and byte count
    test_data = "Ignore this. Hello, World! Ignore this too."
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, startpos: 13, numbytes: 13)
    expected_crc = Zlib.crc32("Hello, World!") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_custom_blksize
    # Test CRC32 calculation with custom block size
    test_data = "A" * 1000  # Large data to test chunking
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, blksize: 100)
    expected_crc = Zlib.crc32(test_data) & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_empty_stream
    # Test CRC32 calculation on empty stream
    stream = StringIO.new("")

    crc = XGUtils.streamcrc32(stream)
    expected_crc = Zlib.crc32("") & 0xffffffff

    assert_equal expected_crc, crc
  end

  def test_streamcrc32_preserves_position
    # Test that stream position is preserved
    test_data = "Hello, World!"
    stream = StringIO.new(test_data)
    stream.seek(5)  # Move to middle of stream

    XGUtils.streamcrc32(stream)
    assert_equal 5, stream.tell  # Position should be restored
  end

  def test_utf16intarraytostr_basic
    # Test basic UTF16 to string conversion
    int_array = [72, 101, 108, 108, 111, 0]  # "Hello" followed by null terminator
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Hello", result
  end

  def test_utf16intarraytostr_with_special_chars
    # Test with special characters
    int_array = [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33, 0]  # "Hello, World!"
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Hello, World!", result
  end

  def test_utf16intarraytostr_null_array
    # Test with empty array
    int_array = [0]  # Just null terminator
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "", result
  end

  def test_utf16intarraytostr_no_null_terminator
    # Test array without null terminator
    int_array = [72, 101, 108, 108, 111]  # "Hello" without null
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Hello", result
  end

  def test_utf16intarraytostr_multiple_nulls
    # Test array with multiple nulls (should stop at first)
    int_array = [72, 101, 0, 108, 108, 111, 0]  # "He" then null
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "He", result
  end

  def test_delphidatetimeconv_basic
    # Test basic Delphi datetime conversion
    delphi_datetime = 0.0  # Dec 30, 1899
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(1899, 12, 30), result
  end

  def test_delphidatetimeconv_with_days
    # Test conversion with days
    delphi_datetime = 1.0  # Dec 31, 1899
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(1899, 12, 31), result
  end

  def test_delphidatetimeconv_with_fractional_day
    # Test conversion with fractional day (time component)
    delphi_datetime = 0.5  # Dec 30, 1899 12:00:00
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    expected = DateTime.new(1899, 12, 30, 12, 0, 0)
    assert_equal expected, result
  end

  def test_delphidatetimeconv_with_days_and_time
    # Test conversion with both days and time
    delphi_datetime = 1.25  # Dec 31, 1899 06:00:00
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    expected = DateTime.new(1899, 12, 31, 6, 0, 0)
    assert_equal expected, result
  end

  def test_delphidatetimeconv_year_2000
    # Test Y2K and beyond
    days_to_2000 = (DateTime.new(2000, 1, 1) - DateTime.new(1899, 12, 30)).to_i
    delphi_datetime = days_to_2000.to_f
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(2000, 1, 1), result
  end

  def test_delphishortstrtostr_basic
    # Test basic short string conversion
    shortstring_bytes = [5, 72, 101, 108, 108, 111]  # Length 5, "Hello"
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal "Hello", result
  end

  def test_delphishortstrtostr_empty_string
    # Test empty string
    shortstring_bytes = [0]  # Length 0
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal "", result
  end

  def test_delphishortstrtostr_max_length
    # Test maximum length string (255 chars)
    test_string = "A" * 255
    shortstring_bytes = [255] + test_string.bytes
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal test_string, result
  end

  def test_delphishortstrtostr_with_special_chars
    # Test with special characters
    test_string = "Héllo, Wørld!"
    shortstring_bytes = [test_string.bytesize] + test_string.bytes
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal test_string, result
  end

  def test_delphishortstrtostr_longer_buffer
    # Test when buffer is longer than specified length
    shortstring_bytes = [5, 72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100]  # Length 5, but more data
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal "Hello", result  # Should only read 5 characters
  end

  def test_delphishortstrtostr_utf8_encoding
    # Test that result is properly UTF-8 encoded
    shortstring_bytes = [5, 72, 101, 108, 108, 111]  # "Hello"
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_streamcrc32_zero_bytes
    # Test CRC32 calculation with zero bytes
    test_data = "Hello, World!"
    stream = StringIO.new(test_data)
    stream.seek(5)  # Move to middle

    crc = XGUtils.streamcrc32(stream, numbytes: 0)
    expected_crc = Zlib.crc32("") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 5, stream.tell  # Position should be restored
  end

  def test_utf16intarraytostr_empty_array
    # Test with completely empty array
    int_array = []
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "", result
  end

  def test_delphishortstrtostr_buffer_shorter_than_length
    # Test when buffer is shorter than specified length
    shortstring_bytes = [10, 65, 66, 67]  # Says length 10 but only 3 chars

    # This should not crash and handle gracefully
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    # Should get the available characters
    assert_equal "ABC", result
  end

  # Additional edge case tests for better coverage
  def test_streamcrc32_with_small_blksize_and_large_data
    # Test with very small block size and larger data
    test_data = "A" * 1000
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, blksize: 1)  # 1 byte at a time
    expected_crc = Zlib.crc32(test_data) & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Position should be restored
  end

  def test_streamcrc32_with_exact_numbytes_boundary
    # Test with numbytes exactly matching data size
    test_data = "Exact match"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, numbytes: test_data.length)
    expected_crc = Zlib.crc32(test_data) & 0xffffffff

    assert_equal expected_crc, crc
  end

  def test_utf16intarraytostr_with_high_values
    # Test with values that might cause encoding issues
    int_array = [72, 233, 108, 108, 111, 0]  # "Héllo" with accented character
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Héllo", result
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_delphidatetimeconv_negative_value
    # Test with negative Delphi datetime (before base date)
    delphi_datetime = -1.0  # Dec 29, 1899
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(1899, 12, 29), result
  end

  def test_delphidatetimeconv_precise_time
    # Test with very precise fractional time
    delphi_datetime = 1.999988426  # Close to end of day
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    # Should be Dec 31, 1899 near end of day
    assert_equal 1899, result.year
    assert_equal 12, result.month
    assert_equal 31, result.day
    assert result.hour >= 23  # Should be late in the day
  end

  def test_delphishortstrtostr_with_zero_bytes
    # Test with embedded zero bytes
    shortstring_bytes = [8, 65, 0, 66, 0, 67, 0, 68, 0]  # "A\0B\0C\0D\0"
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    # Should include the zero bytes as part of the string
    assert_equal "A\0B\0C\0D\0", result
  end

  def test_delphishortstrtostr_maximum_valid_length
    # Test with length 254 (close to max but valid)
    test_string = "X" * 254
    shortstring_bytes = [254] + test_string.bytes
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal test_string, result
  end

  def test_utf16intarraytostr_single_character
    # Test with single character
    int_array = [65, 0]  # "A" followed by null
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "A", result
  end

  def test_streamcrc32_edge_case_with_position_restore
    # Test that stream position is correctly restored even with errors
    test_data = "Hello World"
    stream = StringIO.new(test_data)
    original_pos = 5
    stream.seek(original_pos)

    # Test with invalid parameters that should still restore position
    crc = XGUtils.streamcrc32(stream, startpos: 0, numbytes: test_data.length)
    
    # Position should be restored to original
    assert_equal original_pos, stream.tell
    
    # CRC should be correct
    expected_crc = Zlib.crc32(test_data) & 0xffffffff
    assert_equal expected_crc, crc
  end

  def test_delphidatetimeconv_fraction_boundary
    # Test with fraction exactly at 0.5 (noon)
    delphi_datetime = 0.5
    result = XGUtils.delphidatetimeconv(delphi_datetime)
    
    assert_equal 1899, result.year
    assert_equal 12, result.month
    assert_equal 30, result.day
    assert_equal 12, result.hour
    assert_equal 0, result.min
    assert_equal 0, result.sec
  end

  def test_utf16intarraytostr_with_invalid_encoding_recovery
    # Test behavior with characters that might have encoding issues
    # Using values that are valid but might test edge cases
    int_array = [0x41, 0x42, 0x43, 0]  # Simple ASCII
    result = XGUtils.utf16intarraytostr(int_array)
    
    assert_equal "ABC", result
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_streamcrc32_with_startpos_at_end
    # Test CRC calculation when startpos is at the end of stream
    test_data = "Test data"
    stream = StringIO.new(test_data)
    
    # Start position at end of stream
    crc = XGUtils.streamcrc32(stream, startpos: test_data.length)
    
    # Should get CRC of empty data
    expected_crc = Zlib.crc32("") & 0xffffffff
    assert_equal expected_crc, crc
  end

  def test_delphishortstrtostr_with_length_zero_boundary
    # Test exactly at boundary conditions
    shortstring_bytes = [0, 65, 66, 67]  # Length 0, followed by data
    result = XGUtils.delphishortstrtostr(shortstring_bytes)
    
    assert_equal "", result
  end

  # Test module is properly defined
  def test_module_exists
    assert defined?(XGUtils)
    assert XGUtils.is_a?(Module)
  end

  # Test all methods are module methods
  def test_module_methods
    expected_methods = [:streamcrc32, :utf16intarraytostr, :delphidatetimeconv, :delphishortstrtostr, :render_board]

    expected_methods.each do |method|
      assert XGUtils.respond_to?(method), "XGUtils should respond to #{method}"
    end
  end

  # Tests for render_board method
  def test_render_board_invalid_input
    # Test with nil input
    result = XGUtils.render_board(nil)
    assert_equal "Invalid position: must be array of 26 integers", result

    # Test with wrong size array
    result = XGUtils.render_board([1, 2, 3])
    assert_equal "Invalid position: must be array of 26 integers", result

    # Test with array of wrong size
    result = XGUtils.render_board([0] * 25)
    assert_equal "Invalid position: must be array of 26 integers", result
  end

  def test_render_board_empty_position
    # Test with empty board (all zeros)
    position = [0] * 26
    result = XGUtils.render_board(position)

    # Should contain the basic board structure (goal_board format)
    assert result.include?("|"), "Should contain table separators"
    assert result.include?("BAR"), "Should contain BAR column"
    assert result.include?("OFF"), "Should contain OFF column"
    assert result.include?("Outer Board"), "Should contain section label"
    assert result.include?("Home Board"), "Should contain section label"
    
    # Point numbers should be present (1-24 in goal_board format)
    (1..24).each do |point|
      assert result.include?(sprintf("%2d", point)), "Should contain point #{point}"
    end
  end

  def test_render_board_starting_position
    # Test with a typical backgammon starting position
    # Standard starting position has 2 checkers on 24, 5 on 13, 3 on 8, 5 on 6 for player 1
    # And opposite for player 2
    position = [0] * 26
    
    # Player 1 checkers (positive values)
    position[24] = 2   # 2 checkers on point 24
    position[13] = 5   # 5 checkers on point 13 
    position[8] = 3    # 3 checkers on point 8
    position[6] = 5    # 5 checkers on point 6
    
    # Player 2 checkers (negative values)
    position[1] = -2   # 2 checkers on point 1
    position[12] = -5  # 5 checkers on point 12
    position[17] = -3  # 3 checkers on point 17
    position[19] = -5  # 5 checkers on point 19

    result = XGUtils.render_board(position)

    # Should contain checkers representation
    assert result.include?("X"), "Should contain Player 1 checkers"
    assert result.include?("O"), "Should contain Player 2 checkers"
    
    # Should not crash and return valid string
    assert result.is_a?(String)
    assert result.length > 100, "Should return substantial output"
  end

  def test_render_board_with_bear_off
    # Test with checkers in bear-off areas
    position = [0] * 26
    position[0] = 5    # Player 1 bear-off
    position[25] = -3  # Player 2 bear-off
    
    result = XGUtils.render_board(position)
    
    # Should show bear-off checkers in OFF columns (goal_board format)
    assert result.include?("X"), "Should show Player 1 checkers in bear-off"
    assert result.include?("O"), "Should show Player 2 checkers in bear-off"
    # In goal_board format, bear-off is shown visually in OFF columns, not as text
    lines = result.split("\n")
    off_columns = lines.select { |line| line.include?("OFF") || line.include?("X") || line.include?("O") }
    assert off_columns.length > 0, "Should have OFF columns with checkers"
  end

  def test_render_board_with_many_checkers
    # Test with stacks higher than 5 checkers
    position = [0] * 26
    position[1] = 10   # 10 Player 1 checkers on point 1 (lower half)
    position[24] = -8  # 8 Player 2 checkers on point 24 (upper half)
    position[13] = 7   # 7 Player 1 checkers on point 13 (upper half)
    position[6] = -6   # 6 Player 2 checkers on point 6 (lower half)
    
    result = XGUtils.render_board(position)
    
    # Should handle high stacks gracefully
    assert result.is_a?(String)
    assert result.include?("X"), "Should show Player 1 checkers"
    assert result.include?("O"), "Should show Player 2 checkers"
    
    # Verify stack counts are displayed for tall stacks
    assert result.include?("10"), "Should show count 10 for point 1 stack"
    assert result.include?(" 8"), "Should show count 8 for point 24 stack" 
    assert result.include?(" 7"), "Should show count 7 for point 13 stack"
    assert result.include?(" 6"), "Should show count 6 for point 6 stack"
  end

  def test_render_board_mixed_positions
    # Test with various checker positions
    position = [0] * 26
    
    # Mix of positions for both players
    position[1] = 3
    position[5] = -2
    position[12] = 1
    position[18] = -4
    position[23] = 2
    position[0] = 1    # Bear-off
    position[25] = -1  # Bear-off
    
    result = XGUtils.render_board(position)
    
    # Basic validation that board renders (goal_board format)
    assert result.is_a?(String)
    assert result.include?("|"), "Should have table structure"
    assert result.include?("BAR"), "Should have BAR column"
    assert result.include?("OFF"), "Should have OFF column"
    # Bear-off shown visually in OFF columns in goal_board format
    assert result.include?("X"), "Should show Player 1 checkers"
    assert result.include?("O"), "Should show Player 2 checkers"
  end

  def test_render_board_structure
    # Test that the board has the expected structure (goal_board format)
    position = [0] * 26
    result = XGUtils.render_board(position)
    
    lines = result.split("\n")
    
    # Should have multiple lines
    assert lines.length > 10, "Should have multiple lines"
    
    # Should have table structure with headers
    assert lines.first.include?("|"), "First line should be table header"
    assert lines.first.include?("BAR"), "First line should include BAR column"
    assert lines.first.include?("OFF"), "First line should include OFF column"
    
    # Should have section labels
    section_lines = lines.select { |line| line.include?("Outer Board") || line.include?("Home Board") }
    assert section_lines.length >= 2, "Should have section labels"
  end

  def test_render_board_point_numbering
    # Test that point numbers are correctly displayed (goal_board format)
    position = [0] * 26
    result = XGUtils.render_board(position)
    
    # All points (1-24) should be present in goal_board format
    (1..24).each do |point|
      assert result.include?(sprintf("%2d", point)), "Should include point #{point}"
    end
    
    # BAR and OFF columns should be present
    assert result.include?("BAR"), "Should include BAR column"
    assert result.include?("OFF"), "Should include OFF column"
  end

  def test_render_board_tall_stack_positioning
    # Test specific positioning of stack counts for tall stacks
    position = [0] * 26
    
    # Create different tall stacks to test positioning
    position[13] = 9    # Upper half - should show count in innermost row
    position[1] = 8     # Lower half - should show count in topmost row
    position[18] = -7   # Upper half, player 2
    position[6] = -6    # Lower half, player 2
    
    result = XGUtils.render_board(position)
    lines = result.split("\n")
    
    # Based on the goal_board structure:
    # Line 6: Upper half innermost row (before middle separator)
    # Line 8: Lower half topmost row (after middle separator)
    
    # Upper half: stack count should be in innermost row
    upper_innermost_line = lines[6]
    assert upper_innermost_line.include?("9"), "Point 13 count should be in innermost row of upper half"
    assert upper_innermost_line.include?("7"), "Point 18 count should be in innermost row of upper half"
    
    # Lower half: stack count should be in topmost row  
    lower_topmost_line = lines[8]
    assert lower_topmost_line.include?("8"), "Point 1 count should be in topmost row of lower half"
    assert lower_topmost_line.include?("6"), "Point 6 count should be in topmost row of lower half"
    
    # Verify that normal stacks (≤5) still work correctly
    position[2] = 3
    position[14] = -4
    result2 = XGUtils.render_board(position)
    
    assert result2.include?("X"), "Should still show normal stacks"
    assert result2.include?("O"), "Should still show normal stacks"
  end

  def test_render_dice
    # Test render_dice method with valid dice arrays
    result = XGUtils.render_dice([4, 6])
    assert_equal "4 6", result

    result = XGUtils.render_dice([1, 1])
    assert_equal "1 1", result

    result = XGUtils.render_dice([6, 3])
    assert_equal "6 3", result

    # Test with invalid inputs
    result = XGUtils.render_dice(nil)
    assert_equal "", result

    result = XGUtils.render_dice([])
    assert_equal "", result

    result = XGUtils.render_dice([1])
    assert_equal "", result

    result = XGUtils.render_dice([1, 2, 3])
    assert_equal "", result

    result = XGUtils.render_dice("not an array")
    assert_equal "", result
  end
end
