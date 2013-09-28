#!/usr/bin/env ruby

require "pebble"

bundle = Pebble::Bundle.new 'my-pebble-bundle.pbw'

bundle.is_app?
# => true

bundle.is_firmware?
# => false

bundle.has_resources?
# => true

bundle.app_metadata
# =>
# {"header"=>"PBLAPP\x00\x00",
#  "struct_version"=>{"major"=>8, "minor"=>1},
#  "sdk_version"=>{"major"=>3, "minor"=>3},
#  "app_version"=>{"major"=>1, "minor"=>0},
#  "bin_size"=>15375,
#  "bin_offset"=>2147745792,
#  "crc"=>740519882,
#  "name"=>"Counter",
#  "company"=>"Ps0ke",
#  "icon_resource_id"=>16777216,
#  "sym_table_addr"=>3758096384,
#  "flags"=>0,
#  "reloc_list_start"=>1007616000,
#  "num_reloc_entries"=>218169344,
#  "uuid"=>
#    [13, 176, 64, 13, 119, 142, 64, 188, 143, 107, 23, 78, 185, 247, 144, 235]}

bundle.app_metadata.name
# => "Counter"

bundle.uuid_hex
# => ["d", "b0", "40", "d", "77", "8e", "40", "bc", "8f", "6b", "17", "4e", "b9", "f7", "90", "eb"]

bundle.uuid_hex_string
# => "0D B0 40 0D 77 8E 40 BC 8F 6B 17 4E B9 F7 90 EB""0D B0 40 0D 77 8E 40 BC 8F 6B 17 4E B9 F7 90 EB"

bundle.app_info
# =>
# {"reqFwVer"=>1,
#  "timestamp"=>1380124444,
#  "crc"=>1737718662,
#  "name"=>"pebble-app.bin",
#  "size"=>4976}

bundle.resources_info
# =>
# {"timestamp"=>1380124444,
#  "crc"=>3982446848,
#  "friendlyVersion"=>"0.0.1",
#  "name"=>"app_resources.pbpack",
#  "size"=>4468}

# this is not a firmware bundle
bundle.firmware_info
# => nil

# returns the value the object was initialized with
bundle.path
# => "my-pebble-bundle.pbw

# close the bundle (it's a ZIP file)
# reading info from the object will continue to work
bundle.close

