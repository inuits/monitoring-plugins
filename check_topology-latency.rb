#!/usr/bin/env ruby

# Author: Jan Tlusty
# Email:  honza@inuits.eu
# Date:   Thu Mar 02 2017


require 'net/http'
require 'uri'
require 'json'
require 'optparse'

host = 'http://localhost'
port = 8888

warning_latency = 1000
critical_latency= 1200

def usage(optparse)
  puts optparse
  puts 'Usage: ./storm.rb -h <host> -p <port>'
end

optparse = OptionParser.new do |opts|
  opts.on('-h', '--host HOSTNAME', "Hostname") do |f|
    host = f
  end
  opts.on('-p', '--port PORT', "Port") do |f|
    port = f
  end
  opts.on('-H', '--help', "Displays this message") do
    usage(optparse)
    exit 0
  end
end

optparse.parse!


if host !~ /^https?:\/\/.*/
   host = 'http://' + host
end



  topologies = []
  exit_code = 0
  max_latency = 0
  message = ''
  uri_summary = URI::parse("#{host}:#{port}/api/v1/topology/summary")
  req_summary = Net::HTTP::Get.new(uri_summary)
  res_summary = Net::HTTP.start(uri_summary.hostname, uri_summary.port) {|http|
  http.request(req_summary)}
  json_summary = JSON.parse(res_summary.body)

  json_summary['topologies'].each do |topology|
    topologies.push(
      {'name' => topology['name'],
       'id'   => topology['id'],}
                )
  end

  topologies.each do |topology|
    uri = URI::parse("#{host}:#{port}/api/v1/topology/#{topology['id']}")
    req = Net::HTTP::Get.new(uri)
    res = Net::HTTP.start(uri.hostname, uri.port) {|http|
    http.request(req)}
    json = JSON.parse(res.body)
    latency = json['topologyStats'][0]['completeLatency'].to_i
    if latency > max_latency
      max_latency = latency
    end 
    message += "#{topology['name']}: #{latency}ms; "
    end
    if max_latency >= critical_latency
      exit_code = 2
    elsif max_latency >= warning_latency
      exit code = 1
    else
      exit_code = 0 
    end
puts message
exit exit_code
