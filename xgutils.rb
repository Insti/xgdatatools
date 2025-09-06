#
#   xgutils.rb - XG related utility functions
#   Copyright (C) 2013  Michael Petch <mpetch@gnubg.org>
#                                     <mpetch@capp-sysware.com>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

require "zlib"
require "date"

module XGUtils
  # Compute the CRC32 on a given stream. Restore the original
  # position in the stream upon finishing. Process the stream in
  # chunks defined by blksize
  def self.streamcrc32(stream, numbytes: nil, startpos: nil, blksize: 32768)
    crc32 = 0
    curstreampos = stream.tell

    stream.seek(startpos, IO::SEEK_SET) unless startpos.nil?

    if numbytes.nil?
      loop do
        block = stream.read(blksize)
        break if block.nil? || block.empty?
        crc32 = Zlib.crc32(block, crc32)
      end
    else
      bytesleft = numbytes
      while bytesleft > 0
        current_blksize = [bytesleft, blksize].min
        block = stream.read(current_blksize)
        crc32 = Zlib.crc32(block, crc32)
        bytesleft -= current_blksize
      end
    end

    stream.seek(curstreampos, IO::SEEK_SET)
    crc32 & 0xffffffff
  end

  # Convert an array of integers (UTF16) to a string.
  # Input array is null terminated.
  def self.utf16intarraytostr(intarray)
    newstr = []
    intarray.each do |intval|
      break if intval == 0
      newstr << intval.chr(Encoding::UTF_8)
    end
    newstr.join.encode("UTF-8")
  end

  # Convert a double float Delphi style timedate object to a Ruby
  # DateTime object. Delphi uses the number of days since
  # Dec 30th, 1899 in the whole number component. The fractional
  # component represents the fraction of a day (multiply by 86400
  # to translate to seconds)
  def self.delphidatetimeconv(delphi_datetime)
    days = delphi_datetime.to_i
    seconds = (86400 * (delphi_datetime % 1)).to_i

    base_date = DateTime.new(1899, 12, 30)
    base_date + days + Rational(seconds, 86400)
  end

  # Convert Delphi Pascal style shortstring to a Ruby string.
  # shortstring is a single byte (length of string) followed by
  # length number of bytes. shortstrings are not null terminated.
  def self.delphishortstrtostr(shortstring_abytes)
    length = shortstring_abytes[0]
    shortstring_abytes[1, length].pack("C*").force_encoding("UTF-8")
  end

  # Format a point number as exactly 3 characters for board display.
  # 1-digit numbers (1-9) are centered with spaces: " 1 "
  # 2-digit numbers (10-24) are left-aligned with trailing space: "10 "
  #
  # @param point [Integer] Point number (1-24)
  # @return [String] 3-character formatted point number
  def self.format_point_3char(point)
    if point < 10
      " #{point} "  # 1-digit: center with spaces
    else
      "#{point} "   # 2-digit: left-align with trailing space
    end
  end

  # Format a checker character as exactly 3 characters for board display.
  # All characters are centered with spaces: " X "
  #
  # @param char [String] Checker character ('X', 'O', or ' ')
  # @return [String] 3-character formatted checker
  def self.format_checker_3char(char)
    " #{char} "
  end

  # Render an ASCII representation of a backgammon board given a position array.
  # 
  # The position array is a PositionEngine (array[0..25] of ShortInt) where:
  # - Index 0: Player 1's bear-off area 
  # - Indices 1-24: The 24 points on the board (1-12 and 13-24)
  # - Index 25: Player 2's bear-off area or bar
  # 
  # Positive values indicate Player 1's checkers, negative values indicate Player 2's checkers.
  # The absolute value indicates the number of checkers on that point.
  #
  # @param position [Array<Integer>] Array of 26 integers representing the board position
  # @return [String] ASCII representation of the backgammon board
  def self.render_board(position)
    return "Invalid position: must be array of 26 integers" unless position.is_a?(Array) && position.length == 26

    # Initialize board display components
    lines = []
    
    # Top border
    lines << "┌" + "─" * 39 + "┐"
    
    # Point numbers (top)
    top_points = (13..18).to_a + ["|"] + (19..24).to_a
    lines << "│" + top_points.map { |p| p.is_a?(Integer) ? format_point_3char(p) : " │ " }.join("") + "│"
    
    # Top half of board (points 13-24, showing up to 5 checkers)
    5.times do |row|
      line = "│"
      
      # Points 13-18
      (13..18).each do |point|
        checkers = position[point]
        if checkers > 0
          # Player 1's checkers (positive)
          char = checkers > row ? "X" : " "
        elsif checkers < 0
          # Player 2's checkers (negative)
          char = (-checkers) > row ? "O" : " "
        else
          char = " "
        end
        line += format_checker_3char(char)
      end
      
      # Middle separator
      line += " │ "
      
      # Points 19-24
      (19..24).each do |point|
        checkers = position[point]
        if checkers > 0
          # Player 1's checkers (positive)
          char = checkers > row ? "X" : " "
        elsif checkers < 0
          # Player 2's checkers (negative)
          char = (-checkers) > row ? "O" : " "
        else
          char = " "
        end
        line += format_checker_3char(char)
      end
      
      line += "│"
      lines << line
    end
    
    # Middle bar
    bar_line = "│" + "─" * 18 + " │ " + "─" * 18 + "│"
    lines << bar_line
    
    # Show bar and bear-off info
    bear_off_1 = position[0] # Player 1 bear-off
    bear_off_2 = position[25] # Player 2 bear-off/bar
    
    # Create info line with proper alignment to match point numbers line (41 chars total)
    # Left section: 18 chars, middle separator: 3 chars (" │ "), right section: 18 chars
    left_part = "│Bear-off P1: #{bear_off_1 > 0 ? bear_off_1 : 0}"
    # Pad left part to 19 chars (including the │)
    left_padding = " " * (19 - left_part.length)
    
    right_part = "Bear-off P2: #{bear_off_2 < 0 ? -bear_off_2 : 0}"
    # Pad right part to 18 chars 
    right_padding = " " * (18 - right_part.length)
    
    info_line = left_part + left_padding + " │ " + right_part + right_padding + "│"
    lines << info_line
    
    lines << bar_line
    
    # Bottom half of board (points 12-1, showing up to 5 checkers)
    5.times do |row|
      line = "│"
      
      # Points 12-7
      (12).downto(7).each do |point|
        checkers = position[point]
        if checkers > 0
          # Player 1's checkers (positive)
          char = checkers > (4 - row) ? "X" : " "
        elsif checkers < 0
          # Player 2's checkers (negative)  
          char = (-checkers) > (4 - row) ? "O" : " "
        else
          char = " "
        end
        line += format_checker_3char(char)
      end
      
      # Middle separator
      line += " │ "
      
      # Points 6-1
      (6).downto(1).each do |point|
        checkers = position[point]
        if checkers > 0
          # Player 1's checkers (positive)
          char = checkers > (4 - row) ? "X" : " "
        elsif checkers < 0
          # Player 2's checkers (negative)
          char = (-checkers) > (4 - row) ? "O" : " "
        else
          char = " "
        end
        line += format_checker_3char(char)
      end
      
      line += "│"
      lines << line
    end
    
    # Point numbers (bottom)
    bottom_points = (12).downto(7).to_a + ["|"] + (6).downto(1).to_a
    lines << "│" + bottom_points.map { |p| p.is_a?(Integer) ? format_point_3char(p) : " │ " }.join("") + "│"
    
    # Bottom border
    lines << "└" + "─" * 39 + "┘"
    
    # Legend
    lines << ""
    lines << "Legend: X = Player 1, O = Player 2"
    lines << "        Positive values = Player 1, Negative values = Player 2"
    
    lines.join("\n")
  end
end
