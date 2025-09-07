#
#   xgdatatools.rb - Main module for XGDataTools
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

require "logger"

module Xgdatatools
  @logger = nil

  # Returns a singleton logger instance
  def self.logger
    @logger ||= create_logger
  end

  # Initialize the logger with optional configuration
  def self.init_logger(level: :info, output: STDOUT)
    @logger = create_logger(level: level, output: output)
  end

  # Set the logger to a specific instance (useful for testing)
  def self.logger=(logger_instance)
    @logger = logger_instance
  end

  private

  def self.create_logger(level: :info, output: STDOUT)
    logger = Logger.new(output)
    logger.level = case level
                   when :debug then Logger::DEBUG
                   when :info then Logger::INFO  
                   when :warn then Logger::WARN
                   when :error then Logger::ERROR
                   else Logger::INFO
                   end
    logger.formatter = proc do |severity, datetime, progname, msg|
      "[#{severity}] #{msg}\n"
    end
    logger
  end
end