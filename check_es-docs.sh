#!/bin/bash

#honza@inuits.eu 2019

#Checks the number of documents created within the last n seconds.


es_host=localhost:9200
indexes='logstash-*'
timestamp_field='@timestamp'
docs_warning=4000
docs_critical=1000
seconds=120
result=''
user=''
password=''

usage(){
cat <<EOF
usage: $0 <options>

  -h ES host
  -u user
  -p password
  -i indexes
  -w docs_warning
  -c docs_critical
  -s seconds
EOF
exit 0
}

while getopts 'h:u:p:i:w:c:s:' OPTION
do
  case $OPTION in

    u) user=$OPTARG;;
    p) password=$OPTARG;;
    h) es_host=$OPTARG;;
    h) indexes=$OPTARG;;
    w) docs_warning=$OPTARG;;
    c) docs_critical=$OPTARG;;
    s) seconds=$OPTARG;;
    *) usage;;
  esac
done

result=$(curl  -k -s -u ${user}:${password} -X GET "${es_host}/${indexes}/_count?pretty" -H 'Content-Type: application/json' -d"
{
    \"query\": {
        \"range\" : {
            \"${timestamp_field}\" : {
                \"gte\" : \"now-${seconds}s/s\",
                \"lt\" :  \"now/s\"
            }
        }
    }
}
" 2>/dev/null | jq .count 2>/dev/null | egrep '^[0-9]+$')

if [[ -z $result ]]; then
  status=3
  message="Unknown: unable to get the number of documents from within the last ${seconds} seconds."
elif [[ $result -le $docs_critical ]]; then
  status=2
  message="Critical: ${result} documents were found from within the last ${seconds} seconds."
elif [[ $result -le $docs_warning ]]; then
  status=1
  message="Warning: ${result} documents were found from within the last ${seconds} seconds."
else
  message="OK: ${result} documents were found from within the last ${seconds} seconds."
  status=0
fi

echo "$message"
exit $status
