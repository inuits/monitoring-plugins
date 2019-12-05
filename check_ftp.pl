#! /usr/bin/perl
# nagios: -epn
# anders@fupp.net, 2014-05-05
# Test active/passive FTP + upload/download
use Net::FTP;
use Getopt::Std;
use File::Basename;

getopts('h:u:p:df:');

sub usage {
	print "Usage: check_ftp_alt -h <host> -u <user> -p <pass> [-f <file to upload>]\n";
	exit(1);
}

usage unless ($opt_h && $opt_u && $opt_p);
if ($opt_d) {
	$debug = 3;
} else {	
	$debug = 0;
}
my @chars = ("A".."Z", "a".."z");
my $string;
my $upload_message=' ';

$string .= $chars[rand @chars] for 1..8;
$randfile = "/tmp/$string.dat";
$|=1;  # Flush stdout after every write.

sub errexit {
	my $txt = shift;
	print "$txt\n";
	exit(2);
}
sub doftp {
	my $passive = shift;
	if ($passive == 0) {
		$modetxt = "actively";
	#	print "Active.\n";
#		$ENV{'FTP_PASSIVE'} = 0;
	} else {
#		print "Passive.\n";
		$modetxt = "passively";
#		$ENV{'FTP_PASSIVE'} = 1;
	}

#	print "passive=$passive debug=$debug\n";
	$ftp = Net::FTP->new($opt_h, Timeout => 5, Passive => $passive, Debug => $debug);
#, Debug => 1) {
	unless (defined $ftp) {
		errexit("Could not $modetxt connect with FTP to $opt_h: $@");
	}
	unless ($ftp->login($opt_u, $opt_p)) {
		errexit("Could not login as FTP user $opt_u.");
	}
	if ($opt_f) {
                $upload_message=' and upload/delete ';
		$basef = basename($opt_f);
		unless ($ftp->put($opt_f)) {
			errexit("Could not $modetxt upload file $basef.");
		}
		if  ($ftp->get($basef, $randfile)) {
			unlink($randfile);
		} else {
			errexit("Could not $modetxt download file $basef after uploading.");
		}
		unless ($ftp->delete($basef)) {
			errexit("Could not $modetxt delete file $basef.");
		}
	}
}

doftp(1);
doftp(0);

print "All FTP tests, active/passive login${upload_message}performed OK.\n";
exit(0);
