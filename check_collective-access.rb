#!/usr/bin/env ruby

# Author: Jan Tlusty
# Email:  honza@inuits.eu
# Date:   Fri Jun 24 2016

require 'nokogiri'
require 'pp'
require 'open-uri'
require 'optparse'
require 'yaml'
require 'openssl'

exit_code = 0
options = {}
errors = []

def usage(optparse)
  puts optparse
  puts 'Example usage: ./check_collective_access.rb -u user -h collectiveaccess.yourcompany.com  -p password -c config.yaml
  example config.yaml file:
    ---
    MySQL is back-end database:
      expected: ok
      severity: 2
    SqlSearch database tables exist:
      expected: ok
      severity: 2
  where severity is the exit code that will be used if an item status does not correspond to its expected value, if multiple items are different from their
  expected values, the maximum severity value is used.'

  raise OptionParser::MissingArgument
end

optparse = OptionParser.new do |opts|
  opts.on('-h', '--host HOSTNAME', "Mandatory Host Name") do |f|
    options[:host] = f
  end
  opts.on('-u', '--user USER', "Mandatory User Name") do |f|
    options[:user] = f
  end
    opts.on('-p', '--password PASSWORD', "Mandatory Password") do |f|
    options[:password] = f
  end
    opts.on('-c', '--config CONFIG', "Mandatory Config File") do |f|
    options[:config] = f
  end
end

optparse.parse!

if options[:host].nil? or options[:user].nil? or options[:password].nil?  or options[:config].nil?
  usage(optparse)
end

expected_states = YAML.load(File.read(options[:config]))

begin
html_auth = open("https://#{options[:host]}/service.php/auth/login", :http_basic_authentication=>[options[:user], options[:password]], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
html = open("https://#{options[:host]}/index.php/administrate/setup/ConfigurationCheck/DoCheck", "Cookie" => html_auth.meta['set-cookie'][/collectiveaccess=[^;]+/], :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
rescue
 puts 'Unable to log in to the app, it is either misconfigured or the wrong credentials have been provided'
 exit 3
end
doc = Nokogiri::HTML(html)
rows = doc.css('//*/table[@id="caSearchConfigSettingList"]/tbody/tr')
rows += doc.css('//*/table[@id="caMediaConfigPluginList"]/tbody/tr')

details = {}
rows.collect do |row|
  h1 = {row.at_xpath('td[1]/text()').to_s.strip => row.at_xpath('td[3]/span[1]/text()').to_s.strip}
  details =  details.merge(h1)
end

expected_states.keys.each do |x|
  unless details[x] == expected_states[x]['expected']
    errors.push(x)
    if  expected_states[x]['severity'] > exit_code
      exit_code = expected_states[x]['severity']
    end
  end
end

if errors.empty?
  puts 'All items are in the expected state'
else
  puts 'Items not in the expected state: ' + errors.join(', ') +
  "\nActual values are:\n"
  errors.each do |x|
    puts "#{x} = #{details[x]}"
  end
end
exit exit_code
