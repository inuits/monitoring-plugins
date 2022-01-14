#!/bin/bash
################################################################################
# Script:       check_es_system.sh                                             #
# Author:       Claudio Kuenzler www.claudiokuenzler.com                       #
# Purpose:      Monitor ElasticSearch Store (Disk) Usage                       #
# Official doc: www.claudiokuenzler.com/monitoring-plugins/check_es_system.php #
# License:      GPLv2                                                          #
# GNU General Public Licence (GPL) http://www.gnu.org/                         #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, see <https://www.gnu.org/licenses/>.        #
#                                                                              #
# Copyright 2016,2018-2021 Claudio Kuenzler                                    #
# Copyright 2018 Tomas Barton                                                  #
# Copyright 2020 NotAProfessionalDeveloper                                     #
# Copyright 2020 tatref                                                        #
# Copyright 2020 fbomj                                                         #
# Copyright 2021 chicco27                                                      #
#                                                                              #
# History:                                                                     #
# 20160429: Started programming plugin                                         #
# 20160601: Continued programming. Working now as it should =)                 #
# 20160906: Added memory usage check, check types option (-t)                  #
# 20160906: Renamed plugin from check_es_store to check_es_system              #
# 20160907: Change internal referenced variable name for available size        #
# 20160907: Output now contains both used and available sizes                  #
# 20161017: Add missing -t in usage output                                     #
# 20180105: Fix if statement for authentication (@deric)                       #
# 20180105: Fix authentication when wrong credentials were used                #
# 20180313: Configure max_time for Elastic to respond (@deric)                 #
# 20190219: Fix alternative subject name in ssl (issue 4), direct to auth      #
# 20190220: Added status check type                                            #
# 20190403: Check for mandatory parameter checktype, adjust help               #
# 20190403: Catch connection refused error                                     #
# 20190426: Catch unauthorized (403) error                                     #
# 20190626: Added readonly check type                                          #
# 20190905: Catch empty cluster health status (issue #13)                      #
# 20190909: Added jthreads and tps (thread pool stats) check types             #
# 20190909: Handle correct curl return codes                                   #
# 20190924: Missing 'than' in tps output                                       #
# 20191104: Added master check type                                            #
# 20200401: Fix/handle 503 errors with curl exit code 0 (issue #20)            #
# 20200409: Fix 503 error lookup (issue #22)                                   #
# 20200430: Support both jshon and jq as json parsers (issue #18)              #
# 20200609: Fix readonly check on ALL indices (issue #26)                      #
# 20200723: Add cluster name to status output                                  #
# 20200824: Fix typo in readonly check output                                  #
# 20200916: Internal renaming of -i parameter, use for tps check (issue #28)   #
# 20201110: Fix thresholds in jthreads check                                   #
# 20201125: Show names of read_only indexes with jq, set jq as default parser  #
# 20210616: Fix authentication bug (#38) and non ES URL responding (#39)       #
# 20211202: Added local node (-L), SSL settings (-K, -E), cpu check            #
################################################################################
#Variables and defaults
STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin # Set path
version=1.12.0
port=9200
httpscheme=http
unit=G
include='_all'
max_time=30
parsers=(jq jshon)
################################################################################
#Functions
help () {
echo -e "$0 $version (c) 2016-$(date +%Y) Claudio Kuenzler and contributors (open source rulez!)

Usage: ./check_es_system.sh -H ESNode [-P port] [-S] [-u user -p pass|-E cert -K key] -t checktype [-o unit] [-w int] [-c int] [-m int] [-e string] [-X parser]

Options:

   *  -H Hostname or ip address of ElasticSearch Node
      -L Run check on local node instead of cluster
      -P Port (defaults to 9200)
      -S Use https
      -E Certs for Authentication
      -K Key for Authentication
      -u Username if authentication is required
      -p Password if authentication is required
   *  -t Type of check (disk, mem, cpu, status, readonly, jthreads, tps, master)
      -o Disk space unit (K|M|G) (defaults to G)
      -i Space separated list of included object names to be checked (index names on readonly check, pool names on tps check)
      -w Warning threshold (see usage notes below)
      -c Critical threshold (see usage notes below)
      -m Maximum time in seconds to wait for response (default: 30)
      -e Expect master node (used with 'master' check)
      -X The json parser to be used jshon or jq (default: jq)
      -h Help!

*mandatory options

Threshold format for 'disk', 'mem' and 'cpu': int (for percent), defaults to 80 (warn) and 95 (crit)
Threshold format for 'tps': int,int,int (active, queued, rejected), no defaults
Threshold format for all other check types': int, no defaults

Requirements: curl, expr and one of $(IFS=,; echo "${parsers[*]}")"
exit $STATE_UNKNOWN;
}

