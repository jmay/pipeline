#!/usr/bin/env ruby

# filter out rows that match a string

require "getoptlong"
require "yaml"

require "dataset"

opts = GetoptLong.new(
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--match', GetoptLong::REQUIRED_ARGUMENT ]
)

colnum = match = nil
begin
  opts.each do |opt, arg|
    case opt
    when '--column'
      colnum = arg.to_i
    when '--match'
      match = arg
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

nrows = 0
rejected_rows = 0

$stdin.each_line do |row|
  fields = row.split("\t")
  if fields[colnum] == match
    rejected_rows += 1
  else
    nrows += 1
    $stdout.puts fields.join("\t")
  end
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
}
$stderr.puts stats.to_yaml
