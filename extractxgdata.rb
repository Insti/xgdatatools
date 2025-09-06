#!/usr/bin/env ruby
#
#   extractxgdata.rb - Simple XG data extraction tool
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

require 'optparse'
require 'pp'
require_relative 'xgimport'
require_relative 'xgzarc'
require_relative 'xgstruct'

def parseoptsegments(segments)
  segmentlist = segments.split(',')
  segmentlist.each do |segment|
    unless ['all', 'comments', 'gdhdr', 'thumb', 'gameinfo',
            'gamefile', 'rollouts', 'idx'].include?(segment)
      raise ArgumentError, "#{segment} is not a recognized segment"
    end
  end
  segmentlist
end

def directoryisvalid(dir)
  unless File.directory?(dir)
    raise ArgumentError, "directory path '#{dir}' doesn't exist"
  end
  dir
end

if __FILE__ == $PROGRAM_NAME
  options = {}
  
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options] FILE [FILE ...]"
    opts.separator ""
    opts.separator "XG data extraction utility"
    opts.separator ""
    opts.separator "Options:"
    
    opts.on("-d", "--directory DIR", "Directory to write segments to",
            "(Default is same directory as the import file)") do |dir|
      options[:outdir] = directoryisvalid(dir)
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

  ARGV.each do |xgfilename|
    xgbasepath = File.dirname(xgfilename)
    xgbasefile = File.basename(xgfilename)
    xgext = File.extname(xgfilename)
    
    xgbasepath = options[:outdir] if options[:outdir]

    begin
      xgobj = XGImport::Import.new(xgfilename)
      puts "Processing file: #{xgfilename}"
      fileversion = -1
      
      # To do: move this code to XGImport where it belongs
      xgobj.getfilesegment do |segment|
        output_filename = File.join(
          File.expand_path(xgbasepath),
          File.basename(xgbasefile, xgext) + segment.ext
        )
        segment.copyto(output_filename)

        case segment.type
        when XGImport::Import::Segment::XG_GAMEFILE
          segment.fd.seek(0, IO::SEEK_SET)
          loop do
            rec = XGStruct::GameFileRecord.new(version: fileversion).fromstream(segment.fd)
            break if rec.nil?
            
            if rec.is_a?(XGStruct::HeaderMatchEntry)
              fileversion = rec.Version
            elsif rec.is_a?(XGStruct::UnimplementedEntry)
              next
            end
            
            pp rec, width: 160
          end
          
        when XGImport::Import::Segment::XG_ROLLOUTS
          segment.fd.seek(0, IO::SEEK_SET)
          loop do
            rec = XGStruct::RolloutFileRecord.new.fromstream(segment.fd)
            break if rec.nil?
            
            pp rec, width: 160
          end
        end
      end

    rescue XGImport::Error, XGZarc::Error => e
      puts e.value
    end
  end
end