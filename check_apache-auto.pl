#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use LWP::UserAgent;
use HTTP::Request;


sub help() {
   print <<HERE;
	check_apache-auto.pl
	Fetches the 'server-status?auto' page of an apache server,
		extracts all information and evaluates them.

	This script is based on ideas from that offered on "Nagios Exchange"
	(http://exchange.nagios.org/components/com_mtree/attachment.php?link_id=296&cf_id=24).
	This uses the "server-status? Self" produced by the Apache server (if enabled).
	This version was made by Rober Becht (robert.becht\@habited.net).
	
	usage: check_apache_status -H <hostname or ip(mandatory)> -p <port(80)> 
		-U <username> -P <password>
		-v <character(CPULoad)> -c <critlevel(30)> -w <warnlevel(20)>

	character is guarded that triggers the alert to choose from :
	TotalAccesses 		integer		LiB
        TotalkBytes		integer(KiB)	LiB			
        CPULoad			percent(%)	LiB		
        Uptime			integer(hours)	LiB
        ReqPerSec		real(req/s)	LiB
        BytesPerSec		real(KiB/s)	LiB
	BytesPerReq		real(B/req)	LiB
        BusyWorkers		integer		LiB
	IdleWorkers		integer		HiB

	Note : 	LiB for lower is better and 
		HiB	higher is better.
		You can self determine Higher or Lower is Better 
		by change the default values in following hashes !
		The script contains lines of debugging it is sufficient to enable to fit if necessary.
		If authentication for server access is necessary, it may be that the method is not suitable.
		In this case just change that part.
	Nagios command : \$USER1\$/check_apache-auto.pl -H \$HOSTADDRESS\$ -v \$ARG1$ -c \$ARG2\$ -w \$ARG3\$
			  (without "\")
	     arguments : !CPULoad!25!30 (for example)
	
HERE
   exit;
}

#global variables
use vars qw( $server $mon $user $password $exitcode $alert1 $alert2
	     $uptime $valtab @perfdata2
	    );
my %options = ();
my $port = 80;
my $mon = "CPULoad"; #the default data that triggers the alert
my @alert = ('OK','WARNING','CRITICAL','UNKNOWN');
my $exitcode = 3;
my $alert1 = '';
my $alert2 = '';
my $htmlbrut = '';
my $htmltxt = '';
my @recolte = ();
my %data = ();
my $R = '';
my $topnbr = 10; # Number of items to clear at the beginning of the data collected
my $endnbr = 1; # Number of items to delete the end of the data collected


getopts("H:p:U:P:v:w:c:",\%options);

# Default alert thresholds according to the selected query
# Warning: you must ensure that the names are written 
# exactly as in the table of the data collected?
# If necessary correct the following (or create a hash that translates words)

my %monitor_type = (	'TotalAccesses'		=> 'LiB',
			'TotalkBytes'		=> 'LiB',
			'CPULoad'		=> 'LiB',
			'Uptime'		=> 'LiB',
			'ReqPerSec'		=> 'LiB',
			'BytesPerSec'		=> 'LiB',
			'BytesPerReq'		=> 'LiB',
			'BusyWorkers'		=> 'LiB',
			'IdleWorkers'		=> 'HiB' );			
            
my %critical = (	'TotalAccesses'		=> 100000,
			'TotalkBytes'		=> 60,
			'CPULoad'		=> 30, # in percent
			'Uptime'		=> 30, # in hours
			'ReqPerSec'		=> 6,
			'BytesPerSec'		=> 1000, # in KiB
			'BytesPerReq'		=> 1000, # in KiB
			'BusyWorkers'		=> 10,
			'IdleWorkers'		=> 50 );	
            
my %warning  = (	'TotalAccesses'		=> 30000,
			'TotalkBytes'		=> 30,
			'CPULoad'		=> 20, # in percent
			'Uptime'		=> 25, # in hours
			'ReqPerSec'		=> 4,
			'BytesPerSec'		=> 700, # in KiB
			'BytesPerReq'		=> 768, # in KiB
			'BusyWorkers'		=> 7,
			'IdleWorkers'		=> 70 );

my %adjust_unit = (	'TotalAccesses'		=> 1,
			'TotalkBytes'		=> 0.001,
			'CPULoad'		=> 100,
			'Uptime'		=> 1/3600,
			'ReqPerSec'		=> 1,
			'BytesPerSec'		=> 0.001,
			'BytesPerReq'		=> 0.001,
			'BusyWorkers'		=> 1,
			'IdleWorkers'		=> 1 );

my %units = (		'TotalAccesses'		=> '',
			'TotalkBytes'		=> 'MB',
			'CPULoad'		=> '%',
			'Uptime'		=> 'h',
			'ReqPerSec'		=> 'req/s',
			'BytesPerSec'		=> 'KiB/s',
			'BytesPerReq'		=> 'KiB/req',
			'BusyWorkers'		=> '',
			'IdleWorkers'		=> '' );

my %format_unit = (	'TotalAccesses'		=> '%.0lf',
			'TotalkBytes'		=> '%.3lf',
			'CPULoad'		=> '%.3lf%%',
			'Uptime'		=> '%.4lf',
			'ReqPerSec'		=> '%.3lf',
			'BytesPerSec'		=> '%.3lf',
			'BytesPerReq'		=> '%.3lf',
			'BusyWorkers'		=> '%.0lf',
			'IdleWorkers'		=> '%.0lf' );

my @characters = keys(%monitor_type);	

# Consideration of control parameters
my $server = $options{'H'};
   $mon = $options{'v'} if ($options{'v'}); # the data that triggers the alert
   $port = $options{'p'} if ($options{'p'});
   $user = $options{'U'} if ($options{'U'});
   $password = $options{'P'} if ($options{'P'});

$warning{$mon}  = $options{'w'} if ($options{'w'});
$critical{$mon} = $options{'c'} if ($options{'c'});

help() if (! $options{'H'}); #Displays help in the absence of this parameter (Hostname or IP) need


sub apache_status($) {

    my $hturl = "http://$server:$port/server-status?auto" ;

    my $ua = LWP::UserAgent->new();
      $ua->timeout(10);

    my $req = HTTP::Request->new( GET => $hturl );
     # if login with password is necessary, actively the next line !
     # $req->headers->authorization_basic( $user, $pass );

    $htmlbrut = $ua->request($req)->as_string ;
    $htmlbrut=~ s/ //g;

# Formatting of the data table
    @recolte = split(/\n/,$htmlbrut);
    splice (@recolte, 0, $topnbr);
    splice (@recolte, -$endnbr);
    @recolte = grep { $_ ne '' } @recolte;

    #Debugging
    # print "$req\n";
    # print "$htmlbrut\n";
    #print "@recolte\n\n";
    # Verify this :
    #print "$recolte[0]\n";
    
    my
    @recolte = split(/:/,"@recolte");
    @recolte = split(/ /,"@recolte");
    my $valhash = join(', ',@recolte);
    my %valtab = ( @recolte );

    #Debugging
    #print "@recolte\n";
    #print "$recolte[0]\n";
    #print "$valhash\n";
    # Verify this :
    #print "hash(Uptime) = $valtab{'Uptime'}\n";
    
    return(%valtab) ;
}


sub format_result() {
    
    foreach $R (@characters) {
	my $rdata = sprintf("$format_unit{$R}",($data{$R}*$adjust_unit{$R}));
	push(@perfdata2,"$R=$rdata$units{$R}");
	}
    
    my $mdata = sprintf("$format_unit{$mon}",($data{$mon}*$adjust_unit{$mon}));
    $alert1 = "$mon is ".$mdata."($monitor_type{$mon} as $warning{$mon}$units{$mon})";
    my $perfdata1 = "@perfdata2";
    $perfdata1 =~ s/%{2}/%/g;
#    my $string eq $mon;
    $perfdata1 =~ s/$mon=.{1,10}\s/ /;
    $alert2 = "Other data : $perfdata1" ;
}

sub check_result($) {

my $check = $data{$mon} * $adjust_unit{$mon};
#Debugging
#print "$monitor_type{$mon}\n";

    if ($monitor_type{$mon} eq '') {
    $exitcode = 3;
    }

    if ($monitor_type{$mon} eq 'LiB') { # Lower is better
 	if ($check >= $critical{$mon}) {
		# status CRITICAL for "lower = better"
		$exitcode = 2;		
	    } elsif ($check >= $warning{$mon}) {
		# status WARNING for "lower = better"
		$exitcode = 1;
	    } else {
		# status OK for "lower = better"
		$exitcode = 0;
	    }
	} elsif ($monitor_type{$mon} eq 'HiB') { # Higher is better
	    if ($check <= $critical{$mon}) {
		# status CRITICAL for "higher = better"
		$exitcode = 2;
	    } elsif ($check <= $warning{$mon}) {
		# status WARNING for "higher = better"
		$exitcode = 1;
	    } else {
		# status OK for "higher = better"
		$exitcode = 0;
	    }
	} 
   return($exitcode);
}

sub print_result(){
    # compose the result with perfdata
    print $alert[$exitcode]." - ".$alert1." - ".$alert2." | "."@perfdata2\n";
    exit $exitcode;
}


%data    = apache_status($server);

#Debugging
#print "uptime=$data{'Uptime'}\n";

check_result($mon);

format_result;

print_result;

exit;







