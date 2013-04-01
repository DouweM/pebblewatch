#!/usr/bin/env ruby

require "pebble"

def do_osascript(app, command)
  `osascript -e 'tell application "#{app}" to #{command}'`
end

def update_metadata
  artist  = do_osascript(@app, "artist of current track as string").strip
  album   = do_osascript(@app, "album of current track as string").strip
  track   = do_osascript(@app, "name of current track as string").strip

  nowplaying_metadata = [artist, album, track]

  if nowplaying_metadata != @nowplaying_metadata
    puts "Updating nowplaying metadata: #{nowplaying_metadata}"
    @watch.set_nowplaying_metadata(*nowplaying_metadata)
    @nowplaying_metadata = nowplaying_metadata
  end
end

@app = ARGV[0] || "iTunes"

@watch = Pebble::Watch.autodetect

@watch.on_event(:media_control) do |event|
  commands = {
    playpause:  "playpause",
    next:       "next track",
    previous:   "previous track"
  }

  puts "Executing #{event.button} command"

  do_osascript(@app, commands[event.button])
  update_metadata
end

@watch.connect

Thread.new do
  loop do
    update_metadata
    sleep 5
  end
end

@watch.listen_for_events