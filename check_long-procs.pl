#! /usr/bin/perl
#
# check_long_procs 2013-02-15
#
# check_long_procs v1.0 plugin for nagios
# This program is distributed under GPL License
# and comes with out warranty
# Please submit any bugs to zeal4linux@gmail.com
# uses the system `ps` command for getting the process durations
# alerts if the process is running for more than 24 hours
#
# Ajoy Bharath
#
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
#use diagnostics; Enable this if you run in to any errors/warnings

# Generic variables
my $progversion = "1";
my $progrevision = "0";
my $prog_name = "check_long_procs";
my %STATUS_CODE = (
                        'OK'       => '0',
                        'WARNING'  => '1',
                        'CRITICAL' => '2' ,
                        'UNKNOWN'  => '3'
);
# Initializing variables
my $critical = 0;
my $pattern = '';
my $neg_pattern = '';
my $help;
my $version;
my %longProcesses;

# Sub Routines
sub print_usage() {
        print "Unknown option: @_\n" if ( @_ );
        print "Usage: $prog_name -c <optional critical value> -p <search pattern> -n <search pattern to exclude> [-v] [-h]\n";
        print "Eg:- $prog_name -c 0 -p java -n oracle.\n";
    	print "Eg:- $prog_name -c 0 -p java -n oracle. PS: Tweak the \$critical value to use -c option\n";
        print "Eg:- $prog_name -c 0 -p \"http|ssh\" -n \"java|grep\".\n";
    	print "Eg:- $prog_name -c 0 -p \"http|ssh\" -n \"java|grep\". PS: Tweak the \$critical value to use -c option\n";
        exit($STATUS_CODE{"UNKNOWN"}) unless ($help);
}

sub print_version() {
        print "$prog_name : $progversion.$progrevision\n";
        exit($STATUS_CODE{"UNKNOWN"});
}

sub print_help () {
    print "$prog_name : $progversion.$progrevision";
    print "\n";
    print "Usage: $prog_name -p <search pattern> -n <search pattern to exclude> [-v] [-h]";
    print "\n";
    print "-c <critcal count> = Count of process to send alert, but is optional as the value is hardcoded.\n";
    print "-p <search pattern> = Search pattern for command grep.\n";
    print "-n <search pattern to exclude> = Search pattern to exclude from grep.\n";
    print "-v = Version.\n";
    print "-h = This screen.\n\n";
    print "Eg:- $prog_name  -p java -n oracle.\n";
    print "Eg:- $prog_name -c 0 -p java -n oracle. PS: Tweak the \$critical value to use -c option\n";
    print "\n";
    print "Eg:- $prog_name  -p \"http|ssh\" -n \"java|grep\".\n";
    print "Eg:- $prog_name -c 0 -p \"http|ssh\" -n \"java|grep\". PS: Tweak the \$critical value to use -c option\n";
    print "\n";
    exit($STATUS_CODE{"UNKNOWN"});
}

print_usage() if ( @ARGV < 1 or
          ! GetOptions('c|critical:i' => \$critical, 'p|pattern=s' => \$pattern,
                       'n|negpattern=s' => \$neg_pattern, 'v|version' => \$version, 'h|help' => \$help));
print_help() if ($help);
print_version() if ($version);

# Syntax check of your specified options
if ($pattern eq "") {
        print "You have to specify a pattern to search with the option -p or --pattern\n";
        print_usage();
}
if ($neg_pattern eq "") {
        print "You have to specify a negative pattern to search with the option -n or --negpattern\n";
        print_usage();
}
chomp ($critical);
chop ($pattern);
chop ($neg_pattern);

my @proc = `ps -Ae -o etime,pid,args |grep -v grep`;
my @procs = grep(/$pattern/, @proc);
my @procs_list = grep(!/$neg_pattern/, @procs);
chomp(@procs_list);
foreach my $line (@procs_list) {
    $line =~ s/^\s*//;
    my ( $etime, $pid, $args ) = split( /\s+/, $line, 3 );
    if ( $etime =~ m/(\d+)-/ ) {
        my $days = $1;
        $longProcesses{$pid} = $days;
    }
}
my $count = my @pids = keys %longProcesses;
chomp ($count);
if ($count == $critical) {
  print "OK - No long running processes\n";
  exit($STATUS_CODE{"OK"});
} else {
    print "CRITICAL - $count long running processes found: PIDS :- @pids\n";
        exit($STATUS_CODE{"CRITICAL"});
    }
