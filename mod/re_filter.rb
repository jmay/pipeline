#!/usr/bin/env ruby

require "fastercsv"
require "getoptlong"
require "yaml"

opts = GetoptLong.new(
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--filter', GetoptLong::REQUIRED_ARGUMENT ]
)

filter_col = filter_rule = nil

begin
  opts.each do |opt, arg|
    case opt
    when '--column'
      filter_col = arg.to_i
    when '--filter'
      filter_rule = arg
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

nrows = 0

$stdin.each_line do |line|
  row = line.split(/\t/)

  row[filter_col] = eval "row[filter_col].#{filter_rule}"

  puts row.join("\t")
  nrows += 1
end

stats = {
  :nrows => nrows,
}
$stderr.puts stats.to_yaml
