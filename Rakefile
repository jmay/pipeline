# require "rake/testtask"
require 'spec/rake/spectask'

# Rake::TestTask.new('test') do |t|
#   t.pattern = 'test/tc_*.rb'
#   t.libs = [File.expand_path("lib")]
#   t.warning = true
# end

desc "Run all rspec examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/*_spec.rb']
end
