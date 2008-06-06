#!/usr/bin/env ruby

require "yaml"

nrows = 0

$stdin.each_line do |line|
  fields = line.split(/\s+/)
  puts fields.join("\t")
  nrows += 1
end

stats = {
  :nrows => nrows
}
$stderr.puts stats.to_yaml
