module Pebble
  class Watch
    class Event
      def self.parse(message)
        new
      end
    end
  end
end

require "pebble/watch/log_event"
require "pebble/watch/system_message_event"
require "pebble/watch/media_control_event"
require "pebble/watch/app_message_event"