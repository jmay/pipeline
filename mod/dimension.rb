#!/usr/bin/env ruby

# specify measure roles for one or more columns

require "fastercsv"
require "getoptlong"
require "yaml"

opts = GetoptLong.new(
  [ '--columns', GetoptLong::REQUIRED_ARGUMENT ]
)

ranges = nil
begin
  opts.each do |opt, arg|
    case opt
    when '--columns'
      ranges = []
      arg.gsub(/\s/, '').split(/,/).each do |cols|
        case cols
        when /^\d+$/
          ranges << "[#{cols}]"
        when /(\d+)\-(\d+)/
          ranges << "(#{$1}..#{$2}).to_a"
        when /(\d+)\-/
          ranges << "(#{$1}..END).to_a"
        else
          raise "Can't deal with #{cols}"
        end
      end
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end


dimension_columns = nil
dimension_values = []
nrows = 0
ncolumns = 0

$stdin.each_line do |line|
  row = line.chomp.split(/\t/)

  if dimension_columns.nil? || row.size > ncolumns
    ncolumns = row.size

    dimension_columns = eval(ranges.join('+').gsub(/END/, (ncolumns-1).to_s)).sort.uniq
  end

  dimension_columns.each do |colnum|
    # collect lists of unique values for each dimension column
    if value = row[colnum]
      dimension_values[colnum] ||= Hash.new(0)
      dimension_values[colnum][value] += 1
    end
  end

  # emit the input unchanged
  puts row.join("\t")
  nrows += 1
end

columndata = (0..dimension_columns.max).map do |colnum|
  dimension_values[colnum] &&
  {
    :values => dimension_values[colnum].keys.sort # always sorting the values alphabetically for now
  }
end

stats = {
  :nrows => nrows,
  :columns => columndata
}
$stderr.puts stats.to_yaml
