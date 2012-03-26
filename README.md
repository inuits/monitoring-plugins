### Nagios-plugins

This is a selection of plugins for both Nagios and Icinga.
Packages for RHEL/CentOS and Debian/Ubuntu will be built in a CI fashion in the near future.

A script to build the packages yourself has been included.

### Requirements

* [FPM](https://github.com/jordansissel/fpm)
* Ruby (for FPM)
* rpmbuild 

### Usage

RHEL/CentOS:

    yum install rpm-build
    gem install fpm --no-rdoc --no-ri
    sh build.sh

Debian:

    apt-get install rpm
    gem install fpm --no-rdoc --no-ri
    sh build.sh


### Optional

* Vagrant

An example Vagrant project has been included to get you started right away.

    cd vagrant
    vagrant up
    vagrant ssh
    cd build
    sh build.sh

### Available plugins

<table>
    <tr>
        <th>Plugin</th><th>Author(s)</th><th>Source</th>
    </tr>
    <tr>
        <td>check_bacula</td>
        <td>Julian Hein</td>
        <td><a href="http://exchange.nagios.org/directory/Plugins/Backup-and-Recovery/Bacula/check_bacula-2Epl/details/">upstream</a></td>
    </tr>
    <tr>
        <td>check_mem.pl</td>
        <td><a href="https://github.com/ghoneycutt">Garrett Honeycutt</a></td>
        <td><a href="http://exchange.nagios.org/directory/Plugins/Uncategorized/Operating-Systems/Linux/check_mem/details">upstream</a></td>
    </tr>
    <tr>
        <td>check_mysqld.pl</td>
        <td>William Leibzon</td>
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
        <td>...</td>
        <td>...</td>
        <td><a href="http://google.com">upstream</a></td>
    </tr>
</table>

### Contributions

As usual contributions are highly encouraged.
If you'd like to do so, please do not hesitate to send pull requests.
