### Monitoring-plugins

This is a selection of plugins for both Nagios and Icinga.<br>
Packages are built in a CI fashion using Jenkins and can be found on our [repo](https://pulp.inuits.eu/inuits).

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


* Unit testing

(work in progress)<br>
This requires cucumber to be installed on your workstation.

    cd vagrant
    vagrant up
    make vagrant-validate



### Available plugins

<table>
    <tr>
        <th>Plugin</th><th>Author(s)</th><th>Source</th>
    </tr>
    <tr>
        <td>check_bacula</td>
        <td><a href="http://www.xing.com/profile/Julian_Hein">Julian Hein</a></td>
        <td><a href="http://exchange.nagios.org/directory/Plugins/Backup-and-Recovery/Bacula/check_bacula-2Epl/details/">upstream</a></td>
    </tr>
    <tr>
        <td>check_mem.pl</td>
        <td><a href="http://garretthoneycutt.com/">Garrett Honeycutt</a></td>
        <td><a href="http://exchange.nagios.org/directory/Plugins/Uncategorized/Operating-Systems/Linux/check_mem/details">upstream</a></td>
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
        <td><a href="http://exchange.nagios.org/directory/Plugins/Web-Servers/Apache/Robert-Becht/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_puppet.rb</td>
        <td><a href="http://www.devco.net/">R.I. Pienaar</a></ghoneycutttd>
        <td><a href="https://github.com/ripienaar/monitoring-scripts/blob/master/puppet/check_puppet.rb">upstream</a></td>
    </tr>
    <tr>
        <td>check_linux-stats.pl</td>
        <td>Damien Siaud</td>
        <td><a href="http://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_linux_stats/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_drbd</td>
        <td>Michael Chapman</td>
        <td><a href="https://github.com/anchor/nagios-plugin-drbd">upstream</a></td>
    </tr>
    <tr>
        <td>pmp-check-lvm-snapshots</td>
        <td><a href="http://www.percona.com/">Percona</a></td>
        <td><a href="http://www.percona.com/software/percona-monitoring-plugins/">upstream</a></td>
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
        <td><a href="http://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_iostat--2D-I-2FO-statistics/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_postfix-mailqueue</td>
        <td><a href="http://www.bongermino.de">Bjoern Bongermino</a></td>
        <td><a href="http://exchange.nagios.org/directory/Plugins/Email-and-Groupware/Postfix/check_postfix_mailqueue/details">upstream</a></td>
    </tr>

    <tr>
        <td>check_rabbitmq_aliveness</td>
        <td><a href="http://jamesc.net/">James Casey</a></td>
        <td><a href="https://github.com/jamesc/nagios-plugins-rabbitmq">upstream</a></td>
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
        <td>check_solr</td>
        <td><a href="http://visibilityspots.com/">Jan Collijs</a></td>
        <td><a href="https://github.com/visibilityspots/icinga-scripts#solr">upstream</a></td>
    </tr>
    <tr>
        <td>check_solr_rows</td>
        <td><a href="http://github.com/sperris">J.P. Dowd</a></td>
        <td><a href="https://github.com/sperris/check_solr_rows">upstream</a></td>
    </tr>
    <tr>
        <td>check_es_*</td>
        <td><a href="https://github.com/opentable/">Paul Stack</a></td>
        <td><a href="https://github.com/opentable/nagios-elasticsearch">upstream</a></td>

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

