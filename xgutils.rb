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

  # Format a stack count number as exactly 3 characters for board display.
  # Numbers are centered with spaces: " 7 " for single digit, "12 " for double digit
  #
  # @param count [Integer] Stack count (6-15, since we only show counts for stacks > 5)
  # @return [String] 3-character formatted stack count
  def self.format_stack_count_3char(count)
    if count < 10
      " #{count} "  # Single digit: center with spaces
    else
      "#{count} "   # Double digit: left-align with trailing space
    end
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

    lines = []
    
    # Top header row: | 12 | 13 | 14 | 15 | 16 | 17 | BAR | 18 | 19 | 20 | 21 | 22 | 23 | OFF |
    header_top = "|"
    [12, 13, 14, 15, 16, 17].each { |p| header_top += " #{p.to_s.rjust(2)} |" }
    header_top += " BAR |"
    [18, 19, 20, 21, 22, 23].each { |p| header_top += " #{p.to_s.rjust(2)} |" }
    header_top += " OFF |"
    lines << header_top
    
    # Section label for top half
    section_top = "|--------Outer Board----------|     |-------P=O Home Board--------|     |"
    lines << section_top
    
    # Top half checker rows (5 rows)
    5.times do |row|
      line = "|"
      
      # Points 12, 13-17 (outer board)
      [12, 13, 14, 15, 16, 17].each do |point|
        char = get_checker_char_for_position(position[point], row, :upper)
        line += " #{char.center(2)} |"
      end
      
      # BAR column for top half - assume we'll handle bar separately from bear-off  
      # For now, let's assume no bar checkers (this may need adjustment based on actual game logic)
      bar_char = get_checker_char_for_position(0, row, :upper)
      line += " #{bar_char.center(3)} |"
      
      # Points 18-23 (home board)
      [18, 19, 20, 21, 22, 23].each do |point|
        char = get_checker_char_for_position(position[point], row, :upper)
        line += " #{char.center(2)} |"
      end
      
      # OFF column for Player 2 (from position[25] when negative)
      off_checkers = position[25] < 0 ? position[25] : 0  # Only negative values (Player 2's bear-off)
      off_char = get_checker_char_for_position(off_checkers, row, :upper)
      line += " #{off_char.center(3)} |"
      
      lines << line
    end
    
    # Middle separator
    separator = "|-----------------------------|     |-----------------------------|     |"
    lines << separator
    
    # Bottom half checker rows (5 rows) 
    5.times do |row|
      line = "|"
      
      # Points 11-6 (outer board) - note the reversed order for bottom half
      [11, 10, 9, 8, 7, 6].each do |point|
        char = get_checker_char_for_position(position[point], row, :lower)
        line += " #{char.center(2)} |"
      end
      
      # BAR column for bottom half - assume we'll handle bar separately from bear-off
      # For now, let's assume no bar checkers (this may need adjustment based on actual game logic)
      bar_char = get_checker_char_for_position(0, row, :lower)
      line += " #{bar_char.center(3)} |"
      
      # Points 5-0 (home board)
      [5, 4, 3, 2, 1, 0].each do |point|
        char = get_checker_char_for_position(position[point], row, :lower)
        line += " #{char.center(2)} |"
      end
      
      # OFF column for Player 1 (from position[0])
      off_char = get_checker_char_for_position(position[0], row, :lower)
      line += " #{off_char.center(3)} |"
      
      lines << line
    end
    
    # Section label for bottom half
    section_bottom = "|--------Outer Board----------|     |-------P=X Home Board--------|     |"
    lines << section_bottom
    
    # Bottom header row: | 11 | 10 |  9 |  8 |  7 |  6 | BAR |  5 |  4 |  3 |  2 |  1 |  0 | OFF |
    header_bottom = "|"
    [11, 10, 9, 8, 7, 6].each { |p| header_bottom += " #{p.to_s.rjust(2)} |" }
    header_bottom += " BAR |"
    [5, 4, 3, 2, 1, 0].each { |p| header_bottom += " #{p.to_s.rjust(2)} |" }
    header_bottom += " OFF |"
    lines << header_bottom

    lines.join("\n")
  end

  def self.render_moves(moves)
    moves.each_slice(2)
      .take_while { |from, to| from != -1 && to != -1 }
      .map { |from, to| "#{from + 1}/#{to + 1}" }
      .join(", ")
  end

  # Helper method to get the appropriate checker character for a position
  # @param checkers [Integer] Number of checkers at position (positive=Player1, negative=Player2)
  # @param row [Integer] Row number (0-4)
  # @param half [Symbol] :upper or :lower half of board
  # @return [String] Character to display ('X', 'O', number, or space)
  def self.get_checker_char_for_position(checkers, row, half)
    abs_checkers = checkers.abs
    
    return " " if abs_checkers == 0
    
    if abs_checkers > 5
      # Tall stack logic
      if half == :upper
        # Upper half: count in innermost row (row 4), checkers in rows 0-3
        if row == 4
          return abs_checkers.to_s
        elsif row < 4
          return checkers > 0 ? "X" : "O"
        else
          return " "
        end
      else
        # Lower half: count in topmost row (row 0), checkers in rows 1-4
        if row == 0
          return abs_checkers.to_s
        elsif row > 0
          return checkers > 0 ? "X" : "O"
        else
          return " "
        end
      end
    else
      # Normal stack (1-5 checkers)
      if half == :upper
        # Upper half fills from top down (row 0 is topmost)
        if checkers > 0
          return checkers > row ? "X" : " "
        else
          return abs_checkers > row ? "O" : " "
        end
      else
        # Lower half fills from bottom up (row 4 is bottommost)
        if checkers > 0
          return checkers > (4 - row) ? "X" : " "
        else
          return abs_checkers > (4 - row) ? "O" : " "
        end
      end
    end
  end
end
