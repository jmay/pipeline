#!/usr/bin/env ruby

require "dataset"
require "yaml"

dissector = Dataset::Dissect.new(:input => $stdin)
puts dissector.recipe.to_yaml
