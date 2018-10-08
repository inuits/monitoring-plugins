#!/bin/bash
#
# This script checks if there are any messages waiting for a moderator approval.
#
# Author: Pavel Pulec <kayn@inuits.eu>
#

data_dir=/var/lib/mailman/data
warning=1
critical=20

while getopts d:w:c: opts; do
    case "$opts" in
        d)    data_dir="${OPTARG}";;
        w)    warning="${OPTARG}";;
        c)    critical="${OPTARG}";;
    esac
done

queues () {
  pending_queues=$(ls "${data_dir}"/heldmsg-*.pck 2>/dev/null | sed -r '/^$/d;s/.*heldmsg-(.*)-[0-9]+.pck/\1/' | sort -u | tr '\n' ' ')
}

err=$(ls "${data_dir}" 2>&1 >/dev/null) || {
  echo "UNKNOWN: The content of '${data_dir}' directory can't be listed. Error: ${err}"
  exit 3
}

count=$(ls "${data_dir}"/heldmsg-*.pck 2>/dev/null | wc -l)

if [ "${count}" -ge "${critical}" ]; then
  queues
  echo "CRITICAL: ${count} messages waiting for a moderator approval in the queues: ${pending_queues}"
  exit 2
elif [ "${count}" -ge "${warning}" ]; then
  queues
  echo "WARNING: ${count} messages waiting for a moderator approval in the queues: ${pending_queues}"
  exit 1
else
  echo "OK: no messages waiting for a moderator approval"
fi
