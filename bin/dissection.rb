#!/usr/bin/env ruby

require "dataset"
require "yaml"

begin
  dissector = Dataset::Dissect.new(:input => $stdin)
  puts dissector.recipe.to_yaml
rescue Exception => e
  puts e.to_yaml
end
