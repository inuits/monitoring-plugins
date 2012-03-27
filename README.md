### Nagios-plugins

This is a selection of plugins for both Nagios and Icinga.<br>
Packages are built in a CI fashion using Jenkins and can be found on our [repo](http://repo.inuits.eu/centos/).

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

* Vagrant

An example Vagrant project has been included to get you started right away.

    cd vagrant
    vagrant up
    vagrant ssh
    cd build
    make

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
