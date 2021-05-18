#!/usr/bin/env python2
import urllib2
import json
import pprint
import sys
import httplib

# Constants
OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

# argument parsing
args = sys.argv[1:]
host = "localhost"
port = "8500"
node_name = None
tls = False
ca_cert = None

while len(args) > 0:
    if args[0] == "--host" or args[0] == "-h":
        host = args[1]
    elif args[0] == "--node-name":
        node_name = args[1]
    elif args[0] == "--tls":
        tls =  True
        args = args[1:]
        continue
    elif args[0] == "--ca-cert":
        ca_cert = args[1]
    elif args[0] == "--port":
        port = args[1]

    args = args[2:]

if node_name is None or node_name.strip() == "":
    print("--node-name is a required parameter!")
    sys.exit(UNKNOWN)

# check status
try:
    scheme = "http://"
    if tls:
        scheme = "https://"
    url = scheme + host + ':' + port + '/v1/health/node/' + node_name
    req = urllib2.Request(url)
    response = urllib2.urlopen(req, timeout=10, cafile=ca_cert)
    data = json.loads(response.read())
    if len(data) == 0:
        print("Node not found")
        sys.exit(UNKNOWN)

    checks = { check["CheckID"]: check  for check in data} # convert into dict, key is CheckID

    consul_check = checks["serfHealth"]

    if consul_check["Status"] == "passing":
        print(consul_check["Output"])
        sys.exit(OK)
    elif consul_check["Status"] == "warning":
        print(consul_check["Output"])
        sys.exit(WARNING)
    elif consul_check["Status"] == "critical":
        print(consul_check["Output"])
        sys.exit(CRITICAL)
    elif consul_check["Status"] == "maintenance":
        print("[Service is in maintenance]" + str(consul_check["Output"]))
        sys.exit(WARNING)
    else:
        print("Unknown status")
        sys.exit(UNKNOWN)

except urllib2.URLError as e:
    print("Can't connect to Consul, reported error: " + str(e.reason))
    sys.exit(CRITICAL)
except httplib.HTTPException as e:
    print("Can't connect to Consul, reported error: " + repr(e))
    sys.exit(CRITICAL)
except Exception as e:
    print("Exception while contacting consul: " + repr(e))
    sys.exit(UNKNOWN)
