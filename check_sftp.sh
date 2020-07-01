#!/bin/bash

# honza@inuits.eu
# yenda@inuits.eu

host=''
user=''
password=''
timeout=10
port=22

usage(){
cat <<EOF
usage: $0 <options>
  -h host
  -u user
  -p password
  -P port (defaults to 22)
  -t timeout (defaults to 10 seconds)
EOF
exit 3
}

while getopts 'u:p:h:P:t:' OPTION
do
  case $OPTION in

    u) user=$OPTARG;;
    p) password=$OPTARG;;
    h) host=$OPTARG;;
    P) port=$OPTARG;;
    t) timeout=$OPTARG;;
    *) usage;;
  esac
done

if [[ -z $user ]] || [[ -z $password ]] || [[ -z $host ]]; then
  usage
fi

which lftp &>/dev/null || { echo 'You need to have lftp installed.'; exit 3; }

# 'set net:max-retries 1' - 0 set unlimited, 1 - no retries
# 'set net:timeout ${timeout}' - sets the network protocol timeout.
# 'set net:reconnect-interval-base 5' - sets  the  base minimal time between reconnects

OUT=$(lftp -u "${user},${password}" sftp://$host:$port -e "set net:timeout ${timeout};set net:max-retries 1;set net:reconnect-interval-base 5;ls;bye" 2>&1)

if [[ $? -ne 0 ]]; then
  echo "Unable to connect to connect to ${host}"
  echo $OUT
  exit 2
else
  echo "Successfully connected to ${host}"
  exit 0
fi
