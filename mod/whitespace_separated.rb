#!/usr/bin/env ruby

require "getoptlong"
require "yaml"

# opts = GetoptLong.new(
#   [ '--ignore-leading', GetoptLong::REQUIRED_ARGUMENT ]
# )
# 
# ignore_leading = 0
# begin
#   opts.each do |opt, arg|
#     case opt
#     when '--ignore-leading'
#       ignore_leading = arg.to_i
#     end
#   end
# rescue
#   puts "BAD OPTIONS"
#   exit 1
# end

nrows = rejected_rows = 0

$stdin.each_line do |line|
  fields = line.split(/\s+/)
  fields.shift while fields.first == '' # always truncate leading blanks
  # if ignore_leading
  #   fields.shift while fields.first == ''
  # end
  if fields.any?
    puts fields.join("\t")
    nrows += 1
  else
    rejected_rows += 1
  end
end

stats = {
  :nrows => nrows,
  :rejected_rows => rejected_rows,
}
$stderr.puts stats.to_yaml
