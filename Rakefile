require "rspec/core/rake_task"

spec = Gem::Specification.load("pebblewatch.gemspec")

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Build the .gem file"
task :build do
  system "gem build #{spec.name}.gemspec"
end

desc "Push the .gem file to rubygems.org"
task release: :build do
  system "gem push #{spec.name}-#{spec.version}.gem"
end