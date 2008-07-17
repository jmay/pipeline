#!/usr/bin/env ruby

# extract from HTML source using hpricot

require "getoptlong"
require "hpricot"
require "htmlentities"  # for converting HTML entities like &nbsp;
require "yaml"

opts = GetoptLong.new(
  [ '--xpath', GetoptLong::REQUIRED_ARGUMENT ]
)

xpath = nil
begin
  opts.each do |opt, arg|
    case opt
    when '--xpath'
      xpath = arg
    end
  end
rescue Exception => e
  puts "BAD OPTIONS: #{e.message}"
  exit 1
end

coder = HTMLEntities.new
doc = Hpricot(STDIN.readlines.join)

puts coder.decode(doc.search(xpath).inner_html)


stats = {
}
$stderr.puts stats.to_yaml
