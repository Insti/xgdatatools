#
#   xgstruct.rb - classes to read XG file structures
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
#   This code is based upon Delphi data structures provided by
#   Xavier Dufaure de Citres <contact@extremegammon.com> for purposes
#   of interacting with the ExtremeGammon XG file formats. Field
#   descriptions derived from xg_format.pas. The file formats are
#   published at http://www.extremegammon.com/xgformat.aspx
#

require_relative "xgutils"
require "securerandom"

module XGStruct
  class GameDataFormatHdrRecord < Hash
    SIZEOFREC = 8232

    def initialize(**kw)
      defaults = {
        "MagicNumber" => 0,             # $484D4752, RM_MAGICNUMBER
        "HeaderVersion" => 0,           # version
        "HeaderSize" => 0,              # size of the header
        "ThumbnailOffset" => 0,         # location of the thumbnail (jpg)
        "ThumbnailSize" => 0,           # size in bye of the thumbnail
        "GameGUID" => nil,              # game id (GUID)
        "GameName" => nil,              # Unicode game name
        "SaveName" => nil,              # Unicode save name
        "LevelName" => nil,             # Unicode level name
        "Comments" => nil               # Unicode comments
      }
      super()
      merge!(defaults.merge(kw))
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?("=")
        self[method.to_s.chomp("=")] = args.first
      elsif has_key?(method.to_s)
        self[method.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.end_with?("=") || has_key?(method.to_s) || super
    end

    def fromstream(stream)
      begin
        data = stream.read(SIZEOFREC)
        return nil if data.nil? || data.length < SIZEOFREC

        unpacked_data = data.unpack("C4l<l<Q<l<L<S<S<CCC6S<1024S<1024S<1024S<1024")
      rescue
        return nil
      end

      self["MagicNumber"] = unpacked_data[0..3].reverse.pack("C*").force_encoding("ASCII")
      self["HeaderVersion"] = unpacked_data[4]

      return nil if self["MagicNumber"] != "HMGR" || self["HeaderVersion"] != 1

      self["HeaderSize"] = unpacked_data[5]
      self["ThumbnailOffset"] = unpacked_data[6]
      self["ThumbnailSize"] = unpacked_data[7]

      # Convert Delphi 4 component GUID to a UUID string
      guidp1, guidp2, guidp3, guidp4, _ = unpacked_data[8..12]
      guidp6 = unpacked_data[13].to_s(16).rjust(12, "0")

      # Create UUID string in standard format
      guid_hex = sprintf("%08x-%04x-%04x-%04x-%s", guidp1, guidp2, guidp3, guidp4, guidp6)
      self["GameGUID"] = guid_hex

      self["GameName"] = XGUtils.utf16intarraytostr(unpacked_data[14..1037])
      self["SaveName"] = XGUtils.utf16intarraytostr(unpacked_data[1038..2061])
      self["LevelName"] = XGUtils.utf16intarraytostr(unpacked_data[2062..3085])
      self["Comments"] = XGUtils.utf16intarraytostr(unpacked_data[3086..4109])

      self
    end
  end

  class TimeSettingRecord < Hash
    SIZEOFREC = 32

    def initialize(**kw)
      defaults = {
        "ClockType" => 0,                 # 0=None,0=Fischer,0=Bronstein
        "PerGame" => false,               # time is for session reset after each game
        "Time1" => 0,                     # initial time in sec
        "Time2" => 0,                     # time added (fisher) or reverved (bronstrein) per move in sec
        "Penalty" => 0,                   # point penalty when running our of time (in point)
        "TimeLeft1" => 0,                 # current time left
        "TimeLeft2" => 0,                 # current time left
        "PenaltyMoney" => 0               # point penalty when running our of time (in point)
      }
      super()
      merge!(defaults.merge(kw))
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?("=")
        self[method.to_s.chomp("=")] = args.first
      elsif has_key?(method.to_s)
        self[method.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.end_with?("=") || has_key?(method.to_s) || super
    end

    def fromstream(stream)
      data = stream.read(SIZEOFREC)
      unpacked_data = data.unpack("l<Cxxxl<l<l<l<l<l<")

      self["ClockType"] = unpacked_data[0]
      self["PerGame"] = unpacked_data[1] != 0
      self["Time1"] = unpacked_data[2]
      self["Time2"] = unpacked_data[3]
      self["Penalty"] = unpacked_data[4]
      self["TimeLeft1"] = unpacked_data[5]
      self["TimeLeft2"] = unpacked_data[6]
      self["PenaltyMoney"] = unpacked_data[7]

      self
    end
  end

  class EvalLevelRecord < Hash
    SIZEOFREC = 4

    def initialize(**kw)
      defaults = {
        "Level" => 0,                     # Level used see PLAYERLEVEL table
        "isDouble" => false               # The analyze assume double for the very next move
      }
      super()
      merge!(defaults.merge(kw))
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?("=")
        self[method.to_s.chomp("=")] = args.first
      elsif has_key?(method.to_s)
        self[method.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.end_with?("=") || has_key?(method.to_s) || super
    end

    def fromstream(stream)
      data = stream.read(SIZEOFREC)
      unpacked_data = data.unpack("s<Cc")

      self["Level"] = unpacked_data[0]
      self["isDouble"] = unpacked_data[1] != 0

      self
    end
  end

  # Additional classes would continue here...
  # For now, implementing key classes to demonstrate the pattern

  class UnimplementedEntry < Hash
    def initialize(**kw)
      defaults = {
        "EntryType" => "UNKNOWN",
        "Name" => "UnimplementedEntry"
      }
      super()
      merge!(defaults.merge(kw))
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?("=")
        self[method.to_s.chomp("=")] = args.first
      elsif has_key?(method.to_s)
        self[method.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.end_with?("=") || has_key?(method.to_s) || super
    end

    def fromstream(stream)
      self
    end
  end

  class GameFileRecord < Hash
    def initialize(version: -1, **kw)
      @version = version
      super()
      merge!(kw)
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?("=")
        self[method.to_s.chomp("=")] = args.first
      elsif has_key?(method.to_s)
        self[method.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.end_with?("=") || has_key?(method.to_s) || super
    end

    def fromstream(stream)
      # Simplified implementation - would need full conversion for production use
      UnimplementedEntry.new.fromstream(stream)
    end
  end

  class RolloutFileRecord < Hash
    def initialize(**kw)
      super()
      merge!(kw)
    end

    def method_missing(method, *args, &block)
      if method.to_s.end_with?("=")
        self[method.to_s.chomp("=")] = args.first
      elsif has_key?(method.to_s)
        self[method.to_s]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.end_with?("=") || has_key?(method.to_s) || super
    end

    def fromstream(stream)
      # Simplified implementation - would need full conversion for production use
      UnimplementedEntry.new.fromstream(stream)
    end
  end

  # Header and footer entry classes for compatibility
  class HeaderMatchEntry < Hash
    attr_accessor :Version

    def initialize(**kw)
      @Version = -1
      super()
      merge!(kw)
    end
  end
end
