#!/usr/bin/perl -w
# Name    : check_zammad.pl
# Date    : 05 09 2019
# Author  : Karel Willems - kwillems@inuits.eu
# Summary : This is a Icinga plugin that checks if there are any open tickets in zammad
# Licence : Apache 2.0 -  full text at http://www.apache.org/licenses/LICENSE-2.0


use LWP;
use JSON;
use Monitoring::Plugin;


my $plugin = Monitoring::Plugin->new(
  plugin    => 'check_zammadqueue',
  shortname => 'Zammadqueue',
  version   => 'v0.1',
  url       => 'https://github.com/inuits/monitoring-plugins',
  blurb     => 'Icinga Plugin for checking new zammad tickets',
  usage     => 'Usage: ',
  license => 'http://www.apache.org/licenses/LICENSE-2.0',
  extra   => '
Tested with zammad 2.9.0, perl v5.30.0'
);


my @args = (
  {
    spec     => 'hostname|H=s',
    usage    => '-H, --hostname=STRING',
    desc     => 'Hostname of the Zammad server to read from',
    required => 1,
  },
   {
     spec     => 'token|T=s',
     usage    => '-T, --token=STRING',
     desc     => 'token to authenticate with',
     required => 1,
   },
   {
     spec     => 'protocol|p=s',
     usage    => '-p, --protocol=STRING',
     desc     => 'use http or https',
     default  => 'http',
     required => 0,
   },
   {
    spec     => 'port|P=i',
    usage    => '-P, --port=INTEGER',
    desc     => 'specify port',
    default  => 80,
    required => 0,
  },
);



foreach my $arg (@args) {
  add_arg( $plugin, $arg );
}
$plugin->getopts;


sub add_arg {
  my $plugin = shift;
  my $arg    = shift;

  my $spec     = $arg->{'spec'};
  my $help     = $arg->{'usage'};
  my $default  = $arg->{'default'};
  my $required = $arg->{'required'};

  if ( defined $arg->{'desc'} ) {
    my @desc;

    if ( ref( $arg->{'desc'} ) ) {
      @desc = @{ $arg->{'desc'} };
    } else {
      @desc = ( $arg->{'desc'} );
    }

    foreach my $d (@desc) {
      $help .= "\n   $d";
    }
  }

  $plugin->add_arg(
    spec     => $spec,
    help     => $help,
    default  => $default,
    required => $required,
  );
}


check_queue ( $plugin );

sub send_request {

  my $plugin = shift;
  my $params = shift;

  my $lwp = LWP::UserAgent->new(
    timeout    => '20',
    ssl_opts   => {
      verify_hostname => 0,
      SSL_verify_mode => 0
    },
  );

  my $protocol = $plugin->opts->protocol . '://';

  my $port = $plugin->opts->port;

  my $url = $protocol . $plugin->opts->hostname . ':' . $port . '/api/v1/tickets/search?query=state:new';

  my $request = HTTP::Request->new( GET => $url );

  $request->header( 'Authorization', 'Token token=' . $params->{'token'} );

  my $response = $lwp->request($request);

  if ( HTTP::Status::is_error( $response->code ) ) {
    $plugin->nagios_die( $response->content );
  } else {
    $response = JSON->new->allow_blessed->convert_blessed->decode( $response->content );
  }

  return $response;
}



sub check_queue {

  my $plugin = shift;
  my $tickets_count = 0;


  my %params;

  $params{'token'} = $plugin->opts->token;


  my $response = send_request( $plugin, \%params);


  $tickets_count = $response->{'tickets_count'};

  if ( $tickets_count > 0 ) {
    $plugin->nagios_exit( CRITICAL, " There are $tickets_count tickets open ");
  } else {
    $plugin->nagios_exit( OK, "There are no new tickets open");
  }

}
