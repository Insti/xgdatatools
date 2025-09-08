#!/usr/bin/env ruby
#
# Demo script showing the backgammon board renderer in action
#

require_relative "xgutils"

EMPTY_BOARD = [0] * 26

puts "Demo: Backgammon Board ASCII Renderer"
puts "=" * 50

# Example 1: Empty board
puts "1. Empty Board:"
empty_position = [0] * 26
puts XGUtils.render_board(empty_position)

puts "\n" + "=" * 50

# Example 2: Starting position (simplified)
puts "2. Starting Position (simplified):"
starting_position = [0] * 26

# Player 1 checkers (positive values)
starting_position[24] = 2   # 2 checkers on point 24
starting_position[13] = 5   # 5 checkers on point 13
starting_position[8] = 3    # 3 checkers on point 8
starting_position[6] = 5    # 5 checkers on point 6

# Player 2 checkers (negative values)
starting_position[1] = -2   # 2 checkers on point 1
starting_position[12] = -5  # 5 checkers on point 12
starting_position[17] = -3  # 3 checkers on point 17
starting_position[19] = -5  # 5 checkers on point 19

puts XGUtils.render_board(starting_position)

puts "\n" + "=" * 50

# Example 3: Mid-game position with bear-off
puts "3. Mid-game Position with Bear-off:"
midgame_position = [0] * 26

# Some checkers in bear-off
midgame_position[0] = 3     # Player 1 bear-off
midgame_position[25] = -2   # Player 2 bear-off

# Remaining checkers on board
midgame_position[1] = 2
midgame_position[3] = 1
midgame_position[5] = -3
midgame_position[12] = 4
midgame_position[15] = -1
midgame_position[20] = -2
midgame_position[22] = 3

puts XGUtils.render_board(midgame_position)

puts "\n" + "=" * 50

# Example 4: Position from demo data
puts "4. Position from Demo Move Data:"
# Using the PositionI from the demo
demo_position = [0] * 26
(0..25).each { |i| demo_position[i] = [(i * 2) % 25 - 12, 15].min }

puts XGUtils.render_board(demo_position)

puts "\n" + "=" * 50

# Example 5: Player with many checkers on the bar using XG format
puts "5a. Player with Many Checkers on the Bar (XG format):"
bar_position_player = [0] * 26  # Use 26-element array for XG format

# Some checkers on regular points
bar_position_player[13] = 2    # Player checkers on point 13
bar_position_player[18] = -3   # Opponent checkers on point 18
bar_position_player[6] = 4     # Player checkers on point 6
bar_position_player[20] = -2   # Opponent checkers on point 20

# Bar checkers using XG format indices
bar_position_player[25] = 8    # 8 Player checkers on bar (index 25)
bar_position_player[0] = 0     # No Opponent checkers on bar (index 0)

puts XGUtils.render_board(bar_position_player)

puts "\n" + "=" * 50

# Example 6: Opponent with many checkers on the bar using XG format
puts "5b. Opponent with Many Checkers on the Bar (XG format):"
bar_position_opponent = [0] * 26  # Use 26-element array for XG format

# Some checkers on regular points
bar_position_opponent[14] = 3    # Player checkers on point 14
bar_position_opponent[19] = -2   # Opponent checkers on point 19
bar_position_opponent[7] = 2     # Player checkers on point 7
bar_position_opponent[21] = -4   # Opponent checkers on point 21

# Bar checkers using XG format indices
bar_position_opponent[25] = 0    # No Player checkers on bar (index 25)
bar_position_opponent[0] = -7    # 7 Opponent checkers on bar (index 0)

puts XGUtils.render_board(bar_position_opponent)

# Example 7: Opponent with many checkers on the bar using XG format
puts "7. Both players have only checkers on the bar"

bar_position_both = EMPTY_BOARD
bar_position_both[25] = 7    # 7 Player checkers on bar (index 25)
bar_position_both[0] = -8    # 8 Opponent checkers on bar (index 0)

puts XGUtils.render_board(bar_position_both)

puts "\nDemo complete!"
