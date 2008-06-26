#!/usr/bin/env ruby

# if recipe is specified incorrectly, this module will be invoked

require "yaml"

args = ARGV.join(' ')

stats = {
  :error => "Unknown command with args '#{args}'"
}
$stderr.puts stats.to_yaml
# nothing to STDOUT
