#!/usr/bin/python
# Copyright (c) TurnKey GNU/Linux - http://www.turnkeylinux.org
#
# This file is part of UserAUFS
#
# UserAUFS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.

"""Creates a union mount
Options:
	--udba=<value>		Specify UDBA level (none | reval | inotify)
	-h			This help

<branch> := /path/to/branch[=<permission> [ + <attribute> ]]
    <permission> := rw | ro
    <attribute> := wh | nolwh

See aufs(5) for branch flag meanings.

"""
import sys
import help
import useraufs
import getopt

from utils import fatal

@help.usage(__doc__)
def usage():
    print >> sys.stderr, "Syntax: %s [ -options ] <mount-path> <branch> [<branch> ...]" % sys.argv[0]
    
def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], 'h', ['udba='])
    except getopt.GetoptError, e:
        usage(e)

    udba_level = None
    for opt, val in opts:
        if opt == '--udba':
            if val not in ('none', 'reval', 'inotify'):
                usage("invalid udba level (%s)" % val)

            udba_level = val
        elif opt == '-h':
            usage()

    if len(args) < 2:
        usage()

    mnt = args[0]
    branches = args[1:]

    try:
        useraufs.mount(mnt, branches, udba=udba_level)
    except useraufs.Error, e:
        fatal(e)
    
if __name__=="__main__":
    main()

