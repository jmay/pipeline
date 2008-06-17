#!/usr/bin/env ruby

# specify numeric roles for columns

require "fastercsv"
require "getoptlong"
require "yaml"

require "dataset"

opts = GetoptLong.new(
  [ '--column', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--format', GetoptLong::REQUIRED_ARGUMENT ]
)

# colnum = chron_spec = nil
columns = []
formats = []
begin
  opts.each do |opt, arg|
    case opt
    # when '--column'
    #   colnum = arg.to_i
    # when '--format'
    #   chron_spec = Dataset::Chron.const_get(arg)
    when '--column'
      columns << arg.to_i
    when '--format'
      formats << arg
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

numeric_roles = []
columns.each_with_index do |colnum, i|
  numeric_roles[colnum] = Dataset::Number.find(formats[i])
end

nrows = 0
rejected_rows = 0

$stdin.each_line do |row|
  begin
    fields = row.split("\t")
    numeric_roles.each_with_index do |role, colnum|
      if role
        fields[colnum] = role.new(fields[colnum]).value
      end
    end
    $stdout.puts fields.join("\t")
  rescue
    rejected_rows += 1
  end
  nrows += 1
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
  :columns => numeric_roles.map {|role| role ? { :number => role.label } : nil}
}
$stderr.puts stats.to_yaml
