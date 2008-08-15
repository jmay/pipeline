#!/usr/bin/env ruby

# Rollup data from one chron level to another, using a specified formula
#
# Level can be: month, quarter, year
# Formula can be: last, max, sum, average
#
# TODO: CURRENTLY ONLY SUPPORTS 'last'
# TODO: ONLY TESTED FOR daily data, floating point, rolled up to month using 'last'

require "getoptlong"
require "yaml"

require "dataset"

opts = GetoptLong.new(
  [ '--chron', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--level', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--formula', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--chroncol', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--datacol', GetoptLong::REQUIRED_ARGUMENT ]
)

chron = level = formula = chroncol = datacol = nil

begin
  opts.each do |opt, arg|
    case opt
    when '--chron'
      chron = Dataset::Chron.const_get(arg)
    when '--level'
      level = arg
    when '--formula'
      formula = arg
    when '--chroncol'
      chroncol = arg.to_i
    when '--datacol'
      datacol = arg.to_i
    else
      puts "INVALID OPTION: #{opt} = #{arg}"
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end

output = {}
last_period_in_period = {}

$stdin.each_line do |line|
  row = line.chomp.split(/\t/)

  thischron = chron.new(:index => row[chroncol].to_i)
  rollup_to = thischron.send(level)
  if last_period_in_period[rollup_to]
    last_period_in_period[rollup_to] = thischron if thischron > last_period_in_period[rollup_to]
  else
    last_period_in_period[rollup_to] = thischron
  end

  v = row[datacol].to_f
  if output[rollup_to]
    output[rollup_to] = v if thischron = last_period_in_period[rollup_to]
  else
    output[rollup_to] = v
  end
end

nrows = 0
max = -1.0/0 # negative infinity
min = 1.0/0 # positive infinity

output.keys.sort.each do |chron|
  v = output[chron]
  max = v if v > max
  min = v if v < min

  puts [chron.index, output[chron]].join("\t")
  nrows += 1
end

stats = {
  :nrows => nrows,
  :columns => [
    {
      :min => output.keys.min.index,
      :max => output.keys.max.index
    },
    {
      :max => max,
      :min => min
    }
    ]
}
$stderr.puts stats.to_yaml
