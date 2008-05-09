#!/usr/bin/env ruby

require "fastercsv"
require "getoptlong"
require "yaml"

opts = GetoptLong.new(
  [ '--rows', GetoptLong::REQUIRED_ARGUMENT ]
)

header_rows = 0

begin
  opts.each do |opt, arg|
    case opt
    when '--rows'
      header_rows = arg.to_i
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

nrows = 0

header_lines = []
header_rows.times { header_lines << $stdin.readline.chomp }

headers = header_lines.map {|line| line.split(/\t/)}.transpose.map {|fields| fields.join(' ')}

$stdin.each_line do |line|
  puts line

  nrows += 1
end

stats = {
  :nrows => nrows,
  :columns => headers.map {|hdr| hdr && { :header => hdr }}
}
$stderr.puts stats.to_yaml
