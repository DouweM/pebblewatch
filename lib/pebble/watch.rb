require "pebble/watch/event"

module Pebble
  class Watch
    module Errors
      class NoWatchesFound < StandardError; end
    end

    def self.autodetect
      return nil unless RUBY_PLATFORM =~ /darwin/

      devices = Dir.glob("/dev/tty.Pebble????-SerialPortSe")

      raise Errors::NoWatchesFound if devices.length == 0
      puts "Found multiple watches" if devices.length > 1

      port = devices.first
      id = port[15, 4]
      puts "Found watch with ID #{id}"

      return new(id, port)
    end

    def self.open(id, port)
      watch = new(id, port)

      begin
        watch.connect
        yield watch
      ensure
        watch.disconnect
      end
      nil
    end

    attr_reader :id
    attr_reader :protocol
    attr_reader :event_handlers
    attr_accessor :session_capabilities
    attr_accessor :client_capabilities

    def initialize(id, port)
      @id = id

      @protocol       = Protocol.new(port)
      @event_handlers = Hash.new { |hash, key| hash[key] = [] }

      # We're mirroring Android here.
      @session_capabilities = Capabilities::Session::GAMMA_RAY
      @client_capabilities  = Capabilities::Client::TELEPHONY | Capabilities::Client::SMS | Capabilities::Client::ANDROID

      answer_phone_version_message
      
      receive_event_messages
    end

    def connect
      @protocol.connect
    end

    def disconnect
      @protocol.disconnect
    end

    def listen_for_events
      @protocol.listen_for_messages
    end

    def on_event(event = :any, &handler)
      @event_handlers[event] << handler
      handler
    end

    def stop_listening(*params)
      handler = params.pop
      event   = params.pop || :any

      @event_handlers[event].delete(handler)
    end


    def ping(cookie = 0xDEADBEEF, &async_response_handler)
      message = [0, cookie].pack("CL>")

      @protocol.send_message(Endpoints::PING, message, async_response_handler) do |message|
        restype, cookie = message.unpack("CL>")
        cookie
      end
    end

    def notification_sms(sender, body)
      notification(:sms, sender, body)
    end

    def notification_email(sender, subject, body)
      notification(:email, sender, body, subject)
    end

    def set_nowplaying_metadata(artist, album, track)
      message = [16].pack("C")
      message << package_strings(artist, album, track, 30)

      @protocol.send_message(Endpoints::MUSIC_CONTROL, message)
    end

    def get_versions(&async_response_handler)
      @protocol.send_message(Endpoints::VERSION, "\x00", async_response_handler) do |message|
        response = {}

        response[:firmwares] = {}

        size = 47
        [:normal, :recovery].each_with_index do |type, index|
          offset = index * size + 1

          fw = {}

          fw[:timestamp], fw[:version], fw[:commit], fw[:is_recovery], 
            fw[:hardware_platform], fw[:metadata_version] =
            message[offset, size].unpack("L>A32A8ccc")

          fw[:is_recovery] = (fw[:is_recovery] == 1)

          response[:firmwares][type] = fw
        end

        response[:bootloader_timestamp], response[:hardware_version], response[:serial] =
          message[95, 25].unpack("L>A9A12")

        response[:btmac] = message[120, 6].unpack("H*").first.scan(/../).reverse.map { |c| c.upcase }.join(":")

        response
      end
    end

    def get_installed_apps(&async_response_handler)
      @protocol.send_message(Endpoints::APP_INSTALL_MANAGER, "\x01", async_response_handler) do |message|
        response = {}

        response[:banks_count], apps_count = message[1, 8].unpack("L>L>")
        response[:apps] = []

        size = 78
        apps_count.times do |index|
          offset = index * size + 9

          app = {}

          app[:id], app[:index], app[:name], app[:author], app[:flags], app[:version] = 
            message[offset, size].unpack("L>L>A32A32L>S>")

          response[:apps] << app
        end

        response
      end
    end

    def remove_app(app_id, app_index)
      message = [2, app_id, app_index].pack("cL>L>")

      @protocol.send_message(Endpoints::APP_INSTALL_MANAGER, message)
    end

    def get_time(&async_response_handler)
      @protocol.send_message(Endpoints::TIME, "\x00", async_response_handler) do |message|
        restype, timestamp = message.unpack("CL>")
        Time.at(timestamp)
      end
    end

    def set_time(time)
      timestamp = time.to_i
      message = [2, timestamp].pack("CL>")

      @protocol.send_message(Endpoints::TIME, message)
    end

    def system_message(code)
      puts "Sending system message #{SystemMessages.for_code(code)}"

      message = [code].pack("S>")

      @protocol.send_message(Endpoints::SYSTEM_MESSAGE, message)
    end

    def reset
      @protocol.send_message(Endpoints::RESET, "\x00")
    end

    private
      def answer_phone_version_message
        @protocol.on_receive(Endpoints::PHONE_VERSION) do |message|
          response_message = [1, -1].pack("Cl>")
          response_message << [@session_capabilities, @client_capabilities].pack("L>L>")

          @protocol.send_message(Endpoints::PHONE_VERSION, response_message)
        end
      end

      def receive_event_messages
        events = [
          [:log,            Endpoints::LOGS,            LogEvent],
          [:system_message, Endpoints::SYSTEM_MESSAGE,  SystemMessageEvent],
          [:media_control,  Endpoints::MUSIC_CONTROL,   MediaControlEvent]
        ]

        events.each do |(name, endpoint, event_klass)|
          @protocol.on_receive(endpoint) do |message|
            event = event_klass.parse(message)
            trigger_event(name, event) if event
          end
        end
      end

      def trigger_event(name, event)
        puts "Event '#{name}': #{event.inspect}"

        @event_handlers[:any].each do |handler|
          Thread.new(handler) do |handler|
            handler.call(name, event)
          end
        end

        @event_handlers[name].each do |handler|
          Thread.new(handler) do |handler|
            handler.call(event)
          end
        end
      end

      def notification(type, *params)
        types = {
          email:  0,
          sms:    1
        }

        timestamp = Time.now.to_i
        params.insert(2, timestamp.to_s)

        message = [types[type]].pack("C") 
        message << package_strings(*params)

        @protocol.send_message(Endpoints::NOTIFICATION, message)
      end

      def package_strings(*parts)
        max_part_length = 255
        max_part_length = parts.pop if parts.last.is_a?(Integer)

        message = ""
        parts.each do |part|
          part ||= ""

          part = part[0, max_part_length] if part.length > max_part_length
          message << [part.length].pack("C") + part
        end
        message
      end
  end
end