module Pebble
  class Watch
    class SystemMessageEvent < Event
      attr_accessor :code

      def self.parse(message)
        event = new

        event.code = message.length == 2 ? message.unpack("S>").first : -1

        event
      end

      def message
        SystemMessages.for_code(self.code) || "Unknown"
      end

      def inspect
        "#{self.message} (#{self.code})"
      end
    end
  end
end