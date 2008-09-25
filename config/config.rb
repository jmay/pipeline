#!/usr/bin/env ruby

require "thin"

def arg_string_for(param, value)
  # Rails Hash#to_query inserts "[]" at the end of the name for array parameters; that must
  # be stripped off to get strings that will work as command-line param labels
  Array(value).map {|v| "--#{param.gsub(/\[\]$/,'')} '#{v}'"}.join(' ')
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
  map '/calculate' do
    run PipelineAdapter.new
  end
end
