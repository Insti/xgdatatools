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

puts "\nDemo complete!"
