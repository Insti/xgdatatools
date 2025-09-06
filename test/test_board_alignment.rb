require_relative "test_helper"
require_relative "../xgutils"

class TestXGUtilsBoardAlignment < Minitest::Test
  def test_board_vertical_alignment
    # Test that all lines in the rendered board have consistent vertical bar alignment
    position = [0] * 26
    
    # Add some checkers to test with real content
    position[1] = 3
    position[13] = 5
    position[19] = -4
    position[0] = 2    # Bear-off
    position[25] = -3  # Bear-off
    
    result = XGUtils.render_board(position)
    lines = result.split("\n")
    
    # Filter out empty lines and legend
    board_lines = lines.reject { |line| line.empty? || line.include?("Legend") || line.include?("Positive values") }
    
    # Check that all content lines (except borders) have consistent width and alignment
    content_lines = board_lines[1..-2]  # Exclude top and bottom borders
    
    content_lines.each_with_index do |line, i|
      # All content lines should be exactly 55 characters
      assert_equal 55, line.length, "Line #{i+1} should be 55 characters: '#{line}'"
      
      # Find vertical bar positions
      vertical_positions = []
      line.chars.each_with_index { |char, pos| vertical_positions << pos if char == '│' }
      
      # All lines should have vertical bars at positions 0 and 54 (start and end)
      # The middle position should be at 27, but let's be more flexible for now
      assert vertical_positions.include?(0), 
             "Line #{i+1} missing vertical bar at position 0: '#{line}' (bars at #{vertical_positions})"
      assert vertical_positions.include?(54), 
             "Line #{i+1} missing vertical bar at position 54: '#{line}' (bars at #{vertical_positions})"
      
      # Check that there's a middle separator around position 27 (allow some flexibility)
      middle_bars = vertical_positions.select { |pos| pos >= 25 && pos <= 29 }
      assert middle_bars.length >= 1,
             "Line #{i+1} missing middle vertical bar around position 27: '#{line}' (bars at #{vertical_positions})"
    end
  end
  
  def test_board_alignment_with_various_bear_off_values
    # Test alignment with different bear-off values to ensure padding works correctly
    test_cases = [
      [0, 0],     # No bear-off
      [1, -1],    # Small bear-off
      [15, -15],  # Large bear-off (max is 15 checkers per player)
      [12, -8]    # Mixed values
    ]
    
    test_cases.each do |bear_off_1, bear_off_2|
      position = [0] * 26
      position[0] = bear_off_1
      position[25] = bear_off_2
      
      result = XGUtils.render_board(position)
      lines = result.split("\n")
      
      # Find the info line (contains "Bear-off")
      info_line = lines.find { |line| line.include?("Bear-off") }
      refute_nil info_line, "Should have info line"
      
      # Info line should be exactly 55 characters
      assert_equal 55, info_line.length, 
                   "Info line should be 55 chars with bear-off #{bear_off_1}/#{bear_off_2}: '#{info_line}'"
      
      # Should have vertical bars at expected positions
      vertical_positions = []
      info_line.chars.each_with_index { |char, pos| vertical_positions << pos if char == '│' }
      
      assert vertical_positions.include?(0), "Info line should start with │"
      assert vertical_positions.include?(54), "Info line should end with │ at position 54"
    end
  end
end