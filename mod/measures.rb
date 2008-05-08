#!/usr/bin/env ruby

# specify measure roles for one or more columns

require "fastercsv"
require "getoptlong"
require "yaml"
require "pp"

require "dataset"

opts = GetoptLong.new(
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--format', GetoptLong::REQUIRED_ARGUMENT ]
)

ranges = format = nil

begin
  opts.each do |opt, arg|
    case opt
    when '--column'
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
    when '--format'
      format = Dataset::Units::const_get(arg)
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end


range = nil

nrows = 0
rejected_rows = 0
ncolumns = 0

measure_columns = []

$stdin.each_line do |line|
  if range.nil?
    row = line.chomp.split(/\t/)
    ncolumns = row.size

    range = eval(ranges.join('+').gsub(/END/, ncolumns.to_s)).sort.uniq
    measure_columns = []
    range.each do |colnum|
      measure_columns[colnum] = format
    end
  end

  puts line
  nrows += 1
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
  :ncolumns => ncolumns,
  :columns => measure_columns,
}
$stderr.puts stats.to_yaml
