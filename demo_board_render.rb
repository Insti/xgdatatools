#!/usr/bin/env ruby
#
# Demo script showing the backgammon board renderer in action
#

require_relative "xgutils"

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

# Example 5: Player 1 with many checkers on the bar
puts "5a. Player 1 with Many Checkers on the Bar:"
bar_position_p1 = [0] * 28  # Use 28-element array to support bar checkers

# Some checkers on regular points
bar_position_p1[13] = 2    # Player 1 checkers on point 13
bar_position_p1[18] = -3   # Player 2 checkers on point 18
bar_position_p1[6] = 4     # Player 1 checkers on point 6
bar_position_p1[20] = -2   # Player 2 checkers on point 20

# Bear-off areas
bar_position_p1[0] = 2     # Player 1 bear-off
bar_position_p1[25] = -3   # Player 2 bear-off

# Player 1 with many checkers on the bar
bar_position_p1[26] = 8    # 8 Player 1 checkers on bar
bar_position_p1[27] = 0    # No Player 2 checkers on bar

puts XGUtils.render_board(bar_position_p1)

puts "\n" + "=" * 50

# Example 6: Player 2 with many checkers on the bar
puts "5b. Player 2 with Many Checkers on the Bar:"
bar_position_p2 = [0] * 28  # Use 28-element array to support bar checkers

# Some checkers on regular points
bar_position_p2[14] = 3    # Player 1 checkers on point 14
bar_position_p2[19] = -2   # Player 2 checkers on point 19
bar_position_p2[7] = 2     # Player 1 checkers on point 7
bar_position_p2[21] = -4   # Player 2 checkers on point 21

# Bear-off areas
bar_position_p2[0] = 1     # Player 1 bear-off
bar_position_p2[25] = -5   # Player 2 bear-off

# Player 2 with many checkers on the bar
bar_position_p2[26] = 0    # No Player 1 checkers on bar
bar_position_p2[27] = -7   # 7 Player 2 checkers on bar

puts XGUtils.render_board(bar_position_p2)

puts "\nDemo complete!"
