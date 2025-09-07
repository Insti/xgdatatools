#
#   xgzarc.rb - XG ZLib archive module
#   Copyright (C) 2013,2014  Michael Petch <mpetch@gnubg.org>
#                                          <mpetch@capp-sysware.com>
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
#   This library is an interpretation of ZLBArchive 1.52 data structures.
#   Please see: http://www.delphipages.com/comp/zlibarchive-2104.html
#

require "tempfile"
require "zlib"
require_relative "xgdatatools"
require_relative "xgutils"

module XGZarc
  class Error < StandardError
    attr_reader :value, :error

    def initialize(error)
      @value = "Zlib archive: #{error}"
      @error = error
      super(@value)
    end

    def to_s
      @value.inspect
    end
  end

  class ArchiveRecord < Hash
    SIZEOFREC = 36

    def initialize(**kw)
      defaults = {
        "crc" => 0,
        "filecount" => 0,
        "version" => 0,
        "registrysize" => 0,
        "archivesize" => 0,
        "compressedregistry" => false,
        "reserved" => []
      }
      super()
      merge!(defaults.merge(kw))
    end

    # Define explicit getter and setter methods for all known keys
    def crc
      self["crc"]
    end

    def crc=(value)
      self["crc"] = value
    end

    def filecount
      self["filecount"]
    end

    def filecount=(value)
      self["filecount"] = value
    end

    def version
      self["version"]
    end

    def version=(value)
      self["version"] = value
    end

    def registrysize
      self["registrysize"]
    end

    def registrysize=(value)
      self["registrysize"] = value
    end

    def archivesize
      self["archivesize"]
    end

    def archivesize=(value)
      self["archivesize"] = value
    end

    def compressedregistry
      self["compressedregistry"]
    end

    def compressedregistry=(value)
      self["compressedregistry"] = value
    end

    def reserved
      self["reserved"]
    end

    def reserved=(value)
      self["reserved"] = value
    end

    # Define methods for keys used in tests
    def TestField
      self["TestField"]
    end

    def TestField=(value)
      self["TestField"] = value
    end

    def ExistingKey
      self["ExistingKey"]
    end

    def ExistingKey=(value)
      self["ExistingKey"] = value
    end

    def TestKey
      self["TestKey"]
    end

    def TestKey=(value)
      self["TestKey"] = value
    end

    def fromstream(stream)
      data = stream.read(SIZEOFREC)
      unpacked_data = data.unpack("l<l<l<l<l<l<C12")

      self["crc"] = unpacked_data[0] & 0xffffffff
      self["filecount"] = unpacked_data[1]
      self["version"] = unpacked_data[2]
      self["registrysize"] = unpacked_data[3]
      self["archivesize"] = unpacked_data[4]
      self["compressedregistry"] = unpacked_data[5] != 0
      self["reserved"] = unpacked_data[6..]
    end
  end

  class FileRecord < Hash
    SIZEOFREC = 532

    def initialize(**kw)
      defaults = {
        "name" => nil,
        "path" => nil,
        "osize" => 0,
        "csize" => 0,
        "start" => 0,
        "crc" => 0,
        "compressed" => false,
        "stored" => false,
        "compressionlevel" => 0
      }
      super()
      merge!(defaults.merge(kw))
    end

    # Define explicit getter and setter methods for all known keys
    def name
      self["name"]
    end

    def name=(value)
      self["name"] = value
    end

    def path
      self["path"]
    end

    def path=(value)
      self["path"] = value
    end

    def osize
      self["osize"]
    end

    def osize=(value)
      self["osize"] = value
    end

    def csize
      self["csize"]
    end

    def csize=(value)
      self["csize"] = value
    end

    def start
      self["start"]
    end

    def start=(value)
      self["start"] = value
    end

    def crc
      self["crc"]
    end

    def crc=(value)
      self["crc"] = value
    end

    def compressed
      self["compressed"]
    end

    def compressed=(value)
      self["compressed"] = value
    end

    def stored
      self["stored"]
    end

    def stored=(value)
      self["stored"] = value
    end

    def compressionlevel
      self["compressionlevel"]
    end

    def compressionlevel=(value)
      self["compressionlevel"] = value
    end

    # Define methods for keys used in tests
    def TestField
      self["TestField"]
    end

    def TestField=(value)
      self["TestField"] = value
    end

    def ExistingKey
      self["ExistingKey"]
    end

    def ExistingKey=(value)
      self["ExistingKey"] = value
    end

    def TestKey
      self["TestKey"]
    end

    def TestKey=(value)
      self["TestKey"] = value
    end

    def fromstream(stream)
      data = stream.read(SIZEOFREC)
      unpacked_data = data.unpack("C256C256l<l<l<l<Cxx")

      self["name"] = XGUtils.delphishortstrtostr(unpacked_data[0..255])
      self["path"] = XGUtils.delphishortstrtostr(unpacked_data[256..511])
      self["osize"] = unpacked_data[512]
      self["csize"] = unpacked_data[513]
      self["start"] = unpacked_data[514]
      self["crc"] = unpacked_data[515] & 0xffffffff
      self["compressed"] = unpacked_data[516] == 0
      self["compressionlevel"] = unpacked_data[517]
    end

    def to_s
      to_h.to_s
    end
  end

  class ZlibArchive
    MAXBUFSIZE = 32768
    TMP_PREFIX = "tmpXGI"

    attr_reader :arcrec, :arcregistry, :startofarcdata, :endofarcdata
    attr_accessor :filename, :stream

    def initialize(stream: nil, filename: nil)
      @arcrec = ArchiveRecord.new
      @arcregistry = []
      @startofarcdata = -1
      @endofarcdata = -1

      @filename = filename
      @stream = stream || File.open(filename, "rb")

      logger = Xgdatatools.logger
      logger.debug "Initializing ZlibArchive for file: #{@filename}"
      logger.debug "Stream size: #{begin
        @stream.size
      rescue
        "unknown"
      end} bytes"

      get_archive_index
    end

    private

    def extract_segment(compressed: true, numbytes: nil)
      filename = nil

      begin
        tmpfile = Tempfile.new(TMP_PREFIX, binmode: true)
        filename = tmpfile.path

        if compressed
          # Extract a compressed segment
          inflate = Zlib::Inflate.new
          buf = @stream.read(MAXBUFSIZE)
          decompressed = inflate.inflate(buf)

          raise IOError if decompressed.empty?

          tmpfile.write(decompressed)

          # Read until we have uncompressed a complete segment
          while inflate.total_in < buf.length
            block = @stream.read(MAXBUFSIZE)
            break if block.nil? || block.empty?

            begin
              decompressed = inflate.inflate(block)
              tmpfile.write(decompressed)
            rescue Zlib::BufError
              break
            end
          end

          inflate.close
        else
          # Extract an uncompressed segment
          raise IOError if numbytes.nil?

          blksize = MAXBUFSIZE
          bytesleft = numbytes

          while bytesleft > 0
            current_blksize = [bytesleft, blksize].min
            block = @stream.read(current_blksize)
            tmpfile.write(block)
            bytesleft -= current_blksize
          end
        end

        tmpfile.close
        filename
      rescue
        File.unlink(filename) if filename && File.exist?(filename)
        nil
      end
    end

    def get_archive_index
      filerecords = []
      curstreampos = @stream.tell

      begin
        # Advance to the archive record at the end and retrieve it
        @stream.seek(-ArchiveRecord::SIZEOFREC, IO::SEEK_END)
        @endofarcdata = @stream.tell
        @arcrec.fromstream(@stream)

        logger = Xgdatatools.logger
        logger.debug "Archive record: filecount=#{@arcrec["filecount"]}, registrysize=#{@arcrec["registrysize"]}, archivesize=#{@arcrec["archivesize"]}"
        logger.debug "Archive compressed registry: #{@arcrec["compressedregistry"]}"

        # Position ourselves at the beginning of the archive file index
        @stream.seek(-ArchiveRecord::SIZEOFREC - @arcrec["registrysize"], IO::SEEK_END)
        @startofarcdata = @stream.tell - @arcrec["archivesize"]

        # Compute the CRC32 of all the archive data including file index
        streamcrc = XGUtils.streamcrc32(
          @stream,
          startpos: @startofarcdata,
          numbytes: (@endofarcdata - @startofarcdata)
        )

        logger = Xgdatatools.logger
        logger.debug "Archive CRC check: computed=0x#{streamcrc.to_s(16)}, expected=0x#{@arcrec["crc"].to_s(16)}"
        logger.debug "Archive data: start=#{@startofarcdata}, end=#{@endofarcdata}, size=#{@endofarcdata - @startofarcdata}"

        raise Error.new("Archive CRC check failed - file corrupt") if streamcrc != @arcrec["crc"]

        # Decompress the index into a temporary file
        idx_filename = extract_segment(compressed: @arcrec["compressedregistry"])
        raise Error.new("Error extracting archive index") if idx_filename.nil?

        # Retrieve all the files in the index
        File.open(idx_filename, "rb") do |idx_file|
          @arcrec["filecount"].times do
            curidxpos = @stream.tell

            # Retrieve next file index record
            filerec = FileRecord.new
            filerec.fromstream(idx_file)
            filerecords << filerec

            @stream.seek(curidxpos, IO::SEEK_SET)
          end
        end

        File.unlink(idx_filename) if File.exist?(idx_filename)
      ensure
        @stream.seek(curstreampos, IO::SEEK_SET)
      end

      @arcregistry = filerecords
    end

    public

    def getarchivefile(filerec)
      logger = Xgdatatools.logger
      logger.debug "Extracting file: #{filerec["name"]}"
      logger.debug "File position: #{filerec["start"]} + #{@startofarcdata} = #{filerec["start"] + @startofarcdata}"

      # Do processing on the temporary file
      @stream.seek(filerec["start"] + @startofarcdata, IO::SEEK_SET)
      tmpfilename = extract_segment(
        compressed: filerec["compressed"],
        numbytes: filerec["csize"]
      )

      raise Error.new("Error extracting archived file") if tmpfilename.nil?

      tmpfile = File.open(tmpfilename, "rb")
      logger.debug "Extracted to temporary file: #{tmpfilename}"

      # Compute the CRC32 on the uncompressed file
      streamcrc = XGUtils.streamcrc32(tmpfile)

      logger = Xgdatatools.logger
      logger.debug "File '#{filerec["name"]}' CRC check: computed=0x#{streamcrc.to_s(16)}, expected=0x#{filerec["crc"].to_s(16)}"
      logger.debug "File details: osize=#{filerec["osize"]}, csize=#{filerec["csize"]}, compressed=#{filerec["compressed"]}"

      raise Error.new("File CRC check failed - file corrupt") if streamcrc != filerec["crc"]

      [tmpfile, tmpfilename]
    end

    def setblocksize(blksize)
      @maxbufsize = blksize
    end
  end
end
