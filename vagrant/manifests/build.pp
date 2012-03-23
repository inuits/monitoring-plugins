exec {
  'repo update':
    command => '/usr/bin/apt-get update';
}

Package {
  require => Exec['repo update'],
}

package {
  'make': ensure => present;
  'rpm':  ensure => present;
}

package {
  'fpm':
    ensure   => present,
    provider => gem;
}

# -*- mode: ruby -*-
# vi: set ft=ruby :
