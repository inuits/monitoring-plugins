#!/bin/bash

#honza@inuits.eu

token=''
sentry_url=''
days_ago=1
exit_code=0
extra_config_file=/dev/null
output=''
critical=''
warning=''

usage(){
cat <<EOF
usage: $0 <options>
  -u sentry url
  -t api token
  -d number of the past days to search for events from 
  -w warning number of events 
  -c critical number of events
  -f extra config file

Extra config file allows to set specific thresholds for individual projects. If no thresholds are set for a project, the defaults set with '-w' and '-c' will be used.
The file should look as follows:
<project name>;<warning threshold>;<critical threshold>

one project per line
EOF
exit 3
}

while getopts 'u:t:d:c:w:f:' OPTION
do
  case $OPTION in

    u) sentry_url=$OPTARG;;
    t) token=$OPTARG;;
    d) days_ago=$OPTARG;;
    c) critical=$OPTARG;;
    w) warning=$OPTARG;;
    f) extra_config_file=$OPTARG;;
    *) usage;;
  esac
done

if [[ -z $sentry_url ]] || [[ -z $token ]] || [[ -z $critical ]] || [[ -z $warning ]]; then
  usage
fi


timestamp=$(date +%s --date=" ${days_ago} days ago")
projects=$(curl --silent -H "Authorization: Bearer ${token}" ${sentry_url}/api/0/projects/ | jq .[].name -r)

for project in $projects; do
  _warning=''
  _critical=''
  slug=''
  #check whether the project has moved to a new url
  url=$(curl --silent -H "Authorization: Bearer ${token}" "${sentry_url}/api/0/projects/inuits/${project}/stats/?&since=${timestamp}" | jq -r .detail.extra.url 2>/dev/null)
  if [[ -z $url ]]; then
    events=$(curl --silent -H "Authorization: Bearer ${token}" "${sentry_url}/api/0/projects/inuits/${project}/stats/?&since=${timestamp}" | jq .[][1] | awk '{s+=$1} END {print s}')
  else
    events=$(curl --silent -H "Authorization: Bearer ${token}" "${sentry_url}${url}" | jq .[][1] | awk '{s+=$1} END {print s}')
    slug=$(curl --silent -H "Authorization: Bearer ${token}" "${sentry_url}/api/0/projects/inuits/${project}/stats/" | jq -r .slug 2>/dev/null)
  fi
  if [[ -z $slug ]]; then
    output="${output}$project: $events; "
    slug=$project
  else
    output="${output}$slug: $events; "
  fi
  if egrep -q "^${slug};[0-9]+;[0-9]+$" $extra_config_file; then
    _warning=$(cat $extra_config_file | egrep "^${slug};[0-9]+;[0-9]+$" | cut -f2 -d ';')
    _critical=$(cat $extra_config_file | egrep "^${slug};[0-9]+;[0-9]+$" | cut -f3 -d ';')
    if [[ $events -ge $_critical ]]; then
      exit_code=2
    elif [[ $events -ge $_warning ]]; then
      [[ $exit_code -lt 1 ]] && exit_code=1
    fi
  else
    if [[ $events -ge $critical ]]; then
      exit_code=2
    elif [[ $events -ge $warning ]]; then
      [[ $exit_code -lt 1 ]] && exit_code=1
    fi
  fi
done
echo "${output}for the past ${days_ago} days"
exit $exit_code
