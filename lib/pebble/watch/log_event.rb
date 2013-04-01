module Pebble
  class Watch
    class LogEvent < Event
      attr_accessor :timestamp
      attr_accessor :level
      attr_accessor :filename
      attr_accessor :linenumber
      attr_accessor :message

      def self.parse(raw_message)
        return nil if raw_message.length < 8

        timestamp, level, message_size, linenumber = raw_message[0, 8].unpack("L>CCS>")
        filename  = raw_message[8, 16]
        message   = raw_message[24, message_size]

        log_levels = {
          1   => :error,
          50  => :warning,
          100 => :info,
          200 => :debug,
          250 => :verbose
        }

        event = new

        event.timestamp   = Time.at(timestamp)
        event.level       = log_levels[level] || :unknown
        event.linenumber  = linenumber
        event.filename    = filename
        event.message     = message

        event
      end

      def inspect
        "[#{self.level.to_s.capitalize}] #{self.message}"
      end
    end
  end
end