require "serialport"

module Pebble
  class Protocol
    module Errors
      class NotConnected < StandardError; end
      class LostConnection < StandardError; end
      class MalformedResponse < StandardError; end
    end

    attr_reader :connected
    attr_reader :message_handlers

    def self.open(port)
      protocol = new(port)

      begin
        protocol.connect
        yield protocol
      ensure
        protocol.disconnect
      end
      nil
    end

    def initialize(port)
      @port = port

      @connected          = false
      @send_message_mutex = Mutex.new
      @message_handlers   = Hash.new { |hash, key| hash[key] = [] }
    end

    def connect
      puts "Connecting with port #{@port}"

      @serial_port = SerialPort.new(@port, baudrate: 115200)
      @serial_port.read_timeout = 500

      @connected = true
      puts "Connected"
      
      @receive_messages_thread = Thread.new(&method(:receive_messages))

      true
    end

    def disconnect
      raise Errors::NotConnected unless @connected

      @connected = false

      @serial_port.close()
      @serial_port = nil

      true
    end

    def listen_for_messages
      raise Errors::NotConnected unless @connected

      @receive_messages_thread.join
    end

    def on_receive(endpoint = :any, &handler)
      @message_handlers[endpoint] << handler
      handler
    end

    def stop_receiving(*params)
      handler   = params.pop
      endpoint  = params.pop || :any

      @message_handlers[endpoint].delete(handler)
    end

    def send_message(endpoint, message, async_response_handler = nil, &response_parser)
      raise Errors::NotConnected unless @connected

      message ||= ""

      puts "Sending #{Endpoints.for_code(endpoint)}: #{message.inspect}"

      data = [message.size, endpoint].pack("S>S>") + message

      @send_message_mutex.synchronize do
        @serial_port.write data

        if response_parser
          if async_response_handler
            identifier = on_receive(endpoint) do |response_message|
              stop_receiving(endpoint, identifier)

              parsed_response = response_parser.call(response_message)

              async_response_handler.call(parsed_response)
            end

            true
          else
            received        = false
            parsed_response = nil
            identifier = on_receive(endpoint) do |response_message|
              stop_receiving(endpoint, identifier)

              parsed_response = response_parser.call(response_message)
              received        = true
            end

            sleep 0.015 until received

            parsed_response
          end
        else
          true
        end
      end
    end

    private
      def receive_messages
        puts "Waiting for messages"
        while @connected
          header = @serial_port.read(4)
          next unless header

          raise Errors::MalformedResponse if header.length < 4

          size, endpoint = header.unpack("S>S>")
          message = @serial_port.read(size)

          puts "Received #{Endpoints.for_code(endpoint)}: #{message.inspect}"

          trigger_received(endpoint, message)
        end
      rescue IOError => e
        if @connected
          puts "Lost connection"
          @connected = false
          raise Errors::LostConnection
        end
      ensure
        puts "Finished waiting for messages"
      end

      def trigger_received(endpoint, message)
        @message_handlers[:any].each do |handler|
          Thread.new(handler) do |handler|
            handler.call(endpoint, message)
          end
        end

        @message_handlers[endpoint].each do |handler|
          Thread.new(handler) do |handler|
            handler.call(message)
          end
        end
      end
  end
end