#!/usr/bin/env python3
#
# Copyright (c) 2022 Maarten Beeckmans <maartenb at inuits dot eu>

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of mosquitto nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
'''
check_patroni.py - v0.1 -  Copyright (c) 2022 Maarten Beeckmans <maartenb at inuits dot eu>

Nagios check script for checking patroni status and cluster lag

OPTIONS:

-s : scheme used to connect to the patroni api
-H : hostname/ip of the patroni server we want to query
-p : tcp port patroni api is listening on
-w : replication lag between primary and replica, to crit on (default 50)
-c : replication lag between primary and replica, to warn on (default 100)

EXAMPLE: ./check_patroni.py -H localhost -p 8008 w 50 -c 100

'''

import sys
import argparse
import requests

# Constants
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


def main(input_args):
    '''main script function'''
    critical_exit=False
    warning_exit=False

    parser = argparse.ArgumentParser(description="Nagios check script for checking patroni")
    parser.add_argument("-s", "--scheme",
            dest="scheme", default="http",
            help="Scheme used to connect to the patroni api. http or https")
    parser.add_argument("-H", "--host",
            dest="host", default="localhost",
            help="Hostname/ip of the patroni server we want to query")
    parser.add_argument("-p", "--port",
            dest="port", default="8008",
            help="Tcp port patroni api is listening on")
    parser.add_argument("-c", "--critical-lag",
            dest="critical_lag", default=100, type=int,
            help="replication lag between primary and replica, to crit on")
    parser.add_argument("-w", "--warning-lag",
            dest="warning_lag", default=50, type=int,
            help="replication lag between priary and replica, to warn on")
    args = parser.parse_args(input_args)

    baseurl = args.scheme + "://" + args.host + ":" + args.port
    critical_lag = args.critical_lag
    warning_lag = args.warning_lag

    if get_status_code(baseurl + "/health") != 200:
        print("Postgresql is not running")
        critical_exit=True

    try:
        response = requests.get(baseurl + "/cluster")
    except requests.ConnectionError as err:
        print(err)
        sys.exit(UNKNOWN)

    if response.status_code != 200:
        print('cluster not healty, exitting')
        sys.exit(UNKNOWN)
    leader = next(x for x in response.json()['members'] if x["role"] == "leader")
    if leader["state"] != "running":
        print(f'Leader ({leader["host"]} is not running')
        print()
        critical_exit=True
    for replica in [x for x in response.json()['members'] if x['role'] == "replica"]:
        if replica["timeline"] != leader["timeline"]:
            print(f'Replica ({replica["host"]}) timeline "{replica["timeline"]}" different')
            print(f'  from leader ({leader["host"]}) timeline "{leader["timeline"]}"')
            print()
            critical_exit=True
        if replica["lag"] >= critical_lag:
            print(f'CRIT: Replica ({replica["host"]}) lag {replica["lag"]} >= {critical_lag}')
            print()
            critical_exit=True
        elif replica["lag"] >= warning_lag:
            print(f'WARN: Replica ({replica["host"]}) lag {replica["lag"]} >= {warning_lag}')
            print()
            warning_exit=True
        else:
            print(f'Replica ({replica["host"]}) has a lag {replica["lag"]}')
            print()

    if critical_exit:
        sys.exit(CRITICAL)
    elif warning_exit:
        sys.exit(WARNING)
    else:
        sys.exit(OK)

def get_status_code(url):
    '''Gets the http status code of a given url'''
    try:
        response = requests.get(url)
    except requests.ConnectionError as err:
        print(err)
        sys.exit(UNKNOWN)
    return response.status_code

if __name__ == "__main__":
    main(sys.argv[1:])
