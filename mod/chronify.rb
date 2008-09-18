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
        colnum, chrontype = spec.split(/\s*:\s*/)
        chron_cols << colnum.to_i
        if chrontype =~ /%/
          # explicit strptime format, so this must be a date, not some higher-order chron
          chron_specs[colnum.to_i] = chrontype
        else
          # Dataset::Chron type, attempts automatic format recognition
          chron_specs[colnum.to_i] = Dataset::Chron.const_get(chrontype)
        end
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
chronvalues = []

$stdin.each_line do |line|
  row = line.split(/\t/)
  chrons = []

  begin
    chron_specs.each_with_index do |klass, i|
      if klass
        if klass.is_a?(Class)
          chrons << klass.new(row[i])
        else
          # strptime
          chrons << Dataset::Chron::YYMMDD.new(Date.parse(row[i], klass))
        end
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
    chronvalues << new_chron.index

    if chrons.size == 1
      # don't move the chron column
      row[chron_cols.first] = new_chron.index
    else
      # erase the original chron columns and put a new chron column at the front
      chron_cols.reverse.each {|colnum| row.slice!(colnum)}
      row.unshift(new_chron.index)
    end
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
