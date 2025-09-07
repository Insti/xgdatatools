#!/usr/bin/env ruby
#
# Demo script showing the Move class in action
#

require_relative 'xgstruct'
require 'stringio'

puts "Demo: Move Class Parsing"
puts "=" * 40

# Create sample move data
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
# Position calculation: 9 + 26 + 26 + 4 + 3 + 32 = 100 for dice
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
  puts "  EntryType: #{result['EntryType']}"
  puts "  ActiveP: #{result['ActiveP']} (#{result['ActiveP'] == 1 ? 'Player 1' : 'Player 2'})"
  puts "  ActivePlayer: #{result['ActivePlayer']} (backwards compatibility)"
  puts "  Dice: #{XGUtils.render_dice(result['Dice'])}"
  puts "  CubeA: #{result['CubeA']}"
  puts "  Played: #{result['Played']}"
  puts "  PositionI (first 5): #{result['PositionI'][0..4]}"
  puts "  PositionEnd (first 5): #{result['PositionEnd'][0..4]}"
  
  # Show that DataMoves is parsed too
  if result['DataMoves']
    puts "  DataMoves: #{result['DataMoves'].class} (parsed EngineStructBestMoveRecord)"
    puts "    Level: #{result['DataMoves']['Level']}"
    puts "    NMoves: #{result['DataMoves']['NMoves']}"
  end
  
  puts
  puts "✓ All fields accessible via hash syntax and method syntax:"
  puts "  result['ActiveP'] = #{result['ActiveP']}"
  puts "  result.ActiveP = #{result.ActiveP}"
  puts "  result['Type'] = #{result['Type']}"  
  puts "  result.Type = #{result.Type}"
else
  puts "✗ Failed to parse move data"
end

puts
puts "Demo: EngineStructBestMoveRecord"
puts "=" * 40

# Create sample engine data
engine_data = [0] * XGStruct::EngineStructBestMoveRecord::SIZEOFREC

# Set some basic values in the first 68 bytes
engine_data[0..25] = (0..25).map { |i| i % 25 - 12 }  # Pos array
engine_data[28, 4] = [3].pack("l<").bytes   # Level = 3
engine_data[32, 4] = [5].pack("l<").bytes   # Score[0] = 5  
engine_data[36, 4] = [7].pack("l<").bytes   # Score[1] = 7
engine_data[40, 4] = [2].pack("l<").bytes   # Cube = 2
engine_data[48, 4] = [1].pack("l<").bytes   # Crawford = 1
engine_data[56, 4] = [4].pack("l<").bytes   # NMoves = 4

engine_stream = StringIO.new(engine_data.pack("C*"))
engine_record = XGStruct::EngineStructBestMoveRecord.new
engine_result = engine_record.fromstream(engine_stream)

if engine_result
  puts "✓ EngineStructBestMoveRecord parsed successfully!"
  puts
  puts "Engine details:"
  puts "  Level: #{engine_result['Level']}"
  puts "  Cube: #{engine_result['Cube']}"
  puts "  Crawford: #{engine_result['Crawford']}"
  puts "  NMoves: #{engine_result['NMoves']}"
  puts "  Pos (first 5): #{engine_result['Pos'][0..4]}"
  puts "  Score: #{engine_result['Score']}"
else
  puts "✗ Failed to parse engine data"
end

puts
puts "Demo complete!"