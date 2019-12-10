#!/bin/bash

#honza@inuits.eu

host=''
user=''
password=''
timeout=4
port=22

usage(){
cat <<EOF
usage: $0 <options>
  -h host
  -u user
  -p password
  -P port (defaults to 22)
  -t timeout (defaults to 4 seconds)
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

timeout $timeout lftp -u ${user},${password} sftp://${host}:${port} <<EOF > /dev/null
ls
bye
EOF

if [[ $? -ne 0 ]]; then
  echo "Unable to connect to connect to ${host}"; exit 2;
else
  echo "Successfully connected to ${host}"; exit 0;
fi
