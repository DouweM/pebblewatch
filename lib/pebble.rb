require "logger"

module Pebble
  def self.logger=(new_logger)
    @@logger = new_logger
  end

  def self.logger
    return @@logger if defined?(@@logger)
    @@logger = default_logger
  end

  def self.default_logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger
  end
end

require "pebble/version"
require "pebble/endpoints"
require "pebble/capabilities"
require "pebble/system_messages"
require "pebble/protocol"
require "pebble/watch"