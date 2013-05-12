module Pebble
  class Watch
    class AppMessageEvent < Event
      module TupleType
        ByteArray       = 0
        String          = 1
        UnsignedInteger = 2
        Integer         = 3
      end

      attr_accessor :transaction_id
      attr_accessor :uuid
      attr_accessor :data

      def self.parse(raw_message)
        return nil if raw_message.length < 19

        message_type, transaction_id, uuid, dictionary_length = raw_message[0, 19].unpack("CCA16C")

        data = {}

        offset = 19
        dictionary_length.times do |i|
          key, tuple_type, item_length = raw_message[offset, 7].unpack("CL>S<")
          offset += 7

          format = case tuple_type
          when TupleType::ByteArray;      "a*"
          when TupleType::String;         "A*"
          when TupleType::UnsignedInteger
            case item_length
            when 1; "C"
            when 2; "S<"
            when 4; "L<"
            end
          when TupleType::Integer
            case item_length
            when 1; "c"
            when 2; "s<"
            when 4; "l<"
            end
          end

          item_data = raw_message[offset, item_length].unpack(format).first
          offset += item_length

          data[key] = item_data
        end

        event = new

        event.transaction_id  = transaction_id
        event.uuid            = uuid
        event.data            = data

        event
      end
    end
  end
end