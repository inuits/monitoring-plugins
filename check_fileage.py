#!/usr/bin/python

import os, sys, datetime, stat, time

from stat import *

version = "16th April 2007"
#########################################################################################
#  Author:  Craig Rayner
#  28th February 2007
#########################################################################################

exit_codes = {0: 'OK', 1: 'Warning', 2: 'Critical', 3: 'Unknown'}

def getopts(argv):

	global version
		
	opts = {}
	while argv:
		x = len(argv) - 1
		if argv[0] == '-f':
			opts[argv[0]] = argv[1]
			argv = argv[2:]
		elif argv[0] == '--file':
			opts['-f'] = argv[1]
			argv = argv[2:]
		elif argv[0] == '-w':
			opts[argv[0]] = argv[1]
			argv = argv[2:]
		elif argv[0] == '--warning':
			opts['-w'] = argv[1]
			argv = argv[2:]
		elif argv[0] == '-c':
			opts[argv[0]] = argv[1]
			argv = argv[2:]
		elif argv[0] == '--critical':
			opts['-c'] = argv[1]
			argv = argv[2:]
		elif argv[0] == '-d':
			opts[argv[0]] = argv[1]
			argv = argv[2:]
		elif argv[0] == '--datetype':
			opts['-d'] = argv[1]
			argv = argv[2:]
                elif argv[0] == '-n':
                        opts[argv[0]] = argv[1]
                        argv = argv[2:]
                elif argv[0] == '--not-found':
                        opts['-d'] = argv[1]
                        argv = argv[2:]

		elif argv[0] == '-h':
			PrintHelp()
			argv = argv[1:]
		elif argv[0] == '--help':
			PrintHelp()
			argv = argv[1:]
		elif argv[0] == '-V':
			print 'Version: ' + str(version)
			argv = argv[1:]
		elif argv[0] == '--version':
			print 'Version: ' + str(version)
			argv = argv[1:]
   		else:
			argv = argv[1:]
	return opts

def PrintHelp():

        global version

        print "Version: " + version
	print """
	Usage: check_fileage -f /mount/path/file.ext -w nnnn -c nnnn [-d A|C|M] [-V] [-h]

	Options:
	 -h, --help
	    Print detailed help screen
	 -d, --datetype
	    Date Type: Return the date as defined:
                    A: (time of most recent access),
                    M: (time of most recent content modification),
                    C: (platform dependent; time of most recent metadata change on Unix, or the time of creation on Windows).
                    The default is M.
	 -f, --file
	    The absolute path and file name.
	 -w, --warning
            The age of the file in minutes to generate a warning notification.
         -c, --critical
            The age of the file in minutes to generate a critical notification.
         -n, --not-found
            The code to exit with if the file does not exist.
	 -V, --version
	    State the Version

	Examples:
	 check_fileage -f /path/to/file -w 1440 -C 2880
                 Returns OK if the file is less than the warning time in age.
	"""


if __name__ == '__main__':
	from sys import argv
	myargs = getopts(argv)
	if myargs.has_key('-V'):
		print 'Version: ' + str(version)
	datetype = 'M'
	if myargs.has_key('-d'):
                datetype = myargs['-d']
                if datetype not in 'ACM':
                    datetype = 'M'
        if myargs.has_key('-w'):
                warning = int(myargs['-w']) * 60
        else:
                print 'The warning time is not set.  See check_fileage.py --help'
                PrintHelp()
                sys.exit(3)
        if myargs.has_key('-c'):
                critical = int(myargs['-c']) * 60
                if critical <= warning:
                        print 'The critical time must be older than the warning time.  See check_fileage.py --help'
                        sys.exit(3)
        else:
                print 'The critical time is not set.  See check_fileage.py --help'
                PrintHelp()
                sys.exit(3)
        if myargs.has_key('-n'):
                not_found = int(myargs['-n'])
                if not_found not in [0, 1, 2, 3]:
                        print 'The not-found exit code must be 0, 1, 2 or 3.  See check_fileage.py --help'
                        sys.exit(3)
        else:
                myargs['-n'] = 3
	if myargs.has_key('-f'):
		try:
                        filestat = os.stat(myargs['-f'])
                        if datetype == 'A':
                                filedate = filestat.st_atime
                                descriptive = 'last access'
                        elif datetype == 'C':
                                filedate = filestat.st_ctime
                                descriptive = 'created (NOT *NIX)'
                        else:
                                filedate = filestat.st_mtime
                                descriptive = 'modified'
                        today = time.mktime(time.localtime())
                        exitstate = 0
                        fileage = time.strftime('%a %d %b/%Y %H:%M', time.localtime(filedate))
                        filename = myargs['-f']
                        if filename[1] == ":":
                                filename = filename[2:]
                                filename = filename.replace("\\", "/")
                        filename = os.path.basename(filename)
                        exitmessage = 'OK: ' + filename + ' has a ' + descriptive + ' date of ' + fileage + '\n'
                        if today > filedate + warning:
                                exitstate = 1
                                exitmessage = 'Warning: ' + exitmessage[4:]
                        if today > filedate + critical:
                                exitstate = 2
                                exitmessage = 'Critical: ' + exitmessage[9:]
                        print exitmessage
                        sys.exit(exitstate)
                except OSError:
                        filename = myargs['-f']
                        if filename[1] == ":":
                                filename = filename[2:]
                                filename = filename.replace("\\", "/")
                        filename = os.path.basename(filename)
                        print exit_codes[int(myargs['-n'])] + ': ' + filename + ' not found'
                        sys.exit(int(myargs['-n']))
        else:
                print 'The file name was not set.  See check_fileage.py --help'
                PrintHelp()
		sys.exit(3)
