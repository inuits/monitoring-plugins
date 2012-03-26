#!/bin/bash

## Script:  build.sh
## Version: 0.1.1
## Date:    2012-03-23
## Author:  Tom De Vylder <tomdv@inuits.eu>
## Contrib: 

set -e

for PLUGIN in $(grep -viE '^#' build.txt | awk {'print $1'} | sort | uniq )
do
  PLUGIN_NAME_DEBIAN=$(echo ${PLUGIN} | sed -e 's/check_/check-/g' | cut -d '.' -f 1)
  PLUGIN_NAME_RHEL=$(echo ${PLUGIN} | sed -e 's/check_//g' | cut -d '.' -f 1)
  PLUGIN_VERSION=$(grep -E "^${PLUGIN}\s" build.txt | awk {'print $2'})
  PLUGIN_ITERATION=$(grep -E "^${PLUGIN}\s" build.txt | awk {'print $3'})
  
  echo -e "\e[1;34m[\e[00m --- \e[00;32mBuild package: ${PLUGIN}\e[00m --- \e[1;34m]\e[00m\n"
  # Build Debian 5/6 package
  fpm -s dir -t deb --architecture all \
    -n nagios-plugin-${PLUGIN_NAME_DEBIAN} \
    -v ${PLUGIN_VERSION} --iteration ${PLUGIN_ITERATION} \
    --prefix /usr/lib/nagios/plugins/ \
    ${PLUGIN} &>/dev/null
  cp nagios-plugin-${PLUGIN_NAME_DEBIAN}_${PLUGIN_VERSION}-${PLUGIN_ITERATION}_all.deb packages/debian/5/
  mv nagios-plugin-${PLUGIN_NAME_DEBIAN}_${PLUGIN_VERSION}-${PLUGIN_ITERATION}_all.deb packages/debian/6/

  # Build RHEL 5/6 x86_64 package
  fpm -s dir -t rpm --architecture x86_64 \
    -n nagios-plugins-${PLUGIN_NAME_RHEL} \
    -v ${PLUGIN_VERSION} --iteration ${PLUGIN_ITERATION} \
    --prefix /usr/lib64/nagios/plugins/ \
    ${PLUGIN} &>/dev/null
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/5/
  mv nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/6/
done

