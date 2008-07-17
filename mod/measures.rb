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
      format = Dataset::Number.find(arg) or raise "Unknown number format '#{arg}'"
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

column_units = []
column_min = []
column_max = []

$stdin.each_line do |line|
  row = line.chomp.split(/\t/)

  if range.nil? || row.size > ncolumns
    ncolumns = row.size

    range = eval(ranges.join('+').gsub(/END/, (ncolumns-1).to_s)).sort.uniq
    range.each do |colnum|
      column_units[colnum] = format
    end
  end

  begin
    column_units.each_with_index do |format, colnum|
      if format
        if !row[colnum].nil?
          row[colnum] = format.new(row[colnum]).value
          column_min[colnum] = [ column_min[colnum], row[colnum] ].compact.min
          column_max[colnum] = [ column_max[colnum], row[colnum] ].compact.max
        end
      end
      # row[colnum] = nil if row[colnum] !~ /\d/
    end

    puts row.join("\t")
    nrows += 1
  rescue
    rejected_rows += 1
  end
end

columndata = Array.new(ncolumns)
columndata = (0..ncolumns-1).map do |colnum|
  column_units[colnum] &&
  {
    :number => column_units[colnum].label,
    :min => column_min[colnum],
    :max => column_max[colnum]
  }
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
  :ncolumns => ncolumns,
  # :columns => column_units.map {|units| units && {:units => units}},
  :columns => columndata #column_units.map {|units| units && {:number => format.label}},
}
$stderr.puts stats.to_yaml
