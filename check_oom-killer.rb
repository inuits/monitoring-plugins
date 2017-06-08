#! /usr/bin/env ruby

# -----------------------
# Author: Andreas Paul (xorpaul) <xorpaul@gmail.com> 
# striped down to only contain oom killer check by 
# Yornik Heyl<yornik@yornik.nl>
# Date: 2013-12-02 10:57
# Version: 0.1.1
# -----------------------

require 'date'
require 'optparse'
require 'yaml'

def check_oom()
  oom_cmd = "dmesg | awk '/invoked oom-killer:/ || /Killed process/'"
  oom_data = `#{oom_cmd}`
  lines_count = oom_data.split("\n").size
  oom_result = {'perfdata' => "oom_killer_lines=#{lines_count}"}
  if lines_count == 2
    oom_result['returncode'] = 1
    invoked_line, killed_line = oom_data.split("\n")
    killed_pid = killed_line.split(" ")[3]
    killed_cmd = "dmesg | grep #{killed_pid}]"
    killed_data = `#{killed_cmd}`
    killed_pid_rss = killed_data.split(" ")[-5].to_i
    oom_result['text'] = "WARNING: #{invoked_line.split(" ")[1]} invoked oom-killer: #{killed_line.split(" ")[1..4].join(" ")} to free #{killed_pid_rss / 1024}MB - reset with dmesg -c when finished"
  elsif lines_count > 3
    # we can't match this with reasonable effort, so just scream for help
    oom_result['returncode'] = 1
    oom_result['text'] = "WARNING: oom-killer was invoked and went on a killing spree (dmesg | awk '/invoked oom-killer:/ || /Killed process/) - reset with dmesg -c when finished"
  else
    oom_result['returncode'] = 0
    oom_result['text'] = "OK: No OOM killer activity found in dmesg output"
    oom_result['perfdata'] = ''
  end
  return oom_result
end

results << check_oom()

puts "\n\nresult array: #{results}\n\n" if $debug


# Aggregate check results

output = {}
output['returncode'] = 0
output['text'] = ''
output['multiline'] = ''
output['perfdata'] = ''
results.each do |result|
  output['perfdata'] += "#{result['perfdata']} " if result['perfdata'] != ''
  if result['returncode'] >= 1
    output['text'] += "#{result['text']} "
    case result['returncode']
    when 3
      output['returncode'] = 3 if result['returncode'] > output['returncode']
    when 2
      output['returncode'] = 2 if result['returncode'] > output['returncode']
    when 1
      output['returncode'] = 1 if result['returncode'] > output['returncode']
    end
  else
    output['multiline'] += "#{result['text']}</br>\n"
  end
end
if output['text'] == ''
  output['text'] = 'OK - everything looks okay'
end

puts "#{output['text']}|#{output['perfdata']}\n#{output['multiline'].chomp()}"

exit output['returncode']
