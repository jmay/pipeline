#!/usr/bin/env ruby

# Reformat the contents of columns in an NSF file

def reformat(string, format)
  case format
  when "MM/YYYY"
    val = string.to_i
    sprintf("%02d/%4d", val % 12 + 1, val / 12)
  when /.*%.*f.*/
    sprintf(format, string.to_f).gsub(/(\d)(?=\d{3}+(\.\d*)?[^0-9]*$)/, '\1,')
  when /.*%.*d.*/
    sprintf(format, string.to_i).gsub(/(\d)(?=\d{3}+(\.\d*)?[^0-9]*$)/, '\1,')
  else
    string
  end
end


require "fastercsv"
require "getoptlong"

opts = GetoptLong.new(
  [ '--format', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ]
)

formatting = nil
formats = []
begin
  opts.each do |opt, arg|
    case opt
    when '--format'
      output_format = arg
    when '--column'
      formatting = arg.split(/\s*,\s*/)
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

formatting.each do |entry|
  colnum, fmt = entry.split(/:/)
  formats[colnum.to_i] = fmt
end

FasterCSV.filter(:col_sep => "\t") do |row|
  formats.each_with_index do |fmt, i|
    row[i] = reformat(row[i], fmt)
  end
end
