#!/usr/bin/env ruby

require_relative 'xgutils'

# Debug the test case
position = [0] * 26
position[13] = 9    # Upper half - should show count in innermost row
position[1] = 8     # Lower half - should show count in topmost row
position[18] = -7   # Upper half, player 2
position[6] = -6    # Lower half, player 2

result = XGUtils.render_board(position)
puts "=== DEBUG OUTPUT ==="
puts result
puts "=== LINE BY LINE ==="
lines = result.split("\n")
lines.each_with_index do |line, i|
  puts "#{i}: #{line}"
end
