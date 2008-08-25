#!/usr/bin/env ruby

require "getoptlong"
require "yaml"

opts = GetoptLong.new(
  [ '--headers', GetoptLong::REQUIRED_ARGUMENT ]
)

headers = []

begin
  opts.each do |opt, arg|
    case opt
    when '--headers'
      headers = arg.split(',')
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end


puts headers.join("\t")

# run the input straight through to the output
nrows = 0
$stdin.each_line do |line|
  puts line
  nrows += 1
end

stats = {
  :nrows => nrows
}
$stderr.puts stats.to_yaml
