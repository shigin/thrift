require 'thrift/transport'

require 'net/http'
require 'uri'
require 'stringio'

## Very simple HTTP client
module Thrift
  class HTTPClient < Transport
    def initialize(url)
      @url = URI url
      @outbuf = ""
    end

    def open?; true end
    def read(sz); @inbuf.read sz end
    def write(buf); @outbuf << buf end
    def flush
      http = Net::HTTP.new @url.host, @url.port
      resp, data = http.post(@url.path, @outbuf)
      @inbuf = StringIO.new data
      @outbuf = ""
    end
  end
  deprecate_class! :THttpClient => HTTPClient
end
