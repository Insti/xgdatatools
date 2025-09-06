#!/usr/bin/env ruby

require_relative 'xgutils'

puts "Demonstrating Tall Stack Rendering with Stack Counts"
puts "=" * 60

# Create a position that clearly shows the tall stack feature
position = [0] * 26

# Upper half examples (stack counts appear in innermost row)
position[13] = 7    # 7 Player 1 checkers on point 13
position[18] = -6   # 6 Player 2 checkers on point 18
position[24] = -9   # 9 Player 2 checkers on point 24

# Lower half examples (stack counts appear in topmost row)
position[1] = 8     # 8 Player 1 checkers on point 1
position[6] = -10   # 10 Player 2 checkers on point 6
position[12] = 11   # 11 Player 1 checkers on point 12

# Normal stacks (≤5 checkers) - should behave as before
position[2] = 3     # 3 Player 1 checkers on point 2
position[14] = -4   # 4 Player 2 checkers on point 14

# Bear-off areas
position[0] = 15    # 15 Player 1 checkers in bear-off
position[25] = -12  # 12 Player 2 checkers in bear-off

puts XGUtils.render_board(position)

puts "\nExplanation:"
puts "- Upper half (points 13-24): Stack counts appear in the INNERMOST row (closest to center)"
puts "- Lower half (points 1-12): Stack counts appear in the TOPMOST row (furthest from center)"
puts "- Stacks with ≤5 checkers continue to show all checker symbols"
puts "- Stacks with >5 checkers show up to 4 checker symbols + the count number"
