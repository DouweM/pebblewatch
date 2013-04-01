module Pebble
  module Endpoints
    FIRMWARE            = 1
    TIME                = 11
    VERSION             = 16
    PHONE_VERSION       = 17
    SYSTEM_MESSAGE      = 18
    MUSIC_CONTROL       = 32
    PHONE_CONTROL       = 33
    LOGS                = 2000
    PING                = 2001
    DRAW                = 2002
    RESET               = 2003
    APP                 = 2004
    NOTIFICATION        = 3000
    RESOURCE            = 4000
    SYS_REG             = 5000
    FCT_REG             = 5001
    APP_INSTALL_MANAGER = 6000
    RUNKEEPER           = 7000
    PUT_BYTES           = 48879
    MAX_ENDPOINT        = 65535

    def self.for_code(code)
      constants.find { |constant| const_get(constant) == code }
    end
  end
end