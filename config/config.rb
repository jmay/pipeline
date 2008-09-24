#!/usr/bin/env ruby

require "thin"
require "pp"

def arg_string_for(param, value)
  Array(value).map {|v| "--#{param} '#{v}'"}.join(' ')
end

def command_line_for(command, args)
  command + ' ' + args.map {|k, v| arg_string_for(k, v)}.join(' ')
end

class DownloadAdapter
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

class PipelineAdapter
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

Thin::Server.start('0.0.0.0', 9999) do
  use Rack::CommonLogger
  map '/download' do
    run DownloadAdapter.new
  end
  map '/decipher' do
    run PipelineAdapter.new
  end
  map '/parse' do
    run PipelineAdapter.new
  end
end
