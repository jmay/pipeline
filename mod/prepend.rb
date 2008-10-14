#!/usr/bin/env ruby

# specify a chron role for a single column

require "fastercsv"
require "getoptlong"
require "yaml"
require "facets/blank"

opts = GetoptLong.new(
  [ '--ncolumns', GetoptLong::REQUIRED_ARGUMENT ]
)

ncolumns = 0
begin
  opts.each do |opt, arg|
    case opt
    when '--ncolumns'
      ncolumns = arg.to_i
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

nrows = 0
prefix = Array.new(ncolumns)
$stdin.each_line do |line|
  row = line.chomp.split(/\t/)

  ndatavalues = row.find_all {|cell| !cell.blank?}.size
  case ndatavalues
  when 0
    # blank row, ignore it
    next
  when ncolumns
    # this is a new header row
    prefix = row.values_at(0..ncolumns-1)
  else
    # this is a data row, output with headers prefixed
    puts((prefix + row).join("\t"))
    nrows += 1
  end
end

stats = {
  :nrows => nrows
}
$stderr.puts stats.to_yaml
