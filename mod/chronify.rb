#!/usr/bin/env ruby

# specify a chron role for a single column

require "fastercsv"
require "getoptlong"
require "yaml"

require "dataset"

opts = GetoptLong.new(
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--format', GetoptLong::REQUIRED_ARGUMENT ]
)

# colnum = chron_spec = nil
chron_cols = []
chron_specs = []
begin
  opts.each do |opt, arg|
    case opt
    # when '--column'
    #   colnum = arg.to_i
    # when '--format'
    #   chron_spec = Dataset::Chron.const_get(arg)
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

# chron_cols = [colnum]
# chron_specs = []
# chron_specs[colnum] = chron_spec

nrows = 0
rejected_rows = 0
chron_rows = {}
chronvalues = []

$stdin.each_line do |line|
  row = line.split(/\t/)
# FasterCSV.filter(:col_sep => "\t") do |row|
  chrons = []

  begin
    chron_specs.each_with_index do |klass, i|
      if klass
        chrons << klass.new(row[i])
      end
    end
  rescue
    rejected_rows += 1
    next
  end

  new_chron = chrons.size > 1 ? Dataset::Chron.new(*chrons) : chrons.first
  if new_chron.nil?
    # something bad in the chron values
    rejected_rows += 1
  else
    # all's well
    kname = new_chron.class.name.split(/::/).last
    chron_rows[kname] = chron_rows[kname].to_i + 1

    chron_cols.reverse.each {|colnum| row.slice!(colnum)}

    chronvalues << new_chron.index
    row.unshift(new_chron.index)
    puts row.join("\t")
    nrows += 1
  end
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
  :chron_rows => chron_rows,
  :columns => [
    :chron => chron_rows.keys.first,
    :min => chronvalues.min,
    :max => chronvalues.max
    ]
}
$stderr.puts stats.to_yaml
