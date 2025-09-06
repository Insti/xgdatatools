#!/usr/bin/env ruby

require_relative 'xgutils'

# Test with tall stacks (more than 5 checkers) to see current behavior
position = [0] * 26

# Create tall stacks in different positions
position[1] = 8     # 8 Player 1 checkers on point 1 (lower half)
position[12] = 7    # 7 Player 1 checkers on point 12 (lower half)
position[13] = 9    # 9 Player 1 checkers on point 13 (upper half)
position[24] = -8   # 8 Player 2 checkers on point 24 (upper half)
position[6] = -6    # 6 Player 2 checkers on point 6 (lower half)
position[18] = -6   # 6 Player 2 checkers on point 18 (upper half)

# Also test bear-off and bar (index 25 can represent bar)
position[0] = 9     # 9 Player 1 checkers in bear-off
position[25] = -10  # 10 Player 2 checkers in bear-off/bar

puts "Current behavior with tall stacks:"
puts XGUtils.render_board(position)