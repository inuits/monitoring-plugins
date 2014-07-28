#!/usr/bin/python
from nagioscheck import NagiosCheck, UsageError
from nagioscheck import PerformanceMetric, Status
import urllib2
import optparse

try:
    import json
except ImportError:
    import simplejson as json


class ESNodesCheck(NagiosCheck):

    def __init__(self):

        NagiosCheck.__init__(self)

        self.add_option('E', 'expected_nodes_in_cluster', 'nodes_in_cluster',
                        'This is the expected number of nodes in the cluster')
        self.add_option('H', 'host', 'host', 'The cluster to check')
        self.add_option('P', 'port', 'port', 'The ES port - defaults to 9200')

    def check(self, opts, args):
        host = opts.host
        port = int(opts.port or '9200')
        nodes_in_cluster = int(opts.nodes_in_cluster)

        try:
            response = urllib2.urlopen(r'http://%s:%d/_cluster/health'
                                       % (host, port))
        except urllib2.HTTPError, e:
            raise Status('unknown', ("API failure", None, "API failure:\n\n%s"
                         % str(e)))
        except urllib2.URLError, e:
            raise Status('critical', (e.reason))

        response_body = response.read()

        try:
            es_cluster_health = json.loads(response_body)
        except ValueError:
            raise Status('unknown', ("API returned nonsense",))

        active_cluster_nodes = es_cluster_health['number_of_nodes']

        if active_cluster_nodes != nodes_in_cluster:
            raise Status('CRITICAL', "Number of nodes in the cluster is "
                         "reporting as '%s' but we expected '%s'"
                         % (active_cluster_nodes, nodes_in_cluster))
        else:
            raise Status('OK', "Number of nodes in the cluster is '%s' as "
                         "expected" % (nodes_in_cluster))

if __name__ == "__main__":
    ESNodesCheck().run()
