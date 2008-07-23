#!/usr/bin/env ruby

require "yaml"

columns = []
ARGF.each do |line|
  columns << { :label => line.chomp }
end

puts columns.to_yaml
