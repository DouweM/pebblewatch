#!/usr/bin/env ruby

require "pebble"

def do_osascript(command)
  `osascript -e '#{command}'`
end

def is_muted?
  do_osascript("output muted of (get volume settings)").strip == "true"
end

def current_volume
  do_osascript("output volume of (get volume settings)").to_i
end

def update_metadata
  metadata_text = is_muted? ? "Muted" : "#{current_volume}%"
  
  if metadata_text != @metadata_text
    puts "Updating metadata: #{metadata_text}"
    @watch.set_nowplaying_metadata("Volume", nil, metadata_text)
    @metadata_text = metadata_text
  end
end

@watch = Pebble::Watch.autodetect

@watch.on_event(:media_control) do |event|
  if event.button == :playpause
    if is_muted?
      do_osascript("set volume without output muted")
    else
      do_osascript("set volume with output muted")
    end
  else
    volume = current_volume
    new_volume = event.button == :next ? volume + 5 : volume - 5

    next unless new_volume.between?(0, 100)

    puts "Setting volume to #{new_volume}"

    do_osascript "set volume output volume #{new_volume}"
  end

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