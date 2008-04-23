#!/usr/bin/env ruby

require "fastercsv"
require "getoptlong"
require "yaml"

require "dataset" # for Dataset::Chron

opts = GetoptLong.new(
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ]
)

chron_cols = []
chron_specs = []
begin
  opts.each do |opt, arg|
    case opt
    when '--column'
      arg.split(/\s*,\s*/).map do |spec|
        a, b = spec.split(/\s*:\s*/)
        chron_cols << a.to_i
        chron_specs[a.to_i] = Dataset::Chron.const_get(b)
      end
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

nrows = 0
rejected_rows = 0
chron_rows = {}

FasterCSV.filter(:col_sep => "\t") do |row|
  chrons = []
  chron_specs.each_with_index do |klass, i|
    if klass
      chrons << klass.new(row[i]) rescue nil
    end
  end

  new_chron = Dataset::Chron.new(*chrons)
  if new_chron.nil?
    # something bad in the chron values
    rejected_rows += 1
  else
    # all's well
    kname = new_chron.class.name.split(/::/).last
    chron_rows[kname] = chron_rows[kname].to_i + 1

    chron_cols.reverse.each {|colnum| row.slice!(colnum)}
    row.unshift(new_chron.index)
    nrows += 1
  end
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
  :chron_rows => chron_rows,
}
$stderr.puts stats.to_yaml
