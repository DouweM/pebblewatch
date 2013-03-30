module Pebble
  module Capabilities
    module Session
      GAMMA_RAY = 0x80000000
    end

    module Client
      UNKNOWN = 0
      IOS     = 1
      ANDROID = 2
      OSX     = 3
      LINUX   = 4
      WINDOWS = 5

      TELEPHONY     = 16
      SMS           = 32
      GPS           = 64
      BTLE          = 128
      CAMERA_FRONT  = 240 # No, that doesn't make sense, but it's apparently true.
      CAMERA_REAR   = 256
      ACCEL         = 512
      GYRO          = 1024
      COMPASS       = 2048
    end
  end
end