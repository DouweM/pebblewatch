module Pebble
  class Watch
    class MediaControlEvent < Event
      attr_accessor :button

      BUTTONS = {
        1 => :playpause,
        4 => :next,
        5 => :previous
      }

      def self.parse(message)
        button_id = message.unpack("C").first

        return nil unless BUTTONS.has_key?(button_id)

        event = new

        event.button = BUTTONS[button_id]

        event
      end

      def inspect
        self.button.to_s.capitalize
      end
    end
  end
end