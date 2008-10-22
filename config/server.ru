#!/usr/bin/env ruby
#
# Numbrary batch server
#
# This server runs under thin/rack
#
# Start it up with
#
#    thin start -R config/server.ru -p XXXX -d
#
# Handles POST requests to:
#
#    /download - runs bin/download.pl
#    /decipher - runs bin/pipeline.pl
#    /parse    - runs bin/pipeline.pl
#    /calculate - runs bin/pipeline.pl
#
# In response to a POST, it will send back an empty response, either a success (200) or error (500).
# A success indicates that the batch process was successfully initiated in the background; if all
# goes well it should transmit results via POST back to the postback URL provided in the request payload.
# An error means that it was unable to start up the process, e.g. if required parameters are missing.
#

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
    $stderr.puts cmd
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
    $stderr.puts cmd
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

class AnalyzeAdapter < MyAdapter
  def call(env)
    req = Rack::Request.new(env)
    cmd = command_line_for('bin/analyze.pl', req.params) + ' --background'
    $stderr.puts cmd
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

class DissectAdapter < MyAdapter
  def call(env)
    req = Rack::Request.new(env)
    cmd = command_line_for('bin/dissect.pl', req.params) + ' --background'
    $stderr.puts cmd
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

class CoalesceAdapter < MyAdapter
  def call(env)
    req = Rack::Request.new(env)
    cmd = "bin/coalesce.pl --background --postback #{req.params['postback']} #{req.params['files[]'].join(' ')}"
    $stderr.puts cmd
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
logpath = "log/batchserver.#{$$}.#{ServerPort}.log"
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
map '/inspect' do
  run AnalyzeAdapter.new
end
map '/dissect' do
  run DissectAdapter.new
end
map '/coalesce' do
  run CoalesceAdapter.new
end