authlogic () {
if [[ -z $user ]] && [[ -z $pass ]]; then echo "ES SYSTEM UNKNOWN - Authentication required but missing username and password"; exit $STATE_UNKNOWN
elif [[ -n $user ]] && [[ -z $pass ]]; then echo "ES SYSTEM UNKNOWN - Authentication required but missing password"; exit $STATE_UNKNOWN
elif [[ -n $pass ]] && [[ -z $user ]]; then echo "ES SYSTEM UNKNOWN - Missing username"; exit $STATE_UNKNOWN
fi
}

authlogic_cert () {
if [[ -z $cert ]] && [[ -z $key ]]; then echo "ES SYSTEM UNKNOWN - Authentication required but missing cert and key"; exit $STATE_UNKNOWN
elif [[ -n $cert ]] && [[ -z $key ]]; then echo "ES SYSTEM UNKNOWN - Authentication required but missing key"; exit $STATE_UNKNOWN
elif [[ -n $key ]] && [[ -z $cert ]]; then echo "ES SYSTEM UNKNOWN - Missing cert"; exit $STATE_UNKNOWN
fi
}

unitcalc() {
# ES presents the currently used disk space in Bytes
if [[ -n $unit ]]; then
  case $unit in
    K) availsize=$(expr $available / 1024); outputsize=$(expr ${size} / 1024);;
    M) availsize=$(expr $available / 1024 / 1024); outputsize=$(expr ${size} / 1024 / 1024);;
    G) availsize=$(expr $available / 1024 / 1024 / 1024); outputsize=$(expr ${size} / 1024 / 1024 / 1024);;
  esac
  if [[ -n $warning ]] ; then
    warningsize=$(expr $warning \* ${available} / 100)
  fi
  if [[ -n $critical ]] ; then
    criticalsize=$(expr $critical \* ${available} / 100)
  fi
  usedpercent=$(expr $size \* 100 / $available)
else echo "UNKNOWN - Shouldnt exit here. No units given"; exit $STATE_UNKNOWN
fi
}

thresholdlogic () {
if [ -n $warning ] && [ -z $critical ]; then echo "UNKNOWN - Define both warning and critical thresholds"; exit $STATE_UNKNOWN; fi
if [ -n $critical ] && [ -z $warning ]; then echo "UNKNOWN - Define both warning and critical thresholds"; exit $STATE_UNKNOWN; fi
}

default_percentage_thresholds() {
if [ -z $warning ] || [ "${warning}" = "" ]; then warning=80; fi
if [ -z $critical ] || [ "${critical}" = "" ]; then critical=95; fi
}

json_parse() {
  json_parse_usage() { echo "$0: [-r] [-q] [-c] [-a] -x arg1 -x arg2 ..." 1>&2; exit; }

  local OPTIND opt r q c a x
  while getopts ":rqcax:" opt
  do
    case "${opt}" in
    r)  raw=1;;
    q)  quiet=1;; # only required for jshon
    c)  continue=1;; # only required for jshon
    a)  across=1;;
    x)  args+=("$OPTARG");;
    *)  json_parse_usage;;
    esac
  done

  case ${parser} in
  jshon)
    cmd=()
    for arg in "${args[@]}"; do
      cmd+=(-e $arg)
    done
    jshon ${quiet:+-Q} ${continue:+-C} ${across:+-a} "${cmd[@]}" ${raw:+-u}
    ;;
  jq)
    cmd=()
    for arg in "${args[@]}"; do
      cmd+=(.$arg)
    done
    jq ${raw:+-r} $(IFS=; echo ${across:+.[]}"${cmd[*]}")
    ;;
  esac
}

################################################################################
# Check for people who need help - aren't we all nice ;-)
if [ "${1}" = "--help" -o "${#}" = "0" ]; then help; exit $STATE_UNKNOWN; fi
################################################################################
# Get user-given variables
while getopts "H:LP:SE:K:u:p:d:o:i:w:c:t:m:e:X:" Input
do
  case ${Input} in
  H)      host=${OPTARG};;
  L)      local=true;;
  P)      port=${OPTARG};;
  S)      httpscheme=https;;
  E)      cert=${OPTARG};;
  K)      key=${OPTARG};;
  u)      user=${OPTARG};;
  p)      pass=${OPTARG};;
  d)      oldavailable=${OPTARG};;
  o)      unit=${OPTARG};;
  i)      include=${OPTARG};;
  w)      warning=${OPTARG};;
  c)      critical=${OPTARG};;
  t)      checktype=${OPTARG};;
  m)      max_time=${OPTARG};;
  e)      expect_master=${OPTARG};;
  X)      parser=${OPTARG:=jq};;
  *)      help;;
  esac
