#!/usr/bin/env ruby

require "fastercsv"

$stdin.each_line do |line|
  FasterCSV.parse(line, :col_sep => "\t") do |row|
    puts FasterCSV.generate_line(row, :col_sep => ',')
  end
end
