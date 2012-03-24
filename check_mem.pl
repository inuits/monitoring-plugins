#! /usr/bin/perl -w
#
# $Id: check_mem.pl 8 2008-08-23 08:59:52Z rhomann $
#
# check_mem v1.7 plugin for nagios
#
# uses the output of `free` to find the percentage of memory used
#
# Copyright Notice: GPL
#
# History:
# v1.8 Rouven Homann - rouven.homann@cimt.de
# + added findbin patch from Duane Toler
# + added backward compatibility patch from Timour Ezeev
#
# v1.7 Ingo Lantschner - ingo AT boxbe DOT com
# + adapted for systems with no swap (avoiding divison through 0)
#
# v1.6 Cedric Temple - cedric DOT temple AT cedrictemple DOT info
# + add swap monitoring
#       + if warning and critical threshold are 0, exit with OK
#       + add a directive to exclude/include buffers
#
# v1.5 Rouven Homann - rouven.homann@cimt.de
# + perfomance tweak with free -mt (just one sub process started instead of 7)
# + more code cleanup
#
# v1.4 Garrett Honeycutt - gh@3gupload.com
# + Fixed PerfData output to adhere to standards and show crit/warn values
#
# v1.3 Rouven Homann - rouven.homann@cimt.de
#   + Memory installed, used and free displayed in verbose mode
# + Bit Code Cleanup
#
# v1.2 Rouven Homann - rouven.homann@cimt.de
# + Bug fixed where verbose output was required (nrpe2)
#       + Bug fixed where perfomance data was not displayed at verbose output
# + FindBin Module used for the nagios plugin path of the utils.pm
#
# v1.1 Rouven Homann - rouven.homann@cimt.de
#     + Status Support (-c, -w)
# + Syntax Help Informations (-h)
#       + Version Informations Output (-V)
# + Verbose Output (-v)
#       + Better Error Code Output (as described in plugin guideline)
#
# v1.0 Garrett Honeycutt - gh@3gupload.com
#   + Initial Release
#
use strict;
use FindBin;
FindBin::again();
use lib $FindBin::Bin;
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME $PROGVER);
use Getopt::Long;
use vars qw($opt_V $opt_h $verbose $opt_w $opt_c);

$PROGNAME = "check_mem";
$PROGVER = "1.8";

# add a directive to exclude buffers:
my $DONT_INCLUDE_BUFFERS = 0;

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');
GetOptions ("V"   => \$opt_V, "version"    => \$opt_V,
  "h"   => \$opt_h, "help"       => \$opt_h,
        "v" => \$verbose, "verbose"  => \$verbose,
  "w=s" => \$opt_w, "warning=s"  => \$opt_w,
  "c=s" => \$opt_c, "critical=s" => \$opt_c);

if ($opt_V) {
  print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
  exit $ERRORS{'UNKNOWN'};
}

if ($opt_h) {
  print_help();
  exit $ERRORS{'UNKNOWN'};
}

print_usage() unless (($opt_c) && ($opt_w));

my ($mem_critical, $swap_critical);
my ($mem_warning, $swap_warning);
($mem_critical, $swap_critical) = ($1,$2) if ($opt_c =~ /([0-9]+)[%]?(?:,([0-9]+)[%]?)?/);
($mem_warning, $swap_warning)   = ($1,$2) if ($opt_w =~ /([0-9]+)[%]?(?:,([0-9]+)[%]?)?/);

# Check if swap params were supplied
$swap_critical ||= 100;
$swap_warning  ||= 100;

# print threshold in output message
my $mem_threshold_output = " (";
my $swap_threshold_output = " (";

if ( $mem_warning > 0 && $mem_critical > 0) {
  $mem_threshold_output .= "W> $mem_warning, C> $mem_critical";
}
elsif ( $mem_warning > 0 ) {
  $mem_threshold_output .= "W> $mem_warning";
}
elsif ( $mem_critical > 0 ) {
  $mem_threshold_output .= "C> $mem_critical";
}

if ( $swap_warning > 0 && $swap_critical > 0) {
  $swap_threshold_output .= "W> $swap_warning, C> $swap_critical";
}
elsif ( $swap_warning > 0 ) {
  $swap_threshold_output .= "W> $swap_warning";
}
elsif ( $swap_critical > 0 )  {
  $swap_threshold_output .= "C> $swap_critical";
}

