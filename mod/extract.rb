#!/usr/bin/env ruby

# Use CustomExtractor to convert source data to NSF

require "fastercsv"
require "yaml"

require "dataset" # for CustomExtractor

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
  :nrows => ce.data.size,
  :ncolumns => ce.data.first && ce.data.first.size,
  :error => error,
  :notes => ce.notes && ce.notes.gsub(/\A\s*/, ''), # needed to avoid libsyck YAML parsing bug
  :columns => ce.headers.map {|h| {:headings => h}}
}
$stderr.puts stats.to_yaml
