#!/bin/bash
##########################################################
#                                                        #
# check_vault                                            #
#                                                        #
# Author: Christophe Vanlancker <carroarmato0@inuits.eu> #
# Update: Temmerman Joeri <ratty@inuits.eu>              #
#                                                        #
# This is a simple Nagios/Icinga check which will query  #
# the state of Vault.                                    #
#                                                        #
# 2023-02-28:                                            #
#  - Option to raise critical on sealed vault            #
#                                                        #
# 2019-10-16:                                            #
#  - Minor rewrite to support vault v1.2.3               #
#                                                        #
# 2017-10-11:                                            #
#  - Fix Vault command not found when using nrpe         #
#  - Allow specifying the address                        #
#                                                        #
# 2017-10-10:                                            #
#  - Initial release                                     #
#                                                        #
##########################################################

# Constants
OK=0;
WARNING=1;
CRITICAL=2;
UNKNOWN=3;

SEALED_RC=$WARNING;

# Define PATH incase the user executing the script doesn't have it set (nrpe)
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

ADDRESS=""

# Parse through provided arguments
while [ "$1" != "" ]; do
  case $1 in
    -a | --address )      shift
                          ADDRESS="-address $1"
                          ;;

    --tls )               shift
                          TLS="true"
                          ;;
    --tls-server-name )   shift
                          TLS="true"
                          export VAULT_TLS_SERVER_NAME="$1"
                          ;;
    --ca-cert )           shift
                          TLS="true"
                          export VAULT_CACERT="$1"
                          ;;
    --sealed-critical )   shift
                          SEALED_RC=$CRITICAL
                          ;;
    * )
  esac
  shift
done

if [ -z "$ADDRESS" ]; then
  if [ "$TLS" = true ]; then
    ADDRESS='-address https://127.0.0.1:8200'
  else
    ADDRESS='-address http://127.0.0.1:8200'
  fi
fi

STATUS_COMMAND="vault status -format=json $ADDRESS";
OUTPUT=$(eval $STATUS_COMMAND 2>&1);

if [[ $OUTPUT == *"command not found"* ]]; then
  echo "Vault command not found";
  exit $UNKNOWN;
elif [[ $OUTPUT == *"connection refused"* ]]; then
  echo "Unable to connect to server";
  exit $CRITICAL;
elif [[ $OUTPUT == *"server is not yet initialized"* ]]; then
  echo "Vault not initialized";
  exit $WARNING;
elif [[ $OUTPUT == *"\"sealed\": true"* ]]; then
  KEY_THRESHOLD="$(echo $OUTPUT | egrep -o '"t": [[:digit:]]' | cut -d ':' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')";
  USEAL_PROGRESS="$(echo $OUTPUT | egrep -o '"progress": [[:digit:]]' | cut -d ':' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')";
  echo "Vault sealed, $USEAL_PROGRESS/$KEY_THRESHOLD entered";
  exit $SEALED_RC;
elif [[ $OUTPUT == *"\"sealed\": false"* ]]; then
  echo "Vault unsealed";
  exit $OK;
else
  echo "Vault in an unknown state";
  echo $OUTPUT;
  exit $UNKNOWN;
fi
