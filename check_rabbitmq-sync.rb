#!/usr/bin/env ruby

# Author: Jan Tlusty
# Email:  honza@inuits.eu
# Date:   Tue Aug 09 2016

require 'net/http'
require 'uri'
require 'json'
require 'optparse'


def usage(optparse)
  puts optparse
  raise OptionParser::MissingArgument
end

options = {}
optparse = OptionParser.new do |opts|
  opts.on('-h', '--host HOST', "Mandatory Host") do |f|
    options[:host] = f
  end
  opts.on('-u', '--user USER', "Mandatory User Name") do |f|
    options[:user] = f
  end
  opts.on('-p', '--password PASSWORD', "Mandatory Password") do |f|
    options[:password] = f
  end
  opts.on('-v', '--vhost VHOST', "Mandatory Vhost") do |f|
    options[:vhost] = f
  end
  opts.on('-P', '--port PORT', "Mandatory Port") do |f|
    options[:port] = f
  end
end


optparse.parse!

if options[:host] !~ /^https?:\/\/.*/
  options[:host] = 'http://' + options[:host]
end


if options[:host].nil? or options[:user].nil? or options[:password].nil? or options[:vhost].nil? or options[:port].nil?
  usage(optparse)
end


begin
  uri = URI::parse("#{options[:host]}:#{options[:port]}/api/queues/#{options[:vhost]}")
  req = Net::HTTP::Get.new(uri)
  req.basic_auth options[:user], options[:password]
  res = Net::HTTP.start(uri.hostname, uri.port) {|http|
  http.request(req)
}

rescue
  puts 'Unable to log in to the app.'
  exit 3
end

begin
  json = JSON.parse(res.body)
  msg=''
  json.each do |queue|
    if queue.key?('slave_nodes')
      if queue['slave_nodes'].sort != queue['synchronised_slave_nodes'].sort
        msg += "#{queue['name']}: slave_nodes = #{queue['slave_nodes'].sort}, synchronized slave nodes = #{queue['synchronised_slave_nodes'].sort} "
      end
    end
  end
rescue
  puts "Something went wrong, rabbitmq returned #{res.body}"
  exit 3
end

if msg == ''
  puts 'All slave nodes are synchronized'
  exit 0
else
  puts msg
  exit 1
end
