#!/usr/bin/env ruby

require "getoptlong"
require "yaml"
require "facets/blank"
require "pp"

opts = GetoptLong.new(
  [ '--freeze', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--dimension', GetoptLong::REQUIRED_ARGUMENT]
)

ncolumns_to_freeze = 0
dimension_name = nil
begin
  opts.each do |opt, arg|
    case opt
    when '--freeze'
      ncolumns_to_freeze = arg.to_i
    when '--dimension'
      dimension_name = arg
    end
  end
rescue Exception => e
  raise "BAD OPTIONS: #{e.message}"
end

nrows = 0

headerline = $stdin.readline.chomp
headings = headerline.split(/\t/)

$stdin.each_line do |line|
  line.chomp!
  fields = line.split(/\t/)

  frozen = fields.slice!(0, ncolumns_to_freeze)

  fields.each_with_index do |value, colnum|
    if !value.blank?
      row = []
      row.concat(frozen)
      row << headings[colnum + ncolumns_to_freeze]
      row << value

      puts row.join("\t")
      nrows += 1
    end
  end
end

columndata = Array.new(ncolumns_to_freeze + 2)
ncolumns_to_freeze.times do |colnum|
  columndata[colnum] = { :heading => headings[colnum] } if !headings[colnum].blank?
end
columndata[-2] = {:label => dimension_name} if !dimension_name.blank?

stats = {
  :nrows => nrows,
  :columns => columndata
}
$stderr.puts stats.to_yaml
