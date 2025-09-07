#!/usr/bin/env ruby
#
#   xgbinaryextract.rb - XG binary component extraction tool
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

require "optparse"
require "fileutils"
require_relative "xgdatatools"
require_relative "xgimport"
require_relative "xgzarc"
require_relative "xgstruct"

def directoryisvalid(dir)
  unless File.directory?(dir)
    raise ArgumentError, "directory path '#{dir}' doesn't exist"
  end
  dir
end

# Map segment types to human-readable names
SEGMENT_TYPE_NAMES = {
  XGImport::Import::Segment::GDF_HDR => "gdf_hdr",
  XGImport::Import::Segment::GDF_IMAGE => "gdf_image",
  XGImport::Import::Segment::XG_GAMEHDR => "xg_gamehdr",
  XGImport::Import::Segment::XG_GAMEFILE => "xg_gamefile",
  XGImport::Import::Segment::XG_ROLLOUTS => "xg_rollouts",
  XGImport::Import::Segment::XG_COMMENT => "xg_comment",
  XGImport::Import::Segment::ZLIBARC_IDX => "zlibarc_idx",
  XGImport::Import::Segment::XG_UNKNOWN => "xg_unknown"
}

# Map segment types to subtypes (for future expansion)
SEGMENT_SUBTYPES = {
  XGImport::Import::Segment::GDF_HDR => "header",
  XGImport::Import::Segment::GDF_IMAGE => "thumbnail",
  XGImport::Import::Segment::XG_GAMEHDR => "header",
  XGImport::Import::Segment::XG_GAMEFILE => "data",
  XGImport::Import::Segment::XG_ROLLOUTS => "data",
  XGImport::Import::Segment::XG_COMMENT => "text",
  XGImport::Import::Segment::ZLIBARC_IDX => "index",
  XGImport::Import::Segment::XG_UNKNOWN => "unknown"
}

def extract_xg_components(xgfilename, output_dir, logger)
  logger.info "Processing file: #{xgfilename}"

  unless File.exist?(xgfilename)
    logger.error "File does not exist: #{xgfilename}"
    return false
  end

  logger.debug "File size: #{File.size(xgfilename)} bytes"

  begin
    xgobj = XGImport::Import.new(xgfilename)
    puts "Processing file: #{xgfilename}"

    # Counter for numbering segments of the same type
    segment_counters = Hash.new(0)

    # Extract each segment as a binary file
    xgobj.getfilesegment do |segment|
      # Get type name and subtype for this segment
      type_name = SEGMENT_TYPE_NAMES[segment.type] || "unknown"
      subtype = SEGMENT_SUBTYPES[segment.type] || "data"

      # Increment counter for this segment type
      segment_counters[segment.type] += 1
      number = segment_counters[segment.type]

      # Generate output filename: [type]_[number]_[subtype].bin
      output_filename = File.join(
        File.expand_path(output_dir),
        "#{type_name}_#{number.to_s.rjust(3, "0")}_#{subtype}.bin"
      )

      logger.debug "Extracting segment: #{segment.type} (#{type_name}) -> #{output_filename}"

      # Copy the binary data to the output file
      segment.copyto(output_filename)
      logger.debug "Segment extracted successfully: #{File.size(output_filename)} bytes"

      puts "Extracted: #{File.basename(output_filename)} (#{File.size(output_filename)} bytes)"
    end
  rescue XGImport::Error, XGZarc::Error, Errno::ENOENT, Errno::EINVAL => e
    error_message = e.respond_to?(:value) ? e.value : e.message
    logger.error "Error processing #{xgfilename}: #{error_message}"
    puts "Error: #{error_message}"
    return false
  end

  true
end

if __FILE__ == $PROGRAM_NAME
  options = {log_level: :info}

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options] FILE [FILE ...]"
    opts.separator ""
    opts.separator "XG binary component extraction utility"
    opts.separator ""
    opts.separator "Extracts XG file components into binary files named as:"
    opts.separator "[type]_[number]_[subtype].bin"
    opts.separator ""
    opts.separator "Options:"

    opts.on("-d", "--directory DIR", "Directory to write binary files to",
      "(Default is same directory as the input file)") do |dir|
      options[:outdir] = directoryisvalid(dir)
    end

    opts.on("-v", "--verbose LEVEL", [:debug, :info, :warn, :error],
      "Set logging level (debug, info, warn, error). Default: info") do |level|
      options[:log_level] = level
    end

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end

  begin
    parser.parse!
  rescue => e
    puts "Error: #{e.message}"
    puts parser.help
    exit 1
  end

  if ARGV.empty?
    puts "Error: No XG files specified"
    puts parser.help
    exit 1
  end

  # Initialize logger
  Xgdatatools.init_logger(level: options[:log_level])
  logger = Xgdatatools.logger

  success_count = 0
  ARGV.each do |xgfilename|
    unless File.exist?(xgfilename)
      puts "Error: File '#{xgfilename}' does not exist"
      next
    end

    # Determine output directory
    output_dir = options[:outdir] || File.dirname(xgfilename)
    logger.debug "Output directory: #{output_dir}"

    # Extract components from this file
    if extract_xg_components(xgfilename, output_dir, logger)
      success_count += 1
    end
  end

  puts "\nSuccessfully processed #{success_count} of #{ARGV.length} files."
  exit (success_count == ARGV.length) ? 0 : 1
end
