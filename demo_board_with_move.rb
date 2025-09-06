#!/usr/bin/env ruby
#
# Demo script showing board rendering with actual move data
#

require_relative 'xgstruct'
require_relative 'xgutils'
require 'stringio'

puts "Demo: Board Rendering with Move Class Data"
puts "=" * 50

# Create sample move data (based on demo_move_class.rb)
data = [0] * XGStruct::MoveEntry::SIZEOFREC

# Set up the record structure
data[8] = 3  # EntryType = tsMove

# Set ActiveP to player 1 at the correct position (9 + 52)
data[9 + 52, 4] = [1].pack("l<").bytes

# Set some position data
offset = 9
(0..25).each { |i| data[offset + i] = [(i * 2) % 25 - 12, 15].min }  # PositionI
offset += 26
(0..25).each { |i| data[offset + i] = [(i * 3) % 25 - 10, 15].min }  # PositionEnd

# Set dice at the appropriate position
dice_offset = 9 + 26 + 26 + 4 + 3 + 32
data[dice_offset, 8] = [4, 6].pack("l<2").bytes

# Set cube value
cube_offset = dice_offset + 8
data[cube_offset, 4] = [2].pack("l<").bytes  # Cube value 2

# Create stream and parse
stream = StringIO.new(data.pack("C*"))
move = XGStruct::MoveEntry.new
result = move.fromstream(stream)

if result
  puts "✓ Move parsed successfully!"
  puts
  puts "Move details:"
  puts "  Type: #{result['Type']}"
  puts "  ActiveP: #{result['ActiveP']} (#{result['ActiveP'] == 1 ? 'Player 1' : 'Player 2'})"
  puts "  Dice: #{result['Dice']}"
  puts "  CubeA: #{result['CubeA']}"
  puts

  puts "Initial Position:"
  puts XGUtils.render_board(result['PositionI'])

  puts "\n" + "=" * 50
  puts "Final Position:"
  puts XGUtils.render_board(result['PositionEnd'])

else
  puts "✗ Failed to parse move data"
end

puts "\nDemo complete!"