done

# Check for mandatory opts
if [[ -z ${host} ]]; then help; exit $STATE_UNKNOWN; fi
if [[ -z ${checktype} ]]; then help; exit $STATE_UNKNOWN; fi

# Check for deprecated opts
if [[ -n ${oldavailable} ]]; then
  echo "ES SYSTEM UNKNOWN: -d parameter is now invalid. Capacities are now discovered directly from Elasticsearch."
  exit ${STATE_UNKNOWN}
fi

# Local checks are only useful for certain check types
if [[ -n ${local} ]] && ( ! [[ ${checktype} =~ ^(cpu|mem|disk|jthreads)$ ]] ); then
  echo "ES SYSTEM UNKNOWN: Node local checks (-L) only work with the following check types: cpu, mem, disk, jthreads"
  exit ${STATE_UNKNOWN}
fi
################################################################################
# Check requirements
for cmd in curl expr ${parser}; do
  if ! `which ${cmd} >/dev/null 2>&1`; then
    echo "UNKNOWN: ${cmd} does not exist, please check if command exists and PATH is correct"
    exit ${STATE_UNKNOWN}
  fi
done
# Find parser
if [ -z ${parser} ]; then
  for cmd in ${parsers[@]}; do
    if `which ${cmd} >/dev/null 2>&1`; then
      parser=${cmd}
      break
    fi
  done
  if [ -z "${parser}" ]; then
    echo "UNKNOWN: No JSON parser found. Either one of the following is required: $(IFS=,; echo "${parsers[*]}")"
    exit ${STATE_UNKNOWN}
  fi
fi

