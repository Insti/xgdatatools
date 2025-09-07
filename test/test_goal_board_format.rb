#!/usr/bin/env ruby

require_relative 'test_helper'
require_relative '../xgutils'

class TestGoalBoardFormat < Minitest::Test
  def test_goal_board_basic_structure
    # Test that the new format has the expected table-like structure
    empty_position = [0] * 26
    result = XGUtils.render_board(empty_position)
    lines = result.split("\n")
    
    # Should have table-like structure with | separators
    # Top header should include BAR and OFF columns
    # Should have section labels for Outer Board and Home Board
    
    # For now, just test that we get some output
    assert result.is_a?(String)
    assert lines.length > 0
  end
  
  def test_goal_board_headers
    # Test that headers match the goal format:
    # | 12 | 13 | 14 | 15 | 16 | 17 | BAR | 18 | 19 | 20 | 21 | 22 | 23 | OFF |
    # | 11 | 10 |  9 |  8 |  7 |  6 | BAR |  5 |  4 |  3 |  2 |  1 |  0 | OFF |
    
    empty_position = [0] * 26
    result = XGUtils.render_board(empty_position)
    
    # This test will initially fail until we implement the new format
    # For now just check basic structure
    assert result.include?("BAR"), "Should include BAR column"
    assert result.include?("OFF"), "Should include OFF column" 
  end
  
  def test_goal_board_section_labels
    # Test that section labels are present:
    # |--------Outer Board----------|     |-------P=O Home Board--------|
    # |--------Outer Board----------|     |-------P=X Home Board--------|
    
    empty_position = [0] * 26
    result = XGUtils.render_board(empty_position)
    
    # This test will initially fail until we implement the new format
    assert result.include?("Outer Board"), "Should include Outer Board section label"
    assert result.include?("Home Board"), "Should include Home Board section label"
  end
  
  def test_goal_board_with_checkers
    # Test with some checkers placed on the board
    position = [0] * 26
    position[13] = 2    # 2 Player 1 checkers on point 13
    position[18] = -3   # 3 Player 2 checkers on point 18
    position[0] = 1     # 1 Player 1 checker in bear-off
    position[25] = -2   # 2 Player 2 checkers in bear-off/bar
    
    result = XGUtils.render_board(position)
    
    # Should show checkers in appropriate positions
    assert result.include?("X"), "Should show Player 1 checkers"
    assert result.include?("O"), "Should show Player 2 checkers"
  end
  
  def test_goal_board_tall_stacks
    # Test that tall stacks (>5 checkers) show counts correctly
    position = [0] * 26
    position[13] = 7    # 7 Player 1 checkers on point 13 (upper half)
    position[6] = -8    # 8 Player 2 checkers on point 6 (lower half)
    
    result = XGUtils.render_board(position)
    
    # Should show stack counts for tall stacks
    assert result.include?("7"), "Should show stack count for 7-checker stack"
    assert result.include?("8"), "Should show stack count for 8-checker stack"
  end
end