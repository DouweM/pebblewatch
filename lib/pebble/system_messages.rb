module Pebble
  module SystemMessages
    FIRMWARE_AVAILABLE            = 0
    FIRMWARE_START                = 1
    FIRMWARE_COMPLETE             = 2
    FIRMWARE_FAIL                 = 3
    FIRMWARE_UP_TO_DATE           = 4
    FIRMWARE_OUT_OF_DATE          = 5
    BLUETOOTH_START_DISCOVERABLE  = 6
    BLUETOOTH_END_DISCOVERABLE    = 7

    def self.for_code(code)
      constants.find { |constant| const_get(constant) == code }
    end
  end
end