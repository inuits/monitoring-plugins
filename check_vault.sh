#!/bin/bash
##########################################################
#                                                        #
# check_vault                                            #
#                                                        #
# Author: Christophe Vanlancker <carroarmato0@inuits.eu> #
#                                                        #
# This is a simple Nagios/Icinga check which will query  #
# the state of Vault.                                    #
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


STATUS_COMMAND="vault status $ADDRESS";

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
elif [[ $OUTPUT == *"Sealed: true"* ]]; then
  KEY_THRESHOLD="$(echo $OUTPUT | egrep -o 'Key Threshold: [[:digit:]]' | cut -d ':' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')";
  USEAL_PROGRESS="$(echo $OUTPUT | egrep -o 'Unseal Progress: [[:digit:]]' | cut -d ':' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')";
  echo "Vault sealed, $USEAL_PROGRESS/$KEY_THRESHOLD entered";
  exit $WARNING;
elif [[ $OUTPUT == *"Sealed: false"* ]]; then
  echo "Vault unsealed";
  exit $OK;
else
  echo "Vault in an unknown state";
  echo $OUTPUT;
  exit $UNKNOWN;
fi
