#!/usr/bin/env ruby

# =head1 NAME
# 
# subtract.rb - calculate difference between measure values in matching rows in two sources
# 
# =head1 DESCRIPTION
# 
# Take two sources and compute a difference.
#
# Needs to know which are the key columns to match on in each source, and which are the data columns.
# Mismatch rows will be rejected, only records for which there are values in the two sources will have
# a result included in the output.  Mismatch rows are not errors, they are dropped silently (e.g. so we can
# have sources will overlapping time periods).
#
# Will fail if there are any other column besides key and data.
# There must be the same number of key columns in the two sources.
# Uniqueness of the key columns is assumed for both sources.
# 
# Read primary source from stdin, merge with secondary source, write merged records to stdout
# 
# =head1 CONTRACT
# 
# Assumes TSV for both sources, outputs TSV.
# 
# =head1 OPTIONS
# 
#   --input filename [REQUIRED] file to read secondary source from
#   --group1 colnum [REQUIRED] list of columns in stdin to match on (starting from zero)
#   --group2 colnum [REQUIRED] list of columns in secondary source to match with (starting from zero)
#   --pick1 colnum [REQUIRED] column in primary source to subtract from
#   --pick2 colnum [REQUIRED] column in secondary source to substract from pick1
# 

require "getoptlong"
require "yaml"

require "dataset"

opts = GetoptLong.new(
  [ '--input', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--group1', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--group2', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--pick1', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--pick2', GetoptLong::REQUIRED_ARGUMENT ]
)

source2_file = nil
source1_keycols = []
source2_keycols = []
source1_datacol = source2_datacol = nil

begin
  opts.each do |opt, arg|
    case opt
    when '--input'
      source2_file = arg
    when '--group1'
      source1_keycols = arg.split(/\s*,\s*/).map(&:to_i).sort
    when '--group2'
      source2_keycols = arg.split(/\s*,\s*/).map(&:to_i).sort
    when '--pick1'
      source1_datacol = arg.to_i
    when '--pick2'
      source2_datacol = arg.to_i
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

source1_data = {}
source2_data = {}

# load source 2
nrows2 = 0
File.open(source2_file).each_line do |line|
  row = line.chomp.split(/\t/)
  key = row.values_at(*source2_keycols)
  source2_data[key] = row[source2_datacol].to_f
  nrows2 += 1
end

# load source 1
nrows1 = 0
$stdin.each_line do |line|
  row = line.chomp.split(/\t/)
  key = row.values_at(*source1_keycols)
  source1_data[key] = row[source1_datacol].to_f
  nrows1 += 1
end

output = []

# output rows in sorted order by the order of source1_keycols
nrows = 0
source1_data.keys.sort.each do |key|
  if source2_data[key]
    # there is a match, emit this record
    row = key.dup
    row << source1_data[key] - source2_data[key]
    puts row.join("\t")
    nrows += 1
  end
end


stats = {
  :nrows => nrows
}
$stderr.puts stats.to_yaml
