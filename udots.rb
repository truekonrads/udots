#!/usr/bin/env ruby
#!/usr/bin/env ruby
require 'rubydns'
require 'trollop'

DEFAULT_SOCKS_VERSION="4"
SOCKS_SERVER_REGEX=/(.+):(\d{1,5})/

opts = Trollop::options do
      version "udots v0.1a by @truekonrads"
      opt :zone, "Only resolve these queries/zones (it's a regex)", :type => :string, :default =>'\.'
      opt :port, "Port to listen to", :type => :int, :default => 53
      opt :upstream_host, "Upstream DNS host", :type=> :string, :required  => true
      opt :upstream_port, "Upstream DNS port", :type=> :int, :default => 53
     
      opt :interface, "Interface to which to listen to", :type => :string, :default => "0.0.0.0"
      opt :loglevel, "Log level - DEBUG, INFO, etc", :type => :string, :default => "INFO"
    #   opt :socks_version, "Version of socks server, default #{DEFAULT_SOCKS_VERSION}", :type => :string, :default => DEFAULT_SOCKS_VERSION
    #   opt :socks_server, "socks server as <host:port>", :type=> :string, :required => false

end
# Trollop::die :socks_version, "Valid choices are 4, 4a and 5 and not `#{opts[:sockver]}`" if !(["4","4a","5"].include? opts[:socks_version])
# Trollop::die :socks_server, "Please specify socks server as <host:port>" if ( (!opts[:socks_server].nil?) && (!opts[:socks_server].match(SOCKS_SERVER_REGEX)))
 
# if !opts[:socks_server].nil?
#     require 'socksify'
#     (server,port)=opts[:socks_server].match(SOCKS_SERVER_REGEX).captures
#     puts "Server is: #{server} and port is: #{port}"
#     TCPSocket.socks_server=server
#     TCPSocket.socks_port=port.to_i
#     TCPSocket.socks_version=opts[:socks_version]
# end

UPSTREAM = RubyDNS::Resolver.new([[:tcp, opts[:upstream_host], opts[:upstream_port]]])
INTERFACES = [
    [:udp, opts[:interface], opts[:port]],
    [:tcp, opts[:interface], opts[:port]],
]

RubyDNS::run_server(INTERFACES) do
    on(:start) do
      @logger.level = eval("Logger::#{opts[:loglevel]}")
    end

    match(/#{Regexp.new(opts[:zone])}/) do |transaction, match_data| 
        transaction.passthrough!(UPSTREAM)        
    end

    otherwise do |transaction| 
        transaction.fail!(:Refused)        
    end
end