#!/usr/bin/env ruby

# This is the "analyze" stage of the Numbrary pipeline.
#
# USAGE:
#   filename for NSF input
#   filename for YAML stats
#   filename to write the parsing recipe
#   filename to write the
#


$LOAD_PATH.unshift("/Users/jmay/Projects/Numbrary/numbrary/trunk/lib/dataset/lib")

require "util"
require "extractor"
require "fastercsv"
require "yaml"

# datafile, codefile = ARGV
codefile = ARGV.shift

# raw = File.read(datafile)
code = File.read(codefile)

raw = $stdin.read

error = nil

begin
  ce = Extractor::CustomExtractor.new(code)
  ce.run(raw)
rescue Exception => e
  error = {
    :message => e.message,
    :backtrace => e.backtrace
  }
end

# FasterCSV.dump(ce.data, $stdout, :col_sep => "\t")
ce.data.each do |row|
  puts FasterCSV.generate_line(row, :col_sep => "\t")
end

stats = {
  :notes => ce.notes && ce.notes.gsub(/\A\s*/, ''), # needed to avoid libsyck YAML parsing bug
  :headers => ce.headers,
  :nrows => ce.data.size,
  :ncolumns => ce.data.first && ce.data.first.size,
  :error => error
}
$stderr.puts stats.to_yaml
