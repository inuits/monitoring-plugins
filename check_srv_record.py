#!/usr/bin/env python2

# Copyright (c) 2018 Lander Van den Bulcke <landervandenbulcke at gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


import dns.resolver
import socket
import argparse
import sys

nagios_codes = [ 'OK', 'WARNING', 'CRITICAL', 'UNKNOWN' ]

def exit_now(status=3, message='Something went wrong'):
    print "%s - %s" % (nagios_codes[status], message)
    sys.exit(status)

def socket_is_open(ip, port, timeout, retries):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(int(timeout))
    
    res = False
    for i in range(int(retries)):
        try:
            s.connect((str(ip), int(port)))
            s.shutdown(socket.SHUT_RDWR)
            res = True
            break;
        except:
            continue
        finally:
            s.close()
    return res 

def resolve_a_record(query):
    resolv = dns.resolver.Resolver()
    return str(resolv.query(query, "A")[0])

def resolve_srv_record(query):
    try:
        results = []
        resolv = dns.resolver.Resolver()
        srvs = resolv.query(query, "SRV")
        for srv in srvs:
            results.append((srv.target.to_text(omit_final_dot=True), resolve_a_record(srv.target), int(srv.port)))
        return results
    except:
        exit_now(2, 'DNS lookup failed')
        
parser = argparse.ArgumentParser()
parser.add_argument('-Q', '--query', metavar='<query>', help='DNS SRV record to query for', dest='query', default=None)
parser.add_argument('-t', '--timeout', metavar='<timeout>', help='Timeout to try to connect to socket', dest='timeout', default=10)
parser.add_argument('-r', '--retries', metavar='<retries>', help='Number of times to retry connecting to socket', dest='retries', default=3)

args = parser.parse_args()

hosts_up = ''

targets = resolve_srv_record(args.query)
for target in targets:
    result = socket_is_open(target[1], target[2], args.timeout, args.retries)
    if not result:
        exit_now(2, "%s:%s is not reachable" % (target[0], target[2]))
    else:
        hosts_up += "%s:%s, " % (target[0], target[2])
exit_now(0, "%s are reachable" % hosts_up[:-2])
