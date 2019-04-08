#!/usr/bin/perl -w

# check_ro_mounts.pl Copyright (c) 2008 Valentin Vidic <vvidic@carnet.hr>
#
# Checks the mount table for read-only mounts - these are usually a sign of
# trouble (broken filesystem etc.)
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# you should have received a copy of the GNU General Public License
# along with this program (or with Nagios);  if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA

use strict;
use Getopt::Long;
use lib "/usr/lib/nagios/plugins";
use utils qw (%ERRORS &support);

my $name = 'RO_MOUNTS';
my $mtab = '/proc/mounts';
my @includes = ();
my @excludes = ();
my @excluded_types = ();
my @ro_mounts = ();
my $want_help = 0;

Getopt::Long::Configure(qw(no_ignore_case));
my $res = GetOptions(
    "help|h" => \$want_help,
    "mtab|m=s" => \$mtab,
    "path|p=s" => \@includes,
    "partition=s" => \@includes,
    "exclude|x=s" => \@excludes,
    "exclude-type|X=s" => \@excluded_types,
);

if ($want_help or !$res) {
    print_help();
    exit $ERRORS{$res ? 'OK' : 'UNKNOWN'};
}

my $includes_re       = globs2re(@includes);
my $excludes_re       = globs2re(@excludes);
my $excluded_types_re = globs2re(@excluded_types);

open(MTAB, $mtab) or nagios_exit(UNKNOWN => "Can't open $mtab: $!");
MOUNT: while (<MTAB>) {
    # parse mtab lines
    my ($dev, $dir, $fs, $opt) = split;
    my @opts = split(',', $opt);

    # check includes/excludes
    if ($includes_re) {
        next MOUNT unless $dev =~ qr/$includes_re/
                       or $dir =~ qr/$includes_re/;
    }
    if ($excludes_re) {
        next MOUNT if $dev =~ qr/$excludes_re/
                   or $dir =~ qr/$excludes_re/;
    }
    if ($excluded_types_re) {
        next MOUNT if $fs =~ qr/$excluded_types_re/;
    }

    # check for ro option
    if (grep /^ro$/, @opts) {
        push @ro_mounts, $dir;
    }
}
nagios_exit(UNKNOWN => "Read failed on $mtab: $!") if $!;
close(MTAB) or nagios_exit(UNKNOWN => "Can't close $mtab: $!");

# report findings
if (@ro_mounts) {
    nagios_exit(CRITICAL => "Found ro mounts: @ro_mounts");
} else {
    nagios_exit(OK => "No ro mounts found");
}

# convert glob patterns to a RE (undef if no patterns)
sub globs2re {
    my(@patterns) = @_;

    @patterns or return undef;
    foreach (@patterns) {
        s/ \\(.)       / sprintf('\x%02X', ord($1)) /egx;
        s/ ([^\\*?\w]) / sprintf('\x%02X', ord($1)) /egx;
        s/\*/.*/g;
        s/\?/./g;
    }
    return '\A(?:' . join('|', @patterns) . ')\z';
}

# output the result and exit plugin style
sub nagios_exit {
    my ($result, $msg) = @_;

    print "$name $result: $msg\n";
    exit $ERRORS{$result};
}

sub print_help {
    print <<EOH;
check_ro_mounts 0.1
Copyright (c) 2008 Valentin Vidic <vvidic\@carnet.hr>

This plugin checks the mount table for read-only mounts.


Usage:
  check_ro_mounts [-m mtab] [-p path] [-x path] [-X type]

Options:
 -h, --help
    Print detailed help screen
 -m, --mtab=FILE
    Use this mtab instead (default is /proc/mounts)
 -p, --path=PATH, --partition=PARTITION
    Glob pattern of path or partition to check (may be repeated)
 -x, --exclude=PATH <STRING>
    Glob pattern of path or partition to ignore (only works if -p unspecified)
 -X, --exclude-type=TYPE <STRING>
    Ignore all filesystems of indicated type (may be repeated)

EOH

    support();
}

# vim:sw=4:ts=4:et
