### Monitoring-plugins

This is a selection of plugins for both Nagios and Icinga.<br>
Packages are built in a CI fashion using Jenkins and can be found on our [repo](https://pulp.inuits.io/inuits/).

A script to build packages yourself is included as well.

### Requirements

* [FPM](https://github.com/jordansissel/fpm)
* Ruby (for FPM)
* rpmbuild


### Usage

RHEL/CentOS:

    yum install rpm-build
    gem install fpm --no-rdoc --no-ri
    cd build
    make

Debian:

    apt-get install rpm
    gem install fpm --no-rdoc --no-ri
    cd build
    make


### Optional

* Jenkins

In order to have Jenkins to build your packages simply add a new command shell build directive, with the following content:

    make


* Vagrant

An example Vagrant project has been included to get you started right away.

    cd vagrant
    vagrant up
    make vagrant-build


### Available plugins

<table>
    <tr>
        <th>Plugin</th><th>Author(s)</th><th>Source</th>
    </tr>
    <tr>
        <td>check_bacula</td>
        <td><a href="https://www.xing.com/profile/Julian_Hein">Julian Hein</a></td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Backup-and-Recovery/Bacula/check_bacula-2Epl/details/">upstream</a></td>
    </tr>
    <tr>
        <td>check_crm</td>
        <td>Phil Garner and Peter Mottram</td>
        <td><a href="https://github.com/C-Otto/check_crm">upstream</a></td>
    </tr>
    <tr>
        <td>check_mem.pl</td>
        <td><a href="http://garretthoneycutt.com/">Garrett Honeycutt</a></td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Uncategorized/Operating-Systems/Linux/check_mem/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_mysqld.pl</td>
        <td><a href="http://william.leibzon.org">William Leibzon</a></td>
        <td><a href="http://william.leibzon.org/nagios/">upstream</a></td>
    </tr>
    <tr>
        <td>check_linux-procstat.pl</td>
        <td><a href="http://william.leibzon.org">William Leibzon</a></td>
        <td><a href="http://william.leibzon.org/nagios/">upstream</a></td>
    </tr>
    <tr>
        <td>check_memcached.pl</td>
        <td><a href="http://william.leibzon.org">William Leibzon</a></td>
        <td><a href="http://william.leibzon.org/nagios/">upstream</a></td>
    </tr>
    <tr>
        <td>check_apache-auto.pl</td>
        <td>Robert Becht</td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Web-Servers/Apache/Robert-Becht/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_puppet.rb</td>
        <td><a href="https://www.devco.net/">R.I. Pienaar</a></ghoneycutttd>
        <td><a href="https://github.com/ripienaar/monitoring-scripts/blob/master/puppet/check_puppet.rb">upstream</a></td>
    </tr>
    <tr>
        <td>check_linux-stats.pl</td>
        <td>Damien Siaud</td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_linux_stats/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_drbd</td>
        <td>Michael Chapman</td>
        <td><a href="https://github.com/anchor/nagios-plugin-drbd">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-lvm-snapshots</td>
        <td><a href="https://www.percona.com/">Percona</a></td>
        <td><a href="https://www.percona.com/software/mysql-tools/percona-monitoring-plugins">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-deadlocks</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-deleted-files</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-file-privs</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-innodb</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-pidfile</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-processlist</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-replication-delay</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-replication-running</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-mysql-status</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-pt-table-checksum</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-unix-memory</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
    </tr>
    <tr>
        <td>check_iostat</td>
        <td>Thiago Varela</td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_iostat--2D-I-2FO-statistics/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_postfix-mailqueue</td>
        <td><a href="http://www.bongermino.de">Bjoern Bongermino</a></td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Email-and-Groupware/Postfix/check_postfix_mailqueue/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_aliveness</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/nagios-plugins-rabbitmq/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_aliveness</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_objects</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_overview</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_queue</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_server</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq_watermark</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
    </tr>
    <tr>
        <td>check_solr.py</td>
        <td><a href="https://github.com/cpganderton">Chris Ganderton</a></td>
        <td><a href="https://github.com/cpganderton/nagios-solr">upstream</a></td>
    </tr>
    <tr>
        <td>check_elasticsearch</td>
        <td><a href="https://github.com/marianschmotzer">Marianschmotzer</a></td>
        <td><a href="https://github.com/marianschmotzer/nagios-plugin-elasticsearch">upstream</a><td>
    </tr>
    <tr>
        <td>check_es_*</td>
        <td><a href="https://github.com/opentable/">Paul Stack</a></td>
        <td><a href="https://github.com/opentable/nagios-elasticsearch">upstream</a></td>
    </tr>
    <tr>
        <td>check_puppetdb_*</td>
        <td><a href="https://github.com/jasonhancock/nagios-puppetdb.git">Jason Hancock</a></td>
        <td><a href="https://github.com/jasonhancock/nagios-puppetdb.git">upstream</a></td>
    </tr>
    <tr>
        <td>check_mongodb.py</td>
        <td><a href="http://zcentric.com/">Mike Zupan</a></td>
        <td><a href="https://github.com/mzupan/nagios-plugin-mongodb.git">upstream</a></td>
    </tr>
    <tr>
        <td>check_printer</td>
        <td><a href="https://www.ciphron.de/">JK</a></td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Hardware/Printers/check_printer--2D-All-in-one-printer-check-suitable-for-most-devices/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_jstat</td>
        <td><a href="https://github.com/Ericbla/">Alcatel-Lucent</a></td>
        <td><a href="https://github.com/Ericbla/check_jstat.git">upstream</a></td>
    </tr>
    <tr>
        <td>check_ntpd-health.pl</td>
        <td><a href="https://github.com/leprasmurf">Tim Forbes</a></td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Network-Protocols/NTP-and-Time/check_ntpd/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_service-restart</td>
        <td><a href="https://exchange.icinga.org/arioch/check_service_restart">Tom De Vylder</a></td>
        <td><a href="https://github.com/arioch/check_service_restart">upstream</a></td>
    </tr>
    <tr>
        <td>check_long-procs</td>
        <td><a href="https://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_long_procs/details">Ajoy Bharath</a></td>
        <td><a href="http://zeal4linux.org/nagios.html">upstream</a></td>
    </tr>
    <tr>
        <td>check_drupal-cron</td>
        <td>unknown</td>
        <td>unknown</td>
    </tr>
    <tr>
	    <td>check_pgactivity</td>
	    <td><a href="http://opm.io">Open PostgreSQL Monitoring</td>
	    <td><a href="https://github.com/OPMDG/check_pgactivity">upstream</td>
    </tr>
    <tr>
        <td>check_collective-access</td>
        <td><a href="https://github.com/honzatlusty">Jan Tlusty</a></td>
        <td><a href="https://github.com/honzatlusty/nagios-collective-access">upstream</a></td>
    </tr>
    <tr>
        <td>check_fileage</td>
        <td><a href="https://github.com/loxo33">loxo33</a></td>
        <td><a href="https://github.com/honzatlusty/sysadmin/blob/master/check_fileage.py">upstream</a></td>
    </tr>
    <tr>
        <td>check_rabbitmq-sync</td>
        <td><a href="https://github.com/honzatlusty">Jan Tlusty</a></td>
        <td><a href="https://github.com/honzatlusty/nagios-rabbitmq-sync">upstream</a></td>
    </tr>
    <tr>
        <td>check_zmstatus</td>
        <td><a href="https://github.com/gmykhailiuta">gmykhailiuta</a></td>
        <td><a href="https://raw.githubusercontent.com/gmykhailiuta/check_zmstatus/master/check_zmstatus.pl">upstream</a></td>
    </tr>
    <tr>
        <td>check_graphite</td>
        <td><a href="https://github.com/datacratic">datacratic</a></td>
        <td><a href="https://github.com/datacratic/check_graphite">upstream</a></td>
    </tr>
    <tr>
        <td>check_ssl_cert</td>
        <td><a href="https://github.com/matteocorti">matteocorti</a></td>
        <td><a href="https://github.com/matteocorti/check_ssl_cert">upstream</a></td>
    </tr>
    <tr>
        <td>check_topology-latency.rb</td>
        <td><a href="https://github.com/honzatlusty">Jan Tlusty</a></td>
        <td><a href="https://github.com/honzatlusty/nagios-storm-topology-latency">upstream</a></td>
    </tr>
    <tr>
        <td>check_graphite-metric</td>
        <td><a href="https://github.com/kali-hernandez">kali-hernandez</a></td>
        <td><a href="https://github.com/kali-hernandez/nagios_plugins/blob/master/check_graphite_metric">upstream</a></td>
    </tr>
</table>

### Contributions

As usual contributions are highly encouraged.
If you'd like to do so, please do not hesitate to send pull requests.

Guidelines:

- Fork this repository
- Add plugin script to the repository
- Add plugin details to build.txt
- Update author table in README.md
- Send a pull request
- ...
- Profit!

