#!/usr/bin/env ruby

# =head1 NAME
# 
# merge.rb - combine rows from two sources (stdin and named file), based on list of merge columns identified for each
# 
# =head1 DESCRIPTION
# 
# Take two sources and merge them.  Merge means to concatenate the data columns in the sources
# based on matches between the grouping columns.  The output is sorted based on the grouping columns.
# By default early (low-sorting by grouping columns) rows will be dropped until the first record
# that contains values from both sources.  If '--retain 1' is specified then even those early records
# will be included.
# 
# Read primary source from stdin, merge with secondary source, write merged records to stdout
# 
# Data columns from the secondary source are injected into the output following the data columns from
# the primary source.
# 
# =head1 CONTRACT
# 
# Standard expectations (TSV, no blank lines, stripped, squeezed, UTF-8) for both source files
# 
# Expects that both the primary and secondary sources rows will be unique based on the grouping columns.
# 
# Output will be normalized TSV also.
# 
# =head1 OPTIONS
# 
#   --input filename [REQUIRED] file to read secondary source from
#   --group1 colnum [REQUIRED] list of columns in stdin to match on (starting from zero)
#   --group2 colnum [REQUIRED] list of columns in secondary source to match with (starting from zero)
#   --pick2 colnum [REQUIRED] list of columns in secondary source to append to original columns
#   --retain 0|1 (default 0) whether to keep early data with just one of the sources
# 
# =head1 TODO
# 
# What to do if you merge with a source that is missing some mappings?  Does this have an implicit filter?
# 

# specify a chron role for a single column

require "getoptlong"
require "yaml"

require "dataset"

opts = GetoptLong.new(
  [ '--input', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--group1', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--group2', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--pick2', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--retain', GetoptLong::REQUIRED_ARGUMENT ]
)

source2_file = nil
source1_keycols = []
source2_keycols = []
source2_datacols = []
retain = false

begin
  opts.each do |opt, arg|
    case opt
    when '--input'
      source2_file = arg
    when '--group1'
      source1_keycols = arg.split(/\s*,\s*/).map(&:to_i).sort
    when '--group2'
      source2_keycols = arg.split(/\s*,\s*/).map(&:to_i).sort
    when '--pick2'
      source2_datacols = arg.split(/\s*,\s*/).map(&:to_i).sort
    when '--retain'
      retain = true if arg.to_i > 0
    end
  end
rescue
  puts "BAD OPTIONS"
  exit 1
end

source1_data = {}
source2_data = {}
source1_ncolumns = 0

# load source 2
nrows2 = 0
File.open(source2_file).each_line do |line|
  row = line.chomp.split(/\t/)
  key = row.values_at(*source2_keycols)
  data = row.values_at(*source2_datacols)
  source2_data[key] = data
  nrows2 += 1
end

# load source 1
nrows1 = 0
$stdin.each_line do |line|
  row = line.chomp.split(/\t/)
  source1_ncolumns = row.size
  key = row.values_at(*source1_keycols)
  source1_data[key] = row
  nrows1 += 1
end

merge_keys = {}
source1_data.keys.each do |key|
  merge_keys[key] = 1
end
source2_data.keys.each do |key|
  merge_keys[key] = 1
end


# output rows in chron order
foundboth = false # haven't found records that appear in both sources yet
nrows = 0
merge_keys.keys.sort.each do |key|
  inrow = source1_data[key]
  if inrow.nil?
    next unless foundboth || retain # don't output anything until first record with both sources
    # data only in source2, use blanks in the source1 columns
    outrow = key.dup
    outrow.concat(Array.new(source1_ncolumns - source1_keycols.size))
    outrow.concat(source2_data[key])
  elsif source2_data[key]
    # data in both source1 and source2
    foundboth = true
    outrow = inrow.dup
    outrow.concat(source2_data[key])
  else
    next unless foundboth || retain
    # data only in source1
    outrow = inrow.dup
    outrow.concat(Array.new(source2_datacols.size))
  end

  puts outrow.join("\t")
  nrows += 1
end


stats = {
  :nrows => nrows,
  :ncolumns => source1_ncolumns + source2_datacols.size
}
$stderr.puts stats.to_yaml
