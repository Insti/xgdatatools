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
end
