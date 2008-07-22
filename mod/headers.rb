#!/usr/bin/env ruby

require "fastercsv"
require "getoptlong"
require "yaml"
require "pp"

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
headers = header_lines.map {|line| line.split(/\t/)}
max_header_cols = headers.map{|row| row.size}.max
headers.each {|row| row[max_header_cols-1] ||= nil} # pad all headers to same width so transpose will work

headers = headers.transpose.map {|fields| fields.join(' ').strip}

# run the rest of the input straight through to the next pipeline stage
$stdin.each_line do |line|
  puts line
  nrows += 1
end

stats = {
  :nrows => nrows,
  :columns => headers.map {|hdr| hdr && { :heading => hdr }}
}
$stderr.puts stats.to_yaml
