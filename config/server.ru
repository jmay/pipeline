#!/usr/bin/env ruby

# require "thin"
require "pp"

class MyAdapter
  def arg_string_for(param, value)
    # Rails Hash#to_query inserts "[]" at the end of the name for array parameters; that must
    # be stripped off to get strings that will work as command-line param labels
    Array(value).map {|v| "--#{param.gsub(/\[\]$/,'')} '#{v}'"}.join(' ')
  end

  def command_line_for(command, args)
    command + ' ' + args.map {|k, v| arg_string_for(k, v)}.join(' ')
  end
end

class DownloadAdapter < MyAdapter
  def call(env)
    req = Rack::Request.new(env)
    cmd = command_line_for('bin/download.pl', req.params) + ' --background'
    system(cmd)
    status = $?.success? ? 200 : 500
    [
      status,
      {
        'Content-Type'   => 'text/plain',
        'Content-Length' => '0',
      },
      []
    ]
  end
end

class PipelineAdapter < MyAdapter
  def call(env)
    req = Rack::Request.new(env)
    cmd = command_line_for('bin/pipeline.pl', req.params) + ' --background'
    system(cmd)
    status = $?.success? ? 200 : 500
    [
      status,
      {
        'Content-Type'   => 'text/plain',
        'Content-Length' => '0',
      },
      []
    ]
  end
end

ObjectSpace.each_object(Thin::Server) do |obj|
  ServerPort = obj.port.to_s
end
logpath = "log/pipelineserver.#{$$}.#{ServerPort}.log"
logfile = File.new(logpath, "w+")
logfile.sync = true # to force unbuffered writes
use Rack::CommonLogger, logfile

$stderr.puts "\nStarting at #{Time.now}"
$stderr.puts "Logging to #{logpath}"

map '/download' do
  run DownloadAdapter.new
end
map '/decipher' do
  run PipelineAdapter.new
end
map '/parse' do
  run PipelineAdapter.new
end
map '/calculate' do
  run PipelineAdapter.new
end
