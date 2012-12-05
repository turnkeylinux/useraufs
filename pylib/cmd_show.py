#!/usr/bin/python
# Copyright (c) TurnKey Linux - http://www.turnkeylinux.org
#
# This file is part of UserAUFS
#
# UserAUFS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.

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
        opts, args = getopt.gnu_getopt(sys.argv[1:], 'm')
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

