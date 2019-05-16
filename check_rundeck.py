#!/usr/bin/env python
import json
import urllib2
import sys
import urllib
import optparse


def main(argv):
	p = optparse.OptionParser(conflict_handler="resolve", description="Icinga2 plugin for Rundeck health checks.")
	p.add_option('-H', '--hostname ', action='store', type='string', dest='hostname', default='127.0.0.1', help='Hostname of the node where Rundeck runs on.', metavar=' hostname' )
	p.add_option('-P', '--port ', action='store', type='int', dest='port', default='4440', help='The port Rundeck is using.', metavar=' port')
	p.add_option('-u', '--username ', action='store', type='string', dest='user', default=None, help='Rundeck user to authenticate with. [REQUIRED]', metavar=' user')
	p.add_option('-p', '--password ', action='store', type='string', dest='password', default=None, help='Rundeck password to authenicate with. [REQUIRED]', metavar = ' password')
	(options, args) = p.parse_args()
	if not options.user and not options.password:
		p.error('Credentials are missing, example: ./rundeck_check.py -u foo -p bar')
	if not options.user:
	 	p.error('Username is required to authenticate, example: -u foo')
	if not options.password:
		p.error('A password is required to authenticate, example: -p bar')

	hostname = options.hostname
	port = options.port
	user = options.user
	password = options.password
	apicall(hostname, port, user, password)
	
def apicall(url, port, user, password):
	opener = urllib2.build_opener(urllib2.HTTPCookieProcessor)
	urllib2.install_opener(opener)
	r = urllib2.Request("http://{}:{}/api/25/metrics/healthcheck".format(url, port))
	r.add_header('Content-Type', 'application/json')
	r.get_method()
	try:
		urllib2.urlopen("http://{}:{}/j_security_check".format(url, port), data=urllib.urlencode({'j_username':user,'j_password':password})) 
		jsondata = json.load(urllib2.urlopen(r))
	except urllib2.HTTPError, e:
		if str(e.code) == '403':
			print('Connection refused for user: {user}\nHTTPError: {error}'.format(user=user, error=e.code))
		else:
			print('HTTPError: '+ str(e.code))
		sys.exit(2)
	except urllib2.URLError, e:
		if hasattr(e, 'reason'):
			print("Failed to reach " +  url)
			print 'Reason:', e.reason
		elif hasattr(e, 'code'):
			print 'The server could not fulfill the request.'
			print 'Error code:', e.code
		sys.exit(2)
	except ValueError:
		print("API returned unreadable data")
		sys.exit(3)
	except Exception:
		import traceback
		print('generic exception: ' + traceback.format_exc())
		sys.exit(2)
	try:
		datacheck = jsondata["dataSource.connection.time"]["healthy"]
		quartzcheck = jsondata["quartz.scheduler.threadPool"]["healthy"]
	except KeyError, e:
		print ("Couldn't find key: " + str(e))
		sys.exit(3)
	healthcheck(datacheck, quartzcheck)
	


def healthcheck(datacheck, quartzcheck):
	if (datacheck is True and quartzcheck is True):
		print('Datasource connection: healthy\nQuartz scheduler threadpool: healthy')
		sys.exit(0)
	elif (datacheck is True and quartzcheck is False):
		print("Datasource connection: healthy\nQuartz scheduler threadpool: unhealthy")
		sys.exit(2)
	elif (datacheck is False and quartzcheck is True):
		print('Datasource connection: unhealthy\nQuartz scheduler threadpool: healthy')
		sys.exit(2)
	else:
		print('Datasource connection: unhealthy\nQuartz scheduler threadpool: unhealthy')
		sys.exit(2)
	

if __name__ == "__main__":
	main(sys.argv[1:])

	
