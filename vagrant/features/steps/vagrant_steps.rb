When /^I download the basebox from "(.*)"$/ do |url|
  visit url
end

Then /^downloading the (.*) ?basebox should succeed/ do |_|
  success_code?.should be_true
end

When /^I verify network settings '(.+)'$/ do |ip|
  cmd = 'ssh vagrant -c "sudo ifconfig | grep "'
  status = Cucumber::Nagios::Command.popen4(cmd, :ip) do |p, i, o, e|
    @stdout = o.gets(nil)
    @stderr = e.gets(nil)
  end
  @status = status
end

Then /^I should see the defined IP address/ do
    @status.exitstatus.should eql(exit_code.to_i)
end