$mem_threshold_output .= ")";
$swap_threshold_output .= ")";

my $verbose = $verbose;

my ($mem_percent, $mem_total, $mem_used, $swap_percent, $swap_total, $swap_used) = &sys_stats();
my $free_mem = $mem_total - $mem_used;
my $free_swap = $swap_total - $swap_used;

# set output message
my $output = "Memory Usage".$mem_threshold_output.": ". $mem_percent.'% <br>';
$output .= "Swap Usage".$swap_threshold_output.": ". $swap_percent.'%';

# set verbose output message
my $verbose_output = "Memory Usage:".$mem_threshold_output.": ". $mem_percent.'% '."- Total: $mem_total MB, used: $mem_used MB, free: $free_mem MB<br>";
$verbose_output .= "Swap Usage:".$swap_threshold_output.": ". $swap_percent.'% '."- Total: $swap_total MB, used: $swap_used MB, free: $free_swap MB<br>";

# set perfdata message
my $perfdata_output = "MemUsed=$mem_percent\%;$mem_warning;$mem_critical";
$perfdata_output .= " SwapUsed=$swap_percent\%;$swap_warning;$swap_critical";


# if threshold are 0, exit with OK
if ( $mem_warning == 0 ) { $mem_warning = 101 };
if ( $swap_warning == 0 ) { $swap_warning = 101 };
if ( $mem_critical == 0 ) { $mem_critical = 101 };
if ( $swap_critical == 0 ) { $swap_critical = 101 };


if ($mem_percent>$mem_critical || $swap_percent>$swap_critical) {
    if ($verbose) { print "<b>CRITICAL: ".$verbose_output."</b>|".$perfdata_output."\n";}
    else { print "<b>CRITICAL: ".$output."</b>|".$perfdata_output."\n";}
    exit $ERRORS{'CRITICAL'};
} elsif ($mem_percent>$mem_warning || $swap_percent>$swap_warning) {
    if ($verbose) { print "<b>WARNING: ".$verbose_output."</b>|".$perfdata_output."\n";}
    else { print "<b>WARNING: ".$output."</b>|".$perfdata_output."\n";}
    exit $ERRORS{'WARNING'};
} else {
    if ($verbose) { print "OK: ".$verbose_output."|".$perfdata_output."\n";}
    else { print "OK: ".$output."|".$perfdata_output."\n";}
    exit $ERRORS{'OK'};
}

sub sys_stats {
    my @memory = split(" ", `free -mt`);
    my $mem_total = $memory[7];
    my $mem_used;
    if ( $DONT_INCLUDE_BUFFERS) { $mem_used = $memory[15]; }
    else { $mem_used = $memory[8];}
    my $swap_total = $memory[18];
    my $swap_used = $memory[19];
    my $mem_percent = ($mem_used / $mem_total) * 100;
    my $swap_percent;
    if ($swap_total == 0) {
  $swap_percent = 0;
    } else {
  $swap_percent = ($swap_used / $swap_total) * 100;
    }
    return (sprintf("%.0f",$mem_percent),$mem_total,$mem_used, sprintf("%.0f",$swap_percent),$swap_total,$swap_used);
}

sub print_usage () {
    print "Usage: $PROGNAME -w <warn> -c <crit> [-v] [-h]\n";
    exit $ERRORS{'UNKNOWN'} unless ($opt_h);
}

sub print_help () {
    print_revision($PROGNAME,'$Revision: '.$PROGVER.' $');
    print "Copyright (c) 2005 Garrett Honeycutt/Rouven Homann/Cedric Temple\n";
    print "\n";
    print_usage();
    print "\n";
    print "-w <MemoryWarn>,<SwapWarn> = Memory and Swap usage to activate a warning message (eg: -w 90,25 ) .\n";
    print "-c <MemoryCrit>,<SwapCrit> = Memory and Swap usage to activate a critical message (eg: -c 95,50 ).\n";
    print "-v = Verbose Output.\n";
    print "-h = This screen.\n\n";
    support();
}
