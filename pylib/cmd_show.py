#!/usr/bin/python
"""Show this user's union mounts
Options:
	-m	print multi-line format (more human readable)

"""
import sys
import re
import os

import help
import getopt
import useraufs

@help.usage(__doc__)
def usage():
    print >> sys.stderr, "Syntax: %s [ -m ]" % sys.argv[0]

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'm')
    except getopt.GetoptError, e:
        usage(e)

    multiline = False
    for opt, val in opts:
        if opt == '-h':
            usage()
        elif opt == '-m':
            multiline = True

    for branches, dir in useraufs.get_mounts():
        if multiline:
            print "[ %s ]" % dir
            for branch in branches.split(":"):
                print branch
            print
        else:
            print "%s\t%s" % (branches, dir)
        
if __name__=="__main__":
    main()

