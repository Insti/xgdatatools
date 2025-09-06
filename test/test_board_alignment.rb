require_relative "test_helper"
require_relative "../xgutils"

class TestXGUtilsBoardAlignment < Minitest::Test
  def test_board_vertical_alignment
    # Test that all lines in the rendered board have consistent table structure alignment
    position = [0] * 26
    
    # Add some checkers to test with real content
    position[1] = 3
    position[13] = 5
    position[19] = -4
    position[0] = 2    # Bear-off
    position[25] = -3  # Bear-off
    
    result = XGUtils.render_board(position)
    lines = result.split("\n")
    
    # All lines should start and end with | for table structure
    lines.each_with_index do |line, i|
      next if line.empty?
      assert line.start_with?("|"), "Line #{i+1} should start with |: '#{line}'"
      assert line.end_with?("|"), "Line #{i+1} should end with |: '#{line}'"
    end
    
    # Header lines should contain expected elements
    header_lines = lines.select { |line| line.match(/\|\s*\d+\s*\|/) }
    assert header_lines.length >= 2, "Should have top and bottom header lines"
    
    # Should have BAR and OFF columns in headers
    header_lines.each do |header|
      assert header.include?("BAR"), "Header should include BAR column: '#{header}'"
      assert header.include?("OFF"), "Header should include OFF column: '#{header}'"
    end
  end
  
  def test_board_alignment_with_various_bear_off_values
    # Test alignment with different bear-off values in OFF columns
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
      
      # In goal_board format, bear-off is shown visually in OFF columns
      # Verify that table structure is maintained
      off_columns_found = 0
      lines.each do |line|
        off_columns_found += 1 if line.include?("OFF")
      end
      
      assert off_columns_found >= 2, "Should have OFF columns in headers with bear-off #{bear_off_1}/#{bear_off_2}"
      
      # Verify basic table structure consistency
      checker_lines = lines.select { |line| line.match(/\|\s*[XO\d\s]*\s*\|/) && !line.include?("Board") }
      checker_lines.each do |line|
        assert line.start_with?("|"), "Checker line should start with |: '#{line}'"
        assert line.end_with?("|"), "Checker line should end with |: '#{line}'"
      end
    end
  end
end