#!/usr/bin/env ruby

# extract from HTML source using hpricot

require "getoptlong"
require "hpricot"
require "htmlentities"  # for converting HTML entities like &nbsp;
require "yaml"
require "pp"

opts = GetoptLong.new(
  [ '--xpath', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--nth', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--table', GetoptLong::REQUIRED_ARGUMENT ]
)

xpath = nth = nil
parsetable = false

begin
  opts.each do |opt, arg|
    case opt
    when '--xpath'
      xpath = arg
    when '--nth'
      nth = arg.to_i
    when '--table'
      parsetable = true
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end

Coder = HTMLEntities.new
doc = Hpricot(STDIN.readlines.join)

def mydecode(cell)
  Coder.decode(cell.inner_text.gsub(/&nbsp;/, ' ').gsub(/[[:space:]]+/, ' ').gsub(/\?/, '')).strip
end

node = doc.search(xpath)
if nth
  node = node[nth]
end

# (table/"/tr").each do |row|
#   rowcells = (html_table_row_cells(row)).map {|cell| cell.inner_text.strip.gsub(/[$,]/, '').gsub(/\s+/, ' ')}
#   if rowcells.find {|cell| cell =~ /\S/}
#     # there's at least one cell that has a non-blank in it
#     lines << rowcells
#   end

if parsetable
  node.search("tr").each do |tr|
    row = tr.search("td,th").map {|cell| mydecode(cell)}
    if row.find_all{|cell| cell =~ /[^[:space:]]/}.any?
      puts row.join("\t")
    end
  end
else
  puts Coder.decode(node.inner_html)
end


stats = {
}
$stderr.puts stats.to_yaml


