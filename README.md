# pebblewatch

A Ruby library for communicating with your Pebble smartwatch.

The protocol implementation was based on the documentation at http://pebbledev.org/, the Python implementation at [Hexxeh/libpebble](https://github.com/Hexxeh/libpebble) and the .NET implementation at [barometz/flint](https://github.com/barometz/flint).

## To Do

- [x] Basic protocol communication
- [x] Sending of messages (notifications etc)
- [x] Receiving of events (log, music control)
- [ ] Firmware/app uploading
- [ ] CLI
- [ ] REPL

## Installation

```sh
gem install pebblewatch
```

## Usage

Make sure your Pebble is paired with your computer and set up as a serial port. We're going to need the path or index of the port, which in the case of OS X looks like `/dev/tty.Pebble7F30-SerialPortSe` for Pebble ID `7F30`. 

```ruby
require "pebble"

# Create your watch using the serial port assigned to your Pebble.
watch = Pebble::Watch.new("7F30", "/dev/tty.Pebble7F30-SerialPortSe")
# You can also use autodetection if you're on OS X:
# watch = Pebble::Watch.autodetect

# The watch object will be on the receiving end of 3 kinds of events:
watch.on_event(:log) do |event|
  puts "LOG"
  puts "timestamp:  #{event.timestamp}"
  puts "level:      #{event.level}"
  puts "filename:   #{event.filename}"
  puts "linenumber: #{event.linenumber}"
  puts "message:    #{event.message}"
end

watch.on_event(:system_message) do |event|
  puts "System Message: #{event.message} (#{event.code})"
end

handler = watch.on_event(:media_control) do |event|
  case event.button
  when :playpause
    puts "Play or pause music"
  when :next
    puts "Next track"
  when :previous
    puts "Previous track"
  end
end

# Suddenly had a change of heart? Just cover your ears.
watch.stop_listening(:media_control, handler)

# To make sure we don't miss any events, we haven't connected yet. 
# Because we also want to *send* stuff to the watch, we will now.
watch.connect


# We can of course send notifications.
watch.ping
watch.notification_sms("Scarlett Johansson", "Hey baby, what are you doing tonight?")
watch.notification_email("Tim Cook", "RE: Final offer", 
  "All right, you drive a hard bargain. We'll pay $2 Billion for the whole shop and that is our final offer.")

# Or let Pebble know what we're listening to.
watch.set_nowplaying_metadata(
  "Artist you've probably never heard of",
  "Album released exclusively through SoundCloud", 
  "Song that doesn't suck per se but isn't great either"
)

# We can also do some maintenancy things, although there's currently no firmware/app uploading.
versions = watch.get_versions
puts "Normal firmware version:    #{versions[:firmwares][:normal][:version]}"
puts "Recovery firmware version:  #{versions[:firmwares][:recovery][:version]}"
puts "Bluetooth MAC address:      #{versions[:btmac]}"

# Fun fact: We don't have to wait for the results synchronously. (This works on every message with a response.)
watch.get_installed_apps do |apps|
  puts "Installed apps: (#{apps[:apps].length} of #{apps[:banks_count]} banks in use)"
  apps[:apps].each do |app|
    puts "#{app[:index]}/#{app[:id]}: #{app[:name]} by #{app[:author]}"
  end
end

# Dieting is not just for dogs anymore.
watch.remove_app(id, index)

time = watch.get_time
# Or asynchronously: watch.get_time { |time| ... }

# Time travel is just one method call away.
watch.set_time(Time.now + (365 * 24 * 60 * 60))

# This is mostly interesting for internal stuff, but since there's a :system_message event as well, I thought why not.
watch.system_message(Pebble::SystemMessages::FIRMWARE_OUT_OF_DATE)

# Yeah, I'd stay away from this one.
watch.reset


# If you're done sending messages but want the program to keep listing for incoming events, say so:
watch.listen_for_events
# Note that listening will only end when the connection is lost, so anything that comes after this call will only then be executed. 
# This will generally be the last call in your program.

# If we don't want to wait around and listen, just let the program exit or disconnect explicitly:
watch.disconnect
```

Oh, and if you want to do some lower level stuff, have a look at [`Pebble::Protocol`](lib/pebble/protocol.rb) which you can access through `watch.protocol`.

```ruby
watch.protocol.on_receive(endpoint) do |message|
  # Do whatever
end

watch.protocol.send_message(endpoint, message)
```

## Examples
Check out the [`examples/`](examples) folder for two examples that I actually use myself. They're kind of similar, but should give you an idea of how this whole thing works.

## License
Copyright (c) 2013 Douwe Maan

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.