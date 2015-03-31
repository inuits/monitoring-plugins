#!/usr/bin/perl -w

#version: 2.1
#source: http://exchange.nagios.org/directory/Plugins/Network-Protocols/NTP-and-Time/check_ntpd/details
#owner: leprasmurf (tim.forbes@infotechfl.com)

use Getopt::Long;
use strict;

GetOptions(
                "critical=i" => \(my $critical_threshold = '50'),
                "warning=i" => \(my $warning_threshold = '75'),
                "peer_critical=i" => \(my $peer_critical_threshold = '1'),
                "peer_warning=i" => \(my $peer_warning_threshold = '2'),
                "help" => \&display_help,
);

my $ntpq_path = `/usr/bin/which ntpq`;
my $pidof_path = `/usr/bin/which pidof`;
$ntpq_path =~ s/\n//g;
$pidof_path =~ s/\n//g;
my @server_list = `$ntpq_path -pn`;
my %server_health;
my $peer_count;
my $overall_health = 0;
my $good_count;
my $selected_primary = "false";
my $selected_backup = 0;

my $ntpd_uptime = 0;
my $uptime = 0;
my $ntpd_elapsed_time = 0;

my $pid_ntpd = `$pidof_path ntpd|cut -d' ' -f 1`;
$pid_ntpd =~ s/\n//g;

# Check if ntpd daemon is not just restarted
if($pid_ntpd eq  "") {
        print_overall_health("Critical");
        print_server_list();
        exit 2;
} else {
        my $ntpd_pid_path = "/proc/$pid_ntpd/stat";
        $ntpd_uptime = `awk '{print int(\$22 / 100)}' $ntpd_pid_path`;
        $ntpd_uptime =~ s/\n//g;
        $uptime = `awk '{print int(\$1)}' /proc/uptime`;
        $uptime =~ s/\n//g;
        $ntpd_elapsed_time = $uptime - $ntpd_uptime;
        if($ntpd_elapsed_time < 900) {
                print "OK - NTPd deamon started 15 minutes ago, syncing with NTP servers";
                exit 0;
        }
}

# Check if there are enough good servers
for(my $j = 0; $j < @server_list; $j++) {
        #split each element of the peer line
        my @tmp_array = split(" ", $server_list[$j]);

        # Check for first character of peer
        # space = Discarded due to high stratum and/or failed sanity checks.
        # x = Designated falseticker by the intersection algorithm.
        # . = Culled from the end of the candidate list.
        # - = Discarded by the clustering algorithm.
        # + = Included in the final selection set.
        # # = Selected for synchronization but distance exceeds maximum.
        # * = Selected for synchronization.
        # o = Selected for synchronization, pps signal in use.
        if(substr($tmp_array[0], 0, 1) eq '*') {
                $selected_primary = "true";
        } elsif(substr($tmp_array[0], 0, 1) eq '+') {
                $selected_backup++;
        }
}


# Cleanup server list
for(my $i = 0; $i < @server_list; $i++) {
        if(($server_list[$i] =~ /LOCA?L/) || ($server_list[$i] =~ /INIT/)) {
                splice(@server_list, $i, 1);
                $i--;
        } elsif($server_list[$i] =~ /^===/) {
                splice(@server_list, $i, 1);
                $i--;
        } elsif($server_list[$i] =~ /STEP/) {
                splice(@server_list, $i, 1);
                $i--;
        } elsif($server_list[$i] =~ /jitter$/) {
                splice(@server_list, $i, 1);
                $i--;
        } elsif($server_list[$i] =~ /^No association/) {
                splice(@server_list, $i, 1);
                $i--;
        }
}

# Get number of peers
$peer_count = @server_list;

# Cycle through peers
for(my $i = 0; $i < @server_list; $i++) {
        #split each element of the peer line
        my @tmp_array = split(" ", $server_list[$i]);

        $good_count = 0;
        # Read in the octal number in column 6
        my $rearch = oct($tmp_array[6]);

        # while $rearch is not 0
        while($rearch) {
                # 1s place 0 or 1?
                $good_count += $rearch % 2;
                # Bit shift to the right
                $rearch = $rearch >> 1;
        }

        # Calculate good packets received
        $rearch = int(($good_count / 8) * 100);

        # Set percentage in hash
        $server_health{$tmp_array[0]} = $rearch;
}

# Cycle through hash and tally weighted average of peer health
while(my($key, $val) = each(%server_health)) {
        $overall_health += $val * (1 / $peer_count);
}

########################### Nagios Status checks ###########################
#if overall health is below critical threshold, crit
if($overall_health <= $critical_threshold) {
        print_overall_health("Critical");
        print_server_list();
        exit 2;
}

#if overall health is below warning and above critical threshold, warn
if(($overall_health <= $warning_threshold) && ($overall_health > $critical_threshold)) {
        print_overall_health("Warning");
        print_server_list();
        exit 1;
}

#if the number of peers is below the critical threshold, crit
if($peer_count <= $peer_critical_threshold) {
        print_overall_health("Critical");
        print_server_list();
        exit 2;
#if the number of peers is below the warning threshold, warn
} elsif($peer_count <= $peer_warning_threshold) {
        print_overall_health("Warning");
        print_server_list();
        exit 1;
}

#check to make sure we have one backup and one selected ntp server
#if there is no primary ntp server selected, crit
if($selected_primary ne "true") {
        print_overall_health("Critical");
        print_server_list();
        exit 2;
#if there is no backup ntp server selected, warn
} elsif($selected_backup < 1) {
        print_overall_health("Warning");
        print_server_list();
        exit 1;
}

print_overall_health("OK");
print_server_list();
exit 0;

sub print_server_list {
        print "---------------------------\n";
        while(my($key, $val) = each(%server_health)) {
                print "Received " . $val . "% of the traffic from " . $key . "\n";
        }
}

sub print_overall_health {
        print $_[0] . " - NTPd Health is " . $overall_health . "% with " . $peer_count . " peers.\n";
}

sub display_help {
        print "This nagios check is to determine the health of the NTPd client on the local system.  It uses the reach attribute from 'ntpq -pn' to determine the health of each listed peer, and determines the average health based on the number of peers.  For example, if there are 3 peers, and one peer has dropped 2 of the last 8 packets, it's health will be 75%.  This will result in an overall health of about 92% ((100+100+75) / 3).\n";
        print "\n";
        print "Available Options:\n";
        print "\t--critical|-c <num>\t-Set the critical threshold for overall health (default:50)\n";
        print "\t--warning|-w <num>\t-Set the warning threshold for overall health (default:75)\n";
        print "\t--peer_critical <num>\t-Set the critical threshold for number of peers (default:1)\n";
        print "\t--peer_warning <num>\t-Set the warning threshold for number of peers (default:2)\n";
        print "\t--help|-h\t\t-display this help\n";
        exit 0;
}

