#!/usr/bin/env ruby

# Compute baseline values for specified input columns

require "getoptlong"
require "yaml"

def process_row(row, baseline_values, datacols, maximums, minimums)
  datacols.each do |colnum|
    row[colnum] = row[colnum].to_f / baseline_values[colnum] * 100
    maximums[colnum] = row[colnum] if row[colnum] > maximums[colnum]
    minimums[colnum] = row[colnum] if row[colnum] < minimums[colnum]
  end
  puts row.join("\t")
end

opts = GetoptLong.new(
  [ '--chroncol', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--baseline', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--datacols', GetoptLong::REQUIRED_ARGUMENT ]
)

chroncol = baseline = nil
datacols = []

begin
  opts.each do |opt, arg|
    case opt
    when '--chroncol'
      chroncol = arg.to_i
    when '--baseline'
      baseline = arg.to_i
    when '--datacols'
      datacols = arg.split(',').map{|n| n.to_i}
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end

baseline_values = []

nrows = 0
cached_rows = []

maximums = Array.new(datacols.max+1, -1.0/0)
minimums = Array.new(datacols.max+1, 1.0/0)

$stdin.each_line do |line|
  row = line.chomp.split(/\t/)

  thischron = row[chroncol].to_i
  maximums[chroncol] = thischron if thischron > maximums[chroncol]
  minimums[chroncol] = thischron if thischron < minimums[chroncol]

  if thischron == baseline
    datacols.each do |colnum|
      baseline_values[colnum] = row[colnum].to_f
    end

    if cached_rows
      # process all the cached rows
      cached_rows.each do |crow|
        process_row(crow, baseline_values, datacols, maximums, minimums)
      end
      nrows += cached_rows.size

      cached_rows = [] # clear the cache

      process_row(row, baseline_values, datacols, maximums, minimums)
      nrows += 1
    end
  elsif baseline_values.any?
    process_row(row, baseline_values, datacols, maximums, minimums)
    nrows += 1
  else
    # cache this row
    cached_rows << row
  end
end

# compute min/max for the chron column and for all the data columns
columns = []
columns[chroncol] = { :min => minimums[chroncol], :max => maximums[chroncol] }
datacols.each do |colnum|
  columns[colnum] = { :number => 'Index', :min => minimums[colnum], :max => maximums[colnum] }
end

stats = {
  :nrows => nrows,
  :columns => columns
}
$stderr.puts stats.to_yaml
