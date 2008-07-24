#!/usr/bin/env ruby

require "facets/enumerable/each_by"

# require "fastercsv"
require "getoptlong"
require "yaml"

opts = GetoptLong.new(
  [ '--freeze', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--format', GetoptLong::REQUIRED_ARGUMENT ]
)

freeze = nil
begin
  opts.each do |opt, arg|
    case opt
    when '--freeze'
      freeze = arg.to_i #arg.gsub(/\s/, '').split(/,/).map {|n| n.to_i}.sort
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end

nrows = 0

$stdin.each_line do |line|
  line.chomp!
  fields = line.split(/\t/)

  frozen = []
  if freeze
    frozen = fields.slice!(0, freeze)
  end

  fields.each_by(2) do |a,b|
    row = frozen.dup
    row << a << b
    puts row.join("\t")
    nrows += 1
  end
end

stats = {
  :nrows => nrows,
}
$stderr.puts stats.to_yaml
