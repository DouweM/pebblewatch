$:.push File.expand_path("../lib", __FILE__)
require "pebble/version"

Gem::Specification.new do |s|
  s.name          = "pebblewatch"
  s.version       = Pebble::VERSION

  s.platform      = Gem::Platform::RUBY
  s.author        = "Douwe Maan"
  s.email         = "douwe@selenight.nl"
  s.homepage      = "https://github.com/DouweM/pebblewatch"
  s.description   = "A Ruby library for communicating with your Pebble smartwatch."
  s.summary       = "Pebble communication library"
  s.license       = "MIT"

  s.files         = Dir.glob("lib/**/*") + %w(LICENSE README.md Rakefile Gemfile)
  s.test_files    = Dir.glob("spec/**/*")
  s.require_path  = "lib"

  s.add_runtime_dependency "serialport", "~> 1.1"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end