#!/usr/bin/env ruby

require "thin"

class DownloadAdapter
  def call(env)
    req = Rack::Request.new(env)
    cmd_args = req.params.map {|k,v| "--#{k} '#{v}'"}.join(' ')
    cmd = "bin/download.pl #{cmd_args} --background"
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
  map '/files' do
    run Rack::File.new('.')
  end
end
# 
# download = proc do |env|
#   
#   body = ["you said: #{query_string}\n"]                                       # Body of the response
#   [
#     200,                                        # Status code
#     {
#       'Content-Type' => 'text/html',            # Response headers
#       'Content-Length' => body.join.size.to_s
#     },
#     body
#   ]
# end
# 
# pipeline = proc do |env|
#   body = ["bingo\n"]                                       # Body of the response
#   [
#     200,                                        # Status code
#     {
#       'Content-Type' => 'text/html',            # Response headers
#       'Content-Length' => body.join.size.to_s
#     },
#     body
#   ]
# end
# 
# bigapp = Rack::URLMap.new('/download'  => download,
#                        '/pipeline' => pipeline)
# 
# Thin::Server.new('0.0.0.0', 9999, bigapp).start