################################################################################
# Retrieve information from Elasticsearch cluster
getstatus() {
if [[ ${local} ]]; then
  esurl="${httpscheme}://${host}:${port}/_nodes/_local/stats"
else
  esurl="${httpscheme}://${host}:${port}/_cluster/stats"
fi
eshealthurl="${httpscheme}://${host}:${port}/_cluster/health"

if [[ -z $user ]] && [[ -z $cert ]]; then
  # Without authentication
  esstatus=$(curl -k -s --max-time ${max_time} $esurl)
  esstatusrc=$?
  if [[ $esstatusrc -eq 7 ]]; then
    echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
    exit $STATE_CRITICAL
  elif [[ $esstatusrc -eq 28 ]]; then
    echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
    exit $STATE_CRITICAL
  elif [[ "$esstatus" =~ "503 Service Unavailable" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available: ${host}:${port} return error 503"
    exit $STATE_CRITICAL
  elif [[ "$esstatus" =~ "Unknown resource" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available: ${esstatus}"
    exit $STATE_CRITICAL
  elif ! [[ "$esstatus" =~ "cluster_name" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available at this address ${host}:${port}"
    exit $STATE_CRITICAL
  fi
  # Additionally get cluster health infos
  if [ $checktype = status ]; then
    eshealth=$(curl -k -s --max-time ${max_time} $eshealthurl)
    if [[ -z $eshealth ]]; then
      echo "ES SYSTEM CRITICAL - unable to get cluster health information"
      exit $STATE_CRITICAL
    fi
  fi
fi

if [[ -n $user ]] || [[ -n $(echo $esstatus | grep -i authentication) ]] ; then
  # Authentication required
  authlogic
  esstatus=$(curl -k -s --max-time ${max_time} --basic -u ${user}:${pass} $esurl)
  esstatusrc=$?
  if [[ $esstatusrc -eq 7 ]]; then
    echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
    exit $STATE_CRITICAL
  elif [[ $esstatusrc -eq 28 ]]; then
    echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
    exit $STATE_CRITICAL
  elif [[ "$esstatus" =~ "503 Service Unavailable" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available: ${host}:${port} return error 503"
    exit $STATE_CRITICAL
  elif [[ "$esstatus" =~ "Unknown resource" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available: ${esstatus}"
    exit $STATE_CRITICAL
  elif [[ -n $(echo "$esstatus" | grep -i "unable to authenticate") ]]; then
    echo "ES SYSTEM CRITICAL - Unable to authenticate user $user for REST request"
    exit $STATE_CRITICAL
  elif [[ -n $(echo "$esstatus" | grep -i "unauthorized") ]]; then
    echo "ES SYSTEM CRITICAL - User $user is unauthorized"
    exit $STATE_CRITICAL
  elif ! [[ "$esstatus" =~ "cluster_name" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available at this address ${host}:${port}"
    exit $STATE_CRITICAL
  fi
  # Additionally get cluster health infos
  if [[ $checktype = status ]]; then
    eshealth=$(curl -k -s --max-time ${max_time} --basic -u ${user}:${pass} $eshealthurl)
    if [[ -z $eshealth ]]; then
      echo "ES SYSTEM CRITICAL - unable to get cluster health information"
      exit $STATE_CRITICAL
    fi
  fi
fi

if [[ -n $cert ]] || [[ -n $(echo $esstatus | grep -i authentication) ]] ; then
  # Authentication with certificate
  authlogic_cert
  esstatus=$(curl -k -s --max-time ${max_time} -E ${cert} --key ${key} $esurl)
  esstatusrc=$?
  if [[ $esstatusrc -eq 7 ]]; then
    echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
    exit $STATE_CRITICAL
  elif [[ $esstatusrc -eq 28 ]]; then
    echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
    exit $STATE_CRITICAL
  elif [[ "$esstatus" =~ "503 Service Unavailable" ]]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch not available: ${host}:${port} return error 503"
    exit $STATE_CRITICAL
  elif [[ -n $(echo "$esstatus" | grep -i "unable to authenticate") ]]; then
    echo "ES SYSTEM CRITICAL - Unable to authenticate user $user for REST request"
    exit $STATE_CRITICAL
  elif [[ -n $(echo "$esstatus" | grep -i "unauthorized") ]]; then
    echo "ES SYSTEM CRITICAL - User $user is unauthorized"
    exit $STATE_CRITICAL
  fi
  # Additionally get cluster health infos
  if [[ $checktype = status ]]; then
    eshealth=$(curl -k -s --max-time ${max_time} -E ${cert} --key ${key} $eshealthurl)
    if [[ -z $eshealth ]]; then
      echo "ES SYSTEM CRITICAL - unable to get cluster health information"
      exit $STATE_CRITICAL
    fi
  fi
fi

# Catch empty reply from server (typically happens when ssl port used with http connection)
if [[ -z $esstatus ]] || [[ $esstatus = '' ]]; then
  echo "ES SYSTEM UNKNOWN - Empty reply from server (verify ssl settings)"
  exit $STATE_UNKNOWN
fi
}
################################################################################
# Do the checks
case $checktype in
disk) # Check disk usage
  getstatus
  default_percentage_thresholds
  if [[ ${local} ]]; then
    size=$(echo $esstatus | json_parse -x 'nodes|' -x '[]' -x indices -x store -x size_in_bytes)
    available=$(echo $esstatus | json_parse -x 'nodes|' -x '[]' -x fs -x total -x total_in_bytes)
  else
    size=$(echo $esstatus | json_parse -x indices -x store -x size_in_bytes)
    available=$(echo $esstatus | json_parse -x nodes -x fs -x total_in_bytes)
  fi

  unitcalc
  if [ -n "${warning}" ] || [ -n "${critical}" ]; then
    # Handle tresholds
    thresholdlogic
    if [ $size -ge $criticalsize ]; then
      echo "ES SYSTEM CRITICAL - Disk usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_disk=${size}B;${warningsize};${criticalsize};0;${available}"
      exit $STATE_CRITICAL
    elif [ $size -ge $warningsize ]; then
      echo "ES SYSTEM WARNING - Disk usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_disk=${size}B;${warningsize};${criticalsize};0;${available}"
      exit $STATE_WARNING
    else
      echo "ES SYSTEM OK - Disk usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_disk=${size}B;${warningsize};${criticalsize};0;${available}"
      exit $STATE_OK
    fi
  else
    # No thresholds
    echo "ES SYSTEM OK - Disk usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_disk=${size}B;;;0;${available}"
    exit $STATE_OK
  fi
  ;;

mem) # Check memory usage
  getstatus
  default_percentage_thresholds
  if [[ ${local} ]]; then
    size=$(echo $esstatus | json_parse -x 'nodes|' -x '[]' -x jvm -x mem -x heap_used_in_bytes)
    available=$(echo $esstatus | json_parse -x 'nodes|' -x '[]' -x jvm -x mem -x heap_max_in_bytes)
  else
    size=$(echo $esstatus | json_parse -x nodes -x jvm -x mem -x heap_used_in_bytes)
    available=$(echo $esstatus | json_parse -x nodes -x jvm -x mem -x heap_max_in_bytes)
  fi

  unitcalc
  if [ -n "${warning}" ] || [ -n "${critical}" ]; then
    # Handle tresholds
    thresholdlogic
    if [ $size -ge $criticalsize ]; then
      echo "ES SYSTEM CRITICAL - Memory usage is at ${usedpercent}% ($outputsize $unit) from $availsize $unit|es_memory=${size}B;${warningsize};${criticalsize};0;${available}"
      exit $STATE_CRITICAL
    elif [ $size -ge $warningsize ]; then
      echo "ES SYSTEM WARNING - Memory usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_memory=${size}B;${warningsize};${criticalsize};0;${available}"
      exit $STATE_WARNING
    else
      echo "ES SYSTEM OK - Memory usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_memory=${size}B;${warningsize};${criticalsize};0;${available}"
      exit $STATE_OK
    fi
  else
    # No thresholds
    echo "ES SYSTEM OK - Memory usage is at ${usedpercent}% ($outputsize $unit from $availsize $unit)|es_memory=${size}B;;;0;${available}"
    exit $STATE_OK
  fi
  ;;

cpu) # Check memory usage
  getstatus
  default_percentage_thresholds
  if [[ ${local} ]]; then
    value=$(echo $esstatus | json_parse -x 'nodes|' -x '[]' -x process -x cpu -x percent)
  else
    value=$(echo $esstatus | json_parse -x nodes -x process -x cpu -x percent)
  fi

  if [ -n "${warning}" ] || [ -n "${critical}" ]; then
    # Handle tresholds
    thresholdlogic
    if [ $value -ge $critical ]; then
      echo "ES SYSTEM CRITICAL - CPU usage is at ${value}% |es_cpu=${value}%;${warning};${critical};0;100"
      exit $STATE_CRITICAL
    elif [ $value -ge $warning ]; then
      echo "ES SYSTEM WARNING - CPU usage is at ${value}% |es_cpu=${value}%;${warning};${critical};0;100"
      exit $STATE_WARNING
    else
      echo "ES SYSTEM OK - CPU usage is at ${value}% |es_cpu=${value}%;${warning};${critical};0;100"
      exit $STATE_OK
    fi
  else
    # No thresholds
    echo "ES SYSTEM OK - CPU usage is at ${value}% |es_cpu=${value}%;${warning};${critical};0;100"
    exit $STATE_OK
  fi
  ;;

status) # Check Elasticsearch status
  getstatus
  status=$(echo $esstatus | json_parse -r -x status)
  clustername=$(echo $esstatus | json_parse -r -x cluster_name)
  shards=$(echo $esstatus | json_parse -r -x indices -x shards -x total)
  docs=$(echo $esstatus | json_parse -r -x indices -x docs -x count)
  nodest=$(echo $esstatus | json_parse -r -x nodes -x count -x total)
  nodesd=$(echo $esstatus | json_parse -r -x nodes -x count -x data)
  relocating=$(echo $eshealth | json_parse -r -x relocating_shards)
  init=$(echo $eshealth | json_parse -r -x initializing_shards)
  unass=$(echo $eshealth | json_parse -r -x unassigned_shards)
  if [ "$status" = "green" ]; then
    echo "ES SYSTEM OK - Elasticsearch Cluster \"$clustername\" is green (${nodest} nodes, ${nodesd} data nodes, ${shards} shards, ${docs} docs)|total_nodes=${nodest};;;; data_nodes=${nodesd};;;; total_shards=${shards};;;; relocating_shards=${relocating};;;; initializing_shards=${init};;;; unassigned_shards=${unass};;;; docs=${docs};;;;"
    exit $STATE_OK
  elif [ "$status" = "yellow" ]; then
    echo "ES SYSTEM WARNING - Elasticsearch Cluster \"$clustername\" is yellow (${nodest} nodes, ${nodesd} data nodes, ${shards} shards, ${relocating} relocating shards, ${init} initializing shards, ${unass} unassigned shards, ${docs} docs)|total_nodes=${nodest};;;; data_nodes=${nodesd};;;; total_shards=${shards};;;; relocating_shards=${relocating};;;; initializing_shards=${init};;;; unassigned_shards=${unass};;;; docs=${docs};;;;"
      exit $STATE_WARNING
  elif [ "$status" = "red" ]; then
    echo "ES SYSTEM CRITICAL - Elasticsearch Cluster \"$clustername\" is red (${nodest} nodes, ${nodesd} data nodes, ${shards} shards, ${relocating} relocating shards, ${init} initializing shards, ${unass} unassigned shards, ${docs} docs)|total_nodes=${nodest};;;; data_nodes=${nodesd};;;; total_shards=${shards};;;; relocating_shards=${relocating};;;; initializing_shards=${init};;;; unassigned_shards=${unass};;;; docs=${docs};;;;"
      exit $STATE_CRITICAL
  fi
  ;;

readonly) # Check Readonly status on given indexes
  getstatus
  icount=0
  for index in $include; do
    if [[ -z $user ]]; then
      # Without authentication
      settings=$(curl -k -s --max-time ${max_time} ${httpscheme}://${host}:${port}/$index/_settings)
      if [[ $? -eq 7 ]]; then
        echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
        exit $STATE_CRITICAL
      elif [[ $? -eq 28 ]]; then
        echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
        exit $STATE_CRITICAL
      fi
      rocount=$(echo $settings | json_parse -r -q -c -a -x settings -x index -x blocks -x read_only | grep -c true)
      roadcount=$(echo $settings | json_parse -r -q -c -a -x settings -x index -x blocks -x read_only_allow_delete | grep -c true)
      if [[ $rocount -gt 0 ]]; then
        output[${icount}]=" $index is read-only -"
        roerror=true
      fi
      if [[ $roadcount -gt 0 ]]; then
        output[${icount}]+=" $index is read-only (allow delete) -"
        roerror=true
      fi
    fi

    if [[ -n $user ]] || [[ -n $(echo $esstatus | grep -i authentication) ]] ; then
      # Authentication required
      authlogic
      settings=$(curl -k -s --max-time ${max_time} --basic -u ${user}:${pass} ${httpscheme}://${host}:${port}/$index/_settings)
      settingsrc=$?
      if [[ $settingsrc -eq 7 ]]; then
        echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
        exit $STATE_CRITICAL
      elif [[ $settingsrc -eq 28 ]]; then
        echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
        exit $STATE_CRITICAL
      elif [[ -n $(echo $esstatus | grep -i "unable to authenticate") ]]; then
        echo "ES SYSTEM CRITICAL - Unable to authenticate user $user for REST request"
        exit $STATE_CRITICAL
      elif [[ -n $(echo $esstatus | grep -i "unauthorized") ]]; then
        echo "ES SYSTEM CRITICAL - User $user is unauthorized"
        exit $STATE_CRITICAL
      fi
      rocount=$(echo $settings | json_parse -r -q -c -a -x settings -x index -x blocks -x read_only | grep -c true)
      roadcount=$(echo $settings | json_parse -r -q -c -a -x settings -x index -x blocks -x read_only_allow_delete | grep -c true)
      if [[ $rocount -gt 0 ]]; then
        if [[ "$index" = "_all" ]]; then
          if [[ $parser = "jq" ]]; then
            roindexes=$(echo $settings | jq -r '.[].settings.index |select(.blocks.read_only == "true").provided_name')
          fi
          output[${icount}]=" $rocount index(es) found read-only $roindexes -"
        else output[${icount}]=" $index is read-only -"
        fi
        roerror=true
      fi
      if [[ $roadcount -gt 0 ]]; then
        if [[ "$index" = "_all" ]]; then
          if [[ $parser = "jq" ]]; then
            roadindexes=$(echo $settings | jq -r '.[].settings.index |select(.blocks.read_only_allow_delete == "true").provided_name' | tr '\n' ' ')
          fi
          output[${icount}]+=" $roadcount index(es) found read-only (allow delete) $roadindexes"
        else output[${icount}]+=" $index is read-only (allow delete) -"
        fi
        roerror=true
      fi
    fi
    let icount++
  done

  if [[ $roerror ]]; then
    echo "ES SYSTEM CRITICAL - ${output[*]}"
    exit $STATE_CRITICAL
  else
    echo "ES SYSTEM OK - Elasticsearch Indexes ($include) are writeable"
    exit $STATE_OK
  fi
  ;;

jthreads) # Check JVM threads
  getstatus
  if [[ ${local} ]]; then
    threads=$(echo $esstatus | json_parse -x 'nodes|' -x '[]' -x jvm -x threads -x count)
  else
    threads=$(echo $esstatus | json_parse -r -x nodes -x jvm -x "threads")
  fi

  if [ -n "${warning}" ] || [ -n "${critical}" ]; then
    # Handle tresholds
    thresholdlogic
    if [[ $threads -ge $critical ]]; then
      echo "ES SYSTEM CRITICAL - Number of JVM threads is ${threads}|es_jvm_threads=${threads};${warning};${critical};;"
      exit $STATE_CRITICAL
    elif [[ $threads -ge $warning ]]; then
      echo "ES SYSTEM WARNING - Number of JVM threads is ${threads}|es_jvm_threads=${threads};${warning};${critical};;"
      exit $STATE_WARNING
    else
      echo "ES SYSTEM OK - Number of JVM threads is ${threads}|es_jvm_threads=${threads};${warning};${critical};;"
      exit $STATE_OK
    fi
  else
    # No thresholds
    echo "ES SYSTEM OK - Number of JVM threads is ${threads}|es_jvm_threads=${threads};${warning};${critical};;"
    exit $STATE_OK
  fi
  ;;

tps) # Check Thread Pool Statistics
  getstatus
  if [[ -z $user ]]; then
    # Without authentication
    threadpools=$(curl -k -s --max-time ${max_time} ${httpscheme}://${host}:${port}/_cat/thread_pool)
    threadpoolrc=$?
    if [[ $threadpoolrc -eq 7 ]]; then
      echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
      exit $STATE_CRITICAL
    elif [[ $threadpoolrc -eq 28 ]]; then
      echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
      exit $STATE_CRITICAL
    fi
  fi

  if [[ -n $user ]] || [[ -n $(echo $esstatus | grep -i authentication) ]] ; then
    # Authentication required
    authlogic
    threadpools=$(curl -k -s --max-time ${max_time} --basic -u ${user}:${pass} ${httpscheme}://${host}:${port}/_cat/thread_pool)
    threadpoolrc=$?
    if [[ $threadpoolrc -eq 7 ]]; then
      echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
      exit $STATE_CRITICAL
    elif [[ $threadpoolrc -eq 28 ]]; then
      echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
      exit $STATE_CRITICAL
    elif [[ -n $(echo $esstatus | grep -i "unable to authenticate") ]]; then
      echo "ES SYSTEM CRITICAL - Unable to authenticate user $user for REST request"
      exit $STATE_CRITICAL
    elif [[ -n $(echo $esstatus | grep -i "unauthorized") ]]; then
      echo "ES SYSTEM CRITICAL - User $user is unauthorized"
      exit $STATE_CRITICAL
    fi
  fi

  if ! [[ $include = "_all"  ]]; then
    tpsgrep=$(echo "$include" | sed "s/ /|/g")
    threadpools=$(echo "$threadpools" | egrep -i "(${tpsgrep})")
    if [[ $(echo ${threadpools[*]}) = "" ]]; then
      echo "Thread Pool check is critical: No thread pools found with given name(s): ${include}."
      exit $STATE_CRITICAL
    fi
  fi

  tpname=($(echo "$threadpools" | awk '{print $1"-"$2}' | sed "s/\n//g"))
  tpactive=($(echo "$threadpools" | awk '{print $3}' | sed "s/\n//g"))
  tpqueue=($(echo "$threadpools" | awk '{print $4}' | sed "s/\n//g"))
  tprejected=($(echo "$threadpools" | awk '{print $5}' | sed "s/\n//g"))

  if [ -n "${warning}" ] || [ -n "${critical}" ]; then
    # Handle thresholds. They have to come in a special format: n,n,n (active, queue, rejected)
    thresholdlogic
    wactive=$(echo ${warning} | awk -F',' '{print $1}')
    wqueue=$(echo ${warning} | awk -F',' '{print $2}')
    wrejected=$(echo ${warning} | awk -F',' '{print $3}')
    cactive=$(echo ${critical} | awk -F',' '{print $1}')
    cqueue=$(echo ${critical} | awk -F',' '{print $2}')
    crejected=$(echo ${critical} | awk -F',' '{print $3}')

    i=0; for tp in ${tpname[*]}; do
      perfdata[$i]="tp_${tp}_active=${tpactive[$i]};${wactive};${cactive};; tp_${tp}_queue=${tpqueue[$i]};${wqueue};${cqueue};; tp_${tp}_rejected=${tprejected[$i]};${wrejected};${crejected};; "
      let i++
    done

    i=0
    for tpa in $(echo ${tpactive[*]}); do
      if [[ $tpa -ge $cactive ]]; then
        echo "Thread Pool ${tpname[$i]} is critical: Active ($tpa) is equal or higher than threshold ($cactive)|${perfdata[*]}"
        exit $STATE_CRITICAL
      elif [[ $tpa -ge $wactive ]]; then
        echo "Thread Pool ${tpname[$i]} is warning: Active ($tpa) is equal or higher than threshold ($wactive)|${perfdata[*]}"
        exit $STATE_WARNING
      fi
      let i++
    done

    i=0
    for tpq in $(echo ${tpqueue[*]}); do
      if [[ $tpq -ge $cqueue ]]; then
        echo "Thread Pool ${tpname[$i]} is critical: Queue ($tpq) is equal or higher than threshold ($cqueue)|${perfdata[*]}"
        exit $STATE_CRITICAL
      elif [[ $tpq -ge $wqueue ]]; then
        echo "Thread Pool ${tpname[$i]} is warning: Queue ($tpq) is equal or higher than threshold ($wqueue)|${perfdata[*]}"
        exit $STATE_WARNING
      fi
      let i++
    done

    i=0
    for tpr in $(echo ${tprejected[*]}); do
      if [[ $tpr -ge $crejected ]]; then
        echo "Thread Pool ${tpname[$i]} is critical: Rejected ($tpr) is equal or higher than threshold ($crejected)|${perfdata[*]}"
        exit $STATE_CRITICAL
      elif [[ $tpr -ge $wrejected ]]; then
        echo "Thread Pool ${tpname[$i]} is warning: Rejected ($tpr) is equal or higher than threshold ($wrejected)|${perfdata[*]}"
        exit $STATE_WARNING
      fi
      let i++
    done

   echo "ES SYSTEM OK - Found ${#tpname[*]} thread pools in cluster|${perfdata[*]}"
   exit $STATE_OK
   fi

  # No Thresholds
  i=0; for tp in ${tpname[*]}; do
    perfdata[$i]="tp_${tp}_active=${tpactive[$i]};;;; tp_${tp}_queue=${tpqueue[$i]};;;; tp_${tp}_rejected=${tprejected[$i]};;;; "
    let i++
  done
  echo "ES SYSTEM OK - Found ${#tpname[*]} thread pools in cluster|${perfdata[*]}"
  exit $STATE_OK
  ;;

master) # Check Cluster Master
  getstatus
  if [[ -z $user ]]; then
    # Without authentication
    master=$(curl -k -s --max-time ${max_time} ${httpscheme}://${host}:${port}/_cat/master)
    masterrc=$?
    if [[ $masterrc -eq 7 ]]; then
      echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
      exit $STATE_CRITICAL
    elif [[ $masterrc -eq 28 ]]; then
      echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
      exit $STATE_CRITICAL
    fi
  fi

  if [[ -n $user ]] || [[ -n $(echo $esstatus | grep -i authentication) ]] ; then
    # Authentication required
    authlogic
    master=$(curl -k -s --max-time ${max_time} --basic -u ${user}:${pass} ${httpscheme}://${host}:${port}/_cat/master)
    masterrc=$?
    if [[ $threadpoolrc -eq 7 ]]; then
      echo "ES SYSTEM CRITICAL - Failed to connect to ${host} port ${port}: Connection refused"
      exit $STATE_CRITICAL
    elif [[ $threadpoolrc -eq 28 ]]; then
      echo "ES SYSTEM CRITICAL - server did not respond within ${max_time} seconds"
      exit $STATE_CRITICAL
    elif [[ -n $(echo $esstatus | grep -i "unable to authenticate") ]]; then
      echo "ES SYSTEM CRITICAL - Unable to authenticate user $user for REST request"
      exit $STATE_CRITICAL
    elif [[ -n $(echo $esstatus | grep -i "unauthorized") ]]; then
      echo "ES SYSTEM CRITICAL - User $user is unauthorized"
      exit $STATE_CRITICAL
    fi
  fi

  masternode=$(echo "$master" | awk '{print $NF}')

  if [[ -n ${expect_master} ]]; then
    if [[ "${expect_master}" = "${masternode}" ]]; then
      echo "ES SYSTEM OK - Master node is $masternode"
      exit $STATE_OK
    else
      echo "ES SYSTEM WARNING - Master node is $masternode but expected ${expect_master}"
      exit $STATE_WARNING
    fi
  else
    echo "ES SYSTEM OK - Master node is $masternode"
    exit $STATE_OK
  fi
  ;;

*) help
esac
