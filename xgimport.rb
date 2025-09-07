#
#   xgimport.rb - XG import module
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

require "tempfile"
require "fileutils"
require_relative "xgdatatools"
require_relative "xgutils"
require_relative "xgzarc"
require_relative "xgstruct"

module XGImport
  class Error < StandardError
    attr_reader :value, :error, :filename

    def initialize(error, filename)
      @value = "XG Import Error processing '#{filename}': #{error}"
      @error = error
      @filename = filename
      super(@value)
    end

    def to_s
      @value.inspect
    end
  end

  class Import
    class Segment
      GDF_HDR, GDF_IMAGE, XG_GAMEHDR, XG_GAMEFILE, XG_ROLLOUTS, XG_COMMENT,
        ZLIBARC_IDX, XG_UNKNOWN = (0..7).to_a

      EXTENSIONS = ["_gdh.bin", ".jpg", "_gamehdr.bin", "_gamefile.bin",
        "_rollouts.bin", "_comments.bin", "_idx.bin", nil]

      GDF_HDR_EXT = EXTENSIONS[0]
      GDF_IMAGE_EXT = EXTENSIONS[1]
      XG_GAMEHDR_EXT = EXTENSIONS[2]
      XG_GAMEFILE_EXT = EXTENSIONS[3]
      XG_ROLLOUTS_EXT = EXTENSIONS[4]
      XG_COMMENTS_EXT = EXTENSIONS[5]
      XG_IDX_EXT = EXTENSIONS[6]

      XG_FILEMAP = {
        "temp.xgi" => XG_GAMEHDR,
        "temp.xgr" => XG_ROLLOUTS,
        "temp.xgc" => XG_COMMENT,
        "temp.xg" => XG_GAMEFILE
      }

      XG_GAMEHDR_LEN = 556
      TMP_PREFIX = "tmpXGI"

      attr_accessor :filename, :fd, :file, :type, :ext

      def initialize(type: GDF_HDR, delete: true, prefix: TMP_PREFIX)
        @filename = nil
        @fd = nil
        @file = nil
        @type = type
        @prefix = prefix
        @autodelete = delete
        @ext = EXTENSIONS[type]
      end

      def createtempfile(mode = "w+b")
        @tempfile = Tempfile.new(@prefix, binmode: true)
        @filename = @tempfile.path
        @fd = @tempfile
        @file = @tempfile
        self
      end

      def closetempfile
        @file&.close unless @file&.closed?
      ensure
        @fd = nil
        @file = nil
        if @autodelete && @filename && File.exist?(@filename)
          begin
            File.unlink(@filename)
          ensure
            @filename = nil
          end
        end
      end

      def copyto(fileto)
        FileUtils.copy(@filename, fileto)
      end
    end

    attr_accessor :filename

    def initialize(filename)
      @filename = filename
    end

    def getfilesegment
      return enum_for(:getfilesegment) unless block_given?

      logger = Xgdatatools.logger
      logger.debug "Starting file segment extraction for: #{@filename}"

      File.open(@filename, "rb") do |xginfile|
        # Extract the uncompressed Game Data Header (GDH)
        gdfheader = XGStruct::GameDataFormatHdrRecord.new.fromstream(xginfile)
        logger.debug "Game data format header: #{gdfheader ? gdfheader.to_h : "nil"}"

        raise Error.new("Not a game data format file", @filename) if gdfheader.nil?

        logger.debug "Header size: #{gdfheader["HeaderSize"]}, Thumbnail size: #{gdfheader["ThumbnailSize"]}"

        # Extract the Game Format Header to a temporary file
        segment = Segment.new(type: Segment::GDF_HDR)
        segment.createtempfile

        xginfile.seek(0, IO::SEEK_SET)
        block = xginfile.read(gdfheader["HeaderSize"])
        segment.file.write(block)
        segment.file.flush

        logger.debug "Extracted GDF header segment"
        yield segment
        segment.closetempfile

        # Extract the uncompressed thumbnail JPEG from the GDF hdr
        if gdfheader["ThumbnailSize"] > 0
          segment = Segment.new(type: Segment::GDF_IMAGE)
          segment.createtempfile

          xginfile.seek(gdfheader["ThumbnailOffset"], IO::SEEK_CUR)
          imgbuf = xginfile.read(gdfheader["ThumbnailSize"])
          segment.file.write(imgbuf)
          segment.file.flush

          yield segment
          segment.closetempfile
        end

        # Retrieve an archive object from the stream
        logger.debug "Creating ZlibArchive object from stream"
        archiveobj = XGZarc::ZlibArchive.new(stream: xginfile)
        logger.debug "Archive initialized with #{archiveobj.arcregistry.length} files"

        # Process all the files in the archive
        archiveobj.arcregistry.each do |filerec|
          logger.debug "Processing archive file: #{filerec["name"]} (#{filerec["osize"]} bytes)"
          # Retrieve the archive file to a temporary file
          segment_file, seg_filename = archiveobj.getarchivefile(filerec)

          # Create a file segment object to pass back to the caller
          xg_filetype = Segment::XG_FILEMAP[filerec["name"]]
          xg_filesegment = Segment.new(type: xg_filetype, delete: false)
          xg_filesegment.filename = seg_filename
          xg_filesegment.fd = segment_file

          # If we are looking at the game info file then check
          # the magic number to ensure it is valid
          if xg_filetype == Segment::XG_GAMEFILE
            segment_file.seek(Segment::XG_GAMEHDR_LEN, IO::SEEK_SET)
            magic_str = segment_file.read(4)

            unless magic_str == "DMLI"
              raise Error.new("Not a valid XG gamefile", @filename)
            end
          end

          yield xg_filesegment

          segment_file.close
          File.unlink(seg_filename) if File.exist?(seg_filename)
        end
      end
    end
  end
end
