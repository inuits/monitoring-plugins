#!/bin/bash

## Script:  build.sh
## Version: 0.1.5
## Date:    2014-01-31
## Author:  Tom De Vylder <tomdv@inuits.eu>
## Contrib:

set -e -x

rm -rf *.deb
rm -rf *.rpm

if [ -z "${GIT_PREVIOUS_COMMIT}" ] && [ -e last_success ]; then
  GIT_PREVIOUS_COMMIT=$(cat last_success)
fi

# Prep output directories
mkdir -p packages/debian/{5,6}
mkdir -p packages/rhel/{5,6,7,8,9}

# Go over each defined plugin
for PLUGIN in $(grep -viE '^#|^$' build.txt | awk {'print $1'} | sort | uniq); do
  PLUGIN_NAME_DEBIAN=$(echo ${PLUGIN} | sed -e 's/check_/check-/g' | tr '_' '-' | cut -d '.' -f 1)
  PLUGIN_NAME_RHEL=$(echo ${PLUGIN} | sed -e 's/check_//g' | cut -d '.' -f 1)
  PLUGIN_VERSION=$(grep -E "^${PLUGIN}\s" build.txt | awk {'print $2'})
  PLUGIN_ITERATION=$(git rev-list HEAD -- "${PLUGIN}" | wc -l)
  PLUGIN_EPOCH=$(date +'%s')
  PLUGIN_URL="https://github.com/inuits/monitoring-plugins"

  echo -e "\e[1;34m[\e[00m --- \e[00;32mBuild package: ${PLUGIN}\e[00m --- \e[1;34m]\e[00m"

  # Enforce permissions
  chmod 755 ${PLUGIN}

  # Build Debian 5/6 package
  fpm -s dir -t deb --architecture all \
    -n nagios-plugin-${PLUGIN_NAME_DEBIAN} \
    -v ${PLUGIN_VERSION} --iteration ${PLUGIN_ITERATION} --epoch $PLUGIN_EPOCH \
    --prefix /usr/lib/nagios/plugins \
    --description "Nagios Plugin - ${PLUGIN_NAME_DEBIAN}" \
    --url "${PLUGIN_URL}" \
    ${PLUGIN} &>/dev/null
  cp nagios-plugin-${PLUGIN_NAME_DEBIAN}_${PLUGIN_VERSION}-${PLUGIN_ITERATION}_all.deb packages/debian/5/
  mv nagios-plugin-${PLUGIN_NAME_DEBIAN}_${PLUGIN_VERSION}-${PLUGIN_ITERATION}_all.deb packages/debian/6/

  # Build RHEL 5/6 i386 package
  setarch i386 fpm -s dir -t rpm --architecture i386 \
    -n nagios-plugins-${PLUGIN_NAME_RHEL} \
    -v ${PLUGIN_VERSION} --iteration ${PLUGIN_ITERATION} --epoch $PLUGIN_EPOCH \
    --prefix /usr/lib64/nagios/plugins \
    --description "Nagios Plugin - ${PLUGIN}" \
    --url "${PLUGIN_URL}" \
    ${PLUGIN} &>/dev/null
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.i386.rpm packages/rhel/5/
  mv nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.i386.rpm packages/rhel/6/

  # Build RHEL 5/6 i686 package
  setarch i686 fpm -s dir -t rpm --architecture i686 \
    -n nagios-plugins-${PLUGIN_NAME_RHEL} \
    -v ${PLUGIN_VERSION} --iteration ${PLUGIN_ITERATION} --epoch $PLUGIN_EPOCH \
    --prefix /usr/lib64/nagios/plugins \
    --description "Nagios Plugin - ${PLUGIN}" \
    --url "${PLUGIN_URL}" \
    ${PLUGIN} &>/dev/null
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.i686.rpm packages/rhel/5/
  mv nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.i686.rpm packages/rhel/6/

  # Build RHEL 5/6/7/8/9 x86_64 package
  setarch x86_64 fpm -s dir -t rpm --architecture x86_64 \
    -n nagios-plugins-${PLUGIN_NAME_RHEL} \
    -v ${PLUGIN_VERSION} --iteration ${PLUGIN_ITERATION} --epoch $PLUGIN_EPOCH \
    --prefix /usr/lib64/nagios/plugins \
    --description "Nagios Plugin - ${PLUGIN}" \
    --url "${PLUGIN_URL}" \
    ${PLUGIN} &>/dev/null
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/5/
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/6/
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/7/
  cp nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/8/
  mv nagios-plugins-${PLUGIN_NAME_RHEL}-${PLUGIN_VERSION}-${PLUGIN_ITERATION}.x86_64.rpm packages/rhel/9/
done

git rev-parse HEAD >last_success
