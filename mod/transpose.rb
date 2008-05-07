#!/usr/bin/env ruby

require "fastercsv"
require "getoptlong"
require "yaml"


ncolumns = nil

input_rows = []
rejected_rows = []
ncolumn_rows = {}

$stdin.each_line do |line|
  line.chomp!
  row = line.split(/\t/)

  ncolumn_rows[row.size] = (ncolumn_rows[row.size] || 0) + 1

  if ncolumns.nil?
    ncolumns = row.size
  end

  if row.size == ncolumns
    input_rows << row
  else
    rejected_rows << row
  end
end

output_rows = input_rows.transpose

output_rows.each do |row|
  puts row.join("\t")
end

stats = {
  :nrows => output_rows.size,
  :ncolumns => ncolumns,
  :rejected_nrows => rejected_rows.size,
  :ncolumn_rows => ncolumn_rows,
}
$stderr.puts stats.to_yaml
