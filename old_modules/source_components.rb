#!/usr/bin/env ruby

require "drb"
require "yaml"
require "getoptlong"

opts = GetoptLong.new(
  [ '--source', GetoptLong::REQUIRED_ARGUMENT ]
)
sourcename = nil

begin
  opts.each do |opt, arg|
    case opt
    when '--source'
      sourcename = arg
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

if sourcename.nil?
  puts "USAGE"
  exit 1
end


DRb.start_service
ro = DRbObject.new(nil, 'druby://localhost:7777')
result = ro.components(
  :source => sourcename)

print result.to_yaml
