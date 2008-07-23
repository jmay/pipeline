#!/usr/bin/env ruby
# inject_file --source XXXX --component XXXX --storage XXXX --filename XXXX

require "drb"
require "yaml"


require "getoptlong"

opts = GetoptLong.new(
  [ '--source', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--component', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--storage', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--filename', GetoptLong::REQUIRED_ARGUMENT ]
)
sourcename = compname = stasher = filename = nil

begin
  opts.each do |opt, arg|
    case opt
    when '--source'
      sourcename = arg
    when '--component'
      compname = arg.to_sym
    when '--storage'
      stasher = arg
    when '--filename'
      filename = arg
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

if sourcename.nil? || compname.nil? || stasher.nil? || filename.nil?
  puts "USAGE"
  exit 1
end


DRb.start_service
ro = DRbObject.new(nil, 'druby://localhost:7777')
result = ro.inject(
  :source => sourcename,
  :component => compname,
  :stasher => stasher,
  :filename => filename)

print result.to_yaml
